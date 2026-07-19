import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/aloe/aloe_catalog.dart';
import 'package:bio_g/core/crops/aloe/aloe_lifecycle.dart';

/// Perfil universal agronómico de la Sábila / Aloe ornamental (Documento B,
/// SA v1.0).
///
/// MISMAS UNIDADES REALES que el resto del ecosistema BIO-G (frijol, hortalizas,
/// granos, árboles, cactus, suculenta). No se negocia: el dashboard, el motor de
/// alertas y la pantalla NPK comparan contra estas unidades.
///
///   - humedad     → % (0..100)
///   - temperatura → °C
///   - pH          → pH
///   - EC          → mS/cm
///   - resistencia → MPa
///   - N / P / K   → mg/kg
///
/// **No son los números de la suculenta ni del cactus.** Se copia la
/// arquitectura, no la biología (Doc B §0.5). Las cinco divergencias frente a la
/// suculenta tienen fuente: la sábila usa una banda hídrica ~2 puntos más húmeda
/// (el déficit le cuesta biomasa), tolera MUCHA más sal (banda EC más amplia),
/// es indiferente al pH (peso bajo), es menos rústica al frío, y tiene una
/// respuesta a N documentada (cap y peso mayores).
///
/// Los valores marcados como defaults de ingeniería (D1 en el Doc B) están
/// pendientes de validación con la sonda BIO-G en sustrato real.
class AloeUniversalProfile {
  const AloeUniversalProfile._();

  // ── pH por CONTEXTO (Doc B §4.3) ───────────────────────────────────────────
  // El pH depende del contexto de cultivo, no de la etapa: la etapa cambia el
  // peso, no el rango. La sábila es notablemente indiferente al pH y tolera
  // alcalinidad, así que la banda es ancha y va con peso bajo (§6). Sin contexto
  // declarado se usa el rango prudente `unknown`.

  /// Maceta / vivero: sustrato confinado, se acidifica y saliniza más rápido.
  static const AgroRange phPotNursery = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.8,
    optimalMax: 7.4,
    highMin: 8.2,
  );

  /// Jardinera / cama drenante.
  static const AgroRange phPlanterGarden = AgroRange(
    lowMax: 5.1,
    optimalMin: 5.9,
    optimalMax: 7.7,
    highMin: 8.5,
  );

  /// Paisaje / suelo abierto: suelos más calcáreos, tolera pH más alto.
  static const AgroRange phLandscapeGround = AgroRange(
    lowMax: 5.2,
    optimalMin: 6.0,
    optimalMax: 8.0,
    highMin: 8.7,
  );

  /// Contexto sin declarar: rango intermedio y prudente.
  static const AgroRange phUnknownContext = AgroRange(
    lowMax: 5.1,
    optimalMin: 5.9,
    optimalMax: 7.6,
    highMin: 8.4,
  );
}

/// Datos por etapa. Mismo patrón que `SucculentUniversalProfile` y el cactus.
class _AloeStageProfile {
  const _AloeStageProfile({
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

// Los pesos de CADA etapa suman 1.00 (Doc B §6).
const Map<String, _AloeStageProfile> _aloeStageProfiles =
    <String, _AloeStageProfile>{
      // Recién plantada: la raíz aún se acomoda. Agua de más = cuello dañado.
      AloeStageIds.installationEstablishment: _AloeStageProfile(
        moisture: AgroRange(
          lowMax: 10,
          optimalMin: 16,
          optimalMax: 60,
          highMin: 76,
        ),
        soilTemp: AgroRange(
          lowMax: 9,
          optimalMin: 17,
          optimalMax: 30,
          highMin: 36,
        ),
        ec: AgroRange(
          lowMax: 0.2,
          optimalMin: 0.5,
          optimalMax: 1.8,
          highMin: 2.8,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.0,
          highMin: 1.6,
        ),
        nPpm: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 38, highMin: 55),
        pPpm: AgroRange(lowMax: 5, optimalMin: 10, optimalMax: 26, highMin: 42),
        kPpm: AgroRange(
          lowMax: 38,
          optimalMin: 65,
          optimalMax: 145,
          highMin: 205,
        ),
        wMoisture: 0.32,
        wSoilTemp: 0.15,
        wPh: 0.06,
        wEc: 0.11,
        wResistance: 0.14,
        wN: 0.08,
        wP: 0.06,
        wK: 0.08,
        nWindowEs: 'Sin demanda',
        pWindowEs: 'Apoyo a raíz',
        kWindowEs: 'Apoyo a raíz',
        nGuidanceEs:
            'No intentes acelerar el arraigo con mucho fertilizante: el tejido '
            'tierno se echa a perder.',
        pGuidanceEs: 'El fósforo acompaña el arraigo. No hace falta más.',
        kGuidanceEs: 'El potasio da firmeza mientras agarra raíz.',
        careNoteEs:
            'La raíz todavía se está acomodando. Que se vea seca al principio '
            'es normal; riega con cuidado y revisa que el agua salga bien.',
      ),
      // Echando raíz: alternancia riego → drenaje → secado.
      AloeStageIds.rootEstablishment: _AloeStageProfile(
        moisture: AgroRange(
          lowMax: 10,
          optimalMin: 17,
          optimalMax: 62,
          highMin: 78,
        ),
        soilTemp: AgroRange(
          lowMax: 9,
          optimalMin: 17,
          optimalMax: 31,
          highMin: 37,
        ),
        ec: AgroRange(
          lowMax: 0.2,
          optimalMin: 0.5,
          optimalMax: 1.8,
          highMin: 2.8,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.0,
          highMin: 1.6,
        ),
        nPpm: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 40, highMin: 58),
        pPpm: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 30, highMin: 46),
        kPpm: AgroRange(
          lowMax: 42,
          optimalMin: 70,
          optimalMax: 155,
          highMin: 215,
        ),
        wMoisture: 0.33,
        wSoilTemp: 0.15,
        wPh: 0.05,
        wEc: 0.11,
        wResistance: 0.14,
        wN: 0.07,
        wP: 0.07,
        wK: 0.08,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Ventana de raíz',
        kWindowEs: 'Apoyo a raíz',
        nGuidanceEs: 'El agua y la raíz pesan más que los nutrientes.',
        pGuidanceEs: 'Ventana buena para fósforo: la raíz lo está usando.',
        kGuidanceEs: 'El potasio ayuda a que aguante el cambio de maceta.',
        careNoteEs:
            'Mantén el sustrato suelto y deja que pierda humedad antes de '
            'volver a regar.',
      ),
      // Creciendo: la etapa donde el NPK pesa de verdad.
      AloeStageIds.activeGrowth: _AloeStageProfile(
        moisture: AgroRange(
          lowMax: 12,
          optimalMin: 20,
          optimalMax: 68,
          highMin: 84,
        ),
        soilTemp: AgroRange(
          lowMax: 11,
          optimalMin: 19,
          optimalMax: 32,
          highMin: 38,
        ),
        ec: AgroRange(
          lowMax: 0.3,
          optimalMin: 0.6,
          optimalMax: 2.2,
          highMin: 3.2,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.3,
          highMin: 1.9,
        ),
        nPpm: AgroRange(
          lowMax: 14,
          optimalMin: 24,
          optimalMax: 52,
          highMin: 74,
        ),
        pPpm: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 36, highMin: 54),
        kPpm: AgroRange(
          lowMax: 55,
          optimalMin: 88,
          optimalMax: 180,
          highMin: 245,
        ),
        wMoisture: 0.26,
        wSoilTemp: 0.13,
        wPh: 0.06,
        wEc: 0.11,
        wResistance: 0.10,
        wN: 0.13,
        wP: 0.09,
        wK: 0.12,
        nWindowEs: 'Demanda activa',
        pWindowEs: 'Demanda activa',
        kWindowEs: 'Demanda activa',
        nGuidanceEs:
            'Los nutrientes importan más ahora, pero una lectura no define una '
            'dosis. De más, la hoja se alarga y se ablanda.',
        pGuidanceEs: 'El fósforo sostiene la raíz durante el empuje.',
        kGuidanceEs:
            'El potasio ayuda a la firmeza de la hoja y al manejo del agua.',
        careNoteEs:
            'Está formando hojas nuevas e hijuelos. Evita encharcarla y no la '
            'dejes seca demasiado tiempo.',
      ),
      // Estable: se queda aquí indefinidamente. El mantenimiento NO cierra ciclo.
      AloeStageIds.maintenance: _AloeStageProfile(
        moisture: AgroRange(
          lowMax: 10,
          optimalMin: 16,
          optimalMax: 64,
          highMin: 80,
        ),
        soilTemp: AgroRange(
          lowMax: 8,
          optimalMin: 15,
          optimalMax: 31,
          highMin: 38,
        ),
        ec: AgroRange(
          lowMax: 0.2,
          optimalMin: 0.5,
          optimalMax: 2.0,
          highMin: 3.0,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.3,
          highMin: 2.0,
        ),
        nPpm: AgroRange(
          lowMax: 12,
          optimalMin: 18,
          optimalMax: 44,
          highMin: 64,
        ),
        pPpm: AgroRange(lowMax: 6, optimalMin: 11, optimalMax: 30, highMin: 46),
        kPpm: AgroRange(
          lowMax: 48,
          optimalMin: 75,
          optimalMax: 162,
          highMin: 225,
        ),
        wMoisture: 0.29,
        wSoilTemp: 0.13,
        wPh: 0.06,
        wEc: 0.12,
        wResistance: 0.12,
        wN: 0.10,
        wP: 0.08,
        wK: 0.10,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Mantenimiento',
        kWindowEs: 'Mantenimiento',
        nGuidanceEs:
            'No necesita fertilizante solo porque crezca lento.',
        pGuidanceEs: 'Fósforo de mantenimiento. Sin urgencia.',
        kGuidanceEs: 'Mantén el potasio: es lo que la conserva firme.',
        careNoteEs:
            'Puede crecer despacio. Revisa forma, firmeza y que el sustrato '
            'drene bien. Aguanta bien la sequía: no riegues por calendario.',
      ),
      // En reposo: menor uso de agua. Frío con sustrato húmedo es lo peor.
      AloeStageIds.rest: _AloeStageProfile(
        moisture: AgroRange(
          lowMax: 7,
          optimalMin: 12,
          optimalMax: 54,
          highMin: 70,
        ),
        soilTemp: AgroRange(
          lowMax: 5,
          optimalMin: 9,
          optimalMax: 22,
          highMin: 31,
        ),
        ec: AgroRange(
          lowMax: 0.2,
          optimalMin: 0.4,
          optimalMax: 1.5,
          highMin: 2.4,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.2,
          highMin: 1.8,
        ),
        nPpm: AgroRange(lowMax: 7, optimalMin: 11, optimalMax: 28, highMin: 46),
        pPpm: AgroRange(lowMax: 4, optimalMin: 8, optimalMax: 23, highMin: 38),
        kPpm: AgroRange(
          lowMax: 32,
          optimalMin: 54,
          optimalMax: 128,
          highMin: 185,
        ),
        wMoisture: 0.34,
        wSoilTemp: 0.19,
        wPh: 0.05,
        wEc: 0.12,
        wResistance: 0.11,
        wN: 0.06,
        wP: 0.05,
        wK: 0.08,
        nWindowEs: 'Sin demanda',
        pWindowEs: 'Sin demanda',
        kWindowEs: 'Demanda baja',
        nGuidanceEs: 'No intentes despertarla con fertilizante.',
        pGuidanceEs: 'En reposo el fósforo no es prioridad.',
        kGuidanceEs: 'El potasio ayuda a resistir el frío.',
        careNoteEs:
            'Está usando menos agua. Evita mantener el sustrato húmedo, sobre '
            'todo con frío.',
      ),
      // Etapa por confirmar: targets amplios y prudentes.
      AloeStageIds.unknown: _AloeStageProfile(
        moisture: AgroRange(
          lowMax: 10,
          optimalMin: 16,
          optimalMax: 64,
          highMin: 80,
        ),
        soilTemp: AgroRange(
          lowMax: 8,
          optimalMin: 15,
          optimalMax: 30,
          highMin: 36,
        ),
        ec: AgroRange(
          lowMax: 0.2,
          optimalMin: 0.5,
          optimalMax: 2.0,
          highMin: 3.0,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.3,
          highMin: 2.0,
        ),
        nPpm: AgroRange(
          lowMax: 12,
          optimalMin: 18,
          optimalMax: 44,
          highMin: 64,
        ),
        pPpm: AgroRange(lowMax: 6, optimalMin: 11, optimalMax: 30, highMin: 46),
        kPpm: AgroRange(
          lowMax: 48,
          optimalMin: 75,
          optimalMax: 162,
          highMin: 225,
        ),
        wMoisture: 0.31,
        wSoilTemp: 0.15,
        wPh: 0.06,
        wEc: 0.12,
        wResistance: 0.13,
        wN: 0.08,
        wP: 0.06,
        wK: 0.09,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Mantenimiento',
        kWindowEs: 'Mantenimiento',
        nGuidanceEs: 'Nitrógeno bajo mientras se confirma el estado.',
        pGuidanceEs: 'Fósforo de mantenimiento mientras se confirma el estado.',
        kGuidanceEs: 'Potasio de mantenimiento mientras se confirma el estado.',
        careNoteEs:
            'BIO-G seguirá leyendo agua, temperatura y suelo mientras confirmas '
            'el estado. Cuida sobre todo el exceso de agua.',
      ),
    };

_AloeStageProfile _profileForStage(String? stageId) {
  final id = normalizeAloeStageId(stageId);
  return _aloeStageProfiles[id] ?? _aloeStageProfiles[AloeStageIds.unknown]!;
}

AgroRange _aloePhForContext(String? contextId) {
  return switch (contextId?.trim().toLowerCase()) {
    'pot' || 'nursery' => AloeUniversalProfile.phPotNursery,
    'planter' || 'garden_bed' => AloeUniversalProfile.phPlanterGarden,
    'landscape' || 'open_ground' => AloeUniversalProfile.phLandscapeGround,
    _ => AloeUniversalProfile.phUnknownContext,
  };
}

/// Targets de sensor por etapa, en unidades reales.
///
/// El pH viene del CONTEXTO de cultivo (maceta, jardinera, paisaje). Sin
/// contexto declarado se usa el rango prudente `unknown` (Doc B §4.3): el perfil
/// NO inventa un contexto que el usuario no declaró.
StageTargets resolveAloeTargets(
  String? stageId, {
  String? cultivationContextId,
}) {
  final p = _profileForStage(stageId);
  return StageTargets(
    moistureRaw: p.moisture,
    soilTemp: p.soilTemp,
    ph: _aloePhForContext(cultivationContextId),
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

/// Targets por etapa + perfil. El perfil NO implica un contexto de cultivo
/// (una sábila vive en maceta, jardinera o jardín), así que el pH usa el rango
/// prudente salvo que el contexto se conozca explícitamente.
StageTargets resolveAloeTargetsForProfile(
  String? stageId, {
  required String? profileId,
  String? cultivationContextId,
}) {
  return resolveAloeTargets(
    stageId,
    cultivationContextId: cultivationContextId,
  );
}

/// Ajustes por perfil (Doc B §7). NO crean bandas nuevas ni etiquetas nuevas:
/// solo multiplican castigos del AgroScore ya existentes.
///
/// ⚠ `coldToleranceAssumption = none` en TODOS los perfiles a propósito
/// (Doc B §7.3, §7.4): el frío NO se modela por perfil en v1. Las cifras de
/// resistencia al frío de SA-03/SA-04 son mínimos "en seco" de fuentes
/// comerciales. Por eso ningún perfil suaviza el castigo por frío.
class AloeProfileAdjustments {
  const AloeProfileAdjustments({
    this.moistureCriticalHighPenaltyMultiplier = 1.0,
    this.moistureCriticalLowPenaltyMultiplier = 1.0,
    this.resistanceHighMultiplier = 1.0,
    this.ecHighMultiplier = 1.0,
    this.heatSeverityMultiplier = 1.0,
    this.nitrogenHighSeverityMultiplier = 1.0,
    this.activeGrowthNpkMultiplier = 1.0,
    this.coldWetSeverityBump = 0,
    this.limitNpkPriorityToReview = false,
  });

  final double moistureCriticalHighPenaltyMultiplier;
  final double moistureCriticalLowPenaltyMultiplier;
  final double resistanceHighMultiplier;
  final double ecHighMultiplier;
  final double heatSeverityMultiplier;
  final double nitrogenHighSeverityMultiplier;
  final double activeGrowthNpkMultiplier;
  final int coldWetSeverityBump;

  /// SA-SKIP: `npkPriorityCeiling = review`. Con un perfil sin confirmar no se
  /// escala una lectura de sonda a "acción recomendada".
  final bool limitNpkPriorityToReview;
}

/// Ajustes del perfil. Un id desconocido cae en el perfil general (prudente).
AloeProfileAdjustments aloeProfileAdjustments(String? profileId) {
  return switch (profileId?.trim().toLowerCase()) {
    // Hoja ancha: el agua se queda en el cuello y el centro de la roseta;
    // A. vera es zona 10a-12b; su respuesta a N es la mejor documentada.
    kSa01BroadleafRosette => const AloeProfileAdjustments(
      moistureCriticalHighPenaltyMultiplier: 1.10,
      coldWetSeverityBump: 1,
      activeGrowthNpkMultiplier: 1.05,
    ),
    // Pequeña de maceta: poco volumen radicular; una maceta grande seca lento y
    // el cuello se queda húmedo; crecimiento lento; sensible al sol de mediodía.
    kSa02SmallClumping => const AloeProfileAdjustments(
      moistureCriticalHighPenaltyMultiplier: 1.15,
      heatSeverityMultiplier: 1.05,
      activeGrowthNpkMultiplier: 0.85,
      nitrogenHighSeverityMultiplier: 1.10,
    ),
    // Arbustiva: mucha masa y reserva, tolera secado moderado; el anclaje y las
    // sales pesan más. Frío NO modelado por perfil.
    kSa03ShrubbyBranching => const AloeProfileAdjustments(
      moistureCriticalLowPenaltyMultiplier: 0.92,
      resistanceHighMultiplier: 1.10,
      ecHighMultiplier: 1.05,
    ),
    // Moteada de jardín: forma colonia; paisaje con acumulación de sales; misma
    // reserva que SA-01. Mayor rusticidad reportada sin fuente fuerte: no se
    // premia. Frío NO modelado por perfil.
    kSa04SpottedLandscape => const AloeProfileAdjustments(
      moistureCriticalHighPenaltyMultiplier: 1.05,
      moistureCriticalLowPenaltyMultiplier: 0.95,
      ecHighMultiplier: 1.05,
    ),
    // Perfil general: prudente con el exceso, indulgente con la sequía y sin
    // suposiciones de luz, frío ni reposo ("es mejor pecar de seco que de
    // mojado", Doc B §7.5).
    _ => const AloeProfileAdjustments(
      moistureCriticalHighPenaltyMultiplier: 1.12,
      moistureCriticalLowPenaltyMultiplier: 0.90,
      limitNpkPriorityToReview: true,
    ),
  };
}

/// Pesos del AgroScore por etapa. Cada fila suma 1.00, también con el ajuste de
/// perfil aplicado (se renormaliza: un perfil mueve el reparto, no el total).
StageWeights resolveAloeStageWeights(String? stageId, {String? profileId}) {
  final p = _profileForStage(stageId);
  final adj = aloeProfileAdjustments(profileId);

  double wMoisture = p.wMoisture;
  double wSoilTemp = p.wSoilTemp;
  double wPh = p.wPh;
  double wEc = p.wEc;
  double wResistance = p.wResistance;
  double wN = p.wN;
  double wP = p.wP;
  double wK = p.wK;

  final bool isActiveGrowth =
      normalizeAloeStageId(stageId) == AloeStageIds.activeGrowth;

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

/// Nota corta de cuidado por etapa, en lenguaje de agricultor (Doc B §8).
String aloeStageCareNoteEs(String? stageId) =>
    _profileForStage(stageId).careNoteEs;
