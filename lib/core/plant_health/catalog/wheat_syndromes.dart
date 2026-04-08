import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo sanitario de trigo.
///
/// Base técnica usada para esta versión:
/// - CIMMYT / guías de identificación de enfermedades de trigo.
/// - Crop Protection Network (royas, tan spot, Fusarium head blight).
/// - AHDB (yellow rust, Septoria tritici blotch).
/// - trabajos de México/El Bajío (Scielo) para priorización regional.
const List<PlantHealthSyndrome> wheatSyndromes = <PlantHealthSyndrome>[
  // ── 1. Roya de la hoja (roya parda) ────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'wheat_leaf_rust_01',
    cropId: CropCatalog.wheatCropId,
    labelEs: 'Pústulas anaranjadas dispersas en hoja – roya de la hoja',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomOrangePustules,
    strongSignals: <String>{PlantHealthIds.signalSporesRubOff},
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalPustulesOnStem,
      PlantHealthIds.signalCannotScrapeOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'puccinia_triticina',
        labelEs: 'Roya de la hoja',
        scientificName: 'Puccinia triticina',
        type: 'fungus',
        summaryEs:
            'Pústulas naranja-café, generalmente redondas u ovaladas y dispersas en la hoja. La roya más común en trigo de muchas regiones productoras.',
        contradictorySignalIds: <String>{PlantHealthIds.signalCoolDewyWindow},
      ),
      PlantHealthDiagnosis(
        id: 'puccinia_striiformis',
        labelEs: 'Roya amarilla / lineal',
        scientificName: 'Puccinia striiformis f. sp. tritici',
        type: 'fungus',
        summaryEs:
            'Debe mantenerse como diferencial si el observador describe pústulas en bandas o líneas entre nervaduras.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalCoolDewyWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar que las pústulas sí sueltan polvo naranja al tocarlas o rasparlas.',
      'Si las pústulas están dispersas y no forman líneas claras, sube roya de la hoja.',
      'Si las pústulas se alinean entre nervaduras, mover el diferencial hacia roya amarilla.',
      'Si también hay pústulas en tallo o pedúnculo, subir roya del tallo.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Dar prioridad a la hoja bandera y a la hoja inmediatamente inferior.',
      'Si el cuadro sube antes de espigamiento o floración, considerar revisión técnica para decisión fungicida.',
      'Monitorear evolución cada 48 horas si persiste humedad o rocío.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La diferenciación fina entre royas mejora con observación detallada del patrón de pústulas.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── 2. Roya amarilla / lineal ─────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'wheat_stripe_rust_01',
    cropId: CropCatalog.wheatCropId,
    labelEs: 'Pústulas amarillas alineadas en hoja – roya amarilla / lineal',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomOrangePustules,
    strongSignals: <String>{
      PlantHealthIds.signalSporesRubOff,
      PlantHealthIds.signalCoolDewyWindow,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    conflictingSignals: <String>{
      PlantHealthIds.signalPustulesOnStem,
      PlantHealthIds.signalCannotScrapeOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'puccinia_striiformis',
        labelEs: 'Roya amarilla / lineal',
        scientificName: 'Puccinia striiformis f. sp. tritici',
        type: 'fungus',
        summaryEs:
            'Pústulas amarillas a amarillo-naranja, agrupadas en líneas o franjas a lo largo de la hoja. Favorecida por clima fresco y húmedo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalCoolDewyWindow},
      ),
      PlantHealthDiagnosis(
        id: 'puccinia_triticina',
        labelEs: 'Roya de la hoja',
        scientificName: 'Puccinia triticina',
        type: 'fungus',
        summaryEs:
            'Debe permanecer como diferencial cuando el observador solo reporta pústulas naranjas sin describir claramente las líneas.',
        contradictorySignalIds: <String>{PlantHealthIds.signalCoolDewyWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar si las pústulas forman franjas o bandas entre nervaduras.',
      'Revisar si hubo clima fresco con rocío prolongado recientemente.',
      'En hojas jóvenes puede iniciar menos ordenada; en hojas maduras suele verse más lineal.',
      'Si el patrón es disperso en vez de lineal, bajar roya amarilla y subir roya de la hoja.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Revisar rápido si ya alcanzó hojas superiores o la hoja bandera.',
      'No esperar demasiado cuando el ambiente sigue fresco y húmedo: esta roya puede escalar con rapidez.',
      'Documentar presión para decisiones varietales futuras.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La roya amarilla puede confundirse al inicio con roya de la hoja si el patrón aún no está bien definido.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── 3. Roya del tallo ──────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'wheat_stem_rust_01',
    cropId: CropCatalog.wheatCropId,
    labelEs: 'Pústulas grandes en tallo o pedúnculo – roya del tallo',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    },
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organSpike,
    },
    primarySymptomId: PlantHealthIds.symptomOrangeReddishPustules,
    strongSignals: <String>{
      PlantHealthIds.signalPustulesOnStem,
      PlantHealthIds.signalSporesRubOff,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'puccinia_graminis_tritici',
        labelEs: 'Roya del tallo',
        scientificName: 'Puccinia graminis f. sp. tritici',
        type: 'fungus',
        summaryEs:
            'Pústulas más grandes, rojizas a oscuras, en tallo, vaina y a veces espiga; rompen la epidermis y pueden debilitar la planta.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalPustulesOnStem},
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar pústulas visibles en tallo, vaina o pedúnculo, no solo en hoja.',
      'Revisar si la epidermis se ve rasgada alrededor de la pústula.',
      'Si ya alcanzó pedúnculo o espiga, tratarlo como cuadro de alta urgencia.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Escalar revisión técnica el mismo día si se confirma presencia en tallo o pedúnculo.',
      'Revisar varios puntos del lote para estimar distribución real.',
      'Documentar inmediatamente por su importancia fitosanitaria y por el riesgo de pérdidas severas.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La roya del tallo es un cuadro de alta prioridad y merece validación técnica urgente.',
    favorsHighHumidity: true,
  ),

  // ── 4. Complejo de manchas y tizones foliares ──────────────────────────────
  PlantHealthSyndrome(
    id: 'wheat_foliar_blight_01',
    cropId: CropCatalog.wheatCropId,
    labelEs:
        'Manchas foliares necróticas sin pústulas – septoriosis / mancha bronceada',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalNoClearPustules,
      PlantHealthIds.signalHumidWindow,
    },
    weakSignals: <String>{PlantHealthIds.signalRapidFoliarCollapse},
    conflictingSignals: <String>{PlantHealthIds.signalSporesRubOff},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'zymoseptoria_tritici',
        labelEs: 'Septoriosis de la hoja',
        scientificName: 'Zymoseptoria tritici',
        type: 'fungus',
        summaryEs:
            'Lesiones alargadas o rectangulares restringidas por nervaduras, con pequeños puntos negros (picnidios) en tejido maduro.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNoClearPustules,
          PlantHealthIds.signalHumidWindow,
        },
      ),
      PlantHealthDiagnosis(
        id: 'pyrenophora_tritici_repentis',
        labelEs: 'Mancha bronceada / tan spot',
        scientificName: 'Pyrenophora tritici-repentis',
        type: 'fungus',
        summaryEs:
            'Lesiones café a pajizas con halo amarillo bien definido; suele iniciar desde hojas inferiores y asociarse a rastrojo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalNoClearPustules},
        contradictorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'stagonospora_nodorum',
        labelEs: 'Mancha nodorum / glume blotch',
        scientificName: 'Parastagonospora nodorum',
        type: 'fungus',
        summaryEs:
            'Diferencial cuando las lesiones son más irregulares, con borde amarillento difuso y posibilidad de avance hacia glumas.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
        contradictorySignalIds: <String>{PlantHealthIds.signalNoClearPustules},
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar puntitos negros dentro de la lesión: eso acerca septoriosis.',
      'Si la lesión tiene halo amarillo bien marcado, subir mancha bronceada.',
      'Si las manchas avanzan a glumas o el borde amarillo es más difuso, dejar abierto nodorum.',
      'Confirmar que no hay pústulas que suelten esporas; si las hay, mover el cuadro hacia roya.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Evaluar de inmediato si la hoja bandera ya está afectada.',
      'Si el cuadro avanza antes o durante antesis/llenado, puede justificar revisión técnica para decisión fungicida.',
      'Considerar rastrojo y rotación como parte del análisis del siguiente ciclo.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. El complejo foliar necrosante del trigo puede requerir lupa o laboratorio para una diferenciación fina.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    favorsRecentStress: true,
  ),

  // ── 5. Pulgones del trigo ──────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'wheat_aphid_01',
    cropId: CropCatalog.wheatCropId,
    labelEs: 'Colonias de pulgón en hoja o espiga',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organSpike,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAphidColonies,
    strongSignals: <String>{
      PlantHealthIds.signalSpikeFeeding,
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalAphidEarlyToxicity,
    },
    weakSignals: <String>{
      PlantHealthIds.signalLeafRolling,
      PlantHealthIds.signalSootyMold,
      PlantHealthIds.signalVectorPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'schizaphis_graminum_wheat',
        labelEs: 'Pulgón verde del cereal',
        scientificName: 'Schizaphis graminum',
        type: 'insect',
        summaryEs:
            'Sube cuando hay clorosis fuerte, daño tóxico y debilitamiento temprano del cultivo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAphidEarlyToxicity,
          PlantHealthIds.signalLeafRolling,
        },
        contradictorySignalIds: <String>{PlantHealthIds.signalSpikeFeeding},
      ),
      PlantHealthDiagnosis(
        id: 'sitobion_avenae',
        labelEs: 'Pulgón de la espiga',
        scientificName: 'Sitobion avenae',
        type: 'insect',
        summaryEs:
            'Gana peso cuando la colonia se concentra en espiga o hojas superiores durante llenado.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSpikeFeeding},
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAphidEarlyToxicity,
        },
      ),
      PlantHealthDiagnosis(
        id: 'rhopalosiphum_padi',
        labelEs: 'Pulgón del cerezo / bird-cherry oat aphid',
        scientificName: 'Rhopalosiphum padi',
        type: 'insect',
        summaryEs:
            'Debe quedar abierto como diferencial importante y como vector relevante de BYDV.',
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAphidEarlyToxicity,
          PlantHealthIds.signalSpikeFeeding,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Definir si el pulgón está principalmente en hoja o ya en espiga.',
      'Si hay clorosis intensa o pérdida de vigor temprana, subir pulgón verde del cereal.',
      'Si la colonia está sobre espiga, subir Sitobion avenae.',
      'Si el cuadro parece más de vector/virus que de daño directo, abrir también BYDV.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Muestrear varios puntos antes de decidir control amplio.',
      'Separar daño directo por succión de riesgo de virus transmitido por pulgones.',
      'Si hay enemigos naturales abundantes, considerar su aporte antes de intervenir.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. No sustituye muestreo formal ni identificación entomológica de especie.',
    favorsVectorPressure: true,
  ),

  // ── 6. Enanismo amarillo de la cebada (BYDV) en trigo ─────────────────────
  PlantHealthSyndrome(
    id: 'wheat_bydv_01',
    cropId: CropCatalog.wheatCropId,
    labelEs: 'Amarillamiento o enanismo con presencia de pulgones – BYDV',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomStuntingReddening,
    strongSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalLeafRolling,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAphidEarlyToxicity,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'bydv_wheat',
        labelEs: 'Enanismo amarillo (BYDV)',
        scientificName: 'Barley yellow dwarf virus',
        type: 'virus',
        summaryEs:
            'Amarillamiento desde punta y márgenes, reducción de macollos y enanismo, sobre todo si la infección ocurrió temprano.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalVectorPresent},
      ),
      PlantHealthDiagnosis(
        id: 'rhopalosiphum_padi',
        labelEs: 'Pulgón vector asociado',
        scientificName: 'Rhopalosiphum padi',
        type: 'insect',
        summaryEs:
            'Vector importante cuando hubo pulgones presentes antes de aparecer el amarillamiento.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalVectorPresent},
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAphidEarlyToxicity,
        },
      ),
      PlantHealthDiagnosis(
        id: 'schizaphis_graminum_wheat',
        labelEs: 'Daño tóxico por pulgón verde',
        scientificName: 'Schizaphis graminum',
        type: 'insect',
        summaryEs:
            'Mantenerlo como diferencial si domina la clorosis por alimentación y no tanto el patrón viral del lote.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAphidEarlyToxicity,
          PlantHealthIds.signalLeafRolling,
        },
        contradictorySignalIds: <String>{PlantHealthIds.signalVectorPresent},
      ),
    ],
    confirmationChecksEs: <String>[
      'Observar si el amarillamiento empieza desde la punta o márgenes de hojas viejas y progresa hacia la base.',
      'Revisar si el lote perdió vigor o macollos y si hubo pulgones antes del síntoma.',
      'Si el daño es muy localizado a colonias activas, pensar más en pulgón directo; si el patrón ya quedó en la planta, subir BYDV.',
      'Recordar que el virus no se cura una vez instalado.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Separar plantas con virus instalado de plantas con solo colonias actuales de pulgón.',
      'Documentar fecha de siembra, presión de pulgón y distribución del daño en el lote.',
      'Priorizar prevención y manejo de vectores en cuadros tempranos o lotes vecinos.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La confirmación viral requiere prueba especializada; una vez presente, el virus no tiene cura en campo.',
    favorsVectorPressure: true,
    favorsCoolDewyWindow: true,
  ),
];
