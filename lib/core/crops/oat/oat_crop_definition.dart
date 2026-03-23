import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/cereal_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/oat/oat_crop_engine_adapter.dart';
import 'package:bio_g/crops/oat/oat_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/oat_models.dart';
import 'package:bio_g/widgets/seeds/oat_profiles.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class OatCropDefinition implements CropDefinition {
  static const Set<String> _criticalStages = {
    'booting',
    'heading',
    'flowering',
  };

  @override
  CropKey get cropKey => CropKey.oat;

  @override
  CropCategory get category => CropCategory.grain;

  @override
  String get displayName => 'Avena';

  @override
  CropEngine get engine => OatCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonicalProfileId = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonicalProfileId != null) {
      final resolved = oatProfiles[canonicalProfileId];
      if (resolved != null) return resolved;
    }

    if (oatProfiles.containsKey(kAvGen)) {
      return oatProfiles[kAvGen];
    }

    if (oatProfiles.isNotEmpty) {
      return oatProfiles.values.first;
    }

    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final oatStage = _resolveStage(stage.stageKey);
    return oatUniversalV1.byStage[oatStage];
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
    final oatStage = _resolveStage(stage.stageKey);
    final oatProfile = profile as OatProfile;
    final weights = oatUniversalV1.weights[oatStage];
    final targets = targetsOverride ?? oatUniversalV1.byStage[oatStage];

    if (targets == null || weights == null) {
      final empty = AgroEvalResult(
        soilControlScore01: 0.0,
        metrics: const {},
        alerts: const [],
        suggestedAlertKeys: const ['stage.unknown'],
      );
      return (eval: empty, nextAlertsState: alertsState);
    }

    final seedStage = OatStageResult(
      profile: oatProfile,
      stage: oatStage,
      daySinceSowing: 0,
      floweringBand: oatProfile.floweringDays,
      endBand: oatProfile.endWindowDays,
      expectedFloweringDay: oatProfile.floweringDays.mid,
      expectedEndDay: oatProfile.endWindowDays.mid,
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
      stageKey: oatStage.name,
      criticalStageKeys: _criticalStages,
      alertsState: alertsState,
      cropLabel: 'Avena',
      stageLabel: seedStage.stageLabelEs,
    );
  }

  OatStageKey _resolveStage(String rawStage) {
    return OatStageKey.values.firstWhere(
      (stage) => stage.name == rawStage,
      orElse: () => OatStageKey.tillering,
    );
  }

  String? _resolveCanonicalProfileId({
    String? profileId,
    String? varietyAlias,
  }) {
    if (profileId != null && profileId.trim().isNotEmpty) {
      final canonical = resolveCanonicalOatProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }

    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalOatProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }

    return null;
  }
}
