import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Perfil universal agronomico del Mango / Arbol de mango — arbol perenne
/// tropical/subtropical SIEMPREVERDE, de fruto fresco, con floracion sensible y
/// produccion EPISODICA.
///
/// Alimentado por el documento oficial
/// `05_Guia_Fertilizacion_NPK_Targets_BioG_Mango_MG_v1_1` (§5.2 StageTargets +
/// §0.0.3 ajustes v1.1 que MANDAN sobre el cuerpo base, §6 StageWeights, §7
/// lectura por etapa) y `01_Ficha_Tecnica` (§5, §7, §10).
///
/// Reglas no negociables que respeta este archivo:
/// - NO es una receta de fertilizacion en kg/ha; son prioridades RELATIVAS
///   N-P-K por etapa fisiologica (0..1) + targets de sensor BIO-G v1.
/// - Solo usa metricas compatibles con BIO-G v1: soilMoisture, soilTemp, ph,
///   ec, resistance, n, p, k. Ca/Mg/B/Zn/Fe/Mn/Cu/Cl/Na, inducción floral,
///   antracnosis/cenicilla, mosca de fruta y carga quedan como CONTEXTO de
///   mensaje, nunca como sensores obligatorios (doc 05 §1, §3.8, §3.9).
/// - Contrato AgroRange v1.5: `lowMax` es frontera critica baja (NO inicio del
///   optimo). En EC/resistance la metrica es de exceso: `lowMax = -0.01` es un
///   placeholder seguro documentado (doc 05 §5).
/// - N y K son protagonistas con LÓGICA OPUESTA por etapa (doc 05 §0.0.2, §3.5,
///   §3.7): N manda en juvenil/brote/vegetativo/postcosecha; en reposo/inducción
///   y en llenado/madurez el N ALTO es riesgo (empuja vegetativo, baja calidad).
///   K sube desde floración/cuajado y es MÁXIMO en llenado (calibre/calidad). P
///   pesa en raíz/establecimiento/floración pero NO domina el ciclo adulto.
/// - La salinidad es un BLOQUEO central: EC alta (>=1.8 en reproducción) baja
///   confianza y bloquea recomendaciones agresivas; EC baja no es deficiencia
///   (doc 05 §0.0.2, §3.3, §5).
/// - Contrato v1.5: `dormancy` es reposo funcional / preparación / posible
///   inducción (NO árbol pelón caducifolio); `post_harvest` es etapa ACTIVA que
///   prepara la siguiente floración (NO cierra el cultivo); `fruit_fill` NO es
///   `harvest_maturity` (llenado/calibre, NO cosecha). La NO floración es un
///   estado válido; la inducción NO se convierte en receta (doc 01 §0.4, §0.7).
/// - El mango NO es limón, NO es naranjo y NO es manzano: fisiología propia
///   (doc 04 §0). El perfil/variedad MG NO cambia la estructura fenologica ni
///   estos targets base; solo ajusta sensibilidad/mensajes (doc 05 §8).
///
/// Entradas publicas que el resto del proyecto debe usar:
/// - [resolveMangoTreeTargets]             → StageTargets por etapa.
/// - [resolveMangoTreeStageWeights]        → StageWeights (AgroScore).
/// - [resolveMangoTreeNutritionPriorities] → prioridades NPK + nota UX.
class MangoTreeUniversalProfile {
  const MangoTreeUniversalProfile._();

  /// pH de etapas activas (doc 05 §5.1): óptimo 5.5-7.0. `highMin` 8.0 marca la
  /// frontera de bloqueo de Fe/Zn/Mn/P por alcalinidad/caliza.
  static const AgroRange phActive = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.5,
    optimalMax: 7.0,
    highMin: 8.0,
  );

  /// pH base (juvenil/dormancia/vegetativo/llenado/madurez/postcosecha/unknown):
  /// óptimo un poco más amplio 5.5-7.3 porque en reposo/cosecha la
  /// disponibilidad fina pesa menos.
  static const AgroRange phBase = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.5,
    optimalMax: 7.3,
    highMin: 8.2,
  );
}

/// Prioridades NPK relativas por etapa + contexto UX corto (doc 05 §7).
///
/// Las prioridades son 0.00 (sin prioridad) a 1.00 (prioridad maxima). NO son
/// dosis: son peso fisiologico para interpretar la lectura del sensor.
class MangoTreeStageNutrition {
  const MangoTreeStageNutrition({
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

  /// Nota corta y segura para UX (doc 05 §5.2 "Nota UX").
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

/// Datos crudos por etapa, transcritos del documento 05 (§5.2 base + §0.0.3
/// ajustes v1.1, §6 y §7).
///
/// `nRel/pRel/kRel` son los AgroRange RELATIVOS (escala 0..100). El motor
/// compartido los convierte a mg/kg comparables con el cap del cultivo
/// (`NutrientTargetRangeResolver` + `NpkCaps`, N=115 / P=95 / K=190). Las bandas
/// ya son suaves: no se dejan rangos pegados optimo→critico.
class _MangoStageProfile {
  const _MangoStageProfile({
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

const Map<String, _MangoStageProfile>
_mangoStageProfiles = <String, _MangoStageProfile>{
  TreeStageIds.plantingTransplant: _MangoStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 80, highMin: 88),
    soilTemp: AgroRange(lowMax: 14, optimalMin: 20, optimalMax: 32, highMin: 36),
    ph: MangoTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.1, highMin: 1.7),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.4,
      highMin: 2.0,
    ),
    nRel: AgroRange(lowMax: 12, optimalMin: 25, optimalMax: 45, highMin: 75),
    pRel: AgroRange(lowMax: 22, optimalMin: 50, optimalMax: 75, highMin: 92),
    kRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 88),
    nPriority: 0.35,
    pPriority: 0.70,
    kPriority: 0.40,
    wMoisture: 0.25,
    wSoilTemp: 0.12,
    wPh: 0.11,
    wEc: 0.16,
    wResistance: 0.16,
    wN: 0.06,
    wP: 0.09,
    wK: 0.05,
    confidence: 'medium',
    careNoteEs: 'Raíz nueva; P funcional, humedad pareja, baja EC; sin flor/fruto',
    uxGuidanceEs:
        'El mango acaba de entrar al suelo. Ahorita no se fuerza flor ni fruta: '
        'primero raíz viva, humedad pareja, baja salinidad y buen drenaje. El P '
        'ayuda al arranque, pero si hay sales o compactación el fertilizante no '
        'se aprovecha.',
    nWindowEs: 'N bajo-moderado: priorizar raíz',
    pWindowEs: 'Ventana de raíz: P funcional',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.rootEstablishment: _MangoStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 14, optimalMin: 20, optimalMax: 32, highMin: 36),
    ph: MangoTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.1, highMin: 1.7),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.4,
      highMin: 2.0,
    ),
    nRel: AgroRange(lowMax: 14, optimalMin: 28, optimalMax: 48, highMin: 78),
    pRel: AgroRange(lowMax: 22, optimalMin: 50, optimalMax: 76, highMin: 92),
    kRel: AgroRange(lowMax: 16, optimalMin: 36, optimalMax: 62, highMin: 88),
    nPriority: 0.38,
    pPriority: 0.72,
    kPriority: 0.45,
    wMoisture: 0.26,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.16,
    wResistance: 0.16,
    wN: 0.06,
    wP: 0.09,
    wK: 0.05,
    confidence: 'medium',
    careNoteEs: 'Raíz fina activa; humedad estable y baja EC; no quemar con sales',
    uxGuidanceEs:
        'La raíz está agarrando. Si el suelo está seco, salino o compacto, el '
        'NPK no resuelve la absorción. Primero haz que la raíz pueda respirar y '
        'tomar agua; evita sales y compactación cerca de la zona de raíz.',
    nWindowEs: 'N de apoyo suave',
    pWindowEs: 'Raíz fina: P funcional',
    kWindowEs: 'K medio',
  ),
  TreeStageIds.juvenileVegetative: _MangoStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 58, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 15, optimalMin: 21, optimalMax: 33, highMin: 37),
    ph: MangoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 28, optimalMin: 55, optimalMax: 75, highMin: 92),
    pRel: AgroRange(lowMax: 14, optimalMin: 32, optimalMax: 55, highMin: 82),
    kRel: AgroRange(lowMax: 22, optimalMin: 45, optimalMax: 70, highMin: 90),
    nPriority: 0.78,
    pPriority: 0.45,
    kPriority: 0.52,
    wMoisture: 0.18,
    wSoilTemp: 0.10,
    wPh: 0.09,
    wEc: 0.12,
    wResistance: 0.12,
    wN: 0.18,
    wP: 0.09,
    wK: 0.12,
    confidence: 'medium',
    careNoteEs: 'Construir copa y hoja madura; no exigir floración ni fruto',
    uxGuidanceEs:
        'En mango joven buscas copa, raíz, hoja madura y estructura, no fruta. '
        'El N ayuda a formar el árbol, pero sin quemar raíz ni irse a puro '
        'follaje. No lo castigues por no florear; si hay hoja chica o clorosis '
        'con nervadura verde, revisa Fe/Zn/Mn y pH antes que más N.',
    nWindowEs: 'Construcción de árbol: N moderado-alto',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'K medio',
  ),
  // v1.1 (doc 05 §0.0.3): en reposo/inducción el N ALTO empuja vegetativo y
  // rompe la floración; K/reservas pesan. Nrel 6/12/28/55; Krel 22/45/70/88.
  TreeStageIds.dormancy: _MangoStageProfile(
    moisture: AgroRange(lowMax: 35, optimalMin: 50, optimalMax: 78, highMin: 88),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 28, highMin: 35),
    ph: MangoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 28, highMin: 55),
    pRel: AgroRange(lowMax: 12, optimalMin: 28, optimalMax: 55, highMin: 82),
    kRel: AgroRange(lowMax: 22, optimalMin: 45, optimalMax: 70, highMin: 88),
    nPriority: 0.25,
    pPriority: 0.50,
    kPriority: 0.62,
    wMoisture: 0.17,
    wSoilTemp: 0.20,
    wPh: 0.10,
    wEc: 0.14,
    wResistance: 0.10,
    wN: 0.08,
    wP: 0.09,
    wK: 0.12,
    confidence: 'low',
    // Contrato mango: reposo funcional / preparación / posible inducción, NO
    // árbol pelón. La NO floración es estado válido (doc 01 §0.4, §0.6).
    careNoteEs: 'Reposo funcional / preparación; no empujar N (rompe inducción)',
    uxGuidanceEs:
        'El mango está quieto o preparándose: sigue verde, NO es un árbol '
        'pelón. No lo empujes con N fuerte porque se puede ir a brote y no a '
        'flor. La inducción no se receta: se evalúan clima fresco/seco, hoja '
        'madura y reservas. Si no floreó, puede ser un estado válido, no una '
        'falla de fertilizante.',
    nWindowEs: 'Reposo/inducción: N bajo controlado',
    pWindowEs: 'P funcional de reservas',
    kWindowEs: 'K/reservas de preparación',
  ),
  TreeStageIds.budbreak: _MangoStageProfile(
    moisture: AgroRange(lowMax: 40, optimalMin: 56, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 15, optimalMin: 21, optimalMax: 33, highMin: 37),
    ph: MangoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 50, optimalMax: 70, highMin: 88),
    pRel: AgroRange(lowMax: 14, optimalMin: 30, optimalMax: 55, highMin: 82),
    kRel: AgroRange(lowMax: 20, optimalMin: 42, optimalMax: 66, highMin: 88),
    nPriority: 0.70,
    pPriority: 0.42,
    kPriority: 0.52,
    wMoisture: 0.18,
    wSoilTemp: 0.12,
    wPh: 0.09,
    wEc: 0.12,
    wResistance: 0.10,
    wN: 0.20,
    wP: 0.08,
    wK: 0.11,
    confidence: 'medium',
    careNoteEs: 'Brote/flush: N útil, pero exceso puede desplazar la flor',
    uxGuidanceEs:
        'Hay brote nuevo (cobrizo/rojizo o verde tierno). El N ayuda a la hoja, '
        'pero no confundas brote vegetativo con flor: si el árbol se va a puro '
        'flush puede atrasar o bajar la floración. Vigila trips, ácaros y '
        'plagas de brote antes de culpar al fertilizante.',
    nWindowEs: 'Brotación: N útil pero controlado',
    pWindowEs: 'P de soporte',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.vegetativeGrowth: _MangoStageProfile(
    moisture: AgroRange(lowMax: 40, optimalMin: 56, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 16, optimalMin: 22, optimalMax: 34, highMin: 38),
    ph: MangoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.1),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 26, optimalMin: 52, optimalMax: 72, highMin: 90),
    pRel: AgroRange(lowMax: 12, optimalMin: 28, optimalMax: 52, highMin: 80),
    kRel: AgroRange(lowMax: 22, optimalMin: 45, optimalMax: 68, highMin: 88),
    nPriority: 0.72,
    pPriority: 0.35,
    kPriority: 0.50,
    wMoisture: 0.18,
    wSoilTemp: 0.11,
    wPh: 0.09,
    wEc: 0.12,
    wResistance: 0.10,
    wN: 0.21,
    wP: 0.07,
    wK: 0.12,
    confidence: 'medium',
    careNoteEs: 'Construir hoja funcional sin irse a puro follaje',
    uxGuidanceEs:
        'Que se vea verde no siempre significa que va a producir. Construye hoja '
        'madura, pero si el N está alto y no hay evento floral, el mango puede '
        'estar en modo follaje y competir con la floración. EC alta + N/K altos '
        '= sales; pH alto + hoja chica = Fe/Zn/Mn, no asumas N bajo.',
    nWindowEs: 'Crecimiento: N útil controlado',
    pWindowEs: 'P bajo-medio',
    kWindowEs: 'K de acompañamiento',
  ),
  // v1.1 (doc 05 §0.0.3): floración requiere N moderado, P funcional, K alto y
  // B/Ca contexto. Nrel 10/22/42/66; Prel 18/42/68/88; Krel 34/60/84/96.
  TreeStageIds.flowering: _MangoStageProfile(
    moisture: AgroRange(lowMax: 50, optimalMin: 64, optimalMax: 82, highMin: 88),
    soilTemp: AgroRange(lowMax: 15, optimalMin: 20, optimalMax: 30, highMin: 35),
    ph: MangoTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.1, highMin: 1.8),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 10, optimalMin: 22, optimalMax: 42, highMin: 66),
    pRel: AgroRange(lowMax: 18, optimalMin: 42, optimalMax: 68, highMin: 88),
    kRel: AgroRange(lowMax: 34, optimalMin: 60, optimalMax: 84, highMin: 96),
    nPriority: 0.35,
    pPriority: 0.58,
    kPriority: 0.70,
    wMoisture: 0.22,
    wSoilTemp: 0.18,
    wPh: 0.08,
    wEc: 0.15,
    wResistance: 0.08,
    wN: 0.06,
    wP: 0.10,
    wK: 0.13,
    confidence: 'high',
    careNoteEs: 'Flor no es cosecha: agua/HR/sanidad y K mandan, N pesado no',
    uxGuidanceEs:
        'La flor no se amarra con puro fertilizante. Si hay lluvia, humedad '
        'alta, polvo blanco (cenicilla), panícula negra (antracnosis), calor o '
        'falta de agua, el problema va ANTES que el NPK. El N alto no arregla '
        'una floración estresada y puede irse a follaje; el K y el P deben estar '
        'funcionales, y B/Ca son contexto (no sensor v1).',
    nWindowEs: 'Floración: N moderado, sin exceso',
    pWindowEs: 'Floración: P funcional',
    kWindowEs: 'Floración: K alto',
  ),
  // v1.1 (doc 05 §0.0.3): cuajado frágil; K y agua/EC dominan, N pesado no.
  // Nrel 12/24/45/68; Krel 40/66/88/98.
  TreeStageIds.fruitSet: _MangoStageProfile(
    moisture: AgroRange(lowMax: 52, optimalMin: 65, optimalMax: 84, highMin: 90),
    soilTemp: AgroRange(lowMax: 17, optimalMin: 22, optimalMax: 32, highMin: 36),
    ph: MangoTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.1, highMin: 1.8),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 12, optimalMin: 24, optimalMax: 45, highMin: 68),
    pRel: AgroRange(lowMax: 16, optimalMin: 35, optimalMax: 60, highMin: 82),
    kRel: AgroRange(lowMax: 40, optimalMin: 66, optimalMax: 88, highMin: 98),
    nPriority: 0.38,
    pPriority: 0.45,
    kPriority: 0.82,
    wMoisture: 0.24,
    wSoilTemp: 0.16,
    wPh: 0.08,
    wEc: 0.17,
    wResistance: 0.08,
    wN: 0.06,
    wP: 0.08,
    wK: 0.13,
    confidence: 'high',
    careNoteEs: 'Punto más frágil: K + agua estable + baja EC; N pesado no',
    uxGuidanceEs:
        'El manguito recién amarrado es lo más delicado. El K ayuda, pero el '
        'agua estable y la EC baja pesan más: con falta de agua o sales el mango '
        'tira frutito aunque el NPK esté bien. Algo de caída puede ser normal; '
        'se vuelve alerta si coincide con calor, sales, humedad baja, raíz mala '
        'o sanidad de panícula. B/Ca/Zn son contexto avanzado, no dosis.',
    nWindowEs: 'Cuajado: N moderado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Cuajado: K sube fuerte',
  ),
  // v1.1 (doc 05 §0.0.3): llenado usa K alto; N bajo-moderado para no meter
  // brote ni bajar calidad. Nrel 12/24/48/68; Krel 45/70/92/99.
  TreeStageIds.fruitFill: _MangoStageProfile(
    moisture: AgroRange(lowMax: 50, optimalMin: 64, optimalMax: 85, highMin: 92),
    soilTemp: AgroRange(lowMax: 18, optimalMin: 23, optimalMax: 33, highMin: 38),
    ph: MangoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.2, highMin: 1.9),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 12, optimalMin: 24, optimalMax: 48, highMin: 68),
    pRel: AgroRange(lowMax: 12, optimalMin: 25, optimalMax: 45, highMin: 76),
    kRel: AgroRange(lowMax: 45, optimalMin: 70, optimalMax: 92, highMin: 99),
    nPriority: 0.45,
    pPriority: 0.30,
    kPriority: 0.95,
    wMoisture: 0.24,
    wSoilTemp: 0.12,
    wPh: 0.08,
    wEc: 0.15,
    wResistance: 0.09,
    wN: 0.07,
    wP: 0.04,
    wK: 0.21,
    confidence: 'high',
    // CONTRATO v1.5: copy de LLENADO del mango (calibre/color/calidad), nunca
    // cosecha.
    careNoteEs: 'Calibre y calidad; K/agua mandan, N con cuidado, no cosecha aún',
    uxGuidanceEs:
        'El mango está creciendo y llenando: se juega el calibre, el color y la '
        'calidad. Aquí manda el K con agua estable y hoja funcional. Si el K '
        'sale bajo pero el suelo está seco o salino, primero corrige agua/sales; '
        'si no, el árbol no lo aprovecha. La EC alta castiga calibre y calidad. '
        'Mg/Ca son contexto. Esto es llenado, todavía NO cosecha.',
    nWindowEs: 'Llenado: N bajo-moderado con carga real',
    pWindowEs: 'P bajo',
    kWindowEs: 'Llenado del mango: K protagonista',
  ),
  // v1.1 (doc 05 §0.0.3): no N en maduración de variedades con cambio de color;
  // K sostiene calidad. Nrel 6/14/30/55; Krel 34/58/82/95.
  TreeStageIds.harvestMaturity: _MangoStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 58, optimalMax: 78, highMin: 90),
    soilTemp: AgroRange(lowMax: 18, optimalMin: 22, optimalMax: 32, highMin: 38),
    ph: MangoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 6, optimalMin: 14, optimalMax: 30, highMin: 55),
    pRel: AgroRange(lowMax: 10, optimalMin: 22, optimalMax: 40, highMin: 70),
    kRel: AgroRange(lowMax: 34, optimalMin: 58, optimalMax: 82, highMin: 95),
    nPriority: 0.25,
    pPriority: 0.20,
    kPriority: 0.72,
    wMoisture: 0.18,
    wSoilTemp: 0.10,
    wPh: 0.08,
    wEc: 0.14,
    wResistance: 0.08,
    wN: 0.07,
    wP: 0.04,
    wK: 0.31,
    confidence: 'medium',
    careNoteEs:
        'Corte no es final; N alto tarde baja calidad/poscosecha; K con EC baja',
    uxGuidanceEs:
        'Cerca del corte cuida madurez fisiológica, calibre, firmeza, sanidad y '
        'destino; no decidas la madurez solo por el color externo (Kent/Keitt '
        'pueden verse verdes y estar de corte). No empujes N tarde: en '
        'variedades que cambian de color puede meter brote, bajar firmeza/color '
        'y complicar la poscosecha. El K sostiene calidad, pero no con EC alta.',
    nWindowEs: 'Madurez: evitar N alto tarde',
    pWindowEs: 'P bajo',
    kWindowEs: 'Madurez: K útil para calidad',
  ),
  // v1.1 (doc 05 §0.0.3): ventana fuerte de recuperación/reservas si raíz/EC/
  // agua están bien. Nrel 24/48/70/88; Krel 30/55/80/94.
  TreeStageIds.postHarvest: _MangoStageProfile(
    moisture: AgroRange(lowMax: 40, optimalMin: 56, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 16, optimalMin: 21, optimalMax: 33, highMin: 37),
    ph: MangoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 24, optimalMin: 48, optimalMax: 70, highMin: 88),
    pRel: AgroRange(lowMax: 14, optimalMin: 30, optimalMax: 55, highMin: 80),
    kRel: AgroRange(lowMax: 30, optimalMin: 55, optimalMax: 80, highMin: 94),
    nPriority: 0.72,
    pPriority: 0.38,
    kPriority: 0.65,
    wMoisture: 0.19,
    wSoilTemp: 0.11,
    wPh: 0.09,
    wEc: 0.13,
    wResistance: 0.10,
    wN: 0.16,
    wP: 0.08,
    wK: 0.14,
    confidence: 'medium',
    careNoteEs: 'Recuperar reservas y hoja madura para la siguiente floración',
    uxGuidanceEs:
        'Después de cosechar el mango NO se apaga: aquí se prepara el siguiente '
        'ciclo. Es la ventana MÁS fuerte de recuperación de reservas y hoja '
        'madura. Corrige N/K moderados solo con hoja activa, riego parejo y EC '
        'baja. Si el árbol quedó defoliado, cargó mucho o hubo estrés, registra '
        'memoria: la próxima floración depende de esto.',
    nWindowEs: 'Postcosecha: N de recuperación (con hoja activa)',
    pWindowEs: 'P bajo-medio',
    kWindowEs: 'Postcosecha: K de reservas',
  ),
  TreeStageIds.unknown: _MangoStageProfile(
    moisture: AgroRange(lowMax: 38, optimalMin: 55, optimalMax: 80, highMin: 90),
    soilTemp: AgroRange(lowMax: 14, optimalMin: 20, optimalMax: 32, highMin: 37),
    ph: MangoTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 32, optimalMax: 60, highMin: 85),
    pRel: AgroRange(lowMax: 12, optimalMin: 28, optimalMax: 55, highMin: 82),
    kRel: AgroRange(lowMax: 24, optimalMin: 48, optimalMax: 75, highMin: 92),
    nPriority: 0.45,
    pPriority: 0.38,
    kPriority: 0.58,
    wMoisture: 0.20,
    wSoilTemp: 0.13,
    wPh: 0.09,
    wEc: 0.14,
    wResistance: 0.11,
    wN: 0.11,
    wP: 0.07,
    wK: 0.15,
    confidence: 'low',
    careNoteEs: 'Fallback conservador; pedir etapa visible',
    uxGuidanceEs:
        'Puedo leer el suelo, pero para afinar NPK necesito saber qué se ve: '
        '¿brote nuevo, árbol quieto, panícula/flor, frutito, mango creciendo, '
        'listo para corte o después de cosecha? Sin etapa, el NPK fino tiene '
        'baja confianza y BIO-G usa rangos conservadores.',
    nWindowEs: 'Etapa no definida',
    pWindowEs: 'Etapa no definida',
    kWindowEs: 'Etapa no definida',
  ),
};

_MangoStageProfile _profileForStage(String? stageId) {
  final id = normalizeTreeStageId(stageId);
  return _mangoStageProfiles[id] ?? _mangoStageProfiles[TreeStageIds.unknown]!;
}

/// Targets de sensor por etapa para `resolveTargets` del mango (doc 05 §5.2 +
/// §0.0.3 v1.1).
///
/// Los `nIndex/pIndex/kIndex` llevan el rango RELATIVO por etapa (0..100). El
/// motor compartido (`NutrientTargetRangeResolver`) los convierte a mg/kg con el
/// cap del cultivo (`NpkCaps`, N=115 / P=95 / K=190), asi las bandas bajo/optimo/
/// alto-util/exceso ya quedan suaves sin saltos optimo→critico.
StageTargets resolveMangoTreeTargets(String? stageId) {
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
StageWeights resolveMangoTreeStageWeights(String? stageId) {
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
MangoTreeStageNutrition resolveMangoTreeNutritionPriorities(String? stageId) {
  final p = _profileForStage(stageId);
  return MangoTreeStageNutrition(
    stageId: normalizeTreeStageId(stageId),
    nPriority01: p.nPriority,
    pPriority01: p.pPriority,
    kPriority01: p.kPriority,
    confidence: p.confidence,
    careNoteEs: p.careNoteEs,
  );
}

/// Guia UX corta por etapa (doc 05 §7) para tarjetas/resumenes del mango.
String mangoTreeStageGuidanceEs(String? stageId) =>
    _profileForStage(stageId).uxGuidanceEs;
