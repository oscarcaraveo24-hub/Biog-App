import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/chili_agro_score_engine.dart';
import 'package:bio_g/core/crops/chili/chili_crop_engine_adapter.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/crops/chili/chili_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/chili_models.dart';
import 'package:bio_g/widgets/seeds/chili_profiles.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class ChiliCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.chili;

  @override
  CropCategory get category => CropCategory.vegetable;

  @override
  String get displayName => 'Chile';

  @override
  CropEngine get engine => const ChiliCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonicalProfileId = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonicalProfileId != null) {
      final resolved = chiliProfiles[canonicalProfileId];
      if (resolved != null) return resolved;
    }

    if (chiliProfiles.containsKey(kChGen)) return chiliProfiles[kChGen];
    if (chiliProfiles.isNotEmpty) return chiliProfiles.values.first;
    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final stageResolution = _resolveStage(stage.stageKey);
    return chiliUniversalV1.byStage[stageResolution.stage];
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
    final chiliStage = stageResolution.stage;
    final chiliProfile = profile as ChiliProfile;

    final seedStage = ChiliStageResult(
      profile: chiliProfile,
      stage: chiliStage,
      daySinceAnchor: stage.daySinceSowing ?? 0,
      establishmentMode: chiliProfile.defaultEstablishmentMode,
      floweringBand: chiliProfile.floweringDays,
      harvestStartBand: chiliProfile.harvestStartDays,
      endBand: chiliProfile.endWindowDays,
      expectedFloweringDay: chiliProfile.floweringDays.mid,
      expectedHarvestStartDay: chiliProfile.harvestStartDays.mid,
      expectedEndDay: chiliProfile.endWindowDays.mid,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: stage.stageProgressPct ?? 0,
      windowsNow:
          stage.windowsNow.whereType<SeedWindowKey>().toList(growable: false),
      productiveState: _productiveStateFromKey(stage.productiveState),
      expectedPlantHeightTodayM: _expectedHeightForStage(
        profile: chiliProfile,
        stage: chiliStage,
        stageProgress: stage.stageProgressPct ?? 0.5,
      ),
      stageLabelEs: stage.stageLabelEs,
      productiveStateLabelEs: stage.productiveStateLabelEs ?? '',
      heroAsset: stage.heroAsset,
      helperCaption: stage.helperCaption,
    );

    final out = ChiliAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: chiliUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Chile',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedChiliStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in ChiliStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedChiliStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedChiliStage(
        stage: ChiliStageKey.germinacion,
        usedFallback: false,
      );
    }
    if (normalized.contains('establec') ||
        normalized.contains('emerg') ||
        normalized.contains('transplant')) {
      return const _ResolvedChiliStage(
        stage: ChiliStageKey.establecimiento,
        usedFallback: false,
      );
    }
    if (normalized.contains('veget') || normalized.contains('veg')) {
      return const _ResolvedChiliStage(
        stage: ChiliStageKey.vegetativo,
        usedFallback: false,
      );
    }
    if (normalized.contains('flor') || normalized.contains('flower')) {
      return const _ResolvedChiliStage(
        stage: ChiliStageKey.floracion,
        usedFallback: false,
      );
    }
    if (normalized.contains('cuaj') ||
        normalized.contains('amarre') ||
        normalized.contains('fruit set') ||
        normalized.contains('fruitset')) {
      return const _ResolvedChiliStage(
        stage: ChiliStageKey.cuajado,
        usedFallback: false,
      );
    }
    if (normalized.contains('llen') || normalized.contains('fill')) {
      return const _ResolvedChiliStage(
        stage: ChiliStageKey.llenado,
        usedFallback: false,
      );
    }
    if (normalized.contains('cosech') ||
        normalized.contains('harvest') ||
        normalized.contains('progresiv')) {
      return const _ResolvedChiliStage(
        stage: ChiliStageKey.cosechaProgresiva,
        usedFallback: false,
      );
    }
    if (normalized.contains('fin') ||
        normalized.contains('senesc') ||
        normalized.contains('cierr') ||
        normalized.contains('end')) {
      return const _ResolvedChiliStage(
        stage: ChiliStageKey.finCiclo,
        usedFallback: false,
      );
    }

    return const _ResolvedChiliStage(
      stage: ChiliStageKey.vegetativo,
      usedFallback: true,
    );
  }

  ChiliStageKey? _productiveStateFromKey(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.trim().toLowerCase();
    for (final stage in ChiliStageKey.values) {
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
    required ChiliProfile profile,
    required ChiliStageKey stage,
    double stageProgress = 0.5,
  }) {
    final (double startPct, double endPct) = switch (stage) {
      ChiliStageKey.germinacion => (0.00, 0.03),
      ChiliStageKey.establecimiento => (0.03, 0.20),
      ChiliStageKey.vegetativo => (0.20, 0.68),
      ChiliStageKey.floracion => (0.68, 0.82),
      ChiliStageKey.cuajado => (0.82, 0.92),
      ChiliStageKey.llenado => (0.92, 0.98),
      ChiliStageKey.cosechaProgresiva => (0.98, 1.00),
      ChiliStageKey.finCiclo => (1.00, 1.00),
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
      final canonical = resolveCanonicalChiliProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }

    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalChiliProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }

    return null;
  }
}

class _ResolvedChiliStage {
  final ChiliStageKey stage;
  final bool usedFallback;

  const _ResolvedChiliStage({
    required this.stage,
    required this.usedFallback,
  });
}
