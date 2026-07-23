/// Catálogo de riesgos, sanidad y estrés del Rosal (Doc C).
///
/// Contrato de seguridad (Doc C §0): BIO-G NO diagnostica patógenos, NO prescribe
/// plaguicidas ni dosis. El sensor por sí solo no genera un `high_priority`
/// sanitario. El lenguaje es "condición compatible", "revisa", "confirma". Un
/// evento de estrés NO es una etapa ni un diagnóstico.
///
/// Este archivo es el vocabulario estable (grupos, niveles, urgencias e ids de
/// riesgo). El detalle clínico (síndromes S01–S16, diferenciales, señales) vive
/// en `lib/core/plant_health/catalog/rose_syndromes.dart`, que consume el motor
/// de sanidad compartido.
library;

/// Grupo del riesgo (Doc C §1–§4).
enum RoseRiskGroup {
  foliarDisease,
  flowerDisease,
  caneStructure,
  rootCollar,
  virusHighConsequence,
  pests,
  abioticStress,
  salinityNutrition,
  benignDifferential,
  dataQuality,
  safety,
}

/// Nivel de salida del riesgo (Doc C §24).
enum RoseRiskLevel { info, observation, warning, highPriority }

/// Urgencia recomendada (Doc C §24). El sensor nunca alcanza `immediate` por sí
/// solo: eso requiere confirmación externa/fitosanitaria.
enum RoseRiskUrgency { monitor72h, review48h, review24h, sameDay, immediate }

/// Ids canónicos de riesgo del rosal (Doc C §26). Se conservan idénticos para
/// que el motor de sanidad y el reporte los referencien sin duplicar.
class RoseRiskIds {
  const RoseRiskIds._();

  // Enfermedades foliares.
  static const String blackSpotCompatible = 'ro_black_spot_compatible';
  static const String powderyMildewCompatible = 'ro_powdery_mildew_compatible';
  static const String downyMildewCompatible = 'ro_downy_mildew_compatible';
  static const String rustCompatible = 'ro_rust_compatible';
  static const String otherLeafSpotPossible = 'ro_other_leaf_spot_possible';

  // Enfermedades de flor.
  static const String botrytisFlowerBlightCompatible =
      'ro_botrytis_flower_blight_compatible';

  // Caña y estructura.
  static const String cankerDiebackCompatible = 'ro_canker_dieback_compatible';
  static const String caneBorerOrGirdlerPossible =
      'ro_cane_borer_or_girdler_possible';

  // Raíz y cuello.
  static const String phytophthoraRootCrownRotCompatible =
      'ro_phytophthora_root_crown_rot_compatible';
  static const String otherRootRotPossible = 'ro_other_root_rot_possible';
  static const String crownGallCompatible = 'ro_crown_gall_compatible';

  // Virus de alta consecuencia.
  static const String rosetteDiseaseSuspicion = 'ro_rosette_disease_suspicion';
  static const String mosaicVirusComplexPossible =
      'ro_mosaic_virus_complex_possible';

  // Plagas.
  static const String aphidsPossible = 'ro_aphids_possible';
  static const String spiderMitesPossible = 'ro_spider_mites_possible';
  static const String thripsDamagePossible = 'ro_thrips_damage_possible';
  static const String midgeOrShootTipPestPossible =
      'ro_midge_or_shoot_tip_pest_possible';
  static const String scaleInsectsPossible = 'ro_scale_insects_possible';
  static const String mealybugPossible = 'ro_mealybug_possible';
  static const String sawflySlugPossible = 'ro_sawfly_slug_possible';
  static const String beetleOrChewerPossible = 'ro_beetle_or_chewer_possible';
  static const String sootyMoldSecondary = 'ro_sooty_mold_secondary';

  // Estrés abiótico.
  static const String coldInjuryPossible = 'ro_cold_injury_possible';
  static const String caneSunburnPossible = 'ro_cane_sunburn_possible';
  static const String droughtHeatScorchPossible =
      'ro_drought_heat_scorch_possible';
  static const String heatWaterStressBudPossible =
      'ro_heat_water_stress_bud_possible';
  static const String waterloggingRootAsphyxiaPossible =
      'ro_waterlogging_root_asphyxia_possible';
  static const String transplantStressPossible =
      'ro_transplant_stress_possible';
  static const String herbicideInjuryPossible = 'ro_herbicide_injury_possible';
  static const String sprayPhytotoxicityPossible =
      'ro_spray_phytotoxicity_possible';

  // Salinidad y nutrición.
  static const String salinityStressPossible = 'ro_salinity_stress_possible';
  static const String ironZincUnavailabilityPossible =
      'ro_iron_zinc_unavailability_possible';
  static const String nitrogenShortagePossible =
      'ro_nitrogen_shortage_possible';
  static const String rootDysfunctionPossible = 'ro_root_dysfunction_possible';

  // Calidad de dato.
  static const String readingUnreliable = 'ro_reading_unreliable';

  static const List<String> all = <String>[
    blackSpotCompatible,
    powderyMildewCompatible,
    downyMildewCompatible,
    rustCompatible,
    otherLeafSpotPossible,
    botrytisFlowerBlightCompatible,
    cankerDiebackCompatible,
    caneBorerOrGirdlerPossible,
    phytophthoraRootCrownRotCompatible,
    otherRootRotPossible,
    crownGallCompatible,
    rosetteDiseaseSuspicion,
    mosaicVirusComplexPossible,
    aphidsPossible,
    spiderMitesPossible,
    thripsDamagePossible,
    midgeOrShootTipPestPossible,
    scaleInsectsPossible,
    mealybugPossible,
    sawflySlugPossible,
    beetleOrChewerPossible,
    sootyMoldSecondary,
    coldInjuryPossible,
    caneSunburnPossible,
    droughtHeatScorchPossible,
    heatWaterStressBudPossible,
    waterloggingRootAsphyxiaPossible,
    transplantStressPossible,
    herbicideInjuryPossible,
    sprayPhytotoxicityPossible,
    salinityStressPossible,
    ironZincUnavailabilityPossible,
    nitrogenShortagePossible,
    rootDysfunctionPossible,
    readingUnreliable,
  ];
}
