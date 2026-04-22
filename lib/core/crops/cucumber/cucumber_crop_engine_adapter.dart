import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/cucumber_engine.dart';
import 'package:bio_g/widgets/seeds/cucumber_models.dart';

/// Adapter que expone CucumberEngine contra el contrato CropEngine.
class CucumberCropEngineAdapter implements CropEngine {
  /// Si viene null, el engine usa el default del perfil.
  final CucumberEstablishmentMode? establishmentMode;

  const CucumberCropEngineAdapter({this.establishmentMode});

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final cucumberProfile = profile as CucumberProfile;

    final result = CucumberEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: cucumberProfile,
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
