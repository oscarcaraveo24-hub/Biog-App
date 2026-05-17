import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/lettuce_models.dart';

/// Perfil Universal BIO-G de lechuga (`crop_lettuce` v1.1).
///
/// Contiene targets sensoriales y pesos de score por etapa para la
/// familia `CropKey.lettuce`. La fuente son las secciones 5 (rangos
/// fisiológicos), 6 (NPK por etapa) y 9 (ponderación AgroScore) del
/// Perfil Universal revisado.
///
/// IMPORTANTE para v1:
/// - La fertilización activa es NPK. Ca/Mg/S reciben prioridad
///   informativa pero NO generan dosis ni alertas principales (el Ca de
///   tip burn queda como diagnóstico visual/futuro).
/// - Agua estable, temperatura y salinidad son los cuellos reales del
///   cultivo; E4 (formación de cabeza) y E5 (ventana de cosecha) pesan
///   más porque ahí se decide el valor comercial.
class LettuceUniversalProfile {
  const LettuceUniversalProfile({
    required this.byStage,
    required this.weights,
  });

  final Map<LettuceStageKey, StageTargets> byStage;
  final Map<LettuceStageKey, StageWeights> weights;
}

// ─────────────────────────────────────────────────────────────────────
// Rangos sensoriales BIO-G v1.1 §5.
// pH operativo 6.0-6.8; observación 5.8-7.2; alerta <5.8 / >7.5.
// ECe <1.3 dS/m segura; 1.3-2.0 observación; >2.0 alerta; >3.0 crítico.
// Lechuga es cultivo sensible: raíz superficial, ciclo corto.
// ─────────────────────────────────────────────────────────────────────
const AgroRange _phStd = AgroRange(
  lowMax: 5.6,
  optimalMin: 6.0,
  optimalMax: 6.8,
  highMin: 7.4,
);

// Salinidad: cultivo sensible. 1.3 ya marca pérdida potencial.
const AgroRange _ecStd = AgroRange(
  lowMax: 0.0,
  optimalMin: 0.0,
  optimalMax: 1.3,
  highMin: 2.0,
);

// Cierre de ciclo: tolera algo más de CE acumulada sin castigar igual.
const AgroRange _ecLate = AgroRange(
  lowMax: 0.0,
  optimalMin: 0.0,
  optimalMax: 1.6,
  highMin: 2.4,
);

// Compactación: raíz superficial; <2.0 MPa óptimo, >=2.0 alerta, >3.0 crítico.
const AgroRange _resistance = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 2.0,
  highMin: 3.0,
);

// Suelo de germinación: óptimo 15-22 °C; riesgo de termoinhibición >26-28.
const AgroRange _soilTempGerm = AgroRange(
  lowMax: 9,
  optimalMin: 15,
  optimalMax: 22,
  highMin: 27,
);

// Suelo en etapas activas: lechuga es de estación fresca.
const AgroRange _soilTempStd = AgroRange(
  lowMax: 7,
  optimalMin: 14,
  optimalMax: 24,
  highMin: 30,
);

// Agua disponible 60-95% óptimo; <50% déficit; >100% saturación/anoxia.
const AgroRange _moistureActive = AgroRange(
  lowMax: 50,
  optimalMin: 60,
  optimalMax: 95,
  highMin: 100,
);

// Sobre-madurez: humedad menos crítica, pero el suelo no debe secarse.
const AgroRange _moistureLate = AgroRange(
  lowMax: 42,
  optimalMin: 55,
  optimalMax: 92,
  highMin: 100,
);

StageTargets _targets({
  required AgroRange moisture,
  required AgroRange soilTemp,
  required AgroRange ph,
  required AgroRange ec,
  required double nLow,
  required double nOptMin,
  required double nOptMax,
  required double pLow,
  required double pOptMin,
  required double pOptMax,
  required double kLow,
  required double kOptMin,
  required double kOptMax,
  required double nPriority,
  required double pPriority,
  required double kPriority,
  required double caPriority,
  required double mgPriority,
  required double sPriority,
  required String nWindow,
  required String pWindow,
  required String kWindow,
  required String nGuide,
  required String pGuide,
  required String kGuide,
  required String caGuide,
  required String mgGuide,
  required String sGuide,
  String? nHint,
  String? pHint,
  String? kHint,
  double confidence = 0.78,
}) {
  AgroRange idx(double p) => AgroRange(
        lowMax: (p * 100 - 12).clamp(0, 100).toDouble(),
        optimalMin: (p * 100 - 5).clamp(0, 100).toDouble(),
        optimalMax: (p * 100 + 12).clamp(0, 100).toDouble(),
        highMin: (p * 100 + 22).clamp(0, 100).toDouble(),
      );

  AgroRange ppm(double low, double min, double max) => AgroRange(
        lowMax: low,
        optimalMin: min,
        optimalMax: max,
        highMin: max + (max - min) * 0.55,
      );

  return StageTargets(
    moistureRaw: moisture,
    soilTemp: soilTemp,
    ph: ph,
    ec: ec,
    resistance: _resistance,
    nIndex: idx(nPriority),
    pIndex: idx(pPriority),
    kIndex: idx(kPriority),
    nSoilPpmRange: ppm(nLow, nOptMin, nOptMax),
    pSoilPpmRange: ppm(pLow, pOptMin, pOptMax),
    kSoilPpmRange: ppm(kLow, kOptMin, kOptMax),
    nPriority: nPriority,
    pPriority: pPriority,
    kPriority: kPriority,
    caPriority: caPriority,
    mgPriority: mgPriority,
    sPriority: sPriority,
    nWindowLabelEs: nWindow,
    pWindowLabelEs: pWindow,
    kWindowLabelEs: kWindow,
    nShortGuidanceEs: nGuide,
    pShortGuidanceEs: pGuide,
    kShortGuidanceEs: kGuide,
    caShortGuidanceEs: caGuide,
    mgShortGuidanceEs: mgGuide,
    sShortGuidanceEs: sGuide,
    nPlannerHintEs: nHint,
    pPlannerHintEs: pHint,
    kPlannerHintEs: kHint,
    nConfidence01: confidence,
    pConfidence01: confidence,
    kConfidence01: confidence,
  );
}

final LettuceUniversalProfile lettuceUniversalV1 = LettuceUniversalProfile(
  byStage: <LettuceStageKey, StageTargets>{
    LettuceStageKey.germinacion: _targets(
      moisture: _moistureActive,
      soilTemp: _soilTempGerm,
      ph: _phStd,
      ec: _ecStd,
      nLow: 12,
      nOptMin: 16,
      nOptMax: 30,
      pLow: 22,
      pOptMin: 30,
      pOptMax: 46,
      kLow: 45,
      kOptMin: 58,
      kOptMax: 88,
      nPriority: 0.14,
      pPriority: 0.42,
      kPriority: 0.22,
      caPriority: 0.28,
      mgPriority: 0.22,
      sPriority: 0.16,
      nWindow: 'Arranque sin presión de N',
      pWindow: 'Soporte mínimo de raíz',
      kWindow: 'Reserva mínima',
      nGuide: 'No empujar N en germinación; la semilla usa reservas y las sales bajas mandan.',
      pGuide: 'P apenas como base para raíz incipiente.',
      kGuide: 'K solo en mínimos; cuidar CE para no frenar la germinación.',
      caGuide: 'Ca de base como contexto agronómico, sin dosis activa v1.',
      mgGuide: 'Mg en mantenimiento.',
      sGuide: 'S sin protagonismo.',
      confidence: 0.68,
    ),
    LettuceStageKey.establecimiento: _targets(
      moisture: _moistureActive,
      soilTemp: _soilTempStd,
      ph: _phStd,
      ec: _ecStd,
      nLow: 24,
      nOptMin: 32,
      nOptMax: 52,
      pLow: 36,
      pOptMin: 46,
      pOptMax: 66,
      kLow: 60,
      kOptMin: 78,
      kOptMax: 115,
      nPriority: 0.40,
      pPriority: 0.78,
      kPriority: 0.42,
      caPriority: 0.40,
      mgPriority: 0.28,
      sPriority: 0.20,
      nWindow: 'Soporte moderado',
      pWindow: 'Pegue y raíz',
      kWindow: 'Balance inicial',
      nGuide: 'N suave acompaña el establecimiento; sin pulsos altos en raíz joven.',
      pGuide: 'P es clave para que la raíz superficial enraíce bien.',
      kGuide: 'K como balance temprano, sin subir sales.',
      caGuide: 'Ca y Mg como contexto; v1 no genera dosis.',
      mgGuide: 'Mg apoya las primeras hojas verdaderas.',
      sGuide: 'S en soporte base.',
      nHint: 'Evitar pulsos altos de N: la chupadera se favorece con tejido tierno y exceso de agua.',
      pHint: 'Corregir P temprano si la lectura queda corta.',
      kHint: 'Mantener K base sin cargar CE.',
      confidence: 0.80,
    ),
    LettuceStageKey.desarrolloVegetativo: _targets(
      moisture: _moistureActive,
      soilTemp: _soilTempStd,
      ph: _phStd,
      ec: _ecStd,
      nLow: 45,
      nOptMin: 58,
      nOptMax: 88,
      pLow: 26,
      pOptMin: 34,
      pOptMax: 52,
      kLow: 80,
      kOptMin: 100,
      kOptMax: 140,
      nPriority: 0.80,
      pPriority: 0.48,
      kPriority: 0.58,
      caPriority: 0.44,
      mgPriority: 0.40,
      sPriority: 0.26,
      nWindow: 'Alta demanda foliar',
      pWindow: 'Soporte de P',
      kWindow: 'Reserva antes de cabeza',
      nGuide: 'Etapa de mayor demanda de N para hoja; suficiente sin exceder para no ablandar tejido.',
      pGuide: 'P pasa a soporte; la respuesta fuerte ya quedó en arranque.',
      kGuide: 'K sube de cara a la formación de cabeza y la turgencia.',
      caGuide: 'Ca como contexto; el riesgo de tip burn se maneja con agua y ventilación.',
      mgGuide: 'Mg sostiene fotosíntesis y hoja sana.',
      sGuide: 'S acompaña el vigor general.',
      nHint: 'No llegar a cabeza con planta sobre-vegetada: el exceso de N favorece Botrytis y tip burn.',
      kHint: 'Preparar reserva de K antes de que cierre la cabeza.',
      confidence: 0.84,
    ),
    LettuceStageKey.formacionCabeza: _targets(
      moisture: _moistureActive,
      soilTemp: _soilTempStd,
      ph: _phStd,
      ec: _ecStd,
      nLow: 32,
      nOptMin: 42,
      nOptMax: 66,
      pLow: 22,
      pOptMin: 30,
      pOptMax: 48,
      kLow: 100,
      kOptMin: 125,
      kOptMax: 165,
      nPriority: 0.50,
      pPriority: 0.40,
      kPriority: 0.80,
      caPriority: 0.52,
      mgPriority: 0.42,
      sPriority: 0.30,
      nWindow: 'N moderado: no empujar crecimiento blando',
      pWindow: 'P de mantenimiento',
      kWindow: 'K para turgencia y calidad',
      nGuide: 'Reducir el impulso de N: el exceso ablanda la hoja y sube tip burn y enfermedades.',
      pGuide: 'P de soporte; rara vez es el cuello en esta etapa.',
      kGuide: 'K apoya turgencia, firmeza y calidad de la cabeza/roseta.',
      caGuide: 'Ca clave para tip burn: en v1 se maneja con ventilación y riego estable, no como dosis.',
      mgGuide: 'Mg sostiene hoja activa hasta cosecha.',
      sGuide: 'S en soporte.',
      nHint: 'Evitar aplicaciones tardías de N cerca de cabeza cerrada: favorece hoja blanda y Botrytis.',
      kHint: 'Sostener K con humedad pareja, sin golpes salinos.',
      confidence: 0.86,
    ),
    LettuceStageKey.ventanaCosecha: _targets(
      moisture: _moistureActive,
      soilTemp: _soilTempStd,
      ph: _phStd,
      ec: _ecStd,
      nLow: 18,
      nOptMin: 24,
      nOptMax: 44,
      pLow: 18,
      pOptMin: 24,
      pOptMax: 42,
      kLow: 80,
      kOptMin: 100,
      kOptMax: 140,
      nPriority: 0.25,
      pPriority: 0.28,
      kPriority: 0.55,
      caPriority: 0.42,
      mgPriority: 0.34,
      sPriority: 0.24,
      nWindow: 'N a la baja: no empujar cerca de corte',
      pWindow: 'P de mantenimiento',
      kWindow: 'K de soporte de calidad',
      nGuide: 'No recomendar N fuerte cerca de cosecha: tejido tierno, menor vida de anaquel y posibles nitratos.',
      pGuide: 'P de mantenimiento; sin protagonismo en cosecha.',
      kGuide: 'K sostiene turgencia y firmeza al cortar.',
      caGuide: 'Ca informativo; la calidad depende más de agua y ventilación estables.',
      mgGuide: 'Mg sostiene color y hoja funcional.',
      sGuide: 'S acompaña.',
      nHint: 'BIO-G no recomienda aplicaciones fuertes de N cerca del corte; priorizar calidad y sanidad.',
      kHint: 'Mantener K constante y CE bajo control para cosechar con turgencia.',
      confidence: 0.82,
    ),
    LettuceStageKey.sobremadurez: _targets(
      moisture: _moistureLate,
      soilTemp: _soilTempStd,
      ph: _phStd,
      ec: _ecLate,
      nLow: 14,
      nOptMin: 18,
      nOptMax: 36,
      pLow: 16,
      pOptMin: 22,
      pOptMax: 40,
      kLow: 55,
      kOptMin: 72,
      kOptMax: 110,
      nPriority: 0.15,
      pPriority: 0.18,
      kPriority: 0.30,
      caPriority: 0.22,
      mgPriority: 0.20,
      sPriority: 0.16,
      nWindow: 'Cierre de N',
      pWindow: 'Cierre de P',
      kWindow: 'Cierre de K',
      nGuide: 'No corregir N tarde: la planta pasó su punto. Documentar y cerrar.',
      pGuide: 'Usar la lectura para la base del siguiente ciclo.',
      kGuide: 'K solo sostiene la cosecha residual; no empujar.',
      caGuide: 'Ca informativo; v1 no genera dosis.',
      mgGuide: 'Mg en mantenimiento.',
      sGuide: 'S en mantenimiento.',
      nHint: 'No invertir en N tarde; reservar la lectura para pre-siembra del próximo ciclo.',
      pHint: 'Usar la lectura de P para planear la base del siguiente ciclo.',
      kHint: 'Documentar K para trazabilidad del plan.',
      confidence: 0.64,
    ),
  },
  // Pesos por etapa (Perfil Universal §9). E4 y E5 pesan más: ahí se
  // decide el valor comercial. Agua y temperatura mandan en cosecha.
  weights: const <LettuceStageKey, StageWeights>{
    LettuceStageKey.germinacion: StageWeights(
      moisture: 0.32,
      soilTemp: 0.20,
      resistance: 0.10,
      ph: 0.10,
      ec: 0.14,
      npk: 0.14,
    ),
    LettuceStageKey.establecimiento: StageWeights(
      moisture: 0.30,
      soilTemp: 0.12,
      resistance: 0.16,
      ph: 0.10,
      ec: 0.14,
      npk: 0.18,
    ),
    LettuceStageKey.desarrolloVegetativo: StageWeights(
      moisture: 0.28,
      soilTemp: 0.10,
      resistance: 0.10,
      ph: 0.10,
      ec: 0.12,
      npk: 0.30,
    ),
    LettuceStageKey.formacionCabeza: StageWeights(
      moisture: 0.30,
      soilTemp: 0.16,
      resistance: 0.06,
      ph: 0.08,
      ec: 0.16,
      npk: 0.24,
    ),
    LettuceStageKey.ventanaCosecha: StageWeights(
      moisture: 0.30,
      soilTemp: 0.16,
      resistance: 0.06,
      ph: 0.08,
      ec: 0.16,
      npk: 0.24,
    ),
    LettuceStageKey.sobremadurez: StageWeights(
      moisture: 0.24,
      soilTemp: 0.10,
      resistance: 0.08,
      ph: 0.12,
      ec: 0.16,
      npk: 0.30,
    ),
  },
);
