// test/core/peach_tree/peach_tree_agro_score_engine_test.dart
//
// El motor del durazno delega en el motor genérico de árbol. Reglas: "alto útil"
// no penaliza ni alerta; solo el exceso real (>= highMin) baja el ring y avisa.
// Contrato v1.5: fruit_fill NO usa copy de cosecha/madurez; harvest_maturity sí.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/agro/peach_tree_agro_score_engine.dart';
import 'package:bio_g/core/agro/peach_tree_nutrition_modifier.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_universal_profile.dart';
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
  double n = 45,
  double p = 35,
  double k = 150,
}) {
  return BioGTelemetry(
    deviceId: 'peach-1',
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
  String profileId = kDzSkip,
}) {
  return PeachTreeAgroScoreEngine.evaluate(
    t: t,
    stageId: stage,
    stageLabelEs: treeStageDisplayName(stage),
    targets: resolvePeachTreeTargets(stage),
    weights: resolvePeachTreeStageWeights(stage),
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
  group('Bandas de suelo del durazno (observación vs crítico real)', () {
    test('madurez + humedad 59% queda operativa y no tumba el ring', () {
      final out = _run(
        _tele(soilMoisturePct: 59),
        stage: TreeStageIds.harvestMaturity,
      );
      final moisture = out.eval.metrics[AgroMetricKey.soilMoisture]!;
      expect(moisture.band, AgroBand.optimal);
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

    test('CE moderada no es crítica; extremo real sí (durazno salino-sensible)', () {
      final ecWatch = _run(_tele(ec: 2.0));
      final ecExtreme = _run(_tele(ec: 2.4));
      expect(ecWatch.eval.metrics[AgroMetricKey.ec]!.band, AgroBand.high);
      expect(ecExtreme.eval.metrics[AgroMetricKey.ec]!.band, AgroBand.critical);
    });
  });

  group('Bandas NPK del durazno (alto útil vs exceso)', () {
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

    test('N=90 en llenado → EXCESO con aviso y ring más bajo', () {
      final baseline = _run(_tele()).eval.soilControlScore01;
      final out = _run(_tele(n: 90));
      final n = out.eval.metrics[AgroMetricKey.n]!;
      expect(n.priorityLabel, NutrientPriorityLabel.reviewAccumulation);
      expect(n.band, AgroBand.high);
      expect(out.eval.suggestedAlertKeys, contains('npk.n.review_accumulation'));
      expect(out.eval.soilControlScore01, lessThan(baseline));
    });

    test('N=70 alto útil → banda alta SIN aviso ni penalización', () {
      final baseline = _run(_tele()).eval.soilControlScore01;
      final out = _run(_tele(n: 70));
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
      final usefulHigh = _run(_tele(k: 170));
      final accumulation = _run(_tele(k: 178));
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
      final out = _run(_tele(n: 90), stage: TreeStageIds.fruitFill);
      final n = out.eval.metrics[AgroMetricKey.n]!;
      final copy = _metricCopy(n);
      expect(n.priorityLabel, NutrientPriorityLabel.reviewAccumulation);
      _expectNoHarvestCopy(copy);
      expect(copy, contains('llenado'));
    });

    test('N alto en madurez usa copy propio de cosecha/madurez', () {
      final out = _run(_tele(n: 75), stage: TreeStageIds.harvestMaturity);
      final n = out.eval.metrics[AgroMetricKey.n]!;
      final copy = _metricCopy(n);
      expect(n.priorityLabel, NutrientPriorityLabel.reviewAccumulation);
      expect(copy, anyOf(contains('cosecha'), contains('madurez')));
    });

    test('llenado y madurez generan recomendaciones distintas para N alto', () {
      final fruitFill = _run(
        _tele(n: 90),
        stage: TreeStageIds.fruitFill,
      ).eval.metrics[AgroMetricKey.n]!;
      final harvest = _run(
        _tele(n: 75),
        stage: TreeStageIds.harvestMaturity,
      ).eval.metrics[AgroMetricKey.n]!;
      expect(
        fruitFill.practicalRecommendationEs,
        isNot(harvest.practicalRecommendationEs),
      );
    });

    test('N alto en vegetativo menciona vigor (durazno NO fuego bacteriano)', () {
      final out = _run(_tele(n: 100), stage: TreeStageIds.vegetativeGrowth);
      final n = out.eval.metrics[AgroMetricKey.n]!;
      final copy = _metricCopy(n);
      expect(copy, anyOf(contains('vigor'), contains('sombra')));
      // El durazno es de hueso: no debe heredar el copy de pepita.
      expect(copy, isNot(contains('fuego bacteriano')));
    });
  });

  group('Modificador por perfil DZ', () {
    test('N en exceso tardío penaliza MÁS en DZ-04 blanco que en general', () {
      final t = _tele(n: 75);
      final blanco = _run(
        t,
        stage: TreeStageIds.harvestMaturity,
        profileId: kDz04BlancoDulce,
      ).eval.soilControlScore01;
      final generic = _run(
        t,
        stage: TreeStageIds.harvestMaturity,
        profileId: kDzSkip,
      ).eval.soilControlScore01;
      expect(blanco, lessThan(generic));
    });

    test('cautions NPK de durazno no filtran codigos internos DZ', () {
      for (final profileId in <String>[
        kDzSkip,
        kDz01CriolloRegional,
        kDz02TempranoBajoFrio,
        kDz03AmarilloComercial,
        kDz04BlancoDulce,
        kDz05TardioIndustria,
      ]) {
        final modifier = resolvePeachTreeNutritionModifier(
          profileId: profileId,
        );
        final copy = <String>[
          modifier.labelEs,
          modifier.summaryEs,
          modifier.practicalCaution(AgroMetricKey.n, TreeStageIds.fruitFill),
          modifier.practicalCaution(
            AgroMetricKey.k,
            TreeStageIds.harvestMaturity,
          ),
          modifier.practicalCaution(AgroMetricKey.p, TreeStageIds.budbreak),
        ].join(' ');

        expect(copy, isNot(contains('DZ-')), reason: profileId);
        expect(copy, isNot(contains('DZ-SKIP')), reason: profileId);
        expect(copy, isNot(contains('dz_')), reason: profileId);
        expect(copy, isNot(contains('dz_skip')), reason: profileId);
      }
    });
  });

  group('Consistencia ring ↔ detalle NPK', () {
    test('la banda del eval coincide con la etiqueta de interpret()', () {
      for (final n in <double>[30, 45, 70, 90]) {
        final t = _tele(n: n);
        final evalMetric = _run(t).eval.metrics[AgroMetricKey.n]!;
        final interp = NutrientRecommendationEngine.interpret(
          nutrient: AgroMetricKey.n,
          rawPpm: n,
          cropKey: 'peach_tree',
          stageKey: TreeStageIds.fruitFill,
          profileId: kDzSkip,
          targets: resolvePeachTreeTargets(TreeStageIds.fruitFill),
          weights: resolvePeachTreeStageWeights(TreeStageIds.fruitFill),
          ph: t.ph,
          ec: t.ec,
          soilMoisturePct: t.soilMoisturePct,
        );
        expect(evalMetric.priorityLabel, interp.label, reason: 'N=$n label');
        expect(evalMetric.band, interp.label.agroBand, reason: 'N=$n band');
      }
    });

    test('guia de fertilizacion de durazno es conservadora, no anual', () {
      final interp = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.p,
        rawPpm: 0,
        cropKey: 'durazno',
        stageKey: TreeStageIds.budbreak,
        profileId: kDz03AmarilloComercial,
        targets: resolvePeachTreeTargets(TreeStageIds.budbreak),
        weights: resolvePeachTreeStageWeights(TreeStageIds.budbreak),
      );
      final copy = <String>[
        interp.doseGuideEs ?? '',
        interp.fertilizerEquivalentEs ?? '',
      ].join(' ').toLowerCase();

      expect(copy, contains('duraznero'));
      expect(copy, contains('analisis'));
      expect(copy, isNot(contains('kg/ha')));
      expect(copy, isNot(contains('g/m')));
      expect(copy, isNot(contains('semilla')));
      expect(copy, isNot(contains('dz_')));
      expect(copy, isNot(contains('dz-')));
    });
  });

  group('No-regresión: el durazno no afecta a granos', () {
    test('frijol con los mismos rangos conserva su etiqueta de exceso', () {
      final targets = resolvePeachTreeTargets(TreeStageIds.fruitFill);
      final beanHigh = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: 65,
        cropKey: 'bean',
        stageKey: 'grainFill',
        targets: targets,
      );
      final peachHigh = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: 65,
        cropKey: 'peach_tree',
        stageKey: TreeStageIds.fruitFill,
        targets: targets,
      );
      // El durazno trata el alto como útil; el frijol lo penaliza.
      expect(peachHigh.labelEs, 'Alto útil');
      expect(beanHigh.labelEs, isNot('Alto útil'));
    });
  });
}
