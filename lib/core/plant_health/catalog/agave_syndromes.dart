import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Sanidad del Maguey / Agave ornamental (Documento C, MG v1.0).
///
/// Contrato de seguridad (Doc C §2) — inviolable:
/// - BIO-G **no** diagnostica un organismo causal (ni hongo, ni bacteria, ni
///   picudo) y **no** dice "tiene pudrición" como hecho confirmado.
/// - **No** confirma picudo sin insecto, larva o galería; el colapso por sí solo
///   no basta (Doc C §6, MG-SYN-004).
/// - **No** receta productos ni dosis, **no** ordena fumigar/quemar, **no**
///   recomienda cortar el quiote, **no** predice muerte ni decide jima.
/// - El sensor por sí solo **nunca** genera una alerta sanitaria alta: los
///   síndromes requieren observación del usuario (Doc C §14, MG-C-014).
/// - El quiote y la senescencia postfloración NO son enfermedades (Doc C §7.6).
///
/// Estructura espejo de `aloe_syndromes.dart`; textos e ids son propios.
///
/// v1 tiene **17 síndromes** (MG-SYN-001..017): ninguno se difiere.
const Set<PlantHealthStageBucket> _agaveStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.lateSeason,
};

const String _agaveDisclaimer =
    'BIO-G organiza observaciones y contexto para orientar la revisión. '
    'No confirma una enfermedad, una plaga, un organismo causal ni una '
    'decisión de cosecha.';

const List<PlantHealthSyndrome> agaveSyndromes = <PlantHealthSyndrome>[
  // ── MG-SYN-001 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_root_crown_condition_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Base, raíz o cogollo con deterioro por confirmar',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveRootCrownCondition,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveLossOfAnchor,
      PlantHealthIds.signalAgaveSoftOrWatery,
      PlantHealthIds.signalAgaveProgressing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalAgaveSnoutWeevilAdult,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveFirmDry,
      PlantHealthIds.signalAgaveStable,
      PlantHealthIds.signalAgaveBasalLeafDryOnly,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_root_crown_deterioration_compatible',
        labelEs: 'Condición compatible con deterioro de raíz, cuello o cogollo',
        type: 'condition_compatible',
        summaryEs:
            'La base, la raíz y el cogollo necesitan revisión. La causa no '
            'puede confirmarse con una lectura de suelo. Antes de regar, revisa '
            'la firmeza de la base y el drenaje.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveLossOfAnchor,
          PlantHealthIds.signalAgaveSoftOrWatery,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveFirmDry,
          PlantHealthIds.signalAgaveStable,
        },
      ),
      PlantHealthDiagnosis(
        id: 'agave_transplant_stress_possible',
        labelEs: 'Estrés de trasplante o anclaje por confirmar',
        type: 'visual_concern',
        summaryEs:
            'Un trasplante reciente, una raíz lastimada o una plantación '
            'demasiado profunda pueden producir un cuadro parecido sin que '
            'exista enfermedad.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La roseta está firme o se mueve en el suelo?',
      '¿La base está firme, seca, blanda o húmeda?',
      '¿El suelo sigue muy húmedo?',
      '¿El cambio está avanzando?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'No agregues agua mientras el suelo continúe húmedo.',
      'Revisa drenaje y estabilidad sin jalar ni desarmar la planta.',
      'Mantén alejadas a personas y animales si una roseta grande está '
          'inestable.',
      'Busca evaluación local si pierde soporte o el centro se deteriora.',
    ],
    disclaimerEs: _agaveDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── MG-SYN-002 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_soft_water_soaked_tissue_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Tejido blando, húmedo o acuoso que requiere revisión',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organCrown,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveSoftWaterSoakedTissue,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveSoftOrWatery,
      PlantHealthIds.signalAgaveCenterCollapse,
      PlantHealthIds.signalAgaveAbnormalOdor,
      PlantHealthIds.signalAgaveProgressing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalAgaveCreamLarvaeGalleries,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveFirmDry,
      PlantHealthIds.signalAgaveDryCorkyBud,
      PlantHealthIds.signalAgaveStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_soft_tissue_damage_compatible',
        labelEs: 'Condición compatible con daño interno activo',
        type: 'condition_compatible',
        summaryEs:
            'El tejido blando o acuoso es prioritario, pero no identifica por '
            'sí solo una bacteria, un hongo o un insecto. El frío y el exceso '
            'de agua producen cuadros parecidos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveSoftOrWatery,
          PlantHealthIds.signalAgaveCenterCollapse,
          PlantHealthIds.signalAgaveAbnormalOdor,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveFirmDry,
          PlantHealthIds.signalAgaveDryCorkyBud,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La zona está blanda o acuosa?',
      '¿Hay líquido o un olor que ya sea perceptible?',
      '¿La zona está creciendo?',
      '¿Ves un insecto, larvas o galerías?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Evita más agua si el suelo sigue húmedo.',
      'No cortes ni abras el cogollo solo para confirmar.',
      'Documenta el borde y la progresión.',
      'Busca evaluación local prioritaria si la planta pierde soporte.',
    ],
    disclaimerEs: _agaveDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── MG-SYN-003 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_wilt_dry_bud_anchor_loss_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Marchitez o pudrición seca del cogollo por confirmar',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveWiltDryBud,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveDryCorkyBud,
      PlantHealthIds.signalAgaveLossOfAnchor,
      PlantHealthIds.signalAgaveProgressing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveSoftOrWatery,
      PlantHealthIds.signalAgaveAbnormalOdor,
      PlantHealthIds.signalAgaveBasalLeafDryOnly,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_wilt_dry_bud_compatible',
        labelEs: 'Patrón compatible con marchitez y cogollo seco',
        type: 'condition_compatible',
        summaryEs:
            'La marchitez con hojas enrolladas rígidas y un cogollo seco, '
            'corrugado y sin olor forma un patrón compatible, pero requiere '
            'diagnóstico especializado. BIO-G no puede identificar Fusarium.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveDryCorkyBud,
          PlantHealthIds.signalAgaveLossOfAnchor,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveSoftOrWatery,
          PlantHealthIds.signalAgaveAbnormalOdor,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las hojas basales o intermedias se enrollan y permanecen rígidas?',
      '¿El centro está seco y corrugado o blando y húmedo?',
      '¿La roseta perdió anclaje?',
      '¿El patrón aparece en más plantas?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'No lo interpretes como falta de agua sin revisar base y raíz.',
      'Evita compartir suelo o herramientas entre plantas alteradas.',
      'Documenta si el cogollo está seco, rígido y sin olor.',
      'Busca evaluación local; BIO-G no puede identificar Fusarium.',
    ],
    disclaimerEs: _agaveDisclaimer,
    favorsRecentStress: true,
  ),

  // ── MG-SYN-004 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_snout_weevil_internal_boring_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Picudo del agave o barrenado interno por confirmar',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveSnoutWeevil,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveSnoutWeevilAdult,
      PlantHealthIds.signalAgaveCreamLarvaeGalleries,
      PlantHealthIds.signalAgaveCenterCollapse,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAgaveLossOfAnchor,
      PlantHealthIds.signalAgaveAbnormalOdor,
      PlantHealthIds.signalAgaveMechanicalWoundMark,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveStable,
      PlantHealthIds.signalAgaveCentralFlowerStalk,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_snout_weevil_compatible',
        labelEs: 'Condición compatible con picudo del agave',
        type: 'condition_compatible',
        summaryEs:
            'El picudo se confirma con un insecto oscuro de pico alargado, '
            'larvas claras o galerías internas; el colapso por sí solo no '
            'basta. BIO-G no confirma el organismo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveSnoutWeevilAdult,
          PlantHealthIds.signalAgaveCreamLarvaeGalleries,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveCentralFlowerStalk,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Ves un insecto oscuro con pico alargado?',
      '¿Ves larvas claras, galerías o tejido perforado?',
      '¿La roseta está floja o colapsando?',
      '¿El daño comienza en la base o el centro?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Aísla el área y evita mover material alterado entre plantas.',
      'No desarmes una roseta espinosa sin apoyo.',
      'Registra fotografías del insecto, la entrada y el daño.',
      'Busca identificación local y sigue solo las reglas fitosanitarias '
          'aplicables.',
    ],
    disclaimerEs: _agaveDisclaimer,
    favorsVectorPressure: true,
  ),

  // ── MG-SYN-005 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_mite_greasy_streak_core_distortion_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Raya grasosa y centro deformado compatibles con ácaro del agave',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organCrown,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveMiteGreasyStreak,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveGreasyStreakInnerLeaf,
      PlantHealthIds.signalAgaveDeformedCore,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAgaveProgressing,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveSunnySidePatch,
      PlantHealthIds.signalAgaveSunkenConcentricRings,
      PlantHealthIds.signalAgaveSoftScaleBodies,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_mite_compatible',
        labelEs: 'Condición compatible con ácaro del agave',
        type: 'condition_compatible',
        summaryEs:
            'La raya grasosa en la cara interna de las hojas nuevas y un '
            'cogollo que se deforma son una señal característica, pero siguen '
            'siendo una orientación, no un diagnóstico automático. El ácaro no '
            'se ve a simple vista.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveGreasyStreakInnerLeaf,
          PlantHealthIds.signalAgaveDeformedCore,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveSunnySidePatch,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La marca parece grasosa y está en la cara interna de hojas nuevas?',
      '¿El cogollo está deformándose?',
      '¿Aparece en otras plantas de la colección?',
      '¿La marca es estable o sigue avanzando?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Separa temporalmente la planta.',
      'No desarmes la roseta para buscar ácaros.',
      'Compara el crecimiento nuevo y revisa plantas vecinas.',
      'Busca confirmación especializada si progresa.',
    ],
    disclaimerEs: _agaveDisclaimer,
    favorsVectorPressure: true,
  ),

  // ── MG-SYN-006 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_soft_scale_waxy_material_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Escama blanda o material ceroso con insectos por confirmar',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveSoftScaleWaxy,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveSoftScaleBodies,
      PlantHealthIds.signalAgaveStickySooty,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAgaveProgressing,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveUniformWaxyBloom,
      PlantHealthIds.signalAgaveLeafImprint,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_soft_scale_compatible',
        labelEs: 'Condición compatible con escama blanda',
        type: 'condition_compatible',
        summaryEs:
            'La escama blanda sí está documentada en Agave: placas con un '
            'cuerpo debajo, colonias y superficie pegajosa. Un material blanco '
            'o ceroso uniforme sin cuerpos no se identifica como plaga.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveSoftScaleBodies,
          PlantHealthIds.signalAgaveStickySooty,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveUniformWaxyBloom,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Se ve un cuerpo debajo de la placa o cubierta?',
      '¿La superficie está pegajosa?',
      '¿Las placas forman colonias?',
      '¿La capa es uniforme en toda la hoja?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Separa temporalmente la planta.',
      'Revisa con lupa sin meter las manos entre espinas.',
      'Documenta cuerpos, placas y pegajosidad.',
      'Busca identificación antes de cualquier producto.',
    ],
    disclaimerEs: _agaveDisclaimer,
    favorsVectorPressure: true,
  ),

  // ── MG-SYN-007 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_plant_bug_feeding_scar_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Cicatrices superficiales compatibles con chinche del agave',
    stages: _agaveStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAgavePlantBugScar,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveSmallPlantBugs,
      PlantHealthIds.signalAgavePaleFeedingScars,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAgaveProgressing,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveSoftOrWatery,
      PlantHealthIds.signalAgaveCreamLarvaeGalleries,
      PlantHealthIds.signalAgaveGreasyStreakInnerLeaf,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_plant_bug_compatible',
        labelEs: 'Condición compatible con chinche del agave',
        type: 'visual_concern',
        summaryEs:
            'Cicatrices pálidas y superficiales con insectos pequeños '
            'moviéndose sobre la planta son compatibles con la chinche; la '
            'presencia del insecto es clave para diferenciarlas de un roce o '
            'granizo. El centro suele seguir firme.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveSmallPlantBugs,
          PlantHealthIds.signalAgavePaleFeedingScars,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveSoftOrWatery,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Ves insectos pequeños moviéndose sobre la planta?',
      '¿Las cicatrices son superficiales, secas y claras?',
      '¿Aparecen marcas nuevas?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Observa sin manipular el centro.',
      'Compara si aparecen marcas nuevas.',
      'No lo trates como pudrición.',
      'Busca identificación si aumenta la población.',
    ],
    disclaimerEs: _agaveDisclaimer,
    favorsVectorPressure: true,
  ),

  // ── MG-SYN-008 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_anthracnose_like_lesion_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Lesiones hundidas compatibles con antracnosis',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organCrown,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveAnthracnoseLesion,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveSunkenConcentricRings,
      PlantHealthIds.signalAgavePinkOrangeSporeMass,
      PlantHealthIds.signalAgaveLesionReachingCore,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAgaveProgressing,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveSunnySidePatch,
      PlantHealthIds.signalAgaveStable,
      PlantHealthIds.signalAgaveGreasyStreakInnerLeaf,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_anthracnose_compatible',
        labelEs: 'Condición compatible con antracnosis',
        type: 'condition_compatible',
        summaryEs:
            'Manchas hundidas con anillos concéntricos y masas rosadas o '
            'naranjas en humedad son compatibles con antracnosis, pero la '
            'apariencia no confirma Colletotrichum. Evita mojar el follaje.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveSunkenConcentricRings,
          PlantHealthIds.signalAgavePinkOrangeSporeMass,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveSunnySidePatch,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La lesión está hundida?',
      '¿Tiene anillos o material rosado o naranja?',
      '¿Aumenta durante periodos húmedos?',
      '¿Está alcanzando la base o el cogollo?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Evita mojar hojas y centro.',
      'Separa la planta si aparecen lesiones nuevas.',
      'No compartas herramientas sin limpieza.',
      'Busca evaluación local si avanza.',
    ],
    disclaimerEs: _agaveDisclaimer,
    favorsHighHumidity: true,
  ),

  // ── MG-SYN-009 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_gray_spot_like_lesion_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Mancha gris o tizón foliar por confirmar',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveGraySpotLesion,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveGraySpotChloroticHalo,
      PlantHealthIds.signalAgaveLesionReachingCore,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAgaveProgressing,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveSunnySidePatch,
      PlantHealthIds.signalAgaveGreasyStreakInnerLeaf,
      PlantHealthIds.signalAgaveSoftScaleBodies,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_gray_spot_compatible',
        labelEs: 'Condición compatible con mancha gris',
        type: 'condition_compatible',
        summaryEs:
            'Manchas grisáceas con halo amarillo que se unen y avanzan hacia '
            'el centro, tras lluvia o follaje mojado, pueden corresponder a '
            'mancha gris, pero no confirman Cercospora.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveGraySpotChloroticHalo,
          PlantHealthIds.signalAgaveLesionReachingCore,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveSunnySidePatch,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La mancha tiene un halo amarillo?',
      '¿Está cerca del cogollo?',
      '¿Las manchas se están uniendo?',
      '¿Hubo lluvia, neblina o follaje mojado?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Evita mojar las hojas.',
      'Mejora el espacio y la circulación sin herir la planta.',
      'Registra el avance.',
      'Busca evaluación si progresa hacia el centro.',
    ],
    disclaimerEs: _agaveDisclaimer,
    favorsHighHumidity: true,
  ),

  // ── MG-SYN-010 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_cold_frost_injury_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Daño por frío o helada',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveColdFrostInjury,
    strongSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalAgaveFrostBlackenedTissue,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalAgaveSoftOrWatery,
      PlantHealthIds.signalAgaveProgressing,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveSunnySidePatch,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalAgaveSunkenConcentricRings,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_cold_injury_compatible',
        labelEs: 'Condición compatible con daño por frío',
        type: 'condition_compatible',
        summaryEs:
            'Un ennegrecimiento o tejido translúcido y flácido tras una helada '
            'es compatible con daño por frío; puede verse negro y después '
            'secarse, y no debe confundirse automáticamente con pudrición. El '
            'perfil de hoja suave (MG-04) es el más sensible.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalAgaveFrostBlackenedTissue,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveSunnySidePatch,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo helada o frío intenso antes del cambio?',
      '¿El tejido se volvió negro, translúcido o flácido después?',
      '¿El suelo estaba húmedo?',
      '¿El centro conserva firmeza?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Protégelo de más frío.',
      'No agregues agua si sigue húmedo.',
      'No cortes tejido mientras continúa cambiando.',
      'Vigila el centro y la estabilidad.',
    ],
    disclaimerEs: _agaveDisclaimer,
    favorsRecentStress: true,
  ),

  // ── MG-SYN-011 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_sunburn_heat_reflection_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Quemadura por sol, calor o cambio brusco de exposición',
    stages: _agaveStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAgaveSunburnHeat,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveSunnySidePatch,
      PlantHealthIds.signalAgaveChangedSunExposure,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAgaveStable,
      PlantHealthIds.signalHeatStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveSoftOrWatery,
      PlantHealthIds.signalAgaveProgressing,
      PlantHealthIds.signalAgavePinkOrangeSporeMass,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_sunburn_compatible',
        labelEs: 'Condición compatible con quemadura de sol',
        type: 'visual_concern',
        summaryEs:
            'Un parche seco y firme del lado soleado, sobre todo tras mover u '
            'orientar la planta, es compatible con quemadura. Deja una cicatriz '
            'permanente, pero no debería seguir avanzando una vez corregida la '
            'exposición.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveSunnySidePatch,
          PlantHealthIds.signalAgaveChangedSunExposure,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveSoftOrWatery,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La mancha está del lado que recibe más sol?',
      '¿La planta cambió de lugar u orientación?',
      '¿La zona está seca y firme?',
      '¿Dejó de crecer la lesión?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Evita otro cambio brusco de exposición.',
      'Reduce el calor reflejado de paredes o grava.',
      'Vigila que la zona siga seca y estable.',
      'Eleva la revisión si se ablanda o se expande.',
    ],
    disclaimerEs: _agaveDisclaimer,
  ),

  // ── MG-SYN-012 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_mechanical_wound_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Herida, golpe, granizo o retiro de hijuelo',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveMechanicalWound,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveMechanicalWoundMark,
      PlantHealthIds.signalAgaveOffsetRemovalRecent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveSunkenConcentricRings,
      PlantHealthIds.signalAgaveCreamLarvaeGalleries,
      PlantHealthIds.signalAgaveGreasyStreakInnerLeaf,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_mechanical_wound_compatible',
        labelEs: 'Condición compatible con herida mecánica',
        type: 'visual_concern',
        summaryEs:
            'Un corte, golpe, granizo o la herida tras retirar un hijuelo '
            'puede quedar como cicatriz; se vuelve prioritaria cuando cambia de '
            'firmeza, olor o tamaño. Retirar un hijuelo no cambia la etapa de '
            'la planta madre.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveMechanicalWoundMark,
          PlantHealthIds.signalAgaveOffsetRemovalRecent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveCreamLarvaeGalleries,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo golpe, corte, granizo o retiro de hijuelo?',
      '¿La zona está seca o blanda?',
      '¿La herida está aumentando?',
      '¿La herramienta se usó en otras plantas?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Mantén la zona sin agua acumulada.',
      'No amplíes la herida.',
      'Separa las herramientas hasta limpiarlas.',
      'Busca revisión si se vuelve blanda o llega al centro.',
    ],
    disclaimerEs: _agaveDisclaimer,
    favorsRecentStress: true,
  ),

  // ── MG-SYN-013 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_salt_fertilizer_injury_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Daño compatible con sales o fertilización',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveSaltFertilizerInjury,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveWhiteCrustSubstrate,
      PlantHealthIds.signalAgaveRecentFertilizer,
      PlantHealthIds.signalAgaveLeafTipEdgeBurn,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalAgaveStable,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalAgaveCreamLarvaeGalleries,
      PlantHealthIds.signalAgaveSunnySidePatch,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_salt_injury_compatible',
        labelEs: 'Condición compatible con exceso de sales',
        type: 'visual_concern',
        summaryEs:
            'Puntas y bordes secos con costra blanca en el suelo, tras '
            'fertilizar o con EC alta, apoyan una revisión por sales, pero no '
            'identifican la sal ni el nutriente responsable.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveWhiteCrustSubstrate,
          PlantHealthIds.signalAgaveRecentFertilizer,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay costra blanca en el suelo o la maceta?',
      '¿Se fertilizó recientemente?',
      '¿El daño comienza en puntas o bordes?',
      '¿La lectura de sales está alta?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'No agregues fertilizante mientras las sales estén altas.',
      'Revisa agua, drenaje y tendencia.',
      'No realices un lavado con volumen calculado por BIO-G.',
      'Busca análisis local si persiste.',
    ],
    disclaimerEs: _agaveDisclaimer,
  ),

  // ── MG-SYN-014 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_animal_chewing_damage_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Mordedura o daño por animales',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveAnimalDamage,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveMissingChewedTissue,
      PlantHealthIds.signalAgaveAnimalTracksScat,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveCreamLarvaeGalleries,
      PlantHealthIds.signalAgaveGraySpotChloroticHalo,
      PlantHealthIds.signalAgaveGreasyStreakInnerLeaf,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_animal_damage_compatible',
        labelEs: 'Condición compatible con daño por animales',
        type: 'visual_concern',
        summaryEs:
            'Tejido faltante o mordido con huellas, excremento o madrigueras '
            'orienta a daño físico por animal; las galerías internas, en '
            'cambio, obligan a evaluar picudo. No lo atribuyas automáticamente '
            'a enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveMissingChewedTissue,
          PlantHealthIds.signalAgaveAnimalTracksScat,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveCreamLarvaeGalleries,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Falta tejido o solo cambió de color?',
      '¿Ves huellas, excremento, baba o madrigueras?',
      '¿La base sigue firme?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Evita nuevo acceso a la planta.',
      'Mantén la herida sin agua acumulada.',
      'No atribuyas automáticamente el daño a enfermedad.',
      'Busca revisión si alcanza el centro.',
    ],
    disclaimerEs: _agaveDisclaimer,
  ),

  // ── MG-SYN-015 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_flower_stalk_transition_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Tallo floral o quiote observado',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveFlowerStalk,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveCentralFlowerStalk,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAgaveOffsetsPresent,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveSoftOrWatery,
      PlantHealthIds.signalAgaveCreamLarvaeGalleries,
      PlantHealthIds.signalAgaveAbnormalOdor,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_flowering_transition',
        labelEs: 'Floración: cambio natural, no enfermedad',
        type: 'visual_concern',
        summaryEs:
            'En muchos agaves, cada roseta florece una vez y después entra en '
            'senescencia; los hijuelos pueden continuar. BIO-G no predice '
            'cuánto tiempo le queda, no decide jima ni recomienda cortar el '
            'quiote. La floración no oculta olor, larvas ni base blanda.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveCentralFlowerStalk,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveSoftOrWatery,
          PlantHealthIds.signalAgaveCreamLarvaeGalleries,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El tallo sale exactamente del centro?',
      '¿Está formando ramas o estructuras florales?',
      '¿Es una sola roseta o un grupo?',
      '¿Hay hijuelos?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Registra el evento y observa hijuelos y estabilidad.',
      'No cortes el quiote por instrucción de BIO-G.',
      'No lo interpretes como jima ni cosecha.',
      'Revisa la seguridad si el tallo es muy grande.',
    ],
    disclaimerEs: _agaveDisclaimer,
  ),

  // ── MG-SYN-016 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_post_flowering_senescence_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Senescencia de la roseta madre después de floración',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomAgavePostFloweringSenescence,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveCentralFlowerStalk,
      PlantHealthIds.signalAgaveGradualOuterDrying,
      PlantHealthIds.signalAgaveFirmDry,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAgaveOffsetsPresent,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveSoftOrWatery,
      PlantHealthIds.signalAgaveAbnormalOdor,
      PlantHealthIds.signalAgaveCreamLarvaeGalleries,
      PlantHealthIds.signalAgaveCenterCollapse,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_post_flowering_senescence_compatible',
        labelEs: 'Senescencia normal después de floración',
        type: 'visual_concern',
        summaryEs:
            'El secado gradual de las hojas exteriores tras una floración '
            'confirmada, con base firme y sin olor y con hijuelos sanos, puede '
            'ser normal; el tejido blando, el olor o el colapso rápido '
            'requieren otra revisión.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveGradualOuterDrying,
          PlantHealthIds.signalAgaveCentralFlowerStalk,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveSoftOrWatery,
          PlantHealthIds.signalAgaveAbnormalOdor,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La planta ya floreció?',
      '¿El secado es gradual?',
      '¿La base sigue firme y sin olor?',
      '¿Hay hijuelos sanos?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Observa la seguridad del tallo y la roseta.',
      'No predigas una fecha exacta de muerte.',
      'No atribuyas tejido blando a senescencia normal.',
      'Busca ayuda si una estructura grande se vuelve inestable.',
    ],
    disclaimerEs: _agaveDisclaimer,
  ),

  // ── MG-SYN-017 ──────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'agave_benign_natural_change_01',
    cropId: CropCatalog.agaveCropId,
    labelEs: 'Cambio natural o cicatriz estable',
    stages: _agaveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAgaveBenignNaturalChange,
    strongSignals: <String>{
      PlantHealthIds.signalAgaveBasalLeafDryOnly,
      PlantHealthIds.signalAgaveUniformWaxyBloom,
      PlantHealthIds.signalAgaveLeafImprint,
      PlantHealthIds.signalAgaveStable,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAgaveOffsetsPresent,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalAgaveProgressing,
      PlantHealthIds.signalAgaveLesionReachingCore,
      PlantHealthIds.signalAgaveSoftOrWatery,
      PlantHealthIds.signalAgaveCreamLarvaeGalleries,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'agave_benign_natural_change_compatible',
        labelEs: 'Cambio natural de bajo riesgo',
        type: 'visual_concern',
        summaryEs:
            'Una o pocas hojas basales viejas y secas, improntas simétricas de '
            'dientes, una capa glauca uniforme, variegación estable o un '
            'hijuelo pueden ser normales mientras el centro siga firme y el '
            'cambio no avance.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAgaveBasalLeafDryOnly,
          PlantHealthIds.signalAgaveUniformWaxyBloom,
          PlantHealthIds.signalAgaveStable,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAgaveProgressing,
          PlantHealthIds.signalAgaveLesionReachingCore,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El cambio está solo en hojas exteriores?',
      '¿Es seco, firme y estable?',
      '¿Se repite de forma simétrica?',
      '¿El centro permanece sano?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Compara con el crecimiento nuevo.',
      'No raspes la cera.',
      'No cortes hojas internas.',
      'Eleva la revisión si el cambio avanza al centro.',
    ],
    disclaimerEs: _agaveDisclaimer,
  ),
];
