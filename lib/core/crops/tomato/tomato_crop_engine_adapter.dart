import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/tomato_engine.dart';
import 'package:bio_g/widgets/seeds/tomato_models.dart';

/// Adapter que expone TomatoEngine contra el contrato CropEngine.
class TomatoCropEngineAdapter implements CropEngine {
  /// Modo de establecimiento a usar en el cálculo.
  ///
  /// Si es null, el engine usa el default del perfil (trasplante en v1).
  /// El resolver superior inyecta este valor desde el DeviceCropContext
  /// (campo `establishmentModeId`).
  final TomatoEstablishmentMode? establishmentMode;

  const TomatoCropEngineAdapter({this.establishmentMode});

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final tomatoProfile = profile as TomatoProfile;

    final result = TomatoEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: tomatoProfile,
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
