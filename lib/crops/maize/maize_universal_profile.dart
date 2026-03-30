import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class MaizeUniversalProfile {
  const MaizeUniversalProfile({required this.byStage, required this.weights});

  final Map<MaizeStageKey, StageTargets> byStage;
  final Map<MaizeStageKey, StageWeights> weights;
}

/// Ficha Universal Maíz v1 (ajustada):
/// - Humedad: raw% (0..100) del sensor (0 aire – 100 agua).
///   ✅ Rango óptimo subido y rangos acortados para que 25% NO sea “óptimo”.
///   ✅ flowerSet más estricto.
/// - Compactación: MPa (no índice). ✅ No penaliza por “bajo”, solo por “alto”.
/// - NPK: índices 0..100 por etapa (no ppm “universales”).
const maizeUniversalV1 = MaizeUniversalProfile(
  byStage: {
    // =========================
    // GERMINATION / EMERGENCE
    // =========================
    MaizeStageKey.germination: StageTargets(
      // ✅ Semilla necesita buen colchón de humedad (subimos óptimo)
      moistureRaw: AgroRange(
        lowMax: 12,
        optimalMin: 30,
        optimalMax: 75,
        highMin: 85,
      ),
      soilTemp: AgroRange(
        lowMax: 12,
        optimalMin: 18,
        optimalMax: 28,
        highMin: 34,
      ),
      // ✅ Germinación: plántula sensible a pH extremo → rango más estrecho
      ph: AgroRange(
        lowMax: 5.8,
        optimalMin: 6.0,
        optimalMax: 6.5,
        highMin: 7.0,
      ),
      // ✅ Germinación: raíz incipiente muy sensible a salinidad
      ec: AgroRange(
        lowMax: 0.4,
        optimalMin: 0.5,
        optimalMax: 1.2,
        highMin: 2.0,
      ),
      // ✅ MPa: no hay “crítico por bajo”; crítico solo por arriba de highMin
      resistance: AgroRange(
        lowMax: -1.0,
        optimalMin: 0.0,
        optimalMax: 1.2,
        highMin: 1.8,
      ),
      nIndex: AgroRange(
        lowMax: 12,
        optimalMin: 22,
        optimalMax: 48,
        highMin: 66,
      ),
      pIndex: AgroRange(
        lowMax: 10,
        optimalMin: 20,
        optimalMax: 45,
        highMin: 62,
      ),
      kIndex: AgroRange(
        lowMax: 15,
        optimalMin: 28,
        optimalMax: 62,
        highMin: 80,
      ),
      nPriority: 0.28,
      pPriority: 0.58,
      kPriority: 0.32,
      nWindowLabelEs: 'Base de arranque de N',
      pWindowLabelEs: 'Arranque, raíces y energía',
      kWindowLabelEs: 'Balance inicial y vigor',
      nShortGuidanceEs: 'Lectura temprana de N; aquí importa no arrancar corto.',
      pShortGuidanceEs: 'P pesa fuerte desde arranque por raíces y uniformidad.',
      kShortGuidanceEs: 'K acompaña vigor temprano y balance fisiológico.',
      nPlannerHintEs: 'Si no hubo base, usa una dosis corta de arranque; no empujes N fuerte todavía.',
      pPlannerHintEs: 'Si el arranque viene corto, prioriza P bien colocado cerca de la semilla.',
      kPlannerHintEs: 'No muevas K por rutina; corrige solo si el soporte del lote es bajo.',
      nConfidence01: 0.76,
      pConfidence01: 0.82,
      kConfidence01: 0.70,
    ),

    MaizeStageKey.emergence: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 12,
        optimalMin: 30,
        optimalMax: 72,
        highMin: 85,
      ),
      soilTemp: AgroRange(
        lowMax: 12,
        optimalMin: 18,
        optimalMax: 28,
        highMin: 34,
      ),
      // ✅ Emergencia: plántula aún sensible a pH extremo
      ph: AgroRange(
        lowMax: 5.8,
        optimalMin: 6.0,
        optimalMax: 6.5,
        highMin: 7.0,
      ),
      // ✅ Emergencia: raíz joven, sensible a salinidad
      ec: AgroRange(
        lowMax: 0.4,
        optimalMin: 0.5,
        optimalMax: 1.3,
        highMin: 2.0,
      ),
      resistance: AgroRange(
        lowMax: -1.0,
        optimalMin: 0.0,
        optimalMax: 1.2,
        highMin: 1.8,
      ),
      nIndex: AgroRange(
        lowMax: 12,
        optimalMin: 24,
        optimalMax: 48,
        highMin: 66,
      ),
      pIndex: AgroRange(
        lowMax: 10,
        optimalMin: 20,
        optimalMax: 45,
        highMin: 62,
      ),
      kIndex: AgroRange(
        lowMax: 15,
        optimalMin: 28,
        optimalMax: 63,
        highMin: 80,
      ),
      nPriority: 0.34,
      pPriority: 0.60,
      kPriority: 0.36,
      nWindowLabelEs: 'Base de arranque de N',
      pWindowLabelEs: 'Arranque, raíces y energía',
      kWindowLabelEs: 'Balance inicial y vigor',
      nShortGuidanceEs: 'Seguimiento temprano de N antes del tramo fuerte.',
      pShortGuidanceEs: 'P sigue siendo nutriente clave en emergencia.',
      kShortGuidanceEs: 'K acompaña vigor y balance temprano.',
      nPlannerHintEs: 'Asegura una base corta de N si el lote arrancó sin soporte.',
      pPlannerHintEs: 'Starter o banda corta de P tiene más valor aquí que una corrección tardía.',
      kPlannerHintEs: 'Revisa K si el lote es arenoso o ya traía antecedentes bajos.',
      nConfidence01: 0.78,
      pConfidence01: 0.84,
      kConfidence01: 0.72,
    ),

    // =========================
    // VEGETATIVE
    // =========================
    MaizeStageKey.vegEarly: StageTargets(
      // ✅ aquí es donde te pegaba el 25% “óptimo”: lo corregimos
      moistureRaw: AgroRange(
        lowMax: 12,
        optimalMin: 32,
        optimalMax: 70,
        highMin: 85,
      ),
      soilTemp: AgroRange(
        lowMax: 14,
        optimalMin: 18,
        optimalMax: 30,
        highMin: 36,
      ),
      // ✅ Veg temprana: raíz en expansión, pH estándar maíz
      ph: AgroRange(
        lowMax: 5.6,
        optimalMin: 5.8,
        optimalMax: 6.8,
        highMin: 7.2,
      ),
      // ✅ Veg temprana: tolerancia intermedia a salinidad
      ec: AgroRange(
        lowMax: 0.5,
        optimalMin: 0.6,
        optimalMax: 1.5,
        highMin: 2.3,
      ),
      resistance: AgroRange(
        lowMax: -1.0,
        optimalMin: 0.0,
        optimalMax: 1.5,
        highMin: 2.0,
      ),
      nIndex: AgroRange(
        lowMax: 12,
        optimalMin: 25,
        optimalMax: 50,
        highMin: 68,
      ),
      pIndex: AgroRange(
        lowMax: 10,
        optimalMin: 20,
        optimalMax: 45,
        highMin: 62,
      ),
      kIndex: AgroRange(
        lowMax: 15,
        optimalMin: 30,
        optimalMax: 65,
        highMin: 82,
      ),
      nPriority: 0.44,
      pPriority: 0.62,
      kPriority: 0.40,
      nWindowLabelEs: 'Base previa a V6',
      pWindowLabelEs: 'Arranque, raíces y energía',
      kWindowLabelEs: 'Balance inicial y vigor',
      nShortGuidanceEs: 'Todavía no es el pico de N, pero no conviene llegar corto a V6.',
      pShortGuidanceEs: 'P sigue sosteniendo establecimiento y uniformidad.',
      kShortGuidanceEs: 'K acompaña vigor y balance hídrico temprano.',
      nPlannerHintEs: 'Si la base fue débil, corrige antes de que el cultivo entre a demanda fuerte.',
      pPlannerHintEs: 'Si el arranque fosfatado no quedó bien, todavía pesa más planear que corregir tarde.',
      kPlannerHintEs: 'Valida si el lote trae respaldo suficiente de K antes del crecimiento fuerte.',
      nConfidence01: 0.80,
      pConfidence01: 0.84,
      kConfidence01: 0.74,
    ),

    MaizeStageKey.vegMid: StageTargets(
      // ✅ antes: optimalMin 22 -> ahora subimos
      moistureRaw: AgroRange(
        lowMax: 12,
        optimalMin: 32,
        optimalMax: 68,
        highMin: 85,
      ),
      soilTemp: AgroRange(
        lowMax: 14,
        optimalMin: 18,
        optimalMax: 30,
        highMin: 36,
      ),
      ph: AgroRange(
        lowMax: 5.6,
        optimalMin: 5.8,
        optimalMax: 6.8,
        highMin: 7.2,
      ),
      ec: AgroRange(
        lowMax: 0.7,
        optimalMin: 0.7,
        optimalMax: 1.7,
        highMin: 2.6,
      ),
      resistance: AgroRange(
        lowMax: -1.0,
        optimalMin: 0.0,
        optimalMax: 1.5,
        highMin: 2.0,
      ),
      nIndex: AgroRange(
        lowMax: 14,
        optimalMin: 26,
        optimalMax: 52,
        highMin: 68,
      ),
      pIndex: AgroRange(
        lowMax: 10,
        optimalMin: 20,
        optimalMax: 45,
        highMin: 62,
      ),
      kIndex: AgroRange(
        lowMax: 15,
        optimalMin: 30,
        optimalMax: 65,
        highMin: 82,
      ),
      nPriority: 0.72,
      pPriority: 0.42,
      kPriority: 0.56,
      nWindowLabelEs: 'Tramo fuerte de N (V6-V8)',
      pWindowLabelEs: 'Soporte de crecimiento',
      kWindowLabelEs: 'Agua, estructura y balance',
      nShortGuidanceEs: 'N entra en tramo fuerte y ya pesa en la decisión del lote.',
      pShortGuidanceEs: 'P pasa a soporte; normalmente pierde prioridad frente a N.',
      kShortGuidanceEs: 'K gana peso conforme sube demanda y estrés.',
      nPlannerHintEs: 'Aquí suele entrar la mayor parte del plan de N; revisa cobertura real.',
      pPlannerHintEs: 'Confirma si hace falta ajustar base de P o documentarlo para el siguiente ciclo.',
      kPlannerHintEs: 'Revisa K si hay arena, baja CEC o presión hídrica.',
      nConfidence01: 0.88,
      pConfidence01: 0.78,
      kConfidence01: 0.80,
    ),

    MaizeStageKey.vegAdvanced: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 12,
        optimalMin: 32,
        optimalMax: 70,
        highMin: 85,
      ),
      soilTemp: AgroRange(
        lowMax: 14,
        optimalMin: 18,
        optimalMax: 30,
        highMin: 36,
      ),
      ph: AgroRange(
        lowMax: 5.6,
        optimalMin: 5.8,
        optimalMax: 6.8,
        highMin: 7.2,
      ),
      ec: AgroRange(
        lowMax: 0.7,
        optimalMin: 0.7,
        optimalMax: 1.7,
        highMin: 2.6,
      ),
      resistance: AgroRange(
        lowMax: -1.0,
        optimalMin: 0.0,
        optimalMax: 1.6,
        highMin: 2.1,
      ),
      nIndex: AgroRange(
        lowMax: 14,
        optimalMin: 28,
        optimalMax: 52,
        highMin: 70,
      ),
      pIndex: AgroRange(
        lowMax: 10,
        optimalMin: 20,
        optimalMax: 45,
        highMin: 62,
      ),
      kIndex: AgroRange(
        lowMax: 15,
        optimalMin: 32,
        optimalMax: 66,
        highMin: 82,
      ),
      nPriority: 0.82,
      pPriority: 0.38,
      kPriority: 0.64,
      nWindowLabelEs: 'Tramo fuerte de N (V6 a pre-espiga)',
      pWindowLabelEs: 'Soporte de crecimiento',
      kWindowLabelEs: 'Agua, estructura y balance',
      nShortGuidanceEs: 'N sigue siendo nutriente clave al acercarse a espigamiento.',
      pShortGuidanceEs: 'P aquí se interpreta más como soporte que como urgencia tardía.',
      kShortGuidanceEs: 'K ya pesa más en balance hídrico y estructura.',
      nPlannerHintEs: 'Valida si el plan principal de N ya cubrió la ventana fuerte o si falta complemento.',
      pPlannerHintEs: 'Si P quedó corto, normalmente conviene corregir mejor pre-siembra del siguiente ciclo.',
      kPlannerHintEs: 'Bajo calor o sequía, conviene revisar K antes de entrar a reproductivo.',
      nConfidence01: 0.90,
      pConfidence01: 0.76,
      kConfidence01: 0.82,
    ),

    // =========================
    // REPRODUCTIVE
    // =========================
    MaizeStageKey.tasseling: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 15,
        optimalMin: 35,
        optimalMax: 75,
        highMin: 88,
      ),
      soilTemp: AgroRange(
        lowMax: 15,
        optimalMin: 18,
        optimalMax: 30,
        highMin: 35,
      ),
      // ✅ Tasseling: etapa crítica reproductiva → pH más estrecho
      ph: AgroRange(
        lowMax: 5.8,
        optimalMin: 6.0,
        optimalMax: 6.8,
        highMin: 7.0,
      ),
      // ✅ Tasseling: sensibilidad moderada a salinidad
      ec: AgroRange(
        lowMax: 0.6,
        optimalMin: 0.7,
        optimalMax: 1.6,
        highMin: 2.4,
      ),
      resistance: AgroRange(
        lowMax: -1.0,
        optimalMin: 0.0,
        optimalMax: 1.6,
        highMin: 2.1,
      ),
      nIndex: AgroRange(
        lowMax: 14,
        optimalMin: 28,
        optimalMax: 52,
        highMin: 70,
      ),
      pIndex: AgroRange(
        lowMax: 10,
        optimalMin: 20,
        optimalMax: 45,
        highMin: 62,
      ),
      kIndex: AgroRange(
        lowMax: 16,
        optimalMin: 33,
        optimalMax: 68,
        highMin: 84,
      ),
      nPriority: 0.90,
      pPriority: 0.34,
      kPriority: 0.74,
      nWindowLabelEs: 'Pico de demanda de N',
      pWindowLabelEs: 'Balance reproductivo de P',
      kWindowLabelEs: 'Agua, tallo y balance',
      nShortGuidanceEs: 'Tasseling es ventana fuerte para N y no conviene llegar corto.',
      pShortGuidanceEs: 'P aquí se vigila más como balance del sistema.',
      kShortGuidanceEs: 'K pesa en agua, tallo y estabilidad fisiológica.',
      nPlannerHintEs: 'Si hubo pérdidas o el lote quedó corto, esta es la última ventana útil para ajustar N.',
      pPlannerHintEs: 'Evita sobredosificar P tarde; confirma mejor estrategia para el siguiente ciclo.',
      kPlannerHintEs: 'Revisa K si hay estrés hídrico o tallo débil antes de floración.',
      nConfidence01: 0.92,
      pConfidence01: 0.74,
      kConfidence01: 0.86,
    ),

    // Etapa crítica
    MaizeStageKey.flowerSet: StageTargets(
      // ✅ más estricto para que al bajar empiece a alertar antes
      moistureRaw: AgroRange(
        lowMax: 15,
        optimalMin: 40,
        optimalMax: 78,
        highMin: 90,
      ),
      soilTemp: AgroRange(
        lowMax: 15,
        optimalMin: 18,
        optimalMax: 30,
        highMin: 35,
      ),
      // ✅ FlowerSet: máxima sensibilidad reproductiva → pH estrecho
      ph: AgroRange(
        lowMax: 5.8,
        optimalMin: 6.0,
        optimalMax: 6.8,
        highMin: 7.0,
      ),
      // ✅ FlowerSet: salinidad moderada-baja para no estresar polinización
      ec: AgroRange(
        lowMax: 0.6,
        optimalMin: 0.7,
        optimalMax: 1.5,
        highMin: 2.3,
      ),
      resistance: AgroRange(
        lowMax: -1.0,
        optimalMin: 0.0,
        optimalMax: 1.6,
        highMin: 2.1,
      ),
      nIndex: AgroRange(
        lowMax: 60,
        optimalMin: 70,
        optimalMax: 90,
        highMin: 98,
      ),
      pIndex: AgroRange(
        lowMax: 35,
        optimalMin: 45,
        optimalMax: 65,
        highMin: 75,
      ),
      kIndex: AgroRange(
        lowMax: 60,
        optimalMin: 70,
        optimalMax: 90,
        highMin: 98,
      ),
      nPriority: 0.92,
      pPriority: 0.30,
      kPriority: 0.78,
      nWindowLabelEs: 'N en floración y cuajado',
      pWindowLabelEs: 'Balance reproductivo de P',
      kWindowLabelEs: 'Soporte hídrico y llenado',
      nShortGuidanceEs: 'En floración la lectura de N pesa mucho más que en arranque.',
      pShortGuidanceEs: 'P aquí actúa más como balance del sistema que como corrección típica.',
      kShortGuidanceEs: 'K ayuda a sostener agua, tallo y funcionamiento del cultivo.',
      nPlannerHintEs: 'Si todavía existe ventana útil y hubo pérdidas, evalúa complemento corto de N.',
      pPlannerHintEs: 'La mejor corrección fuerte de P suele quedar para pre-siembra o arranque del siguiente ciclo.',
      kPlannerHintEs: 'Con calor o déficit hídrico, vigila K porque su peso aquí sí aumenta.',
      nConfidence01: 0.94,
      pConfidence01: 0.72,
      kConfidence01: 0.88,
    ),

    // =========================
    // LATE SEASON
    // =========================
    MaizeStageKey.maturitySenescence: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 10,
        optimalMin: 28,
        optimalMax: 60,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 15,
        optimalMin: 18,
        optimalMax: 30,
        highMin: 35,
      ),
      // ✅ Madurez: planta más tolerante, rango pH más amplio
      ph: AgroRange(
        lowMax: 5.4,
        optimalMin: 5.6,
        optimalMax: 7.0,
        highMin: 7.4,
      ),
      // ✅ Madurez: mayor tolerancia a salinidad
      ec: AgroRange(
        lowMax: 0.6,
        optimalMin: 0.7,
        optimalMax: 2.0,
        highMin: 3.0,
      ),
      resistance: AgroRange(
        lowMax: -1.0,
        optimalMin: 0.0,
        optimalMax: 1.8,
        highMin: 2.3,
      ),
      nIndex: AgroRange(
        lowMax: 45,
        optimalMin: 55,
        optimalMax: 75,
        highMin: 85,
      ),
      pIndex: AgroRange(
        lowMax: 30,
        optimalMin: 40,
        optimalMax: 60,
        highMin: 70,
      ),
      kIndex: AgroRange(
        lowMax: 50,
        optimalMin: 60,
        optimalMax: 80,
        highMin: 90,
      ),
      nPriority: 0.46,
      pPriority: 0.22,
      kPriority: 0.52,
      nWindowLabelEs: 'Sostén final y cierre de N',
      pWindowLabelEs: 'Cierre de ciclo de P',
      kWindowLabelEs: 'Balance final de K',
      nShortGuidanceEs: 'N ya se interpreta más como cierre que como empuje fuerte.',
      pShortGuidanceEs: 'P entra como lectura de soporte y planeación.',
      kShortGuidanceEs: 'K todavía sirve para balance final del lote.',
      nPlannerHintEs: 'Usa esta lectura para cierre del plan y aprendizaje del siguiente ciclo.',
      pPlannerHintEs: 'Evita correcciones fuertes tardías de P; documenta el ajuste para pre-siembra.',
      kPlannerHintEs: 'Si K viene muy corto, úsalo para planear mejor la base del siguiente ciclo.',
      nConfidence01: 0.78,
      pConfidence01: 0.70,
      kConfidence01: 0.76,
    ),

    MaizeStageKey.harvest: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 8,
        optimalMin: 20,
        optimalMax: 45,
        highMin: 75,
      ),
      soilTemp: AgroRange(
        lowMax: 12,
        optimalMin: 18,
        optimalMax: 30,
        highMin: 36,
      ),
      // ✅ Cosecha: máxima tolerancia, planta ya senescente
      ph: AgroRange(
        lowMax: 5.2,
        optimalMin: 5.5,
        optimalMax: 7.2,
        highMin: 7.5,
      ),
      // ✅ Cosecha: EC muy tolerante, planta no absorbe activamente
      ec: AgroRange(
        lowMax: 0.5,
        optimalMin: 0.7,
        optimalMax: 2.2,
        highMin: 3.2,
      ),
      resistance: AgroRange(
        lowMax: -1.0,
        optimalMin: 0.0,
        optimalMax: 2.0,
        highMin: 2.5,
      ),
      nIndex: AgroRange(
        lowMax: 30,
        optimalMin: 40,
        optimalMax: 60,
        highMin: 70,
      ),
      pIndex: AgroRange(
        lowMax: 25,
        optimalMin: 35,
        optimalMax: 55,
        highMin: 65,
      ),
      kIndex: AgroRange(
        lowMax: 35,
        optimalMin: 45,
        optimalMax: 65,
        highMin: 75,
      ),
      nPriority: 0.18,
      pPriority: 0.15,
      kPriority: 0.20,
      nWindowLabelEs: 'Cierre y trazabilidad de N',
      pWindowLabelEs: 'Cierre de ciclo de P',
      kWindowLabelEs: 'Cierre y balance de K',
      nShortGuidanceEs: 'La lectura de N aquí sirve para cierre y trazabilidad.',
      pShortGuidanceEs: 'La lectura de P aquí pesa más como referencia del lote.',
      kShortGuidanceEs: 'La lectura de K aquí sirve para balance final y planeación.',
      nPlannerHintEs: 'No empujes N por rutina en cosecha; usa el dato para ajustar el siguiente plan.',
      pPlannerHintEs: 'Evita correcciones de P en cosecha; documenta el dato para el siguiente ciclo.',
      kPlannerHintEs: 'Usa la lectura de K como referencia del balance final del lote.',
      nConfidence01: 0.68,
      pConfidence01: 0.66,
      kConfidence01: 0.68,
    ),
  },

  // Pesos para el ring (control del suelo).
  weights: {
    // soilTemp: maíz C4 muy sensible a temp de suelo en germinación
    MaizeStageKey.germination: StageWeights(
      moisture: 0.26,
      soilTemp: 0.10,
      resistance: 0.26,
      ph: 0.14,
      ec: 0.10,
      npk: 0.14,
    ),
    MaizeStageKey.emergence: StageWeights(
      moisture: 0.26,
      soilTemp: 0.10,
      resistance: 0.26,
      ph: 0.14,
      ec: 0.10,
      npk: 0.14,
    ),

    MaizeStageKey.vegEarly: StageWeights(
      moisture: 0.23,
      soilTemp: 0.06,
      resistance: 0.23,
      ph: 0.14,
      ec: 0.10,
      npk: 0.24,
    ),
    MaizeStageKey.vegMid: StageWeights(
      moisture: 0.23,
      soilTemp: 0.06,
      resistance: 0.23,
      ph: 0.14,
      ec: 0.10,
      npk: 0.24,
    ),
    MaizeStageKey.vegAdvanced: StageWeights(
      moisture: 0.23,
      soilTemp: 0.06,
      resistance: 0.23,
      ph: 0.14,
      ec: 0.10,
      npk: 0.24,
    ),

    MaizeStageKey.tasseling: StageWeights(
      moisture: 0.25,
      soilTemp: 0.05,
      resistance: 0.18,
      ph: 0.12,
      ec: 0.10,
      npk: 0.30,
    ),
    MaizeStageKey.flowerSet: StageWeights(
      moisture: 0.28,
      soilTemp: 0.05,
      resistance: 0.18,
      ph: 0.09,
      ec: 0.10,
      npk: 0.30,
    ),

    MaizeStageKey.maturitySenescence: StageWeights(
      moisture: 0.20,
      soilTemp: 0.04,
      resistance: 0.20,
      ph: 0.18,
      ec: 0.10,
      npk: 0.28,
    ),
    MaizeStageKey.harvest: StageWeights(
      moisture: 0.18,
      soilTemp: 0.04,
      resistance: 0.18,
      ph: 0.20,
      ec: 0.10,
      npk: 0.30,
    ),
  },
);
