import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/soil_condition_score.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/marigold/marigold_universal_profile.dart';
import 'package:bio_g/widgets/seeds/marigold_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Motor AgroScore del Cempasúchil (modo `annual_ornamental`).
///
/// ESPEJO ESTRUCTURAL de `SunflowerAgroScoreEngine` / `TulipAgroScoreEngine`:
/// mismas bandas, mismas claves de alerta CANÓNICAS (`soilMoisture.critical`,
/// `ph.low`, …), sin claves `npk.*` desde el NPK Interpretation Reset. Un
/// cempasúchil se lee, clasifica y alerta igual que cualquier cultivo de BIO-G.
/// Lo propio del Cempasúchil son sus castigos (Documento B §16), sus
/// multiplicadores por perfil (§15) y su doctrina: el agua manda; el NPK
/// acompaña; el exceso de N favorece follaje y retrasa la floración.
///
/// Contrato (Documento B §1.4): claves SIEMPRE canónicas, NUNCA `marigold.*` ni
/// `cempasuchil.*`. Orden maestro: Humedad → Temperatura → EC → pH →
/// Resistencia → NPK. La tarjeta de Resistencia se conserva; la EC se evalúa
/// internamente y no la reemplaza. La luz y el fotoperiodo NO son métricas de
/// la sonda y por eso NO generan clave ni modifican el score (§19.1, §24.4).
/// En `cycle_complete` el motor hace BYPASS: cero alertas, cero prioridad
/// nutrimental (§21, §24.3).
class MarigoldAgroScoreEngine {
  const MarigoldAgroScoreEngine._();

  /// Etapas críticas (severityBump = 2): germinación, emergencia, botón y flor
  /// (Documento B §17).
  static const Set<String> criticalStages = <String>{
    MarigoldStageIds.germination,
    MarigoldStageIds.emergence,
    MarigoldStageIds.budFormation,
    MarigoldStageIds.flowering,
  };

  /// Etapas semicríticas (severityBump = 1): siembra, plántula y alargamiento
  /// del tallo, más la banda por confirmar (Documento B §17).
  static const Set<String> semiCriticalStages = <String>{
    MarigoldStageIds.sowing,
    MarigoldStageIds.earlyVegetativeGrowth,
    MarigoldStageIds.stemElongation,
    MarigoldStageIds.unknown,
  };

  // Las etapas de riesgo por N alto y las de demanda de N/P/K (Documento B
  // §16.1, §16.2) ya no viven en el motor de score: con el NPK Interpretation
  // Reset (Guía v0.4, §4) la etiqueta NPK cruda dejó de castigar el score, y
  // ese conocimiento fenológico se expresa en la guía de nutrición del
  // cempasúchil, donde la etapa —no la sonda— decide la prioridad.

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
    final stage = normalizeMarigoldStageId(stageId);
    final ctx = marigoldAgroContextForProfile(profileId);
    final bool isTraditional = ctx == MarigoldAgroContext.traditionalField;
    final bool isCutFlower = ctx == MarigoldAgroContext.tallCutFlower;
    final bool isCompact = ctx == MarigoldAgroContext.compactContainer;
    final bool isLandscape = ctx == MarigoldAgroContext.landscapeBedding;

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
      AgroMetricKey.soilMoisture: _wrapLegacy(
        moistureEval,
        displayValue: moistureRawCal,
      ),
      AgroMetricKey.soilTemp: _wrapLegacy(soilTempEval, displayValue: t.hasSoilTempData ? t.soilTempC : null),
      AgroMetricKey.ph: _wrapLegacy(phEval, displayValue: t.hasPhData ? t.ph : null),
      AgroMetricKey.ec: _wrapLegacy(ecEval, displayValue: t.hasEcData ? t.ec : null),
      AgroMetricKey.resistance: _wrapLegacy(resEval, displayValue: t.hasResistanceData ? t.resistance : null),
      AgroMetricKey.n: nMetric,
      AgroMetricKey.p: pMetric,
      AgroMetricKey.k: kMetric,
    };

    // ── BYPASS TERMINAL: cycle_complete no tiene manejo activo (Documento B
    // §21, §24.3). Las tarjetas conservan sus bandas para el historial, pero NO
    // se emiten alertas ni prioridad nutrimental. ────────────────────────────
    if (stage == MarigoldStageIds.cycleComplete) {
      final evalDone = AgroEvalResult(
        soilControlScore01: 1.0,
        metrics: metrics,
        alerts: const <BioGAlert>[],
        suggestedAlertKeys: const <String>[],
      );
      return (eval: evalDone, nextAlertsState: alertsState);
    }

    // ── Castigos del AgroScore (Documento B §16), en el orden maestro ─────────
    double penalty = 1.0;

    final bool moistureExcess = moistureRawCal > targets.moistureRaw.optimalMax;
    final bool moistureDeficit =
        moistureRawCal.isFinite &&
        moistureRawCal < targets.moistureRaw.optimalMin;
    final bool ecHigh =
        ecEval.band == AgroBand.high || ecEval.band == AgroBand.critical;
    final bool resHigh =
        resEval.band == AgroBand.high || resEval.band == AgroBand.critical;
    final bool moistureHigh =
        moistureEval.band == AgroBand.high ||
        (moistureEval.band == AgroBand.critical && moistureExcess);

    final bool isBudOrFlower =
        stage == MarigoldStageIds.budFormation ||
        stage == MarigoldStageIds.flowering;
    final bool isGermOrEmergence =
        stage == MarigoldStageIds.germination ||
        stage == MarigoldStageIds.emergence;

    // Bumps adicionales de severidad (Documento B §17). Se acumulan sobre el
    // bump de etapa y se limitan a 2 para no duplicar el mismo daño.
    int extraBump = 0;

    // §16.1 — humedad crítica (exceso vs. déficit, por etapa).
    if (moistureEval.band == AgroBand.critical) {
      if (moistureExcess) {
        double f = _moistureExcessPenalty(stage);
        // §16.2 — CS-03 + humedad crítica alta ×0.85; §30.3 waterlogging ×1.15.
        if (isCompact) f = _amplify(f, 1.15) * 0.85;
        penalty *= f;
        if (isCompact) extraBump += 1;
      } else {
        double f = _moistureDeficitPenalty(stage);
        // §15 — el déficit en botón/flor pesa más en campo, corte y paisaje.
        if (isBudOrFlower) {
          if (isTraditional || isCutFlower) {
            f = _amplify(f, 1.05);
          } else if (isLandscape) {
            f = _amplify(f, 1.03);
          }
        }
        penalty *= f;
      }
    }

    // §16.1 — temperatura de suelo crítica.
    if (soilTempEval.band == AgroBand.critical) {
      double f = _tempCriticalPenalty(stage);
      // §15 CS-03 — el calor de maceta castiga más.
      final bool soilTempHigh = t.soilTempC.isFinite &&
          t.soilTempC > targets.soilTemp.optimalMax;
      if (isCompact && soilTempHigh) f = _amplify(f, 1.10);
      penalty *= f;
    }

    // §16.1 — pH, EC y resistencia críticas.
    if (phEval.band == AgroBand.critical) penalty *= 0.65;

    if (ecEval.band == AgroBand.critical) {
      double f = _isSeedOrSeedling(stage) ? 0.55 : 0.60;
      // §15 CS-03 — sales en maceta ×1.15; §16.2 — CS-03 + EC crítica ×0.84.
      if (isCompact) {
        f = _amplify(f, 1.15) * 0.84;
        extraBump += 1;
      }
      penalty *= f;
    }

    if (resEval.band == AgroBand.critical) {
      double f = _resistanceCriticalPenalty(stage);
      // §15 CS-02 — anclaje y tallo largo desde alargamiento; §16.2 ×0.90.
      final bool stemOnward = _stemOnwardStages.contains(stage);
      if (isCutFlower && stemOnward) {
        f = _amplify(f, 1.10) * 0.90;
        extraBump += 1;
      } else if (isTraditional && _isSeedOrSeedling(stage)) {
        // §15 CS-01 — resistencia alta durante establecimiento.
        f = _amplify(f, 1.05);
      }
      penalty *= f;
    }

    // §16.1 — NPK. El castigo por exceso/acumulación/deficiencia que salía de la
    // etiqueta NPK cruda se retiró con el NPK Interpretation Reset (Guía v0.4,
    // §4): la sonda deriva N/P/K de la conductividad y no puede afirmar ni
    // exceso ni falta. La sensibilidad del cempasúchil al N alto en
    // alargamiento/botón sigue viva donde puede afirmarse: en su guía de
    // nutrición por etapa.

    // §16.2 — combinaciones de riesgo. No se duplica el mismo daño: cada
    // combinación aparece una sola vez.
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

    if (isBudOrFlower &&
        airTemp.isFinite &&
        airTemp > MarigoldUniversalProfile.airHeatMinC &&
        moistureDeficit) {
      penalty *= 0.58; // calor + humedad baja en botón/floración.
      extraBump += 1;
    }
    if (isGermOrEmergence &&
        airTemp.isFinite &&
        airTemp < MarigoldUniversalProfile.airColdMaxC &&
        moistureHigh) {
      penalty *= 0.60; // frío + humedad alta en germinación/emergencia.
      extraBump += 1;
    }
    if (ecHigh && moistureDeficit) {
      penalty *= 0.70; // EC alta + humedad baja.
    } else if (ecHigh && moistureHigh) {
      penalty *= 0.68; // EC alta + humedad alta.
    }
    if (resHigh && moistureDeficit) {
      penalty *= 0.75; // resistencia alta + humedad baja.
    }
    if (stage == MarigoldStageIds.flowering &&
        moistureHigh &&
        airHum.isFinite &&
        airHum >= MarigoldUniversalProfile.airHumidityHighPct) {
      // Humedad alta + HR ambiental alta en floración. En cama densa (CS-04)
      // el riesgo de follaje mojado sube (§15 CS-04, §16.2).
      penalty *= isLandscape ? 0.68 * 0.90 : 0.68;
    }
    // §16.2 — no multiplicar indefinidamente: piso 0.08 (§26.9).
    penalty = penalty.clamp(0.08, 1.00);

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

    // Claves CANÓNICAS del AlertsEngine compartido (nunca `marigold.*`).
    final suggested = <String>[];
    _pushSoilAlert(suggested, 'soilMoisture', moistureEval, stage);
    _pushSoilAlert(suggested, 'soilTemp', soilTempEval, stage);
    _pushSoilAlert(suggested, 'ph', phEval, stage);
    _pushSoilAlert(suggested, 'ec', ecEval, stage);
    _pushSoilAlert(suggested, 'resistance', resEval, stage);

    _pushEnvironmentalAlerts(suggested, t, stage);

    // Severidad por etapa (Documento B §17): crítica 2, semicrítica 1, resto 0,
    // más los bumps de combinación. Techo 2 para no duplicar (§16.2).
    final int stageBump = criticalStages.contains(stage)
        ? 2
        : semiCriticalStages.contains(stage)
        ? 1
        : 0;
    final int severityBump = math.min(2, stageBump + extraBump);

    final built = AlertsEngine.buildFromSuggestedKeys(
      deviceId: t.deviceId,
      now: t.timestamp,
      severityBump: severityBump,
      suggestedKeys: suggested,
      prev: alertsState,
      cooldown: alertsCooldown,
      cropLabel: cropLabel ?? 'tu cempasúchil',
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

  // ── Castigos por etapa (Documento B §16.1) ────────────────────────────────

  static const Set<String> _stemOnwardStages = <String>{
    MarigoldStageIds.stemElongation,
    MarigoldStageIds.budFormation,
    MarigoldStageIds.flowering,
    MarigoldStageIds.postBloom,
    MarigoldStageIds.senescence,
  };

  static bool _isSeedOrSeedling(String stage) =>
      stage == MarigoldStageIds.sowing ||
      stage == MarigoldStageIds.germination ||
      stage == MarigoldStageIds.emergence;

  /// Amplifica un castigo: convierte "severidad ×m" (Documento B §15) en un
  /// factor. El DAÑO (1 - factor) crece m veces; el resultado se acota para no
  /// producir un castigo desproporcionado por un solo modificador de perfil.
  static double _amplify(double factor, double multiplier) {
    final damage = (1.0 - factor) * multiplier;
    return (1.0 - damage).clamp(0.05, 1.0);
  }


  /// §16.1 — humedad crítica por DÉFICIT. Botón y floración son las ventanas
  /// más sensibles (×0.56); el resto de las etapas activas usa ×0.63. En
  /// senescencia el déficit ya no es un daño equivalente.
  static double _moistureDeficitPenalty(String stage) {
    switch (stage) {
      case MarigoldStageIds.budFormation:
      case MarigoldStageIds.flowering:
        return 0.56;
      case MarigoldStageIds.senescence:
        return 0.80;
      case MarigoldStageIds.postBloom:
        return 0.70;
      default:
        return 0.63;
    }
  }

  /// §16.1 — humedad crítica por EXCESO. Germinación y emergencia son las más
  /// sensibles a la saturación (×0.42); el resto de las etapas activas ×0.48.
  static double _moistureExcessPenalty(String stage) {
    switch (stage) {
      case MarigoldStageIds.germination:
      case MarigoldStageIds.emergence:
        return 0.42;
      case MarigoldStageIds.senescence:
        return 0.70;
      default:
        return 0.48;
    }
  }

  /// §16.1 — temperatura de suelo crítica.
  static double _tempCriticalPenalty(String stage) {
    switch (stage) {
      case MarigoldStageIds.germination:
      case MarigoldStageIds.emergence:
        return 0.52;
      case MarigoldStageIds.budFormation:
      case MarigoldStageIds.flowering:
        return 0.55;
      default:
        return 0.60;
    }
  }

  /// §16.1 — resistencia crítica: establecimiento ×0.67, planta desarrollada
  /// ×0.72.
  static double _resistanceCriticalPenalty(String stage) {
    switch (stage) {
      case MarigoldStageIds.sowing:
      case MarigoldStageIds.germination:
      case MarigoldStageIds.emergence:
      case MarigoldStageIds.earlyVegetativeGrowth:
        return 0.67;
      default:
        return 0.72;
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
      // La EC baja NUNCA es crítica (banda baja informativa); una EC crítica
      // solo viene por acumulación de sales (lado alto) (Documento B §8, §22.4).
      out.add('$key.critical');
      return;
    }

    // La humedad ALTA siempre avisa: el exceso de agua es un riesgo prioritario
    // (Documento B §3.1, §5).
    if (key == 'soilMoisture' && e.band == AgroBand.high) {
      out.add('$key.high');
      return;
    }

    // EC baja NO se sugiere como alerta (Documento B §8 reglas, §22.4): un
    // sustrato limpio puede tener EC baja sin ser deficiencia.
    if (key == 'ec' && e.band == AgroBand.low) return;

    if (isSensitiveStage && e.band == AgroBand.low) out.add('$key.low');
    if (isSensitiveStage && e.band == AgroBand.high) out.add('$key.high');
  }

  /// Alertas ambientales (Documento B §18). El frío y el calor elevan la
  /// vigilancia; la humedad ambiental alta favorece problemas de flor durante
  /// botón y floración. No sobre-alarma cuando la planta ya está cerrando el
  /// ciclo.
  static void _pushEnvironmentalAlerts(
    List<String> out,
    BioGTelemetry t,
    String stage,
  ) {
    // NaN y no cero cuando el canal no midió: toda comparación ordenada con
    // NaN es falsa, así que la combinación de riesgo se apaga entera en vez de
    // dispararse con un 0.0 sintetizado. Ver la nota larga en el bloque de
    // alertas ambientales de este mismo archivo.
    final airTemp = t.hasAirTempData ? t.airTempC : double.nan;
    final airHum = t.hasAirHumidityData ? t.airHumidityPct : double.nan;

    final bool closing = stage == MarigoldStageIds.senescence;
    final bool budOrFlower =
        stage == MarigoldStageIds.budFormation ||
        stage == MarigoldStageIds.flowering;

    if (airTemp.isFinite) {
      if (airTemp <= MarigoldUniversalProfile.airFrostMaxC) {
        out.add('airTemp.frost');
      } else if (airTemp < MarigoldUniversalProfile.airColdMaxC && !closing) {
        out.add('airTemp.cold');
      }

      if (airTemp > MarigoldUniversalProfile.airExtremeHeatMinC) {
        out.add('airTemp.extreme_heat');
      } else if (airTemp > MarigoldUniversalProfile.airHeatMinC) {
        out.add('airTemp.heat');
      } else if (budOrFlower && airTemp > 30) {
        // Botón y flor pierden calidad antes que el resto de la planta
        // (Documento B §6, §18.1).
        out.add('airTemp.heat');
      }
    }

    // Humedad ambiental alta solo pesa mientras hay follaje/flor activos.
    if (!closing && airHum.isFinite) {
      if (airHum >= MarigoldUniversalProfile.airHumidityCriticalPct) {
        out.add('airHumidity.critical');
      } else if (airHum >= MarigoldUniversalProfile.airHumidityHighPct) {
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
