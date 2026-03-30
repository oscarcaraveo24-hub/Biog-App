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
    final stageResolution = _resolveStage(stage.stageKey);
    return maizeUniversalV1.byStage[stageResolution.stage];
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
    final stageResolution = _resolveStage(stage.stageKey);
    final maizeStage = stageResolution.stage;
    final maizeProfile = profile as MaizeProfile;

    final seedStage = SeedStageResult(
      profile: maizeProfile,
      stage: maizeStage,
      daySinceSowing: stage.daySinceSowing ?? 0,
      r1Band: maizeProfile.r1Days,
      endBand: maizeProfile.endWindowDays,
      expectedR1Day: maizeProfile.r1Days.mid,
      expectedEndDay: maizeProfile.endWindowDays.max,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: stage.stageProgressPct ?? 0,
      windowsNow: stage.windowsNow.whereType<SeedWindowKey>().toList(
        growable: false,
      ),
      expectedPlantHeightTodayM: _expectedHeightForStage(
        profile: maizeProfile,
        stage: maizeStage,
      ),
      stageLabelEs: stage.stageLabelEs,
      heroAsset: stage.heroAsset,
      helperCaption: stage.helperCaption,
    );

    final out = AgroScoreEngine.evaluateMaize(
      t: bioTelemetry,
      stage: seedStage,
      u: maizeUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Maíz',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedMaizeStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();

    for (final stage in MaizeStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedMaizeStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedMaizeStage(
        stage: MaizeStageKey.germination,
        usedFallback: false,
      );
    }
    if (normalized.contains('emerg')) {
      return const _ResolvedMaizeStage(
        stage: MaizeStageKey.emergence,
        usedFallback: false,
      );
    }
    if (normalized.contains('tempr')) {
      return const _ResolvedMaizeStage(
        stage: MaizeStageKey.vegEarly,
        usedFallback: false,
      );
    }
    if (normalized.contains('media') || normalized.contains('mid')) {
      return const _ResolvedMaizeStage(
        stage: MaizeStageKey.vegMid,
        usedFallback: false,
      );
    }
    if (normalized.contains('avanz') || normalized.contains('pre')) {
      return const _ResolvedMaizeStage(
        stage: MaizeStageKey.vegAdvanced,
        usedFallback: false,
      );
    }
    if (normalized.contains('tass') || normalized.contains('espig')) {
      return const _ResolvedMaizeStage(
        stage: MaizeStageKey.tasseling,
        usedFallback: false,
      );
    }
    if (normalized.contains('flower') ||
        normalized.contains('flor') ||
        normalized.contains('cuaj')) {
      return const _ResolvedMaizeStage(
        stage: MaizeStageKey.flowerSet,
        usedFallback: false,
      );
    }
    if (normalized.contains('llen') ||
        normalized.contains('matur') ||
        normalized.contains('senesc')) {
      return const _ResolvedMaizeStage(
        stage: MaizeStageKey.maturitySenescence,
        usedFallback: false,
      );
    }
    if (normalized.contains('harvest') || normalized.contains('cosech')) {
      return const _ResolvedMaizeStage(
        stage: MaizeStageKey.harvest,
        usedFallback: false,
      );
    }

    return const _ResolvedMaizeStage(
      stage: MaizeStageKey.vegMid,
      usedFallback: true,
    );
  }

  ({AgroEvalResult eval, AlertsState nextAlertsState})
  _withStageFallbackDiagnostic(
    ({AgroEvalResult eval, AlertsState nextAlertsState}) out,
    bool usedFallback,
  ) {
    if (!usedFallback) return out;

    return (
      eval: AgroEvalResult(
        soilControlScore01: out.eval.soilControlScore01,
        nutrientPriorityScore01: out.eval.nutrientPriorityScore01,
        primaryScoreKind: out.eval.primaryScoreKind,
        metrics: out.eval.metrics,
        alerts: out.eval.alerts,
        suggestedAlertKeys: <String>[
          ...out.eval.suggestedAlertKeys,
          'stage.fallback',
        ],
      ),
      nextAlertsState: out.nextAlertsState,
    );
  }


  RangeDouble _expectedHeightForStage({
    required MaizeProfile profile,
    required MaizeStageKey stage,
  }) {
    final pct = switch (stage) {
      MaizeStageKey.germination => const RangeDouble(0.00, 0.02),
      MaizeStageKey.emergence => const RangeDouble(0.02, 0.05),
      MaizeStageKey.vegEarly => const RangeDouble(0.10, 0.30),
      MaizeStageKey.vegMid => const RangeDouble(0.30, 0.55),
      MaizeStageKey.vegAdvanced => const RangeDouble(0.55, 0.70),
      MaizeStageKey.tasseling => const RangeDouble(0.70, 0.85),
      MaizeStageKey.flowerSet => const RangeDouble(0.80, 0.90),
      MaizeStageKey.maturitySenescence => const RangeDouble(0.90, 1.00),
      MaizeStageKey.harvest => const RangeDouble(0.95, 1.00),
    };

    return RangeDouble(
      profile.plantHeightM.min * pct.min,
      profile.plantHeightM.max * pct.max,
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

class _ResolvedMaizeStage {
  final MaizeStageKey stage;
  final bool usedFallback;

  const _ResolvedMaizeStage({required this.stage, required this.usedFallback});
}
