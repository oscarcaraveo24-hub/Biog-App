import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:bio_g/models/yield_projection_config.dart';
import 'package:bio_g/services/biog/storage/yield_projection_storage.dart';

class SharedPrefsYieldProjectionStorage implements YieldProjectionStorage {
  static const String _key = 'biog_yield_projection_configs_v1';

  @override
  Future<Map<String, YieldProjectionConfig>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return <String, YieldProjectionConfig>{};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final result = <String, YieldProjectionConfig>{};

    decoded.forEach((deviceId, value) {
      result[deviceId] = YieldProjectionConfig.fromJson(
        value as Map<String, dynamic>,
      );
    });

    return result;
  }

  @override
  Future<void> save(YieldProjectionConfig config) async {
    final all = await loadAll();
    all[config.deviceId] = config;
    await _writeAll(all);
  }

  @override
  Future<void> delete(String deviceId) async {
    final all = await loadAll();
    all.remove(deviceId);
    await _writeAll(all);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _writeAll(Map<String, YieldProjectionConfig> all) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = <String, dynamic>{};
    all.forEach((key, value) {
      encoded[key] = value.toJson();
    });

    await prefs.setString(_key, jsonEncode(encoded));
  }
}
