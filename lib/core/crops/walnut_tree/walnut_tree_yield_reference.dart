/// Rendimiento aproximado del Nogal pecanero (doc 03 oficial).
///
/// Reglas no negociables:
/// - El rendimiento de un nogal NO se calcula como cultivo anual: se estima por
///   kg de NUEZ CON CASCARA/arbol + arboles/ha + estado productivo + perfil +
///   densidad + manejo + riego + polinizacion + memoria de estres + confianza.
/// - Es APROXIMADO y en rango (bajo / esperado / alto). Nunca es promesa.
/// - Estados no productivos (recien plantado, juvenil) y etapas de
///   establecimiento proyectan 0.
/// - `post_harvest` NO cierra el cultivo ni borra historial (reservas).
/// - La salida principal es kg de nuez con cascara/arbol y t/ha, NO "frutos
///   frescos" ni numero de nueces (doc 03 §0.2).
/// - La polinizacion cruzada pesa mas que en pepita/hueso: si se sabe que falta
///   polinizador compatible, el castigo es mayor (doc 03 §7.3).
/// - El fallback de perfil es SIEMPRE NG-SKIP de nogal, NUNCA AP-SKIP de
///   manzano, PR-SKIP de pera ni DZ-SKIP de durazno (doc 03 §0.1, §16.8).
///
/// Aditivo: NO reemplaza el motor minimo `TreeYieldReferenceCatalog`. La
/// consolidacion queda como follow-up documentado.
library;

import 'package:bio_g/core/crops/walnut_tree/walnut_tree_catalog.dart';
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

/// Referencia base de rendimiento por perfil NG (doc 03 §6 / §12.4).
class WalnutTreeYieldReference {
  const WalnutTreeYieldReference({
    required this.profileId,
    required this.fullKgPerTree,
    required this.expectedTonPerHa,
    required this.confidenceBase,
    this.kernelPct = const YieldRange(48, 54, 58),
    this.notesEs = const <String>[],
  });

  final String profileId;
  final YieldRange fullKgPerTree;
  final YieldRange expectedTonPerHa;
  final double confidenceBase;

  /// Porcentaje de almendra/grano esperado (contexto de calidad, doc 03 §9.3).
  /// NO entra al calculo de kg; es nota de calidad para UX.
  final YieldRange kernelPct;
  final List<String> notesEs;
}

/// Estado productivo del nogal (doc 03 §4).
enum WalnutProductionState {
  nonProductive,
  firstBearing,
  youngBearing,
  fullBearing,
  alternateLowYear,
  unknown,
}

enum WalnutManagementLevel { low, medium, good, high, exceptional }

enum WalnutIrrigationLevel { rainfed, irregular, stable, fertigation }

/// Severidad de estres guardada en memoria multianual (doc 03 §8.2).
enum WalnutStressSeverity { none, mild, moderate, severe }

/// Memoria de estres del nogal (doc 03 §8.3 / doc 04 §13). Solo afecta el
/// rendimiento como modificador; nunca borra historial ni etapa.
class WalnutTreeStressMemory {
  const WalnutTreeStressMemory({
    this.insufficientWinterChill = WalnutStressSeverity.none,
    this.floweringFrost = WalnutStressSeverity.none,
    this.pollinationMismatch = WalnutStressSeverity.none,
    this.fruitSetDrop = WalnutStressSeverity.none,
    this.fruitFillWaterStress = WalnutStressSeverity.none,
    this.zincOrNutritionStress = WalnutStressSeverity.none,
    this.nutBorerOrPestDamage = WalnutStressSeverity.none,
    this.alternateBearing = WalnutStressSeverity.none,
    this.postHarvestReserveRisk = WalnutStressSeverity.none,
  });

  final WalnutStressSeverity insufficientWinterChill;
  final WalnutStressSeverity floweringFrost;
  final WalnutStressSeverity pollinationMismatch;
  final WalnutStressSeverity fruitSetDrop;
  final WalnutStressSeverity fruitFillWaterStress;
  final WalnutStressSeverity zincOrNutritionStress;
  final WalnutStressSeverity nutBorerOrPestDamage;
  final WalnutStressSeverity alternateBearing;
  final WalnutStressSeverity postHarvestReserveRisk;

  bool get hasAnyStress =>
      insufficientWinterChill != WalnutStressSeverity.none ||
      floweringFrost != WalnutStressSeverity.none ||
      pollinationMismatch != WalnutStressSeverity.none ||
      fruitSetDrop != WalnutStressSeverity.none ||
      fruitFillWaterStress != WalnutStressSeverity.none ||
      zincOrNutritionStress != WalnutStressSeverity.none ||
      nutBorerOrPestDamage != WalnutStressSeverity.none ||
      alternateBearing != WalnutStressSeverity.none ||
      postHarvestReserveRisk != WalnutStressSeverity.none;

  /// Factor de rendimiento combinado 0..1 (doc 03 §8.4). Se toma el evento mas
  /// severo (el cuello de botella del ciclo); no se multiplican todos. Helada en
  /// flor, mala polinizacion o barrenador severo pueden justificar 0.25.
  double get yieldFactor01 {
    double factorFor(WalnutStressSeverity s) => switch (s) {
      WalnutStressSeverity.none => 1.0,
      WalnutStressSeverity.mild => 0.88,
      WalnutStressSeverity.moderate => 0.65,
      WalnutStressSeverity.severe => 0.35,
    };
    final factors = <double>[
      factorFor(insufficientWinterChill),
      factorFor(floweringFrost),
      factorFor(pollinationMismatch),
      factorFor(fruitSetDrop),
      factorFor(fruitFillWaterStress),
      factorFor(zincOrNutritionStress),
      factorFor(nutBorerOrPestDamage),
      factorFor(alternateBearing),
      factorFor(postHarvestReserveRisk),
    ];
    double worst = factors.reduce((a, b) => a < b ? a : b);
    // Ajuste especial (doc 03 §8.4): helada en flor / desfase de polinizacion /
    // barrenador severos pueden hundir el ciclo a 0.25.
    final hardHits = <WalnutStressSeverity>[
      floweringFrost,
      pollinationMismatch,
      nutBorerOrPestDamage,
    ];
    if (hardHits.any((s) => s == WalnutStressSeverity.severe) && worst > 0.25) {
      worst = 0.25;
    }
    return worst;
  }
}

/// Sistema de densidad (doc 03 §5.4): define el tope de kg/arbol. El nogal no
/// tiene portainjertos enanizantes: un arbol grande encerrado baja kg/arbol.
class WalnutDensitySystem {
  const WalnutDensitySystem(this.id, this.kgPerTreeCap);

  final String id;
  final double kgPerTreeCap;

  static const WalnutDensitySystem extensive = WalnutDensitySystem(
    'extensive_or_old_spacing',
    90,
  );
  static const WalnutDensitySystem traditionalCommercial = WalnutDensitySystem(
    'traditional_commercial',
    65,
  );
  static const WalnutDensitySystem semiIntensive = WalnutDensitySystem(
    'semi_intensive',
    48,
  );
  static const WalnutDensitySystem intensiveYoung = WalnutDensitySystem(
    'intensive_young_or_managed',
    34,
  );
  static const WalnutDensitySystem veryHighDensityTemporary = WalnutDensitySystem(
    'very_high_density_temporary',
    24,
  );

  /// Regla de cap por densidad (doc 03 §5.4): evita que 100-200 arboles/ha
  /// multipliquen kg/arbol como si fueran arboles aislados.
  static WalnutDensitySystem fromTreesPerHa(double treesPerHa) {
    if (treesPerHa < 60) return extensive;
    if (treesPerHa < 90) return traditionalCommercial;
    if (treesPerHa < 130) return semiIntensive;
    if (treesPerHa < 200) return intensiveYoung;
    return veryHighDensityTemporary;
  }
}

/// Proyeccion de rendimiento aproximada del nogal.
class WalnutTreeYieldProjection {
  const WalnutTreeYieldProjection({
    required this.isProductive,
    required this.profileId,
    required this.productionState,
    required this.confidence01,
    this.kgPerTree,
    this.tonPerHa,
    this.totalKg,
    this.kernelPct,
    this.notesEs = const <String>[],
  });

  final bool isProductive;
  final String profileId;
  final WalnutProductionState productionState;
  final double confidence01;

  final YieldRange? kgPerTree;
  final YieldRange? tonPerHa;
  final YieldRange? totalKg;

  /// Porcentaje de almendra esperado (contexto de calidad, doc 03 §9.3).
  final YieldRange? kernelPct;

  final List<String> notesEs;

  factory WalnutTreeYieldProjection.zero({
    required String profileId,
    required double confidence,
    List<String> notesEs = const <String>[],
  }) => WalnutTreeYieldProjection(
    isProductive: false,
    profileId: profileId,
    productionState: WalnutProductionState.nonProductive,
    confidence01: confidence,
    kgPerTree: YieldRange.zero,
    notesEs: notesEs,
  );
}

/// Tabla de referencia por perfil (doc 03 §6 / §12.4). kg de nuez con cascara.
const Map<String, WalnutTreeYieldReference>
walnutYieldReferenceByProfile = <String, WalnutTreeYieldReference>{
  kNgSkip: WalnutTreeYieldReference(
    profileId: kNgSkip,
    fullKgPerTree: YieldRange(12, 24, 40),
    expectedTonPerHa: YieldRange(0.8, 1.6, 2.4),
    confidenceBase: 0.48,
    kernelPct: YieldRange(48, 54, 58),
    notesEs: <String>[
      'Perfil general: no asume Western, Wichita, marco, riego ni polinizador '
          'especifico. El promedio regional del norte de Mexico ronda ~1.4-1.8 t/ha.',
    ],
  ),
  kNg01Western: WalnutTreeYieldReference(
    profileId: kNg01Western,
    fullKgPerTree: YieldRange(16, 28, 45),
    expectedTonPerHa: YieldRange(1.2, 2.0, 2.8),
    confidenceBase: 0.72,
    kernelPct: YieldRange(55, 58, 60),
    notesEs: <String>[
      'Western Schley: cultivar base del oeste/norte; productivo y relativamente '
          'confiable, pero puede sobrecargar y bajar calidad de almendra.',
    ],
  ),
  kNg02Wichita: WalnutTreeYieldReference(
    profileId: kNg02Wichita,
    fullKgPerTree: YieldRange(18, 30, 48),
    expectedTonPerHa: YieldRange(1.3, 2.2, 3.0),
    confidenceBase: 0.68,
    kernelPct: YieldRange(56, 59, 62),
    notesEs: <String>[
      'Wichita: precoz y prolifica; mayor riesgo de sobrecarga, zinc, ramas '
          'debiles, sticktights y desordenes fisiologicos bajo calor.',
    ],
  ),
  kNg03WesternWichita: WalnutTreeYieldReference(
    profileId: kNg03WesternWichita,
    fullKgPerTree: YieldRange(18, 31, 50),
    expectedTonPerHa: YieldRange(1.4, 2.3, 3.1),
    confidenceBase: 0.76,
    kernelPct: YieldRange(54, 58, 61),
    notesEs: <String>[
      'Bloque Western/Wichita: paquete regional fuerte con buena polinizacion; '
          'no prometer >3 t/ha como normal permanente.',
    ],
  ),
  kNg04CriolloRegional: WalnutTreeYieldReference(
    profileId: kNg04CriolloRegional,
    fullKgPerTree: YieldRange(6, 15, 32),
    expectedTonPerHa: YieldRange(0.4, 1.0, 1.8),
    confidenceBase: 0.38,
    kernelPct: YieldRange(42, 50, 56),
    notesEs: <String>[
      'Criollo/regional: muy heterogeneo (huerto viejo, nativo, mezcla); '
          'confianza baja, alternancia fuerte y dependencia de manejo y edad.',
    ],
  ),
  kNg05TempranoPawneeKanza: WalnutTreeYieldReference(
    profileId: kNg05TempranoPawneeKanza,
    fullKgPerTree: YieldRange(12, 24, 40),
    expectedTonPerHa: YieldRange(1.0, 1.7, 2.5),
    confidenceBase: 0.55,
    kernelPct: YieldRange(51, 56, 60),
    notesEs: <String>[
      'Temprano/Pawnee-Kanza-Cheyenne: adelanta ventana de cosecha; no asumir '
          'la misma productividad que Western/Wichita. Revisar polinizador y helada.',
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

/// Normaliza el profileId al id canónico para el lookup de rendimiento,
/// conservando el historial: los ids previos de NG-05 (`ng_05_temprano_nuevo`,
/// `ng_05_temprano`) siguen resolviendo a `ng_05_temprano_pawnee_kanza`.
String? _normalizeWalnutProfileId(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  if (id == null || id.isEmpty) return id;
  if (id == 'ng_05_temprano_nuevo' || id == 'ng_05_temprano') {
    return kNg05TempranoPawneeKanza;
  }
  return id;
}

/// Multiplicadores por estado productivo (doc 03 §4.1): low/expected/high.
({double low, double expected, double high}) _productionStateFactors(
  WalnutProductionState state,
) {
  return switch (state) {
    WalnutProductionState.nonProductive => (low: 0, expected: 0, high: 0),
    WalnutProductionState.firstBearing => (low: 0.05, expected: 0.15, high: 0.30),
    WalnutProductionState.youngBearing => (low: 0.25, expected: 0.50, high: 0.75),
    WalnutProductionState.fullBearing => (low: 0.70, expected: 1.00, high: 1.20),
    WalnutProductionState.alternateLowYear => (
      low: 0.15,
      expected: 0.45,
      high: 0.70,
    ),
    WalnutProductionState.unknown => (low: 0.25, expected: 0.55, high: 0.80),
  };
}

double _managementFactor(WalnutManagementLevel? level) => switch (level) {
  null => 1.0,
  WalnutManagementLevel.low => 0.55,
  WalnutManagementLevel.medium => 0.85,
  WalnutManagementLevel.good => 1.05,
  WalnutManagementLevel.high => 1.18,
  WalnutManagementLevel.exceptional => 1.30,
};

double _irrigationFactor(WalnutIrrigationLevel? level) => switch (level) {
  null => 1.0,
  WalnutIrrigationLevel.rainfed => 0.45,
  WalnutIrrigationLevel.irregular => 0.72,
  WalnutIrrigationLevel.stable => 1.02,
  WalnutIrrigationLevel.fertigation => 1.10,
};

/// Factor de polinizacion (doc 03 §7.3). Si no se sabe, SKIP no castiga fuerte;
/// si se confirma que falta polinizador compatible, el castigo es mayor que en
/// manzano/pera/durazno (la polinizacion cruzada por viento es central).
double _pollinationFactor(bool? pollinatorKnown) => switch (pollinatorKnown) {
  null => 1.0,
  true => 1.06,
  false => 0.72,
};

/// Inferencia de estado productivo (doc 03 §4.2). Conservadora: en
/// `productive_season` se asume plena produccion por default; `established` y el
/// resto quedan en unknown hasta confirmar carga.
WalnutProductionState _inferProductionState({
  required String stateId,
  required String stageId,
  WalnutProductionState? explicit,
}) {
  if (explicit != null) return explicit;
  if (stateId == TreeStateIds.newlyPlanted ||
      stateId == TreeStateIds.juvenileNonProductive) {
    return WalnutProductionState.nonProductive;
  }
  if (stateId == TreeStateIds.productiveSeason) {
    return switch (stageId) {
      TreeStageIds.flowering => WalnutProductionState.unknown,
      TreeStageIds.fruitSet => WalnutProductionState.youngBearing,
      TreeStageIds.fruitFill ||
      TreeStageIds.harvestMaturity ||
      TreeStageIds.postHarvest => WalnutProductionState.fullBearing,
      _ => WalnutProductionState.unknown,
    };
  }
  return WalnutProductionState.unknown;
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

/// Calcula la proyeccion aproximada de rendimiento del nogal (doc 03 §10-§13).
WalnutTreeYieldProjection resolveWalnutTreeYield({
  required String? profileId,
  required String? perennialStateId,
  required String? phenologyStageId,
  double? treesPerHa,
  double? hectares,
  int? treeCount,
  WalnutProductionState? productionState,
  WalnutManagementLevel? managementLevel,
  WalnutIrrigationLevel? irrigationLevel,
  bool? pollinatorKnown,
  WalnutTreeStressMemory? stressMemory,
}) {
  final stateId = normalizeTreeStateId(perennialStateId);
  final stageId = normalizeTreeStageId(phenologyStageId);
  final ref =
      walnutYieldReferenceByProfile[_normalizeWalnutProfileId(profileId)] ??
      walnutYieldReferenceByProfile[kNgSkip]!;

  // 1. Bloqueo no productivo.
  if (_blocksYield(stateId, stageId)) {
    return WalnutTreeYieldProjection.zero(
      profileId: ref.profileId,
      confidence: 0.85,
      notesEs: const <String>[
        'Todavia no proyectamos cosecha: el nogal esta en formacion. Importa '
            'mas formar raiz, estructura, luz y reservas que forzar produccion.',
      ],
    );
  }

  final state = _inferProductionState(
    stateId: stateId,
    stageId: stageId,
    explicit: productionState,
  );
  if (state == WalnutProductionState.nonProductive) {
    return WalnutTreeYieldProjection.zero(
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

  // 4. kg/arbol con factores de estado + comunes, luego tope por densidad.
  YieldRange kgTree = ref.fullKgPerTree
      .scaleEach(sf.low, sf.expected, sf.high)
      .scale(commonFactor);
  if (density != null) {
    kgTree = kgTree.cappedAt(
      WalnutDensitySystem.fromTreesPerHa(density).kgPerTreeCap,
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

  // 7. Confianza (doc 03 §10.2).
  double confidence = ref.confidenceBase;
  if (density == null) confidence -= 0.15;
  if (state == WalnutProductionState.unknown) confidence -= 0.10;
  if (stageId == TreeStageIds.unknown) confidence -= 0.05;
  if (stressMemory != null && stressMemory.hasAnyStress) confidence -= 0.10;
  if (pollinatorKnown == null &&
      (stageId == TreeStageIds.flowering || stageId == TreeStageIds.fruitSet)) {
    confidence -= 0.05;
  }
  if (ref.profileId == kNg04CriolloRegional && confidence > 0.55) {
    confidence = 0.55;
  }
  confidence = confidence.clamp(0.05, 0.95);

  final notes = <String>[...ref.notesEs];
  if (ref.profileId == kNgSkip) {
    notes.add(
      'Este calculo usa un perfil general de nogal. Puede mejorar si eliges '
      'Western, Wichita, bloque Western/Wichita, criollo/regional o temprano.',
    );
  }
  if (density == null) {
    notes.add(
      'Sin densidad ni numero de arboles no estimamos t/ha; indica arboles/ha o '
      'marco de plantacion para mas precision.',
    );
  }
  if (pollinatorKnown == false) {
    notes.add(
      'En nogal la polinizacion cruzada es central. Si falta variedad '
      'compatible cerca o hay desfase floral, el amarre y la carga pueden bajar.',
    );
  }
  if (stress < 1.0) {
    notes.add(
      'Ajustamos a la baja por memoria de estres. En nogal, agua, helada, '
      'polinizacion, barrenador, zinc y alternancia pueden mover mucho la cosecha.',
    );
  }
  if (tonHa != null && tonHa.expected > 3.2) {
    notes.add(
      'Proyeccion alta: revisa sobrecarga, llenado de almendra y alternancia del '
      'siguiente ciclo. Mas kg no siempre significa mejor calidad.',
    );
  }

  return WalnutTreeYieldProjection(
    isProductive: true,
    profileId: ref.profileId,
    productionState: state,
    confidence01: confidence,
    kgPerTree: kgTree,
    tonPerHa: tonHa,
    totalKg: totalKg,
    kernelPct: ref.kernelPct,
    notesEs: notes,
  );
}
