import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/recurring_bloom/recurring_bloom_crops.dart';
// Tulipán (seasonal_bulb): capa compartida del modo bulboso estacional.
import 'package:bio_g/core/crops/seasonal_bulb/seasonal_bulb_crops.dart';
// Girasol (annual_ornamental): capa compartida del modo ornamental anual.
import 'package:bio_g/core/crops/annual_ornamental/annual_ornamental_crops.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/maize/maize_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/tree_profile_presentation.dart';
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
    String? ornamentalStageId,
    DateTime? ornamentalAnchorDate,
    String? ornamentalAnchorTypeId,
    double? ornamentalStageConfidence,
  }) {
    final normalizedCropId = _canonicalCropKey(
      cropId.trim().isEmpty ? CropCatalog.maizeCropId : cropId,
    );

    final bool sameCrop =
        previous != null &&
        _canonicalCropKey(previous.cropId) == normalizedCropId;

    final normalizedCropCategoryId = cropCategoryId.trim().isEmpty
        ? (CropCatalog.cropById(normalizedCropId)?.categoryId ??
              CropCatalog.grainCategoryId)
        : cropCategoryId.trim();

    final isTreeContext = isTreeCrop(
      cropId: normalizedCropId,
      cropCategoryId: normalizedCropCategoryId,
    );

    // Ornamental de establecimiento/mantenimiento (cactus, suculenta…). Usa
    // campos propios de etapa/ancla/confianza; no reutiliza fenología ni estado
    // de árboles.
    final bool isOrnamentalContext = isEstablishmentMaintenanceCrop(
      cropId: normalizedCropId,
      cropCategoryId: normalizedCropCategoryId,
    );

    // Ornamental de floración recurrente (rosal): guarda en los mismos campos
    // ornamentales, pero con su propio modo y su propia estimación (solo el
    // establecimiento se infiere por fecha; los estados recurrentes se confirman
    // visualmente).
    final bool isRecurringBloomContext = isRecurringBloomCrop(
      cropId: normalizedCropId,
      cropCategoryId: normalizedCropCategoryId,
    );

    // Ambos modos ornamentales comparten estructura de persistencia (categoría
    // ornamental, sin siembra ni fenología de árbol).
    final bool isOrnamentalLike =
        isOrnamentalContext || isRecurringBloomContext;

    // Un contexto ornamental histórico en fallow se migra a plantado; nunca
    // expone descanso del suelo ni borra su perfil al normalizarlo.
    final bool isFallow =
        lifecycleStatus == CropLifecycleStatus.fallow && !isOrnamentalLike;
    final String? rawVarietySelection = isFallow
        ? null
        : _normalizeVarietyAlias(varietyAlias);

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
            varietyId:
                isTreeCrop(cropId: normalizedCropId) ||
                    isEstablishmentMaintenanceCrop(cropId: normalizedCropId) ||
                    isRecurringBloomCrop(cropId: normalizedCropId) ||
                    // Tulipán (seasonal_bulb): su tu_* es un PERFIL, no variedad.
                    isSeasonalBulbCrop(cropId: normalizedCropId) ||
                    // Girasol (annual_ornamental): su gi_* es un PERFIL, no variedad.
                    isAnnualOrnamentalCrop(cropId: normalizedCropId)
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
      lifecycleStatus:
          isOrnamentalLike && lifecycleStatus == CropLifecycleStatus.fallow
          ? CropLifecycleStatus.planted
          : lifecycleStatus,
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

    final resolvedScaleId = isOrnamentalLike
        ? null
        : cultivationScaleId?.trim().isNotEmpty == true
        ? cultivationScaleId!.trim()
        : previous?.cultivationScaleId;

    // Memoria de plantación (edad) heredada al reconfigurar el mismo árbol.
    final DateTime? carriedTreeSowingDate = sameCrop
        ? previous.sowingDate
        : null;

    // Ancla ornamental: fecha de plantación/alta (planned o planted).
    final DateTime? ornamentalAnchor = isOrnamentalLike
        ? (ornamentalAnchorDate ??
              selectedDate ??
              (dateConfidence != DateConfidence.unknown && sameCrop
                  ? previous?.ornamentalAnchorDate
                  : null))
        : null;
    final bool preservePreviousOrnamentalStage =
        isOrnamentalLike &&
        sameCrop &&
        dateConfidence != DateConfidence.unknown &&
        ornamentalStageId == null &&
        previous?.ornamentalAnchorDate == ornamentalAnchor;

    // Estimación por fecha: la ornamental de establecimiento estima toda su
    // progresión; el rosal SOLO estima el establecimiento (los estados
    // recurrentes los confirma el usuario de forma visual).
    final OrnamentalStageEstimate? ornamentalEstimate = isOrnamentalContext
        ? estimateOrnamentalStageFromDate(
            cropId: normalizedCropId,
            plantingDate: ornamentalAnchor,
            now: now,
            profileId: resolvedProfileId,
          )
        : null;
    final RecurringBloomStageEstimate? recurringBloomEstimate =
        isRecurringBloomContext
        ? resolveRecurringBloomSetupStage(
            cropId: normalizedCropId,
            intentId: lifecycleStatus == CropLifecycleStatus.planned
                ? kRecurringBloomIntentPlannedPlant
                : kRecurringBloomIntentAlreadyPlanted,
            plantingDate: ornamentalAnchor,
            now: now,
            profileId: resolvedProfileId,
            previousStageId: preservePreviousOrnamentalStage
                ? previous?.ornamentalStageId
                : null,
          )
        : null;

    final String? ornamentalStateId = isOrnamentalContext
        ? normalizeOrnamentalStageId(
            normalizedCropId,
            ornamentalStageId ??
                (preservePreviousOrnamentalStage
                    ? previous?.ornamentalStageId
                    : null) ??
                ornamentalEstimate?.stageId,
          )
        : isRecurringBloomContext
        ? normalizeRecurringBloomStageId(
            normalizedCropId,
            ornamentalStageId ??
                (preservePreviousOrnamentalStage
                    ? previous?.ornamentalStageId
                    : null) ??
                recurringBloomEstimate?.stageId,
          )
        : null;
    final String? ornamentalAnchorType = isOrnamentalContext
        ? normalizeOrnamentalAnchorTypeId(
            normalizedCropId,
            ornamentalAnchorTypeId ??
                (preservePreviousOrnamentalStage
                    ? previous?.ornamentalAnchorTypeId
                    : null) ??
                ornamentalEstimate?.anchorTypeId,
          )
        : isRecurringBloomContext
        ? normalizeRecurringBloomAnchorTypeId(
            normalizedCropId,
            ornamentalAnchorTypeId ??
                (preservePreviousOrnamentalStage
                    ? previous?.ornamentalAnchorTypeId
                    : null) ??
                recurringBloomEstimate?.anchorTypeId,
          )
        : null;
    final double? ornamentalConfidence = isOrnamentalContext
        ? (ornamentalStageConfidence ??
              (preservePreviousOrnamentalStage
                  ? previous?.ornamentalStageConfidence
                  : null) ??
              ornamentalEstimate?.confidence)
        : isRecurringBloomContext
        ? (ornamentalStageConfidence ??
              (preservePreviousOrnamentalStage
                  ? previous?.ornamentalStageConfidence
                  : null) ??
              recurringBloomEstimate?.confidence)
        : null;
    final CropLifecycleStatus effectiveLifecycleStatus =
        isOrnamentalContext && lifecycleStatus == CropLifecycleStatus.fallow
        ? CropLifecycleStatus.planted
        : lifecycleStatus;

    return DeviceCropContext(
      deviceId: deviceId,
      cropCategoryId: normalizedCropCategoryId,
      cropId: normalizedCropId,
      profileId: resolvedProfileId,
      brandId: resolvedBrandId,
      varietyId: resolvedVarietyId,
      varietyAlias: resolvedVarietyAlias,
      calendarTypeId: resolvedCalendarTypeId,
      lifecycleStatus: effectiveLifecycleStatus,
      // Para árboles, sowingDate es el eje MEMORIA/EDAD (fecha de plantación),
      // distinto de perennialAnchorDate (evento de etapa). Si no llega una
      // fecha de plantación nueva, se conserva la del contexto previo para que
      // la edad sobreviva a transiciones de etapa/producción (#4, #14).
      // Cactus/ornamental NO usa sowingDate como eje: la fecha vive en
      // ornamentalAnchorDate. Solo árboles y anuales usan sowingDate.
      sowingDate: effectiveLifecycleStatus == CropLifecycleStatus.planted
          ? (isTreeContext
                ? (treePlantingDate ?? carriedTreeSowingDate)
                : (isOrnamentalLike ? null : selectedDate))
          : null,
      plannedSowingDate:
          !isTreeContext &&
              !isOrnamentalLike &&
              lifecycleStatus == CropLifecycleStatus.planned
          ? selectedDate
          : null,
      sowingDateConfidence: isOrnamentalLike
          ? DateConfidence.unknown
          : dateConfidence,
      cultivationScaleId: resolvedScaleId,
      sowingModeId: isOrnamentalLike
          ? null
          : (sowingModeId ??
                _sowingModeIdFromLifecycle(effectiveLifecycleStatus)),
      timezone: resolvedTimezone,
      regionCode: resolvedRegionCode,
      cycleLabel: cycleLabel ?? previous?.cycleLabel,
      perennialStateId: isTreeContext ? perennialStateId : null,
      // Las ornamentales no usan fenología productiva.
      phenologyStageId: isTreeContext ? phenologyStageId : null,
      perennialAnchorDate: isTreeContext ? perennialAnchorDate : null,
      perennialAnchorTypeId: isTreeContext ? perennialAnchorTypeId : null,
      lifecycleModeId: isOrnamentalContext
          ? ornamentalLifecycleMode(normalizedCropId)
          : isRecurringBloomContext
          ? kRecurringBloomLifecycleModeId
          // Tulipán (seasonal_bulb): persiste su modo de ciclo bulboso estacional.
          // El sowingDate se conserva arriba como ancla real (no se anula).
          : isSeasonalBulbCrop(cropId: normalizedCropId)
          ? kSeasonalBulbLifecycleModeId
          // Girasol (annual_ornamental): persiste su modo de ciclo anual. El
          // sowingDate se conserva arriba como ancla real (no se anula).
          : isAnnualOrnamentalCrop(cropId: normalizedCropId)
          ? kAnnualOrnamentalLifecycleModeId
          : null,
      ornamentalStageId: ornamentalStateId,
      ornamentalAnchorDate: ornamentalAnchor,
      ornamentalAnchorTypeId: ornamentalAnchorType,
      ornamentalAnchorDateConfidence: isOrnamentalLike
          ? dateConfidence
          : null,
      ornamentalStageConfidence: ornamentalConfidence,
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
    // En las ornamentales la selección visible vive en el catálogo de perfiles,
    // pero también se persiste como varietyId para que la identidad elegida
    // viaje completa por wizard -> storage -> runtime. No la descartamos solo
    // porque no exista una fila en el catálogo de variedades anuales.
    if (isEstablishmentMaintenanceCrop(cropId: cropId) ||
        isRecurringBloomCrop(cropId: cropId) ||
        // Tulipán (seasonal_bulb): también identifica su tipo por PERFIL (tu_*),
        // aunque conserve el eje de fecha de un grano.
        isSeasonalBulbCrop(cropId: cropId) ||
        // Girasol (annual_ornamental): identifica su tipo por PERFIL (gi_*),
        // aunque conserve el eje de fecha de un grano.
        isAnnualOrnamentalCrop(cropId: cropId)) {
      return (CropCatalog.profileByAny(cropId, varietyId) ??
              CropCatalog.profileByAny(cropId, varietyAlias))
          ?.id;
    }

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

    if (isEstablishmentMaintenanceCrop(cropId: cropId)) {
      final profile =
          CropCatalog.profileByAny(cropId, resolvedProfileId) ??
          CropCatalog.profileByAny(cropId, rawValue);
      return profile?.label ?? ornamentalGeneralProfileLabel(cropId);
    }

    if (isRecurringBloomCrop(cropId: cropId)) {
      final profile =
          CropCatalog.profileByAny(cropId, resolvedProfileId) ??
          CropCatalog.profileByAny(cropId, rawValue);
      return profile?.label ?? recurringBloomGeneralProfileLabel(cropId);
    }

    // Tulipán (seasonal_bulb): la selección visible es un PERFIL; se persiste su
    // etiqueta humana, nunca el id interno tu_*.
    if (isSeasonalBulbCrop(cropId: cropId)) {
      final profile =
          CropCatalog.profileByAny(cropId, resolvedProfileId) ??
          CropCatalog.profileByAny(cropId, rawValue);
      return profile?.label ?? seasonalBulbGeneralProfileLabel(cropId);
    }

    // Girasol (annual_ornamental): la selección visible es un PERFIL; se persiste
    // su etiqueta humana, nunca el id interno gi_*.
    if (isAnnualOrnamentalCrop(cropId: cropId)) {
      final profile =
          CropCatalog.profileByAny(cropId, resolvedProfileId) ??
          CropCatalog.profileByAny(cropId, rawValue);
      return profile?.label ?? annualOrnamentalGeneralProfileLabel(cropId);
    }

    if (isTreeCrop(cropId: cropId)) {
      final profile =
          CropCatalog.profileByAny(cropId, rawValue) ??
          CropCatalog.profileByAny(cropId, resolvedProfileId);
      return TreeProfilePresentation.displayLabel(
        cropId,
        profile?.id ?? resolvedProfileId,
        fallbackLabel: profile?.label ?? rawValue,
      );
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
    if (isTreeCrop(cropId: cropId)) {
      final profile =
          CropCatalog.profileByAny(cropId, varietyId) ??
          CropCatalog.profileByAny(cropId, varietyAlias);
      return profile?.id;
    }

    if (isEstablishmentMaintenanceCrop(cropId: cropId) ||
        isRecurringBloomCrop(cropId: cropId) ||
        // Tulipán (seasonal_bulb): el tu_* se resuelve como perfil explícito.
        isSeasonalBulbCrop(cropId: cropId) ||
        // Girasol (annual_ornamental): el gi_* se resuelve como perfil explícito.
        isAnnualOrnamentalCrop(cropId: cropId)) {
      return (CropCatalog.profileByAny(cropId, varietyId) ??
              CropCatalog.profileByAny(cropId, varietyAlias))
          ?.id;
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
