// test/core/agro/nutrition/nutrition_readiness_engine_test.dart
//
// Congela el contrato del motor de nutrición con la regla de producto que lo
// define: el agricultor no registra nada; la sonda observa; solo una ventana
// importante que TERMINA sin evidencia pesa en el score.
import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_readiness_engine.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_window_ledger.dart';
import 'package:bio_g/core/agro/nutrition/site_learning.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

const AgroRange _soil = AgroRange(
  lowMax: 15,
  optimalMin: 25,
  optimalMax: 45,
  highMin: 60,
);
const AgroRange _ph = AgroRange(lowMax: 5.0, optimalMin: 6.0, optimalMax: 7.2, highMin: 8.0);
const AgroRange _ec = AgroRange(lowMax: 0.2, optimalMin: 0.6, optimalMax: 2.0, highMin: 3.0);
const AgroRange _res = AgroRange(lowMax: 0.1, optimalMin: 0.3, optimalMax: 1.4, highMin: 2.2);
const AgroRange _temp = AgroRange(lowMax: 8, optimalMin: 15, optimalMax: 28, highMin: 34);

/// Etapa con alta demanda de N (ventana importante) y demanda baja de P/K.
const StageTargets _nDemand = StageTargets(
  moistureRaw: _soil,
  soilTemp: _temp,
  ph: _ph,
  ec: _ec,
  resistance: _res,
  nIndex: AgroRange(lowMax: 60, optimalMin: 70, optimalMax: 90, highMin: 100),
  pIndex: AgroRange(lowMax: 0, optimalMin: 10, optimalMax: 30, highMin: 40),
  kIndex: AgroRange(lowMax: 0, optimalMin: 10, optimalMax: 30, highMin: 40),
  nPriority: 0.85,
  pPriority: 0.2,
  kPriority: 0.2,
  nWindowLabelEs: 'Tramo fuerte de N',
  nShortGuidanceEs: 'El cultivo toma nitrógeno con fuerza en esta etapa.',
);

/// Etapa sin ventana.
const StageTargets _quiet = StageTargets(
  moistureRaw: _soil,
  soilTemp: _temp,
  ph: _ph,
  ec: _ec,
  resistance: _res,
  nIndex: AgroRange(lowMax: 0, optimalMin: 10, optimalMax: 30, highMin: 40),
  pIndex: AgroRange(lowMax: 0, optimalMin: 10, optimalMax: 30, highMin: 40),
  kIndex: AgroRange(lowMax: 0, optimalMin: 10, optimalMax: 30, highMin: 40),
  nPriority: 0.2,
  pPriority: 0.2,
  kPriority: 0.2,
);

final DateTime _t0 = DateTime(2026, 5, 1, 0);

double _diurnal(double h, double amp) => amp * math.sin(h / 24 * 2 * math.pi);

List<BioGTelemetry> _history({
  required int hours,
  double Function(double h)? ecAt,
  double Function(double h)? vwcAt,
}) {
  final List<BioGTelemetry> out = <BioGTelemetry>[];
  for (int h = 0; h <= hours; h += 2) {
    final double hh = h.toDouble();
    final double ec = (ecAt ?? (_) => 1.0)(hh) + _diurnal(hh, 0.03);
    out.add(
      BioGTelemetry(
        deviceId: 'dev',
        timestamp: _t0.add(Duration(hours: h)),
        airTempC: 24,
        airHumidityPct: 50,
        soilMoisturePct: (vwcAt ?? (_) => 32.0)(hh) + _diurnal(hh, 0.5),
        soilTempC: 22,
        ph: 6.8,
        ec: ec,
        resistance: 0.9,
        n: ec * 30,
        p: ec * 12,
        k: ec * 50,
        batteryPct: 90,
        signalRssi: -60,
      ),
    );
  }
  return out;
}

BioGTelemetry _live(DateTime at) => BioGTelemetry(
  deviceId: 'dev',
  timestamp: at,
  airTempC: 24,
  airHumidityPct: 50,
  soilMoisturePct: 32,
  soilTempC: 22,
  ph: 6.8,
  ec: 1.0,
  resistance: 0.9,
  n: 30,
  p: 12,
  k: 50,
  batteryPct: 90,
  signalRssi: -60,
);

NutritionReadinessInput _input({
  required DateTime now,
  required StageTargets targets,
  String stageKey = 'vegMid',
  String stageLabel = 'Vegetativo medio',
  DateTime? stageStartedAt,
  List<BioGTelemetry> history = const <BioGTelemetry>[],
  List<NutritionWindowRecord> windows = const <NutritionWindowRecord>[],
  SiteLearningStatus learning = SiteLearningStatus.unknown,
  bool isPlanted = true,
  bool isGuideMode = false,
}) {
  return NutritionReadinessInput(
    now: now,
    isPlanted: isPlanted,
    isGuideMode: isGuideMode,
    cropKey: 'maize',
    cropLabel: 'Maíz',
    stageKey: stageKey,
    stageLabelEs: stageLabel,
    daysToStageEnd: 20,
    stageProgress01: 0.3,
    stageStartedAt: stageStartedAt ?? _t0.add(const Duration(days: 3)),
    targets: targets,
    live: _live(now),
    deviceId: 'dev',
    seasonKey: 'dev|maize|2026-04-01',
    windows: windows,
    history: history,
    learning: learning,
  );
}

void main() {
  group('NutritionReadinessEngine · guardas', () {
    test('sin cultivo sembrado, en guía o genérico no decide nada', () {
      expect(
        NutritionReadinessEngine.evaluate(
          _input(now: _t0, targets: _nDemand, isPlanted: false),
        ),
        isNull,
      );
      expect(
        NutritionReadinessEngine.evaluate(
          _input(now: _t0, targets: _nDemand, isGuideMode: true),
        ),
        isNull,
      );
    });
  });

  group('NutritionReadinessEngine · ventana abierta', () {
    test('la etapa abre la ventana y el motor la observa SIN penalizar', () {
      final DateTime now = _t0.add(const Duration(days: 5));
      final NutritionEvaluation out = NutritionReadinessEngine.evaluate(
        _input(
          now: now,
          targets: _nDemand,
          history: _history(hours: 24 * 5),
        ),
      )!;
      final NutritionDecision d = out.decision;

      expect(d.state, NutritionState.actionWindow);
      expect(d.headlineEs, startsWith('Esta etapa necesita nutrición'));
      expect(d.awaitingEvidence, isTrue);
      expect(d.scoreFactor, 1.0, reason: 'una ventana abierta nunca penaliza');
      expect(d.unattendedCriticalWindows, 0);
      expect(d.recommendation?.nutrient, AgroMetricKey.n);
      expect(d.detailEs, isNot(contains('regístralo')));
      expect(d.detailEs.toLowerCase(), contains('no necesitas registrar'));
      expect(d.window?.outcome, NutritionWindowOutcome.open);
      expect(d.window?.isCritical, isTrue);
      expect(out.changedWindows, isNotEmpty, reason: 'la ventana nueva se persiste');
    });

    test('la prioridad viene del perfil, nunca de la lectura N/P/K', () {
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(now: _t0.add(const Duration(days: 5)), targets: _nDemand),
      )!.decision;
      expect(d.priorities.first.nutrient, AgroMetricKey.n);
      expect(d.priorities.first.priority, NutritionPriority.high);
      expect(d.priorities.first.isCriticalWindow, isTrue);
      expect(
        d.priorities.where((p) => p.nutrient != AgroMetricKey.n).every(
          (p) => p.priority == NutritionPriority.low,
        ),
        isTrue,
      );
    });

    test('sin ventana en la etapa el motor solo sigue tendencias', () {
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(now: _t0.add(const Duration(days: 5)), targets: _quiet),
      )!.decision;
      expect(d.state, NutritionState.monitor);
      expect(d.window, isNull);
      expect(d.recommendation, isNull);
      expect(d.scoreFactor, 1.0);
      expect(d.trends.length, 3);
      expect(d.trends.every((t) => t.trend == NativeTrend.unknown), isTrue,
          reason: 'sin historial no hay tendencia');
      expect(d.headlineEs, 'Suelo estable, sin necesidades nutrimentales por ahora');
    });

    test('con historial plano el suelo se declara estable; si N sube, lo dice', () {
      final DateTime now = _t0.add(const Duration(days: 8));
      final NutritionDecision flat = NutritionReadinessEngine.evaluate(
        _input(now: now, targets: _quiet, history: _history(hours: 24 * 8)),
      )!.decision;
      expect(flat.trendFor(AgroMetricKey.n)?.trend, NativeTrend.stable);
      expect(flat.trendSummaryEs, 'N estable · P estable · K estable');
      expect(flat.notableTrend, isNull);
      expect(flat.headlineEs, 'Suelo estable, sin necesidades nutrimentales por ahora');

      // La señal de N sube 30 % en las últimas 48 h (P y K siguen la CE,
      // pero aquí se inyecta solo N para aislar la lectura).
      final List<BioGTelemetry> rising = _history(hours: 24 * 8)
          .map(
            (t) => t.timestamp.isAfter(now.subtract(const Duration(hours: 48)))
                ? t.copyWith(n: t.n * 1.3)
                : t,
          )
          .toList();
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(now: now, targets: _quiet, history: rising),
      )!.decision;
      final NutrientTrend n = d.trendFor(AgroMetricKey.n)!;
      expect(n.trend, NativeTrend.rising);
      expect(n.changePct, greaterThan(NutrientTrend.kMovingThresholdPct));
      expect(d.notableTrend?.nutrient, AgroMetricKey.n);
      expect(d.headlineEs, 'Tendencia al alza en nitrógeno');
      expect(d.detailEs, contains('viene subiendo'));
      expect(d.state, NutritionState.monitor, reason: 'una tendencia no abre ventana');
    });
  });

  group('NutritionReadinessEngine · detección automática', () {
    test('un fertirriego dentro de la ventana la deja atendida, sin registro', () {
      // Ventana abre el día 3; el día 6 entra agua con sales.
      final history = _history(
        hours: 24 * 9,
        ecAt: (h) => h < 24 * 6 ? 1.0 : 1.7,
        vwcAt: (h) => h < 24 * 6 ? 32.0 : 38.0,
      );
      final DateTime now = _t0.add(const Duration(days: 9));
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(now: now, targets: _nDemand, history: history),
      )!.decision;

      expect(d.window?.outcome, NutritionWindowOutcome.attendedDetected);
      expect(d.hasDetectedSignature, isTrue);
      expect(d.state, NutritionState.responseWindow);
      expect(d.headlineEs, 'Respuesta compatible con fertilización detectada');
      expect(d.awaitingEvidence, isFalse);
      expect(d.recommendation, isNull, reason: 'no se empuja dosis');
      expect(d.scoreFactor, 1.0);
      expect(d.response?.verdict, ResponseVerdict.pending);
    });

    test('cerrado el horizonte de respuesta, la ventana queda atendida en seguimiento', () {
      final history = _history(
        hours: 24 * 14,
        ecAt: (h) => h < 24 * 6 ? 1.0 : 1.7,
        vwcAt: (h) => h < 24 * 6 ? 32.0 : 38.0,
      );
      final DateTime now = _t0.add(const Duration(days: 14));
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(now: now, targets: _nDemand, history: history),
      )!.decision;

      expect(d.window?.outcome, NutritionWindowOutcome.attendedDetected);
      expect(d.state, NutritionState.monitor);
      expect(d.headlineEs, startsWith('Nutrición atendida'));
      expect(d.response?.verdict, ResponseVerdict.compatible);
      expect(d.window?.responseVerdict, ResponseVerdict.compatible);
    });
  });

  group('NutritionReadinessEngine · cierre de ventana', () {
    test('la ventana importante que terminó observable y sin evidencia pesa', () {
      // Historial plano durante toda la ventana (días 3-10) y la etapa cambió.
      final history = _history(hours: 24 * 16);
      final NutritionWindowRecord open = NutritionWindowRecord(
        id: NutritionWindowRecord.buildId(
          seasonKey: 'dev|maize|2026-04-01',
          stageKey: 'vegmid',
          nutrients: const <AgroMetricKey>[AgroMetricKey.n],
        ),
        seasonKey: 'dev|maize|2026-04-01',
        deviceId: 'dev',
        cropKey: 'maize',
        stageKey: 'vegmid',
        stageLabelEs: 'Vegetativo medio',
        nutrients: const <AgroMetricKey>[AgroMetricKey.n],
        isCritical: true,
        openedAt: _t0.add(const Duration(days: 3)),
        closedAt: _t0.add(const Duration(days: 10)),
        outcome: NutritionWindowOutcome.open,
      );
      // Hoy: día 16, la gracia de cierre (4 días) ya venció.
      final DateTime now = _t0.add(const Duration(days: 16));
      final NutritionEvaluation out = NutritionReadinessEngine.evaluate(
        _input(
          now: now,
          targets: _quiet,
          stageKey: 'flowering',
          stageLabel: 'Floración',
          history: history,
          windows: <NutritionWindowRecord>[open],
        ),
      )!;
      final NutritionDecision d = out.decision;

      final NutritionWindowRecord closed = out.windows.firstWhere((w) => w.id == open.id);
      expect(closed.outcome, NutritionWindowOutcome.unattended);
      expect(closed.penalizes, isTrue);
      expect(d.unattendedCriticalWindows, 1);
      expect(d.scoreFactor, closeTo(NutritionWindowLedger.kUnattendedWindowScoreFactor, 1e-9));
      expect(d.recentlyUnattendedWindow?.id, open.id);
      expect(
        d.headlineEs,
        'Esta ventana nutricional no mostró evidencia suficiente de haber sido atendida',
      );
    });

    test('la misma ventana sin lecturas termina inconclusa y NO pesa', () {
      final NutritionWindowRecord open = NutritionWindowRecord(
        id: 'w1',
        seasonKey: 'dev|maize|2026-04-01',
        deviceId: 'dev',
        cropKey: 'maize',
        stageKey: 'vegmid',
        stageLabelEs: 'Vegetativo medio',
        nutrients: const <AgroMetricKey>[AgroMetricKey.n],
        isCritical: true,
        openedAt: _t0.add(const Duration(days: 3)),
        closedAt: _t0.add(const Duration(days: 10)),
        outcome: NutritionWindowOutcome.open,
      );
      final DateTime now = _t0.add(const Duration(days: 16));
      final NutritionEvaluation out = NutritionReadinessEngine.evaluate(
        _input(
          now: now,
          targets: _quiet,
          stageKey: 'flowering',
          stageLabel: 'Floración',
          history: const <BioGTelemetry>[],
          windows: <NutritionWindowRecord>[open],
        ),
      )!;
      final NutritionWindowRecord closed = out.windows.firstWhere((w) => w.id == 'w1');
      expect(closed.outcome, NutritionWindowOutcome.notComparable);
      expect(closed.penalizes, isFalse);
      expect(out.decision.scoreFactor, 1.0);
    });

    test('durante la gracia de cierre la ventana sigue observándose', () {
      final history = _history(hours: 24 * 12);
      final NutritionWindowRecord open = NutritionWindowRecord(
        id: 'w1',
        seasonKey: 'dev|maize|2026-04-01',
        deviceId: 'dev',
        cropKey: 'maize',
        stageKey: 'vegmid',
        stageLabelEs: 'Vegetativo medio',
        nutrients: const <AgroMetricKey>[AgroMetricKey.n],
        isCritical: true,
        openedAt: _t0.add(const Duration(days: 3)),
        closedAt: _t0.add(const Duration(days: 10)),
        outcome: NutritionWindowOutcome.open,
      );
      // Día 12: cerró el día 10, la gracia (4 días) sigue abierta.
      final NutritionEvaluation out = NutritionReadinessEngine.evaluate(
        _input(
          now: _t0.add(const Duration(days: 12)),
          targets: _quiet,
          stageKey: 'flowering',
          stageLabel: 'Floración',
          history: history,
          windows: <NutritionWindowRecord>[open],
        ),
      )!;
      final NutritionWindowRecord w = out.windows.firstWhere((w) => w.id == 'w1');
      expect(w.outcome, NutritionWindowOutcome.open);
      expect(w.resolvedAt, isNull);
      expect(out.decision.scoreFactor, 1.0);
    });
  });

  group('NutritionWindowLedger · factor de temporada', () {
    NutritionWindowRecord unattended(String id) => NutritionWindowRecord(
      id: id,
      seasonKey: 's',
      deviceId: 'dev',
      cropKey: 'maize',
      stageKey: id,
      stageLabelEs: id,
      nutrients: const <AgroMetricKey>[AgroMetricKey.n],
      isCritical: true,
      openedAt: _t0,
      closedAt: _t0,
      resolvedAt: _t0,
      outcome: NutritionWindowOutcome.unattended,
    );

    test('cada ventana importante sin evidencia multiplica el factor', () {
      expect(NutritionWindowLedger.seasonScoreFactor(const []), 1.0);
      expect(
        NutritionWindowLedger.seasonScoreFactor([unattended('a')]),
        closeTo(0.94, 1e-9),
      );
      expect(
        NutritionWindowLedger.seasonScoreFactor([unattended('a'), unattended('b')]),
        closeTo(0.94 * 0.94, 1e-9),
      );
    });

    test('el factor tiene piso', () {
      final many = List<NutritionWindowRecord>.generate(10, (i) => unattended('w$i'));
      expect(
        NutritionWindowLedger.seasonScoreFactor(many),
        NutritionWindowLedger.kMinSeasonScoreFactor,
      );
    });

    test('una ventana no importante sin evidencia no penaliza', () {
      final NutritionWindowRecord soft = unattended('a').copyWith(isCritical: false);
      expect(soft.penalizes, isFalse);
      expect(NutritionWindowLedger.seasonScoreFactor([soft]), 1.0);
    });
  });
}
