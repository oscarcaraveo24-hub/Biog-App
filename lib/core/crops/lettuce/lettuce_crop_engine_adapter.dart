import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/lettuce_engine.dart';
import 'package:bio_g/widgets/seeds/lettuce_models.dart';

/// Adaptador entre el motor fenológico de lechuga y la API `CropEngine`.
/// Se mantiene paralelo al adapter de calabaza/berenjena.
class LettuceCropEngineAdapter implements CropEngine {
  final LettuceEstablishmentMode? establishmentMode;

  const LettuceCropEngineAdapter({this.establishmentMode});

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final lettuceProfile = profile as LettuceProfile;

    final result = LettuceEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: lettuceProfile,
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
