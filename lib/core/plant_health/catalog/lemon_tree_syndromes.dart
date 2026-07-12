import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo de riesgos / sanidad vegetal del Limón (`crop_lemon_tree`).
///
/// Alimentado por el documento oficial
/// `04_Riesgos_Cultivo_Sanidad_Estres_Memoria_BioG_Limon_LM_v1`.
///
/// Reglas no negociables (doc 04 §0, §9, §13):
/// - BIO-G ORIENTA, no diagnostica de forma absoluta: "condición favorable a…",
///   "revisa…", "síntomas compatibles con…", "confirma si avanza…".
/// - NO receta plaguicidas ni ingredientes activos.
/// - NO diagnostica HLB/VTC/cancro/leprosis/Phytophthora de forma cerrada: eleva
///   cautela y pide confirmación con técnico/sanidad local.
/// - El perfil LM solo modifica sensibilidad/mensajes (varietyModifiers); el
///   catálogo base es el mismo para todas las variedades.
/// - Cítrico SIEMPREVERDE con MEMORIA fuerte y producción frecuente: salinidad,
///   HLB/psílido, Phytophthora/gomosis, antracnosis, defoliación, caída de flor/
///   fruto, desfase mal aplicado y mala postcosecha pesan en el ciclo siguiente
///   (doc 04 §5.10, §9.4). `dormancy` y `post_harvest` NO apagan la sanidad.
/// - Fruta verde comercial: en Persa/Mexicano el corte puede ser verde; no
///   marcar inmaduro por no estar amarillo (doc 04 §13).
///
/// El limón NO es un naranjo pequeño (doc 04 §0, §13): reusa IDs cítricos de
/// `PlantHealthIds`, pero el copy, diagnósticos probables y memoria son de limón
/// (antracnosis fuerte en mexicano, desfase, cortes escalonados). NO se copia el
/// catálogo del naranjo cambiando "naranja" por "limón".

const Set<PlantHealthStageBucket> _establishmentStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.lateSeason,
    };

// Incluye `lateSeason` a propósito: en cítricos chupadores, ácaros, salinidad y
// deficiencias siguen pesando en postcosecha/reposo relativo —etapas que el
// adapter mapea a lateSeason— para que post_harvest/dormancy NO queden como
// etapas apagadas (memoria y siguiente floración; doc 04 §2.3, §5.10).
const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.lateSeason,
};

// Brotación tierna: minador, psílido, pulgones, trips, ácaros (doc 04 §5.3).
const Set<PlantHealthStageBucket> _flushStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
};

// Fe/Zn/Mn / hoja chica / clorosis: brotación y crecimiento (doc 04 §5.10).
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

// Brote/flor/fruto pequeño para antracnosis y muerte de ramas (doc 04 §5.6).
const Set<PlantHealthStageBucket> _anthracnoseStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    };

// Fruto/cáscara: amarre, llenado, madurez y postcosecha (doc 04 §5.8, §5.9).
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

// Clima (frío/helada/calor/viento): pesa en flor/fruto pero puede darse en todo
// el ciclo (doc 04 §5.9).
const Set<PlantHealthStageBucket> _climateStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const String _disclaimer =
    'Orientación de riesgo, no diagnóstico definitivo. BIO-G sugiere revisar, '
    'comparar y confirmar en campo o con asesoría/sanidad local si el daño '
    'avanza. No prescribe plaguicidas ni ingredientes activos. HLB, cancro, '
    'tristeza, leprosis y Phytophthora requieren confirmación técnica; no se '
    'cierran por sensor.';

const List<String> _hlbActions = <String>[
  'No cierres HLB por una hoja amarilla. Revisa si el moteado es disparejo/'
      'asimétrico, si hay psílido (ninfas o tubitos blancos) en los brotes, '
      'fruta chica/ladeada o sectores de copa amarillos.',
  'Si hay señales compatibles y la región tiene psílido/HLB, toma foto y '
      'confirma con técnico/laboratorio/sanidad local. BIO-G baja la confianza '
      'del NPK cuando hay sospecha de HLB: el árbol no mueve bien fotoasimilados '
      'ni nutrientes.',
  'Fertilizar no cura el HLB. Protege el brote tierno: es donde se mete el '
      'psílido. No lo diagnostiques por el sensor.',
];

const List<String> _rootActions = <String>[
  'Revisa cuello, raíces y drenaje antes de regar más.',
  'Marchitez con suelo húmedo NO es falta de agua: puede ser raíz asfixiada, '
      'Phytophthora o compactación. Si hay goma en el tronco bajo, piensa en '
      'gomosis/cuello antes que fertilizante.',
  'El limón es sensible a sales: si la EC está alta, no empujes NPK; revisa '
      'agua, drenaje y salitre en la zona de raíz.',
];

const List<String> _flushActions = <String>[
  'Revisa brotes tiernos y envés: psílido, minador (galerías plateadas), '
      'pulgones, trips o ácaros.',
  'Brote tierno NO significa exceso de N automáticamente: primero busca la '
      'plaga antes de culpar al fertilizante.',
  'En limón continuo/desfase, cada flush nuevo sube la presión del vector: '
      'monitorea y confirma con sanidad local si aparece el psílido.',
];

const List<String> _foliarActions = <String>[
  'Revisa el envés: chupadores (escamas, cochinillas, mosca blanca/prieta, '
      'pulgones, psílido), mielecilla pegajosa, negrilla (fumagina) o ácaros.',
  'La negrilla es CONSECUENCIA de la mielecilla: busca primero el insecto '
      'chupador, no la trates como hongo principal.',
  'Si defolia durante llenado o postcosecha, guarda la memoria: baja reservas y '
      'afecta la siguiente floración y el calibre.',
];

const List<String> _bloomActions = <String>[
  'En floración/cuajado el limón no perdona estrés: cruza calor, frío/helada, '
      'viento, humedad del suelo y sales antes de culpar al fertilizante.',
  'Algo de caída de flor/frutito puede ser normal. Se vuelve alerta si coincide '
      'con calor, agua baja, salinidad, raíz mala o poca hoja.',
  'El desfase no es magia: si el árbol entra débil o el estrés se pasó, puede '
      'florear y perder cuajado. No prometas más cosecha solo por inducir flor.',
];

const List<String> _anthracnoseActions = <String>[
  'En limón mexicano, revisa brotes, flor y limoncitos: necrosis, frutitos '
      'momificados, "tachuelas", lesiones corchosas o agrietamiento.',
  'Si hay humedad/lluvia y daño en flor/fruto pequeño, no lo reduzcas a trips o '
      'riego. La antracnosis merece entrada propia en mexicano.',
  'Guarda la pérdida de cuajado y el daño de fruta como memoria. Si hay muerte '
      'de ramas, revisa raíz, sales, HLB y Phytophthora, no lo cierres como HLB.',
];

const List<String> _foliarDiseaseActions = <String>[
  'Revisa si las manchas se ven grasosas en el envés (greasy spot), ásperas '
      'tipo "lija" (melanosis) o corchosas/verrugosas (roña/sarna).',
  'Cruza con humedad/lluvia prolongada, dosel cerrado y madera muerta. La '
      'defoliación afecta reservas y la siguiente floración.',
  'Si hay lesiones elevadas con halo y contexto regional, no lo cierres: puede '
      'ser cancro (regulado). Pide confirmación fitosanitaria; no recetes.',
];

const List<String> _fruitActions = <String>[
  'Abre varios limones: ¿hay moho verde/azul, olor fuerte, larvas, pudrición '
      'desde el pedúnculo o daño superficial?',
  'Separa brown rot por salpicadura/humedad (fruta baja tras lluvia) del moho '
      'de cosecha por heridas (Penicillium) y de la mosca de la fruta (larvas). '
      'No diagnostiques sin abrir muestra.',
  'Si hay mosca de la fruta o riesgo regulado, en región con campaña recomienda '
      'seguimiento con sanidad local. Guarda el evento de clima húmedo.',
];

const List<String> _abioticActions = <String>[
  'El limón rajado suele venir de riego irregular (seco y luego mucha agua), '
      'calor o cáscara débil; el golpe de sol, del lado expuesto; la cicatriz de '
      'viento, del roce con ramas/espinas.',
  'Revisa patrón de riego, calor y aplicaciones recientes (aceite/cobre/'
      'herbicida) antes de asumir un hongo. La fitotoxicidad sigue el patrón de '
      'la aspersión/deriva.',
  'Limón chico/seco o con poco jugo: revisa agua, K, sales, raíz y HLB antes de '
      'asumir una sola causa. Guarda como memoria de calidad.',
];

const List<String> _nutritionActions = <String>[
  'Con pH alto o caliza, la hoja nueva amarilla con nervadura verde suele ser '
      'Fe/Zn/Mn bloqueados, NO falta de nitrógeno. Confirma con análisis foliar.',
  'K bajo pega a calibre y jugo, pero si falta agua o hay sales, primero corrige '
      'eso: el limón no toma bien el K con la raíz estresada.',
  'Bordes de hoja quemados pueden ser sales/cloruros/sodio/boro o calor, no solo '
      'falta de potasio. BIO-G v1 no mide Fe/Zn/Mn/B/Ca/Mg: úsalos como contexto '
      'y análisis, no como dosis.',
];

const List<String> _climateActions = <String>[
  'Cruza con el clima reciente: helada/frío tumba flor, brote y fruta '
      '(el mexicano es más sensible al frío); el golpe de sol aparece del lado '
      'expuesto; el granizo/viento marca patrón de roce.',
  'No diagnostiques nutrición ni hongo si el daño coincide con un evento '
      'climático. Registra el evento como memoria de carga/continuidad.',
  'En floración/cuajado el calor + baja humedad puede tumbar amarre aunque el '
      'NPK esté bien.',
];

const List<String> _memoryActions = <String>[
  'La cosecha NO cierra el limón: si queda hoja activa, el árbol recupera '
      'reservas para la siguiente floración/corte. No apagues el seguimiento.',
  'Guarda estreses del ciclo (salinidad, HLB/psílido, Phytophthora, '
      'defoliación, caída fuerte, cortes seguidos, desfase mal aplicado): '
      'afectan brotación, cuajado y calibre del siguiente ciclo.',
  'Si la EC quedó alta al cierre o el árbol quedó cansado por carga alta o '
      'muchos cortes, la siguiente floración puede salir débil: cuida hoja, raíz '
      'y sales.',
];

/// Modificador de sensibilidad por perfil LM (doc 04 §8).
VarietyModifier _lmModifier({
  required Set<String> profiles,
  required String diagnosisId,
  required int delta,
  required String rationale,
  bool requiresCaution = false,
}) => VarietyModifier(
  cropId: CropCatalog.lemonTreeCropId,
  varietyIds: profiles,
  diagnosisIds: <String>{diagnosisId},
  scoreDelta: delta,
  rationaleEs: rationale,
  isProxy: true,
  requiresCaution: requiresCaution,
);

/// Catálogo de síndromes del limón. `final` (no `const`) por los modificadores
/// por perfil LM construidos con [_lmModifier].
final List<PlantHealthSyndrome> lemonTreeSyndromes = <PlantHealthSyndrome>[
  // ── Familia 1: HLB, psílido asiático y riesgos regulados ──────────────────
  PlantHealthSyndrome(
    id: 'lemon_hlb_psyllid_regulated_01',
    cropId: CropCatalog.lemonTreeCropId,
    labelEs: 'Moteado disparejo, brote con psílido o limón chico/deforme',
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
            'Moteado AMARILLO ASIMÉTRICO en hoja, sectores de copa amarillos, '
            'árbol decaído, limón chico/ladeado/deforme y caída. En limón '
            'mexicano y persa es uno de los riesgos más graves en México. BIO-G '
            'NUNCA lo confirma por sensor ni foto suelta: si hay moteado '
            'disparejo + fruta chica/deforme + caída + psílido/región citrícola, '
            'eleva la urgencia y baja la confianza del NPK. Fertilizar no cura.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalAsymmetricMottle},
      ),
      PlantHealthDiagnosis(
        id: 'asian_citrus_psyllid_vector',
        labelEs: 'Psílido asiático de los cítricos / PAC (vector)',
        scientificName: 'Diaphorina citri',
        type: 'insect_vector',
        summaryEs:
            'Insecto pequeño café con postura inclinada; ninfas amarillas/'
            'naranjas con tubitos cerosos blancos y mielecilla en brotes '
            'tiernos. Si se ve psílido, no diagnostiques HLB automáticamente, '
            'pero sube la presión de vector y revisa los brotes. El limón '
            'tropical/continuo y el desfase con flush repetido elevan el riesgo.',
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
      '¿El limón sale chico, ladeado, deforme o se cae verde? ¿La región tiene '
          'HLB/psílido reportado?',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.immediate,
    baseActionsEs: _hlbActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _lmModifier(
        profiles: <String>{kLm02MexicanoColima},
        diagnosisId: 'huanglongbing_hlb_context',
        delta: 8,
        rationale:
            'Fuerte contexto de HLB en limón mexicano del Pacífico mexicano '
            '(Colima/Michoacán/Nayarit/Jalisco); usar con cautela (doc 04 §8).',
        requiresCaution: true,
      ),
      _lmModifier(
        profiles: <String>{kLm04TropicalContinuo, kLm05DesfaseInducido},
        diagnosisId: 'asian_citrus_psyllid_vector',
        delta: 8,
        rationale:
            'Flush frecuente/inducido todo el año sube la presión del psílido '
            '(doc 04 §8).',
      ),
      _lmModifier(
        profiles: <String>{kLm01PersaTahiti},
        diagnosisId: 'asian_citrus_psyllid_vector',
        delta: 5,
        rationale: 'HLB/PAC regional en limón persa (doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 2: Raíz, cuello, drenaje, Phytophthora/gomosis y salinidad ────
  PlantHealthSyndrome(
    id: 'lemon_root_crown_phytophthora_salinity_01',
    cropId: CropCatalog.lemonTreeCropId,
    labelEs: 'Árbol triste con suelo húmedo, goma en tronco o borde quemado',
    stages: _establishmentStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomCitrusGummosisTrunk,
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
        id: 'phytophthora_root_rot',
        labelEs: 'Pudrición de raíz por Phytophthora / raíz asfixiada',
        scientificName: 'Phytophthora spp.',
        type: 'oomycete_soil_complex',
        summaryEs:
            'Árbol triste con suelo húmedo, copa rala, hojas pálidas, caída y '
            'raíz fina marrón. Marchitez con suelo mojado NO es falta de agua: '
            'revisa drenaje y raíz antes de regar. El HLB reduce raíz fina y '
            'agrava el daño; baja la confianza del sensor.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWaterlogging},
      ),
      PlantHealthDiagnosis(
        id: 'salinity_root_stress_context',
        labelEs: 'Estrés salino / salitre / EC alta en raíz',
        type: 'abiotic_soil',
        summaryEs:
            'Borde de hoja quemado, defoliación, fruta chica, caída de flor/'
            'fruto y síntomas de sequía aunque se riegue. El limón es sensible a '
            'sales: si la EC está alta, bloquea recomendaciones agresivas de '
            'NPK. Salinidad + humedad baja = estrés osmótico fuerte. Revisa CE, '
            'agua y drenaje.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'soil_compaction_root_stress',
        labelEs: 'Compactación / raíz sin aire',
        type: 'abiotic_soil',
        summaryEs:
            'Bajo vigor por líneas, charcos, raíz superficial y respuesta pobre '
            'a riego/fertilizante. La raíz cítrica es superficial y necesita '
            'aire: resistencia alta + humedad irregular + bajo vigor = suelo/'
            'raíz primero, NPK después.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRootsDarkRot},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La marchitez ocurre con suelo húmedo (no seco)?',
      '¿Hay goma/exudado color ámbar en la base del tronco o el cuello?',
      '¿El agua deja salitre/costra blanca? ¿El suelo se encharca o se pone '
          'duro?',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _lmModifier(
        profiles: <String>{kLm01PersaTahiti},
        diagnosisId: 'salinity_root_stress_context',
        delta: 5,
        rationale:
            'El limón persa es muy sensible a salinidad y raíz/Phytophthora '
            '(doc 04 §8).',
      ),
      _lmModifier(
        profiles: <String>{kLm03AmarilloEurekaLisbon},
        diagnosisId: 'phytophthora_root_rot',
        delta: 4,
        rationale:
            'El amarillo/Eureka-Lisbon es sensible a contextos frío-húmedos y '
            'Phytophthora (doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 3: Brotación tierna y plagas de brote ─────────────────────────
  PlantHealthSyndrome(
    id: 'lemon_flush_pests_01',
    cropId: CropCatalog.lemonTreeCropId,
    labelEs: 'Hoja nueva con minas, brote enrollado o insectos en brote',
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
            'joven y con flush repetido (tropical/continuo).',
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
        id: 'citrus_thrips_flower_fruit_scarring',
        labelEs: 'Trips / cicatriz en flor o limón chico',
        scientificName: 'Scirtothrips citri',
        type: 'insect',
        summaryEs:
            'Cicatrices plateadas/corchosas cerca del cáliz; el limón sale '
            'marcado desde chico. Marca desde limón chico = revisa trips/viento/'
            'daño físico, no esperes a cosecha. Sepáralo de melanosis y viento.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalThripsPresent},
      ),
      PlantHealthDiagnosis(
        id: 'broad_mite_bud_mite_context',
        labelEs: 'Ácaros de brote / deformación de brote y fruto',
        type: 'mite',
        summaryEs:
            'Hojas nuevas deformadas, brotes atrofiados y fruta con daño '
            'superficial en microclima húmedo/cálido y canopia densa. Si hay '
            'deformación sin minas claras, revisa ácaros/trips/fitotoxicidad.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalLeafRolling},
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
    favorsVectorPressure: true,
    varietyModifiers: <VarietyModifier>[
      _lmModifier(
        profiles: <String>{kLm04TropicalContinuo},
        diagnosisId: 'citrus_leafminer',
        delta: 6,
        rationale:
            'Clima cálido con brotación continua favorece al minador y trips '
            '(doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 4: Chupadores, mielecilla, fumagina, escamas y ácaros ─────────
  PlantHealthSyndrome(
    id: 'lemon_sucking_pests_sooty_mold_mites_01',
    cropId: CropCatalog.lemonTreeCropId,
    labelEs: 'Hoja/fruto pegajoso, negrilla, escamas o bronceado',
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
        id: 'soft_scale_armored_snow_scale_complex',
        labelEs: 'Escamas / conchuelas / escama de nieve',
        type: 'insect',
        summaryEs:
            'Costras pegadas en hoja/rama/fruto que no se mueven, o capa blanca '
            'tipo nieve sobre tronco/ramas de limón mexicano/persa, con '
            'mielecilla y negrilla. Si la costra no se raspa, piensa en escama; '
            'diferénciala de hongo blanco.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalCannotScrapeOff},
      ),
      PlantHealthDiagnosis(
        id: 'mealybug_whitefly_blackfly_complex',
        labelEs: 'Cochinilla / mosca blanca / mosca prieta + fumagina',
        scientificName: 'Aleurocanthus woglumi',
        type: 'insect',
        summaryEs:
            'Masas blancas algodonosas bajo el cáliz, ninfas en el envés, vuelo '
            'de mosquitas al mover la hoja, mielecilla y fumagina negra. '
            'Negrilla + envés con ninfas = chupador: no trates la fumagina como '
            'causa primaria, busca el insecto que produce la miel.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWhiteflyCloud},
      ),
      PlantHealthDiagnosis(
        id: 'citrus_rust_red_spider_mite_complex',
        labelEs: 'Ácaro de la roya / araña roja / bronceado del limón',
        type: 'mite',
        summaryEs:
            'Piel bronceada/oxidada o punteado y telaraña fina en hoja/fruto, en '
            'clima cálido/seco y con polvo. El bronceado sin pudrición puede ser '
            'ácaro; afecta el valor comercial de la cáscara aunque no los kg. '
            'Diferéncialo de salinidad, golpe de sol y deficiencias.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalMitesWebbing},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La hoja/fruta está pegajosa y con tizne negro (negrilla)?',
      '¿Hay costras que no se raspan, algodón blanco, mosquita blanca o '
          'telaraña fina en el envés?',
      '¿Hay hormigas subiendo por el tronco cuidando chupadores?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _foliarActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),

  // ── Familia 5: Floración, cuajado, caída de frutito y desfase ─────────────
  PlantHealthSyndrome(
    id: 'lemon_flowering_set_drop_desfase_01',
    cropId: CropCatalog.lemonTreeCropId,
    labelEs: 'Floreó pero no amarró, se cae el limoncito o el desfase salió débil',
    stages: _bloomStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
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
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'flowering_heat_water_stress',
        labelEs: 'Floración bajo calor / falta de agua',
        type: 'abiotic_physiological',
        summaryEs:
            'Flor que se seca, caída de flor y poco amarre con calor >35 °C, '
            'viento seco, baja humedad del suelo o salinidad. En floración '
            'mandan agua y temperatura: el N alto no arregla una floración '
            'estresada. Puede tirar flor aunque el NPK marque bien.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
      PlantHealthDiagnosis(
        id: 'fruit_set_drop_stress_complex',
        labelEs: 'Caída de limoncito / no amarró',
        type: 'abiotic_physiological',
        summaryEs:
            'Frutitos que amarillean/se caen; mucha flor pero poca carga. Algo '
            'de caída puede ser normal; se vuelve alerta si coincide con calor, '
            'sales, humedad baja, raíz mala, HLB, trips o exceso de N. No '
            'diagnostiques solo por NPK.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFlowerDrop},
      ),
      PlantHealthDiagnosis(
        id: 'salinity_fruit_set_drop',
        labelEs: 'Sales tumbando flor/frutito',
        type: 'abiotic_soil',
        summaryEs:
            'Caída de flor/frutito con borde de hoja quemado o árbol "sediento" '
            'aunque se riegue, con EC alta, riego de pozo o drenaje pobre. Si la '
            'EC está alta, primero sales/agua/drenaje; no empujes fertilización.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'induced_bloom_stress_mismanagement',
        labelEs: 'Desfase / inducción mal aplicado',
        type: 'management_physiological_context',
        summaryEs:
            'Brote/flor irregular, caída de flor y árbol cansado tras estrés '
            'hídrico excesivo, poda/defoliación fuerte o riego de retorno mal '
            'sincronizado. El desfase no es magia: si el árbol entra débil, baja '
            'el cuajado. No prometas más rendimiento por inducir floración.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Floreó mucho pero no amarró?',
      '¿Se cayó el frutito después de calor, viento, frío o falta de agua?',
      '¿Intentaste inducir floración/desfase con riego, poda o estrés? ¿El árbol '
          'trae hoja suficiente o está muy ralo?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _bloomActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _lmModifier(
        profiles: <String>{kLm05DesfaseInducido},
        diagnosisId: 'induced_bloom_stress_mismanagement',
        delta: 10,
        rationale:
            'El perfil desfase/inducido concentra el riesgo de estrés mal '
            'aplicado que tumba el cuajado (doc 04 §5.5, §8).',
      ),
      _lmModifier(
        profiles: <String>{kLm04TropicalContinuo},
        diagnosisId: 'flowering_heat_water_stress',
        delta: 6,
        rationale:
            'Calor + baja HR en zonas tropicales tumba flor/frutito (doc 04 §8).',
      ),
      _lmModifier(
        profiles: <String>{kLm02MexicanoColima},
        diagnosisId: 'fruit_set_drop_stress_complex',
        delta: 5,
        rationale:
            'El limón mexicano tiene caída frecuente de frutito y sensibilidad '
            'al frío (doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 6: Antracnosis, muerte de ramas y complejos flor-fruto ────────
  PlantHealthSyndrome(
    id: 'lemon_anthracnose_flower_fruit_dieback_01',
    cropId: CropCatalog.lemonTreeCropId,
    labelEs: 'Brote, flor o limoncito con necrosis, tachuelas o ramas secas',
    stages: _anthracnoseStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMummifiedFruitRot,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalRecentStress,
    },
    weakSignals: <String>{
      PlantHealthIds.signalFlowerDrop,
      PlantHealthIds.signalWaterSoakedMargin,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'anthracnose_flower_fruit_shoot_complex',
        labelEs: 'Antracnosis en limón / flor, brote y fruto',
        scientificName: 'Colletotrichum spp.',
        type: 'fungus',
        summaryEs:
            'Brotes con necrosis, flores afectadas, frutitos momificados, '
            '"tachuelas" adheridas, lesiones corchosas y agrietamiento de fruto, '
            'con lluvia/humedad, tejido tierno y floraciones frecuentes. En '
            'limón mexicano merece entrada propia: no lo confundas todo con '
            'trips o daño físico.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'fruit_pinhead_mummification_context',
        labelEs: 'Frutitos momificados / "tachuelas"',
        type: 'fungus_physiological_context',
        summaryEs:
            'Frutitos pequeños secos adheridos, con cicatrices y lesiones, por '
            'antracnosis/humedad o estrés en cuajado. Registra como pérdida de '
            'cuajado y sanidad de flor/fruto.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
      PlantHealthDiagnosis(
        id: 'branch_dieback_stress_hlb_complex',
        labelEs: 'Muerte de ramas / secamiento progresivo',
        type: 'complex_context',
        summaryEs:
            'Ramas que se secan desde la punta o por sectores, hoja clorótica y '
            'defoliación por sequía, nutrición deficiente, frío, suelos '
            'compactos, HLB, Phytophthora o heridas. No lo cierres como HLB ni '
            'como falta de agua: revisa raíz, sales, HLB, Phytophthora y estrés '
            'acumulado.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay necrosis en brotes, flores o frutitos con "tachuelas" adheridas?',
      '¿Hubo lluvia/humedad prolongada durante la floración o el cuajado?',
      '¿Hay ramas que se secan desde la punta o por sectores?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _anthracnoseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _lmModifier(
        profiles: <String>{kLm02MexicanoColima},
        diagnosisId: 'anthracnose_flower_fruit_shoot_complex',
        delta: 10,
        rationale:
            'La antracnosis es especialmente importante en limón mexicano '
            '(brote, flor, fruto pequeño; doc 04 §5.6, §8).',
      ),
      _lmModifier(
        profiles: <String>{kLm04TropicalContinuo},
        diagnosisId: 'anthracnose_flower_fruit_shoot_complex',
        delta: 5,
        rationale:
            'Zonas tropicales húmedas favorecen la antracnosis (doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 7: Enfermedades foliares y de copa (hongo/cancro) ─────────────
  PlantHealthSyndrome(
    id: 'lemon_foliar_fungal_canker_01',
    cropId: CropCatalog.lemonTreeCropId,
    labelEs: 'Manchas grasosas, corchosas o ásperas en hoja/fruto',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
      PlantHealthIds.organStem,
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
            'Moteado amarillo que se ve café/negro con aspecto grasoso, más en '
            'el envés, con defoliación si es severa. Favorecida por humedad, '
            'hojarasca y copa cerrada. La defoliación afecta reservas y la '
            'siguiente floración.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'melanose_diaporthe',
        labelEs: 'Melanosis / puntitos ásperos tipo "lija"',
        scientificName: 'Diaporthe citri',
        type: 'fungus',
        summaryEs:
            'Lesiones pequeñas elevadas y ásperas en hoja y fruto joven, tras '
            'lluvia y con madera muerta como fuente. Afecta calidad externa; '
            'revisa madera muerta y humedad.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSpringWetFoliage},
      ),
      PlantHealthDiagnosis(
        id: 'citrus_scab_regional',
        labelEs: 'Roña / sarna de cítricos (regional)',
        scientificName: 'Elsinoë fawcettii',
        type: 'fungus',
        summaryEs:
            'Lesiones corchosas verrugosas y deformación en fruto/hoja tierna en '
            'zonas húmedas. No confundir con cancro: el cancro tiene halo/lesión '
            'elevada y es regulado según región.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDenseWetCanopy},
      ),
      PlantHealthDiagnosis(
        id: 'citrus_canker_regulated_context',
        labelEs: 'Cancro de los cítricos (regulado, según región)',
        scientificName: 'Xanthomonas citri subsp. citri',
        type: 'bacteria_regulated_context',
        summaryEs:
            'Lesiones elevadas/corchosas con halo amarillo y margen acuoso en '
            'hoja/fruto/tallo. No activar como diagnóstico universal: si hay '
            'lesiones con halo y contexto regional, pide confirmación '
            'fitosanitaria. No recomendar productos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterSoakedMargin,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las manchas se ven grasosas en el envés y hay defoliación?',
      '¿Hubo lluvia/humedad prolongada o dosel cerrado y mojado?',
      '¿Las lesiones ásperas de la cáscara son elevadas con halo (posible '
          'cancro regional)?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _foliarDiseaseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    varietyModifiers: <VarietyModifier>[
      _lmModifier(
        profiles: <String>{kLm03AmarilloEurekaLisbon},
        diagnosisId: 'greasy_spot_mycosphaerella',
        delta: 5,
        rationale:
            'El amarillo/Eureka-Lisbon es sensible a enfermedades de humedad '
            '(doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 8: Enfermedades y daños de fruto / cáscara / cosecha ──────────
  PlantHealthSyndrome(
    id: 'lemon_fruit_rot_quality_01',
    cropId: CropCatalog.lemonTreeCropId,
    labelEs: 'Limón podrido, con moho, olor fuerte o larvas',
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
            'Lesión firme café/oliva con olor fuerte, sobre todo en fruta baja '
            'cerca del suelo tras lluvia/salpicadura. Si inicia en fruta baja '
            'tras lluvia, conéctala con Phytophthora/suelo; revisa poda de '
            'faldeo y salpicadura.',
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
            'Mancha acuosa que desarrolla moho verde/azul y pudrición blanda '
            'alrededor de heridas, en fruta cosechada o golpeada. Es problema de '
            'herida/manejo/almacenamiento, no necesariamente del árbol en campo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWhiteGreenBlueMold,
        },
      ),
      PlantHealthDiagnosis(
        id: 'stem_end_rot_lasiodiplodia',
        labelEs: 'Pudrición del extremo del pedúnculo',
        scientificName: 'Lasiodiplodia / Diplodia spp.',
        type: 'fungus',
        summaryEs:
            'Pudrición que avanza oscura desde el pedúnculo, en fruta estresada, '
            'con heridas, calor o mal manejo de cosecha/almacenamiento. Si se '
            'repite, revisa estrés del árbol y manejo de cosecha.',
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
            'larvas o campaña regional, recomienda seguimiento con sanidad '
            'local.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFruitLarvae},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La pudrición viene del lado bajo/cerca del suelo tras lluvia?',
      '¿El moho es verde/azul y arrancó de una herida de manejo?',
      '¿Hay larvas o picaduras al abrir el limón?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _fruitActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),

  // ── Familia 9: Desórdenes abióticos de fruto y ambiente ───────────────────
  PlantHealthSyndrome(
    id: 'lemon_abiotic_fruit_disorders_01',
    cropId: CropCatalog.lemonTreeCropId,
    labelEs: 'Limón rajado, quemado, seco, raspado o con poco jugo',
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
      PlantHealthIds.signalSalinityLoad,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'fruit_splitting_cracking',
        labelEs: 'Limón rajado / agrietado',
        type: 'abiotic_physiological',
        summaryEs:
            'Rajaduras en la cáscara por riego irregular (seco y luego mucha '
            'agua), sequía seguida de agua, calor, cáscara débil o desbalance '
            'K/Ca/Mg contextual. Revisa riego irregular antes de culpar hongo; '
            'si hay lesión corchosa previa, considera antracnosis/daño.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalFruitSplitAfterIrrigation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunburn_fruit_leaf',
        labelEs: 'Golpe de sol / fruta quemada',
        type: 'abiotic_physical',
        summaryEs:
            'Parche seco/quemado del lado expuesto (sur/oeste) de fruta y hojas '
            'por calor, exposición directa, poda fuerte o defoliación. Si el '
            'daño está del lado expuesto, no lo confundas con pudrición o plaga.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalExposedFruitSouthwest,
        },
      ),
      PlantHealthDiagnosis(
        id: 'dry_fruit_low_juice_context',
        labelEs: 'Limón seco / poco jugo / bajo calibre',
        type: 'abiotic_nutritional_context',
        summaryEs:
            'Fruto chico, poco jugo y cáscara gruesa por falta de agua, K bajo o '
            'bloqueado, sales, HLB, raíz dañada, cosecha tardía o calor. Revisa '
            'agua + K + sales + raíz + HLB antes de asumir una sola causa.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
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
      '¿El limón se rajó tras un periodo seco seguido de riego/lluvia?',
      '¿El daño está del lado expuesto al sol (sur/oeste)?',
      '¿El limón sale chico, seco o con poco jugo? ¿Hubo aplicación reciente de '
          'aceite/cobre/herbicida?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _lmModifier(
        profiles: <String>{kLm01PersaTahiti},
        diagnosisId: 'dry_fruit_low_juice_context',
        delta: 5,
        rationale:
            'En Persa el calibre, jugo y calidad externa verde pesan mucho '
            'comercialmente (doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 10: Nutrición, disponibilidad aparente ────────────────────────
  PlantHealthSyndrome(
    id: 'lemon_nutrition_availability_01',
    cropId: CropCatalog.lemonTreeCropId,
    labelEs: 'Hoja amarilla, hoja chica, borde quemado o fruta chica',
    stages: _micronutrientStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
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
            'Hoja NUEVA amarilla con nervaduras verdes, hoja chica o roseta, en '
            'suelos alcalinos/calizos, con exceso de humedad o raíz dañada. En '
            'cítricos el Zn/Fe/Mn es clave y el HLB puede imitarlo. No '
            'diagnostiques falta de N si la clorosis es internerval en hoja '
            'nueva y el pH es alto. Confirma con análisis foliar.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHighPhCalcareous},
      ),
      PlantHealthDiagnosis(
        id: 'potassium_low_fruit_quality_context',
        labelEs: 'K bajo / riesgo de calibre, jugo y calidad',
        type: 'abiotic_nutritional_context',
        summaryEs:
            'Fruto chico, poco jugo y calidad débil en cuajado/llenado/madurez. '
            'K bajo pesa si agua/EC/pH están bien; pero si la humedad está baja '
            'o la EC alta, primero corrige agua/sales: el limón no aprovecha el '
            'K con la raíz estresada. Si el K foliar ya salió alto, no subas más.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'salinity_chloride_boron_leaf_burn',
        labelEs: 'Quemadura de borde por sales / cloruros / boro',
        type: 'abiotic_soil',
        summaryEs:
            'Quemadura marginal, puntas secas, defoliación y fruta chica con EC '
            'alta o agua salina, poca lixiviación y mal drenaje. Si la EC está '
            'alta, no digas "falta K" de inmediato: prioriza sales/agua/drenaje. '
            'Cl/Na/B son contexto avanzado, no sensores v1. Cuidado con KCl en '
            'ambientes salinos.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalLeafEdgeBurn},
      ),
      PlantHealthDiagnosis(
        id: 'nitrogen_deficiency_or_excess_context',
        labelEs: 'N bajo (hoja pálida) o N alto (puro brote)',
        type: 'abiotic_nutritional_context',
        summaryEs:
            'Amarillamiento uniforme en hoja vieja y bajo vigor pueden ser N '
            'bajo, pero descarta pH alto, sales, raíz dañada y HLB antes de '
            'corregir. Al revés, mucho brote tierno y poca fruta con copa muy '
            'vegetativa apunta a N alto: más N no es más limón y atrae plagas de '
            'brote.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWaterlogging},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El amarillamiento es en hoja NUEVA con nervadura verde (interno) o en '
          'hoja VIEJA generalizado?',
      '¿El suelo es de pH alto/calcáreo o hay salitre/EC alta?',
      '¿El árbol se fue a puro brote tierno con poca fruta (posible N alto)?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: _nutritionActions,
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 11: Frío, calor, viento y granizo ─────────────────────────────
  PlantHealthSyndrome(
    id: 'lemon_cold_heat_wind_stress_01',
    cropId: CropCatalog.lemonTreeCropId,
    labelEs: 'Flor, brote o limón dañado tras calor, frío, viento o granizo',
    stages: _climateStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomCitrusRindScarring,
    strongSignals: <String>{
      PlantHealthIds.signalFrostEvent,
      PlantHealthIds.signalDryHotWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalExposedFruitSouthwest,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'frost_fruit_bloom_damage',
        labelEs: 'Daño por frío/helada en flor, brote o fruta',
        type: 'abiotic_cold',
        summaryEs:
            'Flor/brote quemado, fruta dañada y hoja caída tras helada o aire '
            'frío en zonas bajas. El limón mexicano es especialmente sensible al '
            'frío. Si hubo helada, no culpes al NPK por el bajo amarre: registra '
            'el evento climático.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrostEvent},
      ),
      PlantHealthDiagnosis(
        id: 'wind_hail_scarring_rind',
        labelEs: 'Raspadura por viento / roce / granizo',
        type: 'abiotic_physical',
        summaryEs:
            'Cicatriz superficial lineal o irregular donde la fruta rozó con '
            'rama, espina o por granizo/viento. Es daño físico: sigue el patrón '
            'de roce/exposición; no lo confundas con enfermedad ni con trips.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalExposedFruitSouthwest,
        },
      ),
      PlantHealthDiagnosis(
        id: 'heat_low_humidity_bloom_fruit_stress',
        labelEs: 'Calor + baja humedad en flor/fruto',
        type: 'abiotic_physiological',
        summaryEs:
            'Calor extremo + baja HR seca flor y frutito y puede quemar la '
            'cáscara del lado expuesto. En floración/cuajado tumba amarre aunque '
            'el NPK esté bien. Revisa sombra, copa, riego y defoliación.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El daño empezó después de una helada, frío, calor fuerte, viento o '
          'granizo?',
      '¿La marca sigue el lado expuesto o el patrón de roce?',
      '¿Coincidió con floración/cuajado (etapa más sensible)?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _climateActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _lmModifier(
        profiles: <String>{kLm02MexicanoColima},
        diagnosisId: 'frost_fruit_bloom_damage',
        delta: 6,
        rationale:
            'El limón mexicano es más sensible al frío/helada que otros cítricos '
            '(doc 04 §8).',
      ),
      _lmModifier(
        profiles: <String>{kLm03AmarilloEurekaLisbon},
        diagnosisId: 'frost_fruit_bloom_damage',
        delta: 7,
        rationale:
            'El amarillo/Eureka-Lisbon es sensible a heladas/frío (doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 12: Postcosecha y memoria perenne ─────────────────────────────
  PlantHealthSyndrome(
    id: 'lemon_postharvest_memory_01',
    cropId: CropCatalog.lemonTreeCropId,
    labelEs: 'Árbol cansado tras cortes, baja hoja o siguiente floración débil',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organRoot,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomLateDefoliation,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalSalinityLoad,
    },
    weakSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'post_harvest_leaf_loss_memory',
        labelEs: 'Pérdida de hoja después de corte',
        type: 'memory_physiological',
        summaryEs:
            'Árbol cansado, baja hoja, brote débil y poca flor siguiente tras '
            'carga alta, cosecha larga, estrés hídrico, sales, plagas, HLB o '
            'Phytophthora. La cosecha NO cierra el cultivo: guarda la memoria '
            'para la siguiente floración y el calibre.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
      PlantHealthDiagnosis(
        id: 'repeated_flush_reserve_depletion_memory',
        labelEs: 'Muchos brotes/cortes, árbol cansado',
        type: 'memory_physiological',
        summaryEs:
            'Brotes/flor/fruta disparejos, baja continuidad y calibre variable '
            'por floraciones/cosechas repetidas con N/agua mal balanceados y '
            'baja hoja. La producción continua exige hoja y raíz: si el árbol se '
            'fuerza sin reservas, baja calibre y amarre. Pesa en tropical y '
            'desfase.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
      PlantHealthDiagnosis(
        id: 'post_harvest_root_salinity_memory',
        labelEs: 'Raíz/sales arrastradas después de corte',
        type: 'memory_soil',
        summaryEs:
            'Si la EC quedó alta al cierre, con riego irregular o exceso de '
            'fertilizante, el siguiente flush/floración puede salir débil, con '
            'clorosis y caída temprana. Cuida sales, riego y raíz en '
            'postcosecha/reposo relativo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'hlb_chronic_decline_memory',
        labelEs: 'Decaimiento crónico (HLB/región como memoria)',
        type: 'memory_regulated_context',
        summaryEs:
            'Copa sectorizada, fruta chica/deforme, muerte de ramas y bajo '
            'calibre que se arrastra ciclo a ciclo. BIO-G no cierra HLB: lo '
            'guarda como memoria de región/árbol, baja la confianza del NPK y '
            'pide confirmación. Fertilizar no cura el HLB.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalVectorPresent},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Después de cortar quedó cansado o tiró hoja?',
      '¿La siguiente floración salió débil o trajo muchos cortes seguidos y '
          'luego bajó calibre?',
      '¿La EC/sales quedaron altas al cierre del ciclo?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _memoryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _lmModifier(
        profiles: <String>{kLm04TropicalContinuo, kLm05DesfaseInducido},
        diagnosisId: 'repeated_flush_reserve_depletion_memory',
        delta: 8,
        rationale:
            'Tropical/continuo y desfase con cortes/floraciones repetidas agotan '
            'más reservas (doc 04 §5.10, §8).',
      ),
    ],
  ),
];
