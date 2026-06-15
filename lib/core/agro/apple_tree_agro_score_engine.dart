import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/apple_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Motor AgroScore del Manzano — espejo de [BeanAgroScoreEngine] pero para el
/// ciclo perenne del árbol.
///
/// Arquitectura: el manzano es un cultivo de PRIMERA CLASE dentro del mismo
/// pipeline que los granos:
/// - Suelo (humedad, temp, pH, EC, resistencia) → bandas por [AgroRange]
///   (lógica `_evalLegacy`, idéntica a bean).
/// - N/P/K → [NutrientRecommendationEngine.interpret] con `cropKey: apple_tree`,
///   targets/weights del perfil universal y el `AppleTreeNutritionModifier`.
///
/// DECISIÓN DEL MANZANO (alto útil vs exceso):
/// - "Alto útil" (`possibleExcess`, entre óptimo y `highMin`) NO penaliza el
///   score ni alerta: en manzano estar alto no es malo.
/// - "Exceso" real (`reviewAccumulation`, ≥ `highMin`) SÍ baja el score y avisa.
/// - El N en EXCESO en llenado/madurez recibe penalización EXTRA, mayor en
///   AP-02 Red y AP-04 Gala (color/calidad), vía el modificador.
class AppleTreeAgroScoreEngine {
  const AppleTreeAgroScoreEngine._();

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
    final modifier = resolveAppleTreeNutritionModifier(
      profileId: profileId,
      varietyId: varietyId,
      alias: varietyAlias,
    );

    final moisture01 = _normalizeMoisture01(t.soilMoisturePct, cal);
    final moistureRawCal = moisture01 * 100.0;

    final moistureEval = _evalLegacy(value: moistureRawCal, range: targets.moistureRaw);
    final soilTempEval = _evalLegacy(value: t.soilTempC, range: targets.soilTemp);
    final phEval = _evalLegacy(value: t.ph, range: targets.ph);
    final ecEval = _evalLegacy(value: t.ec, range: targets.ec);
    final resEval = _evalLegacy(value: t.resistance, range: targets.resistance);

    final nMetric = _interpretAppleNutrient(
      metricKey: AgroMetricKey.n,
      rawMgKg: t.n.toDouble(),
      hasData: t.hasNitrogenData,
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
    final pMetric = _interpretAppleNutrient(
      metricKey: AgroMetricKey.p,
      rawMgKg: t.p.toDouble(),
      hasData: t.hasPhosphorusData,
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
    final kMetric = _interpretAppleNutrient(
      metricKey: AgroMetricKey.k,
      rawMgKg: t.k.toDouble(),
      hasData: t.hasPotassiumData,
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
      AgroMetricKey.soilMoisture: _wrapLegacy(moistureEval, displayValue: moistureRawCal),
      AgroMetricKey.soilTemp: _wrapLegacy(soilTempEval, displayValue: t.soilTempC),
      AgroMetricKey.ph: _wrapLegacy(phEval, displayValue: t.ph),
      AgroMetricKey.ec: _wrapLegacy(ecEval, displayValue: t.ec),
      AgroMetricKey.resistance: _wrapLegacy(resEval, displayValue: t.resistance),
      AgroMetricKey.n: nMetric,
      AgroMetricKey.p: pMetric,
      AgroMetricKey.k: kMetric,
    };

    final nHealthScore = _appleNutrientHealthScore(nMetric);
    final pHealthScore = _appleNutrientHealthScore(pMetric);
    final kHealthScore = _appleNutrientHealthScore(kMetric);

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
    if (moistureEval.band == AgroBand.critical) criticalPenalty *= 0.45;
    if (soilTempEval.band == AgroBand.critical) criticalPenalty *= 0.50;
    if (phEval.band == AgroBand.critical) criticalPenalty *= 0.45;
    if (ecEval.band == AgroBand.critical) criticalPenalty *= 0.65;
    if (resEval.band == AgroBand.critical) criticalPenalty *= 0.85;
    criticalPenalty *= _appleNutrientPenaltyFactor(nMetric.priorityLabel);
    criticalPenalty *= _appleNutrientPenaltyFactor(pMetric.priorityLabel);
    criticalPenalty *= _appleNutrientPenaltyFactor(kMetric.priorityLabel);

    // Penalización EXTRA por N en EXCESO real tardío (llenado/madurez); mayor en
    // variedades sensibles a color/calidad (AP-02 Red, AP-04 Gala) — doc 05 §3.4.
    if (nMetric.priorityLabel == NutrientPriorityLabel.reviewAccumulation) {
      criticalPenalty *= modifier.lateNitrogenExcessPenaltyFactor(stage);
    }

    final soilControlScore01 = (rawSoilControlScore * criticalPenalty).clamp(0.0, 1.0);

    final nutrientWeightSum = math.max(
      0.0001,
      weights.nutrientN + weights.nutrientP + weights.nutrientK,
    );
    final nutrientPriorityScore01 =
        ((weights.nutrientN * _appleNutrientSeverityScore(nMetric)) +
                (weights.nutrientP * _appleNutrientSeverityScore(pMetric)) +
                (weights.nutrientK * _appleNutrientSeverityScore(kMetric))) /
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
  static AgroMetricEval _interpretAppleNutrient({
    required AgroMetricKey metricKey,
    required double rawMgKg,
    required bool hasData,
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
            treeCriticalWindowLabel(stageId) ?? targets.windowLabelFor(metricKey),
      );
    }

    final interpretation = NutrientRecommendationEngine.interpret(
      nutrient: metricKey,
      rawPpm: rawMgKg,
      cropKey: 'apple_tree',
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
      // Banda derivada de la MISMA etiqueta que ve el detalle NPK → ring y
      // detalle coinciden siempre.
      band: interpretation.label.agroBand,
      score01: _appleHealthForLabel(
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
  /// como sano (1.0): en manzano estar alto no penaliza el ring.
  static double _appleHealthForLabel(
    NutrientPriorityLabel label,
    double stagePressure01,
  ) {
    if (label == NutrientPriorityLabel.possibleExcess) return 1.0;
    return label.healthScore01(stagePressure01: stagePressure01).clamp(0.0, 1.0);
  }

  static double _appleNutrientHealthScore(AgroMetricEval metric) {
    final label = metric.priorityLabel;
    if (label == null) return metric.score01.clamp(0.0, 1.0);
    return _appleHealthForLabel(label, metric.stagePressure01 ?? 0.0);
  }

  static double _appleNutrientSeverityScore(AgroMetricEval metric) {
    final label = metric.priorityLabel;
    if (label == null) return 0.0;
    // "Alto útil" no aporta urgencia: severidad 0.
    if (label == NutrientPriorityLabel.possibleExcess) return 0.0;
    return label.severityScore01(stagePressure01: metric.stagePressure01 ?? 0.0);
  }

  /// Factor de penalización del score por etiqueta de nutriente (manzano).
  /// "Alto útil" = 1.0 (sin penalización); "Exceso" real sí penaliza.
  static double _appleNutrientPenaltyFactor(NutrientPriorityLabel? label) {
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
      // "Alto útil" (possibleExcess) y prioridades suaves NO generan aviso.
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
  // SUELO — bandas por AgroRange (idéntico a bean)
  // ===========================================================================
  static AgroMetricEval _wrapLegacy(_Eval e, {required double displayValue}) {
    return AgroMetricEval(
      band: e.band,
      score01: e.score01,
      labelEs: e.band.labelEs,
      value: displayValue,
    );
  }

  static _Eval _evalLegacy({required double value, required AgroRange range}) {
    if (!value.isFinite || value.isNaN) {
      return _Eval(band: AgroBand.unknown, score01: 0.0);
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

    final score01 = _scoreFromLegacyRange(value, lowMax, optMin, optMax, highMin);
    return _Eval(band: band, score01: score01);
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
  // ALERTAS POR ETAPA — portadas desde AppleTreeCropDefinition (cobertura igual)
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

    final moistureLow = moisture == AgroBand.low || moisture == AgroBand.critical;
    final moistureHigh =
        moisture == AgroBand.high || moisture == AgroBand.critical;
    final heat =
        telemetry.airTempC >= 35 ||
        soilTemp == AgroBand.high ||
        soilTemp == AgroBand.critical;
    final cold = telemetry.airTempC <= 4;
    final highHumidity = telemetry.airHumidityPct >= 85;
    final salinityHigh = ec == AgroBand.high || ec == AgroBand.critical;

    switch (stageId) {
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
            title: 'Salinidad alta en cuajado',
            body:
                'Cuajado activo: revisa CE y acumulacion de sales si la lectura se mantiene alta.',
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
      case TreeStageIds.postHarvest:
        if (moistureLow || nutrientLow) {
          push(
            type: moistureLow
                ? BioGAlertType.lowSoilMoisture
                : BioGAlertType.stageEvent,
            severity: BioGAlertSeverity.warning,
            title: 'Post-cosecha con estres',
            body:
                'Post-cosecha: el arbol recupera reservas para el siguiente ciclo. Manten monitoreo y evita estres sostenido.',
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
                'Reposo: monitoreo pasivo del arbol. Solo conviene actuar si las lecturas extremas se mantienen.',
          );
        }
        break;
      default:
        break;
    }

    return AlertsBuildResult(
      alerts: List<BioGAlert>.unmodifiable(alerts),
      state: alertsState.copyWith(lastByType: nextMap),
    );
  }
}

class _Eval {
  const _Eval({required this.band, required this.score01});

  final AgroBand band;
  final double score01;
}
