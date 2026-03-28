import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/oat_models.dart';

/// Perfil universal de avena (C3, cereal de estación fría).
/// Contiene rangos agronómicos y pesos de importancia por etapa fenológica.

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
// ✅ FIX: raíces jóvenes más sensibles → Early (más estricto) se extiende
//    hasta booting. Late (más tolerante) desde heading en adelante.
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
    // ✅ FIX: soilTemp germinación — avena germina a 4°C pero óptimo es 10-20°C
    OatStageKey.germination: StageTargets(
      moistureRaw: AgroRange(lowMax: 15, optimalMin: 32, optimalMax: 70, highMin: 85),
      soilTemp: AgroRange(lowMax: 4, optimalMin: 10, optimalMax: 20, highMin: 28),
      ph: _oatPhEarly,
      ec: _oatEcEarly,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(lowMax: 20, optimalMin: 28, optimalMax: 48, highMin: 58),
      pIndex: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 78, highMin: 88),
      kIndex: AgroRange(lowMax: 28, optimalMin: 38, optimalMax: 58, highMin: 68),
    ),
    OatStageKey.emergence: StageTargets(
      moistureRaw: AgroRange(lowMax: 15, optimalMin: 32, optimalMax: 68, highMin: 84),
      soilTemp: AgroRange(lowMax: 4, optimalMin: 10, optimalMax: 20, highMin: 28),
      ph: _oatPhEarly,
      ec: _oatEcEarly,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(lowMax: 22, optimalMin: 30, optimalMax: 50, highMin: 60),
      pIndex: AgroRange(lowMax: 48, optimalMin: 58, optimalMax: 80, highMin: 90),
      kIndex: AgroRange(lowMax: 32, optimalMin: 42, optimalMax: 62, highMin: 72),
    ),

    // =========================
    // VEGETATIVE
    // =========================
    OatStageKey.vegEarly: StageTargets(
      moistureRaw: AgroRange(lowMax: 14, optimalMin: 30, optimalMax: 65, highMin: 82),
      soilTemp: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 26, highMin: 32),
      ph: _oatPhVeg,
      ec: _oatEcVeg,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(lowMax: 28, optimalMin: 36, optimalMax: 58, highMin: 68),
      pIndex: AgroRange(lowMax: 50, optimalMin: 60, optimalMax: 82, highMin: 90),
      kIndex: AgroRange(lowMax: 38, optimalMin: 46, optimalMax: 66, highMin: 76),
    ),
    OatStageKey.tillering: StageTargets(
      moistureRaw: AgroRange(lowMax: 16, optimalMin: 32, optimalMax: 66, highMin: 82),
      soilTemp: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 26, highMin: 32),
      ph: _oatPhVeg,
      ec: _oatEcVeg,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 68, highMin: 78),
      pIndex: AgroRange(lowMax: 48, optimalMin: 58, optimalMax: 78, highMin: 88),
      kIndex: AgroRange(lowMax: 42, optimalMin: 52, optimalMax: 72, highMin: 82),
    ),
    // ✅ FIX: elongation y booting ahora usan resistanceEarly (raíces aún en expansión)
    OatStageKey.elongation: StageTargets(
      moistureRaw: AgroRange(lowMax: 18, optimalMin: 35, optimalMax: 68, highMin: 82),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 32),
      ph: _oatPhVeg,
      ec: _oatEcVeg,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 78, highMin: 88),
      pIndex: AgroRange(lowMax: 42, optimalMin: 52, optimalMax: 72, highMin: 82),
      kIndex: AgroRange(lowMax: 48, optimalMin: 58, optimalMax: 78, highMin: 88),
    ),
    OatStageKey.booting: StageTargets(
      moistureRaw: AgroRange(lowMax: 20, optimalMin: 38, optimalMax: 72, highMin: 84),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 30),
      ph: _oatPhFlowering,
      ec: _oatEcFlowering,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(lowMax: 40, optimalMin: 50, optimalMax: 72, highMin: 82),
      pIndex: AgroRange(lowMax: 38, optimalMin: 48, optimalMax: 68, highMin: 78),
      kIndex: AgroRange(lowMax: 52, optimalMin: 62, optimalMax: 82, highMin: 90),
    ),

    // =========================
    // REPRODUCTIVE
    // =========================
    OatStageKey.heading: StageTargets(
      moistureRaw: AgroRange(lowMax: 22, optimalMin: 40, optimalMax: 74, highMin: 86),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 30),
      ph: _oatPhFlowering,
      ec: _oatEcFlowering,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 68, highMin: 78),
      pIndex: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 65, highMin: 75),
      kIndex: AgroRange(lowMax: 55, optimalMin: 65, optimalMax: 85, highMin: 92),
    ),
    OatStageKey.flowering: StageTargets(
      moistureRaw: AgroRange(lowMax: 22, optimalMin: 42, optimalMax: 76, highMin: 86),
      soilTemp: AgroRange(lowMax: 10, optimalMin: 15, optimalMax: 26, highMin: 30),
      ph: _oatPhFlowering,
      ec: _oatEcFlowering,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 30, optimalMin: 38, optimalMax: 62, highMin: 72),
      pIndex: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 65, highMin: 75),
      kIndex: AgroRange(lowMax: 58, optimalMin: 68, optimalMax: 88, highMin: 95),
    ),

    // =========================
    // LATE SEASON
    // =========================
    OatStageKey.grainFill: StageTargets(
      moistureRaw: AgroRange(lowMax: 18, optimalMin: 38, optimalMax: 72, highMin: 82),
      soilTemp: AgroRange(lowMax: 10, optimalMin: 15, optimalMax: 26, highMin: 30),
      ph: _oatPhVeg,
      ec: _oatEcVeg,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 25, optimalMin: 32, optimalMax: 55, highMin: 65),
      pIndex: AgroRange(lowMax: 32, optimalMin: 42, optimalMax: 62, highMin: 72),
      kIndex: AgroRange(lowMax: 60, optimalMin: 68, optimalMax: 88, highMin: 95),
    ),
    OatStageKey.physiologicalMaturity: StageTargets(
      moistureRaw: AgroRange(lowMax: 10, optimalMin: 22, optimalMax: 50, highMin: 65),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 30),
      ph: _oatPhLate,
      ec: _oatEcLate,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 15, optimalMin: 22, optimalMax: 40, highMin: 50),
      pIndex: AgroRange(lowMax: 28, optimalMin: 38, optimalMax: 58, highMin: 68),
      kIndex: AgroRange(lowMax: 40, optimalMin: 48, optimalMax: 68, highMin: 78),
    ),
    OatStageKey.harvest: StageTargets(
      moistureRaw: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 40, highMin: 55),
      soilTemp: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 26, highMin: 32),
      ph: _oatPhLate,
      ec: _oatEcLate,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 35, highMin: 45),
      pIndex: AgroRange(lowMax: 25, optimalMin: 35, optimalMax: 55, highMin: 65),
      kIndex: AgroRange(lowMax: 35, optimalMin: 42, optimalMax: 62, highMin: 72),
    ),
  },
  weights: {
    // soilTemp: avena C3 estación fría — temp suelo importa en germinación
    OatStageKey.germination: StageWeights(
      moisture: 0.28,
      soilTemp: 0.08,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      npk: 0.22,
    ),
    OatStageKey.emergence: StageWeights(
      moisture: 0.28,
      soilTemp: 0.08,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      npk: 0.22,
    ),
    OatStageKey.vegEarly: StageWeights(
      moisture: 0.24,
      soilTemp: 0.06,
      resistance: 0.18,
      ph: 0.12,
      ec: 0.10,
      npk: 0.30,
    ),
    OatStageKey.tillering: StageWeights(
      moisture: 0.24,
      soilTemp: 0.06,
      resistance: 0.18,
      ph: 0.10,
      ec: 0.10,
      npk: 0.32,
    ),
    OatStageKey.elongation: StageWeights(
      moisture: 0.28,
      soilTemp: 0.06,
      resistance: 0.12,
      ph: 0.10,
      ec: 0.10,
      npk: 0.34,
    ),
    OatStageKey.booting: StageWeights(
      moisture: 0.28,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.40,
    ),
    OatStageKey.heading: StageWeights(
      moisture: 0.34,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.34,
    ),
    OatStageKey.flowering: StageWeights(
      moisture: 0.36,
      soilTemp: 0.06,
      resistance: 0.06,
      ph: 0.08,
      ec: 0.10,
      npk: 0.34,
    ),
    OatStageKey.grainFill: StageWeights(
      moisture: 0.34,
      soilTemp: 0.04,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.36,
    ),
    OatStageKey.physiologicalMaturity: StageWeights(
      moisture: 0.26,
      soilTemp: 0.04,
      resistance: 0.16,
      ph: 0.12,
      ec: 0.12,
      npk: 0.30,
    ),
    OatStageKey.harvest: StageWeights(
      moisture: 0.24,
      soilTemp: 0.04,
      resistance: 0.16,
      ph: 0.14,
      ec: 0.12,
      npk: 0.30,
    ),
  },
);
