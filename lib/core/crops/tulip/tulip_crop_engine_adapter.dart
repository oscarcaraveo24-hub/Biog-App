import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/tulip_engine.dart';
import 'package:bio_g/widgets/seeds/tulip_models.dart';

/// Adaptador del motor anual del Tulipán al contrato `CropEngine`. Espeja el
/// patrón de `OatCropEngineAdapter`: `sowingDate` se interpreta como la
/// FECHA ANCLA del ciclo (Documento A §2.1). Emite `stageKey` en snake_case
/// canónico para que assets, sanidad, ciclo-UI y targets lo compartan, y
/// conserva `stageProgressPct = null` en dormancia.
class TulipCropEngineAdapter implements CropEngine {
  const TulipCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final tulipProfile = profile as TulipProfile;

    final result = TulipEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: tulipProfile,
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
