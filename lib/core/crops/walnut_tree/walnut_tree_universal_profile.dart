import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Perfil universal agronomico del Nogal pecanero (Carya illinoinensis) — arbol
/// caducifolio perenne de NUEZ.
///
/// Alimentado por el documento oficial
/// `05_Guia_Fertilizacion_NPK_Targets_BioG_Nogal_NG_v1_2` (§10 StageTargets, §11
/// StageWeights, §0.3/§12 reglas por nutriente) y `01_Ficha_Tecnica_Universal`
/// (§6, §9, §16).
///
/// Reglas no negociables que respeta este archivo:
/// - NO es una receta de fertilizacion en kg/ha; son prioridades RELATIVAS
///   N-P-K por etapa fisiologica (0..1) + targets de sensor BIO-G v1.
/// - Solo usa metricas compatibles con BIO-G v1: soilMoisture, soilTemp, ph,
///   ec, resistance, n, p, k. Zn/Fe/Mn/B/Ca/Mg quedan como CONTEXTO de mensaje,
///   nunca como sensores obligatorios (doc 05 §0.3, §3.6). El ZINC es contexto
///   critico del nogal, pero NO se inventa desde NPK.
/// - Contrato AgroRange v1.4/v1.5: `lowMax` es frontera critica baja (NO inicio
///   del optimo); en suelo/ambiente no se deja `lowMax == optimalMin` ni
///   `optimalMax == highMin`. En EC/resistance la metrica es de exceso:
///   `lowMax = -0.01` es un placeholder seguro documentado (doc 05 §10).
/// - Contrato v1.5: `post_harvest` es etapa ACTIVA (reservas para el siguiente
///   ciclo), NO dormancia; `fruit_fill` NO es `harvest_maturity` (el llenado de
///   nuez/almendra NO habla de cosecha ni ruezno abierto).
/// - Nogal es de NUEZ: estado acuoso, endurecimiento de cascara y llenado de
///   almendra son SUBVENTANAS dentro de `fruit_fill`, NO stageIds nuevos (doc 01
///   §7, doc 05 §0.6). La apertura de ruezno y la cosecha viven en
///   `harvest_maturity`.
/// - El perfil/variedad NG NO cambia la estructura fenologica ni estos targets
///   base; solo ajusta sensibilidad/mensajes en capas superiores (doc 05 §17).
///
/// Entradas publicas que el resto del proyecto debe usar:
/// - [resolveWalnutTreeTargets]             → StageTargets por etapa.
/// - [resolveWalnutTreeStageWeights]        → StageWeights (AgroScore) por etapa.
/// - [resolveWalnutTreeNutritionPriorities] → prioridades NPK + nota UX.
class WalnutTreeUniversalProfile {
  const WalnutTreeUniversalProfile._();

  /// pH de etapas activas (doc 05 §10): optimo 6.0-7.2; en el norte arido los
  /// suelos alcalinos/calizos son comunes y bajan disponibilidad de Zn/Fe/Mn,
  /// por eso `highMin` 8.0 funciona como frontera de bandera de micronutrientes.
  static const AgroRange phActive = AgroRange(
    lowMax: 5.2,
    optimalMin: 6.0,
    optimalMax: 7.2,
    highMin: 8.0,
  );

  /// pH base (dormancia/madurez/postcosecha/unknown): optimo mas amplio 6.0-7.5.
  static const AgroRange phBase = AgroRange(
    lowMax: 5.2,
    optimalMin: 6.0,
    optimalMax: 7.5,
    highMin: 8.2,
  );
}

/// Prioridades NPK relativas por etapa + contexto UX corto (doc 05 §10).
///
/// Las prioridades son 0.00 (sin prioridad) a 1.00 (prioridad maxima). NO son
/// dosis: son peso fisiologico para interpretar la lectura del sensor.
class WalnutTreeStageNutrition {
  const WalnutTreeStageNutrition({
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

  /// Nota corta y segura para UX (doc 05 §10 "lectura BIO-G").
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

/// Datos crudos por etapa, transcritos del documento 05 (§10 y §11).
///
/// `nRel/pRel/kRel` son los AgroRange RELATIVOS (escala 0..100; doc 05 §10 esta
/// en 0..1 y se multiplica por 100). El motor compartido los convierte a mg/kg
/// comparables con el cap del cultivo (`NutrientTargetRangeResolver` +
/// `NpkCaps`). Las bandas ya son suaves: no se dejan rangos pegados
/// optimo→critico.
class _WalnutStageProfile {
  const _WalnutStageProfile({
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

const Map<String, _WalnutStageProfile>
_walnutStageProfiles = <String, _WalnutStageProfile>{
  TreeStageIds.plantingTransplant: _WalnutStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 12, optimalMax: 24, highMin: 30),
    ph: WalnutTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.2, highMin: 1.8),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.0,
    ),
    nRel: AgroRange(lowMax: 5, optimalMin: 18, optimalMax: 35, highMin: 70),
    pRel: AgroRange(lowMax: 20, optimalMin: 55, optimalMax: 75, highMin: 92),
    kRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 58, highMin: 85),
    nPriority: 0.18,
    pPriority: 0.78,
    kPriority: 0.48,
    wMoisture: 0.26,
    wSoilTemp: 0.14,
    wPh: 0.12,
    wEc: 0.20,
    wResistance: 0.18,
    wN: 0.03,
    wP: 0.05,
    wK: 0.02,
    confidence: 'medium',
    careNoteEs:
        'Raiz joven, baja salinidad, humedad estable, no quemar raices.',
    uxGuidanceEs:
        'Tu nogal esta recien plantado. La prioridad es raiz, humedad estable, '
        'baja salinidad y suelo sin compactacion. No conviene empujar nitrogeno; '
        'el fosforo de arranque pesa mas que el N.',
    nWindowEs: 'N bajo: priorizar raiz',
    pWindowEs: 'Ventana de raiz: P alto',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.rootEstablishment: _WalnutStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 62, optimalMax: 84, highMin: 92),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 12, optimalMax: 24, highMin: 30),
    ph: WalnutTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.2, highMin: 1.8),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.0,
    ),
    nRel: AgroRange(lowMax: 10, optimalMin: 22, optimalMax: 45, highMin: 75),
    pRel: AgroRange(lowMax: 20, optimalMin: 55, optimalMax: 75, highMin: 92),
    kRel: AgroRange(lowMax: 15, optimalMin: 38, optimalMax: 60, highMin: 85),
    nPriority: 0.25,
    pPriority: 0.80,
    kPriority: 0.52,
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
        'Raiz fina y oxigeno; P de arranque y suelo sin compactacion.',
    uxGuidanceEs:
        'El nogal esta formando raiz fina. El fosforo, el agua estable y la baja '
        'salinidad pesan mas que una lectura alta de N. El nogal necesita raiz '
        'profunda: cuida drenaje, compactacion y sales.',
    nWindowEs: 'N de apoyo',
    pWindowEs: 'Raiz fina: P alto',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.juvenileVegetative: _WalnutStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 58, optimalMax: 85, highMin: 92),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 28, highMin: 34),
    ph: WalnutTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.5, highMin: 2.2),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 55, optimalMax: 75, highMin: 90),
    pRel: AgroRange(lowMax: 18, optimalMin: 40, optimalMax: 62, highMin: 85),
    kRel: AgroRange(lowMax: 20, optimalMin: 42, optimalMax: 65, highMin: 88),
    nPriority: 0.70,
    pPriority: 0.48,
    kPriority: 0.55,
    wMoisture: 0.22,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.12,
    wResistance: 0.14,
    wN: 0.17,
    wP: 0.06,
    wK: 0.07,
    confidence: 'medium',
    careNoteEs:
        'Estructura, copa, raiz, zinc contextual y vigor sin exceso.',
    uxGuidanceEs:
        'El nogal joven necesita crecer y formar estructura. El nitrogeno ayuda, '
        'pero el zinc, el agua y la raiz son igual de importantes en nogal. Si '
        'ves hojas chicas o brotes en roseta, revisa zinc antes que mas N.',
    nWindowEs: 'Construccion de copa: N util controlado',
    pWindowEs: 'P de acompanamiento',
    kWindowEs: 'K de acompanamiento',
  ),
  TreeStageIds.dormancy: _WalnutStageProfile(
    moisture: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 70, highMin: 90),
    soilTemp: AgroRange(lowMax: -5, optimalMin: 0, optimalMax: 12, highMin: 20),
    ph: WalnutTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 2.0, highMin: 3.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 2.0,
      highMin: 2.6,
    ),
    nRel: AgroRange(lowMax: 0, optimalMin: 15, optimalMax: 35, highMin: 80),
    pRel: AgroRange(lowMax: 0, optimalMin: 20, optimalMax: 40, highMin: 85),
    kRel: AgroRange(lowMax: 0, optimalMin: 20, optimalMax: 45, highMin: 88),
    nPriority: 0.08,
    pPriority: 0.18,
    kPriority: 0.20,
    wMoisture: 0.16,
    wSoilTemp: 0.18,
    wPh: 0.12,
    wEc: 0.18,
    wResistance: 0.12,
    wN: 0.04,
    wP: 0.04,
    wK: 0.04,
    confidence: 'low',
    careNoteEs:
        'Demanda NPK baja; frio, salinidad, suelo y memoria como contexto.',
    uxGuidanceEs:
        'El nogal esta en reposo (pelon). La demanda NPK es baja. El frio '
        'invernal es contexto externo (no sensor v1); usa esta etapa para '
        'revisar pH, salinidad, suelo y planear el arranque. No lo leas como '
        'cultivo muerto.',
    nWindowEs: 'Reposo: demanda baja',
    pWindowEs: 'Reposo: demanda baja',
    kWindowEs: 'Reposo: demanda baja',
  ),
  TreeStageIds.budbreak: _WalnutStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 82, highMin: 92),
    soilTemp: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 24, highMin: 30),
    ph: WalnutTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.6, highMin: 2.2),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 50, optimalMax: 70, highMin: 88),
    pRel: AgroRange(lowMax: 18, optimalMin: 40, optimalMax: 62, highMin: 85),
    kRel: AgroRange(lowMax: 20, optimalMin: 42, optimalMax: 62, highMin: 86),
    nPriority: 0.65,
    pPriority: 0.48,
    kPriority: 0.50,
    wMoisture: 0.22,
    wSoilTemp: 0.18,
    wPh: 0.10,
    wEc: 0.12,
    wResistance: 0.10,
    wN: 0.13,
    wP: 0.06,
    wK: 0.07,
    confidence: 'medium',
    careNoteEs:
        'Arranque desde reservas, zinc contextual critico, suelo templado.',
    uxGuidanceEs:
        'El nogal esta brotando. La raiz se activa antes que la yema, asi que el '
        'arranque usa reservas y necesita hoja funcional. En nogal el zinc '
        'contextual es clave en brotacion y el N debe ser moderado; con suelo '
        'frio la absorcion baja.',
    nWindowEs: 'Arranque: N moderado',
    pWindowEs: 'P suficiente para brotacion',
    kWindowEs: 'K de acompanamiento',
  ),
  TreeStageIds.vegetativeGrowth: _WalnutStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 84, highMin: 92),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 30, highMin: 35),
    ph: WalnutTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.7, highMin: 2.4),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 30, optimalMin: 55, optimalMax: 75, highMin: 90),
    pRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 58, highMin: 82),
    kRel: AgroRange(lowMax: 22, optimalMin: 45, optimalMax: 68, highMin: 90),
    nPriority: 0.72,
    pPriority: 0.38,
    kPriority: 0.55,
    wMoisture: 0.20,
    wSoilTemp: 0.12,
    wPh: 0.09,
    wEc: 0.12,
    wResistance: 0.10,
    wN: 0.19,
    wP: 0.05,
    wK: 0.08,
    confidence: 'medium',
    careNoteEs:
        'Hoja funcional, area foliar, reservas y zinc contextual.',
    uxGuidanceEs:
        'Etapa de hoja y brote. El nitrogeno ayuda a formar copa y area foliar, '
        'pero si falta agua o zinc, mas N no resuelve el problema: en nogal el '
        'exceso de N da vigor blando, sombra y mas plaga chupadora sin mas nuez.',
    nWindowEs: 'Crecimiento: N util controlado',
    pWindowEs: 'P de acompanamiento',
    kWindowEs: 'K de acompanamiento',
  ),
  TreeStageIds.flowering: _WalnutStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 85, highMin: 92),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 26, highMin: 32),
    ph: WalnutTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.6, highMin: 2.2),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 55, highMin: 80),
    pRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 65, highMin: 86),
    kRel: AgroRange(lowMax: 25, optimalMin: 50, optimalMax: 70, highMin: 90),
    nPriority: 0.38,
    pPriority: 0.55,
    kPriority: 0.60,
    wMoisture: 0.26,
    wSoilTemp: 0.18,
    wPh: 0.08,
    wEc: 0.14,
    wResistance: 0.08,
    wN: 0.06,
    wP: 0.09,
    wK: 0.11,
    confidence: 'high',
    careNoteEs:
        'Floracion/polinizacion, reservas, clima; no empujar N como solucion.',
    uxGuidanceEs:
        'Floracion masculina (amentos) y femenina del nogal: etapa muy delicada '
        'que no se resuelve con NPK. La helada, el viento, la lluvia y la '
        'sincronia entre flor macho y hembra deciden el amarre. Revisa clima, '
        'polinizador compatible cercano, agua y reservas antes que nutricion.',
    nWindowEs: 'Floracion: no empujar N',
    pWindowEs: 'Floracion: P relevante',
    kWindowEs: 'Floracion: K relevante',
  ),
  TreeStageIds.fruitSet: _WalnutStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 65, optimalMax: 88, highMin: 94),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 14, optimalMax: 28, highMin: 34),
    ph: WalnutTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.7, highMin: 2.4),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 20, optimalMin: 38, optimalMax: 60, highMin: 83),
    pRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 58, highMin: 82),
    kRel: AgroRange(lowMax: 30, optimalMin: 60, optimalMax: 80, highMin: 94),
    nPriority: 0.45,
    pPriority: 0.45,
    kPriority: 0.75,
    wMoisture: 0.30,
    wSoilTemp: 0.14,
    wPh: 0.08,
    wEc: 0.16,
    wResistance: 0.08,
    wN: 0.07,
    wP: 0.06,
    wK: 0.11,
    confidence: 'high',
    careNoteEs:
        'Amarre de nuez, caida, agua estable, salinidad baja, K subiendo.',
    uxGuidanceEs:
        'La nuez esta amarrando. Agua estable, baja salinidad y K suficiente '
        'ayudan a sostener la carga. La caida de nuez recien amarrada puede venir '
        'de polinizacion, reservas, calor o salinidad: no es solo fertilizante.',
    nWindowEs: 'Amarre: N moderado',
    pWindowEs: 'P de acompanamiento',
    kWindowEs: 'Amarre: K empieza a pesar',
  ),
  TreeStageIds.fruitFill: _WalnutStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 68, optimalMax: 90, highMin: 95),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 30, highMin: 35),
    ph: WalnutTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.8, highMin: 2.5),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.9,
      highMin: 2.5,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 80),
    pRel: AgroRange(lowMax: 10, optimalMin: 25, optimalMax: 45, highMin: 75),
    kRel: AgroRange(lowMax: 35, optimalMin: 70, optimalMax: 90, highMin: 96),
    nPriority: 0.42,
    pPriority: 0.30,
    kPriority: 0.92,
    wMoisture: 0.30,
    wSoilTemp: 0.12,
    wPh: 0.07,
    wEc: 0.14,
    wResistance: 0.08,
    wN: 0.07,
    wP: 0.04,
    wK: 0.18,
    confidence: 'high',
    // CONTRATO v1.5: copy de LLENADO de nuez/almendra, nunca de cosecha/ruezno.
    careNoteEs:
        'Llenado de nuez y almendra: K protagonista, agua y EC primero; '
        'estado acuoso, endurecimiento de cascara y llenado de grano como '
        'subventanas. Sin copy de cosecha.',
    uxGuidanceEs:
        'En crecimiento y llenado de nuez (estado acuoso, endurecimiento de '
        'cascara y llenado de almendra) el potasio y el agua mandan. El N debe '
        'ser suficiente, no excesivo: mucho vigor compite con el grano. Revisa '
        'salinidad, carga de nuez y zinc si la hoja esta debil. La nuez se llena '
        'con hoja, agua y reservas.',
    nWindowEs: 'Llenado: N bajo-moderado',
    pWindowEs: 'P de acompanamiento',
    kWindowEs: 'Llenado de almendra: K protagonista',
  ),
  TreeStageIds.harvestMaturity: _WalnutStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 82, highMin: 92),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 30, highMin: 35),
    ph: WalnutTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.8, highMin: 2.7),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.9,
      highMin: 2.5,
    ),
    nRel: AgroRange(lowMax: 5, optimalMin: 20, optimalMax: 45, highMin: 70),
    pRel: AgroRange(lowMax: 5, optimalMin: 20, optimalMax: 40, highMin: 75),
    kRel: AgroRange(lowMax: 25, optimalMin: 55, optimalMax: 78, highMin: 92),
    nPriority: 0.20,
    pPriority: 0.20,
    kPriority: 0.65,
    wMoisture: 0.22,
    wSoilTemp: 0.12,
    wPh: 0.08,
    wEc: 0.14,
    wResistance: 0.08,
    wN: 0.04,
    wP: 0.04,
    wK: 0.16,
    confidence: 'medium',
    careNoteEs:
        'Calidad final, apertura de ruezno, secado; evitar N tardio.',
    uxGuidanceEs:
        'En madurez de nuez y apertura de ruezno cuida la calidad final, el '
        'secado y la recoleccion (vibrado/vareo). Evita empujar brotes con N '
        'tardio: el N tarde retrasa madurez, baja calidad y puede favorecer '
        'pre-germinacion. Vigila sticktights (nuez pegada) y nuez vana.',
    nWindowEs: 'Madurez: evitar N alto',
    pWindowEs: 'P de acompanamiento',
    kWindowEs: 'Madurez: K util',
  ),
  TreeStageIds.postHarvest: _WalnutStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 80, highMin: 92),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 10, optimalMax: 26, highMin: 32),
    ph: WalnutTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.8, highMin: 2.7),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.9,
      highMin: 2.5,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 80),
    pRel: AgroRange(lowMax: 10, optimalMin: 25, optimalMax: 50, highMin: 80),
    kRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 70, highMin: 90),
    nPriority: 0.50,
    pPriority: 0.30,
    kPriority: 0.60,
    wMoisture: 0.24,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.14,
    wResistance: 0.10,
    wN: 0.11,
    wP: 0.05,
    wK: 0.14,
    confidence: 'medium',
    careNoteEs:
        'Reservas del siguiente ciclo; solo si hay hoja activa.',
    uxGuidanceEs:
        'Despues de cosecha el nogal sigue trabajando: la postcosecha NO cierra '
        'el cultivo. Si conserva hoja activa y el suelo esta bien (humedad '
        'estable, EC baja, temperatura suficiente), recupera reservas para la '
        'siguiente brotacion y reduce la alternancia. No empujes N/K si ya cayo '
        'la hoja o entra a dormancia.',
    nWindowEs: 'Postcosecha: N de reservas (con hoja activa)',
    pWindowEs: 'P de acompanamiento',
    kWindowEs: 'Postcosecha: K de reservas',
  ),
  TreeStageIds.unknown: _WalnutStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 85, highMin: 92),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 12, optimalMax: 28, highMin: 34),
    ph: WalnutTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.7, highMin: 2.5),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 38, optimalMax: 62, highMin: 85),
    pRel: AgroRange(lowMax: 10, optimalMin: 35, optimalMax: 60, highMin: 85),
    kRel: AgroRange(lowMax: 15, optimalMin: 40, optimalMax: 68, highMin: 90),
    nPriority: 0.42,
    pPriority: 0.42,
    kPriority: 0.50,
    wMoisture: 0.25,
    wSoilTemp: 0.14,
    wPh: 0.12,
    wEc: 0.15,
    wResistance: 0.12,
    wN: 0.08,
    wP: 0.07,
    wK: 0.07,
    confidence: 'low',
    careNoteEs: 'Conservador; pedir etapa visible.',
    uxGuidanceEs:
        'Con etapa desconocida, BIO-G usa rangos conservadores. Para mayor '
        'precision, indica si el nogal esta pelon, brotando, con flor/amentos, '
        'con nuez chica, llenando almendra, abriendo ruezno o despues de cosecha.',
    nWindowEs: 'Etapa no definida',
    pWindowEs: 'Etapa no definida',
    kWindowEs: 'Etapa no definida',
  ),
};

_WalnutStageProfile _profileForStage(String? stageId) {
  final id = normalizeTreeStageId(stageId);
  return _walnutStageProfiles[id] ?? _walnutStageProfiles[TreeStageIds.unknown]!;
}

/// Targets de sensor por etapa para `resolveTargets` del nogal (doc 05 §10).
///
/// Los `nIndex/pIndex/kIndex` llevan el rango RELATIVO por etapa (0..100). El
/// motor compartido (`NutrientTargetRangeResolver`) los convierte a mg/kg con el
/// cap del cultivo (`NpkCaps`), asi las bandas bajo/optimo/alto-util/exceso ya
/// quedan suaves sin saltos optimo→critico.
StageTargets resolveWalnutTreeTargets(String? stageId) {
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

/// Pesos AgroScore por etapa (doc 05 §11). Pesos explicitos por nutriente.
StageWeights resolveWalnutTreeStageWeights(String? stageId) {
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

/// Prioridades NPK relativas + nota UX por etapa (doc 05 §10).
WalnutTreeStageNutrition resolveWalnutTreeNutritionPriorities(String? stageId) {
  final p = _profileForStage(stageId);
  return WalnutTreeStageNutrition(
    stageId: normalizeTreeStageId(stageId),
    nPriority01: p.nPriority,
    pPriority01: p.pPriority,
    kPriority01: p.kPriority,
    confidence: p.confidence,
    careNoteEs: p.careNoteEs,
  );
}

/// Guia UX corta por etapa (doc 05 §13) para tarjetas/resumenes del nogal.
String walnutTreeStageGuidanceEs(String? stageId) =>
    _profileForStage(stageId).uxGuidanceEs;
