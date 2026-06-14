import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Rutas de assets del Manzano: imágenes fenológicas por etapa e íconos de
/// wizard por perfil/cultivo.
///
/// Reglas no negociables que respeta este archivo:
/// - NO existe ni se usa una imagen fenológica para `unknown`. Si la etapa es
///   desconocida, [appleTreeStageImage] devuelve `null` y la UI debe usar un
///   fallback neutro ([appleTreeNeutralIcon], `ic_apple_tree_generic.png`).
/// - No se inventan rutas: todas apuntan a archivos reales ya presentes en
///   `assets/seeds/apple/` y `assets/icons/wizard/`.
class AppleTreeAssets {
  const AppleTreeAssets._();

  static const String _stageDir = 'assets/seeds/apple';
  static const String _wizardDir = 'assets/icons/wizard';

  // --- Íconos de wizard ------------------------------------------------------

  /// Ícono principal del cultivo Manzano.
  static const String cropIcon = '$_wizardDir/ic_apple_tree.png';

  /// Fallback neutro del manzano (perfil general / etapa desconocida).
  static const String neutralIcon = '$_wizardDir/ic_apple_tree_generic.png';

  static const String _icGolden = '$_wizardDir/ic_apple_golden.png';
  static const String _icRed = '$_wizardDir/ic_apple_red.png';
  static const String _icCriollaRayada =
      '$_wizardDir/ic_apple_criolla_rayada.png';
  static const String _icGala = '$_wizardDir/ic_apple_gala.png';
  static const String _icLowChill = '$_wizardDir/ic_apple_low_chill.png';

  // --- Imágenes fenológicas por etapa ---------------------------------------

  static const Map<String, String> _stageImages = <String, String>{
    TreeStageIds.plantingTransplant:
        '$_stageDir/apple_stage_planting_transplant.png',
    TreeStageIds.rootEstablishment:
        '$_stageDir/apple_stage_root_establishment.png',
    TreeStageIds.juvenileVegetative:
        '$_stageDir/apple_stage_juvenile_vegetative.png',
    TreeStageIds.dormancy: '$_stageDir/apple_stage_dormancy.png',
    TreeStageIds.budbreak: '$_stageDir/apple_stage_budbreak.png',
    TreeStageIds.vegetativeGrowth:
        '$_stageDir/apple_stage_vegetative_growth.png',
    TreeStageIds.flowering: '$_stageDir/apple_stage_flowering.png',
    TreeStageIds.fruitSet: '$_stageDir/apple_stage_fruit_set.png',
    TreeStageIds.fruitFill: '$_stageDir/apple_stage_fruit_fill.png',
    TreeStageIds.harvestMaturity: '$_stageDir/apple_stage_harvest_maturity.png',
    TreeStageIds.postHarvest: '$_stageDir/apple_stage_post_harvest.png',
    // NOTA: `unknown` no tiene imagen fenológica a propósito.
  };

  /// Íconos de wizard por perfil AP (doc 01). `ap_skip` y desconocido → neutro.
  static const Map<String, String> _profileIcons = <String, String>{
    kApSkip: neutralIcon,
    kAp01Golden: _icGolden,
    kAp02Red: _icRed,
    kAp03CriollaRayada: _icCriollaRayada,
    kAp04Gala: _icGala,
    kAp05LowChill: _icLowChill,
  };
}

/// Imagen fenológica para una etapa del manzano.
///
/// Devuelve `null` para `unknown` (o etapas no reconocidas): la UI debe mostrar
/// un fallback neutro y NUNCA un `apple_stage_unknown.png` (no existe).
String? appleTreeStageImage(String? phenologyStageId) {
  final id = normalizeTreeStageId(phenologyStageId);
  if (id == TreeStageIds.unknown) return null;
  return AppleTreeAssets._stageImages[id];
}

/// Imagen fenológica con fallback neutro garantizado (nunca nulo).
///
/// Útil para widgets que siempre necesitan un asset que pintar.
String appleTreeStageImageOrNeutral(String? phenologyStageId) =>
    appleTreeStageImage(phenologyStageId) ?? AppleTreeAssets.neutralIcon;

/// Ícono de wizard del perfil AP (acepta id de perfil o alias del catálogo).
String appleTreeProfileIcon(String? profileId) {
  final normalized = profileId?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return AppleTreeAssets.neutralIcon;
  }
  final direct = AppleTreeAssets._profileIcons[normalized];
  if (direct != null) return direct;

  // Resolver por alias/etiqueta usando el catálogo de perfiles del manzano.
  for (final entry in appleTreeProfileEntries) {
    final matchesId = entry.id == normalized;
    final matchesAlias = entry.aliases.any(
      (alias) => alias.trim().toLowerCase() == normalized,
    );
    if (matchesId || matchesAlias) {
      return AppleTreeAssets._profileIcons[entry.id] ??
          AppleTreeAssets.neutralIcon;
    }
  }
  return AppleTreeAssets.neutralIcon;
}

/// Ícono neutro del manzano (perfil general / etapa desconocida).
String appleTreeNeutralIcon() => AppleTreeAssets.neutralIcon;
