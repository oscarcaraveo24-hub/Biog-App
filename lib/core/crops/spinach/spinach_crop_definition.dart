import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/spinach_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/spinach/spinach_crop_engine_adapter.dart';
import 'package:bio_g/crops/spinach/spinach_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/spinach_models.dart';
import 'package:bio_g/widgets/seeds/spinach_profiles.dart';

/// Definicion principal de espinaca dentro del registro de cultivos.
///
/// Espinaca es el cultivo madre `CropKey.spinach`; SP-GEN..SP-05 son
/// perfiles internos y las variedades comerciales son aliases.
class SpinachCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.spinach;

  @override
  CropCategory get category => CropCategory.vegetable;

  @override
  String get displayName => 'Espinaca';

  @override
  CropEngine get engine => const SpinachCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonical = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonical != null) {
      final resolved = spinachProfiles[canonical];
      if (resolved != null) return resolved;
    }

    if (spinachProfiles.containsKey(kSpGen)) return spinachProfiles[kSpGen];
    if (spinachProfiles.isNotEmpty) return spinachProfiles.values.first;
    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final stageResolution = _resolveStage(stage.stageKey);
    return spinachUniversalV1.byStage[stageResolution.stage];
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
    final spinachStage = stageResolution.stage;
    final spinachProfile = profile as SpinachProfile;

    final daySince = stage.daySinceSowing ?? 0;
    final nurseryOffset = spinachProfile.defaultEstablishmentMode ==
            SpinachEstablishmentMode.transplant
        ? spinachProfile.nurseryAgeDays
        : 0;
    final effectiveDay = daySince + nurseryOffset;

    final effectiveHarvestStart = spinachProfile.e5EndDay + 1;
    final effectiveHarvestEnd = spinachProfile.e6EndDay;
    final harvestStart = math.max(1, effectiveHarvestStart - nurseryOffset);
    final harvestEnd =
        math.max(harvestStart, effectiveHarvestEnd - nurseryOffset);
    final qualityDeclineStart =
        math.max(harvestEnd + 1, spinachProfile.e6EndDay + 1 - nurseryOffset);
    final qualityDeclineEnd =
        math.max(qualityDeclineStart, spinachProfile.e7EndDay - nurseryOffset);
    final daysToHarvestMin =
        _clampWindowDay(effectiveHarvestStart - effectiveDay);
    final daysToHarvestMax =
        _clampWindowDay(effectiveHarvestEnd - effectiveDay);

    final seedStage = SpinachStageResult(
      profile: spinachProfile,
      stage: spinachStage,
      daySinceAnchor: daySince,
      establishmentMode: spinachProfile.defaultEstablishmentMode,
      harvestBand: RangeInt(harvestStart, harvestEnd),
      qualityDeclineBand: RangeInt(qualityDeclineStart, qualityDeclineEnd),
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

    final out = SpinachAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: spinachUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Espinaca',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedSpinachStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in SpinachStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedSpinachStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedSpinachStage(
        stage: SpinachStageKey.germinacion,
        usedFallback: false,
      );
    }
    if (normalized.contains('establec') ||
        normalized.contains('emerg') ||
        normalized.contains('transplant')) {
      return const _ResolvedSpinachStage(
        stage: SpinachStageKey.establecimiento,
        usedFallback: false,
      );
    }
    if (normalized.contains('temprano') || normalized.contains('early')) {
      return const _ResolvedSpinachStage(
        stage: SpinachStageKey.vegetativoTemprano,
        usedFallback: false,
      );
    }
    if (normalized.contains('expansion') ||
        normalized.contains('foliar') ||
        normalized.contains('leaf_expansion')) {
      return const _ResolvedSpinachStage(
        stage: SpinachStageKey.expansionFoliar,
        usedFallback: false,
      );
    }
    if (normalized.contains('madurez') ||
        normalized.contains('maturity') ||
        normalized.contains('comercial')) {
      return const _ResolvedSpinachStage(
        stage: SpinachStageKey.madurezComercial,
        usedFallback: false,
      );
    }
    if (normalized.contains('cosech') ||
        normalized.contains('ventana') ||
        normalized.contains('harvest')) {
      return const _ResolvedSpinachStage(
        stage: SpinachStageKey.ventanaCosecha,
        usedFallback: false,
      );
    }
    if (normalized.contains('perdida') ||
        normalized.contains('decline') ||
        normalized.contains('sobremadur')) {
      return const _ResolvedSpinachStage(
        stage: SpinachStageKey.perdidaCalidad,
        usedFallback: false,
      );
    }
    if (normalized.contains('espig') ||
        normalized.contains('bolting') ||
        normalized.contains('senesc')) {
      return const _ResolvedSpinachStage(
        stage: SpinachStageKey.espigadoSenescencia,
        usedFallback: false,
      );
    }
    if (normalized.contains('veget') || normalized.contains('veg')) {
      return const _ResolvedSpinachStage(
        stage: SpinachStageKey.vegetativoTemprano,
        usedFallback: false,
      );
    }

    return const _ResolvedSpinachStage(
      stage: SpinachStageKey.vegetativoTemprano,
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
      final canonical = resolveCanonicalSpinachProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }
    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalSpinachProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }
    return null;
  }
}

class _ResolvedSpinachStage {
  final SpinachStageKey stage;
  final bool usedFallback;

  const _ResolvedSpinachStage({
    required this.stage,
    required this.usedFallback,
  });
}
