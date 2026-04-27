import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/chili_engine.dart';
import 'package:bio_g/widgets/seeds/chili_models.dart';

class ChiliCropEngineAdapter implements CropEngine {
  final ChiliEstablishmentMode? establishmentMode;

  const ChiliCropEngineAdapter({this.establishmentMode});

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final chiliProfile = profile as ChiliProfile;

    final result = ChiliEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: chiliProfile,
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
      productiveState: result.productiveState?.name,
      productiveStateLabelEs: result.productiveStateLabelEs.isEmpty
          ? null
          : result.productiveStateLabelEs,
    );
  }
}
