import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

// Conjuntos de etapas de Cempasúchil / Marigold (Doc C §5). El cempasúchil es
// una anual de ciclo único; sus once etapas fenológicas se traducen a los ocho
// buckets compartidos del motor de sanidad sin crear una segunda taxonomía.
//
// `grainFill` es un bucket TÉCNICO compartido: en Cempasúchil representa flores
// envejeciendo, menos botones nuevos y la transición posterior a la floración.
// NUNCA significa grano, semilla comercial, rendimiento ni cosecha (Doc C §5).

const Set<PlantHealthStageBucket> _seedlingStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
};

const Set<PlantHealthStageBucket> _seedlingToEarlyVegStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
    };

/// Raíz, cuello y patrones que pueden aparecer desde plántula hasta floración.
/// También cubre S10/S14/S20 ("emergence a flowering").
const Set<PlantHealthStageBucket> _seedlingToBloomStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
    };

const Set<PlantHealthStageBucket> _earlyVegToPostBloomStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    };

const Set<PlantHealthStageBucket> _foliarDiseaseStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    };

const Set<PlantHealthStageBucket> _budBloomToPostBloomStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    };

const Set<PlantHealthStageBucket> _midVegToLateStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    };

const Set<PlantHealthStageBucket> _earlyVegToBloomStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
    };

const Set<PlantHealthStageBucket> _systemicStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _stemToPostBloomStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    };

const Set<PlantHealthStageBucket> _activeVegToStemStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
    };

const Set<PlantHealthStageBucket> _budBloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _midVegToPostBloomStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    };

const Set<PlantHealthStageBucket> _stemToBloomStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
    };

/// Todas las etapas vivas (S21: daño térmico o solar puede ocurrir en
/// cualquiera).
const Set<PlantHealthStageBucket> _allLiveStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _lateStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

/// Disclaimer obligatorio (Doc C §1.7) presente en cada síndrome de
/// Cempasúchil.
const String _marigoldDisclaimer =
    'BIO-G organiza observaciones y contexto para orientar la revisión. No confirma una enfermedad, una plaga, una deficiencia ni un organismo causal.';

/// Catálogo visual prudente para Cempasúchil / Marigold (`crop_marigold`,
/// Doc C §6, S01–S23).
///
/// El catálogo se organiza por síndromes observables (¿qué ves en tu
/// Cempasúchil?), nunca por enfermedades. Los cuadros describen condiciones
/// compatibles y preguntas de confirmación. Ninguna lectura del dispositivo
/// confirma por sí sola un hongo, una bacteria, un virus, un fitoplasma, un
/// ácaro, un insecto, un nematodo ni una deficiencia. Una señal de sensor
/// aislada nunca produce severidad alta: para `high` debe existir una señal
/// observada fuerte (Doc C §33).
///
/// `critical` NO se usa en v1 (Doc C §32) y `immediate` tampoco: quedan
/// reservados para riesgo regulatorio o de seguridad confirmado por una
/// autoridad.
const List<PlantHealthSyndrome> marigoldSyndromes = <PlantHealthSyndrome>[
  // ────────────────────────────────────────────────────────────────────────
  // Familia 1: Semilla y plántula.
  // ────────────────────────────────────────────────────────────────────────
  // S01. No emerge o nace de forma muy dispareja.
  PlantHealthSyndrome(
    id: 'marigold_poor_patchy_emergence_01',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'No emerge o nace de forma muy dispareja',
    stages: _seedlingStages,
    organIds: <String>{
      PlantHealthIds.organSeed,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldPoorPatchyEmergence,
    strongSignals: <String>{
      PlantHealthIds.signalPoorEmergence,
      PlantHealthIds.signalMarigoldPatchyGaps,
      PlantHealthIds.signalMarigoldSeedMissingOrSoft,
      PlantHealthIds.signalMarigoldSoilCrust,
      PlantHealthIds.signalMarigoldUnevenSowingDepth,
    },
    weakSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalMarigoldOldOrDamagedSeedLot,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldHealthyEmergenceNearby,
      PlantHealthIds.signalMarigoldWithinNormalWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_germination_environment_possible',
        labelEs: 'Condición de germinación desfavorable',
        type: 'abiotic_compatible',
        summaryEs:
            'Frío, sequedad, saturación, salinidad, costra o profundidad pueden impedir una emergencia uniforme sin demostrar un patógeno.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSoilCrust,
          PlantHealthIds.signalMarigoldUnevenSowingDepth,
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalDryHotWindow,
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalSalinityLoad,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldHealthyEmergenceNearby,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_pre_emergence_decay_possible',
        labelEs: 'Deterioro preemergente por confirmar',
        type: 'condition_compatible',
        summaryEs:
            'Semilla o radícula blanda en un medio húmedo es compatible con damping-off preemergente; la inspección visual no distingue Pythium, Rhizoctonia o Fusarium.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSeedMissingOrSoft,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldHealthyEmergenceNearby,
          PlantHealthIds.signalMarigoldWithinNormalWindow,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_seed_quality_or_age_possible',
        labelEs: 'Viabilidad o calidad de semilla por confirmar',
        type: 'input_quality',
        summaryEs:
            'Un lote envejecido, almacenado con humedad o de procedencia desconocida puede emerger de forma irregular.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldOldOrDamagedSeedLot,
          PlantHealthIds.signalMarigoldPatchyGaps,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldHealthyEmergenceNearby,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_seed_loss_possible',
        labelEs: 'Pérdida física o consumo de semilla posible',
        type: 'physical_or_wildlife',
        summaryEs:
            'Semilla ausente y suelo removido pueden corresponder a aves, hormigas, roedores, escurrimiento o manejo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSeedMissingOrSoft,
          PlantHealthIds.signalMarigoldPatchyGaps,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldHealthyEmergenceNearby,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Cuántos días han pasado desde la siembra y qué esperaba la ventana del perfil?',
      '¿El problema forma parches o afecta toda la charola o cama?',
      '¿El medio estuvo seco, frío, saturado o con costra?',
      '¿Una semilla revisada sigue firme?',
      '¿La profundidad de siembra fue uniforme?',
      '¿El mismo lote germinó bien en otro recipiente?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Compara con la ventana del perfil antes de declarar una pérdida.',
      'Revisa humedad, costra, profundidad y temperatura sin desenterrar toda la siembra.',
      'No resiembres ni fertilices hasta separar retraso, pérdida y deterioro.',
      'Conserva fotografías del patrón completo.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // S02. Plántula afinada, vencida o colapsada a nivel del suelo.
  PlantHealthSyndrome(
    id: 'marigold_seedling_collapse_damping_off_02',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Plántula afinada, vencida o colapsada a nivel del suelo',
    stages: _seedlingToEarlyVegStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldSeedlingCollapse,
    strongSignals: <String>{
      PlantHealthIds.signalSeedlingNeckCollapse,
      PlantHealthIds.signalMarigoldStemPinchedAtSoil,
      PlantHealthIds.signalMarigoldWateryBrownLesion,
      PlantHealthIds.signalMarigoldSeedlingFellStillGreen,
      PlantHealthIds.signalMarigoldConsecutiveSeedlingDeaths,
      PlantHealthIds.signalRootsDarkRot,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalMarigoldPoorVentilation,
      PlantHealthIds.signalMarigoldDenseSpacing,
      PlantHealthIds.signalMarigoldReusedSubstrate,
      PlantHealthIds.signalMarigoldFrequentIrrigation,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldStemCleanCut,
      PlantHealthIds.signalMarigoldMissingTissue,
      PlantHealthIds.signalMarigoldDehydratedFirmCollar,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_damping_off_complex_compatible',
        labelEs: 'Condición compatible con damping-off',
        type: 'condition_compatible',
        summaryEs:
            'El colapso del cuello puede asociarse con Pythium, Rhizoctonia, Fusarium u otros organismos; la apariencia sola no identifica cuál.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldStemPinchedAtSoil,
          PlantHealthIds.signalMarigoldWateryBrownLesion,
          PlantHealthIds.signalMarigoldSeedlingFellStillGreen,
          PlantHealthIds.signalMarigoldConsecutiveSeedlingDeaths,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldStemCleanCut,
          PlantHealthIds.signalMarigoldDehydratedFirmCollar,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_cutworm_or_chewing_possible',
        labelEs: 'Plántula cortada por organismo masticador posible',
        type: 'arthropod_possible',
        summaryEs:
            'Un tallo seccionado con tejido faltante, especialmente durante la noche, favorece un diferencial de gusano cortador, babosa u otro consumidor.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldStemCleanCut,
          PlantHealthIds.signalMarigoldMissingTissue,
          PlantHealthIds.signalMarigoldNightDamage,
          PlantHealthIds.signalMarigoldSlimeTrail,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldWateryBrownLesion,
          PlantHealthIds.signalRootsDarkRot,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_water_stress_seedling_possible',
        labelEs: 'Colapso por extremo hídrico posible',
        type: 'abiotic_possible',
        summaryEs:
            'Una raíz muy seca o saturada puede marchitar una plántula sin producir el patrón típico de estrangulamiento.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldDehydratedFirmCollar,
          PlantHealthIds.signalDryHotWindow,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldStemPinchedAtSoil,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_mechanical_seedling_damage_possible',
        labelEs: 'Daño mecánico de plántula posible',
        type: 'physical_damage',
        summaryEs:
            'Viento, manipulación, una gota fuerte o el trasplante pueden quebrar un tallo sin deterioro del cuello.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldRecentTransplant,
          PlantHealthIds.signalMarigoldWindRainEvent,
          PlantHealthIds.signalMarigoldDehydratedFirmCollar,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldWateryBrownLesion,
          PlantHealthIds.signalMarigoldConsecutiveSeedlingDeaths,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El tallo está afinado justo al nivel del suelo?',
      '¿La lesión es húmeda, seca o parece un corte?',
      '¿Hay varias plántulas afectadas juntas?',
      '¿El medio permanece mojado?',
      '¿Hay tejido faltante o rastro de babosa?',
      '¿Ocurrió después de un trasplante o de un riego fuerte?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Separa la observación de una plántula aislada de un brote que avanza.',
      'Reduce riegos repetidos mientras el medio siga húmedo, sin dejar secar semillas viables.',
      'No reutilices herramientas ni bandejas sucias sin limpiarlas.',
      'Solicita diagnóstico local si el colapso continúa.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    favorsRecentStress: true,
  ),

  // ────────────────────────────────────────────────────────────────────────
  // Familia 2: Raíz, cuello y estructura.
  // ────────────────────────────────────────────────────────────────────────
  // S03. Marchitez, amarillamiento o pérdida de soporte con suelo húmedo.
  PlantHealthSyndrome(
    id: 'marigold_root_collar_wilt_03',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Marchitez, amarillamiento o pérdida de soporte con suelo húmedo',
    stages: _seedlingToBloomStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldRootCollarWilt,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldWiltInWetSoil,
      PlantHealthIds.signalMarigoldCollarBrownCrackedSoft,
      PlantHealthIds.signalMarigoldRootCortexSloughs,
      PlantHealthIds.signalMarigoldFineRootsLost,
      PlantHealthIds.signalMarigoldAbnormalOdor,
      PlantHealthIds.signalRootsDarkRot,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalMarigoldRecentTransplant,
      PlantHealthIds.signalMarigoldRootBoundCoiled,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldDrySoilFirmRoot,
      PlantHealthIds.signalMarigoldMiddayWiltRecovers,
      PlantHealthIds.signalMarigoldBentOrBrokenStem,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_pythium_rhizoctonia_root_rot_compatible',
        labelEs: 'Deterioro de raíz compatible con complejo de pudrición',
        type: 'condition_compatible',
        summaryEs:
            'Pythium y Rhizoctonia son diferenciales frecuentes en raíces y cuello; se necesita clínica o laboratorio para separarlos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldCollarBrownCrackedSoft,
          PlantHealthIds.signalMarigoldRootCortexSloughs,
          PlantHealthIds.signalMarigoldAbnormalOdor,
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldDrySoilFirmRoot,
          PlantHealthIds.signalMarigoldMiddayWiltRecovers,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_root_asphyxia_possible',
        labelEs: 'Asfixia radicular por saturación posible',
        type: 'abiotic_possible',
        summaryEs:
            'El exceso de agua puede reducir el oxígeno disponible y producir síntomas parecidos a los de una infección.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalMarigoldWiltInWetSoil,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldDrySoilFirmRoot,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_fusarium_wilt_possible',
        labelEs: 'Marchitez vascular por confirmar',
        type: 'condition_compatible',
        summaryEs:
            'Marchitez progresiva, decoloración interna y raíz dañada pueden ser compatibles con Fusarium, sin confirmación visual.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalVascularBrowning,
          PlantHealthIds.signalOneSidedWilt,
          PlantHealthIds.signalMarigoldFineRootsLost,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldMiddayWiltRecovers,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_transplant_or_compaction_stress_possible',
        labelEs: 'Estrés de trasplante o raíz limitada posible',
        type: 'abiotic_possible',
        summaryEs:
            'Una planta recién movida o con resistencia alta puede perder soporte y agua aun sin pudrición.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldRecentTransplant,
          PlantHealthIds.signalMarigoldRootBoundCoiled,
          PlantHealthIds.signalRecentStress,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldAbnormalOdor,
          PlantHealthIds.signalMarigoldRootCortexSloughs,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El suelo está realmente húmedo en la zona de raíces?',
      '¿La base está firme, café, agrietada o blanda?',
      '¿Hay olor anormal?',
      '¿Las raíces finas siguen claras y firmes?',
      '¿La planta fue trasplantada recientemente?',
      '¿El daño aparece en una zona con mal drenaje?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'No riegues de nuevo sobre suelo saturado.',
      'Fotografía base, raíces y distribución del problema.',
      'No declares un organismo causal a partir de una lectura de humedad.',
      'Busca revisión local si hay base blanda, olor o avance rápido.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    favorsRecentStress: true,
  ),

  // ────────────────────────────────────────────────────────────────────────
  // Familia 3: Follaje y enfermedades foliares.
  // ────────────────────────────────────────────────────────────────────────
  // S04. Manchas cafés o negras que crecen y se unen.
  PlantHealthSyndrome(
    id: 'marigold_dark_concentric_leaf_blight_04',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Manchas cafés o negras que crecen y se unen',
    stages: _earlyVegToPostBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organBud,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldDarkConcentricLeafBlight,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldCircularBrownSpot,
      PlantHealthIds.signalMarigoldChloroticHalo,
      PlantHealthIds.signalMarigoldConcentricRingsInLesion,
      PlantHealthIds.signalMarigoldSpotsCoalescing,
      PlantHealthIds.signalMarigoldStartedLowerLeaves,
      PlantHealthIds.signalMarigoldPetalPedicelDarkening,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMarigoldLeafWetness,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalMarigoldDenseSpacing,
      PlantHealthIds.signalMarigoldPoorVentilation,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldFineWhiteStippling,
      PlantHealthIds.signalMarigoldSunExposedSideDamage,
      PlantHealthIds.signalHailEvent,
      PlantHealthIds.signalWhitePowderGrowth,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_alternaria_tagetica_compatible',
        labelEs: 'Condición compatible con tizón de Alternaria',
        type: 'condition_compatible',
        summaryEs:
            'Alternaria tagetica puede producir lesiones oscuras que se amplían y se unen en hojas, tallos y flores.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldCircularBrownSpot,
          PlantHealthIds.signalMarigoldConcentricRingsInLesion,
          PlantHealthIds.signalMarigoldSpotsCoalescing,
          PlantHealthIds.signalMarigoldPetalPedicelDarkening,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSunExposedSideDamage,
          PlantHealthIds.signalWhitePowderGrowth,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_other_fungal_leaf_spot_possible',
        labelEs: 'Otra mancha fúngica posible',
        type: 'condition_compatible',
        summaryEs:
            'Septoria, Cercospora y otros hongos pueden superponerse visualmente con el mismo patrón.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldStartedLowerLeaves,
          PlantHealthIds.signalMarigoldBlackDotsInLesion,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSunExposedSideDamage,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_bacterial_or_splash_injury_possible',
        labelEs: 'Manchado bacteriano o lesión por salpicadura posible',
        type: 'condition_compatible',
        summaryEs:
            'Lesiones acuosas o angulares pueden requerir descartar bacterias, fitotoxicidad o daño físico.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterSoakedSpots,
          PlantHealthIds.signalAngularLesionPattern,
          PlantHealthIds.signalMarigoldLeafWetness,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldConcentricRingsInLesion,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_abiotic_scorch_differential',
        labelEs: 'Quemadura ambiental como diferencial',
        type: 'abiotic_possible',
        summaryEs:
            'Sol, sales o una aspersión pueden producir tejido necrótico sin propagación infecciosa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSunExposedSideDamage,
          PlantHealthIds.signalMarigoldRecentSprayEvent,
          PlantHealthIds.signalSalinityLoad,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSpotsCoalescing,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La lesión comenzó circular?',
      '¿Tiene halo amarillo o anillos concéntricos?',
      '¿Empezó en las hojas inferiores?',
      '¿Se está uniendo con otras manchas?',
      '¿Hay lesiones en tallos, botones o pétalos?',
      '¿Hubo lluvia o riego sobre el follaje?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Fotografía el frente y el reverso de la hoja.',
      'Marca visualmente el borde de una lesión para observar su progreso.',
      'Evita mojar el follaje al final del día.',
      'No diagnostiques Alternaria sin descartar otros manchados.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // S05. Manchas grisáceas o negras con puntos oscuros.
  PlantHealthSyndrome(
    id: 'marigold_gray_black_spots_black_dots_05',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Manchas grisáceas o negras con puntos oscuros',
    stages: _foliarDiseaseStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldGrayBlackSpots,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldGrayBlackPaperyLesion,
      PlantHealthIds.signalMarigoldBlackDotsInLesion,
      PlantHealthIds.signalMarigoldStartedLowerLeaves,
      PlantHealthIds.signalMarigoldUpwardProgression,
      PlantHealthIds.signalTanPaperySpots,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalMarigoldDenseSpacing,
      PlantHealthIds.signalMarigoldPoorVentilation,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalMarigoldFineWhiteStippling,
      PlantHealthIds.signalMarigoldBronzeSpecklesOlderLeaves,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_septoria_tageticola_compatible',
        labelEs: 'Mancha compatible con Septoria por confirmar',
        type: 'condition_compatible',
        summaryEs:
            'Septoria tageticola puede generar lesiones gris-negras con estructuras puntiformes y comenzar en hojas bajas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldBlackDotsInLesion,
          PlantHealthIds.signalMarigoldStartedLowerLeaves,
          PlantHealthIds.signalMarigoldUpwardProgression,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_cercospora_spot_possible',
        labelEs: 'Mancha de Cercospora posible',
        type: 'condition_compatible',
        summaryEs:
            'Cercospora puede producir manchas foliares similares y requiere identificación de laboratorio.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldGrayBlackPaperyLesion,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldConcentricRingsInLesion,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_alternaria_differential',
        labelEs: 'Alternaria como diferencial',
        type: 'condition_compatible',
        summaryEs:
            'Cuando las lesiones se amplían, coalescen o alcanzan flores, Alternaria continúa siendo un diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSpotsCoalescing,
          PlantHealthIds.signalMarigoldPetalPedicelDarkening,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldBlackDotsInLesion,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_old_spray_or_physical_spot_possible',
        labelEs: 'Residuo, aspersión o daño antiguo posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un patrón estable y relacionado con una aplicación puede no ser infeccioso.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldRecentSprayEvent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldUpwardProgression,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay puntos negros dentro de la mancha?',
      '¿Comenzó en las hojas inferiores?',
      '¿La lesión está seca o húmeda?',
      '¿Avanza hacia arriba?',
      '¿Hubo una aspersión reciente?',
      '¿Las plantas vecinas muestran el mismo patrón?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Compara lesiones nuevas y viejas para estimar el avance.',
      'No raspes ni frotes el tejido sospechoso.',
      'Reduce los periodos de hoja mojada.',
      'Busca identificación si el patrón progresa.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // S06. Botones o flores cafés con moho gris.
  PlantHealthSyndrome(
    id: 'marigold_gray_fuzzy_flower_blight_06',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Botones o flores cafés con moho gris',
    stages: _budBloomToPostBloomStages,
    organIds: <String>{
      PlantHealthIds.organBud,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFlowerHead,
      PlantHealthIds.organLeaf,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldGrayFuzzyFlowerBlight,
    strongSignals: <String>{
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalMarigoldBudNotOpening,
      PlantHealthIds.signalMarigoldWateryFlowerTissue,
      PlantHealthIds.signalMarigoldOldFlowersStuckToHealthy,
      PlantHealthIds.signalMarigoldPetalPedicelDarkening,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalMarigoldLeafWetness,
      PlantHealthIds.signalMarigoldDenseSpacing,
      PlantHealthIds.signalMarigoldPoorVentilation,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldUniformDryFlowerNoMold,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalMarigoldSilverScarring,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_botrytis_flower_blight_compatible',
        labelEs: 'Condición compatible con moho gris',
        type: 'condition_compatible',
        summaryEs:
            'Botrytis cinerea puede invadir pétalos, botones y tejido herido, especialmente con humedad y poca ventilación.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
          PlantHealthIds.signalMarigoldWateryFlowerTissue,
          PlantHealthIds.signalMarigoldOldFlowersStuckToHealthy,
          PlantHealthIds.signalHumidWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldUniformDryFlowerNoMold,
          PlantHealthIds.signalDryHotWindow,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_alternaria_flower_blight_possible',
        labelEs: 'Tizón floral de Alternaria posible',
        type: 'condition_compatible',
        summaryEs:
            'El oscurecimiento de botones y flores sin moho gris claro puede corresponder a Alternaria u otro hongo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldPetalPedicelDarkening,
          PlantHealthIds.signalMarigoldConcentricRingsInLesion,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_normal_flower_aging_possible',
        labelEs: 'Envejecimiento floral normal posible',
        type: 'benign_differential',
        summaryEs:
            'Una flor vieja puede secarse desde el exterior sin tejido acuoso, olor ni expansión hacia tejido sano.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldUniformDryFlowerNoMold,
          PlantHealthIds.signalMarigoldHealthyBudsStillForming,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
          PlantHealthIds.signalMarigoldWateryFlowerTissue,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_thrips_bud_damage_possible',
        labelEs: 'Daño de trips en botón posible',
        type: 'arthropod_possible',
        summaryEs:
            'Cicatrices, pétalos deformes y puntos negros sin moho favorecen trips.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSilverScarring,
          PlantHealthIds.signalMarigoldBlackThripsSpecks,
          PlantHealthIds.signalThripsPresent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay pelusa gris sobre el tejido?',
      '¿El botón está acuoso o seco?',
      '¿El problema inició en las flores viejas?',
      '¿Las flores permanecieron mojadas?',
      '¿Ves insectos pequeños o puntos negros?',
      '¿Se está expandiendo a hojas y tallos?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Retira únicamente el tejido claramente muerto, con herramientas limpias y cuando sea seguro.',
      'Separa las macetas muy afectadas; esto no equivale a una cuarentena oficial.',
      'Mejora la ventilación y evita mojar las flores.',
      'Busca evaluación si el avance alcanza tallos o base.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // S07. Polvo blanco sobre hojas, tallos o flores.
  PlantHealthSyndrome(
    id: 'marigold_white_powdery_coating_07',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Polvo blanco sobre hojas, tallos o flores',
    stages: _midVegToLateStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organBud,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldWhitePowderyCoating,
    strongSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalMarigoldPatchExpanding,
      PlantHealthIds.signalCannotScrapeOff,
      PlantHealthIds.signalMarigoldDownwardLeafCupping,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMarigoldDenseSpacing,
      PlantHealthIds.signalMarigoldPoorVentilation,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalHumidWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldResidueWipesOff,
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalMarigoldFineWhiteStippling,
      PlantHealthIds.signalMarigoldRecentSprayEvent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_powdery_mildew_compatible',
        labelEs: 'Condición compatible con cenicilla polvosa',
        type: 'condition_compatible',
        summaryEs:
            'El crecimiento blanco superficial es compatible con oídio o cenicilla, pero el agente exacto no se confirma visualmente.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWhitePowderGrowth,
          PlantHealthIds.signalMarigoldPatchExpanding,
          PlantHealthIds.signalCannotScrapeOff,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldResidueWipesOff,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_mineral_or_spray_residue_possible',
        labelEs: 'Residuo de agua o aspersión posible',
        type: 'abiotic_possible',
        summaryEs:
            'Depósitos minerales o productos secos pueden limpiarse y no vuelven a crecer entre revisiones.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldResidueWipesOff,
          PlantHealthIds.signalMarigoldRecentSprayEvent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldPatchExpanding,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_whitefly_or_scale_residue_differential',
        labelEs: 'Insectos cerosos como diferencial',
        type: 'arthropod_possible',
        summaryEs:
            'Colonias localizadas, insectos móviles o melaza favorecen una plaga y no una cenicilla.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWhiteflyCloud,
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalMarigoldWaxyScaleShields,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalWhitePowderGrowth,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El material se desprende al rozarlo con una herramienta?',
      '¿Vuelve a aparecer o se expande?',
      '¿Hay puntos negros dentro del parche?',
      '¿Está en ambas caras de la hoja?',
      '¿Hay insectos o melaza?',
      '¿Es un patrón regular de gotas secas?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Fotografía antes y después de una revisión prudente.',
      'Mejora la separación entre plantas y el flujo de aire.',
      'Evita confundir un residuo mineral con un hongo.',
      'Solicita identificación si cubre brotes o flores.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // S08. Punteado bronce, clorosis y hojas curvadas hacia abajo.
  PlantHealthSyndrome(
    id: 'marigold_bronze_speckle_low_ph_08',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Punteado bronce, clorosis y hojas curvadas hacia abajo',
    stages: _earlyVegToBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldBronzeSpeckle,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldBronzeSpecklesOlderLeaves,
      PlantHealthIds.signalMarigoldDownwardLeafCupping,
      PlantHealthIds.signalMarigoldStartedLowerLeaves,
      PlantHealthIds.signalMarigoldStuntedPlant,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMarigoldLowPhRepeated,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalMarigoldRecentSprayEvent,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalMarigoldChloroticHalo,
      PlantHealthIds.signalMarigoldBlackDotsInLesion,
      PlantHealthIds.signalMarigoldSunExposedSideDamage,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_iron_manganese_toxicity_compatible',
        labelEs: 'Bronze speckle compatible con acumulación de Fe/Mn',
        type: 'abiotic_compatible',
        summaryEs:
            'El cempasúchil puede acumular hierro y manganeso cuando el pH del sustrato desciende; la confirmación requiere pH repetido y, de ser posible, análisis.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldBronzeSpecklesOlderLeaves,
          PlantHealthIds.signalMarigoldDownwardLeafCupping,
          PlantHealthIds.signalMarigoldLowPhRepeated,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_spider_mite_differential',
        labelEs: 'Ácaros como diferencial',
        type: 'arthropod_possible',
        summaryEs:
            'Punteado fino con bronceado, organismos en el envés o telaraña favorecen ácaros.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
          PlantHealthIds.signalMarigoldTinyMitesVisible,
          PlantHealthIds.signalDryHotWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldLowPhRepeated,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_fungal_leaf_spot_differential',
        labelEs: 'Mancha foliar como diferencial',
        type: 'condition_compatible',
        summaryEs:
            'Lesiones delimitadas y progresivas pueden ser infecciosas y no nutricionales.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldChloroticHalo,
          PlantHealthIds.signalMarigoldBlackDotsInLesion,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldBronzeSpecklesOlderLeaves,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_spray_phytotoxicity_possible',
        labelEs: 'Fitotoxicidad por aspersión posible',
        type: 'abiotic_possible',
        summaryEs:
            'La aparición simultánea después de una aplicación favorece un daño químico.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldRecentSprayEvent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldUpwardProgression,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El problema comenzó en las hojas viejas?',
      '¿Las hojas se curvan hacia abajo?',
      '¿El pH bajo se repite entre mediciones?',
      '¿Hay ácaros o telaraña en el envés?',
      '¿Se aplicó algún producto recientemente?',
      '¿La lesión tiene un borde definido?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Repite la medición de pH antes de atribuir una acumulación.',
      'No agregues micronutrientes por el color de la hoja.',
      'Compara con plantas del mismo lote y cultivar.',
      'Confirma con análisis si el problema es generalizado.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsRecentStress: true,
  ),

  // S09. Amarillamiento uniforme, hojas nuevas pálidas o bordes quemados.
  PlantHealthSyndrome(
    id: 'marigold_uniform_chlorosis_edge_burn_09',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Amarillamiento uniforme, hojas nuevas pálidas o bordes quemados',
    stages: _systemicStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldChlorosisEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldUniformChlorosis,
      PlantHealthIds.signalMarigoldNewLeavesPale,
      PlantHealthIds.signalLeafEdgeBurn,
      PlantHealthIds.signalMarigoldSameManagementGroup,
      PlantHealthIds.signalMarigoldStuntedPlant,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMarigoldHighPhRepeated,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalMarigoldRootBoundCoiled,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldWhiteRings,
      PlantHealthIds.signalMarigoldStrapLikeLeaves,
      PlantHealthIds.signalMarigoldBlackDotsInLesion,
      PlantHealthIds.signalMarigoldAphidClusters,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_high_ph_iron_unavailability_possible',
        labelEs: 'Baja disponibilidad de hierro por pH alto posible',
        type: 'abiotic_possible',
        summaryEs:
            'Hojas nuevas pálidas con pH alto pueden indicar disponibilidad limitada de hierro; no es una confirmación de deficiencia.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldNewLeavesPale,
          PlantHealthIds.signalMarigoldHighPhRepeated,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldWhiteRings,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_salinity_root_stress_possible',
        labelEs: 'Estrés por sales posible',
        type: 'abiotic_possible',
        summaryEs:
            'EC alta, borde seco y dificultad de absorción forman un patrón compatible con salinidad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSalinityLoad,
          PlantHealthIds.signalLeafEdgeBurn,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldWhiteRings,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_nutrient_imbalance_possible',
        labelEs: 'Desequilibrio nutrimental por confirmar',
        type: 'abiotic_possible',
        summaryEs:
            'La distribución entre hojas viejas y nuevas orienta, pero la sonda no confirma una carencia foliar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldUniformChlorosis,
          PlantHealthIds.signalMarigoldSameManagementGroup,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldStrapLikeLeaves,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_root_dysfunction_differential',
        labelEs: 'Raíz dañada como diferencial',
        type: 'condition_compatible',
        summaryEs:
            'Una raíz fría, saturada, compactada o enferma puede producir clorosis pese a que los nutrientes estén presentes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalMarigoldRootBoundCoiled,
          PlantHealthIds.signalMarigoldFineRootsLost,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldDrySoilFirmRoot,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Comienza en hojas nuevas o en hojas viejas?',
      '¿Es uniforme o forma mosaico?',
      '¿El pH y la EC se repiten fuera de rango?',
      '¿El borde de la hoja está seco?',
      '¿La raíz está húmeda, fría o limitada?',
      '¿Afecta a plantas con el mismo riego?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Revisa primero agua, temperatura, EC y pH.',
      'No recomiendes una fertilización a partir de una imagen.',
      'Compara con una segunda lectura en condiciones de humedad representativa.',
      'Solicita análisis si el patrón persiste.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsRecentStress: true,
  ),

  // S10. Mosaico, anillos claros, hojas estrechas o deformación.
  PlantHealthSyndrome(
    id: 'marigold_mosaic_rings_distortion_10',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Mosaico, anillos claros, hojas estrechas o deformación',
    stages: _seedlingToBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldMosaicRingsDistortion,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldWhiteRings,
      PlantHealthIds.signalMarigoldStrapLikeLeaves,
      PlantHealthIds.signalMarigoldStemNecrosis,
      PlantHealthIds.signalMarigoldStuntedPlant,
      PlantHealthIds.signalAsymmetricMottle,
    },
    weakSignals: <String>{
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalMarigoldSharedPropagationLot,
      PlantHealthIds.signalDryHotWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldUniformChlorosis,
      PlantHealthIds.signalMarigoldHerbicideDriftEvent,
      PlantHealthIds.signalMarigoldFineWhiteStippling,
      PlantHealthIds.signalMarigoldKnownVariegation,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_tswv_compatible',
        labelEs: 'Patrón compatible con TSWV por confirmar',
        type: 'systemic_condition_compatible',
        summaryEs:
            'TSWV puede causar anillos, moteado, deformación, necrosis y reducción de flor; requiere una prueba diagnóstica.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldWhiteRings,
          PlantHealthIds.signalMarigoldStrapLikeLeaves,
          PlantHealthIds.signalMarigoldStemNecrosis,
          PlantHealthIds.signalThripsPresent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldKnownVariegation,
          PlantHealthIds.signalMarigoldHerbicideDriftEvent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_insv_or_other_virus_possible',
        labelEs: 'INSV u otro virus posible',
        type: 'systemic_condition_compatible',
        summaryEs:
            'Otros virus pueden producir síntomas superpuestos que no se distinguen por fotografía.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAsymmetricMottle,
          PlantHealthIds.signalMarigoldSharedPropagationLot,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldKnownVariegation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_herbicide_or_chemical_injury_possible',
        labelEs: 'Daño químico como diferencial',
        type: 'abiotic_possible',
        summaryEs:
            'Una deformación simultánea después de deriva o aplicación puede simular un virus.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldHerbicideDriftEvent,
          PlantHealthIds.signalMarigoldRecentSprayEvent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldWhiteRings,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_nutritional_or_genetic_pattern_possible',
        labelEs: 'Patrón nutricional o genético posible',
        type: 'abiotic_or_trait',
        summaryEs:
            'Una variegación estable o una clorosis uniforme puede no ser infecciosa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldKnownVariegation,
          PlantHealthIds.signalMarigoldUniformChlorosis,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldStemNecrosis,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay anillos claros bien definidos?',
      '¿Las hojas nuevas son estrechas o deformes?',
      '¿Hay trips?',
      '¿Aparece en plantas del mismo lote?',
      '¿Hubo deriva de herbicida o una aplicación reciente?',
      '¿El patrón continúa en el crecimiento nuevo?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Evita mover o propagar plantas con patrón sistémico mientras se revisan.',
      'Separa temporalmente las macetas sospechosas cuando sea viable.',
      'Fotografía hojas jóvenes, tallos y planta completa.',
      'Solicita una prueba local; BIO-G no confirma virus.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsVectorPressure: true,
  ),

  // S11. Flores verdes, pétalos como hojas o muchos brotes cortos.
  PlantHealthSyndrome(
    id: 'marigold_green_leafy_flowers_witches_broom_11',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Flores verdes, pétalos como hojas o muchos brotes cortos',
    stages: _stemToPostBloomStages,
    organIds: <String>{
      PlantHealthIds.organBud,
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldPhyllodyWitchesBroom,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldGreenLeafyFlowers,
      PlantHealthIds.signalMarigoldWitchesBroom,
      PlantHealthIds.signalMarigoldStuntedPlant,
      PlantHealthIds.signalMarigoldUniformChlorosis,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMarigoldLeafhoppersPresent,
      PlantHealthIds.signalMarigoldNearbyWeeds,
      PlantHealthIds.signalMarigoldOtherAsteraceaeAffected,
      PlantHealthIds.signalVectorPresent,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldYoungBudFirmGreen,
      PlantHealthIds.signalMarigoldRecentPinching,
      PlantHealthIds.signalMarigoldHerbicideDriftEvent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_aster_yellows_compatible',
        labelEs: 'Patrón compatible con amarillamiento del aster',
        type: 'systemic_condition_compatible',
        summaryEs:
            'La filodia, la virescencia y la escoba de bruja pueden ser compatibles con un fitoplasma transmitido por chicharritas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldGreenLeafyFlowers,
          PlantHealthIds.signalMarigoldWitchesBroom,
          PlantHealthIds.signalMarigoldLeafhoppersPresent,
          PlantHealthIds.signalMarigoldOtherAsteraceaeAffected,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldRecentPinching,
          PlantHealthIds.signalMarigoldHerbicideDriftEvent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_herbicide_growth_regulator_possible',
        labelEs: 'Daño por herbicida regulador de crecimiento posible',
        type: 'abiotic_possible',
        summaryEs:
            'Tallos retorcidos y deformación general después de una deriva pueden imitar a un fitoplasma.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldHerbicideDriftEvent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldLeafhoppersPresent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_genetic_or_physical_flower_abnormality_possible',
        labelEs: 'Anomalía floral genética o física posible',
        type: 'trait_or_physical',
        summaryEs:
            'Una flor aislada sin patrón sistémico puede ser una anomalía local sin importancia sanitaria.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldYoungBudFirmGreen,
          PlantHealthIds.signalMarigoldRecentPinching,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldWitchesBroom,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Los pétalos se volvieron verdes o parecidos a hojas?',
      '¿Hay muchos brotes cortos desde un mismo punto?',
      '¿Se observa en varias partes de la planta?',
      '¿Hay chicharritas o malezas cercanas?',
      '¿Hubo aplicación de herbicida?',
      '¿Otras asteráceas presentan síntomas?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Evita usar la planta como fuente de semilla o de propagación.',
      'Reduce el movimiento entre áreas mientras se confirma.',
      'Registra la presencia de vectores y de plantas cercanas afectadas.',
      'Busca diagnóstico de extensión o laboratorio.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsVectorPressure: true,
  ),

  // ────────────────────────────────────────────────────────────────────────
  // Familia 4: Botón, flor y capítulo.
  // ────────────────────────────────────────────────────────────────────────
  // S12. Mucha hoja, tallos largos y pocos o ningún botón.
  PlantHealthSyndrome(
    id: 'marigold_lush_no_buds_elongated_12',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Mucha hoja, tallos largos y pocos o ningún botón',
    stages: _activeVegToStemStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldLushNoBuds,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldLushFoliage,
      PlantHealthIds.signalMarigoldLongSoftStems,
      PlantHealthIds.signalMarigoldNoBudsPastWindow,
      PlantHealthIds.signalMarigoldInsufficientLight,
      PlantHealthIds.signalMarigoldHighNitrogenReported,
      PlantHealthIds.signalMarigoldNightLightConfirmed,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalMarigoldLateCultivar,
      PlantHealthIds.signalMarigoldEstimatedSowingDate,
      PlantHealthIds.signalMarigoldRecentPinching,
      PlantHealthIds.signalMarigoldDenseSpacing,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldSmallBudsPresent,
      PlantHealthIds.signalMarigoldWithinCalendar,
      PlantHealthIds.signalMarigoldWhiteRings,
      PlantHealthIds.signalRootsDarkRot,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_excess_nitrogen_growth_possible',
        labelEs: 'Crecimiento vegetativo favorecido por exceso de N posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un follaje exuberante con pocos botones puede acompañar una fertilidad nitrogenada alta.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldHighNitrogenReported,
          PlantHealthIds.signalMarigoldLushFoliage,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSmallBudsPresent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_low_light_etiolation_possible',
        labelEs: 'Luz insuficiente y elongación posible',
        type: 'abiotic_possible',
        summaryEs:
            'Tallos débiles, entrenudos largos e inclinación hacia la luz favorecen una baja iluminación.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldInsufficientLight,
          PlantHealthIds.signalMarigoldLongInternodes,
          PlantHealthIds.signalMarigoldLongSoftStems,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSmallBudsPresent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_photoperiod_delay_possible',
        labelEs: 'Retraso por fotoperiodo o interrupción nocturna posible',
        type: 'phenology_context',
        summaryEs:
            'En cultivares sensibles, noches interrumpidas o días largos pueden retrasar el botón; no es una regla universal ni una lectura de la sonda.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldNightLightConfirmed,
          PlantHealthIds.signalMarigoldNoBudsPastWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSmallBudsPresent,
          PlantHealthIds.signalMarigoldWithinCalendar,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_late_cultivar_or_clock_error_possible',
        labelEs: 'Cultivar tardío o fecha de siembra incorrecta posible',
        type: 'data_or_genotype',
        summaryEs:
            'Un calendario equivocado puede hacer parecer anormal a una planta que todavía está en vegetativo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldLateCultivar,
          PlantHealthIds.signalMarigoldEstimatedSowingDate,
          PlantHealthIds.signalMarigoldWithinCalendar,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldNoBudsPastWindow,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Ya superó la ventana de botón de su perfil?',
      '¿Recibe sol suficiente?',
      '¿Hay luz artificial durante la noche?',
      '¿Se aplicó mucho nitrógeno?',
      '¿Los entrenudos son largos?',
      '¿La fecha de siembra es real o estimada?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Verifica calendario y cultivar antes de tratar esto como un problema.',
      'Revisa luz, noche, nitrógeno y densidad como hipótesis separadas.',
      'No recomiendes fósforo como solución automática.',
      'Corrige la fecha de siembra o el perfil sin borrar historial si hacía falta.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsRecentStress: true,
  ),

  // S13. Botones cafés, deformes o que no logran abrir.
  PlantHealthSyndrome(
    id: 'marigold_bud_browning_abortion_13',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Botones cafés, deformes o que no logran abrir',
    stages: _budBloomStages,
    organIds: <String>{
      PlantHealthIds.organBud,
      PlantHealthIds.organFlowerHead,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldBudBrowningAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldBudBrownOrBlack,
      PlantHealthIds.signalMarigoldBudDrySealed,
      PlantHealthIds.signalMarigoldIncompleteOpening,
      PlantHealthIds.signalMarigoldDeformedPetals,
      PlantHealthIds.signalMarigoldBudDrop,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalSalinityLoad,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldYoungBudFirmGreen,
      PlantHealthIds.signalMarigoldUniformDryFlowerNoMold,
      PlantHealthIds.signalHailEvent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_botrytis_bud_rot_possible',
        labelEs: 'Moho gris o pudrición de botón posible',
        type: 'condition_compatible',
        summaryEs:
            'Botones húmedos que se tornan cafés con moho favorecen Botrytis.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
          PlantHealthIds.signalMarigoldWateryFlowerTissue,
          PlantHealthIds.signalHumidWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldBudDrySealed,
          PlantHealthIds.signalDryHotWindow,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_alternaria_bud_blight_possible',
        labelEs: 'Tizón de botón por Alternaria posible',
        type: 'condition_compatible',
        summaryEs:
            'Botones que se arrugan y oscurecen sin abrir pueden ser compatibles con un tizón fúngico.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldBudBrownOrBlack,
          PlantHealthIds.signalMarigoldPetalPedicelDarkening,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_heat_drought_bud_abort_possible',
        labelEs: 'Aborto por calor o déficit hídrico posible',
        type: 'abiotic_possible',
        summaryEs:
            'El calor y la sequedad durante el botón pueden reducir la apertura y el tamaño floral.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHeatStress,
          PlantHealthIds.signalDryHotWindow,
          PlantHealthIds.signalMarigoldBudDrop,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_thrips_bud_injury_possible',
        labelEs: 'Daño de trips dentro del botón posible',
        type: 'arthropod_possible',
        summaryEs:
            'Pétalos raspados, deformación y puntos negros sin moho favorecen trips.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalThripsPresent,
          PlantHealthIds.signalMarigoldBlackThripsSpecks,
          PlantHealthIds.signalMarigoldDamageInsideBud,
          PlantHealthIds.signalMarigoldDeformedPetals,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El botón está seco o acuoso?',
      '¿Hay moho gris?',
      '¿Hay trips dentro del botón?',
      '¿Coincidió con un periodo de calor o sequedad?',
      '¿La EC está alta?',
      '¿Afecta a todos los botones o solo a algunos?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Revisa botones con lupa sin desarmar toda la planta.',
      'Separa el daño húmedo del daño seco.',
      'No apliques fertilizante para "abrir" botones.',
      'Busca revisión si el problema aumenta rápidamente.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ────────────────────────────────────────────────────────────────────────
  // Familia 5: Plagas e invertebrados.
  // ────────────────────────────────────────────────────────────────────────
  // S14. Pétalos o hojas plateados, raspados y con puntos negros.
  PlantHealthSyndrome(
    id: 'marigold_silver_scar_black_specks_thrips_14',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Pétalos o hojas plateados, raspados y con puntos negros',
    stages: _seedlingToBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organBud,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldSilverScarring,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldSilverScarring,
      PlantHealthIds.signalMarigoldBlackThripsSpecks,
      PlantHealthIds.signalMarigoldSlenderMobileInsects,
      PlantHealthIds.signalMarigoldDamageInsideBud,
      PlantHealthIds.signalMarigoldNewLeafDistorted,
      PlantHealthIds.signalThripsPresent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalMarigoldNearbyWeeds,
      PlantHealthIds.signalVectorPresent,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalMarigoldRecentSprayEvent,
      PlantHealthIds.signalMarigoldSunExposedSideDamage,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_thrips_feeding_possible',
        labelEs: 'Alimentación de trips posible',
        type: 'arthropod_possible',
        summaryEs:
            'El raspado plateado, los puntos negros y los insectos alargados favorecen trips.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSilverScarring,
          PlantHealthIds.signalMarigoldBlackThripsSpecks,
          PlantHealthIds.signalMarigoldSlenderMobileInsects,
          PlantHealthIds.signalThripsPresent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_thrips_vector_risk',
        labelEs: 'Riesgo vectorial asociado a trips',
        type: 'vector_risk',
        summaryEs:
            'La presencia de trips aumenta el contexto para TSWV o INSV, pero no confirma un virus.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalThripsPresent,
          PlantHealthIds.signalMarigoldWhiteRings,
          PlantHealthIds.signalVectorPresent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldKnownVariegation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_spider_mite_scarring_differential',
        labelEs: 'Ácaros como diferencial',
        type: 'arthropod_possible',
        summaryEs:
            'Un punteado fino generalizado con telaraña favorece ácaros y no trips.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
          PlantHealthIds.signalMarigoldFineWhiteStippling,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldBlackThripsSpecks,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_spray_or_weather_scar_possible',
        labelEs: 'Cicatriz por aspersión o clima posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un daño simultáneo después de lluvia, granizo o un producto puede parecer un raspado.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldRecentSprayEvent,
          PlantHealthIds.signalHailEvent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSlenderMobileInsects,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay puntos negros sobre la zona plateada?',
      '¿Ves insectos delgados dentro de las flores?',
      '¿El daño está en los brotes nuevos?',
      '¿Hay anillos o mosaico además del raspado?',
      '¿Existe telaraña?',
      '¿Hubo granizo o una aspersión?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Revisa flores y hojas sacudiéndolas sobre papel claro.',
      'Fotografía el insecto y el daño por separado.',
      'No infieras un virus solo por encontrar trips.',
      'Protege polinizadores y respeta las etiquetas locales si un profesional recomienda manejo.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsVectorPressure: true,
  ),

  // S15. Colonias pequeñas, melaza, hojas pegajosas o tizne negro.
  PlantHealthSyndrome(
    id: 'marigold_sticky_colonies_honeydew_15',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Colonias pequeñas, melaza, hojas pegajosas o tizne negro',
    stages: _systemicStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organBud,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldStickyColonies,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldAphidClusters,
      PlantHealthIds.signalWhiteflyCloud,
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
      PlantHealthIds.signalMarigoldCurledNewGrowth,
      PlantHealthIds.signalMarigoldAntsPresent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMarigoldHighNitrogenReported,
      PlantHealthIds.signalMarigoldDenseSpacing,
      PlantHealthIds.signalMarigoldPoorVentilation,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldBlackDotsInLesion,
      PlantHealthIds.signalMarigoldBlackThripsSpecks,
      PlantHealthIds.signalMarigoldDustySite,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_aphids_possible',
        labelEs: 'Áfidos posibles',
        type: 'arthropod_possible',
        summaryEs:
            'Colonias blandas sobre brotes y hojas curvadas favorecen áfidos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldAphidClusters,
          PlantHealthIds.signalMarigoldCurledNewGrowth,
          PlantHealthIds.signalMarigoldAntsPresent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalWhiteflyCloud,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_whiteflies_possible',
        labelEs: 'Mosca blanca posible',
        type: 'arthropod_possible',
        summaryEs:
            'Adultos blancos que vuelan al mover la planta y ninfas en el envés favorecen mosca blanca.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWhiteflyCloud,
          PlantHealthIds.signalStickyHoneydew,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldAphidClusters,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_sooty_mold_secondary_possible',
        labelEs: 'Tizne secundario sobre melaza posible',
        type: 'secondary_condition',
        summaryEs:
            'Una capa negra superficial puede crecer sobre excreciones azucaradas sin invadir el tejido.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSootyMold,
          PlantHealthIds.signalStickyHoneydew,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldBlackDotsInLesion,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_other_scale_mealybug_possible',
        labelEs: 'Otra cochinilla o escama posible',
        type: 'arthropod_possible',
        summaryEs:
            'Cera o escudos inmóviles requieren un diferencial distinto al de áfidos y mosca blanca.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldWaxyScaleShields,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalWhiteflyCloud,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La hoja está pegajosa?',
      '¿Hay insectos agrupados en los brotes?',
      '¿Vuelan adultos blancos al mover la planta?',
      '¿El negro se limpia de la superficie?',
      '¿Hay hormigas?',
      '¿El crecimiento nuevo está curvado?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Fotografía el envés y los brotes.',
      'Distingue insecto, melaza y tizne como señales diferentes.',
      'Revisa las plantas vecinas.',
      'No recomiendes un plaguicida sin identificar el grupo y revisar polinizadores.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsVectorPressure: true,
    favorsHighHumidity: true,
  ),

  // S16. Punteado fino, bronceado y telaraña.
  PlantHealthSyndrome(
    id: 'marigold_stippling_bronzing_webbing_16',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Punteado fino, bronceado y telaraña',
    stages: _midVegToPostBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldStipplingBronzingWebbing,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldFineWhiteStippling,
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalMarigoldTinyMitesVisible,
      PlantHealthIds.signalMarigoldPrematureLeafDrop,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalMarigoldDustySite,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalMarigoldBlackThripsSpecks,
      PlantHealthIds.signalMarigoldBronzeSpecklesOlderLeaves,
      PlantHealthIds.signalMarigoldUniformChlorosis,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_spider_mites_possible',
        labelEs: 'Ácaros tetraníquidos posibles',
        type: 'arthropod_possible',
        summaryEs:
            'Punteado, bronceado y telaraña durante calor seco son compatibles con ácaros.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
          PlantHealthIds.signalMarigoldTinyMitesVisible,
          PlantHealthIds.signalMarigoldFineWhiteStippling,
          PlantHealthIds.signalDryHotWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldLowPhRepeated,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_thrips_differential',
        labelEs: 'Trips como diferencial',
        type: 'arthropod_possible',
        summaryEs:
            'Raspado plateado y excremento negro sin telaraña favorecen trips.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSilverScarring,
          PlantHealthIds.signalMarigoldBlackThripsSpecks,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_iron_toxicity_differential',
        labelEs: 'Bronze speckle como diferencial',
        type: 'abiotic_possible',
        summaryEs:
            'Puntos bronce en hojas viejas, curvatura hacia abajo y pH bajo favorecen una acumulación de Fe/Mn.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldBronzeSpecklesOlderLeaves,
          PlantHealthIds.signalMarigoldDownwardLeafCupping,
          PlantHealthIds.signalMarigoldLowPhRepeated,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_dust_or_spray_residue_possible',
        labelEs: 'Polvo o residuo posible',
        type: 'abiotic_possible',
        summaryEs:
            'Material superficial sin daño celular puede limpiarse y no progresa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldDustySite,
          PlantHealthIds.signalMarigoldResidueWipesOff,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldTinyMitesVisible,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay telaraña?',
      '¿El daño empieza en el envés?',
      '¿Apareció durante un periodo de calor seco?',
      '¿Se ven organismos al sacudir sobre papel claro?',
      '¿Las hojas viejas se curvan hacia abajo?',
      '¿El pH es bajo?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Usa lupa y papel claro para confirmar la presencia.',
      'Compara con bronze speckle y con trips antes de decidir.',
      'Revisa la tendencia de calor y sequedad.',
      'Evita tratamientos de amplio espectro sin identificación.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsRecentStress: true,
  ),

  // S17. Líneas serpenteantes o minas dentro de la hoja.
  PlantHealthSyndrome(
    id: 'marigold_serpentine_leaf_mines_17',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Líneas serpenteantes o minas dentro de la hoja',
    stages: _earlyVegToBloomStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomMarigoldSerpentineMines,
    strongSignals: <String>{
      PlantHealthIds.signalLeafMines,
      PlantHealthIds.signalMarigoldMineWidensWithLarva,
      PlantHealthIds.signalMarigoldNewMinesAppearing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMarigoldSmallAdultFlies,
      PlantHealthIds.signalMarigoldNearbyWeeds,
      PlantHealthIds.signalHeatStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldSilverScarring,
      PlantHealthIds.signalMarigoldChloroticHalo,
      PlantHealthIds.signalMarigoldIrregularChewedMargins,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_leafminer_possible',
        labelEs: 'Minador de hoja posible',
        type: 'arthropod_possible',
        summaryEs:
            'Las galerías internas son compatibles con minadores, incluidos Liriomyza y otros grupos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalLeafMines,
          PlantHealthIds.signalMarigoldMineWidensWithLarva,
          PlantHealthIds.signalMarigoldSmallAdultFlies,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSilverScarring,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_physical_or_fungal_differential',
        labelEs: 'Daño físico o mancha como diferencial',
        type: 'condition_or_physical',
        summaryEs:
            'Lesiones que no siguen una galería interna requieren otro diagnóstico.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldChloroticHalo,
          PlantHealthIds.signalMarigoldIrregularChewedMargins,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldMineWidensWithLarva,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La línea está dentro del tejido de la hoja?',
      '¿Se ensancha conforme avanza?',
      '¿Hay larva o excremento dentro?',
      '¿Aparecen minas nuevas?',
      '¿Hay adultos pequeños tipo mosca?',
      '¿Las hojas vecinas están afectadas?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Fotografía la hoja a contraluz.',
      'Registra cuántas hojas nuevas resultan afectadas.',
      'No abras todas las minas.',
      'Busca orientación si el daño alcanza gran parte del follaje.',
    ],
    disclaimerEs: _marigoldDisclaimer,
  ),

  // S18. Hojas o flores mordidas, agujeros o plántulas cortadas.
  PlantHealthSyndrome(
    id: 'marigold_chewed_holes_cut_seedlings_18',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Hojas o flores mordidas, agujeros o plántulas cortadas',
    stages: _seedlingToBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organBud,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldChewingDamage,
    strongSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalMarigoldIrregularChewedMargins,
      PlantHealthIds.signalMarigoldMissingTissue,
      PlantHealthIds.signalMarigoldStemCleanCut,
      PlantHealthIds.signalMarigoldSlimeTrail,
      PlantHealthIds.signalMarigoldCaterpillarFrass,
      PlantHealthIds.signalMarigoldBeetleOnFlower,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMarigoldNightDamage,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalMarigoldNearbyWeeds,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldChloroticHalo,
      PlantHealthIds.signalMarigoldStemPinchedAtSoil,
      PlantHealthIds.signalMarigoldLeafWetness,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_caterpillar_cutworm_possible',
        labelEs: 'Oruga o gusano cortador posible',
        type: 'arthropod_possible',
        summaryEs:
            'Mordidas, excremento y plántulas seccionadas favorecen larvas masticadoras.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldCaterpillarFrass,
          PlantHealthIds.signalMarigoldStemCleanCut,
          PlantHealthIds.signalMarigoldMissingTissue,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldStemPinchedAtSoil,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_slug_snail_earwig_possible',
        labelEs: 'Babosa, caracol o tijerilla posible',
        type: 'arthropod_possible',
        summaryEs:
            'Daño nocturno, baba y bordes raspados favorecen estos grupos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSlimeTrail,
          PlantHealthIds.signalMarigoldNightDamage,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldCaterpillarFrass,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_flower_beetle_frailecillo_possible',
        labelEs: 'Escarabajo floral o frailecillo posible',
        type: 'arthropod_possible',
        summaryEs:
            'En México se reportan escarabajos llamados regionalmente frailecillo o burrito sobre las flores; el nombre común no confirma la especie.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldBeetleOnFlower,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSlimeTrail,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_mechanical_hail_damage_possible',
        labelEs: 'Granizo o daño mecánico posible',
        type: 'physical_damage',
        summaryEs:
            'Perforaciones simultáneas en un solo lado después de una tormenta favorecen granizo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHailEvent,
          PlantHealthIds.signalMarigoldWindRainEvent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldCaterpillarFrass,
          PlantHealthIds.signalMarigoldSlimeTrail,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El daño ocurrió de noche?',
      '¿Hay baba o excremento?',
      '¿La plántula está cortada limpiamente?',
      '¿Ves orugas o escarabajos sobre las flores?',
      '¿Hubo granizo?',
      '¿El daño sigue apareciendo?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Revisa al amanecer y al anochecer.',
      'Fotografía el organismo antes de intervenir.',
      'Distingue una pérdida estética aislada de una destrucción activa.',
      'No asumas que el aroma del cempasúchil evita todas las plagas.',
    ],
    disclaimerEs: _marigoldDisclaimer,
  ),

  // S19. Raíces con agallas y planta pequeña o marchita.
  PlantHealthSyndrome(
    id: 'marigold_root_galls_stunting_19',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Raíces con agallas y planta pequeña o marchita',
    stages: _seedlingToBloomStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldRootGalls,
    strongSignals: <String>{
      PlantHealthIds.signalRootGalls,
      PlantHealthIds.signalMarigoldGallsIntegralToRoot,
      PlantHealthIds.signalMarigoldStuntedPlant,
      PlantHealthIds.signalMarigoldPatchyFieldPattern,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMarigoldNematodeHistory,
      PlantHealthIds.signalHeatStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldNodulesRubOff,
      PlantHealthIds.signalMarigoldRootBoundCoiled,
      PlantHealthIds.signalRootsDarkRot,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_root_knot_nematode_possible',
        labelEs: 'Nematodo agallador posible',
        type: 'condition_compatible',
        summaryEs:
            'Aunque muchas Tagetes ayudan a reducir ciertas poblaciones de Meloidogyne, la respuesta depende de especie y cultivar y no autoriza asumir inmunidad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldGallsIntegralToRoot,
          PlantHealthIds.signalRootGalls,
          PlantHealthIds.signalMarigoldNematodeHistory,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldNodulesRubOff,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_normal_lateral_root_or_debris_differential',
        labelEs: 'Raíz lateral o residuo adherido posible',
        type: 'benign_differential',
        summaryEs:
            'Partículas que se desprenden o raíces laterales normales no son agallas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldNodulesRubOff,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldGallsIntegralToRoot,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_root_restriction_possible',
        labelEs: 'Restricción de raíz posible',
        type: 'abiotic_possible',
        summaryEs:
            'Una maceta pequeña, la compactación o una raíz enrollada pueden producir enanismo sin nematodos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldRootBoundCoiled,
          PlantHealthIds.signalMarigoldStuntedPlant,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldGallsIntegralToRoot,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_root_rot_differential',
        labelEs: 'Pudrición de raíz como diferencial',
        type: 'condition_compatible',
        summaryEs:
            'Raíces oscuras, blandas o sin tejido fino favorecen un deterioro radicular.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalMarigoldFineRootsLost,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldGallsIntegralToRoot,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Los bultos forman parte de la raíz?',
      '¿Se desprenden al limpiar suavemente?',
      '¿El problema aparece en parches?',
      '¿Existe historial de Meloidogyne en el sitio?',
      '¿La raíz está firme o podrida?',
      '¿El perfil o el cultivar están identificados?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'No afirmes que todo cempasúchil es inmune a nematodos.',
      'Fotografía las raíces lavadas junto a una escala.',
      'Confirma mediante análisis de suelo o raíz si el daño es importante.',
      'No muevas suelo sospechoso entre camas.',
    ],
    disclaimerEs: _marigoldDisclaimer,
  ),

  // ────────────────────────────────────────────────────────────────────────
  // Familia 6: Estrés abiótico y final normal del ciclo.
  // ────────────────────────────────────────────────────────────────────────
  // S20. Marchitez, hojas secas o flores pequeñas sin lesión específica.
  PlantHealthSyndrome(
    id: 'marigold_wilt_scorch_water_stress_20',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Marchitez, hojas secas o flores pequeñas sin lesión específica',
    stages: _seedlingToBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organBud,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldWaterStressWilt,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldGeneralWilt,
      PlantHealthIds.signalLeafEdgeBurn,
      PlantHealthIds.signalMarigoldSmallFlowers,
      PlantHealthIds.signalMarigoldBudDrop,
      PlantHealthIds.signalMarigoldRecoversAtNight,
      PlantHealthIds.signalMarigoldNoLocalizedLesion,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalMarigoldRootBoundCoiled,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldCollarBrownCrackedSoft,
      PlantHealthIds.signalMarigoldAbnormalOdor,
      PlantHealthIds.signalMarigoldWhiteRings,
      PlantHealthIds.signalMarigoldAphidClusters,
      PlantHealthIds.signalMarigoldSpotsCoalescing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_drought_stress_possible',
        labelEs: 'Estrés por déficit hídrico posible',
        type: 'abiotic_possible',
        summaryEs:
            'Suelo seco, calor y recuperación posterior apoyan un déficit, pero no indican litros exactos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalDryHotWindow,
          PlantHealthIds.signalMarigoldDrySoilFirmRoot,
          PlantHealthIds.signalMarigoldRecoversAtNight,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_waterlogging_root_stress_possible',
        labelEs: 'Estrés por exceso de agua posible',
        type: 'abiotic_possible',
        summaryEs:
            'La marchitez con suelo saturado puede reflejar falta de oxígeno o una raíz dañada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalMarigoldWiltInWetSoil,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldDrySoilFirmRoot,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_salinity_uptake_stress_possible',
        labelEs: 'Dificultad de absorción por sales posible',
        type: 'abiotic_possible',
        summaryEs:
            'Una EC alta puede producir marchitez aun con el suelo húmedo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSalinityLoad,
          PlantHealthIds.signalLeafEdgeBurn,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldRecoversAtNight,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_transient_midday_wilt_possible',
        labelEs: 'Marchitez transitoria por demanda atmosférica posible',
        type: 'benign_differential',
        summaryEs:
            'Una planta que recupera firmeza al bajar la temperatura puede no tener un daño permanente.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldMiddayWiltRecovers,
          PlantHealthIds.signalMarigoldRecoversAtNight,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldCollarBrownCrackedSoft,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El suelo está seco o húmedo en la zona de raíces?',
      '¿La planta se recupera por la noche?',
      '¿Hay base blanda?',
      '¿La EC está alta?',
      '¿Coincidió con viento o calor?',
      '¿Afecta más a las macetas pequeñas?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'No riegues solo por apariencia; confirma la humedad real.',
      'Revisa raíz y EC si el suelo está húmedo.',
      'Registra cuánto dura la marchitez.',
      'Busca revisión si no se recupera o aparece daño de cuello.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsRecentStress: true,
  ),

  // S21. Tejido quemado, translúcido o negro después de calor, sol o frío.
  PlantHealthSyndrome(
    id: 'marigold_temperature_sun_injury_21',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Tejido quemado, translúcido o negro después de calor, sol o frío',
    stages: _allLiveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organBud,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldTemperatureSunInjury,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldSunExposedSideDamage,
      PlantHealthIds.signalMarigoldStrawDryTissue,
      PlantHealthIds.signalMarigoldTranslucentAfterCold,
      PlantHealthIds.signalMarigoldDarkeningAfterFrost,
      PlantHealthIds.signalFrostEvent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMarigoldExposureChange,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalMarigoldRecentTransplant,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldProgressesWithoutEvent,
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalMarigoldWhiteRings,
      PlantHealthIds.signalMarigoldFineWhiteStippling,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_sunscald_heat_injury_possible',
        labelEs: 'Quemadura solar o térmica posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un daño del lado expuesto después de un cambio brusco o de calor reflejado favorece una quemadura.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSunExposedSideDamage,
          PlantHealthIds.signalMarigoldExposureChange,
          PlantHealthIds.signalHeatStress,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldProgressesWithoutEvent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_frost_injury_possible',
        labelEs: 'Daño por frío o helada posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un tejido primero acuoso o translúcido y luego oscuro después de una helada favorece daño por frío.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldTranslucentAfterCold,
          PlantHealthIds.signalMarigoldDarkeningAfterFrost,
          PlantHealthIds.signalFrostEvent,
          PlantHealthIds.signalColdExposure,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSunExposedSideDamage,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_secondary_decay_after_injury_possible',
        labelEs: 'Deterioro secundario de tejido lesionado posible',
        type: 'condition_compatible',
        summaryEs:
            'Un tejido que se vuelve blando, huele o desarrolla moho después del evento requiere revisión sanitaria.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
          PlantHealthIds.signalMarigoldAbnormalOdor,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldStrawDryTissue,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_spot_disease_differential',
        labelEs: 'Mancha infecciosa como diferencial',
        type: 'condition_compatible',
        summaryEs:
            'Lesiones que siguen expandiéndose sin un evento nuevo pueden no ser abióticas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldProgressesWithoutEvent,
          PlantHealthIds.signalMarigoldSpotsCoalescing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSunExposedSideDamage,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo helada o calor extremo?',
      '¿El daño está solo del lado expuesto?',
      '¿La planta cambió de ubicación?',
      '¿El tejido está seco, translúcido o blando?',
      '¿Sigue avanzando?',
      '¿Hay moho u olor?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Registra la fecha y la temperatura del evento.',
      'No declares la muerte de la planta inmediatamente después de una helada.',
      'Evita otro cambio brusco de exposición.',
      'Busca revisión si el tejido se ablanda o el daño llega al cuello.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsRecentStress: true,
    favorsCoolDewyWindow: true,
  ),

  // S22. Tallos doblados, planta caída o flores pesadas.
  PlantHealthSyndrome(
    id: 'marigold_lodging_stem_break_22',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Tallos doblados, planta caída o flores pesadas',
    stages: _stemToBloomStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organRoot,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldLodgingStemBreak,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldBentOrBrokenStem,
      PlantHealthIds.signalMarigoldLeaningAfterWindRain,
      PlantHealthIds.signalMarigoldHeavyFlowerHead,
      PlantHealthIds.signalMarigoldLongInternodes,
      PlantHealthIds.signalMarigoldLooseBase,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMarigoldHighNitrogenReported,
      PlantHealthIds.signalMarigoldInsufficientLight,
      PlantHealthIds.signalMarigoldWindRainEvent,
      PlantHealthIds.signalMarigoldRootBoundCoiled,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldCollarBrownCrackedSoft,
      PlantHealthIds.signalMarigoldGeneralWilt,
      PlantHealthIds.signalStemCanker,
      PlantHealthIds.signalMarigoldNaturallyCompactHabit,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_wind_rain_lodging_possible',
        labelEs: 'Acame por viento o lluvia posible',
        type: 'physical_damage',
        summaryEs:
            'Tallos altos y capítulos pesados pueden doblarse bajo viento o agua.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldWindRainEvent,
          PlantHealthIds.signalMarigoldLeaningAfterWindRain,
          PlantHealthIds.signalMarigoldHeavyFlowerHead,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldCollarBrownCrackedSoft,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_low_light_soft_growth_possible',
        labelEs: 'Tejido débil por baja luz posible',
        type: 'abiotic_possible',
        summaryEs:
            'Entrenudos largos y tallos blandos favorecen una luz insuficiente.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldInsufficientLight,
          PlantHealthIds.signalMarigoldLongInternodes,
          PlantHealthIds.signalMarigoldLongSoftStems,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldNaturallyCompactHabit,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_excess_nitrogen_soft_growth_possible',
        labelEs: 'Crecimiento blando por exceso de N posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un follaje y unos tallos exuberantes pueden reducir la estabilidad de la planta.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldHighNitrogenReported,
          PlantHealthIds.signalMarigoldLushFoliage,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldNaturallyCompactHabit,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_root_anchor_failure_differential',
        labelEs: 'Falla de anclaje o raíz como diferencial',
        type: 'condition_compatible',
        summaryEs:
            'Una planta completa floja con la base alterada requiere revisar raíz y cuello.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldLooseBase,
          PlantHealthIds.signalMarigoldCollarBrownCrackedSoft,
          PlantHealthIds.signalMarigoldRootBoundCoiled,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldWindRainEvent,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo viento, lluvia o riego fuerte?',
      '¿El tallo está quebrado o solo doblado?',
      '¿La base está firme?',
      '¿Es un perfil alto?',
      '¿Los entrenudos son largos?',
      '¿Se aplicó mucho nitrógeno?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'No endereces con fuerza un tallo parcialmente roto.',
      'Revisa soporte, luz, nitrógeno y anclaje como causas separadas.',
      'Evita que el riego por aspersión cargue de agua las flores pesadas.',
      'Busca revisión si la base pierde firmeza.',
    ],
    disclaimerEs: _marigoldDisclaimer,
    favorsRecentStress: true,
  ),

  // S23. Flores envejecidas y planta secándose al final del ciclo.
  PlantHealthSyndrome(
    id: 'marigold_normal_post_bloom_senescence_23',
    cropId: CropCatalog.marigoldCropId,
    labelEs: 'Flores envejecidas y planta secándose al final del ciclo',
    stages: _lateStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMarigoldEndOfCycleSenescence,
    strongSignals: <String>{
      PlantHealthIds.signalMarigoldGradualFlowerDrying,
      PlantHealthIds.signalMarigoldFewerNewBuds,
      PlantHealthIds.signalMarigoldLowerLeavesYellow,
      PlantHealthIds.signalMarigoldSeedsMaturing,
      PlantHealthIds.signalMarigoldDeclineMatchesClock,
      PlantHealthIds.signalMarigoldExpectedSenescence,
    },
    weakSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalMarigoldUniformDryFlowerNoMold,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMarigoldCollarBrownCrackedSoft,
      PlantHealthIds.signalMarigoldAbnormalOdor,
      PlantHealthIds.signalMarigoldSuddenEarlyCollapse,
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalMarigoldWhiteRings,
      PlantHealthIds.signalMarigoldWiltInWetSoil,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'marigold_normal_senescence_compatible',
        labelEs: 'Senescencia anual normal compatible',
        type: 'expected_lifecycle',
        summaryEs:
            'El cempasúchil es anual; el envejecimiento progresivo después de la ventana floral puede ser el cierre normal del ciclo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldDeclineMatchesClock,
          PlantHealthIds.signalMarigoldGradualFlowerDrying,
          PlantHealthIds.signalMarigoldExpectedSenescence,
          PlantHealthIds.signalMarigoldSeedsMaturing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldAbnormalOdor,
          PlantHealthIds.signalMarigoldSuddenEarlyCollapse,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_flower_aging_only_possible',
        labelEs: 'Envejecimiento de flores aisladas posible',
        type: 'benign_differential',
        summaryEs:
            'Algunas flores viejas pueden secarse mientras la planta continúa en floración.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldHealthyBudsStillForming,
          PlantHealthIds.signalMarigoldUniformDryFlowerNoMold,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldFewerNewBuds,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_disease_or_root_decline_differential',
        labelEs: 'Enfermedad o raíz dañada como diferencial',
        type: 'condition_compatible',
        summaryEs:
            'Un declive precoz, húmedo, maloliente o rápido no debe atribuirse al calendario.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMarigoldSuddenEarlyCollapse,
          PlantHealthIds.signalMarigoldAbnormalOdor,
          PlantHealthIds.signalMarigoldWiltInWetSoil,
          PlantHealthIds.signalGrayFuzzyGrowth,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldDeclineMatchesClock,
        },
      ),
      PlantHealthDiagnosis(
        id: 'marigold_frost_termination_possible',
        labelEs: 'Cierre acelerado por helada posible',
        type: 'abiotic_possible',
        summaryEs:
            'Una helada puede terminar el ciclo antes de lo que indicaba el reloj.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalFrostEvent,
          PlantHealthIds.signalMarigoldDarkeningAfterFrost,
          PlantHealthIds.signalColdExposure,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMarigoldGradualFlowerDrying,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La planta está en posfloración o senescencia según su fecha?',
      '¿Aún produce botones sanos?',
      '¿El secado es gradual y el tejido firme?',
      '¿Hay tejido blando, olor o moho?',
      '¿Ocurrió una helada?',
      '¿Solo envejeció una flor?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'No marques posfloración por la primera flor marchita.',
      'No presentes la senescencia normal como una enfermedad.',
      'Permite que la floración continúe mientras haya botones y flores nuevas dominantes.',
      'Escala solo si aparecen señales incompatibles con un cierre normal.',
    ],
    disclaimerEs: _marigoldDisclaimer,
  ),
];
