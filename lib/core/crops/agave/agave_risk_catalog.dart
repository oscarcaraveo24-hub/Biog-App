/// Vocabulario de riesgos del Maguey / Agave (Documento C, MG v1.0).
///
/// Contrato de seguridad (Doc C §2): BIO-G NO diagnostica un organismo causal,
/// NO afirma "tiene pudrición" ni "es picudo", NO receta productos ni dosis, NO
/// recomienda cortar el quiote y NO genera una alerta sanitaria alta desde el
/// sensor por sí solo. El lenguaje es "compatible con", "por confirmar",
/// "revisa".
///
/// Este archivo es SOLO vocabulario estable: grupos, niveles e ids de riesgo. La
/// evaluación vive en el `PlantHealthRegistry` compartido
/// (`plant_health/catalog/agave_syndromes.dart`).
///
/// NO existe memoria de estrés (Doc C §0.3: `supportsStressMemory = false`).
///
/// v1 incluye los 17 síndromes del Doc C §6 (MG-SYN-001..017): ninguno se
/// difiere. El quiote y la senescencia postfloración NO son enfermedades
/// (Doc C §0.2 #6, §7.6).
library;

/// Grupo del riesgo (Doc C §5, orden de precedencia).
enum AgaveRiskGroup {
  rootCrown,
  tissueIntegrity,
  wiltDryBud,
  borerWeevil,
  mite,
  scaleInsect,
  plantBug,
  leafLesion,
  climateStress,
  salinityNutrition,
  mechanicalWound,
  animalDamage,
  floweringSenescence,
  benignDifferential,
  dataQuality,
}

/// Nivel de salida del riesgo (Doc C §3).
enum AgaveRiskLevel { info, observation, warning, highPriority }

/// Urgencia sugerida de REVISIÓN (Doc C §3). No es un diagnóstico ni una
/// predicción de muerte: ordena el tiempo de revisión.
enum AgaveRiskUrgency { monitor72h, review48h, review24h, sameDay }

/// Ids canónicos de riesgo (Doc C §6). Los usa el catálogo de sanidad y el
/// reporte; ninguno se emite como clave del `AlertsEngine`.
class AgaveRiskIds {
  const AgaveRiskIds._();

  static const String rootCrownCondition = 'mg_root_crown_condition';
  static const String softWaterSoakedTissue = 'mg_soft_water_soaked_tissue';
  static const String wiltDryBudAnchorLoss = 'mg_wilt_dry_bud_anchor_loss';
  static const String snoutWeevilBoring = 'mg_snout_weevil_boring';
  static const String miteGreasyStreak = 'mg_mite_greasy_streak';
  static const String softScaleWaxy = 'mg_soft_scale_waxy';
  static const String plantBugScar = 'mg_plant_bug_scar';
  static const String anthracnoseLesion = 'mg_anthracnose_lesion';
  static const String graySpotLesion = 'mg_gray_spot_lesion';
  static const String coldFrostInjury = 'mg_cold_frost_injury';
  static const String sunburnHeat = 'mg_sunburn_heat';
  static const String mechanicalWound = 'mg_mechanical_wound';
  static const String saltFertilizerInjury = 'mg_salt_fertilizer_injury';
  static const String animalDamage = 'mg_animal_damage';
  static const String flowerStalkTransition = 'mg_flower_stalk_transition';
  static const String postFloweringSenescence = 'mg_post_flowering_senescence';
  static const String benignNaturalChange = 'mg_benign_natural_change';

  static const List<String> all = <String>[
    rootCrownCondition,
    softWaterSoakedTissue,
    wiltDryBudAnchorLoss,
    snoutWeevilBoring,
    miteGreasyStreak,
    softScaleWaxy,
    plantBugScar,
    anthracnoseLesion,
    graySpotLesion,
    coldFrostInjury,
    sunburnHeat,
    mechanicalWound,
    saltFertilizerInjury,
    animalDamage,
    flowerStalkTransition,
    postFloweringSenescence,
    benignNaturalChange,
  ];
}

/// Diferenciales BENIGNOS (Doc C §7). Existen para NO alarmar: una hoja basal
/// vieja y seca, improntas de dientes, cera glauca uniforme, variegación
/// estable, hijuelos, el quiote y una cicatriz firme no son enfermedades.
class AgaveBenignDifferentialIds {
  const AgaveBenignDifferentialIds._();

  static const String basalLeafDry = 'mg_basal_leaf_dry';
  static const String leafImprint = 'mg_leaf_imprint';
  static const String glaucousWax = 'mg_glaucous_wax';
  static const String variegation = 'mg_variegation';
  static const String offsetPup = 'mg_offset_pup';
  static const String flowerStalk = 'mg_flower_stalk';
  static const String stableScar = 'mg_stable_scar';

  static const List<String> all = <String>[
    basalLeafDry,
    leafImprint,
    glaucousWax,
    variegation,
    offsetPup,
    flowerStalk,
    stableScar,
  ];
}

/// Etiqueta humana del riesgo, para el reporte. Nunca se muestra el id crudo.
String agaveRiskDisplayName(String id) {
  return switch (id.trim().toLowerCase()) {
    AgaveRiskIds.rootCrownCondition =>
      'Base, raíz o cogollo con deterioro por confirmar',
    AgaveRiskIds.softWaterSoakedTissue =>
      'Tejido blando, húmedo o acuoso que requiere revisión',
    AgaveRiskIds.wiltDryBudAnchorLoss =>
      'Marchitez o pudrición seca del cogollo por confirmar',
    AgaveRiskIds.snoutWeevilBoring =>
      'Picudo del agave o barrenado interno por confirmar',
    AgaveRiskIds.miteGreasyStreak =>
      'Raya grasosa y centro deformado compatibles con ácaro del agave',
    AgaveRiskIds.softScaleWaxy =>
      'Escama blanda o material ceroso con insectos por confirmar',
    AgaveRiskIds.plantBugScar =>
      'Cicatrices superficiales compatibles con chinche del agave',
    AgaveRiskIds.anthracnoseLesion =>
      'Lesiones hundidas compatibles con antracnosis',
    AgaveRiskIds.graySpotLesion => 'Mancha gris o tizón foliar por confirmar',
    AgaveRiskIds.coldFrostInjury => 'Daño por frío o helada',
    AgaveRiskIds.sunburnHeat =>
      'Quemadura por sol, calor o cambio brusco de exposición',
    AgaveRiskIds.mechanicalWound => 'Herida, golpe, granizo o retiro de hijuelo',
    AgaveRiskIds.saltFertilizerInjury =>
      'Daño compatible con sales o fertilización',
    AgaveRiskIds.animalDamage => 'Mordedura o daño por animales',
    AgaveRiskIds.flowerStalkTransition => 'Tallo floral o quiote observado',
    AgaveRiskIds.postFloweringSenescence =>
      'Senescencia de la roseta madre después de floración',
    AgaveRiskIds.benignNaturalChange => 'Cambio natural o cicatriz estable',
    _ => 'Observación registrada',
  };
}
