import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

enum BeanUseType { grain, snap }

enum BeanStageKey {
  germination,
  emergence,
  vegEarly,
  vegAdvanced,
  flowering,
  podSet,
  grainFill,
  physiologicalMaturity,
  harvest,
}

class BeanProfile extends CropProfile {
  final RangeInt floweringDays;
  final RangeInt endWindowDays;
  final String endActionLabel;

  final RangeDouble plantHeightM;
  final RangeDouble lowerPodHeightM;

  final RangeInt germinationDays;
  final RangeInt emergenceDays;
  final RangeInt vegEarlyDays;

  final BeanUseType beanUseType;

  const BeanProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.beanUseType = BeanUseType.grain,
    this.floweringDays = const RangeInt(0, 0),
    this.endWindowDays = const RangeInt(0, 0),
    this.endActionLabel = '',
    this.plantHeightM = const RangeDouble(0, 0),
    this.lowerPodHeightM = const RangeDouble(0, 0),
    this.germinationDays = const RangeInt(0, 0),
    this.emergenceDays = const RangeInt(0, 0),
    this.vegEarlyDays = const RangeInt(0, 0),
  }) : super(cropKey: CropKey.bean);
}

class BeanStageBounds {
  final BeanStageKey key;
  final int startDay;
  final int endDay;

  const BeanStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  }) : assert(startDay >= 1),
       assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

class BeanStageResult {
  final BeanProfile profile;
  final BeanStageKey stage;
  final int daySinceSowing;

  final RangeInt floweringBand;
  final RangeInt endBand;

  final int expectedFloweringDay;
  final int expectedEndDay;

  final int expectedDaysToEnd;
  final double stageProgressPct;
  final List<SeedWindowKey> windowsNow;

  final RangeDouble expectedPlantHeightTodayM;

  final String stageLabelEs;
  final String heroAsset;
  final String helperCaption;

  const BeanStageResult({
    required this.profile,
    required this.stage,
    required this.daySinceSowing,
    required this.floweringBand,
    required this.endBand,
    required this.expectedFloweringDay,
    required this.expectedEndDay,
    required this.expectedDaysToEnd,
    required this.stageProgressPct,
    required this.windowsNow,
    required this.expectedPlantHeightTodayM,
    required this.stageLabelEs,
    required this.heroAsset,
    required this.helperCaption,
  });
}
