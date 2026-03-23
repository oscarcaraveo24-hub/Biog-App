import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/maize/maize_catalog.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/widgets/seeds/barley_profiles.dart';
import 'package:bio_g/widgets/seeds/bean_profiles.dart';
import 'package:bio_g/widgets/seeds/maize_profiles.dart';
import 'package:bio_g/widgets/seeds/oat_profiles.dart';
import 'package:bio_g/widgets/seeds/wheat_profiles.dart';

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
        : CropCatalog.canonicalCropKey(cropId);

    final rawVarietySelection = _normalizeVarietyAlias(varietyAlias);

    final resolvedVarietyId = _resolveCanonicalVarietyId(
      cropId: normalizedCropId,
      varietyId: varietyId,
      varietyAlias: rawVarietySelection,
    );

    final resolvedBrandId = _resolveCanonicalBrandId(
      cropId: normalizedCropId,
      explicitBrandId: brandId,
      varietyId: resolvedVarietyId,
      previous: previous,
    );

    final resolvedVarietyAlias = _resolveVisibleVarietyAlias(
      cropId: normalizedCropId,
      rawValue: rawVarietySelection,
      resolvedVarietyId: resolvedVarietyId,
    );

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
        _normalizeNullable(calendarTypeId) ??
        previous?.calendarTypeId ??
        CropCatalog.defaultCalendarIdForCrop(normalizedCropId);

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

  String? _resolveCanonicalVarietyId({
    required String cropId,
    required String? varietyId,
    required String? varietyAlias,
  }) {
    final normalizedVarietyId = _normalizeNullable(varietyId);
    if (normalizedVarietyId != null) {
      final direct = CropCatalog.varietyById(cropId, normalizedVarietyId);
      if (direct != null) return direct.id;
    }

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

  String? _resolveExplicitProfileId({
    required String cropId,
    required String? varietyId,
    required String? varietyAlias,
  }) {
    // ── Maize ────────────────────────────────────────────────────────────────
    if (cropId == CropCatalog.maizeCropId) {
      if (varietyId != null && varietyId.isNotEmpty) {
        final profileId = maizeVarietyById(varietyId)?.defaultProfileId;
        if (profileId != null && profileId.isNotEmpty) return profileId;
      }
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalMaizeProfileId(varietyAlias);
      }
      return null;
    }

    // ── Bean ─────────────────────────────────────────────────────────────────
    if (cropId == CropCatalog.beanCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalBeanProfileId(varietyAlias);
      }
      return null;
    }

    // ── Oat ──────────────────────────────────────────────────────────────────
    if (cropId == CropCatalog.oatCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalOatProfileId(varietyAlias);
      }
      return null;
    }

    // ── Barley ───────────────────────────────────────────────────────────────
    if (cropId == CropCatalog.barleyCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalBarleyProfileId(varietyAlias);
      }
      return null;
    }

    // ── Wheat ────────────────────────────────────────────────────────────────
    if (cropId == CropCatalog.wheatCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalWheatProfileId(varietyAlias);
      }
      return null;
    }

    return null;
  }

  String? _resolveCanonicalBrandId({
    required String cropId,
    required String? explicitBrandId,
    required String? varietyId,
    required DeviceCropContext? previous,
  }) {
    final normalizedBrandId = _normalizeNullable(explicitBrandId);
    if (normalizedBrandId != null) {
      final brands = CropCatalog.brandsForCrop(cropId);
      final isValidBrand = brands.any((brand) => brand.id == normalizedBrandId);
      if (isValidBrand) {
        return normalizedBrandId;
      }
    }

    if (varietyId != null && varietyId.isNotEmpty) {
      final variety = CropCatalog.varietyById(cropId, varietyId);
      if (variety?.brandId != null && variety!.brandId!.trim().isNotEmpty) {
        return variety.brandId;
      }
    }

    if (previous != null && previous.cropId == cropId) {
      return previous.brandId;
    }

    return null;
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

  String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
