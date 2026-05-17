import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/lettuce_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/lettuce/lettuce_crop_engine_adapter.dart';
import 'package:bio_g/crops/lettuce/lettuce_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/lettuce_models.dart';
import 'package:bio_g/widgets/seeds/lettuce_profiles.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

/// Definición principal de lechuga dentro del registro de cultivos.
///
/// Lechuga es el cultivo madre `CropKey.lettuce` y reúne LE-GEN..LE-05
/// como perfiles internos. NO se crean crop_romaine, crop_iceberg ni
/// crop_baby_leaf separados: son perfiles/UX dentro de `crop_lettuce`.
class LettuceCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.lettuce;

  @override
  CropCategory get category => CropCategory.vegetable;

  @override
  String get displayName => 'Lechuga';

  @override
  CropEngine get engine => const LettuceCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonical = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonical != null) {
      final resolved = lettuceProfiles[canonical];
      if (resolved != null) return resolved;
    }

    if (lettuceProfiles.containsKey(kLeGen)) return lettuceProfiles[kLeGen];
    if (lettuceProfiles.isNotEmpty) return lettuceProfiles.values.first;
    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final stageResolution = _resolveStage(stage.stageKey);
    return lettuceUniversalV1.byStage[stageResolution.stage];
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
    final lettuceStage = stageResolution.stage;
    final lettuceProfile = profile as LettuceProfile;

    final daySince = stage.daySinceSowing ?? 0;
    final nurseryOffset = lettuceProfile.defaultEstablishmentMode ==
            LettuceEstablishmentMode.transplant
        ? lettuceProfile.nurseryAgeDays
        : 0;
    final effectiveDay = daySince + nurseryOffset;

    final effectiveHarvestStart = lettuceProfile.e4EndDay + 1;
    final effectiveHarvestEnd = lettuceProfile.e5EndDay;
    final harvestStart = math.max(1, effectiveHarvestStart - nurseryOffset);
    final harvestEnd = math.max(harvestStart, effectiveHarvestEnd - nurseryOffset);
    final overMatureStart =
        math.max(harvestEnd + 1, lettuceProfile.e5EndDay + 1 - nurseryOffset);
    final overMatureEnd = math.max(
      overMatureStart,
      lettuceProfile.e5EndDay + lettuceProfile.overMatureDays - nurseryOffset,
    );
    final daysToHarvestMin =
        _clampWindowDay(effectiveHarvestStart - effectiveDay);
    final daysToHarvestMax =
        _clampWindowDay(effectiveHarvestEnd - effectiveDay);

    final seedStage = LettuceStageResult(
      profile: lettuceProfile,
      stage: lettuceStage,
      daySinceAnchor: daySince,
      establishmentMode: lettuceProfile.defaultEstablishmentMode,
      harvestBand: RangeInt(harvestStart, harvestEnd),
      overMatureBand: RangeInt(overMatureStart, overMatureEnd),
      expectedHarvestStartDay: harvestStart,
      expectedEndDay: harvestEnd,
      expectedDaysToEnd: stage.expectedDaysToEnd,
      daysToHarvestMin: daysToHarvestMin,
      daysToHarvestMax: daysToHarvestMax,
      stageProgressPct: stage.stageProgressPct ?? 0,
      windowsNow:
          stage.windowsNow.whereType<SeedWindowKey>().toList(growable: false),
      stageLabelEs: stage.stageLabelEs,
      heroAsset: stage.heroAsset,
      helperCaption: stage.helperCaption,
    );

    final out = LettuceAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: lettuceUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Lechuga',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedLettuceStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in LettuceStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedLettuceStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedLettuceStage(
        stage: LettuceStageKey.germinacion,
        usedFallback: false,
      );
    }
    if (normalized.contains('establec') ||
        normalized.contains('emerg') ||
        normalized.contains('transplant')) {
      return const _ResolvedLettuceStage(
        stage: LettuceStageKey.establecimiento,
        usedFallback: false,
      );
    }
    if (normalized.contains('cabeza') ||
        normalized.contains('compact') ||
        normalized.contains('head')) {
      return const _ResolvedLettuceStage(
        stage: LettuceStageKey.formacionCabeza,
        usedFallback: false,
      );
    }
    if (normalized.contains('cosech') ||
        normalized.contains('ventana') ||
        normalized.contains('harvest')) {
      return const _ResolvedLettuceStage(
        stage: LettuceStageKey.ventanaCosecha,
        usedFallback: false,
      );
    }
    if (normalized.contains('sobremadur') ||
        normalized.contains('senesc') ||
        normalized.contains('cierr') ||
        normalized.contains('end')) {
      return const _ResolvedLettuceStage(
        stage: LettuceStageKey.sobremadurez,
        usedFallback: false,
      );
    }
    if (normalized.contains('veget') || normalized.contains('veg')) {
      return const _ResolvedLettuceStage(
        stage: LettuceStageKey.desarrolloVegetativo,
        usedFallback: false,
      );
    }

    return const _ResolvedLettuceStage(
      stage: LettuceStageKey.desarrolloVegetativo,
      usedFallback: true,
    );
  }

  int _clampWindowDay(int value) {
    if (value < 0) return 0;
    if (value > 999999) return 999999;
    return value;
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

  String? _resolveCanonicalProfileId({
    String? profileId,
    String? varietyAlias,
  }) {
    if (profileId != null && profileId.trim().isNotEmpty) {
      final canonical = resolveCanonicalLettuceProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }
    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalLettuceProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }
    return null;
  }
}

class _ResolvedLettuceStage {
  final LettuceStageKey stage;
  final bool usedFallback;

  const _ResolvedLettuceStage({
    required this.stage,
    required this.usedFallback,
  });
}
