/// Vocabulario de riesgos de la Sábila / Aloe (Documento C, SA v1.0).
///
/// Contrato de seguridad (Doc C §1): BIO-G NO diagnostica un organismo causal,
/// NO afirma "tiene pudrición", NO receta productos ni dosis y NO genera una
/// alerta sanitaria alta desde el sensor por sí solo. El lenguaje es "condición
/// compatible", "revisa", "confirma".
///
/// Este archivo es SOLO vocabulario estable: grupos, niveles y ids de riesgo. La
/// evaluación vive en el `PlantHealthRegistry` compartido
/// (`plant_health/catalog/aloe_syndromes.dart`).
///
/// NO existe memoria de estrés (Doc C §0.3: `supportsStressMemory = false`).
///
/// v1 NO incluye el síndrome de perforaciones/barrenado (SA-SYN-010 del Doc C):
/// su confianza para México es baja y se difiere.
library;

/// Grupo del riesgo (Doc C §5.1, orden de prioridad).
enum AloeRiskGroup {
  rootCollar,
  tissueIntegrity,
  gallMite,
  climateLight,
  pests,
  leafSpot,
  salinityNutrition,
  chemicalInjury,
  turgor,
  benignDifferential,
  dataQuality,
}

/// Nivel de salida del riesgo (Doc C §3).
enum AloeRiskLevel { info, observation, warning, highPriority }

/// Urgencia sugerida de REVISIÓN (Doc C §3). No es un diagnóstico ni una
/// predicción de muerte: ordena el tiempo de revisión.
enum AloeRiskUrgency { monitor72h, review48h, review24h, sameDay }

/// Ids canónicos de riesgo (Doc C §6). Los usa el catálogo de sanidad y el
/// reporte; ninguno se emite como clave del `AlertsEngine`.
///
/// SA-SYN-010 (perforaciones/barrenado) se difiere en v1: no se declara.
class AloeRiskIds {
  const AloeRiskIds._();

  static const String rootCollarCondition = 'sa_root_collar_condition';
  static const String softWaterSoakedTissue = 'sa_soft_water_soaked_tissue';
  static const String wartyGallDistortion = 'sa_warty_gall_distortion';
  static const String coldFrostInjury = 'sa_cold_frost_injury';
  static const String sunburnAcclimation = 'sa_sunburn_acclimation';
  static const String dryHardLeafSpot = 'sa_dry_hard_leaf_spot';
  static const String wetAdvancingLesion = 'sa_wet_advancing_lesion';
  static const String mealybugScaleSooty = 'sa_mealybug_scale_sooty';
  static const String spiderMiteStippling = 'sa_spider_mite_stippling';
  static const String saltFertilizerInjury = 'sa_salt_fertilizer_injury';
  static const String sprayInjury = 'sa_spray_injury';
  static const String etiolationLowLight = 'sa_etiolation_low_light';
  static const String wrinklingTurgorLoss = 'sa_wrinkling_turgor_loss';

  static const List<String> all = <String>[
    rootCollarCondition,
    softWaterSoakedTissue,
    wartyGallDistortion,
    coldFrostInjury,
    sunburnAcclimation,
    dryHardLeafSpot,
    wetAdvancingLesion,
    mealybugScaleSooty,
    spiderMiteStippling,
    saltFertilizerInjury,
    sprayInjury,
    etiolationLowLight,
    wrinklingTurgorLoss,
  ];
}

/// Diferenciales BENIGNOS (Doc C §7). Existen para NO alarmar: manchas blancas
/// juveniles, hojas inferiores secas, cera natural, cicatriz de corte de hoja,
/// color rojizo por luz, hijuelos, vara floral o mosquitas del sustrato no son
/// enfermedades.
class AloeBenignDifferentialIds {
  const AloeBenignDifferentialIds._();

  static const String juvenileWhiteSpots = 'sa_juvenile_white_spots';
  static const String lowerLeafSenescence = 'sa_lower_leaf_senescence';
  static const String naturalWaxBloom = 'sa_natural_wax_bloom';
  static const String leafCutScar = 'sa_leaf_cut_scar';
  static const String reddishSunStress = 'sa_reddish_sun_stress';
  static const String pupEmergence = 'sa_pup_emergence';
  static const String flowerStalk = 'sa_flower_stalk';
  static const String fungusGnatWetMedia = 'sa_fungus_gnat_wet_media';

  static const List<String> all = <String>[
    juvenileWhiteSpots,
    lowerLeafSenescence,
    naturalWaxBloom,
    leafCutScar,
    reddishSunStress,
    pupEmergence,
    flowerStalk,
    fungusGnatWetMedia,
  ];
}

/// Etiqueta humana del riesgo, para el reporte. Nunca se muestra el id crudo.
String aloeRiskDisplayName(String id) {
  return switch (id.trim().toLowerCase()) {
    AloeRiskIds.rootCollarCondition =>
      'Base o raíz con deterioro por confirmar',
    AloeRiskIds.softWaterSoakedTissue =>
      'Tejido blando o acuoso que requiere revisión',
    AloeRiskIds.wartyGallDistortion =>
      'Crecimiento deforme con verrugas por confirmar',
    AloeRiskIds.coldFrostInjury => 'Cambio de tejido compatible con frío',
    AloeRiskIds.sunburnAcclimation => 'Daño por sol o cambio de exposición',
    AloeRiskIds.dryHardLeafSpot => 'Manchas secas y duras en la hoja',
    AloeRiskIds.wetAdvancingLesion => 'Manchas empapadas que avanzan',
    AloeRiskIds.mealybugScaleSooty =>
      'Insectos visibles o superficie pegajosa',
    AloeRiskIds.spiderMiteStippling => 'Punteado fino o telaraña',
    AloeRiskIds.saltFertilizerInjury =>
      'Daño compatible con acumulación de sales',
    AloeRiskIds.sprayInjury =>
      'Daño compatible con un producto aplicado',
    AloeRiskIds.etiolationLowLight => 'Crecimiento alargado y débil',
    AloeRiskIds.wrinklingTurgorLoss => 'Hojas arrugadas o menos firmes',
    _ => 'Observación registrada',
  };
}
