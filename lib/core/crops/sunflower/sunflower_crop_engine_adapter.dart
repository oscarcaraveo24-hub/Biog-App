import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_engine.dart';
import 'package:bio_g/widgets/seeds/sunflower_models.dart';

/// Adaptador del motor anual del Girasol al contrato `CropEngine`. Espeja el
/// patrón de `TulipCropEngineAdapter` / `OatCropEngineAdapter`: `sowingDate` se
/// interpreta como la FECHA ANCLA del ciclo (Documento A §9.1). Emite `stageKey`
/// en snake_case canónico para que assets, sanidad, ciclo-UI y targets lo
/// compartan. A diferencia del Tulipán, `stageProgressPct` NUNCA es null: en la
/// etapa terminal `cycle_complete` es 1.0 (Documento A §11.9).
class SunflowerCropEngineAdapter implements CropEngine {
  const SunflowerCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final sunflowerProfile = profile as SunflowerProfile;

    final result = SunflowerEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: sunflowerProfile,
      stressDelayDays: stressDelayDays,
    );

    return CropStageResult(
      stageKey: result.stageId,
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
