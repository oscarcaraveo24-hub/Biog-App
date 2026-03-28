import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Persists telemetry history per device using SharedPreferences.
///
/// Each device's history is stored under its own key to keep reads/writes
/// scoped and fast. A cap prevents unbounded growth.
class TelemetryLocalStorage {
  static const String _prefix = 'biog_telemetry_v1_';
  static const int defaultCap = 2000;

  final int cap;

  TelemetryLocalStorage({this.cap = defaultCap});

  String _keyFor(String deviceId) => '$_prefix$deviceId';

  /// Load all persisted telemetry for [deviceId], ordered by timestamp.
  Future<List<BioGTelemetry>> load(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(deviceId));
    if (raw == null || raw.isEmpty) return <BioGTelemetry>[];

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final list = decoded
        .map((e) => BioGTelemetry.fromJson(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  /// Persist a full telemetry list for [deviceId], trimming to [cap].
  Future<void> save(String deviceId, List<BioGTelemetry> history) async {
    final prefs = await SharedPreferences.getInstance();

    List<BioGTelemetry> toSave = history;
    if (toSave.length > cap) {
      toSave = toSave.sublist(toSave.length - cap);
    }

    final encoded = jsonEncode(
      toSave.map((t) => t.toJson()).toList(growable: false),
    );
    await prefs.setString(_keyFor(deviceId), encoded);
  }

  /// Append a single reading and persist (debounce-friendly).
  Future<void> append(String deviceId, BioGTelemetry reading) async {
    final existing = await load(deviceId);
    existing.add(reading);
    await save(deviceId, existing);
  }

  /// Remove persisted data for a device.
  Future<void> delete(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(deviceId));
  }
}
