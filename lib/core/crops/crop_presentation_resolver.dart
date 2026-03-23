import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';

class CropPresentationData {
  final bool hasConfiguredCrop;
  final bool isFallowMode;
  final bool isGenericSelection;
  final String cropId;
  final String cropDisplayName;
  final String? varietyLabel;
  final String headlineLabel;
  final String runtimeLabel;
  final String iconAsset;

  const CropPresentationData({
    required this.hasConfiguredCrop,
    required this.isFallowMode,
    required this.isGenericSelection,
    required this.cropId,
    required this.cropDisplayName,
    required this.varietyLabel,
    required this.headlineLabel,
    required this.runtimeLabel,
    required this.iconAsset,
  });
}

class CropPresentationResolver {
  CropPresentationResolver._();

  static const String _genericPlantIconAsset =
      'assets/icons/wizard/ic_planta_generica.png';
  static const String _maizeIconAsset = 'assets/icons/wizard/ic_maiz.png';
  static const String _maizeWhiteIconAsset =
      'assets/icons/wizard/ic_maiz_blanco.png';
  static const String _maizeForageIconAsset =
      'assets/icons/wizard/ic_maiz_forrajero.png';
  static const String _maizeEloteIconAsset =
      'assets/icons/wizard/ic_maiz_elotero.png';
  static const String _beanPintoIconAsset = 'assets/icons/wizard/ic_frijol.png';
  static const String _beanRedIconAsset =
      'assets/icons/wizard/ic_frijol_rojo.png';
  static const String _beanBlackIconAsset =
      'assets/icons/wizard/ic_frijol_negro.png';
  static const String _beanWhiteIconAsset =
      'assets/icons/wizard/ic_frijol_blanco.png';
  static const String _wheatIconAsset = 'assets/icons/wizard/ic_trigo.png';
  static const String _barleyIconAsset = 'assets/icons/wizard/ic_cebada.png';
  static const String _oatIconAsset = 'assets/icons/wizard/ic_avena.png';

  static CropPresentationData resolve({
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
    CropDefinition? definition,
    String? explicitCropId,
  }) {
    final hasConfiguredCrop = cropContext != null || seed != null;
    final cropId = CropCatalog.canonicalCropKey(
      explicitCropId ?? cropContext?.cropId ?? seed?.cropKey,
    );
    final sowingStatus = _resolveSowingStatus(
      cropContext: cropContext,
      seed: seed,
    );

    if (!hasConfiguredCrop) {
      return const CropPresentationData(
        hasConfiguredCrop: false,
        isFallowMode: false,
        isGenericSelection: true,
        cropId: '',
        cropDisplayName: 'Sin cultivo configurado',
        varietyLabel: null,
        headlineLabel: 'Sin cultivo configurado',
        runtimeLabel: 'Sin cultivo configurado',
        iconAsset: _genericPlantIconAsset,
      );
    }

    if (sowingStatus == SowingStatus.skip) {
      return CropPresentationData(
        hasConfiguredCrop: true,
        isFallowMode: true,
        isGenericSelection: true,
        cropId: cropId,
        cropDisplayName: 'Descanso del suelo',
        varietyLabel: null,
        headlineLabel: 'Descanso del suelo',
        runtimeLabel: 'Descanso del suelo',
        iconAsset: _genericPlantIconAsset,
      );
    }

    final cropDisplayName =
        CropCatalog.cropById(cropId)?.label ??
        definition?.displayName ??
        CropCatalog.cropDisplayName(cropId);

    final resolvedVariety = CropCatalog.varietyByAny(
      cropId,
      cropContext?.varietyId ?? cropContext?.varietyAlias ?? seed?.varietyAlias,
    );

    final isGenericSelection = _isGenericSelection(
      cropId: cropId,
      cropContext: cropContext,
      seed: seed,
      resolvedVarietyIsGeneric: resolvedVariety?.isGeneric,
    );

    final varietyLabel = (resolvedVariety != null && !resolvedVariety.isGeneric)
        ? resolvedVariety.label
        : null;

    final aliasFallback = _normalizeNullable(
      cropContext?.varietyAlias ?? seed?.varietyAlias,
    );

    final detailLabel = isGenericSelection
        ? 'Perfil genérico'
        : (varietyLabel ?? aliasFallback);

    final headlineLabel = detailLabel == null || detailLabel.isEmpty
        ? cropDisplayName
        : '$cropDisplayName · $detailLabel';

    final runtimeLabel = detailLabel == null || detailLabel.isEmpty
        ? cropDisplayName
        : '$cropDisplayName ($detailLabel)';

    return CropPresentationData(
      hasConfiguredCrop: true,
      isFallowMode: false,
      isGenericSelection: isGenericSelection,
      cropId: cropId,
      cropDisplayName: cropDisplayName,
      varietyLabel: varietyLabel,
      headlineLabel: headlineLabel,
      runtimeLabel: runtimeLabel,
      iconAsset: _resolveIconAsset(
        cropId: cropId,
        cropContext: cropContext,
        seed: seed,
      ),
    );
  }

  static SowingStatus _resolveSowingStatus({
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
  }) {
    if (cropContext != null) {
      return switch (cropContext.lifecycleStatus) {
        CropLifecycleStatus.planned => SowingStatus.planned,
        CropLifecycleStatus.planted => SowingStatus.planted,
        CropLifecycleStatus.fallow => SowingStatus.skip,
      };
    }

    return seed?.status ?? SowingStatus.skip;
  }

  static bool _isGenericSelection({
    required String cropId,
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
    required bool? resolvedVarietyIsGeneric,
  }) {
    if (cropId.isEmpty) return true;

    if (_resolveSowingStatus(cropContext: cropContext, seed: seed) ==
        SowingStatus.skip) {
      return true;
    }

    if (resolvedVarietyIsGeneric != null) {
      return resolvedVarietyIsGeneric;
    }

    final alias = (cropContext?.varietyAlias ?? seed?.varietyAlias ?? '')
        .trim()
        .toLowerCase();

    if (alias.isNotEmpty) {
      return alias == 'generic' ||
          alias == 'generico' ||
          alias == 'genérico' ||
          alias == 'perfil genérico' ||
          alias == 'generic_maize' ||
          alias == 'generic_corn' ||
          alias == 'generic_bean' ||
          alias == 'generic_wheat' ||
          alias == 'generic_barley' ||
          alias == 'generic_oat' ||
          alias.startsWith('generic_');
    }

    final profile = CropCatalog.profileByAny(
      cropId,
      cropContext?.profileId ?? seed?.profileId,
    );
    if (profile != null) {
      return _isGenericProfileId(profile.id);
    }

    return false;
  }

  static String _resolveIconAsset({
    required String cropId,
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
  }) {
    final rawVarietyValue =
        cropContext?.varietyId ??
        cropContext?.varietyAlias ??
        seed?.varietyAlias;

    switch (cropId) {
      case CropCatalog.maizeCropId:
        return _resolveMaizeIcon(rawVarietyValue);
      case CropCatalog.beanCropId:
        return _resolveBeanIcon(rawVarietyValue);
      case CropCatalog.wheatCropId:
        return _wheatIconAsset;
      case CropCatalog.barleyCropId:
        return _barleyIconAsset;
      case CropCatalog.oatCropId:
        return _oatIconAsset;
      default:
        return _genericPlantIconAsset;
    }
  }

  static String _resolveMaizeIcon(String? rawVarietyValue) {
    if (rawVarietyValue == null || rawVarietyValue.trim().isEmpty) {
      return _maizeIconAsset;
    }

    final variety = CropCatalog.varietyByAny(
      CropCatalog.maizeCropId,
      rawVarietyValue,
    );
    if (variety == null) return _maizeIconAsset;

    final useTypeId = variety.useTypeId;
    final marketTypeId = variety.marketTypeId;

    if (useTypeId == 'elote') {
      return _maizeEloteIconAsset;
    }

    if (useTypeId == 'forage') {
      if (marketTypeId == 'white') {
        return _maizeWhiteIconAsset;
      }
      return _maizeForageIconAsset;
    }

    if (marketTypeId == 'white') {
      return _maizeWhiteIconAsset;
    }

    if (marketTypeId == 'yellow') {
      return _maizeIconAsset;
    }

    return _maizeIconAsset;
  }

  static String _resolveBeanIcon(String? rawVarietyValue) {
    final variety = CropCatalog.varietyByAny(
      CropCatalog.beanCropId,
      rawVarietyValue,
    );

    final varietyId = variety?.id;
    final normalizedLabel = (variety?.label ?? rawVarietyValue ?? '')
        .trim()
        .toLowerCase();

    switch (varietyId) {
      case 'bean_negro_temprano':
      case 'bean_negro':
        return _beanBlackIconAsset;
      case 'bean_pinto':
        return _beanPintoIconAsset;
      case 'bean_flor_mayo_junio':
        return _beanRedIconAsset;
      case 'bean_bayo_azufrado_blanco':
        return _beanWhiteIconAsset;
      case 'bean_generic':
        return _beanPintoIconAsset;
    }

    if (normalizedLabel.contains('negro')) return _beanBlackIconAsset;

    if (normalizedLabel.contains('flor de mayo') ||
        normalizedLabel.contains('flor de junio') ||
        normalizedLabel.contains('rojo')) {
      return _beanRedIconAsset;
    }

    if (normalizedLabel.contains('bayo') ||
        normalizedLabel.contains('azufrado') ||
        normalizedLabel.contains('blanco')) {
      return _beanWhiteIconAsset;
    }

    if (normalizedLabel.contains('pinto') || normalizedLabel.contains('gen')) {
      return _beanPintoIconAsset;
    }

    return _beanPintoIconAsset;
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

  static String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
