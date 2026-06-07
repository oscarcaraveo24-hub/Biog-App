import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/garlic_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/garlic/garlic_crop_engine_adapter.dart';
import 'package:bio_g/crops/garlic/garlic_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/garlic_models.dart';
import 'package:bio_g/widgets/seeds/garlic_profiles.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

/// Definicion principal de ajo dentro del registro de cultivos.
///
/// Ajo es cultivo madre independiente `CropKey.garlic`; AG-GEN..AG-05 son
/// perfiles internos y las variedades comerciales son aliases. La
/// vernalizacion y el curado son factores fisiologicos criticos y no se
/// corrigen con NPK.
class GarlicCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.garlic;

  @override
  CropCategory get category => CropCategory.vegetable;

  @override
  String get displayName => 'Ajo';

  @override
  CropEngine get engine => const GarlicCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonical = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonical != null) {
      final resolved = garlicProfiles[canonical];
      if (resolved != null) return resolved;
    }

    if (garlicProfiles.containsKey(kAgGen)) return garlicProfiles[kAgGen];
    if (garlicProfiles.isNotEmpty) return garlicProfiles.values.first;
    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final stageResolution = _resolveStage(stage.stageKey);
    return garlicUniversalV1.byStage[stageResolution.stage];
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
    final garlicStage = stageResolution.stage;
    final garlicProfile = profile as GarlicProfile;

    final daySince = stage.daySinceSowing ?? 0;
    final sproutOffset =
        garlicProfile.defaultEstablishmentMode == GarlicEstablishmentMode.sproutedClove
            ? 7
            : 0;
    final effectiveDay = daySince + sproutOffset;

    final effectiveHarvestStart = garlicProfile.e7EndDay + 1;
    final effectiveHarvestEnd = garlicProfile.e8EndDay;
    final harvestStart = math.max(1, effectiveHarvestStart - sproutOffset);
    final harvestEnd =
        math.max(harvestStart, effectiveHarvestEnd - sproutOffset);
    final curingStart = math.max(harvestEnd + 1, garlicProfile.e8EndDay + 1);
    final curingEnd = math.max(curingStart, garlicProfile.e9EndDay);
    final daysToHarvestMin =
        _clampWindowDay(effectiveHarvestStart - effectiveDay);
    final daysToHarvestMax =
        _clampWindowDay(effectiveHarvestEnd - effectiveDay);

    final seedStage = GarlicStageResult(
      profile: garlicProfile,
      stage: garlicStage,
      daySinceAnchor: daySince,
      establishmentMode: garlicProfile.defaultEstablishmentMode,
      harvestBand: RangeInt(harvestStart, harvestEnd),
      curingBand: RangeInt(curingStart, curingEnd),
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

    final out = GarlicAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: garlicUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Ajo',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedGarlicStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in GarlicStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedGarlicStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('plant') || normalized.contains('clove') ||
        normalized.contains('diente')) {
      return const _ResolvedGarlicStage(
        stage: GarlicStageKey.clovePlanting,
        usedFallback: false,
      );
    }
    if (normalized.contains('emerg') || normalized.contains('establec')) {
      return const _ResolvedGarlicStage(
        stage: GarlicStageKey.emergenceEstablishment,
        usedFallback: false,
      );
    }
    if (normalized.contains('vernal') ||
        normalized.contains('frio') ||
        normalized.contains('cold')) {
      return const _ResolvedGarlicStage(
        stage: GarlicStageKey.coldInductionVernalization,
        usedFallback: false,
      );
    }
    if (normalized.contains('diferenci') ||
        normalized.contains('init') ||
        normalized.contains('bulb_diff')) {
      return const _ResolvedGarlicStage(
        stage: GarlicStageKey.bulbDifferentiation,
        usedFallback: false,
      );
    }
    if (normalized.contains('llenado') ||
        normalized.contains('bulb_fill') ||
        normalized.contains('fill')) {
      return const _ResolvedGarlicStage(
        stage: GarlicStageKey.bulbFilling,
        usedFallback: false,
      );
    }
    if (normalized.contains('madur') || normalized.contains('maturity')) {
      return const _ResolvedGarlicStage(
        stage: GarlicStageKey.bulbMaturation,
        usedFallback: false,
      );
    }
    if (normalized.contains('cosech') || normalized.contains('harvest')) {
      return const _ResolvedGarlicStage(
        stage: GarlicStageKey.harvest,
        usedFallback: false,
      );
    }
    if (normalized.contains('curado') ||
        normalized.contains('curing') ||
        normalized.contains('reposo')) {
      return const _ResolvedGarlicStage(
        stage: GarlicStageKey.curingRest,
        usedFallback: false,
      );
    }
    if (normalized.contains('escapo') ||
        normalized.contains('canuto') ||
        normalized.contains('scape') ||
        normalized.contains('broom') ||
        normalized.contains('escobete')) {
      return const _ResolvedGarlicStage(
        stage: GarlicStageKey.scapeBrooming,
        usedFallback: false,
      );
    }
    if (normalized.contains('veget') || normalized.contains('foliar')) {
      return const _ResolvedGarlicStage(
        stage: GarlicStageKey.vegetativeLeafDevelopment,
        usedFallback: false,
      );
    }

    return const _ResolvedGarlicStage(
      stage: GarlicStageKey.vegetativeLeafDevelopment,
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
      final canonical = resolveCanonicalGarlicProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }
    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalGarlicProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }
    return null;
  }
}

class _ResolvedGarlicStage {
  final GarlicStageKey stage;
  final bool usedFallback;

  const _ResolvedGarlicStage({
    required this.stage,
    required this.usedFallback,
  });
}
