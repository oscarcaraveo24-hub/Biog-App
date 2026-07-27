import 'package:bio_g/core/crops/marigold/marigold_catalog.dart';
import 'package:bio_g/widgets/seeds/marigold_models.dart';
import 'package:bio_g/widgets/seeds/marigold_profiles.dart';

/// Fuente única de rutas para los assets oficiales del Cempasúchil (Documento A
/// §16). Los archivos YA existen con sus nombres finales; no se renombran, no
/// se mueven y no se sustituyen por placeholders de otro cultivo.
///
/// La carpeta de etapas es `assets/seeds/cempasuchil` (minúsculas, nombre en
/// español, igual que la carpeta física del repositorio). Los iconos de perfil
/// del wizard viven en `assets/icons/wizard` con el prefijo `ic_cempasuchil_`.
///
/// Nota de disco: el Documento A §16.2 propuso además un
/// `ic_cempasuchil_unknown.png` para el perfil general. Ese archivo NO existe
/// en el repositorio, así que `cs_skip` usa el ícono del cultivo
/// (`ic_cempasuchil.png`), que es neutral y no inventa un porte. El documento
/// mismo indica que los nombres definitivos deben verificarse contra disco
/// antes de integrar (§16).
///
/// El Cempasúchil NO tiene wizard visual de estado con arte propio (a
/// diferencia del Rosal): su etapa la resuelve el reloj anual. Por eso aquí
/// solo hay UNA familia de arte fenológico (`_stageImages`) más los íconos de
/// perfil del wizard.
class MarigoldAssets {
  const MarigoldAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/cempasuchil';

  // ── Iconos del wizard ──────────────────────────────────────────────────────
  static const String cropIcon = '$_wizardDir/ic_cempasuchil.png';
  static const String profileTraditionalField =
      '$_wizardDir/ic_cempasuchil_traditional_field.png';
  static const String profileTallCutFlower =
      '$_wizardDir/ic_cempasuchil_tall_cut_flower.png';
  static const String profileCompactContainer =
      '$_wizardDir/ic_cempasuchil_compact_container.png';
  static const String profileLandscapeBedding =
      '$_wizardDir/ic_cempasuchil_landscape_bedding.png';

  /// Perfil general: no hay arte "unknown" propio en disco, así que se usa el
  /// ícono neutral del cultivo. NUNCA se hereda el arte del Girasol.
  static const String profileUnknown = cropIcon;

  // ── Imágenes de etapa (assets/seeds/cempasuchil) ───────────────────────────
  static const String stageSowing = '$_stageDir/cempasuchil_stage_sowing.png';
  static const String stageGermination =
      '$_stageDir/cempasuchil_stage_germination.png';
  static const String stageEmergence =
      '$_stageDir/cempasuchil_stage_emergence.png';
  static const String stageEarlyVegetativeGrowth =
      '$_stageDir/cempasuchil_stage_early_vegetative_growth.png';
  static const String stageActiveVegetativeGrowth =
      '$_stageDir/cempasuchil_stage_active_vegetative_growth.png';
  static const String stageStemElongation =
      '$_stageDir/cempasuchil_stage_stem_elongation.png';
  static const String stageBudFormation =
      '$_stageDir/cempasuchil_stage_bud_formation.png';
  static const String stageFlowering =
      '$_stageDir/cempasuchil_stage_flowering.png';
  static const String stagePostBloom =
      '$_stageDir/cempasuchil_stage_post_bloom.png';
  static const String stageSenescence =
      '$_stageDir/cempasuchil_stage_senescence.png';
  static const String stageCycleComplete =
      '$_stageDir/cempasuchil_stage_cycle_complete.png';

  /// Protección ante datos heredados / ids inválidos (Documento A §10.12). NO
  /// es una etapa normal del ciclo.
  static const String stageUnknown =
      '$_stageDir/cempasuchil_stage_unknown.png';

  static const String neutralIcon = cropIcon;
  static const String genericPlantFallback =
      '$_wizardDir/ic_planta_generica.png';

  static const Map<String, String> _profileIcons = <String, String>{
    kCsSkip: profileUnknown,
    kCs01TraditionalField: profileTraditionalField,
    kCs02TallCutFlower: profileTallCutFlower,
    kCs03CompactContainer: profileCompactContainer,
    kCs04LandscapeBedding: profileLandscapeBedding,
  };

  static const Map<String, String> _stageImages = <String, String>{
    MarigoldStageIds.sowing: stageSowing,
    MarigoldStageIds.germination: stageGermination,
    MarigoldStageIds.emergence: stageEmergence,
    MarigoldStageIds.earlyVegetativeGrowth: stageEarlyVegetativeGrowth,
    MarigoldStageIds.activeVegetativeGrowth: stageActiveVegetativeGrowth,
    MarigoldStageIds.stemElongation: stageStemElongation,
    MarigoldStageIds.budFormation: stageBudFormation,
    MarigoldStageIds.flowering: stageFlowering,
    MarigoldStageIds.postBloom: stagePostBloom,
    MarigoldStageIds.senescence: stageSenescence,
    MarigoldStageIds.cycleComplete: stageCycleComplete,
  };

  /// Acepta un profileId canónico o un alias de entrada.
  static String profileIcon(String? profileId) {
    final normalized = profileId?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return cropIcon;

    final direct = _profileIcons[normalized];
    if (direct != null) return direct;

    for (final entry in marigoldProfileEntries) {
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
    final id = normalizeMarigoldStageId(stageId);
    return _stageImages[id] ?? stageUnknown;
  }
}
