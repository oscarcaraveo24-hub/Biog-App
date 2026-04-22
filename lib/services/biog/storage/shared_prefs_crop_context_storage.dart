import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/services/biog/storage/crop_context_storage.dart';

/// SharedPreferences-backed implementation that namespaces every
/// record by the current user. Each user gets an isolated key so
/// signing out of A and signing in as B cannot surface A's crop
/// contexts in B's session.
///
/// Storage layout:
///   `biog_device_crop_contexts_v2_{userId}` — authenticated user
///   `biog_device_crop_contexts_v2__guest`   — unauthenticated / guest
///
/// Note: the legacy key `biog_device_crop_contexts_v1` (global, not
/// namespaced) is intentionally abandoned. Any data written under it
/// was already mirrored in Supabase and will be re-hydrated from there
/// on the next successful sync.
class SharedPrefsCropContextStorage implements CropContextStorage {
  static const String _prefix = 'biog_device_crop_contexts_v2_';
  static const String _guestKey = 'biog_device_crop_contexts_v2__guest';

  String _keyFor(String? userId) {
    if (userId == null || userId.isEmpty) return _guestKey;
    return '$_prefix$userId';
  }

  @override
  Future<Map<String, DeviceCropContext>> loadAll({
    required String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(userId));
    if (raw == null || raw.isEmpty) return <String, DeviceCropContext>{};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, DeviceCropContext>{};

      decoded.forEach((deviceId, value) {
        try {
          result[deviceId] = DeviceCropContext.fromJson(
            value as Map<String, dynamic>,
          );
        } catch (_) {
          // Skip malformed entries rather than poisoning the whole load.
        }
      });

      return result;
    } catch (_) {
      return <String, DeviceCropContext>{};
    }
  }

  @override
  Future<void> save(
    DeviceCropContext context, {
    required String? userId,
  }) async {
    final all = await loadAll(userId: userId);
    all[context.deviceId] = context;
    await _writeAll(all, userId: userId);
  }

  @override
  Future<void> delete(String deviceId, {required String? userId}) async {
    final all = await loadAll(userId: userId);
    all.remove(deviceId);
    await _writeAll(all, userId: userId);
  }

  @override
  Future<void> clearAll({required String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(userId));
  }

  Future<void> _writeAll(
    Map<String, DeviceCropContext> all, {
    required String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = <String, dynamic>{};
    all.forEach((key, value) {
      encoded[key] = value.toJson();
    });

    await prefs.setString(_keyFor(userId), jsonEncode(encoded));
  }
}
