import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/orange_tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_assets.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_catalog.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_universal_profile.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class OrangeTreeProfile extends CropProfile {
  const OrangeTreeProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.orangeTree);
}

final Map<String, OrangeTreeProfile> orangeTreeProfiles =
    <String, OrangeTreeProfile>{
      for (final entry in orangeTreeProfileEntries)
        entry.id: OrangeTreeProfile(
          id: entry.id,
          label: entry.label,
          useType: 'tree',
        ),
    };

class OrangeTreeCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.orangeTree;

  @override
  CropCategory get category => CropCategory.tree;

  @override
  String get displayName => 'Naranjo';

  @override
  CropEngine get engine => const OrangeTreeCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final OrangeTreeProfile? resolved =
          orangeTreeProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in orangeTreeProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any(
              (alias) => _normalize(alias) == normalizedAlias,
            )) {
          return orangeTreeProfiles[entry.id];
        }
      }
    }

    // Fallback OR-SKIP (NUNCA cae a manzano/ap_skip, pera/pr_skip, durazno/
    // dz_skip, nogal/ng_skip ni pistache/ps_skip — doc 03 §13).
    return orangeTreeProfiles[kOrSkip] ??
        (orangeTreeProfiles.isNotEmpty
            ? orangeTreeProfiles.values.first
            : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    // Targets de sensor + semantica NPK relativa por etapa (doc 05). NO dosis.
    return resolveOrangeTreeTargets(stage.stageKey);
  }

  /// Pesos AgroScore por etapa (doc 05 §7).
  StageWeights resolveStageWeights(CropStageResult stage) =>
      resolveOrangeTreeStageWeights(stage.stageKey);

  /// Prioridades NPK relativas + nota UX por etapa (doc 05 §11). NO son dosis.
  OrangeTreeStageNutrition resolveNutritionPriorities(CropStageResult stage) =>
      resolveOrangeTreeNutritionPriorities(stage.stageKey);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    // El naranjo es un cultivo de PRIMERA CLASE del pipeline compartido: la
    // interpretacion NPK y el AgroScore pasan por el motor del arbol (espejo del
    // de granos): NutrientRecommendationEngine + OrangeTreeAgroScoreEngine.
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeTreeStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ?? resolveOrangeTreeTargets(stageId);
    final StageWeights weights = resolveOrangeTreeStageWeights(stageId);

    return OrangeTreeAgroScoreEngine.evaluate(
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

class OrangeTreeCropEngineAdapter implements CropEngine {
  const OrangeTreeCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    // El runtime resolver perenne ignora este engine para arboles: sowingDate no
    // es el eje del arbol. Este fallback mantiene seguro el contrato publico de
    // CropDefinition si una ruta legacy llamara engine.compute.
    return CropStageResult(
      stageKey: TreeStageIds.unknown,
      stageLabelEs: treeStageDisplayName(TreeStageIds.unknown),
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: OrangeTreeAssets.stageUnknown,
      helperCaption: 'Resolver perenne requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
