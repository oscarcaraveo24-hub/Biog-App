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

const Set<String> _habaneroVarieties = <String>{'chili_habanero', 'ch_07'};

const Set<String> _serranoVarieties = <String>{'chili_serrano', 'ch_02'};

const Set<String> _bellPepperVarieties = <String>{
  'chili_bell_pepper',
  'chili_bell_pepper_protected',
  'ch_08',
};

const Set<String> _poblanoAnchoVarieties = <String>{
  'chili_poblano_ancho',
  'chili_ancho_dry',
  'ch_03',
};

const Set<String> _dryChiliVarieties = <String>{
  'chili_guajillo_mirasol',
  'chili_chilaca_pasilla',
  'chili_arbol_puya',
  'chili_arbol_puya_dry',
  'ch_04',
  'ch_05',
  'ch_06',
};

const String _disclaimer =
    'Diagnostico sugerido. BIO-G orienta monitoreo y decision base; confirma en campo y con apoyo tecnico cuando el dano avance o haya duda.';

const List<String> _baseSanitaryActions = <String>[
  'Marcar focos por cama o zona y revisar avance en 24-48 horas.',
  'Retirar tejido muy afectado si ya funciona como fuente de inoculo.',
  'Corregir riego, drenaje y ventilacion antes de perseguir sintomas.',
  'Documentar fotos, etapa y clima reciente para comparar evolucion.',
];

const List<PlantHealthSyndrome> chiliSyndromes = <PlantHealthSyndrome>[
  PlantHealthSyndrome(
    id: 'chili_damping_off_01',
    cropId: CropCatalog.chiliCropId,
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
        id: 'pythium_rhizoctonia_chili_seedling',
        labelEs: 'Damping-off por Pythium / Rhizoctonia',
        scientificName: 'Pythium spp. / Rhizoctonia solani',
        type: 'oomycete_fungus',
        summaryEs:
            'Cuello vencido, raiz oscura o plantulas que se caen despues de emergencia; sube con humedad excesiva y sustrato o suelo frio.',
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
    id: 'chili_phytophthora_root_rot_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Marchitez con cuello o raiz podrida - Phytophthora',
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
        id: 'phytophthora_capsici_chili',
        labelEs: 'Phytophthora capsici',
        scientificName: 'Phytophthora capsici',
        type: 'oomycete',
        summaryEs:
            'Complejo radicular y de cuello muy serio en chile. Se dispara con exceso de humedad, drenaje pobre y agua que mueve inoculo.',
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
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _habaneroVarieties,
        diagnosisIds: <String>{'phytophthora_capsici_chili'},
        scoreDelta: 7,
        rationaleEs:
            'Habanero es mas sensible a calor-humedad y a estres radicular; Phytophthora debe quedar mas arriba, sin cerrar diagnostico.',
        requiresCaution: true,
      ),
    ],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_fusarium_wilt_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Marchitez vascular - Fusarium',
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
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'fusarium_oxysporum_chili',
        labelEs: 'Marchitez fusariana',
        scientificName: 'Fusarium oxysporum complex',
        type: 'fungus',
        summaryEs:
            'Marchitez parcial o completa con pardeamiento vascular. Suele aparecer por focos y empeora con estres radicular.',
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
    id: 'chili_bacterial_spot_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Mancha bacteriana en hoja o fruto',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomBacterialSpeckSpot,
    strongSignals: <String>{
      PlantHealthIds.signalWaterSoakedMargin,
      PlantHealthIds.signalAngularLesionPattern,
      PlantHealthIds.signalHaloMargin,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'xanthomonas_chili_spot_complex',
        labelEs: 'Mancha bacteriana',
        scientificName: 'Xanthomonas euvesicatoria complex',
        type: 'bacteria',
        summaryEs:
            'Lesiones acuosas o angulares en hoja y manchas en fruto. Sube con salpique, labores con follaje mojado y humedad alta.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar borde acuoso o halo, no solo necrosis seca.',
      'Revisar si hubo lluvia, salpique o poda en mojado.',
      'Buscar lesiones en fruto joven si ya hay cuajado.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _bellPepperVarieties,
        diagnosisIds: <String>{'xanthomonas_chili_spot_complex'},
        scoreDelta: 6,
        rationaleEs:
            'Morron/chile gordo castiga mucho la calidad visual; mancha bacteriana en hoja o fruto debe subir como diferencial prudente.',
        requiresCaution: true,
      ),
    ],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_anthracnose_01',
    cropId: CropCatalog.chiliCropId,
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
        id: 'colletotrichum_chili',
        labelEs: 'Antracnosis',
        scientificName: 'Colletotrichum spp.',
        type: 'fungus',
        summaryEs:
            'Lesiones hundidas y oscuras en fruto, a veces con masa rosada o naranja de esporas. Pega fuerte en cosecha y postcosecha.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar lesion hundida circular o alargada en fruto.',
      'Confirmar si aparece masa rosada de esporas con humedad.',
      'Revisar frutos cercanos a madurez y residuos infectados.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _habaneroVarieties,
        diagnosisIds: <String>{'colletotrichum_chili'},
        scoreDelta: 6,
        rationaleEs:
            'Habanero con calor-humedad sostiene mayor riesgo de antracnosis en fruto; subir diferencial con cautela.',
        requiresCaution: true,
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _poblanoAnchoVarieties,
        diagnosisIds: <String>{'colletotrichum_chili'},
        scoreDelta: 5,
        rationaleEs:
            'Poblano/ancho tiene fruto grande y destino de calidad; antracnosis/mancha de fruto debe vigilarse de cerca.',
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _dryChiliVarieties,
        diagnosisIds: <String>{'colletotrichum_chili'},
        scoreDelta: 7,
        rationaleEs:
            'Chiles de mercado seco son sensibles a humedad en cosecha y manchas de fruto; antracnosis sube como sospecha prudente.',
        requiresCaution: true,
      ),
    ],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_powdery_mildew_01',
    cropId: CropCatalog.chiliCropId,
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
        id: 'leveillula_taurica_chili',
        labelEs: 'Cenicilla',
        scientificName: 'Leveillula taurica / Oidium spp.',
        type: 'fungus',
        summaryEs:
            'Polvillo blanco o clorosis asociada a cenicilla; reduce area foliar y calidad si avanza en produccion.',
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
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _bellPepperVarieties,
        diagnosisIds: <String>{'leveillula_taurica_chili'},
        scoreDelta: 5,
        rationaleEs:
            'Morron/chile gordo bajo protegido puede sostener humedad y follaje denso; cenicilla queda un poco mas arriba.',
        requiresCaution: true,
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'chili_botrytis_01',
    cropId: CropCatalog.chiliCropId,
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
        id: 'botrytis_cinerea_chili',
        labelEs: 'Botrytis / moho gris',
        scientificName: 'Botrytis cinerea',
        type: 'fungus',
        summaryEs:
            'Moho gris sobre flores, heridas o frutos en ambientes protegidos con alta humedad y poca ventilacion.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar flores secas, heridas de poda y fruto con tejido blando.',
      'Confirmar moho gris que suelta polvo al tocarlo.',
      'Cruzar con humedad nocturna y condensacion.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _bellPepperVarieties,
        diagnosisIds: <String>{'botrytis_cinerea_chili'},
        scoreDelta: 6,
        rationaleEs:
            'Morron/chile gordo en protegido pierde calidad rapido con moho gris; subir Botrytis si coincide humedad o mala ventilacion.',
        requiresCaution: true,
      ),
    ],
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_thrips_tswv_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Trips, bronceado o virus asociados',
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
        id: 'thrips_chili_complex',
        labelEs: 'Trips',
        scientificName: 'Frankliniella spp. / Thrips spp.',
        type: 'insect',
        summaryEs:
            'Raspado fino y bronceado en brotes, flores y fruto joven. Es clave por dano directo y por virus.',
      ),
      PlantHealthDiagnosis(
        id: 'tswv_chili',
        labelEs: 'Virus transmitidos por trips (incluye TSWV)',
        scientificName: 'Tomato spotted wilt virus complex',
        type: 'virus',
        summaryEs:
            'Deformacion, bronceado, mosaico o anillos con trips presentes elevan sospecha de virus.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Sacudir flores sobre hoja blanca y buscar trips.',
      'Revisar brotes nuevos y frutos pequenos por raspado o deformacion.',
      'Si hay anillos, mosaico o deformacion fuerte, dejar abierta sospecha viral.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _habaneroVarieties,
        diagnosisIds: <String>{'thrips_chili_complex', 'tswv_chili'},
        scoreDelta: 7,
        rationaleEs:
            'Habanero es sensible a trips y virus en brotes/flores; subir diferencial sin cerrar diagnostico.',
        requiresCaution: true,
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _serranoVarieties,
        diagnosisIds: <String>{'thrips_chili_complex', 'tswv_chili'},
        scoreDelta: 6,
        rationaleEs:
            'Serrano de alta carga sufre por trips, raspado y virus; el tipo empuja la sospecha si hay vector.',
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _bellPepperVarieties,
        diagnosisIds: <String>{'thrips_chili_complex', 'tswv_chili'},
        scoreDelta: 5,
        rationaleEs:
            'Morron/chile gordo muestra perdida visual con trips en flor/fruto joven; subir revision.',
      ),
    ],
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_whitefly_virus_01',
    cropId: CropCatalog.chiliCropId,
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
        id: 'whitefly_chili_begomovirus_complex',
        labelEs: 'Mosca blanca y virus asociados',
        scientificName: 'Bemisia tabaci / begomovirus complex',
        type: 'insect_virus',
        summaryEs:
            'Mosca blanca puede causar dano directo, mielecilla y transmitir virus que deforman y amarillean brotes.',
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
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _habaneroVarieties,
        diagnosisIds: <String>{'whitefly_chili_begomovirus_complex'},
        scoreDelta: 7,
        rationaleEs:
            'Habanero suele ser muy castigado por mosca blanca y virus en ambientes calidos; subir diferencial con cautela.',
        requiresCaution: true,
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _serranoVarieties,
        diagnosisIds: <String>{'whitefly_chili_begomovirus_complex'},
        scoreDelta: 5,
        rationaleEs:
            'Serrano en alta carga no tolera bien presion de mosca blanca/virus; revisar temprano.',
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _bellPepperVarieties,
        diagnosisIds: <String>{'whitefly_chili_begomovirus_complex'},
        scoreDelta: 5,
        rationaleEs:
            'Morron/chile gordo bajo protegido puede acumular presion de mosca blanca; subir sospecha si hay vector.',
      ),
    ],
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_aphids_virus_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Pulgon, rizado o virus asociados',
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
        id: 'aphids_chili_virus_complex',
        labelEs: 'Pulgones y virus no persistentes',
        scientificName: 'Aphididae / potyvirus complex',
        type: 'insect_virus',
        summaryEs:
            'Colonias en brotes, mielecilla, hojas enrolladas y posible transmision viral en etapas tempranas.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar enves y brotes tiernos por colonias.',
      'Buscar mielecilla o fumagina.',
      'Si hay mosaico sin colonia visible, revisar historial de llegada del vector.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_pepper_weevil_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Botones o frutos perforados - picudo del chile',
    stages: _productiveStages,
    organIds: <String>{PlantHealthIds.organFlower, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalFlowerDrop,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'anthonomus_eugenii_chili',
        labelEs: 'Picudo del chile',
        scientificName: 'Anthonomus eugenii',
        type: 'insect',
        summaryEs:
            'Perfora botones, flores y frutos pequenos; provoca caida y dano interno dificil de ver tarde.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Abrir botones o frutos caidos para buscar larva o dano interno.',
      'Revisar perforaciones pequenas y excretas.',
      'Mapear focos cerca de bordes o residuos de chile previo.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _habaneroVarieties,
        diagnosisIds: <String>{'anthonomus_eugenii_chili'},
        scoreDelta: 6,
        rationaleEs:
            'Habanero con flor/fruto joven puede perder mucho por picudo; subir diferencial si hay botones o frutos caidos.',
        requiresCaution: true,
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _serranoVarieties,
        diagnosisIds: <String>{'anthonomus_eugenii_chili'},
        scoreDelta: 8,
        rationaleEs:
            'Serrano de cosecha continua mantiene botones y frutos pequenos; picudo debe pesar mas en el ranking.',
        requiresCaution: true,
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _dryChiliVarieties,
        diagnosisIds: <String>{'anthonomus_eugenii_chili'},
        scoreDelta: 6,
        rationaleEs:
            'Chiles de fruto pequeno/seco pueden ocultar dano interno; picudo sube si hay perforacion o caida.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'chili_spider_mites_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Bronceado con telarana fina - arana roja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tetranychus_chili_complex',
        labelEs: 'Arana roja / acaros',
        scientificName: 'Tetranychus urticae complex',
        type: 'mite',
        summaryEs:
            'Punteado, bronceado y telarana fina; avanza rapido en clima seco y caliente.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar enves con lupa por acaros y huevos.',
      'Confirmar telarana fina en focos avanzados.',
      'Distinguir de trips: el acaro deja punteado mas uniforme.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _habaneroVarieties,
        diagnosisIds: <String>{'tetranychus_chili_complex'},
        scoreDelta: 6,
        rationaleEs:
            'Habanero puede resentir acaros con calor y estres; subir sospecha si hay bronceado/punteado.',
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _serranoVarieties,
        diagnosisIds: <String>{'tetranychus_chili_complex'},
        scoreDelta: 5,
        rationaleEs:
            'Serrano de alta densidad puede abrir focos de acaros; revisar enves y bordes.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'chili_leafminers_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Galerias en hoja - minadores',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomLeafMines,
    strongSignals: <String>{PlantHealthIds.signalLeafMines},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'liriomyza_chili_complex',
        labelEs: 'Minadores de hoja',
        scientificName: 'Liriomyza spp.',
        type: 'insect',
        summaryEs:
            'Galerias blanquecinas dentro de la hoja. En alta presion reduce area foliar y abre puerta a estres.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar mina dentro del tejido, no mancha superficial.',
      'Revisar hojas nuevas y medias.',
      'Registrar si hay pupas o adultos cerca del foco.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _habaneroVarieties,
        diagnosisIds: <String>{'liriomyza_chili_complex'},
        scoreDelta: 5,
        rationaleEs:
            'Habanero bajo presion de hoja tierna y calor puede mostrar minador; subir solo como apoyo al monitoreo.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'chili_root_knot_nematodes_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Agallas en raiz - nematodos',
    stages: _fullCycleStages,
    organIds: <String>{PlantHealthIds.organRoot, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomRootGalls,
    strongSignals: <String>{PlantHealthIds.signalRootGalls},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'meloidogyne_chili',
        labelEs: 'Nematodos agalladores',
        scientificName: 'Meloidogyne spp.',
        type: 'nematode',
        summaryEs:
            'Plantas frenadas, amarillas o marchitas por rodales; la confirmacion real esta en agallas de raiz.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Arrancar planta completa y lavar raiz para ver agallas.',
      'Mapear rodales por cama o zona.',
      'Cruzar con historial de solanaceas repetidas.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'chili_heat_flower_abort_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Aborto floral por calor',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
    },
    organIds: <String>{PlantHealthIds.organFlower, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalFlowerDrop,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'chili_heat_flower_abort',
        labelEs: 'Estres termico en floracion',
        type: 'abiotic',
        summaryEs:
            'Picos de calor, baja humedad o riego irregular durante floracion reducen polen viable y tiran flor.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Cruzar caida de flor con maximas de temperatura recientes.',
      'Revisar humedad del suelo durante los picos de calor.',
      'Confirmar que no domina trips o picudo en botones.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _habaneroVarieties,
        diagnosisIds: <String>{'chili_heat_flower_abort'},
        scoreDelta: 7,
        rationaleEs:
            'Habanero es mas sensible a picos de calor en floracion; subir estres termico sin descartar vector.',
        requiresCaution: true,
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _serranoVarieties,
        diagnosisIds: <String>{'chili_heat_flower_abort'},
        scoreDelta: 5,
        rationaleEs:
            'Serrano de alta carga expresa rapido el aborto floral si falla humedad o temperatura.',
      ),
    ],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_poor_fruit_set_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Mal cuaje o fruto deforme',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{PlantHealthIds.organFlower, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFruitDeformation,
    strongSignals: <String>{
      PlantHealthIds.signalFlowerDrop,
      PlantHealthIds.signalDeformedNoRot,
      PlantHealthIds.signalSalinityLoad,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'chili_poor_fruit_set_stress',
        labelEs: 'Mal cuaje por estres agua-salinidad-temperatura',
        type: 'abiotic',
        summaryEs:
            'Cuaje flojo o fruto mal formado cuando se juntan calor/frio, salinidad, riego irregular o desbalance K-Ca.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar CE, humedad y picos de temperatura en flor/cuajado.',
      'Confirmar si el fruto no tiene pudricion ni mordida.',
      'Comparar con presion de trips, picudo o virus.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_cold_damage_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Dano por frio o arranque frenado',
    stages: _fullCycleStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomColdInjury,
    strongSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'chili_cold_injury',
        labelEs: 'Estres por frio',
        type: 'abiotic',
        summaryEs:
            'El chile es sensible a noches frias, sobre todo plantula, floracion y habanero. Puede frenar raiz, flor y crecimiento.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Cruzar sintomas con noches frias o trasplante expuesto.',
      'Revisar brotes y hojas nuevas por crecimiento detenido.',
      'Confirmar que raiz y cuello no esten podridos.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_salinity_stress_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Estres por salinidad',
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
        id: 'chili_salinity_stress',
        labelEs: 'Salinidad / CE alta',
        type: 'abiotic',
        summaryEs:
            'CE alta reduce absorcion de agua, compite con Ca/K y puede castigar floracion, cuajado y calidad de fruto.',
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
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_waterlogging_root_risk_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Exceso de humedad y riesgo radicular',
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
        id: 'chili_waterlogging_root_risk',
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
    id: 'chili_broad_mite_01',
    cropId: CropCatalog.chiliCropId,
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
        id: 'polyphagotarsonemus_chili',
        labelEs: 'Acaro blanco',
        scientificName: 'Polyphagotarsonemus latus',
        type: 'mite',
        summaryEs:
            'Deforma brotes, hojas tiernas, flores y fruto joven. Puede confundirse con virus o fitotoxicidad si no se revisan brotes con lupa.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar brotes tiernos y enves con lupa.',
      'Comparar deformacion nueva contra hojas viejas normales.',
      'Descartar deriva o aplicacion reciente si el patron entro de golpe.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _habaneroVarieties,
        diagnosisIds: <String>{'polyphagotarsonemus_chili'},
        scoreDelta: 9,
        rationaleEs:
            'Habanero es muy sensible a acaro blanco en brotes y fruto joven; subir diferencial, confirmando con lupa.',
        requiresCaution: true,
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _serranoVarieties,
        diagnosisIds: <String>{'polyphagotarsonemus_chili'},
        scoreDelta: 5,
        rationaleEs:
            'Serrano puede abrir focos de acaros en alta densidad; usar como alerta de monitoreo, no diagnostico cerrado.',
      ),
    ],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_psyllid_permanente_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Rizado, amarillamiento o planta parada - psilido',
    stages: _vectorStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalLeafRolling,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'bactericera_cockerelli_chili',
        labelEs: 'Psilido del chile / permanente del chile',
        scientificName: 'Bactericera cockerelli / Candidatus Liberibacter solanacearum',
        type: 'insect_bacteria',
        summaryEs:
            'Brote rizado, amarillamiento, achaparramiento y avance por focos pueden apuntar a psilido y permanente del chile.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar ninfas o adultos en brotes y enves.',
      'Mapear si el problema entro por bordes o focos calientes.',
      'Separar de virus por trips/mosca blanca revisando vector dominante.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_fruitworms_01',
    cropId: CropCatalog.chiliCropId,
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
        id: 'heliothinae_spodoptera_chili',
        labelEs: 'Gusanos fruteros / barrenadores de fruto',
        scientificName: 'Helicoverpa spp. / Spodoptera spp.',
        type: 'insect',
        summaryEs:
            'Mordidas, perforaciones, excretas y dano interno en fruto. El monitoreo temprano evita confundirlo con pudriciones secundarias.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Abrir frutos danados para buscar larva, galeria o excretas.',
      'Revisar flores y frutos pequenos antes de que el dano avance.',
      'Distinguir perforacion de picudo: gusanos suelen dejar mordida y excreta mas evidente.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _dryChiliVarieties,
        diagnosisIds: <String>{'heliothinae_spodoptera_chili'},
        scoreDelta: 6,
        rationaleEs:
            'Chiles de mercado seco o fruto pequeno pueden perder calidad por dano interno; gusanos/fruteros suben con perforacion.',
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _poblanoAnchoVarieties,
        diagnosisIds: <String>{'heliothinae_spodoptera_chili'},
        scoreDelta: 5,
        rationaleEs:
            'Poblano/ancho debe vigilar dano de fruto por su tamano y valor visual.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'chili_blossom_end_rot_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Mancha apical hundida - pudricion apical',
    stages: _productiveStages,
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFruitApicalRot,
    strongSignals: <String>{
      PlantHealthIds.signalFruitApicalBlackPatch,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'chili_blossom_end_rot_ca_water',
        labelEs: 'Pudricion apical por desbalance Ca-agua-salinidad',
        type: 'abiotic',
        summaryEs:
            'Parche oscuro hundido en la punta del fruto. Suele venir de riego irregular, CE alta o mala movilidad de calcio, no de un hongo primario.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar parche en extremo apical del fruto, sin perforacion ni larva.',
      'Revisar historial de riego, CE y humedad durante cuajado/llenado.',
      'Cruzar con lectura de K/Ca/Mg para detectar antagonismos.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Estabilizar humedad del suelo y evitar ciclos seco-encharcado.',
      'Revisar CE antes de subir fertilizacion.',
      'Mantener balance K-Ca-Mg durante cuajado y llenado.',
      'Separar frutos afectados para no confundir calidad con enfermedad.',
    ],
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _bellPepperVarieties,
        diagnosisIds: <String>{'chili_blossom_end_rot_ca_water'},
        scoreDelta: 9,
        rationaleEs:
            'Morron/chile gordo tiene fruto grande y alta exigencia de Ca/agua; BER sube mucho, pero confirmar que no sea dano de plaga.',
        requiresCaution: true,
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _poblanoAnchoVarieties,
        diagnosisIds: <String>{'chili_blossom_end_rot_ca_water'},
        scoreDelta: 7,
        rationaleEs:
            'Poblano/ancho tiene fruto grande; pudricion apical sube si hubo riego irregular, CE o desbalance K-Ca-Mg.',
      ),
    ],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_sunscald_01',
    cropId: CropCatalog.chiliCropId,
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
        id: 'chili_sunscald_heat_exposure',
        labelEs: 'Golpe de sol / escaldado de fruto',
        type: 'abiotic',
        summaryEs:
            'Areas blanquecinas, hundidas o quemadas del lado expuesto del fruto, sobre todo con deshoje, baja cobertura y calor fuerte.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Ver si el dano esta del lado mas expuesto al sol.',
      'Cruzar con deshoje, poda, defoliacion o calor reciente.',
      'Descartar antracnosis si hay masa de esporas o lesion que avanza con humedad.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Proteger cobertura foliar funcional sin forzar exceso de nitrogeno.',
      'Evitar deshojes fuertes en olas de calor.',
      'Mejorar uniformidad de riego durante picos termicos.',
      'Registrar zonas y orientacion del dano para ajustar manejo.',
    ],
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _bellPepperVarieties,
        diagnosisIds: <String>{'chili_sunscald_heat_exposure'},
        scoreDelta: 7,
        rationaleEs:
            'Morron/chile gordo pierde calidad visual por exposicion; golpe de sol sube si falta cobertura.',
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _poblanoAnchoVarieties,
        diagnosisIds: <String>{'chili_sunscald_heat_exposure'},
        scoreDelta: 7,
        rationaleEs:
            'Poblano/ancho tiene fruto grande expuesto; sunscald debe quedar alto si el dano sigue el lado del sol.',
      ),
      VarietyModifier(
        cropId: CropCatalog.chiliCropId,
        varietyIds: _dryChiliVarieties,
        diagnosisIds: <String>{'chili_sunscald_heat_exposure'},
        scoreDelta: 5,
        rationaleEs:
            'Chiles secos o de fruto pequeno pueden marcarse con calor y baja cobertura; subir golpe de sol como diferencial.',
      ),
    ],
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_phytotoxicity_drift_01',
    cropId: CropCatalog.chiliCropId,
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
        id: 'chili_phytotoxicity_or_drift',
        labelEs: 'Fitotoxicidad / deriva',
        type: 'abiotic',
        summaryEs:
            'Quemado, manchas, deformacion o aborto floral que aparece rapido despues de aplicacion, mezcla fuerte o deriva externa.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Cruzar aparicion con aplicaciones, mezclas, limpieza de tanque o deriva vecina.',
      'Ver si el patron sigue borde, viento, cama o pasada de aspersion.',
      'Descartar plaga si no hay mordida, colonia, mina ni vector dominante.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Detener repeticiones de la mezcla sospechosa hasta revisar causa.',
      'Registrar producto, dosis, agua, hora, clima y equipo usado.',
      'Revisar pH/CE del caldo o agua si hay antecedente disponible.',
      'Monitorear rebrote nuevo para distinguir dano pasado de avance activo.',
    ],
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_alternaria_leaf_blight_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Mancha foliar con anillos - Alternaria',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCannotScrapeOff,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'alternaria_chili_leaf_spot',
        labelEs: 'Alternaria / tizon foliar',
        scientificName: 'Alternaria spp.',
        type: 'fungus',
        summaryEs:
            'Manchas necroticas con posible patron de anillos; aumenta con humedad, tejido viejo y estres de planta.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar manchas cafe con borde definido o anillos concentricos.',
      'Revisar hojas bajas y medias primero.',
      'Cruzar con humedad reciente y residuos infectados.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_cercospora_leaf_spot_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Mancha foliar circular o angular - Cercospora',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAngularSpots,
    strongSignals: <String>{
      PlantHealthIds.signalAngularLesionPattern,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCannotScrapeOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cercospora_chili_leaf_spot',
        labelEs: 'Cercospora / mancha foliar',
        scientificName: 'Cercospora spp.',
        type: 'fungus',
        summaryEs:
            'Manchas circulares o angulares que reducen area foliar y predisponen a golpe de sol si defolian.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar si las manchas siguen venas o forman centros claros.',
      'Confirmar que no haya borde acuoso tipico de bacteria.',
      'Cruzar con humedad, salpique y ventilacion.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'chili_contact_seed_virus_01',
    cropId: CropCatalog.chiliCropId,
    labelEs: 'Mosaico persistente sin vector claro',
    stages: _fullCycleStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalCannotScrapeOff,
      PlantHealthIds.signalNoBiteMarks,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tobamovirus_chili_complex',
        labelEs: 'Virus por semilla/contacto (tobamovirus complex)',
        scientificName: 'PMMoV / TMV / ToMV complex',
        type: 'virus',
        summaryEs:
            'Mosaico, deformacion o planta frenada sin vector dominante. Puede moverse por semilla, planta, herramientas o contacto.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar si el mosaico aparece aun sin trips, mosca blanca o pulgon fuerte.',
      'Comparar plantas del mismo lote de planta o charola.',
      'Documentar labores recientes de poda, tutoreo o manejo manual.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseSanitaryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
];
