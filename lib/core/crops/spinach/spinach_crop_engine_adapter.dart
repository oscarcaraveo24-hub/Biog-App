import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/spinach_engine.dart';
import 'package:bio_g/widgets/seeds/spinach_models.dart';

class SpinachCropEngineAdapter implements CropEngine {
  final SpinachEstablishmentMode? establishmentMode;

  const SpinachCropEngineAdapter({this.establishmentMode});

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final spinachProfile = profile as SpinachProfile;

    final result = SpinachEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: spinachProfile,
      establishmentMode: establishmentMode,
      stressDelayDays: stressDelayDays,
    );

    return CropStageResult(
      stageKey: result.stage.name,
      stageLabelEs: result.stageLabelEs,
      expectedDaysToEnd: result.expectedDaysToEnd,
      windowsNow: result.windowsNow,
      heroAsset: result.heroAsset,
      helperCaption: result.helperCaption,
      daySinceSowing: result.daySinceAnchor,
      stageProgressPct: result.stageProgressPct,
    );
  }
}
