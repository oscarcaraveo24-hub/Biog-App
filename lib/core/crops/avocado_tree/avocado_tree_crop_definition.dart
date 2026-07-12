import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/avocado_tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_assets.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_catalog.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_universal_profile.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class AvocadoTreeProfile extends CropProfile {
  const AvocadoTreeProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.avocadoTree);
}

final Map<String, AvocadoTreeProfile> avocadoTreeProfiles =
    <String, AvocadoTreeProfile>{
      for (final entry in avocadoTreeProfileEntries)
        entry.id: AvocadoTreeProfile(
          id: entry.id,
          label: entry.label,
          useType: 'tree',
        ),
    };

class AvocadoTreeCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.avocadoTree;

  @override
  CropCategory get category => CropCategory.tree;

  @override
  String get displayName => 'Aguacate';

  @override
  CropEngine get engine => const AvocadoTreeCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final AvocadoTreeProfile? resolved =
          avocadoTreeProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in avocadoTreeProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any(
              (alias) => _normalize(alias) == normalizedAlias,
            )) {
          return avocadoTreeProfiles[entry.id];
        }
      }
    }

    // Fallback AG-SKIP (NUNCA cae a mango/mg_skip, limón/lm_skip, naranjo/or_skip
    // ni manzano/ap_skip — doc 01 §0.1, §3.1: el aguacate NO es mango, NO es
    // cítrico, NO es manzano).
    return avocadoTreeProfiles[kAgSkip] ??
        (avocadoTreeProfiles.isNotEmpty
            ? avocadoTreeProfiles.values.first
            : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    // Targets de sensor + semantica NPK relativa por etapa (doc 05). NO dosis.
    return resolveAvocadoTreeTargets(stage.stageKey);
  }

  /// Pesos AgroScore por etapa (doc 05 §6).
  StageWeights resolveStageWeights(CropStageResult stage) =>
      resolveAvocadoTreeStageWeights(stage.stageKey);

  /// Prioridades NPK relativas + nota UX por etapa (doc 05 §7). NO son dosis.
  AvocadoTreeStageNutrition resolveNutritionPriorities(CropStageResult stage) =>
      resolveAvocadoTreeNutritionPriorities(stage.stageKey);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    // El aguacate es un cultivo de PRIMERA CLASE del pipeline compartido: la
    // interpretacion NPK y el AgroScore pasan por el motor del arbol (espejo del
    // de granos): NutrientRecommendationEngine + AvocadoTreeAgroScoreEngine.
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeTreeStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ?? resolveAvocadoTreeTargets(stageId);
    final StageWeights weights = resolveAvocadoTreeStageWeights(stageId);

    return AvocadoTreeAgroScoreEngine.evaluate(
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

class AvocadoTreeCropEngineAdapter implements CropEngine {
  const AvocadoTreeCropEngineAdapter();

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
      heroAsset: AvocadoTreeAssets.stageUnknown,
      helperCaption: 'Resolver perenne requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
