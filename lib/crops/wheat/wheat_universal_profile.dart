import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/wheat_models.dart';

/// Perfil universal de trigo (cereal C3 de estación fresca).
///
/// Lógica NPK aplicada:
/// - Arranque: P pesa más por raíz, implantación y macollaje inicial.
/// - Vegetativo temprano: P sigue fuerte, N empieza a subir.
/// - Macollamiento / encañe / embuche: N manda y define macollos/espigas.
/// - Espigamiento / floración: N sigue siendo relevante, pero más para
///   calidad/proteína que para empujar fuerte el rendimiento.
/// - Llenado: K acompaña balance y sostén, pero no debe modelarse como
///   protagonista universal del trigo salvo que el suelo realmente venga corto.
/// - Madurez / cosecha: no vender correcciones tardías como solución principal.
///
/// Nota:
/// Este archivo solo modela prioridades, ventanas y pesos por etapa.
/// No realiza conversiones de ppm -> kg/ha -> fuente comercial -> escala de uso.
/// Eso debe resolverse en fertilization_planner / recommendation_engine.
class WheatUniversalProfile {
  const WheatUniversalProfile({required this.byStage, required this.weights});

  final Map<WheatStageKey, StageTargets> byStage;
  final Map<WheatStageKey, StageWeights> weights;
}

// ── pH diferenciado por grupo de etapa ──────────────────────────
// Trigo óptimo ~6.0–7.5. Se estrecha un poco en floración.
const AgroRange _wheatPhEarly = AgroRange(
  lowMax: 5.6,
  optimalMin: 6.0,
  optimalMax: 7.2,
  highMin: 7.6,
);

const AgroRange _wheatPhVeg = AgroRange(
  lowMax: 5.5,
  optimalMin: 5.8,
  optimalMax: 7.5,
  highMin: 8.0,
);

const AgroRange _wheatPhFlowering = AgroRange(
  lowMax: 5.8,
  optimalMin: 6.0,
  optimalMax: 7.2,
  highMin: 7.5,
);

const AgroRange _wheatPhLate = AgroRange(
  lowMax: 5.3,
  optimalMin: 5.6,
  optimalMax: 7.8,
  highMin: 8.2,
);

// ── EC diferenciado ─────────────────────────────────────────────
const AgroRange _wheatEcEarly = AgroRange(
  lowMax: 0.4,
  optimalMin: 0.5,
  optimalMax: 1.5,
  highMin: 3.0,
);

const AgroRange _wheatEcVeg = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 2.0,
  highMin: 4.0,
);

const AgroRange _wheatEcFlowering = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 1.8,
  highMin: 3.5,
);

const AgroRange _wheatEcLate = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 2.5,
  highMin: 5.0,
);

// ── Resistencia (MPa) ───────────────────────────────────────────
const AgroRange _wheatResistanceEarly = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 1.2,
  highMin: 2.0,
);

const AgroRange _wheatResistanceLate = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 1.6,
  highMin: 2.0,
);

const WheatUniversalProfile wheatUniversalV1 = WheatUniversalProfile(
  byStage: {
    // =========================
    // GERMINATION / EMERGENCE
    // =========================
    WheatStageKey.germination: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 14,
        optimalMin: 30,
        optimalMax: 72,
        highMin: 86,
      ),
      soilTemp: AgroRange(
        lowMax: 3,
        optimalMin: 10,
        optimalMax: 22,
        highMin: 30,
      ),
      ph: _wheatPhEarly,
      ec: _wheatEcEarly,
      resistance: _wheatResistanceEarly,
      nIndex: AgroRange(lowMax: 8, optimalMin: 16, optimalMax: 34, highMin: 52),
      pIndex: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 34, highMin: 48),
      kIndex: AgroRange(
        lowMax: 12,
        optimalMin: 22,
        optimalMax: 48,
        highMin: 68,
      ),
      nPriority: 0.42,
      pPriority: 0.86,
      kPriority: 0.48,
      nWindowLabelEs: 'Arranque moderado',
      pWindowLabelEs: 'Arranque y raíz',
      kWindowLabelEs: 'Base de balance',
      nShortGuidanceEs:
          'El N todavía no manda; evita cargar demasiado la siembra.',
      pShortGuidanceEs:
          'El P pesa fuerte desde el inicio para raíz y establecimiento.',
      kShortGuidanceEs:
          'El K acompaña el balance inicial, pero no desplaza al P en esta etapa.',
      nPlannerHintEs:
          'Usar N como arrancador moderado; guardar la mayor parte para macollamiento.',
      pPlannerHintEs:
          'Priorizar disponibilidad temprana y buena colocación cerca de la línea.',
      kPlannerHintEs:
          'Mantener una base suficiente sin sobrerreaccionar si el suelo no marca problema.',
      nConfidence01: 0.80,
      pConfidence01: 0.90,
      kConfidence01: 0.76,
    ),
    WheatStageKey.emergence: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 14,
        optimalMin: 30,
        optimalMax: 70,
        highMin: 85,
      ),
      soilTemp: AgroRange(
        lowMax: 3,
        optimalMin: 10,
        optimalMax: 22,
        highMin: 30,
      ),
      ph: _wheatPhEarly,
      ec: _wheatEcEarly,
      resistance: _wheatResistanceEarly,
      nIndex: AgroRange(lowMax: 8, optimalMin: 16, optimalMax: 34, highMin: 52),
      pIndex: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 34, highMin: 48),
      kIndex: AgroRange(
        lowMax: 12,
        optimalMin: 22,
        optimalMax: 48,
        highMin: 68,
      ),
      nPriority: 0.46,
      pPriority: 0.84,
      kPriority: 0.50,
      nWindowLabelEs: 'Despegue vegetativo',
      pWindowLabelEs: 'Arranque y raíz',
      kWindowLabelEs: 'Base de balance',
      nShortGuidanceEs:
          'El N empieza a subir, pero el arranque sigue dependiendo más de raíz.',
      pShortGuidanceEs:
          'Mantén P disponible desde el inicio para no frenar implantación.',
      kShortGuidanceEs:
          'El K acompaña el arranque sin volverse todavía el nutriente dominante.',
      nPlannerHintEs:
          'Sostener arranque sin sobredosificar N; preparar fase vegetativa.',
      pPlannerHintEs:
          'Favorecer disponibilidad temprana y buena ubicación del fósforo.',
      kPlannerHintEs:
          'Mantener base suficiente para estabilidad y vigor sin sobreprometer respuesta.',
      nConfidence01: 0.82,
      pConfidence01: 0.90,
      kConfidence01: 0.76,
    ),

    // =========================
    // VEGETATIVE
    // =========================
    WheatStageKey.vegEarly: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 12,
        optimalMin: 28,
        optimalMax: 66,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 5,
        optimalMin: 12,
        optimalMax: 24,
        highMin: 30,
      ),
      ph: _wheatPhVeg,
      ec: _wheatEcVeg,
      resistance: _wheatResistanceEarly,
      nIndex: AgroRange(
        lowMax: 10,
        optimalMin: 18,
        optimalMax: 38,
        highMin: 58,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 36, highMin: 50),
      kIndex: AgroRange(
        lowMax: 12,
        optimalMin: 24,
        optimalMax: 50,
        highMin: 70,
      ),
      nPriority: 0.58,
      pPriority: 0.76,
      kPriority: 0.54,
      nWindowLabelEs: 'Crecimiento vegetativo',
      pWindowLabelEs: 'Raíz y macollaje inicial',
      kWindowLabelEs: 'Balance vegetativo',
      nShortGuidanceEs:
          'El N empieza a ganar importancia, pero todavía no domina por completo.',
      pShortGuidanceEs:
          'El P sigue pesando para sostener raíz activa y salida pareja.',
      kShortGuidanceEs:
          'El K acompaña vigor y equilibrio del crecimiento temprano, sin desplazar a N o P.',
      nPlannerHintEs:
          'Preparar transición hacia macollamiento; evitar quedarse corto de base.',
      pPlannerHintEs:
          'No descuidar P si la implantación quedó floja o el suelo viene bajo.',
      kPlannerHintEs:
          'Mantener disponibilidad base antes de etapas más exigentes.',
      nConfidence01: 0.84,
      pConfidence01: 0.88,
      kConfidence01: 0.78,
    ),
    WheatStageKey.tillering: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 14,
        optimalMin: 30,
        optimalMax: 68,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 5,
        optimalMin: 12,
        optimalMax: 24,
        highMin: 30,
      ),
      ph: _wheatPhVeg,
      ec: _wheatEcVeg,
      resistance: _wheatResistanceEarly,
      nIndex: AgroRange(
        lowMax: 12,
        optimalMin: 26,
        optimalMax: 44,
        highMin: 60,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 16, optimalMax: 32, highMin: 46),
      kIndex: AgroRange(
        lowMax: 14,
        optimalMin: 26,
        optimalMax: 54,
        highMin: 72,
      ),
      nPriority: 0.88,
      pPriority: 0.54,
      kPriority: 0.60,
      nWindowLabelEs: 'Macollamiento y espigas',
      pWindowLabelEs: 'Sostén de arranque',
      kWindowLabelEs: 'Balance y vigor',
      nShortGuidanceEs:
          'Aquí el N sí manda: esta etapa define macollos y espigas fértiles.',
      pShortGuidanceEs:
          'El P sigue apoyando, pero deja de ser el protagonista principal.',
      kShortGuidanceEs:
          'El K ayuda a sostener equilibrio, pero normalmente no desplaza al N en esta fase.',
      nPlannerHintEs:
          'Favorecer fraccionamiento; una parte moderada al arranque y el grueso aquí.',
      pPlannerHintEs:
          'Mantener reserva suficiente; la corrección tardía ya rinde menos.',
      kPlannerHintEs: 'Sostener balance conforme sube la demanda de biomasa.',
      nConfidence01: 0.92,
      pConfidence01: 0.82,
      kConfidence01: 0.80,
    ),
    WheatStageKey.elongation: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 16,
        optimalMin: 34,
        optimalMax: 70,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 6,
        optimalMin: 14,
        optimalMax: 24,
        highMin: 30,
      ),
      ph: _wheatPhVeg,
      ec: _wheatEcVeg,
      resistance: _wheatResistanceEarly,
      nIndex: AgroRange(
        lowMax: 14,
        optimalMin: 28,
        optimalMax: 46,
        highMin: 62,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 16, optimalMax: 30, highMin: 44),
      kIndex: AgroRange(
        lowMax: 16,
        optimalMin: 28,
        optimalMax: 56,
        highMin: 74,
      ),
      nPriority: 0.92,
      pPriority: 0.46,
      kPriority: 0.62,
      nWindowLabelEs: 'Encañe y empuje vegetativo',
      pWindowLabelEs: 'Soporte de base',
      kWindowLabelEs: 'Balance y sostén',
      nShortGuidanceEs:
          'El trigo entra en su ventana fuerte de N; aquí conviene llegar bien nutrido.',
      pShortGuidanceEs:
          'El P ya no corrige con la misma eficiencia que al inicio.',
      kShortGuidanceEs:
          'El K acompaña sostén fisiológico y firmeza, pero N sigue mandando en la etapa.',
      nPlannerHintEs:
          'No llegar corto a esta etapa; revisar déficit con atención alta.',
      pPlannerHintEs:
          'Si faltó P al arranque, la corrección ya es menos eficiente.',
      kPlannerHintEs:
          'Asegurar disponibilidad para sostén y respuesta estable.',
      nConfidence01: 0.94,
      pConfidence01: 0.80,
      kConfidence01: 0.82,
    ),
    WheatStageKey.booting: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 18,
        optimalMin: 38,
        optimalMax: 74,
        highMin: 86,
      ),
      soilTemp: AgroRange(
        lowMax: 6,
        optimalMin: 14,
        optimalMax: 24,
        highMin: 28,
      ),
      ph: _wheatPhFlowering,
      ec: _wheatEcFlowering,
      resistance: _wheatResistanceEarly,
      nIndex: AgroRange(
        lowMax: 16,
        optimalMin: 30,
        optimalMax: 48,
        highMin: 64,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 28, highMin: 42),
      kIndex: AgroRange(
        lowMax: 18,
        optimalMin: 30,
        optimalMax: 58,
        highMin: 76,
      ),
      nPriority: 0.84,
      pPriority: 0.34,
      kPriority: 0.64,
      nWindowLabelEs: 'Pre-espigamiento y cierre de N',
      pWindowLabelEs: 'Reserva de base',
      kWindowLabelEs: 'Balance y sostén',
      nShortGuidanceEs:
          'El N sigue muy importante, pero ya no conviene llegar tarde con la corrección.',
      pShortGuidanceEs:
          'El P pesa menos aquí; prioriza más lo que sí mueve la etapa.',
      kShortGuidanceEs:
          'El K acompaña firmeza y balance, pero no debería modelarse como el eje universal del trigo.',
      nPlannerHintEs:
          'Corregir con criterio; evitar perseguir N demasiado tarde.',
      pPlannerHintEs:
          'Conviene más planear base que vender una corrección milagro.',
      kPlannerHintEs:
          'Preparar sostén fisiológico si la lectura de suelo realmente lo justifica.',
      nConfidence01: 0.92,
      pConfidence01: 0.76,
      kConfidence01: 0.82,
    ),

    // =========================
    // REPRODUCTIVE
    // =========================
    WheatStageKey.heading: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 20,
        optimalMin: 40,
        optimalMax: 76,
        highMin: 86,
      ),
      soilTemp: AgroRange(
        lowMax: 8,
        optimalMin: 14,
        optimalMax: 24,
        highMin: 28,
      ),
      ph: _wheatPhFlowering,
      ec: _wheatEcFlowering,
      resistance: _wheatResistanceLate,
      nIndex: AgroRange(
        lowMax: 14,
        optimalMin: 24,
        optimalMax: 40,
        highMin: 56,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 40),
      kIndex: AgroRange(
        lowMax: 20,
        optimalMin: 32,
        optimalMax: 60,
        highMin: 78,
      ),
      nPriority: 0.60,
      pPriority: 0.24,
      kPriority: 0.62,
      nWindowLabelEs: 'Proteína y calidad',
      pWindowLabelEs: 'Reserva residual',
      kWindowLabelEs: 'Balance y sostén',
      nShortGuidanceEs:
          'Aquí el N sigue pesando, pero más para calidad/proteína que para puro rinde.',
      pShortGuidanceEs:
          'El P deja de ser una palanca fuerte de corrección en esta fase.',
      kShortGuidanceEs:
          'El K acompaña balance y firmeza, pero normalmente no desplaza al N salvo que el suelo venga corto.',
      nPlannerHintEs:
          'No tratar N tardío como sustituto de una base mal hecha.',
      pPlannerHintEs:
          'Usar lectura más para planeación que para corrección agresiva.',
      kPlannerHintEs:
          'Vigilar K como soporte, no como protagonista automático.',
      nConfidence01: 0.88,
      pConfidence01: 0.74,
      kConfidence01: 0.82,
    ),
    WheatStageKey.flowering: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 22,
        optimalMin: 42,
        optimalMax: 78,
        highMin: 88,
      ),
      soilTemp: AgroRange(
        lowMax: 8,
        optimalMin: 15,
        optimalMax: 24,
        highMin: 28,
      ),
      ph: _wheatPhFlowering,
      ec: _wheatEcFlowering,
      resistance: _wheatResistanceLate,
      nIndex: AgroRange(
        lowMax: 12,
        optimalMin: 22,
        optimalMax: 36,
        highMin: 52,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 24, highMin: 38),
      kIndex: AgroRange(
        lowMax: 20,
        optimalMin: 34,
        optimalMax: 62,
        highMin: 80,
      ),
      nPriority: 0.54,
      pPriority: 0.22,
      kPriority: 0.60,
      nWindowLabelEs: 'Calidad y proteína',
      pWindowLabelEs: 'Reserva baja prioridad',
      kWindowLabelEs: 'Balance reproductivo',
      nShortGuidanceEs:
          'El N cerca de antesis pesa más para calidad que para levantar mucho rendimiento.',
      pShortGuidanceEs: 'El P ya no es una palanca fuerte en floración.',
      kShortGuidanceEs:
          'El K sostiene balance y estabilidad, pero no conviene venderlo como eje universal.',
      nPlannerHintEs:
          'Usar lectura con criterio; no perseguir proteína a cualquier costo.',
      pPlannerHintEs: 'Orientar lectura a planeación de base futura.',
      kPlannerHintEs:
          'Dar prioridad a K solo si la etapa y la lectura lo exigen de verdad.',
      nConfidence01: 0.84,
      pConfidence01: 0.72,
      kConfidence01: 0.82,
    ),

    // =========================
    // LATE SEASON
    // =========================
    WheatStageKey.grainFill: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 18,
        optimalMin: 38,
        optimalMax: 72,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 8,
        optimalMin: 15,
        optimalMax: 26,
        highMin: 30,
      ),
      ph: _wheatPhVeg,
      ec: _wheatEcVeg,
      resistance: _wheatResistanceLate,
      nIndex: AgroRange(
        lowMax: 10,
        optimalMin: 18,
        optimalMax: 32,
        highMin: 48,
      ),
      pIndex: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 22, highMin: 36),
      kIndex: AgroRange(
        lowMax: 20,
        optimalMin: 34,
        optimalMax: 64,
        highMin: 82,
      ),
      nPriority: 0.24,
      pPriority: 0.18,
      kPriority: 0.46,
      nWindowLabelEs: 'Cierre de N',
      pWindowLabelEs: 'Reserva baja prioridad',
      kWindowLabelEs: 'Llenado y balance',
      nShortGuidanceEs:
          'No persigas N tardío si el cultivo ya va cerrando; la eficiencia cae fuerte.',
      pShortGuidanceEs: 'El P ya no es una palanca fuerte en llenado.',
      kShortGuidanceEs:
          'El K acompaña balance y sostén del llenado, pero no sustituye una base bien hecha.',
      nPlannerHintEs:
          'Usar lectura con prudencia; poca eficiencia para empujar N tarde.',
      pPlannerHintEs: 'Planear el siguiente ciclo con esta lectura.',
      kPlannerHintEs:
          'Dar prioridad a K solo cuando la lectura muestre un déficit real.',
      nConfidence01: 0.80,
      pConfidence01: 0.70,
      kConfidence01: 0.80,
    ),
    WheatStageKey.physiologicalMaturity: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 10,
        optimalMin: 22,
        optimalMax: 48,
        highMin: 65,
      ),
      soilTemp: AgroRange(
        lowMax: 6,
        optimalMin: 12,
        optimalMax: 24,
        highMin: 30,
      ),
      ph: _wheatPhLate,
      ec: _wheatEcLate,
      resistance: _wheatResistanceLate,
      nIndex: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 28, highMin: 42),
      pIndex: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 20, highMin: 34),
      kIndex: AgroRange(
        lowMax: 16,
        optimalMin: 28,
        optimalMax: 58,
        highMin: 76,
      ),
      nPriority: 0.14,
      pPriority: 0.12,
      kPriority: 0.16,
      nWindowLabelEs: 'Cierre de ciclo',
      pWindowLabelEs: 'Cierre de ciclo',
      kWindowLabelEs: 'Cierre de ciclo',
      nShortGuidanceEs:
          'La etapa ya cerró; usa la lectura para aprendizaje, no para empujar el ciclo.',
      pShortGuidanceEs:
          'La corrección tardía aquí tiene poco retorno agronómico.',
      kShortGuidanceEs:
          'Ya no persigas balance tardío si el cultivo va de salida.',
      nPlannerHintEs: 'No vender corrección tardía como solución principal.',
      pPlannerHintEs: 'Planear el siguiente ciclo con esta lectura.',
      kPlannerHintEs: 'Usar información para ajustar base futura.',
      nConfidence01: 0.78,
      pConfidence01: 0.76,
      kConfidence01: 0.78,
    ),
    WheatStageKey.harvest: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 8,
        optimalMin: 18,
        optimalMax: 38,
        highMin: 55,
      ),
      soilTemp: AgroRange(
        lowMax: 4,
        optimalMin: 10,
        optimalMax: 24,
        highMin: 30,
      ),
      ph: _wheatPhLate,
      ec: _wheatEcLate,
      resistance: _wheatResistanceLate,
      nIndex: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 24, highMin: 36),
      pIndex: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 18, highMin: 32),
      kIndex: AgroRange(
        lowMax: 14,
        optimalMin: 24,
        optimalMax: 54,
        highMin: 72,
      ),
      nPriority: 0.10,
      pPriority: 0.10,
      kPriority: 0.12,
      nWindowLabelEs: 'Ciclo cerrado',
      pWindowLabelEs: 'Ciclo cerrado',
      kWindowLabelEs: 'Ciclo cerrado',
      nShortGuidanceEs:
          'No perseguir N en cosecha; esto ya es información para decidir mejor después.',
      pShortGuidanceEs:
          'La lectura sirve más para diagnóstico y planeación que para corrección.',
      kShortGuidanceEs:
          'No vender aplicación tardía; usar el dato para mejorar la base futura.',
      nPlannerHintEs:
          'Guardar lectura para plan de fertilización del siguiente ciclo.',
      pPlannerHintEs: 'Usar el dato como referencia de cierre.',
      kPlannerHintEs: 'Diagnóstico de cierre, no corrección activa.',
      nConfidence01: 0.76,
      pConfidence01: 0.74,
      kConfidence01: 0.76,
    ),
  },
  weights: {
    WheatStageKey.germination: StageWeights(
      moisture: 0.28,
      soilTemp: 0.08,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      n: 0.05,
      p: 0.10,
      k: 0.07,
    ),
    WheatStageKey.emergence: StageWeights(
      moisture: 0.28,
      soilTemp: 0.08,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      n: 0.06,
      p: 0.09,
      k: 0.07,
    ),
    WheatStageKey.vegEarly: StageWeights(
      moisture: 0.24,
      soilTemp: 0.06,
      resistance: 0.18,
      ph: 0.12,
      ec: 0.10,
      n: 0.09,
      p: 0.12,
      k: 0.09,
    ),
    WheatStageKey.tillering: StageWeights(
      moisture: 0.24,
      soilTemp: 0.06,
      resistance: 0.18,
      ph: 0.10,
      ec: 0.10,
      n: 0.14,
      p: 0.08,
      k: 0.10,
    ),
    WheatStageKey.elongation: StageWeights(
      moisture: 0.28,
      soilTemp: 0.06,
      resistance: 0.12,
      ph: 0.10,
      ec: 0.10,
      n: 0.17,
      p: 0.06,
      k: 0.11,
    ),
    WheatStageKey.booting: StageWeights(
      moisture: 0.30,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      n: 0.20,
      p: 0.05,
      k: 0.13,
    ),
    WheatStageKey.heading: StageWeights(
      moisture: 0.34,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      n: 0.15,
      p: 0.04,
      k: 0.15,
    ),
    WheatStageKey.flowering: StageWeights(
      moisture: 0.36,
      soilTemp: 0.06,
      resistance: 0.06,
      ph: 0.08,
      ec: 0.10,
      n: 0.14,
      p: 0.04,
      k: 0.16,
    ),
    WheatStageKey.grainFill: StageWeights(
      moisture: 0.38,
      soilTemp: 0.04,
      resistance: 0.15,
      ph: 0.10,
      ec: 0.10,
      n: 0.06,
      p: 0.03,
      k: 0.14,
    ),
    WheatStageKey.physiologicalMaturity: StageWeights(
      moisture: 0.28,
      soilTemp: 0.04,
      resistance: 0.20,
      ph: 0.14,
      ec: 0.14,
      n: 0.05,
      p: 0.04,
      k: 0.11,
    ),
    WheatStageKey.harvest: StageWeights(
      moisture: 0.26,
      soilTemp: 0.04,
      resistance: 0.20,
      ph: 0.16,
      ec: 0.14,
      n: 0.04,
      p: 0.04,
      k: 0.12,
    ),
  },
);
