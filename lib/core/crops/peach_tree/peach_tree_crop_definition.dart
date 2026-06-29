import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/peach_tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_assets.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_universal_profile.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class PeachTreeProfile extends CropProfile {
  const PeachTreeProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.peachTree);
}

final Map<String, PeachTreeProfile> peachTreeProfiles =
    <String, PeachTreeProfile>{
      for (final entry in peachTreeProfileEntries)
        entry.id: PeachTreeProfile(
          id: entry.id,
          label: entry.label,
          useType: 'tree',
        ),
    };

class PeachTreeCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.peachTree;

  @override
  CropCategory get category => CropCategory.tree;

  @override
  String get displayName => 'Durazno';

  @override
  CropEngine get engine => const PeachTreeCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final PeachTreeProfile? resolved = peachTreeProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in peachTreeProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any(
              (alias) => _normalize(alias) == normalizedAlias,
            )) {
          return peachTreeProfiles[entry.id];
        }
      }
    }

    // Fallback DZ-SKIP (NUNCA cae a manzano/ap_skip ni pera/pr_skip — doc 03 §0.1).
    return peachTreeProfiles[kDzSkip] ??
        (peachTreeProfiles.isNotEmpty ? peachTreeProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    // Targets de sensor + semántica NPK relativa por etapa (doc 05). NO dosis.
    return resolvePeachTreeTargets(stage.stageKey);
  }

  /// Pesos AgroScore por etapa (doc 05 §11).
  StageWeights resolveStageWeights(CropStageResult stage) =>
      resolvePeachTreeStageWeights(stage.stageKey);

  /// Prioridades NPK relativas + nota UX por etapa (doc 05 §8). NO son dosis.
  PeachTreeStageNutrition resolveNutritionPriorities(CropStageResult stage) =>
      resolvePeachTreeNutritionPriorities(stage.stageKey);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    // El durazno es un cultivo de PRIMERA CLASE del pipeline compartido: la
    // interpretación NPK y el AgroScore pasan por el motor del árbol (espejo del
    // de granos): NutrientRecommendationEngine + PeachTreeAgroScoreEngine.
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeTreeStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ?? resolvePeachTreeTargets(stageId);
    final StageWeights weights = resolvePeachTreeStageWeights(stageId);

    return PeachTreeAgroScoreEngine.evaluate(
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

class PeachTreeCropEngineAdapter implements CropEngine {
  const PeachTreeCropEngineAdapter();

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
      heroAsset: PeachTreeAssets.stageUnknown,
      helperCaption: 'Resolver perenne requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
