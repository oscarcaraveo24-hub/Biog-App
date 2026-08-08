// test/core/weather/agronomic_weather_snapshot_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 8, 3, 12);

  AgronomicWeatherSnapshot snapshotAged(Duration age) {
    return AgronomicWeatherSnapshot(
      lat: 19.4,
      lon: -99.1,
      fetchedAt: now.subtract(age),
      source: WeatherSnapshotSource.forecast,
      airTempC: 24,
      rain: const RainOutlook(probNext24hPct: 30, expectedNext24hMm: 1.2),
      et0TodayMm: 4.2,
      et0Source: Et0Source.openMeteoFao56,
    );
  }

  group('frescura', () {
    test('menos de 1 h es fresco', () {
      expect(
        snapshotAged(const Duration(minutes: 30)).freshnessAt(now),
        WeatherFreshness.fresh,
      );
    });

    test('entre 1 y 6 h envejece', () {
      expect(
        snapshotAged(const Duration(hours: 3)).freshnessAt(now),
        WeatherFreshness.aging,
      );
    });

    test('más de 24 h vence y deja de servir para decidir', () {
      final old = snapshotAged(const Duration(hours: 30));
      expect(old.freshnessAt(now), WeatherFreshness.expired);
      expect(old.isUsableForDecisionAt(now), isFalse);
    });

    test('la penalización de confianza crece con la antigüedad', () {
      expect(
        WeatherFreshness.fresh.confidencePenalty,
        lessThan(WeatherFreshness.aging.confidencePenalty),
      );
      expect(
        WeatherFreshness.aging.confidencePenalty,
        lessThan(WeatherFreshness.stale.confidencePenalty),
      );
    });
  });

  group('honestidad de la caché', () {
    test('marcar como caché NO rejuvenece el dato', () {
      // Es el defecto que tenía la pantalla de Ambiente: reutilizaba el
      // pronóstico anterior pero reescribía `updatedAt` con la hora actual, así
      // que el usuario veía "Se espera lluvia el jueves" junto a "Actualizado
      // hace unos segundos".
      final original = snapshotAged(const Duration(hours: 5));
      final cached = original.asCached();

      expect(cached.fetchedAt, original.fetchedAt);
      expect(cached.source, WeatherSnapshotSource.cache);
      expect(cached.ageAt(now).inHours, 5);
      expect(cached.freshnessLabelEs(now), contains('guardado'));
    });

    test('la etiqueta de antigüedad dice la verdad', () {
      expect(
        snapshotAged(const Duration(minutes: 20)).freshnessLabelEs(now),
        contains('20 min'),
      );
      expect(
        snapshotAged(const Duration(hours: 4)).freshnessLabelEs(now),
        contains('4 h'),
      );
    });
  });

  group('ausencia explícita', () {
    test('unavailable no sirve para decidir y no finge datos', () {
      final none = AgronomicWeatherSnapshot.unavailable(at: now);
      expect(none.isUnavailable, isTrue);
      expect(none.isUsableForDecisionAt(now), isFalse);
      expect(none.airTempC, isNull);
      expect(none.rain.probNext24hPct, isNull);
      expect(none.et0TodayMm, isNull);
    });

    test('una ventana de lluvia sin dato es null, nunca cero', () {
      const outlook = RainOutlook();
      expect(outlook.probNext24hPct, isNull);
      expect(outlook.expectedNext24hMm, isNull);
      expect(outlook.maxProbNext24hPct, isNull);
      expect(outlook.hasAnyForecast, isFalse);
    });

    test('maxProbNext24hPct toma la ventana más severa', () {
      const outlook = RainOutlook(
        probNext6hPct: 20,
        probNext12hPct: 75,
        probNext24hPct: 40,
      );
      expect(outlook.maxProbNext24hPct, 75);
    });
  });

  group('serialización', () {
    test('ida y vuelta conserva la evidencia', () {
      final original = snapshotAged(const Duration(hours: 2));
      final restored = AgronomicWeatherSnapshot.fromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.lat, original.lat);
      expect(restored.fetchedAt, original.fetchedAt);
      expect(restored.rain.probNext24hPct, 30);
      expect(restored.rain.expectedNext24hMm, 1.2);
      expect(restored.et0TodayMm, 4.2);
      expect(restored.et0Source, Et0Source.openMeteoFao56);
    });

    test('un json ilegible devuelve null en vez de lanzar', () {
      expect(
        AgronomicWeatherSnapshot.fromJson(<String, dynamic>{'nada': true}),
        isNull,
      );
      expect(
        AgronomicWeatherSnapshot.fromJson(<String, dynamic>{
          'fetchedAt': 'no-es-fecha',
        }),
        isNull,
      );
    });

    test('la evidencia compacta incluye lo que decide el riego', () {
      final evidence = snapshotAged(const Duration(hours: 1)).toEvidenceJson();
      expect(evidence['rainProb24hPct'], 30);
      expect(evidence['et0TodayMm'], 4.2);
      expect(evidence['source'], 'forecast');
      expect(evidence['fetchedAt'], isNotNull);
    });
  });

  test('currentOnly no habilita una decisión de riego', () {
    // Sin pronóstico no se puede aplicar el veto por lluvia, que es la mitad
    // del valor del motor.
    final currentOnly = AgronomicWeatherSnapshot(
      lat: 19.4,
      lon: -99.1,
      fetchedAt: now,
      source: WeatherSnapshotSource.currentOnly,
      airTempC: 24,
    );
    expect(currentOnly.isUsableForDecisionAt(now), isFalse);
  });
}
