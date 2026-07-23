/// Catálogo de riesgos, sanidad y estrés del Tulipán (Documento C).
///
/// Contrato de seguridad (Documento C §4): BIO-G NO diagnostica patógenos, NO
/// prescribe plaguicidas ni dosis. Una lectura de sensor por sí sola nunca
/// genera un `high`/`critical` sanitario: se requiere una señal observada
/// fuerte. El lenguaje es "condición compatible", "revisa", "confirma". La
/// senescencia y la dormancia son procesos NORMALES, no enfermedad.
///
/// Este archivo es el VOCABULARIO estable (grupos, niveles, urgencias e ids de
/// riesgo). El detalle clínico (síndromes, diferenciales, señales, preguntas
/// de confirmación) vive en `lib/core/plant_health/catalog/tulip_syndromes.dart`,
/// que consume el motor de sanidad COMPARTIDO. Los ids aquí coinciden 1:1 con
/// los ids de síndrome para que el motor y el reporte los referencien sin
/// duplicar.
library;

/// Grupo del riesgo (Documento C §0, §7).
enum TulipRiskGroup {
  bulbRootDisease,
  foliarFlowerDisease,
  virusHighConsequence,
  pests,
  abioticStress,
  physiologicalDisorder,
  wildlifePhysicalDamage,
  managementRisk,
  benignProcess,
  dataQuality,
}

/// Nivel de salida del riesgo (Documento C §4.4). El sensor nunca alcanza los
/// niveles altos por sí solo: eso requiere una señal observada.
enum TulipRiskLevel { normal, watch, review, highPriority, separateAndEscalate }

/// Urgencia recomendada (Documento C §4.4). El sensor nunca alcanza `immediate`
/// por sí solo: requiere confirmación externa/fitosanitaria.
enum TulipRiskUrgency { monitor72h, review48h, review24h, sameDay, immediate }

/// Ids canónicos de riesgo/síndrome del tulipán (Documento C §9, §13.4). Se
/// conservan idénticos a los ids del catálogo de síndromes.
class TulipRiskIds {
  const TulipRiskIds._();

  // P0 — obligatorios para la primera integración.
  static const String naturalSenescenceDormancy =
      'tulip_natural_senescence_dormancy_01';
  static const String bulbSoftWatery = 'tulip_bulb_soft_watery_01';
  static const String basalDryRot = 'tulip_basal_dry_rot_01';
  static const String poorOrFailedEmergence = 'tulip_poor_or_failed_emergence_01';
  static const String glassyBrownRoots = 'tulip_glassy_brown_roots_01';
  static const String fireGrayMold = 'tulip_fire_gray_mold_01';
  static const String budAbortionNoFlower = 'tulip_bud_abortion_no_flower_01';
  static const String stemLeafTopple = 'tulip_stem_leaf_topple_01';
  static const String prematureYellowingChlorosis =
      'tulip_premature_yellowing_chlorosis_01';

  // P1 — importantes para una v1 completa.
  static const String storageBlueMold = 'tulip_storage_blue_mold_01';
  static const String subterraneanShootRot = 'tulip_subterranean_shoot_rot_01';
  static const String viralBreakMosaic = 'tulip_viral_break_mosaic_01';
  static const String aphidHoneydew = 'tulip_aphid_honeydew_01';
  static const String ethyleneStorageDamage = 'tulip_ethylene_storage_damage_01';
  static const String weakElongatedLeaning = 'tulip_weak_elongated_leaning_01';
  static const String frostInjury = 'tulip_frost_injury_01';
  static const String heatShortBloom = 'tulip_heat_short_bloom_01';
  static const String saltRootBurn = 'tulip_salt_root_burn_01';
  static const String edemaWaterImbalance = 'tulip_edema_water_imbalance_01';
  static const String foliageCutEarlyRechargeRisk =
      'tulip_foliage_cut_early_recharge_risk_01';
  static const String physicalWeatherPetalDamage =
      'tulip_physical_weather_petal_damage_01';
  static const String wildlifeFeedingExcavation =
      'tulip_wildlife_feeding_excavation_01';

  // P2 — ampliación (señales difíciles de confirmar en casa).
  static const String bulbMiteDamage = 'tulip_bulb_mite_damage_01';
  static const String stemBulbNematode = 'tulip_stem_bulb_nematode_01';

  static const List<String> all = <String>[
    naturalSenescenceDormancy,
    bulbSoftWatery,
    basalDryRot,
    poorOrFailedEmergence,
    glassyBrownRoots,
    fireGrayMold,
    budAbortionNoFlower,
    stemLeafTopple,
    prematureYellowingChlorosis,
    storageBlueMold,
    subterraneanShootRot,
    viralBreakMosaic,
    aphidHoneydew,
    ethyleneStorageDamage,
    weakElongatedLeaning,
    frostInjury,
    heatShortBloom,
    saltRootBurn,
    edemaWaterImbalance,
    foliageCutEarlyRechargeRisk,
    physicalWeatherPetalDamage,
    wildlifeFeedingExcavation,
    bulbMiteDamage,
    stemBulbNematode,
  ];
}
