import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo de riesgos / sanidad vegetal del Durazno (`crop_peach_tree`).
///
/// Alimentado por el documento oficial
/// `04_Riesgos_Cultivo_Sanidad_Estres_Memoria_BioG_Durazno_DZ_v1`.
///
/// Reglas no negociables:
/// - BIO-G ORIENTA, no diagnostica de forma absoluta: "condición favorable a…",
///   "revisa…", "síntomas compatibles con…", "confirma si avanza…".
/// - NO receta plaguicidas ni ingredientes activos.
/// - El perfil DZ solo modifica sensibilidad/mensajes (varietyModifiers); el
///   catálogo base es el mismo para todas las variedades (doc 04 §6).
/// - Árbol perenne con MEMORIA: helada en flor, brown rot, leaf curl, sequía,
///   barrenadores, granizo y mala postcosecha pesan en el ciclo siguiente.
///
/// Diferencias clave vs manzano/pera (doc 04 §0.1): durazno es frutal de
/// HUESO/carozo. Riesgos centrales propios: torque/lepra (Taphrina), pudrición
/// café (Monilinia), tiro de munición, barrenador del duraznero (goma+aserrín),
/// palomilla oriental y split pit en la subventana de endurecimiento de hueso.
/// NO se reusa fuego bacteriano/psila (eso es pepita). NO se copia el catálogo
/// de manzano ni de pera (doc 04 §1).

const Set<PlantHealthStageBucket> _establishmentStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
    };

// Incluye `lateSeason` a propósito: en durazno el tiro de munición, la mancha
// bacteriana, la roya y los ácaros siguen pesando en postcosecha/dormancia
// —etapas que el adapter mapea a lateSeason— para que post_harvest NO quede como
// etapa apagada (doc 04 §2, §7 post_harvest, §12).
const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.lateSeason,
};

// Torque/lepra (Taphrina): dormancia, brotación y primeras hojas (doc 04 §4.3).
const Set<PlantHealthStageBucket> _leafCurlStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.lateSeason,
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

// Madera/tronco/ramas: vegetativo, llenado, postcosecha y dormancia (doc 04
// §4.6 barrenadores).
const Set<PlantHealthStageBucket> _woodStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeMid,
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
  'Marchitez con suelo húmedo NO es falta de agua: separa pudrición de raíz de '
      'anoxia, salinidad o compactación.',
  'El durazno necesita buen drenaje: no tolera encharcamiento prolongado.',
];

const List<String> _bloomActions = <String>[
  'Revisa flores y frutitos recién cuajados; el centro/pistilo oscuro indica '
      'daño de helada.',
  'En durazno, flor bonita NO asegura cosecha: cruza helada, frío, lluvia y '
      'calor antes de culpar al fertilizante.',
  'Si hubo flor marchita con humedad, vigila pudrición café (Monilinia) en flor.',
];

const List<String> _fruitActions = <String>[
  'Revisa perforaciones, manchas o pudriciones en fruto y compáralas con sol, '
      'granizo, carga/raleo, calibre o balance de calcio.',
  'Protege fruta expuesta y evita heridas que abren puerta a pudriciones.',
  'Guarda el evento para ajustar manejo, raleo y cosecha del siguiente ciclo.',
];

const List<String> _woodActions = <String>[
  'Si ves goma, pregunta primero: ¿hay aserrín/frass?, ¿herida?, ¿cancro?, '
      '¿está en la base del tronco?, ¿hay rama seca?',
  'Goma con aserrín en la base del tronco apunta a barrenador, no a "gomosis" '
      'genérica: revisa cuello y tronco.',
  'No trates la goma como diagnóstico cerrado: puede venir de barrenador, '
      'herida, cancro, frío, exceso/sequía o golpe.',
];

const List<String> _leafCurlActions = <String>[
  'Si las hojas nuevas salen engrosadas, rizadas y rojizas en brotación tras '
      'clima fresco-húmedo, se parece a torque/rizo del duraznero (Taphrina).',
  'No lo confundas con falta de agua: el torque deforma hoja nueva, no marchita '
      'por sequía.',
  'La defoliación repetida por torque debilita el árbol y baja la producción: '
      'guarda la memoria del evento.',
];

/// Modificador de sensibilidad por perfil DZ (doc 04 §6).
VarietyModifier _dzModifier({
  required Set<String> profiles,
  required String diagnosisId,
  required int delta,
  required String rationale,
}) => VarietyModifier(
  cropId: CropCatalog.peachTreeCropId,
  varietyIds: profiles,
  diagnosisIds: <String>{diagnosisId},
  scoreDelta: delta,
  rationaleEs: rationale,
  isProxy: true,
);

/// Catálogo de síndromes del durazno. `final` (no `const`) por los modificadores
/// por perfil DZ construidos con [_dzModifier].
final List<PlantHealthSyndrome> peachTreeSyndromes = <PlantHealthSyndrome>[
  // ── Familia 1: Raíz, cuello, suelo y replantación ────────────────────────
  PlantHealthSyndrome(
    id: 'peach_root_crown_rot_01',
    cropId: CropCatalog.peachTreeCropId,
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
            'compactación, sobre todo en árbol joven o replante. El durazno es '
            'delicado al encharcamiento. Corona café-rojiza y raíces finas '
            'muertas. No recomendar más riego.',
      ),
      PlantHealthDiagnosis(
        id: 'peach_replant_decline',
        labelEs: 'Decaimiento por replantación',
        type: 'root_disease_complex',
        summaryEs:
            'Bajo vigor en huertos donde ya hubo durazno u otro Prunus '
            '(ciruelo, almendro, chabacano). Antes de asumir falta de '
            'fertilizante, pregunta si ya había frutal en ese sitio.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirma si la marchitez ocurre con suelo húmedo (no seco).',
      'Revisa drenaje, compactación y zonas bajas del huerto.',
      '¿Ya había durazno u otro frutal de hueso en ese sitio?',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── Familia 2: Dormancia, frío, helada y floración ───────────────────────
  PlantHealthSyndrome(
    id: 'peach_frost_bloom_01',
    cropId: CropCatalog.peachTreeCropId,
    labelEs: 'Flores cafés/negras o bajo cuajado tras frío/mal clima',
    stages: _bloomStages,
    organIds: <String>{PlantHealthIds.organFlower},
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalFrostEvent,
      PlantHealthIds.signalColdExposure,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'frost_bloom_damage',
        labelEs: 'Daño por helada en floración/cuajado',
        type: 'abiotic_cold',
        summaryEs:
            'La floración del durazno es temprana y MUY sensible a heladas '
            'tardías. Temperaturas bajo cero en botón, flor o cuajado reciente '
            'matan pistilos y bajan la carga. Si hubo helada, no culpes a la '
            'fertilización ni al agua.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrostEvent},
      ),
      PlantHealthDiagnosis(
        id: 'brown_rot_blossom_blight',
        labelEs: 'Pudrición café en flor / blossom blight (Monilinia)',
        scientificName: 'Monilinia spp.',
        type: 'fungus',
        summaryEs:
            'Flores marchitas/cafés con humedad y lluvia en floración. Deja '
            'inóculo (momias/cancros) que reaparece cerca de cosecha. Guarda la '
            'memoria del evento.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'bloom_weather_low_set',
        labelEs: 'Floración con clima desfavorable / bajo cuajado',
        type: 'abiotic_physiological',
        summaryEs:
            'Lluvia, frío, viento o calor seco en floración bajan el cuajado '
            'aunque el NPK se vea correcto. En durazno mucha flor puede terminar '
            'en poca fruta.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa el centro/pistilo de la flor: oscuro indica daño de helada.',
      '¿Hubo helada, frío o lluvia durante la floración?',
      'Si hay flor marchita con humedad, considera pudrición café en flor.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _bloomActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      _dzModifier(
        profiles: <String>{kDz02TempranoBajoFrio},
        diagnosisId: 'frost_bloom_damage',
        delta: 12,
        rationale:
            'Temprano/bajo frío adelanta la floración: una helada tardía pesa '
            'mucho más (doc 04 §6).',
      ),
    ],
  ),

  // ── Familia 3: Torque / rizo / lepra (Taphrina) ──────────────────────────
  PlantHealthSyndrome(
    id: 'peach_leaf_curl_01',
    cropId: CropCatalog.peachTreeCropId,
    labelEs: 'Hojas arrugadas, rizadas y rojizas en brotación',
    stages: _leafCurlStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomLeafCurlReddened,
    strongSignals: <String>{
      PlantHealthIds.signalSpringWetFoliage,
      PlantHealthIds.signalCoolDewyWindow,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'peach_leaf_curl_taphrina',
        labelEs: 'Torque / rizo / lepra del duraznero',
        scientificName: 'Taphrina deformans',
        type: 'fungus',
        summaryEs:
            'Riesgo central del durazno. Hojas nuevas engrosadas, rizadas y '
            'rojizas tras clima fresco-húmedo en brotación; defoliación '
            'temprana. La repetición debilita el árbol y baja la producción. Si '
            'el usuario dice "hojas arrugadas rojas" en primavera, prioriza '
            'Taphrina sobre falta de agua.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSpringWetFoliage,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El daño apareció en hojas nuevas después de clima fresco y húmedo?',
      '¿Las hojas están engrosadas/rizadas y rojizas (no solo marchitas)?',
      'Registra si se repite cada año: la defoliación baja reservas.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _leafCurlActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── Familia 3b: Tiro de munición, mancha bacteriana y roña ───────────────
  PlantHealthSyndrome(
    id: 'peach_shot_hole_bacterial_spot_01',
    cropId: CropCatalog.peachTreeCropId,
    labelEs: 'Agujeritos o manchas en hoja/fruto en clima húmedo',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomShotHoleLeafSpots,
    strongSignals: <String>{
      PlantHealthIds.signalSpringWetFoliage,
      PlantHealthIds.signalHumidWindow,
    },
    weakSignals: <String>{PlantHealthIds.signalDenseWetCanopy},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'shot_hole_coryneum',
        labelEs: 'Tiro de munición / cribado',
        scientificName: 'Wilsonomyces carpophilus',
        type: 'fungus',
        summaryEs:
            'Manchas pequeñas púrpuras/cafés en hoja que se caen y dejan '
            'agujeritos; lesiones en fruto y ramillas. Favorecido por lluvias y '
            'humedad. No confundir con daño de insecto masticador sin revisar el '
            'patrón.',
      ),
      PlantHealthDiagnosis(
        id: 'bacterial_spot_xanthomonas',
        labelEs: 'Mancha bacteriana del durazno',
        scientificName: 'Xanthomonas arboricola pv. pruni',
        type: 'bacteria',
        summaryEs:
            'Manchas angulares en hoja con amarillamiento/defoliación y manchas '
            'en fruto con grietas tras lluvia-viento. No asumas hongo de '
            'inmediato; considera bacteriosis.',
      ),
      PlantHealthDiagnosis(
        id: 'peach_scab',
        labelEs: 'Roña / pecas del durazno',
        scientificName: 'Venturia carpophila',
        type: 'fungus',
        summaryEs:
            'Manchas oscuras pequeñas en fruto, a veces agrupadas, que pueden '
            'cuartear la piel; favorecida por humedad y canopia cerrada.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa hojas jóvenes y fruta pequeña tras lluvia o mojado foliar.',
      'Diferencia agujeritos (tiro de munición) de manchas angulares con '
          'defoliación (bacteriana) y de pecas en fruto (roña).',
      'Cruza con lluvia, viento y dosel húmedo recientes.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── Familia 3c: Pudrición café / Monilinia en fruto ──────────────────────
  PlantHealthSyndrome(
    id: 'peach_brown_rot_01',
    cropId: CropCatalog.peachTreeCropId,
    labelEs: 'Pudrición café del fruto o fruto momificado',
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
        id: 'brown_rot_monilinia',
        labelEs: 'Pudrición café / morena (Monilinia)',
        scientificName: 'Monilinia fructicola',
        type: 'fungus',
        summaryEs:
            'Principal pudrición del durazno. Fruta con pudrición café y masas '
            'de esporas grisáceas, momias en el árbol. Favorecida por humedad, '
            'heridas (insectos/granizo) y fruta madura. Si hubo blossom blight, '
            'el inóculo viene de la floración.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'storage_rot_complex',
        labelEs: 'Pudriciones de cosecha/postcosecha',
        type: 'fungal_postharvest_complex',
        summaryEs:
            'Golpes, heridas, sobremadurez, fruta mojada y mala ventilación '
            'disparan pudriciones cerca o después de cosecha. Separa producción '
            'biológica de producción comercial.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La fruta se pudre con manchas cafés y esporas, sobre todo cerca de '
          'cosecha?',
      'Revisa momias y heridas (insectos/granizo) que abren la puerta.',
      '¿Hubo flor marchita (blossom blight) este ciclo? Es la misma enfermedad.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _fruitActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      _dzModifier(
        profiles: <String>{kDz04BlancoDulce},
        diagnosisId: 'brown_rot_monilinia',
        delta: 8,
        rationale:
            'Blanco/dulce es fruta delicada: pudriciones y daño de cosecha '
            'pesan más en su calidad/mercado (doc 04 §6).',
      ),
      _dzModifier(
        profiles: <String>{kDz05TardioIndustria},
        diagnosisId: 'brown_rot_monilinia',
        delta: 6,
        rationale:
            'Tardío/industria con lluvias pre-cosecha sube el riesgo de brown '
            'rot pre-cosecha (doc 04 §6).',
      ),
    ],
  ),

  // ── Familia 4: Madera, barrenadores y goma ───────────────────────────────
  PlantHealthSyndrome(
    id: 'peach_peachtree_borer_01',
    cropId: CropCatalog.peachTreeCropId,
    labelEs: 'Goma con aserrín en la base del tronco o ramas',
    stages: _woodStages,
    organIds: <String>{PlantHealthIds.organStem, PlantHealthIds.organCrown},
    primarySymptomId: PlantHealthIds.symptomTrunkBaseGumFrass,
    strongSignals: <String>{
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalRecentStress,
    },
    weakSignals: <String>{PlantHealthIds.signalHailEvent},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'peachtree_borer',
        labelEs: 'Barrenador del duraznero / barrenador de corona',
        scientificName: 'Synanthedon exitiosa',
        type: 'insect',
        summaryEs:
            'Goma mezclada con aserrín/frass en la base del tronco/cuello, con '
            'orificios y debilitamiento. Muy alta memoria: puede matar el árbol. '
            'Goma + aserrín en la base = prioriza barrenador, no "gomosis".',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrassPresent},
      ),
      PlantHealthDiagnosis(
        id: 'bacterial_or_cytospora_canker',
        labelEs: 'Cancro bacteriano / Cytospora con goma',
        type: 'canker_complex',
        summaryEs:
            'Goma en rama/cancro con muerte regresiva, ligada a heladas, heridas '
            'de poda y estrés. Si la goma está en rama con cancro y hay rama '
            'seca, considera cancro, no solo barrenador.',
      ),
      PlantHealthDiagnosis(
        id: 'wound_stress_gummosis',
        labelEs: 'Goma por herida o estrés (contexto)',
        type: 'abiotic_physiological',
        summaryEs:
            'La goma también aparece por granizo, poda, sol, frío, sequía o '
            'exceso de agua. Trátala como señal, no como diagnóstico cerrado.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La goma trae aserrín/frass y está en la base del tronco? → barrenador.',
      '¿La goma está en rama con cancro y muerte regresiva? → cancro.',
      '¿Apareció tras granizo/herida/poda? → goma por estrés/herida.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _woodActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),

  // ── Familia 5: Plagas directas de fruto y brote ──────────────────────────
  PlantHealthSyndrome(
    id: 'peach_oriental_fruit_moth_01',
    cropId: CropCatalog.peachTreeCropId,
    labelEs: 'Brotes con punta marchita o fruto perforado con aserrín',
    stages: _fruitStages,
    organIds: <String>{PlantHealthIds.organFruit, PlantHealthIds.organStem},
    primarySymptomId: PlantHealthIds.symptomFruitTunnelFrass,
    strongSignals: <String>{
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalShootTipWilt,
      PlantHealthIds.signalActiveChewing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'oriental_fruit_moth',
        labelEs: 'Palomilla oriental del fruto',
        scientificName: 'Grapholita molesta',
        type: 'insect',
        summaryEs:
            'Plaga directa clave del durazno: puntas de brote marchitas '
            '("shoot strikes") y entrada al fruto con frass, varias '
            'generaciones por temporada. El historial del huerto pesa cada año.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalShootTipWilt},
      ),
      PlantHealthDiagnosis(
        id: 'peach_twig_borer',
        labelEs: 'Barrenador de brotes/ramillas del duraznero',
        scientificName: 'Anarsia lineatella',
        type: 'insect',
        summaryEs:
            'Brotes secos/marchitos con larva y daño en fruto. Si ves "punta '
            'quemada" en brote, no asumas bacteria sin revisar perforación/larva.',
      ),
      PlantHealthDiagnosis(
        id: 'plum_curculio',
        labelEs: 'Curculio / picudo de ciruela-durazno',
        type: 'insect',
        summaryEs:
            'Cicatriz de oviposición en forma de media luna en fruto recién '
            'cuajado, con caída. Considéralo antes de asumir solo aborto '
            'fisiológico (riesgo regional).',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca puntas de brote marchitas y perforación con aserrín en el fruto.',
      'Distingue palomilla/barrenador (galería con larva) de cicatriz de '
          'curculio (media luna externa).',
      'Revisa fruta caída y el historial de plagas del huerto.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _fruitActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),

  // ── Familia 6: Ácaros / araña roja ───────────────────────────────────────
  PlantHealthSyndrome(
    id: 'peach_mites_01',
    cropId: CropCatalog.peachTreeCropId,
    labelEs: 'Bronceado o punteado fino en hoja con calor',
    stages: _fruitStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalMitesWebbing,
    },
    weakSignals: <String>{PlantHealthIds.signalDryHotWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'spider_mites_complex',
        labelEs: 'Ácaros / araña roja',
        type: 'mite',
        summaryEs:
            'Punteado amarillo/bronceado y telaraña fina con calor, baja '
            'humedad y polvo. Si defolia antes de cargar reservas, pesa en el '
            'ciclo siguiente (postcosecha incluida).',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa el envés de las hojas con lupa: telaraña fina o ácaros diminutos.',
      'Cruza con calor y humedad baja recientes.',
      'Diferencia el bronceado de ácaro del golpe de sol o la roña.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 7: Estrés fisiológico, clima y calidad ───────────────────────
  PlantHealthSyndrome(
    id: 'peach_sunburn_01',
    cropId: CropCatalog.peachTreeCropId,
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
            'calor/radiación, fruta expuesta por poda/defoliación/granizo y '
            'estrés hídrico.',
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
    varietyModifiers: <VarietyModifier>[
      _dzModifier(
        profiles: <String>{kDz05TardioIndustria},
        diagnosisId: 'sunburn_sunscald',
        delta: 5,
        rationale:
            'Tardío/industria madura bajo calor: el golpe de sol pesa más (doc '
            '04 §6).',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'peach_overcrop_split_pit_01',
    cropId: CropCatalog.peachTreeCropId,
    labelEs: 'Mucha fruta chica, deforme o con hueso partido',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFruitDeformation,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'overcrop_small_fruit_thinning_need',
        labelEs: 'Sobrecarga / falta de raleo / fruta pequeña',
        type: 'abiotic_physiological',
        summaryEs:
            'Demasiados frutos dan calibre bajo, ramas cargadas y árbol '
            'agotado. Si hay mucha fruta chica con agua moderada, revisa carga y '
            'raleo antes de culpar a K/N.',
      ),
      PlantHealthDiagnosis(
        id: 'split_pit_stone_hardening_disorder',
        labelEs: 'Hueso partido / split pit',
        type: 'abiotic_physiological',
        summaryEs:
            'Hendidura interna del hueso ligada a crecimiento rápido, variedades '
            'tempranas, riego irregular o sobre-raleo en la subventana de '
            'endurecimiento de hueso (dentro de llenado). Fruta más vulnerable a '
            'pudriciones. No es una etapa nueva: es contexto de llenado.',
      ),
      PlantHealthDiagnosis(
        id: 'fruit_drop_physiological',
        labelEs: 'Caída fisiológica de fruto',
        type: 'abiotic_physiological',
        summaryEs:
            'Frutitos caídos por mala polinización, helada, estrés hídrico, '
            'calor o carga excesiva. Cruza clima de floración antes de '
            'diagnosticar.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay muchos frutos pero chicos? Revisa carga y raleo, no solo fertilizante.',
      '¿El hueso aparece partido? Cruza con riego irregular y variedad temprana.',
      'Separa producción biológica (kg) de producción comercial (calibre/calidad).',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: _fruitActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _dzModifier(
        profiles: <String>{kDz02TempranoBajoFrio},
        diagnosisId: 'split_pit_stone_hardening_disorder',
        delta: 6,
        rationale:
            'Las variedades tempranas de crecimiento rápido suben el riesgo de '
            'hueso partido (doc 04 §5).',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'peach_iron_chlorosis_01',
    cropId: CropCatalog.peachTreeCropId,
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
        labelEs: 'Deficiencia de zinc / hoja chica / roseta',
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
