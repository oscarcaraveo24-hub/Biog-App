import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/barley_agro_score_engine.dart';
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
    final stageResolution = _resolveStage(stage.stageKey);
    return barleyUniversalV1.byStage[stageResolution.stage];
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
    final barleyStage = stageResolution.stage;
    final barleyProfile = profile as BarleyProfile;

    final seedStage = BarleyStageResult(
      profile: barleyProfile,
      stage: barleyStage,
      daySinceSowing: stage.daySinceSowing ?? 0,
      floweringBand: barleyProfile.floweringDays,
      endBand: barleyProfile.endWindowDays,
      expectedFloweringDay: barleyProfile.floweringDays.mid,
      expectedEndDay: barleyProfile.endWindowDays.mid,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: stage.stageProgressPct ?? 0,
      windowsNow: stage.windowsNow.whereType<SeedWindowKey>().toList(growable: false),
      expectedPlantHeightTodayM: const RangeDouble(0, 0),
      stageLabelEs: stage.stageLabelEs,
      heroAsset: stage.heroAsset,
      helperCaption: stage.helperCaption,
    );

    final out = BarleyAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: barleyUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Cebada',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedBarleyStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in BarleyStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedBarleyStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedBarleyStage(stage: BarleyStageKey.germination, usedFallback: false);
    }
    if (normalized.contains('emerg')) {
      return const _ResolvedBarleyStage(stage: BarleyStageKey.emergence, usedFallback: false);
    }
    if (normalized.contains('tempr')) {
      return const _ResolvedBarleyStage(stage: BarleyStageKey.vegEarly, usedFallback: false);
    }
    if (normalized.contains('tiller') || normalized.contains('macoll')) {
      return const _ResolvedBarleyStage(stage: BarleyStageKey.tillering, usedFallback: false);
    }
    if (normalized.contains('elong') || normalized.contains('encañ') || normalized.contains('encane')) {
      return const _ResolvedBarleyStage(stage: BarleyStageKey.elongation, usedFallback: false);
    }
    if (normalized.contains('boot') || normalized.contains('embuch')) {
      return const _ResolvedBarleyStage(stage: BarleyStageKey.booting, usedFallback: false);
    }
    if (normalized.contains('head') || normalized.contains('espig')) {
      return const _ResolvedBarleyStage(stage: BarleyStageKey.heading, usedFallback: false);
    }
    if (normalized.contains('flower') || normalized.contains('flor') || normalized.contains('antes')) {
      return const _ResolvedBarleyStage(stage: BarleyStageKey.flowering, usedFallback: false);
    }
    if (normalized.contains('grain') || normalized.contains('llen')) {
      return const _ResolvedBarleyStage(stage: BarleyStageKey.grainFill, usedFallback: false);
    }
    if (normalized.contains('matur')) {
      return const _ResolvedBarleyStage(stage: BarleyStageKey.physiologicalMaturity, usedFallback: false);
    }
    if (normalized.contains('harvest') || normalized.contains('cosech')) {
      return const _ResolvedBarleyStage(stage: BarleyStageKey.harvest, usedFallback: false);
    }

    return const _ResolvedBarleyStage(
      stage: BarleyStageKey.tillering,
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

class _ResolvedBarleyStage {
  final BarleyStageKey stage;
  final bool usedFallback;

  const _ResolvedBarleyStage({required this.stage, required this.usedFallback});
}
