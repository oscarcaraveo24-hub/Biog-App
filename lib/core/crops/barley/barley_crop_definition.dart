import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/cereal_agro_score_engine.dart';
import 'package:bio_g/core/crops/barley/barley_crop_engine_adapter.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/crops/barley/barley_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/barley_models.dart';
import 'package:bio_g/widgets/seeds/barley_profiles.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class BarleyCropDefinition implements CropDefinition {
  static const Set<String> _criticalStages = {
    'booting',
    'heading',
    'flowering',
  };

  @override
  CropKey get cropKey => CropKey.barley;

  @override
  CropCategory get category => CropCategory.grain;

  @override
  String get displayName => 'Cebada';

  @override
  CropEngine get engine => BarleyCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonicalProfileId = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonicalProfileId != null) {
      final resolved = barleyProfiles[canonicalProfileId];
      if (resolved != null) return resolved;
    }

    if (barleyProfiles.containsKey(kCbGen)) {
      return barleyProfiles[kCbGen];
    }

    if (barleyProfiles.isNotEmpty) {
      return barleyProfiles.values.first;
    }

    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final barleyStage = _resolveStage(stage.stageKey);
    return barleyUniversalV1.byStage[barleyStage];
  }

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    final bioTelemetry = telemetry as BioGTelemetry;
    final barleyStage = _resolveStage(stage.stageKey);
    final barleyProfile = profile as BarleyProfile;
    final weights = barleyUniversalV1.weights[barleyStage];
    final targets = targetsOverride ?? barleyUniversalV1.byStage[barleyStage];

    if (targets == null || weights == null) {
      final empty = AgroEvalResult(
        soilControlScore01: 0.0,
        metrics: const {},
        alerts: const [],
        suggestedAlertKeys: const ['stage.unknown'],
      );
      return (eval: empty, nextAlertsState: alertsState);
    }

    final seedStage = BarleyStageResult(
      profile: barleyProfile,
      stage: barleyStage,
      daySinceSowing: 0,
      floweringBand: barleyProfile.floweringDays,
      endBand: barleyProfile.endWindowDays,
      expectedFloweringDay: barleyProfile.floweringDays.mid,
      expectedEndDay: barleyProfile.endWindowDays.mid,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: 0,
      windowsNow: const [],
      expectedPlantHeightTodayM: const RangeDouble(0, 0),
      stageLabelEs: stage.stageLabelEs,
      heroAsset: stage.heroAsset,
      helperCaption: '',
    );

    return CerealAgroScoreEngine.evaluate(
      t: bioTelemetry,
      targets: targets,
      weights: weights,
      stageKey: barleyStage.name,
      criticalStageKeys: _criticalStages,
      alertsState: alertsState,
      cropLabel: 'Cebada',
      stageLabel: seedStage.stageLabelEs,
    );
  }

  BarleyStageKey _resolveStage(String rawStage) {
    return BarleyStageKey.values.firstWhere(
      (stage) => stage.name == rawStage,
      orElse: () => BarleyStageKey.tillering,
    );
  }

  String? _resolveCanonicalProfileId({
    String? profileId,
    String? varietyAlias,
  }) {
    if (profileId != null && profileId.trim().isNotEmpty) {
      final canonical = resolveCanonicalBarleyProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }

    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalBarleyProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }

    return null;
  }
}
