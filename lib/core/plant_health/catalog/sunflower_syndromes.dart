import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

// Conjuntos de etapas de Girasol / Sunflower (Doc C §3). El girasol es
// un anual de ciclo unico; sus etapas fenologicas se traducen a los ocho
// buckets compartidos del motor de sanidad sin crear una segunda taxonomia.

const Set<PlantHealthStageBucket> _seedlingOnlyStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
};

const Set<PlantHealthStageBucket> _seedlingThroughBloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _vegThroughGrainFillStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _stemStructureLateStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _lateVegToGrainFillStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _foliarDiseaseStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _postBloomToEndStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _seedlingToVegLateStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
};

const Set<PlantHealthStageBucket> _seedlingToBudStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
};

const Set<PlantHealthStageBucket> _vegToBloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _midVegToGrainFillStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _stemElongationToBloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _earlySeedlingStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
};

const Set<PlantHealthStageBucket> _wildlifeRiskStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _budFormationWindowStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
};

const Set<PlantHealthStageBucket> _budAndBloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _bloomToPostBloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _endOfCycleStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

/// Disclaimer obligatorio (Doc C §0.2) presente en cada síndrome de Girasol.
const String _sunflowerDisclaimer =
    'BIO-G organiza observaciones y contexto para orientar la revisión. No confirma una enfermedad, una plaga ni un organismo causal.';

/// Catálogo visual prudente para Girasol / Sunflower (`crop_sunflower`,
/// Doc C §5).
///
/// El catálogo se organiza por síndromes observables (¿qué ves en tu
/// Girasol?), nunca por enfermedades. Los cuadros describen condiciones
/// compatibles y preguntas de confirmación. Ninguna lectura del dispositivo
/// confirma por sí sola un hongo, una bacteria, un virus, un ácaro, un
/// insecto ni una deficiencia. Una señal de sensor aislada nunca produce
/// severidad alta: para high/critical debe existir una señal observada
/// fuerte (Doc C §2.3). Orden: Familias 1 a 6 tal como en el Doc C §5.
const List<PlantHealthSyndrome> sunflowerSyndromes = <PlantHealthSyndrome>[
  // ────────────────────────────────────────────────────────────────────────
  // Familia 1: Semilla y plantula.
  // ────────────────────────────────────────────────────────────────────────
  // 1. No emerge o nace de forma muy dispareja.
  PlantHealthSyndrome(
    id: 'sunflower_poor_or_patchy_emergence_01',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'No emerge o nace de forma muy dispareja',
    stages: _seedlingOnlyStages,
    organIds: <String>{
      PlantHealthIds.organSeed,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomPoorEmergence,
    strongSignals: <String>{
      PlantHealthIds.signalPoorEmergence,
      PlantHealthIds.signalSunflowerSeedMissingOrSoft,
      PlantHealthIds.signalSunflowerSoilCrust,
      PlantHealthIds.signalSunflowerUnevenPatches,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalSunflowerDeepSowing,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerHealthyEmergenceNearby,
      PlantHealthIds.signalSunflowerSeedlingPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_germination_environment_possible',
        labelEs: 'Condición de germinación desfavorable',
        type: 'abiotic_compatible',
        summaryEs: 'Suelo demasiado frío, seco, saturado, encostrado o una siembra profunda pueden retrasar o impedir la emergencia sin que exista una enfermedad confirmada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoilCrust,
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalDryHotWindow,
          PlantHealthIds.signalSunflowerDeepSowing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHealthyEmergenceNearby,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_pre_emergence_rot_possible',
        labelEs: 'Deterioro de semilla antes de emerger por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Una semilla blanda, oscura o desintegrada en suelo húmedo es compatible con pudrición preemergente, pero no identifica el organismo causal.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSeedMissingOrSoft,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSeedlingPresent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_seed_predation_or_loss_possible',
        labelEs: 'Pérdida o consumo de semilla posible',
        type: 'physical_or_wildlife',
        summaryEs: 'Semilla ausente, huecos localizados o suelo removido pueden corresponder a aves, roedores, insectos o daño físico.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSeedMissingOrSoft,
          PlantHealthIds.signalSunflowerUnevenPatches,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHealthyEmergenceNearby,
          PlantHealthIds.signalSunflowerSeedlingPresent,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Cuántos días han pasado desde la siembra y qué fecha esperaba el perfil?',
      '¿El suelo está húmedo, seco, frío, encharcado o con costra dura?',
      '¿Al revisar una semilla, sigue firme o está blanda, oscura o ausente?',
      '¿El problema forma parches o afecta toda la siembra por igual?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Compara la fecha con la ventana de germinación del perfil antes de declarar una falla.',
      'Revisa humedad, profundidad y costra superficial sin desenterrar toda la siembra.',
      'No vuelvas a sembrar ni agregues fertilizante hasta confirmar si la semilla sigue viable.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  // 2. Plántula vencida o colapsada a nivel del suelo.
  PlantHealthSyndrome(
    id: 'sunflower_seedling_collapse_at_soil_line_02',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Plántula vencida o colapsada a nivel del suelo',
    stages: _seedlingOnlyStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSeedlingCollapse,
    strongSignals: <String>{
      PlantHealthIds.signalSeedlingNeckCollapse,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalSunflowerSoftDarkNeck,
      PlantHealthIds.signalSunflowerOuterRootSloughs,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalSunflowerWarmWetSoil,
      PlantHealthIds.signalSunflowerReddishBrownGirdle,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerStemCleanCut,
      PlantHealthIds.signalSunflowerFirmDryBreak,
      PlantHealthIds.signalSunflowerSlimeTrail,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_damping_off_complex_compatible',
        labelEs: 'Condición compatible con damping-off',
        type: 'condition_compatible',
        summaryEs: 'El colapso blando y oscuro del cuello o la raíz es compatible con un complejo de Pythium, Rhizoctonia u otros organismos de suelo; solo laboratorio puede distinguirlos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSeedlingNeckCollapse,
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalSunflowerSoftDarkNeck,
          PlantHealthIds.signalSunflowerOuterRootSloughs,
          PlantHealthIds.signalSunflowerWarmWetSoil,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemCleanCut,
          PlantHealthIds.signalSunflowerFirmDryBreak,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_cutworm_or_chewing_possible',
        labelEs: 'Daño de corte o mordida por confirmar',
        type: 'invertebrate_possible',
        summaryEs: 'Un tallo cortado con tejido firme y sin pudrición puede corresponder a larvas nocturnas u otro daño masticador.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemCleanCut,
          PlantHealthIds.signalSunflowerFirmDryBreak,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoftDarkNeck,
          PlantHealthIds.signalRootsDarkRot,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_mechanical_break_possible',
        labelEs: 'Quiebre físico posible',
        type: 'physical_damage',
        summaryEs: 'Viento, manipulación o golpe pueden vencer una plántula sin deterioro del cuello.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerFirmDryBreak,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoftDarkNeck,
          PlantHealthIds.signalSunflowerOuterRootSloughs,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El cuello está blando y oscuro o parece cortado de forma limpia?',
      '¿Las raíces están negras, blandas o pierden su capa exterior?',
      '¿El suelo ha permanecido húmedo o encharcado?',
      '¿Hay mordidas, excremento, larvas o rastro brillante cerca del suelo?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Evita un nuevo riego si el suelo continúa húmedo.',
      'Separa o retira una plántula totalmente colapsada para revisar cuello y raíz sin contaminar otras.',
      'Busca evaluación local si aparecen nuevos colapsos en poco tiempo.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  // ────────────────────────────────────────────────────────────────────────
  // Familia 2: Raiz, cuello y estructura.
  // ────────────────────────────────────────────────────────────────────────
  // 3. Raíz o base blanda, oscura o con pérdida de soporte.
  PlantHealthSyndrome(
    id: 'sunflower_root_crown_soft_deterioration_03',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Raíz o base blanda, oscura o con pérdida de soporte',
    stages: _seedlingThroughBloomStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalSunflowerSoftWateryBase,
      PlantHealthIds.signalSunflowerLossOfSupport,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalSunflowerAbnormalOdor,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalSunflowerOuterRootSloughs,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerRootsFirmLight,
      PlantHealthIds.signalSunflowerBaseFirmDry,
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_root_crown_rot_complex_compatible',
        labelEs: 'Condición compatible con deterioro de raíz o cuello',
        type: 'condition_compatible',
        summaryEs: 'Raíces oscuras, blandas y una base que pierde soporte son compatibles con un problema radicular serio, sin identificar un patógeno.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalSunflowerSoftWateryBase,
          PlantHealthIds.signalSunflowerLossOfSupport,
          PlantHealthIds.signalSunflowerAbnormalOdor,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRootsFirmLight,
          PlantHealthIds.signalSunflowerBaseFirmDry,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_waterlogging_root_dysfunction',
        labelEs: 'Asfixia radicular por exceso de agua posible',
        type: 'abiotic_compatible',
        summaryEs: 'El suelo saturado puede causar marchitez, amarillamiento y pérdida de función aunque no exista infección confirmada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalHumidWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalDryHotWindow,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_transplant_wound_stress',
        labelEs: 'Estrés o herida de trasplante posible',
        type: 'physical_damage',
        summaryEs: 'Una herida reciente puede debilitar el cuello y abrir una vía de deterioro.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRecentStress,
          PlantHealthIds.signalSunflowerOuterRootSloughs,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerBaseFirmDry,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La base cede al tacto o permanece firme?',
      '¿Las raíces son claras y firmes o oscuras y blandas?',
      '¿El agua sale de la maceta o permanece alrededor del cuello?',
      '¿La zona aumenta, huele diferente o la planta se afloja?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Suspende riegos adicionales mientras el suelo siga húmedo.',
      'Revisa drenaje, profundidad de plantación y contacto del cuello con agua acumulada.',
      'Busca evaluación local si la base pierde soporte, aparece olor o el deterioro avanza.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  // 4. Marchita aunque el suelo sigue húmedo.
  PlantHealthSyndrome(
    id: 'sunflower_wilt_while_soil_is_wet_04',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Marchita aunque el suelo sigue húmedo',
    stages: _vegThroughGrainFillStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organRoot,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomWiltVascular,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalSunflowerWiltInWetSoil,
      PlantHealthIds.signalVascularBrowning,
      PlantHealthIds.signalOneSidedWilt,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalSunflowerPatchOrSinglePlant,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerRecoversAfterWater,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalSunflowerNormalPostBloomDroop,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_root_dysfunction_wet_soil',
        labelEs: 'Pérdida de función radicular con suelo húmedo',
        type: 'condition_compatible',
        summaryEs: 'El exceso de agua reduce oxígeno y puede impedir que la raíz absorba agua, por lo que una planta puede marchitarse aunque el suelo esté mojado.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalSunflowerWiltInWetSoil,
          PlantHealthIds.signalHumidWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRecoversAfterWater,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_vascular_wilt_possible',
        labelEs: 'Marchitez vascular por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Marchitez unilateral, avance desde hojas bajas y pardeamiento vascular son compatibles con Verticillium, Fusarium u otro daño vascular, sin confirmarlo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalOneSidedWilt,
          PlantHealthIds.signalVascularBrowning,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRecoversAfterWater,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_stem_or_root_injury_possible',
        labelEs: 'Daño físico de raíz o tallo posible',
        type: 'physical_damage',
        summaryEs: 'Raíces cortadas, cuello lastimado o tallo estrangulado pueden producir un cuadro similar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalSunflowerPatchOrSinglePlant,
        },
        contradictorySignalIds: <String>{},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El suelo está realmente húmedo a la profundidad de la raíz?',
      '¿La marchitez afecta un lado, una rama o toda la planta?',
      '¿Un corte limpio del tallo muestra anillo o tejido vascular café?',
      '¿La raíz o el cuello tienen deterioro visible?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'No riegues por reflejo una planta marchita si el suelo ya está húmedo.',
      'Revisa drenaje, cuello, raíz y daño físico.',
      'Busca evaluación local si existe pardeamiento vascular, progresión rápida o plantas vecinas afectadas.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  // 5. Pierde firmeza durante calor o suelo seco.
  PlantHealthSyndrome(
    id: 'sunflower_wilt_during_dry_heat_05',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Pierde firmeza durante calor o suelo seco',
    stages: _vegThroughGrainFillStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomSunflowerTurgorLoss,
    strongSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalSunflowerSoilDry,
      PlantHealthIds.signalSunflowerRecoversEvening,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalSunflowerContainerHeated,
      PlantHealthIds.signalSunflowerLeafEdgeDry,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalVascularBrowning,
      PlantHealthIds.signalSunflowerNoRecoveryOvernight,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_transient_heat_wilt',
        labelEs: 'Pérdida temporal de firmeza por demanda alta',
        type: 'abiotic_compatible',
        summaryEs: 'Una planta puede decaer en horas de máxima demanda y recuperar firmeza al bajar el calor si la raíz sigue funcional.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalDryHotWindow,
          PlantHealthIds.signalHeatStress,
          PlantHealthIds.signalSunflowerRecoversEvening,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNoRecoveryOvernight,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_drought_stress_progressing',
        labelEs: 'Déficit de agua con daño progresivo posible',
        type: 'abiotic_compatible',
        summaryEs: 'Falta de recuperación, bordes secos y suelo seco profundo indican un cuadro más serio.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoilDry,
          PlantHealthIds.signalSunflowerLeafEdgeDry,
          PlantHealthIds.signalSunflowerNoRecoveryOvernight,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRecoversEvening,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_root_restriction_possible',
        labelEs: 'Raíz restringida o maceta insuficiente posible',
        type: 'structural_condition',
        summaryEs: 'Una maceta pequeña o raíz confinada puede secarse con rapidez y producir marchitez repetida.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerContainerHeated,
        },
        contradictorySignalIds: <String>{},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Recupera firmeza al atardecer o después de corregir la humedad?',
      '¿El suelo está seco solo arriba o también en la zona radicular?',
      '¿La maceta se calienta o se seca varias veces al día?',
      '¿Hay raíces comprimidas, oscuras o con olor?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Confirma la humedad en la zona radicular antes de regar.',
      'Protege la maceta del calentamiento extremo sin mover la planta de golpe a sombra profunda.',
      'Escala la revisión si no recupera firmeza durante la noche o aparecen tejidos oscuros.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 6. Tallo con lesión, hueco o zona que pierde resistencia.
  PlantHealthSyndrome(
    id: 'sunflower_stem_canker_hollow_or_weak_06',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Tallo con lesión, hueco o zona que pierde resistencia',
    stages: _stemStructureLateStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalStemCanker,
      PlantHealthIds.signalSunflowerPetioleCenteredLesion,
      PlantHealthIds.signalSunflowerTriangularLeafLesion,
      PlantHealthIds.signalSunflowerHollowPith,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalSunflowerPrematureDrying,
      PlantHealthIds.signalSunflowerLodging,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerSuperficialBlackSpotOnly,
      PlantHealthIds.signalSunflowerFirmIntactPith,
      PlantHealthIds.signalSunflowerMechanicalBruise,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_phomopsis_compatible',
        labelEs: 'Condición compatible con cancro de tallo tipo Phomopsis',
        scientificName: 'Phomopsis spp.',
        type: 'condition_compatible',
        summaryEs: 'Lesión grande café centrada en un pecíolo, hoja bronceada triangular, médula hueca y vuelco son un patrón compatible, no una confirmación.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerPetioleCenteredLesion,
          PlantHealthIds.signalSunflowerTriangularLeafLesion,
          PlantHealthIds.signalSunflowerHollowPith,
          PlantHealthIds.signalSunflowerLodging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerFirmIntactPith,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_phoma_black_stem_possible',
        labelEs: 'Lesión superficial oscura tipo Phoma por confirmar',
        scientificName: 'Phoma spp.',
        type: 'condition_compatible',
        summaryEs: 'Lesiones negras bien delimitadas y superficiales en la base del pecíolo pueden parecerse, pero suelen conservar la médula más firme.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSuperficialBlackSpotOnly,
          PlantHealthIds.signalStemCanker,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHollowPith,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_bacterial_stalk_deterioration_possible',
        labelEs: 'Deterioro bacteriano del tallo por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Tallo blando, negro, partido o con espuma después de herida y humedad requiere revisión rápida.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHumidWindow,
          PlantHealthIds.signalSunflowerPrematureDrying,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerFirmIntactPith,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_physical_stem_injury',
        labelEs: 'Daño mecánico del tallo posible',
        type: 'physical_damage',
        summaryEs: 'Golpe, roce, amarre o granizo pueden producir lesión sin infección.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerMechanicalBruise,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHollowPith,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La lesión nace donde el pecíolo se une al tallo?',
      '¿La hoja asociada tiene una zona triangular café desde el margen?',
      '¿La médula está firme o hueca y se hunde con facilidad?',
      '¿El tejido está seco o blando, con espuma, olor o avance rápido?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Sostén el tallo si existe riesgo inmediato de quiebre, sin apretar la lesión.',
      'Evita mojar repetidamente la zona y revisa si avanza.',
      'Busca evaluación local si la médula está hueca, hay espuma, ablandamiento o varias plantas afectadas.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  // 7. Se inclina, se vence o el tallo comienza a quebrarse.
  PlantHealthSyndrome(
    id: 'sunflower_lodging_leaning_or_breakage_07',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Se inclina, se vence o el tallo comienza a quebrarse',
    stages: _lateVegToGrainFillStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organFlowerHead,
    },
    primarySymptomId: PlantHealthIds.symptomSunflowerLodging,
    strongSignals: <String>{
      PlantHealthIds.signalSunflowerNewLeaning,
      PlantHealthIds.signalSunflowerStemCrease,
      PlantHealthIds.signalSunflowerRootPlateLoose,
      PlantHealthIds.signalSunflowerHeadHeavy,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalSunflowerWindEvent,
      PlantHealthIds.signalSunflowerStemThin,
      PlantHealthIds.signalSunflowerSoilLooseWet,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerNormalPostBloomDroop,
      PlantHealthIds.signalSunflowerStemFirmVertical,
      PlantHealthIds.signalSunflowerStableAngle,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_wind_or_head_load_lodging',
        labelEs: 'Vuelco por viento o peso de la cabeza posible',
        type: 'physical_damage',
        summaryEs: 'Un tallo alto, una cabeza pesada y ráfagas pueden inclinar la planta sin enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerWindEvent,
          PlantHealthIds.signalSunflowerHeadHeavy,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemFirmVertical,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_weak_stem_growth_imbalance',
        labelEs: 'Tallo débil por crecimiento desbalanceado posible',
        type: 'structural_condition',
        summaryEs: 'Sombra, exceso vegetativo, competencia o poco movimiento pueden dejar un tallo largo y fino.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemThin,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStableAngle,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_root_or_stem_disease_lodging',
        labelEs: 'Pérdida de soporte por raíz o tallo por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Base blanda, raíz suelta, cancro o médula hueca elevan la preocupación.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRootPlateLoose,
          PlantHealthIds.signalSunflowerStemCrease,
          PlantHealthIds.signalSunflowerSoilLooseWet,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemFirmVertical,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_normal_head_angle',
        labelEs: 'Ángulo normal de cabeza madura posible',
        type: 'benign_differential',
        summaryEs: 'La cabeza puede inclinarse después de abrirse mientras el tallo y la base permanecen firmes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNormalPostBloomDroop,
          PlantHealthIds.signalSunflowerStemFirmVertical,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNewLeaning,
          PlantHealthIds.signalSunflowerStemCrease,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Se inclina toda la planta desde la base o solo la cabeza?',
      '¿Hubo viento, lluvia intensa, ave posada o golpe?',
      '¿La base y el tallo están firmes, blandos, huecos o marcados?',
      '¿La flor lleva varios días abierta y el resto de la planta sigue firme?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Coloca soporte holgado si el tallo corre riesgo de quebrarse.',
      'No intentes enderezar bruscamente un tallo ya doblado.',
      'Revisa raíz, cuello y cancro antes de atribuirlo solo al peso de la flor.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // ────────────────────────────────────────────────────────────────────────
  // Familia 3: Follaje y enfermedades foliares.
  // ────────────────────────────────────────────────────────────────────────
  // 8. Manchas en hojas bajas que avanzan hacia arriba.
  PlantHealthSyndrome(
    id: 'sunflower_lower_leaf_spots_progressing_08',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Manchas en hojas bajas que avanzan hacia arriba',
    stages: _foliarDiseaseStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalAngularLesionPattern,
      PlantHealthIds.signalHaloMargin,
      PlantHealthIds.signalSunflowerLowerLeavesFirst,
      PlantHealthIds.signalSunflowerLesionsCoalesce,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalSunflowerRainSplash,
      PlantHealthIds.signalSunflowerYellowThenBrown,
      PlantHealthIds.signalSunflowerDefoliationBottomUp,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerGradualUniformYellowing,
      PlantHealthIds.signalSunflowerInsectBodies,
      PlantHealthIds.signalSunflowerPowderRubOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_alternaria_leaf_blight_compatible',
        labelEs: 'Patrón compatible con tizón foliar tipo Alternaria',
        scientificName: 'Alternaria spp.',
        type: 'condition_compatible',
        summaryEs: 'Manchas oscuras angulares o irregulares desde márgenes y puntas, que se unen y avanzan de abajo hacia arriba, son compatibles.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAngularLesionPattern,
          PlantHealthIds.signalSunflowerLowerLeavesFirst,
          PlantHealthIds.signalSunflowerLesionsCoalesce,
          PlantHealthIds.signalSunflowerDefoliationBottomUp,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerGradualUniformYellowing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_septoria_leaf_blight_possible',
        labelEs: 'Mancha foliar tipo Septoria por confirmar',
        scientificName: 'Septoria spp.',
        type: 'condition_compatible',
        summaryEs: 'Manchas pequeñas café que aumentan con lluvias frecuentes pueden pertenecer a este diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRainSplash,
          PlantHealthIds.signalHumidWindow,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_bacterial_leaf_spot_possible',
        labelEs: 'Mancha bacteriana por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Halo acuoso, lesiones entre venas y tejido que se desprende pueden sugerir un origen bacteriano.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHaloMargin,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_minor_late_leaf_spot',
        labelEs: 'Manchado tardío de impacto limitado posible',
        type: 'benign_differential',
        summaryEs: 'Manchas aisladas en hojas viejas después de floración pueden no comprometer la función ornamental completa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerYellowThenBrown,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerLesionsCoalesce,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Empezó en hojas inferiores y sube?',
      '¿Las manchas son angulares, circulares, acuosas o tienen halo amarillo?',
      '¿Hay lluvia, rocío prolongado o follaje que permanece mojado?',
      '¿El centro de la mancha se desprende o aparecen puntos oscuros?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Retira solo hojas muy dañadas sin defoliar de golpe la planta.',
      'Evita mojar el follaje al final del día y mejora separación de hojas.',
      'Escala la revisión si llega rápido a hojas superiores, tallo o botón.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  // 9. Polvillo blanco que se extiende sobre la hoja.
  PlantHealthSyndrome(
    id: 'sunflower_powdery_white_growth_09',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Polvillo blanco que se extiende sobre la hoja',
    stages: _postBloomToEndStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomPowderyGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalSporesRubOff,
      PlantHealthIds.signalSunflowerUpperSurfaceWhite,
      PlantHealthIds.signalSunflowerLowerLeavesFirst,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalSunflowerLateAfterBloom,
      PlantHealthIds.signalSunflowerBlackSpecksLate,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalUndersideSporulation,
      PlantHealthIds.signalSunflowerUniformDustResidue,
      PlantHealthIds.signalSunflowerCottonyInsects,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_powdery_mildew_compatible',
        labelEs: 'Condición compatible con oidio',
        type: 'condition_compatible',
        summaryEs: 'Parches blancos superficiales que se desprenden al frotar, más comunes después de floración y en hojas bajas, son compatibles con oídio.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWhitePowderGrowth,
          PlantHealthIds.signalSporesRubOff,
          PlantHealthIds.signalSunflowerUpperSurfaceWhite,
          PlantHealthIds.signalSunflowerLateAfterBloom,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalUndersideSporulation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_downy_mildew_local_possible',
        labelEs: 'Mildiu local por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Crecimiento blanco principalmente bajo la hoja, asociado a manchas amarillas angulares, apunta a otro diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalUndersideSporulation,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerUpperSurfaceWhite,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_residue_or_dust',
        labelEs: 'Polvo, residuo o cera posible',
        type: 'benign_differential',
        summaryEs: 'Una capa uniforme que no progresa y coincide con polvo o aplicación reciente puede no ser biológica.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerUniformDustResidue,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSporesRubOff,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El material blanco se desprende al frotarlo?',
      '¿Está arriba de la hoja, abajo o en ambas caras?',
      '¿Hay manchas amarillas angulares en la cara opuesta?',
      '¿Apareció después de floración y avanza desde hojas bajas?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Confirma que sea crecimiento y no polvo antes de actuar.',
      'Mejora ventilación y evita exceso de nitrógeno o follaje demasiado denso.',
      'Busca revisión si invade rápidamente hojas nuevas o el botón.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
  ),
  // 10. Amarillamiento entre venas con capa blanca bajo la hoja.
  PlantHealthSyndrome(
    id: 'sunflower_downy_mildew_pattern_10',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Amarillamiento entre venas con capa blanca bajo la hoja',
    stages: _seedlingToVegLateStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organRoot,
    },
    primarySymptomId: PlantHealthIds.symptomDownyFuzzyGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalUndersideSporulation,
      PlantHealthIds.signalSunflowerVeinBoundChlorosis,
      PlantHealthIds.signalSunflowerSystemicStunting,
      PlantHealthIds.signalCoolDewyWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalSunflowerYoungPlant,
      PlantHealthIds.signalHumidWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalSporesRubOff,
      PlantHealthIds.signalSunflowerNoStunting,
      PlantHealthIds.signalSunflowerAbioticPatternUniform,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_downy_mildew_compatible',
        labelEs: 'Condición compatible con mildiu del girasol',
        scientificName: 'Plasmopara halstedii',
        type: 'condition_compatible',
        summaryEs: 'Enanismo, clorosis asociada a venas y crecimiento blanco en el envés son un patrón fuerte, pero BIO-G no confirma Plasmopara.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalUndersideSporulation,
          PlantHealthIds.signalSunflowerVeinBoundChlorosis,
          PlantHealthIds.signalSunflowerSystemicStunting,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNoStunting,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_local_downy_lesion_possible',
        labelEs: 'Lesión local tipo mildiu por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Manchas localizadas después de noches frescas y rocío pueden presentarse sin infección sistémica.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalCoolDewyWindow,
          PlantHealthIds.signalHumidWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSystemicStunting,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_cold_or_herbicide_mimic',
        labelEs: 'Estrés ambiental con patrón parecido',
        type: 'abiotic_compatible',
        summaryEs: 'Frío, daño químico o alteración nutricional pueden imitar el amarillamiento si no hay crecimiento activo bajo la hoja.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalSunflowerAbioticPatternUniform,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalUndersideSporulation,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La planta está notablemente más baja que otras de la misma edad?',
      '¿La clorosis sigue las venas principales?',
      '¿Hay capa blanca activa en el envés durante la mañana?',
      '¿El suelo estuvo frío y saturado poco después de la siembra?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Evita mover tierra o agua desde esa planta hacia otras mientras se confirma.',
      'Reduce humedad foliar prolongada y revisa drenaje.',
      'Busca diagnóstico local si hay enanismo sistémico o varias plantas con el mismo patrón.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  // 11. Pústulas naranjas, canela o negras que sueltan polvo.
  PlantHealthSyndrome(
    id: 'sunflower_rust_pustules_11',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Pústulas naranjas, canela o negras que sueltan polvo',
    stages: _foliarDiseaseStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomOrangePustules,
    strongSignals: <String>{
      PlantHealthIds.signalSporesRubOff,
      PlantHealthIds.signalSunflowerCinnamonPustules,
      PlantHealthIds.signalSunflowerYellowHalo,
      PlantHealthIds.signalSunflowerUndersidePustules,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalSunflowerWildVolunteerNearby,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNoClearPustules,
      PlantHealthIds.signalSunflowerSoilSplashOnly,
      PlantHealthIds.signalSunflowerFlatNecroticSpot,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_rust_compatible',
        labelEs: 'Condición compatible con roya del girasol',
        scientificName: 'Puccinia helianthi',
        type: 'condition_compatible',
        summaryEs: 'Pústulas polvosas color canela que se desprenden y pueden llevar halo amarillo son compatibles con roya.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSporesRubOff,
          PlantHealthIds.signalSunflowerCinnamonPustules,
          PlantHealthIds.signalSunflowerYellowHalo,
          PlantHealthIds.signalSunflowerUndersidePustules,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNoClearPustules,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_soil_splash_or_residue',
        labelEs: 'Salpicadura de suelo o residuo posible',
        type: 'benign_differential',
        summaryEs: 'Material superficial en hojas bajas que se limpia sin lesión puede ser tierra.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoilSplashOnly,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSporesRubOff,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_other_foliar_lesion',
        labelEs: 'Otra lesión foliar por confirmar',
        type: 'visual_concern',
        summaryEs: 'Una mancha plana sin polvo requiere otro diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerFlatNecroticSpot,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerCinnamonPustules,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La pústula está levantada y suelta polvo al tocarla?',
      '¿Hay estructuras también en el envés?',
      '¿Se observan hojas superiores nuevas afectadas antes de floración?',
      '¿Hay girasol voluntario o residuos cercanos?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Evita confundir tierra seca con pústulas activas.',
      'Reduce permanencia de agua en hojas y elimina residuos muy infectados.',
      'Escala la revisión si alcanza hojas superiores antes o durante la floración.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  // 12. Amarillamiento entre venas que avanza con marchitez.
  PlantHealthSyndrome(
    id: 'sunflower_interveinal_mottle_and_wilt_12',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Amarillamiento entre venas que avanza con marchitez',
    stages: _lateVegToGrainFillStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomWiltVascular,
    strongSignals: <String>{
      PlantHealthIds.signalOneSidedWilt,
      PlantHealthIds.signalVascularBrowning,
      PlantHealthIds.signalSunflowerInterveinalNecrosis,
      PlantHealthIds.signalSunflowerProgressesUpward,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalSunflowerPatchOrRow,
      PlantHealthIds.signalSunflowerPithShrunkenDark,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerYoungLeavesOnly,
      PlantHealthIds.signalSunflowerRecoversEvening,
      PlantHealthIds.signalSunflowerUniformLateYellowing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_verticillium_pattern_compatible',
        labelEs: 'Patrón compatible con marchitez tipo Verticillium',
        scientificName: 'Verticillium spp.',
        type: 'condition_compatible',
        summaryEs: 'Clorosis y necrosis entre venas desde hojas bajas, avance ascendente y daño vascular forman un patrón compatible.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerInterveinalNecrosis,
          PlantHealthIds.signalSunflowerProgressesUpward,
          PlantHealthIds.signalVascularBrowning,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerYoungLeavesOnly,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_fusarium_or_other_vascular_possible',
        labelEs: 'Otro deterioro vascular por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Fusarium y otros daños de raíz o tallo pueden producir marchitez y pardeamiento similares.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalOneSidedWilt,
          PlantHealthIds.signalSunflowerPithShrunkenDark,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_drought_nutrient_mimic',
        labelEs: 'Estrés hídrico o nutricional con patrón parecido',
        type: 'abiotic_compatible',
        summaryEs: 'Sequía y absorción limitada pueden imitar amarillamiento sin infección vascular.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalDryHotWindow,
          PlantHealthIds.signalSunflowerRecoversEvening,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalVascularBrowning,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Comenzó en hojas inferiores y avanza hacia arriba?',
      '¿Afecta un lado de la planta o plantas en parches?',
      '¿Un corte del tallo muestra un anillo café?',
      '¿Recupera por la noche o continúa perdiendo hojas?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Compara plantas afectadas y sanas de la misma edad.',
      'Revisa raíz, cuello y tejido vascular, no solo el color de la hoja.',
      'Busca evaluación local si el patrón asciende o hay pardeamiento interno.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 13. Hojas inferiores amarillas o que comienzan a secarse.
  PlantHealthSyndrome(
    id: 'sunflower_lower_leaf_yellowing_13',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Hojas inferiores amarillas o que comienzan a secarse',
    stages: _foliarDiseaseStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomLateDefoliation,
    strongSignals: <String>{
      PlantHealthIds.signalSunflowerLowerLeavesOnly,
      PlantHealthIds.signalSunflowerGradualProgression,
      PlantHealthIds.signalSunflowerStageAfterBloom,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSunflowerLowNPattern,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalSunflowerShadedLowerLeaves,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerRapidWholePlantYellow,
      PlantHealthIds.signalSunflowerUpperLeavesFirst,
      PlantHealthIds.signalSunflowerActiveSpotsOrPustules,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_normal_leaf_aging_possible',
        labelEs: 'Envejecimiento normal de hojas bajas posible',
        type: 'benign_differential',
        summaryEs: 'Después de floración, algunas hojas bajas pueden amarillear gradualmente mientras la parte superior continúa funcional.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStageAfterBloom,
          PlantHealthIds.signalSunflowerGradualProgression,
          PlantHealthIds.signalSunflowerLowerLeavesOnly,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRapidWholePlantYellow,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_nitrogen_or_root_uptake_issue',
        labelEs: 'Disponibilidad de nitrógeno o absorción limitada por confirmar',
        type: 'nutrient_context',
        summaryEs: 'Amarillamiento que empieza abajo puede ser compatible con N bajo, pero agua, raíz, pH y etapa deben revisarse antes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerLowNPattern,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStageAfterBloom,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_overwatering_yellowing',
        labelEs: 'Amarillamiento por suelo demasiado húmedo posible',
        type: 'abiotic_compatible',
        summaryEs: 'Suelo húmedo persistente puede producir hojas pálidas, caída y marchitez.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalSunflowerShadedLowerLeaves,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_foliar_or_vascular_disease_possible',
        labelEs: 'Enfermedad foliar o vascular por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Manchas activas, avance rápido o marchitez cambian el diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerActiveSpotsOrPustules,
          PlantHealthIds.signalSunflowerUpperLeavesFirst,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerGradualProgression,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La planta ya floreció y el amarillamiento es gradual?',
      '¿Solo afecta hojas bajas o también hojas nuevas?',
      '¿Hay manchas, pústulas, marchitez o raíz alterada?',
      '¿El suelo está demasiado húmedo, seco o con EC alta?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'No fertilices automáticamente por hojas amarillas en posfloración o senescencia.',
      'Revisa etapa, humedad, raíz y patrón antes de interpretar NPK.',
      'Escala la revisión si el amarillamiento sube rápido o afecta el brote.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 14. Bordes o puntas de hojas secos y quemados.
  PlantHealthSyndrome(
    id: 'sunflower_leaf_edge_scorch_14',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Bordes o puntas de hojas secos y quemados',
    stages: _vegThroughGrainFillStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalLeafEdgeBurn,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalSunflowerOlderLeavesFirst,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalSunflowerWindEvent,
      PlantHealthIds.signalSunflowerRecentFertilizer,
      PlantHealthIds.signalSunflowerSoilDry,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerWaterSoakedMargin,
      PlantHealthIds.signalSunflowerActiveFungalMargin,
      PlantHealthIds.signalSunflowerColdEvent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_drought_heat_scorch',
        labelEs: 'Quemadura por calor o déficit de agua posible',
        type: 'abiotic_compatible',
        summaryEs: 'Bordes secos con suelo seco, calor o viento son compatibles con demanda hídrica excesiva.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalDryHotWindow,
          PlantHealthIds.signalSunflowerSoilDry,
          PlantHealthIds.signalHeatStress,
          PlantHealthIds.signalSunflowerWindEvent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerWaterSoakedMargin,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_salinity_or_fertilizer_burn',
        labelEs: 'Carga salina o fertilizante concentrado posible',
        type: 'abiotic_compatible',
        summaryEs: 'EC alta, costra y daño posterior a fertilización apoyan este diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSalinityLoad,
          PlantHealthIds.signalSunflowerRecentFertilizer,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_potassium_pattern_possible',
        labelEs: 'Patrón compatible con baja disponibilidad de K',
        type: 'nutrient_context',
        summaryEs: 'Quemado marginal en hojas viejas puede parecer K bajo, pero necesita confirmación de suelo, agua y raíz.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerOlderLeavesFirst,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_foliar_disease_margin',
        labelEs: 'Lesión foliar desde el margen por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Manchas definidas, halos o avance independiente de calor requieren otra revisión.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerActiveFungalMargin,
          PlantHealthIds.signalSunflowerWaterSoakedMargin,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalLeafEdgeBurn,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El borde está seco y crujiente o acuoso y en expansión?',
      '¿Hubo calor, viento, suelo seco o fertilización reciente?',
      '¿Existe costra blanca o EC alta?',
      '¿El centro de la hoja sigue verde y el daño empieza en hojas viejas?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Corrige primero humedad y exposición extrema sin aplicar nutrientes por una sola señal.',
      'Revisa EC y drenaje si hubo fertilización o agua salina.',
      'Escala si el margen es acuoso, se expande o afecta hojas nuevas.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 15. Mosaico, hojas deformes o crecimiento anormalmente corto.
  PlantHealthSyndrome(
    id: 'sunflower_mosaic_distortion_or_stunting_15',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Mosaico, hojas deformes o crecimiento anormalmente corto',
    stages: _seedlingToBudStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalSunflowerMosaicLightDark,
      PlantHealthIds.signalSunflowerWitchesBroom,
      PlantHealthIds.signalSunflowerFlowerGreening,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSunflowerLeafCurl,
      PlantHealthIds.signalSunflowerInternodesShort,
      PlantHealthIds.signalSunflowerAphidsOrLeafhoppers,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerUniformNutrientPattern,
      PlantHealthIds.signalSunflowerChemicalDropletPattern,
      PlantHealthIds.signalSunflowerGeneticUniformTrait,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_virus_like_pattern',
        labelEs: 'Patrón compatible con alteración viral por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Mosaico, deformación y enanismo pueden corresponder a virus; síntomas visuales no identifican cuál.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerMosaicLightDark,
          PlantHealthIds.signalSunflowerLeafCurl,
          PlantHealthIds.signalSunflowerInternodesShort,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerGeneticUniformTrait,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_aster_yellows_like_pattern',
        labelEs: 'Patrón compatible con amarillamiento tipo aster yellows',
        type: 'condition_compatible',
        summaryEs: 'Flores verdosas, brotes anormales y enanismo con presión de chicharritas requieren revisión.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerFlowerGreening,
          PlantHealthIds.signalSunflowerWitchesBroom,
          PlantHealthIds.signalSunflowerAphidsOrLeafhoppers,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerGeneticUniformTrait,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_herbicide_or_spray_injury',
        labelEs: 'Daño químico o deriva posible',
        type: 'abiotic_compatible',
        summaryEs: 'Deformación súbita después de aplicación o deriva puede imitar enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerChemicalDropletPattern,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalVectorPresent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_genetic_or_profile_trait',
        labelEs: 'Rasgo de cultivar o perfil posible',
        type: 'benign_differential',
        summaryEs: 'Porte compacto uniforme en todas las plantas del mismo lote puede ser propio del perfil.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerGeneticUniformTrait,
          PlantHealthIds.signalSunflowerUniformNutrientPattern,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerMosaicLightDark,
          PlantHealthIds.signalSunflowerFlowerGreening,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay patrón de verde claro y oscuro o solo amarillamiento uniforme?',
      '¿Las flores se vuelven verdes o aparecen muchos brotes cortos?',
      '¿Se observan pulgones, chicharritas u otros vectores?',
      '¿Hubo aplicación, deriva o daño químico reciente?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Separa una planta muy deformada si está en maceta y revisa otras cercanas.',
      'No apliques un producto sin confirmar insecto o causa.',
      'Busca evaluación local si hay flores verdes, enanismo fuerte o propagación entre plantas.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),
  // ────────────────────────────────────────────────────────────────────────
  // Familia 4: Plagas e invertebrados.
  // ────────────────────────────────────────────────────────────────────────
  // 16. Colonias de pulgones, hojas pegajosas o enrolladas.
  PlantHealthSyndrome(
    id: 'sunflower_aphid_colonies_honeydew_16',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Colonias de pulgones, hojas pegajosas o enrolladas',
    stages: _vegToBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomAphidColonies,
    strongSignals: <String>{
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
      PlantHealthIds.signalLeafRolling,
      PlantHealthIds.signalSunflowerVisibleAphidClusters,
    },
    weakSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalSunflowerAntActivity,
      PlantHealthIds.signalSunflowerTenderNewGrowth,
      PlantHealthIds.signalSunflowerHighNitrogenContext,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerNoInsectsFound,
      PlantHealthIds.signalSunflowerFineWebbingOnly,
      PlantHealthIds.signalSunflowerDryDust,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_aphid_infestation_compatible',
        labelEs: 'Pulgones presentes o muy probables',
        type: 'invertebrate_compatible',
        summaryEs: 'Colonias visibles, mielecilla, hormigas y hojas enrolladas forman un cuadro consistente con pulgones.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerVisibleAphidClusters,
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalSootyMold,
          PlantHealthIds.signalSunflowerAntActivity,
          PlantHealthIds.signalLeafRolling,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNoInsectsFound,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_honeydew_other_sucking_insect',
        labelEs: 'Otro insecto chupador posible',
        type: 'invertebrate_possible',
        summaryEs: 'Mosca blanca, escamas u otros insectos también pueden producir mielecilla.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalSootyMold,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerVisibleAphidClusters,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_virus_risk_context',
        labelEs: 'Riesgo de transmisión de virus, no diagnóstico',
        type: 'risk_context',
        summaryEs: 'La presencia de vectores aumenta cautela si además existe mosaico o deformación.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalVectorPresent,
        },
        contradictorySignalIds: <String>{},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Se ven insectos en grupos en brotes, tallos o envés?',
      '¿La superficie está pegajosa y hay hormigas o tizne negro?',
      '¿Las hojas están enrolladas o solo amarillas?',
      '¿Hay mariquitas, crisopas, larvas de sírfidos o pulgones momificados?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Confirma la colonia antes de aplicar cualquier producto.',
      'En una planta firme, un chorro de agua dirigido puede desprender colonias pequeñas sin mojar la flor durante horas.',
      'Protege polinizadores y enemigos naturales; evita aplicaciones indiscriminadas en flor abierta.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsVectorPressure: true,
  ),
  // 17. Punteado fino, bronceado o telaraña muy delgada.
  PlantHealthSyndrome(
    id: 'sunflower_mite_stippling_and_webbing_17',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Punteado fino, bronceado o telaraña muy delgada',
    stages: _midVegToGrainFillStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalSunflowerFineStippling,
      PlantHealthIds.signalSunflowerMitesWithLens,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalSunflowerLowerLeafUnderside,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerStickyHoneydew,
      PlantHealthIds.signalSunflowerLargeChewedHoles,
      PlantHealthIds.signalSunflowerPowderRubOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_spider_mite_compatible',
        labelEs: 'Ácaros tipo araña compatibles con el patrón',
        type: 'invertebrate_compatible',
        summaryEs: 'Punteado, blanqueamiento, bronceado, fibras finas y organismos en el envés son compatibles con ácaros.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
          PlantHealthIds.signalBronzedLeafSurface,
          PlantHealthIds.signalSunflowerFineStippling,
          PlantHealthIds.signalSunflowerMitesWithLens,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStickyHoneydew,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_thrips_or_true_bug_mimic',
        labelEs: 'Trips o chinches como diferencial',
        type: 'invertebrate_possible',
        summaryEs: 'Otros chupadores también producen punteado o plateado; importa observar el organismo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerFineStippling,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_heat_dust_injury',
        labelEs: 'Daño por calor, polvo o abrasión posible',
        type: 'abiotic_compatible',
        summaryEs: 'Follaje opaco sin organismos ni telaraña puede ser ambiental.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalDryHotWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
          PlantHealthIds.signalSunflowerMitesWithLens,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay telaraña muy fina, mudas u organismos con lupa en el envés?',
      '¿El daño empezó en hojas inferiores durante clima seco y caliente?',
      '¿Hay mielecilla o insectos alargados en vez de ácaros?',
      '¿El punteado aumenta entre revisiones?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Inspecciona el envés con lupa antes de concluir.',
      'Reduce estrés por sequía y polvo, sin mantener el suelo saturado.',
      'Evita tratamientos de amplio espectro que puedan eliminar enemigos naturales y empeorar los ácaros.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 18. Plateado, raspado o deformación en hojas, botón o pétalos.
  PlantHealthSyndrome(
    id: 'sunflower_thrips_or_sucking_scar_18',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Plateado, raspado o deformación en hojas, botón o pétalos',
    stages: _stemElongationToBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFlowerHead,
    },
    primarySymptomId: PlantHealthIds.symptomThripsSilverScarring,
    strongSignals: <String>{
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalSunflowerDarkFecalSpecks,
      PlantHealthIds.signalSunflowerBudScarring,
    },
    weakSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalSunflowerPetalDistortion,
      PlantHealthIds.signalSunflowerDamageInsideBud,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerNoInsectsFound,
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalSunflowerMechanicalTear,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_thrips_compatible',
        labelEs: 'Daño compatible con trips',
        type: 'invertebrate_compatible',
        summaryEs: 'Raspado plateado, puntos fecales y pequeños insectos dentro de botones apoyan este diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalThripsPresent,
          PlantHealthIds.signalSunflowerDarkFecalSpecks,
          PlantHealthIds.signalSunflowerDamageInsideBud,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNoInsectsFound,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_true_bug_feeding_possible',
        labelEs: 'Chinche u otro chupador posible',
        type: 'invertebrate_possible',
        summaryEs: 'Punteado, deformación y daño de botón también pueden provenir de chinches.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerBudScarring,
          PlantHealthIds.signalSunflowerPetalDistortion,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalThripsPresent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_abiotic_or_mechanical_scar',
        labelEs: 'Cicatriz ambiental o física posible',
        type: 'physical_damage',
        summaryEs: 'Viento, roce y quemadura pueden dejar marcas parecidas sin insectos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerMechanicalTear,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalThripsPresent,
          PlantHealthIds.signalSunflowerDarkFecalSpecks,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Se observan insectos delgados dentro del botón o al sacudir sobre papel claro?',
      '¿Hay pequeños puntos negros junto al plateado?',
      '¿El daño apareció antes de abrirse la flor?',
      '¿Hubo viento, roce o producto aplicado recientemente?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Confirma insectos vivos; el daño puede permanecer cuando ya se fueron.',
      'Evita tratar una flor abierta sin considerar polinizadores y etiqueta del producto.',
      'Retira solo tejido muy deformado si no compromete la floración ramificada.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsVectorPressure: true,
  ),
  // 19. Hojas o pétalos con mordidas, agujeros o pérdida de tejido.
  PlantHealthSyndrome(
    id: 'sunflower_chewed_holes_or_defoliation_19',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Hojas o pétalos con mordidas, agujeros o pérdida de tejido',
    stages: _seedlingThroughBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalSunflowerLarvaOrBeetleVisible,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSunflowerNightDamage,
      PlantHealthIds.signalSunflowerSlimeTrail,
      PlantHealthIds.signalSunflowerRaggedMargin,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNoBiteMarks,
      PlantHealthIds.signalSunflowerNecroticSpotIntact,
      PlantHealthIds.signalSunflowerHailTearPattern,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_caterpillar_or_beetle_feeding',
        labelEs: 'Oruga o escarabajo masticador posible',
        type: 'invertebrate_possible',
        summaryEs: 'Mordidas activas, excremento y larvas o escarabajos visibles apoyan este diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalActiveChewing,
          PlantHealthIds.signalFrassPresent,
          PlantHealthIds.signalSunflowerLarvaOrBeetleVisible,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNoBiteMarks,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_slug_or_snail_feeding',
        labelEs: 'Babosa o caracol posible',
        type: 'invertebrate_possible',
        summaryEs: 'Agujeros irregulares y rastro brillante durante condiciones húmedas son compatibles.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSlimeTrail,
          PlantHealthIds.signalSunflowerRaggedMargin,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_hail_wind_or_mechanical_tears',
        labelEs: 'Desgarro por granizo, viento o roce posible',
        type: 'physical_damage',
        summaryEs: 'Daño simultáneo y bordes rasgados sin consumo nuevo puede ser físico.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHailTearPattern,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalActiveChewing,
          PlantHealthIds.signalFrassPresent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_leaf_spot_tissue_drop',
        labelEs: 'Tejido desprendido por mancha foliar posible',
        type: 'condition_compatible',
        summaryEs: 'Centros necróticos que caen pueden parecer mordidas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNecroticSpotIntact,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalFeedingHoles,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay excremento, larvas o actividad al anochecer?',
      '¿Se observa rastro brillante en suelo u hojas?',
      '¿El daño apareció de golpe después de viento o granizo?',
      '¿Cada agujero comenzó como una mancha café con halo?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Busca al causante antes de aplicar un producto.',
      'Retira manualmente organismos visibles cuando sea seguro y viable.',
      'Protege especialmente plántulas si la pérdida de hoja progresa.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 20. Tallo cortado o mordido junto al suelo.
  PlantHealthSyndrome(
    id: 'sunflower_stem_cut_at_soil_line_20',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Tallo cortado o mordido junto al suelo',
    stages: _earlySeedlingStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSeedlingCollapse,
    strongSignals: <String>{
      PlantHealthIds.signalSunflowerStemCleanCut,
      PlantHealthIds.signalSunflowerNightDamage,
      PlantHealthIds.signalSunflowerCShapedLarva,
      PlantHealthIds.signalFeedingHoles,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSunflowerSoilDisturbed,
      PlantHealthIds.signalSunflowerSlimeTrail,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSeedlingNeckCollapse,
      PlantHealthIds.signalSunflowerSoftDarkNeck,
      PlantHealthIds.signalRootsDarkRot,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_cutworm_compatible',
        labelEs: 'Daño compatible con gusano cortador',
        type: 'invertebrate_compatible',
        summaryEs: 'Un tallo firme cortado al nivel del suelo y larva curvada cercana son un patrón compatible.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemCleanCut,
          PlantHealthIds.signalSunflowerCShapedLarva,
          PlantHealthIds.signalSunflowerNightDamage,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoftDarkNeck,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_slug_snail_seedling_damage',
        labelEs: 'Daño de babosa o caracol posible',
        type: 'invertebrate_possible',
        summaryEs: 'Tejido raspado, rastro brillante y actividad nocturna en suelo húmedo apoyan este diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSlimeTrail,
          PlantHealthIds.signalSunflowerNightDamage,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemCleanCut,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_mechanical_or_animal_break',
        labelEs: 'Quiebre físico o por fauna posible',
        type: 'physical_damage',
        summaryEs: 'Pisada, herramienta, ave o roedor también pueden cortar la plántula.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoilDisturbed,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_damping_off_mimic',
        labelEs: 'Damping-off como diferencial',
        type: 'condition_compatible',
        summaryEs: 'Cuello blando, oscuro y podrido no es un corte masticado.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSeedlingNeckCollapse,
          PlantHealthIds.signalRootsDarkRot,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemCleanCut,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El corte es firme y limpio o blando y oscuro?',
      '¿Hay larva curvada, rastro de baba o actividad nocturna?',
      '¿El suelo está removido o hay huellas?',
      '¿Otras plántulas caen sin mordida visible?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Protege las plántulas restantes y revisa el área al anochecer.',
      'No atribuyas el corte a hongos si el tejido está firme y masticado.',
      'Retira el organismo visible de forma manual cuando sea posible.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 21. Daño por aves, roedores u otra fauna.
  PlantHealthSyndrome(
    id: 'sunflower_wildlife_head_or_seedling_damage_21',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Daño por aves, roedores u otra fauna',
    stages: _wildlifeRiskStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organFlowerHead,
      PlantHealthIds.organStem,
      PlantHealthIds.organSeed,
    },
    primarySymptomId: PlantHealthIds.symptomSunflowerWildlifeDamage,
    strongSignals: <String>{
      PlantHealthIds.signalSunflowerPeckMarks,
      PlantHealthIds.signalSunflowerMissingSeeds,
      PlantHealthIds.signalSunflowerBitePattern,
      PlantHealthIds.signalSunflowerTracksOrDroppings,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSunflowerStemBentByWeight,
      PlantHealthIds.signalSunflowerHeadExposed,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerSoftRot,
      PlantHealthIds.signalSunflowerGrayMycelium,
      PlantHealthIds.signalSunflowerInsectFrassInsideStem,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_bird_feeding_possible',
        labelEs: 'Alimentación o posado de aves posible',
        type: 'wildlife_damage',
        summaryEs: 'Picotazos, semillas faltantes y cabezas dobladas sin pudrición son compatibles.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerPeckMarks,
          PlantHealthIds.signalSunflowerMissingSeeds,
          PlantHealthIds.signalSunflowerStemBentByWeight,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoftRot,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_rodent_or_mammal_damage',
        labelEs: 'Roedor u otro mamífero posible',
        type: 'wildlife_damage',
        summaryEs: 'Mordidas mayores, tallos cortados y huellas apoyan este diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerBitePattern,
          PlantHealthIds.signalSunflowerTracksOrDroppings,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_insect_or_rot_mimic',
        labelEs: 'Insecto o deterioro de cabeza por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Agujeros con excremento fino o tejido blando requieren otro análisis.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerInsectFrassInsideStem,
          PlantHealthIds.signalSunflowerSoftRot,
          PlantHealthIds.signalSunflowerGrayMycelium,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerPeckMarks,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay marcas de pico, dientes, huellas o excremento?',
      '¿Faltan semillas o tejido sin que exista pudrición?',
      '¿El daño ocurre de noche o durante visitas de aves?',
      '¿La cabeza está blanda, con moho u olor además de mordida?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Usa barrera física que no atrape ni lastime fauna.',
      'Sostén la planta si el posado dobló el tallo.',
      'Revisa heridas húmedas porque pueden abrir paso a pudriciones secundarias.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // ────────────────────────────────────────────────────────────────────────
  // Familia 5: Boton, flor y capitulo.
  // ────────────────────────────────────────────────────────────────────────
  // 22. No forma botón cuando el reloj ya lo esperaba.
  PlantHealthSyndrome(
    id: 'sunflower_bud_delayed_or_absent_22',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'No forma botón cuando el reloj ya lo esperaba',
    stages: _budFormationWindowStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSunflowerBudDelayed,
    strongSignals: <String>{
      PlantHealthIds.signalSunflowerNoBudPastWindow,
      PlantHealthIds.signalSunflowerLongThinGrowth,
      PlantHealthIds.signalSunflowerLowLight,
      PlantHealthIds.signalSunflowerExcessVegetativeGrowth,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalSunflowerRootRestricted,
      PlantHealthIds.signalSunflowerStageDateUncertain,
      PlantHealthIds.signalSalinityLoad,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerBudHiddenPresent,
      PlantHealthIds.signalSunflowerProfileLate,
      PlantHealthIds.signalSunflowerRecentSowingEstimate,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_stage_or_profile_mismatch',
        labelEs: 'Fecha o perfil no representativo posible',
        type: 'model_context',
        summaryEs: 'La variedad, fecha estimada o trasplante pueden desplazar la ventana sin que exista un problema sanitario.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStageDateUncertain,
          PlantHealthIds.signalSunflowerProfileLate,
          PlantHealthIds.signalSunflowerRecentSowingEstimate,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNoBudPastWindow,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_low_light_etiolation',
        labelEs: 'Luz insuficiente con crecimiento estirado posible',
        type: 'abiotic_compatible',
        summaryEs: 'Internudos largos, tallo fino y follaje pálido apoyan falta de luz.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerLowLight,
          PlantHealthIds.signalSunflowerLongThinGrowth,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_excess_nitrogen_vegetative_bias',
        labelEs: 'Crecimiento vegetativo desbalanceado posible',
        type: 'nutrient_context',
        summaryEs: 'Exceso de N puede favorecer follaje y retrasar la transición, pero no se confirma con apariencia sola.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerExcessVegetativeGrowth,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_root_or_heat_stress_delay',
        labelEs: 'Estrés de raíz, calor o sales posible',
        type: 'abiotic_compatible',
        summaryEs: 'Raíz limitada, calor sostenido y EC alta pueden retrasar desarrollo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRootRestricted,
          PlantHealthIds.signalHeatStress,
          PlantHealthIds.signalSalinityLoad,
        },
        contradictorySignalIds: <String>{},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La fecha de siembra es conocida o fue estimada desde una planta comprada?',
      '¿El perfil elegido corresponde a compacto, alto, ramificado o corte?',
      '¿Recibe sol directo suficiente y el tallo está estirado?',
      '¿Existe botón pequeño oculto entre hojas superiores?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Valida fecha y perfil antes de declarar falla de floración.',
      'Revisa luz, raíz, humedad, EC y exceso vegetativo de forma conjunta.',
      'No apliques P o K automáticamente para “forzar” un botón.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 23. Botón que deja de crecer, se seca o cae.
  PlantHealthSyndrome(
    id: 'sunflower_bud_abortion_or_drying_23',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Botón que deja de crecer, se seca o cae',
    stages: _budAndBloomStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organFlowerHead,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalFlowerDrop,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalSunflowerBudBrownDry,
    },
    weakSignals: <String>{
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalSunflowerBudSoftGray,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalSunflowerStemCrease,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerNormalPetalAging,
      PlantHealthIds.signalSunflowerBudOpeningNormally,
      PlantHealthIds.signalSunflowerCutPerformed,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_heat_drought_bud_abort',
        labelEs: 'Aborto de botón por calor o déficit hídrico posible',
        type: 'abiotic_compatible',
        summaryEs: 'Calor fuerte y suelo seco durante botón pueden detener desarrollo o secar tejido reproductivo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHeatStress,
          PlantHealthIds.signalDryHotWindow,
          PlantHealthIds.signalSunflowerBudBrownDry,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerBudOpeningNormally,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_thrips_bug_bud_damage',
        labelEs: 'Daño de trips o chinche por confirmar',
        type: 'invertebrate_possible',
        summaryEs: 'Cicatrices, insectos dentro del botón y deformación apoyan alimentación.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalThripsPresent,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_botrytis_bud_damage_possible',
        labelEs: 'Deterioro húmedo del botón por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Tejido blando con moho gris en ambiente húmedo requiere revisión sanitaria.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerBudSoftGray,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerBudBrownDry,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_physical_bud_injury',
        labelEs: 'Golpe, roce o quiebre posible',
        type: 'physical_damage',
        summaryEs: 'Viento, granizo o manipulación pueden abortar un botón.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemCrease,
          PlantHealthIds.signalSunflowerCutPerformed,
        },
        contradictorySignalIds: <String>{},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El botón está seco y firme o blando y gris?',
      '¿Hubo calor, suelo seco, viento o granizo?',
      '¿Se observan trips, raspado o puntos fecales?',
      '¿El tallo debajo del botón está doblado o lesionado?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Estabiliza humedad sin saturar el suelo.',
      'Evita mojar el botón y confirma insectos antes de tratar.',
      'En perfil ramificado, revisa si otros botones continúan sanos antes de cerrar la floración.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  // 24. Flor o capítulo deforme, incompleto o asimétrico.
  PlantHealthSyndrome(
    id: 'sunflower_flower_malformed_or_asymmetric_24',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Flor o capítulo deforme, incompleto o asimétrico',
    stages: _budAndBloomStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organFlowerHead,
    },
    primarySymptomId: PlantHealthIds.symptomSunflowerHeadDeformation,
    strongSignals: <String>{
      PlantHealthIds.signalSunflowerHeadAsymmetric,
      PlantHealthIds.signalSunflowerPetalDistortion,
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalSunflowerFasciatedStem,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalSunflowerPhysicalDamage,
      PlantHealthIds.signalVectorPresent,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerCultivarNormalDoubleFlower,
      PlantHealthIds.signalSunflowerUniformTraitAcrossBatch,
      PlantHealthIds.signalSunflowerNormalOpeningSequence,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_insect_feeding_deformation',
        labelEs: 'Daño de insecto durante formación posible',
        type: 'invertebrate_possible',
        summaryEs: 'Trips, chinches u otros organismos dentro del botón pueden alterar pétalos y disco.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalThripsPresent,
          PlantHealthIds.signalSunflowerPetalDistortion,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerCultivarNormalDoubleFlower,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_heat_or_water_developmental_stress',
        labelEs: 'Estrés térmico o hídrico durante formación posible',
        type: 'abiotic_compatible',
        summaryEs: 'Eventos fuertes antes de apertura pueden dejar una flor incompleta.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHeatStress,
          PlantHealthIds.signalRecentStress,
          PlantHealthIds.signalSunflowerPhysicalDamage,
        },
        contradictorySignalIds: <String>{},
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_fasciation_or_genetic_trait',
        labelEs: 'Fasciación o rasgo genético posible',
        type: 'benign_differential',
        summaryEs: 'Tallo aplanado, varias cabezas fusionadas o flores dobles uniformes pueden ser una alteración de desarrollo o cultivar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerFasciatedStem,
          PlantHealthIds.signalSunflowerCultivarNormalDoubleFlower,
          PlantHealthIds.signalSunflowerUniformTraitAcrossBatch,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHeadAsymmetric,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_virus_or_aster_yellows_possible',
        labelEs: 'Alteración tipo virus o aster yellows por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Flores verdes, proliferación de brotes y enanismo cambian el diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalVectorPresent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNormalOpeningSequence,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El tallo o botón estaba deformado antes de abrir?',
      '¿Se ven insectos, raspado o puntos oscuros?',
      '¿Otras plantas de la misma variedad tienen la misma forma?',
      '¿La flor es verde, prolifera en brotes o la planta está enana?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Compara con la descripción del cultivar antes de clasificarlo como problema.',
      'Revisa botones nuevos e insectos, no solo la flor ya abierta.',
      'Escala si el patrón se repite con mosaico, enanismo o flores verdes.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),
  // 25. Pétalos o flores que se manchan, se pegan o desarrollan moho gris.
  PlantHealthSyndrome(
    id: 'sunflower_petals_browning_or_gray_mold_25',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Pétalos o flores que se manchan, se pegan o desarrollan moho gris',
    stages: _bloomToPostBloomStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organFlowerHead,
    },
    primarySymptomId: PlantHealthIds.symptomGrayMoldNecrosis,
    strongSignals: <String>{
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalSunflowerPetalsWetStuck,
      PlantHealthIds.signalSunflowerLesionProgressing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalSunflowerOldFlower,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerPetalsDryUniform,
      PlantHealthIds.signalSunflowerNormalPetalDrop,
      PlantHealthIds.signalSunflowerNoGrayGrowth,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_botrytis_like_flower_blight',
        labelEs: 'Condición compatible con moho gris tipo Botrytis',
        scientificName: 'Botrytis cinerea',
        type: 'condition_compatible',
        summaryEs: 'Tejido café húmedo, pétalos pegados y crecimiento gris en ambiente húmedo son compatibles.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
          PlantHealthIds.signalHumidWindow,
          PlantHealthIds.signalSunflowerPetalsWetStuck,
          PlantHealthIds.signalSunflowerLesionProgressing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerPetalsDryUniform,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_normal_flower_aging',
        labelEs: 'Envejecimiento normal de la flor posible',
        type: 'benign_differential',
        summaryEs: 'Pétalos secos de forma uniforme después de varios días de apertura pueden ser normales.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerOldFlower,
          PlantHealthIds.signalSunflowerPetalsDryUniform,
          PlantHealthIds.signalSunflowerNormalPetalDrop,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_heat_scorch_petals',
        labelEs: 'Quemadura de pétalos por calor o sol posible',
        type: 'abiotic_compatible',
        summaryEs: 'Bordes secos del lado expuesto sin moho pueden corresponder a calor.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerPetalsDryUniform,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_thrips_petals',
        labelEs: 'Daño de trips en pétalos posible',
        type: 'invertebrate_possible',
        summaryEs: 'Raspado, plateado y pequeños insectos dentro de la flor apoyan este diferencial.',
        confirmatorySignalIds: <String>{},
        contradictorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Los pétalos están secos o húmedos y pegados?',
      '¿Hay crecimiento gris que aumenta?',
      '¿Cuántos días lleva abierta la flor?',
      '¿El daño coincide con lluvia, rocío, calor o trips?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Evita mojar la flor y mejora ventilación.',
      'Retira pétalos o cabezas muy deteriorados sin tocar flores sanas con herramientas sucias.',
      'Busca revisión si el moho entra al reverso del capítulo o avanza rápidamente.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  // 26. Capítulo blando, acuoso, oscuro o con olor.
  PlantHealthSyndrome(
    id: 'sunflower_head_wet_soft_rot_26',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Capítulo blando, acuoso, oscuro o con olor',
    stages: _bloomToPostBloomStages,
    organIds: <String>{
      PlantHealthIds.organFlowerHead,
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomSunflowerHeadSoftRot,
    strongSignals: <String>{
      PlantHealthIds.signalSunflowerHeadSoftWatery,
      PlantHealthIds.signalSunflowerRottenOdor,
      PlantHealthIds.signalSunflowerSlime,
      PlantHealthIds.signalSunflowerHeadWound,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalSunflowerHailBirdInjury,
      PlantHealthIds.signalSunflowerWarmHumidWeather,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerHeadDryFirm,
      PlantHealthIds.signalSunflowerNormalPostBloomDroop,
      PlantHealthIds.signalSunflowerNoOdor,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_bacterial_head_rot_compatible',
        labelEs: 'Condición compatible con pudrición bacteriana de cabeza',
        type: 'condition_compatible',
        summaryEs: 'Lesión acuosa que se vuelve café, masa viscosa y olor fuerte después de herida forman un patrón compatible.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHeadSoftWatery,
          PlantHealthIds.signalSunflowerRottenOdor,
          PlantHealthIds.signalSunflowerSlime,
          PlantHealthIds.signalSunflowerHeadWound,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHeadDryFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_rhizopus_head_rot_possible',
        labelEs: 'Pudrición tipo Rhizopus por confirmar',
        scientificName: 'Rhizopus spp.',
        type: 'condition_compatible',
        summaryEs: 'Herida seguida de pudrición blanda y después hilos grises con puntos negros apoya este diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHeadWound,
          PlantHealthIds.signalSunflowerHeadSoftWatery,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHeadDryFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_sclerotinia_head_rot_possible',
        labelEs: 'Pudrición tipo Sclerotinia por confirmar',
        scientificName: 'Sclerotinia sclerotiorum',
        type: 'condition_compatible',
        summaryEs: 'Área grande blanda en el reverso, micelio blanco y estructuras negras duras forman otro patrón.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHeadSoftWatery,
          PlantHealthIds.signalHumidWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHeadDryFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_botrytis_head_damage_possible',
        labelEs: 'Moho gris del capítulo por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Crecimiento gris y tejido húmedo sin los otros signos requiere diferenciación.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerWarmHumidWeather,
          PlantHealthIds.signalHumidWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNoOdor,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La cabeza está blanda y acuosa o seca y firme?',
      '¿Hay olor fuerte, baba, hilos grises, moho blanco o estructuras negras duras?',
      '¿Hubo granizo, ave, insecto o herida en la cabeza?',
      '¿El reverso del capítulo está afectado y el daño avanza?',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Evita tocar plantas sanas después de manipular el tejido afectado.',
      'Aísla una maceta afectada y evita riego sobre la cabeza.',
      'Busca evaluación local el mismo día si hay olor, baba, desintegración o pérdida de soporte.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  // 27. Capítulo que se seca de forma irregular, se deshilacha o presenta moho.
  PlantHealthSyndrome(
    id: 'sunflower_head_dry_shredded_or_moldy_27',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Capítulo que se seca de forma irregular, se deshilacha o presenta moho',
    stages: _endOfCycleStages,
    organIds: <String>{
      PlantHealthIds.organFlowerHead,
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomSunflowerHeadDryRot,
    strongSignals: <String>{
      PlantHealthIds.signalSunflowerHeadShredded,
      PlantHealthIds.signalSunflowerWhiteMycelium,
      PlantHealthIds.signalSunflowerBlackSclerotia,
      PlantHealthIds.signalSunflowerGrayThreadsBlackPins,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalSunflowerPriorSoftRot,
      PlantHealthIds.signalSunflowerHeadWound,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerUniformNormalDrying,
      PlantHealthIds.signalSunflowerSeedsFirm,
      PlantHealthIds.signalSunflowerNoMoldStructures,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_sclerotinia_head_pattern',
        labelEs: 'Patrón compatible con deterioro tipo Sclerotinia',
        scientificName: 'Sclerotinia sclerotiorum',
        type: 'condition_compatible',
        summaryEs: 'Cabeza desintegrada, micelio blanco y estructuras negras duras son señales fuertes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHeadShredded,
          PlantHealthIds.signalSunflowerWhiteMycelium,
          PlantHealthIds.signalSunflowerBlackSclerotia,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerUniformNormalDrying,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_rhizopus_dry_phase',
        labelEs: 'Fase seca de pudrición tipo Rhizopus posible',
        scientificName: 'Rhizopus spp.',
        type: 'condition_compatible',
        summaryEs: 'Hilos grises y puntos negros dentro de una cabeza previamente blanda o herida apoyan este diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerGrayThreadsBlackPins,
          PlantHealthIds.signalSunflowerPriorSoftRot,
          PlantHealthIds.signalSunflowerHeadWound,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerUniformNormalDrying,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_normal_head_maturation',
        labelEs: 'Secado normal del capítulo posible',
        type: 'benign_differential',
        summaryEs: 'Secado uniforme, firme, sin olor, moho ni desintegración puede ser cierre normal del ciclo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerUniformNormalDrying,
          PlantHealthIds.signalSunflowerSeedsFirm,
          PlantHealthIds.signalSunflowerNoMoldStructures,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerWhiteMycelium,
          PlantHealthIds.signalSunflowerBlackSclerotia,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_bird_or_insect_shredding',
        labelEs: 'Daño por fauna o insectos posible',
        type: 'physical_damage',
        summaryEs: 'Tejido arrancado con marcas de alimentación y sin crecimiento fúngico requiere otro diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHeadShredded,
          PlantHealthIds.signalSunflowerNoMoldStructures,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerWhiteMycelium,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El secado es uniforme o hay zonas blandas, deshilachadas o colapsadas?',
      '¿Hay moho blanco, estructuras negras duras o hilos grises?',
      '¿Existe olor o hubo una fase acuosa previa?',
      '¿Se observan marcas de aves o insectos?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Distingue secado uniforme de desintegración con estructuras de moho.',
      'No composte tejido con deterioro evidente junto a otras plantas.',
      'Busca evaluación si existen esclerocios, hilos grises o expansión hacia el tallo.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
  ),
  // 28. La cabeza se inclina después de abrirse.
  PlantHealthSyndrome(
    id: 'sunflower_head_droop_after_bloom_28',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'La cabeza se inclina después de abrirse',
    stages: _postBloomToEndStages,
    organIds: <String>{
      PlantHealthIds.organFlowerHead,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSunflowerHeadDroop,
    strongSignals: <String>{
      PlantHealthIds.signalSunflowerHeadHeavy,
      PlantHealthIds.signalSunflowerStageAfterBloom,
      PlantHealthIds.signalSunflowerStemFirm,
      PlantHealthIds.signalSunflowerNormalPostBloomDroop,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSunflowerBirdPerching,
      PlantHealthIds.signalSunflowerLargeHeadProfile,
      PlantHealthIds.signalSunflowerGradualAngle,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerWholePlantWilt,
      PlantHealthIds.signalSunflowerNeckSoftDark,
      PlantHealthIds.signalSunflowerStemCrease,
      PlantHealthIds.signalSunflowerRapidCollapse,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_normal_post_bloom_head_droop',
        labelEs: 'Inclinación normal por peso y madurez posible',
        type: 'benign_differential',
        summaryEs: 'Una cabeza pesada puede inclinarse después de floración mientras tallo, cuello y hojas permanecen firmes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHeadHeavy,
          PlantHealthIds.signalSunflowerStageAfterBloom,
          PlantHealthIds.signalSunflowerStemFirm,
          PlantHealthIds.signalSunflowerGradualAngle,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNeckSoftDark,
          PlantHealthIds.signalSunflowerRapidCollapse,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_structural_bending',
        labelEs: 'Doblez estructural por viento o peso posible',
        type: 'physical_damage',
        summaryEs: 'Pliegue, rajadura o cambio tras viento requiere soporte.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemCrease,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_neck_or_head_deterioration',
        labelEs: 'Deterioro del cuello o capítulo por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Tejido blando, oscuro, olor o colapso rápido no es una inclinación normal.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNeckSoftDark,
          PlantHealthIds.signalSunflowerRapidCollapse,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_water_stress_whole_plant',
        labelEs: 'Estrés hídrico de planta completa posible',
        type: 'abiotic_compatible',
        summaryEs: 'Si hojas y tallo también pierden turgencia debe revisarse el agua y la raíz.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerWholePlantWilt,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStemFirm,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Solo se inclina la cabeza o toda la planta está marchita?',
      '¿El cuello bajo la cabeza está firme y sin lesión?',
      '¿La flor lleva varios días abierta y la inclinación fue gradual?',
      '¿Hubo viento, aves posadas o un pliegue visible?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'No aumentes el riego solo porque una cabeza madura se incline.',
      'Da soporte si el tallo corre riesgo de quebrarse.',
      'Escala si el cuello se ablanda, oscurece o el colapso avanza rápido.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // ────────────────────────────────────────────────────────────────────────
  // Familia 6: Estres abiotico y final de ciclo.
  // ────────────────────────────────────────────────────────────────────────
  // 29. Suelo muy húmedo con amarillamiento, caída o crecimiento detenido.
  PlantHealthSyndrome(
    id: 'sunflower_waterlogging_yellow_wilt_29',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Suelo muy húmedo con amarillamiento, caída o crecimiento detenido',
    stages: _seedlingThroughBloomStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organRoot,
      PlantHealthIds.organLeaf,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalSunflowerWiltInWetSoil,
      PlantHealthIds.signalSunflowerDrainagePoor,
      PlantHealthIds.signalSunflowerSoilWetForDays,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalSunflowerLowerLeafYellow,
      PlantHealthIds.signalHumidWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerSoilDry,
      PlantHealthIds.signalSunflowerRecoversAfterWater,
      PlantHealthIds.signalSunflowerNormalSenescence,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_waterlogging_stress',
        labelEs: 'Estrés por exceso de agua compatible',
        type: 'abiotic_compatible',
        summaryEs: 'Suelo húmedo persistente puede reducir oxígeno, detener raíces y producir marchitez o amarillamiento.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalSunflowerWiltInWetSoil,
          PlantHealthIds.signalSunflowerDrainagePoor,
          PlantHealthIds.signalSunflowerSoilWetForDays,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoilDry,
          PlantHealthIds.signalSunflowerRecoversAfterWater,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_secondary_root_rot_risk',
        labelEs: 'Riesgo de deterioro radicular secundario',
        type: 'risk_context',
        summaryEs: 'La permanencia húmeda aumenta el riesgo, pero la sonda no confirma infección.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalSunflowerSoilWetForDays,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRecoversAfterWater,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_nutrient_uptake_block',
        labelEs: 'Absorción temporalmente limitada posible',
        type: 'nutrient_context',
        summaryEs: 'Raíces sin oxígeno pueden mostrar síntomas que parecen deficiencia aunque haya nutrientes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerLowerLeafYellow,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNormalSenescence,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Cuántos días lleva húmeda la zona radicular?',
      '¿La maceta drena y los orificios están libres?',
      '¿La planta se marchita aunque la lectura sea alta?',
      '¿Las raíces siguen firmes y claras?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Detén riegos mientras la zona siga húmeda.',
      'Mejora salida de agua sin dañar raíces ni remover todo el sustrato de golpe.',
      'Revisa raíz y cuello si la marchitez o amarillamiento progresa.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsHighHumidity: true,
  ),
  // 30. Marchitez, hojas flácidas o secado durante calor y sequedad.
  PlantHealthSyndrome(
    id: 'sunflower_drought_heat_turgor_loss_30',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Marchitez, hojas flácidas o secado durante calor y sequedad',
    stages: _vegThroughGrainFillStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomSunflowerTurgorLoss,
    strongSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalSunflowerSoilDry,
      PlantHealthIds.signalSunflowerWholePlantFlaccid,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSunflowerLeafEdgeDry,
      PlantHealthIds.signalSunflowerContainerHeated,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalSunflowerRootRotSigns,
      PlantHealthIds.signalSunflowerNormalPostBloomDroop,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_drought_stress',
        labelEs: 'Estrés por déficit de agua compatible',
        type: 'abiotic_compatible',
        summaryEs: 'Suelo seco profundo, pérdida de turgencia y recuperación después de corregir humedad apoyan este cuadro.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoilDry,
          PlantHealthIds.signalSunflowerWholePlantFlaccid,
          PlantHealthIds.signalDryHotWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalSunflowerRootRotSigns,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_heat_load_transient',
        labelEs: 'Carga térmica temporal posible',
        type: 'abiotic_compatible',
        summaryEs: 'Decaimiento solo en la hora más caliente con recuperación nocturna puede ser transitorio.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHeatStress,
          PlantHealthIds.signalSunflowerContainerHeated,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRootRotSigns,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_root_failure_mimic',
        labelEs: 'Falla radicular con apariencia de sequía por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Si no recupera aunque el suelo esté bien, debe revisarse raíz, cuello y vasos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRootRotSigns,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoilDry,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La lectura y el tacto confirman suelo seco en profundidad?',
      '¿La planta recupera por la noche?',
      '¿La maceta está muy caliente o limitada de volumen?',
      '¿El botón o flor también se está secando?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Corrige humedad de forma gradual y verifica que el agua llegue a la raíz.',
      'Evita ciclos repetidos de marchitez severa, especialmente en botón y floración.',
      'Escala si no recupera durante la noche o la raíz muestra deterioro.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 31. Tejido blanqueado o seco del lado más expuesto al sol.
  PlantHealthSyndrome(
    id: 'sunflower_sunscald_or_heat_injury_31',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Tejido blanqueado o seco del lado más expuesto al sol',
    stages: _vegToBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomTanPaperySpots,
    strongSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalSunflowerSunnySide,
      PlantHealthIds.signalSunflowerChangedExposure,
      PlantHealthIds.signalTanPaperySpots,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalSunflowerDropletPattern,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerProgressingInShade,
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalSunflowerPustules,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_sunscald_heat_injury',
        labelEs: 'Quemadura por sol o calor compatible',
        type: 'abiotic_compatible',
        summaryEs: 'Daño seco, claro y concentrado en la cara expuesta después de un cambio de sol es compatible.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSunnySide,
          PlantHealthIds.signalSunflowerChangedExposure,
          PlantHealthIds.signalHeatStress,
          PlantHealthIds.signalTanPaperySpots,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerProgressingInShade,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_spray_phytotoxicity',
        labelEs: 'Quemadura por producto o gota posible',
        type: 'abiotic_compatible',
        summaryEs: 'Patrón de gotas o daño posterior a aplicación requiere este diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerDropletPattern,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSunnySide,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_foliar_disease_mimic',
        labelEs: 'Lesión foliar por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Expansión independiente de la exposición, halo o moho apuntan a otro problema.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerProgressingInShade,
          PlantHealthIds.signalGrayFuzzyGrowth,
          PlantHealthIds.signalSunflowerPustules,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerChangedExposure,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La lesión coincide con la cara más soleada?',
      '¿Hubo cambio reciente de ubicación o retiro de sombra?',
      '¿Se aplicó un producto antes del daño?',
      '¿La lesión está seca y estable o húmeda y en expansión?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'No retires de golpe todo el sol; ajusta exposición de forma gradual si hubo cambio.',
      'Evita aplicar productos sobre tejido caliente o flor abierta.',
      'Escala si la lesión se ablanda, crece o aparece moho.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 32. Tejido acuoso, oscuro o colapsado después de frío.
  PlantHealthSyndrome(
    id: 'sunflower_cold_or_frost_injury_32',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Tejido acuoso, oscuro o colapsado después de frío',
    stages: _seedlingThroughBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomColdInjury,
    strongSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalSunflowerWaterSoakedAfterCold,
      PlantHealthIds.signalSunflowerUniformExposedDamage,
      PlantHealthIds.signalSunflowerForecastFrost,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalSunflowerTenderNewGrowth,
      PlantHealthIds.signalSunflowerBlackenedTissue,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalSunflowerLocalizedRotOdor,
      PlantHealthIds.signalSunflowerInsectPattern,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_frost_cold_injury',
        labelEs: 'Daño por frío o helada compatible',
        type: 'abiotic_compatible',
        summaryEs: 'Tejido expuesto que se vuelve acuoso y después oscuro tras una noche fría es compatible.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalSunflowerWaterSoakedAfterCold,
          PlantHealthIds.signalSunflowerUniformExposedDamage,
          PlantHealthIds.signalSunflowerForecastFrost,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerLocalizedRotOdor,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_bacterial_soft_rot_mimic',
        labelEs: 'Pudrición blanda secundaria por confirmar',
        type: 'condition_compatible',
        summaryEs: 'Olor, baba o avance varios días después requiere revisar deterioro secundario.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerLocalizedRotOdor,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerUniformExposedDamage,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_chemical_or_heat_mimic',
        labelEs: 'Daño químico o térmico como diferencial',
        type: 'abiotic_compatible',
        summaryEs: 'Sin evento frío confirmado, el patrón puede tener otra causa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerInsectPattern,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalSunflowerForecastFrost,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo temperatura cercana a congelación o helada?',
      '¿El daño afecta partes expuestas de varias plantas al mismo tiempo?',
      '¿El tejido está acuoso sin olor o se vuelve blando y maloliente?',
      '¿El botón o punto de crecimiento sigue firme?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Espera a que se delimite el tejido antes de retirar grandes partes.',
      'Mantén el suelo estable, no saturado, mientras se evalúa recuperación.',
      'Busca revisión si el punto de crecimiento o cuello pierde firmeza.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 33. Quemado tras fertilización, costra blanca o EC elevada.
  PlantHealthSyndrome(
    id: 'sunflower_salt_or_fertilizer_burn_33',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Quemado tras fertilización, costra blanca o EC elevada',
    stages: _seedlingThroughBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalSunflowerRecentFertilizer,
      PlantHealthIds.signalSunflowerWhiteCrust,
      PlantHealthIds.signalSunflowerRootTipBurn,
    },
    weakSignals: <String>{
      PlantHealthIds.signalLeafEdgeBurn,
      PlantHealthIds.signalSunflowerSoilDry,
      PlantHealthIds.signalSunflowerContainerContext,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerNoRecentInput,
      PlantHealthIds.signalSunflowerActivePustules,
      PlantHealthIds.signalSunflowerColdEvent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_salinity_stress',
        labelEs: 'Estrés por acumulación de sales compatible',
        type: 'abiotic_compatible',
        summaryEs: 'EC alta, costra, raíces dañadas y quemado marginal apoyan acumulación de sales.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSalinityLoad,
          PlantHealthIds.signalSunflowerWhiteCrust,
          PlantHealthIds.signalSunflowerRootTipBurn,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNoRecentInput,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_fertilizer_contact_injury',
        labelEs: 'Daño por contacto o concentración de fertilizante posible',
        type: 'abiotic_compatible',
        summaryEs: 'Daño posterior a aplicación concentrada, especialmente en plántula, requiere cautela.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRecentFertilizer,
          PlantHealthIds.signalSunflowerRootTipBurn,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNoRecentInput,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_drought_or_k_pattern_mimic',
        labelEs: 'Sequía o patrón tipo K como diferencial',
        type: 'nutrient_context',
        summaryEs: 'Bordes secos también aparecen con falta de agua o absorción limitada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoilDry,
          PlantHealthIds.signalLeafEdgeBurn,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSalinityLoad,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La EC está alta y existe costra blanca?',
      '¿Se aplicó fertilizante recientemente o quedó junto a la semilla/raíz?',
      '¿El suelo está seco, lo que concentra sales?',
      '¿Las raíces tienen puntas oscuras o pérdida de crecimiento?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'No agregues más fertilizante.',
      'Revisa drenaje y calidad del agua antes de intentar lavar sales.',
      'En plántulas, escala la revisión si la emergencia o raíz se deterioran.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 34. Crecimiento detenido con suelo apretado o raíz confinada.
  PlantHealthSyndrome(
    id: 'sunflower_compaction_or_rootbound_34',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Crecimiento detenido con suelo apretado o raíz confinada',
    stages: _seedlingToBudStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomStuntingReddening,
    strongSignals: <String>{
      PlantHealthIds.signalSunflowerHighResistance,
      PlantHealthIds.signalSunflowerRootCircling,
      PlantHealthIds.signalSunflowerHardPan,
      PlantHealthIds.signalSunflowerSmallRootVolume,
    },
    weakSignals: <String>{
      PlantHealthIds.signalPoorEmergence,
      PlantHealthIds.signalSunflowerRepeatedDrying,
      PlantHealthIds.signalSunflowerStemThin,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerRootsExpandingFreely,
      PlantHealthIds.signalSunflowerResistanceNormalMoistSoil,
      PlantHealthIds.signalSunflowerGeneticCompactProfile,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_compaction_root_restriction',
        labelEs: 'Restricción física de la raíz compatible',
        type: 'structural_condition',
        summaryEs: 'Resistencia alta en suelo húmedo, raíz desviada o maceta llena de raíces apoyan limitación física.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHighResistance,
          PlantHealthIds.signalSunflowerHardPan,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerResistanceNormalMoistSoil,
          PlantHealthIds.signalSunflowerRootsExpandingFreely,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_container_rootbound',
        labelEs: 'Maceta insuficiente o raíz enrollada posible',
        type: 'structural_condition',
        summaryEs: 'Secado rápido, crecimiento detenido y raíces circulares son compatibles.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRootCircling,
          PlantHealthIds.signalSunflowerSmallRootVolume,
          PlantHealthIds.signalSunflowerRepeatedDrying,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRootsExpandingFreely,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_dry_soil_false_resistance',
        labelEs: 'Resistencia elevada por suelo seco posible',
        type: 'measurement_context',
        summaryEs: 'La resistencia aumenta al secarse el suelo; debe interpretarse junto con humedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHighResistance,
          PlantHealthIds.signalSunflowerRepeatedDrying,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerResistanceNormalMoistSoil,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_compact_cultivar_normal',
        labelEs: 'Porte compacto normal posible',
        type: 'benign_differential',
        summaryEs: 'Un perfil enano sano no debe confundirse con retraso patológico.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerGeneticCompactProfile,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerHighResistance,
          PlantHealthIds.signalSunflowerRootCircling,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La resistencia se midió con humedad suficiente?',
      '¿Las raíces circulan o llenan por completo la maceta?',
      '¿La planta se seca demasiado rápido?',
      '¿El perfil elegido es compacto y otras plantas iguales tienen el mismo porte?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Interpreta resistencia junto con humedad, no de forma aislada.',
      'Revisa volumen de raíz y drenaje sin romper el cepellón innecesariamente.',
      'No fertilices para compensar una limitación física.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 35. Color o crecimiento compatible con nutrición desbalanceada.
  PlantHealthSyndrome(
    id: 'sunflower_nutrient_like_pattern_35',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Color o crecimiento compatible con nutrición desbalanceada',
    stages: _vegToBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSunflowerNutrientPattern,
    strongSignals: <String>{
      PlantHealthIds.signalSunflowerOlderLeavesYellow,
      PlantHealthIds.signalSunflowerPurpleTint,
      PlantHealthIds.signalLeafEdgeBurn,
      PlantHealthIds.signalSunflowerYoungInterveinalChlorosis,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSunflowerStunted,
      PlantHealthIds.signalSunflowerWeakStem,
      PlantHealthIds.signalSunflowerNpkOrientativeOutOfBand,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerActiveSpotsOrPustules,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalSunflowerStageSenescence,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_nitrogen_like_pattern',
        labelEs: 'Patrón compatible con N bajo por confirmar',
        type: 'nutrient_context',
        summaryEs: 'Amarillamiento de hojas viejas puede ser compatible, pero también con senescencia, agua o raíz.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerOlderLeavesYellow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStageSenescence,
          PlantHealthIds.signalWaterlogging,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_phosphorus_like_pattern',
        labelEs: 'Patrón compatible con P limitado por confirmar',
        type: 'nutrient_context',
        summaryEs: 'Crecimiento lento y tintes rojizos o morados pueden aparecer con P bajo o suelo frío.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerPurpleTint,
          PlantHealthIds.signalSunflowerStunted,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStageSenescence,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_potassium_like_pattern',
        labelEs: 'Patrón compatible con K limitado por confirmar',
        type: 'nutrient_context',
        summaryEs: 'Quemado marginal en hojas viejas puede parecer K bajo, pero sequía y sales son diferenciales fuertes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalLeafEdgeBurn,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStageSenescence,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_micronutrient_uptake_pattern',
        labelEs: 'Absorción de micronutrientes limitada posible',
        type: 'nutrient_context',
        summaryEs: 'Clorosis entre venas en hojas nuevas puede relacionarse con pH alto, raíz o micronutrientes; la sonda NPK no lo confirma.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerYoungInterveinalChlorosis,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRootsDarkRot,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El patrón empieza en hojas viejas o nuevas?',
      '¿Hay suelo frío, pH fuera de rango, exceso de agua, sequía o EC alta?',
      '¿La etapa ya es posfloración o senescencia?',
      '¿Existe análisis de suelo o tejido que confirme la sospecha?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Usa NPK solo como lectura orientativa y revisa primero agua, temperatura, EC, pH y raíz.',
      'No conviertas un patrón visual en una orden automática de fertilizar.',
      'Solicita análisis si el problema persiste y el impacto es importante.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
    favorsRecentStress: true,
  ),
  // 36. Flor envejecida y amarillamiento gradual al final del ciclo.
  PlantHealthSyndrome(
    id: 'sunflower_normal_senescence_or_cycle_end_36',
    cropId: CropCatalog.sunflowerCropId,
    labelEs: 'Flor envejecida y amarillamiento gradual al final del ciclo',
    stages: _endOfCycleStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlowerHead,
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomSunflowerNormalSenescence,
    strongSignals: <String>{
      PlantHealthIds.signalSunflowerStageAfterBloom,
      PlantHealthIds.signalSunflowerGradualUniformYellowing,
      PlantHealthIds.signalSunflowerHeadDryFirm,
      PlantHealthIds.signalSunflowerNoActiveLesion,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSunflowerLowerLeavesOnly,
      PlantHealthIds.signalSunflowerPetalsDryUniform,
      PlantHealthIds.signalSunflowerStemStillFirm,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSunflowerRapidCollapse,
      PlantHealthIds.signalSunflowerSoftRot,
      PlantHealthIds.signalSunflowerAbnormalOdor,
      PlantHealthIds.signalSunflowerNewPustulesOrMold,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunflower_normal_senescence',
        labelEs: 'Senescencia normal compatible con la etapa',
        type: 'normal_process',
        summaryEs: 'Después de la floración, el girasol anual amarillea, seca pétalos y completa su ciclo; no entra en dormancia ni reinicia.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStageAfterBloom,
          PlantHealthIds.signalSunflowerGradualUniformYellowing,
          PlantHealthIds.signalSunflowerHeadDryFirm,
          PlantHealthIds.signalSunflowerNoActiveLesion,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRapidCollapse,
          PlantHealthIds.signalSunflowerSoftRot,
          PlantHealthIds.signalSunflowerAbnormalOdor,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_post_bloom_head_weight',
        labelEs: 'Cambio normal de postura posfloración posible',
        type: 'benign_differential',
        summaryEs: 'La cabeza puede inclinarse por peso mientras termina la temporada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStageAfterBloom,
          PlantHealthIds.signalSunflowerStemStillFirm,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRapidCollapse,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_premature_senescence_stress',
        labelEs: 'Senescencia adelantada por estrés por confirmar',
        type: 'abiotic_compatible',
        summaryEs: 'Si ocurre mucho antes de la ventana o avanza en días, revisa agua, raíz, calor, tallo y enfermedades.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerRapidCollapse,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerStageAfterBloom,
          PlantHealthIds.signalSunflowerGradualUniformYellowing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunflower_late_disease_mimic',
        labelEs: 'Enfermedad tardía como diferencial',
        type: 'condition_compatible',
        summaryEs: 'Moho, olor, pústulas, cancro o marchitez localizada no son cierre normal por sí solos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSunflowerSoftRot,
          PlantHealthIds.signalSunflowerAbnormalOdor,
          PlantHealthIds.signalSunflowerNewPustulesOrMold,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSunflowerNoActiveLesion,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La etapa temporal ya es post_bloom o senescence?',
      '¿El cambio es gradual y general o rápido y localizado?',
      '¿El tallo y la cabeza están firmes, secos y sin olor?',
      '¿Hay moho, pústulas, cancro o tejido acuoso activo?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'No intentes detener el cierre natural con fertilizante o riego excesivo.',
      'Mantén seguridad estructural si la cabeza pesa o el tallo se inclina.',
      'Al llegar a cycle_complete, BIO-G debe cerrar el registro y omitir alertas sanitarias activas.',
    ],
    disclaimerEs: _sunflowerDisclaimer,
  ),
];
