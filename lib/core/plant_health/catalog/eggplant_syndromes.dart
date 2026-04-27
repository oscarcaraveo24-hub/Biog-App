import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

const Set<PlantHealthStageBucket> _earlyStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
};

const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
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

const Set<PlantHealthStageBucket> _fullCycleStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _leafChewingStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<String> _genericVarieties = <String>{'eggplant_generic', 'be_gen'};
const Set<String> _ovalVarieties = <String>{
  'eggplant_oval_round',
  'eggplant_italian_purple',
  'eggplant_italian_black',
  'be_02',
};
const Set<String> _stripedVarieties = <String>{'eggplant_striped', 'be_03'};
const Set<String> _whiteVarieties = <String>{'eggplant_white', 'be_04'};
const Set<String> _visualVarieties = <String>{
  'eggplant_striped',
  'eggplant_white',
  'be_03',
  'be_04',
};
const Set<String> _fruitQualityVarieties = <String>{
  'eggplant_long_purple',
  'eggplant_oval_round',
  'eggplant_italian_purple',
  'eggplant_italian_black',
  'eggplant_striped',
  'eggplant_white',
  'be_01',
  'be_02',
  'be_03',
  'be_04',
};

const String _disclaimer =
    'Diagnostico sugerido. BIO-G orienta monitoreo y decision base; confirma en campo y con apoyo tecnico local cuando el dano avance o haya duda.';

const List<String> _baseSanitaryActions = <String>[
  'Marcar focos por cama o zona y revisar avance en 24-48 horas.',
  'Corregir riego, drenaje y ventilacion antes de perseguir sintomas.',
  'Retirar tejido muy afectado si ya funciona como fuente de inoculo.',
  'Documentar fotos, etapa y clima reciente para comparar evolucion.',
];

const VarietyModifier _genericCautionModifier = VarietyModifier(
  cropId: CropCatalog.eggplantCropId,
  varietyIds: _genericVarieties,
  diagnosisIds: <String>{'eggplant_generic_early_warning'},
  scoreDelta: 4,
  rationaleEs:
      'BE-GEN debe alertar temprano sin sobrediagnosticar; usar como advertencia conservadora.',
  isProxy: true,
  requiresCaution: true,
);

const VarietyModifier _visualQualityModifier = VarietyModifier(
  cropId: CropCatalog.eggplantCropId,
  varietyIds: _visualVarieties,
  diagnosisIds: <String>{'eggplant_visual_quality_loss'},
  scoreDelta: 7,
  rationaleEs:
      'Tipos rayados y blancos pierden valor comercial rapido por manchas, cicatrices o golpe de sol.',
  isProxy: true,
  requiresCaution: true,
);

const List<PlantHealthSyndrome> eggplantSyndromes =
    <PlantHealthSyndrome>[
  PlantHealthSyndrome(
    id: 'eggplant_damping_off_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Plantula colapsada - damping-off',
    stages: _earlyStages,
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
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pythium_rhizoctonia_eggplant_seedling',
        labelEs: 'Damping-off por Pythium / Rhizoctonia',
        scientificName: 'Pythium spp. / Rhizoctonia solani',
        type: 'oomycete_fungus',
        summaryEs:
            'Cuello vencido, raiz oscura o plantulas caidas despues de emergencia; sube con humedad excesiva y suelo frio.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar si el cuello esta adelgazado o podrido a ras de suelo.',
      'Confirmar humedad excesiva, charcos o drenaje lento.',
      'Comparar plantulas sanas y enfermas arrancando raiz completa.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_phytophthora_root_crown_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Marchitez con cuello o raiz podrida',
    stages: _fullCycleStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalRapidFoliarCollapse,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'phytophthora_eggplant_root_crown',
        labelEs: 'Phytophthora / pudricion de raiz y cuello',
        scientificName: 'Phytophthora spp.',
        type: 'oomycete',
        summaryEs:
            'Complejo radicular serio favorecido por drenaje pobre, encharque y agua que mueve inoculo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Sacar planta completa y revisar cuello oscuro o raiz podrida.',
      'Mapear si los focos siguen la linea de riego o zonas bajas.',
      'No confundir con pura falta de agua: aqui la raiz no responde.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Bajar riego y corregir drenaje de inmediato.',
      'Evitar mover agua o suelo desde focos hacia zonas sanas.',
      'Retirar plantas colapsadas si ya son fuente evidente de inoculo.',
      'Planear rotacion y sanidad de suelo para el siguiente ciclo.',
    ],
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_fusarium_root_complex_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Raiz pobre, planta frenada o marchitez lenta',
    stages: _fullCycleStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalWaterlogging,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pythium_rhizoctonia_fusarium_eggplant_root',
        labelEs: 'Pythium / Rhizoctonia / Fusarium de raiz',
        scientificName: 'Pythium spp. / Rhizoctonia solani / Fusarium spp.',
        type: 'root_complex',
        summaryEs:
            'Raiz oscura o pobre, planta parada y recuperacion lenta tras riego; suele venir de estres radicular acumulado.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar raiz fina: color, olor y cantidad.',
      'Cruzar con exceso de humedad, compactacion o sales.',
      'Separar de nematodos buscando agallas.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_verticillium_fusarium_wilt_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Marchitez vascular o unilateral',
    stages: _fullCycleStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomWiltVascular,
    strongSignals: <String>{
      PlantHealthIds.signalVascularBrowning,
      PlantHealthIds.signalOneSidedWilt,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'verticillium_fusarium_eggplant_wilt',
        labelEs: 'Verticillium / Fusarium vascular',
        scientificName: 'Verticillium dahliae / Fusarium oxysporum complex',
        type: 'fungus',
        summaryEs:
            'Marchitez por focos con pardeamiento vascular; se agrava con raiz estresada y antecedentes de solanaceas.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Cortar tallo o peciolo y buscar pardeamiento vascular.',
      'Revisar si la marchitez empezo por una rama o lado de la planta.',
      'Sacar raiz para descartar Phytophthora o nematodos.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_bacterial_wilt_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Marchitez rapida sin raiz evidentemente podrida',
    stages: _fullCycleStages,
    organIds: <String>{PlantHealthIds.organStem, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomWiltVascular,
    strongSignals: <String>{
      PlantHealthIds.signalRapidFoliarCollapse,
      PlantHealthIds.signalVascularBrowning,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'ralstonia_eggplant_wilt',
        labelEs: 'Marchitez bacteriana',
        scientificName: 'Ralstonia solanacearum',
        type: 'bacteria',
        summaryEs:
            'Marchitez rapida en zonas favorables, con planta verde que cae y posible exudado bacteriano en corte.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Cruzar con historial regional o lotes con solanaceas afectadas.',
      'Revisar exudado en tallo cortado si hay sospecha fuerte.',
      'Separar de falta de agua y de Phytophthora revisando raiz.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_alternaria_cercospora_leaf_spot_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Mancha foliar - Alternaria / Cercospora',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCannotScrapeOff,
      PlantHealthIds.signalAngularLesionPattern,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'alternaria_cercospora_eggplant_leaf_spot',
        labelEs: 'Alternaria / Cercospora',
        scientificName: 'Alternaria spp. / Cercospora spp.',
        type: 'fungus',
        summaryEs:
            'Manchas cafe o necroticas que reducen area foliar y pueden exponer fruto a golpe de sol.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar hojas bajas y medias primero.',
      'Buscar anillos, centro claro o patron angular.',
      'Cruzar con salpique, humedad y ventilacion.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[_visualQualityModifier],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_phomopsis_fruit_rot_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Pudricion de fruto - Phomopsis',
    stages: _productiveStages,
    organIds: <String>{PlantHealthIds.organFruit, PlantHealthIds.organStem},
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalStemCanker,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCannotScrapeOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'phomopsis_eggplant_fruit_rot',
        labelEs: 'Phomopsis / pudricion de fruto',
        scientificName: 'Phomopsis vexans',
        type: 'fungus',
        summaryEs:
            'Lesiones hundidas en fruto y posibles cancros en tallo; aumenta con humedad, heridas y residuos infectados.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar lesiones hundidas y avance desde heridas.',
      'Revisar tallos o peciolos con cancro.',
      'Cruzar con lluvia, salpique o alta humedad reciente.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[_visualQualityModifier],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_botrytis_protected_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Moho gris en protegido - Botrytis',
    stages: _productiveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomGrayMoldNecrosis,
    strongSignals: <String>{
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalSporesRubOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'botrytis_cinerea_eggplant',
        labelEs: 'Botrytis / moho gris',
        scientificName: 'Botrytis cinerea',
        type: 'fungus',
        summaryEs:
            'Moho gris sobre flores, heridas o frutos con humedad alta y poca ventilacion, especialmente bajo protegido.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar flores secas, heridas y fruto con tejido blando.',
      'Confirmar moho gris que suelta polvo al tocarlo.',
      'Cruzar con humedad nocturna y condensacion.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[_visualQualityModifier],
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_powdery_mildew_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Polvillo blanco - cenicilla',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organStem},
    primarySymptomId: PlantHealthIds.symptomPowderyGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalSporesRubOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'powdery_mildew_eggplant',
        labelEs: 'Cenicilla',
        scientificName: 'Oidium spp. / Leveillula spp.',
        type: 'fungus',
        summaryEs:
            'Polvillo blanco o clorosis asociada; reduce hoja funcional y baja calidad si avanza en produccion.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar crecimiento polvoso superficial.',
      'Revisar hojas medias y enves.',
      'Distinguirlo de polvo o residuos que no siguen el tejido.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_anthracnose_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Lesiones hundidas en fruto - antracnosis',
    stages: _productiveStages,
    organIds: <String>{PlantHealthIds.organFruit, PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalPinkSporeMass,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalWaterSoakedMargin,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'colletotrichum_eggplant',
        labelEs: 'Antracnosis',
        scientificName: 'Colletotrichum spp.',
        type: 'fungus',
        summaryEs:
            'Lesiones hundidas y oscuras en fruto; sube con humedad y afecta cosecha/postcosecha.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar lesion hundida circular o alargada en fruto.',
      'Confirmar si aparece masa rosada de esporas con humedad.',
      'Revisar frutos cercanos a corte y residuos infectados.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[_visualQualityModifier],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_whitefly_virus_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Mosca blanca, mosaico o amarillamiento',
    stages: _vectorStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalWhiteflyCloud,
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalStickyHoneydew,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'whitefly_eggplant_virus_complex',
        labelEs: 'Mosca blanca y virus asociados',
        scientificName: 'Bemisia tabaci / begomovirus complex',
        type: 'insect_virus',
        summaryEs:
            'Mosca blanca causa dano directo, mielecilla y puede empujar virus con mosaico, rizado o amarillamiento.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Mover follaje y verificar nube de mosca blanca.',
      'Revisar brotes nuevos por mosaico, rizado o amarillamiento.',
      'Comparar bordes del lote o entradas de invernadero.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_thrips_virus_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Trips, raspado o virus asociados',
    stages: _vectorStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalVectorPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'thrips_eggplant_complex',
        labelEs: 'Trips',
        scientificName: 'Frankliniella spp. / Thrips spp.',
        type: 'insect',
        summaryEs:
            'Raspado fino en brotes, flores y fruto joven; tambien puede asociarse a virus.',
      ),
      PlantHealthDiagnosis(
        id: 'thrips_eggplant_virus_complex',
        labelEs: 'Virus asociados a trips',
        scientificName: 'Orthotospovirus complex',
        type: 'virus',
        summaryEs:
            'Deformacion, bronceado o anillos con trips presentes elevan sospecha viral.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Sacudir flores sobre hoja blanca y buscar trips.',
      'Revisar brotes nuevos y frutos pequenos por raspado o deformacion.',
      'Si hay anillos o mosaico, dejar abierta sospecha viral.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[_visualQualityModifier],
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_aphids_virus_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Pulgones, rizado o virus',
    stages: _vectorStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomAphidColonies,
    strongSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalLeafRolling,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'aphids_eggplant_virus_complex',
        labelEs: 'Pulgones y virus no persistentes',
        scientificName: 'Aphididae / potyvirus complex',
        type: 'insect_virus',
        summaryEs:
            'Colonias en brotes, mielecilla, rizado y posible mosaico; revisar temprano porque se mueve por focos.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar brotes tiernos y enves.',
      'Buscar mielecilla o hormigas asociadas.',
      'Si hay mosaico, comparar con plantas cercanas.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_spider_mites_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Punteado fino, bronceado o acaros',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tetranychus_eggplant',
        labelEs: 'Arana roja / acaros',
        scientificName: 'Tetranychus spp.',
        type: 'mite',
        summaryEs:
            'Punteado, bronceado y posible telarana fina; sube con calor, polvo y sequedad.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar enves con lupa y buscar telarana fina.',
      'Comparar bordes secos o zonas polvosas.',
      'Distinguir de trips: acaros dejan punteado fino y colonias en enves.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_broad_mite_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Brote enchinado o fruto rugoso - acaro blanco',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomFruitDeformation,
    strongSignals: <String>{
      PlantHealthIds.signalLeafRolling,
      PlantHealthIds.signalDeformedNoRot,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'polyphagotarsonemus_eggplant',
        labelEs: 'Acaro blanco',
        scientificName: 'Polyphagotarsonemus latus',
        type: 'mite',
        summaryEs:
            'Deforma brotes, hojas tiernas y fruto joven; puede confundirse con virus o fitotoxicidad.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar brotes tiernos y enves con lupa.',
      'Comparar deformacion nueva contra hojas viejas normales.',
      'Descartar deriva o mezcla reciente si el patron entro de golpe.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[_visualQualityModifier],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_leafminer_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Galerias en hoja - minador',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomLeafMines,
    strongSignals: <String>{
      PlantHealthIds.signalLeafMines,
      PlantHealthIds.signalVectorPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'liriomyza_eggplant',
        labelEs: 'Minador de hoja',
        scientificName: 'Liriomyza spp.',
        type: 'insect',
        summaryEs:
            'Minas o galerias dentro de la hoja; reduce area foliar y abre entrada a manchas si hay dano alto.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar galerias serpenteadas y larva dentro de la hoja.',
      'Revisar hojas medias y bajas.',
      'Cuantificar porcentaje de hojas con mina activa.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_flea_beetles_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Hojas perforadas - pulguilla/escarabajos',
    stages: _leafChewingStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalNoBiteMarks,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'flea_beetle_eggplant',
        labelEs: 'Pulguilla / escarabajos defoliadores',
        scientificName: 'Chrysomelidae complex',
        type: 'insect',
        summaryEs:
            'Perforaciones pequenas o mordidas en hoja, muy importante en plantula y establecimiento.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar si hay insectos brincadores o mordida fresca.',
      'Cuantificar dano en hojas nuevas.',
      'Separar de manchas: aqui hay agujero real o raspado de mordida.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_fruitworms_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Fruto mordido o perforado - gusanos fruteros',
    stages: _productiveStages,
    organIds: <String>{PlantHealthIds.organFruit, PlantHealthIds.organFlower},
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalFrassPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'fruitworms_eggplant',
        labelEs: 'Gusanos/fruteros',
        scientificName: 'Helicoverpa spp. / Spodoptera spp.',
        type: 'insect',
        summaryEs:
            'Mordidas, perforaciones, excretas o dano interno en fruto; no confundir con pudricion primaria.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Abrir frutos danados para buscar larva, galeria o excretas.',
      'Revisar flores y frutos pequenos antes de que el dano avance.',
      'Separar perforacion de pudricion secundaria.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.eggplantCropId,
        varietyIds: _fruitQualityVarieties,
        diagnosisIds: <String>{'fruitworms_eggplant'},
        scoreDelta: 6,
        rationaleEs:
            'Berenjena se vende por fruto fresco; perforaciones bajan valor y predisponen pudricion.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'eggplant_root_knot_nematode_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Agallas en raiz y planta frenada',
    stages: _fullCycleStages,
    organIds: <String>{PlantHealthIds.organRoot, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomRootGalls,
    strongSignals: <String>{
      PlantHealthIds.signalRootGalls,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'meloidogyne_eggplant',
        labelEs: 'Nematodos agalladores',
        scientificName: 'Meloidogyne spp.',
        type: 'nematode',
        summaryEs:
            'Agallas en raiz, planta frenada y bajo cuaje aunque haya agua; revisar por focos y antecedentes del lote.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Sacar raiz completa y buscar nudos o agallas.',
      'Comparar focos con zonas sanas.',
      'Separar de deficit de agua midiendo humedad real.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_flower_abortion_heat_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Aborto floral por calor o estres',
    stages: _productiveStages,
    organIds: <String>{PlantHealthIds.organFlower, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalFlowerDrop,
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'eggplant_heat_flower_abortion',
        labelEs: 'Aborto floral por calor/estres hidrico',
        type: 'abiotic',
        summaryEs:
            'Caida de flor o mal amarre con calor, baja humedad disponible o riego irregular en ventana critica.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Cruzar caida de flor con picos de calor y sequedad.',
      'Revisar humedad real del suelo en horas criticas.',
      'Descartar trips en flor si hay raspado o vector.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_water_deficit_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Deficit hidrico en etapa sensible',
    stages: _productiveStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFruitDeformation,
    strongSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalLeafRolling,
      PlantHealthIds.signalFlowerDrop,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'eggplant_water_deficit',
        labelEs: 'Deficit hidrico / riego irregular',
        type: 'abiotic',
        summaryEs:
            'Berenjena resiente seca en floracion, cuajado y llenado; puede fallar amarre, deformar fruto o bajar brillo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Cruzar sintomas con lectura de humedad y calendario de riego.',
      'Revisar si el dano aparece despues de picos de calor.',
      'Separar deficit de salinidad midiendo CE.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_waterlogging_anoxia_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Exceso de humedad y anoxia radicular',
    stages: _fullCycleStages,
    organIds: <String>{PlantHealthIds.organRoot, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'eggplant_waterlogging_root_risk',
        labelEs: 'Asfixia radicular / predisposicion a pudriciones',
        type: 'abiotic_risk',
        summaryEs:
            'El exceso de humedad baja oxigeno en raiz y abre puerta a Phytophthora, Pythium y Rhizoctonia.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar drenaje, charcos y olor a anaerobiosis.',
      'Sacar raiz para evaluar color y firmeza.',
      'Confirmar si el patron sigue zonas bajas o riego.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_salinity_stress_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Salinidad elevada durante etapa sensible',
    stages: _fullCycleStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFruitDeformation,
    strongSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalLeafRolling,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'eggplant_salinity_stress',
        labelEs: 'Salinidad / CE alta',
        type: 'abiotic',
        summaryEs:
            'CE alta reduce absorcion de agua y compite con Ca/K/Mg; castiga cuajado, llenado y calidad de fruto.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar CE del sensor o analisis de suelo/agua.',
      'Cruzar con puntas quemadas, aborto floral o fruto deforme.',
      'Separar salinidad de seca real midiendo humedad del suelo.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[_visualQualityModifier],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_sunscald_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Golpe de sol en fruto',
    stages: _productiveStages,
    organIds: <String>{PlantHealthIds.organFruit, PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalScaldBleaching,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'eggplant_sunscald_heat_exposure',
        labelEs: 'Golpe de sol / escaldado de fruto',
        type: 'abiotic',
        summaryEs:
            'Areas blanquecinas, hundidas o quemadas del lado expuesto del fruto, sobre todo con deshoje, defoliacion y calor fuerte.',
      ),
      PlantHealthDiagnosis(
        id: 'eggplant_visual_quality_loss',
        labelEs: 'Riesgo de rechazo visual',
        type: 'quality_risk',
        summaryEs:
            'En tipos blancos o rayados, marcas de sol o cicatrices bajan valor aunque no sean enfermedad primaria.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Ver si el dano esta del lado mas expuesto al sol.',
      'Cruzar con deshoje, poda, defoliacion o calor reciente.',
      'Descartar antracnosis si hay masa de esporas o lesion que avanza con humedad.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[_visualQualityModifier],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_phytotoxicity_drift_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Quemado irregular - fitotoxicidad o deriva',
    stages: _fullCycleStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalNoBiteMarks,
      PlantHealthIds.signalCannotScrapeOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'eggplant_phytotoxicity_or_drift',
        labelEs: 'Fitotoxicidad / deriva',
        type: 'abiotic',
        summaryEs:
            'Quemado, manchas, deformacion o aborto floral que aparece rapido despues de aplicacion, mezcla fuerte o deriva externa.',
      ),
      PlantHealthDiagnosis(
        id: 'eggplant_visual_quality_loss',
        labelEs: 'Riesgo de rechazo visual',
        type: 'quality_risk',
        summaryEs:
            'Rayada y blanca muestran fitotoxicidad con mas castigo visual; confirmar patron antes de cerrar diagnostico.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Cruzar aparicion con aplicaciones, mezclas, limpieza de tanque o deriva vecina.',
      'Ver si el patron sigue borde, viento, cama o pasada de aspersion.',
      'Descartar plaga si no hay mordida, colonia, mina ni vector dominante.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[_visualQualityModifier],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'eggplant_nutrient_imbalance_01',
    cropId: CropCatalog.eggplantCropId,
    labelEs: 'Desbalance nutricional o calidad de fruto',
    stages: _productiveStages,
    organIds: <String>{PlantHealthIds.organFruit, PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomFruitDeformation,
    strongSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalDeformedNoRot,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'eggplant_ca_mg_k_water_imbalance',
        labelEs: 'Desbalance K-Ca-Mg / agua',
        type: 'abiotic',
        summaryEs:
            'Fruto deforme, blando o marcado sin pudricion clara puede venir de riego irregular, CE alta o antagonismo K-Ca-Mg.',
      ),
      PlantHealthDiagnosis(
        id: 'eggplant_generic_early_warning',
        labelEs: 'Alerta conservadora BE-GEN',
        type: 'profile_warning',
        summaryEs:
            'Con perfil generico conviene revisar temprano sin asumir tipo o potencial productivo especifico.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Cruzar con lecturas NPK, pH, CE y humedad.',
      'Revisar si el dano esta en fruto nuevo o en varios cortes.',
      'Separar de plaga o enfermedad si no hay perforacion ni masa de esporas.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _genericCautionModifier,
      VarietyModifier(
        cropId: CropCatalog.eggplantCropId,
        varietyIds: _ovalVarieties,
        diagnosisIds: <String>{'eggplant_ca_mg_k_water_imbalance'},
        scoreDelta: 6,
        rationaleEs:
            'Berenjena oval/bola castiga tamano y uniformidad; subir desbalance si hay fruto deforme.',
      ),
      VarietyModifier(
        cropId: CropCatalog.eggplantCropId,
        varietyIds: _stripedVarieties,
        diagnosisIds: <String>{'eggplant_ca_mg_k_water_imbalance'},
        scoreDelta: 6,
        rationaleEs:
            'Berenjena rayada requiere calidad visual; CE y agua irregular marcan rapido.',
        requiresCaution: true,
      ),
      VarietyModifier(
        cropId: CropCatalog.eggplantCropId,
        varietyIds: _whiteVarieties,
        diagnosisIds: <String>{'eggplant_ca_mg_k_water_imbalance'},
        scoreDelta: 7,
        rationaleEs:
            'Berenjena blanca muestra mas manchas y rechazo visual; confirmar antes de cerrar diagnostico.',
        requiresCaution: true,
      ),
    ],
    favorsRecentStress: true,
  ),
];
