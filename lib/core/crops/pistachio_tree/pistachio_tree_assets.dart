import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Rutas definitivas de assets del Pistache (doc 01).
///
/// Arte cableado: iconos de wizard en `assets/icons/wizard/ic_pistachio_*` y
/// etapas en `assets/seeds/pistachio/pistachio_stage_*`. Si algun PNG faltara,
/// el render puede caer al fallback seguro de arbol generico via los
/// `errorBuilder` existentes; el flujo principal ya usa los assets reales.
///
/// No reutiliza assets de manzano/pera/durazno/nogal como definitivos.
class PistachioTreeAssets {
  const PistachioTreeAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/pistachio';

  static const String iconTree = '$_wizardDir/ic_pistachio_tree.png';
  static const String iconGeneric =
      '$_wizardDir/ic_pistachio_tree_generic.png';
  static const String iconKerman = '$_wizardDir/ic_pistachio_kerman.png';
  static const String iconGoldenHills =
      '$_wizardDir/ic_pistachio_golden_hills.png';
  static const String iconLostHills =
      '$_wizardDir/ic_pistachio_lost_hills.png';
  static const String iconSirora = '$_wizardDir/ic_pistachio_sirora.png';
  static const String iconMediterraneanLowChill =
      '$_wizardDir/ic_pistachio_mediterranean_low_chill.png';

  static const String stagePlantingTransplant =
      '$_stageDir/pistachio_stage_planting_transplant.png';
  static const String stageRootEstablishment =
      '$_stageDir/pistachio_stage_root_establishment.png';
  static const String stageJuvenileVegetative =
      '$_stageDir/pistachio_stage_juvenile_vegetative.png';
  static const String stageDormancy =
      '$_stageDir/pistachio_stage_dormancy.png';
  static const String stageBudbreak =
      '$_stageDir/pistachio_stage_budbreak.png';
  static const String stageVegetativeGrowth =
      '$_stageDir/pistachio_stage_vegetative_growth.png';
  static const String stageFlowering =
      '$_stageDir/pistachio_stage_flowering.png';
  static const String stageFruitSet =
      '$_stageDir/pistachio_stage_fruit_set.png';
  static const String stageFruitFill =
      '$_stageDir/pistachio_stage_fruit_fill.png';
  static const String stageHarvestMaturity =
      '$_stageDir/pistachio_stage_harvest_maturity.png';
  static const String stagePostHarvest =
      '$_stageDir/pistachio_stage_post_harvest.png';
  static const String stageUnknown =
      '$_stageDir/pistachio_stage_unknown.png';

  /// Fallback neutro de arbol generico si algun PNG faltara.
  static const String genericTreeFallback = '$_wizardDir/ic_tree.png';

  /// Icono general del cultivo; PS-SKIP usa [iconGeneric].
  static const String cropIcon = iconTree;
  static const String neutralIcon = iconGeneric;

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

/// Imagen fenologica para una etapa del pistache.
String? pistachioTreeStageImage(String? phenologyStageId) {
  final id = normalizeTreeStageId(phenologyStageId);
  return PistachioTreeAssets._stageImages[id];
}

/// Imagen fenologica con fallback neutro garantizado (nunca nulo).
String pistachioTreeStageImageOrNeutral(String? phenologyStageId) =>
    pistachioTreeStageImage(phenologyStageId) ??
    PistachioTreeAssets.stageUnknown;

/// Icono de wizard del perfil PS (acepta id de perfil o alias del catalogo).
String pistachioTreeProfileIcon(String? profileId) {
  final normalized = profileId?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return PistachioTreeAssets.cropIcon;
  }

  for (final entry in pistachioTreeProfileEntries) {
    final matchesId = entry.id == normalized;
    final matchesAlias = entry.aliases.any(
      (alias) => alias.trim().toLowerCase() == normalized,
    );
    if (matchesId || matchesAlias) {
      switch (entry.id) {
        case kPsSkip:
          return PistachioTreeAssets.iconGeneric;
        case kPs01KermanPeters:
          return PistachioTreeAssets.iconKerman;
        case kPs02GoldenHillsRandy:
          return PistachioTreeAssets.iconGoldenHills;
        case kPs03LostHillsRandy:
          return PistachioTreeAssets.iconLostHills;
        case kPs04SiroraCompatible:
          return PistachioTreeAssets.iconSirora;
        case kPs05LarnakaMateurLowChill:
          return PistachioTreeAssets.iconMediterraneanLowChill;
      }
    }
  }
  return PistachioTreeAssets.cropIcon;
}

/// Icono neutro del pistache (perfil general / etapa desconocida).
String pistachioTreeNeutralIcon() => PistachioTreeAssets.neutralIcon;
