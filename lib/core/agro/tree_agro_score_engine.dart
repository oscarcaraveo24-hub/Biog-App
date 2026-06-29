import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/agro/tree_nutrition_modifier.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Motor AgroScore GENÉRICO para árboles perennes (manzano, pera, …).
///
/// Es la generalización del motor del manzano exigida por el estándar BIO-G
/// ("antes del segundo árbol, generalizar cualquier helper hardcodeado a
/// apple_tree, sin duplicar lógica base"). Tanto `AppleTreeAgroScoreEngine` como
/// `PearTreeAgroScoreEngine` delegan aquí pasando su `cropKey` y su
/// [TreeNutritionModifier]; el comportamiento del manzano queda idéntico (sus
/// pruebas de regresión lo verifican).
///
/// Arquitectura: el árbol es un cultivo de PRIMERA CLASE dentro del mismo
/// pipeline que los granos:
/// - Suelo (humedad, temp, pH, EC, resistencia) → bandas por [AgroRange] con
///   umbrales internos de observación/crítico (5 zonas agronómicas v1.4).
/// - N/P/K → [NutrientRecommendationEngine.interpret] con el `cropKey` del árbol,
///   targets/weights del perfil universal y el modificador del árbol.
///
/// DECISIÓN DE ÁRBOL (alto útil vs exceso):
/// - "Alto útil" (`possibleExcess`, entre óptimo y `highMin`) NO penaliza el
///   score ni alerta.
/// - "Exceso" real (`reviewAccumulation`, ≥ `highMin`) SÍ baja el score y avisa.
/// - El N en EXCESO tardío (llenado/madurez) recibe penalización EXTRA según el
///   modificador del árbol/perfil (color/calidad/almacenamiento).
class TreeAgroScoreEngine {
  const TreeAgroScoreEngine._();

  /// Etapas críticas (más peso al estrés en alertas/score).
  static const Set<String> criticalStages = <String>{
    TreeStageIds.flowering,
    TreeStageIds.fruitSet,
    TreeStageIds.rootEstablishment,
  };

  /// Etapas semicríticas.
  static const Set<String> semiCriticalStages = <String>{
    TreeStageIds.fruitFill,
    TreeStageIds.postHarvest,
  };

  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluate({
    required BioGTelemetry t,
    required String cropKey,
    required TreeNutritionModifier modifier,
    required String stageId,
    required String stageLabelEs,
    required StageTargets targets,
    required StageWeights weights,
    AlertsState alertsState = const AlertsState(),
    Calibration? cal,
    Duration alertsCooldown = AlertsEngine.defaultCooldown,
    String? cropLabel,
    String? profileId,
    String? varietyId,
    String? varietyAlias,
  }) {
    final stage = normalizeTreeStageId(stageId);

    final moisture01 = _normalizeMoisture01(t.soilMoisturePct, cal);
    final moistureRawCal = moisture01 * 100.0;

    final moistureEval = _evalTreeSoilMetric(
      metricKey: AgroMetricKey.soilMoisture,
      value: moistureRawCal,
      range: targets.moistureRaw,
    );
    final soilTempEval = _evalTreeSoilMetric(
      metricKey: AgroMetricKey.soilTemp,
      value: t.soilTempC,
      range: targets.soilTemp,
    );
    final phEval = _evalTreeSoilMetric(
      metricKey: AgroMetricKey.ph,
      value: t.ph,
      range: targets.ph,
    );
    final ecEval = _evalTreeSoilMetric(
      metricKey: AgroMetricKey.ec,
      value: t.ec,
      range: targets.ec,
    );
    final resEval = _evalTreeSoilMetric(
      metricKey: AgroMetricKey.resistance,
      value: t.resistance,
      range: targets.resistance,
    );

    final nMetric = _interpretTreeNutrient(
      metricKey: AgroMetricKey.n,
      rawMgKg: t.n.toDouble(),
      hasData: t.hasNitrogenData,
      cropKey: cropKey,
      stageId: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      ph: t.ph,
      ec: t.ec,
      soilMoisturePct: t.soilMoisturePct,
      profileId: profileId,
      varietyId: varietyId,
      varietyAlias: varietyAlias,
    );
    final pMetric = _interpretTreeNutrient(
      metricKey: AgroMetricKey.p,
      rawMgKg: t.p.toDouble(),
      hasData: t.hasPhosphorusData,
      cropKey: cropKey,
      stageId: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      ph: t.ph,
      ec: t.ec,
      soilMoisturePct: t.soilMoisturePct,
      profileId: profileId,
      varietyId: varietyId,
      varietyAlias: varietyAlias,
    );
    final kMetric = _interpretTreeNutrient(
      metricKey: AgroMetricKey.k,
      rawMgKg: t.k.toDouble(),
      hasData: t.hasPotassiumData,
      cropKey: cropKey,
      stageId: stage,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      ph: t.ph,
      ec: t.ec,
      soilMoisturePct: t.soilMoisturePct,
      profileId: profileId,
      varietyId: varietyId,
      varietyAlias: varietyAlias,
    );

    final metrics = <AgroMetricKey, AgroMetricEval>{
      AgroMetricKey.soilMoisture: _wrapLegacy(
        moistureEval,
        displayValue: moistureRawCal,
      ),
      AgroMetricKey.soilTemp: _wrapLegacy(
        soilTempEval,
        displayValue: t.soilTempC,
      ),
      AgroMetricKey.ph: _wrapLegacy(phEval, displayValue: t.ph),
      AgroMetricKey.ec: _wrapLegacy(ecEval, displayValue: t.ec),
      AgroMetricKey.resistance: _wrapLegacy(
        resEval,
        displayValue: t.resistance,
      ),
      AgroMetricKey.n: nMetric,
      AgroMetricKey.p: pMetric,
      AgroMetricKey.k: kMetric,
    };

    final nHealthScore = _treeNutrientHealthScore(nMetric);
    final pHealthScore = _treeNutrientHealthScore(pMetric);
    final kHealthScore = _treeNutrientHealthScore(kMetric);

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

    double criticalPenalty = 1.0;
    if (moistureEval.isCriticalLow) criticalPenalty *= 0.45;
    if (moistureEval.isCriticalHigh) criticalPenalty *= 0.70;
    if (soilTempEval.isCritical) criticalPenalty *= 0.50;
    if (phEval.isCritical) criticalPenalty *= 0.45;
    if (ecEval.isCritical) criticalPenalty *= 0.65;
    if (resEval.isCritical) criticalPenalty *= 0.85;
    criticalPenalty *= _treeNutrientPenaltyFactor(nMetric.priorityLabel);
    criticalPenalty *= _treeNutrientPenaltyFactor(pMetric.priorityLabel);
    criticalPenalty *= _treeNutrientPenaltyFactor(kMetric.priorityLabel);

    // Penalización EXTRA por N en EXCESO real tardío (llenado/madurez); mayor en
    // perfiles sensibles a calidad/almacenamiento — vía el modificador del árbol.
    if (nMetric.priorityLabel == NutrientPriorityLabel.reviewAccumulation) {
      criticalPenalty *= modifier.lateNitrogenExcessPenaltyFactor(stage);
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
        ((weights.nutrientN * _treeNutrientSeverityScore(nMetric)) +
            (weights.nutrientP * _treeNutrientSeverityScore(pMetric)) +
            (weights.nutrientK * _treeNutrientSeverityScore(kMetric))) /
        nutrientWeightSum;

    final suggested = <String>['tree.stage.$stage'];
    _pushSoilSuggestedKey(suggested, 'soilMoisture', moistureEval.band, stage);
    _pushSoilSuggestedKey(suggested, 'soilTemp', soilTempEval.band, stage);
    _pushSoilSuggestedKey(suggested, 'ph', phEval.band, stage);
    _pushSoilSuggestedKey(suggested, 'ec', ecEval.band, stage);
    _pushSoilSuggestedKey(suggested, 'resistance', resEval.band, stage);
    _pushNutrientSuggestedKey(suggested, 'npk.n', nMetric.priorityLabel);
    _pushNutrientSuggestedKey(suggested, 'npk.p', pMetric.priorityLabel);
    _pushNutrientSuggestedKey(suggested, 'npk.k', kMetric.priorityLabel);

    final alertBuild = _buildTreeAlerts(
      telemetry: t,
      stageId: stage,
      metrics: metrics,
      alertsState: alertsState,
      cooldown: alertsCooldown,
    );

    final eval = AgroEvalResult(
      soilControlScore01: soilControlScore01,
      nutrientPriorityScore01: nutrientPriorityScore01.clamp(0.0, 1.0),
      primaryScoreKind: AgroScoreKind.soilControl,
      metrics: metrics,
      alerts: alertBuild.alerts,
      suggestedAlertKeys: suggested,
    );

    return (eval: eval, nextAlertsState: alertBuild.state);
  }

  // ===========================================================================
  // NUTRIENTES (N/P/K) — vía motor compartido
  // ===========================================================================
  static AgroMetricEval _interpretTreeNutrient({
    required AgroMetricKey metricKey,
    required double rawMgKg,
    required bool hasData,
    required String cropKey,
    required String stageId,
    required String stageLabelEs,
    required StageTargets targets,
    required StageWeights weights,
    double? ph,
    double? ec,
    double? soilMoisturePct,
    String? profileId,
    String? varietyId,
    String? varietyAlias,
  }) {
    if (!hasData || rawMgKg <= 0) {
      return AgroMetricEval(
        band: AgroBand.unknown,
        score01: 0.5,
        labelEs: AgroBand.unknown.labelEs,
        value: rawMgKg,
        stageKey: stageId,
        stageLabelEs: stageLabelEs,
        demandWindowLabelEs:
            treeCriticalWindowLabel(stageId) ??
            targets.windowLabelFor(metricKey),
      );
    }

    final interpretation = NutrientRecommendationEngine.interpret(
      nutrient: metricKey,
      rawPpm: rawMgKg,
      cropKey: cropKey,
      stageKey: stageId,
      profileId: profileId,
      varietyId: varietyId,
      varietyAlias: varietyAlias,
      targets: targets,
      weights: weights,
      ph: ph,
      ec: ec,
      soilMoisturePct: soilMoisturePct,
    );

    return AgroMetricEval(
      band: interpretation.label.agroBand,
      score01: _treeHealthForLabel(
        interpretation.label,
        interpretation.stagePressure01,
      ),
      labelEs: interpretation.labelEs,
      value: rawMgKg,
      priorityLabel: interpretation.label,
      stageKey: stageId,
      stageLabelEs: stageLabelEs,
      demandWindowLabelEs:
          treeCriticalWindowLabel(stageId) ?? interpretation.demandWindowLabel,
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

  /// Salud (0..1) para una etiqueta. "Alto útil" (`possibleExcess`) se trata
  /// como sano (1.0): en árbol estar alto no penaliza el ring.
  static double _treeHealthForLabel(
    NutrientPriorityLabel label,
    double stagePressure01,
  ) {
    if (label == NutrientPriorityLabel.possibleExcess) return 1.0;
    return label
        .healthScore01(stagePressure01: stagePressure01)
        .clamp(0.0, 1.0);
  }

  static double _treeNutrientHealthScore(AgroMetricEval metric) {
    final label = metric.priorityLabel;
    if (label == null) return metric.score01.clamp(0.0, 1.0);
    return _treeHealthForLabel(label, metric.stagePressure01 ?? 0.0);
  }

  static double _treeNutrientSeverityScore(AgroMetricEval metric) {
    final label = metric.priorityLabel;
    if (label == null) return 0.0;
    if (label == NutrientPriorityLabel.possibleExcess) return 0.0;
    return label.severityScore01(
      stagePressure01: metric.stagePressure01 ?? 0.0,
    );
  }

  /// Factor de penalización del score por etiqueta de nutriente (árbol).
  /// "Alto útil" = 1.0 (sin penalización); "Exceso" real sí penaliza.
  static double _treeNutrientPenaltyFactor(NutrientPriorityLabel? label) {
    if (label == null) return 1.0;
    switch (label) {
      case NutrientPriorityLabel.actionRecommended:
        return 0.78;
      case NutrientPriorityLabel.reviewAccumulation:
        return 0.82;
      case NutrientPriorityLabel.reviewManagement:
        return 0.86;
      case NutrientPriorityLabel.highPriority:
        return 0.90;
      case NutrientPriorityLabel.mediumPriority:
        return 0.96;
      case NutrientPriorityLabel.possibleExcess:
      case NutrientPriorityLabel.lowPriority:
      case NutrientPriorityLabel.noPriority:
      case NutrientPriorityLabel.unknown:
        return 1.0;
    }
  }

  static void _pushNutrientSuggestedKey(
    List<String> out,
    String key,
    NutrientPriorityLabel? label,
  ) {
    if (label == null) return;
    switch (label) {
      case NutrientPriorityLabel.actionRecommended:
        out.add('$key.action');
        return;
      case NutrientPriorityLabel.highPriority:
        out.add('$key.high_priority');
        return;
      case NutrientPriorityLabel.reviewManagement:
        out.add('$key.review');
        return;
      case NutrientPriorityLabel.reviewAccumulation:
        out.add('$key.review_accumulation');
        return;
      case NutrientPriorityLabel.possibleExcess:
      case NutrientPriorityLabel.mediumPriority:
      case NutrientPriorityLabel.lowPriority:
      case NutrientPriorityLabel.noPriority:
      case NutrientPriorityLabel.unknown:
        return;
    }
  }

  static void _pushSoilSuggestedKey(
    List<String> out,
    String key,
    AgroBand band,
    String stage,
  ) {
    if (band == AgroBand.critical) {
      out.add('tree.$stage.$key.critical');
    } else if (band == AgroBand.low) {
      out.add('tree.$stage.$key.low');
    } else if (band == AgroBand.high) {
      out.add('tree.$stage.$key.high');
    }
  }

  // ===========================================================================
  // SUELO — bandas por AgroRange con zonas documentales del árbol
  // ===========================================================================
  static AgroMetricEval _wrapLegacy(_Eval e, {required double displayValue}) {
    return AgroMetricEval(
      band: e.band,
      score01: e.score01,
      labelEs: e.band.labelEs,
      value: displayValue,
    );
  }

  static _Eval _evalTreeSoilMetric({
    required AgroMetricKey metricKey,
    required double value,
    required AgroRange range,
  }) {
    if (!value.isFinite || value.isNaN) {
      return const _Eval(
        band: AgroBand.unknown,
        score01: 0.0,
        zone: _TreeRangeZone.unknown,
      );
    }

    switch (metricKey) {
      case AgroMetricKey.soilMoisture:
        return _evalBilateralMetric(
          value: value,
          optimalMin: range.optimalMin,
          optimalMax: range.optimalMax,
          criticalLow: range.lowMax,
          criticalHigh: range.highMin,
          publicCriticalHigh: false,
        );
      case AgroMetricKey.soilTemp:
      case AgroMetricKey.ph:
        return _evalBilateralMetric(
          value: value,
          optimalMin: range.optimalMin,
          optimalMax: range.optimalMax,
          criticalLow: range.lowMax,
          criticalHigh: range.highMin,
        );
      case AgroMetricKey.ec:
      case AgroMetricKey.resistance:
        return _evalHighOnlyMetric(
          value: value,
          optimalMax: range.optimalMax,
          criticalHigh: range.highMin,
        );
      case AgroMetricKey.n:
      case AgroMetricKey.p:
      case AgroMetricKey.k:
        return _evalLegacyRange(value: value, range: range);
    }
  }

  static _Eval _evalBilateralMetric({
    required double value,
    required double optimalMin,
    required double optimalMax,
    required double criticalLow,
    required double criticalHigh,
    bool publicCriticalHigh = true,
  }) {
    final optMin = math.min(optimalMin, optimalMax);
    final optMax = math.max(optimalMin, optimalMax);
    final lowCritical = math.min(criticalLow, optMin);
    final highCritical = math.max(criticalHigh, optMax);

    if (value < lowCritical) {
      return _Eval(
        band: AgroBand.critical,
        score01: _scoreCriticalLow(value, lowCritical, optMin),
        zone: _TreeRangeZone.criticalLow,
      );
    }
    if (value < optMin) {
      return _Eval(
        band: AgroBand.low,
        score01: _scoreSoftLow(value, lowCritical, optMin),
        zone: _TreeRangeZone.low,
      );
    }
    if (value <= optMax) {
      return const _Eval(
        band: AgroBand.optimal,
        score01: 1.0,
        zone: _TreeRangeZone.optimal,
      );
    }
    if (value <= highCritical) {
      return _Eval(
        band: AgroBand.high,
        score01: _scoreSoftHigh(value, optMax, highCritical),
        zone: _TreeRangeZone.high,
      );
    }

    return _Eval(
      band: publicCriticalHigh ? AgroBand.critical : AgroBand.high,
      score01: _scoreCriticalHigh(value, highCritical, optMax),
      zone: _TreeRangeZone.criticalHigh,
    );
  }

  static _Eval _evalHighOnlyMetric({
    required double value,
    required double optimalMax,
    required double criticalHigh,
  }) {
    final optMax = math.max(0.0, optimalMax);
    final highCritical = math.max(criticalHigh, optMax);

    if (value <= optMax) {
      return const _Eval(
        band: AgroBand.optimal,
        score01: 1.0,
        zone: _TreeRangeZone.optimal,
      );
    }
    if (value <= highCritical) {
      final score = _lerp(0.90, 0.55, _invLerp(optMax, highCritical, value));
      return _Eval(
        band: AgroBand.high,
        score01: score.clamp(0.0, 1.0),
        zone: _TreeRangeZone.high,
      );
    }

    return _Eval(
      band: AgroBand.critical,
      score01: _scoreCriticalHigh(value, highCritical, optMax),
      zone: _TreeRangeZone.criticalHigh,
    );
  }

  static _Eval _evalLegacyRange({
    required double value,
    required AgroRange range,
  }) {
    if (!value.isFinite || value.isNaN) {
      return const _Eval(
        band: AgroBand.unknown,
        score01: 0.0,
        zone: _TreeRangeZone.unknown,
      );
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

    final score01 = _scoreFromLegacyRange(
      value,
      lowMax,
      optMin,
      optMax,
      highMin,
    );
    final zone = switch (band) {
      AgroBand.critical when value < lowMax => _TreeRangeZone.criticalLow,
      AgroBand.critical => _TreeRangeZone.criticalHigh,
      AgroBand.low => _TreeRangeZone.low,
      AgroBand.optimal => _TreeRangeZone.optimal,
      AgroBand.high => _TreeRangeZone.high,
      AgroBand.unknown => _TreeRangeZone.unknown,
    };
    return _Eval(band: band, score01: score01, zone: zone);
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

  static double _scoreSoftLow(double v, double criticalLow, double optMin) {
    if ((optMin - criticalLow).abs() < 1e-9) return 0.75;
    return _lerp(0.60, 0.95, _invLerp(criticalLow, optMin, v));
  }

  static double _scoreSoftHigh(double v, double optMax, double criticalHigh) {
    if ((criticalHigh - optMax).abs() < 1e-9) return 0.75;
    return _lerp(0.95, 0.60, _invLerp(optMax, criticalHigh, v));
  }

  static double _scoreCriticalLow(double v, double criticalLow, double optMin) {
    final span = math.max(1.0, (optMin - criticalLow).abs());
    final d = (criticalLow - v) / span;
    return (0.35 / (1 + d)).clamp(0.05, 0.35);
  }

  static double _scoreCriticalHigh(
    double v,
    double criticalHigh,
    double optMax,
  ) {
    final span = math.max(1.0, (criticalHigh - optMax).abs());
    final d = (v - criticalHigh) / span;
    return (0.35 / (1 + d)).clamp(0.05, 0.35);
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

  // ===========================================================================
  // ALERTAS POR ETAPA — lenguaje genérico de árbol perenne
  // ===========================================================================
  static AlertsBuildResult _buildTreeAlerts({
    required BioGTelemetry telemetry,
    required String stageId,
    required Map<AgroMetricKey, AgroMetricEval> metrics,
    required AlertsState alertsState,
    required Duration cooldown,
  }) {
    final nextMap = Map<BioGAlertType, DateTime>.from(alertsState.lastByType);
    final alerts = <BioGAlert>[];
    final now = telemetry.timestamp;

    void push({
      required BioGAlertType type,
      required BioGAlertSeverity severity,
      required String title,
      required String body,
    }) {
      final last = nextMap[type];
      if (last != null && now.difference(last) < cooldown) return;

      alerts.add(
        BioGAlert(
          id: '${telemetry.deviceId}_${type.name}_${now.millisecondsSinceEpoch}',
          deviceId: telemetry.deviceId,
          type: type,
          severity: severity,
          title: title,
          body: body,
          timestamp: now,
        ),
      );
      nextMap[type] = now;
    }

    final moisture = metrics[AgroMetricKey.soilMoisture]?.band;
    final resistance = metrics[AgroMetricKey.resistance]?.band;
    final soilTemp = metrics[AgroMetricKey.soilTemp]?.band;
    final ec = metrics[AgroMetricKey.ec]?.band;
    final nutrientLow =
        <AgroMetricKey>[AgroMetricKey.n, AgroMetricKey.p, AgroMetricKey.k].any(
          (key) =>
              metrics[key]?.band == AgroBand.low ||
              metrics[key]?.band == AgroBand.critical,
        );

    final moistureLow =
        moisture == AgroBand.low || moisture == AgroBand.critical;
    final moistureHigh =
        moisture == AgroBand.high || moisture == AgroBand.critical;
    final heat =
        telemetry.airTempC >= 35 ||
        soilTemp == AgroBand.high ||
        soilTemp == AgroBand.critical;
    final cold = telemetry.airTempC <= 4;
    final highHumidity = telemetry.airHumidityPct >= 85;
    final salinityHigh = ec == AgroBand.high || ec == AgroBand.critical;
    final moistureValue =
        metrics[AgroMetricKey.soilMoisture]?.value ?? telemetry.soilMoisturePct;
    final moistureLikelySaturated =
        moisture == AgroBand.high ||
        (moisture == AgroBand.critical && moistureValue >= 80);
    final moistureLikelyDry =
        moisture == AgroBand.low ||
        (moisture == AgroBand.critical && !moistureLikelySaturated);
    final compactionHigh =
        resistance == AgroBand.high || resistance == AgroBand.critical;
    final soilTempStress =
        soilTemp == AgroBand.critical ||
        telemetry.soilTempC <= 12 ||
        telemetry.soilTempC >= 30;
    final nLabel = metrics[AgroMetricKey.n]?.priorityLabel;
    final kLabel = metrics[AgroMetricKey.k]?.priorityLabel;

    switch (stageId) {
      case TreeStageIds.plantingTransplant:
        if (moistureLikelySaturated) {
          push(
            type: BioGAlertType.highSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Humedad alta en plantación',
            body:
                'En plantación, prioriza raíz y oxígeno. Si hay saturación, no empujes más riego; revisa drenaje y estabilidad del suelo.',
          );
        } else if (moistureLikelyDry) {
          push(
            type: BioGAlertType.lowSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Humedad baja en plantación',
            body:
                'El árbol recién colocado necesita humedad estable. Evita déficit real mientras la raíz empieza a explorar el suelo.',
          );
        }
        if (salinityHigh) {
          push(
            type: BioGAlertType.ecOutOfRange,
            severity: BioGAlertSeverity.warning,
            title: 'Sales altas en plantación',
            body:
                'BioG detecta sales altas en plantación. Evita fertilizar fuerte: prioriza riego parejo y que el árbol agarre raíz.',
          );
        }
        if (compactionHigh || soilTempStress) {
          push(
            type: BioGAlertType.stageEvent,
            severity: BioGAlertSeverity.warning,
            title: 'Raíz con arranque limitado',
            body:
                'En plantación, si el suelo está duro o fuera de rango, el fertilizante rinde poco. Mantén riego parejo y evita dosis fuertes hasta que el árbol agarre.',
          );
        }
        break;
      case TreeStageIds.budbreak:
        if (cold) {
          push(
            type: BioGAlertType.airTempExtreme,
            severity: telemetry.airTempC <= 0
                ? BioGAlertSeverity.critical
                : BioGAlertSeverity.warning,
            title: 'Riesgo de helada en brotación',
            body:
                'Revisa riesgo de helada tardía si hay brotes tiernos. Confirma en campo antes de tomar decisiones fuertes.',
          );
        }
        if (moistureLikelyDry) {
          push(
            type: BioGAlertType.lowSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Humedad baja en brotación',
            body:
                'BioG detecta poca humedad en brotación. Mantén riego parejo: con suelo seco el árbol toma peor NPK.',
          );
        }
        if (salinityHigh) {
          push(
            type: BioGAlertType.ecOutOfRange,
            severity: BioGAlertSeverity.warning,
            title: 'Sales altas en brotación',
            body:
                'BioG detecta sales altas en brotación. Evita meter más fertilizante hasta que baje: el árbol puede absorber peor NPK.',
          );
        }
        if (compactionHigh || soilTempStress) {
          push(
            type: BioGAlertType.stageEvent,
            severity: BioGAlertSeverity.warning,
            title: 'Brotación con raíz lenta',
            body:
                'El suelo puede estar frenando la absorción. Mantén humedad pareja y evita correcciones fuertes de NPK hasta que el árbol responda.',
          );
        } else if (nLabel == NutrientPriorityLabel.reviewAccumulation) {
          push(
            type: BioGAlertType.stageEvent,
            severity: BioGAlertSeverity.warning,
            title: 'N alto en brotación',
            body:
                'BioG detecta N alto al arrancar brotación. No apliques más N por ahora: puede empujar brotes tiernos y sombra de más.',
          );
        }
        break;
      case TreeStageIds.rootEstablishment:
        if (moistureLow) {
          push(
            type: BioGAlertType.lowSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Humedad baja en establecimiento',
            body:
                'El arbol esta en establecimiento. Manten humedad estable y evita secados fuertes mientras forma raiz.',
          );
        } else if (moistureHigh) {
          push(
            type: BioGAlertType.highSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Exceso de humedad en establecimiento',
            body:
                'Exceso de humedad en establecimiento. Revisa drenaje y evita saturacion del suelo.',
          );
        }
        if (resistance == AgroBand.high || resistance == AgroBand.critical) {
          push(
            type: BioGAlertType.stageEvent,
            severity: BioGAlertSeverity.warning,
            title: 'Raiz con suelo resistente',
            body:
                'El arbol esta en establecimiento. Suelo muy resistente puede limitar raiz; revisa compactacion sin hacer labores agresivas junto al tronco.',
          );
        }
        break;
      case TreeStageIds.flowering:
        if (cold) {
          push(
            type: BioGAlertType.airTempExtreme,
            severity: telemetry.airTempC <= 0
                ? BioGAlertSeverity.critical
                : BioGAlertSeverity.warning,
            title: 'Riesgo de estres durante floracion',
            body:
                'Floracion activa: temperatura baja o helada puede afectar la produccion de la temporada.',
          );
        }
        if (moistureLow) {
          push(
            type: BioGAlertType.lowSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Deficit hidrico en floracion',
            body:
                'Floracion activa: pequenas desviaciones pueden afectar la produccion de la temporada. Revisa humedad y riego.',
          );
        }
        if (highHumidity) {
          push(
            type: BioGAlertType.highHumidity,
            severity: BioGAlertSeverity.warning,
            title: 'Humedad alta durante floracion',
            body:
                'Humedad ambiental elevada durante floracion. Revisa el arbol y manten monitoreo.',
          );
        }
        break;
      case TreeStageIds.fruitSet:
        if (moistureLow) {
          push(
            type: BioGAlertType.lowSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Deficit hidrico en cuajado',
            body:
                'Cuajado activo: evita estres hidrico o termico. Esta etapa tiene poca tolerancia al estres.',
          );
        }
        if (heat) {
          push(
            type: BioGAlertType.airTempExtreme,
            severity: BioGAlertSeverity.warning,
            title: 'Calor durante cuajado',
            body:
                'Cuajado activo: el calor puede aumentar estres. Manten humedad estable y revisa el arbol.',
          );
        }
        if (salinityHigh) {
          push(
            type: BioGAlertType.ecOutOfRange,
            severity: BioGAlertSeverity.warning,
            title: 'Sales altas en cuajado',
            body:
                'Cuajado activo: BioG detecta sales altas. Evita más fertilizante y mantén riego parejo.',
          );
        }
        break;
      case TreeStageIds.fruitFill:
        if (moistureLow || heat) {
          push(
            type: moistureLow
                ? BioGAlertType.lowSoilMoisture
                : BioGAlertType.airTempExtreme,
            severity: BioGAlertSeverity.warning,
            title: 'Estres en llenado de fruto',
            body:
                'Llenado de fruto: el arbol necesita estabilidad para sostener calidad y tamano.',
          );
        }
        break;
      case TreeStageIds.harvestMaturity:
        if (nLabel == NutrientPriorityLabel.reviewAccumulation) {
          push(
            type: BioGAlertType.stageEvent,
            severity: BioGAlertSeverity.warning,
            title: 'N alto cerca de madurez',
            body:
                'BioG detecta N alto cerca de cosecha. Frena N: puede retrasar color, bajar firmeza y afectar la calidad del fruto.',
          );
        } else if (kLabel == NutrientPriorityLabel.reviewAccumulation) {
          push(
            type: BioGAlertType.stageEvent,
            severity: BioGAlertSeverity.warning,
            title: 'K alto cerca de cosecha',
            body:
                'BioG detecta K alto. No subas más potasio por ahora: puede subir sales y desbalancear firmeza del fruto.',
          );
        }
        if (salinityHigh) {
          push(
            type: BioGAlertType.ecOutOfRange,
            severity: BioGAlertSeverity.warning,
            title: 'Sales antes de cosecha',
            body:
                'BioG detecta sales altas antes de cosecha. Evita más fertilizante y mantén riego parejo para cuidar calidad.',
          );
        }
        if (moistureLikelyDry || moistureLikelySaturated) {
          push(
            type: moistureLikelyDry
                ? BioGAlertType.lowSoilMoisture
                : BioGAlertType.highSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Humedad extrema antes de cosecha',
            body:
                'La humedad viene fuera de rango antes de cosecha. Corrige riego con cuidado: los cambios bruscos bajan firmeza y calidad.',
          );
        }
        if (heat) {
          push(
            type: BioGAlertType.airTempExtreme,
            severity: BioGAlertSeverity.warning,
            title: 'Calor en madurez',
            body:
                'Calor fuerte cerca de cosecha. Mantén riego parejo y revisa color/firmeza: el fruto puede perder calidad rápido.',
          );
        }
        break;
      case TreeStageIds.postHarvest:
        if (moistureLow || nutrientLow) {
          push(
            type: moistureLow
                ? BioGAlertType.lowSoilMoisture
                : BioGAlertType.stageEvent,
            severity: BioGAlertSeverity.warning,
            title: 'Post-cosecha con estres',
            body:
                'Post-cosecha: el árbol repone fuerza para el siguiente ciclo. Mantén riego parejo y corrige NPK solo si BioG lo mantiene bajo.',
          );
        }
        break;
      case TreeStageIds.dormancy:
        if (moisture == AgroBand.critical || soilTemp == AgroBand.critical) {
          push(
            type: BioGAlertType.stageEvent,
            severity: BioGAlertSeverity.warning,
            title: 'Extremo durante reposo',
            body:
                'Reposo del árbol. No fuerces fertilización; actúa solo si humedad, frío o sales se mantienen en extremo.',
          );
        }
        break;
      default:
        break;
    }

    if (salinityHigh && moistureLikelyDry) {
      push(
        type: BioGAlertType.ecOutOfRange,
        severity: ec == AgroBand.critical
            ? BioGAlertSeverity.critical
            : BioGAlertSeverity.warning,
        title: 'Riesgo salino con humedad baja',
        body:
            'Sales altas con suelo seco estresan al árbol. Estabiliza humedad antes de corregir NPK fuerte.',
      );
    }

    return AlertsBuildResult(
      alerts: List<BioGAlert>.unmodifiable(alerts),
      state: alertsState.copyWith(lastByType: nextMap),
    );
  }
}

class _Eval {
  const _Eval({required this.band, required this.score01, required this.zone});

  final AgroBand band;
  final double score01;
  final _TreeRangeZone zone;

  bool get isCritical =>
      zone == _TreeRangeZone.criticalLow || zone == _TreeRangeZone.criticalHigh;

  bool get isCriticalLow => zone == _TreeRangeZone.criticalLow;

  bool get isCriticalHigh => zone == _TreeRangeZone.criticalHigh;
}

enum _TreeRangeZone { criticalLow, low, optimal, high, criticalHigh, unknown }
