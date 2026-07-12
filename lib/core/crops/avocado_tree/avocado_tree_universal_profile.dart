import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Perfil universal agronomico del Aguacate / Arbol de aguacate — arbol perenne
/// subtropical/tropical SIEMPREVERDE, sin dormancia verdadera, con floracion
/// A/B, cuajado FRAGIL y raiz superficial muy sensible.
///
/// Alimentado por el documento oficial
/// `05_Guia_Fertilizacion_NPK_Targets_BioG_Aguacate_AG_v1_1` (§5 StageTargets +
/// §0.0.3 ajustes v1.1 que MANDAN sobre el cuerpo base, §6 StageWeights, §7
/// prioridades/lectura por etapa, §4 constantes de sensor).
///
/// Reglas no negociables que respeta este archivo:
/// - NO es una receta de fertilizacion en kg/ha; son prioridades RELATIVAS
///   N-P-K por etapa fisiologica (0..1) + targets de sensor BIO-G v1.
/// - Solo usa metricas compatibles con BIO-G v1: soilMoisture, soilTemp, ph,
///   ec, resistance, n, p, k. Ca/Mg/S/B/Zn/Fe/Mn/Cu/Cl/Na, floracion A/B,
///   polinizacion, Phytophthora, materia seca y aceite quedan como CONTEXTO de
///   mensaje, nunca como sensores obligatorios (doc 05 §0.0.6, §2).
/// - Contrato AgroRange v1.5: `lowMax` es frontera critica baja (NO inicio del
///   optimo). En EC/resistance la metrica es de exceso: `lowMax = -0.01` es un
///   placeholder seguro documentado (doc 05 §3.2).
/// - Logica NPK propia del aguacate (doc 05 §0.1, §5.1, §7): N manda en
///   juvenil/brote/vegetativo/postcosecha; en reposo/induccion y cerca del
///   corte el N ALTO es riesgo (empuja vegetativo, compite con flor/fruto, baja
///   calidad). K sube desde floracion/cuajado y es MAXIMO en llenado
///   (calibre/calidad). En floracion K NO domina al maximo: primero cuaja
///   (§0.0.1 pt4). P pesa en raiz/establecimiento/floracion pero NO domina el
///   ciclo adulto.
/// - La raiz manda: la salinidad es un BLOQUEO central. EC alta (>=1.8 en
///   reproduccion, >=2.0 en el resto) baja confianza y bloquea recomendaciones
///   agresivas; EC baja NO es deficiencia (doc 05 §0.3, §4.2). El aguacate es
///   MAS sensible a sales/anoxia que mango o citricos (doc 05 §0.1).
/// - Contrato v1.5: `dormancy` es reposo funcional / preparacion / posible
///   induccion floral (NO arbol pelon caducifolio; el aguacate es
///   siempreverde); `post_harvest` es etapa ACTIVA que prepara reservas y la
///   siguiente floracion (NO cierra el cultivo); `fruit_fill` NO es
///   `harvest_maturity` (llenado/calibre, NO cosecha); el fruto madura para
///   consumo DESPUES del corte, no en el arbol (doc 01 §0.4, §0.6, §7).
/// - El aguacate NO es mango, NO es citrico y NO es manzano: fisiologia propia
///   (doc 01 §0.1, §3.1). El perfil/variedad AG NO cambia la estructura
///   fenologica ni estos targets base; solo ajusta sensibilidad/mensajes.
///
/// Entradas publicas que el resto del proyecto debe usar:
/// - [resolveAvocadoTreeTargets]             → StageTargets por etapa.
/// - [resolveAvocadoTreeStageWeights]        → StageWeights (AgroScore).
/// - [resolveAvocadoTreeNutritionPriorities] → prioridades NPK + nota UX.
class AvocadoTreeUniversalProfile {
  const AvocadoTreeUniversalProfile._();

  /// pH de etapas activas (doc 05 §4.1, §5): optimo 5.6-6.8. `highMin` 7.6 marca
  /// la frontera de bloqueo de Fe/Zn/Mn/P/B por alcalinidad/caliza.
  static const AgroRange phActive = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.6,
    optimalMax: 6.8,
    highMin: 7.6,
  );

  /// pH base (planting/juvenil/dormancia/brote/vegetativo/madurez/postcosecha/
  /// unknown): optimo un poco mas amplio 5.5-7.0 porque en reposo/cosecha la
  /// disponibilidad fina pesa menos.
  static const AgroRange phBase = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.5,
    optimalMax: 7.0,
    highMin: 7.8,
  );
}

/// Prioridades NPK relativas por etapa + contexto UX corto (doc 05 §7).
///
/// Las prioridades son 0.00 (sin prioridad) a 1.00 (prioridad maxima). NO son
/// dosis: son peso fisiologico para interpretar la lectura del sensor.
class AvocadoTreeStageNutrition {
  const AvocadoTreeStageNutrition({
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

  /// Nota corta y segura para UX (doc 05 §7.1).
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

/// Datos crudos por etapa, transcritos del documento 05 (§5 base + §0.0.3
/// ajustes v1.1, §6 y §7).
///
/// `nRel/pRel/kRel` son los AgroRange RELATIVOS (escala 0..100). El motor
/// compartido los convierte a mg/kg comparables con el cap del cultivo
/// (`NutrientTargetRangeResolver` + `NpkCaps`, N=120 / P=95 / K=200). Las bandas
/// ya son suaves: no se dejan rangos pegados optimo→critico.
class _AvocadoStageProfile {
  const _AvocadoStageProfile({
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

const Map<String, _AvocadoStageProfile>
_avocadoStageProfiles = <String, _AvocadoStageProfile>{
  TreeStageIds.plantingTransplant: _AvocadoStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 78, highMin: 86),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 28, highMin: 34),
    ph: AvocadoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 0.8, highMin: 1.4),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.4,
      highMin: 2.0,
    ),
    nRel: AgroRange(lowMax: 6, optimalMin: 16, optimalMax: 32, highMin: 60),
    pRel: AgroRange(lowMax: 18, optimalMin: 48, optimalMax: 72, highMin: 90),
    kRel: AgroRange(lowMax: 12, optimalMin: 30, optimalMax: 55, highMin: 82),
    nPriority: 0.25,
    pPriority: 0.75,
    kPriority: 0.35,
    wMoisture: 0.25,
    wSoilTemp: 0.12,
    wPh: 0.12,
    wEc: 0.18,
    wResistance: 0.18,
    wN: 0.04,
    wP: 0.08,
    wK: 0.03,
    confidence: 'medium',
    careNoteEs:
        'Raíz nueva y cepellón: P funcional, humedad pareja, baja EC; sin flor/fruto',
    uxGuidanceEs:
        'El aguacate acaba de entrar al suelo. No se fuerza flor ni fruta: '
        'primero cuello no enterrado, raíz viva, humedad SIN saturar, baja '
        'salinidad y buen drenaje. El P ayuda al arranque, pero si hay sales o '
        'suelo saturado puedes quemar la raíz fina; N bajo.',
    nWindowEs: 'N bajo: no quemar raíz nueva',
    pWindowEs: 'Ventana de raíz: P funcional',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.rootEstablishment: _AvocadoStageProfile(
    moisture: AgroRange(lowMax: 48, optimalMin: 62, optimalMax: 80, highMin: 87),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 28, highMin: 34),
    ph: AvocadoTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 0.8, highMin: 1.4),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.4,
      highMin: 2.0,
    ),
    nRel: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 38, highMin: 65),
    pRel: AgroRange(lowMax: 20, optimalMin: 52, optimalMax: 75, highMin: 90),
    kRel: AgroRange(lowMax: 14, optimalMin: 35, optimalMax: 58, highMin: 84),
    nPriority: 0.30,
    pPriority: 0.78,
    kPriority: 0.40,
    wMoisture: 0.26,
    wSoilTemp: 0.12,
    wPh: 0.12,
    wEc: 0.18,
    wResistance: 0.18,
    wN: 0.04,
    wP: 0.07,
    wK: 0.03,
    confidence: 'medium',
    careNoteEs:
        'Etapa más delicada: raíz fina y oxígeno; árbol triste con suelo mojado = raíz, no N',
    uxGuidanceEs:
        'La raíz fina del aguacate está agarrando: es la etapa más sensible a '
        'asfixia, Phytophthora, sales y mala agua. Un árbol triste con suelo '
        'MOJADO no pide más agua ni fertilizante: puede ser raíz sin oxígeno. '
        'Primero drenaje, humedad estable y baja EC; el P apoya la raíz.',
    nWindowEs: 'N de apoyo suave',
    pWindowEs: 'Raíz fina: P funcional',
    kWindowEs: 'K medio',
  ),
  TreeStageIds.juvenileVegetative: _AvocadoStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 58, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 30, highMin: 35),
    ph: AvocadoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.0, highMin: 1.6),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.1,
    ),
    nRel: AgroRange(lowMax: 18, optimalMin: 38, optimalMax: 65, highMin: 85),
    pRel: AgroRange(lowMax: 16, optimalMin: 40, optimalMax: 65, highMin: 88),
    kRel: AgroRange(lowMax: 16, optimalMin: 38, optimalMax: 62, highMin: 86),
    nPriority: 0.70,
    pPriority: 0.45,
    kPriority: 0.50,
    wMoisture: 0.20,
    wSoilTemp: 0.10,
    wPh: 0.12,
    wEc: 0.14,
    wResistance: 0.14,
    wN: 0.14,
    wP: 0.08,
    wK: 0.08,
    confidence: 'medium',
    careNoteEs: 'Formar copa, raíz fina y hoja; no exigir floración ni fruto',
    uxGuidanceEs:
        'En aguacate joven buscas copa, raíz fina y hoja funcional, no fruta. '
        'El N ayuda a formar el árbol, pero sin sales ni saturación. No lo '
        'castigues por no florear ni le cargues fruta si aún no tiene '
        'estructura. Con hoja amarilla y pH alto, revisa Fe/Zn/Mn antes que N.',
    nWindowEs: 'Construcción de árbol: N moderado-alto',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'K medio',
  ),
  // v1.1 (doc 05 §0.0.3): en reposo/inducción el N ALTO empuja vegetativo y
  // puede romper la floración; K/reservas pesan. Nrel base 5/12/28/55.
  TreeStageIds.dormancy: _AvocadoStageProfile(
    moisture: AgroRange(lowMax: 35, optimalMin: 50, optimalMax: 72, highMin: 84),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 32),
    ph: AvocadoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 0.9, highMin: 1.5),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 5, optimalMin: 12, optimalMax: 28, highMin: 55),
    pRel: AgroRange(lowMax: 14, optimalMin: 35, optimalMax: 58, highMin: 82),
    kRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 68, highMin: 88),
    nPriority: 0.20,
    pPriority: 0.45,
    kPriority: 0.60,
    wMoisture: 0.18,
    wSoilTemp: 0.10,
    wPh: 0.12,
    wEc: 0.16,
    wResistance: 0.12,
    wN: 0.08,
    wP: 0.10,
    wK: 0.14,
    confidence: 'low',
    // Contrato aguacate: reposo funcional / preparación / posible inducción, NO
    // árbol pelón (el aguacate es siempreverde; doc 01 §0.6).
    careNoteEs:
        'Reposo funcional / preparación floral; no empujar N (puede irse a brote)',
    uxGuidanceEs:
        'El aguacate está quieto o preparándose: sigue verde, NO es un árbol '
        'pelón. Si buscas flor, no lo empujes con N fuerte porque se puede ir a '
        'brote vegetativo. Cuida hoja madura, reservas, raíz y baja salinidad; '
        'no lo sobrerriegues. La inducción no se receta ni se fuerza con estrés.',
    nWindowEs: 'Reposo/inducción: N bajo controlado',
    pWindowEs: 'P funcional de reservas',
    kWindowEs: 'K/reservas de preparación',
  ),
  // v1.1 (doc 05 §0.0.3): budbreak prepara flor; P energía, K aún no máximo.
  // Prel 18/44/70/88; Krel 18/40/64/86. N desde base 16/34/58/80.
  TreeStageIds.budbreak: _AvocadoStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 58, optimalMax: 78, highMin: 86),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 30, highMin: 35),
    ph: AvocadoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 0.9, highMin: 1.5),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.1,
    ),
    nRel: AgroRange(lowMax: 16, optimalMin: 34, optimalMax: 58, highMin: 80),
    pRel: AgroRange(lowMax: 18, optimalMin: 44, optimalMax: 70, highMin: 88),
    kRel: AgroRange(lowMax: 18, optimalMin: 40, optimalMax: 64, highMin: 86),
    nPriority: 0.65,
    pPriority: 0.50,
    kPriority: 0.55,
    wMoisture: 0.20,
    wSoilTemp: 0.10,
    wPh: 0.12,
    wEc: 0.15,
    wResistance: 0.12,
    wN: 0.14,
    wP: 0.08,
    wK: 0.09,
    confidence: 'medium',
    careNoteEs:
        'Brote/yema: distinguir brote vegetativo de flor; vigilar trips/ácaros',
    uxGuidanceEs:
        'Hay yemas hinchadas o brote nuevo (rojizo/cobrizo). No confundas brote '
        'vegetativo con yema floral: si el árbol se va a puro flush puede bajar '
        'la floración. El P ayuda a preparar flor; vigila trips, ácaros y no '
        'sobrerriegues. Aún no es la etapa de K máximo.',
    nWindowEs: 'Brotación: N útil pero controlado',
    pWindowEs: 'Prefloración: P de energía',
    kWindowEs: 'K de acompañamiento',
  ),
  // v1.1 (doc 05 §0.0.3): recuperar hoja/brote sin perder balance; K no se
  // apaga. Nrel 20/42/66/84; Prel 15/36/60/84; Krel 22/48/72/92.
  TreeStageIds.vegetativeGrowth: _AvocadoStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 58, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 30, highMin: 35),
    ph: AvocadoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.0, highMin: 1.6),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.1,
    ),
    nRel: AgroRange(lowMax: 20, optimalMin: 42, optimalMax: 66, highMin: 84),
    pRel: AgroRange(lowMax: 15, optimalMin: 36, optimalMax: 60, highMin: 84),
    kRel: AgroRange(lowMax: 22, optimalMin: 48, optimalMax: 72, highMin: 92),
    nPriority: 0.78,
    pPriority: 0.35,
    kPriority: 0.55,
    wMoisture: 0.20,
    wSoilTemp: 0.10,
    wPh: 0.12,
    wEc: 0.14,
    wResistance: 0.12,
    wN: 0.16,
    wP: 0.06,
    wK: 0.10,
    confidence: 'medium',
    careNoteEs: 'Construir hoja funcional sin exceso de vigor que compita con flor',
    uxGuidanceEs:
        'Que se vea verde no siempre significa que va a producir. Construye hoja '
        'funcional (la fábrica de reservas), pero si el N está alto y no hay '
        'evento floral, el exceso vegetativo compite con flor/fruto. EC alta + '
        'N/K altos = sales; pH alto + hoja chica = Fe/Zn/Mn, no asumas N bajo.',
    nWindowEs: 'Crecimiento: N útil controlado',
    pWindowEs: 'P bajo-medio',
    kWindowEs: 'K de acompañamiento',
  ),
  // v1.1 (doc 05 §0.0.3): floración necesita energía y micros; N/K NO deben
  // dominar sobre agua, polinización, Ca/B/Zn y clima. Nrel 8/20/38/62;
  // Prel 20/45/68/88; Krel 24/45/68/88 (K aún no al máximo: primero cuaja).
  TreeStageIds.flowering: _AvocadoStageProfile(
    moisture: AgroRange(lowMax: 50, optimalMin: 62, optimalMax: 78, highMin: 86),
    soilTemp: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 28, highMin: 33),
    ph: AvocadoTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 0.9, highMin: 1.5),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.4,
      highMin: 2.0,
    ),
    nRel: AgroRange(lowMax: 8, optimalMin: 20, optimalMax: 38, highMin: 62),
    pRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 68, highMin: 88),
    kRel: AgroRange(lowMax: 24, optimalMin: 45, optimalMax: 68, highMin: 88),
    nPriority: 0.40,
    pPriority: 0.65,
    kPriority: 0.75,
    wMoisture: 0.24,
    wSoilTemp: 0.14,
    wPh: 0.10,
    wEc: 0.14,
    wResistance: 0.10,
    wN: 0.07,
    wP: 0.08,
    wK: 0.13,
    confidence: 'high',
    careNoteEs:
        'Etapa crítica: agua/clima/polinización mandan; K aún no al máximo (primero cuaja)',
    uxGuidanceEs:
        'En aguacate mucha flor NO es cosecha: menos de una fracción pequeña '
        'llega a fruto. Aquí mandan agua pareja, temperatura, viento, HR, '
        'polinizadores (tipo A/B) y raíz, ANTES que el NPK. El P y el K deben '
        'estar funcionales, pero no empujes K al máximo como si ya estuviera '
        'llenando fruta: primero hay que cuajar. Ca/B/Zn son contexto, no sensor.',
    nWindowEs: 'Floración: N moderado, sin exceso',
    pWindowEs: 'Floración: P funcional',
    kWindowEs: 'Floración: K moderado (no máximo)',
  ),
  // v1.1 (doc 05 §0.0.3): amarre temprano: K sube, pero Ca/B/Zn/agua/EC mandan;
  // evitar empujar N amoniacal. Nrel 10/22/42/65; Prel 16/36/58/82;
  // Krel 32/56/80/94.
  TreeStageIds.fruitSet: _AvocadoStageProfile(
    moisture: AgroRange(lowMax: 52, optimalMin: 64, optimalMax: 80, highMin: 88),
    soilTemp: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 28, highMin: 33),
    ph: AvocadoTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 0.9, highMin: 1.5),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.4,
      highMin: 2.0,
    ),
    nRel: AgroRange(lowMax: 10, optimalMin: 22, optimalMax: 42, highMin: 65),
    pRel: AgroRange(lowMax: 16, optimalMin: 36, optimalMax: 58, highMin: 82),
    kRel: AgroRange(lowMax: 32, optimalMin: 56, optimalMax: 80, highMin: 94),
    nPriority: 0.42,
    pPriority: 0.50,
    kPriority: 0.88,
    wMoisture: 0.26,
    wSoilTemp: 0.13,
    wPh: 0.10,
    wEc: 0.15,
    wResistance: 0.10,
    wN: 0.06,
    wP: 0.06,
    wK: 0.14,
    confidence: 'high',
    careNoteEs:
        'Punto más frágil: agua estable + baja EC + raíz oxigenada; Ca/B/Zn contexto',
    uxGuidanceEs:
        'El aguacatito recién amarrado es lo más delicado. El K sube, pero el '
        'agua estable, la baja EC y la raíz oxigenada pesan más: con falta de '
        'agua, calor, sales o raíz mala el árbol tira frutito aunque el NPK esté '
        'bien. Algo de caída es fisiológica; es alerta si es masiva o coincide '
        'con estrés. Ca/B/Zn importan como contexto; evita N amoniacal fuerte.',
    nWindowEs: 'Cuajado: N moderado-bajo',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Cuajado: K sube fuerte',
  ),
  // v1.1 (doc 05 §0.0.3): llenado/calibre/materia seca: K MÁXIMO funcional si EC
  // baja y agua estable. Nrel 14/28/50/70; Prel 10/28/50/76; Krel 45/70/94/99.
  TreeStageIds.fruitFill: _AvocadoStageProfile(
    moisture: AgroRange(lowMax: 50, optimalMin: 65, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 30, highMin: 34),
    ph: AvocadoTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.0, highMin: 1.6),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.1,
    ),
    nRel: AgroRange(lowMax: 14, optimalMin: 28, optimalMax: 50, highMin: 70),
    pRel: AgroRange(lowMax: 10, optimalMin: 28, optimalMax: 50, highMin: 76),
    kRel: AgroRange(lowMax: 45, optimalMin: 70, optimalMax: 94, highMin: 99),
    nPriority: 0.48,
    pPriority: 0.32,
    kPriority: 0.95,
    wMoisture: 0.24,
    wSoilTemp: 0.10,
    wPh: 0.10,
    wEc: 0.14,
    wResistance: 0.10,
    wN: 0.08,
    wP: 0.04,
    wK: 0.20,
    confidence: 'high',
    // CONTRATO v1.5: copy de LLENADO del aguacate (calibre/calidad), NUNCA
    // cosecha ni madurez de consumo.
    careNoteEs:
        'Llenado/calibre: K máximo con agua estable y baja EC; N con cuidado; no cosecha aún',
    uxGuidanceEs:
        'El aguacate está creciendo y llenando: se juega el calibre, la materia '
        'seca y la calidad. Aquí manda el K con agua estable, hoja funcional y '
        'baja salinidad. Si el K sale bajo pero el suelo está seco o salino, '
        'primero corrige agua/sales; el árbol no toma el K con la raíz '
        'estresada. Mg/Ca son contexto. Esto es llenado, todavía NO cosecha.',
    nWindowEs: 'Llenado: N bajo-moderado con carga real',
    pWindowEs: 'P bajo',
    kWindowEs: 'Llenado del aguacate: K protagonista',
  ),
  // v1.1 (doc 05 §0.0.3): precosecha: K/calidad; N alto tarde baja confianza por
  // brote/calidad/poscosecha. Nrel 6/16/34/58; Prel 8/24/45/74; Krel 36/60/84/96.
  TreeStageIds.harvestMaturity: _AvocadoStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 58, optimalMax: 78, highMin: 88),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 30, highMin: 35),
    ph: AvocadoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.0, highMin: 1.7),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 6, optimalMin: 16, optimalMax: 34, highMin: 58),
    pRel: AgroRange(lowMax: 8, optimalMin: 24, optimalMax: 45, highMin: 74),
    kRel: AgroRange(lowMax: 36, optimalMin: 60, optimalMax: 84, highMin: 96),
    nPriority: 0.25,
    pPriority: 0.20,
    kPriority: 0.78,
    wMoisture: 0.18,
    wSoilTemp: 0.08,
    wPh: 0.10,
    wEc: 0.14,
    wResistance: 0.10,
    wN: 0.06,
    wP: 0.04,
    wK: 0.18,
    confidence: 'medium',
    careNoteEs:
        'Corte por madurez fisiológica (no color); N tardío baja calidad/poscosecha; K con EC baja',
    uxGuidanceEs:
        'Cerca del corte cuida madurez fisiológica, materia seca/aceite, calibre '
        'y sanidad; el aguacate se corta fisiológicamente maduro y madura para '
        'comer DESPUÉS del corte, no se ablanda en el árbol. No decidas por el '
        'color externo (Hass verde/negro varía). No empujes N tarde: mete brote '
        'y complica poscosecha. El K sostiene calidad, pero no con EC alta. El '
        'fruto puede colgar mientras hay nueva floración: no cierres el cultivo.',
    nWindowEs: 'Madurez: evitar N alto tarde',
    pWindowEs: 'P bajo',
    kWindowEs: 'Madurez: K útil para calidad',
  ),
  // v1.1 (doc 05 §0.0.3): recuperación: reponer reservas y raíz si NO hay EC
  // alta, anoxia ni raíz dañada. Nrel 24/50/74/92; Prel 18/42/66/88;
  // Krel 32/56/82/94.
  TreeStageIds.postHarvest: _AvocadoStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 58, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 30, highMin: 35),
    ph: AvocadoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.0, highMin: 1.7),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.1,
    ),
    nRel: AgroRange(lowMax: 24, optimalMin: 50, optimalMax: 74, highMin: 92),
    pRel: AgroRange(lowMax: 18, optimalMin: 42, optimalMax: 66, highMin: 88),
    kRel: AgroRange(lowMax: 32, optimalMin: 56, optimalMax: 82, highMin: 94),
    nPriority: 0.80,
    pPriority: 0.45,
    kPriority: 0.70,
    wMoisture: 0.22,
    wSoilTemp: 0.10,
    wPh: 0.12,
    wEc: 0.15,
    wResistance: 0.12,
    wN: 0.13,
    wP: 0.06,
    wK: 0.10,
    confidence: 'medium',
    careNoteEs:
        'Postcosecha viva: recuperar hoja/raíz/reservas para la siguiente floración',
    uxGuidanceEs:
        'Después de cosechar el aguacate NO se apaga: la postcosecha es una '
        'ventana VIVA que prepara la siguiente floración. Recupera hoja, raíz y '
        'reservas: aporta N/K moderados solo si la hoja sigue activa, el riego '
        'es parejo y la EC baja. Con hoja caída, raíz dañada, sales altas o '
        'suelo saturado, mejor no fertilizar. Si cargó mucho, registra memoria: '
        'el próximo ciclo puede venir bajo (alternancia).',
    nWindowEs: 'Postcosecha: N de recuperación (con hoja activa)',
    pWindowEs: 'P bajo-medio',
    kWindowEs: 'Postcosecha: K de reservas',
  ),
  TreeStageIds.unknown: _AvocadoStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 58, optimalMax: 80, highMin: 88),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 17, optimalMax: 29, highMin: 35),
    ph: AvocadoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.0, highMin: 1.6),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.1,
    ),
    nRel: AgroRange(lowMax: 10, optimalMin: 25, optimalMax: 50, highMin: 75),
    pRel: AgroRange(lowMax: 12, optimalMin: 32, optimalMax: 58, highMin: 82),
    kRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 70, highMin: 90),
    nPriority: 0.45,
    pPriority: 0.40,
    kPriority: 0.60,
    wMoisture: 0.22,
    wSoilTemp: 0.10,
    wPh: 0.12,
    wEc: 0.16,
    wResistance: 0.14,
    wN: 0.08,
    wP: 0.06,
    wK: 0.10,
    confidence: 'low',
    careNoteEs: 'Fallback conservador; pedir etapa visible',
    uxGuidanceEs:
        'Puedo leer el suelo, pero para afinar NPK necesito saber qué se ve: '
        '¿recién plantado, brote nuevo, árbol quieto, con flor, con frutito, '
        'aguacate creciendo, listo para corte o después de cosecha? Sin etapa, '
        'el NPK fino tiene baja confianza y BIO-G usa rangos conservadores.',
    nWindowEs: 'Etapa no definida',
    pWindowEs: 'Etapa no definida',
    kWindowEs: 'Etapa no definida',
  ),
};

_AvocadoStageProfile _profileForStage(String? stageId) {
  final id = normalizeTreeStageId(stageId);
  return _avocadoStageProfiles[id] ??
      _avocadoStageProfiles[TreeStageIds.unknown]!;
}

/// Targets de sensor por etapa para `resolveTargets` del aguacate (doc 05 §5 +
/// §0.0.3 v1.1).
///
/// Los `nIndex/pIndex/kIndex` llevan el rango RELATIVO por etapa (0..100). El
/// motor compartido (`NutrientTargetRangeResolver`) los convierte a mg/kg con el
/// cap del cultivo (`NpkCaps`, N=120 / P=95 / K=200).
StageTargets resolveAvocadoTreeTargets(String? stageId) {
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

/// Pesos AgroScore por etapa (doc 05 §6). Pesos explicitos por nutriente.
StageWeights resolveAvocadoTreeStageWeights(String? stageId) {
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

/// Prioridades NPK relativas + nota UX por etapa (doc 05 §7).
AvocadoTreeStageNutrition resolveAvocadoTreeNutritionPriorities(String? stageId) {
  final p = _profileForStage(stageId);
  return AvocadoTreeStageNutrition(
    stageId: normalizeTreeStageId(stageId),
    nPriority01: p.nPriority,
    pPriority01: p.pPriority,
    kPriority01: p.kPriority,
    confidence: p.confidence,
    careNoteEs: p.careNoteEs,
  );
}

/// Guia UX corta por etapa (doc 05 §7) para tarjetas/resumenes del aguacate.
String avocadoTreeStageGuidanceEs(String? stageId) =>
    _profileForStage(stageId).uxGuidanceEs;
