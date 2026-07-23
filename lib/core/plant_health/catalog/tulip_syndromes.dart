import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

// Conjuntos de etapas del Tulipán (Doc C §6). El Tulipán es un bulbo estacional
// con reloj anual; sus diez etapas se traducen a los buckets compartidos del
// motor de sanidad sin crear una segunda taxonomía.
const Set<PlantHealthStageBucket> _senescenceStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _bulbSoftStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _basalRotStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _earlyRootStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
};

const Set<PlantHealthStageBucket> _rootZoneStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
};

const Set<PlantHealthStageBucket> _foliarBloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _vegBloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _stemBloomStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _storageStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _vegToRechargeStages =
    <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
};

const Set<PlantHealthStageBucket> _aphidStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _ethyleneStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
};

const Set<PlantHealthStageBucket> _edemaStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.vegetativeLate,
  PlantHealthStageBucket.reproductiveEarly,
};

const Set<PlantHealthStageBucket> _rechargeCutStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.reproductiveMid,
  PlantHealthStageBucket.grainFill,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _wildlifeStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.reproductiveMid,
};

const Set<PlantHealthStageBucket> _bulbMiteStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.reproductiveEarly,
  PlantHealthStageBucket.lateSeason,
};

const Set<PlantHealthStageBucket> _nematodeStages = <PlantHealthStageBucket>{
  PlantHealthStageBucket.seedling,
  PlantHealthStageBucket.vegetativeEarly,
  PlantHealthStageBucket.vegetativeMid,
  PlantHealthStageBucket.lateSeason,
};

/// Disclaimer obligatorio (Doc C §4.1) presente en cada síndrome de Tulipán.
const String _tulipDisclaimer =
    'BIO-G organiza observaciones y contexto para orientar la revisión. '
    'No confirma una enfermedad, una plaga ni un organismo causal.';

/// Catálogo visual prudente para Tulipán ornamental (`crop_tulip`, Doc C §9).
///
/// El catálogo se organiza por síndromes observables ("¿qué ves en tu
/// Tulipán?"), nunca por enfermedades. Los cuadros describen condiciones
/// compatibles y preguntas de confirmación. Ninguna lectura del dispositivo
/// confirma por sí sola un hongo, una bacteria, un virus, un ácaro, un nematodo,
/// una pudrición ni una deficiencia. Una señal de sensor aislada nunca produce
/// severidad alta: para high/critical debe existir una señal observada fuerte
/// (Doc C §4.2). Orden: P0 primero, P1 después, P2 al final (Doc C §13.4).
const List<PlantHealthSyndrome> tulipSyndromes = <PlantHealthSyndrome>[
  // ── P0 ───────────────────────────────────────────────────────────────
  // 1. Senescencia / dormancia normal (benigno imprescindible).
  PlantHealthSyndrome(
    id: 'tulip_natural_senescence_dormancy_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Amarillamiento o desaparición que puede ser normal',
    stages: _senescenceStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomTulipFoliageYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalTulipPostBloomTiming,
      PlantHealthIds.signalTulipGradualYellowing,
      PlantHealthIds.signalTulipTissueFirm,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipPrematureTiming,
      PlantHealthIds.signalTulipSoftOrWatery,
      PlantHealthIds.signalTulipAbnormalOdor,
      PlantHealthIds.signalTulipRapidProgression,
      PlantHealthIds.signalTulipGraySporulation,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_normal_senescence_compatible',
        labelEs: 'Senescencia natural compatible',
        type: 'benign_differential',
        summaryEs:
            'Después de la floración y la recarga, el follaje pierde color y '
            'desaparece. La parte aérea termina, pero el bulbo puede seguir vivo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipPostBloomTiming,
          PlantHealthIds.signalTulipGradualYellowing,
          PlantHealthIds.signalTulipTissueFirm,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipPrematureTiming,
          PlantHealthIds.signalTulipSoftOrWatery,
          PlantHealthIds.signalTulipAbnormalOdor,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_dormancy_compatible',
        labelEs: 'Dormancia del bulbo compatible',
        type: 'benign_differential',
        summaryEs:
            'La ausencia de brote o follaje al final del ciclo puede ser la '
            'etapa normal de reposo y no demuestra muerte.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipSoftOrWatery,
          PlantHealthIds.signalTulipRapidProgression,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La flor ya terminó y las hojas estuvieron verdes después?',
      '¿El amarillamiento avanza lentamente desde puntas o bordes?',
      '¿La base y el bulbo se sienten firmes, sin olor ni tejido acuoso?',
      '¿El calendario coloca a la planta en recarga, senescencia o dormancia?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'No cortes hojas que todavía conserven zonas verdes activas.',
      'Reduce el riego gradualmente conforme termina el follaje.',
      'Revisa solo si aparecen olor, tejido blando, moho o avance repentino.',
    ],
    disclaimerEs: _tulipDisclaimer,
  ),
  // 2. Bulbo blando, acuoso o con olor.
  PlantHealthSyndrome(
    id: 'tulip_bulb_soft_watery_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Bulbo blando, acuoso o con olor anormal',
    stages: _bulbSoftStages,
    organIds: <String>{
      PlantHealthIds.organBulb,
      PlantHealthIds.organBasalPlate,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomTulipBulbSoftWatery,
    strongSignals: <String>{
      PlantHealthIds.signalTulipSoftOrWatery,
      PlantHealthIds.signalTulipAbnormalOdor,
      PlantHealthIds.signalTulipRapidProgression,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalWaterSoakedSpots,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipTissueFirm,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_soft_rot_condition_compatible',
        labelEs: 'Condición compatible con pudrición blanda',
        type: 'condition_compatible',
        summaryEs:
            'Un bulbo blando, húmedo y con olor requiere revisión prioritaria. '
            'Entre los diferenciales están deterioros bacterianos, '
            'Pythium/Phytophthora y descomposición secundaria.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipSoftOrWatery,
          PlantHealthIds.signalTulipAbnormalOdor,
          PlantHealthIds.signalTulipRapidProgression,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_water_injury_anoxia_possible',
        labelEs: 'Daño por saturación o falta de aire posible',
        type: 'environmental_stress',
        summaryEs:
            'El exceso sostenido de agua puede deteriorar el bulbo y la raíz '
            'aunque no se identifique un organismo causal.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El bulbo cede al tacto o pierde su forma?',
      '¿Existe olor fuerte, agrio o desagradable?',
      '¿La base presenta zonas grises, cafés o acuosas?',
      '¿La maceta retuvo agua, quedó en un plato lleno o no drena?',
      '¿El deterioro aumentó desde la última revisión?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Evita volver a regar mientras el medio siga húmedo.',
      'Separa el ejemplar afectado de otros bulbos mientras lo revisas.',
      'Revisa drenaje, placa basal y raíces sin manipular innecesariamente tejido sano.',
      'Solicita evaluación local si el deterioro avanza o hay varios bulbos afectados.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsHighHumidity: true,
  ),
  // 3. Base seca / pudrición basal.
  PlantHealthSyndrome(
    id: 'tulip_basal_dry_rot_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Base seca, café o hundida con deterioro del bulbo',
    stages: _basalRotStages,
    organIds: <String>{
      PlantHealthIds.organBulb,
      PlantHealthIds.organBasalPlate,
      PlantHealthIds.organRoot,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomTulipBasalDryRot,
    strongSignals: <String>{
      PlantHealthIds.signalTulipBasalBrownRot,
      PlantHealthIds.signalTulipRootsAbsentOrRotted,
      PlantHealthIds.signalTulipSourOdor,
      PlantHealthIds.signalTulipPinkWhiteGrowth,
    },
    weakSignals: <String>{
      PlantHealthIds.signalTulipGum,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipTissueFirm,
      PlantHealthIds.signalTulipPostBloomTiming,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_fusarium_basal_rot_compatible',
        labelEs: 'Condición compatible con pudrición basal tipo Fusarium',
        scientificName: 'Fusarium spp.',
        type: 'condition_compatible',
        summaryEs:
            'La pudrición que inicia en la placa basal, raíces ausentes o '
            'deterioradas, amarillamiento desde puntas, aborto de botón y olor '
            'agrio forman un cuadro compatible, sin confirmar la especie.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipBasalBrownRot,
          PlantHealthIds.signalTulipRootsAbsentOrRotted,
          PlantHealthIds.signalTulipSourOdor,
          PlantHealthIds.signalTulipPinkWhiteGrowth,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_storage_or_wound_decay_possible',
        labelEs: 'Deterioro de almacenamiento o herida posible',
        type: 'visual_concern',
        summaryEs:
            'Golpes, cortes y almacenamiento desfavorable pueden abrir la '
            'puerta a deterioro basal o producir un aspecto parecido.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipGum,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La placa basal está café, hundida, seca o separándose?',
      '¿Las raíces están podridas, ausentes o se desprenden?',
      '¿Hay crecimiento blanco o rosado entre escamas?',
      '¿Las hojas amarillean o enrojecen desde las puntas antes de tiempo?',
      '¿El botón se secó o la planta quedó muy corta?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Separa bulbos con deterioro basal evidente.',
      'Evita mezclar material sospechoso con bulbos sanos durante almacenamiento.',
      'Revisa ventilación y retira fuentes visibles de deterioro.',
      'Busca confirmación de laboratorio o extensión si el problema afecta un lote.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsRecentStress: true,
  ),
  // 4. Emergencia deficiente o nula.
  PlantHealthSyndrome(
    id: 'tulip_poor_or_failed_emergence_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'El brote no sale o emerge muy débil',
    stages: _earlyRootStages,
    organIds: <String>{
      PlantHealthIds.organBulb,
      PlantHealthIds.organBasalPlate,
      PlantHealthIds.organRoot,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomPoorEmergence,
    strongSignals: <String>{
      PlantHealthIds.signalTulipShootRotBelowSoil,
      PlantHealthIds.signalTulipSoftOrWatery,
    },
    weakSignals: <String>{
      PlantHealthIds.signalInsufficientChill,
      PlantHealthIds.signalSalinityLoad,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipTissueFirm,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_emergence_failure_needs_confirmation',
        labelEs: 'Falla de emergencia por confirmar',
        type: 'visual_concern',
        summaryEs:
            'La falta de brote puede relacionarse con deterioro de bulbo o '
            'brote, frío incompleto, raíz insuficiente, compactación, sales, '
            'sequedad o calendario incorrecto.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipShootRotBelowSoil,
          PlantHealthIds.signalTulipSoftOrWatery,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_delayed_emergence_possible',
        labelEs: 'Emergencia retrasada posible',
        type: 'benign_differential',
        summaryEs:
            'Con temperaturas bajas o un ancla imprecisa el brote puede tardar '
            'sin que el bulbo esté muerto.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalInsufficientChill,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipShootRotBelowSoil,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La fecha y el perfil realmente superaron la ventana esperada?',
      '¿Existe punta viva bajo la superficie?',
      '¿El bulbo está firme y la placa basal conserva raíces?',
      '¿El suelo está compacto, saturado o extremadamente seco?',
      '¿El bulbo fue preenfriado o su historial de frío es desconocido?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'No des por muerto el bulbo solo por no verlo.',
      'Revisa primero fecha, frío, humedad y resistencia del medio.',
      'Inspecciona físicamente solo cuando la ventana se excedió claramente o hay olor/deterioro.',
      'Evita compensar el retraso con riegos repetidos.',
    ],
    disclaimerEs: _tulipDisclaimer,
  ),
  // 5. Raíces acuosas, cafés, cortas o quebradizas.
  PlantHealthSyndrome(
    id: 'tulip_glassy_brown_roots_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Raíces acuosas, cafés, cortas o quebradizas',
    stages: _rootZoneStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organBasalPlate,
      PlantHealthIds.organBulb,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomRootRotWilt,
    strongSignals: <String>{
      PlantHealthIds.signalTulipRootsGlassy,
      PlantHealthIds.signalTulipRootsBrown,
      PlantHealthIds.signalTulipRootsBreakEasily,
      PlantHealthIds.signalTulipRootRings,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalSalinityLoad,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipTissueFirm,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_pythium_root_rot_compatible',
        labelEs: 'Condición compatible con deterioro radicular tipo Pythium',
        scientificName: 'Pythium spp.',
        type: 'condition_compatible',
        summaryEs:
            'Raíces acuosas, cafés y frágiles, con crecimiento irregular o '
            'plantas cortas por zonas, forman un cuadro compatible con Pythium '
            'u otro deterioro de raíz.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipRootsGlassy,
          PlantHealthIds.signalTulipRootsBrown,
          PlantHealthIds.signalTulipRootsBreakEasily,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_root_suffocation_possible',
        labelEs: 'Asfixia o deterioro físico de raíz posible',
        type: 'environmental_stress',
        summaryEs:
            'Saturación, raíces comprimidas, falta de aire o acumulación salina '
            'pueden producir síntomas semejantes.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalSalinityLoad,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_other_root_fungi_possible',
        labelEs: 'Otro deterioro fúngico de raíz posible',
        type: 'condition_compatible',
        summaryEs:
            'Fusarium, Phytophthora, Rhizoctonia y otros organismos pueden '
            'solaparse visualmente.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipRootsBrown,
          PlantHealthIds.signalTulipRootRings,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las raíces se ven blancas y firmes o cafés y transparentes?',
      '¿Se rompen al tocarlas suavemente?',
      '¿Hay anillos cafés o zonas donde la raíz se marchita?',
      '¿Existe olor fuerte? Su ausencia no descarta deterioro radicular.',
      '¿El problema aparece en parches o en todo el contenedor?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Reduce el agua retenida y revisa la salida del contenedor.',
      'Evita dañar raíces sanas durante la inspección.',
      'Separa contenedores afectados si comparten agua recirculada.',
      'Solicita evaluación cuando el sistema radicular completo esté comprometido.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsHighHumidity: true,
  ),
  // 6. Tulip fire / moho gris.
  PlantHealthSyndrome(
    id: 'tulip_fire_gray_mold_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Manchas que avanzan, deformación o moho gris',
    stages: _foliarBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
      PlantHealthIds.organBulb,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomGrayMoldNecrosis,
    strongSignals: <String>{
      PlantHealthIds.signalTulipBrownWhiteSpots,
      PlantHealthIds.signalTulipGraySporulation,
      PlantHealthIds.signalTulipTwistedLeaves,
      PlantHealthIds.signalTulipBlackSclerotia,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalCoolDewyWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipGeneticPetalPattern,
      PlantHealthIds.signalTulipTissueFirm,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_botrytis_tulipae_compatible',
        labelEs: 'Condición compatible con tulip fire',
        scientificName: 'Botrytis tulipae',
        type: 'condition_compatible',
        summaryEs:
            'Manchas acuosas que se vuelven blancas o cafés, hojas torcidas, '
            'colapso y moho gris bajo humedad son compatibles con Botrytis '
            'tulipae.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipBrownWhiteSpots,
          PlantHealthIds.signalTulipGraySporulation,
          PlantHealthIds.signalTulipTwistedLeaves,
          PlantHealthIds.signalTulipBlackSclerotia,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipGeneticPetalPattern,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_botrytis_cinerea_possible',
        labelEs: 'Moho gris oportunista posible',
        scientificName: 'Botrytis cinerea',
        type: 'condition_compatible',
        summaryEs:
            'Botrytis cinerea puede colonizar tejido dañado o debilitado y '
            'producir moho gris y lesiones, sin ser necesariamente tulip fire.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipGraySporulation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_noninfectious_spot_possible',
        labelEs: 'Daño no infeccioso posible',
        type: 'benign_differential',
        summaryEs:
            'Granizo, helada, roce o quemadura pueden dejar manchas sin '
            'esporulación ni avance.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipGraySporulation,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las manchas crecen o se unen?',
      '¿En pétalos oscuros las marcas se ven claras y en pétalos blancos se ven cafés?',
      '¿Aparece polvo o moho gris en condiciones húmedas?',
      '¿Las hojas inferiores están torcidas o colapsadas?',
      '¿Hay puntos negros firmes en tejido muerto o escamas?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'Evita manipular plantas mojadas.',
      'Separa y retira tejido claramente colapsado sin sacudirlo sobre plantas sanas.',
      'Mejora ventilación y evita mojar repetidamente hojas y flores.',
      'Solicita evaluación si el cuadro avanza o aparece en varias plantas.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsHighHumidity: true,
    favorsCoolDewyWindow: true,
  ),
  // 7. Aborto de botón / no floración (multifactorial).
  PlantHealthSyndrome(
    id: 'tulip_bud_abortion_no_flower_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Solo hojas, botón seco o flor que no abre',
    stages: _vegBloomStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
      PlantHealthIds.organBulb,
    },
    primarySymptomId: PlantHealthIds.symptomFlowerAbortion,
    strongSignals: <String>{
      PlantHealthIds.signalTulipBudNecrosis,
    },
    weakSignals: <String>{
      PlantHealthIds.signalInsufficientChill,
      PlantHealthIds.signalTulipFruitStoredNearby,
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalRootsDarkRot,
      PlantHealthIds.signalDryHotWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipPostBloomTiming,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_flower_blast_compatible',
        labelEs: 'Condición compatible con aborto o desecación floral',
        type: 'physiological_disorder',
        summaryEs:
            'El botón puede secarse, quedar verde, no mostrar color o '
            'permanecer entre las hojas por una combinación de frío '
            'insuficiente, etileno, calor, humedad ambiental alta, déficit de '
            'agua, raíz asfixiada, tamaño de bulbo o enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipBudNecrosis,
          PlantHealthIds.signalInsufficientChill,
          PlantHealthIds.signalHeatStress,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipPostBloomTiming,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_nonflowering_weak_bulb_possible',
        labelEs: 'Bulbo sin suficiente capacidad floral posible',
        type: 'physiological_disorder',
        summaryEs:
            'Un bulbo pequeño, agotado o que no recargó puede producir hojas '
            'sin una flor funcional.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRootsDarkRot,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_delayed_flowering_possible',
        labelEs: 'Floración retrasada posible',
        type: 'benign_differential',
        summaryEs:
            'Un calendario impreciso o temperaturas bajas pueden retrasar sin '
            'abortar.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalInsufficientChill,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipBudNecrosis,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Existe botón visible o solo hojas?',
      '¿El botón está seco, negro, verde o detenido?',
      '¿Se cumplió el frío o el historial es desconocido?',
      '¿Hubo frutas maduras, humo, calefactor o bulbos con Fusarium durante almacenamiento?',
      '¿Las raíces están sanas y el sustrato conserva aire?',
      '¿La planta sufrió calor o déficit durante elongación?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'No aumentes fertilizante o riego como respuesta automática.',
      'Revisa historial de frío, raíz, humedad, temperatura y almacenamiento.',
      'Retira de un espacio cerrado bulbos claramente deteriorados.',
      'Registra el caso para ajustar el siguiente ciclo.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsRecentStress: true,
  ),
  // 8. Topple: caída fisiológica con zona acuosa.
  PlantHealthSyndrome(
    id: 'tulip_stem_leaf_topple_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Tallo u hoja con zona acuosa que se dobla',
    stages: _stemBloomStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomTulipStemTopple,
    strongSignals: <String>{
      PlantHealthIds.signalTulipDarkWateryStemZone,
      PlantHealthIds.signalTulipLeafSplitting,
      PlantHealthIds.signalTulipConstrictionBend,
      PlantHealthIds.signalTulipWaterDropletsFromTissue,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
      PlantHealthIds.signalRootsDarkRot,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipLeansTowardLight,
      PlantHealthIds.signalTulipThinPaleStem,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_topple_calcium_transport_compatible',
        labelEs:
            'Caída fisiológica compatible con transporte insuficiente de calcio',
        type: 'physiological_disorder',
        summaryEs:
            'Una zona verde oscura y acuosa que se contrae y dobla es '
            'compatible con topple. Suele relacionarse con rápido crecimiento, '
            'humedad ambiental alta, baja transpiración o raíces pobres.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipDarkWateryStemZone,
          PlantHealthIds.signalTulipConstrictionBend,
          PlantHealthIds.signalTulipWaterDropletsFromTissue,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipLeansTowardLight,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_mechanical_lodging_possible',
        labelEs: 'Doblez mecánico posible',
        type: 'benign_differential',
        summaryEs:
            'Viento, flor pesada, golpe o inclinación por luz pueden doblar el '
            'tallo sin lesión acuosa.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipLeansTowardLight,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipDarkWateryStemZone,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_stem_pathogen_possible',
        labelEs: 'Daño de tallo por otra causa posible',
        type: 'condition_compatible',
        summaryEs:
            'Lesiones progresivas, moho o necrosis irregular obligan a '
            'considerar enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipGraySporulation,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Existe una zona oscura, acuosa o estrecha donde se dobla?',
      '¿El tallo sigue unido o se quebró limpiamente?',
      '¿La hoja presenta grietas transversales o exuda agua?',
      '¿La humedad ambiental fue alta y el crecimiento muy rápido?',
      '¿Las raíces son escasas o están deterioradas?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Mejora circulación de aire sin exponer a corrientes violentas.',
      'Evita acelerar el crecimiento con calor o exceso de agua.',
      'Revisa salud radicular y estabilidad del medio.',
      'No declares deficiencia de calcio: BIO-G no la mide.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsHighHumidity: true,
  ),
  // 9. Amarillamiento prematuro / clorosis.
  PlantHealthSyndrome(
    id: 'tulip_premature_yellowing_chlorosis_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Hojas amarillas antes de terminar el ciclo',
    stages: _foliarBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organRoot,
      PlantHealthIds.organBulb,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomTulipFoliageYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalTulipPrematureTiming,
      PlantHealthIds.signalTulipInterveinalChlorosis,
    },
    weakSignals: <String>{
      PlantHealthIds.signalWaterlogging,
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalHighPhCalcareous,
      PlantHealthIds.signalSalinityLoad,
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalRootsDarkRot,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipPostBloomTiming,
      PlantHealthIds.signalTulipGradualYellowing,
      PlantHealthIds.signalTulipTissueFirm,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_root_stress_yellowing_possible',
        labelEs: 'Amarillamiento por estrés de raíz posible',
        type: 'environmental_stress',
        summaryEs:
            'Saturación, sequedad, raíz dañada, sales o placa basal deteriorada '
            'pueden amarillear la parte aérea antes de tiempo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalWaterlogging,
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalSalinityLoad,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipPostBloomTiming,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_iron_availability_chlorosis_possible',
        labelEs: 'Clorosis compatible con baja disponibilidad de hierro',
        type: 'nutrient_context',
        summaryEs:
            'Hojas amarillo-verdosas con venas más verdes, especialmente en '
            'condiciones frías, húmedas y pH alto, son compatibles con '
            'indisponibilidad de hierro; BIO-G no confirma deficiencia.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipInterveinalChlorosis,
          PlantHealthIds.signalHighPhCalcareous,
          PlantHealthIds.signalCoolDewyWindow,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_fusarium_or_other_disease_possible',
        labelEs: 'Deterioro basal o enfermedad posible',
        type: 'condition_compatible',
        summaryEs:
            'Amarillamiento desde puntas, enrojecimiento, aborto de botón, '
            'marchitez u olor aumentan la preocupación por Fusarium u otro '
            'deterioro.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalRootsDarkRot,
          PlantHealthIds.signalTulipAbnormalOdor,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipPostBloomTiming,
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_normal_senescence_possible',
        labelEs: 'Senescencia normal posible',
        type: 'benign_differential',
        summaryEs:
            'Si ocurre después de floración y recarga, puede ser la transición '
            'normal.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipPostBloomTiming,
          PlantHealthIds.signalTulipGradualYellowing,
          PlantHealthIds.signalTulipTissueFirm,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipPrematureTiming,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La flor ya terminó o el amarillamiento apareció antes del botón?',
      '¿Las venas permanecen verdes mientras el resto amarillea?',
      '¿El sustrato está saturado, muy seco, salino o compacto?',
      '¿La base está firme y las raíces son blancas?',
      '¿El cambio es gradual o repentino?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Confirma primero la etapa para no confundir senescencia con enfermedad.',
      'Revisa raíz, humedad, EC y pH antes de añadir fertilizante.',
      'Corrige el contexto físico del sustrato antes de interpretar nutrientes.',
      'Escala la revisión si hay olor, base blanda o marchitez rápida.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsHighHumidity: true,
  ),
  // ── P1 ───────────────────────────────────────────────────────────────
  // 10. Moho azul de almacenamiento.
  PlantHealthSyndrome(
    id: 'tulip_storage_blue_mold_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Moho azul verdoso en el bulbo almacenado',
    stages: _storageStages,
    organIds: <String>{
      PlantHealthIds.organBulb,
      PlantHealthIds.organBasalPlate,
    },
    primarySymptomId: PlantHealthIds.symptomTulipBlueGreenMold,
    strongSignals: <String>{
      PlantHealthIds.signalBlueGreenMold,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipTissueFirm,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_penicillium_blue_mold_compatible',
        labelEs: 'Condición compatible con moho azul de almacenamiento',
        scientificName: 'Penicillium spp.',
        type: 'condition_compatible',
        summaryEs:
            'El crecimiento azul verdoso sobre heridas o entre escamas es '
            'compatible con Penicillium, pero la importancia depende de si '
            'existe deterioro profundo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalBlueGreenMold,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_superficial_storage_mold_possible',
        labelEs: 'Moho superficial con daño limitado posible',
        type: 'benign_differential',
        summaryEs:
            'Una pequeña zona superficial sobre tejido firme no equivale '
            'automáticamente a pudrición interna.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipSoftOrWatery,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El moho está solo en la superficie o entra entre las escamas?',
      '¿Debajo del moho el tejido sigue firme y claro?',
      '¿El área crece o el bulbo pierde peso y firmeza?',
      '¿El bulbo fue golpeado, cortado o almacenado húmedo?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Mantén el bulbo seco, ventilado y separado mientras se revisa.',
      'No plantes material con deterioro profundo, olor o pérdida de firmeza.',
      'Evita desprender escamas sanas o provocar nuevas heridas.',
    ],
    disclaimerEs: _tulipDisclaimer,
  ),
  // 11. Deterioro del brote subterráneo (Rhizoctonia).
  PlantHealthSyndrome(
    id: 'tulip_subterranean_shoot_rot_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'El brote se deteriora debajo del suelo',
    stages: _earlyRootStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organBulb,
      PlantHealthIds.organRoot,
      PlantHealthIds.organBasalPlate,
    },
    primarySymptomId: PlantHealthIds.symptomTulipSubterraneanShootRot,
    strongSignals: <String>{
      PlantHealthIds.signalTulipShootRotBelowSoil,
      PlantHealthIds.signalTulipRootsStillIntact,
      PlantHealthIds.signalTulipBlackSclerotia,
    },
    weakSignals: <String>{
      PlantHealthIds.signalCoolDewyWindow,
      PlantHealthIds.signalWaterlogging,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipSoftOrWatery,
      PlantHealthIds.signalTulipRootsAbsentOrRotted,
      PlantHealthIds.signalTulipTissueFirm,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_rhizoctonia_shoot_rot_compatible',
        labelEs: 'Condición compatible con deterioro del brote tipo Rhizoctonia',
        scientificName: 'Rhizoctonia solani',
        type: 'condition_compatible',
        summaryEs:
            'Cuando las raíces permanecen relativamente intactas, pero el brote '
            'se pudre antes de salir, Rhizoctonia es un diferencial importante.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipShootRotBelowSoil,
          PlantHealthIds.signalTulipRootsStillIntact,
          PlantHealthIds.signalTulipBlackSclerotia,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipRootsAbsentOrRotted,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_mechanical_emergence_block_possible',
        labelEs: 'Bloqueo físico de emergencia posible',
        type: 'environmental_stress',
        summaryEs:
            'Costra, compactación, plantación excesivamente profunda o daño '
            'mecánico pueden impedir la salida sin reproducir todos los signos '
            'de Rhizoctonia.',
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipShootRotBelowSoil,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El bulbo desarrolló raíces, pero el brote está café o negro?',
      '¿Hay estructuras negras pequeñas o micelio cerca del brote?',
      '¿El sitio ha tenido Tulipanes repetidamente?',
      '¿El suelo está frío, húmedo y apretado?',
      '¿Otros bulbos cercanos fallaron de manera parecida?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Retira con cuidado material claramente deteriorado para no dispersarlo.',
      'Evita reutilizar sin revisión el mismo sustrato o contenedor.',
      'Revisa compactación y profundidad antes de atribuir el cuadro a una enfermedad.',
      'Busca apoyo local si aparece en múltiples plantas.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsCoolDewyWindow: true,
  ),
  // 12. Rompimiento viral / mosaico.
  PlantHealthSyndrome(
    id: 'tulip_viral_break_mosaic_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Rayas irregulares en flor y moteado en hojas',
    stages: _vegToRechargeStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomMosaicYellowing,
    strongSignals: <String>{
      PlantHealthIds.signalTulipIrregularColorBreak,
      PlantHealthIds.signalTulipLeafMottling,
      PlantHealthIds.signalTulipTwistedLeaves,
    },
    weakSignals: <String>{
      PlantHealthIds.signalAphidContamination,
      PlantHealthIds.signalVectorPresent,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipGeneticPetalPattern,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_virus_pattern_compatible',
        labelEs: 'Patrón compatible con alteración viral',
        type: 'condition_compatible',
        summaryEs:
            'Rayas nuevas e irregulares en pétalos junto con hojas moteadas, '
            'deformación o menor vigor forman un cuadro compatible con virus, '
            'pero requieren confirmación.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipIrregularColorBreak,
          PlantHealthIds.signalTulipLeafMottling,
          PlantHealthIds.signalTulipTwistedLeaves,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipGeneticPetalPattern,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_genetic_pattern_possible',
        labelEs: 'Patrón varietal o genético posible',
        type: 'benign_differential',
        summaryEs:
            'Muchos cultivares modernos tienen franjas, bordes, flecos o '
            'combinaciones de color estables que no son enfermedad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipGeneticPetalPattern,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipIrregularColorBreak,
          PlantHealthIds.signalTulipLeafMottling,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_environmental_color_change_possible',
        labelEs: 'Cambio de color por ambiente o maduración posible',
        type: 'benign_differential',
        summaryEs:
            'Temperatura, edad de la flor y variación del cultivar pueden '
            'modificar intensidad o distribución de color.',
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipLeafMottling,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El patrón ya aparecía en la etiqueta o fotografías del cultivar?',
      '¿Las rayas son simétricas y uniformes o nuevas e irregulares?',
      '¿Las hojas también muestran mosaico, rayas o deformación?',
      '¿La planta está más corta o débil que sus vecinas?',
      '¿Hay pulgones o varias plantas desarrollaron el mismo cambio?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Separa temporalmente la planta sospechosa mientras se confirma.',
      'No propagues ni compartas bulbos de una planta con patrón nuevo y pérdida de vigor.',
      'Revisa pulgones en hojas y brotes.',
      'Consulta un servicio de extensión o laboratorio antes de declarar un virus.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsVectorPressure: true,
  ),
  // 13. Pulgones / melaza.
  PlantHealthSyndrome(
    id: 'tulip_aphid_honeydew_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Pulgones, melaza o deformación de brotes',
    stages: _aphidStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomAphidColonies,
    strongSignals: <String>{
      PlantHealthIds.signalAphidContamination,
      PlantHealthIds.signalSootyMold,
      PlantHealthIds.signalTulipStickyHoneydew,
      PlantHealthIds.signalTulipVisibleAphids,
    },
    weakSignals: <String>{
      PlantHealthIds.signalTulipTwistedLeaves,
      PlantHealthIds.signalVectorPresent,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_aphid_feeding_compatible',
        labelEs: 'Daño compatible con pulgones',
        type: 'pest_compatible',
        summaryEs:
            'Colonias visibles, tejido pegajoso, fumagina y deformación son '
            'compatibles con pulgones.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipVisibleAphids,
          PlantHealthIds.signalTulipStickyHoneydew,
          PlantHealthIds.signalSootyMold,
          PlantHealthIds.signalAphidContamination,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_other_sap_feeder_possible',
        labelEs: 'Otro insecto chupador posible',
        type: 'pest_compatible',
        summaryEs:
            'Sin una observación clara, otros insectos pueden producir '
            'deformación o residuos.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipStickyHoneydew,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipVisibleAphids,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hay insectos pequeños agrupados en hojas, tallos o botón?',
      '¿La superficie se siente pegajosa?',
      '¿Existe recubrimiento negro superficial sobre la melaza?',
      '¿Los brotes nuevos están torcidos?',
      '¿Hay hormigas atendiendo colonias?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Aísla una planta con colonia abundante para reducir el movimiento de insectos.',
      'Revisa el envés de hojas, botón y unión de tallos.',
      'Evita mover pulgones a otras plantas durante la manipulación.',
      'Busca identificación local si la población aumenta.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsVectorPressure: true,
  ),
  // 14. Daño de almacenamiento compatible con etileno.
  PlantHealthSyndrome(
    id: 'tulip_ethylene_storage_damage_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Daño de almacenamiento compatible con etileno',
    stages: _ethyleneStages,
    organIds: <String>{
      PlantHealthIds.organBulb,
      PlantHealthIds.organRoot,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomTulipEthyleneDamage,
    strongSignals: <String>{
      PlantHealthIds.signalTulipGum,
      PlantHealthIds.signalTulipBudNecrosis,
      PlantHealthIds.signalTulipOpenShoot,
      PlantHealthIds.signalTulipPinkWhiteGrowth,
    },
    weakSignals: <String>{
      PlantHealthIds.signalTulipFruitStoredNearby,
      PlantHealthIds.signalRootsDarkRot,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipTissueFirm,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_ethylene_injury_compatible',
        labelEs: 'Condición compatible con exposición a etileno',
        type: 'physiological_disorder',
        summaryEs:
            'Formación de goma, botón necrótico, planta corta o delgada y raíz '
            'pobre después del almacenamiento son compatibles con etileno.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipGum,
          PlantHealthIds.signalTulipBudNecrosis,
          PlantHealthIds.signalTulipOpenShoot,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_fusarium_secondary_ethylene_possible',
        labelEs: 'Etileno procedente de bulbos deteriorados posible',
        type: 'condition_compatible',
        summaryEs:
            'Bulbos con Fusarium pueden liberar etileno y afectar ejemplares '
            'cercanos aunque estos no estén infectados.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipPinkWhiteGrowth,
          PlantHealthIds.signalTulipFruitStoredNearby,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_other_storage_disorder_possible',
        labelEs: 'Otro trastorno de almacenamiento posible',
        type: 'visual_concern',
        summaryEs:
            'Temperaturas incorrectas, deshidratación, golpe o enfriamiento '
            'fuera de etapa pueden producir fallas parecidas.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Los bulbos estuvieron junto a fruta madura, flores cortadas, humo o combustión?',
      '¿Había bulbos con olor agrio o Fusarium en el mismo espacio?',
      '¿Se formó goma clara o café entre escamas?',
      '¿El brote interno estaba abierto o el botón quedó negro?',
      '¿El problema afecta varios bulbos almacenados juntos?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.review24h,
    baseActionsEs: <String>[
      'Ventila y separa de inmediato las fuentes posibles de etileno.',
      'Retira bulbos deteriorados del espacio compartido.',
      'No guardes Tulipanes junto a frutas o verduras maduras.',
      'Registra duración, temperatura y condiciones del almacenamiento.',
    ],
    disclaimerEs: _tulipDisclaimer,
  ),
  // 15. Tallo débil, elongado o inclinado (sin lesión acuosa).
  PlantHealthSyndrome(
    id: 'tulip_weak_elongated_leaning_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Tallo largo, delgado o inclinado sin tejido acuoso',
    stages: _vegBloomStages,
    organIds: <String>{
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomTulipWeakElongatedStem,
    strongSignals: <String>{
      PlantHealthIds.signalTulipLeansTowardLight,
      PlantHealthIds.signalTulipThinPaleStem,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHeatStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipDarkWateryStemZone,
      PlantHealthIds.signalTulipBasalBrownRot,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_low_light_elongation_compatible',
        labelEs: 'Elongación por luz insuficiente compatible',
        type: 'environmental_stress',
        summaryEs:
            'Un tallo pálido que se inclina hacia la luz y carece de lesión '
            'acuosa es compatible con baja luminosidad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipLeansTowardLight,
          PlantHealthIds.signalTulipThinPaleStem,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipDarkWateryStemZone,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_heat_fast_growth_possible',
        labelEs: 'Crecimiento acelerado por calor posible',
        type: 'environmental_stress',
        summaryEs:
            'Temperatura alta durante la fase activa puede producir tallos '
            'menos firmes y floración más rápida.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHeatStress,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_heavy_flower_lodging_possible',
        labelEs: 'Peso de la flor o viento posible',
        type: 'physical_damage',
        summaryEs:
            'Flores dobles, parrot o premium pueden inclinar tallos sanos por '
            'peso, lluvia o viento.',
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipDarkWateryStemZone,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El tallo se inclina hacia una ventana o fuente de luz?',
      '¿Existe lesión acuosa o solo es delgado?',
      '¿La habitación o invernadero estuvo cálido?',
      '¿Las plantas están muy juntas?',
      '¿La flor es pesada o recibió lluvia/viento?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Aumenta luz útil de forma gradual y evita calor excesivo.',
      'Gira macetas decorativas con moderación para equilibrar la dirección de crecimiento.',
      'Separa plantas demasiado juntas para mejorar luz y aire.',
      'Usa soporte físico solo si es necesario y sin dañar el tallo.',
    ],
    disclaimerEs: _tulipDisclaimer,
  ),
  // 16. Daño por helada.
  PlantHealthSyndrome(
    id: 'tulip_frost_injury_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Tejido blanquecino, translúcido o colapsado después de frío',
    stages: _foliarBloomStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomColdInjury,
    strongSignals: <String>{
      PlantHealthIds.signalColdExposure,
      PlantHealthIds.signalTulipWhiteCollapsedTissue,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipGraySporulation,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_frost_injury_compatible',
        labelEs: 'Daño por helada compatible',
        type: 'environmental_stress',
        summaryEs:
            'Blanqueamiento, aspecto translúcido y colapso poco después de una '
            'helada son compatibles con daño por frío.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalColdExposure,
          PlantHealthIds.signalTulipWhiteCollapsedTissue,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipGraySporulation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_botrytis_after_injury_possible',
        labelEs: 'Colonización secundaria de tejido dañado posible',
        type: 'condition_compatible',
        summaryEs:
            'El tejido lesionado puede ser colonizado posteriormente; moho gris '
            'y avance tras el evento requieren otra revisión.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipGraySporulation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_other_physical_damage_possible',
        labelEs: 'Otro daño físico posible',
        type: 'physical_damage',
        summaryEs:
            'Granizo, roce o viento pueden producir lesiones localizadas.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo helada o temperatura extrema justo antes del cambio?',
      '¿El daño está en zonas más expuestas?',
      '¿El tejido se volvió blanco y colapsó sin moho al inicio?',
      '¿Aparecen después manchas activas o esporulación gris?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'No retires de inmediato todo el follaje que aún conserve tejido verde.',
      'Permite que el daño se delimite antes de evaluar cuánto tejido sigue funcional.',
      'Vigila moho secundario en tejido colapsado.',
      'Protege botones y flores de nuevos eventos extremos cuando sea posible.',
    ],
    disclaimerEs: _tulipDisclaimer,
  ),
  // 17. Calor / floración corta.
  PlantHealthSyndrome(
    id: 'tulip_heat_short_bloom_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'La flor abre y termina demasiado rápido',
    stages: _stemBloomStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomTulipShortBloom,
    strongSignals: <String>{
      PlantHealthIds.signalHeatStress,
      PlantHealthIds.signalTulipRapidOpening,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipGraySporulation,
      PlantHealthIds.signalTulipBudNecrosis,
      PlantHealthIds.signalTulipSoftOrWatery,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_heat_shortened_bloom_compatible',
        labelEs: 'Floración acortada por calor compatible',
        type: 'environmental_stress',
        summaryEs:
            'Una flor sana que abre con rapidez y pierde duración durante '
            'temperaturas altas es compatible con estrés térmico.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalHeatStress,
          PlantHealthIds.signalTulipRapidOpening,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipGraySporulation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_natural_end_of_bloom_possible',
        labelEs: 'Fin natural de la flor posible',
        type: 'benign_differential',
        summaryEs:
            'La flor del Tulipán tiene una ventana limitada; el calendario y el '
            'estado del pétalo ayudan a distinguir normalidad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipPostBloomTiming,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_disease_or_bud_damage_possible',
        labelEs: 'Daño sanitario o de botón posible',
        type: 'condition_compatible',
        summaryEs:
            'Manchas, moho, tejido acuoso o botón que nunca abrió no encajan '
            'con calor aislado.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipGraySporulation,
          PlantHealthIds.signalTulipBudNecrosis,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La flor abrió normalmente antes de terminar?',
      '¿Los pétalos están limpios o presentan manchas y moho?',
      '¿Hubo calor sostenido, calefacción o sol intenso sobre la maceta?',
      '¿La duración fue corta en varias plantas al mismo tiempo?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Mueve macetas de interior a un sitio luminoso y fresco, sin choque brusco.',
      'Evita fuentes directas de calefacción.',
      'No aumentes el riego por reflejo si el sustrato aún conserva humedad.',
      'Registra temperatura y duración para el siguiente ciclo.',
    ],
    disclaimerEs: _tulipDisclaimer,
  ),
  // 18. Daño salino / quemadura de raíz.
  PlantHealthSyndrome(
    id: 'tulip_salt_root_burn_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Raíces cortas, torcidas o cafés con sales elevadas',
    stages: _rootZoneStages,
    organIds: <String>{
      PlantHealthIds.organRoot,
      PlantHealthIds.organBasalPlate,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomTulipSaltRootBurn,
    strongSignals: <String>{
      PlantHealthIds.signalTulipRootsShortCrooked,
      PlantHealthIds.signalTulipDarkRootTips,
      PlantHealthIds.signalSalinityLoad,
    },
    weakSignals: <String>{
      PlantHealthIds.signalDryHotWindow,
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipRootsGlassy,
      PlantHealthIds.signalTulipAbnormalOdor,
      PlantHealthIds.signalTulipSoftOrWatery,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_salt_injury_compatible',
        labelEs: 'Daño salino compatible',
        type: 'environmental_stress',
        summaryEs:
            'Raíces cortas, torcidas, claras a cafés y puntas oscuras junto con '
            'EC alta son compatibles con daño salino.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipRootsShortCrooked,
          PlantHealthIds.signalTulipDarkRootTips,
          PlantHealthIds.signalSalinityLoad,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipRootsGlassy,
          PlantHealthIds.signalTulipAbnormalOdor,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_root_rot_possible',
        labelEs: 'Deterioro de raíz posible',
        type: 'condition_compatible',
        summaryEs:
            'Raíces acuosas, quebradizas, olor o bulbo blando aumentan la '
            'probabilidad de pudrición en vez de sales.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipRootsGlassy,
          PlantHealthIds.signalTulipAbnormalOdor,
          PlantHealthIds.signalTulipSoftOrWatery,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_low_ph_chemical_injury_possible',
        labelEs: 'Daño químico o pH extremo posible',
        type: 'environmental_stress',
        summaryEs:
            'Un medio muy ácido u otra exposición química también puede '
            'lesionar puntas.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipDarkRootTips,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿La EC subió después de fertilizar o dejar secar demasiado la maceta?',
      '¿Las raíces son firmes pero cortas y torcidas o son acuosas y se rompen?',
      '¿Las puntas están oscuras?',
      '¿Existe olor o deterioro del bulbo?',
      '¿El problema mejora al estabilizar el medio?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Detén aplicaciones adicionales de fertilizante mientras se revisa la EC.',
      'Verifica drenaje y calidad del agua.',
      'No intentes corregir con un gran volumen de agua si el contenedor no drena.',
      'Revisa nuevamente EC y raíz después de estabilizar el medio.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsRecentStress: true,
  ),
  // 19. Edema / desequilibrio de agua.
  PlantHealthSyndrome(
    id: 'tulip_edema_water_imbalance_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Tejido oscuro y acuoso o gotas sin pudrición evidente',
    stages: _edemaStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomTulipEdema,
    strongSignals: <String>{
      PlantHealthIds.signalTulipDarkWateryStemZone,
      PlantHealthIds.signalTulipWaterDropletsFromTissue,
      PlantHealthIds.signalTulipTissueFirm,
    },
    weakSignals: <String>{
      PlantHealthIds.signalHumidWindow,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipAbnormalOdor,
      PlantHealthIds.signalTulipGraySporulation,
      PlantHealthIds.signalTulipSoftOrWatery,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_edema_compatible',
        labelEs: 'Desequilibrio de agua y transpiración compatible',
        type: 'physiological_disorder',
        summaryEs:
            'El Tulipán puede absorber más agua de la que libera, generando '
            'tejido oscuro y acuoso o gotas sobre el brote.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipWaterDropletsFromTissue,
          PlantHealthIds.signalTulipTissueFirm,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipAbnormalOdor,
          PlantHealthIds.signalTulipGraySporulation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_topple_early_phase_possible',
        labelEs: 'Fase temprana de topple posible',
        type: 'physiological_disorder',
        summaryEs:
            'Si aparece constricción o doblez posterior, el cuadro puede '
            'evolucionar hacia topple.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipDarkWateryStemZone,
          PlantHealthIds.signalTulipConstrictionBend,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_soft_rot_possible',
        labelEs: 'Pudrición blanda posible',
        type: 'condition_compatible',
        summaryEs:
            'Olor, avance destructivo o bulbo blando contradicen un edema '
            'puramente fisiológico.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipAbnormalOdor,
          PlantHealthIds.signalTulipSoftOrWatery,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las gotas salen del tejido o son agua externa?',
      '¿Existe olor, moho o destrucción progresiva?',
      '¿La humedad ambiental es alta y el aire casi no circula?',
      '¿La planta crece muy rápido en un ambiente fresco y húmedo?',
      '¿Comienza a doblarse una zona del tallo u hoja?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Mejora el movimiento de aire y evita humedad ambiental excesiva.',
      'Evita saturar el medio durante periodos de baja transpiración.',
      'Vigila si aparece constricción, grieta, olor o deterioro.',
      'Escala a revisión sanitaria si el tejido se descompone.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsHighHumidity: true,
  ),
  // 20. Follaje retirado antes de terminar la recarga.
  PlantHealthSyndrome(
    id: 'tulip_foliage_cut_early_recharge_risk_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Follaje retirado antes de terminar la recarga',
    stages: _rechargeCutStages,
    organIds: <String>{
      PlantHealthIds.organLeaf,
      PlantHealthIds.organBulb,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomTulipFoliageRemovedEarly,
    strongSignals: <String>{
      PlantHealthIds.signalTulipLeavesCutGreen,
      PlantHealthIds.signalTulipPostBloomTiming,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipGradualYellowing,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_recharge_interrupted_compatible',
        labelEs: 'Recarga del bulbo interrumpida',
        type: 'management_risk',
        summaryEs:
            'Retirar hojas verdes reduce la oportunidad de transferir reservas '
            'al bulbo de reemplazo y puede debilitar el regreso del siguiente '
            'ciclo.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipLeavesCutGreen,
          PlantHealthIds.signalTulipPostBloomTiming,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipGradualYellowing,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_no_perennial_intent',
        labelEs: 'Sin intención de conservar el bulbo',
        type: 'benign_differential',
        summaryEs:
            'En un Tulipán forzado tratado como decoración de una temporada, el '
            'usuario puede decidir no conservarlo; la app debe explicarlo sin '
            'alarmar.',
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Las hojas estaban verdes cuando se cortaron?',
      '¿El usuario quiere conservar el bulbo para otro ciclo?',
      '¿La planta pasó por una etapa de hojas activas después de la flor?',
      '¿El perfil es forzado interior de una sola temporada?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Conserva el follaje verde cuando se busca que el bulbo recargue.',
      'Retira hojas cuando estén amarillas a cafés y ya no sean funcionales.',
      'Registra la interrupción como factor del próximo ciclo, no como enfermedad.',
    ],
    disclaimerEs: _tulipDisclaimer,
  ),
  // 21. Daño físico / meteorológico de pétalos.
  PlantHealthSyndrome(
    id: 'tulip_physical_weather_petal_damage_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Pétalos o tallos dañados por lluvia, viento o golpe',
    stages: _stemBloomStages,
    organIds: <String>{
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
    },
    primarySymptomId: PlantHealthIds.symptomTulipPhysicalDamage,
    strongSignals: <String>{
      PlantHealthIds.signalTulipChewedTissue,
    },
    weakSignals: <String>{
      PlantHealthIds.signalRecentStress,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipGraySporulation,
      PlantHealthIds.signalTulipBrownWhiteSpots,
      PlantHealthIds.signalTulipSoftOrWatery,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_weather_physical_damage_compatible',
        labelEs: 'Daño físico o meteorológico compatible',
        type: 'physical_damage',
        summaryEs:
            'Rasgaduras limpias, pétalos golpeados y doblez después de viento o '
            'lluvia son compatibles con daño físico.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipChewedTissue,
          PlantHealthIds.signalRecentStress,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipGraySporulation,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_botrytis_after_damage_possible',
        labelEs: 'Moho secundario sobre tejido lesionado posible',
        type: 'condition_compatible',
        summaryEs:
            'Las heridas pueden colonizarse si permanecen húmedas; manchas que '
            'avanzan o moho gris cambian la prioridad.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipGraySporulation,
          PlantHealthIds.signalTulipBrownWhiteSpots,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Hubo lluvia intensa, granizo, viento o manipulación?',
      '¿Las lesiones tienen bordes limpios o se expanden?',
      '¿Aparece moho gris después?',
      '¿La flor es doble, parrot, fringed o especialmente pesada?',
    ],
    severity: PlantHealthSeverity.low,
    urgency: PlantHealthUrgency.monitor72h,
    baseActionsEs: <String>[
      'Protege flores pesadas de lluvia y viento cuando sea posible.',
      'Retira solo tejido completamente roto o colapsado.',
      'Vigila humedad y moho secundario durante los días siguientes.',
    ],
    disclaimerEs: _tulipDisclaimer,
    favorsRecentStress: true,
  ),
  // 22. Fauna: bulbo excavado o follaje mordido.
  PlantHealthSyndrome(
    id: 'tulip_wildlife_feeding_excavation_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Bulbo excavado, desaparecido o follaje mordido',
    stages: _wildlifeStages,
    organIds: <String>{
      PlantHealthIds.organBulb,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organStem,
      PlantHealthIds.organFlower,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomFeedingHoles,
    strongSignals: <String>{
      PlantHealthIds.signalTulipBulbMissing,
      PlantHealthIds.signalTulipFreshExcavation,
      PlantHealthIds.signalTulipChewedTissue,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipSoftOrWatery,
      PlantHealthIds.signalTulipShootRotBelowSoil,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_rodent_or_squirrel_damage_compatible',
        labelEs: 'Daño de roedor o ardilla compatible',
        type: 'pest_compatible',
        summaryEs:
            'Suelo removido, bulbo faltante o mordido y fallas aisladas son '
            'compatibles con ardillas, ratones, topillos u otros animales.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipBulbMissing,
          PlantHealthIds.signalTulipFreshExcavation,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipSoftOrWatery,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_deer_rabbit_feeding_possible',
        labelEs: 'Consumo de follaje o botón por fauna posible',
        type: 'pest_compatible',
        summaryEs:
            'Cortes o mordidas en brotes y flores pueden corresponder a '
            'venados, conejos u otros herbívoros.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipChewedTissue,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_slug_snail_feeding_possible',
        labelEs: 'Daño de babosa o caracol posible',
        type: 'pest_compatible',
        summaryEs:
            'Agujeros irregulares, bordes raspados y rastros de baba favorecen '
            'este diferencial.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipChewedTissue,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_nonemergence_other_cause_possible',
        labelEs: 'Falla de emergencia por otra causa posible',
        type: 'visual_concern',
        summaryEs:
            'Si el bulbo sigue presente, la causa puede ser frío, pudrición, '
            'brote dañado o calendario.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipShootRotBelowSoil,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipBulbMissing,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿El bulbo está ausente o solo no emergió?',
      '¿Hay suelo recién removido, túneles, huellas o excremento?',
      '¿El tejido presenta mordidas o cortes limpios?',
      '¿Existen rastros de baba?',
      '¿El daño ocurre en plantas aisladas o uniformemente en todo el lote?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Confirma primero que el bulbo realmente falta.',
      'Protege físicamente el área sin bloquear la emergencia.',
      'Evita venenos o métodos peligrosos dentro de la recomendación automática de BIO-G.',
      'Consulta control local de fauna cuando el daño sea recurrente.',
    ],
    disclaimerEs: _tulipDisclaimer,
  ),
  // ── P2 ───────────────────────────────────────────────────────────────
  // 23. Ácaros de bulbo.
  PlantHealthSyndrome(
    id: 'tulip_bulb_mite_damage_01',
    cropId: CropCatalog.tulipCropId,
    labelEs: 'Bulbo con cicatrices finas o daño interno de botón',
    stages: _bulbMiteStages,
    organIds: <String>{
      PlantHealthIds.organBulb,
      PlantHealthIds.organBasalPlate,
      PlantHealthIds.organFlower,
      PlantHealthIds.organStem,
    },
    primarySymptomId: PlantHealthIds.symptomBulbMiteScars,
    strongSignals: <String>{
      PlantHealthIds.signalBulbMiteBrownScars,
      PlantHealthIds.signalTulipBudNecrosis,
      PlantHealthIds.signalTulipOpenShoot,
    },
    weakSignals: <String>{
      PlantHealthIds.signalTulipPinkWhiteGrowth,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipTissueFirm,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_bulb_mite_damage_compatible',
        labelEs: 'Daño compatible con ácaros de bulbo',
        type: 'pest_compatible',
        summaryEs:
            'Ácaros pueden aprovechar tejido dañado y, en ciertos cuadros, '
            'lesionar estructuras internas y botón.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalBulbMiteBrownScars,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_secondary_decay_possible',
        labelEs: 'Deterioro secundario de tejido dañado posible',
        type: 'condition_compatible',
        summaryEs:
            'Los ácaros suelen coexistir con heridas, mohos o pudriciones; '
            'encontrar daño no demuestra que sean la causa primaria.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipPinkWhiteGrowth,
          PlantHealthIds.signalTulipBudNecrosis,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Se observan organismos diminutos con lupa en escamas o base?',
      '¿Hay cicatrices cafés finas o tejido desmenuzado?',
      '¿El brote interno quedó abierto o el botón se volvió negro?',
      '¿El bulbo ya presentaba Fusarium, heridas o moho?',
    ],
    severity: PlantHealthSeverity.medium,
    urgency: PlantHealthUrgency.review48h,
    baseActionsEs: <String>[
      'Separa bulbos dañados durante almacenamiento.',
      'Evita conservar material con pudrición activa junto a bulbos sanos.',
      'Solicita identificación porque los ácaros pueden ser difíciles de confirmar a simple vista.',
    ],
    disclaimerEs: _tulipDisclaimer,
  ),
  // 24. Nematodo de tallo y bulbo (cautela / posible cuarentena).
  PlantHealthSyndrome(
    id: 'tulip_stem_bulb_nematode_01',
    cropId: CropCatalog.tulipCropId,
    labelEs:
        'Bulbo con anillos cafés, escamas alteradas o crecimiento deformado',
    stages: _nematodeStages,
    organIds: <String>{
      PlantHealthIds.organBulb,
      PlantHealthIds.organBasalPlate,
      PlantHealthIds.organStem,
      PlantHealthIds.organLeaf,
      PlantHealthIds.organWholePlant,
    },
    primarySymptomId: PlantHealthIds.symptomTulipBulbRingsDistortion,
    strongSignals: <String>{
      PlantHealthIds.signalTulipBrownConcentricRings,
      PlantHealthIds.signalTulipTwistedLeaves,
    },
    weakSignals: <String>{
      PlantHealthIds.signalTulipSoftOrWatery,
    },
    conflictingSignals: <String>{
      PlantHealthIds.signalTulipTissueFirm,
    },
    probableDiagnoses: <PlantHealthDiagnosis>[
      PlantHealthDiagnosis(
        id: 'tulip_ditylenchus_compatible',
        labelEs: 'Condición compatible con nematodo de tallo y bulbo',
        scientificName: 'Ditylenchus dipsaci',
        type: 'condition_compatible',
        summaryEs:
            'Anillos o bandas decoloradas dentro del bulbo, escamas alteradas y '
            'crecimiento deformado son compatibles con Ditylenchus, pero '
            'requieren laboratorio.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipBrownConcentricRings,
          PlantHealthIds.signalTulipTwistedLeaves,
        },
        contradictorySignalIds: <String>{
          PlantHealthIds.signalTulipTissueFirm,
        },
      ),
      PlantHealthDiagnosis(
        id: 'tulip_other_bulb_decay_possible',
        labelEs: 'Otro deterioro del bulbo posible',
        type: 'condition_compatible',
        summaryEs:
            'Fusarium, bacterias, daño físico y almacenamiento pueden producir '
            'decoloración parecida.',
        confirmatorySignalIds: <String>{
          PlantHealthIds.signalTulipSoftOrWatery,
        },
      ),
    ],
    confirmationChecksEs: <String>[
      '¿Un corte transversal muestra anillos o bandas internas?',
      '¿Varias plantas del mismo lote están deformadas o pequeñas?',
      '¿La decoloración sigue una herida puntual o aparece en varias escamas?',
      '¿El material proviene de un lote nuevo o de suelo usado repetidamente?',
    ],
    severity: PlantHealthSeverity.high,
    urgency: PlantHealthUrgency.sameDay,
    baseActionsEs: <String>[
      'No propagues ni redistribuyas material sospechoso.',
      'Separa el lote y evita mover suelo o restos a otras áreas.',
      'Solicita diagnóstico de laboratorio o autoridad fitosanitaria local.',
    ],
    disclaimerEs: _tulipDisclaimer,
  ),
];
