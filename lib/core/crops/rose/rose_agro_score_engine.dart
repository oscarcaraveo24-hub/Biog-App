import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/rose/rose_catalog.dart';
import 'package:bio_g/core/crops/rose/rose_lifecycle.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Motor AgroScore del Rosal (modo `recurring_bloom`).
///
/// Es un ESPEJO ESTRUCTURAL de `CactusAgroScoreEngine`: mismas bandas, mismas
/// claves de alerta canónicas, mismo motor de nutrición. Un rosal se lee, se
/// clasifica y se alerta igual que cualquier otro cultivo de BIO-G. Lo que
/// cambia es la agronomía (agua dominante, K clave en floración, N en brote) y
/// los "castigos" combinados propios del rosal (Doc B §3).
///
/// Reglas del contrato (Doc B §0, §7): claves de alerta SIEMPRE canónicas
/// (`soilMoisture.critical`, `ph.low`, `npk.k.action`, …), nunca claves con
/// prefijo `rose.*`. El orden maestro de evaluación es
/// Humedad → Temperatura → EC → pH → Resistencia → NPK.
class RoseAgroScoreEngine {
  const RoseAgroScoreEngine._();

  /// Etapas críticas (severityBump = 2): raíz aún sin trabajar y ventanas de
  /// botón/floración, donde el daño cuesta la floración (Doc B §3, severityBump).
  static const Set<String> criticalStages = <String>{
    RoseStageIds.installationEstablishment,
    RoseStageIds.rootEstablishment,
    RoseStageIds.budFormation,
    RoseStageIds.flowering,
  };

  /// Etapas semicríticas. En el rosal todas las etapas no críticas conservan un
  /// severityBump de 1 (Doc B). Este set se mantiene por paridad estructural con
  /// las demás ornamentales.
  static const Set<String> semiCriticalStages = <String>{
    RoseStageIds.rest,
    RoseStageIds.postBloomRecovery,
    RoseStageIds.vegetativeFlush,
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
    final stage = normalizeRoseStageId(stageId);
    final bool isMiniPot = profileId?.trim().toLowerCase() ==
        kRo01MiniatureContainer;

    final moisture01 = _normalizeMoisture01(t.soilMoisturePct, cal);
    final moistureRawCal = moisture01 * 100.0;

    final moistureEval = _evalLegacy(
      value: moistureRawCal,
      range: targets.moistureRaw,
    );
    final soilTempEval = _evalLegacy(value: t.soilTempC, range: targets.soilTemp);
    final phEval = _evalLegacy(value: t.ph, range: targets.ph);
    final ecEval = _evalLegacy(value: t.ec, range: targets.ec);
    final resEval = _evalLegacy(value: t.resistance, range: targets.resistance);

    final nMetric = _interpretRoseNutrient(
      metricKey: AgroMetricKey.n,
      rawMgKg: t.n.toDouble(),
      stage: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      t: t,
    );
    final pMetric = _interpretRoseNutrient(
      metricKey: AgroMetricKey.p,
      rawMgKg: t.p.toDouble(),
      stage: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      t: t,
    );
    final kMetric = _interpretRoseNutrient(
      metricKey: AgroMetricKey.k,
      rawMgKg: t.k.toDouble(),
      stage: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      t: t,
    );

    final metrics = <AgroMetricKey, AgroMetricEval>{
      AgroMetricKey.soilMoisture: _wrapLegacy(
        moistureEval,
        displayValue: moistureRawCal,
      ),
      AgroMetricKey.soilTemp: _wrapLegacy(soilTempEval, displayValue: t.soilTempC),
      AgroMetricKey.ph: _wrapLegacy(phEval, displayValue: t.ph),
      AgroMetricKey.ec: _wrapLegacy(ecEval, displayValue: t.ec),
      AgroMetricKey.resistance: _wrapLegacy(resEval, displayValue: t.resistance),
      AgroMetricKey.n: nMetric,
      AgroMetricKey.p: pMetric,
      AgroMetricKey.k: kMetric,
    };

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

    // ── Castigos base (Doc B §3.1) ────────────────────────────────────────────
    double criticalPenalty = 1.0;
    final bool moistureExcess = moistureRawCal > targets.moistureRaw.optimalMax;
    if (moistureEval.band == AgroBand.critical) {
      // Exceso de agua ×0.48 ; sequía ×0.50.
      criticalPenalty *= moistureExcess ? 0.48 : 0.50;
    }
    if (soilTempEval.band == AgroBand.critical) criticalPenalty *= 0.55;
    if (ecEval.band == AgroBand.critical) criticalPenalty *= 0.55;
    if (phEval.band == AgroBand.critical) criticalPenalty *= 0.65;
    if (resEval.band == AgroBand.critical) criticalPenalty *= 0.68;
    criticalPenalty *= _nutrientPenaltyFactor(nMetric.priorityLabel);
    criticalPenalty *= _nutrientPenaltyFactor(pMetric.priorityLabel);
    criticalPenalty *= _nutrientPenaltyFactor(kMetric.priorityLabel);

    // ── Castigos combinados (Doc B §3.2) ──────────────────────────────────────
    final bool isBudOrFlower =
        stage == RoseStageIds.budFormation || stage == RoseStageIds.flowering;
    final bool dry = moistureRawCal < targets.moistureRaw.optimalMin;
    final bool heat =
        t.soilTempC > targets.soilTemp.optimalMax || t.airTempC >= 32;
    final bool ecHigh =
        ecEval.band == AgroBand.high || ecEval.band == AgroBand.critical;

    // Frío + sustrato húmedo.
    if (_isColdAndWet(
      soilTempC: t.soilTempC,
      moisturePct: moistureRawCal,
      targets: targets,
    )) {
      criticalPenalty *= 0.70;
    }
    // Sequía + botón/floración.
    if (dry && isBudOrFlower) criticalPenalty *= 0.72;
    // Calor + botón/floración.
    if (heat && isBudOrFlower) criticalPenalty *= 0.72;
    // EC alta + suelo seco.
    if (ecHigh && dry) criticalPenalty *= 0.75;
    // EC alta + rosal mini de maceta.
    if (ecHigh && isMiniPot) criticalPenalty *= 0.85;
    // N alto + brotación muy vigorosa.
    if (stage == RoseStageIds.vegetativeFlush &&
        _isExcessSide(nMetric.priorityLabel)) {
      criticalPenalty *= 0.82;
    }

    final soilControlScore01 = (rawSoilControlScore * criticalPenalty).clamp(
      0.0,
      1.0,
    );

    final nutrientWeightSum = math.max(
      0.0001,
      weights.nutrientN + weights.nutrientP + weights.nutrientK,
    );
    final nutrientPriorityScore01 =
        ((weights.nutrientN * _nutrientSeverityScore(nMetric)) +
            (weights.nutrientP * _nutrientSeverityScore(pMetric)) +
            (weights.nutrientK * _nutrientSeverityScore(kMetric))) /
        nutrientWeightSum;

    // Claves CANÓNICAS del AlertsEngine compartido (nunca `rose.*`).
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

    final severityBump = criticalStages.contains(stage) ? 2 : 1;

    final built = AlertsEngine.buildFromSuggestedKeys(
      deviceId: t.deviceId,
      now: t.timestamp,
      severityBump: severityBump,
      suggestedKeys: suggested,
      prev: alertsState,
      cooldown: alertsCooldown,
      cropLabel: cropLabel ?? 'tu rosal',
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

  /// Frío con sustrato húmedo: combinación que favorece pudrición y hongos.
  static bool _isColdAndWet({
    required double soilTempC,
    required double moisturePct,
    required StageTargets targets,
  }) {
    if (!soilTempC.isFinite || !moisturePct.isFinite) return false;
    final cold = soilTempC <= targets.soilTemp.optimalMin;
    final wet = moisturePct >= targets.moistureRaw.optimalMax;
    return cold && wet;
  }

  static bool _isExcessSide(NutrientPriorityLabel? label) {
    if (label == null) return false;
    return label.isExcessSide;
  }

  static AgroMetricEval _interpretRoseNutrient({
    required AgroMetricKey metricKey,
    required double rawMgKg,
    required String stage,
    required String stageLabelEs,
    required StageTargets targets,
    required StageWeights weights,
    required BioGTelemetry t,
  }) {
    final interpretation = NutrientRecommendationEngine.interpret(
      nutrient: metricKey,
      rawPpm: rawMgKg,
      cropKey: 'rose',
      stageKey: stage,
      targets: targets,
      weights: weights,
      ph: t.ph,
      ec: t.ec,
      soilMoisturePct: t.soilMoisturePct,
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

  /// Factores de castigo por nutriente (Doc B §3.1): acumulación/exceso ×0.74,
  /// déficit crítico en etapa activa ×0.82.
  static double _nutrientPenaltyFactor(NutrientPriorityLabel? label) {
    if (label == null) return 1.0;
    switch (label) {
      case NutrientPriorityLabel.reviewAccumulation:
        return 0.74;
      case NutrientPriorityLabel.actionRecommended:
        return 0.82;
      case NutrientPriorityLabel.possibleExcess:
        return 0.85;
      case NutrientPriorityLabel.highPriority:
        return 0.88;
      case NutrientPriorityLabel.reviewManagement:
        return 0.90;
      case NutrientPriorityLabel.mediumPriority:
        return 0.96;
      case NutrientPriorityLabel.lowPriority:
      case NutrientPriorityLabel.noPriority:
      case NutrientPriorityLabel.unknown:
        return 1.0;
    }
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
      out.add('$key.critical');
      return;
    }

    // La humedad ALTA siempre avisa: el exceso de agua favorece pudrición y
    // hongos foliares en el rosal.
    if (key == 'soilMoisture' && e.band == AgroBand.high) {
      out.add('$key.high');
      return;
    }

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

  /// Alertas ambientales del rosal (Doc B §3.3). Umbrales más sensibles al calor
  /// que un cactus: el botón/flor sufre desde 32 °C.
  static void _pushEnvironmentalAlerts(
    List<String> out,
    BioGTelemetry t,
    String stage,
  ) {
    final airTemp = t.airTempC;
    final airHum = t.airHumidityPct;

    if (airTemp <= 0) {
      out.add('airTemp.frost');
    } else if (airTemp <= 5 && stage != RoseStageIds.rest) {
      // El frío no sobre-alarma si la planta está confirmada en reposo.
      out.add('airTemp.cold');
    }

    if (airTemp >= 40) {
      out.add('airTemp.extreme_heat');
    } else if (airTemp >= 32) {
      out.add('airTemp.heat');
    }

    // Humedad ambiental alta sostenida favorece problemas foliares y de flor.
    if (airHum >= 88) {
      out.add('airHumidity.critical');
    } else if (airHum >= 75) {
      out.add('airHumidity.high');
    }
  }

  static double _normalizeMoisture01(double raw0to100, Calibration? cal) {
    final dry = cal?.moistureDryRaw;
    final wet = cal?.moistureWetRaw;

    if (dry != null && wet != null && (wet - dry).abs() > 1e-6) {
      return ((raw0to100 - dry) / (wet - dry)).clamp(0.0, 1.0);
    }
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
