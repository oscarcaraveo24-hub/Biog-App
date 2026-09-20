// lib/services/biog/nutrition/nutrition_local_storage.dart
//
// Memoria persistente del motor de nutrición: el LIBRO DE VENTANAS y la ÉPOCA
// DE INSTALACIÓN del sitio (Guía v0.4, §21–§22 y fase 8).
//
// Por qué existe: la ventana de una etapa puede abrir, ser atendida o terminar
// sin evidencia mientras la app está cerrada. Si el resultado viviera solo en
// memoria, cambiar de etapa lo borraría y el score histórico y la proyección
// perderían justo lo que la Guía manda conservar. Igual que
// `CropEventLocalStorage`: es memoria, no funcionalidad; ningún fallo aquí
// puede tumbar el Panel.
//
// Local-first, como todo lo demás en el teléfono. La subida a Supabase queda
// para cuando exista la tabla (migración escrita, no aplicada).
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:bio_g/core/agro/nutrition/nutrition_season_declaration.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/agro/nutrition/site_learning.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class NutritionLocalStorage {
  static const String _dbName = 'biog_nutrition.db';
  static const String _windowsTable = 'nutrition_windows';
  static const String _epochsTable = 'installation_epochs';

  /// Declaración de temporada («¿cómo vas a fertilizar?»), una por
  /// dispositivo y temporada. Versión 2 del esquema (13 sep 2026).
  static const String _declarationsTable = 'nutrition_declarations';

  /// Versión del esquema. Subirla exige un paso en [_upgradeSchema]: las
  /// instalaciones existentes no vuelven a pasar por `onCreate`.
  static const int _schemaVersion = 2;

  /// Marcador para filas sin dueño resuelto (la sesión puede tardar).
  static const String legacyUserId = '__legacy__';

  static Future<Database>? _dbFuture;

  Future<Database> get _db => _dbFuture ??= _openDb();

  static Future<Database> _openDb() async {
    final String dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _dbName),
      version: _schemaVersion,
      onCreate: (Database db, int version) async {
        await _createSchema(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        await _upgradeSchema(db, oldVersion, newVersion);
      },
    );
  }

  /// Migraciones incrementales. Cada paso es idempotente (`IF NOT EXISTS`).
  static Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDeclarationsTable(db);
    }
  }

  static Future<void> _createDeclarationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_declarationsTable (
        user_id TEXT NOT NULL DEFAULT '$legacyUserId',
        device_id TEXT NOT NULL,
        season_key TEXT NOT NULL,
        declared_at INTEGER NOT NULL,
        payload TEXT NOT NULL,
        PRIMARY KEY (user_id, device_id, season_key)
      )
    ''');
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $_windowsTable (
        user_id TEXT NOT NULL DEFAULT '$legacyUserId',
        device_id TEXT NOT NULL,
        season_key TEXT NOT NULL,
        window_id TEXT NOT NULL,
        opened_at INTEGER NOT NULL,
        outcome TEXT NOT NULL,
        payload TEXT NOT NULL,
        PRIMARY KEY (user_id, device_id, window_id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_${_windowsTable}_season ON $_windowsTable '
      '(user_id, device_id, season_key, opened_at)',
    );
    await db.execute('''
      CREATE TABLE $_epochsTable (
        user_id TEXT NOT NULL DEFAULT '$legacyUserId',
        device_id TEXT NOT NULL,
        epoch_id TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        payload TEXT NOT NULL,
        PRIMARY KEY (user_id, device_id, epoch_id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_${_epochsTable}_device ON $_epochsTable '
      '(user_id, device_id, started_at DESC)',
    );
    await _createDeclarationsTable(db);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // VENTANAS
  // ═════════════════════════════════════════════════════════════════════════

  /// Inserta o reemplaza las ventanas indicadas (misma identidad → misma fila).
  Future<void> upsertWindows(
    List<NutritionWindowRecord> records, {
    String? userId,
  }) async {
    if (records.isEmpty) return;
    try {
      final Database db = await _db;
      final String owner = userId ?? legacyUserId;
      await db.transaction((Transaction txn) async {
        for (final NutritionWindowRecord r in records) {
          await txn.rawInsert(
            'INSERT OR REPLACE INTO $_windowsTable '
            '(user_id, device_id, season_key, window_id, opened_at, outcome, payload) '
            'VALUES (?, ?, ?, ?, ?, ?, ?)',
            <Object?>[
              owner,
              r.deviceId,
              r.seasonKey,
              r.id,
              r.openedAt.toUtc().millisecondsSinceEpoch,
              r.outcome.name,
              jsonEncode(r.toJson()),
            ],
          );
        }
      });
    } catch (_) {
      // Guardar memoria nunca puede afectar a la app.
    }
  }

  /// Ventanas de una temporada, de la más antigua a la más reciente.
  Future<List<NutritionWindowRecord>> loadSeason({
    required String deviceId,
    required String seasonKey,
    String? userId,
  }) async {
    try {
      final Database db = await _db;
      final List<Map<String, Object?>> rows = await db.query(
        _windowsTable,
        columns: <String>['payload'],
        where: userId == null
            ? 'device_id = ? AND season_key = ?'
            : 'device_id = ? AND season_key = ? AND user_id = ?',
        whereArgs: userId == null
            ? <Object?>[deviceId, seasonKey]
            : <Object?>[deviceId, seasonKey, userId],
        orderBy: 'opened_at ASC',
      );
      return _decodeWindows(rows);
    } catch (_) {
      return <NutritionWindowRecord>[];
    }
  }

  /// Todas las ventanas de un dispositivo (para el historial y para comparar
  /// la respuesta habitual del sitio entre temporadas).
  Future<List<NutritionWindowRecord>> loadDevice({
    required String deviceId,
    String? userId,
    int limit = 200,
  }) async {
    try {
      final Database db = await _db;
      final List<Map<String, Object?>> rows = await db.query(
        _windowsTable,
        columns: <String>['payload'],
        where: userId == null ? 'device_id = ?' : 'device_id = ? AND user_id = ?',
        whereArgs: userId == null ? <Object?>[deviceId] : <Object?>[deviceId, userId],
        orderBy: 'opened_at DESC',
        limit: limit,
      );
      return _decodeWindows(rows);
    } catch (_) {
      return <NutritionWindowRecord>[];
    }
  }

  static List<NutritionWindowRecord> _decodeWindows(
    List<Map<String, Object?>> rows,
  ) {
    final List<NutritionWindowRecord> out = <NutritionWindowRecord>[];
    for (final Map<String, Object?> row in rows) {
      final Object? raw = row['payload'];
      if (raw is! String) continue;
      try {
        final NutritionWindowRecord? r = NutritionWindowRecord.tryFromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (r != null) out.add(r);
      } catch (_) {
        // Fila ilegible: se ignora sin tumbar la consulta.
      }
    }
    return out;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ÉPOCAS DE INSTALACIÓN
  // ═════════════════════════════════════════════════════════════════════════

  /// Abre una época nueva (instalación inicial o reubicación).
  Future<void> saveEpoch(InstallationEpoch epoch, {String? userId}) async {
    try {
      final Database db = await _db;
      final String epochId =
          epoch.epochId ?? epoch.startedAt.toUtc().millisecondsSinceEpoch.toString();
      await db.rawInsert(
        'INSERT OR REPLACE INTO $_epochsTable '
        '(user_id, device_id, epoch_id, started_at, payload) VALUES (?, ?, ?, ?, ?)',
        <Object?>[
          userId ?? legacyUserId,
          epoch.deviceId,
          epochId,
          epoch.startedAt.toUtc().millisecondsSinceEpoch,
          jsonEncode(
            InstallationEpoch(
              deviceId: epoch.deviceId,
              startedAt: epoch.startedAt,
              epochId: epochId,
              reasonEs: epoch.reasonEs,
            ).toJson(),
          ),
        ],
      );
    } catch (_) {
      // Ídem.
    }
  }

  /// Época vigente (la más reciente) del dispositivo.
  Future<InstallationEpoch?> currentEpoch(
    String deviceId, {
    String? userId,
  }) async {
    try {
      final Database db = await _db;
      final List<Map<String, Object?>> rows = await db.query(
        _epochsTable,
        columns: <String>['payload'],
        where: userId == null ? 'device_id = ?' : 'device_id = ? AND user_id = ?',
        whereArgs: userId == null ? <Object?>[deviceId] : <Object?>[deviceId, userId],
        orderBy: 'started_at DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final Object? raw = rows.first['payload'];
      if (raw is! String) return null;
      return InstallationEpoch.tryFromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // DECLARACIÓN DE TEMPORADA
  // ═════════════════════════════════════════════════════════════════════════

  /// Guarda (o reemplaza) cómo va a fertilizar el productor esta temporada.
  Future<void> saveDeclaration(
    NutritionSeasonDeclaration declaration, {
    String? userId,
  }) async {
    try {
      final Database db = await _db;
      await db.rawInsert(
        'INSERT OR REPLACE INTO $_declarationsTable '
        '(user_id, device_id, season_key, declared_at, payload) VALUES (?, ?, ?, ?, ?)',
        <Object?>[
          userId ?? legacyUserId,
          declaration.deviceId,
          declaration.seasonKey,
          declaration.declaredAt.toUtc().millisecondsSinceEpoch,
          jsonEncode(declaration.toJson()),
        ],
      );
    } catch (e) {
      // Guardar memoria nunca tumba la app, pero en desarrollo se dice: una
      // declaración que no persiste vuelve a preguntar al productor.
      if (kDebugMode) debugPrint('[nutrition] saveDeclaration falló: $e');
    }
  }

  /// Declaración de una temporada, si existe. Con [userId] busca primero la
  /// fila del usuario y, si no la hay, la fila sin dueño (`__legacy__`): una
  /// respuesta dada antes de resolverse la sesión no se pierde.
  Future<NutritionSeasonDeclaration?> loadDeclaration({
    required String deviceId,
    required String seasonKey,
    String? userId,
  }) async {
    try {
      final Database db = await _db;
      final List<Map<String, Object?>> rows = await db.query(
        _declarationsTable,
        columns: <String>['payload', 'user_id'],
        where: userId == null
            ? 'device_id = ? AND season_key = ?'
            : 'device_id = ? AND season_key = ? AND user_id IN (?, ?)',
        whereArgs: userId == null
            ? <Object?>[deviceId, seasonKey]
            : <Object?>[deviceId, seasonKey, userId, legacyUserId],
        orderBy: 'declared_at DESC',
      );
      if (rows.isEmpty) return null;
      // Preferir la fila del usuario sobre la sin dueño.
      Map<String, Object?> pick = rows.first;
      if (userId != null) {
        for (final Map<String, Object?> r in rows) {
          if (r['user_id'] == userId) {
            pick = r;
            break;
          }
        }
      }
      final Object? raw = pick['payload'];
      if (raw is! String) return null;
      return NutritionSeasonDeclaration.tryFromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[nutrition] loadDeclaration falló: $e');
      return null;
    }
  }

  /// Borra la declaración de una temporada (el productor «deshace»).
  Future<void> deleteDeclaration({
    required String deviceId,
    required String seasonKey,
    String? userId,
  }) async {
    try {
      final Database db = await _db;
      await db.delete(
        _declarationsTable,
        where: userId == null
            ? 'device_id = ? AND season_key = ?'
            : 'device_id = ? AND season_key = ? AND user_id = ?',
        whereArgs: userId == null
            ? <Object?>[deviceId, seasonKey]
            : <Object?>[deviceId, seasonKey, userId],
      );
    } catch (_) {
      // Ídem.
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BORRADO
  // ═════════════════════════════════════════════════════════════════════════

  /// Borra la memoria nutricional de un dispositivo.
  Future<void> deleteDevice(String deviceId) async {
    try {
      final Database db = await _db;
      await db.delete(_windowsTable, where: 'device_id = ?', whereArgs: <Object?>[deviceId]);
      await db.delete(_epochsTable, where: 'device_id = ?', whereArgs: <Object?>[deviceId]);
      await db.delete(_declarationsTable, where: 'device_id = ?', whereArgs: <Object?>[deviceId]);
    } catch (_) {
      // Ídem.
    }
  }

  /// Borra todo lo de un usuario (cerrar sesión, eliminar cuenta).
  Future<void> deleteForUser(String userId) async {
    try {
      final Database db = await _db;
      await db.delete(_windowsTable, where: 'user_id = ?', whereArgs: <Object?>[userId]);
      await db.delete(_epochsTable, where: 'user_id = ?', whereArgs: <Object?>[userId]);
      await db.delete(_declarationsTable, where: 'user_id = ?', whereArgs: <Object?>[userId]);
    } catch (_) {
      // Ídem.
    }
  }

  /// Vacía las tablas por completo.
  Future<void> deleteAll() async {
    try {
      final Database db = await _db;
      await db.delete(_windowsTable);
      await db.delete(_epochsTable);
      await db.delete(_declarationsTable);
    } catch (_) {
      // Ídem.
    }
  }
}
