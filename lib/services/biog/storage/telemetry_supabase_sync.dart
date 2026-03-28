import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Syncs telemetry to the `telemetry_backup` table in Supabase.
///
/// Used as a cloud backup so data survives app reinstalls or device resets.
/// Local storage (SharedPreferences) remains the primary source of truth.
class TelemetrySupabaseSync {
  static const String _table = 'telemetry_backup';

  SupabaseClient get _client => Supabase.instance.client;

  /// Upload a batch of telemetry rows. Skips duplicates by timestamp+device.
  Future<void> uploadBatch(List<BioGTelemetry> readings) async {
    if (readings.isEmpty) return;

    final rows = readings.map((t) => <String, dynamic>{
      'device_id': t.deviceId,
      'timestamp': t.timestamp.toIso8601String(),
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
    }).toList();

    try {
      await _client.from(_table).upsert(
        rows,
        onConflict: 'device_id,timestamp',
      );
    } catch (_) {
      // Silently fail — local storage is the primary source.
      // Sync will retry on the next batch.
    }
  }

  /// Download all telemetry for [deviceId] from Supabase, ordered by time.
  Future<List<BioGTelemetry>> download(String deviceId) async {
    try {
      final data = await _client
          .from(_table)
          .select()
          .eq('device_id', deviceId)
          .order('timestamp', ascending: true)
          .limit(2000);

      return (data as List<dynamic>)
          .map((row) => BioGTelemetry.fromJson(_mapRow(row)))
          .toList();
    } catch (_) {
      return <BioGTelemetry>[];
    }
  }

  /// Delete all backup data for a device.
  Future<void> delete(String deviceId) async {
    try {
      await _client.from(_table).delete().eq('device_id', deviceId);
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  /// Maps a Supabase row to the format expected by BioGTelemetry.fromJson.
  static Map<String, dynamic> _mapRow(dynamic row) {
    final m = row as Map<String, dynamic>;
    return <String, dynamic>{
      'device_id': m['device_id'],
      'timestamp': m['timestamp'],
      'air_temp_c': m['air_temp_c'] ?? 0,
      'air_humidity_pct': m['air_humidity_pct'] ?? 0,
      'soil_moisture_pct': m['soil_moisture_pct'] ?? 0,
      'soil_temp_c': m['soil_temp_c'] ?? 0,
      'ph': m['ph'] ?? 0,
      'ec': m['ec'] ?? 0,
      'resistance': m['resistance'] ?? 0,
      'n': m['n'] ?? 0,
      'p': m['p'] ?? 0,
      'k': m['k'] ?? 0,
      'battery_pct': m['battery_pct'] ?? 0,
      'signal_rssi': m['signal_rssi'] ?? 0,
    };
  }
}
