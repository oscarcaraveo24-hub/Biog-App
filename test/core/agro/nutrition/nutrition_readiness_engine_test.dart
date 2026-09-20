// test/core/agro/nutrition/nutrition_readiness_engine_test.dart
//
// Congela el contrato del motor de nutrición con la regla de producto que lo
// define: el agricultor no registra nada; la sonda observa; solo una ventana
// importante que TERMINA sin evidencia pesa en el score.
import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guide.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guides.dart';
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
  String cropKey = 'maize',
  String cropLabel = 'Maíz',
  String stageKey = 'vegMid',
  String stageLabel = 'Vegetativo medio',
  DateTime? stageStartedAt,
  List<BioGTelemetry> history = const <BioGTelemetry>[],
  List<NutritionWindowRecord> windows = const <NutritionWindowRecord>[],
  SiteLearningStatus learning = SiteLearningStatus.unknown,
  bool isPlanted = true,
  bool isGuideMode = false,
  NutritionGuide? guide,
  BioGTelemetry? live,
  int daysToStageEnd = 20,
  String? nextStageKey,
  String? nextStageLabel,
  bool isPerennial = false,
  String? cultivationScaleId,
}) {
  return NutritionReadinessInput(
    now: now,
    isPlanted: isPlanted,
    isGuideMode: isGuideMode,
    cropKey: cropKey,
    cropLabel: cropLabel,
    stageKey: stageKey,
    stageLabelEs: stageLabel,
    daysToStageEnd: daysToStageEnd,
    stageProgress01: 0.3,
    stageStartedAt: stageStartedAt ?? _t0.add(const Duration(days: 3)),
    targets: targets,
    nextStageKey: nextStageKey,
    nextStageLabelEs: nextStageLabel,
    guide: guide,
    live: live ?? _live(now),
    deviceId: 'dev',
    seasonKey: 'dev|$cropKey|2026-04-01',
    windows: windows,
    history: history,
    learning: learning,
    isPerennial: isPerennial,
    cultivationScaleId: cultivationScaleId,
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
      // Sin guía curada el titular nombra nutriente y etapa; nunca el
      // genérico «esta etapa necesita nutrición».
      expect(d.headlineEs, 'Aplica nitrógeno en «Vegetativo medio»');
      expect(d.tagEs, 'Aplica N');
      expect(d.recommendation?.kind, NutritionRecommendationKind.apply);
      expect(d.recommendation?.hasDose, isFalse, reason: 'sin guía no hay cifra');
      expect(d.detailEs, contains('todavía no tiene guía de dosis'));
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

  group('NutritionReadinessEngine · guía curada: copy específico y kg/ha', () {
    final NutritionGuide maize = kNutritionGuides['maize']!;

    test('V6–V8 abre nitrógeno con la ventana de la guía y la dosis en kg/ha', () {
      final DateTime now = _t0.add(const Duration(days: 5));
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(now: now, targets: _nDemand, guide: maize, history: _history(hours: 24 * 5)),
      )!.decision;

      expect(d.state, NutritionState.actionWindow);
      expect(d.headlineEs, 'Aplica nitrógeno: segunda fertilización (V6–V8)');
      expect(d.tagEs, 'Aplica N');
      expect(d.window?.windowLabelEs, 'Segunda fertilización (V6–V8)');
      expect(d.window?.displayLabelEs, 'Segunda fertilización (V6–V8)');
      expect(d.window?.isCritical, isTrue, reason: 'la regla de la guía la marca importante');

      final NutritionRecommendation rec = d.recommendation!;
      expect(rec.allNutrients, <AgroMetricKey>[AgroMetricKey.n]);
      expect(rec.doses.length, 1);
      final NutritionDoseRange n = rec.doseFor(AgroMetricKey.n)!;
      expect(n.labelEs, '64–96 kg/ha de N');
      expect(n.commercialEquivalentEs, '≈ 140–210 kg/ha de urea');
      expect(rec.doseFor(AgroMetricKey.p), isNull);
      expect(
        d.detailEs,
        startsWith(
          'Dosis orientativa (guía curada): N: 64–96 kg/ha (≈ 140–210 kg/ha de urea). '
          'Momento: cuando la planta tiene de 6 a 8 hojas (V6–V8',
        ),
      );
      expect(d.detailEs, contains('Maíz en «Vegetativo medio»: de las 6 hojas a la floración'));
      // El porqué viaja estructurado para la pestaña N/P/K.
      expect(rec.rationaleEs, startsWith('De las 6 hojas a la floración'));
      expect(rec.timingEs, startsWith('Cuando la planta tiene de 6 a 8 hojas'));
      expect(d.detailEs, contains('no necesitas registrar nada'));
      expect(rec.headlineForNutrient(AgroMetricKey.n), d.headlineEs);
      expect(d.reasons.first, contains('abre la ventana «Segunda fertilización (V6–V8)»'));
    });

    test('la fertilización de fondo abre N, P y K; el K condicionado no va en el titular', () {
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(
          now: _t0.add(const Duration(days: 2)),
          targets: _quiet,
          guide: maize,
          stageKey: 'germination',
          stageLabel: 'Germinación',
          stageStartedAt: _t0,
        ),
      )!.decision;

      expect(d.state, NutritionState.actionWindow);
      final NutritionRecommendation rec = d.recommendation!;
      expect(rec.allNutrients, <AgroMetricKey>[AgroMetricKey.n, AgroMetricKey.p, AgroMetricKey.k]);
      expect(rec.headlineNutrients, <AgroMetricKey>[AgroMetricKey.n, AgroMetricKey.p]);
      expect(d.headlineEs, 'Aplica nitrógeno y fósforo: fertilización de fondo');
      expect(d.tagEs, 'Aplica N + P');
      expect(rec.doseFor(AgroMetricKey.k)?.isConditional, isTrue);
      expect(rec.doseFor(AgroMetricKey.p)?.labelEs, '50–80 kg/ha de P₂O₅');
      expect(rec.headlineForNutrient(AgroMetricKey.p), 'Aplica fósforo: fertilización de fondo');
      expect(d.detailEs, contains('K₂O: hasta 60 kg/ha'));
      expect(d.detailEs, contains('solo si tu análisis de suelo sale bajo en potasio'));
      expect(d.window?.nutrients.length, 3, reason: 'la ventana del libro lleva los tres');
      expect(d.window?.isCritical, isFalse);
    });

    test('en el fondo, la urea descuenta el nitrógeno que ya trae el MAP', () {
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(
          now: _t0.add(const Duration(days: 2)),
          targets: _quiet,
          guide: maize,
          stageKey: 'germination',
          stageLabel: 'Germinación',
          stageStartedAt: _t0,
        ),
      )!.decision;

      final NutritionRecommendation rec = d.recommendation!;
      // La dosis de la guía no se toca: sigue siendo el 33 % del plan de N.
      expect(rec.doseFor(AgroMetricKey.n)!.labelEs, '53–79 kg/ha de N');
      // Lo que cambia es el saco: el MAP que cubre el fósforo lleva 11 % de N.
      expect(
        rec.doseFor(AgroMetricKey.n)!.commercialEquivalentEs,
        '≈ 90–135 kg/ha de urea',
      );
      expect(
        rec.rulesEs.first,
        'El MAP de esta aplicación ya aporta 11–17 kg/ha de nitrógeno; la '
        'cifra de urea de arriba ya lo tiene descontado.',
      );
    });

    test('en BIO-G Huerto la misma dosis se dice en g/m²', () {
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(
          now: _t0.add(const Duration(days: 5)),
          targets: _nDemand,
          guide: maize,
          history: _history(hours: 24 * 5),
          // «orchard» es el id que el onboarding guarda para «Huerto»: antes
          // se le escapaba a la conversión y el huerto veía kg/ha de campo.
          cultivationScaleId: 'orchard',
        ),
      )!.decision;

      final NutritionDoseRange n = d.recommendation!.doseFor(AgroMetricKey.n)!;
      expect(n.unit, DoseUnit.gramsPerSquareMeter);
      expect(n.labelEs, '6.4–9.6 g/m² de N');
      expect(n.commercialEquivalentEs, '≈ 14–21 g/m² de urea');
      expect(n.transparencyEs, contains('1 kg/ha = 0.1 g/m²'));
    });

    test('tomate vegetativo: N es el foco; P y K acompañan con su reparto', () {
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(
          now: _t0.add(const Duration(days: 20)),
          targets: _quiet,
          cropKey: 'tomato',
          cropLabel: 'Tomate',
          guide: kNutritionGuides['tomato']!,
          stageKey: 'vegetativo',
          stageLabel: 'Vegetativo',
        ),
      )!.decision;

      expect(d.state, NutritionState.actionWindow);
      expect(d.headlineEs, 'Aplica nitrógeno: vegetativo');
      expect(d.tagEs, 'Aplica N');
      final NutritionRecommendation rec = d.recommendation!;
      expect(rec.allNutrients, <AgroMetricKey>[AgroMetricKey.n]);
      expect(rec.companionNutrients, <AgroMetricKey>[AgroMetricKey.p, AgroMetricKey.k]);
      expect(rec.coversNutrient(AgroMetricKey.k), isFalse);
      expect(rec.mentionsNutrient(AgroMetricKey.k), isTrue);
      expect(rec.doseFor(AgroMetricKey.n)?.labelEs, '49–65 kg/ha de N');
      expect(rec.doseFor(AgroMetricKey.k)?.labelEs, '18–27 kg/ha de K₂O');
      expect(rec.headlineForNutrient(AgroMetricKey.k), 'Acompaña con potasio: vegetativo');
      expect(d.detailEs, startsWith('Dosis orientativa (guía curada): N: 45–60 kg/ha'));
      expect(d.detailEs, contains('Acompaña con: P₂O₅: 12–20 kg/ha'));
      expect(d.window?.nutrients, <AgroMetricKey>[AgroMetricKey.n], reason: 'el libro observa solo el foco');
    });

    test('con guía, el perfil NO abre ventanas que la guía no contempla', () {
      // El perfil heredado marca N alto en floración; la guía cierra la
      // ventana desde espigamiento. Antes esto abría una ventana importante
      // y la sentenciaba «sin evidencia» contra el productor.
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(
          now: _t0.add(const Duration(days: 40)),
          targets: _nDemand,
          guide: maize,
          stageKey: 'flowerSet',
          stageLabel: 'Floración',
          history: _history(hours: 24 * 8),
        ),
      )!.decision;

      expect(d.state, NutritionState.monitor);
      expect(d.window, isNull);
      expect(d.recommendation, isNull);
      final NutrientStagePriority n = d.priorities.firstWhere((p) => p.nutrient == AgroMetricKey.n);
      expect(n.priority, NutritionPriority.medium);
      expect(n.priority01, lessThan(NutritionPriorityX.kHighPriorityThreshold01));
      expect(n.isCriticalWindow, isFalse);
      expect(d.headlineEs, 'Suelo estable, sin necesidades nutrimentales por ahora');
      expect(d.detailEs, contains('En «Espigamiento y floración» la guía de Maíz no reparte fertilizante'));
      expect(d.detailEs, contains('No quedan ventanas de fertilización en este ciclo.'));
      expect(d.reasons.first, contains('no abre ventana'));
    });

    test('sin guía el perfil sigue mandando (misma etapa abre por prioridad)', () {
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(
          now: _t0.add(const Duration(days: 40)),
          targets: _nDemand,
          stageKey: 'flowerSet',
          stageLabel: 'Floración',
        ),
      )!.decision;
      expect(d.state, NutritionState.actionWindow);
      expect(d.headlineEs, 'Aplica nitrógeno en «Floración»');
    });

    test('suelo seco: la ventana sigue abierta pero el copy dice «prepara»', () {
      final DateTime now = _t0.add(const Duration(days: 5));
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(
          now: now,
          targets: _nDemand,
          guide: maize,
          live: _live(now).copyWith(soilMoisturePct: 6),
        ),
      )!.decision;

      expect(d.state, NutritionState.prepare);
      expect(d.awaitingEvidence, isTrue);
      expect(
        d.headlineEs,
        'Prepara nitrógeno: segunda fertilización (V6–V8), todavía no apliques',
      );
      expect(d.tagEs, 'Prepara N');
      expect(d.recommendation?.kind, NutritionRecommendationKind.prepare);
      expect(d.detailEs, startsWith('Dosis orientativa (guía curada): N: 64–96 kg/ha'));
      expect(d.detailEs, contains('Todavía no apliques'));
      expect(d.scoreFactor, 1.0);
    });

    test('la ventana que se acerca se anuncia con su nombre y su dosis prevista', () {
      final NutritionGuide apple = kNutritionGuides['apple_tree']!;
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(
          now: _t0.add(const Duration(days: 5)),
          targets: _quiet,
          cropKey: 'apple_tree',
          cropLabel: 'Manzano',
          guide: apple,
          stageKey: 'dormancy',
          stageLabel: 'Reposo',
          daysToStageEnd: 6,
          nextStageKey: 'budbreak',
          nextStageLabel: 'Brotación',
          isPerennial: true,
        ),
      )!.decision;

      expect(d.state, NutritionState.prepare);
      expect(d.awaitingEvidence, isFalse);
      expect(d.headlineEs, 'Se acerca nitrógeno: después de floración');
      expect(d.tagEs, 'Pronto N');
      final NutritionRecommendation rec = d.recommendation!;
      expect(rec.kind, NutritionRecommendationKind.upcoming);
      expect(rec.inDays, 6);
      expect(rec.doses.length, 1);
      // kg/ha de huerta, desde la guía del manzano; nada de cosecha por árbol.
      final NutritionDoseRange n = rec.doseFor(AgroMetricKey.n)!;
      expect(n.unit, DoseUnit.kgPerHectare);
      expect(n.labelEs, '35–70 kg/ha de N');
      expect(n.transparencyEs, contains('50 % del plan de temporada'));
      expect(d.detailEs, startsWith('En ~6 días entra «Brotación»'));
      expect(d.detailEs, contains('Dosis orientativa prevista: N:'));
      expect(d.upcomingWindowInDays, 6);
    });

    test('frutal: cada ventana lleva su fracción del plan anual de la huerta', () {
      final NutritionGuide apple = kNutritionGuides['apple_tree']!;
      NutritionDecision at(String stage, String label) => NutritionReadinessEngine.evaluate(
        _input(
          now: _t0.add(const Duration(days: 5)),
          targets: _quiet,
          cropKey: 'apple_tree',
          cropLabel: 'Manzano',
          guide: apple,
          stageKey: stage,
          stageLabel: label,
          isPerennial: true,
        ),
      )!.decision;

      final NutritionDoseRange spring = at('budbreak', 'Brotación').recommendation!.doseFor(AgroMetricKey.n)!;
      final NutritionDoseRange autumn = at('post_harvest', 'Post-cosecha').recommendation!.doseFor(AgroMetricKey.n)!;
      expect(spring.labelEs, '35–70 kg/ha de N');
      expect(autumn.labelEs, '35–70 kg/ha de N');
      expect(
        spring.max,
        closeTo(autumn.max, 1e-9),
        reason: 'NMSU: la mitad tras floración y la mitad tras cosecha',
      );
      expect(
        at('budbreak', 'Brotación').headlineEs,
        'Aplica nitrógeno: después de floración',
      );
      expect(
        at('post_harvest', 'Post-cosecha').headlineEs,
        'Aplica nitrógeno y fósforo: post-cosecha',
      );
      // Ningún copy pide la cosecha esperada por árbol: la dosis no depende
      // de ella (decisión de producto, 6 sep 2026).
      expect(at('budbreak', 'Brotación').detailEs, isNot(contains('cosecha esperada')));
      final NutritionDecision young = at('planting_transplant', 'Plantación');
      expect(young.headlineEs, 'Aplica fósforo: establecimiento');
      // El fósforo del frutal quedó condicionado al análisis foliar: NMSU es
      // categórico en que los frutales no responden a la fertilización
      // fosfatada, así que el plan arranca en 0 y se muestra como condición.
      expect(
        young.recommendation!.doseFor(AgroMetricKey.p)?.labelEs,
        'hasta 30 kg/ha de P₂O₅',
      );
      expect(young.detailEs, isNot(contains('cosecha esperada')));
    });

    test('cebada en llenado de grano: el perfil alto de K ya no abre ventana', () {
      const StageTargets kHigh = StageTargets(
        moistureRaw: _soil,
        soilTemp: _temp,
        ph: _ph,
        ec: _ec,
        resistance: _res,
        nIndex: AgroRange(lowMax: 0, optimalMin: 10, optimalMax: 30, highMin: 40),
        pIndex: AgroRange(lowMax: 0, optimalMin: 10, optimalMax: 30, highMin: 40),
        kIndex: AgroRange(lowMax: 0, optimalMin: 10, optimalMax: 30, highMin: 40),
        nPriority: 0.46,
        pPriority: 0.52,
        kPriority: 0.80,
      );
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        _input(
          now: _t0.add(const Duration(days: 60)),
          targets: kHigh,
          cropKey: 'barley',
          cropLabel: 'Cebada',
          guide: kNutritionGuides['barley']!,
          stageKey: 'grainFill',
          stageLabel: 'Llenado de grano',
        ),
      )!.decision;
      expect(d.window, isNull);
      expect(d.state, NutritionState.monitor);
      expect(d.priorities.every((p) => p.priority != NutritionPriority.high), isTrue);
      expect(d.detailEs, contains('la guía de Cebada no reparte fertilizante'));
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
      expect(d.headlineEs, 'Nutrición atendida: «Vegetativo medio»');
      expect(d.tagEs, 'Atendida');
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
      expect(d.headlineEs, 'Sin evidencia de fertilización: «Vegetativo medio»');
      expect(d.tagEs, 'Sin evidencia');
      expect(
        d.detailEs,
        startsWith(
          'Esta ventana nutricional no mostró evidencia suficiente de haber sido atendida',
        ),
      );
      expect(d.detailEs, contains('No es una certeza de que no fertilizaste'));
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
