/// Vocabulario de riesgos del Nopal (Documento C, NO v1.0).
///
/// Contrato de seguridad (Doc C §1): BIO-G NO diagnostica un organismo causal,
/// NO afirma "tiene mancha negra" ni "tiene cochinilla", NO receta productos ni
/// dosis, NO certifica comestibilidad de una penca o una tuna y NO genera una
/// alerta sanitaria alta desde el sensor por sí solo. El lenguaje es "condición
/// compatible con", "posible", "por confirmar", "revisa".
///
/// Este archivo es SOLO vocabulario estable: grupos, niveles e ids de riesgo. La
/// evaluación vive en el `PlantHealthRegistry` compartido
/// (`plant_health/catalog/nopal_syndromes.dart`).
///
/// NO existe memoria de estrés (Doc A §2.8: `supportsStressMemory = false`).
///
/// v1 incluye los 18 síndromes observables del Doc C §6 (S01..S18). Ninguno se
/// difiere. El corte manual de una penca, la floración y la aparición de tunas
/// NO son enfermedades (Doc C §0).
library;

/// Grupo del riesgo (Doc C §6, orden de precedencia).
enum NopalRiskGroup {
  rootCrown,
  tissueIntegrity,
  cankerExudate,
  surfaceLesion,
  systemicPattern,
  scaleInsect,
  suckingInsect,
  borerHighConsequence,
  chewingDamage,
  mite,
  climateStress,
  salinityNutrition,
  mechanicalWound,
  growthDeficit,
  benignDifferential,
  dataQuality,
}

/// Nivel de salida del riesgo (Doc C §1).
enum NopalRiskLevel { info, observation, warning, highPriority }

/// Urgencia sugerida de REVISIÓN (Doc C §1). No es un diagnóstico ni una
/// predicción de muerte: ordena el tiempo de revisión.
enum NopalRiskUrgency { monitor72h, review48h, review24h, sameDay }

/// Ids canónicos de riesgo (Doc C §6). Los usa el catálogo de sanidad y el
/// reporte; ninguno se emite como clave del `AlertsEngine`.
class NopalRiskIds {
  const NopalRiskIds._();

  static const String blackMapSpots = 'no_black_map_spots';
  static const String raisedBlackScab = 'no_raised_black_scab';
  static const String cankerCrackExudate = 'no_canker_crack_exudate';
  static const String softWaterSoakedTissue = 'no_soft_water_soaked_tissue';
  static const String rootCollarDecline = 'no_root_collar_decline';
  static const String chloroticRingsMosaic = 'no_chlorotic_rings_mosaic';
  static const String whiteCottonWax = 'no_white_cotton_wax';
  static const String suckingBlotches = 'no_sucking_blotches';
  static const String eggRowHollowPad = 'no_egg_row_hollow_pad';
  static const String chewingGalleries = 'no_chewing_galleries';
  static const String stipplingBronzingDeformity =
      'no_stippling_bronzing_deformity';
  static const String shrivelTurgorLoss = 'no_shrivel_turgor_loss';
  static const String sunscald = 'no_sunscald';
  static const String coldInjury = 'no_cold_injury';
  static const String mechanicalWound = 'no_mechanical_wound';
  static const String etiolatedNewPads = 'no_etiolated_new_pads';
  static const String chlorosisDryMargin = 'no_chlorosis_dry_margin';
  static const String witchesBroom = 'no_witches_broom';

  static const List<String> all = <String>[
    blackMapSpots,
    raisedBlackScab,
    cankerCrackExudate,
    softWaterSoakedTissue,
    rootCollarDecline,
    chloroticRingsMosaic,
    whiteCottonWax,
    suckingBlotches,
    eggRowHollowPad,
    chewingGalleries,
    stipplingBronzingDeformity,
    shrivelTurgorLoss,
    sunscald,
    coldInjury,
    mechanicalWound,
    etiolatedNewPads,
    chlorosisDryMargin,
    witchesBroom,
  ];

  /// Riesgos de ALTA CONSECUENCIA fitosanitaria (Doc C §1.6, §1.7). No implican
  /// cuarentena declarada por BIO-G ni destrucción automática: activan lenguaje
  /// de NO MOVER material y de buscar revisión de la autoridad vegetal local.
  static const Set<String> highConsequence = <String>{eggRowHollowPad};
}

/// Diferenciales BENIGNOS (Doc C §7 y siguientes). Existen para NO alarmar: el
/// corchado de la base vieja, una cicatriz firme, los gloquidios normales, una
/// penca joven tierna, el color morado estacional y el encogimiento invernal de
/// un nopal rastrero no son enfermedades.
class NopalBenignDifferentialIds {
  const NopalBenignDifferentialIds._();

  static const String normalCorking = 'no_normal_corking';
  static const String stableScar = 'no_stable_scar';
  static const String normalGlochidTuft = 'no_normal_glochid_tuft';
  static const String tenderYoungPad = 'no_tender_young_pad';
  static const String seasonalPurpling = 'no_seasonal_purpling';
  static const String winterShriveling = 'no_winter_shriveling';
  static const String cleanCutHealing = 'no_clean_cut_healing';

  static const List<String> all = <String>[
    normalCorking,
    stableScar,
    normalGlochidTuft,
    tenderYoungPad,
    seasonalPurpling,
    winterShriveling,
    cleanCutHealing,
  ];
}

/// Etiqueta humana del riesgo, para el reporte. Nunca se muestra el id crudo.
String nopalRiskDisplayName(String id) {
  return switch (id.trim().toLowerCase()) {
    NopalRiskIds.blackMapSpots =>
      'Manchas negras redondas o con forma de mapa por confirmar',
    NopalRiskIds.raisedBlackScab =>
      'Costras oscuras, elevadas o secas sobre la penca',
    NopalRiskIds.cankerCrackExudate =>
      'Grieta, lesión seca o líquido oscuro en una penca',
    NopalRiskIds.softWaterSoakedTissue => 'Tejido blando, acuoso o hundido',
    NopalRiskIds.rootCollarDecline =>
      'Pérdida de soporte o decaimiento desde la base',
    NopalRiskIds.chloroticRingsMosaic =>
      'Círculos amarillos, mosaico o manchas cloróticas',
    NopalRiskIds.whiteCottonWax => 'Algodón blanco o cera pegada a la penca',
    NopalRiskIds.suckingBlotches =>
      'Manchas pálidas o cafés alrededor de puntos de alimentación',
    NopalRiskIds.eggRowHollowPad =>
      'Hilera de huevos, excremento y penca hueca: requiere descartar plaga de '
          'importancia fitosanitaria',
    NopalRiskIds.chewingGalleries =>
      'Bordes mordidos, galerías o agujeros en la penca',
    NopalRiskIds.stipplingBronzingDeformity =>
      'Punteado, bronceado o deformación compatibles con artrópodo',
    NopalRiskIds.shrivelTurgorLoss =>
      'Arrugamiento, pérdida de firmeza o inclinación',
    NopalRiskIds.sunscald => 'Quemadura por sol o cambio brusco de exposición',
    NopalRiskIds.coldInjury => 'Daño por frío o helada',
    NopalRiskIds.mechanicalWound => 'Herida, golpe, granizo o corte',
    NopalRiskIds.etiolatedNewPads =>
      'Pencas nuevas largas, delgadas o pálidas por poca luz',
    NopalRiskIds.chlorosisDryMargin =>
      'Clorosis, borde seco y crecimiento débil por confirmar',
    NopalRiskIds.witchesBroom =>
      'Muchos brotes cortos desde un punto o deformación tipo escoba',
    _ => 'Observación registrada',
  };
}

/// True si el riesgo exige lenguaje de no movimiento y revisión oficial
/// (Doc C §1.6). BIO-G NO declara una plaga cuarentenaria ni denuncia: pide no
/// mover pencas ni material y buscar identificación de la autoridad local.
bool isNopalHighConsequenceRisk(String id) =>
    NopalRiskIds.highConsequence.contains(id.trim().toLowerCase());
