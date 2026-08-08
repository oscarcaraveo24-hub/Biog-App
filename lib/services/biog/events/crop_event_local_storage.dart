import 'dart:convert';

import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Memoria persistente de los eventos del cultivo.
///
/// Hasta ahora los eventos se recalculaban dentro del `build()` de la pantalla
/// y no se guardaban en ningún lado. La consecuencia práctica: si el cultivo
/// cambiaba de etapa a las tres de la madrugada y el agricultor no tenía la app
/// abierta en ese instante, ese evento **nunca existió**. El Historial no era
/// memoria del cultivo, era una foto del momento.
///
/// Esta clase no cambia nada de lo que se ve en pantalla: solo conserva lo que
/// ya se calcula, para que sobreviva a cerrar la app. Es además el requisito
/// para que más adelante una notificación pueda sonar sin la app abierta.
///
/// Usa su propio archivo de base de datos, separado del de telemetría, para no
/// tocar un almacenamiento que ya está en uso.
class CropEventLocalStorage {
  static const String _dbName = 'biog_crop_events.db';
  static const String _table = 'crop_events';

  /// Marcador de las filas escritas antes de que existiera `user_id`.
  static const String legacyUserId = '__legacy__';

  static Future<Database>? _dbFuture;

  Future<Database> get _db => _dbFuture ??= _openDb();

  static Future<Database> _openDb() async {
    final String dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _dbName),
      // v2: se añade `user_id`.
      //
      // La tabla se indexaba solo por `device_id` y no tenía dueño, así que
      // ni `removeDevice` ni `unbindUser` podían purgarla. Cambiar de cuenta
      // en el mismo teléfono dejaba el historial agronómico del usuario
      // anterior en disco, sin ninguna ruta de borrado: una fuga de datos y
      // un incumplimiento directo del derecho de supresión que hay que
      // declarar en las tiendas.
      version: 2,
      onCreate: (Database db, int version) async {
        await _createSchema(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Se recrea la tabla en vez de hacer ALTER TABLE ADD COLUMN.
          //
          // Dos razones, y las dos importan:
          //
          // 1. `user_id` tiene que entrar en la LLAVE PRIMARIA. Con la llave
          //    vieja `(device_id, dedup_key)`, dos cuentas en el mismo teléfono
          //    vinculadas al mismo Bio-G producen la misma `dedup_key` dentro
          //    de la misma hora, y el `INSERT OR IGNORE` descartaba en silencio
          //    el evento del segundo usuario. SQLite no permite cambiar una PK
          //    con ALTER TABLE.
          //
          // 2. Las filas anteriores no tienen dueño conocido. Marcarlas como
          //    "heredadas" y dejarlas visibles significaba que CUALQUIER cuenta
          //    posterior vería el historial de la anterior: exactamente la fuga
          //    que esta migración venía a cerrar.
          //
          // Se pierde el historial persistido previo, y es aceptable: nadie lo
          // leía todavía (Historial y Notificaciones recalculan en memoria) y
          // se vuelve a generar con la siguiente lectura.
          await db.execute('DROP TABLE IF EXISTS $_table');
          await _createSchema(db);
        }
      },
    );
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $_table (
        user_id TEXT NOT NULL DEFAULT '$legacyUserId',
        device_id TEXT NOT NULL,
        dedup_key TEXT NOT NULL,
        ts INTEGER NOT NULL,
        payload TEXT NOT NULL,
        PRIMARY KEY (user_id, device_id, dedup_key)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_${_table}_device_ts ON $_table '
      '(user_id, device_id, ts DESC)',
    );
    await db.execute('CREATE INDEX idx_${_table}_user ON $_table (user_id)');
  }

  /// Guarda los eventos que todavía no estaban registrados.
  ///
  /// Usa `INSERT OR IGNORE` contra la llave de deduplicación: recalcular la
  /// misma lectura mil veces no genera mil filas. Devuelve cuántos eran nuevos.
  Future<int> saveNew(
    String deviceId,
    List<AgronomicEvent> events, {
    String? userId,
  }) async {
    if (events.isEmpty) return 0;
    try {
      final Database db = await _db;
      int inserted = 0;
      final String owner = userId ?? legacyUserId;

      await db.transaction((Transaction txn) async {
        for (final AgronomicEvent e in events) {
          final int n = await txn.rawInsert(
            'INSERT OR IGNORE INTO $_table '
            '(user_id, device_id, dedup_key, ts, payload) '
            'VALUES (?, ?, ?, ?, ?)',
            <Object?>[
              owner,
              deviceId,
              e.dedupKey,
              e.timestamp.toUtc().millisecondsSinceEpoch,
              jsonEncode(e.toJson()),
            ],
          );
          if (n > 0) inserted++;
        }
      });

      return inserted;
    } catch (_) {
      // Guardar el historial de eventos nunca puede afectar a la app.
      return 0;
    }
  }

  /// Eventos registrados de un dispositivo, del más reciente al más antiguo.
  ///
  /// Con [userId] se devuelven únicamente los eventos de esa cuenta.
  ///
  /// Sin [userId] se devuelven los de todas, que es lo que quiere una
  /// herramienta de diagnóstico pero NUNCA la interfaz: cualquier pantalla
  /// debe pasar el usuario activo.
  Future<List<AgronomicEvent>> load(
    String deviceId, {
    int limit = 500,
    String? userId,
  }) async {
    try {
      final Database db = await _db;
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        columns: <String>['payload'],
        // Solo lo del propio usuario. Ya no se incluyen filas "heredadas":
        // eso dejaría el historial de una cuenta visible para la siguiente.
        where: userId == null
            ? 'device_id = ?'
            : 'device_id = ? AND user_id = ?',
        whereArgs: userId == null
            ? <Object?>[deviceId]
            : <Object?>[deviceId, userId],
        orderBy: 'ts DESC',
        limit: limit,
      );

      final List<AgronomicEvent> out = <AgronomicEvent>[];
      for (final Map<String, Object?> row in rows) {
        final Object? raw = row['payload'];
        if (raw is! String) continue;
        try {
          final AgronomicEvent? e = AgronomicEvent.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
          if (e != null) out.add(e);
        } catch (_) {
          // Fila ilegible: se ignora sin tumbar la consulta.
        }
      }
      return out;
    } catch (_) {
      return <AgronomicEvent>[];
    }
  }

  /// Cuántos eventos hay registrados para un dispositivo.
  Future<int> count(String deviceId) async {
    try {
      final Database db = await _db;
      final List<Map<String, Object?>> rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $_table WHERE device_id = ?',
        <Object?>[deviceId],
      );
      final Object? c = rows.isEmpty ? null : rows.first['c'];
      return c is int ? c : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Borra los eventos de un dispositivo.
  Future<void> delete(String deviceId) async {
    try {
      final Database db = await _db;
      await db.delete(
        _table,
        where: 'device_id = ?',
        whereArgs: <Object?>[deviceId],
      );
    } catch (_) {
      // Ídem.
    }
  }

  /// Borra todo lo de un usuario.
  ///
  /// Se llama al cerrar sesión y al eliminar la cuenta. Sin esto, el historial
  /// agronómico del usuario anterior sobrevivía en el teléfono.
  Future<void> deleteForUser(String userId) async {
    try {
      final Database db = await _db;
      // Solo lo de este usuario. Incluir las filas heredadas haría que el
      // primero en cerrar sesión borrara el historial de los demás.
      await db.delete(
        _table,
        where: 'user_id = ?',
        whereArgs: <Object?>[userId],
      );
    } catch (_) {
      // Ídem.
    }
  }

  /// Vacía la tabla por completo.
  Future<void> deleteAll() async {
    try {
      final Database db = await _db;
      await db.delete(_table);
    } catch (_) {
      // Ídem.
    }
  }
}
