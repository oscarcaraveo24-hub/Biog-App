import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo de riesgos / sanidad vegetal del Manzano (`crop_apple_tree`).
///
/// Alimentado por el documento oficial
/// `04_Riesgos_Cultivo_Sanidad_Estres_Memoria_BioG_Manzano_v1`.
///
/// Reglas no negociables:
/// - BIO-G ORIENTA, no diagnostica de forma absoluta: "condición favorable a…",
///   "revisa…", "síntomas compatibles con…", "confirma si avanza…".
/// - NO receta plaguicidas ni ingredientes activos.
/// - El perfil AP solo modifica sensibilidad/mensajes (varietyModifiers); el
///   catálogo base es el mismo para todas las variedades.
/// - Es un árbol perenne con MEMORIA multianual: helada, granizo, estrés en
///   floración/cuajado/llenado y mala postcosecha pesan en el ciclo siguiente.
///
/// Cobertura v1: las familias de mayor prioridad de cada grupo del documento.
/// El catálogo está diseñado como plantilla extensible para los siguientes
/// frutales; los riesgos regionales/secundarios del doc 04 quedan documentados
/// como pendientes y se agregan con el mismo molde sin romper el build.

// Mapas de etapas (buckets perennes → buckets genéricos del motor).
const Set<PlantHealthStageBucket> _establishmentStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
    };

const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _bloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _fruitStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _woodStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _allTreeStages = <PlantHealthStageBucket>{
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
    'Orientación de riesgo, no diagnóstico definitivo. BIO-G sugiere revisar, '
    'comparar y confirmar en campo o con asesoría técnica local si el daño '
    'avanza. No prescribe plaguicidas ni ingredientes activos.';

const List<String> _baseActions = <String>[
  'Marca el foco (por árbol, línea o borde) y revisa el avance en 24-72 horas.',
  'Cruza el síntoma con etapa, clima reciente (lluvia, helada, granizo, calor) '
      'y manejo antes de asumir una sola causa.',
  'Registra fotos, etapa visible y condiciones: en árbol la memoria del ciclo '
      'importa para el siguiente.',
];

const List<String> _rootActions = <String>[
  'Revisa cuello, raíces y drenaje antes de regar más.',
  'Separa pudrición de raíz de anoxia, salinidad o compactación.',
  'Si el árbol decae con suelo húmedo, no es falta de agua.',
];

const List<String> _bloomActions = <String>[
  'Revisa racimos florales, brotes tiernos y posible exudado.',
  'No empujes nitrógeno ni vigor durante floración.',
  'Cruza con helada, lluvia, humedad y actividad de polinizadores.',
];

const List<String> _fruitActions = <String>[
  'Revisa perforaciones, manchas o pudriciones en fruto y compáralas con sol, '
      'granizo, chinches o balance de calcio.',
  'Protege fruta expuesta y evita heridas que abren puerta a pudriciones.',
  'Guarda el evento para ajustar manejo y cosecha del siguiente ciclo.',
];

const List<String> _woodActions = <String>[
  'Revisa madera, heridas de poda, granizo y base del tronco.',
  'No trates una muerte regresiva de rama como simple problema de hoja.',
  'Evita poda en húmedo y desinfecta herramienta entre árboles.',
];

/// Modificador de sensibilidad por perfil AP (doc 04 §6).
VarietyModifier _apModifier({
  required Set<String> profiles,
  required String diagnosisId,
  required int delta,
  required String rationale,
}) => VarietyModifier(
  cropId: CropCatalog.appleTreeCropId,
  varietyIds: profiles,
  diagnosisIds: <String>{diagnosisId},
  scoreDelta: delta,
  rationaleEs: rationale,
  isProxy: true,
);

/// Catálogo de síndromes del manzano.
///
/// Es `final` (no `const`) porque los modificadores por perfil AP se construyen
/// con el helper [_apModifier]; el resto de los datos siguen siendo constantes.
final List<PlantHealthSyndrome> appleTreeSyndromes = <PlantHealthSyndrome>[
  // ── Familia 1: Raíz, cuello, suelo y madera ──────────────────────────────
  PlantHealthSyndrome(
    id: 'apple_root_crown_rot_01',
    cropId: CropCatalog.appleTreeCropId,
    labelEs: 'Decaimiento con suelo húmedo o raíz/cuello oscuros',
    stages: _establishmentStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
    },
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'phytophthora_root_crown_rot',
        labelEs: 'Pudrición de raíz/corona por exceso de humedad',
        scientificName: 'Phytophthora spp.',
        type: 'oomycete',
        summaryEs:
            'Favorecida por suelo saturado, drenaje pobre, riego excesivo y '
            'compactación, sobre todo en árbol joven. Corona café-rojiza y '
            'raíces finas muertas. No recomendar más riego.',
      ),
      PlantHealthDiagnosis(
        id: 'root_crown_rot_complex',
        labelEs: 'Complejo de raíz y cuello',
        type: 'root_disease_complex',
        summaryEs:
            'Decaimiento irregular con raíces café/negras cuando hay marchitez '
            'o bajo vigor sin causa foliar evidente.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirma si la marchitez ocurre con suelo húmedo (no seco).',
      'Revisa drenaje, compactación y zonas bajas del huerto.',
      'Revisa corteza interna del cuello: café-rojiza es señal de alerta.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'apple_canker_wood_decline_01',
    cropId: CropCatalog.appleTreeCropId,
    labelEs: 'Muerte regresiva de rama o cancro en madera',
    stages: _woodStages,
    organIds: <String>{PlantHealthIds.organStem},
    primarySymptomId: PlantHealthIds.symptomShootDecayCanker,
    strongSignals: <String>{
      PlantHealthIds.signalStemCanker,
      PlantHealthIds.signalHailEvent,
    },
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'canker_wood_decline_complex',
        labelEs: 'Cancros y decaimiento de madera',
        type: 'fungal_wood_complex',
        summaryEs:
            'Zonas hundidas en corteza, exudado y muerte regresiva tras '
            'heridas de poda, granizo o helada. Alta memoria: puede ser puerta '
            'a problemas estructurales.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa heridas de poda, granizo o helada recientes.',
      'Busca corteza agrietada, hundida o con goma/exudado.',
      'Confirma si la rama muere de la punta hacia adentro.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _woodActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),

  // ── Familia 2: Flor, brote y bacterias ───────────────────────────────────
  PlantHealthSyndrome(
    id: 'apple_fire_blight_01',
    cropId: CropCatalog.appleTreeCropId,
    labelEs: 'Racimos florales o brotes quemados con exudado',
    stages: _bloomStages,
    organIds: <String>{PlantHealthIds.organFlower, PlantHealthIds.organStem},
    primarySymptomId: PlantHealthIds.symptomBlightedBlossomsShoots,
    strongSignals: <String>{
      PlantHealthIds.signalAmberBacterialOoze,
      PlantHealthIds.signalShepherdsCrookShoot,
      PlantHealthIds.signalSpringWetFoliage,
    },
    weakSignals: <String>{PlantHealthIds.signalHailEvent},
    conflictingSignals: <String>{PlantHealthIds.signalFrostEvent},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'fire_blight',
        labelEs: 'Tizón de fuego / fuego bacteriano',
        scientificName: 'Erwinia amylovora',
        type: 'bacteria',
        summaryEs:
            'Favorecido por clima cálido-húmedo en floración, lluvia, granizo, '
            'heridas y exceso de vigor/N. Brotes en "cayado de pastor" y '
            'exudado ámbar. Muy alta memoria: puede matar ramas y árboles '
            'jóvenes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAmberBacterialOoze,
          PlantHealthIds.signalShepherdsCrookShoot,
        },
      ),
      PlantHealthDiagnosis(
        id: 'bacterial_blossom_blast',
        labelEs: 'Bacteriosis de flor / blast bacteriano',
        type: 'bacteria',
        summaryEs:
            'Flores quemadas tras frío-lluvia. Puede confundirse con helada o '
            'tizón de fuego; revisa exudado y patrón antes de concluir.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrostEvent},
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca exudado ámbar/pegajoso en brotes o racimos.',
      '¿El brote se dobla en gancho (cayado de pastor)?',
      'Confirma si hubo clima cálido-húmedo o granizo en floración.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _bloomActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _apModifier(
        profiles: <String>{kAp04Gala},
        diagnosisId: 'fire_blight',
        delta: 12,
        rationale:
            'Gala es de las más susceptibles a tizón de fuego: floración y '
            'brote tierno pesan más.',
      ),
      _apModifier(
        profiles: <String>{kAp05LowChill},
        diagnosisId: 'fire_blight',
        delta: 6,
        rationale:
            'Bajo frío con floración temprana y clima inestable sube el riesgo.',
      ),
    ],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'apple_frost_bloom_damage_01',
    cropId: CropCatalog.appleTreeCropId,
    labelEs: 'Flores cafés/negras tras helada',
    stages: _bloomStages,
    organIds: <String>{PlantHealthIds.organFlower},
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{PlantHealthIds.signalFrostEvent},
    weakSignals: <String>{PlantHealthIds.signalColdExposure},
    conflictingSignals: <String>{PlantHealthIds.signalAmberBacterialOoze},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'frost_bloom_damage',
        labelEs: 'Daño por helada en floración',
        type: 'abiotic_cold',
        summaryEs:
            'Temperaturas bajo cero en botón rosa, flor o cuajado reciente '
            'dañan pistilos y bajan cuajado. Memoria alta: afecta rendimiento '
            'anual, alternancia y reservas.',
      ),
      PlantHealthDiagnosis(
        id: 'poor_pollination_low_fruit_set',
        labelEs: 'Mala polinización / bajo cuajado',
        type: 'abiotic_physiological',
        summaryEs:
            'Frío, lluvia, viento o pocas abejas bajan el cuajado aunque el NPK '
            'se vea correcto. Revisa polinizadores y clima de floración.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa el centro/pistilo de la flor: oscuro indica daño de helada.',
      '¿Hubo temperatura bajo cero o helada reportada?',
      'Revisa frutos recién cuajados por anillos de helada.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _bloomActions,
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 3: Enfermedades de hoja y fruto ──────────────────────────────
  PlantHealthSyndrome(
    id: 'apple_scab_01',
    cropId: CropCatalog.appleTreeCropId,
    labelEs: 'Manchas oliva-negras aterciopeladas en hoja/fruto',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomVelvetyOliveSpots,
    strongSignals: <String>{
      PlantHealthIds.signalSpringWetFoliage,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'apple_scab',
        labelEs: 'Sarna / moteado del manzano',
        scientificName: 'Venturia inaequalis',
        type: 'fungus',
        summaryEs:
            'Manchas oliva a negras aterciopeladas en hoja y fruta joven, con '
            'costras y deformación. Favorecida por primavera húmeda y mojado '
            'foliar prolongado. Inóculo en hojas caídas.',
      ),
      PlantHealthDiagnosis(
        id: 'powdery_mildew',
        labelEs: 'Cenicilla / oídio',
        scientificName: 'Podosphaera leucotricha',
        type: 'fungus',
        summaryEs:
            'Polvo blanco/gris en brotes y hojas nuevas con días cálidos y '
            'noches húmedas; puede causar russeting en fruto.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWhitePowderGrowth},
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa hojas jóvenes y fruta pequeña tras lluvia o mojado foliar.',
      'Diferencia manchas aterciopeladas (sarna) de polvo blanco (cenicilla).',
      'Confirma si la primavera fue húmeda o el dosel quedó cerrado.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'apple_fruit_rot_complex_01',
    cropId: CropCatalog.appleTreeCropId,
    labelEs: 'Pudrición de fruto o fruto momificado',
    stages: _fruitStages,
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomMummifiedFruitRot,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalHailEvent,
    },
    weakSignals: <String>{PlantHealthIds.signalDenseWetCanopy},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'bitter_rot',
        labelEs: 'Pudrición amarga / bitter rot',
        scientificName: 'Colletotrichum spp.',
        type: 'fungus',
        summaryEs:
            'Lesiones circulares hundidas con anillos concéntricos en fruta '
            'madura, favorecida por clima cálido-húmedo y heridas.',
      ),
      PlantHealthDiagnosis(
        id: 'black_rot_frogeye',
        labelEs: 'Pudrición negra / black rot',
        scientificName: 'Diplodia seriata',
        type: 'fungus',
        summaryEs:
            'Pudrición firme oscura cerca del cáliz, ligada a madera muerta y '
            'cancros; manchas tipo ojo de rana en hoja.',
      ),
      PlantHealthDiagnosis(
        id: 'sooty_blotch_flyspeck',
        labelEs: 'Mancha de hollín y puntitos negros',
        type: 'fungal_surface_complex',
        summaryEs:
            'Manchas superficiales tipo hollín y puntos negros en la piel con '
            'dosel húmedo y cerrado; daña apariencia más que pulpa.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si la lesión es hundida con anillos o cerca del cáliz.',
      'Busca madera muerta o cancros como fuente cercana.',
      'Confirma si hubo lluvia/calor o granizo cerca de cosecha.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _fruitActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),

  // ── Familia 4: Plagas directas de fruto ──────────────────────────────────
  PlantHealthSyndrome(
    id: 'apple_codling_moth_01',
    cropId: CropCatalog.appleTreeCropId,
    labelEs: 'Perforación con galería o aserrín en el fruto',
    stages: _fruitStages,
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFruitTunnelFrass,
    strongSignals: <String>{
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalActiveChewing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'codling_moth',
        labelEs: 'Palomilla de la manzana / carpocapsa',
        scientificName: 'Cydia pomonella',
        type: 'insect',
        summaryEs:
            'Principal plaga directa de fruto: perforación con frass y galería '
            'hacia las semillas, con caída prematura. El historial del bloque '
            'pesa cada año.',
      ),
      PlantHealthDiagnosis(
        id: 'leafroller_fruit_scarring_complex',
        labelEs: 'Enrolladores / gusanos de hoja y fruto',
        type: 'insect',
        summaryEs:
            'Hojas pegadas o enrolladas y cicatrices superficiales en fruto '
            'joven; revisa larvas, no solo enfermedad.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca perforación con aserrín (frass) y galería hacia la semilla.',
      'Distingue daño de palomilla de una simple pudrición.',
      'Revisa fruta caída y el historial de palomilla del huerto.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _fruitActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
    varietyModifiers: <VarietyModifier>[
      _apModifier(
        profiles: <String>{kAp01Golden, kAp02Red, kAp04Gala},
        diagnosisId: 'codling_moth',
        delta: 6,
        rationale:
            'Perfiles comerciales con fruta de mesa: el daño de palomilla pesa '
            'más en calidad comercial.',
      ),
    ],
  ),

  // ── Familia 5: Plagas de brote, hoja y madera ────────────────────────────
  PlantHealthSyndrome(
    id: 'apple_woolly_aphid_01',
    cropId: CropCatalog.appleTreeCropId,
    labelEs: 'Masas blancas algodonosas en ramas o tronco',
    stages: _woodStages,
    organIds: <String>{PlantHealthIds.organStem, PlantHealthIds.organRoot},
    primarySymptomId: PlantHealthIds.symptomWoollyWhiteColonies,
    strongSignals: <String>{
      PlantHealthIds.signalGallsOnWoodRoots,
      PlantHealthIds.signalStickyHoneydew,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'woolly_apple_aphid',
        labelEs: 'Pulgón lanígero del manzano',
        scientificName: 'Eriosoma lanigerum',
        type: 'insect',
        summaryEs:
            'Masas blancas algodonosas en ramas, tronco, heridas y raíces, con '
            'agallas y debilitamiento. Fuerte en Chihuahua; vuelve cada año y '
            'puede afectar raíz y madera.',
      ),
      PlantHealthDiagnosis(
        id: 'green_rosy_apple_aphid',
        labelEs: 'Pulgón verde / ceniciento',
        type: 'insect',
        summaryEs:
            'Colonias en brotes tiernos con hojas enrolladas y fruto joven '
            'deformado, favorecidas por brotación tierna y exceso de N.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Si ves "algodón" o "bolitas blancas" en ramas/tronco, prioriza pulgón '
          'lanígero.',
      'Revisa heridas, base del árbol y raíces/sierpes.',
      'Busca agallas o deformaciones en la madera.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _woodActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _apModifier(
        profiles: <String>{kAp01Golden},
        diagnosisId: 'woolly_apple_aphid',
        delta: 6,
        rationale:
            'Golden en Chihuahua sube por evidencia regional de pulgón '
            'lanígero.',
      ),
    ],
  ),

  // ── Familia 6: Estrés fisiológico, clima y calidad ───────────────────────
  PlantHealthSyndrome(
    id: 'apple_sunburn_01',
    cropId: CropCatalog.appleTreeCropId,
    labelEs: 'Mancha clara o quemada en el lado soleado del fruto',
    stages: _fruitStages,
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFruitSunburnPatch,
    strongSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalExposedFruitSouthwest,
    },
    weakSignals: <String>{PlantHealthIds.signalDryHotWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'sunburn_sunscald',
        labelEs: 'Golpe de sol / quemadura de fruto',
        type: 'abiotic_heat',
        summaryEs:
            'Manchas claras, cafés o hundidas en el lado expuesto, mayor con '
            'calor/radiación, fruta expuesta por poda/defoliación y estrés '
            'hídrico.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa el lado soleado (suroeste) y zonas defoliadas del árbol.',
      'Cruza con calor, radiación y humedad baja recientes.',
      'Diferencia de una pudrición: el golpe de sol es por exposición.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: _fruitActions,
    disclaimerEs: _disclaimer,
  ),
  PlantHealthSyndrome(
    id: 'apple_bitter_pit_01',
    cropId: CropCatalog.appleTreeCropId,
    labelEs: 'Puntos oscuros hundidos en el fruto (mancha amarga)',
    stages: _fruitStages,
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFruitSunkenPits,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'bitter_pit_calcium_functional',
        labelEs: 'Bitter pit / mancha amarga / calcio funcional',
        type: 'abiotic_physiological',
        summaryEs:
            'Puntos oscuros hundidos y tejido corchoso bajo la piel, ligados a '
            'calcio funcional bajo, vigor excesivo, exceso de N/K y riego '
            'irregular. Se lee como balance agua-vigor-carga, no como receta de '
            'calcio.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si los puntos aparecen o crecen en almacenamiento.',
      'Cruza con vigor alto, N/K altos, baja carga y riego irregular.',
      'En v1 no apliques calcio a ciegas: confirma el balance primero.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: _fruitActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _apModifier(
        profiles: <String>{kAp01Golden, kAp04Gala},
        diagnosisId: 'bitter_pit_calcium_functional',
        delta: 5,
        rationale:
            'Golden y Gala son más sensibles a bitter pit / calcio funcional.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'apple_iron_chlorosis_01',
    cropId: CropCatalog.appleTreeCropId,
    labelEs: 'Hojas nuevas amarillas con nervaduras verdes',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomInternervalChlorosisNewLeaves,
    strongSignals: <String>{PlantHealthIds.signalHighPhCalcareous},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'iron_chlorosis_high_ph',
        labelEs: 'Clorosis férrica por pH alto',
        type: 'abiotic_nutritional',
        summaryEs:
            'Hojas nuevas amarillas con nervaduras verdes en suelo calcáreo o '
            'pH alto: puede haber hierro en el suelo pero no disponible. '
            'Confirmar con análisis antes de corregir; no es falta de N.',
      ),
      PlantHealthDiagnosis(
        id: 'zinc_deficiency_rosette',
        labelEs: 'Deficiencia de zinc / roseta',
        type: 'abiotic_nutritional',
        summaryEs:
            'Hojas pequeñas, entrenudos cortos y brotes tipo roseta; en pH alto '
            'puede haber bloqueo de zinc. Confirmar antes de corregir.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El amarillamiento es en hojas nuevas con nervadura verde?',
      'Confirma si el suelo es de pH alto o calcáreo.',
      'Conviene análisis de suelo/foliar antes de corregir.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
  ),
];

/// Conjunto de etapas usado por documentación/expansión futura del catálogo.
const Set<PlantHealthStageBucket> appleTreeAllStages = _allTreeStages;
