/// Rendimiento aproximado del Mango (doc 03 oficial).
///
/// Reglas no negociables:
/// - El rendimiento del mango NO se calcula como cultivo anual ni desde
///   `sowingDate`: se estima por kg de mango fresco/arbol + arboles/ha + estado
///   productivo + perfil MG + densidad + manejo + riego + inducción/floración/
///   cuajado + carga + calidad comercial + memoria de estres + confianza
///   (doc 03 §0.5, §13).
/// - Es APROXIMADO y en rango (bajo / esperado / alto). Nunca es promesa.
/// - Estados no productivos y etapas de establecimiento proyectan 0.
/// - `post_harvest` NO cierra el cultivo ni borra historial (doc 03 §0.5).
/// - La salida principal es kg de mango fresco/arbol y t/ha, NO numero de
///   frutos, cajas, Brix ni precio (doc 03 §0.3).
/// - El mango NO usa kg/arbol de limón/naranjo/manzano/nogal (doc 03 §0.1, §17).
///   Tiene fisiología propia: la NO floración es válida, el cuajado es frágil,
///   hay caída natural y por estrés, alternancia productiva y fuerte dependencia
///   de reservas/postcosecha. El cuello de botella dominante es
///   inducción/floración/cuajado (`MangoBloomSetStatus`), no la polinización.
/// - El fallback de perfil es SIEMPRE MG-SKIP de mango, NUNCA el SKIP de otro
///   arbol (doc 03 §11, §16).
///
/// Aditivo: NO reemplaza el motor minimo `TreeYieldReferenceCatalog`.
library;

import 'package:bio_g/core/crops/mango_tree/mango_tree_catalog.dart';
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

/// Referencia base de rendimiento por perfil MG (doc 03 §11).
class MangoTreeYieldReference {
  const MangoTreeYieldReference({
    required this.profileId,
    required this.fullKgPerTree,
    required this.expectedTonPerHa,
    required this.confidenceBase,
    this.commercialFruitPct = const YieldRange(45, 65, 82),
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

/// Estado productivo del mango (doc 03 §6). Incluye alternancia (on/off),
/// floración/cuajado débil e inducción manejada/fallida: en mango el evento
/// reproductivo NO está garantizado cada ciclo.
enum MangoProductionState {
  nonProductive,
  firstBearing,
  youngBearing,
  fullBearing,
  lowFloweringYear,
  lowSetOrDropYear,
  alternateBearingHighYear,
  alternateBearingLowYear,
  inducedBloomManaged,
  inducedBloomStressFailure,
  oldDeclining,
  unknown,
}

enum MangoManagementLevel { low, medium, good, high, exceptional }

enum MangoIrrigationLevel {
  rainfedHumid,
  rainfedDry,
  irregular,
  stable,
  fertigation,
  managedDeficitForInduction,
}

/// Calidad de inducción / floración / cuajado / amarre (doc 03 §9.1). En mango
/// el cuello de botella NO es solo NPK: se decide entre inducción, panícula,
/// sanidad de flor, cuajado, caída de frutito y retención inicial.
enum MangoBloomSetStatus {
  unknown,
  inductionLikely,
  noFloweringLikely,
  goodBloomGoodSet,
  goodBloomPoorSet,
  weakBloom,
  heatColdRainSetLoss,
  anthracnosePowderyMildewBloomLoss,
  fruitSetConfirmed,
  inducedBloomManaged,
  inducedBloomStressFailure,
  alternateOffNoBloom,
}

/// Carga visible de fruto (doc 03 §9.2).
enum MangoCropLoadStatus { noneVisible, light, balanced, heavy, veryHeavy, unknown }

/// Riesgo de calidad comercial (doc 03 §9.3). NO borra kg biologicos: solo baja
/// el porcentaje comercializable y agrega nota.
enum MangoCommercialQualityRisk { none, mild, moderate, severe }

/// Severidad de estres guardada en memoria multianual (doc 03 §10).
enum MangoStressSeverity { none, mild, moderate, severe }

/// Memoria de estres del mango (doc 03 §10.2 / doc 04 §7). El mango tiene
/// memoria fuerte de 1-2 ciclos: estrés en postcosecha, inducción, floración,
/// cuajado o llenado afecta el rendimiento actual y el siguiente. Solo modula el
/// rendimiento; nunca borra historial ni etapa.
class MangoTreeStressMemory {
  const MangoTreeStressMemory({
    this.inductionFailure = MangoStressSeverity.none,
    this.floweringHeatColdOrRain = MangoStressSeverity.none,
    this.anthracnoseOrPowderyMildewBloomLoss = MangoStressSeverity.none,
    this.fruitSetDrop = MangoStressSeverity.none,
    this.fruitFillWaterStress = MangoStressSeverity.none,
    this.salinityOrSodicityStress = MangoStressSeverity.none,
    this.rootDeclineOrWaterlogging = MangoStressSeverity.none,
    this.nutritionOrLeafStress = MangoStressSeverity.none,
    this.pestOrDiseaseFruitLoss = MangoStressSeverity.none,
    this.windHailSunburnOrRindDamage = MangoStressSeverity.none,
    this.postHarvestReserveRisk = MangoStressSeverity.none,
    this.heavyCropAlternateBearingRisk = MangoStressSeverity.none,
    this.inducedStressMismanaged = MangoStressSeverity.none,
    this.excessVegetativeFlushOrPruning = MangoStressSeverity.none,
  });

  final MangoStressSeverity inductionFailure;
  final MangoStressSeverity floweringHeatColdOrRain;
  final MangoStressSeverity anthracnoseOrPowderyMildewBloomLoss;
  final MangoStressSeverity fruitSetDrop;
  final MangoStressSeverity fruitFillWaterStress;
  final MangoStressSeverity salinityOrSodicityStress;
  final MangoStressSeverity rootDeclineOrWaterlogging;
  final MangoStressSeverity nutritionOrLeafStress;
  final MangoStressSeverity pestOrDiseaseFruitLoss;
  final MangoStressSeverity windHailSunburnOrRindDamage;
  final MangoStressSeverity postHarvestReserveRisk;
  final MangoStressSeverity heavyCropAlternateBearingRisk;
  final MangoStressSeverity inducedStressMismanaged;
  final MangoStressSeverity excessVegetativeFlushOrPruning;

  bool get hasAnyStress =>
      inductionFailure != MangoStressSeverity.none ||
      floweringHeatColdOrRain != MangoStressSeverity.none ||
      anthracnoseOrPowderyMildewBloomLoss != MangoStressSeverity.none ||
      fruitSetDrop != MangoStressSeverity.none ||
      fruitFillWaterStress != MangoStressSeverity.none ||
      salinityOrSodicityStress != MangoStressSeverity.none ||
      rootDeclineOrWaterlogging != MangoStressSeverity.none ||
      nutritionOrLeafStress != MangoStressSeverity.none ||
      pestOrDiseaseFruitLoss != MangoStressSeverity.none ||
      windHailSunburnOrRindDamage != MangoStressSeverity.none ||
      postHarvestReserveRisk != MangoStressSeverity.none ||
      heavyCropAlternateBearingRisk != MangoStressSeverity.none ||
      inducedStressMismanaged != MangoStressSeverity.none ||
      excessVegetativeFlushOrPruning != MangoStressSeverity.none;

  /// Factor de rendimiento combinado 0..1 (doc 03 §10.3). Se toma el evento mas
  /// severo (el cuello de botella del ciclo); no se multiplican todos.
  /// Inducción fallida, floración golpeada, antracnosis/cenicilla, caída de
  /// frutito o estrés inducido mal aplicado SEVEROS pueden justificar cap hard a
  /// 0.22 (rango 0.20-0.25 del doc).
  double get yieldFactor01 {
    double factorFor(MangoStressSeverity s) => switch (s) {
      MangoStressSeverity.none => 1.0,
      MangoStressSeverity.mild => 0.88,
      MangoStressSeverity.moderate => 0.65,
      MangoStressSeverity.severe => 0.35,
    };
    final factors = <double>[
      factorFor(inductionFailure),
      factorFor(floweringHeatColdOrRain),
      factorFor(anthracnoseOrPowderyMildewBloomLoss),
      factorFor(fruitSetDrop),
      factorFor(fruitFillWaterStress),
      factorFor(salinityOrSodicityStress),
      factorFor(rootDeclineOrWaterlogging),
      factorFor(nutritionOrLeafStress),
      factorFor(pestOrDiseaseFruitLoss),
      factorFor(windHailSunburnOrRindDamage),
      factorFor(postHarvestReserveRisk),
      factorFor(heavyCropAlternateBearingRisk),
      factorFor(inducedStressMismanaged),
      factorFor(excessVegetativeFlushOrPruning),
    ];
    double worst = factors.reduce((a, b) => a < b ? a : b);
    final hardHits = <MangoStressSeverity>[
      inductionFailure,
      floweringHeatColdOrRain,
      anthracnoseOrPowderyMildewBloomLoss,
      fruitSetDrop,
      inducedStressMismanaged,
    ];
    if (hardHits.any((s) => s == MangoStressSeverity.severe) && worst > 0.22) {
      worst = 0.22;
    }
    return worst;
  }
}

/// Sistema de densidad (doc 03 §7.3): define el tope de kg/arbol. El cap evita
/// que la alta densidad multiplique kg/arbol como si cada arbol fuera amplio y
/// aislado (competencia de luz, agua, espacio y manejo de copa).
class MangoDensitySystem {
  const MangoDensitySystem(this.id, this.kgPerTreeCap);

  final String id;
  final double kgPerTreeCap;

  static const MangoDensitySystem extensive = MangoDensitySystem(
    'extensive_or_old_spacing_under_150_trees_ha',
    190,
  );
  static const MangoDensitySystem traditional = MangoDensitySystem(
    'traditional_150_250_trees_ha',
    155,
  );
  static const MangoDensitySystem commercialModerate = MangoDensitySystem(
    'commercial_250_450_trees_ha',
    115,
  );
  static const MangoDensitySystem intensiveManaged = MangoDensitySystem(
    'intensive_450_800_trees_ha',
    80,
  );
  static const MangoDensitySystem highDensityManaged = MangoDensitySystem(
    'high_density_800_1250_trees_ha',
    50,
  );
  static const MangoDensitySystem ultraHighDensity = MangoDensitySystem(
    'ultra_high_density_over_1250_trees_ha',
    38,
  );

  static MangoDensitySystem fromTreesPerHa(double treesPerHa) {
    if (treesPerHa < 150) return extensive;
    if (treesPerHa < 250) return traditional;
    if (treesPerHa < 450) return commercialModerate;
    if (treesPerHa < 800) return intensiveManaged;
    if (treesPerHa < 1250) return highDensityManaged;
    return ultraHighDensity;
  }
}

/// Proyeccion de rendimiento aproximada del mango.
class MangoTreeYieldProjection {
  const MangoTreeYieldProjection({
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
  final MangoProductionState productionState;
  final double confidence01;

  final YieldRange? kgPerTree;
  final YieldRange? tonPerHa;
  final YieldRange? totalKg;

  /// Contexto de calidad: fruta comercializable (doc 03 §0.3, §9.4).
  final YieldRange? commercialFruitPct;

  final List<String> notesEs;

  factory MangoTreeYieldProjection.zero({
    required String profileId,
    required double confidence,
    List<String> notesEs = const <String>[],
  }) => MangoTreeYieldProjection(
    isProductive: false,
    profileId: profileId,
    productionState: MangoProductionState.nonProductive,
    confidence01: confidence,
    kgPerTree: YieldRange.zero,
    notesEs: notesEs,
  );
}

/// Tabla de referencia por perfil (doc 03 §4, §11). kg de mango fresco/arbol.
const Map<String, MangoTreeYieldReference> mangoYieldReferenceByProfile =
    <String, MangoTreeYieldReference>{
      kMgSkip: MangoTreeYieldReference(
        profileId: kMgSkip,
        fullKgPerTree: YieldRange(18, 48, 90),
        expectedTonPerHa: YieldRange(4, 10.5, 20),
        confidenceBase: 0.44,
        commercialFruitPct: YieldRange(45, 65, 82),
        notesEs: <String>[
          'Perfil general: no asume Ataulfo, Tommy, Kent, Keitt, criollo, '
              'densidad, riego, poda, portainjerto ni manejo técnico. No '
              'prometer floración anual.',
        ],
      ),
      kMg01AtaulfoManila: MangoTreeYieldReference(
        profileId: kMg01AtaulfoManila,
        fullKgPerTree: YieldRange(18, 45, 85),
        expectedTonPerHa: YieldRange(5, 12, 24),
        confidenceBase: 0.62,
        commercialFruitPct: YieldRange(50, 72, 88),
        notesEs: <String>[
          'Ataulfo/Manila: perfil temprano/premium; más cuidado con madurez de '
              'corte, calidad externa, floración, cuajado y alternancia. Premium '
              'no significa más toneladas.',
        ],
      ),
      kMg02TommyAtkins: MangoTreeYieldReference(
        profileId: kMg02TommyAtkins,
        fullKgPerTree: YieldRange(30, 70, 120),
        expectedTonPerHa: YieldRange(7, 17, 30),
        confidenceBase: 0.66,
        commercialFruitPct: YieldRange(58, 75, 90),
        notesEs: <String>[
          'Tommy Atkins: volumen/exportación; buen potencial con riego, copa '
              'manejada y sanidad. Vigilar exceso vegetativo, floración y '
              'calidad interna.',
        ],
      ),
      kMg03Kent: MangoTreeYieldReference(
        profileId: kMg03Kent,
        fullKgPerTree: YieldRange(32, 75, 130),
        expectedTonPerHa: YieldRange(8, 19, 32),
        confidenceBase: 0.62,
        commercialFruitPct: YieldRange(55, 76, 90),
        notesEs: <String>[
          'Kent: intermedio-tardío, buena calidad interna; requiere agua y '
              'sanidad durante el llenado largo. Vigilar madurez y alternancia.',
        ],
      ),
      kMg04Keitt: MangoTreeYieldReference(
        profileId: kMg04Keitt,
        fullKgPerTree: YieldRange(35, 80, 140),
        expectedTonPerHa: YieldRange(8, 20, 35),
        confidenceBase: 0.58,
        commercialFruitPct: YieldRange(52, 72, 88),
        notesEs: <String>[
          'Keitt: tardío/muy tardío, fruto grande; buen potencial, pero el largo '
              'llenado aumenta exposición a estrés hídrico, plagas, sanidad y '
              'calidad.',
        ],
      ),
      kMg05CriolloRegional: MangoTreeYieldReference(
        profileId: kMg05CriolloRegional,
        fullKgPerTree: YieldRange(15, 40, 85),
        expectedTonPerHa: YieldRange(3.5, 9, 20),
        confidenceBase: 0.46,
        commercialFruitPct: YieldRange(40, 60, 78),
        notesEs: <String>[
          'Criollo/regional: muy variable; puede ser rústico, de mercado local o '
              'árbol viejo. No asumir rendimiento alto por tamaño del árbol.',
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
/// conservando el historial: los ids previos/alias siguen resolviendo a su id
/// canonico (doc 03 §12).
String? _normalizeMangoProfileId(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  if (id == null || id.isEmpty) return id;
  if (id == 'mg_01_ataulfo' ||
      id == 'mg_01_manila' ||
      id == 'mg_01_mango_miel' ||
      id == 'mg_01_champagne' ||
      id == 'mg_01_premium') {
    return kMg01AtaulfoManila;
  }
  if (id == 'mg_02_tommy' ||
      id == 'mg_02_tommy_atkins' ||
      id == 'mg_02_exportacion' ||
      id == 'mg_02_volumen') {
    return kMg02TommyAtkins;
  }
  if (id == 'mg_03_kent' ||
      id == 'mg_03_exportacion_tardia' ||
      id == 'mg_03_calidad_interna') {
    return kMg03Kent;
  }
  if (id == 'mg_04_keitt' ||
      id == 'mg_04_tardio' ||
      id == 'mg_04_muy_tardio' ||
      id == 'mg_04_ventana_extendida') {
    return kMg04Keitt;
  }
  if (id == 'mg_05_criollo' ||
      id == 'mg_05_regional' ||
      id == 'mg_05_local' ||
      id == 'mg_05_huerto_viejo') {
    return kMg05CriolloRegional;
  }
  return id;
}

/// Multiplicadores por estado productivo (doc 03 §6.1).
({double low, double expected, double high}) _productionStateFactors(
  MangoProductionState state,
) {
  return switch (state) {
    MangoProductionState.nonProductive => (low: 0, expected: 0, high: 0),
    MangoProductionState.firstBearing => (
      low: 0.05,
      expected: 0.18,
      high: 0.35,
    ),
    MangoProductionState.youngBearing => (
      low: 0.25,
      expected: 0.55,
      high: 0.85,
    ),
    MangoProductionState.fullBearing => (low: 0.70, expected: 1.00, high: 1.20),
    MangoProductionState.lowFloweringYear => (
      low: 0.08,
      expected: 0.30,
      high: 0.55,
    ),
    MangoProductionState.lowSetOrDropYear => (
      low: 0.10,
      expected: 0.35,
      high: 0.65,
    ),
    MangoProductionState.alternateBearingHighYear => (
      low: 0.85,
      expected: 1.10,
      high: 1.35,
    ),
    MangoProductionState.alternateBearingLowYear => (
      low: 0.05,
      expected: 0.25,
      high: 0.55,
    ),
    MangoProductionState.inducedBloomManaged => (
      low: 0.40,
      expected: 0.80,
      high: 1.10,
    ),
    MangoProductionState.inducedBloomStressFailure => (
      low: 0.05,
      expected: 0.25,
      high: 0.55,
    ),
    MangoProductionState.oldDeclining => (
      low: 0.25,
      expected: 0.55,
      high: 0.85,
    ),
    MangoProductionState.unknown => (low: 0.20, expected: 0.50, high: 0.80),
  };
}

double _managementFactor(MangoManagementLevel? level) => switch (level) {
  null => 1.0,
  MangoManagementLevel.low => 0.55,
  MangoManagementLevel.medium => 0.85,
  MangoManagementLevel.good => 1.05,
  MangoManagementLevel.high => 1.18,
  MangoManagementLevel.exceptional => 1.30,
};

/// Convierte el porcentaje de cuidado del usuario a factor (doc 03 §8.2). 100%
/// = manejo correcto para el potencial base del perfil, NO cosecha maxima.
double _carePercentFactor(double? carePercent) {
  if (carePercent == null) return 1.0;
  final p = carePercent.clamp(0, 130).toDouble();
  if (p <= 30) return 0.38;
  if (p <= 50) return 0.58;
  if (p <= 70) return 0.76;
  if (p <= 90) return 0.90;
  if (p <= 105) return 1.00;
  if (p <= 115) return 1.12;
  if (p <= 125) return 1.20;
  return 1.25;
}

double _irrigationFactor(MangoIrrigationLevel? level) => switch (level) {
  null => 1.0,
  MangoIrrigationLevel.rainfedHumid => 0.78,
  MangoIrrigationLevel.rainfedDry => 0.48,
  MangoIrrigationLevel.irregular => 0.68,
  MangoIrrigationLevel.stable => 1.03,
  MangoIrrigationLevel.fertigation => 1.12,
  // El déficit leve/controlado puede favorecer inducción, pero el severo tumba
  // rendimiento. El riego no "premia" el estrés por sí solo: la respuesta se
  // modela con bloomSet y memoria (doc 03 §8.3).
  MangoIrrigationLevel.managedDeficitForInduction => 0.95,
};

/// Factor de inducción/floración/cuajado (doc 03 §9.1). Si no se sabe, no
/// destruye el calculo (baja confianza). La NO floración y la caída por estrés
/// tumban el amarre; la inducción bien manejada sube ligero.
double _bloomSetFactor(MangoBloomSetStatus? status) => switch (status) {
  null || MangoBloomSetStatus.unknown => 1.0,
  MangoBloomSetStatus.inductionLikely => 1.02,
  MangoBloomSetStatus.fruitSetConfirmed => 1.05,
  MangoBloomSetStatus.goodBloomGoodSet => 1.10,
  MangoBloomSetStatus.inducedBloomManaged => 1.05,
  MangoBloomSetStatus.goodBloomPoorSet => 0.65,
  MangoBloomSetStatus.weakBloom => 0.55,
  MangoBloomSetStatus.heatColdRainSetLoss => 0.40,
  MangoBloomSetStatus.anthracnosePowderyMildewBloomLoss => 0.40,
  MangoBloomSetStatus.inducedBloomStressFailure => 0.35,
  MangoBloomSetStatus.noFloweringLikely => 0.20,
  MangoBloomSetStatus.alternateOffNoBloom => 0.15,
};

/// Factor de carga visible (doc 03 §9.2). Carga heavy/veryHeavy sube kg
/// biologicos, pero puede bajar calibre/calidad y reservas del siguiente ciclo
/// (se maneja como nota/alternancia aparte).
double _cropLoadFactor(MangoCropLoadStatus? status) => switch (status) {
  null || MangoCropLoadStatus.unknown => 1.0,
  MangoCropLoadStatus.noneVisible => 0.15,
  MangoCropLoadStatus.light => 0.50,
  MangoCropLoadStatus.balanced => 1.0,
  MangoCropLoadStatus.heavy => 1.08,
  MangoCropLoadStatus.veryHeavy => 1.12,
};

/// Factor de calidad comercial (doc 03 §9.3). NO borra kg biologicos: solo baja
/// el porcentaje comercializable.
double _commercialQualityFactor(MangoCommercialQualityRisk? risk) =>
    switch (risk) {
      null || MangoCommercialQualityRisk.none => 1.0,
      MangoCommercialQualityRisk.mild => 0.92,
      MangoCommercialQualityRisk.moderate => 0.76,
      MangoCommercialQualityRisk.severe => 0.50,
    };

/// Inferencia de estado productivo (doc 03 §6.2). Conservadora: floración se
/// trata como lowFloweringYear (flor no es cosecha); fruit_fill/harvest/
/// post_harvest como fullBearing por defecto conservador.
MangoProductionState _inferProductionState({
  required String stateId,
  required String stageId,
  MangoProductionState? explicit,
}) {
  if (explicit != null) return explicit;
  if (stateId == TreeStateIds.newlyPlanted ||
      stateId == TreeStateIds.juvenileNonProductive) {
    return MangoProductionState.nonProductive;
  }
  if (stateId == TreeStateIds.established ||
      stateId == TreeStateIds.productiveSeason) {
    return switch (stageId) {
      TreeStageIds.flowering => MangoProductionState.lowFloweringYear,
      TreeStageIds.fruitSet => MangoProductionState.youngBearing,
      TreeStageIds.fruitFill ||
      TreeStageIds.harvestMaturity ||
      TreeStageIds.postHarvest => MangoProductionState.fullBearing,
      _ => MangoProductionState.unknown,
    };
  }
  return MangoProductionState.unknown;
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

bool _isInducedState(MangoProductionState state) =>
    state == MangoProductionState.inducedBloomManaged ||
    state == MangoProductionState.inducedBloomStressFailure;

/// Calcula la proyeccion aproximada de rendimiento del mango (doc 03 §13).
MangoTreeYieldProjection resolveMangoTreeYield({
  required String? profileId,
  required String? perennialStateId,
  required String? phenologyStageId,
  double? treesPerHa,
  double? hectares,
  int? treeCount,
  MangoProductionState? productionState,
  MangoManagementLevel? managementLevel,
  double? carePercent,
  MangoIrrigationLevel? irrigationLevel,
  MangoBloomSetStatus? bloomSetStatus,
  MangoCropLoadStatus? cropLoadStatus,
  MangoCommercialQualityRisk? commercialQualityRisk,
  MangoTreeStressMemory? stressMemory,
}) {
  final stateId = normalizeTreeStateId(perennialStateId);
  final stageId = normalizeTreeStageId(phenologyStageId);
  final ref =
      mangoYieldReferenceByProfile[_normalizeMangoProfileId(profileId)] ??
      mangoYieldReferenceByProfile[kMgSkip]!;

  // 1. Bloqueo no productivo.
  if (_blocksYield(stateId, stageId)) {
    return MangoTreeYieldProjection.zero(
      profileId: ref.profileId,
      confidence: 0.85,
      notesEs: const <String>[
        'Todavía no proyectamos cosecha fuerte. En mango joven primero importa '
            'raíz, copa, hoja madura y estructura antes que forzar floración.',
      ],
    );
  }

  final state = _inferProductionState(
    stateId: stateId,
    stageId: stageId,
    explicit: productionState,
  );
  if (state == MangoProductionState.nonProductive) {
    return MangoTreeYieldProjection.zero(
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
      MangoDensitySystem.fromTreesPerHa(density).kgPerTreeCap,
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

  // 8. Confianza (doc 03 §13.3).
  final bool isHighDensity = density != null && density >= 800;
  final bool managementIsHigh =
      managementLevel == MangoManagementLevel.high ||
      managementLevel == MangoManagementLevel.exceptional;

  double confidence = ref.confidenceBase;
  if (density == null) confidence -= 0.15;
  if (state == MangoProductionState.unknown) confidence -= 0.10;
  if (stageId == TreeStageIds.unknown) confidence -= 0.05;
  if (stressMemory != null && stressMemory.hasAnyStress) confidence -= 0.10;
  if ((stageId == TreeStageIds.flowering || stageId == TreeStageIds.fruitSet) &&
      bloomSetStatus == null) {
    confidence -= 0.05;
  }
  if (irrigationLevel == null && stageId == TreeStageIds.fruitFill) {
    confidence -= 0.05;
  }
  // La inducción/desfase sin bloomSet/riego informado pierde confianza extra.
  if (_isInducedState(state) &&
      (bloomSetStatus == null || irrigationLevel == null)) {
    confidence -= 0.10;
  }
  if (commercialQualityRisk == MangoCommercialQualityRisk.severe) {
    confidence -= 0.05;
  }
  // Alta densidad sin manejo alto no es expectativa simple (doc 03 §13.3).
  if (isHighDensity && !managementIsHigh) confidence -= 0.10;
  if (density != null &&
      stageId != TreeStageIds.unknown &&
      (cropLoadStatus == MangoCropLoadStatus.balanced ||
          cropLoadStatus == MangoCropLoadStatus.heavy ||
          cropLoadStatus == MangoCropLoadStatus.veryHeavy)) {
    confidence += 0.05;
  }
  // El perfil general nunca pasa de 0.60 salvo historial real (doc 03 §13.3).
  if (ref.profileId == kMgSkip && confidence > 0.60) confidence = 0.60;
  // Alta densidad sin historial no pasa de 0.70 (doc 03 §13.3).
  if (isHighDensity && confidence > 0.70) confidence = 0.70;
  confidence = confidence.clamp(0.05, 0.95);

  // 9. Notas.
  final notes = <String>[...ref.notesEs];
  if (ref.profileId == kMgSkip) {
    notes.add(
      'Este cálculo usa un perfil general de mango. Puede mejorar si eliges '
      'Ataulfo/Manila, Tommy, Kent, Keitt o Criollo sin perder historial.',
    );
  }
  if (density == null) {
    notes.add(
      'Sin densidad ni número de árboles no estimamos t/ha con precisión; '
      'indica árboles/ha o marco de plantación para mejorar la proyección.',
    );
  }
  if (bloomSetStatus == MangoBloomSetStatus.noFloweringLikely ||
      bloomSetStatus == MangoBloomSetStatus.alternateOffNoBloom) {
    notes.add(
      'El mango puede no florear un ciclo. No es falla automática: revisa edad, '
      'hoja madura, exceso de vigor, clima fresco/seco, poda y reservas. No lo '
      'arregla el fertilizante.',
    );
  }
  if (bloomSetStatus == MangoBloomSetStatus.goodBloomPoorSet ||
      bloomSetStatus == MangoBloomSetStatus.weakBloom) {
    notes.add(
      'Florear mucho no significa cosechar mucho. Si tiró flor o frutito, el '
      'rendimiento baja aunque el árbol se vea cargado de panícula.',
    );
  }
  if (commercialQualityRisk != null &&
      commercialQualityRisk != MangoCommercialQualityRisk.none) {
    notes.add(
      'Puede haber kg biológicos, pero no toda la fruta entra como buena: '
      'revisa calibre, madurez, mancha, golpe de sol, antracnosis y mosca de '
      'fruta.',
    );
  }
  if (cropLoadStatus == MangoCropLoadStatus.heavy ||
      cropLoadStatus == MangoCropLoadStatus.veryHeavy) {
    notes.add(
      'Traer mucho mango sube kg, pero puede bajar calibre y cansar el '
      'siguiente ciclo si no recupera reservas en postcosecha (alternancia).',
    );
  }
  if (stress < 1.0) {
    notes.add(
      'Ajustamos a la baja por memoria de estrés. Inducción fallida, floración '
      'golpeada, antracnosis/cenicilla, caída de frutito, sales, agua o una '
      'postcosecha débil pueden pegarle al cuajado, al calibre y al siguiente '
      'ciclo.',
    );
  }
  if (tonHa != null && tonHa.expected > 30) {
    notes.add(
      'Proyección alta: confirma densidad real, poda, riego, carga, sanidad y '
      'fruta comercializable antes de tomarlo como expectativa. En alta '
      'densidad se limita kg/árbol.',
    );
  }
  if (tonHa != null && tonHa.expected > 45) {
    notes.add(
      'Proyección de sistema intensivo/tecnificado: requiere diseño de copa, '
      'poda, riego/fertirriego, manejo alto, baja memoria de estrés y carga '
      'confirmada. Valídalo localmente; no es expectativa normal.',
    );
  }

  return MangoTreeYieldProjection(
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
