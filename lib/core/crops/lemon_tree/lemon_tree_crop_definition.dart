import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/lemon_tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_assets.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_catalog.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_universal_profile.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class LemonTreeProfile extends CropProfile {
  const LemonTreeProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.lemonTree);
}

final Map<String, LemonTreeProfile> lemonTreeProfiles =
    <String, LemonTreeProfile>{
      for (final entry in lemonTreeProfileEntries)
        entry.id: LemonTreeProfile(
          id: entry.id,
          label: entry.label,
          useType: 'tree',
        ),
    };

class LemonTreeCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.lemonTree;

  @override
  CropCategory get category => CropCategory.tree;

  @override
  String get displayName => 'Limón';

  @override
  CropEngine get engine => const LemonTreeCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final LemonTreeProfile? resolved = lemonTreeProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in lemonTreeProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any(
              (alias) => _normalize(alias) == normalizedAlias,
            )) {
          return lemonTreeProfiles[entry.id];
        }
      }
    }

    // Fallback LM-SKIP (NUNCA cae a manzano/ap_skip, pera/pr_skip, durazno/
    // dz_skip, nogal/ng_skip, pistache/ps_skip ni naranjo/or_skip — doc 03 §13,
    // doc 04 §13: el limón NO es un naranjo pequeño).
    return lemonTreeProfiles[kLmSkip] ??
        (lemonTreeProfiles.isNotEmpty
            ? lemonTreeProfiles.values.first
            : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    // Targets de sensor + semantica NPK relativa por etapa (doc 05). NO dosis.
    return resolveLemonTreeTargets(stage.stageKey);
  }

  /// Pesos AgroScore por etapa (doc 05 §6).
  StageWeights resolveStageWeights(CropStageResult stage) =>
      resolveLemonTreeStageWeights(stage.stageKey);

  /// Prioridades NPK relativas + nota UX por etapa (doc 05 §7). NO son dosis.
  LemonTreeStageNutrition resolveNutritionPriorities(CropStageResult stage) =>
      resolveLemonTreeNutritionPriorities(stage.stageKey);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    // El limón es un cultivo de PRIMERA CLASE del pipeline compartido: la
    // interpretacion NPK y el AgroScore pasan por el motor del arbol (espejo del
    // de granos): NutrientRecommendationEngine + LemonTreeAgroScoreEngine.
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeTreeStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ?? resolveLemonTreeTargets(stageId);
    final StageWeights weights = resolveLemonTreeStageWeights(stageId);

    return LemonTreeAgroScoreEngine.evaluate(
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

class LemonTreeCropEngineAdapter implements CropEngine {
  const LemonTreeCropEngineAdapter();

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
      heroAsset: LemonTreeAssets.stageUnknown,
      helperCaption: 'Resolver perenne requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
