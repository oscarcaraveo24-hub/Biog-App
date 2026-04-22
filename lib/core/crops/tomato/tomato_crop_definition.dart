import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/tomato_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/tomato/tomato_crop_engine_adapter.dart';
import 'package:bio_g/crops/tomato/tomato_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/tomato_models.dart';
import 'package:bio_g/widgets/seeds/tomato_profiles.dart';

class TomatoCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.tomato;

  @override
  CropCategory get category => CropCategory.vegetable;

  @override
  String get displayName => 'Tomate';

  @override
  CropEngine get engine => const TomatoCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonicalProfileId = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonicalProfileId != null) {
      final resolved = tomatoProfiles[canonicalProfileId];
      if (resolved != null) return resolved;
    }

    // Fallback: TM-GEN (skip obligatorio de la filosofía BIO-G).
    if (tomatoProfiles.containsKey(kTmGen)) {
      return tomatoProfiles[kTmGen];
    }

    if (tomatoProfiles.isNotEmpty) {
      return tomatoProfiles.values.first;
    }

    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final stageResolution = _resolveStage(stage.stageKey);
    return tomatoUniversalV1.byStage[stageResolution.stage];
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
    final tomatoStage = stageResolution.stage;
    final tomatoProfile = profile as TomatoProfile;

    final seedStage = TomatoStageResult(
      profile: tomatoProfile,
      stage: tomatoStage,
      daySinceAnchor: stage.daySinceSowing ?? 0,
      establishmentMode: tomatoProfile.defaultEstablishmentMode,
      floweringBand: tomatoProfile.floweringDays,
      harvestStartBand: tomatoProfile.harvestStartDays,
      endBand: tomatoProfile.endWindowDays,
      expectedFloweringDay: tomatoProfile.floweringDays.mid,
      expectedHarvestStartDay: tomatoProfile.harvestStartDays.mid,
      expectedEndDay: tomatoProfile.endWindowDays.mid,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: stage.stageProgressPct ?? 0,
      windowsNow:
          stage.windowsNow.whereType<SeedWindowKey>().toList(growable: false),
      productiveState: _productiveStateFromKey(stage.productiveState),
      expectedPlantHeightTodayM: _expectedHeightForStage(
        profile: tomatoProfile,
        stage: tomatoStage,
        stageProgress: stage.stageProgressPct ?? 0.5,
      ),
      stageLabelEs: stage.stageLabelEs,
      productiveStateLabelEs: stage.productiveStateLabelEs ?? '',
      heroAsset: stage.heroAsset,
      helperCaption: stage.helperCaption,
    );

    final out = TomatoAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: tomatoUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Tomate',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedTomatoStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in TomatoStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedTomatoStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedTomatoStage(
          stage: TomatoStageKey.germinacion, usedFallback: false);
    }
    if (normalized.contains('establec') || normalized.contains('establis')) {
      return const _ResolvedTomatoStage(
          stage: TomatoStageKey.establecimiento, usedFallback: false);
    }
    if (normalized.contains('veget') || normalized.contains('veg')) {
      return const _ResolvedTomatoStage(
          stage: TomatoStageKey.vegetativo, usedFallback: false);
    }
    if (normalized.contains('flor') || normalized.contains('flower')) {
      return const _ResolvedTomatoStage(
          stage: TomatoStageKey.floracion, usedFallback: false);
    }
    if (normalized.contains('cuaj') || normalized.contains('fruit set') ||
        normalized.contains('amarre')) {
      return const _ResolvedTomatoStage(
          stage: TomatoStageKey.cuajado, usedFallback: false);
    }
    if (normalized.contains('llen') || normalized.contains('fill')) {
      return const _ResolvedTomatoStage(
          stage: TomatoStageKey.llenado, usedFallback: false);
    }
    if (normalized.contains('cosech') || normalized.contains('harvest')) {
      return const _ResolvedTomatoStage(
          stage: TomatoStageKey.cosechaProgresiva, usedFallback: false);
    }
    if (normalized.contains('fin') || normalized.contains('cierr') ||
        normalized.contains('end')) {
      return const _ResolvedTomatoStage(
          stage: TomatoStageKey.finCiclo, usedFallback: false);
    }

    return const _ResolvedTomatoStage(
      stage: TomatoStageKey.vegetativo,
      usedFallback: true,
    );
  }

  TomatoStageKey? _productiveStateFromKey(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.trim().toLowerCase();
    for (final stage in TomatoStageKey.values) {
      if (stage.name.toLowerCase() == normalized) return stage;
    }
    return null;
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
    required TomatoProfile profile,
    required TomatoStageKey stage,
    double stageProgress = 0.5,
  }) {
    final (double startPct, double endPct) = switch (stage) {
      TomatoStageKey.germinacion => (0.00, 0.02),
      TomatoStageKey.establecimiento => (0.02, 0.15),
      TomatoStageKey.vegetativo => (0.15, 0.55),
      TomatoStageKey.floracion => (0.55, 0.75),
      TomatoStageKey.cuajado => (0.75, 0.88),
      TomatoStageKey.llenado => (0.88, 0.97),
      TomatoStageKey.cosechaProgresiva => (0.97, 1.00),
      TomatoStageKey.finCiclo => (1.00, 1.00),
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
      final canonical = resolveCanonicalTomatoProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }

    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalTomatoProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }

    return null;
  }
}

class _ResolvedTomatoStage {
  final TomatoStageKey stage;
  final bool usedFallback;

  const _ResolvedTomatoStage({
    required this.stage,
    required this.usedFallback,
  });
}
