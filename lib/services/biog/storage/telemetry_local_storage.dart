import 'dart:convert';

import 'package:bio_g/models/biog_telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists telemetry history per device using SharedPreferences.
///
/// Local storage is the app's primary source of truth.
/// Supabase and future Bluetooth sync should merge incoming readings here.
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

    if (raw == null || raw.isEmpty) {
      return <BioGTelemetry>[];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      final list = <BioGTelemetry>[];
      for (final row in decoded) {
        if (row is! Map) continue;
        final telemetry = BioGTelemetry.tryFromJson(
          Map<String, dynamic>.from(row),
        );
        if (telemetry != null) list.add(telemetry);
      }

      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    } catch (_) {
      // Corrupted local cache should not break the app.
      // Return empty and let cloud/Bluetooth sync repopulate it.
      return <BioGTelemetry>[];
    }
  }

  /// Load telemetry for [deviceId] inside the given time [window].
  Future<List<BioGTelemetry>> loadWindow(
    String deviceId, {
    required Duration window,
  }) async {
    final since = DateTime.now().toUtc().subtract(window);
    final history = await load(deviceId);

    return history
        .where((t) => !t.timestamp.toUtc().isBefore(since))
        .toList(growable: false);
  }

  /// Returns the latest locally persisted telemetry reading for [deviceId].
  Future<BioGTelemetry?> latest(String deviceId) async {
    final history = await load(deviceId);
    if (history.isEmpty) return null;
    return history.last;
  }

  /// Persist a full telemetry list for [deviceId], trimming to [cap].
  ///
  /// This method also normalizes ordering and removes duplicates by:
  /// deviceId + timestamp.
  Future<void> save(String deviceId, List<BioGTelemetry> history) async {
    final prefs = await SharedPreferences.getInstance();

    final normalized = _normalize(deviceId, history);
    final toSave = _trimToCap(normalized);

    final encoded = jsonEncode(
      toSave.map((t) => t.toJson()).toList(growable: false),
    );

    await prefs.setString(_keyFor(deviceId), encoded);
  }

  /// Merge incoming readings with local history and persist.
  ///
  /// This is the main method for offline-first sync:
  /// - Supabase downloads should use this.
  /// - Future Bluetooth batches should use this.
  /// - Upload retries can safely call this without duplicating readings.
  Future<List<BioGTelemetry>> mergeAndSave(
    String deviceId,
    List<BioGTelemetry> incoming,
  ) async {
    if (incoming.isEmpty) {
      return load(deviceId);
    }

    final existing = await load(deviceId);
    final merged = <BioGTelemetry>[...existing, ...incoming];

    final normalized = _normalize(deviceId, merged);
    final toSave = _trimToCap(normalized);

    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      toSave.map((t) => t.toJson()).toList(growable: false),
    );

    await prefs.setString(_keyFor(deviceId), encoded);
    return toSave;
  }

  /// Append a single reading and persist.
  ///
  /// Internally uses [mergeAndSave] to avoid duplicates.
  Future<void> append(String deviceId, BioGTelemetry reading) async {
    await mergeAndSave(deviceId, <BioGTelemetry>[reading]);
  }

  /// Remove persisted data for a device.
  Future<void> delete(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(deviceId));
  }

  List<BioGTelemetry> _normalize(
    String deviceId,
    List<BioGTelemetry> readings,
  ) {
    final byKey = <String, BioGTelemetry>{};

    for (final reading in readings) {
      if (reading.deviceId != deviceId) continue;

      final key = _readingKey(reading);
      byKey[key] = reading;
    }

    final normalized = byKey.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return normalized;
  }

  List<BioGTelemetry> _trimToCap(List<BioGTelemetry> readings) {
    if (readings.length <= cap) return readings;
    return readings.sublist(readings.length - cap);
  }

  String _readingKey(BioGTelemetry reading) {
    return '${reading.deviceId}_${reading.timestamp.toUtc().toIso8601String()}';
  }
}
