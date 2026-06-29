import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo de riesgos / sanidad vegetal del Nogal pecanero (`crop_walnut_tree`).
///
/// Alimentado por el documento oficial
/// `04_Riesgos_Cultivo_Sanidad_Estres_Memoria_BioG_Nogal_v1`.
///
/// Reglas no negociables:
/// - BIO-G ORIENTA, no diagnostica de forma absoluta: "condición favorable a…",
///   "revisa…", "síntomas compatibles con…", "confirma si avanza…".
/// - NO receta plaguicidas ni ingredientes activos (doc 04 §0, §14).
/// - El perfil NG solo modifica sensibilidad/mensajes (varietyModifiers); el
///   catálogo base es el mismo para todas las variedades (doc 04 §6).
/// - Árbol perenne con MEMORIA fuerte: helada en flor, mala polinización, estrés
///   hídrico en llenado, defoliación por pulgón/ácaro, barrenadores y mala
///   postcosecha pesan en el ciclo siguiente (alternancia) (doc 04 §13).
///
/// Diferencias clave vs manzano/pera/durazno (doc 04 §0): el nogal es frutal de
/// NUEZ con raíz profunda, alta demanda de agua en llenado, alta demanda de
/// ZINC, sensibilidad a salinidad/compactación y polinización cruzada por viento.
/// Riesgos centrales propios: deficiencia de zinc (roseta/hoja chica), pudrición
/// texana de raíz (Phymatotrichopsis), barrenador de la nuez (casebearer),
/// barrenador del ruezno (hickory shuckworm), pulgón amarillo/negro, decaimiento
/// de ruezno (shuck decline) y memoria de alternancia. NO se reusa el catálogo de
/// pepita ni de hueso (doc 04 §1).

const Set<PlantHealthStageBucket> _establishmentStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
    };

// Incluye `lateSeason` a propósito: en nogal los pulgones, ácaros y deficiencias
// siguen pesando en postcosecha/dormancia —etapas que el adapter mapea a
// lateSeason— para que post_harvest NO quede como etapa apagada (reservas y
// alternancia; doc 04 §2, §11 post_harvest, §13).
const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.lateSeason,
};

// Zinc / roseta: brotación y crecimiento vegetativo/juvenil (doc 04 §5.6).
const Set<PlantHealthStageBucket> _zincStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
};

// Floración masculina/femenina y amarre (doc 04 §4.2).
const Set<PlantHealthStageBucket> _bloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

// Nuez/ruezno: amarre, llenado, madurez y postcosecha (doc 04 §4.3).
const Set<PlantHealthStageBucket> _nutStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Madera/tronco/ramas (doc 04 §4.1 barrenadores/cancros).
const Set<PlantHealthStageBucket> _woodStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const String _disclaimer =
    'Orientación de riesgo, no diagnóstico definitivo. BIO-G sugiere revisar, '
    'comparar y confirmar en campo o con asesoría/sanidad local si el daño '
    'avanza. No prescribe plaguicidas ni ingredientes activos.';

const List<String> _baseActions = <String>[
  'Marca el foco (por árbol, línea o borde) y revisa el avance en 24-72 horas.',
  'Cruza el síntoma con etapa, clima reciente (lluvia, helada, granizo, calor) '
      'y manejo antes de asumir una sola causa.',
  'Registra fotos, etapa visible y condiciones: en nogal la memoria del ciclo '
      'pesa fuerte para el siguiente (alternancia).',
];

const List<String> _rootActions = <String>[
  'Revisa cuello, raíces y drenaje antes de regar más.',
  'Marchitez con suelo húmedo NO es falta de agua: separa pudrición de raíz de '
      'anoxia, salinidad o compactación.',
  'El nogal necesita raíz profunda: en zonas áridas vigila sales (EC) y suelo '
      'calizo; si el árbol se seca por focos, revisa raíz/corona.',
];

const List<String> _bloomActions = <String>[
  'Revisa amentos (flor macho) y flores femeninas; el centro oscuro indica '
      'daño de helada.',
  'En nogal, mucha flor o mucho polen NO asegura nuez: cruza helada, frío, '
      'viento, lluvia y sincronía floral antes de culpar al fertilizante.',
  '¿Hay otra variedad compatible (Western/Wichita) floreando cerca? La '
      'polinización cruzada por viento es clave para el amarre.',
];

const List<String> _nutActions = <String>[
  'Abre varias nueces y revisa: ¿hay perforación, frass/seda, túneles negros, '
      'larva o agujero redondo (BB)?, ¿el ruezno abre o se queda pegado?',
  'Separa caída natural y aborto de daño de barrenador de la nuez/ruezno, '
      'chinches o estrés hídrico.',
  'Guarda el evento para ajustar manejo, riego y monitoreo del siguiente ciclo.',
];

const List<String> _woodActions = <String>[
  'Si ves aserrín/frass u hoyos en tronco o ramas, revisa madera y estrés base '
      '(agua, sales) antes de tratarlo como plaga foliar.',
  'Guarda eventos de granizo, poda o herida: si el daño aparece después, sube '
      'el riesgo de cancro/decaimiento de madera.',
  'No trates el decaimiento como diagnóstico cerrado: cruza barrenador, herida, '
      'cancro, frío, sequía o exceso de agua.',
];

const List<String> _zincActions = <String>[
  'Si las hojas salen chicas, con entrenudos cortos o en roseta, en nogal se '
      'parece a deficiencia de zinc, sobre todo con pH alto/suelo calizo.',
  'No lo confundas con falta de N: con pH alto el zinc/hierro pueden estar '
      'presentes pero no disponibles. Confirma con análisis foliar.',
  'BIO-G v1 no mide zinc; úsalo como contexto y revisa historial de '
      'aspersiones foliares de zinc.',
];

const List<String> _foliarActions = <String>[
  'Revisa el envés de las hojas: pulgones amarillos/negros, mielecilla '
      'pegajosa, negrilla (fumagina) o ácaros y telaraña fina.',
  'La negrilla es consecuencia de la mielecilla: busca primero el pulgón o '
      'chupador, no lo trates como hongo principal.',
  'Si defolia durante llenado o postcosecha, guarda la memoria: baja reservas y '
      'sube la alternancia del siguiente ciclo.',
];

const List<String> _saltActions = <String>[
  'Bordes de hoja quemados pueden ser salinidad, boro/cloruros, calor o sequía, '
      'no solo falta de potasio. Revisa EC, agua, drenaje y patrón del daño.',
  'En llenado, el déficit de agua puede dejar nuez vana o almendra ligera '
      'aunque la nuez se vea formada; estabiliza riego antes de fertilizar.',
  'Si el agua/suelo tienen sales, no interpretes el NPK como si todo estuviera '
      'disponible.',
];

/// Modificador de sensibilidad por perfil NG (doc 04 §6).
VarietyModifier _ngModifier({
  required Set<String> profiles,
  required String diagnosisId,
  required int delta,
  required String rationale,
}) => VarietyModifier(
  cropId: CropCatalog.walnutTreeCropId,
  varietyIds: profiles,
  diagnosisIds: <String>{diagnosisId},
  scoreDelta: delta,
  rationaleEs: rationale,
  isProxy: true,
);

/// Catálogo de síndromes del nogal. `final` (no `const`) por los modificadores
/// por perfil NG construidos con [_ngModifier].
final List<PlantHealthSyndrome> walnutTreeSyndromes = <PlantHealthSyndrome>[
  // ── Familia 1: Raíz, cuello, suelo, salinidad y madera ────────────────────
  PlantHealthSyndrome(
    id: 'walnut_root_crown_rot_01',
    cropId: CropCatalog.walnutTreeCropId,
    labelEs: 'Decaimiento con suelo húmedo o secamiento por focos',
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
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalHighPhCalcareous,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'root_crown_rot_anoxia',
        labelEs: 'Raíz asfixiada / pudrición de raíz-cuello por exceso de agua',
        type: 'root_disease_complex',
        summaryEs:
            'Favorecida por suelo saturado, drenaje pobre, riego pesado y '
            'compactación. Marchitez con suelo húmedo, hojas amarillas, raíz '
            'oscura y respuesta pobre al fertilizante. No recomendar más riego.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWaterlogging},
      ),
      PlantHealthDiagnosis(
        id: 'phymatotrichopsis_texas_root_rot',
        labelEs: 'Pudrición texana / algodonosa de raíz',
        scientificName: 'Phymatotrichopsis omnivora',
        type: 'fungus',
        summaryEs:
            'Riesgo regional del norte árido en suelos alcalinos/calizos con '
            'historial de algodón/alfalfa/mezquite. El árbol se seca de forma '
            'repentina o por manchones, con hojas bronceadas que quedan pegadas. '
            'No es diagnóstico por sensor: revisa raíz/corona y confirma local.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHighPhCalcareous},
      ),
      PlantHealthDiagnosis(
        id: 'soil_compaction_salinity_root_stress',
        labelEs: 'Compactación / salinidad / raíz limitada',
        type: 'abiotic_soil',
        summaryEs:
            'Resistencia alta, sales (EC) y poca aireación reducen raíz fina y '
            'absorción. Antes de asumir falta de fertilizante, revisa '
            'compactación, drenaje y CE.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirma si la marchitez ocurre con suelo húmedo (no seco).',
      'Revisa drenaje, compactación, CE y zonas bajas/salinas del huerto.',
      '¿El secamiento aparece por focos en verano y el suelo es calizo? Considera '
          'pudrición texana y confirma con sanidad local.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── Familia 2: Dormancia, helada, floración y polinización ────────────────
  PlantHealthSyndrome(
    id: 'walnut_frost_pollination_01',
    cropId: CropCatalog.walnutTreeCropId,
    labelEs: 'Floreó pero amarró poco, o flores dañadas tras frío/mal clima',
    stages: _bloomStages,
    organIds: <String>{PlantHealthIds.organFlower},
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalFrostEvent,
      PlantHealthIds.signalNoPollinatorNearby,
    },
    weakSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalInsufficientChill,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'frost_budbreak_flowering_damage',
        labelEs: 'Daño por helada en brotación/floración',
        type: 'abiotic_cold',
        summaryEs:
            'Heladas tardías en yema, flor femenina o nuez recién amarrada '
            'bajan la carga. Si hubo helada, la pérdida puede venir del clima, '
            'no de la fertilización; puede dejar exceso de vigor por baja carga.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrostEvent},
      ),
      PlantHealthDiagnosis(
        id: 'floral_dichogamy_mismatch',
        labelEs: 'Desincronía floral / falta de polinizador compatible',
        type: 'abiotic_physiological',
        summaryEs:
            'El nogal es dicógamo (Tipo I/protandro vs Tipo II/protógino) y se '
            'poliniza por viento. Muchos amentos/polen con poca nuez sugieren '
            'desfase o falta de variedad compatible cercana (Western/Wichita). '
            'En SKIP, alerta conservadora sin pedir seleccionar polinizador.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNoPollinatorNearby,
        },
      ),
      PlantHealthDiagnosis(
        id: 'insufficient_chill_irregular_budbreak',
        labelEs: 'Frío insuficiente / brotación-floración dispareja',
        type: 'abiotic_physiological',
        summaryEs:
            'Inviernos cálidos o erráticos dan brotación/floración dispareja y '
            'baja sincronía. Es contexto climático (no sensor v1): no leer la '
            'baja carga como falla de NPK.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa el centro de la flor femenina: oscuro indica daño de helada.',
      '¿Hubo helada, frío, viento fuerte o lluvia durante la floración?',
      '¿Hay otra variedad compatible floreando cerca para polinizar?',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _bloomActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _ngModifier(
        profiles: <String>{kNg05TempranoPawneeKanza},
        diagnosisId: 'frost_budbreak_flowering_damage',
        delta: 10,
        rationale:
            'Los tempranos (Pawnee/Cheyenne) brotan/florean antes: una helada '
            'tardía pesa más (doc 04 §6).',
      ),
    ],
  ),

  // ── Familia 3: Zinc / roseta / clorosis (nutricional) ─────────────────────
  PlantHealthSyndrome(
    id: 'walnut_zinc_rosette_01',
    cropId: CropCatalog.walnutTreeCropId,
    labelEs: 'Hojas chicas, entrenudos cortos o brotes en roseta',
    stages: _zincStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomRosetteLittleLeaf,
    strongSignals: <String>{PlantHealthIds.signalHighPhCalcareous},
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'zinc_deficiency_rosette_little_leaf',
        labelEs: 'Deficiencia de zinc / roseta / hoja chica',
        type: 'abiotic_nutritional',
        summaryEs:
            'Riesgo central del nogal pecanero, sobre todo en suelos alcalinos/'
            'calizos del norte. Entrenudos cortos, hojas pequeñas/onduladas, '
            'brotes en roseta y bajo crecimiento. Con pH alto y hoja chica, '
            'no diagnostiques falta de N: revisa zinc y confirma con foliar.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHighPhCalcareous},
      ),
      PlantHealthDiagnosis(
        id: 'iron_manganese_chlorosis_high_ph',
        labelEs: 'Clorosis férrica/Mn por pH alto',
        type: 'abiotic_nutritional',
        summaryEs:
            'Hojas nuevas amarillas con nervaduras verdes en suelo calcáreo o '
            'pH alto: el hierro/manganeso puede estar en el suelo pero no '
            'disponible. Confirmar con análisis antes de corregir; no es N.',
      ),
      PlantHealthDiagnosis(
        id: 'nickel_deficiency_mouse_ear',
        labelEs: 'Deficiencia de níquel / "oreja de ratón"',
        type: 'abiotic_nutritional',
        summaryEs:
            'Hojas pequeñas y redondeadas tipo oreja de ratón, brotación lenta '
            'y madera quebradiza. Riesgo avanzado/diferencial si la hoja chica '
            'no cuadra con zinc; confirmar con observación/análisis.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las hojas salen chicas con entrenudos cortos o en roseta?',
      'Confirma si el suelo es de pH alto o calcáreo.',
      'Conviene análisis foliar e historial de aspersiones de zinc.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _zincActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _ngModifier(
        profiles: <String>{kNg02Wichita},
        diagnosisId: 'zinc_deficiency_rosette_little_leaf',
        delta: 10,
        rationale:
            'Wichita es más sensible a deficiencia de zinc que Western (doc 04 §6).',
      ),
      _ngModifier(
        profiles: <String>{kNg05TempranoPawneeKanza},
        diagnosisId: 'zinc_deficiency_rosette_little_leaf',
        delta: 6,
        rationale:
            'Pawnee y tempranos exigen hoja funcional temprano: el zinc pesa más '
            'en el arranque (doc 04 §6).',
      ),
    ],
  ),

  // ── Familia 4: Pulgones, melaza, fumagina y ácaros (hoja funcional) ───────
  PlantHealthSyndrome(
    id: 'walnut_aphids_mites_01',
    cropId: CropCatalog.walnutTreeCropId,
    labelEs: 'Hoja pegajosa, negrilla, puntos amarillos/cafés o bronceado',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomHoneydewSootyShoots,
    strongSignals: <String>{
      PlantHealthIds.signalYellowAphids,
      PlantHealthIds.signalBlackPecanAphids,
      PlantHealthIds.signalStickyHoneydew,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSootyMold,
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalHeatStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'yellow_aphid_complex',
        labelEs: 'Complejo de pulgones amarillos',
        scientificName: 'Monellia caryella / Monelliopsis pecanis',
        type: 'insect',
        summaryEs:
            'Pulgones amarillos en el envés con mielecilla pegajosa y negrilla '
            '(fumagina) que baja la fotosíntesis. Si el usuario dice "hoja '
            'pegajosa" o "mielecilla", busca pulgón antes que hongo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalYellowAphids},
      ),
      PlantHealthDiagnosis(
        id: 'black_pecan_aphid',
        labelEs: 'Pulgón negro del nogal',
        scientificName: 'Melanocallis caryaefoliae',
        type: 'insect',
        summaryEs:
            'Pocas colonias bastan para causar puntos amarillos que se vuelven '
            'cafés/necróticos y defoliación. Si defolia antes de cargar '
            'reservas, pega fuerte en el ciclo siguiente (alternancia).',
        confirmatorySignalIds: <String>{PlantHealthIds.signalBlackPecanAphids},
      ),
      PlantHealthDiagnosis(
        id: 'pecan_leaf_scorch_mite_spider_mites',
        labelEs: 'Ácaro del quemado / araña roja',
        type: 'mite',
        summaryEs:
            'Con calor, baja humedad y polvo, bronceado/quemado en el envés y '
            'defoliación tardía. Revisa el envés; no asumas solo sequía o sales.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalMitesWebbing},
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa el envés: pulgones amarillos/negros, mielecilla, negrilla o ácaros.',
      'La negrilla crece sobre la mielecilla: busca primero el chupador.',
      'Cruza con calor/humedad baja para distinguir ácaros de pulgón.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[..._foliarActions, ..._baseActions],
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 5: Plagas directas de nuez y ruezno ───────────────────────────
  PlantHealthSyndrome(
    id: 'walnut_nut_shuck_pests_01',
    cropId: CropCatalog.walnutTreeCropId,
    labelEs: 'Nuez perforada con frass, ruezno con túneles o pegado',
    stages: _nutStages,
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomNutShuckTunnels,
    strongSignals: <String>{
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalShuckStuck,
      PlantHealthIds.signalRoundBbExitHole,
    },
    weakSignals: <String>{PlantHealthIds.signalActiveChewing},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pecan_nut_casebearer',
        labelEs: 'Gusano barrenador de la nuez / pecan nut casebearer',
        scientificName: 'Acrobasis nuxvorella',
        type: 'insect',
        summaryEs:
            'En nuez recién amarrada, racimos con nueces pequeñas perforadas, '
            'seda/frass y caída temprana. Si la nuez chica cae con perforación, '
            'prioriza barrenador antes que aborto por NPK.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrassPresent},
      ),
      PlantHealthDiagnosis(
        id: 'hickory_shuckworm',
        labelEs: 'Gusano barrenador del ruezno / hickory shuckworm',
        scientificName: 'Cydia caryana',
        type: 'insect',
        summaryEs:
            'Galerías y túneles negros en el ruezno; ruezno pegado a la cáscara, '
            'mala apertura, sticktights y baja calidad en llenado/madurez. Si el '
            'ruezno no abre con túneles negros, revisa shuckworm.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalShuckStuck},
      ),
      PlantHealthDiagnosis(
        id: 'pecan_weevil_regional',
        labelEs: 'Picudo / barrenador de la nuez (pecan weevil)',
        scientificName: 'Curculio caryae',
        type: 'insect',
        summaryEs:
            'Plaga regional/regulatoria: caída en estado acuoso por picaduras, '
            'larva blanca dentro de la nuez y agujero redondo (BB) en la '
            'cáscara. No activar como universal sin contexto; conserva muestra/'
            'foto y consulta sanidad local.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRoundBbExitHole},
      ),
    ],
    confirmationChecksEs: <String>[
      'Abre varias nueces: ¿hay frass/seda, túneles negros, larva o agujero BB?',
      '¿El ruezno abre normal o se queda pegado con galerías?',
      'Conserva muestra/foto si sospechas picudo y consulta sanidad local.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _nutActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),

  // ── Familia 5b: Chinches / mancha de almendra ─────────────────────────────
  PlantHealthSyndrome(
    id: 'walnut_kernel_spot_01',
    cropId: CropCatalog.walnutTreeCropId,
    labelEs: 'Almendra con manchas negras o mal sabor',
    stages: _nutStages,
    organIds: <String>{PlantHealthIds.organFruit, PlantHealthIds.organGrain},
    primarySymptomId: PlantHealthIds.symptomKernelDarkSpots,
    strongSignals: <String>{PlantHealthIds.signalWeedCompetition},
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'stink_bug_leaf_footed_bug_kernel_spot',
        labelEs: 'Chinches / leaf-footed bugs / mancha amarga de almendra',
        type: 'insect',
        summaryEs:
            'En llenado a madurez, puntos/manchas negras en la almendra y sabor '
            'amargo/rancio, con daño más fuerte en bordes con maleza o cultivos '
            'vecinos. Si la almendra sale manchada sin pudrición externa clara, '
            'sube el riesgo de chinche.',
      ),
      PlantHealthDiagnosis(
        id: 'kernel_discoloration_complex',
        labelEs: 'Manchado / oscurecimiento de almendra',
        type: 'complex',
        summaryEs:
            'Puede venir de chinches, shuckworm, hongos, estrés hídrico, retraso '
            'de cosecha o mal almacenamiento. No diagnostiques una sola causa '
            'sin abrir la nuez y revisar ruezno, perforaciones y humedad.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La almendra tiene puntos negros o mal sabor sin pudrición externa clara?',
      'Revisa bordes con maleza o cultivos vecinos cosechados.',
      'Cruza con humedad, retraso de cosecha y daño de ruezno.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _nutActions,
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 6: Decaimiento / pudrición de ruezno ──────────────────────────
  PlantHealthSyndrome(
    id: 'walnut_shuck_decline_01',
    cropId: CropCatalog.walnutTreeCropId,
    labelEs: 'Ruezno que se ennegrece, muere o no llena la almendra',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomShuckDiebackBlackening,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalDryHotWindow,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'crop_overload_shuck_decline',
        labelEs: 'Sobrecarga / decaimiento de ruezno por estrés',
        type: 'abiotic_physiological',
        summaryEs:
            'Carga muy alta con agua/hoja limitadas: ruezno que se oscurece, '
            'nuez vana y almendra mal llena, con alternancia el año siguiente. '
            'Trátalo como estrés-carga-ruezno, no siempre hongo primario. Guarda '
            'carga alta/agua baja.',
      ),
      PlantHealthDiagnosis(
        id: 'phytophthora_stem_end_shuck_rot',
        labelEs: 'Pudrición de ruezno/almendra (Phytophthora / stem-end)',
        type: 'oomycete_fungal_complex',
        summaryEs:
            'Con humedad alta y ruezno negro húmedo/blando, pudrición que puede '
            'iniciar en base o punta y dejar la almendra inservible. Diferénciala '
            'del estrés seco y del shuckworm.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'water_stress_light_kernel',
        labelEs: 'Estrés hídrico en llenado / almendra ligera o vana',
        type: 'abiotic_physiological',
        summaryEs:
            'El 85% del peso seco de la nuez se acumula al final del ciclo: el '
            'déficit de agua en llenado deja almendra arrugada/ligera o nuez '
            'vana aunque la nuez se vea formada. Estabiliza riego antes que NPK.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El ruezno se oscurece desde la punta (carga/estrés) o está negro húmedo '
          '(posible pudrición)?',
      'Revisa carga de nuez, agua, hoja funcional y calibre de almendra.',
      'Guarda el evento: en nogal la sobrecarga dispara alternancia.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _nutActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _ngModifier(
        profiles: <String>{kNg02Wichita},
        diagnosisId: 'crop_overload_shuck_decline',
        delta: 8,
        rationale:
            'Wichita es prolífica y propensa a sobrecarga/shuck decline bajo '
            'calor (doc 04 §6).',
      ),
    ],
  ),

  // ── Familia 7: Estrés salino / quemado de borde y agua ────────────────────
  PlantHealthSyndrome(
    id: 'walnut_salinity_leaf_burn_01',
    cropId: CropCatalog.walnutTreeCropId,
    labelEs: 'Bordes de hoja quemados o nuez chica con suelo regado',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organWholePlant},
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{PlantHealthIds.signalSalinityLoad},
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHighPhCalcareous,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'salinity_marginal_leaf_burn',
        labelEs: 'Quemado marginal por salinidad / sales',
        type: 'abiotic_soil',
        summaryEs:
            'Muy importante en el norte árido: EC alta, agua salina o drenaje '
            'pobre queman el borde de la hoja, bajan vigor y dejan nuez chica, '
            'pareciendo sequía aunque se riegue. Si EC alta, no asumas falta de N.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'boron_chloride_toxicity',
        labelEs: 'Toxicidad por boro/cloruros (contexto)',
        type: 'abiotic_soil',
        summaryEs:
            'Agua con boro/cloruros y mal drenaje dan quemado marginal parecido '
            'a salinidad. Pide análisis de agua/suelo; no corrijas con más '
            'fertilizante.',
      ),
      PlantHealthDiagnosis(
        id: 'drought_stress_kernel_fill',
        labelEs: 'Estrés hídrico en etapa sensible',
        type: 'abiotic_physiological',
        summaryEs:
            'Déficit de agua con calor en amarre/llenado: caída de nuez, mala '
            'almendra y más daño por calor/salinidad. Estabiliza riego antes de '
            'interpretar el NPK.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El borde quemado aparece aunque el suelo esté regado? Revisa EC/sales.',
      'Cruza con pH alto, drenaje, boro/cloruros y patrón del daño.',
      'En llenado, el déficit de agua deja nuez vana o almendra ligera.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _saltActions,
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 8: Madera, barrenadores de tronco y cancros ───────────────────
  PlantHealthSyndrome(
    id: 'walnut_trunk_borer_decline_01',
    cropId: CropCatalog.walnutTreeCropId,
    labelEs: 'Aserrín u hoyos en tronco/ramas, o ramas que se secan',
    stages: _woodStages,
    organIds: <String>{PlantHealthIds.organStem, PlantHealthIds.organCrown},
    primarySymptomId: PlantHealthIds.symptomShootDecayCanker,
    strongSignals: <String>{
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalRecentStress,
    },
    weakSignals: <String>{PlantHealthIds.signalHailEvent},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'trunk_borer_ambrosia_complex',
        labelEs: 'Barrenador de tronco/ramas / ambrosial',
        type: 'insect',
        summaryEs:
            'Árboles estresados o ramas debilitadas: hoyos pequeños redondos, '
            'aserrín/frass, escurrimiento en corteza y ramas que mueren. Si hay '
            'frass/hoyos, revisa madera y estrés base, no la trates como plaga '
            'foliar.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrassPresent},
      ),
      PlantHealthDiagnosis(
        id: 'wood_canker_decline_complex',
        labelEs: 'Cancros y decaimiento de madera',
        type: 'canker_complex',
        summaryEs:
            'Heridas de poda, granizo, heladas o estrés dan corteza hundida, '
            'grietas, exudados y muerte regresiva. Guarda el evento de herida/'
            'granizo: si el daño aparece después, sube el riesgo.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay aserrín/frass u hoyos en tronco o ramas? → barrenador.',
      '¿Hay corteza hundida, grietas o muerte regresiva tras herida/poda? → cancro.',
      'Revisa el estrés base del árbol (agua, sales, compactación).',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _woodActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _ngModifier(
        profiles: <String>{kNg04CriolloRegional},
        diagnosisId: 'trunk_borer_ambrosia_complex',
        delta: 6,
        rationale:
            'Huertos viejos/criollos con árboles altos y manejo irregular suben '
            'el riesgo de barrenadores y decaimiento de madera (doc 04 §6).',
      ),
    ],
  ),

  // ── Familia 9: Caída prematura de nuez (fisiológica vs plaga) ─────────────
  PlantHealthSyndrome(
    id: 'walnut_premature_nut_drop_01',
    cropId: CropCatalog.walnutTreeCropId,
    labelEs: 'Caída de nuez recién amarrada o en oleadas',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
    },
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomPrematureNutDrop,
    strongSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalFrassPresent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalNoPollinatorNearby,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'premature_nut_drop_physiological',
        labelEs: 'Caída fisiológica / aborto de nuez',
        type: 'abiotic_physiological',
        summaryEs:
            'Aborto natural, mala polinización, estrés hídrico, calor, salinidad '
            'o carga excesiva tiran nuez recién amarrada en oleadas. Pregunta '
            'cuándo cae y si hay perforación/frass antes de diagnosticar.',
      ),
      PlantHealthDiagnosis(
        id: 'pecan_nut_casebearer_early',
        labelEs: 'Barrenador de la nuez (caída con perforación)',
        scientificName: 'Acrobasis nuxvorella',
        type: 'insect',
        summaryEs:
            'Si la nuez chica cae con perforación, seda o frass en el racimo, la '
            'causa probable es el barrenador de la nuez, no solo aborto por NPK.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrassPresent},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La nuez caída tiene perforación, seda o frass? → barrenador.',
      '¿Hubo helada, calor, sequía, salinidad o falta de polinizador? → fisiológica.',
      'Registra el evento para revisar carga, agua y alternancia.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _nutActions,
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 10: Defoliación temprana / postcosecha débil / alternancia ────
  // Memoria multianual (doc 04 §13): la postcosecha NO cierra el cultivo. La
  // pérdida temprana de hoja (pulgón negro/ácaros/enfermedad) baja reservas y
  // dispara alternancia el ciclo siguiente. Vive en lateSeason (post_harvest/
  // dormancia) y también en llenado, donde la defoliación ya pesa.
  PlantHealthSyndrome(
    id: 'walnut_defoliation_alternance_01',
    cropId: CropCatalog.walnutTreeCropId,
    labelEs: 'Defoliación temprana o postcosecha débil (riesgo de alternancia)',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomLateDefoliation,
    strongSignals: <String>{
      PlantHealthIds.signalBlackPecanAphids,
      PlantHealthIds.signalRecentStress,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'post_harvest_leaf_loss_memory',
        labelEs: 'Pérdida temprana de hoja / postcosecha débil',
        type: 'abiotic_physiological',
        summaryEs:
            'La hoja después de cosecha sigue cargando reservas para la '
            'siguiente brotación. Si pulgón negro, ácaros o enfermedad defolian '
            'temprano, el nogal entra al invierno con pocas reservas. La '
            'postcosecha NO cierra el cultivo: cuídala.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalBlackPecanAphids},
      ),
      PlantHealthDiagnosis(
        id: 'alternate_bearing_memory',
        labelEs: 'Alternancia productiva (memoria del ciclo)',
        type: 'abiotic_physiological',
        summaryEs:
            'Un año de carga muy alta, estrés en llenado, defoliación o mala '
            'postcosecha puede bajar la carga del siguiente año. No trates cada '
            'ciclo como independiente: guarda el historial y maneja carga, agua '
            'y reservas.',
      ),
      PlantHealthDiagnosis(
        id: 'low_reserve_next_cycle_risk',
        labelEs: 'Reservas bajas para el siguiente arranque',
        type: 'abiotic_physiological',
        summaryEs:
            'Defoliación, sequía o sobrecarga dejan al árbol con pocas reservas '
            'para brotación y amarre del próximo ciclo. BIO-G baja la confianza '
            'del siguiente arranque y sugiere observar.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El árbol perdió hoja antes de tiempo (pulgón negro, ácaros, enfermedad)?',
      '¿Cargó mucho este año? Puede venir un año bajo por alternancia.',
      'Registra el evento: en nogal la postcosecha y la carga marcan el ciclo '
          'siguiente.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: _foliarActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
];
