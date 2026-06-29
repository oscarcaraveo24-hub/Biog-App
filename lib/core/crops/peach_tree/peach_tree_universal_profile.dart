import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Perfil universal agronómico del Durazno (Prunus persica) — frutal de
/// hueso/carozo.
///
/// Alimentado por el documento oficial
/// `05_Guia_Fertilizacion_NPK_Targets_BioG_Durazno_DZ_v1_1_reforzada` (§8, §10,
/// §11) y `01_Ficha_Tecnica_Universal` (§8, §9, §10).
///
/// Reglas no negociables que respeta este archivo:
/// - NO es una receta de fertilización en kg/ha; son prioridades RELATIVAS
///   N-P-K por etapa fisiológica (0..1) + targets de sensor BIO-G v1.
/// - Solo usa métricas compatibles con BIO-G v1: soilMoisture, soilTemp, ph,
///   ec, resistance, n, p, k. Ca/Mg/B/Zn/Fe quedan como CONTEXTO de mensaje,
///   nunca como sensores obligatorios (doc 05 §3.7, §4.4-§4.7).
/// - Contrato AgroRange v1.4/v1.5: `lowMax` es frontera crítica baja (NO inicio
///   del óptimo); en suelo/ambiente no se deja `lowMax == optimalMin` ni
///   `optimalMax == highMin` sin justificación. En EC/resistance la métrica es
///   de exceso: `lowMax = -0.01` es un placeholder seguro documentado.
/// - Contrato v1.5: `post_harvest` es etapa ACTIVA (reservas), NO dormancia;
///   `fruit_fill` NO es `harvest_maturity` (el llenado no habla de cosecha).
/// - Durazno es de HUESO: el endurecimiento de hueso/carozo es una SUBVENTANA
///   dentro de `fruit_fill`, NO un stageId nuevo (doc 01 §0.3, §14).
/// - El perfil/variedad DZ NO cambia la estructura fenológica ni estos targets
///   base; solo ajusta sensibilidad/mensajes en capas superiores (doc 05 §15).
///
/// Las entradas públicas que el resto del proyecto debe usar:
/// - [resolvePeachTreeTargets]             → StageTargets por etapa.
/// - [resolvePeachTreeStageWeights]        → StageWeights (AgroScore) por etapa.
/// - [resolvePeachTreeNutritionPriorities] → prioridades NPK + nota UX.
class PeachTreeUniversalProfile {
  const PeachTreeUniversalProfile._();

  /// pH de etapas activas (doc 05 §6.1, §10): óptimo 6.0-7.0; extremo cerca de
  /// <5.2 o >7.8. v1.1 sugiere favorecer 6.0-6.5 en suelo mexicano/calizo solo
  /// como matiz de mensaje, sin sobreajustar el target de código.
  static const AgroRange phActiveSensitive = AgroRange(
    lowMax: 5.2,
    optimalMin: 6.0,
    optimalMax: 7.0,
    highMin: 7.8,
  );

  /// pH base (dormancia / unknown): óptimo más amplio 6.0-7.2.
  static const AgroRange phBase = AgroRange(
    lowMax: 5.2,
    optimalMin: 6.0,
    optimalMax: 7.2,
    highMin: 8.0,
  );
}

/// Prioridades NPK relativas por etapa + contexto UX corto (doc 05 §8).
///
/// Las prioridades son 0.00 (sin prioridad) a 1.00 (prioridad máxima). NO son
/// dosis: son peso fisiológico para interpretar la lectura del sensor.
class PeachTreeStageNutrition {
  const PeachTreeStageNutrition({
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

  /// Nota corta y segura para UX (doc 05 §9 "Lectura:").
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
/// `nRel/pRel/kRel` son los AgroRange RELATIVOS (escala 0..100; doc 05 §10 está
/// en 0..1 y se multiplica por 100). Se entregan como `nIndex/pIndex/kIndex` y
/// el motor compartido los convierte a mg/kg comparables con el cap del cultivo
/// (`NutrientTargetRangeResolver` + `NpkCaps`). Sus bandas ya son suaves: no se
/// dejan rangos pegados óptimo→crítico.
class _PeachStageProfile {
  const _PeachStageProfile({
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

const Map<String, _PeachStageProfile>
_peachStageProfiles = <String, _PeachStageProfile>{
  TreeStageIds.plantingTransplant: _PeachStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 62, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 12, optimalMax: 24, highMin: 30),
    ph: PeachTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.2, highMin: 1.8),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.4,
      highMin: 2.0,
    ),
    nRel: AgroRange(lowMax: 5, optimalMin: 18, optimalMax: 35, highMin: 70),
    pRel: AgroRange(lowMax: 20, optimalMin: 55, optimalMax: 75, highMin: 92),
    kRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 55, highMin: 85),
    nPriority: 0.18,
    pPriority: 0.82,
    kPriority: 0.45,
    wMoisture: 0.25,
    wSoilTemp: 0.15,
    wPh: 0.12,
    wEc: 0.18,
    wResistance: 0.20,
    wN: 0.03,
    wP: 0.05,
    wK: 0.02,
    confidence: 'medium',
    careNoteEs:
        'Raíz joven, baja salinidad, humedad estable, no quemar raíces.',
    uxGuidanceEs:
        'Tu duraznero está recién plantado. La prioridad es raíz, humedad '
        'estable, baja salinidad y suelo sin compactación. No conviene empujar '
        'nitrógeno; el fósforo pesa más que el nitrógeno.',
    nWindowEs: 'N bajo: priorizar raíz',
    pWindowEs: 'Ventana de raíz: P alto',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.rootEstablishment: _PeachStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 62, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 12, optimalMax: 24, highMin: 30),
    ph: PeachTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.2, highMin: 1.8),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.4,
      highMin: 2.0,
    ),
    nRel: AgroRange(lowMax: 10, optimalMin: 25, optimalMax: 45, highMin: 75),
    pRel: AgroRange(lowMax: 20, optimalMin: 55, optimalMax: 75, highMin: 92),
    kRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 85),
    nPriority: 0.28,
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
    careNoteEs: 'Raíz fina y oxígeno mandan; P de arranque y suelo sin compactar.',
    uxGuidanceEs:
        'El duraznero está formando raíz fina. El fósforo y la condición del '
        'suelo pesan más que una lectura alta de N. La raíz del durazno es '
        'superficial: mantén humedad estable sin saturar.',
    nWindowEs: 'N de apoyo',
    pWindowEs: 'Raíz fina: P alto',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.juvenileVegetative: _PeachStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 58, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 26, highMin: 32),
    ph: PeachTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.5, highMin: 2.2),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 50, optimalMax: 70, highMin: 88),
    pRel: AgroRange(lowMax: 18, optimalMin: 40, optimalMax: 60, highMin: 85),
    kRel: AgroRange(lowMax: 20, optimalMin: 40, optimalMax: 60, highMin: 85),
    nPriority: 0.74,
    pPriority: 0.52,
    kPriority: 0.58,
    wMoisture: 0.22,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.12,
    wResistance: 0.15,
    wN: 0.16,
    wP: 0.08,
    wK: 0.08,
    confidence: 'medium',
    careNoteEs:
        'Formar estructura y madera fructífera sin vigor blando ni exceso de N.',
    uxGuidanceEs:
        'El árbol joven necesita crecer copa y madera fructífera, pero sin '
        'exceso de vigor. Mucho N da brotes blandos, sombra y más presión de '
        'plagas; en durazno no conviene forzar fruta todavía.',
    nWindowEs: 'Construcción de copa: N útil controlado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.dormancy: _PeachStageProfile(
    moisture: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 68, highMin: 86),
    soilTemp: AgroRange(lowMax: -5, optimalMin: 0, optimalMax: 12, highMin: 20),
    ph: PeachTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.8, highMin: 2.5),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 2.0,
      highMin: 2.6,
    ),
    nRel: AgroRange(lowMax: 0, optimalMin: 15, optimalMax: 35, highMin: 80),
    pRel: AgroRange(lowMax: 0, optimalMin: 20, optimalMax: 40, highMin: 85),
    kRel: AgroRange(lowMax: 0, optimalMin: 20, optimalMax: 40, highMin: 85),
    nPriority: 0.08,
    pPriority: 0.18,
    kPriority: 0.18,
    wMoisture: 0.14,
    wSoilTemp: 0.18,
    wPh: 0.10,
    wEc: 0.12,
    wResistance: 0.10,
    wN: 0.04,
    wP: 0.04,
    wK: 0.04,
    confidence: 'low',
    careNoteEs:
        'Demanda NPK baja; frío, salinidad, suelo y reservas como contexto.',
    uxGuidanceEs:
        'El duraznero está en reposo y sin hoja activa. La demanda NPK es baja. '
        'El frío invernal es contexto externo (no sensor v1); usa esta etapa '
        'para revisar pH, salinidad, suelo y planear el arranque.',
    nWindowEs: 'Reposo: demanda baja',
    pWindowEs: 'Reposo: demanda baja',
    kWindowEs: 'Reposo: demanda baja',
  ),
  TreeStageIds.budbreak: _PeachStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 80, highMin: 90),
    soilTemp: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 22, highMin: 28),
    ph: PeachTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.5, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 45, optimalMax: 65, highMin: 85),
    pRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 65, highMin: 85),
    kRel: AgroRange(lowMax: 20, optimalMin: 40, optimalMax: 60, highMin: 85),
    nPriority: 0.62,
    pPriority: 0.58,
    kPriority: 0.55,
    wMoisture: 0.22,
    wSoilTemp: 0.18,
    wPh: 0.10,
    wEc: 0.12,
    wResistance: 0.10,
    wN: 0.13,
    wP: 0.08,
    wK: 0.07,
    confidence: 'medium',
    careNoteEs: 'Arranque desde reservas, suelo templado, N moderado y P/K balanceados.',
    uxGuidanceEs:
        'El árbol está brotando. Parte del arranque viene de reservas del ciclo '
        'anterior. Si el suelo está frío la absorción será lenta. Vigila frío '
        'tardío: la yema avanzada del durazno pierde tolerancia a la helada.',
    nWindowEs: 'Arranque: N moderado',
    pWindowEs: 'P suficiente para brotación',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.vegetativeGrowth: _PeachStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 80, highMin: 90),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 27, highMin: 33),
    ph: PeachTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.6, highMin: 2.2),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 30, optimalMin: 50, optimalMax: 70, highMin: 88),
    pRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 85),
    kRel: AgroRange(lowMax: 25, optimalMin: 45, optimalMax: 65, highMin: 88),
    nPriority: 0.68,
    pPriority: 0.42,
    kPriority: 0.62,
    wMoisture: 0.20,
    wSoilTemp: 0.12,
    wPh: 0.09,
    wEc: 0.10,
    wResistance: 0.11,
    wN: 0.18,
    wP: 0.08,
    wK: 0.12,
    confidence: 'medium',
    careNoteEs:
        'Hoja y madera de fruto; evitar sombreo por exceso de N y luz interna baja.',
    uxGuidanceEs:
        'Etapa de hojas y brotes. Nitrógeno moderado ayuda, pero el exceso da '
        'copa cerrada, sombra y madera que no endurece bien antes del frío. En '
        'durazno la luz dentro de la copa define la madera fructífera del '
        'siguiente ciclo.',
    nWindowEs: 'Crecimiento: N útil controlado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.flowering: _PeachStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 24, highMin: 28),
    ph: PeachTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.5, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 28, optimalMax: 48, highMin: 75),
    pRel: AgroRange(lowMax: 25, optimalMin: 50, optimalMax: 70, highMin: 88),
    kRel: AgroRange(lowMax: 25, optimalMin: 45, optimalMax: 65, highMin: 85),
    nPriority: 0.26,
    pPriority: 0.66,
    kPriority: 0.62,
    wMoisture: 0.26,
    wSoilTemp: 0.20,
    wPh: 0.08,
    wEc: 0.14,
    wResistance: 0.08,
    wN: 0.05,
    wP: 0.10,
    wK: 0.09,
    confidence: 'high',
    careNoteEs:
        'Etapa crítica: helada, clima y agua mandan; B/Zn/Ca contexto, no empujar N.',
    uxGuidanceEs:
        'La floración del durazno es temprana y muy sensible a heladas tardías; '
        'no se resuelve con N. Agua estable, clima, reservas y B/Zn/Ca '
        'contextuales pesan mucho. Mucha flor no garantiza carga.',
    nWindowEs: 'Floración: no empujar N',
    pWindowEs: 'Floración: P relevante',
    kWindowEs: 'Floración: K relevante',
  ),
  TreeStageIds.fruitSet: _PeachStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 65, optimalMax: 85, highMin: 92),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 14, optimalMax: 26, highMin: 31),
    ph: PeachTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.5, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 18, optimalMin: 35, optimalMax: 55, highMin: 78),
    pRel: AgroRange(lowMax: 15, optimalMin: 40, optimalMax: 60, highMin: 85),
    kRel: AgroRange(lowMax: 30, optimalMin: 60, optimalMax: 80, highMin: 92),
    nPriority: 0.32,
    pPriority: 0.48,
    kPriority: 0.78,
    wMoisture: 0.30,
    wSoilTemp: 0.16,
    wPh: 0.08,
    wEc: 0.15,
    wResistance: 0.08,
    wN: 0.05,
    wP: 0.07,
    wK: 0.11,
    confidence: 'high',
    careNoteEs:
        'Amarre/cuajado: agua estable, salinidad baja, K subiendo, evitar aborto.',
    uxGuidanceEs:
        'En cuajado el árbol decide qué fruta sostiene. El K empieza a pesar '
        'más, pero agua estable, baja salinidad y evitar calor/estrés definen '
        'el amarre. Si hubo helada o frío, la carga puede caer aunque el NPK '
        'esté bien.',
    nWindowEs: 'Cuajado: N moderado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Cuajado: K empieza a pesar',
  ),
  TreeStageIds.fruitFill: _PeachStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 65, optimalMax: 88, highMin: 93),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 30, highMin: 35),
    ph: PeachTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.6, highMin: 2.2),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 30, optimalMax: 50, highMin: 75),
    pRel: AgroRange(lowMax: 10, optimalMin: 25, optimalMax: 45, highMin: 75),
    kRel: AgroRange(lowMax: 35, optimalMin: 70, optimalMax: 90, highMin: 96),
    nPriority: 0.30,
    pPriority: 0.32,
    kPriority: 0.92,
    wMoisture: 0.30,
    wSoilTemp: 0.12,
    wPh: 0.08,
    wEc: 0.13,
    wResistance: 0.08,
    wN: 0.07,
    wP: 0.05,
    wK: 0.20,
    confidence: 'high',
    // CONTRATO v1.5: copy de LLENADO, nunca de cosecha/madurez.
    careNoteEs:
        'Llenado: K protagonista para calibre y firmeza; hueso/carozo como '
        'subventana; N controlado y agua estable.',
    uxGuidanceEs:
        'En llenado, el K es protagonista para calibre, turgencia y firmeza del '
        'fruto verde que crece. El endurecimiento de hueso/carozo ocurre dentro '
        'de esta etapa: agua estable y N controlado; revisa balance con Ca/Mg y '
        'EC. Mucha fruta sin raleo baja el calibre.',
    nWindowEs: 'Llenado: N bajo-moderado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Llenado: K protagonista',
  ),
  TreeStageIds.harvestMaturity: _PeachStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 80, highMin: 90),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 30, highMin: 35),
    ph: PeachTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.7, highMin: 2.3),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 5, optimalMin: 18, optimalMax: 35, highMin: 60),
    pRel: AgroRange(lowMax: 5, optimalMin: 20, optimalMax: 40, highMin: 75),
    kRel: AgroRange(lowMax: 25, optimalMin: 55, optimalMax: 78, highMin: 92),
    nPriority: 0.14,
    pPriority: 0.22,
    kPriority: 0.68,
    wMoisture: 0.22,
    wSoilTemp: 0.14,
    wPh: 0.08,
    wEc: 0.12,
    wResistance: 0.08,
    wN: 0.04,
    wP: 0.04,
    wK: 0.14,
    confidence: 'medium',
    careNoteEs:
        'Madurez/cosecha: calidad final, color, firmeza y azúcares; evitar N tardío.',
    uxGuidanceEs:
        'En madurez/cosecha evita N alto: cerca de cosecha el N retrasa la '
        'madurez, baja color y firmeza. Prioridad: calidad final, firmeza, '
        'ventana de corte y evitar golpe de sol. La ventana de cosecha del '
        'durazno puede ser corta.',
    nWindowEs: 'Madurez: evitar N alto',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Madurez: K útil',
  ),
  TreeStageIds.postHarvest: _PeachStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 80, highMin: 90),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 10, optimalMax: 25, highMin: 30),
    ph: PeachTreeUniversalProfile.phActiveSensitive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.7, highMin: 2.3),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 20, optimalMin: 40, optimalMax: 65, highMin: 82),
    pRel: AgroRange(lowMax: 10, optimalMin: 30, optimalMax: 55, highMin: 85),
    kRel: AgroRange(lowMax: 20, optimalMin: 40, optimalMax: 65, highMin: 88),
    nPriority: 0.52,
    pPriority: 0.34,
    kPriority: 0.58,
    wMoisture: 0.22,
    wSoilTemp: 0.10,
    wPh: 0.10,
    wEc: 0.12,
    wResistance: 0.10,
    wN: 0.12,
    wP: 0.08,
    wK: 0.12,
    confidence: 'medium',
    careNoteEs:
        'Etapa viva: reservas y yemas del siguiente ciclo; solo con hoja activa.',
    uxGuidanceEs:
        'Después de cosecha el duraznero sigue vivo. Si conserva hoja verde '
        'activa y el suelo está estable, puede recuperar reservas y formar las '
        'yemas del siguiente ciclo. La postcosecha NO cierra el cultivo; no '
        'empujes N si ya cayó la hoja o entra a dormancia.',
    nWindowEs: 'Postcosecha: N de reservas (con hoja activa)',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Postcosecha: K de reservas',
  ),
  TreeStageIds.unknown: _PeachStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 58, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 12, optimalMax: 26, highMin: 32),
    ph: PeachTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.6, highMin: 2.2),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 38, optimalMax: 62, highMin: 85),
    pRel: AgroRange(lowMax: 10, optimalMin: 38, optimalMax: 62, highMin: 85),
    kRel: AgroRange(lowMax: 15, optimalMin: 40, optimalMax: 65, highMin: 88),
    nPriority: 0.42,
    pPriority: 0.42,
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
        'precisión, indica si el árbol está brotando, floreando, con frutito, '
        'llenando fruto, en cosecha o postcosecha.',
    nWindowEs: 'Etapa no definida',
    pWindowEs: 'Etapa no definida',
    kWindowEs: 'Etapa no definida',
  ),
};

_PeachStageProfile _profileForStage(String? stageId) {
  final id = normalizeTreeStageId(stageId);
  return _peachStageProfiles[id] ?? _peachStageProfiles[TreeStageIds.unknown]!;
}

/// Targets de sensor por etapa para `resolveTargets` del durazno (doc 05 §10).
///
/// Los `nIndex/pIndex/kIndex` llevan el rango RELATIVO por etapa (0..100). El
/// motor compartido (`NutrientTargetRangeResolver`) los convierte a mg/kg con el
/// cap del cultivo (`NpkCaps`), así las bandas bajo/óptimo/alto-útil/exceso ya
/// quedan suaves sin saltos óptimo→crítico.
StageTargets resolvePeachTreeTargets(String? stageId) {
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
StageWeights resolvePeachTreeStageWeights(String? stageId) {
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
PeachTreeStageNutrition resolvePeachTreeNutritionPriorities(String? stageId) {
  final p = _profileForStage(stageId);
  return PeachTreeStageNutrition(
    stageId: normalizeTreeStageId(stageId),
    nPriority01: p.nPriority,
    pPriority01: p.pPriority,
    kPriority01: p.kPriority,
    confidence: p.confidence,
    careNoteEs: p.careNoteEs,
  );
}

/// Guía UX corta por etapa (doc 05 §9) para tarjetas/resúmenes del durazno.
String peachTreeStageGuidanceEs(String? stageId) =>
    _profileForStage(stageId).uxGuidanceEs;
