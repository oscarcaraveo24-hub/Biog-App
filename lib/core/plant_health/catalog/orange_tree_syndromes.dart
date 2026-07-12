import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo de riesgos / sanidad vegetal del Naranjo (`crop_orange_tree`).
///
/// Alimentado por el documento oficial
/// `04_Riesgos_Cultivo_Sanidad_Estres_Memoria_BioG_Naranjo_OR_v1`.
///
/// Reglas no negociables:
/// - BIO-G ORIENTA, no diagnostica de forma absoluta: "condición favorable a…",
///   "revisa…", "síntomas compatibles con…", "confirma si avanza…".
/// - NO receta plaguicidas ni ingredientes activos (doc 04 §0).
/// - NO diagnostica HLB/VTC/cancro/Phytophthora de forma cerrada: eleva cautela
///   y pide confirmación con técnico/sanidad local (doc 04 §0, §5.1).
/// - El perfil OR solo modifica sensibilidad/mensajes (varietyModifiers); el
///   catálogo base es el mismo para todas las variedades.
/// - Cítrico SIEMPREVERDE con MEMORIA fuerte: salinidad, HLB/psílido,
///   Phytophthora, defoliación, caída de fruto y mala postcosecha pesan en el
///   ciclo siguiente (doc 04 §5.10, §10). `dormancy` y `post_harvest` NO apagan
///   la sanidad.
///
/// Ejes críticos propios del naranjo (doc 04 §0): brotación tierna (vector
/// psílido/HLB), floración/cuajado sensibles, raíz/cuello/salinidad y calidad
/// externa/interna del fruto. NO se reusa el catálogo del pistache.

const Set<PlantHealthStageBucket> _establishmentStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
    };

// Incluye `lateSeason` a propósito: en cítricos chupadores, ácaros, salinidad y
// deficiencias siguen pesando en postcosecha/reposo relativo —etapas que el
// adapter mapea a lateSeason— para que post_harvest/dormancy NO queden como
// etapas apagadas (memoria y siguiente floración; doc 04 §5.10, §10).
const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.lateSeason,
};

// Brotación tierna: minador, psílido, pulgones, trips (doc 04 §5.3).
const Set<PlantHealthStageBucket> _flushStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
};

// Fe/Zn/Mn / hoja chica / clorosis: brotación y crecimiento (doc 04 §5.9,
// doc 05 §8.5).
const Set<PlantHealthStageBucket> _micronutrientStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.lateSeason,
    };

// Floración y cuajado (doc 04 §5.5).
const Set<PlantHealthStageBucket> _bloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

// Fruto/cáscara: amarre, llenado, madurez y postcosecha (doc 04 §5.7, §5.8).
const Set<PlantHealthStageBucket> _fruitStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// HLB/psílido/vector: todo el año, con foco en brotes tiernos y fruto (doc 04
// §5.1).
const Set<PlantHealthStageBucket> _hlbStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const String _disclaimer =
    'Orientación de riesgo, no diagnóstico definitivo. BIO-G sugiere revisar, '
    'comparar y confirmar en campo o con asesoría/sanidad local si el daño '
    'avanza. No prescribe plaguicidas ni ingredientes activos. HLB, VTC, cancro '
    'y Phytophthora requieren confirmación técnica; no se cierran por sensor.';

const List<String> _baseActions = <String>[
  'Marca el foco (por árbol, línea o borde) y revisa el avance en 24-72 horas.',
  'Cruza el síntoma con etapa, clima reciente (calor, frío, helada, lluvia, '
      'viento) y manejo antes de asumir una sola causa.',
  'Registra fotos, etapa visible y condiciones: en naranjo la memoria del ciclo '
      'pesa fuerte para la siguiente floración/cosecha.',
];

const List<String> _hlbActions = <String>[
  'No cierres el diagnóstico: el HLB/dragón amarillo se parece a deficiencias. '
      'Revisa si el moteado de la hoja es DISPAREJO/asimétrico, si hay psílido '
      '(ninfas o tubitos blancos en brotes) y si la fruta sale chica, ladeada o '
      'amarga.',
  'Si hay señales compatibles y la región tiene psílido/HLB, toma foto y '
      'confirma con técnico o sanidad local (SENASICA/campaña). BIO-G baja la '
      'confianza de la lectura NPK cuando hay sospecha de HLB.',
  'Protege el brote tierno: es donde se mete el psílido. No diagnostiques HLB '
      'por una hoja amarilla ni por el sensor.',
];

const List<String> _rootActions = <String>[
  'Revisa cuello, raíces y drenaje antes de regar más.',
  'Marchitez con suelo húmedo NO es falta de agua: separa pudrición de raíz/'
      'asfixia (Phytophthora) de salinidad o compactación. Si hay goma en la '
      'base del tronco, piensa en gomosis, no en falta de fertilizante.',
  'El naranjo es sensible a sales: si la EC está alta, no empujes fertilización '
      'fuerte. Revisa CE, agua de riego, drenaje y lavado.',
];

const List<String> _flushActions = <String>[
  'Revisa los brotes tiernos y el envés de la hoja nueva: minador (galerías '
      'plateadas serpenteadas), psílido, pulgones o trips.',
  'Brote tierno NO significa exceso de nitrógeno automáticamente: primero busca '
      'la plaga antes de culpar al fertilizante.',
  'En zona con HLB, el brote tierno sube la presión del psílido: monitorea y '
      'confirma con sanidad local si aparece el vector.',
];

const List<String> _foliarActions = <String>[
  'Revisa el envés de las hojas: chupadores (escamas, cochinillas, mosca blanca/'
      'prieta, pulgones), mielecilla pegajosa, negrilla (fumagina) o ácaros.',
  'La negrilla es CONSECUENCIA de la mielecilla: busca primero el insecto '
      'chupador, no la trates como hongo principal.',
  'Si defolia durante llenado o postcosecha, guarda la memoria: baja reservas y '
      'afecta la siguiente floración y el calibre.',
];

const List<String> _bloomActions = <String>[
  'En floración/cuajado el naranjo no perdona estrés: cruza calor, frío/helada, '
      'viento, humedad del suelo y sales antes de culpar al fertilizante.',
  'Algo de caída de flor/frutito puede ser normal. Se vuelve alerta si coincide '
      'con calor, agua baja, salinidad, raíz mala o sanidad.',
  'Mucha flor no asegura cosecha: si no hay hoja funcional o hubo estrés, '
      'fertilizar no resuelve el cuajado.',
];

const List<String> _fruitActions = <String>[
  'Abre y revisa varias naranjas: ¿pudrición (café/verde-azul), larvas/'
      'picaduras, mancha de cáscara, rajado o fruta seca por dentro?',
  'Separa pudrición de fruto bajo tras lluvia (brown rot/Phytophthora del '
      'suelo) del moho de cosecha por heridas (Penicillium) y de la mosca de la '
      'fruta (larvas). No diagnostiques sin abrir muestra.',
  'Si hay mosca de la fruta o plaga regulada, en región con campaña recomienda '
      'seguimiento con sanidad local. Guarda el evento de clima húmedo.',
];

const List<String> _abioticActions = <String>[
  'Muchos daños de fruta NO son enfermedad: el rajado suele venir de riego '
      'irregular (seco y luego mucha agua), calor o cáscara débil; el golpe de '
      'sol, del lado expuesto; la cicatriz de viento, del roce con ramas.',
  'Revisa patrón de riego, calor y aplicaciones recientes (aceite/cobre/'
      'herbicida) antes de asumir un hongo. La fitotoxicidad sigue el patrón de '
      'la aspersión/deriva.',
  'Guarda como estrés hídrico/físico o de manejo: ayuda a decidir riego, poda y '
      'calidad del siguiente ciclo.',
];

const List<String> _nutritionActions = <String>[
  'Con pH alto o caliza, la hoja nueva amarilla con nervadura verde suele ser '
      'Fe/Zn/Mn bloqueados, NO falta de nitrógeno. Confirma con análisis foliar.',
  'K bajo en llenado pega a calibre y jugo, pero si falta agua o hay sales, '
      'primero corrige eso: el árbol no toma bien el K con la raíz estresada.',
  'Bordes de hoja quemados pueden ser sales/cloruros/sodio o calor, no solo '
      'falta de potasio. BIO-G v1 no mide Fe/Zn/Mn/B/Ca/Mg: úsalos como '
      'contexto y análisis, no como dosis.',
];

const List<String> _memoryActions = <String>[
  'La cosecha NO cierra el naranjo: si queda hoja activa, el árbol recupera '
      'reservas para la siguiente floración. No apagues el seguimiento.',
  'Guarda estreses de este ciclo (salinidad, HLB/psílido, Phytophthora, '
      'defoliación, caída fuerte, cosecha larga): afectan brotación, cuajado y '
      'calibre del siguiente ciclo.',
  'Si la EC quedó alta al cierre o el árbol quedó cansado por carga alta, la '
      'siguiente floración puede salir débil: cuida hoja, raíz y sales.',
];

/// Modificador de sensibilidad por perfil OR (doc 04 §6, doc 05 §11).
VarietyModifier _orModifier({
  required Set<String> profiles,
  required String diagnosisId,
  required int delta,
  required String rationale,
  bool requiresCaution = false,
}) => VarietyModifier(
  cropId: CropCatalog.orangeTreeCropId,
  varietyIds: profiles,
  diagnosisIds: <String>{diagnosisId},
  scoreDelta: delta,
  rationaleEs: rationale,
  isProxy: true,
  requiresCaution: requiresCaution,
);

/// Catálogo de síndromes del naranjo. `final` (no `const`) por los modificadores
/// por perfil OR construidos con [_orModifier].
final List<PlantHealthSyndrome> orangeTreeSyndromes = <PlantHealthSyndrome>[
  // ── Familia 1: HLB, psílido asiático y riesgos regulados ──────────────────
  PlantHealthSyndrome(
    id: 'orange_hlb_psyllid_context_01',
    cropId: CropCatalog.orangeTreeCropId,
    labelEs: 'Moteado disparejo, brote con psílido o fruta chica/ladeada',
    stages: _hlbStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomCitrusBlotchyMottle,
    strongSignals: <String>{
      PlantHealthIds.signalAsymmetricMottle,
      PlantHealthIds.signalPsyllidWaxyTubules,
    },
    weakSignals: <String>{
      PlantHealthIds.signalFruitBitterMisshapen,
      PlantHealthIds.signalFlushNewGrowth,
      PlantHealthIds.signalVectorPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'huanglongbing_hlb_context',
        labelEs: 'HLB / dragón amarillo / greening (contexto, NO diagnóstico)',
        scientificName: 'Candidatus Liberibacter spp.',
        type: 'bacteria_regulated_context',
        summaryEs:
            'El HLB da moteado AMARILLO ASIMÉTRICO en hoja, sectores amarillos, '
            'árbol decaído, fruto chico/ladeado/amargo y caída prematura. BIO-G '
            'NUNCA lo confirma por sensor ni por una foto suelta: si hay moteado '
            'disparejo + fruta chica/deforme + caída + región con psílido, eleva '
            'la urgencia de revisión y baja la confianza del NPK (el HLB imita '
            'deficiencias). Confirma con técnico/laboratorio/sanidad.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalAsymmetricMottle},
      ),
      PlantHealthDiagnosis(
        id: 'asian_citrus_psyllid_vector',
        labelEs: 'Psílido asiático de los cítricos (vector)',
        scientificName: 'Diaphorina citri',
        type: 'insect_vector',
        summaryEs:
            'Insecto pequeño café con postura inclinada; ninfas amarillas/'
            'naranjas con tubitos cerosos blancos y mielecilla en brotes '
            'tiernos. Si se ve psílido, no diagnostiques HLB automáticamente, '
            'pero sube la presión de vector y revisa los brotes. En regiones '
            'productoras, sugiere seguimiento con campaña/asesoría local.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalPsyllidWaxyTubules,
        },
      ),
      PlantHealthDiagnosis(
        id: 'citrus_canker_regulated_context',
        labelEs: 'Cancro de los cítricos (regulado, según región)',
        scientificName: 'Xanthomonas citri subsp. citri',
        type: 'bacteria_regulated_context',
        summaryEs:
            'Lesiones elevadas/corchosas con margen acuoso y halo amarillo en '
            'hoja/fruto/tallo, ásperas, que no se limpian. No activar como '
            'diagnóstico universal: si hay lesiones con halo y contexto '
            'regional, pide confirmación fitosanitaria. No recomendar productos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterSoakedMargin,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tristeza_virus_context',
        labelEs: 'Tristeza de los cítricos / decaimiento (VTC)',
        scientificName: 'Citrus tristeza virus',
        type: 'virus_context',
        summaryEs:
            'Decaimiento crónico, bajo vigor, hojas pequeñas/cloróticas y muerte '
            'en combinaciones sensibles de portainjerto. Solo diferencial de '
            'decaimiento: requiere diagnóstico técnico. No confundir con sales, '
            'Phytophthora, HLB o nutrición.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El moteado amarillo es disparejo/asimétrico entre los dos lados de la '
          'hoja?',
      '¿Hay psílido (ninfas, tubitos blancos) en los brotes tiernos?',
      '¿La fruta sale chica, ladeada, amarga o cae verde? ¿La región tiene HLB/'
          'psílido reportado?',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.immediate,
    baseActionsEs: _hlbActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _orModifier(
        profiles: <String>{kOr05TropicalCalido},
        diagnosisId: 'asian_citrus_psyllid_vector',
        delta: 8,
        rationale:
            'Clima cálido/tropical con brotes frecuentes todo el año sube la '
            'presión del psílido (doc 04 §6, doc 05 §11).',
      ),
      _orModifier(
        profiles: <String>{kOr04CriolloRegional},
        diagnosisId: 'asian_citrus_psyllid_vector',
        delta: 5,
        rationale:
            'Huertos criollos/regionales mixtos y traspatios elevan el riesgo '
            'de vector; usar con cautela (doc 04 §6).',
        requiresCaution: true,
      ),
    ],
  ),

  // ── Familia 2: Raíz, cuello, drenaje, Phytophthora y salinidad ────────────
  PlantHealthSyndrome(
    id: 'orange_root_crown_phytophthora_01',
    cropId: CropCatalog.orangeTreeCropId,
    labelEs: 'Decaimiento con suelo húmedo, goma en tronco o borde quemado',
    stages: _establishmentStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalGumAtTrunkBase,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalHighPhCalcareous,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'phytophthora_gummosis_foot_rot',
        labelEs: 'Gomosis / pudrición de cuello por Phytophthora',
        scientificName: 'Phytophthora spp.',
        type: 'oomycete_soil_complex',
        summaryEs:
            'Goma/ámbar en el tronco bajo o cuello, corteza oscura/hundida y '
            'decaimiento de copa con baja respuesta al riego/fertilizante. '
            'Favorecida por humedad en el cuello, riego pegado al tronco, mal '
            'drenaje y suelo pesado. No recomendar más riego ni fertilizante: '
            'prioriza cuello, drenaje y raíz.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalGumAtTrunkBase},
      ),
      PlantHealthDiagnosis(
        id: 'phytophthora_root_rot_anoxia',
        labelEs: 'Pudrición de raíz por Phytophthora / raíz asfixiada',
        scientificName: 'Phytophthora nicotianae, P. palmivora',
        type: 'oomycete_soil_complex',
        summaryEs:
            'Árbol triste con suelo húmedo, copa rala, hojas pálidas, caída y '
            'raíz fina marrón. Marchitez con suelo mojado NO es falta de agua: '
            'revisa drenaje y raíz antes de regar. El HLB puede agravar el daño '
            'de raíz y baja la confianza del sensor.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWaterlogging},
      ),
      PlantHealthDiagnosis(
        id: 'salinity_root_stress_context',
        labelEs: 'Estrés salino / EC alta en raíz',
        type: 'abiotic_soil',
        summaryEs:
            'Borde de hoja quemado, defoliación, fruta chica y síntomas de '
            'sequía aunque se riegue. El naranjo es sensible a sales: si la EC '
            'está alta, bloquea recomendaciones agresivas de NPK. Salinidad + '
            'humedad baja = estrés osmótico fuerte. Revisa CE, agua y drenaje.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'soil_compaction_root_stress',
        labelEs: 'Compactación / raíz sin aire',
        type: 'abiotic_soil',
        summaryEs:
            'Bajo vigor por líneas, charcos, raíz superficial y respuesta pobre '
            'a riego/fertilizante. La raíz cítrica necesita aireación: '
            'resistencia alta + humedad alta dispara riesgo de raíz. Suelo y '
            'raíz primero, NPK después.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRootsDarkRot},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La marchitez ocurre con suelo húmedo (no seco)?',
      '¿Hay goma/exudado en la base del tronco o el cuello?',
      '¿El agua de riego deja salitre/costra blanca? ¿El suelo se encharca o se '
          'pone duro?',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _orModifier(
        profiles: <String>{kOr01Valencia},
        diagnosisId: 'salinity_root_stress_context',
        delta: 5,
        rationale:
            'Valencia de ciclo largo con riego prolongado acumula más sales; '
            'vigilar salinidad y postcosecha (doc 04 §6).',
      ),
      _orModifier(
        profiles: <String>{kOr04CriolloRegional},
        diagnosisId: 'salinity_root_stress_context',
        delta: 5,
        rationale:
            'Manejo irregular en huertos regionales sube el riesgo de salinidad/'
            'raíz (doc 04 §6).',
        requiresCaution: true,
      ),
    ],
  ),

  // ── Familia 3: Brotación tierna y plagas de brote ─────────────────────────
  PlantHealthSyndrome(
    id: 'orange_flush_pests_01',
    cropId: CropCatalog.orangeTreeCropId,
    labelEs: 'Hoja nueva con minas, brote enrollado o frutito con cicatriz',
    stages: _flushStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomLeafMines,
    strongSignals: <String>{
      PlantHealthIds.signalLeafMines,
      PlantHealthIds.signalFlushNewGrowth,
    },
    weakSignals: <String>{
      PlantHealthIds.signalLeafRolling,
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalStickyHoneydew,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'citrus_leafminer',
        labelEs: 'Minador de la hoja de los cítricos',
        scientificName: 'Phyllocnistis citrella',
        type: 'insect',
        summaryEs:
            'Galerías plateadas/serpenteadas en hojas nuevas, hojas enrolladas '
            'o deformadas y brote tierno dañado. Si hay "caminitos" en la hoja '
            'nueva, no diagnostiques hongo ni deficiencia. Pesa más en árbol '
            'joven y con flush fuerte; puede abrir puerta a cancro.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalLeafMines},
      ),
      PlantHealthDiagnosis(
        id: 'aphid_flush_complex',
        labelEs: 'Pulgones en brote tierno',
        type: 'insect',
        summaryEs:
            'Colonias en brotes, hojas enrolladas, mielecilla pegajosa y '
            'negrilla posterior. Hoja pegajosa + brote enrollado = revisar '
            'pulgón/chupador antes que hongo. El exceso de N y las hormigas '
            'favorecen la colonia.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalStickyHoneydew},
      ),
      PlantHealthDiagnosis(
        id: 'citrus_thrips_rind_scar',
        labelEs: 'Trips de los cítricos / cicatriz en fruto joven',
        scientificName: 'Scirtothrips citri',
        type: 'insect',
        summaryEs:
            'Cicatrices plateadas/corchosas en la cáscara, anillos o raspaduras '
            'cerca del cáliz; la fruta sale marcada desde chica. Separa de la '
            'cicatriz de viento y de melanosis por el patrón y la etapa.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalThripsPresent},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay galerías/minas serpenteadas en la hoja NUEVA?',
      '¿El brote está tierno, enrollado o con mielecilla?',
      '¿La marca de la fruta nace desde que estaba chica, cerca del cáliz?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _flushActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _orModifier(
        profiles: <String>{kOr05TropicalCalido},
        diagnosisId: 'citrus_leafminer',
        delta: 8,
        rationale:
            'Clima cálido con brotación continua todo el año favorece al '
            'minador (doc 04 §6, doc 05 §11).',
      ),
    ],
  ),

  // ── Familia 4: Chupadores, mielecilla, fumagina y ácaros ──────────────────
  PlantHealthSyndrome(
    id: 'orange_sucking_pests_sooty_01',
    cropId: CropCatalog.orangeTreeCropId,
    labelEs: 'Hoja pegajosa, negrilla o fruta bronceada/manchada',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomHoneydewSootyShoots,
    strongSignals: <String>{
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCannotScrapeOff,
      PlantHealthIds.signalWhiteflyCloud,
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalBronzedLeafSurface,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'scale_mealybug_complex',
        labelEs: 'Escamas / cochinillas (piojo harinoso)',
        type: 'insect',
        summaryEs:
            'Costras pegadas en hoja/rama/fruto que no se mueven, o masas '
            'blancas algodonosas bajo el cáliz y uniones de fruta, con '
            'mielecilla y negrilla. Si la costra no se raspa, piensa en escama; '
            'si son colonias algodonosas, cochinilla. No confundir con hongo '
            'blanco.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalCannotScrapeOff},
      ),
      PlantHealthDiagnosis(
        id: 'whitefly_blackfly_sooty_complex',
        labelEs: 'Mosca blanca / mosca prieta + fumagina',
        scientificName: 'Aleurocanthus woglumi',
        type: 'insect',
        summaryEs:
            'Ninfas/escamas en el envés, vuelo de mosquitas al mover la hoja, '
            'mielecilla y fumagina negra. Negrilla + envés con ninfas = '
            'chupador: no trates la fumagina como causa primaria, busca el '
            'insecto que produce la miel.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWhiteflyCloud},
      ),
      PlantHealthDiagnosis(
        id: 'citrus_rust_spider_mite_complex',
        labelEs: 'Ácaro de la roya / araña roja / bronceado',
        type: 'mite',
        summaryEs:
            'Piel bronceada/oxidada (russeting) o punteado y telaraña fina en '
            'hoja/fruto, en clima cálido/seco y con polvo. El bronceado sin '
            'pudrición puede ser ácaro, no solo "fruta quemada". Diferéncialo de '
            'salinidad, golpe de sol y deficiencias.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalMitesWebbing},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La hoja/fruta está pegajosa y con tizne negro (negrilla)?',
      '¿Hay costras que no se raspan, algodón blanco, mosquita blanca o '
          'telaraña fina en el envés?',
      '¿La fruta se ve bronceada/oxidada sin pudrición?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _foliarActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),

  // ── Familia 5: Floración, cuajado y caída temprana ────────────────────────
  PlantHealthSyndrome(
    id: 'orange_flowering_set_drop_01',
    cropId: CropCatalog.orangeTreeCropId,
    labelEs: 'Floreó pero amarró poco, o se cae el frutito',
    stages: _bloomStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalFlowerDrop,
      PlantHealthIds.signalDryHotWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalFrostEvent,
      PlantHealthIds.signalSalinityLoad,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'flowering_heat_water_stress',
        labelEs: 'Estrés de floración por calor/agua',
        type: 'abiotic_physiological',
        summaryEs:
            'Flor seca, caída de flores y poco amarre con calor fuerte, viento '
            'seco, baja humedad del suelo o salinidad. Si coincide con calor y '
            'agua baja, el mensaje debe hablar de agua/temperatura primero, no '
            'de fertilizante: el N alto no arregla una floración estresada.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
      PlantHealthDiagnosis(
        id: 'frost_bloom_damage',
        labelEs: 'Daño por frío/helada en flor o fruto pequeño',
        type: 'abiotic_cold',
        summaryEs:
            'Flor café/negra, fruto pequeño dañado o que cae y hojas tiernas '
            'quemadas tras helada o noches frías. Si hubo helada, no culpes al '
            'NPK por el bajo amarre: registra el evento climático.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrostEvent},
      ),
      PlantHealthDiagnosis(
        id: 'fruit_set_drop_stress_complex',
        labelEs: 'Caída de fruto recién amarrado (June drop / estrés)',
        type: 'abiotic_physiological',
        summaryEs:
            'Frutitos pequeños en el suelo y baja retención tras floración '
            'fuerte. Parte de la caída puede ser natural (competencia de '
            'carbohidratos). Se vuelve alerta si coincide con calor, agua baja, '
            'salinidad, HLB, poca hoja o plaga: no diagnostiques solo por NPK.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFlowerDrop},
      ),
      PlantHealthDiagnosis(
        id: 'navel_orange_fruit_drop_context',
        labelEs: 'Caída fuerte en Navel / ombligo',
        type: 'abiotic_physiological',
        summaryEs:
            'La fisiología del Navel favorece una caída importante después del '
            'cuajado, agravada por estrés de agua/calor y carga. Es contexto del '
            'perfil Navel; no lo generalices a todos los naranjos.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHeatStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Floreó mucho pero amarró poco?',
      '¿Hubo calor fuerte, viento seco, helada o falta de agua durante la flor/'
          'cuajado?',
      '¿La caída coincide con sales, raíz mala o brotes que compiten?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _bloomActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _orModifier(
        profiles: <String>{kOr02Navel},
        diagnosisId: 'navel_orange_fruit_drop_context',
        delta: 10,
        rationale:
            'El Navel tiene caída fisiológica marcada tras el cuajado (doc 04 '
            '§5.5, §6).',
      ),
      _orModifier(
        profiles: <String>{kOr03Temprano},
        diagnosisId: 'flowering_heat_water_stress',
        delta: 6,
        rationale:
            'El grupo temprano florea/cuaja antes y puede coincidir con calor/'
            'estrés temprano (doc 04 §6).',
      ),
    ],
  ),

  // ── Familia 6: Enfermedades foliares y de copa ────────────────────────────
  PlantHealthSyndrome(
    id: 'orange_foliar_disease_01',
    cropId: CropCatalog.orangeTreeCropId,
    labelEs: 'Manchas grasosas, ásperas u oscuras en hoja/fruto',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalDenseWetCanopy,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSpringWetFoliage,
      PlantHealthIds.signalUndersideSporulation,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'greasy_spot_mycosphaerella',
        labelEs: 'Mancha grasienta / greasy spot',
        scientificName: 'Mycosphaerella citri',
        type: 'fungus',
        summaryEs:
            'Manchas amarillas que se ven cafés/negras con aspecto grasoso, más '
            'visibles en el envés, con defoliación si es severa. Favorecida por '
            'humedad prolongada, hojarasca y mala ventilación. No confundir con '
            'HLB (patrón) ni con deficiencia.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'melanose_diaporthe',
        labelEs: 'Melanosis / manchado áspero de hoja y fruta',
        scientificName: 'Diaporthe citri',
        type: 'fungus',
        summaryEs:
            'Puntos ásperos/corchosos en fruta y hoja, con patrón de "lágrima" '
            'o escurrimiento en la fruta, tras lluvia y con madera muerta como '
            'fuente. Si las manchas ásperas no penetran y hubo lluvia, sepáralo '
            'de trips, cicatriz de viento y cancro.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSpringWetFoliage},
      ),
      PlantHealthDiagnosis(
        id: 'anthracnose_colletotrichum',
        labelEs: 'Antracnosis / manchado y secamiento',
        scientificName: 'Colletotrichum spp.',
        type: 'fungus',
        summaryEs:
            'Manchas oscuras, "tearstain" en fruta, muerte de brotes y '
            'pudrición blanda en cosecha/postcosecha, sobre tejido debilitado o '
            'estresado y con humedad. Diferénciala de Alternaria, Septoria, '
            'Phytophthora y daño físico.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'citrus_scab_regional',
        labelEs: 'Sarna / costra de cítricos (regional)',
        scientificName: 'Elsinoë fawcettii',
        type: 'fungus',
        summaryEs:
            'Lesiones corchosas, verrugosas o costrosas con deformación de '
            'fruto/hoja en tejido joven y regiones húmedas. Diferénciala de '
            'cancro, trips y melanosis.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDenseWetCanopy},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las manchas se ven grasosas en el envés y hay defoliación?',
      '¿Hubo lluvia/humedad prolongada o dosel cerrado y mojado?',
      '¿Las manchas ásperas de la cáscara NO penetran (superficiales)?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── Familia 7: Enfermedades y daños de fruto / cáscara / cosecha ──────────
  PlantHealthSyndrome(
    id: 'orange_fruit_disease_rot_01',
    cropId: CropCatalog.orangeTreeCropId,
    labelEs: 'Naranja podrida, con moho, larvas o pudrición desde el pedúnculo',
    stages: _fruitStages,
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomMummifiedFruitRot,
    strongSignals: <String>{
      PlantHealthIds.signalWhiteGreenBlueMold,
      PlantHealthIds.signalFruitLowCanopyRainSplash,
    },
    weakSignals: <String>{
      PlantHealthIds.signalFruitLarvae,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'brown_rot_phytophthora_fruit',
        labelEs: 'Pudrición café de fruto / brown rot',
        scientificName: 'Phytophthora spp.',
        type: 'oomycete',
        summaryEs:
            'Pudrición café blanda, sobre todo en el lado inferior del fruto y '
            'en fruta cerca del suelo, tras lluvia/salpicadura. Si la pudrición '
            'viene de abajo y hubo lluvia, conéctala con Phytophthora y suelo, '
            'no solo con postcosecha.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalFruitLowCanopyRainSplash,
        },
      ),
      PlantHealthDiagnosis(
        id: 'penicillium_blue_green_mold',
        labelEs: 'Moho verde/azul de cosecha y postcosecha',
        scientificName: 'Penicillium digitatum / P. italicum',
        type: 'fungus',
        summaryEs:
            'Mancha acuosa que desarrolla micelio blanco y esporas verdes/'
            'azules, asociada a heridas y manejo brusco en fruta madura. No la '
            'confundas con un problema de árbol completo: es de herida/manejo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWhiteGreenBlueMold},
      ),
      PlantHealthDiagnosis(
        id: 'alternaria_black_rot_navel',
        labelEs: 'Alternaria / pudrición negra o mancha parda',
        scientificName: 'Alternaria spp.',
        type: 'fungus',
        summaryEs:
            'Pudrición oscura que avanza hacia el centro del fruto, frecuente en '
            'Navel y en fruta madura/almacenamiento. Si la pudrición se ve en '
            'cosecha/postcosecha sin salpicadura de suelo, considera Alternaria/'
            'Penicillium/Lasiodiplodia según el patrón.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'fruit_fly_maggot_context',
        labelEs: 'Mosca de la fruta / larvas en el fruto (regional)',
        scientificName: 'Anastrepha spp.',
        type: 'insect_regulated_context',
        summaryEs:
            'Picaduras, fruta caída y larvas internas con pudrición secundaria '
            'en fruta madura. No diagnostiques sin abrir fruta/muestra. Si hay '
            'larvas o picaduras y la región tiene campaña, recomienda '
            'seguimiento con sanidad local.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFruitLarvae},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La pudrición viene del lado bajo/cerca del suelo tras lluvia?',
      '¿El moho es verde/azul y arrancó de una herida de manejo?',
      '¿Hay larvas o picaduras al abrir la fruta?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _fruitActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      _orModifier(
        profiles: <String>{kOr02Navel},
        diagnosisId: 'alternaria_black_rot_navel',
        delta: 8,
        rationale:
            'El Navel es más susceptible a Alternaria/black rot en fruta madura '
            '(doc 04 §6, §5.7).',
      ),
    ],
  ),

  // ── Familia 8: Desórdenes abióticos de fruto y hoja ───────────────────────
  PlantHealthSyndrome(
    id: 'orange_abiotic_fruit_disorders_01',
    cropId: CropCatalog.orangeTreeCropId,
    labelEs: 'Naranja rajada, quemada por sol o con cicatriz de viento',
    stages: _fruitStages,
    organIds: <String>{
      PlantHealthIds.organFruit,
      PlantHealthIds.organLeaf,
    },
    primarySymptomId: PlantHealthIds.symptomCitrusSplitFruit,
    strongSignals: <String>{
      PlantHealthIds.signalFruitSplitAfterIrrigation,
      PlantHealthIds.signalExposedFruitSouthwest,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRindScarsNearCalyx,
      PlantHealthIds.signalRecentSprayOilCopper,
      PlantHealthIds.signalHeatStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'fruit_splitting_cracking',
        labelEs: 'Rajado / partido de naranja',
        type: 'abiotic_physiological',
        summaryEs:
            'Grietas desde el extremo estilar o lateral, con entrada de hongos/'
            'insectos, por estrés hídrico (seco y luego mucha agua), riego '
            'irregular, calor, cáscara débil y K/Ca contextual. No es siempre '
            'hongo: revisa patrón de riego, calor, K y carga.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalFruitSplitAfterIrrigation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunburn_fruit_leaf',
        labelEs: 'Golpe de sol / fruta quemada',
        type: 'abiotic_physical',
        summaryEs:
            'Parches amarillos/café coriáceos en el lado expuesto (sur/oeste) de '
            'fruta y hojas, por calor extremo, radiación, poda fuerte o déficit '
            'hídrico. Si el daño está del lado expuesto, no lo confundas con '
            'pudrición o plaga.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalExposedFruitSouthwest,
        },
      ),
      PlantHealthDiagnosis(
        id: 'wind_scarring_rind',
        labelEs: 'Cicatriz por viento / raspadura de cáscara',
        type: 'abiotic_physical',
        summaryEs:
            'Cicatrices superficiales alargadas o corchosas donde la fruta rozó '
            'con rama o espina, en canopia abierta y fruta expuesta. Es daño '
            'físico: sepáralo de trips, melanosis y cancro.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRindScarsNearCalyx,
        },
      ),
      PlantHealthDiagnosis(
        id: 'phytotoxicity_oil_copper_herbicide',
        labelEs: 'Fitotoxicidad / quemadura por aplicación o deriva',
        type: 'abiotic_chemical',
        summaryEs:
            'Manchas tras aplicaciones de aceite, cobre o herbicida (o deriva), '
            'con patrón de salpicadura o del lado expuesto. Pregunta por '
            'aplicaciones recientes: si el patrón coincide con la aspersión, no '
            'lo confundas con enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRecentSprayOilCopper,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La fruta se rajó tras un periodo seco seguido de riego/lluvia?',
      '¿El daño está del lado expuesto al sol (sur/oeste)?',
      '¿Hubo aplicación reciente de aceite, cobre o herbicida?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _orModifier(
        profiles: <String>{kOr02Navel},
        diagnosisId: 'fruit_splitting_cracking',
        delta: 8,
        rationale:
            'El Navel es más sensible al rajado y a la calidad externa (doc 04 '
            '§6, §5.8).',
      ),
    ],
  ),

  // ── Familia 9: Nutrición y disponibilidad aparente ────────────────────────
  PlantHealthSyndrome(
    id: 'orange_nutrition_availability_01',
    cropId: CropCatalog.orangeTreeCropId,
    labelEs: 'Hoja amarilla con nervadura verde, fruta chica o borde quemado',
    stages: _micronutrientStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomInternervalChlorosisNewLeaves,
    strongSignals: <String>{
      PlantHealthIds.signalHighPhCalcareous,
      PlantHealthIds.signalLeafEdgeBurn,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalWaterlogging,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'iron_zinc_manganese_chlorosis_high_ph',
        labelEs: 'Clorosis por Fe/Zn/Mn (pH alto/caliza)',
        type: 'abiotic_nutritional_context',
        summaryEs:
            'Hoja NUEVA amarilla con nervaduras verdes, hoja chica o brotes '
            'pálidos, en suelos alcalinos/calizos, con exceso de humedad o raíz '
            'dañada. No diagnostiques falta de N si la clorosis es internerval '
            'en hoja nueva y el pH es alto: Fe/Zn/Mn son contexto, no sensor v1. '
            'Confirma con análisis foliar.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHighPhCalcareous},
      ),
      PlantHealthDiagnosis(
        id: 'potassium_low_fruit_quality_context',
        labelEs: 'K bajo / riesgo de calibre, jugo y cáscara',
        type: 'abiotic_nutritional_context',
        summaryEs:
            'Fruta chica, llenado pobre y mayor sensibilidad a estrés en '
            'llenado/madurez. K bajo pesa si agua/EC/pH están bien; pero si la '
            'humedad está baja o la EC alta, primero corrige agua/sales: el '
            'árbol no aprovecha el K con la raíz estresada.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'salinity_chloride_boron_leaf_burn',
        labelEs: 'Quemadura de borde por sales / cloruros / boro',
        type: 'abiotic_soil',
        summaryEs:
            'Quemadura marginal (tip burn), defoliación y bajo vigor con EC alta '
            'o agua salina, poca lixiviación y mal drenaje. Si la EC está alta, '
            'no digas "falta K" de inmediato: prioriza sales/agua/drenaje. Cl/Na/'
            'B son contexto avanzado, no sensores v1.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalLeafEdgeBurn},
      ),
      PlantHealthDiagnosis(
        id: 'nitrogen_deficiency_context',
        labelEs: 'N bajo / hoja pálida generalizada',
        type: 'abiotic_nutritional_context',
        summaryEs:
            'Hojas VIEJAS pálidas de forma generalizada, bajo crecimiento y copa '
            'rala, cuando humedad, raíz, EC y pH están bien. Antes de recomendar '
            'N, descarta pH alto, sales, raíz dañada y HLB: N bajo con raíz '
            'enferma no se resuelve solo con fertilizante.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El amarillamiento es en hoja NUEVA con nervadura verde (interno) o en '
          'hoja VIEJA generalizado?',
      '¿El suelo es de pH alto/calcáreo o hay salitre/EC alta?',
      '¿El borde de la hoja está quemado con agua salina o poca lixiviación?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: _nutritionActions,
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 10: Postcosecha y memoria perenne ─────────────────────────────
  PlantHealthSyndrome(
    id: 'orange_postharvest_memory_01',
    cropId: CropCatalog.orangeTreeCropId,
    labelEs: 'Defoliación o árbol cansado después de cosecha',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomLateDefoliation,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalDryHotWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalWaterlogging,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'post_harvest_leaf_loss_memory',
        labelEs: 'Defoliación postcosecha / poca hoja para la siguiente flor',
        type: 'memory_physiological',
        summaryEs:
            'Caída de hoja, copa rala y brotes débiles tras cosecha, por ácaros, '
            'chupadores, HLB, salinidad, Phytophthora, sequía o helada. Guarda '
            'el evento: impacta la siguiente floración y el calibre. No apagues '
            'las alertas después de cosecha.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
      PlantHealthDiagnosis(
        id: 'post_harvest_root_salinity_memory',
        labelEs: 'Raíz/sales arrastradas después de cosecha',
        type: 'memory_soil',
        summaryEs:
            'Si la EC quedó alta al cierre, con riego irregular o exceso de '
            'fertilizante, el siguiente flush/floración puede salir débil, con '
            'clorosis y caída temprana. Cuida sales, riego y raíz en postcosecha/'
            'reposo relativo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'heavy_crop_reserve_depletion_context',
        labelEs: 'Carga alta / reservas bajas para el siguiente ciclo',
        type: 'memory_physiological',
        summaryEs:
            'Árbol cansado con brotación débil y menor floración/cuajado tras '
            'una carga alta o cosecha larga (Valencia/tropical). Cuida hoja '
            'activa, riego y nutrición moderada en postcosecha para recuperar '
            'reservas.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
      PlantHealthDiagnosis(
        id: 'hlb_chronic_decline_memory',
        labelEs: 'Decaimiento crónico (HLB/VTC como contexto de memoria)',
        type: 'memory_regulated_context',
        summaryEs:
            'Decaimiento que se arrastra ciclo a ciclo con moteado asimétrico, '
            'fruta chica y baja hoja funcional. BIO-G no cierra HLB/VTC: lo '
            'guarda como memoria de región/árbol y pide confirmación. Fertilizar '
            'no revierte HLB/VTC.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalAsymmetricMottle},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El árbol perdió hoja o quedó cansado después de la cosecha?',
      '¿La EC quedó alta o hubo riego irregular al cierre del ciclo?',
      '¿Viene de una carga alta o cosecha larga (Valencia/tropical)?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _memoryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _orModifier(
        profiles: <String>{kOr01Valencia, kOr05TropicalCalido},
        diagnosisId: 'heavy_crop_reserve_depletion_context',
        delta: 6,
        rationale:
            'Valencia y tropical con cosecha extendida agotan más reservas; '
            'cuidar postcosecha y hoja activa (doc 04 §5.10, §6).',
      ),
    ],
  ),
];
