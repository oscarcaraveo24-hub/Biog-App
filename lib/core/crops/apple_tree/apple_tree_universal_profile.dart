import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Perfil universal agronómico del Manzano (Malus domestica).
///
/// Alimentado por el documento oficial:
/// `05_Guia_Fertilizacion_NPK_Targets_BioG_Manzano_v1_1`.
///
/// Reglas no negociables que respeta este archivo:
/// - NO es una receta de fertilización en kg/ha; son prioridades RELATIVAS
///   N-P-K por etapa fisiológica (0..1) + targets de sensor BIO-G v1.
/// - Solo usa métricas compatibles con BIO-G v1: soilMoisture, soilTemp, ph,
///   ec, resistance, n, p, k. Ca/Mg/B/Zn/Fe quedan como CONTEXTO de mensaje,
///   nunca como sensores obligatorios.
/// - La variedad/perfil AP NO cambia la estructura fenológica ni estos targets
///   base; solo ajusta sensibilidad/mensajes en capas superiores.
/// - `post_harvest` es una etapa ACTIVA (recuperación de reservas), no cierra
///   el cultivo: tiene prioridad N/K real, no simbólica.
/// - `unknown` usa un perfil conservador; no inventa precisión.
///
/// Las tres entradas públicas que el resto del proyecto debe usar:
/// - [resolveAppleTreeTargets]          → StageTargets por etapa.
/// - [resolveAppleTreeStageWeights]     → StageWeights (AgroScore) por etapa.
/// - [resolveAppleTreeNutritionPriorities] → prioridades NPK + nota UX.
class AppleTreeUniversalProfile {
  const AppleTreeUniversalProfile._();

  /// pH objetivo universal de manzano (doc 05 §6.1): preferido 6.0–6.8,
  /// alerta baja <5.5, alta >7.5. Es estable entre etapas.
  static const AgroRange _phUniversal = AgroRange(
    lowMax: 5.5,
    optimalMin: 6.0,
    optimalMax: 6.8,
    highMin: 7.5,
  );
}

/// Prioridades NPK relativas por etapa + contexto UX corto.
///
/// Las prioridades son 0.00 (sin prioridad) a 1.00 (prioridad máxima). NO son
/// dosis: son peso fisiológico para que BIO-G interprete las lecturas del
/// sensor según la etapa (doc 05 §8).
class AppleTreeStageNutrition {
  const AppleTreeStageNutrition({
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

  /// Confianza cualitativa del modelado de la etapa: 'low' | 'medium' | 'high'.
  final String confidence;

  /// Nota corta y segura para UX (doc 05 §8.1 "Cuidado:").
  final String careNoteEs;

  /// Nutriente NPK dominante de la etapa (el de mayor prioridad relativa).
  AgroMetricKey get dominantNutrient {
    if (kPriority01 >= nPriority01 && kPriority01 >= pPriority01) {
      return AgroMetricKey.k;
    }
    if (nPriority01 >= pPriority01) return AgroMetricKey.n;
    return AgroMetricKey.p;
  }
}

/// Datos crudos por etapa, transcritos del documento 05 (§8, §9, §10, §12).
class _AppleStageProfile {
  const _AppleStageProfile({
    required this.moisture,
    required this.soilTemp,
    required this.ec,
    required this.resistance,
    required this.nPriority,
    required this.pPriority,
    required this.kPriority,
    required this.nTargetRange,
    required this.pTargetRange,
    required this.kTargetRange,
    required this.wMoisture,
    required this.wSoilTemp,
    required this.wPh,
    required this.wEc,
    required this.wResistance,
    required this.wNpk,
    required this.confidence,
    required this.careNoteEs,
    required this.uxGuidanceEs,
    required this.nWindowEs,
    required this.pWindowEs,
    required this.kWindowEs,
  });

  final AgroRange moisture;
  final AgroRange soilTemp;
  final AgroRange ec;
  final AgroRange resistance;

  /// Prioridades relativas por nutriente (0..1) — doc 05 §8.1.
  final double nPriority;
  final double pPriority;
  final double kPriority;

  /// Rango relativo objetivo 0..1 por nutriente — doc 05 §9 (nRelativeTarget…).
  final AgroRange nTargetRange;
  final AgroRange pTargetRange;
  final AgroRange kTargetRange;

  /// Pesos AgroScore — doc 05 §10.
  final double wMoisture;
  final double wSoilTemp;
  final double wPh;
  final double wEc;
  final double wResistance;
  final double wNpk;

  final String confidence;
  final String careNoteEs;
  final String uxGuidanceEs;
  final String nWindowEs;
  final String pWindowEs;
  final String kWindowEs;
}

/// Tabla maestra cableada desde el documento 05. Llave = TreeStageIds.
const Map<String, _AppleStageProfile>
_appleStageProfiles = <String, _AppleStageProfile>{
  TreeStageIds.plantingTransplant: _AppleStageProfile(
    moisture: AgroRange(
      lowMax: 65,
      optimalMin: 65,
      optimalMax: 85,
      highMin: 85,
    ),
    soilTemp: AgroRange(
      lowMax: 12,
      optimalMin: 12,
      optimalMax: 24,
      highMin: 24,
    ),
    ec: AgroRange(lowMax: 0.2, optimalMin: 0.2, optimalMax: 1.5, highMin: 2.0),
    resistance: AgroRange(
      lowMax: 0.1,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.0,
    ),
    nPriority: 0.25,
    pPriority: 0.80,
    kPriority: 0.40,
    nTargetRange: AgroRange(
      lowMax: 20,
      optimalMin: 20,
      optimalMax: 40,
      highMin: 40,
    ),
    pTargetRange: AgroRange(
      lowMax: 60,
      optimalMin: 60,
      optimalMax: 80,
      highMin: 80,
    ),
    kTargetRange: AgroRange(
      lowMax: 35,
      optimalMin: 35,
      optimalMax: 55,
      highMin: 55,
    ),
    wMoisture: 0.25,
    wSoilTemp: 0.15,
    wPh: 0.15,
    wEc: 0.20,
    wResistance: 0.15,
    wNpk: 0.10,
    confidence: 'medium',
    careNoteEs: 'Raíz, baja salinidad y no quemar el árbol recién plantado.',
    uxGuidanceEs:
        'Tu manzano está recién colocado. La prioridad no es empujar '
        'fertilizante: es raíz, humedad estable, baja salinidad y suelo sin '
        'compactación. El fósforo pesa más que el nitrógeno en esta fase.',
    nWindowEs: 'N bajo: priorizar raíz',
    pWindowEs: 'Ventana de raíz: P alto',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.rootEstablishment: _AppleStageProfile(
    moisture: AgroRange(
      lowMax: 65,
      optimalMin: 65,
      optimalMax: 90,
      highMin: 90,
    ),
    soilTemp: AgroRange(
      lowMax: 12,
      optimalMin: 12,
      optimalMax: 24,
      highMin: 24,
    ),
    ec: AgroRange(lowMax: 0.2, optimalMin: 0.2, optimalMax: 1.5, highMin: 2.0),
    resistance: AgroRange(
      lowMax: 0.1,
      optimalMin: 0.0,
      optimalMax: 1.5,
      highMin: 2.0,
    ),
    nPriority: 0.35,
    pPriority: 0.85,
    kPriority: 0.45,
    nTargetRange: AgroRange(
      lowMax: 25,
      optimalMin: 25,
      optimalMax: 45,
      highMin: 45,
    ),
    pTargetRange: AgroRange(
      lowMax: 60,
      optimalMin: 60,
      optimalMax: 80,
      highMin: 80,
    ),
    kTargetRange: AgroRange(
      lowMax: 35,
      optimalMin: 35,
      optimalMax: 60,
      highMin: 60,
    ),
    wMoisture: 0.30,
    wSoilTemp: 0.12,
    wPh: 0.12,
    wEc: 0.18,
    wResistance: 0.18,
    wNpk: 0.10,
    confidence: 'medium',
    careNoteEs: 'Raíz fina, humedad estable, EC baja, compactación baja.',
    uxGuidanceEs:
        'El árbol está formando raíz fina. Mantén humedad estable sin '
        'saturar. Fósforo y condición de suelo pesan más que nitrógeno alto.',
    nWindowEs: 'N de apoyo',
    pWindowEs: 'Raíz fina: P alto',
    kWindowEs: 'K de apoyo',
  ),
  TreeStageIds.juvenileVegetative: _AppleStageProfile(
    moisture: AgroRange(
      lowMax: 60,
      optimalMin: 60,
      optimalMax: 85,
      highMin: 85,
    ),
    soilTemp: AgroRange(
      lowMax: 12,
      optimalMin: 12,
      optimalMax: 26,
      highMin: 26,
    ),
    ec: AgroRange(lowMax: 0.2, optimalMin: 0.2, optimalMax: 1.7, highMin: 2.2),
    resistance: AgroRange(
      lowMax: 0.1,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.1,
    ),
    nPriority: 0.75,
    pPriority: 0.55,
    kPriority: 0.55,
    nTargetRange: AgroRange(
      lowMax: 55,
      optimalMin: 55,
      optimalMax: 75,
      highMin: 75,
    ),
    pTargetRange: AgroRange(
      lowMax: 45,
      optimalMin: 45,
      optimalMax: 65,
      highMin: 65,
    ),
    kTargetRange: AgroRange(
      lowMax: 45,
      optimalMin: 45,
      optimalMax: 65,
      highMin: 65,
    ),
    wMoisture: 0.22,
    wSoilTemp: 0.12,
    wPh: 0.12,
    wEc: 0.12,
    wResistance: 0.15,
    wNpk: 0.27,
    confidence: 'medium',
    careNoteEs: 'Formar estructura sin provocar vigor blando excesivo.',
    uxGuidanceEs:
        'El árbol joven necesita crecer y formar estructura. El nitrógeno '
        'importa, pero si hay exceso puede producir brotes blandos y atrasar '
        'la entrada a producción.',
    nWindowEs: 'Construcción de copa: N útil',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.dormancy: _AppleStageProfile(
    moisture: AgroRange(
      lowMax: 50,
      optimalMin: 50,
      optimalMax: 75,
      highMin: 75,
    ),
    soilTemp: AgroRange(lowMax: 4, optimalMin: 4, optimalMax: 16, highMin: 16),
    ec: AgroRange(lowMax: 0.2, optimalMin: 0.2, optimalMax: 1.8, highMin: 2.3),
    resistance: AgroRange(
      lowMax: 0.1,
      optimalMin: 0.0,
      optimalMax: 2.0,
      highMin: 2.5,
    ),
    nPriority: 0.10,
    pPriority: 0.20,
    kPriority: 0.20,
    nTargetRange: AgroRange(
      lowMax: 20,
      optimalMin: 20,
      optimalMax: 40,
      highMin: 40,
    ),
    pTargetRange: AgroRange(
      lowMax: 30,
      optimalMin: 30,
      optimalMax: 50,
      highMin: 50,
    ),
    kTargetRange: AgroRange(
      lowMax: 30,
      optimalMin: 30,
      optimalMax: 50,
      highMin: 50,
    ),
    wMoisture: 0.20,
    wSoilTemp: 0.20,
    wPh: 0.20,
    wEc: 0.20,
    wResistance: 0.15,
    wNpk: 0.05,
    confidence: 'low',
    careNoteEs:
        'Demanda baja; no sobreinterpretar NPK. Revisar pH, salinidad y '
        'reservas.',
    uxGuidanceEs:
        'El árbol está en reposo. La demanda NPK es baja. Es mejor revisar '
        'pH, salinidad, compactación y preparar el arranque de brotación.',
    nWindowEs: 'Reposo: demanda baja',
    pWindowEs: 'Reposo: demanda baja',
    kWindowEs: 'Reposo: demanda baja',
  ),
  TreeStageIds.budbreak: _AppleStageProfile(
    moisture: AgroRange(
      lowMax: 60,
      optimalMin: 60,
      optimalMax: 85,
      highMin: 85,
    ),
    soilTemp: AgroRange(
      lowMax: 10,
      optimalMin: 10,
      optimalMax: 22,
      highMin: 22,
    ),
    ec: AgroRange(lowMax: 0.2, optimalMin: 0.2, optimalMax: 1.6, highMin: 2.0),
    resistance: AgroRange(
      lowMax: 0.1,
      optimalMin: 0.0,
      optimalMax: 1.7,
      highMin: 2.1,
    ),
    nPriority: 0.65,
    pPriority: 0.60,
    kPriority: 0.55,
    nTargetRange: AgroRange(
      lowMax: 50,
      optimalMin: 50,
      optimalMax: 70,
      highMin: 70,
    ),
    pTargetRange: AgroRange(
      lowMax: 50,
      optimalMin: 50,
      optimalMax: 70,
      highMin: 70,
    ),
    kTargetRange: AgroRange(
      lowMax: 45,
      optimalMin: 45,
      optimalMax: 65,
      highMin: 65,
    ),
    wMoisture: 0.22,
    wSoilTemp: 0.18,
    wPh: 0.12,
    wEc: 0.12,
    wResistance: 0.11,
    wNpk: 0.25,
    confidence: 'medium',
    careNoteEs:
        'Arranque depende de reservas; no sobrefertilizar si suelo frío.',
    uxGuidanceEs:
        'El árbol está arrancando. Parte del arranque viene de reservas del '
        'año anterior. N moderado, P suficiente y humedad estable ayudan, '
        'pero con suelo frío la absorción puede ser lenta.',
    nWindowEs: 'Arranque: N moderado',
    pWindowEs: 'P suficiente para brotación',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.vegetativeGrowth: _AppleStageProfile(
    moisture: AgroRange(
      lowMax: 60,
      optimalMin: 60,
      optimalMax: 85,
      highMin: 85,
    ),
    soilTemp: AgroRange(
      lowMax: 12,
      optimalMin: 12,
      optimalMax: 26,
      highMin: 26,
    ),
    ec: AgroRange(lowMax: 0.2, optimalMin: 0.2, optimalMax: 1.7, highMin: 2.2),
    resistance: AgroRange(
      lowMax: 0.1,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.2,
    ),
    nPriority: 0.70,
    pPriority: 0.45,
    kPriority: 0.60,
    nTargetRange: AgroRange(
      lowMax: 55,
      optimalMin: 55,
      optimalMax: 75,
      highMin: 75,
    ),
    pTargetRange: AgroRange(
      lowMax: 40,
      optimalMin: 40,
      optimalMax: 60,
      highMin: 60,
    ),
    kTargetRange: AgroRange(
      lowMax: 50,
      optimalMin: 50,
      optimalMax: 70,
      highMin: 70,
    ),
    wMoisture: 0.20,
    wSoilTemp: 0.12,
    wPh: 0.10,
    wEc: 0.12,
    wResistance: 0.11,
    wNpk: 0.35,
    confidence: 'medium',
    careNoteEs:
        'Hoja funcional y brotes; controlar exceso de N, sobre todo tarde.',
    uxGuidanceEs:
        'Etapa de hoja y brote. Nitrógeno útil, pero controlado. Demasiado N '
        'puede generar vigor excesivo, más sombra y menos calidad después.',
    nWindowEs: 'Crecimiento: N útil controlado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'K de acompañamiento',
  ),
  TreeStageIds.flowering: _AppleStageProfile(
    moisture: AgroRange(
      lowMax: 65,
      optimalMin: 65,
      optimalMax: 90,
      highMin: 90,
    ),
    soilTemp: AgroRange(
      lowMax: 12,
      optimalMin: 12,
      optimalMax: 24,
      highMin: 24,
    ),
    ec: AgroRange(lowMax: 0.2, optimalMin: 0.2, optimalMax: 1.5, highMin: 2.0),
    resistance: AgroRange(
      lowMax: 0.1,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.0,
    ),
    nPriority: 0.35,
    pPriority: 0.70,
    kPriority: 0.65,
    nTargetRange: AgroRange(
      lowMax: 30,
      optimalMin: 30,
      optimalMax: 50,
      highMin: 50,
    ),
    pTargetRange: AgroRange(
      lowMax: 55,
      optimalMin: 55,
      optimalMax: 75,
      highMin: 75,
    ),
    kTargetRange: AgroRange(
      lowMax: 55,
      optimalMin: 55,
      optimalMax: 75,
      highMin: 75,
    ),
    wMoisture: 0.30,
    wSoilTemp: 0.20,
    wPh: 0.10,
    wEc: 0.15,
    wResistance: 0.10,
    wNpk: 0.15,
    confidence: 'high',
    careNoteEs:
        'Floración usa reservas; no empujar solo N. Agua estable; B/Ca/Zn '
        'como contexto.',
    uxGuidanceEs:
        'Floración es crítica. No conviene empujar solo nitrógeno. '
        'Prioridad: agua estable, temperatura adecuada, P/K suficientes y '
        'revisar boro/zinc/calcio si hay historial de mal cuajado.',
    nWindowEs: 'Floración: no empujar N',
    pWindowEs: 'Floración: P relevante',
    kWindowEs: 'Floración: K relevante',
  ),
  TreeStageIds.fruitSet: _AppleStageProfile(
    moisture: AgroRange(
      lowMax: 65,
      optimalMin: 65,
      optimalMax: 90,
      highMin: 90,
    ),
    soilTemp: AgroRange(
      lowMax: 14,
      optimalMin: 14,
      optimalMax: 26,
      highMin: 26,
    ),
    ec: AgroRange(lowMax: 0.2, optimalMin: 0.2, optimalMax: 1.5, highMin: 2.0),
    resistance: AgroRange(
      lowMax: 0.1,
      optimalMin: 0.0,
      optimalMax: 1.6,
      highMin: 2.0,
    ),
    nPriority: 0.35,
    pPriority: 0.55,
    kPriority: 0.75,
    nTargetRange: AgroRange(
      lowMax: 30,
      optimalMin: 30,
      optimalMax: 50,
      highMin: 50,
    ),
    pTargetRange: AgroRange(
      lowMax: 45,
      optimalMin: 45,
      optimalMax: 65,
      highMin: 65,
    ),
    kTargetRange: AgroRange(
      lowMax: 60,
      optimalMin: 60,
      optimalMax: 80,
      highMin: 80,
    ),
    wMoisture: 0.32,
    wSoilTemp: 0.15,
    wPh: 0.08,
    wEc: 0.18,
    wResistance: 0.10,
    wNpk: 0.17,
    confidence: 'high',
    careNoteEs:
        'Amarre, aborto de fruto, estrés hídrico, salinidad y balance Ca/Mg.',
    uxGuidanceEs:
        'En cuajado, el árbol decide qué fruta sostiene. Evita déficit '
        'hídrico, salinidad y calor. K empieza a pesar más, pero el balance '
        'con Ca/Mg importa.',
    nWindowEs: 'Cuajado: N moderado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Cuajado: K empieza a pesar',
  ),
  TreeStageIds.fruitFill: _AppleStageProfile(
    moisture: AgroRange(
      lowMax: 65,
      optimalMin: 65,
      optimalMax: 90,
      highMin: 90,
    ),
    soilTemp: AgroRange(
      lowMax: 16,
      optimalMin: 16,
      optimalMax: 28,
      highMin: 28,
    ),
    ec: AgroRange(lowMax: 0.2, optimalMin: 0.2, optimalMax: 1.6, highMin: 2.1),
    resistance: AgroRange(
      lowMax: 0.1,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.2,
    ),
    nPriority: 0.30,
    pPriority: 0.40,
    kPriority: 0.88,
    nTargetRange: AgroRange(
      lowMax: 25,
      optimalMin: 25,
      optimalMax: 45,
      highMin: 45,
    ),
    pTargetRange: AgroRange(
      lowMax: 35,
      optimalMin: 35,
      optimalMax: 55,
      highMin: 55,
    ),
    kTargetRange: AgroRange(
      lowMax: 70,
      optimalMin: 70,
      optimalMax: 90,
      highMin: 90,
    ),
    wMoisture: 0.26,
    wSoilTemp: 0.12,
    wPh: 0.08,
    wEc: 0.14,
    wResistance: 0.08,
    wNpk: 0.32,
    confidence: 'high',
    careNoteEs: 'Calibre, azúcares, firmeza, color; vigilar K alto vs Ca/Mg.',
    uxGuidanceEs:
        'En llenado, K gana prioridad para calibre, azúcar y calidad. El '
        'nitrógeno debe mantenerse moderado-bajo; exceso puede afectar '
        'color, firmeza y madurez.',
    nWindowEs: 'Llenado: N bajo-moderado',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Llenado: K protagonista',
  ),
  TreeStageIds.harvestMaturity: _AppleStageProfile(
    moisture: AgroRange(
      lowMax: 60,
      optimalMin: 60,
      optimalMax: 85,
      highMin: 85,
    ),
    soilTemp: AgroRange(
      lowMax: 14,
      optimalMin: 14,
      optimalMax: 28,
      highMin: 28,
    ),
    ec: AgroRange(lowMax: 0.2, optimalMin: 0.2, optimalMax: 1.7, highMin: 2.2),
    resistance: AgroRange(
      lowMax: 0.1,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.2,
    ),
    nPriority: 0.18,
    pPriority: 0.30,
    kPriority: 0.70,
    nTargetRange: AgroRange(
      lowMax: 18,
      optimalMin: 18,
      optimalMax: 40,
      highMin: 40,
    ),
    pTargetRange: AgroRange(
      lowMax: 25,
      optimalMin: 25,
      optimalMax: 50,
      highMin: 50,
    ),
    kTargetRange: AgroRange(
      lowMax: 60,
      optimalMin: 60,
      optimalMax: 80,
      highMin: 80,
    ),
    wMoisture: 0.20,
    wSoilTemp: 0.12,
    wPh: 0.08,
    wEc: 0.12,
    wResistance: 0.08,
    wNpk: 0.40,
    confidence: 'medium',
    careNoteEs: 'Evitar exceso de N; calidad, color, madurez y almacenamiento.',
    uxGuidanceEs:
        'Cerca de cosecha, no cierres el cultivo ni empujes N de más. '
        'Prioridad: calidad, madurez, color, firmeza y evitar estrés.',
    nWindowEs: 'Madurez: evitar N alto',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Madurez: K útil',
  ),
  TreeStageIds.postHarvest: _AppleStageProfile(
    moisture: AgroRange(
      lowMax: 55,
      optimalMin: 55,
      optimalMax: 80,
      highMin: 80,
    ),
    soilTemp: AgroRange(
      lowMax: 10,
      optimalMin: 10,
      optimalMax: 24,
      highMin: 24,
    ),
    ec: AgroRange(lowMax: 0.2, optimalMin: 0.2, optimalMax: 1.7, highMin: 2.2),
    resistance: AgroRange(
      lowMax: 0.1,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.2,
    ),
    nPriority: 0.60,
    pPriority: 0.35,
    kPriority: 0.65,
    nTargetRange: AgroRange(
      lowMax: 40,
      optimalMin: 40,
      optimalMax: 65,
      highMin: 65,
    ),
    pTargetRange: AgroRange(
      lowMax: 35,
      optimalMin: 35,
      optimalMax: 55,
      highMin: 55,
    ),
    kTargetRange: AgroRange(
      lowMax: 45,
      optimalMin: 45,
      optimalMax: 70,
      highMin: 70,
    ),
    wMoisture: 0.24,
    wSoilTemp: 0.14,
    wPh: 0.12,
    wEc: 0.14,
    wResistance: 0.10,
    wNpk: 0.26,
    confidence: 'medium',
    careNoteEs:
        'Recuperación de reservas para el siguiente ciclo; solo si hay hoja '
        'activa y raíz activa.',
    uxGuidanceEs:
        'Después de cosecha el árbol sigue trabajando. Si todavía hay hoja '
        'activa, humedad adecuada y temperatura suficiente, esta etapa ayuda '
        'a recuperar reservas para el siguiente ciclo.',
    nWindowEs: 'Postcosecha: N de reservas (con hoja activa)',
    pWindowEs: 'P de acompañamiento',
    kWindowEs: 'Postcosecha: K de reservas',
  ),
  TreeStageIds.unknown: _AppleStageProfile(
    moisture: AgroRange(
      lowMax: 60,
      optimalMin: 60,
      optimalMax: 85,
      highMin: 85,
    ),
    soilTemp: AgroRange(
      lowMax: 12,
      optimalMin: 12,
      optimalMax: 26,
      highMin: 26,
    ),
    ec: AgroRange(lowMax: 0.2, optimalMin: 0.2, optimalMax: 1.7, highMin: 2.2),
    resistance: AgroRange(
      lowMax: 0.1,
      optimalMin: 0.0,
      optimalMax: 1.8,
      highMin: 2.2,
    ),
    nPriority: 0.45,
    pPriority: 0.45,
    kPriority: 0.50,
    nTargetRange: AgroRange(
      lowMax: 40,
      optimalMin: 40,
      optimalMax: 65,
      highMin: 65,
    ),
    pTargetRange: AgroRange(
      lowMax: 40,
      optimalMin: 40,
      optimalMax: 65,
      highMin: 65,
    ),
    kTargetRange: AgroRange(
      lowMax: 40,
      optimalMin: 40,
      optimalMax: 70,
      highMin: 70,
    ),
    wMoisture: 0.25,
    wSoilTemp: 0.15,
    wPh: 0.15,
    wEc: 0.15,
    wResistance: 0.15,
    wNpk: 0.15,
    confidence: 'low',
    careNoteEs: 'Conservador; pedir etapa visible o análisis.',
    uxGuidanceEs:
        'Con etapa desconocida, BIO-G usa un perfil conservador. Para mayor '
        'precisión, indica si el árbol está brotando, floreando, con fruto '
        'verde, madurando o después de cosecha.',
    nWindowEs: 'Etapa no definida',
    pWindowEs: 'Etapa no definida',
    kWindowEs: 'Etapa no definida',
  ),
};

_AppleStageProfile _profileForStage(String? stageId) {
  final id = normalizeTreeStageId(stageId);
  return _appleStageProfiles[id] ?? _appleStageProfiles[TreeStageIds.unknown]!;
}

/// Convierte el rango ÓPTIMO de suficiencia (mg/kg) del doc 05 en un
/// [AgroRange] comparable con BANDAS SUAVES para que el motor compartido
/// (`NutrientTargetRangeResolver` + `NutrientRecommendationEngine`) detecte
/// bajo / óptimo / alto-útil / exceso sin saltos bruscos óptimo→crítico.
///
/// Bandas resultantes (regla del manzano, decisión del usuario):
/// - `< lowMax`               → crítico / "Urge aplicar" (déficit fuerte).
/// - `lowMax .. optimalMin`   → "Bajo" (déficit suave, prioridad gradual).
/// - `optimalMin .. optimalMax` → "Óptimo".
/// - `optimalMax .. highMin`  → "Alto útil": zona amplia y tolerante por
///   encima del óptimo. En manzano estar alto NO es malo; el motor del árbol
///   la trata casi como óptimo (sin penalización ni alerta).
/// - `>= highMin`             → "Exceso" real (claramente desproporcionado):
///   esto sí baja el score y genera advertencia.
///
/// Los multiplicadores (0.65 abajo, 1.5 arriba) son una elección de ingeniería
/// documentada: el doc 05 sólo fija el óptimo relativo por etapa, no las colas.
/// 1.5× sobre el óptimo deja, p. ej., N de fruto (25–45) con exceso a partir de
/// ~67 mg/kg, de modo que N≈71 cae en exceso (≈1.6× el tope óptimo) mientras
/// que un N moderadamente alto (≈50) queda en "alto útil" tolerante.
AgroRange _appleSoilPpmRange(AgroRange optimal) {
  final double optMin = optimal.optimalMin;
  final double optMax = optimal.optimalMax;
  return AgroRange(
    lowMax: optMin * 0.65,
    optimalMin: optMin,
    optimalMax: optMax,
    highMin: optMax * 1.5,
  );
}

/// Targets de sensor por etapa para `resolveTargets` del manzano (doc 05 §9).
///
/// Incluye los rangos de suelo (humedad/temp/pH/EC/resistencia) y la semántica
/// NPK relativa por etapa (prioridad + ventana + guía corta). NO contiene
/// dosis: los `nIndex/pIndex/kIndex` legacy reflejan el rango relativo 0..1
/// escalado a 0..100.
StageTargets resolveAppleTreeTargets(String? stageId) {
  final p = _profileForStage(stageId);
  return StageTargets(
    moistureRaw: p.moisture,
    soilTemp: p.soilTemp,
    ph: AppleTreeUniversalProfile._phUniversal,
    ec: p.ec,
    resistance: p.resistance,
    nIndex: p.nTargetRange,
    pIndex: p.pTargetRange,
    kIndex: p.kTargetRange,
    // Rangos comparables REALES de suelo (mg/kg). Con esto el resolver usa los
    // ppm directamente (sin escalar por cap), así el detalle NPK muestra el
    // objetivo correcto (p. ej. N 20–40) y no el escalado legacy (22–48).
    nSoilPpmRange: _appleSoilPpmRange(p.nTargetRange),
    pSoilPpmRange: _appleSoilPpmRange(p.pTargetRange),
    kSoilPpmRange: _appleSoilPpmRange(p.kTargetRange),
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

/// Pesos AgroScore por etapa (doc 05 §10). Suma aproximada de 1.0 por etapa.
StageWeights resolveAppleTreeStageWeights(String? stageId) {
  final p = _profileForStage(stageId);
  return StageWeights(
    moisture: p.wMoisture,
    soilTemp: p.wSoilTemp,
    resistance: p.wResistance,
    ph: p.wPh,
    ec: p.wEc,
    npk: p.wNpk,
  );
}

/// Prioridades NPK relativas + nota UX por etapa (doc 05 §8).
AppleTreeStageNutrition resolveAppleTreeNutritionPriorities(String? stageId) {
  final p = _profileForStage(stageId);
  return AppleTreeStageNutrition(
    stageId: normalizeTreeStageId(stageId),
    nPriority01: p.nPriority,
    pPriority01: p.pPriority,
    kPriority01: p.kPriority,
    confidence: p.confidence,
    careNoteEs: p.careNoteEs,
  );
}

/// Guía UX corta por etapa (doc 05 §12) para tarjetas/resúmenes del manzano.
String appleTreeStageGuidanceEs(String? stageId) =>
    _profileForStage(stageId).uxGuidanceEs;
