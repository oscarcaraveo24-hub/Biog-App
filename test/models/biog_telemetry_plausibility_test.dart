import 'package:bio_g/models/biog_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Congela el contrato de plausibilidad física de la telemetría.
///
/// Fundacional 2.1 §9.2: "Toda lectura fuera de los rangos físicamente
/// posibles será rechazada por el sistema antes de llegar al motor de
/// interpretación" y "no se generará una nueva recomendación basada en una
/// lectura inválida".
///
/// El mecanismo es indirecto a propósito: una lectura implausible se convierte
/// en `null` durante el parseo, y eso apaga la bandera `hasXData`
/// correspondiente. El motor ya sabe abstenerse cuando la bandera está apagada.
void main() {
  Map<String, dynamic> base() => <String, dynamic>{
    'device_id': '7c2a9632-2da5-4a53-9238-6dd561e978ef',
    'timestamp': '2026-07-27T00:00:00.000Z',
  };

  group('BioGTelemetry.tryFromJson · dato ausente vs. cero', () {
    test('un pH ausente no se declara como dato presente', () {
      final t = BioGTelemetry.tryFromJson(base());
      expect(t, isNotNull);
      expect(
        t!.hasPhData,
        isFalse,
        reason: 'Antes, ph ?? 0.0 hacía indistinguible un pH ausente de un '
            'suelo extremadamente ácido.',
      );
    });

    test('un NPK ausente no se declara como dato presente', () {
      final t = BioGTelemetry.tryFromJson(base())!;
      expect(t.hasNitrogenData, isFalse);
      expect(t.hasPhosphorusData, isFalse);
      expect(t.hasPotassiumData, isFalse);
    });

    test('una bandera explícita no puede afirmar un dato que no llegó', () {
      final t = BioGTelemetry.tryFromJson(<String, dynamic>{
        ...base(),
        'has_ph_data': true,
      })!;
      expect(t.hasPhData, isFalse);
    });
  });

  group('BioGTelemetry.tryFromJson · rangos físicos', () {
    test('pH fuera de la escala 0-14 se trata como ausente', () {
      expect(
        BioGTelemetry.tryFromJson(<String, dynamic>{...base(), 'ph': 25.0})!
            .hasPhData,
        isFalse,
      );
      expect(
        BioGTelemetry.tryFromJson(<String, dynamic>{...base(), 'ph': -1.0})!
            .hasPhData,
        isFalse,
      );
    });

    test('un nitrógeno negativo se trata como ausente', () {
      final t = BioGTelemetry.tryFromJson(<String, dynamic>{
        ...base(),
        'n': -40.0,
      })!;
      expect(
        t.hasNitrogenData,
        isFalse,
        reason: 'Una lectura de N = -40 mg/kg inflaba el déficit calculado y '
            'producía una dosis de urea desproporcionada.',
      );
    });

    test('humedad de suelo fuera de 0-100 % se trata como ausente', () {
      expect(
        BioGTelemetry.tryFromJson(<String, dynamic>{
          ...base(),
          'soil_moisture_pct': 140.0,
        })!.hasSoilMoistureData,
        isFalse,
      );
    });

    test('una batería fuera de 0-100 % queda nula', () {
      expect(
        BioGTelemetry.tryFromJson(<String, dynamic>{
          ...base(),
          'battery_pct': 320.0,
        })!.batteryPct,
        isNull,
      );
    });
  });

  group('BioGTelemetry.tryFromJson · no rechaza datos reales', () {
    test('los extremos observados en producción siguen siendo válidos', () {
      // Mínimos y máximos reales de la tabla `telemetry` (966 lecturas).
      // Si un cambio de rangos rompe esta prueba, está rechazando datos que
      // el sistema ya recibió como buenos.
      final t = BioGTelemetry.tryFromJson(<String, dynamic>{
        ...base(),
        'air_temp_c': 31.12,
        'air_humidity_pct': 75.98,
        'soil_moisture_pct': 60.5,
        'soil_temp_c': 25.77,
        'ph': 6.53,
        'ec': 1.49,
        'resistance': 1.46,
        'n': 74.0,
        'p': 34.0,
        'k': 93.0,
        'battery_pct': 96.0,
      })!;

      expect(t.hasPhData, isTrue);
      expect(t.hasSoilMoistureData, isTrue);
      expect(t.hasSoilTempData, isTrue);
      expect(t.hasResistanceData, isTrue);
      expect(t.hasNitrogenData, isTrue);
      expect(t.hasPhosphorusData, isTrue);
      expect(t.hasPotassiumData, isTrue);
      expect(t.ph, closeTo(6.53, 0.0001));
      expect(t.batteryPct, closeTo(96.0, 0.0001));
    });

    test('un cero legítimo sigue siendo un dato presente', () {
      final t = BioGTelemetry.tryFromJson(<String, dynamic>{
        ...base(),
        'n': 0.0,
      })!;
      expect(t.hasNitrogenData, isTrue);
      expect(t.n, 0.0);
    });
  });
}
