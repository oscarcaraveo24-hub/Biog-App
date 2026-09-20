import 'dart:async';
import 'dart:convert';

import 'package:bio_g/models/biog_telemetry.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Persiste el historial de telemetría por dispositivo.
///
/// La API pública de esta clase NO cambió al migrar a SQLite: los mismos
/// métodos, las mismas firmas, la misma semántica. Sólo cambiaron las tripas.
///
/// Por qué se migró:
/// antes todo el historial de un dispositivo vivía en SharedPreferences como
/// **una sola cadena JSON**. Cada lectura nueva obligaba a decodificar las hasta
/// 2000 anteriores, insertar una, y volver a codificar y escribir el bloque
/// completo — con ~25 campos por fila eso ronda el megabyte, cargado íntegro en
/// memoria en cada operación. `latest()` y `loadWindow()` también decodificaban
/// todo para quedarse con una fila o con una ventana.
///
/// Con SQLite se inserta una fila sin tocar las demás, y las consultas por
/// ventana o por última lectura se resuelven con un índice.
///
/// El almacenamiento local sigue siendo la fuente primaria de verdad: Supabase
/// y el futuro sync por Bluetooth mezclan sus lecturas aquí.
class TelemetryLocalStorage {
  /// Clave heredada en SharedPreferences. Se conserva para poder migrar los
  /// datos que el usuario ya tenía guardados.
  static const String _legacyPrefix = 'biog_telemetry_v1_';

  /// Marca de migración cumplida, para no volver a intentarla.
  static const String _migrationFlag = 'biog_telemetry_sqlite_migrated_v1';

  /// Tope de lecturas conservadas por dispositivo.
  ///
  /// Con la cadencia de transmisión prevista en el documento fundacional —un
  /// paquete cada dos horas— 2000 lecturas son unos 166 días: un ciclo agrícola
  /// completo. Se mantiene el mismo valor que antes para no alterar el
  /// comportamiento; ahora subirlo sería barato.
  static const int defaultCap = 2000;

  static const String _table = 'telemetry';
  static const String _dbName = 'biog_telemetry.db';

  /// Process-wide commit bus shared by every storage instance.
  ///
  /// The ingest service and the offline-first reader are intentionally
  /// separate objects, but they write/read the same SQLite database. Without
  /// this bus, a BLE append was invisible to an already-open live stream until
  /// its next Supabase poll. The event carries the post-commit latest value so
  /// listeners never have to publish the incoming row blindly (a cloud row
  /// can be older than what SQLite already contains).
  static final StreamController<_TelemetryLocalCommit> _commits =
      StreamController<_TelemetryLocalCommit>.broadcast(sync: true);

  final int cap;

  TelemetryLocalStorage({this.cap = defaultCap});

  static Future<Database>? _dbFuture;

  Future<Database> get _db => _dbFuture ??= _openDb();

  /// Emits after a successful local commit for [deviceId].
  ///
  /// This stream does not replay. Call [latest] for the initial snapshot, then
  /// keep this subscription alive for BLE/local commits.
  Stream<BioGTelemetry?> watchLatest(String deviceId) {
    final String normalized = _normalizeDeviceId(deviceId);
    return _commits.stream
        .where((_TelemetryLocalCommit event) => event.deviceId == normalized)
        .map((_TelemetryLocalCommit event) => event.latest);
  }

  static Future<Database> _openDb() async {
    final String dir = await getDatabasesPath();
    final String path = p.join(dir, _dbName);

    final Database db = await openDatabase(
      path,
      // v2: se vacía la caché una sola vez.
      //
      // La razón no es un cambio de esquema sino de SIGNIFICADO de `ts`. Antes,
      // `TelemetrySupabaseSync` resolvía la fecha de una fila tomando el máximo
      // entre `timestamp` y `created_at`, y `created_at` (hora de inserción)
      // casi siempre ganaba. Ahora manda la hora declarada por el dispositivo.
      // La misma medición pasa a tener una `ts` distinta, y como la llave es
      // (device_id, ts), convivirían dos filas para una sola lectura: el
      // Historial dibujaría cada punto dos veces, desplazado.
      //
      // Vaciar es seguro: esta tabla es caché de lo que hay en Supabase y se
      // repuebla en la siguiente descarga.
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_table (
            device_id TEXT NOT NULL,
            ts INTEGER NOT NULL,
            payload TEXT NOT NULL,
            PRIMARY KEY (device_id, ts)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_${_table}_device_ts ON $_table (device_id, ts DESC)',
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.delete(_table);
        }
      },
    );

    await _migrateFromSharedPreferences(db);
    return db;
  }

  /// Mueve a SQLite el historial que quedó guardado en SharedPreferences.
  ///
  /// Copia primero y borra después, y sólo borra la clave vieja de un
  /// dispositivo cuando su inserción terminó bien. Si algo falla, el dato viejo
  /// se queda donde está y se reintenta en el siguiente arranque.
  static Future<void> _migrateFromSharedPreferences(Database db) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationFlag) == true) return;

    final Iterable<String> legacyKeys = prefs.getKeys().where(
      (String k) => k.startsWith(_legacyPrefix),
    );

    for (final String key in legacyKeys) {
      final String deviceId = key.substring(_legacyPrefix.length);
      if (deviceId.isEmpty) continue;

      try {
        final String? raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) {
          await prefs.remove(key);
          continue;
        }

        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        final Batch batch = db.batch();

        for (final dynamic row in decoded) {
          if (row is! Map) continue;
          final BioGTelemetry? t = BioGTelemetry.tryFromJson(
            Map<String, dynamic>.from(row),
          );
          if (t == null || t.deviceId != deviceId) continue;
          batch.insert(_table, <String, Object?>{
            'device_id': t.deviceId,
            'ts': t.timestamp.toUtc().millisecondsSinceEpoch,
            'payload': jsonEncode(t.toJson()),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        await batch.commit(noResult: true);
        await prefs.remove(key);
      } catch (_) {
        // Un dispositivo con caché corrupta no puede impedir la migración de
        // los demás ni el arranque de la app.
      }
    }

    await prefs.setBool(_migrationFlag, true);
  }

  // ── API pública (idéntica a la versión anterior) ───────────────────────────

  /// Todo el historial de [deviceId], ordenado por fecha ascendente.
  Future<List<BioGTelemetry>> load(String deviceId) async {
    final String normalizedDeviceId = _normalizeDeviceId(deviceId);
    try {
      final Database db = await _db;
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        columns: <String>['payload'],
        where: 'device_id = ?',
        whereArgs: <Object?>[normalizedDeviceId],
        orderBy: 'ts ASC',
      );
      return _decodeRows(rows);
    } catch (_) {
      // Una base corrupta no debe tumbar la app: se devuelve vacío y la nube
      // vuelve a poblarla.
      return <BioGTelemetry>[];
    }
  }

  /// Historial de [deviceId] dentro de la ventana pedida.
  ///
  /// Ahora se resuelve con un filtro en la consulta en vez de cargar todo el
  /// historial y descartar en memoria.
  Future<List<BioGTelemetry>> loadWindow(
    String deviceId, {
    required Duration window,
  }) async {
    final String normalizedDeviceId = _normalizeDeviceId(deviceId);
    final DateTime since = DateTime.now().toUtc().subtract(window);
    try {
      final Database db = await _db;
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        columns: <String>['payload'],
        where: 'device_id = ? AND ts >= ?',
        whereArgs: <Object?>[normalizedDeviceId, since.millisecondsSinceEpoch],
        orderBy: 'ts ASC',
      );
      return _decodeRows(rows);
    } catch (_) {
      return <BioGTelemetry>[];
    }
  }

  /// Última lectura persistida de [deviceId]. Una fila, no todo el historial.
  Future<BioGTelemetry?> latest(String deviceId) async {
    final String normalizedDeviceId = _normalizeDeviceId(deviceId);
    try {
      final Database db = await _db;
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        columns: <String>['payload'],
        where: 'device_id = ?',
        whereArgs: <Object?>[normalizedDeviceId],
        orderBy: 'ts DESC',
        limit: 1,
      );
      final List<BioGTelemetry> decoded = _decodeRows(rows);
      return decoded.isEmpty ? null : decoded.first;
    } catch (_) {
      return null;
    }
  }

  /// Reemplaza el historial completo de [deviceId], recortando al tope.
  ///
  /// Descarta duplicados por deviceId + fecha, igual que antes.
  Future<void> save(String deviceId, List<BioGTelemetry> history) async {
    final String normalizedDeviceId = _normalizeDeviceId(deviceId);
    final List<BioGTelemetry> toSave = _trimToCap(
      _normalize(normalizedDeviceId, history),
    );
    try {
      final Database db = await _db;
      await db.transaction((Transaction txn) async {
        await txn.delete(
          _table,
          where: 'device_id = ?',
          whereArgs: <Object?>[normalizedDeviceId],
        );
        final Batch batch = txn.batch();
        for (final BioGTelemetry t in toSave) {
          batch.insert(
            _table,
            _rowFor(t),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
      _publishCommit(normalizedDeviceId, toSave.isEmpty ? null : toSave.last);
    } catch (_) {
      // Sin persistencia local la app sigue funcionando con lo que ya tiene
      // en memoria; no se interrumpe al usuario por un fallo de disco.
    }
  }

  /// Mezcla lecturas nuevas con el historial local y persiste.
  ///
  /// Es el método principal del modo offline-first: lo usan las descargas de
  /// Supabase y lo usará el sync por Bluetooth. Reintentar es seguro: no
  /// duplica lecturas.
  Future<List<BioGTelemetry>> mergeAndSave(
    String deviceId,
    List<BioGTelemetry> incoming, {
    bool overwriteExisting = true,
  }) async {
    final String normalizedDeviceId = _normalizeDeviceId(deviceId);
    if (incoming.isEmpty) return load(normalizedDeviceId);

    try {
      final Database db = await _db;
      final Batch batch = db.batch();
      for (final BioGTelemetry t in _normalize(normalizedDeviceId, incoming)) {
        batch.insert(
          _table,
          _rowFor(t),
          // Cloud refreshes use IGNORE: a row already committed locally for
          // the same measurement timestamp cannot be replaced by a delayed
          // response. BLE/local appends keep REPLACE for idempotent retries.
          conflictAlgorithm: overwriteExisting
              ? ConflictAlgorithm.replace
              : ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
      await _enforceCap(db, normalizedDeviceId);
      final List<BioGTelemetry> merged = await load(normalizedDeviceId);
      _publishCommit(normalizedDeviceId, merged.isEmpty ? null : merged.last);
      return merged;
    } catch (_) {
      return load(normalizedDeviceId);
    }
  }

  /// Agrega una lectura suelta. Se apoya en [mergeAndSave] para no duplicar.
  Future<void> append(String deviceId, BioGTelemetry reading) async {
    await mergeAndSave(deviceId, <BioGTelemetry>[reading]);
  }

  /// Borra lo persistido de un dispositivo.
  Future<void> delete(String deviceId) async {
    final String normalizedDeviceId = _normalizeDeviceId(deviceId);
    try {
      final Database db = await _db;
      await db.delete(
        _table,
        where: 'device_id = ?',
        whereArgs: <Object?>[normalizedDeviceId],
      );
      _publishCommit(normalizedDeviceId, null);
    } catch (_) {
      // Ídem: un fallo al limpiar no debe propagarse a la interfaz.
    }
  }

  // ── Internos ───────────────────────────────────────────────────────────────

  Map<String, Object?> _rowFor(BioGTelemetry t) => <String, Object?>{
    'device_id': t.deviceId,
    'ts': t.timestamp.toUtc().millisecondsSinceEpoch,
    'payload': jsonEncode(t.toJson()),
  };

  List<BioGTelemetry> _decodeRows(List<Map<String, Object?>> rows) {
    final List<BioGTelemetry> out = <BioGTelemetry>[];
    for (final Map<String, Object?> row in rows) {
      final Object? raw = row['payload'];
      if (raw is! String) continue;
      try {
        final BioGTelemetry? t = BioGTelemetry.tryFromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (t != null) out.add(t);
      } catch (_) {
        // Fila ilegible: se ignora sin tumbar la consulta completa.
      }
    }
    return out;
  }

  /// Conserva sólo las [cap] lecturas más recientes del dispositivo.
  Future<void> _enforceCap(Database db, String deviceId) async {
    await db.rawDelete(
      'DELETE FROM $_table WHERE device_id = ? AND ts NOT IN ('
      'SELECT ts FROM $_table WHERE device_id = ? ORDER BY ts DESC LIMIT ?)',
      <Object?>[deviceId, deviceId, cap],
    );
  }

  List<BioGTelemetry> _normalize(
    String deviceId,
    List<BioGTelemetry> readings,
  ) {
    final Map<String, BioGTelemetry> byKey = <String, BioGTelemetry>{};
    for (final BioGTelemetry reading in readings) {
      if (_normalizeDeviceId(reading.deviceId) != deviceId) continue;
      final BioGTelemetry normalizedReading = reading.deviceId == deviceId
          ? reading
          : reading.copyWith(deviceId: deviceId);
      byKey[_readingKey(normalizedReading)] = normalizedReading;
    }
    final List<BioGTelemetry> normalized = byKey.values.toList()
      ..sort(
        (BioGTelemetry a, BioGTelemetry b) =>
            a.timestamp.compareTo(b.timestamp),
      );
    return normalized;
  }

  List<BioGTelemetry> _trimToCap(List<BioGTelemetry> readings) {
    if (readings.length <= cap) return readings;
    return readings.sublist(readings.length - cap);
  }

  String _readingKey(BioGTelemetry reading) {
    return '${reading.deviceId}_${reading.timestamp.toUtc().toIso8601String()}';
  }

  void _publishCommit(String deviceId, BioGTelemetry? latest) {
    if (_commits.isClosed) return;
    _commits.add(_TelemetryLocalCommit(deviceId: deviceId, latest: latest));
  }

  static String _normalizeDeviceId(String value) {
    final String trimmed = value.trim();
    return BioGDevice.isTelemetryDeviceId(trimmed)
        ? trimmed.toLowerCase()
        : trimmed;
  }
}

class _TelemetryLocalCommit {
  const _TelemetryLocalCommit({required this.deviceId, required this.latest});

  final String deviceId;
  final BioGTelemetry? latest;
}
