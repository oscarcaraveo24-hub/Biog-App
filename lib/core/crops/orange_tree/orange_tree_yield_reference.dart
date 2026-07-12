/// Rendimiento aproximado del Naranjo (doc 03 oficial).
///
/// Reglas no negociables:
/// - El rendimiento del naranjo NO se calcula como cultivo anual ni desde
///   `sowingDate`: se estima por kg de naranja fresca/arbol + arboles/ha +
///   estado productivo + perfil OR + densidad + manejo + riego + floracion/
///   cuajado + carga + memoria de estres + confianza (doc 03 §0.5, §10).
/// - Es APROXIMADO y en rango (bajo / esperado / alto). Nunca es promesa.
/// - Estados no productivos y etapas de establecimiento proyectan 0.
/// - `post_harvest` NO cierra el cultivo ni borra historial (doc 03 §0.5).
/// - La salida principal es kg de naranja fresca/arbol y t/ha, NO numero de
///   frutos, cajas, jugo, Brix ni precio (doc 03 §0.2).
/// - El naranjo es autofertil / no depende fuerte de polinizador: se modela
///   calidad de floracion/cuajado (`OrangeBloomSetStatus`), NO polinizacion
///   macho-hembra como el pistache (doc 03 §7.4).
/// - El fallback de perfil es SIEMPRE OR-SKIP de naranjo, NUNCA el SKIP de otro
///   arbol (doc 03 §13).
///
/// Aditivo: NO reemplaza el motor minimo `TreeYieldReferenceCatalog`.
library;

import 'package:bio_g/core/crops/orange_tree/orange_tree_catalog.dart';
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

/// Referencia base de rendimiento por perfil OR (doc 03 §12.4).
class OrangeTreeYieldReference {
  const OrangeTreeYieldReference({
    required this.profileId,
    required this.fullKgPerTree,
    required this.expectedTonPerHa,
    required this.confidenceBase,
    this.commercialFruitPct = const YieldRange(65, 78, 88),
    this.notesEs = const <String>[],
  });

  final String profileId;
  final YieldRange fullKgPerTree;
  final YieldRange expectedTonPerHa;
  final double confidenceBase;

  /// Porcentaje orientativo de fruta comercializable. Contexto de calidad
  /// (doc 03 §0.3, §9). NO entra al calculo principal de kg biologicos.
  final YieldRange commercialFruitPct;
  final List<String> notesEs;
}

/// Estado productivo del naranjo (doc 03 §4).
enum OrangeProductionState {
  nonProductive,
  firstBearing,
  youngBearing,
  fullBearing,
  lowSetOrDropYear,
  oldDeclining,
  unknown,
}

enum OrangeManagementLevel { low, medium, good, high, exceptional }

enum OrangeIrrigationLevel {
  rainfedHumid,
  rainfedDry,
  irregular,
  stable,
  fertigation,
}

/// Calidad de floracion / cuajado / amarre (doc 03 §7.4). El naranjo no depende
/// fuerte de polinizador; el cuello de botella es el estres de floracion/cuajado
/// (calor, agua, frio, sales), no la falta de macho.
enum OrangeBloomSetStatus {
  unknown,
  goodBloomGoodSet,
  goodBloomPoorSet,
  weakBloom,
  frostHeatRainSetLoss,
  fruitSetConfirmed,
}

/// Carga visible de fruto (doc 03 §7.5).
enum OrangeCropLoadStatus { noneVisible, light, balanced, heavy, unknown }

/// Riesgo de calidad comercial (doc 03 §7.6). NO borra kg biologicos; solo baja
/// el porcentaje comercializable y agrega nota.
enum OrangeCommercialQualityRisk { none, mild, moderate, severe }

/// Severidad de estres guardada en memoria multianual (doc 03 §8).
enum OrangeStressSeverity { none, mild, moderate, severe }

/// Memoria de estres del naranjo (doc 03 §8 / doc 04 §5, §10). Solo afecta el
/// rendimiento como modificador; nunca borra historial ni etapa.
class OrangeTreeStressMemory {
  const OrangeTreeStressMemory({
    this.floweringHeatOrFrost = OrangeStressSeverity.none,
    this.fruitSetDrop = OrangeStressSeverity.none,
    this.fruitFillWaterStress = OrangeStressSeverity.none,
    this.salinityOrSodicityStress = OrangeStressSeverity.none,
    this.phytophthoraOrRootDecline = OrangeStressSeverity.none,
    this.hlbOrCanopyDecline = OrangeStressSeverity.none,
    this.nutritionOrLeafStress = OrangeStressSeverity.none,
    this.pestOrDiseaseFruitLoss = OrangeStressSeverity.none,
    this.windHailOrSunburnDamage = OrangeStressSeverity.none,
    this.postHarvestReserveRisk = OrangeStressSeverity.none,
  });

  final OrangeStressSeverity floweringHeatOrFrost;
  final OrangeStressSeverity fruitSetDrop;
  final OrangeStressSeverity fruitFillWaterStress;
  final OrangeStressSeverity salinityOrSodicityStress;
  final OrangeStressSeverity phytophthoraOrRootDecline;
  final OrangeStressSeverity hlbOrCanopyDecline;
  final OrangeStressSeverity nutritionOrLeafStress;
  final OrangeStressSeverity pestOrDiseaseFruitLoss;
  final OrangeStressSeverity windHailOrSunburnDamage;
  final OrangeStressSeverity postHarvestReserveRisk;

  bool get hasAnyStress =>
      floweringHeatOrFrost != OrangeStressSeverity.none ||
      fruitSetDrop != OrangeStressSeverity.none ||
      fruitFillWaterStress != OrangeStressSeverity.none ||
      salinityOrSodicityStress != OrangeStressSeverity.none ||
      phytophthoraOrRootDecline != OrangeStressSeverity.none ||
      hlbOrCanopyDecline != OrangeStressSeverity.none ||
      nutritionOrLeafStress != OrangeStressSeverity.none ||
      pestOrDiseaseFruitLoss != OrangeStressSeverity.none ||
      windHailOrSunburnDamage != OrangeStressSeverity.none ||
      postHarvestReserveRisk != OrangeStressSeverity.none;

  /// Factor de rendimiento combinado 0..1 (doc 03 §8.4). Se toma el evento mas
  /// severo (el cuello de botella del ciclo); no se multiplican todos. Helada/
  /// calor en flor, caida de cuajado, Phytophthora/raiz o HLB/decaimiento
  /// severos pueden justificar 0.25.
  double get yieldFactor01 {
    double factorFor(OrangeStressSeverity s) => switch (s) {
      OrangeStressSeverity.none => 1.0,
      OrangeStressSeverity.mild => 0.88,
      OrangeStressSeverity.moderate => 0.65,
      OrangeStressSeverity.severe => 0.35,
    };
    final factors = <double>[
      factorFor(floweringHeatOrFrost),
      factorFor(fruitSetDrop),
      factorFor(fruitFillWaterStress),
      factorFor(salinityOrSodicityStress),
      factorFor(phytophthoraOrRootDecline),
      factorFor(hlbOrCanopyDecline),
      factorFor(nutritionOrLeafStress),
      factorFor(pestOrDiseaseFruitLoss),
      factorFor(windHailOrSunburnDamage),
      factorFor(postHarvestReserveRisk),
    ];
    double worst = factors.reduce((a, b) => a < b ? a : b);
    final hardHits = <OrangeStressSeverity>[
      floweringHeatOrFrost,
      fruitSetDrop,
      phytophthoraOrRootDecline,
      hlbOrCanopyDecline,
    ];
    if (hardHits.any((s) => s == OrangeStressSeverity.severe) && worst > 0.25) {
      worst = 0.25;
    }
    return worst;
  }
}

/// Sistema de densidad (doc 03 §5.4): define el tope de kg/arbol. El cap evita
/// que la alta densidad multiplique kg/arbol como si cada arbol fuera amplio y
/// aislado (competencia de luz, agua, espacio y manejo de copa).
class OrangeDensitySystem {
  const OrangeDensitySystem(this.id, this.kgPerTreeCap);

  final String id;
  final double kgPerTreeCap;

  static const OrangeDensitySystem extensive = OrangeDensitySystem(
    'extensive_or_old_spacing',
    160,
  );
  static const OrangeDensitySystem traditional = OrangeDensitySystem(
    'traditional_200_300_trees_ha',
    125,
  );
  static const OrangeDensitySystem commercialModerate = OrangeDensitySystem(
    'commercial_300_450_trees_ha',
    100,
  );
  static const OrangeDensitySystem highDensityManaged = OrangeDensitySystem(
    'high_density_450_650_trees_ha',
    75,
  );
  static const OrangeDensitySystem veryHighDensity = OrangeDensitySystem(
    'very_high_density_over_650_trees_ha',
    55,
  );

  static OrangeDensitySystem fromTreesPerHa(double treesPerHa) {
    if (treesPerHa < 200) return extensive;
    if (treesPerHa < 300) return traditional;
    if (treesPerHa < 450) return commercialModerate;
    if (treesPerHa < 650) return highDensityManaged;
    return veryHighDensity;
  }
}

/// Proyeccion de rendimiento aproximada del naranjo.
class OrangeTreeYieldProjection {
  const OrangeTreeYieldProjection({
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
  final OrangeProductionState productionState;
  final double confidence01;

  final YieldRange? kgPerTree;
  final YieldRange? tonPerHa;
  final YieldRange? totalKg;

  /// Contexto de calidad: fruta comercializable (doc 03 §0.3, §9).
  final YieldRange? commercialFruitPct;

  final List<String> notesEs;

  factory OrangeTreeYieldProjection.zero({
    required String profileId,
    required double confidence,
    List<String> notesEs = const <String>[],
  }) => OrangeTreeYieldProjection(
    isProductive: false,
    profileId: profileId,
    productionState: OrangeProductionState.nonProductive,
    confidence01: confidence,
    kgPerTree: YieldRange.zero,
    notesEs: notesEs,
  );
}

/// Tabla de referencia por perfil (doc 03 §12.4). kg de naranja fresca/arbol.
const Map<String, OrangeTreeYieldReference> orangeYieldReferenceByProfile =
    <String, OrangeTreeYieldReference>{
      kOrSkip: OrangeTreeYieldReference(
        profileId: kOrSkip,
        fullKgPerTree: YieldRange(25, 45, 75),
        expectedTonPerHa: YieldRange(8, 16, 28),
        confidenceBase: 0.48,
        commercialFruitPct: YieldRange(60, 75, 85),
        notesEs: <String>[
          'Perfil general: no asume Valencia, Navel, densidad, portainjerto, '
              'riego ni manejo intensivo. El promedio nacional mexicano es '
              'conservador; no sobreestimar.',
        ],
      ),
      kOr01Valencia: OrangeTreeYieldReference(
        profileId: kOr01Valencia,
        fullKgPerTree: YieldRange(35, 60, 95),
        expectedTonPerHa: YieldRange(12, 22, 40),
        confidenceBase: 0.68,
        commercialFruitPct: YieldRange(65, 78, 88),
        notesEs: <String>[
          'Valencia: perfil tardío/de jugo, buen potencial con riego y sanidad; '
              'vigilar cosecha tardía, caída, calibre y calidad de jugo.',
        ],
      ),
      kOr02Navel: OrangeTreeYieldReference(
        profileId: kOr02Navel,
        fullKgPerTree: YieldRange(30, 55, 85),
        expectedTonPerHa: YieldRange(10, 20, 35),
        confidenceBase: 0.62,
        commercialFruitPct: YieldRange(70, 82, 92),
        notesEs: <String>[
          'Navel/ombligo: perfil de mesa; el rendimiento debe leerse junto con '
              'calibre, color, daño externo y porcentaje comercializable.',
        ],
      ),
      kOr03Temprano: OrangeTreeYieldReference(
        profileId: kOr03Temprano,
        fullKgPerTree: YieldRange(25, 50, 80),
        expectedTonPerHa: YieldRange(8, 18, 32),
        confidenceBase: 0.55,
        commercialFruitPct: YieldRange(62, 76, 88),
        notesEs: <String>[
          'Temprano/Hamlin-Pineapple: ventana temprana; vigilar caída temprana, '
              'calibre, color y balance vegetativo-reproductivo.',
        ],
      ),
      kOr04CriolloRegional: OrangeTreeYieldReference(
        profileId: kOr04CriolloRegional,
        fullKgPerTree: YieldRange(15, 35, 65),
        expectedTonPerHa: YieldRange(5, 12, 24),
        confidenceBase: 0.38,
        commercialFruitPct: YieldRange(50, 68, 82),
        notesEs: <String>[
          'Criollo/regional: muy variable por genética, edad, manejo y zona. '
              'Confianza baja; no sobreestimar huertos viejos o de temporal.',
        ],
      ),
      kOr05TropicalCalido: OrangeTreeYieldReference(
        profileId: kOr05TropicalCalido,
        fullKgPerTree: YieldRange(25, 55, 90),
        expectedTonPerHa: YieldRange(9, 20, 35),
        confidenceBase: 0.50,
        commercialFruitPct: YieldRange(58, 74, 86),
        notesEs: <String>[
          'Tropical/clima cálido: puede tener etapas traslapadas y cosecha '
              'variable; vigilar calor, agua, HLB/psílido, caída y raíz.',
        ],
      ),
    };

/// Conversiones oficiales (doc 03 §5.1).
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
/// conservando el historial: los ids previos de cada OR siguen resolviendo a su
/// id canonico (doc 03 §12.5).
String? _normalizeOrangeProfileId(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  if (id == null || id.isEmpty) return id;
  if (id == 'or_01_valencia_tardia' ||
      id == 'or_01_valencia_late' ||
      id == 'or_01_tardia') {
    return kOr01Valencia;
  }
  if (id == 'or_02_navel_mesa' ||
      id == 'or_02_ombligo' ||
      id == 'or_02_washington_navel') {
    return kOr02Navel;
  }
  if (id == 'or_03_temprano_hamlin_pineapple' ||
      id == 'or_03_hamlin' ||
      id == 'or_03_pineapple') {
    return kOr03Temprano;
  }
  if (id == 'or_04_criolla' || id == 'or_04_regional') {
    return kOr04CriolloRegional;
  }
  if (id == 'or_05_tropical' || id == 'or_05_clima_calido') {
    return kOr05TropicalCalido;
  }
  return id;
}

/// Multiplicadores por estado productivo (doc 03 §4.1).
({double low, double expected, double high}) _productionStateFactors(
  OrangeProductionState state,
) {
  return switch (state) {
    OrangeProductionState.nonProductive => (low: 0, expected: 0, high: 0),
    OrangeProductionState.firstBearing => (
      low: 0.05,
      expected: 0.18,
      high: 0.35,
    ),
    OrangeProductionState.youngBearing => (
      low: 0.30,
      expected: 0.60,
      high: 0.85,
    ),
    OrangeProductionState.fullBearing => (low: 0.75, expected: 1.00, high: 1.20),
    OrangeProductionState.lowSetOrDropYear => (
      low: 0.15,
      expected: 0.45,
      high: 0.75,
    ),
    OrangeProductionState.oldDeclining => (
      low: 0.30,
      expected: 0.60,
      high: 0.85,
    ),
    OrangeProductionState.unknown => (low: 0.25, expected: 0.55, high: 0.85),
  };
}

double _managementFactor(OrangeManagementLevel? level) => switch (level) {
  null => 1.0,
  OrangeManagementLevel.low => 0.55,
  OrangeManagementLevel.medium => 0.85,
  OrangeManagementLevel.good => 1.05,
  OrangeManagementLevel.high => 1.18,
  OrangeManagementLevel.exceptional => 1.30,
};

/// Convierte el porcentaje de cuidado del usuario a factor (doc 03 §7.2). 100%
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
  if (p <= 125) return 1.22;
  return 1.25;
}

double _irrigationFactor(OrangeIrrigationLevel? level) => switch (level) {
  null => 1.0,
  OrangeIrrigationLevel.rainfedHumid => 0.75,
  OrangeIrrigationLevel.rainfedDry => 0.50,
  OrangeIrrigationLevel.irregular => 0.72,
  OrangeIrrigationLevel.stable => 1.02,
  OrangeIrrigationLevel.fertigation => 1.12,
};

/// Factor de floracion/cuajado (doc 03 §7.4). Si no se sabe, no destruye el
/// calculo (baja confianza). El naranjo es autofertil: el peso esta en la
/// calidad de la floracion/cuajado, no en la falta de macho.
double _bloomSetFactor(OrangeBloomSetStatus? status) => switch (status) {
  null || OrangeBloomSetStatus.unknown => 1.0,
  OrangeBloomSetStatus.goodBloomGoodSet => 1.08,
  OrangeBloomSetStatus.fruitSetConfirmed => 1.03,
  OrangeBloomSetStatus.goodBloomPoorSet => 0.72,
  OrangeBloomSetStatus.weakBloom => 0.65,
  OrangeBloomSetStatus.frostHeatRainSetLoss => 0.55,
};

/// Factor de carga visible (doc 03 §7.5). Carga heavy sube kg biologicos, pero
/// puede bajar calibre/calidad comercial (se maneja como nota aparte).
double _cropLoadFactor(OrangeCropLoadStatus? status) => switch (status) {
  null || OrangeCropLoadStatus.unknown => 1.0,
  OrangeCropLoadStatus.noneVisible => 0.20,
  OrangeCropLoadStatus.light => 0.55,
  OrangeCropLoadStatus.balanced => 1.0,
  OrangeCropLoadStatus.heavy => 1.05,
};

/// Factor de calidad comercial (doc 03 §7.6). NO borra kg biologicos: solo baja
/// el porcentaje comercializable.
double _commercialQualityFactor(OrangeCommercialQualityRisk? risk) =>
    switch (risk) {
      null || OrangeCommercialQualityRisk.none => 1.0,
      OrangeCommercialQualityRisk.mild => 0.92,
      OrangeCommercialQualityRisk.moderate => 0.78,
      OrangeCommercialQualityRisk.severe => 0.55,
    };

/// Inferencia de estado productivo (doc 03 §4.2). Conservadora.
OrangeProductionState _inferProductionState({
  required String stateId,
  required String stageId,
  OrangeProductionState? explicit,
}) {
  if (explicit != null) return explicit;
  if (stateId == TreeStateIds.newlyPlanted ||
      stateId == TreeStateIds.juvenileNonProductive) {
    return OrangeProductionState.nonProductive;
  }
  if (stateId == TreeStateIds.productiveSeason) {
    return switch (stageId) {
      TreeStageIds.flowering => OrangeProductionState.unknown,
      TreeStageIds.fruitSet => OrangeProductionState.youngBearing,
      TreeStageIds.fruitFill ||
      TreeStageIds.harvestMaturity ||
      TreeStageIds.postHarvest => OrangeProductionState.fullBearing,
      _ => OrangeProductionState.unknown,
    };
  }
  return OrangeProductionState.unknown;
}

/// Estados/etapas que bloquean rendimiento comercial (doc 03 §4.3).
bool _blocksYield(String stateId, String stageId) {
  if (stateId == TreeStateIds.newlyPlanted ||
      stateId == TreeStateIds.juvenileNonProductive) {
    return true;
  }
  return stageId == TreeStageIds.plantingTransplant ||
      stageId == TreeStageIds.rootEstablishment ||
      stageId == TreeStageIds.juvenileVegetative;
}

/// Calcula la proyeccion aproximada de rendimiento del naranjo (doc 03 §10, §13).
OrangeTreeYieldProjection resolveOrangeTreeYield({
  required String? profileId,
  required String? perennialStateId,
  required String? phenologyStageId,
  double? treesPerHa,
  double? hectares,
  int? treeCount,
  OrangeProductionState? productionState,
  OrangeManagementLevel? managementLevel,
  double? carePercent,
  OrangeIrrigationLevel? irrigationLevel,
  OrangeBloomSetStatus? bloomSetStatus,
  OrangeCropLoadStatus? cropLoadStatus,
  OrangeCommercialQualityRisk? commercialQualityRisk,
  OrangeTreeStressMemory? stressMemory,
}) {
  final stateId = normalizeTreeStateId(perennialStateId);
  final stageId = normalizeTreeStageId(phenologyStageId);
  final ref =
      orangeYieldReferenceByProfile[_normalizeOrangeProfileId(profileId)] ??
      orangeYieldReferenceByProfile[kOrSkip]!;

  // 1. Bloqueo no productivo.
  if (_blocksYield(stateId, stageId)) {
    return OrangeTreeYieldProjection.zero(
      profileId: ref.profileId,
      confidence: 0.85,
      notesEs: const <String>[
        'Todavía no proyectamos cosecha: el naranjo está en formación. Importa '
            'más formar raíz, copa, hoja sana y estructura que forzar producción.',
      ],
    );
  }

  final state = _inferProductionState(
    stateId: stateId,
    stageId: stageId,
    explicit: productionState,
  );
  if (state == OrangeProductionState.nonProductive) {
    return OrangeTreeYieldProjection.zero(
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
  // se usa carePercent como principal cuando existe (doc 03 §7.2).
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
      OrangeDensitySystem.fromTreesPerHa(density).kgPerTreeCap,
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

  // 8. Confianza (doc 03 §10.2).
  double confidence = ref.confidenceBase;
  if (density == null) confidence -= 0.15;
  if (state == OrangeProductionState.unknown) confidence -= 0.10;
  if (stageId == TreeStageIds.unknown) confidence -= 0.05;
  if (stressMemory != null && stressMemory.hasAnyStress) confidence -= 0.10;
  if (irrigationLevel == null &&
      (stageId == TreeStageIds.fruitSet || stageId == TreeStageIds.fruitFill)) {
    confidence -= 0.05;
  }
  if ((stageId == TreeStageIds.flowering || stageId == TreeStageIds.fruitSet) &&
      bloomSetStatus == null) {
    confidence -= 0.05;
  }
  if (ref.profileId == kOr04CriolloRegional && confidence > 0.55) {
    confidence = 0.55;
  }
  if (density != null &&
      stageId != TreeStageIds.unknown &&
      (cropLoadStatus == OrangeCropLoadStatus.balanced ||
          cropLoadStatus == OrangeCropLoadStatus.heavy)) {
    confidence += 0.05;
  }
  confidence = confidence.clamp(0.05, 0.95);

  // 9. Notas.
  final notes = <String>[...ref.notesEs];
  if (ref.profileId == kOrSkip) {
    notes.add(
      'Este cálculo usa un perfil general de naranjo. Puede mejorar si eliges '
      'Valencia, Navel, temprano, criollo/regional o tropical/clima cálido.',
    );
  }
  if (density == null) {
    notes.add(
      'Sin densidad ni número de árboles no estimamos t/ha con precisión; '
      'indica árboles/ha o marco de plantación para mejorar la proyección.',
    );
  }
  if (commercialQualityRisk != null &&
      commercialQualityRisk != OrangeCommercialQualityRisk.none) {
    notes.add(
      'Puede haber kg biológicos, pero parte de la fruta puede bajar de '
      'categoría por calibre, color, daño externo, caída o sanidad.',
    );
  }
  if (stress < 1.0) {
    notes.add(
      'Ajustamos a la baja por memoria de estrés. Una floración golpeada, agua, '
      'salinidad, raíz o sanidad pueden pegarle al cuajado y al calibre.',
    );
  }
  if (tonHa != null && tonHa.expected > 40) {
    notes.add(
      'Proyección alta: confirma densidad real, árboles faltantes, manejo, '
      'riego, calibre, fruta comercializable y sanidad antes de tomarlo como '
      'expectativa.',
    );
  }
  if (tonHa != null &&
      tonHa.expected < 8 &&
      state == OrangeProductionState.fullBearing) {
    notes.add(
      'Proyección baja para árbol productivo: revisar floración/cuajado, agua, '
      'salinidad, raíz, HLB/gomosis/Phytophthora, defoliación y postcosecha.',
    );
  }

  return OrangeTreeYieldProjection(
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
