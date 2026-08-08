// lib/core/agro/traceability/recommendation_store.dart
//
// Memoria auditable de las recomendaciones. Se escribe Y se lee.
//
// El almacén de eventos que ya existía tenía un defecto que la auditoría no
// detectó: `CropEventLocalStorage.load()` y `.delete()` no tenían un solo
// llamador. Se escribía a SQLite en cada lectura de telemetría —gastando
// entrada/salida y batería— y ni el Historial ni Notificaciones lo
// consultaban: ambos recalculaban en memoria. Era memoria de escritura pura.
//
// Este almacén nace con la lectura como requisito, no como intención:
//  - [load] y [loadPending] son parte del contrato y tienen consumidores.
//  - Cada fila lleva `user_id`, así que se puede purgar al cambiar de cuenta.
//  - [respond] cierra el ciclo: guarda qué hizo el agricultor.
//  - [expirePending] marca como vencidas las que nadie contestó, para que
//    "sin responder" signifique de verdad "sin responder".

import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:bio_g/core/agro/traceability/recommendation_record.dart';

class RecommendationStore {
  RecommendationStore({Database Function()? testDatabase})
    : _testDatabase = testDatabase;

  static const String _dbName = 'biog_recommendations.db';
  static const String _table = 'recommendations';

  /// Dueño de las filas escritas sin sesión (invitado).
  static const String guestUserId = '__guest__';

  static Future<Database>? _dbFuture;
  final Database Function()? _testDatabase;

  Future<Database> get _db async {
    final override = _testDatabase;
    if (override != null) return override();
    return _dbFuture ??= _openDb();
  }

  static Future<Database> _openDb() async {
    final String dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _dbName),
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT NOT NULL PRIMARY KEY,
            user_id TEXT NOT NULL,
            device_id TEXT NOT NULL,
            kind TEXT NOT NULL,
            issued_at INTEGER NOT NULL,
            valid_until INTEGER,
            user_response TEXT NOT NULL,
            payload TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_${_table}_owner ON $_table '
          '(user_id, device_id, issued_at DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_${_table}_response ON $_table (user_response)',
        );
      },
    );
  }

  /// Guarda un registro. Si ya existía con el mismo id, no lo sobrescribe.
  ///
  /// La inmutabilidad es el punto: una recomendación emitida no se reescribe.
  /// Lo único que cambia después es la respuesta del usuario, y para eso está
  /// [respond].
  Future<bool> save(RecommendationRecord record) async {
    try {
      final db = await _db;
      final inserted = await db.rawInsert(
        'INSERT OR IGNORE INTO $_table '
        '(id, user_id, device_id, kind, issued_at, valid_until, '
        'user_response, payload) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          record.id,
          record.userId ?? guestUserId,
          record.deviceId,
          record.kind.name,
          record.issuedAt.toUtc().millisecondsSinceEpoch,
          record.validUntil?.toUtc().millisecondsSinceEpoch,
          record.userResponse.name,
          record.encode(),
        ],
      );
      return inserted > 0;
    } catch (_) {
      // Registrar la trazabilidad nunca puede interrumpir al agricultor.
      return false;
    }
  }

  /// Recomendaciones de un dispositivo, de la más reciente a la más antigua.
  Future<List<RecommendationRecord>> load({
    required String deviceId,
    String? userId,
    RecommendationKind? kind,
    int limit = 200,
  }) async {
    try {
      final db = await _db;

      final where = StringBuffer('device_id = ?');
      final args = <Object?>[deviceId];

      if (userId != null) {
        where.write(' AND (user_id = ? OR user_id = ?)');
        args
          ..add(userId)
          ..add(guestUserId);
      }
      if (kind != null) {
        where.write(' AND kind = ?');
        args.add(kind.name);
      }

      final rows = await db.query(
        _table,
        columns: <String>['payload'],
        where: where.toString(),
        whereArgs: args,
        orderBy: 'issued_at DESC',
        limit: limit,
      );

      return _decode(rows);
    } catch (_) {
      return const <RecommendationRecord>[];
    }
  }

  /// Recomendaciones que el usuario todavía no ha contestado.
  ///
  /// Es lo que permite que la interfaz insista con una acción de alto impacto
  /// en vez de emitirla una vez y olvidarla.
  Future<List<RecommendationRecord>> loadPending({
    required String deviceId,
    String? userId,
    int limit = 50,
  }) async {
    try {
      final db = await _db;

      final where = StringBuffer('device_id = ? AND user_response = ?');
      final args = <Object?>[deviceId, UserResponse.pending.name];

      if (userId != null) {
        where.write(' AND (user_id = ? OR user_id = ?)');
        args
          ..add(userId)
          ..add(guestUserId);
      }

      final rows = await db.query(
        _table,
        columns: <String>['payload'],
        where: where.toString(),
        whereArgs: args,
        orderBy: 'issued_at DESC',
        limit: limit,
      );

      return _decode(rows);
    } catch (_) {
      return const <RecommendationRecord>[];
    }
  }

  /// La última recomendación de un tipo, para saber qué se aconsejó por última
  /// vez sin recalcular nada.
  Future<RecommendationRecord?> latest({
    required String deviceId,
    required RecommendationKind kind,
    String? userId,
  }) async {
    final list = await load(
      deviceId: deviceId,
      userId: userId,
      kind: kind,
      limit: 1,
    );
    return list.isEmpty ? null : list.first;
  }

  /// Registra qué hizo el agricultor.
  Future<bool> respond({
    required String recordId,
    required UserResponse response,
    required DateTime at,
  }) async {
    try {
      final db = await _db;

      final rows = await db.query(
        _table,
        columns: <String>['payload'],
        where: 'id = ?',
        whereArgs: <Object?>[recordId],
        limit: 1,
      );
      if (rows.isEmpty) return false;

      final raw = rows.first['payload'];
      if (raw is! String) return false;

      final record = RecommendationRecord.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (record == null) return false;

      final updated = record.respond(response, at: at);

      final count = await db.update(
        _table,
        <String, Object?>{
          'user_response': response.name,
          'payload': updated.encode(),
        },
        where: 'id = ?',
        whereArgs: <Object?>[recordId],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }

  /// Marca como vencidas las pendientes cuya validez ya pasó.
  ///
  /// Sin esto, una recomendación de hace tres semanas seguiría figurando como
  /// "esperando respuesta", que es falso: venció.
  Future<int> expirePending({required DateTime now}) async {
    try {
      final db = await _db;
      final nowMs = now.toUtc().millisecondsSinceEpoch;

      final rows = await db.query(
        _table,
        columns: <String>['id', 'payload'],
        where: 'user_response = ? AND valid_until IS NOT NULL AND valid_until < ?',
        whereArgs: <Object?>[UserResponse.pending.name, nowMs],
      );

      var updated = 0;
      for (final row in rows) {
        final id = row['id'];
        final raw = row['payload'];
        if (id is! String || raw is! String) continue;

        final record = RecommendationRecord.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (record == null) continue;

        final expired = record.respond(UserResponse.expired, at: now);
        final n = await db.update(
          _table,
          <String, Object?>{
            'user_response': UserResponse.expired.name,
            'payload': expired.encode(),
          },
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
        updated += n;
      }
      return updated;
    } catch (_) {
      return 0;
    }
  }

  Future<int> count({required String deviceId, String? userId}) async {
    try {
      final db = await _db;
      final rows = await db.rawQuery(
        userId == null
            ? 'SELECT COUNT(*) AS c FROM $_table WHERE device_id = ?'
            : 'SELECT COUNT(*) AS c FROM $_table WHERE device_id = ? '
                  'AND (user_id = ? OR user_id = ?)',
        userId == null
            ? <Object?>[deviceId]
            : <Object?>[deviceId, userId, guestUserId],
      );
      final c = rows.isEmpty ? null : rows.first['c'];
      return c is int ? c : 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> deleteForDevice(String deviceId) async {
    try {
      final db = await _db;
      await db.delete(
        _table,
        where: 'device_id = ?',
        whereArgs: <Object?>[deviceId],
      );
    } catch (_) {
      // Ídem.
    }
  }

  /// Purga por usuario. Requisito del derecho de supresión y condición para
  /// que cambiar de cuenta en el mismo teléfono no filtre historial.
  Future<void> deleteForUser(String userId) async {
    try {
      final db = await _db;
      await db.delete(_table, where: 'user_id = ?', whereArgs: <Object?>[userId]);
    } catch (_) {
      // Ídem.
    }
  }

  Future<void> deleteAll() async {
    try {
      final db = await _db;
      await db.delete(_table);
    } catch (_) {
      // Ídem.
    }
  }

  List<RecommendationRecord> _decode(List<Map<String, Object?>> rows) {
    final out = <RecommendationRecord>[];
    for (final row in rows) {
      final raw = row['payload'];
      if (raw is! String) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final record = RecommendationRecord.fromJson(
          decoded.cast<String, dynamic>(),
        );
        if (record != null) out.add(record);
      } catch (_) {
        // Fila ilegible: se ignora sin tumbar la consulta.
      }
    }
    return out;
  }
}
