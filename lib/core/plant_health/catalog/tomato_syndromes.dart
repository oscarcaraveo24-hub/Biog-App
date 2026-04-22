import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

const Set<PlantHealthStageBucket> _tomatoFoliarDiseaseStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    };

const Set<PlantHealthStageBucket> _tomatoVectorStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
    };

const Set<PlantHealthStageBucket> _tomatoProductiveStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    };

const Set<PlantHealthStageBucket> _tomatoFruitStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    };

const Set<PlantHealthStageBucket> _tomatoFullCycleStages =
    <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
      PlantHealthStageBucket.lateSeason,
    };

/// Tomato sanitary catalog for BIO-G v1.
///
/// Scope:
/// - Soil-grown tomato only.
/// - Open field and protected soil systems.
/// - No hydroponics or inert substrate flows.
const List<PlantHealthSyndrome> tomatoSyndromes = <PlantHealthSyndrome>[
  PlantHealthSyndrome(
    id: 'tomato_late_blight_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Manchas acuosas de avance rapido - tizon tardio',
    stages: _tomatoFoliarDiseaseStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalWaterSoakedMargin,
      PlantHealthIds.signalRapidFoliarCollapse,
      PlantHealthIds.signalCoolDewyWindow,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalFrassPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'phytophthora_infestans',
        labelEs: 'Tizon tardio',
        scientificName: 'Phytophthora infestans',
        type: 'oomycete',
        summaryEs:
            'Provoca lesiones acuosas gris-verdosas que avanzan muy rapido en hoja, peciolo y tallo. Con rocio prolongado puede aparecer micelio blanquecino en el enves y colapso acelerado del dosel.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterSoakedMargin,
          PlantHealthIds.signalRapidFoliarCollapse,
          PlantHealthIds.signalCoolDewyWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalActiveChewing,
          PlantHealthIds.signalFrassPresent,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar borde acuoso en las lesiones, no solo un margen seco.',
      'Revisar el enves al amanecer o con alta humedad para detectar micelio blanquecino.',
      'Si el lote se vino abajo en 24-48 horas despues de noches frescas y humedas, la sospecha sube mucho.',
      'Revisar tallos y peciolos; las lesiones oscuras que los rodean pesan fuerte para tizon tardio.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Aislar y sacar focos tempranos para bajar inoculo.',
      'Evitar riego por aspersion y horas largas de follaje mojado.',
      'En protegido, abrir ventilacion nocturna y bajar humedad relativa.',
      'Si el frente humedo sigue activo, evaluar fungicida especifico con apoyo tecnico.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. Puede confundirse con tizon temprano, pero aqui pesan el borde acuoso, el clima fresco-humedo y la velocidad de avance.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'tomato_early_blight_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Manchas concentricas en hojas bajeras - tizon temprano',
    stages: _tomatoFoliarDiseaseStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalDarkStriations,
      PlantHealthIds.signalNoClearPustules,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalWaterSoakedMargin,
      PlantHealthIds.signalRapidFoliarCollapse,
      PlantHealthIds.signalActiveChewing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'alternaria_solani',
        labelEs: 'Tizon temprano',
        scientificName: 'Alternaria solani',
        type: 'fungus',
        summaryEs:
            'Empieza en hojas viejas con lesiones cafes de anillos concentricos tipo diana. Sube desde la parte baja, causa defoliacion y deja fruto expuesto a golpe de sol.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalDarkStriations,
          PlantHealthIds.signalNoClearPustules,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalWaterSoakedMargin,
          PlantHealthIds.signalRapidFoliarCollapse,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar patron de anillos concentricos en hojas viejas o bajeras.',
      'Revisar si el avance fue gradual y no explosivo como en tizon tardio.',
      'Si hay lesiones en tallo cerca del cuello, documentarlas porque ayudan a diferenciar Alternaria.',
      'Si aparecen mordidas, galerias o excretas, revisar Tuta antes de asumir enfermedad.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Quitar hojas bajeras muy cargadas para bajar inoculo y mejorar ventilacion.',
      'Evitar salpique de suelo al follaje y periodos largos de hoja mojada.',
      'Si ya llego a hojas medias o a racimos y el ambiente sigue favorable, evaluar fungicida con soporte tecnico.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. Aqui pesan el patron concentric y el avance mas lento que el tizon tardio.',
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'tomato_gray_mold_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Moho gris en flor, hoja o tallo - Botrytis',
    stages: _tomatoProductiveStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomGrayFoliarScald,
    strongSignals: <String>{
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalSporesRubOff,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalStemCanker,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'botrytis_cinerea',
        labelEs: 'Moho gris / Botrytis',
        scientificName: 'Botrytis cinerea',
        type: 'fungus',
        summaryEs:
            'Crece como moho gris afelpado sobre heridas de poda, flores secas, tallos y frutos cuando hay humedad alta y poca ventilacion. Es un clasico de tomate protegido.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalGrayFuzzyGrowth,
          PlantHealthIds.signalHumidWindow,
          PlantHealthIds.signalSporesRubOff,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalWhitePowderGrowth,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Mover suavemente el tejido afectado y confirmar si suelta polvo de esporas grises.',
      'Revisar heridas de poda, flores abortadas y racimos cerrados con poca ventilacion.',
      'En fruto, confirmar tejido blando con micelio gris y no solo una mancha seca superficial.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Bajar humedad relativa y condensacion nocturna, sobre todo bajo cubierta.',
      'Podar y deshojar solo en condiciones secas y con higiene de herramientas.',
      'Retirar tejido muerto o colonizado para cortar fuentes de esporas.',
      'Si el brote ya agarro racimos, evaluar programa fungicida con criterio tecnico.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. Botrytis suele indicar fallo de humedad y ventilacion mas que un problema de suelo.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'tomato_whitefly_tylcv_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Rizado, amarillamiento o mosaico con mosca blanca',
    stages: _tomatoVectorStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalWhiteflyCloud,
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalLeafRolling,
    },
    weakSignals: <String>{
      PlantHealthIds.signalStickyHoneydew,
      PlantHealthIds.signalSootyMold,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tylcv',
        labelEs: 'Virus del rizado amarillo',
        scientificName: 'Tomato yellow leaf curl virus',
        type: 'virus',
        summaryEs:
            'En infecciones tempranas produce rizado hacia arriba, amarillamiento marginal, entrenudos cortos y una fuerte perdida de vigor. Una vez instalado, no se corrige.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalLeafRolling,
          PlantHealthIds.signalVectorPresent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalSootyMold,
        },
      ),
      PlantHealthDiagnosis(
        id: 'bemisia_tabaci_tomato',
        labelEs: 'Mosca blanca',
        scientificName: 'Bemisia tabaci',
        type: 'insect',
        summaryEs:
            'Ademas del dano directo por succion, mielecilla y fumagina, es el vector principal de begomovirus en tomate.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWhiteflyCloud,
          PlantHealthIds.signalStickyHoneydew,
          PlantHealthIds.signalSootyMold,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Mover el follaje y confirmar si sale nube de mosca blanca.',
      'Revisar hojas nuevas: el TYLCV se nota mejor en crecimiento nuevo que en hojas viejas.',
      'Si domina mielecilla y tizne sin rizado claro, puede pesar mas el dano directo del insecto que el componente viral.',
      'Documentar si el problema entro muy temprano; ahi es donde mas castiga rendimiento.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Cortar presion temprana del vector; el dano viral ya instalado no se revierte.',
      'Monitorear bordes, malezas hospederas y puntos calientes con trampas amarillas.',
      'En protegido, revisar mallas, dobles puertas y sellos laterales.',
      'Separar plantas muy deformadas si ya son foco evidente.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. La confirmacion especifica del virus requiere laboratorio; aqui se pondera por clinica y presencia de vector.',
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'tomato_tuta_absoluta_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Galerias, perforaciones y excretas - Tuta absoluta',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomNecroticFoliarSpots,
    strongSignals: <String>{
      PlantHealthIds.signalActiveChewing,
      PlantHealthIds.signalFrassPresent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalLeafRolling,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalNoBiteMarks,
      PlantHealthIds.signalWaterSoakedMargin,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tuta_absoluta',
        labelEs: 'Polilla del tomate',
        scientificName: 'Phthorimaea absoluta',
        type: 'insect',
        summaryEs:
            'La larva mina la hoja, deja excretas oscuras y puede perforar tallo y fruto. En tomate protegido suele ser una de las plagas mas costosas si se atrasa el control.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalActiveChewing,
          PlantHealthIds.signalFrassPresent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalNoBiteMarks,
          PlantHealthIds.signalWaterSoakedMargin,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar galerias transluidas o irregulares dentro del foliolo, no solo manchas planas.',
      'Confirmar excretas oscuras dentro de la mina o junto al dano.',
      'Revisar fruto y tallo joven; la entrada a fruto cambia la urgencia economica.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Retirar hojas y frutos claramente atacados para bajar presion.',
      'Monitorear con feromona para medir curva real de la plaga.',
      'No dejar residuos verdes sin destruir dentro o junto al modulo.',
      'Si ya hay dano en fruto, evaluar control tecnico con rotacion real de modos de accion.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. Algunas minas pueden parecerse a Liriomyza, pero Tuta pesa mas cuando tambien aparece dano en tallo o fruto.',
  ),
  PlantHealthSyndrome(
    id: 'tomato_blossom_end_rot_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Parche apical negro en fruto - blossom-end rot',
    stages: _tomatoFruitStages,
    organIds: <String>{
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomFruitApicalRot,
    strongSignals: <String>{
      PlantHealthIds.signalFruitApicalBlackPatch,
    },
    weakSignals: <String>{
      PlantHealthIds.signalLeafRolling,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'blossom_end_rot',
        labelEs: 'Pudricion apical por desbalance Ca-agua',
        scientificName: '',
        type: 'abiotic',
        summaryEs:
            'No es una enfermedad infecciosa. Se expresa como un parche apical oscuro y hundido cuando la entrada de calcio al fruto falla por riego irregular, salinidad o desbalance con K y Mg.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalFruitApicalBlackPatch,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar mancha apical hundida en el extremo floral del fruto, no alrededor del pedunculo.',
      'Revisar historial de riego: los jalones de seca y recuperacion suelen disparar el problema.',
      'Cruzar con el contexto nutricional: K muy alto, salinidad o Ca desplazado empeoran la expresion.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Estabilizar riego y evitar oscilaciones fuertes de humedad en el suelo.',
      'Revisar balance de Ca frente a K, Mg y sales totales.',
      'No tratar como hongo: aqui vale mas el manejo de agua y nutricion que el fungicida.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. Si la lesion trae micelio, exudado o inicia por heridas, revisar tambien patologias de fruto.',
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'tomato_powdery_mildew_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Polvillo blanco superficial - cenicilla',
    stages: _tomatoFoliarDiseaseStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomPowderyGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalSporesRubOff,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalWaterSoakedMargin,
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalCannotScrapeOff,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'oidium_neolycopersici',
        labelEs: 'Cenicilla',
        scientificName: 'Oidium neolycopersici / Leveillula taurica',
        type: 'fungus',
        summaryEs:
            'Se presenta como crecimiento blanco superficial, primero en focos y luego en laminas mas amplias. Reduce fotosintesis y calidad del dosel si se deja avanzar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWhitePowderGrowth,
          PlantHealthIds.signalSporesRubOff,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalWaterSoakedMargin,
          PlantHealthIds.signalGrayFuzzyGrowth,
          PlantHealthIds.signalCannotScrapeOff,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar que el crecimiento es superficial y se desprende al frotar.',
      'Revisar hojas medias y altas, donde suele arrancar en ambientes de ventilacion limitada.',
      'Si el tejido esta acuoso o afelpado gris, pensar mejor en tizones o Botrytis.',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Abrir dosel y mejorar ventilacion para bajar humedad interna.',
      'Eliminar hojas muy tomadas cuando el foco aun es pequeno.',
      'Si el avance se acelera en etapa productiva, evaluar manejo fungicida con soporte tecnico.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. La cenicilla suele ser menos explosiva que Botrytis o tizones, pero puede quitar mucha area foliar util si se subestima.',
  ),
  PlantHealthSyndrome(
    id: 'tomato_vascular_wilt_complex_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Marchitez vascular - fusarium / verticillium',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomWiltVascular,
    strongSignals: <String>{
      PlantHealthIds.signalVascularBrowning,
      PlantHealthIds.signalOneSidedWilt,
    },
    weakSignals: <String>{
      PlantHealthIds.signalLeafRolling,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalGrayFuzzyGrowth,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'fusarium_oxysporum_f_sp_lycopersici',
        labelEs: 'Fusarium wilt',
        scientificName: 'Fusarium oxysporum f. sp. lycopersici',
        type: 'fungus',
        summaryEs:
            'Suele arrancar como marchitez parcial o unilateral, con amarillamiento y pardeamiento vascular al cortar tallo o peciolo. Empeora con calor y suelos infestados.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalOneSidedWilt,
          PlantHealthIds.signalVascularBrowning,
        },
      ),
      PlantHealthDiagnosis(
        id: 'verticillium_dahliae',
        labelEs: 'Verticillium wilt',
        scientificName: 'Verticillium dahliae',
        type: 'fungus',
        summaryEs:
            'Causa clorosis interveinal, marchitez y pardeamiento vascular, a menudo con avance mas lento y en condiciones algo mas frescas que Fusarium.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalVascularBrowning,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalOneSidedWilt,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Cortar tallo o peciolo y revisar si hay pardeamiento vascular real.',
      'Anotar si la marchitez empezo en un lado de la planta o en una rama.',
      'Comparar con el horario: si se colapsa al mediodia y recupera en la tarde, revisar tambien componente hidrico.',
      'Sacar una planta completa para revisar raices y cuello antes de cerrar diagnostico.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Marcar focos y evitar mover suelo o agua desde plantas sospechosas al resto del lote.',
      'Retirar plantas muy afectadas si ya son fuente clara de inoculo.',
      'Documentar patron por camas o lineas; el acomodo espacial ayuda mucho en wilts de suelo.',
      'Para siguientes ciclos, pensar en portainjerto, rotacion y sanidad de suelo.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. La confirmacion fuerte requiere revisar tejido vascular y, si se puede, apoyo de laboratorio.',
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'tomato_bacterial_spot_speck_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Punteado o mancha bacteriana en hoja y fruto',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.seedling,
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
    },
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomBacterialSpeckSpot,
    strongSignals: <String>{
      PlantHealthIds.signalHaloMargin,
      PlantHealthIds.signalWaterSoakedMargin,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAngularLesionPattern,
      PlantHealthIds.signalHumidWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalWhitePowderGrowth,
      PlantHealthIds.signalGrayFuzzyGrowth,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'xanthomonas_tomato_spot_complex',
        labelEs: 'Bacterial spot',
        scientificName:
            'Xanthomonas euvesicatoria / perforans / vesicatoria complex',
        type: 'bacteria',
        summaryEs:
            'Produce lesiones negras o cafes con borde acuoso en hoja y lesiones costrosas en fruto. Sube fuerte con salpique, herramientas y humedad alta.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterSoakedMargin,
          PlantHealthIds.signalAngularLesionPattern,
        },
      ),
      PlantHealthDiagnosis(
        id: 'pseudomonas_syringae_pv_tomato',
        labelEs: 'Bacterial speck',
        scientificName: 'Pseudomonas syringae pv. tomato',
        type: 'bacteria',
        summaryEs:
            'Tiende a dar puntitos mas pequenos con halo clorotico claro, especialmente en ambientes frescos y humedos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHaloMargin,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalAngularLesionPattern,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Confirmar si la lesion arranca acuosa o grasosa antes de secarse.',
      'En fruto, diferenciar entre costra bacteriana superficial y lesion hundida de otro origen.',
      'Si predominan halos pequenos en clima fresco-humedo, speck gana fuerza.',
      'Si hay salpique, lluvia o poda en mojado, la hipotesis bacteriana sube.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Evitar manejo del follaje mojado y desinfectar herramientas.',
      'Reducir salpique y escurrimientos entre camas o lineas.',
      'No mezclar lotes sanos con plantas de semillero sospechosas.',
      'Si el brote ya esta en fruto comercial, valorar respuesta tecnica rapida.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. La separacion fina entre spot y speck mejora con laboratorio, pero el manejo preventivo inicial es muy parecido.',
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  PlantHealthSyndrome(
    id: 'tomato_bacterial_canker_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Cancros en tallo o fruto con marchitez - cancro bacteriano',
    stages: <PlantHealthStageBucket>{
      PlantHealthStageBucket.vegetativeEarly,
      PlantHealthStageBucket.vegetativeMid,
      PlantHealthStageBucket.vegetativeLate,
      PlantHealthStageBucket.reproductiveEarly,
      PlantHealthStageBucket.reproductiveMid,
      PlantHealthStageBucket.grainFill,
    },
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organFruit,
    },
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalStemCanker,
      PlantHealthIds.signalVascularBrowning,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHaloMargin,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'clavibacter_michiganensis',
        labelEs: 'Cancro bacteriano',
        scientificName: 'Clavibacter michiganensis',
        type: 'bacteria',
        summaryEs:
            'Puede combinar cancros en tallo, marchitez sistemica y lesiones de fruto tipo ojo de pajaro. Se mueve facil con semilla, trasplante y labores.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalStemCanker,
          PlantHealthIds.signalVascularBrowning,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Buscar cancros en tallo, peciolo o pedunculo y no solo manchas foliares.',
      'Revisar si hay pardeamiento vascular o marchitez persistente en ramas.',
      'En fruto, confirmar lesiones pequenas con halo claro tipo ojo de pajaro.',
      'Preguntar por poda, deschuponado o amarre recientes: ayudan a mover la bacteria.',
    ],
    severity: PlantHealthSeverity.critical,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Aislar y retirar plantas muy sospechosas para no seguir inoculando con labores.',
      'Desinfectar tijeras, cuchillos y manos entre lineas o modulos.',
      'Suspender labores agresivas en tejido mojado o con exudado.',
      'Revisar origen de semilla o trasplante si el brote viene desde etapas tempranas.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. El cancro bacteriano se puede parecer a otros wilts o manchas, pero aqui pesan cancros, vascular y lesiones tipicas en fruto.',
    favorsHighHumidity: true,
  ),
  PlantHealthSyndrome(
    id: 'tomato_thrips_virus_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Bronceado y raspado fino - trips y virus asociados',
    stages: _tomatoVectorStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFruit,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalThripsPresent,
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalVectorPresent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalLeafRolling,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalMitesWebbing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'frankliniella_occidentalis',
        labelEs: 'Trips',
        scientificName: 'Frankliniella occidentalis',
        type: 'insect',
        summaryEs:
            'Causa raspado fino, plateado o bronceado en hoja, flor y fruto joven. Su impacto economico crece mucho por el vector de virus.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalThripsPresent,
          PlantHealthIds.signalBronzedLeafSurface,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tomato_spotted_wilt_virus',
        labelEs: 'Virus asociados a trips',
        scientificName: 'Tomato spotted wilt virus',
        type: 'virus',
        summaryEs:
            'Cuando el dano de trips se acompana de deformacion, anillos o bronceado sistemico, hay que dejar abierto el componente viral asociado.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalVectorPresent,
          PlantHealthIds.signalLeafRolling,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Sacudir flores y brotes tiernos sobre una hoja blanca para confirmar trips.',
      'Separar raspado fino/plateado de un bronceado uniforme por acaros o estres.',
      'Si el problema entro muy temprano y la planta se deformo, dejar mas alta la sospecha de virus asociado.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Monitorear flores, brotes tiernos y trampas adhesivas para medir presion real.',
      'Controlar malezas hospederas y focos tempranos dentro y fuera del modulo.',
      'No esperar a ver dano generalizado en fruto; el costo sube antes.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. La confirmacion del virus requiere laboratorio, pero la combinacion de trips + bronceado + deformacion obliga a no subestimarlo.',
    favorsVectorPressure: true,
  ),
  PlantHealthSyndrome(
    id: 'tomato_mites_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Bronceado con telarana fina - acaros',
    stages: _tomatoFoliarDiseaseStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
    },
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalBronzedLeafSurface,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalThripsPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tetranychus_urticae_complex',
        labelEs: 'Acaros',
        scientificName: 'Tetranychus urticae complex',
        type: 'mite',
        summaryEs:
            'Provocan punteado fino, bronceado y, cuando la colonia sube, telarana ligera y secado rapido del follaje. En ambiente caluroso el avance suele ser muy rapido.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalMitesWebbing,
          PlantHealthIds.signalBronzedLeafSurface,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalThripsPresent,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Revisar enves de hoja con lupa para detectar colonias y huevos.',
      'Confirmar telarana fina entre foliolos o en nervaduras cuando el foco ya va avanzado.',
      'Diferenciar de trips: los acaros dejan mas punteado uniforme y webbing cuando suben.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Detectar focos primero en bordes calientes y secos del modulo o la parcela.',
      'Evitar perder tiempo con controles tardios cuando ya hay webbing en hojas medias y altas.',
      'Si la presion esta subiendo, evaluar manejo tecnico y compatibilidad con enemigos naturales.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. El bronceado foliar tambien puede venir de trips o estres; la presencia de colonias y telarana fina es la clave.',
  ),
  PlantHealthSyndrome(
    id: 'tomato_root_knot_nematodes_01',
    cropId: CropCatalog.tomatoCropId,
    labelEs: 'Raices con agallas y planta frenada - nematodos',
    stages: _tomatoFullCycleStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootGalls,
    strongSignals: <String>{
      PlantHealthIds.signalRootGalls,
    },
    weakSignals: <String>{
      PlantHealthIds.signalLeafRolling,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'meloidogyne_spp',
        labelEs: 'Nematodos agalladores',
        scientificName: 'Meloidogyne spp.',
        type: 'nematode',
        summaryEs:
            'Dan un cuadro de planta frenada, clorotica y cansada, pero la confirmacion fuerte sale al arrancar la planta y encontrar agallas en raiz.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRootGalls,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      'Sacar una planta completa y lavar raiz para confirmar agallas reales.',
      'Revisar si el problema aparece por rodales o camas especificas; ese patron es tipico.',
      'No cerrar diagnostico solo por amarillamiento o bajo vigor: hay que ver raiz.',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Marcar zonas calientes y evitar mover suelo contaminado a areas limpias.',
      'Documentar severidad por cama para decidir rotacion, injerto o manejo biologico en el siguiente ciclo.',
      'Si el lote esta en protegido, revisar historial del suelo antes de repetir tomate.',
    ],
    disclaimerEs:
        'Diagnostico sugerido. El dato clinico util aqui es la raiz; sin revisar agallas, el resultado debe tomarse como sospecha.',
  ),
];
