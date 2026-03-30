import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/bean_models.dart';

class BeanUniversalProfile {
  const BeanUniversalProfile({required this.byStage, required this.weights});

  final Map<BeanStageKey, StageTargets> byStage;
  final Map<BeanStageKey, StageWeights> weights;
}

// ── pH diferenciado por grupo de etapa ──────────────────────────
// Germinación/emergencia: plántula sensible
const AgroRange _beanPhEarly = AgroRange(
  lowMax: 5.6,
  optimalMin: 6.0,
  optimalMax: 6.8,
  highMin: 7.2,
);

// Vegetativo: rango estándar frijol
const AgroRange _beanPhVeg = AgroRange(
  lowMax: 5.5,
  optimalMin: 5.8,
  optimalMax: 7.0,
  highMin: 7.5,
);

// Floración/podSet: frijol es MÁS sensible a pH extremo aquí
const AgroRange _beanPhFlowering = AgroRange(
  lowMax: 5.8,
  optimalMin: 6.0,
  optimalMax: 6.8,
  highMin: 7.0,
);

// Madurez/cosecha: planta tolerante
const AgroRange _beanPhLate = AgroRange(
  lowMax: 5.3,
  optimalMin: 5.6,
  optimalMax: 7.2,
  highMin: 7.8,
);

// ── EC diferenciado — frijol MUY sensible a salinidad en emergencia ─
const AgroRange _beanEcGerm = AgroRange(
  lowMax: 0.4,
  optimalMin: 0.5,
  optimalMax: 0.8,
  highMin: 1.2,
);

const AgroRange _beanEcVeg = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 1.0,
  highMin: 1.5,
);

const AgroRange _beanEcFlowering = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 0.9,
  highMin: 1.3,
);

const AgroRange _beanEcLate = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 1.2,
  highMin: 1.8,
);

// ── Resistencia (MPa) ───────────────────────────────────────────
const AgroRange _beanResistanceEarly = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 1.4,
  highMin: 2.0,
);

const AgroRange _beanResistanceLate = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 1.6,
  highMin: 2.0,
);

const BeanUniversalProfile beanUniversalV1 = BeanUniversalProfile(
  byStage: {
    // =========================
    // GERMINATION / EMERGENCE
    // =========================
    BeanStageKey.germination: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 18,
        optimalMin: 35,
        optimalMax: 68,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 12,
        optimalMin: 18,
        optimalMax: 28,
        highMin: 32,
      ),
      ph: _beanPhEarly,
      ec: _beanEcGerm,
      resistance: _beanResistanceEarly,
      nIndex: AgroRange(
        lowMax: 20,
        optimalMin: 25,
        optimalMax: 45,
        highMin: 55,
      ),
      pIndex: AgroRange(
        lowMax: 45,
        optimalMin: 55,
        optimalMax: 80,
        highMin: 90,
      ),
      kIndex: AgroRange(
        lowMax: 30,
        optimalMin: 40,
        optimalMax: 60,
        highMin: 70,
      ),
      nPriority: 0.28,
      pPriority: 0.82,
      kPriority: 0.38,
      nWindowLabelEs: 'Arranque prudente de N',
      pWindowLabelEs: 'Arranque, raíces y energía',
      kWindowLabelEs: 'Soporte inicial de K',
      nShortGuidanceEs: 'En arranque, el frijol no pide empujar N alto de rutina.',
      pShortGuidanceEs: 'En arranque, el P pesa mucho más en raíces y establecimiento.',
      kShortGuidanceEs: 'K acompaña balance inicial y vigor, pero no suele dominar al P.',
      nPlannerHintEs: 'Si la lectura de N está corta, usar apoyo moderado y evitar exceso temprano.',
      pPlannerHintEs: 'Favorecer banda/starter y evitar contacto con semilla cuando el P está corto.',
      kPlannerHintEs: 'Activar K solo si el suelo viene bajo y el lote realmente lo justifica.',
      nConfidence01: 0.72,
      pConfidence01: 0.86,
      kConfidence01: 0.70,
    ),
    BeanStageKey.emergence: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 18,
        optimalMin: 35,
        optimalMax: 65,
        highMin: 80,
      ),
      soilTemp: AgroRange(
        lowMax: 12,
        optimalMin: 18,
        optimalMax: 28,
        highMin: 32,
      ),
      ph: _beanPhEarly,
      ec: _beanEcGerm,
      resistance: _beanResistanceEarly,
      nIndex: AgroRange(
        lowMax: 22,
        optimalMin: 28,
        optimalMax: 48,
        highMin: 58,
      ),
      pIndex: AgroRange(
        lowMax: 48,
        optimalMin: 58,
        optimalMax: 82,
        highMin: 92,
      ),
      kIndex: AgroRange(
        lowMax: 35,
        optimalMin: 42,
        optimalMax: 62,
        highMin: 72,
      ),
      nPriority: 0.32,
      pPriority: 0.84,
      kPriority: 0.40,
      nWindowLabelEs: 'Arranque prudente de N',
      pWindowLabelEs: 'Implantación y raíces',
      kWindowLabelEs: 'Soporte inicial de K',
      nShortGuidanceEs: 'N acompaña establecimiento, pero el foco sigue sin ser un empuje fuerte.',
      pShortGuidanceEs: 'P sigue siendo la prioridad principal al salir la planta.',
      kShortGuidanceEs: 'K acompaña vigor y balance inicial.',
      nPlannerHintEs: 'Si N viene corto, corrige con prudencia y sin castigar nodulación futura.',
      pPlannerHintEs: 'Si P viene corto, priorizar banda/starter y buena colocación.',
      kPlannerHintEs: 'No sumar K de rutina si la lectura no lo justifica.',
      nConfidence01: 0.74,
      pConfidence01: 0.88,
      kConfidence01: 0.72,
    ),

    // =========================
    // VEGETATIVE
    // =========================
    BeanStageKey.vegEarly: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 16,
        optimalMin: 32,
        optimalMax: 62,
        highMin: 78,
      ),
      soilTemp: AgroRange(
        lowMax: 14,
        optimalMin: 18,
        optimalMax: 28,
        highMin: 32,
      ),
      ph: _beanPhVeg,
      ec: _beanEcVeg,
      resistance: _beanResistanceEarly,
      nIndex: AgroRange(
        lowMax: 25,
        optimalMin: 32,
        optimalMax: 55,
        highMin: 65,
      ),
      pIndex: AgroRange(
        lowMax: 52,
        optimalMin: 62,
        optimalMax: 85,
        highMin: 92,
      ),
      kIndex: AgroRange(
        lowMax: 40,
        optimalMin: 48,
        optimalMax: 68,
        highMin: 78,
      ),
      nPriority: 0.42,
      pPriority: 0.74,
      kPriority: 0.50,
      nWindowLabelEs: 'Cobertura inicial de N',
      pWindowLabelEs: 'Raíces y energía temprana',
      kWindowLabelEs: 'Balance fisiológico temprano',
      nShortGuidanceEs: 'N empieza a ganar peso, pero P sigue muy metido en arranque.',
      pShortGuidanceEs: 'Todavía conviene cuidar P por su papel en energía y sistema radicular.',
      kShortGuidanceEs: 'K acompaña balance hídrico y vigor de crecimiento.',
      nPlannerHintEs: 'Si el lote viene corto de N, preferir corrección moderada y bien justificada.',
      pPlannerHintEs: 'Si P sigue corto, reforzar arranque con banda y buena colocación.',
      kPlannerHintEs: 'Activar K si el suelo está bajo o el balance del lote se aprieta.',
      nConfidence01: 0.76,
      pConfidence01: 0.84,
      kConfidence01: 0.74,
    ),
    BeanStageKey.vegAdvanced: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 18,
        optimalMin: 35,
        optimalMax: 65,
        highMin: 78,
      ),
      soilTemp: AgroRange(
        lowMax: 14,
        optimalMin: 18,
        optimalMax: 28,
        highMin: 31,
      ),
      ph: _beanPhVeg,
      ec: _beanEcVeg,
      resistance: _beanResistanceEarly,
      nIndex: AgroRange(
        lowMax: 28,
        optimalMin: 35,
        optimalMax: 58,
        highMin: 68,
      ),
      pIndex: AgroRange(
        lowMax: 50,
        optimalMin: 60,
        optimalMax: 82,
        highMin: 90,
      ),
      kIndex: AgroRange(
        lowMax: 45,
        optimalMin: 52,
        optimalMax: 72,
        highMin: 82,
      ),
      nPriority: 0.70,
      pPriority: 0.56,
      kPriority: 0.58,
      nWindowLabelEs: 'Demanda creciente de N',
      pWindowLabelEs: 'Soporte energético de P',
      kWindowLabelEs: 'Balance hídrico y estructura',
      nShortGuidanceEs: 'N ya sube fuerte de peso al avanzar el crecimiento del frijol.',
      pShortGuidanceEs: 'P sigue aportando energía, pero ya no domina como en arranque.',
      kShortGuidanceEs: 'K ayuda a sostener balance y vigor del lote.',
      nPlannerHintEs: 'Si el lote no viene bien nodulado, aquí conviene revisar cobertura real de N.',
      pPlannerHintEs: 'Corregir P solo si la lectura sigue corta y la etapa todavía lo paga.',
      kPlannerHintEs: 'Subir K cuando el suelo viene bajo y el lote empieza a demandar más soporte.',
      nConfidence01: 0.84,
      pConfidence01: 0.76,
      kConfidence01: 0.76,
    ),

    // =========================
    // REPRODUCTIVE
    // =========================
    BeanStageKey.flowering: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 20,
        optimalMin: 40,
        optimalMax: 70,
        highMin: 80,
      ),
      soilTemp: AgroRange(
        lowMax: 15,
        optimalMin: 18,
        optimalMax: 28,
        highMin: 30,
      ),
      ph: _beanPhFlowering,
      ec: _beanEcFlowering,
      resistance: _beanResistanceLate,
      nIndex: AgroRange(
        lowMax: 25,
        optimalMin: 32,
        optimalMax: 55,
        highMin: 65,
      ),
      pIndex: AgroRange(
        lowMax: 48,
        optimalMin: 58,
        optimalMax: 78,
        highMin: 86,
      ),
      kIndex: AgroRange(
        lowMax: 55,
        optimalMin: 62,
        optimalMax: 82,
        highMin: 90,
      ),
      nPriority: 0.82,
      pPriority: 0.46,
      kPriority: 0.62,
      nWindowLabelEs: 'Demanda fuerte de N',
      pWindowLabelEs: 'Soporte reproductivo de P',
      kWindowLabelEs: 'Balance hídrico y floración',
      nShortGuidanceEs: 'En floración, N gana mucho peso si la cobertura del lote quedó corta.',
      pShortGuidanceEs: 'P sigue aportando energía, pero su papel más fuerte ya ocurrió al arranque.',
      kShortGuidanceEs: 'K ayuda mucho al balance fisiológico en floración.',
      nPlannerHintEs: 'Revisar nodulación y cobertura del plan antes de meter más N.',
      pPlannerHintEs: 'Pagar P tardío solo cuando la lectura realmente lo justifique.',
      kPlannerHintEs: 'Si K viene bajo, aquí ya puede volverse un soporte importante.',
      nConfidence01: 0.88,
      pConfidence01: 0.74,
      kConfidence01: 0.80,
    ),
    BeanStageKey.podSet: StageTargets(
      // ✅ Rango de humedad ampliado: optimalMin 38 (era 42), optimalMax 76 (era 72)
      moistureRaw: AgroRange(
        lowMax: 20,
        optimalMin: 38,
        optimalMax: 76,
        highMin: 85,
      ),
      soilTemp: AgroRange(
        lowMax: 15,
        optimalMin: 18,
        optimalMax: 28,
        highMin: 30,
      ),
      ph: _beanPhFlowering,
      ec: _beanEcFlowering,
      resistance: _beanResistanceLate,
      nIndex: AgroRange(
        lowMax: 24,
        optimalMin: 30,
        optimalMax: 52,
        highMin: 62,
      ),
      pIndex: AgroRange(
        lowMax: 45,
        optimalMin: 55,
        optimalMax: 75,
        highMin: 84,
      ),
      kIndex: AgroRange(
        lowMax: 58,
        optimalMin: 65,
        optimalMax: 85,
        highMin: 92,
      ),
      nPriority: 0.86,
      pPriority: 0.42,
      kPriority: 0.68,
      nWindowLabelEs: 'Demanda fuerte de N',
      pWindowLabelEs: 'Soporte reproductivo de P',
      kWindowLabelEs: 'Balance hídrico y amarre',
      nShortGuidanceEs: 'En amarre de vaina, N sigue muy sensible si el lote viene corto.',
      pShortGuidanceEs: 'P se mantiene como soporte, pero no suele ser el cuello principal aquí.',
      kShortGuidanceEs: 'K gana peso en balance hídrico y estabilidad fisiológica.',
      nPlannerHintEs: 'Si la lectura de N sigue apretada, revisar cobertura y nodulación con mucha atención.',
      pPlannerHintEs: 'No empujar P de rutina en esta fase si el lote ya viene cubierto.',
      kPlannerHintEs: 'Con K bajo, aquí sí conviene evaluar soporte del nutriente.',
      nConfidence01: 0.90,
      pConfidence01: 0.72,
      kConfidence01: 0.82,
    ),

    // =========================
    // LATE SEASON
    // =========================
    BeanStageKey.grainFill: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 18,
        optimalMin: 38,
        optimalMax: 68,
        highMin: 78,
      ),
      soilTemp: AgroRange(
        lowMax: 15,
        optimalMin: 18,
        optimalMax: 28,
        highMin: 31,
      ),
      ph: _beanPhVeg,
      ec: _beanEcVeg,
      resistance: _beanResistanceLate,
      nIndex: AgroRange(
        lowMax: 20,
        optimalMin: 26,
        optimalMax: 48,
        highMin: 58,
      ),
      pIndex: AgroRange(
        lowMax: 40,
        optimalMin: 48,
        optimalMax: 70,
        highMin: 80,
      ),
      kIndex: AgroRange(
        lowMax: 60,
        optimalMin: 68,
        optimalMax: 88,
        highMin: 95,
      ),
      nPriority: 0.72,
      pPriority: 0.34,
      kPriority: 0.74,
      nWindowLabelEs: 'Cobertura de N en llenado',
      pWindowLabelEs: 'Soporte final de P',
      kWindowLabelEs: 'Balance hídrico y llenado',
      nShortGuidanceEs: 'N sigue importando en llenado, sobre todo si la nodulación no sostuvo el ritmo.',
      pShortGuidanceEs: 'P pasa a un papel más de soporte que de empuje principal.',
      kShortGuidanceEs: 'K se vuelve muy valioso para balance y movimiento de azúcares.',
      nPlannerHintEs: 'Corregir N tardío solo si la etapa todavía paga la intervención.',
      pPlannerHintEs: 'Usar P tardío más como aprendizaje de plan que como corrección agresiva.',
      kPlannerHintEs: 'Si K está corto, esta etapa sí puede justificar soporte del nutriente.',
      nConfidence01: 0.82,
      pConfidence01: 0.68,
      kConfidence01: 0.84,
    ),
    BeanStageKey.physiologicalMaturity: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 10,
        optimalMin: 20,
        optimalMax: 45,
        highMin: 60,
      ),
      soilTemp: AgroRange(
        lowMax: 14,
        optimalMin: 18,
        optimalMax: 26,
        highMin: 30,
      ),
      ph: _beanPhLate,
      ec: _beanEcLate,
      resistance: _beanResistanceLate,
      nIndex: AgroRange(
        lowMax: 12,
        optimalMin: 18,
        optimalMax: 35,
        highMin: 45,
      ),
      pIndex: AgroRange(
        lowMax: 30,
        optimalMin: 38,
        optimalMax: 58,
        highMin: 68,
      ),
      kIndex: AgroRange(
        lowMax: 38,
        optimalMin: 45,
        optimalMax: 65,
        highMin: 75,
      ),
      nPriority: 0.24,
      pPriority: 0.20,
      kPriority: 0.30,
      nWindowLabelEs: 'Cierre de ciclo de N',
      pWindowLabelEs: 'Cierre de ciclo de P',
      kWindowLabelEs: 'Cierre de ciclo de K',
      nShortGuidanceEs: 'En cierre, N sirve más para lectura y aprendizaje del lote.',
      pShortGuidanceEs: 'En cierre, P ya no suele ser una urgencia operativa.',
      kShortGuidanceEs: 'En cierre, K se interpreta más como balance final del lote.',
      nPlannerHintEs: 'En madurez, preferir documentar y ajustar el siguiente plan antes que empujar correcciones tardías.',
      pPlannerHintEs: 'Usar esta lectura para afinar el próximo arranque más que para corregir tarde.',
      kPlannerHintEs: 'Usar esta lectura para balance y trazabilidad del plan próximo.',
      nConfidence01: 0.68,
      pConfidence01: 0.64,
      kConfidence01: 0.68,
    ),
    BeanStageKey.harvest: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 8,
        optimalMin: 15,
        optimalMax: 35,
        highMin: 50,
      ),
      soilTemp: AgroRange(
        lowMax: 14,
        optimalMin: 18,
        optimalMax: 26,
        highMin: 30,
      ),
      ph: _beanPhLate,
      ec: _beanEcLate,
      resistance: _beanResistanceLate,
      nIndex: AgroRange(
        lowMax: 10,
        optimalMin: 15,
        optimalMax: 30,
        highMin: 40,
      ),
      pIndex: AgroRange(
        lowMax: 25,
        optimalMin: 35,
        optimalMax: 55,
        highMin: 65,
      ),
      kIndex: AgroRange(
        lowMax: 35,
        optimalMin: 42,
        optimalMax: 62,
        highMin: 72,
      ),
      nPriority: 0.18,
      pPriority: 0.16,
      kPriority: 0.22,
      nWindowLabelEs: 'Cosecha y trazabilidad',
      pWindowLabelEs: 'Cosecha y trazabilidad',
      kWindowLabelEs: 'Cosecha y trazabilidad',
      nShortGuidanceEs: 'En cosecha, la lectura sirve más para cierre técnico que para intervención.',
      pShortGuidanceEs: 'En cosecha, la lectura de P ayuda a afinar el siguiente ciclo.',
      kShortGuidanceEs: 'En cosecha, la lectura de K ayuda a balance y trazabilidad del lote.',
      nPlannerHintEs: 'No empujar correcciones tardías de N en cosecha.',
      pPlannerHintEs: 'Usar la lectura de P para preparar el siguiente arranque.',
      kPlannerHintEs: 'Usar la lectura de K para ajustar el plan del siguiente ciclo.',
      nConfidence01: 0.62,
      pConfidence01: 0.60,
      kConfidence01: 0.62,
    ),
  },

  // ── Pesos para el ring (control del suelo) ────────────────────
  // ✅ BUG FIX: physiologicalMaturity sumaba 0.72, harvest 0.70 → ahora suman 1.0
  weights: {
    // soilTemp: frijol sensible a temp suelo en germinación (C3 tropical)
    BeanStageKey.germination: StageWeights(
      moisture: 0.30,
      soilTemp: 0.08,
      resistance: 0.18,
      ph: 0.12,
      ec: 0.10,
      npk: 0.22,
    ),
    BeanStageKey.emergence: StageWeights(
      moisture: 0.30,
      soilTemp: 0.08,
      resistance: 0.18,
      ph: 0.12,
      ec: 0.10,
      npk: 0.22,
    ),
    BeanStageKey.vegEarly: StageWeights(
      moisture: 0.26,
      soilTemp: 0.06,
      resistance: 0.16,
      ph: 0.12,
      ec: 0.10,
      npk: 0.30,
    ),
    BeanStageKey.vegAdvanced: StageWeights(
      moisture: 0.28,
      soilTemp: 0.06,
      resistance: 0.12,
      ph: 0.10,
      ec: 0.10,
      npk: 0.34,
    ),
    BeanStageKey.flowering: StageWeights(
      moisture: 0.38,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.30,
    ),
    BeanStageKey.podSet: StageWeights(
      moisture: 0.38,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.30,
    ),
    BeanStageKey.grainFill: StageWeights(
      moisture: 0.34,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.34,
    ),
    BeanStageKey.physiologicalMaturity: StageWeights(
      moisture: 0.26,
      soilTemp: 0.04,
      resistance: 0.14,
      ph: 0.14,
      ec: 0.14,
      npk: 0.28,
    ),
    BeanStageKey.harvest: StageWeights(
      moisture: 0.22,
      soilTemp: 0.04,
      resistance: 0.14,
      ph: 0.16,
      ec: 0.14,
      npk: 0.30,
    ),
  },
);
