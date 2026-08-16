// lib/core/agro/irrigation/irrigation_types.dart
//
// Lenguaje de dominio del motor de riego.
//
// Hasta ahora la "decisión" de riego era una cadena de texto elegida por un
// `switch` de ocho líneas dentro del presentador del Panel. Cuatro frases
// sueltas, ninguna estructura: era imposible saber por qué se dijo lo que se
// dijo, guardarlo, probarlo o mostrarlo distinto en otra pantalla.
//
// Aquí la decisión pasa a ser un objeto con acción, urgencia, razones,
// confianza, evidencia y vigencia. La interfaz se limita a pintarlo.
//
// Fundacional 2.1: primero decidir de forma prudente y explicable (motor de
// veto), después cuantificar (balance hídrico). Este archivo es el vocabulario
// de la primera mitad.

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';

/// Las cinco respuestas posibles. No hay una sexta.
enum IrrigationAction {
  /// Hay déficit confirmado, la lectura es válida y vigente, la etapa lo
  /// demanda y no hay lluvia suficiente próxima.
  regar,

  /// El suelo está dentro o por encima del objetivo, hay saturación, o el
  /// riego sería innecesario.
  noRegar,

  /// Hay lluvia probable, recuperación de humedad en curso, o incertidumbre
  /// que justifica volver a evaluar más tarde.
  esperar,

  /// Sensor y clima se contradicen, falta contexto de suelo, o la situación
  /// requiere inspección humana.
  revisar,

  /// La lectura es inválida, vieja o incompleta. No se genera recomendación.
  datosInsuficientes,
}

extension IrrigationActionX on IrrigationAction {
  String get labelEs {
    switch (this) {
      case IrrigationAction.regar:
        return 'Regar';
      case IrrigationAction.noRegar:
        return 'No regar';
      case IrrigationAction.esperar:
        return 'Esperar';
      case IrrigationAction.revisar:
        return 'Revisar';
      case IrrigationAction.datosInsuficientes:
        return 'Datos insuficientes';
    }
  }

  /// Etiqueta corta para la esquina de la tarjeta del Panel.
  String get tagEs {
    switch (this) {
      case IrrigationAction.regar:
        return 'Regar';
      case IrrigationAction.noRegar:
        return 'OK';
      case IrrigationAction.esperar:
        return 'Esperar';
      case IrrigationAction.revisar:
        return 'Revisar';
      case IrrigationAction.datosInsuficientes:
        return '—';
    }
  }

  /// True si la acción implica que el agricultor haga algo ahora.
  bool get isActionable =>
      this == IrrigationAction.regar || this == IrrigationAction.revisar;

  /// True si la decisión se tomó sobre evidencia suficiente.
  ///
  /// `datosInsuficientes` no es una recomendación: es la ausencia de una.
  /// Nada aguas abajo debe tratarla como consejo.
  bool get isRecommendation => this != IrrigationAction.datosInsuficientes;
}

/// Qué tan urgente es actuar. Independiente de la acción: se puede tener
/// `revisar` urgente y `regar` sin prisa.
enum IrrigationUrgency { none, low, medium, high, critical }

extension IrrigationUrgencyX on IrrigationUrgency {
  String get labelEs {
    switch (this) {
      case IrrigationUrgency.none:
        return 'Sin urgencia';
      case IrrigationUrgency.low:
        return 'Baja';
      case IrrigationUrgency.medium:
        return 'Media';
      case IrrigationUrgency.high:
        return 'Alta';
      case IrrigationUrgency.critical:
        return 'Crítica';
    }
  }

  int get rank {
    switch (this) {
      case IrrigationUrgency.none:
        return 0;
      case IrrigationUrgency.low:
        return 1;
      case IrrigationUrgency.medium:
        return 2;
      case IrrigationUrgency.high:
        return 3;
      case IrrigationUrgency.critical:
        return 4;
    }
  }
}

/// Motivos estructurados. Existen como enum y no como texto libre para que se
/// puedan probar, contar y traducir sin depender de la redacción.
enum IrrigationReasonCode {
  // Bloqueos de dato
  noCropConfigured,
  moistureSensorAbsent,
  moistureReadingStale,
  moistureReadingImplausible,
  noStageTarget,

  // Estado del suelo
  moistureCritical,
  moistureBelowTarget,
  moistureWithinTarget,
  moistureAboveTarget,
  soilSaturated,

  // Clima
  rainExpectedSoon,
  rainExpectedLater,
  noRainExpected,
  weatherUnavailable,
  weatherStale,
  recentRainRecorded,

  // Conflictos
  sensorWeatherConflict,
  recentIrrigationLogged,

  // Limitaciones declaradas
  soilProfileMissing,
  et0Imprecise,
}

extension IrrigationReasonCodeX on IrrigationReasonCode {
  /// True si el motivo, por sí solo, impide emitir una recomendación.
  bool get isBlocking =>
      this == IrrigationReasonCode.noCropConfigured ||
      this == IrrigationReasonCode.moistureSensorAbsent ||
      this == IrrigationReasonCode.moistureReadingStale ||
      this == IrrigationReasonCode.moistureReadingImplausible;
}

/// Un motivo con su explicación en lenguaje humano.
@immutable
class IrrigationReason {
  const IrrigationReason({
    required this.code,
    required this.textEs,
    this.isLimitation = false,
  });

  final IrrigationReasonCode code;

  /// Redacción para el agricultor. Concreta y sin jerga: "Se esperan 9 mm en
  /// las próximas 12 horas", no "condiciones meteorológicas favorables".
  final String textEs;

  /// True cuando el motivo describe algo que el sistema NO sabe, en vez de
  /// algo que observó. Se muestra distinto: es una limitación declarada, que
  /// el Fundacional exige hacer explícita en lugar de disimular.
  final bool isLimitation;

  Map<String, Object?> toJson() => <String, Object?>{
    'code': code.name,
    'text': textEs,
    if (isLimitation) 'limitation': true,
  };

  @override
  String toString() => '${code.name}: $textEs';

  @override
  bool operator ==(Object other) =>
      other is IrrigationReason &&
      other.code == code &&
      other.textEs == textEs &&
      other.isLimitation == isLimitation;

  @override
  int get hashCode => Object.hash(code, textEs, isLimitation);
}

/// Estimación cuantitativa de lámina.
///
/// Se rellena únicamente cuando hay base real para hacerlo: textura conocida
/// (o derivada del equipo), profundidad radicular del cultivo y una lectura de
/// humedad presente y vigente. Sin uno de esos ingredientes queda **nula**, y la
/// tarjeta dice «riega como acostumbras» en vez de fingir precisión.
///
/// El motor de veto nunca la inventa: la produce
/// `MoistureTargetResolver.depthFor`, que devuelve null antes que adivinar.
@immutable
class IrrigationDepthEstimate {
  const IrrigationDepthEstimate({
    required this.millimeters,
    required this.basisEs,
    this.lowMillimeters,
    this.highMillimeters,
    this.includesSystemLosses = false,
    this.litersPerPlant,
    this.litersPerSquareMeter,
  });

  final double millimeters;
  final String basisEs;

  /// ── La banda, y por qué es obligatoria ──────────────────────────────────
  ///
  /// La exactitud declarada del canal de humedad es de ±3 puntos de contenido
  /// volumétrico en el rango bajo. Sobre una zona radicular de 40 cm eso son
  /// ±12 mm de lámina; sobre una lámina neta calculada de 40 mm, **±30 %**. Un
  /// tercio.
  ///
  /// Publicar «aplica 40 mm» comunicaría una precisión que el instrumento no
  /// tiene, antes siquiera de contar el error de la textura elegida a mano y el
  /// de la profundidad radicular estimada. La banda no es una cortesía: es el
  /// número.
  final double? lowMillimeters;
  final double? highMillimeters;

  /// True cuando [millimeters] ya cuenta las pérdidas del sistema de riego.
  ///
  /// Sin sistema declarado se publica la lámina NETA y hay que decirlo: para
  /// los mismos 40 mm netos son 44 por goteo, 53 por aspersión y 67 por surco.
  /// La diferencia entre el mejor y el peor sistema es del 52 %; fingir que se
  /// conoce esa conversión sin saber el sistema sería peor que no darla.
  final bool includesSystemLosses;

  final double? litersPerPlant;
  final double? litersPerSquareMeter;

  bool get hasBand => lowMillimeters != null && highMillimeters != null;

  /// Nunca una cifra cerrada.
  String get bandEs {
    final lo = lowMillimeters;
    final hi = highMillimeters;
    if (lo == null || hi == null) return 'unos ${_fmt(millimeters)} mm';
    return 'entre ${_fmt(lo)} y ${_fmt(hi)} mm';
  }

  static String _fmt(double v) => v.toStringAsFixed(v < 10 ? 1 : 0);

  Map<String, Object?> toJson() => <String, Object?>{
    'mm': millimeters,
    'lowMm': lowMillimeters,
    'highMm': highMillimeters,
    'includesSystemLosses': includesSystemLosses,
    'basis': basisEs,
    'litersPerPlant': litersPerPlant,
    'litersPerM2': litersPerSquareMeter,
  };
}

/// La decisión completa.
@immutable
class IrrigationDecision {
  const IrrigationDecision({
    required this.action,
    required this.urgency,
    required this.confidence01,
    required this.reasons,
    required this.headlineEs,
    required this.detailEs,
    required this.decidedAt,
    required this.engineVersion,
    this.validUntil,
    this.requiresHumanReview = false,
    this.requiresConfirmation = false,
    this.weather,
    this.moisturePct,
    this.moistureBandName,
    this.stageKey,
    this.stageLabel,
    this.depth,
    this.evidence = const <String, Object?>{},
  });

  final IrrigationAction action;
  final IrrigationUrgency urgency;

  /// 0..1. Baja con dato viejo, clima ausente o contexto de suelo faltante.
  final double confidence01;

  /// Por qué se decidió esto, en orden de peso.
  final List<IrrigationReason> reasons;

  /// Frase principal para la tarjeta. Nunca contiene un plazo ("24 horas") si
  /// la evidencia no incluye clima vigente.
  final String headlineEs;

  /// Explicación en una o dos frases.
  final String detailEs;

  final DateTime decidedAt;

  /// Hasta cuándo vale esta decisión. Después hay que recalcular: una
  /// recomendación de riego no es válida indefinidamente.
  final DateTime? validUntil;

  /// El sistema pide ojo humano antes de actuar.
  final bool requiresHumanReview;

  /// La acción es de alto impacto y la interfaz debe pedir confirmación
  /// explícita. A diferencia de la bandera muerta que había en el planificador
  /// de fertilización, ésta sí se consume: ver `IrrigationDecision.isBlocking`
  /// y el registro auditable.
  final bool requiresConfirmation;

  /// Versión del motor que produjo la decisión. Sin esto es imposible saber
  /// con qué reglas se aconsejó algo hace tres meses.
  final String engineVersion;

  /// Clima exacto que se usó. Se guarda con la decisión, no se vuelve a pedir.
  final AgronomicWeatherSnapshot? weather;

  final double? moisturePct;
  final String? moistureBandName;
  final String? stageKey;
  final String? stageLabel;

  /// Lámina estimada. Null en V1-A.
  final IrrigationDepthEstimate? depth;

  /// Datos crudos que entraron en la decisión.
  final Map<String, Object?> evidence;

  bool get isBlocking => !action.isRecommendation;

  /// True si esta decisión debe sustituir al texto que la tarjeta mostraba
  /// antes (el derivado solo de la banda de humedad).
  ///
  /// La distinción importa para no empobrecer la interfaz. Hay dos casos en
  /// que el motor NO aporta nada y conviene dejar el texto anterior, que sí
  /// conoce el contexto del cultivo:
  ///
  ///  - `noCropConfigured`: el Panel ya explica el modo genérico y la
  ///    preparación previa a la siembra mejor que un mensaje genérico.
  ///  - `noStageTarget`: falta configuración del catálogo, no es un problema
  ///    de riego; la evaluación agronómica existente sigue siendo más útil.
  ///
  /// Todo lo demás sí manda, incluidos los bloqueos por dato ausente o
  /// vencido: ahí callar sería justamente el error que se vino a corregir.
  bool get overridesLegacyCard {
    final blockingCodes = reasons
        .map((r) => r.code)
        .where(
          (c) =>
              c == IrrigationReasonCode.noCropConfigured ||
              c == IrrigationReasonCode.noStageTarget,
        );
    return blockingCodes.isEmpty;
  }

  /// True si la decisión pide una acción concreta del agricultor.
  ///
  /// Cuando es false —humedad en rango, sin nada que hacer— una tarjeta con
  /// contexto de etapa (árbol, ornamental) informa más que "No riegues".
  bool get isActionable =>
      action.isActionable ||
      action == IrrigationAction.esperar ||
      action == IrrigationAction.datosInsuficientes;

  bool get hasWeatherEvidence => weather != null && !weather!.isUnavailable;

  /// Limitaciones declaradas: lo que el sistema reconoce no saber.
  List<IrrigationReason> get limitations =>
      reasons.where((r) => r.isLimitation).toList(growable: false);

  /// Motivos observados, sin las limitaciones.
  List<IrrigationReason> get observations =>
      reasons.where((r) => !r.isLimitation).toList(growable: false);

  bool isExpiredAt(DateTime now) {
    final until = validUntil;
    if (until == null) return false;
    return now.isAfter(until);
  }

  String confidenceLabelEs() {
    if (confidence01 >= 0.85) return 'Confianza alta';
    if (confidence01 >= 0.60) return 'Confianza media';
    if (confidence01 >= 0.35) return 'Confianza baja';
    return 'Confianza insuficiente';
  }

  IrrigationDecision copyWith({
    IrrigationAction? action,
    IrrigationUrgency? urgency,
    double? confidence01,
    List<IrrigationReason>? reasons,
    String? headlineEs,
    String? detailEs,
    DateTime? decidedAt,
    DateTime? validUntil,
    bool? requiresHumanReview,
    bool? requiresConfirmation,
    String? engineVersion,
    AgronomicWeatherSnapshot? weather,
    double? moisturePct,
    String? moistureBandName,
    String? stageKey,
    String? stageLabel,
    IrrigationDepthEstimate? depth,
    Map<String, Object?>? evidence,
  }) {
    return IrrigationDecision(
      action: action ?? this.action,
      urgency: urgency ?? this.urgency,
      confidence01: confidence01 ?? this.confidence01,
      reasons: reasons ?? this.reasons,
      headlineEs: headlineEs ?? this.headlineEs,
      detailEs: detailEs ?? this.detailEs,
      decidedAt: decidedAt ?? this.decidedAt,
      validUntil: validUntil ?? this.validUntil,
      requiresHumanReview: requiresHumanReview ?? this.requiresHumanReview,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      engineVersion: engineVersion ?? this.engineVersion,
      weather: weather ?? this.weather,
      moisturePct: moisturePct ?? this.moisturePct,
      moistureBandName: moistureBandName ?? this.moistureBandName,
      stageKey: stageKey ?? this.stageKey,
      stageLabel: stageLabel ?? this.stageLabel,
      depth: depth ?? this.depth,
      evidence: evidence ?? this.evidence,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'action': action.name,
    'urgency': urgency.name,
    'confidence01': confidence01,
    'reasons': reasons.map((r) => r.toJson()).toList(),
    'headline': headlineEs,
    'detail': detailEs,
    'decidedAt': decidedAt.toUtc().toIso8601String(),
    'validUntil': validUntil?.toUtc().toIso8601String(),
    'requiresHumanReview': requiresHumanReview,
    'requiresConfirmation': requiresConfirmation,
    'engineVersion': engineVersion,
    'weather': weather?.toEvidenceJson(),
    'moisturePct': moisturePct,
    'moistureBand': moistureBandName,
    'stageKey': stageKey,
    'stageLabel': stageLabel,
    'depth': depth?.toJson(),
    'evidence': evidence,
  };

  @override
  String toString() =>
      'IrrigationDecision(${action.name}, urgency=${urgency.name}, '
      'confidence=${confidence01.toStringAsFixed(2)}, "$headlineEs")';
}
