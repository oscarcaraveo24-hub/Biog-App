import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo sanitario de avena.
///
/// Fuentes principales:
/// - INIFAP, agendas técnicas y mejoramiento genético de avena en México.
/// - Scielo / INIFAP: Turquesa y Ágata.
/// - USDA ARS / extensiones universitarias para royas, manchas foliares y áfidos.
const List<PlantHealthSyndrome> oatSyndromes = <PlantHealthSyndrome>[
  // ── 1. Royas de la avena ──────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'oat_rust_pustules_01',
    cropId: CropCatalog.oatCropId,
    labelEs: 'Pústulas naranja-rojizas en hoja, tallo o panícula',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organSpike,
    },
    primarySymptomId: PlantHealthIds.symptomOrangeReddishPustules,
    strongSignals: <String>{
      PlantHealthIds.signalSporesRubOff,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalPustulesOnStem,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    conflictingSignals: <String>{
      PlantHealthIds.signalNoClearPustules,
      PlantHealthIds.signalCannotScrapeOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'oat_leaf_crown_rust',
        labelEs: 'Roya de la hoja / corona',
        scientificName: 'Puccinia coronata f. sp. avenae',
        type: 'fungus',
        summaryEs:
            'Sospecha alta cuando predominan pústulas anaranjadas en hojas. En avena suele ser una de las royas más comunes y puede reducir forraje y grano.',
        contradictorySignalIds: <String>{PlantHealthIds.signalPustulesOnStem},
      ),
      PlantHealthDiagnosis(
        id: 'oat_stem_rust',
        labelEs: 'Roya del tallo',
        scientificName: 'Puccinia graminis f. sp. avenae',
        type: 'fungus',
        summaryEs:
            'Sube mucho cuando también hay pústulas en tallo o vainas foliares. En México es una de las enfermedades más agresivas de la avena.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalPustulesOnStem},
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar que sí hay pústulas con polvo de esporas al raspar.',
      'Si el cuadro está casi solo en hojas, mantener muy alta la sospecha de roya de la hoja / corona.',
      'Si también hay pústulas en tallo o vainas, subir roya del tallo.',
      'Si no hay pústulas claras y solo hay necrosis, cambiar hacia manchas foliares.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Revisar el tercio superior del follaje y presencia de pústulas en tallo.',
      'Si el cuadro avanza antes o durante embuche / espigamiento, escalar revisión técnica el mismo día.',
      'Documentar variedad sembrada, porque en avena la reacción varietal cambia mucho el riesgo.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. No confirma raza fisiológica ni sustituye revisión técnica presencial.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.oatCropId,
        varietyIds: <String>{'oat_chihuahua', 'oat_cuauhtemoc'},
        diagnosisIds: <String>{'oat_stem_rust'},
        scoreDelta: 12,
        rationaleEs:
            'Chihuahua y Cuauhtémoc están documentadas como altamente susceptibles a roya del tallo en México.',
      ),
      VarietyModifier(
        cropId: CropCatalog.oatCropId,
        varietyIds: <String>{'oat_agata'},
        diagnosisIds: <String>{'oat_stem_rust', 'oat_leaf_crown_rust'},
        scoreDelta: -10,
        rationaleEs:
            'Ágata se reporta resistente a moderadamente resistente a roya del tallo y roya de la corona.',
      ),
      VarietyModifier(
        cropId: CropCatalog.oatCropId,
        varietyIds: <String>{'oat_turquesa'},
        diagnosisIds: <String>{'oat_stem_rust', 'oat_leaf_crown_rust'},
        scoreDelta: -8,
        rationaleEs:
            'Turquesa se reporta moderadamente resistente a roya del tallo y con muy buen comportamiento frente a roya de la hoja / corona.',
      ),
      VarietyModifier(
        cropId: CropCatalog.oatCropId,
        varietyIds: <String>{'oat_karma'},
        diagnosisIds: <String>{'oat_stem_rust'},
        scoreDelta: -5,
        rationaleEs:
            'Karma ha mostrado mejor estabilidad y resistencia relativa frente a roya del tallo que Chihuahua en evaluaciones mexicanas.',
      ),
    ],
  ),

  // ── 2. Manchas foliares de la avena ───────────────────────────────────────
  PlantHealthSyndrome(
    id: 'oat_leaf_blotch_01',
    cropId: CropCatalog.oatCropId,
    labelEs: 'Manchas foliares rojizas, café o grisáceas sin pústulas claras',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{PlantHealthIds.signalNoClearPustules},
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    conflictingSignals: <String>{
      PlantHealthIds.signalPustulesOnStem,
      PlantHealthIds.signalSporesRubOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'drechslera_avenae',
        labelEs: 'Mancha foliar / helmintosporiosis de la avena',
        scientificName: 'Drechslera avenae',
        type: 'fungus',
        summaryEs:
            'Encaja cuando predominan manchas rojizo-café o estrías cortas con margen púrpura, especialmente desde etapas tempranas.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalNoClearPustules},
      ),
      PlantHealthDiagnosis(
        id: 'parastagonospora_avenae',
        labelEs: 'Septoria de la avena',
        scientificName: 'Parastagonospora avenae',
        type: 'fungus',
        summaryEs:
            'Sospecharla si las lesiones son grisáceas a café, algo lineales o rectangulares, y pueden mostrar puntitos negros en tejido maduro.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'oat_stress_or_phyto',
        labelEs: 'Estrés / fitotoxicidad',
        type: 'stress',
        summaryEs:
            'Mantener abierto cuando la lesión es atípica, no hay pústulas, y el patrón no encaja bien con enfermedad foliar.',
        contradictorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      'Si hay manchas rojizas o café con tendencia a necrosarse sin pústulas, pensar primero en mancha foliar.',
      'Si la lesión es grisácea, más lineal o rectangular, revisar con lupa si existen puntitos negros de fructificación.',
      'Si realmente hay pústulas con polvo, mover el caso a roya.',
      'Separar mancha foliar real de quemadura ambiental o fitotoxicidad.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Revisar hoja bandera y pérdida de área foliar funcional.',
      'Documentar si el problema arrancó desde plántula, porque eso favorece helmintosporiosis.',
      'Si el cultivo se acerca a espigamiento y el daño escala, acelerar la confirmación.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La discriminación visual mejora mucho con foto o revisión presencial.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.oatCropId,
        varietyIds: <String>{'oat_agata'},
        diagnosisIds: <String>{'drechslera_avenae', 'parastagonospora_avenae'},
        scoreDelta: -8,
        rationaleEs:
            'Ágata se reporta tolerante al complejo de enfermedades foliares.',
      ),
      VarietyModifier(
        cropId: CropCatalog.oatCropId,
        varietyIds: <String>{'oat_turquesa'},
        diagnosisIds: <String>{'drechslera_avenae', 'parastagonospora_avenae'},
        scoreDelta: -5,
        rationaleEs:
            'Turquesa se reporta tolerante al complejo de enfermedades foliares.',
      ),
    ],
  ),

  // ── 3. Pulgones de la avena ───────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'oat_aphid_colonies_01',
    cropId: CropCatalog.oatCropId,
    labelEs: 'Colonias de pulgón en hojas o panícula',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organSpike,
    },
    primarySymptomId: PlantHealthIds.symptomAphidColonies,
    strongSignals: <String>{
      PlantHealthIds.signalAphidEarlyToxicity,
      PlantHealthIds.signalSpikeFeeding,
    },
    weakSignals: <String>{PlantHealthIds.signalLeafRolling},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'schizaphis_graminum',
        labelEs: 'Pulgón verde de los cereales / greenbug',
        scientificName: 'Schizaphis graminum',
        type: 'insect',
        summaryEs:
            'Sube cuando el daño es temprano, tóxico, con clorosis marcada, enrollamiento y caída rápida del vigor.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAphidEarlyToxicity,
          PlantHealthIds.signalLeafRolling,
        },
        contradictorySignalIds: <String>{PlantHealthIds.signalSpikeFeeding},
      ),
      PlantHealthDiagnosis(
        id: 'rhopalosiphum_padi',
        labelEs: 'Pulgón del cerezo-avena / bird cherry-oat aphid',
        scientificName: 'Rhopalosiphum padi',
        type: 'insect',
        summaryEs:
            'Muy común en cereales; suele dar menos daño tóxico directo, pero es vector importante de enanismo amarillo (BYDV).',
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAphidEarlyToxicity,
          PlantHealthIds.signalSpikeFeeding,
        },
      ),
      PlantHealthDiagnosis(
        id: 'macrosiphum_avenae',
        labelEs: 'Pulgón de la espiga / English grain aphid',
        scientificName: 'Macrosiphum avenae',
        type: 'insect',
        summaryEs:
            'Gana peso cuando la colonia ya está instalada en panícula / espiga y no tanto en plantas muy jóvenes.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSpikeFeeding},
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAphidEarlyToxicity,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Definir si el problema empezó en plantas jóvenes o ya está concentrado en panícula.',
      'Si hay clorosis tóxica fuerte y enrollamiento, subir greenbug.',
      'Si hay colonias visibles pero poco daño directo, mantener alto bird cherry-oat aphid.',
      'Si la colonia ya se instaló en espiga / panícula, subir English grain aphid.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Revisar varias plantas para confirmar distribución y densidad real.',
      'No subestimar colonias aparentemente leves porque varias especies transmiten BYDV.',
      'Si el lote está joven y el vigor ya cayó, priorizar validación técnica pronta.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. No sustituye identificación entomológica formal.',
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),

  // ── 4. Enanismo amarillo (BYDV) ───────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'oat_bydv_01',
    cropId: CropCatalog.oatCropId,
    labelEs:
        'Enanismo, enrojecimiento o amarillamiento desde la punta de la hoja',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomStuntingReddening,
    strongSignals: <String>{PlantHealthIds.signalVectorPresent},
    weakSignals: <String>{PlantHealthIds.signalLeafRolling},
    conflictingSignals: <String>{
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalFrassPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'barley_yellow_dwarf_virus',
        labelEs: 'Virus del enanismo amarillo (BYDV)',
        scientificName: 'Barley yellow dwarf virus',
        type: 'virus',
        summaryEs:
            'En avena suele causar enrojecimiento, amarillamiento o tonalidades bronceadas desde la punta de la hoja, con enanismo y pérdida de vigor.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalVectorPresent},
        contradictorySignalIds: <String>{
          PlantHealthIds.signalActiveChewing,
          PlantHealthIds.signalFrassPresent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'aphid_direct_damage',
        labelEs: 'Daño directo por pulgón',
        type: 'insect',
        summaryEs:
            'Debe quedar como diferencial si hay pulgones presentes pero el patrón de coloración y enanismo no es tan típico de virosis.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalLeafRolling},
        contradictorySignalIds: <String>{PlantHealthIds.signalVectorPresent},
      ),
      PlantHealthDiagnosis(
        id: 'nutrient_or_environmental_stress',
        labelEs: 'Estrés nutricional o ambiental',
        type: 'stress',
        summaryEs:
            'Mantener abierto si el enrojecimiento es difuso y no hay evidencia suficiente de pulgones o virosis.',
        contradictorySignalIds: <String>{PlantHealthIds.signalVectorPresent},
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar si el enrojecimiento o amarillamiento inicia en la punta y avanza hacia abajo.',
      'Buscar plantas en manchones o parches y confirmar si hay pulgones en el lote o cerca.',
      'Si la infección fue temprana, el enanismo suele ser mucho más evidente.',
      'La confirmación formal de virosis requiere prueba diagnóstica.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Separar daño por virosis de deficiencias nutricionales o estrés frío.',
      'Monitorear pulgones vectores y plantas voluntarias / gramíneas hospederas cercanas.',
      'Si el cuadro es temprano y en manchones, no dejarlo sin revisión.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La confirmación de BYDV requiere laboratorio.',
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),

  // ── 5. Defoliación tardía / gusano soldado ────────────────────────────────
  PlantHealthSyndrome(
    id: 'oat_late_defoliation_01',
    cropId: CropCatalog.oatCropId,
    labelEs: 'Defoliación rápida en llenado o daño foliar tardío',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    },
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organSpike},
    primarySymptomId: PlantHealthIds.symptomLateDefoliation,
    strongSignals: <String>{
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalRapidFoliarCollapse,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    conflictingSignals: <String>{PlantHealthIds.signalNoBiteMarks},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'mythimna_unipuncta',
        labelEs: 'Gusano soldado / true armyworm',
        scientificName: 'Mythimna unipuncta',
        type: 'insect',
        summaryEs:
            'Sube cuando sí hay mordidas activas, larvas, frass o incluso corte de panículas / espigas en avena.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalActiveChewing,
          PlantHealthIds.signalRapidFoliarCollapse,
        },
        contradictorySignalIds: <String>{PlantHealthIds.signalNoBiteMarks},
      ),
      PlantHealthDiagnosis(
        id: 'late_rust_collapse',
        labelEs: 'Colapso tardío por roya severa',
        type: 'fungus',
        summaryEs:
            'Debe subir si el follaje se perdió sin mordidas claras y hubo pústulas previas o rastro claro de roya.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalNoBiteMarks},
        contradictorySignalIds: <String>{PlantHealthIds.signalActiveChewing},
      ),
      PlantHealthDiagnosis(
        id: 'mechanical_environmental',
        labelEs: 'Daño mecánico o ambiental',
        type: 'stress',
        summaryEs:
            'Mantener abierto si no hay consumo activo ni signos sanitarios claros.',
        contradictorySignalIds: <String>{
          PlantHealthIds.signalActiveChewing,
          PlantHealthIds.signalHumidWindow,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar larvas, frass o mordidas recientes si se sospecha gusano soldado.',
      'Si no hay mordidas claras, revisar si hubo roya severa antes del colapso.',
      'En etapas de llenado, revisar también si hay panículas cortadas o dañadas.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Confirmar si la pérdida de follaje sigue activa.',
      'Separar defoliación por insecto de colapso sanitario tardío.',
      'Si el llenado aún depende del follaje verde, no dejar el cuadro sin revisar.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. El diferencial sigue abierto si no se confirma consumo activo o pústulas previas.',
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.oatCropId,
        varietyIds: <String>{'oat_chihuahua', 'oat_cuauhtemoc'},
        diagnosisIds: <String>{'late_rust_collapse'},
        scoreDelta: 6,
        rationaleEs:
            'Chihuahua y Cuauhtémoc tienen vulnerabilidad histórica a roya del tallo; sin mordidas claras, este diferencial sube un poco.',
      ),
      VarietyModifier(
        cropId: CropCatalog.oatCropId,
        varietyIds: <String>{'oat_turquesa', 'oat_agata'},
        diagnosisIds: <String>{'late_rust_collapse'},
        scoreDelta: -4,
        rationaleEs:
            'Turquesa y Ágata tienen mejor comportamiento relativo frente a royas que las variedades históricamente susceptibles.',
      ),
    ],
  ),
];
