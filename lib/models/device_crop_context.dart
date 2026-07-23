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

  // ── Contexto ornamental (establecimiento + mantenimiento) ────────────────
  // Campos aditivos y nullable. No reutilizan la semántica fenológica de los
  // árboles y no alteran contextos anuales o perennes existentes.

  final String? lifecycleModeId;
  final String? ornamentalStageId;
  final DateTime? ornamentalAnchorDate;
  final String? ornamentalAnchorTypeId;
  final DateConfidence? ornamentalAnchorDateConfidence;
  final double? ornamentalStageConfidence;

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
    this.lifecycleModeId,
    this.ornamentalStageId,
    this.ornamentalAnchorDate,
    this.ornamentalAnchorTypeId,
    this.ornamentalAnchorDateConfidence,
    this.ornamentalStageConfidence,
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
    Object? lifecycleModeId = _sentinel,
    Object? ornamentalStageId = _sentinel,
    Object? ornamentalAnchorDate = _sentinel,
    Object? ornamentalAnchorTypeId = _sentinel,
    Object? ornamentalAnchorDateConfidence = _sentinel,
    Object? ornamentalStageConfidence = _sentinel,
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
      lifecycleModeId: identical(lifecycleModeId, _sentinel)
          ? this.lifecycleModeId
          : lifecycleModeId as String?,
      ornamentalStageId: identical(ornamentalStageId, _sentinel)
          ? this.ornamentalStageId
          : ornamentalStageId as String?,
      ornamentalAnchorDate: identical(ornamentalAnchorDate, _sentinel)
          ? this.ornamentalAnchorDate
          : ornamentalAnchorDate as DateTime?,
      ornamentalAnchorTypeId: identical(ornamentalAnchorTypeId, _sentinel)
          ? this.ornamentalAnchorTypeId
          : ornamentalAnchorTypeId as String?,
      ornamentalAnchorDateConfidence:
          identical(ornamentalAnchorDateConfidence, _sentinel)
          ? this.ornamentalAnchorDateConfidence
          : ornamentalAnchorDateConfidence as DateConfidence?,
      ornamentalStageConfidence: identical(ornamentalStageConfidence, _sentinel)
          ? this.ornamentalStageConfidence
          : ornamentalStageConfidence as double?,
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
      'lifecycleModeId': lifecycleModeId,
      'ornamentalStageId': ornamentalStageId,
      'ornamentalAnchorDate': ornamentalAnchorDate?.toIso8601String(),
      'ornamentalAnchorTypeId': ornamentalAnchorTypeId,
      'ornamentalAnchorDateConfidence': ornamentalAnchorDateConfidence?.name,
      'ornamentalStageConfidence': ornamentalStageConfidence,
      'catalogVersion': catalogVersion,
      'source': source.name,
      'configuredAt': configuredAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DeviceCropContext.fromJson(Map<String, dynamic> json) {
    final String rawCropId = json['cropId'] as String;
    final String normalizedCropId = rawCropId.trim().toLowerCase();
    final String rawCategoryId = json['cropCategoryId'] as String;
    final String rawProfileId = json['profileId'] as String;
    final String normalizedProfileId = rawProfileId.trim().toLowerCase();
    // La categoría ornamental por sí sola no identifica al cultivo: una rosa u
    // otra ornamental futura nunca debe migrar a crop_cactus ni a crop_succulent
    // por compartir categoría. Solo aceptamos IDs/aliases del cultivo.
    final String? ornamentalCropId = _ornamentalCropIdOrNull(normalizedCropId);
    final bool isOrnamental = ornamentalCropId != null;
    // El rosal es ornamental pero de MODO distinto (recurring_bloom). Guarda en
    // los mismos campos, pero con su propia canonicalización de perfil/etapa;
    // nunca pasa por la de las ornamentales de establecimiento (que borraría sus
    // estados de floración).
    final String? roseCropId = _roseCropIdOrNull(normalizedCropId);
    final bool isRose = roseCropId != null;
    final bool isOrnamentalLike = isOrnamental || isRose;

    final String canonicalProfileId = isOrnamental
        ? _resolvePersistedOrnamentalProfileId(
            cropId: ornamentalCropId!,
            profileId: normalizedProfileId,
            varietyId: json['varietyId'] as String?,
            varietyAlias: json['varietyAlias'] as String?,
          )
        : isRose
        ? _resolvePersistedRoseProfileId(
            profileId: normalizedProfileId,
            varietyId: json['varietyId'] as String?,
            varietyAlias: json['varietyAlias'] as String?,
          )
        : rawProfileId;

    DateTime? parseDate(Object? raw) =>
        raw is String && raw.isNotEmpty ? DateTime.parse(raw) : null;

    final String? legacyOrnamentalStage = isOrnamentalLike
        ? json['perennialStateId'] as String?
        : null;
    final DateTime? legacyOrnamentalAnchor = isOrnamentalLike
        ? parseDate(json['perennialAnchorDate'])
        : null;
    final String? legacyOrnamentalAnchorType = isOrnamentalLike
        ? json['perennialAnchorTypeId'] as String?
        : null;
    final DateTime? legacyOrnamentalSowingDate = isOrnamentalLike
        ? parseDate(json['sowingDate'])
        : null;
    final CropLifecycleStatus rawLifecycleStatus = CropLifecycleStatus.values
        .byName(json['lifecycleStatus'] as String);
    return DeviceCropContext(
      deviceId: json['deviceId'] as String,
      cropCategoryId: isOrnamentalLike ? 'ornamental' : rawCategoryId,
      cropId: isOrnamental
          ? ornamentalCropId!
          : isRose
          ? roseCropId!
          : rawCropId,
      profileId: canonicalProfileId,
      brandId: json['brandId'] as String?,
      // En las ornamentales el profileId también es el id canónico de la opción
      // elegida. Conservarlo aquí evita que un roundtrip borre la selección y
      // obligue al runtime a caer en el perfil general.
      varietyId: isOrnamentalLike
          ? canonicalProfileId
          : json['varietyId'] as String?,
      varietyAlias: isOrnamental
          ? _canonicalOrnamentalVisibleAlias(
              ornamentalCropId!,
              json['varietyAlias'] as String?,
              canonicalProfileId,
            )
          : isRose
          ? _canonicalRoseVisibleAlias(
              json['varietyAlias'] as String?,
              canonicalProfileId,
            )
          : json['varietyAlias'] as String?,
      calendarTypeId: json['calendarTypeId'] as String?,
      lifecycleStatus:
          isOrnamentalLike && rawLifecycleStatus == CropLifecycleStatus.fallow
          ? CropLifecycleStatus.planted
          : rawLifecycleStatus,
      sowingDate: isOrnamentalLike || json['sowingDate'] == null
          ? null
          : DateTime.parse(json['sowingDate'] as String),
      plannedSowingDate: isOrnamentalLike || json['plannedSowingDate'] == null
          ? null
          : DateTime.parse(json['plannedSowingDate'] as String),
      sowingDateConfidence: DateConfidence.values.byName(
        json['sowingDateConfidence'] as String,
      ),
      cultivationScaleId: isOrnamentalLike
          ? null
          : json['cultivationScaleId'] as String?,
      sowingModeId: isOrnamentalLike ? null : json['sowingModeId'] as String?,
      timezone: json['timezone'] as String?,
      regionCode: json['regionCode'] as String?,
      cycleLabel: json['cycleLabel'] as String?,
      establishmentModeId: json['establishmentModeId'] as String?,
      // Contextos antiguos no traen estas claves: quedan null de forma segura.
      perennialStateId: isOrnamentalLike
          ? null
          : json['perennialStateId'] as String?,
      phenologyStageId: isOrnamentalLike
          ? null
          : json['phenologyStageId'] as String?,
      perennialAnchorDate: isOrnamentalLike
          ? null
          : parseDate(json['perennialAnchorDate']),
      perennialAnchorTypeId: isOrnamentalLike
          ? null
          : json['perennialAnchorTypeId'] as String?,
      lifecycleModeId:
          json['lifecycleModeId'] as String? ??
          (isOrnamental
              ? 'establishment_maintenance'
              : isRose
              ? 'recurring_bloom'
              : null),
      ornamentalStageId: isOrnamental
          ? _canonicalOrnamentalStageId(
              json['ornamentalStageId'] as String? ?? legacyOrnamentalStage,
            )
          : isRose
          ? _canonicalRoseStageId(
              json['ornamentalStageId'] as String? ?? legacyOrnamentalStage,
            )
          : json['ornamentalStageId'] as String?,
      ornamentalAnchorDate:
          parseDate(json['ornamentalAnchorDate']) ??
          legacyOrnamentalAnchor ??
          legacyOrnamentalSowingDate,
      ornamentalAnchorTypeId:
          json['ornamentalAnchorTypeId'] as String? ??
          legacyOrnamentalAnchorType,
      ornamentalAnchorDateConfidence:
          _dateConfidenceOrNull(json['ornamentalAnchorDateConfidence']) ??
          (isOrnamentalLike
              ? DateConfidence.values.byName(
                  json['sowingDateConfidence'] as String,
                )
              : null),
      ornamentalStageConfidence:
          (json['ornamentalStageConfidence'] as num?)?.toDouble() ??
          (isOrnamentalLike ? 0.25 : null),
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

DateConfidence? _dateConfidenceOrNull(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    return DateConfidence.values.byName(raw);
  } catch (_) {
    return null;
  }
}

// ── Ornamentales (establecimiento + mantenimiento) ───────────────────────────
//
// El modelo no importa el catálogo (evita ciclos), así que los ids/aliases de
// entrada de las ornamentales viven aquí. Solo se aceptan alias del CULTIVO, no
// de la categoría: una ornamental futura nunca migra sola a cactus o suculenta.

const Set<String> _cactusCropAliases = <String>{
  'crop_cactus',
  'cactus',
  'cactos',
  'cacto',
  'cactus ornamental',
  'cactus desertico',
  'cactus desértico',
  'cactaceae',
  'cactacea',
  'cactácea',
  'cactus_generic',
  'cactus_mini',
  'cactus_columnar',
};

const Set<String> _succulentCropAliases = <String>{
  'crop_succulent',
  'succulent',
  'succulents',
  'suculenta',
  'suculentas',
  'planta suculenta',
  'plantas suculentas',
  'planta crasa',
  'crasa',
  'crasas',
  'suculenta ornamental',
};

const Set<String> _aloeCropAliases = <String>{
  'crop_aloe',
  'aloe',
  'aloe vera',
  'sabila',
  'sábila',
  'zabila',
  'zábila',
  'sabila ornamental',
  'planta de sabila',
  'planta de sábila',
};

const Set<String> _agaveCropAliases = <String>{
  'crop_agave',
  'agave',
  'agaves',
  'maguey',
  'magueyes',
  'planta de maguey',
  'planta de agave',
};

/// Devuelve el cropId canónico de la ornamental, o `null` si no lo es.
String? _ornamentalCropIdOrNull(String normalizedCropId) {
  if (_cactusCropAliases.contains(normalizedCropId)) return 'crop_cactus';
  if (_succulentCropAliases.contains(normalizedCropId)) return 'crop_succulent';
  if (_aloeCropAliases.contains(normalizedCropId)) return 'crop_aloe';
  if (_agaveCropAliases.contains(normalizedCropId)) return 'crop_agave';
  return null;
}

String _ornamentalGeneralProfileId(String cropId) => switch (cropId) {
  'crop_succulent' => 'su_skip',
  'crop_aloe' => 'sa_skip',
  'crop_agave' => 'mg_skip',
  _ => 'ca_skip',
};

String? _canonicalOrnamentalProfileIdOrNull(String cropId, String? value) {
  return switch (cropId) {
    'crop_succulent' => _canonicalSucculentProfileIdOrNull(value),
    'crop_aloe' => _canonicalAloeProfileIdOrNull(value),
    'crop_agave' => _canonicalAgaveProfileIdOrNull(value),
    _ => _canonicalCactusProfileIdOrNull(value),
  };
}

String? _canonicalCactusProfileIdOrNull(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'ca_skip' ||
    'ca-skip' ||
    'caskip' ||
    'cactus' ||
    'cactus general' ||
    'no sé / cactus general' ||
    'no se / cactus general' ||
    'cactus_generic' => 'ca_skip',
    'ca_01_desert_container' ||
    'ca-01' ||
    'ca01' ||
    'ca_01' ||
    'cactus de maceta' ||
    'cactus mini' ||
    'cactus_mini' => 'ca_01_desert_container',
    'ca_02_barrel_biznaga' ||
    'ca-02' ||
    'ca02' ||
    'ca_02' ||
    'biznaga' ||
    'cactus barril' ||
    'biznaga o cactus barril' => 'ca_02_barrel_biznaga',
    'ca_03_columnar_landscape' ||
    'ca-03' ||
    'ca03' ||
    'ca_03' ||
    'cactus columna' ||
    'cactus columna u órgano' ||
    'cactus columnar u órgano' ||
    'cactus_columnar' => 'ca_03_columnar_landscape',
    'ca_04_clustered_desert' ||
    'ca-04' ||
    'ca04' ||
    'ca_04' ||
    'cactus agrupado' ||
    'cactus agrupado o ramificado' ||
    'cactus agrupado o de varios tallos' => 'ca_04_clustered_desert',
    _ => null,
  };
}

String? _canonicalSucculentProfileIdOrNull(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'su_skip' ||
    'su-skip' ||
    'suskip' ||
    'suculenta' ||
    'suculenta general' ||
    'no sé / suculenta general' ||
    'no se / suculenta general' ||
    'planta crasa' ||
    'crasa' => 'su_skip',
    'su_01_rosette_bright_light' ||
    'su-01' ||
    'su01' ||
    'su_01' ||
    'suculenta de roseta' ||
    'echeveria' ||
    'rosa de piedra' => 'su_01_rosette_bright_light',
    'su_02_trailing_cascading' ||
    'su-02' ||
    'su02' ||
    'su_02' ||
    'suculenta colgante' ||
    'cola de burro' ||
    'collar de perlas' => 'su_02_trailing_cascading',
    'su_03_branching_woody' ||
    'su-03' ||
    'su03' ||
    'su_03' ||
    'suculenta tipo jade o ramificada' ||
    'suculenta ramificada' ||
    'arbol de jade' ||
    'árbol de jade' => 'su_03_branching_woody',
    'su_04_compact_filtered_light' ||
    'su-04' ||
    'su04' ||
    'su_04' ||
    'suculenta compacta de luz filtrada' ||
    'suculenta compacta' ||
    'haworthia' => 'su_04_compact_filtered_light',
    _ => null,
  };
}

String? _canonicalAloeProfileIdOrNull(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'sa_skip' ||
    'sa-skip' ||
    'saskip' ||
    'sabila' ||
    'sábila' ||
    'sábila general' ||
    'no sé / sábila general' ||
    'no se / sabila general' => 'sa_skip',
    'sa_01_broadleaf_rosette' ||
    'sa-01' ||
    'sa01' ||
    'sa_01' ||
    'sábila de hoja ancha' ||
    'aloe vera' ||
    'aloe barbadensis' => 'sa_01_broadleaf_rosette',
    'sa_02_small_clumping' ||
    'sa-02' ||
    'sa02' ||
    'sa_02' ||
    'sábila pequeña de maceta' ||
    'aloe enano' => 'sa_02_small_clumping',
    'sa_03_shrubby_branching' ||
    'sa-03' ||
    'sa03' ||
    'sa_03' ||
    'sábila arbustiva o de candelabro' ||
    'aloe arborescens' => 'sa_03_shrubby_branching',
    'sa_04_spotted_landscape' ||
    'sa-04' ||
    'sa04' ||
    'sa_04' ||
    'sábila moteada de jardín' ||
    'aloe maculata' => 'sa_04_spotted_landscape',
    _ => null,
  };
}

String? _canonicalAgaveProfileIdOrNull(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'mg_skip' ||
    'mg-skip' ||
    'mgskip' ||
    'maguey general' => 'mg_skip',
    'mg_01_compact_sculptural' ||
    'mg-01' ||
    'mg01' ||
    'mg_01' ||
    'maguey compacto' ||
    'agave victoriae-reginae' ||
    'agave parryi' => 'mg_01_compact_sculptural',
    'mg_02_large_spiny_landscape' ||
    'mg-02' ||
    'mg02' ||
    'mg_02' ||
    'maguey grande de paisaje' ||
    'agave americana' => 'mg_02_large_spiny_landscape',
    'mg_03_blue_narrow_field' ||
    'mg-03' ||
    'mg03' ||
    'mg_03' ||
    'maguey azul o de hoja angosta' ||
    'agave tequilana' => 'mg_03_blue_narrow_field',
    'mg_04_soft_spineless_warm' ||
    'mg-04' ||
    'mg04' ||
    'mg_04' ||
    'maguey de hoja suave' ||
    'agave attenuata' => 'mg_04_soft_spineless_warm',
    _ => null,
  };
}

String _resolvePersistedOrnamentalProfileId({
  required String cropId,
  required String profileId,
  String? varietyId,
  String? varietyAlias,
}) {
  final general = _ornamentalGeneralProfileId(cropId);
  final fromProfile = _canonicalOrnamentalProfileIdOrNull(cropId, profileId);
  final fromVariety = _canonicalOrnamentalProfileIdOrNull(cropId, varietyId);
  final fromAlias = _canonicalOrnamentalProfileIdOrNull(cropId, varietyAlias);

  // Repara contextos históricos donde el perfil general quedó en profileId
  // mientras la selección específica sobrevivía en varietyId/varietyAlias.
  for (final candidate in <String?>[fromVariety, fromProfile, fromAlias]) {
    if (candidate != null && candidate != general) return candidate;
  }
  return fromProfile ?? fromVariety ?? fromAlias ?? general;
}

/// Los ids de etapa son los mismos en todas las ornamentales de este modo
/// (instalación → raíz → crecimiento → mantenimiento ↔ reposo). Lo que cambia
/// entre plantas son las VENTANAS y los targets, no los nombres de etapa.
String _canonicalOrnamentalStageId(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'installation_establishment' ||
    'planned' ||
    'installation' ||
    'repot' ||
    'transplant' => 'installation_establishment',
    'root_establishment' || 'rooting' || 'establishing' => 'root_establishment',
    'active_growth' || 'growing' || 'active' => 'active_growth',
    'maintenance' || 'stable' || 'established' => 'maintenance',
    'rest' || 'dormant' || 'resting' => 'rest',
    _ => 'unknown',
  };
}

/// Etiqueta VISIBLE de la selección ornamental. Nunca se le muestra al usuario
/// un id interno ni la palabra "SKIP".
String _canonicalOrnamentalVisibleAlias(
  String cropId,
  String? raw,
  String profileId,
) {
  final value = raw?.trim();
  final normalized = value?.toLowerCase();
  const internalInputs = <String>{
    // Cactus
    'ca_skip',
    'ca-skip',
    'caskip',
    'cactus_generic',
    'ca_01_desert_container',
    'ca-01',
    'ca01',
    'ca_01',
    'cactus_mini',
    'ca_02_barrel_biznaga',
    'ca-02',
    'ca02',
    'ca_02',
    'ca_03_columnar_landscape',
    'ca-03',
    'ca03',
    'ca_03',
    'cactus_columnar',
    'ca_04_clustered_desert',
    'ca-04',
    'ca04',
    'ca_04',
    // Suculenta
    'su_skip',
    'su-skip',
    'suskip',
    'su_01_rosette_bright_light',
    'su-01',
    'su01',
    'su_01',
    'su_02_trailing_cascading',
    'su-02',
    'su02',
    'su_02',
    'su_03_branching_woody',
    'su-03',
    'su03',
    'su_03',
    'su_04_compact_filtered_light',
    'su-04',
    'su04',
    'su_04',
    // Sábila / Aloe
    'sa_skip',
    'sa-skip',
    'saskip',
    'sa_01_broadleaf_rosette',
    'sa-01',
    'sa01',
    'sa_01',
    'sa_02_small_clumping',
    'sa-02',
    'sa02',
    'sa_02',
    'sa_03_shrubby_branching',
    'sa-03',
    'sa03',
    'sa_03',
    'sa_04_spotted_landscape',
    'sa-04',
    'sa04',
    'sa_04',
    // Maguey / Agave
    'mg_skip',
    'mg-skip',
    'mgskip',
    'mg_01_compact_sculptural',
    'mg-01',
    'mg01',
    'mg_01',
    'mg_02_large_spiny_landscape',
    'mg-02',
    'mg02',
    'mg_02',
    'mg_03_blue_narrow_field',
    'mg-03',
    'mg03',
    'mg_03',
    'mg_04_soft_spineless_warm',
    'mg-04',
    'mg04',
    'mg_04',
  };
  if (value != null &&
      value.isNotEmpty &&
      !internalInputs.contains(normalized)) {
    return value;
  }
  if (cropId == 'crop_succulent') {
    return switch (profileId) {
      'su_01_rosette_bright_light' => 'Suculenta de roseta',
      'su_02_trailing_cascading' => 'Suculenta colgante',
      'su_03_branching_woody' => 'Suculenta tipo jade o ramificada',
      'su_04_compact_filtered_light' => 'Suculenta compacta de luz filtrada',
      _ => 'No sé / suculenta general',
    };
  }
  if (cropId == 'crop_aloe') {
    return switch (profileId) {
      'sa_01_broadleaf_rosette' => 'Sábila de hoja ancha',
      'sa_02_small_clumping' => 'Sábila pequeña de maceta',
      'sa_03_shrubby_branching' => 'Sábila arbustiva o de candelabro',
      'sa_04_spotted_landscape' => 'Sábila moteada de jardín',
      _ => 'No sé / sábila general',
    };
  }
  if (cropId == 'crop_agave') {
    return switch (profileId) {
      'mg_01_compact_sculptural' => 'Maguey compacto',
      'mg_02_large_spiny_landscape' => 'Maguey grande de paisaje',
      'mg_03_blue_narrow_field' => 'Maguey azul o de hoja angosta',
      'mg_04_soft_spineless_warm' => 'Maguey de hoja suave',
      _ => 'No sé / maguey general',
    };
  }
  return switch (profileId) {
    'ca_01_desert_container' => 'Cactus de maceta',
    'ca_02_barrel_biznaga' => 'Biznaga o cactus barril',
    'ca_03_columnar_landscape' => 'Cactus columna u órgano',
    'ca_04_clustered_desert' => 'Cactus agrupado o de varios tallos',
    _ => 'No sé / cactus general',
  };
}

// ── Rosal (floración recurrente) ─────────────────────────────────────────────
//
// El rosal es ornamental por categoría, pero de modo `recurring_bloom`. Guarda en
// los mismos campos `ornamental*`, pero con su propia canonicalización: sus
// estados (brote/botón/floración/post-floración/reposo) NO deben pasar por
// `_canonicalOrnamentalStageId`, que los borraría a `unknown`. Solo se aceptan
// alias del CULTIVO rosal: nunca migra a cactus/suculenta por compartir categoría.

const Set<String> _roseCropAliases = <String>{
  'crop_rose',
  'rose',
  'roses',
  'rosa',
  'rosas',
  'rosal',
  'rosales',
  'orn_rose',
  'ornamental_rose',
  'rosa_hybrida',
};

/// Devuelve el cropId canónico del rosal, o `null` si no lo es.
String? _roseCropIdOrNull(String normalizedCropId) {
  if (_roseCropAliases.contains(normalizedCropId)) return 'crop_rose';
  return null;
}

String? _canonicalRoseProfileIdOrNull(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'ro_skip' ||
    'ro-skip' ||
    'roskip' ||
    'rosal' ||
    'rosal general' ||
    'rosa' ||
    'no sé / rosal general' ||
    'no se / rosal general' ||
    'rose_generic' => 'ro_skip',
    'ro_01_miniature_container' ||
    'ro-01' ||
    'ro01' ||
    'ro_01' ||
    'rosal mini o de maceta' ||
    'rosal mini' ||
    'rosal de maceta' ||
    'rose_mini' => 'ro_01_miniature_container',
    'ro_02_large_flowered_bush' ||
    'ro-02' ||
    'ro02' ||
    'ro_02' ||
    'rosal de flor grande' ||
    'hybrid tea' => 'ro_02_large_flowered_bush',
    'ro_03_clustered_landscape' ||
    'ro-03' ||
    'ro03' ||
    'ro_03' ||
    'rosal de flores en racimo o de jardín' ||
    'rosal de racimo' ||
    'rosal de jardin' ||
    'rosal de jardín' ||
    'floribunda' ||
    'rose_jardin' => 'ro_03_clustered_landscape',
    'ro_04_repeat_climber' ||
    'ro-04' ||
    'ro04' ||
    'ro_04' ||
    'rosal trepador' ||
    'climbing rose' => 'ro_04_repeat_climber',
    _ => null,
  };
}

String _resolvePersistedRoseProfileId({
  required String profileId,
  String? varietyId,
  String? varietyAlias,
}) {
  const general = 'ro_skip';
  final fromProfile = _canonicalRoseProfileIdOrNull(profileId);
  final fromVariety = _canonicalRoseProfileIdOrNull(varietyId);
  final fromAlias = _canonicalRoseProfileIdOrNull(varietyAlias);
  for (final candidate in <String?>[fromVariety, fromProfile, fromAlias]) {
    if (candidate != null && candidate != general) return candidate;
  }
  return fromProfile ?? fromVariety ?? fromAlias ?? general;
}

/// Canonicaliza el id de etapa del rosal PRESERVANDO los estados de floración
/// recurrente. NO usa la canonicalización de establecimiento (que los borraría).
String _canonicalRoseStageId(String? value) {
  return switch (value?.trim().toLowerCase()) {
    'installation_establishment' ||
    'planned' ||
    'installation' ||
    'recien_plantado' ||
    'repot' ||
    'transplant' => 'installation_establishment',
    'root_establishment' ||
    'rooting' ||
    'establishing' ||
    'root' => 'root_establishment',
    'vegetative_flush' ||
    'sprouting' ||
    'flush' ||
    'brotando' ||
    'vegetative' ||
    'vegetative_growth' => 'vegetative_flush',
    'bud_formation' ||
    'bud' ||
    'buds' ||
    'budding' ||
    'boton' ||
    'botones' => 'bud_formation',
    'flowering' ||
    'bloom' ||
    'blooming' ||
    'floracion' ||
    'floración' => 'flowering',
    'post_bloom_recovery' ||
    'post_bloom' ||
    'postbloom' ||
    'recovery' ||
    'deadheading' => 'post_bloom_recovery',
    'rest' || 'dormant' || 'dormancy' || 'resting' || 'reposo' => 'rest',
    _ => 'unknown',
  };
}

/// Etiqueta VISIBLE de la selección del rosal. Nunca se muestra un id interno.
String _canonicalRoseVisibleAlias(String? raw, String profileId) {
  final value = raw?.trim();
  final normalized = value?.toLowerCase();
  const internalInputs = <String>{
    'ro_skip',
    'ro-skip',
    'roskip',
    'rose_generic',
    'ro_01_miniature_container',
    'ro-01',
    'ro01',
    'ro_01',
    'rose_mini',
    'ro_02_large_flowered_bush',
    'ro-02',
    'ro02',
    'ro_02',
    'ro_03_clustered_landscape',
    'ro-03',
    'ro03',
    'ro_03',
    'rose_jardin',
    'ro_04_repeat_climber',
    'ro-04',
    'ro04',
    'ro_04',
  };
  if (value != null &&
      value.isNotEmpty &&
      !internalInputs.contains(normalized)) {
    return value;
  }
  return switch (profileId) {
    'ro_01_miniature_container' => 'Rosal mini o de maceta',
    'ro_02_large_flowered_bush' => 'Rosal de flor grande',
    'ro_03_clustered_landscape' => 'Rosal de flores en racimo o de jardín',
    'ro_04_repeat_climber' => 'Rosal trepador',
    _ => 'No sé / rosal general',
  };
}
