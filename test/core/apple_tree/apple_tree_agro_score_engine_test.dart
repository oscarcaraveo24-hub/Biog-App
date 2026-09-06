// test/core/apple_tree/apple_tree_agro_score_engine_test.dart
//
// El motor del manzano espeja al de granos: suelo por AgroRange con presencia
// de señal. N/P/K ya no se interpretan aquí (Guía v0.4, §2 y §8): son señal
// nativa; el manejo nutricional lo decide el motor de nutrición por etapa.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/apple_tree_agro_score_engine.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_universal_profile.dart';
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
  double k = 80,
}) {
  return BioGTelemetry(
    deviceId: 'tree-1',
    timestamp: DateTime.utc(2026, 6, 14, 10),
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
  String profileId = kApSkip,
}) {
  return AppleTreeAgroScoreEngine.evaluate(
    t: t,
    stageId: stage,
    stageLabelEs: treeStageDisplayName(stage),
    targets: resolveAppleTreeTargets(stage),
    weights: resolveAppleTreeStageWeights(stage),
    profileId: profileId,
  );
}

void main() {
  group('Bandas de suelo del manzano (observacion vs critico real)', () {
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

    test('llenado + humedad 59% queda en observacion baja, no critico', () {
      final out = _run(_tele(soilMoisturePct: 59));
      final moisture = out.eval.metrics[AgroMetricKey.soilMoisture]!;

      expect(moisture.band, AgroBand.low);
      expect(moisture.score01, greaterThan(0.70));
      expect(
        out.eval.suggestedAlertKeys,
        isNot(contains('tree.fruit_fill.soilMoisture.critical')),
      );
    });

    test('humedad 44% y 20% entran como deficit critico real', () {
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
        lessThan(
          lowAlert.eval.metrics[AgroMetricKey.soilMoisture]!.score01,
        ),
      );
    });

    test('humedad 91% se lee como exceso/saturacion, no como deficit', () {
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
      expect(
        out.eval.alerts.map((a) => a.type),
        contains(BioGAlertType.highSoilMoisture),
      );
    });

    test('temperatura apenas fuera de optimo no es critica', () {
      final watch = _run(
        _tele(soilTempC: 9),
        stage: TreeStageIds.budbreak,
      );
      final harvestFloor = _run(
        _tele(soilTempC: 10),
        stage: TreeStageIds.harvestMaturity,
      );
      final extreme = _run(
        _tele(soilTempC: 4),
        stage: TreeStageIds.budbreak,
      );

      expect(
        watch.eval.metrics[AgroMetricKey.soilTemp]!.band,
        isNot(AgroBand.critical),
      );
      expect(
        harvestFloor.eval.metrics[AgroMetricKey.soilTemp]!.band,
        AgroBand.optimal,
      );
      expect(
        extreme.eval.metrics[AgroMetricKey.soilTemp]!.band,
        AgroBand.critical,
      );
    });

    test('dormancia suaviza frio de suelo frente a una etapa activa', () {
      final dormant = _run(
        _tele(soilTempC: 2),
        stage: TreeStageIds.dormancy,
      );
      final active = _run(
        _tele(soilTempC: 2),
        stage: TreeStageIds.budbreak,
      );

      expect(
        dormant.eval.metrics[AgroMetricKey.soilTemp]!.band,
        isNot(AgroBand.critical),
      );
      expect(
        active.eval.metrics[AgroMetricKey.soilTemp]!.band,
        AgroBand.critical,
      );
      expect(
        dormant.eval.soilControlScore01,
        greaterThan(active.eval.soilControlScore01),
      );
    });

    test('pH 7.6 advierte disponibilidad; pH 8.2 ya es extremo', () {
      final observation = _run(_tele(ph: 7.6));
      final extreme = _run(_tele(ph: 8.2));

      expect(observation.eval.metrics[AgroMetricKey.ph]!.band, AgroBand.high);
      expect(
        extreme.eval.metrics[AgroMetricKey.ph]!.band,
        AgroBand.critical,
      );
    });

    test('CE y resistencia moderadas no son criticas; extremos reales si', () {
      final ecWatch = _run(
        _tele(ec: 2.1),
        stage: TreeStageIds.harvestMaturity,
      );
      final ecExtreme = _run(_tele(ec: 3.2));
      final resistanceWatch = _run(_tele(resistance: 2.1));
      final resistanceExtreme = _run(_tele(resistance: 3.2));

      expect(ecWatch.eval.metrics[AgroMetricKey.ec]!.band, AgroBand.high);
      expect(
        ecExtreme.eval.metrics[AgroMetricKey.ec]!.band,
        AgroBand.critical,
      );
      expect(
        resistanceWatch.eval.metrics[AgroMetricKey.resistance]!.band,
        AgroBand.high,
      );
      expect(
        resistanceExtreme.eval.metrics[AgroMetricKey.resistance]!.band,
        AgroBand.critical,
      );
    });

    test('CE alta con humedad baja eleva alerta salina transversal', () {
      final out = _run(_tele(ec: 2.2, soilMoisturePct: 50));

      expect(out.eval.metrics[AgroMetricKey.ec]!.band, AgroBand.high);
      expect(out.eval.metrics[AgroMetricKey.soilMoisture]!.band, AgroBand.low);
      expect(
        out.eval.alerts.map((a) => a.type),
        contains(BioGAlertType.ecOutOfRange),
      );
    });

    test('etapa unknown usa criterio conservador, no agresivo', () {
      final out = _run(
        _tele(soilMoisturePct: 59, soilTempC: 10),
        stage: TreeStageIds.unknown,
      );

      expect(
        out.eval.metrics[AgroMetricKey.soilMoisture]!.band,
        isNot(AgroBand.critical),
      );
      expect(
        out.eval.metrics[AgroMetricKey.soilTemp]!.band,
        isNot(AgroBand.critical),
      );
      expect(out.eval.soilControlScore01, greaterThan(0.75));
    });
  });

  group('Alertas por etapa del manzano', () {
    test('plantación con saturación avisa sin recomendar más riego', () {
      final out = _run(
        _tele(soilMoisturePct: 95),
        stage: TreeStageIds.plantingTransplant,
      );

      expect(
        out.eval.alerts.map((a) => a.type),
        contains(BioGAlertType.highSoilMoisture),
      );
      expect(
        out.eval.alerts.map((a) => a.body).join(' '),
        contains('no empujes más riego'),
      );
    });

    test('brotación con frío avisa riesgo de helada tardía', () {
      final out = _run(_tele(airTempC: 2), stage: TreeStageIds.budbreak);

      expect(
        out.eval.alerts.map((a) => a.type),
        contains(BioGAlertType.airTempExtreme),
      );
      expect(
        out.eval.alerts.map((a) => a.title),
        contains('Riesgo de helada en brotación'),
      );
    });

  });

}
