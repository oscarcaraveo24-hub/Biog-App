/// Rendimiento aproximado del Limón (doc 03 oficial).
///
/// Reglas no negociables:
/// - El rendimiento del limón NO se calcula como cultivo anual ni desde
///   `sowingDate`: se estima por kg de limón fresco/arbol + arboles/ha + estado
///   productivo + perfil LM + densidad + manejo + riego + floracion/cuajado +
///   carga + memoria de estres + confianza (doc 03 §0.5, §13).
/// - Es APROXIMADO y en rango (bajo / esperado / alto). Nunca es promesa.
/// - Estados no productivos y etapas de establecimiento proyectan 0.
/// - `post_harvest` NO cierra el cultivo ni borra historial (doc 03 §0.5).
/// - La salida principal es kg de limón fresco/arbol y t/ha, NO numero de
///   frutos, cajas, jugo, Brix ni precio (doc 03 §0.3).
/// - El limón NO usa kg/arbol de naranjo (doc 03 §0.1, §18). El cuello de
///   botella es el estres de floracion/cuajado (`LemonBloomSetStatus`), no la
///   polinizacion; el desfase mal aplicado (`inducedBloomStressFailure`) baja
///   el amarre.
/// - El fallback de perfil es SIEMPRE LM-SKIP de limón, NUNCA el SKIP de otro
///   arbol (doc 03 §11, §19.11).
///
/// Aditivo: NO reemplaza el motor minimo `TreeYieldReferenceCatalog`.
library;

import 'package:bio_g/core/crops/lemon_tree/lemon_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Rango aproximado bajo / esperado / alto.
class YieldRange {
  const YieldRange(this.low, this.expected, this.high);

  final double low;
  final double expected;
  final double high;

  YieldRange scale(double factor) =>
      YieldRange(low * factor, expected * factor, high * factor);

  YieldRange scaleEach(double fLow, double fExp, double fHigh) =>
      YieldRange(low * fLow, expected * fExp, high * fHigh);

  /// Limita cada extremo a un tope (cap kg/arbol por densidad).
  YieldRange cappedAt(double cap) => YieldRange(
    low > cap ? cap : low,
    expected > cap ? cap : expected,
    high > cap ? cap : high,
  );

  static const YieldRange zero = YieldRange(0, 0, 0);
}

/// Referencia base de rendimiento por perfil LM (doc 03 §11).
class LemonTreeYieldReference {
  const LemonTreeYieldReference({
    required this.profileId,
    required this.fullKgPerTree,
    required this.expectedTonPerHa,
    required this.confidenceBase,
    this.commercialFruitPct = const YieldRange(45, 62, 78),
    this.notesEs = const <String>[],
  });

  final String profileId;
  final YieldRange fullKgPerTree;
  final YieldRange expectedTonPerHa;
  final double confidenceBase;

  /// Porcentaje orientativo de fruta comercializable. Contexto de calidad
  /// (doc 03 §0.3, §9.4). NO entra al calculo principal de kg biologicos.
  final YieldRange commercialFruitPct;
  final List<String> notesEs;
}

/// Estado productivo del limón (doc 03 §6). Incluye `offSeasonInduced` para el
/// perfil de desfase (doc 03 §6.1), ausente en el naranjo.
enum LemonProductionState {
  nonProductive,
  firstBearing,
  youngBearing,
  fullBearing,
  lowSetOrDropYear,
  offSeasonInduced,
  oldDeclining,
  unknown,
}

enum LemonManagementLevel { low, medium, good, high, exceptional }

enum LemonIrrigationLevel {
  rainfedHumid,
  rainfedDry,
  irregular,
  stable,
  fertigation,
}

/// Calidad de floracion / cuajado / amarre (doc 03 §9.1). En limón no se modela
/// polinizacion; el cuello de botella es el estres de floracion/cuajado (agua,
/// calor, frio, sales) y el desfase mal aplicado.
enum LemonBloomSetStatus {
  unknown,
  goodBloomGoodSet,
  goodBloomPoorSet,
  weakBloom,
  heatDroughtSetLoss,
  fruitSetConfirmed,
  inducedBloomManaged,
  inducedBloomStressFailure,
}

/// Carga visible de fruto (doc 03 §9.2).
enum LemonCropLoadStatus { noneVisible, light, balanced, heavy, unknown }

/// Riesgo de calidad comercial (doc 03 §9.3). NO borra kg biologicos; solo baja
/// el porcentaje comercializable y agrega nota.
enum LemonCommercialQualityRisk { none, mild, moderate, severe }

/// Severidad de estres guardada en memoria multianual (doc 03 §10).
enum LemonStressSeverity { none, mild, moderate, severe }

/// Memoria de estres del limón (doc 03 §10.2 / doc 04 §5, §9.4). Solo afecta el
/// rendimiento como modificador; nunca borra historial ni etapa.
class LemonTreeStressMemory {
  const LemonTreeStressMemory({
    this.floweringHeatOrDrought = LemonStressSeverity.none,
    this.fruitSetDrop = LemonStressSeverity.none,
    this.fruitFillWaterStress = LemonStressSeverity.none,
    this.salinityOrSodicityStress = LemonStressSeverity.none,
    this.phytophthoraOrRootDecline = LemonStressSeverity.none,
    this.hlbOrCanopyDecline = LemonStressSeverity.none,
    this.nutritionOrLeafStress = LemonStressSeverity.none,
    this.pestOrDiseaseFruitLoss = LemonStressSeverity.none,
    this.windHailSunburnOrRindDamage = LemonStressSeverity.none,
    this.inducedStressMismanaged = LemonStressSeverity.none,
    this.postHarvestReserveRisk = LemonStressSeverity.none,
  });

  final LemonStressSeverity floweringHeatOrDrought;
  final LemonStressSeverity fruitSetDrop;
  final LemonStressSeverity fruitFillWaterStress;
  final LemonStressSeverity salinityOrSodicityStress;
  final LemonStressSeverity phytophthoraOrRootDecline;
  final LemonStressSeverity hlbOrCanopyDecline;
  final LemonStressSeverity nutritionOrLeafStress;
  final LemonStressSeverity pestOrDiseaseFruitLoss;
  final LemonStressSeverity windHailSunburnOrRindDamage;
  final LemonStressSeverity inducedStressMismanaged;
  final LemonStressSeverity postHarvestReserveRisk;

  bool get hasAnyStress =>
      floweringHeatOrDrought != LemonStressSeverity.none ||
      fruitSetDrop != LemonStressSeverity.none ||
      fruitFillWaterStress != LemonStressSeverity.none ||
      salinityOrSodicityStress != LemonStressSeverity.none ||
      phytophthoraOrRootDecline != LemonStressSeverity.none ||
      hlbOrCanopyDecline != LemonStressSeverity.none ||
      nutritionOrLeafStress != LemonStressSeverity.none ||
      pestOrDiseaseFruitLoss != LemonStressSeverity.none ||
      windHailSunburnOrRindDamage != LemonStressSeverity.none ||
      inducedStressMismanaged != LemonStressSeverity.none ||
      postHarvestReserveRisk != LemonStressSeverity.none;

  /// Factor de rendimiento combinado 0..1 (doc 03 §10.3). Se toma el evento mas
  /// severo (el cuello de botella del ciclo); no se multiplican todos.
  /// HLB/copa, Phytophthora/raiz, floracion/cuajado golpeados o estres inducido
  /// mal aplicado severos pueden justificar cap hard a 0.25.
  double get yieldFactor01 {
    double factorFor(LemonStressSeverity s) => switch (s) {
      LemonStressSeverity.none => 1.0,
      LemonStressSeverity.mild => 0.88,
      LemonStressSeverity.moderate => 0.65,
      LemonStressSeverity.severe => 0.35,
    };
    final factors = <double>[
      factorFor(floweringHeatOrDrought),
      factorFor(fruitSetDrop),
      factorFor(fruitFillWaterStress),
      factorFor(salinityOrSodicityStress),
      factorFor(phytophthoraOrRootDecline),
      factorFor(hlbOrCanopyDecline),
      factorFor(nutritionOrLeafStress),
      factorFor(pestOrDiseaseFruitLoss),
      factorFor(windHailSunburnOrRindDamage),
      factorFor(inducedStressMismanaged),
      factorFor(postHarvestReserveRisk),
    ];
    double worst = factors.reduce((a, b) => a < b ? a : b);
    final hardHits = <LemonStressSeverity>[
      floweringHeatOrDrought,
      fruitSetDrop,
      phytophthoraOrRootDecline,
      hlbOrCanopyDecline,
      inducedStressMismanaged,
    ];
    if (hardHits.any((s) => s == LemonStressSeverity.severe) && worst > 0.25) {
      worst = 0.25;
    }
    return worst;
  }
}

/// Sistema de densidad (doc 03 §7.3): define el tope de kg/arbol. El cap evita
/// que la alta densidad multiplique kg/arbol como si cada arbol fuera amplio y
/// aislado (competencia de luz, agua, espacio y manejo de copa).
class LemonDensitySystem {
  const LemonDensitySystem(this.id, this.kgPerTreeCap);

  final String id;
  final double kgPerTreeCap;

  static const LemonDensitySystem extensive = LemonDensitySystem(
    'extensive_or_old_spacing_under_250_trees_ha',
    180,
  );
  static const LemonDensitySystem traditional = LemonDensitySystem(
    'traditional_250_400_trees_ha',
    130,
  );
  static const LemonDensitySystem commercialModerate = LemonDensitySystem(
    'commercial_400_650_trees_ha',
    95,
  );
  static const LemonDensitySystem highDensityManaged = LemonDensitySystem(
    'high_density_650_900_trees_ha',
    55,
  );
  static const LemonDensitySystem veryHighDensity = LemonDensitySystem(
    'very_high_density_over_900_trees_ha',
    50,
  );

  static LemonDensitySystem fromTreesPerHa(double treesPerHa) {
    if (treesPerHa < 250) return extensive;
    if (treesPerHa < 400) return traditional;
    if (treesPerHa < 650) return commercialModerate;
    if (treesPerHa < 900) return highDensityManaged;
    return veryHighDensity;
  }
}

/// Proyeccion de rendimiento aproximada del limón.
class LemonTreeYieldProjection {
  const LemonTreeYieldProjection({
    required this.isProductive,
    required this.profileId,
    required this.productionState,
    required this.confidence01,
    this.kgPerTree,
    this.tonPerHa,
    this.totalKg,
    this.commercialFruitPct,
    this.notesEs = const <String>[],
  });

  final bool isProductive;
  final String profileId;
  final LemonProductionState productionState;
  final double confidence01;

  final YieldRange? kgPerTree;
  final YieldRange? tonPerHa;
  final YieldRange? totalKg;

  /// Contexto de calidad: fruta comercializable (doc 03 §0.3, §9.4).
  final YieldRange? commercialFruitPct;

  final List<String> notesEs;

  factory LemonTreeYieldProjection.zero({
    required String profileId,
    required double confidence,
    List<String> notesEs = const <String>[],
  }) => LemonTreeYieldProjection(
    isProductive: false,
    profileId: profileId,
    productionState: LemonProductionState.nonProductive,
    confidence01: confidence,
    kgPerTree: YieldRange.zero,
    notesEs: notesEs,
  );
}

/// Tabla de referencia por perfil (doc 03 §4, §11). kg de limón fresco/arbol.
const Map<String, LemonTreeYieldReference> lemonYieldReferenceByProfile =
    <String, LemonTreeYieldReference>{
      kLmSkip: LemonTreeYieldReference(
        profileId: kLmSkip,
        fullKgPerTree: YieldRange(15, 35, 65),
        expectedTonPerHa: YieldRange(5, 12, 24),
        confidenceBase: 0.44,
        commercialFruitPct: YieldRange(45, 62, 78),
        notesEs: <String>[
          'Perfil general: no asume Persa, Mexicano, Amarillo, densidad, riego, '
              'portainjerto ni manejo técnico. No sobreestimar.',
        ],
      ),
      kLm01PersaTahiti: LemonTreeYieldReference(
        profileId: kLm01PersaTahiti,
        fullKgPerTree: YieldRange(35, 70, 115),
        expectedTonPerHa: YieldRange(10, 24, 42),
        confidenceBase: 0.68,
        commercialFruitPct: YieldRange(55, 72, 88),
        notesEs: <String>[
          'Persa/Tahití: buen potencial con riego, poda, sanidad y densidad; '
              'vigilar exportable, calibre, color verde comercial, salinidad y '
              'raíz. En alta densidad cada árbol carga menos: aplica caps.',
        ],
      ),
      kLm02MexicanoColima: LemonTreeYieldReference(
        profileId: kLm02MexicanoColima,
        fullKgPerTree: YieldRange(20, 45, 80),
        expectedTonPerHa: YieldRange(7, 16, 30),
        confidenceBase: 0.62,
        commercialFruitPct: YieldRange(50, 68, 84),
        notesEs: <String>[
          'Mexicano/Colima: cosecha frecuente, fruto chico y ácido; vigilar '
              'frío, HLB/psílido, antracnosis, caída de frutito, agua y '
              'salinidad.',
        ],
      ),
      kLm03AmarilloEurekaLisbon: LemonTreeYieldReference(
        profileId: kLm03AmarilloEurekaLisbon,
        fullKgPerTree: YieldRange(30, 60, 100),
        expectedTonPerHa: YieldRange(8, 20, 36),
        confidenceBase: 0.54,
        commercialFruitPct: YieldRange(55, 72, 88),
        notesEs: <String>[
          'Amarillo/Eureka/Lisbon: menor presencia relativa en México; leer con '
              'clima, heladas, humedad y calidad comercial. El corte sí habla de '
              'color amarillo.',
        ],
      ),
      kLm04TropicalContinuo: LemonTreeYieldReference(
        profileId: kLm04TropicalContinuo,
        fullKgPerTree: YieldRange(20, 50, 90),
        expectedTonPerHa: YieldRange(6, 18, 35),
        confidenceBase: 0.50,
        commercialFruitPct: YieldRange(45, 62, 78),
        notesEs: <String>[
          'Tropical/continuo: puede tener cortes y floraciones repetidas; '
              'vigilar agotamiento, plagas de brote, salinidad y estrés '
              'acumulado.',
        ],
      ),
      kLm05DesfaseInducido: LemonTreeYieldReference(
        profileId: kLm05DesfaseInducido,
        fullKgPerTree: YieldRange(18, 40, 80),
        expectedTonPerHa: YieldRange(5, 16, 32),
        confidenceBase: 0.42,
        commercialFruitPct: YieldRange(45, 65, 85),
        notesEs: <String>[
          'Desfase/inducido: busca mover la ventana de cosecha, no prometer más '
              'toneladas. Estrés mal aplicado puede bajar el amarre.',
        ],
      ),
    };

/// Conversiones oficiales (doc 03 §7.1).
double treesPerHaFromSpacing(double rowM, double treeM) {
  if (rowM <= 0 || treeM <= 0) return 0;
  return 10000 / (rowM * treeM);
}

double tonHaFromKgTree(double kgTree, double treesPerHa) =>
    (kgTree * treesPerHa) / 1000;

double kgTreeFromTonHa(double tonHa, double treesPerHa) {
  if (treesPerHa <= 0) return 0;
  return (tonHa * 1000) / treesPerHa;
}

/// Normaliza el profileId al id canonico para el lookup de rendimiento,
/// conservando el historial: los ids previos de cada LM siguen resolviendo a su
/// id canonico (doc 03 §12).
String? _normalizeLemonProfileId(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  if (id == null || id.isEmpty) return id;
  if (id == 'lm_01_persa' ||
      id == 'lm_01_tahiti' ||
      id == 'lm_01_persian_lime' ||
      id == 'lm_01_sin_semilla') {
    return kLm01PersaTahiti;
  }
  if (id == 'lm_02_mexicano' ||
      id == 'lm_02_colima' ||
      id == 'lm_02_criollo' ||
      id == 'lm_02_key_lime' ||
      id == 'lm_02_agrio') {
    return kLm02MexicanoColima;
  }
  if (id == 'lm_03_amarillo' ||
      id == 'lm_03_italiano' ||
      id == 'lm_03_eureka' ||
      id == 'lm_03_lisbon' ||
      id == 'lm_03_lisboa') {
    return kLm03AmarilloEurekaLisbon;
  }
  if (id == 'lm_04_tropical' ||
      id == 'lm_04_continuo' ||
      id == 'lm_04_de_calor') {
    return kLm04TropicalContinuo;
  }
  if (id == 'lm_05_desfase' ||
      id == 'lm_05_inducido' ||
      id == 'lm_05_invierno' ||
      id == 'lm_05_programado') {
    return kLm05DesfaseInducido;
  }
  return id;
}

/// Multiplicadores por estado productivo (doc 03 §6.1).
({double low, double expected, double high}) _productionStateFactors(
  LemonProductionState state,
) {
  return switch (state) {
    LemonProductionState.nonProductive => (low: 0, expected: 0, high: 0),
    LemonProductionState.firstBearing => (
      low: 0.08,
      expected: 0.25,
      high: 0.45,
    ),
    LemonProductionState.youngBearing => (
      low: 0.35,
      expected: 0.65,
      high: 0.90,
    ),
    LemonProductionState.fullBearing => (low: 0.75, expected: 1.00, high: 1.20),
    LemonProductionState.lowSetOrDropYear => (
      low: 0.15,
      expected: 0.45,
      high: 0.75,
    ),
    LemonProductionState.offSeasonInduced => (
      low: 0.20,
      expected: 0.55,
      high: 0.95,
    ),
    LemonProductionState.oldDeclining => (
      low: 0.30,
      expected: 0.60,
      high: 0.85,
    ),
    LemonProductionState.unknown => (low: 0.25, expected: 0.55, high: 0.85),
  };
}

double _managementFactor(LemonManagementLevel? level) => switch (level) {
  null => 1.0,
  LemonManagementLevel.low => 0.55,
  LemonManagementLevel.medium => 0.85,
  LemonManagementLevel.good => 1.05,
  LemonManagementLevel.high => 1.18,
  LemonManagementLevel.exceptional => 1.28,
};

/// Convierte el porcentaje de cuidado del usuario a factor (doc 03 §8.2). 100%
/// = manejo correcto para el potencial base del perfil, NO cosecha maxima.
double _carePercentFactor(double? carePercent) {
  if (carePercent == null) return 1.0;
  final p = carePercent.clamp(0, 130).toDouble();
  if (p <= 30) return 0.40;
  if (p <= 50) return 0.60;
  if (p <= 70) return 0.78;
  if (p <= 90) return 0.90;
  if (p <= 105) return 1.00;
  if (p <= 115) return 1.12;
  if (p <= 125) return 1.20;
  return 1.25;
}

double _irrigationFactor(LemonIrrigationLevel? level) => switch (level) {
  null => 1.0,
  LemonIrrigationLevel.rainfedHumid => 0.75,
  LemonIrrigationLevel.rainfedDry => 0.45,
  LemonIrrigationLevel.irregular => 0.70,
  LemonIrrigationLevel.stable => 1.02,
  LemonIrrigationLevel.fertigation => 1.12,
};

/// Factor de floracion/cuajado (doc 03 §9.1). Si no se sabe, no destruye el
/// calculo (baja confianza). El desfase mal aplicado (`inducedBloomStressFailure`)
/// tumba el amarre; el inducido bien manejado sube ligero.
double _bloomSetFactor(LemonBloomSetStatus? status) => switch (status) {
  null || LemonBloomSetStatus.unknown => 1.0,
  LemonBloomSetStatus.goodBloomGoodSet => 1.08,
  LemonBloomSetStatus.fruitSetConfirmed => 1.03,
  LemonBloomSetStatus.goodBloomPoorSet => 0.70,
  LemonBloomSetStatus.weakBloom => 0.60,
  LemonBloomSetStatus.heatDroughtSetLoss => 0.50,
  LemonBloomSetStatus.inducedBloomManaged => 1.05,
  LemonBloomSetStatus.inducedBloomStressFailure => 0.50,
};

/// Factor de carga visible (doc 03 §9.2). Carga heavy sube kg biologicos, pero
/// puede bajar calibre/calidad comercial (se maneja como nota aparte).
double _cropLoadFactor(LemonCropLoadStatus? status) => switch (status) {
  null || LemonCropLoadStatus.unknown => 1.0,
  LemonCropLoadStatus.noneVisible => 0.20,
  LemonCropLoadStatus.light => 0.55,
  LemonCropLoadStatus.balanced => 1.0,
  LemonCropLoadStatus.heavy => 1.05,
};

/// Factor de calidad comercial (doc 03 §9.3). NO borra kg biologicos: solo baja
/// el porcentaje comercializable.
double _commercialQualityFactor(LemonCommercialQualityRisk? risk) =>
    switch (risk) {
      null || LemonCommercialQualityRisk.none => 1.0,
      LemonCommercialQualityRisk.mild => 0.92,
      LemonCommercialQualityRisk.moderate => 0.78,
      LemonCommercialQualityRisk.severe => 0.55,
    };

/// Inferencia de estado productivo (doc 03 §6.2). Conservadora.
LemonProductionState _inferProductionState({
  required String stateId,
  required String stageId,
  LemonProductionState? explicit,
}) {
  if (explicit != null) return explicit;
  if (stateId == TreeStateIds.newlyPlanted ||
      stateId == TreeStateIds.juvenileNonProductive) {
    return LemonProductionState.nonProductive;
  }
  if (stateId == TreeStateIds.productiveSeason) {
    return switch (stageId) {
      TreeStageIds.flowering => LemonProductionState.unknown,
      TreeStageIds.fruitSet => LemonProductionState.youngBearing,
      TreeStageIds.fruitFill ||
      TreeStageIds.harvestMaturity ||
      TreeStageIds.postHarvest => LemonProductionState.fullBearing,
      _ => LemonProductionState.unknown,
    };
  }
  return LemonProductionState.unknown;
}

/// Estados/etapas que bloquean rendimiento comercial (doc 03 §6.3).
bool _blocksYield(String stateId, String stageId) {
  if (stateId == TreeStateIds.newlyPlanted ||
      stateId == TreeStateIds.juvenileNonProductive) {
    return true;
  }
  return stageId == TreeStageIds.plantingTransplant ||
      stageId == TreeStageIds.rootEstablishment ||
      stageId == TreeStageIds.juvenileVegetative;
}

/// Calcula la proyeccion aproximada de rendimiento del limón (doc 03 §13).
LemonTreeYieldProjection resolveLemonTreeYield({
  required String? profileId,
  required String? perennialStateId,
  required String? phenologyStageId,
  double? treesPerHa,
  double? hectares,
  int? treeCount,
  LemonProductionState? productionState,
  LemonManagementLevel? managementLevel,
  double? carePercent,
  LemonIrrigationLevel? irrigationLevel,
  LemonBloomSetStatus? bloomSetStatus,
  LemonCropLoadStatus? cropLoadStatus,
  LemonCommercialQualityRisk? commercialQualityRisk,
  LemonTreeStressMemory? stressMemory,
}) {
  final stateId = normalizeTreeStateId(perennialStateId);
  final stageId = normalizeTreeStageId(phenologyStageId);
  final ref =
      lemonYieldReferenceByProfile[_normalizeLemonProfileId(profileId)] ??
      lemonYieldReferenceByProfile[kLmSkip]!;

  // 1. Bloqueo no productivo.
  if (_blocksYield(stateId, stageId)) {
    return LemonTreeYieldProjection.zero(
      profileId: ref.profileId,
      confidence: 0.85,
      notesEs: const <String>[
        'Todavía no proyectamos cosecha fuerte. En limonero joven primero '
            'importa raíz, copa, hoja sana y estructura antes que forzar '
            'producción.',
      ],
    );
  }

  final state = _inferProductionState(
    stateId: stateId,
    stageId: stageId,
    explicit: productionState,
  );
  if (state == LemonProductionState.nonProductive) {
    return LemonTreeYieldProjection.zero(
      profileId: ref.profileId,
      confidence: 0.85,
    );
  }

  // 2. Densidad efectiva.
  final density =
      treesPerHa ??
      ((treeCount != null && hectares != null && hectares > 0)
          ? treeCount / hectares
          : null);

  // 3. Modificadores. Si hay manejo y carePercent, no se multiplican agresivo:
  // se usa carePercent como principal cuando existe (doc 03 §8.2).
  final sf = _productionStateFactors(state);
  final mgmt = _managementFactor(managementLevel);
  final care = _carePercentFactor(carePercent);
  final managementCombined = carePercent == null ? mgmt : care;
  final irr = _irrigationFactor(irrigationLevel);
  final set = _bloomSetFactor(bloomSetStatus);
  final load = _cropLoadFactor(cropLoadStatus);
  final stress = stressMemory?.yieldFactor01 ?? 1.0;
  final commonFactor = managementCombined * irr * set * load * stress;

  // 4. kg/arbol con factores de estado + comunes, luego tope por densidad.
  YieldRange kgTree = ref.fullKgPerTree
      .scaleEach(sf.low, sf.expected, sf.high)
      .scale(commonFactor);
  if (density != null) {
    kgTree = kgTree.cappedAt(
      LemonDensitySystem.fromTreesPerHa(density).kgPerTreeCap,
    );
  }

  // 5. t/ha desde kg/arbol y densidad.
  final tonHa = density == null
      ? null
      : YieldRange(
          tonHaFromKgTree(kgTree.low, density),
          tonHaFromKgTree(kgTree.expected, density),
          tonHaFromKgTree(kgTree.high, density),
        );

  // 6. Total kg si hay numero de arboles.
  final totalKg = treeCount == null ? null : kgTree.scale(treeCount.toDouble());

  // 7. Calidad comercial como contexto.
  final commercialFruitPct = ref.commercialFruitPct.scale(
    _commercialQualityFactor(commercialQualityRisk),
  );

  // 8. Confianza (doc 03 §14.1).
  double confidence = ref.confidenceBase;
  if (density == null) confidence -= 0.15;
  if (state == LemonProductionState.unknown) confidence -= 0.10;
  if (stageId == TreeStageIds.unknown) confidence -= 0.05;
  if (stressMemory != null && stressMemory.hasAnyStress) confidence -= 0.10;
  if ((stageId == TreeStageIds.flowering || stageId == TreeStageIds.fruitSet) &&
      bloomSetStatus == null) {
    confidence -= 0.05;
  }
  if (irrigationLevel == null && stageId == TreeStageIds.fruitFill) {
    confidence -= 0.05;
  }
  // El desfase sin bloomSet/riego informado pierde confianza adicional.
  if (ref.profileId == kLm05DesfaseInducido &&
      (bloomSetStatus == null || irrigationLevel == null)) {
    confidence -= 0.10;
  }
  if (density != null &&
      stageId != TreeStageIds.unknown &&
      (cropLoadStatus == LemonCropLoadStatus.balanced ||
          cropLoadStatus == LemonCropLoadStatus.heavy)) {
    confidence += 0.05;
  }
  // El perfil general nunca pasa de 0.60 salvo historial real (doc 03 §14.1).
  if (ref.profileId == kLmSkip && confidence > 0.60) confidence = 0.60;
  // El desfase nunca pasa de 0.58 sin perfil base/historial (doc 03 §14.1).
  if (ref.profileId == kLm05DesfaseInducido && confidence > 0.58) {
    confidence = 0.58;
  }
  confidence = confidence.clamp(0.05, 0.95);

  // 9. Notas.
  final notes = <String>[...ref.notesEs];
  if (ref.profileId == kLmSkip) {
    notes.add(
      'Este cálculo usa un perfil general de limón. Puede mejorar si eliges '
      'Persa, Mexicano, Amarillo, Tropical o Desfase sin perder historial.',
    );
  }
  if (density == null) {
    notes.add(
      'Sin densidad ni número de árboles no estimamos t/ha con precisión; '
      'indica árboles/ha o marco de plantación para mejorar la proyección.',
    );
  }
  if (commercialQualityRisk != null &&
      commercialQualityRisk != LemonCommercialQualityRisk.none) {
    notes.add(
      'Puede haber kg biológicos, pero no toda la fruta entra como buena: '
      'revisa calibre, jugo, cáscara, daño externo y sanidad.',
    );
  }
  if (stress < 1.0) {
    notes.add(
      'Ajustamos a la baja por memoria de estrés. Una floración golpeada, agua, '
      'salinidad, raíz, HLB o un desfase mal aplicado pueden pegarle al cuajado '
      'y al calibre.',
    );
  }
  if (tonHa != null && tonHa.expected > 40) {
    notes.add(
      'Proyección alta: confirma densidad real, árboles faltantes, poda, riego, '
      'salinidad, calibre y fruta comercializable antes de tomarlo como '
      'expectativa. En alta densidad se limita kg/árbol.',
    );
  }
  if (tonHa != null &&
      tonHa.expected < 7 &&
      state == LemonProductionState.fullBearing) {
    notes.add(
      'Proyección baja para árbol productivo: revisar floración/cuajado, agua, '
      'salinidad, raíz, HLB/psílido/Phytophthora, defoliación y postcosecha. No '
      'se arregla solo con fertilizante.',
    );
  }

  return LemonTreeYieldProjection(
    isProductive: true,
    profileId: ref.profileId,
    productionState: state,
    confidence01: confidence,
    kgPerTree: kgTree,
    tonPerHa: tonHa,
    totalKg: totalKg,
    commercialFruitPct: commercialFruitPct,
    notesEs: notes,
  );
}
