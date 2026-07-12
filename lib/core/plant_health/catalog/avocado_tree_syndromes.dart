import 'package:bio_g/core/crops/avocado_tree/avocado_tree_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo de riesgos / sanidad vegetal del Aguacate (`crop_avocado_tree`).
///
/// Alimentado por el documento oficial
/// `04_Riesgos_Cultivo_Sanidad_Estres_Memoria_BioG_Aguacate_AG_v1`.
///
/// Reglas no negociables (doc 04 §0, §12, §13):
/// - BIO-G ORIENTA, no diagnostica de forma absoluta: "condición favorable a…",
///   "síntomas compatibles con…", "revisa…", "confirma con técnico/laboratorio/
///   sanidad local si avanza…".
/// - NO receta plaguicidas, ingredientes activos, fosfitos ni dosis; NO
///   recomienda anillado, estrés hídrico inducido ni reguladores.
/// - Prioridad agronómica (doc 04 §13): 1) raíz/drenaje/Phytophthora/salinidad;
///   2) floración/cuajado/polinización/caída; 3) calidad de fruto (trips/roña/
///   antracnosis/stem-end rot); 4) plagas reglamentadas con cautela oficial;
///   5) memoria de alternancia y postcosecha.
/// - NO diagnostica Phytophthora sólo por sensor: usa contexto raíz/drenaje/
///   humedad/declive. NO diagnostica plagas reglamentadas (barrenadores/
///   palomilla) sin señales físicas y advertencia de sanidad local.
/// - `dormancy` es reposo funcional / preparación floral (el aguacate es
///   SIEMPREVERDE, NO árbol pelón) y `post_harvest` NO cierra el cultivo:
///   memoria y siguiente floración (doc 04 §2.5, §8). El fruto madura para
///   consumo DESPUÉS del corte.
/// - El perfil AG solo modifica sensibilidad/mensajes (varietyModifiers); el
///   catálogo base es el mismo para todas las variedades.
///
/// El aguacate NO es mango, NO es cítrico y NO es manzano (doc 04 §0): reusa IDs
/// GENÉRICOS de `PlantHealthIds` (doc 04 §2.3), pero el copy, diagnósticos
/// probables y memoria son de aguacate (Phytophthora/tristeza, salinidad/
/// cloruros, cuajado A/B, alternancia, sunblotch). NO se copia el catálogo de
/// otro árbol cambiando nombres.
// TODO(plant-health-aguacate): si el equipo amplía PlantHealthIds, migrar a los
// IDs específicos sugeridos en doc 04 §2.4 (symptomAvocadoFineRootRot,
// signalChlorideSodiumBoronRisk, etc.) para mayor precisión.

// Raíz/suelo/salinidad: pesa en TODO el ciclo (doc 04 §5.1, §7). Incluye
// lateSeason para que dormancy/postcosecha no queden apagadas.
const Set<PlantHealthStageBucket> _rootStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Salinidad/cloruros/punta quemada: vegetativo y reproducción + poscosecha
// (doc 04 §5.1, §5.2).
const Set<PlantHealthStageBucket> _salinityStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Floración y cuajado: aborto floral, polinización A/B, caída (doc 04 §5.2).
const Set<PlantHealthStageBucket> _bloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

// Cuajado/caída de frutito: amarre y llenado temprano (doc 04 §5.2).
const Set<PlantHealthStageBucket> _setDropStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

// Chupadores, escamas, fumagina, ácaros y lace bug: hoja funcional (doc 04
// §5.3).
const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Trips/cicatriz: flor y fruto joven (doc 04 §5.3, síndrome 5).
const Set<PlantHealthStageBucket> _scarringStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

// Fruto/roña/cáscara: cuajado, llenado y madurez (doc 04 §5.5).
const Set<PlantHealthStageBucket> _fruitStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Poscosecha/pudriciones de fruto: madurez y postcosecha (doc 04 §5.5).
const Set<PlantHealthStageBucket> _postharvestFruitStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    };

// Barrenadores reglamentados: llenado y madurez/poscosecha (doc 04 §5.4).
const Set<PlantHealthStageBucket> _borerStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Cancro/muerte regresiva/madera: copa y postcosecha (doc 04 §5.5).
const Set<PlantHealthStageBucket> _woodStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Sunblotch/viroide/material crónico (doc 04 §5.5, Familia 10).
const Set<PlantHealthStageBucket> _sunblotchStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Clima extremo/fitotoxicidad: brote, flor y fruto (doc 04 §6, Familia 11).
const Set<PlantHealthStageBucket> _weatherStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Golpe de sol: joven, llenado y madurez (doc 04 §5.6, síndrome 15).
const Set<PlantHealthStageBucket> _sunburnStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

// Frío/helada: brote, flor y cuajado (doc 04 §5.6, síndrome 16).
const Set<PlantHealthStageBucket> _coldStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.lateSeason,
};

// Memoria/alternancia/postcosecha: cierre y arranque del siguiente ciclo
// (doc 04 §8, Familia 12).
const Set<PlantHealthStageBucket> _memoryStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.lateSeason,
};

const String _disclaimer =
    'Orientación de riesgo, no diagnóstico definitivo. BIO-G sugiere revisar, '
    'comparar y confirmar en campo o con asesoría/sanidad local si el daño '
    'avanza. No prescribe plaguicidas ni ingredientes activos, ni recomienda '
    'anillado, estrés hídrico o reguladores. Phytophthora, antracnosis, roña, '
    'sunblotch, stem-end rot y plagas reglamentadas (barrenadores/palomilla) '
    'requieren confirmación técnica; no se cierran por sensor.';

const List<String> _rootPhytophthoraActions = <String>[
  'Revisa drenaje, raíz fina, humedad real y EC/agua antes de meter más '
      'fertilizante. En aguacate un árbol triste con suelo mojado NO pide más '
      'agua: puede ser raíz sin oxígeno o Phytophthora.',
  'Si la raíz no respira, el sensor puede marcar nutrientes pero el árbol no '
      'los toma. Primero drenaje, oxígeno y sales; el NPK espera.',
  'La pudrición de raíz por Phytophthora no se confirma por sensor: cava, '
      'revisa raíces oscuras/ausentes y confirma con técnico/laboratorio.',
];

const List<String> _salinityActions = <String>[
  'Punta y borde de hoja VIEJA quemados pueden ser sales/cloruros/sodio/boro, '
      'no falta de nitrógeno. Revisa EC, agua de riego y drenaje.',
  'Con EC alta, BIO-G bloquea recomendaciones agresivas de NPK: primero agua, '
      'lavado técnico, drenaje y raíz. El sensor no distingue cloruro/sodio/boro.',
  'Si usas fuentes con cloruro y ves borde quemado, revisa sales antes de subir '
      'más potasio. Confirma con análisis foliar/suelo/agua.',
];

const List<String> _bloomSetActions = <String>[
  'En aguacate mucha flor NO es cosecha: menos de una fracción pequeña llega a '
      'fruto. Revisa polinización (tipo A/B), abejas, clima, agua y raíz antes '
      'de culpar al fertilizante.',
  'Si hubo calor seco, frío, viento o lluvia en floración, el problema va ANTES '
      'que el NPK. Un tipo B compatible cerca puede ayudar SI coincide la '
      'floración y hay abejas, pero no es requisito universal.',
  'No conviertas la floración fuera de temporada («flor loca») en promesa de '
      'cosecha: puede tirar fruta. Guarda memoria del evento.',
];

const List<String> _setDropActions = <String>[
  'Algo de caída de frutito es fisiológico. Se vuelve alerta si es masiva, '
      'repetida o coincide con calor, sales (EC alta), agua baja/alta, raíz mala '
      'o baja polinización.',
  'En cuajado, primero agua estable, baja salinidad y raíz oxigenada; luego '
      'Ca/B/Zn contexto. El aguacatito no se sostiene con puro fertilizante.',
  'Registra la caída fuerte como memoria: puede explicar baja cosecha y '
      'alternancia del siguiente ciclo.',
];

const List<String> _thripsActions = <String>[
  'Raspado plateado/corchoso cerca del cáliz en fruto joven apunta a trips '
      '(o viento/roce como diferencial). Revisa flor, cáliz y envés de hoja '
      'nueva.',
  'El daño temprano queda marcado hasta la cosecha: guárdalo como riesgo de '
      'calidad externa, no esperes al corte.',
  'No recetes insecticida: confirma trips con muestreo y diferencia de roña, '
      'viento y sunblotch.',
];

const List<String> _miteActions = <String>[
  'Bronceado, punteado y telaraña fina bajo la hoja apuntan a ácaros (persea/'
      'café). Con polvo, calor seco y estrés hídrico, revisa ácaros y agua '
      'juntos.',
  'La defoliación por ácaro baja fotosíntesis y expone la fruta al golpe de '
      'sol. Registra la pérdida de hoja como memoria.',
  'No lo confundas con salinidad: la sal quema borde de hoja vieja; el ácaro '
      'broncea la superficie y deja telaraña.',
];

const List<String> _laceBugActions = <String>[
  'Manchas cloróticas/necrosadas con puntos negros brillantes en el ENVÉS '
      'apuntan a chinche de encaje (lace bug); no come del fruto.',
  'Puede parecer quemadura por sal: revisa el envés y los puntos negros antes '
      'de diagnosticar salinidad.',
  'Si defolia, registra la pérdida de hoja: baja cuajado y calibre después.',
];

const List<String> _suckerActions = <String>[
  'La negrilla (fumagina) es CONSECUENCIA de la mielecilla. Busca escamas, '
      'cochinillas o mosca blanca en el envés y ramas.',
  'Revisa hormigas: muchas veces protegen a los chupadores que dejan la miel.',
  'Si cubre mucha hoja o fruta, registra la pérdida de fotosíntesis/calidad '
      'como memoria del ciclo.',
];

const List<String> _regulatedBorerActions = <String>[
  'Abre varias frutas/ramas sospechosas. Busca larvas, galerías, frass/aserrín '
      'o túneles hacia el hueso.',
  'Barrenador de ramas, barrenador del hueso y palomilla barrenadora son plagas '
      'REGLAMENTADAS: no se diagnostican por sensor. Contacta sanidad local / '
      'Junta / SENASICA y NO muevas fruta sospechosa.',
  'El riesgo es comercial/oficial: sigue muestreo, trampeo y campaña, no NPK.',
];

const List<String> _anthracnoseActions = <String>[
  'Manchas negras hundidas que aparecen al MADURAR aunque el fruto se veía sano '
      'en el árbol apuntan a antracnosis latente. Registra el clima húmedo del '
      'ciclo.',
  'Si hubo lluvia, rocío o copa cerrada, sube el riesgo de antracnosis/roña y '
      'baja la confianza de que sea sólo NPK. No la confundas con golpe de sol '
      'ni sunblotch.',
  'No recetes fungicida: compara frutos sanos y dañados y confirma con técnico '
      'si avanza.',
];

const List<String> _stemEndRotActions = <String>[
  'Si la pudrición empieza por el PEDÚNCULO y aparece al ablandar, piensa en '
      'stem-end rot/poscosecha, no en plaga por default.',
  'Conecta la fruta podrida con sanidad de rama/copa (cancro/madera muerta) y '
      'cosecha en seco. Guarda el daño poscosecha como memoria de calidad.',
  'Diferencia stem-end rot de antracnosis y de la mosca/barrenador; confirma '
      'con técnico si es recurrente.',
];

const List<String> _scabActions = <String>[
  'Lesiones corchosas elevadas/costras en la cáscara apuntan a roña (sarna). Es '
      'daño cosmético/comercial; diferéncialo de trips, viento, golpe de sol y '
      'sunblotch.',
  'Favorecida por humedad, lluvia y copa densa sobre tejido joven susceptible. '
      'No recetes fungicida: registra el clima y confirma con técnico.',
  'En exportación la roña demerita calidad externa aunque la pulpa esté sana.',
];

const List<String> _cankerActions = <String>[
  'Una rama que se seca desde la punta, con exudado rojizo que seca a polvo y '
      'tejido café en cuña al cortar, apunta a cancro / muerte regresiva. NO es '
      'NPK.',
  'Revisa heridas de poda, golpe de sol, estrés hídrico, salinidad y raíz. La '
      'muerte de rama reduce copa: tiene memoria muy alta.',
  'Diferéncialo de barrenillo ambrosial (orificios/aserrín tipo azúcar) y '
      'confirma con técnico si avanza.',
];

const List<String> _sunblotchActions = <String>[
  'Estrías o manchas hundidas amarillas/rojas/blancas en fruto, estrías en '
      'brotes y corteza tipo «alligator» con bajo rendimiento crónico apuntan a '
      'sunblotch (viroide). Puede haber portadores SIN síntomas.',
  'No se resuelve con fertilizante. Revisa el origen del material vegetal '
      '(injerto/semilla/portainjerto) y confirma con técnico/laboratorio.',
  'Diferéncialo de trips, roña y golpe de sol antes de concluir.',
];

const List<String> _sunburnActions = <String>[
  'Un parche pálido/amarillo que se vuelve café/negro del lado EXPUESTO '
      '(sur/oeste) por calor apunta a golpe de sol, no a hongo de entrada.',
  'Suele venir tras defoliación, poda fuerte o fruta expuesta. Registra la '
      'defoliación como memoria: expone más fruta al sol.',
  'Cuida sombra/copa; no lo trates como pudrición ni plaga.',
];

const List<String> _coldActions = <String>[
  'Flor quemada, brote negro y hojas colgando/necrosadas tras noche fría o '
      'helada apuntan a daño por frío. Cruza con el evento climático; no '
      'diagnostiques NPK.',
  'Espera a que el daño se exprese; no sobrepodes ni fertilices agresivo sin '
      'evaluar la recuperación.',
  'En floración/cuajado el frío puede bajar la carga: guárdalo como memoria del '
      'ciclo.',
];

const List<String> _phytotoxicityActions = <String>[
  'Quemadura uniforme o con patrón de aspersión tras una aplicación (aceite/'
      'cobre/sales/mezcla con calor) apunta a fitotoxicidad, no a hongo/plaga.',
  'Pregunta por aplicaciones recientes: si el patrón coincide con la aspersión '
      'o la deriva, no lo cierres como enfermedad.',
  'Diferéncialo de salinidad y golpe de sol; registra el producto y la fecha.',
];

const List<String> _memoryActions = <String>[
  'La postcosecha NO cierra el aguacate: es cuando el árbol recupera hoja, raíz '
      'y reservas para la siguiente floración. No apagues el seguimiento.',
  'Si el año pasado cargó mucho y no recuperó reservas, este año puede venir '
      'bajo (alternancia). No se fuerza, se registra.',
  'Guarda memoria de raíz/sales, defoliación, caída fuerte o floración golpeada: '
      'puede explicar bajo rendimiento aunque el sensor marque NPK bonito.',
];

/// Modificador de sensibilidad por perfil AG (doc 04 §6.2).
VarietyModifier _agModifier({
  required Set<String> profiles,
  required String diagnosisId,
  required int delta,
  required String rationale,
  bool requiresCaution = false,
}) => VarietyModifier(
  cropId: CropCatalog.avocadoTreeCropId,
  varietyIds: profiles,
  diagnosisIds: <String>{diagnosisId},
  scoreDelta: delta,
  rationaleEs: rationale,
  isProxy: true,
  requiresCaution: requiresCaution,
);

/// Catálogo de síndromes del aguacate. `final` (no `const`) por los
/// modificadores por perfil AG construidos con [_agModifier].
final List<PlantHealthSyndrome> avocadoTreeSyndromes = <PlantHealthSyndrome>[
  // ── Familia 1: Raíz, drenaje, Phytophthora y tristeza del aguacate ────────
  PlantHealthSyndrome(
    id: 'avocado_phytophthora_root_rot_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Tristeza / pudrición de raíz por Phytophthora',
    stages: _rootStages,
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
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalHighPhCalcareous,
      PlantHealthIds.signalLeafEdgeBurn,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalFrostEvent,
      PlantHealthIds.signalHailEvent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_phytophthora_cinnamomi_context',
        labelEs: 'Phytophthora / pudrición de raíz (tristeza)',
        scientificName: 'Phytophthora cinnamomi',
        type: 'oomycete_context',
        summaryEs:
            'Copa amarilla o pálida, hojas pequeñas, decaimiento progresivo, '
            'ramas secas, raíz fina ausente/oscura y marchitez aunque el suelo '
            'esté húmedo, favorecido por suelo pesado, encharque, drenaje pobre, '
            'riego excesivo y salinidad. Es una de las enfermedades más '
            'destructivas del aguacate. No se diagnostica por sensor: revisa '
            'raíz, drenaje y patrón de decaimiento, y confirma con técnico.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRootsDarkRot},
      ),
      PlantHealthDiagnosis(
        id: 'root_anoxia_waterlogging_context',
        labelEs: 'Exceso de agua / raíz sin oxígeno',
        type: 'abiotic_soil',
        summaryEs:
            'Suelo húmedo, árbol decaído, hoja amarilla, olor a podrido y caída '
            'de flor/frutito tras riego pesado, lluvia, suelo arcilloso o '
            'compactación. En aguacate más agua puede EMPEORAR: diferencia '
            'sequía de anoxia antes de regar o fertilizar.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWaterlogging},
      ),
      PlantHealthDiagnosis(
        id: 'poor_drainage_compaction_root_context',
        labelEs: 'Compactación / drenaje flojo / raíz limitada',
        type: 'abiotic_soil',
        summaryEs:
            'Charcos, raíz superficial pobre, crecimiento lento, clorosis y '
            'respuesta débil a fertilizante con resistencia/compactación alta. '
            'Si la raíz está comprimida, el NPK puede verse presente pero no '
            'entrar al árbol.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHighPhCalcareous},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La marchitez ocurre con el suelo HÚMEDO (no seco)?',
      '¿El suelo se encharca o tarda mucho en drenar después de regar/llover?',
      '¿Las raíces finas se ven oscuras, escasas o con mal olor?',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _rootPhytophthoraActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg05AntillanoTropical},
        diagnosisId: 'root_anoxia_waterlogging_context',
        delta: 10,
        rationale:
            'Antillano/tropical en clima húmedo concentra riesgo de exceso de '
            'humedad y enfermedades de raíz (doc 04 §6.2).',
      ),
      _agModifier(
        profiles: <String>{kAg01Hass},
        diagnosisId: 'avocado_phytophthora_cinnamomi_context',
        delta: 8,
        rationale:
            'Hass de exportación: raíz/Phytophthora y salinidad castigan fuerte '
            'el cuajado y el calibre (doc 04 §6.2).',
      ),
    ],
  ),

  // ── Familia 2: Salinidad, cloruros, sodio, boro y pH ──────────────────────
  PlantHealthSyndrome(
    id: 'avocado_salinity_tip_burn_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Salinidad / cloruros / sodio / punta quemada',
    stages: _salinityStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalLeafEdgeBurn,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHighPhCalcareous,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalFrostEvent,
      PlantHealthIds.signalMitesWebbing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_chloride_sodium_tip_burn_context',
        labelEs: 'Toxicidad por cloruro / sodio / sales',
        type: 'abiotic_soil',
        summaryEs:
            'Puntas y bordes de hojas VIEJAS quemados, caída de hojas, fruto '
            'chico, cuajado débil y árbol "sediento" aunque se riegue, con EC '
            'alta, agua salina o drenaje pobre. El aguacate es muy sensible a '
            'sales: EC alta no es "nutriente bueno", es bloqueo/toxicidad. El '
            'sensor no distingue cloruro/sodio/boro; pide análisis de agua/'
            'suelo/foliar.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'boron_toxicity_context',
        labelEs: 'Boro alto / toxicidad posible',
        type: 'abiotic_nutritional_context',
        summaryEs:
            'Bordes quemados y necrosis marginal similares a salinidad, con '
            'crecimiento frenado, agua con boro o fertirriego sin análisis. El '
            'boro tiene margen estrecho (poco falta, mucho quema): no lo simules '
            'con el sensor NPK; pide análisis.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
      PlantHealthDiagnosis(
        id: 'high_ph_micronutrient_lockout_context',
        labelEs: 'pH alto / bloqueo de Fe/Zn/Mn',
        type: 'abiotic_nutritional_context',
        summaryEs:
            'Hoja NUEVA amarilla con nervadura verde, brote débil y respuesta '
            'pobre al N en suelo calizo, agua bicarbonatada o pH >7.5. No es N '
            'automático: Fe/Zn/Mn/B son contexto avanzado, no sensores v1. '
            'Confirma con análisis foliar.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHighPhCalcareous},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las puntas quemadas están en hojas VIEJAS (borde/punta)?',
      '¿Tienes agua con sales/cloruros/salitre o EC alta?',
      '¿La hoja NUEVA sale amarilla con nervadura verde (pH alto)?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _salinityActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg01Hass, kAg02MendezCarmen},
        diagnosisId: 'avocado_chloride_sodium_tip_burn_context',
        delta: 6,
        rationale:
            'Hass/Méndez de exportación: la salinidad/cloruros castiga cuajado, '
            'calibre y calidad premium (doc 04 §6.2).',
      ),
    ],
  ),

  // ── Familia 3: Floración, tipo A/B, polinización y bajo cuajado ───────────
  PlantHealthSyndrome(
    id: 'avocado_flower_set_failure_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Floración fuerte pero bajo cuajado',
    stages: _bloomStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalFlowerDrop,
      PlantHealthIds.signalNoPollinatorNearby,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_low_fruit_set_pollination_context',
        labelEs: 'Mucha flor pero poco cuajado',
        type: 'physiological_context',
        summaryEs:
            'Flor abundante, inflorescencias sin frutito y pocos frutitos '
            'retenidos por mal traslape A/B, poca actividad de polinizadores, '
            'clima frío/caliente, viento, lluvia, baja reserva o árbol aislado. '
            'En aguacate menos de 1% de flores llega a fruto: mucha flor NO es '
            'cosecha. Un tipo B compatible cerca puede ayudar SI coincide la '
            'floración y hay abejas.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalNoPollinatorNearby},
      ),
      PlantHealthDiagnosis(
        id: 'avocado_flower_abortion_heat_cold_context',
        labelEs: 'Aborto floral por calor/frío/viento seco',
        type: 'abiotic_physiological',
        summaryEs:
            'Flor que se seca, caída de flor, baja actividad de insectos y hoja '
            'decaída tras calor seco, baja humedad, viento o noches frías. Si '
            'hubo pico térmico o frío en floración, no culpes al NPK primero.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHeatStress},
      ),
      PlantHealthDiagnosis(
        id: 'avocado_flower_type_overlap_context',
        labelEs: 'Sincronía floral A/B / polinización cruzada',
        type: 'physiological_context',
        summaryEs:
            'Hass (tipo A) solo con flor pero poco amarre; un Fuerte/tipo B '
            'cerca puede mejorar el contexto si coincide la apertura floral y '
            'hay abejas. El tipo A/B NO es etapa ni receta: no obligues al '
            'usuario a saberlo; úsalo como ayuda si captura la variedad.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFlowerDrop},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Floreó mucho pero casi no amarró fruto?',
      '¿Hay polinizadores/abejas o sólo una variedad aislada?',
      '¿La floración coincidió con calor fuerte, frío, viento o lluvia?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _bloomSetActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg01Hass},
        diagnosisId: 'avocado_flower_type_overlap_context',
        delta: 8,
        rationale:
            'Hass (tipo A) con bajo cuajado recurrente concentra el contexto de '
            'polinización A/B (doc 04 §6.2).',
      ),
      _agModifier(
        profiles: <String>{kAg04FuertePielVerde},
        diagnosisId: 'avocado_flower_type_overlap_context',
        delta: 10,
        rationale:
            'Fuerte es tipo B/polinizador: el traslape floral es contexto '
            'central, pero no garantiza cuajado (doc 04 §6.2).',
      ),
      _agModifier(
        profiles: <String>{kAg02MendezCarmen},
        diagnosisId: 'avocado_low_fruit_set_pollination_context',
        delta: 8,
        rationale:
            'Méndez/Carmen con floración desfasada puede cuajar mal por ventana '
            'variable (doc 04 §6.2).',
      ),
    ],
  ),

  // ── Familia 4: Cuajado, caída de frutito, carga y alternancia ─────────────
  PlantHealthSyndrome(
    id: 'avocado_fruitlet_drop_stress_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Se cae el aguacatito / no amarró',
    stages: _setDropStages,
    organIds: <String>{
      PlantHealthIds.organFruit,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFruitDeformation,
    strongSignals: <String>{
      PlantHealthIds.signalFlowerDrop,
      PlantHealthIds.signalSalinityLoad,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'physiological_fruitlet_drop_context',
        labelEs: 'Caída fisiológica normal de frutito',
        type: 'physiological_context',
        summaryEs:
            'Caen muchos frutitos pequeños pero quedan algunos sanos, sin '
            'estrés fuerte: es regulación natural de carga y baja fecundación. '
            'Algo de caída es NORMAL en aguacate. Alertar sólo si es excesiva o '
            'coincide con estrés.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFlowerDrop},
      ),
      PlantHealthDiagnosis(
        id: 'avocado_fruitlet_drop_stress_complex',
        labelEs: 'Caída de aguacatito por estrés',
        type: 'abiotic_physiological',
        summaryEs:
            'Frutito amarillo/negro que cae, pedúnculo seco y árbol con punta '
            'quemada o raíz estresada, por raíz mala, salinidad, calor, sequía, '
            'exceso de agua, mala polinización, baja reserva o alternancia. '
            'Revisa agua, raíz, EC, clima y polinización ANTES de hablar de '
            'fertilizante.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
      PlantHealthDiagnosis(
        id: 'heavy_crop_small_fruit_context',
        labelEs: 'Mucha carga / fruta chica / calibre bajo',
        type: 'abiotic_physiological',
        summaryEs:
            'Muchos frutos pero pequeños, crecimiento lento y hoja cansada con '
            'carga alta, poca hoja funcional, agua/sales o K/Ca/Mg/B/Zn '
            'desbalanceados. Más kg no siempre es mejor: puede bajar calibre, '
            'calidad y el siguiente ciclo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El frutito cae amarillo, negro o todavía verde?',
      '¿La caída coincide con calor, sales (EC alta), agua baja/alta o raíz mala?',
      '¿Es una caída moderada (normal) o masiva/repetida (estrés)?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _setDropActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg02MendezCarmen},
        diagnosisId: 'avocado_fruitlet_drop_stress_complex',
        delta: 8,
        rationale:
            'Méndez/Carmen con floración fuera de temporada acumula caída '
            'fisiológica y por estrés (doc 04 §6.2).',
      ),
    ],
  ),

  // ── Familia 5: Trips y cicatriz de fruto joven ────────────────────────────
  PlantHealthSyndrome(
    id: 'avocado_thrips_scarring_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Trips / raspado en fruto joven',
    stages: _scarringStages,
    organIds: <String>{
      PlantHealthIds.organFruit,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomThripsSilverScarring,
    strongSignals: <String>{
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalThripsSilverScarring,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRindScarsNearCalyx,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalExposedFruitSouthwest,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_thrips_fruit_scarring_context',
        labelEs: 'Trips del aguacate / cicatriz en fruto joven',
        type: 'insect',
        summaryEs:
            'Raspado plateado/bronceado y cicatrices corchosas en fruto joven '
            'cerca del cáliz, con daño en flor y larvas en el envés, en clima '
            'fresco-templado de primavera. El daño temprano queda marcado hasta '
            'la cosecha: revisa fruto joven y envés, no esperes al corte.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalThripsSilverScarring,
        },
      ),
      PlantHealthDiagnosis(
        id: 'wind_rub_fruit_scarring_context',
        labelEs: 'Raspadura por viento / roce (diferencial)',
        type: 'abiotic_physical',
        summaryEs:
            'Cicatriz superficial lineal donde el fruto rozó con rama o por '
            'viento. Es daño físico y sigue el patrón de roce/exposición; no lo '
            'confundas con trips ni con roña.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRindScarsNearCalyx,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El raspado plateado/corchoso está cerca del cáliz o en la flor?',
      '¿Ves trips o larvas en el envés de hoja nueva/fruto joven?',
      '¿La cicatriz sigue el patrón de roce con ramas o viento?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _thripsActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg01Hass, kAg02MendezCarmen},
        diagnosisId: 'avocado_thrips_fruit_scarring_context',
        delta: 5,
        rationale:
            'En Hass/Méndez de exportación la cicatriz de trips demerita calidad '
            'externa de fruto joven (doc 04 §6.2).',
      ),
    ],
  ),

  // ── Familia 6: Ácaros / bronceado / defoliación ───────────────────────────
  PlantHealthSyndrome(
    id: 'avocado_mite_defoliation_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Ácaros / bronceado / defoliación',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalMitesWebbing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'persea_mite_bronzing_context',
        labelEs: 'Ácaro persea / bronceado / defoliación',
        type: 'mite',
        summaryEs:
            'Puntos/colonias bajo la hoja, manchas bronceadas, telaraña fina y '
            'caída de hoja que expone la fruta al sol, en clima seco, polvo y '
            'estrés hídrico. La defoliación por ácaro baja fotosíntesis: '
            'registra la pérdida de hoja como memoria.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalMitesWebbing},
      ),
      PlantHealthDiagnosis(
        id: 'mite_vs_water_stress_context',
        labelEs: 'Estrés hídrico como diferencial',
        type: 'abiotic_physiological',
        summaryEs:
            'Con polvo, calor y bronceado, revisa ácaros y estrés hídrico '
            'juntos: la falta de agua agrava el daño y lo confunde. No lo '
            'confundas con salinidad (borde de hoja vieja quemado).',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDryHotWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay bronceado, punteado y telaraña fina bajo la hoja?',
      '¿Está cayendo hoja y quedando la fruta expuesta al sol?',
      '¿Hay polvo, calor seco y estrés hídrico acompañando?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _miteActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg06TardioLambReed},
        diagnosisId: 'persea_mite_bronzing_context',
        delta: 5,
        rationale:
            'Tardío/Lamb/Reed, con llenado largo y fruta grande expuesta, sufre '
            'más el golpe de sol tras defoliación por ácaro (doc 04 §6.2).',
      ),
    ],
  ),

  // ── Familia 7: Chinche de encaje / lace bug ───────────────────────────────
  PlantHealthSyndrome(
    id: 'avocado_lace_bug_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Chinche de encaje / manchas en hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalLeafEdgeBurn,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_lace_bug_context',
        labelEs: 'Chinche de encaje (lace bug)',
        type: 'insect',
        summaryEs:
            'Manchas cloróticas/necrosadas y puntos negros brillantes (frass) '
            'en el ENVÉS, con hoja seca que cae; no se alimenta del fruto. '
            'Favorecida por clima cálido, baja vigilancia y árboles estresados. '
            'Si defolia, baja cuajado y calibre después.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFeedingHoles},
      ),
      PlantHealthDiagnosis(
        id: 'lace_bug_vs_salinity_context',
        labelEs: 'Salinidad / ácaros como diferencial',
        type: 'abiotic_context',
        summaryEs:
            'Puede parecer quemadura por sal: revisa el ENVÉS y los puntos '
            'negros antes de diagnosticar salinidad. Los ácaros dan bronceado '
            'con telaraña; el lace bug deja manchas y frass negro.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las manchas tienen puntos negros brillantes en el ENVÉS?',
      '¿La EC/agua está normal (descartar salinidad)?',
      '¿Está cayendo hoja por las manchas?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _laceBugActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),

  // ── Familia 8: Escamas / cochinillas / chupadores con fumagina ────────────
  PlantHealthSyndrome(
    id: 'avocado_sap_sucker_sooty_mold_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Cochinillas / escamas / chupadores con fumagina',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFruit,
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
        id: 'avocado_scale_mealybug_context',
        labelEs: 'Escamas / cochinillas / piojo harinoso',
        type: 'insect',
        summaryEs:
            'Costras que no se raspan o masas algodonosas, mielecilla y '
            'fumagina en copa densa, con hormigas y baja ventilación. Si la '
            'costra no se raspa, piensa en escama; la fumagina es consecuencia, '
            'busca el chupador.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalCannotScrapeOff},
      ),
      PlantHealthDiagnosis(
        id: 'avocado_sooty_mold_honeydew_context',
        labelEs: 'Fumagina / negrilla por mielecilla',
        type: 'fungus_secondary',
        summaryEs:
            'Capa negra superficial que se raspa y hoja/fruto pegajoso, causada '
            'por cochinillas, escamas o mosca blanca. No la trates como hongo '
            'principal: busca el insecto que produce la miel y las hormigas.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSootyMold},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La hoja/fruta está pegajosa y con tizne negro (negrilla)?',
      '¿Hay costras que no se raspan, algodón blanco o mosca blanca en el envés?',
      '¿Hay hormigas subiendo por el tronco cuidando chupadores?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _suckerActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),

  // ── Familia 9: Plagas reglamentadas / barrenadores ────────────────────────
  PlantHealthSyndrome(
    id: 'avocado_regulated_borers_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Barrenadores reglamentados / galerías en rama o hueso',
    stages: _borerStages,
    organIds: <String>{
      PlantHealthIds.organFruit,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomFruitTunnelFrass,
    strongSignals: <String>{
      PlantHealthIds.signalFruitLarvae,
      PlantHealthIds.signalFrassPresent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalWhiteGreenBlueMold,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_seed_borer_regulated_context',
        labelEs: 'Barrenador del hueso / larva dentro del fruto (regulado)',
        type: 'insect_regulated_context',
        summaryEs:
            'Orificios, larva dentro, galería hacia el hueso, fruta caída y '
            'pudrición secundaria en zonas no libres. Es plaga REGLAMENTADA: no '
            'se diagnostica por sensor. Abre muestra, sigue a sanidad local y NO '
            'muevas fruta sospechosa sin lineamientos oficiales.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFruitLarvae},
      ),
      PlantHealthDiagnosis(
        id: 'avocado_branch_borer_regulated_context',
        labelEs: 'Barrenador de ramas del aguacatero (regulado)',
        type: 'insect_regulated_context',
        summaryEs:
            'Perforaciones, aserrín/frass, galerías y ramas que se quiebran o '
            'secan, en zonas con presencia y huertas sin campaña. No '
            'diagnostiques por sensor: si hay frass/galería/rama quebradiza, '
            'pide revisión oficial/local.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrassPresent},
      ),
      PlantHealthDiagnosis(
        id: 'avocado_seed_moth_regulated_context',
        labelEs: 'Palomilla barrenadora del hueso (regulada)',
        scientificName: 'Stenoma catenifer',
        type: 'insect_regulated_context',
        summaryEs:
            'Entrada en fruto, frass, túneles, semilla dañada y larva, con '
            'presencia regional y baja campaña. Riesgo comercial/oficial, no '
            'diagnóstico de app: deriva a campaña/reglamento y muestreo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFeedingHoles},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay larvas, túneles o frass al abrir varias frutas/ramas?',
      '¿La región tiene campaña/muestreo de plagas reglamentadas activo?',
      '¿Las ramas se quiebran/secan con aserrín (barrenador de ramas)?',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.immediate,
    baseActionsEs: _regulatedBorerActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg06TardioLambReed},
        diagnosisId: 'avocado_seed_borer_regulated_context',
        delta: 6,
        rationale:
            'Tardío/Reed deja fruta madura más tiempo en árbol y sube el riesgo '
            'de barrenador del hueso (doc 04 §6.2).',
      ),
    ],
  ),

  // ── Familia 10: Antracnosis en fruto/hoja ─────────────────────────────────
  PlantHealthSyndrome(
    id: 'avocado_anthracnose_fruit_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Antracnosis / manchas hundidas en fruto',
    stages: _fruitStages,
    organIds: <String>{
      PlantHealthIds.organFruit,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalDenseWetCanopy,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWhiteGreenBlueMold,
      PlantHealthIds.signalHailEvent,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_anthracnose_context',
        labelEs: 'Antracnosis del aguacate',
        scientificName: 'Colletotrichum spp.',
        type: 'fungus',
        summaryEs:
            'Manchas negras/hundidas que aparecen al madurar/ablandar aunque el '
            'fruto se veía sano en el árbol, con manchas en hoja/brote en '
            'humedad alta, lluvia, heridas y copa cerrada. Puede infectar antes '
            'y verse después del corte. No la confundas con golpe de sol ni '
            'sunblotch.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
      PlantHealthDiagnosis(
        id: 'rain_humidity_fruit_disease_context',
        labelEs: 'Lluvia / humedad alta pegando en fruto',
        type: 'climate_disease_context',
        summaryEs:
            'Fruta mojada, copa cerrada y manchas tras lluvia/rocío prolongado. '
            'Si llovió sobre la fruta, primero sanidad/manejo de copa; registra '
            'el clima húmedo del ciclo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalDenseWetCanopy},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las manchas aparecen cuando el fruto empieza a ablandar (poscosecha)?',
      '¿Hubo lluvia, rocío o copa muy cerrada/húmeda?',
      '¿Las lesiones son negras y hundidas (no del lado del sol)?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _anthracnoseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg05AntillanoTropical},
        diagnosisId: 'avocado_anthracnose_context',
        delta: 8,
        rationale:
            'Antillano/tropical en clima húmedo concentra antracnosis/roña '
            '(doc 04 §6.2).',
      ),
    ],
  ),

  // ── Familia 11: Pudrición por pedúnculo / stem-end rot poscosecha ─────────
  PlantHealthSyndrome(
    id: 'avocado_stem_end_rot_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Pudrición por pedúnculo / stem-end rot',
    stages: _postharvestFruitStages,
    organIds: <String>{
      PlantHealthIds.organFruit,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomMummifiedFruitRot,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalStemCanker,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWhiteGreenBlueMold,
      PlantHealthIds.signalFruitLowCanopyRainSplash,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_stem_end_rot_context',
        labelEs: 'Stem-end rot / pudrición por pedúnculo',
        scientificName: 'Botryosphaeriaceae / Colletotrichum (complejo)',
        type: 'fungus',
        summaryEs:
            'Pudrición que INICIA desde el pedúnculo y avanza oscura hacia la '
            'pulpa, en fruta aparentemente sana al corte que se pudre al '
            'ablandar, por infección latente, cancros/ramas, heridas o cosecha '
            'con humedad. Si arranca del pedúnculo, no es plaga por default.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalStemCanker},
      ),
      PlantHealthDiagnosis(
        id: 'avocado_postharvest_handling_decay_context',
        labelEs: 'Pudrición por manejo/cosecha/poscosecha',
        type: 'fungus_context',
        summaryEs:
            'Fruta aparentemente sana que se pudre al ablandar, con manchas '
            'desde heridas o pedúnculo, por cosecha con lluvia, golpes, demora a '
            'frío o fruta sobremadura. No todo problema poscosecha es del árbol: '
            'registra el manejo de corte.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalWhiteGreenBlueMold},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La pudrición empieza por el PEDÚNCULO (stem-end rot)?',
      '¿Aparece al ablandar aunque el fruto se veía sano en el árbol?',
      '¿Cosechaste con lluvia/humedad o hubo golpes/demora a frío?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _stemEndRotActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg06TardioLambReed},
        diagnosisId: 'avocado_stem_end_rot_context',
        delta: 5,
        rationale:
            'Tardío/Reed concentra infección latente y stem-end rot en la '
            'poscosecha de ventana extendida (doc 04 §6.2).',
      ),
    ],
  ),

  // ── Familia 12: Roña / sarna corchosa en fruto ────────────────────────────
  PlantHealthSyndrome(
    id: 'avocado_scab_fruit_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Roña / sarna corchosa en fruto',
    stages: _fruitStages,
    organIds: <String>{
      PlantHealthIds.organFruit,
      PlantHealthIds.organLeaf,
    },
    primarySymptomId: PlantHealthIds.symptomFruitSunkenPits,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalDenseWetCanopy,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalThripsSilverScarring,
      PlantHealthIds.signalExposedFruitSouthwest,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_scab_context',
        labelEs: 'Roña / sarna del aguacate',
        scientificName: 'Sphaceloma perseae / Elsinoë perseae',
        type: 'fungus',
        summaryEs:
            'Lesiones corchosas elevadas, costras y fruta marcada con lesiones '
            'pequeñas en hoja, favorecidas por humedad, lluvia, tejido joven '
            'susceptible y copa densa. Es daño cosmético/comercial: diferéncialo '
            'de trips, viento, sunblotch y golpe de sol.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalHumidWindow},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las lesiones son corchosas/elevadas (costra) en la cáscara?',
      '¿Hubo humedad/lluvia y copa densa sobre tejido joven?',
      '¿Puedes descartar trips (raspado plateado) y golpe de sol (lado expuesto)?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _scabActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg05AntillanoTropical},
        diagnosisId: 'avocado_scab_context',
        delta: 6,
        rationale:
            'Antillano/tropical húmedo concentra roña sobre calidad externa '
            '(doc 04 §6.2).',
      ),
    ],
  ),

  // ── Familia 13: Cancro / muerte regresiva de rama ─────────────────────────
  PlantHealthSyndrome(
    id: 'avocado_branch_canker_dieback_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Cancro / muerte regresiva de rama',
    stages: _woodStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomShootDecayCanker,
    strongSignals: <String>{
      PlantHealthIds.signalStemCanker,
      PlantHealthIds.signalShootTipWilt,
    },
    weakSignals: <String>{
      PlantHealthIds.signalOneSidedWilt,
      PlantHealthIds.signalVascularBrowning,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalHeatStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_branch_canker_dieback_context',
        labelEs: 'Cancro / muerte regresiva (Botryosphaeriaceae)',
        scientificName: 'Botryosphaeriaceae / Lasiodiplodia / Neofusicoccum',
        type: 'fungus_wood_context',
        summaryEs:
            'Rama que se seca desde la punta, exudado rojizo que seca a polvo '
            'blanco/café y tejido marrón en cuña al cortar (cancro), tras estrés '
            'hídrico, salinidad, heridas de poda, golpe de sol o madera muerta. '
            'La rama seca NO es NPK: revisa heridas, estrés, raíz y patógenos de '
            'madera. Reduce copa y tiene memoria alta.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalStemCanker},
      ),
      PlantHealthDiagnosis(
        id: 'ambrosia_beetle_dieback_context',
        labelEs: 'Barrenillo ambrosial / muerte por Fusarium (diferencial)',
        type: 'insect_fungus_context',
        summaryEs:
            'Pequeños orificios, exudados tipo azúcar/aserrín, marchitez de rama '
            'y galerías internas en árboles estresados. Riesgo emergente/'
            'regional: no diagnostiques si no hay orificios/galerías y '
            'confirmación.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalShootTipWilt},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La rama se seca desde la punta con exudado rojizo/blanco?',
      '¿Al cortar hay tejido café en cuña (cancro)?',
      '¿Hubo poda con heridas, estrés hídrico, sales o golpe de sol?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _cankerActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),

  // ── Familia 14: Sunblotch / viroide del manchado ──────────────────────────
  PlantHealthSyndrome(
    id: 'avocado_sunblotch_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Sunblotch / manchado viroide',
    stages: _sunblotchStages,
    organIds: <String>{
      PlantHealthIds.organFruit,
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFruitSunkenPits,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
    },
    weakSignals: <String>{
      PlantHealthIds.signalLateGreenExcessVigor,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalThripsSilverScarring,
      PlantHealthIds.signalExposedFruitSouthwest,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_sunblotch_viroid_context',
        labelEs: 'Sunblotch / viroide del manchado del aguacate',
        scientificName: 'Avocado sunblotch viroid (ASBVd)',
        type: 'viroid_context',
        summaryEs:
            'Manchas o rayas amarillas/rojas/blancas HUNDIDAS en fruto, estrías '
            'en brotes, corteza tipo «alligator» y árbol con bajo rendimiento '
            'crónico, ligado a material vegetal infectado (injerto/semilla/'
            'portainjerto); puede haber portadores SIN síntomas. Si el patrón '
            'coincide y el bajo rendimiento es crónico, pide diagnóstico técnico. '
            'No se resuelve con fertilizante.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalLateGreenExcessVigor,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nursery_material_problem_context',
        labelEs: 'Material de vivero / portainjerto como origen',
        type: 'establishment_context',
        summaryEs:
            'Árbol crónicamente bajo desde el inicio, con material no '
            'certificado o portainjerto sensible. Si falla desde plantación y '
            'los sensores no lo explican, revisa el origen de la planta/injerto. '
            'No lo resuelvas con NPK.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El fruto tiene estrías/depresiones amarillas/rojas/blancas?',
      '¿Hay estrías en brotes o corteza tipo «alligator»?',
      '¿El bajo rendimiento es crónico y viene desde el material de vivero?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _sunblotchActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),

  // ── Familia 15: Golpe de sol / quemadura por calor ────────────────────────
  PlantHealthSyndrome(
    id: 'avocado_sunburn_heat_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Golpe de sol / fruta u hoja quemada',
    stages: _sunburnStages,
    organIds: <String>{
      PlantHealthIds.organFruit,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomFruitSunburnPatch,
    strongSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalExposedFruitSouthwest,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_sunburn_heat_context',
        labelEs: 'Golpe de sol / calor seco',
        type: 'abiotic_physical',
        summaryEs:
            'Mancha pálida/amarilla del lado EXPUESTO (sur/oeste) que puede '
            'volverse café/negra, con hoja quemada y rama expuesta, tras '
            'defoliación, poda fuerte, calor intenso y baja HR. Si hay fruta '
            'expuesta y calor, no diagnostiques hongo de entrada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalExposedFruitSouthwest,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El daño está del lado expuesto al sol (sur/oeste)?',
      '¿Hubo defoliación, poda fuerte o fruta muy expuesta?',
      '¿Hubo calor intenso, baja humedad o viento seco?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _sunburnActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg06TardioLambReed},
        diagnosisId: 'avocado_sunburn_heat_context',
        delta: 6,
        rationale:
            'Tardío/Lamb/Reed con fruta grande y expuesta sufre más golpe de sol '
            '(doc 04 §6.2).',
      ),
    ],
  ),

  // ── Familia 16: Daño por frío / helada ────────────────────────────────────
  PlantHealthSyndrome(
    id: 'avocado_cold_frost_damage_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Daño por frío / helada',
    stages: _coldStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomColdInjury,
    strongSignals: <String>{
      PlantHealthIds.signalFrostEvent,
      PlantHealthIds.signalColdExposure,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_frost_cold_context',
        labelEs: 'Helada / frío subletal',
        type: 'abiotic_cold',
        summaryEs:
            'Flor quemada, brote negro, hojas colgando/necrosadas y fruta con '
            'daño y caída posterior tras temperaturas bajas, helada, viento frío '
            'o sitio bajo, sobre todo en árbol joven o brote tierno. Cruza con '
            'el evento climático; no diagnostiques NPK. Espera la expresión del '
            'daño antes de sobrepodar o fertilizar agresivo.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalFrostEvent},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo helada, frío fuerte o viento frío reciente?',
      '¿La flor/brote se ve negro o las hojas cuelgan necrosadas?',
      '¿El sitio es bajo o el árbol es joven/tierno?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _coldActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg05AntillanoTropical},
        diagnosisId: 'avocado_frost_cold_context',
        delta: 12,
        rationale:
            'Antillano/tropical de costa cálida es más sensible a un evento de '
            'frío/helada (doc 04 §6.2).',
      ),
    ],
  ),

  // ── Familia 17: Fitotoxicidad / quemadura por aplicación ──────────────────
  PlantHealthSyndrome(
    id: 'avocado_phytotoxicity_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Fitotoxicidad / quemadura por aplicación',
    stages: _weatherStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomLeafEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalRecentSprayOilCopper,
      PlantHealthIds.signalUniformLeafBurn,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalDryHotWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalFrostEvent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'avocado_phytotoxicity_spray_context',
        labelEs: 'Fitotoxicidad por aplicación',
        type: 'abiotic_chemical',
        summaryEs:
            'Quemadura uniforme o con patrón de aspersión/gota tras mezclas '
            'incompatibles, aplicación con calor o aceite/cobre/sales sobre hoja '
            'tierna. Pregunta por aplicaciones recientes: si el patrón coincide '
            'con la aspersión/deriva, no lo cierres como hongo, plaga ni sal.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRecentSprayOilCopper,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El daño empezó tras una aplicación reciente (aceite/cobre/mezcla)?',
      '¿El patrón es uniforme o sigue la línea de aspersión/gota?',
      '¿Puedes descartar sales (EC alta) y golpe de sol (lado expuesto)?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _phytotoxicityActions,
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 18: Memoria de alternancia / vecería / postcosecha ────────────
  PlantHealthSyndrome(
    id: 'avocado_alternate_bearing_memory_syndrome',
    cropId: CropCatalog.avocadoTreeCropId,
    labelEs: 'Memoria de año cargado / vecería / postcosecha débil',
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
        id: 'avocado_alternate_bearing_memory',
        labelEs: 'Vecería / año cargado y año bajo',
        type: 'memory_physiological',
        summaryEs:
            'Un año muy cargado agota reservas y puede bajar la floración/carga '
            'del siguiente ciclo si el árbol quedó sin hoja funcional, raíz '
            'activa o equilibrio vegetativo. BIO-G registra memoria, no sólo la '
            'cosecha actual: la alternancia no se fuerza, se registra.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalLateGreenExcessVigor,
        },
      ),
      PlantHealthDiagnosis(
        id: 'avocado_postharvest_weak_recovery_memory',
        labelEs: 'Postcosecha débil / reservas agotadas',
        type: 'memory_physiological',
        summaryEs:
            'Árbol defoliado, con brote débil, sales acumuladas o raíz cansada '
            'tras la cosecha. La postcosecha define la siguiente floración: si '
            'no recuperó hoja/raíz/reservas, el próximo ciclo puede entrar bajo. '
            'No se arregla sólo con NPK.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
      PlantHealthDiagnosis(
        id: 'avocado_defoliation_memory_context',
        labelEs: 'Pérdida de hoja funcional / árbol cansado',
        type: 'memory_physiological',
        summaryEs:
            'Copa rala, fruta expuesta y floración posterior floja tras ácaros, '
            'lace bug, salinidad, Phytophthora, helada, calor o poda fuerte. Sin '
            'hoja no hay carbohidratos: puede bajar calibre y la siguiente '
            'floración.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El año pasado cargó mucho y este viene bajo (alternancia)?',
      '¿Después de cosechar quedó cansado, defoliado o con brote débil?',
      '¿Las sales/EC quedaron altas o la raíz sufrió al cierre del ciclo?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _memoryActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
    varietyModifiers: <VarietyModifier>[
      _agModifier(
        profiles: <String>{kAg01Hass},
        diagnosisId: 'avocado_alternate_bearing_memory',
        delta: 6,
        rationale:
            'Hass tiene alternancia marcada y sensibilidad de postcosecha '
            '(doc 04 §6.2).',
      ),
      _agModifier(
        profiles: <String>{kAg06TardioLambReed},
        diagnosisId: 'avocado_postharvest_weak_recovery_memory',
        delta: 5,
        rationale:
            'Tardío/Reed, con llenado muy largo, hace pesar más la memoria y la '
            'postcosecha (doc 04 §6.2).',
      ),
    ],
  ),
];
