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
}

@immutable
class BioGDevice {
  const BioGDevice({
    required this.id,
    required this.name,
    required this.locationName,
    required this.seedId,
    required this.profileId,
    this.status = BioGDeviceStatus.active,
    this.createdAt,
  });

  final String id;
  final String name;
  final String locationName;

  /// Ej: 'DK-2069' o el id que uses en Seeds.
  final String seedId;

  /// Ej: 'MZG-07' o 'basic_soil'
  final String profileId;

  final BioGDeviceStatus status;
  final DateTime? createdAt;

  BioGDevice copyWith({
    String? id,
    String? name,
    String? locationName,
    String? seedId,
    String? profileId,
    BioGDeviceStatus? status,
    DateTime? createdAt,
  }) {
    return BioGDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      locationName: locationName ?? this.locationName,
      seedId: seedId ?? this.seedId,
      profileId: profileId ?? this.profileId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

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

  // Nutrientes
  final double n; // ppm (ejemplo)
  final double p; // ppm
  final double k; // ppm

  // Estado dispositivo
  final double batteryPct; // %
  final int signalRssi; // dBm (ejemplo -40 bueno, -90 malo)

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
    double? batteryPct,
    int? signalRssi,
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
      batteryPct: batteryPct ?? this.batteryPct,
      signalRssi: signalRssi ?? this.signalRssi,
    );
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
