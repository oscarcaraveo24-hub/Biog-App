import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Perfil universal agronomico del Pistache (Pistacia vera L.) — arbol
/// caducifolio perenne, DIOICO (macho/hembra) y de NUEZ/semilla comestible.
///
/// Alimentado por el documento oficial
/// `05_Guia_Fertilizacion_NPK_Targets_BioG_Pistache_PS_v1_1` (§9.1 StageTargets,
/// §10 StageWeights, §11 prioridades, §12 lectura por etapa) y
/// `01_Ficha_Tecnica_Universal` (§6, §9, §10).
///
/// Reglas no negociables que respeta este archivo:
/// - NO es una receta de fertilizacion en kg/ha; son prioridades RELATIVAS
///   N-P-K por etapa fisiologica (0..1) + targets de sensor BIO-G v1.
/// - Solo usa metricas compatibles con BIO-G v1: soilMoisture, soilTemp, ph,
///   ec, resistance, n, p, k. B/Zn/Cu/Fe/Ca/Mg/Na/Cl quedan como CONTEXTO de
///   mensaje, nunca como sensores obligatorios (doc 05 §1.2, §2.6, §8.4-§8.7).
/// - Contrato AgroRange v1.5: `lowMax` es frontera critica baja (NO inicio del
///   optimo). En EC/resistance la metrica es de exceso: `lowMax = -0.01` es un
///   placeholder seguro documentado (doc 05 §1.3).
/// - Pistache tolera salinidad mejor que muchos frutales, pero EC alta NO se
///   celebra: sigue bajando confianza NPK y subiendo estres (doc 01 §0.7,
///   doc 05 §0.7, §2.7).
/// - Contrato v1.5: `post_harvest` es etapa ACTIVA (reservas para el siguiente
///   ciclo), NO dormancia; `fruit_fill` NO es `harvest_maturity` (el llenado de
///   kernel/grano NO habla de cosecha ni pistache abierto).
/// - Pistache es de NUEZ: expansion de cascara, endurecimiento de cascara y
///   llenado de kernel son SUBVENTANAS dentro de `fruit_fill`, NO stageIds
///   nuevos (doc 01 §7, doc 05 §1.1). La apertura (hull slip) y la cosecha viven
///   en `harvest_maturity`.
/// - El perfil/variedad PS NO cambia la estructura fenologica ni estos targets
///   base; solo ajusta sensibilidad/mensajes en capas superiores (doc 05 §13).
///
/// Entradas publicas que el resto del proyecto debe usar:
/// - [resolvePistachioTreeTargets]             → StageTargets por etapa.
/// - [resolvePistachioTreeStageWeights]        → StageWeights (AgroScore).
/// - [resolvePistachioTreeNutritionPriorities] → prioridades NPK + nota UX.
class PistachioTreeUniversalProfile {
  const PistachioTreeUniversalProfile._();

  /// pH de etapas activas (doc 05 §9.1, §14): optimo amplio 6.5-7.8; pistache
  /// tolera alcalinidad/caliza, pero `highMin` 8.5 funciona como frontera de
  /// bandera de bloqueo de micronutrientes (Fe/Zn/Cu/P).
  static const AgroRange phActive = AgroRange(
    lowMax: 5.8,
    optimalMin: 6.5,
    optimalMax: 7.8,
    highMin: 8.5,
  );

  /// pH base (dormancia/madurez/postcosecha/unknown): optimo mas amplio 6.5-8.0
  /// porque en reposo/cosecha la disponibilidad fina pesa menos.
  static const AgroRange phBase = AgroRange(
    lowMax: 5.8,
    optimalMin: 6.5,
    optimalMax: 8.0,
    highMin: 8.6,
  );
}

/// Prioridades NPK relativas por etapa + contexto UX corto (doc 05 §11).
///
/// Las prioridades son 0.00 (sin prioridad) a 1.00 (prioridad maxima). NO son
/// dosis: son peso fisiologico para interpretar la lectura del sensor.
class PistachioTreeStageNutrition {
  const PistachioTreeStageNutrition({
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

  /// Nota corta y segura para UX (doc 05 §11 "Nota UX").
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

/// Datos crudos por etapa, transcritos del documento 05 (§9.1, §10 y §11).
///
/// `nRel/pRel/kRel` son los AgroRange RELATIVOS (escala 0..100). El motor
/// compartido los convierte a mg/kg comparables con el cap del cultivo
/// (`NutrientTargetRangeResolver` + `NpkCaps`). Las bandas ya son suaves: no se
/// dejan rangos pegados optimo→critico.
class _PistachioStageProfile {
  const _PistachioStageProfile({
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

const AgroRange _ecLow = AgroRange(
  lowMax: -0.01,
  optimalMin: 0.0,
  optimalMax: 2.0,
  highMin: 3.5,
);
const AgroRange _ecMid = AgroRange(
  lowMax: -0.01,
  optimalMin: 0.0,
  optimalMax: 2.5,
  highMin: 4.5,
);
const AgroRange _ecHigh = AgroRange(
  lowMax: -0.01,
  optimalMin: 0.0,
  optimalMax: 2.8,
  highMin: 4.8,
);
const AgroRange _ecBase = AgroRange(
  lowMax: -0.01,
  optimalMin: 0.0,
  optimalMax: 3.0,
  highMin: 5.0,
);

const Map<String, _PistachioStageProfile>
_pistachioStageProfiles = <String, _PistachioStageProfile>{
  TreeStageIds.plantingTransplant: _PistachioStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 55, optimalMax: 75, highMin: 86),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 26, highMin: 33),
    ph: PistachioTreeUniversalProfile.phActive,
    ec: _ecLow,
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 5, optimalMin: 15, optimalMax: 30, highMin: 70),
    pRel: AgroRange(lowMax: 20, optimalMin: 50, optimalMax: 72, highMin: 90),
    kRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 55, highMin: 85),
    nPriority: 0.18,
    pPriority: 0.78,
    kPriority: 0.45,
    wMoisture: 0.28,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.20,
    wResistance: 0.20,
    wN: 0.03,
    wP: 0.05,
    wK: 0.02,
    confidence: 'medium',
    careNoteEs:
        'Raiz e injerto primero; humedad pareja, baja salinidad, sin '
        'compactacion. No quemar con N.',
    uxGuidanceEs:
        'Tu pistache esta recien plantado. No lo empujes con nitrogeno: primero '
        'que agarre raiz, con humedad pareja, baja salinidad y suelo sin '
        'apretarlo. El fosforo de arranque pesa mas que el N.',
    nWindowEs: 'N bajo: priorizar raiz/injerto',
    pWindowEs: 'Ventana de raiz: P alto',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.rootEstablishment: _PistachioStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 55, optimalMax: 76, highMin: 86),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 28, highMin: 34),
    ph: PistachioTreeUniversalProfile.phActive,
    ec: _ecLow,
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 10, optimalMin: 20, optimalMax: 40, highMin: 75),
    pRel: AgroRange(lowMax: 20, optimalMin: 55, optimalMax: 75, highMin: 90),
    kRel: AgroRange(lowMax: 18, optimalMin: 38, optimalMax: 60, highMin: 85),
    nPriority: 0.25,
    pPriority: 0.80,
    kPriority: 0.50,
    wMoisture: 0.30,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.20,
    wResistance: 0.18,
    wN: 0.03,
    wP: 0.05,
    wK: 0.02,
    confidence: 'medium',
    careNoteEs:
        'Raiz fina, oxigeno y drenaje; en pistache el exceso de agua puede ser '
        'mas peligroso que un deficit leve.',
    uxGuidanceEs:
        'El pistache esta formando raiz. Si el suelo esta duro, salino o '
        'demasiado mojado, no va a aprovechar el NPK aunque el sensor marque '
        'nutrientes. Rootstock y drenaje pesan mas que la dosis.',
    nWindowEs: 'N de apoyo suave',
    pWindowEs: 'Raiz fina: P alto',
    kWindowEs: 'K medio',
  ),
  TreeStageIds.juvenileVegetative: _PistachioStageProfile(
    moisture: AgroRange(lowMax: 38, optimalMin: 50, optimalMax: 78, highMin: 88),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 31, highMin: 38),
    ph: PistachioTreeUniversalProfile.phActive,
    ec: _ecMid,
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.6,
    ),
    nRel: AgroRange(lowMax: 28, optimalMin: 55, optimalMax: 78, highMin: 92),
    pRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 58, highMin: 85),
    kRel: AgroRange(lowMax: 25, optimalMin: 45, optimalMax: 70, highMin: 90),
    nPriority: 0.72,
    pPriority: 0.45,
    kPriority: 0.55,
    wMoisture: 0.22,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.15,
    wResistance: 0.14,
    wN: 0.17,
    wP: 0.05,
    wK: 0.05,
    confidence: 'medium',
    careNoteEs:
        'Crecer parejo y formar estructura; Zn/Cu/B contexto. Sin vigor blando '
        'tardio.',
    uxGuidanceEs:
        'En pistache joven si importa crecer, pero crecer parejo. Mucho N tarde '
        'puede dejar madera blanda y puro follaje. Si ves hoja chica, brote '
        'corto o roseta, revisa zinc y pH antes que mas N.',
    nWindowEs: 'Construccion de arbol: N util controlado',
    pWindowEs: 'P de acompanamiento',
    kWindowEs: 'K medio-alto',
  ),
  TreeStageIds.dormancy: _PistachioStageProfile(
    moisture: AgroRange(lowMax: 25, optimalMin: 35, optimalMax: 65, highMin: 85),
    soilTemp: AgroRange(lowMax: -2, optimalMin: 0, optimalMax: 12, highMin: 22),
    ph: PistachioTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 3.0, highMin: 5.5),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 2.2,
      highMin: 3.0,
    ),
    nRel: AgroRange(lowMax: 0, optimalMin: 5, optimalMax: 18, highMin: 55),
    pRel: AgroRange(lowMax: 0, optimalMin: 5, optimalMax: 20, highMin: 60),
    kRel: AgroRange(lowMax: 0, optimalMin: 5, optimalMax: 20, highMin: 60),
    nPriority: 0.05,
    pPriority: 0.05,
    kPriority: 0.05,
    wMoisture: 0.20,
    wSoilTemp: 0.20,
    wPh: 0.10,
    wEc: 0.18,
    wResistance: 0.10,
    wN: 0.04,
    wP: 0.04,
    wK: 0.04,
    confidence: 'low',
    careNoteEs:
        'Demanda NPK baja; frio efectivo, madera, reservas y planificacion con '
        'analisis.',
    uxGuidanceEs:
        'Dormancia no es arbol muerto. Aqui NPK no manda; manda frio cumplido, '
        'madera sana, suelo y planificacion. El frio invernal es contexto '
        'externo (no sensor v1): no leas la etapa como cultivo apagado.',
    nWindowEs: 'Reposo: demanda baja',
    pWindowEs: 'Reposo: demanda baja',
    kWindowEs: 'Reposo: demanda baja',
  ),
  TreeStageIds.budbreak: _PistachioStageProfile(
    moisture: AgroRange(lowMax: 38, optimalMin: 50, optimalMax: 76, highMin: 88),
    soilTemp: AgroRange(lowMax: 7, optimalMin: 12, optimalMax: 28, highMin: 36),
    ph: PistachioTreeUniversalProfile.phActive,
    ec: _ecMid,
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.6,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 45, optimalMax: 65, highMin: 85),
    pRel: AgroRange(lowMax: 20, optimalMin: 40, optimalMax: 62, highMin: 85),
    kRel: AgroRange(lowMax: 25, optimalMin: 45, optimalMax: 68, highMin: 90),
    nPriority: 0.68,
    pPriority: 0.55,
    kPriority: 0.55,
    wMoisture: 0.20,
    wSoilTemp: 0.16,
    wPh: 0.10,
    wEc: 0.14,
    wResistance: 0.12,
    wN: 0.14,
    wP: 0.08,
    wK: 0.08,
    confidence: 'medium',
    careNoteEs:
        'Arranque desde reservas; N/P moderados, Zn/B/Cu contexto. Antes de '
        'hoja hay poca absorcion real.',
    uxGuidanceEs:
        'El pistache esta arrancando. N ayuda a hoja, P acompana el arranque y '
        'K acompana; pero si falto frio o zinc, no lo arregla solo el '
        'fertilizante. El 50% de expansion foliar es ventana para foliares/'
        'micros, no sensor v1.',
    nWindowEs: 'Arranque: N moderado-alto',
    pWindowEs: 'P suficiente para brotacion',
    kWindowEs: 'K de acompanamiento',
  ),
  TreeStageIds.vegetativeGrowth: _PistachioStageProfile(
    moisture: AgroRange(lowMax: 38, optimalMin: 50, optimalMax: 78, highMin: 88),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 15, optimalMax: 32, highMin: 39),
    ph: PistachioTreeUniversalProfile.phActive,
    ec: _ecHigh,
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.9,
      highMin: 2.7,
    ),
    nRel: AgroRange(lowMax: 35, optimalMin: 55, optimalMax: 75, highMin: 92),
    pRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 55, highMin: 80),
    kRel: AgroRange(lowMax: 35, optimalMin: 55, optimalMax: 75, highMin: 92),
    nPriority: 0.75,
    pPriority: 0.35,
    kPriority: 0.65,
    wMoisture: 0.20,
    wSoilTemp: 0.12,
    wPh: 0.09,
    wEc: 0.14,
    wResistance: 0.10,
    wN: 0.18,
    wP: 0.05,
    wK: 0.12,
    confidence: 'medium',
    careNoteEs:
        'Hoja funcional: la fabrica del pistache. Con poca carga y mucho N se '
        'va a puro follaje y sombra.',
    uxGuidanceEs:
        'El follaje es la fabrica del pistache, pero si hay poca carga y mucho '
        'N, el arbol se puede ir a puro verde. EC alta + N/K altos = sales; pH '
        'alto + hoja chica = Zn/Fe/Cu, no asumas N bajo.',
    nWindowEs: 'Crecimiento: N util controlado',
    pWindowEs: 'P bajo-medio',
    kWindowEs: 'K de acompanamiento',
  ),
  TreeStageIds.flowering: _PistachioStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 55, optimalMax: 78, highMin: 88),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 30, highMin: 37),
    ph: PistachioTreeUniversalProfile.phActive,
    ec: _ecMid,
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.6,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 40, optimalMax: 60, highMin: 85),
    pRel: AgroRange(lowMax: 25, optimalMin: 45, optimalMax: 65, highMin: 88),
    kRel: AgroRange(lowMax: 35, optimalMin: 55, optimalMax: 75, highMin: 92),
    nPriority: 0.45,
    pPriority: 0.60,
    kPriority: 0.65,
    wMoisture: 0.24,
    wSoilTemp: 0.16,
    wPh: 0.08,
    wEc: 0.14,
    wResistance: 0.10,
    wN: 0.10,
    wP: 0.10,
    wK: 0.12,
    confidence: 'high',
    careNoteEs:
        'Floracion macho/hembra: clima, polinizacion y frio mandan. NPK no '
        'reemplaza polen. B contexto.',
    uxGuidanceEs:
        'En floracion no gana el que tiene mas NPK. Gana el que trae frio '
        'cumplido, macho compatible, hembra receptiva, viento y buen clima. El '
        'N alto no compensa falta de macho; la lluvia/humedad/viento/helada '
        'dominan el cuajado.',
    nWindowEs: 'Floracion: no empujar N',
    pWindowEs: 'Floracion: P relevante',
    kWindowEs: 'Floracion: K relevante',
  ),
  TreeStageIds.fruitSet: _PistachioStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 58, optimalMax: 80, highMin: 90),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 32, highMin: 39),
    ph: PistachioTreeUniversalProfile.phActive,
    ec: _ecMid,
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.6,
    ),
    nRel: AgroRange(lowMax: 30, optimalMin: 45, optimalMax: 65, highMin: 88),
    pRel: AgroRange(lowMax: 20, optimalMin: 35, optimalMax: 55, highMin: 80),
    kRel: AgroRange(lowMax: 45, optimalMin: 65, optimalMax: 85, highMin: 96),
    nPriority: 0.55,
    pPriority: 0.45,
    kPriority: 0.78,
    wMoisture: 0.26,
    wSoilTemp: 0.12,
    wPh: 0.08,
    wEc: 0.14,
    wResistance: 0.10,
    wN: 0.10,
    wP: 0.06,
    wK: 0.18,
    confidence: 'high',
    careNoteEs:
        'Amarre/cuajado: agua estable, raiz y K. Si hubo mala polinizacion, no '
        'lo corrige un golpe de fertilizante.',
    uxGuidanceEs:
        'Ya se esta amarrando el pistache. Aqui cuida agua estable, raiz y K; '
        'si hubo mala polinizacion, no lo corrige un golpe de fertilizante. '
        'Humedad baja o alta = caida/estres; EC alta = baja absorcion.',
    nWindowEs: 'Amarre: N moderado',
    pWindowEs: 'P de acompanamiento',
    kWindowEs: 'Amarre: K empieza a pesar',
  ),
  TreeStageIds.fruitFill: _PistachioStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 58, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 34, highMin: 40),
    ph: PistachioTreeUniversalProfile.phActive,
    ec: _ecHigh,
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.9,
      highMin: 2.8,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 40, optimalMax: 60, highMin: 85),
    pRel: AgroRange(lowMax: 10, optimalMin: 25, optimalMax: 45, highMin: 75),
    kRel: AgroRange(lowMax: 55, optimalMin: 72, optimalMax: 92, highMin: 98),
    nPriority: 0.60,
    pPriority: 0.25,
    kPriority: 0.92,
    wMoisture: 0.28,
    wSoilTemp: 0.10,
    wPh: 0.07,
    wEc: 0.17,
    wResistance: 0.08,
    wN: 0.12,
    wP: 0.03,
    wK: 0.25,
    confidence: 'high',
    // CONTRATO v1.5: copy de LLENADO de kernel/grano, nunca de cosecha/apertura.
    careNoteEs:
        'Llenado de kernel: agua estable, hoja sana y K protagonista. N alto '
        'sin carga o con sales no ayuda. Sin copy de cosecha.',
    uxGuidanceEs:
        'Esta es la ventana cara: el pistache se esta llenando por dentro. Agua '
        'estable, hoja sana y potasio pesan mas que empujar nitrogeno. El N '
        'ayuda solo si hay carga y raiz sana; con baja carga se va a puro '
        'follaje. K bajo con agua/EC bien = alerta fuerte; K alto + EC alta no '
        'se celebra. Kernel, split futuro, blanks y cerrados son contexto, no '
        'cosecha.',
    nWindowEs: 'Llenado: N moderado con carga real',
    pWindowEs: 'P bajo-medio',
    kWindowEs: 'Llenado de kernel: K protagonista',
  ),
  TreeStageIds.harvestMaturity: _PistachioStageProfile(
    moisture: AgroRange(lowMax: 38, optimalMin: 50, optimalMax: 75, highMin: 88),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 16, optimalMax: 32, highMin: 40),
    ph: PistachioTreeUniversalProfile.phBase,
    ec: _ecBase,
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 2.0,
      highMin: 2.8,
    ),
    nRel: AgroRange(lowMax: 10, optimalMin: 25, optimalMax: 45, highMin: 75),
    pRel: AgroRange(lowMax: 5, optimalMin: 18, optimalMax: 35, highMin: 65),
    kRel: AgroRange(lowMax: 40, optimalMin: 60, optimalMax: 80, highMin: 95),
    nPriority: 0.25,
    pPriority: 0.12,
    kPriority: 0.72,
    wMoisture: 0.20,
    wSoilTemp: 0.10,
    wPh: 0.08,
    wEc: 0.18,
    wResistance: 0.08,
    wN: 0.06,
    wP: 0.03,
    wK: 0.18,
    confidence: 'medium',
    careNoteEs:
        'Madurez/apertura: calidad final, pistache abierto/cerrado/vano. Evitar '
        'N tardio; vigilar salinidad y NOW/early split.',
    uxGuidanceEs:
        'Ahora si hablamos de pistache abriendo, cerrados, vanos y calidad. No '
        'metas N tarde como si fueras a llenar lo que ya no lleno. Cuida '
        'navel orangeworm, mummies, early split y cosecha a tiempo; EC alta '
        'afecta calidad y no debe empujar fertilizante.',
    nWindowEs: 'Madurez: evitar N alto',
    pWindowEs: 'P bajo',
    kWindowEs: 'Madurez: K util para calidad',
  ),
  TreeStageIds.postHarvest: _PistachioStageProfile(
    moisture: AgroRange(lowMax: 35, optimalMin: 48, optimalMax: 75, highMin: 88),
    soilTemp: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 28, highMin: 36),
    ph: PistachioTreeUniversalProfile.phBase,
    ec: _ecBase,
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 2.0,
      highMin: 2.8,
    ),
    nRel: AgroRange(lowMax: 10, optimalMin: 22, optimalMax: 45, highMin: 70),
    pRel: AgroRange(lowMax: 8, optimalMin: 20, optimalMax: 38, highMin: 65),
    kRel: AgroRange(lowMax: 25, optimalMin: 45, optimalMax: 68, highMin: 90),
    nPriority: 0.35,
    pPriority: 0.20,
    kPriority: 0.55,
    wMoisture: 0.22,
    wSoilTemp: 0.10,
    wPh: 0.10,
    wEc: 0.18,
    wResistance: 0.10,
    wN: 0.09,
    wP: 0.04,
    wK: 0.12,
    confidence: 'medium',
    careNoteEs:
        'Reservas del siguiente ciclo si hay hoja activa; N postcosecha NO es '
        'regla universal. Saneamiento de mummies.',
    uxGuidanceEs:
        'El pistache no termino al cosechar. Si queda hoja activa, el arbol '
        'esta juntando reservas para el siguiente ciclo, pero no todo huerto '
        'necesita N postcosecha. Solo corrige con hoja activa, raiz activa, '
        'agua funcional y EC baja; guarda memoria de estres y saneamiento.',
    nWindowEs: 'Postcosecha: N de reservas (solo con hoja activa)',
    pWindowEs: 'P bajo',
    kWindowEs: 'Postcosecha: K de reservas',
  ),
  TreeStageIds.unknown: _PistachioStageProfile(
    moisture: AgroRange(lowMax: 35, optimalMin: 50, optimalMax: 78, highMin: 90),
    soilTemp: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 30, highMin: 38),
    ph: PistachioTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 2.8, highMin: 5.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 2.0,
      highMin: 2.8,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 30, optimalMax: 60, highMin: 88),
    pRel: AgroRange(lowMax: 10, optimalMin: 25, optimalMax: 55, highMin: 85),
    kRel: AgroRange(lowMax: 20, optimalMin: 40, optimalMax: 75, highMin: 92),
    nPriority: 0.45,
    pPriority: 0.30,
    kPriority: 0.55,
    wMoisture: 0.22,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.16,
    wResistance: 0.12,
    wN: 0.10,
    wP: 0.06,
    wK: 0.12,
    confidence: 'low',
    careNoteEs: 'Conservador; pedir etapa visible.',
    uxGuidanceEs:
        'Puedo leer el suelo, pero para afinar NPK necesito saber que se ve: '
        '¿flor, pistache amarrado, llenandose, abriendo o despues de cosecha? '
        'Mientras tanto BIO-G usa rangos conservadores.',
    nWindowEs: 'Etapa no definida',
    pWindowEs: 'Etapa no definida',
    kWindowEs: 'Etapa no definida',
  ),
};

_PistachioStageProfile _profileForStage(String? stageId) {
  final id = normalizeTreeStageId(stageId);
  return _pistachioStageProfiles[id] ??
      _pistachioStageProfiles[TreeStageIds.unknown]!;
}

/// Targets de sensor por etapa para `resolveTargets` del pistache (doc 05 §9.1).
///
/// Los `nIndex/pIndex/kIndex` llevan el rango RELATIVO por etapa (0..100). El
/// motor compartido (`NutrientTargetRangeResolver`) los convierte a mg/kg con el
/// cap del cultivo (`NpkCaps`), asi las bandas bajo/optimo/alto-util/exceso ya
/// quedan suaves sin saltos optimo→critico.
StageTargets resolvePistachioTreeTargets(String? stageId) {
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

/// Pesos AgroScore por etapa (doc 05 §10). Pesos explicitos por nutriente.
StageWeights resolvePistachioTreeStageWeights(String? stageId) {
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

/// Prioridades NPK relativas + nota UX por etapa (doc 05 §11).
PistachioTreeStageNutrition resolvePistachioTreeNutritionPriorities(
  String? stageId,
) {
  final p = _profileForStage(stageId);
  return PistachioTreeStageNutrition(
    stageId: normalizeTreeStageId(stageId),
    nPriority01: p.nPriority,
    pPriority01: p.pPriority,
    kPriority01: p.kPriority,
    confidence: p.confidence,
    careNoteEs: p.careNoteEs,
  );
}

/// Guia UX corta por etapa (doc 05 §12, §19) para tarjetas/resumenes del pistache.
String pistachioTreeStageGuidanceEs(String? stageId) =>
    _profileForStage(stageId).uxGuidanceEs;
