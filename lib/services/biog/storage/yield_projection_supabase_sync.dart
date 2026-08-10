import 'dart:convert';

import 'package:bio_g/models/yield_projection_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Syncs [YieldProjectionConfig] to Supabase as a cloud backup.
///
/// SharedPreferences remains the primary local source of truth.
///
/// Las LECTURAS son best-effort y devuelven vacío ante un fallo. Las
/// ESCRITURAS ([upload], [delete]) NO: propagan la excepción porque su único
/// llamador es `PendingSyncQueue` y ésa es la señal con la que decide
/// conservar y reintentar el pendiente. No volver a envolverlas en
/// `catch (_)` — eso reintroduce la pérdida silenciosa.
class YieldProjectionSupabaseSync {
  static const String _table = 'device_yield_projection_configs';

  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Upload a single yield projection config to Supabase.
  ///
  /// PROPAGA EL ERROR A PROPÓSITO. El único llamador es `PendingSyncQueue`,
  /// cuyo contrato es "lanza = reintenta": la operación pendiente se borra de
  /// la bandeja sólo si el handler termina sin excepción. Con el `catch (_)`
  /// que había aquí, un fallo de red era indistinguible de un éxito y la cola
  /// tiraba la operación al primer intento, dejando la proyección de
  /// rendimiento sin subir para siempre y el backoff sin alcanzar nunca.
  Future<void> upload(YieldProjectionConfig config) async {
    final userId = _userId;
    // Sin sesión no hay escritura posible. Antes era un `return` mudo que la
    // cola leía como confirmación y usaba para descartar el pendiente.
    if (userId == null) {
      throw StateError('yield projection upload: sin sesión');
    }

    await _client
        .from(_table)
        .upsert(_toRow(userId, config), onConflict: 'user_id,device_id');
  }

  /// Upload all configs for the current user.
  Future<void> uploadAll(Map<String, YieldProjectionConfig> configs) async {
    final userId = _userId;
    if (userId == null) return;
    if (configs.isEmpty) return;

    try {
      final rows = configs.values.map((c) => _toRow(userId, c)).toList();

      await _client.from(_table).upsert(rows, onConflict: 'user_id,device_id');
    } catch (_) {
      // Best-effort.
    }
  }

  /// Download all configs for the current user from Supabase.
  Future<Map<String, YieldProjectionConfig>> downloadAll() async {
    final userId = _userId;
    if (userId == null) return <String, YieldProjectionConfig>{};

    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(100);

      final result = <String, YieldProjectionConfig>{};

      for (final row in (data as List<dynamic>)) {
        final m = row as Map<String, dynamic>;
        final deviceId = m['device_id'] as String?;
        if (deviceId == null || deviceId.isEmpty) continue;

        try {
          final configJson = m['config_json'] as String?;
          if (configJson == null || configJson.isEmpty) continue;

          final decoded = jsonDecode(configJson) as Map<String, dynamic>;
          result[deviceId] = YieldProjectionConfig.fromJson(decoded);
        } catch (_) {
          // Skip malformed rows.
        }
      }

      return result;
    } catch (_) {
      return <String, YieldProjectionConfig>{};
    }
  }

  /// Delete a specific device config from Supabase.
  ///
  /// Propaga el error por el mismo motivo que [upload]: sin excepción la cola
  /// da el borrado por hecho y la fila sobrevive en la nube, lista para volver
  /// a bajar en el siguiente `downloadAll`.
  Future<void> delete(String deviceId) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('yield projection delete: sin sesión');
    }

    await _client
        .from(_table)
        .delete()
        .eq('user_id', userId)
        .eq('device_id', deviceId);
  }

  Map<String, dynamic> _toRow(String userId, YieldProjectionConfig config) {
    return <String, dynamic>{
      'user_id': userId,
      'device_id': config.deviceId,
      'crop_id': config.cropId,
      'cultivation_scale_id': config.cultivationScaleId,
      'area_unit': config.areaUnit.name,
      'input_method': config.inputMethod.name,
      'target_yield_ton_per_ha': config.targetYieldTonPerHa,
      'estimated_price_per_ton': config.estimatedPricePerTon,
      'config_json': jsonEncode(config.toJson()),
      'updated_at': config.updatedAt.toIso8601String(),
    };
  }
}
