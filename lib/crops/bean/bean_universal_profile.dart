import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/bean_models.dart';

class BeanUniversalProfile {
  const BeanUniversalProfile({required this.byStage, required this.weights});

  final Map<BeanStageKey, StageTargets> byStage;
  final Map<BeanStageKey, StageWeights> weights;
}

const AgroRange _beanPh = AgroRange(
  lowMax: 5.5,
  optimalMin: 6.0,
  optimalMax: 7.5,
  highMin: 8.0,
);

const AgroRange _beanEc = AgroRange(
  lowMax: 0.6,
  optimalMin: 0.6,
  optimalMax: 1.0,
  highMin: 1.5,
);

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
      ph: _beanPh,
      ec: _beanEc,
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
      ph: _beanPh,
      ec: _beanEc,
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
    ),
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
      ph: _beanPh,
      ec: _beanEc,
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
      ph: _beanPh,
      ec: _beanEc,
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
    ),
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
      ph: _beanPh,
      ec: _beanEc,
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
    ),
    BeanStageKey.podSet: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 22,
        optimalMin: 42,
        optimalMax: 72,
        highMin: 80,
      ),
      soilTemp: AgroRange(
        lowMax: 15,
        optimalMin: 18,
        optimalMax: 28,
        highMin: 30,
      ),
      ph: _beanPh,
      ec: _beanEc,
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
    ),
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
      ph: _beanPh,
      ec: _beanEc,
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
      ph: _beanPh,
      ec: _beanEc,
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
      ph: _beanPh,
      ec: _beanEc,
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
    ),
  },
  weights: {
    BeanStageKey.germination: StageWeights(
      moisture: 0.34,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      npk: 0.24,
    ),
    BeanStageKey.emergence: StageWeights(
      moisture: 0.34,
      resistance: 0.20,
      ph: 0.12,
      ec: 0.10,
      npk: 0.24,
    ),
    BeanStageKey.vegEarly: StageWeights(
      moisture: 0.28,
      resistance: 0.18,
      ph: 0.12,
      ec: 0.10,
      npk: 0.32,
    ),
    BeanStageKey.vegAdvanced: StageWeights(
      moisture: 0.30,
      resistance: 0.14,
      ph: 0.10,
      ec: 0.10,
      npk: 0.36,
    ),
    BeanStageKey.flowering: StageWeights(
      moisture: 0.42,
      resistance: 0.10,
      ph: 0.08,
      ec: 0.10,
      npk: 0.30,
    ),
    BeanStageKey.podSet: StageWeights(
      moisture: 0.42,
      resistance: 0.10,
      ph: 0.08,
      ec: 0.10,
      npk: 0.30,
    ),
    BeanStageKey.grainFill: StageWeights(
      moisture: 0.38,
      resistance: 0.10,
      ph: 0.08,
      ec: 0.10,
      npk: 0.34,
    ),
    BeanStageKey.physiologicalMaturity: StageWeights(
      moisture: 0.20,
      resistance: 0.12,
      ph: 0.10,
      ec: 0.12,
      npk: 0.18,
    ),
    BeanStageKey.harvest: StageWeights(
      moisture: 0.18,
      resistance: 0.12,
      ph: 0.10,
      ec: 0.12,
      npk: 0.18,
    ),
  },
);
