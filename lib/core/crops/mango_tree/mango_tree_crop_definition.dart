import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/mango_tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_assets.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_catalog.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_universal_profile.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class MangoTreeProfile extends CropProfile {
  const MangoTreeProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.mangoTree);
}

final Map<String, MangoTreeProfile> mangoTreeProfiles =
    <String, MangoTreeProfile>{
      for (final entry in mangoTreeProfileEntries)
        entry.id: MangoTreeProfile(
          id: entry.id,
          label: entry.label,
          useType: 'tree',
        ),
    };

class MangoTreeCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.mangoTree;

  @override
  CropCategory get category => CropCategory.tree;

  @override
  String get displayName => 'Mango';

  @override
  CropEngine get engine => const MangoTreeCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final MangoTreeProfile? resolved = mangoTreeProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in mangoTreeProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any(
              (alias) => _normalize(alias) == normalizedAlias,
            )) {
          return mangoTreeProfiles[entry.id];
        }
      }
    }

    // Fallback MG-SKIP (NUNCA cae a manzano/ap_skip, pera/pr_skip, durazno/
    // dz_skip, nogal/ng_skip, pistache/ps_skip, naranjo/or_skip ni limón/lm_skip
    // — doc 01 §12, doc 04 §13: el mango NO es limón, NO es naranjo, NO es
    // manzano).
    return mangoTreeProfiles[kMgSkip] ??
        (mangoTreeProfiles.isNotEmpty
            ? mangoTreeProfiles.values.first
            : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    // Targets de sensor + semantica NPK relativa por etapa (doc 05). NO dosis.
    return resolveMangoTreeTargets(stage.stageKey);
  }

  /// Pesos AgroScore por etapa (doc 05 §6).
  StageWeights resolveStageWeights(CropStageResult stage) =>
      resolveMangoTreeStageWeights(stage.stageKey);

  /// Prioridades NPK relativas + nota UX por etapa (doc 05 §7). NO son dosis.
  MangoTreeStageNutrition resolveNutritionPriorities(CropStageResult stage) =>
      resolveMangoTreeNutritionPriorities(stage.stageKey);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    // El mango es un cultivo de PRIMERA CLASE del pipeline compartido: la
    // interpretacion NPK y el AgroScore pasan por el motor del arbol (espejo del
    // de granos): NutrientRecommendationEngine + MangoTreeAgroScoreEngine.
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeTreeStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ?? resolveMangoTreeTargets(stageId);
    final StageWeights weights = resolveMangoTreeStageWeights(stageId);

    return MangoTreeAgroScoreEngine.evaluate(
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

class MangoTreeCropEngineAdapter implements CropEngine {
  const MangoTreeCropEngineAdapter();

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
      heroAsset: MangoTreeAssets.stageUnknown,
      helperCaption: 'Resolver perenne requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
