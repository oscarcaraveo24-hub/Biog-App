// lib/core/telemetry/telemetry_contract.dart
//
// Contrato de telemetría entre el hardware Bio-G y la aplicación.
//
// Por qué existe: hasta ahora la app leía filas de la tabla `telemetry` y las
// convertía a `BioGTelemetry` sin ningún contrato explícito. Faltaba todo lo
// que hace auditable una medición —identidad del dispositivo, versión de
// protocolo, versión de firmware, calibración aplicada, hora de medición
// separada de la de recepción, número de secuencia, banderas de calidad— y
// `uploadBatch()` no tenía ni un solo llamador.
//
// Este archivo define el sobre (`TelemetryEnvelope`) que el firmware debe
// emitir y que la app sabe validar. Es deliberadamente independiente del
// transporte: el mismo sobre vale por BLE, por HTTP o por un archivo de
// pruebas, y por eso puede cerrarse y probarse ANTES de fabricar firmware,
// que era el orden que pedía el plan de cierre.

import 'package:flutter/foundation.dart';

import 'package:bio_g/models/biog_telemetry.dart';

/// Versión del contrato que esta build de la app entiende.
///
/// El firmware debe declarar la suya en cada sobre. Si no coincide en MAJOR,
/// la lectura se rechaza en vez de interpretarse a medias.
const int kTelemetryProtocolVersionMajor = 1;
const int kTelemetryProtocolVersionMinor = 0;

/// Cómo llegó la medición.
enum TelemetryTransportKind { ble, wifi, cloud, manual, test }

/// Resultado de validar un sobre.
enum TelemetryRejectionReason {
  missingDeviceId,
  invalidDeviceId,
  missingMeasuredAt,
  measuredAtInFuture,
  protocolTooNew,
  protocolTooOld,
  noUsableMetrics,
  duplicateSequence,
}

extension TelemetryRejectionReasonX on TelemetryRejectionReason {
  String get labelEs {
    switch (this) {
      case TelemetryRejectionReason.missingDeviceId:
        return 'El sobre no trae identificador de dispositivo.';
      case TelemetryRejectionReason.invalidDeviceId:
        return 'El identificador de dispositivo no tiene formato válido.';
      case TelemetryRejectionReason.missingMeasuredAt:
        return 'El sobre no trae hora de medición.';
      case TelemetryRejectionReason.measuredAtInFuture:
        return 'La hora de medición está en el futuro.';
      case TelemetryRejectionReason.protocolTooNew:
        return 'El dispositivo usa una versión de protocolo más nueva que la app.';
      case TelemetryRejectionReason.protocolTooOld:
        return 'El dispositivo usa una versión de protocolo que ya no se admite.';
      case TelemetryRejectionReason.noUsableMetrics:
        return 'El sobre no contiene ninguna métrica utilizable.';
      case TelemetryRejectionReason.duplicateSequence:
        return 'Ya se recibió una lectura con este número de secuencia.';
    }
  }
}

/// Identidad física del dispositivo que midió.
///
/// Es lo que hoy falta por completo: el id contra el que la app consulta la
/// tabla `telemetry` es un UUID generado en el teléfono, no algo que el
/// hardware conozca. Sin esta identidad, conectar un Bio-G real es imposible
/// por diseño, no por falta de radio.
@immutable
class TelemetryDeviceIdentity {
  const TelemetryDeviceIdentity({
    required this.deviceId,
    this.hardwareSerial,
    this.deviceModelId,
    this.firmwareVersion,
    this.protocolMajor = kTelemetryProtocolVersionMajor,
    this.protocolMinor = kTelemetryProtocolVersionMinor,
    this.calibrationId,
    this.calibratedAt,
  });

  /// UUID que viaja en `telemetry.device_id`. Lo emite el hardware, no la app.
  final String deviceId;

  /// Serie grabada de fábrica. Permite reconocer el mismo aparato aunque se
  /// reemparejé o cambie de cuenta.
  final String? hardwareSerial;

  /// `campo` | `huerto` | `maceta`.
  final String? deviceModelId;

  final String? firmwareVersion;
  final int protocolMajor;
  final int protocolMinor;

  /// Identificador de la tabla de calibración aplicada a esta medición.
  final String? calibrationId;
  final DateTime? calibratedAt;

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool get hasValidId => _uuid.hasMatch(deviceId.trim());

  static bool isValidDeviceId(String value) => _uuid.hasMatch(value.trim());

  Map<String, Object?> toJson() => <String, Object?>{
    'deviceId': deviceId,
    'hardwareSerial': hardwareSerial,
    'deviceModelId': deviceModelId,
    'firmwareVersion': firmwareVersion,
    'protocol': '$protocolMajor.$protocolMinor',
    'calibrationId': calibrationId,
    'calibratedAt': calibratedAt?.toUtc().toIso8601String(),
  };

  static TelemetryDeviceIdentity? fromJson(Map<String, dynamic> json) {
    final id = (json['deviceId'] ?? json['device_id'])?.toString().trim();
    if (id == null || id.isEmpty) return null;

    final protocol = (json['protocol'] ?? '').toString();
    final parts = protocol.split('.');
    final major = parts.isNotEmpty
        ? int.tryParse(parts[0]) ?? kTelemetryProtocolVersionMajor
        : kTelemetryProtocolVersionMajor;
    final minor = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final calibratedRaw = json['calibratedAt'] ?? json['calibrated_at'];

    return TelemetryDeviceIdentity(
      deviceId: id,
      hardwareSerial: (json['hardwareSerial'] ?? json['hardware_serial'])
          ?.toString(),
      deviceModelId: (json['deviceModelId'] ?? json['device_model_id'])
          ?.toString(),
      firmwareVersion: (json['firmwareVersion'] ?? json['firmware_version'])
          ?.toString(),
      protocolMajor: major,
      protocolMinor: minor,
      calibrationId: (json['calibrationId'] ?? json['calibration_id'])
          ?.toString(),
      calibratedAt: calibratedRaw == null
          ? null
          : DateTime.tryParse(calibratedRaw.toString()),
    );
  }
}

/// Estado del hardware en el momento de medir. Separado de las métricas
/// agronómicas porque responde a otra pregunta: no "cómo está el suelo" sino
/// "puedo confiar en lo que este aparato me está diciendo".
@immutable
class TelemetryQuality {
  const TelemetryQuality({
    this.batteryPct,
    this.signalRssi,
    this.sensorErrorCode,
    this.clockTrusted = true,
    this.isRetransmission = false,
  });

  final double? batteryPct;
  final int? signalRssi;

  /// Código de error del propio sensor. Distinto de "no llegó el dato": aquí
  /// el aparato dice explícitamente que algo falla.
  final String? sensorErrorCode;

  /// False si el dispositivo perdió la hora (batería agotada, arranque en
  /// frío). Con reloj no confiable la medición no puede fechar decisiones.
  final bool clockTrusted;

  /// True si el sobre viaja desde la cola local tras haber estado sin señal.
  final bool isRetransmission;

  bool get hasSensorError =>
      sensorErrorCode != null && sensorErrorCode!.trim().isNotEmpty;

  static const TelemetryQuality unknown = TelemetryQuality();

  Map<String, Object?> toJson() => <String, Object?>{
    'batteryPct': batteryPct,
    'signalRssi': signalRssi,
    'sensorErrorCode': sensorErrorCode,
    'clockTrusted': clockTrusted,
    'isRetransmission': isRetransmission,
  };
}

/// El sobre completo: una medición con todo lo necesario para auditarla.
@immutable
class TelemetryEnvelope {
  const TelemetryEnvelope({
    required this.identity,
    required this.measuredAt,
    required this.receivedAt,
    required this.reading,
    this.timezone,
    this.sequenceNumber,
    this.batchId,
    this.quality = TelemetryQuality.unknown,
    this.transport = TelemetryTransportKind.cloud,
  });

  final TelemetryDeviceIdentity identity;

  /// Cuándo midió el sensor, según el dispositivo.
  final DateTime measuredAt;

  /// Cuándo lo recibió la app. Deliberadamente separado de [measuredAt]: son
  /// dos hechos distintos y confundirlos es lo que hacía que una lectura vieja
  /// se presentara como nueva.
  final DateTime receivedAt;

  /// Zona horaria declarada por el dispositivo (`America/Mexico_City`).
  final String? timezone;

  /// Contador monótono del dispositivo. Permite detectar huecos y duplicados
  /// sin depender del reloj.
  final int? sequenceNumber;

  /// Identificador del lote cuando la lectura llega agrupada tras un periodo
  /// sin señal.
  final String? batchId;

  final TelemetryQuality quality;
  final TelemetryTransportKind transport;

  /// Las métricas ya normalizadas al modelo interno.
  final BioGTelemetry reading;

  /// Retraso entre medición y recepción.
  Duration get transitDelay {
    final d = receivedAt.toUtc().difference(measuredAt.toUtc());
    return d.isNegative ? Duration.zero : d;
  }

  /// Valida el sobre. Devuelve `null` si es aceptable.
  ///
  /// [now] se inyecta para poder probar el caso de medición en el futuro.
  TelemetryRejectionReason? validate({
    required DateTime now,
    Duration futureTolerance = const Duration(minutes: 5),
  }) {
    final id = identity.deviceId.trim();
    if (id.isEmpty) return TelemetryRejectionReason.missingDeviceId;
    if (!identity.hasValidId) return TelemetryRejectionReason.invalidDeviceId;

    if (identity.protocolMajor > kTelemetryProtocolVersionMajor) {
      return TelemetryRejectionReason.protocolTooNew;
    }
    if (identity.protocolMajor < 1) {
      return TelemetryRejectionReason.protocolTooOld;
    }

    // Un reloj adelantado produciría lecturas "del futuro" que romperían
    // cualquier cálculo de vigencia. Se tolera un margen pequeño por deriva.
    if (measuredAt.toUtc().isAfter(now.toUtc().add(futureTolerance))) {
      return TelemetryRejectionReason.measuredAtInFuture;
    }

    if (!hasAnyUsableMetric) return TelemetryRejectionReason.noUsableMetrics;

    return null;
  }

  /// True si al menos una métrica agronómica llegó realmente presente.
  ///
  /// Se apoya en las banderas, no en los valores: un sobre lleno de ceros
  /// sintetizados no es una medición.
  bool get hasAnyUsableMetric {
    final r = reading;
    return r.hasSoilMoistureData ||
        r.hasSoilTempData ||
        r.hasPhData ||
        r.hasEcData ||
        r.hasResistanceData ||
        r.hasNitrogenData ||
        r.hasPhosphorusData ||
        r.hasPotassiumData ||
        r.hasAirTempData ||
        r.hasAirHumidityData;
  }

  /// Convierte el sobre a la lectura interna, garantizando que el `deviceId` y
  /// la hora sean los del contrato y no los que trajera el payload.
  BioGTelemetry toReading() {
    return reading.copyWith(
      deviceId: identity.deviceId.trim(),
      timestamp: measuredAt,
      batteryPct: quality.batteryPct ?? reading.batteryPct,
      signalRssi: quality.signalRssi ?? reading.signalRssi,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'identity': identity.toJson(),
    'measuredAt': measuredAt.toUtc().toIso8601String(),
    'receivedAt': receivedAt.toUtc().toIso8601String(),
    'timezone': timezone,
    'sequenceNumber': sequenceNumber,
    'batchId': batchId,
    'quality': quality.toJson(),
    'transport': transport.name,
    'reading': reading.toJson(),
  };

  /// Construye un sobre desde el payload crudo del dispositivo.
  ///
  /// Devuelve `null` si el payload no permite formar un sobre mínimo. Nunca
  /// lanza: un firmware con un bug no puede tumbar la app.
  static TelemetryEnvelope? fromDevicePayload(
    Map<String, dynamic> json, {
    required DateTime receivedAt,
    TelemetryTransportKind transport = TelemetryTransportKind.cloud,
  }) {
    try {
      final identity = TelemetryDeviceIdentity.fromJson(
        (json['identity'] as Map?)?.cast<String, dynamic>() ?? json,
      );
      if (identity == null) return null;

      final measuredRaw =
          json['measuredAt'] ??
          json['measured_at'] ??
          json['timestamp'] ??
          json['recorded_at'];
      final measuredAt = measuredRaw == null
          ? null
          : DateTime.tryParse(measuredRaw.toString());
      if (measuredAt == null) return null;

      final readingJson =
          (json['reading'] as Map?)?.cast<String, dynamic>() ?? json;

      // El modelo interno exige device_id y timestamp; se inyectan desde el
      // contrato para que el payload no pueda contradecirlos.
      final normalized = Map<String, dynamic>.from(readingJson)
        ..['device_id'] = identity.deviceId
        ..['timestamp'] = measuredAt.toUtc().toIso8601String();

      final reading = BioGTelemetry.tryFromJson(normalized);
      if (reading == null) return null;

      final qualityJson =
          (json['quality'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};

      return TelemetryEnvelope(
        identity: identity,
        measuredAt: measuredAt,
        receivedAt: receivedAt,
        reading: reading,
        timezone: (json['timezone'] ?? json['tz'])?.toString(),
        sequenceNumber: _asInt(json['sequenceNumber'] ?? json['seq']),
        batchId: (json['batchId'] ?? json['batch_id'])?.toString(),
        quality: TelemetryQuality(
          batteryPct: _asDouble(
            qualityJson['batteryPct'] ??
                qualityJson['battery_pct'] ??
                json['battery_pct'],
          ),
          signalRssi: _asInt(
            qualityJson['signalRssi'] ??
                qualityJson['signal_rssi'] ??
                json['signal_rssi'],
          ),
          sensorErrorCode:
              (qualityJson['sensorErrorCode'] ?? qualityJson['error'])
                  ?.toString(),
          clockTrusted:
              _asBool(qualityJson['clockTrusted'] ?? json['clock_trusted']) ??
              true,
          isRetransmission:
              _asBool(
                qualityJson['isRetransmission'] ?? json['is_retransmission'],
              ) ??
              false,
        ),
        transport: transport,
      );
    } catch (_) {
      return null;
    }
  }

  static double? _asDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static bool? _asBool(Object? v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase().trim();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }
}
