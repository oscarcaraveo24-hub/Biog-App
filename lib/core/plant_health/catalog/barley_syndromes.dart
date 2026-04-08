import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo sanitario de cebada auditado con fuentes técnicas.
///
/// Base consultada para esta versión:
/// - INIFAP, Enfermedades comunes de la cebada en México (2022).
/// - INIFAP / Rev. Mex. de Fitopatología (2021), roya amarilla en cebada.
/// - UC IPM / AHDB / UMN / UMaine / PNW Handbooks para síntomas y diferenciales.
const List<PlantHealthSyndrome> barleySyndromes = <PlantHealthSyndrome>[
  // ── 1. Mancha reticulada / spot form net blotch ───────────────────────────
  PlantHealthSyndrome(
    id: 'barley_net_blotch_01',
    cropId: CropCatalog.barleyCropId,
    labelEs: 'Manchas reticuladas o manchas ovaladas en hoja',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomNetLikeSpots,
    strongSignals: <String>{
      PlantHealthIds.signalNetPattern,
      PlantHealthIds.signalNoClearPustules,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
    },
    conflictingSignals: <String>{PlantHealthIds.signalSporesRubOff},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pyrenophora_teres_net',
        labelEs: 'Mancha reticulada (net form)',
        scientificName: 'Pyrenophora teres f. teres',
        type: 'fungus',
        summaryEs:
            'Lesiones alargadas con patrón reticulado oscuro a lo largo y a través de la hoja. Puede iniciar temprano desde rastrojo o semilla infectada.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalNetPattern},
      ),
      PlantHealthDiagnosis(
        id: 'pyrenophora_teres_spot',
        labelEs: 'Mancha reticulada (spot form)',
        scientificName: 'Pyrenophora teres f. maculata',
        type: 'fungus',
        summaryEs:
            'Manchas ovaladas oscuras de 3–6 mm con halo clorótico, sin formar la red típica de la forma net.',
        contradictorySignalIds: <String>{PlantHealthIds.signalNetPattern},
      ),
    ],
    confirmationChecksEs: <String>[
      'Si la lesión forma líneas oscuras cruzadas, favorece la forma net (f. teres).',
      'Si son manchas ovaladas con halo amarillo y no se alargan, favorece la forma spot (f. maculata).',
      'Revisar si hubo rocío prolongado, humedad alta o si el lote viene de cebada sobre cebada.',
      'Si realmente hay pústulas que sueltan polvo, cambiar el diferencial hacia royas.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Revisar severidad en hojas superiores, especialmente antes de espigamiento.',
      'Priorizar rotación y manejo de rastrojo si el problema es recurrente.',
      'Si la enfermedad ya subió a hoja bandera y el clima sigue fresco-húmedo, evaluar fungicida.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La forma net y la forma spot comparten etiología general pero difieren en el patrón de lesión.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.barleyCropId,
        varietyIds: <String>{'barley_maravilla'},
        diagnosisIds: <String>{
          'pyrenophora_teres_net',
          'pyrenophora_teres_spot',
        },
        scoreDelta: -4,
        rationaleEs:
            'Maravilla fue descrita con tolerancia moderada a mancha reticular en evaluaciones del programa de cebada del INIFAP.',
      ),
    ],
  ),

  // ── 2. Escaldadura de la hoja ─────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'barley_scald_01',
    cropId: CropCatalog.barleyCropId,
    labelEs: 'Escaldadura gris / pajiza en hojas',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
    },
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organStem},
    primarySymptomId: PlantHealthIds.symptomGrayFoliarScald,
    strongSignals: <String>{
      PlantHealthIds.signalScaldBleaching,
      PlantHealthIds.signalWaterSoakedMargin,
      PlantHealthIds.signalNoClearPustules,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'rhynchosporium_commune',
        labelEs: 'Escaldadura de la cebada',
        scientificName: 'Rhynchosporium commune',
        type: 'fungus',
        summaryEs:
            'Inicia como manchas acuosas gris-verdosas y progresa a lesiones ovaladas o irregulares con centro pajizo y margen café oscuro.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalScaldBleaching,
          PlantHealthIds.signalWaterSoakedMargin,
          PlantHealthIds.signalNoClearPustules,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar inicio acuoso gris-verde que luego se vuelve pajizo o blanquecino.',
      'Confirmar margen café oscuro bien definido alrededor de la lesión.',
      'Revisar si hay lesiones también en vainas o glumas bajo clima fresco y húmedo.',
      'Si el clima se volvió caliente y seco, el avance suele frenarse.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Valorar si la enfermedad ya alcanzó hojas superiores.',
      'En lotes con antecedente, reforzar rotación, semilla sana y manejo de residuo.',
      'Si progresa antes de espigamiento bajo ambiente favorable, evaluar control foliar.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. Puede confundirse con manchas fisiológicas o daño ambiental si no se observa bien el margen oscuro.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.barleyCropId,
        varietyIds: <String>{'barley_maravilla'},
        diagnosisIds: <String>{'rhynchosporium_commune'},
        scoreDelta: -3,
        rationaleEs:
            'Maravilla fue descrita con tolerancia moderada a escaldadura de la hoja.',
      ),
    ],
  ),

  // ── 3. Complejo de royas de la cebada ─────────────────────────────────────
  PlantHealthSyndrome(
    id: 'barley_rust_01',
    cropId: CropCatalog.barleyCropId,
    labelEs: 'Pústulas anaranjadas o amarillas – complejo de royas',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organStem},
    primarySymptomId: PlantHealthIds.symptomOrangePustules,
    strongSignals: <String>{
      PlantHealthIds.signalSporesRubOff,
      PlantHealthIds.signalCoolDewyWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalPustulesOnStem,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'puccinia_striiformis_hordei',
        labelEs: 'Roya amarilla / lineal de la cebada',
        scientificName: 'Puccinia striiformis f. sp. hordei',
        type: 'fungus',
        summaryEs:
            'Pústulas amarillo-naranja alineadas entre nervaduras, favorecidas por clima fresco y húmedo. En México es una de las royas de mayor importancia económica.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalCoolDewyWindow},
        contradictorySignalIds: <String>{PlantHealthIds.signalPustulesOnStem},
      ),
      PlantHealthDiagnosis(
        id: 'puccinia_hordei',
        labelEs: 'Roya de la hoja (roya enana)',
        scientificName: 'Puccinia hordei',
        type: 'fungus',
        summaryEs:
            'Pústulas pequeñas, más redondas y dispersas en lámina foliar; a menudo con halo clorótico.',
        contradictorySignalIds: <String>{PlantHealthIds.signalPustulesOnStem},
      ),
      PlantHealthDiagnosis(
        id: 'puccinia_graminis_barley',
        labelEs: 'Roya del tallo',
        scientificName: 'Puccinia graminis',
        type: 'fungus',
        summaryEs:
            'Pústulas más grandes y alargadas, de tono rojo ladrillo, frecuentes en tallos y vainas; después se oscurecen.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalPustulesOnStem},
      ),
    ],
    confirmationChecksEs: <String>[
      'Si las pústulas forman hileras entre nervaduras, favorecer roya amarilla / lineal.',
      'Si son pequeñas, redondas y más dispersas en hoja, favorecer roya de la hoja.',
      'Si aparecen en tallo o vaina y son más alargadas con epidermis rasgada, favorecer roya del tallo.',
      'Confirmar que sí desprenden polvo de esporas al tacto.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Monitorear inmediatamente hojas inferiores y superiores para estimar avance real.',
      'Si el cultivo está antes de espigamiento o llenado temprano y el clima sigue fresco-húmedo, evaluar fungicida con rapidez.',
      'Documentar variedad sembrada: en cebada mexicana la tolerancia varietal cambia mucho el riesgo real.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. El patrón exacto de las pústulas y su ubicación ayudan a separar roya amarilla, roya de la hoja y roya del tallo.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.barleyCropId,
        varietyIds: <String>{'barley_esmeralda'},
        diagnosisIds: <String>{'puccinia_striiformis_hordei'},
        scoreDelta: -10,
        rationaleEs:
            'Esmeralda fue descrita por INIFAP como la primera variedad maltera mexicana con tolerancia a roya lineal amarilla.',
      ),
      VarietyModifier(
        cropId: CropCatalog.barleyCropId,
        varietyIds: <String>{'barley_maravilla'},
        diagnosisIds: <String>{
          'puccinia_striiformis_hordei',
          'puccinia_hordei',
        },
        scoreDelta: -7,
        rationaleEs:
            'Maravilla presenta tolerancia documentada a roya lineal amarilla y roya de la hoja.',
      ),
    ],
  ),

  // ── 4. Raya estriada de la cebada ─────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'barley_stripe_01',
    cropId: CropCatalog.barleyCropId,
    labelEs: 'Rayas longitudinales en hojas – raya estriada',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
    },
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomStripedLeaves,
    strongSignals: <String>{
      PlantHealthIds.signalDarkStriations,
      PlantHealthIds.signalSeedStaining,
    },
    weakSignals: <String>{PlantHealthIds.signalNoClearPustules},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pyrenophora_graminea',
        labelEs: 'Raya estriada',
        scientificName: 'Pyrenophora graminea',
        type: 'fungus',
        summaryEs:
            'Enfermedad transmitida por semilla. Produce rayas largas pálidas a café, hojas rasgadas y espigas vanas o estériles en plantas afectadas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalDarkStriations,
          PlantHealthIds.signalNoClearPustules,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Las rayas siguen el sentido longitudinal de la hoja y luego el tejido se desgarra.',
      'Revisar si hay plantas achaparradas o espigas vanas.',
      'Investigar si la semilla estaba certificada o tratada, porque el patógeno es semilla-transmitido.',
      'Si varias plantas vecinas muestran el problema desde muy temprano, aumenta la sospecha.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Cuantificar el porcentaje de plantas afectadas para decidir impacto real.',
      'Documentar el lote y priorizar semilla certificada o tratamiento de semilla para el siguiente ciclo.',
      'Una vez establecida de forma sistémica, el control curativo en el ciclo suele ser limitado.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La confirmación es importante porque el manejo clave es preventivo sobre semilla y no tanto correctivo en campo.',
  ),
];
