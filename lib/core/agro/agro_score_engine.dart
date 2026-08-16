// lib/core/agro/agro_score_engine.dart
import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/crops/maize/maize_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class AgroScoreEngine {
  /// Etapas críticas de maíz para severity bump en alertas.
  static const Set<MaizeStageKey> _criticalStages = {MaizeStageKey.flowerSet};

  static const Set<MaizeStageKey> _semiCriticalStages = {
    MaizeStageKey.tasseling,
  };

  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateMaize({
    required BioGTelemetry t,
    required SeedStageResult stage,
    required MaizeUniversalProfile u,
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

    final soilTemp = t.soilTempC;
    final ph = t.ph;
    final ec = t.ec;
    final resistanceMpa = t.resistance;

    final nRaw = t.n.toDouble();
    final pRaw = t.p.toDouble();
    final kRaw = t.k.toDouble();

    final moistureEval = _evalLegacy(
      value: moistureRawCal,
      range: targets.moistureRaw,
    );
    final soilTempEval = _evalLegacy(value: soilTemp, range: targets.soilTemp);
    final phEval = _evalLegacy(value: ph, range: targets.ph);
    final ecEval = _evalLegacy(value: ec, range: targets.ec);
    final resEval = _evalLegacy(
      value: resistanceMpa,
      range: targets.resistance,
    );

    final nMetric = _interpretMaizeNutrient(
      metricKey: AgroMetricKey.n,
      hasData: t.hasNitrogenData,
      rawMgKg: nRaw,
      stageKey: stageKey,
      targets: targets,
      weights: weights,
      ph: ph,
      ec: ec,
      soilMoisturePct: t.hasSoilMoistureData ? t.soilMoisturePct : null,
    );

    final pMetric = _interpretMaizeNutrient(
      metricKey: AgroMetricKey.p,
      rawMgKg: pRaw,
      hasData: t.hasPhosphorusData,
      stageKey: stageKey,
      targets: targets,
      weights: weights,
      ph: ph,
      ec: ec,
      soilMoisturePct: t.hasSoilMoistureData ? t.soilMoisturePct : null,
    );

    final kMetric = _interpretMaizeNutrient(
      metricKey: AgroMetricKey.k,
      rawMgKg: kRaw,
      hasData: t.hasPotassiumData,
      stageKey: stageKey,
      targets: targets,
      weights: weights,
      ph: ph,
      ec: ec,
      soilMoisturePct: t.hasSoilMoistureData ? t.soilMoisturePct : null,
    );

    final metrics = <AgroMetricKey, AgroMetricEval>{
      AgroMetricKey.soilMoisture: _wrapLegacy(
        moistureEval,
        displayValue: moistureRawCal,
      ),
      AgroMetricKey.soilTemp: _wrapLegacy(soilTempEval, displayValue: soilTemp),
      AgroMetricKey.ph: _wrapLegacy(phEval, displayValue: ph),
      AgroMetricKey.ec: _wrapLegacy(ecEval, displayValue: ec),
      AgroMetricKey.resistance: _wrapLegacy(
        resEval,
        displayValue: resistanceMpa,
      ),
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

    double criticalPenalty = 1.0;
    if (moistureEval.band == AgroBand.critical) criticalPenalty *= 0.45;
    if (soilTempEval.band == AgroBand.critical) criticalPenalty *= 0.50;
    if (phEval.band == AgroBand.critical) criticalPenalty *= 0.45;
    if (ecEval.band == AgroBand.critical) criticalPenalty *= 0.65;
    if (resEval.band == AgroBand.critical) criticalPenalty *= 0.85;
    criticalPenalty *= _nutrientPenaltyFactor(nMetric.priorityLabel);
    criticalPenalty *= _nutrientPenaltyFactor(pMetric.priorityLabel);
    criticalPenalty *= _nutrientPenaltyFactor(kMetric.priorityLabel);

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

    final suggested = <String>[];

    _pushLegacyAlertsForMetric(
      suggested,
      'soilMoisture',
      moistureEval,
      stageKey,
    );
    _pushLegacyAlertsForMetric(suggested, 'soilTemp', soilTempEval, stageKey);
    _pushLegacyAlertsForMetric(suggested, 'ph', phEval, stageKey);
    _pushLegacyAlertsForMetric(suggested, 'ec', ecEval, stageKey);
    _pushLegacyAlertsForMetric(suggested, 'resistance', resEval, stageKey);

    _pushNutrientAlertsForMetric(suggested, 'npk.n', nMetric, stageKey);
    _pushNutrientAlertsForMetric(suggested, 'npk.p', pMetric, stageKey);
    _pushNutrientAlertsForMetric(suggested, 'npk.k', kMetric, stageKey);

    _pushEnvironmentalAlerts(suggested, t, stageKey);

    final int severityBump = _criticalStages.contains(stageKey)
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
      stageLabel: _stageLabelEs(stageKey),
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
    return label.severityScore01(
      stagePressure01: metric.stagePressure01 ?? 0.0,
    );
  }

  static double _nutrientHealthScore(AgroMetricEval metric) {
    final label = metric.priorityLabel;
    if (label == null) return metric.score01.clamp(0.0, 1.0);
    return label.healthScore01(stagePressure01: metric.stagePressure01 ?? 0.0);
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

    final score01 = _scoreFromLegacyRange(
      value,
      lowMax,
      optMin,
      optMax,
      highMin,
    );

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
    } else {
      final span = math.max(1e-6, (highMin - optMax).abs());
      final d = (v - highMin) / span;
      return (0.35 / (1 + d)).clamp(0.05, 0.35);
    }
  }

  static AgroMetricEval _interpretMaizeNutrient({
    required AgroMetricKey metricKey,
    required double rawMgKg,
    required bool hasData,
    required MaizeStageKey stageKey,
    required StageTargets targets,
    required StageWeights weights,
    required double ph,
    required double ec,
    // Nullable: sin sonda de humedad se pasa null, y el motor nutrimental ya lo
    // acepta. Los motores hermanos ya lo declaraban así; este se quedó atrás.
    required double? soilMoisturePct,
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
        stageKey: stageKey.name,
        stageLabelEs: _stageLabelEs(stageKey),
        demandWindowLabelEs: targets.windowLabelFor(metricKey),
      );
    }

    final interpretation = NutrientRecommendationEngine.interpret(
      nutrient: metricKey,
      rawPpm: rawMgKg,
      cropKey: 'maize',
        stageKey: stageKey.name,
      targets: targets,
      weights: weights,
      ph: ph,
      ec: ec,
      soilMoisturePct: soilMoisturePct,
      trendPct: null,
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

  static void _pushLegacyAlertsForMetric(
    List<String> out,
    String key,
    _Eval e,
    MaizeStageKey stage,
  ) {
    final isCriticalStage =
        _criticalStages.contains(stage) || _semiCriticalStages.contains(stage);

    if (e.band == AgroBand.critical) {
      out.add('$key.critical');
      return;
    }

    if (isCriticalStage && e.band == AgroBand.low) out.add('$key.low');
    if (isCriticalStage && e.band == AgroBand.high) out.add('$key.high');
  }

  static void _pushNutrientAlertsForMetric(
    List<String> out,
    String key,
    AgroMetricEval metric,
    MaizeStageKey stage,
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
    MaizeStageKey stage,
  ) {
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
    final isReproductive =
        _criticalStages.contains(stage) || _semiCriticalStages.contains(stage);

    if (airTemp <= 0) {
      out.add('airTemp.frost');
    } else if (airTemp < 4) {
      out.add('airTemp.cold');
    }

    if (airTemp > 40) {
      out.add('airTemp.extreme_heat');
    } else if (airTemp > 35 || (isReproductive && airTemp > 33)) {
      out.add('airTemp.heat');
    }

    if (airHum > 90) {
      out.add('airHumidity.critical');
    } else if (airHum > 80) {
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

  static String _stageLabelEs(MaizeStageKey stageKey) {
    switch (stageKey) {
      case MaizeStageKey.germination:
        return 'Germinación';
      case MaizeStageKey.emergence:
        return 'Emergencia';
      case MaizeStageKey.vegEarly:
        return 'Vegetativa temprana';
      case MaizeStageKey.vegMid:
        return 'Vegetativa media';
      case MaizeStageKey.vegAdvanced:
        return 'Vegetativa avanzada';
      case MaizeStageKey.tasseling:
        return 'Espigado';
      case MaizeStageKey.flowerSet:
        return 'Floración y cuajado';
      case MaizeStageKey.maturitySenescence:
        return 'Maduración / senescencia';
      case MaizeStageKey.harvest:
        return 'Cosecha';
    }
  }

  static bool _isEstablishmentStage(MaizeStageKey stageKey) {
    return stageKey == MaizeStageKey.germination ||
        stageKey == MaizeStageKey.emergence ||
        stageKey == MaizeStageKey.vegEarly;
  }

  static String _defaultDemandWindow(
    AgroMetricKey metricKey,
    MaizeStageKey stageKey,
  ) {
    switch (metricKey) {
      case AgroMetricKey.n:
        if (stageKey == MaizeStageKey.vegMid ||
            stageKey == MaizeStageKey.vegAdvanced ||
            stageKey == MaizeStageKey.tasseling ||
            stageKey == MaizeStageKey.flowerSet) {
          return 'Tramo fuerte de N (V6 a floración)';
        }
        if (_isEstablishmentStage(stageKey)) {
          return 'Base de arranque de N';
        }
        if (stageKey == MaizeStageKey.maturitySenescence) {
          return 'Cierre y trazabilidad de N';
        }
        return 'Seguimiento de N';

      case AgroMetricKey.p:
        if (_isEstablishmentStage(stageKey)) {
          return 'Arranque, raíces y energía';
        }
        if (stageKey == MaizeStageKey.vegMid ||
            stageKey == MaizeStageKey.vegAdvanced) {
          return 'Soporte de crecimiento';
        }
        return 'Balance de P';

      case AgroMetricKey.k:
        if (stageKey == MaizeStageKey.tasseling ||
            stageKey == MaizeStageKey.flowerSet ||
            stageKey == MaizeStageKey.maturitySenescence) {
          return 'Agua, tallo y balance';
        }
        return 'Balance fisiológico de K';

      default:
        return '';
    }
  }

  static String _defaultShortRecommendation({
    required AgroMetricKey metricKey,
    required NutrientPriorityLabel label,
  }) {
    final nutrientName = metricKey.labelEs.toLowerCase();

    switch (label) {
      case NutrientPriorityLabel.actionRecommended:
        return '¡Urge aplicar $nutrientName! El cultivo lo necesita ya.';
      case NutrientPriorityLabel.reviewManagement:
        return 'Revisa tu manejo de $nutrientName. Hay desajuste.';
      case NutrientPriorityLabel.highPriority:
        return 'El cultivo necesita $nutrientName. Conviene actuar.';
      case NutrientPriorityLabel.mediumPriority:
        return 'El nivel de $nutrientName empieza a bajar. Vigila.';
      case NutrientPriorityLabel.lowPriority:
        return 'Por ahora $nutrientName no es la prioridad.';
      case NutrientPriorityLabel.noPriority:
        return 'Todo bien con $nutrientName. Tierra nutrida.';
      case NutrientPriorityLabel.possibleExcess:
        return 'Frena la aplicación. Tienes $nutrientName de más.';
      case NutrientPriorityLabel.reviewAccumulation:
        return 'Exceso fuerte de $nutrientName. Podrías dañar el suelo.';
      case NutrientPriorityLabel.unknown:
        return 'Faltan datos para evaluar $nutrientName.';
    }
  }

  static String _defaultPracticalRecommendation({
    required NutrientPriorityLabel label,
    String? plannerHint,
  }) {
    if (plannerHint != null && plannerHint.trim().isNotEmpty) {
      return plannerHint;
    }

    switch (label) {
      case NutrientPriorityLabel.actionRecommended:
        return 'El cultivo necesita este nutriente ya. Conviene aplicar pronto para no perder rendimiento.';
      case NutrientPriorityLabel.reviewManagement:
        return 'Revisa tu plan de fertilización: algo no cuadra entre lo que aplicaste y lo que la planta está recibiendo.';
      case NutrientPriorityLabel.highPriority:
        return 'Conviene actuar. La planta va a necesitar más de este nutriente pronto.';
      case NutrientPriorityLabel.mediumPriority:
        return 'El nivel va bajando. Ve preparando la próxima aplicación para no quedarte corto.';
      case NutrientPriorityLabel.lowPriority:
        return 'Todo en orden por ahora. Sigue vigilando sin apresurarte a aplicar.';
      case NutrientPriorityLabel.noPriority:
        return 'Niveles bien. No apliques de más solo por costumbre: cuida tu bolsillo.';
      case NutrientPriorityLabel.possibleExcess:
        return 'Tienes de sobra. Frena la aplicación para no desbalancear el suelo.';
      case NutrientPriorityLabel.reviewAccumulation:
        return 'Niveles muy altos. Pausa el fertilizante y deja que la tierra se equilibre.';
      case NutrientPriorityLabel.unknown:
        return 'No hay datos suficientes para hacer una recomendación.';
    }
  }

  static String _defaultJustification({
    required AgroMetricKey metricKey,
    required MaizeStageKey stageKey,
  }) {
    switch (metricKey) {
      case AgroMetricKey.n:
        if (stageKey == MaizeStageKey.vegMid ||
            stageKey == MaizeStageKey.vegAdvanced ||
            stageKey == MaizeStageKey.tasseling ||
            stageKey == MaizeStageKey.flowerSet) {
          return 'En maíz, la captura de nitrógeno se acelera fuerte desde V6 y gana máximo peso alrededor de espigamiento y floración.';
        }
        if (_isEstablishmentStage(stageKey)) {
          return 'En arranque, el maíz usa solo una fracción menor del N total; la presión real sube conforme entra a V6 y prefloración.';
        }
        return 'En cierre de ciclo, el N se interpreta más como trazabilidad y aprendizaje del lote que como una corrección agresiva tardía.';

      case AgroMetricKey.p:
        if (_isEstablishmentStage(stageKey)) {
          return 'El fósforo pesa mucho al arranque por su relación con raíces, energía y uniformidad del establecimiento.';
        }
        return 'El fósforo sostiene procesos clave, pero su mayor retorno suele estar en llegar bien colocado desde arranque.';

      case AgroMetricKey.k:
        if (stageKey == MaizeStageKey.tasseling ||
            stageKey == MaizeStageKey.flowerSet ||
            stageKey == MaizeStageKey.maturitySenescence) {
          return 'El potasio gana peso hacia etapas reproductivas por su papel en agua, tallo, transporte y estabilidad del cultivo.';
        }
        return 'El potasio acompaña balance hídrico, vigor y estabilidad fisiológica durante el ciclo del cultivo.';

      default:
        return 'La interpretación depende de la etapa y del contexto del cultivo.';
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
