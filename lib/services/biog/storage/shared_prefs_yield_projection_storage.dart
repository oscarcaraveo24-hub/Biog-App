import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:bio_g/models/yield_projection_config.dart';
import 'package:bio_g/services/biog/storage/yield_projection_storage.dart';

/// SharedPreferences-backed implementation with per-user namespacing.
/// See [SharedPrefsCropContextStorage] for the contract — signing out
/// of user A must not leak their yield projection config into user B's
/// session.
///
/// Storage layout:
///   `biog_yield_projection_configs_v2_{userId}` — authenticated user
///   `biog_yield_projection_configs_v2__guest`   — guest / unauthenticated
class SharedPrefsYieldProjectionStorage implements YieldProjectionStorage {
  static const String _prefix = 'biog_yield_projection_configs_v2_';
  static const String _guestKey = 'biog_yield_projection_configs_v2__guest';

  String _keyFor(String? userId) {
    if (userId == null || userId.isEmpty) return _guestKey;
    return '$_prefix$userId';
  }

  @override
  Future<Map<String, YieldProjectionConfig>> loadAll({
    required String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(userId));
    if (raw == null || raw.isEmpty) {
      return <String, YieldProjectionConfig>{};
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, YieldProjectionConfig>{};

      decoded.forEach((deviceId, value) {
        try {
          result[deviceId] = YieldProjectionConfig.fromJson(
            value as Map<String, dynamic>,
          );
        } catch (_) {
          // Skip malformed entries.
        }
      });

      return result;
    } catch (_) {
      return <String, YieldProjectionConfig>{};
    }
  }

  @override
  Future<void> save(
    YieldProjectionConfig config, {
    required String? userId,
  }) async {
    final all = await loadAll(userId: userId);
    all[config.deviceId] = config;
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
    Map<String, YieldProjectionConfig> all, {
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
