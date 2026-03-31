import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Syncs [DeviceCropContext] to the `device_crop_contexts` table in Supabase.
///
/// Works as a cloud backup so crop configuration survives app reinstalls.
/// SharedPreferences remains the primary local source of truth.
class CropContextSupabaseSync {
  static const String _table = 'device_crop_contexts';

  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Upload a single crop context to Supabase.
  Future<void> upload(DeviceCropContext context) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _client.from(_table).upsert(
        _toRow(userId, context),
        onConflict: 'user_id,device_id',
      );
    } catch (_) {
      // Best-effort — local storage is the primary source.
    }
  }

  /// Upload all crop contexts for the current user.
  Future<void> uploadAll(Map<String, DeviceCropContext> contexts) async {
    final userId = _userId;
    if (userId == null) return;

    if (contexts.isEmpty) return;

    try {
      final rows = contexts.values
          .map((c) => _toRow(userId, c))
          .toList();

      await _client.from(_table).upsert(
        rows,
        onConflict: 'user_id,device_id',
      );
    } catch (_) {
      // Best-effort.
    }
  }

  /// Download all crop contexts for the current user from Supabase.
  Future<Map<String, DeviceCropContext>> downloadAll() async {
    final userId = _userId;
    if (userId == null) return <String, DeviceCropContext>{};

    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(50);

      final result = <String, DeviceCropContext>{};

      for (final row in (data as List<dynamic>)) {
        final m = row as Map<String, dynamic>;
        final deviceId = m['device_id'] as String?;
        if (deviceId == null) continue;

        try {
          final contextJson = m['context_json'] as String?;
          if (contextJson == null) continue;

          final decoded = jsonDecode(contextJson) as Map<String, dynamic>;
          result[deviceId] = DeviceCropContext.fromJson(decoded);
        } catch (_) {
          // Skip malformed rows.
        }
      }

      return result;
    } catch (_) {
      return <String, DeviceCropContext>{};
    }
  }

  /// Delete a specific device's crop context from Supabase.
  Future<void> delete(String deviceId) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _client
          .from(_table)
          .delete()
          .eq('user_id', userId)
          .eq('device_id', deviceId);
    } catch (_) {
      // Best-effort.
    }
  }

  Map<String, dynamic> _toRow(String userId, DeviceCropContext context) {
    return <String, dynamic>{
      'user_id': userId,
      'device_id': context.deviceId,
      'crop_id': context.cropId,
      'profile_id': context.profileId,
      'lifecycle_status': context.lifecycleStatus.name,
      'context_json': jsonEncode(context.toJson()),
      'updated_at': context.updatedAt.toIso8601String(),
    };
  }
}
