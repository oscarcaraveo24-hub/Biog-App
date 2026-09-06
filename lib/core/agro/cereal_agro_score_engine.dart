// lib/core/agro/cereal_agro_score_engine.dart
//
// Motor agronómico compartido para cereales (avena, cebada, trigo).
// Usa la misma semántica de score continuo que maíz y frijol para mantener
// consistencia entre cultivos al comparar Soil Control Score y bandas.

import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/soil_condition_score.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class CerealAgroScoreEngine {
  /// Evalúa telemetría contra targets/weights ya resueltos por etapa.
  /// [stageKey] es el nombre del enum (e.g. "flowering").
  /// [targets] y [weights] vienen del universal profile del cultivo.
  /// [criticalStageKeys] indica cuáles etapas son críticas para alertas extra.
  ///
  /// Los «caps» de NPK por cultivo que recibía este motor se retiraron con el
  /// NPK Interpretation Reset (Guía v0.4, §4): N/P/K ya no se convierten a un
  /// índice 0..100 ni se comparan contra la banda del catálogo. Viajan como
  /// señal nativa.
  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluate({
    required BioGTelemetry t,
    required StageTargets targets,
    required StageWeights weights,
    required String stageKey,
    required Set<String> criticalStageKeys,
    AlertsState alertsState = const AlertsState(),
    Calibration? cal,
    Duration alertsCooldown = AlertsEngine.defaultCooldown,
    String? cropLabel,
    String? stageLabel,
  }) {
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

    // Sin bandera de presencia el canal viaja como NaN: la métrica sale «sin
    // dato» y fuera del denominador del score (ver `SoilConditionScore`).
    final soilTemp = t.hasSoilTempData ? t.soilTempC : double.nan;
    final ph = t.hasPhData ? t.ph : double.nan;
    final ec = t.hasEcData ? t.ec : double.nan;
    final resistance = t.hasResistanceData ? t.resistance : double.nan;

    final moistureEval = _eval(
      value: moistureRawCal,
      range: targets.moistureRaw,
    );
    final soilTempEval = _eval(value: soilTemp, range: targets.soilTemp);
    final phEval = _eval(value: ph, range: targets.ph);
    final ecEval = _eval(value: ec, range: targets.ec);
    final resistanceEval = _eval(value: resistance, range: targets.resistance);
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
      AgroMetricKey.soilMoisture: _wrap(moistureEval),
      AgroMetricKey.soilTemp: _wrap(soilTempEval),
      AgroMetricKey.ph: _wrap(phEval),
      AgroMetricKey.ec: _wrap(ecEval),
      AgroMetricKey.resistance: _wrap(resistanceEval),
      AgroMetricKey.n: nMetric,
      AgroMetricKey.p: pMetric,
      AgroMetricKey.k: kMetric,
    };

    // ── Penalización por métricas físicas en estado crítico ──
    double criticalPenalty = 1.0;
    if (moistureEval.band == AgroBand.critical) criticalPenalty *= 0.45;
    if (soilTempEval.band == AgroBand.critical) criticalPenalty *= 0.50;
    if (phEval.band == AgroBand.critical) criticalPenalty *= 0.45;
    if (ecEval.band == AgroBand.critical) criticalPenalty *= 0.65;
    if (resistanceEval.band == AgroBand.critical) criticalPenalty *= 0.85;

    // ── Condición del suelo: solo señales físicas presentes ─────────────────
    //
    // Los pesos de N/P/K del perfil no entran (peso cero por decisión) y una
    // señal ausente sale del denominador en vez de valer 0 o 0.5. La
    // cobertura de evidencia viaja aparte. Ver `SoilConditionScore`.
    final SoilConditionScoreResult soil = SoilConditionScore.compute(
      metrics: metrics,
      weights: weights,
      criticalPenalty: criticalPenalty,
    );

    final suggestedAlertKeys = <String>[];
    final isCriticalStage = criticalStageKeys.contains(stageKey);

    _pushAlertsForMetric(
      suggestedAlertKeys,
      'soilMoisture',
      moistureEval,
      isCriticalStage,
    );
    _pushAlertsForMetric(
      suggestedAlertKeys,
      'soilTemp',
      soilTempEval,
      isCriticalStage,
    );
    _pushAlertsForMetric(suggestedAlertKeys, 'ph', phEval, isCriticalStage);
    _pushAlertsForMetric(suggestedAlertKeys, 'ec', ecEval, isCriticalStage);
    _pushAlertsForMetric(
      suggestedAlertKeys,
      'resistance',
      resistanceEval,
      isCriticalStage,
    );

    // ── Alertas ambientales (no participan en score, solo notificaciones) ──
    _pushEnvironmentalAlerts(suggestedAlertKeys, t, isCriticalStage);

    // severityBump: 2=full (flowering-like), 1=partial (tasseling-like), 0=normal
    final int severityBump = isCriticalStage ? 2 : 0;

    final alertsBuild = AlertsEngine.buildFromSuggestedKeys(
      deviceId: t.deviceId,
      now: t.timestamp,
      severityBump: severityBump,
      suggestedKeys: suggestedAlertKeys,
      prev: alertsState,
      cooldown: alertsCooldown,
      cropLabel: cropLabel,
      stageLabel: stageLabel,
    );

    final agroEval = AgroEvalResult(
      soilControlScore01: soil.score01,
      soilCoverage: soil.coverage,
      metrics: metrics,
      alerts: alertsBuild.alerts,
      suggestedAlertKeys: suggestedAlertKeys,
    );

    return (eval: agroEval, nextAlertsState: alertsBuild.state);
  }

  static AgroMetricEval _wrap(_Eval e) => AgroMetricEval(
    band: e.band,
    score01: e.score01,
    labelEs: _labelEs(e.band),
    // NaN significa «no llegó»: hacia afuera viaja como null, no como número.
    value: e.value.isFinite ? e.value : null,
  );

  static String _labelEs(AgroBand band) {
    switch (band) {
      case AgroBand.optimal:
        return 'Óptimo';
      case AgroBand.low:
        return 'Bajo';
      case AgroBand.high:
        return 'Alto';
      case AgroBand.critical:
        return 'Crítico';
      case AgroBand.unknown:
        return '—';
    }
  }


  static _Eval _eval({required double value, required AgroRange range}) {
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

  static void _pushAlertsForMetric(
    List<String> out,
    String key,
    _Eval e,
    bool isCriticalStage,
  ) {
    if (e.band == AgroBand.critical) {
      out.add('$key.critical');
      return;
    }

    if (isCriticalStage && e.band == AgroBand.low) {
      out.add('$key.low');
    }

    if (isCriticalStage && e.band == AgroBand.high) {
      out.add('$key.high');
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

  /// Alertas ambientales basadas en airTempC y airHumidityPct.
  /// No participan en el score (solo notificaciones/avisos).
  /// Umbrales genéricos para cereales C3 — trigo/cebada/avena.
  static void _pushEnvironmentalAlerts(
    List<String> out,
    BioGTelemetry t,
    bool isCriticalStage,
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

    // Helada: <2 °C siempre alerta; en etapa crítica, <4 °C
    if (airTemp <= 0) {
      out.add('airTemp.frost');
    } else if (airTemp < 2 || (isCriticalStage && airTemp < 4)) {
      out.add('airTemp.cold');
    }

    // Calor: >35 °C warning, >40 °C critical
    if (airTemp > 40) {
      out.add('airTemp.extreme_heat');
    } else if (airTemp > 35) {
      out.add('airTemp.heat');
    }

    // Humedad relativa alta: >90 critical, >80 warning
    if (airHum > 90) {
      out.add('airHumidity.critical');
    } else if (airHum > 80) {
      out.add('airHumidity.high');
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
