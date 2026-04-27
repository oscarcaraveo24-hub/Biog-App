import 'package:bio_g/models/biog_telemetry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Syncs telemetry with the official `telemetry` table in Supabase.
///
/// Local storage remains the primary source of truth for the app.
/// Supabase is used as cloud sync / remote history for online scenarios.
class TelemetrySupabaseSync {
  static const String _table = 'telemetry';
  static const int _defaultLimit = 2000;

  SupabaseClient get _client => Supabase.instance.client;

  /// Upload a batch of telemetry rows.
  ///
  /// Requires a unique index in Supabase:
  /// device_id + timestamp
  ///
  /// Recommended SQL:
  /// create unique index if not exists uq_telemetry_device_timestamp
  /// on public.telemetry (device_id, timestamp);
  Future<void> uploadBatch(List<BioGTelemetry> readings) async {
    if (readings.isEmpty) return;

    final rows = readings.map(_toSupabaseRow).toList();

    try {
      await _client
          .from(_table)
          .upsert(rows, onConflict: 'device_id,timestamp');
    } catch (_) {
      // Local storage is the primary source of truth.
      // Cloud sync is best-effort and can retry later.
    }
  }

  /// Downloads the latest telemetry row for [deviceId].
  Future<BioGTelemetry?> downloadLatest(String deviceId) async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('device_id', deviceId)
          .order('timestamp', ascending: false)
          .limit(1);

      final rows = data as List<dynamic>;
      if (rows.isEmpty) return null;

      return BioGTelemetry.fromJson(_mapRow(rows.first));
    } catch (_) {
      return null;
    }
  }

  /// Downloads telemetry for [deviceId] inside the given time [window].
  Future<List<BioGTelemetry>> downloadWindow(
    String deviceId, {
    required Duration window,
    int limit = _defaultLimit,
  }) async {
    final since = DateTime.now().toUtc().subtract(window);
    return downloadSince(deviceId, since: since, limit: limit);
  }

  /// Downloads telemetry for [deviceId] since a specific [since] timestamp.
  Future<List<BioGTelemetry>> downloadSince(
    String deviceId, {
    required DateTime since,
    int limit = _defaultLimit,
  }) async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('device_id', deviceId)
          .gte('timestamp', since.toUtc().toIso8601String())
          .order('timestamp', ascending: true)
          .limit(limit);

      return (data as List<dynamic>)
          .map((row) => BioGTelemetry.fromJson(_mapRow(row)))
          .toList();
    } catch (_) {
      return <BioGTelemetry>[];
    }
  }

  /// Downloads recent telemetry for [deviceId], ordered by time.
  ///
  /// Kept for backwards compatibility with existing code.
  Future<List<BioGTelemetry>> download(String deviceId) async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('device_id', deviceId)
          .order('timestamp', ascending: true)
          .limit(_defaultLimit);

      return (data as List<dynamic>)
          .map((row) => BioGTelemetry.fromJson(_mapRow(row)))
          .toList();
    } catch (_) {
      return <BioGTelemetry>[];
    }
  }

  /// Delete all cloud telemetry data for a device.
  ///
  /// This is best-effort. In production, regular users may not have DELETE
  /// permission depending on RLS policies.
  Future<void> delete(String deviceId) async {
    try {
      await _client.from(_table).delete().eq('device_id', deviceId);
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  static Map<String, dynamic> _toSupabaseRow(BioGTelemetry t) {
    return <String, dynamic>{
      'device_id': t.deviceId,
      'timestamp': t.timestamp.toUtc().toIso8601String(),
      'air_temp_c': t.airTempC,
      'air_humidity_pct': t.airHumidityPct,
      'soil_moisture_pct': t.soilMoisturePct,
      'soil_temp_c': t.soilTempC,
      'ph': t.ph,
      'ec': t.ec,
      'resistance': t.resistance,
      'n': t.n,
      'p': t.p,
      'k': t.k,
      'battery_pct': t.batteryPct,
      'signal_rssi': t.signalRssi,
    };
  }

  /// Maps a Supabase row to the format expected by BioGTelemetry.fromJson.
  static Map<String, dynamic> _mapRow(dynamic row) {
    final m = row as Map<String, dynamic>;

    return <String, dynamic>{
      'device_id': m['device_id'],
      'timestamp': m['timestamp'],
      'air_temp_c': _asDouble(m['air_temp_c']),
      'air_humidity_pct': _asDouble(m['air_humidity_pct']),
      'soil_moisture_pct': _asDouble(m['soil_moisture_pct']),
      'soil_temp_c': _asDouble(m['soil_temp_c']),
      'ph': _asDouble(m['ph']),
      'ec': _asDouble(m['ec']),
      'resistance': _asDouble(m['resistance']),
      'n': _asDouble(m['n']),
      'p': _asDouble(m['p']),
      'k': _asDouble(m['k']),
      'battery_pct': _asDouble(m['battery_pct']),
      'signal_rssi': _asInt(m['signal_rssi']),
    };
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }
}
