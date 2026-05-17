import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

const Set<PlantHealthStageBucket> _earlyStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
};

const Set<PlantHealthStageBucket> _rootSoilStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _vectorStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _productiveStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _flowerFruitStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _lateFruitStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _allSquashStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<String> _genericVarieties = <String>{'squash_generic', 'ca_gen'};

const Set<String> _tenderFruitVarieties = <String>{
  'squash_zucchini',
  'squash_criolla',
  'squash_round',
  'ca_01',
  'ca_02',
  'ca_03',
};

const Set<String> _matureFruitVarieties = <String>{
  'squash_castilla',
  'squash_butternut',
  'squash_chilacayote',
  'ca_04',
  'ca_05',
  'ca_06',
};

const Set<String> _seedVarieties = <String>{'squash_pipian', 'ca_07'};

const String _disclaimer =
    'Diagnostico sugerido. BIO-G orienta monitoreo y manejo cultural; confirma en campo y con apoyo tecnico local si el dano avanza.';

const List<String> _baseActions = <String>[
  'Marcar focos por cama o zona y revisar avance en 24-48 horas.',
  'Corregir riego, drenaje y ventilacion antes de perseguir sintomas.',
  'Retirar fruto o tejido muy afectado si ya funciona como fuente de inoculo.',
  'Documentar fotos, etapa y clima reciente para comparar evolucion.',
];

const List<String> _rootSoilActions = <String>[
  'Revisar raiz completa, cuello y corona antes de asumir falta de agua.',
  'Corregir encharcamiento, cama baja, riego largo o compactacion.',
  'Comparar zona baja/humeda contra zona con mejor drenaje.',
  'Registrar humedad de suelo, textura, resistencia y clima reciente.',
];

const List<String> _vectorActions = <String>[
  'Revisar enves de hoja, brotes tiernos, orillas, maleza y cultivos vecinos.',
  'Separar dano directo de plaga contra sintomas compatibles con virus.',
  'Marcar focos de entrada y revisar si avanzan hacia el centro del lote.',
  'Evitar diagnostico definitivo sin observar vector, patron y avance.',
];

const List<String> _pollinationActions = <String>[
  'Observar flores y actividad de abejas temprano por la manana.',
  'Estabilizar humedad del suelo durante floracion y cuajado.',
  'Registrar calor, lluvia, frio, nublado o aplicaciones recientes en flor.',
  'No asumir falta de fertilizante si el problema coincide con mala polinizacion.',
];

const List<String> _abioticActions = <String>[
  'Cruzar sintomas con riego, CE, temperatura, raiz y etapa antes de recomendar correccion.',
  'Revisar si el patron es uniforme; si lo es, puede apuntar mas a ambiente, fitotoxicidad o manejo.',
  'Registrar aplicaciones recientes, cambios de riego, calor, frio o lluvia.',
  'Evitar recetas fuertes sin confirmar si el dano es fisiologico, nutricional o sanitario.',
];

const List<PlantHealthSyndrome> squashSyndromes = <PlantHealthSyndrome>[
  PlantHealthSyndrome(
    id: 'squash_damping_off_seedling_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Plantula caida o cuello estrangulado',
    stages: _earlyStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalSeedlingNeckCollapse,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'squash_damping_off_complex',
        labelEs: 'Damping-off / muerte de plantula',
        scientificName: 'Pythium spp. / Rhizoctonia solani / Fusarium spp.',
        type: 'fungus_oomycete',
        summaryEs:
            'Falla de emergencia, cuello oscuro o plantula vencida. En calabaza se favorece por suelo frio, humedad excesiva, costra, salinidad o mala aireacion.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si la semilla no emergio o si la plantula se doblo en el cuello.',
      'Arranca una plantula completa y revisa raiz fina, cuello y olor a pudricion.',
      'Confirma si hubo suelo frio, riego pesado, charola/suelo saturado o costra.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootSoilActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_root_crown_rot_complex_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Raiz oscura, cuello lesionado o marchitez por parches',
    stages: _rootSoilStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalSeedlingNeckCollapse,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pythium_rhizoctonia_fusarium_squash_root_crown',
        labelEs: 'Complejo de raiz y cuello',
        scientificName: 'Pythium spp. / Rhizoctonia spp. / Fusarium spp.',
        type: 'fungus_oomycete',
        summaryEs:
            'Marchitez irregular con raiz cafe, cuello danado o bajo vigor. Puede confundirse con falta de agua, pero el suelo suele estar humedo o con mala aireacion.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa raiz y cuello de plantas enfermas y plantas vecinas sanas.',
      'Confirma si el patron aparece en parches, zonas bajas o suelo compactado.',
      'No regar mas hasta distinguir deficit real de anoxia o raiz podrida.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootSoilActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_phytophthora_crown_fruit_rot_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Marchitez rapida, corona acuosa o fruto podrido',
    stages: _rootSoilStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalWaterSoakedMargin,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalGrayFuzzyGrowth,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'phytophthora_squash_crown_fruit_rot',
        labelEs: 'Phytophthora de corona, raiz o fruto',
        scientificName: 'Phytophthora capsici / Phytophthora spp.',
        type: 'oomycete',
        summaryEs:
            'Riesgo muy fuerte cuando hay agua acumulada: corona acuosa, marchitez rapida o fruto con pudricion humeda. En fruto maduro y pipian pesa mas por contacto con suelo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si la marchitez aparece despues de lluvia, riego largo o cama baja.',
      'Observa corona y base de guia; busca tejido acuoso, cafe o colapsado.',
      'Levanta frutos en contacto con suelo y revisa la cara inferior.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _rootSoilActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.squashCropId,
        varietyIds: _matureFruitVarieties,
        diagnosisIds: <String>{'phytophthora_squash_crown_fruit_rot'},
        scoreDelta: 8,
        rationaleEs:
            'CA-04/05/06 tienen fruto maduro y mayor tiempo de exposicion a suelo humedo.',
      ),
      VarietyModifier(
        cropId: CropCatalog.squashCropId,
        varietyIds: _seedVarieties,
        diagnosisIds: <String>{'phytophthora_squash_crown_fruit_rot'},
        scoreDelta: 7,
        rationaleEs:
            'CA-07 necesita mantener fruto sano hasta madurez de pepita.',
      ),
    ],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_root_knot_nematodes_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Parches debiles con raiz agallada',
    stages: _rootSoilStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'root_knot_nematodes_squash',
        labelEs: 'Nematodos agalladores',
        scientificName: 'Meloidogyne spp.',
        type: 'nematode',
        summaryEs:
            'Parches de bajo vigor o marchitez irregular con raiz deformada/agallada. No debe diagnosticarse solo por planta chica: hay que revisar raiz y, si es posible, muestra de suelo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Arranca plantas de borde del parche y revisa si hay agallas en raiz.',
      'Compara raiz de planta debil contra planta sana fuera del foco.',
      'Pregunta por historial del lote, rotacion pobre, maleza hospedera o suelo arenoso.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _rootSoilActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_powdery_mildew_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Polvillo blanco en hoja - cenicilla',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomPowderyGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalSporesRubOff,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    conflictingSignals: <String>{PlantHealthIds.signalUndersideSporulation},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'podosphaera_squash_powdery_mildew',
        labelEs: 'Cenicilla / oidio de cucurbitaceas',
        scientificName: 'Podosphaera xanthii / Erysiphe cichoracearum',
        type: 'fungus',
        summaryEs:
            'Polvo blanco superficial que reduce hoja activa, llenado de fruto y peso de pepita si no se detecta temprano.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Raspa suavemente: si el polvo se desprende, sube la sospecha.',
      'Revisa hojas medias y bajas; suele iniciar en focos antes de cerrar el dosel.',
      'Si hay enves gris y manchas angulares, revisar mildiu velloso en vez de cenicilla.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.squashCropId,
        varietyIds: _matureFruitVarieties,
        diagnosisIds: <String>{'podosphaera_squash_powdery_mildew'},
        scoreDelta: 5,
        rationaleEs:
            'Fruto maduro y ciclos largos dependen de mantener hoja sana hasta llenado.',
      ),
      VarietyModifier(
        cropId: CropCatalog.squashCropId,
        varietyIds: _seedVarieties,
        diagnosisIds: <String>{'podosphaera_squash_powdery_mildew'},
        scoreDelta: 5,
        rationaleEs: 'CA-07 necesita hoja funcional hasta llenado de pepita.',
      ),
    ],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_downy_mildew_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Manchas angulares y enves activo - mildiu',
    stages: _foliarStages,
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
    },
    conflictingSignals: <String>{PlantHealthIds.signalWhitePowderGrowth},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pseudoperonospora_squash_downy_mildew',
        labelEs: 'Mildiu velloso de cucurbitaceas',
        scientificName: 'Pseudoperonospora cubensis',
        type: 'oomycete',
        summaryEs:
            'Cuadro explosivo con rocio o lluvia: manchas angulares, enves con esporulacion y defoliacion rapida.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Voltea la hoja temprano y busca enves gris o sucio donde coincide la mancha.',
      'Confirma que las lesiones respetan nervaduras y avanzan rapido.',
      'Relaciona el foco con lluvia, rocio largo o follaje mojado.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_bacterial_angular_leaf_spot_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Manchas angulares acuosas o tejido roto',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomAngularSpots,
    strongSignals: <String>{
      PlantHealthIds.signalAngularLesionPattern,
      PlantHealthIds.signalWaterSoakedMargin,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'angular_leaf_spot_squash',
        labelEs: 'Mancha angular bacteriana',
        scientificName: 'Pseudomonas syringae pv. lachrymans',
        type: 'bacteria',
        summaryEs:
            'Lesiones angulares acuosas que pueden secarse y romper tejido. Se favorece por lluvia, salpique, manejo en humedo y residuos infectados.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si la lesion respeta nervaduras y parece acuosa al inicio.',
      'Ubica si hubo lluvia, aspersion, salpique o manejo con follaje mojado.',
      'Diferencia de mildiu: aqui no siempre hay esporulacion activa en el enves.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_anthracnose_gummy_alternaria_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Manchas foliares, cancros o fruto marcado',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalStemCanker,
      PlantHealthIds.signalWaterSoakedMargin,
      PlantHealthIds.signalPinkSporeMass,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'anthracnose_gummy_stem_squash_complex',
        labelEs: 'Complejo de manchas, antracnosis o gomosis',
        scientificName:
            'Colletotrichum spp. / Didymella bryoniae / Alternaria spp.',
        type: 'fungus',
        summaryEs:
            'Manchas que saltan de hoja a tallo o fruto, con mayor riesgo cuando hay residuos, humedad y fruto cercano a cosecha.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si hay cancro en guia o peciolo, no solo mancha de hoja.',
      'Busca manchas hundidas en fruto o masa rosada/naranja en lesiones.',
      'Ubica si el foco inicia cerca de residuos o zonas con poca ventilacion.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_botrytis_gray_mold_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Moho gris en flor, herida o fruto',
    stages: _productiveStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalWaterSoakedMargin,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'botrytis_gray_mold_squash',
        labelEs: 'Botrytis / moho gris',
        scientificName: 'Botrytis cinerea',
        type: 'fungus',
        summaryEs:
            'Moho gris en flores viejas, heridas o fruto bajo humedad alta y mala ventilacion. Pesa mas en protegido en suelo o dosel cerrado.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca flor vieja pegada al fruto o tejido senescente con moho gris.',
      'Confirma humedad alta, condensacion o poca ventilacion.',
      'Revisa si el problema nace en heridas, flores viejas o tejido muerto.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_whitefly_aphid_virus_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Mosca blanca, pulgon, mosaico o amarillamiento',
    stages: _vectorStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalWhiteflyCloud,
      PlantHealthIds.signalAphidEarlyToxicity,
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
    },
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'squash_vector_virus_complex',
        labelEs: 'Virus asociados a vectores',
        scientificName:
            'Begomovirus / Potyvirus complex; Bemisia tabaci / Aphididae',
        type: 'insect_virus',
        summaryEs:
            'Mosaico, rizado, amarillamiento o planta frenada con mosca blanca o pulgon. El dano temprano pesa mas que una colonia tardia.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa brotes nuevos: mosaico, rizado y achaparramiento pesan mas que hojas viejas.',
      'Sacude la planta para ver nube de mosca blanca y revisa enves por colonias.',
      'Si hay mosaico sin vector visible, pregunta por focos vecinos o maleza hospedera.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.squashCropId,
        varietyIds: _genericVarieties,
        diagnosisIds: <String>{'squash_vector_virus_complex'},
        scoreDelta: 3,
        rationaleEs:
            'CA-GEN debe alertar conservadoramente sin asumir tipo comercial.',
        isProxy: true,
        requiresCaution: true,
      ),
      VarietyModifier(
        cropId: CropCatalog.squashCropId,
        varietyIds: _tenderFruitVarieties,
        diagnosisIds: <String>{'squash_vector_virus_complex'},
        scoreDelta: 4,
        rationaleEs:
            'Calabacita de corte tierno pierde calidad rapido con virus y deformacion.',
      ),
    ],
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_silverleaf_whitefly_disorder_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Hoja plateada o blanquecina con mosca blanca',
    stages: _vectorStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalWhiteflyCloud,
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'silverleaf_whitefly_disorder_squash',
        labelEs: 'Silverleaf asociado a mosca blanca',
        scientificName: 'Bemisia tabaci - silverleaf disorder',
        type: 'insect_physiological',
        summaryEs:
            'Hojas blanquecinas o plateadas con presion de mosca blanca. En zucchini y calabacita puede bajar vigor, calidad y continuidad de cosecha.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa enves por ninfas y adultos de mosca blanca, no solo adultos volando.',
      'Confirma si el plateado inicia en focos calientes, orillas o entradas.',
      'Diferencia silverleaf de cenicilla: la hoja se ve plateada, no con polvo que se desprende.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.squashCropId,
        varietyIds: _tenderFruitVarieties,
        diagnosisIds: <String>{'silverleaf_whitefly_disorder_squash'},
        scoreDelta: 5,
        rationaleEs:
            'CA-01/02/03 pierden calidad rapidamente por plateado y baja continuidad.',
      ),
    ],
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_thrips_mites_bronzing_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Raspado, bronceado o plateado fino',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalMitesWebbing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHeatStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'thrips_mites_squash_complex',
        labelEs: 'Trips / acaros en brote, flor o fruto joven',
        scientificName: 'Thripidae / Tetranychidae',
        type: 'arthropod',
        summaryEs:
            'Raspado fino, bronceado o telarana; en calabacita afecta fruto joven y en flor puede reducir amarre.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Golpea flores o brotes sobre una hoja blanca y busca trips pequenos.',
      'Revisa enves por punteado fino y telarana si hubo calor seco.',
      'Distingue raspado de mosaico viral: el vector visible sube la sospecha.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_cucumber_beetles_wilt_risk_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Mordidas tempranas y riesgo de marchitez bacteriana',
    stages: _vectorStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalVectorPresent,
    },
    conflictingSignals: <String>{PlantHealthIds.signalNoBiteMarks},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cucumber_beetle_bacterial_wilt_risk_squash',
        labelEs: 'Escarabajo del pepino / riesgo de marchitez bacteriana',
        scientificName:
            'Diabrotica spp. / Acalymma spp. / Erwinia tracheiphila',
        type: 'insect_bacteria_risk',
        summaryEs:
            'Mordidas en cotiledones, hojas, flores o fruto. En zonas con historial puede subir riesgo de marchitez bacteriana transmitida por escarabajos.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca mordidas en cotiledones, flores y bordes de hojas jovenes.',
      'Revisa si hay escarabajos activos o dano fresco cerca de bordes/maleza.',
      'Si hay marchitez repentina sin raiz podrida, revisar historial de escarabajos.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_bug_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Chinche de calabaza, huevos o hojas debilitadas',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalActiveChewing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'squash_bug_syndrome',
        labelEs: 'Chinche de la calabaza',
        scientificName: 'Anasa tristis / Coreidae',
        type: 'insect',
        summaryEs:
            'Huevos, ninfas o adultos debilitando hojas y guias. Pesa mas en calabaza madura, ciclos largos y dosel cerrado con residuos de cucurbitaceas.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa enves de hojas por huevos agrupados y ninfas grises.',
      'Observa hojas que se marchitan o necrosan aunque la raiz no este podrida.',
      'Busca adultos cerca de corona, residuos o partes sombreadas del dosel.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.squashCropId,
        varietyIds: _matureFruitVarieties,
        diagnosisIds: <String>{'squash_bug_syndrome'},
        scoreDelta: 5,
        rationaleEs:
            'Fruto maduro y ciclos largos acumulan mas presion de chinche.',
      ),
    ],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_vine_borer_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Guia colapsada con aserrin o barrenador',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
    },
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalFeedingHoles,
    },
    conflictingSignals: <String>{PlantHealthIds.signalNoBiteMarks},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'squash_vine_borer_syndrome',
        labelEs: 'Barrenador de la guia / tallo',
        scientificName: 'Melittia cucurbitae / complex',
        type: 'insect',
        summaryEs:
            'Marchitez repentina de una guia con excremento tipo aserrin en la base. No confundir de inmediato con falta de agua o pudricion de raiz.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa base de guia y tallo por frass/aserrin fresco.',
      'Compara guia colapsada contra raiz y cuello; si raiz esta sana, sube sospecha.',
      'Busca perforacion o guia hueca/blanda en el punto de entrada.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'squash_pickleworm_melonworm_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Larvas en flor, brote o fruto perforado',
    stages: _productiveStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalActiveChewing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'diaphania_pickleworm_melonworm_squash',
        labelEs: 'Diaphania / gusano de flor o fruto',
        scientificName: 'Diaphania nitidalis / Diaphania hyalinata',
        type: 'insect',
        summaryEs:
            'Larvas perforan flores, brotes o fruto tierno. En clima calido y siembras tardias puede subir rapido y causar pudricion secundaria.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Abre flores o frutos danados y busca larva o excremento.',
      'Revisa brotes tiernos si hay dano sin fruto visible.',
      'Relaciona con calor, humedad y ciclos continuos de cucurbitaceas cerca.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'squash_poor_pollination_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Flor femenina aborta o fruto no amarra',
    stages: _flowerFruitStages,
    organIds: <String>{PlantHealthIds.organFlower, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalFlowerDrop,
      PlantHealthIds.signalDeformedNoRot,
      PlantHealthIds.signalFruitHooking,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'poor_pollination_squash',
        labelEs: 'Mala polinizacion',
        scientificName: 'Pollination failure / abiotic context',
        type: 'abiotic_pollination',
        summaryEs:
            'La calabaza necesita polinizacion efectiva en la manana. Puede haber flores, pero si faltan abejas o el clima no ayuda, el fruto pequeno amarillea, se deforma o cae.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si hay flores macho y hembra abiertas en la misma manana.',
      'Observa actividad de abejas temprano, antes del calor fuerte.',
      'Confirma que el fruto no tenga mordida, pudricion o dano de trips.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _pollinationActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_heat_flower_abortion_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Calor fuerte, flor cae o cuajado irregular',
    stages: _flowerFruitStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalFlowerDrop,
      PlantHealthIds.signalDeformedNoRot,
    },
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'heat_flower_abortion_squash',
        labelEs: 'Aborto floral por calor',
        scientificName: 'Abiotic heat stress',
        type: 'abiotic',
        summaryEs:
            'Dias muy calidos, noches calientes, baja humedad o deficit de agua reducen flor funcional y amarre. No se debe resolver como falta simple de fertilizante.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Relaciona la caida de flor con dias arriba de calor fuerte o noches calientes.',
      'Revisa si la humedad del suelo tambien venia bajando.',
      'Observa si el problema se concentra en floracion/cuajado.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _pollinationActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_drought_stress_flower_fruit_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Estres hidrico en flor o fruto',
    stages: _productiveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalFlowerDrop,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'drought_stress_squash',
        labelEs: 'Deficit hidrico en etapa critica',
        scientificName: 'Abiotic water deficit',
        type: 'abiotic',
        summaryEs:
            'Riego irregular o baja humedad en floracion, cuajado o llenado causa marchitez, aborto, fruto chico o deforme. En calabaza esta ventana pesa mucho.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa humedad del suelo antes de fertilizar o culpar a plaga.',
      'Confirma si la planta se recupera por la tarde/noche o si ya hay dano de raiz.',
      'Ubica si el problema coincide con viento, calor o suelo ligero.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_anoxia_excess_moisture_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Marchitez con suelo humedo o saturado',
    stages: _rootSoilStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'anoxia_excess_moisture_squash',
        labelEs: 'Anoxia / exceso de humedad',
        scientificName: 'Abiotic excess moisture',
        type: 'abiotic',
        summaryEs:
            'La planta puede verse marchita aunque el suelo este mojado. La raiz de calabaza necesita oxigeno; el exceso persistente favorece pudriciones.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Toca el suelo y revisa humedad real antes de regar mas.',
      'Revisa raiz y cuello para separar anoxia de patogeno avanzado.',
      'Ubica zonas bajas, cama compactada o riego demasiado largo.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootSoilActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_salinity_ec_high_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'CE alta, borde quemado o cuajado debil',
    stages: _allSquashStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalWaterlogging,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'salinity_ec_high_squash',
        labelEs: 'Salinidad / CE alta',
        scientificName: 'Abiotic salinity stress',
        type: 'abiotic',
        summaryEs:
            'CE alta se comporta como sequia fisiologica: bajo vigor, bordes danados, aborto o fruto chico. En v1 no debe convertirse en receta automatica.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa lectura de CE junto con humedad; sales altas con bulbo seco pesan mas.',
      'Pregunta por fertirriego cargado, agua salina, acolchado o lavado insuficiente.',
      'Separa de enfermedad: la salinidad suele verse mas uniforme que un foco infeccioso.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_sunscald_fruit_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Golpe de sol en fruto expuesto',
    stages: _lateFruitStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRapidFoliarCollapse,
    },
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunscald_squash_fruit',
        labelEs: 'Sunscald / golpe de sol en fruto',
        scientificName: 'Abiotic sunscald',
        type: 'abiotic',
        summaryEs:
            'Fruto expuesto por defoliacion, cenicilla, mildiu, virus o plaga puede quemarse con radiacion y calor. No siempre es pudricion inicial.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si el dano esta del lado expuesto al sol.',
      'Confirma si hubo defoliacion previa, cenicilla, mildiu o plaga.',
      'Diferencia de pudricion: golpe de sol inicia seco o claro; pudricion tiende a blanda/humeda.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_blossom_end_rot_functional_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Lesion apical seca en fruto joven',
    stages: _flowerFruitStages,
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalDeformedNoRot,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalWaterlogging,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'blossom_end_rot_functional_squash',
        labelEs: 'Pudricion apical funcional / agua-CE-raiz',
        scientificName: 'Functional calcium disorder / abiotic complex',
        type: 'abiotic_quality',
        summaryEs:
            'Lesion seca o hundida en extremo floral. En BIO-G v1 se lee como problema de agua, CE, raiz y transpiracion; no como aplicar calcio a ciegas.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si hay humedad irregular, CE alta, raiz limitada o calor.',
      'Confirma si la lesion esta en extremo floral y no viene de mordida o hongo.',
      'No recomendar calcio a ciegas sin revisar agua, raiz y salinidad.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_cold_frost_damage_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Frio, helada o arranque lento',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.reproductiveEarly,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalFlowerDrop,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cold_frost_damage_squash',
        labelEs: 'Dano por frio o helada',
        scientificName: 'Abiotic cold/frost injury',
        type: 'abiotic',
        summaryEs:
            'Calabaza es sensible al frio. Suelo frio retrasa germinacion; helada o noches frias pueden danar hoja, flor y amarre.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Relaciona el dano con noches frias, helada o siembra temprana.',
      'Revisa si el dano aparece uniforme en la parte mas expuesta.',
      'Distingue de enfermedad: el dano por frio suele coincidir con evento climatico claro.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_phytotoxicity_herbicide_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Quemado o deformacion uniforme tras aplicacion',
    stages: _allSquashStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalDeformedNoRot,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'phytotoxicity_herbicide_squash',
        labelEs: 'Fitotoxicidad / deriva / mezcla fuerte',
        scientificName: 'Abiotic chemical injury',
        type: 'abiotic_phytotoxicity',
        summaryEs:
            'Quemado, deformacion nueva o patron por linea/borde despues de aplicacion o deriva. Preguntar antes de asumir enfermedad.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Pregunta por herbicida, fertilizante foliar, plaguicida, mezcla o deriva reciente.',
      'Observa si el patron es por linea, borde, viento o uniforme en todo el lote.',
      'Revisa si el dano nuevo coincide con aplicacion en calor o dosis fuerte.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_nitrogen_excess_vigor_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Mucha guia y hoja, poco fruto',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalFlowerDrop,
      PlantHealthIds.signalDeformedNoRot,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nitrogen_excess_vigor_squash',
        labelEs: 'Exceso vegetativo por nitrogeno o agua',
        scientificName: 'Abiotic nutrition/vigor imbalance',
        type: 'abiotic_nutrition',
        summaryEs:
            'Mucho follaje, poca flor funcional o poco amarre puede venir de exceso de N, agua alta, baja luz o cosecha retrasada. En floracion no conviene empujar puro nitrogeno.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si hay guia muy vigorosa y poco cuajado real.',
      'Cruza con NPK, riego, luz, densidad y etapa antes de corregir.',
      'Confirma que no sea mala polinizacion, calor o virus deformando el fruto.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'squash_fruit_contact_rot_01',
    cropId: CropCatalog.squashCropId,
    labelEs: 'Fruto con pudricion por contacto con suelo humedo',
    stages: _productiveStages,
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalWaterSoakedMargin,
      PlantHealthIds.signalGrayFuzzyGrowth,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'squash_contact_soil_fruit_rot',
        labelEs: 'Pudricion de fruto por suelo mojado',
        scientificName: 'Phytophthora spp. / Pythium spp. / secondary rots',
        type: 'oomycete_secondary',
        summaryEs:
            'Fruto maduro o pipian apoyado en suelo mojado desarrolla manchas hundidas, blandas o moho secundario.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Levanta el fruto y revisa la cara en contacto con el suelo.',
      'Relaciona el foco con charcos, cama baja o rastrojo mojado.',
      'Separa golpe de sol de pudricion: la pudricion suele estar humeda o blanda.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Mejorar drenaje y evitar que el fruto quede sobre zonas encharcadas.',
      'Retirar frutos colapsados para bajar foco de pudricion.',
      'En fruto maduro, revisar contacto con suelo antes de lluvias o cosecha.',
    ],
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.squashCropId,
        varietyIds: _matureFruitVarieties,
        diagnosisIds: <String>{'squash_contact_soil_fruit_rot'},
        scoreDelta: 7,
        rationaleEs:
            'CA-04/05/06 pasan mas tiempo con fruto maduro apoyado en suelo.',
      ),
      VarietyModifier(
        cropId: CropCatalog.squashCropId,
        varietyIds: _seedVarieties,
        diagnosisIds: <String>{'squash_contact_soil_fruit_rot'},
        scoreDelta: 6,
        rationaleEs:
            'CA-07 debe proteger fruto hasta que la pepita madure y se seque.',
      ),
    ],
    favorsHighHumidity: true,
  ),
];
