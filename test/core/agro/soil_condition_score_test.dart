// test/core/agro/soil_condition_score_test.dart
//
// El AgroScore limpio (Guía v0.4, §6 y §7): condición física del suelo con
// N/P/K a peso cero, señal ausente fuera del denominador y cobertura aparte.
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/soil_condition_score.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:flutter_test/flutter_test.dart';

AgroMetricEval _m(AgroBand band, double score) =>
    AgroMetricEval(band: band, score01: score, labelEs: band.labelEs, value: 1);

const StageWeights _w = StageWeights(
  moisture: 0.35,
  soilTemp: 0.15,
  resistance: 0.15,
  ph: 0.15,
  ec: 0.20,
  npk: 0.5, // heredado: no debe mover nada
);

void main() {
  group('SoilConditionScore', () {
    test('N/P/K no mueven el puntaje aunque vengan con banda y valor', () {
      final Map<AgroMetricKey, AgroMetricEval> base = {
        AgroMetricKey.soilMoisture: _m(AgroBand.optimal, 1.0),
        AgroMetricKey.soilTemp: _m(AgroBand.optimal, 1.0),
        AgroMetricKey.resistance: _m(AgroBand.optimal, 1.0),
        AgroMetricKey.ph: _m(AgroBand.optimal, 1.0),
        AgroMetricKey.ec: _m(AgroBand.optimal, 1.0),
      };
      final withNpk = <AgroMetricKey, AgroMetricEval>{
        ...base,
        AgroMetricKey.n: _m(AgroBand.critical, 0.0),
        AgroMetricKey.p: _m(AgroBand.critical, 0.0),
        AgroMetricKey.k: _m(AgroBand.critical, 0.0),
      };
      final a = SoilConditionScore.compute(metrics: base, weights: _w);
      final b = SoilConditionScore.compute(metrics: withNpk, weights: _w);
      expect(a.score01, 1.0);
      expect(b.score01, a.score01);
      expect(b.coverage.evaluable, 5);
      expect(b.coverage.present, 5);
    });

    test('una señal ausente sale del denominador; la cobertura lo declara', () {
      final metrics = <AgroMetricKey, AgroMetricEval>{
        AgroMetricKey.soilMoisture: _m(AgroBand.optimal, 1.0),
        AgroMetricKey.soilTemp: _m(AgroBand.optimal, 1.0),
        AgroMetricKey.resistance: _m(AgroBand.optimal, 1.0),
        AgroMetricKey.ec: _m(AgroBand.optimal, 1.0),
        // Sin dato: banda desconocida, como devuelve cada motor ante un NaN.
        AgroMetricKey.ph: const AgroMetricEval(
          band: AgroBand.unknown,
          score01: 0.0,
          labelEs: '—',
        ),
      };
      final r = SoilConditionScore.compute(metrics: metrics, weights: _w);
      expect(r.score01, 1.0, reason: 'el pH ausente no arrastra el promedio');
      expect(r.coverage.present, 4);
      expect(r.coverage.isComplete, isFalse);
      expect(r.coverage.labelEs, '4 de 5 señales');
      expect(r.coverage.missingLabelEs, contains('pH'));
    });

    test('sin ninguna señal el puntaje es 0 y la cobertura lo dice', () {
      final r = SoilConditionScore.compute(
        metrics: const <AgroMetricKey, AgroMetricEval>{},
        weights: _w,
      );
      expect(r.score01, 0.0);
      expect(r.coverage.hasAnySignal, isFalse);
    });

    test('la penalización crítica se aplica una sola vez', () {
      final metrics = <AgroMetricKey, AgroMetricEval>{
        AgroMetricKey.soilMoisture: _m(AgroBand.critical, 0.2),
        AgroMetricKey.soilTemp: _m(AgroBand.optimal, 1.0),
        AgroMetricKey.resistance: _m(AgroBand.optimal, 1.0),
        AgroMetricKey.ph: _m(AgroBand.optimal, 1.0),
        AgroMetricKey.ec: _m(AgroBand.optimal, 1.0),
      };
      final r = SoilConditionScore.compute(
        metrics: metrics,
        weights: _w,
        criticalPenalty: 0.7,
      );
      expect(r.rawScore01, closeTo(0.35 * 0.2 + 0.65, 1e-9));
      expect(r.score01, closeTo(r.rawScore01 * 0.7, 1e-9));
    });
  });
}
