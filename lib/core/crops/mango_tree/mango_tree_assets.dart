import 'package:bio_g/core/crops/mango_tree/mango_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Assets finales del Mango (doc 01, seccion visual).
///
/// El mango usa arte propio: iconos de perfil en `assets/icons/wizard/` y
/// etapas fenologicas en `assets/seeds/mango/`. No depende de placeholders
/// genericos de arbol.
///
/// Decision de mango: `dormancy` representa reposo funcional / preparacion /
/// induccion, no arbol caducifolio sin hojas.
class MangoTreeAssets {
  const MangoTreeAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/mango';

  static const String iconTree = '$_wizardDir/ic_mango_tree.png';
  static const String iconGeneric = iconTree;
  static const String iconAtaulfoManila =
      '$_wizardDir/ic_mango_ataulfo_manila.png';
  static const String iconTommyAtkins =
      '$_wizardDir/ic_mango_tommy_atkins.png';
  static const String iconKent = '$_wizardDir/ic_mango_kent.png';
  static const String iconKeitt = '$_wizardDir/ic_mango_keitt.png';
  static const String iconCriolloRegional =
      '$_wizardDir/ic_mango_criollo_regional.png';

  /// Nombre historico conservado para callers/tests; ahora apunta a Mango real.
  static const String genericTreeFallback = iconTree;

  /// Icono general del cultivo; MG-SKIP usa [iconGeneric].
  static const String cropIcon = iconTree;
  static const String neutralIcon = iconGeneric;

  static const String stagePlantingTransplant =
      '$_stageDir/mango_stage_planting_transplant.png';
  static const String stageRootEstablishment =
      '$_stageDir/mango_stage_root_establishment.png';
  static const String stageJuvenileVegetative =
      '$_stageDir/mango_stage_juvenile_vegetative.png';
  static const String stageDormancy = '$_stageDir/mango_stage_dormancy.png';
  static const String stageBudbreak = '$_stageDir/mango_stage_budbreak.png';
  static const String stageVegetativeGrowth =
      '$_stageDir/mango_stage_vegetative_growth.png';
  static const String stageFlowering = '$_stageDir/mango_stage_flowering.png';
  static const String stageFruitSet = '$_stageDir/mango_stage_fruit_set.png';
  static const String stageFruitFill = '$_stageDir/mango_stage_fruit_fill.png';
  static const String stageHarvestMaturity =
      '$_stageDir/mango_stage_harvest_maturity.png';
  static const String stagePostHarvest =
      '$_stageDir/mango_stage_post_harvest.png';
  static const String stageUnknown = '$_stageDir/mango_stage_unknown.png';

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

  static const Map<String, String> _profileIcons = <String, String>{
    kMgSkip: cropIcon,
    kMg01AtaulfoManila: iconAtaulfoManila,
    kMg02TommyAtkins: iconTommyAtkins,
    kMg03Kent: iconKent,
    kMg04Keitt: iconKeitt,
    kMg05CriolloRegional: iconCriolloRegional,
  };
}

/// Imagen fenologica para una etapa del mango.
String? mangoTreeStageImage(String? phenologyStageId) {
  final id = normalizeTreeStageId(phenologyStageId);
  return MangoTreeAssets._stageImages[id];
}

/// Imagen fenologica con fallback neutro garantizado (nunca nulo).
String mangoTreeStageImageOrNeutral(String? phenologyStageId) =>
    mangoTreeStageImage(phenologyStageId) ?? MangoTreeAssets.stageUnknown;

/// Icono de wizard del perfil MG (acepta id de perfil o alias del catalogo).
///
String mangoTreeProfileIcon(String? profileId) {
  final normalized = profileId?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return MangoTreeAssets.cropIcon;
  }

  final directMatch = MangoTreeAssets._profileIcons[normalized];
  if (directMatch != null) {
    return directMatch;
  }

  for (final entry in mangoTreeProfileEntries) {
    final matchesAlias = entry.aliases.any(
      (alias) => alias.trim().toLowerCase() == normalized,
    );
    if (matchesAlias) {
      return MangoTreeAssets._profileIcons[entry.id] ??
          MangoTreeAssets.cropIcon;
    }
  }
  return MangoTreeAssets.cropIcon;
}

/// Icono neutro del mango (perfil general / etapa desconocida).
String mangoTreeNeutralIcon() => MangoTreeAssets.neutralIcon;
