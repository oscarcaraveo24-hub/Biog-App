/// Rendimiento aproximado de la Pera (doc 03 oficial).
///
/// Reglas no negociables:
/// - El rendimiento de un árbol NO se calcula como cultivo anual: se estima por
///   kg/árbol + árboles/ha + estado productivo + perfil + densidad + manejo +
///   memoria de estrés + confianza.
/// - Es APROXIMADO y en rango (bajo / esperado / alto). Nunca es promesa.
/// - Estados no productivos (recién plantado, juvenil) y etapas de
///   establecimiento proyectan 0.
/// - `post_harvest` NO cierra el cultivo ni borra historial.
/// - En pera la POLINIZACIÓN pesa más que en muchos frutales: sin polinizador
///   compatible o con mal clima en floración el rango baja (doc 03 §6, §9, §11).
/// - El fallback de perfil es SIEMPRE PR-SKIP de pera, NUNCA AP-SKIP de manzano
///   (doc 03 §0.1).
///
/// Aditivo: NO reemplaza el motor mínimo `TreeYieldReferenceCatalog`. La
/// consolidación queda como follow-up documentado.
library;

import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
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

  /// Limita cada extremo a un tope (cap kg/árbol por densidad).
  YieldRange cappedAt(double cap) => YieldRange(
    low > cap ? cap : low,
    expected > cap ? cap : expected,
    high > cap ? cap : high,
  );

  static const YieldRange zero = YieldRange(0, 0, 0);
}

/// Referencia base de rendimiento por perfil PR (doc 03 §10.1).
class PearTreeYieldReference {
  const PearTreeYieldReference({
    required this.profileId,
    required this.fullKgPerTree,
    required this.expectedTonPerHa,
    required this.confidenceBase,
    this.notesEs = const <String>[],
  });

  final String profileId;
  final YieldRange fullKgPerTree;
  final YieldRange expectedTonPerHa;
  final double confidenceBase;
  final List<String> notesEs;
}

/// Estado productivo del árbol (doc 03 §6 / §10.2).
enum PearProductionState {
  nonProductive,
  firstBearing,
  youngBearing,
  fullBearing,
  alternateLowYear,
  unknown,
}

enum PearManagementLevel { low, medium, good, high, exceptional }

enum PearIrrigationLevel { rainfed, irregular, stable, fertigation }

/// Severidad de estrés guardada en memoria multianual.
enum PearStressSeverity { none, mild, moderate, severe }

/// Memoria de estrés de la pera (doc 03 §9 / doc 04 §8 / doc 05 §15). Solo
/// afecta el rendimiento como modificador; nunca borra historial ni etapa.
class PearTreeStressMemory {
  const PearTreeStressMemory({
    this.floweringFrost = PearStressSeverity.none,
    this.lowPollination = PearStressSeverity.none,
    this.fruitSetWaterStress = PearStressSeverity.none,
    this.fruitFillWaterStress = PearStressSeverity.none,
    this.fireBlight = PearStressSeverity.none,
    this.pearPsylla = PearStressSeverity.none,
    this.hailDamage = PearStressSeverity.none,
    this.alternateBearing = PearStressSeverity.none,
    this.postHarvestReserveRisk = PearStressSeverity.none,
  });

  final PearStressSeverity floweringFrost;
  final PearStressSeverity lowPollination;
  final PearStressSeverity fruitSetWaterStress;
  final PearStressSeverity fruitFillWaterStress;
  final PearStressSeverity fireBlight;
  final PearStressSeverity pearPsylla;
  final PearStressSeverity hailDamage;
  final PearStressSeverity alternateBearing;
  final PearStressSeverity postHarvestReserveRisk;

  bool get hasAnyStress =>
      floweringFrost != PearStressSeverity.none ||
      lowPollination != PearStressSeverity.none ||
      fruitSetWaterStress != PearStressSeverity.none ||
      fruitFillWaterStress != PearStressSeverity.none ||
      fireBlight != PearStressSeverity.none ||
      pearPsylla != PearStressSeverity.none ||
      hailDamage != PearStressSeverity.none ||
      alternateBearing != PearStressSeverity.none ||
      postHarvestReserveRisk != PearStressSeverity.none;

  /// Factor de rendimiento combinado 0..1 (doc 03 §9). Se toma el evento más
  /// severo (el cuello de botella del ciclo).
  double get yieldFactor01 {
    double factorFor(PearStressSeverity s) => switch (s) {
      PearStressSeverity.none => 1.0,
      PearStressSeverity.mild => 0.92,
      PearStressSeverity.moderate => 0.72,
      // Helada/granizo/fuego bacteriano fuerte: reducción fuerte.
      PearStressSeverity.severe => 0.30,
    };
    final factors = <double>[
      factorFor(floweringFrost),
      factorFor(lowPollination),
      factorFor(fruitSetWaterStress),
      factorFor(fruitFillWaterStress),
      factorFor(fireBlight),
      factorFor(pearPsylla),
      factorFor(hailDamage),
      factorFor(alternateBearing),
      factorFor(postHarvestReserveRisk),
    ];
    return factors.reduce((a, b) => a < b ? a : b);
  }
}

/// Sistema de densidad (doc 03 §5 / §10.3): define el tope de kg/árbol.
class PearDensitySystem {
  const PearDensitySystem(this.id, this.kgPerTreeCap);

  final String id;
  final double kgPerTreeCap;

  static const PearDensitySystem backyardOrchard = PearDensitySystem(
    'backyard_orchard',
    140,
  );
  static const PearDensitySystem traditionalExtensive = PearDensitySystem(
    'traditional_extensive',
    130,
  );
  static const PearDensitySystem traditionalCommercial = PearDensitySystem(
    'traditional_commercial',
    100,
  );
  static const PearDensitySystem semiIntensive = PearDensitySystem(
    'semi_intensive',
    85,
  );
  static const PearDensitySystem mediumModern = PearDensitySystem(
    'medium_modern',
    60,
  );
  static const PearDensitySystem highDensity = PearDensitySystem(
    'high_density',
    38,
  );
  static const PearDensitySystem veryHighDensity = PearDensitySystem(
    'very_high_density',
    25,
  );

  static PearDensitySystem fromTreesPerHa(double treesPerHa) {
    if (treesPerHa < 400) return traditionalExtensive;
    if (treesPerHa < 700) return traditionalCommercial;
    if (treesPerHa < 1200) return semiIntensive;
    if (treesPerHa < 1800) return mediumModern;
    if (treesPerHa < 3000) return highDensity;
    return veryHighDensity;
  }
}

/// Proyección de rendimiento aproximada de la pera.
class PearTreeYieldProjection {
  const PearTreeYieldProjection({
    required this.isProductive,
    required this.profileId,
    required this.productionState,
    required this.confidence01,
    this.kgPerTree,
    this.tonPerHa,
    this.totalKg,
    this.notesEs = const <String>[],
  });

  final bool isProductive;
  final String profileId;
  final PearProductionState productionState;
  final double confidence01;

  final YieldRange? kgPerTree;
  final YieldRange? tonPerHa;
  final YieldRange? totalKg;

  final List<String> notesEs;

  factory PearTreeYieldProjection.zero({
    required String profileId,
    required double confidence,
    List<String> notesEs = const <String>[],
  }) => PearTreeYieldProjection(
    isProductive: false,
    profileId: profileId,
    productionState: PearProductionState.nonProductive,
    confidence01: confidence,
    kgPerTree: YieldRange.zero,
    notesEs: notesEs,
  );
}

/// Tabla de referencia por perfil (doc 03 §10.1).
const Map<String, PearTreeYieldReference>
pearYieldReferenceByProfile = <String, PearTreeYieldReference>{
  kPrSkip: PearTreeYieldReference(
    profileId: kPrSkip,
    fullKgPerTree: YieldRange(20, 35, 55),
    expectedTonPerHa: YieldRange(6, 18, 35),
    confidenceBase: 0.42,
    notesEs: <String>[
      'Perfil general: no asume Bartlett, Anjou, alta densidad ni '
          'polinizador. En México el promedio nacional ronda ~7.5 t/ha.',
    ],
  ),
  kPr01BartlettWilliams: PearTreeYieldReference(
    profileId: kPr01BartlettWilliams,
    fullKgPerTree: YieldRange(25, 55, 85),
    expectedTonPerHa: YieldRange(12, 38, 70),
    confidenceBase: 0.65,
    notesEs: <String>[
      'Bartlett/Williams: 45-65 t/ha en sistemas comerciales maduros con '
          'riego y polinizador; 70 t/ha solo intensivo validado.',
    ],
  ),
  kPr02Anjou: PearTreeYieldReference(
    profileId: kPr02Anjou,
    fullKgPerTree: YieldRange(20, 45, 75),
    expectedTonPerHa: YieldRange(10, 32, 65),
    confidenceBase: 0.55,
    notesEs: <String>[
      'Anjou: pera de conservación; como polinizador de Bartlett rinde '
          'menos por bloque. Calidad/almacenaje pesan en valor, no en t/ha.',
    ],
  ),
  kPr03Bosc: PearTreeYieldReference(
    profileId: kPr03Bosc,
    fullKgPerTree: YieldRange(20, 45, 70),
    expectedTonPerHa: YieldRange(8, 30, 60),
    confidenceBase: 0.45,
    notesEs: <String>[
      'Bosc: nicho/PNW; no subir por "premium" (premium es precio, no '
          't/ha). Sensible a fuego bacteriano.',
    ],
  ),
  kPr04SeckelComice: PearTreeYieldReference(
    profileId: kPr04SeckelComice,
    fullKgPerTree: YieldRange(12, 30, 55),
    expectedTonPerHa: YieldRange(5, 22, 50),
    confidenceBase: 0.42,
    notesEs: <String>[
      'Seckel/Comice: premium/nicho; el volumen es menor y la calidad '
          'organoléptica pesa más que la tonelada.',
    ],
  ),
  kPr05KiefferRustic: PearTreeYieldReference(
    profileId: kPr05KiefferRustic,
    fullKgPerTree: YieldRange(25, 50, 90),
    expectedTonPerHa: YieldRange(7, 28, 55),
    confidenceBase: 0.45,
    notesEs: <String>[
      'Kieffer/rústica: árboles grandes con muchos kg/árbol pero densidad y '
          'calidad variables; confianza baja-media.',
    ],
  ),
};

/// Conversiones oficiales (doc 03 §3).
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

/// Multiplicadores por estado productivo (doc 03 §10.2): low/expected/high.
({double low, double expected, double high}) _productionStateFactors(
  PearProductionState state,
) {
  return switch (state) {
    PearProductionState.nonProductive => (low: 0, expected: 0, high: 0),
    PearProductionState.firstBearing => (low: 0.05, expected: 0.15, high: 0.28),
    PearProductionState.youngBearing => (low: 0.25, expected: 0.50, high: 0.72),
    PearProductionState.fullBearing => (low: 0.75, expected: 1.00, high: 1.15),
    PearProductionState.alternateLowYear => (
      low: 0.20,
      expected: 0.50,
      high: 0.75,
    ),
    PearProductionState.unknown => (low: 0.30, expected: 0.55, high: 0.85),
  };
}

double _managementFactor(PearManagementLevel? level) => switch (level) {
  null => 1.0,
  PearManagementLevel.low => 0.58,
  PearManagementLevel.medium => 0.88,
  PearManagementLevel.good => 1.07,
  PearManagementLevel.high => 1.25,
  PearManagementLevel.exceptional => 1.42,
};

double _irrigationFactor(PearIrrigationLevel? level) => switch (level) {
  null => 1.0,
  PearIrrigationLevel.rainfed => 0.60,
  PearIrrigationLevel.irregular => 0.80,
  PearIrrigationLevel.stable => 1.02,
  PearIrrigationLevel.fertigation => 1.12,
};

/// Modificador de polinización (doc 03 §9, §11). En pera es más fuerte que en
/// manzano. `fruitVisible` (cuajado confirmado en fruit_fill/harvest) eleva el
/// piso porque el amarre ya ocurrió.
double _pollinationFactor({
  required bool? pollinatorKnown,
  required bool fruitVisible,
  required String stageId,
}) {
  if (fruitVisible) {
    // El cuajado ya pasó: la polinización deja de ser cuello de botella.
    return switch (pollinatorKnown) {
      true => 1.06,
      false => 0.92,
      null => 0.95,
    };
  }
  final isBloomWindow =
      stageId == TreeStageIds.flowering || stageId == TreeStageIds.fruitSet;
  if (!isBloomWindow) return 1.0;
  return switch (pollinatorKnown) {
    true => 1.06,
    false => 0.62,
    null => 0.85,
  };
}

PearProductionState _inferProductionState({
  required String stateId,
  required String stageId,
  PearProductionState? explicit,
}) {
  if (explicit != null) return explicit;
  return switch (stateId) {
    TreeStateIds.newlyPlanted ||
    TreeStateIds.juvenileNonProductive => PearProductionState.nonProductive,
    TreeStateIds.productiveSeason => PearProductionState.fullBearing,
    TreeStateIds.established => PearProductionState.unknown,
    _ => PearProductionState.unknown,
  };
}

/// Estados/etapas que bloquean rendimiento comercial (doc 03 §1 / §6).
bool _blocksYield(String stateId, String stageId) {
  if (stateId == TreeStateIds.newlyPlanted ||
      stateId == TreeStateIds.juvenileNonProductive) {
    return true;
  }
  return stageId == TreeStageIds.plantingTransplant ||
      stageId == TreeStageIds.rootEstablishment ||
      stageId == TreeStageIds.juvenileVegetative;
}

/// Calcula la proyección aproximada de rendimiento de la pera (doc 03 §8-§11).
PearTreeYieldProjection resolvePearTreeYield({
  required String? profileId,
  required String? perennialStateId,
  required String? phenologyStageId,
  double? treesPerHa,
  double? hectares,
  int? treeCount,
  PearProductionState? productionState,
  PearManagementLevel? managementLevel,
  PearIrrigationLevel? irrigationLevel,
  bool? pollinatorKnown,
  bool? fruitVisible,
  PearTreeStressMemory? stressMemory,
}) {
  final stateId = normalizeTreeStateId(perennialStateId);
  final stageId = normalizeTreeStageId(phenologyStageId);
  final ref =
      pearYieldReferenceByProfile[profileId?.trim().toLowerCase()] ??
      pearYieldReferenceByProfile[kPrSkip]!;

  // 1. Bloqueo no productivo.
  if (_blocksYield(stateId, stageId)) {
    return PearTreeYieldProjection.zero(
      profileId: ref.profileId,
      confidence: 0.85,
      notesEs: const <String>[
        'No proyectamos cosecha todavía porque tu peral aún está en formación. '
            'Importa más formar raíz, estructura y reservas.',
      ],
    );
  }

  final state = _inferProductionState(
    stateId: stateId,
    stageId: stageId,
    explicit: productionState,
  );
  if (state == PearProductionState.nonProductive) {
    return PearTreeYieldProjection.zero(
      profileId: ref.profileId,
      confidence: 0.85,
    );
  }

  // 2. Fruta visible: en llenado/madurez el cuajado ya ocurrió (doc 03 §11).
  final bool resolvedFruitVisible =
      fruitVisible ??
      (stageId == TreeStageIds.fruitFill ||
          stageId == TreeStageIds.harvestMaturity);

  // 3. Densidad efectiva.
  final density =
      treesPerHa ??
      ((treeCount != null && hectares != null && hectares > 0)
          ? treeCount / hectares
          : null);

  // 4. Modificadores.
  final sf = _productionStateFactors(state);
  final mgmt = _managementFactor(managementLevel);
  final irr = _irrigationFactor(irrigationLevel);
  final poll = _pollinationFactor(
    pollinatorKnown: pollinatorKnown,
    fruitVisible: resolvedFruitVisible,
    stageId: stageId,
  );
  final stress = stressMemory?.yieldFactor01 ?? 1.0;
  final commonFactor = mgmt * irr * poll * stress;

  // 5. kg/árbol con factores de estado + comunes, luego tope por densidad.
  YieldRange kgTree = ref.fullKgPerTree
      .scaleEach(sf.low, sf.expected, sf.high)
      .scale(commonFactor);
  if (density != null) {
    kgTree = kgTree.cappedAt(
      PearDensitySystem.fromTreesPerHa(density).kgPerTreeCap,
    );
  }

  // 6. t/ha desde kg/árbol y densidad.
  final tonHa = density == null
      ? null
      : YieldRange(
          tonHaFromKgTree(kgTree.low, density),
          tonHaFromKgTree(kgTree.expected, density),
          tonHaFromKgTree(kgTree.high, density),
        );

  // 7. Total kg si hay número de árboles.
  final totalKg = treeCount == null ? null : kgTree.scale(treeCount.toDouble());

  // 8. Confianza.
  double confidence = ref.confidenceBase;
  if (density == null) confidence -= 0.15;
  if (state == PearProductionState.unknown) confidence -= 0.10;
  if (stageId == TreeStageIds.unknown) confidence -= 0.05;
  if (resolvedFruitVisible) confidence += 0.08;
  if (stressMemory != null && stressMemory.hasAnyStress) confidence -= 0.10;
  confidence = confidence.clamp(0.05, 0.95);

  final notes = <String>[...ref.notesEs];
  if (ref.profileId == kPrSkip) {
    notes.add(
      'Este cálculo usa un perfil general de pera. Puede mejorar si eliges '
      'Bartlett/Williams, Anjou, Bosc, Seckel/Comice o Kieffer/rústica.',
    );
  }
  if (density == null) {
    notes.add(
      'Sin densidad ni número de árboles no estimamos t/ha; indica árboles/ha '
      'o marco de plantación para más precisión.',
    );
  }
  if (poll < 1.0 && !resolvedFruitVisible) {
    notes.add(
      'El rendimiento aún es incierto. Muchos perales necesitan otra variedad '
      'compatible floreando cerca para amarrar bien.',
    );
  }
  if (stress < 1.0) {
    notes.add(
      'Ajustamos a la baja por estrés guardado (helada, mala polinización, '
      'fuego bacteriano, sequía o alternancia). El ciclo puede moverse mucho.',
    );
  }

  return PearTreeYieldProjection(
    isProductive: true,
    profileId: ref.profileId,
    productionState: state,
    confidence01: confidence,
    kgPerTree: kgTree,
    tonPerHa: tonHa,
    totalKg: totalKg,
    notesEs: notes,
  );
}
