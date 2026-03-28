import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/barley_models.dart';

class BarleyUniversalProfile {
  const BarleyUniversalProfile({required this.byStage, required this.weights});

  final Map<BarleyStageKey, StageTargets> byStage;
  final Map<BarleyStageKey, StageWeights> weights;
}

// ── pH diferenciado por grupo de etapa ──────────────────────────
// Cebada tolera pH más alcalino que trigo (hasta 8.5 en campo).
// Germinación/emergencia: plántula sensible
const AgroRange _barleyPhEarly = AgroRange(
  lowMax: 5.6,
  optimalMin: 6.0,
  optimalMax: 7.5,
  highMin: 8.0,
);

// Vegetativo: rango amplio, cebada es tolerante
const AgroRange _barleyPhVeg = AgroRange(
  lowMax: 5.5,
  optimalMin: 5.8,
  optimalMax: 8.0,
  highMin: 8.5,
);

// Heading/flowering: más estrecho para absorción de nutrientes
const AgroRange _barleyPhFlowering = AgroRange(
  lowMax: 5.8,
  optimalMin: 6.0,
  optimalMax: 7.5,
  highMin: 8.0,
);

// Madurez/cosecha: muy tolerante
const AgroRange _barleyPhLate = AgroRange(
  lowMax: 5.3,
  optimalMin: 5.6,
  optimalMax: 8.2,
  highMin: 8.8,
);

// ── EC diferenciado ─────────────────────────────────────────────
// Cebada es el cereal MÁS tolerante a salinidad
const AgroRange _barleyEcEarly = AgroRange(
  lowMax: 0.4,
  optimalMin: 0.5,
  optimalMax: 3.0,
  highMin: 5.0,
);

const AgroRange _barleyEcVeg = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 4.0,
  highMin: 7.0,
);

const AgroRange _barleyEcFlowering = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 3.5,
  highMin: 6.0,
);

const AgroRange _barleyEcLate = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 5.0,
  highMin: 8.0,
);

// ── Resistencia (MPa) ───────────────────────────────────────────
// Cebada: raíces más superficiales → heading mantiene Early (más estricto)
const AgroRange _barleyResistanceEarly = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 1.2,
  highMin: 2.0,
);

const AgroRange _barleyResistanceLate = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 1.6,
  highMin: 2.0,
);

const BarleyUniversalProfile barleyUniversalV1 = BarleyUniversalProfile(
  byStage: {
    // =========================
    // GERMINATION / EMERGENCE
    // =========================
    BarleyStageKey.germination: StageTargets(
      moistureRaw: AgroRange(lowMax: 14, optimalMin: 30, optimalMax: 72, highMin: 86),
      soilTemp: AgroRange(lowMax: 4, optimalMin: 12, optimalMax: 25, highMin: 34),
      ph: _barleyPhEarly,
      ec: _barleyEcEarly,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(lowMax: 22, optimalMin: 30, optimalMax: 50, highMin: 60),
      pIndex: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 78, highMin: 88),
      kIndex: AgroRange(lowMax: 28, optimalMin: 38, optimalMax: 58, highMin: 68),
    ),
    BarleyStageKey.emergence: StageTargets(
      moistureRaw: AgroRange(lowMax: 14, optimalMin: 30, optimalMax: 70, highMin: 85),
      soilTemp: AgroRange(lowMax: 4, optimalMin: 12, optimalMax: 25, highMin: 34),
      ph: _barleyPhEarly,
      ec: _barleyEcEarly,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(lowMax: 25, optimalMin: 34, optimalMax: 54, highMin: 64),
      pIndex: AgroRange(lowMax: 48, optimalMin: 58, optimalMax: 80, highMin: 90),
      kIndex: AgroRange(lowMax: 32, optimalMin: 42, optimalMax: 62, highMin: 72),
    ),

    // =========================
    // VEGETATIVE
    // =========================
    BarleyStageKey.vegEarly: StageTargets(
      moistureRaw: AgroRange(lowMax: 12, optimalMin: 28, optimalMax: 66, highMin: 82),
      soilTemp: AgroRange(lowMax: 6, optimalMin: 14, optimalMax: 26, highMin: 34),
      ph: _barleyPhVeg,
      ec: _barleyEcVeg,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(lowMax: 30, optimalMin: 40, optimalMax: 62, highMin: 72),
      pIndex: AgroRange(lowMax: 50, optimalMin: 60, optimalMax: 82, highMin: 90),
      kIndex: AgroRange(lowMax: 38, optimalMin: 48, optimalMax: 68, highMin: 78),
    ),
    BarleyStageKey.tillering: StageTargets(
      moistureRaw: AgroRange(lowMax: 14, optimalMin: 30, optimalMax: 68, highMin: 82),
      soilTemp: AgroRange(lowMax: 6, optimalMin: 14, optimalMax: 26, highMin: 34),
      ph: _barleyPhVeg,
      ec: _barleyEcVeg,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(lowMax: 38, optimalMin: 48, optimalMax: 72, highMin: 82),
      pIndex: AgroRange(lowMax: 46, optimalMin: 56, optimalMax: 76, highMin: 86),
      kIndex: AgroRange(lowMax: 42, optimalMin: 52, optimalMax: 72, highMin: 82),
    ),
    BarleyStageKey.elongation: StageTargets(
      moistureRaw: AgroRange(lowMax: 16, optimalMin: 34, optimalMax: 70, highMin: 82),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 32),
      ph: _barleyPhVeg,
      ec: _barleyEcVeg,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(lowMax: 48, optimalMin: 58, optimalMax: 82, highMin: 92),
      pIndex: AgroRange(lowMax: 40, optimalMin: 50, optimalMax: 70, highMin: 80),
      kIndex: AgroRange(lowMax: 50, optimalMin: 60, optimalMax: 80, highMin: 90),
    ),
    BarleyStageKey.booting: StageTargets(
      moistureRaw: AgroRange(lowMax: 18, optimalMin: 38, optimalMax: 74, highMin: 86),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 31),
      ph: _barleyPhFlowering,
      ec: _barleyEcFlowering,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(lowMax: 42, optimalMin: 52, optimalMax: 75, highMin: 85),
      pIndex: AgroRange(lowMax: 38, optimalMin: 48, optimalMax: 68, highMin: 78),
      kIndex: AgroRange(lowMax: 54, optimalMin: 64, optimalMax: 84, highMin: 92),
    ),

    // =========================
    // REPRODUCTIVE
    // =========================
    // ✅ heading mantiene resistanceEarly (raíces superficiales de cebada)
    BarleyStageKey.heading: StageTargets(
      moistureRaw: AgroRange(lowMax: 20, optimalMin: 40, optimalMax: 76, highMin: 86),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 31),
      ph: _barleyPhFlowering,
      ec: _barleyEcFlowering,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(lowMax: 38, optimalMin: 48, optimalMax: 70, highMin: 80),
      pIndex: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 65, highMin: 75),
      kIndex: AgroRange(lowMax: 56, optimalMin: 66, optimalMax: 86, highMin: 94),
    ),
    BarleyStageKey.flowering: StageTargets(
      moistureRaw: AgroRange(lowMax: 22, optimalMin: 42, optimalMax: 78, highMin: 88),
      soilTemp: AgroRange(lowMax: 10, optimalMin: 15, optimalMax: 26, highMin: 31),
      ph: _barleyPhFlowering,
      ec: _barleyEcFlowering,
      resistance: _barleyResistanceLate,
      nIndex: AgroRange(lowMax: 32, optimalMin: 40, optimalMax: 65, highMin: 75),
      pIndex: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 65, highMin: 75),
      kIndex: AgroRange(lowMax: 58, optimalMin: 68, optimalMax: 88, highMin: 95),
    ),

    // =========================
    // LATE SEASON
    // =========================
    BarleyStageKey.grainFill: StageTargets(
      moistureRaw: AgroRange(lowMax: 18, optimalMin: 38, optimalMax: 72, highMin: 82),
      soilTemp: AgroRange(lowMax: 10, optimalMin: 15, optimalMax: 28, highMin: 35),
      ph: _barleyPhVeg,
      ec: _barleyEcVeg,
      resistance: _barleyResistanceLate,
      nIndex: AgroRange(lowMax: 26, optimalMin: 34, optimalMax: 58, highMin: 68),
      pIndex: AgroRange(lowMax: 32, optimalMin: 42, optimalMax: 62, highMin: 72),
      kIndex: AgroRange(lowMax: 62, optimalMin: 70, optimalMax: 90, highMin: 96),
    ),
    BarleyStageKey.physiologicalMaturity: StageTargets(
      moistureRaw: AgroRange(lowMax: 10, optimalMin: 22, optimalMax: 48, highMin: 65),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 32),
      ph: _barleyPhLate,
      ec: _barleyEcLate,
      resistance: _barleyResistanceLate,
      nIndex: AgroRange(lowMax: 16, optimalMin: 24, optimalMax: 42, highMin: 52),
      pIndex: AgroRange(lowMax: 28, optimalMin: 38, optimalMax: 58, highMin: 68),
      kIndex: AgroRange(lowMax: 42, optimalMin: 50, optimalMax: 70, highMin: 80),
    ),
    BarleyStageKey.harvest: StageTargets(
      moistureRaw: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 38, highMin: 55),
      soilTemp: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 26, highMin: 34),
      ph: _barleyPhLate,
      ec: _barleyEcLate,
      resistance: _barleyResistanceLate,
      nIndex: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 35, highMin: 45),
      pIndex: AgroRange(lowMax: 24, optimalMin: 34, optimalMax: 54, highMin: 64),
      kIndex: AgroRange(lowMax: 36, optimalMin: 44, optimalMax: 64, highMin: 74),
    ),
  },

  // ✅ Pesos diferenciados de trigo:
  // Cebada es más eficiente en uso de agua → moisture ligeramente menor en veg
  // Cebada menos demandante de N en etapas tardías → npk menor en grainFill+
  weights: {
    // soilTemp: cebada C3 estación fría — temp suelo importa en germinación
    BarleyStageKey.germination: StageWeights(
      moisture: 0.28,
      soilTemp: 0.08,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      npk: 0.22,
    ),
    BarleyStageKey.emergence: StageWeights(
      moisture: 0.28,
      soilTemp: 0.08,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      npk: 0.22,
    ),
    BarleyStageKey.vegEarly: StageWeights(
      moisture: 0.22,
      soilTemp: 0.06,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      npk: 0.30,
    ),
    BarleyStageKey.tillering: StageWeights(
      moisture: 0.22,
      soilTemp: 0.06,
      resistance: 0.18,
      ph: 0.10,
      ec: 0.12,
      npk: 0.32,
    ),
    BarleyStageKey.elongation: StageWeights(
      moisture: 0.26,
      soilTemp: 0.06,
      resistance: 0.14,
      ph: 0.10,
      ec: 0.12,
      npk: 0.32,
    ),
    BarleyStageKey.booting: StageWeights(
      moisture: 0.28,
      soilTemp: 0.06,
      resistance: 0.10,
      ph: 0.08,
      ec: 0.12,
      npk: 0.36,
    ),
    BarleyStageKey.heading: StageWeights(
      moisture: 0.34,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.34,
    ),
    BarleyStageKey.flowering: StageWeights(
      moisture: 0.34,
      soilTemp: 0.06,
      resistance: 0.06,
      ph: 0.08,
      ec: 0.12,
      npk: 0.34,
    ),
    BarleyStageKey.grainFill: StageWeights(
      moisture: 0.32,
      soilTemp: 0.04,
      resistance: 0.10,
      ph: 0.08,
      ec: 0.12,
      npk: 0.34,
    ),
    BarleyStageKey.physiologicalMaturity: StageWeights(
      moisture: 0.28,
      soilTemp: 0.04,
      resistance: 0.16,
      ph: 0.12,
      ec: 0.12,
      npk: 0.28,
    ),
    BarleyStageKey.harvest: StageWeights(
      moisture: 0.24,
      soilTemp: 0.04,
      resistance: 0.16,
      ph: 0.14,
      ec: 0.14,
      npk: 0.28,
    ),
  },
);
