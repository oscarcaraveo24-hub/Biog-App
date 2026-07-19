/// Vocabulario de riesgos de la Suculenta (Documento C, SU v1.0).
///
/// Contrato de seguridad (Doc C §1): BIO-G NO diagnostica un organismo causal,
/// NO afirma "tiene pudrición", NO receta productos ni dosis y NO genera una
/// alerta sanitaria alta desde el sensor por sí solo. El lenguaje es "condición
/// compatible", "revisa", "confirma".
///
/// Este archivo es SOLO vocabulario estable: grupos, niveles y ids de riesgo. La
/// evaluación vive en el `PlantHealthRegistry` compartido
/// (`plant_health/catalog/succulent_syndromes.dart`).
///
/// NO existe memoria de estrés (Doc C §0.3: `supportsStressMemory = false`). Por
/// eso este catálogo NO declara estados ni eventos de memoria: no se declara una
/// capacidad que nadie computa.
library;

/// Grupo del riesgo (Doc C §5.1, orden de prioridad).
enum SucculentRiskGroup {
  rootCollar,
  tissueIntegrity,
  waterSubstrate,
  salinityNutrition,
  climateLight,
  pests,
  surfaceGrowth,
  chemicalInjury,
  benignDifferential,
  dataQuality,
}

/// Nivel de salida del riesgo (Doc C §3).
enum SucculentRiskLevel { info, observation, warning, highPriority }

/// Urgencia sugerida de REVISIÓN (Doc C §3). No es un diagnóstico ni una
/// predicción de muerte: ordena el tiempo de revisión.
enum SucculentRiskUrgency { monitor72h, review48h, review24h, sameDay }

/// Ids canónicos de riesgo (Doc C §6). Los usa el catálogo de sanidad y el
/// reporte; ninguno se emite como clave del `AlertsEngine`.
class SucculentRiskIds {
  const SucculentRiskIds._();

  static const String rootCollarDeterioration = 'su_root_collar_deterioration';
  static const String softWaterSoakedTissue = 'su_soft_water_soaked_tissue';
  static const String wrinklingTurgorLoss = 'su_wrinkling_turgor_loss';
  static const String edemaCorkyBlisters = 'su_edema_corky_blisters';
  static const String etiolationLowLight = 'su_etiolation_low_light';
  static const String sunburnAcclimation = 'su_sunburn_acclimation';
  static const String coldFrostInjury = 'su_cold_frost_injury';
  static const String powderySurfaceGrowth = 'su_powdery_surface_growth';
  static const String leafSpotGrayMold = 'su_leaf_spot_gray_mold';
  static const String mealybugScale = 'su_mealybug_scale';
  static const String mitesThrips = 'su_mites_thrips';
  static const String saltFertilizerInjury = 'su_salt_fertilizer_injury';
  static const String phytotoxicitySprayInjury =
      'su_phytotoxicity_spray_injury';
  static const String fungusGnatWetMedia = 'su_fungus_gnat_wet_media';
  static const String prolongedWetRootZone = 'su_prolonged_wet_root_zone';
  static const String drainageFailureSuspected = 'su_drainage_failure_suspected';
  static const String prolongedDryExposure = 'su_prolonged_dry_exposure';
  static const String mechanicalDamage = 'su_mechanical_damage';
  static const String readingUnreliable = 'su_reading_unreliable';

  static const List<String> all = <String>[
    rootCollarDeterioration,
    softWaterSoakedTissue,
    wrinklingTurgorLoss,
    edemaCorkyBlisters,
    etiolationLowLight,
    sunburnAcclimation,
    coldFrostInjury,
    powderySurfaceGrowth,
    leafSpotGrayMold,
    mealybugScale,
    mitesThrips,
    saltFertilizerInjury,
    phytotoxicitySprayInjury,
    fungusGnatWetMedia,
    prolongedWetRootZone,
    drainageFailureSuspected,
    prolongedDryExposure,
    mechanicalDamage,
    readingUnreliable,
  ];
}

/// Diferenciales BENIGNOS (Doc C §7). Existen para NO alarmar: una o dos hojas
/// inferiores secas, la cera natural, el color rojo/morado por luz, una cicatriz
/// vieja o un tallo leñoso firme no son enfermedades.
class SucculentBenignDifferentialIds {
  const SucculentBenignDifferentialIds._();

  static const String lowerLeafSenescence = 'su_lower_leaf_senescence';
  static const String naturalWaxFarina = 'su_natural_wax_farina';
  static const String redPurplePigmentation = 'su_red_purple_pigmentation';
  static const String oldScarOrBurn = 'su_old_scar_or_burn';
  static const String woodyStemNormal = 'su_woody_stem_normal';
  static const String mechanicalLeafDrop = 'su_mechanical_leaf_drop';

  static const List<String> all = <String>[
    lowerLeafSenescence,
    naturalWaxFarina,
    redPurplePigmentation,
    oldScarOrBurn,
    woodyStemNormal,
    mechanicalLeafDrop,
  ];
}

/// Etiqueta humana del riesgo, para el reporte. Nunca se muestra el id crudo.
String succulentRiskDisplayName(String id) {
  return switch (id.trim().toLowerCase()) {
    SucculentRiskIds.rootCollarDeterioration =>
      'Base o raíz con deterioro por confirmar',
    SucculentRiskIds.softWaterSoakedTissue =>
      'Tejido blando o acuoso que requiere revisión',
    SucculentRiskIds.wrinklingTurgorLoss => 'Hojas arrugadas o menos firmes',
    SucculentRiskIds.edemaCorkyBlisters => 'Ampollas o costras por revisar',
    SucculentRiskIds.etiolationLowLight => 'Crecimiento nuevo estirado o pálido',
    SucculentRiskIds.sunburnAcclimation =>
      'Mancha compatible con quemadura de sol',
    SucculentRiskIds.coldFrostInjury => 'Cambio de tejido después de frío',
    SucculentRiskIds.powderySurfaceGrowth =>
      'Capa blanca que necesita identificación',
    SucculentRiskIds.leafSpotGrayMold => 'Manchas o moho en hojas y tallos',
    SucculentRiskIds.mealybugScale =>
      'Material algodonoso o escamas con insectos por confirmar',
    SucculentRiskIds.mitesThrips =>
      'Punteado o deformación con plaga pequeña por confirmar',
    SucculentRiskIds.saltFertilizerInjury =>
      'Daño compatible con acumulación de sales',
    SucculentRiskIds.phytotoxicitySprayInjury =>
      'Mancha compatible con daño por producto aplicado',
    SucculentRiskIds.fungusGnatWetMedia =>
      'Mosquitas asociadas con sustrato húmedo',
    SucculentRiskIds.prolongedWetRootZone => 'Sustrato húmedo por mucho tiempo',
    SucculentRiskIds.drainageFailureSuspected => 'El agua no está saliendo bien',
    SucculentRiskIds.prolongedDryExposure => 'Sequedad prolongada',
    SucculentRiskIds.mechanicalDamage => 'Daño por golpe o manipulación',
    SucculentRiskIds.readingUnreliable => 'Lectura poco confiable',
    _ => 'Observación registrada',
  };
}
