import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/oat_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/oat/oat_crop_engine_adapter.dart';
import 'package:bio_g/crops/oat/oat_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/oat_models.dart';
import 'package:bio_g/widgets/seeds/oat_profiles.dart';

class OatCropDefinition implements CropDefinition {
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
    final stageResolution = _resolveStage(stage.stageKey);
    return oatUniversalV1.byStage[stageResolution.stage];
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
    final oatStage = stageResolution.stage;
    final oatProfile = profile as OatProfile;

    final seedStage = OatStageResult(
      profile: oatProfile,
      stage: oatStage,
      daySinceSowing: stage.daySinceSowing ?? 0,
      floweringBand: oatProfile.floweringDays,
      endBand: oatProfile.endWindowDays,
      expectedFloweringDay: oatProfile.floweringDays.mid,
      expectedEndDay: oatProfile.endWindowDays.mid,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: stage.stageProgressPct ?? 0,
      windowsNow: stage.windowsNow.whereType<SeedWindowKey>().toList(growable: false),
      expectedPlantHeightTodayM: _expectedHeightForStage(
        profile: oatProfile,
        stage: oatStage,
        stageProgress: stage.stageProgressPct ?? 0.5,
      ),
      stageLabelEs: stage.stageLabelEs,
      heroAsset: stage.heroAsset,
      helperCaption: stage.helperCaption,
    );

    final out = OatAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: oatUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Avena',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedOatStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in OatStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedOatStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedOatStage(stage: OatStageKey.germination, usedFallback: false);
    }
    if (normalized.contains('emerg')) {
      return const _ResolvedOatStage(stage: OatStageKey.emergence, usedFallback: false);
    }
    if (normalized.contains('tempr')) {
      return const _ResolvedOatStage(stage: OatStageKey.vegEarly, usedFallback: false);
    }
    if (normalized.contains('tiller') || normalized.contains('macoll')) {
      return const _ResolvedOatStage(stage: OatStageKey.tillering, usedFallback: false);
    }
    if (normalized.contains('elong') || normalized.contains('encañ') || normalized.contains('encane')) {
      return const _ResolvedOatStage(stage: OatStageKey.elongation, usedFallback: false);
    }
    if (normalized.contains('boot') || normalized.contains('embuch')) {
      return const _ResolvedOatStage(stage: OatStageKey.booting, usedFallback: false);
    }
    if (normalized.contains('head') || normalized.contains('espig')) {
      return const _ResolvedOatStage(stage: OatStageKey.heading, usedFallback: false);
    }
    if (normalized.contains('flower') || normalized.contains('flor')) {
      return const _ResolvedOatStage(stage: OatStageKey.flowering, usedFallback: false);
    }
    if (normalized.contains('grain') || normalized.contains('llen')) {
      return const _ResolvedOatStage(stage: OatStageKey.grainFill, usedFallback: false);
    }
    if (normalized.contains('matur')) {
      return const _ResolvedOatStage(stage: OatStageKey.physiologicalMaturity, usedFallback: false);
    }
    if (normalized.contains('harvest') || normalized.contains('cosech')) {
      return const _ResolvedOatStage(stage: OatStageKey.harvest, usedFallback: false);
    }

    return const _ResolvedOatStage(
      stage: OatStageKey.tillering,
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

  RangeDouble _expectedHeightForStage({
    required OatProfile profile,
    required OatStageKey stage,
    double stageProgress = 0.5,
  }) {
    final (double startPct, double endPct) = switch (stage) {
      OatStageKey.germination => (0.00, 0.02),
      OatStageKey.emergence => (0.02, 0.05),
      OatStageKey.vegEarly => (0.05, 0.18),
      OatStageKey.tillering => (0.18, 0.38),
      OatStageKey.elongation => (0.38, 0.65),
      OatStageKey.booting => (0.65, 0.82),
      OatStageKey.heading => (0.82, 0.95),
      OatStageKey.flowering => (0.95, 1.00),
      OatStageKey.grainFill => (0.95, 1.00),
      OatStageKey.physiologicalMaturity => (0.95, 1.00),
      OatStageKey.harvest => (0.95, 1.00),
    };

    final p = stageProgress.clamp(0.0, 1.0);
    final pct = startPct + (endPct - startPct) * p;

    return RangeDouble(
      profile.plantHeightM.min * pct,
      profile.plantHeightM.max * pct,
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

class _ResolvedOatStage {
  final OatStageKey stage;
  final bool usedFallback;

  const _ResolvedOatStage({required this.stage, required this.usedFallback});
}
