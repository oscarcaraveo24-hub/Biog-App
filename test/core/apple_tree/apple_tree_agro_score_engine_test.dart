// test/core/apple_tree/apple_tree_agro_score_engine_test.dart
//
// El motor del manzano espeja al de granos: suelo por AgroRange, NPK por
// NutrientRecommendationEngine. Regla del manzano: "alto útil" no penaliza ni
// alerta; sólo el exceso real (>= highMin) baja el ring y avisa. El N en exceso
// tardío penaliza más en AP-02 Red / AP-04 Gala (color/calidad).

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/apple_tree_agro_score_engine.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_universal_profile.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

BioGTelemetry _tele({
  double soilMoisturePct = 75,
  double soilTempC = 22,
  double ph = 6.4,
  double ec = 1.0,
  double resistance = 0.8,
  double n = 35,
  double p = 45,
  double k = 80,
}) {
  return BioGTelemetry(
    deviceId: 'tree-1',
    timestamp: DateTime.utc(2026, 6, 14, 10),
    airTempC: 20,
    airHumidityPct: 55,
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
  String profileId = kApSkip,
}) {
  return AppleTreeAgroScoreEngine.evaluate(
    t: t,
    stageId: stage,
    stageLabelEs: treeStageDisplayName(stage),
    targets: resolveAppleTreeTargets(stage),
    weights: resolveAppleTreeStageWeights(stage),
    profileId: profileId,
  );
}

void main() {
  group('Bandas NPK del manzano (doc 05 + decisión alto útil vs exceso)', () {
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

    test('N=71 en llenado → EXCESO (no óptimo) con aviso y ring más bajo', () {
      final baseline = _run(_tele()).eval.soilControlScore01;
      final out = _run(_tele(n: 71));
      final n = out.eval.metrics[AgroMetricKey.n]!;

      expect(n.priorityLabel, NutrientPriorityLabel.reviewAccumulation);
      expect(n.band, AgroBand.high); // exceso se muestra como banda alta
      expect(n.band, isNot(AgroBand.optimal)); // el bug era "Óptimo"
      expect(out.eval.suggestedAlertKeys, contains('npk.n.review_accumulation'));
      expect(out.eval.soilControlScore01, lessThan(baseline));
    });

    test('N=55 alto útil → banda alta SIN aviso y SIN penalización notable', () {
      final baseline = _run(_tele()).eval.soilControlScore01;
      final out = _run(_tele(n: 55));
      final n = out.eval.metrics[AgroMetricKey.n]!;

      expect(n.priorityLabel, NutrientPriorityLabel.possibleExcess);
      expect(n.band, AgroBand.high);
      // Sin aviso de N.
      expect(
        out.eval.suggestedAlertKeys.where((k) => k.startsWith('npk.n')),
        isEmpty,
      );
      // Sin penalización: el ring queda igual que con todo en rango.
      expect(out.eval.soilControlScore01, closeTo(baseline, 1e-9));
    });

    test('P por debajo de lowMax en establecimiento → acción recomendada', () {
      final out = _run(
        _tele(p: 30, k: 50, n: 35),
        stage: TreeStageIds.rootEstablishment,
      );
      final p = out.eval.metrics[AgroMetricKey.p]!;
      expect(p.priorityLabel, NutrientPriorityLabel.actionRecommended);
      expect(p.band, AgroBand.critical);
      expect(out.eval.suggestedAlertKeys, contains('npk.p.action'));
    });

    test(
      'N en exceso tardío penaliza MÁS en AP-02 Red que en perfil general',
      () {
        final t = _tele(n: 70);
        final red = _run(
          t,
          stage: TreeStageIds.harvestMaturity,
          profileId: kAp02Red,
        ).eval.soilControlScore01;
        final gala = _run(
          t,
          stage: TreeStageIds.harvestMaturity,
          profileId: kAp04Gala,
        ).eval.soilControlScore01;
        final generic = _run(
          t,
          stage: TreeStageIds.harvestMaturity,
          profileId: kApSkip,
        ).eval.soilControlScore01;

        expect(red, lessThan(generic));
        expect(gala, lessThan(generic));
      },
    );
  });

  group('Consistencia ring ↔ detalle NPK', () {
    test('la banda del eval coincide con la etiqueta de interpret()', () {
      for (final n in <double>[20, 35, 55, 71]) {
        final t = _tele(n: n);
        final evalMetric = _run(t).eval.metrics[AgroMetricKey.n]!;
        final interp = NutrientRecommendationEngine.interpret(
          nutrient: AgroMetricKey.n,
          rawPpm: n,
          cropKey: 'apple_tree',
          stageKey: TreeStageIds.fruitFill,
          profileId: kApSkip,
          targets: resolveAppleTreeTargets(TreeStageIds.fruitFill),
          weights: resolveAppleTreeStageWeights(TreeStageIds.fruitFill),
          ph: t.ph,
          ec: t.ec,
          soilMoisturePct: t.soilMoisturePct,
        );
        // El detalle muestra evalMetric.band y interpret().labelEs: deben venir
        // de la misma etiqueta para no contradecirse.
        expect(evalMetric.priorityLabel, interp.label, reason: 'N=$n label');
        expect(evalMetric.band, interp.label.agroBand, reason: 'N=$n band');
      }
    });
  });

  group('No-regresión de granos: el cambio no afecta al frijol', () {
    test('frijol N alto/óptimo conserva su clasificación en el motor común', () {
      final targets = resolveAppleTreeTargets(TreeStageIds.fruitFill);
      // El motor compartido clasifica por el rango de suelo, sin el modificador
      // de manzano (gateado por cultivo). Mismo rango, cropKey distinto.
      final beanHigh = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: 71,
        cropKey: 'bean',
        stageKey: 'grainFill',
        targets: targets,
      );
      final beanOk = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: 35,
        cropKey: 'bean',
        stageKey: 'grainFill',
        targets: targets,
      );
      expect(beanHigh.label, NutrientPriorityLabel.reviewAccumulation);
      expect(beanOk.label, NutrientPriorityLabel.noPriority);
    });
  });
}
