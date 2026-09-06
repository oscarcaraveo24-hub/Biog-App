import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/soil_condition_score.dart';
import 'package:bio_g/core/crops/cactus/cactus_lifecycle.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Motor AgroScore del Cactus ornamental.
///
/// Es un ESPEJO ESTRUCTURAL de `BeanAgroScoreEngine`: mismas bandas, mismas
/// claves de alerta, misma señal nativa N/P/K sin diagnóstico. Un cactus se lee, se clasifica y
/// se alerta igual que cualquier otro cultivo de BIO-G. Lo único que cambia es
/// la agronomía (targets bajos, agua dominante) y que la etapa viene del
/// resolver ornamental en lugar de la fecha de siembra.
///
/// Por qué importa: la versión anterior emitía claves propias
/// (`cactus.maintenance.moisture.critical`) que el `AlertsEngine` compartido NO
/// reconoce, así que el cactus NO generaba ninguna alerta. Aquí se usan las
/// claves canónicas (`soilMoisture.critical`, `ph.low`, …) y el
/// agricultor recibe exactamente los mismos mensajes que en frijol.
class CactusAgroScoreEngine {
  const CactusAgroScoreEngine._();

  /// Etapas críticas: la planta acaba de moverse y la raíz aún no trabaja.
  /// Un exceso de agua aquí es lo que la mata.
  static const Set<String> criticalStages = <String>{
    CactusStageIds.installationEstablishment,
    CactusStageIds.rootEstablishment,
  };

  /// Etapas semicríticas.
  static const Set<String> semiCriticalStages = <String>{
    CactusStageIds.rest,
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
  }) {
    final stage = normalizeCactusStageId(stageId);

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

    final moistureEval = _evalLegacy(
      value: moistureRawCal,
      range: targets.moistureRaw,
    );
    final soilTempEval = _evalLegacy(
      value: t.hasSoilTempData ? t.soilTempC : double.nan,
      range: targets.soilTemp,
    );
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
      AgroMetricKey.soilMoisture: _wrapLegacy(
        moistureEval,
        displayValue: moistureRawCal,
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

    double criticalPenalty = 1.0;
    // El exceso de agua es EL riesgo del cactus: pesa más que la falta.
    if (moistureEval.band == AgroBand.critical) {
      criticalPenalty *= moistureRawCal > targets.moistureRaw.optimalMax
          ? 0.40
          : 0.60;
    }
    if (soilTempEval.band == AgroBand.critical) criticalPenalty *= 0.55;
    if (phEval.band == AgroBand.critical) criticalPenalty *= 0.60;
    if (ecEval.band == AgroBand.critical) criticalPenalty *= 0.60;
    // Sustrato compactado = raíz asfixiada y agua retenida en el cuello.
    if (resEval.band == AgroBand.critical) criticalPenalty *= 0.70;

    // Frío + sustrato húmedo: la combinación que pudre la raíz. Castigo extra.
    if (_isColdAndWet(
      soilTempC: t.hasSoilTempData ? t.soilTempC : double.nan,
      moisturePct: moistureRawCal,
      targets: targets,
    )) {
      criticalPenalty *= 0.65;
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

    // Claves CANÓNICAS del AlertsEngine compartido. Mismos mensajes que frijol.
    final suggested = <String>[];
    _pushSoilAlert(suggested, 'soilMoisture', moistureEval, stage);
    _pushSoilAlert(suggested, 'soilTemp', soilTempEval, stage);
    _pushSoilAlert(suggested, 'ph', phEval, stage);
    _pushSoilAlert(suggested, 'ec', ecEval, stage);
    _pushSoilAlert(suggested, 'resistance', resEval, stage);

    _pushEnvironmentalAlerts(suggested, t);

    final severityBump = criticalStages.contains(stage)
        ? 2
        : semiCriticalStages.contains(stage)
        ? 1
        : 0;

    final built = AlertsEngine.buildFromSuggestedKeys(
      deviceId: t.deviceId,
      now: t.timestamp,
      severityBump: severityBump,
      suggestedKeys: suggested,
      prev: alertsState,
      cooldown: alertsCooldown,
      cropLabel: cropLabel ?? 'tu cactus',
      stageLabel: stageLabelEs,
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

  /// Frío con sustrato húmedo. No es una lectura cualquiera: es la causa #1 de
  /// pudrición en cactus.
  static bool _isColdAndWet({
    required double soilTempC,
    required double moisturePct,
    required StageTargets targets,
  }) {
    if (!soilTempC.isFinite || !moisturePct.isFinite) return false;
    final cold = soilTempC <= targets.soilTemp.optimalMin;
    final wet = moisturePct >= targets.moistureRaw.optimalMax;
    return cold && wet;
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

  static void _pushSoilAlert(
    List<String> out,
    String key,
    _Eval e,
    String stage,
  ) {
    final isSensitiveStage =
        criticalStages.contains(stage) || semiCriticalStages.contains(stage);

    if (e.band == AgroBand.critical) {
      out.add('$key.critical');
      return;
    }

    // La humedad ALTA siempre avisa en cactus, en cualquier etapa: es el riesgo
    // que de verdad mata la planta.
    if (key == 'soilMoisture' && e.band == AgroBand.high) {
      out.add('$key.high');
      return;
    }

    if (isSensitiveStage && e.band == AgroBand.low) out.add('$key.low');
    if (isSensitiveStage && e.band == AgroBand.high) out.add('$key.high');
  }

  static void _pushEnvironmentalAlerts(List<String> out, BioGTelemetry t) {
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

    if (airTemp <= 0) {
      out.add('airTemp.frost');
    } else if (airTemp < 4) {
      out.add('airTemp.cold');
    }

    // El cactus aguanta MUCHO más calor que un cultivo anual: umbrales altos.
    if (airTemp > 45) {
      out.add('airTemp.extreme_heat');
    } else if (airTemp > 40) {
      out.add('airTemp.heat');
    }

    // Humedad ambiental alta sostenida favorece pudrición y hongos.
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
