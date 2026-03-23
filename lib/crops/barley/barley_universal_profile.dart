import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/barley_models.dart';

class BarleyUniversalProfile {
  const BarleyUniversalProfile({required this.byStage, required this.weights});

  final Map<BarleyStageKey, StageTargets> byStage;
  final Map<BarleyStageKey, StageWeights> weights;
}

const AgroRange _barleyPh = AgroRange(
  lowMax: 5.5,
  optimalMin: 6.0,
  optimalMax: 8.0,
  highMin: 8.5,
);

const AgroRange _barleyEc = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.6,
  optimalMax: 4.0,
  highMin: 8.0,
);

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
    BarleyStageKey.germination: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 14,
        optimalMin: 30,
        optimalMax: 72,
        highMin: 86,
      ),
      soilTemp: AgroRange(
        lowMax: 4,
        optimalMin: 12,
        optimalMax: 25,
        highMin: 34,
      ),
      ph: _barleyPh,
      ec: _barleyEc,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(
        lowMax: 22,
        optimalMin: 30,
        optimalMax: 50,
        highMin: 60,
      ),
      pIndex: AgroRange(
        lowMax: 45,
        optimalMin: 55,
        optimalMax: 78,
        highMin: 88,
      ),
      kIndex: AgroRange(
        lowMax: 28,
        optimalMin: 38,
        optimalMax: 58,
        highMin: 68,
      ),
    ),
    BarleyStageKey.emergence: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 14,
        optimalMin: 30,
        optimalMax: 70,
        highMin: 85,
      ),
      soilTemp: AgroRange(
        lowMax: 4,
        optimalMin: 12,
        optimalMax: 25,
        highMin: 34,
      ),
      ph: _barleyPh,
      ec: _barleyEc,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(
        lowMax: 25,
        optimalMin: 34,
        optimalMax: 54,
        highMin: 64,
      ),
      pIndex: AgroRange(
        lowMax: 48,
        optimalMin: 58,
        optimalMax: 80,
        highMin: 90,
      ),
      kIndex: AgroRange(
        lowMax: 32,
        optimalMin: 42,
        optimalMax: 62,
        highMin: 72,
      ),
    ),
    BarleyStageKey.vegEarly: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 12,
        optimalMin: 28,
        optimalMax: 66,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 6,
        optimalMin: 14,
        optimalMax: 26,
        highMin: 34,
      ),
      ph: _barleyPh,
      ec: _barleyEc,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(
        lowMax: 30,
        optimalMin: 40,
        optimalMax: 62,
        highMin: 72,
      ),
      pIndex: AgroRange(
        lowMax: 50,
        optimalMin: 60,
        optimalMax: 82,
        highMin: 90,
      ),
      kIndex: AgroRange(
        lowMax: 38,
        optimalMin: 48,
        optimalMax: 68,
        highMin: 78,
      ),
    ),
    BarleyStageKey.tillering: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 14,
        optimalMin: 30,
        optimalMax: 68,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 6,
        optimalMin: 14,
        optimalMax: 26,
        highMin: 34,
      ),
      ph: _barleyPh,
      ec: _barleyEc,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(
        lowMax: 38,
        optimalMin: 48,
        optimalMax: 72,
        highMin: 82,
      ),
      pIndex: AgroRange(
        lowMax: 46,
        optimalMin: 56,
        optimalMax: 76,
        highMin: 86,
      ),
      kIndex: AgroRange(
        lowMax: 42,
        optimalMin: 52,
        optimalMax: 72,
        highMin: 82,
      ),
    ),
    BarleyStageKey.elongation: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 16,
        optimalMin: 34,
        optimalMax: 70,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 8,
        optimalMin: 14,
        optimalMax: 26,
        highMin: 32,
      ),
      ph: _barleyPh,
      ec: _barleyEc,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(
        lowMax: 48,
        optimalMin: 58,
        optimalMax: 82,
        highMin: 92,
      ),
      pIndex: AgroRange(
        lowMax: 40,
        optimalMin: 50,
        optimalMax: 70,
        highMin: 80,
      ),
      kIndex: AgroRange(
        lowMax: 50,
        optimalMin: 60,
        optimalMax: 80,
        highMin: 90,
      ),
    ),
    BarleyStageKey.booting: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 18,
        optimalMin: 38,
        optimalMax: 74,
        highMin: 86,
      ),
      soilTemp: AgroRange(
        lowMax: 8,
        optimalMin: 14,
        optimalMax: 26,
        highMin: 31,
      ),
      ph: _barleyPh,
      ec: _barleyEc,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(
        lowMax: 42,
        optimalMin: 52,
        optimalMax: 75,
        highMin: 85,
      ),
      pIndex: AgroRange(
        lowMax: 38,
        optimalMin: 48,
        optimalMax: 68,
        highMin: 78,
      ),
      kIndex: AgroRange(
        lowMax: 54,
        optimalMin: 64,
        optimalMax: 84,
        highMin: 92,
      ),
    ),
    BarleyStageKey.heading: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 20,
        optimalMin: 40,
        optimalMax: 76,
        highMin: 86,
      ),
      soilTemp: AgroRange(
        lowMax: 8,
        optimalMin: 14,
        optimalMax: 26,
        highMin: 31,
      ),
      ph: _barleyPh,
      ec: _barleyEc,
      resistance: _barleyResistanceEarly,
      nIndex: AgroRange(
        lowMax: 38,
        optimalMin: 48,
        optimalMax: 70,
        highMin: 80,
      ),
      pIndex: AgroRange(
        lowMax: 35,
        optimalMin: 45,
        optimalMax: 65,
        highMin: 75,
      ),
      kIndex: AgroRange(
        lowMax: 56,
        optimalMin: 66,
        optimalMax: 86,
        highMin: 94,
      ),
    ),
    BarleyStageKey.flowering: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 22,
        optimalMin: 42,
        optimalMax: 78,
        highMin: 88,
      ),
      soilTemp: AgroRange(
        lowMax: 10,
        optimalMin: 15,
        optimalMax: 26,
        highMin: 31,
      ),
      ph: _barleyPh,
      ec: _barleyEc,
      resistance: _barleyResistanceLate,
      nIndex: AgroRange(
        lowMax: 32,
        optimalMin: 40,
        optimalMax: 65,
        highMin: 75,
      ),
      pIndex: AgroRange(
        lowMax: 35,
        optimalMin: 45,
        optimalMax: 65,
        highMin: 75,
      ),
      kIndex: AgroRange(
        lowMax: 58,
        optimalMin: 68,
        optimalMax: 88,
        highMin: 95,
      ),
    ),
    BarleyStageKey.grainFill: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 18,
        optimalMin: 38,
        optimalMax: 72,
        highMin: 82,
      ),
      soilTemp: AgroRange(
        lowMax: 10,
        optimalMin: 15,
        optimalMax: 28,
        highMin: 35,
      ),
      ph: _barleyPh,
      ec: _barleyEc,
      resistance: _barleyResistanceLate,
      nIndex: AgroRange(
        lowMax: 26,
        optimalMin: 34,
        optimalMax: 58,
        highMin: 68,
      ),
      pIndex: AgroRange(
        lowMax: 32,
        optimalMin: 42,
        optimalMax: 62,
        highMin: 72,
      ),
      kIndex: AgroRange(
        lowMax: 62,
        optimalMin: 70,
        optimalMax: 90,
        highMin: 96,
      ),
    ),
    BarleyStageKey.physiologicalMaturity: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 10,
        optimalMin: 22,
        optimalMax: 48,
        highMin: 65,
      ),
      soilTemp: AgroRange(
        lowMax: 8,
        optimalMin: 14,
        optimalMax: 26,
        highMin: 32,
      ),
      ph: _barleyPh,
      ec: _barleyEc,
      resistance: _barleyResistanceLate,
      nIndex: AgroRange(
        lowMax: 16,
        optimalMin: 24,
        optimalMax: 42,
        highMin: 52,
      ),
      pIndex: AgroRange(
        lowMax: 28,
        optimalMin: 38,
        optimalMax: 58,
        highMin: 68,
      ),
      kIndex: AgroRange(
        lowMax: 42,
        optimalMin: 50,
        optimalMax: 70,
        highMin: 80,
      ),
    ),
    BarleyStageKey.harvest: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 8,
        optimalMin: 18,
        optimalMax: 38,
        highMin: 55,
      ),
      soilTemp: AgroRange(
        lowMax: 6,
        optimalMin: 12,
        optimalMax: 26,
        highMin: 34,
      ),
      ph: _barleyPh,
      ec: _barleyEc,
      resistance: _barleyResistanceLate,
      nIndex: AgroRange(
        lowMax: 12,
        optimalMin: 18,
        optimalMax: 35,
        highMin: 45,
      ),
      pIndex: AgroRange(
        lowMax: 24,
        optimalMin: 34,
        optimalMax: 54,
        highMin: 64,
      ),
      kIndex: AgroRange(
        lowMax: 36,
        optimalMin: 44,
        optimalMax: 64,
        highMin: 74,
      ),
    ),
  },
  weights: {
    BarleyStageKey.germination: StageWeights(
      moisture: 0.32,
      resistance: 0.22,
      ph: 0.12,
      ec: 0.10,
      npk: 0.24,
    ),
    BarleyStageKey.emergence: StageWeights(
      moisture: 0.32,
      resistance: 0.22,
      ph: 0.12,
      ec: 0.10,
      npk: 0.24,
    ),
    BarleyStageKey.vegEarly: StageWeights(
      moisture: 0.26,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      npk: 0.32,
    ),
    BarleyStageKey.tillering: StageWeights(
      moisture: 0.26,
      resistance: 0.20,
      ph: 0.10,
      ec: 0.10,
      npk: 0.34,
    ),
    BarleyStageKey.elongation: StageWeights(
      moisture: 0.30,
      resistance: 0.14,
      ph: 0.10,
      ec: 0.10,
      npk: 0.36,
    ),
    BarleyStageKey.booting: StageWeights(
      moisture: 0.34,
      resistance: 0.10,
      ph: 0.08,
      ec: 0.10,
      npk: 0.38,
    ),
    BarleyStageKey.heading: StageWeights(
      moisture: 0.36,
      resistance: 0.10,
      ph: 0.08,
      ec: 0.10,
      npk: 0.36,
    ),
    BarleyStageKey.flowering: StageWeights(
      moisture: 0.40,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.34,
    ),
    BarleyStageKey.grainFill: StageWeights(
      moisture: 0.36,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.10,
      npk: 0.38,
    ),
    BarleyStageKey.physiologicalMaturity: StageWeights(
      moisture: 0.28,
      resistance: 0.18,
      ph: 0.12,
      ec: 0.12,
      npk: 0.30,
    ),
    BarleyStageKey.harvest: StageWeights(
      moisture: 0.26,
      resistance: 0.18,
      ph: 0.14,
      ec: 0.12,
      npk: 0.30,
    ),
  },
);
