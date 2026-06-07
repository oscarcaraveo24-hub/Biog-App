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

const Set<PlantHealthStageBucket> _rootBulbStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _bulbStorageStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _allGarlicStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const String _disclaimer =
    'Diagnostico sugerido. BIO-G orienta riesgo, monitoreo y manejo cultural; confirma en campo y con apoyo tecnico local si el dano avanza. No prescribe ingredientes activos ni recetas de plaguicidas.';

const List<String> _baseActions = <String>[
  'Marcar focos por cama o zona y revisar avance en 24-48 horas.',
  'Separar problema sanitario de riego, CE, frio, diente-semilla y curado.',
  'Registrar fotos, etapa, humedad, temperatura, riego y fertilizacion reciente.',
  'No mover dientes, bulbos, suelo ni herramienta de focos a zonas sanas.',
];

const List<String> _seedBulbActions = <String>[
  'Abrir dientes/bulbos sospechosos y revisar olor, moho, plato basal y escamas.',
  'Separar diente-semilla o bulbos blandos, mohosos o heridos.',
  'Revisar procedencia, curado, almacenamiento y manejo de golpes.',
  'No usar fertilizante para compensar semilla enferma o mal curada.',
];

const List<String> _foliarActions = <String>[
  'Revisar enves, pliegues, cuello y hojas internas.',
  'Reducir mojado foliar tardio y mejorar ventilacion del dosel.',
  'No subir N si hay HR alta, CE alta, follaje muy verde o maduracion cercana.',
  'Confirmar patron y avance antes de escalar manejo sanitario.',
];

const List<String> _rootActions = <String>[
  'Sacar plantas completas y revisar raiz, plato basal, cuello y olor.',
  'Diferenciar pudricion/anoxia de salinidad, compactacion o falta de agua.',
  'Revisar historial de Allium, rotacion y zonas bajas del lote.',
  'Evitar mover suelo o residuos enfermos hacia otros lotes.',
];

const List<String> _abioticActions = <String>[
  'Cruzar sintomas con agua, CE, temperatura, raiz, etapa y fertilizacion.',
  'Si el patron es uniforme, pensar primero en ambiente, sales o manejo.',
  'No corregir con NPK fuerte sin confirmar agua, salinidad y oxigenacion.',
  'Registrar el evento para ajustar fecha, perfil y manejo del siguiente ciclo.',
];

/// Catalogo de riesgos / sanidad vegetal de ajo (`crop_garlic`).
///
/// No diagnostica de forma absoluta. Los diferenciales se expresan como
/// "compatible con", "riesgo de" o "condiciones favorables a".
const List<PlantHealthSyndrome> garlicSyndromes = <PlantHealthSyndrome>[
  PlantHealthSyndrome(
    id: 'garlic_seed_clove_decay_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Diente-semilla blando, mohoso o con mala nacencia',
    stages: _earlyStages,
    organIds: <String>{
      PlantHealthIds.organSeedClove,
      PlantHealthIds.organBulb,
      PlantHealthIds.organRoot,
    },
    primarySymptomId: PlantHealthIds.symptomBlueGreenMold,
    strongSignals: <String>{
      PlantHealthIds.signalSeedCloveBlueGreenMold,
      PlantHealthIds.signalSoftCloveBeforePlanting,
      PlantHealthIds.signalPoorEmergence,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_penicillium_blue_mold',
        labelEs: 'Compatible con Penicillium / moho azul',
        scientificName: 'Penicillium spp.',
        type: 'fungus_storage_seed',
        summaryEs:
            'Moho azul-verde en diente o escama, mas comun en semilla golpeada, mal curada o almacenada con humedad.',
      ),
      PlantHealthDiagnosis(
        id: 'garlic_black_mold_storage',
        labelEs: 'Riesgo de moho negro en almacenamiento',
        scientificName: 'Aspergillus niger',
        type: 'fungus_storage',
        summaryEs:
            'Polvo negro bajo escamas o en dientes, favorecido por calor, heridas y curado/almacenamiento deficiente.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalBlackMoldSpores},
      ),
      PlantHealthDiagnosis(
        id: 'garlic_bacterial_soft_rot_seed',
        labelEs: 'Compatible con pudricion blanda bacteriana',
        scientificName: 'Complejo bacteriano de pudricion blanda',
        type: 'bacteria',
        summaryEs:
            'Diente blando, acuoso o con olor agrio. Suele avanzar con heridas, exceso de humedad y mala ventilacion.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalBulbScaleWaterSoaked,
          PlantHealthIds.signalSourSmell,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Abre dientes con mala nacencia y busca moho azul-verde o tejido blando.',
      'Compara semilla nueva contra semilla almacenada por mas tiempo.',
      'Revisa si hubo golpes, humedad alta o curado incompleto.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _seedBulbActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_basal_root_rot_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Plato basal cafe, raices pobres o planta amarilla',
    stages: _rootBulbStages,
    organIds: <String>{
      PlantHealthIds.organBasalPlate,
      PlantHealthIds.organRoot,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomBasalPlateBrownRot,
    strongSignals: <String>{
      PlantHealthIds.signalBasalPlateBrownRot,
      PlantHealthIds.signalPinkRoots,
      PlantHealthIds.signalRootsDarkRot,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_fusarium_basal_rot',
        labelEs: 'Compatible con Fusarium basal rot',
        scientificName: 'Fusarium oxysporum f. sp. cepae / Fusarium spp.',
        type: 'fungus',
        summaryEs:
            'Pudricion seca desde plato basal, raices pobres y amarillamiento. Sube con suelo calido, heridas, semilla infectada y estres.',
      ),
      PlantHealthDiagnosis(
        id: 'garlic_pink_root',
        labelEs: 'Compatible con raiz rosada',
        scientificName: 'Setophoma terrestris',
        type: 'fungus',
        summaryEs:
            'Raices rosadas/rojizas que se secan; plantas enanas y bulbos chicos. El historial de Allium y el estres elevan riesgo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalPinkRoots},
      ),
    ],
    confirmationChecksEs: <String>[
      'Corta la base y confirma si la pudricion inicia en plato basal.',
      'Busca raices rosadas, rojas o moradas en plantas vivas.',
      'Diferencia de anoxia por suelo saturado o compactado.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_white_rot_sclerotinia_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Micelio blanco, esclerocios o pudricion regional de base',
    stages: _rootBulbStages,
    organIds: <String>{
      PlantHealthIds.organBasalPlate,
      PlantHealthIds.organRoot,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomWhiteMyceliumSclerotia,
    strongSignals: <String>{
      PlantHealthIds.signalWhiteMyceliumSclerotia,
      PlantHealthIds.signalWaterlogging,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_white_rot',
        labelEs: 'Compatible con white rot',
        scientificName: 'Sclerotium cepivorum',
        type: 'fungus_quarantine_risk',
        summaryEs:
            'Micelio blanco y esclerocios negros en raiz/base. Puede persistir en suelo y requiere extrema precaucion con movimiento de suelo, bulbos y herramientas.',
      ),
      PlantHealthDiagnosis(
        id: 'garlic_sclerotinia_southern_blight',
        labelEs: 'Riesgo regional de Sclerotinia / southern blight',
        scientificName: 'Sclerotinia spp. / Sclerotium rolfsii',
        type: 'fungus_regional',
        summaryEs:
            'Pudriciones de cuello/base favorecidas por humedad, residuos y condiciones regionales. Confirmar patron y estructuras del hongo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca micelio blanco y bolitas negras en base o escamas externas.',
      'Revisa si el foco sigue lineas de riego, zonas bajas o residuos.',
      'Evita mover suelo o bulbos del foco a otras zonas.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_neck_soft_storage_rot_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Cuello blando, escamas acuosas o pudricion en curado',
    stages: _bulbStorageStages,
    organIds: <String>{
      PlantHealthIds.organNeck,
      PlantHealthIds.organBulb,
      PlantHealthIds.organBasalPlate,
    },
    primarySymptomId: PlantHealthIds.symptomNeckSoftRot,
    strongSignals: <String>{
      PlantHealthIds.signalNeckSoft,
      PlantHealthIds.signalGrayMoldNeck,
      PlantHealthIds.signalBulbScaleWaterSoaked,
      PlantHealthIds.signalPoorCuringNeckMoist,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_botrytis_neck_rot',
        labelEs: 'Compatible con Botrytis neck rot',
        scientificName: 'Botrytis spp.',
        type: 'fungus_storage',
        summaryEs:
            'Cuello blando y moho gris en curado/almacenamiento. Favorecido por HR alta, curado lento, heridas y N/riego tardio.',
      ),
      PlantHealthDiagnosis(
        id: 'garlic_bacterial_soft_rot_complex',
        labelEs: 'Riesgo de complejo bacteriano blando',
        scientificName: 'Pectobacterium / Burkholderia / bacterias blandas',
        type: 'bacteria',
        summaryEs:
            'Escamas acuosas, olor agrio y tejido blando. Se favorece por heridas, calor y humedad excesiva.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Presiona cuello y revisa si esta blando, humedo o con moho gris.',
      'Abre bulbos y busca escamas internas acuosas u olor agrio.',
      'Relaciona con riego/N tardio, cosecha con cuello verde o curado lento.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _seedBulbActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_foliar_disease_complex_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Manchas foliares, pustulas, mildiu o blight en hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organNeck},
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalDownyFuzzyGrowth,
      PlantHealthIds.signalPurpleConcentricLesions,
      PlantHealthIds.signalDarkOliveLeafBlight,
      PlantHealthIds.signalSporesRubOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_rust',
        labelEs: 'Compatible con roya',
        scientificName: 'Puccinia allii',
        type: 'fungus',
        summaryEs:
            'Pustulas anaranjadas o rojizas que sueltan polvo. Favorece humedad y dosel cerrado; puede reducir area foliar para llenar bulbo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSporesRubOff},
      ),
      PlantHealthDiagnosis(
        id: 'garlic_downy_mildew',
        labelEs: 'Riesgo de mildiu velloso',
        scientificName: 'Peronospora destructor',
        type: 'oomycete',
        summaryEs:
            'Crecimiento velloso gris/morado en hoja con clima fresco-humedo y rocio. Puede avanzar rapido por manchones.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalDownyFuzzyGrowth,
          PlantHealthIds.signalCoolDewyWindow,
        },
      ),
      PlantHealthDiagnosis(
        id: 'garlic_purple_blotch_stemphylium',
        labelEs: 'Compatible con mancha purpura / Stemphylium',
        scientificName: 'Alternaria porri / Stemphylium vesicarium',
        type: 'fungus',
        summaryEs:
            'Lesiones purpuras, pajizas u oliva que coalescen. Favorece humedad alta, hoja mojada y tejido debilitado.',
      ),
      PlantHealthDiagnosis(
        id: 'garlic_botrytis_leaf_blight',
        labelEs: 'Compatible con Botrytis leaf blight',
        scientificName: 'Botrytis spp.',
        type: 'fungus',
        summaryEs:
            'Puntos blancos o manchas foliares que avanzan con humedad y follaje denso. Vigilar porque la hoja llena el bulbo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si las pustulas sueltan polvo al frotar.',
      'Busca esporulacion en enves temprano por la manana.',
      'Diferencia manchas con mordidas de trips o fitotoxicidad uniforme.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _foliarActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_virus_mosaic_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Mosaico, rayado, enanismo o lote desuniforme',
    stages: _allGarlicStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalLeafRolling,
      PlantHealthIds.signalThripsPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_virus_mosaic_complex',
        labelEs: 'Compatible con virus/mosaicos de ajo',
        scientificName: 'Complejo viral de ajo',
        type: 'virus',
        summaryEs:
            'Mosaico, rayado, deformacion y bajo vigor. En ajo propagado por diente, la semilla puede mover virus entre ciclos; vectores agravan diseminacion.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirma si el patron viene desde semilla o aparece por focos.',
      'Revisa trips, afidos u otros vectores y Allium voluntarios.',
      'Compara plantas de distintos lotes de diente-semilla.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_thrips_leafminer_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Raspado plateado, minas o dano en hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organNeck},
    primarySymptomId: PlantHealthIds.symptomThripsSilverScarring,
    strongSignals: <String>{
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalThripsSilverScarring,
      PlantHealthIds.signalLeafMines,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_thrips',
        labelEs: 'Compatible con trips',
        scientificName: 'Thrips tabaci / trips spp.',
        type: 'insect',
        summaryEs:
            'Raspado plateado/bronceado y presencia en pliegues/cuello. Reduce area foliar y puede abrir puerta a enfermedades.',
      ),
      PlantHealthDiagnosis(
        id: 'garlic_leafminers',
        labelEs: 'Compatible con minadores de hoja',
        scientificName: 'Liriomyza spp. / minadores',
        type: 'insect',
        summaryEs:
            'Galerias internas en hoja. Distinguir de manchas fungicas porque la mina sigue trayectoria.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalLeafMines},
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa pliegues y cuello con lupa para trips.',
      'Distingue raspado superficial de galerias internas.',
      'Busca bordes de lote, malezas y Allium vecinos.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _foliarActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_soil_insects_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Fallas de stand, larvas, mordidas o diente comido',
    stages: _earlyStages,
    organIds: <String>{
      PlantHealthIds.organSeedClove,
      PlantHealthIds.organRoot,
      PlantHealthIds.organBasalPlate,
    },
    primarySymptomId: PlantHealthIds.symptomMaggotStandLoss,
    strongSignals: <String>{
      PlantHealthIds.signalMaggotLarvae,
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalActiveChewing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_maggots_wireworms_soil_insects',
        labelEs: 'Compatible con maggots, wireworms o insectos de suelo',
        scientificName: 'Delia spp. / gusanos alambre / insectos de suelo',
        type: 'insect_soil',
        summaryEs:
            'Larvas en base/diente, fallas de stand o mordidas subterraneas. Revisar si el dano coincide con materia organica, residuos o historial.',
      ),
      PlantHealthDiagnosis(
        id: 'garlic_cutworms',
        labelEs: 'Riesgo de trozadores/cutworms',
        scientificName: 'Agrotis spp. y otros',
        type: 'insect',
        summaryEs:
            'Plantas cortadas o mordidas cerca del suelo, especialmente en bordes o maleza previa.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Escarba alrededor de plantas faltantes y busca larvas o mordidas.',
      'Revisa bordes, residuos y maleza previa.',
      'Diferencia falla de emergencia por semilla enferma.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'garlic_mites_nematodes_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Bulbo deformado, cicatrices, raices noduladas o planta enana',
    stages: _allGarlicStages,
    organIds: <String>{
      PlantHealthIds.organBulb,
      PlantHealthIds.organRoot,
      PlantHealthIds.organSeedClove,
    },
    primarySymptomId: PlantHealthIds.symptomBulbMiteScars,
    strongSignals: <String>{
      PlantHealthIds.signalBulbMiteBrownScars,
      PlantHealthIds.signalDistortedSpongyBulb,
      PlantHealthIds.signalRootGalls,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_bulb_eriophyid_mites',
        labelEs: 'Compatible con acaros de bulbo / eriofidos',
        scientificName: 'Rhizoglyphus spp. / Aceria tulipae',
        type: 'mite',
        summaryEs:
            'Cicatrices, polvo, deformacion o dientes esponjosos. Puede moverse con diente-semilla y empeorar en almacenamiento.',
      ),
      PlantHealthDiagnosis(
        id: 'garlic_stem_bulb_nematode',
        labelEs: 'Riesgo de nematodo de tallo y bulbo',
        scientificName: 'Ditylenchus dipsaci',
        type: 'nematode',
        summaryEs:
            'Bulbo hinchado, deformado o esponjoso y crecimiento irregular. Confirmar con muestra; no mover semilla sospechosa.',
      ),
      PlantHealthDiagnosis(
        id: 'garlic_root_nematodes',
        labelEs: 'Riesgo de nematodos de raiz',
        scientificName: 'Meloidogyne spp. / Paratrichodorus spp.',
        type: 'nematode',
        summaryEs:
            'Raices con agallas o raices cortas, planta frenada y bulbo chico. Confirmar con patron y analisis si avanza.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRootGalls},
      ),
    ],
    confirmationChecksEs: <String>[
      'Abre bulbos y busca cicatrices, polvo, acaros o tejido esponjoso.',
      'Revisa raices con agallas o raiz corta tipo stubby.',
      'Diferencia de dano por compactacion/salinidad.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _seedBulbActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'garlic_slugs_weeds_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Mordidas superficiales, baba o competencia fuerte de maleza',
    stages: _allGarlicStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalWeedCompetition,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_slugs_snails_conditional',
        labelEs: 'Riesgo condicional de babosas/caracoles',
        scientificName: 'Slugs / snails',
        type: 'mollusk',
        summaryEs:
            'Mordidas y dano superficial en ambientes humedos, sombreados o con residuos. Confirmar con revision nocturna o temprano.',
      ),
      PlantHealthDiagnosis(
        id: 'garlic_weeds_competition',
        labelEs: 'Competencia de malezas / Allium voluntario',
        scientificName: 'Maleza y voluntarios',
        type: 'weed_competition',
        summaryEs:
            'Maleza compite por luz, agua, nutrientes y puede hospedar vectores o enfermedades. En ajo temprano pega fuerte al calibre final.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca baba, mordidas nocturnas o refugios humedos.',
      'Revisa cobertura de maleza, bordes y voluntarios de Allium.',
      'Distingue mordida real de mancha foliar o fitotoxicidad.',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_vernalization_failure_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Mucha hoja pero pocos dientes o mala diferenciacion',
    stages: _bulbStorageStages,
    organIds: <String>{PlantHealthIds.organBulb, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomPoorCloveDifferentiation,
    strongSignals: <String>{
      PlantHealthIds.signalPoorCloveDifferentiation,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalNoBulbPhotoperiod,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_insufficient_cold_differentiation',
        labelEs: 'Compatible con frio insuficiente / mala diferenciacion',
        scientificName: 'Desorden fisiologico',
        type: 'abiotic_physiology',
        summaryEs:
            'Falta de frio o perfil mal adaptado limita diferenciacion de dientes aunque el cultivo este verde. NPK no corrige vernalizacion.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa fecha de plantacion, perfil AG y historial de frio.',
      'Abre bulbos y confirma dientes pocos, grandes o mal definidos.',
      'Diferencia de N tardio, salinidad o diente-semilla de mala calidad.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_brooming_scape_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Escobeteado, canutos, escapo o dientes expuestos',
    stages: _bulbStorageStages,
    organIds: <String>{PlantHealthIds.organBulb, PlantHealthIds.organStem},
    primarySymptomId: PlantHealthIds.symptomExposedClovesBrooming,
    strongSignals: <String>{
      PlantHealthIds.signalExposedClovesBrooming,
      PlantHealthIds.signalUnexpectedScape,
      PlantHealthIds.signalLateGreenExcessVigor,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_brooming_scape_canutos',
        labelEs: 'Compatible con escobeteado / canutos / escapo no esperado',
        scientificName: 'Desorden fisiologico de Allium',
        type: 'abiotic_physiology',
        summaryEs:
            'Dientes expuestos, escapo o bulbo abierto por frio irregular, estres, variedad, manejo de N/agua o cosecha tardia.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si hay escapo/canuto o dientes expuestos en varios sectores.',
      'Cruza con frio, golpes de calor, N tardio, riego irregular y perfil.',
      'No intentes corregir con mas NPK; evalua descarte y cosecha.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_excess_late_n_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Follaje muy verde tarde, cuello blando o maduracion retrasada',
    stages: _bulbStorageStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organNeck,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomThickNeck,
    strongSignals: <String>{
      PlantHealthIds.signalLateGreenExcessVigor,
      PlantHealthIds.signalThickNeck,
      PlantHealthIds.signalPoorCuringNeckMoist,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_excess_late_n',
        labelEs: 'Riesgo por exceso de N tardio',
        scientificName: 'Manejo nutricional',
        type: 'management_nutrition',
        summaryEs:
            'N tarde puede mantener vigor, retrasar madurez, favorecer escobeteado/canutos, pudriciones y mal curado.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa aplicaciones recientes de N y riego.',
      'Confirma si el cuello sigue verde/blando cerca de cosecha.',
      'Cruza con CE alta o humedad excesiva.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'garlic_water_deficit_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Deficit hidrico, bulbo chico o puntas secas',
    stages: _rootBulbStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organBulb},
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalLeafEdgeBurn,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_water_deficit',
        labelEs: 'Compatible con deficit hidrico',
        scientificName: 'Estres hidrico',
        type: 'abiotic_water',
        summaryEs:
            'Secados fuertes reducen raiz, diferenciacion, llenado y calibre. Puede parecer deficiencia nutrimental si no se revisa humedad.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa humedad real en zona de raiz, no solo superficie.',
      'Cruza con calor, viento y etapa de llenado.',
      'No diagnosticar NPK sin confirmar agua.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_waterlogging_anoxia_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Exceso de humedad, anoxia o raiz negra',
    stages: _rootBulbStages,
    organIds: <String>{PlantHealthIds.organRoot, PlantHealthIds.organBulb},
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalBulbScaleWaterSoaked,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_waterlogging_anoxia',
        labelEs: 'Compatible con exceso de humedad / anoxia',
        scientificName: 'Estres hidrico + complejo radicular',
        type: 'abiotic_water_root_complex',
        summaryEs:
            'Suelo saturado reduce oxigeno, limita raiz y favorece pudriciones. No se debe interpretar automaticamente como falta de nutriente.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si la planta se marchita con suelo humedo.',
      'Verifica drenaje, compactacion y zonas bajas.',
      'Saca plantas completas y huele/observa raiz y base.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_salinity_compaction_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Salinidad, raiz limitada o bulbo deforme',
    stages: _allGarlicStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organBulb,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomDeformedBulb,
    strongSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalDeformedNoRot,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_salinity',
        labelEs: 'Riesgo por salinidad / CE alta',
        scientificName: 'Estres salino',
        type: 'abiotic_salinity',
        summaryEs:
            'Ajo es sensible a sales. CE alta reduce absorcion de agua, raiz, calibre y curado; no subir fertilizante como primera respuesta.',
      ),
      PlantHealthDiagnosis(
        id: 'garlic_compaction',
        labelEs: 'Riesgo por compactacion',
        scientificName: 'Restriccion fisica de raiz',
        type: 'abiotic_soil_structure',
        summaryEs:
            'Raiz limitada y bulbo deforme por costra, suelo pesado o resistencia alta. Puede confundirse con deficiencia.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa CE, agua de riego y acumulacion de sales.',
      'Evalua resistencia/costra y profundidad efectiva de raiz.',
      'Confirma si el patron es uniforme por cama o lote.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_phytotoxicity_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Quemadura uniforme, deformacion o dano tras manejo reciente',
    stages: _allGarlicStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalUniformLeafBurn,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalCannotScrapeOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_phytotoxicity',
        labelEs: 'Compatible con fitotoxicidad',
        scientificName: 'Dano por manejo/insumo/ambiente',
        type: 'abiotic_phytotoxicity',
        summaryEs:
            'Quemadura o deformacion uniforme tras aplicacion, sales, calor, frio o mezcla. Diferenciar de enfermedad porque no sigue foco infeccioso.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa fecha de aplicacion, mezcla, dosis, hora y clima.',
      'Confirma si el patron es uniforme y coincide con paso de equipo.',
      'Diferencia de roya/manchas que suelen tener estructuras o focos.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_poor_curing_storage_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Mal curado, brotacion o perdida en almacenamiento',
    stages: _bulbStorageStages,
    organIds: <String>{PlantHealthIds.organBulb, PlantHealthIds.organNeck},
    primarySymptomId: PlantHealthIds.symptomPoorCuringNeckMoist,
    strongSignals: <String>{
      PlantHealthIds.signalPoorCuringNeckMoist,
      PlantHealthIds.signalStorageSprouting,
      PlantHealthIds.signalNeckSoft,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_poor_curing',
        labelEs: 'Compatible con curado deficiente',
        scientificName: 'Manejo poscosecha',
        type: 'postharvest_management',
        summaryEs:
            'Cuello humedo, bulbo blando o pudriciones por cosecha/curado con humedad, golpes, poco aire o N/riego tardio.',
      ),
      PlantHealthDiagnosis(
        id: 'garlic_storage_sprouting',
        labelEs: 'Riesgo de brotacion en almacenamiento',
        scientificName: 'Desorden poscosecha',
        type: 'postharvest_physiology',
        summaryEs:
            'Brotacion por curado/almacenamiento deficiente, temperatura, humedad o madurez incorrecta.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalStorageSprouting},
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa cuello, ventilacion, humedad y temperatura de almacenamiento.',
      'Separa bulbos blandos, brotados o con olor.',
      'Registra si hubo N/riego tardio o cosecha inmadura.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _seedBulbActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'garlic_sunscald_postharvest_01',
    cropId: CropCatalog.garlicCropId,
    labelEs: 'Asoleado, escamas quemadas o dano poscosecha',
    stages: _bulbStorageStages,
    organIds: <String>{PlantHealthIds.organBulb},
    primarySymptomId: PlantHealthIds.symptomSunscaldOuterScales,
    strongSignals: <String>{
      PlantHealthIds.signalSunscaldOuterScales,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'garlic_sunscald_postharvest_damage',
        labelEs: 'Compatible con asoleado / dano poscosecha',
        scientificName: 'Dano por sol, calor o golpes',
        type: 'postharvest_abiotic',
        summaryEs:
            'Escamas externas quemadas, deshidratadas o con dano por exposicion al sol/calor tras cosecha. Puede bajar calidad comercial y almacenamiento.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si el dano esta en el lado expuesto al sol.',
      'Confirma tiempo de exposicion, temperatura y manejo de golpes.',
      'Diferencia de mohos: no debe haber esporulacion activa.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _seedBulbActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
];
