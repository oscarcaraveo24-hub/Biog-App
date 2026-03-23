import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
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

    final SowingStatus sowingStatus = _resolveSowingStatus(
      seed: seed,
      cropContext: cropContext,
    );

    final bool hasSeed = seed != null || cropContext != null;

    final String cropKeyName = _canonicalCropKey(
      cropContext?.cropId ?? seed?.cropKey,
    );

    final CropDefinition? definition = cropKeyName.isEmpty
        ? null
        : CropRegistry.byKeyName(cropKeyName);

    final CropProfile? profile = _resolveProfile(
      seed: seed,
      cropContext: cropContext,
      definition: definition,
      cropKeyName: cropKeyName,
      sowingStatus: sowingStatus,
    );

    final DateTime? plantedDate = _resolvePlantedDate(
      seed: seed,
      cropContext: cropContext,
    );

    final bool isPlanted =
        sowingStatus == SowingStatus.planted && plantedDate != null;

    final bool isPlanned = sowingStatus == SowingStatus.planned;

    final bool isGenericMode =
        !hasSeed ||
        sowingStatus == SowingStatus.skip ||
        _isGenericSelection(
          cropKeyName: cropKeyName,
          seed: seed,
          cropContext: cropContext,
        );

    CropStageResult? stageResult;
    StageTargets? targets;
    AgroEvalResult? eval;
    AlertsState nextAlertsState = alertsState;

    if (isPlanted && definition != null && profile != null) {
      final DateTime effectivePlantedDate = plantedDate;

      stageResult = definition.engine.compute(
        sowingDate: effectivePlantedDate,
        today: today,
        profile: profile,
        stressDelayDays: 0,
      );

      targets = definition.resolveTargets(stageResult);

      if (live != null) {
        final out = definition.evaluateTelemetry(
          telemetry: live,
          stage: stageResult,
          alertsState: alertsState,
        );
        eval = out.eval;
        nextAlertsState = out.nextAlertsState;
      }
    }

    final SeedInstall? effectiveSeed =
        seed ?? _legacySeedFromContext(cropContext);

    return CropRuntimeSnapshot(
      device: device,
      live: live,
      seed: effectiveSeed,
      cropContext: cropContext,
      definition: definition,
      profile: profile,
      stageResult: stageResult,
      targets: targets,
      eval: eval,
      nextAlertsState: nextAlertsState,
      cropKeyName: cropKeyName,
      cropLabel: _buildCropLabel(
        seed: seed,
        cropContext: cropContext,
        definition: definition,
        cropKeyName: cropKeyName,
      ),
      cropIconAsset: _buildCropIconAsset(
        seed: seed,
        cropContext: cropContext,
        cropKeyName: cropKeyName,
      ),
      stageLabel: _buildStageLabel(
        sowingStatus: sowingStatus,
        stageResult: stageResult,
        hasSeed: hasSeed,
        hasResolvedDefinition: definition != null,
        hasResolvedProfile: profile != null,
      ),
      sowingStatus: sowingStatus,
      hasSeed: hasSeed,
      isPlanted: isPlanted,
      isPlanned: isPlanned,
      isGenericMode: isGenericMode,
    );
  }

  static SeedInstall? _legacySeedFromContext(DeviceCropContext? cropContext) {
    if (cropContext == null) return null;
    return SeedInstall.fromDeviceCropContext(cropContext);
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

    final String? rawVarietyValue =
        cropContext?.varietyId ??
        cropContext?.varietyAlias ??
        seed?.varietyAlias;

    final String? resolvedVarietyId = CropCatalog.resolveVarietyId(
      cropId: cropKeyName,
      rawValue: rawVarietyValue,
    );

    final String? explicitProfileId = _normalizeNullable(
      cropContext?.profileId ?? seed?.profileId,
    );

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
      return 'Pre-siembra';
    }

    return 'Descanso del suelo';
  }

  static String _buildCropLabel({
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
    required CropDefinition? definition,
    required String cropKeyName,
  }) {
    final status = _resolveSowingStatus(seed: seed, cropContext: cropContext);

    if (seed == null && cropContext == null) {
      return 'Sin cultivo configurado';
    }

    if (status == SowingStatus.skip) {
      return 'Descanso del suelo';
    }

    final String displayName =
        CropCatalog.cropById(cropKeyName)?.label ??
        definition?.displayName ??
        _fallbackDisplayName(cropKeyName);

    final String? varietyLabel = _resolvedVarietyLabel(
      cropKeyName: cropKeyName,
      rawValue:
          cropContext?.varietyId ??
          cropContext?.varietyAlias ??
          seed?.varietyAlias,
    );

    final bool isGenericSelection = _isGenericSelection(
      cropKeyName: cropKeyName,
      seed: seed,
      cropContext: cropContext,
    );

    final String baseLabel;
    if (isGenericSelection) {
      baseLabel = '$displayName (Perfil genérico)';
    } else if (varietyLabel != null) {
      baseLabel = '$displayName ($varietyLabel)';
    } else {
      final alias = _normalizeNullable(
        cropContext?.varietyAlias ?? seed?.varietyAlias,
      );
      baseLabel = alias == null ? displayName : '$displayName ($alias)';
    }

    if (status == SowingStatus.planned) {
      return '$baseLabel · Pre-siembra';
    }

    return baseLabel;
  }

  static String? _resolvedVarietyLabel({
    required String cropKeyName,
    required String? rawValue,
  }) {
    if (cropKeyName.isEmpty) return null;

    final variety = CropCatalog.varietyByAny(cropKeyName, rawValue);
    if (variety != null) {
      return variety.isGeneric ? null : variety.label;
    }

    return null;
  }

  static bool _isGenericSelection({
    required String cropKeyName,
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
  }) {
    if (cropKeyName.isEmpty) return true;

    if (_resolveSowingStatus(seed: seed, cropContext: cropContext) ==
        SowingStatus.skip) {
      return true;
    }

    final String? rawVarietyValue =
        cropContext?.varietyId ??
        cropContext?.varietyAlias ??
        seed?.varietyAlias;

    final variety = CropCatalog.varietyByAny(cropKeyName, rawVarietyValue);
    if (variety != null) {
      return variety.isGeneric;
    }

    final alias = (cropContext?.varietyAlias ?? seed?.varietyAlias ?? '')
        .trim()
        .toLowerCase();

    if (alias.isNotEmpty) {
      return alias == 'generic' ||
          alias == 'generico' ||
          alias == 'genérico' ||
          alias == 'perfil genérico' ||
          alias.startsWith('generic_');
    }

    final profile = CropCatalog.profileByAny(
      cropKeyName,
      cropContext?.profileId ?? seed?.profileId,
    );
    if (profile != null) {
      return profile.id.endsWith('_generic') || profile.id == 'fj_gen';
    }

    return false;
  }

  static String _fallbackDisplayName(String? cropKey) =>
      CropCatalog.cropDisplayName(CropCatalog.canonicalCropKey(cropKey));

  static String _buildCropIconAsset({
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
    required String cropKeyName,
  }) {
    final status = _resolveSowingStatus(seed: seed, cropContext: cropContext);

    if (seed == null && cropContext == null) {
      return 'assets/icons/wizard/ic_planta_generica.png';
    }

    if (status == SowingStatus.skip) {
      return 'assets/icons/wizard/ic_planta_generica.png';
    }

    switch (cropKeyName) {
      case CropCatalog.maizeCropId:
        return _resolveMaizeIcon(seed: seed, cropContext: cropContext);
      case CropCatalog.beanCropId:
        return _resolveBeanIcon(seed: seed, cropContext: cropContext);
      default:
        return 'assets/icons/wizard/ic_planta_generica.png';
    }
  }

  static String _resolveMaizeIcon({
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
  }) {
    const String fallback = 'assets/icons/wizard/ic_maiz.png';

    final String? rawVarietyValue =
        cropContext?.varietyId ??
        cropContext?.varietyAlias ??
        seed?.varietyAlias;

    if (rawVarietyValue == null || rawVarietyValue.trim().isEmpty) {
      return fallback;
    }

    final variety = CropCatalog.varietyByAny(
      CropCatalog.maizeCropId,
      rawVarietyValue,
    );
    if (variety == null) return fallback;

    final String? useTypeId = variety.useTypeId;
    final String? marketTypeId = variety.marketTypeId;

    if (useTypeId == 'elote') {
      return 'assets/icons/wizard/ic_maiz_elotero.png';
    }

    if (useTypeId == 'forage') {
      if (marketTypeId == 'white') {
        return 'assets/icons/wizard/ic_maiz_blanco.png';
      }
      return 'assets/icons/wizard/ic_maiz_forrajero.png';
    }

    if (marketTypeId == 'white') {
      return 'assets/icons/wizard/ic_maiz_blanco.png';
    }

    if (marketTypeId == 'yellow') {
      return 'assets/icons/wizard/ic_maiz.png';
    }

    return fallback;
  }

  static String _resolveBeanIcon({
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
  }) {
    const String pinto = 'assets/icons/wizard/ic_frijol.png';
    const String red = 'assets/icons/wizard/ic_frijol_rojo.png';
    const String black = 'assets/icons/wizard/ic_frijol_negro.png';
    const String white = 'assets/icons/wizard/ic_frijol_blanco.png';

    final String? rawVarietyValue =
        cropContext?.varietyId ??
        cropContext?.varietyAlias ??
        seed?.varietyAlias;

    final variety = CropCatalog.varietyByAny(
      CropCatalog.beanCropId,
      rawVarietyValue,
    );

    final String? varietyId = variety?.id;
    final String normalizedLabel = (variety?.label ?? rawVarietyValue ?? '')
        .trim()
        .toLowerCase();

    switch (varietyId) {
      case 'bean_negro_temprano':
      case 'bean_negro':
        return black;
      case 'bean_pinto':
        return pinto;
      case 'bean_flor_mayo_junio':
        return red;
      case 'bean_bayo_azufrado_blanco':
        return white;
      case 'bean_generic':
        return pinto;
    }

    if (normalizedLabel.contains('negro')) return black;

    if (normalizedLabel.contains('flor de mayo') ||
        normalizedLabel.contains('flor de junio') ||
        normalizedLabel.contains('rojo')) {
      return red;
    }

    if (normalizedLabel.contains('bayo') ||
        normalizedLabel.contains('azufrado') ||
        normalizedLabel.contains('blanco')) {
      return white;
    }

    if (normalizedLabel.contains('pinto') || normalizedLabel.contains('gen')) {
      return pinto;
    }

    return pinto;
  }

  static String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
