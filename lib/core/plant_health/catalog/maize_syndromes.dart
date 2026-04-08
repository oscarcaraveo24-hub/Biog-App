import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo sanitario de maíz.
///
/// Referencias base de curaduría clínica:
/// - FAO, fall armyworm in maize.
/// - Crop Protection Network (CPN), corn disease encyclopedia.
/// - Literatura técnica regional de INIFAP / México para roya polisora y manejo.
const List<PlantHealthSyndrome> maizeSyndromes = <PlantHealthSyndrome>[
  // ── 1. Gusano cogollero ────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'maize_fall_armyworm_01',
    cropId: CropCatalog.maizeCropId,
    labelEs: 'Cogollo perforado o comido – gusano cogollero',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
    },
    organIds: <String>{PlantHealthIds.organWhorl, PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomWhorlFeeding,
    strongSignals: <String>{
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalActiveChewing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalLeafRolling,
      PlantHealthIds.signalDeadHeart,
    },
    conflictingSignals: <String>{PlantHealthIds.signalNoBiteMarks},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spodoptera_frugiperda',
        labelEs: 'Gusano cogollero',
        scientificName: 'Spodoptera frugiperda',
        type: 'insect',
        summaryEs:
            'Daño típico en cogollo con “ventanas”, perforaciones alineadas y excretas frescas dentro del verticilo. Puede destruir el meristemo en plantas jóvenes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalFrassPresent,
          PlantHealthIds.signalActiveChewing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'diatraea_spp',
        labelEs: 'Barrenador del tallo',
        scientificName: 'Diatraea spp.',
        type: 'insect',
        summaryEs:
            'Diferencial cuando predomina corazón muerto o galerías internas en tallo, con menos excretas frescas dentro del cogollo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDeadHeart},
        contradictorySignalIds: <String>{PlantHealthIds.signalFrassPresent},
      ),
    ],
    confirmationChecksEs: <String>[
      'Abrir el cogollo y confirmar excretas frescas (frass) y larva activa.',
      'Buscar daño tipo “ventana” en hojas recién desenrolladas y perforaciones alineadas.',
      'Si hay corazón muerto sin larva ni excretas frescas, subir la sospecha de barrenador.',
      'Registrar tamaño de larva: larvas pequeñas responden mejor a control oportuno.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Confirmar presencia real de larva antes de decidir control.',
      'Dirigir la revisión al cogollo; ahí se esconde la plaga y ahí debe llegar el tratamiento.',
      'Si predomina corazón muerto generalizado, la ventana de control suele ser más limitada.',
      'Usar umbrales y recomendación local para definir manejo biológico o químico.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. No sustituye muestreo formal ni identificación entomológica.',
  ),

  // ── 2. Tizones foliares y mancha gris ─────────────────────────────────────
  PlantHealthSyndrome(
    id: 'maize_foliar_blight_01',
    cropId: CropCatalog.maizeCropId,
    labelEs:
        'Manchas foliares alargadas o rectangulares – tizones / mancha gris',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalNoClearPustules,
      PlantHealthIds.signalHumidWindow,
    },
    weakSignals: <String>{PlantHealthIds.signalCoolDewyWindow},
    conflictingSignals: <String>{PlantHealthIds.signalSporesRubOff},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'exserohilum_turcicum',
        labelEs: 'Tizón norteño',
        scientificName: 'Exserohilum turcicum',
        type: 'fungus',
        summaryEs:
            'Lesiones largas, elípticas o en forma de cigarro, de color verde grisáceo a pajizo. Suelen iniciar en hojas bajas y avanzar hacia arriba.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalCoolDewyWindow},
      ),
      PlantHealthDiagnosis(
        id: 'cercospora_zeae_maydis',
        labelEs: 'Mancha gris',
        scientificName: 'Cercospora zeae-maydis',
        type: 'fungus',
        summaryEs:
            'Lesiones largas, angostas y rectangulares, claramente delimitadas por nervaduras. Con alta severidad pueden unirse y secar hojas completas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNoClearPustules,
          PlantHealthIds.signalHumidWindow,
        },
      ),
      PlantHealthDiagnosis(
        id: 'bipolaris_maydis',
        labelEs: 'Tizón sureño',
        scientificName: 'Bipolaris maydis',
        type: 'fungus',
        summaryEs:
            'Lesiones más pequeñas, bronceadas a café, generalmente más cortas que el tizón norteño. Sube en ambientes cálidos y húmedos.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
        contradictorySignalIds: <String>{PlantHealthIds.signalCoolDewyWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      'Si la lesión es larga y tipo “cigarro”, subir tizón norteño.',
      'Si la lesión es más rectangular y limitada por nervaduras, subir mancha gris.',
      'Si las lesiones son más cortas y numerosas en clima cálido-húmedo, considerar tizón sureño.',
      'Descartar roya: las lesiones de tizón no deben soltar polvo de esporas al raspar.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Evaluar si ya están afectadas las hojas cercanas a la mazorca, porque ahí pega más al rendimiento.',
      'Si el avance es rápido antes o alrededor de floración, valorar fungicida con criterio técnico.',
      'Registrar patrón de lesión para mejorar la diferenciación entre tizón norteño, sureño y mancha gris.',
      'Documentar híbrido, fecha de siembra y presión de humedad para decisiones futuras.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La diferenciación exacta entre patógenos mejora con apoyo de laboratorio.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── 3. Royas del maíz ──────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'maize_rust_complex_01',
    cropId: CropCatalog.maizeCropId,
    labelEs: 'Pústulas anaranjadas en hoja – royas del maíz',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
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
        id: 'puccinia_sorghi',
        labelEs: 'Roya común',
        scientificName: 'Puccinia sorghi',
        type: 'fungus',
        summaryEs:
            'Pústulas ladrillo-anaranjadas, ovaladas o alargadas, presentes en ambas caras de la hoja. Se favorece más con temperaturas moderadas y rocío.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalCoolDewyWindow},
      ),
      PlantHealthDiagnosis(
        id: 'puccinia_polysora',
        labelEs: 'Roya sureña / polisora',
        scientificName: 'Puccinia polysora',
        type: 'fungus',
        summaryEs:
            'Pústulas más pequeñas, redondeadas, muy numerosas y concentradas principalmente en el haz. Puede ser más agresiva en ambientes cálido-húmedos.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar que las pústulas sí sueltan polvo naranja al raspar.',
      'Si predominan en ambas caras y son más alargadas, subir roya común.',
      'Si son más pequeñas, densas y sobre todo en el haz, subir roya sureña / polisora.',
      'Si el punto negro no se desprende al raspar, considerar mancha de asfalto en lugar de roya.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Evaluar severidad en hojas superiores y cercanas a la mazorca.',
      'En roya sureña, la revisión debe ser más rápida porque puede escalar fuerte en clima cálido-húmedo.',
      'Documentar fecha de siembra e híbrido, porque siembras tardías o materiales susceptibles suelen sufrir más.',
      'Si el lote está en ventana crítica y la presión sube, valorar fungicida con soporte técnico.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La diferenciación entre roya común y polisora mejora con observación detallada del tamaño, forma y distribución de pústulas.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── 4. Mancha de asfalto ───────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'maize_tar_spot_01',
    cropId: CropCatalog.maizeCropId,
    labelEs: 'Puntos negros elevados que no se desprenden – mancha de asfalto',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomRaisedBlackSpots,
    strongSignals: <String>{PlantHealthIds.signalCannotScrapeOff},
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
    },
    conflictingSignals: <String>{PlantHealthIds.signalSporesRubOff},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'phyllachora_maydis',
        labelEs: 'Mancha de asfalto',
        scientificName: 'Phyllachora maydis',
        type: 'fungus',
        summaryEs:
            'Puntos negros elevados, firmes y brillantes, dispersos en la hoja. No son polvo ni pústulas y no se desprenden al raspar.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalCannotScrapeOff},
        contradictorySignalIds: <String>{PlantHealthIds.signalSporesRubOff},
      ),
    ],
    confirmationChecksEs: <String>[
      'Intentar raspar el punto negro: si no se desprende, sube mucho la sospecha.',
      'Confirmar que el punto es elevado y no una mancha plana o polvo superficial.',
      'No confundir con roya: la roya rompe epidermis y sí libera esporas.',
      'Si el lote tuvo humedad y rocíos prolongados, la probabilidad aumenta.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Cuantificar severidad en tercio medio y superior del dosel.',
      'Si la presión sube en fases reproductivas, valorar respuesta rápida con criterio técnico.',
      'Registrar híbrido y antecedente del lote para decisiones futuras de manejo y rotación.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La confirmación formal puede requerir apoyo fitopatológico.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── 5. Pudriciones de mazorca ──────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'maize_ear_rot_01',
    cropId: CropCatalog.maizeCropId,
    labelEs: 'Pudrición o moho en mazorca',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    },
    organIds: <String>{PlantHealthIds.organEar, PlantHealthIds.organGrain},
    primarySymptomId: PlantHealthIds.symptomEarRot,
    strongSignals: <String>{PlantHealthIds.signalMoldOnEar},
    weakSignals: <String>{
      PlantHealthIds.signalSilkDamage,
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'fusarium_verticillioides',
        labelEs: 'Fusariosis de mazorca',
        scientificName: 'Fusarium verticillioides',
        type: 'fungus',
        summaryEs:
            'Moho blanco a rosado o púrpura, a menudo en granos dispersos o asociados a daño de insecto. Riesgo importante de fumonisinas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMoldOnEar,
          PlantHealthIds.signalSilkDamage,
          PlantHealthIds.signalFrassPresent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'aspergillus_flavus',
        labelEs: 'Pudrición por Aspergillus',
        scientificName: 'Aspergillus flavus',
        type: 'fungus',
        summaryEs:
            'Polvo o moho verde-olivo a verde amarillento, frecuente hacia la punta de la mazorca. Se asocia a calor y estrés hídrico; riesgo de aflatoxinas.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalMoldOnEar},
        contradictorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'stenocarpella_maydis',
        labelEs: 'Pudrición por Diplodia',
        scientificName: 'Stenocarpella maydis',
        type: 'fungus',
        summaryEs:
            'Moho blanco denso que suele iniciar en la base de la mazorca y avanzar hacia arriba; la bráctea puede verse blanqueada.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalMoldOnEar},
        contradictorySignalIds: <String>{PlantHealthIds.signalSilkDamage},
      ),
    ],
    confirmationChecksEs: <String>[
      'Abrir la mazorca y observar el color y textura del moho: blanco-rosado, verde-olivo o blanco denso.',
      'Si el daño aparece en granos dispersos o cerca de heridas de insecto, subir Fusarium.',
      'Si predomina moho verde polvoso, sobre todo con calor/sequía, subir Aspergillus.',
      'Si el moho blanco inicia desde la base de la mazorca, subir Diplodia.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Muestrear mazorcas y separar claramente material sano del sospechoso.',
      'Si hay sospecha de aflatoxinas o fumonisinas, no mezclar grano afectado con grano sano.',
      'Revisar daño de insecto, cobertura de mazorca y humedad al final del ciclo.',
      'Si la madurez ya lo permite, valorar cosecha oportuna para reducir deterioro adicional.',
    ],
    disclaimerEs:
        'Diagnóstico sugerido. La confirmación del agente y el análisis de micotoxinas requiere laboratorio.',
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
];
