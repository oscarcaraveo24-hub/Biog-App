// lib/core/agro/agro_score_engine.dart
import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/crops/maize/maize_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class AgroScoreEngine {
  /// Evalúa telemetría + etapa y regresa score + métricas + alertas.
  ///
  /// - NO incluye Weather en el ring.
  /// - SoilHealthRing = “controlable del suelo” (humedad, pH, EC, resistencia, NPK).
  ///
  /// ✅ IMPORTANTE (v2 de tu app):
  /// - NPK se evalúa contra rangos por etapa del Universal Profile.
  ///   (En este profile, esos rangos son ÍNDICE 0..100 normalizado desde ppm).
  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateMaize({
    required BioGTelemetry t,
    required SeedStageResult stage,
    required MaizeUniversalProfile u,
    AlertsState alertsState = const AlertsState(),
    Calibration? cal,
    Duration alertsCooldown = AlertsEngine.defaultCooldown,
    String? cropLabel,
  }) {
    final stageKey = stage.stage;
    final targets = u.byStage[stageKey];
    final weights = u.weights[stageKey];

    if (targets == null || weights == null) {
      final empty = AgroEvalResult(
        soilControlScore01: 0.0,
        metrics: const {},
        alerts: const [],
        suggestedAlertKeys: const ['stage.unknown'],
      );
      return (eval: empty, nextAlertsState: alertsState);
    }

    // ---------- Normalización v1 ----------
    final moisture01 = _normalizeMoisture01(t.soilMoisturePct, cal); // 0..1
    final moistureRawCal = moisture01 * 100.0;

    final soilTemp = t.soilTempC;
    final ph = t.ph;
    final ec = t.ec;

    // ✅ MPa directo (compactación / resistencia a penetración)
    final resistanceMpa = t.resistance;

    // ✅ NPK (ppm -> índice 0..100) para comparar contra targets.nIndex/pIndex/kIndex
    final nIndex0to100 = _ppmToIndex0to100(t.n.toDouble(), AgroMetricKey.n);
    final pIndex0to100 = _ppmToIndex0to100(t.p.toDouble(), AgroMetricKey.p);
    final kIndex0to100 = _ppmToIndex0to100(t.k.toDouble(), AgroMetricKey.k);

    // ---------- Evaluaciones ----------
    final moistureEval = _eval(
      value: moistureRawCal,
      range: targets.moistureRaw,
    );
    final soilTempEval = _eval(value: soilTemp, range: targets.soilTemp);
    final phEval = _eval(value: ph, range: targets.ph);
    final ecEval = _eval(value: ec, range: targets.ec);

    final resEval = _eval(value: resistanceMpa, range: targets.resistance);

    // ✅ AHORA sí: comparar índice 0..100 contra rangos índice 0..100
    final nEval = _eval(value: nIndex0to100, range: targets.nIndex);
    final pEval = _eval(value: pIndex0to100, range: targets.pIndex);
    final kEval = _eval(value: kIndex0to100, range: targets.kIndex);

    final metrics = <AgroMetricKey, AgroMetricEval>{
      AgroMetricKey.soilMoisture: _wrap(moistureEval),
      AgroMetricKey.soilTemp: _wrap(soilTempEval),
      AgroMetricKey.ph: _wrap(phEval),
      AgroMetricKey.ec: _wrap(ecEval),
      AgroMetricKey.resistance: _wrap(resEval),

      // ✅ value aquí ya es índice 0..100 (no ppm)
      AgroMetricKey.n: _wrap(nEval),
      AgroMetricKey.p: _wrap(pEval),
      AgroMetricKey.k: _wrap(kEval),
    };

    // NPK score compuesto:
    final npkScore01 = _avg([nEval.score01, pEval.score01, kEval.score01]);

    // SoilControlScore (ring):
    final wSum = math.max(0.0001, weights.sum);
    final soilControlScore01 =
        (weights.moisture * moistureEval.score01 +
            weights.resistance * resEval.score01 +
            weights.ph * phEval.score01 +
            weights.ec * ecEval.score01 +
            weights.npk * npkScore01) /
        wSum;

    // ---------- Suggested alert keys ----------
    final suggested = <String>[];
    _pushAlertsForMetric(suggested, 'soilMoisture', moistureEval, stageKey);
    _pushAlertsForMetric(suggested, 'soilTemp', soilTempEval, stageKey);
    _pushAlertsForMetric(suggested, 'ph', phEval, stageKey);
    _pushAlertsForMetric(suggested, 'ec', ecEval, stageKey);
    _pushAlertsForMetric(suggested, 'resistance', resEval, stageKey);

    _pushAlertsForMetric(suggested, 'npk.n', nEval, stageKey);
    _pushAlertsForMetric(suggested, 'npk.p', pEval, stageKey);
    _pushAlertsForMetric(suggested, 'npk.k', kEval, stageKey);

    // ---------- Build BioGAlert real (anti-spam) ----------
    final built = AlertsEngine.buildFromSuggestedKeys(
      deviceId: t.deviceId,
      now: t.timestamp,
      stageKey: stageKey,
      suggestedKeys: suggested,
      prev: alertsState,
      cooldown: alertsCooldown,
      cropLabel: cropLabel,
    );

    final eval = AgroEvalResult(
      soilControlScore01: soilControlScore01.clamp(0.0, 1.0),
      metrics: metrics,
      alerts: built.alerts,
      suggestedAlertKeys: suggested,
    );

    return (eval: eval, nextAlertsState: built.state);
  }

  // -------------------------
  // Internals
  // -------------------------

  // ✅ Misma lógica/caps que usas en Dashboard (_ppmCapFor)
  static double _ppmCapFor(AgroMetricKey k) {
    switch (k) {
      case AgroMetricKey.n:
        return 120.0;
      case AgroMetricKey.p:
        return 80.0;
      case AgroMetricKey.k:
        return 140.0;
      default:
        return 100.0;
    }
  }

  static double _ppmToIndex0to100(double ppm, AgroMetricKey k) {
    return ((ppm / _ppmCapFor(k)) * 100.0).clamp(0.0, 100.0);
  }

  static AgroMetricEval _wrap(_Eval e) => AgroMetricEval(
    band: e.band,
    score01: e.score01,
    labelEs: _labelEs(e.band),
    value: e.value,
  );

  static String _labelEs(AgroBand b) {
    switch (b) {
      case AgroBand.low:
        return 'Bajo';
      case AgroBand.optimal:
        return 'Óptimo';
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

    // sanea rangos por seguridad
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
    } else {
      final span = math.max(1e-6, (highMin - optMax).abs());
      final d = (v - highMin) / span;
      return (0.35 / (1 + d)).clamp(0.05, 0.35);
    }
  }

  static void _pushAlertsForMetric(
    List<String> out,
    String key,
    _Eval e,
    MaizeStageKey stage,
  ) {
    final isCriticalStage = stage == MaizeStageKey.flowerSet;

    if (e.band == AgroBand.critical) {
      out.add('$key.critical');
      return;
    }

    // En etapa crítica, también alertamos low/high (pero no spameamos por cooldown).
    if (isCriticalStage && e.band == AgroBand.low) out.add('$key.low');
    if (isCriticalStage && e.band == AgroBand.high) out.add('$key.high');
  }

  static double _normalizeMoisture01(double raw0to100, Calibration? cal) {
    final dry = cal?.moistureDryRaw;
    final wet = cal?.moistureWetRaw;

    if (dry != null && wet != null && (wet - dry).abs() > 1e-6) {
      return ((raw0to100 - dry) / (wet - dry)).clamp(0.0, 1.0);
    }
    return (raw0to100 / 100.0).clamp(0.0, 1.0);
  }

  static double _avg(List<double> xs) {
    if (xs.isEmpty) return 0.0;
    final s = xs.fold<double>(0.0, (a, b) => a + b);
    return (s / xs.length).clamp(0.0, 1.0);
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
