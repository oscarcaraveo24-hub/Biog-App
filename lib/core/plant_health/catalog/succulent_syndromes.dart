import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

/// Sanidad de la Suculenta ornamental (Documento C, SU v1.0).
///
/// Contrato de seguridad (Doc C §1) — inviolable:
/// - BIO-G **no** diagnostica un organismo causal (ni hongo, ni bacteria, ni
///   plaga) y **no** dice "tiene pudrición" como hecho confirmado.
/// - **No** receta productos, ingredientes activos ni dosis.
/// - El sensor por sí solo **nunca** genera una alerta sanitaria alta: los
///   síndromes requieren observación del usuario.
/// - Ante dos explicaciones plausibles, se prioriza la revisión que evite
///   agravar el daño (hojas arrugadas + sustrato húmedo ⇒ NO sugerir riego).
///
/// Estructura copiada de `cactus_syndromes.dart`; textos e ids son propios.
const Set<PlantHealthStageBucket> _succulentStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.lateSeason,
};

const String _succulentDisclaimer =
    'BIO-G organiza observaciones y contexto para orientar la revisión. '
    'No confirma una enfermedad, una plaga ni un organismo causal.';

const List<PlantHealthSyndrome> succulentSyndromes = <PlantHealthSyndrome>[
  // ── SU-SYN-001 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_root_collar_condition_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Base o raíz con deterioro por confirmar',
    stages: _succulentStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSucculentRootCollarDeterioration,
    strongSignals: <String>{
      PlantHealthIds.signalSucculentSoftOrWatery,
      PlantHealthIds.signalSucculentProgressing,
      PlantHealthIds.signalSucculentLossOfSupport,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalSucculentWrinkling,
      PlantHealthIds.signalSucculentFungusGnats,
      PlantHealthIds.signalSucculentAbnormalOdor,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentFirmDry,
      PlantHealthIds.signalSucculentStable,
      PlantHealthIds.signalSucculentLowerLeavesOnly,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_root_collar_deterioration_compatible',
        labelEs: 'Condición compatible con deterioro de raíz o cuello',
        type: 'condition_compatible',
        summaryEs:
            'La apariencia de sed también aparece cuando la raíz ya no '
            'funciona. Antes de regar, revisa la base, el drenaje y la humedad '
            'real. Estos datos no identifican una causa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentSoftOrWatery,
          PlantHealthIds.signalSucculentProgressing,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSucculentFirmDry,
          PlantHealthIds.signalSucculentStable,
        },
      ),
      PlantHealthDiagnosis(
        id: 'succulent_transplant_stress_possible',
        labelEs: 'Estrés de trasplante o anclaje por confirmar',
        type: 'visual_concern',
        summaryEs:
            'Un cambio de maceta reciente, una raíz lastimada o una maceta '
            'inestable pueden producir un cuadro parecido sin que exista '
            'enfermedad.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La base está firme o blanda?',
      '¿El sustrato sigue húmedo?',
      '¿La planta se mueve fácilmente en la maceta?',
      '¿El cambio está avanzando?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Revisa que el agua pueda salir libremente.',
      'Evita agregar más agua mientras el sustrato siga húmedo.',
      'Mantén la planta separada si hay tejido alterado o insectos.',
      'Busca evaluación local si la base pierde firmeza o la planta se afloja.',
    ],
    disclaimerEs: _succulentDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── SU-SYN-002 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_soft_water_soaked_tissue_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Tejido blando o acuoso que requiere revisión',
    stages: _succulentStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSucculentSoftWaterSoakedTissue,
    strongSignals: <String>{
      PlantHealthIds.signalSucculentSoftOrWatery,
      PlantHealthIds.signalSucculentProgressing,
      PlantHealthIds.signalSucculentLossOfSupport,
      PlantHealthIds.signalSucculentAbnormalOdor,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentFirmDry,
      PlantHealthIds.signalSucculentStable,
      PlantHealthIds.signalSucculentUniformWaxyBloom,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_internal_tissue_damage_compatible',
        labelEs: 'Condición compatible con daño interno activo',
        type: 'condition_compatible',
        summaryEs:
            'El tejido blando y acuoso necesita revisión prioritaria. BIO-G no '
            'puede confirmar la causa, pero sí reconocer que el cambio está '
            'activo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentProgressing,
          PlantHealthIds.signalSucculentAbnormalOdor,
          PlantHealthIds.signalSucculentLossOfSupport,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSucculentFirmDry,
          PlantHealthIds.signalSucculentStable,
        },
      ),
      PlantHealthDiagnosis(
        id: 'succulent_cold_or_wound_damage_possible',
        labelEs: 'Daño por frío o herida reciente por confirmar',
        type: 'visual_concern',
        summaryEs:
            'Un golpe, un corte o una exposición a frío pueden ablandar el '
            'tejido sin que exista una plaga o una enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalRecentStress,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La zona cede al tacto o se siente acuosa?',
      '¿Está creciendo?',
      '¿Hay líquido, olor o pérdida de soporte?',
      '¿Hubo frío, golpe o riego reciente?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Aísla temporalmente la planta.',
      'Evita mojar la zona y no agregues agua si el sustrato sigue húmedo.',
      'Registra el borde de la zona para comprobar si avanza.',
      'Busca evaluación local si la zona crece o la planta pierde soporte.',
    ],
    disclaimerEs: _succulentDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),

  // ── SU-SYN-003 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_wrinkling_turgor_loss_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Hojas arrugadas o menos firmes',
    stages: _succulentStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSucculentWrinklingTurgorLoss,
    strongSignals: <String>{PlantHealthIds.signalSucculentWrinkling},
    weakSignals: <String>{
      PlantHealthIds.signalSucculentFirmDry,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalSucculentLowerLeavesOnly,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentSoftOrWatery,
      PlantHealthIds.signalSucculentStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_water_deficit_compatible',
        labelEs: 'Falta de agua compatible (sustrato seco, base firme)',
        type: 'condition_compatible',
        summaryEs:
            'Con el sustrato seco y la base firme, la arruga suele responder al '
            'manejo hídrico de la etapa. Confirma la firmeza y el último riego '
            'antes de actuar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentFirmDry,
          PlantHealthIds.signalDryHotWindow,
        },
        contradictorySignalIds: <String>{PlantHealthIds.signalWaterlogging},
      ),
      PlantHealthDiagnosis(
        id: 'succulent_root_not_working_compatible',
        labelEs: 'Raíz que no está tomando agua (sustrato húmedo)',
        type: 'condition_compatible',
        summaryEs:
            'Las arrugas con el sustrato húmedo NO piden más agua: primero se '
            'revisa la raíz, el cuello y el drenaje. Regar aquí agrava el '
            'cuadro.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalSucculentSoftOrWatery,
        },
        contradictorySignalIds: <String>{PlantHealthIds.signalSucculentFirmDry},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El sustrato está seco o húmedo?',
      '¿La base está firme?',
      '¿Las arrugas afectan toda la planta o solo hojas inferiores?',
      '¿Cuándo fue el último riego?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Confirma la humedad real antes de decidir un riego.',
      'Si el sustrato está húmedo, revisa raíz, cuello y drenaje.',
      'Si está seco y la base está firme, sigue el manejo de agua de su etapa.',
      'Busca revisión si la planta pierde soporte.',
    ],
    disclaimerEs: _succulentDisclaimer,
    favorsRecentStress: true,
  ),

  // ── SU-SYN-004 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_edema_intumescence_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Ampollas o costras por revisar',
    stages: _succulentStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organStem},
    primarySymptomId: PlantHealthIds.symptomSucculentEdemaCorkyBlisters,
    strongSignals: <String>{
      PlantHealthIds.signalSucculentRaisedBlisters,
      PlantHealthIds.signalSucculentCorkyScabs,
      PlantHealthIds.signalSucculentLowerLeavesOnly,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalDenseWetCanopy,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentFineWebbing,
      PlantHealthIds.signalSucculentCottonWaxInsects,
      PlantHealthIds.signalSucculentProgressing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_edema_compatible',
        labelEs: 'Respuesta compatible con exceso de agua frente a luz y aire',
        type: 'condition_compatible',
        summaryEs:
            'Estas ampollas pueden ser una respuesta de la planta al exceso de '
            'agua respecto a la luz y la ventilación. No son contagiosas por sí '
            'mismas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentRaisedBlisters,
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalCoolDewyWindow,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSucculentFineWebbing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'succulent_fine_pest_damage_possible',
        labelEs: 'Daño de plaga fina por descartar con lupa',
        type: 'visual_concern',
        summaryEs:
            'Ácaros y trips pueden dejar marcas parecidas. La lupa decide: si '
            'hay organismos o telaraña, no es una ampolla benigna.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentFineWebbing,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Los bultos están sobre todo debajo de hojas viejas?',
      '¿Ves insectos o telaraña con lupa?',
      '¿Aparecieron en días frescos, húmedos o con poca luz?',
      '¿El crecimiento nuevo sale limpio?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Evita mantener el sustrato húmedo en periodos frescos y oscuros.',
      'Mejora la luz y la circulación de aire de forma gradual.',
      'No lo trates como plaga sin confirmar insectos.',
      'Vuelve a revisar el crecimiento nuevo.',
    ],
    disclaimerEs: _succulentDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── SU-SYN-005 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_etiolation_low_light_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Crecimiento nuevo estirado o pálido',
    stages: _succulentStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSucculentEtiolatedGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalSucculentElongatedPaleGrowth,
      PlantHealthIds.signalSucculentRosetteOpening,
    },
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentSoftOrWatery,
      PlantHealthIds.signalSucculentFineWebbing,
      PlantHealthIds.signalSucculentCottonWaxInsects,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_low_light_growth_compatible',
        labelEs: 'Crecimiento compatible con poca luz',
        type: 'condition_compatible',
        summaryEs:
            'El crecimiento nuevo se está estirando buscando luz. El cambio de '
            'exposición debe ser gradual para no causar quemadura.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentElongatedPaleGrowth,
          PlantHealthIds.signalSucculentRosetteOpening,
        },
      ),
      PlantHealthDiagnosis(
        id: 'succulent_excess_nitrogen_possible',
        labelEs: 'Exceso de nutrición como factor por revisar',
        type: 'visual_concern',
        summaryEs:
            'Un exceso de fertilización también alarga y ablanda el tejido. Se '
            'menciona como factor, no como receta.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalSalinityLoad},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El cambio aparece solo en el crecimiento nuevo?',
      '¿La planta se movió a un sitio más oscuro?',
      '¿La roseta se abrió o el tallo se inclinó hacia la luz?',
      '¿Hubo fertilización reciente?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Aumenta la luz de forma gradual, sin pasar de sombra a sol fuerte.',
      'No intentes corregir la forma con más fertilizante.',
      'Evalúa el crecimiento nuevo: el tejido ya estirado no recupera su forma.',
    ],
    disclaimerEs: _succulentDisclaimer,
  ),

  // ── SU-SYN-006 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_sunburn_acclimation_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Mancha compatible con quemadura de sol',
    stages: _succulentStages,
    organIds: <String>{PlantHealthIds.organLeaf, PlantHealthIds.organStem},
    primarySymptomId: PlantHealthIds.symptomSucculentSunburnPatch,
    strongSignals: <String>{
      PlantHealthIds.signalSucculentSunnySide,
      PlantHealthIds.signalSucculentChangedSunExposure,
      PlantHealthIds.signalSucculentFirmDry,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalSucculentStable,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentSoftOrWatery,
      PlantHealthIds.signalSucculentAbnormalOdor,
      PlantHealthIds.signalSucculentProgressing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_sunburn_compatible',
        labelEs: 'Daño compatible con cambio brusco de exposición',
        type: 'condition_compatible',
        summaryEs:
            'La mancha puede ser una quemadura por cambio brusco de luz. El '
            'tejido dañado no vuelve a su aspecto anterior, pero no debe seguir '
            'avanzando.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentSunnySide,
          PlantHealthIds.signalSucculentChangedSunExposure,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSucculentSoftOrWatery,
        },
      ),
      PlantHealthDiagnosis(
        id: 'succulent_chemical_or_active_lesion_possible',
        labelEs: 'Daño por producto o lesión activa por descartar',
        type: 'visual_concern',
        summaryEs:
            'Si la zona se ablanda, crece o aparece lejos de la cara soleada, '
            'ya no se trata como una simple quemadura.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentRecentSpray,
          PlantHealthIds.signalSucculentProgressing,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La mancha está del lado que recibe más sol?',
      '¿La planta cambió de lugar recientemente?',
      '¿La zona está seca y firme?',
      '¿Se aplicó algún producto antes del sol?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Evita otro cambio brusco de exposición.',
      'Mantén luz suficiente, pero aumenta el sol de forma gradual.',
      'Vigila que la zona permanezca seca, firme y estable.',
      'Trátala como lesión activa si se ablanda o crece.',
    ],
    disclaimerEs: _succulentDisclaimer,
  ),

  // ── SU-SYN-007 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_cold_frost_injury_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Cambio de tejido después de frío',
    stages: _succulentStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSucculentColdTissueChange,
    strongSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalSucculentSoftOrWatery,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalSucculentProgressing,
      PlantHealthIds.signalSucculentLossOfSupport,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentSunnySide,
      PlantHealthIds.signalSucculentStable,
      PlantHealthIds.signalSucculentFineWebbing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_cold_injury_compatible',
        labelEs: 'Daño compatible con frío o helada',
        type: 'condition_compatible',
        summaryEs:
            'El frío puede causar cambios que aparecen días después del evento. '
            'Vigila firmeza, color y soporte. El sustrato húmedo durante el frío '
            'aumenta la preocupación.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalSucculentSoftOrWatery,
        },
        contradictorySignalIds: <String>{PlantHealthIds.signalSucculentStable},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo frío o helada antes del cambio?',
      '¿El tejido está blando, acuoso o translúcido?',
      '¿La planta estaba mojada?',
      '¿La zona sigue aumentando?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Protege la planta de más frío.',
      'Evita añadir agua si el sustrato sigue húmedo.',
      'No manipules con fuerza un tejido que todavía está cambiando.',
      'Busca evaluación local si el daño progresa o la planta colapsa.',
    ],
    disclaimerEs: _succulentDisclaimer,
    favorsHighHumidity: true,
  ),

  // ── SU-SYN-008 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_powdery_surface_growth_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Capa blanca que necesita identificación',
    stages: _succulentStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomSucculentPowderySurfaceGrowth,
    strongSignals: <String>{
      PlantHealthIds.signalSucculentPowderyPatches,
      PlantHealthIds.signalSporesRubOff,
      PlantHealthIds.signalSucculentProgressing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalDenseWetCanopy,
      PlantHealthIds.signalCoolDewyWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentUniformWaxyBloom,
      PlantHealthIds.signalSucculentStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_powdery_surface_growth_compatible',
        labelEs: 'Crecimiento superficial blanco compatible',
        type: 'condition_compatible',
        summaryEs:
            'Una capa blanca puede ser cera protectora, insectos o una '
            'enfermedad superficial. La forma y la progresión ayudan a '
            'distinguirlas; BIO-G no identifica el organismo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentPowderyPatches,
          PlantHealthIds.signalSucculentProgressing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSucculentUniformWaxyBloom,
        },
      ),
      PlantHealthDiagnosis(
        id: 'succulent_natural_wax_differential',
        labelEs: 'Cera natural de la hoja (diferencial benigno)',
        type: 'benign_differential',
        summaryEs:
            'Una película uniforme, azulada o mate, presente desde que nació la '
            'hoja, suele ser cera natural. No se retira por rutina: se pierde de '
            'forma permanente en esa hoja.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentUniformWaxyBloom,
          PlantHealthIds.signalSucculentStable,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSucculentPowderyPatches,
        },
      ),
      PlantHealthDiagnosis(
        id: 'succulent_mealybug_from_white_material_possible',
        labelEs: 'Material algodonoso con insectos por confirmar',
        type: 'visual_concern',
        summaryEs:
            'Si dentro del material hay cuerpos, escamas o melaza pegajosa, el '
            'cuadro apunta a insectos chupadores, no a una capa superficial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentCottonWaxInsects,
          PlantHealthIds.signalStickyHoneydew,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La capa es uniforme o aparece en parches que crecen?',
      '¿Se ven insectos dentro del material?',
      '¿La hoja siempre tuvo ese acabado mate?',
      '¿La capa se extiende a hojas nuevas?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Aísla temporalmente la planta si la capa se extiende.',
      'Evita mojar el follaje.',
      'Revisa con lupa antes de tratar.',
      'No retires por rutina la cera uniforme de hojas sanas.',
    ],
    disclaimerEs: _succulentDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── SU-SYN-009 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_leaf_spot_gray_mold_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Manchas o moho en hojas y tallos',
    stages: _succulentStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomSucculentLeafSpotGrayMold,
    strongSignals: <String>{
      PlantHealthIds.signalWaterSoakedSpots,
      PlantHealthIds.signalGrayFuzzyGrowth,
      PlantHealthIds.signalSucculentProgressing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalDenseWetCanopy,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentFirmDry,
      PlantHealthIds.signalSucculentStable,
      PlantHealthIds.signalSucculentUniformWaxyBloom,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_leaf_lesion_compatible',
        labelEs: 'Lesión foliar activa compatible',
        type: 'condition_compatible',
        summaryEs:
            'Las manchas pueden tener causas distintas. La humedad, el tipo de '
            'borde y la progresión ayudan a decidir si requieren atención '
            'prioritaria. No se identifica el organismo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterSoakedSpots,
          PlantHealthIds.signalGrayFuzzyGrowth,
          PlantHealthIds.signalSucculentProgressing,
        },
        contradictorySignalIds: <String>{PlantHealthIds.signalSucculentStable},
      ),
      PlantHealthDiagnosis(
        id: 'succulent_old_scar_differential',
        labelEs: 'Cicatriz o daño resuelto (diferencial benigno)',
        type: 'benign_differential',
        summaryEs:
            'Una mancha seca, firme, estable y sin olor suele ser daño ya '
            'resuelto. No requiere aislamiento.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentFirmDry,
          PlantHealthIds.signalSucculentStable,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La mancha está húmeda o seca?',
      '¿Hay crecimiento gris o velloso?',
      '¿Aumenta entre revisiones?',
      '¿Hubo follaje mojado o tejido muerto cerca?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Separa la planta mientras se confirma el cuadro.',
      'Evita mojar las hojas y retira solo el tejido totalmente desprendido.',
      'Mejora el espacio y la circulación de aire.',
      'Busca evaluación local si avanzan o aparecen en varias plantas.',
    ],
    disclaimerEs: _succulentDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),

  // ── SU-SYN-010 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_mealybug_scale_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Material algodonoso o escamas con insectos por confirmar',
    stages: _succulentStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSucculentCottonWaxScale,
    strongSignals: <String>{
      PlantHealthIds.signalSucculentCottonWaxInsects,
      PlantHealthIds.signalSucculentScaleBodies,
      PlantHealthIds.signalStickyHoneydew,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSootyMold,
      PlantHealthIds.signalVectorPresent,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentUniformWaxyBloom,
      PlantHealthIds.signalSucculentStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_sucking_pest_compatible',
        labelEs: 'Insectos chupadores compatibles (cochinilla o escama)',
        type: 'pest_compatible',
        summaryEs:
            'El material algodonoso puede contener insectos chupadores. Confirma '
            'cuerpos, escamas o pegajosidad antes de tratar. Algunas especies '
            'viven en la raíz y pasan desapercibidas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentCottonWaxInsects,
          PlantHealthIds.signalSucculentScaleBodies,
          PlantHealthIds.signalStickyHoneydew,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSucculentUniformWaxyBloom,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Se ven cuerpos o escamas dentro del material?',
      '¿Está pegajoso?',
      '¿Se concentra en axilas y uniones?',
      '¿Aparece también cerca del drenaje?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Aísla la planta de las demás.',
      'Inspecciona uniones, envés, base y borde de la maceta.',
      'Retira físicamente los individuos visibles cuando sea seguro.',
      'Busca apoyo si la infestación es extensa o llega a la raíz.',
    ],
    disclaimerEs: _succulentDisclaimer,
    favorsVectorPressure: true,
  ),

  // ── SU-SYN-011 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_mites_thrips_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Punteado o deformación con plaga pequeña por confirmar',
    stages: _succulentStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
    },
    primarySymptomId: PlantHealthIds.symptomSucculentStipplingWebbing,
    strongSignals: <String>{
      PlantHealthIds.signalSucculentFineWebbing,
      PlantHealthIds.signalMitesWebbing,
      PlantHealthIds.signalThripsPresent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalBronzedLeafSurface,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalVectorPresent,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentRaisedBlisters,
      PlantHealthIds.signalSucculentSunnySide,
      PlantHealthIds.signalSucculentStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_fine_pest_compatible',
        labelEs: 'Plaga fina compatible (ácaros o trips)',
        type: 'pest_compatible',
        summaryEs:
            'El punteado puede venir de ácaros, trips o daño ambiental. Confirma '
            'organismos con lupa antes de aplicar cualquier producto.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentFineWebbing,
          PlantHealthIds.signalThripsPresent,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSucculentRaisedBlisters,
        },
      ),
      PlantHealthDiagnosis(
        id: 'succulent_environmental_marking_possible',
        labelEs: 'Marca ambiental o edema por descartar',
        type: 'visual_concern',
        summaryEs:
            'El edema, el polvo y una quemadura leve pueden parecerse a daño de '
            'plaga. Sin organismos, no se trata como plaga.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentRaisedBlisters,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay telaraña fina?',
      '¿Ves organismos móviles con lupa?',
      '¿El daño aparece primero en brotes nuevos o en hojas bajas?',
      '¿Hay raspado plateado o puntos negros?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Aísla temporalmente la planta.',
      'Confirma el insecto o el ácaro con lupa.',
      'Revisa las plantas vecinas.',
      'Evita remedios caseros sin probar antes en una zona pequeña.',
    ],
    disclaimerEs: _succulentDisclaimer,
    favorsVectorPressure: true,
  ),

  // ── SU-SYN-012 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_salt_fertilizer_injury_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Daño compatible con acumulación de sales',
    stages: _succulentStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSucculentSaltLeafBurn,
    strongSignals: <String>{
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalLeafEdgeBurn,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSucculentRecentSpray,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentSunnySide,
      PlantHealthIds.signalColdExposure,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_salt_accumulation_compatible',
        labelEs: 'Acumulación de sales compatible',
        type: 'condition_compatible',
        summaryEs:
            'Las sales por encima de lo conveniente dificultan que la raíz tome '
            'agua y queman puntas y bordes. No agregues fertilizante por ahora.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSalinityLoad,
          PlantHealthIds.signalLeafEdgeBurn,
        },
        contradictorySignalIds: <String>{PlantHealthIds.signalColdExposure},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay costra blanca en el sustrato o en la maceta?',
      '¿Se fertilizó hace poco?',
      '¿El daño aparece en puntas y bordes?',
      '¿La lectura de sales está alta?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'No agregues más fertilizante mientras las sales sigan altas.',
      'Revisa el drenaje, el agua de riego y cada cuánto fertilizas.',
      'Busca un análisis local si la tendencia persiste.',
    ],
    disclaimerEs: _succulentDisclaimer,
  ),

  // ── SU-SYN-013 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_phytotoxicity_spray_injury_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Mancha compatible con daño por producto aplicado',
    stages: _succulentStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSucculentChemicalSprayBurn,
    strongSignals: <String>{
      PlantHealthIds.signalSucculentRecentSpray,
      PlantHealthIds.signalSucculentDropletPattern,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSucculentSunnySide,
      PlantHealthIds.signalLeafEdgeBurn,
      PlantHealthIds.signalSucculentStable,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentProgressing,
      PlantHealthIds.signalSucculentCottonWaxInsects,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_phytotoxicity_compatible',
        labelEs: 'Daño compatible con producto aplicado',
        type: 'condition_compatible',
        summaryEs:
            'El patrón puede corresponder a una quemadura por producto, o por la '
            'combinación de producto y sol. Suspende nuevas aplicaciones hasta '
            'identificar la causa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentRecentSpray,
          PlantHealthIds.signalSucculentDropletPattern,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalSucculentProgressing,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Se aplicó algún producto en los últimos días?',
      '¿La mancha tiene forma de gotas o escurrimiento?',
      '¿La planta recibió sol después de aplicarlo?',
      '¿El daño dejó de avanzar?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Suspende nuevas aplicaciones hasta identificar la causa.',
      'Revisa la etiqueta del producto y su compatibilidad con la planta.',
      'No mezcles productos ni remedios caseros.',
      'Prueba cualquier aplicación futura en una zona pequeña y observa.',
    ],
    disclaimerEs: _succulentDisclaimer,
  ),

  // ── SU-SYN-014 ─────────────────────────────────────────────────────────────
  PlantHealthSyndrome(
    id: 'succulent_fungus_gnat_wet_media_01',
    cropId: CropCatalog.succulentCropId,
    labelEs: 'Mosquitas asociadas con sustrato húmedo',
    stages: _succulentStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomSucculentFungusGnatIndicator,
    strongSignals: <String>{
      PlantHealthIds.signalSucculentFungusGnats,
      PlantHealthIds.signalWaterlogging,
    },
    weakSignals: <String>{
      PlantHealthIds.signalSucculentSoftOrWatery,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalHumidWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalSucculentFirmDry,
      PlantHealthIds.signalSucculentStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'succulent_wet_media_indicator_compatible',
        labelEs: 'Indicador de sustrato húmedo',
        type: 'condition_compatible',
        summaryEs:
            'Estas mosquitas suelen aumentar cuando el sustrato permanece '
            'húmedo. Son una señal para revisar agua y drenaje, no una prueba de '
            'daño grave por sí solas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalSucculentFungusGnats,
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{PlantHealthIds.signalSucculentFirmDry},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Salen del sustrato al mover la maceta?',
      '¿El suelo permanece húmedo varios días?',
      '¿Hay materia vegetal en descomposición?',
      '¿La planta también muestra raíz o cuello alterado?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Revisa por qué el sustrato permanece húmedo.',
      'Mejora el drenaje y retira el material en descomposición.',
      'No atribuyas todo el deterioro a las mosquitas.',
      'Evalúa raíz y cuello si la planta también pierde vigor.',
    ],
    disclaimerEs: _succulentDisclaimer,
    favorsHighHumidity: true,
  ),
];
