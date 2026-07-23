import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

// Conjuntos de etapas del Rosal (Doc C §5). El Rosal usa un mapeo propio de
// recurring_bloom y NO reutiliza establishment_maintenance.
const Set<PlantHealthStageBucket> _roseAllStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _roseLeafActiveStages =
    <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _roseFlowerStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _roseRootStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _roseCaneStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.lateSeason,
};

const String _roseDisclaimer =
    'BIO-G organiza observaciones y contexto para orientar la revisión. '
    'No confirma una enfermedad, una plaga ni un organismo causal.';

/// Catálogo visual prudente para Rosal ornamental (Doc C).
///
/// El catálogo se organiza por síndromes observables ("¿qué ves en tu rosal?"),
/// nunca por enfermedades. Los cuadros describen condiciones compatibles y
/// preguntas de confirmación. Ninguna lectura del dispositivo confirma por sí
/// sola un hongo, una bacteria, un virus, un ácaro, un insecto, una pudrición,
/// una deficiencia ni una toxicidad.
const List<PlantHealthSyndrome> roseSyndromes = <PlantHealthSyndrome>[
  // S01 — Manchas oscuras, amarillamiento y caída.
  PlantHealthSyndrome(
    id: 'rose_dark_leaf_spots_yellow_drop_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Manchas oscuras y hojas que amarillean o caen',
    stages: _roseLeafActiveStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalRoseFeatheryBlackMargin,
      PlantHealthIds.signalRoseYellowHaloOrLeaf,
      PlantHealthIds.signalRoseLowerLeavesFirst,
      PlantHealthIds.signalRosePrematureLeafDrop,
      PlantHealthIds.signalRoseSpotsProgressWetWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalDenseWetCanopy,
      PlantHealthIds.signalRoseSpotsOnCanes,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseOrangePowderUnderLeaf,
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalRoseVeinLimitedAngular,
      PlantHealthIds.signalRoseUniformEdgeScorch,
      PlantHealthIds.signalRoseSpotsDoNotProgress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_black_spot_compatible',
        labelEs: 'Condición compatible con mancha negra del rosal',
        scientificName: 'Diplocarpon rosae',
        type: 'condition_compatible',
        summaryEs:
            'La combinación de manchas oscuras con borde irregular, '
            'amarillamiento y caída es compatible con mancha negra. '
            'BIO-G no confirma el hongo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseFeatheryBlackMargin,
          PlantHealthIds.signalRoseYellowHaloOrLeaf,
          PlantHealthIds.signalRoseLowerLeavesFirst,
          PlantHealthIds.signalRosePrematureLeafDrop,
          PlantHealthIds.signalRoseSpotsProgressWetWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalWhitePowderGrowth,
          PlantHealthIds.signalRoseOrangePowderUnderLeaf,
          PlantHealthIds.signalRoseVeinLimitedAngular,
          PlantHealthIds.signalRoseUniformEdgeScorch,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_other_leaf_spot_possible',
        labelEs: 'Otra mancha foliar por confirmar',
        type: 'condition_compatible',
        summaryEs:
            'Varias manchas foliares se parecen entre sí. El color del centro, '
            'el borde y la parte inferior de la hoja ayudan a diferenciarlas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseLeafCenterFallsFromSpot,
          PlantHealthIds.signalRoseSpotsDoNotProgress,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseFeatheryBlackMargin,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_spray_or_physical_spot_possible',
        labelEs: 'Daño por aspersión o salpicadura posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un tratamiento reciente, un patrón de gotas y lesiones que '
            'aparecieron a la vez y no avanzan orientan a un daño físico o '
            'químico, no a una enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseRecentSpray,
          PlantHealthIds.signalRoseDropletPattern,
          PlantHealthIds.signalRoseSpotsDoNotProgress,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseSpotsProgressWetWindow,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La mancha tiene borde irregular o como con flecos?',
      '¿La hoja se pone amarilla alrededor?',
      '¿Empieza en las hojas de abajo?',
      '¿Las hojas se caen con facilidad?',
      '¿Las manchas aumentan después de lluvia o follaje mojado?',
      '¿Hay polvo o pústulas debajo de la hoja?',
      '¿Aplicaste algo sobre el follaje recientemente?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Revisa ambos lados de varias hojas.',
      'Retira del área de revisión las hojas caídas para observar nueva progresión.',
      'Evita mojar el follaje mientras confirmas.',
      'Mejora el espacio entre ramas sin realizar una poda agresiva inmediata.',
      'Registra si las manchas aparecen en hojas nuevas.',
      'Busca evaluación local si la caída avanza rápidamente.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  // S02 — Polvillo blanco y crecimiento deformado.
  PlantHealthSyndrome(
    id: 'rose_white_powder_distorted_growth_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Polvillo blanco y hojas o botones deformados',
    stages: _roseLeafActiveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomPowderyGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalRosePowderRubsOrSmears,
      PlantHealthIds.signalRoseYoungLeavesCurled,
      PlantHealthIds.signalRoseBudsSepalsWhite,
      PlantHealthIds.signalRoseRedTintAroundPowder,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalRoseWarmDayCoolNight,
      PlantHealthIds.signalRoseCrowdedNewGrowth,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseUniformSprayResidue,
      PlantHealthIds.signalRoseOrangePowderUnderLeaf,
      PlantHealthIds.signalRoseCottonyWax,
      PlantHealthIds.signalRoseNoGrowthDistortion,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_powdery_mildew_compatible',
        labelEs: 'Condición compatible con oídio o cenicilla',
        scientificName: 'Podosphaera pannosa',
        type: 'condition_compatible',
        summaryEs:
            'El polvillo superficial con deformación del crecimiento nuevo es '
            'compatible con oídio. BIO-G no confirma el organismo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRosePowderRubsOrSmears,
          PlantHealthIds.signalRoseYoungLeavesCurled,
          PlantHealthIds.signalRoseBudsSepalsWhite,
          PlantHealthIds.signalRoseRedTintAroundPowder,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseUniformSprayResidue,
          PlantHealthIds.signalRoseOrangePowderUnderLeaf,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_spray_residue_possible',
        labelEs: 'Residuo de aspersión o mineral posible',
        type: 'abiotic_possible',
        summaryEs:
            'Una capa uniforme, con patrón de gotas, que no aumenta ni deforma '
            'el tejido nuevo y se desprende como residuo seco orienta a una '
            'aplicación reciente.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseRecentSpray,
          PlantHealthIds.signalRoseUniformSprayResidue,
          PlantHealthIds.signalRoseNoGrowthDistortion,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseYoungLeavesCurled,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_waxy_or_normal_surface_possible',
        labelEs: 'Superficie natural o depósito por confirmar',
        type: 'benign_differential',
        summaryEs:
            'Algunas hojas tienen brillo, cerosidad o polvo ambiental sin '
            'progresión ni tejido deformado; conviene compararlas con hojas '
            'jóvenes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseNoGrowthDistortion,
          PlantHealthIds.signalRoseSpotsDoNotProgress,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRosePowderRubsOrSmears,
          PlantHealthIds.signalRoseYoungLeavesCurled,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El blanco parece harina o ceniza?',
      '¿Está también en botones, sépalos o tallos jóvenes?',
      '¿Las hojas nuevas están torcidas?',
      '¿Aumenta entre revisiones?',
      '¿Aplicaste un producto o agua con minerales?',
      '¿El blanco está solo debajo de la hoja?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Compara hojas jóvenes y maduras.',
      'Revisa si el polvo aumenta en los brotes nuevos.',
      'Mejora la ventilación sin deshidratar la planta.',
      'Evita el exceso de nitrógeno mientras el crecimiento está blando.',
      'Busca evaluación local si el botón deja de desarrollarse.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  // S03 — Manchas angulares moradas y caída rápida.
  PlantHealthSyndrome(
    id: 'rose_angular_purple_rapid_drop_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Manchas angulares moradas o marrones y caída rápida',
    stages: _roseLeafActiveStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAngularSpots,
    strongSignals: <String>{
      PlantHealthIds.signalAngularLesionPattern,
      PlantHealthIds.signalRoseVeinLimitedAngular,
      PlantHealthIds.signalRosePurpleRedBrownSpots,
      PlantHealthIds.signalUndersideSporulation,
      PlantHealthIds.signalPurpleDownySporulation,
      PlantHealthIds.signalRapidFoliarCollapse,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalDenseWetCanopy,
      PlantHealthIds.signalRoseRecentWetWeather,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseFeatheryBlackMargin,
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalRoseOrangePowderUnderLeaf,
      PlantHealthIds.signalRoseUniformSprayResidue,
      PlantHealthIds.signalRoseSpotsDoNotProgress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_downy_mildew_compatible',
        labelEs: 'Condición compatible con mildiu velloso',
        scientificName: 'Peronospora sparsa',
        type: 'condition_compatible',
        summaryEs:
            'El patrón angular con caída rápida y posible crecimiento debajo '
            'de la hoja es compatible con mildiu. Puede confundirse con '
            'nutrición, daño químico o mancha negra.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAngularLesionPattern,
          PlantHealthIds.signalRoseVeinLimitedAngular,
          PlantHealthIds.signalRosePurpleRedBrownSpots,
          PlantHealthIds.signalUndersideSporulation,
          PlantHealthIds.signalPurpleDownySporulation,
          PlantHealthIds.signalRapidFoliarCollapse,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseFeatheryBlackMargin,
          PlantHealthIds.signalWhitePowderGrowth,
          PlantHealthIds.signalRoseOrangePowderUnderLeaf,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_black_spot_differential',
        labelEs: 'Mancha negra como diferencial',
        scientificName: 'Diplocarpon rosae',
        type: 'condition_compatible',
        summaryEs:
            'Un borde fibroso, manchas no limitadas por venas que empiezan '
            'abajo y amarillamiento alrededor orientan más a mancha negra que '
            'a mildiu.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseFeatheryBlackMargin,
          PlantHealthIds.signalRoseLowerLeavesFirst,
          PlantHealthIds.signalRoseYellowHaloOrLeaf,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseVeinLimitedAngular,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_spray_or_nutrition_differential',
        labelEs: 'Daño químico o alteración nutricional posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un patrón uniforme, con aplicación reciente, sin crecimiento en '
            'el envés y sin progresión orienta a daño químico o nutricional.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseUniformSprayResidue,
          PlantHealthIds.signalRoseRecentSpray,
          PlantHealthIds.signalRoseSpotsDoNotProgress,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalUndersideSporulation,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La forma de la mancha sigue las venas?',
      '¿Es morada, rojiza o marrón?',
      '¿Hay un vellito o polvo gris debajo?',
      '¿Las hojas se caen rápidamente?',
      '¿Hubo lluvia, rocío o humedad alta?',
      '¿Aplicaste un producto recientemente?',
      '¿Otras plantas también se deformaron?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Separa temporalmente las plantas en maceta si es posible.',
      'Evita mover hojas mojadas entre rosales.',
      'Registra la velocidad de caída.',
      'Revisa el envés con buena luz.',
      'Busca evaluación local si el patrón avanza en uno o dos días.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  // S04 — Pústulas naranjas debajo de la hoja.
  PlantHealthSyndrome(
    id: 'rose_orange_pustules_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Puntos o polvo naranja debajo de las hojas',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.lateSeason,
    },
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomOrangePustules,
    strongSignals: <String>{
      PlantHealthIds.signalRoseOrangePowderUnderLeaf,
      PlantHealthIds.signalSporesRubOff,
      PlantHealthIds.signalRoseRaisedOrangeBumps,
      PlantHealthIds.signalRoseUpperLeafDiscoloration,
      PlantHealthIds.signalRoseLeafTwistingWithOrange,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalRosePrematureLeafDrop,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseFeatheryBlackMargin,
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalRoseInsectEggsDistinct,
      PlantHealthIds.signalRoseOrangeObjectsDoNotSmear,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_rust_compatible',
        labelEs: 'Condición compatible con roya del rosal',
        scientificName: 'Phragmidium spp.',
        type: 'condition_compatible',
        summaryEs:
            'Pústulas elevadas naranjas que predominan debajo de la hoja, '
            'liberan polvo y decoloran la parte superior son compatibles con '
            'roya. BIO-G no confirma el organismo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseOrangePowderUnderLeaf,
          PlantHealthIds.signalSporesRubOff,
          PlantHealthIds.signalRoseRaisedOrangeBumps,
          PlantHealthIds.signalRoseUpperLeafDiscoloration,
          PlantHealthIds.signalRoseLeafTwistingWithOrange,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseInsectEggsDistinct,
          PlantHealthIds.signalRoseOrangeObjectsDoNotSmear,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_insect_eggs_or_residue_possible',
        labelEs: 'Huevos, residuos o partículas posibles',
        type: 'benign_differential',
        summaryEs:
            'Objetos definidos que no sueltan polvo, con individuos visibles y '
            'sin lesión en el tejido, orientan a huevos o residuos y no a una '
            'enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseInsectEggsDistinct,
          PlantHealthIds.signalRoseOrangeObjectsDoNotSmear,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSporesRubOff,
          PlantHealthIds.signalRoseOrangePowderUnderLeaf,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Los puntos están principalmente debajo de la hoja?',
      '¿Se levantan como pequeños bultos?',
      '¿Suelta polvo naranja al tocar con cuidado?',
      '¿La parte superior de la hoja se decoloró?',
      '¿Parecen huevos separados?',
      '¿Hay hojas torcidas o marchitas?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Revisa varias hojas por ambos lados.',
      'Evita trasladar hojas afectadas entre plantas.',
      'Retira material caído del área de observación.',
      'Busca confirmación si aparecen nuevas pústulas.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  // S05 — Botones o flores que no abren.
  PlantHealthSyndrome(
    id: 'rose_bud_flower_browning_failed_open_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Botones o flores manchados, deformes o que no abren',
    stages: _roseFlowerStages,
    organIds: <String>{PlantHealthIds.organFlower},
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalRoseBudFailsToOpen,
      PlantHealthIds.signalRoseBrownSpottedPetals,
      PlantHealthIds.signalRoseGrayFuzzyFlower,
      PlantHealthIds.signalRosePetalScratchesFlecks,
      PlantHealthIds.signalRoseTinyInsectsInsideFlower,
      PlantHealthIds.signalRoseBentBlackenedShootTip,
    },
    weakSignals: <String>{
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalFlowerDrop,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalRoseOldSpentFlower,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseFlowerOpenedNormally,
      PlantHealthIds.signalRoseDamageOnlyAfterAging,
      PlantHealthIds.signalRoseNoInsectsNoMoldStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_botrytis_flower_blight_compatible',
        labelEs: 'Condición compatible con moho gris en botón o flor',
        scientificName: 'Botrytis cinerea',
        type: 'condition_compatible',
        summaryEs:
            'Pétalos manchados, botón marrón con pelusa gris y tejido húmedo '
            'en periodo fresco y húmedo son compatibles con moho gris. '
            'BIO-G no confirma el organismo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseBrownSpottedPetals,
          PlantHealthIds.signalRoseGrayFuzzyFlower,
          PlantHealthIds.signalGrayFuzzyGrowth,
          PlantHealthIds.signalHumidWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRosePetalScratchesFlecks,
          PlantHealthIds.signalRoseTinyInsectsInsideFlower,
          PlantHealthIds.signalRoseDamageOnlyAfterAging,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_thrips_damage_possible',
        labelEs: 'Daño por trips posible',
        type: 'arthropod_possible',
        summaryEs:
            'Pétalos raspados con marcas plateadas, pequeñas rayas y diminutos '
            'insectos al sacudir la flor orientan a trips.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRosePetalScratchesFlecks,
          PlantHealthIds.signalRoseTinyInsectsInsideFlower,
          PlantHealthIds.signalThripsPresent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseGrayFuzzyFlower,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_midge_or_shoot_tip_pest_possible',
        labelEs: 'Plaga del botón o de la punta por confirmar',
        type: 'arthropod_possible',
        summaryEs:
            'Puntas dobladas, botones negros o secos y daño concentrado en los '
            'puntos de crecimiento, sin pelusa gris, orientan a una plaga de '
            'brote o punta.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseBentBlackenedShootTip,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseGrayFuzzyFlower,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_heat_water_stress_bud_possible',
        labelEs: 'Estrés de calor o agua posible',
        type: 'abiotic_possible',
        summaryEs:
            'Suelo seco, calor y daño simultáneo en muchos botones, sin '
            'insectos ni pelusa y con pétalos crujientes, orientan a estrés '
            'ambiental.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHeatStress,
          PlantHealthIds.signalRoseSoilDry,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseTinyInsectsInsideFlower,
          PlantHealthIds.signalRoseGrayFuzzyFlower,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_normal_flower_senescence_possible',
        labelEs: 'Flor agotada por edad posible',
        type: 'benign_differential',
        summaryEs:
            'Una flor que ya había abierto, cuyos pétalos caen con normalidad '
            'sin avanzar a botones jóvenes ni a lesión de tallo, apunta a '
            'envejecimiento normal.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseOldSpentFlower,
          PlantHealthIds.signalRoseFlowerOpenedNormally,
          PlantHealthIds.signalRoseDamageOnlyAfterAging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseGrayFuzzyFlower,
          PlantHealthIds.signalRoseBentBlackenedShootTip,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El botón nunca abrió o la flor ya estaba vieja?',
      '¿Hay pelusa gris?',
      '¿Los pétalos tienen raspaduras o puntos?',
      '¿Ves insectos pequeños dentro?',
      '¿La punta del tallo está doblada o negra?',
      '¿Hubo calor fuerte o suelo muy seco?',
      '¿El daño avanza a botones nuevos?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Retira de la observación las flores completamente agotadas para distinguir el daño nuevo.',
      'Revisa el interior de los botones con luz.',
      'Sacude una flor sobre papel claro para buscar insectos.',
      'Evita mantener las flores mojadas.',
      'Registra humedad, calor y progresión.',
      'Busca identificación local antes de tratar.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),
  // S06 — Lesión en caña o muerte regresiva.
  PlantHealthSyndrome(
    id: 'rose_cane_lesion_dieback_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Rama con lesión, zona hundida o muerte regresiva',
    stages: _roseCaneStages,
    organIds: <String>{PlantHealthIds.organStem},
    primarySymptomId: PlantHealthIds.symptomShootDecayCanker,
    strongSignals: <String>{
      PlantHealthIds.signalStemCanker,
      PlantHealthIds.signalRoseDeadBranchAmongHealthy,
      PlantHealthIds.signalRosePurpleBlackCaneLesion,
      PlantHealthIds.signalRoseGrayCenterBlackDots,
      PlantHealthIds.signalRoseCaneDiesFromTip,
      PlantHealthIds.signalRoseCrackedFlakingBark,
    },
    weakSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalRoseRecentPruning,
      PlantHealthIds.signalRoseStemSwelling,
      PlantHealthIds.signalRoseSunnyExposedSide,
      PlantHealthIds.signalShootTipWilt,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseCaneUniformlyGreenInside,
      PlantHealthIds.signalRoseNormalOldWood,
      PlantHealthIds.signalRoseSpotsDoNotProgress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_canker_dieback_compatible',
        labelEs: 'Condición compatible con cancro o muerte regresiva',
        type: 'condition_compatible',
        summaryEs:
            'Una rama muerta dentro de una planta sana, con lesión de borde '
            'definido, centro gris, puntos negros y corteza agrietada es '
            'compatible con cancro. BIO-G no confirma el organismo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalStemCanker,
          PlantHealthIds.signalRosePurpleBlackCaneLesion,
          PlantHealthIds.signalRoseGrayCenterBlackDots,
          PlantHealthIds.signalRoseCrackedFlakingBark,
          PlantHealthIds.signalRoseDeadBranchAmongHealthy,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseCaneUniformlyGreenInside,
          PlantHealthIds.signalRoseNormalOldWood,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_cold_injury_possible',
        labelEs: 'Daño por frío posible',
        type: 'abiotic_possible',
        summaryEs:
            'Una helada reciente, con tejido joven y varias puntas afectadas '
            'al mismo tiempo y sin borde de cancro definido al inicio, orienta '
            'a daño por frío.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalRoseCaneDiesFromTip,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseSunnyExposedSide,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_sunburn_cane_possible',
        labelEs: 'Quemadura de caña por calor o exposición posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un área negra o quemada en el lado sur u oeste, con defoliación '
            'previa o calor reflejado y lesión seca sin progresión húmeda, '
            'orienta a quemadura de caña.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseSunnyExposedSide,
          PlantHealthIds.signalRoseBleachedBlackenedCane,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_cane_borer_or_girdler_possible',
        labelEs: 'Barrenador o anillador de caña posible',
        type: 'arthropod_possible',
        summaryEs:
            'Un orificio con aserrín, hinchazón, canal interno y rama '
            'marchita por encima orienta a un barrenador o anillador.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseStemSwelling,
          PlantHealthIds.signalRoseBorerHoleFrass,
          PlantHealthIds.signalShootTipWilt,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseCaneUniformlyGreenInside,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_pruning_wound_recovery_possible',
        labelEs: 'Herida de poda en cicatrización posible',
        type: 'benign_differential',
        summaryEs:
            'Un corte reciente con borde firme y seco, que no crece, con '
            'tejido inferior verde y sin exudado, apunta a una herida de poda '
            'cicatrizando.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseRecentPruning,
          PlantHealthIds.signalRoseSpotsDoNotProgress,
          PlantHealthIds.signalRoseCaneUniformlyGreenInside,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRosePurpleBlackCaneLesion,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La rama está muerta por encima de una mancha o lesión?',
      '¿La lesión tiene borde morado, negro o marrón?',
      '¿Hay grietas o puntos negros?',
      '¿Hubo helada o poda reciente?',
      '¿El daño está solo en el lado de mayor sol?',
      '¿Hay un orificio, aserrín o hinchazón?',
      '¿La zona avanza entre revisiones?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Marca el límite de la lesión para comparar la progresión.',
      'Revisa el interior de una punta ya muerta solo si puede hacerse sin dañar tejido sano.',
      'Limpia las herramientas antes de usarlas en otro rosal.',
      'Evita heridas adicionales.',
      'Busca evaluación si la lesión llega a la base.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsCoolDewyWindow: true,
    favorsRecentStress: true,
  ),
  // S07 — Decaimiento de raíz o cuello.
  PlantHealthSyndrome(
    id: 'rose_root_crown_decline_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Marchitez o decaimiento con raíz o cuello por confirmar',
    stages: _roseRootStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalRoseCrownBrownOrSoft,
      PlantHealthIds.signalRoseFewFeederRoots,
      PlantHealthIds.signalRoseWiltsWhileSoilWet,
      PlantHealthIds.signalRoseLossOfSupport,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalVascularBrowning,
      PlantHealthIds.signalOneSidedWilt,
      PlantHealthIds.signalRoseRecentTransplant,
      PlantHealthIds.signalRoseFungusGnats,
      PlantHealthIds.signalRoseSourAbnormalOdor,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseRootsFirmWhiteTips,
      PlantHealthIds.signalRoseSoilDryDuringWilt,
      PlantHealthIds.signalRosePlantRecoversAfterIrrigation,
      PlantHealthIds.signalRoseCrownFirmNormal,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_phytophthora_root_crown_rot_compatible',
        labelEs: 'Condición compatible con deterioro de raíz o corona por humedad',
        scientificName: 'Phytophthora spp.',
        type: 'condition_compatible',
        summaryEs:
            'Marchitez con suelo húmedo, pocas raíces finas y tejido de corona '
            'alterado es compatible con un deterioro serio de raíz. Solo una '
            'revisión física o de laboratorio puede confirmar la causa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalRoseCrownBrownOrSoft,
          PlantHealthIds.signalRoseWiltsWhileSoilWet,
          PlantHealthIds.signalRoseDeclineProgressing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseRootsFirmWhiteTips,
          PlantHealthIds.signalRoseSoilDryDuringWilt,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_other_root_rot_possible',
        labelEs: 'Otra pudrición de raíz posible',
        type: 'condition_compatible',
        summaryEs:
            'Otros organismos de raíz pueden producir un cuadro parecido; '
            'raíces oscuras y frágiles con pocas raíces finas requieren '
            'revisión física.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalRoseFewFeederRoots,
          PlantHealthIds.signalRoseWiltsWhileSoilWet,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseRootsFirmWhiteTips,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_waterlogging_root_asphyxia_possible',
        labelEs: 'Asfixia radicular por exceso de agua posible',
        type: 'abiotic_possible',
        summaryEs:
            'Suelo saturado o drenaje bloqueado, sin lesión definida de raíz y '
            'con mejora al recuperar oxígeno, orienta a asfixia radicular.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalRosePlantRecoversAfterIrrigation,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalRoseSourAbnormalOdor,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_transplant_stress_possible',
        labelEs: 'Estrés de establecimiento posible',
        type: 'visual_concern',
        summaryEs:
            'Una plantación reciente con raíz firme, pérdida moderada de hojas '
            'y sin olor ni avance, con brotes vivos, orienta a estrés de '
            'establecimiento.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseRecentTransplant,
          PlantHealthIds.signalRoseRootsFirmWhiteTips,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseDeclineProgressing,
          PlantHealthIds.signalRoseSourAbnormalOdor,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_vascular_or_cane_problem_possible',
        labelEs: 'Problema vascular o de caña posible',
        type: 'condition_compatible',
        summaryEs:
            'Un solo lado afectado, estrías internas y suelo que no está '
            'mojado, con lesión de caña y punta que muere primero, orienta a '
            'un problema vascular o de caña.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalOneSidedWilt,
          PlantHealthIds.signalVascularBrowning,
          PlantHealthIds.signalRoseSoilDryDuringWilt,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El suelo sigue mojado cuando la planta se marchita?',
      '¿La corona está firme o blanda?',
      '¿Las raíces finas son claras y firmes u oscuras y frágiles?',
      '¿Hay olor anormal?',
      '¿La planta se mueve porque perdió anclaje?',
      '¿Afecta a toda la planta o a una sola rama?',
      '¿Fue plantada recientemente?',
      '¿La situación avanza?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Suspende los riegos repetidos mientras el suelo siga húmedo.',
      'Revisa la salida del agua y la profundidad de plantación.',
      'No declares una pudrición sin observar la raíz o la corona.',
      'Separa las macetas con deterioro progresivo.',
      'Busca evaluación local si la corona cambia de firmeza.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  // S08 — Agalla en cuello, raíz o tallo bajo.
  PlantHealthSyndrome(
    id: 'rose_crown_root_gall_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Bulto o agalla en la base, raíz o tallo',
    stages: _roseAllStages,
    organIds: <String>{
      PlantHealthIds.organCrown,
      PlantHealthIds.organStem,
      PlantHealthIds.organRoot,
    },
    primarySymptomId: PlantHealthIds.symptomRootGalls,
    strongSignals: <String>{
      PlantHealthIds.signalRootGalls,
      PlantHealthIds.signalGallsOnWoodRoots,
      PlantHealthIds.signalRoseRoughIrregularGall,
      PlantHealthIds.signalRoseGallAtSoilLine,
      PlantHealthIds.signalRoseGallHardensDarkens,
      PlantHealthIds.signalRoseStuntedAboveGall,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalRoseWoundNearGall,
      PlantHealthIds.signalRosePurchasedWithSwelling,
      PlantHealthIds.signalRoseMultipleGalls,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseSmoothRegularGraftUnion,
      PlantHealthIds.signalRoseSoftTemporaryCallus,
      PlantHealthIds.signalRoseGallInsectExitHole,
      PlantHealthIds.signalRoseNormalRootFlare,
      PlantHealthIds.signalRoseStableOldSwelling,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_crown_gall_compatible',
        labelEs: 'Condición compatible con agalla de la corona',
        scientificName: 'Rhizobium radiobacter',
        type: 'condition_compatible',
        summaryEs:
            'Una masa irregular y rugosa en la base o raíz que crece, oscurece '
            'y frena a la planta, aparecida tras una herida, es compatible con '
            'agalla de la corona. BIO-G no confirma el organismo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseRoughIrregularGall,
          PlantHealthIds.signalRoseGallAtSoilLine,
          PlantHealthIds.signalRoseGallHardensDarkens,
          PlantHealthIds.signalRoseStuntedAboveGall,
          PlantHealthIds.signalRoseWoundNearGall,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseSmoothRegularGraftUnion,
          PlantHealthIds.signalRoseNormalRootFlare,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_normal_graft_union_possible',
        labelEs: 'Unión de injerto normal posible',
        type: 'benign_differential',
        summaryEs:
            'Un bulto regular en la ubicación típica del injerto, estable y de '
            'superficie organizada, en una planta injertada, orienta a una '
            'unión de injerto normal.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseSmoothRegularGraftUnion,
          PlantHealthIds.signalRoseStableOldSwelling,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseGallHardensDarkens,
          PlantHealthIds.signalRoseStuntedAboveGall,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_callus_wound_possible',
        labelEs: 'Callo de herida posible',
        type: 'benign_differential',
        summaryEs:
            'Un crecimiento localizado, firme y estable sobre una herida '
            'conocida, sin más agallas, orienta a un callo de cicatrización.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseWoundNearGall,
          PlantHealthIds.signalRoseSoftTemporaryCallus,
          PlantHealthIds.signalRoseStableOldSwelling,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseGallHardensDarkens,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_insect_gall_possible',
        labelEs: 'Agalla causada por insecto posible',
        type: 'arthropod_possible',
        summaryEs:
            'Una estructura en tallo u hoja, no en la corona, con orificio o '
            'larva y daño principalmente cosmético, orienta a una agalla de '
            'insecto.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseGallInsectExitHole,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseGallAtSoilLine,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Está en la línea del suelo?',
      '¿La superficie es rugosa e irregular?',
      '¿Crece entre revisiones?',
      '¿El rosal es injertado?',
      '¿El bulto es liso y simétrico?',
      '¿Hay una herida o un orificio?',
      '¿La planta se está frenando?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'No cortes la agalla antes de identificar su ubicación.',
      'Evita usar la misma herramienta en otros rosales sin limpiarla.',
      'Fotografía el tamaño y la forma con una referencia.',
      'Busca evaluación local para distinguir agalla, injerto y callo.',
      'No propagues material de una planta sospechosa.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsRecentStress: true,
  ),
  // S09 — Roseta, escoba de bruja o aguijones excesivos.
  PlantHealthSyndrome(
    id: 'rose_rosette_excess_prickles_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Brote en roseta, crecimiento deforme o demasiados aguijones',
    stages: _roseLeafActiveStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRoseRosetteExcessPrickles,
    strongSignals: <String>{
      PlantHealthIds.signalRoseWitchesBroom,
      PlantHealthIds.signalRoseExcessPrickles,
      PlantHealthIds.signalRoseThickenedCane,
      PlantHealthIds.signalRosePersistentRedYellowDistortion,
      PlantHealthIds.signalRoseDeformedLeavesFlowers,
      PlantHealthIds.signalRoseProgressesToOtherBranches,
    },
    weakSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalRoseNearOtherSymptomaticRoses,
      PlantHealthIds.signalRoseBranchDieback,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseNormalRedGrowthTurnsGreen,
      PlantHealthIds.signalRoseNormalPrickleDensity,
      PlantHealthIds.signalRoseHealthyBasalBreak,
      PlantHealthIds.signalRoseHerbicideAffectsOtherPlants,
      PlantHealthIds.signalRoseGrowthNormalizes,
      PlantHealthIds.signalRoseNormalFullSizedLeaves,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_rosette_disease_suspicion',
        labelEs: 'Patrón que requiere descartar enfermedad de la roseta',
        scientificName: 'Rose rosette virus',
        type: 'high_consequence_suspicion',
        summaryEs:
            'Hay varias señales que requieren descartar una alteración seria '
            'del crecimiento cuando coinciden escoba de bruja, aguijones muy '
            'numerosos, caña engrosada, color anormal persistente, hojas y '
            'flores deformes y progresión. BIO-G no afirma que el rosal tenga '
            'roseta; el patrón necesita evaluación externa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseWitchesBroom,
          PlantHealthIds.signalRoseExcessPrickles,
          PlantHealthIds.signalRoseThickenedCane,
          PlantHealthIds.signalRosePersistentRedYellowDistortion,
          PlantHealthIds.signalRoseDeformedLeavesFlowers,
          PlantHealthIds.signalRoseProgressesToOtherBranches,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseNormalRedGrowthTurnsGreen,
          PlantHealthIds.signalRoseNormalPrickleDensity,
          PlantHealthIds.signalRoseHealthyBasalBreak,
          PlantHealthIds.signalRoseHerbicideAffectsOtherPlants,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_herbicide_injury_possible',
        labelEs: 'Daño por herbicida posible',
        type: 'abiotic_possible',
        summaryEs:
            'Hojas angostas o en cuchara, brotes pequeños y otras especies '
            'cercanas afectadas tras una aplicación o deriva, sin aguijones '
            'excesivos ni engrosamiento típico, orientan a daño por herbicida.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseHerbicideAffectsOtherPlants,
          PlantHealthIds.signalRoseNarrowLeavesCupping,
          PlantHealthIds.signalRoseRecentSpray,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseExcessPrickles,
          PlantHealthIds.signalRoseThickenedCane,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_normal_red_new_growth_possible',
        labelEs: 'Brote rojo normal posible',
        type: 'benign_differential',
        summaryEs:
            'Un brote que empieza rojo y madura a verde, con hojas de tamaño '
            'normal, estructura ordenada, aguijones habituales y flores '
            'normales, apunta a crecimiento nuevo normal.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseNormalRedGrowthTurnsGreen,
          PlantHealthIds.signalRoseNormalPrickleDensity,
          PlantHealthIds.signalRoseNormalFullSizedLeaves,
          PlantHealthIds.signalRoseGrowthNormalizes,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseWitchesBroom,
          PlantHealthIds.signalRoseExcessPrickles,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_healthy_basal_break_possible',
        labelEs: 'Brote basal vigoroso normal posible',
        type: 'benign_differential',
        summaryEs:
            'Una sola caña fuerte desde la base, con hojas normales, estructura '
            'simple (no escoba), color que madura y sin deformación de flor, '
            'apunta a un brote basal sano.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseHealthyBasalBreak,
          PlantHealthIds.signalRoseNormalFullSizedLeaves,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseWitchesBroom,
          PlantHealthIds.signalRoseDeformedLeavesFlowers,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_pruning_or_nutrition_flush_possible',
        labelEs: 'Brotación intensa por poda o nutrición posible',
        type: 'visual_concern',
        summaryEs:
            'Una poda reciente o mucho nitrógeno pueden dar brotes blandos '
            'pero ordenados, sin aguijones anormales y que se normalizan.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseRecentPruning,
          PlantHealthIds.signalRoseGrowthNormalizes,
          PlantHealthIds.signalRoseNormalPrickleDensity,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseExcessPrickles,
          PlantHealthIds.signalRoseThickenedCane,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Salen muchos brotes pequeños desde un mismo punto, como una escoba?',
      '¿Hay muchísimos más aguijones que en las ramas sanas de la misma planta?',
      '¿La caña nueva es más gruesa y blanda que la caña vieja?',
      '¿El color rojo o amarillo anormal permanece en lugar de madurar a verde?',
      '¿Las hojas y las flores salen pequeñas y deformes?',
      '¿El patrón avanza a otras ramas entre revisiones?',
      '¿Coinciden varias de estas señales a la vez, o solo una?',
      '¿Hubo herbicida cerca o hay otras especies deformes?',
      '¿Es solo brote rojo, una sola caña vigorosa o solo muchos aguijones? Por sí solos no bastan.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Separa temporalmente el rosal de otros si está en maceta.',
      'No podes otros rosales con la misma herramienta sin limpiarla.',
      'Evita mover material de la planta.',
      'Toma fotografías de la planta completa, los brotes, los aguijones y las flores.',
      'Compara con el crecimiento sano de la misma planta.',
      'Busca diagnóstico de una extensión, laboratorio o autoridad fitosanitaria.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),
  // S10 — Líneas, anillos o mosaico amarillo.
  PlantHealthSyndrome(
    id: 'rose_mosaic_pattern_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Líneas, anillos o mosaico amarillo en las hojas',
    stages: _roseLeafActiveStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalRoseYellowWavyLines,
      PlantHealthIds.signalRoseYellowRingsZigzags,
      PlantHealthIds.signalRoseVeinClearing,
      PlantHealthIds.signalRosePatternRepeatsNewLeaves,
      PlantHealthIds.signalRoseSymptomsCoolWeather,
      PlantHealthIds.signalRoseLeafLeatheryWrinkled,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalRoseStunting,
      PlantHealthIds.signalRoseKnownGraftedStock,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseInterveinalChlorosisNoPattern,
      PlantHealthIds.signalRoseUniformOldLeafYellowing,
      PlantHealthIds.signalRoseRecentSpray,
      PlantHealthIds.signalMitesWebbing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_mosaic_virus_complex_possible',
        labelEs: 'Patrón compatible con mosaico viral por confirmar',
        scientificName: 'Prunus necrotic ringspot virus, Apple mosaic virus',
        type: 'condition_compatible',
        summaryEs:
            'Líneas onduladas, anillos o zigzags amarillos estables, más '
            'visibles en clima fresco y en material injertado, son compatibles '
            'con un mosaico viral. La confirmación requiere prueba de virus.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseYellowWavyLines,
          PlantHealthIds.signalRoseYellowRingsZigzags,
          PlantHealthIds.signalRosePatternRepeatsNewLeaves,
          PlantHealthIds.signalRoseSymptomsCoolWeather,
          PlantHealthIds.signalRoseKnownGraftedStock,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseInterveinalChlorosisNoPattern,
          PlantHealthIds.signalRoseUniformOldLeafYellowing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_nutrient_chlorosis_differential',
        labelEs: 'Clorosis por nutrición o pH posible',
        type: 'nutrient_context',
        summaryEs:
            'Un amarillo solo entre las venas, simétrico y sin anillos, con pH '
            'alto, orienta a una clorosis nutricional más que a un virus.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseInterveinalChlorosisNoPattern,
          PlantHealthIds.signalRoseHighPhContext,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseYellowRingsZigzags,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_herbicide_or_spray_pattern_possible',
        labelEs: 'Daño químico posible',
        type: 'abiotic_possible',
        summaryEs:
            'Una aparición súbita tras una aplicación, con varias especies '
            'afectadas y hojas nuevas deformes, y un patrón que no se repite '
            'después, orienta a daño químico.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseRecentSpray,
          PlantHealthIds.signalRoseHerbicideAffectsOtherPlants,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRosePatternRepeatsNewLeaves,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Son líneas onduladas, anillos o zigzags?',
      '¿El patrón se repite en las hojas nuevas?',
      '¿Es más visible con clima fresco?',
      '¿La hoja está arrugada o coriácea?',
      '¿El amarillo está solo entre las venas?',
      '¿Hubo aspersión o herbicida?',
      '¿Otras plantas también están afectadas?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Fotografía el patrón con luz uniforme.',
      'Compara hojas jóvenes y maduras.',
      'No uses el patrón para declarar una deficiencia.',
      'Evita propagar una planta con patrón persistente.',
      'Busca confirmación si el vigor disminuye.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsRecentStress: true,
  ),
  // S11 — Clorosis y crecimiento débil.
  PlantHealthSyndrome(
    id: 'rose_chlorosis_weak_growth_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Hojas pálidas o amarillas y crecimiento débil',
    stages: _roseLeafActiveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRoseChlorosisWeakGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalRoseInterveinalChlorosisNewLeaves,
      PlantHealthIds.signalRoseUniformYellowOldLeaves,
      PlantHealthIds.signalRoseShortWeakShoots,
      PlantHealthIds.signalRoseHighPhContext,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalWaterlogging,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalRoseLowNReadingRepeated,
      PlantHealthIds.signalRoseRootDeclineSigns,
      PlantHealthIds.signalRoseSandyCalcareousSoil,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseYellowRingsZigzags,
      PlantHealthIds.signalRoseFeatheryBlackMargin,
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalRoseNormalSeasonalAging,
      PlantHealthIds.signalRoseOnlyOneCaneAffected,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_iron_zinc_unavailability_possible',
        labelEs: 'Hierro o zinc poco disponibles por confirmar',
        type: 'nutrient_context',
        summaryEs:
            'Hojas jóvenes amarillas entre venas, con venas verdes, en suelo de '
            'pH alto o calcáreo, orientan a hierro o zinc poco disponibles. No '
            'confirma una deficiencia foliar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseInterveinalChlorosisNewLeaves,
          PlantHealthIds.signalRoseHighPhContext,
          PlantHealthIds.signalRoseSandyCalcareousSoil,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseUniformYellowOldLeaves,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_nitrogen_shortage_possible',
        labelEs: 'Nitrógeno bajo como posibilidad',
        type: 'nutrient_context',
        summaryEs:
            'Hojas viejas uniformemente amarillas que caen desde abajo, con '
            'brotes cortos, EC no alta y raíz sana, orientan a nitrógeno bajo. '
            'Una sola lectura no confirma una deficiencia.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseUniformYellowOldLeaves,
          PlantHealthIds.signalRoseShortWeakShoots,
          PlantHealthIds.signalRoseLowNReadingRepeated,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSalinityLoad,
          PlantHealthIds.signalRoseInterveinalChlorosisNewLeaves,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_root_dysfunction_possible',
        labelEs: 'Raíz limitada o dañada posible',
        type: 'condition_compatible',
        summaryEs:
            'Suelo mojado o compactado, marchitez y corona o raíces alteradas '
            'que no responden a la fertilización, orientan a una raíz limitada '
            'o dañada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalRoseRootDeclineSigns,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseNormalSeasonalAging,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_salinity_stress_possible',
        labelEs: 'Estrés por sales posible',
        type: 'abiotic_possible',
        summaryEs:
            'EC alta, borde quemado, raíces marrones desde las puntas y '
            'fertilización reciente orientan a un estrés por sales.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSalinityLoad,
          PlantHealthIds.signalLeafEdgeBurn,
          PlantHealthIds.signalRoseRecentFertilizer,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseNormalSeasonalAging,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_normal_old_leaf_senescence_possible',
        labelEs: 'Envejecimiento normal de hojas viejas posible',
        type: 'benign_differential',
        summaryEs:
            'Pocas hojas internas amarillas sin progresión, con brotes nuevos '
            'sanos y patrón uniforme en post-floración o reposo, apuntan a un '
            'envejecimiento normal.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseNormalSeasonalAging,
          PlantHealthIds.signalRoseUniformOldLeafYellowing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseInterveinalChlorosisNewLeaves,
          PlantHealthIds.signalRoseShortWeakShoots,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Son hojas nuevas o viejas las afectadas?',
      '¿Las venas permanecen verdes?',
      '¿Hay manchas negras?',
      '¿El borde está quemado?',
      '¿El suelo está mojado?',
      '¿El pH está alto?',
      '¿La EC está alta?',
      '¿El crecimiento nuevo es sano?',
      '¿La lectura de NPK se repite?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'No corrijas un nutriente por una sola lectura.',
      'Revisa primero el pH, la EC, la humedad y la raíz.',
      'Compara hojas jóvenes y viejas.',
      'Confirma con un análisis si el patrón persiste.',
      'Evita acumular fertilizante mientras la causa no esté clara.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  // S12 — Bordes secos o tejido quemado.
  PlantHealthSyndrome(
    id: 'rose_scorch_edge_burn_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Bordes secos, tejido quemado o daño por exposición',
    stages: _roseLeafActiveStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalLeafEdgeBurn,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalRoseSunnySideDamage,
      PlantHealthIds.signalRoseRecentSpray,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalRoseRecentFertilizer,
      PlantHealthIds.signalRoseSoilDry,
      PlantHealthIds.signalRoseReflectedHeat,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalRoseFeatheryBlackMargin,
      PlantHealthIds.signalRoseOrangePowderUnderLeaf,
      PlantHealthIds.signalRoseDamageProgressesHumidCool,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_drought_heat_scorch_possible',
        labelEs: 'Quemadura por calor o sequedad posible',
        type: 'abiotic_possible',
        summaryEs:
            'Calor, suelo seco, daño del lado soleado y borde seco simultáneo '
            'orientan a una quemadura por calor o sequedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHeatStress,
          PlantHealthIds.signalRoseSoilDry,
          PlantHealthIds.signalRoseSunnySideDamage,
          PlantHealthIds.signalLeafEdgeBurn,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_salt_fertilizer_burn_possible',
        labelEs: 'Quemadura por sales o fertilización posible',
        type: 'abiotic_possible',
        summaryEs:
            'EC alta, fertilizante reciente, costra blanca y borde seco, '
            'especialmente en maceta, orientan a una quemadura por sales.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSalinityLoad,
          PlantHealthIds.signalRoseRecentFertilizer,
          PlantHealthIds.signalLeafEdgeBurn,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseDamageProgressesHumidCool,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_spray_phytotoxicity_possible',
        labelEs: 'Daño por aspersión posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un patrón de gotas tras un producto reciente en el lado tratado, '
            'de aparición súbita y sin progresión infecciosa, orienta a '
            'fitotoxicidad por aspersión.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseRecentSpray,
          PlantHealthIds.signalRoseDropletPattern,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseDamageProgressesHumidCool,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_cane_sunburn_possible',
        labelEs: 'Quemadura solar de caña posible',
        type: 'abiotic_possible',
        summaryEs:
            'Una caña negra en el lado expuesto, con defoliación previa o una '
            'pared o piedra que refleja calor y lesión seca, orienta a '
            'quemadura solar de caña.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseSunnySideDamage,
          PlantHealthIds.signalRoseBleachedBlackenedCane,
          PlantHealthIds.signalRoseReflectedHeat,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseDamageProgressesHumidCool,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_cold_burn_possible',
        labelEs: 'Daño por frío posible',
        type: 'abiotic_possible',
        summaryEs:
            'Una helada con tejido joven ennegrecido en muchas puntas, no '
            'limitado al lado soleado, orienta a un daño por frío.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseSunnySideDamage,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El daño está en el borde de la hoja?',
      '¿Afecta el lado de mayor sol?',
      '¿Hubo calor o helada?',
      '¿El suelo estaba seco?',
      '¿La EC está alta?',
      '¿Fertilizaste o asperjaste algo?',
      '¿Tiene patrón de gotas?',
      '¿El tejido está seco o húmedo?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Corrige primero el evento ambiental evidente.',
      'No agregues fertilizante con EC alta.',
      'Registra el lado de exposición.',
      'Evita nuevas aspersiones hasta identificar el patrón.',
      'Busca revisión si la caña se hunde o el daño avanza.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsRecentStress: true,
  ),
  // S13 — Colonias, melaza y brotes enrollados.
  PlantHealthSyndrome(
    id: 'rose_aphid_honeydew_distortion_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Insectos en brotes, hojas pegajosas o crecimiento enrollado',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
    },
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organStem},
    primarySymptomId: PlantHealthIds.symptomAphidColonies,
    strongSignals: <String>{
      PlantHealthIds.signalRoseSoftBodiedColonies,
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
      PlantHealthIds.signalLeafRolling,
      PlantHealthIds.signalRoseInsectsTenderShoots,
      PlantHealthIds.signalRoseAntActivity,
    },
    weakSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalRoseBudDistortion,
      PlantHealthIds.signalRoseCastSkins,
      PlantHealthIds.signalRoseBeneficialPredators,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseFixedScaleBodies,
      PlantHealthIds.signalRoseFineWebbing,
      PlantHealthIds.signalRosePetalScratchesFlecks,
      PlantHealthIds.signalRoseCleanSemicircleCut,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_aphids_possible',
        labelEs: 'Pulgones posibles',
        scientificName: 'Macrosiphum rosae',
        type: 'arthropod_possible',
        summaryEs:
            'Insectos blandos en colonias sobre los brotes tiernos, con melaza, '
            'hojas enrolladas y mudas blancas, orientan a pulgones.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseSoftBodiedColonies,
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalLeafRolling,
          PlantHealthIds.signalRoseInsectsTenderShoots,
          PlantHealthIds.signalRoseCastSkins,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseFixedScaleBodies,
          PlantHealthIds.signalRoseFineWebbing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_scale_or_whitefly_differential',
        labelEs: 'Escamas, mosca blanca u otro chupador posible',
        type: 'arthropod_possible',
        summaryEs:
            'Cuerpos fijos, escudos, algodón o una nube de insectos, con una '
            'distribución distinta, orientan a escamas, mosca blanca u otro '
            'chupador.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseFixedScaleBodies,
          PlantHealthIds.signalRoseCottonyWax,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseSoftBodiedColonies,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_normal_beneficial_insects_present',
        labelEs: 'Insectos benéficos presentes',
        type: 'benign_differential',
        summaryEs:
            'Catarinas, larvas de sírfidos, crisopas o momias de pulgón, con '
            'pocos pulgones y planta sin daño, apuntan a insectos benéficos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseBeneficialPredators,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseSoftBodiedColonies,
          PlantHealthIds.signalStickyHoneydew,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay colonias en las puntas de los brotes?',
      '¿Los insectos son blandos?',
      '¿La hoja está pegajosa?',
      '¿Hay tizne negro (fumagina)?',
      '¿Hay hormigas subiendo?',
      '¿Ves catarinas o larvas benéficas?',
      '¿El daño está aumentando?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Revisa si hay depredadores naturales.',
      'Evita un tratamiento general sin confirmar la población.',
      'Compara varias puntas de brote.',
      'En infestación localizada, separa la maceta mientras observas.',
      'Busca orientación local si el brote deja de crecer.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsVectorPressure: true,
  ),
  // S14 — Punteado, bronceado o telaraña.
  PlantHealthSyndrome(
    id: 'rose_stippling_bronzing_webbing_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Punteado fino, bronceado o telaraña en hojas',
    stages: _roseLeafActiveStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalRoseFineStippling,
      PlantHealthIds.signalRoseMitesUnderLeaf,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRoseDamageHotWeather,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalRoseLeafGrayOffGreen,
      PlantHealthIds.signalRoseDustyCrowdedSite,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseFeatheryBlackMargin,
      PlantHealthIds.signalRoseOrangePowderUnderLeaf,
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalRoseLargeSilverScarsThrips,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_spider_mites_possible',
        labelEs: 'Ácaros posibles',
        scientificName: 'Tetranychus urticae',
        type: 'arthropod_possible',
        summaryEs:
            'Puntos finos en el envés, bronceado, calor seco, telaraña fina y '
            'organismos diminutos orientan a ácaros.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseFineStippling,
          PlantHealthIds.signalRoseMitesUnderLeaf,
          PlantHealthIds.signalMitesWebbing,
          PlantHealthIds.signalBronzedLeafSurface,
          PlantHealthIds.signalDryHotWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseLargeSilverScarsThrips,
          PlantHealthIds.signalWhitePowderGrowth,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_thrips_or_leafhopper_differential',
        labelEs: 'Trips o saltahojas como diferencial',
        type: 'arthropod_possible',
        summaryEs:
            'Un raspado más grande, color plateado, insectos que saltan y daño '
            'en pétalos con poca telaraña orientan a trips o saltahojas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseLargeSilverScarsThrips,
          PlantHealthIds.signalThripsPresent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_dust_or_spray_residue_possible',
        labelEs: 'Polvo o residuo posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un material que se limpia, sin lesión ni progresión y por '
            'exposición ambiental, orienta a polvo o residuo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseDustyCrowdedSite,
          PlantHealthIds.signalRoseSpotsDoNotProgress,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
          PlantHealthIds.signalRoseFineStippling,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Los puntos son muy finos?',
      '¿La hoja se ve gris o bronce?',
      '¿Hay telaraña fina?',
      '¿Ves puntos móviles debajo de la hoja?',
      '¿Ha hecho calor y ambiente seco?',
      '¿También hay daño en los pétalos?',
      '¿El material se limpia sin dejar lesión?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Revisa el envés con lupa.',
      'Evita tratamientos de amplio espectro antes de confirmar.',
      'Observa la presencia de depredadores.',
      'Reduce el polvo y el estrés hídrico sin mojar las flores por periodos prolongados.',
      'Busca identificación si la población aumenta.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsRecentStress: true,
    favorsVectorPressure: true,
  ),
  // S15 — Hojas con ventanas, encaje o agujeros.
  PlantHealthSyndrome(
    id: 'rose_chewing_windowpane_holes_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Hojas con ventanas, encaje, esqueletización o agujeros',
    stages: _roseLeafActiveStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalRoseWindowpaneDamage,
      PlantHealthIds.signalRoseSkeletonizedLeaf,
      PlantHealthIds.signalRoseLarvaeUnderLeaf,
      PlantHealthIds.signalRoseBeetlesOnFlower,
    },
    weakSignals: <String>{
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalRoseCleanSemicircleCut,
      PlantHealthIds.signalRosePetalsEaten,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNoBiteMarks,
      PlantHealthIds.signalRoseLeafCenterFallsFromSpot,
      PlantHealthIds.signalLeafMines,
      PlantHealthIds.signalRoseUniformEdgeScorch,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_sawfly_slug_possible',
        labelEs: 'Larva de mosca sierra o "babosa del rosal" posible',
        type: 'arthropod_possible',
        summaryEs:
            'Una ventana transparente, daño de encaje y una larva verde debajo '
            'de la hoja, que no es una babosa real ni una oruga de mariposa, '
            'orientan a larva de mosca sierra.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseWindowpaneDamage,
          PlantHealthIds.signalRoseSkeletonizedLeaf,
          PlantHealthIds.signalRoseLarvaeUnderLeaf,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseCleanSemicircleCut,
          PlantHealthIds.signalNoBiteMarks,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_beetle_or_chewer_possible',
        labelEs: 'Escarabajo u otro masticador posible',
        type: 'arthropod_possible',
        summaryEs:
            'Agujeros irregulares, flor comida, escarabajos visibles y varios '
            'individuos orientan a escarabajos u otros masticadores.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalFeedingHoles,
          PlantHealthIds.signalActiveChewing,
          PlantHealthIds.signalRoseBeetlesOnFlower,
          PlantHealthIds.signalRosePetalsEaten,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNoBiteMarks,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_leafcutter_bee_benign',
        labelEs: 'Corte de abeja cortadora posible',
        type: 'benign_differential',
        summaryEs:
            'Los cortes redondos o semicirculares casi perfectos en el borde '
            'de la hoja, en pocos números y en una planta sana, suelen ser '
            'cosméticos y no justifican una alerta fuerte.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseCleanSemicircleCut,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseLarvaeUnderLeaf,
          PlantHealthIds.signalRoseSkeletonizedLeaf,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_leaf_spot_shot_hole_possible',
        labelEs: 'Centro de mancha que se desprendió posible',
        type: 'benign_differential',
        summaryEs:
            'Un borde de lesión, manchas previas al agujero, centro gris y '
            'varias lesiones redondas, sin mordida, orientan a un centro de '
            'mancha que se desprendió y no a una plaga masticadora.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseLeafCenterFallsFromSpot,
          PlantHealthIds.signalNoBiteMarks,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseLarvaeUnderLeaf,
          PlantHealthIds.signalActiveChewing,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Parece que falta solo una capa de la hoja (ventana)?',
      '¿Se ve como encaje o esqueletizada?',
      '¿Hay larvas debajo de la hoja?',
      '¿El agujero es un semicírculo o círculo casi perfecto?',
      '¿Hay escarabajos?',
      '¿Había una mancha antes del agujero?',
      '¿El daño sigue apareciendo?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Revisa debajo de la hoja.',
      'Distingue el daño activo del daño antiguo.',
      'No generes una alerta fuerte por cortes redondos aislados.',
      'Registra el porcentaje visual aproximado sin exigir conteos exactos.',
      'Busca identificación si hay defoliación rápida.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsVectorPressure: true,
  ),
  // S16 — Escamas, algodón, melaza o tizne.
  PlantHealthSyndrome(
    id: 'rose_scale_cotton_sooty_01',
    cropId: CropCatalog.roseCropId,
    labelEs: 'Bultos fijos, algodón o costra con melaza y tizne',
    stages: _roseAllStages,
    organIds: <String>{PlantHealthIds.organStem, PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomRoseScaleCottonSooty,
    strongSignals: <String>{
      PlantHealthIds.signalRoseFixedScaleBodies,
      PlantHealthIds.signalRoseCottonyWax,
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
      PlantHealthIds.signalRoseInsectsNodes,
      PlantHealthIds.signalRoseAntActivity,
    },
    weakSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalRoseWeakShoots,
      PlantHealthIds.signalRoseLeafYellowing,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalRoseSoftBodiedColonies,
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalRoseNormalCaneLenticels,
      PlantHealthIds.signalRoseNoHoneydew,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rose_scale_insects_possible',
        labelEs: 'Escamas o cochinillas posibles',
        type: 'arthropod_possible',
        summaryEs:
            'Cuerpos fijos, escudos o costras en tallo o envés, con melaza en '
            'especies blandas y tizne secundario, orientan a escamas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseFixedScaleBodies,
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalSootyMold,
          PlantHealthIds.signalRoseInsectsNodes,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseSoftBodiedColonies,
          PlantHealthIds.signalRoseNormalCaneLenticels,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_mealybug_possible',
        labelEs: 'Cochinilla algodonosa posible',
        type: 'arthropod_possible',
        summaryEs:
            'Material como algodón o cera en los nodos, de movimiento lento y '
            'con melaza, orienta a una cochinilla algodonosa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseCottonyWax,
          PlantHealthIds.signalRoseInsectsNodes,
          PlantHealthIds.signalStickyHoneydew,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseFixedScaleBodies,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_aphid_honeydew_differential',
        labelEs: 'Melaza de pulgón posible',
        type: 'arthropod_possible',
        summaryEs:
            'Colonias blandas en brotes jóvenes con mudas y sin escudos '
            'orientan a melaza de pulgón más que a escamas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRoseSoftBodiedColonies,
          PlantHealthIds.signalStickyHoneydew,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseFixedScaleBodies,
          PlantHealthIds.signalRoseCottonyWax,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rose_sooty_mold_secondary',
        labelEs: 'Tizne superficial secundario posible',
        type: 'condition_compatible',
        summaryEs:
            'Una capa negra superficial sobre melaza, que se limpia '
            'parcialmente y acompaña a insectos chupadores, orienta a un tizne '
            'secundario.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSootyMold,
          PlantHealthIds.signalStickyHoneydew,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalRoseNoHoneydew,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Los bultos están pegados y no caminan?',
      '¿Hay material parecido a algodón?',
      '¿La hoja está pegajosa?',
      '¿Hay una capa negra superficial?',
      '¿Hay hormigas?',
      '¿El blanco parece polvo de hongo o cera de insecto?',
      '¿Se concentra en los nodos y tallos?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Revisa con lupa.',
      'Distingue los cuerpos fijos del polvillo.',
      'Observa si existe melaza.',
      'Evita mover la maceta junto a otras hasta confirmar.',
      'Busca identificación antes de aplicar un tratamiento.',
    ],
    disclaimerEs: _roseDisclaimer,
    favorsVectorPressure: true,
  ),
];
