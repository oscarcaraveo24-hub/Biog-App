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
        lowMax: 25,
        optimalMin: 35,
        optimalMax: 55,
        highMin: 65,
      ),
      pIndex: AgroRange(
        lowMax: 45,
        optimalMin: 55,
        optimalMax: 75,
        highMin: 85,
      ),
      kIndex: AgroRange(
        lowMax: 30,
        optimalMin: 40,
        optimalMax: 60,
        highMin: 70,
      ),
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
        lowMax: 30,
        optimalMin: 40,
        optimalMax: 60,
        highMin: 70,
      ),
      pIndex: AgroRange(
        lowMax: 45,
        optimalMin: 55,
        optimalMax: 75,
        highMin: 85,
      ),
      kIndex: AgroRange(
        lowMax: 35,
        optimalMin: 45,
        optimalMax: 65,
        highMin: 75,
      ),
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
        lowMax: 45,
        optimalMin: 55,
        optimalMax: 75,
        highMin: 85,
      ),
      pIndex: AgroRange(
        lowMax: 40,
        optimalMin: 50,
        optimalMax: 70,
        highMin: 80,
      ),
      kIndex: AgroRange(
        lowMax: 40,
        optimalMin: 50,
        optimalMax: 70,
        highMin: 80,
      ),
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
        lowMax: 50,
        optimalMin: 60,
        optimalMax: 85,
        highMin: 95,
      ),
      pIndex: AgroRange(
        lowMax: 35,
        optimalMin: 45,
        optimalMax: 65,
        highMin: 75,
      ),
      kIndex: AgroRange(
        lowMax: 45,
        optimalMin: 55,
        optimalMax: 75,
        highMin: 85,
      ),
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
        lowMax: 55,
        optimalMin: 65,
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
        lowMax: 50,
        optimalMin: 60,
        optimalMax: 80,
        highMin: 90,
      ),
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
        lowMax: 55,
        optimalMin: 65,
        optimalMax: 85,
        highMin: 95,
      ),
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
