import 'dart:convert';

enum YieldInputMethod {
  /// El productor captura directamente la población objetivo por hectárea.
  populationPerArea,

  /// El productor captura el total de semillas sembradas.
  totalSeeds,

  /// El productor captura sacos sembrados y semillas por saco.
  bagsAndSeedsPerBag,
}

enum YieldAreaUnit { hectare, squareMeter, pot }

class YieldProjectionConfig {
  final String deviceId;
  final String cropId;

  /// Escala operativa del dispositivo (`field`, `bed`, `pot`).
  final String? cultivationScaleId;

  /// Superficie sembrada en la unidad elegida.
  final double? areaValue;
  final YieldAreaUnit areaUnit;

  /// Método con el que el productor capturó la base de siembra.
  final YieldInputMethod inputMethod;

  /// Población objetivo por hectárea cuando [inputMethod] es
  /// [YieldInputMethod.populationPerArea].
  final double? targetPopulationPerHa;

  /// Total de semillas sembradas cuando [inputMethod] es
  /// [YieldInputMethod.totalSeeds].
  final double? totalSeedsSown;

  /// Sacos sembrados cuando [inputMethod] es
  /// [YieldInputMethod.bagsAndSeedsPerBag].
  final double? bagsSown;

  /// Semillas por saco cuando [inputMethod] es
  /// [YieldInputMethod.bagsAndSeedsPerBag].
  final double? seedsPerBag;

  /// Meta objetivo del productor en toneladas por hectárea.
  final double? targetYieldTonPerHa;

  /// Precio estimado por tonelada. Opcional.
  final double? estimatedPricePerTon;

  /// Notas opcionales del productor o del flujo.
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const YieldProjectionConfig({
    required this.deviceId,
    required this.cropId,
    required this.areaUnit,
    required this.inputMethod,
    required this.createdAt,
    required this.updatedAt,
    this.cultivationScaleId,
    this.areaValue,
    this.targetPopulationPerHa,
    this.totalSeedsSown,
    this.bagsSown,
    this.seedsPerBag,
    this.targetYieldTonPerHa,
    this.estimatedPricePerTon,
    this.notes,
  }) : assert(deviceId != ''),
       assert(cropId != '');

  factory YieldProjectionConfig.initial({
    required String deviceId,
    required String cropId,
    String? cultivationScaleId,
    YieldAreaUnit areaUnit = YieldAreaUnit.hectare,
    YieldInputMethod inputMethod = YieldInputMethod.populationPerArea,
    DateTime? now,
  }) {
    final ts = now ?? DateTime.now();
    return YieldProjectionConfig(
      deviceId: deviceId.trim(),
      cropId: cropId.trim(),
      cultivationScaleId: _normalizeNullable(cultivationScaleId),
      areaUnit: areaUnit,
      inputMethod: inputMethod,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  YieldProjectionConfig copyWith({
    String? deviceId,
    String? cropId,
    Object? cultivationScaleId = _sentinel,
    Object? areaValue = _sentinel,
    YieldAreaUnit? areaUnit,
    YieldInputMethod? inputMethod,
    Object? targetPopulationPerHa = _sentinel,
    Object? totalSeedsSown = _sentinel,
    Object? bagsSown = _sentinel,
    Object? seedsPerBag = _sentinel,
    Object? targetYieldTonPerHa = _sentinel,
    Object? estimatedPricePerTon = _sentinel,
    Object? notes = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return YieldProjectionConfig(
      deviceId: (deviceId ?? this.deviceId).trim(),
      cropId: (cropId ?? this.cropId).trim(),
      cultivationScaleId: identical(cultivationScaleId, _sentinel)
          ? this.cultivationScaleId
          : _normalizeNullable(cultivationScaleId as String?),
      areaValue: identical(areaValue, _sentinel)
          ? this.areaValue
          : _toNullableDouble(areaValue),
      areaUnit: areaUnit ?? this.areaUnit,
      inputMethod: inputMethod ?? this.inputMethod,
      targetPopulationPerHa: identical(targetPopulationPerHa, _sentinel)
          ? this.targetPopulationPerHa
          : _toNullableDouble(targetPopulationPerHa),
      totalSeedsSown: identical(totalSeedsSown, _sentinel)
          ? this.totalSeedsSown
          : _toNullableDouble(totalSeedsSown),
      bagsSown: identical(bagsSown, _sentinel)
          ? this.bagsSown
          : _toNullableDouble(bagsSown),
      seedsPerBag: identical(seedsPerBag, _sentinel)
          ? this.seedsPerBag
          : _toNullableDouble(seedsPerBag),
      targetYieldTonPerHa: identical(targetYieldTonPerHa, _sentinel)
          ? this.targetYieldTonPerHa
          : _toNullableDouble(targetYieldTonPerHa),
      estimatedPricePerTon: identical(estimatedPricePerTon, _sentinel)
          ? this.estimatedPricePerTon
          : _toNullableDouble(estimatedPricePerTon),
      notes: identical(notes, _sentinel)
          ? this.notes
          : _normalizeNullable(notes as String?),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Área convertida a hectáreas cuando aplica.
  ///
  /// Para `pot` devuelve `null` porque no hay conversión directa válida a ha.
  double? get areaInHectares {
    final value = areaValue;
    if (value == null || value <= 0) return null;

    switch (areaUnit) {
      case YieldAreaUnit.hectare:
        return value;
      case YieldAreaUnit.squareMeter:
        return value / 10000.0;
      case YieldAreaUnit.pot:
        return null;
    }
  }

  /// Total estimado de semillas sembradas según el método de captura.
  double? get estimatedSeedsSown {
    switch (inputMethod) {
      case YieldInputMethod.populationPerArea:
        final population = _positiveOrNull(targetPopulationPerHa);
        final hectares = areaInHectares;
        if (population == null || hectares == null) return null;
        return population * hectares;

      case YieldInputMethod.totalSeeds:
        return _positiveOrNull(totalSeedsSown);

      case YieldInputMethod.bagsAndSeedsPerBag:
        final bags = _positiveOrNull(bagsSown);
        final seeds = _positiveOrNull(seedsPerBag);
        if (bags == null || seeds == null) return null;
        return bags * seeds;
    }
  }

  /// Población estimada por hectárea derivada del método de captura.
  double? get estimatedPopulationPerHa {
    switch (inputMethod) {
      case YieldInputMethod.populationPerArea:
        return _positiveOrNull(targetPopulationPerHa);

      case YieldInputMethod.totalSeeds:
      case YieldInputMethod.bagsAndSeedsPerBag:
        final totalSeeds = estimatedSeedsSown;
        final hectares = areaInHectares;
        if (totalSeeds == null || hectares == null || hectares <= 0) {
          return null;
        }
        return totalSeeds / hectares;
    }
  }

  bool get hasArea => _positiveOrNull(areaValue) != null;

  bool get hasPopulationInput {
    switch (inputMethod) {
      case YieldInputMethod.populationPerArea:
        return _positiveOrNull(targetPopulationPerHa) != null;
      case YieldInputMethod.totalSeeds:
        return _positiveOrNull(totalSeedsSown) != null;
      case YieldInputMethod.bagsAndSeedsPerBag:
        return _positiveOrNull(bagsSown) != null &&
            _positiveOrNull(seedsPerBag) != null;
    }
  }

  bool get hasTargetYield => _positiveOrNull(targetYieldTonPerHa) != null;

  bool get hasPriceInput => _positiveOrNull(estimatedPricePerTon) != null;

  /// Config suficiente para activar la proyección v1.
  ///
  /// Nota UX actual: la base manual obligatoria ya no pide meta de
  /// rendimiento. Para esta etapa basta con superficie + siembra válida.
  bool get isReadyForProjection =>
      hasArea && hasPopulationInput && estimatedPopulationPerHa != null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'cropId': cropId,
      'cultivationScaleId': cultivationScaleId,
      'areaValue': areaValue,
      'areaUnit': areaUnit.name,
      'inputMethod': inputMethod.name,
      'targetPopulationPerHa': targetPopulationPerHa,
      'totalSeedsSown': totalSeedsSown,
      'bagsSown': bagsSown,
      'seedsPerBag': seedsPerBag,
      'targetYieldTonPerHa': targetYieldTonPerHa,
      'estimatedPricePerTon': estimatedPricePerTon,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory YieldProjectionConfig.fromJson(Map<String, dynamic> json) {
    return YieldProjectionConfig(
      deviceId: (json['deviceId'] as String).trim(),
      cropId: (json['cropId'] as String).trim(),
      cultivationScaleId: _normalizeNullable(
        json['cultivationScaleId'] as String?,
      ),
      areaValue: _numToDouble(json['areaValue']),
      areaUnit: YieldAreaUnit.values.byName(json['areaUnit'] as String),
      inputMethod: YieldInputMethod.values.byName(
        json['inputMethod'] as String,
      ),
      targetPopulationPerHa: _numToDouble(json['targetPopulationPerHa']),
      totalSeedsSown: _numToDouble(json['totalSeedsSown']),
      bagsSown: _numToDouble(json['bagsSown']),
      seedsPerBag: _numToDouble(json['seedsPerBag']),
      targetYieldTonPerHa: _numToDouble(json['targetYieldTonPerHa']),
      estimatedPricePerTon: _numToDouble(json['estimatedPricePerTon']),
      notes: _normalizeNullable(json['notes'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String encode() => jsonEncode(toJson());

  factory YieldProjectionConfig.decode(String raw) {
    return YieldProjectionConfig.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}

const Object _sentinel = Object();

String? _normalizeNullable(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

double? _numToDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

double? _toNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

double? _positiveOrNull(double? value) {
  if (value == null || value <= 0) return null;
  return value;
}
