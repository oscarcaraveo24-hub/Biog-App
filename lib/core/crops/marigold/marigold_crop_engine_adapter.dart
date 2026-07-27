import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/marigold_engine.dart';
import 'package:bio_g/widgets/seeds/marigold_models.dart';

/// Adaptador del motor anual del Cempasúchil al contrato `CropEngine`. Espeja
/// el patrón de `SunflowerCropEngineAdapter` / `TulipCropEngineAdapter`:
/// `sowingDate` se interpreta como la FECHA ANCLA del ciclo (Documento A §9.1,
/// §13.1). Emite `stageKey` en snake_case canónico para que assets, sanidad,
/// ciclo-UI y targets lo compartan. Igual que el Girasol y a diferencia del
/// Tulipán, `stageProgressPct` NUNCA es null: en la etapa terminal
/// `cycle_complete` es 1.0 (Documento A §10.11).
class MarigoldCropEngineAdapter implements CropEngine {
  const MarigoldCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final marigoldProfile = profile as MarigoldProfile;

    final result = MarigoldEngine.compute(
      sowingDate: sowingDate,
      today: today,
      profile: marigoldProfile,
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
