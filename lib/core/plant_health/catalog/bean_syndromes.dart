import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo sanitario de frijol.
///
/// Fuentes guía para esta versión:
/// - UC IPM / Dry beans: bean anthracnose, bean common mosaic.
/// - Plantwise / CABI: bean rust, angular leaf spot, bean golden mosaic.
/// - CIAT / literatura técnica de frijol tropical.
///
/// Nota de modelado BIO-G:
/// - Se priorizaron síndromes clínicos que sí caben en la taxonomía actual
///   de órganos / síntomas / señales.
/// - En esta pasada se retiraron modificadores varietales demasiado finos
///   cuando el catálogo actual de frijol está agrupado por tipos amplios
///   (negro / pinto / flor de mayo-junio), para evitar sesgos falsos.
const List<PlantHealthSyndrome> beanSyndromes = <PlantHealthSyndrome>[
  // ── 1. Antracnosis del frijol ──────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'bean_anthracnose_01',
    cropId: CropCatalog.beanCropId,
    labelEs:
        'Lesiones oscuras hundidas en vaina, tallo o nervaduras – antracnosis',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{
      PlantHealthIds.organPod,
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
    },
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalPodCanker,
      PlantHealthIds.signalPinkSporeMass,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalSeedStaining,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'colletotrichum_lindemuthianum',
        labelEs: 'Antracnosis',
        scientificName: 'Colletotrichum lindemuthianum',
        type: 'fungus',
        summaryEs:
            'Produce lesiones hundidas negro-rojas en vainas, tallos y nervaduras; en humedad puede verse masa rosada de esporas. También puede venir en semilla.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalPodCanker,
          PlantHealthIds.signalPinkSporeMass,
          PlantHealthIds.signalSeedStaining,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'En vaina, confirmar lesión hundida con borde oscuro bien definido.',
      'En humedad, buscar masa de esporas salmón o rosada en el centro.',
      'En hojas, revisar el envés: las nervaduras pueden verse rojo-ladrillo a púrpura y luego oscurecerse.',
      'Si el problema apareció desde plántula y hubo semilla no certificada, la sospecha sube.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Si el brote es temprano y el ambiente sigue húmedo, evaluar manejo fungicida con apoyo técnico.',
      'No guardar semilla de plantas o vainas afectadas.',
      'En el siguiente ciclo, priorizar semilla sana/certificada, rotación y menor salpique de agua.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La antracnosis se confirma mejor cuando la lesión hundida y la esporulación rosada son claras.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── 2. Roya del frijol ─────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'bean_rust_01',
    cropId: CropCatalog.beanCropId,
    labelEs: 'Pústulas anaranjadas o café-rojizas en hoja – roya del frijol',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomOrangePustules,
    strongSignals: <String>{PlantHealthIds.signalSporesRubOff},
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
    },
    conflictingSignals: <String>{PlantHealthIds.signalCannotScrapeOff},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'uromyces_appendiculatus',
        labelEs: 'Roya del frijol',
        scientificName: 'Uromyces appendiculatus',
        type: 'fungus',
        summaryEs:
            'Forma pústulas pequeñas anaranjadas a café-canela que liberan polvo de esporas; puede avanzar a defoliación y dañar hojas y vainas.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSporesRubOff},
        contradictorySignalIds: <String>{PlantHealthIds.signalCannotScrapeOff},
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar pústulas que sí liberan polvo canela al frotar.',
      'Buscar más lesiones en envés, aunque pueden verse en ambas caras de la hoja.',
      'Las pústulas viejas se oscurecen; si no se desprenden al raspar, pensar en otro problema.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Monitorear rápido si ya entró a floración o llenado, porque la defoliación impacta rendimiento.',
      'Si la presión sube y el ambiente sigue favorable, evaluar fungicida con criterio técnico.',
      'Registrar la reacción varietal observada para elegir mejor material en el siguiente ciclo.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La roya del frijol tiene muchas razas; el comportamiento varietal puede cambiar por región.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── 3. Mancha angular ──────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'bean_angular_leaf_spot_01',
    cropId: CropCatalog.beanCropId,
    labelEs: 'Manchas angulares en hojas o vainas – mancha angular',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organPod,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomAngularSpots,
    strongSignals: <String>{
      PlantHealthIds.signalAngularLesionPattern,
      PlantHealthIds.signalNoClearPustules,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalWaterSoakedMargin,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pseudocercospora_griseola',
        labelEs: 'Mancha angular',
        scientificName: 'Pseudocercospora griseola',
        type: 'fungus',
        summaryEs:
            'Las lesiones quedan limitadas por las nervaduras, por eso toman forma angular. En humedad puede haber esporulación gris oscura en el envés.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAngularLesionPattern,
          PlantHealthIds.signalWaterSoakedMargin,
          PlantHealthIds.signalNoClearPustules,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'La lesión debe verse “encerrada” entre nervaduras, no redonda y libre.',
      'En hojas húmedas, revisar envés para detectar esporulación gris oscura.',
      'También puede aparecer en pecíolos, tallos y vainas; si hay vainas manchadas, la sospecha sube.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Evaluar si ya está subiendo a hojas medias y superiores o si ya tocó vainas.',
      'Si entra temprano y el ambiente sigue húmedo, puede justificar manejo oportuno.',
      'Rotación, rastrojo y semilla sana ayudan a bajar inóculo del siguiente ciclo.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La mancha angular puede confundirse con bacteriosis; el patrón angular real es la clave.',
    favorsHighHumidity: true,
  ),

  // ── 4. Mosca blanca + mosaico dorado / amarillamiento ─────────────────────
  PlantHealthSyndrome(
    id: 'bean_whitefly_virus_01',
    cropId: CropCatalog.beanCropId,
    labelEs: 'Mosaico dorado o amarillamiento con mosca blanca',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalWhiteflyCloud,
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalLeafRolling,
    },
    weakSignals: <String>{
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'bgymv',
        labelEs: 'Virus del mosaico dorado amarillo',
        scientificName: 'Bean golden yellow mosaic virus (BGYMV)',
        type: 'virus',
        summaryEs:
            'Provoca mosaico amarillo brillante o dorado, deformación y reducción fuerte del crecimiento; el daño es mayor cuando infecta temprano.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalVectorPresent,
          PlantHealthIds.signalLeafRolling,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalSootyMold,
        },
      ),
      PlantHealthDiagnosis(
        id: 'bemisia_tabaci',
        labelEs: 'Mosca blanca',
        scientificName: 'Bemisia tabaci',
        type: 'insect',
        summaryEs:
            'Es el vector clave del mosaico dorado y además causa daño directo por succión, mielecilla y fumagina cuando la población sube.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWhiteflyCloud,
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalSootyMold,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Al mover el follaje, confirmar si sale nube de mosca blanca.',
      'Revisar hojas jóvenes: el virus suele expresarse como mosaico amarillo brillante con enrollamiento o deformación.',
      'Si predominan mielecilla y fumagina sin mosaico claro, puede pesar más el daño directo del insecto que el viral.',
      'Si la infección apareció muy temprano y la planta quedó chica o deformada, la sospecha de virus sube mucho.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'El componente viral no se corrige una vez instalado; el valor está en cortar presión temprana del vector y reducir fuentes de inóculo.',
      'Monitorear agresivamente bordes, malezas hospederas y focos tempranos.',
      'No confiar solo en ver miel o fumagina: confirmar también mosaico y deformación para estimar cuánto pesa el virus.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La confirmación específica del virus requiere prueba de laboratorio; visualmente se orienta por mosaico dorado + presencia de mosca blanca.',
    favorsVectorPressure: true,
  ),
];
