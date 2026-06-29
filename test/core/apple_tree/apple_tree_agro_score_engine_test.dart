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
  double airTempC = 20,
  double airHumidityPct = 55,
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
  group('Bandas de suelo del manzano (observacion vs critico real)', () {
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

    test('llenado + humedad 59% queda en observacion baja, no critico', () {
      final out = _run(_tele(soilMoisturePct: 59));
      final moisture = out.eval.metrics[AgroMetricKey.soilMoisture]!;

      expect(moisture.band, AgroBand.low);
      expect(moisture.score01, greaterThan(0.70));
      expect(
        out.eval.suggestedAlertKeys,
        isNot(contains('tree.fruit_fill.soilMoisture.critical')),
      );
    });

    test('humedad 44% y 20% entran como deficit critico real', () {
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
        lessThan(
          lowAlert.eval.metrics[AgroMetricKey.soilMoisture]!.score01,
        ),
      );
    });

    test('humedad 91% se lee como exceso/saturacion, no como deficit', () {
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
      expect(
        out.eval.alerts.map((a) => a.type),
        contains(BioGAlertType.highSoilMoisture),
      );
    });

    test('temperatura apenas fuera de optimo no es critica', () {
      final watch = _run(
        _tele(soilTempC: 9),
        stage: TreeStageIds.budbreak,
      );
      final harvestFloor = _run(
        _tele(soilTempC: 10),
        stage: TreeStageIds.harvestMaturity,
      );
      final extreme = _run(
        _tele(soilTempC: 4),
        stage: TreeStageIds.budbreak,
      );

      expect(
        watch.eval.metrics[AgroMetricKey.soilTemp]!.band,
        isNot(AgroBand.critical),
      );
      expect(
        harvestFloor.eval.metrics[AgroMetricKey.soilTemp]!.band,
        AgroBand.optimal,
      );
      expect(
        extreme.eval.metrics[AgroMetricKey.soilTemp]!.band,
        AgroBand.critical,
      );
    });

    test('dormancia suaviza frio de suelo frente a una etapa activa', () {
      final dormant = _run(
        _tele(soilTempC: 2),
        stage: TreeStageIds.dormancy,
      );
      final active = _run(
        _tele(soilTempC: 2),
        stage: TreeStageIds.budbreak,
      );

      expect(
        dormant.eval.metrics[AgroMetricKey.soilTemp]!.band,
        isNot(AgroBand.critical),
      );
      expect(
        active.eval.metrics[AgroMetricKey.soilTemp]!.band,
        AgroBand.critical,
      );
      expect(
        dormant.eval.soilControlScore01,
        greaterThan(active.eval.soilControlScore01),
      );
    });

    test('pH 7.6 advierte disponibilidad; pH 8.2 ya es extremo', () {
      final observation = _run(_tele(ph: 7.6));
      final extreme = _run(_tele(ph: 8.2));

      expect(observation.eval.metrics[AgroMetricKey.ph]!.band, AgroBand.high);
      expect(
        extreme.eval.metrics[AgroMetricKey.ph]!.band,
        AgroBand.critical,
      );
    });

    test('CE y resistencia moderadas no son criticas; extremos reales si', () {
      final ecWatch = _run(
        _tele(ec: 2.1),
        stage: TreeStageIds.harvestMaturity,
      );
      final ecExtreme = _run(_tele(ec: 3.2));
      final resistanceWatch = _run(_tele(resistance: 2.1));
      final resistanceExtreme = _run(_tele(resistance: 3.2));

      expect(ecWatch.eval.metrics[AgroMetricKey.ec]!.band, AgroBand.high);
      expect(
        ecExtreme.eval.metrics[AgroMetricKey.ec]!.band,
        AgroBand.critical,
      );
      expect(
        resistanceWatch.eval.metrics[AgroMetricKey.resistance]!.band,
        AgroBand.high,
      );
      expect(
        resistanceExtreme.eval.metrics[AgroMetricKey.resistance]!.band,
        AgroBand.critical,
      );
    });

    test('CE alta con humedad baja eleva alerta salina transversal', () {
      final out = _run(_tele(ec: 2.2, soilMoisturePct: 50));

      expect(out.eval.metrics[AgroMetricKey.ec]!.band, AgroBand.high);
      expect(out.eval.metrics[AgroMetricKey.soilMoisture]!.band, AgroBand.low);
      expect(
        out.eval.alerts.map((a) => a.type),
        contains(BioGAlertType.ecOutOfRange),
      );
    });

    test('etapa unknown usa criterio conservador, no agresivo', () {
      final out = _run(
        _tele(soilMoisturePct: 59, soilTempC: 10),
        stage: TreeStageIds.unknown,
      );

      expect(
        out.eval.metrics[AgroMetricKey.soilMoisture]!.band,
        isNot(AgroBand.critical),
      );
      expect(
        out.eval.metrics[AgroMetricKey.soilTemp]!.band,
        isNot(AgroBand.critical),
      );
      expect(out.eval.soilControlScore01, greaterThan(0.75));
    });
  });

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
      expect(
        out.eval.suggestedAlertKeys,
        contains('npk.n.review_accumulation'),
      );
      expect(out.eval.soilControlScore01, lessThan(baseline));
    });

    test('N alto en llenado usa copy de calibre/fruto, no de cosecha', () {
      final out = _run(
        _tele(n: 71),
        stage: TreeStageIds.fruitFill,
        profileId: kAp01Golden,
      );
      final n = out.eval.metrics[AgroMetricKey.n]!;
      final copy = _metricCopy(n);

      expect(n.priorityLabel, NutrientPriorityLabel.reviewAccumulation);
      _expectNoHarvestCopy(copy);
      expect(copy, contains('llenado'));
      expect(copy, contains('calibre'));
      expect(copy, contains('fruto'));
      expect(copy, contains('k/ca'));
    });

    test('N alto en madurez usa copy propio de cosecha/madurez', () {
      final out = _run(_tele(n: 71), stage: TreeStageIds.harvestMaturity);
      final n = out.eval.metrics[AgroMetricKey.n]!;
      final copy = _metricCopy(n);

      expect(n.priorityLabel, NutrientPriorityLabel.reviewAccumulation);
      expect(copy, anyOf(contains('cosecha'), contains('madurez')));
    });

    test('N alto genera recomendaciones distintas en llenado y madurez', () {
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
      _expectNoHarvestCopy(_metricCopy(fruitFill));
      expect(_metricCopy(harvest), contains('madurez'));
    });

    test(
      'N=55 alto útil → banda alta SIN aviso y SIN penalización notable',
      () {
        final baseline = _run(_tele()).eval.soilControlScore01;
        final out = _run(_tele(n: 55));
        final n = out.eval.metrics[AgroMetricKey.n]!;

        expect(n.priorityLabel, NutrientPriorityLabel.possibleExcess);
        expect(n.band, AgroBand.high);
        expect(n.labelEs, 'Alto útil');
        expect(n.shortRecommendationEs, contains('alto útil'));
        final copy = _metricCopy(n);
        _expectNoHarvestCopy(copy);
        expect(copy, contains('llenado'));
        // Sin aviso de N.
        expect(
          out.eval.suggestedAlertKeys.where((k) => k.startsWith('npk.n')),
          isEmpty,
        );
        // Sin penalización: el ring queda igual que con todo en rango.
        expect(out.eval.soilControlScore01, closeTo(baseline, 1e-9));
      },
    );

    test('K alto en llenado es alto util; acumulacion real si supera umbral', () {
      final baseline = _run(_tele()).eval.soilControlScore01;
      final usefulHigh = _run(_tele(k: 110));
      final accumulation = _run(_tele(k: 140));
      final kUseful = usefulHigh.eval.metrics[AgroMetricKey.k]!;
      final kAccumulation = accumulation.eval.metrics[AgroMetricKey.k]!;

      expect(kUseful.priorityLabel, NutrientPriorityLabel.possibleExcess);
      expect(kUseful.labelEs, 'Alto útil');
      expect(kUseful.band, AgroBand.high);
      expect(
        usefulHigh.eval.suggestedAlertKeys.where((k) => k.startsWith('npk.k')),
        isEmpty,
      );
      expect(usefulHigh.eval.soilControlScore01, closeTo(baseline, 1e-9));

      expect(
        kAccumulation.priorityLabel,
        NutrientPriorityLabel.reviewAccumulation,
      );
      expect(
        accumulation.eval.suggestedAlertKeys,
        contains('npk.k.review_accumulation'),
      );
      expect(accumulation.eval.soilControlScore01, lessThan(baseline));
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

  group('Alertas por etapa del manzano', () {
    test('plantación con saturación avisa sin recomendar más riego', () {
      final out = _run(
        _tele(soilMoisturePct: 95),
        stage: TreeStageIds.plantingTransplant,
      );

      expect(
        out.eval.alerts.map((a) => a.type),
        contains(BioGAlertType.highSoilMoisture),
      );
      expect(
        out.eval.alerts.map((a) => a.body).join(' '),
        contains('no empujes más riego'),
      );
    });

    test('brotación con frío avisa riesgo de helada tardía', () {
      final out = _run(_tele(airTempC: 2), stage: TreeStageIds.budbreak);

      expect(
        out.eval.alerts.map((a) => a.type),
        contains(BioGAlertType.airTempExtreme),
      );
      expect(
        out.eval.alerts.map((a) => a.title),
        contains('Riesgo de helada en brotación'),
      );
    });

    test('madurez con N en exceso real avisa calidad/color', () {
      final out = _run(_tele(n: 71), stage: TreeStageIds.harvestMaturity);

      expect(
        out.eval.alerts.map((a) => a.type),
        contains(BioGAlertType.stageEvent),
      );
      expect(
        out.eval.alerts.map((a) => a.title),
        contains('N alto cerca de madurez'),
      );
      expect(out.eval.alerts.map((a) => a.body).join(' '), contains('color'));
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
      final beanUsefulHigh = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: 55,
        cropKey: 'bean',
        stageKey: 'grainFill',
        targets: targets,
      );
      expect(beanHigh.label, NutrientPriorityLabel.reviewAccumulation);
      expect(beanOk.label, NutrientPriorityLabel.noPriority);
      expect(beanUsefulHigh.label, NutrientPriorityLabel.possibleExcess);
      expect(beanUsefulHigh.labelEs, 'Pausar (Exceso)');
    });
  });
}
