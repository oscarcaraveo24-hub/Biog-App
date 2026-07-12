import 'package:bio_g/core/crops/lemon_tree/lemon_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Assets del Limón (doc 01 §11).
///
/// TEMPORAL: el arte final del limón todavía NO existe. Los PNG cableados aquí
/// son RECICLADOS de otro cítrico (naranjo) como placeholder seguro mientras se
/// produce el arte propio de limón. Los archivos ya viven en las rutas de limón
/// (`assets/icons/wizard/ic_lemon_*` y `assets/seeds/lemon/lemon_stage_*`), así
/// que reemplazarlos después NO requiere tocar este código.
///
/// TODO(assets): sustituir por arte real de limón. Reglas visuales (doc 01 §11):
/// hojas cítricas brillantes, flor blanca (azahar), fruto verde/amarillo según
/// perfil. `dormancy` verde/vivo (NO árbol pelón). `fruit_fill` no es cosecha
/// final. `harvest_maturity` acepta verde comercial (Persa/Mexicano) y amarillo
/// (Amarillo/Eureka-Lisbon).
///
/// Decision citrica: `dormancy` NO usa arbol pelon. El limonero es siempreverde;
/// en reposo relativo conserva hoja.
class LemonTreeAssets {
  const LemonTreeAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/lemon';

  static const String iconTree = '$_wizardDir/ic_lemon_tree.png';
  static const String iconGeneric = '$_wizardDir/ic_lemon_tree.png';
  static const String iconPersaTahiti =
      '$_wizardDir/ic_lemon_persa_tahiti.png';
  static const String iconMexicanoColima =
      '$_wizardDir/ic_lemon_mexicano_colima.png';
  static const String iconAmarilloEurekaLisbon =
      '$_wizardDir/ic_lemon_amarillo_eureka_lisbon.png';
  static const String iconTropicalContinuo =
      '$_wizardDir/ic_lemon_tropical_continuo.png';
  static const String iconDesfaseInducido =
      '$_wizardDir/ic_lemon_desfase_inducido.png';

  /// Fallback neutro de arbol generico si algun PNG faltara.
  static const String genericTreeFallback = '$_wizardDir/ic_tree.png';

  /// Icono general del cultivo; LM-SKIP usa [iconGeneric].
  static const String cropIcon = iconTree;
  static const String neutralIcon = iconGeneric;

  static const String stagePlantingTransplant =
      '$_stageDir/lemon_stage_planting_transplant.png';
  static const String stageRootEstablishment =
      '$_stageDir/lemon_stage_root_establishment.png';
  static const String stageJuvenileVegetative =
      '$_stageDir/lemon_stage_juvenile_vegetative.png';
  static const String stageDormancy = '$_stageDir/lemon_stage_dormancy.png';
  static const String stageBudbreak = '$_stageDir/lemon_stage_budbreak.png';
  static const String stageVegetativeGrowth =
      '$_stageDir/lemon_stage_vegetative_growth.png';
  static const String stageFlowering = '$_stageDir/lemon_stage_flowering.png';
  static const String stageFruitSet = '$_stageDir/lemon_stage_fruit_set.png';
  static const String stageFruitFill = '$_stageDir/lemon_stage_fruit_fill.png';
  static const String stageHarvestMaturity =
      '$_stageDir/lemon_stage_harvest_maturity.png';
  static const String stagePostHarvest =
      '$_stageDir/lemon_stage_post_harvest.png';
  static const String stageUnknown = '$_stageDir/lemon_stage_unknown.png';

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

/// Imagen fenologica para una etapa del limon.
String? lemonTreeStageImage(String? phenologyStageId) {
  final id = normalizeTreeStageId(phenologyStageId);
  return LemonTreeAssets._stageImages[id];
}

/// Imagen fenologica con fallback neutro garantizado (nunca nulo).
String lemonTreeStageImageOrNeutral(String? phenologyStageId) =>
    lemonTreeStageImage(phenologyStageId) ?? LemonTreeAssets.stageUnknown;

/// Icono de wizard del perfil LM (acepta id de perfil o alias del catalogo).
String lemonTreeProfileIcon(String? profileId) {
  final normalized = profileId?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return LemonTreeAssets.cropIcon;
  }

  for (final entry in lemonTreeProfileEntries) {
    final matchesId = entry.id == normalized;
    final matchesAlias = entry.aliases.any(
      (alias) => alias.trim().toLowerCase() == normalized,
    );
    if (matchesId || matchesAlias) {
      switch (entry.id) {
        case kLmSkip:
          return LemonTreeAssets.iconGeneric;
        case kLm01PersaTahiti:
          return LemonTreeAssets.iconPersaTahiti;
        case kLm02MexicanoColima:
          return LemonTreeAssets.iconMexicanoColima;
        case kLm03AmarilloEurekaLisbon:
          return LemonTreeAssets.iconAmarilloEurekaLisbon;
        case kLm04TropicalContinuo:
          return LemonTreeAssets.iconTropicalContinuo;
        case kLm05DesfaseInducido:
          return LemonTreeAssets.iconDesfaseInducido;
      }
    }
  }
  return LemonTreeAssets.cropIcon;
}

/// Icono neutro del limon (perfil general / etapa desconocida).
String lemonTreeNeutralIcon() => LemonTreeAssets.neutralIcon;
