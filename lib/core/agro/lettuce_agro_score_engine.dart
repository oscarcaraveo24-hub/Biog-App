import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/crops/lettuce/lettuce_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/lettuce_models.dart';

/// AgroScore específico para lechuga (`CropKey.lettuce`).
///
/// Sigue el patrón de calabaza/berenjena, con diferencias propias de una
/// hortaliza de hoja:
///  - Formación de cabeza (E4) y ventana de cosecha (E5) son la ventana
///    CRÍTICA: ahí se decide turgencia, calidad y oportunidad de corte.
///  - El espigado (bolting) NO es etapa: se evalúa como evento de falla
///    [LettuceBoltingRisk] y puede sobreescribir el mensaje de cosecha.
///  - Salinidad es sensibilidad ALTA (cultivo sensible).
///  - No hay floración, amarre ni llenado de fruto que evaluar.
class LettuceAgroScoreEngine {
  static const Set<LettuceStageKey> _criticalStages = {
    LettuceStageKey.formacionCabeza,
    LettuceStageKey.ventanaCosecha,
  };

  static const Set<LettuceStageKey> _semiCriticalStages = {
    LettuceStageKey.desarrolloVegetativo,
    LettuceStageKey.sobremadurez,
  };

  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluate({
    required BioGTelemetry t,
    required LettuceStageResult stage,
    required LettuceUniversalProfile u,
    AlertsState alertsState = const AlertsState(),
    Calibration? cal,
    Duration alertsCooldown = AlertsEngine.defaultCooldown,
    String? cropLabel,
    StageTargets? targetsOverride,
    StageWeights? weightsOverride,
  }) {
    final stageKey = stage.stage;
    final targets = targetsOverride ?? u.byStage[stageKey];
    final weights = weightsOverride ?? u.weights[stageKey];

    if (targets == null || weights == null) {
      final empty = AgroEvalResult(
        soilControlScore01: 0.0,
        nutrientPriorityScore01: 0.0,
        primaryScoreKind: AgroScoreKind.nutrientPriority,
        metrics: const {},
        alerts: const [],
        suggestedAlertKeys: const ['stage.unknown'],
      );
      return (eval: empty, nextAlertsState: alertsState);
    }

    final moisture01 = _normalizeMoisture01(t.soilMoisturePct, cal);
    final moistureRawCal = moisture01 * 100.0;

    final moistureEval =
        _evalLegacy(value: moistureRawCal, range: targets.moistureRaw);
    final soilTempEval =
        _evalLegacy(value: t.soilTempC, range: targets.soilTemp);
    final phEval = _evalLegacy(value: t.ph, range: targets.ph);
    final ecEval = _evalLegacy(value: t.ec, range: targets.ec);
    final resEval = _evalLegacy(value: t.resistance, range: targets.resistance);

    final nMetric = _interpretLettuceNutrient(
      metricKey: AgroMetricKey.n,
      rawMgKg: t.n.toDouble(),
      stageKey: stageKey,
      targets: targets,
      weights: weights,
      ph: t.ph,
      ec: t.ec,
      soilMoisturePct: t.soilMoisturePct,
      profileId: stage.profile.id,
    );
    final pMetric = _interpretLettuceNutrient(
      metricKey: AgroMetricKey.p,
      rawMgKg: t.p.toDouble(),
      stageKey: stageKey,
      targets: targets,
      weights: weights,
      ph: t.ph,
      ec: t.ec,
      soilMoisturePct: t.soilMoisturePct,
      profileId: stage.profile.id,
    );
    final kMetric = _interpretLettuceNutrient(
      metricKey: AgroMetricKey.k,
      rawMgKg: t.k.toDouble(),
      stageKey: stageKey,
      targets: targets,
      weights: weights,
      ph: t.ph,
      ec: t.ec,
      soilMoisturePct: t.soilMoisturePct,
      profileId: stage.profile.id,
    );

    final metrics = <AgroMetricKey, AgroMetricEval>{
      AgroMetricKey.soilMoisture:
          _wrapLegacy(moistureEval, displayValue: moistureRawCal),
      AgroMetricKey.soilTemp:
          _wrapLegacy(soilTempEval, displayValue: t.soilTempC),
      AgroMetricKey.ph: _wrapLegacy(phEval, displayValue: t.ph),
      AgroMetricKey.ec: _wrapLegacy(ecEval, displayValue: t.ec),
      AgroMetricKey.resistance:
          _wrapLegacy(resEval, displayValue: t.resistance),
      AgroMetricKey.n: nMetric,
      AgroMetricKey.p: pMetric,
      AgroMetricKey.k: kMetric,
    };

    final wSum = math.max(0.0001, weights.sum);
    final rawSoilControlScore = (weights.moisture * moistureEval.score01 +
            weights.soilTemp * soilTempEval.score01 +
            weights.resistance * resEval.score01 +
            weights.ph * phEval.score01 +
            weights.ec * ecEval.score01 +
            weights.nutrientN * _nutrientHealthScore(nMetric) +
            weights.nutrientP * _nutrientHealthScore(pMetric) +
            weights.nutrientK * _nutrientHealthScore(kMetric)) /
        wSum;

    // Penalizaciones críticas: en formación de cabeza y cosecha el agua,
    // la temperatura y la salinidad pesan más (ventana de calidad §9).
    double criticalPenalty = 1.0;
    if (moistureEval.band == AgroBand.critical) criticalPenalty *= 0.40;
    if (soilTempEval.band == AgroBand.critical) criticalPenalty *= 0.50;
    if (phEval.band == AgroBand.critical) criticalPenalty *= 0.58;
    if (ecEval.band == AgroBand.critical) criticalPenalty *= 0.52;
    if (resEval.band == AgroBand.critical) criticalPenalty *= 0.80;
    criticalPenalty *= _nutrientPenaltyFactor(nMetric.priorityLabel);
    criticalPenalty *= _nutrientPenaltyFactor(pMetric.priorityLabel);
    criticalPenalty *= _nutrientPenaltyFactor(kMetric.priorityLabel);

    // El espigado degrada el valor comercial: penaliza el score directo.
    final boltingRisk = computeBoltingRisk(
      airTempC: t.airTempC,
      moistureRawCal: moistureRawCal,
      stage: stageKey,
    );
    switch (boltingRisk) {
      case LettuceBoltingRisk.critico:
        criticalPenalty *= 0.55;
        break;
      case LettuceBoltingRisk.alto:
        criticalPenalty *= 0.74;
        break;
      case LettuceBoltingRisk.medio:
        criticalPenalty *= 0.90;
        break;
      case LettuceBoltingRisk.bajo:
        break;
    }

    final soilControlScore01 =
        (rawSoilControlScore * criticalPenalty).clamp(0.0, 1.0);

    final nutrientWeightSum = math.max(
      0.0001,
      weights.nutrientN + weights.nutrientP + weights.nutrientK,
    );
    final nutrientPriorityScore01 =
        (weights.nutrientN * _nutrientSeverityScore(nMetric) +
                weights.nutrientP * _nutrientSeverityScore(pMetric) +
                weights.nutrientK * _nutrientSeverityScore(kMetric)) /
            nutrientWeightSum;

    final suggested = <String>[];
    _pushLegacyAlertsForMetric(suggested, 'soilMoisture', moistureEval, stageKey);
    _pushLegacyAlertsForMetric(suggested, 'soilTemp', soilTempEval, stageKey);
    _pushLegacyAlertsForMetric(suggested, 'ph', phEval, stageKey);
    _pushLegacyAlertsForMetric(suggested, 'ec', ecEval, stageKey);
    _pushLegacyAlertsForMetric(suggested, 'resistance', resEval, stageKey);
    _pushNutrientAlertsForMetric(suggested, 'npk.n', nMetric, stageKey);
    _pushNutrientAlertsForMetric(suggested, 'npk.p', pMetric, stageKey);
    _pushNutrientAlertsForMetric(suggested, 'npk.k', kMetric, stageKey);
    _pushEnvironmentalAlerts(suggested, t, stage, boltingRisk);

    final severityBump = _criticalStages.contains(stageKey)
        ? 2
        : _semiCriticalStages.contains(stageKey)
            ? 1
            : 0;

    final built = AlertsEngine.buildFromSuggestedKeys(
      deviceId: t.deviceId,
      now: t.timestamp,
      severityBump: severityBump,
      suggestedKeys: suggested,
      prev: alertsState,
      cooldown: alertsCooldown,
      cropLabel: cropLabel,
      stageLabel: stage.stageLabelEs,
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

  /// Evalúa el riesgo de espigado / bolting (evento E7 del Perfil
  /// Universal). Disparadores: calor sostenido, déficit hídrico y edad
  /// fisiológica avanzada. No es una etapa: es una falla de calidad.
  static LettuceBoltingRisk computeBoltingRisk({
    required double airTempC,
    required double moistureRawCal,
    required LettuceStageKey stage,
  }) {
    final isQualityStage = stage == LettuceStageKey.formacionCabeza ||
        stage == LettuceStageKey.ventanaCosecha;
    final isExposedStage = isQualityStage ||
        stage == LettuceStageKey.desarrolloVegetativo ||
        stage == LettuceStageKey.sobremadurez;
    if (!isExposedStage) return LettuceBoltingRisk.bajo;
    if (!airTempC.isFinite) return LettuceBoltingRisk.bajo;

    final waterStress = moistureRawCal > 0 && moistureRawCal < 50;

    if (airTempC >= 30 && isQualityStage) return LettuceBoltingRisk.critico;
    if (airTempC >= 30) return LettuceBoltingRisk.alto;
    if (airTempC > 28 && (isQualityStage || waterStress)) {
      return LettuceBoltingRisk.alto;
    }
    if (airTempC > 28) return LettuceBoltingRisk.medio;
    if (airTempC > 25 && isQualityStage && waterStress) {
      return LettuceBoltingRisk.medio;
    }
    return LettuceBoltingRisk.bajo;
  }

  static AgroMetricEval _interpretLettuceNutrient({
    required AgroMetricKey metricKey,
    required double rawMgKg,
    required LettuceStageKey stageKey,
    required StageTargets targets,
    required StageWeights weights,
    required String profileId,
    double? ph,
    double? ec,
    double? soilMoisturePct,
  }) {
    final interpretation = NutrientRecommendationEngine.interpret(
      nutrient: metricKey,
      rawPpm: rawMgKg,
      cropKey: 'lettuce',
      stageKey: stageKey.name,
      profileId: profileId,
      targets: targets,
      weights: weights,
      ph: ph,
      ec: ec,
      soilMoisturePct: soilMoisturePct,
    );

    return AgroMetricEval(
      band: interpretation.label.agroBand,
      score01: interpretation.label
          .severityScore01(stagePressure01: interpretation.stagePressure01)
          .clamp(0.0, 1.0),
      labelEs: interpretation.labelEs,
      value: rawMgKg,
      priorityLabel: interpretation.label,
      stageKey: stageKey.name,
      stageLabelEs: _stageLabelEs(stageKey),
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
    return label.severityScore01(stagePressure01: metric.stagePressure01 ?? 0);
  }

  static double _nutrientHealthScore(AgroMetricEval metric) {
    final label = metric.priorityLabel;
    if (label == null) return metric.score01.clamp(0.0, 1.0);
    return label.healthScore01(stagePressure01: metric.stagePressure01 ?? 0);
  }

  static double _nutrientPenaltyFactor(NutrientPriorityLabel? label) {
    if (label == null) return 1.0;
    switch (label) {
      case NutrientPriorityLabel.actionRecommended:
        return 0.78;
      case NutrientPriorityLabel.reviewAccumulation:
        return 0.82;
      case NutrientPriorityLabel.reviewManagement:
        return 0.86;
      case NutrientPriorityLabel.highPriority:
      case NutrientPriorityLabel.possibleExcess:
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

    final score01 =
        _scoreFromLegacyRange(value, lowMax, optMin, optMax, highMin);
    return _Eval(value: value, band: band, score01: score01);
  }

  static double _scoreFromLegacyRange(
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

  static void _pushLegacyAlertsForMetric(
    List<String> out,
    String key,
    _Eval e,
    LettuceStageKey stage,
  ) {
    final isSensitiveStage =
        _criticalStages.contains(stage) || _semiCriticalStages.contains(stage);

    if (e.band == AgroBand.critical) {
      out.add('$key.critical');
      return;
    }

    if (isSensitiveStage && e.band == AgroBand.low) out.add('$key.low');
    if (isSensitiveStage && e.band == AgroBand.high) out.add('$key.high');
  }

  static void _pushNutrientAlertsForMetric(
    List<String> out,
    String key,
    AgroMetricEval metric,
    LettuceStageKey stage,
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
        if (_criticalStages.contains(stage) ||
            _semiCriticalStages.contains(stage)) {
          out.add('$key.medium_priority');
        }
        return;
      case NutrientPriorityLabel.lowPriority:
      case NutrientPriorityLabel.noPriority:
      case NutrientPriorityLabel.unknown:
        return;
    }
  }

  /// Alertas ambientales y de oportunidad específicas de lechuga.
  ///
  /// Prioriza: calor sostenido (acelera espigado y amargor), espigado
  /// inminente/confirmado, HR alta (mildiu/Botrytis/tip burn) y la
  /// ventana de cosecha (revisión 3-7 días antes, corte oportuno).
  static void _pushEnvironmentalAlerts(
    List<String> out,
    BioGTelemetry t,
    LettuceStageResult stage,
    LettuceBoltingRisk boltingRisk,
  ) {
    final airTemp = t.airTempC;
    final airHum = t.airHumidityPct;
    final isQualityStage = _criticalStages.contains(stage.stage);

    // Frío / helada: la lechuga es de estación fresca, pero la helada
    // aún daña hoja y favorece eventos de estrés.
    if (airTemp <= 0) {
      out.add('airTemp.frost');
    } else if (airTemp < 4) {
      out.add('airTemp.cold');
    }

    // Calor: >28 °C sostenido es alerta; >30 °C es crítico para lechuga.
    if (airTemp > 30) {
      out.add('airTemp.extreme_heat');
    } else if (airTemp > 28 || (isQualityStage && airTemp > 27)) {
      out.add('airTemp.heat');
    }

    // HR alta favorece mildiu velloso, Botrytis y tip burn.
    if (airHum > 90) {
      out.add('airHumidity.critical');
    } else if (airHum > 85) {
      out.add('airHumidity.high');
    }

    // Espigado / bolting (evento E7). Sobreescribe el tono de cosecha.
    switch (boltingRisk) {
      case LettuceBoltingRisk.critico:
        out.add('lettuce.bolting_critical');
        break;
      case LettuceBoltingRisk.alto:
        out.add('lettuce.bolting_warning');
        break;
      case LettuceBoltingRisk.medio:
      case LettuceBoltingRisk.bajo:
        break;
    }

    // Ventana de cosecha y revisión de campo.
    if (stage.stage == LettuceStageKey.ventanaCosecha) {
      final urgentByHeatOrBolting = airTemp > 28 ||
          boltingRisk == LettuceBoltingRisk.alto ||
          boltingRisk == LettuceBoltingRisk.critico;
      out.add(urgentByHeatOrBolting
          ? 'lettuce.harvest_urgent'
          : 'lettuce.harvest_window');
    } else if (stage.stage == LettuceStageKey.sobremadurez) {
      out.add('lettuce.harvest_past');
    } else if (stage.daysToHarvestMin > 0 && stage.daysToHarvestMin <= 7) {
      out.add('lettuce.harvest_review');
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

  static String _stageLabelEs(LettuceStageKey stageKey) {
    switch (stageKey) {
      case LettuceStageKey.germinacion:
        return 'Germinacion';
      case LettuceStageKey.establecimiento:
        return 'Emergencia / establecimiento';
      case LettuceStageKey.desarrolloVegetativo:
        return 'Desarrollo vegetativo';
      case LettuceStageKey.formacionCabeza:
        return 'Formacion de cabeza / madurez comercial';
      case LettuceStageKey.ventanaCosecha:
        return 'Ventana de cosecha';
      case LettuceStageKey.sobremadurez:
        return 'Sobre-madurez / senescencia';
    }
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
