import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/widgets/seeds/cucumber_profiles.dart';
import 'package:bio_g/widgets/seeds/tomato_profiles.dart';

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
  static const String _tomatoIconAsset = 'assets/icons/wizard/ic_tomate.png';
  static const String _cucumberIconAsset =
      'assets/icons/wizard/ic_cucumber.png';
  static const String _cucumberSlicerIconAsset =
      'assets/icons/wizard/ic_cucumber_slicer.png';
  static const String _cucumberEnglishProtectedIconAsset =
      'assets/icons/wizard/ic_cucumber_english_protected.png';
  static const String _cucumberPersianMiniIconAsset =
      'assets/icons/wizard/ic_cucumber_persian_mini.png';
  static const String _cucumberCornichonPicklingIconAsset =
      'assets/icons/wizard/ic_cucumber_cornichon_pickling.png';
  static const String _tomatoGenericIconAsset =
      'assets/icons/wizard/ic_tomate_generico.png';
  static const String _tomatoBolaIconAsset =
      'assets/icons/wizard/ic_tomate_bola.png';
  static const String _tomatoCherryIconAsset =
      'assets/icons/wizard/ic_tomate_cherry.png';
  static const String _tomatoRacimoIconAsset =
      'assets/icons/wizard/ic_tomate_racimo.png';
  static const String _tomatoSaladetteOpenIconAsset =
      'assets/icons/wizard/ic_tomate_saladette_campo_abierto.png';
  static const String _tomatoSaladetteProtectedIconAsset =
      'assets/icons/wizard/ic_tomate_saladette_protegido.png';

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
      return CropCatalog.isGenericAlias(alias) || alias.startsWith('generic_');
    }

    final profile = CropCatalog.profileByAny(
      cropId,
      cropContext?.profileId ?? seed?.profileId,
    );
    if (profile != null) {
      return CropCatalog.isGenericProfileId(profile.id);
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
      case CropCatalog.tomatoCropId:
        return _resolveTomatoIcon(rawVarietyValue);
      case CropCatalog.cucumberCropId:
        return _resolveCucumberIcon(rawVarietyValue);
      default:
        return _genericPlantIconAsset;
    }
  }

  static String _resolveTomatoIcon(String? rawVarietyValue) {
    final raw = (rawVarietyValue ?? '').trim();
    if (raw.isEmpty) return _tomatoIconAsset;

    final canonical = resolveCanonicalTomatoProfileId(raw);
    switch (canonical) {
      case kTm01:
        return _tomatoSaladetteOpenIconAsset;
      case kTm02:
        return _tomatoSaladetteProtectedIconAsset;
      case kTm03:
        return _tomatoBolaIconAsset;
      case kTm04:
        return _tomatoCherryIconAsset;
      case kTm05:
        return _tomatoRacimoIconAsset;
      case kTmGen:
        return _tomatoGenericIconAsset;
    }

    final normalized = raw.toLowerCase();
    if (normalized.contains('cherry') || normalized.contains('uva')) {
      return _tomatoCherryIconAsset;
    }
    if (normalized.contains('bola') ||
        normalized.contains('redondo') ||
        normalized.contains('beef')) {
      return _tomatoBolaIconAsset;
    }
    if (normalized.contains('racimo') ||
        normalized.contains('tov') ||
        normalized.contains('truss')) {
      return _tomatoRacimoIconAsset;
    }
    if (normalized.contains('saladette') ||
        normalized.contains('roma') ||
        normalized.contains('pera')) {
      if (normalized.contains('protegido') ||
          normalized.contains('invernadero') ||
          normalized.contains('malla')) {
        return _tomatoSaladetteProtectedIconAsset;
      }
      return _tomatoSaladetteOpenIconAsset;
    }
    if (normalized.contains('gen')) return _tomatoGenericIconAsset;
    return _tomatoIconAsset;
  }

  static String _resolveCucumberIcon(String? rawVarietyValue) {
    final raw = (rawVarietyValue ?? '').trim();
    if (raw.isEmpty) return _cucumberIconAsset;

    final canonical = resolveCanonicalCucumberProfileId(raw);
    switch (canonical) {
      case kPe01:
        return _cucumberSlicerIconAsset;
      case kPe02:
        return _cucumberEnglishProtectedIconAsset;
      case kPe03:
        return _cucumberPersianMiniIconAsset;
      case kPe04:
        return _cucumberCornichonPicklingIconAsset;
      case kPeGen:
        return _cucumberIconAsset;
    }

    final variety = CropCatalog.varietyByAny(CropCatalog.cucumberCropId, raw);
    switch (variety?.id) {
      case 'cucumber_slicer_ca':
        return _cucumberSlicerIconAsset;
      case 'cucumber_european_protected':
        return _cucumberEnglishProtectedIconAsset;
      case 'cucumber_persian':
        return _cucumberPersianMiniIconAsset;
      case 'cucumber_pickler':
        return _cucumberCornichonPicklingIconAsset;
      case 'cucumber_generic':
        return _cucumberIconAsset;
    }

    final normalized = raw.toLowerCase();
    if (normalized.contains('pickler') ||
        normalized.contains('cornichon') ||
        normalized.contains('cornichÃ³n') ||
        normalized.contains('encurtido') ||
        normalized.contains('pepinillo')) {
      return _cucumberCornichonPicklingIconAsset;
    }
    if (normalized.contains('persa') ||
        normalized.contains('persian') ||
        normalized.contains('mini') ||
        normalized.contains('beit')) {
      return _cucumberPersianMiniIconAsset;
    }
    if (normalized.contains('slicer') ||
        normalized.contains('americano') ||
        normalized.contains('criollo')) {
      return _cucumberSlicerIconAsset;
    }
    if (normalized.contains('europeo') ||
        normalized.contains('ingles') ||
        normalized.contains('inglÃ©s') ||
        normalized.contains('english') ||
        normalized.contains('protegido')) {
      return _cucumberEnglishProtectedIconAsset;
    }
    if (normalized.contains('gen')) return _cucumberIconAsset;
    return _cucumberIconAsset;
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

  static String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
