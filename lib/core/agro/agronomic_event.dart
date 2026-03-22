// lib/core/agro/agronomic_event.dart

enum AgronomicEventType {
  // Contexto general
  genericMode,
  preSowing,
  cropActivated,
  stageTransition,

  // Humedad
  lowMoisture,
  highMoisture,
  stableMoisture,

  // pH
  lowPh,
  highPh,
  stablePh,

  // Resistencia / compactación
  soilCompaction,
  goodSoilStructure,

  // Temperatura
  heatStress,
  coldStress,
  stableSoilTemp,

  // Nutrientes
  npkReading,
  nutrientImbalance,
  nitrogenLow,
  phosphorusLow,
  potassiumLow,

  // Tendencia / estado combinado
  stableSoil,
  combinedStress,
  recovery,

  // Recomendaciones / calendario
  irrigationRecommended,
  fertilizationRecommended,
}

enum AgronomicEventSeverity { info, caution, warning, critical }

class AgronomicEvent {
  const AgronomicEvent({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.deviceId,
    this.metricKey,
    this.seedProfileId,
    this.seedAlias,
    this.stageKey,
    this.stageLabel,
    this.isInformative = false,
    this.isCritical = false,
    this.metadata = const <String, Object?>{},
  });

  final AgronomicEventType type;
  final AgronomicEventSeverity severity;

  /// Título corto para UI.
  final String title;

  /// Mensaje farmer-friendly.
  final String message;

  /// Momento del evento.
  final DateTime timestamp;

  /// Opcional: BioG específico al que pertenece.
  final String? deviceId;

  /// Ejemplo: moisture, ph, resistance, soilTemp, n, p, k, npk.
  final String? metricKey;

  /// ID interno del perfil agrícola si aplica.
  final String? seedProfileId;

  /// Alias visible de la semilla / cultivo.
  final String? seedAlias;

  /// Clave técnica de etapa si aplica.
  final String? stageKey;

  /// Label amigable de etapa si aplica.
  final String? stageLabel;

  /// Para distinguir eventos informativos en History / Dashboard.
  final bool isInformative;

  /// Para distinguir eventos críticos rápidamente.
  final bool isCritical;

  /// Campo flexible para guardar datos extra sin romper contrato.
  final Map<String, Object?> metadata;

  bool get isAlertLike =>
      severity == AgronomicEventSeverity.warning ||
      severity == AgronomicEventSeverity.critical;

  bool get isSevere =>
      severity == AgronomicEventSeverity.critical || isCritical;

  bool get isContextEvent =>
      type == AgronomicEventType.genericMode ||
      type == AgronomicEventType.preSowing ||
      type == AgronomicEventType.cropActivated ||
      type == AgronomicEventType.stageTransition;

  AgronomicEvent copyWith({
    AgronomicEventType? type,
    AgronomicEventSeverity? severity,
    String? title,
    String? message,
    DateTime? timestamp,
    String? deviceId,
    String? metricKey,
    String? seedProfileId,
    String? seedAlias,
    String? stageKey,
    String? stageLabel,
    bool? isInformative,
    bool? isCritical,
    Map<String, Object?>? metadata,
  }) {
    return AgronomicEvent(
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      metricKey: metricKey ?? this.metricKey,
      seedProfileId: seedProfileId ?? this.seedProfileId,
      seedAlias: seedAlias ?? this.seedAlias,
      stageKey: stageKey ?? this.stageKey,
      stageLabel: stageLabel ?? this.stageLabel,
      isInformative: isInformative ?? this.isInformative,
      isCritical: isCritical ?? this.isCritical,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'AgronomicEvent('
        'type: $type, '
        'severity: $severity, '
        'title: $title, '
        'message: $message, '
        'timestamp: $timestamp, '
        'deviceId: $deviceId, '
        'metricKey: $metricKey, '
        'seedProfileId: $seedProfileId, '
        'seedAlias: $seedAlias, '
        'stageKey: $stageKey, '
        'stageLabel: $stageLabel, '
        'isInformative: $isInformative, '
        'isCritical: $isCritical, '
        'metadata: $metadata'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AgronomicEvent &&
        other.type == type &&
        other.severity == severity &&
        other.title == title &&
        other.message == message &&
        other.timestamp == timestamp &&
        other.deviceId == deviceId &&
        other.metricKey == metricKey &&
        other.seedProfileId == seedProfileId &&
        other.seedAlias == seedAlias &&
        other.stageKey == stageKey &&
        other.stageLabel == stageLabel &&
        other.isInformative == isInformative &&
        other.isCritical == isCritical &&
        _mapEquals(other.metadata, metadata);
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      severity,
      title,
      message,
      timestamp,
      deviceId,
      metricKey,
      seedProfileId,
      seedAlias,
      stageKey,
      stageLabel,
      isInformative,
      isCritical,
      Object.hashAll(metadata.entries.map((e) => Object.hash(e.key, e.value))),
    );
  }

  static bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
