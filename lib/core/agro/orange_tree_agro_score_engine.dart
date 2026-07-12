import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/orange_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Motor AgroScore del Naranjo.
///
/// Delega en el motor generico [TreeAgroScoreEngine] (mismo pipeline perenne que
/// manzano/pera/durazno/nogal/pistache), resolviendo el modificador del naranjo
/// y su `cropKey`. No duplica logica base: solo aporta la identidad del cultivo
/// (doc 05 §1, §20).
class OrangeTreeAgroScoreEngine {
  const OrangeTreeAgroScoreEngine._();

  /// Etapas criticas (mas peso al estres en alertas/score).
  static const Set<String> criticalStages = TreeAgroScoreEngine.criticalStages;

  /// Etapas semicriticas.
  static const Set<String> semiCriticalStages =
      TreeAgroScoreEngine.semiCriticalStages;

  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluate({
    required BioGTelemetry t,
    required String stageId,
    required String stageLabelEs,
    required StageTargets targets,
    required StageWeights weights,
    AlertsState alertsState = const AlertsState(),
    Calibration? cal,
    Duration alertsCooldown = AlertsEngine.defaultCooldown,
    String? cropLabel,
    String? profileId,
    String? varietyId,
    String? varietyAlias,
  }) {
    final modifier = resolveOrangeTreeNutritionModifier(
      profileId: profileId,
      varietyId: varietyId,
      alias: varietyAlias,
    );

    return TreeAgroScoreEngine.evaluate(
      t: t,
      cropKey: 'orange_tree',
      modifier: modifier,
      stageId: stageId,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      alertsState: alertsState,
      cal: cal,
      alertsCooldown: alertsCooldown,
      cropLabel: cropLabel ?? 'Naranjo',
      profileId: profileId,
      varietyId: varietyId,
      varietyAlias: varietyAlias,
    );
  }
}
