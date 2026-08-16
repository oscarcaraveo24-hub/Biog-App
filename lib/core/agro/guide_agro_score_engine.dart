// lib/core/agro/guide_agro_score_engine.dart
//
// Motor del MODO GUÍA GENERAL.
//
// Es `CerealAgroScoreEngine` recortado a las cinco condiciones del suelo, con
// una diferencia que es la razón de que exista este archivo en vez de reusar
// aquél: **no evalúa N, P ni K**. El mapa `metrics` sale sin esas tres claves,
// no con las claves puestas a "desconocido".
//
// Esa distinción importa. Si se emitieran con banda —aunque fuera contra un
// rango abierto— cualquier pantalla que lea `eval.metrics[AgroMetricKey.n]`
// empezaría a pintar una etiqueta de nitrógeno para un cultivo que el sistema
// no conoce. Al no existir la clave, no hay nada que pintar y el
// comportamiento correcto sale solo, sin depender de que cada consumidor se
// acuerde de comprobar el modo.
//
// Tampoco arrastra la penalización por NPK crítico que `CerealAgroScoreEngine`
// aplica ignorando el peso (`criticalPenalty *= 0.70` por nutriente): en guía
// esa penalización no puede dispararse porque no hay evaluación nutrimental.
//
// El resto —normalización de humedad, semántica de bandas, curva de score y
// alertas ambientales— es idéntico a propósito. Dos motores que puntúan
// distinto la misma lectura serían dos verdades.
//
// La única otra desviación está en qué alertas se emiten por métrica: aquí
// solo las críticas. El porqué está documentado sobre `_pushAlertsForMetric`.

import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/generic/generic_guide.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class GuideAgroScoreEngine {
  /// Evalúa la telemetría contra las bandas generales de [kGuideTargets].
  ///
  /// Sin etapa fenológica: no hay ninguna que resolver. Por eso tampoco recibe
  /// `criticalStageKeys` — ninguna ventana es crítica cuando no se sabe qué
  /// planta es, y subir la severidad de las alertas sobre esa base sería
  /// exactamente el tipo de alarmismo que el Fundacional prohíbe.
  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluate({
    required BioGTelemetry t,
    StageTargets targets = kGuideTargets,
    StageWeights weights = kGuideWeights,
    AlertsState alertsState = const AlertsState(),
    Calibration? cal,
    Duration alertsCooldown = AlertsEngine.defaultCooldown,
    String cropLabel = kGuideCropLabel,
  }) {
    final double moisture01 = _normalizeMoisture01(t.soilMoisturePct, cal);
    final double moistureRawCal = moisture01 * 100.0;

    // Cada métrica se evalúa solo si su sensor reportó. `BioGTelemetry`
    // rellena con 0.0 lo que falta, y 0.0 cae en "crítico" en cuatro de los
    // cinco rangos: sin esta comprobación un sensor averiado se leería como
    // suelo en emergencia. Los motores del catálogo todavía no lo hacen; aquí
    // sí, porque el archivo es nuevo y no arrastra ese contrato.
    final _Eval moistureEval = _eval(
      value: moistureRawCal,
      range: targets.moistureRaw,
      hasData: t.hasSoilMoistureData,
    );
    final _Eval soilTempEval = _eval(
      value: t.soilTempC,
      range: targets.soilTemp,
      hasData: t.hasSoilTempData,
    );
    final _Eval phEval = _eval(
      value: t.ph,
      range: targets.ph,
      hasData: t.hasPhData,
    );
    final _Eval ecEval = _eval(
      value: t.ec,
      range: targets.ec,
      hasData: t.hasEcData,
    );
    final _Eval resistanceEval = _eval(
      value: t.resistance,
      range: targets.resistance,
      hasData: t.hasResistanceData,
    );

    // Cinco claves. N, P y K NO aparecen: ver la nota de cabecera.
    final Map<AgroMetricKey, AgroMetricEval> metrics =
        <AgroMetricKey, AgroMetricEval>{
          AgroMetricKey.soilMoisture: _wrap(moistureEval),
          AgroMetricKey.soilTemp: _wrap(soilTempEval),
          AgroMetricKey.ph: _wrap(phEval),
          AgroMetricKey.ec: _wrap(ecEval),
          AgroMetricKey.resistance: _wrap(resistanceEval),
        };

    // Solo pesos de suelo —`weights.sum` incluiría los nutrientes— y solo de
    // las métricas que sí tienen dato. Repartir el peso de un sensor ausente
    // entre los presentes es la diferencia entre "no lo sé" y "está mal": si
    // una métrica sin dato entrara con score 0, el anillo de salud caería por
    // un sensor roto, no por el suelo.
    double weightedScore = 0.0;
    double totalW = 0.0;

    void accumulate(_Eval e, double w) {
      if (e.band == AgroBand.unknown) return;
      weightedScore += w * e.score01;
      totalW += w;
    }

    accumulate(moistureEval, weights.moisture);
    accumulate(soilTempEval, weights.soilTemp);
    accumulate(resistanceEval, weights.resistance);
    accumulate(phEval, weights.ph);
    accumulate(ecEval, weights.ec);

    final double rawScore = weightedScore / math.max(0.0001, totalW);

    // Mismos factores que el motor de cereales para las cinco de suelo.
    double criticalPenalty = 1.0;
    if (moistureEval.band == AgroBand.critical) criticalPenalty *= 0.45;
    if (soilTempEval.band == AgroBand.critical) criticalPenalty *= 0.50;
    if (phEval.band == AgroBand.critical) criticalPenalty *= 0.45;
    if (ecEval.band == AgroBand.critical) criticalPenalty *= 0.65;
    if (resistanceEval.band == AgroBand.critical) criticalPenalty *= 0.85;

    final double soilControlScore01 = rawScore * criticalPenalty;

    final List<String> suggestedAlertKeys = <String>[];

    // La humedad es la única métrica cuya crítica cambia de significado según
    // el lado: 10 % es sequía y 92 % es encharcamiento, y la clave
    // `soilMoisture.critical` solo sabe decir la primera. Un aviso que diga
    // "muy seco" con la maceta inundada es peor que no avisar.
    if (moistureEval.band == AgroBand.critical) {
      suggestedAlertKeys.add(
        moistureEval.aboveRange
            ? 'soilMoisture.saturated'
            : 'soilMoisture.critical',
      );
    }

    _pushAlertsForMetric(suggestedAlertKeys, 'soilTemp', soilTempEval);
    _pushAlertsForMetric(suggestedAlertKeys, 'ph', phEval);
    _pushAlertsForMetric(suggestedAlertKeys, 'ec', ecEval);
    _pushAlertsForMetric(suggestedAlertKeys, 'resistance', resistanceEval);

    // Helada y calor extremo NO dependen de saber qué planta es. Omitirlas
    // aquí dejaría al usuario de guía como el único de la app sin aviso de
    // helada, y una helada no perdona por no estar en el catálogo.
    _pushEnvironmentalAlerts(suggestedAlertKeys, t);

    final alertsBuild = AlertsEngine.buildFromSuggestedKeys(
      deviceId: t.deviceId,
      now: t.timestamp,
      severityBump: 0,
      suggestedKeys: suggestedAlertKeys,
      prev: alertsState,
      cooldown: alertsCooldown,
      cropLabel: cropLabel,
      stageLabel: null,
      isGuide: true,
    );

    final AgroEvalResult agroEval = AgroEvalResult(
      soilControlScore01: soilControlScore01.clamp(0.0, 1.0),
      metrics: metrics,
      alerts: alertsBuild.alerts,
      suggestedAlertKeys: suggestedAlertKeys,
    );

    return (eval: agroEval, nextAlertsState: alertsBuild.state);
  }

  // ── Todo lo de abajo replica `CerealAgroScoreEngine` sin desviarse ─────────

  /// Solo emite la crítica. Nunca `.low` ni `.high`.
  ///
  /// `CerealAgroScoreEngine` reserva esas dos para la etapa crítica del
  /// cultivo, y en guía no hay etapa: emitirlas siempre convertiría este modo
  /// en el más ruidoso de la app —notificaría cosas que a un maíz en etapa
  /// normal no se le notifican— y encima sobre una planta que el sistema no
  /// puede identificar.
  ///
  /// El agricultor no se queda sin la información: "Bajo" y "Alto" sí se
  /// pintan en las bandas del Panel, que es donde va a mirar. Lo que no hacen
  /// es sonar el teléfono.
  static void _pushAlertsForMetric(
    List<String> out,
    String metricKey,
    _Eval e,
  ) {
    if (e.band == AgroBand.critical) {
      out.add('$metricKey.critical');
    }
  }

  /// Alertas ambientales. No entran en el score, solo en avisos.
  ///
  /// Umbrales sin `isCriticalStage`: en guía no hay ventana crítica que
  /// justifique adelantar el umbral, así que se usan los valores base que ya
  /// aplican todos los motores del catálogo fuera de etapa crítica.
  ///
  /// Las banderas `hasAirTempData` / `hasAirHumidityData` NO son opcionales.
  /// `BioGTelemetry` rellena con 0.0 el sensor que falta, y `0.0 <= 0` cumple
  /// la condición de helada: un equipo sin sensor de aire avisaría de helada
  /// crítica en cada lectura, para siempre. Es el mismo fallo que
  /// `agro_event_input_factory.dart` documenta haber corregido en la otra
  /// ruta; los motores del catálogo todavía lo arrastran.
  static void _pushEnvironmentalAlerts(List<String> out, BioGTelemetry t) {
    if (t.hasAirTempData) {
      final double airTemp = t.airTempC;

      if (airTemp <= 0) {
        out.add('airTemp.frost');
      } else if (airTemp < 2) {
        out.add('airTemp.cold');
      }

      if (airTemp > 40) {
        out.add('airTemp.extreme_heat');
      } else if (airTemp > 35) {
        out.add('airTemp.heat');
      }
    }

    if (t.hasAirHumidityData) {
      final double airHum = t.airHumidityPct;

      if (airHum > 90) {
        out.add('airHumidity.critical');
      } else if (airHum > 80) {
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

  static _Eval _eval({
    required double value,
    required AgroRange range,
    bool hasData = true,
  }) {
    if (!hasData || !value.isFinite || value.isNaN) {
      return _Eval(value: value, band: AgroBand.unknown, score01: 0.0);
    }

    final double lowMax = math.min(range.lowMax, range.optimalMin);
    final double optMin = math.max(range.lowMax, range.optimalMin);
    final double optMax = math.max(range.optimalMax, optMin);
    final double highMin = math.max(range.highMin, optMax);

    AgroBand band;
    bool aboveRange = false;
    if (value < lowMax) {
      band = AgroBand.critical;
    } else if (value < optMin) {
      band = AgroBand.low;
    } else if (value <= optMax) {
      band = AgroBand.optimal;
    } else if (value <= highMin) {
      band = AgroBand.high;
      aboveRange = true;
    } else {
      band = AgroBand.critical;
      aboveRange = true;
    }

    return _Eval(
      value: value,
      band: band,
      score01: _scoreFromRange(value, lowMax, optMin, optMax, highMin),
      aboveRange: aboveRange,
    );
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
      return _lerp(0.55, 0.95, _invLerp(lowMax, optMin, v));
    }

    if (v > optMax && v <= highMin) {
      return _lerp(0.95, 0.55, _invLerp(optMax, highMin, v));
    }

    if (v < lowMax) {
      final double span = math.max(1e-6, (optMin - lowMax).abs());
      final double d = (lowMax - v) / span;
      return (0.35 / (1 + d)).clamp(0.05, 0.35);
    }

    final double span = math.max(1e-6, (highMin - optMax).abs());
    final double d = (v - highMin) / span;
    return (0.35 / (1 + d)).clamp(0.05, 0.35);
  }

  static double _invLerp(double a, double b, double v) {
    if ((b - a).abs() < 1e-9) return 0.0;
    return ((v - a) / (b - a)).clamp(0.0, 1.0);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _Eval {
  const _Eval({
    required this.value,
    required this.band,
    required this.score01,
    this.aboveRange = false,
  });

  final double value;
  final AgroBand band;
  final double score01;

  /// True si la desviación es por arriba del óptimo.
  ///
  /// Lo decide `_eval`, que es quien tiene los límites ya saneados
  /// (`optMax = max(optimalMax, optMin)`). Compararlo fuera contra el
  /// `AgroRange` crudo daría el lado equivocado con un rango mal formado.
  final bool aboveRange;
}
