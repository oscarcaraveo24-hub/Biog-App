// lib/core/agro/traceability/recommendation_record.dart
//
// Registro inmutable de una recomendación oficial de BIO-G.
//
// Regla del Fundacional 2.1: si no se puede reconstruir con qué datos y qué
// reglas se emitió, no debe considerarse una recomendación oficial de BIO-G.
//
// Lo que se guardaba antes: un `AgronomicEvent` con un `metadata` de cuatro
// claves —`source`, `group`, `value`, `band`—. Sin id de lectura, sin
// unidades, sin presencia, sin vigencia, sin snapshot climático, sin versión
// del motor, sin versión del catálogo, sin confianza y sin la acción del
// usuario. Y encima nunca se leía.
//
// Este registro es la respuesta completa. Cada campo existe porque alguien
// —una auditoría, un cliente, una reclamación por una cosecha perdida— puede
// preguntar por él.

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/agro/traceability/engine_versions.dart';
import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';

/// Qué tipo de consejo se emitió.
enum RecommendationKind { irrigation, fertilization, plantHealth, cropCycle }

extension RecommendationKindX on RecommendationKind {
  String get labelEs {
    switch (this) {
      case RecommendationKind.irrigation:
        return 'Riego';
      case RecommendationKind.fertilization:
        return 'Fertilización';
      case RecommendationKind.plantHealth:
        return 'Sanidad';
      case RecommendationKind.cropCycle:
        return 'Ciclo del cultivo';
    }
  }
}

/// Qué hizo el agricultor con la recomendación.
///
/// Era el campo más ausente de todos: no existía forma de saber si alguien
/// hizo caso. Sin esto no hay ciclo de aprendizaje ni evidencia de que el
/// consejo se siguiera.
enum UserResponse {
  /// Todavía no ha respondido.
  pending,

  /// La aceptó como válida.
  accepted,

  /// La pospuso para más tarde.
  postponed,

  /// La descartó.
  dismissed,

  /// Ejecutó la acción (regó, aplicó).
  performed,

  /// Pidió revisión humana.
  reviewRequested,

  /// Venció sin respuesta.
  expired,
}

extension UserResponseX on UserResponse {
  String get labelEs {
    switch (this) {
      case UserResponse.pending:
        return 'Sin responder';
      case UserResponse.accepted:
        return 'Aceptada';
      case UserResponse.postponed:
        return 'Pospuesta';
      case UserResponse.dismissed:
        return 'Descartada';
      case UserResponse.performed:
        return 'Realizada';
      case UserResponse.reviewRequested:
        return 'Revisión solicitada';
      case UserResponse.expired:
        return 'Vencida sin respuesta';
    }
  }

  bool get isClosed => this != UserResponse.pending;
}

/// Una métrica tal como entró en la decisión: con unidad, presencia y calidad.
///
/// Guardar `12.4` a secas no sirve para auditar. Hay que saber que eran 12.4
/// **por ciento**, que el sensor **sí** lo midió (y no que se rellenó con
/// cero), y qué tan viejo era el dato.
@immutable
class RecordedMetric {
  const RecordedMetric({
    required this.key,
    required this.unit,
    required this.isPresent,
    this.value,
    this.band,
    this.measuredAt,
    this.ageMinutes,
    this.isCalibrated,
  });

  final String key;
  final String unit;

  /// False si el sensor no entregó el dato. Con `false`, [value] no significa
  /// nada y jamás debe interpretarse como una medición.
  final bool isPresent;

  final double? value;
  final String? band;
  final DateTime? measuredAt;
  final int? ageMinutes;
  final bool? isCalibrated;

  Map<String, Object?> toJson() => <String, Object?>{
    'key': key,
    'unit': unit,
    'present': isPresent,
    'value': value,
    'band': band,
    'measuredAt': measuredAt?.toUtc().toIso8601String(),
    'ageMinutes': ageMinutes,
    'calibrated': isCalibrated,
  };

  static RecordedMetric? fromJson(Map<String, dynamic> json) {
    try {
      final measured = json['measuredAt'];
      return RecordedMetric(
        key: json['key'] as String,
        unit: (json['unit'] as String?) ?? '',
        isPresent: (json['present'] as bool?) ?? false,
        value: (json['value'] as num?)?.toDouble(),
        band: json['band'] as String?,
        measuredAt: measured is String ? DateTime.tryParse(measured) : null,
        ageMinutes: (json['ageMinutes'] as num?)?.toInt(),
        isCalibrated: json['calibrated'] as bool?,
      );
    } catch (_) {
      return null;
    }
  }
}

@immutable
class RecommendationRecord {
  const RecommendationRecord({
    required this.id,
    required this.kind,
    required this.issuedAt,
    required this.deviceId,
    required this.readingId,
    required this.headlineEs,
    required this.detailEs,
    required this.engineVersion,
    required this.schemaVersion,
    required this.metrics,
    required this.reasons,
    this.userId,
    this.action,
    this.urgency,
    this.confidence01,
    this.validUntil,
    this.requiresConfirmation = false,
    this.requiresHumanReview = false,
    this.cropId,
    this.cropLabel,
    this.varietyId,
    this.varietyAlias,
    this.stageKey,
    this.stageLabel,
    this.catalogVersion,
    this.parcelLabel,
    this.parcelLat,
    this.parcelLon,
    this.weather,
    this.userResponse = UserResponse.pending,
    this.respondedAt,
    this.limitations = const <String>[],
    this.extra = const <String, Object?>{},
  });

  /// Llave estable. Dos cálculos sobre la misma lectura producen el mismo id,
  /// así que recalcular no duplica filas.
  final String id;

  final RecommendationKind kind;
  final DateTime issuedAt;

  final String? userId;
  final String deviceId;

  /// Identidad de la lectura que fundamentó la recomendación.
  ///
  /// `BioGTelemetry` no tiene columna `id`, así que se deriva de forma estable
  /// como `deviceId|epochMillisUtc`. Ver [buildReadingId]. Cuando el contrato
  /// de telemetría incorpore un id propio del hardware, este campo lo adopta
  /// sin cambiar la forma del registro.
  final String readingId;

  final String headlineEs;
  final String detailEs;

  /// Acción concreta (`regar`, `esperar`…) cuando aplica.
  final String? action;
  final String? urgency;
  final double? confidence01;
  final DateTime? validUntil;

  final bool requiresConfirmation;
  final bool requiresHumanReview;

  // ── Identidad agronómica ──────────────────────────────────────────────────
  final String? cropId;
  final String? cropLabel;
  final String? varietyId;
  final String? varietyAlias;
  final String? stageKey;
  final String? stageLabel;

  /// Versión del catálogo agronómico vigente al emitir.
  ///
  /// Ya existía en `DeviceCropContext` y se escribía en la base, pero nunca
  /// llegaba al evento, así que era imposible saber con qué catálogo se
  /// aconsejó.
  final String? catalogVersion;

  // ── Parcela ───────────────────────────────────────────────────────────────
  final String? parcelLabel;
  final double? parcelLat;
  final double? parcelLon;

  // ── Evidencia ─────────────────────────────────────────────────────────────
  final List<RecordedMetric> metrics;

  /// Clima exacto que se usó, no el que haya ahora.
  final AgronomicWeatherSnapshot? weather;

  /// Razones en lenguaje humano, en el orden en que pesaron.
  final List<String> reasons;

  /// Lo que el sistema declaró no saber.
  final List<String> limitations;

  final String engineVersion;
  final String schemaVersion;

  // ── Respuesta del usuario ─────────────────────────────────────────────────
  final UserResponse userResponse;
  final DateTime? respondedAt;

  final Map<String, Object?> extra;

  bool get isAnswered => userResponse.isClosed;

  bool isExpiredAt(DateTime now) {
    final until = validUntil;
    if (until == null) return false;
    return now.isAfter(until);
  }

  /// Id estable de una lectura.
  static String buildReadingId(String deviceId, DateTime timestamp) {
    return '$deviceId|${timestamp.toUtc().millisecondsSinceEpoch}';
  }

  /// Id estable de una recomendación.
  ///
  /// Incluye el tipo para que riego y fertilización sobre la misma lectura
  /// sean registros distintos, y la versión del motor para que una decisión
  /// recalculada tras cambiar las reglas NO sobrescriba la anterior: la
  /// historia de lo que se aconsejó no puede reescribirse.
  static String buildId({
    required RecommendationKind kind,
    required String readingId,
    required String engineVersion,
  }) {
    return '${kind.name}|$readingId|$engineVersion';
  }

  RecommendationRecord respond(UserResponse response, {required DateTime at}) {
    return copyWith(userResponse: response, respondedAt: at);
  }

  RecommendationRecord copyWith({
    UserResponse? userResponse,
    DateTime? respondedAt,
  }) {
    return RecommendationRecord(
      id: id,
      kind: kind,
      issuedAt: issuedAt,
      userId: userId,
      deviceId: deviceId,
      readingId: readingId,
      headlineEs: headlineEs,
      detailEs: detailEs,
      action: action,
      urgency: urgency,
      confidence01: confidence01,
      validUntil: validUntil,
      requiresConfirmation: requiresConfirmation,
      requiresHumanReview: requiresHumanReview,
      cropId: cropId,
      cropLabel: cropLabel,
      varietyId: varietyId,
      varietyAlias: varietyAlias,
      stageKey: stageKey,
      stageLabel: stageLabel,
      catalogVersion: catalogVersion,
      parcelLabel: parcelLabel,
      parcelLat: parcelLat,
      parcelLon: parcelLon,
      metrics: metrics,
      weather: weather,
      reasons: reasons,
      limitations: limitations,
      engineVersion: engineVersion,
      schemaVersion: schemaVersion,
      userResponse: userResponse ?? this.userResponse,
      respondedAt: respondedAt ?? this.respondedAt,
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'kind': kind.name,
    'issuedAt': issuedAt.toUtc().toIso8601String(),
    'userId': userId,
    'deviceId': deviceId,
    'readingId': readingId,
    'headline': headlineEs,
    'detail': detailEs,
    'action': action,
    'urgency': urgency,
    'confidence01': confidence01,
    'validUntil': validUntil?.toUtc().toIso8601String(),
    'requiresConfirmation': requiresConfirmation,
    'requiresHumanReview': requiresHumanReview,
    'cropId': cropId,
    'cropLabel': cropLabel,
    'varietyId': varietyId,
    'varietyAlias': varietyAlias,
    'stageKey': stageKey,
    'stageLabel': stageLabel,
    'catalogVersion': catalogVersion,
    'parcelLabel': parcelLabel,
    'parcelLat': parcelLat,
    'parcelLon': parcelLon,
    'metrics': metrics.map((m) => m.toJson()).toList(),
    'weather': weather?.toJson(),
    'reasons': reasons,
    'limitations': limitations,
    'engineVersion': engineVersion,
    'schemaVersion': schemaVersion,
    'userResponse': userResponse.name,
    'respondedAt': respondedAt?.toUtc().toIso8601String(),
    'extra': extra,
  };

  String encode() => jsonEncode(toJson());

  /// Devuelve `null` si la fila es ilegible. Un registro viejo con un formato
  /// que ya no se entiende nunca puede tumbar la pantalla de historial.
  static RecommendationRecord? fromJson(Map<String, dynamic> json) {
    try {
      final metricsRaw = json['metrics'];
      final metrics = <RecordedMetric>[];
      if (metricsRaw is List) {
        for (final m in metricsRaw) {
          if (m is! Map) continue;
          final parsed = RecordedMetric.fromJson(m.cast<String, dynamic>());
          if (parsed != null) metrics.add(parsed);
        }
      }

      final weatherRaw = json['weather'];
      final weather = weatherRaw is Map
          ? AgronomicWeatherSnapshot.fromJson(weatherRaw.cast<String, dynamic>())
          : null;

      final validUntilRaw = json['validUntil'];
      final respondedRaw = json['respondedAt'];

      return RecommendationRecord(
        id: json['id'] as String,
        kind: RecommendationKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => RecommendationKind.irrigation,
        ),
        issuedAt: DateTime.parse(json['issuedAt'] as String),
        userId: json['userId'] as String?,
        deviceId: (json['deviceId'] as String?) ?? '',
        readingId: (json['readingId'] as String?) ?? '',
        headlineEs: (json['headline'] as String?) ?? '',
        detailEs: (json['detail'] as String?) ?? '',
        action: json['action'] as String?,
        urgency: json['urgency'] as String?,
        confidence01: (json['confidence01'] as num?)?.toDouble(),
        validUntil: validUntilRaw is String
            ? DateTime.tryParse(validUntilRaw)
            : null,
        requiresConfirmation:
            (json['requiresConfirmation'] as bool?) ?? false,
        requiresHumanReview: (json['requiresHumanReview'] as bool?) ?? false,
        cropId: json['cropId'] as String?,
        cropLabel: json['cropLabel'] as String?,
        varietyId: json['varietyId'] as String?,
        varietyAlias: json['varietyAlias'] as String?,
        stageKey: json['stageKey'] as String?,
        stageLabel: json['stageLabel'] as String?,
        catalogVersion: json['catalogVersion'] as String?,
        parcelLabel: json['parcelLabel'] as String?,
        parcelLat: (json['parcelLat'] as num?)?.toDouble(),
        parcelLon: (json['parcelLon'] as num?)?.toDouble(),
        metrics: metrics,
        weather: weather,
        reasons:
            (json['reasons'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[],
        limitations:
            (json['limitations'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[],
        engineVersion: (json['engineVersion'] as String?) ?? 'desconocida',
        schemaVersion:
            (json['schemaVersion'] as String?) ??
            BioGEngineVersions.recommendationRecordSchema,
        userResponse: UserResponse.values.firstWhere(
          (r) => r.name == json['userResponse'],
          orElse: () => UserResponse.pending,
        ),
        respondedAt: respondedRaw is String
            ? DateTime.tryParse(respondedRaw)
            : null,
        extra:
            (json['extra'] as Map?)?.cast<String, Object?>() ??
            const <String, Object?>{},
      );
    } catch (_) {
      return null;
    }
  }

  /// Construye el registro a partir de una decisión de riego.
  ///
  /// Es la traducción que convierte una decisión efímera en memoria auditable.
  factory RecommendationRecord.fromIrrigationDecision({
    required IrrigationDecision decision,
    required String deviceId,
    required DateTime readingTimestamp,
    String? userId,
    String? cropId,
    String? cropLabel,
    String? varietyId,
    String? varietyAlias,
    String? catalogVersion,
    String? parcelLabel,
    double? parcelLat,
    double? parcelLon,
    bool? moistureIsPresent,
    bool? moistureIsCalibrated,
    int? moistureAgeMinutes,
  }) {
    final readingId = buildReadingId(deviceId, readingTimestamp);

    return RecommendationRecord(
      id: buildId(
        kind: RecommendationKind.irrigation,
        readingId: readingId,
        engineVersion: decision.engineVersion,
      ),
      kind: RecommendationKind.irrigation,
      issuedAt: decision.decidedAt,
      userId: userId,
      deviceId: deviceId,
      readingId: readingId,
      headlineEs: decision.headlineEs,
      detailEs: decision.detailEs,
      action: decision.action.name,
      urgency: decision.urgency.name,
      confidence01: decision.confidence01,
      validUntil: decision.validUntil,
      requiresConfirmation: decision.requiresConfirmation,
      requiresHumanReview: decision.requiresHumanReview,
      cropId: cropId ?? decision.evidence['cropId']?.toString(),
      cropLabel: cropLabel,
      varietyId: varietyId,
      varietyAlias: varietyAlias,
      stageKey: decision.stageKey,
      stageLabel: decision.stageLabel,
      catalogVersion: catalogVersion,
      parcelLabel: parcelLabel,
      parcelLat: parcelLat,
      parcelLon: parcelLon,
      metrics: <RecordedMetric>[
        RecordedMetric(
          key: 'soilMoisture',
          unit: '%',
          isPresent: moistureIsPresent ?? (decision.moisturePct != null),
          value: decision.moisturePct,
          band: decision.moistureBandName,
          measuredAt: readingTimestamp,
          ageMinutes: moistureAgeMinutes,
          isCalibrated: moistureIsCalibrated,
        ),
      ],
      weather: decision.weather,
      reasons: decision.observations
          .map((r) => r.textEs)
          .toList(growable: false),
      limitations: decision.limitations
          .map((r) => r.textEs)
          .toList(growable: false),
      engineVersion: decision.engineVersion,
      schemaVersion: BioGEngineVersions.recommendationRecordSchema,
      extra: <String, Object?>{'evidence': decision.evidence},
    );
  }
}
