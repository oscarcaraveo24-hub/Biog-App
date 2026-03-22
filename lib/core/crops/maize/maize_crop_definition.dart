import 'package:bio_g/core/agro/agro_score_engine.dart';
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/maize/maize_crop_engine_adapter.dart';
import 'package:bio_g/crops/maize/maize_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/maize_profiles.dart';

class MaizeCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.maize;

  @override
  CropCategory get category => CropCategory.grain;

  @override
  String get displayName => 'Maíz';

  @override
  CropEngine get engine => MaizeCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonicalProfileId = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonicalProfileId != null) {
      final resolved = maizeProfiles[canonicalProfileId];
      if (resolved != null) return resolved;
    }

    if (maizeProfiles.containsKey(kMaizeGenericProfileId)) {
      return maizeProfiles[kMaizeGenericProfileId];
    }

    if (maizeProfiles.isNotEmpty) {
      return maizeProfiles.values.first;
    }

    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final maizeStage = MaizeStageKey.values.firstWhere(
      (e) => e.name == stage.stageKey,
      orElse: () => MaizeStageKey.vegMid,
    );

    return maizeUniversalV1.byStage[maizeStage];
  }

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required AlertsState alertsState,
  }) {
    final bioTelemetry = telemetry as BioGTelemetry;

    final maizeStage = MaizeStageKey.values.firstWhere(
      (e) => e.name == stage.stageKey,
      orElse: () => MaizeStageKey.vegMid,
    );

    final fallbackProfile =
        maizeProfiles[kMaizeGenericProfileId] ?? maizeProfiles.values.first;

    final seedStage = SeedStageResult(
      profile: fallbackProfile,
      stage: maizeStage,
      daySinceSowing: 0,
      r1Band: fallbackProfile.r1Days,
      endBand: fallbackProfile.endWindowDays,
      expectedR1Day: fallbackProfile.r1Days.mid,
      expectedEndDay: fallbackProfile.endWindowDays.mid,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: 0,
      windowsNow: const [],
      expectedPlantHeightTodayM: const RangeDouble(0, 0),
      stageLabelEs: stage.stageLabelEs,
      heroAsset: stage.heroAsset,
      helperCaption: '',
    );

    return AgroScoreEngine.evaluateMaize(
      t: bioTelemetry,
      stage: seedStage,
      u: maizeUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Maíz',
    );
  }

  String? _resolveCanonicalProfileId({
    String? profileId,
    String? varietyAlias,
  }) {
    if (profileId != null && profileId.trim().isNotEmpty) {
      final canonicalFromProfileId = resolveCanonicalMaizeProfileId(
        profileId.trim(),
      );
      if (canonicalFromProfileId != null) return canonicalFromProfileId;
    }

    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonicalFromAlias = resolveCanonicalMaizeProfileId(
        varietyAlias.trim(),
      );
      if (canonicalFromAlias != null) return canonicalFromAlias;
    }

    return null;
  }
}
