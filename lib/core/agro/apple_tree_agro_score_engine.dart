import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/alerts_engine.dart';
import 'package:bio_g/core/agro/tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Motor AgroScore del Manzano.
///
/// Desde la integración del segundo árbol (pera), la lógica base vive en el
/// motor genérico [TreeAgroScoreEngine] (estándar BIO-G: "generalizar helpers
/// hardcodeados a apple_tree antes del segundo árbol"). Este wrapper conserva la
/// API pública del manzano y solo aporta su `cropKey`; el comportamiento es
/// idéntico (las pruebas de regresión del manzano lo verifican).
///
/// Desde el NPK Interpretation Reset (Guía v0.4, §4) este wrapper ya no resuelve
/// el modificador nutricional de la variedad: el score del árbol no interpreta
/// N/P/K. El modificador sigue existiendo y lo consume el motor de nutrición.
class AppleTreeAgroScoreEngine {
  const AppleTreeAgroScoreEngine._();

  /// Etapas críticas (más peso al estrés en alertas/score).
  static const Set<String> criticalStages = TreeAgroScoreEngine.criticalStages;

  /// Etapas semicríticas.
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
    return TreeAgroScoreEngine.evaluate(
      t: t,
      cropKey: 'apple_tree',
      stageId: stageId,
      stageLabelEs: stageLabelEs,
      targets: targets,
      weights: weights,
      alertsState: alertsState,
      cal: cal,
      alertsCooldown: alertsCooldown,
      cropLabel: cropLabel,
      profileId: profileId,
      varietyId: varietyId,
      varietyAlias: varietyAlias,
    );
  }
}
