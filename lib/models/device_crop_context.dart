import 'dart:convert';

enum CropLifecycleStatus { planned, planted, fallow }

enum DateConfidence { exact, estimated, unknown }

enum CropConfigSource { wizard, manualEdit, demo, imported }

class DeviceCropContext {
  final String deviceId;

  // identidad de catálogo
  final String cropCategoryId; // grain
  final String cropId; // maize
  final String profileId; // maize_generic, maize_mid, etc.
  final String? brandId; // dekalb, pioneer (solo maíz v1)
  final String? varietyId; // dekalb_dk2069_grain
  final String? varietyAlias; // visible label (DK-2069)
  final String? calendarTypeId; // pv, oi, riego, temporal

  // estado operativo
  final CropLifecycleStatus lifecycleStatus;
  final DateTime? sowingDate;
  final DateTime? plannedSowingDate;
  final DateConfidence sowingDateConfidence;

  // escala operativa
  final String? cultivationScaleId; // field, bed, pot

  // contexto adicional
  final String? sowingModeId; // rainfed / irrigated
  final String? timezone;
  final String? regionCode;
  final String? cycleLabel;

  /// Modo de establecimiento: siembra_directa | trasplante.
  ///
  /// Opcional; relevante para cultivos como tomate donde cambia el anclaje
  /// temporal del ciclo (el reloj biológico arranca en trasplante, no en
  /// semilla). Grano tradicional no lo usa.
  final String? establishmentModeId;

  // ── Contexto perenne (árboles/frutales) ─────────────────────────────────────
  //
  // Campos nullable usados solo por la categoría Árbol. Los cultivos anuales
  // (grano/hortaliza) los dejan en null y su semántica no cambia. La condición
  // "es perenne" NO se persiste: se deriva de cropCategoryId == tree (ver
  // CropCategory.tree). Estos campos quedan estructurados para la Fase 2 del
  // runtime perenne; en esta fase no alteran comportamiento.

  /// Estado fisiológico del perenne (p. ej. dormancia, brotación, crecimiento).
  /// No aplica a anuales.
  final String? perennialStateId;

  /// Etapa fenológica visible del ciclo productivo anual del árbol.
  /// No aplica a anuales.
  final String? phenologyStageId;

  /// Fecha de anclaje del ciclo perenne (no es fecha de siembra). El reloj de un
  /// árbol no arranca en siembra ni "termina"; el ciclo productivo se reinicia.
  /// No reutilizar [sowingDate] para árboles.
  final DateTime? perennialAnchorDate;

  /// Tipo del anclaje perenne (p. ej. brotación, floración, plantación).
  /// Acompaña a [perennialAnchorDate]. No aplica a anuales.
  final String? perennialAnchorTypeId;

  // trazabilidad
  final String catalogVersion;
  final CropConfigSource source;
  final DateTime configuredAt;
  final DateTime updatedAt;

  const DeviceCropContext({
    required this.deviceId,
    required this.cropCategoryId,
    required this.cropId,
    required this.profileId,
    required this.lifecycleStatus,
    required this.sowingDateConfidence,
    required this.catalogVersion,
    required this.source,
    required this.configuredAt,
    required this.updatedAt,
    this.brandId,
    this.varietyId,
    this.varietyAlias,
    this.calendarTypeId,
    this.sowingDate,
    this.plannedSowingDate,
    this.cultivationScaleId,
    this.sowingModeId,
    this.timezone,
    this.regionCode,
    this.cycleLabel,
    this.establishmentModeId,
    this.perennialStateId,
    this.phenologyStageId,
    this.perennialAnchorDate,
    this.perennialAnchorTypeId,
  });

  DeviceCropContext copyWith({
    String? deviceId,
    String? cropCategoryId,
    String? cropId,
    String? profileId,
    Object? brandId = _sentinel,
    Object? varietyId = _sentinel,
    Object? varietyAlias = _sentinel,
    Object? calendarTypeId = _sentinel,
    CropLifecycleStatus? lifecycleStatus,
    Object? sowingDate = _sentinel,
    Object? plannedSowingDate = _sentinel,
    DateConfidence? sowingDateConfidence,
    Object? cultivationScaleId = _sentinel,
    Object? sowingModeId = _sentinel,
    Object? timezone = _sentinel,
    Object? regionCode = _sentinel,
    Object? cycleLabel = _sentinel,
    Object? establishmentModeId = _sentinel,
    Object? perennialStateId = _sentinel,
    Object? phenologyStageId = _sentinel,
    Object? perennialAnchorDate = _sentinel,
    Object? perennialAnchorTypeId = _sentinel,
    String? catalogVersion,
    CropConfigSource? source,
    DateTime? configuredAt,
    DateTime? updatedAt,
  }) {
    return DeviceCropContext(
      deviceId: deviceId ?? this.deviceId,
      cropCategoryId: cropCategoryId ?? this.cropCategoryId,
      cropId: cropId ?? this.cropId,
      profileId: profileId ?? this.profileId,
      brandId: identical(brandId, _sentinel)
          ? this.brandId
          : brandId as String?,
      varietyId: identical(varietyId, _sentinel)
          ? this.varietyId
          : varietyId as String?,
      varietyAlias: identical(varietyAlias, _sentinel)
          ? this.varietyAlias
          : varietyAlias as String?,
      calendarTypeId: identical(calendarTypeId, _sentinel)
          ? this.calendarTypeId
          : calendarTypeId as String?,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      sowingDate: identical(sowingDate, _sentinel)
          ? this.sowingDate
          : sowingDate as DateTime?,
      plannedSowingDate: identical(plannedSowingDate, _sentinel)
          ? this.plannedSowingDate
          : plannedSowingDate as DateTime?,
      sowingDateConfidence: sowingDateConfidence ?? this.sowingDateConfidence,
      cultivationScaleId: identical(cultivationScaleId, _sentinel)
          ? this.cultivationScaleId
          : cultivationScaleId as String?,
      sowingModeId: identical(sowingModeId, _sentinel)
          ? this.sowingModeId
          : sowingModeId as String?,
      timezone: identical(timezone, _sentinel)
          ? this.timezone
          : timezone as String?,
      regionCode: identical(regionCode, _sentinel)
          ? this.regionCode
          : regionCode as String?,
      cycleLabel: identical(cycleLabel, _sentinel)
          ? this.cycleLabel
          : cycleLabel as String?,
      establishmentModeId: identical(establishmentModeId, _sentinel)
          ? this.establishmentModeId
          : establishmentModeId as String?,
      perennialStateId: identical(perennialStateId, _sentinel)
          ? this.perennialStateId
          : perennialStateId as String?,
      phenologyStageId: identical(phenologyStageId, _sentinel)
          ? this.phenologyStageId
          : phenologyStageId as String?,
      perennialAnchorDate: identical(perennialAnchorDate, _sentinel)
          ? this.perennialAnchorDate
          : perennialAnchorDate as DateTime?,
      perennialAnchorTypeId: identical(perennialAnchorTypeId, _sentinel)
          ? this.perennialAnchorTypeId
          : perennialAnchorTypeId as String?,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      source: source ?? this.source,
      configuredAt: configuredAt ?? this.configuredAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'cropCategoryId': cropCategoryId,
      'cropId': cropId,
      'profileId': profileId,
      'brandId': brandId,
      'varietyId': varietyId,
      'varietyAlias': varietyAlias,
      'calendarTypeId': calendarTypeId,
      'lifecycleStatus': lifecycleStatus.name,
      'sowingDate': sowingDate?.toIso8601String(),
      'plannedSowingDate': plannedSowingDate?.toIso8601String(),
      'sowingDateConfidence': sowingDateConfidence.name,
      'cultivationScaleId': cultivationScaleId,
      'sowingModeId': sowingModeId,
      'timezone': timezone,
      'regionCode': regionCode,
      'cycleLabel': cycleLabel,
      'establishmentModeId': establishmentModeId,
      'perennialStateId': perennialStateId,
      'phenologyStageId': phenologyStageId,
      'perennialAnchorDate': perennialAnchorDate?.toIso8601String(),
      'perennialAnchorTypeId': perennialAnchorTypeId,
      'catalogVersion': catalogVersion,
      'source': source.name,
      'configuredAt': configuredAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DeviceCropContext.fromJson(Map<String, dynamic> json) {
    return DeviceCropContext(
      deviceId: json['deviceId'] as String,
      cropCategoryId: json['cropCategoryId'] as String,
      cropId: json['cropId'] as String,
      profileId: json['profileId'] as String,
      brandId: json['brandId'] as String?,
      varietyId: json['varietyId'] as String?,
      varietyAlias: json['varietyAlias'] as String?,
      calendarTypeId: json['calendarTypeId'] as String?,
      lifecycleStatus: CropLifecycleStatus.values.byName(
        json['lifecycleStatus'] as String,
      ),
      sowingDate: json['sowingDate'] == null
          ? null
          : DateTime.parse(json['sowingDate'] as String),
      plannedSowingDate: json['plannedSowingDate'] == null
          ? null
          : DateTime.parse(json['plannedSowingDate'] as String),
      sowingDateConfidence: DateConfidence.values.byName(
        json['sowingDateConfidence'] as String,
      ),
      cultivationScaleId: json['cultivationScaleId'] as String?,
      sowingModeId: json['sowingModeId'] as String?,
      timezone: json['timezone'] as String?,
      regionCode: json['regionCode'] as String?,
      cycleLabel: json['cycleLabel'] as String?,
      establishmentModeId: json['establishmentModeId'] as String?,
      // Contextos antiguos no traen estas claves: quedan null de forma segura.
      perennialStateId: json['perennialStateId'] as String?,
      phenologyStageId: json['phenologyStageId'] as String?,
      perennialAnchorDate: json['perennialAnchorDate'] == null
          ? null
          : DateTime.parse(json['perennialAnchorDate'] as String),
      perennialAnchorTypeId: json['perennialAnchorTypeId'] as String?,
      catalogVersion: json['catalogVersion'] as String,
      source: CropConfigSource.values.byName(json['source'] as String),
      configuredAt: DateTime.parse(json['configuredAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String encode() => jsonEncode(toJson());

  factory DeviceCropContext.decode(String raw) {
    return DeviceCropContext.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

const Object _sentinel = Object();
