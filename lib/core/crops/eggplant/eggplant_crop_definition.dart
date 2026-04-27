import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/eggplant_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/eggplant/eggplant_crop_engine_adapter.dart';
import 'package:bio_g/crops/eggplant/eggplant_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/eggplant_models.dart';
import 'package:bio_g/widgets/seeds/eggplant_profiles.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class EggplantCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.eggplant;

  @override
  CropCategory get category => CropCategory.vegetable;

  @override
  String get displayName => 'Berenjena';

  @override
  CropEngine get engine => const EggplantCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonicalProfileId = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonicalProfileId != null) {
      final resolved = eggplantProfiles[canonicalProfileId];
      if (resolved != null) return resolved;
    }

    if (eggplantProfiles.containsKey(kBeGen)) return eggplantProfiles[kBeGen];
    if (eggplantProfiles.isNotEmpty) return eggplantProfiles.values.first;
    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final stageResolution = _resolveStage(stage.stageKey);
    return eggplantUniversalV1.byStage[stageResolution.stage];
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
    final eggplantStage = stageResolution.stage;
    final eggplantProfile = profile as EggplantProfile;

    final seedStage = EggplantStageResult(
      profile: eggplantProfile,
      stage: eggplantStage,
      daySinceAnchor: stage.daySinceSowing ?? 0,
      establishmentMode: eggplantProfile.defaultEstablishmentMode,
      floweringBand: eggplantProfile.floweringDays,
      harvestStartBand: eggplantProfile.harvestStartDays,
      endBand: eggplantProfile.endWindowDays,
      expectedFloweringDay: eggplantProfile.floweringDays.mid,
      expectedHarvestStartDay: eggplantProfile.harvestStartDays.mid,
      expectedEndDay: eggplantProfile.endWindowDays.mid,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: stage.stageProgressPct ?? 0,
      windowsNow:
          stage.windowsNow.whereType<SeedWindowKey>().toList(growable: false),
      productiveState: _productiveStateFromKey(stage.productiveState),
      expectedPlantHeightTodayM: _expectedHeightForStage(
        profile: eggplantProfile,
        stage: eggplantStage,
        stageProgress: stage.stageProgressPct ?? 0.5,
      ),
      stageLabelEs: stage.stageLabelEs,
      productiveStateLabelEs: stage.productiveStateLabelEs ?? '',
      heroAsset: stage.heroAsset,
      helperCaption: stage.helperCaption,
    );

    final out = EggplantAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: eggplantUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Berenjena',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedEggplantStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in EggplantStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedEggplantStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedEggplantStage(
        stage: EggplantStageKey.germinacion,
        usedFallback: false,
      );
    }
    if (normalized.contains('establec') ||
        normalized.contains('emerg') ||
        normalized.contains('transplant')) {
      return const _ResolvedEggplantStage(
        stage: EggplantStageKey.establecimiento,
        usedFallback: false,
      );
    }
    if (normalized.contains('veget') || normalized.contains('veg')) {
      return const _ResolvedEggplantStage(
        stage: EggplantStageKey.vegetativo,
        usedFallback: false,
      );
    }
    if (normalized.contains('flor') || normalized.contains('flower')) {
      return const _ResolvedEggplantStage(
        stage: EggplantStageKey.floracion,
        usedFallback: false,
      );
    }
    if (normalized.contains('cuaj') ||
        normalized.contains('amarre') ||
        normalized.contains('fruit set') ||
        normalized.contains('fruitset')) {
      return const _ResolvedEggplantStage(
        stage: EggplantStageKey.cuajado,
        usedFallback: false,
      );
    }
    if (normalized.contains('llen') || normalized.contains('fill')) {
      return const _ResolvedEggplantStage(
        stage: EggplantStageKey.llenado,
        usedFallback: false,
      );
    }
    if (normalized.contains('cosech') ||
        normalized.contains('harvest') ||
        normalized.contains('progresiv')) {
      return const _ResolvedEggplantStage(
        stage: EggplantStageKey.cosechaProgresiva,
        usedFallback: false,
      );
    }
    if (normalized.contains('fin') ||
        normalized.contains('senesc') ||
        normalized.contains('cierr') ||
        normalized.contains('end')) {
      return const _ResolvedEggplantStage(
        stage: EggplantStageKey.finCiclo,
        usedFallback: false,
      );
    }

    return const _ResolvedEggplantStage(
      stage: EggplantStageKey.vegetativo,
      usedFallback: true,
    );
  }

  EggplantStageKey? _productiveStateFromKey(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.trim().toLowerCase();
    for (final stage in EggplantStageKey.values) {
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
    required EggplantProfile profile,
    required EggplantStageKey stage,
    double stageProgress = 0.5,
  }) {
    final (double startPct, double endPct) = switch (stage) {
      EggplantStageKey.germinacion => (0.00, 0.03),
      EggplantStageKey.establecimiento => (0.03, 0.22),
      EggplantStageKey.vegetativo => (0.22, 0.68),
      EggplantStageKey.floracion => (0.68, 0.82),
      EggplantStageKey.cuajado => (0.82, 0.92),
      EggplantStageKey.llenado => (0.92, 0.98),
      EggplantStageKey.cosechaProgresiva => (0.98, 1.00),
      EggplantStageKey.finCiclo => (1.00, 1.00),
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
      final canonical = resolveCanonicalEggplantProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }

    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalEggplantProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }

    return null;
  }
}

class _ResolvedEggplantStage {
  final EggplantStageKey stage;
  final bool usedFallback;

  const _ResolvedEggplantStage({
    required this.stage,
    required this.usedFallback,
  });
}
