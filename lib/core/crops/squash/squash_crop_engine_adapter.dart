import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/squash_engine.dart';
import 'package:bio_g/widgets/seeds/squash_models.dart';

/// Adaptador entre el motor fenológico de calabaza y la API de
/// `CropEngine`. Se mantiene paralelo al adapter de berenjena/pepino.
class SquashCropEngineAdapter implements CropEngine {
  final SquashEstablishmentMode? establishmentMode;

  const SquashCropEngineAdapter({this.establishmentMode});

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final squashProfile = profile as SquashProfile;

    final result = SquashEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: squashProfile,
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
