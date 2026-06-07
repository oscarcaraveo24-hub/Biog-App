import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/garlic_engine.dart';
import 'package:bio_g/widgets/seeds/garlic_models.dart';

class GarlicCropEngineAdapter implements CropEngine {
  final GarlicEstablishmentMode? establishmentMode;

  const GarlicCropEngineAdapter({this.establishmentMode});

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final garlicProfile = profile as GarlicProfile;

    final result = GarlicEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: garlicProfile,
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
