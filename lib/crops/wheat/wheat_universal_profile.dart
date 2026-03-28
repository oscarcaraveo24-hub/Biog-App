// Perfil Universal de Trigo (Triticum spp.)
// Basado en datos agronómicos para clima templado-frío (C3)
// Incluye 11 estadios fenológicos con rangos de tolerancia y sensibilidades específicas

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/wheat_models.dart';

class WheatUniversalProfile {
  const WheatUniversalProfile({required this.byStage, required this.weights});

  final Map<WheatStageKey, StageTargets> byStage;
  final Map<WheatStageKey, StageWeights> weights;
}

// ── pH diferenciado por grupo de etapa ──────────────────────────
// ✅ Trigo óptimo 6.0-7.5. El rango alto 7.8 era agresivo para suelos calcáreos MX.
// Germinación/emergencia: plántula sensible
const AgroRange _wheatPhEarly = AgroRange(
  lowMax: 5.6,
  optimalMin: 6.0,
  optimalMax: 7.2,
  highMin: 7.6,
);

// Vegetativo: rango estándar trigo
const AgroRange _wheatPhVeg = AgroRange(
  lowMax: 5.5,
  optimalMin: 5.8,
  optimalMax: 7.5,
  highMin: 8.0,
);

// Heading/flowering: más estrecho para máxima absorción
const AgroRange _wheatPhFlowering = AgroRange(
  lowMax: 5.8,
  optimalMin: 6.0,
  optimalMax: 7.2,
  highMin: 7.5,
);

// Madurez/cosecha: tolerante
const AgroRange _wheatPhLate = AgroRange(
  lowMax: 5.3,
  optimalMin: 5.6,
  optimalMax: 7.8,
  highMin: 8.2,
);

// ── EC diferenciado ─────────────────────────────────────────────
// Emergencia sensible, cosecha tolerante
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
      moistureRaw: AgroRange(lowMax: 14, optimalMin: 30, optimalMax: 72, highMin: 86),
      soilTemp: AgroRange(lowMax: 3, optimalMin: 10, optimalMax: 22, highMin: 30),
      ph: _wheatPhEarly,
      ec: _wheatEcEarly,
      resistance: _wheatResistanceEarly,
      nIndex: AgroRange(lowMax: 22, optimalMin: 30, optimalMax: 50, highMin: 60),
      pIndex: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 78, highMin: 88),
      kIndex: AgroRange(lowMax: 28, optimalMin: 38, optimalMax: 58, highMin: 68),
    ),
    WheatStageKey.emergence: StageTargets(
      moistureRaw: AgroRange(lowMax: 14, optimalMin: 30, optimalMax: 70, highMin: 85),
      soilTemp: AgroRange(lowMax: 3, optimalMin: 10, optimalMax: 22, highMin: 30),
      ph: _wheatPhEarly,
      ec: _wheatEcEarly,
      resistance: _wheatResistanceEarly,
      nIndex: AgroRange(lowMax: 25, optimalMin: 34, optimalMax: 54, highMin: 64),
      pIndex: AgroRange(lowMax: 48, optimalMin: 58, optimalMax: 80, highMin: 90),
      kIndex: AgroRange(lowMax: 32, optimalMin: 42, optimalMax: 62, highMin: 72),
    ),

    // =========================
    // VEGETATIVE
    // =========================
    WheatStageKey.vegEarly: StageTargets(
      moistureRaw: AgroRange(lowMax: 12, optimalMin: 28, optimalMax: 66, highMin: 82),
      soilTemp: AgroRange(lowMax: 5, optimalMin: 12, optimalMax: 24, highMin: 30),
      ph: _wheatPhVeg,
      ec: _wheatEcVeg,
      resistance: _wheatResistanceEarly,
      nIndex: AgroRange(lowMax: 30, optimalMin: 40, optimalMax: 62, highMin: 72),
      pIndex: AgroRange(lowMax: 50, optimalMin: 60, optimalMax: 82, highMin: 90),
      kIndex: AgroRange(lowMax: 38, optimalMin: 48, optimalMax: 68, highMin: 78),
    ),
    WheatStageKey.tillering: StageTargets(
      moistureRaw: AgroRange(lowMax: 14, optimalMin: 30, optimalMax: 68, highMin: 82),
      soilTemp: AgroRange(lowMax: 5, optimalMin: 12, optimalMax: 24, highMin: 30),
      ph: _wheatPhVeg,
      ec: _wheatEcVeg,
      resistance: _wheatResistanceEarly,
      nIndex: AgroRange(lowMax: 40, optimalMin: 50, optimalMax: 74, highMin: 84),
      pIndex: AgroRange(lowMax: 48, optimalMin: 58, optimalMax: 78, highMin: 88),
      kIndex: AgroRange(lowMax: 42, optimalMin: 52, optimalMax: 72, highMin: 82),
    ),
    WheatStageKey.elongation: StageTargets(
      moistureRaw: AgroRange(lowMax: 16, optimalMin: 34, optimalMax: 70, highMin: 82),
      soilTemp: AgroRange(lowMax: 6, optimalMin: 14, optimalMax: 24, highMin: 30),
      ph: _wheatPhVeg,
      ec: _wheatEcVeg,
      resistance: _wheatResistanceEarly,
      nIndex: AgroRange(lowMax: 50, optimalMin: 60, optimalMax: 84, highMin: 94),
      pIndex: AgroRange(lowMax: 40, optimalMin: 50, optimalMax: 70, highMin: 80),
      kIndex: AgroRange(lowMax: 50, optimalMin: 60, optimalMax: 80, highMin: 90),
    ),
    WheatStageKey.booting: StageTargets(
      moistureRaw: AgroRange(lowMax: 18, optimalMin: 38, optimalMax: 74, highMin: 86),
      soilTemp: AgroRange(lowMax: 6, optimalMin: 14, optimalMax: 24, highMin: 28),
      ph: _wheatPhFlowering,
      ec: _wheatEcFlowering,
      resistance: _wheatResistanceEarly,
      nIndex: AgroRange(lowMax: 44, optimalMin: 54, optimalMax: 78, highMin: 88),
      pIndex: AgroRange(lowMax: 38, optimalMin: 48, optimalMax: 68, highMin: 78),
      kIndex: AgroRange(lowMax: 54, optimalMin: 64, optimalMax: 84, highMin: 92),
    ),

    // =========================
    // REPRODUCTIVE
    // =========================
    WheatStageKey.heading: StageTargets(
      moistureRaw: AgroRange(lowMax: 20, optimalMin: 40, optimalMax: 76, highMin: 86),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 24, highMin: 28),
      ph: _wheatPhFlowering,
      ec: _wheatEcFlowering,
      resistance: _wheatResistanceLate,
      nIndex: AgroRange(lowMax: 38, optimalMin: 48, optimalMax: 72, highMin: 82),
      pIndex: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 65, highMin: 75),
      kIndex: AgroRange(lowMax: 56, optimalMin: 66, optimalMax: 86, highMin: 94),
    ),
    WheatStageKey.flowering: StageTargets(
      moistureRaw: AgroRange(lowMax: 22, optimalMin: 42, optimalMax: 78, highMin: 88),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 15, optimalMax: 24, highMin: 28),
      ph: _wheatPhFlowering,
      ec: _wheatEcFlowering,
      resistance: _wheatResistanceLate,
      nIndex: AgroRange(lowMax: 32, optimalMin: 40, optimalMax: 65, highMin: 75),
      pIndex: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 65, highMin: 75),
      kIndex: AgroRange(lowMax: 58, optimalMin: 68, optimalMax: 88, highMin: 95),
    ),

    // =========================
    // LATE SEASON
    // =========================
    WheatStageKey.grainFill: StageTargets(
      moistureRaw: AgroRange(lowMax: 18, optimalMin: 38, optimalMax: 72, highMin: 82),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 15, optimalMax: 26, highMin: 30),
      ph: _wheatPhVeg,
      ec: _wheatEcVeg,
      resistance: _wheatResistanceLate,
      nIndex: AgroRange(lowMax: 26, optimalMin: 34, optimalMax: 58, highMin: 68),
      pIndex: AgroRange(lowMax: 32, optimalMin: 42, optimalMax: 62, highMin: 72),
      kIndex: AgroRange(lowMax: 62, optimalMin: 70, optimalMax: 90, highMin: 96),
    ),
    WheatStageKey.physiologicalMaturity: StageTargets(
      moistureRaw: AgroRange(lowMax: 10, optimalMin: 22, optimalMax: 48, highMin: 65),
      soilTemp: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 24, highMin: 30),
      ph: _wheatPhLate,
      ec: _wheatEcLate,
      resistance: _wheatResistanceLate,
      nIndex: AgroRange(lowMax: 16, optimalMin: 24, optimalMax: 42, highMin: 52),
      pIndex: AgroRange(lowMax: 28, optimalMin: 38, optimalMax: 58, highMin: 68),
      kIndex: AgroRange(lowMax: 42, optimalMin: 50, optimalMax: 70, highMin: 80),
    ),
    WheatStageKey.harvest: StageTargets(
      moistureRaw: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 38, highMin: 55),
      soilTemp: AgroRange(lowMax: 4, optimalMin: 10, optimalMax: 24, highMin: 30),
      ph: _wheatPhLate,
      ec: _wheatEcLate,
      resistance: _wheatResistanceLate,
      nIndex: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 35, highMin: 45),
      pIndex: AgroRange(lowMax: 24, optimalMin: 34, optimalMax: 54, highMin: 64),
      kIndex: AgroRange(lowMax: 36, optimalMin: 44, optimalMax: 64, highMin: 74),
    ),
  },
  weights: {
    // soilTemp: trigo C3 — temp suelo importa en germinación (vernalización)
    WheatStageKey.germination: StageWeights(
      moisture: 0.26,
      soilTemp: 0.08,
      resistance: 0.22,
      ph: 0.12,
      ec: 0.10,
      npk: 0.22,
    ),
    WheatStageKey.emergence: StageWeights(
      moisture: 0.26,
      soilTemp: 0.08,
      resistance: 0.22,
      ph: 0.12,
      ec: 0.10,
      npk: 0.22,
    ),
    WheatStageKey.vegEarly: StageWeights(
      moisture: 0.24,
      soilTemp: 0.06,
      resistance: 0.18,
      ph: 0.12,
      ec: 0.10,
      npk: 0.30,
    ),
    WheatStageKey.tillering: StageWeights(
      moisture: 0.24,
      soilTemp: 0.06,
      resistance: 0.18,
      ph: 0.10,
      ec: 0.10,
      npk: 0.32,
    ),
    WheatStageKey.elongation: StageWeights(
      moisture: 0.28,
      soilTemp: 0.06,
      resistance: 0.12,
      ph: 0.10,
      ec: 0.10,
      npk: 0.34,
    ),
    WheatStageKey.booting: StageWeights(
      moisture: 0.32,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.36,
    ),
    WheatStageKey.heading: StageWeights(
      moisture: 0.34,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.34,
    ),
    WheatStageKey.flowering: StageWeights(
      moisture: 0.36,
      soilTemp: 0.06,
      resistance: 0.06,
      ph: 0.08,
      ec: 0.10,
      npk: 0.34,
    ),
    WheatStageKey.grainFill: StageWeights(
      moisture: 0.34,
      soilTemp: 0.04,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.36,
    ),
    WheatStageKey.physiologicalMaturity: StageWeights(
      moisture: 0.26,
      soilTemp: 0.04,
      resistance: 0.16,
      ph: 0.12,
      ec: 0.12,
      npk: 0.30,
    ),
    WheatStageKey.harvest: StageWeights(
      moisture: 0.24,
      soilTemp: 0.04,
      resistance: 0.16,
      ph: 0.14,
      ec: 0.12,
      npk: 0.30,
    ),
  },
);
