import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/squash_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/squash/squash_crop_engine_adapter.dart';
import 'package:bio_g/crops/squash/squash_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/squash_models.dart';
import 'package:bio_g/widgets/seeds/squash_profiles.dart';

/// Definición principal de calabaza dentro del registro de cultivos.
///
/// Calabaza es el cultivo madre (CropKey.squash) y reúne CA-GEN..CA-07
/// como perfiles internos. NO se crea CropKey.pumpkin separado.
class SquashCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.squash;

  @override
  CropCategory get category => CropCategory.vegetable;

  @override
  String get displayName => 'Calabaza';

  @override
  CropEngine get engine => const SquashCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonical = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonical != null) {
      final resolved = squashProfiles[canonical];
      if (resolved != null) return resolved;
    }

    if (squashProfiles.containsKey(kCaGen)) return squashProfiles[kCaGen];
    if (squashProfiles.isNotEmpty) return squashProfiles.values.first;
    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final stageResolution = _resolveStage(stage.stageKey);
    return squashUniversalV1.byStage[stageResolution.stage];
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
    final squashStage = stageResolution.stage;
    final squashProfile = profile as SquashProfile;

    final seedStage = SquashStageResult(
      profile: squashProfile,
      stage: squashStage,
      daySinceAnchor: stage.daySinceSowing ?? 0,
      establishmentMode: squashProfile.defaultEstablishmentMode,
      floweringBand: squashProfile.floweringDays,
      harvestStartBand: squashProfile.harvestStartDays,
      endBand: squashProfile.endWindowDays,
      expectedFloweringDay: squashProfile.floweringDays.mid,
      expectedHarvestStartDay: squashProfile.harvestStartDays.mid,
      expectedEndDay: squashProfile.endWindowDays.mid,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      stageProgressPct: stage.stageProgressPct ?? 0,
      windowsNow:
          stage.windowsNow.whereType<SeedWindowKey>().toList(growable: false),
      productiveState: _productiveStateFromKey(stage.productiveState),
      expectedPlantHeightTodayM: _expectedHeightForStage(
        profile: squashProfile,
        stage: squashStage,
        stageProgress: stage.stageProgressPct ?? 0.5,
      ),
      stageLabelEs: stage.stageLabelEs,
      productiveStateLabelEs: stage.productiveStateLabelEs ?? '',
      heroAsset: stage.heroAsset,
      helperCaption: stage.helperCaption,
    );

    final out = SquashAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: squashUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Calabaza',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedSquashStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in SquashStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedSquashStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedSquashStage(
        stage: SquashStageKey.germinacion,
        usedFallback: false,
      );
    }
    if (normalized.contains('establec') ||
        normalized.contains('emerg') ||
        normalized.contains('transplant')) {
      return const _ResolvedSquashStage(
        stage: SquashStageKey.establecimiento,
        usedFallback: false,
      );
    }
    if (normalized.contains('veget') || normalized.contains('veg')) {
      return const _ResolvedSquashStage(
        stage: SquashStageKey.vegetativo,
        usedFallback: false,
      );
    }
    if (normalized.contains('flor') || normalized.contains('flower')) {
      return const _ResolvedSquashStage(
        stage: SquashStageKey.floracion,
        usedFallback: false,
      );
    }
    if (normalized.contains('cuaj') ||
        normalized.contains('amarre') ||
        normalized.contains('fruitset') ||
        normalized.contains('fruit set') ||
        normalized.contains('poliniz')) {
      return const _ResolvedSquashStage(
        stage: SquashStageKey.cuajado,
        usedFallback: false,
      );
    }
    if (normalized.contains('llen') || normalized.contains('fill')) {
      return const _ResolvedSquashStage(
        stage: SquashStageKey.llenado,
        usedFallback: false,
      );
    }
    if (normalized.contains('cosech') ||
        normalized.contains('harvest') ||
        normalized.contains('progresiv')) {
      return const _ResolvedSquashStage(
        stage: SquashStageKey.cosechaProgresiva,
        usedFallback: false,
      );
    }
    if (normalized.contains('fin') ||
        normalized.contains('senesc') ||
        normalized.contains('cierr') ||
        normalized.contains('end')) {
      return const _ResolvedSquashStage(
        stage: SquashStageKey.finCiclo,
        usedFallback: false,
      );
    }

    return const _ResolvedSquashStage(
      stage: SquashStageKey.vegetativo,
      usedFallback: true,
    );
  }

  SquashStageKey? _productiveStateFromKey(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.trim().toLowerCase();
    for (final stage in SquashStageKey.values) {
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
    required SquashProfile profile,
    required SquashStageKey stage,
    double stageProgress = 0.5,
  }) {
    final (double startPct, double endPct) = switch (stage) {
      SquashStageKey.germinacion => (0.00, 0.05),
      SquashStageKey.establecimiento => (0.05, 0.25),
      SquashStageKey.vegetativo => (0.25, 0.70),
      SquashStageKey.floracion => (0.70, 0.85),
      SquashStageKey.cuajado => (0.85, 0.93),
      SquashStageKey.llenado => (0.93, 0.98),
      SquashStageKey.cosechaProgresiva => (0.98, 1.00),
      SquashStageKey.finCiclo => (1.00, 1.00),
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
      final canonical = resolveCanonicalSquashProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }
    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalSquashProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }
    return null;
  }
}

class _ResolvedSquashStage {
  final SquashStageKey stage;
  final bool usedFallback;

  const _ResolvedSquashStage({
    required this.stage,
    required this.usedFallback,
  });
}
