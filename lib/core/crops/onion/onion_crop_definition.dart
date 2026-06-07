import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/onion_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/onion/onion_crop_engine_adapter.dart';
import 'package:bio_g/crops/onion/onion_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/onion_models.dart';
import 'package:bio_g/widgets/seeds/onion_profiles.dart';

/// Definicion principal de cebolla dentro del registro de cultivos.
///
/// Cebolla es el cultivo madre `CropKey.onion`; ON-GEN..ON-05 son
/// perfiles internos y las variedades comerciales son aliases. El organo
/// objetivo es el bulbo y la floracion/espigado se modela como evento de
/// perdida de calidad, no como etapa productiva.
class OnionCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.onion;

  @override
  CropCategory get category => CropCategory.vegetable;

  @override
  String get displayName => 'Cebolla';

  @override
  CropEngine get engine => const OnionCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final canonical = _resolveCanonicalProfileId(
      profileId: profileId,
      varietyAlias: varietyAlias,
    );

    if (canonical != null) {
      final resolved = onionProfiles[canonical];
      if (resolved != null) return resolved;
    }

    if (onionProfiles.containsKey(kOnGen)) return onionProfiles[kOnGen];
    if (onionProfiles.isNotEmpty) return onionProfiles.values.first;
    return null;
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    final stageResolution = _resolveStage(stage.stageKey);
    return onionUniversalV1.byStage[stageResolution.stage];
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
    final onionStage = stageResolution.stage;
    final onionProfile = profile as OnionProfile;

    final daySince = stage.daySinceSowing ?? 0;
    final nurseryOffset = (onionProfile.defaultEstablishmentMode ==
                OnionEstablishmentMode.transplant ||
            onionProfile.defaultEstablishmentMode ==
                OnionEstablishmentMode.set)
        ? onionProfile.nurseryAgeDays
        : 0;
    final effectiveDay = daySince + nurseryOffset;

    final effectiveHarvestStart = onionProfile.e7EndDay + 1;
    final effectiveHarvestEnd = onionProfile.e8EndDay;
    final harvestStart = math.max(1, effectiveHarvestStart - nurseryOffset);
    final harvestEnd =
        math.max(harvestStart, effectiveHarvestEnd - nurseryOffset);
    final qualityDeclineStart =
        math.max(harvestEnd + 1, onionProfile.e8EndDay + 1 - nurseryOffset);
    final qualityDeclineEnd = math.max(
      qualityDeclineStart,
      onionProfile.e8EndDay + onionProfile.boltingEventDays - nurseryOffset,
    );
    final daysToHarvestMin =
        _clampWindowDay(effectiveHarvestStart - effectiveDay);
    final daysToHarvestMax =
        _clampWindowDay(effectiveHarvestEnd - effectiveDay);

    final seedStage = OnionStageResult(
      profile: onionProfile,
      stage: onionStage,
      daySinceAnchor: daySince,
      establishmentMode: onionProfile.defaultEstablishmentMode,
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

    final out = OnionAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stage: seedStage,
      u: onionUniversalV1,
      alertsState: alertsState,
      cropLabel: 'Cebolla',
      targetsOverride: targetsOverride,
    );

    return _withStageFallbackDiagnostic(out, stageResolution.usedFallback);
  }

  _ResolvedOnionStage _resolveStage(String rawStage) {
    final normalized = rawStage.trim().toLowerCase();
    for (final stage in OnionStageKey.values) {
      if (stage.name.toLowerCase() == normalized) {
        return _ResolvedOnionStage(stage: stage, usedFallback: false);
      }
    }

    if (normalized.contains('germin')) {
      return const _ResolvedOnionStage(
        stage: OnionStageKey.germinacion,
        usedFallback: false,
      );
    }
    if (normalized.contains('emerg')) {
      return const _ResolvedOnionStage(
        stage: OnionStageKey.emergencia,
        usedFallback: false,
      );
    }
    if (normalized.contains('establec') || normalized.contains('transplant')) {
      return const _ResolvedOnionStage(
        stage: OnionStageKey.establecimiento,
        usedFallback: false,
      );
    }
    if (normalized.contains('induccion') ||
        normalized.contains('pre_bulb') ||
        normalized.contains('prebulb')) {
      return const _ResolvedOnionStage(
        stage: OnionStageKey.induccionBulbificacion,
        usedFallback: false,
      );
    }
    if (normalized.contains('iniciobulbo') ||
        normalized.contains('bulb_init') ||
        normalized.contains('initiation')) {
      return const _ResolvedOnionStage(
        stage: OnionStageKey.inicioBulbo,
        usedFallback: false,
      );
    }
    if (normalized.contains('llenado') ||
        normalized.contains('bulb_fill') ||
        normalized.contains('fill')) {
      return const _ResolvedOnionStage(
        stage: OnionStageKey.llenadoBulbo,
        usedFallback: false,
      );
    }
    if (normalized.contains('madur') ||
        normalized.contains('maturity') ||
        normalized.contains('cosech') ||
        normalized.contains('harvest') ||
        normalized.contains('curado') ||
        normalized.contains('cuello')) {
      return const _ResolvedOnionStage(
        stage: OnionStageKey.maduracionCosecha,
        usedFallback: false,
      );
    }
    if (normalized.contains('espig') ||
        normalized.contains('bolting') ||
        normalized.contains('seedstalk') ||
        normalized.contains('senesc')) {
      return const _ResolvedOnionStage(
        stage: OnionStageKey.espigado,
        usedFallback: false,
      );
    }
    if (normalized.contains('veget') || normalized.contains('foliar')) {
      return const _ResolvedOnionStage(
        stage: OnionStageKey.vegetativo,
        usedFallback: false,
      );
    }

    return const _ResolvedOnionStage(
      stage: OnionStageKey.vegetativo,
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
      final canonical = resolveCanonicalOnionProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }
    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalOnionProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }
    return null;
  }
}

class _ResolvedOnionStage {
  final OnionStageKey stage;
  final bool usedFallback;

  const _ResolvedOnionStage({
    required this.stage,
    required this.usedFallback,
  });
}
