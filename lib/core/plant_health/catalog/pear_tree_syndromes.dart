import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Catálogo de riesgos / sanidad vegetal de la Pera (`crop_pear_tree`).
///
/// Alimentado por el documento oficial
/// `04_Riesgos_Cultivo_Sanidad_Estres_Memoria_BioG_Pera_v1`.
///
/// Reglas no negociables:
/// - BIO-G ORIENTA, no diagnostica de forma absoluta: "condición favorable a…",
///   "revisa…", "síntomas compatibles con…", "confirma si avanza…".
/// - NO receta plaguicidas ni ingredientes activos.
/// - El perfil PR solo modifica sensibilidad/mensajes (varietyModifiers); el
///   catálogo base es el mismo para todas las variedades (doc 04 §6).
/// - Árbol perenne con MEMORIA multianual: helada, mala polinización, fuego
///   bacteriano, psila y mala postcosecha pesan en el ciclo siguiente.
///
/// Diferencias clave vs manzano (doc 04 §0): la psila del peral y el fuego
/// bacteriano son riesgos centrales; la polinización cruzada pesa más.
/// Cobertura v1: familias de mayor prioridad (PR-SKIP, doc 04 §6). El resto del
/// catálogo del doc 04 queda como pendiente extensible con el mismo molde.

const Set<PlantHealthStageBucket> _establishmentStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
    };

// Incluye `lateSeason` a propósito: en peral la psila y la mancha foliar
// (Fabraea) siguen pesando en postcosecha/dormancia — etapas que el adapter
// mapea a lateSeason — para que post_harvest NO quede como etapa apagada
// (doc 04 §2 y §6: psila tardía, ácaros, defoliación, sanidad residual).
const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
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
  'La pera tolera suelos algo más húmedos, pero no encharcamiento permanente.',
];

const List<String> _bloomActions = <String>[
  'Revisa racimos florales, brotes tiernos y posible exudado ámbar.',
  'No empujes nitrógeno ni vigor durante floración (sube riesgo de fuego '
      'bacteriano).',
  'Cruza con helada, lluvia, humedad y actividad de polinizadores/otra variedad '
      'compatible cerca.',
];

const List<String> _fruitActions = <String>[
  'Revisa perforaciones, manchas o pudriciones en fruto y compáralas con sol, '
      'granizo, chinches, russeting o balance de calcio.',
  'Protege fruta expuesta y evita heridas que abren puerta a pudriciones.',
  'Guarda el evento para ajustar manejo y cosecha del siguiente ciclo.',
];

const List<String> _psyllaActions = <String>[
  'Si ves melaza pegajosa o negrilla, busca primero el insecto chupador '
      '(psila): revisa brotes, envés de hojas, ninfas y huevos.',
  'La negrilla es consecuencia de la melaza, no la causa: tratar solo el hongo '
      'no resuelve.',
  'Vigila vigor: el exceso de brote tierno favorece a la psila.',
];

/// Modificador de sensibilidad por perfil PR (doc 04 §6).
VarietyModifier _prModifier({
  required Set<String> profiles,
  required String diagnosisId,
  required int delta,
  required String rationale,
}) => VarietyModifier(
  cropId: CropCatalog.pearTreeCropId,
  varietyIds: profiles,
  diagnosisIds: <String>{diagnosisId},
  scoreDelta: delta,
  rationaleEs: rationale,
  isProxy: true,
);

/// Catálogo de síndromes de la pera. `final` (no `const`) por los modificadores
/// por perfil PR construidos con [_prModifier].
final List<PlantHealthSyndrome> pearTreeSyndromes = <PlantHealthSyndrome>[
  // ── Familia 1: Raíz, cuello, suelo y madera ──────────────────────────────
  PlantHealthSyndrome(
    id: 'pear_root_crown_rot_01',
    cropId: CropCatalog.pearTreeCropId,
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
            'compactación, sobre todo en árbol joven o replante. Corona '
            'café-rojiza y raíces finas muertas. No recomendar más riego.',
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
      '¿Ya había frutal (pera/manzano/membrillo) en ese sitio? Puede ser '
          'decaimiento por replantación.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── Familia 2: Flor, brote y bacterias ───────────────────────────────────
  PlantHealthSyndrome(
    id: 'pear_fire_blight_01',
    cropId: CropCatalog.pearTreeCropId,
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
            'Principal riesgo bacteriano del peral. Favorecido por clima '
            'cálido-húmedo en floración, lluvia, granizo, heridas y exceso de '
            'vigor/N. Brotes en "cayado de pastor" y exudado ámbar. Muy alta '
            'memoria: puede matar ramas y árboles jóvenes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalAmberBacterialOoze,
          PlantHealthIds.signalShepherdsCrookShoot,
        },
      ),
      PlantHealthDiagnosis(
        id: 'bacterial_blossom_blast',
        labelEs: 'Bacteriosis de flor / blossom blast',
        type: 'bacteria',
        summaryEs:
            'Flores quemadas tras frío-lluvia. Puede confundirse con helada o '
            'tizón de fuego; revisa exudado y progresión antes de concluir.',
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
      _prModifier(
        profiles: <String>{kPr03Bosc},
        diagnosisId: 'fire_blight',
        delta: 12,
        rationale:
            'Bosc está marcada como especialmente susceptible a fuego '
            'bacteriano bajo presión (OSU/PNW).',
      ),
      _prModifier(
        profiles: <String>{kPr01BartlettWilliams},
        diagnosisId: 'fire_blight',
        delta: 8,
        rationale:
            'Bartlett/Williams puede tener floración extendida: más tiempo con '
            'flor abierta mantiene el riesgo.',
      ),
      _prModifier(
        profiles: <String>{kPr04SeckelComice},
        diagnosisId: 'fire_blight',
        delta: 6,
        rationale:
            'Comice puede ser sensible; Seckel algo menos, pero no '
            'inmune.',
      ),
    ],
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'pear_frost_pollination_01',
    cropId: CropCatalog.pearTreeCropId,
    labelEs: 'Flores cafés/negras o bajo cuajado tras frío/mal clima',
    stages: _bloomStages,
    organIds: <String>{PlantHealthIds.organFlower},
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalFrostEvent,
      PlantHealthIds.signalNoPollinatorNearby,
    },
    weakSignals: <String>{PlantHealthIds.signalColdExposure},
    conflictingSignals: <String>{PlantHealthIds.signalAmberBacterialOoze},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'frost_bloom_damage',
        labelEs: 'Daño por helada en floración',
        type: 'abiotic_cold',
        summaryEs:
            'Temperaturas bajo cero en botón, flor o cuajado reciente dañan '
            'pistilos y bajan cuajado. Memoria alta: afecta el rendimiento del '
            'año, la alternancia y las reservas.',
      ),
      PlantHealthDiagnosis(
        id: 'poor_pollination_low_fruit_set',
        labelEs: 'Mala polinización / bajo cuajado',
        type: 'abiotic_physiological',
        summaryEs:
            'En pera la polinización cruzada es clave. Frío, lluvia, viento, '
            'pocas abejas o falta de variedad compatible bajan el cuajado '
            'aunque el NPK se vea correcto. No culpar al fertilizante primero.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNoPollinatorNearby,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa el centro/pistilo de la flor: oscuro indica daño de helada.',
      '¿Hay otra variedad de pera compatible floreando cerca y actividad de '
          'abejas?',
      'Revisa frutos recién cuajados: deformes/asimétricos sugieren mala '
          'polinización.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _bloomActions,
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 3: Psila, melaza y decaimiento ───────────────────────────────
  PlantHealthSyndrome(
    id: 'pear_psylla_01',
    cropId: CropCatalog.pearTreeCropId,
    labelEs: 'Melaza pegajosa y negrilla en brotes/hojas',
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
      PlantHealthIds.signalPsyllaNymphsShoots,
    },
    weakSignals: <String>{PlantHealthIds.signalLateGreenExcessVigor},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pear_psylla',
        labelEs: 'Psila del peral',
        scientificName: 'Cacopsylla pyricola / C. pyri',
        type: 'insect',
        summaryEs:
            'Riesgo central del peral europeo: insectos chupadores que producen '
            'melaza, negrilla, debilitan el árbol, manchan fruto y pueden '
            'vehicular el decaimiento del peral. Favorecida por vigor tierno y '
            'ruptura de enemigos naturales. Muy alta memoria.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalPsyllaNymphsShoots,
        },
      ),
      PlantHealthDiagnosis(
        id: 'sooty_mold_honeydew_complex',
        labelEs: 'Negrilla / fumagina sobre melaza',
        type: 'fungal_surface_complex',
        summaryEs:
            'Película negra superficial sobre la melaza de chupadores. No es la '
            'causa principal: hay que controlar el insecto (psila/pulgón), no '
            'solo el hongo.',
      ),
      PlantHealthDiagnosis(
        id: 'aphids_complex',
        labelEs: 'Pulgones',
        type: 'insect',
        summaryEs:
            'Colonias en brotes tiernos con melaza y hojas enrolladas, '
            'favorecidas por N alto. Descartar psila si hay decaimiento.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca ninfas/insectos pequeños en brotes y envés de hojas.',
      '¿La melaza viene con negrilla y hojas ennegrecidas?',
      'Revisa si el vigor es muy tierno (favorece psila).',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _psyllaActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),

  // ── Familia 4: Enfermedades de hoja y fruto ──────────────────────────────
  PlantHealthSyndrome(
    id: 'pear_scab_leaf_spot_01',
    cropId: CropCatalog.pearTreeCropId,
    labelEs: 'Manchas oscuras en hoja/fruto en clima húmedo',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomVelvetyOliveSpots,
    strongSignals: <String>{
      PlantHealthIds.signalSpringWetFoliage,
      PlantHealthIds.signalHumidWindow,
    },
    weakSignals: <String>{PlantHealthIds.signalDenseWetCanopy},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'pear_scab',
        labelEs: 'Roña / moteado del peral',
        scientificName: 'Venturia pirina',
        type: 'fungus',
        summaryEs:
            'Lesiones oliva a negras aterciopeladas en hoja y fruto, con '
            'costras, grietas o russeting alrededor. Favorecida por primavera '
            'húmeda y mojado foliar prolongado; inóculo en hojas/twigs.',
      ),
      PlantHealthDiagnosis(
        id: 'fabraea_leaf_spot_black_spot',
        labelEs: 'Mancha foliar Fabraea / black spot',
        scientificName: 'Diplocarpon mespili',
        type: 'fungus',
        summaryEs:
            'Manchas café-negras en hoja con amarillamiento y defoliación en '
            'veranos lluviosos; también en fruto y ramillas. Si defolia antes '
            'de cargar reservas, baja el retorno floral.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalUndersideSporulation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'pear_rust',
        labelEs: 'Roya del peral',
        type: 'fungus',
        summaryEs:
            'Manchas naranja/rojizas en hoja con hospedero alternante '
            '(juníperos/sabinos) cercano y primavera húmeda.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa hojas jóvenes y fruta pequeña tras lluvia o mojado foliar.',
      'Diferencia manchas aterciopeladas (roña) de manchas con defoliación '
          '(Fabraea) y de manchas naranja (roya).',
      'Para roya, ¿hay juníperos/sabinos/cedros cerca?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    varietyModifiers: <VarietyModifier>[
      _prModifier(
        profiles: <String>{kPr05KiefferRustic},
        diagnosisId: 'fabraea_leaf_spot_black_spot',
        delta: 6,
        rationale:
            'Kieffer/rústicas en regiones húmedas y bajo manejo suben Fabraea.',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'pear_fruit_rot_complex_01',
    cropId: CropCatalog.pearTreeCropId,
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
        id: 'bulls_eye_rot_neofabraea',
        labelEs: "Pudrición ojo de buey / bull's eye rot",
        scientificName: 'Neofabraea spp.',
        type: 'fungus',
        summaryEs:
            'Lesiones circulares hundidas con anillos concéntricos que aparecen '
            'en almacenamiento; se origina en huerto con lluvia pre-cosecha y '
            'cancros. Puede verse sano al corte y pudrir en frío.',
      ),
      PlantHealthDiagnosis(
        id: 'storage_rot_complex',
        labelEs: 'Complejo de pudriciones de almacenamiento',
        type: 'fungal_postharvest_complex',
        summaryEs:
            'Golpes, granizo, fruta sobremadura o mojada y mala ventilación '
            'disparan pudriciones después de cosecha. Separa producción '
            'biológica de producción comercial.',
      ),
      PlantHealthDiagnosis(
        id: 'botrytis_gray_mold',
        labelEs: 'Moho gris / Botrytis',
        scientificName: 'Botrytis cinerea',
        type: 'fungus',
        summaryEs:
            'Moho gris en flores viejas, heridas y fruta cerca de cosecha o en '
            'almacén con humedad alta.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si la lesión es hundida con anillos (ojo de buey) o moho gris.',
      'Cruza con lluvia pre-cosecha, granizo, golpes y dosel húmedo.',
      'Guarda el evento de calidad: el riesgo de almacén puede no verse al '
          'corte.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _fruitActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      _prModifier(
        profiles: <String>{kPr02Anjou},
        diagnosisId: 'bulls_eye_rot_neofabraea',
        delta: 8,
        rationale:
            'Anjou es de conservación/almacenaje: las pudriciones de almacén '
            'pesan más en su mercado.',
      ),
    ],
  ),

  // ── Familia 5: Plagas directas de fruto ──────────────────────────────────
  PlantHealthSyndrome(
    id: 'pear_codling_moth_01',
    cropId: CropCatalog.pearTreeCropId,
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
        labelEs: 'Palomilla / carpocapsa / gusano de la pera',
        scientificName: 'Cydia pomonella',
        type: 'insect',
        summaryEs:
            'Principal plaga directa de fruto: perforación con frass y galería '
            'hacia las semillas, con caída prematura. El historial del huerto '
            'pesa cada año.',
      ),
      PlantHealthDiagnosis(
        id: 'stink_bug_lygus_fruit_damage',
        labelEs: 'Chinches / Lygus / daño por picadura',
        type: 'insect',
        summaryEs:
            'Picaduras, deformaciones y tejido corchoso bajo la piel, más en '
            'bordes con maleza o cultivos vecinos. Revisa si el daño es '
            'externo (sin galería interna).',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca perforación con aserrín (frass) y galería hacia la semilla.',
      'Distingue palomilla (galería interna) de chinche (picadura externa) y de '
          'pudrición.',
      'Revisa fruta caída y el historial de palomilla del huerto.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _fruitActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),

  // ── Familia 6: Plagas de hoja/brote (ácaros) ─────────────────────────────
  PlantHealthSyndrome(
    id: 'pear_mites_russet_01',
    cropId: CropCatalog.pearTreeCropId,
    labelEs: 'Bronceado/russeting fino o punteado en hoja/fruto',
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
            'humedad y polvo. Si defolia antes de reservas, pesa en el ciclo '
            'siguiente.',
      ),
      PlantHealthDiagnosis(
        id: 'pear_rust_mite',
        labelEs: 'Ácaro de la roya del peral',
        type: 'mite',
        summaryEs:
            'Bronceado/russeting fino en hoja y fruto, difícil de ver sin lupa. '
            'No confundir con roña o golpe de sol.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa envés de hojas con lupa: telaraña fina o ácaros diminutos.',
      'Cruza con calor y humedad baja recientes.',
      'Diferencia russeting de ácaro del russet varietal (Bosc) o de roña.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
  ),

  // ── Familia 7: Estrés fisiológico, clima y calidad ───────────────────────
  PlantHealthSyndrome(
    id: 'pear_sunburn_01',
    cropId: CropCatalog.pearTreeCropId,
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
    id: 'pear_cork_spot_01',
    cropId: CropCatalog.pearTreeCropId,
    labelEs: 'Puntos hundidos o tejido corchoso en el fruto (cork spot)',
    stages: _fruitStages,
    organIds: <String>{PlantHealthIds.organFruit},
    primarySymptomId: PlantHealthIds.symptomFruitSunkenPits,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalDryHotWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cork_spot_calcium_functional',
        labelEs: 'Cork spot / calcio funcional / tejido corchoso',
        type: 'abiotic_physiological',
        summaryEs:
            'Manchas hundidas/corchosas bajo piel o en pulpa, ligadas a calcio '
            'funcional bajo, vigor alto, exceso de N/K, baja carga y riego '
            'irregular. Se lee como balance agua-vigor-carga, no como receta de '
            'calcio.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si las manchas aparecen o crecen en almacenamiento.',
      'Cruza con vigor alto, N/K altos, baja carga y riego irregular.',
      'En v1 no apliques calcio a ciegas: confirma el balance primero.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: _fruitActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      _prModifier(
        profiles: <String>{kPr03Bosc, kPr04SeckelComice},
        diagnosisId: 'cork_spot_calcium_functional',
        delta: 5,
        rationale:
            'Bosc/Comice pueden requerir más atención a Mg y balance Ca/K '
            '(OSU).',
      ),
    ],
  ),
  PlantHealthSyndrome(
    id: 'pear_iron_chlorosis_01',
    cropId: CropCatalog.pearTreeCropId,
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
