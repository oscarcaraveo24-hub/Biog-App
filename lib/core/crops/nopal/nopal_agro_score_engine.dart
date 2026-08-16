import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/nopal/nopal_lifecycle.dart';
import 'package:bio_g/core/crops/nopal/nopal_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Motor AgroScore del Nopal ornamental (Documento B §16).
///
/// Es un ESPEJO ESTRUCTURAL de `AgaveAgroScoreEngine` (que a su vez lo es de la
/// sábila, la suculenta, el cactus y el frijol): mismas bandas, mismas CLAVES
/// CANÓNICAS de alerta y el mismo motor de nutrición compartido. Lo único propio
/// es la agronomía (castigos, combinaciones, umbrales de aire y multiplicadores
/// por perfil).
///
/// Nunca emite claves `nopal.*`, `no.*`, `opuntia.*` ni `tuna.*`: el
/// `AlertsEngine` compartido las descartaría en silencio y el cultivo quedaría
/// MUDO (Doc B §1.4). El corte manual de una penca o de una tuna pertenece al
/// EventEngine, no aquí, y NO cambia la etapa (Doc B §3.9).
///
/// Regla maestra de interpretación (Doc B §0):
///
///   Humedad → Temperatura → EC → pH → Resistencia → NPK
///
/// Castigos base (Doc B §16.1): el exceso de agua es EL riesgo (0.43, mucho más
/// duro que la sequía 0.64); la EC y la temperatura crítica castigan igual
/// (0.56); el pH tolera banda amplia (0.64); la resistencia pesa en la raíz
/// (0.68).
class NopalAgroScoreEngine {
  const NopalAgroScoreEngine._();

  /// Etapas críticas: la raíz aún no trabaja o la planta gasta poca agua. Un
  /// exceso de agua aquí es lo que la mata (Doc B §17, bump +2 por etapa).
  static const Set<String> criticalStages = <String>{
    NopalStageIds.installationEstablishment,
    NopalStageIds.rootEstablishment,
    NopalStageIds.rest,
  };

  /// Etapas semicríticas: crecimiento activo y etapa por confirmar (bump +1).
  static const Set<String> semiCriticalStages = <String>{
    NopalStageIds.activeGrowth,
    NopalStageIds.unknown,
  };

  // ── Castigos base (Doc B §16.1) ────────────────────────────────────────────
  // Factor menor = castigo mayor.
  static const double _moistureCriticalHighPenalty = 0.43;
  static const double _moistureCriticalLowPenalty = 0.64;
  static const double _soilTempCriticalPenalty = 0.56;
  static const double _phCriticalPenalty = 0.64;
  static const double _ecCriticalPenalty = 0.56;
  static const double _resistanceCriticalPenalty = 0.68;
  static const double _npkAccumulationPenalty = 0.76;
  static const double _npkCriticalLowInGrowthPenalty = 0.84;

  // ── Combinaciones (Doc B §16.2) ────────────────────────────────────────────
  // Cada una se aplica UNA sola vez y en el orden fijo del Doc B §16.4. Las tres
  // combinaciones por perfil del Doc B §16.2 que comparten disparador con un
  // multiplicador de §15 (NO-02 + resistencia crítica, NO-04 + frío húmedo) se
  // implementan como ese multiplicador para no castigar dos veces lo mismo.
  static const double _coldAndWetPenalty = 0.60;
  static const double _ecHighAndDryPenalty = 0.72;
  static const double _ecHighAndWetPenalty = 0.70;
  static const double _heatAndDroughtInGrowthPenalty = 0.72;
  static const double _establishmentAndCriticalWetPenalty = 0.82;
  static const double _containerEcHighPenalty = 0.85;

  // ── Umbrales de aire (Doc B §18) ───────────────────────────────────────────
  static const double _airFrostC = 0.0;
  static const double _airColdC = 5.0;
  static const double _airHeatC = 38.0;
  static const double _airExtremeHeatC = 45.0;
  static const double _airHumidityHighPct = 82.0;
  static const double _airHumidityCriticalPct = 92.0;

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
    String? cultivationContextId,
  }) {
    // 1) Normalizar humedad.
    final stage = normalizeNopalStageId(stageId);
    final adj = nopalProfileAdjustments(profileId);

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

    // 5) Clasificar métricas (targets y contexto de pH ya vienen resueltos).
    final moistureEval = _eval(
      value: moistureRawCal,
      range: targets.moistureRaw,
    );
    final soilTempEval = _eval(value: t.soilTempC, range: targets.soilTemp);
    final phEval = _eval(value: t.ph, range: targets.ph);
    final ecEval = _eval(value: t.ec, range: targets.ec);
    final resEval = _eval(value: t.resistance, range: targets.resistance);

    // 6) Interpretar NPK con el motor compartido. Las puertas del Doc B §19.1
    //    bajan la prioridad cuando el contexto no permite una recomendación
    //    fuerte; NO apagan la tarjeta.
    final bool npkGated =
        adj.limitNpkPriorityToReview ||
        stage == NopalStageIds.unknown ||
        stage == NopalStageIds.rest ||
        moistureEval.band == AgroBand.critical ||
        soilTempEval.band == AgroBand.critical ||
        ecEval.band == AgroBand.critical ||
        phEval.band == AgroBand.critical;

    final nMetric = _interpretNutrient(
      metricKey: AgroMetricKey.n,
      hasData: t.hasNitrogenData,
      rawMgKg: t.n.toDouble(),
      stage: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      t: t,
      limitToReview: npkGated,
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
      limitToReview: npkGated,
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
      limitToReview: npkGated,
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

    // 7) Score ponderado.
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

    final bool moistureExcess =
        moistureRawCal > targets.moistureRaw.optimalMax;
    final bool moistureDeficit =
        moistureRawCal < targets.moistureRaw.optimalMin;
    final bool ecHigh = t.ec > targets.ec.optimalMax;

    final bool coldAndWet = _isColdAndWet(
      soilTempC: t.soilTempC,
      moisturePct: moistureRawCal,
      targets: targets,
    );

    // 8) Castigos individuales. Cada uno se aplica UNA vez.
    double criticalPenalty = 1.0;

    // El exceso de agua es EL riesgo del nopal: desplaza oxígeno, prolonga el
    // contacto húmedo en la base y agrava el frío (Doc B §3.1).
    if (moistureEval.band == AgroBand.critical) {
      criticalPenalty *= moistureExcess
          ? _scaled(
              _moistureCriticalHighPenalty,
              adj.moistureCriticalHighPenaltyMultiplier,
            )
          : _scaled(
              _moistureCriticalLowPenalty,
              adj.moistureCriticalLowPenaltyMultiplier,
            );
    }

    // Temperatura crítica. El calor de sustrato confinado se castiga más en
    // NO-01; el frío se castiga más en NO-02 y menos en NO-04 confirmado y
    // estable (Doc B §15).
    if (soilTempEval.band == AgroBand.critical) {
      final bool isHeat = t.soilTempC > targets.soilTemp.optimalMax;
      criticalPenalty *= isHeat
          ? _scaled(
              _soilTempCriticalPenalty,
              adj.containerHeatSeverityMultiplier,
            )
          : _scaled(
              _soilTempCriticalPenalty,
              _effectiveColdMultiplier(adj: adj, stage: stage),
            );
    }

    // pH. Banda amplia; una lectura extrema importa pero no se corrige desde una
    // sola lectura (Doc B §3.4).
    if (phEval.band == AgroBand.critical) criticalPenalty *= _phCriticalPenalty;

    // Sales. La EC crítica precede a cualquier lectura NPK baja (Doc B §3.5).
    if (ecEval.band == AgroBand.critical) {
      criticalPenalty *= ecHigh
          ? _scaled(_ecCriticalPenalty, adj.ecHighMultiplier)
          : _ecCriticalPenalty;
    }

    // Sustrato apretado: la raíz batalla. NO-02 castiga más por anclaje
    // (Doc B §3.6, §15.2). Aquí se implementa la combinación "NO-02 +
    // resistencia crítica" del Doc B §16.2, para no castigarla dos veces.
    if (resEval.band == AgroBand.critical) {
      final bool isHigh = t.resistance > targets.resistance.optimalMax;
      criticalPenalty *= isHigh
          ? _scaled(_resistanceCriticalPenalty, adj.resistanceHighMultiplier)
          : _resistanceCriticalPenalty;
    }

    // NPK: pesa menos y nunca supera una raíz crítica (Doc B §16.3).
    criticalPenalty *= _nutrientPenaltyFactor(
      nMetric.priorityLabel,
      stage: stage,
      highMultiplier: adj.nitrogenHighSeverityMultiplier,
    );
    criticalPenalty *= _nutrientPenaltyFactor(
      pMetric.priorityLabel,
      stage: stage,
    );
    criticalPenalty *= _nutrientPenaltyFactor(
      kMetric.priorityLabel,
      stage: stage,
    );

    // 9) Combinaciones (Doc B §16.2), en orden fijo.
    // A) Frío + suelo húmedo: el peor caso. NO-04 lo agrava (aquí se implementa
    //    la combinación "NO-04 + frío húmedo" del §16.2).
    if (coldAndWet) {
      criticalPenalty *= _scaled(
        _coldAndWetPenalty,
        adj.coldWetSeverityMultiplier,
      );
    }

    // B) EC alta + suelo seco: al secarse el sustrato la EC sube y pierde
    //    representatividad (Doc B §3.5).
    if (ecHigh && ecEval.band != AgroBand.optimal && moistureDeficit) {
      criticalPenalty *= _ecHighAndDryPenalty;
    }

    // C) EC alta + humedad alta: sales disueltas en la zona radicular.
    if (ecHigh && ecEval.band != AgroBand.optimal && moistureExcess) {
      criticalPenalty *= _ecHighAndWetPenalty;
    }

    // D) Calor + sequía durante el crecimiento activo.
    if (stage == NopalStageIds.activeGrowth &&
        t.soilTempC > targets.soilTemp.optimalMax &&
        moistureDeficit) {
      criticalPenalty *= _heatAndDroughtInGrowthPenalty;
    }

    // E) Instalación o raíz con humedad crítica ALTA: la ventana más delicada.
    if ((stage == NopalStageIds.installationEstablishment ||
            stage == NopalStageIds.rootEstablishment) &&
        moistureEval.band == AgroBand.critical &&
        moistureExcess) {
      criticalPenalty *= _establishmentAndCriticalWetPenalty;
    }

    // F) NO-01 con EC ALTA (banda alta, no crítica) en sustrato confinado. La
    //    banda crítica ya se castigó arriba con `ecHighMultiplier`: aquí no se
    //    duplica (Doc B §16.2).
    if (adj.containerHeatSeverityMultiplier > 1.0 &&
        _isConfinedSubstrate(cultivationContextId) &&
        ecEval.band == AgroBand.high) {
      criticalPenalty *= _containerEcHighPenalty;
    }

    // 10) Limitar.
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

    // 11) Claves CANÓNICAS del AlertsEngine compartido. Mismos mensajes que
    //     frijol. Nunca claves propias del cultivo (Doc B §1.4).
    final suggested = <String>[];
    _pushSoilAlert(suggested, 'soilMoisture', moistureEval, stage);
    _pushSoilAlert(suggested, 'soilTemp', soilTempEval, stage);
    _pushSoilAlert(suggested, 'ph', phEval, stage);
    _pushSoilAlert(suggested, 'ec', ecEval, stage);
    _pushSoilAlert(suggested, 'resistance', resEval, stage);

    _pushNutrientAlert(suggested, 'npk.n', nMetric, stage);
    _pushNutrientAlert(suggested, 'npk.p', pMetric, stage);
    _pushNutrientAlert(suggested, 'npk.k', kMetric, stage);
    _pushEnvironmentalAlerts(suggested, t, stage: stage, adj: adj);

    // Severity bumps (Doc B §17).
    int severityBump = criticalStages.contains(stage)
        ? 2
        : semiCriticalStages.contains(stage)
        ? 1
        : 0;
    if (coldAndWet) severityBump += adj.coldWetSeverityBump;

    // 12) Construir alertas.
    final built = AlertsEngine.buildFromSuggestedKeys(
      deviceId: t.deviceId,
      now: t.timestamp,
      severityBump: severityBump,
      suggestedKeys: suggested,
      prev: alertsState,
      cooldown: alertsCooldown,
      cropLabel: cropLabel ?? 'tu nopal',
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

  /// El ajuste de frío de NO-04 SOLO aplica en planta estable o en reposo
  /// (Doc B §6.5, §15.4). En instalación y raíz se usa el castigo base: un
  /// ejemplar recién plantado no tiene la rusticidad de una colonia establecida.
  static double _effectiveColdMultiplier({
    required NopalProfileAdjustments adj,
    required String stage,
  }) {
    if (!adj.coldToleranceRequiresStablePlant) return adj.coldSeverityMultiplier;
    final bool stablePlant =
        stage == NopalStageIds.maintenance || stage == NopalStageIds.rest;
    return stablePlant ? adj.coldSeverityMultiplier : 1.0;
  }

  static bool _isConfinedSubstrate(String? contextId) {
    final v = contextId?.trim().toLowerCase();
    return v == 'pot' || v == 'nursery';
  }

  /// Aplica el multiplicador de perfil sobre un castigo base.
  /// Un multiplicador > 1 castiga MÁS (factor menor).
  static double _scaled(double basePenalty, double multiplier) {
    final scaled = 1.0 - ((1.0 - basePenalty) * multiplier);
    return scaled.clamp(0.05, 1.0);
  }

  /// Frío con suelo húmedo: la combinación que se lleva la raíz (Doc B §16.2).
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
    required bool hasData,
    required String stage,
    required String stageLabelEs,
    required StageTargets targets,
    required StageWeights weights,
    required BioGTelemetry t,
    bool limitToReview = false,
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
      cropKey: 'nopal',
        stageKey: stage,
      targets: targets,
      weights: weights,
      ph: t.ph,
      ec: t.ec,
      soilMoisturePct: t.hasSoilMoistureData ? t.soilMoisturePct : null,
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

  /// Puertas del Doc B §19.1: techo de prioridad = revisión. Con perfil sin
  /// confirmar, etapa sin confirmar, reposo o una métrica de suelo en crítico,
  /// una lectura de sonda NUNCA se convierte en "acción recomendada". La banda y
  /// la interpretación se conservan: no se anula el NPK, se cambia prioridad.
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

  /// Castigo por nutriente (Doc B §16.1). Una lectura BAJA aislada solo castiga
  /// DURANTE EL CRECIMIENTO (0.84): fuera de crecimiento, un N bajo no vuelve
  /// "Alerta" un cultivo Óptimo. El exceso compatible con acumulación castiga
  /// 0.76.
  static double _nutrientPenaltyFactor(
    NutrientPriorityLabel? label, {
    required String stage,
    double highMultiplier = 1.0,
  }) {
    if (label == null) return 1.0;
    switch (label) {
      case NutrientPriorityLabel.reviewAccumulation:
        return _scaled(_npkAccumulationPenalty, highMultiplier);
      case NutrientPriorityLabel.possibleExcess:
        return _scaled(0.90, highMultiplier);
      case NutrientPriorityLabel.actionRecommended:
      case NutrientPriorityLabel.highPriority:
        return stage == NopalStageIds.activeGrowth
            ? _npkCriticalLowInGrowthPenalty
            : 1.0;
      case NutrientPriorityLabel.reviewManagement:
      case NutrientPriorityLabel.mediumPriority:
      case NutrientPriorityLabel.lowPriority:
      case NutrientPriorityLabel.noPriority:
      case NutrientPriorityLabel.unknown:
        return 1.0;
    }
  }

  /// Clasificación con bordes INCLUSIVOS (Doc B §4.2):
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
    // verdad se lleva la planta (Doc B §3.1).
    if (key == 'soilMoisture' && e.band == AgroBand.high) {
      out.add('$key.high');
      return;
    }

    // Las sales altas también avisan siempre: la EC no tiene tarjeta propia, así
    // que la alerta es su único canal (Doc B §1.2, §8.3).
    if (key == 'ec' && e.band == AgroBand.high) {
      out.add('$key.high');
      return;
    }

    // La EC BAJA no dispara aviso fuerte: puede ser agua limpia o suelo pobre
    // pero funcional (Doc B §8.2).
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

  /// Umbrales de aire (Doc B §18). Son D1 de ingeniería y NO representan límites
  /// de muerte. El aviso de HELADA nunca se elimina, ni siquiera en NO-04
  /// (Doc B §18.2).
  static void _pushEnvironmentalAlerts(
    List<String> out,
    BioGTelemetry t, {
    required String stage,
    required NopalProfileAdjustments adj,
  }) {
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

    if (airTemp <= _airFrostC) {
      out.add('airTemp.frost');
    } else if (airTemp < _airColdC) {
      // "Cold" solo cuando NO hay reposo confirmado (Doc B §18.1): en reposo un
      // aire fresco es esperable y no merece aviso por sí solo.
      if (stage != NopalStageIds.rest) out.add('airTemp.cold');
    }

    if (airTemp > _airExtremeHeatC) {
      out.add('airTemp.extreme_heat');
    } else if (airTemp > _airHeatC) {
      out.add('airTemp.heat');
    }

    // Humedad ambiental alta sostenida: por sí sola NO diagnostica; se combina
    // con suelo húmedo, frío, poca ventilación o tejido dañado (Doc B §18.3).
    if (airHum > _airHumidityCriticalPct) {
      out.add('airHumidity.critical');
    } else if (airHum > _airHumidityHighPct) {
      out.add('airHumidity.high');
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
