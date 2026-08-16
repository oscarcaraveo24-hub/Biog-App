import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_profiles.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Motor AgroScore del Girasol (modo `annual_ornamental`).
///
/// ESPEJO ESTRUCTURAL de `TulipAgroScoreEngine` / `RoseAgroScoreEngine`: mismas
/// bandas, mismas claves de alerta CANÓNICAS (`soilMoisture.critical`, `ph.low`,
/// `npk.k.action`, …), mismo motor de nutrición compartido. Un girasol se lee,
/// clasifica y alerta igual que cualquier cultivo de BIO-G. Lo propio del
/// Girasol son sus castigos (Documento B §14) y su doctrina: el agua manda; el
/// NPK acompaña; el exceso de N es un riesgo estructural.
///
/// Contrato (Documento B §1.4): claves SIEMPRE canónicas, NUNCA `sunflower.*` ni
/// `girasol.*`. Orden maestro: Humedad → Temperatura → EC → pH → Resistencia →
/// NPK. La tarjeta de Resistencia se conserva; la EC se evalúa internamente y no
/// la reemplaza. En `cycle_complete` el motor hace BYPASS: cero alertas, cero
/// prioridad nutrimental (Documento B §0.2 regla 11, §4, §19.3 test 17).
class SunflowerAgroScoreEngine {
  const SunflowerAgroScoreEngine._();

  /// Etapas críticas (severityBump = 2): germinación, emergencia, botón y flor
  /// (Documento B §14.6).
  static const Set<String> criticalStages = <String>{
    SunflowerStageIds.germination,
    SunflowerStageIds.emergence,
    SunflowerStageIds.budFormation,
    SunflowerStageIds.flowering,
  };

  /// Etapas semicríticas (severityBump = 1): siembra y alargamiento del tallo
  /// (Documento B §14.6).
  static const Set<String> semiCriticalStages = <String>{
    SunflowerStageIds.sowing,
    SunflowerStageIds.stemElongation,
  };

  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluate({
    required BioGTelemetry t,
    required String stageId,
    required String stageLabelEs,
    required StageTargets targets,
    required StageWeights weights,
    AlertsState alertsState = const AlertsState(),
    Calibration? cal,
    Duration alertsCooldown = AlertsEngine.defaultCooldown,
    String? cropLabel,
    String? profileId,
  }) {
    final stage = normalizeSunflowerStageId(stageId);
    final bool isTallOrCut =
        profileId?.trim().toLowerCase() == kGi01TallGarden ||
        profileId?.trim().toLowerCase() == kGi04CutFlowerSingleStem;
    final bool isCompact =
        profileId?.trim().toLowerCase() == kGi02CompactContainer;

    // ── La bandera de presencia manda ──────────────────────────────────────
    //
    // `BioGTelemetry` rellena con 0.0 el sensor que no reportó, y 0.0 cae en
    // CRÍTICO en cuatro de los cinco rangos: sin esta guarda, una sonda
    // averiada o desconectada se leería como suelo en emergencia y el anillo
    // del Panel pintaría un diagnóstico catastrófico de un dato que no existe.
    //
    // NaN y no cero: `_evalLegacy` ya devuelve `AgroBand.unknown` ante un valor
    // no finito, así que la métrica sale como «sin dato» —que es la verdad— sin
    // tocar la firma del evaluador ni la de este motor.
    final moisture01 = t.hasSoilMoistureData
        ? _normalizeMoisture01(t.soilMoisturePct, cal)
        : double.nan;
    final moistureRawCal = moisture01 * 100.0;

    final moistureEval = _evalLegacy(value: moistureRawCal, range: targets.moistureRaw);
    final soilTempEval = _evalLegacy(value: t.soilTempC, range: targets.soilTemp);
    final phEval = _evalLegacy(value: t.ph, range: targets.ph);
    final ecEval = _evalLegacy(value: t.ec, range: targets.ec);
    final resEval = _evalLegacy(value: t.resistance, range: targets.resistance);

    final nMetric = _interpretNutrient(
      metricKey: AgroMetricKey.n,
      hasData: t.hasNitrogenData,
      rawMgKg: t.n.toDouble(),
      stage: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      t: t,
    );
    final pMetric = _interpretNutrient(
      metricKey: AgroMetricKey.p,
      rawMgKg: t.p.toDouble(),
      hasData: t.hasPhosphorusData,
      stage: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      t: t,
    );
    final kMetric = _interpretNutrient(
      metricKey: AgroMetricKey.k,
      rawMgKg: t.k.toDouble(),
      hasData: t.hasPotassiumData,
      stage: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      t: t,
    );

    final metrics = <AgroMetricKey, AgroMetricEval>{
      AgroMetricKey.soilMoisture: _wrapLegacy(moistureEval, displayValue: moistureRawCal),
      AgroMetricKey.soilTemp: _wrapLegacy(soilTempEval, displayValue: t.soilTempC),
      AgroMetricKey.ph: _wrapLegacy(phEval, displayValue: t.ph),
      AgroMetricKey.ec: _wrapLegacy(ecEval, displayValue: t.ec),
      AgroMetricKey.resistance: _wrapLegacy(resEval, displayValue: t.resistance),
      AgroMetricKey.n: nMetric,
      AgroMetricKey.p: pMetric,
      AgroMetricKey.k: kMetric,
    };

    // ── BYPASS TERMINAL: cycle_complete no tiene manejo activo (Documento B §4,
    // §19.3 test 17). Las tarjetas conservan sus bandas para el historial, pero
    // NO se emiten alertas ni prioridad nutrimental. ─────────────────────────
    if (stage == SunflowerStageIds.cycleComplete) {
      final evalDone = AgroEvalResult(
        soilControlScore01: 1.0,
        nutrientPriorityScore01: 0.0,
        primaryScoreKind: AgroScoreKind.nutrientPriority,
        metrics: metrics,
        alerts: const <BioGAlert>[],
        suggestedAlertKeys: const <String>[],
      );
      return (eval: evalDone, nextAlertsState: alertsState);
    }

    final nHealthScore = _nutrientHealthScore(nMetric);
    final pHealthScore = _nutrientHealthScore(pMetric);
    final kHealthScore = _nutrientHealthScore(kMetric);

    final wSum = math.max(0.0001, weights.sum);
    final rawSoilControlScore =
        (weights.moisture * moistureEval.score01 +
            weights.soilTemp * soilTempEval.score01 +
            weights.resistance * resEval.score01 +
            weights.ph * phEval.score01 +
            weights.ec * ecEval.score01 +
            weights.nutrientN * nHealthScore +
            weights.nutrientP * pHealthScore +
            weights.nutrientK * kHealthScore) /
        wSum;

    // ── Castigos del AgroScore (Documento B §14), en el orden maestro ─────────
    double penalty = 1.0;

    final bool moistureExcess = moistureRawCal > targets.moistureRaw.optimalMax;
    final bool moistureDeficit =
        moistureRawCal.isFinite && moistureRawCal < targets.moistureRaw.optimalMin;
    final bool ecHigh =
        ecEval.band == AgroBand.high || ecEval.band == AgroBand.critical;
    final bool resHigh =
        resEval.band == AgroBand.high || resEval.band == AgroBand.critical;
    final bool moistureHigh =
        moistureEval.band == AgroBand.high ||
        (moistureEval.band == AgroBand.critical && moistureExcess);

    // §14.1 / §14.2 — humedad crítica (exceso vs. déficit, por etapa).
    if (moistureEval.band == AgroBand.critical) {
      if (moistureExcess) {
        penalty *= _moistureExcessPenalty(stage);
        if (isCompact) penalty *= 0.90; // §14.2 maceta compacta.
      } else {
        penalty *= _moistureDeficitPenalty(stage);
      }
    }

    // §14.3 — temperatura de suelo crítica.
    if (soilTempEval.band == AgroBand.critical) {
      penalty *= _tempCriticalPenalty(stage);
    }

    // §14.3 / §7.2 — pH, EC y resistencia críticas.
    if (phEval.band == AgroBand.critical) penalty *= 0.65;
    if (ecEval.band == AgroBand.critical) {
      penalty *= _isSeedOrSeedling(stage) ? 0.55 : 0.60;
    }
    if (resEval.band == AgroBand.critical) penalty *= _resistanceCriticalPenalty(stage);

    // §14.3 — NPK. El nitrógeno en exceso castiga más en tallo/botón de alto o
    // corte.
    penalty *= _nutrientPenaltyFactor(
      nMetric.priorityLabel,
      AgroMetricKey.n,
      stage: stage,
      isTallOrCut: isTallOrCut,
    );
    penalty *= _nutrientPenaltyFactor(
      pMetric.priorityLabel,
      AgroMetricKey.p,
      stage: stage,
      isTallOrCut: isTallOrCut,
    );
    penalty *= _nutrientPenaltyFactor(
      kMetric.priorityLabel,
      AgroMetricKey.k,
      stage: stage,
      isTallOrCut: isTallOrCut,
    );

    // §14.4 — combinaciones de riesgo.
    // ── Un canal que no midió viaja como NaN, jamás como cero ──────────────
    //
    // `BioGTelemetry` rellena con 0.0 el sensor ausente y baja su bandera de
    // presencia. Sin esta línea, `0.0 <= 0` cumple la condición de helada: un
    // equipo sin sensor de aire —o con un cable flojo en el bus— gritaría
    // «Riesgo de helada» CRÍTICO en cada lectura, para siempre. Un productor
    // puede encender calefactores o quemar diésel por un canal que nunca
    // existió.
    //
    // NaN, y no un cero: en IEEE-754 toda comparación ordenada con NaN es
    // falsa, así que apaga los cinco umbrales de este bloque —helada, frío,
    // calor, calor extremo y humedad— de una sola vez y sin poder olvidarse
    // ninguno. `isFinite` también da falso, que es lo correcto.
    final airTemp = t.hasAirTempData ? t.airTempC : double.nan;
    final airHum = t.hasAirHumidityData ? t.airHumidityPct : double.nan;
    final bool isBudOrFlower =
        stage == SunflowerStageIds.budFormation ||
        stage == SunflowerStageIds.flowering;
    final bool isGermOrEmergence =
        stage == SunflowerStageIds.germination ||
        stage == SunflowerStageIds.emergence;

    if (isBudOrFlower && airTemp.isFinite && airTemp > 30 && moistureDeficit) {
      penalty *= 0.60; // calor + humedad baja en botón/floración.
    }
    if (isGermOrEmergence && airTemp.isFinite && airTemp < 4 && moistureHigh) {
      penalty *= 0.65; // frío + humedad alta en germinación/emergencia.
    }
    if (ecHigh && moistureDeficit) {
      penalty *= 0.70; // EC alta + humedad baja (§8.5).
    }
    if (resHigh && moistureDeficit) {
      penalty *= 0.75; // resistencia alta + humedad baja (§9.3).
    }
    if (stage == SunflowerStageIds.flowering &&
        moistureEval.band == AgroBand.high &&
        airHum.isFinite &&
        airHum >= 80) {
      penalty *= 0.75; // humedad alta + HR ambiental alta en floración.
    }

    // §14.5 — no multiplicar indefinidamente: piso 0.08.
    penalty = penalty.clamp(0.08, 1.00);

    final soilControlScore01 = (rawSoilControlScore * penalty).clamp(0.0, 1.0);

    final nutrientWeightSum = math.max(
      0.0001,
      weights.nutrientN + weights.nutrientP + weights.nutrientK,
    );
    final nutrientPriorityScore01 =
        ((weights.nutrientN * _nutrientSeverityScore(nMetric)) +
            (weights.nutrientP * _nutrientSeverityScore(pMetric)) +
            (weights.nutrientK * _nutrientSeverityScore(kMetric))) /
        nutrientWeightSum;

    // Claves CANÓNICAS del AlertsEngine compartido (nunca `sunflower.*`).
    final suggested = <String>[];
    _pushSoilAlert(suggested, 'soilMoisture', moistureEval, stage);
    _pushSoilAlert(suggested, 'soilTemp', soilTempEval, stage);
    _pushSoilAlert(suggested, 'ph', phEval, stage);
    _pushSoilAlert(suggested, 'ec', ecEval, stage);
    _pushSoilAlert(suggested, 'resistance', resEval, stage);

    _pushNutrientAlert(suggested, 'npk.n', nMetric, stage);
    _pushNutrientAlert(suggested, 'npk.p', pMetric, stage);
    _pushNutrientAlert(suggested, 'npk.k', kMetric, stage);
    _pushEnvironmentalAlerts(suggested, t, stage);

    // Severidad por etapa (Documento B §14.6): crítica 2, semicrítica 1, resto 0.
    final int severityBump = criticalStages.contains(stage)
        ? 2
        : semiCriticalStages.contains(stage)
        ? 1
        : 0;

    final built = AlertsEngine.buildFromSuggestedKeys(
      deviceId: t.deviceId,
      now: t.timestamp,
      severityBump: severityBump,
      suggestedKeys: suggested,
      prev: alertsState,
      cooldown: alertsCooldown,
      cropLabel: cropLabel ?? 'tu girasol',
      stageLabel: stageLabelEs,
    );

    final eval = AgroEvalResult(
      soilControlScore01: soilControlScore01,
      nutrientPriorityScore01: nutrientPriorityScore01.clamp(0.0, 1.0),
      primaryScoreKind: AgroScoreKind.nutrientPriority,
      metrics: metrics,
      alerts: built.alerts,
      suggestedAlertKeys: suggested,
    );

    return (eval: eval, nextAlertsState: built.state);
  }

  // ── Castigos por etapa (Documento B §14.1, §14.2, §14.3) ──────────────────

  static bool _isSeedOrSeedling(String stage) =>
      stage == SunflowerStageIds.sowing ||
      stage == SunflowerStageIds.germination ||
      stage == SunflowerStageIds.emergence;

  static double _moistureDeficitPenalty(String stage) {
    switch (stage) {
      case SunflowerStageIds.sowing:
      case SunflowerStageIds.germination:
        return 0.40;
      case SunflowerStageIds.emergence:
        return 0.45;
      case SunflowerStageIds.earlyVegetativeGrowth:
      case SunflowerStageIds.activeVegetativeGrowth:
        return 0.55;
      case SunflowerStageIds.stemElongation:
        return 0.50;
      case SunflowerStageIds.budFormation:
        return 0.40;
      case SunflowerStageIds.flowering:
        return 0.38;
      case SunflowerStageIds.postBloom:
        return 0.60;
      case SunflowerStageIds.senescence:
        return 0.75;
      default:
        return 0.55;
    }
  }

  static double _moistureExcessPenalty(String stage) {
    switch (stage) {
      case SunflowerStageIds.sowing:
      case SunflowerStageIds.germination:
        return 0.42;
      case SunflowerStageIds.emergence:
        return 0.45;
      case SunflowerStageIds.earlyVegetativeGrowth:
      case SunflowerStageIds.activeVegetativeGrowth:
        return 0.55;
      case SunflowerStageIds.stemElongation:
      case SunflowerStageIds.budFormation:
      case SunflowerStageIds.flowering:
        return 0.55;
      case SunflowerStageIds.postBloom:
        return 0.60;
      case SunflowerStageIds.senescence:
        return 0.75;
      default:
        return 0.55;
    }
  }

  static double _tempCriticalPenalty(String stage) {
    switch (stage) {
      case SunflowerStageIds.germination:
      case SunflowerStageIds.emergence:
        return 0.50;
      case SunflowerStageIds.earlyVegetativeGrowth:
      case SunflowerStageIds.activeVegetativeGrowth:
      case SunflowerStageIds.stemElongation:
        return 0.55;
      case SunflowerStageIds.budFormation:
      case SunflowerStageIds.flowering:
        return 0.50;
      case SunflowerStageIds.sowing:
        return 0.55;
      case SunflowerStageIds.postBloom:
        return 0.70;
      case SunflowerStageIds.senescence:
        return 0.80;
      default:
        return 0.55;
    }
  }

  static double _resistanceCriticalPenalty(String stage) {
    switch (stage) {
      case SunflowerStageIds.sowing:
      case SunflowerStageIds.germination:
      case SunflowerStageIds.emergence:
        return 0.55;
      case SunflowerStageIds.earlyVegetativeGrowth:
      case SunflowerStageIds.activeVegetativeGrowth:
      case SunflowerStageIds.stemElongation:
        return 0.65;
      case SunflowerStageIds.budFormation:
      case SunflowerStageIds.flowering:
        return 0.70;
      case SunflowerStageIds.postBloom:
      case SunflowerStageIds.senescence:
        return 0.80;
      default:
        return 0.65;
    }
  }

  /// Factores NPK (Documento B §14.3). El N en exceso castiga más (×0.72) en
  /// tallo/botón de los perfiles alto o corte; en el resto ×0.82. P/K en
  /// acumulación ×0.82. Revisión de manejo ×0.88. Una deficiencia (prioridad de
  /// acción) NO castiga el score: se expresa como prioridad nutrimental, no como
  /// crisis (Documento B §16.5).
  static double _nutrientPenaltyFactor(
    NutrientPriorityLabel? label,
    AgroMetricKey key, {
    required String stage,
    required bool isTallOrCut,
  }) {
    if (label == null) return 1.0;
    switch (label) {
      case NutrientPriorityLabel.possibleExcess:
      case NutrientPriorityLabel.reviewAccumulation:
        if (key == AgroMetricKey.n) {
          final bool stemOrBud =
              stage == SunflowerStageIds.stemElongation ||
              stage == SunflowerStageIds.budFormation;
          return (isTallOrCut && stemOrBud) ? 0.72 : 0.82;
        }
        return 0.82;
      case NutrientPriorityLabel.reviewManagement:
        return 0.88;
      case NutrientPriorityLabel.actionRecommended:
      case NutrientPriorityLabel.highPriority:
      case NutrientPriorityLabel.mediumPriority:
      case NutrientPriorityLabel.lowPriority:
      case NutrientPriorityLabel.noPriority:
      case NutrientPriorityLabel.unknown:
        return 1.0;
    }
  }

  static AgroMetricEval _interpretNutrient({
    required AgroMetricKey metricKey,
    required double rawMgKg,
    required bool hasData,
    required String stage,
    required String stageLabelEs,
    required StageTargets targets,
    required StageWeights weights,
    required BioGTelemetry t,
  }) {
    // Sin sonda de nutrientes no hay dato, y ausencia NO es cero.
    //
    // Un 0 ppm entra en `interpret` y sale como `actionRecommended`, la peor
    // etiqueta de deficiencia que existe: un equipo sin sonda NPK le decía al
    // productor «aplica fertilizante ya», en cada lectura, para siempre. El
    // motor de frutales ya se guardaba de esto desde el principio; el resto no.
    if (!hasData || rawMgKg <= 0) {
      return AgroMetricEval(
        band: AgroBand.unknown,
        score01: 0.5,
        labelEs: AgroBand.unknown.labelEs,
        value: rawMgKg,
        stageKey: stage,
        stageLabelEs: stageLabelEs,
        demandWindowLabelEs: targets.windowLabelFor(metricKey),
      );
    }

    final interpretation = NutrientRecommendationEngine.interpret(
      nutrient: metricKey,
      rawPpm: rawMgKg,
      cropKey: 'sunflower',
        stageKey: stage,
      targets: targets,
      weights: weights,
      ph: t.ph,
      ec: t.ec,
      soilMoisturePct: t.hasSoilMoistureData ? t.soilMoisturePct : null,
    );

    return AgroMetricEval(
      band: interpretation.label.agroBand,
      score01: interpretation.label
          .severityScore01(stagePressure01: interpretation.stagePressure01)
          .clamp(0.0, 1.0),
      labelEs: interpretation.labelEs,
      value: rawMgKg,
      priorityLabel: interpretation.label,
        stageKey: stage,
        stageLabelEs: stageLabelEs,
      demandWindowLabelEs: interpretation.demandWindowLabel,
      shortRecommendationEs: interpretation.shortRecommendation,
      practicalRecommendationEs: interpretation.practicalRecommendation,
      doseGuideEs: interpretation.doseGuideEs,
      fertilizerEquivalentEs: interpretation.fertilizerEquivalentEs,
      justificationEs: interpretation.justification,
      stagePressure01: interpretation.stagePressure01,
      contextModifier01: interpretation.contextModifier01,
      trendModifier01: interpretation.trendModifier01,
    );
  }

  static AgroMetricEval _wrapLegacy(_Eval e, {required double displayValue}) {
    return AgroMetricEval(
      band: e.band,
      score01: e.score01,
      labelEs: e.band.labelEs,
      value: displayValue,
    );
  }

  static double _nutrientSeverityScore(AgroMetricEval metric) {
    final label = metric.priorityLabel;
    if (label == null) return 0.0;
    return label.severityScore01(stagePressure01: metric.stagePressure01 ?? 0.0);
  }

  static double _nutrientHealthScore(AgroMetricEval metric) {
    final label = metric.priorityLabel;
    if (label == null) return metric.score01.clamp(0.0, 1.0);
    return label.healthScore01(stagePressure01: metric.stagePressure01 ?? 0.0);
  }

  static _Eval _evalLegacy({required double value, required AgroRange range}) {
    if (!value.isFinite || value.isNaN) {
      return _Eval(value: value, band: AgroBand.unknown, score01: 0.0);
    }

    final lowMax = math.min(range.lowMax, range.optimalMin);
    final optMin = math.max(range.lowMax, range.optimalMin);
    final optMax = math.max(range.optimalMax, optMin);
    final highMin = math.max(range.highMin, optMax);

    AgroBand band;
    if (value < lowMax) {
      band = AgroBand.critical;
    } else if (value < optMin) {
      band = AgroBand.low;
    } else if (value <= optMax) {
      band = AgroBand.optimal;
    } else if (value <= highMin) {
      band = AgroBand.high;
    } else {
      band = AgroBand.critical;
    }

    final score01 = _scoreFromRange(value, lowMax, optMin, optMax, highMin);
    return _Eval(value: value, band: band, score01: score01);
  }

  static double _scoreFromRange(
    double v,
    double lowMax,
    double optMin,
    double optMax,
    double highMin,
  ) {
    if (v >= optMin && v <= optMax) return 1.0;

    if (v >= lowMax && v < optMin) {
      final t = _invLerp(lowMax, optMin, v);
      return _lerp(0.55, 0.95, t);
    }

    if (v > optMax && v <= highMin) {
      final t = _invLerp(optMax, highMin, v);
      return _lerp(0.95, 0.55, t);
    }

    if (v < lowMax) {
      final span = math.max(1e-6, (optMin - lowMax).abs());
      final d = (lowMax - v) / span;
      return (0.35 / (1 + d)).clamp(0.05, 0.35);
    }

    final span = math.max(1e-6, (highMin - optMax).abs());
    final d = (v - highMin) / span;
    return (0.35 / (1 + d)).clamp(0.05, 0.35);
  }

  static void _pushSoilAlert(
    List<String> out,
    String key,
    _Eval e,
    String stage,
  ) {
    final isSensitiveStage =
        criticalStages.contains(stage) || semiCriticalStages.contains(stage);

    if (e.band == AgroBand.critical) {
      // La EC baja NUNCA es crítica (banda baja informativa); una EC crítica
      // solo viene por acumulación de sales (lado alto).
      out.add('$key.critical');
      return;
    }

    // La humedad ALTA siempre avisa: el exceso de agua es un riesgo principal
    // (Documento B §5.3).
    if (key == 'soilMoisture' && e.band == AgroBand.high) {
      out.add('$key.high');
      return;
    }

    // EC baja NO se sugiere como alerta (Documento B §8.6, §16.4): un sustrato
    // limpio puede tener EC baja sin ser deficiencia.
    if (key == 'ec' && e.band == AgroBand.low) return;

    if (isSensitiveStage && e.band == AgroBand.low) out.add('$key.low');
    if (isSensitiveStage && e.band == AgroBand.high) out.add('$key.high');
  }

  static void _pushNutrientAlert(
    List<String> out,
    String key,
    AgroMetricEval metric,
    String stage,
  ) {
    final label = metric.priorityLabel;
    if (label == null) return;

    switch (label) {
      case NutrientPriorityLabel.actionRecommended:
        out.add('$key.action');
        return;
      case NutrientPriorityLabel.reviewManagement:
        out.add('$key.review');
        return;
      case NutrientPriorityLabel.highPriority:
        out.add('$key.high_priority');
        return;
      case NutrientPriorityLabel.possibleExcess:
        out.add('$key.possible_excess');
        return;
      case NutrientPriorityLabel.reviewAccumulation:
        out.add('$key.review_accumulation');
        return;
      case NutrientPriorityLabel.mediumPriority:
        if (criticalStages.contains(stage) ||
            semiCriticalStages.contains(stage)) {
          out.add('$key.medium_priority');
        }
        return;
      case NutrientPriorityLabel.lowPriority:
      case NutrientPriorityLabel.noPriority:
      case NutrientPriorityLabel.unknown:
        return;
    }
  }

  /// Alertas ambientales (Documento B §6.5). El frío y el calor elevan la
  /// vigilancia; la humedad ambiental alta favorece problemas de flor durante la
  /// floración. No sobre-alarma cuando la planta ya está en senescencia.
  static void _pushEnvironmentalAlerts(
    List<String> out,
    BioGTelemetry t,
    String stage,
  ) {
    // NaN y no cero cuando el canal no midió: toda comparación ordenada con
    // NaN es falsa, así que la combinación de riesgo se apaga entera en vez de
    // dispararse con un 0.0 sintetizado. Ver la nota larga en el bloque de
    // alertas ambientales de este mismo archivo.
    final airTemp = t.hasAirTempData ? t.airTempC : double.nan;
    final airHum = t.hasAirHumidityData ? t.airHumidityPct : double.nan;

    final bool closing = stage == SunflowerStageIds.senescence;
    final bool budOrFlower =
        stage == SunflowerStageIds.budFormation ||
        stage == SunflowerStageIds.flowering;

    if (airTemp.isFinite) {
      if (airTemp <= 0) {
        out.add('airTemp.frost');
      } else if (airTemp < 4 && !closing) {
        out.add('airTemp.cold');
      }

      if (airTemp > 38) {
        out.add('airTemp.extreme_heat');
      } else if (airTemp > 32) {
        out.add('airTemp.heat');
      } else if (budOrFlower && airTemp > 30) {
        out.add('airTemp.heat');
      }
    }

    // Humedad ambiental alta solo pesa mientras hay follaje/flor activos.
    if (!closing && airHum.isFinite) {
      if (airHum >= 90) {
        out.add('airHumidity.critical');
      } else if (airHum >= 80) {
        out.add('airHumidity.high');
      }
    }
  }

  /// Contenido volumétrico del sensor, a fracción 0..1.
  ///
  /// La rama de calibración relativa seco/mojado se BORRÓ. El módulo de agua
  /// declara que la humedad es contenido volumétrico real y que no necesita
  /// calibración de usuario; el propio contrato de datos crudos lo dice por
  /// escrito. Aquella rama existía para otra clase de sonda —la capacitiva
  /// analógica barata— y no aplica al sensor que entrega VWC ya calibrado de
  /// fábrica.
  ///
  /// Verificado antes de borrarla: el tipo tenía dos consumidores y **cero
  /// productores**. Nadie la instanciaba, y no había pantalla para hacerlo. Se
  /// borra en vez de dejarla dormida porque un condicional que nadie puede
  /// activar hoy pero que alguien activará en seis meses es peor que ninguno:
  /// para entonces nadie recordará por qué estaba ahí, y el efecto sería que el
  /// motor de riego leyera 25 % como 25 % mientras el de puntuación leyera el
  /// mismo 25 % como 58 % relativo —dos lecturas del mismo dato, en la misma
  /// pantalla—.
  static double _normalizeMoisture01(double raw0to100, Calibration? cal) {
    return (raw0to100 / 100.0).clamp(0.0, 1.0);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _invLerp(double a, double b, double v) {
    final denom = (b - a);
    if (denom.abs() < 1e-9) return 0.0;
    return ((v - a) / denom).clamp(0.0, 1.0);
  }
}

class _Eval {
  const _Eval({required this.value, required this.band, required this.score01});

  final double value;
  final AgroBand band;
  final double score01;
}
