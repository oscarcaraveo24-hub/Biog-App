// test/core/agro/irrigation/irrigation_engine_test.dart
//
// Pruebas del motor de riego.
//
// El primer grupo cubre el defecto más caro del sistema anterior: un sensor de
// humedad ausente llegaba al motor como 0.0, caía por debajo del umbral bajo y
// producía "Riego recomendado" con severidad crítica, indistinguible de una
// recomendación real. Esa es la prueba que nunca existió.

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_engine.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_inputs.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';

/// Objetivo típico de humedad: crítico <20, bajo 20-30, óptimo 30-55, alto >65.
///
/// A nivel superior para poder usarlo como valor por defecto de un parámetro.
const AgroRange kTarget = AgroRange(
  lowMax: 20,
  optimalMin: 30,
  optimalMax: 55,
  highMin: 65,
);

void main() {
  const engine = IrrigationEngine();

  final DateTime now = DateTime.utc(2026, 8, 3, 12);

  AgronomicWeatherSnapshot weatherWith({
    int? probNext24h,
    double? expectedMm,
    double? observedLast24h,
    Duration age = Duration.zero,
    WeatherSnapshotSource source = WeatherSnapshotSource.forecast,
  }) {
    return AgronomicWeatherSnapshot(
      lat: 19.4,
      lon: -99.1,
      fetchedAt: now.subtract(age),
      source: source,
      airTempC: 24,
      airHumidityPct: 55,
      rain: RainOutlook(
        probNext24hPct: probNext24h,
        expectedNext24hMm: expectedMm,
        observedLast24hMm: observedLast24h,
      ),
      et0TodayMm: 4.2,
      et0Source: Et0Source.openMeteoFao56,
    );
  }

  IrrigationEngineInput inputWith({
    required MoistureReading moisture,
    AgronomicWeatherSnapshot? weather,
    AgroRange? moistureTarget = kTarget,
    bool isGenericMode = false,
    DateTime? lastIrrigationAt,
    bool isUnderCover = false,
    IrrigationPolicy policy = IrrigationPolicy.standard,
  }) {
    return IrrigationEngineInput(
      now: now,
      moisture: moisture,
      weather: weather ?? weatherWith(probNext24h: 5, expectedMm: 0),
      deviceId: 'dev-1',
      cropId: 'maize',
      stageKey: 'vegetative',
      stageLabel: 'Crecimiento vegetativo',
      moistureTarget: moistureTarget,
      lastIrrigationAt: lastIrrigationAt,
      isGenericMode: isGenericMode,
      isUnderCover: isUnderCover,
      policy: policy,
    );
  }

  MoistureReading reading(double pct, {Duration age = const Duration(minutes: 10)}) {
    return MoistureReading(
      percent: pct,
      isPresent: true,
      measuredAt: now.subtract(age),
    );
  }

  group('dato ausente', () {
    test('sensor sin humedad NO produce recomendación de riego', () {
      // Reproduce el bug histórico: el valor crudo es 0.0 (lo que sintetiza
      // BioGTelemetry) pero la bandera de presencia dice que no hubo dato.
      final decision = engine.decide(
        inputWith(
          moisture: MoistureReading.fromTelemetry(
            rawPercent: 0.0,
            hasData: false,
            measuredAt: now.subtract(const Duration(minutes: 5)),
          ),
        ),
      );

      expect(decision.action, IrrigationAction.datosInsuficientes);
      expect(decision.action.isRecommendation, isFalse);
      expect(decision.confidence01, 0.0);
      expect(
        decision.reasons.first.code,
        IrrigationReasonCode.moistureSensorAbsent,
      );
      expect(decision.headlineEs, isNot(contains('Riega')));
    });

    test('un 0 % realmente medido SÍ se trata como suelo seco', () {
      final decision = engine.decide(
        inputWith(
          moisture: MoistureReading.fromTelemetry(
            rawPercent: 0.0,
            hasData: true,
            measuredAt: now.subtract(const Duration(minutes: 5)),
          ),
        ),
      );

      expect(decision.action, IrrigationAction.regar);
      expect(decision.urgency, IrrigationUrgency.critical);
    });

    test('lectura sin hora de medición no decide', () {
      final decision = engine.decide(
        inputWith(
          moisture: const MoistureReading(percent: 15, isPresent: true),
        ),
      );

      expect(decision.action, IrrigationAction.datosInsuficientes);
      expect(
        decision.reasons.first.code,
        IrrigationReasonCode.moistureReadingStale,
      );
    });

    test('valor fuera de rango físico se rechaza, no se recorta', () {
      final decision = engine.decide(
        inputWith(moisture: reading(250)),
      );

      expect(decision.action, IrrigationAction.datosInsuficientes);
      expect(
        decision.reasons.first.code,
        IrrigationReasonCode.moistureReadingImplausible,
      );
      expect(decision.requiresHumanReview, isTrue);
    });

    test('modo genérico no recomienda riego', () {
      final decision = engine.decide(
        inputWith(moisture: reading(10), isGenericMode: true),
      );

      expect(decision.action, IrrigationAction.datosInsuficientes);
      expect(
        decision.reasons.first.code,
        IrrigationReasonCode.noCropConfigured,
      );
    });

    test('sin objetivo de etapa pide revisión, no ordena regar', () {
      final decision = engine.decide(
        inputWith(moisture: reading(10), moistureTarget: null),
      );

      expect(decision.action, IrrigationAction.revisar);
      expect(decision.requiresHumanReview, isTrue);
    });
  });

  group('vigencia de la lectura', () {
    test('lectura más vieja que el límite no decide', () {
      final decision = engine.decide(
        inputWith(moisture: reading(12, age: const Duration(hours: 9))),
      );

      expect(decision.action, IrrigationAction.datosInsuficientes);
      expect(
        decision.reasons.first.code,
        IrrigationReasonCode.moistureReadingStale,
      );
    });

    test('la lectura reciente da más confianza que la que está por vencer', () {
      final fresh = engine.decide(
        inputWith(moisture: reading(25, age: const Duration(minutes: 5))),
      );
      final old = engine.decide(
        inputWith(moisture: reading(25, age: const Duration(hours: 5))),
      );

      expect(fresh.confidence01, greaterThan(old.confidence01));
    });

    test('la decisión nunca sobrevive a la lectura que la fundamenta', () {
      final decision = engine.decide(
        inputWith(moisture: reading(25, age: const Duration(hours: 5))),
      );

      // Quedan 1 h de vigencia de lectura, menos que las 6 h de la decisión.
      expect(decision.validUntil, isNotNull);
      expect(
        decision.validUntil!.difference(now).inMinutes,
        lessThanOrEqualTo(60),
      );
    });
  });

  group('veto por lluvia', () {
    test('déficit + lluvia probable y suficiente => ESPERAR', () {
      final decision = engine.decide(
        inputWith(
          moisture: reading(25),
          weather: weatherWith(probNext24h: 80, expectedMm: 12),
        ),
      );

      expect(decision.action, IrrigationAction.esperar);
      expect(
        decision.reasons.map((r) => r.code),
        contains(IrrigationReasonCode.rainExpectedSoon),
      );
      expect(decision.detailEs, contains('lluvia'));
    });

    test('probabilidad alta pero volumen ridículo NO veta el riego', () {
      // 90 % de 0.3 mm no moja la zona radicular. Vetar por eso sería peor que
      // no mirar el clima.
      final decision = engine.decide(
        inputWith(
          moisture: reading(25),
          weather: weatherWith(probNext24h: 90, expectedMm: 0.3),
        ),
      );

      expect(decision.action, isNot(IrrigationAction.esperar));
    });

    test('volumen alto pero probabilidad baja NO veta el riego', () {
      final decision = engine.decide(
        inputWith(
          moisture: reading(25),
          weather: weatherWith(probNext24h: 20, expectedMm: 30),
        ),
      );

      expect(decision.action, isNot(IrrigationAction.esperar));
    });

    test('bajo techo la lluvia no veta', () {
      final decision = engine.decide(
        inputWith(
          moisture: reading(25),
          weather: weatherWith(probNext24h: 95, expectedMm: 40),
          isUnderCover: true,
          policy: IrrigationPolicy.potted,
        ),
      );

      expect(decision.action, IrrigationAction.regar);
    });
  });

  group('contradicción sensor / clima', () {
    test('llovió fuerte pero el sensor marca crítico => REVISAR', () {
      final decision = engine.decide(
        inputWith(
          moisture: reading(8),
          weather: weatherWith(
            probNext24h: 10,
            expectedMm: 0,
            observedLast24h: 25,
          ),
        ),
      );

      expect(decision.action, IrrigationAction.revisar);
      expect(
        decision.reasons.map((r) => r.code),
        contains(IrrigationReasonCode.sensorWeatherConflict),
      );
      expect(decision.requiresHumanReview, isTrue);
      expect(decision.requiresConfirmation, isTrue);
    });
  });

  group('sin clima disponible', () {
    test('déficit crítico riega igual, pero lo declara', () {
      final decision = engine.decide(
        inputWith(
          moisture: reading(8),
          weather: AgronomicWeatherSnapshot.unavailable(at: now),
        ),
      );

      expect(decision.action, IrrigationAction.regar);
      expect(
        decision.limitations.map((r) => r.code),
        contains(IrrigationReasonCode.weatherUnavailable),
      );
      expect(decision.hasWeatherEvidence, isFalse);
    });

    test('déficit moderado sin clima pide revisión', () {
      final decision = engine.decide(
        inputWith(
          moisture: reading(25),
          weather: AgronomicWeatherSnapshot.unavailable(at: now),
        ),
      );

      expect(decision.action, IrrigationAction.revisar);
      expect(decision.requiresHumanReview, isTrue);
    });

    test('un pronóstico vencido cuenta como no disponible', () {
      final decision = engine.decide(
        inputWith(
          moisture: reading(25),
          weather: weatherWith(
            probNext24h: 5,
            expectedMm: 0,
            age: const Duration(hours: 30),
          ),
        ),
      );

      expect(decision.action, IrrigationAction.revisar);
      expect(
        decision.limitations.map((r) => r.code),
        contains(IrrigationReasonCode.weatherStale),
      );
    });
  });

  group('estados sin déficit', () {
    test('humedad dentro del objetivo => NO REGAR', () {
      final decision = engine.decide(inputWith(moisture: reading(42)));

      expect(decision.action, IrrigationAction.noRegar);
      expect(decision.urgency, IrrigationUrgency.none);
      expect(decision.requiresConfirmation, isFalse);
    });

    test('saturación => NO REGAR con motivo explícito', () {
      final decision = engine.decide(inputWith(moisture: reading(80)));

      expect(decision.action, IrrigationAction.noRegar);
      expect(
        decision.reasons.map((r) => r.code),
        contains(IrrigationReasonCode.soilSaturated),
      );
    });

    test('por encima del óptimo pero sin saturar => NO REGAR', () {
      final decision = engine.decide(inputWith(moisture: reading(60)));

      expect(decision.action, IrrigationAction.noRegar);
    });
  });

  group('riego reciente', () {
    test('déficit moderado con riego reciente => ESPERAR', () {
      final decision = engine.decide(
        inputWith(
          moisture: reading(25),
          lastIrrigationAt: now.subtract(const Duration(hours: 3)),
        ),
      );

      expect(decision.action, IrrigationAction.esperar);
      expect(
        decision.reasons.map((r) => r.code),
        contains(IrrigationReasonCode.recentIrrigationLogged),
      );
    });

    test('déficit crítico riega aunque haya riego reciente', () {
      final decision = engine.decide(
        inputWith(
          moisture: reading(5),
          lastIrrigationAt: now.subtract(const Duration(hours: 3)),
        ),
      );

      expect(decision.action, IrrigationAction.regar);
    });
  });

  group('evidencia y trazabilidad', () {
    test('toda decisión declara motor, evidencia y limitaciones', () {
      final decision = engine.decide(inputWith(moisture: reading(25)));

      expect(decision.engineVersion, IrrigationEngine.version);
      expect(decision.evidence['moisturePct'], 25);
      expect(decision.evidence['moisturePresent'], isTrue);
      expect(decision.evidence['weather'], isNotNull);
      // Sin perfil de suelo capturado, el motor lo dice en vez de callarlo.
      expect(
        decision.limitations.map((r) => r.code),
        contains(IrrigationReasonCode.soilProfileMissing),
      );
    });

    test('V1-A nunca inventa una lámina en milímetros', () {
      final decision = engine.decide(inputWith(moisture: reading(10)));
      expect(decision.depth, isNull);
    });

    test('una recomendación de regar cita el clima que usó', () {
      final decision = engine.decide(
        inputWith(
          moisture: reading(25),
          weather: weatherWith(probNext24h: 10, expectedMm: 0),
        ),
      );

      expect(decision.action, IrrigationAction.regar);
      expect(decision.weather, isNotNull);
      expect(decision.hasWeatherEvidence, isTrue);
      expect(
        decision.reasons.map((r) => r.code),
        contains(IrrigationReasonCode.noRainExpected),
      );
    });
  });
}
