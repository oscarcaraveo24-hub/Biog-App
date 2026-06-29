import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Rutas de assets de la Pera: imágenes fenológicas por etapa e íconos de wizard
/// por perfil/cultivo (doc 01 §16).
///
/// Reglas no negociables:
/// - NO se hardcodea ni reutiliza `apple_tree` para pera (doc 01 §16/§17).
/// - Los PNG reales viven en `assets/seeds/pear/` y `assets/icons/wizard/`.
///   No se declara ninguna ruta `pear_tree` inexistente.
class PearTreeAssets {
  const PearTreeAssets._();

  static const String _stageDir = 'assets/seeds/pear';
  static const String _wizardDir = 'assets/icons/wizard';

  // --- Íconos de wizard ------------------------------------------------------

  /// Ícono principal del cultivo Pera.
  static const String cropIcon = '$_wizardDir/ic_pear_tree.png';

  /// Fallback neutro de la pera (perfil general / etapa desconocida).
  static const String neutralIcon = '$_wizardDir/ic_pear_tree_generic.png';

  static const String _icBartlettWilliams =
      '$_wizardDir/ic_pear_bartlett_williams.png';
  static const String _icAnjou = '$_wizardDir/ic_pear_anjou.png';
  static const String _icBosc = '$_wizardDir/ic_pear_bosc.png';
  static const String _icSeckelComice = '$_wizardDir/ic_pear_seckel_comice.png';
  static const String _icKiefferRustic =
      '$_wizardDir/ic_pear_kieffer_rustic.png';

  // --- Imágenes fenológicas por etapa ---------------------------------------

  static const Map<String, String> _stageImages = <String, String>{
    TreeStageIds.plantingTransplant:
        '$_stageDir/pear_stage_planting_transplant.png',
    TreeStageIds.rootEstablishment:
        '$_stageDir/pear_stage_root_establishment.png',
    TreeStageIds.juvenileVegetative:
        '$_stageDir/pear_stage_juvenile_vegetative.png',
    TreeStageIds.dormancy: '$_stageDir/pear_stage_dormancy.png',
    TreeStageIds.budbreak: '$_stageDir/pear_stage_budbreak.png',
    TreeStageIds.vegetativeGrowth:
        '$_stageDir/pear_stage_vegetative_growth.png',
    TreeStageIds.flowering: '$_stageDir/pear_stage_flowering.png',
    TreeStageIds.fruitSet: '$_stageDir/pear_stage_fruit_set.png',
    TreeStageIds.fruitFill: '$_stageDir/pear_stage_fruit_fill.png',
    TreeStageIds.harvestMaturity: '$_stageDir/pear_stage_harvest_maturity.png',
    TreeStageIds.postHarvest: '$_stageDir/pear_stage_post_harvest.png',
    TreeStageIds.unknown: '$_stageDir/pear_stage_unknown.png',
  };

  /// Íconos de wizard por perfil PR (doc 01). `pr_skip`/desconocido → neutro.
  static const Map<String, String> _profileIcons = <String, String>{
    kPrSkip: neutralIcon,
    kPr01BartlettWilliams: _icBartlettWilliams,
    kPr02Anjou: _icAnjou,
    kPr03Bosc: _icBosc,
    kPr04SeckelComice: _icSeckelComice,
    kPr05KiefferRustic: _icKiefferRustic,
  };
}

/// Imagen fenológica para una etapa de la pera.
String? pearTreeStageImage(String? phenologyStageId) {
  final id = normalizeTreeStageId(phenologyStageId);
  return PearTreeAssets._stageImages[id];
}

/// Imagen fenológica con fallback neutro garantizado (nunca nulo).
String pearTreeStageImageOrNeutral(String? phenologyStageId) =>
    pearTreeStageImage(phenologyStageId) ?? PearTreeAssets.neutralIcon;

/// Ícono de wizard del perfil PR (acepta id de perfil o alias del catálogo).
String pearTreeProfileIcon(String? profileId) {
  final normalized = profileId?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return PearTreeAssets.neutralIcon;
  }
  final direct = PearTreeAssets._profileIcons[normalized];
  if (direct != null) return direct;

  for (final entry in pearTreeProfileEntries) {
    final matchesId = entry.id == normalized;
    final matchesAlias = entry.aliases.any(
      (alias) => alias.trim().toLowerCase() == normalized,
    );
    if (matchesId || matchesAlias) {
      return PearTreeAssets._profileIcons[entry.id] ??
          PearTreeAssets.neutralIcon;
    }
  }
  return PearTreeAssets.neutralIcon;
}

/// Ícono neutro de la pera (perfil general / etapa desconocida).
String pearTreeNeutralIcon() => PearTreeAssets.neutralIcon;
