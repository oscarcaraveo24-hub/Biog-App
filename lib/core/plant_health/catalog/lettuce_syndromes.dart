import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

// Buckets de etapa para lechuga (hortaliza de hoja). El motor de 8
// buckets se reinterpreta: reproductiveEarly = formación de cabeza (E4),
// reproductiveMid/grainFill = ventana de cosecha (E5), lateSeason =
// sobre-madurez (E6). No hay floración productiva.
const Set<PlantHealthStageBucket> _earlyStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
};

const Set<PlantHealthStageBucket> _foliarStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _vectorStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

// Ventana de calidad: cabeza, cosecha y sobre-madurez (E4-E6).
const Set<PlantHealthStageBucket> _qualityStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _rootSoilStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _allLettuceStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<String> _headVarieties = <String>{
  'lettuce_romaine',
  'lettuce_mini_romaine',
  'lettuce_iceberg',
  'lettuce_butterhead',
  'le_01',
  'le_02',
  'le_03',
  'le_04',
};

const Set<String> _butterheadVarieties = <String>{
  'lettuce_butterhead',
  'le_04',
};

const Set<String> _looseLeafVarieties = <String>{
  'lettuce_looseleaf',
  'le_05',
};

const Set<String> _genericVarieties = <String>{
  'lettuce_generic',
  'le_gen',
};

const String _disclaimer =
    'Diagnostico sugerido. BIO-G orienta monitoreo y manejo cultural; confirma en campo y con apoyo tecnico local si el dano avanza. No prescribe pesticidas.';

const List<String> _baseActions = <String>[
  'Marcar focos por cama o zona y revisar avance en 24-48 horas.',
  'Corregir riego, drenaje y ventilacion antes de perseguir sintomas.',
  'Retirar hojas o plantas muy afectadas si ya funcionan como fuente de inoculo.',
  'Documentar fotos, etapa y clima reciente para comparar evolucion.',
];

const List<String> _rootSoilActions = <String>[
  'Revisar raiz superficial, cuello y base antes de asumir falta de agua.',
  'Corregir encharcamiento, cama baja, riego largo o compactacion.',
  'Comparar zona baja/humeda contra zona con mejor drenaje.',
  'Registrar humedad de suelo, textura, resistencia y clima reciente.',
];

const List<String> _vectorActions = <String>[
  'Revisar enves de hoja, hojas internas, orillas, maleza y cultivos vecinos.',
  'Separar dano directo de plaga contra sintomas compatibles con virus.',
  'Manejar malezas hospederas en bordes y camas: son refugio de pulgon, trips y virus.',
  'Evitar diagnostico definitivo sin observar vector, patron y avance.',
];

const List<String> _abioticActions = <String>[
  'Cruzar sintomas con riego, CE, temperatura, raiz y etapa antes de recomendar correccion.',
  'Revisar si el patron es uniforme; si lo es, apunta mas a ambiente, sales o manejo.',
  'Registrar aplicaciones recientes, cambios de riego, calor, frio o lluvia.',
  'Evitar recetas fuertes sin confirmar si el dano es fisiologico, nutricional o sanitario.',
];

const List<String> _qualityActions = <String>[
  'Estabilizar el riego: la lechuga pierde calidad rapido con estres hidrico.',
  'Revisar sombra y ventilacion si hay calor sostenido o HR alta.',
  'Decidir cosecha oportuna: si el dano de calidad avanza, cortar pronto.',
  'Registrar calor, humedad y etapa para ajustar el proximo ciclo.',
];

/// Catálogo de riesgos / sanidad vegetal de lechuga (`crop_lettuce`).
///
/// Cubre el catálogo extendido del documento de Riesgos v1.1: eventos
/// fisiológicos (espigado, amargor, tip burn), complejos fúngicos,
/// bacteriosis, plagas, virosis y abióticos. BIO-G da riesgo, señales,
/// urgencia y acción conservadora; nunca dosis de pesticida.
const List<PlantHealthSyndrome> lettuceSyndromes = <PlantHealthSyndrome>[
  // 1) Espigado / bolting + amargor (evento de falla de calidad).
  PlantHealthSyndrome(
    id: 'lettuce_bolting_bitterness_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Tallo central alargado, hojas puntiagudas o sabor amargo',
    stages: _qualityStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomBoltingStem,
    strongSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    weakSignals: <String>{PlantHealthIds.signalSalinityLoad},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_bolting',
        labelEs: 'Espigado / bolting',
        scientificName: 'Falla fisiologica reproductiva',
        type: 'physiological_failure',
        summaryEs:
            'El tallo floral se alarga y la planta cambia de hoja a reproduccion. Reduce o destruye el valor comercial por amargor y perdida de forma. Lo disparan calor sostenido, dias largos, edad avanzada y estres acumulado. No se corrige una vez iniciado.',
      ),
      PlantHealthDiagnosis(
        id: 'lettuce_excess_bitterness',
        labelEs: 'Amargor excesivo',
        scientificName: 'Trastorno de calidad',
        type: 'quality_disorder',
        summaryEs:
            'Sabor amargo y hoja dura por calor, deficit hidrico, sobre-madurez o N tardio. A veces precede o acompana al espigado.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si el tallo central empieza a crecer hacia arriba en el centro de la planta.',
      'Observa si las hojas nuevas salen mas pequenas y puntiagudas.',
      'Relaciona con dias de calor sostenido o riego irregular reciente.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Si el tallo central ya se alarga, cosechar cuanto antes mientras siga comercial.',
      'En preventivo, estabilizar el riego y revisar sombra o ventilacion.',
      'No esperar mejoria: el espigado no se revierte una vez iniciado.',
      'Registrar el evento para ajustar fechas y variedad del proximo ciclo.',
    ],
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),

  // 2) Tip burn / quemado de puntas internas.
  PlantHealthSyndrome(
    id: 'lettuce_tip_burn_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Puntas o bordes marrones en hojas internas o jovenes',
    stages: _qualityStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalRecentStress,
    },
    weakSignals: <String>{PlantHealthIds.signalDryHotWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_tip_burn',
        labelEs: 'Tip burn / quemado de puntas internas',
        scientificName: 'Desorden fisiologico asociado a calcio y transpiracion',
        type: 'physiological_disorder',
        summaryEs:
            'Bordes o puntas marrones en hojas internas por crecimiento rapido, baja transpiracion, HR alta y riego intermitente. En BIO-G v1 el calcio NO es sensor activo: se maneja con ventilacion y riego estable.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Abre la cabeza o roseta y revisa si el dano esta en hojas internas o jovenes.',
      'Confirma si hubo HR alta, poca ventilacion o crecimiento rapido por N.',
      'Diferencia de pudricion: el tip burn inicia seco, no acuoso.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Mejorar ventilacion y estabilidad de riego; evitar el exceso de N.',
      'Revisar hojas internas antes de decidir el corte.',
      'Consultar calcio/tejido con tecnico solo si el dano es severo.',
      'Documentar HR, calor y manejo para comparar.',
    ],
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.lettuceCropId,
        varietyIds: _butterheadVarieties,
        diagnosisIds: <String>{'lettuce_tip_burn'},
        scoreDelta: 5,
        rationaleEs:
            'La mantequilla tiene hoja muy tierna y es mas sensible a tip burn.',
      ),
      VarietyModifier(
        cropId: CropCatalog.lettuceCropId,
        varietyIds: _genericVarieties,
        diagnosisIds: <String>{'lettuce_tip_burn'},
        scoreDelta: 3,
        rationaleEs:
            'LE-GEN debe alertar de forma conservadora sin asumir tipo.',
        isProxy: true,
        requiresCaution: true,
      ),
    ],
  ),

  // 3) Damping-off / chupadera.
  PlantHealthSyndrome(
    id: 'lettuce_damping_off_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Plantula caida o cuello estrangulado',
    stages: _earlyStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSeedlingCollapse,
    strongSignals: <String>{
      PlantHealthIds.signalSeedlingNeckCollapse,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_damping_off_complex',
        labelEs: 'Damping-off / chupadera',
        scientificName: 'Pythium spp. / Rhizoctonia solani / Fusarium spp.',
        type: 'fungus_oomycete',
        summaryEs:
            'Plantulas colapsadas al cuello en semillero o cama. Se favorece por suelo/sustrato muy humedo, poca ventilacion, semilla o sustrato contaminado y exceso de sales.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si la plantula se doblo en el cuello con zona oscura o estrangulada.',
      'Confirma si el sustrato/suelo estuvo saturado o con poca ventilacion.',
      'Arranca una plantula y revisa raiz fina y olor a pudricion.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootSoilActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // 4) Pudricion basal: Sclerotinia + bottom rot / Rhizoctonia.
  PlantHealthSyndrome(
    id: 'lettuce_basal_rot_complex_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Pudricion en la base, colapso o moho blanco',
    stages: _rootSoilStages,
    organIds: <String>{
      PlantHealthIds.organCrown,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalRootsDarkRot,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalHumidWindow,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_sclerotinia_drop',
        labelEs: 'Sclerotinia / leaf drop / pudricion basal',
        scientificName: 'Sclerotinia sclerotiorum / Sclerotinia minor',
        type: 'fungus',
        summaryEs:
            'Pudricion acuosa en la base con micelio blanco algodonoso y esclerocios negros. Se favorece con clima fresco-humedo, exceso de riego, residuos y alta densidad.',
      ),
      PlantHealthDiagnosis(
        id: 'lettuce_bottom_rot_rhizoctonia',
        labelEs: 'Bottom rot / Rhizoctonia',
        scientificName: 'Rhizoctonia solani',
        type: 'fungus',
        summaryEs:
            'Lesiones pardas en hojas inferiores en contacto con suelo humedo, calor moderado y mala ventilacion.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Abre la base de la planta y busca tejido acuoso, micelio blanco o esclerocios negros.',
      'Revisa si las hojas bajas en contacto con el suelo tienen lesiones pardas.',
      'Relaciona el foco con exceso de riego, residuos o camas muy cerradas.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Mejorar drenaje y aireacion; evitar mantener la base saturada.',
      'Retirar plantas afectadas y no compostar material enfermo.',
      'Manejar residuos y considerar rotacion de cultivos.',
      'Documentar humedad, densidad y clima reciente.',
    ],
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // 5) Mildiu velloso / Bremia lactucae.
  PlantHealthSyndrome(
    id: 'lettuce_downy_mildew_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Manchas amarillas angulares con enves gris',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomAngularSpots,
    strongSignals: <String>{
      PlantHealthIds.signalAngularLesionPattern,
      PlantHealthIds.signalUndersideSporulation,
      PlantHealthIds.signalRapidFoliarCollapse,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
    },
    conflictingSignals: <String>{PlantHealthIds.signalWhitePowderGrowth},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_bremia_downy_mildew',
        labelEs: 'Mildiu velloso de la lechuga',
        scientificName: 'Bremia lactucae',
        type: 'oomycete',
        summaryEs:
            'Manchas angulares amarillas en el haz y micelio gris-blanco en el enves. Se dispara con HR >85%, noches frescas, mojado foliar y poca ventilacion.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Voltea la hoja temprano y busca enves gris donde coincide la mancha.',
      'Confirma que las lesiones respetan nervaduras y avanzan rapido.',
      'Relaciona el foco con rocio largo, HR alta o riego nocturno/foliar.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // 6) Botrytis / moho gris.
  PlantHealthSyndrome(
    id: 'lettuce_botrytis_gray_mold_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Necrosis humeda con moho gris en hoja o base',
    stages: _qualityStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomGrayMoldNecrosis,
    strongSignals: <String>{
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalWaterSoakedMargin,
    },
    weakSignals: <String>{PlantHealthIds.signalCoolDewyWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_botrytis',
        labelEs: 'Botrytis / moho gris',
        scientificName: 'Botrytis cinerea',
        type: 'fungus',
        summaryEs:
            'Lesiones pardas con moho gris afelpado y olor a pudricion. Se favorece con HR alta, tejido viejo o danado, N tardio y poca ventilacion.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca moho gris en hojas viejas, heridas o tejido senescente.',
      'Confirma HR alta, condensacion o poca ventilacion.',
      'Revisa si el problema nace en heridas o tejido muerto.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.lettuceCropId,
        varietyIds: _butterheadVarieties,
        diagnosisIds: <String>{'lettuce_botrytis'},
        scoreDelta: 4,
        rationaleEs:
            'La mantequilla tiene hoja blanda y dosel cerrado: mas riesgo de moho gris.',
      ),
    ],
  ),

  // 7) Cenicilla / powdery mildew.
  PlantHealthSyndrome(
    id: 'lettuce_powdery_mildew_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Polvillo blanco superficial en hoja',
    stages: _qualityStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomPowderyGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalSporesRubOff,
    },
    weakSignals: <String>{PlantHealthIds.signalHumidWindow},
    conflictingSignals: <String>{PlantHealthIds.signalUndersideSporulation},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_powdery_mildew',
        labelEs: 'Cenicilla / oidio',
        scientificName: 'Erysiphe cichoracearum / Golovinomyces cichoracearum',
        type: 'fungus',
        summaryEs:
            'Polvo blanco superficial en hojas, mas comun cerca de madurez con baja luz y HR alta. Reduce calidad y hoja activa.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Raspa suavemente: si el polvo se desprende, sube la sospecha de cenicilla.',
      'Revisa hojas medias y externas; suele iniciar en focos.',
      'Si hay enves gris y manchas angulares, revisar mildiu velloso en su lugar.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _baseActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),

  // 8) Bacteriosis / soft rot / pudricion blanda.
  PlantHealthSyndrome(
    id: 'lettuce_bacterial_soft_rot_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Tejido acuoso, blando y con olor fuerte',
    stages: _qualityStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalWaterSoakedMargin,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalHeatStress,
    },
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_soft_rot_bacteria',
        labelEs: 'Pudricion blanda bacteriana',
        scientificName: 'Pectobacterium spp. / Pseudomonas spp.',
        type: 'bacteria',
        summaryEs:
            'Tejido acuoso y blando que avanza rapido, con olor fuerte. Se favorece con heridas, agua libre, calor y mal manejo en campo o poscosecha.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si el tejido se siente acuoso, blando y huele fuerte.',
      'Ubica si hubo heridas, lluvia, agua libre o manejo en humedo.',
      'Confirma que el avance sea rapido y no una mancha seca.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Evitar heridas y manejo con follaje mojado; cosechar en seco si es posible.',
      'Mejorar higiene y enfriamiento; retirar tejido muy afectado.',
      'No mojar de mas el follaje y revisar drenaje.',
      'Escalar a tecnico si el avance es rapido en lote comercial.',
    ],
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),

  // 9) Pulgones.
  PlantHealthSyndrome(
    id: 'lettuce_aphids_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Colonias de pulgon, melaza y deformacion',
    stages: _vectorStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAphidColonies,
    strongSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalAphidEarlyToxicity,
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
    },
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_aphids',
        labelEs: 'Pulgones',
        scientificName: 'Nasonovia ribisnigri / Myzus persicae / Aphididae',
        type: 'insect',
        summaryEs:
            'Colonias en enves y hojas jovenes con melaza y deformacion. Contaminan la cabeza y pueden transmitir virus. El dano interno en cabeza pesa mas que una colonia externa tardia.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa enves y hojas internas: el pulgon dentro de la cabeza pesa mas.',
      'Busca melaza pegajosa y fumagina negra como senal indirecta.',
      'Revisa malezas hospederas y cultivos vecinos como foco de entrada.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.lettuceCropId,
        varietyIds: _headVarieties,
        diagnosisIds: <String>{'lettuce_aphids'},
        scoreDelta: 4,
        rationaleEs:
            'En tipos que cabecean, el pulgon contamina la cabeza y baja calidad comercial.',
      ),
    ],
  ),

  // 10) Trips.
  PlantHealthSyndrome(
    id: 'lettuce_thrips_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Raspado plateado y punteado fino en hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalDryHotWindow,
    },
    weakSignals: <String>{PlantHealthIds.signalVectorPresent},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_thrips',
        labelEs: 'Trips',
        scientificName: 'Frankliniella spp. / Thrips tabaci',
        type: 'insect',
        summaryEs:
            'Raspado plateado, puntos negros de excremento y dano estetico. Clima calido-seco y malezas o flores cercanas favorecen su presion; pueden ser vectores.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Golpea hojas o brotes sobre una superficie clara y busca trips pequenos.',
      'Revisa hojas jovenes por raspado plateado y puntos negros.',
      'Distingue raspado de mosaico viral: el vector visible sube la sospecha.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),

  // 11) Minador de hoja.
  PlantHealthSyndrome(
    id: 'lettuce_leafminer_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Galerias serpenteantes dentro de la hoja',
    stages: _foliarStages,
    organIds: <String>{PlantHealthIds.organLeaf},
    primarySymptomId: PlantHealthIds.symptomLeafMines,
    strongSignals: <String>{
      PlantHealthIds.signalLeafMines,
      PlantHealthIds.signalVectorPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_leafminer',
        labelEs: 'Minador de hoja',
        scientificName: 'Liriomyza spp.',
        type: 'insect',
        summaryEs:
            'Galerias blancas o plateadas serpenteantes dentro de la hoja. Sube con presion regional, cultivos vecinos y reduccion de parasitoides naturales.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Mira la hoja a contraluz y sigue la galeria; busca la larva al final.',
      'Revisa si el dano avanza hacia hojas comerciales internas.',
      'Pregunta por cultivos vecinos y uso de productos que afecten parasitoides.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),

  // 12) Mosca blanca.
  PlantHealthSyndrome(
    id: 'lettuce_whitefly_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Mosca blanca, melaza y amarillamiento',
    stages: _vectorStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomWhiteflyPresence,
    strongSignals: <String>{
      PlantHealthIds.signalWhiteflyCloud,
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
    },
    weakSignals: <String>{PlantHealthIds.signalHeatStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_whitefly',
        labelEs: 'Mosca blanca',
        scientificName: 'Bemisia tabaci / Trialeurodes vaporariorum',
        type: 'insect',
        summaryEs:
            'Adultos blancos al mover las hojas, ninfas en enves, melaza y clorosis. Contamina la lechuga y puede ser vector potencial; sube con clima calido y cultivos vecinos.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Sacude la planta para ver la nube de mosca blanca y revisa enves por ninfas.',
      'Busca melaza pegajosa y fumagina negra en el follaje.',
      'Ubica si la presion viene de cultivos vecinos o malezas hospederas.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),

  // 13) Virosis asociadas a vectores.
  PlantHealthSyndrome(
    id: 'lettuce_virus_complex_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Mosaico, amarillamiento o crecimiento irregular',
    stages: _vectorStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalRecentStress,
    },
    weakSignals: <String>{PlantHealthIds.signalAphidEarlyToxicity},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_vector_virus_complex',
        labelEs: 'Virosis asociadas a vectores',
        scientificName:
            'Lettuce mosaic virus / complejo viral; Aphididae / Thripidae / Bemisia',
        type: 'insect_virus',
        summaryEs:
            'Mosaico, amarillamiento, deformacion o planta frenada. No hay cura quimica directa: se maneja controlando vectores, eliminando focos y usando semilla sana.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa brotes nuevos: mosaico y deformacion pesan mas que hojas viejas.',
      'Busca pulgon, trips o mosca blanca como vectores cercanos.',
      'Si hay mosaico sin vector visible, pregunta por focos vecinos, semilla o maleza hospedera.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _vectorActions,
    disclaimerEs: _disclaimer,
    varietyModifiers: <VarietyModifier>[
      VarietyModifier(
        cropId: CropCatalog.lettuceCropId,
        varietyIds: _looseLeafVarieties,
        diagnosisIds: <String>{'lettuce_vector_virus_complex'},
        scoreDelta: 4,
        rationaleEs:
            'Hoja suelta y baby leaf pierden valor comercial muy rapido con mosaico y deformacion viral.',
      ),
    ],
    favorsVectorPressure: true,
    favorsRecentStress: true,
  ),

  // 14) Malezas como refugio de plagas y vectores.
  PlantHealthSyndrome(
    id: 'lettuce_weeds_vector_refuge_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Malezas en bordes o camas con vectores cerca',
    stages: _vectorStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAphidColonies,
    strongSignals: <String>{
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalAphidEarlyToxicity,
    },
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_weeds_vector_refuge',
        labelEs: 'Malezas/refugios como riesgo indirecto',
        scientificName: 'Hospederos de pulgon, trips, mosca blanca y virus',
        type: 'cultural_risk',
        summaryEs:
            'Malezas en bordes, camas o canales funcionan como refugio de vectores y reservorio de virus. No es una enfermedad por si sola, pero aumenta presion de pulgon, trips, mosca blanca y virosis.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa bordes, canales y espacios entre camas por malezas hospederas.',
      'Busca pulgon, trips o mosca blanca en malezas antes de revisar solo la lechuga.',
      'Relaciona los focos de mosaico, melaza o deformacion con la entrada desde orillas.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Manejar malezas hospederas en bordes y camas sin remover suelo de forma agresiva.',
      'Monitorear primero orillas y entradas de viento donde suelen llegar vectores.',
      'Separar maleza/refugio de dano directo: confirmar vector y patron antes de escalar.',
      'Registrar focos para ajustar limpieza, rotacion y monitoreo del proximo ciclo.',
    ],
    disclaimerEs: _disclaimer,
    favorsVectorPressure: true,
  ),

  // 15) Babosas y caracoles.
  PlantHealthSyndrome(
    id: 'lettuce_slugs_snails_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Mordidas irregulares con rastro brillante',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalFeedingHoles,
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalCoolDewyWindow,
    },
    weakSignals: <String>{PlantHealthIds.signalWaterlogging},
    conflictingSignals: <String>{PlantHealthIds.signalNoBiteMarks},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_slugs_snails',
        labelEs: 'Babosas y caracoles',
        scientificName: 'Gastropoda',
        type: 'mollusk',
        summaryEs:
            'Mordidas irregulares y rastro brillante. Suben con suelo humedo, noches frescas, residuos y riego nocturno.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Busca mordidas irregulares y rastro brillante, sobre todo temprano o de noche.',
      'Revisa refugios humedos: residuos, tablas, orillas y maleza.',
      'Confirma si el dano coincide con riego nocturno o lluvia.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Eliminar refugios humedos y residuos cerca de las camas.',
      'Regar temprano para que la superficie llegue seca a la noche.',
      'Usar trampas y monitoreo nocturno; consultar tecnico si el dano avanza.',
      'Documentar focos y clima reciente.',
    ],
    disclaimerEs: _disclaimer,
    favorsCoolDewyWindow: true,
  ),

  // 16) Deficit hidrico.
  PlantHealthSyndrome(
    id: 'lettuce_water_deficit_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Marchitez, perdida de turgencia o bordes secos',
    stages: _foliarStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_water_deficit',
        labelEs: 'Deficit hidrico',
        scientificName: 'Estres abiotico por falta de agua',
        type: 'abiotic',
        summaryEs:
            'Humedad <50% AW con calor o viento causa marchitez, perdida de turgencia y bordes secos. En lechuga afecta directamente sabor, calidad y oportunidad de cosecha, y puede disparar el espigado.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa la humedad real del suelo antes de culpar a una plaga.',
      'Confirma si la planta recupera turgencia de tarde/noche o si ya hay dano.',
      'Ubica si coincide con viento, calor o suelo ligero.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _qualityActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),

  // 17) Exceso de humedad / anoxia.
  PlantHealthSyndrome(
    id: 'lettuce_excess_moisture_anoxia_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Marchitez o crecimiento lento con suelo saturado',
    stages: _rootSoilStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_anoxia_excess_moisture',
        labelEs: 'Anoxia / exceso de humedad',
        scientificName: 'Estres abiotico por saturacion',
        type: 'abiotic',
        summaryEs:
            'La planta puede verse marchita aunque el suelo este mojado. La raiz superficial de lechuga necesita oxigeno; la saturacion prolongada favorece pudriciones.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Toca el suelo y revisa la humedad real antes de regar mas.',
      'Revisa raiz y cuello para separar anoxia de patogeno avanzado.',
      'Ubica zonas bajas, cama compactada o riego demasiado largo.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _rootSoilActions,
    disclaimerEs: _disclaimer,
    favorsHighHumidity: true,
  ),

  // 18) Estres salino.
  PlantHealthSyndrome(
    id: 'lettuce_salinity_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Crecimiento reducido y bordes quemados por sales',
    stages: _allLettuceStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_salinity_stress',
        labelEs: 'Estres salino / CE alta',
        scientificName: 'Estres abiotico por salinidad',
        type: 'abiotic',
        summaryEs:
            'Lechuga es sensible a sales: ECe >1.3 dS/m ya marca perdida potencial; >2.0 es alerta y >3.0 critico. Frena crecimiento y quema bordes aunque haya fertilizante disponible. No se resuelve agregando mas fertilizante.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa la lectura de CE junto con la humedad; sales altas con bulbo seco pesan mas.',
      'Pregunta por agua de riego salina, fertirriego cargado o lavado insuficiente.',
      'Separa de enfermedad: la salinidad suele verse mas uniforme que un foco infeccioso.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),

  // 19) Compactacion / raiz limitada.
  PlantHealthSyndrome(
    id: 'lettuce_compaction_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Crecimiento desuniforme con raiz superficial limitada',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
    },
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalRecentStress,
      PlantHealthIds.signalWaterlogging,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_compaction',
        labelEs: 'Compactacion / raiz limitada',
        scientificName: 'Limitacion fisica del suelo',
        type: 'physical',
        summaryEs:
            'Resistencia >=2 MPa limita la raiz superficial de la lechuga: absorbe peor agua y nutrientes y aparecen encharcamientos. La correccion real suele ser pre-siembra, no durante el ciclo.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisa si el crecimiento es desuniforme por parches o lineas de maquinaria.',
      'Confirma si la raiz queda corta y superficial, y si hay encharques.',
      'Pregunta por cama mal preparada o suelo trabajado en humedo.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Tratar la compactacion pre-siembra: subsoleo/escarificado y materia organica.',
      'Evitar trabajar el suelo en humedo y el paso de maquinaria.',
      'Revisar riego para no agravar el encharcamiento.',
      'Documentar resistencia y zonas afectadas para el proximo ciclo.',
    ],
    disclaimerEs: _disclaimer,
    favorsRecentStress: true,
  ),

  // 20) Dano por frio / helada.
  PlantHealthSyndrome(
    id: 'lettuce_cold_injury_01',
    cropId: CropCatalog.lettuceCropId,
    labelEs: 'Dano por frio, helada o arranque frenado',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomColdInjury,
    strongSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalRecentStress,
    },
    weakSignals: <String>{PlantHealthIds.signalCoolDewyWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'lettuce_cold_frost_injury',
        labelEs: 'Dano por frio o helada',
        scientificName: 'Estres abiotico por frio',
        type: 'abiotic',
        summaryEs:
            'La lechuga es de estacion fresca y tolera frio moderado, pero la helada puede danar hojas externas y marcar la cabeza. El frio fuerte tambien frena el arranque.',
      ),
    ],
    confirmationChecksEs: <String>[
      'Relaciona el dano con noches frias o helada reciente.',
      'Revisa si el dano aparece uniforme en hojas externas o expuestas.',
      'Distingue de enfermedad: el dano por frio coincide con un evento climatico claro.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: _abioticActions,
    disclaimerEs: _disclaimer,
    favorsCoolDewyWindow: true,
  ),
];
