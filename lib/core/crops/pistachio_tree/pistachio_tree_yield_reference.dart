/// Rendimiento aproximado del Pistache (doc 03 oficial).
///
/// Reglas no negociables:
/// - El rendimiento de pistache NO se calcula como cultivo anual: se estima por
///   kg de pistache seco con cascara/arbol promedio del huerto + arboles/ha +
///   estado productivo + perfil + densidad + manejo + riego + polinizacion
///   macho-hembra + alternancia + memoria de estres + confianza.
/// - Es APROXIMADO y en rango (bajo / esperado / alto). Nunca es promesa.
/// - Estados no productivos y etapas de establecimiento proyectan 0.
/// - `post_harvest` NO cierra el cultivo ni borra historial.
/// - La salida principal es kg de pistache seco con cascara/arbol y t/ha, NO
///   "frutos frescos" ni numero de pistaches (doc 03 §0.2, §0.3).
/// - En pistache hay machos y hembras. Si el usuario no separa el conteo, los
///   kg/arbol son conservadores e incluyen dilucion de machos (doc 03 §0.2).
/// - La polinizacion macho-hembra por viento es cuello de botella central: pesa
///   mas y distinto que en nogal (doc 03 §0.5, §8.3).
/// - El fallback de perfil es SIEMPRE PS-SKIP de pistache, NUNCA AP-SKIP de
///   manzano, PR-SKIP de pera, DZ-SKIP de durazno ni NG-SKIP de nogal
///   (doc 03 §13).
///
/// Aditivo: NO reemplaza el motor minimo `TreeYieldReferenceCatalog`.
library;

import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_catalog.dart';
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

/// Referencia base de rendimiento por perfil PS (doc 03 §7).
class PistachioTreeYieldReference {
  const PistachioTreeYieldReference({
    required this.profileId,
    required this.fullKgPerTree,
    required this.expectedTonPerHa,
    required this.confidenceBase,
    this.splitPct = const YieldRange(65, 80, 88),
    this.notesEs = const <String>[],
  });

  final String profileId;
  final YieldRange fullKgPerTree;
  final YieldRange expectedTonPerHa;
  final double confidenceBase;

  /// Porcentaje orientativo de frutos abiertos/split. Contexto de calidad
  /// (doc 03 §0.3). NO entra al calculo principal de kg.
  final YieldRange splitPct;
  final List<String> notesEs;
}

/// Estado productivo del pistache (doc 03 §5).
enum PistachioProductionState {
  nonProductive,
  firstBearing,
  youngBearing,
  fullBearing,
  alternateLowYear,
  unknown,
}

enum PistachioManagementLevel { low, medium, good, high, exceptional }

enum PistachioIrrigationLevel {
  rainfed,
  irregular,
  stable,
  regulatedDeficit,
  fertigation,
}

/// Estado de polinizacion macho-hembra (doc 03 §8.3). Cuello de botella central
/// del pistache: pesa mas que en pepita/hueso y diferente al nogal.
enum PistachioPollinationStatus {
  unknown,
  compatibleMalePresent,
  malePresentButMismatchRisk,
  lowMaleRatio,
  noMaleKnown,
}

/// Ciclo de carga / alternancia (doc 03 §8.4).
enum PistachioBearingCycle { unknown, onYear, offYear, balanced }

/// Severidad de estres guardada en memoria multianual (doc 03 §9.1).
enum PistachioStressSeverity { none, mild, moderate, severe }

/// Memoria de estres del pistache (doc 03 §9 / doc 04 §9). Solo afecta el
/// rendimiento como modificador; nunca borra historial ni etapa.
class PistachioTreeStressMemory {
  const PistachioTreeStressMemory({
    this.insufficientWinterChill = PistachioStressSeverity.none,
    this.floweringFrost = PistachioStressSeverity.none,
    this.bloomRainOrHumidity = PistachioStressSeverity.none,
    this.pollinationMismatch = PistachioStressSeverity.none,
    this.fruitSetDrop = PistachioStressSeverity.none,
    this.fruitFillWaterStress = PistachioStressSeverity.none,
    this.salinityOrBoronStress = PistachioStressSeverity.none,
    this.heatStress = PistachioStressSeverity.none,
    this.navelOrangewormOrInsectDamage = PistachioStressSeverity.none,
    this.alternateBearing = PistachioStressSeverity.none,
    this.postHarvestReserveRisk = PistachioStressSeverity.none,
  });

  final PistachioStressSeverity insufficientWinterChill;
  final PistachioStressSeverity floweringFrost;
  final PistachioStressSeverity bloomRainOrHumidity;
  final PistachioStressSeverity pollinationMismatch;
  final PistachioStressSeverity fruitSetDrop;
  final PistachioStressSeverity fruitFillWaterStress;
  final PistachioStressSeverity salinityOrBoronStress;
  final PistachioStressSeverity heatStress;
  final PistachioStressSeverity navelOrangewormOrInsectDamage;
  final PistachioStressSeverity alternateBearing;
  final PistachioStressSeverity postHarvestReserveRisk;

  bool get hasAnyStress =>
      insufficientWinterChill != PistachioStressSeverity.none ||
      floweringFrost != PistachioStressSeverity.none ||
      bloomRainOrHumidity != PistachioStressSeverity.none ||
      pollinationMismatch != PistachioStressSeverity.none ||
      fruitSetDrop != PistachioStressSeverity.none ||
      fruitFillWaterStress != PistachioStressSeverity.none ||
      salinityOrBoronStress != PistachioStressSeverity.none ||
      heatStress != PistachioStressSeverity.none ||
      navelOrangewormOrInsectDamage != PistachioStressSeverity.none ||
      alternateBearing != PistachioStressSeverity.none ||
      postHarvestReserveRisk != PistachioStressSeverity.none;

  /// Factor de rendimiento combinado 0..1 (doc 03 §9.3). Se toma el evento mas
  /// severo (el cuello de botella del ciclo); no se multiplican todos. Helada en
  /// flor, lluvia/HR en floracion, mala polinizacion o navel orangeworm severos
  /// pueden justificar 0.25.
  double get yieldFactor01 {
    double factorFor(PistachioStressSeverity s) => switch (s) {
      PistachioStressSeverity.none => 1.0,
      PistachioStressSeverity.mild => 0.88,
      PistachioStressSeverity.moderate => 0.65,
      PistachioStressSeverity.severe => 0.35,
    };
    final factors = <double>[
      factorFor(insufficientWinterChill),
      factorFor(floweringFrost),
      factorFor(bloomRainOrHumidity),
      factorFor(pollinationMismatch),
      factorFor(fruitSetDrop),
      factorFor(fruitFillWaterStress),
      factorFor(salinityOrBoronStress),
      factorFor(heatStress),
      factorFor(navelOrangewormOrInsectDamage),
      factorFor(alternateBearing),
      factorFor(postHarvestReserveRisk),
    ];
    double worst = factors.reduce((a, b) => a < b ? a : b);
    final hardHits = <PistachioStressSeverity>[
      floweringFrost,
      bloomRainOrHumidity,
      pollinationMismatch,
      navelOrangewormOrInsectDamage,
    ];
    if (hardHits.any((s) => s == PistachioStressSeverity.severe) &&
        worst > 0.25) {
      worst = 0.25;
    }
    return worst;
  }
}

/// Sistema de densidad (doc 03 §6.4): define el tope de kg/arbol. El cap evita
/// que 400-600 arboles/ha multipliquen kg/arbol como si cada arbol fuera
/// aislado (sombra, competencia, machos improductivos en el conteo).
class PistachioDensitySystem {
  const PistachioDensitySystem(this.id, this.kgPerTreeCap);

  final String id;
  final double kgPerTreeCap;

  static const PistachioDensitySystem extensive = PistachioDensitySystem(
    'extensive_or_wide_spacing',
    24,
  );
  static const PistachioDensitySystem traditionalCommercial =
      PistachioDensitySystem('traditional_commercial', 18);
  static const PistachioDensitySystem standardCaliforniaLike =
      PistachioDensitySystem('standard_300_350_trees_ha', 14);
  static const PistachioDensitySystem mediumHighDensity =
      PistachioDensitySystem('medium_high_density', 11);
  static const PistachioDensitySystem highDensityManaged =
      PistachioDensitySystem('high_density_managed', 9);

  static PistachioDensitySystem fromTreesPerHa(double treesPerHa) {
    if (treesPerHa < 220) return extensive;
    if (treesPerHa < 300) return traditionalCommercial;
    if (treesPerHa < 380) return standardCaliforniaLike;
    if (treesPerHa < 520) return mediumHighDensity;
    return highDensityManaged;
  }
}

/// Proyeccion de rendimiento aproximada del pistache.
class PistachioTreeYieldProjection {
  const PistachioTreeYieldProjection({
    required this.isProductive,
    required this.profileId,
    required this.productionState,
    required this.confidence01,
    this.kgPerTree,
    this.tonPerHa,
    this.totalKg,
    this.splitPct,
    this.notesEs = const <String>[],
  });

  final bool isProductive;
  final String profileId;
  final PistachioProductionState productionState;
  final double confidence01;

  final YieldRange? kgPerTree;
  final YieldRange? tonPerHa;
  final YieldRange? totalKg;

  /// Contexto de calidad: frutos abiertos/split (doc 03 §0.3).
  final YieldRange? splitPct;

  final List<String> notesEs;

  factory PistachioTreeYieldProjection.zero({
    required String profileId,
    required double confidence,
    List<String> notesEs = const <String>[],
  }) => PistachioTreeYieldProjection(
    isProductive: false,
    profileId: profileId,
    productionState: PistachioProductionState.nonProductive,
    confidence01: confidence,
    kgPerTree: YieldRange.zero,
    notesEs: notesEs,
  );
}

/// Tabla de referencia por perfil (doc 03 §7). kg de pistache seco con cascara.
const Map<String, PistachioTreeYieldReference>
pistachioYieldReferenceByProfile = <String, PistachioTreeYieldReference>{
  kPsSkip: PistachioTreeYieldReference(
    profileId: kPsSkip,
    fullKgPerTree: YieldRange(4, 9, 18),
    expectedTonPerHa: YieldRange(0.8, 1.8, 3.0),
    confidenceBase: 0.44,
    splitPct: YieldRange(60, 75, 85),
    notesEs: <String>[
      'Perfil general: no asume variedad, macho compatible, portainjerto, riego '
          'ni densidad. No sobreestimar si el usuario solo sabe que es pistache.',
    ],
  ),
  kPs01KermanPeters: PistachioTreeYieldReference(
    profileId: kPs01KermanPeters,
    fullKgPerTree: YieldRange(5, 10, 20),
    expectedTonPerHa: YieldRange(1.0, 2.5, 3.6),
    confidenceBase: 0.70,
    splitPct: YieldRange(60, 75, 84),
    notesEs: <String>[
      'Kerman/Peters: estandar tradicional. Buen rendimiento si hay frio y '
          'sincronia; mas riesgo de cerrado/blanks que Golden Hills/Lost Hills.',
    ],
  ),
  kPs02GoldenHillsRandy: PistachioTreeYieldReference(
    profileId: kPs02GoldenHillsRandy,
    fullKgPerTree: YieldRange(6, 12, 22),
    expectedTonPerHa: YieldRange(1.2, 2.8, 4.0),
    confidenceBase: 0.74,
    splitPct: YieldRange(70, 82, 90),
    notesEs: <String>[
      'Golden Hills/Randy: cultivar moderno temprano, alto potencial y buen '
          'porcentaje de split si el polinizador coincide.',
    ],
  ),
  kPs03LostHillsRandy: PistachioTreeYieldReference(
    profileId: kPs03LostHillsRandy,
    fullKgPerTree: YieldRange(6, 12, 23),
    expectedTonPerHa: YieldRange(1.3, 2.8, 4.1),
    confidenceBase: 0.72,
    splitPct: YieldRange(70, 82, 90),
    notesEs: <String>[
      'Lost Hills/Randy: nuez grande, buen split y menor alternancia reportada '
          'en ensayos; revisar loose shells/handling y sitio.',
    ],
  ),
  kPs04SiroraCompatible: PistachioTreeYieldReference(
    profileId: kPs04SiroraCompatible,
    fullKgPerTree: YieldRange(4, 9, 18),
    expectedTonPerHa: YieldRange(0.8, 2.0, 3.2),
    confidenceBase: 0.48,
    splitPct: YieldRange(62, 76, 86),
    notesEs: <String>[
      'Sirora/compatible: perfil adaptable con evidencia local variable; no '
          'prometer rendimiento alto sin validacion de zona y macho.',
    ],
  ),
  kPs05LarnakaMateurLowChill: PistachioTreeYieldReference(
    profileId: kPs05LarnakaMateurLowChill,
    fullKgPerTree: YieldRange(3.5, 8, 16),
    expectedTonPerHa: YieldRange(0.7, 1.8, 3.0),
    confidenceBase: 0.45,
    splitPct: YieldRange(58, 72, 84),
    notesEs: <String>[
      'Larnaka/Mateur bajo-frio relativo: usar donde Kerman no ajusta por frio, '
          'pero no asumir que no requiere dormancia ni polinizador compatible.',
    ],
  ),
};

/// Conversiones oficiales (doc 03 §4.1).
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
/// conservando el historial: los ids previos de cada PS siguen resolviendo a su
/// id canonico (doc 03 §13).
String? _normalizePistachioProfileId(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  if (id == null || id.isEmpty) return id;
  if (id == 'ps_01_kerman') return kPs01KermanPeters;
  if (id == 'ps_02_golden_hills' || id == 'ps_02_golden') {
    return kPs02GoldenHillsRandy;
  }
  if (id == 'ps_03_lost_hills' || id == 'ps_03_lost') {
    return kPs03LostHillsRandy;
  }
  if (id == 'ps_04_sirora') return kPs04SiroraCompatible;
  if (id == 'ps_05_larnaka_mateur' ||
      id == 'ps_05_low_chill' ||
      id == 'ps_05_mediterraneo') {
    return kPs05LarnakaMateurLowChill;
  }
  return id;
}

/// Multiplicadores por estado productivo (doc 03 §5.1).
({double low, double expected, double high}) _productionStateFactors(
  PistachioProductionState state,
) {
  return switch (state) {
    PistachioProductionState.nonProductive => (low: 0, expected: 0, high: 0),
    PistachioProductionState.firstBearing => (
      low: 0.08,
      expected: 0.20,
      high: 0.35,
    ),
    PistachioProductionState.youngBearing => (
      low: 0.35,
      expected: 0.65,
      high: 0.90,
    ),
    PistachioProductionState.fullBearing => (
      low: 0.70,
      expected: 1.00,
      high: 1.20,
    ),
    PistachioProductionState.alternateLowYear => (
      low: 0.35,
      expected: 0.60,
      high: 0.85,
    ),
    PistachioProductionState.unknown => (low: 0.25, expected: 0.55, high: 0.85),
  };
}

double _managementFactor(PistachioManagementLevel? level) => switch (level) {
  null => 1.0,
  PistachioManagementLevel.low => 0.55,
  PistachioManagementLevel.medium => 0.85,
  PistachioManagementLevel.good => 1.05,
  PistachioManagementLevel.high => 1.18,
  PistachioManagementLevel.exceptional => 1.30,
};

double _irrigationFactor(PistachioIrrigationLevel? level) => switch (level) {
  null => 1.0,
  PistachioIrrigationLevel.rainfed => 0.38,
  PistachioIrrigationLevel.irregular => 0.68,
  PistachioIrrigationLevel.stable => 1.00,
  PistachioIrrigationLevel.regulatedDeficit => 0.95,
  PistachioIrrigationLevel.fertigation => 1.10,
};

/// Factor de polinizacion (doc 03 §8.3). Si no se sabe, no destruye el calculo
/// (baja confianza); si se confirma falta/desfase de macho, castiga fuerte
/// porque la polinizacion cruzada por viento es central en pistache.
double _pollinationFactor(PistachioPollinationStatus? status) =>
    switch (status) {
      null || PistachioPollinationStatus.unknown => 1.0,
      PistachioPollinationStatus.compatibleMalePresent => 1.08,
      PistachioPollinationStatus.malePresentButMismatchRisk => 0.75,
      PistachioPollinationStatus.lowMaleRatio => 0.70,
      PistachioPollinationStatus.noMaleKnown => 0.35,
    };

/// Factor de alternancia (doc 03 §8.4). Un ano OFF no significa arbol enfermo.
double _bearingCycleFactor(PistachioBearingCycle? cycle) => switch (cycle) {
  null || PistachioBearingCycle.unknown => 1.0,
  PistachioBearingCycle.onYear => 1.10,
  PistachioBearingCycle.offYear => 0.68,
  PistachioBearingCycle.balanced => 1.0,
};

/// Inferencia de estado productivo (doc 03 §5.2). Conservadora.
PistachioProductionState _inferProductionState({
  required String stateId,
  required String stageId,
  PistachioProductionState? explicit,
}) {
  if (explicit != null) return explicit;
  if (stateId == TreeStateIds.newlyPlanted ||
      stateId == TreeStateIds.juvenileNonProductive) {
    return PistachioProductionState.nonProductive;
  }
  if (stateId == TreeStateIds.productiveSeason) {
    return switch (stageId) {
      TreeStageIds.flowering => PistachioProductionState.unknown,
      TreeStageIds.fruitSet => PistachioProductionState.youngBearing,
      TreeStageIds.fruitFill ||
      TreeStageIds.harvestMaturity ||
      TreeStageIds.postHarvest => PistachioProductionState.fullBearing,
      _ => PistachioProductionState.unknown,
    };
  }
  return PistachioProductionState.unknown;
}

/// Estados/etapas que bloquean rendimiento comercial (doc 03 §5.3).
bool _blocksYield(String stateId, String stageId) {
  if (stateId == TreeStateIds.newlyPlanted ||
      stateId == TreeStateIds.juvenileNonProductive) {
    return true;
  }
  return stageId == TreeStageIds.plantingTransplant ||
      stageId == TreeStageIds.rootEstablishment ||
      stageId == TreeStageIds.juvenileVegetative;
}

/// Calcula la proyeccion aproximada de rendimiento del pistache (doc 03 §10).
PistachioTreeYieldProjection resolvePistachioTreeYield({
  required String? profileId,
  required String? perennialStateId,
  required String? phenologyStageId,
  double? treesPerHa,
  double? hectares,
  int? treeCount,
  PistachioProductionState? productionState,
  PistachioManagementLevel? managementLevel,
  PistachioIrrigationLevel? irrigationLevel,
  PistachioPollinationStatus? pollinationStatus,
  PistachioBearingCycle? bearingCycle,
  PistachioTreeStressMemory? stressMemory,
}) {
  final stateId = normalizeTreeStateId(perennialStateId);
  final stageId = normalizeTreeStageId(phenologyStageId);
  final ref =
      pistachioYieldReferenceByProfile[_normalizePistachioProfileId(
        profileId,
      )] ??
      pistachioYieldReferenceByProfile[kPsSkip]!;

  // 1. Bloqueo no productivo.
  if (_blocksYield(stateId, stageId)) {
    return PistachioTreeYieldProjection.zero(
      profileId: ref.profileId,
      confidence: 0.85,
      notesEs: const <String>[
        'Todavia no proyectamos cosecha: el pistache esta en formacion. Importa '
            'mas formar raiz, estructura, luz, macho/hembra correcto y reservas.',
      ],
    );
  }

  final state = _inferProductionState(
    stateId: stateId,
    stageId: stageId,
    explicit: productionState,
  );
  if (state == PistachioProductionState.nonProductive) {
    return PistachioTreeYieldProjection.zero(
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

  // 3. Modificadores.
  final sf = _productionStateFactors(state);
  final mgmt = _managementFactor(managementLevel);
  final irr = _irrigationFactor(irrigationLevel);
  final poll = _pollinationFactor(pollinationStatus);
  final alt = _bearingCycleFactor(bearingCycle);
  final stress = stressMemory?.yieldFactor01 ?? 1.0;
  final commonFactor = mgmt * irr * poll * alt * stress;

  // 4. kg/arbol con factores de estado + comunes, luego tope por densidad.
  YieldRange kgTree = ref.fullKgPerTree
      .scaleEach(sf.low, sf.expected, sf.high)
      .scale(commonFactor);
  if (density != null) {
    kgTree = kgTree.cappedAt(
      PistachioDensitySystem.fromTreesPerHa(density).kgPerTreeCap,
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

  // 7. Confianza (doc 03 §10.3).
  double confidence = ref.confidenceBase;
  if (density == null) confidence -= 0.15;
  if (state == PistachioProductionState.unknown) confidence -= 0.10;
  if (stageId == TreeStageIds.unknown) confidence -= 0.05;
  if (stressMemory != null && stressMemory.hasAnyStress) confidence -= 0.10;
  if (pollinationStatus == null ||
      pollinationStatus == PistachioPollinationStatus.unknown) {
    if (stageId == TreeStageIds.flowering || stageId == TreeStageIds.fruitSet) {
      confidence -= 0.08;
    }
  }
  if ((ref.profileId == kPs04SiroraCompatible ||
          ref.profileId == kPs05LarnakaMateurLowChill) &&
      confidence > 0.58) {
    confidence = 0.58;
  }
  if (density != null &&
      stageId != TreeStageIds.unknown &&
      pollinationStatus == PistachioPollinationStatus.compatibleMalePresent) {
    confidence += 0.08;
  }
  confidence = confidence.clamp(0.05, 0.95);

  final notes = <String>[...ref.notesEs];
  if (ref.profileId == kPsSkip) {
    notes.add(
      'Este calculo usa un perfil general de pistache. Mejora si eliges Kerman, '
      'Golden Hills, Lost Hills, Sirora o Larnaka/Mateur.',
    );
  }
  if (density == null) {
    notes.add(
      'Sin densidad ni numero de arboles no estimamos t/ha con buena confianza; '
      'indica arboles/ha o marco de plantacion.',
    );
  }
  if (pollinationStatus == PistachioPollinationStatus.noMaleKnown ||
      pollinationStatus == PistachioPollinationStatus.lowMaleRatio ||
      pollinationStatus ==
          PistachioPollinationStatus.malePresentButMismatchRisk) {
    notes.add(
      'En pistache la polinizacion macho-hembra por viento es central. Si falta '
      'macho compatible o no coincide la floracion, el amarre puede caer fuerte.',
    );
  }
  if (bearingCycle == PistachioBearingCycle.offYear) {
    notes.add(
      'Ajuste por ano bajo de alternancia. En pistache un ano bajo puede ser '
      'normal despues de un ano cargado, pero conviene revisar reservas y '
      'postcosecha.',
    );
  }
  if (stress < 1.0) {
    notes.add(
      'Ajustamos a la baja por memoria de estres. Frio insuficiente, lluvia en '
      'floracion, agua, salinidad, insecto y postcosecha pueden mover mucho la '
      'cosecha.',
    );
  }
  if (tonHa != null && tonHa.expected > 4.0) {
    notes.add(
      'Proyeccion alta: revisar split/open, blanks, cosecha a tiempo, plagas y '
      'alternancia. Mas kg no siempre significa mas calidad vendible.',
    );
  }

  return PistachioTreeYieldProjection(
    isProductive: true,
    profileId: ref.profileId,
    productionState: state,
    confidence01: confidence,
    kgPerTree: kgTree,
    tonPerHa: tonHa,
    totalKg: totalKg,
    splitPct: ref.splitPct,
    notesEs: notes,
  );
}
