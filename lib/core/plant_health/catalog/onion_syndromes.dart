import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

const Set<PlantHealthStageBucket> _earlyStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
};

const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _bulbStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _rootStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _storageStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _allOnionStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<String> _redVarieties = <String>{
  'onion_purple',
  'on_03',
};

const Set<String> _storageVarieties = <String>{
  'onion_transition',
  'on_04',
};

const Set<String> _bunchingVarieties = <String>{
  'onion_cambray',
  'on_05',
};

const String _disclaimer =
    'Diagnostico sugerido. BIO-G orienta riesgo, monitoreo y manejo cultural; confirma en campo y con apoyo tecnico local si el dano avanza. No prescribe pesticidas.';

const List<String> _baseActions = <String>[
  'Marcar focos por cama o zona y revisar avance en 24-48 horas.',
  'Separar problema sanitario de riego, CE, calor, fotoperiodo o compactacion.',
  'Retirar hojas o plantas muy afectadas si ya son fuente de inoculo.',
  'Registrar fotos, etapa, humedad, temperatura y manejo reciente.',
];

const List<String> _leafActions = <String>[
  'Revisar enves, pliegues de hoja y cuello donde se esconde trips.',
  'Evitar mojado foliar tardio y mejorar ventilacion del dosel.',
  'No subir N si hay calor, CE alta, HR alta o cuello grueso.',
  'Proteger area foliar: la hoja es la fabrica que llena el bulbo.',
];

const List<String> _rootActions = <String>[
  'Sacar plantas completas y revisar raiz, plato basal, cuello y olor.',
  'Diferenciar pudricion radicular de anoxia, salinidad o compactacion.',
  'No mover suelo, bulbos ni herramienta de un foco a otros lotes.',
  'Revisar historial de Allium en el lote y la rotacion.',
];

const List<String> _bulbActions = <String>[
  'Priorizar madurez, cuello seco, curado y ventilacion sobre crecer mas.',
  'Evitar heridas, riego tardio y N tardio que abren puerta a pudriciones.',
  'Separar bulbos enfermos antes de almacenar o vender.',
  'Registrar el evento para ajustar manejo y conservacion del siguiente ciclo.',
];

const List<String> _vectorActions = <String>[
  'Revisar pliegues, cuello, bordes del lote, malezas y Allium vecinos.',
  'Distinguir dano directo de plaga de sintomas compatibles con virus.',
  'Manejar malezas hospederas, voluntarios y focos sin recetar quimicos.',
  'Confirmar vector, patron y avance antes de escalar manejo.',
];

const List<String> _abioticActions = <String>[
  'Cruzar sintomas con riego, CE, temperatura, raiz, fotoperiodo y etapa.',
  'Si el patron es uniforme, pensar primero en ambiente, sales o manejo.',
  'No corregir con fertilizante fuerte sin confirmar agua y salinidad.',
  'Usar la lectura para ajustar el siguiente ciclo si el cultivo ya esta tarde.',
];

/// Catalogo de riesgos / sanidad vegetal de cebolla (`crop_onion`).
///
/// La salida es compatible con "revise/confirme"; no receta plaguicidas ni
/// ingredientes activos. Organo objetivo: bulbo (hoja + base en cambray).
const List<PlantHealthSyndrome> onionSyndromes = <PlantHealthSyndrome>[
  // ── 1. Establecimiento / suelo ───────────────────────────────────────
  PlantHealthSyndrome(
    id: 'onion_damping_off_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Nacencia pobre, plantula caida o cuello vencido',
    stages: _earlyStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSeedlingCollapse,
    strongSignals: <String>{
      PlantHealthIds.signalSeedlingNeckCollapse,
      PlantHealthIds.signalPoorEmergence,
      PlantHealthIds.signalWaterlogging,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_damping_off',
        labelEs: 'Damping-off / muerte de plantula',
        scientificName: 'Pythium spp. / Rhizoctonia solani / Fusarium spp.',
        type: 'fungus_oomycete',
        summaryEs:
            'Plantulas colapsadas por cuello o raiz joven. Se favorece por suelo frio-humedo, costra, exceso de agua, cama mal drenada y salinidad en arranque.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa cuello oscuro o estrangulado en plantulas caidas.',
      'Confirma si el suelo estuvo saturado, frio o con costra.',
      'Compara zonas bajas contra zonas con mejor drenaje.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_root_rot_anoxia_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Marchitez con suelo humedo o raiz oscura',
    stages: _rootStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalWaterlogging,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_root_rot_anoxia',
        labelEs: 'Pudricion de raiz / anoxia',
        scientificName: 'Complejo radicular + saturacion',
        type: 'root_disease_complex',
        summaryEs:
            'Raiz superficial limitada por exceso de agua, suelo pesado o compactacion. Marchitez con suelo humedo, parches y amarillamiento.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si la marchitez ocurre con suelo humedo (no seco).',
      'Verifica drenaje, compactacion y zonas bajas.',
      'No subir riego ni fertilizante hasta separar raiz de falta de nutriente.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_pink_root_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Raices rosadas/rojas y planta enana',
    stages: _rootStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomPinkRoots,
    strongSignals: <String>{
      PlantHealthIds.signalPinkRoots,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_pink_root',
        labelEs: 'Raiz rosada / pink root',
        scientificName: 'Setophoma (Phoma) terrestris',
        type: 'fungus',
        summaryEs:
            'Raices rosa que viran a rojo/purpura y luego se secan; plantas enanas y bulbos chicos. Pesa por historial de Allium, calor y estres.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Saca raices activas y busca color rosa-rojo-purpura.',
      'Revisa historial del lote y rotacion de Allium.',
      'No confundir con raices viejas/muertas normales.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_fusarium_basal_rot_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Plato basal cafe y pudricion seca desde la base',
    stages: _bulbStages,
    organIds: <String>{
      PlantHealthIds.organBasalPlate,
      PlantHealthIds.organBulb,
      PlantHealthIds.organRoot,
    },
    primarySymptomId: PlantHealthIds.symptomBasalPlateBrownRot,
    strongSignals: <String>{
      PlantHealthIds.signalBasalPlateBrownRot,
      PlantHealthIds.signalHeatStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_fusarium_basal_rot',
        labelEs: 'Pudricion basal por Fusarium',
        scientificName: 'Fusarium oxysporum f. sp. cepae',
        type: 'fungus',
        summaryEs:
            'Pudricion seca que inicia en el plato basal y sube; hojas amarillas desde puntas y bulbo que se agrieta. Sube con suelo calido, heridas y plagas secundarias.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Corta el bulbo y revisa si la pudricion inicia en el plato basal.',
      'Diferencia de bacteria que entra por cuello.',
      'Relaciona con suelo calido, heridas o plagas de suelo.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _bulbActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_white_rot_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Micelio blanco y esclerocios negros en la base',
    stages: _bulbStages,
    organIds: <String>{
      PlantHealthIds.organBasalPlate,
      PlantHealthIds.organRoot,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomWhiteMyceliumSclerotia,
    strongSignals: <String>{
      PlantHealthIds.signalWhiteMyceliumSclerotia,
      PlantHealthIds.signalCoolDewyWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_white_rot',
        labelEs: 'Pudricion blanca / white rot',
        scientificName: 'Stromatinia cepivora (Sclerotium cepivorum)',
        type: 'fungus',
        summaryEs:
            'Micelio blanco en la base con bolitas negras tipo semilla de amapola; la planta se desprende facil. Senal fuerte: el inoculo persiste muchos anos en el suelo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca micelio blanco y esclerocios negros en base/raiz.',
      'Confirma si la planta se desprende con facilidad.',
      'Evita mover suelo, bulbos o equipo de ese foco a otros lotes.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsCoolDewyWindow: true,
    favorsHighHumidity: true,
  ),
  // ── 2. Enfermedades foliares ─────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'onion_downy_mildew_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Crecimiento velloso gris/morado en hoja con parches amarillos',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomDownyFuzzyGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalDownyFuzzyGrowth,
      PlantHealthIds.signalDenseWetCanopy,
      PlantHealthIds.signalCoolDewyWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_downy_mildew',
        labelEs: 'Mildiu velloso',
        scientificName: 'Peronospora destructor',
        type: 'oomycete',
        summaryEs:
            'Riesgo critico en hoja. Crecimiento gris/blanco/morado con parches amarillos que avanzan con viento. Se favorece con HR muy alta, rocio, hoja mojada y clima fresco.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Voltea la hoja temprano y busca esporulacion gris/morada.',
      'Relaciona con HR alta, rocio o riego que moja follaje.',
      'Revisa si el dano avanza por parches con el viento.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _leafActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.onionCropId,
        varietyIds: _storageVarieties,
        diagnosisIds: <String>{'onion_downy_mildew'},
        scoreDelta: 4,
        rationaleEs:
            'Transicion/altiplano sube riesgo por frio, lluvia tardia y dosel cerrado.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'onion_botrytis_leaf_blight_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Manchas blancas hundidas con halo y puntas secas',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomWhiteSunkenLeafSpots,
    strongSignals: <String>{
      PlantHealthIds.signalWhiteSunkenLeafSpots,
      PlantHealthIds.signalDenseWetCanopy,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_botrytis_leaf_blight',
        labelEs: 'Botrytis leaf blight',
        scientificName: 'Botrytis squamosa',
        type: 'fungus',
        summaryEs:
            'Manchas blancas pequenas hundidas con halo que secan puntas y reducen el tamano del bulbo. Sube con mojado foliar prolongado y dosel cerrado.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca manchas blancas hundidas con halo en hojas.',
      'Confirma rocio, hoja mojada o ventilacion limitada.',
      'Revisa si las puntas empiezan a secarse.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _leafActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_purple_blotch_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Lesiones elipticas purpuras con anillos concentricos',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomPurpleConcentricLesions,
    strongSignals: <String>{
      PlantHealthIds.signalPurpleConcentricLesions,
      PlantHealthIds.signalHumidWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalThripsSilverScarring,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_purple_blotch',
        labelEs: 'Mancha purpura / Alternaria',
        scientificName: 'Alternaria porri',
        type: 'fungus',
        summaryEs:
            'Lesiones elipticas tan/purpura con anillos concentricos y halo amarillo; la hoja se quiebra. Sube con humedad, tejido viejo, dano por trips y estres.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca lesiones purpuras con anillos y halo amarillo.',
      'Relaciona con rocio, trips o tejido viejo lesionado.',
      'Revisa si inicia en hojas viejas.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _leafActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_stemphylium_leaf_blight_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Manchas oscuras oliva-negro que coalescen y tiznan la hoja',
    stages: _bulbStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomDarkOliveLeafBlight,
    strongSignals: <String>{
      PlantHealthIds.signalDarkOliveLeafBlight,
      PlantHealthIds.signalHumidWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_stemphylium_leaf_blight',
        labelEs: 'Stemphylium leaf blight',
        scientificName: 'Stemphylium vesicarium',
        type: 'fungus',
        summaryEs:
            'Manchas oscuras oliva-negro que coalescen y causan tizne y defoliacion rapida. El follaje pierde area activa y baja el calibre del bulbo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si las manchas son oliva-negro y se unen.',
      'Confirma humedad de dosel, rocio nocturno o estres previo.',
      'Relaciona con lesiones previas de mancha purpura o mildiu.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _leafActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_rust_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Pustulas naranjas o rojizas en hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomOrangePustules,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_rust',
        labelEs: 'Roya de la cebolla',
        scientificName: 'Puccinia allii',
        type: 'fungus',
        summaryEs:
            'Pustulas naranjas/rojizas que luego oscurecen en hoja. Regional; sube con HR alta y temperaturas moderadas en ciclos repetidos de Allium.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca pustulas naranja/rojizas elevadas en la hoja.',
      'Confirma humedad alta y ciclos de Allium cercanos.',
      'Revisa densidad y ventilacion del dosel.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  // ── 3. Plagas y vectores ─────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'onion_thrips_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Plateado/bronceado y trips en cuello y pliegues',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organNeck},
    primarySymptomId: PlantHealthIds.symptomThripsSilverScarring,
    strongSignals: <String>{
      PlantHealthIds.signalThripsSilverScarring,
      PlantHealthIds.signalThripsInNeckFolds,
      PlantHealthIds.signalThripsPresent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_thrips',
        labelEs: 'Trips de la cebolla',
        scientificName: 'Thrips tabaci / Frankliniella occidentalis',
        type: 'insect',
        summaryEs:
            'Plaga eje de cebolla: raspado/succion deja plateado-bronceado, reduce fotosintesis, abre puerta a enfermedades y puede vectorizar IYSV. Critico en inicio de bulbo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa dentro del cuello y pliegues de hoja, no solo la superficie.',
      'Confirma insectos pequenos y raspado plateado.',
      'Relaciona con clima seco-caliente y campos vecinos (cereales/alfalfa).',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.onionCropId,
        varietyIds: _bunchingVarieties,
        diagnosisIds: <String>{'onion_thrips'},
        scoreDelta: 5,
        rationaleEs:
            'En cambray la hoja es producto: el dano cosmetico de trips pesa mas y mas temprano.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'onion_iris_yellow_spot_virus_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Lesiones pajizas tipo diamante asociadas a trips',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomStrawDiamondLesions,
    strongSignals: <String>{
      PlantHealthIds.signalStrawDiamondLesions,
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalVectorPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_iris_yellow_spot_virus',
        labelEs: 'Virus del manchado amarillo (IYSV)',
        scientificName: 'Iris yellow spot virus (transmitido por trips)',
        type: 'insect_virus',
        summaryEs:
            'Lesiones pajizas/amarillas en forma de diamante o huso, con necrosis y muerte de hojas. Asociado a trips viruliferos, malezas/voluntarios, estres y exceso de N.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca lesiones pajizas tipo diamante en hojas/escapo.',
      'Confirma presencia y presion de trips.',
      'Revisa malezas hospederas y cebolla voluntaria cercana.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_leafminer_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Galerias o minas blancas serpenteantes en hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomLeafMines,
    strongSignals: <String>{PlantHealthIds.signalLeafMines},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_leafminer',
        labelEs: 'Minadores de hoja',
        scientificName: 'Liriomyza spp.',
        type: 'insect',
        summaryEs:
            'Galerias internas serpenteantes. En bulbo seco puede ser cosmetico, pero en cambray afecta directamente el producto comercial.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Mira la hoja a contraluz y busca larva al final de la mina.',
      'Distingue de mancha: la mina sigue un trazo interno.',
      'Revisa si el dano llega a hoja comercializable (cambray).',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.onionCropId,
        varietyIds: _bunchingVarieties,
        diagnosisIds: <String>{'onion_leafminer'},
        scoreDelta: 6,
        rationaleEs: 'En cambray las galerias son dano comercial directo.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'onion_maggot_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Larvas blancas en base/semilla y fallas de stand',
    stages: _earlyStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organBulb,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMaggotStandLoss,
    strongSignals: <String>{
      PlantHealthIds.signalMaggotLarvae,
      PlantHealthIds.signalPoorEmergence,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_maggot',
        labelEs: 'Gusano de la cebolla / gusano de semilla',
        scientificName: 'Delia antiqua / Delia platura',
        type: 'soil_insect',
        summaryEs:
            'Larvas blancas sin patas que comen semilla, plantula y base; causan fallas de stand y pudricion secundaria. Suben con suelo fresco-humedo y materia organica fresca.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Desentierra semilla/plantula y busca larvas blancas en la base.',
      'Relaciona con materia organica fresca o rotacion con leguminosas.',
      'Separa de damping-off si no hay cuello podrido sin larva.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_nematodes_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Planta frenada con raiz o bulbo deformado',
    stages: _rootStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomRootGalls,
    strongSignals: <String>{
      PlantHealthIds.signalRootGalls,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_nematodes',
        labelEs: 'Nematodos de tallo/bulbo y raiz',
        scientificName: 'Ditylenchus dipsaci / Meloidogyne spp.',
        type: 'nematode',
        summaryEs:
            'Raiz corta o agallada, bulbo deformado y tejido gris/blando en cuello si es Ditylenchus. Se confirma con raiz y, si aplica, analisis local.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Saca raiz/bulbo y busca agallas, lesiones o tejido esponjoso.',
      'Compara focos con historial del lote y material/semilla.',
      'No confundir con compactacion sin revisar raiz.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  // ── 4. Pudriciones de bulbo / cuello / almacenamiento ────────────────
  PlantHealthSyndrome(
    id: 'onion_botrytis_neck_rot_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Cuello blando con moho gris entre escamas',
    stages: _storageStages,
    organIds: <String>{PlantHealthIds.organNeck, PlantHealthIds.organBulb},
    primarySymptomId: PlantHealthIds.symptomNeckSoftRot,
    strongSignals: <String>{
      PlantHealthIds.signalNeckSoft,
      PlantHealthIds.signalGrayMoldNeck,
      PlantHealthIds.signalPoorCuringNeckMoist,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_botrytis_neck_rot',
        labelEs: 'Pudricion de cuello por Botrytis',
        scientificName: 'Botrytis allii / B. aclada',
        type: 'fungus',
        summaryEs:
            'Cuello blando, tejido acuoso cafe y moho gris entre escamas. Suele iniciar en campo y aparecer en almacenamiento; sube con N tardio, cuello grueso, cosecha inmadura y mal curado.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa cuello blando y moho gris entre escamas.',
      'Confirma si hubo N tardio, riego tardio o curado incompleto.',
      'Separa bulbos afectados antes de almacenar.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _bulbActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.onionCropId,
        varietyIds: _storageVarieties,
        diagnosisIds: <String>{'onion_botrytis_neck_rot'},
        scoreDelta: 5,
        rationaleEs:
            'Almacenamiento/bodega: la pudricion de cuello define perdida poscosecha.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'onion_bacterial_bulb_rot_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Escamas internas acuosas, olor agrio o centro colapsado',
    stages: _storageStages,
    organIds: <String>{
      PlantHealthIds.organBulb,
      PlantHealthIds.organNeck,
    },
    primarySymptomId: PlantHealthIds.symptomBulbScaleWaterSoaked,
    strongSignals: <String>{
      PlantHealthIds.signalBulbScaleWaterSoaked,
      PlantHealthIds.signalSourSmell,
      PlantHealthIds.signalCenterLeafBleaching,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_bacterial_bulb_rot',
        labelEs: 'Pudriciones bacterianas de bulbo (complejo)',
        scientificName:
            'Pantoea / Burkholderia / Pectobacterium / Dickeya (center rot, sour skin, soft rot)',
        type: 'bacteria',
        summaryEs:
            'Escamas internas acuosas/amarillas, olor agrio y centro/escamas separadas. Sube con calor >29 C, agua libre, heridas, riego por aspersion, N alto y curado lento.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Corta el bulbo y revisa escamas internas acuosas u olor agrio.',
      'Relaciona con calor, heridas, aspersion tardia y curado lento.',
      'Distingue de Fusarium (que inicia en plato basal).',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _bulbActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_black_blue_mold_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Esporas negras o moho azul-verde bajo las escamas',
    stages: _storageStages,
    organIds: <String>{PlantHealthIds.organBulb},
    primarySymptomId: PlantHealthIds.symptomBlackMoldSpores,
    strongSignals: <String>{
      PlantHealthIds.signalBlackMoldSpores,
      PlantHealthIds.signalBlueGreenMold,
      PlantHealthIds.signalPoorCuringNeckMoist,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_black_blue_mold',
        labelEs: 'Moho negro / moho azul poscosecha',
        scientificName: 'Aspergillus niger / Penicillium spp.',
        type: 'fungus',
        summaryEs:
            'Masas negras de esporas (calor) o moho verde-azul (almacenamiento) bajo escamas externas. Suben con heridas, humedad, condensacion y curado deficiente.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa escamas externas: polvo negro o moho azul-verde.',
      'Relaciona con heridas, calor o mala ventilacion en bodega.',
      'Mejora curado, ventilacion y manejo sin golpes.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _bulbActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  // ── 5. Desordenes fisiologicos / manejo ──────────────────────────────
  PlantHealthSyndrome(
    id: 'onion_no_bulb_photoperiod_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Mucha hoja y poco bulbo: revisa fotoperiodo',
    stages: _bulbStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomNoBulbPhotoperiod,
    strongSignals: <String>{
      PlantHealthIds.signalNoBulbPhotoperiod,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_no_bulb_photoperiod',
        labelEs: 'No bulbificacion por fotoperiodo incorrecto',
        scientificName: 'Desajuste fisiologico de fotoperiodo',
        type: 'physiological_failure',
        summaryEs:
            'La cebolla puede crecer con buena hoja y no formar bulbo si el tipo no corresponde al dia de la zona. No es enfermedad ni falta de fertilizante: el fotoperiodo no se corrige con NPK.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirma si hay hoja grande pero el bulbo no avanza.',
      'Revisa tipo/variedad, fecha de siembra, region y exceso de N.',
      'No tratar como deficiencia nutricional ni enfermedad.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'onion_seedstalk_bolting_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Tallo floral / espigado con perdida de calidad',
    stages: _bulbStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomSeedstalkBolting,
    strongSignals: <String>{
      PlantHealthIds.signalSeedstalkBolting,
      PlantHealthIds.signalColdExposure,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_seedstalk_bolting',
        labelEs: 'Espigado / tallo floral',
        scientificName: 'Falla fisiologica de calidad',
        type: 'physiological_failure',
        summaryEs:
            'Emision de tallo floral no deseado, con bulbo duro/deformado. Se asocia a planta grande expuesta a frio/vernalizacion, variedad sensible, fecha incorrecta y estres. No es floracion productiva.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si el tallo central empieza a alargarse.',
      'Relaciona con frio en planta grande, set grande o fecha incorrecta.',
      'Si hay tallo floral, decide cosecha/cierre; no lo trates como bulbo normal.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Decidir cosecha o cierre segun calidad comercial restante.',
      'Registrar frio, edad, fecha, set y variedad para el siguiente ciclo.',
      'No fertilizar para "recuperar" un bulbo espigado.',
    ],
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_excess_n_thick_neck_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Cuello grueso, follaje muy verde tarde y madurez retrasada',
    stages: _storageStages,
    organIds: <String>{
      PlantHealthIds.organNeck,
      PlantHealthIds.organBulb,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomThickNeck,
    strongSignals: <String>{
      PlantHealthIds.signalThickNeck,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_excess_n_thick_neck',
        labelEs: 'Exceso de N / cuello grueso / mala maduracion',
        scientificName: 'Desbalance nutricional y de manejo',
        type: 'nutrition_risk',
        summaryEs:
            'N alto o tardio mantiene hoja verde, engruesa cuello, retrasa madurez y empeora conservacion; sube riesgo de Botrytis, bacterias y bulbos dobles.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si el cuello no cierra y el follaje sigue muy verde tarde.',
      'Relaciona con N tardio, N residual alto o riego tardio.',
      'Detener N y priorizar maduracion y curado.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'onion_water_deficit_bulb_quality_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Bulbo chico, partido o doble por agua irregular',
    stages: _bulbStages,
    organIds: <String>{
      PlantHealthIds.organBulb,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomBulbSplitting,
    strongSignals: <String>{
      PlantHealthIds.signalBulbSplitting,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHeatStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_water_deficit_bulb_quality',
        labelEs: 'Deficit hidrico en bulbo / calibre bajo',
        scientificName: 'Estres abiotico por agua irregular',
        type: 'abiotic',
        summaryEs:
            'En induccion/llenado la falta o irregularidad de agua reduce calibre y puede causar bulbos partidos o dobles. La cebolla no siempre se marchita de forma evidente.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa humedad real en zona de raiz (10-30 cm) antes de fertilizar.',
      'Confirma si hubo riego irregular o rehidratacion brusca.',
      'Relaciona con calor y viento en la etapa de bulbo.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_salinity_quality_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Puntas quemadas, bajo vigor y bulbo chico por sales',
    stages: _allOnionStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalLeafEdgeBurn,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_salinity_quality',
        labelEs: 'Estres salino / CE alta',
        scientificName: 'Estres abiotico por salinidad/sodio/boro',
        type: 'abiotic',
        summaryEs:
            'Cebolla es sensible a sales: CE alta reduce emergencia, vigor, calibre y calidad. No se corrige agregando fertilizante; revisa agua, drenaje y lavado.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa CE de suelo/agua junto con humedad.',
      'Si el patron es uniforme, pensar en sales antes que enfermedad.',
      'No subir N/K si la CE ya esta en alerta.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'onion_compaction_deformed_bulb_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Bulbo deforme y raiz limitada por suelo duro',
    stages: _rootStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomDeformedBulb,
    strongSignals: <String>{
      PlantHealthIds.signalDeformedNoRot,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_compaction_deformed_bulb',
        labelEs: 'Compactacion / bulbo deforme',
        scientificName: 'Limitacion fisica del suelo',
        type: 'physical',
        summaryEs:
            'Resistencia alta o capa dura limita raiz superficial y agua disponible; bulbos pequenos o deformes y drenaje pobre. No se arregla con mas fertilizante.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si hay humedad suficiente pero poco crecimiento.',
      'Confirma raiz corta, suelo duro o capa compactada.',
      'Relaciona con encharque o costra superficial.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'onion_poor_curing_storage_01',
    cropId: CropCatalog.onionCropId,
    labelEs: 'Cuello humedo tras cosecha y riesgo de almacenamiento',
    stages: _storageStages,
    organIds: <String>{PlantHealthIds.organNeck, PlantHealthIds.organBulb},
    primarySymptomId: PlantHealthIds.symptomPoorCuringNeckMoist,
    strongSignals: <String>{
      PlantHealthIds.signalPoorCuringNeckMoist,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'onion_poor_curing_storage',
        labelEs: 'Curado deficiente / riesgo de almacenamiento',
        scientificName: 'Trastorno de calidad poscosecha',
        type: 'quality_disorder',
        summaryEs:
            'Cuello humedo, piel floja o curado incompleto suben pudriciones en bodega. El rendimiento comercial no es solo peso: necesita cuello seco, curado y baja humedad.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si el cuello quedo humedo, grueso o mal seco.',
      'Confirma ventilacion, HR y madurez al cosechar.',
      'No prometer almacenamiento si hubo N tardio, lluvia o heridas.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _bulbActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.onionCropId,
        varietyIds: _redVarieties,
        diagnosisIds: <String>{'onion_poor_curing_storage'},
        scoreDelta: 3,
        rationaleEs:
            'En morada, color y piel sufren mas con humedad y curado deficiente.',
      ),
      VarietyModifier(
        cropId: CropCatalog.onionCropId,
        varietyIds: _storageVarieties,
        diagnosisIds: <String>{'onion_poor_curing_storage'},
        scoreDelta: 4,
        rationaleEs:
            'Bodega/almacenamiento exige curado y cuello seco para conservar.',
      ),
    ],
  ),
];
