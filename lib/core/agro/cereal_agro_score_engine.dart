// lib/core/agro/cereal_agro_score_engine.dart
//
// Motor agronómico compartido para cereales (avena, cebada, trigo).
// Usa la misma semántica de score continuo que maíz y frijol para mantener
// consistencia entre cultivos al comparar Soil Control Score y bandas.

import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class CerealAgroScoreEngine {
  /// Evalúa telemetría contra targets/weights ya resueltos por etapa.
  /// [stageKey] es el nombre del enum (e.g. "flowering").
  /// [targets] y [weights] vienen del universal profile del cultivo.
  /// [criticalStageKeys] indica cuáles etapas son críticas para alertas extra.
  /// [nCapPpm], [pCapPpm], [kCapPpm] permiten configurar los caps de NPK por cultivo.
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
    double nCapPpm = 120.0,
    double pCapPpm = 80.0,
    double kCapPpm = 140.0,
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

    final soilTemp = t.soilTempC;
    final ph = t.ph;
    final ec = t.ec;
    final resistance = t.resistance;

    final nRawPpm = _calibrateValue(t.n, cal?.nMinRaw, cal?.nMaxRaw);
    final pRawPpm = _calibrateValue(t.p, cal?.pMinRaw, cal?.pMaxRaw);
    final kRawPpm = _calibrateValue(t.k, cal?.kMinRaw, cal?.kMaxRaw);

    final nIndex0to100 = _ppmToIndex0to100(nRawPpm, nCapPpm);
    final pIndex0to100 = _ppmToIndex0to100(pRawPpm, pCapPpm);
    final kIndex0to100 = _ppmToIndex0to100(kRawPpm, kCapPpm);

    final moistureEval = _eval(
      value: moistureRawCal,
      range: targets.moistureRaw,
    );
    final soilTempEval = _eval(value: soilTemp, range: targets.soilTemp);
    final phEval = _eval(value: ph, range: targets.ph);
    final ecEval = _eval(value: ec, range: targets.ec);
    final resistanceEval = _eval(value: resistance, range: targets.resistance);
    // Sin sonda de nutrientes no hay dato, y ausencia NO es cero.
    //
    // Este motor no pasa por `_interpret*Nutrient` —evalúa el índice contra la
    // banda directamente—, así que la guarda va aquí. Sin ella, un trigo sin
    // sonda NPK daba índice 0, caía en `critical` contra la banda del catálogo
    // (lowMax 8) y multiplicaba la penalización crítica tres veces: el
    // `soilControlScore01` se quedaba en un tercio de forma permanente, con
    // N, P y K en «Crítico» para siempre.
    final nEval = t.hasNitrogenData
        ? _eval(value: nIndex0to100, range: targets.nIndex)
        : _evalUnknown(nIndex0to100);
    final pEval = t.hasPhosphorusData
        ? _eval(value: pIndex0to100, range: targets.pIndex)
        : _evalUnknown(pIndex0to100);
    final kEval = t.hasPotassiumData
        ? _eval(value: kIndex0to100, range: targets.kIndex)
        : _evalUnknown(kIndex0to100);

    final metrics = <AgroMetricKey, AgroMetricEval>{
      AgroMetricKey.soilMoisture: _wrap(moistureEval),
      AgroMetricKey.soilTemp: _wrap(soilTempEval),
      AgroMetricKey.ph: _wrap(phEval),
      AgroMetricKey.ec: _wrap(ecEval),
      AgroMetricKey.resistance: _wrap(resistanceEval),
      AgroMetricKey.n: _wrap(nEval),
      AgroMetricKey.p: _wrap(pEval),
      AgroMetricKey.k: _wrap(kEval),
    };

    final totalW = math.max(0.0001, weights.sum);
    final rawScore =
        (weights.moisture * moistureEval.score01 +
            weights.soilTemp * soilTempEval.score01 +
            weights.resistance * resistanceEval.score01 +
            weights.ph * phEval.score01 +
            weights.ec * ecEval.score01 +
            weights.nutrientN * nEval.score01 +
            weights.nutrientP * pEval.score01 +
            weights.nutrientK * kEval.score01) /
        totalW;

    // ── Penalización por métricas en estado crítico ──
    double criticalPenalty = 1.0;
    if (moistureEval.band == AgroBand.critical) criticalPenalty *= 0.45;
    if (soilTempEval.band == AgroBand.critical) criticalPenalty *= 0.50;
    if (phEval.band == AgroBand.critical) criticalPenalty *= 0.45;
    if (ecEval.band == AgroBand.critical) criticalPenalty *= 0.65;
    if (resistanceEval.band == AgroBand.critical) criticalPenalty *= 0.85;
    if (nEval.band == AgroBand.critical) criticalPenalty *= 0.70;
    if (pEval.band == AgroBand.critical) criticalPenalty *= 0.70;
    if (kEval.band == AgroBand.critical) criticalPenalty *= 0.70;

    final soilControlScore01 = rawScore * criticalPenalty;

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
    _pushAlertsForMetric(suggestedAlertKeys, 'npk.n', nEval, isCriticalStage);
    _pushAlertsForMetric(suggestedAlertKeys, 'npk.p', pEval, isCriticalStage);
    _pushAlertsForMetric(suggestedAlertKeys, 'npk.k', kEval, isCriticalStage);

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
      soilControlScore01: soilControlScore01.clamp(0.0, 1.0),
      metrics: metrics,
      alerts: alertsBuild.alerts,
      suggestedAlertKeys: suggestedAlertKeys,
    );

    return (eval: agroEval, nextAlertsState: alertsBuild.state);
  }

  static double _ppmToIndex0to100(double ppm, double cap) {
    return ((ppm / cap) * 100.0).clamp(0.0, 100.0);
  }

  static double _calibrateValue(double value, double? minRaw, double? maxRaw) {
    if (minRaw == null && maxRaw == null) return value;
    final lo = minRaw ?? double.negativeInfinity;
    final hi = maxRaw ?? double.infinity;
    return value.clamp(lo, hi);
  }

  static AgroMetricEval _wrap(_Eval e) => AgroMetricEval(
    band: e.band,
    score01: e.score01,
    labelEs: _labelEs(e.band),
    value: e.value,
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

  /// Métrica sin sensor: banda desconocida y puntuación NEUTRA.
  ///
  /// El 0.5 importa. `_eval` ya devuelve `unknown` ante NaN, pero con
  /// `score01: 0.0`, y ese cero entra en el promedio ponderado de la línea 102
  /// como si el nutriente estuviera en lo peor. Para una sonda ausente lo
  /// correcto es no opinar: ni premia ni castiga. Es el mismo 0.5 que usa la
  /// guarda de los otros veintitrés motores.
  static _Eval _evalUnknown(double value) =>
      _Eval(value: value, band: AgroBand.unknown, score01: 0.5);

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

  static double _avg(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sum = values.fold<double>(0.0, (a, b) => a + b);
    return (sum / values.length).clamp(0.0, 1.0);
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
