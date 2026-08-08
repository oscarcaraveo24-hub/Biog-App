// test/models/biog_telemetry_presence_test.dart
//
// Banderas de presencia. El hueco que quedaba: humedad de suelo, pH,
// resistencia y NPK sí distinguían dato ausente de cero, pero temperatura de
// aire, humedad de aire y CE no.

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/models/biog_telemetry.dart';

void main() {
  const String deviceId = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';
  final String ts = DateTime.utc(2026, 8, 3, 12).toIso8601String();

  group('métricas de aire y CE', () {
    test('un campo ausente queda marcado como ausente, no como cero real', () {
      final t = BioGTelemetry.tryFromJson(<String, dynamic>{
        'device_id': deviceId,
        'timestamp': ts,
        'soil_moisture_pct': 30.0,
        // sin air_temp_c, sin air_humidity_pct, sin ec
      });

      expect(t, isNotNull);
      expect(t!.hasAirTempData, isFalse);
      expect(t.hasAirHumidityData, isFalse);
      expect(t.hasEcData, isFalse);

      // El valor numérico sigue siendo 0.0 por compatibilidad, pero la bandera
      // es la fuente de verdad y nadie debe leer el número sin consultarla.
      expect(t.airTempC, 0.0);
      expect(t.hasSoilMoistureData, isTrue);
    });

    test('un valor presente marca la bandera', () {
      final t = BioGTelemetry.tryFromJson(<String, dynamic>{
        'device_id': deviceId,
        'timestamp': ts,
        'air_temp_c': 23.4,
        'air_humidity_pct': 61.0,
        'ec': 1.35,
      });

      expect(t!.hasAirTempData, isTrue);
      expect(t.hasAirHumidityData, isTrue);
      expect(t.hasEcData, isTrue);
      expect(t.airTempC, 23.4);
      expect(t.ec, 1.35);
    });

    test('un valor fuera de rango físico se trata como ausente', () {
      final t = BioGTelemetry.tryFromJson(<String, dynamic>{
        'device_id': deviceId,
        'timestamp': ts,
        'air_temp_c': 500.0,
        'ec': -3.0,
      });

      expect(t!.hasAirTempData, isFalse);
      expect(t.hasEcData, isFalse);
    });

    test('una bandera explícita no puede afirmar un dato que no llegó', () {
      final t = BioGTelemetry.tryFromJson(<String, dynamic>{
        'device_id': deviceId,
        'timestamp': ts,
        'has_air_temp_data': true,
        // pero no hay air_temp_c
      });

      expect(t!.hasAirTempData, isFalse);
    });

    test('una bandera explícita en false se respeta aunque venga el valor', () {
      final t = BioGTelemetry.tryFromJson(<String, dynamic>{
        'device_id': deviceId,
        'timestamp': ts,
        'air_temp_c': 22.0,
        'has_air_temp_data': false,
      });

      expect(t!.hasAirTempData, isFalse);
    });
  });

  group('serialización', () {
    test('las banderas nuevas viajan en toJson', () {
      final t = BioGTelemetry.tryFromJson(<String, dynamic>{
        'device_id': deviceId,
        'timestamp': ts,
        'soil_moisture_pct': 30.0,
      });

      final json = t!.toJson();
      expect(json['has_air_temp_data'], isFalse);
      expect(json['has_air_humidity_data'], isFalse);
      expect(json['has_ec_data'], isFalse);
    });

    test('ida y vuelta conserva la presencia', () {
      final original = BioGTelemetry.tryFromJson(<String, dynamic>{
        'device_id': deviceId,
        'timestamp': ts,
        'air_temp_c': 25.0,
        // sin humedad de suelo
      })!;

      final restored = BioGTelemetry.tryFromJson(original.toJson())!;

      expect(restored.hasAirTempData, isTrue);
      expect(restored.hasSoilMoistureData, isFalse);
      expect(restored.hasEcData, isFalse);
    });
  });

  test('copyWith conserva las banderas nuevas', () {
    final t = BioGTelemetry.tryFromJson(<String, dynamic>{
      'device_id': deviceId,
      'timestamp': ts,
      'air_temp_c': 25.0,
    })!;

    final copy = t.copyWith(airHumidityPct: 50);
    expect(copy.hasAirTempData, isTrue);
    expect(copy.hasEcData, isFalse);
  });
}
