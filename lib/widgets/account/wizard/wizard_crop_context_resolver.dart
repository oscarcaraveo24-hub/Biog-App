import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/maize/maize_catalog.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/widgets/seeds/maize_profiles.dart';

class WizardCropContextResolver {
  const WizardCropContextResolver();

  DeviceCropContext resolve({
    required String deviceId,
    required String cropCategoryId,
    required String cropId,
    required CropLifecycleStatus lifecycleStatus,
    required DateConfidence dateConfidence,
    required DateTime now,
    DeviceCropContext? previous,
    String? brandId,
    String? varietyId,
    String? varietyAlias,
    String? calendarTypeId,
    DateTime? selectedDate,
    String? timezone,
    String? regionCode,
    String? cycleLabel,
    String? sowingModeId,
  }) {
    final normalizedCropCategoryId = cropCategoryId.trim().isEmpty
        ? CropCatalog.grainCategoryId
        : cropCategoryId.trim();

    final normalizedCropId = cropId.trim().isEmpty
        ? CropCatalog.maizeCropId
        : cropId.trim().toLowerCase();

    final rawVarietySelection = _normalizeVarietyAlias(varietyAlias);

    // Primary: use canonical varietyId if provided directly (new catalog path).
    // Fallback: resolve from alias (legacy / onboarding path).
    final resolvedVarietyId =
        varietyId ??
        _resolveVarietyId(
          cropId: normalizedCropId,
          varietyAlias: rawVarietySelection,
        );

    // Resolve brandId: explicit > from variety entry > previous > null.
    final resolvedBrandId = brandId ??
        _resolveBrandIdFromVariety(normalizedCropId, resolvedVarietyId) ??
        previous?.brandId;

    final resolvedVarietyAlias = _resolveVisibleVarietyAlias(
      cropId: normalizedCropId,
      rawValue: rawVarietySelection,
      resolvedVarietyId: resolvedVarietyId,
    );

    // New chain: varietyId → defaultProfileId first, then alias map fallback.
    final resolvedExplicitProfileId = _resolveExplicitProfileId(
      cropId: normalizedCropId,
      varietyId: resolvedVarietyId,
      varietyAlias: rawVarietySelection,
    );

    final resolvedProfileId = CropCatalog.resolveProfileId(
      cropId: normalizedCropId,
      varietyId: resolvedVarietyId,
      explicitProfileId: resolvedExplicitProfileId,
    );

    final resolvedCalendarTypeId =
        calendarTypeId ??
        previous?.calendarTypeId ??
        _defaultCalendarTypeIdForCrop(normalizedCropId);

    final resolvedTimezone =
        (timezone ?? previous?.timezone ?? 'America/Mexico_City').trim();

    final resolvedRegionCode = (regionCode ?? previous?.regionCode ?? 'MX')
        .trim();

    return DeviceCropContext(
      deviceId: deviceId,
      cropCategoryId: normalizedCropCategoryId,
      cropId: normalizedCropId,
      profileId: resolvedProfileId,
      brandId: resolvedBrandId,
      varietyId: resolvedVarietyId,
      varietyAlias: resolvedVarietyAlias,
      calendarTypeId: resolvedCalendarTypeId,
      lifecycleStatus: lifecycleStatus,
      sowingDate: lifecycleStatus == CropLifecycleStatus.planted
          ? selectedDate
          : null,
      plannedSowingDate: lifecycleStatus == CropLifecycleStatus.planned
          ? selectedDate
          : null,
      sowingDateConfidence: dateConfidence,
      sowingModeId: sowingModeId ?? _sowingModeIdFromLifecycle(lifecycleStatus),
      timezone: resolvedTimezone,
      regionCode: resolvedRegionCode,
      cycleLabel: cycleLabel ?? previous?.cycleLabel,
      catalogVersion: CropCatalog.version,
      source: CropConfigSource.wizard,
      configuredAt: previous?.configuredAt ?? now,
      updatedAt: now,
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  String? _resolveVarietyId({
    required String cropId,
    required String? varietyAlias,
  }) {
    if (varietyAlias == null || varietyAlias.isEmpty) return null;
    return CropCatalog.varietyByAny(cropId, varietyAlias)?.id;
  }

  String? _resolveVisibleVarietyAlias({
    required String cropId,
    required String? rawValue,
    required String? resolvedVarietyId,
  }) {
    if (resolvedVarietyId != null) {
      final variety = CropCatalog.varietyById(cropId, resolvedVarietyId);
      if (variety != null) return variety.label;
    }

    final fromAny = CropCatalog.varietyByAny(cropId, rawValue);
    if (fromAny != null) {
      return fromAny.label;
    }

    return rawValue;
  }

  /// Resolves the explicit profile ID for the given crop context.
  ///
  /// Resolution order (maize only):
  ///   1. `varietyEntry.defaultProfileId` — canonical, most accurate.
  ///   2. Alias-map lookup via [resolveCanonicalMaizeProfileId] — covers
  ///      legacy short aliases like "DK-2069", "MZF-03", "ANTÍLOPE FORRAJE".
  ///
  /// Returns null for non-maize crops (CropCatalog resolves those generically).
  String? _resolveExplicitProfileId({
    required String cropId,
    required String? varietyId,
    required String? varietyAlias,
  }) {
    if (cropId != CropCatalog.maizeCropId) return null;

    // 1. Primary: variety entry's defaultProfileId (new catalog-based path).
    if (varietyId != null && varietyId.isNotEmpty) {
      final profileId = maizeVarietyById(varietyId)?.defaultProfileId;
      if (profileId != null && profileId.isNotEmpty) return profileId;
    }

    // 2. Fallback: alias-map resolution (legacy DK-2069, short codes, etc.).
    if (varietyAlias != null && varietyAlias.isNotEmpty) {
      return resolveCanonicalMaizeProfileId(varietyAlias);
    }

    return null;
  }

  String? _defaultCalendarTypeIdForCrop(String cropId) {
    if (cropId == CropCatalog.maizeCropId) {
      return CropCatalog.maizeDefaultCalendarId;
    }
    return null;
  }

  String? _resolveBrandIdFromVariety(String cropId, String? varietyId) {
    if (varietyId == null || varietyId.isEmpty) return null;
    final variety = CropCatalog.varietyById(cropId, varietyId);
    return variety?.brandId;
  }

  String _sowingModeIdFromLifecycle(CropLifecycleStatus status) {
    return switch (status) {
      CropLifecycleStatus.planted => 'planted',
      CropLifecycleStatus.planned => 'planned',
      CropLifecycleStatus.fallow => 'skip',
    };
  }

  String? _normalizeVarietyAlias(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }
}
