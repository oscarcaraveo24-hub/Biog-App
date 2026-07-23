import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/agave/agave_lifecycle.dart';
import 'package:bio_g/core/crops/agave/agave_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Motor AgroScore del Maguey / Agave ornamental (Documento B §8).
///
/// Es un ESPEJO ESTRUCTURAL de `AloeAgroScoreEngine` (que a su vez lo es de la
/// suculenta, el cactus y el frijol): mismas bandas, mismas CLAVES CANÓNICAS de
/// alerta y el mismo motor de nutrición compartido. Lo único propio es la
/// agronomía (castigos, umbrales de aire y multiplicadores por perfil).
///
/// Nunca emite claves `agave.*`, `mg.*`, `maguey.*`, `tequila.*`, `jima.*` ni
/// `quiote.*`: el `AlertsEngine` compartido las descartaría en silencio y el
/// cultivo quedaría MUDO (Doc B §12). El evento manual de tallo floral
/// (`agave.flower_stalk_observed`) pertenece al EventEngine, no aquí.
///
/// Castigos base (Doc B §8.1): el exceso de agua es EL riesgo (0.42, más duro
/// que la sequía 0.64); el frío húmedo es compuesto (0.62); la EC y el pH
/// castigan con dureza media (0.60 / 0.62) porque el maguey tolera una banda
/// amplia; la resistencia pesa en la raíz (0.68).
class AgaveAgroScoreEngine {
  const AgaveAgroScoreEngine._();

  /// Etapas críticas: la raíz aún no trabaja o la planta gasta poca agua. Un
  /// exceso de agua aquí es lo que la mata (Doc B §8.3, bump +2 por etapa).
  static const Set<String> criticalStages = <String>{
    AgaveStageIds.installationEstablishment,
    AgaveStageIds.rootEstablishment,
    AgaveStageIds.rest,
  };

  /// Etapas semicríticas: crecimiento activo y etapa por confirmar (bump +1).
  static const Set<String> semiCriticalStages = <String>{
    AgaveStageIds.activeGrowth,
    AgaveStageIds.unknown,
  };

  // ── Castigos base (Doc B §8.1) ─────────────────────────────────────────────
  // Factor menor = castigo mayor. El exceso de agua pesa más que la sequía.
  static const double _moistureCriticalHighPenalty = 0.42;
  static const double _moistureCriticalLowPenalty = 0.64;
  static const double _coldAndWetPenalty = 0.62;
  static const double _soilTempCriticalPenalty = 0.56;
  static const double _phCriticalPenalty = 0.62;
  static const double _ecCriticalPenalty = 0.60;
  static const double _resistanceCriticalPenalty = 0.68;

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
    final stage = normalizeAgaveStageId(stageId);
    final adj = agaveProfileAdjustments(profileId);

    final moisture01 = _normalizeMoisture01(t.soilMoisturePct, cal);
    final moistureRawCal = moisture01 * 100.0;

    final moistureEval = _eval(
      value: moistureRawCal,
      range: targets.moistureRaw,
    );
    final soilTempEval = _eval(value: t.soilTempC, range: targets.soilTemp);
    final phEval = _eval(value: t.ph, range: targets.ph);
    final ecEval = _eval(value: t.ec, range: targets.ec);
    final resEval = _eval(value: t.resistance, range: targets.resistance);

    final nMetric = _interpretNutrient(
      metricKey: AgroMetricKey.n,
      rawMgKg: t.n.toDouble(),
      stage: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      t: t,
      limitToReview: adj.limitNpkPriorityToReview,
    );
    final pMetric = _interpretNutrient(
      metricKey: AgroMetricKey.p,
      rawMgKg: t.p.toDouble(),
      stage: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      t: t,
      limitToReview: adj.limitNpkPriorityToReview,
    );
    final kMetric = _interpretNutrient(
      metricKey: AgroMetricKey.k,
      rawMgKg: t.k.toDouble(),
      stage: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      t: t,
      limitToReview: adj.limitNpkPriorityToReview,
    );

    final metrics = <AgroMetricKey, AgroMetricEval>{
      AgroMetricKey.soilMoisture: _wrap(
        moistureEval,
        displayValue: moistureRawCal,
      ),
      AgroMetricKey.soilTemp: _wrap(soilTempEval, displayValue: t.soilTempC),
      AgroMetricKey.ph: _wrap(phEval, displayValue: t.ph),
      AgroMetricKey.ec: _wrap(ecEval, displayValue: t.ec),
      AgroMetricKey.resistance: _wrap(resEval, displayValue: t.resistance),
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

    final bool coldAndWet = _isColdAndWet(
      soilTempC: t.soilTempC,
      moisturePct: moistureRawCal,
      targets: targets,
    );

    double criticalPenalty = 1.0;

    // 1) El exceso de agua es EL riesgo del maguey: daña raíz y cuello y pudre.
    //    Pesa más que la falta; el maguey tolera bien la sequía moderada.
    if (moistureEval.band == AgroBand.critical) {
      final bool isExcess = moistureRawCal > targets.moistureRaw.optimalMax;
      criticalPenalty *= isExcess
          ? _scaled(
              _moistureCriticalHighPenalty,
              adj.moistureCriticalHighPenaltyMultiplier,
            )
          : _scaled(
              _moistureCriticalLowPenalty,
              adj.moistureCriticalLowPenaltyMultiplier,
            );
    }

    // 2) Temperatura crítica. El calor de maceta se castiga más en MG-01/MG-04;
    //    el frío seco se castiga más en el perfil suave MG-04 (Doc B §7).
    if (soilTempEval.band == AgroBand.critical) {
      final bool isHeat = t.soilTempC > targets.soilTemp.optimalMax;
      criticalPenalty *= isHeat
          ? _scaled(
              _soilTempCriticalPenalty,
              adj.containerHeatSeverityMultiplier,
            )
          : _scaled(_soilTempCriticalPenalty, adj.coldSeverityMultiplier);
    }

    // 3) pH. El maguey tolera una banda amplia; una lectura extrema importa,
    //    pero no se corrige desde una sola lectura (Doc B §4.3, §8.2).
    if (phEval.band == AgroBand.critical) criticalPenalty *= _phCriticalPenalty;

    // 4) Sales. La EC crítica precede a cualquier lectura NPK baja. Tolerancia
    //    variable por especie: MG-03 la castiga algo más; MG-02 algo menos.
    if (ecEval.band == AgroBand.critical) {
      final bool isHigh = t.ec > targets.ec.optimalMax;
      criticalPenalty *= isHigh
          ? _scaled(_ecCriticalPenalty, adj.ecHighMultiplier)
          : _ecCriticalPenalty;
    }

    // 5) Sustrato apretado: la raíz batalla. USDA usa ~2 MPa como restricción
    //    probable. MG-02 no recibe permiso para compactación (Doc B §4.5, §7.2).
    if (resEval.band == AgroBand.critical) {
      final bool isHigh = t.resistance > targets.resistance.optimalMax;
      criticalPenalty *= isHigh
          ? _scaled(_resistanceCriticalPenalty, adj.resistanceHighMultiplier)
          : _resistanceCriticalPenalty;
    }

    criticalPenalty *= _nutrientPenaltyFactor(
      nMetric.priorityLabel,
      highMultiplier: adj.nitrogenHighSeverityMultiplier,
    );
    criticalPenalty *= _nutrientPenaltyFactor(pMetric.priorityLabel);
    criticalPenalty *= _nutrientPenaltyFactor(kMetric.priorityLabel);

    // 6) Frío + sustrato húmedo: castigo compuesto (Doc B §8.1, combinación A).
    //    Es el peor caso; MG-03 y MG-04 lo agravan (especies sensibles al frío).
    if (coldAndWet) {
      criticalPenalty *= _scaled(
        _coldAndWetPenalty,
        adj.coldWetSeverityMultiplier,
      );
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

    // Claves CANÓNICAS del AlertsEngine compartido. Mismos mensajes que frijol.
    final suggested = <String>[];
    _pushSoilAlert(suggested, 'soilMoisture', moistureEval, stage);
    _pushSoilAlert(suggested, 'soilTemp', soilTempEval, stage);
    _pushSoilAlert(suggested, 'ph', phEval, stage);
    _pushSoilAlert(suggested, 'ec', ecEval, stage);
    _pushSoilAlert(suggested, 'resistance', resEval, stage);

    _pushNutrientAlert(suggested, 'npk.n', nMetric, stage);
    _pushNutrientAlert(suggested, 'npk.p', pMetric, stage);
    _pushNutrientAlert(suggested, 'npk.k', kMetric, stage);
    _pushEnvironmentalAlerts(suggested, t);

    int severityBump = criticalStages.contains(stage)
        ? 2
        : semiCriticalStages.contains(stage)
        ? 1
        : 0;
    if (coldAndWet) severityBump += adj.coldWetSeverityBump;

    final built = AlertsEngine.buildFromSuggestedKeys(
      deviceId: t.deviceId,
      now: t.timestamp,
      severityBump: severityBump,
      suggestedKeys: suggested,
      prev: alertsState,
      cooldown: alertsCooldown,
      cropLabel: cropLabel ?? 'tu maguey',
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

  /// Aplica el multiplicador de perfil sobre un castigo base.
  /// Un multiplicador > 1 castiga MÁS (factor menor).
  static double _scaled(double basePenalty, double multiplier) {
    final scaled = 1.0 - ((1.0 - basePenalty) * multiplier);
    return scaled.clamp(0.05, 1.0);
  }

  /// Frío con sustrato húmedo: la combinación que se lleva la raíz (Doc B §1.2).
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

  static AgroMetricEval _interpretNutrient({
    required AgroMetricKey metricKey,
    required double rawMgKg,
    required String stage,
    required String stageLabelEs,
    required StageTargets targets,
    required StageWeights weights,
    required BioGTelemetry t,
    bool limitToReview = false,
  }) {
    final interpretation = NutrientRecommendationEngine.interpret(
      nutrient: metricKey,
      rawPpm: rawMgKg,
      cropKey: 'agave',
      stageKey: stage,
      targets: targets,
      weights: weights,
      ph: t.ph,
      ec: t.ec,
      soilMoisturePct: t.soilMoisturePct,
    );

    final NutrientPriorityLabel label = limitToReview
        ? _capPriorityToReview(interpretation.label)
        : interpretation.label;

    return AgroMetricEval(
      band: interpretation.label.agroBand,
      score01: label
          .severityScore01(stagePressure01: interpretation.stagePressure01)
          .clamp(0.0, 1.0),
      labelEs: interpretation.labelEs,
      value: rawMgKg,
      priorityLabel: label,
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

  /// MG-SKIP: techo de prioridad = revisión (Doc B §7.5). Con un perfil sin
  /// confirmar, una lectura de sonda NUNCA se convierte en "acción recomendada".
  /// La banda y la interpretación se conservan: no se anula el NPK.
  static NutrientPriorityLabel _capPriorityToReview(
    NutrientPriorityLabel label,
  ) {
    switch (label) {
      case NutrientPriorityLabel.actionRecommended:
      case NutrientPriorityLabel.highPriority:
        return NutrientPriorityLabel.reviewManagement;
      case NutrientPriorityLabel.reviewAccumulation:
      case NutrientPriorityLabel.reviewManagement:
      case NutrientPriorityLabel.possibleExcess:
      case NutrientPriorityLabel.mediumPriority:
      case NutrientPriorityLabel.lowPriority:
      case NutrientPriorityLabel.noPriority:
      case NutrientPriorityLabel.unknown:
        return label;
    }
  }

  static AgroMetricEval _wrap(_Eval e, {required double displayValue}) {
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
    return label.severityScore01(
      stagePressure01: metric.stagePressure01 ?? 0.0,
    );
  }

  static double _nutrientHealthScore(AgroMetricEval metric) {
    final label = metric.priorityLabel;
    if (label == null) return metric.score01.clamp(0.0, 1.0);
    return label.healthScore01(stagePressure01: metric.stagePressure01 ?? 0.0);
  }

  /// Castigo por nutriente. Una lectura BAJA aislada no aplica castigo compuesto
  /// (Doc B §8.1): el agua y las sales mandan, y un N bajo por sí solo no vuelve
  /// "Alerta" un cultivo Óptimo. Solo el exceso compatible con acumulación
  /// castiga (x0.80, Doc B §8.1).
  static double _nutrientPenaltyFactor(
    NutrientPriorityLabel? label, {
    double highMultiplier = 1.0,
  }) {
    if (label == null) return 1.0;
    switch (label) {
      case NutrientPriorityLabel.reviewAccumulation:
        // Acumulación compatible (nutriente alto + sales): castigo notorio.
        return _scaled(0.80, highMultiplier);
      case NutrientPriorityLabel.possibleExcess:
        return _scaled(0.90, highMultiplier);
      case NutrientPriorityLabel.actionRecommended:
      case NutrientPriorityLabel.reviewManagement:
      case NutrientPriorityLabel.highPriority:
      case NutrientPriorityLabel.mediumPriority:
      case NutrientPriorityLabel.lowPriority:
      case NutrientPriorityLabel.noPriority:
      case NutrientPriorityLabel.unknown:
        return 1.0;
    }
  }

  /// Clasificación con la semántica del Doc B §3.3 (bordes INCLUSIVOS):
  ///
  ///   v <= lowMax                   → crítico (por defecto)
  ///   lowMax < v < optimalMin       → bajo
  ///   optimalMin <= v <= optimalMax → óptimo
  ///   optimalMax < v < highMin      → alto
  ///   v >= highMin                  → crítico (por exceso)
  static _Eval _eval({required double value, required AgroRange range}) {
    if (!value.isFinite || value.isNaN) {
      return _Eval(value: value, band: AgroBand.unknown, score01: 0.0);
    }

    final lowMax = math.min(range.lowMax, range.optimalMin);
    final optMin = math.max(range.lowMax, range.optimalMin);
    final optMax = math.max(range.optimalMax, optMin);
    final highMin = math.max(range.highMin, optMax);

    AgroBand band;
    if (value <= lowMax) {
      band = AgroBand.critical;
    } else if (value < optMin) {
      band = AgroBand.low;
    } else if (value <= optMax) {
      band = AgroBand.optimal;
    } else if (value < highMin) {
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

    if (v > lowMax && v < optMin) {
      final t = _invLerp(lowMax, optMin, v);
      return _lerp(0.55, 0.95, t);
    }

    if (v > optMax && v < highMin) {
      final t = _invLerp(optMax, highMin, v);
      return _lerp(0.95, 0.55, t);
    }

    if (v <= lowMax) {
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

    // La humedad ALTA avisa SIEMPRE, en cualquier etapa: es el riesgo que de
    // verdad se lleva la planta.
    if (key == 'soilMoisture' && e.band == AgroBand.high) {
      out.add('$key.high');
      return;
    }

    // Las sales altas también avisan siempre: la EC no tiene tarjeta propia,
    // así que la alerta es su único canal (Doc B §13.2).
    if (key == 'ec' && e.band == AgroBand.high) {
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

  static void _pushEnvironmentalAlerts(List<String> out, BioGTelemetry t) {
    final airTemp = t.airTempC;
    final airHum = t.airHumidityPct;

    // El maguey NO promete tolerancia a helada en v1 (Doc A §3.4, §11.5): el
    // frío avisa. Es algo más rústico que la sábila, pero MG-04 (hoja suave) es
    // sensible; la prudencia manda. Umbrales D1 de ingeniería.
    if (airTemp <= 0) {
      out.add('airTemp.frost');
    } else if (airTemp < 5) {
      out.add('airTemp.cold');
    }

    // Tolera bien el calor (planta de zonas áridas), más que la sábila.
    if (airTemp > 44) {
      out.add('airTemp.extreme_heat');
    } else if (airTemp > 39) {
      out.add('airTemp.heat');
    }

    // Humedad ambiental alta sostenida: favorece tejido blando, mancha y
    // antracnosis (Doc C §6, MG-SYN-008/009).
    if (airHum > 90) {
      out.add('airHumidity.critical');
    } else if (airHum > 80) {
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
