import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bio_g/models/biog_telemetry.dart';

/// When `true`, every read/write against the telemetry table prints a
/// `[BioG/Telemetry]` line with the device id, table, row count, and
/// (for the latest read) the parsed battery/RSSI. Already gated by
/// [kDebugMode], so the prints disappear in release builds.
///
/// Flip this to `false` to silence the per-poll output during normal
/// development.
const bool kBioGTelemetryDebugLogs = true;

/// Syncs telemetry with the official `telemetry` table in Supabase.
///
/// Local storage remains the primary source of truth for the app.
/// Supabase is used as cloud sync / remote history for online scenarios.
class TelemetrySupabaseSync {
  static const String _table = 'telemetry';
  static const int _defaultLimit = 2000;
  static const List<String> _timeColumns = <String>['timestamp', 'created_at'];
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  SupabaseClient get _client => Supabase.instance.client;

  static bool isValidTelemetryDeviceId(String value) {
    return _uuidPattern.hasMatch(value.trim());
  }

  void _log(String message) {
    if (!kDebugMode) return;
    if (!kBioGTelemetryDebugLogs) return;
    debugPrint('[BioG/Telemetry] $message');
  }

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
      _log('upload table=$_table rows=${rows.length}');
      await _client
          .from(_table)
          .upsert(rows, onConflict: 'device_id,timestamp');
    } catch (e) {
      _log('upload error table=$_table rows=${rows.length} error=$e');
      // Local storage is the primary source of truth.
      // Cloud sync is best-effort and can retry later.
    }
  }

  /// Downloads the latest telemetry row for [deviceId].
  Future<BioGTelemetry?> downloadLatest(String deviceId) async {
    final normalizedDeviceId = deviceId.trim();
    if (normalizedDeviceId.isEmpty) return null;
    if (!isValidTelemetryDeviceId(normalizedDeviceId)) {
      _log(
        'latest skipped table=$_table device_id=$normalizedDeviceId '
        'reason=not_uuid',
      );
      return null;
    }

    for (final timeColumn in _timeColumns) {
      try {
        _log(
          'latest query table=$_table device_id=$normalizedDeviceId '
          'order_by=$timeColumn desc limit=1',
        );

        final data = await _client
            .from(_table)
            .select()
            .eq('device_id', normalizedDeviceId)
            .order(timeColumn, ascending: false)
            .limit(1);

        final rows = _rowsFrom(data);
        if (rows.isEmpty) {
          _log(
            'latest empty table=$_table device_id=$normalizedDeviceId '
            'order_by=$timeColumn rows=0',
          );
          continue;
        }

        final telemetry = _telemetryFromRow(
          rows.first,
          deviceId: normalizedDeviceId,
          source: 'latest/$timeColumn',
          preferLatestTimestamp: true,
        );

        if (telemetry != null) {
          _logLatestFound(telemetry, rows.length, timeColumn);
          return telemetry;
        }

        _log(
          'latest parse_failed table=$_table device_id=$normalizedDeviceId '
          'order_by=$timeColumn rows=${rows.length}',
        );
      } catch (e) {
        _log(
          'latest error table=$_table device_id=$normalizedDeviceId '
          'order_by=$timeColumn error=$e',
        );
      }
    }

    return null;
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
    final normalizedDeviceId = deviceId.trim();
    if (normalizedDeviceId.isEmpty) return <BioGTelemetry>[];
    if (!isValidTelemetryDeviceId(normalizedDeviceId)) {
      _log(
        'history skipped table=$_table device_id=$normalizedDeviceId '
        'reason=not_uuid',
      );
      return <BioGTelemetry>[];
    }

    final sinceIso = since.toUtc().toIso8601String();

    for (final timeColumn in _timeColumns) {
      try {
        _log(
          'history query table=$_table device_id=$normalizedDeviceId '
          'since=$sinceIso order_by=$timeColumn asc limit=$limit',
        );

        final data = await _client
            .from(_table)
            .select()
            .eq('device_id', normalizedDeviceId)
            .gte(timeColumn, sinceIso)
            .order(timeColumn, ascending: true)
            .limit(limit);

        final rows = _rowsFrom(data);
        final parsed = _telemetryListFromRows(
          rows,
          deviceId: normalizedDeviceId,
          source: 'history/$timeColumn',
        );

        _log(
          'history result table=$_table device_id=$normalizedDeviceId '
          'order_by=$timeColumn rows=${rows.length} parsed=${parsed.length}',
        );

        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (e) {
        _log(
          'history error table=$_table device_id=$normalizedDeviceId '
          'order_by=$timeColumn error=$e',
        );
      }
    }

    return <BioGTelemetry>[];
  }

  /// Downloads recent telemetry for [deviceId], ordered by time.
  ///
  /// Kept for backwards compatibility with existing code.
  Future<List<BioGTelemetry>> download(String deviceId) async {
    final normalizedDeviceId = deviceId.trim();
    if (normalizedDeviceId.isEmpty) return <BioGTelemetry>[];
    if (!isValidTelemetryDeviceId(normalizedDeviceId)) {
      _log(
        'download skipped table=$_table device_id=$normalizedDeviceId '
        'reason=not_uuid',
      );
      return <BioGTelemetry>[];
    }

    for (final timeColumn in _timeColumns) {
      try {
        _log(
          'download query table=$_table device_id=$normalizedDeviceId '
          'order_by=$timeColumn asc limit=$_defaultLimit',
        );

        final data = await _client
            .from(_table)
            .select()
            .eq('device_id', normalizedDeviceId)
            .order(timeColumn, ascending: true)
            .limit(_defaultLimit);

        final rows = _rowsFrom(data);
        final parsed = _telemetryListFromRows(
          rows,
          deviceId: normalizedDeviceId,
          source: 'download/$timeColumn',
        );

        _log(
          'download result table=$_table device_id=$normalizedDeviceId '
          'order_by=$timeColumn rows=${rows.length} parsed=${parsed.length}',
        );

        if (parsed.isNotEmpty) {
          return parsed;
        }
      } catch (e) {
        _log(
          'download error table=$_table device_id=$normalizedDeviceId '
          'order_by=$timeColumn error=$e',
        );
      }
    }

    return <BioGTelemetry>[];
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

  List<Map<String, dynamic>> _rowsFrom(dynamic data) {
    final rawRows = data as List<dynamic>;
    final rows = <Map<String, dynamic>>[];

    for (final row in rawRows) {
      if (row is Map) {
        rows.add(Map<String, dynamic>.from(row));
      }
    }

    return rows;
  }

  List<BioGTelemetry> _telemetryListFromRows(
    List<Map<String, dynamic>> rows, {
    required String deviceId,
    required String source,
  }) {
    final parsed = <BioGTelemetry>[];

    for (final row in rows) {
      final telemetry = _telemetryFromRow(
        row,
        deviceId: deviceId,
        source: source,
      );
      if (telemetry != null) parsed.add(telemetry);
    }

    parsed.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return parsed;
  }

  BioGTelemetry? _telemetryFromRow(
    Map<String, dynamic> row, {
    required String deviceId,
    required String source,
    bool preferLatestTimestamp = false,
  }) {
    final mapped = _mapRow(
      row,
      preferLatestTimestamp: preferLatestTimestamp,
    );
    final telemetry = BioGTelemetry.tryFromJson(mapped);

    if (telemetry == null) {
      _log(
        'parse_failed source=$source table=$_table device_id=$deviceId '
        'row_device_id=${row['device_id']} timestamp=${row['timestamp']} '
        'created_at=${row['created_at']} battery_pct=${row['battery_pct']} '
        'signal_rssi=${row['signal_rssi']}',
      );
    }

    return telemetry;
  }

  void _logLatestFound(
    BioGTelemetry telemetry,
    int rowCount,
    String timeColumn,
  ) {
    _log(
      'latest found table=$_table device_id=${telemetry.deviceId} '
      'order_by=$timeColumn rows=$rowCount timestamp=${telemetry.timestamp.toIso8601String()} '
      'battery_pct=${telemetry.batteryPct} signal_rssi=${telemetry.signalRssi}',
    );
  }

  /// Maps a Supabase row to the format expected by BioGTelemetry.
  static Map<String, dynamic> _mapRow(
    Map<String, dynamic> m, {
    bool preferLatestTimestamp = false,
  }) {
    return <String, dynamic>{
      'device_id': m['device_id'] ?? m['deviceId'],
      'timestamp': preferLatestTimestamp
          ? _latestTimestampIso(m)
          : (m['timestamp'] ??
                m['created_at'] ??
                m['createdAt'] ??
                m['recorded_at']),
      'created_at': m['created_at'] ?? m['createdAt'],
      'recorded_at': m['recorded_at'],
      'air_temp_c': _asNullableDouble(
        m['air_temp_c'] ??
            m['airTempC'] ??
            m['temperature'] ??
            m['temperature_c'] ??
            m['air_temperature'] ??
            m['ambient_temperature'] ??
            m['temp_c'] ??
            m['temp'],
      ),
      'air_humidity_pct': _asNullableDouble(
        m['air_humidity_pct'] ??
            m['airHumidityPct'] ??
            m['air_humidity'] ??
            m['humidity_pct'] ??
            m['humidity'] ??
            m['hum'],
      ),
      'soil_moisture_pct': _asNullableDouble(
        m['soil_moisture_pct'] ??
            m['soilMoisturePct'] ??
            m['soil_moisture'] ??
            m['soil_humidity'] ??
            m['soilHumidity'] ??
            m['moisture'] ??
            m['humidity_soil'] ??
            m['humedad_suelo'],
      ),
      'soil_temp_c': _asNullableDouble(
        m['soil_temp_c'] ??
            m['soilTempC'] ??
            m['soil_temp'] ??
            m['soil_temperature'] ??
            m['soilTemperature'] ??
            m['soil_temperature_c'] ??
            m['ground_temperature'],
      ),
      'ph': _asNullableDouble(
        m['ph'] ?? m['pH'] ?? m['PH'] ?? m['pg'] ?? m['PG'],
      ),
      'ec': _asNullableDouble(
        m['ec'] ??
            m['Ec'] ??
            m['EC'] ??
            m['conductivity'] ??
            m['electrical_conductivity'],
      ),
      'resistance': _asNullableDouble(
        m['resistance'] ??
            m['rt'] ??
            m['RT'] ??
            m['soil_resistance'] ??
            m['resistance_mpa'],
      ),
      'n': _asNullableDouble(
        m['n'] ?? m['N'] ?? m['nitrogen'] ?? m['nitrogen_ppm'],
      ),
      'p': _asNullableDouble(
        m['p'] ?? m['P'] ?? m['phosphorus'] ?? m['phosphorus_ppm'],
      ),
      'k': _asNullableDouble(
        m['k'] ?? m['K'] ?? m['potassium'] ?? m['potassium_ppm'],
      ),
      'battery_pct': m['battery_pct'],
      'batteryPct': m['batteryPct'],
      'battery_percent': m['battery_percent'],
      'signal_rssi': m['signal_rssi'],
      'signalRssi': m['signalRssi'],
      'rssi': m['rssi'],
      'has_sensor_data': _hasAnySensorRawField(m),
    };
  }

  static String? _latestTimestampIso(Map<String, dynamic> m) {
    final dates = <DateTime>[];

    for (final value in <dynamic>[
      m['timestamp'],
      m['created_at'],
      m['createdAt'],
      m['recorded_at'],
    ]) {
      final parsed = _asDateTime(value);
      if (parsed != null) dates.add(parsed.toUtc());
    }

    if (dates.isEmpty) return null;
    dates.sort((a, b) => b.compareTo(a));
    return dates.first.toIso8601String();
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;

    final hasExplicitZone =
        text.endsWith('Z') ||
        text.endsWith('z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(text);

    final normalized = hasExplicitZone ? text : '${text}Z';
    return DateTime.tryParse(normalized);
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return double.tryParse(text);
  }

  static bool _hasAnySensorRawField(Map<String, dynamic> row) {
    const keys = <String>[
      'npk',
      'NPK',
      'n',
      'N',
      'p',
      'P',
      'k',
      'K',
      'nitrogen',
      'nitrogen_ppm',
      'phosphorus',
      'phosphorus_ppm',
      'potassium',
      'potassium_ppm',
      'air_temp_c',
      'airTempC',
      'temperature_c',
      'air_temperature',
      'ambient_temperature',
      'temp_c',
      'temp',
      'air_humidity_pct',
      'airHumidityPct',
      'air_humidity',
      'humidity_pct',
      'hum',
      'soil_moisture_pct',
      'soilMoisturePct',
      'soil_moisture',
      'soil_humidity',
      'soilHumidity',
      'moisture',
      'humidity_soil',
      'humedad_suelo',
      'soil_temp_c',
      'soilTempC',
      'soil_temperature',
      'soilTemperature',
      'soil_temperature_c',
      'soil_temp',
      'ground_temperature',
      'temperature',
      'humidity',
      'ph',
      'pH',
      'PH',
      'pg',
      'PG',
      'ec',
      'Ec',
      'EC',
      'rt',
      'RT',
      'resistance',
    ];

    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return true;
    }
    return false;
  }
}
