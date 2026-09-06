import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/soil_condition_score.dart';
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
/// - N/P/K → señal nativa sin diagnóstico (NPK Interpretation Reset, Guía v0.4
///   §4). La sonda deriva estos canales de la conductividad; el árbol no los
///   compara contra ningún objetivo. Lo que antes se decidía aquí sobre «alto
///   útil», «exceso» o «N alto en brotación» a partir del raw salió del
///   runtime: el manejo nutricional del frutal lo decide el motor de nutrición
///   con la etapa, la guía de restitución (`TreeRestitutionPlanner`), el
///   modificador de variedad y el historial de aplicaciones.
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

    final moistureEval = _evalTreeSoilMetric(
      metricKey: AgroMetricKey.soilMoisture,
      value: moistureRawCal,
      range: targets.moistureRaw,
    );
    final soilTempEval = _evalTreeSoilMetric(
      metricKey: AgroMetricKey.soilTemp,
      value: t.hasSoilTempData ? t.soilTempC : double.nan,
      range: targets.soilTemp,
    );
    final phEval = _evalTreeSoilMetric(
      metricKey: AgroMetricKey.ph,
      value: t.hasPhData ? t.ph : double.nan,
      range: targets.ph,
    );
    final ecEval = _evalTreeSoilMetric(
      metricKey: AgroMetricKey.ec,
      value: t.hasEcData ? t.ec : double.nan,
      range: targets.ec,
    );
    final resEval = _evalTreeSoilMetric(
      metricKey: AgroMetricKey.resistance,
      value: t.hasResistanceData ? t.resistance : double.nan,
      range: targets.resistance,
    );

    // ── N/P/K: señal nativa, sin diagnóstico ──────────────────────────────
    //
    // La sonda 7-en-1 deriva estos tres canales de la conductividad; no los
    // mide químicamente. Desde el NPK Interpretation Reset (Guía v0.4, §4) el
    // motor los conserva como señal cruda —para historial, tendencias y
    // respuesta a eventos— y no los compara contra ningún objetivo del
    // cultivo. El manejo nutricional lo decide `NutritionReadinessEngine` con
    // etapa, guía auditada, historial y condiciones físicas.
    final nMetric = AgroMetricEval.nativeSignal(
      value: t.n.toDouble(),
      hasData: t.hasNitrogenData,
    );
    final pMetric = AgroMetricEval.nativeSignal(
      value: t.p.toDouble(),
      hasData: t.hasPhosphorusData,
    );
    final kMetric = AgroMetricEval.nativeSignal(
      value: t.k.toDouble(),
      hasData: t.hasPotassiumData,
    );

    final metrics = <AgroMetricKey, AgroMetricEval>{
      AgroMetricKey.soilMoisture: _wrapLegacy(
        moistureEval,
        displayValue: t.hasSoilMoistureData ? moistureRawCal : null,
      ),
      AgroMetricKey.soilTemp: _wrapLegacy(
        soilTempEval,
        displayValue: t.hasSoilTempData ? t.soilTempC : null,
      ),
      AgroMetricKey.ph: _wrapLegacy(phEval, displayValue: t.hasPhData ? t.ph : null),
      AgroMetricKey.ec: _wrapLegacy(ecEval, displayValue: t.hasEcData ? t.ec : null),
      AgroMetricKey.resistance: _wrapLegacy(
        resEval,
        displayValue: t.hasResistanceData ? t.resistance : null,
      ),
      AgroMetricKey.n: nMetric,
      AgroMetricKey.p: pMetric,
      AgroMetricKey.k: kMetric,
    };

    // ── Condición del suelo: solo señales físicas presentes ─────────────────
    //
    // Los pesos de N/P/K del perfil no entran (peso cero por decisión) y una
    // señal ausente sale del denominador en vez de valer 0 o 0.5. La
    // cobertura de evidencia viaja aparte. Ver `SoilConditionScore`.
    double criticalPenalty = 1.0;
    if (moistureEval.isCriticalLow) criticalPenalty *= 0.45;
    if (moistureEval.isCriticalHigh) criticalPenalty *= 0.70;
    if (soilTempEval.isCritical) criticalPenalty *= 0.50;
    if (phEval.isCritical) criticalPenalty *= 0.45;
    if (ecEval.isCritical) criticalPenalty *= 0.65;
    if (resEval.isCritical) criticalPenalty *= 0.85;

    final SoilConditionScoreResult soil = SoilConditionScore.compute(
      metrics: metrics,
      weights: weights,
      criticalPenalty: criticalPenalty,
    );

    final suggested = <String>['tree.stage.$stage'];
    _pushSoilSuggestedKey(suggested, 'soilMoisture', moistureEval.band, stage);
    _pushSoilSuggestedKey(suggested, 'soilTemp', soilTempEval.band, stage);
    _pushSoilSuggestedKey(suggested, 'ph', phEval.band, stage);
    _pushSoilSuggestedKey(suggested, 'ec', ecEval.band, stage);
    _pushSoilSuggestedKey(suggested, 'resistance', resEval.band, stage);

    final alertBuild = _buildTreeAlerts(
      telemetry: t,
      stageId: stage,
      metrics: metrics,
      alertsState: alertsState,
      cooldown: alertsCooldown,
      // Umbral de encharcamiento REAL, no un 80 escrito a mano. `highMin` ya
      // viene derivado de la textura del suelo (0,90 x saturación), así que en
      // arena dispara a 34,2 % y en arcilla a 47,7 % — dos números distintos
      // para el mismo criterio agronómico.
      saturationThresholdPct: targets.moistureRaw.highMin,
    );

    final eval = AgroEvalResult(
      soilControlScore01: soil.score01,
      soilCoverage: soil.coverage,
      metrics: metrics,
      alerts: alertBuild.alerts,
      suggestedAlertKeys: suggested,
    );

    return (eval: eval, nextAlertsState: alertBuild.state);
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
  static AgroMetricEval _wrapLegacy(_Eval e, {required double? displayValue}) {
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

  // ===========================================================================
  // ALERTAS POR ETAPA — lenguaje genérico de árbol perenne
  // ===========================================================================
  static AlertsBuildResult _buildTreeAlerts({
    required BioGTelemetry telemetry,
    required String stageId,
    required Map<AgroMetricKey, AgroMetricEval> metrics,
    required AlertsState alertsState,
    required Duration cooldown,
    required double saturationThresholdPct,
  }) {
    final nextMap = Map<BioGAlertType, DateTime>.from(alertsState.lastByType);
    final nextKeyMap = Map<String, DateTime>.from(alertsState.lastByKey);
    final alerts = <BioGAlert>[];
    final now = telemetry.timestamp;

    void push({
      required BioGAlertType type,
      required BioGAlertSeverity severity,
      required String title,
      required String body,
    }) {
      // Cooldown por (tipo + severidad): ver la nota en AlertsState.lastByKey.
      final cooldownKey = AlertsState.cooldownKey(type, severity);
      final last = nextKeyMap[cooldownKey];
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
      nextKeyMap[cooldownKey] = now;
    }

    final moisture = metrics[AgroMetricKey.soilMoisture]?.band;
    final resistance = metrics[AgroMetricKey.resistance]?.band;
    final soilTemp = metrics[AgroMetricKey.soilTemp]?.band;
    final ec = metrics[AgroMetricKey.ec]?.band;
    final moistureLow =
        moisture == AgroBand.low || moisture == AgroBand.critical;
    final moistureHigh =
        moisture == AgroBand.high || moisture == AgroBand.critical;
    final heat =
        (telemetry.hasAirTempData && telemetry.airTempC >= 35) ||
        soilTemp == AgroBand.high ||
        soilTemp == AgroBand.critical;
    // La bandera manda también aquí. Este archivo ya honra `hasNitrogenData`,
    // `hasPhosphorusData` y `hasPotassimData` unas líneas más arriba; olvidar la
    // del aire dejaba un aviso de helada en brotación disparándose con el 0.0
    // sintetizado de un equipo sin sensor de aire.
    final cold = telemetry.hasAirTempData && telemetry.airTempC <= 4;
    final highHumidity =
        telemetry.hasAirHumidityData && telemetry.airHumidityPct >= 85;
    final salinityHigh = ec == AgroBand.high || ec == AgroBand.critical;
    final moistureValue =
        metrics[AgroMetricKey.soilMoisture]?.value ?? telemetry.soilMoisturePct;
    // El 80 % que había aquí escrito a mano era físicamente inalcanzable en
    // suelo mineral: la saturación más alta de la tabla —arcilla— es 53 %, y su
    // umbral de encharcamiento 47,7 %. Ningún árbol en tierra llegaba nunca a
    // esa condición, así que la rama de «exceso de humedad» estaba muerta justo
    // en los cultivos que mata la asfixia radicular: aguacate, cítrico y nogal.
    // El 80 % que había aquí escrito a mano no era solo inalcanzable en suelo
    // mineral —la saturación más alta de la tabla, arcilla, es 53 %—: además
    // colgaba de `moisture == critical`, y la humedad se evalúa con
    // `publicCriticalHigh: false`, así que `critical` solo puede venir del lado
    // SECO. La condición era doblemente imposible y la rama estaba muerta,
    // justo en los cultivos que mata la asfixia radicular: aguacate, cítrico y
    // nogal.
    //
    // Ahora la lectura se compara directamente contra el umbral de
    // encharcamiento derivado de la textura (0,90 × saturación): en arena
    // dispara a 34,2 % y en arcilla a 47,7 %.
    final moistureLikelySaturated =
        moisture == AgroBand.high || moistureValue >= saturationThresholdPct;
    final moistureLikelyDry =
        moisture == AgroBand.low ||
        (moisture == AgroBand.critical && !moistureLikelySaturated);
    final compactionHigh =
        resistance == AgroBand.high || resistance == AgroBand.critical;
    // Con la bandera: sin sensor de temperatura de suelo el 0.0 sintetizado
    // cumplía `<= 12` y declaraba «raíz lenta» en cada lectura, para siempre.
    final soilTempStress =
        soilTemp == AgroBand.critical ||
        (telemetry.hasSoilTempData &&
            (telemetry.soilTempC <= 12 || telemetry.soilTempC >= 30));
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
            severity: telemetry.hasAirTempData && telemetry.airTempC <= 0
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
        }
        // El aviso «N alto en brotación» que salía de la etiqueta NPK cruda se
        // retiró con el reset: la sonda no puede afirmar exceso de nitrógeno.
        // La cautela sobre N en brotación vive ahora en la guía de nutrición.
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
            severity: telemetry.hasAirTempData && telemetry.airTempC <= 0
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
        // Los avisos «N alto / K alto cerca de cosecha» que salían de la
        // etiqueta NPK cruda se retiraron con el reset. La cautela con N y K
        // tardíos sigue viva en la guía de nutrición del frutal, donde puede
        // afirmarse con la etapa y el historial de aplicaciones, no con la
        // sonda.
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
        if (moistureLow) {
          push(
            type: BioGAlertType.lowSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Post-cosecha con estres',
            body:
                'Post-cosecha: el árbol repone fuerza para el siguiente ciclo. Mantén riego parejo; la reposición de nutrientes la marca la guía del frutal, no la sonda.',
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
      state: alertsState.copyWith(lastByType: nextMap, lastByKey: nextKeyMap),
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
