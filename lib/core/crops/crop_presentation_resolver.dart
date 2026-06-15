import 'package:bio_g/core/crops/apple_tree/apple_tree_assets.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/widgets/seeds/chili_profiles.dart';
import 'package:bio_g/widgets/seeds/cucumber_profiles.dart';
import 'package:bio_g/widgets/seeds/eggplant_profiles.dart';
import 'package:bio_g/widgets/seeds/garlic_profiles.dart';
import 'package:bio_g/widgets/seeds/lettuce_profiles.dart';
import 'package:bio_g/widgets/seeds/onion_profiles.dart';
import 'package:bio_g/widgets/seeds/spinach_profiles.dart';
import 'package:bio_g/widgets/seeds/squash_profiles.dart';
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

  static const String _chiliIconAsset = 'assets/icons/wizard/ic_chili.png';
  static const String _chiliGenericIconAsset =
      'assets/icons/wizard/ic_chili_generic.png';
  static const String _chiliJalapenoIconAsset =
      'assets/icons/wizard/ic_chili_jalapeno.png';
  static const String _chiliSerranoIconAsset =
      'assets/icons/wizard/ic_chili_serrano.png';
  static const String _chiliPoblanoAnchoIconAsset =
      'assets/icons/wizard/ic_chili_poblano_ancho.png';
  static const String _chiliChilacaPasillaIconAsset =
      'assets/icons/wizard/ic_chili_chilaca_pasilla.png';
  static const String _chiliGuajilloMirasolIconAsset =
      'assets/icons/wizard/ic_chili_guajillo_mirasol.png';
  static const String _chiliArbolPuyaIconAsset =
      'assets/icons/wizard/ic_chili_arbol_puya.png';
  static const String _chiliHabaneroIconAsset =
      'assets/icons/wizard/ic_chili_habanero.png';
  static const String _chiliBellPepperIconAsset =
      'assets/icons/wizard/ic_chili_bell_pepper.png';

  static const String _eggplantIconAsset =
      'assets/icons/wizard/ic_eggplant.png';

  // Generic uses the mother-crop eggplant icon.
  static const String _eggplantGenericIconAsset =
      'assets/icons/wizard/ic_eggplant.png';

  static const String _eggplantItalianBlackIconAsset =
      'assets/icons/wizard/ic_eggplant_italian_black.png';
  static const String _eggplantLongPurpleIconAsset =
      'assets/icons/wizard/ic_eggplant_long_purple.png';
  static const String _eggplantOvalRoundIconAsset =
      'assets/icons/wizard/ic_eggplant_oval_round.png';
  static const String _eggplantStripedIconAsset =
      'assets/icons/wizard/ic_eggplant_striped.png';
  static const String _eggplantWhiteIconAsset =
      'assets/icons/wizard/ic_eggplant_white.png';

  static const String _squashIconAsset =
      'assets/icons/wizard/ic_squash_generic.png';
  static const String _squashZucchiniIconAsset =
      'assets/icons/wizard/ic_squash_italian_zucchini.png';
  static const String _squashCriollaIconAsset =
      'assets/icons/wizard/ic_squash_criolla_huicha.png';
  static const String _squashRoundIconAsset =
      'assets/icons/wizard/ic_squash_round_bola.png';
  static const String _squashCastillaIconAsset =
      'assets/icons/wizard/ic_squash_castilla.png';
  static const String _squashButternutIconAsset =
      'assets/icons/wizard/ic_squash_butternut_buchona.png';
  static const String _squashChilacayoteIconAsset =
      'assets/icons/wizard/ic_squash_chilacayote.png';
  static const String _squashPipianIconAsset =
      'assets/icons/wizard/ic_squash_pipian_pepita.png';

  static const String _lettuceIconAsset =
      'assets/icons/wizard/ic_lettuce_generic.png';
  static const String _lettuceRomaineIconAsset =
      'assets/icons/wizard/ic_lettuce_romaine.png';
  static const String _lettuceMiniRomaineIconAsset =
      'assets/icons/wizard/ic_lettuce_mini_romaine.png';
  static const String _lettuceIcebergIconAsset =
      'assets/icons/wizard/ic_lettuce_iceberg.png';
  static const String _lettuceButterheadIconAsset =
      'assets/icons/wizard/ic_lettuce_butterhead.png';
  static const String _lettuceLooseLeafIconAsset =
      'assets/icons/wizard/ic_lettuce_loose_leaf.png';
  static const String _spinachIconAsset =
      'assets/icons/wizard/ic_spinach.png';
  static const String _spinachGenericIconAsset =
      'assets/icons/wizard/ic_spinach_generic.png';
  static const String _spinachSavoySummerIconAsset =
      'assets/icons/wizard/ic_spinach_savoy_summer.png';
  static const String _spinachSavoyWinterIconAsset =
      'assets/icons/wizard/ic_spinach_savoy_winter.png';
  static const String _spinachSmoothBabyIconAsset =
      'assets/icons/wizard/ic_spinach_smooth_baby.png';
  static const String _spinachOrientalBunchingIconAsset =
      'assets/icons/wizard/ic_spinach_oriental_bunching.png';
  static const String _spinachProcessingIconAsset =
      'assets/icons/wizard/ic_spinach_processing.png';
  static const String _onionIconAsset =
      'assets/icons/wizard/ic_onion_generic.png';
  static const String _onionGenericIconAsset =
      'assets/icons/wizard/ic_onion_generic.png';
  static const String _onionWhiteIconAsset =
      'assets/icons/wizard/ic_onion_white.png';
  static const String _onionYellowIconAsset =
      'assets/icons/wizard/ic_onion_yellow.png';
  static const String _onionPurpleIconAsset =
      'assets/icons/wizard/ic_onion_purple.png';
  static const String _onionTransitionIconAsset =
      'assets/icons/wizard/ic_onion_transition.png';
  static const String _onionCambrayIconAsset =
      'assets/icons/wizard/ic_onion_cambray.png';
  // Icono del cultivo madre Ajo (sin variedad/perfil). AG-GEN usa el generico.
  static const String _garlicIconAsset =
      'assets/icons/wizard/ic_garlic.png';
  static const String _garlicGenericIconAsset =
      'assets/icons/wizard/ic_garlic_generic.png';
  static const String _garlicWhiteIconAsset =
      'assets/icons/wizard/ic_garlic_white.png';
  static const String _garlicJaspeadoIconAsset =
      'assets/icons/wizard/ic_garlic_jaspeado.png';
  static const String _garlicPurpleIconAsset =
      'assets/icons/wizard/ic_garlic_purple.png';
  static const String _garlicCreoleIconAsset =
      'assets/icons/wizard/ic_garlic_criollo.png';
  static const String _garlicChineseIconAsset =
      'assets/icons/wizard/ic_garlic_chinese_korean.png';

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

    final visibleDetailLabel = _genericDetailLabel(
      cropId: cropId,
      isGenericSelection: isGenericSelection,
      fallback: detailLabel,
    );

    final headlineLabel =
        visibleDetailLabel == null || visibleDetailLabel.isEmpty
        ? cropDisplayName
        : '$cropDisplayName · $visibleDetailLabel';

    final runtimeLabel =
        visibleDetailLabel == null || visibleDetailLabel.isEmpty
        ? cropDisplayName
        : '$cropDisplayName ($visibleDetailLabel)';

    final displayHeadlineLabel = _genericHeadlineLabel(
      cropId: cropId,
      cropDisplayName: cropDisplayName,
      isGenericSelection: isGenericSelection,
      fallback: headlineLabel,
    );

    return CropPresentationData(
      hasConfiguredCrop: true,
      isFallowMode: false,
      isGenericSelection: isGenericSelection,
      cropId: cropId,
      cropDisplayName: cropDisplayName,
      varietyLabel: varietyLabel,
      headlineLabel: displayHeadlineLabel,
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

  static String? _genericDetailLabel({
    required String cropId,
    required bool isGenericSelection,
    required String? fallback,
  }) {
    if (!isGenericSelection) return fallback;
    if (cropId == CropCatalog.squashCropId) return 'Calabaza genérica';
    if (cropId == CropCatalog.lettuceCropId) return 'Lechuga genérica';
    if (cropId == CropCatalog.spinachCropId) return 'Espinaca generica';
    if (cropId == CropCatalog.garlicCropId) return 'Ajo generico';
    if (cropId == CropCatalog.onionCropId) return 'Cebolla genérica';
    return fallback;
  }

  static String _genericHeadlineLabel({
    required String cropId,
    required String cropDisplayName,
    required bool isGenericSelection,
    required String fallback,
  }) {
    if (!isGenericSelection) return fallback;
    if (cropId == CropCatalog.squashCropId) {
      return '$cropDisplayName - Calabaza genérica';
    }
    if (cropId == CropCatalog.lettuceCropId) {
      return '$cropDisplayName - Lechuga genérica';
    }
    if (cropId == CropCatalog.spinachCropId) {
      return '$cropDisplayName - Espinaca generica';
    }
    if (cropId == CropCatalog.garlicCropId) {
      return '$cropDisplayName - Ajo generico';
    }
    if (cropId == CropCatalog.onionCropId) {
      return '$cropDisplayName - Cebolla generica';
    }
    return fallback;
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
        cropContext?.profileId ??
        seed?.varietyAlias ??
        seed?.profileId;

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
      case CropCatalog.chiliCropId:
        return _resolveChiliIcon(rawVarietyValue);
      case CropCatalog.eggplantCropId:
        return _resolveEggplantIcon(rawVarietyValue);
      case CropCatalog.squashCropId:
        return _resolveSquashIcon(rawVarietyValue);
      case CropCatalog.lettuceCropId:
        return _resolveLettuceIcon(rawVarietyValue);
      case CropCatalog.spinachCropId:
        return _resolveSpinachIcon(rawVarietyValue);
      case CropCatalog.onionCropId:
        return _resolveOnionIcon(rawVarietyValue);
      case CropCatalog.garlicCropId:
        return _resolveGarlicIcon(rawVarietyValue);
      case CropCatalog.appleTreeCropId:
        // El manzano guarda la variedad/perfil en `profileId` (AP-01..AP-05),
        // no en varietyId. Tras normalizar, `varietyAlias` puede traer una
        // etiqueta legible (p. ej. "AP-01 - Golden") que NO mapea a icono y
        // tapaba al profileId en la cadena `varietyId ?? varietyAlias ??
        // profileId`, cayendo al icono neutro. Por eso aquí priorizamos
        // profileId para el icono de variedad.
        return _resolveAppleTreeIcon(
          cropContext?.profileId ?? rawVarietyValue ?? seed?.profileId,
        );
      default:
        return _genericPlantIconAsset;
    }
  }

  /// Ícono del manzano por perfil AP. Sin perfil claro → ícono del cultivo
  /// (`ic_apple_tree.png`); AP-SKIP/genérico → neutro (`ic_apple_tree_generic`).
  static String _resolveAppleTreeIcon(String? rawVarietyValue) {
    final raw = (rawVarietyValue ?? '').trim();
    if (raw.isEmpty) return AppleTreeAssets.cropIcon;
    return appleTreeProfileIcon(raw);
  }

  static String _resolveSpinachIcon(String? rawVarietyValue) {
    final raw = (rawVarietyValue ?? '').trim();
    if (raw.isEmpty) return _spinachIconAsset;

    final canonical = resolveCanonicalSpinachProfileId(raw);
    switch (canonical) {
      case kSpGen:
        return _spinachGenericIconAsset;
      case kSp01:
        return _spinachSavoySummerIconAsset;
      case kSp02:
        return _spinachSavoyWinterIconAsset;
      case kSp03:
        return _spinachSmoothBabyIconAsset;
      case kSp04:
        return _spinachOrientalBunchingIconAsset;
      case kSp05:
        return _spinachProcessingIconAsset;
    }

    final variety = CropCatalog.varietyByAny(CropCatalog.spinachCropId, raw);
    switch (variety?.id) {
      case 'spinach_generic':
        return _spinachGenericIconAsset;
      case 'spinach_savoy_summer':
        return _spinachSavoySummerIconAsset;
      case 'spinach_savoy_winter':
        return _spinachSavoyWinterIconAsset;
      case 'spinach_smooth_baby':
        return _spinachSmoothBabyIconAsset;
      case 'spinach_oriental_bunching':
        return _spinachOrientalBunchingIconAsset;
      case 'spinach_processing':
        return _spinachProcessingIconAsset;
    }

    return _spinachIconAsset;
  }

  static String _resolveOnionIcon(String? rawVarietyValue) {
    final raw = (rawVarietyValue ?? '').trim();
    if (raw.isEmpty) return _onionIconAsset;

    final canonical = resolveCanonicalOnionProfileId(raw);
    switch (canonical) {
      case kOnGen:
        return _onionGenericIconAsset;
      case kOn01:
        return _onionWhiteIconAsset;
      case kOn02:
        return _onionYellowIconAsset;
      case kOn03:
        return _onionPurpleIconAsset;
      case kOn04:
        return _onionTransitionIconAsset;
      case kOn05:
        return _onionCambrayIconAsset;
    }

    final variety = CropCatalog.varietyByAny(CropCatalog.onionCropId, raw);
    switch (variety?.id) {
      case 'onion_generic':
        return _onionGenericIconAsset;
      case 'onion_white':
        return _onionWhiteIconAsset;
      case 'onion_yellow':
        return _onionYellowIconAsset;
      case 'onion_purple':
        return _onionPurpleIconAsset;
      case 'onion_transition':
        return _onionTransitionIconAsset;
      case 'onion_cambray':
        return _onionCambrayIconAsset;
    }

    return _onionIconAsset;
  }

  static String _resolveGarlicIcon(String? rawVarietyValue) {
    final raw = (rawVarietyValue ?? '').trim();
    if (raw.isEmpty) return _garlicIconAsset;

    final canonical = resolveCanonicalGarlicProfileId(raw);
    switch (canonical) {
      case kAgGen:
        return _garlicGenericIconAsset;
      case kAg01:
        return _garlicWhiteIconAsset;
      case kAg02:
        return _garlicJaspeadoIconAsset;
      case kAg03:
        return _garlicPurpleIconAsset;
      case kAg04:
        return _garlicCreoleIconAsset;
      case kAg05:
        return _garlicChineseIconAsset;
    }

    final variety = CropCatalog.varietyByAny(CropCatalog.garlicCropId, raw);
    switch (variety?.id) {
      case 'garlic_generic':
        return _garlicGenericIconAsset;
      case 'garlic_white_pearl':
      case 'garlic_orion':
      case 'garlic_san_marqueno':
        return _garlicWhiteIconAsset;
      case 'garlic_jaspeado_calera':
      case 'garlic_cezac_06':
      case 'garlic_barretero':
        return _garlicJaspeadoIconAsset;
      case 'garlic_purple':
        return _garlicPurpleIconAsset;
      case 'garlic_criollo_regional':
        return _garlicCreoleIconAsset;
      case 'garlic_chinese_korean':
        return _garlicChineseIconAsset;
    }

    return _garlicIconAsset;
  }

  static String _resolveLettuceIcon(String? rawVarietyValue) {
    final raw = (rawVarietyValue ?? '').trim();
    if (raw.isEmpty) return _lettuceIconAsset;

    final canonical = resolveCanonicalLettuceProfileId(raw);
    switch (canonical) {
      case kLeGen:
        return _lettuceIconAsset;
      case kLe01:
        return _lettuceRomaineIconAsset;
      case kLe02:
        return _lettuceMiniRomaineIconAsset;
      case kLe03:
        return _lettuceIcebergIconAsset;
      case kLe04:
        return _lettuceButterheadIconAsset;
      case kLe05:
        return _lettuceLooseLeafIconAsset;
    }

    final variety = CropCatalog.varietyByAny(CropCatalog.lettuceCropId, raw);
    switch (variety?.id) {
      case 'lettuce_romaine':
        return _lettuceRomaineIconAsset;
      case 'lettuce_mini_romaine':
        return _lettuceMiniRomaineIconAsset;
      case 'lettuce_iceberg':
        return _lettuceIcebergIconAsset;
      case 'lettuce_butterhead':
        return _lettuceButterheadIconAsset;
      case 'lettuce_looseleaf':
        return _lettuceLooseLeafIconAsset;
      case 'lettuce_generic':
        return _lettuceIconAsset;
    }

    return _lettuceIconAsset;
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

  static String _resolveChiliIcon(String? rawVarietyValue) {
    final raw = (rawVarietyValue ?? '').trim();
    if (raw.isEmpty) return _chiliIconAsset;

    final canonical = resolveCanonicalChiliProfileId(raw);
    switch (canonical) {
      case kCh01:
        return _chiliJalapenoIconAsset;
      case kCh02:
        return _chiliSerranoIconAsset;
      case kCh03:
        return _chiliPoblanoAnchoIconAsset;
      case kCh04:
        return _chiliChilacaPasillaIconAsset;
      case kCh05:
        return _chiliGuajilloMirasolIconAsset;
      case kCh06:
        return _chiliArbolPuyaIconAsset;
      case kCh07:
        return _chiliHabaneroIconAsset;
      case kCh08:
        return _chiliBellPepperIconAsset;
      case kChGen:
        return _chiliGenericIconAsset;
    }

    final variety = CropCatalog.varietyByAny(CropCatalog.chiliCropId, raw);
    switch (variety?.id) {
      case 'chili_jalapeno':
        return _chiliJalapenoIconAsset;
      case 'chili_serrano':
        return _chiliSerranoIconAsset;
      case 'chili_poblano_ancho':
        return _chiliPoblanoAnchoIconAsset;
      case 'chili_chilaca_pasilla':
        return _chiliChilacaPasillaIconAsset;
      case 'chili_guajillo_mirasol':
        return _chiliGuajilloMirasolIconAsset;
      case 'chili_arbol_puya':
        return _chiliArbolPuyaIconAsset;
      case 'chili_habanero':
        return _chiliHabaneroIconAsset;
      case 'chili_bell_pepper':
        return _chiliBellPepperIconAsset;
      case 'chili_generic':
        return _chiliGenericIconAsset;
    }

    final normalized = raw.toLowerCase();
    if (normalized.contains('jalapeno') || normalized.contains('chipotle')) {
      return _chiliJalapenoIconAsset;
    }
    if (normalized.contains('serrano')) return _chiliSerranoIconAsset;
    if (normalized.contains('poblano') ||
        normalized.contains('ancho') ||
        normalized.contains('mulato')) {
      return _chiliPoblanoAnchoIconAsset;
    }
    if (normalized.contains('chilaca') || normalized.contains('pasilla')) {
      return _chiliChilacaPasillaIconAsset;
    }
    if (normalized.contains('guajillo') || normalized.contains('mirasol')) {
      return _chiliGuajilloMirasolIconAsset;
    }
    if (normalized.contains('arbol') || normalized.contains('puya')) {
      return _chiliArbolPuyaIconAsset;
    }
    if (normalized.contains('habanero')) return _chiliHabaneroIconAsset;
    if (normalized.contains('morron') ||
        normalized.contains('gordo') ||
        normalized.contains('pimiento') ||
        normalized.contains('bell')) {
      return _chiliBellPepperIconAsset;
    }
    if (normalized.contains('gen') || normalized.contains('otro')) {
      return _chiliGenericIconAsset;
    }
    return _chiliIconAsset;
  }

  static String _resolveEggplantIcon(String? rawVarietyValue) {
    final raw = (rawVarietyValue ?? '').trim();
    if (raw.isEmpty) return _eggplantIconAsset;

    final variety = CropCatalog.varietyByAny(CropCatalog.eggplantCropId, raw);
    switch (variety?.id) {
      case 'eggplant_long_purple':
        return _eggplantLongPurpleIconAsset;
      case 'eggplant_italian_purple':
        return _eggplantItalianBlackIconAsset;
      case 'eggplant_oval_round':
        return _eggplantOvalRoundIconAsset;
      case 'eggplant_striped':
        return _eggplantStripedIconAsset;
      case 'eggplant_white':
        return _eggplantWhiteIconAsset;
      case 'eggplant_generic':
        return _eggplantGenericIconAsset;
    }

    final normalized = raw.toLowerCase();

    if (normalized.contains('italiana') ||
        normalized.contains('italian') ||
        normalized.contains('clasica') ||
        normalized.contains('clásica') ||
        normalized.contains('black beauty')) {
      return _eggplantItalianBlackIconAsset;
    }

    final canonical = resolveCanonicalEggplantProfileId(raw);
    switch (canonical) {
      case kBe01:
        return _eggplantLongPurpleIconAsset;
      case kBe02:
        return _eggplantOvalRoundIconAsset;
      case kBe03:
        return _eggplantStripedIconAsset;
      case kBe04:
        return _eggplantWhiteIconAsset;
      case kBeGen:
        return _eggplantGenericIconAsset;
    }

    if (normalized.contains('larga') ||
        normalized.contains('semilarga') ||
        normalized.contains('barcelona') ||
        normalized.contains('dark night') ||
        normalized.contains('orestia') ||
        normalized.contains('napoli') ||
        normalized.contains('nápoli') ||
        normalized.contains('oriental') ||
        normalized.contains('china')) {
      return _eggplantLongPurpleIconAsset;
    }

    if (normalized.contains('oval') ||
        normalized.contains('bola') ||
        normalized.contains('americana') ||
        normalized.contains('morada grande') ||
        normalized.contains('night shadow') ||
        normalized.contains('emma')) {
      return _eggplantOvalRoundIconAsset;
    }

    if (normalized.contains('rayada') ||
        normalized.contains('listada') ||
        normalized.contains('jaspeada') ||
        normalized.contains('graffiti') ||
        normalized.contains('grafiti')) {
      return _eggplantStripedIconAsset;
    }

    if (normalized.contains('blanca') || normalized.contains('white')) {
      return _eggplantWhiteIconAsset;
    }

    if (normalized.contains('gen') ||
        normalized.contains('otra') ||
        normalized.contains('no se') ||
        normalized.contains('no sé')) {
      return _eggplantGenericIconAsset;
    }

    return _eggplantIconAsset;
  }

  static String _resolveSquashIcon(String? rawVarietyValue) {
    final raw = (rawVarietyValue ?? '').trim();
    if (raw.isEmpty) return _squashIconAsset;

    final canonical = resolveCanonicalSquashProfileId(raw);
    switch (canonical) {
      case kCaGen:
        return _squashIconAsset;
      case kCa01:
        return _squashZucchiniIconAsset;
      case kCa02:
        return _squashCriollaIconAsset;
      case kCa03:
        return _squashRoundIconAsset;
      case kCa04:
        return _squashCastillaIconAsset;
      case kCa05:
        return _squashButternutIconAsset;
      case kCa06:
        return _squashChilacayoteIconAsset;
      case kCa07:
        return _squashPipianIconAsset;
    }

    final variety = CropCatalog.varietyByAny(CropCatalog.squashCropId, raw);
    switch (variety?.id) {
      case 'squash_zucchini':
        return _squashZucchiniIconAsset;
      case 'squash_criolla':
        return _squashCriollaIconAsset;
      case 'squash_round':
        return _squashRoundIconAsset;
      case 'squash_castilla':
        return _squashCastillaIconAsset;
      case 'squash_butternut':
        return _squashButternutIconAsset;
      case 'squash_chilacayote':
        return _squashChilacayoteIconAsset;
      case 'squash_pipian':
        return _squashPipianIconAsset;
      case null:
        break;
      default:
        return _squashIconAsset;
    }

    return _squashIconAsset;
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
