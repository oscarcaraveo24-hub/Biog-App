import 'package:bio_g/core/crops/succulent/succulent_catalog.dart';
import 'package:bio_g/core/crops/succulent/succulent_lifecycle.dart';

/// Fuente única de rutas para los assets oficiales de Suculenta.
///
/// Los archivos YA existen con sus nombres finales. No se renombran, no se
/// mueven y no se sustituyen por placeholders.
class SucculentAssets {
  const SucculentAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/succulent';

  // ── Iconos glossy del wizard ───────────────────────────────────────────────
  static const String cropIcon = '$_wizardDir/ic_succulent.png';
  static const String profileUnknown = '$_wizardDir/ic_succulent_unknown.png';
  static const String profileRosette = '$_wizardDir/ic_succulent_rosette.png';
  static const String profileTrailing = '$_wizardDir/ic_succulent_trailing.png';
  static const String profileBranching =
      '$_wizardDir/ic_succulent_branching.png';
  static const String profileCompactFiltered =
      '$_wizardDir/ic_succulent_compact_filtered.png';

  // ── Imágenes de etapa ──────────────────────────────────────────────────────
  static const String stageInstallationEstablishment =
      '$_stageDir/succulent_stage_installation_establishment.png';
  static const String stageRootEstablishment =
      '$_stageDir/succulent_stage_root_establishment.png';
  static const String stageActiveGrowth =
      '$_stageDir/succulent_stage_active_growth.png';
  static const String stageMaintenance =
      '$_stageDir/succulent_stage_maintenance.png';
  static const String stageRest = '$_stageDir/succulent_stage_rest.png';
  static const String stageUnknown = '$_stageDir/succulent_stage_unknown.png';

  static const String neutralIcon = profileUnknown;
  static const String genericPlantFallback =
      '$_wizardDir/ic_planta_generica.png';

  static const Map<String, String> _profileIcons = <String, String>{
    kSuSkip: profileUnknown,
    kSu01RosetteBrightLight: profileRosette,
    kSu02TrailingCascading: profileTrailing,
    kSu03BranchingWoody: profileBranching,
    kSu04CompactFilteredLight: profileCompactFiltered,
  };

  static const Map<String, String> _stageImages = <String, String>{
    SucculentStageIds.installationEstablishment: stageInstallationEstablishment,
    SucculentStageIds.rootEstablishment: stageRootEstablishment,
    SucculentStageIds.activeGrowth: stageActiveGrowth,
    SucculentStageIds.maintenance: stageMaintenance,
    SucculentStageIds.rest: stageRest,
    SucculentStageIds.unknown: stageUnknown,
  };

  /// Acepta un profileId canónico o un alias de entrada.
  static String profileIcon(String? profileId) {
    final normalized = profileId?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return cropIcon;

    final direct = _profileIcons[normalized];
    if (direct != null) return direct;

    for (final entry in succulentProfileEntries) {
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
    final id = normalizeSucculentStageId(stageId);
    return _stageImages[id] ?? stageUnknown;
  }
}
