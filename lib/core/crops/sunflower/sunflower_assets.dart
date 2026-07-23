import 'package:bio_g/core/crops/sunflower/sunflower_catalog.dart';
import 'package:bio_g/widgets/seeds/sunflower_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_profiles.dart';

/// Fuente única de rutas para los assets oficiales del Girasol (Documento A
/// §15). Los archivos YA existen con sus nombres finales; no se renombran, no se
/// mueven y no se sustituyen por placeholders de otro cultivo.
///
/// La carpeta de etapas es `assets/seeds/Sunflower` (con S mayúscula y nombre en
/// inglés, igual que la carpeta física del repositorio). Los iconos de perfil
/// del wizard viven en `assets/icons/wizard`.
///
/// El Girasol NO tiene wizard visual de estado con arte propio (a diferencia del
/// Rosal): su etapa la resuelve el reloj anual. Por eso aquí solo hay UNA familia
/// de arte fenológico (`_stageImages`) más los íconos de perfil del wizard.
class SunflowerAssets {
  const SunflowerAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/Sunflower';

  // ── Iconos del wizard ──────────────────────────────────────────────────────
  static const String cropIcon = '$_wizardDir/ic_sunflower.png';
  static const String profileUnknown = '$_wizardDir/ic_sunflower_unknown.png';
  static const String profileTallGarden =
      '$_wizardDir/ic_sunflower_tall_garden.png';
  static const String profileCompactContainer =
      '$_wizardDir/ic_sunflower_compact_container.png';
  static const String profileBranchingOrnamental =
      '$_wizardDir/ic_sunflower_branching_ornamental.png';
  static const String profileCutFlowerSingleStem =
      '$_wizardDir/ic_sunflower_cut_flower_single_stem.png';

  // ── Imágenes de etapa (assets/seeds/Sunflower) ─────────────────────────────
  static const String stageSowing = '$_stageDir/sunflower_stage_sowing.png';
  static const String stageGermination =
      '$_stageDir/sunflower_stage_germination.png';
  static const String stageEmergence =
      '$_stageDir/sunflower_stage_emergence.png';
  static const String stageEarlyVegetativeGrowth =
      '$_stageDir/sunflower_stage_early_vegetative_growth.png';
  static const String stageActiveVegetativeGrowth =
      '$_stageDir/sunflower_stage_active_vegetative_growth.png';
  static const String stageStemElongation =
      '$_stageDir/sunflower_stage_stem_elongation.png';
  static const String stageBudFormation =
      '$_stageDir/sunflower_stage_bud_formation.png';
  static const String stageFlowering =
      '$_stageDir/sunflower_stage_flowering.png';
  static const String stagePostBloom =
      '$_stageDir/sunflower_stage_post_bloom.png';
  static const String stageSenescence =
      '$_stageDir/sunflower_stage_senescence.png';
  static const String stageCycleComplete =
      '$_stageDir/sunflower_stage_cycle_complete.png';

  /// Protección ante datos heredados / ids inválidos (Documento A §10.10). NO es
  /// una etapa normal del ciclo.
  static const String stageUnknown =
      '$_stageDir/sunflower_stage_unknown.png';

  static const String neutralIcon = profileUnknown;
  static const String genericPlantFallback =
      '$_wizardDir/ic_planta_generica.png';

  static const Map<String, String> _profileIcons = <String, String>{
    kGiSkip: profileUnknown,
    kGi01TallGarden: profileTallGarden,
    kGi02CompactContainer: profileCompactContainer,
    kGi03BranchingOrnamental: profileBranchingOrnamental,
    kGi04CutFlowerSingleStem: profileCutFlowerSingleStem,
  };

  static const Map<String, String> _stageImages = <String, String>{
    SunflowerStageIds.sowing: stageSowing,
    SunflowerStageIds.germination: stageGermination,
    SunflowerStageIds.emergence: stageEmergence,
    SunflowerStageIds.earlyVegetativeGrowth: stageEarlyVegetativeGrowth,
    SunflowerStageIds.activeVegetativeGrowth: stageActiveVegetativeGrowth,
    SunflowerStageIds.stemElongation: stageStemElongation,
    SunflowerStageIds.budFormation: stageBudFormation,
    SunflowerStageIds.flowering: stageFlowering,
    SunflowerStageIds.postBloom: stagePostBloom,
    SunflowerStageIds.senescence: stageSenescence,
    SunflowerStageIds.cycleComplete: stageCycleComplete,
  };

  /// Acepta un profileId canónico o un alias de entrada.
  static String profileIcon(String? profileId) {
    final normalized = profileId?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return cropIcon;

    final direct = _profileIcons[normalized];
    if (direct != null) return direct;

    for (final entry in sunflowerProfileEntries) {
      final isAlias = entry.aliases.any(
        (alias) => alias.trim().toLowerCase() == normalized,
      );
      if (isAlias) return _profileIcons[entry.id] ?? cropIcon;
    }
    return cropIcon;
  }

  /// Resuelve siempre una imagen fenológica válida; un stageId desconocido usa
  /// el arte oficial de etapa por confirmar.
  static String stageImageOrNeutral(String? stageId) {
    final id = normalizeSunflowerStageId(stageId);
    return _stageImages[id] ?? stageUnknown;
  }
}
