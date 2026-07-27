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

  final int cap;

  TelemetryLocalStorage({this.cap = defaultCap});

  static Future<Database>? _dbFuture;

  Future<Database> get _db => _dbFuture ??= _openDb();

  static Future<Database> _openDb() async {
    final String dir = await getDatabasesPath();
    final String path = p.join(dir, _dbName);

    final Database db = await openDatabase(
      path,
      version: 1,
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

    final Iterable<String> legacyKeys = prefs
        .getKeys()
        .where((String k) => k.startsWith(_legacyPrefix));

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
    try {
      final Database db = await _db;
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        columns: <String>['payload'],
        where: 'device_id = ?',
        whereArgs: <Object?>[deviceId],
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
    final DateTime since = DateTime.now().toUtc().subtract(window);
    try {
      final Database db = await _db;
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        columns: <String>['payload'],
        where: 'device_id = ? AND ts >= ?',
        whereArgs: <Object?>[deviceId, since.millisecondsSinceEpoch],
        orderBy: 'ts ASC',
      );
      return _decodeRows(rows);
    } catch (_) {
      return <BioGTelemetry>[];
    }
  }

  /// Última lectura persistida de [deviceId]. Una fila, no todo el historial.
  Future<BioGTelemetry?> latest(String deviceId) async {
    try {
      final Database db = await _db;
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        columns: <String>['payload'],
        where: 'device_id = ?',
        whereArgs: <Object?>[deviceId],
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
    final List<BioGTelemetry> toSave = _trimToCap(
      _normalize(deviceId, history),
    );
    try {
      final Database db = await _db;
      await db.transaction((Transaction txn) async {
        await txn.delete(
          _table,
          where: 'device_id = ?',
          whereArgs: <Object?>[deviceId],
        );
        final Batch batch = txn.batch();
        for (final BioGTelemetry t in toSave) {
          batch.insert(_table, _rowFor(t),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });
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
    List<BioGTelemetry> incoming,
  ) async {
    if (incoming.isEmpty) return load(deviceId);

    try {
      final Database db = await _db;
      final Batch batch = db.batch();
      for (final BioGTelemetry t in _normalize(deviceId, incoming)) {
        batch.insert(_table, _rowFor(t),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      await _enforceCap(db, deviceId);
      return load(deviceId);
    } catch (_) {
      return load(deviceId);
    }
  }

  /// Agrega una lectura suelta. Se apoya en [mergeAndSave] para no duplicar.
  Future<void> append(String deviceId, BioGTelemetry reading) async {
    await mergeAndSave(deviceId, <BioGTelemetry>[reading]);
  }

  /// Borra lo persistido de un dispositivo.
  Future<void> delete(String deviceId) async {
    try {
      final Database db = await _db;
      await db.delete(
        _table,
        where: 'device_id = ?',
        whereArgs: <Object?>[deviceId],
      );
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
      if (reading.deviceId != deviceId) continue;
      byKey[_readingKey(reading)] = reading;
    }
    final List<BioGTelemetry> normalized = byKey.values.toList()
      ..sort((BioGTelemetry a, BioGTelemetry b) =>
          a.timestamp.compareTo(b.timestamp));
    return normalized;
  }

  List<BioGTelemetry> _trimToCap(List<BioGTelemetry> readings) {
    if (readings.length <= cap) return readings;
    return readings.sublist(readings.length - cap);
  }

  String _readingKey(BioGTelemetry reading) {
    return '${reading.deviceId}_${reading.timestamp.toUtc().toIso8601String()}';
  }
}
