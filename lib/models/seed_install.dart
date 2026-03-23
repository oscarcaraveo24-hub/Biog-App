// lib/models/seed_install.dart

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Estado legacy de instalación del cultivo en un BioG.
///
/// Ojo:
/// Este modelo ya NO debería ser la fuente principal de verdad.
/// Se conserva como adaptador temporal mientras la app migra a
/// [DeviceCropContext].
enum SowingStatus {
  planned, // se va a sembrar (pre-siembra)
  planted, // ya está sembrado
  skip, // perfil genérico / usuario omitió wizard / descanso
}

class SeedInstall {
  /// Id del dispositivo BioG
  final String deviceId;

  /// Clave canónica del cultivo activo (ej: maize, wheat, barley, bean)
  final String cropKey;

  /// Alias visible legacy de la variedad (ej: DK-2069, generic)
  final String varietyAlias;

  /// Id del perfil agronómico canónico (ej: maize_generic)
  final String? profileId;

  /// Fecha de siembra real
  final DateTime? sowingDate;

  /// Fecha planeada de siembra
  final DateTime? plannedSowingDate;

  /// Estado actual del cultivo
  final SowingStatus status;

  const SeedInstall({
    required this.deviceId,
    required this.cropKey,
    required this.varietyAlias,
    this.profileId,
    this.sowingDate,
    this.plannedSowingDate,
    required this.status,
  }) : assert(deviceId != ''),
       assert(cropKey != ''),
       assert(varietyAlias != '');

  /// Constructor helper para cultivo ya sembrado
  factory SeedInstall.planted({
    required String deviceId,
    required String cropKey,
    required String varietyAlias,
    required DateTime sowingDate,
    String? profileId,
  }) {
    return SeedInstall(
      deviceId: deviceId,
      cropKey: _canonicalCropKey(cropKey),
      varietyAlias: varietyAlias.trim(),
      profileId: _normalizeNullable(profileId),
      sowingDate: sowingDate,
      plannedSowingDate: null,
      status: SowingStatus.planted,
    );
  }

  /// Constructor helper para cultivo planeado (pre-siembra)
  factory SeedInstall.planned({
    required String deviceId,
    required String cropKey,
    required String varietyAlias,
    required DateTime plannedDate,
    String? profileId,
  }) {
    return SeedInstall(
      deviceId: deviceId,
      cropKey: _canonicalCropKey(cropKey),
      varietyAlias: varietyAlias.trim(),
      profileId: _normalizeNullable(profileId),
      sowingDate: null,
      plannedSowingDate: plannedDate,
      status: SowingStatus.planned,
    );
  }

  /// Constructor helper para modo genérico / wizard omitido.
  ///
  /// Aquí `cropKey` ya es obligatorio para no esconder defaults silenciosos.
  factory SeedInstall.skip({
    required String deviceId,
    required String cropKey,
    String varietyAlias = 'generic',
    String? profileId,
  }) {
    return SeedInstall(
      deviceId: deviceId,
      cropKey: _canonicalCropKey(cropKey),
      varietyAlias: varietyAlias.trim(),
      profileId: _normalizeNullable(profileId),
      sowingDate: null,
      plannedSowingDate: null,
      status: SowingStatus.skip,
    );
  }

  bool get isPlanted => status == SowingStatus.planted;
  bool get isPlanned => status == SowingStatus.planned;
  bool get isSkip => status == SowingStatus.skip;

  SeedInstall copyWith({
    String? deviceId,
    String? cropKey,
    String? varietyAlias,
    Object? profileId = _seedInstallSentinel,
    Object? sowingDate = _seedInstallSentinel,
    Object? plannedSowingDate = _seedInstallSentinel,
    SowingStatus? status,
  }) {
    return SeedInstall(
      deviceId: deviceId ?? this.deviceId,
      cropKey: _canonicalCropKey(cropKey ?? this.cropKey),
      varietyAlias: (varietyAlias ?? this.varietyAlias).trim(),
      profileId: identical(profileId, _seedInstallSentinel)
          ? this.profileId
          : _normalizeNullable(profileId as String?),
      sowingDate: identical(sowingDate, _seedInstallSentinel)
          ? this.sowingDate
          : sowingDate as DateTime?,
      plannedSowingDate: identical(plannedSowingDate, _seedInstallSentinel)
          ? this.plannedSowingDate
          : plannedSowingDate as DateTime?,
      status: status ?? this.status,
    );
  }

  /// Adaptador legacy -> modelo formal nuevo.
  DeviceCropContext toDeviceCropContext({
    String cropCategoryId = CropCatalog.grainCategoryId,
    String? timezone,
    String? regionCode,
    String? cycleLabel,
    String? calendarTypeId,
    String? sowingModeId,
    String catalogVersion = CropCatalog.version,
    CropConfigSource source = CropConfigSource.demo,
    DateTime? configuredAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    final normalizedCropKey = _canonicalCropKey(cropKey);
    final catalogCrop = CropCatalog.cropById(normalizedCropKey);

    final lifecycleStatus = switch (status) {
      SowingStatus.planned => CropLifecycleStatus.planned,
      SowingStatus.planted => CropLifecycleStatus.planted,
      SowingStatus.skip => CropLifecycleStatus.fallow,
    };

    final dateConfidence = switch (status) {
      SowingStatus.planted =>
        sowingDate != null ? DateConfidence.exact : DateConfidence.unknown,
      SowingStatus.planned =>
        plannedSowingDate != null
            ? DateConfidence.exact
            : DateConfidence.unknown,
      SowingStatus.skip => DateConfidence.unknown,
    };

    final normalizedExplicitProfileId = _normalizeNullable(profileId);
    final rawVarietyAlias = _normalizeNullable(varietyAlias);

    final resolvedVarietyId = CropCatalog.resolveVarietyId(
      cropId: normalizedCropKey,
      rawValue: rawVarietyAlias,
    );

    final resolvedProfileId = CropCatalog.resolveProfileId(
      cropId: normalizedCropKey,
      varietyId: resolvedVarietyId,
      explicitProfileId: normalizedExplicitProfileId,
    );

    final resolvedBrandId = _resolveBrandId(
      cropId: normalizedCropKey,
      varietyId: resolvedVarietyId,
    );

    final resolvedVarietyAlias = _resolvedVarietyAliasForContext(
      cropId: normalizedCropKey,
      rawVarietyAlias: rawVarietyAlias,
      resolvedVarietyId: resolvedVarietyId,
      resolvedProfileId: resolvedProfileId,
      status: status,
    );

    final resolvedCropCategoryId = cropCategoryId.trim().isNotEmpty
        ? cropCategoryId.trim()
        : (catalogCrop?.categoryId ?? CropCatalog.grainCategoryId);

    final resolvedCalendarTypeId =
        _normalizeNullable(calendarTypeId) ??
        CropCatalog.defaultCalendarIdForCrop(normalizedCropKey);

    final resolvedSowingModeId =
        _normalizeNullable(sowingModeId) ?? _defaultSowingModeId(status);

    return DeviceCropContext(
      deviceId: deviceId,
      cropCategoryId: resolvedCropCategoryId,
      cropId: normalizedCropKey,
      profileId: resolvedProfileId,
      brandId: resolvedBrandId,
      varietyId: resolvedVarietyId,
      varietyAlias: resolvedVarietyAlias,
      calendarTypeId: resolvedCalendarTypeId,
      lifecycleStatus: lifecycleStatus,
      sowingDate: sowingDate,
      plannedSowingDate: plannedSowingDate,
      sowingDateConfidence: dateConfidence,
      sowingModeId: resolvedSowingModeId,
      timezone: _normalizeNullable(timezone),
      regionCode: _normalizeNullable(regionCode),
      cycleLabel: _normalizeNullable(cycleLabel),
      catalogVersion: catalogVersion.trim().isEmpty
          ? CropCatalog.version
          : catalogVersion.trim(),
      source: source,
      configuredAt: configuredAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Adaptador modelo formal nuevo -> legacy temporal.
  factory SeedInstall.fromDeviceCropContext(DeviceCropContext context) {
    final status = switch (context.lifecycleStatus) {
      CropLifecycleStatus.planned => SowingStatus.planned,
      CropLifecycleStatus.planted => SowingStatus.planted,
      CropLifecycleStatus.fallow => SowingStatus.skip,
    };

    return SeedInstall(
      deviceId: context.deviceId,
      cropKey: _canonicalCropKey(context.cropId),
      varietyAlias: _legacyVarietyAliasFromContext(context),
      profileId: _normalizeNullable(context.profileId),
      sowingDate: context.sowingDate,
      plannedSowingDate: context.plannedSowingDate,
      status: status,
    );
  }

  static String _legacyVarietyAliasFromContext(DeviceCropContext context) {
    final cropId = _canonicalCropKey(context.cropId);

    if (context.lifecycleStatus == CropLifecycleStatus.fallow) {
      return 'generic';
    }

    final explicitAlias = _normalizeNullable(context.varietyAlias);
    if (explicitAlias != null) {
      if (_isGenericAlias(explicitAlias)) {
        return 'generic';
      }

      final explicitVarietyId = CropCatalog.resolveVarietyId(
        cropId: cropId,
        rawValue: explicitAlias,
      );

      if (explicitVarietyId != null) {
        final explicitVariety = CropCatalog.varietyById(
          cropId,
          explicitVarietyId,
        );
        if (explicitVariety != null) {
          return explicitVariety.isGeneric ? 'generic' : explicitVariety.label;
        }
      }

      if (_isGenericProfileId(context.profileId)) {
        return 'generic';
      }

      return explicitAlias;
    }

    final variety = CropCatalog.varietyById(cropId, context.varietyId);
    if (variety != null) {
      return variety.isGeneric ? 'generic' : variety.label;
    }

    final profile = CropCatalog.profileById(cropId, context.profileId);
    if (profile != null && _isGenericProfileId(profile.id)) {
      return 'generic';
    }

    return 'generic';
  }

  static String? _resolvedVarietyAliasForContext({
    required String cropId,
    required String? rawVarietyAlias,
    required String? resolvedVarietyId,
    required String resolvedProfileId,
    required SowingStatus status,
  }) {
    if (status == SowingStatus.skip) {
      return 'generic';
    }

    if (resolvedVarietyId != null) {
      final variety = CropCatalog.varietyById(cropId, resolvedVarietyId);
      if (variety != null) {
        return variety.isGeneric ? 'generic' : variety.label;
      }
    }

    if (_isGenericAlias(rawVarietyAlias) ||
        _isGenericProfileId(resolvedProfileId)) {
      return 'generic';
    }

    return rawVarietyAlias;
  }

  static String? _resolveBrandId({
    required String cropId,
    required String? varietyId,
  }) {
    if (varietyId == null || varietyId.isEmpty) return null;
    return CropCatalog.varietyById(cropId, varietyId)?.brandId;
  }

  static String _defaultSowingModeId(SowingStatus status) {
    return switch (status) {
      SowingStatus.planned => 'planned',
      SowingStatus.planted => 'planted',
      SowingStatus.skip => 'skip',
    };
  }

  static bool _isGenericAlias(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    return normalized.isEmpty ||
        normalized == 'generic' ||
        normalized == 'genérico' ||
        normalized == 'generico' ||
        normalized == 'perfil genérico' ||
        normalized == 'generic_maize' ||
        normalized == 'generic_corn' ||
        normalized == 'generic_bean' ||
        normalized == 'generic_wheat' ||
        normalized == 'generic_barley' ||
        normalized == 'generic_oat';
  }

  static bool _isGenericProfileId(String? profileId) {
    final normalized = profileId?.trim().toLowerCase() ?? '';
    return normalized.isNotEmpty &&
        (normalized.endsWith('_generic') ||
            normalized == 'fj_gen' ||
            normalized == 'tr_gen' ||
            normalized == 'cb_gen' ||
            normalized == 'av_gen');
  }

  static String _canonicalCropKey(String value) {
    final result = CropCatalog.canonicalCropKey(value);
    if (result.isEmpty) {
      throw ArgumentError.value(value, 'cropKey', 'No puede estar vacío.');
    }
    return result;
  }

  static String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}

const Object _seedInstallSentinel = Object();
