import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/succulent/succulent_catalog.dart';
import 'package:bio_g/core/crops/succulent/succulent_lifecycle.dart';

/// Perfil universal agronómico de la Suculenta ornamental (Documento B, SU v1.0).
///
/// MISMAS UNIDADES REALES que el resto del ecosistema BIO-G (frijol, hortalizas,
/// granos, árboles, cactus). No se negocia: el dashboard, el motor de alertas y
/// la pantalla NPK comparan contra estas unidades.
///
///   - humedad     → % (0..100)
///   - temperatura → °C
///   - pH          → pH
///   - EC          → mS/cm
///   - resistencia → MPa
///   - N / P / K   → mg/kg
///
/// **No son los números del cactus.** Se copia la arquitectura, no la biología
/// (Doc B §20): la suculenta usa una banda hídrica ligeramente más húmeda,
/// mantiene alta sensibilidad al exceso de agua, permite más peso nutricional en
/// crecimiento activo y admite EC algo mayor.
///
/// Los valores marcados como defaults de ingeniería (D1 en el Doc B) están
/// pendientes de validación con la sonda BIO-G en sustrato real.
class SucculentUniversalProfile {
  const SucculentUniversalProfile._();

  // ── pH por CONTEXTO (Doc B §4.3) ───────────────────────────────────────────
  // El pH depende del contexto de cultivo, no de la etapa: la etapa cambia el
  // peso, no el rango. Sin contexto declarado se usa el rango prudente.

  /// Maceta / vivero: sustrato confinado, se acidifica y saliniza más rápido.
  static const AgroRange phPotNursery = AgroRange(
    lowMax: 4.8,
    optimalMin: 5.5,
    optimalMax: 6.7,
    highMin: 7.6,
  );

  /// Jardinera / cama drenante.
  static const AgroRange phPlanterGarden = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.5,
    optimalMax: 7.0,
    highMin: 8.0,
  );

  /// Paisaje / suelo abierto: suelos más calcáreos, tolera pH más alto.
  static const AgroRange phLandscapeGround = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.6,
    optimalMax: 7.5,
    highMin: 8.3,
  );

  /// Contexto sin declarar: rango intermedio y prudente.
  static const AgroRange phUnknownContext = AgroRange(
    lowMax: 4.9,
    optimalMin: 5.5,
    optimalMax: 7.0,
    highMin: 8.0,
  );
}

/// Datos por etapa. Mismo patrón que `BeanUniversalProfile` y el cactus.
class _SucculentStageProfile {
  const _SucculentStageProfile({
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
const Map<String, _SucculentStageProfile> _succulentStageProfiles =
    <String, _SucculentStageProfile>{
      // Recién plantada: la raíz aún se acomoda. Agua de más = raíz perdida.
      SucculentStageIds.installationEstablishment: _SucculentStageProfile(
        moisture: AgroRange(
          lowMax: 8,
          optimalMin: 14,
          optimalMax: 54,
          highMin: 72,
        ),
        soilTemp: AgroRange(
          lowMax: 8,
          optimalMin: 16,
          optimalMax: 29,
          highMin: 36,
        ),
        ec: AgroRange(
          lowMax: 0.2,
          optimalMin: 0.4,
          optimalMax: 1.2,
          highMin: 1.8,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.0,
          highMin: 1.6,
        ),
        nPpm: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 32, highMin: 48),
        pPpm: AgroRange(lowMax: 5, optimalMin: 10, optimalMax: 25, highMin: 40),
        kPpm: AgroRange(
          lowMax: 35,
          optimalMin: 60,
          optimalMax: 135,
          highMin: 190,
        ),
        wMoisture: 0.33,
        wSoilTemp: 0.14,
        wPh: 0.07,
        wEc: 0.12,
        wResistance: 0.14,
        wN: 0.07,
        wP: 0.05,
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
            'La raíz todavía se está acomodando. Riega con cuidado y revisa que '
            'el agua salga bien.',
      ),
      // Echando raíz: alternancia riego → drenaje → secado.
      SucculentStageIds.rootEstablishment: _SucculentStageProfile(
        moisture: AgroRange(
          lowMax: 8,
          optimalMin: 15,
          optimalMax: 56,
          highMin: 74,
        ),
        soilTemp: AgroRange(
          lowMax: 8,
          optimalMin: 16,
          optimalMax: 30,
          highMin: 36,
        ),
        ec: AgroRange(
          lowMax: 0.2,
          optimalMin: 0.4,
          optimalMax: 1.2,
          highMin: 1.8,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.0,
          highMin: 1.6,
        ),
        nPpm: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 34, highMin: 50),
        pPpm: AgroRange(lowMax: 6, optimalMin: 11, optimalMax: 28, highMin: 44),
        kPpm: AgroRange(
          lowMax: 40,
          optimalMin: 65,
          optimalMax: 145,
          highMin: 200,
        ),
        wMoisture: 0.34,
        wSoilTemp: 0.14,
        wPh: 0.06,
        wEc: 0.12,
        wResistance: 0.14,
        wN: 0.06,
        wP: 0.06,
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
      SucculentStageIds.activeGrowth: _SucculentStageProfile(
        moisture: AgroRange(
          lowMax: 10,
          optimalMin: 18,
          optimalMax: 62,
          highMin: 80,
        ),
        soilTemp: AgroRange(
          lowMax: 10,
          optimalMin: 18,
          optimalMax: 31,
          highMin: 38,
        ),
        ec: AgroRange(
          lowMax: 0.3,
          optimalMin: 0.5,
          optimalMax: 1.5,
          highMin: 2.2,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.3,
          highMin: 1.9,
        ),
        nPpm: AgroRange(
          lowMax: 12,
          optimalMin: 20,
          optimalMax: 45,
          highMin: 65,
        ),
        pPpm: AgroRange(lowMax: 7, optimalMin: 13, optimalMax: 32, highMin: 48),
        kPpm: AgroRange(
          lowMax: 50,
          optimalMin: 80,
          optimalMax: 165,
          highMin: 225,
        ),
        wMoisture: 0.27,
        wSoilTemp: 0.12,
        wPh: 0.08,
        wEc: 0.13,
        wResistance: 0.10,
        wN: 0.11,
        wP: 0.08,
        wK: 0.11,
        nWindowEs: 'Demanda activa',
        pWindowEs: 'Demanda activa',
        kWindowEs: 'Demanda activa',
        nGuidanceEs:
            'Los nutrientes importan más ahora, pero una lectura no define una '
            'dosis. De más, el tallo se alarga y se debilita.',
        pGuidanceEs: 'El fósforo sostiene la raíz durante el empuje.',
        kGuidanceEs:
            'El potasio ayuda a la firmeza de la hoja y al manejo del agua.',
        careNoteEs:
            'Está formando hojas o tallos nuevos. Evita encharcarla y no la '
            'dejes seca demasiado tiempo.',
      ),
      // Estable: se queda aquí indefinidamente. El mantenimiento NO cierra ciclo.
      SucculentStageIds.maintenance: _SucculentStageProfile(
        moisture: AgroRange(
          lowMax: 8,
          optimalMin: 14,
          optimalMax: 58,
          highMin: 76,
        ),
        soilTemp: AgroRange(
          lowMax: 7,
          optimalMin: 14,
          optimalMax: 30,
          highMin: 38,
        ),
        ec: AgroRange(
          lowMax: 0.2,
          optimalMin: 0.4,
          optimalMax: 1.4,
          highMin: 2.0,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.3,
          highMin: 2.0,
        ),
        nPpm: AgroRange(
          lowMax: 10,
          optimalMin: 16,
          optimalMax: 38,
          highMin: 56,
        ),
        pPpm: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 28, highMin: 44),
        kPpm: AgroRange(
          lowMax: 45,
          optimalMin: 70,
          optimalMax: 150,
          highMin: 210,
        ),
        wMoisture: 0.30,
        wSoilTemp: 0.12,
        wPh: 0.08,
        wEc: 0.14,
        wResistance: 0.12,
        wN: 0.09,
        wP: 0.06,
        wK: 0.09,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Mantenimiento',
        kWindowEs: 'Mantenimiento',
        nGuidanceEs:
            'No necesita fertilizante solo porque crezca lento.',
        pGuidanceEs: 'Fósforo de mantenimiento. Sin urgencia.',
        kGuidanceEs: 'Mantén el potasio: es lo que la conserva firme.',
        careNoteEs:
            'Puede crecer despacio. Revisa forma, firmeza y que el sustrato '
            'drene bien.',
      ),
      // En reposo: menor uso de agua. Frío con sustrato húmedo es lo peor.
      SucculentStageIds.rest: _SucculentStageProfile(
        moisture: AgroRange(
          lowMax: 6,
          optimalMin: 10,
          optimalMax: 48,
          highMin: 66,
        ),
        soilTemp: AgroRange(
          lowMax: 4,
          optimalMin: 8,
          optimalMax: 20,
          highMin: 30,
        ),
        ec: AgroRange(
          lowMax: 0.2,
          optimalMin: 0.3,
          optimalMax: 1.0,
          highMin: 1.6,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.2,
          highMin: 1.8,
        ),
        nPpm: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 26, highMin: 42),
        pPpm: AgroRange(lowMax: 4, optimalMin: 8, optimalMax: 22, highMin: 36),
        kPpm: AgroRange(
          lowMax: 30,
          optimalMin: 50,
          optimalMax: 120,
          highMin: 175,
        ),
        wMoisture: 0.35,
        wSoilTemp: 0.18,
        wPh: 0.06,
        wEc: 0.14,
        wResistance: 0.11,
        wN: 0.05,
        wP: 0.04,
        wK: 0.07,
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
      SucculentStageIds.unknown: _SucculentStageProfile(
        moisture: AgroRange(
          lowMax: 8,
          optimalMin: 14,
          optimalMax: 58,
          highMin: 76,
        ),
        soilTemp: AgroRange(
          lowMax: 7,
          optimalMin: 14,
          optimalMax: 29,
          highMin: 36,
        ),
        ec: AgroRange(
          lowMax: 0.2,
          optimalMin: 0.4,
          optimalMax: 1.4,
          highMin: 2.0,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.3,
          highMin: 2.0,
        ),
        nPpm: AgroRange(
          lowMax: 10,
          optimalMin: 16,
          optimalMax: 38,
          highMin: 56,
        ),
        pPpm: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 28, highMin: 44),
        kPpm: AgroRange(
          lowMax: 45,
          optimalMin: 70,
          optimalMax: 150,
          highMin: 210,
        ),
        wMoisture: 0.32,
        wSoilTemp: 0.14,
        wPh: 0.07,
        wEc: 0.13,
        wResistance: 0.13,
        wN: 0.07,
        wP: 0.06,
        wK: 0.08,
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

_SucculentStageProfile _profileForStage(String? stageId) {
  final id = normalizeSucculentStageId(stageId);
  return _succulentStageProfiles[id] ??
      _succulentStageProfiles[SucculentStageIds.unknown]!;
}

AgroRange _succulentPhForContext(String? contextId) {
  return switch (contextId?.trim().toLowerCase()) {
    'pot' || 'nursery' => SucculentUniversalProfile.phPotNursery,
    'planter' || 'garden_bed' => SucculentUniversalProfile.phPlanterGarden,
    'landscape' ||
    'open_ground' => SucculentUniversalProfile.phLandscapeGround,
    _ => SucculentUniversalProfile.phUnknownContext,
  };
}

/// Targets de sensor por etapa, en unidades reales.
///
/// El pH viene del CONTEXTO de cultivo (maceta, jardinera, paisaje). Sin
/// contexto declarado se usa el rango prudente `unknown` (Doc B §4.3): el perfil
/// NO inventa un contexto que el usuario no declaró.
StageTargets resolveSucculentTargets(
  String? stageId, {
  String? cultivationContextId,
}) {
  final p = _profileForStage(stageId);
  return StageTargets(
    moistureRaw: p.moisture,
    soilTemp: p.soilTemp,
    ph: _succulentPhForContext(cultivationContextId),
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
/// (una roseta vive en maceta, jardinera o jardín), así que el pH usa el rango
/// prudente salvo que el contexto se conozca explícitamente.
StageTargets resolveSucculentTargetsForProfile(
  String? stageId, {
  required String? profileId,
  String? cultivationContextId,
}) {
  return resolveSucculentTargets(
    stageId,
    cultivationContextId: cultivationContextId,
  );
}

/// Ajustes por perfil (Doc B §7). NO crean bandas nuevas ni etiquetas nuevas:
/// solo multiplican castigos del AgroScore ya existentes.
class SucculentProfileAdjustments {
  const SucculentProfileAdjustments({
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

  /// SU-SKIP: `npkPriorityCeiling = review`. Con un perfil sin confirmar no se
  /// escala una lectura de sonda a "acción recomendada".
  final bool limitNpkPriorityToReview;
}

/// Ajustes del perfil. Un id desconocido cae en el perfil general (prudente).
SucculentProfileAdjustments succulentProfileAdjustments(String? profileId) {
  return switch (profileId?.trim().toLowerCase()) {
    // Agua en la base/corona; forma sensible a sombra y a sol brusco.
    kSu01RosetteBrightLight => const SucculentProfileAdjustments(
      moistureCriticalHighPenaltyMultiplier: 1.10,
      coldWetSeverityBump: 1,
      nitrogenHighSeverityMultiplier: 1.05,
    ),
    // Maceta colgante: puede secar rápido; sigue existiendo riesgo por exceso.
    kSu02TrailingCascading => const SucculentProfileAdjustments(
      moistureCriticalLowPenaltyMultiplier: 1.05,
      moistureCriticalHighPenaltyMultiplier: 1.05,
      resistanceHighMultiplier: 0.95,
      activeGrowthNpkMultiplier: 1.05,
    ),
    // Más masa y anclaje: tolera secado moderado; sales y sustrato apretado
    // pesan más.
    kSu03BranchingWoody => const SucculentProfileAdjustments(
      moistureCriticalLowPenaltyMultiplier: 0.95,
      resistanceHighMultiplier: 1.10,
      ecHighMultiplier: 1.05,
    ),
    // Crecimiento lento, raíz sensible a humedad, sol directo puede dañar.
    kSu04CompactFilteredLight => const SucculentProfileAdjustments(
      moistureCriticalHighPenaltyMultiplier: 1.15,
      heatSeverityMultiplier: 1.05,
      activeGrowthNpkMultiplier: 0.85,
      nitrogenHighSeverityMultiplier: 1.10,
    ),
    // Perfil general: prudente con el exceso, indulgente con la sequía y sin
    // suposiciones de luz, frío ni reposo.
    _ => const SucculentProfileAdjustments(
      moistureCriticalHighPenaltyMultiplier: 1.10,
      moistureCriticalLowPenaltyMultiplier: 0.90,
      limitNpkPriorityToReview: true,
    ),
  };
}

/// Pesos del AgroScore por etapa. Cada fila suma 1.00, también con el ajuste de
/// perfil aplicado (se renormaliza: un perfil mueve el reparto, no el total).
StageWeights resolveSucculentStageWeights(String? stageId, {String? profileId}) {
  final p = _profileForStage(stageId);
  final adj = succulentProfileAdjustments(profileId);

  double wMoisture = p.wMoisture;
  double wSoilTemp = p.wSoilTemp;
  double wPh = p.wPh;
  double wEc = p.wEc;
  double wResistance = p.wResistance;
  double wN = p.wN;
  double wP = p.wP;
  double wK = p.wK;

  final bool isActiveGrowth =
      normalizeSucculentStageId(stageId) == SucculentStageIds.activeGrowth;

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
String succulentStageCareNoteEs(String? stageId) =>
    _profileForStage(stageId).careNoteEs;
