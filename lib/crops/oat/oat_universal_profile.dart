import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/oat_models.dart';

/// Perfil universal de avena (C3, cereal de estación fría).
/// Contiene rangos agronómicos y pesos de importancia por etapa fenológica.
/// Basado en datos de PDF Bio-G: tolerancias de estrés, optimas de suelo/nutrición,
/// y sensibilidades diferenciales según fase de crecimiento.

// Shared ranges for all stages
const AgroRange _oatPh = AgroRange(lowMax: 5.0, optimalMin: 5.5, optimalMax: 7.5, highMin: 8.0);
const AgroRange _oatEc = AgroRange(lowMax: 0.5, optimalMin: 0.6, optimalMax: 2.5, highMin: 4.0);
const AgroRange _oatResistanceEarly = AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.2, highMin: 2.0);
const AgroRange _oatResistanceLate = AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.6, highMin: 2.0);

class OatUniversalProfile {
  const OatUniversalProfile({required this.byStage, required this.weights});
  final Map<OatStageKey, StageTargets> byStage;
  final Map<OatStageKey, StageWeights> weights;
}

const oatUniversalV1 = OatUniversalProfile(
  byStage: {
    OatStageKey.germination: StageTargets(
      moistureRaw: AgroRange(lowMax: 15, optimalMin: 32, optimalMax: 70, highMin: 85),
      soilTemp: AgroRange(lowMax: 5, optimalMin: 10, optimalMax: 25, highMin: 32),
      ph: _oatPh,
      ec: _oatEc,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(lowMax: 20, optimalMin: 28, optimalMax: 48, highMin: 58),
      pIndex: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 78, highMin: 88),
      kIndex: AgroRange(lowMax: 28, optimalMin: 38, optimalMax: 58, highMin: 68),
    ),
    OatStageKey.emergence: StageTargets(
      moistureRaw: AgroRange(lowMax: 15, optimalMin: 32, optimalMax: 68, highMin: 84),
      soilTemp: AgroRange(lowMax: 5, optimalMin: 10, optimalMax: 25, highMin: 32),
      ph: _oatPh,
      ec: _oatEc,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(lowMax: 22, optimalMin: 30, optimalMax: 50, highMin: 60),
      pIndex: AgroRange(lowMax: 48, optimalMin: 58, optimalMax: 80, highMin: 90),
      kIndex: AgroRange(lowMax: 32, optimalMin: 42, optimalMax: 62, highMin: 72),
    ),
    OatStageKey.vegEarly: StageTargets(
      moistureRaw: AgroRange(lowMax: 14, optimalMin: 30, optimalMax: 65, highMin: 82),
      soilTemp: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 26, highMin: 32),
      ph: _oatPh,
      ec: _oatEc,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(lowMax: 28, optimalMin: 36, optimalMax: 58, highMin: 68),
      pIndex: AgroRange(lowMax: 50, optimalMin: 60, optimalMax: 82, highMin: 90),
      kIndex: AgroRange(lowMax: 38, optimalMin: 46, optimalMax: 66, highMin: 76),
    ),
    OatStageKey.tillering: StageTargets(
      moistureRaw: AgroRange(lowMax: 16, optimalMin: 32, optimalMax: 66, highMin: 82),
      soilTemp: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 26, highMin: 32),
      ph: _oatPh,
      ec: _oatEc,
      resistance: _oatResistanceEarly,
      nIndex: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 68, highMin: 78),
      pIndex: AgroRange(lowMax: 48, optimalMin: 58, optimalMax: 78, highMin: 88),
      kIndex: AgroRange(lowMax: 42, optimalMin: 52, optimalMax: 72, highMin: 82),
    ),
    OatStageKey.elongation: StageTargets(
      moistureRaw: AgroRange(lowMax: 18, optimalMin: 35, optimalMax: 68, highMin: 82),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 32),
      ph: _oatPh,
      ec: _oatEc,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 45, optimalMin: 55, optimalMax: 78, highMin: 88),
      pIndex: AgroRange(lowMax: 42, optimalMin: 52, optimalMax: 72, highMin: 82),
      kIndex: AgroRange(lowMax: 48, optimalMin: 58, optimalMax: 78, highMin: 88),
    ),
    OatStageKey.booting: StageTargets(
      moistureRaw: AgroRange(lowMax: 20, optimalMin: 38, optimalMax: 72, highMin: 84),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 30),
      ph: _oatPh,
      ec: _oatEc,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 40, optimalMin: 50, optimalMax: 72, highMin: 82),
      pIndex: AgroRange(lowMax: 38, optimalMin: 48, optimalMax: 68, highMin: 78),
      kIndex: AgroRange(lowMax: 52, optimalMin: 62, optimalMax: 82, highMin: 90),
    ),
    OatStageKey.heading: StageTargets(
      moistureRaw: AgroRange(lowMax: 22, optimalMin: 40, optimalMax: 74, highMin: 86),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 30),
      ph: _oatPh,
      ec: _oatEc,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 68, highMin: 78),
      pIndex: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 65, highMin: 75),
      kIndex: AgroRange(lowMax: 55, optimalMin: 65, optimalMax: 85, highMin: 92),
    ),
    OatStageKey.flowering: StageTargets(
      moistureRaw: AgroRange(lowMax: 22, optimalMin: 42, optimalMax: 76, highMin: 86),
      soilTemp: AgroRange(lowMax: 10, optimalMin: 15, optimalMax: 26, highMin: 30),
      ph: _oatPh,
      ec: _oatEc,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 30, optimalMin: 38, optimalMax: 62, highMin: 72),
      pIndex: AgroRange(lowMax: 35, optimalMin: 45, optimalMax: 65, highMin: 75),
      kIndex: AgroRange(lowMax: 58, optimalMin: 68, optimalMax: 88, highMin: 95),
    ),
    OatStageKey.grainFill: StageTargets(
      moistureRaw: AgroRange(lowMax: 18, optimalMin: 38, optimalMax: 72, highMin: 82),
      soilTemp: AgroRange(lowMax: 10, optimalMin: 15, optimalMax: 26, highMin: 30),
      ph: _oatPh,
      ec: _oatEc,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 25, optimalMin: 32, optimalMax: 55, highMin: 65),
      pIndex: AgroRange(lowMax: 32, optimalMin: 42, optimalMax: 62, highMin: 72),
      kIndex: AgroRange(lowMax: 60, optimalMin: 68, optimalMax: 88, highMin: 95),
    ),
    OatStageKey.physiologicalMaturity: StageTargets(
      moistureRaw: AgroRange(lowMax: 10, optimalMin: 22, optimalMax: 50, highMin: 65),
      soilTemp: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 26, highMin: 30),
      ph: _oatPh,
      ec: _oatEc,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 15, optimalMin: 22, optimalMax: 40, highMin: 50),
      pIndex: AgroRange(lowMax: 28, optimalMin: 38, optimalMax: 58, highMin: 68),
      kIndex: AgroRange(lowMax: 40, optimalMin: 48, optimalMax: 68, highMin: 78),
    ),
    OatStageKey.harvest: StageTargets(
      moistureRaw: AgroRange(lowMax: 8, optimalMin: 18, optimalMax: 40, highMin: 55),
      soilTemp: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 26, highMin: 32),
      ph: _oatPh,
      ec: _oatEc,
      resistance: _oatResistanceLate,
      nIndex: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 35, highMin: 45),
      pIndex: AgroRange(lowMax: 25, optimalMin: 35, optimalMax: 55, highMin: 65),
      kIndex: AgroRange(lowMax: 35, optimalMin: 42, optimalMax: 62, highMin: 72),
    ),
  },
  weights: {
    OatStageKey.germination: StageWeights(
      moisture: 0.32,
      resistance: 0.22,
      ph: 0.12,
      ec: 0.10,
      npk: 0.24,
    ),
    OatStageKey.emergence: StageWeights(
      moisture: 0.32,
      resistance: 0.22,
      ph: 0.12,
      ec: 0.10,
      npk: 0.24,
    ),
    OatStageKey.vegEarly: StageWeights(
      moisture: 0.26,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      npk: 0.32,
    ),
    OatStageKey.tillering: StageWeights(
      moisture: 0.26,
      resistance: 0.20,
      ph: 0.10,
      ec: 0.10,
      npk: 0.34,
    ),
    OatStageKey.elongation: StageWeights(
      moisture: 0.30,
      resistance: 0.14,
      ph: 0.10,
      ec: 0.10,
      npk: 0.36,
    ),
    OatStageKey.booting: StageWeights(
      moisture: 0.32,
      resistance: 0.10,
      ph: 0.08,
      ec: 0.10,
      npk: 0.40,
    ),
    OatStageKey.heading: StageWeights(
      moisture: 0.36,
      resistance: 0.10,
      ph: 0.08,
      ec: 0.10,
      npk: 0.36,
    ),
    OatStageKey.flowering: StageWeights(
      moisture: 0.40,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.34,
    ),
    OatStageKey.grainFill: StageWeights(
      moisture: 0.36,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.38,
    ),
    OatStageKey.physiologicalMaturity: StageWeights(
      moisture: 0.28,
      resistance: 0.18,
      ph: 0.12,
      ec: 0.12,
      npk: 0.30,
    ),
    OatStageKey.harvest: StageWeights(
      moisture: 0.26,
      resistance: 0.18,
      ph: 0.14,
      ec: 0.12,
      npk: 0.30,
    ),
  },
);
