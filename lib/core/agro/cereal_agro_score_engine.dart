// lib/core/agro/cereal_agro_score_engine.dart
//
// Motor agronómico compartido para cereales (avena, cebada, trigo).
// Comparte la misma lógica de scoring que maíz/frijol pero opera
// sobre StageTargets + StageWeights resueltos externamente.

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
    // ── Evaluar métricas de suelo ──
    final moistureEval = _evalMetric(t.soilMoisturePct, targets.moistureRaw);
    final soilTempEval = _evalMetric(t.soilTempC, targets.soilTemp);
    final phEval = _evalMetric(t.ph, targets.ph);
    final ecEval = _evalMetric(t.ec, targets.ec);
    final resistanceEval = _evalMetric(t.resistance, targets.resistance);

    // ── Evaluar NPK ──
    // Igual que maíz/frijol: el score compara un índice 0..100 derivado de ppm
    // contra los targets nIndex/pIndex/kIndex del universal profile.
    final nRawPpm = _calibrateValue(t.n, cal?.nMinRaw, cal?.nMaxRaw);
    final pRawPpm = _calibrateValue(t.p, cal?.pMinRaw, cal?.pMaxRaw);
    final kRawPpm = _calibrateValue(t.k, cal?.kMinRaw, cal?.kMaxRaw);

    final nIndex0to100 = _ppmToIndex0to100(nRawPpm, AgroMetricKey.n);
    final pIndex0to100 = _ppmToIndex0to100(pRawPpm, AgroMetricKey.p);
    final kIndex0to100 = _ppmToIndex0to100(kRawPpm, AgroMetricKey.k);

    final nEval = _evalMetric(nIndex0to100, targets.nIndex);
    final pEval = _evalMetric(pIndex0to100, targets.pIndex);
    final kEval = _evalMetric(kIndex0to100, targets.kIndex);

    // ── Scores 0-1 ──
    final double nScore01 = _bandScore(nEval);
    final double pScore01 = _bandScore(pEval);
    final double kScore01 = _bandScore(kEval);
    final double npkScore01 = (nScore01 + pScore01 + kScore01) / 3.0;
    final double soilControlScore01 = _weightedSoilScore(
      moistureScore: _bandScore(moistureEval),
      resistanceScore: _bandScore(resistanceEval),
      phScore: _bandScore(phEval),
      ecScore: _bandScore(ecEval),
      npkScore: npkScore01,
      weights: weights,
    );

    // ── Construir mapa de métricas ──
    final metrics = <AgroMetricKey, AgroMetricEval>{
      AgroMetricKey.soilMoisture: AgroMetricEval(
        band: moistureEval,
        score01: _bandScore(moistureEval),
        labelEs: _labelEs(moistureEval),
        value: t.soilMoisturePct,
      ),
      AgroMetricKey.soilTemp: AgroMetricEval(
        band: soilTempEval,
        score01: _bandScore(soilTempEval),
        labelEs: _labelEs(soilTempEval),
        value: t.soilTempC,
      ),
      AgroMetricKey.ph: AgroMetricEval(
        band: phEval,
        score01: _bandScore(phEval),
        labelEs: _labelEs(phEval),
        value: t.ph,
      ),
      AgroMetricKey.ec: AgroMetricEval(
        band: ecEval,
        score01: _bandScore(ecEval),
        labelEs: _labelEs(ecEval),
        value: t.ec,
      ),
      AgroMetricKey.resistance: AgroMetricEval(
        band: resistanceEval,
        score01: _bandScore(resistanceEval),
        labelEs: _labelEs(resistanceEval),
        value: t.resistance,
      ),
      AgroMetricKey.n: AgroMetricEval(
        band: nEval,
        score01: nScore01,
        labelEs: _labelEs(nEval),
        value: nIndex0to100,
      ),
      AgroMetricKey.p: AgroMetricEval(
        band: pEval,
        score01: pScore01,
        labelEs: _labelEs(pEval),
        value: pIndex0to100,
      ),
      AgroMetricKey.k: AgroMetricEval(
        band: kEval,
        score01: kScore01,
        labelEs: _labelEs(kEval),
        value: kIndex0to100,
      ),
    };

    // ── Generar sugerencias de alertas ──
    final suggestedAlertKeys = <String>[];
    final isCriticalStage = criticalStageKeys.contains(stageKey);

    _pushAlerts(
      'soilMoisture',
      moistureEval,
      isCriticalStage,
      suggestedAlertKeys,
    );
    _pushAlerts('soilTemp', soilTempEval, isCriticalStage, suggestedAlertKeys);
    _pushAlerts('ph', phEval, isCriticalStage, suggestedAlertKeys);
    _pushAlerts('ec', ecEval, isCriticalStage, suggestedAlertKeys);
    _pushAlerts(
      'resistance',
      resistanceEval,
      isCriticalStage,
      suggestedAlertKeys,
    );
    _pushAlerts('npk.n', nEval, isCriticalStage, suggestedAlertKeys);
    _pushAlerts('npk.p', pEval, isCriticalStage, suggestedAlertKeys);
    _pushAlerts('npk.k', kEval, isCriticalStage, suggestedAlertKeys);

    // ── Mapear etapa cereal → MaizeStageKey para AlertsEngine ──
    final maizeStage = _mapCerealStageToAlertStage(stageKey);

    // ── Construir alertas ──
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

    // ── Resultado ──
    final agroEval = AgroEvalResult(
      soilControlScore01: soilControlScore01,
      metrics: metrics,
      alerts: alertsBuild.alerts,
      suggestedAlertKeys: suggestedAlertKeys,
    );

    return (eval: agroEval, nextAlertsState: alertsBuild.state);
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

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

  /// Aplica calibración por clamp si hay valores min/max de raw.
  static double _calibrateValue(double value, double? minRaw, double? maxRaw) {
    if (minRaw == null && maxRaw == null) return value;
    final lo = minRaw ?? double.negativeInfinity;
    final hi = maxRaw ?? double.infinity;
    return value.clamp(lo, hi);
  }

  /// Evalúa un valor numérico contra un AgroRange y retorna un AgroBand.
  static AgroBand _evalMetric(double value, AgroRange range) {
    if (value < range.lowMax) return AgroBand.low;
    if (value >= range.lowMax && value < range.optimalMin) return AgroBand.low;
    if (value >= range.optimalMin && value <= range.optimalMax) {
      return AgroBand.optimal;
    }
    if (value > range.optimalMax && value <= range.highMin)
      return AgroBand.high;
    if (value > range.highMin) return AgroBand.critical;
    return AgroBand.unknown;
  }

  /// Score (0-1) según la banda.
  static double _bandScore(AgroBand band) {
    switch (band) {
      case AgroBand.optimal:
        return 1.0;
      case AgroBand.low:
      case AgroBand.high:
        return 0.6;
      case AgroBand.critical:
        return 0.2;
      case AgroBand.unknown:
        return 0.5;
    }
  }

  /// Etiqueta en español para la banda.
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
        return 'N/A';
    }
  }

  /// Score ponderado de control edáfico usando StageWeights.
  static double _weightedSoilScore({
    required double moistureScore,
    required double resistanceScore,
    required double phScore,
    required double ecScore,
    required double npkScore,
    required StageWeights weights,
  }) {
    final totalW = math.max(0.0001, weights.sum);
    return (moistureScore * weights.moisture +
            resistanceScore * weights.resistance +
            phScore * weights.ph +
            ecScore * weights.ec +
            npkScore * weights.npk) /
        totalW;
  }

  /// Empuja alert keys según la banda y si es etapa crítica.
  static void _pushAlerts(
    String metricKey,
    AgroBand band,
    bool isCriticalStage,
    List<String> out,
  ) {
    switch (band) {
      case AgroBand.critical:
        out.add('$metricKey.critical');
        break;
      case AgroBand.low:
        out.add('$metricKey.low');
        break;
      case AgroBand.high:
        out.add('$metricKey.high');
        break;
      case AgroBand.optimal:
      case AgroBand.unknown:
        break;
    }
  }

  /// Mapea etapa cereal (string) a MaizeStageKey para AlertsEngine.
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
