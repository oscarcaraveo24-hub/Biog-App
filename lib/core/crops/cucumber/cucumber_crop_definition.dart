import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/cucumber_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/cucumber/cucumber_crop_engine_adapter.dart';
import 'package:bio_g/crops/cucumber/cucumber_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/cucumber_models.dart';
import 'package:bio_g/widgets/seeds/cucumber_profiles.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class CucumberCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.cucumber;

  @override
  CropCategory get category => CropCategory.vegetable;

  @override
  String get displayName => 'Pepino';

  @override
  CropEngine get engine => const CucumberCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonicalProfileId = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonicalProfileId != null) {
      final resolved = cucumberProfiles[canonicalProfileId];
      if (resolved != null) return resolved;
    }

    if (cucumberProfiles.containsKey(kPeGen)) {
      return cucumberProfiles[kPeGen];
    }

    if (cucumberProfiles.isNotEmpty) {
      return cucumberProfiles.values.first;
    }

    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final stageResolution = _resolveStage(stage.stageKey);
    return cucumberUniversalV1.byStage[stageResolution.stage];
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
    final cucumberStage = stageResolution.stage;
    final cucumberProfile = profile as CucumberProfile;

    final seedStage = CucumberStageResult(
      profile: cucumberProfile,
      stage: cucumberStage,
      daySinceAnchor: stage.daySinceSowing ?? 0,
      establishmentMode: cucumberProfile.defaultEstablishmentMode,
      floweringBand: cucumberProfile.floweringDays,
      harvestStartBand: cucumberProfile.harvestStartDays,
      endBand: cucumberProfile.endWindowDays,
      expectedFloweringDay: cucumberProfile.floweringDays.mid,
      expectedHarvestStartDay: cucumberProfile.harvestStartDays.mid,
      expectedEndDay: cucumberProfile.endWindowDays.mid,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: stage.stageProgressPct ?? 0,
      windowsNow:
          stage.windowsNow.whereType<SeedWindowKey>().toList(growable: false),
      productiveState: _productiveStateFromKey(stage.productiveState),
      expectedPlantHeightTodayM: _expectedHeightForStage(
        profile: cucumberProfile,
        stage: cucumberStage,
        stageProgress: stage.stageProgressPct ?? 0.5,
      ),
      stageLabelEs: stage.stageLabelEs,
      productiveStateLabelEs: stage.productiveStateLabelEs ?? '',
      heroAsset: stage.heroAsset,
      helperCaption: stage.helperCaption,
    );

    final out = CucumberAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: cucumberUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Pepino',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedCucumberStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in CucumberStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedCucumberStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedCucumberStage(
        stage: CucumberStageKey.germinacion,
        usedFallback: false,
      );
    }
    if (normalized.contains('establec') || normalized.contains('transplant')) {
      return const _ResolvedCucumberStage(
        stage: CucumberStageKey.establecimiento,
        usedFallback: false,
      );
    }
    if (normalized.contains('veget') || normalized.contains('veg')) {
      return const _ResolvedCucumberStage(
        stage: CucumberStageKey.vegetativo,
        usedFallback: false,
      );
    }
    if (normalized.contains('flor') || normalized.contains('flower')) {
      return const _ResolvedCucumberStage(
        stage: CucumberStageKey.floracion,
        usedFallback: false,
      );
    }
    if (normalized.contains('cuaj') ||
        normalized.contains('fruit set') ||
        normalized.contains('amarre')) {
      return const _ResolvedCucumberStage(
        stage: CucumberStageKey.cuajado,
        usedFallback: false,
      );
    }
    if (normalized.contains('llen') || normalized.contains('fill')) {
      return const _ResolvedCucumberStage(
        stage: CucumberStageKey.llenado,
        usedFallback: false,
      );
    }
    if (normalized.contains('cosech') ||
        normalized.contains('harvest') ||
        normalized.contains('progresiv')) {
      return const _ResolvedCucumberStage(
        stage: CucumberStageKey.cosechaProgresiva,
        usedFallback: false,
      );
    }
    if (normalized.contains('fin') ||
        normalized.contains('cierr') ||
        normalized.contains('end')) {
      return const _ResolvedCucumberStage(
        stage: CucumberStageKey.finCiclo,
        usedFallback: false,
      );
    }

    return const _ResolvedCucumberStage(
      stage: CucumberStageKey.vegetativo,
      usedFallback: true,
    );
  }

  CucumberStageKey? _productiveStateFromKey(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.trim().toLowerCase();
    for (final stage in CucumberStageKey.values) {
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
    required CucumberProfile profile,
    required CucumberStageKey stage,
    double stageProgress = 0.5,
  }) {
    final (double startPct, double endPct) = switch (stage) {
      CucumberStageKey.germinacion => (0.00, 0.03),
      CucumberStageKey.establecimiento => (0.03, 0.18),
      CucumberStageKey.vegetativo => (0.18, 0.60),
      CucumberStageKey.floracion => (0.60, 0.78),
      CucumberStageKey.cuajado => (0.78, 0.90),
      CucumberStageKey.llenado => (0.90, 0.97),
      CucumberStageKey.cosechaProgresiva => (0.97, 1.00),
      CucumberStageKey.finCiclo => (1.00, 1.00),
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
      final canonical = resolveCanonicalCucumberProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }

    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalCucumberProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }

    return null;
  }
}

class _ResolvedCucumberStage {
  final CucumberStageKey stage;
  final bool usedFallback;

  const _ResolvedCucumberStage({
    required this.stage,
    required this.usedFallback,
  });
}
