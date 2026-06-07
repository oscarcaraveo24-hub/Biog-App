// lib/models/biog_telemetry.dart
import 'package:flutter/foundation.dart';

enum BioGDeviceStatus { pendingConfig, active, offline }

enum BioGAlertSeverity { info, warning, critical }

enum BioGAlertType {
  lowSoilMoisture,
  highSoilMoisture,
  phOutOfRange,
  ecOutOfRange,
  tempExtreme,
  sensorOffline,
  stageEvent,
  airTempExtreme,
  highHumidity,
}

final RegExp _bioGTelemetryDeviceIdPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

@immutable
class BioGDevice {
  const BioGDevice({
    required this.id,
    required this.name,
    required this.locationName,
    required this.seedId,
    required this.profileId,
    this.deviceModelId,
    this.telemetryDeviceIdOverride,
    this.status = BioGDeviceStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String locationName;

  /// Campo LEGACY conservado por compatibilidad con flujos viejos.
  ///
  /// No debe usarse como fuente de verdad del cultivo activo.
  /// El contexto real por dispositivo vive en [DeviceCropContext] vía BioGStore.
  final String seedId;

  /// Campo LEGACY conservado por compatibilidad con flujos viejos.
  ///
  /// No debe usarse como fuente de verdad del perfil activo.
  /// El perfil real debe resolverse desde [DeviceCropContext].
  final String profileId;

  /// Modelo comercial del dispositivo (`campo`, `huerto`, `maceta`).
  final String? deviceModelId;

  /// Real UUID used by `telemetry.device_id` when the UI/local device id
  /// does not match the telemetry key.
  ///
  /// Legacy UI ids such as `biog-...` can still exist in Cuenta, but they
  /// must never be used to query the `telemetry` table.
  final String? telemetryDeviceIdOverride;

  final BioGDeviceStatus status;
  final DateTime? createdAt;

  /// Marca de última modificación usada para last-write-wins al
  /// reconciliar el caché local contra el remoto en Supabase. Cae en
  /// `createdAt` si el backend no informa `updated_at`.
  final DateTime? updatedAt;

  /// Device id accepted by the Supabase `telemetry.device_id` UUID column.
  /// Legacy local ids such as `biog-...` are valid UI identities, but they
  /// must not be used for telemetry queries.
  String? get telemetryDeviceId {
    final override = telemetryDeviceIdOverride?.trim();
    if (override != null && isTelemetryDeviceId(override)) return override;

    final normalized = id.trim();
    if (isTelemetryDeviceId(normalized)) return normalized;
    return null;
  }

  static bool isTelemetryDeviceId(String value) {
    return _bioGTelemetryDeviceIdPattern.hasMatch(value.trim());
  }

  BioGDevice copyWith({
    String? id,
    String? name,
    String? locationName,
    String? seedId,
    String? profileId,
    Object? deviceModelId = _bioGDeviceSentinel,
    Object? telemetryDeviceIdOverride = _bioGDeviceSentinel,
    BioGDeviceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BioGDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      locationName: locationName ?? this.locationName,
      seedId: seedId ?? this.seedId,
      profileId: profileId ?? this.profileId,
      deviceModelId: identical(deviceModelId, _bioGDeviceSentinel)
          ? this.deviceModelId
          : deviceModelId as String?,
      telemetryDeviceIdOverride:
          identical(telemetryDeviceIdOverride, _bioGDeviceSentinel)
          ? this.telemetryDeviceIdOverride
          : telemetryDeviceIdOverride as String?,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const Object _bioGDeviceSentinel = Object();

@immutable
class BioGTelemetry {
  const BioGTelemetry({
    required this.deviceId,
    required this.timestamp,
    required this.airTempC,
    required this.airHumidityPct,
    required this.soilMoisturePct,
    required this.soilTempC,
    required this.ph,
    required this.ec,
    required this.resistance,
    required this.n,
    required this.p,
    required this.k,
    required this.batteryPct,
    required this.signalRssi,
    this.hasSoilMoistureData = true,
    this.hasSoilTempData = true,
    this.hasPhData = true,
    this.hasResistanceData = true,
    this.hasNitrogenData = true,
    this.hasPhosphorusData = true,
    this.hasPotassiumData = true,
    this.hasSensorData = true,
  });

  final String deviceId;
  final DateTime timestamp;

  // Ambiente
  final double airTempC; // °C
  final double airHumidityPct; // %

  // Suelo
  final double soilMoisturePct; // %
  final double soilTempC; // °C
  final double ph; // 0–14
  final double ec; // mS/cm (o la unidad que uses)
  final double resistance; //Mpa (compactacion suelo)

  final bool hasSoilMoistureData;
  final bool hasSoilTempData;
  final bool hasPhData;
  final bool hasResistanceData;

  // Nutrientes
  final double n; // ppm (ejemplo)
  final double p; // ppm
  final double k; // ppm

  /// Presence flags preserve the difference between a real `0` and a
  /// nutrient that was absent from the source payload.
  final bool hasNitrogenData;
  final bool hasPhosphorusData;
  final bool hasPotassiumData;

  // Estado dispositivo
  final double? batteryPct; // %
  final int? signalRssi; // dBm (ejemplo -40 bueno, -90 malo)

  /// True when at least one real sensor field was present in the source
  /// payload. This lets account hardware status distinguish "battery/RSSI
  /// only" rows from actual telemetry rows without changing the numeric
  /// fields used elsewhere in the app.
  final bool hasSensorData;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'device_id': deviceId,
    'timestamp': timestamp.toIso8601String(),
    'air_temp_c': airTempC,
    'air_humidity_pct': airHumidityPct,
    'soil_moisture_pct': soilMoisturePct,
    'soil_temp_c': soilTempC,
    'ph': ph,
    'ec': ec,
    'resistance': resistance,
    'has_soil_moisture_data': hasSoilMoistureData,
    'has_soil_temp_data': hasSoilTempData,
    'has_ph_data': hasPhData,
    'has_resistance_data': hasResistanceData,
    'n': n,
    'p': p,
    'k': k,
    'has_nitrogen_data': hasNitrogenData,
    'has_phosphorus_data': hasPhosphorusData,
    'has_potassium_data': hasPotassiumData,
    'battery_pct': batteryPct,
    'signal_rssi': signalRssi,
    'has_sensor_data': hasSensorData,
  };

  factory BioGTelemetry.fromJson(Map<String, dynamic> json) {
    final parsed = BioGTelemetry.tryFromJson(json);
    if (parsed == null) {
      throw const FormatException('Invalid BioGTelemetry payload');
    }
    return parsed;
  }

  static BioGTelemetry? tryFromJson(Map<String, dynamic> json) {
    final String? deviceId = _firstString(<dynamic>[
      json['device_id'],
      json['deviceId'],
    ]);
    final DateTime? timestamp = _firstDateTime(<dynamic>[
      json['timestamp'],
      json['created_at'],
      json['createdAt'],
      json['recorded_at'],
    ]);

    if (deviceId == null || deviceId.isEmpty || timestamp == null) {
      return null;
    }

    final double? airTempC = _firstNullableDouble(<dynamic>[
      json['air_temp_c'],
      json['airTempC'],
      json['temperature'],
      json['temperature_c'],
      json['air_temperature'],
      json['ambient_temperature'],
      json['temp_c'],
      json['temp'],
    ]);
    final double? airHumidityPct = _firstNullableDouble(<dynamic>[
      json['air_humidity_pct'],
      json['airHumidityPct'],
      json['air_humidity'],
      json['humidity_pct'],
      json['humidity'],
      json['hum'],
    ]);
    final double? soilMoisturePct = _firstNullableDouble(<dynamic>[
      json['soil_moisture_pct'],
      json['soilMoisturePct'],
      json['soil_moisture'],
      json['soil_humidity'],
      json['soilHumidity'],
      json['moisture'],
      json['humidity_soil'],
      json['humedad_suelo'],
    ]);
    final double? soilTempC = _firstNullableDouble(<dynamic>[
      json['soil_temp_c'],
      json['soilTempC'],
      json['soil_temp'],
      json['soil_temperature'],
      json['soilTemperature'],
      json['soil_temperature_c'],
      json['ground_temperature'],
    ]);
    final double? ph = _firstNullableDouble(<dynamic>[
      json['ph'],
      json['pH'],
      json['PH'],
      json['pg'],
      json['PG'],
    ]);
    final double? ec = _firstNullableDouble(<dynamic>[
      json['ec'],
      json['Ec'],
      json['EC'],
      json['conductivity'],
      json['electrical_conductivity'],
    ]);
    final double? resistance = _firstNullableDouble(<dynamic>[
      json['resistance'],
      json['rt'],
      json['RT'],
      json['soil_resistance'],
      json['resistance_mpa'],
    ]);
    final double? n = _firstNullableDouble(<dynamic>[
      json['n'],
      json['N'],
      json['nitrogen'],
      json['nitrogen_ppm'],
    ]);
    final double? p = _firstNullableDouble(<dynamic>[
      json['p'],
      json['P'],
      json['phosphorus'],
      json['phosphorus_ppm'],
    ]);
    final double? k = _firstNullableDouble(<dynamic>[
      json['k'],
      json['K'],
      json['potassium'],
      json['potassium_ppm'],
    ]);
    final bool? explicitHasNitrogenData = _asBool(
      json['has_nitrogen_data'] ?? json['hasNitrogenData'],
    );
    final bool? explicitHasSoilMoistureData = _asBool(
      json['has_soil_moisture_data'] ?? json['hasSoilMoistureData'],
    );
    final bool? explicitHasSoilTempData = _asBool(
      json['has_soil_temp_data'] ?? json['hasSoilTempData'],
    );
    final bool? explicitHasPhData = _asBool(
      json['has_ph_data'] ?? json['hasPhData'],
    );
    final bool? explicitHasResistanceData = _asBool(
      json['has_resistance_data'] ?? json['hasResistanceData'],
    );
    final bool? explicitHasPhosphorusData = _asBool(
      json['has_phosphorus_data'] ?? json['hasPhosphorusData'],
    );
    final bool? explicitHasPotassiumData = _asBool(
      json['has_potassium_data'] ?? json['hasPotassiumData'],
    );

    final bool? explicitHasSensorData = _asBool(
      json['has_sensor_data'] ?? json['hasSensorData'],
    );
    final bool detectedSensorData =
        _hasAnySensorValue(<double?>[
          airTempC,
          airHumidityPct,
          soilMoisturePct,
          soilTempC,
          ph,
          ec,
          resistance,
          n,
          p,
          k,
        ]) ||
        _hasAnyRawSensorField(json);

    return BioGTelemetry(
      deviceId: deviceId,
      timestamp: timestamp,
      airTempC: airTempC ?? 0.0,
      airHumidityPct: airHumidityPct ?? 0.0,
      soilMoisturePct: soilMoisturePct ?? 0.0,
      soilTempC: soilTempC ?? 0.0,
      ph: ph ?? 0.0,
      ec: ec ?? 0.0,
      resistance: resistance ?? 0.0,
      n: n ?? 0.0,
      p: p ?? 0.0,
      k: k ?? 0.0,
      hasSoilMoistureData:
          explicitHasSoilMoistureData ?? soilMoisturePct != null,
      hasSoilTempData: explicitHasSoilTempData ?? soilTempC != null,
      hasPhData: explicitHasPhData ?? ph != null,
      hasResistanceData: explicitHasResistanceData ?? resistance != null,
      hasNitrogenData: explicitHasNitrogenData ?? n != null,
      hasPhosphorusData: explicitHasPhosphorusData ?? p != null,
      hasPotassiumData: explicitHasPotassiumData ?? k != null,
      batteryPct: _firstNullableDouble(<dynamic>[
        json['battery_pct'],
        json['batteryPct'],
        json['battery_percent'],
      ]),
      signalRssi: _firstNullableInt(<dynamic>[
        json['signal_rssi'],
        json['signalRssi'],
        json['rssi'],
      ]),
      hasSensorData: explicitHasSensorData ?? detectedSensorData,
    );
  }

  BioGTelemetry copyWith({
    String? deviceId,
    DateTime? timestamp,
    double? airTempC,
    double? airHumidityPct,
    double? soilMoisturePct,
    double? soilTempC,
    double? ph,
    double? ec,
    double? resistance,
    double? n,
    double? p,
    double? k,
    bool? hasSoilMoistureData,
    bool? hasSoilTempData,
    bool? hasPhData,
    bool? hasResistanceData,
    bool? hasNitrogenData,
    bool? hasPhosphorusData,
    bool? hasPotassiumData,
    double? batteryPct,
    int? signalRssi,
    bool? hasSensorData,
  }) {
    return BioGTelemetry(
      deviceId: deviceId ?? this.deviceId,
      timestamp: timestamp ?? this.timestamp,
      airTempC: airTempC ?? this.airTempC,
      airHumidityPct: airHumidityPct ?? this.airHumidityPct,
      soilMoisturePct: soilMoisturePct ?? this.soilMoisturePct,
      soilTempC: soilTempC ?? this.soilTempC,
      ph: ph ?? this.ph,
      ec: ec ?? this.ec,
      resistance: resistance ?? this.resistance,
      n: n ?? this.n,
      p: p ?? this.p,
      k: k ?? this.k,
      hasSoilMoistureData:
          hasSoilMoistureData ?? this.hasSoilMoistureData,
      hasSoilTempData: hasSoilTempData ?? this.hasSoilTempData,
      hasPhData: hasPhData ?? this.hasPhData,
      hasResistanceData: hasResistanceData ?? this.hasResistanceData,
      hasNitrogenData: hasNitrogenData ?? this.hasNitrogenData,
      hasPhosphorusData: hasPhosphorusData ?? this.hasPhosphorusData,
      hasPotassiumData: hasPotassiumData ?? this.hasPotassiumData,
      batteryPct: batteryPct ?? this.batteryPct,
      signalRssi: signalRssi ?? this.signalRssi,
      hasSensorData: hasSensorData ?? this.hasSensorData,
    );
  }

  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }

  static String? _firstString(Iterable<dynamic> values) {
    for (final value in values) {
      final parsed = _asString(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;

    return DateTime.tryParse(text);
  }

  static DateTime? _firstDateTime(Iterable<dynamic> values) {
    for (final value in values) {
      final parsed = _asDateTime(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static double _asDouble(dynamic value) => _asNullableDouble(value) ?? 0.0;

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return double.tryParse(text);
  }

  static double? _firstNullableDouble(Iterable<dynamic> values) {
    for (final value in values) {
      final parsed = _asNullableDouble(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.round();

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return int.tryParse(text) ?? double.tryParse(text)?.round();
  }

  static int? _firstNullableInt(Iterable<dynamic> values) {
    for (final value in values) {
      final parsed = _asNullableInt(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty || text == 'null') return null;
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }

  static bool _hasAnySensorValue(Iterable<double?> values) {
    for (final value in values) {
      if (value != null && value.isFinite) return true;
    }
    return false;
  }

  static bool _hasAnyRawSensorField(Map<String, dynamic> json) {
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
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return true;
    }
    return false;
  }
}

@immutable
class BioGAlert {
  const BioGAlert({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  final String id;
  final String deviceId;
  final BioGAlertType type;
  final BioGAlertSeverity severity;
  final String title;
  final String body;
  final DateTime timestamp;
}
