import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';

abstract class CropDefinition {
  CropKey get cropKey;
  CropCategory get category;
  String get displayName;

  CropEngine get engine;

  CropProfile? resolveProfile({String? profileId, String? varietyAlias});

  StageTargets? resolveTargets(CropStageResult stage);

  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  });
}
