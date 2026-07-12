import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Perfil universal agronomico del Limón / Limonero — arbol perenne
/// SIEMPREVERDE, cítrico, de fruto fresco (verde o amarillo segun perfil).
///
/// Alimentado por el documento oficial
/// `05_Guia_Fertilizacion_NPK_Targets_BioG_Limon_LM_v1_1` (§5.2 StageTargets,
/// §6 StageWeights, §7 lectura por etapa) y `01_Ficha_Tecnica` (§5, §7, §10).
///
/// Reglas no negociables que respeta este archivo:
/// - NO es una receta de fertilizacion en kg/ha; son prioridades RELATIVAS
///   N-P-K por etapa fisiologica (0..1) + targets de sensor BIO-G v1.
/// - Solo usa metricas compatibles con BIO-G v1: soilMoisture, soilTemp, ph,
///   ec, resistance, n, p, k. Fe/Zn/Mn/Ca/Mg/B/Cu/Cl/Na, HLB/psílido y
///   Phytophthora/gomosis quedan como CONTEXTO de mensaje, nunca como sensores
///   obligatorios (doc 05 §1, §3.8, §3.9).
/// - Contrato AgroRange v1.5: `lowMax` es frontera critica baja (NO inicio del
///   optimo). En EC/resistance la metrica es de exceso: `lowMax = -0.01` es un
///   placeholder seguro documentado (doc 05 §5).
/// - N y K son protagonistas, pero distinto: N pesa en brotación/vegetativo/
///   postcosecha; K pesa MÁS FUERTE que en naranjo en cuajado/llenado/madurez
///   (calibre, jugo, calidad). P pesa en raíz/establecimiento/floración pero NO
///   domina el ciclo adulto (doc 05 §0.0.1, §3.5-§3.7).
/// - La salinidad es un BLOQUEO central: el limón es SENSIBLE a sales. EC alta
///   baja confianza y no se celebra. En cítricos EC no tiene "deficiencia baja";
///   es métrica de exceso (doc 05 §0.0.1, §3.3, §5).
/// - Contrato v1.5: `dormancy` es reposo relativo / baja actividad (NO árbol
///   pelón caducifolio); `post_harvest` es etapa ACTIVA (recuperación entre
///   cortes, NO cierra el cultivo); `fruit_fill` NO es `harvest_maturity` (el
///   llenado/calibre/jugo NO habla de cosecha).
/// - El limón NO es un naranjo pequeño: enfatiza floración/corte repetido,
///   fruta verde comercial y K más alto (doc 01 §0, doc 05 §0.3).
/// - El perfil/variedad LM NO cambia la estructura fenologica ni estos targets
///   base; solo ajusta sensibilidad/mensajes en capas superiores (doc 05 §8).
///
/// Entradas publicas que el resto del proyecto debe usar:
/// - [resolveLemonTreeTargets]             → StageTargets por etapa.
/// - [resolveLemonTreeStageWeights]        → StageWeights (AgroScore).
/// - [resolveLemonTreeNutritionPriorities] → prioridades NPK + nota UX.
class LemonTreeUniversalProfile {
  const LemonTreeUniversalProfile._();

  /// pH de etapas activas (doc 05 §5.1): óptimo 5.8-7.2. `highMin` 8.0 marca la
  /// frontera de bloqueo de Fe/Zn/Mn/P por alcalinidad/caliza.
  static const AgroRange phActive = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.8,
    optimalMax: 7.2,
    highMin: 8.0,
  );

  /// pH base (dormancia/juvenil/madurez/postcosecha/unknown): óptimo un poco más
  /// amplio 5.7-7.4 porque en reposo/cosecha la disponibilidad fina pesa menos.
  static const AgroRange phBase = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.7,
    optimalMax: 7.4,
    highMin: 8.2,
  );
}

/// Prioridades NPK relativas por etapa + contexto UX corto (doc 05 §7).
///
/// Las prioridades son 0.00 (sin prioridad) a 1.00 (prioridad maxima). NO son
/// dosis: son peso fisiologico para interpretar la lectura del sensor.
class LemonTreeStageNutrition {
  const LemonTreeStageNutrition({
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

/// Datos crudos por etapa, transcritos del documento 05 (§5.2, §6 y §7).
///
/// `nRel/pRel/kRel` son los AgroRange RELATIVOS (escala 0..100). El motor
/// compartido los convierte a mg/kg comparables con el cap del cultivo
/// (`NutrientTargetRangeResolver` + `NpkCaps`). Las bandas ya son suaves: no se
/// dejan rangos pegados optimo→critico.
class _LemonStageProfile {
  const _LemonStageProfile({
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

const Map<String, _LemonStageProfile>
_lemonStageProfiles = <String, _LemonStageProfile>{
  TreeStageIds.plantingTransplant: _LemonStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 80, highMin: 88),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 28, highMin: 34),
    ph: LemonTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.0, highMin: 1.6),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.1,
    ),
    nRel: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 36, highMin: 72),
    pRel: AgroRange(lowMax: 20, optimalMin: 55, optimalMax: 78, highMin: 92),
    kRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 86),
    nPriority: 0.25,
    pPriority: 0.78,
    kPriority: 0.40,
    wMoisture: 0.26,
    wSoilTemp: 0.14,
    wPh: 0.12,
    wEc: 0.16,
    wResistance: 0.16,
    wN: 0.04,
    wP: 0.08,
    wK: 0.04,
    confidence: 'medium',
    careNoteEs: 'Raíz joven; P de arranque, no quemar con N/sales',
    uxGuidanceEs:
        'El limón acaba de entrar al suelo. Ahorita no se fuerza fruta ni N: '
        'primero raíz viva, humedad pareja, baja salinidad y cuello sano. El '
        'fósforo de arranque pesa más que el N; la raíz fina del limón es '
        'delicada con las sales.',
    nWindowEs: 'N bajo: priorizar raíz',
    pWindowEs: 'Ventana de raíz: P alto',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.rootEstablishment: _LemonStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 28, highMin: 34),
    ph: LemonTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.0, highMin: 1.7),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.1,
    ),
    nRel: AgroRange(lowMax: 10, optimalMin: 22, optimalMax: 44, highMin: 75),
    pRel: AgroRange(lowMax: 20, optimalMin: 55, optimalMax: 78, highMin: 92),
    kRel: AgroRange(lowMax: 16, optimalMin: 38, optimalMax: 62, highMin: 86),
    nPriority: 0.32,
    pPriority: 0.80,
    kPriority: 0.45,
    wMoisture: 0.27,
    wSoilTemp: 0.13,
    wPh: 0.12,
    wEc: 0.17,
    wResistance: 0.17,
    wN: 0.04,
    wP: 0.07,
    wK: 0.03,
    confidence: 'medium',
    careNoteEs: 'Raíz fina activa; humedad pareja y baja EC',
    uxGuidanceEs:
        'La raíz fina del limón es delicada. Si hay sales o suelo duro, el NPK '
        'no se aprovecha. Revisa humedad, EC y compactación antes de subir '
        'fertilizante; el limón toma mal el NPK con la raíz estresada.',
    nWindowEs: 'N de apoyo suave',
    pWindowEs: 'Raíz fina: P alto',
    kWindowEs: 'K medio',
  ),
  TreeStageIds.juvenileVegetative: _LemonStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 58, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 17, optimalMax: 30, highMin: 35),
    ph: LemonTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.2, highMin: 1.9),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 58, optimalMax: 78, highMin: 92),
    pRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 58, highMin: 85),
    kRel: AgroRange(lowMax: 22, optimalMin: 48, optimalMax: 72, highMin: 92),
    nPriority: 0.78,
    pPriority: 0.48,
    kPriority: 0.58,
    wMoisture: 0.20,
    wSoilTemp: 0.10,
    wPh: 0.10,
    wEc: 0.13,
    wResistance: 0.13,
    wN: 0.16,
    wP: 0.08,
    wK: 0.10,
    confidence: 'medium',
    careNoteEs: 'Formar copa y hoja; no exigir fruta',
    uxGuidanceEs:
        'En limón joven buscas copa, raíz y hoja, no fruta. El N ayuda, pero si '
        'te pasas haces brote débil y atraes plagas. No penalices la poca '
        'fruta; si hay hoja chica o clorosis con nervadura verde, revisa Fe/Zn/'
        'Mn y pH antes que más N.',
    nWindowEs: 'Construcción de árbol: N controlado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'K medio-alto',
  ),
  TreeStageIds.dormancy: _LemonStageProfile(
    moisture: AgroRange(lowMax: 35, optimalMin: 52, optimalMax: 78, highMin: 90),
    soilTemp: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 26, highMin: 34),
    ph: LemonTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.1),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 0, optimalMin: 8, optimalMax: 30, highMin: 65),
    pRel: AgroRange(lowMax: 0, optimalMin: 10, optimalMax: 28, highMin: 68),
    kRel: AgroRange(lowMax: 0, optimalMin: 12, optimalMax: 35, highMin: 72),
    nPriority: 0.18,
    pPriority: 0.22,
    kPriority: 0.25,
    wMoisture: 0.22,
    wSoilTemp: 0.14,
    wPh: 0.12,
    wEc: 0.16,
    wResistance: 0.14,
    wN: 0.07,
    wP: 0.06,
    wK: 0.09,
    confidence: 'low',
    // Contrato cítrico: reposo relativo / baja actividad / entre cortes, NO
    // árbol pelón.
    careNoteEs: 'Reposo relativo / entre cortes; no árbol apagado',
    uxGuidanceEs:
        'El limonero sigue verde: NO es un árbol que tira hoja. Si está en baja '
        'actividad o entre cortes, BIO-G baja la presión de NPK y cuida raíz, '
        'humedad, sales y preparación del siguiente flush/floración. Reposo '
        'relativo, no cultivo apagado.',
    nWindowEs: 'Reposo relativo: demanda baja',
    pWindowEs: 'Reposo relativo: demanda baja',
    kWindowEs: 'Reposo relativo: demanda baja',
  ),
  TreeStageIds.budbreak: _LemonStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 84, highMin: 91),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 30, highMin: 35),
    ph: LemonTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.2, highMin: 1.9),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 58, optimalMax: 78, highMin: 92),
    pRel: AgroRange(lowMax: 15, optimalMin: 38, optimalMax: 62, highMin: 86),
    kRel: AgroRange(lowMax: 22, optimalMin: 48, optimalMax: 72, highMin: 92),
    nPriority: 0.78,
    pPriority: 0.50,
    kPriority: 0.60,
    wMoisture: 0.20,
    wSoilTemp: 0.10,
    wPh: 0.10,
    wEc: 0.13,
    wResistance: 0.11,
    wN: 0.18,
    wP: 0.08,
    wK: 0.10,
    confidence: 'medium',
    careNoteEs: 'Brote tierno; N sí, pero cuidado con psílido/minador y sales',
    uxGuidanceEs:
        'Va entrando brote tierno / flush nuevo. El N ayuda a la hoja, pero el '
        'brote tierno atrae psílido, minador y pulgones: revisa hojas nuevas '
        'antes de culpar al fertilizante. En limón tropical/continuo el flush '
        'se repite y sube la presión de vector.',
    nWindowEs: 'Brotación: N moderado-alto',
    pWindowEs: 'P suficiente para brotación',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.vegetativeGrowth: _LemonStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 58, optimalMax: 84, highMin: 91),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 31, highMin: 36),
    ph: LemonTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 28, optimalMin: 58, optimalMax: 80, highMin: 93),
    pRel: AgroRange(lowMax: 12, optimalMin: 32, optimalMax: 55, highMin: 85),
    kRel: AgroRange(lowMax: 25, optimalMin: 52, optimalMax: 76, highMin: 92),
    nPriority: 0.76,
    pPriority: 0.40,
    kPriority: 0.64,
    wMoisture: 0.19,
    wSoilTemp: 0.09,
    wPh: 0.10,
    wEc: 0.13,
    wResistance: 0.11,
    wN: 0.18,
    wP: 0.07,
    wK: 0.13,
    confidence: 'medium',
    careNoteEs: 'Construir hoja, sin irse a puro follaje',
    uxGuidanceEs:
        'Buena hoja es necesaria, pero no queremos puro follaje. Si el N está '
        'alto y hay poca carga, el limón se va a brote tierno y sombra sin '
        'limón comercial. EC alta + N/K altos = sales; pH alto + hoja chica = '
        'Fe/Zn/Mn, no asumas N bajo. El K mantiene balance y calidad futura.',
    nWindowEs: 'Crecimiento: N útil controlado',
    pWindowEs: 'P bajo-medio',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.flowering: _LemonStageProfile(
    moisture: AgroRange(lowMax: 50, optimalMin: 65, optimalMax: 86, highMin: 92),
    soilTemp: AgroRange(lowMax: 11, optimalMin: 18, optimalMax: 30, highMin: 35),
    ph: LemonTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.2, highMin: 1.8),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 16, optimalMin: 35, optimalMax: 56, highMin: 78),
    pRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 68, highMin: 88),
    kRel: AgroRange(lowMax: 28, optimalMin: 55, optimalMax: 78, highMin: 92),
    nPriority: 0.42,
    pPriority: 0.62,
    kPriority: 0.70,
    wMoisture: 0.26,
    wSoilTemp: 0.14,
    wPh: 0.10,
    wEc: 0.15,
    wResistance: 0.10,
    wN: 0.07,
    wP: 0.08,
    wK: 0.10,
    confidence: 'high',
    careNoteEs: 'Floración crítica; agua/temperatura/EC mandan, N pesado no',
    uxGuidanceEs:
        'En floración (azahar) el limón no perdona agua baja, calor seco ni '
        'sales: puede tirar flor aunque el NPK marque bien. El N alto no '
        'arregla una floración estresada y se puede ir a follaje. P y K deben '
        'estar funcionales antes de la floración; si floreó pero no amarró, '
        'revisa agua, calor, viento, frío y sales antes que el fertilizante.',
    nWindowEs: 'Floración: N sin exceso',
    pWindowEs: 'Floración: P relevante',
    kWindowEs: 'Floración: K relevante',
  ),
  TreeStageIds.fruitSet: _LemonStageProfile(
    moisture: AgroRange(lowMax: 50, optimalMin: 65, optimalMax: 86, highMin: 92),
    soilTemp: AgroRange(lowMax: 11, optimalMin: 18, optimalMax: 31, highMin: 36),
    ph: LemonTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.2, highMin: 1.8),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.2,
    ),
    nRel: AgroRange(lowMax: 18, optimalMin: 38, optimalMax: 60, highMin: 80),
    pRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 84),
    kRel: AgroRange(lowMax: 35, optimalMin: 65, optimalMax: 85, highMin: 95),
    nPriority: 0.48,
    pPriority: 0.55,
    kPriority: 0.84,
    wMoisture: 0.26,
    wSoilTemp: 0.11,
    wPh: 0.10,
    wEc: 0.16,
    wResistance: 0.10,
    wN: 0.06,
    wP: 0.07,
    wK: 0.14,
    confidence: 'high',
    careNoteEs: 'Amarre del limoncito; K sube, sales/agua baja tumban cuajado',
    uxGuidanceEs:
        'El limoncito está amarrando. El K empieza a mandar, pero el agua '
        'estable y la EC baja pesan más: con falta de agua o sales el limón '
        'tira frutito aunque el NPK esté bien. Algo de caída puede ser normal; '
        'se vuelve alerta si coincide con calor, sales, humedad baja o raíz '
        'mala. N pesado puede empujar brote y caída.',
    nWindowEs: 'Amarre: N moderado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Amarre: K sube fuerte',
  ),
  TreeStageIds.fruitFill: _LemonStageProfile(
    moisture: AgroRange(lowMax: 50, optimalMin: 65, optimalMax: 88, highMin: 93),
    soilTemp: AgroRange(lowMax: 11, optimalMin: 18, optimalMax: 32, highMin: 37),
    ph: LemonTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.1, highMin: 1.8),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 58, highMin: 80),
    pRel: AgroRange(lowMax: 8, optimalMin: 22, optimalMax: 45, highMin: 75),
    kRel: AgroRange(lowMax: 42, optimalMin: 72, optimalMax: 92, highMin: 97),
    nPriority: 0.45,
    pPriority: 0.32,
    kPriority: 0.92,
    wMoisture: 0.26,
    wSoilTemp: 0.09,
    wPh: 0.09,
    wEc: 0.17,
    wResistance: 0.10,
    wN: 0.06,
    wP: 0.04,
    wK: 0.19,
    confidence: 'high',
    // CONTRATO v1.5: copy de LLENADO de limón (calibre/jugo), nunca cosecha.
    careNoteEs: 'Calibre y jugo; K/agua mandan, no cosecha todavía',
    uxGuidanceEs:
        'El limón se está creciendo y llenando: se juega el calibre y el jugo. '
        'Aquí manda el K con agua estable. Si el K sale bajo pero el suelo está '
        'seco o salino, primero corrige agua/sales; si no, el árbol no lo '
        'aprovecha. La EC alta castiga calibre, jugo y hoja. Esto es llenado, '
        'todavía NO cosecha.',
    nWindowEs: 'Llenado: N medio con carga real',
    pWindowEs: 'P bajo-moderado',
    kWindowEs: 'Llenado del limón: K protagonista',
  ),
  TreeStageIds.harvestMaturity: _LemonStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 58, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 9, optimalMin: 16, optimalMax: 32, highMin: 37),
    ph: LemonTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 42, highMin: 68),
    pRel: AgroRange(lowMax: 5, optimalMin: 18, optimalMax: 40, highMin: 70),
    kRel: AgroRange(lowMax: 30, optimalMin: 58, optimalMax: 80, highMin: 92),
    nPriority: 0.26,
    pPriority: 0.18,
    kPriority: 0.70,
    wMoisture: 0.21,
    wSoilTemp: 0.08,
    wPh: 0.10,
    wEc: 0.15,
    wResistance: 0.10,
    wN: 0.06,
    wP: 0.04,
    wK: 0.16,
    confidence: 'medium',
    careNoteEs:
        'Corte/madurez comercial; en persa/mexicano el verde puede ser maduro',
    uxGuidanceEs:
        'Cerca del corte cuida calidad, calibre, jugo, caída y sanidad. En '
        'limón persa/mexicano el verde puede ser comercial: no lo marques '
        'inmaduro por no estar amarillo. En amarillo/Eureka-Lisbon sí puede '
        'hablarse de color amarillo. No empujes N tarde: puede dar brote '
        'blando, caída y bajar calidad.',
    nWindowEs: 'Madurez: evitar N alto tarde',
    pWindowEs: 'P bajo',
    kWindowEs: 'Madurez: K útil para calidad',
  ),
  TreeStageIds.postHarvest: _LemonStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 58, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 15, optimalMax: 30, highMin: 36),
    ph: LemonTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.1),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 40, optimalMax: 65, highMin: 85),
    pRel: AgroRange(lowMax: 8, optimalMin: 22, optimalMax: 45, highMin: 75),
    kRel: AgroRange(lowMax: 22, optimalMin: 48, optimalMax: 72, highMin: 90),
    nPriority: 0.60,
    pPriority: 0.30,
    kPriority: 0.62,
    wMoisture: 0.22,
    wSoilTemp: 0.09,
    wPh: 0.10,
    wEc: 0.15,
    wResistance: 0.12,
    wN: 0.12,
    wP: 0.05,
    wK: 0.15,
    confidence: 'medium',
    careNoteEs: 'Recuperación entre cortes; hoja activa y reservas',
    uxGuidanceEs:
        'Después del corte el limonero NO se apaga: sigue con hoja y raíz para '
        'recuperar reservas y preparar la siguiente floración o corte. Corrige '
        'N/K moderados solo con hoja activa, riego parejo y EC baja. Si hay '
        'frío, sales, raíz mala o HLB, no empujes N tardío. La cosecha no '
        'cierra el cultivo.',
    nWindowEs: 'Postcosecha: N de reservas (con hoja activa)',
    pWindowEs: 'P bajo-medio',
    kWindowEs: 'Postcosecha: K de reservas',
  ),
  TreeStageIds.unknown: _LemonStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 85, highMin: 92),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 16, optimalMax: 31, highMin: 37),
    ph: LemonTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.1),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 62, highMin: 85),
    pRel: AgroRange(lowMax: 10, optimalMin: 30, optimalMax: 55, highMin: 82),
    kRel: AgroRange(lowMax: 22, optimalMin: 48, optimalMax: 72, highMin: 92),
    nPriority: 0.48,
    pPriority: 0.38,
    kPriority: 0.58,
    wMoisture: 0.23,
    wSoilTemp: 0.10,
    wPh: 0.10,
    wEc: 0.15,
    wResistance: 0.12,
    wN: 0.10,
    wP: 0.07,
    wK: 0.13,
    confidence: 'low',
    careNoteEs: 'Fallback conservador; pedir etapa visible',
    uxGuidanceEs:
        'Puedo leer el suelo, pero para afinar NPK necesito saber qué se ve: '
        '¿brote nuevo, flor/azahar, frutito amarrado, limón creciendo, listo '
        'para corte o después de corte? Mientras tanto BIO-G usa rangos '
        'conservadores.',
    nWindowEs: 'Etapa no definida',
    pWindowEs: 'Etapa no definida',
    kWindowEs: 'Etapa no definida',
  ),
};

_LemonStageProfile _profileForStage(String? stageId) {
  final id = normalizeTreeStageId(stageId);
  return _lemonStageProfiles[id] ?? _lemonStageProfiles[TreeStageIds.unknown]!;
}

/// Targets de sensor por etapa para `resolveTargets` del limón (doc 05 §5.2).
///
/// Los `nIndex/pIndex/kIndex` llevan el rango RELATIVO por etapa (0..100). El
/// motor compartido (`NutrientTargetRangeResolver`) los convierte a mg/kg con el
/// cap del cultivo (`NpkCaps`), asi las bandas bajo/optimo/alto-util/exceso ya
/// quedan suaves sin saltos optimo→critico.
StageTargets resolveLemonTreeTargets(String? stageId) {
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
StageWeights resolveLemonTreeStageWeights(String? stageId) {
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
LemonTreeStageNutrition resolveLemonTreeNutritionPriorities(String? stageId) {
  final p = _profileForStage(stageId);
  return LemonTreeStageNutrition(
    stageId: normalizeTreeStageId(stageId),
    nPriority01: p.nPriority,
    pPriority01: p.pPriority,
    kPriority01: p.kPriority,
    confidence: p.confidence,
    careNoteEs: p.careNoteEs,
  );
}

/// Guia UX corta por etapa (doc 05 §7) para tarjetas/resumenes del limón.
String lemonTreeStageGuidanceEs(String? stageId) =>
    _profileForStage(stageId).uxGuidanceEs;
