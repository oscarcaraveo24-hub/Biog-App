import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/cereal_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/crops/wheat/wheat_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/wheat_models.dart';

class WheatAgroScoreEngine {
  /// Etapas críticas para trigo: heading, flowering (GS 50–69).
  /// En trigo, antesis + llenado temprano son las más críticas.
  // ✅ FIX: booting añadido como critical (consistente con adapter windows)
  static const Set<String> _criticalStages = {
    'booting', 'heading', 'flowering', 'grainFill',
  };

  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluate({
    required BioGTelemetry t,
    required WheatStageResult stage,
    required WheatUniversalProfile u,
    AlertsState alertsState = const AlertsState(),
    Calibration? cal,
    Duration alertsCooldown = const Duration(minutes: 60),
    String? cropLabel,
    StageTargets? targetsOverride,
    StageWeights? weightsOverride,
  }) {
    final stageKey = stage.stage;
    final targets = targetsOverride ?? u.byStage[stageKey];
    final weights = weightsOverride ?? u.weights[stageKey];

    if (targets == null || weights == null) {
      final empty = AgroEvalResult(
        soilControlScore01: 0.0,
        metrics: const {},
        alerts: const [],
        suggestedAlertKeys: const ['stage.unknown'],
      );
      return (eval: empty, nextAlertsState: alertsState);
    }

    return CerealAgroScoreEngine.evaluate(
      t: t,
      targets: targets,
      weights: weights,
      stageKey: stageKey.name,
      criticalStageKeys: _criticalStages,
      alertsState: alertsState,
      cal: cal,
      alertsCooldown: alertsCooldown,
      cropLabel: cropLabel,
      stageLabel: stage.stageLabelEs,
    );
  }
}
