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

const Set<PlantHealthStageBucket> _qualityStages = <PlantHealthStageBucket>{
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
};

const Set<PlantHealthStageBucket> _allSpinachStages =
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

const Set<String> _babyLeafVarieties = <String>{
  'spinach_smooth_baby',
  'sp_03',
};

const Set<String> _processVarieties = <String>{
  'spinach_processing',
  'sp_05',
};

const String _disclaimer =
    'Diagnostico sugerido. BIO-G orienta riesgo, monitoreo y manejo cultural; confirma en campo y con apoyo tecnico local si el dano avanza. No prescribe pesticidas.';

const List<String> _baseActions = <String>[
  'Marcar focos por cama o zona y revisar avance en 24-48 horas.',
  'Separar problema sanitario de riego, CE, calor o compactacion.',
  'Retirar hojas o plantas muy afectadas si ya son fuente de inoculo.',
  'Registrar fotos, etapa, humedad, temperatura y manejo reciente.',
];

const List<String> _leafQualityActions = <String>[
  'Priorizar hoja limpia, turgente y cosecha oportuna sobre mas crecimiento.',
  'Revisar enves, hojas internas, ventilacion y mojado foliar.',
  'Evitar subir N si hay calor, CE alta, HR alta o corte cercano.',
  'Documentar calidad comercial antes de decidir cosecha o cierre.',
];

const List<String> _rootActions = <String>[
  'Revisar raiz, cuello, drenaje y compactacion antes de asumir falta de nutriente.',
  'Corregir riego largo, cama baja, encharque o costra superficial.',
  'Comparar focos con zonas de mejor drenaje.',
  'Registrar humedad, resistencia y olor/color de raiz.',
];

const List<String> _vectorActions = <String>[
  'Revisar enves de hojas, bordes, malezas y cultivos vecinos.',
  'Distinguir dano directo de plaga contra sintomas compatibles con virus.',
  'Manejar malezas hospederas y focos sin recetar ingredientes activos.',
  'Confirmar vector, patron y avance antes de escalar manejo.',
];

const List<String> _abioticActions = <String>[
  'Cruzar sintomas con riego, CE, temperatura, raiz y etapa.',
  'Si el patron es uniforme, pensar primero en ambiente, sales o manejo.',
  'No corregir con fertilizante fuerte sin confirmar agua y salinidad.',
  'Usar la lectura para ajustar el siguiente ciclo si el cultivo ya esta tarde.',
];

/// Catalogo de riesgos / sanidad vegetal de espinaca (`crop_spinach`).
///
/// La salida es compatible con "revise/confirme"; no receta plaguicidas ni
/// ingredientes activos.
const List<PlantHealthSyndrome> spinachSyndromes = <PlantHealthSyndrome>[
  PlantHealthSyndrome(
    id: 'spinach_damping_off_01',
    cropId: CropCatalog.spinachCropId,
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
        id: 'spinach_damping_off',
        labelEs: 'Damping-off / chupadera',
        scientificName: 'Pythium spp. / Rhizoctonia solani / Fusarium spp.',
        type: 'fungus_oomycete',
        summaryEs:
            'Plantulas colapsadas por cuello o raiz joven. Se favorece por suelo saturado, costra, baja ventilacion y salinidad en arranque.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa cuello oscuro o estrangulado en plantulas caidas.',
      'Confirma si el suelo estuvo saturado o con costra.',
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
    id: 'spinach_root_rot_complex_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Marchitez con raiz oscura o cuello podrido',
    stages: _rootStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalWaterlogging,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_root_rot_complex',
        labelEs: 'Complejo de pudricion de raiz',
        scientificName: 'Pythium spp. / Rhizoctonia spp. / Phytophthora spp.',
        type: 'root_disease_complex',
        summaryEs:
            'Raiz limitada, oscura o podrida con planta frenada. Exceso de agua, suelo frio, compactacion y salinidad aumentan el riesgo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Saca plantas completas y revisa raiz fina, cuello y olor.',
      'Verifica si el foco coincide con riego largo o drenaje flojo.',
      'No subir fertilizante hasta separar raiz enferma de falta de nutriente.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_fusarium_wilt_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Marchitez progresiva con pardeamiento vascular',
    stages: _rootStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomWiltVascular,
    strongSignals: <String>{
      PlantHealthIds.signalVascularBrowning,
      PlantHealthIds.signalOneSidedWilt,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_fusarium_wilt',
        labelEs: 'Fusarium wilt / marchitez vascular',
        scientificName: 'Fusarium oxysporum f. sp. spinaciae',
        type: 'fungus',
        summaryEs:
            'Marchitez y amarillamiento con tejido vascular cafe. Suele avanzar por focos y se agrava con suelo caliente y estres.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Corta corona o raiz y busca pardeamiento vascular.',
      'Ubica si el problema avanza por lineas o parches repetidos.',
      'Revisa historial del lote y rotacion.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_downy_mildew_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Manchas amarillas con enves gris o morado',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAngularSpots,
    strongSignals: <String>{
      PlantHealthIds.signalPurpleDownySporulation,
      PlantHealthIds.signalUndersideSporulation,
      PlantHealthIds.signalDenseWetCanopy,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_downy_mildew',
        labelEs: 'Mildiu velloso',
        scientificName: 'Peronospora effusa',
        type: 'oomycete',
        summaryEs:
            'Riesgo critico en hoja comercial. Se favorece con HR alta, mojado foliar, noches frescas y dosel cerrado.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Voltea la hoja temprano y busca esporulacion gris/morada.',
      'Relaciona con HR alta, rocio o riego que moja follaje.',
      'Revisa si el dano ya llega a hoja comercial.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _leafQualityActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.spinachCropId,
        varietyIds: _babyLeafVarieties,
        diagnosisIds: <String>{'spinach_downy_mildew'},
        scoreDelta: 6,
        rationaleEs:
            'Baby leaf pierde valor comercial rapido con mildiu o manchas.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'spinach_cladosporium_leaf_spot_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Manchas cafe claras o secas en hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomTanPaperySpots,
    strongSignals: <String>{
      PlantHealthIds.signalTanPaperySpots,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_cladosporium_leaf_spot',
        labelEs: 'Cladosporium leaf spot',
        scientificName: 'Cladosporium variabile',
        type: 'fungus',
        summaryEs:
            'Manchas foliares que bajan calidad visual. Sube con humedad alta, mojado foliar y residuos.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si las manchas son secas y se repiten en hojas medias.',
      'Confirma humedad alta o ventilacion limitada.',
      'Separa de bacteriosis si no hay halo acuoso.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_stemphylium_leaf_spot_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Manchas cafe secas con avance por humedad',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalTanPaperySpots,
      PlantHealthIds.signalDenseWetCanopy,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_stemphylium_leaf_spot',
        labelEs: 'Stemphylium leaf spot',
        scientificName: 'Stemphylium spp.',
        type: 'fungus',
        summaryEs:
            'Manchas necroticas en hoja; se favorece con humedad, tejido viejo y poca circulacion de aire.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si inicia en hojas viejas o zonas cerradas.',
      'Comprueba si se expande despues de HR alta o lluvia.',
      'Diferencia de minador: aqui no hay galeria interna.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_anthracnose_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Lesiones hundidas o necroticas en hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalWaterSoakedSpots,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_anthracnose',
        labelEs: 'Antracnosis',
        scientificName: 'Colletotrichum spp.',
        type: 'fungus',
        summaryEs:
            'Lesiones hundidas o necroticas que reducen hoja comercial; favorecida por humedad y salpicadura.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca lesiones hundidas, oscuras o con halo en hoja.',
      'Relaciona con salpicadura de suelo o lluvias recientes.',
      'Evita confundir con dano mecanico sin patron de avance.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_bacterial_leaf_spot_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Manchas acuosas o con halo en hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomWaterSoakedSpots,
    strongSignals: <String>{
      PlantHealthIds.signalWaterSoakedSpots,
      PlantHealthIds.signalHaloMargin,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_bacterial_leaf_spot',
        labelEs: 'Mancha bacteriana',
        scientificName: 'Pseudomonas spp. / Xanthomonas spp.',
        type: 'bacteria',
        summaryEs:
            'Manchas acuosas o angulares que contaminan hoja. Salpique, humedad y heridas aumentan riesgo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca halos acuosos o lesiones traslucidas.',
      'Relaciona con lluvia, riego por aspersion o manejo con hoja mojada.',
      'Separa de hongo si no hay esporulacion visible.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_white_rust_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Pustulas blancas o ampollas en hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomWhitePustules,
    strongSignals: <String>{
      PlantHealthIds.signalWhitePustules,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_white_rust',
        labelEs: 'Roya blanca',
        scientificName: 'Albugo occidentalis',
        type: 'oomycete',
        summaryEs:
            'Pustulas blancas en hoja que bajan calidad comercial. Aumenta con humedad alta y hojas mojadas.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca pustulas blancas elevadas en enves o haz.',
      'Confirma si coinciden con manchas amarillas del lado opuesto.',
      'Revisa humedad y densidad del dosel.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _leafQualityActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_botrytis_gray_mold_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Moho gris o necrosis humeda en hoja',
    stages: _qualityStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organCrown},
    primarySymptomId: PlantHealthIds.symptomGrayMoldNecrosis,
    strongSignals: <String>{
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalDenseWetCanopy,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_botrytis',
        labelEs: 'Botrytis / moho gris',
        scientificName: 'Botrytis cinerea',
        type: 'fungus',
        summaryEs:
            'Moho gris y tejido humedo en hoja o base; se favorece con HR alta, hoja vieja, exceso de N y poca ventilacion.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca moho gris afelpado en tejido viejo o dañado.',
      'Confirma dosel mojado o ventilacion insuficiente.',
      'Revisa si hay N alto o cosecha retrasada.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _leafQualityActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_virus_complex_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Mosaico, amarillamiento o hoja deformada',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalCrownDistortion,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_virus_complex',
        labelEs: 'Complejo viral',
        scientificName: 'Virus asociados a pulgones/trips/mosca blanca',
        type: 'insect_virus',
        summaryEs:
            'Mosaico, amarillamiento y deformacion. No hay cura directa; el enfoque es confirmar vector, focos y material sano.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa brotes nuevos y patron de mosaico.',
      'Busca pulgones, trips o mosca blanca en bordes y enves.',
      'Confirma si hay focos vecinos o malezas hospederas.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_leafminer_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Galerias o minas dentro de la hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomLeafMines,
    strongSignals: <String>{PlantHealthIds.signalLeafMines},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_leafminers',
        labelEs: 'Minadores de hoja',
        scientificName: 'Liriomyza spp. / Pegomya spp.',
        type: 'insect',
        summaryEs:
            'Galerias internas en hoja. En espinaca pesan mucho porque la hoja es el producto comercial.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Mira la hoja a contraluz y busca larva al final de la mina.',
      'Distingue de mancha: la mina sigue un trazo interno.',
      'Revisa si el dano llega a hojas comercializables.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.spinachCropId,
        varietyIds: _babyLeafVarieties,
        diagnosisIds: <String>{'spinach_leafminers'},
        scoreDelta: 5,
        rationaleEs: 'Baby leaf rechaza facilmente hoja con minas visibles.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'spinach_aphids_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Pulgones, melaza o contaminacion en hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAphidColonies,
    strongSignals: <String>{
      PlantHealthIds.signalAphidContamination,
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalVectorPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_aphids',
        labelEs: 'Pulgones',
        scientificName: 'Aphididae',
        type: 'insect',
        summaryEs:
            'Colonias en enves o brotes contaminan hoja comercial y pueden mover virus.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa enves, brote central y hojas internas.',
      'Busca melaza, fumagina o pulgones escondidos.',
      'Ubica malezas hospederas y cultivos vecinos.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_caterpillars_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Mordidas o perforaciones en hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalFrassPresent,
    },
    conflictingSignals: <String>{PlantHealthIds.signalNoBiteMarks},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_caterpillars',
        labelEs: 'Orugas / gusanos defoliadores',
        scientificName: 'Lepidoptera',
        type: 'insect',
        summaryEs:
            'Mordidas y excretas reducen valor de hoja; revisar actividad real antes de decidir manejo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca larvas y excretas, no solo perforaciones viejas.',
      'Revisa de noche o temprano si el dano parece fresco.',
      'Diferencia de babosas por ausencia de rastro brillante.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'spinach_crown_mite_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Corona deformada o brote central torcido',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organCrown, PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomLeafDistortion,
    strongSignals: <String>{
      PlantHealthIds.signalCrownDistortion,
      PlantHealthIds.signalMitesWebbing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_crown_mite',
        labelEs: 'Acaro de corona',
        scientificName: 'Tyrophagus / Rhizoglyphus complex',
        type: 'mite',
        summaryEs:
            'Deformacion de corona y hojas nuevas; puede confundirse con virus o fitotoxicidad.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa brote central y corona con lupa si es posible.',
      'Compara con sintomas de virus: busca vector y patron.',
      'Relaciona con residuos, humedad y estres previo.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_seedcorn_maggot_wireworm_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Semilla o plantula danada bajo suelo',
    stages: _earlyStages,
    organIds: <String>{PlantHealthIds.organRoot, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomPoorEmergence,
    strongSignals: <String>{
      PlantHealthIds.signalPoorEmergence,
      PlantHealthIds.signalDeadHeart,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_seedcorn_maggot_wireworm',
        labelEs: 'Gusano de semilla / gusano de alambre',
        scientificName: 'Delia platura / Elateridae',
        type: 'soil_insect',
        summaryEs:
            'Nacencia desuniforme por dano a semilla, raiz o plantula. Revisar suelo antes de resembrar.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Desentierra semilla/plantula y busca galerias o larvas.',
      'Relaciona con materia organica fresca o historial de plaga de suelo.',
      'Separa de damping-off si no hay cuello podrido.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'spinach_flea_beetles_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Perforaciones pequenas tipo perdigon',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalActiveChewing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_flea_beetles',
        labelEs: 'Pulguillas / flea beetles',
        scientificName: 'Chrysomelidae',
        type: 'insect',
        summaryEs:
            'Perforaciones pequenas y multiples que bajan calidad visual, sobre todo en hoja tierna.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca pequenos escarabajos saltadores en hojas o bordes.',
      'Revisa si el dano es de puntos pequenos y repetidos.',
      'Ubica entrada desde maleza o cultivos vecinos.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'spinach_slugs_snails_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Mordidas irregulares con rastro brillante',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalWaterlogging,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_slugs_snails',
        labelEs: 'Babosas / caracoles',
        scientificName: 'Gastropoda',
        type: 'mollusk',
        summaryEs:
            'Mordidas irregulares y rastro brillante. Suben con humedad, residuos y noches frescas.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca rastro brillante temprano o de noche.',
      'Revisa residuos, bordes y zonas humedas.',
      'Distingue de oruga por rastro y ausencia de excreta.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_nematodes_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Planta frenada con raiz con agallas o lesiones',
    stages: _rootStages,
    organIds: <String>{PlantHealthIds.organRoot, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomRootGalls,
    strongSignals: <String>{PlantHealthIds.signalRootGalls},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_nematodes',
        labelEs: 'Nematodos',
        scientificName: 'Meloidogyne spp. / Pratylenchus spp.',
        type: 'nematode',
        summaryEs:
            'Raiz con agallas o lesiones y crecimiento irregular. Se confirma con raiz y, si aplica, analisis local.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Saca raiz completa y busca agallas, lesiones o raiz pobre.',
      'Compara focos con historial del lote.',
      'No confundir con compactacion sin revisar raiz.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'spinach_bolting_heat_stress_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Tallo floral o espigado con perdida de calidad',
    stages: _qualityStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomBoltingStem,
    strongSignals: <String>{
      PlantHealthIds.signalBoltingStem,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_bolting_heat_stress',
        labelEs: 'Espigado / bolting por calor-edad',
        scientificName: 'Falla fisiologica de calidad',
        type: 'physiological_failure',
        summaryEs:
            'La espinaca cambia a tallo floral por calor, dias largos, edad o estres. La hoja pierde calidad aunque la planta siga creciendo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si el tallo central empieza a alargarse.',
      'Relaciona con calor sostenido o retraso de cosecha.',
      'Si hay tallo floral, no tratar como floracion util.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Cosechar de inmediato si aun hay calidad comercial.',
      'Cerrar ciclo si el tallo floral ya domina.',
      'Registrar calor, edad, riego y perfil SP para ajustar el proximo ciclo.',
    ],
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_water_deficit_quality_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Hoja flacida, marchitez o bordes secos',
    stages: _qualityStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalLeafEdgeBurn,
      PlantHealthIds.signalHeatStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_water_deficit_quality',
        labelEs: 'Estres hidrico y perdida de turgencia',
        scientificName: 'Estres abiotico por deficit de agua',
        type: 'abiotic',
        summaryEs:
            'Humedad insuficiente afecta turgencia, textura y vida de anaquel; puede parecer falta de nutriente.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa humedad real antes de subir fertilizante.',
      'Confirma si el dano coincide con calor, viento o riego irregular.',
      'Observa recuperacion de turgencia al bajar temperatura.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _leafQualityActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_waterlogging_anoxia_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Marchitez con suelo saturado o raiz sin oxigeno',
    stages: _rootStages,
    organIds: <String>{PlantHealthIds.organRoot, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_waterlogging_anoxia',
        labelEs: 'Exceso de humedad / anoxia',
        scientificName: 'Estres abiotico por saturacion',
        type: 'abiotic',
        summaryEs:
            'La planta puede verse marchita aunque haya agua. Saturacion prolongada reduce oxigeno y abre la puerta a pudriciones.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirma humedad alta o encharque antes de regar otra vez.',
      'Revisa olor/color de raiz.',
      'Ubica zonas bajas o compactadas.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_salinity_quality_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Bordes quemados, poca turgencia o crecimiento frenado por sales',
    stages: _allSpinachStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalLeafEdgeBurn,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_salinity_quality',
        labelEs: 'Estres salino y perdida de calidad',
        scientificName: 'Estres abiotico por CE alta',
        type: 'abiotic',
        summaryEs:
            'CE elevada reduce turgencia y calidad de hoja. En baby leaf/fresco pesa mas; no se corrige agregando fertilizante.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa CE junto con humedad; bulbo seco concentra sales.',
      'Pregunta por agua de riego salina o fertilizacion cargada.',
      'Si el patron es uniforme, pensar en sales antes que enfermedad.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.spinachCropId,
        varietyIds: _babyLeafVarieties,
        diagnosisIds: <String>{'spinach_salinity_quality'},
        scoreDelta: 5,
        rationaleEs: 'Baby leaf tiene mayor sensibilidad visual a CE alta.',
      ),
    ],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_compaction_root_limit_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Crecimiento irregular con raiz limitada',
    stages: _rootStages,
    organIds: <String>{PlantHealthIds.organRoot, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_compaction_root_limit',
        labelEs: 'Compactacion / raiz limitada',
        scientificName: 'Limitacion fisica del suelo',
        type: 'physical',
        summaryEs:
            'Resistencia alta limita raiz y agua disponible. La correccion real suele ser de preparacion de suelo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si el patron sigue lineas de maquinaria o parches.',
      'Confirma raiz corta y suelo duro.',
      'Relaciona con encharque o costra superficial.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'spinach_nutrient_imbalance_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Color irregular, hoja blanda o vigor desbalanceado',
    stages: _qualityStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalSalinityLoad,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_nutrient_imbalance',
        labelEs: 'Desequilibrio nutricional NPK',
        scientificName: 'Desbalance nutricional',
        type: 'nutrition_risk',
        summaryEs:
            'N alto puede dar hoja blanda, nitratos y peor anaquel; N bajo reduce crecimiento. P/K se interpretan con suelo, agua y CE.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Cruza sintomas con lecturas NPK, CE, humedad y etapa.',
      'Si el riego es irregular, estabilizar agua antes de corregir nutrientes.',
      'No recomendar N fuerte cerca de cosecha o bolting.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'spinach_phytotoxicity_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Quemado uniforme tras aplicacion o cambio de manejo',
    stages: _allSpinachStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalLeafEdgeBurn,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_phytotoxicity',
        labelEs: 'Fitotoxicidad',
        scientificName: 'Dano por manejo o aplicacion reciente',
        type: 'management_injury',
        summaryEs:
            'Quemado o deformacion tras aplicacion, mezcla, deriva, salinidad o cambio brusco. Confirmar fecha y patron antes de atribuir a plaga.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Pregunta por aplicaciones, mezcla, lavado o fertirriego reciente.',
      'Revisa si el patron es uniforme o por franjas.',
      'Separa de enfermedad si no hay avance por focos.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'spinach_postharvest_quality_01',
    cropId: CropCatalog.spinachCropId,
    labelEs: 'Hoja amarilla, sucia o con mala vida de anaquel',
    stages: _qualityStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalDenseWetCanopy,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalAphidContamination,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spinach_postharvest_quality',
        labelEs: 'Riesgo de calidad poscosecha',
        scientificName: 'Trastorno de calidad comercial',
        type: 'quality_disorder',
        summaryEs:
            'Hoja con tierra, amarillamiento, dano de plaga o exceso de humedad pierde vida de anaquel. Rendimiento comercial no es biomasa bruta.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa hoja comercial, suciedad, turgencia y sanidad antes del corte.',
      'Confirma si hay HR alta, N alto, minador, mildiu o pulgon.',
      'Decide cosecha/cierre segun calidad real, no solo tamano.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _leafQualityActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.spinachCropId,
        varietyIds: _processVarieties,
        diagnosisIds: <String>{'spinach_postharvest_quality'},
        scoreDelta: -2,
        rationaleEs:
            'Proceso tolera algo mas de forma visual, pero no hoja enferma o contaminada.',
      ),
    ],
  ),
];
