import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Perfil universal agronomico del Naranjo (Citrus sinensis (L.) Osbeck) —
/// arbol perenne SIEMPREVERDE, cítrico, de fruto fresco/jugo.
///
/// Alimentado por el documento oficial
/// `05_Guia_Fertilizacion_NPK_Targets_BioG_Naranjo_OR_v1_1` (§6 StageTargets,
/// §7 StageWeights, §8 lectura por etapa, §11 prioridades) y `01_Ficha_Tecnica`
/// (§6, §9, §10).
///
/// Reglas no negociables que respeta este archivo:
/// - NO es una receta de fertilizacion en kg/ha; son prioridades RELATIVAS
///   N-P-K por etapa fisiologica (0..1) + targets de sensor BIO-G v1.
/// - Solo usa metricas compatibles con BIO-G v1: soilMoisture, soilTemp, ph,
///   ec, resistance, n, p, k. Fe/Zn/Mn/Ca/Mg/B/Cu/Cl/Na y HLB/psílido quedan
///   como CONTEXTO de mensaje, nunca como sensores obligatorios (doc 05 §0.2.2,
///   §3.8, §3.9).
/// - Contrato AgroRange v1.5: `lowMax` es frontera critica baja (NO inicio del
///   optimo). En EC/resistance la metrica es de exceso: `lowMax = -0.01` es un
///   placeholder seguro documentado (doc 05 §5, §6).
/// - N y K son protagonistas, pero distinto: N pesa en brotación/vegetativo/
///   floración; K pesa en cuajado/llenado/madurez (calibre, jugo, calidad).
///   P pesa en raíz/establecimiento/floración pero NO domina el ciclo adulto
///   (doc 05 §0 §3.5-§3.7).
/// - La salinidad es un BLOQUEO central: EC alta baja confianza y no se celebra.
///   En cítricos EC no tiene "deficiencia baja"; es métrica de exceso (doc 05
///   §0.0.1 §5, §3.3).
/// - Contrato v1.5: `dormancy` es reposo relativo / baja actividad (NO árbol
///   pelón caducifolio); `post_harvest` es etapa ACTIVA (reservas para el
///   siguiente ciclo, NO cierra el cultivo); `fruit_fill` NO es
///   `harvest_maturity` (el llenado de naranja/calibre/jugo NO habla de cosecha).
/// - El perfil/variedad OR NO cambia la estructura fenologica ni estos targets
///   base; solo ajusta sensibilidad/mensajes en capas superiores (doc 05 §11).
///
/// Entradas publicas que el resto del proyecto debe usar:
/// - [resolveOrangeTreeTargets]             → StageTargets por etapa.
/// - [resolveOrangeTreeStageWeights]        → StageWeights (AgroScore).
/// - [resolveOrangeTreeNutritionPriorities] → prioridades NPK + nota UX.
class OrangeTreeUniversalProfile {
  const OrangeTreeUniversalProfile._();

  /// pH de etapas activas (doc 05 §3.4, §6): óptimo amplio 5.8-7.3 porque México
  /// tiene suelos ácidos y alcalinos. `highMin` 8.1 marca la frontera de bloqueo
  /// de Fe/Zn/Mn/P por alcalinidad/caliza.
  static const AgroRange phActive = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.8,
    optimalMax: 7.3,
    highMin: 8.1,
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

/// Prioridades NPK relativas por etapa + contexto UX corto (doc 05 §11).
///
/// Las prioridades son 0.00 (sin prioridad) a 1.00 (prioridad maxima). NO son
/// dosis: son peso fisiologico para interpretar la lectura del sensor.
class OrangeTreeStageNutrition {
  const OrangeTreeStageNutrition({
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

  /// Nota corta y segura para UX (doc 05 §6 "Nota").
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

/// Datos crudos por etapa, transcritos del documento 05 (§6, §7 y §8).
///
/// `nRel/pRel/kRel` son los AgroRange RELATIVOS (escala 0..100). El motor
/// compartido los convierte a mg/kg comparables con el cap del cultivo
/// (`NutrientTargetRangeResolver` + `NpkCaps`). Las bandas ya son suaves: no se
/// dejan rangos pegados optimo→critico.
class _OrangeStageProfile {
  const _OrangeStageProfile({
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

const Map<String, _OrangeStageProfile>
_orangeStageProfiles = <String, _OrangeStageProfile>{
  TreeStageIds.plantingTransplant: _OrangeStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 80, highMin: 88),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 28, highMin: 34),
    ph: OrangeTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.1, highMin: 1.7),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.1,
    ),
    nRel: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 35, highMin: 70),
    pRel: AgroRange(lowMax: 20, optimalMin: 55, optimalMax: 78, highMin: 92),
    kRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 58, highMin: 85),
    nPriority: 0.25,
    pPriority: 0.75,
    kPriority: 0.38,
    wMoisture: 0.26,
    wSoilTemp: 0.14,
    wPh: 0.12,
    wEc: 0.16,
    wResistance: 0.16,
    wN: 0.04,
    wP: 0.08,
    wK: 0.04,
    confidence: 'medium',
    careNoteEs: 'Raíz joven, evitar quemadura y sales',
    uxGuidanceEs:
        'El naranjo acaba de entrar al suelo. Ahorita no se trata de forzar '
        'fruta ni puro N: primero raíz, humedad pareja, baja salinidad y suelo '
        'sin compactación. El fósforo de arranque pesa más que el N.',
    nWindowEs: 'N bajo: priorizar raíz',
    pWindowEs: 'Ventana de raíz: P alto',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.rootEstablishment: _OrangeStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 28, highMin: 34),
    ph: OrangeTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.1, highMin: 1.8),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.1,
    ),
    nRel: AgroRange(lowMax: 10, optimalMin: 22, optimalMax: 42, highMin: 75),
    pRel: AgroRange(lowMax: 20, optimalMin: 55, optimalMax: 78, highMin: 92),
    kRel: AgroRange(lowMax: 15, optimalMin: 38, optimalMax: 60, highMin: 86),
    nPriority: 0.32,
    pPriority: 0.78,
    kPriority: 0.42,
    wMoisture: 0.27,
    wSoilTemp: 0.13,
    wPh: 0.12,
    wEc: 0.17,
    wResistance: 0.16,
    wN: 0.05,
    wP: 0.08,
    wK: 0.02,
    confidence: 'medium',
    careNoteEs: 'Raíz fina activa; suelo manda antes que NPK',
    uxGuidanceEs:
        'Si la raíz no está trabajando, el fertilizante no se aprovecha. Revisa '
        'humedad, sales y compactación antes de subir NPK. El naranjo no toma '
        'bien el NPK con la raíz estresada.',
    nWindowEs: 'N de apoyo suave',
    pWindowEs: 'Raíz fina: P alto',
    kWindowEs: 'K medio',
  ),
  TreeStageIds.juvenileVegetative: _OrangeStageProfile(
    moisture: AgroRange(lowMax: 40, optimalMin: 55, optimalMax: 80, highMin: 90),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 30, highMin: 36),
    ph: OrangeTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 55, optimalMax: 75, highMin: 90),
    pRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 58, highMin: 85),
    kRel: AgroRange(lowMax: 22, optimalMin: 45, optimalMax: 70, highMin: 90),
    nPriority: 0.72,
    pPriority: 0.42,
    kPriority: 0.55,
    wMoisture: 0.24,
    wSoilTemp: 0.13,
    wPh: 0.10,
    wEc: 0.15,
    wResistance: 0.12,
    wN: 0.13,
    wP: 0.07,
    wK: 0.06,
    confidence: 'medium',
    careNoteEs: 'Formar copa y raíz sin empujar madera blanda',
    uxGuidanceEs:
        'En árbol joven buscas copa y raíz, no fruta. El N ayuda, pero si te '
        'pasas haces madera tierna y problemas de manejo. Si hay hoja chica o '
        'clorosis con nervadura verde, revisa Fe/Zn/Mn y pH antes que más N.',
    nWindowEs: 'Construcción de árbol: N controlado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'K medio-alto',
  ),
  TreeStageIds.dormancy: _OrangeStageProfile(
    moisture: AgroRange(lowMax: 35, optimalMin: 50, optimalMax: 75, highMin: 88),
    soilTemp: AgroRange(lowMax: 5, optimalMin: 10, optimalMax: 24, highMin: 32),
    ph: OrangeTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.2),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.5,
    ),
    nRel: AgroRange(lowMax: 0, optimalMin: 8, optimalMax: 25, highMin: 60),
    pRel: AgroRange(lowMax: 0, optimalMin: 8, optimalMax: 25, highMin: 65),
    kRel: AgroRange(lowMax: 0, optimalMin: 10, optimalMax: 30, highMin: 70),
    nPriority: 0.18,
    pPriority: 0.18,
    kPriority: 0.22,
    wMoisture: 0.22,
    wSoilTemp: 0.12,
    wPh: 0.12,
    wEc: 0.16,
    wResistance: 0.12,
    wN: 0.06,
    wP: 0.05,
    wK: 0.05,
    confidence: 'low',
    // Contrato cítrico: reposo relativo / baja actividad, NO árbol pelón.
    careNoteEs: 'No pintar como árbol pelón; no sobrerreaccionar a NPK',
    uxGuidanceEs:
        'El naranjo puede seguir verde: NO es un árbol que tira hoja. Si está '
        'en baja actividad (frío/seca), BIO-G baja la presión de NPK y cuida '
        'raíz, humedad, sales y preparación de la floración. Reposo relativo, '
        'no cultivo apagado.',
    nWindowEs: 'Reposo relativo: demanda baja',
    pWindowEs: 'Reposo relativo: demanda baja',
    kWindowEs: 'Reposo relativo: demanda baja',
  ),
  TreeStageIds.budbreak: _OrangeStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 30, highMin: 36),
    ph: OrangeTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.1),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 25, optimalMin: 55, optimalMax: 75, highMin: 90),
    pRel: AgroRange(lowMax: 15, optimalMin: 38, optimalMax: 62, highMin: 86),
    kRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 68, highMin: 90),
    nPriority: 0.72,
    pPriority: 0.48,
    kPriority: 0.58,
    wMoisture: 0.24,
    wSoilTemp: 0.14,
    wPh: 0.11,
    wEc: 0.14,
    wResistance: 0.11,
    wN: 0.12,
    wP: 0.07,
    wK: 0.07,
    confidence: 'medium',
    careNoteEs: 'Hoja nueva, micronutrientes y N moderado-alto',
    uxGuidanceEs:
        'Va entrando brote nuevo. El N ayuda a hoja, pero el brote tierno atrae '
        'psílido, minador y pulgones: revisa hojas nuevas antes de culpar al '
        'fertilizante. Si hay hojas chicas o clorosis con nervadura verde, '
        'piensa en Fe/Zn/Mn y pH, no en falta de N.',
    nWindowEs: 'Brotación: N moderado-alto',
    pWindowEs: 'P suficiente para brotación',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.vegetativeGrowth: _OrangeStageProfile(
    moisture: AgroRange(lowMax: 42, optimalMin: 58, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 17, optimalMax: 32, highMin: 38),
    ph: OrangeTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.2),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 28, optimalMin: 55, optimalMax: 78, highMin: 92),
    pRel: AgroRange(lowMax: 12, optimalMin: 32, optimalMax: 55, highMin: 85),
    kRel: AgroRange(lowMax: 25, optimalMin: 50, optimalMax: 75, highMin: 92),
    nPriority: 0.75,
    pPriority: 0.35,
    kPriority: 0.62,
    wMoisture: 0.24,
    wSoilTemp: 0.14,
    wPh: 0.10,
    wEc: 0.14,
    wResistance: 0.11,
    wN: 0.14,
    wP: 0.05,
    wK: 0.08,
    confidence: 'medium',
    careNoteEs: 'Construir hoja funcional; evitar puro follaje',
    uxGuidanceEs:
        'Buen follaje es necesario, pero no queremos puro follaje. Si el N está '
        'alto y la carga de fruta es baja, el árbol se puede ir a hoja y sombra. '
        'EC alta + N/K altos = sales; pH alto + hoja chica = Fe/Zn/Mn, no '
        'asumas N bajo.',
    nWindowEs: 'Crecimiento: N útil controlado',
    pWindowEs: 'P bajo-medio',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.flowering: _OrangeStageProfile(
    moisture: AgroRange(lowMax: 50, optimalMin: 65, optimalMax: 85, highMin: 92),
    soilTemp: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 30, highMin: 35),
    ph: OrangeTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 18, optimalMin: 38, optimalMax: 60, highMin: 82),
    pRel: AgroRange(lowMax: 18, optimalMin: 45, optimalMax: 68, highMin: 88),
    kRel: AgroRange(lowMax: 25, optimalMin: 50, optimalMax: 75, highMin: 90),
    nPriority: 0.48,
    pPriority: 0.62,
    kPriority: 0.65,
    wMoisture: 0.30,
    wSoilTemp: 0.15,
    wPh: 0.10,
    wEc: 0.14,
    wResistance: 0.09,
    wN: 0.08,
    wP: 0.08,
    wK: 0.06,
    confidence: 'high',
    careNoteEs: 'Etapa crítica: agua, temperatura, P/K y N sin exceso',
    uxGuidanceEs:
        'Floración (azahar) es etapa delicada. Aquí mandan humedad estable, '
        'temperatura y balance; el N alto no arregla una floración estresada y '
        'puede irse a follaje. Si floreó pero no amarró, revisa calor, frío, '
        'viento, agua y sales antes de culpar al fertilizante.',
    nWindowEs: 'Floración: N sin exceso',
    pWindowEs: 'Floración: P relevante',
    kWindowEs: 'Floración: K relevante',
  ),
  TreeStageIds.fruitSet: _OrangeStageProfile(
    moisture: AgroRange(lowMax: 50, optimalMin: 65, optimalMax: 85, highMin: 92),
    soilTemp: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 31, highMin: 36),
    ph: OrangeTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.0),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.3,
    ),
    nRel: AgroRange(lowMax: 20, optimalMin: 40, optimalMax: 62, highMin: 84),
    pRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 85),
    kRel: AgroRange(lowMax: 32, optimalMin: 60, optimalMax: 82, highMin: 94),
    nPriority: 0.52,
    pPriority: 0.48,
    kPriority: 0.78,
    wMoisture: 0.30,
    wSoilTemp: 0.14,
    wPh: 0.09,
    wEc: 0.16,
    wResistance: 0.10,
    wN: 0.08,
    wP: 0.06,
    wK: 0.07,
    confidence: 'high',
    careNoteEs: 'Evitar caída por estrés; K empieza a mandar',
    uxGuidanceEs:
        'En cuajado/amarre se define mucha fruta. Si falta agua o hay sales, la '
        'naranja tira fruto aunque el NPK no se vea tan mal. Algo de caída puede '
        'ser normal; se vuelve alerta si coincide con calor, sales, humedad baja '
        'o raíz mala. El K empieza a pesar.',
    nWindowEs: 'Amarre: N moderado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Amarre: K empieza a pesar',
  ),
  TreeStageIds.fruitFill: _OrangeStageProfile(
    moisture: AgroRange(lowMax: 50, optimalMin: 65, optimalMax: 88, highMin: 93),
    soilTemp: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 32, highMin: 38),
    ph: OrangeTreeUniversalProfile.phActive,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.2, highMin: 1.9),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 58, highMin: 82),
    pRel: AgroRange(lowMax: 10, optimalMin: 25, optimalMax: 48, highMin: 78),
    kRel: AgroRange(lowMax: 40, optimalMin: 70, optimalMax: 90, highMin: 96),
    nPriority: 0.45,
    pPriority: 0.30,
    kPriority: 0.90,
    wMoisture: 0.30,
    wSoilTemp: 0.14,
    wPh: 0.09,
    wEc: 0.17,
    wResistance: 0.10,
    wN: 0.05,
    wP: 0.04,
    wK: 0.11,
    confidence: 'high',
    // CONTRATO v1.5: copy de LLENADO de naranja (calibre/jugo), nunca cosecha.
    careNoteEs: 'Calibre, jugo, K, agua estable y salinidad baja',
    uxGuidanceEs:
        'La naranja se está creciendo y llenando por dentro. Aquí manda el K '
        'con agua estable: se juega el calibre y el jugo. Si el K sale bajo pero '
        'el suelo está seco o salino, primero corrige agua/sales; si no, el '
        'árbol no lo aprovecha. Esto es llenado, todavía NO cosecha.',
    nWindowEs: 'Llenado: N medio con carga real',
    pWindowEs: 'P bajo-moderado',
    kWindowEs: 'Llenado de naranja: K protagonista',
  ),
  TreeStageIds.harvestMaturity: _OrangeStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 58, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 30, highMin: 36),
    ph: OrangeTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.2),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.9,
      highMin: 2.5,
    ),
    nRel: AgroRange(lowMax: 8, optimalMin: 20, optimalMax: 45, highMin: 70),
    pRel: AgroRange(lowMax: 5, optimalMin: 18, optimalMax: 40, highMin: 70),
    kRel: AgroRange(lowMax: 25, optimalMin: 55, optimalMax: 78, highMin: 92),
    nPriority: 0.25,
    pPriority: 0.20,
    kPriority: 0.68,
    wMoisture: 0.25,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.17,
    wResistance: 0.10,
    wN: 0.05,
    wP: 0.04,
    wK: 0.07,
    confidence: 'medium',
    careNoteEs: 'Calidad final; no empujar N tarde',
    uxGuidanceEs:
        'Ya estás en madurez/cosecha: cuida color, calibre, jugo, caída y '
        'calidad final. No empujes N tarde si no hace falta: puede retrasar '
        'color, engrosar cáscara y bajar calidad. En Valencia el color externo '
        'puede engañar (reverdecido).',
    nWindowEs: 'Madurez: evitar N alto tarde',
    pWindowEs: 'P bajo',
    kWindowEs: 'Madurez: K útil para calidad',
  ),
  TreeStageIds.postHarvest: _OrangeStageProfile(
    moisture: AgroRange(lowMax: 40, optimalMin: 55, optimalMax: 82, highMin: 90),
    soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 30, highMin: 36),
    ph: OrangeTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.2),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 82),
    pRel: AgroRange(lowMax: 8, optimalMin: 22, optimalMax: 45, highMin: 75),
    kRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 68, highMin: 88),
    nPriority: 0.55,
    pPriority: 0.30,
    kPriority: 0.60,
    wMoisture: 0.25,
    wSoilTemp: 0.12,
    wPh: 0.11,
    wEc: 0.16,
    wResistance: 0.11,
    wN: 0.10,
    wP: 0.05,
    wK: 0.10,
    confidence: 'medium',
    careNoteEs: 'Hoja activa, reservas y preparación del siguiente ciclo',
    uxGuidanceEs:
        'Después de cosecha el naranjo NO se apaga. Si trae hoja activa, está '
        'recuperando reservas para la siguiente floración. Corrige N/K moderados '
        'solo con hoja activa, riego parejo y EC baja; si ya viene frío o baja '
        'actividad, no empujes N tardío.',
    nWindowEs: 'Postcosecha: N de reservas (con hoja activa)',
    pWindowEs: 'P bajo-medio',
    kWindowEs: 'Postcosecha: K de reservas',
  ),
  TreeStageIds.unknown: _OrangeStageProfile(
    moisture: AgroRange(lowMax: 45, optimalMin: 60, optimalMax: 85, highMin: 92),
    soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 30, highMin: 36),
    ph: OrangeTreeUniversalProfile.phBase,
    ec: AgroRange(lowMax: -0.01, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.2),
    resistance: AgroRange(
      lowMax: -0.01,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.4,
    ),
    nRel: AgroRange(lowMax: 15, optimalMin: 35, optimalMax: 60, highMin: 85),
    pRel: AgroRange(lowMax: 10, optimalMin: 30, optimalMax: 55, highMin: 82),
    kRel: AgroRange(lowMax: 20, optimalMin: 45, optimalMax: 70, highMin: 90),
    nPriority: 0.45,
    pPriority: 0.40,
    kPriority: 0.55,
    wMoisture: 0.25,
    wSoilTemp: 0.13,
    wPh: 0.11,
    wEc: 0.15,
    wResistance: 0.12,
    wN: 0.08,
    wP: 0.06,
    wK: 0.10,
    confidence: 'low',
    careNoteEs: 'Fallback conservador; pedir etapa visible',
    uxGuidanceEs:
        'Puedo leer el suelo, pero para afinar NPK necesito saber qué se ve: '
        '¿brote nuevo, flor/azahar, frutito amarrado, naranja creciendo, madura/'
        'cosecha o después de cosecha? Mientras tanto BIO-G usa rangos '
        'conservadores.',
    nWindowEs: 'Etapa no definida',
    pWindowEs: 'Etapa no definida',
    kWindowEs: 'Etapa no definida',
  ),
};

_OrangeStageProfile _profileForStage(String? stageId) {
  final id = normalizeTreeStageId(stageId);
  return _orangeStageProfiles[id] ??
      _orangeStageProfiles[TreeStageIds.unknown]!;
}

/// Targets de sensor por etapa para `resolveTargets` del naranjo (doc 05 §6).
///
/// Los `nIndex/pIndex/kIndex` llevan el rango RELATIVO por etapa (0..100). El
/// motor compartido (`NutrientTargetRangeResolver`) los convierte a mg/kg con el
/// cap del cultivo (`NpkCaps`), asi las bandas bajo/optimo/alto-util/exceso ya
/// quedan suaves sin saltos optimo→critico.
StageTargets resolveOrangeTreeTargets(String? stageId) {
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

/// Pesos AgroScore por etapa (doc 05 §7). Pesos explicitos por nutriente.
StageWeights resolveOrangeTreeStageWeights(String? stageId) {
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
OrangeTreeStageNutrition resolveOrangeTreeNutritionPriorities(String? stageId) {
  final p = _profileForStage(stageId);
  return OrangeTreeStageNutrition(
    stageId: normalizeTreeStageId(stageId),
    nPriority01: p.nPriority,
    pPriority01: p.pPriority,
    kPriority01: p.kPriority,
    confidence: p.confidence,
    careNoteEs: p.careNoteEs,
  );
}

/// Guia UX corta por etapa (doc 05 §8, §14) para tarjetas/resumenes del naranjo.
String orangeTreeStageGuidanceEs(String? stageId) =>
    _profileForStage(stageId).uxGuidanceEs;
