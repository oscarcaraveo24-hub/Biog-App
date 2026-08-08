// test/core/telemetry/telemetry_contract_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/telemetry/telemetry_contract.dart';
import 'package:bio_g/models/biog_telemetry.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 8, 3, 12);
  const String validUuid = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';

  BioGTelemetry readingWith({
    double soilMoisture = 32,
    bool hasMoisture = true,
    bool hasAirTemp = true,
  }) {
    return BioGTelemetry(
      deviceId: validUuid,
      timestamp: now,
      airTempC: 24,
      airHumidityPct: 55,
      soilMoisturePct: soilMoisture,
      soilTempC: 19,
      ph: 6.4,
      ec: 1.1,
      resistance: 0.8,
      n: 40,
      p: 20,
      k: 90,
      batteryPct: 88,
      signalRssi: -60,
      hasSoilMoistureData: hasMoisture,
      hasAirTempData: hasAirTemp,
    );
  }

  TelemetryEnvelope envelopeWith({
    String deviceId = validUuid,
    DateTime? measuredAt,
    BioGTelemetry? reading,
    int? sequence,
  }) {
    return TelemetryEnvelope(
      identity: TelemetryDeviceIdentity(
        deviceId: deviceId,
        hardwareSerial: 'BG-2026-0001',
        deviceModelId: 'campo',
        firmwareVersion: '1.4.2',
        calibrationId: 'cal-7',
      ),
      measuredAt: measuredAt ?? now.subtract(const Duration(minutes: 5)),
      receivedAt: now,
      timezone: 'America/Mexico_City',
      sequenceNumber: sequence,
      reading: reading ?? readingWith(),
    );
  }

  group('validación del contrato', () {
    test('un sobre completo se acepta', () {
      expect(envelopeWith().validate(now: now), isNull);
    });

    test('id que no es UUID se rechaza', () {
      // Es exactamente lo que devuelve hoy el escáner QR simulado.
      final envelope = envelopeWith(deviceId: 'BIOG-QR-001');
      expect(
        envelope.validate(now: now),
        TelemetryRejectionReason.invalidDeviceId,
      );
    });

    test('id vacío se rechaza', () {
      expect(
        envelopeWith(deviceId: '   ').validate(now: now),
        TelemetryRejectionReason.missingDeviceId,
      );
    });

    test('medición en el futuro se rechaza', () {
      final envelope = envelopeWith(
        measuredAt: now.add(const Duration(hours: 2)),
      );
      expect(
        envelope.validate(now: now),
        TelemetryRejectionReason.measuredAtInFuture,
      );
    });

    test('una deriva pequeña de reloj se tolera', () {
      final envelope = envelopeWith(
        measuredAt: now.add(const Duration(minutes: 2)),
      );
      expect(envelope.validate(now: now), isNull);
    });

    test('protocolo más nuevo que la app se rechaza', () {
      final envelope = TelemetryEnvelope(
        identity: TelemetryDeviceIdentity(
          deviceId: validUuid,
          protocolMajor: kTelemetryProtocolVersionMajor + 1,
        ),
        measuredAt: now.subtract(const Duration(minutes: 1)),
        receivedAt: now,
        reading: readingWith(),
      );
      expect(
        envelope.validate(now: now),
        TelemetryRejectionReason.protocolTooNew,
      );
    });

    test('un sobre sin ninguna métrica presente se rechaza', () {
      // Un payload lleno de ceros sintetizados no es una medición.
      final empty = BioGTelemetry(
        deviceId: validUuid,
        timestamp: now,
        airTempC: 0,
        airHumidityPct: 0,
        soilMoisturePct: 0,
        soilTempC: 0,
        ph: 0,
        ec: 0,
        resistance: 0,
        n: 0,
        p: 0,
        k: 0,
        batteryPct: null,
        signalRssi: null,
        hasSoilMoistureData: false,
        hasSoilTempData: false,
        hasPhData: false,
        hasResistanceData: false,
        hasNitrogenData: false,
        hasPhosphorusData: false,
        hasPotassiumData: false,
        hasAirTempData: false,
        hasAirHumidityData: false,
        hasEcData: false,
      );

      final envelope = envelopeWith(reading: empty);
      expect(envelope.hasAnyUsableMetric, isFalse);
      expect(
        envelope.validate(now: now),
        TelemetryRejectionReason.noUsableMetrics,
      );
    });
  });

  group('medición vs recepción', () {
    test('el retraso de tránsito se conserva y no se colapsa', () {
      // El defecto que había: `_latestTimestampIso` tomaba el máximo entre
      // `timestamp` y `created_at`, así que una lectura de hace horas subida
      // ahora se presentaba con la hora de subida.
      final envelope = envelopeWith(
        measuredAt: now.subtract(const Duration(hours: 6)),
      );
      expect(envelope.transitDelay, const Duration(hours: 6));
      expect(envelope.toReading().timestamp, envelope.measuredAt);
    });

    test('la identidad del contrato manda sobre la del payload', () {
      final reading = readingWith().copyWith(deviceId: 'otro-id-cualquiera');
      final envelope = envelopeWith(reading: reading);
      expect(envelope.toReading().deviceId, validUuid);
    });
  });

  group('parseo del payload del dispositivo', () {
    test('construye un sobre desde un payload plano', () {
      final envelope = TelemetryEnvelope.fromDevicePayload(
        <String, dynamic>{
          'deviceId': validUuid,
          'firmware_version': '1.4.2',
          'protocol': '1.0',
          'measured_at': now
              .subtract(const Duration(minutes: 3))
              .toIso8601String(),
          'seq': 42,
          'soil_moisture_pct': 31.5,
          'air_temp_c': 23.0,
          'battery_pct': 91,
        },
        receivedAt: now,
      );

      expect(envelope, isNotNull);
      expect(envelope!.identity.deviceId, validUuid);
      expect(envelope.identity.firmwareVersion, '1.4.2');
      expect(envelope.sequenceNumber, 42);
      expect(envelope.reading.soilMoisturePct, 31.5);
      expect(envelope.reading.hasSoilMoistureData, isTrue);
      expect(envelope.validate(now: now), isNull);
    });

    test('un payload sin hora de medición no forma sobre', () {
      final envelope = TelemetryEnvelope.fromDevicePayload(
        <String, dynamic>{'deviceId': validUuid, 'soil_moisture_pct': 30},
        receivedAt: now,
      );
      expect(envelope, isNull);
    });

    test('un payload corrupto devuelve null en vez de lanzar', () {
      expect(
        TelemetryEnvelope.fromDevicePayload(
          <String, dynamic>{'basura': true},
          receivedAt: now,
        ),
        isNull,
      );
    });

    test('un dato ausente NO se convierte en presente', () {
      final envelope = TelemetryEnvelope.fromDevicePayload(
        <String, dynamic>{
          'deviceId': validUuid,
          'measured_at': now.toIso8601String(),
          'air_temp_c': 22.5,
          // sin humedad de suelo
        },
        receivedAt: now,
      );

      expect(envelope, isNotNull);
      expect(envelope!.reading.hasSoilMoistureData, isFalse);
      expect(envelope.reading.hasAirTempData, isTrue);
    });
  });

  test('el UUID válido se reconoce; el texto libre no', () {
    expect(TelemetryDeviceIdentity.isValidDeviceId(validUuid), isTrue);
    expect(TelemetryDeviceIdentity.isValidDeviceId('BIOG-BLE-001'), isFalse);
    expect(TelemetryDeviceIdentity.isValidDeviceId(''), isFalse);
  });
}
