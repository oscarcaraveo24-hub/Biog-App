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
import 'package:bio_g/widgets/seeds/maize_models.dart';

class CerealAgroScoreEngine {
  /// Evalúa telemetría contra targets/weights ya resueltos por etapa.
  /// [stageKey] es el nombre del enum (e.g. "flowering").
  /// [targets] y [weights] vienen del universal profile del cultivo.
  /// [criticalStageKeys] indica cuáles etapas son críticas para alertas extra.
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
    final moisture01 = _normalizeMoisture01(t.soilMoisturePct, cal);
    final moistureRawCal = moisture01 * 100.0;

    final soilTemp = t.soilTempC;
    final ph = t.ph;
    final ec = t.ec;
    final resistance = t.resistance;

    final nRawPpm = _calibrateValue(t.n, cal?.nMinRaw, cal?.nMaxRaw);
    final pRawPpm = _calibrateValue(t.p, cal?.pMinRaw, cal?.pMaxRaw);
    final kRawPpm = _calibrateValue(t.k, cal?.kMinRaw, cal?.kMaxRaw);

    final nIndex0to100 = _ppmToIndex0to100(nRawPpm, AgroMetricKey.n);
    final pIndex0to100 = _ppmToIndex0to100(pRawPpm, AgroMetricKey.p);
    final kIndex0to100 = _ppmToIndex0to100(kRawPpm, AgroMetricKey.k);

    final moistureEval = _eval(
      value: moistureRawCal,
      range: targets.moistureRaw,
    );
    final soilTempEval = _eval(value: soilTemp, range: targets.soilTemp);
    final phEval = _eval(value: ph, range: targets.ph);
    final ecEval = _eval(value: ec, range: targets.ec);
    final resistanceEval = _eval(value: resistance, range: targets.resistance);
    final nEval = _eval(value: nIndex0to100, range: targets.nIndex);
    final pEval = _eval(value: pIndex0to100, range: targets.pIndex);
    final kEval = _eval(value: kIndex0to100, range: targets.kIndex);

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

    final npkScore01 = _avg([nEval.score01, pEval.score01, kEval.score01]);
    final totalW = math.max(0.0001, weights.sum);
    final soilControlScore01 =
        (weights.moisture * moistureEval.score01 +
            weights.resistance * resistanceEval.score01 +
            weights.ph * phEval.score01 +
            weights.ec * ecEval.score01 +
            weights.npk * npkScore01) /
        totalW;

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

    final maizeStage = _mapCerealStageToAlertStage(stageKey);

    final alertsBuild = AlertsEngine.buildFromSuggestedKeys(
      deviceId: t.deviceId,
      now: t.timestamp,
      stageKey: maizeStage,
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

  static double _ppmCapFor(AgroMetricKey key) {
    switch (key) {
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

  static double _ppmToIndex0to100(double ppm, AgroMetricKey key) {
    return ((ppm / _ppmCapFor(key)) * 100.0).clamp(0.0, 100.0);
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

  static double _normalizeMoisture01(double raw0to100, Calibration? cal) {
    final dry = cal?.moistureDryRaw;
    final wet = cal?.moistureWetRaw;

    if (dry != null && wet != null && (wet - dry).abs() > 1e-6) {
      return ((raw0to100 - dry) / (wet - dry)).clamp(0.0, 1.0);
    }

    return (raw0to100 / 100.0).clamp(0.0, 1.0);
  }

  static double _avg(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sum = values.fold<double>(0.0, (a, b) => a + b);
    return (sum / values.length).clamp(0.0, 1.0);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  static double _invLerp(double a, double b, double v) {
    final denom = (b - a);
    if (denom.abs() < 1e-9) return 0.0;
    return ((v - a) / denom).clamp(0.0, 1.0);
  }

  static MaizeStageKey _mapCerealStageToAlertStage(String stageKey) {
    switch (stageKey) {
      case 'germination':
        return MaizeStageKey.germination;
      case 'emergence':
        return MaizeStageKey.emergence;
      case 'vegEarly':
        return MaizeStageKey.vegEarly;
      case 'tillering':
        return MaizeStageKey.vegMid;
      case 'elongation':
        return MaizeStageKey.vegAdvanced;
      case 'booting':
      case 'heading':
        return MaizeStageKey.tasseling;
      case 'flowering':
        return MaizeStageKey.flowerSet;
      case 'grainFill':
      case 'physiologicalMaturity':
        return MaizeStageKey.maturitySenescence;
      case 'harvest':
        return MaizeStageKey.harvest;
      default:
        return MaizeStageKey.vegMid;
    }
  }
}

class _Eval {
  const _Eval({required this.value, required this.band, required this.score01});

  final double value;
  final AgroBand band;
  final double score01;
}
