import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/services/biog/storage/crop_context_storage.dart';

class SharedPrefsCropContextStorage implements CropContextStorage {
  static const String _key = 'biog_device_crop_contexts_v1';

  @override
  Future<Map<String, DeviceCropContext>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String, DeviceCropContext>{};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final result = <String, DeviceCropContext>{};

    decoded.forEach((deviceId, value) {
      result[deviceId] = DeviceCropContext.fromJson(
        value as Map<String, dynamic>,
      );
    });

    return result;
  }

  @override
  Future<void> save(DeviceCropContext context) async {
    final all = await loadAll();
    all[context.deviceId] = context;
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

  Future<void> _writeAll(Map<String, DeviceCropContext> all) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = <String, dynamic>{};
    all.forEach((key, value) {
      encoded[key] = value.toJson();
    });

    await prefs.setString(_key, jsonEncode(encoded));
  }
}
