import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/bean_agro_score_engine.dart';
import 'package:bio_g/core/crops/bean/bean_crop_engine_adapter.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/crops/bean/bean_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/bean_models.dart';
import 'package:bio_g/widgets/seeds/bean_profiles.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class BeanCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.bean;

  @override
  CropCategory get category => CropCategory.grain;

  @override
  String get displayName => 'Frijol';

  @override
  CropEngine get engine => BeanCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonicalProfileId = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonicalProfileId != null) {
      final resolved = beanProfiles[canonicalProfileId];
      if (resolved != null) return resolved;
    }

    if (beanProfiles.containsKey(kFjGen)) {
      return beanProfiles[kFjGen];
    }

    if (beanProfiles.isNotEmpty) {
      return beanProfiles.values.first;
    }

    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final beanStage = _resolveStage(stage.stageKey);
    return beanUniversalV1.byStage[beanStage];
  }

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required AlertsState alertsState,
  }) {
    final bioTelemetry = telemetry as BioGTelemetry;
    final beanStage = _resolveStage(stage.stageKey);

    final fallbackProfile = beanProfiles[kFjGen] ?? beanProfiles.values.first;

    final seedStage = BeanStageResult(
      profile: fallbackProfile,
      stage: beanStage,
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

    return BeanAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: beanUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Frijol',
    );
  }

  BeanStageKey _resolveStage(String rawStage) {
    return BeanStageKey.values.firstWhere(
      (stage) => stage.name == rawStage,
      orElse: () => BeanStageKey.vegAdvanced,
    );
  }

  String? _resolveCanonicalProfileId({
    String? profileId,
    String? varietyAlias,
  }) {
    if (profileId != null && profileId.trim().isNotEmpty) {
      final canonical = resolveCanonicalBeanProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }

    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalBeanProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }

    return null;
  }
}
