/// Rendimiento aproximado del Manzano (doc 03 oficial).
///
/// Reglas no negociables:
/// - El rendimiento de un árbol NO se calcula como cultivo anual: se estima por
///   kg/árbol + árboles/ha + estado productivo + perfil + densidad + manejo +
///   memoria de estrés + confianza.
/// - Es APROXIMADO y en rango (bajo / esperado / alto). Nunca es promesa.
/// - Estados no productivos (recién plantado, juvenil) y etapas de
///   establecimiento proyectan 0.
/// - `post_harvest` NO cierra el cultivo ni borra historial.
///
/// Relación con el módulo existente:
/// El proyecto ya tiene `core/yield/tree_yield_reference_catalog.dart`
/// (`TreeYieldReferenceCatalog`), un modelo MÍNIMO y conservador por tier
/// (kg/árbol × nº de árboles) que es el que hoy alimenta la pantalla de
/// proyección de rendimiento (decisiones #10/#11: no persiste densidad). Este
/// archivo es la referencia AGRONÓMICA COMPLETA del documento 03 (perfiles AP,
/// densidades, modificadores de manejo/agua/polinización, memoria de estrés y
/// conversión a t/ha). Es aditivo: NO reemplaza ni rompe el módulo mínimo. La
/// consolidación de ambos en un solo motor de proyección queda como follow-up
/// documentado para no refactorizar la pantalla/almacenamiento/Supabase de
/// golpe.
library;

import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
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

/// Referencia base de rendimiento por perfil AP (doc 03 §10.1).
class AppleTreeYieldReference {
  const AppleTreeYieldReference({
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
enum AppleProductionState {
  nonProductive,
  firstBearing,
  youngBearing,
  fullBearing,
  alternateLowYear,
  unknown,
}

enum AppleManagementLevel { low, medium, good, high, exceptional }

enum AppleIrrigationLevel { rainfed, irregular, stable, fertigation }

/// Severidad de estrés guardada en memoria multianual.
enum AppleStressSeverity { none, mild, moderate, severe }

/// Memoria de estrés del manzano (doc 03 §9 / doc 04 §10). Solo afecta el
/// rendimiento como modificador; nunca borra historial ni etapa.
class AppleTreeStressMemory {
  const AppleTreeStressMemory({
    this.floweringFrost = AppleStressSeverity.none,
    this.fruitSetWaterStress = AppleStressSeverity.none,
    this.fruitFillKStress = AppleStressSeverity.none,
    this.hailDamage = AppleStressSeverity.none,
    this.alternateBearing = AppleStressSeverity.none,
    this.postHarvestReserveRisk = AppleStressSeverity.none,
  });

  final AppleStressSeverity floweringFrost;
  final AppleStressSeverity fruitSetWaterStress;
  final AppleStressSeverity fruitFillKStress;
  final AppleStressSeverity hailDamage;
  final AppleStressSeverity alternateBearing;
  final AppleStressSeverity postHarvestReserveRisk;

  bool get hasAnyStress =>
      floweringFrost != AppleStressSeverity.none ||
      fruitSetWaterStress != AppleStressSeverity.none ||
      fruitFillKStress != AppleStressSeverity.none ||
      hailDamage != AppleStressSeverity.none ||
      alternateBearing != AppleStressSeverity.none ||
      postHarvestReserveRisk != AppleStressSeverity.none;

  /// Factor de rendimiento combinado 0..1 (doc 03 §9 stressModifier). Se toma
  /// el evento más severo (el cuello de botella del ciclo).
  double get yieldFactor01 {
    double factorFor(AppleStressSeverity s) => switch (s) {
      AppleStressSeverity.none => 1.0,
      AppleStressSeverity.mild => 0.92,
      AppleStressSeverity.moderate => 0.75,
      // Helada/granizo fuerte en ventana reproductiva: reducción fuerte.
      AppleStressSeverity.severe => 0.35,
    };
    final factors = <double>[
      factorFor(floweringFrost),
      factorFor(fruitSetWaterStress),
      factorFor(fruitFillKStress),
      factorFor(hailDamage),
      factorFor(alternateBearing),
      factorFor(postHarvestReserveRisk),
    ];
    return factors.reduce((a, b) => a < b ? a : b);
  }
}

/// Sistema de densidad (doc 03 §5 / §10.3): define el tope de kg/árbol.
class AppleDensitySystem {
  const AppleDensitySystem(this.id, this.kgPerTreeCap);

  final String id;
  final double kgPerTreeCap;

  static const AppleDensitySystem traditionalExtensive = AppleDensitySystem(
    'traditional_extensive',
    120,
  );
  static const AppleDensitySystem semiIntensive = AppleDensitySystem(
    'semi_intensive',
    90,
  );
  static const AppleDensitySystem mediumModern = AppleDensitySystem(
    'medium_modern',
    75,
  );
  static const AppleDensitySystem highDensity = AppleDensitySystem(
    'high_density',
    45,
  );
  static const AppleDensitySystem veryHighDensity = AppleDensitySystem(
    'very_high_density',
    25,
  );

  static AppleDensitySystem fromTreesPerHa(double treesPerHa) {
    if (treesPerHa < 500) return traditionalExtensive;
    if (treesPerHa < 900) return semiIntensive;
    if (treesPerHa < 1500) return mediumModern;
    if (treesPerHa < 3000) return highDensity;
    return veryHighDensity;
  }
}

/// Proyección de rendimiento aproximada del manzano.
class AppleTreeYieldProjection {
  const AppleTreeYieldProjection({
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
  final AppleProductionState productionState;
  final double confidence01;

  /// Rango aproximado por árbol (kg). Null si no aplica.
  final YieldRange? kgPerTree;

  /// Rango aproximado por hectárea (t). Null si no se conoce densidad.
  final YieldRange? tonPerHa;

  /// Rango aproximado total (kg) si se conoce el número de árboles.
  final YieldRange? totalKg;

  final List<String> notesEs;

  factory AppleTreeYieldProjection.zero({
    required String profileId,
    required double confidence,
    List<String> notesEs = const <String>[],
  }) => AppleTreeYieldProjection(
    isProductive: false,
    profileId: profileId,
    productionState: AppleProductionState.nonProductive,
    confidence01: confidence,
    kgPerTree: YieldRange.zero,
    notesEs: notesEs,
  );
}

/// Tabla de referencia por perfil (doc 03 §10.1).
const Map<String, AppleTreeYieldReference>
appleYieldReferenceByProfile = <String, AppleTreeYieldReference>{
  kApSkip: AppleTreeYieldReference(
    profileId: kApSkip,
    fullKgPerTree: YieldRange(25, 40, 60),
    expectedTonPerHa: YieldRange(15, 30, 45),
    confidenceBase: 0.45,
    notesEs: <String>[
      'Perfil general: no asume Golden, Red, portainjerto ni alta densidad.',
    ],
  ),
  kAp01Golden: AppleTreeYieldReference(
    profileId: kAp01Golden,
    fullKgPerTree: YieldRange(35, 55, 75),
    expectedTonPerHa: YieldRange(25, 40, 55),
    confidenceBase: 0.72,
    notesEs: <String>[
      'Golden/MM111 en Chihuahua: 52-64 t/ha como referencia fuerte con '
          'fertirrigación; 80-100 t/ha solo excepcional.',
    ],
  ),
  kAp02Red: AppleTreeYieldReference(
    profileId: kAp02Red,
    fullKgPerTree: YieldRange(30, 48, 65),
    expectedTonPerHa: YieldRange(20, 35, 50),
    confidenceBase: 0.60,
    notesEs: <String>[
      'Red: calidad visual y color pesan mucho; no dar premium sin manejo '
          'de color.',
    ],
  ),
  kAp03CriollaRayada: AppleTreeYieldReference(
    profileId: kAp03CriollaRayada,
    fullKgPerTree: YieldRange(20, 40, 70),
    expectedTonPerHa: YieldRange(8, 20, 30),
    confidenceBase: 0.40,
    notesEs: <String>['Criolla/Rayada: muy heterogénea; confianza baja-media.'],
  ),
  kAp04Gala: AppleTreeYieldReference(
    profileId: kAp04Gala,
    fullKgPerTree: YieldRange(25, 50, 70),
    expectedTonPerHa: YieldRange(30, 45, 60),
    confidenceBase: 0.70,
    notesEs: <String>[
      'Gala: alto potencial t/ha en alta densidad (WSU 65-81 t/ha netas); '
          'en México no copiar ese techo sin alta densidad/trellis/riego.',
    ],
  ),
  kAp05LowChill: AppleTreeYieldReference(
    profileId: kAp05LowChill,
    fullKgPerTree: YieldRange(15, 35, 50),
    expectedTonPerHa: YieldRange(8, 22, 35),
    confidenceBase: 0.50,
    notesEs: <String>[
      'Bajo frío: depende de adaptación de zona y polinizador; fuera de '
          'zona baja la confianza.',
    ],
  ),
};

/// Conversiones oficiales (doc 03 §3 / §11).
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
  AppleProductionState state,
) {
  return switch (state) {
    AppleProductionState.nonProductive => (low: 0, expected: 0, high: 0),
    AppleProductionState.firstBearing => (
      low: 0.05,
      expected: 0.15,
      high: 0.30,
    ),
    AppleProductionState.youngBearing => (
      low: 0.25,
      expected: 0.50,
      high: 0.75,
    ),
    AppleProductionState.fullBearing => (low: 0.75, expected: 1.00, high: 1.20),
    AppleProductionState.alternateLowYear => (
      low: 0.20,
      expected: 0.50,
      high: 0.75,
    ),
    AppleProductionState.unknown => (low: 0.30, expected: 0.60, high: 0.90),
  };
}

double _managementFactor(AppleManagementLevel? level) => switch (level) {
  null => 1.0,
  AppleManagementLevel.low => 0.60,
  AppleManagementLevel.medium => 0.90,
  AppleManagementLevel.good => 1.07,
  AppleManagementLevel.high => 1.25,
  AppleManagementLevel.exceptional => 1.45,
};

double _irrigationFactor(AppleIrrigationLevel? level) => switch (level) {
  null => 1.0,
  AppleIrrigationLevel.rainfed => 0.57,
  AppleIrrigationLevel.irregular => 0.80,
  AppleIrrigationLevel.stable => 1.02,
  AppleIrrigationLevel.fertigation => 1.12,
};

double _pollinationFactor(bool? pollinatorKnown) => switch (pollinatorKnown) {
  null => 1.0,
  true => 1.05,
  false => 0.92,
};

/// Deriva el estado productivo desde el estado/etapa perenne si no se dio uno
/// explícito. `established` sin carga confirmada queda como `unknown`
/// (conservador), `productive_season` por defecto plena producción.
AppleProductionState _inferProductionState({
  required String stateId,
  required String stageId,
  AppleProductionState? explicit,
}) {
  if (explicit != null) return explicit;
  return switch (stateId) {
    TreeStateIds.newlyPlanted ||
    TreeStateIds.juvenileNonProductive => AppleProductionState.nonProductive,
    TreeStateIds.productiveSeason => AppleProductionState.fullBearing,
    TreeStateIds.established => AppleProductionState.unknown,
    _ => AppleProductionState.unknown,
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

/// Calcula la proyección aproximada de rendimiento del manzano (doc 03 §8).
///
/// Devuelve rangos bajo/esperado/alto por árbol y por hectárea según los datos
/// disponibles, con una confianza que baja si falta densidad, el estado es
/// incierto o hay estrés en memoria.
AppleTreeYieldProjection resolveAppleTreeYield({
  required String? profileId,
  required String? perennialStateId,
  required String? phenologyStageId,
  double? treesPerHa,
  double? hectares,
  int? treeCount,
  AppleProductionState? productionState,
  AppleManagementLevel? managementLevel,
  AppleIrrigationLevel? irrigationLevel,
  bool? pollinatorKnown,
  AppleTreeStressMemory? stressMemory,
}) {
  final stateId = normalizeTreeStateId(perennialStateId);
  final stageId = normalizeTreeStageId(phenologyStageId);
  final ref =
      appleYieldReferenceByProfile[profileId?.trim().toLowerCase()] ??
      appleYieldReferenceByProfile[kApSkip]!;

  // 1. Bloqueo no productivo.
  if (_blocksYield(stateId, stageId)) {
    return AppleTreeYieldProjection.zero(
      profileId: ref.profileId,
      confidence: 0.85,
      notesEs: const <String>[
        'No proyectamos cosecha todavía: el árbol aún está en formación. '
            'Importa más formar raíz, estructura y reservas.',
      ],
    );
  }

  final state = _inferProductionState(
    stateId: stateId,
    stageId: stageId,
    explicit: productionState,
  );
  if (state == AppleProductionState.nonProductive) {
    return AppleTreeYieldProjection.zero(
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
  final poll = _pollinationFactor(pollinatorKnown);
  final stress = stressMemory?.yieldFactor01 ?? 1.0;
  final commonFactor = mgmt * irr * poll * stress;

  // 4. kg/árbol con factores de estado + comunes, luego tope por densidad.
  YieldRange kgTree = ref.fullKgPerTree
      .scaleEach(sf.low, sf.expected, sf.high)
      .scale(commonFactor);
  if (density != null) {
    kgTree = kgTree.cappedAt(
      AppleDensitySystem.fromTreesPerHa(density).kgPerTreeCap,
    );
  }

  // 5. t/ha desde kg/árbol y densidad.
  final tonHa = density == null
      ? null
      : YieldRange(
          tonHaFromKgTree(kgTree.low, density),
          tonHaFromKgTree(kgTree.expected, density),
          tonHaFromKgTree(kgTree.high, density),
        );

  // 6. Total kg si hay número de árboles.
  final totalKg = treeCount == null ? null : kgTree.scale(treeCount.toDouble());

  // 7. Confianza.
  double confidence = ref.confidenceBase;
  if (density == null) confidence -= 0.15;
  if (state == AppleProductionState.unknown) confidence -= 0.10;
  if (stageId == TreeStageIds.unknown) confidence -= 0.05;
  if (stressMemory != null && stressMemory.hasAnyStress) confidence -= 0.10;
  confidence = confidence.clamp(0.05, 0.95);

  final notes = <String>[...ref.notesEs];
  if (ref.profileId == kApSkip) {
    notes.add(
      'Este cálculo usa un perfil general de manzano. Puede mejorar si eliges '
      'Golden, Red, Gala, criolla/rayada o bajo frío.',
    );
  }
  if (density == null) {
    notes.add(
      'Sin densidad ni número de árboles no estimamos t/ha; indica árboles/ha '
      'o marco de plantación para más precisión.',
    );
  }
  if (stress < 1.0) {
    notes.add(
      'Ajustamos a la baja por estrés guardado (helada, sequía, granizo o '
      'alternancia). El rendimiento del ciclo puede moverse mucho.',
    );
  }

  return AppleTreeYieldProjection(
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
