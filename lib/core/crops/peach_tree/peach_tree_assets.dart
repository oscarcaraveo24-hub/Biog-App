import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Rutas definitivas de assets del Durazno / Duraznero.
///
/// No reutiliza assets de manzano/pera como definitivos. Si en el futuro se
/// reemplaza el arte, este archivo sigue siendo el unico punto de cableado.
class PeachTreeAssets {
  const PeachTreeAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/peach';

  static const String iconTree = '$_wizardDir/ic_peach_tree.png';
  static const String iconGeneric = '$_wizardDir/ic_peach_tree_generic.png';
  static const String iconCriolloRegional =
      '$_wizardDir/ic_peach_criollo_regional.png';
  static const String iconTempranoBajoFrio =
      '$_wizardDir/ic_peach_temprano_bajo_frio.png';
  static const String iconAmarilloComercial =
      '$_wizardDir/ic_peach_amarillo_comercial.png';
  static const String iconBlancoDulce =
      '$_wizardDir/ic_peach_blanco_dulce.png';
  static const String iconTardioIndustria =
      '$_wizardDir/ic_peach_tardio_industria.png';

  static const String stagePlantingTransplant =
      '$_stageDir/peach_stage_planting_transplant.png';
  static const String stageRootEstablishment =
      '$_stageDir/peach_stage_root_establishment.png';
  static const String stageJuvenileVegetative =
      '$_stageDir/peach_stage_juvenile_vegetative.png';
  static const String stageDormancy =
      '$_stageDir/peach_stage_dormancy.png';
  static const String stageBudbreak =
      '$_stageDir/peach_stage_budbreak.png';
  static const String stageVegetativeGrowth =
      '$_stageDir/peach_stage_vegetative_growth.png';
  static const String stageFlowering =
      '$_stageDir/peach_stage_flowering.png';
  static const String stageFruitSet =
      '$_stageDir/peach_stage_fruit_set.png';
  static const String stageFruitFill =
      '$_stageDir/peach_stage_fruit_fill.png';
  static const String stageHarvestMaturity =
      '$_stageDir/peach_stage_harvest_maturity.png';
  static const String stagePostHarvest =
      '$_stageDir/peach_stage_post_harvest.png';
  static const String stageUnknown =
      '$_stageDir/peach_stage_unknown.png';

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

/// Imagen fenologica para una etapa del durazno.
String? peachTreeStageImage(String? phenologyStageId) {
  final id = normalizeTreeStageId(phenologyStageId);
  return PeachTreeAssets._stageImages[id];
}

/// Imagen fenologica con fallback neutro garantizado (nunca nulo).
String peachTreeStageImageOrNeutral(String? phenologyStageId) =>
    peachTreeStageImage(phenologyStageId) ?? PeachTreeAssets.stageUnknown;

/// Icono de wizard del perfil DZ (acepta id de perfil o alias del catalogo).
String peachTreeProfileIcon(String? profileId) {
  final normalized = profileId?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return PeachTreeAssets.cropIcon;
  }

  for (final entry in peachTreeProfileEntries) {
    final matchesId = entry.id == normalized;
    final matchesAlias = entry.aliases.any(
      (alias) => alias.trim().toLowerCase() == normalized,
    );
    if (matchesId || matchesAlias) {
      switch (entry.id) {
        case kDzSkip:
          return PeachTreeAssets.iconGeneric;
        case kDz01CriolloRegional:
          return PeachTreeAssets.iconCriolloRegional;
        case kDz02TempranoBajoFrio:
          return PeachTreeAssets.iconTempranoBajoFrio;
        case kDz03AmarilloComercial:
          return PeachTreeAssets.iconAmarilloComercial;
        case kDz04BlancoDulce:
          return PeachTreeAssets.iconBlancoDulce;
        case kDz05TardioIndustria:
          return PeachTreeAssets.iconTardioIndustria;
      }
    }
  }
  return PeachTreeAssets.iconGeneric;
}

/// Icono neutro del durazno (perfil general / etapa desconocida).
String peachTreeNeutralIcon() => PeachTreeAssets.neutralIcon;
