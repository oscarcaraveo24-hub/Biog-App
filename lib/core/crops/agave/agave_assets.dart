import 'package:bio_g/core/crops/agave/agave_catalog.dart';
import 'package:bio_g/core/crops/agave/agave_lifecycle.dart';

/// Fuente única de rutas para los assets oficiales del Maguey / Agave.
///
/// Los archivos YA existen con sus nombres finales (Doc A §12). No se renombran,
/// no se mueven y no se sustituyen por placeholders. La carpeta de etapas es
/// `assets/seeds/agave` (minúscula, como cactus/succulent). Los iconos de perfil
/// usan el nombre completo del morfotipo (`ic_agave_compact_sculptural.png`,
/// etc.), que corresponde 1:1 con los profileId `mg_0x_*`.
class AgaveAssets {
  const AgaveAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/agave';

  // ── Iconos glossy del wizard ───────────────────────────────────────────────
  static const String cropIcon = '$_wizardDir/ic_agave.png';
  static const String profileUnknown = '$_wizardDir/ic_agave_unknown.png';
  static const String profileCompactSculptural =
      '$_wizardDir/ic_agave_compact_sculptural.png';
  static const String profileLargeSpinyLandscape =
      '$_wizardDir/ic_agave_large_spiny_landscape.png';
  static const String profileBlueNarrowField =
      '$_wizardDir/ic_agave_blue_narrow_field.png';
  static const String profileSoftSpinelessWarm =
      '$_wizardDir/ic_agave_soft_spineless_warm.png';

  // ── Imágenes de etapa ──────────────────────────────────────────────────────
  static const String stageInstallationEstablishment =
      '$_stageDir/agave_stage_installation_establishment.png';
  static const String stageRootEstablishment =
      '$_stageDir/agave_stage_root_establishment.png';
  static const String stageActiveGrowth =
      '$_stageDir/agave_stage_active_growth.png';
  static const String stageMaintenance =
      '$_stageDir/agave_stage_maintenance.png';
  static const String stageRest = '$_stageDir/agave_stage_rest.png';
  static const String stageUnknown = '$_stageDir/agave_stage_unknown.png';

  static const String neutralIcon = profileUnknown;
  static const String genericPlantFallback =
      '$_wizardDir/ic_planta_generica.png';

  static const Map<String, String> _profileIcons = <String, String>{
    kAgaveSkip: profileUnknown,
    kAgave01CompactSculptural: profileCompactSculptural,
    kAgave02LargeSpinyLandscape: profileLargeSpinyLandscape,
    kAgave03BlueNarrowField: profileBlueNarrowField,
    kAgave04SoftSpinelessWarm: profileSoftSpinelessWarm,
  };

  static const Map<String, String> _stageImages = <String, String>{
    AgaveStageIds.installationEstablishment: stageInstallationEstablishment,
    AgaveStageIds.rootEstablishment: stageRootEstablishment,
    AgaveStageIds.activeGrowth: stageActiveGrowth,
    AgaveStageIds.maintenance: stageMaintenance,
    AgaveStageIds.rest: stageRest,
    AgaveStageIds.unknown: stageUnknown,
  };

  /// Acepta un profileId canónico o un alias de entrada.
  static String profileIcon(String? profileId) {
    final normalized = profileId?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return cropIcon;

    final direct = _profileIcons[normalized];
    if (direct != null) return direct;

    for (final entry in agaveProfileEntries) {
      final isAlias = entry.aliases.any(
        (alias) => alias.trim().toLowerCase() == normalized,
      );
      if (isAlias) return _profileIcons[entry.id] ?? cropIcon;
    }
    return cropIcon;
  }

  /// Resuelve siempre una imagen válida; un stageId desconocido usa el arte
  /// oficial de etapa por confirmar.
  static String stageImageOrNeutral(String? stageId) {
    final id = normalizeAgaveStageId(stageId);
    return _stageImages[id] ?? stageUnknown;
  }
}
