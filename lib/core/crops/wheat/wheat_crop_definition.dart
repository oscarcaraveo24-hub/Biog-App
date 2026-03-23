import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/wheat_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/wheat/wheat_crop_engine_adapter.dart';
import 'package:bio_g/crops/wheat/wheat_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/wheat_models.dart';
import 'package:bio_g/widgets/seeds/wheat_profiles.dart';

class WheatCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.wheat;

  @override
  CropCategory get category => CropCategory.grain;

  @override
  String get displayName => 'Trigo';

  @override
  CropEngine get engine => WheatCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonicalProfileId = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonicalProfileId != null) {
      final resolved = wheatProfiles[canonicalProfileId];
      if (resolved != null) return resolved;
    }

    if (wheatProfiles.containsKey(kTrGen)) {
      return wheatProfiles[kTrGen];
    }

    if (wheatProfiles.isNotEmpty) {
      return wheatProfiles.values.first;
    }

    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final wheatStage = _resolveStage(stage.stageKey);
    return wheatUniversalV1.byStage[wheatStage];
  }

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required AlertsState alertsState,
  }) {
    final bioTelemetry = telemetry as BioGTelemetry;
    final wheatStage = _resolveStage(stage.stageKey);

    final fallbackProfile = wheatProfiles[kTrGen] ?? wheatProfiles.values.first;

    final seedStage = WheatStageResult(
      profile: fallbackProfile,
      stage: wheatStage,
      daySinceSowing: 0,
      floweringBand: fallbackProfile.floweringDays,
      endBand: fallbackProfile.endWindowDays,
      expectedFloweringDay: fallbackProfile.floweringDays.mid,
      expectedEndDay: fallbackProfile.endWindowDays.mid,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: 0,
      windowsNow: const [],
      expectedPlantHeightTodayM: const RangeDouble(0, 0),
      stageLabelEs: stage.stageLabelEs,
      heroAsset: stage.heroAsset,
      helperCaption: '',
    );

    return WheatAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: wheatUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Trigo',
    );
  }

  WheatStageKey _resolveStage(String rawStage) {
    return WheatStageKey.values.firstWhere(
      (stage) => stage.name == rawStage,
      orElse: () => WheatStageKey.tillering,
    );
  }

  String? _resolveCanonicalProfileId({
    String? profileId,
    String? varietyAlias,
  }) {
    if (profileId != null && profileId.trim().isNotEmpty) {
      final canonical = resolveCanonicalWheatProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }

    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalWheatProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }

    return null;
  }
}
