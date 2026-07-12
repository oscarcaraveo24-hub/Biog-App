import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo de riesgos / sanidad vegetal del Mango (`crop_mango_tree`).
///
/// Alimentado por el documento oficial
/// `04_Riesgos_Cultivo_Sanidad_Estres_Memoria_BioG_Mango_MG_v1`.
///
/// Reglas no negociables (doc 04 §0, §13):
/// - BIO-G ORIENTA, no diagnostica de forma absoluta: "condición favorable a…",
///   "revisa…", "síntomas compatibles con…", "confirma si avanza…".
/// - NO receta plaguicidas, ingredientes activos ni dosis.
/// - NO diagnostica antracnosis, cenicilla, malformación, mosca de fruta,
///   stem-end rot ni mancha bacteriana de forma cerrada: eleva cautela y pide
///   confirmación con técnico/sanidad local.
/// - La NO floración es un estado válido, NO un error del motor. La inducción no
///   se convierte en receta de estrés hídrico/PBZ/nitratos (doc 04 §0, §5.1).
/// - El perfil MG solo modifica sensibilidad/mensajes (varietyModifiers); el
///   catálogo base es el mismo para todas las variedades.
/// - Árbol perenne tropical con MEMORIA fuerte de 1-2 ciclos: inducción,
///   floración, cuajado, llenado y postcosecha se encadenan (doc 04 §7). Las
///   etapas `dormancy` y `post_harvest` NO apagan la sanidad (memoria y
///   siguiente floración; doc 04 §2.3).
///
/// El mango NO es limón, NO es naranjo y NO es manzano (doc 04 §0): reusa IDs
/// GENÉRICOS de `PlantHealthIds` (doc 04 §2.2), pero el copy, diagnósticos
/// probables y memoria son de mango (antracnosis/cenicilla de panícula, mosca de
/// la fruta, malformación, alternancia). NO se copia el catálogo de otro árbol
/// cambiando nombres.

// Inducción / reposo / no-floración: dormancy y postcosecha (lateSeason) +
// vegetativo (doc 04 §3 Familia 1, §5.1).
const Set<PlantHealthStageBucket> _inductionStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.lateSeason,
};

// Floración y cuajado: panícula, cenicilla, antracnosis temprana, caída de flor
// y frutito (doc 04 §5.1, §5.2).
const Set<PlantHealthStageBucket> _bloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

// Raíz/suelo/salinidad: pesa en todo el ciclo, fuerte en establecimiento y
// reproducción (doc 04 §6, Familia 10). Incluye lateSeason para que dormancy/
// postcosecha no queden apagadas.
const Set<PlantHealthStageBucket> _rootStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Fruto/cáscara/mosca de fruta: llenado, madurez y poscosecha (doc 04 §5.3,
// §5.5, §6).
const Set<PlantHealthStageBucket> _fruitStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Chupadores, escamas, fumagina y ácaros: hoja funcional todo el ciclo (doc 04
// §3 Familia 7).
const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Trips/ácaros/cicatriz: brote, flor y fruto pequeño (doc 04 §3 Familia 6).
const Set<PlantHealthStageBucket> _scarringStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

// Malformación/muerte de ramas/madera: brote, panícula y copa (doc 04 §5.4).
const Set<PlantHealthStageBucket> _woodStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.lateSeason,
};

// Poscosecha/pudriciones de fruto: madurez y postcosecha (doc 04 §5.5).
const Set<PlantHealthStageBucket> _postharvestFruitStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    };

// Clima/fitotoxicidad: brote, flor y fruto en casi todo el ciclo (doc 04 §6,
// Familia 11).
const Set<PlantHealthStageBucket> _weatherStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Memoria/alternancia/postcosecha: cierre y arranque del siguiente ciclo
// (doc 04 §7, Familia 12).
const Set<PlantHealthStageBucket> _memoryStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.lateSeason,
};

const String _disclaimer =
    'Orientación de riesgo, no diagnóstico definitivo. BIO-G sugiere revisar, '
    'comparar y confirmar en campo o con asesoría/sanidad local si el daño '
    'avanza. No prescribe plaguicidas ni ingredientes activos. Antracnosis, '
    'cenicilla, malformación, mosca de la fruta, stem-end rot y mancha '
    'bacteriana requieren confirmación técnica; no se cierran por sensor.';

const List<String> _inductionActions = <String>[
  'No todo mango florece por calendario. Revisa si el árbol trae brote maduro, '
      'si hubo clima fresco/seco y si no se fue a puro follaje. La ausencia de '
      'flor puede ser un estado válido.',
  'Si el árbol es joven, no lo castigues por no producir. Si ya es productivo y '
      'no floreó, guarda memoria de clima, poda, riego, N y cosecha anterior.',
  'No conviertas el estrés hídrico en receta: un estrés leve puede inducir, '
      'pero si se pasa tira flor y frutito. BIO-G no receta PBZ/nitratos.',
];

const List<String> _panicleDiseaseActions = <String>[
  'Revisa la panícula: polvillo blanco (cenicilla), puntos negros, flores secas '
      'o panícula ennegrecida (antracnosis).',
  'Si hubo lluvia, rocío o humedad alta en floración, sube el riesgo de '
      'antracnosis/cenicilla y baja la confianza de que el problema sea solo '
      'NPK. No culpes al fertilizante de entrada.',
  'No diagnostiques con una foto suelta. Compara panículas sanas y dañadas, '
      'revisa el clima de rocío y confirma con técnico si avanza.',
];

const List<String> _setDropActions = <String>[
  'Algo de caída de flor/manguito puede ser normal. Se vuelve alerta si la '
      'caída es fuerte o coincide con calor, frío, lluvia, humedad baja, sales o '
      'panícula enferma.',
  'En cuajado, primero agua estable, panícula sana y raíz funcional. Luego '
      'revisa K/N/P; el manguito no se sostiene con puro fertilizante.',
  'Registra la caída fuerte como memoria: puede explicar baja cosecha y '
      'alternancia del siguiente ciclo.',
];

const List<String> _rootWaterActions = <String>[
  'Revisa humedad, drenaje, sales y raíz antes de meter más fertilizante.',
  'Marchitez con suelo húmedo NO es falta de agua: puede ser raíz sin aire, '
      'encharcamiento o compactación. No riegues más ni fertilices fuerte.',
  'Si la EC está alta, BIO-G bloquea recomendaciones agresivas de NPK: primero '
      'sales, agua, drenaje y raíz. El mango sensible a sales pierde cuajado y '
      'calibre.',
];

const List<String> _fruitFlyActions = <String>[
  'Abre varias frutas sospechosas. Busca larvas, galerías o picaduras.',
  'Si hay larvas o campaña regional de mosca de la fruta, confirma con sanidad '
      'local / Junta / SENASICA. No muevas fruta sospechosa sin seguir reglas '
      'locales.',
  'El sensor NO detecta la mosca de la fruta. Esto se confirma con muestreo, '
      'trampeo o fruta abierta, no por NPK.',
];

const List<String> _suckerActions = <String>[
  'La negrilla (fumagina) es CONSECUENCIA de la mielecilla. Busca escamas, '
      'cochinillas, saltahojas, pulgones o mosca blanca en el envés.',
  'Revisa hormigas: muchas veces protegen a los chupadores que dejan la miel.',
  'Si cubre mucha hoja o fruta, registra la pérdida de fotosíntesis/calidad '
      'como memoria del ciclo.',
];

const List<String> _thripsMiteActions = <String>[
  'Raspado plateado/bronceado en fruto pequeño apunta a trips, ácaros o '
      'roce/viento; revisa flor, cáliz, envés y brote nuevo.',
  'El daño temprano queda marcado hasta la cosecha: guárdalo como riesgo de '
      'calidad, no esperes al corte.',
  'Con polvo + calor + bronceado, revisa ácaros y estrés hídrico juntos.',
];

const List<String> _malformationDiebackActions = <String>[
  'Panículas tipo escoba o brotes deformes NO son floración normal. Toma foto, '
      'compara árboles y confirma con técnico.',
  'Si hay ramas secándose, revisa heridas de poda, estrés hídrico, cancro, raíz '
      'y patógenos de madera; no lo resuelvas con NPK.',
  'La malformación y la muerte regresiva tienen memoria muy alta: regístralas '
      'para el siguiente ciclo.',
];

const List<String> _fruitQualityActions = <String>[
  'Fruta chica/rajada/quemada suele venir de agua irregular, calor, sales, '
      'defoliación o K bloqueado; revisa el patrón de riego antes de culpar un '
      'hongo.',
  'Si el K sale bajo pero falta agua o hay EC alta, primero corrige la '
      'absorción: el mango no toma bien el K con la raíz estresada.',
  'Revisa la orientación del daño: el golpe de sol suele estar del lado '
      'expuesto (sur/oeste).',
];

const List<String> _postharvestDecayActions = <String>[
  'Si la pudrición empieza por el pedúnculo, separa el stem-end rot de la '
      'antracnosis y de la mosca de la fruta.',
  'La antracnosis puede ser latente: el fruto se ve bien en el árbol y se mancha '
      'al madurar. Registra el clima húmedo del ciclo.',
  'Guarda el daño poscosecha como memoria de calidad y de manejo de corte.',
];

const List<String> _weatherDamageActions = <String>[
  'Cruza el síntoma con el clima y las aplicaciones recientes: granizo, viento, '
      'sol, frío, calor o mezcla de aspersión.',
  'No diagnostiques hongo si el patrón sigue la línea de aspersión, el lado '
      'soleado o un evento de granizo.',
  'Registra el evento: en floración/cuajado puede explicar la baja carga sin '
      'que falte fertilizante.',
];

const List<String> _memoryActions = <String>[
  'La postcosecha NO cierra el mango: es cuando el árbol repone reservas para '
      'inducir o sostener la siguiente floración. No apagues el seguimiento.',
  'Si hubo carga alta, caída fuerte, defoliación, sales, antracnosis/cenicilla o '
      'estrés hídrico, guarda la memoria para el próximo ciclo.',
  'La alternancia no se fuerza, pero se registra: un año muy cargado o muy '
      'estresado puede bajar el siguiente.',
];

/// Modificador de sensibilidad por perfil MG (doc 04 §8).
VarietyModifier _mgModifier({
  required Set<String> profiles,
  required String diagnosisId,
  required int delta,
  required String rationale,
  bool requiresCaution = false,
}) => VarietyModifier(
  cropId: CropCatalog.mangoTreeCropId,
  varietyIds: profiles,
  diagnosisIds: <String>{diagnosisId},
  scoreDelta: delta,
  rationaleEs: rationale,
  isProxy: true,
  requiresCaution: requiresCaution,
);

/// Catálogo de síndromes del mango. `final` (no `const`) por los modificadores
/// por perfil MG construidos con [_mgModifier].
final List<PlantHealthSyndrome> mangoTreeSyndromes = <PlantHealthSyndrome>[
  // ── Familia 1: Inducción floral, reposo funcional y no-floración ──────────
  PlantHealthSyndrome(
    id: 'mango_induction_no_flowering_01',
    cropId: CropCatalog.mangoTreeCropId,
    labelEs: 'Mango con poco brote floral, puro follaje o sin panícula',
    stages: _inductionStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalLateGreenExcessVigor,
      PlantHealthIds.signalRecentStress,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHighPhCalcareous,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalHeatStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'poor_flower_induction_context',
        labelEs: 'No indujo flor / baja probabilidad de floración',
        type: 'physiological_context',
        summaryEs:
            'Mucho follaje, brote nuevo y poca o nada de panícula: árbol sano '
            'pero sin flor. Puede deberse a ciclo previo cálido, exceso de brote '
            'vegetativo, brote joven, exceso de N, poda tardía, postcosecha '
            'débil o alternancia tras un año cargado. La NO floración es un '
            'estado válido: no es falla automática ni falta de fertilizante.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalLateGreenExcessVigor,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nitrogen_excess_vegetative_flush_context',
        labelEs: 'Puro follaje y poca flor (N alto / vigor)',
        type: 'abiotic_nutritional_context',
        summaryEs:
            'Brote tierno abundante, copa muy vegetativa y floración débil con N '
            'alto, poda o riego fuerte y baja carga. En mango, N alto no siempre '
            'es bueno: puede frenar la inducción y mandar el árbol a puro brote. '
            'Más N no es más mango.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalLateGreenExcessVigor,
        },
      ),
      PlantHealthDiagnosis(
        id: 'warm_winter_no_induction_context',
        labelEs: 'Invierno/ciclo cálido sin disparo de floración',
        type: 'climate_context',
        summaryEs:
            'Sin periodo fresco/seco de preparación, el mango adulto puede no '
            'inducir flor. BIO-G evalúa condiciones favorables, no promete '
            'fechas ni convierte el clima en receta.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHeatStress},
      ),
      PlantHealthDiagnosis(
        id: 'postharvest_reserve_depletion_context',
        labelEs: 'Postcosecha débil / reservas agotadas',
        type: 'memory_physiological',
        summaryEs:
            'Árbol cansado tras carga alta, defoliación o estrés, con brote '
            'débil y poca panícula el ciclo siguiente. La postcosecha define la '
            'siguiente floración: si no recuperó hoja/raíz/reservas, puede entrar '
            'bajo. No se arregla solo con NPK.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El árbol trae panículas/flor o solo brote nuevo y hoja?',
      '¿Se fue a puro follaje o metiste N/poda/riego fuerte antes de la '
          'floración?',
      '¿El año pasado cargó mucho o quedó estresado/defoliado en postcosecha?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _inductionActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _mgModifier(
        profiles: <String>{kMg05CriolloRegional},
        diagnosisId: 'poor_flower_induction_context',
        delta: 5,
        rationale:
            'El criollo/regional tiene floración y alternancia más variables '
            '(doc 04 §8).',
      ),
      _mgModifier(
        profiles: <String>{kMg02TommyAtkins},
        diagnosisId: 'nitrogen_excess_vegetative_flush_context',
        delta: 5,
        rationale:
            'Tommy Atkins puede irse a exceso vegetativo por N y retrasar '
            'floración (doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 2: Cenicilla y antracnosis de panícula/floración ──────────────
  PlantHealthSyndrome(
    id: 'mango_powdery_anthracnose_panicle_01',
    cropId: CropCatalog.mangoTreeCropId,
    labelEs: 'Panícula con polvillo blanco, puntos negros o flores secándose',
    stages: _bloomStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomPowderyGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalHumidWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalFlowerDrop,
      PlantHealthIds.signalDenseWetCanopy,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'mango_powdery_mildew_panicle',
        labelEs: 'Cenicilla / oídio en panícula',
        scientificName: 'Oidium mangiferae',
        type: 'fungus',
        summaryEs:
            'Polvillo blanco/gris en panículas, flores que se secan, panícula '
            'oscura y cuajado bajo, favorecido por clima fresco-húmedo, rocío y '
            'copa densa. Polvillo en panícula + flor que cae = riesgo de '
            'cenicilla. No diagnostiques solo por sensor; revisa panícula '
            'completa y clima de rocío.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWhitePowderGrowth},
      ),
      PlantHealthDiagnosis(
        id: 'mango_anthracnose_panicle_blossom',
        labelEs: 'Antracnosis en flor/panícula',
        scientificName: 'Colletotrichum gloeosporioides',
        type: 'fungus',
        summaryEs:
            'Puntos negros en panícula, flores que se ennegrecen, necrosis en '
            'brotes y caída fuerte, favorecido por lluvia, humedad alta, rocío y '
            'copa cerrada. Puede venir desde la flor y reaparecer en poscosecha. '
            'Alta HR + panícula negra + caída = eleva el riesgo; no recetes '
            'fungicida.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'rain_humidity_bloom_disease_context',
        labelEs: 'Lluvia / humedad alta pegando en flor',
        type: 'climate_disease_context',
        summaryEs:
            'Panículas mojadas, flores negras o secas y caída fuerte tras lluvia '
            'fuera de temporada, rocío prolongado o dosel cerrado. Si llovió en '
            'floración, primero sanidad/polinización/amarre; no NPK primero.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalCoolDewyWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La panícula trae polvillo blanco (cenicilla) o puntos negros '
          '(antracnosis)?',
      '¿Hubo lluvia, rocío o humedad alta durante la floración?',
      '¿Las flores se secan o ennegrecen y cae mucho manguito?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _panicleDiseaseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    varietyModifiers: <VarietyModifier>[
      _mgModifier(
        profiles: <String>{kMg01AtaulfoManila},
        diagnosisId: 'mango_anthracnose_panicle_blossom',
        delta: 7,
        rationale:
            'Ataulfo/Manila es sensible a antracnosis en floración/cuajado en el '
            'Pacífico húmedo (doc 04 §8).',
      ),
      _mgModifier(
        profiles: <String>{kMg03Kent, kMg04Keitt},
        diagnosisId: 'mango_anthracnose_panicle_blossom',
        delta: 5,
        rationale:
            'Kent/Keitt tardíos cruzan lluvias y presión de antracnosis '
            '(doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 3: Cuajado, caída de flor y manguito ──────────────────────────
  PlantHealthSyndrome(
    id: 'mango_fruit_set_drop_01',
    cropId: CropCatalog.mangoTreeCropId,
    labelEs: 'Mucha flor, poco amarre o manguitos cayendo',
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
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'mango_fruit_set_drop_complex',
        labelEs: 'No amarró / se cayó el manguito',
        type: 'abiotic_physiological',
        summaryEs:
            'Floreó mucho pero quedaron pocos frutos; manguitos amarillos o '
            'negros que caen y panículas vacías. Puede venir de antracnosis, '
            'cenicilla, lluvia, calor, frío, estrés hídrico, exceso de agua, '
            'baja hoja, mala polinización, salinidad o alternancia. No culpes de '
            'entrada al fertilizante.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFlowerDrop},
      ),
      PlantHealthDiagnosis(
        id: 'physiological_fruit_drop_context',
        labelEs: 'Caída fisiológica normal de manguito',
        type: 'physiological_context',
        summaryEs:
            'Muchos manguitos pequeños caen pero quedan algunos sanos, sin '
            'síntomas fuertes de estrés. Algo de caída es regulación natural de '
            'carga. Alertar solo si es excesiva o coincide con clima/sanidad/'
            'agua baja.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFlowerDrop},
      ),
      PlantHealthDiagnosis(
        id: 'drought_heat_set_loss',
        labelEs: 'Falta de agua / calor en cuajado',
        type: 'abiotic_physiological',
        summaryEs:
            'Frutito amarillo, caída, hojas con baja turgencia y suelo seco con '
            'humedad baja, calor, viento seco o salinidad. En cuajado el agua '
            'estable pesa más que el NPK: si la humedad está baja, no recomiendes '
            'K/N primero.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
      PlantHealthDiagnosis(
        id: 'pollination_or_flower_balance_context',
        labelEs: 'Floración abundante pero poco fruto',
        type: 'physiological_context',
        summaryEs:
            'Muchas flores, poco amarre y panículas vacías sin pudrición clara, '
            'por poca actividad de insectos, lluvia/viento, clima extremo o '
            'competencia vegetativa. Mucha flor no significa cosecha: revisa '
            'clima, polinizadores y sanidad de la panícula.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Floreó mucho pero amarró poco o se cae el mango chiquito?',
      '¿La caída coincide con calor, frío, lluvia, humedad baja o sales?',
      '¿Los manguitos se ponen amarillos/negros antes de caer?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _setDropActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _mgModifier(
        profiles: <String>{kMg01AtaulfoManila},
        diagnosisId: 'mango_fruit_set_drop_complex',
        delta: 8,
        rationale:
            'Ataulfo/Manila concentra riesgo de aborto floral y caída de frutito '
            '(doc 04 §8, §9 síndrome 3).',
      ),
      _mgModifier(
        profiles: <String>{kMg04Keitt},
        diagnosisId: 'drought_heat_set_loss',
        delta: 4,
        rationale:
            'Keitt, con llenado largo, acumula estrés hídrico que golpea el '
            'amarre (doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 4: Raíz, suelo, salinidad, pH, compactación y anoxia ──────────
  PlantHealthSyndrome(
    id: 'mango_root_water_salinity_01',
    cropId: CropCatalog.mangoTreeCropId,
    labelEs: 'Árbol triste con suelo seco, saturado, sales o raíz limitada',
    stages: _rootStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalSalinityLoad,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalHighPhCalcareous,
      PlantHealthIds.signalLeafEdgeBurn,
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'root_rot_waterlogging_context',
        labelEs: 'Raíz asfixiada / exceso de humedad',
        type: 'abiotic_soil',
        summaryEs:
            'Marchitez con suelo húmedo, raíz oscura, bajo vigor, hoja amarilla '
            'y caída de fruto tras encharque, lluvia prolongada, riego excesivo o '
            'compactación. El mango no tolera raíz sin aire: no pidas más agua si '
            'el suelo ya está saturado.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWaterlogging},
      ),
      PlantHealthDiagnosis(
        id: 'salinity_root_stress_context',
        labelEs: 'Sales / salinidad frenando el mango',
        type: 'abiotic_soil',
        summaryEs:
            'Borde de hoja quemado, baja brotación, fruta chica, caída y árbol '
            '"sediento" aunque se riegue, con EC alta, riego de pozo o drenaje '
            'pobre. Si la EC está alta, BIO-G bloquea recomendaciones agresivas '
            'de NPK: primero agua, sales, drenaje y raíz.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'soil_compaction_root_stress',
        labelEs: 'Compactación / raíz sin aire',
        type: 'abiotic_soil',
        summaryEs:
            'Charcos, raíz superficial, bajo vigor por líneas y respuesta pobre '
            'a riego/fertilizante. Resistencia alta + bajo vigor = suelo/raíz '
            'primero, NPK después.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRootsDarkRot},
      ),
      PlantHealthDiagnosis(
        id: 'high_ph_micronutrient_context',
        labelEs: 'pH alto / clorosis / micros bloqueados',
        type: 'abiotic_nutritional_context',
        summaryEs:
            'Hoja nueva amarilla con nervadura verde, brote corto y hoja chica '
            'en suelos calizos, agua dura o pH alto. No es N automático: '
            'Fe/Zn/Mn/Mg/B/Ca son contexto avanzado, no sensores v1. Confirma con '
            'análisis foliar.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHighPhCalcareous},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La marchitez ocurre con suelo húmedo (no seco)?',
      '¿El agua deja salitre/costra blanca o el árbol se ve "sediento" aunque se '
          'riegue?',
      '¿El suelo se encharca, se pone duro o la hoja nueva sale amarilla con '
          'nervadura verde?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootWaterActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _mgModifier(
        profiles: <String>{kMg01AtaulfoManila},
        diagnosisId: 'salinity_root_stress_context',
        delta: 4,
        rationale:
            'La salinidad castiga fuerte el cuajado/calibre premium del Ataulfo '
            '(doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 5: Mosca de la fruta y riesgos regulados/comerciales ──────────
  PlantHealthSyndrome(
    id: 'mango_fruit_fly_quarantine_01',
    cropId: CropCatalog.mangoTreeCropId,
    labelEs: 'Mango con picaduras, larvas o riesgo de mosca de la fruta',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    },
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFruitTunnelFrass,
    strongSignals: <String>{
      PlantHealthIds.signalFruitLarvae,
      PlantHealthIds.signalFrassPresent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWhiteGreenBlueMold,
      PlantHealthIds.signalFruitLowCanopyRainSplash,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'anastrepha_fruit_fly_context',
        labelEs: 'Mosca de la fruta en mango (regulada/comercial)',
        scientificName: 'Anastrepha spp.',
        type: 'insect_regulated_context',
        summaryEs:
            'Picaduras, larvas dentro de la fruta, pudrición secundaria y fruta '
            'caída en fruta madura/sobremadura, con presión regional o campaña. '
            'No se diagnostica por sensor ni por una mancha superficial: se '
            'confirma con fruta abierta, larvas y trampeo. Si hay campaña, sigue '
            'a sanidad local.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFruitLarvae},
      ),
      PlantHealthDiagnosis(
        id: 'fruit_borer_seed_weevil_context',
        labelEs: 'Barrenador / picudo del fruto o semilla',
        type: 'insect_context',
        summaryEs:
            'Orificio, frass/aserrín, túneles, semilla dañada o larva interna en '
            'fruta en desarrollo o abandonada. Abre muestra: no lo confundas con '
            'la mosca de la fruta sin ver larva, picadura o patrón.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrassPresent},
      ),
      PlantHealthDiagnosis(
        id: 'postharvest_decay_secondary_context',
        labelEs: 'Pudrición secundaria de fruta dañada',
        type: 'fungus_context',
        summaryEs:
            'Moho y pudrición blanda alrededor de picaduras/heridas en fruta '
            'madura o caída. Suele ser consecuencia del daño de insecto o del '
            'manejo, no la causa primaria. Revisa la herida original.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWhiteGreenBlueMold},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay larvas o picaduras al abrir varias frutas?',
      '¿La región tiene campaña/trampeo de mosca de la fruta activo?',
      '¿La fruta está madura/sobremadura o caída en el suelo?',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.immediate,
    baseActionsEs: _fruitFlyActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
    varietyModifiers: <VarietyModifier>[
      _mgModifier(
        profiles: <String>{kMg04Keitt},
        diagnosisId: 'anastrepha_fruit_fly_context',
        delta: 8,
        rationale:
            'Keitt, muy tardío, deja fruta madura más tiempo en árbol y sube el '
            'riesgo de mosca de la fruta (doc 04 §8, §9 síndrome 5).',
      ),
      _mgModifier(
        profiles: <String>{kMg03Kent},
        diagnosisId: 'anastrepha_fruit_fly_context',
        delta: 6,
        rationale:
            'Kent tardío/exportación exige cautela con mosca de la fruta '
            '(doc 04 §8).',
      ),
      _mgModifier(
        profiles: <String>{kMg02TommyAtkins},
        diagnosisId: 'anastrepha_fruit_fly_context',
        delta: 5,
        rationale: 'Tommy de exportación/volumen: mosca de fruta comercial '
            '(doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 6: Chupadores, escamas, fumagina y ácaros ─────────────────────
  PlantHealthSyndrome(
    id: 'mango_scale_sooty_mold_suckers_01',
    cropId: CropCatalog.mangoTreeCropId,
    labelEs: 'Mielecilla, negrilla, escamas/cochinillas o chupadores',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFruit,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomHoneydewSootyShoots,
    strongSignals: <String>{
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCannotScrapeOff,
      PlantHealthIds.signalWhiteflyCloud,
      PlantHealthIds.signalDenseWetCanopy,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'mango_scale_mealybug_complex',
        labelEs: 'Escamas / cochinillas / piojo harinoso',
        type: 'insect',
        summaryEs:
            'Costras pegadas que no se raspan, masas algodonosas, mielecilla y '
            'fumagina en copa densa, con hormigas y baja ventilación. Si la '
            'costra no se raspa, piensa en escama; la fumagina es consecuencia, '
            'busca el chupador.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalCannotScrapeOff},
      ),
      PlantHealthDiagnosis(
        id: 'sooty_mold_honeydew_complex',
        labelEs: 'Fumagina / negrilla por mielecilla',
        type: 'fungus_secondary',
        summaryEs:
            'Capa negra superficial que se raspa, hoja/fruto pegajoso, causada '
            'por cochinillas, escamas, pulgones, saltahojas o mosca blanca. No '
            'la trates como hongo principal: busca el insecto que produce la '
            'miel.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSootyMold},
      ),
      PlantHealthDiagnosis(
        id: 'mango_hopper_cicadellid_context',
        labelEs: 'Saltahojas / cicadélidos en panícula',
        type: 'insect',
        summaryEs:
            'Insectitos saltadores en panícula/envés, mielecilla, fumagina y '
            'flores marchitas o caídas en panículas tiernas. Si hay mielecilla/'
            'negrilla en panícula, busca chupadores antes que hongo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWhiteflyCloud},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La hoja/fruta está pegajosa y con tizne negro (negrilla)?',
      '¿Hay costras que no se raspan, algodón blanco o mosquita blanca en el '
          'envés?',
      '¿Hay hormigas subiendo por el tronco cuidando chupadores?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _suckerActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),

  // ── Familia 7: Trips, ácaros, raspado y cicatriz de flor/fruto ────────────
  PlantHealthSyndrome(
    id: 'mango_thrips_mites_scarring_01',
    cropId: CropCatalog.mangoTreeCropId,
    labelEs: 'Raspado, bronceado o cicatriz en flor/fruto/hoja',
    stages: _scarringStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomThripsSilverScarring,
    strongSignals: <String>{
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalThripsSilverScarring,
    },
    weakSignals: <String>{
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalExposedFruitSouthwest,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'mango_thrips_flower_fruit_scarring',
        labelEs: 'Trips / raspado en flor o mango chico',
        type: 'insect',
        summaryEs:
            'Raspado plateado/bronceado y cicatrices en fruto joven cerca del '
            'cáliz, con flor lastimada, en clima seco-cálido. La marca nace desde '
            'el fruto pequeño: revisa trips/viento/roce, no esperes a la cosecha.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalThripsSilverScarring,
        },
      ),
      PlantHealthDiagnosis(
        id: 'mango_mites_bronzing_context',
        labelEs: 'Ácaros / bronceado / punteado fino',
        type: 'mite',
        summaryEs:
            'Hoja bronceada, punteado, telaraña fina y fruto con russeting en '
            'calor seco, polvo, estrés hídrico y baja fauna benéfica. Polvo + '
            'calor + bronceado = revisa ácaros y estrés hídrico juntos.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalMitesWebbing},
      ),
      PlantHealthDiagnosis(
        id: 'wind_rub_mechanical_scarring',
        labelEs: 'Raspadura por viento / roce',
        type: 'abiotic_physical',
        summaryEs:
            'Cicatriz superficial lineal donde el fruto rozó con rama o por '
            'viento. Es daño físico y sigue el patrón de roce/exposición; no lo '
            'confundas con trips ni con enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalExposedFruitSouthwest,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El raspado plateado/bronceado está cerca del cáliz o en la flor?',
      '¿Hay telaraña fina, punteado y polvo con calor seco (ácaros)?',
      '¿La cicatriz sigue el patrón de roce con ramas o viento?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _thripsMiteActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _mgModifier(
        profiles: <String>{kMg02TommyAtkins, kMg03Kent},
        diagnosisId: 'mango_thrips_flower_fruit_scarring',
        delta: 4,
        rationale:
            'En exportación la cicatriz de trips demerita calidad externa '
            '(doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 8: Malformación, muerte regresiva y madera/vivero ─────────────
  PlantHealthSyndrome(
    id: 'mango_malformation_dieback_01',
    cropId: CropCatalog.mangoTreeCropId,
    labelEs: 'Panícula tipo escoba, brote deforme o ramas secándose',
    stages: _woodStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomShootDecayCanker,
    strongSignals: <String>{
      PlantHealthIds.signalStemCanker,
      PlantHealthIds.signalShootTipWilt,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalHighPhCalcareous,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'mango_malformation_floral_vegetative',
        labelEs: 'Malformación de mango / panícula tipo escoba',
        scientificName: 'Fusarium spp. (complejo)',
        type: 'fungus_complex_context',
        summaryEs:
            'Panículas compactas/deformes tipo escoba, brotes vegetativos '
            'deformes y floración anormal que no amarra, ligadas a material de '
            'vivero infectado, ácaros como contexto e historial de huerto. No lo '
            'confundas con mucha flor normal; si se repite, registra memoria y '
            'pide confirmación técnica. No se resuelve con NPK.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalShootTipWilt},
      ),
      PlantHealthDiagnosis(
        id: 'dieback_canker_lasiodiplodia_context',
        labelEs: 'Muerte regresiva / cancro / ramas secándose',
        scientificName: 'Lasiodiplodia / Botryosphaeriaceae',
        type: 'fungus_wood_context',
        summaryEs:
            'Ramas secas desde la punta, cancro, goma/exudado y muerte de brotes '
            'tras estrés hídrico, heridas de poda, golpe de sol o árboles '
            'debilitados. La muerte de rama no es NPK: revisa poda, heridas, '
            'estrés, raíz y patógenos de madera.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalStemCanker},
      ),
      PlantHealthDiagnosis(
        id: 'nursery_material_problem_context',
        labelEs: 'Planta de vivero / injerto / raíz mal lograda',
        type: 'establishment_context',
        summaryEs:
            'Árbol que no arranca, brote débil, cuello/injerto raro, raíz '
            'deformada o clorosis temprana con material no certificado. Si falla '
            'desde el inicio y los sensores no lo explican, pregunta por el '
            'origen de la planta, la raíz y el injerto.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay panículas compactas tipo escoba o brotes deformes que no amarran?',
      '¿Hay ramas que se secan desde la punta, cancro o goma?',
      '¿El problema viene desde plantación (vivero/injerto/raíz)?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _malformationDiebackActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),

  // ── Familia 9: Calibre, rajado, sol y desórdenes de fruto ─────────────────
  PlantHealthSyndrome(
    id: 'mango_fruit_quality_abiotic_01',
    cropId: CropCatalog.mangoTreeCropId,
    labelEs: 'Mango chico, rajado, quemado o con calidad débil',
    stages: _fruitStages,
    organIds: <String>{
      PlantHealthIds.organFruit,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFruitSunburnPatch,
    strongSignals: <String>{
      PlantHealthIds.signalFruitSplitAfterIrrigation,
      PlantHealthIds.signalExposedFruitSouthwest,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalLeafEdgeBurn,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'fruit_splitting_irrigation_context',
        labelEs: 'Mango rajado / partido',
        type: 'abiotic_physiological',
        summaryEs:
            'Grietas en el fruto por riego irregular (seco y luego mucha agua), '
            'sequía seguida de riego/lluvia, calor o cáscara débil. Revisa el '
            'riego irregular antes de culpar a un hongo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalFruitSplitAfterIrrigation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sunburn_heat_fruit_context',
        labelEs: 'Golpe de sol / fruta quemada',
        type: 'abiotic_physical',
        summaryEs:
            'Parche claro/café seco del lado expuesto (sur/oeste) por calor, '
            'fruta expuesta, poda fuerte o defoliación. Si el daño está del lado '
            'expuesto, no lo confundas con pudrición o plaga.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalExposedFruitSouthwest,
        },
      ),
      PlantHealthDiagnosis(
        id: 'potassium_low_fruit_quality_context',
        labelEs: 'K bajo / calibre-calidad débil',
        type: 'abiotic_nutritional_context',
        summaryEs:
            'Fruta chica, bajo calibre, maduración débil y caída con carga alta, '
            'K bajo/bloqueado, salinidad o raíz mala. El K pesa en llenado, pero '
            'si hay agua baja o EC alta, primero corrige la absorción; no subas K '
            'con sales altas.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'internal_breakdown_spongy_tissue_context',
        labelEs: 'Tejido esponjoso / desorden interno',
        type: 'abiotic_physiological',
        summaryEs:
            'Fruta externamente aceptable pero con pulpa interna esponjosa/'
            'oscura, ligada a variedad, madurez/corte, calor y manejo '
            'poscosecha. No siempre se ve por fuera: regístralo como calidad '
            'interna y revisa madurez/temperatura/perfil.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El mango se rajó tras un periodo seco seguido de riego/lluvia?',
      '¿El daño está del lado expuesto al sol (sur/oeste)?',
      '¿El mango sale chico o con calidad débil? ¿Hay carga alta, K bajo o '
          'sales?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _fruitQualityActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _mgModifier(
        profiles: <String>{kMg03Kent, kMg04Keitt},
        diagnosisId: 'potassium_low_fruit_quality_context',
        delta: 5,
        rationale:
            'Kent/Keitt, con llenado largo, dependen de agua y K para el calibre '
            '(doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 10: Poscosecha, stem-end rot y pudriciones de fruto ───────────
  PlantHealthSyndrome(
    id: 'mango_postharvest_decay_01',
    cropId: CropCatalog.mangoTreeCropId,
    labelEs: 'Mango que se pudre al madurar, por pedúnculo o con moho',
    stages: _postharvestFruitStages,
    organIds: <String>{
      PlantHealthIds.organFruit,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomMummifiedFruitRot,
    strongSignals: <String>{
      PlantHealthIds.signalWhiteGreenBlueMold,
      PlantHealthIds.signalHumidWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalFruitLowCanopyRainSplash,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'stem_end_rot_context',
        labelEs: 'Pudrición por pedúnculo / stem-end rot',
        scientificName: 'Lasiodiplodia / Diplodia spp.',
        type: 'fungus',
        summaryEs:
            'Pudrición que inicia desde el pedúnculo y avanza oscura hacia la '
            'pulpa, en fruta aparentemente sana al corte que se pudre después, '
            'por infección latente, estrés del árbol, heridas o mal manejo. Si '
            'arranca del pedúnculo, no es mosca por default.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'anthracnose_fruit_ripening_context',
        labelEs: 'Antracnosis latente en maduración',
        scientificName: 'Colletotrichum spp.',
        type: 'fungus',
        summaryEs:
            'Manchas oscuras hundidas que aparecen al madurar aunque el fruto se '
            'veía sano en árbol, tras humedad/lluvia en el ciclo. La antracnosis '
            'puede ser latente y explotar en maduración/poscosecha. Registra el '
            'clima húmedo y la etapa.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWhiteGreenBlueMold},
      ),
      PlantHealthDiagnosis(
        id: 'postharvest_decay_mold_context',
        labelEs: 'Moho / pudrición poscosecha por herida',
        scientificName: 'Alternaria / Penicillium spp.',
        type: 'fungus',
        summaryEs:
            'Moho blanco/verde/azul y pudrición blanda que crece en almacén, por '
            'golpes, madurez excesiva, heridas o mala ventilación. Es problema '
            'de calidad/poscosecha; no siempre indica enfermedad activa en el '
            'árbol.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La pudrición empieza por el pedúnculo (stem-end rot)?',
      '¿La mancha aparece al madurar aunque el fruto se veía sano en el árbol?',
      '¿El moho arrancó de una herida/golpe de manejo?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _postharvestDecayActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      _mgModifier(
        profiles: <String>{kMg03Kent, kMg04Keitt},
        diagnosisId: 'anthracnose_fruit_ripening_context',
        delta: 5,
        rationale:
            'Kent/Keitt tardíos concentran antracnosis latente y stem-end rot en '
            'poscosecha (doc 04 §8).',
      ),
    ],
  ),

  // ── Familia 11: Fitotoxicidad, clima extremo y daño físico ────────────────
  PlantHealthSyndrome(
    id: 'mango_phytotoxicity_weather_damage_01',
    cropId: CropCatalog.mangoTreeCropId,
    labelEs: 'Quemadura por sol, frío, granizo, aplicación o viento',
    stages: _weatherStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalRecentSprayOilCopper,
      PlantHealthIds.signalUniformLeafBurn,
    },
    weakSignals: <String>{
      PlantHealthIds.signalFrostEvent,
      PlantHealthIds.signalHailEvent,
      PlantHealthIds.signalExposedFruitSouthwest,
      PlantHealthIds.signalColdExposure,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'phytotoxicity_spray_context',
        labelEs: 'Quemadura por aplicación / fitotoxicidad',
        type: 'abiotic_chemical',
        summaryEs:
            'Quemadura uniforme con patrón de aspersión tras mezclas '
            'incompatibles, aplicación con calor o aceite/azufre/cobre/herbicida. '
            'Pregunta por aplicaciones recientes: si el patrón coincide con la '
            'aspersión/deriva, no lo cierres como hongo o plaga.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRecentSprayOilCopper,
        },
      ),
      PlantHealthDiagnosis(
        id: 'cold_frost_bloom_damage',
        labelEs: 'Daño por frío / helada en flor/brote',
        type: 'abiotic_cold',
        summaryEs:
            'Flor negra, panícula quemada, brote dañado y caída tras noche fría, '
            'frente frío o ubicación baja, sobre todo con brote tierno o flor '
            'abierta. Cruza con el evento climático; no diagnostiques NPK.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrostEvent},
      ),
      PlantHealthDiagnosis(
        id: 'hail_wind_mechanical_damage',
        labelEs: 'Granizo / viento / roce',
        type: 'abiotic_physical',
        summaryEs:
            'Heridas lineales, golpes, cicatrices de un lado y hojas rotas tras '
            'tormenta, viento fuerte o granizo. Patrón físico: vigila la entrada '
            'de enfermedades secundarias por las heridas.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHailEvent},
      ),
      PlantHealthDiagnosis(
        id: 'sunburn_heat_leaf_fruit_context',
        labelEs: 'Golpe de sol / calor en hoja y fruto',
        type: 'abiotic_physical',
        summaryEs:
            'Parche seco del lado expuesto y hoja quemada por calor, baja HR, '
            'viento seco, poda fuerte o defoliación. El daño sigue la orientación '
            'expuesta; revisa copa, defoliación y exposición.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalExposedFruitSouthwest,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El daño empezó tras una aplicación (patrón de aspersión/deriva)?',
      '¿Hubo helada, frío, calor fuerte, viento o granizo reciente?',
      '¿La marca sigue el lado expuesto o el patrón de roce/aspersión?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _weatherDamageActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),

  // ── Familia 12: Memoria productiva, alternancia y postcosecha ─────────────
  PlantHealthSyndrome(
    id: 'mango_memory_alternate_bearing_01',
    cropId: CropCatalog.mangoTreeCropId,
    labelEs: 'Árbol cansado, alternancia o postcosecha débil',
    stages: _memoryStages,
    organIds: <String>{
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomLateDefoliation,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalLateGreenExcessVigor,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHighPhCalcareous,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'alternate_bearing_memory',
        labelEs: 'Alternancia productiva (año cargado / año bajo)',
        type: 'memory_physiological',
        summaryEs:
            'Un año muy cargado agota reservas y puede reducir la inducción/'
            'floración del siguiente ciclo. BIO-G registra memoria, no solo la '
            'cosecha actual: si el año pasado cargó mucho y no recuperó, este año '
            'puede entrar bajo. La alternancia no se fuerza, se registra.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalLateGreenExcessVigor,
        },
      ),
      PlantHealthDiagnosis(
        id: 'postharvest_leaf_loss_memory',
        labelEs: 'Postcosecha débil / defoliación',
        type: 'memory_physiological',
        summaryEs:
            'Árbol defoliado, brote débil y poca reserva tras la cosecha, poda '
            'mal hecha, estrés hídrico o sales. La postcosecha define la próxima '
            'inducción/floración: cuida hoja, raíz y reservas antes de forzar '
            'flor.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
      PlantHealthDiagnosis(
        id: 'heavy_crop_reserve_depletion_memory',
        labelEs: 'Carga alta que agotó reservas',
        type: 'memory_physiological',
        summaryEs:
            'Tras un año de carga muy alta el árbol puede quedar cansado, con '
            'menor calibre y floración débil el ciclo siguiente. Traer mucho '
            'mango sube kg pero puede cansar el árbol si no recupera en '
            'postcosecha.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
      PlantHealthDiagnosis(
        id: 'repeated_bloom_failure_memory',
        labelEs: 'Fallas de floración/estrés repetidas',
        type: 'memory_physiological',
        summaryEs:
            'Ciclos seguidos con inducción débil, sales altas al cierre, estrés '
            'hídrico o sanidad de panícula dejan una memoria que arrastra baja '
            'floración y cuajado. Cuida sales, riego, raíz y reservas en '
            'postcosecha/reposo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El año pasado cargó mucho y este viene bajo (alternancia)?',
      '¿Después de cosechar quedó cansado, defoliado o con brote débil?',
      '¿Las sales/EC quedaron altas al cierre del ciclo?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _memoryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _mgModifier(
        profiles: <String>{kMg01AtaulfoManila},
        diagnosisId: 'alternate_bearing_memory',
        delta: 6,
        rationale:
            'Ataulfo/Manila tiene alternancia marcada y sensibilidad de '
            'postcosecha (doc 04 §8).',
      ),
      _mgModifier(
        profiles: <String>{kMg04Keitt},
        diagnosisId: 'heavy_crop_reserve_depletion_memory',
        delta: 5,
        rationale:
            'Keitt, muy tardío, hace pesar más la memoria y la postcosecha '
            '(doc 04 §8).',
      ),
    ],
  ),
];
