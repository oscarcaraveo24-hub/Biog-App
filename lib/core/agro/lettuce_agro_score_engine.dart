import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/soil_condition_score.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/crops/lettuce/lettuce_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/lettuce_models.dart';

/// AgroScore específico para lechuga (`CropKey.lettuce`).
///
/// Sigue el patrón de calabaza/berenjena, con diferencias propias de una
/// hortaliza de hoja:
///  - Formación de cabeza (E4) y ventana de cosecha (E5) son la ventana
///    CRÍTICA: ahí se decide turgencia, calidad y oportunidad de corte.
///  - El espigado (bolting) NO es etapa: se evalúa como evento de falla
///    [LettuceBoltingRisk] y puede sobreescribir el mensaje de cosecha.
///  - Salinidad es sensibilidad ALTA (cultivo sensible).
///  - No hay floración, amarre ni llenado de fruto que evaluar.
class LettuceAgroScoreEngine {
  static const Set<LettuceStageKey> _criticalStages = {
    LettuceStageKey.formacionCabeza,
    LettuceStageKey.ventanaCosecha,
  };

  static const Set<LettuceStageKey> _semiCriticalStages = {
    LettuceStageKey.desarrolloVegetativo,
    LettuceStageKey.sobremadurez,
  };

  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluate({
    required BioGTelemetry t,
    required LettuceStageResult stage,
    required LettuceUniversalProfile u,
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

    final moistureEval =
        _evalLegacy(value: moistureRawCal, range: targets.moistureRaw);
    final soilTempEval =
        _evalLegacy(value: t.hasSoilTempData ? t.soilTempC : double.nan, range: targets.soilTemp);
    final phEval = _evalLegacy(value: t.hasPhData ? t.ph : double.nan, range: targets.ph);
    final ecEval = _evalLegacy(value: t.hasEcData ? t.ec : double.nan, range: targets.ec);
    final resEval = _evalLegacy(value: t.hasResistanceData ? t.resistance : double.nan, range: targets.resistance);

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
      AgroMetricKey.soilMoisture:
          _wrapLegacy(moistureEval, displayValue: t.hasSoilMoistureData ? moistureRawCal : null),
      AgroMetricKey.soilTemp:
          _wrapLegacy(soilTempEval, displayValue: t.hasSoilTempData ? t.soilTempC : null),
      AgroMetricKey.ph: _wrapLegacy(phEval, displayValue: t.hasPhData ? t.ph : null),
      AgroMetricKey.ec: _wrapLegacy(ecEval, displayValue: t.hasEcData ? t.ec : null),
      AgroMetricKey.resistance:
          _wrapLegacy(resEval, displayValue: t.hasResistanceData ? t.resistance : null),
      AgroMetricKey.n: nMetric,
      AgroMetricKey.p: pMetric,
      AgroMetricKey.k: kMetric,
    };

    // Penalizaciones críticas: en formación de cabeza y cosecha el agua,
    // la temperatura y la salinidad pesan más (ventana de calidad §9).
    double criticalPenalty = 1.0;
    if (moistureEval.band == AgroBand.critical) criticalPenalty *= 0.40;
    if (soilTempEval.band == AgroBand.critical) criticalPenalty *= 0.50;
    if (phEval.band == AgroBand.critical) criticalPenalty *= 0.58;
    if (ecEval.band == AgroBand.critical) criticalPenalty *= 0.52;
    if (resEval.band == AgroBand.critical) criticalPenalty *= 0.80;

    // El espigado degrada el valor comercial: penaliza el score directo.
    final boltingRisk = computeBoltingRisk(
      airTempC: t.hasAirTempData ? t.airTempC : double.nan,
      moistureRawCal: moistureRawCal,
      stage: stageKey,
      moistureBand: targets.moistureRaw,
    );
    switch (boltingRisk) {
      case LettuceBoltingRisk.critico:
        criticalPenalty *= 0.55;
        break;
      case LettuceBoltingRisk.alto:
        criticalPenalty *= 0.74;
        break;
      case LettuceBoltingRisk.medio:
        criticalPenalty *= 0.90;
        break;
      case LettuceBoltingRisk.bajo:
        break;
    }

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

    final suggested = <String>[];
    _pushLegacyAlertsForMetric(suggested, 'soilMoisture', moistureEval, stageKey);
    _pushLegacyAlertsForMetric(suggested, 'soilTemp', soilTempEval, stageKey);
    _pushLegacyAlertsForMetric(suggested, 'ph', phEval, stageKey);
    _pushLegacyAlertsForMetric(suggested, 'ec', ecEval, stageKey);
    _pushLegacyAlertsForMetric(suggested, 'resistance', resEval, stageKey);
    _pushEnvironmentalAlerts(suggested, t, stage, boltingRisk);

    final severityBump = _criticalStages.contains(stageKey)
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
      stageLabel: stage.stageLabelEs,
    );

    final eval = AgroEvalResult(
      soilControlScore01: soil.score01,
      soilCoverage: soil.coverage,
      metrics: metrics,
      alerts: built.alerts,
      suggestedAlertKeys: suggested,
    );

    return (eval: eval, nextAlertsState: built.state);
  }

  /// Evalúa el riesgo de espigado / bolting (evento E7 del Perfil
  /// Universal). Disparadores: calor sostenido, déficit hídrico y edad
  /// fisiológica avanzada. No es una etapa: es una falla de calidad.
  /// [moistureBand] es la banda de humedad ya derivada de la textura del suelo
  /// (`targets.moistureRaw`). El umbral de estrés hídrico sale de ahí.
  ///
  /// Antes era `moistureRawCal < 50` fijo, y eso NO era un umbral: era una
  /// constante encendida. La capacidad de campo más alta de la tabla de suelos
  /// es 40 (arcilla) y su umbral de encharcamiento 47,7, así que **ninguna
  /// lectura de un suelo mineral llega a 50**. El riesgo de espigado subía en
  /// cada lectura válida, para siempre, en cualquier tierra.
  static LettuceBoltingRisk computeBoltingRisk({
    required double airTempC,
    required double moistureRawCal,
    required LettuceStageKey stage,
    AgroRange? moistureBand,
  }) {
    final isQualityStage = stage == LettuceStageKey.formacionCabeza ||
        stage == LettuceStageKey.ventanaCosecha;
    final isExposedStage = isQualityStage ||
        stage == LettuceStageKey.desarrolloVegetativo ||
        stage == LettuceStageKey.sobremadurez;
    if (!isExposedStage) return LettuceBoltingRisk.bajo;
    if (!airTempC.isFinite) return LettuceBoltingRisk.bajo;

    // Por debajo del punto de recarga hay estrés hídrico de verdad: es el mismo
    // límite con el que el resto de la app dice «bajo». Sin banda, el literal
    // viejo queda de respaldo para no cambiar el comportamiento a ciegas.
    final waterStress =
        moistureRawCal > 0 && moistureRawCal < (moistureBand?.optimalMin ?? 50);

    if (airTempC >= 30 && isQualityStage) return LettuceBoltingRisk.critico;
    if (airTempC >= 30) return LettuceBoltingRisk.alto;
    if (airTempC > 28 && (isQualityStage || waterStress)) {
      return LettuceBoltingRisk.alto;
    }
    if (airTempC > 28) return LettuceBoltingRisk.medio;
    if (airTempC > 25 && isQualityStage && waterStress) {
      return LettuceBoltingRisk.medio;
    }
    return LettuceBoltingRisk.bajo;
  }

  static AgroMetricEval _wrapLegacy(_Eval e, {required double? displayValue}) {
    return AgroMetricEval(
      band: e.band,
      score01: e.score01,
      labelEs: e.band.labelEs,
      value: displayValue,
    );
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

    final score01 =
        _scoreFromLegacyRange(value, lowMax, optMin, optMax, highMin);
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
    }

    final span = math.max(1e-6, (highMin - optMax).abs());
    final d = (v - highMin) / span;
    return (0.35 / (1 + d)).clamp(0.05, 0.35);
  }

  static void _pushLegacyAlertsForMetric(
    List<String> out,
    String key,
    _Eval e,
    LettuceStageKey stage,
  ) {
    final isSensitiveStage =
        _criticalStages.contains(stage) || _semiCriticalStages.contains(stage);

    if (e.band == AgroBand.critical) {
      out.add('$key.critical');
      return;
    }

    if (isSensitiveStage && e.band == AgroBand.low) out.add('$key.low');
    if (isSensitiveStage && e.band == AgroBand.high) out.add('$key.high');
  }

  /// Alertas ambientales y de oportunidad específicas de lechuga.
  ///
  /// Prioriza: calor sostenido (acelera espigado y amargor), espigado
  /// inminente/confirmado, HR alta (mildiu/Botrytis/tip burn) y la
  /// ventana de cosecha (revisión 3-7 días antes, corte oportuno).
  static void _pushEnvironmentalAlerts(
    List<String> out,
    BioGTelemetry t,
    LettuceStageResult stage,
    LettuceBoltingRisk boltingRisk,
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
    final isQualityStage = _criticalStages.contains(stage.stage);

    // Frío / helada: la lechuga es de estación fresca, pero la helada
    // aún daña hoja y favorece eventos de estrés.
    if (airTemp <= 0) {
      out.add('airTemp.frost');
    } else if (airTemp < 4) {
      out.add('airTemp.cold');
    }

    // Calor: >28 °C sostenido es alerta; >30 °C es crítico para lechuga.
    if (airTemp > 30) {
      out.add('airTemp.extreme_heat');
    } else if (airTemp > 28 || (isQualityStage && airTemp > 27)) {
      out.add('airTemp.heat');
    }

    // HR alta favorece mildiu velloso, Botrytis y tip burn.
    if (airHum > 90) {
      out.add('airHumidity.critical');
    } else if (airHum > 85) {
      out.add('airHumidity.high');
    }

    // Espigado / bolting (evento E7). Sobreescribe el tono de cosecha.
    switch (boltingRisk) {
      case LettuceBoltingRisk.critico:
        out.add('lettuce.bolting_critical');
        break;
      case LettuceBoltingRisk.alto:
        out.add('lettuce.bolting_warning');
        break;
      case LettuceBoltingRisk.medio:
      case LettuceBoltingRisk.bajo:
        break;
    }

    // Ventana de cosecha y revisión de campo.
    if (stage.stage == LettuceStageKey.ventanaCosecha) {
      final urgentByHeatOrBolting = airTemp > 28 ||
          boltingRisk == LettuceBoltingRisk.alto ||
          boltingRisk == LettuceBoltingRisk.critico;
      out.add(urgentByHeatOrBolting
          ? 'lettuce.harvest_urgent'
          : 'lettuce.harvest_window');
    } else if (stage.stage == LettuceStageKey.sobremadurez) {
      out.add('lettuce.harvest_past');
    } else if (stage.daysToHarvestMin > 0 && stage.daysToHarvestMin <= 7) {
      out.add('lettuce.harvest_review');
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
