// lib/core/agro/irrigation/irrigation_inputs.dart
//
// Entradas normalizadas del motor de riego y la política que lo gobierna.
//
// Regla que define todo este archivo: **una métrica ausente se representa como
// `null`, jamás como `0`**. El bug más caro del sistema anterior era que un
// sensor desconectado producía `soilMoisturePct = 0.0`, el motor lo leía como
// suelo seco de verdad y emitía "Riego recomendado" con severidad crítica,
// indistinguible de una recomendación legítima.
//
// Por eso [IrrigationEngineInput] no acepta un `double` de humedad: acepta un
// `MoistureReading` que obliga a declarar si el dato existe.

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';

/// Lectura de humedad con su procedencia y validez.
///
/// El constructor nombrado [MoistureReading.absent] existe para que el código
/// llamante tenga que decir explícitamente "no hay dato" en vez de pasar cero.
@immutable
class MoistureReading {
  const MoistureReading({
    required this.percent,
    required this.isPresent,
    this.measuredAt,
    this.isCalibrated = true,
  });

  /// Lectura ausente. No hay valor y no hay forma de fingir que lo hay.
  const MoistureReading.absent({this.measuredAt})
    : percent = null,
      isPresent = false,
      isCalibrated = false;

  final double? percent;

  /// True solo si el sensor entregó realmente el dato. Se corresponde con
  /// `BioGTelemetry.hasSoilMoistureData`.
  final bool isPresent;

  /// Cuándo se midió. Null significa que no se sabe, lo que por sí solo
  /// invalida la lectura para decidir: sin hora no hay vigencia.
  final DateTime? measuredAt;

  final bool isCalibrated;

  /// True si hay un número utilizable.
  bool get hasValue {
    final v = percent;
    return isPresent && v != null && v.isFinite;
  }

  /// True si el valor cae dentro del rango físicamente posible de un sensor
  /// de humedad volumétrica expresado en porcentaje.
  bool get isPhysicallyPlausible {
    final v = percent;
    if (v == null || !v.isFinite) return false;
    return v >= 0 && v <= 100;
  }

  Duration? ageAt(DateTime now) {
    final t = measuredAt;
    if (t == null) return null;
    final diff = now.toUtc().difference(t.toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Construye la lectura desde los campos de telemetría, respetando la
  /// bandera de presencia. Es el único puente autorizado entre el modelo de
  /// telemetría y el motor: aquí es donde el cero sintetizado se convierte,
  /// correctamente, en ausencia.
  factory MoistureReading.fromTelemetry({
    required double rawPercent,
    required bool hasData,
    DateTime? measuredAt,
    bool isCalibrated = true,
  }) {
    if (!hasData) return MoistureReading.absent(measuredAt: measuredAt);
    return MoistureReading(
      percent: rawPercent,
      isPresent: true,
      measuredAt: measuredAt,
      isCalibrated: isCalibrated,
    );
  }
}

/// Contexto de suelo. Todo opcional: hoy la app no lo captura, y el motor debe
/// funcionar declarando esa limitación en vez de asumir valores por defecto.
///
/// Cuando el wizard capture textura y profundidad radicular, este objeto se
/// llena y habilita el balance hídrico de V1-B sin cambiar la firma del motor.
@immutable
class SoilContext {
  const SoilContext({
    this.textureId,
    this.fieldCapacityPct,
    this.wiltingPointPct,
    this.rootDepthCm,
    this.allowableDepletionFraction,
    this.systemEfficiency01,
  });

  /// `sandy` | `loam` | `clay` | ...
  final String? textureId;

  final double? fieldCapacityPct;
  final double? wiltingPointPct;
  final double? rootDepthCm;
  final double? allowableDepletionFraction;
  final double? systemEfficiency01;

  static const SoilContext unknown = SoilContext();

  /// True si hay lo mínimo para calcular una lámina real.
  bool get supportsWaterBalance =>
      fieldCapacityPct != null &&
      wiltingPointPct != null &&
      rootDepthCm != null &&
      allowableDepletionFraction != null;

  bool get isEmpty =>
      textureId == null &&
      fieldCapacityPct == null &&
      wiltingPointPct == null &&
      rootDepthCm == null;

  Map<String, Object?> toJson() => <String, Object?>{
    'textureId': textureId,
    'fieldCapacityPct': fieldCapacityPct,
    'wiltingPointPct': wiltingPointPct,
    'rootDepthCm': rootDepthCm,
    'allowableDepletion': allowableDepletionFraction,
    'systemEfficiency01': systemEfficiency01,
  };
}

/// Umbrales del motor. Centralizados y versionados: cambiar una política es
/// cambiar este objeto, no cazar constantes por el código.
@immutable
class IrrigationPolicy {
  const IrrigationPolicy({
    this.readingMaxAge = const Duration(hours: 6),
    this.readingIdealAge = const Duration(hours: 1),
    this.rainVetoProbPct = 60,
    this.rainVetoMinMm = 5.0,
    this.rainWatchProbPct = 40,
    this.rainWatchMinMm = 2.0,
    this.recentRainRelevantMm = 8.0,
    this.decisionValidity = const Duration(hours: 6),
    this.recentIrrigationWindow = const Duration(hours: 12),
    this.minConfidenceToRecommend = 0.35,
    this.confirmationConfidenceThreshold = 0.60,
  });

  /// Más vieja que esto, la lectura no decide nada.
  final Duration readingMaxAge;

  /// Por debajo de esto, la lectura no penaliza la confianza.
  final Duration readingIdealAge;

  /// Probabilidad a partir de la cual la lluvia veta el riego, siempre que
  /// además se esperen al menos [rainVetoMinMm].
  ///
  /// Se exigen las dos condiciones a propósito: 80 % de probabilidad de 0.2 mm
  /// no moja la zona radicular, y vetar un riego por eso sería peor que no
  /// mirar el clima.
  final int rainVetoProbPct;
  final double rainVetoMinMm;

  /// Probabilidad a partir de la cual conviene vigilar sin vetar todavía.
  final int rainWatchProbPct;

  /// Volumen mínimo para que esa vigilancia tenga sentido.
  ///
  /// Un 90 % de probabilidad de 0.3 mm no cambia nada en el suelo: esperar por
  /// eso deja al cultivo en déficit a cambio de nada. Si el volumen previsto
  /// es conocido y ridículo, la lluvia deja de ser relevante para la decisión.
  final double rainWatchMinMm;

  /// Lluvia caída en las últimas 24 h que debería haberse reflejado en el
  /// sensor. Si llovió esto y el suelo sigue crítico, hay contradicción.
  final double recentRainRelevantMm;

  final Duration decisionValidity;
  final Duration recentIrrigationWindow;

  /// Por debajo de esta confianza no se emite una acción; se pide revisión.
  final double minConfidenceToRecommend;

  /// Por debajo de esta confianza, una acción de alto impacto exige
  /// confirmación explícita del agricultor.
  final double confirmationConfidenceThreshold;

  static const IrrigationPolicy standard = IrrigationPolicy();

  /// Política para maceta y cultivo ornamental de interior: el volumen de
  /// sustrato es pequeño, se seca más rápido y la lluvia rara vez aplica.
  static const IrrigationPolicy potted = IrrigationPolicy(
    readingMaxAge: Duration(hours: 12),
    rainVetoProbPct: 101, // nunca vetar por lluvia: está bajo techo
    rainVetoMinMm: 1000,
    decisionValidity: Duration(hours: 12),
  );
}

/// Todo lo que el motor necesita para decidir. Objeto plano y puro: el motor
/// no hace red, no lee disco y no conoce widgets, así que es enteramente
/// determinista y se puede probar caso por caso.
@immutable
class IrrigationEngineInput {
  const IrrigationEngineInput({
    required this.now,
    required this.moisture,
    required this.weather,
    this.deviceId,
    this.cropId,
    this.cropLabel,
    this.isGenericMode = false,
    this.stageKey,
    this.stageLabel,
    this.moistureTarget,
    this.moistureBand,
    this.soil = SoilContext.unknown,
    this.lastIrrigationAt,
    this.policy = IrrigationPolicy.standard,
    this.isUnderCover = false,
  });

  final DateTime now;

  final MoistureReading moisture;

  /// Clima ya resuelto por `WeatherRepository`. Nunca null: cuando no hay
  /// clima se pasa un snapshot `unavailable`, para que el motor tenga que
  /// tratar el caso explícitamente.
  final AgronomicWeatherSnapshot weather;

  final String? deviceId;
  final String? cropId;
  final String? cropLabel;

  /// True cuando no hay cultivo o variedad concreta seleccionada. En ese caso
  /// no hay objetivo por etapa contra el cual comparar.
  final bool isGenericMode;

  final String? stageKey;
  final String? stageLabel;

  /// Rango objetivo de humedad para la etapa fenológica actual.
  ///
  /// Viene de los perfiles por cultivo que ya existen y funcionan; el motor no
  /// los reimplementa ni los sustituye.
  final AgroRange? moistureTarget;

  /// Banda ya calculada por el motor de score, si está disponible.
  final AgroBand? moistureBand;

  final SoilContext soil;

  /// Último riego registrado por el usuario.
  final DateTime? lastIrrigationAt;

  final IrrigationPolicy policy;

  /// Maceta bajo techo, invernadero cerrado: la lluvia del pronóstico no llega
  /// al sustrato y no debe vetar el riego.
  final bool isUnderCover;

  bool get hasStageTarget => moistureTarget != null;
}
