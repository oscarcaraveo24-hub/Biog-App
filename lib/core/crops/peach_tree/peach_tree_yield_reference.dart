/// Rendimiento aproximado del Durazno (doc 03 oficial).
///
/// Reglas no negociables:
/// - El rendimiento de un árbol NO se calcula como cultivo anual: se estima por
///   kg/árbol + árboles/ha + estado productivo + perfil + densidad + manejo +
///   carga/raleo + frío/floración/cuajado + memoria de estrés + confianza.
/// - Es APROXIMADO y en rango (bajo / esperado / alto). Nunca es promesa.
/// - Estados no productivos (recién plantado, juvenil) y etapas de
///   establecimiento proyectan 0.
/// - `post_harvest` NO cierra el cultivo ni borra historial.
/// - DIFERENCIA CLAVE FRENTE A MANZANO/PERA (doc 03 §11): en durazno,
///   `productive_season` + `flowering` NO infiere plena producción por default;
///   mucha flor puede terminar en poca fruta por helada/frío/lluvia/estrés. La
///   confianza sube cuando hay fruto visible (fruit_fill/harvest_maturity).
/// - El fallback de perfil es SIEMPRE DZ-SKIP de durazno, NUNCA AP-SKIP de
///   manzano ni PR-SKIP de pera (doc 03 §0.1, §13).
///
/// Aditivo: NO reemplaza el motor mínimo `TreeYieldReferenceCatalog`. La
/// consolidación queda como follow-up documentado.
library;

import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
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

/// Referencia base de rendimiento por perfil DZ (doc 03 §10.1).
class PeachTreeYieldReference {
  const PeachTreeYieldReference({
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
enum PeachProductionState {
  nonProductive,
  firstBearing,
  youngBearing,
  fullBearing,
  frostOrPoorSetLowCrop,
  overloadedSmallFruit,
  unknown,
}

enum PeachManagementLevel { low, medium, good, high, exceptional }

enum PeachIrrigationLevel { rainfed, irregular, stable, fertigation }

/// Carga/raleo visible (doc 03 §8 modelo E / §9 cropLoadModifier; doc 05 §3.8).
/// La carga es un "sensor humano": define calibre y producción comercial.
enum PeachCropLoadStatus { noVisibleFruit, light, balanced, heavy, unknown }

/// Severidad de estrés guardada en memoria multianual.
enum PeachStressSeverity { none, mild, moderate, severe }

/// Memoria de estrés del durazno (doc 03 §10.5 / doc 04 §9 / doc 05 §15). Solo
/// afecta el rendimiento como modificador; nunca borra historial ni etapa.
class PeachTreeStressMemory {
  const PeachTreeStressMemory({
    this.insufficientChill = PeachStressSeverity.none,
    this.floweringFrost = PeachStressSeverity.none,
    this.poorFruitSet = PeachStressSeverity.none,
    this.fruitFillWaterStress = PeachStressSeverity.none,
    this.heatStress = PeachStressSeverity.none,
    this.hailDamage = PeachStressSeverity.none,
    this.leafDiseaseOrDefoliation = PeachStressSeverity.none,
    this.postHarvestReserveRisk = PeachStressSeverity.none,
  });

  final PeachStressSeverity insufficientChill;
  final PeachStressSeverity floweringFrost;
  final PeachStressSeverity poorFruitSet;
  final PeachStressSeverity fruitFillWaterStress;
  final PeachStressSeverity heatStress;
  final PeachStressSeverity hailDamage;
  final PeachStressSeverity leafDiseaseOrDefoliation;
  final PeachStressSeverity postHarvestReserveRisk;

  bool get hasAnyStress =>
      insufficientChill != PeachStressSeverity.none ||
      floweringFrost != PeachStressSeverity.none ||
      poorFruitSet != PeachStressSeverity.none ||
      fruitFillWaterStress != PeachStressSeverity.none ||
      heatStress != PeachStressSeverity.none ||
      hailDamage != PeachStressSeverity.none ||
      leafDiseaseOrDefoliation != PeachStressSeverity.none ||
      postHarvestReserveRisk != PeachStressSeverity.none;

  /// Factor de rendimiento combinado 0..1 (doc 03 §9). Se toma el evento más
  /// severo (el cuello de botella del ciclo). En durazno la helada en floración
  /// puede anular la producción del año.
  double get yieldFactor01 {
    double factorFor(PeachStressSeverity s) => switch (s) {
      PeachStressSeverity.none => 1.0,
      PeachStressSeverity.mild => 0.90,
      PeachStressSeverity.moderate => 0.68,
      // Helada en flor / granizo severo / defoliación fuerte: reducción fuerte.
      PeachStressSeverity.severe => 0.28,
    };
    final factors = <double>[
      factorFor(insufficientChill),
      factorFor(floweringFrost),
      factorFor(poorFruitSet),
      factorFor(fruitFillWaterStress),
      factorFor(heatStress),
      factorFor(hailDamage),
      factorFor(leafDiseaseOrDefoliation),
      factorFor(postHarvestReserveRisk),
    ];
    return factors.reduce((a, b) => a < b ? a : b);
  }
}

/// Sistema de densidad (doc 03 §5 / §10.6): define el tope de kg/árbol.
class PeachDensitySystem {
  const PeachDensitySystem(this.id, this.kgPerTreeCap);

  final String id;
  final double kgPerTreeCap;

  static const PeachDensitySystem traditionalExtensive = PeachDensitySystem(
    'traditional_extensive',
    120,
  );
  static const PeachDensitySystem traditionalCommercial = PeachDensitySystem(
    'traditional_commercial',
    90,
  );
  static const PeachDensitySystem semiIntensive = PeachDensitySystem(
    'semi_intensive',
    70,
  );
  static const PeachDensitySystem mediumModern = PeachDensitySystem(
    'medium_modern',
    45,
  );
  static const PeachDensitySystem highDensity = PeachDensitySystem(
    'high_density',
    30,
  );
  static const PeachDensitySystem veryHighDensity = PeachDensitySystem(
    'very_high_density',
    18,
  );

  /// Regla de cap por densidad (doc 03 §10.6): evita t/ha absurdas en alta
  /// densidad (p. ej. 70 kg/árbol × 3000 árboles/ha = 210 t/ha, imposible).
  static PeachDensitySystem fromTreesPerHa(double treesPerHa) {
    if (treesPerHa < 300) return traditionalExtensive;
    if (treesPerHa < 600) return traditionalCommercial;
    if (treesPerHa < 1000) return semiIntensive;
    if (treesPerHa < 1800) return mediumModern;
    if (treesPerHa < 3000) return highDensity;
    return veryHighDensity;
  }
}

/// Proyección de rendimiento aproximada del durazno.
class PeachTreeYieldProjection {
  const PeachTreeYieldProjection({
    required this.isProductive,
    required this.profileId,
    required this.productionState,
    required this.confidence01,
    this.kgPerTree,
    this.tonPerHa,
    this.totalKg,
    this.commercialQualityFactor = 1.0,
    this.notesEs = const <String>[],
  });

  final bool isProductive;
  final String profileId;
  final PeachProductionState productionState;
  final double confidence01;

  final YieldRange? kgPerTree;
  final YieldRange? tonPerHa;
  final YieldRange? totalKg;

  /// 0..1: cuánto de la producción biológica es comercializable. < 1 cuando hay
  /// sobrecarga sin raleo (fruta chica): kg sí, calidad/calibre no (doc 03 §6).
  final double commercialQualityFactor;

  final List<String> notesEs;

  factory PeachTreeYieldProjection.zero({
    required String profileId,
    required double confidence,
    List<String> notesEs = const <String>[],
  }) => PeachTreeYieldProjection(
    isProductive: false,
    profileId: profileId,
    productionState: PeachProductionState.nonProductive,
    confidence01: confidence,
    kgPerTree: YieldRange.zero,
    notesEs: notesEs,
  );
}

/// Tabla de referencia por perfil (doc 03 §10.1).
const Map<String, PeachTreeYieldReference>
peachYieldReferenceByProfile = <String, PeachTreeYieldReference>{
  kDzSkip: PeachTreeYieldReference(
    profileId: kDzSkip,
    fullKgPerTree: YieldRange(18, 32, 45),
    expectedTonPerHa: YieldRange(5, 12, 25),
    confidenceBase: 0.42,
    notesEs: <String>[
      'Perfil general: no asume bajo frío, criollo, amarillo, blanco, industria, '
          'riego ni raleo. En México el promedio nacional reciente ronda ~8 t/ha.',
    ],
  ),
  kDz01CriolloRegional: PeachTreeYieldReference(
    profileId: kDz01CriolloRegional,
    fullKgPerTree: YieldRange(20, 38, 60),
    expectedTonPerHa: YieldRange(6, 14, 28),
    confidenceBase: 0.45,
    notesEs: <String>[
      'Criollo/regional es heterogéneo: puede ser muy bueno localmente, pero no '
          'asumir tecnificación. Calidad y mercado pueden limitar el valor.',
    ],
  ),
  kDz02TempranoBajoFrio: PeachTreeYieldReference(
    profileId: kDz02TempranoBajoFrio,
    fullKgPerTree: YieldRange(12, 25, 40),
    expectedTonPerHa: YieldRange(5, 11, 25),
    confidenceBase: 0.50,
    notesEs: <String>[
      'Bajo frío/temprano: el valor suele venir por ventana de mercado más que '
          'por toneladas. Muy sensible a frío insuficiente, helada tardía y '
          'calor en cuajado.',
    ],
  ),
  kDz03AmarilloComercial: PeachTreeYieldReference(
    profileId: kDz03AmarilloComercial,
    fullKgPerTree: YieldRange(25, 45, 70),
    expectedTonPerHa: YieldRange(10, 22, 40),
    confidenceBase: 0.65,
    notesEs: <String>[
      'Perfil comercial fresco con potencial medio-alto si hay riego, poda, '
          'raleo y sanidad. Kentucky ~17-22 t/ha; California moderno hasta ~34-45 '
          't/ha como techo tecnificado.',
    ],
  ),
  kDz04BlancoDulce: PeachTreeYieldReference(
    profileId: kDz04BlancoDulce,
    fullKgPerTree: YieldRange(15, 30, 50),
    expectedTonPerHa: YieldRange(6, 15, 30),
    confidenceBase: 0.50,
    notesEs: <String>[
      'Perfil premium/nicho: calidad, sabor y manejo de cosecha pesan más que el '
          'volumen. Premium NO significa más toneladas.',
    ],
  ),
  kDz05TardioIndustria: PeachTreeYieldReference(
    profileId: kDz05TardioIndustria,
    fullKgPerTree: YieldRange(25, 50, 75),
    expectedTonPerHa: YieldRange(12, 28, 45),
    confidenceBase: 0.62,
    notesEs: <String>[
      'Industria/tardío puede tener alto volumen en sistema comercial tipo '
          'California/proceso (~38-45 t/ha en huerto maduro); no asumirlo en SKIP.',
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

/// Multiplicadores por estado productivo (doc 03 §9): low/expected/high.
({double low, double expected, double high}) _productionStateFactors(
  PeachProductionState state,
) {
  return switch (state) {
    PeachProductionState.nonProductive => (low: 0, expected: 0, high: 0),
    PeachProductionState.firstBearing => (low: 0.05, expected: 0.15, high: 0.28),
    PeachProductionState.youngBearing => (low: 0.25, expected: 0.50, high: 0.72),
    PeachProductionState.fullBearing => (low: 0.75, expected: 1.00, high: 1.15),
    // Carga baja por helada/cuajado fallido: 0-45% del esperado (doc 03 §6).
    PeachProductionState.frostOrPoorSetLowCrop => (
      low: 0.0,
      expected: 0.20,
      high: 0.45,
    ),
    // Sobrecarga con fruta chica: kg biológico alto, calidad comercial baja.
    PeachProductionState.overloadedSmallFruit => (
      low: 0.80,
      expected: 0.95,
      high: 1.10,
    ),
    PeachProductionState.unknown => (low: 0.30, expected: 0.55, high: 0.85),
  };
}

double _managementFactor(PeachManagementLevel? level) => switch (level) {
  null => 1.0,
  PeachManagementLevel.low => 0.58,
  PeachManagementLevel.medium => 0.88,
  PeachManagementLevel.good => 1.07,
  PeachManagementLevel.high => 1.25,
  PeachManagementLevel.exceptional => 1.42,
};

double _irrigationFactor(PeachIrrigationLevel? level) => switch (level) {
  null => 1.0,
  PeachIrrigationLevel.rainfed => 0.60,
  PeachIrrigationLevel.irregular => 0.80,
  PeachIrrigationLevel.stable => 1.02,
  PeachIrrigationLevel.fertigation => 1.12,
};

/// Factor por carga/raleo visible (doc 03 §9 cropLoadModifier). `heavy` sube el
/// kg biológico levemente pero NO la calidad comercial (eso lo lleva
/// [PeachTreeYieldProjection.commercialQualityFactor]).
double _cropLoadFactor(PeachCropLoadStatus? status) => switch (status) {
  null => 1.0,
  PeachCropLoadStatus.noVisibleFruit => 0.30,
  PeachCropLoadStatus.light => 0.55,
  PeachCropLoadStatus.balanced => 1.0,
  PeachCropLoadStatus.heavy => 1.08,
  PeachCropLoadStatus.unknown => 1.0,
};

/// Inferencia de estado productivo (doc 03 §11). Regla propia del durazno: en
/// `productive_season`, la FLORACIÓN no infiere plena producción (mucha flor no
/// asegura carga); el cuajado es young/unknown y el fruto visible sí es pleno.
PeachProductionState _inferProductionState({
  required String stateId,
  required String stageId,
  PeachProductionState? explicit,
}) {
  if (explicit != null) return explicit;
  if (stateId == TreeStateIds.newlyPlanted ||
      stateId == TreeStateIds.juvenileNonProductive) {
    return PeachProductionState.nonProductive;
  }
  if (stateId == TreeStateIds.productiveSeason) {
    return switch (stageId) {
      // Floración: NO plena producción por default (doc 03 §11).
      TreeStageIds.flowering => PeachProductionState.unknown,
      TreeStageIds.fruitSet => PeachProductionState.youngBearing,
      TreeStageIds.fruitFill ||
      TreeStageIds.harvestMaturity ||
      TreeStageIds.postHarvest => PeachProductionState.fullBearing,
      _ => PeachProductionState.unknown,
    };
  }
  // established u otros: sin confirmación de carga, conservador.
  return PeachProductionState.unknown;
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

/// Calcula la proyección aproximada de rendimiento del durazno (doc 03 §8-§11).
PeachTreeYieldProjection resolvePeachTreeYield({
  required String? profileId,
  required String? perennialStateId,
  required String? phenologyStageId,
  double? treesPerHa,
  double? hectares,
  int? treeCount,
  PeachProductionState? productionState,
  PeachManagementLevel? managementLevel,
  PeachIrrigationLevel? irrigationLevel,
  PeachCropLoadStatus? cropLoadStatus,
  bool? fruitVisible,
  PeachTreeStressMemory? stressMemory,
}) {
  final stateId = normalizeTreeStateId(perennialStateId);
  final stageId = normalizeTreeStageId(phenologyStageId);
  final ref =
      peachYieldReferenceByProfile[profileId?.trim().toLowerCase()] ??
      peachYieldReferenceByProfile[kDzSkip]!;

  // 1. Bloqueo no productivo.
  if (_blocksYield(stateId, stageId)) {
    return PeachTreeYieldProjection.zero(
      profileId: ref.profileId,
      confidence: 0.85,
      notesEs: const <String>[
        'No proyectamos cosecha todavía porque tu duraznero aún está en '
            'formación. Importa más formar raíz, estructura y reservas.',
      ],
    );
  }

  final state = _inferProductionState(
    stateId: stateId,
    stageId: stageId,
    explicit: productionState,
  );
  if (state == PeachProductionState.nonProductive) {
    return PeachTreeYieldProjection.zero(
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
  final cropLoad = _cropLoadFactor(cropLoadStatus);
  final stress = stressMemory?.yieldFactor01 ?? 1.0;
  final commonFactor = mgmt * irr * cropLoad * stress;

  // 5. kg/árbol con factores de estado + comunes, luego tope por densidad.
  YieldRange kgTree = ref.fullKgPerTree
      .scaleEach(sf.low, sf.expected, sf.high)
      .scale(commonFactor);
  if (density != null) {
    kgTree = kgTree.cappedAt(
      PeachDensitySystem.fromTreesPerHa(density).kgPerTreeCap,
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

  // 8. Calidad comercial: sobrecarga sin raleo baja calibre comercial (doc 03 §6).
  final double commercialQuality =
      (state == PeachProductionState.overloadedSmallFruit ||
          cropLoadStatus == PeachCropLoadStatus.heavy)
      ? 0.78
      : 1.0;

  // 9. Confianza.
  double confidence = ref.confidenceBase;
  if (density == null) confidence -= 0.15;
  if (state == PeachProductionState.unknown) confidence -= 0.10;
  if (stageId == TreeStageIds.unknown) confidence -= 0.05;
  if (resolvedFruitVisible) confidence += 0.08;
  if (stressMemory != null && stressMemory.hasAnyStress) confidence -= 0.10;
  confidence = confidence.clamp(0.05, 0.95);

  final notes = <String>[...ref.notesEs];
  if (ref.profileId == kDzSkip) {
    notes.add(
      'Este cálculo usa un perfil general de durazno. Puede mejorar si eliges si '
      'es criollo/regional, bajo frío, amarillo comercial, blanco/dulce o '
      'tardío/industria.',
    );
  }
  if (density == null) {
    notes.add(
      'Sin densidad ni número de árboles no estimamos t/ha; indica árboles/ha o '
      'marco de plantación para más precisión.',
    );
  }
  if (stageId == TreeStageIds.flowering && !resolvedFruitVisible) {
    notes.add(
      'El duraznero puede tener mucha flor y aun así producir poco si hubo '
      'helada, frío, lluvia o estrés. La estimación sube cuando confirmas '
      'frutito o fruto visible.',
    );
  }
  if (commercialQuality < 1.0) {
    notes.add(
      'Con mucha fruta sin raleo, el árbol puede dar kg pero con calibre y '
      'calidad comercial menores. En durazno la carga y el raleo pesan mucho.',
    );
  }
  if (stress < 1.0) {
    notes.add(
      'Ajustamos a la baja por estrés guardado (helada, mal cuajado, sequía en '
      'llenado, calor, granizo, defoliación o postcosecha débil). El ciclo '
      'puede moverse mucho.',
    );
  }

  return PeachTreeYieldProjection(
    isProductive: true,
    profileId: ref.profileId,
    productionState: state,
    confidence01: confidence,
    kgPerTree: kgTree,
    tonPerHa: tonHa,
    totalKg: totalKg,
    commercialQualityFactor: commercialQuality,
    notesEs: notes,
  );
}
