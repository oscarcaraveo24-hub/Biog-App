import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/pear_tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_universal_profile.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class PearTreeProfile extends CropProfile {
  const PearTreeProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.pearTree);
}

final Map<String, PearTreeProfile> pearTreeProfiles = <String, PearTreeProfile>{
  for (final entry in pearTreeProfileEntries)
    entry.id: PearTreeProfile(
      id: entry.id,
      label: entry.label,
      useType: 'tree',
    ),
};

class PearTreeCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.pearTree;

  @override
  CropCategory get category => CropCategory.tree;

  @override
  String get displayName => 'Pera';

  @override
  CropEngine get engine => const PearTreeCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final PearTreeProfile? resolved = pearTreeProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in pearTreeProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any(
              (alias) => _normalize(alias) == normalizedAlias,
            )) {
          return pearTreeProfiles[entry.id];
        }
      }
    }

    // Fallback PR-SKIP (NUNCA cae a manzano/ap_skip — doc 03 §0.1).
    return pearTreeProfiles[kPrSkip] ??
        (pearTreeProfiles.isNotEmpty ? pearTreeProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    // Targets de sensor + semántica NPK relativa por etapa (doc 05). NO dosis.
    return resolvePearTreeTargets(stage.stageKey);
  }

  /// Pesos AgroScore por etapa (doc 05 §11).
  StageWeights resolveStageWeights(CropStageResult stage) =>
      resolvePearTreeStageWeights(stage.stageKey);

  /// Prioridades NPK relativas + nota UX por etapa (doc 05 §8). NO son dosis.
  PearTreeStageNutrition resolveNutritionPriorities(CropStageResult stage) =>
      resolvePearTreeNutritionPriorities(stage.stageKey);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    // La pera es un cultivo de PRIMERA CLASE del pipeline compartido: la
    // interpretación NPK y el AgroScore pasan por el motor del árbol (espejo del
    // de granos): NutrientRecommendationEngine + PearTreeAgroScoreEngine.
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeTreeStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ?? resolvePearTreeTargets(stageId);
    final StageWeights weights = resolvePearTreeStageWeights(stageId);

    return PearTreeAgroScoreEngine.evaluate(
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

class PearTreeCropEngineAdapter implements CropEngine {
  const PearTreeCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    // El runtime resolver perenne ignora este engine para árboles: sowingDate no
    // es el eje del árbol. Este fallback mantiene seguro el contrato público de
    // CropDefinition si una ruta legacy llamara engine.compute.
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
