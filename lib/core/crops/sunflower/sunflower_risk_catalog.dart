/// Catálogo de riesgos, sanidad y estrés del Girasol (Documento C).
///
/// Contrato de seguridad (Documento C §0.1, §2, §7): BIO-G NO diagnostica
/// patógenos, NO prescribe plaguicidas ni dosis. Una lectura de sensor por sí
/// sola nunca genera un `high`/`critical` sanitario: se requiere una señal
/// observada fuerte reportada por el usuario. El lenguaje es "condición
/// compatible con…", "revisa", "por confirmar". La senescencia normal y el fin
/// del ciclo son procesos NORMALES, no enfermedad.
///
/// Este archivo es el VOCABULARIO estable (grupos, niveles, urgencias e ids de
/// riesgo). El detalle clínico (síndromes, diferenciales, señales, preguntas de
/// confirmación) vive en
/// `lib/core/plant_health/catalog/sunflower_syndromes.dart`, que consume el motor
/// de sanidad COMPARTIDO. Los ids aquí coinciden 1:1 con los ids de síndrome
/// para que el motor y el reporte los referencien sin duplicar (Documento C
/// §10.5).
library;

/// Familia del riesgo (Documento C §0).
enum SunflowerRiskGroup {
  seedAndSeedling,
  rootCrownStructure,
  foliageDisease,
  pestsInvertebrates,
  budFlowerHead,
  abioticStress,
  benignProcess,
}

/// Nivel de salida del riesgo (Documento C §2.3). El sensor nunca alcanza los
/// niveles altos por sí solo: eso requiere una señal observada.
enum SunflowerRiskLevel { normal, watch, review, highPriority, separateAndEscalate }

/// Urgencia recomendada (Documento C §2.4). El sensor nunca alcanza `immediate`
/// por sí solo: requiere confirmación externa/fitosanitaria.
enum SunflowerRiskUrgency { monitor72h, review48h, review24h, sameDay, immediate }

/// Disclaimer canónico obligatorio en cada resultado (Documento C §0.2).
const String sunflowerHealthDisclaimer =
    'BIO-G organiza observaciones y contexto para orientar la revisión. '
    'No confirma una enfermedad, una plaga ni un organismo causal.';

/// Ids canónicos de riesgo/síndrome del girasol (Documento C §5). Se conservan
/// idénticos a los ids del catálogo de síndromes (36 en total, seis familias).
class SunflowerRiskIds {
  const SunflowerRiskIds._();

  // Familia 1 — semilla y plántula.
  static const String poorOrPatchyEmergence =
      'sunflower_poor_or_patchy_emergence_01';
  static const String seedlingCollapseAtSoilLine =
      'sunflower_seedling_collapse_at_soil_line_02';

  // Familia 2 — raíz, cuello y estructura.
  static const String rootCrownSoftDeterioration =
      'sunflower_root_crown_soft_deterioration_03';
  static const String wiltWhileSoilIsWet =
      'sunflower_wilt_while_soil_is_wet_04';
  static const String wiltDuringDryHeat = 'sunflower_wilt_during_dry_heat_05';
  static const String stemCankerHollowOrWeak =
      'sunflower_stem_canker_hollow_or_weak_06';
  static const String lodgingLeaningOrBreakage =
      'sunflower_lodging_leaning_or_breakage_07';

  // Familia 3 — follaje y enfermedades foliares.
  static const String lowerLeafSpotsProgressing =
      'sunflower_lower_leaf_spots_progressing_08';
  static const String powderyWhiteGrowth = 'sunflower_powdery_white_growth_09';
  static const String downyMildewPattern = 'sunflower_downy_mildew_pattern_10';
  static const String rustPustules = 'sunflower_rust_pustules_11';
  static const String interveinalMottleAndWilt =
      'sunflower_interveinal_mottle_and_wilt_12';
  static const String lowerLeafYellowing =
      'sunflower_lower_leaf_yellowing_13';
  static const String leafEdgeScorch = 'sunflower_leaf_edge_scorch_14';
  static const String mosaicDistortionOrStunting =
      'sunflower_mosaic_distortion_or_stunting_15';

  // Familia 4 — plagas e invertebrados.
  static const String aphidColoniesHoneydew =
      'sunflower_aphid_colonies_honeydew_16';
  static const String miteStipplingAndWebbing =
      'sunflower_mite_stippling_and_webbing_17';
  static const String thripsOrSuckingScar =
      'sunflower_thrips_or_sucking_scar_18';
  static const String chewedHolesOrDefoliation =
      'sunflower_chewed_holes_or_defoliation_19';
  static const String stemCutAtSoilLine = 'sunflower_stem_cut_at_soil_line_20';
  static const String wildlifeHeadOrSeedlingDamage =
      'sunflower_wildlife_head_or_seedling_damage_21';

  // Familia 5 — botón, flor y capítulo.
  static const String budDelayedOrAbsent =
      'sunflower_bud_delayed_or_absent_22';
  static const String budAbortionOrDrying =
      'sunflower_bud_abortion_or_drying_23';
  static const String flowerMalformedOrAsymmetric =
      'sunflower_flower_malformed_or_asymmetric_24';
  static const String petalsBrowningOrGrayMold =
      'sunflower_petals_browning_or_gray_mold_25';
  static const String headWetSoftRot = 'sunflower_head_wet_soft_rot_26';
  static const String headDryShreddedOrMoldy =
      'sunflower_head_dry_shredded_or_moldy_27';
  static const String headDroopAfterBloom =
      'sunflower_head_droop_after_bloom_28';

  // Familia 6 — estrés abiótico y final normal del ciclo.
  static const String waterloggingYellowWilt =
      'sunflower_waterlogging_yellow_wilt_29';
  static const String droughtHeatTurgorLoss =
      'sunflower_drought_heat_turgor_loss_30';
  static const String sunscaldOrHeatInjury =
      'sunflower_sunscald_or_heat_injury_31';
  static const String coldOrFrostInjury = 'sunflower_cold_or_frost_injury_32';
  static const String saltOrFertilizerBurn =
      'sunflower_salt_or_fertilizer_burn_33';
  static const String compactionOrRootbound =
      'sunflower_compaction_or_rootbound_34';
  static const String nutrientLikePattern =
      'sunflower_nutrient_like_pattern_35';
  static const String normalSenescenceOrCycleEnd =
      'sunflower_normal_senescence_or_cycle_end_36';

  static const List<String> all = <String>[
    poorOrPatchyEmergence,
    seedlingCollapseAtSoilLine,
    rootCrownSoftDeterioration,
    wiltWhileSoilIsWet,
    wiltDuringDryHeat,
    stemCankerHollowOrWeak,
    lodgingLeaningOrBreakage,
    lowerLeafSpotsProgressing,
    powderyWhiteGrowth,
    downyMildewPattern,
    rustPustules,
    interveinalMottleAndWilt,
    lowerLeafYellowing,
    leafEdgeScorch,
    mosaicDistortionOrStunting,
    aphidColoniesHoneydew,
    miteStipplingAndWebbing,
    thripsOrSuckingScar,
    chewedHolesOrDefoliation,
    stemCutAtSoilLine,
    wildlifeHeadOrSeedlingDamage,
    budDelayedOrAbsent,
    budAbortionOrDrying,
    flowerMalformedOrAsymmetric,
    petalsBrowningOrGrayMold,
    headWetSoftRot,
    headDryShreddedOrMoldy,
    headDroopAfterBloom,
    waterloggingYellowWilt,
    droughtHeatTurgorLoss,
    sunscaldOrHeatInjury,
    coldOrFrostInjury,
    saltOrFertilizerBurn,
    compactionOrRootbound,
    nutrientLikePattern,
    normalSenescenceOrCycleEnd,
  ];
}
