import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/crops/onion/onion_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/onion_models.dart';

/// AgroScore especifico para cebolla (`CropKey.onion`).
///
/// Agua, temperatura, salinidad, fotoperiodo y calidad de bulbo pesan mas
/// que volumen de hoja. El espigado se trata como evento de perdida
/// comercial, no como floracion. La etapa critica es induccion ->
/// llenado de bulbo -> maduracion/cuello.
class OnionAgroScoreEngine {
  static const Set<OnionStageKey> _criticalStages = {
    OnionStageKey.induccionBulbificacion,
    OnionStageKey.inicioBulbo,
    OnionStageKey.llenadoBulbo,
    OnionStageKey.maduracionCosecha,
    OnionStageKey.espigado,
  };

  static const Set<OnionStageKey> _semiCriticalStages = {
    OnionStageKey.vegetativo,
  };

  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluate({
    required BioGTelemetry t,
    required OnionStageResult stage,
    required OnionUniversalProfile u,
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

    final nMetric = _interpretOnionNutrient(
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
    final pMetric = _interpretOnionNutrient(
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
    final kMetric = _interpretOnionNutrient(
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

    double criticalPenalty = 1.0;
    if (moistureEval.band == AgroBand.critical) criticalPenalty *= 0.42;
    if (soilTempEval.band == AgroBand.critical) criticalPenalty *= 0.48;
    if (phEval.band == AgroBand.critical) criticalPenalty *= 0.58;
    if (ecEval.band == AgroBand.critical) criticalPenalty *= 0.48;
    if (resEval.band == AgroBand.critical) criticalPenalty *= 0.78;
    criticalPenalty *= _nutrientPenaltyFactor(nMetric.priorityLabel);
    criticalPenalty *= _nutrientPenaltyFactor(pMetric.priorityLabel);
    criticalPenalty *= _nutrientPenaltyFactor(kMetric.priorityLabel);

    final boltingRisk = computeBoltingRisk(
      airTempC: t.airTempC,
      stage: stageKey,
      profileSensitivity01: stage.profile.boltingSensitivity01,
    );
    switch (boltingRisk) {
      case OnionBoltingRisk.critico:
        criticalPenalty *= 0.52;
        break;
      case OnionBoltingRisk.alto:
        criticalPenalty *= 0.72;
        break;
      case OnionBoltingRisk.medio:
        criticalPenalty *= 0.88;
        break;
      case OnionBoltingRisk.bajo:
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

  /// Riesgo de espigado/seedstalk. En cebolla el espigado se asocia a
  /// planta grande expuesta a frio/vernalizacion y a estres; el calor
  /// fuerte tambien acelera madurez y puede predisponer en materiales
  /// sensibles. No es floracion productiva.
  static OnionBoltingRisk computeBoltingRisk({
    required double airTempC,
    required OnionStageKey stage,
    required double profileSensitivity01,
  }) {
    if (stage == OnionStageKey.espigado) return OnionBoltingRisk.critico;
    if (!airTempC.isFinite) return OnionBoltingRisk.bajo;

    // El espigado pesa sobre todo desde planta establecida hasta bulbo.
    final isExposedStage = stage == OnionStageKey.vegetativo ||
        stage == OnionStageKey.induccionBulbificacion ||
        stage == OnionStageKey.inicioBulbo ||
        stage == OnionStageKey.llenadoBulbo;
    if (!isExposedStage) return OnionBoltingRisk.bajo;

    final sensitive = profileSensitivity01 >= 0.62;
    final coldEvent = airTempC <= 8.0;
    final coolEvent = airTempC <= 12.0;

    if (coldEvent && sensitive) return OnionBoltingRisk.alto;
    if (coldEvent) return OnionBoltingRisk.medio;
    if (coolEvent && sensitive) return OnionBoltingRisk.medio;
    return OnionBoltingRisk.bajo;
  }

  static AgroMetricEval _interpretOnionNutrient({
    required AgroMetricKey metricKey,
    required double rawMgKg,
    required OnionStageKey stageKey,
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
      cropKey: 'onion',
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
        return 0.80;
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
    OnionStageKey stage,
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
    OnionStageKey stage,
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

  static void _pushEnvironmentalAlerts(
    List<String> out,
    BioGTelemetry t,
    OnionStageResult stage,
    OnionBoltingRisk boltingRisk,
  ) {
    final airTemp = t.airTempC;
    final airHum = t.airHumidityPct;
    final stageKey = stage.stage;
    final isBulbStage = stageKey == OnionStageKey.induccionBulbificacion ||
        stageKey == OnionStageKey.inicioBulbo ||
        stageKey == OnionStageKey.llenadoBulbo;
    final isMaturity = stageKey == OnionStageKey.maduracionCosecha;

    if (airTemp <= 0) {
      out.add('airTemp.frost');
    } else if (airTemp < 4) {
      out.add('airTemp.cold');
    }
    // Doc: >30 C en induccion/llenado acelera madurez y reduce calibre.
    if (airTemp >= 32 || (isBulbStage && airTemp > 30)) {
      out.add('airTemp.extreme_heat');
    } else if (airTemp > 28 || (isBulbStage && airTemp > 26)) {
      out.add('airTemp.heat');
    }

    if (airHum > 90) {
      out.add('airHumidity.critical');
      out.add('onion.foliar_disease_risk');
    } else if (airHum > 85) {
      out.add('airHumidity.high');
      out.add('onion.foliar_disease_risk');
    }

    // Cebolla es sensible a sales (estricto).
    if (t.ec > 2.6) {
      out.add('onion.salinity_critical');
    } else if (t.ec > 1.8) {
      out.add('onion.salinity_warning');
    }

    switch (boltingRisk) {
      case OnionBoltingRisk.critico:
        out.add('onion.bolting_critical');
        break;
      case OnionBoltingRisk.alto:
        out.add('onion.bolting_warning');
        break;
      case OnionBoltingRisk.medio:
      case OnionBoltingRisk.bajo:
        break;
    }

    // Fotoperiodo manda en induccion: recordatorio de logica/modelo.
    if (stageKey == OnionStageKey.induccionBulbificacion &&
        !stage.profile.isBunching &&
        stage.profile.photoperiodSensitivity01 >= 0.80) {
      out.add('onion.photoperiod_watch');
    }

    // Maduracion: cuello/curado + humedad alta = riesgo de conservacion.
    if (isMaturity && (airHum > 85 || stage.profile.bulbQualitySensitivity01 >= 0.85)) {
      out.add('onion.neck_curing_risk');
    }

    if (isMaturity) {
      final urgentByHeatOrHumidity = airTemp > 30 || airHum > 88;
      out.add(urgentByHeatOrHumidity
          ? 'onion.harvest_urgent'
          : 'onion.harvest_window');
    } else if (stageKey == OnionStageKey.espigado) {
      out.add('onion.harvest_past');
    } else if (stage.daysToHarvestMin > 0 && stage.daysToHarvestMin <= 10) {
      out.add('onion.harvest_review');
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

  static String _stageLabelEs(OnionStageKey stageKey) {
    switch (stageKey) {
      case OnionStageKey.germinacion:
        return 'Germinacion';
      case OnionStageKey.emergencia:
        return 'Emergencia / plantula';
      case OnionStageKey.establecimiento:
        return 'Establecimiento';
      case OnionStageKey.vegetativo:
        return 'Desarrollo vegetativo foliar';
      case OnionStageKey.induccionBulbificacion:
        return 'Induccion a bulbificacion';
      case OnionStageKey.inicioBulbo:
        return 'Inicio de bulbo';
      case OnionStageKey.llenadoBulbo:
        return 'Llenado de bulbo';
      case OnionStageKey.maduracionCosecha:
        return 'Maduracion / cuello / cosecha';
      case OnionStageKey.espigado:
        return 'Espigado / tallo floral';
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
