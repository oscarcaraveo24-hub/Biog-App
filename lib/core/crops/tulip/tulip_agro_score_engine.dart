import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/soil_condition_score.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/tulip_models.dart';
import 'package:bio_g/widgets/seeds/tulip_profiles.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Motor AgroScore del Tulipán (modo `seasonal_bulb`).
///
/// ESPEJO ESTRUCTURAL de `RoseAgroScoreEngine`: mismas bandas, mismas claves
/// de alerta CANÓNICAS (`soilMoisture.critical`, `ph.low`, …),
/// misma señal nativa N/P/K sin diagnóstico. Un tulipán se lee, clasifica y alerta igual que
/// cualquier cultivo de BIO-G. Lo propio del tulipán son sus castigos
/// (Documento B §12) y su doctrina: el agua y la temperatura gobiernan; el NPK
/// acompaña; la EC baja no es defecto.
///
/// Contrato (Documento B §14): claves SIEMPRE canónicas, NUNCA `tulip.*` ni
/// `seasonalBulb.*`. Orden maestro: Humedad → Temperatura → EC → pH →
/// Resistencia → NPK. La EC nunca se sugiere como alerta baja (§14.1).
class TulipAgroScoreEngine {
  const TulipAgroScoreEngine._();

  /// Etapas críticas (severityBump = 2): frío/enraizado y ventanas de tallo,
  /// botón y flor (Documento B §13.1).
  static const Set<String> criticalStages = <String>{
    TulipStageIds.rootingChilling,
    TulipStageIds.stemElongation,
    TulipStageIds.budFormation,
    TulipStageIds.flowering,
  };

  /// Etapas semicríticas (severityBump = 1): plantación, emergencia y recarga
  /// (Documento B §13.2).
  static const Set<String> semiCriticalStages = <String>{
    TulipStageIds.bulbPlanting,
    TulipStageIds.shootEmergence,
    TulipStageIds.bulbRecharge,
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
    final stage = normalizeTulipStageId(stageId);
    final bool isPremium =
        profileId?.trim().toLowerCase() == kTu05SpecialPremium;

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

    final moistureEval = _evalLegacy(value: moistureRawCal, range: targets.moistureRaw);
    final soilTempEval = _evalLegacy(value: t.hasSoilTempData ? t.soilTempC : double.nan, range: targets.soilTemp);
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
      AgroMetricKey.soilMoisture: _wrapLegacy(moistureEval, displayValue: moistureRawCal),
      AgroMetricKey.soilTemp: _wrapLegacy(soilTempEval, displayValue: t.hasSoilTempData ? t.soilTempC : null),
      AgroMetricKey.ph: _wrapLegacy(phEval, displayValue: t.hasPhData ? t.ph : null),
      AgroMetricKey.ec: _wrapLegacy(ecEval, displayValue: t.hasEcData ? t.ec : null),
      AgroMetricKey.resistance: _wrapLegacy(resEval, displayValue: t.hasResistanceData ? t.resistance : null),
      AgroMetricKey.n: nMetric,
      AgroMetricKey.p: pMetric,
      AgroMetricKey.k: kMetric,
    };

    // ── Castigos del AgroScore (Documento B §12), en el orden de §12.8 ────────
    double penalty = 1.0;

    final bool moistureExcess = moistureRawCal > targets.moistureRaw.optimalMax;

    // §12.1 / §12.2 — humedad crítica (exceso vs. déficit, por etapa).
    if (moistureEval.band == AgroBand.critical) {
      penalty *= moistureExcess
          ? _moistureExcessPenalty(stage)
          : _moistureDeficitPenalty(stage);
    }

    // §12.4 — temperatura crítica (con matiz de calor por etapa y premium).
    if (soilTempEval.band == AgroBand.critical) {
      final bool heat = t.soilTempC > targets.soilTemp.optimalMax;
      penalty *= _tempCriticalPenalty(stage, heat: heat, isPremium: isPremium);
    }

    // §12.3 — combinación frío + húmedo (bulbo enterrado). V1 asume el bulbo
    // bajo la sonda; la excepción "bulbo levantado" queda para una versión con
    // dormancyMode persistido.
    // `isFinite` no basta: 0.0 es finito, y es justo lo que rellena la
    // telemetría cuando la sonda de temperatura de suelo no reportó. Sin la
    // bandera, un bulbo enterrado entraría en la combinación frío+húmedo por un
    // canal que no existió.
    if (t.hasSoilTempData &&
        t.soilTempC.isFinite &&
        moistureRawCal.isFinite &&
        t.soilTempC <= 5) {
      final bool criticalHighMoisture =
          moistureEval.band == AgroBand.critical && moistureExcess;
      final bool highMoisture = moistureEval.band == AgroBand.high;
      const Set<String> buriedStages = <String>{
        TulipStageIds.bulbPlanting,
        TulipStageIds.rootingChilling,
        TulipStageIds.dormancy,
      };
      if (criticalHighMoisture && buriedStages.contains(stage)) {
        penalty *= 0.55;
      } else if (highMoisture) {
        penalty *= 0.78;
      }
    }

    // §12.5 — pH, EC y resistencia críticas.
    if (phEval.band == AgroBand.critical) penalty *= 0.62;
    if (ecEval.band == AgroBand.critical) penalty *= 0.50;
    if (resEval.band == AgroBand.critical) penalty *= 0.68;

    // §12.6 — NPK. El nitrógeno en exceso castiga más que P o K.

    // §12.7 — cumplimiento de frío histórico: `unknown` → ×1.00. V1 no cuenta
    // acumulación de frío (sin historial suficiente); no se castiga al usuario
    // por no tenerlo. Sin cambio.

    // ── Condición del suelo: solo señales físicas presentes ─────────────────
    //
    // Los pesos de N/P/K del perfil no entran (peso cero por decisión) y una
    // señal ausente sale del denominador en vez de valer 0 o 0.5. La
    // cobertura de evidencia viaja aparte. Ver `SoilConditionScore`.
    final SoilConditionScoreResult soil = SoilConditionScore.compute(
      metrics: metrics,
      weights: weights,
      criticalPenalty: penalty,
    );

    // Claves CANÓNICAS del AlertsEngine compartido (nunca `tulip.*`).
    final suggested = <String>[];
    _pushSoilAlert(suggested, 'soilMoisture', moistureEval, stage);
    _pushSoilAlert(suggested, 'soilTemp', soilTempEval, stage);
    _pushSoilAlert(suggested, 'ph', phEval, stage);
    _pushSoilAlert(suggested, 'ec', ecEval, stage);
    _pushSoilAlert(suggested, 'resistance', resEval, stage);

    _pushEnvironmentalAlerts(suggested, t, stage);

    // Severidad por etapa (Documento B §13): crítica 2, semicrítica 1, resto 0.
    // La senescencia normal y la dormancia NO deben parecer emergencia.
    final int severityBump = criticalStages.contains(stage)
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
      cropLabel: cropLabel ?? 'tu tulipán',
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

  // ── Castigos por etapa (Documento B §12.1, §12.2, §12.4) ──────────────────

  static double _moistureExcessPenalty(String stage) {
    switch (stage) {
      case TulipStageIds.bulbPlanting:
      case TulipStageIds.rootingChilling:
      case TulipStageIds.dormancy:
        return 0.38;
      case TulipStageIds.shootEmergence:
      case TulipStageIds.vegetativeGrowth:
      case TulipStageIds.stemElongation:
        return 0.45;
      case TulipStageIds.budFormation:
      case TulipStageIds.flowering:
      case TulipStageIds.bulbRecharge:
        return 0.42;
      case TulipStageIds.foliageSenescence:
        return 0.48;
      default:
        return 0.42;
    }
  }

  static double _moistureDeficitPenalty(String stage) {
    switch (stage) {
      case TulipStageIds.bulbPlanting:
      case TulipStageIds.rootingChilling:
      case TulipStageIds.shootEmergence:
        return 0.60;
      case TulipStageIds.vegetativeGrowth:
      case TulipStageIds.bulbRecharge:
        return 0.55;
      case TulipStageIds.stemElongation:
      case TulipStageIds.budFormation:
      case TulipStageIds.flowering:
        return 0.48;
      case TulipStageIds.foliageSenescence:
      case TulipStageIds.dormancy:
        return 0.75;
      default:
        return 0.60;
    }
  }

  static double _tempCriticalPenalty(
    String stage, {
    required bool heat,
    required bool isPremium,
  }) {
    switch (stage) {
      case TulipStageIds.rootingChilling:
        return 0.45;
      case TulipStageIds.stemElongation:
        return heat ? 0.52 : 0.58;
      case TulipStageIds.budFormation:
        return heat ? 0.50 : 0.58;
      case TulipStageIds.flowering:
        // Flores dobles/premium son más frágiles al calor en floración.
        return heat ? (isPremium ? 0.45 : 0.50) : 0.58;
      case TulipStageIds.foliageSenescence:
      case TulipStageIds.dormancy:
        return 0.75;
      default:
        return 0.58;
    }
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
      // La EC baja NUNCA es crítica (`lowMax = -1`); una EC crítica solo puede
      // venir por acumulación de sales (lado alto).
      out.add('$key.critical');
      return;
    }

    // La humedad ALTA siempre avisa: el exceso de agua es el riesgo principal
    // del bulbo (Documento B §1, §2).
    if (key == 'soilMoisture' && e.band == AgroBand.high) {
      out.add('$key.high');
      return;
    }

    // EC baja NO se sugiere como alerta (Documento B §14.1): un sustrato limpio
    // puede tener EC baja sin ser deficiencia.
    if (key == 'ec' && e.band == AgroBand.low) return;

    if (isSensitiveStage && e.band == AgroBand.low) out.add('$key.low');
    if (isSensitiveStage && e.band == AgroBand.high) out.add('$key.high');
  }

  /// Alertas ambientales (Documento B §4.2, §15). El calor acorta la flor; la
  /// humedad ambiental alta sostenida favorece problemas foliares y de flor. No
  /// sobre-alarma el frío cuando la planta está en senescencia o dormancia.
  static void _pushEnvironmentalAlerts(
    List<String> out,
    BioGTelemetry t,
    String stage,
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

    final bool dormantOrClosing =
        stage == TulipStageIds.dormancy ||
        stage == TulipStageIds.foliageSenescence;

    if (airTemp <= 0) {
      out.add('airTemp.frost');
    } else if (airTemp <= 5 && !dormantOrClosing) {
      out.add('airTemp.cold');
    }

    if (airTemp >= 38) {
      out.add('airTemp.extreme_heat');
    } else if (airTemp >= 26) {
      out.add('airTemp.heat');
    }

    // Humedad ambiental alta solo pesa mientras hay follaje/flor activos.
    if (!dormantOrClosing) {
      if (airHum >= 90) {
        out.add('airHumidity.critical');
      } else if (airHum >= 80) {
        out.add('airHumidity.high');
      }
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
