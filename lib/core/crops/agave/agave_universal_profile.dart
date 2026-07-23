import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/agave/agave_catalog.dart';
import 'package:bio_g/core/crops/agave/agave_lifecycle.dart';

/// Perfil universal agronómico del Maguey / Agave ornamental (Documento B,
/// MG v1.0).
///
/// MISMAS UNIDADES REALES que el resto del ecosistema BIO-G (frijol, hortalizas,
/// granos, árboles, cactus, suculenta, sábila). No se negocia: el dashboard, el
/// motor de alertas y la pantalla NPK comparan contra estas unidades.
///
///   - humedad     → % (0..100)
///   - temperatura → °C
///   - pH          → pH
///   - EC          → mS/cm
///   - resistencia → MPa
///   - N / P / K   → mg/kg
///
/// **No son los números del cactus, la suculenta ni la sábila.** Se copia la
/// arquitectura, no la biología (Doc B §0.5). El maguey usa una banda hídrica
/// baja-moderada (el exceso sostenido pesa más que la sequía), tolera una banda
/// pH más alcalina, responde a N en crecimiento (cap y peso mayores que cactus)
/// y conserva K como cap más alto por su función estructural e hídrica.
///
/// Los valores marcados como defaults de ingeniería (D1 en el Doc B) están
/// pendientes de validación con la sonda BIO-G en sustrato real. Ninguno es una
/// dosis, una suficiencia de laboratorio ni un objetivo productivo (Doc B §14).
class AgaveUniversalProfile {
  const AgaveUniversalProfile._();

  // ── pH por CONTEXTO (Doc B §4.3) ───────────────────────────────────────────
  // El pH depende del contexto de cultivo, no de la etapa: la etapa cambia el
  // peso, no el rango. El maguey tolera una banda más alcalina que
  // cactus/suculenta general. Sin contexto declarado se usa el rango prudente
  // `unknown` (el perfil NO inventa un contexto que el usuario no declaró).

  /// Maceta / macetón / vivero: sustrato confinado, se acidifica y saliniza más
  /// rápido; banda más estrecha.
  static const AgroRange phPotNursery = AgroRange(
    lowMax: 4.8,
    optimalMin: 5.8,
    optimalMax: 7.2,
    highMin: 8.0,
  );

  /// Jardinera / cama drenante / rocalla.
  static const AgroRange phPlanterGarden = AgroRange(
    lowMax: 5.0,
    optimalMin: 6.0,
    optimalMax: 7.8,
    highMin: 8.5,
  );

  /// Paisaje / suelo abierto / cerca viva: tolera alcalinidad moderada.
  static const AgroRange phLandscapeGround = AgroRange(
    lowMax: 5.0,
    optimalMin: 6.0,
    optimalMax: 8.1,
    highMin: 8.8,
  );

  /// Contexto sin declarar: rango intermedio y prudente.
  static const AgroRange phUnknownContext = AgroRange(
    lowMax: 4.9,
    optimalMin: 5.8,
    optimalMax: 7.8,
    highMin: 8.5,
  );
}

/// Datos por etapa. Mismo patrón que `AloeUniversalProfile` y la suculenta.
class _AgaveStageProfile {
  const _AgaveStageProfile({
    required this.moisture,
    required this.soilTemp,
    required this.ec,
    required this.resistance,
    required this.nPpm,
    required this.pPpm,
    required this.kPpm,
    required this.wMoisture,
    required this.wSoilTemp,
    required this.wPh,
    required this.wEc,
    required this.wResistance,
    required this.wN,
    required this.wP,
    required this.wK,
    required this.nWindowEs,
    required this.pWindowEs,
    required this.kWindowEs,
    required this.nGuidanceEs,
    required this.pGuidanceEs,
    required this.kGuidanceEs,
    required this.careNoteEs,
  });

  final AgroRange moisture;
  final AgroRange soilTemp;
  final AgroRange ec;
  final AgroRange resistance;
  final AgroRange nPpm;
  final AgroRange pPpm;
  final AgroRange kPpm;
  final double wMoisture;
  final double wSoilTemp;
  final double wPh;
  final double wEc;
  final double wResistance;
  final double wN;
  final double wP;
  final double wK;
  final String nWindowEs;
  final String pWindowEs;
  final String kWindowEs;
  final String nGuidanceEs;
  final String pGuidanceEs;
  final String kGuidanceEs;
  final String careNoteEs;
}

// Los pesos de CADA etapa suman 1.00 (Doc B §6). Los targets son las tablas del
// Doc B §4 en unidades reales.
const Map<String, _AgaveStageProfile> _agaveStageProfiles =
    <String, _AgaveStageProfile>{
      // Recién plantado: raíz perturbada. Suficiente humedad para contacto, sin
      // saturar (Doc B §4.1).
      AgaveStageIds.installationEstablishment: _AgaveStageProfile(
        moisture: AgroRange(
          lowMax: 6,
          optimalMin: 12,
          optimalMax: 34,
          highMin: 50,
        ),
        soilTemp: AgroRange(
          lowMax: 5,
          optimalMin: 15,
          optimalMax: 30,
          highMin: 38,
        ),
        ec: AgroRange(
          lowMax: 0.15,
          optimalMin: 0.35,
          optimalMax: 1.3,
          highMin: 2.0,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.0,
          highMin: 1.6,
        ),
        nPpm: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 32, highMin: 50),
        pPpm: AgroRange(lowMax: 5, optimalMin: 9, optimalMax: 20, highMin: 32),
        kPpm: AgroRange(
          lowMax: 35,
          optimalMin: 60,
          optimalMax: 140,
          highMin: 200,
        ),
        wMoisture: 0.31,
        wSoilTemp: 0.14,
        wPh: 0.07,
        wEc: 0.11,
        wResistance: 0.16,
        wN: 0.08,
        wP: 0.06,
        wK: 0.07,
        nWindowEs: 'Sin demanda',
        pWindowEs: 'Apoyo a raíz',
        kWindowEs: 'Apoyo a raíz',
        nGuidanceEs:
            'No intentes acelerar el arraigo con mucho fertilizante.',
        pGuidanceEs: 'El fósforo acompaña el arraigo. No hace falta más.',
        kGuidanceEs: 'El potasio da firmeza mientras agarra raíz.',
        careNoteEs:
            'La raíz todavía se está acomodando. Mantén libre la salida del '
            'agua y evita que el suelo permanezca empapado.',
      ),
      // Echando raíz: la raíz explora el sustrato; el anclaje es prioritario
      // (Doc B §4.1, §6).
      AgaveStageIds.rootEstablishment: _AgaveStageProfile(
        moisture: AgroRange(
          lowMax: 6,
          optimalMin: 14,
          optimalMax: 36,
          highMin: 52,
        ),
        soilTemp: AgroRange(
          lowMax: 5,
          optimalMin: 15,
          optimalMax: 31,
          highMin: 38,
        ),
        ec: AgroRange(
          lowMax: 0.15,
          optimalMin: 0.35,
          optimalMax: 1.4,
          highMin: 2.1,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.1,
          highMin: 1.7,
        ),
        nPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 38, highMin: 58),
        pPpm: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 24, highMin: 36),
        kPpm: AgroRange(
          lowMax: 40,
          optimalMin: 70,
          optimalMax: 155,
          highMin: 215,
        ),
        wMoisture: 0.32,
        wSoilTemp: 0.14,
        wPh: 0.06,
        wEc: 0.11,
        wResistance: 0.16,
        wN: 0.07,
        wP: 0.07,
        wK: 0.07,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Ventana de raíz',
        kWindowEs: 'Apoyo a raíz',
        nGuidanceEs: 'El agua y la raíz pesan más que los nutrientes.',
        pGuidanceEs: 'Ventana buena para fósforo: la raíz lo está usando.',
        kGuidanceEs: 'El potasio ayuda a que aguante el cambio.',
        careNoteEs:
            'El maguey está afirmando la raíz. Revisa que el suelo no esté '
            'apretado y que pierda humedad antes de volver a regar.',
      ),
      // Creciendo y madurando: la etapa donde el NPK pesa de verdad. Madurar =
      // consolidar la planta, NO estar listo para jima (Doc B §2.8, §10).
      AgaveStageIds.activeGrowth: _AgaveStageProfile(
        moisture: AgroRange(
          lowMax: 8,
          optimalMin: 16,
          optimalMax: 40,
          highMin: 58,
        ),
        soilTemp: AgroRange(
          lowMax: 7,
          optimalMin: 18,
          optimalMax: 32,
          highMin: 40,
        ),
        ec: AgroRange(
          lowMax: 0.2,
          optimalMin: 0.45,
          optimalMax: 1.8,
          highMin: 2.8,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.4,
          highMin: 2.0,
        ),
        nPpm: AgroRange(
          lowMax: 15,
          optimalMin: 25,
          optimalMax: 55,
          highMin: 80,
        ),
        pPpm: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 32, highMin: 46),
        kPpm: AgroRange(
          lowMax: 55,
          optimalMin: 90,
          optimalMax: 190,
          highMin: 260,
        ),
        wMoisture: 0.26,
        wSoilTemp: 0.12,
        wPh: 0.08,
        wEc: 0.12,
        wResistance: 0.10,
        wN: 0.12,
        wP: 0.10,
        wK: 0.10,
        nWindowEs: 'Demanda activa',
        pWindowEs: 'Demanda activa',
        kWindowEs: 'Demanda activa',
        nGuidanceEs:
            'Los nutrientes importan más ahora, pero una lectura no define una '
            'dosis.',
        pGuidanceEs: 'El fósforo sostiene la raíz durante el crecimiento.',
        kGuidanceEs:
            'El potasio ayuda a la regulación del agua y la firmeza de la hoja.',
        careNoteEs:
            'Está formando hojas y estructura. Tolera sequedad, pero el '
            'crecimiento puede frenarse si pasa demasiado tiempo en condición '
            'extrema. Madurar aquí no es estar listo para jima.',
      ),
      // Maduro y estable: se queda aquí indefinidamente. NO cierra ciclo, NO es
      // jima ni azúcar (Doc B §2.8, §9.5, §10).
      AgaveStageIds.maintenance: _AgaveStageProfile(
        moisture: AgroRange(
          lowMax: 5,
          optimalMin: 10,
          optimalMax: 34,
          highMin: 52,
        ),
        soilTemp: AgroRange(
          lowMax: 3,
          optimalMin: 12,
          optimalMax: 32,
          highMin: 40,
        ),
        ec: AgroRange(
          lowMax: 0.15,
          optimalMin: 0.35,
          optimalMax: 1.6,
          highMin: 2.5,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.5,
          highMin: 2.1,
        ),
        nPpm: AgroRange(
          lowMax: 10,
          optimalMin: 18,
          optimalMax: 42,
          highMin: 65,
        ),
        pPpm: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 26, highMin: 40),
        kPpm: AgroRange(
          lowMax: 45,
          optimalMin: 75,
          optimalMax: 170,
          highMin: 235,
        ),
        wMoisture: 0.29,
        wSoilTemp: 0.12,
        wPh: 0.08,
        wEc: 0.13,
        wResistance: 0.12,
        wN: 0.09,
        wP: 0.07,
        wK: 0.10,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Mantenimiento',
        kWindowEs: 'Mantenimiento',
        nGuidanceEs: 'No necesita fertilizante solo por crecer despacio.',
        pGuidanceEs: 'Fósforo de mantenimiento. Sin urgencia.',
        kGuidanceEs: 'Mantén el potasio: conserva la firmeza de la planta.',
        careNoteEs:
            'El maguey está bien instalado y puede permanecer así durante '
            'muchos años. Evita regar por calendario y vigila que el suelo '
            'drene. Esta etiqueta no confirma cosecha, azúcar ni denominación '
            'de origen.',
      ),
      // En reposo: menor uso de agua; el frío húmedo es lo peor (Doc B §2.7,
      // §4.1). No se infiere por mes ni por sequedad.
      AgaveStageIds.rest: _AgaveStageProfile(
        moisture: AgroRange(
          lowMax: 3,
          optimalMin: 7,
          optimalMax: 24,
          highMin: 40,
        ),
        soilTemp: AgroRange(
          lowMax: 0,
          optimalMin: 6,
          optimalMax: 20,
          highMin: 30,
        ),
        ec: AgroRange(
          lowMax: 0.1,
          optimalMin: 0.25,
          optimalMax: 1.1,
          highMin: 1.8,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.3,
          highMin: 1.9,
        ),
        nPpm: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 28, highMin: 45),
        pPpm: AgroRange(lowMax: 4, optimalMin: 7, optimalMax: 18, highMin: 30),
        kPpm: AgroRange(
          lowMax: 30,
          optimalMin: 50,
          optimalMax: 125,
          highMin: 180,
        ),
        wMoisture: 0.34,
        wSoilTemp: 0.19,
        wPh: 0.06,
        wEc: 0.13,
        wResistance: 0.12,
        wN: 0.05,
        wP: 0.04,
        wK: 0.07,
        nWindowEs: 'Sin demanda',
        pWindowEs: 'Sin demanda',
        kWindowEs: 'Demanda baja',
        nGuidanceEs: 'No intentes activarlo con fertilizante.',
        pGuidanceEs: 'En reposo el fósforo no es prioridad.',
        kGuidanceEs: 'El potasio ayuda a resistir el frío.',
        careNoteEs:
            'Está usando menos agua. Evita mantener el suelo húmedo, '
            'especialmente con frío.',
      ),
      // Etapa por confirmar: targets amplios y prudentes (Doc B §4).
      AgaveStageIds.unknown: _AgaveStageProfile(
        moisture: AgroRange(
          lowMax: 5,
          optimalMin: 10,
          optimalMax: 34,
          highMin: 52,
        ),
        soilTemp: AgroRange(
          lowMax: 3,
          optimalMin: 12,
          optimalMax: 30,
          highMin: 38,
        ),
        ec: AgroRange(
          lowMax: 0.15,
          optimalMin: 0.35,
          optimalMax: 1.5,
          highMin: 2.3,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.4,
          highMin: 2.0,
        ),
        nPpm: AgroRange(
          lowMax: 10,
          optimalMin: 18,
          optimalMax: 42,
          highMin: 65,
        ),
        pPpm: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 26, highMin: 40),
        kPpm: AgroRange(
          lowMax: 45,
          optimalMin: 75,
          optimalMax: 170,
          highMin: 235,
        ),
        wMoisture: 0.31,
        wSoilTemp: 0.14,
        wPh: 0.07,
        wEc: 0.12,
        wResistance: 0.14,
        wN: 0.08,
        wP: 0.06,
        wK: 0.08,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Mantenimiento',
        kWindowEs: 'Mantenimiento',
        nGuidanceEs: 'Se conserva la banda compartida; no se prescribe.',
        pGuidanceEs: 'Fósforo de mantenimiento mientras se confirma el estado.',
        kGuidanceEs: 'Potasio de mantenimiento mientras se confirma el estado.',
        careNoteEs:
            'BIO-G seguirá leyendo agua, temperatura y suelo mientras confirmas '
            'el estado. Cuida sobre todo el exceso de agua y el frío húmedo.',
      ),
    };

_AgaveStageProfile _profileForStage(String? stageId) {
  final id = normalizeAgaveStageId(stageId);
  return _agaveStageProfiles[id] ?? _agaveStageProfiles[AgaveStageIds.unknown]!;
}

/// Mapeo de contexto de cultivo a banda de pH (Doc B §4.3).
AgroRange _agavePhForContext(String? contextId) {
  return switch (contextId?.trim().toLowerCase()) {
    'pot' ||
    'large_container' ||
    'nursery' => AgaveUniversalProfile.phPotNursery,
    'planter' ||
    'garden_bed' ||
    'rock_garden' => AgaveUniversalProfile.phPlanterGarden,
    'landscape' ||
    'open_ground' ||
    'living_fence' ||
    'field_edge' => AgaveUniversalProfile.phLandscapeGround,
    _ => AgaveUniversalProfile.phUnknownContext,
  };
}

/// Targets de sensor por etapa, en unidades reales.
///
/// El pH viene del CONTEXTO de cultivo (maceta, jardinera, paisaje). Sin
/// contexto declarado se usa el rango prudente `unknown` (Doc B §4.3): el perfil
/// NO inventa un contexto que el usuario no declaró.
StageTargets resolveAgaveTargets(
  String? stageId, {
  String? cultivationContextId,
}) {
  final p = _profileForStage(stageId);
  return StageTargets(
    moistureRaw: p.moisture,
    soilTemp: p.soilTemp,
    ph: _agavePhForContext(cultivationContextId),
    ec: p.ec,
    resistance: p.resistance,
    // Índices legacy: se conservan por compatibilidad del contrato compartido.
    // Los rangos que MANDAN son los explícitos en mg/kg.
    nIndex: p.nPpm,
    pIndex: p.pPpm,
    kIndex: p.kPpm,
    nSoilPpmRange: p.nPpm,
    pSoilPpmRange: p.pPpm,
    kSoilPpmRange: p.kPpm,
    nWindowLabelEs: p.nWindowEs,
    pWindowLabelEs: p.pWindowEs,
    kWindowLabelEs: p.kWindowEs,
    nShortGuidanceEs: p.nGuidanceEs,
    pShortGuidanceEs: p.pGuidanceEs,
    kShortGuidanceEs: p.kGuidanceEs,
  );
}

/// Targets por etapa + perfil. El perfil NO implica un contexto de cultivo (un
/// maguey vive en maceta, jardinera, paisaje o suelo directo), así que el pH usa
/// el rango prudente salvo que el contexto se conozca explícitamente.
StageTargets resolveAgaveTargetsForProfile(
  String? stageId, {
  required String? profileId,
  String? cultivationContextId,
}) {
  return resolveAgaveTargets(
    stageId,
    cultivationContextId: cultivationContextId,
  );
}

/// Ajustes por perfil (Doc B §7). NO crean bandas nuevas ni etiquetas nuevas:
/// solo multiplican castigos del AgroScore ya existentes.
///
/// ⚠ `coldToleranceAssumption = none` en MG-01 y MG-SKIP a propósito
/// (Doc B §7.1, §7.5): sin especie confirmada no se baja el castigo por frío. El
/// frío suave/húmedo se AGRAVA en MG-03 y MG-04 (especies sensibles), nunca se
/// suaviza automáticamente.
class AgaveProfileAdjustments {
  const AgaveProfileAdjustments({
    this.moistureCriticalHighPenaltyMultiplier = 1.0,
    this.moistureCriticalLowPenaltyMultiplier = 1.0,
    this.resistanceHighMultiplier = 1.0,
    this.ecHighMultiplier = 1.0,
    this.containerHeatSeverityMultiplier = 1.0,
    this.coldSeverityMultiplier = 1.0,
    this.coldWetSeverityMultiplier = 1.0,
    this.nitrogenHighSeverityMultiplier = 1.0,
    this.activeGrowthNpkMultiplier = 1.0,
    this.coldWetSeverityBump = 0,
    this.limitNpkPriorityToReview = false,
  });

  final double moistureCriticalHighPenaltyMultiplier;
  final double moistureCriticalLowPenaltyMultiplier;
  final double resistanceHighMultiplier;
  final double ecHighMultiplier;

  /// Calor de maceta (MG-01, MG-04): el sustrato confinado se calienta más que
  /// el aire (Doc B §7.1, §7.4).
  final double containerHeatSeverityMultiplier;

  /// Frío seco crítico (MG-04): agaves suaves menos rústicos (Doc B §7.4).
  final double coldSeverityMultiplier;

  /// Frío + sustrato húmedo (MG-03, MG-04, MG-SKIP): el peor caso compuesto
  /// (Doc B §7.3, §7.4, §7.5).
  final double coldWetSeverityMultiplier;

  final double nitrogenHighSeverityMultiplier;
  final double activeGrowthNpkMultiplier;

  /// Bump de severidad de ALERTA cuando hay frío húmedo (solo el perfil suave
  /// MG-04, que es el más sensible a helada).
  final int coldWetSeverityBump;

  /// MG-SKIP: `npkPriorityCeiling = review` (Doc B §7.5). Con un perfil sin
  /// confirmar no se escala una lectura de sonda a "acción recomendada".
  final bool limitNpkPriorityToReview;
}

/// Ajustes del perfil (Doc B §7). Un id desconocido cae en el perfil general
/// (prudente).
AgaveProfileAdjustments agaveProfileAdjustments(String? profileId) {
  return switch (profileId?.trim().toLowerCase()) {
    // MG-01 compacto: maceta pequeña cambia humedad y sales rápido; crecimiento
    // lento (no necesita N alto); no se asume tolerancia al frío (Doc B §7.1).
    kAgave01CompactSculptural => const AgaveProfileAdjustments(
      moistureCriticalHighPenaltyMultiplier: 1.10,
      containerHeatSeverityMultiplier: 1.05,
      ecHighMultiplier: 1.05,
      activeGrowthNpkMultiplier: 0.90,
    ),
    // MG-02 grande de paisaje: estable, tolera algo más de sequía; el suelo
    // pesado retiene agua y la compactación pesa; algunas especies toleran más
    // sal (Doc B §7.2).
    kAgave02LargeSpinyLandscape => const AgaveProfileAdjustments(
      moistureCriticalLowPenaltyMultiplier: 0.90,
      moistureCriticalHighPenaltyMultiplier: 1.10,
      resistanceHighMultiplier: 1.10,
      ecHighMultiplier: 0.95,
    ),
    // MG-03 azul / hoja angosta: A. tequilana responde a fertigación (NPK pesa
    // más), pero el exceso de agua y el frío húmedo siguen siendo peligrosos
    // (Doc B §7.3). BIO-G no persigue rendimiento.
    kAgave03BlueNarrowField => const AgaveProfileAdjustments(
      moistureCriticalHighPenaltyMultiplier: 1.12,
      coldWetSeverityMultiplier: 1.12,
      ecHighMultiplier: 1.05,
      activeGrowthNpkMultiplier: 1.08,
      nitrogenHighSeverityMultiplier: 1.05,
    ),
    // MG-04 hoja suave: los agaves suaves (attenuata, etc.) son menos rústicos a
    // helada; el frío y el frío húmedo se agravan; calor de maceta relevante
    // (Doc B §7.4).
    kAgave04SoftSpinelessWarm => const AgaveProfileAdjustments(
      moistureCriticalHighPenaltyMultiplier: 1.15,
      coldWetSeverityMultiplier: 1.25,
      coldSeverityMultiplier: 1.20,
      containerHeatSeverityMultiplier: 1.05,
      activeGrowthNpkMultiplier: 0.95,
      coldWetSeverityBump: 1,
    ),
    // MG-SKIP: prudente con el exceso, indulgente con la sequía, techo de
    // prioridad NPK = revisión y sin suposiciones de especie, tamaño, tolerancia
    // al frío ni a sales (Doc B §7.5).
    _ => const AgaveProfileAdjustments(
      moistureCriticalHighPenaltyMultiplier: 1.12,
      moistureCriticalLowPenaltyMultiplier: 0.88,
      coldWetSeverityMultiplier: 1.10,
      activeGrowthNpkMultiplier: 0.90,
      limitNpkPriorityToReview: true,
    ),
  };
}

/// Pesos del AgroScore por etapa. Cada fila suma 1.00, también con el ajuste de
/// perfil aplicado (se renormaliza: un perfil mueve el reparto, no el total).
StageWeights resolveAgaveStageWeights(String? stageId, {String? profileId}) {
  final p = _profileForStage(stageId);
  final adj = agaveProfileAdjustments(profileId);

  double wMoisture = p.wMoisture;
  double wSoilTemp = p.wSoilTemp;
  double wPh = p.wPh;
  double wEc = p.wEc;
  double wResistance = p.wResistance;
  double wN = p.wN;
  double wP = p.wP;
  double wK = p.wK;

  final bool isActiveGrowth =
      normalizeAgaveStageId(stageId) == AgaveStageIds.activeGrowth;

  if (isActiveGrowth && adj.activeGrowthNpkMultiplier != 1.0) {
    wN *= adj.activeGrowthNpkMultiplier;
    wP *= adj.activeGrowthNpkMultiplier;
    wK *= adj.activeGrowthNpkMultiplier;

    final double sum =
        wMoisture + wSoilTemp + wPh + wEc + wResistance + wN + wP + wK;
    if (sum > 0) {
      wMoisture /= sum;
      wSoilTemp /= sum;
      wPh /= sum;
      wEc /= sum;
      wResistance /= sum;
      wN /= sum;
      wP /= sum;
      wK /= sum;
    }
  }

  return StageWeights(
    moisture: wMoisture,
    soilTemp: wSoilTemp,
    resistance: wResistance,
    ph: wPh,
    ec: wEc,
    n: wN,
    p: wP,
    k: wK,
  );
}

/// Nota corta de cuidado por etapa, en lenguaje de agricultor (Doc B §10).
String agaveStageCareNoteEs(String? stageId) =>
    _profileForStage(stageId).careNoteEs;
