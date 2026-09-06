// test/core/pear_tree/pear_tree_agro_score_engine_test.dart
//
// El motor de la pera espeja al de granos: suelo por AgroRange con presencia
// de señal. N/P/K ya no se interpretan aquí (Guía v0.4, §2 y §8): son señal
// nativa; el manejo nutricional lo decide el motor de nutrición por etapa.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/pear_tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_universal_profile.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

BioGTelemetry _tele({
  double soilMoisturePct = 75,
  double soilTempC = 22,
  double airTempC = 20,
  double airHumidityPct = 55,
  double ph = 6.4,
  double ec = 1.0,
  double resistance = 0.8,
  double n = 35,
  double p = 45,
  double k = 110,
}) {
  return BioGTelemetry(
    deviceId: 'pear-1',
    timestamp: DateTime.utc(2026, 6, 20, 10),
    airTempC: airTempC,
    airHumidityPct: airHumidityPct,
    soilMoisturePct: soilMoisturePct,
    soilTempC: soilTempC,
    ph: ph,
    ec: ec,
    resistance: resistance,
    n: n,
    p: p,
    k: k,
    batteryPct: 95,
    signalRssi: -54,
  );
}

({AgroEvalResult eval, AlertsState nextAlertsState}) _run(
  BioGTelemetry t, {
  String stage = TreeStageIds.fruitFill,
  String profileId = kPrSkip,
}) {
  return PearTreeAgroScoreEngine.evaluate(
    t: t,
    stageId: stage,
    stageLabelEs: treeStageDisplayName(stage),
    targets: resolvePearTreeTargets(stage),
    weights: resolvePearTreeStageWeights(stage),
    profileId: profileId,
  );
}

void main() {
  group('Bandas de suelo de la pera (observación vs crítico real)', () {
    test('madurez + humedad 59% queda operativa y no tumba el ring', () {
      final out = _run(
        _tele(soilMoisturePct: 59),
        stage: TreeStageIds.harvestMaturity,
      );
      final moisture = out.eval.metrics[AgroMetricKey.soilMoisture]!;
      expect(moisture.band, AgroBand.optimal);
      expect(
        out.eval.suggestedAlertKeys,
        isNot(contains('tree.harvest_maturity.soilMoisture.critical')),
      );
      expect(out.eval.soilControlScore01, greaterThan(0.80));
    });

    test('llenado + humedad 59% queda en observación baja, no crítico', () {
      final out = _run(_tele(soilMoisturePct: 59));
      final moisture = out.eval.metrics[AgroMetricKey.soilMoisture]!;
      expect(moisture.band, AgroBand.low);
      expect(moisture.score01, greaterThan(0.70));
      expect(
        out.eval.suggestedAlertKeys,
        isNot(contains('tree.fruit_fill.soilMoisture.critical')),
      );
    });

    test('humedad 44% y 20% entran como déficit crítico real', () {
      final lowAlert = _run(_tele(soilMoisturePct: 44));
      final severe = _run(_tele(soilMoisturePct: 20));
      expect(
        lowAlert.eval.metrics[AgroMetricKey.soilMoisture]!.band,
        AgroBand.critical,
      );
      expect(
        severe.eval.metrics[AgroMetricKey.soilMoisture]!.band,
        AgroBand.critical,
      );
      expect(
        severe.eval.metrics[AgroMetricKey.soilMoisture]!.score01,
        lessThan(lowAlert.eval.metrics[AgroMetricKey.soilMoisture]!.score01),
      );
    });

    test('humedad 91% en madurez se lee como saturación, no déficit', () {
      final out = _run(
        _tele(soilMoisturePct: 91),
        stage: TreeStageIds.harvestMaturity,
      );
      final moisture = out.eval.metrics[AgroMetricKey.soilMoisture]!;
      expect(moisture.band, AgroBand.high);
      expect(
        out.eval.suggestedAlertKeys,
        contains('tree.harvest_maturity.soilMoisture.high'),
      );
    });

    test('dormancia suaviza frío de suelo frente a una etapa activa', () {
      final dormant = _run(_tele(soilTempC: 2), stage: TreeStageIds.dormancy);
      final active = _run(_tele(soilTempC: 2), stage: TreeStageIds.budbreak);
      expect(
        dormant.eval.metrics[AgroMetricKey.soilTemp]!.band,
        isNot(AgroBand.critical),
      );
      expect(
        active.eval.metrics[AgroMetricKey.soilTemp]!.band,
        AgroBand.critical,
      );
    });

    test('pH 7.6 advierte disponibilidad; pH 8.2 ya es extremo', () {
      final observation = _run(_tele(ph: 7.6));
      final extreme = _run(_tele(ph: 8.2));
      expect(observation.eval.metrics[AgroMetricKey.ph]!.band, AgroBand.high);
      expect(extreme.eval.metrics[AgroMetricKey.ph]!.band, AgroBand.critical);
    });

    test(
      'CE moderada no es crítica; extremo real sí (pera es salino-sensible)',
      () {
        final ecWatch = _run(_tele(ec: 2.0));
        final ecExtreme = _run(_tele(ec: 2.4));
        expect(ecWatch.eval.metrics[AgroMetricKey.ec]!.band, AgroBand.high);
        expect(
          ecExtreme.eval.metrics[AgroMetricKey.ec]!.band,
          AgroBand.critical,
        );
      },
    );
  });

}
