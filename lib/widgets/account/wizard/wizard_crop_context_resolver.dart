import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/maize/maize_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/widgets/seeds/barley_profiles.dart';
import 'package:bio_g/widgets/seeds/bean_profiles.dart';
import 'package:bio_g/widgets/seeds/chili_profiles.dart';
import 'package:bio_g/widgets/seeds/cucumber_profiles.dart';
import 'package:bio_g/widgets/seeds/eggplant_profiles.dart';
import 'package:bio_g/widgets/seeds/garlic_profiles.dart';
import 'package:bio_g/widgets/seeds/lettuce_profiles.dart';
import 'package:bio_g/widgets/seeds/maize_profiles.dart';
import 'package:bio_g/widgets/seeds/oat_profiles.dart';
import 'package:bio_g/widgets/seeds/onion_profiles.dart';
import 'package:bio_g/widgets/seeds/spinach_profiles.dart';
import 'package:bio_g/widgets/seeds/squash_profiles.dart';
import 'package:bio_g/widgets/seeds/tomato_profiles.dart';
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
    String? cultivationScaleId,
    String? perennialStateId,
    String? phenologyStageId,
    DateTime? perennialAnchorDate,
    String? perennialAnchorTypeId,
    DateTime? treePlantingDate,
  }) {
    final normalizedCropId = _canonicalCropKey(
      cropId.trim().isEmpty ? CropCatalog.maizeCropId : cropId,
    );

    final bool sameCrop = previous != null &&
        _canonicalCropKey(previous.cropId) == normalizedCropId;

    final normalizedCropCategoryId = cropCategoryId.trim().isEmpty
        ? (CropCatalog.cropById(normalizedCropId)?.categoryId ??
            CropCatalog.grainCategoryId)
        : cropCategoryId.trim();

    final isTreeContext = isTreeCrop(
      cropId: normalizedCropId,
      cropCategoryId: normalizedCropCategoryId,
    );

    final bool isFallow = lifecycleStatus == CropLifecycleStatus.fallow;
    final String? rawVarietySelection =
        isFallow ? null : _normalizeVarietyAlias(varietyAlias);

    final String? resolvedVarietyId = isFallow
        ? null
        : _resolveCanonicalVarietyId(
            cropId: normalizedCropId,
            varietyId: varietyId,
            varietyAlias: rawVarietySelection,
          );

    final String? resolvedExplicitProfileId = isFallow
        ? null
        : _resolveExplicitProfileId(
            cropId: normalizedCropId,
            varietyId: normalizedCropId == CropCatalog.appleTreeCropId
                ? _normalizeNullable(varietyId)
                : resolvedVarietyId,
            varietyAlias: rawVarietySelection,
          );

    final String resolvedProfileId = CropCatalog.resolveProfileId(
      cropId: normalizedCropId,
      varietyId: resolvedVarietyId,
      explicitProfileId: resolvedExplicitProfileId,
    );

    final String? resolvedBrandId = isFallow
        ? null
        : _resolveCanonicalBrandId(
            cropId: normalizedCropId,
            explicitBrandId: brandId,
            varietyId: resolvedVarietyId,
            previous: sameCrop ? previous : null,
          );

    final String? resolvedVarietyAlias = _resolveVisibleVarietyAlias(
      cropId: normalizedCropId,
      rawValue: rawVarietySelection,
      resolvedVarietyId: resolvedVarietyId,
      resolvedProfileId: resolvedProfileId,
      lifecycleStatus: lifecycleStatus,
    );

    final String? resolvedCalendarTypeId = CropCatalog.resolveCalendarId(
      cropId: normalizedCropId,
      requested: calendarTypeId,
      previousCalendarId: sameCrop ? previous?.calendarTypeId : null,
    );

    final String resolvedTimezone =
        (timezone ?? previous?.timezone ?? 'America/Mexico_City').trim();

    final String resolvedRegionCode =
        (regionCode ?? previous?.regionCode ?? 'MX').trim();

    final resolvedScaleId = cultivationScaleId?.trim().isNotEmpty == true
        ? cultivationScaleId!.trim()
        : previous?.cultivationScaleId;

    // Memoria de plantación (edad) heredada al reconfigurar el mismo árbol.
    final DateTime? carriedTreeSowingDate =
        sameCrop ? previous.sowingDate : null;

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
      // Para árboles, sowingDate es el eje MEMORIA/EDAD (fecha de plantación),
      // distinto de perennialAnchorDate (evento de etapa). Si no llega una
      // fecha de plantación nueva, se conserva la del contexto previo para que
      // la edad sobreviva a transiciones de etapa/producción (#4, #14).
      sowingDate: lifecycleStatus == CropLifecycleStatus.planted
          ? (isTreeContext
              ? (treePlantingDate ?? carriedTreeSowingDate)
              : selectedDate)
          : null,
      plannedSowingDate:
          !isTreeContext && lifecycleStatus == CropLifecycleStatus.planned
          ? selectedDate
          : null,
      sowingDateConfidence: dateConfidence,
      cultivationScaleId: resolvedScaleId,
      sowingModeId: sowingModeId ?? _sowingModeIdFromLifecycle(lifecycleStatus),
      timezone: resolvedTimezone,
      regionCode: resolvedRegionCode,
      cycleLabel: cycleLabel ?? previous?.cycleLabel,
      perennialStateId: isTreeContext ? perennialStateId : null,
      phenologyStageId: isTreeContext ? phenologyStageId : null,
      perennialAnchorDate: isTreeContext ? perennialAnchorDate : null,
      perennialAnchorTypeId: isTreeContext ? perennialAnchorTypeId : null,
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
    required String resolvedProfileId,
    required CropLifecycleStatus lifecycleStatus,
  }) {
    if (lifecycleStatus == CropLifecycleStatus.fallow) {
      return 'generic';
    }

    if (cropId == CropCatalog.appleTreeCropId) {
      final profile =
          CropCatalog.profileByAny(cropId, rawValue) ??
          CropCatalog.profileByAny(cropId, resolvedProfileId);
      return profile?.label ?? rawValue;
    }

    if (resolvedVarietyId != null) {
      final variety = CropCatalog.varietyById(cropId, resolvedVarietyId);
      if (variety != null) return variety.isGeneric ? 'generic' : variety.label;
    }

    final fromAny = CropCatalog.varietyByAny(cropId, rawValue);
    if (fromAny != null) {
      return fromAny.isGeneric ? 'generic' : fromAny.label;
    }

    if (CropCatalog.isGenericAlias(rawValue) ||
        CropCatalog.isGenericProfileId(resolvedProfileId)) {
      return 'generic';
    }

    return rawValue;
  }

  String? _resolveExplicitProfileId({
    required String cropId,
    required String? varietyId,
    required String? varietyAlias,
  }) {
    if (cropId == CropCatalog.appleTreeCropId) {
      final profile =
          CropCatalog.profileByAny(cropId, varietyId) ??
          CropCatalog.profileByAny(cropId, varietyAlias);
      return profile?.id;
    }

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

    if (cropId == CropCatalog.beanCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalBeanProfileId(varietyAlias);
      }
      return null;
    }

    if (cropId == CropCatalog.oatCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalOatProfileId(varietyAlias);
      }
      return null;
    }

    if (cropId == CropCatalog.barleyCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalBarleyProfileId(varietyAlias);
      }
      return null;
    }

    if (cropId == CropCatalog.wheatCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalWheatProfileId(varietyAlias);
      }
      return null;
    }

    if (cropId == CropCatalog.tomatoCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalTomatoProfileId(varietyAlias);
      }
      return null;
    }

    if (cropId == CropCatalog.cucumberCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalCucumberProfileId(varietyAlias);
      }
      return null;
    }

    if (cropId == CropCatalog.chiliCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalChiliProfileId(varietyAlias);
      }
      return null;
    }

    if (cropId == CropCatalog.eggplantCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalEggplantProfileId(varietyAlias);
      }
      return null;
    }

    if (cropId == CropCatalog.squashCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalSquashProfileId(varietyAlias);
      }
      return null;
    }

    if (cropId == CropCatalog.lettuceCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalLettuceProfileId(varietyAlias);
      }
      return null;
    }

    if (cropId == CropCatalog.spinachCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalSpinachProfileId(varietyAlias);
      }
      return null;
    }

    if (cropId == CropCatalog.onionCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalOnionProfileId(varietyAlias);
      }
      return null;
    }

    if (cropId == CropCatalog.garlicCropId) {
      if (varietyAlias != null && varietyAlias.isNotEmpty) {
        return resolveCanonicalGarlicProfileId(varietyAlias);
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

    return previous?.brandId;
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
