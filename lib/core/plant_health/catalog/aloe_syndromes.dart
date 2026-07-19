import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Sanidad de la Sábila / Aloe ornamental (Documento C, SA v1.0).
///
/// Contrato de seguridad (Doc C §1) — inviolable:
/// - BIO-G **no** diagnostica un organismo causal (ni hongo, ni bacteria, ni
///   plaga) y **no** dice "tiene pudrición" como hecho confirmado.
/// - **No** receta productos, ingredientes activos ni dosis.
/// - El sensor por sí solo **nunca** genera una alerta sanitaria alta: los
///   síndromes requieren observación del usuario.
/// - Ante dos explicaciones plausibles, se prioriza la revisión que evite
///   agravar el daño (hojas arrugadas + sustrato húmedo ⇒ NO sugerir riego).
/// - Sensor solo → máximo nivel `observation` (Doc C §2).
///
/// Estructura copiada de `succulent_syndromes.dart`; textos e ids son propios.
///
/// v1 tiene **13 síndromes** (SA-SYN-001..014 sin el 010): el síndrome de
/// perforaciones/barrenado (SA-SYN-010) se difiere por baja confianza para
/// México (Doc C §6, decisión de producto).
///
/// Cuatro aportes propios frente a la suculenta (Doc C §0):
///  1. Ácaro de agalla (`aloe_warty_gall_distortion_01`): daño que NO se
///     revierte; la acción base es retirar y aislar, no revisar y esperar.
///  2. Pregunta seca/empapada: separa manchas secas (observation) de lesión
///     húmeda que avanza (warning) por tacto.
///  3. Regla anti-alarma de la roya: las manchas secas nunca escalan solas.
///  4. Inversión del cuadro hídrico: "sedienta con el suelo mojado" impide el
///     riego (apunta a la raíz).
const Set<PlantHealthStageBucket> _aloeStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.lateSeason,
};

const String _aloeDisclaimer =
    'BIO-G organiza observaciones y contexto para orientar la revisión. '
    'No confirma una enfermedad, una plaga ni un organismo causal.';

const List<PlantHealthSyndrome> aloeSyndromes = <PlantHealthSyndrome>[
  // ── SA-SYN-001 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'aloe_root_collar_condition_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Base o raíz con deterioro por confirmar',
    stages: _aloeStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAloeRootCollarCondition,
    strongSignals: <String>{
      PlantHealthIds.signalAloeSoftOrWatery,
      PlantHealthIds.signalAloeProgressing,
      PlantHealthIds.signalAloeLossOfSupport,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalAloeWrinkling,
      PlantHealthIds.signalAloeFungusGnats,
      PlantHealthIds.signalAloeAbnormalOdor,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeFirmDry,
      PlantHealthIds.signalAloeStable,
      PlantHealthIds.signalAloeLowerLeavesOnly,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_root_collar_deterioration_compatible',
        labelEs: 'Condición compatible con deterioro de raíz o cuello',
        type: 'condition_compatible',
        summaryEs:
            'La apariencia de sed también aparece cuando la raíz ya no '
            'funciona. Antes de regar, revisa la base, el drenaje y la humedad '
            'real. Estos datos no identifican una causa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeSoftOrWatery,
          PlantHealthIds.signalAloeProgressing,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAloeFirmDry,
          PlantHealthIds.signalAloeStable,
        },
      ),
      PlantHealthDiagnosis(
        id: 'aloe_transplant_stress_possible',
        labelEs: 'Estrés de trasplante o anclaje por confirmar',
        type: 'visual_concern',
        summaryEs:
            'Un cambio de maceta reciente, una raíz lastimada o una maceta '
            'inestable pueden producir un cuadro parecido sin que exista '
            'enfermedad.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La base está firme o blanda?',
      '¿El sustrato sigue húmedo?',
      '¿La planta se mueve fácilmente en la maceta?',
      '¿El cambio está avanzando?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Revisa que el agua pueda salir libremente.',
      'Evita agregar más agua mientras el sustrato siga húmedo.',
      'Mantén la planta separada si hay tejido alterado o insectos.',
      'Busca evaluación local si la base pierde firmeza o la planta se afloja.',
    ],
    disclaimerEs: _aloeDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── SA-SYN-002 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'aloe_soft_water_soaked_tissue_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Tejido blando o acuoso que requiere revisión',
    stages: _aloeStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAloeSoftWaterSoakedTissue,
    strongSignals: <String>{
      PlantHealthIds.signalAloeSoftOrWatery,
      PlantHealthIds.signalAloeProgressing,
      PlantHealthIds.signalAloeLossOfSupport,
      PlantHealthIds.signalAloeAbnormalOdor,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeFirmDry,
      PlantHealthIds.signalAloeStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_internal_tissue_damage_compatible',
        labelEs: 'Condición compatible con daño interno activo',
        type: 'condition_compatible',
        summaryEs:
            'El tejido blando y acuoso necesita revisión prioritaria. BIO-G no '
            'puede confirmar la causa, pero sí reconocer que el cambio está '
            'activo. El frío y el exceso de agua producen cuadros parecidos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeProgressing,
          PlantHealthIds.signalAloeAbnormalOdor,
          PlantHealthIds.signalAloeLossOfSupport,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAloeFirmDry,
          PlantHealthIds.signalAloeStable,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El tejido cede o escurre al tocarlo?',
      '¿El cambio avanza de un día a otro?',
      '¿Hubo frío reciente o el sustrato quedó encharcado?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Aísla la planta si el tejido blando avanza.',
      'No riegues mientras el tejido siga blando o el sustrato húmedo.',
      'Retira con cuidado el material claramente colapsado si puedes hacerlo '
          'sin dañar el resto.',
      'Busca evaluación local si el cambio se extiende rápido.',
    ],
    disclaimerEs: _aloeDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── SA-SYN-003 ★ EXCLUSIVO DE SÁBILA ───────────────────────────────────────
  PlantHealthSyndrome(
    id: 'aloe_warty_gall_distortion_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Crecimiento deforme con verrugas por confirmar',
    stages: _aloeStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAloeWartyGallDistortion,
    strongSignals: <String>{
      PlantHealthIds.signalAloeWartyGrowth,
      PlantHealthIds.signalAloeCrookedFlowerStalk,
      PlantHealthIds.signalAloeProgressing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAloeTouchingAnotherAloe,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeStable,
      PlantHealthIds.signalAloeFineStippling,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_gall_mite_compatible',
        labelEs: 'Condición compatible con ácaro de agalla del aloe',
        type: 'condition_compatible',
        summaryEs:
            'Las verrugas o masas rugosas que avanzan, y una vara floral '
            'torcida o crespa, son compatibles con el ácaro de agalla. Este '
            'daño no se revierte y puede pasar por el aire a otras sábilas '
            'cercanas. BIO-G no confirma el organismo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeWartyGrowth,
          PlantHealthIds.signalAloeCrookedFlowerStalk,
          PlantHealthIds.signalAloeProgressing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAloeStable,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El crecimiento deforme está aumentando?',
      '¿La vara floral salió torcida o crespa?',
      '¿La planta toca o está junto a otras sábilas?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Separa esta planta de otras sábilas o aloes: el daño puede propagarse.',
      'Este cambio no se revierte; la parte deforme no vuelve a su forma.',
      'Evita mover herramientas o manos entre esta planta y las sanas sin '
          'limpiarlas.',
      'Busca evaluación local si el daño avanza o aparece en varias plantas.',
    ],
    disclaimerEs: _aloeDisclaimer,
    favorsVectorPressure: true,
  ),

  // ── SA-SYN-004 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'aloe_cold_frost_injury_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Cambio de tejido compatible con frío',
    stages: _aloeStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAloeColdTissueChange,
    strongSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalAloeGlassyTranslucent,
      PlantHealthIds.signalAloeReddishBrownBase,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAloeSoftOrWatery,
      PlantHealthIds.signalAloeProgressing,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeSunnySide,
      PlantHealthIds.signalHeatStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_cold_injury_compatible',
        labelEs: 'Condición compatible con daño por frío',
        type: 'condition_compatible',
        summaryEs:
            'Un tejido vidrioso o traslúcido y una base rojiza tras una noche '
            'fría son compatibles con daño por frío. La sábila es poco '
            'resistente a la helada. El frío con sustrato húmedo es el peor '
            'caso.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalAloeGlassyTranslucent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAloeSunnySide,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo una noche fría o helada reciente?',
      '¿El tejido se ve vidrioso o traslúcido?',
      '¿El daño está colapsando o avanzando?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Protégela del frío y no la riegues mientras el sustrato siga húmedo.',
      'Espera a ver si el daño se estabiliza antes de retirar tejido.',
      'Si la base se ablanda tras el frío, trátala como revisión de base y '
          'raíz.',
    ],
    disclaimerEs: _aloeDisclaimer,
    favorsRecentStress: true,
  ),

  // ── SA-SYN-005 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'aloe_sunburn_acclimation_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Daño por sol o cambio de exposición',
    stages: _aloeStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAloeSunburnPatch,
    strongSignals: <String>{
      PlantHealthIds.signalAloeSunnySide,
      PlantHealthIds.signalAloeChangedSunExposure,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAloeStable,
      PlantHealthIds.signalHeatStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeProgressing,
      PlantHealthIds.signalAloeSoftOrWatery,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_sunburn_compatible',
        labelEs: 'Condición compatible con quemadura de sol',
        type: 'condition_compatible',
        summaryEs:
            'Una mancha seca del lado soleado, sobre todo tras mover la planta '
            'a más sol, es compatible con quemadura. El tejido dañado no se '
            'recupera, pero la planta sigue.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeSunnySide,
          PlantHealthIds.signalAloeChangedSunExposure,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La mancha mira hacia el lado del sol?',
      '¿La planta recibió más sol que antes?',
      '¿La mancha está seca y estable, sin avanzar?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Si la moviste a más sol, dale sombra parcial unos días para aclimatarla.',
      'La marca seca no se borra, pero no suele avanzar.',
      'Registra y compara: si la zona empieza a ablandarse, cambia la revisión.',
    ],
    disclaimerEs: _aloeDisclaimer,
  ),

  // ── SA-SYN-006 ─────────────────────────────────────────────────────────────
  // Regla anti-alarma: NUNCA escala a alto por sí solo (la roya no mata).
  PlantHealthSyndrome(
    id: 'aloe_dry_hard_leaf_spot_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Manchas secas y duras en la hoja',
    stages: _aloeStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAloeDryHardLeafSpot,
    strongSignals: <String>{
      PlantHealthIds.signalAloeDryHardSpots,
      PlantHealthIds.signalAloeStable,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAloeLeafCutRecent,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeWetAdvancingLesion,
      PlantHealthIds.signalAloeSoftOrWatery,
      PlantHealthIds.signalAloeProgressing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_dry_leaf_spot_compatible',
        labelEs: 'Mancha seca y estable, de bajo riesgo',
        type: 'visual_concern',
        summaryEs:
            'Las manchas secas y duras que no avanzan son de bajo riesgo. El '
            'crecimiento nuevo suele salir limpio. La clave es el tacto: seca '
            'y firme, no empapada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeDryHardSpots,
          PlantHealthIds.signalAloeStable,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAloeWetAdvancingLesion,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La mancha se siente seca y dura al tacto?',
      '¿La mancha lleva tiempo igual, sin crecer?',
      '¿El crecimiento nuevo sale limpio?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Registra la mancha y compárala en unos días.',
      'Si se siente seca y no avanza, no requiere acción urgente.',
      'Evita mojar las hojas de noche, sobre todo si conviven varias plantas.',
    ],
    disclaimerEs: _aloeDisclaimer,
  ),

  // ── SA-SYN-007 ─────────────────────────────────────────────────────────────
  // Se separa de SA-SYN-006 por el tacto: empapada y avanza.
  PlantHealthSyndrome(
    id: 'aloe_wet_advancing_lesion_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Manchas empapadas que avanzan',
    stages: _aloeStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomAloeWetAdvancingLesion,
    strongSignals: <String>{
      PlantHealthIds.signalAloeWetAdvancingLesion,
      PlantHealthIds.signalAloeProgressing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalAloeSoftOrWatery,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeDryHardSpots,
      PlantHealthIds.signalAloeStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_wet_lesion_compatible',
        labelEs: 'Condición compatible con lesión húmeda activa',
        type: 'condition_compatible',
        summaryEs:
            'Una mancha empapada que crece de un día a otro necesita revisión. '
            'BIO-G no confirma la causa, pero el tacto húmedo y el avance la '
            'separan de una mancha seca de bajo riesgo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeWetAdvancingLesion,
          PlantHealthIds.signalAloeProgressing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAloeDryHardSpots,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La mancha se siente empapada al tacto?',
      '¿Está creciendo de un día a otro?',
      '¿El sustrato o las hojas se mantienen húmedos mucho tiempo?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Deja que las hojas y el sustrato se sequen; evita mojar la planta.',
      'Aíslala si la mancha avanza o si hay más plantas cerca.',
      'Retira con cuidado una hoja claramente colapsada si puedes hacerlo sin '
          'dañar el resto.',
    ],
    disclaimerEs: _aloeDisclaimer,
    favorsHighHumidity: true,
  ),

  // ── SA-SYN-008 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'aloe_mealybug_scale_sooty_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Insectos visibles o superficie pegajosa',
    stages: _aloeStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomAloeMealybugScaleSooty,
    strongSignals: <String>{
      PlantHealthIds.signalAloeCottonWaxInsects,
      PlantHealthIds.signalAloeScaleBodies,
      PlantHealthIds.signalAloeStickySooty,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAloeProgressing,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeFineWebbing,
      PlantHealthIds.signalAloeDryHardSpots,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_sap_feeder_compatible',
        labelEs: 'Condición compatible con insectos chupadores',
        type: 'condition_compatible',
        summaryEs:
            'Material blanco algodonoso, escamas adheridas o una superficie '
            'pegajosa con capa negra son compatibles con cochinilla, escama o '
            'pulgón. BIO-G no confirma la plaga.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeCottonWaxInsects,
          PlantHealthIds.signalAloeScaleBodies,
          PlantHealthIds.signalAloeStickySooty,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Se distinguen cuerpos o insectos en el material blanco?',
      '¿Hay escamas adheridas o melaza pegajosa?',
      '¿La superficie pegajosa tiene una capa negra encima?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Aísla la planta para que los insectos no pasen a otras.',
      'Retira lo visible con un paño o hisopo si puedes hacerlo con cuidado.',
      'Revisa el envés de las hojas y las axilas, donde se esconden.',
    ],
    disclaimerEs: _aloeDisclaimer,
    favorsVectorPressure: true,
  ),

  // ── SA-SYN-009 ─────────────────────────────────────────────────────────────
  // NO confundir con SA-SYN-003: si hay verrugas, es agalla, no araña roja.
  PlantHealthSyndrome(
    id: 'aloe_spider_mite_stippling_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Punteado fino o telaraña',
    stages: _aloeStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAloeSpiderMiteStippling,
    strongSignals: <String>{
      PlantHealthIds.signalAloeFineStippling,
      PlantHealthIds.signalAloeFineWebbing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalAloeProgressing,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeWartyGrowth,
      PlantHealthIds.signalAloeStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_spider_mite_compatible',
        labelEs: 'Condición compatible con araña roja',
        type: 'condition_compatible',
        summaryEs:
            'Un punteado muy fino con telaraña, sobre todo en tiempo caluroso '
            'y seco, es compatible con araña roja. Si en cambio hay verrugas o '
            'masas rugosas, el cuadro es otro (crecimiento deforme).',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeFineStippling,
          PlantHealthIds.signalAloeFineWebbing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAloeWartyGrowth,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El punteado es muy fino y parejo?',
      '¿Hay telaraña muy fina en las hojas?',
      '¿El tiempo ha estado caluroso y seco?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Aísla la planta y revisa el envés de las hojas con buena luz.',
      'El ambiente caluroso y seco favorece a la araña roja.',
      'Si además hay verrugas o deformación, trátalo como crecimiento deforme, '
          'no como araña.',
    ],
    disclaimerEs: _aloeDisclaimer,
    favorsVectorPressure: true,
  ),

  // ── SA-SYN-011 ─────────────────────────────────────────────────────────────
  // Umbral MÁS ALTO del catálogo: la sábila tolera bien las sales.
  PlantHealthSyndrome(
    id: 'aloe_salt_fertilizer_injury_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Daño compatible con acumulación de sales',
    stages: _aloeStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAloeSaltLeafBurn,
    strongSignals: <String>{
      PlantHealthIds.signalAloeWhiteCrustSubstrate,
      PlantHealthIds.signalAloeRecentFertilizer,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAloeStable,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeSoftOrWatery,
      PlantHealthIds.signalColdExposure,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_salt_injury_compatible',
        labelEs: 'Condición compatible con exceso de sales',
        type: 'visual_concern',
        summaryEs:
            'Puntas o bordes quemados con costra blanca en el sustrato, tras '
            'fertilizar, son compatibles con acumulación de sales. La sábila '
            'tolera bien las sales, así que este cuadro exige señales claras.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeWhiteCrustSubstrate,
          PlantHealthIds.signalAloeRecentFertilizer,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay costra blanca en el sustrato o el borde de la maceta?',
      '¿Se fertilizó o abonó hace poco?',
      '¿El daño está en las puntas o los bordes de la hoja?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Evita fertilizar mientras la planta muestre este cambio.',
      'Un riego abundante con buen drenaje ayuda a lavar las sales acumuladas.',
      'Revisa que el agua salga bien para que las sales no se queden.',
    ],
    disclaimerEs: _aloeDisclaimer,
  ),

  // ── SA-SYN-012 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'aloe_spray_injury_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Daño compatible con un producto aplicado',
    stages: _aloeStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAloeSprayInjury,
    strongSignals: <String>{
      PlantHealthIds.signalAloeRecentSpray,
      PlantHealthIds.signalAloeDropletPattern,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAloeStable,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeProgressing,
      PlantHealthIds.signalAloeSoftOrWatery,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_spray_injury_compatible',
        labelEs: 'Condición compatible con daño por producto aplicado',
        type: 'visual_concern',
        summaryEs:
            'Una mancha con forma de gotas tras aplicar un producto o remedio '
            'casero es compatible con daño por el producto. Suele quedarse '
            'donde cayó y no avanzar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeRecentSpray,
          PlantHealthIds.signalAloeDropletPattern,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Se aplicó un producto o remedio en los últimos días?',
      '¿La mancha tiene forma de gotas o escurrimiento?',
      '¿La mancha se quedó igual, sin avanzar?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Suspende el producto que aplicaste sobre la planta.',
      'Evita aplicar remedios sobre la hoja bajo sol fuerte.',
      'Registra la mancha: si se queda igual, es de bajo riesgo.',
    ],
    disclaimerEs: _aloeDisclaimer,
  ),

  // ── SA-SYN-013 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'aloe_etiolation_low_light_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Crecimiento alargado y débil',
    stages: _aloeStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAloeEtiolatedGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalAloeElongatedPaleGrowth,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAloeStable,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeSoftOrWatery,
      PlantHealthIds.signalAloeProgressing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_low_light_compatible',
        labelEs: 'Crecimiento por poca luz, de bajo riesgo',
        type: 'visual_concern',
        summaryEs:
            'Hojas nuevas estiradas, pálidas e inclinadas hacia la luz indican '
            'que la planta busca más luz. No es enfermedad; el tejido ya '
            'estirado no se acorta.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeElongatedPaleGrowth,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El crecimiento nuevo sale estirado o pálido?',
      '¿La planta se inclina hacia la ventana o la luz?',
      '¿Está en un sitio con poca luz?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Acércala poco a poco a un sitio con más luz, sin sol directo de golpe.',
      'El tejido ya estirado se queda así; el crecimiento nuevo saldrá más '
          'compacto con buena luz.',
    ],
    disclaimerEs: _aloeDisclaimer,
  ),

  // ── SA-SYN-014 ─────────────────────────────────────────────────────────────
  // Existe para IMPEDIR que el usuario riegue: "sedienta con el suelo mojado".
  PlantHealthSyndrome(
    id: 'aloe_wrinkling_turgor_loss_01',
    cropId: CropCatalog.aloeCropId,
    labelEs: 'Hojas arrugadas o menos firmes',
    stages: _aloeStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAloeWrinklingTurgorLoss,
    strongSignals: <String>{
      PlantHealthIds.signalAloeWrinkling,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalAloeSoftOrWatery,
      PlantHealthIds.signalAloeFirmDry,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAloeStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aloe_turgor_loss_wet_soil_compatible',
        labelEs: 'Arrugas con sustrato húmedo: revisa la raíz, no riegues',
        type: 'condition_compatible',
        summaryEs:
            'Si las hojas se arrugan pero el sustrato sigue húmedo, la planta '
            'se ve sedienta porque la raíz no está tomando agua, no porque '
            'falte agua. Regar en ese caso empeora el cuadro.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeWrinkling,
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalAloeSoftOrWatery,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAloeFirmDry,
        },
      ),
      PlantHealthDiagnosis(
        id: 'aloe_turgor_loss_dry_soil_compatible',
        labelEs: 'Arrugas con sustrato seco: falta de agua, de bajo riesgo',
        type: 'visual_concern',
        summaryEs:
            'Si las hojas se arrugan y el sustrato está seco y firme, es '
            'simple falta de agua. Un riego con buen drenaje suele resolverlo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAloeFirmDry,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El sustrato está húmedo o seco?',
      '¿La base se siente firme o blanda?',
      '¿Las arrugas van en aumento?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Si el sustrato sigue húmedo, NO riegues: revisa la base y el drenaje.',
      'Si el sustrato está seco y firme, un riego con buen drenaje ayuda.',
      'Si además la base se ablanda, trátalo como revisión de base y raíz.',
    ],
    disclaimerEs: _aloeDisclaimer,
    favorsHighHumidity: true,
  ),
];
