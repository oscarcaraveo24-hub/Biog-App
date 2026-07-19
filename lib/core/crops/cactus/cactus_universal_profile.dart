import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/cactus/cactus_catalog.dart';
import 'package:bio_g/core/crops/cactus/cactus_lifecycle.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';

/// Perfil universal agronómico del Cactus ornamental.
///
/// MISMAS UNIDADES REALES que el resto del ecosistema BIO-G (frijol, hortalizas,
/// granos, árboles). Esto NO es negociable: el dashboard, el motor de alertas y
/// la pantalla NPK comparan contra estas unidades.
///
///   - humedad     → % (0..100)
///   - temperatura → °C
///   - pH          → pH
///   - EC          → mS/cm   (igual que frijol: 0.4–1.8)
///   - resistencia → MPa     (igual que frijol: 0.0–2.0)
///   - N / P / K   → mg/kg   (rangos explícitos de suficiencia de suelo)
///
/// La versión anterior usaba "índices comparables" (EC 40–160, resistencia
/// 40–190, baseline=100) que no significan nada contra las tarjetas reales del
/// dashboard. Eso obligaba a ocultar métricas e inventar etiquetas como
/// "Sin baseline comparable" u "objetivo 8–30%". Queda eliminado.
///
/// Agronomía del cactus (xerófito desértico), respetada dentro de las unidades
/// reales:
///   - Es una planta de BAJA demanda: los targets NPK son bajos, no los de un
///     cultivo de rendimiento.
///   - El agua manda: el exceso sostenido de humedad es el riesgo #1 (pudrición
///     de raíz y cuello). Por eso los rangos de humedad son bajos y el peso de
///     humedad domina el AgroScore.
///   - El sustrato debe estar suelto y drenar: la compactación (resistencia
///     alta) es peligrosa.
///   - K pesa más que N dentro del bloque nutrimental (turgencia, pared celular,
///     tolerancia a estrés). El exceso de N produce tejido blando y propenso a
///     pudrirse.
class CactusUniversalProfile {
  const CactusUniversalProfile._();

  /// pH del sustrato. El cactus tolera un rango amplio y ligeramente ácido a
  /// neutro; el contexto (maceta vs. suelo de jardín) ajusta los extremos.
  static const AgroRange phBase = AgroRange(
    lowMax: 4.8,
    optimalMin: 5.5,
    optimalMax: 7.2,
    highMin: 8.0,
  );

  /// Maceta / vivero: sustrato confinado, se acidifica y saliniza más rápido.
  static const AgroRange phPotNursery = AgroRange(
    lowMax: 4.6,
    optimalMin: 5.2,
    optimalMax: 6.8,
    highMin: 7.4,
  );

  /// Jardinera / cama de jardín.
  static const AgroRange phPlanterGarden = AgroRange(
    lowMax: 4.8,
    optimalMin: 5.5,
    optimalMax: 7.2,
    highMin: 8.0,
  );

  /// Paisaje / suelo abierto: suelos más calcáreos, tolera pH más alto.
  static const AgroRange phLandscapeGround = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.8,
    optimalMax: 7.8,
    highMin: 8.4,
  );
}

// ── EC (mS/cm) ───────────────────────────────────────────────────────────────
// El cactus es sensible a la acumulación de sales, sobre todo en maceta. Rangos
// bajos y conservadores, en las MISMAS unidades que frijol.

const AgroRange _cactusEcEstablishment = AgroRange(
  lowMax: 0.2,
  optimalMin: 0.4,
  optimalMax: 1.0,
  highMin: 1.5,
);

const AgroRange _cactusEcGrowth = AgroRange(
  lowMax: 0.3,
  optimalMin: 0.5,
  optimalMax: 1.2,
  highMin: 1.8,
);

const AgroRange _cactusEcMaintenance = AgroRange(
  lowMax: 0.2,
  optimalMin: 0.4,
  optimalMax: 1.1,
  highMin: 1.6,
);

const AgroRange _cactusEcRest = AgroRange(
  lowMax: 0.2,
  optimalMin: 0.3,
  optimalMax: 0.9,
  highMin: 1.4,
);

// ── Resistencia (MPa) ────────────────────────────────────────────────────────
// El cactus exige sustrato suelto y drenante. La compactación asfixia la raíz y
// retiene agua junto al cuello. Umbral de compactación más estricto que frijol.

const AgroRange _cactusResistanceEstablishment = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 1.0,
  highMin: 1.6,
);

const AgroRange _cactusResistanceEstablished = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 1.2,
  highMin: 1.8,
);

// ── NPK (mg/kg) ──────────────────────────────────────────────────────────────
// Rangos EXPLÍCITOS de suficiencia de suelo, como los árboles. Baja demanda.
// K > P > N en importancia relativa. El N alto se castiga: produce tejido blando.

const AgroRange _cactusNEstablishment = AgroRange(
  lowMax: 6,
  optimalMin: 12,
  optimalMax: 28,
  highMin: 45,
);

const AgroRange _cactusNGrowth = AgroRange(
  lowMax: 10,
  optimalMin: 18,
  optimalMax: 40,
  highMin: 60,
);

const AgroRange _cactusNMaintenance = AgroRange(
  lowMax: 8,
  optimalMin: 14,
  optimalMax: 32,
  highMin: 50,
);

const AgroRange _cactusNRest = AgroRange(
  lowMax: 5,
  optimalMin: 10,
  optimalMax: 24,
  highMin: 40,
);

const AgroRange _cactusPEstablishment = AgroRange(
  lowMax: 5,
  optimalMin: 10,
  optimalMax: 26,
  highMin: 40,
);

const AgroRange _cactusPGrowth = AgroRange(
  lowMax: 6,
  optimalMin: 12,
  optimalMax: 30,
  highMin: 45,
);

const AgroRange _cactusPMaintenance = AgroRange(
  lowMax: 5,
  optimalMin: 10,
  optimalMax: 26,
  highMin: 40,
);

const AgroRange _cactusPRest = AgroRange(
  lowMax: 4,
  optimalMin: 8,
  optimalMax: 22,
  highMin: 36,
);

const AgroRange _cactusKEstablishment = AgroRange(
  lowMax: 35,
  optimalMin: 60,
  optimalMax: 130,
  highMin: 185,
);

const AgroRange _cactusKGrowth = AgroRange(
  lowMax: 45,
  optimalMin: 75,
  optimalMax: 150,
  highMin: 205,
);

const AgroRange _cactusKMaintenance = AgroRange(
  lowMax: 40,
  optimalMin: 65,
  optimalMax: 140,
  highMin: 195,
);

const AgroRange _cactusKRest = AgroRange(
  lowMax: 30,
  optimalMin: 55,
  optimalMax: 120,
  highMin: 175,
);

/// Datos por etapa. Mismo patrón que `BeanUniversalProfile`.
class _CactusStageProfile {
  const _CactusStageProfile({
    required this.moisture,
    required this.soilTemp,
    required this.ph,
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
  final AgroRange ph;
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

// Los pesos de cada etapa suman 1.00 (igual que frijol y árbol).
const Map<String, _CactusStageProfile> _cactusStageProfiles =
    <String, _CactusStageProfile>{
      // Recién colocada: la raíz aún no trabaja. Agua de más = pudrición.
      CactusStageIds.installationEstablishment: _CactusStageProfile(
        moisture: AgroRange(
          lowMax: 4,
          optimalMin: 10,
          optimalMax: 50,
          highMin: 68,
        ),
        soilTemp: AgroRange(
          lowMax: 6,
          optimalMin: 16,
          optimalMax: 30,
          highMin: 38,
        ),
        ph: CactusUniversalProfile.phBase,
        ec: _cactusEcEstablishment,
        resistance: _cactusResistanceEstablishment,
        nPpm: _cactusNEstablishment,
        pPpm: _cactusPEstablishment,
        kPpm: _cactusKEstablishment,
        wMoisture: 0.34,
        wSoilTemp: 0.13,
        wPh: 0.07,
        wEc: 0.12,
        wResistance: 0.14,
        wN: 0.06,
        wP: 0.06,
        wK: 0.08,
        nWindowEs: 'Sin demanda',
        pWindowEs: 'Apoyo a raíz',
        kWindowEs: 'Apoyo a raíz',
        nGuidanceEs:
            'Recién colocada: no empujes con nitrógeno. El tejido tierno se '
            'pudre.',
        pGuidanceEs: 'El fósforo acompaña el arraigo. No hace falta más.',
        kGuidanceEs: 'El potasio da firmeza mientras agarra raíz.',
        careNoteEs:
            'Recién colocada: riega poco, revisa que el sustrato drene y no '
            'fertilices.',
      ),
      // Echando raíz: alternancia riego → drenaje → secado.
      CactusStageIds.rootEstablishment: _CactusStageProfile(
        moisture: AgroRange(
          lowMax: 4,
          optimalMin: 12,
          optimalMax: 52,
          highMin: 70,
        ),
        soilTemp: AgroRange(
          lowMax: 6,
          optimalMin: 16,
          optimalMax: 30,
          highMin: 38,
        ),
        ph: CactusUniversalProfile.phBase,
        ec: _cactusEcEstablishment,
        resistance: _cactusResistanceEstablishment,
        nPpm: _cactusNEstablishment,
        pPpm: _cactusPGrowth,
        kPpm: _cactusKEstablishment,
        wMoisture: 0.34,
        wSoilTemp: 0.14,
        wPh: 0.06,
        wEc: 0.12,
        wResistance: 0.14,
        wN: 0.05,
        wP: 0.07,
        wK: 0.08,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Ventana de raíz',
        kWindowEs: 'Apoyo a raíz',
        nGuidanceEs: 'Echando raíz: el nitrógeno alto solo trae problemas.',
        pGuidanceEs: 'Ventana buena para fósforo: la raíz lo está usando.',
        kGuidanceEs: 'El potasio ayuda a que aguante el estrés del trasplante.',
        careNoteEs:
            'Echando raíz: deja secar entre riegos. No la fuerces a crecer con '
            'fertilizante.',
      ),
      // Creciendo: única etapa donde el NPK realmente pesa.
      CactusStageIds.activeGrowth: _CactusStageProfile(
        moisture: AgroRange(
          lowMax: 6,
          optimalMin: 15,
          optimalMax: 58,
          highMin: 76,
        ),
        soilTemp: AgroRange(
          lowMax: 8,
          optimalMin: 18,
          optimalMax: 32,
          highMin: 40,
        ),
        ph: CactusUniversalProfile.phBase,
        ec: _cactusEcGrowth,
        resistance: _cactusResistanceEstablished,
        nPpm: _cactusNGrowth,
        pPpm: _cactusPGrowth,
        kPpm: _cactusKGrowth,
        wMoisture: 0.28,
        wSoilTemp: 0.12,
        wPh: 0.08,
        wEc: 0.12,
        wResistance: 0.11,
        wN: 0.11,
        wP: 0.08,
        wK: 0.10,
        nWindowEs: 'Demanda activa',
        pWindowEs: 'Demanda activa',
        kWindowEs: 'Alta demanda de K',
        nGuidanceEs:
            'Creciendo: el nitrógeno sirve, pero de más da tejido aguado y '
            'débil.',
        pGuidanceEs: 'El fósforo sostiene raíz y espinas durante el empuje.',
        kGuidanceEs:
            'El potasio manda en cactus: firmeza, espinas y aguante al calor.',
        careNoteEs:
            'Creciendo: riega por pulsos sin encharcar. Es la única etapa donde '
            'la nutrición pesa de verdad.',
      ),
      // Estable: se queda aquí indefinidamente. El mantenimiento NO cierra ciclo.
      CactusStageIds.maintenance: _CactusStageProfile(
        moisture: AgroRange(
          lowMax: 4,
          optimalMin: 10,
          optimalMax: 54,
          highMin: 72,
        ),
        soilTemp: AgroRange(
          lowMax: 5,
          optimalMin: 12,
          optimalMax: 32,
          highMin: 40,
        ),
        ph: CactusUniversalProfile.phBase,
        ec: _cactusEcMaintenance,
        resistance: _cactusResistanceEstablished,
        nPpm: _cactusNMaintenance,
        pPpm: _cactusPMaintenance,
        kPpm: _cactusKMaintenance,
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
        nGuidanceEs: 'Estable: nitrógeno bajo. No busques crecimiento rápido.',
        pGuidanceEs: 'Fósforo de mantenimiento. Sin urgencia.',
        kGuidanceEs: 'Mantén el potasio: es lo que la conserva firme.',
        careNoteEs:
            'Estable: vigila que no se acumule sal ni humedad. Puede quedarse '
            'así por años.',
      ),
      // En reposo: menor demanda de agua. Frío + humedad es la peor combinación.
      CactusStageIds.rest: _CactusStageProfile(
        moisture: AgroRange(
          lowMax: 3,
          optimalMin: 7,
          optimalMax: 44,
          highMin: 62,
        ),
        soilTemp: AgroRange(
          lowMax: 2,
          optimalMin: 6,
          optimalMax: 20,
          highMin: 32,
        ),
        ph: CactusUniversalProfile.phBase,
        ec: _cactusEcRest,
        resistance: _cactusResistanceEstablished,
        nPpm: _cactusNRest,
        pPpm: _cactusPRest,
        kPpm: _cactusKRest,
        wMoisture: 0.34,
        wSoilTemp: 0.18,
        wPh: 0.06,
        wEc: 0.13,
        wResistance: 0.11,
        wN: 0.05,
        wP: 0.05,
        wK: 0.08,
        nWindowEs: 'Sin demanda',
        pWindowEs: 'Sin demanda',
        kWindowEs: 'Demanda baja',
        nGuidanceEs:
            'En reposo: no fertilices con nitrógeno. La planta no lo va a usar.',
        pGuidanceEs: 'En reposo el fósforo no es prioridad.',
        kGuidanceEs: 'El potasio ayuda a resistir el frío.',
        careNoteEs:
            'En reposo: riega mucho menos. Frío con sustrato húmedo es lo más '
            'peligroso para la raíz.',
      ),
      // Etapa por confirmar: targets amplios y prudentes.
      CactusStageIds.unknown: _CactusStageProfile(
        moisture: AgroRange(
          lowMax: 4,
          optimalMin: 10,
          optimalMax: 54,
          highMin: 72,
        ),
        soilTemp: AgroRange(
          lowMax: 5,
          optimalMin: 12,
          optimalMax: 30,
          highMin: 38,
        ),
        ph: CactusUniversalProfile.phBase,
        ec: _cactusEcMaintenance,
        resistance: _cactusResistanceEstablished,
        nPpm: _cactusNMaintenance,
        pPpm: _cactusPMaintenance,
        kPpm: _cactusKMaintenance,
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
        nGuidanceEs: 'Nitrógeno bajo mientras se confirma la etapa.',
        pGuidanceEs: 'Fósforo de mantenimiento mientras se confirma la etapa.',
        kGuidanceEs: 'Potasio de mantenimiento mientras se confirma la etapa.',
        careNoteEs:
            'Etapa por confirmar: cuida sobre todo el exceso de agua, el mal '
            'drenaje y el frío húmedo.',
      ),
    };

_CactusStageProfile _profileForStage(String? stageId) {
  final id = normalizeCactusStageId(stageId);
  return _cactusStageProfiles[id] ??
      _cactusStageProfiles[CactusStageIds.unknown]!;
}

/// Targets de sensor por etapa, en unidades reales.
StageTargets resolveCactusTargets(
  String? stageId, {
  String? cultivationContextId,
}) {
  final p = _profileForStage(stageId);
  return StageTargets(
    moistureRaw: p.moisture,
    soilTemp: p.soilTemp,
    ph: _cactusPhForContext(cultivationContextId, fallback: p.ph),
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

/// Targets ajustados por el contexto de cultivo que el perfil implica de forma
/// inequívoca. CA-02 y CA-04 admiten maceta o paisaje, así que conservan el
/// rango base hasta que el usuario lo precise.
StageTargets resolveCactusTargetsForProfile(
  String? stageId, {
  required String? profileId,
}) {
  final cultivationContextId = switch (profileId?.trim().toLowerCase()) {
    kCa01DesertContainer => 'pot',
    kCa03ColumnarLandscape => 'landscape',
    _ => 'unknown',
  };
  return resolveCactusTargets(
    stageId,
    cultivationContextId: cultivationContextId,
  );
}

AgroRange _cactusPhForContext(String? contextId, {required AgroRange fallback}) {
  return switch (contextId?.trim().toLowerCase()) {
    'pot' || 'nursery' => CactusUniversalProfile.phPotNursery,
    'planter' || 'garden_bed' => CactusUniversalProfile.phPlanterGarden,
    'landscape' || 'open_ground' => CactusUniversalProfile.phLandscapeGround,
    _ => fallback,
  };
}

/// Pesos del AgroScore por etapa. Cada fila suma 1.00.
StageWeights resolveCactusStageWeights(String? stageId, {String? profileId}) {
  final p = _profileForStage(stageId);
  return StageWeights(
    moisture: p.wMoisture,
    soilTemp: p.wSoilTemp,
    resistance: p.wResistance,
    ph: p.wPh,
    ec: p.wEc,
    n: p.wN,
    p: p.wP,
    k: p.wK,
  );
}

/// Nota corta de cuidado por etapa, en lenguaje de agricultor.
String cactusStageCareNoteEs(String? stageId) =>
    _profileForStage(stageId).careNoteEs;
