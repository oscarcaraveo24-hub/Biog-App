import 'package:bio_g/core/crops/avocado_tree/avocado_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Assets finales del Aguacate (doc 01 seccion 12).
///
/// Regla visual: el aguacate es siempreverde. `dormancy` representa reposo
/// funcional / preparacion floral, no arbol pelon ni muerto.
class AvocadoTreeAssets {
  const AvocadoTreeAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/avocado';

  // Iconos glossy del wizard por perfil AG.
  static const String iconTree = '$_wizardDir/ic_avocado_tree.png';
  static const String iconGeneric = iconTree;
  static const String iconHass = '$_wizardDir/ic_avocado_hass.png';
  static const String iconMendezCarmen =
      '$_wizardDir/ic_avocado_mendez_carmen.png';
  static const String iconCriolloMexicano =
      '$_wizardDir/ic_avocado_criollo_mexicano.png';
  static const String iconFuertePielVerde =
      '$_wizardDir/ic_avocado_fuerte_piel_verde.png';
  static const String iconAntillanoTropical =
      '$_wizardDir/ic_avocado_antillano_tropical.png';
  static const String iconTardioLambReed =
      '$_wizardDir/ic_avocado_tardio_lamb_reed.png';

  /// Fallback neutro del aguacate.
  static const String genericTreeFallback = iconTree;

  /// Icono general del cultivo; AG-SKIP usa [iconGeneric].
  static const String cropIcon = iconTree;
  static const String neutralIcon = iconGeneric;

  // Etapas fenologicas reales del aguacate.
  static const String stagePlantingTransplant =
      '$_stageDir/avocado_stage_planting_transplant.png';
  static const String stageRootEstablishment =
      '$_stageDir/avocado_stage_root_establishment.png';
  static const String stageJuvenileVegetative =
      '$_stageDir/avocado_stage_juvenile_vegetative.png';
  static const String stageDormancy =
      '$_stageDir/avocado_stage_dormancy.png';
  static const String stageBudbreak =
      '$_stageDir/avocado_stage_budbreak.png';
  static const String stageVegetativeGrowth =
      '$_stageDir/avocado_stage_vegetative_growth.png';
  static const String stageFlowering =
      '$_stageDir/avocado_stage_flowering.png';
  static const String stageFruitSet = '$_stageDir/avocado_stage_fruit_set.png';
  static const String stageFruitFill =
      '$_stageDir/avocado_stage_fruit_fill.png';
  static const String stageHarvestMaturity =
      '$_stageDir/avocado_stage_harvest_maturity.png';
  static const String stagePostHarvest =
      '$_stageDir/avocado_stage_post_harvest.png';
  static const String stageUnknown = '$_stageDir/avocado_stage_unknown.png';

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
    kAgSkip: cropIcon,
    kAg01Hass: iconHass,
    kAg02MendezCarmen: iconMendezCarmen,
    kAg03CriolloMexicano: iconCriolloMexicano,
    kAg04FuertePielVerde: iconFuertePielVerde,
    kAg05AntillanoTropical: iconAntillanoTropical,
    kAg06TardioLambReed: iconTardioLambReed,
  };
}

/// Imagen fenologica para una etapa del aguacate.
String? avocadoTreeStageImage(String? phenologyStageId) {
  final id = normalizeTreeStageId(phenologyStageId);
  return AvocadoTreeAssets._stageImages[id];
}

/// Imagen fenologica con fallback neutro garantizado (nunca nulo).
String avocadoTreeStageImageOrNeutral(String? phenologyStageId) =>
    avocadoTreeStageImage(phenologyStageId) ?? AvocadoTreeAssets.stageUnknown;

/// Icono de wizard del perfil AG (acepta id de perfil o alias del catalogo).
String avocadoTreeProfileIcon(String? profileId) {
  final normalized = profileId?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return AvocadoTreeAssets.cropIcon;
  }

  final directMatch = AvocadoTreeAssets._profileIcons[normalized];
  if (directMatch != null) {
    return directMatch;
  }

  for (final entry in avocadoTreeProfileEntries) {
    final matchesAlias = entry.aliases.any(
      (alias) => alias.trim().toLowerCase() == normalized,
    );
    if (matchesAlias) {
      return AvocadoTreeAssets._profileIcons[entry.id] ??
          AvocadoTreeAssets.cropIcon;
    }
  }
  return AvocadoTreeAssets.cropIcon;
}

/// Icono neutro del aguacate (perfil general / etapa desconocida).
String avocadoTreeNeutralIcon() => AvocadoTreeAssets.neutralIcon;
