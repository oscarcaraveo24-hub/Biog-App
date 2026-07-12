import 'package:bio_g/core/crops/orange_tree/orange_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Assets finales del Naranjo (doc 01 sec. 13).
///
/// Arte cableado: iconos de wizard en `assets/icons/wizard/ic_orange_*` y
/// etapas en `assets/seeds/orange/orange_stage_*`. Si algun PNG faltara, el
/// render puede caer al fallback seguro de arbol generico via los `errorBuilder`
/// existentes; el flujo principal ya usa los assets reales.
///
/// Decision citrica: `dormancy` NO usa arbol pelon. El naranjo es siempreverde;
/// en reposo relativo conserva hoja.
class OrangeTreeAssets {
  const OrangeTreeAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/orange';

  static const String iconTree = '$_wizardDir/ic_orange_tree.png';
  static const String iconGeneric = '$_wizardDir/ic_orange_tree.png';
  static const String iconValencia = '$_wizardDir/ic_orange_valencia.png';
  static const String iconNavel = '$_wizardDir/ic_orange_navel.png';
  static const String iconTemprano = '$_wizardDir/ic_orange_temprano.png';
  static const String iconCriolloRegional =
      '$_wizardDir/ic_orange_criollo_regional.png';
  static const String iconTropicalCalido =
      '$_wizardDir/ic_orange_tropical_calido.png';

  /// Fallback neutro de arbol generico si algun PNG faltara.
  static const String genericTreeFallback = '$_wizardDir/ic_tree.png';

  /// Icono general del cultivo; OR-SKIP usa [iconGeneric].
  static const String cropIcon = iconTree;
  static const String neutralIcon = iconGeneric;

  static const String stagePlantingTransplant =
      '$_stageDir/orange_stage_planting_transplant.png';
  static const String stageRootEstablishment =
      '$_stageDir/orange_stage_root_establishment.png';
  static const String stageJuvenileVegetative =
      '$_stageDir/orange_stage_juvenile_vegetative.png';
  static const String stageDormancy = '$_stageDir/orange_stage_dormancy.png';
  static const String stageBudbreak = '$_stageDir/orange_stage_budbreak.png';
  static const String stageVegetativeGrowth =
      '$_stageDir/orange_stage_vegetative_growth.png';
  static const String stageFlowering = '$_stageDir/orange_stage_flowering.png';
  static const String stageFruitSet = '$_stageDir/orange_stage_fruit_set.png';
  static const String stageFruitFill = '$_stageDir/orange_stage_fruit_fill.png';
  static const String stageHarvestMaturity =
      '$_stageDir/orange_stage_harvest_maturity.png';
  static const String stagePostHarvest =
      '$_stageDir/orange_stage_post_harvest.png';
  static const String stageUnknown = '$_stageDir/orange_stage_unknown.png';

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

/// Imagen fenologica para una etapa del naranjo.
String? orangeTreeStageImage(String? phenologyStageId) {
  final id = normalizeTreeStageId(phenologyStageId);
  return OrangeTreeAssets._stageImages[id];
}

/// Imagen fenologica con fallback neutro garantizado (nunca nulo).
String orangeTreeStageImageOrNeutral(String? phenologyStageId) =>
    orangeTreeStageImage(phenologyStageId) ?? OrangeTreeAssets.stageUnknown;

/// Icono de wizard del perfil OR (acepta id de perfil o alias del catalogo).
String orangeTreeProfileIcon(String? profileId) {
  final normalized = profileId?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return OrangeTreeAssets.cropIcon;
  }

  for (final entry in orangeTreeProfileEntries) {
    final matchesId = entry.id == normalized;
    final matchesAlias = entry.aliases.any(
      (alias) => alias.trim().toLowerCase() == normalized,
    );
    if (matchesId || matchesAlias) {
      switch (entry.id) {
        case kOrSkip:
          return OrangeTreeAssets.iconGeneric;
        case kOr01Valencia:
          return OrangeTreeAssets.iconValencia;
        case kOr02Navel:
          return OrangeTreeAssets.iconNavel;
        case kOr03Temprano:
          return OrangeTreeAssets.iconTemprano;
        case kOr04CriolloRegional:
          return OrangeTreeAssets.iconCriolloRegional;
        case kOr05TropicalCalido:
          return OrangeTreeAssets.iconTropicalCalido;
      }
    }
  }
  return OrangeTreeAssets.cropIcon;
}

/// Icono neutro del naranjo (perfil general / etapa desconocida).
String orangeTreeNeutralIcon() => OrangeTreeAssets.neutralIcon;
