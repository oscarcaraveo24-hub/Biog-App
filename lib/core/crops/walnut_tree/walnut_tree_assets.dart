import 'package:bio_g/core/crops/walnut_tree/walnut_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Rutas definitivas de assets del Nogal pecanero (doc 01 §14).
///
/// Arte cableado: iconos de wizard en `assets/icons/wizard/ic_walnut_*` y etapas
/// en `assets/seeds/walnut/walnut_stage_*` (ambos directorios declarados en
/// pubspec). Si algun PNG faltara (p. ej. arte aun no entregado), el render cae
/// a un fallback seguro de arbol generico via `WizardAssetIcon.errorBuilder`
/// (`genericTreeFallback` = ic_tree.png); la app NO se rompe.
///
/// No reutiliza assets de manzano/pera/durazno como definitivos.
class WalnutTreeAssets {
  const WalnutTreeAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/walnut';

  static const String iconTree = '$_wizardDir/ic_walnut_tree.png';
  static const String iconWestern = '$_wizardDir/ic_walnut_western.png';
  static const String iconWichita = '$_wizardDir/ic_walnut_wichita.png';
  static const String iconWesternWichita =
      '$_wizardDir/ic_walnut_western_wichita.png';
  static const String iconCriolloRegional =
      '$_wizardDir/ic_walnut_criollo_regional.png';
  static const String iconTemprano = '$_wizardDir/ic_walnut_temprano.png';

  static const String stagePlantingTransplant =
      '$_stageDir/walnut_stage_planting_transplant.png';
  static const String stageRootEstablishment =
      '$_stageDir/walnut_stage_root_establishment.png';
  static const String stageJuvenileVegetative =
      '$_stageDir/walnut_stage_juvenile_vegetative.png';
  static const String stageDormancy = '$_stageDir/walnut_stage_dormancy.png';
  static const String stageBudbreak = '$_stageDir/walnut_stage_budbreak.png';
  static const String stageVegetativeGrowth =
      '$_stageDir/walnut_stage_vegetative_growth.png';
  static const String stageFlowering = '$_stageDir/walnut_stage_flowering.png';
  static const String stageFruitSet = '$_stageDir/walnut_stage_fruit_set.png';
  static const String stageFruitFill = '$_stageDir/walnut_stage_fruit_fill.png';
  static const String stageHarvestMaturity =
      '$_stageDir/walnut_stage_harvest_maturity.png';
  static const String stagePostHarvest =
      '$_stageDir/walnut_stage_post_harvest.png';
  static const String stageUnknown = '$_stageDir/walnut_stage_unknown.png';

  /// Fallback neutro de arbol generico (errorBuilder) si algun PNG faltara.
  /// Garantiza un icono valido en la UI sin romper el render.
  static const String genericTreeFallback = '$_wizardDir/ic_tree.png';

  /// Icono general del nogal: NO hay `ic_walnut_tree_generic.png`. El perfil
  /// general/SKIP usa el icono del cultivo (`ic_walnut_tree.png`), igual que el
  /// patron de los demas arboles.
  static const String cropIcon = iconTree;
  static const String neutralIcon = iconTree;

  static const Map<String, String> _stageImages = <String, String>{
    TreeStageIds.plantingTransplant: stagePlantingTransplant,
    TreeStageIds.rootEstablishment: stageRootEstablishment,
    TreeStageIds.juvenileVegetative: stageJuvenileVegetative,
    TreeStageIds.dormancy: stageDormancy,
    TreeStageIds.budbreak: stageBudbreak,
    TreeStageIds.vegetativeGrowth: stageVegetativeGrowth,
    TreeStageIds.flowering: stageFlowering,
    TreeStageIds.fruitSet: stageFruitSet,
    TreeStageIds.fruitFill: stageFruitFill,
    TreeStageIds.harvestMaturity: stageHarvestMaturity,
    TreeStageIds.postHarvest: stagePostHarvest,
    TreeStageIds.unknown: stageUnknown,
  };
}

/// Imagen fenologica para una etapa del nogal.
String? walnutTreeStageImage(String? phenologyStageId) {
  final id = normalizeTreeStageId(phenologyStageId);
  return WalnutTreeAssets._stageImages[id];
}

/// Imagen fenologica con fallback neutro garantizado (nunca nulo).
String walnutTreeStageImageOrNeutral(String? phenologyStageId) =>
    walnutTreeStageImage(phenologyStageId) ?? WalnutTreeAssets.stageUnknown;

/// Icono de wizard del perfil NG (acepta id de perfil o alias del catalogo).
String walnutTreeProfileIcon(String? profileId) {
  final normalized = profileId?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return WalnutTreeAssets.cropIcon;
  }

  for (final entry in walnutTreeProfileEntries) {
    final matchesId = entry.id == normalized;
    final matchesAlias = entry.aliases.any(
      (alias) => alias.trim().toLowerCase() == normalized,
    );
    if (matchesId || matchesAlias) {
      switch (entry.id) {
        case kNgSkip:
          return WalnutTreeAssets.iconTree;
        case kNg01Western:
          return WalnutTreeAssets.iconWestern;
        case kNg02Wichita:
          return WalnutTreeAssets.iconWichita;
        case kNg03WesternWichita:
          return WalnutTreeAssets.iconWesternWichita;
        case kNg04CriolloRegional:
          return WalnutTreeAssets.iconCriolloRegional;
        case kNg05TempranoPawneeKanza:
          return WalnutTreeAssets.iconTemprano;
      }
    }
  }
  return WalnutTreeAssets.cropIcon;
}

/// Icono neutro del nogal (perfil general / etapa desconocida).
String walnutTreeNeutralIcon() => WalnutTreeAssets.neutralIcon;
