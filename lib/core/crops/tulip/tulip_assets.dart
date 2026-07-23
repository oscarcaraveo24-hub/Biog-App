import 'package:bio_g/core/crops/tulip/tulip_catalog.dart';
import 'package:bio_g/widgets/seeds/tulip_models.dart';
import 'package:bio_g/widgets/seeds/tulip_profiles.dart';

/// Fuente única de rutas para los assets oficiales del Tulipán.
///
/// Los archivos YA existen con sus nombres finales (Documento A). No se
/// renombran, no se mueven y no se sustituyen por placeholders de otro
/// cultivo. La carpeta de etapas es `assets/seeds/Tulipan` (con T mayúscula y
/// nombre en español, igual que `assets/seeds/Aloe`, `assets/seeds/Rose`,
/// `assets/seeds/Oat`).
///
/// El Tulipán NO tiene wizard visual de estado (a diferencia del Rosal): su
/// etapa la resuelve el reloj anual. Por eso aquí solo hay UNA familia de
/// arte fenológico (`_stageImages`) más los íconos de perfil del wizard.
class TulipAssets {
  const TulipAssets._();

  static const String _wizardDir = 'assets/icons/wizard';
  static const String _stageDir = 'assets/seeds/Tulipan';

  // ── Iconos del wizard ──────────────────────────────────────────────────────
  static const String cropIcon = '$_wizardDir/ic_tulip.png';
  static const String profileUnknown = '$_wizardDir/ic_tulip_unknown.png';
  static const String profileGardenExterior =
      '$_wizardDir/ic_tulip_garden_exterior.png';
  static const String profileDecorativeContainer =
      '$_wizardDir/ic_tulip_decorative_container.png';
  static const String profileForcedIndoor =
      '$_wizardDir/ic_tulip_forced_indoor.png';
  static const String profileCutFlower =
      '$_wizardDir/ic_tulip_cut_flower.png';
  static const String profileSpecialPremium =
      '$_wizardDir/ic_tulip_special_premium.png';

  // ── Imágenes de etapa (assets/seeds/Tulipan) ───────────────────────────────
  static const String stageBulbPlanting =
      '$_stageDir/tulip_stage_bulb_planting.png';
  static const String stageRootingChilling =
      '$_stageDir/tulip_stage_rooting_chilling.png';
  static const String stageShootEmergence =
      '$_stageDir/tulip_stage_shoot_emergence.png';
  static const String stageVegetativeGrowth =
      '$_stageDir/tulip_stage_vegetative_growth.png';
  static const String stageStemElongation =
      '$_stageDir/tulip_stage_stem_elongation.png';
  static const String stageBudFormation =
      '$_stageDir/tulip_stage_bud_formation.png';
  static const String stageFlowering = '$_stageDir/tulip_stage_flowering.png';
  static const String stageBulbRecharge =
      '$_stageDir/tulip_stage_bulb_recharge.png';
  static const String stageFoliageSenescence =
      '$_stageDir/tulip_stage_foliage_senescence.png';
  static const String stageDormancy = '$_stageDir/tulip_stage_dormancy.png';

  /// Protección ante datos heredados / ids inválidos (Documento A §5.1). NO es
  /// una etapa normal del ciclo.
  static const String stageUnknown = '$_stageDir/tulip_stage_unknown.png';

  static const String neutralIcon = profileUnknown;
  static const String genericPlantFallback =
      '$_wizardDir/ic_planta_generica.png';

  static const Map<String, String> _profileIcons = <String, String>{
    kTuSkip: profileUnknown,
    kTu01GardenExterior: profileGardenExterior,
    kTu02DecorativeContainer: profileDecorativeContainer,
    kTu03ForcedIndoor: profileForcedIndoor,
    kTu04CutFlower: profileCutFlower,
    kTu05SpecialPremium: profileSpecialPremium,
  };

  static const Map<String, String> _stageImages = <String, String>{
    TulipStageIds.bulbPlanting: stageBulbPlanting,
    TulipStageIds.rootingChilling: stageRootingChilling,
    TulipStageIds.shootEmergence: stageShootEmergence,
    TulipStageIds.vegetativeGrowth: stageVegetativeGrowth,
    TulipStageIds.stemElongation: stageStemElongation,
    TulipStageIds.budFormation: stageBudFormation,
    TulipStageIds.flowering: stageFlowering,
    TulipStageIds.bulbRecharge: stageBulbRecharge,
    TulipStageIds.foliageSenescence: stageFoliageSenescence,
    TulipStageIds.dormancy: stageDormancy,
  };

  /// Acepta un profileId canónico o un alias de entrada.
  static String profileIcon(String? profileId) {
    final normalized = profileId?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return cropIcon;

    final direct = _profileIcons[normalized];
    if (direct != null) return direct;

    for (final entry in tulipProfileEntries) {
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
    final id = normalizeTulipStageId(stageId);
    return _stageImages[id] ?? stageUnknown;
  }
}
