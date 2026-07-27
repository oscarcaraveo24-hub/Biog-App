import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Sanidad del Nopal ornamental (Documento C, NO v1.0).
///
/// Contrato de seguridad (Doc C section 1) - inviolable:
/// - BIO-G **no** diagnostica un organismo causal (ni hongo, ni bacteria, ni
///   virus, ni fitoplasma, ni insecto) y **no** dice "tiene mancha negra" ni
///   "tiene cochinilla" como hecho confirmado.
/// - **No** receta plaguicidas, dosis, mezclas ni frecuencias.
/// - **No** certifica comestibilidad de una penca ni de una tuna, y **no**
///   decide cuando cortar: el aprovechamiento lo decide el usuario.
/// - El sensor por si solo **nunca** genera una alerta sanitaria alta: los
///   sindromes requieren observacion del usuario.
/// - **No** se pide tocar gloquidios, espinas, tejido blando, exudados ni
///   insectos con la mano desnuda (Doc C section 1.5).
/// - BIO-G **no** declara una plaga cuarentenaria ni ordena destruir una
///   planta. Ante un patron de alta consecuencia pide NO MOVER material y
///   buscar revision de la autoridad vegetal local (Doc C section 1.6).
///
/// Estructura espejo de `agave_syndromes.dart`; textos e ids son propios.
///
/// v1 tiene **18 sindromes** (S01..S18): ninguno se difiere. La severidad y la
/// urgencia estan CONGELADAS en un solo valor por sindrome (el motor no
/// escala); donde el documento proponia una escalada condicional se tomo el
/// valor mas conservador. Ver `temp/nopal/DECISIONES_INTEGRACION.md`.
const Set<PlantHealthStageBucket> _nopalStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.lateSeason,
};

const String _nopalDisclaimer =
    'BIO-G organiza observaciones y contexto para orientar la revision. '
    'No confirma una enfermedad, una plaga ni un organismo causal.';

/// Aviso adicional para los patrones de ALTA CONSECUENCIA fitosanitaria
/// (Doc C section 1.7). No declara una plaga cuarentenaria: pide no mover
/// material y buscar revision oficial.
const String _nopalHighConsequenceDisclaimer =
    'Esta combinacion de senales requiere descartar una plaga de importancia '
    'fitosanitaria. No muevas pencas ni material de la planta y busca revision '
    'de la autoridad vegetal local. BIO-G no confirma ni declara una plaga.';

const List<PlantHealthSyndrome> nopalSyndromes = <PlantHealthSyndrome>[
  // ── S01 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_black_map_spots_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Manchas negras redondas o con forma de mapa',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalBlackMapSpots,
    strongSignals: <String>{
      PlantHealthIds.signalNopalCircularBlackSpot,
      PlantHealthIds.signalNopalMapLikeBlackPattern,
      PlantHealthIds.signalNopalSmallBlackDotsOnLesion,
      PlantHealthIds.signalNopalLesionExpands,
      PlantHealthIds.signalNopalLowerPadsWorse,
      PlantHealthIds.signalHumidWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalDenseWetCanopy,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalNopalRainSplash,
      PlantHealthIds.signalNopalSpotVisibleBothSides,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalRaisedDryScab,
      PlantHealthIds.signalNopalSoftWatery,
      PlantHealthIds.signalNopalSunnySide,
      PlantHealthIds.signalNopalOneSidedHailPattern,
      PlantHealthIds.signalNopalStableScar,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_black_spot_pseudocercospora_compatible',
        labelEs: 'Condición compatible con mancha negra del nopal',
        scientificName:
            'Pseudocercospora opuntiae',
        type: 'condition_compatible',
        summaryEs:
            'Lo que se ve coincide con la mancha negra que se ha estudiado en '
            'nopal en México: empieza como un punto café que se oscurece, '
            'primero redondo, y al juntarse varias manchas queda un dibujo '
            'tipo mapa. Suele aparecer o crecer después de lluvias, riegos '
            'que mojan la planta o rocío persistente. Esto no confirma el '
            'organismo; hace falta revisión local para saberlo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalCircularBlackSpot,
          PlantHealthIds.signalNopalMapLikeBlackPattern,
          PlantHealthIds.signalNopalLesionExpands,
          PlantHealthIds.signalNopalLowerPadsWorse,
          PlantHealthIds.signalHumidWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalRaisedDryScab,
          PlantHealthIds.signalNopalStableScar,
          PlantHealthIds.signalNopalOneSidedHailPattern,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_phyllosticta_pad_spot_possible',
        labelEs: 'Mancha de penca con puntos negros posible',
        scientificName:
            'Phyllosticta sp.',
        type: 'condition_compatible',
        summaryEs:
            'Cuando la mancha se ve casi negra, seca y con muchos puntitos '
            'negros muy pequeños dentro, encaja con otro grupo de hongos de '
            'penca. Es más común en las pencas de abajo y donde la humedad se '
            'queda mucho tiempo; a veces el centro de la mancha se desprende. '
            'Es solo una posibilidad para revisar, no una identificación.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalSmallBlackDotsOnLesion,
          PlantHealthIds.signalNopalLowerPadsWorse,
          PlantHealthIds.signalHumidWindow,
          PlantHealthIds.signalNopalRainSplash,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalSoftWatery,
          PlantHealthIds.signalNopalSunnySide,
          PlantHealthIds.signalNopalStableScar,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_abiotic_spot_differential',
        labelEs: 'Daño ambiental o herida antigua posible',
        type: 'abiotic_possible',
        summaryEs:
            'Si las marcas aparecieron todas al mismo tiempo después de '
            'granizo, sol fuerte o un golpe, y desde entonces no han '
            'cambiado, lo más probable es que sean huellas de ese evento y no '
            'algo que siga avanzando. Ayuda que estén solo del lado expuesto '
            'y que el tejido siga firme. Vale la pena marcarlas y compararlas '
            'en la siguiente revisión.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalOneSidedHailPattern,
          PlantHealthIds.signalNopalSunnySide,
          PlantHealthIds.signalNopalStableScar,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalLesionExpands,
          PlantHealthIds.signalHumidWindow,
          PlantHealthIds.signalNopalSmallBlackDotsOnLesion,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La mancha empezó redonda?',
      '¿Se unieron formando un dibujo tipo mapa?',
      '¿Ves puntitos negros dentro de la mancha?',
      '¿Creció desde la última revisión?',
      '¿Está solo del lado del sol o apareció después de granizo?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Fotografía el frente y el reverso de la penca.',
      'Marca el límite de la mancha para compararlo en la siguiente revisión.',
      'Evita mojar las pencas y revisa que el agua no se quede.',
      'No uses pencas afectadas para propagar.',
      'Busca revisión de un técnico local si la mancha sigue avanzando.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
    favorsRecentStress: true,
  ),

  // ── S02 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_raised_black_scab_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Costras oscuras, elevadas o secas sobre la penca',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalRaisedBlackScab,
    strongSignals: <String>{
      PlantHealthIds.signalNopalRaisedDryScab,
      PlantHealthIds.signalNopalLightBrownToBlack,
      PlantHealthIds.signalNopalPaleDeadBorder,
      PlantHealthIds.signalNopalSurfaceOnly,
      PlantHealthIds.signalNopalScabDetaches,
      PlantHealthIds.signalNopalScarOrDeformity,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalNopalMultipleScabs,
      PlantHealthIds.signalNopalReducedGreenArea,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalSoftWatery,
      PlantHealthIds.signalNopalUniformCorkingAtBase,
      PlantHealthIds.signalNopalKnownImpact,
      PlantHealthIds.signalNopalDarkExudate,
      PlantHealthIds.signalNopalCottonWax,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_black_scab_complex_compatible',
        labelEs: 'Condición compatible con costra negra del nopal',
        scientificName:
            'Complejo asociado en investigación mexicana: Cladosporium '
            'cladosporioides, Aplosporella hesperidica, Didymella glomerata',
        type: 'condition_compatible',
        summaryEs:
            'La lesión que empieza café clara, se oscurece, queda elevada y '
            'seca y tiene un borde pálido muerto coincide con lo que se llama '
            'costra negra del nopal. En la investigación aparece como un '
            'complejo de varios hongos, no como una sola especie, así que no '
            'se puede señalar un culpable único. Cuando se desprende suele '
            'dejar cicatriz y puede deformar la penca.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalRaisedDryScab,
          PlantHealthIds.signalNopalLightBrownToBlack,
          PlantHealthIds.signalNopalPaleDeadBorder,
          PlantHealthIds.signalNopalScabDetaches,
          PlantHealthIds.signalNopalScarOrDeformity,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalUniformCorkingAtBase,
          PlantHealthIds.signalNopalSoftWatery,
          PlantHealthIds.signalNopalKnownImpact,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_normal_corking_possible',
        labelEs: 'Corchado o envejecimiento normal posible',
        type: 'benign_differential',
        summaryEs:
            'Con los años la base del nopal se endurece y toma un color café '
            'claro parejo, como corteza: eso es normal y no es una '
            'enfermedad. Se reconoce porque el tejido está firme, el cambio '
            'es uniforme alrededor de la base y no aumenta de una revisión a '
            'otra. Si solo ves eso, basta con seguir observando.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalUniformCorkingAtBase,
          PlantHealthIds.signalNopalSurfaceOnly,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalScabDetaches,
          PlantHealthIds.signalNopalPaleDeadBorder,
          PlantHealthIds.signalNopalMultipleScabs,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_old_wound_scar_possible',
        labelEs: 'Cicatriz antigua posible',
        type: 'abiotic_possible',
        summaryEs:
            'Si recuerdas un golpe, granizo o roce en ese punto y la marca '
            'lleva tiempo igual, lo más probable es que sea una cicatriz ya '
            'cerrada. Ayuda que sea una sola lesión, con el borde estable y '
            'sin tejido blando alrededor. Conviene fotografiarla para '
            'comprobar que sigue sin cambiar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalKnownImpact,
          PlantHealthIds.signalNopalScarOrDeformity,
          PlantHealthIds.signalNopalSurfaceOnly,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalMultipleScabs,
          PlantHealthIds.signalNopalReducedGreenArea,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La costra sobresale y se siente seca?',
      '¿Empezó café clara y se volvió negra?',
      '¿Tiene un borde pálido alrededor?',
      '¿Se desprende y deja cicatriz?',
      '¿Está solo en la base vieja y firme?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Compara las costras nuevas con las viejas de la base.',
      'Fotografía con luz de lado para que se note el relieve.',
      'No rasques ni desprendas la costra.',
      'Anota si el área verde de la penca se va reduciendo.',
      'Busca revisión local si aparecen muchas lesiones nuevas.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── S03 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_dry_canker_crack_exudate_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Grieta, lesión seca o líquido oscuro en una penca',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organStem,
      PlantHealthIds.organNeck,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalCankerCrackExudate,
    strongSignals: <String>{
      PlantHealthIds.signalNopalDrySunkenCanker,
      PlantHealthIds.signalNopalCrackedTissue,
      PlantHealthIds.signalNopalDarkExudate,
      PlantHealthIds.signalNopalBlackGum,
      PlantHealthIds.signalNopalLesionExpands,
      PlantHealthIds.signalNopalPadDiesBeyondLesion,
    },
    weakSignals: <String>{
      PlantHealthIds.signalNopalPriorWound,
      PlantHealthIds.signalNopalAbnormalOdor,
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalStableScar,
      PlantHealthIds.signalNopalCleanCut,
      PlantHealthIds.signalNopalUniformCorkingAtBase,
      PlantHealthIds.signalNopalSurfaceOnly,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_dry_canker_fungal_complex_compatible',
        labelEs: 'Condición compatible con cancro o necrosis profunda',
        scientificName:
            'Grupos posibles: Lasiodiplodia, Fusarium y otros hongos de '
            'cladodio',
        type: 'condition_compatible',
        summaryEs:
            'Una lesión hundida, agrietada, que sigue secando tejido y que a '
            'veces suelta un líquido o goma oscura encaja con un cancro '
            'profundo de la penca. Casi siempre empieza en una herida previa: '
            'un corte, un golpe o una entrada de insecto. Es un patrón de '
            'varios hongos, así que no se puede nombrar uno solo sin '
            'revisión.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalDrySunkenCanker,
          PlantHealthIds.signalNopalCrackedTissue,
          PlantHealthIds.signalNopalDarkExudate,
          PlantHealthIds.signalNopalPadDiesBeyondLesion,
          PlantHealthIds.signalNopalPriorWound,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalCleanCut,
          PlantHealthIds.signalNopalStableScar,
          PlantHealthIds.signalNopalSurfaceOnly,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_bacterial_decay_entry_possible',
        labelEs: 'Deterioro bacteriano secundario posible',
        type: 'condition_compatible',
        summaryEs:
            'Cuando la herida escurre líquido, huele mal y el tejido pasa de '
            'firme a blando en poco tiempo, puede haber un deterioro '
            'bacteriano metido en la herida. Suele avanzar más rápido que una '
            'lesión seca. Este cambio de olor y textura es la señal que más '
            'conviene vigilar entre revisiones.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalAbnormalOdor,
          PlantHealthIds.signalNopalDarkExudate,
          PlantHealthIds.signalNopalLesionExpands,
          PlantHealthIds.signalNopalPriorWound,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalStableScar,
          PlantHealthIds.signalNopalSurfaceOnly,
          PlantHealthIds.signalNopalCleanCut,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_clean_cut_healing_possible',
        labelEs: 'Corte limpio en cicatrización posible',
        type: 'benign_differential',
        summaryEs:
            'Si en ese punto hubo un corte o una poda, un borde seco y parejo '
            'con callo uniforme es la forma normal en que el nopal cierra la '
            'herida. Se reconoce porque no huele, no crece y el tejido de '
            'alrededor sigue firme. Basta con no volver a lastimar esa zona.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalCleanCut,
          PlantHealthIds.signalNopalStableScar,
          PlantHealthIds.signalNopalSurfaceOnly,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalDarkExudate,
          PlantHealthIds.signalNopalLesionExpands,
          PlantHealthIds.signalNopalAbnormalOdor,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_insect_wound_possible',
        labelEs: 'Herida de insecto o barrenador posible',
        type: 'arthropod_possible',
        summaryEs:
            'Un agujero con excremento alrededor o una galería por dentro '
            'apunta a que un insecto abrió la herida y el hongo entró '
            'después. Conviene fotografiar el agujero de cerca, sin tocarlo '
            'ni meter nada. Si hay larvas dentro de la penca, revisa también '
            'el apartado de hilera de huevos y penca hueca.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalFeedingHoles,
          PlantHealthIds.signalFrassPresent,
          PlantHealthIds.signalNopalPriorWound,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalStableScar,
          PlantHealthIds.signalNopalCleanCut,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La lesión está hundida o agrietada?',
      '¿Sale líquido oscuro o goma negra?',
      '¿Hay mal olor?',
      '¿La zona seca creció desde la última revisión?',
      '¿Ves agujeros o excremento cerca de la lesión?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'No toques el exudado ni la lesión.',
      'Fotografía la lesión y marca su borde para comparar.',
      'Evita hacer nuevas heridas y limpia las herramientas antes de pasar a '
      'otra planta.',
      'No uses esa penca para propagar.',
      'Busca evaluación local si la lesión se acerca a la base.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── S04 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_soft_water_soaked_tissue_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Tejido blando, acuoso o hundido',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organCrown,
      PlantHealthIds.organNeck,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalSoftWaterSoakedTissue,
    strongSignals: <String>{
      PlantHealthIds.signalNopalSoftWatery,
      PlantHealthIds.signalNopalSunkenWetArea,
      PlantHealthIds.signalNopalTissueBreakdown,
      PlantHealthIds.signalNopalDarkSoftMargin,
      PlantHealthIds.signalNopalAbnormalOdor,
      PlantHealthIds.signalNopalRapidProgression,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalNopalPriorWound,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalFirmDry,
      PlantHealthIds.signalNopalStableScar,
      PlantHealthIds.signalNopalSeasonalShriveling,
      PlantHealthIds.signalNopalNormalYoungPad,
      PlantHealthIds.signalNopalBleachedPatch,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_soft_rot_complex_compatible',
        labelEs: 'Condición compatible con deterioro blando de tejido',
        scientificName:
            'Complejo posible: Pectobacterium, Pythium, Fusarium u otros '
            'microorganismos, casi siempre después de una herida',
        type: 'condition_compatible',
        summaryEs:
            'Una zona hundida, acuosa, con borde oscuro y que a veces huele '
            'mal encaja con un deterioro blando del tejido. Suele ir junto '
            'con suelo encharcado, riegos seguidos o una herida por donde '
            'entró el problema. Este patrón puede avanzar en horas, por eso '
            'conviene revisarlo el mismo día.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalSoftWatery,
          PlantHealthIds.signalNopalSunkenWetArea,
          PlantHealthIds.signalNopalAbnormalOdor,
          PlantHealthIds.signalNopalRapidProgression,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalFirmDry,
          PlantHealthIds.signalNopalNormalYoungPad,
          PlantHealthIds.signalNopalStableScar,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_cold_softening_possible',
        labelEs: 'Tejido alterado por frío posible',
        type: 'abiotic_possible',
        summaryEs:
            'Después de una helada el tejido se ve primero translúcido, como '
            'mojado, y luego se pone negro. Se distingue porque el cambio '
            'aparece al mismo tiempo en varias zonas expuestas y no en un '
            'solo punto. Si hubo frío fuerte esos días, anótalo junto con la '
            'foto.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalNopalTissueBreakdown,
          PlantHealthIds.signalNopalDarkSoftMargin,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalNormalYoungPad,
          PlantHealthIds.signalNopalFirmDry,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_impact_breakdown_possible',
        labelEs: 'Daño interno después de golpe posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un golpe, una caída o granizo pueden reventar el tejido por '
            'dentro y dejar una zona blanda localizada días después. Ayuda a '
            'reconocerlo que sea un solo punto, que coincida con el lugar del '
            'impacto y que las demás plantas estén bien. Aun así conviene '
            'vigilarlo, porque esa zona se puede deteriorar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalPriorWound,
          PlantHealthIds.signalNopalSunkenWetArea,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalRapidProgression,
          PlantHealthIds.signalWaterlogging,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_normal_tender_growth_differential',
        labelEs: 'Penca joven normal como diferencial',
        type: 'benign_differential',
        summaryEs:
            'Las pencas nuevas son blandas y tiernas en toda su superficie y '
            'se endurecen conforme maduran: eso es crecimiento normal. Se '
            'diferencia de un problema porque el color es parejo, no hay una '
            'zona hundida localizada y no hay olor. Si la penca completa está '
            'tierna y creciendo, solo obsérvala.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalNormalYoungPad,
          PlantHealthIds.signalNopalFirmDry,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalAbnormalOdor,
          PlantHealthIds.signalNopalSunkenWetArea,
          PlantHealthIds.signalNopalTissueBreakdown,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La zona se hunde al presionar con una herramienta?',
      '¿Se ve acuosa o translúcida?',
      '¿Hay mal olor?',
      '¿Creció en horas o en pocos días?',
      '¿Es una penca nueva completa o solo una zona localizada?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Suspende los riegos mientras el suelo siga húmedo.',
      'Separa temporalmente la maceta de las demás plantas.',
      'No cortes ni propagues esa penca sin evaluación.',
      'Fotografía la textura y la ubicación exacta de la zona blanda.',
      'Busca revisión local si el tejido sigue cediendo.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── S05 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_root_collar_decline_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Pérdida de soporte o decaimiento desde la base',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organNeck,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalRootCollarDecline,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalNopalBaseSoft,
      PlantHealthIds.signalNopalLossOfSupport,
      PlantHealthIds.signalNopalWiltsWhileSoilWet,
      PlantHealthIds.signalNopalAbnormalOdor,
    },
    weakSignals: <String>{
      PlantHealthIds.signalNopalFewFineRoots,
      PlantHealthIds.signalNopalRecentTransplant,
      PlantHealthIds.signalNopalPlantingTooDeep,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalRootsFirmLightTips,
      PlantHealthIds.signalNopalDrySoilDuringWrinkling,
      PlantHealthIds.signalNopalOnePadOnly,
      PlantHealthIds.signalNopalStableOldLean,
      PlantHealthIds.signalNopalCleanBreak,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_root_collar_rot_compatible',
        labelEs: 'Condición compatible con deterioro de raíz o cuello',
        type: 'condition_compatible',
        summaryEs:
            'Una base blanda, raíces oscuras y una planta que se marchita '
            'aunque el suelo siga mojado apuntan a un deterioro en la raíz o '
            'el cuello. El mal olor en la base refuerza esa idea. No se puede '
            'decir qué organismo es sin una revisión, pero es de las '
            'situaciones que más rápido pueden tirar la planta.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalNopalBaseSoft,
          PlantHealthIds.signalNopalAbnormalOdor,
          PlantHealthIds.signalNopalWiltsWhileSoilWet,
          PlantHealthIds.signalNopalFewFineRoots,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalRootsFirmLightTips,
          PlantHealthIds.signalNopalCleanBreak,
          PlantHealthIds.signalNopalStableOldLean,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_root_asphyxia_possible',
        labelEs: 'Asfixia radicular por exceso de agua posible',
        type: 'abiotic_possible',
        summaryEs:
            'Cuando el suelo o la maceta se queda saturado, la raíz se queda '
            'sin aire y la planta se ve caída aunque no le falte agua. Se '
            'sospecha sobre todo si hubo un riego fuerte o lluvia reciente y '
            'el drenaje está tapado. Aquí el punto a revisar es por dónde '
            'sale el agua, no la planta.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalNopalWiltsWhileSoilWet,
          PlantHealthIds.signalNopalFewFineRoots,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalDrySoilDuringWrinkling,
          PlantHealthIds.signalNopalCleanBreak,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_transplant_instability_possible',
        labelEs: 'Inestabilidad de trasplante posible',
        type: 'abiotic_possible',
        summaryEs:
            'Una planta recién instalada puede bambolearse simplemente porque '
            'todavía no ancla bien o quedó sembrada muy profunda. Se '
            'distingue porque la base sigue firme, las raíces se ven claras y '
            'no hay olor ni avance. Suele resolverse con tiempo y con revisar '
            'la profundidad y el soporte.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalRecentTransplant,
          PlantHealthIds.signalNopalRootsFirmLightTips,
          PlantHealthIds.signalNopalPlantingTooDeep,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalBaseSoft,
          PlantHealthIds.signalNopalAbnormalOdor,
          PlantHealthIds.signalRootsDarkRot,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_basal_mechanical_break_possible',
        labelEs: 'Ruptura mecánica de la base posible',
        type: 'abiotic_possible',
        summaryEs:
            'El viento, el peso de las pencas o un golpe pueden romper la '
            'unión de la base sin que haya ninguna pudrición. Se reconoce '
            'porque la ruptura se ve limpia y el tejido alrededor sigue firme '
            'y seco. Aun así conviene proteger esa herida para que no entre '
            'nada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalCleanBreak,
          PlantHealthIds.signalNopalLossOfSupport,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalBaseSoft,
          PlantHealthIds.signalNopalAbnormalOdor,
          PlantHealthIds.signalRootsDarkRot,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La base está firme o blanda?',
      '¿La planta perdió el anclaje?',
      '¿El suelo sigue mojado?',
      '¿Hay mal olor en la base?',
      '¿Fue trasplantada hace poco o quedó muy profunda?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'No sostengas ni endereces el nopal con la mano desnuda.',
      'Revisa el drenaje y no riegues sobre suelo saturado.',
      'Fotografía la base y el nivel de plantación.',
      'Evita mover la planta hasta que alguien la revise.',
      'Busca evaluación local si sigue perdiendo soporte.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── S06 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_chlorotic_rings_mosaic_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Círculos amarillos, mosaico o manchas cloróticas',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalChloroticRingsMosaic,
    strongSignals: <String>{
      PlantHealthIds.signalNopalYellowRings,
      PlantHealthIds.signalNopalMosaicPattern,
      PlantHealthIds.signalNopalChloroticHalo,
      PlantHealthIds.signalNopalPatternRepeats,
      PlantHealthIds.signalNopalPatternOnNewPads,
      PlantHealthIds.signalNopalIrregularMottling,
    },
    weakSignals: <String>{
      PlantHealthIds.signalNopalPropagationHistory,
      PlantHealthIds.signalNopalMultiplePadsAffected,
      PlantHealthIds.signalNopalPersistentDeformation,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalSunnySide,
      PlantHealthIds.signalNopalUniformChlorosis,
      PlantHealthIds.signalNopalTanScar,
      PlantHealthIds.signalNopalFreshSprayPattern,
      PlantHealthIds.signalNopalNoRepeat,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_virus_pattern_compatible',
        labelEs: 'Patrón compatible con virus de Opuntia por confirmar',
        scientificName:
            'Grupos posibles: Sammons\' Opuntia virus, Cactus virus X u otros '
            'potexvirus y tobamovirus',
        type: 'condition_compatible',
        summaryEs:
            'Los anillos amarillos y el mosaico que se repiten también en las '
            'pencas nuevas son el patrón típico de un virus de Opuntia. '
            'Muchas veces viajan en el material de propagación, por eso '
            'importa saber de dónde salió la penca. Un patrón no basta para '
            'saber qué virus es ni qué tan grave será: eso solo se confirma '
            'con análisis.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalYellowRings,
          PlantHealthIds.signalNopalMosaicPattern,
          PlantHealthIds.signalNopalPatternRepeats,
          PlantHealthIds.signalNopalPatternOnNewPads,
          PlantHealthIds.signalNopalPropagationHistory,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalUniformChlorosis,
          PlantHealthIds.signalNopalSunnySide,
          PlantHealthIds.signalNopalNoRepeat,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_sammons_ring_benign_possible',
        labelEs: 'Anillos persistentes con impacto limitado posible',
        type: 'benign_differential',
        summaryEs:
            'Hay anillos que se quedan años en la penca sin que la planta '
            'pierda vigor ni se deforme. Se reconocen porque el dibujo es '
            'estable, la planta sigue creciendo bien y no aparece necrosis. '
            'En ese caso lo razonable es observar y no propagar de esas '
            'pencas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalYellowRings,
          PlantHealthIds.signalNopalChloroticHalo,
          PlantHealthIds.signalNopalPatternRepeats,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalPersistentDeformation,
          PlantHealthIds.signalNopalUniformChlorosis,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_nutrient_or_ph_chlorosis_possible',
        labelEs: 'Clorosis por suelo o nutrición posible',
        type: 'abiotic_possible',
        summaryEs:
            'Cuando el amarillamiento es parejo en toda la penca y no forma '
            'anillos ni mosaico, suele tener que ver con el suelo: pH alto, '
            'sales o un crecimiento pobre en general. Afecta a la planta '
            'completa y no dibuja figuras. No conviene dar por hecho una '
            'deficiencia solo por el color.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalUniformChlorosis,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalYellowRings,
          PlantHealthIds.signalNopalMosaicPattern,
          PlantHealthIds.signalNopalPatternRepeats,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_sun_or_spray_pattern_possible',
        labelEs: 'Daño de exposición o aspersión posible',
        type: 'abiotic_possible',
        summaryEs:
            'El sol directo o algo que se roció encima pueden dejar manchas '
            'claras que aparecieron todas el mismo día. La pista principal es '
            'que están del lado expuesto y que el crecimiento nuevo sale '
            'limpio. Si aplicaste algo hace poco, anota qué fue y cuándo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalSunnySide,
          PlantHealthIds.signalNopalFreshSprayPattern,
          PlantHealthIds.signalNopalNoRepeat,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalPatternOnNewPads,
          PlantHealthIds.signalNopalPatternRepeats,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Son anillos o círculos amarillos?',
      '¿El mismo dibujo se repite en las pencas nuevas?',
      '¿La planta sigue creciendo bien?',
      '¿Hay deformación en el crecimiento nuevo?',
      '¿Está solo del lado del sol o aplicaste algo hace poco?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'No uses pencas con este patrón para propagar.',
      'Fotografía varias pencas, incluidas las más nuevas.',
      'Compara el crecimiento nuevo en cada revisión.',
      'No des por hecho que es falta de nutrientes solo por el color.',
      'Busca confirmación local si el patrón avanza o deforma.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsRecentStress: true,
  ),

  // ── S07 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_white_cotton_wax_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Algodón blanco o cera pegada a la penca',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organStem,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalWhiteCottonWax,
    strongSignals: <String>{
      PlantHealthIds.signalNopalCottonWax,
      PlantHealthIds.signalNopalColoniesOnAreoles,
      PlantHealthIds.signalNopalRedMaterialUnderWax,
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
      PlantHealthIds.signalNopalPadYellowingNearColony,
    },
    weakSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalNopalDryingPads,
      PlantHealthIds.signalNopalFruitDrop,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalNopalMineralResidue,
      PlantHealthIds.signalNopalNormalGlochids,
      PlantHealthIds.signalMitesWebbing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_dactylopius_possible',
        labelEs: 'Cochinilla del nopal posible',
        scientificName:
            'Dactylopius spp.',
        type: 'arthropod_possible',
        summaryEs:
            'El algodón blanco pegado en colonias sobre las areolas, con '
            'material rojizo debajo de la cera, es el patrón de la cochinilla '
            'del nopal. El color rojo apoya el género, pero no permite '
            'distinguir entre la cochinilla de grana y las especies que dañan '
            'la penca. Si la penca amarillea alrededor de las colonias, '
            'conviene revisarlo pronto.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalCottonWax,
          PlantHealthIds.signalNopalColoniesOnAreoles,
          PlantHealthIds.signalNopalRedMaterialUnderWax,
          PlantHealthIds.signalNopalPadYellowingNearColony,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalNormalGlochids,
          PlantHealthIds.signalWhitePowderGrowth,
          PlantHealthIds.signalNopalMineralResidue,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_other_scale_or_mealybug_possible',
        labelEs: 'Otra escama o cochinilla posible',
        type: 'arthropod_possible',
        summaryEs:
            'Hay otras escamas y cochinillas harinosas que también dejan cera '
            'blanca, pero sin material rojizo debajo. Suelen venir '
            'acompañadas de melaza pegajosa y de un tizne negro que crece '
            'sobre esa melaza. La identificación cambia el manejo, así que '
            'conviene confirmarla antes de hacer nada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalSootyMold,
          PlantHealthIds.signalNopalCottonWax,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalRedMaterialUnderWax,
          PlantHealthIds.signalNopalNormalGlochids,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_normal_glochid_tuft_differential',
        labelEs: 'Gloquidios o areolas normales posibles',
        type: 'benign_differential',
        summaryEs:
            'Las areolas del nopal tienen mechones claros que se ven parejos '
            'y repartidos en toda la planta: eso es normal. Se distingue de '
            'una plaga porque el patrón es regular, no se expande, no hay '
            'melaza y no se ven insectos. No hace falta tocarlos para '
            'comprobarlo, basta una foto de cerca.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalNormalGlochids,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalColoniesOnAreoles,
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalNopalPadYellowingNearColony,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_fungal_powder_differential',
        labelEs: 'Crecimiento superficial por confirmar',
        type: 'condition_compatible',
        summaryEs:
            'Si lo blanco se ve como polvo continuo que se extiende por la '
            'superficie y no como bultos de cera en colonias, puede ser un '
            'crecimiento superficial distinto. La diferencia se nota en la '
            'textura: polvo parejo contra cera en montoncitos. Una foto de '
            'cerca con buena luz ayuda a distinguirlo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWhitePowderGrowth,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalCottonWax,
          PlantHealthIds.signalNopalRedMaterialUnderWax,
          PlantHealthIds.signalNopalColoniesOnAreoles,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Son colonias irregulares o puntos regulares en toda la planta?',
      '¿Está pegado a las areolas?',
      '¿Hay material rojizo debajo de la cera?',
      '¿La penca amarillea alrededor?',
      '¿Hay melaza pegajosa o tizne negro?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'No toques las colonias ni la cera con la mano.',
      'Fotografía de cerca y también la planta completa.',
      'Separa la maceta de las demás si es posible.',
      'Revisa las otras Opuntia cercanas y no propagues material.',
      'Busca identificación local antes de aplicar cualquier cosa.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),

  // ── S08 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_pale_sucking_blotches_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Manchas pálidas o cafés alrededor de puntos de alimentación',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organStem,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomNopalSuckingBlotches,
    strongSignals: <String>{
      PlantHealthIds.signalNopalPaleFeedingBlotch,
      PlantHealthIds.signalNopalTanScar,
      PlantHealthIds.signalNopalPlantBugPresent,
      PlantHealthIds.signalNopalLeafFootedBugPresent,
      PlantHealthIds.signalNopalSapSuckingPunctures,
      PlantHealthIds.signalNopalFeedingClusters,
    },
    weakSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalNopalYoungPad,
      PlantHealthIds.signalNopalFlowerOrFruitDamage,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalMapLikeBlackPattern,
      PlantHealthIds.signalNopalRaisedDryScab,
      PlantHealthIds.signalNopalSunnySide,
      PlantHealthIds.signalNopalNoInsectAndStable,
      PlantHealthIds.signalNopalImpactCrater,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_cactus_bug_feeding_possible',
        labelEs: 'Daño de chinche del cactus posible',
        scientificName:
            'Chelinidea vittiger, Narnia spp. u otros coreidos y míridos',
        type: 'arthropod_possible',
        summaryEs:
            'Las manchitas pálidas agrupadas alrededor de picaduras son el '
            'rastro típico de chinches que chupan savia. Se suelen ver en '
            'grupo y afectan sobre todo el tejido nuevo. Si ves los insectos '
            'junto a las manchas, fotografíalos sin tocarlos para que alguien '
            'los identifique.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalPlantBugPresent,
          PlantHealthIds.signalNopalPaleFeedingBlotch,
          PlantHealthIds.signalNopalSapSuckingPunctures,
          PlantHealthIds.signalNopalFeedingClusters,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalNoInsectAndStable,
          PlantHealthIds.signalNopalMapLikeBlackPattern,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_leaf_footed_bug_possible',
        labelEs: 'Chinche de patas foliáceas posible',
        type: 'arthropod_possible',
        summaryEs:
            'Son chinches grandes con las patas traseras ensanchadas, como '
            'hojitas, y dejan cicatrices cafés donde pican. Suelen buscar los '
            'frutos y los brotes más que la penca vieja. Verlas temprano o al '
            'atardecer es la mejor forma de saber si siguen activas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalLeafFootedBugPresent,
          PlantHealthIds.signalNopalTanScar,
          PlantHealthIds.signalNopalFlowerOrFruitDamage,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalNoInsectAndStable,
          PlantHealthIds.signalNopalSunnySide,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_cosmetic_sucking_scar_possible',
        labelEs: 'Cicatriz cosmética de alimentación posible',
        type: 'visual_concern',
        summaryEs:
            'Cuando quedan unos pocos puntos, el tejido sigue firme y ya no '
            'hay insectos, lo más probable es que sea la marca de una '
            'alimentación vieja. Afecta la apariencia pero no el vigor de la '
            'planta. Conviene compararlo en la siguiente revisión para '
            'confirmar que no cambia.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalNoInsectAndStable,
          PlantHealthIds.signalNopalTanScar,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalFeedingClusters,
          PlantHealthIds.signalNopalPlantBugPresent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_fungal_spot_differential',
        labelEs: 'Mancha no relacionada con insectos posible',
        type: 'condition_compatible',
        summaryEs:
            'Si las manchas siguen creciendo aunque nunca veas insectos ni '
            'picaduras, puede tratarse de otra cosa. Las manchas oscuras tipo '
            'mapa o las costras elevadas y secas van por otro camino. En ese '
            'caso revisa los apartados de manchas negras y de costras.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalMapLikeBlackPattern,
          PlantHealthIds.signalNopalRaisedDryScab,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalPlantBugPresent,
          PlantHealthIds.signalNopalSapSuckingPunctures,
          PlantHealthIds.signalNopalFeedingClusters,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Ves chinches sobre la planta?',
      '¿Las manchas están junto a picaduras?',
      '¿Afectan sobre todo las pencas o brotes nuevos?',
      '¿El tejido sigue firme?',
      '¿Las manchas se extienden aunque no veas insectos?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Fotografía el insecto y la mancha en la misma toma.',
      'Revisa temprano y al atardecer, que es cuando se ven mejor.',
      'Distingue el daño viejo de la alimentación activa.',
      'No apliques un tratamiento general sin identificar el insecto.',
      'Busca orientación local si la población aumenta.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),

  // ── S09 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_egg_stick_frass_hollow_pad_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Hilera de huevos, excremento o penca vaciada por dentro',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalEggStickFrassHollowPad,
    strongSignals: <String>{
      PlantHealthIds.signalNopalEggStick,
      PlantHealthIds.signalNopalInternalOrangeBlackLarvae,
      PlantHealthIds.signalNopalFrassAtEntry,
      PlantHealthIds.signalNopalOozeAtEntry,
      PlantHealthIds.signalNopalHollowPad,
      PlantHealthIds.signalNopalPadCollapseFromInside,
    },
    weakSignals: <String>{
      PlantHealthIds.signalNopalLarvalEntryHole,
      PlantHealthIds.signalNopalMultiplePadsAffected,
      PlantHealthIds.signalNopalNearbyOpuntiaDamage,
      PlantHealthIds.signalNopalGallery,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalAdultBeetle,
      PlantHealthIds.signalNopalRaggedMargin,
      PlantHealthIds.signalNopalAnimalBite,
      PlantHealthIds.signalNopalToolDamage,
      PlantHealthIds.signalNopalNoInternalDamage,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_cactus_moth_high_consequence_suspicion',
        labelEs: 'Patrón que requiere descartar palomilla del nopal',
        scientificName:
            'Cactoblastis cactorum',
        type: 'arthropod_possible',
        summaryEs:
            'La combinación de una hilera de huevos que parece una espina '
            'pegada, larvas anaranjadas con bandas oscuras dentro de la '
            'penca, excremento o líquido en el punto de entrada y una penca '
            'que se vacía por dentro es un patrón que hay que descartar '
            'cuanto antes. Esto no confirma nada: solo la autoridad vegetal '
            'puede decir de qué se trata. Mientras tanto, lo más importante '
            'es no mover ni repartir material de esa planta.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalEggStick,
          PlantHealthIds.signalNopalInternalOrangeBlackLarvae,
          PlantHealthIds.signalNopalFrassAtEntry,
          PlantHealthIds.signalNopalHollowPad,
          PlantHealthIds.signalNopalPadCollapseFromInside,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalNoInternalDamage,
          PlantHealthIds.signalNopalAdultBeetle,
          PlantHealthIds.signalNopalRaggedMargin,
          PlantHealthIds.signalNopalAnimalBite,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_native_moth_or_borer_possible',
        labelEs: 'Otra polilla o barrenador posible',
        type: 'arthropod_possible',
        summaryEs:
            'En la región hay otras polillas y barrenadores propios que '
            'también dejan larvas y galerías dentro de la penca. Se '
            'diferencian porque no dejan la hilera de huevos típica y el daño '
            'sigue otro patrón. Solo una identificación regional puede '
            'separarlos con certeza.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalLarvalEntryHole,
          PlantHealthIds.signalNopalFrassAtEntry,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalEggStick,
          PlantHealthIds.signalNopalInternalOrangeBlackLarvae,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_longhorn_internal_damage_possible',
        labelEs: 'Daño interno de escarabajo posible',
        type: 'arthropod_possible',
        summaryEs:
            'Ciertos escarabajos negros de antenas largas mordisquean el '
            'borde de la penca y abren galerías por dentro, dejando '
            'excremento. Se distinguen porque se ve el adulto y no hay hilera '
            'de huevos. Fotografía el insecto de lejos, sin tocarlo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalAdultBeetle,
          PlantHealthIds.signalNopalRaggedMargin,
          PlantHealthIds.signalNopalGallery,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalEggStick,
          PlantHealthIds.signalNopalInternalOrangeBlackLarvae,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_secondary_soft_decay_possible',
        labelEs: 'Deterioro secundario dentro de una herida posible',
        type: 'condition_compatible',
        summaryEs:
            'A veces el agujero lo hizo una herramienta o un golpe y lo que '
            'escurre es un deterioro que entró después por esa herida. Se '
            'sospecha cuando no hay larvas ni hilera de huevos y el daño no '
            'viene de dentro. Aun así conviene documentarlo bien antes de '
            'tocar nada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalOozeAtEntry,
          PlantHealthIds.signalNopalToolDamage,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalEggStick,
          PlantHealthIds.signalNopalInternalOrangeBlackLarvae,
          PlantHealthIds.signalNopalHollowPad,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay una hilera de huevos que parece una espina pegada?',
      '¿Hay larvas dentro de la penca?',
      '¿Son anaranjadas con bandas oscuras?',
      '¿Sale excremento o líquido por algún agujero?',
      '¿La penca quedó hueca por dentro?',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'No muevas la planta, las pencas ni el material a otro lugar.',
      'No cortes para propagar y no tires material fuera del sitio.',
      'Fotografía los huevos, la entrada, las larvas y la planta completa sin '
      'tocar nada.',
      'Anota la ubicación exacta, la región y la fecha.',
      'Contacta a la autoridad vegetal local para que lo revisen; en México, '
      'sanidad vegetal o SENASICA.',
    ],
    disclaimerEs: _nopalHighConsequenceDisclaimer,
    favorsVectorPressure: true,
  ),

  // ── S10 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_ragged_gallery_chewing_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Bordes mordidos, galerías, agujeros o tejido comido',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organCrown,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalChewingGallery,
    strongSignals: <String>{
      PlantHealthIds.signalNopalRaggedMargin,
      PlantHealthIds.signalNopalGallery,
      PlantHealthIds.signalNopalAdultBeetle,
      PlantHealthIds.signalNopalAnimalBite,
      PlantHealthIds.signalFrassPresent,
      PlantHealthIds.signalActiveChewing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalNopalLossOfSupport,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalCleanCut,
      PlantHealthIds.signalNopalStableScar,
      PlantHealthIds.signalNopalEggStick,
      PlantHealthIds.signalNopalMapLikeBlackPattern,
      PlantHealthIds.signalNopalCottonWax,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_longhorn_beetle_possible',
        labelEs: 'Escarabajo longicornio del cactus posible',
        scientificName:
            'Moneilema spp.',
        type: 'arthropod_possible',
        summaryEs:
            'Algunos escarabajos que viven en cactáceas comen el borde de la '
            'penca y pueden abrir túneles por dentro. Suelen verse como '
            'insectos negros de antenas largas y muchas veces dejan '
            'excremento cerca del daño. Es solo una posibilidad: hace falta '
            'ver bien el insecto o el daño para acercarse a una respuesta.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalAdultBeetle,
          PlantHealthIds.signalNopalRaggedMargin,
          PlantHealthIds.signalNopalGallery,
          PlantHealthIds.signalFrassPresent,
          PlantHealthIds.signalHumidWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalCleanCut,
          PlantHealthIds.signalNopalEggStick,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_other_borer_possible',
        labelEs: 'Otro barrenador posible',
        type: 'arthropod_possible',
        summaryEs:
            'Otros insectos barrenadores también pueden abrir galerías dentro '
            'de la penca sin que se vea al adulto. El daño por dentro no '
            'siempre se nota desde afuera hasta que la penca se debilita. '
            'Conviene observar si hay excremento o pequeños orificios de '
            'entrada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalGallery,
          PlantHealthIds.signalFrassPresent,
          PlantHealthIds.signalActiveChewing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalEggStick,
          PlantHealthIds.signalNopalCleanCut,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_rodent_or_herbivore_possible',
        labelEs: 'Daño de roedor o herbívoro posible',
        type: 'condition_compatible',
        summaryEs:
            'Los roedores, conejos u otros animales arrancan trozos grandes, '
            'casi siempre en la parte baja de la planta. Es más común cuando '
            'hay sequía y poca comida alrededor. Suele haber huellas o '
            'excremento de animal cerca.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalAnimalBite,
          PlantHealthIds.signalNopalRaggedMargin,
          PlantHealthIds.signalDryHotWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalGallery,
          PlantHealthIds.signalNopalCleanCut,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_manual_cut_possible',
        labelEs: 'Corte humano o poda posible',
        type: 'benign_differential',
        summaryEs:
            'Un corte hecho con herramienta deja un borde limpio y recto, y '
            'con el tiempo forma un callo seco. Si sabes que hubo poda o '
            'cosecha y no aparece daño nuevo, lo más probable es que sea eso. '
            'No es una enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalCleanCut,
          PlantHealthIds.signalNopalStableScar,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalActiveChewing,
          PlantHealthIds.signalFrassPresent,
          PlantHealthIds.signalNopalGallery,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El borde está irregular o el corte es limpio?',
      '¿Ves un insecto negro con antenas largas?',
      '¿Hay excremento cerca del daño?',
      '¿Se ve un túnel o galería en la penca?',
      '¿Aparece daño nuevo cada noche?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Toma fotos del daño y, si ves un insecto, fotografíalo a distancia.',
      'Fíjate si el borde es un corte limpio o una mordida irregular.',
      'Revisa si hay excremento o aserrín debajo de la penca.',
      'No metas herramientas ni los dedos dentro de las galerías.',
      'Busca ayuda técnica si el daño llega a la base o al interior de la '
      'penca.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsHighHumidity: true,
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),

  // ── S11 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_stippling_bronzing_gall_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Punteado fino, bronceado, telaraña o deformación localizada',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalMiteStipplingGall,
    strongSignals: <String>{
      PlantHealthIds.signalNopalFineStippling,
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalNopalMicroscopicMites,
      PlantHealthIds.signalNopalGall,
      PlantHealthIds.signalNopalLocalizedDistortion,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalNopalMineralResidue,
      PlantHealthIds.signalNopalProgressesToNewPads,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalWitchesBroomCluster,
      PlantHealthIds.signalNopalCottonWax,
      PlantHealthIds.signalNopalPaleFeedingBlotch,
      PlantHealthIds.signalNopalUniformCorkingAtBase,
      PlantHealthIds.signalNopalGrowthNormalizes,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_spider_mite_possible',
        labelEs: 'Ácaros con punteado o telaraña posibles',
        type: 'arthropod_possible',
        summaryEs:
            'Cuando hace calor y el ambiente está seco, algunos ácaros muy '
            'pequeños pican la superficie y dejan puntitos finos. La penca '
            'puede verse bronceada o mate y a veces aparece una telaraña muy '
            'delgada. Hace falta lupa, porque casi no se ven a simple vista.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalFineStippling,
          PlantHealthIds.signalMitesWebbing,
          PlantHealthIds.signalBronzedLeafSurface,
          PlantHealthIds.signalDryHotWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalMineralResidue,
          PlantHealthIds.signalNopalWitchesBroomCluster,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_eriophyid_mite_possible',
        labelEs: 'Ácaro asociado a agallas o deformación posible',
        type: 'arthropod_possible',
        summaryEs:
            'Hay ácaros aún más pequeños que se asocian a bultos o '
            'deformaciones en un punto concreto de la penca. En estos casos '
            'no suele haber telaraña y el resto de la planta se ve normal. Es '
            'una posibilidad que solo se afina con observación especializada.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalGall,
          PlantHealthIds.signalNopalLocalizedDistortion,
          PlantHealthIds.signalNopalMicroscopicMites,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
          PlantHealthIds.signalNopalWitchesBroomCluster,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_dust_or_residue_possible',
        labelEs: 'Polvo o residuo posible',
        type: 'benign_differential',
        summaryEs:
            'El polvo del camino o el residuo de una aplicación pueden dejar '
            'una película que parece daño. Si es una capa que se va con la '
            'lluvia y no hay puntos finos ni deformación, probablemente no '
            'sea un problema de la planta. No es una enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalMineralResidue,
          PlantHealthIds.signalNopalGrowthNormalizes,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalFineStippling,
          PlantHealthIds.signalBronzedLeafSurface,
          PlantHealthIds.signalMitesWebbing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_phytoplasma_differential',
        labelEs: 'Alteración sistémica como diferencial',
        type: 'condition_compatible',
        summaryEs:
            'Si en vez de una sola deformación aparecen muchos brotes y el '
            'patrón avanza a pencas nuevas, el cuadro ya no encaja con '
            'ácaros. Eso apunta a una alteración de toda la planta y se '
            'revisa aparte. La app no puede confirmarlo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalWitchesBroomCluster,
          PlantHealthIds.signalNopalProgressesToNewPads,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalLocalizedDistortion,
          PlantHealthIds.signalMitesWebbing,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Ves puntos muy finos en la penca?',
      '¿Hay telaraña muy delgada?',
      '¿El tejido está bronceado o solo hay una película de polvo?',
      '¿Hay un bulto o agalla en un punto localizado?',
      '¿Salen muchos brotes deformes del mismo punto?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Revisa la penca con lupa y buena luz.',
      'Fotografía con luz de lado para que se noten los puntos.',
      'No saques conclusiones por una sola deformación.',
      'Compara el tejido nuevo con el viejo.',
      'Busca identificación si la agalla crece o se extiende.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),

  // ── S12 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_wrinkling_leaning_turgor_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Pencas arrugadas, delgadas o inclinadas',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organCrown,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalWrinklingTurgorLoss,
    strongSignals: <String>{
      PlantHealthIds.signalNopalWrinkling,
      PlantHealthIds.signalNopalLossOfTurgor,
      PlantHealthIds.signalNopalNewLeaning,
      PlantHealthIds.signalNopalLossOfSupport,
      PlantHealthIds.signalNopalSeasonalShriveling,
      PlantHealthIds.signalNopalWiltsWhileSoilWet,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalFirmDry,
      PlantHealthIds.signalNopalSoftWatery,
      PlantHealthIds.signalNopalCleanBreak,
      PlantHealthIds.signalNopalStableOldLean,
      PlantHealthIds.signalNopalNormalSpeciesShape,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_drought_turgor_loss_possible',
        labelEs: 'Pérdida de turgencia por sequedad posible',
        type: 'abiotic_possible',
        summaryEs:
            'Cuando el suelo lleva tiempo seco y hace calor, la penca se '
            'arruga y se ve más delgada, pero sigue firme. Suele afectar a '
            'toda la planta por igual y no hay olor ni zonas blandas. Muchas '
            'veces mejora cuando se recuperan las condiciones.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalWrinkling,
          PlantHealthIds.signalNopalLossOfTurgor,
          PlantHealthIds.signalDryHotWindow,
          PlantHealthIds.signalNopalFirmDry,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalSoftWatery,
          PlantHealthIds.signalNopalWiltsWhileSoilWet,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_winter_shriveling_benign_possible',
        labelEs: 'Encogimiento estacional posible',
        type: 'benign_differential',
        summaryEs:
            'Algunos nopales rastreros se arrugan y se ven flácidos cada '
            'invierno y vuelven a llenarse en primavera. Si el tejido está '
            'firme, no hay olor y ya pasó otros años, es un cambio normal de '
            'la temporada. No es una enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalSeasonalShriveling,
          PlantHealthIds.signalNopalFirmDry,
          PlantHealthIds.signalColdExposure,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalSoftWatery,
          PlantHealthIds.signalNopalLossOfSupport,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_root_failure_possible',
        labelEs: 'Raíz limitada o dañada posible',
        type: 'condition_compatible',
        summaryEs:
            'Si la planta se arruga o se inclina mientras el suelo está '
            'húmedo, puede que la raíz no esté absorbiendo bien. También se '
            'nota cuando la planta pierde soporte o la base cambia de '
            'aspecto. Es un cuadro que conviene revisar sin tardar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalWiltsWhileSoilWet,
          PlantHealthIds.signalNopalLossOfSupport,
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalNopalNewLeaning,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalStableOldLean,
          PlantHealthIds.signalNopalSeasonalShriveling,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_structural_weight_or_old_lean_possible',
        labelEs: 'Inclinación estructural estable posible',
        type: 'benign_differential',
        summaryEs:
            'Una planta grande y con mucho peso puede quedar inclinada de '
            'forma estable durante años. Si la inclinación es antigua, no '
            'avanza y la base sigue firme, suele ser un tema de estructura y '
            'no de salud. No es una enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalStableOldLean,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalNewLeaning,
          PlantHealthIds.signalNopalLossOfSupport,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La penca se ve firme o blanda?',
      '¿El suelo está seco o húmedo?',
      '¿Esto ya pasó en otros inviernos?',
      '¿La planta se ve floja o sin soporte en la base?',
      '¿La inclinación es nueva o lleva mucho tiempo igual?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'No riegues solo porque la penca se ve arrugada.',
      'Revisa la humedad del suelo, la base y el perfil de la planta.',
      'Compara con fotos anteriores para ver si el cambio es nuevo.',
      'No trates de enderezar la planta a la fuerza.',
      'Busca revisión pronto si la base se ablanda o la planta pierde '
      'soporte.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsRecentStress: true,
  ),

  // ── S13 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_sunburn_bleached_patch_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Zona amarilla, blanca o seca en el lado de mayor sol',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalSunburnPatch,
    strongSignals: <String>{
      PlantHealthIds.signalNopalSunnySide,
      PlantHealthIds.signalNopalChangedSunExposure,
      PlantHealthIds.signalNopalBleachedPatch,
      PlantHealthIds.signalNopalStrawYellow,
      PlantHealthIds.signalNopalFirmDry,
      PlantHealthIds.signalHeatStress,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalNopalReflectedHeat,
      PlantHealthIds.signalNopalNurseryOrigin,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalSoftWatery,
      PlantHealthIds.signalNopalMultipleRandomSides,
      PlantHealthIds.signalNopalMapLikeBlackPattern,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalNopalCottonWax,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_sunburn_possible',
        labelEs: 'Quemadura solar posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un cambio brusco de sombra a sol fuerte puede quemar la cara más '
            'expuesta de la penca. La zona empieza pálida o blanquecina y '
            'después se vuelve color paja, pero se mantiene seca y firme. Una '
            'vez que la exposición se estabiliza, suele dejar de crecer.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalSunnySide,
          PlantHealthIds.signalNopalChangedSunExposure,
          PlantHealthIds.signalNopalBleachedPatch,
          PlantHealthIds.signalNopalStrawYellow,
          PlantHealthIds.signalNopalFirmDry,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalSoftWatery,
          PlantHealthIds.signalNopalMultipleRandomSides,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_heat_reflection_possible',
        labelEs: 'Daño por calor reflejado posible',
        type: 'abiotic_possible',
        summaryEs:
            'Una pared clara, un vidrio, una piedra o una maceta oscura '
            'pueden concentrar calor sobre un lado de la planta. El daño '
            'aparece justo en la cara que da a ese objeto. Cambiar la '
            'orientación o dar algo de sombra suele bastar para que no siga.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalReflectedHeat,
          PlantHealthIds.signalNopalSunnySide,
          PlantHealthIds.signalHeatStress,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalMultipleRandomSides,
          PlantHealthIds.signalColdExposure,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_frost_or_spot_differential',
        labelEs: 'Frío o mancha como diferencial',
        type: 'condition_compatible',
        summaryEs:
            'Si el daño está en varios lados sin relación con el sol, o el '
            'tejido se ablanda, hay que pensar en frío o en una mancha. Esos '
            'cuadros se comportan distinto y se revisan aparte. Vale la pena '
            'mirar si la zona avanza o se queda igual.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalNopalMapLikeBlackPattern,
          PlantHealthIds.signalNopalMultipleRandomSides,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalSunnySide,
          PlantHealthIds.signalNopalChangedSunExposure,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El daño está solo del lado que recibe más sol?',
      '¿La planta cambió de lugar o de exposición hace poco?',
      '¿Venía de vivero, invernadero o interior?',
      '¿La zona se ve seca y firme, no blanda?',
      '¿Hay una pared, piedra o maceta oscura que refleje calor?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Evita otro cambio brusco de sol o de lugar.',
      'Toma una foto anotando hacia dónde da el sol.',
      'No cubras la base con material húmedo.',
      'Observa si la lesión deja de crecer cuando la exposición se '
      'estabiliza.',
      'Busca revisión si la zona se ablanda.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsRecentStress: true,
  ),

  // ── S14 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_cold_translucent_black_tissue_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Tejido translúcido, negro o seco después de frío',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalColdTissueChange,
    strongSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalNopalTranslucentTissue,
      PlantHealthIds.signalNopalBlackAfterFreeze,
      PlantHealthIds.signalNopalMultipleExposedPads,
      PlantHealthIds.signalNopalDryCrispLater,
      PlantHealthIds.signalNopalColdSensitiveProfile,
    },
    weakSignals: <String>{
      PlantHealthIds.signalNopalWetCold,
      PlantHealthIds.signalNopalNewGrowth,
      PlantHealthIds.signalNopalSoftWatery,
      PlantHealthIds.signalNopalAbnormalOdor,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalMapLikeBlackPattern,
      PlantHealthIds.signalNopalImpactCrater,
      PlantHealthIds.signalNopalSeasonalShriveling,
      PlantHealthIds.signalNopalWarmWeatherProgression,
      PlantHealthIds.signalNopalCottonWax,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_freeze_injury_possible',
        labelEs: 'Daño por helada posible',
        type: 'abiotic_possible',
        summaryEs:
            'Después de una helada, el tejido se ve primero translúcido o '
            'aguado y luego se vuelve negro. Suele afectar varias pencas del '
            'lado más expuesto y a los brotes más tiernos. Conviene esperar '
            'unos días antes de sacar conclusiones, porque el daño tarda en '
            'definirse.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalNopalTranslucentTissue,
          PlantHealthIds.signalNopalBlackAfterFreeze,
          PlantHealthIds.signalNopalMultipleExposedPads,
          PlantHealthIds.signalNopalColdSensitiveProfile,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalMapLikeBlackPattern,
          PlantHealthIds.signalNopalWarmWeatherProgression,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_winter_shriveling_benign_differential',
        labelEs: 'Reposo o encogimiento invernal posible',
        type: 'benign_differential',
        summaryEs:
            'Algunas variedades se encogen y se ven arrugadas durante el '
            'invierno y se recuperan solas en primavera. Si el tejido sigue '
            'firme, no se puso negro y no hay olor, es el patrón normal de la '
            'temporada. No es una enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalSeasonalShriveling,
          PlantHealthIds.signalColdExposure,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalBlackAfterFreeze,
          PlantHealthIds.signalNopalTranslucentTissue,
          PlantHealthIds.signalNopalSoftWatery,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_secondary_decay_after_cold_possible',
        labelEs: 'Deterioro secundario después de frío posible',
        type: 'condition_compatible',
        summaryEs:
            'Después del frío, el tejido dañado puede ablandarse si hay '
            'humedad. Ahí el problema deja de ser el frío y pasa a ser el '
            'deterioro que viene después, sobre todo si aparece olor o la '
            'zona sigue avanzando. Es lo que hay que vigilar en los días '
            'siguientes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalSoftWatery,
          PlantHealthIds.signalNopalAbnormalOdor,
          PlantHealthIds.signalNopalWetCold,
          PlantHealthIds.signalNopalWarmWeatherProgression,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalDryCrispLater,
          PlantHealthIds.signalNopalSeasonalShriveling,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo helada o frío fuerte hace poco?',
      '¿La penca se puso translúcida o aguada?',
      '¿Después se puso negra?',
      '¿El tejido se ve seco y firme o blando y mojado?',
      '¿Apareció mal olor o el daño sigue avanzando?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'No declares la planta muerta de inmediato.',
      'Espera unos días para distinguir tejido firme, seco o blando.',
      'Evita riego adicional si el suelo sigue húmedo.',
      'Fotografía la progresión cada pocos días.',
      'Busca revisión si el daño llega a la base.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsCoolDewyWindow: true,
    favorsRecentStress: true,
  ),

  // ── S15 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_impact_wound_scar_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Heridas, perforaciones o cicatrices después de un evento',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalImpactWoundScar,
    strongSignals: <String>{
      PlantHealthIds.signalNopalImpactCrater,
      PlantHealthIds.signalNopalOneSidedHailPattern,
      PlantHealthIds.signalNopalFreshPuncture,
      PlantHealthIds.signalNopalCleanBreak,
      PlantHealthIds.signalNopalKnownImpact,
      PlantHealthIds.signalNopalStableScar,
    },
    weakSignals: <String>{
      PlantHealthIds.signalNopalWindEvent,
      PlantHealthIds.signalNopalAnimalContact,
      PlantHealthIds.signalNopalToolDamage,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalProgressesWithoutNewImpact,
      PlantHealthIds.signalNopalSoftRotAwayFromWound,
      PlantHealthIds.signalNopalMapLikeBlackPattern,
      PlantHealthIds.signalNopalEggStick,
      PlantHealthIds.signalNopalCottonWax,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_hail_damage_possible',
        labelEs: 'Daño por granizo posible',
        type: 'abiotic_possible',
        summaryEs:
            'El granizo deja varios golpes que aparecen todos al mismo tiempo '
            'y casi siempre en el mismo lado de la planta. Con el tiempo esas '
            'heridas se secan y quedan como cicatrices. Si hubo tormenta hace '
            'poco, encaja bien con lo que se ve.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalImpactCrater,
          PlantHealthIds.signalNopalOneSidedHailPattern,
          PlantHealthIds.signalNopalKnownImpact,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalProgressesWithoutNewImpact,
          PlantHealthIds.signalNopalMapLikeBlackPattern,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_mechanical_wound_possible',
        labelEs: 'Golpe, herramienta o caída posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un golpe, una caída, el roce de una herramienta o el viento '
            'fuerte pueden abrir heridas o romper una penca. El corte suele '
            'ser limpio y no aumenta si no vuelve a pasar nada. Anotar cuándo '
            'ocurrió ayuda a distinguirlo de otras causas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalCleanBreak,
          PlantHealthIds.signalNopalToolDamage,
          PlantHealthIds.signalNopalKnownImpact,
          PlantHealthIds.signalNopalWindEvent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalOneSidedHailPattern,
          PlantHealthIds.signalNopalProgressesWithoutNewImpact,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_animal_damage_possible',
        labelEs: 'Daño de animal posible',
        type: 'condition_compatible',
        summaryEs:
            'El paso de animales puede dejar perforaciones, raspones o pencas '
            'quebradas. Suele haber señales alrededor, como huellas o plantas '
            'movidas. El daño no avanza por sí solo entre un evento y otro.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalAnimalContact,
          PlantHealthIds.signalNopalFreshPuncture,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalOneSidedHailPattern,
          PlantHealthIds.signalNopalStableScar,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_secondary_infection_at_wound_possible',
        labelEs: 'Deterioro secundario de una herida posible',
        type: 'condition_compatible',
        summaryEs:
            'Una herida que estaba seca y empieza a ablandarse, a soltar '
            'líquido o a oler, ya no se explica solo por el golpe. Eso indica '
            'que algo más está aprovechando la herida, sobre todo con '
            'humedad. Es la situación que conviene revisar pronto.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalProgressesWithoutNewImpact,
          PlantHealthIds.signalNopalSoftRotAwayFromWound,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalStableScar,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo granizo, viento fuerte o un golpe?',
      '¿Las heridas están en un solo lado?',
      '¿Todas aparecieron al mismo tiempo?',
      '¿La herida se ve seca y cerrada?',
      '¿Está creciendo sin que haya pasado nada nuevo?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Anota la fecha del granizo o del golpe.',
      'No confundas una cicatriz seca y estable con una enfermedad.',
      'Vigila si la zona pasa de firme a blanda.',
      'Evita mojar las heridas al regar.',
      'Busca revisión si aparece exudado o mal olor.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsRecentStress: true,
  ),

  // ── S16 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_pale_elongated_growth_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Pencas nuevas largas, delgadas o pálidas',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalPaleElongatedGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalNopalElongatedPad,
      PlantHealthIds.signalNopalPaleNewGrowth,
      PlantHealthIds.signalNopalWeakNarrowPad,
      PlantHealthIds.signalNopalLowLightContext,
      PlantHealthIds.signalNopalIndoorContext,
      PlantHealthIds.signalNopalLeaningTowardLight,
    },
    weakSignals: <String>{
      PlantHealthIds.signalNopalHighNitrogen,
      PlantHealthIds.signalNopalRootRestriction,
      PlantHealthIds.signalNopalCrowding,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalNormalSpeciesShape,
      PlantHealthIds.signalNopalVariegatedTrait,
      PlantHealthIds.signalNopalStrongFullSunGrowth,
      PlantHealthIds.signalNopalLocalizedDistortion,
      PlantHealthIds.signalNopalWitchesBroomCluster,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_low_light_etiolation_possible',
        labelEs: 'Crecimiento débil por poca luz posible',
        type: 'abiotic_possible',
        summaryEs:
            'Con poca luz, la penca nueva sale más larga, delgada y pálida '
            'que las anteriores y tiende a inclinarse hacia donde entra la '
            'luz. Es muy común en plantas de interior o que se movieron a la '
            'sombra. Solo se nota en el crecimiento nuevo: las pencas viejas '
            'se ven normales.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalElongatedPad,
          PlantHealthIds.signalNopalPaleNewGrowth,
          PlantHealthIds.signalNopalLowLightContext,
          PlantHealthIds.signalNopalIndoorContext,
          PlantHealthIds.signalNopalLeaningTowardLight,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalStrongFullSunGrowth,
          PlantHealthIds.signalNopalNormalSpeciesShape,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_excess_n_soft_growth_possible',
        labelEs: 'Crecimiento blando por exceso de nitrógeno posible',
        type: 'abiotic_possible',
        summaryEs:
            'Un exceso de nitrógeno hace que la planta crezca rápido con '
            'tejido blando y color muy verde. En ese caso la luz no es el '
            'problema y suele venir de fertilizar de más. Revisar las '
            'lecturas de nitrógeno y de EC ayuda a ubicarlo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalHighNitrogen,
          PlantHealthIds.signalNopalWeakNarrowPad,
          PlantHealthIds.signalSalinityLoad,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalLowLightContext,
          PlantHealthIds.signalNopalPaleNewGrowth,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_normal_profile_shape_possible',
        labelEs: 'Forma normal del perfil posible',
        type: 'benign_differential',
        summaryEs:
            'Hay variedades cuya forma normal es alargada, delgada o de color '
            'claro. Si las pencas nuevas se parecen a las de plantas sanas de '
            'la misma variedad y luego maduran y endurecen, no hay nada raro. '
            'No es una enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalNormalSpeciesShape,
          PlantHealthIds.signalNopalVariegatedTrait,
          PlantHealthIds.signalNopalStrongFullSunGrowth,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalLowLightContext,
          PlantHealthIds.signalNopalElongatedPad,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_root_or_water_stress_growth_possible',
        labelEs: 'Crecimiento limitado por raíz o agua posible',
        type: 'condition_compatible',
        summaryEs:
            'Una raíz apretada en la maceta o el agua justa también producen '
            'pencas pequeñas y débiles. En ese caso el crecimiento es corto y '
            'flojo más que largo y estirado. Conviene mirar el espacio de la '
            'raíz y la humedad del sustrato.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalRootRestriction,
          PlantHealthIds.signalNopalWeakNarrowPad,
          PlantHealthIds.signalSalinityLoad,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalStrongFullSunGrowth,
          PlantHealthIds.signalNopalHighNitrogen,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La penca nueva es más larga y delgada que las anteriores?',
      '¿Se ve más pálida que el resto?',
      '¿La planta está en interior o en sombra?',
      '¿Las pencas nuevas se inclinan hacia la luz?',
      '¿Esa forma coincide con la variedad que tienes?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Compara las pencas nuevas con las anteriores.',
      'No pases la planta de sombra a sol fuerte de golpe.',
      'Revisa el nitrógeno y la EC del sustrato.',
      'Confirma cuál es la forma normal de tu variedad.',
      'Busca revisión si la deformación avanza.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsRecentStress: true,
  ),

  // ── S17 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_chlorosis_edge_burn_weak_growth_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Pencas pálidas, bordes secos o crecimiento débil',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalChlorosisEdgeBurn,
    strongSignals: <String>{
      PlantHealthIds.signalNopalUniformChlorosis,
      PlantHealthIds.signalNopalEdgeBurn,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalNopalHighPhContext,
      PlantHealthIds.signalNopalWeakGrowth,
      PlantHealthIds.signalWaterlogging,
    },
    weakSignals: <String>{
      PlantHealthIds.signalNopalLowNRepeated,
      PlantHealthIds.signalNopalRootRestriction,
      PlantHealthIds.signalNopalFewFineRoots,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalNormalVariegation,
      PlantHealthIds.signalNopalYellowRings,
      PlantHealthIds.signalNopalMapLikeBlackPattern,
      PlantHealthIds.signalNopalPaleFeedingBlotch,
      PlantHealthIds.signalNopalSunnySide,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_salinity_stress_possible',
        labelEs: 'Estrés por sales posible',
        type: 'abiotic_possible',
        summaryEs:
            'Cuando se acumulan sales en el sustrato, la penca se ve pálida y '
            'los bordes se secan. Es frecuente en maceta, con riego escaso o '
            'fertilización repetida, y a veces la planta no absorbe bien '
            'aunque el suelo esté húmedo. Una lectura de EC alta apoya esta '
            'posibilidad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSalinityLoad,
          PlantHealthIds.signalNopalEdgeBurn,
          PlantHealthIds.signalNopalRootRestriction,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalNormalVariegation,
          PlantHealthIds.signalNopalYellowRings,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_ph_nutrient_unavailability_possible',
        labelEs: 'Nutrientes poco disponibles por pH posible',
        type: 'abiotic_possible',
        summaryEs:
            'Con un pH alto, algunos nutrientes están en el suelo pero la '
            'planta no los puede tomar. El resultado es una decoloración '
            'pareja y crecimiento lento, aunque se haya fertilizado. Medir el '
            'pH ayuda a saber si vale la pena mirar por ahí.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalHighPhContext,
          PlantHealthIds.signalNopalUniformChlorosis,
          PlantHealthIds.signalNopalWeakGrowth,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalNormalVariegation,
          PlantHealthIds.signalNopalSunnySide,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_root_dysfunction_possible',
        labelEs: 'Raíz limitada o dañada posible',
        type: 'condition_compatible',
        summaryEs:
            'Si la raíz está limitada, dañada o con el suelo siempre húmedo, '
            'la planta se ve pálida y crece poco aunque no le falte alimento. '
            'El problema no está en la penca sino abajo. Conviene revisar el '
            'estado del sustrato y de las raíces.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalNopalFewFineRoots,
          PlantHealthIds.signalNopalWeakGrowth,
          PlantHealthIds.signalNopalRootRestriction,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalNormalVariegation,
          PlantHealthIds.signalNopalSunnySide,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_normal_variegation_possible',
        labelEs: 'Variegación normal posible',
        type: 'benign_differential',
        summaryEs:
            'Algunas variedades tienen zonas claras o amarillentas de '
            'nacimiento. Si el patrón es estable, la planta crece bien y no '
            'hay bordes secos, es su color normal. No es una enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalNormalVariegation,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalEdgeBurn,
          PlantHealthIds.signalNopalWeakGrowth,
          PlantHealthIds.signalSalinityLoad,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Está pálida toda la penca o solo el borde?',
      '¿La EC del sustrato está alta?',
      '¿El pH del suelo está alto?',
      '¿El suelo se mantiene húmedo mucho tiempo?',
      '¿Es una variedad variegada o de color claro normal?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'No fertilices por una sola lectura.',
      'Revisa pH, EC, humedad del suelo y estado de la raíz.',
      'Confirma si tu variedad es variegada.',
      'Repite la medición unos días después.',
      'Busca un análisis de suelo o agua si el problema sigue.',
    ],
    disclaimerEs: _nopalDisclaimer,
    favorsRecentStress: true,
  ),

  // ── S18 ──────────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'nopal_witches_broom_deformation_01',
    cropId: CropCatalog.nopalCropId,
    labelEs: 'Muchos brotes cortos desde un punto o crecimiento muy deforme',
    stages: _nopalStages,
    organIds: <String>{
      PlantHealthIds.organCladode,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNopalWitchesBroomDeformation,
    strongSignals: <String>{
      PlantHealthIds.signalNopalWitchesBroomCluster,
      PlantHealthIds.signalNopalManyShortShoots,
      PlantHealthIds.signalNopalPersistentDeformation,
      PlantHealthIds.signalNopalAbnormalProliferation,
      PlantHealthIds.signalNopalYellowingWithBroom,
      PlantHealthIds.signalNopalProgressesToNewPads,
    },
    weakSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalNopalNurseryOrigin,
      PlantHealthIds.signalNopalNearbyAffectedCacti,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNopalCrestedCultivarKnown,
      PlantHealthIds.signalNopalNormalBranching,
      PlantHealthIds.signalNopalPruningResponse,
      PlantHealthIds.signalNopalLocalizedDistortion,
      PlantHealthIds.signalNopalGrowthNormalizes,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'nopal_phytoplasma_witches_broom_suspicion',
        labelEs: 'Patrón compatible con escoba de bruja por confirmar',
        scientificName:
            'fitoplasma del grupo 16SrII',
        type: 'condition_compatible',
        summaryEs:
            'Cuando salen muchos brotes cortos desde un mismo punto, con '
            'amarillamiento y avanzando a pencas nuevas, el patrón se parece '
            'al de la escoba de bruja. En México se ha asociado a un '
            'fitoplasma en Opuntia de vivero, pero eso solo se confirma en '
            'laboratorio. Esta app no puede confirmarlo ni descartarlo, y no '
            'toda proliferación tiene esa causa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalWitchesBroomCluster,
          PlantHealthIds.signalNopalManyShortShoots,
          PlantHealthIds.signalNopalProgressesToNewPads,
          PlantHealthIds.signalNopalYellowingWithBroom,
          PlantHealthIds.signalNopalNearbyAffectedCacti,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalCrestedCultivarKnown,
          PlantHealthIds.signalNopalPruningResponse,
          PlantHealthIds.signalNopalGrowthNormalizes,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_known_crest_monstrose_possible',
        labelEs: 'Forma crestada o monstruosa conocida posible',
        type: 'benign_differential',
        summaryEs:
            'Hay variedades crestadas o monstruosas que se venden justamente '
            'por su forma irregular. Si la planta se compró así, el patrón es '
            'estable y no hay amarillamiento, es su forma propia. No es una '
            'enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalCrestedCultivarKnown,
          PlantHealthIds.signalNopalGrowthNormalizes,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalYellowingWithBroom,
          PlantHealthIds.signalNopalProgressesToNewPads,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_mite_gall_deformation_possible',
        labelEs: 'Ácaro o agalla como diferencial',
        type: 'arthropod_possible',
        summaryEs:
            'Un ácaro puede provocar una agalla o una deformación en un punto '
            'concreto sin afectar al resto de la planta. Si la alteración es '
            'localizada y no se extiende a pencas nuevas, el cuadro encaja '
            'mejor con eso. Se revisa con lupa y buena luz.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalLocalizedDistortion,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalProgressesToNewPads,
          PlantHealthIds.signalNopalYellowingWithBroom,
        },
      ),
      PlantHealthDiagnosis(
        id: 'nopal_pruning_or_damage_regrowth_possible',
        labelEs: 'Rebrote después de poda o daño posible',
        type: 'benign_differential',
        summaryEs:
            'Después de un corte o un daño es normal que salgan varios brotes '
            'alrededor de la herida. Si el crecimiento se normaliza después y '
            'no hay amarillamiento, es la respuesta esperada a la poda. No es '
            'una enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalNopalPruningResponse,
          PlantHealthIds.signalNopalNormalBranching,
          PlantHealthIds.signalNopalGrowthNormalizes,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNopalYellowingWithBroom,
          PlantHealthIds.signalNopalProgressesToNewPads,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Salen muchos brotes cortos del mismo punto?',
      '¿El patrón avanza a pencas nuevas?',
      '¿Hay amarillamiento junto con los brotes?',
      '¿La planta se compró así o es una variedad crestada?',
      '¿Hay otras Opuntia cerca con el mismo patrón?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'No propagues ni regales esquejes de esta planta.',
      'Separa la maceta de las demás plantas.',
      'Fotografía la planta completa y el punto donde salen los brotes.',
      'Limpia las herramientas antes de usarlas en otras plantas.',
      'Busca diagnóstico especializado antes de tomar decisiones.',
    ],
    disclaimerEs: _nopalHighConsequenceDisclaimer,
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),
];
