import 'package:bio_g/core/crops/rose/rose_catalog.dart';
import 'package:bio_g/core/crops/rose/rose_lifecycle.dart';

/// Fuente única de rutas para los assets oficiales del Rosal.
///
/// El rosal tiene DOS familias de arte donde las demás ornamentales tienen una:
///   - `_stageImages`  → imágenes fenológicas de seguimiento (assets/seeds/rose).
///   - `_stateIcons`   → íconos del wizard visual "¿Cómo está tu rosal ahora?"
///     (assets/icons/wizard/ic_rose_state_*), exclusivos del modo de floración
///     recurrente.
///
/// Las rutas normales nunca reutilizan arte de otros cultivos. Los resolvers
/// conservan un fallback defensivo al icono general / etapa desconocida.
class RoseAssets {
  const RoseAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/rose';

  static const String cropIcon = '$_wizardDir/ic_rose.png';
  static const String profileUnknown = '$_wizardDir/ic_rose_unknown.png';
  static const String profileMiniatureContainer =
      '$_wizardDir/ic_rose_miniature_container.png';
  static const String profileLargeFloweredBush =
      '$_wizardDir/ic_rose_large_flowered_bush.png';
  static const String profileClusteredLandscape =
      '$_wizardDir/ic_rose_clustered_landscape.png';
  static const String profileRepeatClimber =
      '$_wizardDir/ic_rose_repeat_climber.png';

  // Íconos del wizard visual de estado actual (floración recurrente).
  static const String stateVegetativeFlush =
      '$_wizardDir/ic_rose_state_vegetative_flush.png';
  static const String stateBudFormation =
      '$_wizardDir/ic_rose_state_bud_formation.png';
  static const String stateFlowering =
      '$_wizardDir/ic_rose_state_flowering.png';
  static const String statePostBloomRecovery =
      '$_wizardDir/ic_rose_state_post_bloom_recovery.png';
  static const String stateRest = '$_wizardDir/ic_rose_state_rest.png';

  // Imágenes fenológicas de seguimiento.
  static const String stageInstallationEstablishment =
      '$_stageDir/rose_stage_installation_establishment.png';
  static const String stageRootEstablishment =
      '$_stageDir/rose_stage_root_establishment.png';
  static const String stageVegetativeFlush =
      '$_stageDir/rose_stage_vegetative_flush.png';
  static const String stageBudFormation =
      '$_stageDir/rose_stage_bud_formation.png';
  static const String stageFlowering = '$_stageDir/rose_stage_flowering.png';
  static const String stagePostBloomRecovery =
      '$_stageDir/rose_stage_post_bloom_recovery.png';
  static const String stageRest = '$_stageDir/rose_stage_rest.png';
  static const String stageUnknown = '$_stageDir/rose_stage_unknown.png';

  static const String neutralIcon = profileUnknown;
  static const String genericPlantFallback =
      '$_wizardDir/ic_planta_generica.png';

  static const Map<String, String> _profileIcons = <String, String>{
    kRoSkip: profileUnknown,
    kRo01MiniatureContainer: profileMiniatureContainer,
    kRo02LargeFloweredBush: profileLargeFloweredBush,
    kRo03ClusteredLandscape: profileClusteredLandscape,
    kRo04RepeatClimber: profileRepeatClimber,
  };

  static const Map<String, String> _stageImages = <String, String>{
    RoseStageIds.installationEstablishment: stageInstallationEstablishment,
    RoseStageIds.rootEstablishment: stageRootEstablishment,
    RoseStageIds.vegetativeFlush: stageVegetativeFlush,
    RoseStageIds.budFormation: stageBudFormation,
    RoseStageIds.flowering: stageFlowering,
    RoseStageIds.postBloomRecovery: stagePostBloomRecovery,
    RoseStageIds.rest: stageRest,
    RoseStageIds.unknown: stageUnknown,
  };

  /// Íconos del wizard visual, solo para los estados recurrentes.
  static const Map<String, String> _stateIcons = <String, String>{
    RoseStageIds.vegetativeFlush: stateVegetativeFlush,
    RoseStageIds.budFormation: stateBudFormation,
    RoseStageIds.flowering: stateFlowering,
    RoseStageIds.postBloomRecovery: statePostBloomRecovery,
    RoseStageIds.rest: stateRest,
  };

  /// Acepta un profileId canónico o un alias histórico de entrada.
  static String profileIcon(String? profileId) {
    final normalized = profileId?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return cropIcon;

    final direct = _profileIcons[normalized];
    if (direct != null) return direct;

    for (final entry in roseProfileEntries) {
      final isAlias = entry.aliases.any(
        (alias) => alias.trim().toLowerCase() == normalized,
      );
      if (isAlias) return _profileIcons[entry.id] ?? cropIcon;
    }
    return cropIcon;
  }

  /// Resuelve siempre una imagen fenológica válida; un stageId desconocido usa
  /// el arte oficial de etapa desconocida.
  static String stageImageOrNeutral(String? stageId) {
    final id = normalizeRoseStageId(stageId);
    return _stageImages[id] ?? stageUnknown;
  }

  /// Ícono del wizard visual para el estado dado. Los estados recurrentes usan
  /// el arte `ic_rose_state_*`; el establecimiento usa el icono del cultivo y el
  /// desconocido usa el icono general.
  static String stateIconForStage(String? stageId) {
    final id = normalizeRoseStageId(stageId);
    final direct = _stateIcons[id];
    if (direct != null) return direct;
    if (RoseStageIds.establishmentStages.contains(id)) return cropIcon;
    return profileUnknown;
  }
}
