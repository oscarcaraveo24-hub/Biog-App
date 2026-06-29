import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/apple_tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_universal_profile.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class AppleTreeProfile extends CropProfile {
  const AppleTreeProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.appleTree);
}

final Map<String, AppleTreeProfile> appleTreeProfiles =
    <String, AppleTreeProfile>{
      for (final entry in appleTreeProfileEntries)
        entry.id: AppleTreeProfile(
          id: entry.id,
          label: entry.label,
          useType: 'tree',
        ),
    };

class AppleTreeCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.appleTree;

  @override
  CropCategory get category => CropCategory.tree;

  @override
  String get displayName => 'Manzano';

  @override
  CropEngine get engine => const AppleTreeCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final AppleTreeProfile? resolved = appleTreeProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in appleTreeProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any(
              (alias) => _normalize(alias) == normalizedAlias,
            )) {
          return appleTreeProfiles[entry.id];
        }
      }
    }

    return appleTreeProfiles[kApSkip] ??
        (appleTreeProfiles.isNotEmpty ? appleTreeProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    // Targets de sensor + rangos comparables de suelo (mg/kg) y semántica NPK
    // relativa por etapa (doc 05). NO son dosis kg/ha.
    return resolveAppleTreeTargets(stage.stageKey);
  }

  /// Pesos AgroScore por etapa (doc 05 §10). Misma fuente que usa
  /// [evaluateTelemetry] para ponderar el control de suelo.
  StageWeights resolveStageWeights(CropStageResult stage) =>
      resolveAppleTreeStageWeights(stage.stageKey);

  /// Prioridades NPK relativas + nota UX por etapa (doc 05 §8). NO son dosis.
  AppleTreeStageNutrition resolveNutritionPriorities(CropStageResult stage) =>
      resolveAppleTreeNutritionPriorities(stage.stageKey);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    // El manzano es un cultivo de PRIMERA CLASE del pipeline compartido: la
    // interpretación NPK y el AgroScore pasan por el motor dedicado, espejo del
    // de granos (NutrientRecommendationEngine + AppleTreeAgroScoreEngine).
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeTreeStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ?? resolveAppleTreeTargets(stageId);
    final StageWeights weights = resolveAppleTreeStageWeights(stageId);

    return AppleTreeAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stageId: stageId,
      stageLabelEs: stage.stageLabelEs,
      targets: targets,
      weights: weights,
      alertsState: alertsState,
      cropLabel: displayName,
      profileId: profile.id,
    );
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}

class AppleTreeCropEngineAdapter implements CropEngine {
  const AppleTreeCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    // The runtime resolver bypasses this engine for trees because sowingDate
    // is not the logical axis for perennials. This fallback keeps the public
    // CropDefinition contract safe if a legacy caller invokes engine.compute.
    return CropStageResult(
      stageKey: TreeStageIds.unknown,
      stageLabelEs: treeStageDisplayName(TreeStageIds.unknown),
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: 'assets/icons/wizard/ic_tree.png',
      helperCaption: 'Resolver perenne requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
