import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo de riesgos / sanidad vegetal del Pistache (`crop_pistachio_tree`).
///
/// Alimentado por el documento oficial
/// `04_Riesgos_Cultivo_Sanidad_Estres_Memoria_BioG_Pistache_v1`.
///
/// Reglas no negociables:
/// - BIO-G ORIENTA, no diagnostica de forma absoluta: "condición favorable a…",
///   "revisa…", "síntomas compatibles con…", "confirma si avanza…".
/// - NO receta plaguicidas ni ingredientes activos (doc 04 §0).
/// - El perfil PS solo modifica sensibilidad/mensajes (varietyModifiers); el
///   catálogo base es el mismo para todas las variedades.
/// - Árbol perenne DIOICO con MEMORIA fuerte: frío insuficiente, helada/lluvia
///   en flor, falta de macho compatible, estrés hídrico en llenado, navel
///   orangeworm/mummies y mala postcosecha pesan en el ciclo siguiente
///   (alternancia) (doc 04 §9).
///
/// Diferencias clave vs nogal (doc 04 §0): el pistache es DIOICO (macho/hembra
/// separados) y se poliniza por viento, tolera salinidad relativa pero NO mal
/// drenaje, y su valor comercial depende de % de abiertos / vanos (blanks) /
/// cerrados / manchado. Riesgos centrales propios: falta/desfase de macho, frío
/// insuficiente, blanks/non-split, navel orangeworm, early split + aflatoxina,
/// Botryosphaeria/Alternaria. NO se reusa el catálogo del nogal (doc 04 §0).

const Set<PlantHealthStageBucket> _establishmentStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
    };

// Incluye `lateSeason` a propósito: en pistache chupadores, ácaros y
// deficiencias siguen pesando en postcosecha/dormancia —etapas que el adapter
// mapea a lateSeason— para que post_harvest NO quede como etapa apagada
// (reservas y alternancia; doc 04 §7, §9).
const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.lateSeason,
};

// Zinc/Cu/Fe / hoja chica: brotación y crecimiento vegetativo/juvenil
// (doc 04 §6, doc 05 §8.5).
const Set<PlantHealthStageBucket> _micronutrientStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
    };

// Floración macho/hembra y cuajado (doc 04 §3).
const Set<PlantHealthStageBucket> _bloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

// Fruto/kernel/hull: amarre, llenado, madurez y postcosecha (doc 04 §4, §5, §9).
const Set<PlantHealthStageBucket> _nutStages = <PlantHealthStageBucket>{
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
  'Cruza el síntoma con etapa, clima reciente (frío, helada, lluvia, viento, '
      'calor) y manejo antes de asumir una sola causa.',
  'Registra fotos, etapa visible y condiciones: en pistache la memoria del '
      'ciclo pesa fuerte para el siguiente (alternancia).',
];

const List<String> _rootActions = <String>[
  'Revisa cuello, raíces y drenaje antes de regar más.',
  'Marchitez con suelo húmedo NO es falta de agua: separa pudrición de raíz/'
      'asfixia de salinidad o compactación. El pistache no tolera mal drenaje.',
  'El pistache aguanta sales mejor que otros frutales, pero EC alta sigue '
      'siendo estrés: revisa CE, agua de riego y lavado, no lo celebres.',
];

const List<String> _bloomActions = <String>[
  'El pistache es dioico: revisa si hay árbol macho compatible floreando cerca '
      'y si coincide con la flor hembra receptiva. El polen viaja por viento.',
  'Mucha flor NO asegura cosecha: cruza helada, frío insuficiente, lluvia, alta '
      'humedad y viento antes de culpar al fertilizante.',
  'Si no sabes si tienes macho y hembra, BIO-G baja la confianza del cuajado: '
      'no promete cosecha sin polinizador.',
];

const List<String> _nutActions = <String>[
  'Abre varios pistaches y revisa: ¿hay gusano/larva, frass, telaraña, túneles, '
      'kernel manchado, vano (blank) o cerrado que no abre?',
  'Separa caída natural y blanks de polinización/frío del daño de insecto '
      '(navel orangeworm, chinches) o de estrés hídrico/salinidad.',
  'Guarda el evento para ajustar manejo, riego, saneamiento de momias y '
      'monitoreo del siguiente ciclo.',
];

const List<String> _micronutrientActions = <String>[
  'Si las hojas salen chicas, con entrenudos cortos o clorosis internerval, en '
      'pistache se parece a zinc/hierro/cobre, sobre todo con pH alto o caliza.',
  'No lo confundas con falta de N: con pH alto el micronutriente puede estar '
      'presente pero no disponible. Confirma con análisis foliar.',
  'BIO-G v1 no mide zinc/boro/hierro; úsalos como contexto y revisa historial '
      'de aspersiones foliares.',
];

const List<String> _foliarActions = <String>[
  'Revisa el envés de las hojas: chupadores (cotton aphid, Gill\'s mealybug, '
      'escamas), mielecilla pegajosa, negrilla (fumagina) o ácaros y telaraña.',
  'La negrilla es consecuencia de la mielecilla: busca primero el chupador, no '
      'la trates como hongo principal.',
  'Si defolia durante llenado o postcosecha, guarda la memoria: baja reservas y '
      'sube la alternancia del siguiente ciclo.',
];

const List<String> _saltActions = <String>[
  'Bordes de hoja quemados pueden ser salinidad, boro/cloruros/sodio, calor o '
      'sequía, no solo falta de potasio. Revisa EC, agua de pozo, drenaje y '
      'patrón del daño.',
  'En llenado, el déficit de agua deja kernel pobre, vano o cerrado aunque el '
      'pistache se vea formado; estabiliza riego antes de fertilizar.',
  'El pistache tolera sales relativo, pero EC alta + humedad baja = sequía '
      'fisiológica aunque se riegue.',
];

const List<String> _diseaseActions = <String>[
  'Separa Botryosphaeria (lesiones negras en panícula/brote/fruto con momias '
      'que quedan en árbol) de Alternaria (manchas en hoja/fruto con clima '
      'húmedo): no asumas una sola enfermedad.',
  'El mojado prolongado de primavera/verano y el dosel cerrado favorecen estos '
      'hongos: cruza humedad, lluvia y ventilación antes de tratar.',
  'Guarda el evento de clima húmedo y la presencia de momias: el inóculo del '
      'año pasa al siguiente ciclo.',
];

/// Modificador de sensibilidad por perfil PS (doc 04 §6, doc 05 §13).
VarietyModifier _psModifier({
  required Set<String> profiles,
  required String diagnosisId,
  required int delta,
  required String rationale,
}) => VarietyModifier(
  cropId: CropCatalog.pistachioTreeCropId,
  varietyIds: profiles,
  diagnosisIds: <String>{diagnosisId},
  scoreDelta: delta,
  rationaleEs: rationale,
  isProxy: true,
);

/// Catálogo de síndromes del pistache. `final` (no `const`) por los
/// modificadores por perfil PS construidos con [_psModifier].
final List<PlantHealthSyndrome> pistachioTreeSyndromes = <PlantHealthSyndrome>[
  // ── Familia 1: Raíz, cuello, suelo, salinidad y madera ────────────────────
  PlantHealthSyndrome(
    id: 'pistachio_root_crown_rot_01',
    cropId: CropCatalog.pistachioTreeCropId,
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
      PlantHealthIds.signalSalinityLoad,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'phytophthora_root_crown_rot_anoxia',
        labelEs: 'Phytophthora / raíz asfixiada por exceso de agua',
        scientificName: 'Phytophthora spp.',
        type: 'oomycete_soil_complex',
        summaryEs:
            'El pistache NO tolera mal drenaje: suelo saturado, riego pesado o '
            'arcilla >35% dan asfixia radicular y pudrición de cuello. '
            'Marchitez con suelo húmedo y respuesta pobre al fertilizante. No '
            'recomendar más riego: revisa drenaje y aireación.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWaterlogging},
      ),
      PlantHealthDiagnosis(
        id: 'verticillium_wilt_pistachio',
        labelEs: 'Verticillium / marchitez vascular',
        scientificName: 'Verticillium dahliae',
        type: 'fungus',
        summaryEs:
            'Riesgo en suelos con historial de hortícolas/algodón susceptibles. '
            'Marchitez por sectores, ramas que mueren de un lado y pardeamiento '
            'vascular. No es diagnóstico por sensor: revisa raíz/madera y '
            'confirma con sanidad local; el portainjerto influye.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRootsDarkRot},
      ),
      PlantHealthDiagnosis(
        id: 'soil_compaction_salinity_root_stress',
        labelEs: 'Compactación / salinidad / raíz limitada',
        type: 'abiotic_soil',
        summaryEs:
            'Resistencia alta, sales (EC) y poca aireación reducen raíz fina y '
            'absorción. El pistache tolera sales relativo, pero EC alta sigue '
            'estresando. Antes de asumir falta de fertilizante, revisa '
            'compactación, drenaje y CE.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirma si la marchitez ocurre con suelo húmedo (no seco).',
      'Revisa drenaje, compactación, CE y zonas bajas/salinas del huerto.',
      '¿Hay arcilla pesada (>35%) o mal drenaje? El pistache lo paga rápido.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── Familia 2: Frío, dormancia, helada, floración macho/hembra ────────────
  PlantHealthSyndrome(
    id: 'pistachio_chill_frost_pollination_01',
    cropId: CropCatalog.pistachioTreeCropId,
    labelEs: 'Floreó pero amarró poco, o flor dañada tras frío/mal clima',
    stages: _bloomStages,
    organIds: <String>{PlantHealthIds.organFlower},
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalNoPollinatorNearby,
      PlantHealthIds.signalFrostEvent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalInsufficientChill,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'missing_or_mismatched_male_pollination',
        labelEs: 'Falta de macho compatible / desincronía de polinización',
        type: 'abiotic_physiological',
        summaryEs:
            'El pistache es dioico y se poliniza por viento: la hembra solo '
            'cuaja si hay árbol macho compatible (Peters para Kerman; Randy '
            'para Golden/Lost Hills) floreando al mismo tiempo. Mucha flor con '
            'poca nuez sugiere falta/desfase de macho, poco viento o lluvia en '
            'floración. En SKIP, alerta conservadora sin pedir el macho exacto.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNoPollinatorNearby,
        },
      ),
      PlantHealthDiagnosis(
        id: 'frost_budbreak_flowering_damage',
        labelEs: 'Daño por helada en brotación/floración',
        type: 'abiotic_cold',
        summaryEs:
            'Heladas tardías en yema o flor bajan la carga. Si hubo helada, la '
            'pérdida puede venir del clima, no de la fertilización; puede dejar '
            'exceso de vigor por baja carga.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrostEvent},
      ),
      PlantHealthDiagnosis(
        id: 'insufficient_chill_irregular_bloom',
        labelEs: 'Frío insuficiente / brotación-floración dispareja',
        type: 'abiotic_physiological',
        summaryEs:
            'Inviernos cálidos o erráticos dan brotación/floración extendida y '
            'baja sincronía macho-hembra, con nutlet drop y nueces vacías. Es '
            'contexto climático (no sensor v1): no leer la baja carga como '
            'falla de NPK. "Bajo-frío relativo" NO es sin frío.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalInsufficientChill},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Tienes árboles macho y hembra? ¿Coincidió la floración?',
      '¿Hubo helada, frío insuficiente, lluvia o viento fuerte durante la flor?',
      '¿La variedad es de alto frío (Kerman) en una zona de invierno cálido?',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _bloomActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _psModifier(
        profiles: <String>{kPs01KermanPeters},
        diagnosisId: 'insufficient_chill_irregular_bloom',
        delta: 10,
        rationale:
            'Kerman exige alto frío y depende de sincronía con Peters: el frío '
            'insuficiente pega más (doc 04 §3, doc 05 §13.2).',
      ),
      _psModifier(
        profiles: <String>{kPs05LarnakaMateurLowChill},
        diagnosisId: 'frost_budbreak_flowering_damage',
        delta: 10,
        rationale:
            'Los mediterráneos bajo-frío brotan/florean antes: una helada '
            'tardía pesa más (doc 04 §3, doc 05 §13.6).',
      ),
    ],
  ),

  // ── Familia 3: Zinc / Fe / Cu / clorosis (micronutrientes) ────────────────
  PlantHealthSyndrome(
    id: 'pistachio_micronutrient_chlorosis_01',
    cropId: CropCatalog.pistachioTreeCropId,
    labelEs: 'Hojas chicas, entrenudos cortos o clorosis con nervaduras verdes',
    stages: _micronutrientStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomRosetteLittleLeaf,
    strongSignals: <String>{PlantHealthIds.signalHighPhCalcareous},
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'zinc_copper_deficiency_high_ph',
        labelEs: 'Deficiencia de zinc/cobre por pH alto / suelo calizo',
        type: 'abiotic_nutritional',
        summaryEs:
            'En suelos alcalinos/calizos, sobre todo en pistache joven, el zinc '
            'y el cobre se fijan: hojas pequeñas, entrenudos cortos y brotes '
            'débiles. Con pH alto y hoja chica, no diagnostiques falta de N: '
            'revisa zinc/cobre y confirma con foliar. El foliar temprano suele '
            'ser más útil que el suelo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHighPhCalcareous},
      ),
      PlantHealthDiagnosis(
        id: 'iron_chlorosis_high_ph',
        labelEs: 'Clorosis férrica por pH alto / caliza',
        type: 'abiotic_nutritional',
        summaryEs:
            'Hojas nuevas amarillas con nervaduras verdes en suelo calcáreo o '
            'pH alto: el hierro puede estar en el suelo pero no disponible. '
            'Influye en el peso final del kernel. Confirmar con análisis antes '
            'de corregir; no es N.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las hojas salen chicas con entrenudos cortos, o amarillas con '
          'nervaduras verdes?',
      'Confirma si el suelo es de pH alto o calcáreo.',
      'Conviene análisis foliar e historial de aspersiones de zinc/hierro.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _micronutrientActions,
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 4: Cuajado, blanks, non-split y fisiología de nuez ────────────
  PlantHealthSyndrome(
    id: 'pistachio_blanks_nonsplit_01',
    cropId: CropCatalog.pistachioTreeCropId,
    labelEs: 'Pistache vano (blank), cerrado o que no abre',
    stages: _nutStages,
    organIds: <String>{PlantHealthIds.organFruit, PlantHealthIds.organGrain},
    primarySymptomId: PlantHealthIds.symptomBlankClosedNut,
    strongSignals: <String>{
      PlantHealthIds.signalNoPollinatorNearby,
      PlantHealthIds.signalDryHotWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalInsufficientChill,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'blank_nuts_pollination_chill',
        labelEs: 'Pistache vano (blank) por polinización/frío',
        type: 'abiotic_physiological',
        summaryEs:
            'El pistache vano/blank suele venir de mala polinización (falta/'
            'desfase de macho, poco viento, lluvia), frío insuficiente o aborto '
            'de embrión. No lo leas como falta de K sin revisar primero macho/'
            'hembra, clima y carga.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNoPollinatorNearby,
        },
      ),
      PlantHealthDiagnosis(
        id: 'closed_shell_nonsplit_fill',
        labelEs: 'Pistache cerrado / non-split por llenado o variedad',
        type: 'abiotic_physiological',
        summaryEs:
            'El cerrado/non-split depende de variedad (Kerman cierra más que '
            'Golden/Lost Hills), llenado de kernel, agua, calor y cosecha. Es '
            'tema de calidad de fruto, no una plaga: revisa agua/K en llenado y '
            'no lo trates con insecticida.',
      ),
      PlantHealthDiagnosis(
        id: 'kernel_fill_water_salinity_stress',
        labelEs: 'Kernel pobre por estrés hídrico/salino en llenado',
        type: 'abiotic_physiological',
        summaryEs:
            'El déficit de agua, EC alta o calor en llenado dejan kernel '
            'arrugado/ligero o cerrado aunque el fruto se vea formado. '
            'Estabiliza riego y revisa sales antes que NPK.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      'Abre varios pistaches: ¿están vanos (sin kernel), cerrados o llenos?',
      '¿Tienes macho compatible y coincidió la floración? ¿Hubo frío suficiente?',
      'Revisa agua, EC y carga en llenado antes de culpar al fertilizante.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _nutActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _psModifier(
        profiles: <String>{kPs01KermanPeters},
        diagnosisId: 'closed_shell_nonsplit_fill',
        delta: 8,
        rationale:
            'Kerman tiene mayor riesgo de cerrado/non-split y blanks que los '
            'cultivares modernos (doc 03 §2.1, doc 05 §13.2).',
      ),
    ],
  ),

  // ── Familia 5: Navel orangeworm, chinches y daño de kernel ────────────────
  PlantHealthSyndrome(
    id: 'pistachio_now_bug_kernel_01',
    cropId: CropCatalog.pistachioTreeCropId,
    labelEs: 'Pistache con gusano, frass, telaraña o kernel manchado',
    stages: _nutStages,
    organIds: <String>{PlantHealthIds.organFruit, PlantHealthIds.organGrain},
    primarySymptomId: PlantHealthIds.symptomNutwormMummies,
    strongSignals: <String>{
      PlantHealthIds.signalNavelOrangeworm,
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalEarlyHullSplit,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMummyNuts,
      PlantHealthIds.signalWeedCompetition,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'navel_orangeworm',
        labelEs: 'Gusano del ombligo / navel orangeworm',
        scientificName: 'Amyelois transitella',
        type: 'insect',
        summaryEs:
            'Plaga clave de calidad: larva en el kernel con frass y telaraña, '
            'ligada a early split y a momias (mummies) del ciclo anterior. El '
            'riesgo arranca con la apertura temprana del hull, no solo en '
            'cosecha. Asociada a manchado y a aflatoxina. Saneamiento de momias '
            'y cosecha a tiempo bajan la presión.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalNavelOrangeworm},
      ),
      PlantHealthDiagnosis(
        id: 'stink_leaffooted_bug_kernel_stain',
        labelEs: 'Chinches / leaf-footed bugs / mancha de kernel',
        type: 'insect',
        summaryEs:
            'En cuajado a llenado, las chinches pican el fruto y dejan '
            'epicarpo manchado, aborto o kernel manchado, con más daño en '
            'bordes con maleza o cultivos vecinos. Si el kernel sale manchado '
            'sin pudrición externa clara, sube el riesgo de chinche.',
      ),
      PlantHealthDiagnosis(
        id: 'kernel_stain_complex',
        labelEs: 'Manchado / decoloración de kernel (complejo)',
        type: 'complex',
        summaryEs:
            'Puede venir de chinches, navel orangeworm, hongos (Alternaria/'
            'Aspergillus), estrés hídrico, retraso de cosecha o mal '
            'almacenamiento. No diagnostiques una sola causa sin abrir el '
            'pistache y revisar hull, perforaciones y humedad.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Abre varios pistaches: ¿hay larva, frass, telaraña o kernel manchado?',
      '¿Hay momias (nueces viejas) en el árbol o en el suelo? Son fuente de NOW.',
      '¿El hull/cascarilla se abrió temprano? El early split abre la puerta a '
          'insectos y hongos.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _nutActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
    varietyModifiers: <VarietyModifier>[
      _psModifier(
        profiles: <String>{kPs01KermanPeters},
        diagnosisId: 'navel_orangeworm',
        delta: 6,
        rationale:
            'Kerman cosecha más tarde, con mayor exposición a navel orangeworm '
            'y mummies en preharvest (doc 03 §2.2, doc 04 §5).',
      ),
    ],
  ),

  // ── Familia 6: Botryosphaeria / Alternaria / panícula y brote ─────────────
  PlantHealthSyndrome(
    id: 'pistachio_panicle_shoot_blight_01',
    cropId: CropCatalog.pistachioTreeCropId,
    labelEs: 'Racimos, brotes o frutos con lesiones negras y momias',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    },
    organIds: <String>{
      PlantHealthIds.organFruit,
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
    },
    primarySymptomId: PlantHealthIds.symptomPanicleShootBlight,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalMummyNuts,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSpringWetFoliage,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'botryosphaeria_panicle_shoot_blight',
        labelEs: 'Botryosphaeria / tizón de panícula y brote',
        scientificName: 'Botryosphaeria dothidea',
        type: 'fungus',
        summaryEs:
            'Lesiones negras en racimos (panículas), brotes y frutos, con '
            'momias que quedan en el árbol y sirven de inóculo el año '
            'siguiente. Favorecida por humedad/lluvia y dosel cerrado. Es de '
            'las enfermedades más serias del pistache: confirma con sanidad '
            'local y maneja saneamiento de momias.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalMummyNuts},
      ),
      PlantHealthDiagnosis(
        id: 'alternaria_late_blight',
        labelEs: 'Alternaria / tizón tardío de hoja y fruto',
        scientificName: 'Alternaria alternata',
        type: 'fungus',
        summaryEs:
            'Manchas oscuras en hoja y fruto con clima húmedo, alta HR, rocío y '
            'riego excesivo; mancha el kernel y baja calidad. No la confundas '
            'con Botryosphaeria: cruza el patrón (hoja vs panícula/momia) y la '
            'humedad antes de tratar.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'botrytis_blossom_shoot_blight',
        labelEs: 'Botrytis / tizón de flor y brote (contexto húmedo frío)',
        scientificName: 'Botrytis cinerea',
        type: 'fungus',
        summaryEs:
            'Con primavera fría y húmeda, tizón de flor/brote con moho gris. '
            'Diferénciala de Botryosphaeria (más de verano/calor) y de daño '
            'de helada; pesa el clima de floración.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las lesiones negras están en racimos/brotes con momias (Botryosphaeria) '
          'o en hojas/fruto con clima húmedo (Alternaria)?',
      '¿Hubo lluvia, rocío prolongado o dosel cerrado y poco ventilado?',
      '¿Quedaron momias del año pasado? Son inóculo para el siguiente ciclo.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _diseaseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),

  // ── Familia 7: Chupadores, ácaros, melaza y defoliación ───────────────────
  PlantHealthSyndrome(
    id: 'pistachio_sucking_pests_mites_01',
    cropId: CropCatalog.pistachioTreeCropId,
    labelEs: 'Hoja pegajosa, negrilla, bronceado o defoliación',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomHoneydewSootyShoots,
    strongSignals: <String>{
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalHeatStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'gills_mealybug_soft_scale',
        labelEs: 'Gill\'s mealybug / escamas blandas',
        type: 'insect',
        summaryEs:
            'Cochinillas/escamas con mielecilla pegajosa y negrilla (fumagina) '
            'que baja la fotosíntesis; el equipo de cosecha puede dispersarlas. '
            'Si el usuario dice "hoja pegajosa", busca el chupador antes que el '
            'hongo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalStickyHoneydew},
      ),
      PlantHealthDiagnosis(
        id: 'cotton_aphid_young_trees',
        labelEs: 'Pulgón del algodón en árbol joven',
        scientificName: 'Aphis gossypii',
        type: 'insect',
        summaryEs:
            'En árboles jóvenes, colonias con mielecilla y negrilla que frenan '
            'el crecimiento. Revisa el envés; la negrilla crece sobre la '
            'mielecilla, no es el problema principal.',
      ),
      PlantHealthDiagnosis(
        id: 'flat_spider_mites_bronzing',
        labelEs: 'Citrus flat mite / araña / bronceado',
        type: 'mite',
        summaryEs:
            'Con calor, baja humedad y polvo, bronceado/raspado en el envés y '
            'defoliación tardía que baja reservas. Revisa el envés; no asumas '
            'solo sequía o sales.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalMitesWebbing},
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa el envés: cochinillas/escamas, pulgón, mielecilla, negrilla o '
          'ácaros y telaraña fina.',
      'La negrilla crece sobre la mielecilla: busca primero el chupador.',
      'Cruza con calor/humedad baja para distinguir ácaros de chupador.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[..._foliarActions, ..._baseActions],
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 8: Estrés salino / quemado de borde / agua y calidad ──────────
  PlantHealthSyndrome(
    id: 'pistachio_salinity_water_quality_01',
    cropId: CropCatalog.pistachioTreeCropId,
    labelEs: 'Bordes de hoja quemados o early split con suelo regado',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{PlantHealthIds.signalSalinityLoad},
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHighPhCalcareous,
      PlantHealthIds.signalEarlyHullSplit,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'salinity_boron_chloride_leaf_burn',
        labelEs: 'Quemado marginal por salinidad / boro / cloruros',
        type: 'abiotic_soil',
        summaryEs:
            'El pistache tolera sales relativo, pero EC alta, agua salobre o '
            'boro/cloruros/sodio queman el borde de la hoja, bajan vigor y '
            'calidad, pareciendo sequía aunque se riegue. No leas el borde '
            'quemado como K bajo: revisa EC, agua de pozo y lavado.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'early_split_aflatoxin_risk',
        labelEs: 'Early split / apertura temprana del hull (riesgo de calidad)',
        type: 'abiotic_physiological',
        summaryEs:
            'Cuando la cascarilla/hull se abre antes de tiempo en el árbol, el '
            'pistache queda expuesto a insectos (navel orangeworm), mohos y '
            'aflatoxina, con manchado. No lo confundas con la madurez normal '
            '(hull slip): el early split es un riesgo, no una señal de cosecha.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalEarlyHullSplit},
      ),
      PlantHealthDiagnosis(
        id: 'water_heat_stress_kernel',
        labelEs: 'Estrés hídrico / calor en etapa sensible',
        type: 'abiotic_physiological',
        summaryEs:
            'Déficit de agua con calor en amarre/llenado: caída de fruto, '
            'kernel pobre/cerrado y más daño por calor/salinidad. Estabiliza '
            'riego antes de interpretar el NPK; en pistache el K sin agua no '
            'llena.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El borde quemado aparece aunque el suelo esté regado? Revisa EC/sales.',
      'Cruza con pH alto, drenaje, boro/cloruros y patrón del daño.',
      '¿El hull se abrió temprano? Sube el riesgo de insecto, moho y aflatoxina.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _saltActions,
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 9: Cosecha, postcosecha, mummies, alternancia (memoria) ───────
  // Memoria multianual (doc 04 §9): la postcosecha NO cierra el cultivo. La
  // pérdida temprana de hoja, la sobrecarga, el navel orangeworm/mummies y la
  // mala postcosecha bajan reservas y disparan alternancia el ciclo siguiente.
  PlantHealthSyndrome(
    id: 'pistachio_postharvest_alternance_01',
    cropId: CropCatalog.pistachioTreeCropId,
    labelEs: 'Defoliación temprana, momias o postcosecha débil (alternancia)',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomLateDefoliation,
    strongSignals: <String>{
      PlantHealthIds.signalMummyNuts,
      PlantHealthIds.signalRecentStress,
    },
    weakSignals: <String>{
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'mummies_sanitation_now_carryover',
        labelEs: 'Momias / saneamiento para el siguiente ciclo',
        type: 'abiotic_physiological',
        summaryEs:
            'Las nueces no cosechadas (momias) en árbol y suelo son fuente de '
            'navel orangeworm y de hongos (Botryosphaeria) para el año '
            'siguiente. La postcosecha NO cierra el cultivo: el saneamiento de '
            'momias baja la presión del próximo ciclo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalMummyNuts},
      ),
      PlantHealthDiagnosis(
        id: 'post_harvest_leaf_loss_memory',
        labelEs: 'Pérdida temprana de hoja / postcosecha débil',
        type: 'abiotic_physiological',
        summaryEs:
            'La hoja después de cosecha sigue cargando reservas para la '
            'siguiente brotación. Si ácaros, defoliación o estrés tiran la hoja '
            'temprano, el pistache entra al invierno con pocas reservas. No '
            'todo huerto necesita N postcosecha: cuida hoja, agua y sanidad.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
      PlantHealthDiagnosis(
        id: 'alternate_bearing_memory',
        labelEs: 'Alternancia productiva (memoria del ciclo)',
        type: 'abiotic_physiological',
        summaryEs:
            'En pistache la alternancia es muy marcada: un año de carga muy '
            'alta, estrés en llenado o mala postcosecha baja la carga del '
            'siguiente. No trates cada ciclo como independiente: guarda el '
            'historial y maneja carga, agua y reservas. Un año bajo no siempre '
            'es enfermedad.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Quedaron momias (nueces viejas) en el árbol o suelo? Saneamiento.',
      '¿El árbol perdió hoja antes de tiempo (ácaros, estrés, enfermedad)?',
      '¿Cargó mucho este año? Puede venir un año bajo por alternancia.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: _foliarActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),
];
