// test/core/agro/traceability/recommendation_record_test.dart
//
// El registro auditable. Regla del Fundacional 2.1: si no se puede
// reconstruir con qué datos y qué reglas se emitió, no es una recomendación
// oficial de BIO-G.

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_engine.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_inputs.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/agro/traceability/engine_versions.dart';
import 'package:bio_g/core/agro/traceability/recommendation_record.dart';
import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 8, 3, 12);
  const String deviceId = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';

  final weather = AgronomicWeatherSnapshot(
    lat: 19.4,
    lon: -99.1,
    fetchedAt: now.subtract(const Duration(minutes: 20)),
    source: WeatherSnapshotSource.forecast,
    airTempC: 27,
    airHumidityPct: 44,
    rain: const RainOutlook(probNext24hPct: 10, expectedNext24hMm: 0),
    et0TodayMm: 5.4,
    et0Source: Et0Source.openMeteoFao56,
  );

  /// Decisión sin hora de medición: el motor no puede establecer vigencia.
  IrrigationDecision decisionWithoutTimestamp(double moisture) {
    return const IrrigationEngine().decide(
      IrrigationEngineInput(
        now: now,
        moisture: MoistureReading(percent: moisture, isPresent: true),
        weather: weather,
      ),
    );
  }

  /// Decisión completa y utilizable: déficit real, lectura vigente, sin lluvia.
  IrrigationDecision realDecision() {
    return const IrrigationEngine().decide(
      IrrigationEngineInput(
        now: now,
        moisture: MoistureReading(
          percent: 18,
          isPresent: true,
          measuredAt: now.subtract(const Duration(minutes: 12)),
        ),
        weather: weather,
        deviceId: deviceId,
        cropId: 'maize',
        stageKey: 'vegetative',
        stageLabel: 'Crecimiento vegetativo',
        moistureTarget: const AgroRange(
          lowMax: 20,
          optimalMin: 30,
          optimalMax: 55,
          highMin: 65,
        ),
      ),
    );
  }

  group('identidad estable', () {
    test('el id de lectura es reproducible', () {
      final a = RecommendationRecord.buildReadingId(deviceId, now);
      final b = RecommendationRecord.buildReadingId(deviceId, now);
      expect(a, b);
      expect(a, contains(deviceId));
    });

    test('recalcular la misma lectura produce el mismo id', () {
      final id1 = RecommendationRecord.buildId(
        kind: RecommendationKind.irrigation,
        readingId: 'r1',
        engineVersion: '1.0.0',
      );
      final id2 = RecommendationRecord.buildId(
        kind: RecommendationKind.irrigation,
        readingId: 'r1',
        engineVersion: '1.0.0',
      );
      expect(id1, id2);
    });

    test('otra versión del motor produce OTRO registro', () {
      // La historia de lo que se aconsejó no puede reescribirse cuando cambian
      // las reglas.
      final v1 = RecommendationRecord.buildId(
        kind: RecommendationKind.irrigation,
        readingId: 'r1',
        engineVersion: '1.0.0',
      );
      final v2 = RecommendationRecord.buildId(
        kind: RecommendationKind.irrigation,
        readingId: 'r1',
        engineVersion: '1.1.0',
      );
      expect(v1, isNot(v2));
    });

    test('riego y fertilización sobre la misma lectura son distintos', () {
      final riego = RecommendationRecord.buildId(
        kind: RecommendationKind.irrigation,
        readingId: 'r1',
        engineVersion: '1.0.0',
      );
      final fert = RecommendationRecord.buildId(
        kind: RecommendationKind.fertilization,
        readingId: 'r1',
        engineVersion: '1.0.0',
      );
      expect(riego, isNot(fert));
    });
  });

  group('evidencia completa', () {
    test('conserva motor, catálogo, etapa, clima y razones', () {
      final record = RecommendationRecord.fromIrrigationDecision(
        decision: realDecision(),
        deviceId: deviceId,
        readingTimestamp: now,
        userId: 'user-1',
        cropId: 'maize',
        cropLabel: 'Maíz',
        varietyAlias: 'DK-2069',
        catalogVersion: '2.1',
        parcelLabel: 'Lote norte',
        parcelLat: 19.4,
        parcelLon: -99.1,
        moistureIsPresent: true,
        moistureIsCalibrated: true,
        moistureAgeMinutes: 12,
      );

      expect(record.engineVersion, BioGEngineVersions.irrigation);
      expect(
        record.schemaVersion,
        BioGEngineVersions.recommendationRecordSchema,
      );
      expect(record.catalogVersion, '2.1');
      expect(record.stageLabel, 'Crecimiento vegetativo');
      expect(record.varietyAlias, 'DK-2069');
      expect(record.parcelLabel, 'Lote norte');
      expect(record.weather, isNotNull);
      expect(record.weather!.et0TodayMm, 5.4);
      expect(record.reasons, isNotEmpty);
      expect(record.userResponse, UserResponse.pending);
    });

    test('la métrica guarda unidad, presencia y antigüedad', () {
      final record = RecommendationRecord.fromIrrigationDecision(
        decision: realDecision(),
        deviceId: deviceId,
        readingTimestamp: now,
        moistureIsPresent: true,
        moistureIsCalibrated: false,
        moistureAgeMinutes: 12,
      );

      final metric = record.metrics.single;
      expect(metric.key, 'soilMoisture');
      expect(metric.unit, '%');
      expect(metric.isPresent, isTrue);
      expect(metric.isCalibrated, isFalse);
      expect(metric.ageMinutes, 12);
      expect(metric.value, 18);
    });

    test('las limitaciones declaradas se guardan aparte de las razones', () {
      final record = RecommendationRecord.fromIrrigationDecision(
        decision: realDecision(),
        deviceId: deviceId,
        readingTimestamp: now,
      );

      // Sin perfil de suelo capturado, el motor declara la limitación y el
      // registro la conserva.
      expect(record.limitations, isNotEmpty);
      expect(
        record.limitations.any((l) => l.contains('perfil de suelo')),
        isTrue,
      );
    });
  });

  group('respuesta del usuario', () {
    test('empieza pendiente y se puede cerrar', () {
      final record = RecommendationRecord.fromIrrigationDecision(
        decision: realDecision(),
        deviceId: deviceId,
        readingTimestamp: now,
      );

      expect(record.userResponse, UserResponse.pending);
      expect(record.isAnswered, isFalse);

      final answered = record.respond(UserResponse.performed, at: now);
      expect(answered.userResponse, UserResponse.performed);
      expect(answered.isAnswered, isTrue);
      expect(answered.respondedAt, now);
      // Responder no altera la evidencia.
      expect(answered.id, record.id);
      expect(answered.reasons, record.reasons);
    });
  });

  group('serialización', () {
    test('ida y vuelta conserva todo lo auditable', () {
      final original = RecommendationRecord.fromIrrigationDecision(
        decision: realDecision(),
        deviceId: deviceId,
        readingTimestamp: now,
        userId: 'user-1',
        catalogVersion: '2.1',
      );

      final restored = RecommendationRecord.fromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.engineVersion, original.engineVersion);
      expect(restored.catalogVersion, '2.1');
      expect(restored.confidence01, original.confidence01);
      expect(restored.metrics.length, original.metrics.length);
      expect(restored.metrics.single.isPresent, isTrue);
      expect(restored.weather?.et0TodayMm, 5.4);
      expect(restored.reasons, original.reasons);
      expect(restored.limitations, original.limitations);
    });

    test('un json ilegible devuelve null en vez de lanzar', () {
      expect(
        RecommendationRecord.fromJson(<String, dynamic>{'roto': true}),
        isNull,
      );
    });
  });

  test('la decisión real sí es una recomendación registrable', () {
    final decision = realDecision();
    expect(decision.action, IrrigationAction.regar);
    expect(decision.action.isRecommendation, isTrue);
  });

  test('una decisión sin datos suficientes no es una recomendación', () {
    // El recorder la descarta: guardarla diría "BIO-G recomendó" algo que
    // nunca recomendó.
    final decision = decisionWithoutTimestamp(15);
    expect(decision.action, IrrigationAction.datosInsuficientes);
    expect(decision.action.isRecommendation, isFalse);
  });
}
