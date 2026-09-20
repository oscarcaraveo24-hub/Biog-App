// Pruebas del traductor BLE -> contrato interno.
//
// Son Dart puro: no necesitan radio, ni telefono, ni ESP32. Cubren
// exactamente lo que puede salir mal en silencio cuando llegue el hardware.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/telemetry/telemetry_contract.dart';
import 'package:bio_g/services/biog/telemetry/ble/biog_ble_codec.dart';

List<int> _b(Object json) => utf8.encode(jsonEncode(json));

const String _kDeviceId = '3f2b6c10-9d44-4a1e-8f77-1b2c3d4e5f60';

TelemetryDeviceIdentity get _identity => const TelemetryDeviceIdentity(
  deviceId: _kDeviceId,
  hardwareSerial: 'BIOG-C-2632-000001-7',
  deviceModelId: 'campo',
  firmwareVersion: '0.1.0',
);

void main() {
  group('decodeIdentity', () {
    test('lee el JSON de identidad del firmware', () {
      final identity = BioGBleCodec.decodeIdentity(
        _b(<String, Object?>{
          'deviceId': _kDeviceId,
          'hardwareSerial': 'BIOG-C-2632-000001-7',
          'deviceModelId': 'campo',
          'firmwareVersion': '0.1.0',
          'protocol': '1.0',
        }),
      );

      expect(identity, isNotNull);
      expect(identity!.deviceId, _kDeviceId);
      expect(identity.hardwareSerial, 'BIOG-C-2632-000001-7');
      expect(identity.deviceModelId, 'campo');
      expect(identity.protocolMajor, 1);
    });

    test('rechaza un deviceId que no es UUID en vez de aceptarlo', () {
      // Es el caso que importa: si esto pasara, la app subiria telemetria con
      // un identificador basura y no habria vuelta atras.
      final identity = BioGBleCodec.decodeIdentity(
        _b(<String, Object?>{'deviceId': 'BIOG-DEV-001', 'protocol': '1.0'}),
      );
      expect(identity, isNull);
    });

    test('rechaza bytes vacios y JSON roto sin lanzar', () {
      expect(BioGBleCodec.decodeIdentity(const <int>[]), isNull);
      expect(BioGBleCodec.decodeIdentity(utf8.encode('{no es json')), isNull);
      expect(BioGBleCodec.decodeIdentity(utf8.encode('[1,2,3]')), isNull);
    });
  });

  group('decodeTelemetry', () {
    final receivedAt = DateTime.utc(2026, 8, 31, 18, 30);

    TelemetryEnvelope decode(Map<String, Object?> payload, {int? rssi}) {
      final e = BioGBleCodec.decodeTelemetry(
        _b(payload),
        identity: _identity,
        receivedAt: receivedAt,
        signalRssi: rssi,
      );
      expect(e, isNotNull, reason: 'el sobre no debio ser nulo');
      return e!;
    }

    test('traduce el sobre compacto del ESP32', () {
      final e = decode(<String, Object?>{
        'seq': 12,
        'sm': 34.5,
        'st': 21.2,
        'ph': 6.8,
        'ec': 1.4,
        'n': 40,
        'p': 18,
        'k': 95,
      }, rssi: -57);

      expect(e.sequenceNumber, 12);
      expect(e.transport, TelemetryTransportKind.ble);
      expect(e.reading.soilMoisturePct, 34.5);
      expect(e.reading.soilTempC, 21.2);
      expect(e.reading.ph, 6.8);
      expect(e.reading.ec, 1.4);
      expect(e.reading.n, 40.0);
      expect(e.reading.p, 18.0);
      expect(e.reading.k, 95.0);
      expect(e.reading.signalRssi, -57);
    });

    test('N/P/K del BIO-G físico se conservan RAW sin escalado', () {
      final e = decode(<String, Object?>{'st': 24, 'n': 12, 'p': 6, 'k': 18});

      expect((e.reading.n, e.reading.p, e.reading.k), (12, 6, 18));
      expect(e.reading.soilTempC, 24);
    });

    test('el deviceId sale de la identidad, nunca del transporte', () {
      final e = decode(<String, Object?>{'sm': 30.0});
      expect(e.identity.deviceId, _kDeviceId);
      expect(e.reading.deviceId, _kDeviceId);
    });

    test('lo que el sobre NO trae queda marcado ausente, no en cero', () {
      // Este es el corazon del asunto. El sobre BLE de hoy no trae aire ni
      // resistencia. Si se colaran como 0.0 con la bandera en true, subirian
      // ceros falsos e irreversibles a la nube.
      final e = decode(<String, Object?>{'sm': 34.5, 'ph': 6.8});

      expect(e.reading.hasSoilMoistureData, isTrue);
      expect(e.reading.hasPhData, isTrue);

      expect(e.reading.hasAirTempData, isFalse);
      expect(e.reading.hasAirHumidityData, isFalse);
      expect(e.reading.hasResistanceData, isFalse);
      expect(e.reading.hasEcData, isFalse);
      expect(e.reading.hasNitrogenData, isFalse);
      expect(e.reading.hasPhosphorusData, isFalse);
      expect(e.reading.hasPotassiumData, isFalse);
      expect(e.reading.hasSoilTempData, isFalse);
    });

    test('un cero REAL se conserva como cero presente', () {
      final e = decode(<String, Object?>{'n': 0});
      expect(e.reading.n, 0.0);
      expect(e.reading.hasNitrogenData, isTrue);
    });

    test('la CE cruda del registro (µS/cm) se convierte UNA vez a mS/cm', () {
      // Contrato del sensor (Guia v0.4, fase 3): la unica conversion de CE del
      // sistema vive en `SoilSensorSpec`, y el codec la aplica en la frontera.
      final e = decode(<String, Object?>{'ec_us': 1400});
      expect(e.reading.hasEcData, isTrue);
      expect(e.reading.ec, closeTo(1.4, 1e-9));
    });

    test('un valor fuera del rango plausible del contrato es dato AUSENTE', () {
      // 25 000 µS/cm (25 mS/cm) esta por encima de lo que la sonda puede
      // medir: sonda descalibrada o payload corrupto, nunca «suelo salino».
      final e = decode(<String, Object?>{
        'sm': 34.5,
        'ec_us': 25000,
        'n': 5000,
      });
      expect(e.reading.hasEcData, isFalse);
      expect(e.reading.hasNitrogenData, isFalse);
      expect(e.reading.hasSoilMoistureData, isTrue);
    });

    test('declara que el reloj no es del aparato', () {
      // El sobre compacto no trae hora de medicion: la pone el telefono.
      // Decir lo contrario seria fechar decisiones agronomicas con una hora
      // inventada.
      final e = decode(<String, Object?>{'sm': 34.5});
      expect(e.quality.clockTrusted, isFalse);
      expect(e.measuredAt, receivedAt);
      expect(e.receivedAt, receivedAt);
    });

    test('el sobre resultante pasa la validacion del contrato', () {
      final e = decode(<String, Object?>{'sm': 34.5, 'ph': 6.8, 'seq': 3});
      expect(
        e.validate(now: receivedAt.add(const Duration(seconds: 1))),
        isNull,
      );
    });

    test('un sobre sin ninguna metrica lo rechaza el contrato', () {
      final e = decode(<String, Object?>{'seq': 9});
      expect(
        e.validate(now: receivedAt.add(const Duration(seconds: 1))),
        TelemetryRejectionReason.noUsableMetrics,
      );
    });

    test('tolera numeros en texto y descarta valores no finitos', () {
      final e = decode(<String, Object?>{'sm': '34.5', 'ph': 'no-es-numero'});
      expect(e.reading.soilMoisturePct, 34.5);
      expect(e.reading.hasSoilMoistureData, isTrue);
      expect(e.reading.hasPhData, isFalse);
    });

    test('JSON roto devuelve null en vez de lanzar', () {
      expect(
        BioGBleCodec.decodeTelemetry(
          utf8.encode('{"sm":'),
          identity: _identity,
          receivedAt: receivedAt,
        ),
        isNull,
      );
    });
  });
}
