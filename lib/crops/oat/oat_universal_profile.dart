import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/oat_models.dart';

/// Perfil universal de avena (C3, cereal de estación fría).
/// Contiene rangos agronómicos y pesos de importancia por etapa fenológica.
///
//// NUEVA LÓGICA NPK PARA AVENA:
/// - Arranque: P pesa más por raíz y establecimiento.
/// - Vegetativo temprano: P sigue fuerte, N empieza a subir.
/// - Macollamiento / elongación / embuche: N manda.
/// - Espigamiento / floración / llenado: K gana protagonismo.
/// - Madurez / cosecha: no perseguir correcciones tardías.

// ── pH diferenciado por grupo de etapa ──────────────────────────
// Avena tolera pH más ácido que otros cereales (hasta 4.5 en campo).
// Germinación/emergencia: rango estrecho, plántula sensible
const AgroRange _oatPhEarly = AgroRange(
  lowMax: 4.8,
  optimalMin: 5.2,
  optimalMax: 7.0,
  highMin: 7.5,
);

// Vegetativo: rango estándar avena
const AgroRange _oatPhVeg = AgroRange(
  lowMax: 4.5,
  optimalMin: 5.0,
  optimalMax: 7.2,
  highMin: 7.8,
);

// Floración/heading: algo más estrecho para máxima absorción
const AgroRange _oatPhFlowering = AgroRange(
  lowMax: 5.0,
  optimalMin: 5.5,
  optimalMax: 7.0,
  highMin: 7.5,
);

// Madurez/cosecha: tolerante
const AgroRange _oatPhLate = AgroRange(
  lowMax: 4.5,
  optimalMin: 5.0,
  optimalMax: 7.5,
  highMin: 8.2,
);

// ── EC diferenciado por etapa ───────────────────────────────────
// Emergencia más sensible a salinidad
const AgroRange _oatEcEarly = AgroRange(
  lowMax: 0.4,
  optimalMin: 0.5,
  optimalMax: 1.8,
  highMin: 3.0,
);

// Vegetativo: tolerancia intermedia
const AgroRange _oatEcVeg = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 2.2,
  highMin: 3.5,
);

// Floración: moderada
const AgroRange _oatEcFlowering = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 2.0,
  highMin: 3.2,
);

// Madurez/cosecha: tolerante
const AgroRange _oatEcLate = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 2.8,
  highMin: 4.2,
);

// ── Resistencia (MPa) ───────────────────────────────────────────
// raíces jóvenes más sensibles → Early (más estricto) se extiende
// hasta booting. Late (más tolerante) desde heading en adelante.
const AgroRange _oatResistanceEarly = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 1.2,
  highMin: 2.0,
);

const AgroRange _oatResistanceLate = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 1.6,
  highMin: 2.0,
);

class OatUniversalProfile {
  const OatUniversalProfile({required this.byStage, required this.weights});

  final Map<OatStageKey, StageTargets> byStage;
  final Map<OatStageKey, StageWeights> weights;
}

const oatUniversalV1 = OatUniversalProfile(
  byStage: {
    // =========================
    // GERMINATION / EMERGENCE
    // =========================
    OatStageKey.germination: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 15,
        optimalMin: 32,
        optimalMax: 70,
        highMin: 85,
      ),
      soilTemp: AgroRange(
        lowMax: 4,
        optimalMin: 10,
        optimalMax: 20,
        highMin: 28,
      ),
      ph: _oatPhEarly,
      ec: _oatEcEarly,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(
        lowMax: 10,
        optimalMin: 18,
        optimalMax: 43,
        highMin: 60,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 40, highMin: 56),
      kIndex: AgroRange(
        lowMax: 12,
        optimalMin: 24,
        optimalMax: 56,
        highMin: 72,
      ),

      nPriority: 0.42,
      pPriority: 0.84,
      kPriority: 0.52,

      nWindowLabelEs: 'Arranque y hojas iniciales',
      pWindowLabelEs: 'Arranque y raíz',
      kWindowLabelEs: 'Estabilidad inicial',

      nShortGuidanceEs:
          'El N todavía no manda; vigila sin sobrecargar el arranque.',
      pShortGuidanceEs:
          'El P pesa fuerte desde el inicio para raíz y establecimiento.',
      kShortGuidanceEs:
          'El K ayuda a balance inicial, pero no desplaza al P en esta etapa.',

      nPlannerHintEs:
          'Favorecer arranque moderado; evitar empujar N demasiado temprano.',
      pPlannerHintEs:
          'Priorizar disponibilidad temprana; corrección tardía pierde eficiencia.',
      kPlannerHintEs: 'Mantener disponibilidad base sin sobrecorregir.',

      nConfidence01: 0.78,
      pConfidence01: 0.88,
      kConfidence01: 0.76,
    ),

    OatStageKey.emergence: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 15,
        optimalMin: 32,
        optimalMax: 68,
        highMin: 84,
      ),
      soilTemp: AgroRange(
        lowMax: 4,
        optimalMin: 10,
        optimalMax: 20,
        highMin: 28,
      ),
      ph: _oatPhEarly,
      ec: _oatEcEarly,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(
        lowMax: 10,
        optimalMin: 18,
        optimalMax: 43,
        highMin: 60,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 40, highMin: 56),
      kIndex: AgroRange(
        lowMax: 12,
        optimalMin: 24,
        optimalMax: 56,
        highMin: 72,
      ),

      nPriority: 0.46,
      pPriority: 0.82,
      kPriority: 0.54,

      nWindowLabelEs: 'Despegue vegetativo',
      pWindowLabelEs: 'Arranque y raíz',
      kWindowLabelEs: 'Balance inicial',

      nShortGuidanceEs:
          'El N empieza a subir, pero el arranque sigue dependiendo más de raíz.',
      pShortGuidanceEs:
          'Mantén P disponible desde el inicio para no frenar establecimiento.',
      kShortGuidanceEs:
          'El K acompaña el arranque, sin volverse todavía el nutriente dominante.',

      nPlannerHintEs:
          'Sostener arranque sin sobredosificar N; preparar fase vegetativa.',
      pPlannerHintEs:
          'Favorecer disponibilidad temprana y ubicación eficiente.',
      kPlannerHintEs: 'Mantener base suficiente para estabilidad y vigor.',

      nConfidence01: 0.80,
      pConfidence01: 0.88,
      kConfidence01: 0.77,
    ),

    // =========================
    // VEGETATIVE
    // =========================
    OatStageKey.vegEarly: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 14,
        optimalMin: 30,
        optimalMax: 65,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 6,
        optimalMin: 12,
        optimalMax: 26,
        highMin: 32,
      ),
      ph: _oatPhVeg,
      ec: _oatEcVeg,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(
        lowMax: 10,
        optimalMin: 20,
        optimalMax: 45,
        highMin: 62,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 40, highMin: 56),
      kIndex: AgroRange(
        lowMax: 12,
        optimalMin: 25,
        optimalMax: 58,
        highMin: 74,
      ),

      nPriority: 0.62,
      pPriority: 0.72,
      kPriority: 0.58,

      nWindowLabelEs: 'Crecimiento vegetativo',
      pWindowLabelEs: 'Raíz y establecimiento',
      kWindowLabelEs: 'Balance vegetativo',

      nShortGuidanceEs:
          'El N empieza a ganar importancia, pero todavía no domina por completo.',
      pShortGuidanceEs:
          'El P sigue pesando para sostener raíz activa y un arranque parejo.',
      kShortGuidanceEs:
          'El K acompaña el vigor y la estabilidad del crecimiento temprano.',

      nPlannerHintEs:
          'Preparar transición hacia macollamiento; considerar fraccionamiento.',
      pPlannerHintEs: 'No descuidar base de P si el arranque quedó corto.',
      kPlannerHintEs:
          'Mantener disponibilidad base antes de etapas más exigentes.',

      nConfidence01: 0.82,
      pConfidence01: 0.84,
      kConfidence01: 0.78,
    ),

    OatStageKey.tillering: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 16,
        optimalMin: 32,
        optimalMax: 66,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 6,
        optimalMin: 12,
        optimalMax: 26,
        highMin: 32,
      ),
      ph: _oatPhVeg,
      ec: _oatEcVeg,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(
        lowMax: 10,
        optimalMin: 20,
        optimalMax: 45,
        highMin: 62,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 40, highMin: 56),
      kIndex: AgroRange(
        lowMax: 12,
        optimalMin: 26,
        optimalMax: 58,
        highMin: 74,
      ),

      nPriority: 0.82,
      pPriority: 0.58,
      kPriority: 0.66,

      nWindowLabelEs: 'Macollamiento y empuje vegetativo',
      pWindowLabelEs: 'Sostén de arranque',
      kWindowLabelEs: 'Balance y vigor',

      nShortGuidanceEs:
          'Aquí el N ya importa mucho: esta etapa define empuje y estructura.',
      pShortGuidanceEs:
          'El P sigue apoyando, pero deja de ser el protagonista principal.',
      kShortGuidanceEs:
          'El K ayuda a sostener equilibrio y respuesta del cultivo.',

      nPlannerHintEs:
          'Favorecer fraccionamiento; una parte al arranque y otra en macollamiento.',
      pPlannerHintEs:
          'Mantener reserva suficiente; evitar depender de corrección tardía.',
      kPlannerHintEs: 'Sostener balance conforme sube la demanda de biomasa.',

      nConfidence01: 0.88,
      pConfidence01: 0.80,
      kConfidence01: 0.80,
    ),

    OatStageKey.elongation: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 18,
        optimalMin: 35,
        optimalMax: 68,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 8,
        optimalMin: 14,
        optimalMax: 26,
        highMin: 32,
      ),
      ph: _oatPhVeg,
      ec: _oatEcVeg,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(
        lowMax: 12,
        optimalMin: 22,
        optimalMax: 47,
        highMin: 64,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 40, highMin: 56),
      kIndex: AgroRange(
        lowMax: 14,
        optimalMin: 28,
        optimalMax: 60,
        highMin: 76,
      ),

      nPriority: 0.90,
      pPriority: 0.50,
      kPriority: 0.72,

      nWindowLabelEs: 'Elongación y empuje vegetativo',
      pWindowLabelEs: 'Soporte de base',
      kWindowLabelEs: 'Balance y sostén',

      nShortGuidanceEs:
          'La avena entra en su ventana fuerte de N; aquí conviene llegar bien nutrida.',
      pShortGuidanceEs:
          'El P ya no corrige con la misma eficiencia que al inicio.',
      kShortGuidanceEs:
          'El K gana importancia para sostén fisiológico y equilibrio.',

      nPlannerHintEs:
          'No llegar corto a esta etapa; revisar déficit con atención alta.',
      pPlannerHintEs:
          'Si faltó P al arranque, la corrección ya es menos eficiente.',
      kPlannerHintEs:
          'Asegurar disponibilidad para sostén y respuesta estable.',

      nConfidence01: 0.90,
      pConfidence01: 0.78,
      kConfidence01: 0.82,
    ),

    OatStageKey.booting: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 20,
        optimalMin: 38,
        optimalMax: 72,
        highMin: 84,
      ),
      soilTemp: AgroRange(
        lowMax: 8,
        optimalMin: 14,
        optimalMax: 26,
        highMin: 30,
      ),
      ph: _oatPhFlowering,
      ec: _oatEcFlowering,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(
        lowMax: 12,
        optimalMin: 22,
        optimalMax: 47,
        highMin: 64,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 40, highMin: 56),
      kIndex: AgroRange(
        lowMax: 14,
        optimalMin: 28,
        optimalMax: 60,
        highMin: 76,
      ),

      nPriority: 0.88,
      pPriority: 0.42,
      kPriority: 0.74,

      nWindowLabelEs: 'Pre-espigamiento y empuje final de N',
      pWindowLabelEs: 'Reserva de base',
      kWindowLabelEs: 'Firmeza y balance',

      nShortGuidanceEs:
          'El N sigue muy importante, pero ya no conviene llegar tarde con la corrección.',
      pShortGuidanceEs:
          'El P pesa menos aquí; prioriza más lo que sí mueve la etapa.',
      kShortGuidanceEs:
          'El K ya sostiene balance y firmeza conforme avanza la estructura.',

      nPlannerHintEs:
          'Corregir con criterio; evitar perseguir N demasiado tarde.',
      pPlannerHintEs:
          'Conviene más planear base que vender una corrección milagro.',
      kPlannerHintEs: 'Preparar sostén fisiológico antes de espigamiento.',

      nConfidence01: 0.90,
      pConfidence01: 0.76,
      kConfidence01: 0.84,
    ),

    // =========================
    // REPRODUCTIVE
    // =========================
    OatStageKey.heading: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 22,
        optimalMin: 40,
        optimalMax: 74,
        highMin: 86,
      ),
      soilTemp: AgroRange(
        lowMax: 8,
        optimalMin: 14,
        optimalMax: 26,
        highMin: 30,
      ),
      ph: _oatPhFlowering,
      ec: _oatEcFlowering,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(
        lowMax: 12,
        optimalMin: 22,
        optimalMax: 47,
        highMin: 64,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 40, highMin: 56),
      kIndex: AgroRange(
        lowMax: 14,
        optimalMin: 30,
        optimalMax: 62,
        highMin: 76,
      ),

      nPriority: 0.48,
      pPriority: 0.30,
      kPriority: 0.82,

      nWindowLabelEs: 'Cierre de N',
      pWindowLabelEs: 'Reserva residual',
      kWindowLabelEs: 'Espigamiento y firmeza',

      nShortGuidanceEs:
          'Ya no conviene empujar N como en macollamiento; la eficiencia cae.',
      pShortGuidanceEs:
          'El P deja de ser una palanca fuerte de corrección en esta fase.',
      kShortGuidanceEs:
          'El K toma más peso para balance, firmeza y sostén reproductivo.',

      nPlannerHintEs: 'Evitar perseguir N tardío solo por alcanzar un número.',
      pPlannerHintEs:
          'Usar lectura más para planeación que para corrección agresiva.',
      kPlannerHintEs: 'Vigilar K para sostén, estabilidad y llenado posterior.',

      nConfidence01: 0.84,
      pConfidence01: 0.74,
      kConfidence01: 0.88,
    ),

    OatStageKey.flowering: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 22,
        optimalMin: 42,
        optimalMax: 76,
        highMin: 86,
      ),
      soilTemp: AgroRange(
        lowMax: 10,
        optimalMin: 15,
        optimalMax: 26,
        highMin: 30,
      ),
      ph: _oatPhFlowering,
      ec: _oatEcFlowering,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(
        lowMax: 12,
        optimalMin: 22,
        optimalMax: 45,
        highMin: 64,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 40, highMin: 56),
      kIndex: AgroRange(
        lowMax: 14,
        optimalMin: 30,
        optimalMax: 62,
        highMin: 78,
      ),

      nPriority: 0.42,
      pPriority: 0.26,
      kPriority: 0.84,

      nWindowLabelEs: 'Cierre de aplicación fuerte de N',
      pWindowLabelEs: 'Base ya definida',
      kWindowLabelEs: 'Floración y balance',

      nShortGuidanceEs:
          'El N ya no debe dominar decisiones tardías salvo un caso muy claro.',
      pShortGuidanceEs:
          'El P aquí ya no tiene la misma eficiencia de respuesta.',
      kShortGuidanceEs:
          'El K sostiene equilibrio fisiológico y estabilidad del cultivo.',

      nPlannerHintEs:
          'Priorizar prudencia; no sobrecargar N en fase reproductiva.',
      pPlannerHintEs: 'Usar lectura como aprendizaje para el siguiente ciclo.',
      kPlannerHintEs: 'Mantener K para sostén y transición hacia llenado.',

      nConfidence01: 0.82,
      pConfidence01: 0.72,
      kConfidence01: 0.88,
    ),

    // =========================
    // LATE SEASON
    // =========================
    OatStageKey.grainFill: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 18,
        optimalMin: 38,
        optimalMax: 72,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 10,
        optimalMin: 15,
        optimalMax: 26,
        highMin: 30,
      ),
      ph: _oatPhVeg,
      ec: _oatEcVeg,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(
        lowMax: 10,
        optimalMin: 20,
        optimalMax: 43,
        highMin: 62,
      ),
      pIndex: AgroRange(lowMax: 8, optimalMin: 16, optimalMax: 38, highMin: 56),
      kIndex: AgroRange(
        lowMax: 14,
        optimalMin: 30,
        optimalMax: 64,
        highMin: 78,
      ),

      nPriority: 0.34,
      pPriority: 0.22,
      kPriority: 0.86,

      nWindowLabelEs: 'N de cierre',
      pWindowLabelEs: 'Reserva baja prioridad',
      kWindowLabelEs: 'Llenado y balance',

      nShortGuidanceEs: 'No persigas N tardío si la etapa ya va cerrando.',
      pShortGuidanceEs: 'El P ya no es una palanca fuerte en llenado.',
      kShortGuidanceEs:
          'El K pesa más para sostener balance y llenado en esta fase.',

      nPlannerHintEs:
          'Usar lectura con prudencia; poca eficiencia para empujar N tarde.',
      pPlannerHintEs: 'Orientar lectura a planeación de base futura.',
      kPlannerHintEs: 'Dar prioridad a K si la etapa y lectura lo exigen.',

      nConfidence01: 0.80,
      pConfidence01: 0.70,
      kConfidence01: 0.90,
    ),

    OatStageKey.physiologicalMaturity: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 10,
        optimalMin: 22,
        optimalMax: 50,
        highMin: 65,
      ),
      soilTemp: AgroRange(
        lowMax: 8,
        optimalMin: 14,
        optimalMax: 26,
        highMin: 30,
      ),
      ph: _oatPhLate,
      ec: _oatEcLate,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 8, optimalMin: 16, optimalMax: 40, highMin: 60),
      pIndex: AgroRange(lowMax: 6, optimalMin: 14, optimalMax: 36, highMin: 54),
      kIndex: AgroRange(
        lowMax: 12,
        optimalMin: 26,
        optimalMax: 58,
        highMin: 74,
      ),

      nPriority: 0.18,
      pPriority: 0.16,
      kPriority: 0.22,

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

      nConfidence01: 0.76,
      pConfidence01: 0.74,
      kConfidence01: 0.76,
    ),

    OatStageKey.harvest: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 8,
        optimalMin: 18,
        optimalMax: 40,
        highMin: 55,
      ),
      soilTemp: AgroRange(
        lowMax: 6,
        optimalMin: 12,
        optimalMax: 26,
        highMin: 32,
      ),
      ph: _oatPhLate,
      ec: _oatEcLate,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 38, highMin: 58),
      pIndex: AgroRange(lowMax: 6, optimalMin: 14, optimalMax: 36, highMin: 54),
      kIndex: AgroRange(
        lowMax: 10,
        optimalMin: 22,
        optimalMax: 54,
        highMin: 72,
      ),

      nPriority: 0.12,
      pPriority: 0.12,
      kPriority: 0.16,

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

      nConfidence01: 0.74,
      pConfidence01: 0.72,
      kConfidence01: 0.74,
    ),
  },

  weights: {
    OatStageKey.germination: StageWeights(
      moisture: 0.28,
      soilTemp: 0.08,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      n: 0.05,
      p: 0.10,
      k: 0.07,
    ),
    OatStageKey.emergence: StageWeights(
      moisture: 0.28,
      soilTemp: 0.08,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      n: 0.06,
      p: 0.09,
      k: 0.07,
    ),
    OatStageKey.vegEarly: StageWeights(
      moisture: 0.24,
      soilTemp: 0.06,
      resistance: 0.18,
      ph: 0.12,
      ec: 0.10,
      n: 0.10,
      p: 0.11,
      k: 0.09,
    ),
    OatStageKey.tillering: StageWeights(
      moisture: 0.24,
      soilTemp: 0.06,
      resistance: 0.18,
      ph: 0.10,
      ec: 0.10,
      n: 0.14,
      p: 0.08,
      k: 0.10,
    ),
    OatStageKey.elongation: StageWeights(
      moisture: 0.28,
      soilTemp: 0.06,
      resistance: 0.12,
      ph: 0.10,
      ec: 0.10,
      n: 0.16,
      p: 0.06,
      k: 0.12,
    ),
    OatStageKey.booting: StageWeights(
      moisture: 0.28,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      n: 0.18,
      p: 0.07,
      k: 0.15,
    ),
    OatStageKey.heading: StageWeights(
      moisture: 0.34,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      n: 0.09,
      p: 0.05,
      k: 0.20,
    ),
    OatStageKey.flowering: StageWeights(
      moisture: 0.36,
      soilTemp: 0.06,
      resistance: 0.06,
      ph: 0.08,
      ec: 0.10,
      n: 0.08,
      p: 0.04,
      k: 0.22,
    ),
    OatStageKey.grainFill: StageWeights(
      moisture: 0.34,
      soilTemp: 0.04,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      n: 0.08,
      p: 0.04,
      k: 0.24,
    ),
    OatStageKey.physiologicalMaturity: StageWeights(
      moisture: 0.26,
      soilTemp: 0.04,
      resistance: 0.16,
      ph: 0.12,
      ec: 0.12,
      n: 0.06,
      p: 0.05,
      k: 0.19,
    ),
    OatStageKey.harvest: StageWeights(
      moisture: 0.24,
      soilTemp: 0.04,
      resistance: 0.16,
      ph: 0.14,
      ec: 0.12,
      n: 0.05,
      p: 0.05,
      k: 0.20,
    ),
  },
);
