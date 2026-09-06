import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/soil_condition_score.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/crops/onion/onion_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/onion_models.dart';

/// AgroScore especifico para cebolla (`CropKey.onion`).
///
/// Agua, temperatura, salinidad, fotoperiodo y calidad de bulbo pesan mas
/// que volumen de hoja. El espigado se trata como evento de perdida
/// comercial, no como floracion. La etapa critica es induccion ->
/// llenado de bulbo -> maduracion/cuello.
class OnionAgroScoreEngine {
  static const Set<OnionStageKey> _criticalStages = {
    OnionStageKey.induccionBulbificacion,
    OnionStageKey.inicioBulbo,
    OnionStageKey.llenadoBulbo,
    OnionStageKey.maduracionCosecha,
    OnionStageKey.espigado,
  };

  static const Set<OnionStageKey> _semiCriticalStages = {
    OnionStageKey.vegetativo,
  };

  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluate({
    required BioGTelemetry t,
    required OnionStageResult stage,
    required OnionUniversalProfile u,
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

    double criticalPenalty = 1.0;
    if (moistureEval.band == AgroBand.critical) criticalPenalty *= 0.42;
    if (soilTempEval.band == AgroBand.critical) criticalPenalty *= 0.48;
    if (phEval.band == AgroBand.critical) criticalPenalty *= 0.58;
    if (ecEval.band == AgroBand.critical) criticalPenalty *= 0.48;
    if (resEval.band == AgroBand.critical) criticalPenalty *= 0.78;

    final boltingRisk = computeBoltingRisk(
      // NaN cuando el canal no midió. La función ya sale por `!isFinite`, así
      // que un equipo sin sensor de aire devuelve riesgo bajo en vez de leer el
      // 0.0 sintetizado como un evento de frío de vernalización.
      airTempC: t.hasAirTempData ? t.airTempC : double.nan,
      stage: stageKey,
      profileSensitivity01: stage.profile.boltingSensitivity01,
    );
    switch (boltingRisk) {
      case OnionBoltingRisk.critico:
        criticalPenalty *= 0.52;
        break;
      case OnionBoltingRisk.alto:
        criticalPenalty *= 0.72;
        break;
      case OnionBoltingRisk.medio:
        criticalPenalty *= 0.88;
        break;
      case OnionBoltingRisk.bajo:
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

  /// Riesgo de espigado/seedstalk. En cebolla el espigado se asocia a
  /// planta grande expuesta a frio/vernalizacion y a estres; el calor
  /// fuerte tambien acelera madurez y puede predisponer en materiales
  /// sensibles. No es floracion productiva.
  static OnionBoltingRisk computeBoltingRisk({
    required double airTempC,
    required OnionStageKey stage,
    required double profileSensitivity01,
  }) {
    if (stage == OnionStageKey.espigado) return OnionBoltingRisk.critico;
    if (!airTempC.isFinite) return OnionBoltingRisk.bajo;

    // El espigado pesa sobre todo desde planta establecida hasta bulbo.
    final isExposedStage = stage == OnionStageKey.vegetativo ||
        stage == OnionStageKey.induccionBulbificacion ||
        stage == OnionStageKey.inicioBulbo ||
        stage == OnionStageKey.llenadoBulbo;
    if (!isExposedStage) return OnionBoltingRisk.bajo;

    final sensitive = profileSensitivity01 >= 0.62;
    final coldEvent = airTempC <= 8.0;
    final coolEvent = airTempC <= 12.0;

    if (coldEvent && sensitive) return OnionBoltingRisk.alto;
    if (coldEvent) return OnionBoltingRisk.medio;
    if (coolEvent && sensitive) return OnionBoltingRisk.medio;
    return OnionBoltingRisk.bajo;
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
    OnionStageKey stage,
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

  static void _pushEnvironmentalAlerts(
    List<String> out,
    BioGTelemetry t,
    OnionStageResult stage,
    OnionBoltingRisk boltingRisk,
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
    final stageKey = stage.stage;
    final isBulbStage = stageKey == OnionStageKey.induccionBulbificacion ||
        stageKey == OnionStageKey.inicioBulbo ||
        stageKey == OnionStageKey.llenadoBulbo;
    final isMaturity = stageKey == OnionStageKey.maduracionCosecha;

    if (airTemp <= 0) {
      out.add('airTemp.frost');
    } else if (airTemp < 4) {
      out.add('airTemp.cold');
    }
    // Doc: >30 C en induccion/llenado acelera madurez y reduce calibre.
    if (airTemp >= 32 || (isBulbStage && airTemp > 30)) {
      out.add('airTemp.extreme_heat');
    } else if (airTemp > 28 || (isBulbStage && airTemp > 26)) {
      out.add('airTemp.heat');
    }

    if (airHum > 90) {
      out.add('airHumidity.critical');
      out.add('onion.foliar_disease_risk');
    } else if (airHum > 85) {
      out.add('airHumidity.high');
      out.add('onion.foliar_disease_risk');
    }

    // Cebolla es sensible a sales (estricto).
    if (t.ec > 2.6) {
      out.add('onion.salinity_critical');
    } else if (t.ec > 1.8) {
      out.add('onion.salinity_warning');
    }

    switch (boltingRisk) {
      case OnionBoltingRisk.critico:
        out.add('onion.bolting_critical');
        break;
      case OnionBoltingRisk.alto:
        out.add('onion.bolting_warning');
        break;
      case OnionBoltingRisk.medio:
      case OnionBoltingRisk.bajo:
        break;
    }

    // Fotoperiodo manda en induccion: recordatorio de logica/modelo.
    if (stageKey == OnionStageKey.induccionBulbificacion &&
        !stage.profile.isBunching &&
        stage.profile.photoperiodSensitivity01 >= 0.80) {
      out.add('onion.photoperiod_watch');
    }

    // Maduracion: cuello/curado + humedad alta = riesgo de conservacion.
    if (isMaturity && (airHum > 85 || stage.profile.bulbQualitySensitivity01 >= 0.85)) {
      out.add('onion.neck_curing_risk');
    }

    if (isMaturity) {
      final urgentByHeatOrHumidity = airTemp > 30 || airHum > 88;
      out.add(urgentByHeatOrHumidity
          ? 'onion.harvest_urgent'
          : 'onion.harvest_window');
    } else if (stageKey == OnionStageKey.espigado) {
      out.add('onion.harvest_past');
    } else if (stage.daysToHarvestMin > 0 && stage.daysToHarvestMin <= 10) {
      out.add('onion.harvest_review');
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
