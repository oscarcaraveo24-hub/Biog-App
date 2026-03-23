import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/cereal_agro_score_engine.dart';
import 'package:bio_g/crops/barley/barley_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/widgets/seeds/barley_models.dart';

class BarleyAgroScoreEngine {
  /// Etapas críticas para cebada: booting, heading, flowering (GS 40–69).
  static const Set<String> _criticalStages = {
    'booting', 'heading', 'flowering',
  };

  static ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluate({
    required BioGTelemetry t,
    required BarleyStageResult stage,
    required BarleyUniversalProfile u,
    AlertsState alertsState = const AlertsState(),
    Calibration? cal,
    Duration alertsCooldown = const Duration(minutes: 60),
    String? cropLabel,
  }) {
    final stageKey = stage.stage;
    final targets = u.byStage[stageKey];
    final weights = u.weights[stageKey];

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
