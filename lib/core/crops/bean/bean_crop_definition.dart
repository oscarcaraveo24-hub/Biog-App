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
    final stageResolution = _resolveStage(stage.stageKey);
    return beanUniversalV1.byStage[stageResolution.stage];
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
    final beanStage = stageResolution.stage;
    final beanProfile = profile as BeanProfile;

    final seedStage = BeanStageResult(
      profile: beanProfile,
      stage: beanStage,
      daySinceSowing: stage.daySinceSowing ?? 0,
      floweringBand: beanProfile.floweringDays,
      endBand: beanProfile.endWindowDays,
      expectedFloweringDay: beanProfile.floweringDays.mid,
      expectedEndDay: beanProfile.endWindowDays.mid,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: stage.stageProgressPct ?? 0,
      windowsNow: stage.windowsNow.whereType<SeedWindowKey>().toList(growable: false),
      expectedPlantHeightTodayM: const RangeDouble(0, 0),
      stageLabelEs: stage.stageLabelEs,
      heroAsset: stage.heroAsset,
      helperCaption: stage.helperCaption,
    );

    final out = BeanAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: beanUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Frijol',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedBeanStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in BeanStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedBeanStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedBeanStage(stage: BeanStageKey.germination, usedFallback: false);
    }
    if (normalized.contains('emerg')) {
      return const _ResolvedBeanStage(stage: BeanStageKey.emergence, usedFallback: false);
    }
    if (normalized.contains('tempr')) {
      return const _ResolvedBeanStage(stage: BeanStageKey.vegEarly, usedFallback: false);
    }
    if (normalized.contains('pre') || normalized.contains('advanced') || normalized.contains('avanz')) {
      return const _ResolvedBeanStage(stage: BeanStageKey.vegAdvanced, usedFallback: false);
    }
    if (normalized.contains('flower') || normalized.contains('flor')) {
      return const _ResolvedBeanStage(stage: BeanStageKey.flowering, usedFallback: false);
    }
    if (normalized.contains('pod') || normalized.contains('vaina') || normalized.contains('amarre')) {
      return const _ResolvedBeanStage(stage: BeanStageKey.podSet, usedFallback: false);
    }
    if (normalized.contains('grain') || normalized.contains('llen')) {
      return const _ResolvedBeanStage(stage: BeanStageKey.grainFill, usedFallback: false);
    }
    if (normalized.contains('matur') || normalized.contains('senesc')) {
      return const _ResolvedBeanStage(stage: BeanStageKey.physiologicalMaturity, usedFallback: false);
    }
    if (normalized.contains('harvest') || normalized.contains('cosech')) {
      return const _ResolvedBeanStage(stage: BeanStageKey.harvest, usedFallback: false);
    }

    return const _ResolvedBeanStage(
      stage: BeanStageKey.vegEarly,
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

class _ResolvedBeanStage {
  final BeanStageKey stage;
  final bool usedFallback;

  const _ResolvedBeanStage({required this.stage, required this.usedFallback});
}
