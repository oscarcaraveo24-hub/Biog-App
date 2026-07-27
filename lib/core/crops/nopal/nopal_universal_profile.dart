import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/nopal/nopal_catalog.dart';
import 'package:bio_g/core/crops/nopal/nopal_lifecycle.dart';

/// Perfil universal agronómico del Nopal ornamental (Documento B, NO v1.0).
///
/// MISMAS UNIDADES REALES que el resto del ecosistema BIO-G (frijol, hortalizas,
/// granos, árboles, cactus, suculenta, sábila, maguey). No se negocia: el
/// dashboard, el motor de alertas y la pantalla NPK comparan contra estas
/// unidades.
///
///   - humedad     → % (0..100, escala operativa BIO-G, NO es VWC de laboratorio)
///   - temperatura → °C
///   - pH          → pH
///   - EC          → mS/cm
///   - resistencia → MPa
///   - N / P / K   → mg/kg
///
/// **No son los números del cactus, la suculenta, la sábila ni el maguey.** Se
/// copia la arquitectura, no la biología (Doc B §0). El nopal usa una banda
/// hídrica más amplia que el cactus (el crecimiento activo puede pedir más agua
/// al emitir pencas), responde a N mejor documentado que el cactus (cap 90 vs
/// 60) y conserva K como cap más alto por su papel osmótico y por la alta
/// concentración observada en cladodios.
///
/// Los valores marcados como defaults de ingeniería (D1 en el Doc B) están
/// pendientes de validación con la sonda BIO-G en sustrato real. Ninguno es una
/// dosis, una suficiencia de laboratorio ni un objetivo productivo (Doc B §2).
class NopalUniversalProfile {
  const NopalUniversalProfile._();

  // ── pH por CONTEXTO (Doc B §7) ─────────────────────────────────────────────
  // El pH depende del contexto de cultivo, no de la etapa: la etapa cambia el
  // peso, no el rango. **El contexto GANA sobre el perfil** (Doc B §7.5): NO-01
  // no obliga pH de maceta si el contexto dice suelo, y NO-02 no obliga pH de
  // suelo si el contexto dice maceta. El perfil ajusta severidad, no la
  // identidad química del medio.

  /// Maceta / vivero: poco volumen, cambios rápidos, sales y agua alcalina se
  /// acumulan; banda más estrecha (Doc B §7.1).
  static const AgroRange phPotNursery = AgroRange(
    lowMax: 4.8,
    optimalMin: 5.5,
    optimalMax: 7.0,
    highMin: 7.8,
  );

  /// Jardinera / cama de jardín / rocalla (Doc B §7.2).
  static const AgroRange phPlanterGarden = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.8,
    optimalMax: 7.6,
    highMin: 8.3,
  );

  /// Paisaje / suelo directo: admite suelos calcáreos moderados. 8.6 NO se
  /// presenta como ideal, es el borde crítico (Doc B §7.3).
  static const AgroRange phLandscapeGround = AgroRange(
    lowMax: 5.0,
    optimalMin: 6.0,
    optimalMax: 8.0,
    highMin: 8.6,
  );

  /// Contexto sin declarar: rango intermedio y prudente. El perfil NO debe
  /// inventar maceta ni suelo (Doc B §7.4).
  static const AgroRange phUnknownContext = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.7,
    optimalMax: 7.7,
    highMin: 8.4,
  );

  // ── Ajuste de frío para NO-04 (Doc B §6.5) ─────────────────────────────────
  // Solo para nopales bajos/rastreros de grupos con frío documentado, y SOLO en
  // planta estable o en reposo. NO se aplica en instalación, en raíz ni con
  // perfil general. No convierte el ajuste en garantía de supervivencia.

  /// `maintenance` con perfil NO-04 confirmado.
  static const AgroRange coldHardySoilTempMaintenance = AgroRange(
    lowMax: -2,
    optimalMin: 4,
    optimalMax: 32,
    highMin: 40,
  );

  /// `rest` con perfil NO-04 confirmado.
  static const AgroRange coldHardySoilTempRest = AgroRange(
    lowMax: -8,
    optimalMin: -2,
    optimalMax: 16,
    highMin: 28,
  );
}

/// Datos por etapa. Mismo patrón que `AgaveUniversalProfile` y la sábila.
class _NopalStageProfile {
  const _NopalStageProfile({
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

// Los pesos de CADA etapa suman 1.00 (Doc B §14). Los targets son las tablas del
// Doc B §5, §6, §8, §9, §11, §12 y §13 en unidades reales.
const Map<String, _NopalStageProfile> _nopalStageProfiles =
    <String, _NopalStageProfile>{
      // Recién plantado: la penca o la raíz necesita contacto con el medio sin
      // quedarse empapada. La humedad domina el peso (Doc B §5.1).
      NopalStageIds.installationEstablishment: _NopalStageProfile(
        moisture: AgroRange(
          lowMax: 5,
          optimalMin: 12,
          optimalMax: 48,
          highMin: 68,
        ),
        soilTemp: AgroRange(
          lowMax: 6,
          optimalMin: 16,
          optimalMax: 30,
          highMin: 38,
        ),
        ec: AgroRange(
          lowMax: 0.15,
          optimalMin: 0.35,
          optimalMax: 1.20,
          highMin: 2.00,
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
        wMoisture: 0.33,
        wSoilTemp: 0.13,
        wPh: 0.07,
        wEc: 0.12,
        wResistance: 0.15,
        wN: 0.06,
        wP: 0.06,
        wK: 0.08,
        nWindowEs: 'Sin demanda',
        pWindowEs: 'Apoyo a raíz',
        kWindowEs: 'Apoyo a raíz',
        nGuidanceEs:
            'El nitrógeno no manda aquí. De más solo saca tejido tierno.',
        pGuidanceEs: 'El fósforo acompaña el arraigo. No hace falta más.',
        kGuidanceEs: 'El potasio da firmeza mientras agarra raíz.',
        careNoteEs:
            'La penca todavía está agarrando. Mantén libre la salida del agua y '
            'evita regar otra vez antes de que el suelo pierda humedad.',
      ),
      // Echando raíz: la emisión de raíces usa agua, pero la zona sigue
      // necesitando oxígeno. Es la humedad más alta del establecimiento
      // (Doc B §5.2).
      NopalStageIds.rootEstablishment: _NopalStageProfile(
        moisture: AgroRange(
          lowMax: 6,
          optimalMin: 14,
          optimalMax: 52,
          highMin: 72,
        ),
        soilTemp: AgroRange(
          lowMax: 7,
          optimalMin: 18,
          optimalMax: 31,
          highMin: 39,
        ),
        ec: AgroRange(
          lowMax: 0.15,
          optimalMin: 0.35,
          optimalMax: 1.30,
          highMin: 2.10,
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
          highMin: 220,
        ),
        wMoisture: 0.34,
        wSoilTemp: 0.14,
        wPh: 0.06,
        wEc: 0.12,
        wResistance: 0.15,
        wN: 0.05,
        wP: 0.07,
        wK: 0.07,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Ventana de raíz',
        kWindowEs: 'Apoyo a raíz',
        nGuidanceEs: 'El agua y el espacio para la raíz pesan más que el N.',
        pGuidanceEs: 'Ventana buena para fósforo: la raíz lo está usando.',
        kGuidanceEs: 'El potasio ayuda a que aguante el cambio.',
        careNoteEs:
            'Está echando raíz. Revisa que el suelo no esté apretado y que '
            'pierda humedad antes de volver a regar.',
      ),
      // Creciendo: la etapa más húmeda y donde el NPK pesa de verdad. Una
      // lectura de 60 % sigue siendo ÓPTIMA aquí y no significa "regar"
      // (Doc B §5.3).
      NopalStageIds.activeGrowth: _NopalStageProfile(
        moisture: AgroRange(
          lowMax: 8,
          optimalMin: 18,
          optimalMax: 60,
          highMin: 78,
        ),
        soilTemp: AgroRange(
          lowMax: 8,
          optimalMin: 20,
          optimalMax: 33,
          highMin: 41,
        ),
        ec: AgroRange(
          lowMax: 0.20,
          optimalMin: 0.50,
          optimalMax: 1.80,
          highMin: 2.80,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.4,
          highMin: 2.0,
        ),
        nPpm: AgroRange(lowMax: 15, optimalMin: 28, optimalMax: 58, highMin: 85),
        pPpm: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 32, highMin: 48),
        kPpm: AgroRange(
          lowMax: 55,
          optimalMin: 90,
          optimalMax: 195,
          highMin: 270,
        ),
        wMoisture: 0.27,
        wSoilTemp: 0.12,
        wPh: 0.07,
        wEc: 0.12,
        wResistance: 0.10,
        wN: 0.13,
        wP: 0.09,
        wK: 0.10,
        nWindowEs: 'Demanda activa',
        pWindowEs: 'Demanda activa',
        kWindowEs: 'Demanda activa',
        nGuidanceEs:
            'Es cuando más participa el nitrógeno, pero una lectura no define '
            'una dosis.',
        pGuidanceEs: 'El fósforo sostiene la raíz durante el crecimiento.',
        kGuidanceEs:
            'El potasio acompaña la regulación del agua y la firmeza de la '
            'penca.',
        careNoteEs:
            'Está sacando pencas nuevas y puede usar más agua que de costumbre. '
            'Aun así, el exceso sostenido sigue siendo lo más peligroso.',
      ),
      // Estable: se queda aquí indefinidamente. Cortar una penca o retirar una
      // tuna NO cambia esta etapa (Doc B §3.9, §5.4).
      NopalStageIds.maintenance: _NopalStageProfile(
        moisture: AgroRange(
          lowMax: 5,
          optimalMin: 12,
          optimalMax: 54,
          highMin: 72,
        ),
        soilTemp: AgroRange(
          lowMax: 4,
          optimalMin: 12,
          optimalMax: 32,
          highMin: 40,
        ),
        ec: AgroRange(
          lowMax: 0.15,
          optimalMin: 0.35,
          optimalMax: 1.50,
          highMin: 2.50,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.5,
          highMin: 2.1,
        ),
        nPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 42, highMin: 65),
        pPpm: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 26, highMin: 40),
        kPpm: AgroRange(
          lowMax: 45,
          optimalMin: 75,
          optimalMax: 175,
          highMin: 240,
        ),
        wMoisture: 0.30,
        wSoilTemp: 0.12,
        wPh: 0.08,
        wEc: 0.13,
        wResistance: 0.12,
        wN: 0.08,
        wP: 0.07,
        wK: 0.10,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Mantenimiento',
        kWindowEs: 'Mantenimiento',
        nGuidanceEs: 'Crecer despacio no es deficiencia. No fuerces con N.',
        pGuidanceEs: 'Fósforo de mantenimiento. Sin urgencia.',
        kGuidanceEs: 'Mantén el potasio: conserva la firmeza de la planta.',
        careNoteEs:
            'El nopal está bien instalado y puede seguir así durante años. '
            'Evita regar por calendario y vigila las sales. Si cortas una penca '
            'o levantas una tuna, la planta conserva su etapa.',
      ),
      // En reposo: banda más seca. El frío húmedo es el peor caso (Doc B §5.5).
      // No se infiere reposo por una lectura.
      NopalStageIds.rest: _NopalStageProfile(
        moisture: AgroRange(
          lowMax: 3,
          optimalMin: 7,
          optimalMax: 40,
          highMin: 62,
        ),
        soilTemp: AgroRange(
          lowMax: -2,
          optimalMin: 4,
          optimalMax: 18,
          highMin: 30,
        ),
        ec: AgroRange(
          lowMax: 0.10,
          optimalMin: 0.25,
          optimalMax: 1.00,
          highMin: 1.80,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.3,
          highMin: 1.9,
        ),
        nPpm: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 26, highMin: 42),
        pPpm: AgroRange(lowMax: 4, optimalMin: 7, optimalMax: 18, highMin: 30),
        kPpm: AgroRange(
          lowMax: 30,
          optimalMin: 50,
          optimalMax: 125,
          highMin: 180,
        ),
        wMoisture: 0.34,
        wSoilTemp: 0.20,
        wPh: 0.06,
        wEc: 0.13,
        wResistance: 0.11,
        wN: 0.04,
        wP: 0.04,
        wK: 0.08,
        nWindowEs: 'Sin demanda',
        pWindowEs: 'Sin demanda',
        kWindowEs: 'Demanda baja',
        nGuidanceEs: 'No promuevas tejido nuevo mientras está en reposo.',
        pGuidanceEs: 'En reposo el fósforo no es prioridad.',
        kGuidanceEs: 'El potasio ayuda a resistir el frío.',
        careNoteEs:
            'Está usando menos agua. Evita mantener el suelo húmedo, sobre todo '
            'con frío: esa combinación es la que se lleva la raíz.',
      ),
      // Etapa por confirmar: banda prudente, ni la más seca ni la más húmeda.
      // Limita la prioridad NPK a revisión (Doc B §5.6).
      NopalStageIds.unknown: _NopalStageProfile(
        moisture: AgroRange(
          lowMax: 5,
          optimalMin: 12,
          optimalMax: 52,
          highMin: 70,
        ),
        soilTemp: AgroRange(
          lowMax: 5,
          optimalMin: 12,
          optimalMax: 31,
          highMin: 39,
        ),
        ec: AgroRange(
          lowMax: 0.15,
          optimalMin: 0.35,
          optimalMax: 1.40,
          highMin: 2.30,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.4,
          highMin: 2.0,
        ),
        nPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 42, highMin: 65),
        pPpm: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 26, highMin: 40),
        kPpm: AgroRange(
          lowMax: 45,
          optimalMin: 75,
          optimalMax: 170,
          highMin: 235,
        ),
        wMoisture: 0.32,
        wSoilTemp: 0.14,
        wPh: 0.07,
        wEc: 0.12,
        wResistance: 0.13,
        wN: 0.07,
        wP: 0.06,
        wK: 0.09,
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

_NopalStageProfile _profileForStage(String? stageId) {
  final id = normalizeNopalStageId(stageId);
  return _nopalStageProfiles[id] ?? _nopalStageProfiles[NopalStageIds.unknown]!;
}

/// Mapeo de contexto de cultivo a banda de pH (Doc B §7).
AgroRange _nopalPhForContext(String? contextId) {
  return switch (contextId?.trim().toLowerCase()) {
    'pot' || 'nursery' => NopalUniversalProfile.phPotNursery,
    'planter' ||
    'garden_bed' ||
    'rock_garden' => NopalUniversalProfile.phPlanterGarden,
    'landscape' ||
    'open_ground' ||
    'living_fence' ||
    'field_edge' => NopalUniversalProfile.phLandscapeGround,
    _ => NopalUniversalProfile.phUnknownContext,
  };
}

/// True cuando el contexto declarado es sustrato confinado (maceta o vivero).
/// Solo entonces se aplican los ajustes de sustrato de NO-01 (Doc B §8.4,
/// §15.1): "no asumir maceta si el contexto dice suelo".
bool _isConfinedSubstrate(String? contextId) {
  final v = contextId?.trim().toLowerCase();
  return v == 'pot' || v == 'nursery';
}

/// Targets de sensor por etapa, en unidades reales.
///
/// El pH viene del CONTEXTO de cultivo (maceta, jardinera, paisaje). Sin
/// contexto declarado se usa el rango prudente `unknown` (Doc B §7.4): el perfil
/// NO inventa un contexto que el usuario no declaró.
StageTargets resolveNopalTargets(
  String? stageId, {
  String? cultivationContextId,
}) {
  final p = _profileForStage(stageId);
  return StageTargets(
    moistureRaw: p.moisture,
    soilTemp: p.soilTemp,
    ph: _nopalPhForContext(cultivationContextId),
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

/// Targets por etapa + perfil.
///
/// A diferencia del maguey, en nopal DOS perfiles sí mueven rangos, no solo
/// castigos (Doc B §6.5, §8.4, §15.1):
///
/// - **NO-01 en maceta o vivero**: sustrato confinado. Sube el piso de humedad,
///   baja el techo crítico y estrecha la EC. Solo si el contexto declarado es
///   `pot`/`nursery`: no se asume maceta cuando el contexto dice suelo.
/// - **NO-04 confirmado, en planta estable o en reposo**: banda de temperatura
///   de suelo con tolerancia al frío. NUNCA en instalación ni en raíz, y nunca
///   con el perfil general.
///
/// El pH sigue viniendo del CONTEXTO, nunca del perfil (Doc B §7.5).
StageTargets resolveNopalTargetsForProfile(
  String? stageId, {
  required String? profileId,
  String? cultivationContextId,
}) {
  final base = resolveNopalTargets(
    stageId,
    cultivationContextId: cultivationContextId,
  );
  final String stage = normalizeNopalStageId(stageId);
  final String? profile = profileId?.trim().toLowerCase();

  AgroRange moisture = base.moistureRaw;
  AgroRange ec = base.ec;
  AgroRange soilTemp = base.soilTemp;

  // NO-01 en sustrato confinado: poco volumen, secado rápido y acumulación
  // rápida de sales (Doc B §15.1). El highMin baja 4 puntos porque una maceta
  // pequeña se satura antes.
  if (profile == kNopal01CompactClumpingContainer &&
      _isConfinedSubstrate(cultivationContextId)) {
    moisture = AgroRange(
      lowMax: moisture.lowMax + 1,
      optimalMin: moisture.optimalMin + 1,
      optimalMax: moisture.optimalMax,
      highMin: moisture.highMin - 4,
    );
    // Nunca se permite que lowMax rebase optimalMin (Doc B §8.4).
    final double ecOptimalMax = ec.optimalMax - 0.15;
    ec = AgroRange(
      lowMax: ec.lowMax > ecOptimalMax ? ecOptimalMax : ec.lowMax,
      optimalMin: ec.optimalMin,
      optimalMax: ecOptimalMax,
      highMin: ec.highMin - 0.25,
    );
  }

  // NO-04 confirmado: tolerancia al frío SOLO en planta estable o en reposo
  // (Doc B §6.5). El perfil general nunca la recibe.
  if (profile == kNopal04LowSpreadingColdHardy) {
    if (stage == NopalStageIds.maintenance) {
      soilTemp = NopalUniversalProfile.coldHardySoilTempMaintenance;
    } else if (stage == NopalStageIds.rest) {
      soilTemp = NopalUniversalProfile.coldHardySoilTempRest;
    }
  }

  return StageTargets(
    moistureRaw: moisture,
    soilTemp: soilTemp,
    ph: base.ph,
    ec: ec,
    resistance: base.resistance,
    nIndex: base.nIndex,
    pIndex: base.pIndex,
    kIndex: base.kIndex,
    nSoilPpmRange: base.nSoilPpmRange,
    pSoilPpmRange: base.pSoilPpmRange,
    kSoilPpmRange: base.kSoilPpmRange,
    nWindowLabelEs: base.nWindowLabelEs,
    pWindowLabelEs: base.pWindowLabelEs,
    kWindowLabelEs: base.kWindowLabelEs,
    nShortGuidanceEs: base.nShortGuidanceEs,
    pShortGuidanceEs: base.pShortGuidanceEs,
    kShortGuidanceEs: base.kShortGuidanceEs,
  );
}

/// Ajustes por perfil (Doc B §15). Salvo los dos casos de rango descritos
/// arriba, NO crean bandas nuevas ni etiquetas nuevas: solo multiplican castigos
/// del AgroScore ya existentes.
///
/// ⚠ El frío NUNCA se suaviza en NO-01, NO-02, NO-03 ni en el perfil general
/// (Doc B §15). Solo NO-04 confirmado y en planta estable/reposo recibe
/// `coldSeverityMultiplier < 1`, y aun así el aviso de helada no se elimina
/// jamás (Doc B §18.2).
class NopalProfileAdjustments {
  const NopalProfileAdjustments({
    this.moistureCriticalHighPenaltyMultiplier = 1.0,
    this.moistureCriticalLowPenaltyMultiplier = 1.0,
    this.resistanceHighMultiplier = 1.0,
    this.ecHighMultiplier = 1.0,
    this.containerHeatSeverityMultiplier = 1.0,
    this.coldSeverityMultiplier = 1.0,
    this.coldWetSeverityMultiplier = 1.0,
    this.nitrogenHighSeverityMultiplier = 1.0,
    this.activeGrowthNpkMultiplier = 1.0,
    this.restNpkMultiplier = 1.0,
    this.coldWetSeverityBump = 0,
    this.limitNpkPriorityToReview = false,
    this.sensorLocalCaution = false,
    this.coldToleranceRequiresStablePlant = false,
  });

  final double moistureCriticalHighPenaltyMultiplier;
  final double moistureCriticalLowPenaltyMultiplier;
  final double resistanceHighMultiplier;
  final double ecHighMultiplier;

  /// Calor de sustrato confinado (NO-01): la maceta se calienta más que el aire
  /// (Doc B §15.1).
  final double containerHeatSeverityMultiplier;

  /// Frío seco crítico. >1 castiga más (NO-02, planta de tipo cálido);
  /// <1 castiga menos (NO-04 confirmado y estable) (Doc B §15.2, §15.4).
  final double coldSeverityMultiplier;

  /// Frío + suelo húmedo: el peor caso compuesto (Doc B §16.2).
  final double coldWetSeverityMultiplier;

  final double nitrogenHighSeverityMultiplier;
  final double activeGrowthNpkMultiplier;

  /// NO-04 baja el peso de NPK en reposo (Doc B §15.4).
  final double restNpkMultiplier;

  /// Bump de severidad de ALERTA cuando hay frío húmedo.
  final int coldWetSeverityBump;

  /// NO-SKIP y etapa por confirmar: `npkPriorityCeiling = review` (Doc B §15.5,
  /// §19.1). Con un perfil sin confirmar una lectura de sonda no escala a
  /// "acción recomendada".
  final bool limitNpkPriorityToReview;

  /// La sonda describe SOLO la zona donde está enterrada (Doc B §3.2). En una
  /// nopalera arbustiva o en un ejemplar alto, una lectura no representa toda la
  /// planta: los textos evitan frases globales.
  final bool sensorLocalCaution;

  /// El ajuste de frío de NO-04 exige planta estable o en reposo; en
  /// instalación y raíz NO aplica (Doc B §6.5, §15.4).
  final bool coldToleranceRequiresStablePlant;
}

/// Ajustes del perfil (Doc B §15). Un id desconocido cae en el perfil general
/// (prudente).
NopalProfileAdjustments nopalProfileAdjustments(String? profileId) {
  return switch (profileId?.trim().toLowerCase()) {
    // NO-01 compacto/agrupado: poco volumen radicular, secado rápido,
    // acumulación rápida de sales, sustrato que se calienta. No se asume
    // rusticidad al frío (Doc B §15.1).
    kNopal01CompactClumpingContainer => const NopalProfileAdjustments(
      ecHighMultiplier: 1.15,
      containerHeatSeverityMultiplier: 1.10,
      nitrogenHighSeverityMultiplier: 1.10,
      activeGrowthNpkMultiplier: 0.95,
    ),
    // NO-02 alto o de penca grande: raíz extensa y anclaje crítico. La
    // compactación pesa más, el déficit en crecimiento pesa algo más y el frío
    // se agrava (tipo cálido predominante). Una sonda describe solo su zona
    // (Doc B §15.2). NO se suben rangos de NPK ni de humedad por tamaño.
    kNopal02UprightLargePadWarm => const NopalProfileAdjustments(
      resistanceHighMultiplier: 1.10,
      moistureCriticalLowPenaltyMultiplier: 1.05,
      coldSeverityMultiplier: 1.15,
      sensorLocalCaution: true,
    ),
    // NO-03 arbustivo de paisaje: perfil de especies variadas, así que el ajuste
    // es pequeño. Suelo heterogéneo y sonda poco representativa; tolera algo más
    // el calor y algo más el déficit en mantenimiento. La EC NO se suaviza y no
    // se asume tolerancia a helada (Doc B §15.3).
    kNopal03DesertShrubSpinyLandscape => const NopalProfileAdjustments(
      moistureCriticalLowPenaltyMultiplier: 0.97,
      containerHeatSeverityMultiplier: 0.95,
      sensorLocalCaution: true,
    ),
    // NO-04 bajo o rastrero: grupos con frío documentado. El castigo por frío
    // seco baja, pero el frío HÚMEDO se agrava y el aviso de helada nunca se
    // elimina. El arrugamiento invernal por sí solo no se penaliza
    // (Doc B §15.4).
    kNopal04LowSpreadingColdHardy => const NopalProfileAdjustments(
      coldSeverityMultiplier: 0.75,
      coldWetSeverityMultiplier: 1.15,
      restNpkMultiplier: 0.85,
      coldWetSeverityBump: 1,
      coldToleranceRequiresStablePlant: true,
    ),
    // NO-SKIP: targets base, techo de prioridad NPK = revisión, sonda local con
    // cautela y ninguna suposición de especie, tolerancia fría, tolerancia
    // salina ni demanda alta (Doc B §15.5).
    _ => const NopalProfileAdjustments(
      limitNpkPriorityToReview: true,
      sensorLocalCaution: true,
    ),
  };
}

/// Pesos del AgroScore por etapa. Cada fila suma 1.00, también con el ajuste de
/// perfil aplicado (se renormaliza: un perfil mueve el reparto, no el total).
StageWeights resolveNopalStageWeights(String? stageId, {String? profileId}) {
  final p = _profileForStage(stageId);
  final adj = nopalProfileAdjustments(profileId);
  final String stage = normalizeNopalStageId(stageId);

  double wMoisture = p.wMoisture;
  double wSoilTemp = p.wSoilTemp;
  double wPh = p.wPh;
  double wEc = p.wEc;
  double wResistance = p.wResistance;
  double wN = p.wN;
  double wP = p.wP;
  double wK = p.wK;

  // NO-02 sube el peso de N y K en crecimiento activo (Doc B §15.2).
  if (stage == NopalStageIds.activeGrowth &&
      profileId?.trim().toLowerCase() == kNopal02UprightLargePadWarm) {
    wN *= 1.05;
    wK *= 1.05;
  }

  final double npkMultiplier = switch (stage) {
    NopalStageIds.activeGrowth => adj.activeGrowthNpkMultiplier,
    NopalStageIds.rest => adj.restNpkMultiplier,
    _ => 1.0,
  };

  if (npkMultiplier != 1.0) {
    wN *= npkMultiplier;
    wP *= npkMultiplier;
    wK *= npkMultiplier;
  }

  final double sum =
      wMoisture + wSoilTemp + wPh + wEc + wResistance + wN + wP + wK;
  if (sum > 0 && (sum - 1.0).abs() > 1e-9) {
    wMoisture /= sum;
    wSoilTemp /= sum;
    wPh /= sum;
    wEc /= sum;
    wResistance /= sum;
    wN /= sum;
    wP /= sum;
    wK /= sum;
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

/// Nota corta de cuidado por etapa, en lenguaje de agricultor (Doc B §20).
String nopalStageCareNoteEs(String? stageId) =>
    _profileForStage(stageId).careNoteEs;

/// Aviso de sonda local (Doc B §3.2). Se usa en los textos para no afirmar el
/// estado de TODA la planta cuando la raíz supera ampliamente el punto de
/// lectura. Nunca se dice "Todo tu nopal está seco".
String? nopalSensorScopeNoteEs(String? profileId) {
  final adj = nopalProfileAdjustments(profileId);
  if (!adj.sensorLocalCaution) return null;
  return 'La lectura describe la zona donde está la sonda, no toda la planta.';
}
