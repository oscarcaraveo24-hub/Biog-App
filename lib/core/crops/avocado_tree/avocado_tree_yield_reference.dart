/// Rendimiento aproximado del Aguacate (doc 03 oficial).
///
/// Reglas no negociables:
/// - El rendimiento del aguacate NO se calcula como cultivo anual ni desde
///   `sowingDate`: se estima por kg de aguacate fresco/arbol + arboles/ha +
///   estado productivo + perfil AG + densidad + manejo + riego/drenaje +
///   floracion/polinizacion/cuajado + carga + calidad comercial + memoria de
///   estres + confianza (doc 03 §0.5, §13).
/// - Es APROXIMADO y en rango (bajo / esperado / alto). Nunca es promesa.
/// - Estados no productivos y etapas de establecimiento proyectan 0.
/// - `post_harvest` NO cierra el cultivo ni borra historial (doc 03 §0.5): es
///   ventana viva que prepara la siguiente floracion.
/// - La salida principal es kg de aguacate fresco/arbol y t/ha, NO numero de
///   frutos, cajas, materia seca, aceite ni precio (doc 03 §0.3).
/// - El aguacate NO usa kg/arbol de mango/limón/naranjo/manzano (doc 03 §0.1,
///   §16). Tiene fisiologia propia: raiz superficial muy sensible, floracion
///   A/B, cuajado FRAGIL (menos de 1% de flor llega a fruto), caida fisiologica
///   y por estres, alternancia marcada, fruta que madura DESPUES del corte y
///   postcosecha viva. El cuello de botella incluye raiz/agua/EC/Phytophthora
///   ademas de floracion/cuajado; la polinizacion A/B es contexto, no el unico
///   factor.
/// - El fallback de perfil es SIEMPRE AG-SKIP de aguacate, NUNCA el SKIP de otro
///   arbol (doc 03 §11, §16).
///
/// Aditivo: NO reemplaza el motor minimo `TreeYieldReferenceCatalog`.
library;

import 'package:bio_g/core/crops/avocado_tree/avocado_tree_catalog.dart';
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

/// Referencia base de rendimiento por perfil AG (doc 03 §11.2).
class AvocadoTreeYieldReference {
  const AvocadoTreeYieldReference({
    required this.profileId,
    required this.fullKgPerTree,
    required this.expectedTonPerHa,
    required this.confidenceBase,
    this.commercialFruitPct = const YieldRange(40, 62, 78),
    this.notesEs = const <String>[],
  });

  final String profileId;
  final YieldRange fullKgPerTree;
  final YieldRange expectedTonPerHa;
  final double confidenceBase;

  /// Porcentaje orientativo de fruta comercializable. Contexto de calidad
  /// (doc 03 §0.3, §9.5). NO entra al calculo principal de kg biologicos.
  final YieldRange commercialFruitPct;
  final List<String> notesEs;
}

/// Estado productivo del aguacate (doc 03 §6). Incluye alternancia (on/off),
/// floracion sin cuajado y raiz/salinidad: en aguacate el evento reproductivo
/// es FRAGIL y NO esta garantizado.
enum AvocadoProductionState {
  nonProductive,
  firstBearing,
  youngBearing,
  fullBearing,
  floweringButNoSet,
  lowSetOrDropYear,
  alternateBearingHighYear,
  alternateBearingLowYear,
  rootDeclineOrSalinityYear,
  oldDeclining,
  unknown,
}

enum AvocadoManagementLevel { low, medium, good, high, exceptional }

enum AvocadoIrrigationLevel {
  rainfedHumid,
  rainfedDry,
  irregular,
  stable,
  microSprinkler,
  fertigation,
  waterloggingRisk,
  salinityAwareManaged,
}

/// Calidad de floracion / polinizacion / cuajado / amarre (doc 03 §9.1). En
/// aguacate mucha flor NO es cosecha; el cuello de botella incluye tipo A/B,
/// abejas, clima, salinidad y raiz.
enum AvocadoBloomSetStatus {
  unknown,
  inductionLikely,
  goodBloomGoodSet,
  fruitSetConfirmed,
  offBloomMendezManaged,
  heavyBloomPoorSet,
  weakBloom,
  typeABMismatchOrLowBeeActivity,
  heatColdRainSetLoss,
  salinityRootSetLoss,
  offBloomDrop,
  noFloweringLikely,
}

/// Polinizacion especifica A/B (doc 03 §9.2). Contexto: la presencia de
/// compatible ayuda SOLO si coincide floracion y hay polinizadores.
enum AvocadoPollinationStatus {
  unknown,
  selfOnlyButNormal,
  compatibleTypeBNearby,
  compatibleTypeANearby,
  lowBeeActivity,
  weatherMismatch,
  noCompatibleKnown,
}

/// Carga visible de fruto (doc 03 §9.3).
enum AvocadoCropLoadStatus { noneVisible, light, balanced, heavy, veryHeavy, unknown }

/// Riesgo de calidad comercial (doc 03 §9.4). NO borra kg biologicos: solo baja
/// el porcentaje comercializable y agrega nota.
enum AvocadoCommercialQualityRisk { none, mild, moderate, severe }

/// Severidad de estres guardada en memoria multianual (doc 03 §10).
enum AvocadoStressSeverity { none, mild, moderate, severe }

/// Memoria de estres del aguacate (doc 03 §10.2 / doc 04 §8). El aguacate tiene
/// memoria fuerte de 1-2 ciclos: raiz/Phytophthora, salinidad, floracion/cuajado
/// golpeados, caida de frutito, carga alta o una postcosecha debil afectan el
/// rendimiento actual y el siguiente. Solo modula el rendimiento; nunca borra
/// historial ni etapa.
class AvocadoTreeStressMemory {
  const AvocadoTreeStressMemory({
    this.floweringHeatOrCold = AvocadoStressSeverity.none,
    this.bloomRainOrWind = AvocadoStressSeverity.none,
    this.lowBeeActivity = AvocadoStressSeverity.none,
    this.fruitSetDrop = AvocadoStressSeverity.none,
    this.fruitFillWaterStress = AvocadoStressSeverity.none,
    this.waterloggingOrPoorDrainage = AvocadoStressSeverity.none,
    this.phytophthoraOrRootDecline = AvocadoStressSeverity.none,
    this.salinityChlorideSodiumBoron = AvocadoStressSeverity.none,
    this.heatSunburnStress = AvocadoStressSeverity.none,
    this.thripsMiteScabAnthracnoseDamage = AvocadoStressSeverity.none,
    this.alternateBearing = AvocadoStressSeverity.none,
    this.heavyCropReserveDepletion = AvocadoStressSeverity.none,
    this.postHarvestReserveRisk = AvocadoStressSeverity.none,
  });

  final AvocadoStressSeverity floweringHeatOrCold;
  final AvocadoStressSeverity bloomRainOrWind;
  final AvocadoStressSeverity lowBeeActivity;
  final AvocadoStressSeverity fruitSetDrop;
  final AvocadoStressSeverity fruitFillWaterStress;
  final AvocadoStressSeverity waterloggingOrPoorDrainage;
  final AvocadoStressSeverity phytophthoraOrRootDecline;
  final AvocadoStressSeverity salinityChlorideSodiumBoron;
  final AvocadoStressSeverity heatSunburnStress;
  final AvocadoStressSeverity thripsMiteScabAnthracnoseDamage;
  final AvocadoStressSeverity alternateBearing;
  final AvocadoStressSeverity heavyCropReserveDepletion;
  final AvocadoStressSeverity postHarvestReserveRisk;

  bool get hasAnyStress =>
      floweringHeatOrCold != AvocadoStressSeverity.none ||
      bloomRainOrWind != AvocadoStressSeverity.none ||
      lowBeeActivity != AvocadoStressSeverity.none ||
      fruitSetDrop != AvocadoStressSeverity.none ||
      fruitFillWaterStress != AvocadoStressSeverity.none ||
      waterloggingOrPoorDrainage != AvocadoStressSeverity.none ||
      phytophthoraOrRootDecline != AvocadoStressSeverity.none ||
      salinityChlorideSodiumBoron != AvocadoStressSeverity.none ||
      heatSunburnStress != AvocadoStressSeverity.none ||
      thripsMiteScabAnthracnoseDamage != AvocadoStressSeverity.none ||
      alternateBearing != AvocadoStressSeverity.none ||
      heavyCropReserveDepletion != AvocadoStressSeverity.none ||
      postHarvestReserveRisk != AvocadoStressSeverity.none;

  /// Factor de rendimiento combinado 0..1 (doc 03 §10.3). Se toma el evento mas
  /// severo (el cuello de botella del ciclo); no se multiplican todos. Hard caps
  /// del doc: Phytophthora/raiz severa max 0.30; encharque severo max 0.35;
  /// salinidad/cloruros/boro severos max 0.40; caida de fruta severa max 0.35;
  /// off-year fuerte max 0.50.
  double get yieldFactor01 {
    double factorFor(AvocadoStressSeverity s) => switch (s) {
      AvocadoStressSeverity.none => 1.0,
      AvocadoStressSeverity.mild => 0.88,
      AvocadoStressSeverity.moderate => 0.65,
      AvocadoStressSeverity.severe => 0.35,
    };
    final factors = <double>[
      factorFor(floweringHeatOrCold),
      factorFor(bloomRainOrWind),
      factorFor(lowBeeActivity),
      factorFor(fruitSetDrop),
      factorFor(fruitFillWaterStress),
      factorFor(waterloggingOrPoorDrainage),
      factorFor(phytophthoraOrRootDecline),
      factorFor(salinityChlorideSodiumBoron),
      factorFor(heatSunburnStress),
      factorFor(thripsMiteScabAnthracnoseDamage),
      factorFor(alternateBearing),
      factorFor(heavyCropReserveDepletion),
      factorFor(postHarvestReserveRisk),
    ];
    double worst = factors.reduce((a, b) => a < b ? a : b);

    // Hard caps por evento severo especifico (doc 03 §10.3).
    if (phytophthoraOrRootDecline == AvocadoStressSeverity.severe &&
        worst > 0.30) {
      worst = 0.30;
    }
    if (waterloggingOrPoorDrainage == AvocadoStressSeverity.severe &&
        worst > 0.35) {
      worst = 0.35;
    }
    if (fruitSetDrop == AvocadoStressSeverity.severe && worst > 0.35) {
      worst = 0.35;
    }
    if (salinityChlorideSodiumBoron == AvocadoStressSeverity.severe &&
        worst > 0.40) {
      worst = 0.40;
    }
    if (alternateBearing == AvocadoStressSeverity.severe && worst > 0.50) {
      worst = 0.50;
    }
    return worst;
  }
}

/// Sistema de densidad (doc 03 §7.3): define el tope de kg/arbol. El cap evita
/// que la alta densidad multiplique kg/arbol como si cada arbol fuera amplio y
/// aislado (competencia de luz, agua, raiz, oxigeno y manejo de copa). En
/// aguacate la competencia por raiz/agua/oxigeno es especialmente fuerte.
class AvocadoDensitySystem {
  const AvocadoDensitySystem(this.id, this.kgPerTreeCap);

  final String id;
  final double kgPerTreeCap;

  static const AvocadoDensitySystem extensive = AvocadoDensitySystem(
    'extensive_or_old_spacing_under_180_trees_ha',
    145,
  );
  static const AvocadoDensitySystem traditional = AvocadoDensitySystem(
    'traditional_180_300_trees_ha',
    110,
  );
  static const AvocadoDensitySystem commercialModerate = AvocadoDensitySystem(
    'commercial_300_500_trees_ha',
    82,
  );
  static const AvocadoDensitySystem highDensityManaged = AvocadoDensitySystem(
    'high_density_500_800_trees_ha',
    55,
  );
  static const AvocadoDensitySystem veryHighDensityManaged =
      AvocadoDensitySystem(
    'very_high_density_800_1200_trees_ha',
    36,
  );
  static const AvocadoDensitySystem ultraHighDensity = AvocadoDensitySystem(
    'ultra_high_density_over_1200_trees_ha',
    26,
  );

  static AvocadoDensitySystem fromTreesPerHa(double treesPerHa) {
    if (treesPerHa < 180) return extensive;
    if (treesPerHa < 300) return traditional;
    if (treesPerHa < 500) return commercialModerate;
    if (treesPerHa < 800) return highDensityManaged;
    if (treesPerHa < 1200) return veryHighDensityManaged;
    return ultraHighDensity;
  }
}

/// Proyeccion de rendimiento aproximada del aguacate.
class AvocadoTreeYieldProjection {
  const AvocadoTreeYieldProjection({
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
  final AvocadoProductionState productionState;
  final double confidence01;

  final YieldRange? kgPerTree;
  final YieldRange? tonPerHa;
  final YieldRange? totalKg;

  /// Contexto de calidad: fruta comercializable (doc 03 §0.3, §9.5).
  final YieldRange? commercialFruitPct;

  final List<String> notesEs;

  factory AvocadoTreeYieldProjection.zero({
    required String profileId,
    required double confidence,
    List<String> notesEs = const <String>[],
  }) => AvocadoTreeYieldProjection(
    isProductive: false,
    profileId: profileId,
    productionState: AvocadoProductionState.nonProductive,
    confidence01: confidence,
    kgPerTree: YieldRange.zero,
    notesEs: notesEs,
  );
}

/// Tabla de referencia por perfil (doc 03 §4, §11.2). kg de aguacate fresco/arbol.
const Map<String, AvocadoTreeYieldReference> avocadoYieldReferenceByProfile =
    <String, AvocadoTreeYieldReference>{
      kAgSkip: AvocadoTreeYieldReference(
        profileId: kAgSkip,
        fullKgPerTree: YieldRange(15, 40, 75),
        expectedTonPerHa: YieldRange(3.5, 9.5, 16),
        confidenceBase: 0.42,
        commercialFruitPct: YieldRange(40, 62, 78),
        notesEs: <String>[
          'Perfil general: no asume Hass, Méndez, Fuerte, criollo, antillano, '
              'tipo floral A/B, portainjerto, densidad, riego ni manejo técnico. '
              'No sobreestimar.',
        ],
      ),
      kAg01Hass: AvocadoTreeYieldReference(
        profileId: kAg01Hass,
        fullKgPerTree: YieldRange(25, 55, 100),
        expectedTonPerHa: YieldRange(7, 14, 24),
        confidenceBase: 0.68,
        commercialFruitPct: YieldRange(55, 75, 90),
        notesEs: <String>[
          'Hass: potencial bueno con raíz sana, riego estable, baja salinidad, '
              'poda/luz y carga confirmada. Vigilar alternancia, calibre y '
              'madurez de corte. Exportación es calidad, no garantía de kg.',
        ],
      ),
      kAg02MendezCarmen: AvocadoTreeYieldReference(
        profileId: kAg02MendezCarmen,
        fullKgPerTree: YieldRange(22, 55, 95),
        expectedTonPerHa: YieldRange(8, 15, 24),
        confidenceBase: 0.58,
        commercialFruitPct: YieldRange(52, 72, 88),
        notesEs: <String>[
          'Méndez/Carmen: ventana temprana/off-bloom; no asumir más kg que Hass '
              'por ser temprano. La floración fuera de temporada puede tirar '
              'fruta si clima/agua/raíz fallan.',
        ],
      ),
      kAg03CriolloMexicano: AvocadoTreeYieldReference(
        profileId: kAg03CriolloMexicano,
        fullKgPerTree: YieldRange(12, 35, 85),
        expectedTonPerHa: YieldRange(2.5, 7.5, 16),
        confidenceBase: 0.38,
        commercialFruitPct: YieldRange(30, 55, 75),
        notesEs: <String>[
          'Criollo/mexicano: muy heterogéneo; puede haber árboles grandes, pero '
              'calidad, densidad, ventana y alternancia varían mucho. Confianza '
              'baja sin historial.',
        ],
      ),
      kAg04FuertePielVerde: AvocadoTreeYieldReference(
        profileId: kAg04FuertePielVerde,
        fullKgPerTree: YieldRange(18, 42, 80),
        expectedTonPerHa: YieldRange(4.5, 10, 18),
        confidenceBase: 0.50,
        commercialFruitPct: YieldRange(42, 62, 80),
        notesEs: <String>[
          'Fuerte/piel verde: tipo B y posible polinizador de Hass; puede '
              'alternar o ser inconsistente. No tratarlo como Hass negro de '
              'exportación.',
        ],
      ),
      kAg05AntillanoTropical: AvocadoTreeYieldReference(
        profileId: kAg05AntillanoTropical,
        fullKgPerTree: YieldRange(30, 70, 130),
        expectedTonPerHa: YieldRange(7, 15, 26),
        confidenceBase: 0.50,
        commercialFruitPct: YieldRange(40, 62, 80),
        notesEs: <String>[
          'Antillano/tropical: fruto grande puede subir kg/árbol, pero no '
              'equivale a Hass exportación. Vigilar drenaje, antracnosis/roña, '
              'calidad externa y poscosecha.',
        ],
      ),
      kAg06TardioLambReed: AvocadoTreeYieldReference(
        profileId: kAg06TardioLambReed,
        fullKgPerTree: YieldRange(25, 60, 110),
        expectedTonPerHa: YieldRange(7, 16, 27),
        confidenceBase: 0.54,
        commercialFruitPct: YieldRange(52, 72, 88),
        notesEs: <String>[
          'Tardío/Lamb Hass/Reed: ventana extendida y potencial bueno, pero no '
              'default. Requiere corte correcto, carga confirmada, luz/poda y '
              'mercado.',
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
/// canonico (doc 03 §11.3).
String? _normalizeAvocadoProfileId(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  if (id == null || id.isEmpty) return id;
  return switch (id) {
    'ag-skip' || 'ag_general' || 'avocado' || 'aguacate' || 'palta' || 'palto' =>
      kAgSkip,
    'ag_01' || 'ag-01' || 'hass' || 'aguacate_hass' => kAg01Hass,
    'ag_02' ||
    'ag-02' ||
    'mendez' ||
    'méndez' ||
    'carmen' ||
    'hass_mendez' ||
    'hass-mendez' => kAg02MendezCarmen,
    'ag_03' ||
    'ag-03' ||
    'criollo' ||
    'mexicano' ||
    'regional' ||
    'nacional' => kAg03CriolloMexicano,
    'ag_04' ||
    'ag-04' ||
    'fuerte' ||
    'piel_verde' ||
    'green_skin' => kAg04FuertePielVerde,
    'ag_05' ||
    'ag-05' ||
    'antillano' ||
    'tropical' ||
    'costa' ||
    'west_indian' => kAg05AntillanoTropical,
    'ag_06' ||
    'ag-06' ||
    'lamb_hass' ||
    'lamb' ||
    'reed' ||
    'tardio' ||
    'tardío' => kAg06TardioLambReed,
    _ => id,
  };
}

/// Multiplicadores por estado productivo (doc 03 §6.1).
({double low, double expected, double high}) _productionStateFactors(
  AvocadoProductionState state,
) {
  return switch (state) {
    AvocadoProductionState.nonProductive => (low: 0, expected: 0, high: 0),
    AvocadoProductionState.firstBearing => (
      low: 0.05,
      expected: 0.18,
      high: 0.35,
    ),
    AvocadoProductionState.youngBearing => (
      low: 0.20,
      expected: 0.50,
      high: 0.85,
    ),
    AvocadoProductionState.fullBearing => (low: 0.65, expected: 1.00, high: 1.20),
    AvocadoProductionState.floweringButNoSet => (
      low: 0.08,
      expected: 0.28,
      high: 0.55,
    ),
    AvocadoProductionState.lowSetOrDropYear => (
      low: 0.08,
      expected: 0.32,
      high: 0.60,
    ),
    AvocadoProductionState.alternateBearingHighYear => (
      low: 0.85,
      expected: 1.12,
      high: 1.40,
    ),
    AvocadoProductionState.alternateBearingLowYear => (
      low: 0.05,
      expected: 0.25,
      high: 0.55,
    ),
    AvocadoProductionState.rootDeclineOrSalinityYear => (
      low: 0.05,
      expected: 0.22,
      high: 0.50,
    ),
    AvocadoProductionState.oldDeclining => (
      low: 0.20,
      expected: 0.50,
      high: 0.85,
    ),
    AvocadoProductionState.unknown => (low: 0.20, expected: 0.50, high: 0.80),
  };
}

double _managementFactor(AvocadoManagementLevel? level) => switch (level) {
  null => 1.0,
  AvocadoManagementLevel.low => 0.55,
  AvocadoManagementLevel.medium => 0.85,
  AvocadoManagementLevel.good => 1.05,
  AvocadoManagementLevel.high => 1.18,
  AvocadoManagementLevel.exceptional => 1.28,
};

/// Convierte el porcentaje de cuidado del usuario a factor (doc 03 §8.2). 100%
/// = manejo correcto para el potencial base del perfil, NO cosecha maxima.
double _carePercentFactor(double? carePercent) {
  if (carePercent == null) return 1.0;
  final p = carePercent.clamp(0, 130).toDouble();
  if (p <= 30) return 0.35;
  if (p <= 50) return 0.55;
  if (p <= 70) return 0.74;
  if (p <= 90) return 0.90;
  if (p <= 105) return 1.00;
  if (p <= 115) return 1.10;
  if (p <= 125) return 1.18;
  return 1.24;
}

/// Riego y drenaje (doc 03 §8.3). En aguacate el riego NO premia el exceso de
/// agua: la saturacion sostenida y la raiz sin oxigeno bajan mas el rendimiento
/// que una lectura moderadamente seca fuera de etapa critica.
double _irrigationFactor(AvocadoIrrigationLevel? level) => switch (level) {
  null => 1.0,
  AvocadoIrrigationLevel.rainfedHumid => 0.78,
  AvocadoIrrigationLevel.rainfedDry => 0.48,
  AvocadoIrrigationLevel.irregular => 0.65,
  AvocadoIrrigationLevel.stable => 1.03,
  AvocadoIrrigationLevel.microSprinkler => 1.08,
  AvocadoIrrigationLevel.fertigation => 1.12,
  AvocadoIrrigationLevel.waterloggingRisk => 0.45,
  AvocadoIrrigationLevel.salinityAwareManaged => 0.98,
};

/// Factor de floracion/polinizacion/cuajado (doc 03 §9.1). Si no se sabe, no
/// destruye el calculo (baja confianza). Menos de 1% de flor llega a fruto: la
/// floracion abundante con mal cuajado tumba el amarre.
double _bloomSetFactor(AvocadoBloomSetStatus? status) => switch (status) {
  null || AvocadoBloomSetStatus.unknown => 1.0,
  AvocadoBloomSetStatus.inductionLikely => 1.02,
  AvocadoBloomSetStatus.goodBloomGoodSet => 1.08,
  AvocadoBloomSetStatus.fruitSetConfirmed => 1.05,
  AvocadoBloomSetStatus.offBloomMendezManaged => 1.00,
  AvocadoBloomSetStatus.heavyBloomPoorSet => 0.55,
  AvocadoBloomSetStatus.weakBloom => 0.58,
  AvocadoBloomSetStatus.typeABMismatchOrLowBeeActivity => 0.68,
  AvocadoBloomSetStatus.heatColdRainSetLoss => 0.45,
  AvocadoBloomSetStatus.salinityRootSetLoss => 0.40,
  AvocadoBloomSetStatus.offBloomDrop => 0.50,
  AvocadoBloomSetStatus.noFloweringLikely => 0.20,
};

/// Factor de polinizacion A/B (doc 03 §9.2). La compatibilidad ayuda solo si
/// coincide floracion y hay polinizadores; NO es un multiplicador enorme.
double _pollinationFactor(AvocadoPollinationStatus? status) => switch (status) {
  null || AvocadoPollinationStatus.unknown => 1.0,
  AvocadoPollinationStatus.selfOnlyButNormal => 0.95,
  AvocadoPollinationStatus.compatibleTypeBNearby => 1.06,
  AvocadoPollinationStatus.compatibleTypeANearby => 1.04,
  AvocadoPollinationStatus.lowBeeActivity => 0.75,
  AvocadoPollinationStatus.weatherMismatch => 0.65,
  AvocadoPollinationStatus.noCompatibleKnown => 0.88,
};

/// Factor de carga visible (doc 03 §9.3). Carga heavy/veryHeavy sube kg
/// biologicos, pero puede bajar calibre/calidad, retorno floral y reservas del
/// siguiente ciclo (se maneja como nota/alternancia aparte).
double _cropLoadFactor(AvocadoCropLoadStatus? status) => switch (status) {
  null || AvocadoCropLoadStatus.unknown => 1.0,
  AvocadoCropLoadStatus.noneVisible => 0.12,
  AvocadoCropLoadStatus.light => 0.45,
  AvocadoCropLoadStatus.balanced => 1.0,
  AvocadoCropLoadStatus.heavy => 1.08,
  AvocadoCropLoadStatus.veryHeavy => 1.12,
};

/// Factor de calidad comercial (doc 03 §9.4). NO borra kg biologicos: solo baja
/// el porcentaje comercializable.
double _commercialQualityFactor(AvocadoCommercialQualityRisk? risk) =>
    switch (risk) {
      null || AvocadoCommercialQualityRisk.none => 1.0,
      AvocadoCommercialQualityRisk.mild => 0.92,
      AvocadoCommercialQualityRisk.moderate => 0.76,
      AvocadoCommercialQualityRisk.severe => 0.55,
    };

/// Inferencia de estado productivo (doc 03 §6.2). Conservadora: floración se
/// trata como floweringButNoSet (flor no es cosecha); fruit_fill/harvest/
/// post_harvest como fullBearing por defecto conservador.
AvocadoProductionState _inferProductionState({
  required String stateId,
  required String stageId,
  AvocadoProductionState? explicit,
}) {
  if (explicit != null) return explicit;
  if (stateId == TreeStateIds.newlyPlanted ||
      stateId == TreeStateIds.juvenileNonProductive) {
    return AvocadoProductionState.nonProductive;
  }
  if (stateId == TreeStateIds.established ||
      stateId == TreeStateIds.productiveSeason) {
    return switch (stageId) {
      TreeStageIds.flowering => AvocadoProductionState.floweringButNoSet,
      TreeStageIds.fruitSet => AvocadoProductionState.lowSetOrDropYear,
      TreeStageIds.fruitFill ||
      TreeStageIds.harvestMaturity ||
      TreeStageIds.postHarvest => AvocadoProductionState.fullBearing,
      _ => AvocadoProductionState.unknown,
    };
  }
  return AvocadoProductionState.unknown;
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

/// Calcula la proyeccion aproximada de rendimiento del aguacate (doc 03 §13).
AvocadoTreeYieldProjection resolveAvocadoTreeYield({
  required String? profileId,
  required String? perennialStateId,
  required String? phenologyStageId,
  double? treesPerHa,
  double? hectares,
  int? treeCount,
  AvocadoProductionState? productionState,
  AvocadoManagementLevel? managementLevel,
  double? carePercent,
  AvocadoIrrigationLevel? irrigationLevel,
  AvocadoBloomSetStatus? bloomSetStatus,
  AvocadoPollinationStatus? pollinationStatus,
  AvocadoCropLoadStatus? cropLoadStatus,
  AvocadoCommercialQualityRisk? commercialQualityRisk,
  AvocadoTreeStressMemory? stressMemory,
}) {
  final stateId = normalizeTreeStateId(perennialStateId);
  final stageId = normalizeTreeStageId(phenologyStageId);
  final ref =
      avocadoYieldReferenceByProfile[_normalizeAvocadoProfileId(profileId)] ??
      avocadoYieldReferenceByProfile[kAgSkip]!;

  // 1. Bloqueo no productivo.
  if (_blocksYield(stateId, stageId)) {
    return AvocadoTreeYieldProjection.zero(
      profileId: ref.profileId,
      confidence: 0.85,
      notesEs: const <String>[
        'Todavía no proyectamos cosecha fuerte. En aguacate joven primero '
            'importa raíz sana, drenaje, copa, hoja y estructura. Forzar carga '
            'temprano puede cansar el árbol.',
      ],
    );
  }

  final state = _inferProductionState(
    stateId: stateId,
    stageId: stageId,
    explicit: productionState,
  );
  if (state == AvocadoProductionState.nonProductive) {
    return AvocadoTreeYieldProjection.zero(
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
  final poll = _pollinationFactor(pollinationStatus);
  final load = _cropLoadFactor(cropLoadStatus);
  final stress = stressMemory?.yieldFactor01 ?? 1.0;
  final commonFactor = managementCombined * irr * set * poll * load * stress;

  // 4. kg/arbol con factores de estado + comunes, luego tope por densidad.
  YieldRange kgTree = ref.fullKgPerTree
      .scaleEach(sf.low, sf.expected, sf.high)
      .scale(commonFactor);
  if (density != null) {
    kgTree = kgTree.cappedAt(
      AvocadoDensitySystem.fromTreesPerHa(density).kgPerTreeCap,
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
      managementLevel == AvocadoManagementLevel.high ||
      managementLevel == AvocadoManagementLevel.exceptional;
  final bool isReproStage =
      stageId == TreeStageIds.flowering || stageId == TreeStageIds.fruitSet;
  final bool rootOrSalinityStress =
      state == AvocadoProductionState.rootDeclineOrSalinityYear ||
      (stressMemory != null &&
          (stressMemory.phytophthoraOrRootDecline ==
                  AvocadoStressSeverity.severe ||
              stressMemory.salinityChlorideSodiumBoron ==
                  AvocadoStressSeverity.severe ||
              stressMemory.waterloggingOrPoorDrainage ==
                  AvocadoStressSeverity.severe));

  double confidence = ref.confidenceBase;
  if (density == null) confidence -= 0.15;
  if (state == AvocadoProductionState.unknown) confidence -= 0.10;
  if (stageId == TreeStageIds.unknown) confidence -= 0.05;
  if (isReproStage && bloomSetStatus == null) confidence -= 0.06;
  if (isReproStage && pollinationStatus == null) confidence -= 0.05;
  if (stageId == TreeStageIds.fruitFill && irrigationLevel == null) {
    confidence -= 0.05;
  }
  if (stressMemory != null && stressMemory.hasAnyStress) confidence -= 0.10;
  if (rootOrSalinityStress) confidence -= 0.15;
  if (commercialQualityRisk == AvocadoCommercialQualityRisk.severe) {
    confidence -= 0.05;
  }
  // Alta densidad sin manejo alto no es expectativa simple (doc 03 §13.3).
  if (isHighDensity && !managementIsHigh) confidence -= 0.10;
  if (density != null &&
      stageId != TreeStageIds.unknown &&
      (cropLoadStatus == AvocadoCropLoadStatus.balanced ||
          cropLoadStatus == AvocadoCropLoadStatus.heavy ||
          cropLoadStatus == AvocadoCropLoadStatus.veryHeavy)) {
    confidence += 0.05;
  }
  // El perfil general nunca pasa de 0.60 salvo historial real (doc 03 §13.3).
  if (ref.profileId == kAgSkip && confidence > 0.60) confidence = 0.60;
  // Criollo/regional sin historial: cap 0.55 (doc 03 §13.3).
  if (ref.profileId == kAg03CriolloMexicano && confidence > 0.55) {
    confidence = 0.55;
  }
  // Alta densidad sin historial no pasa de 0.70 (doc 03 §13.3).
  if (isHighDensity && confidence > 0.70) confidence = 0.70;
  confidence = confidence.clamp(0.05, 0.95);

  // 9. Notas.
  final notes = <String>[...ref.notesEs];
  if (ref.profileId == kAgSkip) {
    notes.add(
      'Este cálculo usa un perfil general de aguacate. Puede mejorar si eliges '
      'Hass, Méndez/Carmen, Criollo, Fuerte, Antillano o Tardío sin perder '
      'historial.',
    );
  }
  if (density == null) {
    notes.add(
      'Sin densidad ni número de árboles no estimamos t/ha con precisión; '
      'indica árboles/ha o marco de plantación para mejorar la proyección.',
    );
  }
  if (bloomSetStatus == AvocadoBloomSetStatus.noFloweringLikely ||
      bloomSetStatus == AvocadoBloomSetStatus.offBloomDrop) {
    notes.add(
      'En aguacate, mucha flor no significa cosecha: menos de una fracción '
      'pequeña llega a fruto. Revisa cuajado, clima, abejas (tipo A/B), agua y '
      'raíz antes de culpar al fertilizante.',
    );
  }
  if (bloomSetStatus == AvocadoBloomSetStatus.heavyBloomPoorSet ||
      bloomSetStatus == AvocadoBloomSetStatus.weakBloom ||
      bloomSetStatus == AvocadoBloomSetStatus.salinityRootSetLoss) {
    notes.add(
      'Florear mucho no es cosechar mucho. Si tiró flor o aguacatito, el '
      'rendimiento baja aunque el árbol se viera cargado de flor.',
    );
  }
  if (pollinationStatus == AvocadoPollinationStatus.lowBeeActivity ||
      pollinationStatus == AvocadoPollinationStatus.noCompatibleKnown) {
    notes.add(
      'La polinización puede ayudar si coincide la floración de un tipo '
      'compatible y hay actividad de abejas, pero no es receta: también mandan '
      'clima, agua y raíz.',
    );
  }
  if (commercialQualityRisk != null &&
      commercialQualityRisk != AvocadoCommercialQualityRisk.none) {
    notes.add(
      'Puede haber kg biológicos, pero no toda la fruta entra como buena: '
      'revisa calibre, madurez, golpe de sol, roña, trips y antracnosis.',
    );
  }
  if (cropLoadStatus == AvocadoCropLoadStatus.heavy ||
      cropLoadStatus == AvocadoCropLoadStatus.veryHeavy) {
    notes.add(
      'Cargar mucho aguacate sube kg, pero puede bajar calibre y cansar el '
      'siguiente ciclo si no recupera reservas en postcosecha (alternancia).',
    );
  }
  if (rootOrSalinityStress) {
    notes.add(
      'Ajustamos a la baja por raíz/salinidad. En aguacate, un árbol con raíz '
      'sospechosa, encharque o sales altas rinde menos aunque el NPK salga '
      'bien: primero drenaje, oxígeno y lavado técnico.',
    );
  } else if (stress < 1.0) {
    notes.add(
      'Ajustamos a la baja por memoria de estrés. Floración golpeada, caída de '
      'frutito, sales, agua o una postcosecha débil pueden pegarle al cuajado, '
      'al calibre y al siguiente ciclo.',
    );
  }
  if (tonHa != null && tonHa.expected > 20) {
    notes.add(
      'Proyección alta: confirma densidad real, poda, riego, carga, sanidad de '
      'raíz y fruta comercializable antes de tomarlo como expectativa. Es de '
      'huerta buena/tecnificada o año fuerte, no default.',
    );
  }
  if (tonHa != null && tonHa.expected > 30) {
    notes.add(
      'Proyección de sistema intensivo/validado: requiere poda, luz, riego/'
      'fertirriego, raíz sana, baja salinidad y carga confirmada. Valídalo '
      'localmente; no es expectativa normal.',
    );
  }

  return AvocadoTreeYieldProjection(
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
