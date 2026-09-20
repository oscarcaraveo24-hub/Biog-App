// test/screens/npk/npk_tab_copy_test.dart
//
// Congela las reglas del resumen de la pestaña N/P/K (Oscar, 7 sep 2026):
// máximo 50 palabras, frases completas, nutrientes con todas sus letras y
// siempre con el porqué. Se prueba contra las 32 guías curadas, no solo
// contra un ejemplo.
import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guide.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guides.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_readiness_engine.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_season_declaration.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/agro/nutrition/site_learning.dart';
import 'package:bio_g/core/agro/water/soil_water_scale.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/screens/npk/npk_tab_copy.dart';
import 'package:flutter_test/flutter_test.dart';

const AgroRange _soil = AgroRange(lowMax: 15, optimalMin: 25, optimalMax: 45, highMin: 60);
const AgroRange _ph = AgroRange(lowMax: 5.0, optimalMin: 6.0, optimalMax: 7.2, highMin: 8.0);
const AgroRange _ec = AgroRange(lowMax: 0.2, optimalMin: 0.6, optimalMax: 2.0, highMin: 3.0);
const AgroRange _res = AgroRange(lowMax: 0.1, optimalMin: 0.3, optimalMax: 1.4, highMin: 2.2);
const AgroRange _temp = AgroRange(lowMax: 8, optimalMin: 15, optimalMax: 28, highMin: 34);

/// Etapa con alta demanda de N y demanda baja de P/K.
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

/// Etapa sin demanda en el perfil: con guía, solo sus reglas abren ventana.
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

List<BioGTelemetry> _history({required int hours}) {
  final List<BioGTelemetry> out = <BioGTelemetry>[];
  for (int h = 0; h <= hours; h += 2) {
    final double hh = h.toDouble();
    final double ec = 1.0 + _diurnal(hh, 0.03);
    out.add(
      BioGTelemetry(
        deviceId: 'dev',
        timestamp: _t0.add(Duration(hours: h)),
        airTempC: 24,
        airHumidityPct: 50,
        soilMoisturePct: 32.0 + _diurnal(hh, 0.5),
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

NutritionDecision _decide({
  required String cropKey,
  required String cropLabel,
  required String stageKey,
  required String stageLabel,
  StageTargets targets = _quiet,
  bool isPerennial = false,
  List<BioGTelemetry> history = const <BioGTelemetry>[],
  NitrogenPassPlan? passes,
  SoilTexture soilTexture = SoilTexture.unknown,
}) {
  final DateTime now = _t0.add(const Duration(days: 5));
  return NutritionReadinessEngine.evaluate(
    NutritionReadinessInput(
      now: now,
      isPlanted: true,
      isGuideMode: false,
      soilTexture: soilTexture,
      seasonDeclaration: passes == null
          ? null
          : NutritionSeasonDeclaration(
              deviceId: 'dev',
              seasonKey: 'dev|$cropKey|2026-04-01',
              cropKey: cropKey,
              passes: passes,
              declaredAt: _t0,
            ),
      cropKey: cropKey,
      cropLabel: cropLabel,
      stageKey: stageKey,
      stageLabelEs: stageLabel,
      daysToStageEnd: 20,
      stageProgress01: 0.3,
      stageStartedAt: _t0.add(const Duration(days: 3)),
      targets: targets,
      guide: kNutritionGuides[cropKey],
      live: _live(now),
      deviceId: 'dev',
      seasonKey: 'dev|$cropKey|2026-04-01',
      windows: const <NutritionWindowRecord>[],
      history: history,
      learning: SiteLearningStatus.unknown,
      isPerennial: isPerennial,
    ),
  )!.decision;
}

NutrientTrend _trend(AgroMetricKey n, NativeTrend t, {int samples = 12}) =>
    NutrientTrend(nutrient: n, trend: t, samples: samples, changePct: 2);

/// Letra N/P/K suelta (fuera de fórmulas y siglas).
final RegExp _bareLetter = RegExp(
  r'(^|[^\p{L}\p{N}_₀-₉])[NPK](?![\p{L}\p{N}_₀-₉])',
  unicode: true,
);

void main() {
  group('NpkTabCopy · reglas del texto', () {
    test('las letras sueltas se escriben con todas sus letras', () {
      expect(
        NpkTabCopy.spellOutNutrients('Al plantar, P en el fondo; N ligero.'),
        'Al plantar, fósforo en el fondo; nitrógeno ligero.',
      );
      expect(NpkTabCopy.spellOutNutrients('K para tallo firme.'), 'Potasio para tallo firme.');
      expect(NpkTabCopy.spellOutNutrients('Va bien. N al final.'), 'Va bien. Nitrógeno al final.');
      // Fórmulas, siglas y códigos de etapa no se tocan.
      const String untouched = '30–60 kg/ha de P₂O₅ · ≈ 60–115 kg/ha de MAP; K₂O, KCl, NPK y V6–V8.';
      expect(NpkTabCopy.spellOutNutrients(untouched), untouched);
    });

    test('cuenta palabras, no símbolos', () {
      expect(NpkTabCopy.wordCount('uno dos tres'), 3);
      expect(NpkTabCopy.wordCount('30–60 kg/ha de P₂O₅ · ≈ 60–115 kg/ha'), 6);
      expect(NpkTabCopy.wordCount('   '), 0);
    });

    test('el resumen recorta por frases: primero el recordatorio, después el porqué, al último el cuándo', () {
      final String when = List<String>.filled(20, 'cuándo').join(' ');
      final String whyA = List<String>.filled(20, 'porqué').join(' ');
      final String whyB = List<String>.filled(15, 'más').join(' ');
      final String tail = List<String>.filled(10, 'cola').join(' ');

      // 20 + 35 + 10 = 65 → sin cola (55) → sin la segunda frase del porqué (40).
      final String s = NpkTabCopy.summarize(when: when, why: '$whyA. $whyB.', tail: tail)!;
      expect(NpkTabCopy.wordCount(s), 40);
      expect(s, isNot(contains('cola')));
      expect(s, isNot(contains('más')));
      expect(s, startsWith('Cuándo'));
      expect(s, contains('Porqué'));

      // Si con una sola frase de porqué sigue sobrando, cae el cuándo antes
      // que el porqué.
      final String longWhy = List<String>.filled(45, 'porqué').join(' ');
      final String t = NpkTabCopy.summarize(when: when, why: longWhy)!;
      expect(NpkTabCopy.wordCount(t), 45);
      expect(t, isNot(contains('cuándo')));

      // Último recurso: una sola frase más larga que el tope se corta con «…».
      final String huge = List<String>.filled(60, 'palabra').join(' ');
      final String u = NpkTabCopy.summarize(why: huge)!;
      expect(NpkTabCopy.wordCount(u), NpkTabCopy.kMaxSummaryWords);
      expect(u, endsWith('…'));
    });

    test('cada frase queda con mayúscula inicial y punto final', () {
      expect(
        NpkTabCopy.summarize(lead: <String>['solo si tu análisis sale bajo en potasio'], when: 'al plantar; ', why: 'P para raíz'),
        'Solo si tu análisis sale bajo en potasio. Al plantar. Fósforo para raíz.',
      );
      expect(NpkTabCopy.summarize(), isNull);
    });
  });

  group('NpkTabCopy · contra las 32 guías', () {
    test('ninguna ventana pasa de 50 palabras ni deja una N/P/K suelta', () {
      int windows = 0;
      for (final NutritionGuide g in kNutritionGuides.values) {
        for (final StageNutritionRule r in g.stageRules) {
          if (r.windowNutrients.isEmpty) continue;
          windows++;
          final String s = NpkTabCopy.summarize(
            when: r.timingEs,
            why: r.rationaleEs,
            tail: 'Cuando apliques no registres nada: BIO-G lo detecta.',
          )!;
          expect(
            NpkTabCopy.wordCount(s),
            lessThanOrEqualTo(NpkTabCopy.kMaxSummaryWords),
            reason: '${g.cropKey} / ${r.stageKeys.first}: $s',
          );
          expect(s, isNot(matches(_bareLetter)), reason: '${g.cropKey}: $s');
          // El porqué de la guía siempre llega, al menos su primera frase.
          final String why = (r.rationaleEs ?? '').trim();
          if (why.isNotEmpty) {
            final String firstWhy = NpkTabCopy.firstSentence(why);
            expect(
              s,
              contains(NpkTabCopy.spellOutNutrients(firstWhy).substring(0, math.min(20, firstWhy.length))),
              reason: '${g.cropKey} / ${r.stageKeys.first} perdió el porqué',
            );
          }
        }
      }
      expect(windows, greaterThan(60));
    });

    test('los textos de la guía ya vienen sin letras sueltas y en frases completas', () {
      for (final NutritionGuide g in kNutritionGuides.values) {
        for (final StageNutritionRule r in g.stageRules) {
          for (final String? t in <String?>[r.timingEs, r.rationaleEs]) {
            if (t == null || t.trim().isEmpty) continue;
            expect(t, isNot(matches(_bareLetter)), reason: '${g.cropKey}: $t');
            expect(t.trim(), endsWith('.'), reason: '${g.cropKey}: $t');
            expect(
              t,
              isNot(matches(RegExp(r'\blb\b|acre'))),
              reason: '${g.cropKey}: unidades en kg/ha, no lb/acre',
            );
          }
        }
      }
    });
  });

  group('NpkTabCopy · con el motor', () {
    test('maíz V6–V8: titular, dosis, resumen ≤ 50 palabras con cuándo y porqué, chip de importancia', () {
      final NutritionDecision d = _decide(
        cropKey: 'maize',
        cropLabel: 'Maíz',
        stageKey: 'vegMid',
        stageLabel: 'Vegetativo medio',
        targets: _nDemand,
        history: _history(hours: 24 * 5),
      );
      expect(d.state, NutritionState.actionWindow);
      final NpkTabCopy c = NpkTabCopy.build(
        nutrient: AgroMetricKey.n,
        decision: d,
        isGuide: false,
        isPlanned: false,
        hasLive: true,
        trend: _trend(AgroMetricKey.n, NativeTrend.stable),
      );
      expect(c.headline, 'Aplica nitrógeno: segunda fertilización (V6–V8)');
      expect(c.dose, '64–96 kg/ha de N · ≈ 140–210 kg/ha de urea');
      expect(c.tone, NpkTabTone.action);
      expect(c.importance, 'Importante en vegetativo medio');
      final String s = c.summary!;
      expect(NpkTabCopy.wordCount(s), lessThanOrEqualTo(50));
      expect(s, contains('Cuando la planta tiene de 6 a 8 hojas'));
      expect(s, contains('De las 6 hojas a la floración el maíz toma más de la mitad del nitrógeno'));
      expect(s, isNot(matches(_bareLetter)));
      expect(s, isNot(contains('prioridad')));
      expect(s, isNot(contains('firma')));

      // El fósforo no está en esta ventana: la pestaña lo dice con el porqué
      // de la etapa y hacia dónde va la señal, sin chip de importancia.
      final NpkTabCopy p = NpkTabCopy.build(
        nutrient: AgroMetricKey.p,
        decision: d,
        isGuide: false,
        isPlanned: false,
        hasLive: true,
        trend: _trend(AgroMetricKey.p, NativeTrend.rising),
      );
      expect(p.headline, 'Sin aplicar fósforo por ahora');
      expect(p.importance, isNull);
      expect(p.summary, contains('La señal de fósforo viene al alza.'));
      expect(NpkTabCopy.wordCount(p.summary!), lessThanOrEqualTo(50));
    });

    test('aguacate recién plantado: «Aplica fósforo: establecimiento» con dosis, cuándo y porqué en palabras', () {
      final NutritionDecision d = _decide(
        cropKey: 'avocado_tree',
        cropLabel: 'Aguacate',
        stageKey: 'planting_transplant',
        stageLabel: 'Plantación',
        isPerennial: true,
      );
      final NpkTabCopy c = NpkTabCopy.build(
        nutrient: AgroMetricKey.p,
        decision: d,
        isGuide: false,
        isPlanned: false,
        hasLive: true,
        trend: _trend(AgroMetricKey.p, NativeTrend.unknown, samples: 2),
      );
      expect(c.headline, 'Aplica fósforo: establecimiento');
      expect(c.dose, '30–60 kg/ha de P₂O₅ · ≈ 60–115 kg/ha de MAP');
      final String s = c.summary!;
      expect(NpkTabCopy.wordCount(s), lessThanOrEqualTo(50));
      expect(s, startsWith('Al plantar: el fósforo en el fondo del hoyo'));
      expect(s, contains('El árbol joven necesita echar raíz'));
      expect(s, isNot(contains(' P ')));
      expect(s, isNot(matches(_bareLetter)));
    });

    test('etapa cerrada por la guía: el resumen explica por qué no toca y cuándo vuelve a tocar', () {
      final NutritionDecision d = _decide(
        cropKey: 'apple_tree',
        cropLabel: 'Manzano',
        stageKey: 'harvest_maturity',
        stageLabel: 'Cosecha',
        isPerennial: true,
      );
      expect(d.recommendation, isNull);
      expect(d.closedWindowNoteEs, contains('no reparte fertilizante'));
      expect(d.nextWindowNoteEs, contains('Próxima ventana: post-cosecha'));
      final NpkTabCopy c = NpkTabCopy.build(
        nutrient: AgroMetricKey.n,
        decision: d,
        isGuide: false,
        isPlanned: false,
        hasLive: true,
        trend: _trend(AgroMetricKey.n, NativeTrend.stable),
      );
      expect(c.headline, 'Sin aplicar nitrógeno por ahora');
      expect(c.summary, contains('el nitrógeno cerca de la cosecha retrasa el color'));
      expect(c.summary, contains('La señal de nitrógeno se mantiene estable.'));
      expect(NpkTabCopy.wordCount(c.summary!), lessThanOrEqualTo(50));
    });

    test('ventana plegada por el plan: la pestaña de nitrógeno lo dice con esas palabras', () {
      // Maíz en V10–V12 con «una sola vez» (arcilla): el N de la temporada
      // ya se fue a V6–V8. Antes decía «Sin aplicar nitrógeno por ahora ·
      // la guía de Maíz no reparte fertilizante», que no era cierto.
      final NutritionDecision d = _decide(
        cropKey: 'maize',
        cropLabel: 'Maíz',
        stageKey: 'vegAdvanced',
        stageLabel: 'Vegetativa avanzada',
        targets: _nDemand,
        passes: NitrogenPassPlan.single,
        soilTexture: SoilTexture.clay,
      );
      expect(d.recommendation, isNull, reason: 'la ventana plegada no abre nada');
      expect(d.planNoteEs, contains('el nitrógeno de Maíz va en «Segunda fertilización (V6–V8)»'));
      expect(d.isNitrogenAlreadyDone, isFalse);
      final NpkTabCopy c = NpkTabCopy.build(
        nutrient: AgroMetricKey.n,
        decision: d,
        isGuide: false,
        isPlanned: false,
        hasLive: true,
        trend: _trend(AgroMetricKey.n, NativeTrend.stable),
      );
      expect(c.headline, 'Sin nitrógeno en esta etapa');
      expect(c.summary, startsWith('Según tu plan (una sola vez), el nitrógeno de Maíz va en «Segunda fertilización (V6–V8)».'));
      expect(c.summary, contains('icono de ajustes'));
      expect(c.summary, isNot(contains('no reparte fertilizante')));
      expect(c.summary, isNot(matches(_bareLetter)));
      expect(NpkTabCopy.wordCount(c.summary!), lessThanOrEqualTo(50));
      // El fósforo y el potasio no cambian de discurso: no toca porque van al fondo.
      final NpkTabCopy p = NpkTabCopy.build(
        nutrient: AgroMetricKey.p,
        decision: d,
        isGuide: false,
        isPlanned: false,
        hasLive: true,
        trend: _trend(AgroMetricKey.p, NativeTrend.stable),
      );
      expect(p.headline, 'Sin aplicar fósforo por ahora');

      // Y en V6–V8 la pestaña sí da la dosis completa de la temporada.
      final NutritionDecision v6 = _decide(
        cropKey: 'maize',
        cropLabel: 'Maíz',
        stageKey: 'vegMid',
        stageLabel: 'Vegetativa media',
        targets: _nDemand,
        passes: NitrogenPassPlan.single,
        soilTexture: SoilTexture.clay,
      );
      final NpkTabCopy open = NpkTabCopy.build(
        nutrient: AgroMetricKey.n,
        decision: v6,
        isGuide: false,
        isPlanned: false,
        hasLive: true,
        trend: _trend(AgroMetricKey.n, NativeTrend.stable),
      );
      expect(open.headline, 'Aplica nitrógeno: segunda fertilización (V6–V8)');
      expect(open.dose, '160–240 kg/ha de N · ≈ 350–520 kg/ha de urea');
      expect(open.summary, contains('todo el nitrógeno de la temporada'));
    });

    test('«ya fertilicé»: la pestaña de nitrógeno lo da por hecho y no reprocha nada', () {
      final NutritionDecision d = _decide(
        cropKey: 'maize',
        cropLabel: 'Maíz',
        stageKey: 'vegMid',
        stageLabel: 'Vegetativa media',
        targets: _nDemand,
        passes: NitrogenPassPlan.alreadyDone,
      );
      expect(d.isNitrogenAlreadyDone, isTrue);
      expect(d.recommendation, isNull);
      final NpkTabCopy c = NpkTabCopy.build(
        nutrient: AgroMetricKey.n,
        decision: d,
        isGuide: false,
        isPlanned: false,
        hasLive: true,
        trend: _trend(AgroMetricKey.n, NativeTrend.stable),
      );
      expect(c.headline, 'Nitrógeno ya aplicado');
      expect(c.tone, NpkTabTone.good);
      expect(c.summary, contains('ya fertilizaste'));
      expect(c.importance, isNull);
      expect(NpkTabCopy.wordCount(c.summary!), lessThanOrEqualTo(50));
    });

    test('sin cultivo, antes de sembrar y sin decisión: copys de espera', () {
      final NutrientTrend t = _trend(AgroMetricKey.k, NativeTrend.unknown, samples: 0);
      expect(
        NpkTabCopy.build(nutrient: AgroMetricKey.k, decision: null, isGuide: true, isPlanned: false, hasLive: false, trend: t).headline,
        'Sin cultivo asignado',
      );
      expect(
        NpkTabCopy.build(nutrient: AgroMetricKey.k, decision: null, isGuide: false, isPlanned: true, hasLive: false, trend: t).headline,
        'Referencia antes de sembrar',
      );
      final NpkTabCopy c = NpkTabCopy.build(nutrient: AgroMetricKey.k, decision: null, isGuide: false, isPlanned: false, hasLive: false, trend: t);
      expect(c.headline, 'Potasio en seguimiento');
      expect(c.summary, contains('potasio'));
    });
  });

  group('NpkTrendPill', () {
    test('sin señal, tendencia conocida, calibrando y estable', () {
      final NutrientTrend stable = _trend(AgroMetricKey.n, NativeTrend.stable);
      expect(NpkTrendPill.resolve(hasLive: false, trend: stable, decision: null).label, 'Sin señal');
      expect(NpkTrendPill.resolve(hasLive: true, trend: stable, decision: null).label, 'Estable');
      expect(
        NpkTrendPill.resolve(hasLive: true, trend: _trend(AgroMetricKey.n, NativeTrend.rising), decision: null).label,
        'Al alza',
      );
      expect(
        NpkTrendPill.resolve(hasLive: true, trend: _trend(AgroMetricKey.n, NativeTrend.falling), decision: null).label,
        'A la baja',
      );
      // Sin tendencia todavía: «Calibrando» con pocas lecturas o en aprendizaje;
      // «Estable» cuando ya hay lecturas y el sitio pasó el aprendizaje.
      expect(
        NpkTrendPill.resolve(hasLive: true, trend: _trend(AgroMetricKey.n, NativeTrend.unknown, samples: 2), decision: null).label,
        'Calibrando',
      );
      final NpkTrendPill later = NpkTrendPill.resolve(
        hasLive: true,
        trend: _trend(AgroMetricKey.n, NativeTrend.unknown, samples: 12),
        decision: null,
      );
      expect(later.label, 'Estable');
      expect(later.color, NpkTrendPill.stable);
      // Nada de «Sin tendencia aún».
      for (final NativeTrend t in NativeTrend.values) {
        for (final int n in <int>[0, 3, 12]) {
          final String label = NpkTrendPill.resolve(hasLive: true, trend: _trend(AgroMetricKey.p, t, samples: n), decision: null).label;
          expect(label, isNot(contains('Sin tendencia')));
        }
      }
    });

    test('en aprendizaje del sitio dice «Calibrando» aunque haya lecturas', () {
      // Etapa sin ventana (la guía de maíz cierra en espigamiento) para que
      // el aprendizaje sea el estado, no una ventana abierta.
      final NutritionDecision d = NutritionReadinessEngine.evaluate(
        NutritionReadinessInput(
          now: _t0.add(const Duration(days: 2)),
          isPlanted: true,
          isGuideMode: false,
          cropKey: 'maize',
          cropLabel: 'Maíz',
          stageKey: 'tasseling',
          stageLabelEs: 'Espigamiento',
          daysToStageEnd: 20,
          stageProgress01: 0.3,
          stageStartedAt: _t0,
          targets: _quiet,
          guide: kNutritionGuides['maize'],
          live: _live(_t0.add(const Duration(days: 2))),
          deviceId: 'dev',
          seasonKey: 'dev|maize|2026-04-01',
          windows: const <NutritionWindowRecord>[],
          history: _history(hours: 48),
          learning: SiteLearningStatus(
            isLearning: true,
            daysSinceStart: 2,
            daysLeft: 5,
            startedAt: _t0,
          ),
          isPerennial: false,
        ),
      )!.decision;
      expect(d.state, NutritionState.learning);
      final NpkTrendPill pill = NpkTrendPill.resolve(
        hasLive: true,
        trend: _trend(AgroMetricKey.n, NativeTrend.unknown, samples: 12),
        decision: d,
      );
      expect(pill.label, 'Calibrando');
      expect(pill.color, NpkTrendPill.calibrating);
      final NpkTabCopy c = NpkTabCopy.build(
        nutrient: AgroMetricKey.n,
        decision: d,
        isGuide: false,
        isPlanned: false,
        hasLive: true,
        trend: _trend(AgroMetricKey.n, NativeTrend.unknown, samples: 12),
      );
      expect(c.headline, 'Conociendo tu suelo');
      expect(c.summary, contains('En 5 días la tendencia será confiable.'));
    });
  });
}
