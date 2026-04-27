import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/eggplant_engine.dart';
import 'package:bio_g/widgets/seeds/eggplant_models.dart';

class EggplantCropEngineAdapter implements CropEngine {
  final EggplantEstablishmentMode? establishmentMode;

  const EggplantCropEngineAdapter({this.establishmentMode});

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final eggplantProfile = profile as EggplantProfile;

    final result = EggplantEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: eggplantProfile,
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
