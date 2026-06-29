// test/core/pear_tree/pear_tree_agro_score_engine_test.dart
//
// El motor de la pera delega en el motor genérico de árbol. Reglas: "alto útil"
// no penaliza ni alerta; solo el exceso real (>= highMin) baja el ring y avisa.
// Contrato v1.5: fruit_fill NO usa copy de cosecha/madurez; harvest_maturity sí.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/agro/pear_tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_universal_profile.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

BioGTelemetry _tele({
  double soilMoisturePct = 75,
  double soilTempC = 22,
  double airTempC = 20,
  double airHumidityPct = 55,
  double ph = 6.4,
  double ec = 1.0,
  double resistance = 0.8,
  double n = 35,
  double p = 45,
  double k = 110,
}) {
  return BioGTelemetry(
    deviceId: 'pear-1',
    timestamp: DateTime.utc(2026, 6, 20, 10),
    airTempC: airTempC,
    airHumidityPct: airHumidityPct,
    soilMoisturePct: soilMoisturePct,
    soilTempC: soilTempC,
    ph: ph,
    ec: ec,
    resistance: resistance,
    n: n,
    p: p,
    k: k,
    batteryPct: 95,
    signalRssi: -54,
  );
}

({AgroEvalResult eval, AlertsState nextAlertsState}) _run(
  BioGTelemetry t, {
  String stage = TreeStageIds.fruitFill,
  String profileId = kPrSkip,
}) {
  return PearTreeAgroScoreEngine.evaluate(
    t: t,
    stageId: stage,
    stageLabelEs: treeStageDisplayName(stage),
    targets: resolvePearTreeTargets(stage),
    weights: resolvePearTreeStageWeights(stage),
    profileId: profileId,
  );
}

String _metricCopy(AgroMetricEval metric) {
  return [
    metric.shortRecommendationEs,
    metric.practicalRecommendationEs,
  ].whereType<String>().join(' ').toLowerCase();
}

void _expectNoHarvestCopy(String text) {
  for (final forbidden in <String>[
    'cosecha',
    'madurez',
    'maduración',
    'maduracion',
  ]) {
    expect(text, isNot(contains(forbidden)), reason: forbidden);
  }
}

void main() {
  group('Bandas de suelo de la pera (observación vs crítico real)', () {
    test('madurez + humedad 59% queda operativa y no tumba el ring', () {
      final out = _run(
        _tele(soilMoisturePct: 59),
        stage: TreeStageIds.harvestMaturity,
      );
      final moisture = out.eval.metrics[AgroMetricKey.soilMoisture]!;
      expect(moisture.band, AgroBand.optimal);
      expect(
        out.eval.suggestedAlertKeys,
        isNot(contains('tree.harvest_maturity.soilMoisture.critical')),
      );
      expect(out.eval.soilControlScore01, greaterThan(0.80));
    });

    test('llenado + humedad 59% queda en observación baja, no crítico', () {
      final out = _run(_tele(soilMoisturePct: 59));
      final moisture = out.eval.metrics[AgroMetricKey.soilMoisture]!;
      expect(moisture.band, AgroBand.low);
      expect(moisture.score01, greaterThan(0.70));
      expect(
        out.eval.suggestedAlertKeys,
        isNot(contains('tree.fruit_fill.soilMoisture.critical')),
      );
    });

    test('humedad 44% y 20% entran como déficit crítico real', () {
      final lowAlert = _run(_tele(soilMoisturePct: 44));
      final severe = _run(_tele(soilMoisturePct: 20));
      expect(
        lowAlert.eval.metrics[AgroMetricKey.soilMoisture]!.band,
        AgroBand.critical,
      );
      expect(
        severe.eval.metrics[AgroMetricKey.soilMoisture]!.band,
        AgroBand.critical,
      );
      expect(
        severe.eval.metrics[AgroMetricKey.soilMoisture]!.score01,
        lessThan(lowAlert.eval.metrics[AgroMetricKey.soilMoisture]!.score01),
      );
    });

    test('humedad 91% en madurez se lee como saturación, no déficit', () {
      final out = _run(
        _tele(soilMoisturePct: 91),
        stage: TreeStageIds.harvestMaturity,
      );
      final moisture = out.eval.metrics[AgroMetricKey.soilMoisture]!;
      expect(moisture.band, AgroBand.high);
      expect(
        out.eval.suggestedAlertKeys,
        contains('tree.harvest_maturity.soilMoisture.high'),
      );
    });

    test('dormancia suaviza frío de suelo frente a una etapa activa', () {
      final dormant = _run(_tele(soilTempC: 2), stage: TreeStageIds.dormancy);
      final active = _run(_tele(soilTempC: 2), stage: TreeStageIds.budbreak);
      expect(
        dormant.eval.metrics[AgroMetricKey.soilTemp]!.band,
        isNot(AgroBand.critical),
      );
      expect(
        active.eval.metrics[AgroMetricKey.soilTemp]!.band,
        AgroBand.critical,
      );
    });

    test('pH 7.6 advierte disponibilidad; pH 8.2 ya es extremo', () {
      final observation = _run(_tele(ph: 7.6));
      final extreme = _run(_tele(ph: 8.2));
      expect(observation.eval.metrics[AgroMetricKey.ph]!.band, AgroBand.high);
      expect(extreme.eval.metrics[AgroMetricKey.ph]!.band, AgroBand.critical);
    });

    test(
      'CE moderada no es crítica; extremo real sí (pera es salino-sensible)',
      () {
        final ecWatch = _run(_tele(ec: 2.0));
        final ecExtreme = _run(_tele(ec: 2.4));
        expect(ecWatch.eval.metrics[AgroMetricKey.ec]!.band, AgroBand.high);
        expect(
          ecExtreme.eval.metrics[AgroMetricKey.ec]!.band,
          AgroBand.critical,
        );
      },
    );
  });

  group('Bandas NPK de la pera (alto útil vs exceso)', () {
    test('todo en rango → óptimo, sin aviso, ring alto', () {
      final out = _run(_tele());
      final n = out.eval.metrics[AgroMetricKey.n]!;
      expect(n.band, AgroBand.optimal);
      expect(n.priorityLabel, NutrientPriorityLabel.noPriority);
      expect(out.eval.soilControlScore01, greaterThan(0.95));
      expect(
        out.eval.suggestedAlertKeys.where((k) => k.startsWith('npk.')),
        isEmpty,
      );
    });

    test('N=71 en llenado → EXCESO con aviso y ring más bajo', () {
      final baseline = _run(_tele()).eval.soilControlScore01;
      final out = _run(_tele(n: 71));
      final n = out.eval.metrics[AgroMetricKey.n]!;
      expect(n.priorityLabel, NutrientPriorityLabel.reviewAccumulation);
      expect(n.band, AgroBand.high);
      expect(
        out.eval.suggestedAlertKeys,
        contains('npk.n.review_accumulation'),
      );
      expect(out.eval.soilControlScore01, lessThan(baseline));
    });

    test('N=55 alto útil → banda alta SIN aviso ni penalización', () {
      final baseline = _run(_tele()).eval.soilControlScore01;
      final out = _run(_tele(n: 55));
      final n = out.eval.metrics[AgroMetricKey.n]!;
      expect(n.priorityLabel, NutrientPriorityLabel.possibleExcess);
      expect(n.band, AgroBand.high);
      expect(n.labelEs, 'Alto útil');
      expect(
        out.eval.suggestedAlertKeys.where((k) => k.startsWith('npk.n')),
        isEmpty,
      );
      expect(out.eval.soilControlScore01, closeTo(baseline, 1e-9));
    });

    test('K alto útil vs acumulación real en llenado', () {
      final baseline = _run(_tele()).eval.soilControlScore01;
      final usefulHigh = _run(_tele(k: 130));
      final accumulation = _run(_tele(k: 140));
      final kUseful = usefulHigh.eval.metrics[AgroMetricKey.k]!;
      final kAccum = accumulation.eval.metrics[AgroMetricKey.k]!;
      expect(kUseful.priorityLabel, NutrientPriorityLabel.possibleExcess);
      expect(kUseful.labelEs, 'Alto útil');
      expect(usefulHigh.eval.soilControlScore01, closeTo(baseline, 1e-9));
      expect(kAccum.priorityLabel, NutrientPriorityLabel.reviewAccumulation);
      expect(
        accumulation.eval.suggestedAlertKeys,
        contains('npk.k.review_accumulation'),
      );
      expect(accumulation.eval.soilControlScore01, lessThan(baseline));
    });

    test('P por debajo de lowMax en establecimiento → acción recomendada', () {
      final out = _run(
        _tele(p: 15, k: 50, n: 30),
        stage: TreeStageIds.rootEstablishment,
      );
      final p = out.eval.metrics[AgroMetricKey.p]!;
      expect(p.priorityLabel, NutrientPriorityLabel.actionRecommended);
      expect(p.band, AgroBand.critical);
      expect(out.eval.suggestedAlertKeys, contains('npk.p.action'));
    });
  });

  group('Contrato v1.5: identidad de etapa en copy NPK', () {
    test('N alto en llenado usa copy de calibre/llenado, NO de cosecha', () {
      final out = _run(_tele(n: 71), stage: TreeStageIds.fruitFill);
      final n = out.eval.metrics[AgroMetricKey.n]!;
      final copy = _metricCopy(n);
      expect(n.priorityLabel, NutrientPriorityLabel.reviewAccumulation);
      _expectNoHarvestCopy(copy);
      expect(copy, contains('llenado'));
    });

    test('N alto en madurez usa copy propio de cosecha/madurez', () {
      final out = _run(_tele(n: 71), stage: TreeStageIds.harvestMaturity);
      final n = out.eval.metrics[AgroMetricKey.n]!;
      final copy = _metricCopy(n);
      expect(n.priorityLabel, NutrientPriorityLabel.reviewAccumulation);
      expect(copy, anyOf(contains('cosecha'), contains('madurez')));
    });

    test('llenado y madurez generan recomendaciones distintas para N alto', () {
      final fruitFill = _run(
        _tele(n: 71),
        stage: TreeStageIds.fruitFill,
      ).eval.metrics[AgroMetricKey.n]!;
      final harvest = _run(
        _tele(n: 71),
        stage: TreeStageIds.harvestMaturity,
      ).eval.metrics[AgroMetricKey.n]!;
      expect(
        fruitFill.practicalRecommendationEs,
        isNot(harvest.practicalRecommendationEs),
      );
    });

    test('N alto en vegetativo menciona riesgo de fuego bacteriano', () {
      final out = _run(_tele(n: 80), stage: TreeStageIds.vegetativeGrowth);
      final n = out.eval.metrics[AgroMetricKey.n]!;
      expect(
        _metricCopy(n),
        anyOf(contains('fuego bacteriano'), contains('vigor')),
      );
    });
  });

  group('Modificador por perfil PR', () {
    test('N en exceso tardío penaliza MÁS en Anjou que en perfil general', () {
      final t = _tele(n: 71);
      final anjou = _run(
        t,
        stage: TreeStageIds.harvestMaturity,
        profileId: kPr02Anjou,
      ).eval.soilControlScore01;
      final generic = _run(
        t,
        stage: TreeStageIds.harvestMaturity,
        profileId: kPrSkip,
      ).eval.soilControlScore01;
      expect(anjou, lessThan(generic));
    });
  });

  group('Consistencia ring ↔ detalle NPK', () {
    test('la banda del eval coincide con la etiqueta de interpret()', () {
      for (final n in <double>[20, 35, 55, 71]) {
        final t = _tele(n: n);
        final evalMetric = _run(t).eval.metrics[AgroMetricKey.n]!;
        final interp = NutrientRecommendationEngine.interpret(
          nutrient: AgroMetricKey.n,
          rawPpm: n,
          cropKey: 'pear_tree',
          stageKey: TreeStageIds.fruitFill,
          profileId: kPrSkip,
          targets: resolvePearTreeTargets(TreeStageIds.fruitFill),
          weights: resolvePearTreeStageWeights(TreeStageIds.fruitFill),
          ph: t.ph,
          ec: t.ec,
          soilMoisturePct: t.soilMoisturePct,
        );
        expect(evalMetric.priorityLabel, interp.label, reason: 'N=$n label');
        expect(evalMetric.band, interp.label.agroBand, reason: 'N=$n band');
      }
    });
  });

  group('No-regresión: el árbol no afecta a granos', () {
    test('frijol con los mismos rangos conserva su etiqueta de exceso', () {
      final targets = resolvePearTreeTargets(TreeStageIds.fruitFill);
      final beanUsefulHigh = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: 55,
        cropKey: 'bean',
        stageKey: 'grainFill',
        targets: targets,
      );
      final pearUsefulHigh = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: 55,
        cropKey: 'pear_tree',
        stageKey: TreeStageIds.fruitFill,
        targets: targets,
      );
      // Misma banda interna, distinto label UX: bean penaliza, pera lo trata útil.
      expect(beanUsefulHigh.label, NutrientPriorityLabel.possibleExcess);
      expect(beanUsefulHigh.labelEs, 'Pausar (Exceso)');
      expect(pearUsefulHigh.labelEs, 'Alto útil');
    });
  });
}
