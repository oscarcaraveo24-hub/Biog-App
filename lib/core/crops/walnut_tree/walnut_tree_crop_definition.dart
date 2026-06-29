import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/walnut_tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_assets.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_catalog.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_universal_profile.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class WalnutTreeProfile extends CropProfile {
  const WalnutTreeProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.walnutTree);
}

final Map<String, WalnutTreeProfile> walnutTreeProfiles =
    <String, WalnutTreeProfile>{
      for (final entry in walnutTreeProfileEntries)
        entry.id: WalnutTreeProfile(
          id: entry.id,
          label: entry.label,
          useType: 'tree',
        ),
    };

class WalnutTreeCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.walnutTree;

  @override
  CropCategory get category => CropCategory.tree;

  @override
  String get displayName => 'Nogal';

  @override
  CropEngine get engine => const WalnutTreeCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final WalnutTreeProfile? resolved =
          walnutTreeProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in walnutTreeProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any(
              (alias) => _normalize(alias) == normalizedAlias,
            )) {
          return walnutTreeProfiles[entry.id];
        }
      }
    }

    // Fallback NG-SKIP (NUNCA cae a manzano/ap_skip, pera/pr_skip ni
    // durazno/dz_skip — doc 03 §0.1, §16.8).
    return walnutTreeProfiles[kNgSkip] ??
        (walnutTreeProfiles.isNotEmpty
            ? walnutTreeProfiles.values.first
            : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    // Targets de sensor + semantica NPK relativa por etapa (doc 05). NO dosis.
    return resolveWalnutTreeTargets(stage.stageKey);
  }

  /// Pesos AgroScore por etapa (doc 05 §11).
  StageWeights resolveStageWeights(CropStageResult stage) =>
      resolveWalnutTreeStageWeights(stage.stageKey);

  /// Prioridades NPK relativas + nota UX por etapa (doc 05 §10). NO son dosis.
  WalnutTreeStageNutrition resolveNutritionPriorities(CropStageResult stage) =>
      resolveWalnutTreeNutritionPriorities(stage.stageKey);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    // El nogal es un cultivo de PRIMERA CLASE del pipeline compartido: la
    // interpretacion NPK y el AgroScore pasan por el motor del arbol (espejo del
    // de granos): NutrientRecommendationEngine + WalnutTreeAgroScoreEngine.
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeTreeStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ?? resolveWalnutTreeTargets(stageId);
    final StageWeights weights = resolveWalnutTreeStageWeights(stageId);

    return WalnutTreeAgroScoreEngine.evaluate(
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

class WalnutTreeCropEngineAdapter implements CropEngine {
  const WalnutTreeCropEngineAdapter();

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
      heroAsset: WalnutTreeAssets.stageUnknown,
      helperCaption: 'Resolver perenne requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
