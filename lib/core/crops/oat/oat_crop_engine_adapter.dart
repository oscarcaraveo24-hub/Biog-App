// lib/core/crops/oat/oat_crop_engine_adapter.dart
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/oat_engine.dart';
import 'package:bio_g/widgets/seeds/oat_models.dart';

class OatCropEngineAdapter implements CropEngine {
  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final oatProfile = profile as OatProfile;

    final result = OatEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: oatProfile,
      stressDelayDays: stressDelayDays,
    );

    return CropStageResult(
      stageKey: result.stage.name,
      stageLabelEs: result.stageLabelEs,
      expectedDaysToEnd: result.expectedDaysToEnd,
      windowsNow: result.windowsNow,
      heroAsset: result.heroAsset,
    );
  }
}
