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
    final stageResolution = _resolveStage(stage.stageKey);
    return wheatUniversalV1.byStage[stageResolution.stage];
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
    final wheatStage = stageResolution.stage;
    final wheatProfile = profile as WheatProfile;

    final seedStage = WheatStageResult(
      profile: wheatProfile,
      stage: wheatStage,
      daySinceSowing: stage.daySinceSowing ?? 0,
      floweringBand: wheatProfile.floweringDays,
      endBand: wheatProfile.endWindowDays,
      expectedFloweringDay: wheatProfile.floweringDays.mid,
      expectedEndDay: wheatProfile.endWindowDays.mid,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: stage.stageProgressPct ?? 0,
      windowsNow: stage.windowsNow.whereType<SeedWindowKey>().toList(growable: false),
      expectedPlantHeightTodayM: const RangeDouble(0, 0),
      stageLabelEs: stage.stageLabelEs,
      heroAsset: stage.heroAsset,
      helperCaption: stage.helperCaption,
    );

    final out = WheatAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: wheatUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Trigo',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedWheatStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in WheatStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedWheatStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedWheatStage(stage: WheatStageKey.germination, usedFallback: false);
    }
    if (normalized.contains('emerg')) {
      return const _ResolvedWheatStage(stage: WheatStageKey.emergence, usedFallback: false);
    }
    if (normalized.contains('tempr')) {
      return const _ResolvedWheatStage(stage: WheatStageKey.vegEarly, usedFallback: false);
    }
    if (normalized.contains('tiller') || normalized.contains('macoll')) {
      return const _ResolvedWheatStage(stage: WheatStageKey.tillering, usedFallback: false);
    }
    if (normalized.contains('elong') || normalized.contains('encañ') || normalized.contains('encane')) {
      return const _ResolvedWheatStage(stage: WheatStageKey.elongation, usedFallback: false);
    }
    if (normalized.contains('boot') || normalized.contains('embuch')) {
      return const _ResolvedWheatStage(stage: WheatStageKey.booting, usedFallback: false);
    }
    if (normalized.contains('head') || normalized.contains('espig')) {
      return const _ResolvedWheatStage(stage: WheatStageKey.heading, usedFallback: false);
    }
    if (normalized.contains('flower') || normalized.contains('flor') || normalized.contains('antes')) {
      return const _ResolvedWheatStage(stage: WheatStageKey.flowering, usedFallback: false);
    }
    if (normalized.contains('grain') || normalized.contains('llen')) {
      return const _ResolvedWheatStage(stage: WheatStageKey.grainFill, usedFallback: false);
    }
    if (normalized.contains('matur')) {
      return const _ResolvedWheatStage(stage: WheatStageKey.physiologicalMaturity, usedFallback: false);
    }
    if (normalized.contains('harvest') || normalized.contains('cosech')) {
      return const _ResolvedWheatStage(stage: WheatStageKey.harvest, usedFallback: false);
    }

    return const _ResolvedWheatStage(
      stage: WheatStageKey.tillering,
      usedFallback: true,
    );
  }

  ({AgroEvalResult eval, AlertsState nextAlertsState}) _withStageFallbackDiagnostic(
    ({AgroEvalResult eval, AlertsState nextAlertsState}) out,
    bool usedFallback,
  ) {
    if (!usedFallback) return out;

    return (
      eval: AgroEvalResult(
        soilControlScore01: out.eval.soilControlScore01,
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

class _ResolvedWheatStage {
  final WheatStageKey stage;
  final bool usedFallback;

  const _ResolvedWheatStage({required this.stage, required this.usedFallback});
}
