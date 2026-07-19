/// Catálogo de riesgos, sanidad, estrés y memoria del Cactus (doc 04).
///
/// Contrato de seguridad (doc 04 §0.1, §2): BIO-G NO diagnostica patógenos, NO
/// prescribe plaguicidas ni dosis. El sensor por sí solo no genera un
/// `high_priority` sanitario. El lenguaje es "condición compatible", "revisa",
/// "confirma". Un evento de estrés NO es una etapa ni un diagnóstico.
///
/// Este archivo es el vocabulario estable (grupos, niveles, ids de riesgo y de
/// memoria). El motor de priorización/evidencia fino se conectará cuando el
/// hardware esté validado (doc 04 §5, §16); aquí quedan los contratos.
library;

/// Grupo del riesgo (doc 04 §4, §20.1).
enum CactusRiskGroup {
  rootCollar,
  waterSubstrate,
  salinityNutrition,
  climateLight,
  tissueStructure,
  establishment,
  pests,
  diseaseCompatible,
  dataQuality,
  safety,
}

/// Nivel de salida del riesgo (doc 04 §2.1, §20.1).
enum CactusRiskLevel { info, observation, warning, highPriority }

/// Estado de un evento en la memoria de estrés (doc 04 §14.4, §20.1).
enum CactusMemoryStatus {
  candidate,
  active,
  monitoring,
  improving,
  resolved,
  chronic,
  externallyConfirmed,
  dismissed,
}

/// Ids canónicos de riesgo (doc 04 §20.3). Se conservan idénticos para que el
/// motor de sanidad y el reporte los referencien sin duplicar.
class CactusRiskIds {
  const CactusRiskIds._();

  static const String prolongedWetRootZone = 'ca_prolonged_wet_root_zone';
  static const String drainageFailureSuspected =
      'ca_drainage_failure_suspected';
  static const String rootHypoxiaRisk = 'ca_root_hypoxia_risk';
  static const String repeatedOverwatering = 'ca_repeated_overwatering';
  static const String prolongedDryExposure = 'ca_prolonged_dry_exposure';
  static const String fastDryDownOrPoorWetting =
      'ca_fast_dry_down_or_poor_wetting';
  static const String coldWetExposure = 'ca_cold_wet_exposure';
  static const String substrateSaltAccumulation =
      'ca_substrate_salt_accumulation';
  static const String plantingTooDeep = 'ca_planting_too_deep';
  static const String postTransplantRootInjury =
      'ca_post_transplant_root_injury';
  static const String rootLossSuspected = 'ca_root_loss_suspected';
  static const String sunburnAcclimationRisk = 'ca_sunburn_acclimation_risk';
  static const String freezeInjuryRisk = 'ca_freeze_injury_risk';
  static const String heatDehydrationCompound = 'ca_heat_dehydration_compound';
  static const String lowLightEtiolation = 'ca_low_light_etiolation';
  static const String abruptEnvironmentChange = 'ca_abrupt_environment_change';
  static const String softOrWaterSoakedTissue =
      'ca_soft_or_water_soaked_tissue';
  static const String darkLesionOrExudate = 'ca_dark_lesion_or_exudate';
  static const String mechanicalWound = 'ca_mechanical_wound';
  static const String localizedCollapseOrLeaning =
      'ca_localized_collapse_or_leaning';
  static const String naturalCorkingPossible = 'ca_natural_corking_possible';
  static const String wrinklingOrTurgorLoss = 'ca_wrinkling_or_turgor_loss';
  static const String mealybugOrScaleSuspected =
      'ca_mealybug_or_scale_suspected';
  static const String rootMealybugSuspected = 'ca_root_mealybug_suspected';
  static const String spiderMiteSuspected = 'ca_spider_mite_suspected';
  static const String cactusLonghornBeetleSuspected =
      'ca_cactus_longhorn_beetle_suspected';
  static const String fungusGnatWetMediaIndicator =
      'ca_fungus_gnat_wet_media_indicator';
  static const String rootOrCrownRotCompatible =
      'ca_root_or_crown_rot_compatible';
  static const String internalSoftRotCompatible =
      'ca_internal_soft_rot_compatible';
  static const String fungalLesionCompatible = 'ca_fungal_lesion_compatible';
  static const String readingUnreliable = 'ca_reading_unreliable';

  static const List<String> all = <String>[
    prolongedWetRootZone,
    drainageFailureSuspected,
    rootHypoxiaRisk,
    repeatedOverwatering,
    prolongedDryExposure,
    fastDryDownOrPoorWetting,
    coldWetExposure,
    substrateSaltAccumulation,
    plantingTooDeep,
    postTransplantRootInjury,
    rootLossSuspected,
    sunburnAcclimationRisk,
    freezeInjuryRisk,
    heatDehydrationCompound,
    lowLightEtiolation,
    abruptEnvironmentChange,
    softOrWaterSoakedTissue,
    darkLesionOrExudate,
    mechanicalWound,
    localizedCollapseOrLeaning,
    naturalCorkingPossible,
    wrinklingOrTurgorLoss,
    mealybugOrScaleSuspected,
    rootMealybugSuspected,
    spiderMiteSuspected,
    cactusLonghornBeetleSuspected,
    fungusGnatWetMediaIndicator,
    rootOrCrownRotCompatible,
    internalSoftRotCompatible,
    fungalLesionCompatible,
    readingUnreliable,
  ];
}

/// Eventos de memoria de estrés (doc 04 §14.5). NO se guardan como diagnóstico
/// de patógeno: pudrición/hongo/bacteria solo pueden vivir como
/// `*_compatible` o `external_diagnosis_user_reported` (doc 04 §14.6).
class CactusMemoryEventIds {
  const CactusMemoryEventIds._();

  static const String installationOrRepot = 'installation_or_repot';
  static const String rootDisturbance = 'root_disturbance';
  static const String containerOrSubstrateChanged =
      'container_or_substrate_changed';
  static const String sensorRepositioned = 'sensor_repositioned';
  static const String abruptEnvironmentChange = 'abrupt_environment_change';
  static const String repeatedOverwatering = 'repeated_overwatering';
  static const String prolongedWetRootZone = 'prolonged_wet_root_zone';
  static const String slowDryDownRepeated = 'slow_dry_down_repeated';
  static const String fastDryDownRepeated = 'fast_dry_down_repeated';
  static const String prolongedDryHeat = 'prolonged_dry_heat';
  static const String coldWetExposure = 'cold_wet_exposure';
  static const String freezeExposure = 'freeze_exposure';
  static const String sunExposureChange = 'sun_exposure_change';
  static const String sunburnReported = 'sunburn_reported';
  static const String plantingTooDeepReported = 'planting_too_deep_reported';
  static const String mechanicalWound = 'mechanical_wound';
  static const String softTissueReported = 'soft_tissue_reported';
  static const String darkExudateReported = 'dark_exudate_reported';
  static const String collapseOrLeaning = 'collapse_or_leaning';
  static const String pestSuspected = 'pest_suspected';
  static const String pestUserConfirmed = 'pest_user_confirmed';
  static const String salinityEpisode = 'salinity_episode';
  static const String readingUnreliableRepeated = 'reading_unreliable_repeated';
  static const String recoveryEvidence = 'recovery_evidence';
}

/// Etiqueta humana para reportes. Un id desconocido nunca se expone en UI.
String cactusMemoryEventDisplayName(String id) {
  return switch (id.trim().toLowerCase()) {
    CactusMemoryEventIds.installationOrRepot => 'Plantación o cambio de maceta',
    CactusMemoryEventIds.rootDisturbance => 'Alteración de raíces',
    CactusMemoryEventIds.containerOrSubstrateChanged =>
      'Cambio de contenedor o sustrato',
    CactusMemoryEventIds.sensorRepositioned => 'Sensor reubicado',
    CactusMemoryEventIds.abruptEnvironmentChange => 'Cambio brusco de ambiente',
    CactusMemoryEventIds.repeatedOverwatering => 'Exceso de agua repetido',
    CactusMemoryEventIds.prolongedWetRootZone =>
      'Humedad prolongada en la raíz',
    CactusMemoryEventIds.slowDryDownRepeated => 'Secado lento repetido',
    CactusMemoryEventIds.fastDryDownRepeated => 'Secado rápido repetido',
    CactusMemoryEventIds.prolongedDryHeat => 'Sequedad y calor prolongados',
    CactusMemoryEventIds.coldWetExposure => 'Exposición a frío y humedad',
    CactusMemoryEventIds.freezeExposure => 'Exposición a helada',
    CactusMemoryEventIds.sunExposureChange => 'Cambio de exposición al sol',
    CactusMemoryEventIds.sunburnReported => 'Daño solar reportado',
    CactusMemoryEventIds.plantingTooDeepReported =>
      'Plantación profunda reportada',
    CactusMemoryEventIds.mechanicalWound => 'Herida mecánica',
    CactusMemoryEventIds.softTissueReported => 'Tejido blando reportado',
    CactusMemoryEventIds.darkExudateReported => 'Exudado oscuro reportado',
    CactusMemoryEventIds.collapseOrLeaning => 'Inclinación o colapso',
    CactusMemoryEventIds.pestSuspected => 'Plaga por confirmar',
    CactusMemoryEventIds.pestUserConfirmed => 'Plaga confirmada por el usuario',
    CactusMemoryEventIds.salinityEpisode => 'Episodio de salinidad',
    CactusMemoryEventIds.readingUnreliableRepeated =>
      'Lecturas poco confiables repetidas',
    CactusMemoryEventIds.recoveryEvidence => 'Evidencia de recuperación',
    _ => 'Evento ornamental registrado',
  };
}
