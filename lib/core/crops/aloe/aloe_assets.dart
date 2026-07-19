import 'package:bio_g/core/crops/aloe/aloe_catalog.dart';
import 'package:bio_g/core/crops/aloe/aloe_lifecycle.dart';

/// Fuente única de rutas para los assets oficiales de Sábila / Aloe.
///
/// Los archivos YA existen con sus nombres finales (Doc A §9). No se renombran,
/// no se mueven y no se sustituyen por placeholders. La carpeta de etapas es
/// `assets/seeds/Aloe` (con A mayúscula, igual que Oat/Squash/Onion/Garlic).
class AloeAssets {
  const AloeAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/Aloe';

  // ── Iconos glossy del wizard ───────────────────────────────────────────────
  static const String cropIcon = '$_wizardDir/ic_aloe.png';
  static const String profileUnknown = '$_wizardDir/ic_aloe_unknown.png';
  static const String profileBroadleaf = '$_wizardDir/ic_aloe_broadleaf.png';
  static const String profileSmallClumping =
      '$_wizardDir/icon_conic_aloe_small_clumping.png';
  static const String profileShrubby = '$_wizardDir/ic_aloe_shrubby.png';
  static const String profileSpotted = '$_wizardDir/ic_aloe_spotted.png';

  // ── Imágenes de etapa ──────────────────────────────────────────────────────
  static const String stageInstallationEstablishment =
      '$_stageDir/aloe_stage_installation_establishment.png';
  static const String stageRootEstablishment =
      '$_stageDir/aloe_stage_root_establishment.png';
  static const String stageActiveGrowth =
      '$_stageDir/aloe_stage_active_growth.png';
  static const String stageMaintenance =
      '$_stageDir/aloe_stage_maintenance.png';
  static const String stageRest = '$_stageDir/aloe_stage_rest.png';
  static const String stageUnknown = '$_stageDir/aloe_stage_unknown.png';

  static const String neutralIcon = profileUnknown;
  static const String genericPlantFallback =
      '$_wizardDir/ic_planta_generica.png';

  static const Map<String, String> _profileIcons = <String, String>{
    kSaSkip: profileUnknown,
    kSa01BroadleafRosette: profileBroadleaf,
    kSa02SmallClumping: profileSmallClumping,
    kSa03ShrubbyBranching: profileShrubby,
    kSa04SpottedLandscape: profileSpotted,
  };

  static const Map<String, String> _stageImages = <String, String>{
    AloeStageIds.installationEstablishment: stageInstallationEstablishment,
    AloeStageIds.rootEstablishment: stageRootEstablishment,
    AloeStageIds.activeGrowth: stageActiveGrowth,
    AloeStageIds.maintenance: stageMaintenance,
    AloeStageIds.rest: stageRest,
    AloeStageIds.unknown: stageUnknown,
  };

  /// Acepta un profileId canónico o un alias de entrada.
  static String profileIcon(String? profileId) {
    final normalized = profileId?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return cropIcon;

    final direct = _profileIcons[normalized];
    if (direct != null) return direct;

    for (final entry in aloeProfileEntries) {
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
    final id = normalizeAloeStageId(stageId);
    return _stageImages[id] ?? stageUnknown;
  }
}
