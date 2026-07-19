import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/cactus/cactus_crop_definition.dart';
import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/succulent/succulent_crop_definition.dart';
import 'package:bio_g/core/crops/aloe/aloe_crop_definition.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_presentation_resolver.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/tree_stage_resolver.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';

class CropRuntimeResolver {
  CropRuntimeResolver._();

  static CropRuntimeSnapshot resolve({
    required BioGDevice? device,
    required SeedInstall? seed,
    DeviceCropContext? cropContext,
    required BioGTelemetry? live,
    required AlertsState alertsState,
    DateTime? now,
  }) {
    final DateTime today = now ?? DateTime.now();
    final DeviceCropContext? normalizedContext = _normalizeContext(cropContext);
    final SeedInstall? effectiveSeed = normalizedContext != null
        ? SeedInstall.fromDeviceCropContext(normalizedContext)
        : seed;

    final SowingStatus sowingStatus = _resolveSowingStatus(
      seed: effectiveSeed,
      cropContext: normalizedContext,
    );

    final bool hasSeed = effectiveSeed != null || normalizedContext != null;

    final String cropKeyName = _canonicalCropKey(
      normalizedContext?.cropId ?? effectiveSeed?.cropKey,
    );

    final CropDefinition? definition = cropKeyName.isEmpty
        ? null
        : CropRegistry.byKeyName(cropKeyName);

    final CropProfile? profile = _resolveProfile(
      seed: effectiveSeed,
      cropContext: normalizedContext,
      definition: definition,
      cropKeyName: cropKeyName,
      sowingStatus: sowingStatus,
    );

    final DateTime? plantedDate = _resolvePlantedDate(
      seed: effectiveSeed,
      cropContext: normalizedContext,
    );

    final bool isPerennialRuntime = isPerennialCrop(
      cropId: cropKeyName,
      cropCategoryId: normalizedContext?.cropCategoryId,
      category: definition?.category,
    );

    // Ornamental de establecimiento/mantenimiento (cactus, suculenta…): el eje
    // NO es la siembra; la etapa se resuelve por estado guardado o por la fecha
    // de plantación. No hay rendimiento ni cosecha. La pregunta es por el MODO
    // DE CICLO, no por una planta concreta.
    final bool isOrnamentalRuntime = isEstablishmentMaintenanceCrop(
      cropId: cropKeyName,
      cropCategoryId: normalizedContext?.cropCategoryId,
      category: definition?.category,
    );

    final bool isPlanted =
        sowingStatus == SowingStatus.planted &&
        (isPerennialRuntime || isOrnamentalRuntime || plantedDate != null);

    final bool isPlanned = sowingStatus == SowingStatus.planned;

    final presentation = CropPresentationResolver.resolve(
      cropContext: normalizedContext,
      seed: effectiveSeed,
      definition: definition,
      explicitCropId: cropKeyName,
    );

    CropStageResult? stageResult;
    StageTargets? targets;
    AgroEvalResult? eval;
    DateTime? engineSowingDate;
    AlertsState nextAlertsState = alertsState;

    if (isOrnamentalRuntime &&
        (sowingStatus == SowingStatus.planted ||
            sowingStatus == SowingStatus.planned) &&
        normalizedContext != null) {
      // Ornamental: etapa por estado guardado o por fecha (sin cosecha ni
      // rendimiento). NO se invoca YieldProjection.
      stageResult = resolveOrnamentalStageResult(
        context: normalizedContext,
        today: today,
      );

      if (definition != null && profile != null) {
        targets = definition is CactusCropDefinition
            ? definition.resolveTargetsForProfile(
                stageResult,
                profileId: profile.id,
              )
            : definition is SucculentCropDefinition
            ? definition.resolveTargetsForProfile(
                stageResult,
                profileId: profile.id,
              )
            : definition is AloeCropDefinition
            ? definition.resolveTargetsForProfile(
                stageResult,
                profileId: profile.id,
              )
            : definition.resolveTargets(stageResult);

        if (sowingStatus == SowingStatus.planted && live != null) {
          final out = definition.evaluateTelemetry(
            telemetry: live,
            stage: stageResult,
            profile: profile,
            targetsOverride: targets,
            alertsState: alertsState,
          );
          eval = out.eval;
          nextAlertsState = out.nextAlertsState;
        }
      }
    } else if (isPerennialRuntime &&
        sowingStatus == SowingStatus.planted &&
        normalizedContext != null) {
      stageResult = PerennialStageResolver.resolve(
        context: normalizedContext,
        today: today,
      );

      if (definition != null && profile != null) {
        targets = definition.resolveTargets(stageResult);

        if (live != null) {
          final out = definition.evaluateTelemetry(
            telemetry: live,
            stage: stageResult,
            profile: profile,
            targetsOverride: targets,
            alertsState: alertsState,
          );
          eval = out.eval;
          nextAlertsState = out.nextAlertsState;
        }
      }
    } else if (!isPerennialRuntime &&
        !isOrnamentalRuntime &&
        isPlanted &&
        definition != null &&
        profile != null) {
      final DateTime effectiveSowingDate = _effectiveSowingDateForCalendar(
        cropId: cropKeyName,
        calendarTypeId: normalizedContext?.calendarTypeId,
        plantedDate: plantedDate!,
      );
      engineSowingDate = effectiveSowingDate;

      stageResult = definition.engine.compute(
        sowingDate: effectiveSowingDate,
        today: today,
        profile: profile,
        stressDelayDays: 0,
      );

      final StageTargets? baseTargets = definition.resolveTargets(stageResult);
      if (baseTargets != null) {
        targets = CropCatalog.adjustTargetsForCalendar(
          cropId: cropKeyName,
          calendarId: normalizedContext?.calendarTypeId,
          stageKey: stageResult.stageKey,
          baseTargets: baseTargets,
        );
      }

      if (live != null) {
        final out = definition.evaluateTelemetry(
          telemetry: live,
          stage: stageResult,
          profile: profile,
          targetsOverride: targets,
          alertsState: alertsState,
        );
        eval = out.eval;
        nextAlertsState = out.nextAlertsState;
      }
    }

    return CropRuntimeSnapshot(
      device: device,
      live: live,
      seed: effectiveSeed,
      cropContext: normalizedContext,
      definition: definition,
      profile: profile,
      stageResult: stageResult,
      targets: targets,
      eval: eval,
      nextAlertsState: nextAlertsState,
      cropKeyName: cropKeyName,
      cropLabel: presentation.runtimeLabel,
      cropIconAsset: presentation.iconAsset,
      stageLabel: _buildStageLabel(
        sowingStatus: sowingStatus,
        stageResult: stageResult,
        hasSeed: hasSeed,
        hasResolvedDefinition: definition != null,
        hasResolvedProfile: profile != null,
      ),
      sowingStatus: sowingStatus,
      engineSowingDate: engineSowingDate,
      hasSeed: hasSeed,
      isPlanted: isPlanted,
      isPlanned: isPlanned,
      isGenericMode: presentation.isGenericSelection,
    );
  }

  static CropProfile? _resolveProfile({
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
    required CropDefinition? definition,
    required String cropKeyName,
    required SowingStatus sowingStatus,
  }) {
    if (definition == null) return null;
    if (cropKeyName.isEmpty) return null;
    if (sowingStatus == SowingStatus.skip) return null;

    final bool isOrnamental = isEstablishmentMaintenanceCrop(
      cropId: cropKeyName,
      cropCategoryId: cropContext?.cropCategoryId,
      category: definition.category,
    );
    final String? ornamentalSelectionId = isOrnamental
        ? _resolveOrnamentalSelectionId(
            cropId: cropKeyName,
            profileId: cropContext?.profileId ?? seed?.profileId,
            varietyId: cropContext?.varietyId,
            varietyAlias: cropContext?.varietyAlias ?? seed?.varietyAlias,
          )
        : null;

    final String? rawVarietyValue = isOrnamental
        ? ornamentalSelectionId
        : cropContext?.varietyId ??
              cropContext?.varietyAlias ??
              seed?.varietyAlias;

    final String? resolvedVarietyId = CropCatalog.resolveVarietyId(
      cropId: cropKeyName,
      rawValue: rawVarietyValue,
    );

    final String? explicitProfileId = isOrnamental
        ? ornamentalSelectionId
        : _normalizeNullable(cropContext?.profileId ?? seed?.profileId);

    final String resolvedProfileId = CropCatalog.resolveProfileId(
      cropId: cropKeyName,
      varietyId: resolvedVarietyId,
      explicitProfileId: explicitProfileId,
    );

    return definition.resolveProfile(
      profileId: resolvedProfileId,
      varietyAlias: cropContext?.varietyAlias ?? seed?.varietyAlias,
    );
  }

  static SowingStatus _resolveSowingStatus({
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
  }) {
    if (cropContext != null) {
      switch (cropContext.lifecycleStatus) {
        case CropLifecycleStatus.planned:
          return SowingStatus.planned;
        case CropLifecycleStatus.planted:
          return SowingStatus.planted;
        case CropLifecycleStatus.fallow:
          return SowingStatus.skip;
      }
    }

    return seed?.status ?? SowingStatus.skip;
  }

  static DateTime? _resolvePlantedDate({
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
  }) {
    final status = _resolveSowingStatus(seed: seed, cropContext: cropContext);
    if (status != SowingStatus.planted) return null;
    return cropContext?.sowingDate ?? seed?.sowingDate;
  }

  static String _canonicalCropKey(String? raw) =>
      CropCatalog.canonicalCropKey(raw);

  static DateTime _effectiveSowingDateForCalendar({
    required String cropId,
    required String? calendarTypeId,
    required DateTime plantedDate,
  }) {
    final int offsetDays = CropCatalog.phenologyOffsetDaysForCalendar(
      cropId: cropId,
      calendarId: calendarTypeId,
    );

    if (offsetDays == 0) return plantedDate;
    return plantedDate.subtract(Duration(days: offsetDays));
  }

  static String _buildStageLabel({
    required SowingStatus sowingStatus,
    required CropStageResult? stageResult,
    required bool hasSeed,
    required bool hasResolvedDefinition,
    required bool hasResolvedProfile,
  }) {
    if (!hasSeed) {
      return 'Sin cultivo configurado';
    }

    if (sowingStatus == SowingStatus.planted) {
      if (stageResult != null) {
        return stageResult.stageLabelEs;
      }

      if (!hasResolvedDefinition || !hasResolvedProfile) {
        return 'Cultivo configurado';
      }

      return 'Etapa desconocida';
    }

    if (sowingStatus == SowingStatus.planned) {
      if (stageResult != null) {
        return stageResult.stageLabelEs;
      }
      return 'Pre-siembra';
    }

    return 'Descanso del suelo';
  }

  static DeviceCropContext? _normalizeContext(DeviceCropContext? cropContext) {
    if (cropContext == null) return null;

    final String cropId = CropCatalog.canonicalCropKey(cropContext.cropId);
    if (cropId.isEmpty) {
      return cropContext;
    }

    final cropEntry = CropCatalog.cropById(cropId);
    final String cropCategoryId =
        _normalizeNullable(cropContext.cropCategoryId) ??
        cropEntry?.categoryId ??
        CropCatalog.grainCategoryId;

    final bool isOrnamental = isEstablishmentMaintenanceCrop(
      cropId: cropId,
      cropCategoryId: cropCategoryId,
    );
    final bool isFallow =
        cropContext.lifecycleStatus == CropLifecycleStatus.fallow &&
        !isOrnamental;
    final CropLifecycleStatus normalizedLifecycleStatus =
        isOrnamental && cropContext.lifecycleStatus == CropLifecycleStatus.fallow
        ? CropLifecycleStatus.planted
        : cropContext.lifecycleStatus;
    final String? ornamentalSelectionId = isOrnamental
        ? _resolveOrnamentalSelectionId(
            cropId: cropId,
            profileId: cropContext.profileId,
            varietyId: cropContext.varietyId,
            varietyAlias: cropContext.varietyAlias,
          )
        : null;
    final String? rawVarietyValue = isFallow
        ? null
        : (isOrnamental
              ? ornamentalSelectionId
              : (cropContext.varietyId ?? cropContext.varietyAlias));

    final String? resolvedVarietyId = isFallow
        ? null
        : isOrnamental
        ? ornamentalSelectionId
        : CropCatalog.resolveVarietyId(
            cropId: cropId,
            rawValue: rawVarietyValue,
          );

    final String resolvedProfileId = isOrnamental
        ? (ornamentalSelectionId ?? ornamentalDefaultProfileId(cropId))
        : CropCatalog.resolveProfileId(
            cropId: cropId,
            varietyId: resolvedVarietyId,
            explicitProfileId: isFallow
                ? null
                : _normalizeNullable(cropContext.profileId),
          );

    final resolvedVarietyAlias = _resolvedVarietyAlias(
      cropId: cropId,
      lifecycleStatus: normalizedLifecycleStatus,
      rawVarietyAlias: cropContext.varietyAlias,
      resolvedVarietyId: resolvedVarietyId,
      resolvedProfileId: resolvedProfileId,
    );

    return cropContext.copyWith(
      cropCategoryId: cropCategoryId,
      cropId: cropId,
      profileId: resolvedProfileId,
      lifecycleStatus: normalizedLifecycleStatus,
      brandId: _resolveBrandId(
        cropId: cropId,
        explicitBrandId: isFallow ? null : cropContext.brandId,
        varietyId: resolvedVarietyId,
      ),
      varietyId: resolvedVarietyId,
      varietyAlias: resolvedVarietyAlias,
      lifecycleModeId: isOrnamental
          ? ornamentalLifecycleMode(cropId)
          : cropContext.lifecycleModeId,
      ornamentalStageId: isOrnamental
          ? normalizeOrnamentalStageId(
              cropId,
              cropContext.ornamentalStageId ?? cropContext.perennialStateId,
            )
          : cropContext.ornamentalStageId,
      ornamentalAnchorDate: isOrnamental
          ? cropContext.ornamentalAnchorDate ?? cropContext.perennialAnchorDate
          : cropContext.ornamentalAnchorDate,
      ornamentalAnchorTypeId: isOrnamental
          ? cropContext.ornamentalAnchorTypeId ??
                cropContext.perennialAnchorTypeId
          : cropContext.ornamentalAnchorTypeId,
      perennialStateId: isOrnamental ? null : cropContext.perennialStateId,
      phenologyStageId: isOrnamental ? null : cropContext.phenologyStageId,
      perennialAnchorDate: isOrnamental ? null : cropContext.perennialAnchorDate,
      perennialAnchorTypeId: isOrnamental
          ? null
          : cropContext.perennialAnchorTypeId,
      cultivationScaleId: isOrnamental ? null : cropContext.cultivationScaleId,
      calendarTypeId: CropCatalog.resolveCalendarId(
        cropId: cropId,
        requested: cropContext.calendarTypeId,
      ),
      sowingDate:
          !isOrnamental &&
              cropContext.lifecycleStatus == CropLifecycleStatus.planted
          ? cropContext.sowingDate
          : null,
      plannedSowingDate:
          !isOrnamental &&
              cropContext.lifecycleStatus == CropLifecycleStatus.planned
          ? cropContext.plannedSowingDate
          : null,
      sowingModeId: isOrnamental
          ? null
          : _normalizeNullable(cropContext.sowingModeId) ??
                _defaultSowingModeId(cropContext.lifecycleStatus),
    );
  }

  static String? _resolveBrandId({
    required String cropId,
    required String? explicitBrandId,
    required String? varietyId,
  }) {
    if (varietyId != null && varietyId.isNotEmpty) {
      final variety = CropCatalog.varietyById(cropId, varietyId);
      final fromVariety = _normalizeNullable(variety?.brandId);
      if (fromVariety != null) {
        return fromVariety;
      }
    }

    final normalizedExplicit = _normalizeNullable(explicitBrandId);
    if (normalizedExplicit == null) return null;

    final valid = CropCatalog.brandsForCrop(
      cropId,
    ).any((brand) => brand.id == normalizedExplicit);
    return valid ? normalizedExplicit : null;
  }

  static String? _resolvedVarietyAlias({
    required String cropId,
    required CropLifecycleStatus lifecycleStatus,
    required String? rawVarietyAlias,
    required String? resolvedVarietyId,
    required String resolvedProfileId,
  }) {
    if (lifecycleStatus == CropLifecycleStatus.fallow) {
      return 'generic';
    }

    if (isEstablishmentMaintenanceCrop(cropId: cropId)) {
      return CropCatalog.profileByAny(cropId, resolvedProfileId)?.label ??
          ornamentalGeneralProfileLabel(cropId);
    }

    if (resolvedVarietyId != null) {
      final variety = CropCatalog.varietyById(cropId, resolvedVarietyId);
      if (variety != null) {
        return variety.isGeneric ? 'generic' : variety.label;
      }
    }

    if (CropCatalog.isGenericAlias(rawVarietyAlias) ||
        CropCatalog.isGenericProfileId(resolvedProfileId)) {
      return 'generic';
    }

    return _normalizeNullable(rawVarietyAlias);
  }

  static String _defaultSowingModeId(CropLifecycleStatus status) {
    return switch (status) {
      CropLifecycleStatus.planned => 'planned',
      CropLifecycleStatus.planted => 'planted',
      CropLifecycleStatus.fallow => 'skip',
    };
  }

  static String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  /// Resuelve la selección visible de una ornamental (cactus, suculenta…).
  ///
  /// Una selección específica superviviente REPARA un perfil general heredado:
  /// si el usuario eligió "Suculenta colgante" y un roundtrip dejó `su_skip` en
  /// `profileId`, la selección se recupera de `varietyId`/`varietyAlias`.
  static String? _resolveOrnamentalSelectionId({
    required String cropId,
    String? profileId,
    String? varietyId,
    String? varietyAlias,
  }) {
    final fromProfile = CropCatalog.profileByAny(cropId, profileId);
    final fromVariety = CropCatalog.profileByAny(cropId, varietyId);
    final fromAlias = CropCatalog.profileByAny(cropId, varietyAlias);

    final String generalProfileId = ornamentalDefaultProfileId(cropId);
    for (final entry in [fromVariety, fromProfile, fromAlias]) {
      if (entry != null && entry.id != generalProfileId) {
        return entry.id;
      }
    }
    return fromProfile?.id ?? fromVariety?.id ?? fromAlias?.id;
  }
}
