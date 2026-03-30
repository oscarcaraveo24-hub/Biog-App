import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/bean_engine.dart';
import 'package:bio_g/widgets/seeds/bean_models.dart';

class BeanCropEngineAdapter implements CropEngine {
  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final beanProfile = profile as BeanProfile;

    final result = BeanEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: beanProfile,
      stressDelayDays: stressDelayDays,
    );

    return CropStageResult(
      stageKey: result.stage.name,
      stageLabelEs: result.stageLabelEs,
      expectedDaysToEnd: result.expectedDaysToEnd,
      windowsNow: result.windowsNow,
      heroAsset: result.heroAsset,
      helperCaption: result.helperCaption,
      daySinceSowing: result.daySinceSowing,
      stageProgressPct: result.stageProgressPct,
    );
  }
}
