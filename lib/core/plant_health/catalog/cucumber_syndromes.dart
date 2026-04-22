import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

const Set<PlantHealthStageBucket> _cucumberFullCycleStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    };

const Set<PlantHealthStageBucket> _cucumberEarlyStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
    };

const Set<PlantHealthStageBucket> _cucumberFoliarStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    };

const Set<PlantHealthStageBucket> _cucumberProductiveStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    };

const Set<PlantHealthStageBucket> _cucumberFlowerFruitStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    };

const Set<String> _cucumberFieldVarieties = <String>{
  'cucumber_slicer_ca',
  'cucumber_pickler',
};

const Set<String> _cucumberProtectedVarieties = <String>{
  'cucumber_european_protected',
  'cucumber_persian',
};

const Set<String> _cucumberParthenocarpicProtectedVarieties = <String>{
  'cucumber_european_protected',
  'cucumber_persian',
};

/// Catálogo sanitario base de pepino para BIO-G v1.
///
/// Criterio de modelado:
/// - Campo abierto e invernadero en suelo.
/// - Sin hidroponía ni sustratos inertes.
/// - Se priorizan cuadros que sí pueden entrar con la taxonomía actual del
///   wizard (órgano -> síntoma principal -> señales secundarias).
const List<PlantHealthSyndrome> cucumberSyndromes = <PlantHealthSyndrome>[
  PlantHealthSyndrome(
    id: 'cucumber_downy_mildew_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs:
        'Manchas angulares con envés activo – riesgo de mildiu velloso',
    stages: _cucumberFoliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAngularSpots,
    strongSignals: <String>{
      PlantHealthIds.signalAngularLesionPattern,
      PlantHealthIds.signalUndersideSporulation,
      PlantHealthIds.signalRapidFoliarCollapse,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalWaterSoakedMargin,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalSporesRubOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pseudoperonospora_cubensis',
        labelEs: 'Mildiu velloso del pepino',
        scientificName: 'Pseudoperonospora cubensis',
        type: 'oomycete',
        summaryEs:
            'Cuadro explosivo de humedad: manchas angulares, envés con esporulación y defoliación rápida cuando el follaje se mantiene mojado.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAngularLesionPattern,
          PlantHealthIds.signalUndersideSporulation,
          PlantHealthIds.signalRapidFoliarCollapse,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalWhitePowderGrowth,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Voltea la hoja y busca esporulación gris-violácea o sucia en el envés, sobre todo temprano en la mañana.',
      'Confirma que la lesión quede frenada por nervaduras y no se vea redonda libre.',
      'Si el follaje se descompuso muy rápido tras humedad alta o rocío largo, la sospecha sube mucho.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Baja mojado foliar y mejora ventilación de inmediato.',
      'Aísla el foco y corta tejido muy colapsado si ya está esporulando.',
      'Si el lote sigue en ventana húmeda, revisar manejo técnico cuanto antes.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. Mildiu velloso y bacteriosis angular pueden cruzarse; el envés activo y la velocidad del colapso ayudan a separarlos.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberFieldVarieties,
        diagnosisIds: <String>{'pseudoperonospora_cubensis'},
        scoreDelta: 6,
        rationaleEs:
            'En campo abierto este cuadro pesa más por lluvia, rocío y salpique.',
      ),
    ],
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_powdery_mildew_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Polvillo blanco superficial – cenicilla del pepino',
    stages: _cucumberFoliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomPowderyGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalSporesRubOff,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalUndersideSporulation,
      PlantHealthIds.signalWaterSoakedMargin,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'podosphaera_xanthii_cucumber',
        labelEs: 'Cenicilla / mildiu polvoso',
        scientificName: 'Podosphaera xanthii / Golovinomyces spp.',
        type: 'fungus',
        summaryEs:
            'Forma polvo blanco visible en hoja, empieza en focos y termina restando fotosíntesis, vida útil del dosel y llenado.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWhitePowderGrowth,
          PlantHealthIds.signalSporesRubOff,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalUndersideSporulation,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirma que sí haya polvillo superficial y no sólo clorosis o raspado.',
      'Revisa hojas medias y bajas: suele empezar en focos y luego subir.',
      'Si el cultivo está bajo cubierta y la ventilación viene justa, la sospecha sube.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Bajar densidad de follaje y mejorar ventilación donde el dosel viene cerrado.',
      'No dejar que suba a hojas nuevas productivas sin revisar manejo.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. Si el envés trae esporulación húmeda más que polvo superficial, revisar mildiu velloso.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberProtectedVarieties,
        diagnosisIds: <String>{'podosphaera_xanthii_cucumber'},
        scoreDelta: 6,
        rationaleEs:
            'En pepino protegido la cenicilla suele pesar más por ventilación limitada y continuidad del cultivo.',
      ),
    ],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_botrytis_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Necrosis húmeda con moho gris – Botrytis',
    stages: _cucumberProductiveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomGrayMoldNecrosis,
    strongSignals: <String>{
      PlantHealthIds.signalGrayFuzzyGrowth,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalStemCanker,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'botrytis_cinerea_cucumber',
        labelEs: 'Moho gris / Botrytis',
        scientificName: 'Botrytis cinerea',
        type: 'fungus',
        summaryEs:
            'Ataca flores, tejidos tiernos y heridas en ambientes húmedos con poca ventilación; deja micelio gris afelpado y necrosis húmeda.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
          PlantHealthIds.signalStemCanker,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca primero flores viejas, restos senescentes, pecíolos y heridas del tutorado o cosecha.',
      'Confirma micelio gris afelpado, no polvo blanco seco.',
      'Si el foco arranca en zonas húmedas o cerradas del invernadero, la sospecha sube.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Sanea tejido muerto y residuos húmedos que sigan sirviendo de foco.',
      'Mejora ventilación y evita periodos largos de humedad retenida en flor y follaje.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. En fruto o tallo puede mezclarse con otras pudriciones; el moho gris visible es la clave.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberProtectedVarieties,
        diagnosisIds: <String>{'botrytis_cinerea_cucumber'},
        scoreDelta: 8,
        rationaleEs:
            'Bajo cubierta este cuadro gana peso cuando la HR se queda alta y la ventilación no alcanza.',
      ),
    ],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_damping_off_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Plántula colapsada en cuello – damping-off / muerte súbita',
    stages: _cucumberEarlyStages,
    organIds: <String>{
      PlantHealthIds.organCrown,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSeedlingCollapse,
    strongSignals: <String>{
      PlantHealthIds.signalSeedlingNeckCollapse,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'damping_off_complex_cucumber',
        labelEs: 'Damping-off / muerte súbita',
        scientificName: 'Pythium spp. / Rhizoctonia spp. / otros',
        type: 'complex',
        summaryEs:
            'El cuello se adelgaza, se oscurece o se pudre y la plántula cae muy rápido en suelos o charolas demasiado húmedas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSeedlingNeckCollapse,
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalWaterlogging,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa cuello de la plántula: si está delgado, oscuro o acuoso, la sospecha sube mucho.',
      'Saca una planta completa para ver raíz joven ennegrecida o muy corta.',
      'Confirma si el problema arrancó en focos de exceso de humedad o drenaje flojo.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Corta riegos excesivos y mejora aireación/drenaje donde el suelo quedó pesado.',
      'No sigas empujando fertilización sobre plantas ya colapsadas; primero corrige la base hídrica.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. En plántula, riego, sustrato y sanidad del cuello pesan más que cualquier lectura aislada.',
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_root_rot_complex_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Marchitez con raíz o cuello comprometido – pudrición radicular',
    stages: _cucumberFullCycleStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pythium_phytophthora_root_rot_cucumber',
        labelEs: 'Pudrición de cuello y raíz',
        scientificName: 'Pythium spp. / Phytophthora spp.',
        type: 'oomycete',
        summaryEs:
            'Da marchitez con suelo todavía húmedo, cuello oscuro y raíz deteriorada; sube fuerte con encharcamiento y drenaje flojo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalRootsDarkRot,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'No te quedes sólo con la hoja marchita: abre el cuello y revisa raíz real.',
      'Si la planta se ve caída pero el suelo sigue húmedo, sospecha más de raíz que de sequía.',
      'La sospecha sube tras lluvia, riego pesado o compactación.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Prioridad total a corregir exceso de agua, drenaje y zonas compactadas.',
      'Aísla focos y evita mover agua contaminada entre camas o surcos.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. Marchitez por raíz y marchitez vascular se pueden cruzar; abrir cuello y raíz cambia la lectura.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberProtectedVarieties,
        diagnosisIds: <String>{'pythium_phytophthora_root_rot_cucumber'},
        scoreDelta: 5,
        rationaleEs:
            'En protegido en suelo este cuadro gana peso cuando el riego y la HR se desbalancean.',
      ),
    ],
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_fusarium_wilt_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Marchitez vascular progresiva – fusariosis',
    stages: _cucumberFoliarStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organStem,
      PlantHealthIds.organRoot,
    },
    primarySymptomId: PlantHealthIds.symptomWiltVascular,
    strongSignals: <String>{
      PlantHealthIds.signalVascularBrowning,
      PlantHealthIds.signalOneSidedWilt,
    },
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    conflictingSignals: <String>{PlantHealthIds.signalWaterlogging},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'fusarium_wilt_cucumber',
        labelEs: 'Marchitez fusariana',
        scientificName: 'Fusarium spp.',
        type: 'fungus',
        summaryEs:
            'Marchitez más lenta y vascular, a veces unilateral, con pardeamiento interno del tallo o cuello.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalVascularBrowning,
          PlantHealthIds.signalOneSidedWilt,
        },
        contradictorySignalIds: <String>{PlantHealthIds.signalWaterlogging},
      ),
    ],
    confirmationChecksEs: <String>[
      'Corta tallo o cuello y busca vasos pardos, no sólo raíz húmeda podrida.',
      'Pregunta si el lote tiene historial repetido del problema o rotación pobre.',
      'Si la marchitez viene unilateral o progresiva, la sospecha sube.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Mapea focos y no confundas este cuadro con un problema puramente de riego.',
      'Registra historial del lote porque la lectura para el siguiente ciclo importa mucho.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La confirmación mejora con corte vascular o laboratorio cuando el cuadro es dudoso.',
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_angular_leaf_spot_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Manchas angulares acuosas – bacteriosis angular',
    stages: _cucumberFoliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAngularSpots,
    strongSignals: <String>{
      PlantHealthIds.signalAngularLesionPattern,
      PlantHealthIds.signalWaterSoakedMargin,
      PlantHealthIds.signalHaloMargin,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    conflictingSignals: <String>{
      PlantHealthIds.signalUndersideSporulation,
      PlantHealthIds.signalWhitePowderGrowth,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pseudomonas_syringae_lachrymans',
        labelEs: 'Bacteriosis angular / angular leaf spot',
        scientificName: 'Pseudomonas syringae pv. lachrymans',
        type: 'bacterium',
        summaryEs:
            'Lesión angular y acuosa que luego se rompe o perfora; sube con semilla/residuo infectado, salpique y mojado foliar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAngularLesionPattern,
          PlantHealthIds.signalWaterSoakedMargin,
          PlantHealthIds.signalHaloMargin,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalUndersideSporulation,
          PlantHealthIds.signalWhitePowderGrowth,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca borde acuoso o halo antes de que la mancha se seque y se rompa.',
      'Pregunta si hubo lluvia, salpique o semilla dudosa.',
      'Si el cuadro viene muy foliado y húmedo pero sin polvo ni envés activo, esta sospecha sube.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Evita seguir mojando follaje y corta salpique entre plantas.',
      'Aísla focos y registra si entró desde bordes o después de lluvia.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. Se puede cruzar con mildiu velloso; la fase acuosa y la perforación posterior ayudan a separarla.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberFieldVarieties,
        diagnosisIds: <String>{'pseudomonas_syringae_lachrymans'},
        scoreDelta: 6,
        rationaleEs:
            'En campo abierto este cuadro pesa más por lluvia, salpique y continuidad de cucurbitáceas.',
      ),
    ],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_anthracnose_gummy_stem_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Lesiones hundidas y cancros – antracnosis / gomosis',
    stages: _cucumberFoliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalStemCanker,
      PlantHealthIds.signalPinkSporeMass,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalWaterSoakedMargin,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'colletotrichum_orbiculare_cucumber',
        labelEs: 'Antracnosis / gomosis',
        scientificName: 'Colletotrichum orbiculare / complejo gomosis',
        type: 'fungus',
        summaryEs:
            'Lesiones hundidas en hoja, tallo o fruto; en humedad puede verse masa rosada y en tallo puede ir con cancros o exudado gomoso.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalStemCanker,
          PlantHealthIds.signalPinkSporeMass,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'En fruto, confirma lesión hundida real y no raspado superficial.',
      'En tallo, busca cancro, grieta o exudado.',
      'Si el lote viene de lluvia o residuo infectado, la sospecha sube.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Aísla focos con fruto o tallo ya muy comprometido.',
      'Reduce salpique y evita dejar fruto enfermo dentro del lote.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. El nombre exacto del patógeno puede variar por región; en producto importa más el cuadro funcional.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberFieldVarieties,
        diagnosisIds: <String>{'colletotrichum_orbiculare_cucumber'},
        scoreDelta: 5,
        rationaleEs:
            'En campo abierto este complejo pesa más cuando hay lluvia, residuos y salpique.',
      ),
    ],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_aphid_virus_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Mosaico o deformación con áfidos – probable complejo viral',
    stages: _cucumberFoliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalLeafRolling,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAphidEarlyToxicity,
      PlantHealthIds.signalStickyHoneydew,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cucumber_aphid_virus_complex',
        labelEs: 'Complejo viral transmitido por áfidos',
        scientificName: 'CMV / WMV / ZYMV / otros',
        type: 'virus',
        summaryEs:
            'Mosaico, deformación, enanismo o fruto irregular con presencia de áfidos y maleza hospedera alrededor.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalVectorPresent,
          PlantHealthIds.signalLeafRolling,
          PlantHealthIds.signalAphidEarlyToxicity,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si el patrón está en focos y si ya tocó brotes nuevos.',
      'Confirma presencia de áfidos o presión reciente en bordes y maleza.',
      'Si el amarillamiento viene con deformación de hoja o fruto, sube la sospecha viral.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Prioriza cortar focos de vector y maleza hospedera alrededor del lote.',
      'Si el mosaico ya está claro, separar diagnóstico de un simple desorden nutricional.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. Virus y fitotoxicidades pueden confundirse; el patrón de distribución y la presión de vector pesan mucho.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberFieldVarieties,
        diagnosisIds: <String>{'cucumber_aphid_virus_complex'},
        scoreDelta: 6,
        rationaleEs:
            'En campo abierto el complejo viral por áfidos suele pesar más cuando hay maleza y siembras escalonadas cerca.',
      ),
    ],
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_whitefly_virus_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Mosca blanca visible o encrespado asociado',
    stages: _cucumberFoliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomWhiteflyPresence,
    strongSignals: <String>{
      PlantHealthIds.signalWhiteflyCloud,
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
    },
    weakSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalLeafRolling,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'bemisia_tabaci_cucumber',
        labelEs: 'Mosca blanca',
        scientificName: 'Bemisia tabaci / Trialeurodes spp.',
        type: 'insect',
        summaryEs:
            'Chupa savia, deja mielecilla y fumagina, y en presión alta también abre la puerta a complejos virales o encrespados.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWhiteflyCloud,
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalSootyMold,
        },
      ),
      PlantHealthDiagnosis(
        id: 'cucumber_whitefly_virus_complex',
        labelEs: 'Mosca blanca con posible virus asociado',
        scientificName: 'Complejo viral asociado a vector',
        type: 'virus',
        summaryEs:
            'Cuando además de la mosca blanca aparece deformación o encrespado sostenido, hay que pensar en cuadro combinado, no solo en el insecto.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWhiteflyCloud,
          PlantHealthIds.signalLeafRolling,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Sacude follaje y confirma nube de adultos, no sólo uno o dos insectos aislados.',
      'Revisa envés, mielecilla y tizne negro en hojas medias y bajas.',
      'Si también hay deformación sostenida, separa presión de plaga de posible virus asociado.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Atender primero focos en entradas, ventilas y bordes calientes.',
      'No dejar que mielecilla y fumagina sigan cerrando fotosíntesis.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. En pepino protegido conviene separar daño directo de mosca blanca y sospecha viral asociada.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberProtectedVarieties,
        diagnosisIds: <String>{
          'bemisia_tabaci_cucumber',
          'cucumber_whitefly_virus_complex',
        },
        scoreDelta: 8,
        rationaleEs:
            'Bajo cubierta este foco pesa más, sobre todo si arrancó en puertas o ventilas.',
      ),
    ],
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_aphids_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Colonias de áfidos en brote o envés',
    stages: _cucumberFoliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomAphidColonies,
    strongSignals: <String>{
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalLeafRolling,
    },
    weakSignals: <String>{PlantHealthIds.signalVectorPresent},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aphids_cucumber_complex',
        labelEs: 'Áfidos',
        scientificName: 'Aphis gossypii y otros',
        type: 'insect',
        summaryEs:
            'Colonias en brotes y envés que deforman hoja, ensucian con mielecilla y además mueven riesgo viral si no se frenan.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalLeafRolling,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa brotes tiernos y envés, no solo hojas viejas.',
      'Si la colonia ya va acompañada de mielecilla y deformación, el foco ya está activo.',
      'En floración, sube la atención porque además empuja riesgo viral.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Monitorear brotes tiernos y maleza hospedera cercana.',
      'No esperar a que el foco se haga general cuando el cultivo ya entró a floración.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. Colonias pequeñas pueden parecer menores, pero en pepino abren rápido puerta a deformación y virus.',
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_thrips_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Raspado fino o plateado en hoja, flor o fruto – trips',
    stages: _cucumberFlowerFruitStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalBronzedLeafSurface,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'thrips_cucumber_complex',
        labelEs: 'Trips',
        scientificName: 'Frankliniella occidentalis / Thrips palmi / otros',
        type: 'insect',
        summaryEs:
            'Raspan tejido, dejan plateado o bronceado, dañan flor y marcan fruto joven; en protegido pueden subir muy rápido con calor y baja HR.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalThripsPresent,
          PlantHealthIds.signalBronzedLeafSurface,
          PlantHealthIds.signalDryHotWindow,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Mira flor y envés con detalle; los trips suelen esconderse en tejido tierno.',
      'En fruto joven, revisa raspado fino o cicatriz superficial temprana.',
      'Si el ambiente viene seco y caliente, la sospecha sube.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'No revisar sólo al centro: puertas y ventilas suelen prender primero.',
      'Aumenta disciplina de monitoreo en floración y amarre.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. El raspado de trips puede confundirse con estrés superficial; ver el insecto o la marca fresca ayuda mucho.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberProtectedVarieties,
        diagnosisIds: <String>{'thrips_cucumber_complex'},
        scoreDelta: 8,
        rationaleEs:
            'En pepino protegido este cuadro pesa más por focos en ventilas y ambiente seco-caliente.',
      ),
    ],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_spider_mites_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Bronceado fino con telaraña – araña roja',
    stages: _cucumberFoliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalBronzedLeafSurface,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{PlantHealthIds.signalThripsPresent},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tetranychus_urticae_cucumber',
        labelEs: 'Araña roja',
        scientificName: 'Tetranychus urticae',
        type: 'mite',
        summaryEs:
            'Arranca con punteado clorótico, luego broncea la hoja y en presión alta deja telaraña fina; castiga muy rápido en calor seco.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
          PlantHealthIds.signalBronzedLeafSurface,
          PlantHealthIds.signalDryHotWindow,
        },
        contradictorySignalIds: <String>{PlantHealthIds.signalThripsPresent},
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa envés y busca puntos móviles o telaraña fina, no sólo el bronceado.',
      'Si el lote viene con estrés hídrico y baja HR, la sospecha sube mucho.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'No esperes a que el bronceado cierre media hoja para reaccionar.',
      'Revisa focos secos y calientes primero.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. Araña roja y trips pueden compartir bronceado; la telaraña y el ácaro visible separan mejor.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberProtectedVarieties,
        diagnosisIds: <String>{'tetranychus_urticae_cucumber'},
        scoreDelta: 8,
        rationaleEs:
            'Bajo cubierta la araña roja suele dispararse más por baja HR y puntos calientes.',
      ),
    ],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_leafminers_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Galerías serpentinas dentro de la hoja – minadores',
    stages: _cucumberFoliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomLeafMines,
    strongSignals: <String>{PlantHealthIds.signalLeafMines},
    weakSignals: <String>{PlantHealthIds.signalVectorPresent},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'leafminer_cucumber_complex',
        labelEs: 'Minadores de hoja',
        scientificName: 'Liriomyza spp. y otros',
        type: 'insect',
        summaryEs:
            'Dejan galerías serpentinas y punturas de alimentación; restan área útil y suben con maleza y monitoreo flojo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalLeafMines},
      ),
    ],
    confirmationChecksEs: <String>[
      'La marca debe ir “por dentro” de la hoja como camino o serpiente, no como mancha plana.',
      'Revisa si ya hay muchas punturas pequeñas acompañando las minas.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Sube monitoreo en bordes y maleza hospedera cercana.',
      'No dejar que el foco avance a hojas nuevas si la planta aún viene armando dosel.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. Si no hay galería interna clara, revisar otro cuadro foliar.',
  ),
  PlantHealthSyndrome(
    id: 'cucumber_root_knot_nematodes_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Raíz con agallas y vigor caído – nematodos',
    stages: _cucumberFullCycleStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootGalls,
    strongSignals: <String>{PlantHealthIds.signalRootGalls},
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'meloidogyne_cucumber',
        labelEs: 'Nematodos agalladores',
        scientificName: 'Meloidogyne spp.',
        type: 'nematode',
        summaryEs:
            'Bajan vigor, deforman la raíz y vuelven irregular la marchitez; pegan especialmente en lotes repetidos y con rotación floja.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRootGalls},
      ),
    ],
    confirmationChecksEs: <String>[
      'Saca planta completa y confirma nudos o agallas reales en raíz, no solo raíz corta o dañada.',
      'Pregunta por historial del lote y continuidad de cucurbitáceas.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Mapea focos porque rara vez arranca homogéneo desde el día uno.',
      'No confundir con simple falta de agua si la raíz ya viene deformada.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La raíz manda el diagnóstico; ver sólo la parte aérea puede engañar.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberFieldVarieties,
        diagnosisIds: <String>{'meloidogyne_cucumber'},
        scoreDelta: 5,
        rationaleEs:
            'En campo abierto y lotes repetidos este cuadro suele pesar más por historial y rotación pobre.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'cucumber_borers_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Daño perforado con excretas – perforadores regionales',
    stages: _cucumberFlowerFruitStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalFrassPresent,
    },
    weakSignals: <String>{PlantHealthIds.signalVectorPresent},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'diaphania_cucumber_borers',
        labelEs: 'Perforadores regionales',
        scientificName: 'Diaphania spp. y afines',
        type: 'insect',
        summaryEs:
            'Perforan brotes, flores o fruto y dejan excretas visibles; el daño suele ser más regional y de presión local.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalFeedingHoles,
          PlantHealthIds.signalActiveChewing,
          PlantHealthIds.signalFrassPresent,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirma agujero real con borde masticado o larva presente.',
      'Revisa flor y fruto joven además de brotes tiernos.',
      'Si el problema es muy localizado y regional, puede ser este complejo y no una enfermedad.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Abrir y revisar fruto o brote sospechoso, no quedarse sólo con la marca externa.',
      'Monitorear bordes y maleza hospedera regional.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. Este cuadro depende mucho de zona; si no hay mordida o excretas, revisar otra causa.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberFieldVarieties,
        diagnosisIds: <String>{'diaphania_cucumber_borers'},
        scoreDelta: 6,
        rationaleEs:
            'En campo abierto este cuadro pesa más por presión regional y maleza hospedera.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'cucumber_heat_flower_abort_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Caída de flor o mal cuaje por calor',
    stages: _cucumberFlowerFruitStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalFlowerDrop,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cucumber_heat_flower_abort',
        labelEs: 'Aborto floral por calor',
        scientificName: 'Desorden abiótico',
        type: 'abiotic',
        summaryEs:
            'En ventana crítica, el calor sostenido y la HR baja tumban flor o vuelven errático el cuaje aunque no haya plaga dominante.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHeatStress,
          PlantHealthIds.signalFlowerDrop,
          PlantHealthIds.signalDryHotWindow,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Antes de culpar nutrición, revisa si vino un pico térmico o ambiente muy seco.',
      'Pregunta si la caída fue rápida y sin lesión clara de patógeno.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Proteger la ventana de floración: agua pareja, ventilación y sombreo cuando aplique.',
      'No perseguir el síntoma sólo con más nitrógeno; primero corrige ambiente y continuidad hídrica.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. El aborto floral también puede mezclarse con estrés salino o radicular; revisar contexto completo.',
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_fruit_deformation_stress_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Fruto deforme por agua–HR–salinidad–ambiente',
    stages: _cucumberFlowerFruitStages,
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFruitDeformation,
    strongSignals: <String>{
      PlantHealthIds.signalFruitHooking,
      PlantHealthIds.signalDeformedNoRot,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalFruitApicalBlackPatch,
      PlantHealthIds.signalFeedingHoles,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cucumber_fruit_deformation_stress',
        labelEs: 'Fruto deforme por estrés agua–salinidad–ambiente',
        scientificName: 'Desorden abiótico',
        type: 'abiotic',
        summaryEs:
            'Fruto curvo, cuello marcado o llenado disparejo cuando el cultivo pierde continuidad de agua, sube CE o se seca demasiado el ambiente.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalFruitHooking,
          PlantHealthIds.signalDeformedNoRot,
          PlantHealthIds.signalSalinityLoad,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalFruitApicalBlackPatch,
          PlantHealthIds.signalFeedingHoles,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirma que el fruto esté deforme pero sin pudrición activa ni mordida clara.',
      'Cruza lectura con riego, ambiente y CE; en pepino rara vez es sólo una causa.',
      'En materiales partenocárpicos protegidos, revisar también entrada no deseada de polinizadores si la forma es muy tipo maza.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Prioriza continuidad de agua y revisar carga salina antes de subir fertilizante a ciegas.',
      'No leer la deformación como simple “detalle cosmético”; ya está diciendo que el sistema perdió balance.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. Si además hay mancha negra hundida o perforación, revisar otro cuadro principal.',
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.cucumberCropId,
        varietyIds: _cucumberParthenocarpicProtectedVarieties,
        diagnosisIds: <String>{'cucumber_fruit_deformation_stress'},
        scoreDelta: 4,
        rationaleEs:
            'En materiales protegidos partenocárpicos la forma del fruto es más sensible al ambiente y al manejo de HR.',
      ),
    ],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_waterlogging_risk_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Riesgo radicular por exceso de humedad',
    stages: _cucumberFullCycleStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{PlantHealthIds.signalWaterlogging},
    weakSignals: <String>{
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cucumber_waterlogging_root_risk',
        labelEs: 'Exceso de humedad / anoxia radicular',
        scientificName: 'Desorden abiótico',
        type: 'abiotic',
        summaryEs:
            'La planta se cae con suelo todavía húmedo porque la raíz pierde aire y el cuello se compromete; si no se corrige, después entra complejo radicular.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalRootsDarkRot,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Pregunta primero por lluvia, riego pesado o drenaje flojo antes de culpar deficiencia.',
      'Si el suelo sigue húmedo cuando la planta se ve caída, la sospecha sube.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Ajusta riego, escurrimiento y aireación del suelo de inmediato.',
      'No sigas empujando CE cuando la raíz ya está sin oxígeno.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. Este cuadro puede ser la puerta de entrada a pudriciones verdaderas; por eso la urgencia es alta.',
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cucumber_cold_damage_01',
    cropId: CropCatalog.cucumberCropId,
    labelEs: 'Daño por frío o trasplante frío',
    stages: _cucumberEarlyStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organFlower,
      PlantHealthIds.organLeaf,
    },
    primarySymptomId: PlantHealthIds.symptomColdInjury,
    strongSignals: <String>{PlantHealthIds.signalColdExposure},
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalFlowerDrop,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cucumber_cold_injury',
        labelEs: 'Daño por frío',
        scientificName: 'Desorden abiótico',
        type: 'abiotic',
        summaryEs:
            'Frena crecimiento, tumba flor temprana y deja al pepino sin empuje cuando el trasplante o el lote recibe frío sostenido.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalFlowerDrop,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirma si hubo noche fría, trasplante expuesto o arranque muy por debajo del rango útil.',
      'Si no hay lesión biótica clara y el crecimiento se frenó de golpe, esta sospecha sube.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Priorizar protección térmica y evitar nuevos estreses sobre un cultivo todavía frío.',
      'No exigir al sistema con riegos o sales innecesarias mientras la planta sigue frenada.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. El frío también puede abrir puerta a raíz débil y mal arranque; revisar base del establecimiento.',
    favorsRecentStress: true,
  ),
];
