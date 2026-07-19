import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

const Set<PlantHealthStageBucket> _cactusStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.lateSeason,
};

const String _cactusDisclaimer =
    'BIO-G organiza observaciones y contexto para orientar la revisión. '
    'No confirma una enfermedad, una plaga ni un organismo causal.';

/// Catálogo visual prudente para Cactus ornamental.
///
/// Los cuadros describen condiciones compatibles y preguntas de confirmación.
/// Las lecturas del dispositivo aportan contexto, pero nunca diagnostican por
/// sí solas una enfermedad o una plaga.
const List<PlantHealthSyndrome> cactusSyndromes = <PlantHealthSyndrome>[
  PlantHealthSyndrome(
    id: 'cactus_root_collar_condition_01',
    cropId: CropCatalog.cactusCropId,
    labelEs: 'Base o raíz con deterioro por confirmar',
    stages: _cactusStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomCactusRootCollarDeterioration,
    strongSignals: <String>{
      PlantHealthIds.signalCactusSoftOrWatery,
      PlantHealthIds.signalCactusProgressing,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalCactusAbnormalOdor,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalCactusFirmDry,
      PlantHealthIds.signalCactusStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cactus_root_collar_deterioration_compatible',
        labelEs: 'Condición compatible con deterioro de raíz o cuello',
        type: 'condition_compatible',
        summaryEs:
            'Una base o raíz alterada necesita contexto de humedad, firmeza '
            'y progresión. Estos datos no identifican un patógeno.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalCactusSoftOrWatery,
          PlantHealthIds.signalCactusProgressing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalCactusFirmDry,
          PlantHealthIds.signalCactusStable,
        },
      ),
      PlantHealthDiagnosis(
        id: 'cactus_root_establishment_stress_possible',
        labelEs: 'Estrés de establecimiento o anclaje por confirmar',
        type: 'visual_concern',
        summaryEs:
            'Trasplante, plantación profunda, herida o anclaje insuficiente '
            'pueden producir un cuadro parecido sin identificar enfermedad.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalRecentStress},
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La base está firme, blanda, hundida o húmeda al tacto?',
      '¿El cambio avanza entre revisiones?',
      '¿La zona radicular permanece húmeda o hubo riego repetido?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Revisa que el agua salga bien y que el sustrato no se quede empapado.',
      'Evita un nuevo riego mientras la zona siga húmeda.',
      'Busca evaluación local si la base pierde firmeza, soporte o sigue avanzando.',
    ],
    disclaimerEs: _cactusDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cactus_soft_water_soaked_tissue_01',
    cropId: CropCatalog.cactusCropId,
    labelEs: 'Tejido blando, acuoso o hundido',
    stages: _cactusStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomCactusSoftWaterSoakedTissue,
    strongSignals: <String>{
      PlantHealthIds.signalCactusSoftOrWatery,
      PlantHealthIds.signalCactusProgressing,
      PlantHealthIds.signalCactusDarkExudate,
      PlantHealthIds.signalCactusLossOfSupport,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalCactusAbnormalOdor,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalCactusFirmDry,
      PlantHealthIds.signalCactusStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cactus_internal_tissue_damage_compatible',
        labelEs: 'Condición compatible con daño interno serio',
        type: 'condition_compatible',
        summaryEs:
            'El tejido blando o acuoso progresivo requiere revisión '
            'prioritaria, sin que BIO-G pueda confirmar la causa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalCactusProgressing,
          PlantHealthIds.signalCactusDarkExudate,
          PlantHealthIds.signalCactusLossOfSupport,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalCactusFirmDry,
          PlantHealthIds.signalCactusStable,
        },
      ),
      PlantHealthDiagnosis(
        id: 'cactus_cold_or_wound_damage_compatible',
        labelEs: 'Daño por frío o herida por confirmar',
        type: 'visual_concern',
        summaryEs:
            'Una herida o helada reciente también puede volver el tejido '
            'blando; importa confirmar el evento y la progresión.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalRecentStress,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La zona cede al tacto o se siente acuosa?',
      '¿Hay líquido oscuro, olor anormal o pérdida de soporte?',
      '¿La zona aumenta rápido?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Aísla temporalmente la planta de otras.',
      'Evita mojar la zona o volver a regar mientras el sustrato siga húmedo.',
      'Busca evaluación local si la zona crece o la planta pierde soporte.',
    ],
    disclaimerEs: _cactusDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cactus_dark_lesion_or_exudate_01',
    cropId: CropCatalog.cactusCropId,
    labelEs: 'Lesión oscura, hundida o con exudado',
    stages: _cactusStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomDarkSunkenLesions,
    strongSignals: <String>{
      PlantHealthIds.signalCactusDarkExudate,
      PlantHealthIds.signalCactusProgressing,
      PlantHealthIds.signalCactusSoftOrWatery,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalCactusFirmDry,
      PlantHealthIds.signalCactusStable,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cactus_dark_lesion_needs_confirmation',
        labelEs: 'Daño de tejido por confirmar',
        type: 'visual_concern',
        summaryEs:
            'El color oscuro por sí solo no distingue herida, cicatriz, '
            'quemadura u otra condición. Importan humedad, firmeza y avance.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalCactusDarkExudate,
          PlantHealthIds.signalCactusProgressing,
          PlantHealthIds.signalCactusSoftOrWatery,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalCactusFirmDry,
          PlantHealthIds.signalCactusStable,
        },
      ),
      PlantHealthDiagnosis(
        id: 'cactus_dry_wound_or_scar_possible',
        labelEs: 'Herida seca o cicatriz posible',
        type: 'benign_differential',
        summaryEs:
            'Una herida puede oscurecerse mientras cicatriza. Firmeza, '
            'sequedad y estabilidad reducen la preocupación.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalCactusFirmDry,
          PlantHealthIds.signalCactusStable,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalCactusSoftOrWatery,
          PlantHealthIds.signalCactusProgressing,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La mancha está seca y firme o húmeda y blanda?',
      '¿Hay líquido, olor o puntos visibles?',
      '¿La lesión crece entre revisiones?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Registra la zona y compárala en la siguiente revisión.',
      'Mantén vigilada cualquier herida para confirmar que seque y no avance.',
      'Solicita revisión local si aparece tejido blando, exudado o progresión.',
    ],
    disclaimerEs: _cactusDisclaimer,
    favorsHighHumidity: true,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cactus_natural_corking_possible_01',
    cropId: CropCatalog.cactusCropId,
    labelEs: 'Zona seca y firme que puede ser corchado o cicatriz',
    stages: _cactusStages,
    organIds: <String>{PlantHealthIds.organStem, PlantHealthIds.organCrown},
    primarySymptomId: PlantHealthIds.symptomCactusDryFirmCorking,
    strongSignals: <String>{
      PlantHealthIds.signalCactusFirmDry,
      PlantHealthIds.signalCactusStable,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalCactusSoftOrWatery,
      PlantHealthIds.signalCactusProgressing,
      PlantHealthIds.signalCactusDarkExudate,
      PlantHealthIds.signalCactusAbnormalOdor,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cactus_corking_or_scar_possible',
        labelEs: 'Corchado o cicatriz posible',
        type: 'benign_differential',
        summaryEs:
            'Una zona marrón o beige, seca, firme y estable puede ser corchado '
            'o una cicatriz; debe vigilarse sin confundirla con tejido blando.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalCactusFirmDry,
          PlantHealthIds.signalCactusStable,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalCactusSoftOrWatery,
          PlantHealthIds.signalCactusProgressing,
          PlantHealthIds.signalCactusDarkExudate,
        },
      ),
      PlantHealthDiagnosis(
        id: 'cactus_active_tissue_change_needs_review',
        labelEs: 'Cambio activo de tejido por descartar',
        type: 'visual_concern',
        summaryEs:
            'Si la zona se ablanda, humedece o aumenta, deja de comportarse '
            'como un corchado estable y necesita nueva revisión.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalCactusSoftOrWatery,
          PlantHealthIds.signalCactusProgressing,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalCactusFirmDry,
          PlantHealthIds.signalCactusStable,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La zona está dura, seca o corchosa?',
      '¿Permanece estable sin humedad ni hundimiento?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Vigila si cambia de tamaño, se ablanda o aparece humedad.',
      'Conserva el registro como cicatriz posible mientras permanezca firme y estable.',
    ],
    disclaimerEs: _cactusDisclaimer,
  ),
  PlantHealthSyndrome(
    id: 'cactus_wrinkling_turgor_loss_01',
    cropId: CropCatalog.cactusCropId,
    labelEs: 'Arrugas o pérdida de turgor',
    stages: _cactusStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomCactusWrinklingTurgorLoss,
    strongSignals: <String>{PlantHealthIds.signalCactusWrinkling},
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{PlantHealthIds.signalCactusSoftOrWatery},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cactus_turgor_loss_needs_hydric_review',
        labelEs: 'Pérdida de turgor con causa aún incierta',
        type: 'hydric_observation',
        summaryEs:
            'La apariencia no distingue por sí sola sequedad, raíz no '
            'funcional, trasplante, calor o reposo.',
      ),
      PlantHealthDiagnosis(
        id: 'cactus_root_function_needs_review',
        labelEs: 'Función radicular por revisar',
        type: 'hydric_observation',
        summaryEs:
            'Una raíz dañada por exceso de agua previo puede hacer que la '
            'planta se vea seca. Revisa la humedad antes de volver a regar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalRecentStress,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La planta perdió volumen o contrajo sus costillas?',
      '¿El sustrato lleva mucho tiempo seco, o al revés, húmedo?',
      '¿Hubo trasplante, calor o un exceso de agua previo?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Revisa la humedad del sustrato antes de decidir si riegas.',
      'No riegues solo por la apariencia de la planta.',
    ],
    disclaimerEs: _cactusDisclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cactus_mealybug_scale_suspected_01',
    cropId: CropCatalog.cactusCropId,
    labelEs: 'Material algodonoso, ceroso o escamas por confirmar',
    stages: _cactusStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organRoot,
    },
    primarySymptomId: PlantHealthIds.symptomCactusWhiteCottonyMaterial,
    strongSignals: <String>{PlantHealthIds.signalCactusCottonWaxScale},
    weakSignals: <String>{PlantHealthIds.signalRecentStress},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cactus_sucking_insects_suspected',
        labelEs: 'Insectos chupadores por confirmar',
        type: 'pest_suspected',
        summaryEs:
            'Algodón, cera o escamas pueden ser compatibles con una plaga, '
            'pero requieren confirmar cuerpos o insectos visibles.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalCactusCottonWaxScale,
        },
      ),
      PlantHealthDiagnosis(
        id: 'cactus_surface_residue_needs_confirmation',
        labelEs: 'Residuo superficial por descartar',
        type: 'visual_concern',
        summaryEs:
            'El material blanco debe inspeccionarse de cerca: sin cuerpos, '
            'escamas o insectos visibles la sospecha permanece abierta.',
        contradictorySignalIds: <String>{
          PlantHealthIds.signalCactusCottonWaxScale,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Se distinguen cuerpos, escamas o material ceroso en areolas y uniones?',
      '¿Hay material pegajoso o insectos visibles?',
      '¿La misma señal aparece en base o raíz durante una inspección segura?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Separa temporalmente la planta y revisa areolas, uniones y base.',
      'Confirma la presencia del insecto antes de tratar.',
      'Si se confirma, sigue la etiqueta aplicable o consulta a un especialista; BIO-G no indica productos ni dosis.',
    ],
    disclaimerEs: _cactusDisclaimer,
  ),
  PlantHealthSyndrome(
    id: 'cactus_spider_mite_suspected_01',
    cropId: CropCatalog.cactusCropId,
    labelEs: 'Punteado, bronceado o telaraña fina',
    stages: _cactusStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomBronzingStippling,
    strongSignals: <String>{PlantHealthIds.signalCactusFineWebbing},
    weakSignals: <String>{PlantHealthIds.signalDryHotWindow},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cactus_mites_suspected',
        labelEs: 'Ácaros por confirmar',
        type: 'pest_suspected',
        summaryEs:
            'El punteado y la telaraña fina pueden ser compatibles con ácaros, '
            'pero también con polvo, cicatriz, quemadura o daño mecánico.',
        confirmatorySignalIds: <String>{PlantHealthIds.signalCactusFineWebbing},
      ),
      PlantHealthDiagnosis(
        id: 'cactus_surface_damage_or_dust_possible',
        labelEs: 'Polvo, cicatriz o daño superficial por descartar',
        type: 'visual_concern',
        summaryEs:
            'Sin organismos o telaraña fina confirmados, el punteado no '
            'permite concluir que exista una plaga.',
        contradictorySignalIds: <String>{
          PlantHealthIds.signalCactusFineWebbing,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay telaraña muy fina o pequeños organismos visibles con lupa?',
      '¿El punteado aumenta y no corresponde a polvo o cicatriz?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Aísla temporalmente la planta si observas organismos o telaraña.',
      'Confirma con lupa antes de tratar.',
      'No apliques un producto basándote solo en el punteado.',
    ],
    disclaimerEs: _cactusDisclaimer,
  ),
  PlantHealthSyndrome(
    id: 'cactus_sunburn_acclimation_01',
    cropId: CropCatalog.cactusCropId,
    labelEs: 'Daño compatible con cambio brusco de sol',
    stages: _cactusStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomCactusSunburnPatch,
    strongSignals: <String>{
      PlantHealthIds.signalCactusSunnySide,
      PlantHealthIds.signalCactusChangedSunExposure,
      PlantHealthIds.signalHeatStress,
    },
    weakSignals: <String>{PlantHealthIds.signalDryHotWindow},
    conflictingSignals: <String>{PlantHealthIds.signalCactusSoftOrWatery},
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cactus_sun_exposure_damage_compatible',
        labelEs: 'Daño por exposición solar compatible',
        type: 'abiotic_condition_compatible',
        summaryEs:
            'Una zona firme y seca orientada al sol tras un cambio de '
            'exposición puede ser quemadura, sin descartar otras causas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalCactusSunnySide,
          PlantHealthIds.signalCactusChangedSunExposure,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalCactusSoftOrWatery,
        },
      ),
      PlantHealthDiagnosis(
        id: 'cactus_wound_or_corking_differential',
        labelEs: 'Herida o corchado por descartar',
        type: 'benign_differential',
        summaryEs:
            'Una cicatriz o corchado antiguo puede parecer quemadura; la '
            'orientación al sol y el cambio de exposición ayudan a distinguir.',
        contradictorySignalIds: <String>{
          PlantHealthIds.signalCactusSunnySide,
          PlantHealthIds.signalCactusChangedSunExposure,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La zona afectada está del lado soleado?',
      '¿Hubo cambio reciente de orientación o exposición?',
      '¿El tejido está firme y seco o blando y húmedo?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Evita otro cambio brusco de exposición.',
      'Vigila firmeza, humedad y progresión de la zona.',
      'Haz cualquier ajuste de luz de forma gradual.',
    ],
    disclaimerEs: _cactusDisclaimer,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cactus_freeze_injury_01',
    cropId: CropCatalog.cactusCropId,
    labelEs: 'Cambio de tejido después de frío o helada',
    stages: _cactusStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomCactusColdTissueChange,
    strongSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalFrostEvent,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCactusSoftOrWatery,
      PlantHealthIds.signalCactusProgressing,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cactus_cold_damage_compatible',
        labelEs: 'Daño por frío compatible',
        type: 'abiotic_condition_compatible',
        summaryEs:
            'El daño por frío puede aparecer días o semanas después. '
            'La observación no permite asumir tolerancia ni recuperación.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalFrostEvent,
        },
      ),
      PlantHealthDiagnosis(
        id: 'cactus_other_tissue_stress_possible',
        labelEs: 'Otro estrés de tejido por descartar',
        type: 'visual_concern',
        summaryEs:
            'Humedad persistente, herida u otro cambio ambiental pueden '
            'parecer daño por frío si el evento no está confirmado.',
        contradictorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalFrostEvent,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo noche fría o helada reciente?',
      '¿Cambiaron color, firmeza o estabilidad después del evento?',
      '¿La zona sigue progresando?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Vigila color, firmeza y estabilidad durante los días siguientes.',
      'Evita nuevo riego si el sustrato sigue húmedo.',
      'Busca evaluación local si el tejido se ablanda o pierde soporte.',
    ],
    disclaimerEs: _cactusDisclaimer,
    favorsCoolDewyWindow: true,
    favorsRecentStress: true,
  ),
  PlantHealthSyndrome(
    id: 'cactus_localized_collapse_leaning_01',
    cropId: CropCatalog.cactusCropId,
    labelEs: 'Inclinación nueva o pérdida de soporte',
    stages: _cactusStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organCrown,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomCactusLeaningCollapse,
    strongSignals: <String>{
      PlantHealthIds.signalCactusNewLeaning,
      PlantHealthIds.signalCactusLossOfSupport,
      PlantHealthIds.signalCactusSoftOrWatery,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalRecentStress,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'cactus_structural_instability',
        labelEs: 'Inestabilidad estructural que requiere revisión',
        type: 'safety_concern',
        summaryEs:
            'La inclinación puede relacionarse con luz, anclaje, suelo, '
            'viento o daño interno. No debe asumirse una sola causa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalCactusNewLeaning,
          PlantHealthIds.signalCactusLossOfSupport,
        },
      ),
      PlantHealthDiagnosis(
        id: 'cactus_light_wind_or_anchor_change_possible',
        labelEs: 'Cambio de luz, viento o anclaje por confirmar',
        type: 'safety_concern',
        summaryEs:
            'El crecimiento hacia la luz, viento o suelo flojo también pueden '
            'inclinar la planta; primero debe conservarse la seguridad.',
        contradictorySignalIds: <String>{
          PlantHealthIds.signalCactusSoftOrWatery,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La inclinación es nueva o aumenta?',
      '¿La base está firme o blanda?',
      '¿Hay viento, suelo flojo o un trasplante reciente?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Revisa base y anclaje sin colocarte en la dirección de una posible caída.',
      'Si es un cactus grande o inestable, mantén distancia y solicita apoyo profesional.',
    ],
    disclaimerEs: _cactusDisclaimer,
    favorsRecentStress: true,
  ),
];
