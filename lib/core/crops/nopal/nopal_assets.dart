import 'package:bio_g/core/crops/nopal/nopal_catalog.dart';
import 'package:bio_g/core/crops/nopal/nopal_lifecycle.dart';

/// Fuente única de rutas para los assets oficiales del Nopal.
///
/// Los archivos YA existen con sus nombres finales. No se renombran, no se
/// mueven y no se sustituyen por placeholders. La carpeta de etapas es
/// `assets/seeds/nopal` (minúscula, como cactus/succulent/agave). Los iconos de
/// perfil usan el nombre completo del morfotipo
/// (`ic_nopal_compact_clumping_container.png`, etc.), que corresponde 1:1 con
/// los profileId `no_0x_*`.
///
/// Recordatorio del Doc A §6.1: el arte de NO-01 no debe invitar a tocar la
/// planta. Los gloquidios parecen pelusa suave y se desprenden.
class NopalAssets {
  const NopalAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/nopal';

  // ── Iconos glossy del wizard ───────────────────────────────────────────────
  static const String cropIcon = '$_wizardDir/ic_nopal.png';
  static const String profileUnknown = '$_wizardDir/ic_nopal_unknown.png';
  static const String profileCompactClumpingContainer =
      '$_wizardDir/ic_nopal_compact_clumping_container.png';
  static const String profileUprightLargePadWarm =
      '$_wizardDir/ic_nopal_upright_large_pad_warm.png';
  static const String profileDesertShrubSpinyLandscape =
      '$_wizardDir/ic_nopal_desert_shrub_spiny_landscape.png';
  static const String profileLowSpreadingColdHardy =
      '$_wizardDir/ic_nopal_low_spreading_cold_hardy.png';

  // ── Imágenes de etapa ──────────────────────────────────────────────────────
  static const String stageInstallationEstablishment =
      '$_stageDir/nopal_stage_installation_establishment.png';
  static const String stageRootEstablishment =
      '$_stageDir/nopal_stage_root_establishment.png';
  static const String stageActiveGrowth =
      '$_stageDir/nopal_stage_active_growth.png';
  static const String stageMaintenance =
      '$_stageDir/nopal_stage_maintenance.png';
  static const String stageRest = '$_stageDir/nopal_stage_rest.png';
  static const String stageUnknown = '$_stageDir/nopal_stage_unknown.png';

  static const String neutralIcon = profileUnknown;
  static const String genericPlantFallback =
      '$_wizardDir/ic_planta_generica.png';

  static const Map<String, String> _profileIcons = <String, String>{
    kNopalSkip: profileUnknown,
    kNopal01CompactClumpingContainer: profileCompactClumpingContainer,
    kNopal02UprightLargePadWarm: profileUprightLargePadWarm,
    kNopal03DesertShrubSpinyLandscape: profileDesertShrubSpinyLandscape,
    kNopal04LowSpreadingColdHardy: profileLowSpreadingColdHardy,
  };

  static const Map<String, String> _stageImages = <String, String>{
    NopalStageIds.installationEstablishment: stageInstallationEstablishment,
    NopalStageIds.rootEstablishment: stageRootEstablishment,
    NopalStageIds.activeGrowth: stageActiveGrowth,
    NopalStageIds.maintenance: stageMaintenance,
    NopalStageIds.rest: stageRest,
    NopalStageIds.unknown: stageUnknown,
  };

  /// Acepta un profileId canónico o un alias de entrada.
  static String profileIcon(String? profileId) {
    final normalized = profileId?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return cropIcon;

    final direct = _profileIcons[normalized];
    if (direct != null) return direct;

    for (final entry in nopalProfileEntries) {
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
    final id = normalizeNopalStageId(stageId);
    return _stageImages[id] ?? stageUnknown;
  }
}
