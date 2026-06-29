import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Perfil universal agronómico de la Pera (Pyrus communis).
///
/// Alimentado por el documento oficial
/// `05_Guia_Fertilizacion_NPK_Targets_BioG_Pera_v1_1_reforzada` (§8, §10, §11,
/// §13) y `01_Ficha_Tecnica_Universal` (§9, §10).
///
/// Reglas no negociables que respeta este archivo:
/// - NO es una receta de fertilización en kg/ha; son prioridades RELATIVAS
///   N-P-K por etapa fisiológica (0..1) + targets de sensor BIO-G v1.
/// - Solo usa métricas compatibles con BIO-G v1: soilMoisture, soilTemp, ph,
///   ec, resistance, n, p, k. Ca/Mg/B/Zn/Fe quedan como CONTEXTO de mensaje,
///   nunca como sensores obligatorios (doc 05 §3.7-§3.9).
/// - Contrato AgroRange v1.4: `lowMax` es frontera crítica baja (NO inicio del
///   óptimo); en suelo/ambiente no se deja `lowMax == optimalMin` ni
///   `optimalMax == highMin` sin justificación. En EC/resistance la métrica es
///   de exceso: `lowMax = -0.01` es un placeholder seguro documentado.
/// - Contrato v1.5: `post_harvest` es etapa ACTIVA (reservas), NO dormancia;
///   `fruit_fill` NO es `harvest_maturity`.
/// - El perfil/variedad PR NO cambia la estructura fenológica ni estos targets
///   base; solo ajusta sensibilidad/mensajes en capas superiores.
///
/// Las entradas públicas que el resto del proyecto debe usar:
/// - [resolvePearTreeTargets]            → StageTargets por etapa.
/// - [resolvePearTreeStageWeights]       → StageWeights (AgroScore) por etapa.
/// - [resolvePearTreeNutritionPriorities] → prioridades NPK + nota UX.
class PearTreeUniversalProfile {
  const PearTreeUniversalProfile._();

  /// pH de etapas activas sensibles (doc 05 §10.3): preferido 6.0-6.8, extremo
  /// fuerte cerca de <5.2 o >7.8.
  static const AgroRange phActiveSensitive = AgroRange(
    lowMax: 5.2,
    optimalMin: 6.0,
    optimalMax: 6.8,
    highMin: 7.8,
  );

  /// pH base (dormancia / unknown / etapas no críticas): óptimo 6.0-7.0.
  static const AgroRange phBase = AgroRange(
    lowMax: 5.2,
    optimalMin: 6.0,
    optimalMax: 7.0,
    highMin: 8.0,
  );
}

/// Prioridades NPK relativas por etapa + contexto UX corto (doc 05 §8).
///
/// Las prioridades son 0.00 (sin prioridad) a 1.00 (prioridad máxima). NO son
/// dosis: son peso fisiológico para interpretar la lectura del sensor.
class PearTreeStageNutrition {
  const PearTreeStageNutrition({
    required this.stageId,
    required this.nPriority01,
    required this.pPriority01,
    required this.kPriority01,
    required this.confidence,
    required this.careNoteEs,
  });

  final String stageId;
  final double nPriority01;
  final double pPriority01;
  final double kPriority01;

  /// Confianza cualitativa del modelado: 'low' | 'medium' | 'high'.
  final String confidence;

  /// Nota corta y segura para UX (doc 05 §8 "Cuidado:").
  final String careNoteEs;

  /// Nutriente NPK dominante de la etapa (mayor prioridad relativa).
  AgroMetricKey get dominantNutrient {
    if (kPriority01 >= nPriority01 && kPriority01 >= pPriority01) {
      return AgroMetricKey.k;
    }
    if (nPriority01 >= pPriority01) return AgroMetricKey.n;
    return AgroMetricKey.p;
  }
}

/// Datos crudos por etapa, transcritos del documento 05.
///
/// `nRel/pRel/kRel` son los AgroRange RELATIVOS (escala 0..100; doc 05 §10.6-§10.8
/// está en 0..1 y se multiplica por 100). Se entregan como `nIndex/pIndex/kIndex`
/// y el motor compartido los convierte a mg/kg comparables con el cap del cultivo
/// (`NutrientTargetRangeResolver` + `NpkCaps`). Sus bandas ya son suaves: no se
/// dejan rangos pegados óptimo→crítico.
class _PearStageProfile {
  const _PearStageProfile({
    required this.moisture,
    required this.soilTemp,
    required this.ph,
    required this.ec,
    required this.resistance,
    required this.nRel,
    required this.pRel,
    required this.kRel,
    required this.nPriority,
    required this.pPriority,
    required this.kPriority,
    required this.wMoisture,
    required this.wSoilTemp,
    required this.wPh,
    required this.wEc,
    required this.wResistance,
    required this.wN,
    required this.wP,
    required this.wK,
    required this.confidence,
    required this.careNoteEs,
    required this.uxGuidanceEs,
    required this.nWindowEs,
    required this.pWindowEs,
    required this.kWindowEs,
  });

  final AgroRange moisture;
  final AgroRange soilTemp;
  final AgroRange ph;
  final AgroRange ec;
  final AgroRange resistance;

  final AgroRange nRel;
  final AgroRange pRel;
  final AgroRange kRel;

  final double nPriority;
  final double pPriority;
  final double kPriority;

  final double wMoisture;
  final double wSoilTemp;
  final double wPh;
  final double wEc;
  final double wResistance;
  final double wN;
  final double wP;
  final double wK;

  final String confidence;
  final String careNoteEs;
  final String uxGuidanceEs;
  final String nWindowEs;
  final String pWindowEs;
  final String kWindowEs;
}

const Map<String, _PearStageProfile>
_pearStageProfiles = <String, _PearStageProfile>{
  TreeStageIds.plantingTransplant: _PearStageProfile(
    moisture: AgroRange(
      lowMax: 45,
      optimalMin: 65,
      optimalMax: 85,
      highMin: 92,
    ),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 12, optimalMax: 24, highMin: 30),
    ph: PearTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.2,
      highMin: 1.8,
    ),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.0,
    ),
    nRel: AgroRange(lowMax: 5, optimalMin: 20, optimalMax: 40, highMin: 75),
    pRel: AgroRange(lowMax: 20, optimalMin: 55, optimalMax: 75, highMin: 92),
    kRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 55, highMin: 85),
    nPriority: 0.20,
    pPriority: 0.80,
    kPriority: 0.45,
    wMoisture: 0.25,
    wSoilTemp: 0.15,
    wPh: 0.12,
    wEc: 0.18,
    wResistance: 0.18,
    wN: 0.03,
    wP: 0.06,
    wK: 0.03,
    confidence: 'medium',
    careNoteEs:
        'Raíz joven, baja salinidad y no quemar el árbol recién plantado.',
    uxGuidanceEs:
        'Tu peral está recién establecido. La prioridad es raíz, humedad '
        'estable, baja salinidad y suelo sin compactación. No conviene '
        'empujar nitrógeno; el fósforo pesa más que el nitrógeno.',
    nWindowEs: 'N bajo: priorizar raíz',
    pWindowEs: 'Ventana de raíz: P alto',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.rootEstablishment: _PearStageProfile(
    moisture: AgroRange(
      lowMax: 45,
      optimalMin: 65,
      optimalMax: 85,
      highMin: 92,
    ),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 12, optimalMax: 24, highMin: 30),
    ph: PearTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.2,
      highMin: 1.8,
    ),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.0,
    ),
    nRel: AgroRange(lowMax: 10, optimalMin: 25, optimalMax: 45, highMin: 75),
    pRel: AgroRange(lowMax: 20, optimalMin: 55, optimalMax: 75, highMin: 92),
    kRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 85),
    nPriority: 0.30,
    pPriority: 0.82,
    kPriority: 0.50,
    wMoisture: 0.30,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.18,
    wResistance: 0.18,
    wN: 0.03,
    wP: 0.06,
    wK: 0.03,
    confidence: 'medium',
    careNoteEs:
        'Raíces finas, humedad estable, EC baja, oxígeno, compactación baja.',
    uxGuidanceEs:
        'El peral está formando raíz fina. Fósforo y condición del suelo '
        'pesan más que una lectura alta de N. Mantén humedad estable sin '
        'saturar.',
    nWindowEs: 'N de apoyo',
    pWindowEs: 'Raíz fina: P alto',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.juvenileVegetative: _PearStageProfile(
    moisture: AgroRange(
      lowMax: 45,
      optimalMin: 60,
      optimalMax: 85,
      highMin: 92,
    ),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 26, highMin: 32),
    ph: PearTreeUniversalProfile.phBase,
    ec: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.2,
    ),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 55, optimalMax: 75, highMin: 90),
    pRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 65, highMin: 85),
    kRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 65, highMin: 88),
    nPriority: 0.72,
    pPriority: 0.55,
    kPriority: 0.58,
    wMoisture: 0.20,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.10,
    wResistance: 0.13,
    wN: 0.18,
    wP: 0.08,
    wK: 0.09,
    confidence: 'medium',
    careNoteEs:
        'Formar estructura sin vigor blando; no forzar fruta. Exceso de N '
        'sube riesgo de fuego bacteriano.',
    uxGuidanceEs:
        'El árbol joven necesita crecer, pero sin exceso de vigor. Mucho N '
        'puede formar brotes blandos, retrasar la entrada a producción y '
        'aumentar el riesgo de fuego bacteriano.',
    nWindowEs: 'Construcción de copa: N útil controlado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.dormancy: _PearStageProfile(
    moisture: AgroRange(
      lowMax: 35,
      optimalMin: 45,
      optimalMax: 70,
      highMin: 90,
    ),
    soilTemp: AgroRange(lowMax: -5, optimalMin: 0, optimalMax: 12, highMin: 20),
    ph: PearTreeUniversalProfile.phBase,
    ec: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.5,
    ),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 2.0,
      highMin: 2.5,
    ),
    nRel: AgroRange(lowMax: 0, optimalMin: 20, optimalMax: 40, highMin: 80),
    pRel: AgroRange(lowMax: 0, optimalMin: 25, optimalMax: 45, highMin: 90),
    kRel: AgroRange(lowMax: 0, optimalMin: 25, optimalMax: 45, highMin: 90),
    nPriority: 0.10,
    pPriority: 0.20,
    kPriority: 0.20,
    wMoisture: 0.18,
    wSoilTemp: 0.20,
    wPh: 0.12,
    wEc: 0.15,
    wResistance: 0.12,
    wN: 0.05,
    wP: 0.04,
    wK: 0.04,
    confidence: 'low',
    careNoteEs:
        'Demanda baja; no sobreinterpretar NPK. Revisar pH, salinidad y '
        'planear. Frío es contexto externo.',
    uxGuidanceEs:
        'El peral está en reposo. La demanda NPK es baja. Usa esta etapa '
        'para revisar pH, salinidad, suelo y planear el arranque.',
    nWindowEs: 'Reposo: demanda baja',
    pWindowEs: 'Reposo: demanda baja',
    kWindowEs: 'Reposo: demanda baja',
  ),
  TreeStageIds.budbreak: _PearStageProfile(
    moisture: AgroRange(
      lowMax: 45,
      optimalMin: 55,
      optimalMax: 80,
      highMin: 90,
    ),
    soilTemp: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 22, highMin: 28),
    ph: PearTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.0,
    ),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 50, optimalMax: 70, highMin: 85),
    pRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 65, highMin: 85),
    kRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 65, highMin: 88),
    nPriority: 0.60,
    pPriority: 0.60,
    kPriority: 0.55,
    wMoisture: 0.22,
    wSoilTemp: 0.18,
    wPh: 0.10,
    wEc: 0.12,
    wResistance: 0.10,
    wN: 0.12,
    wP: 0.08,
    wK: 0.08,
    confidence: 'medium',
    careNoteEs: 'Arranque desde reservas; raíz puede estar fría.',
    uxGuidanceEs:
        'El árbol está arrancando. Parte del arranque viene de reservas del '
        'ciclo anterior. Si el suelo está frío, la absorción será lenta.',
    nWindowEs: 'Arranque: N moderado',
    pWindowEs: 'P suficiente para brotación',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.vegetativeGrowth: _PearStageProfile(
    moisture: AgroRange(
      lowMax: 45,
      optimalMin: 55,
      optimalMax: 80,
      highMin: 90,
    ),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 26, highMin: 32),
    ph: PearTreeUniversalProfile.phBase,
    ec: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.2,
    ),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 30, optimalMin: 50, optimalMax: 70, highMin: 88),
    pRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 85),
    kRel: AgroRange(lowMax: 20, optimalMin: 50, optimalMax: 70, highMin: 88),
    nPriority: 0.65,
    pPriority: 0.45,
    kPriority: 0.60,
    wMoisture: 0.20,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.10,
    wResistance: 0.12,
    wN: 0.18,
    wP: 0.07,
    wK: 0.11,
    confidence: 'medium',
    careNoteEs:
        'Hoja y brote; controlar exceso de vigor por fuego bacteriano y '
        'calidad.',
    uxGuidanceEs:
        'Etapa de hojas y brotes. Nitrógeno moderado ayuda, pero exceso '
        'puede generar sombra, vigor blando y más riesgo de fuego '
        'bacteriano.',
    nWindowEs: 'Crecimiento: N útil controlado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.flowering: _PearStageProfile(
    moisture: AgroRange(
      lowMax: 45,
      optimalMin: 60,
      optimalMax: 85,
      highMin: 90,
    ),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 24, highMin: 28),
    ph: PearTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.0,
    ),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 30, optimalMax: 50, highMin: 75),
    pRel: AgroRange(lowMax: 20, optimalMin: 50, optimalMax: 70, highMin: 88),
    kRel: AgroRange(lowMax: 25, optimalMin: 50, optimalMax: 70, highMin: 88),
    nPriority: 0.30,
    pPriority: 0.68,
    kPriority: 0.65,
    wMoisture: 0.28,
    wSoilTemp: 0.20,
    wPh: 0.08,
    wEc: 0.14,
    wResistance: 0.08,
    wN: 0.04,
    wP: 0.08,
    wK: 0.10,
    confidence: 'high',
    careNoteEs:
        'Floración usa reservas; agua y clima pesan más que N. B/Zn/Ca como '
        'contexto; cuidar fuego bacteriano.',
    uxGuidanceEs:
        'Floración es crítica. No se resuelve solo con N. Agua estable, '
        'clima, polinización, B/Zn/Ca contextuales y reservas pesan mucho. '
        'Cuida el fuego bacteriano.',
    nWindowEs: 'Floración: no empujar N',
    pWindowEs: 'Floración: P relevante',
    kWindowEs: 'Floración: K relevante',
  ),
  TreeStageIds.fruitSet: _PearStageProfile(
    moisture: AgroRange(
      lowMax: 45,
      optimalMin: 65,
      optimalMax: 85,
      highMin: 90,
    ),
    soilTemp: AgroRange(
      lowMax: 10,
      optimalMin: 14,
      optimalMax: 26,
      highMin: 30,
    ),
    ph: PearTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.0,
    ),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 30, optimalMax: 50, highMin: 75),
    pRel: AgroRange(lowMax: 15, optimalMin: 40, optimalMax: 60, highMin: 85),
    kRel: AgroRange(lowMax: 30, optimalMin: 60, optimalMax: 80, highMin: 92),
    nPriority: 0.32,
    pPriority: 0.50,
    kPriority: 0.78,
    wMoisture: 0.30,
    wSoilTemp: 0.15,
    wPh: 0.08,
    wEc: 0.16,
    wResistance: 0.08,
    wN: 0.04,
    wP: 0.07,
    wK: 0.12,
    confidence: 'high',
    careNoteEs:
        'Amarre, caída, tamaño potencial; agua estable, salinidad baja, '
        'evitar calor/estrés. Ca/Mg contexto.',
    uxGuidanceEs:
        'En cuajado el árbol decide qué fruta sostiene. El K empieza a '
        'pesar más, pero agua, salinidad y calor pueden cambiar todo. La '
        'polinización previa también define el amarre.',
    nWindowEs: 'Cuajado: N moderado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Cuajado: K empieza a pesar',
  ),
  TreeStageIds.fruitFill: _PearStageProfile(
    moisture: AgroRange(
      lowMax: 45,
      optimalMin: 65,
      optimalMax: 90,
      highMin: 94,
    ),
    soilTemp: AgroRange(
      lowMax: 10,
      optimalMin: 16,
      optimalMax: 28,
      highMin: 32,
    ),
    ph: PearTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.2,
    ),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 10, optimalMin: 25, optimalMax: 45, highMin: 70),
    pRel: AgroRange(lowMax: 10, optimalMin: 30, optimalMax: 50, highMin: 80),
    kRel: AgroRange(lowMax: 35, optimalMin: 70, optimalMax: 90, highMin: 96),
    nPriority: 0.28,
    pPriority: 0.35,
    kPriority: 0.90,
    wMoisture: 0.26,
    wSoilTemp: 0.12,
    wPh: 0.08,
    wEc: 0.13,
    wResistance: 0.08,
    wN: 0.05,
    wP: 0.05,
    wK: 0.23,
    confidence: 'high',
    careNoteEs:
        'K protagonista; N bajo-moderado; Ca/Mg/B contexto; vigilar EC. '
        'Calibre y firmeza dependen de agua estable.',
    uxGuidanceEs:
        'En llenado, K es protagonista para tamaño y calidad. N debe '
        'mantenerse bajo-moderado; revisa balance con Ca/Mg y EC.',
    nWindowEs: 'Llenado: N bajo-moderado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Llenado: K protagonista',
  ),
  TreeStageIds.harvestMaturity: _PearStageProfile(
    moisture: AgroRange(
      lowMax: 45,
      optimalMin: 55,
      optimalMax: 80,
      highMin: 90,
    ),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 28, highMin: 32),
    ph: PearTreeUniversalProfile.phBase,
    ec: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 5, optimalMin: 18, optimalMax: 35, highMin: 60),
    pRel: AgroRange(lowMax: 5, optimalMin: 25, optimalMax: 45, highMin: 80),
    kRel: AgroRange(lowMax: 25, optimalMin: 55, optimalMax: 75, highMin: 92),
    nPriority: 0.15,
    pPriority: 0.25,
    kPriority: 0.65,
    wMoisture: 0.22,
    wSoilTemp: 0.14,
    wPh: 0.08,
    wEc: 0.12,
    wResistance: 0.08,
    wN: 0.05,
    wP: 0.05,
    wK: 0.26,
    confidence: 'medium',
    careNoteEs:
        'Madurez/cosecha comercial; evitar N alto; firmeza, calidad y '
        'conservación. K suficiente sin desbalance.',
    uxGuidanceEs:
        'En madurez/cosecha, evita N alto. Prioridad: firmeza, calidad, '
        'conservación y fruta comercial. En pera europea muchas variedades '
        'se cortan firmes y maduran fuera del árbol.',
    nWindowEs: 'Madurez: evitar N alto',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Madurez: K útil',
  ),
  TreeStageIds.postHarvest: _PearStageProfile(
    moisture: AgroRange(
      lowMax: 45,
      optimalMin: 55,
      optimalMax: 80,
      highMin: 90,
    ),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 10, optimalMax: 24, highMin: 30),
    ph: PearTreeUniversalProfile.phBase,
    ec: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 78),
    pRel: AgroRange(lowMax: 10, optimalMin: 30, optimalMax: 55, highMin: 85),
    kRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 70, highMin: 90),
    nPriority: 0.55,
    pPriority: 0.35,
    kPriority: 0.60,
    wMoisture: 0.22,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.14,
    wResistance: 0.10,
    wN: 0.12,
    wP: 0.07,
    wK: 0.13,
    confidence: 'medium',
    careNoteEs:
        'Reservas y yemas del siguiente ciclo; B/Zn contexto; solo con hoja '
        'activa, EC baja y temperatura suficiente.',
    uxGuidanceEs:
        'Después de cosecha el peral sigue vivo. Si conserva hoja activa y '
        'el suelo está bien, puede recuperar reservas para el siguiente '
        'ciclo. La postcosecha NO cierra el cultivo.',
    nWindowEs: 'Postcosecha: N de reservas (con hoja activa)',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Postcosecha: K de reservas',
  ),
  TreeStageIds.unknown: _PearStageProfile(
    moisture: AgroRange(
      lowMax: 45,
      optimalMin: 60,
      optimalMax: 85,
      highMin: 92,
    ),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 12, optimalMax: 26, highMin: 32),
    ph: PearTreeUniversalProfile.phBase,
    ec: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.2,
    ),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 40, optimalMax: 65, highMin: 85),
    pRel: AgroRange(lowMax: 10, optimalMin: 40, optimalMax: 65, highMin: 85),
    kRel: AgroRange(lowMax: 15, optimalMin: 40, optimalMax: 70, highMin: 90),
    nPriority: 0.45,
    pPriority: 0.45,
    kPriority: 0.50,
    wMoisture: 0.24,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.14,
    wResistance: 0.12,
    wN: 0.09,
    wP: 0.09,
    wK: 0.10,
    confidence: 'low',
    careNoteEs: 'Conservador; pedir etapa visible.',
    uxGuidanceEs:
        'Con etapa desconocida, BIO-G usa rangos conservadores. Para mayor '
        'precisión, indica si el árbol está brotando, floreando, con '
        'frutito, llenando fruto, en cosecha o postcosecha.',
    nWindowEs: 'Etapa no definida',
    pWindowEs: 'Etapa no definida',
    kWindowEs: 'Etapa no definida',
  ),
};

_PearStageProfile _profileForStage(String? stageId) {
  final id = normalizeTreeStageId(stageId);
  return _pearStageProfiles[id] ?? _pearStageProfiles[TreeStageIds.unknown]!;
}

/// Targets de sensor por etapa para `resolveTargets` de la pera (doc 05 §10).
///
/// Los `nIndex/pIndex/kIndex` llevan el rango RELATIVO por etapa (0..100). El
/// motor compartido (`NutrientTargetRangeResolver`) los convierte a mg/kg con el
/// cap del cultivo (`NpkCaps`), así las bandas bajo/óptimo/alto-útil/exceso ya
/// quedan suaves sin saltos óptimo→crítico.
StageTargets resolvePearTreeTargets(String? stageId) {
  final p = _profileForStage(stageId);
  return StageTargets(
    moistureRaw: p.moisture,
    soilTemp: p.soilTemp,
    ph: p.ph,
    ec: p.ec,
    resistance: p.resistance,
    nIndex: p.nRel,
    pIndex: p.pRel,
    kIndex: p.kRel,
    nPriority: p.nPriority,
    pPriority: p.pPriority,
    kPriority: p.kPriority,
    nWindowLabelEs: p.nWindowEs,
    pWindowLabelEs: p.pWindowEs,
    kWindowLabelEs: p.kWindowEs,
    nShortGuidanceEs: p.uxGuidanceEs,
    pShortGuidanceEs: p.uxGuidanceEs,
    kShortGuidanceEs: p.uxGuidanceEs,
  );
}

/// Pesos AgroScore por etapa (doc 05 §11). Pesos explícitos por nutriente.
StageWeights resolvePearTreeStageWeights(String? stageId) {
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

/// Prioridades NPK relativas + nota UX por etapa (doc 05 §8).
PearTreeStageNutrition resolvePearTreeNutritionPriorities(String? stageId) {
  final p = _profileForStage(stageId);
  return PearTreeStageNutrition(
    stageId: normalizeTreeStageId(stageId),
    nPriority01: p.nPriority,
    pPriority01: p.pPriority,
    kPriority01: p.kPriority,
    confidence: p.confidence,
    careNoteEs: p.careNoteEs,
  );
}

/// Guía UX corta por etapa (doc 05 §13) para tarjetas/resúmenes de la pera.
String pearTreeStageGuidanceEs(String? stageId) =>
    _profileForStage(stageId).uxGuidanceEs;
