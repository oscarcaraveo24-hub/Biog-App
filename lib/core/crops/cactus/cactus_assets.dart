import 'package:bio_g/core/crops/cactus/cactus_catalog.dart';
import 'package:bio_g/core/crops/cactus/cactus_lifecycle.dart';

/// Fuente única de rutas para los assets oficiales de Cactus.
///
/// Las rutas normales nunca reutilizan arte de otros cultivos. Los resolvers
/// conservan un fallback defensivo al icono general/etapa desconocida.
class CactusAssets {
  const CactusAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/cactus';

  static const String cropIcon = '$_wizardDir/ic_cactus.png';
  static const String profileUnknown = '$_wizardDir/ic_cactus_unknown.png';
  static const String profileDesertContainer =
      '$_wizardDir/ic_cactus_desert_container.png';
  static const String profileBarrelBiznaga =
      '$_wizardDir/ic_cactus_barrel_biznaga.png';
  static const String profileColumnarLandscape =
      '$_wizardDir/ic_cactus_columnar_landscape.png';
  static const String profileClusteredDesert =
      '$_wizardDir/ic_cactus_clustered_desert.png';

  static const String stageInstallationEstablishment =
      '$_stageDir/cactus_stage_installation_establishment.png';
  static const String stageRootEstablishment =
      '$_stageDir/cactus_stage_root_establishment.png';
  static const String stageActiveGrowth =
      '$_stageDir/cactus_stage_active_growth.png';
  static const String stageMaintenance =
      '$_stageDir/cactus_stage_maintenance.png';
  static const String stageRest = '$_stageDir/cactus_stage_rest.png';
  static const String stageUnknown = '$_stageDir/cactus_stage_unknown.png';

  static const String neutralIcon = profileUnknown;
  static const String genericPlantFallback =
      '$_wizardDir/ic_planta_generica.png';

  static const Map<String, String> _profileIcons = <String, String>{
    kCaSkip: profileUnknown,
    kCa01DesertContainer: profileDesertContainer,
    kCa02BarrelBiznaga: profileBarrelBiznaga,
    kCa03ColumnarLandscape: profileColumnarLandscape,
    kCa04ClusteredDesert: profileClusteredDesert,
  };

  static const Map<String, String> _stageImages = <String, String>{
    CactusStageIds.installationEstablishment: stageInstallationEstablishment,
    CactusStageIds.rootEstablishment: stageRootEstablishment,
    CactusStageIds.activeGrowth: stageActiveGrowth,
    CactusStageIds.maintenance: stageMaintenance,
    CactusStageIds.rest: stageRest,
    CactusStageIds.unknown: stageUnknown,
  };

  /// Acepta un profileId canónico o un alias histórico de entrada.
  static String profileIcon(String? profileId) {
    final normalized = profileId?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return cropIcon;

    final direct = _profileIcons[normalized];
    if (direct != null) return direct;

    for (final entry in cactusProfileEntries) {
      final isAlias = entry.aliases.any(
        (alias) => alias.trim().toLowerCase() == normalized,
      );
      if (isAlias) return _profileIcons[entry.id] ?? cropIcon;
    }
    return cropIcon;
  }

  /// Resuelve siempre una imagen válida; un stageId desconocido usa el arte
  /// oficial de etapa desconocida.
  static String stageImageOrNeutral(String? stageId) {
    final id = normalizeCactusStageId(stageId);
    return _stageImages[id] ?? stageUnknown;
  }
}
