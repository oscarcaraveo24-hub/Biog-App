// test/core/agro/nutrition/nutrition_plan_resolver_test.dart
//
// El resolver del plan de nitrógeno (decisión de producto, 13 sep 2026):
// guía × textura × declaración → guía efectiva. Aquí se congela la
// aritmética del plegado por PRIORIDAD agronómica (17 sep 2026: «una sola
// vez» en maíz cae en V6–V8, no en la siembra), los guardarraíles (arena
// escala el mínimo), la cuarta opción «ya fertilicé» y el tono tras una
// respuesta mayor de lo habitual.
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guide.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guides.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_plan_resolver.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_readiness_engine.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_season_declaration.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/agro/water/soil_water_scale.dart';
import 'package:flutter_test/flutter_test.dart';

NutritionGuide _guide(String key) => kNutritionGuides[key]!;

NutritionSeasonDeclaration _decl(
  String crop,
  NitrogenPassPlan passes, {
  String seasonKey = 'dev|crop|2026-04-01',
}) => NutritionSeasonDeclaration(
  deviceId: 'dev',
  seasonKey: seasonKey,
  cropKey: crop,
  passes: passes,
  declaredAt: DateTime(2026, 4, 2),
);

NitrogenPassOption _opt(NutritionPlanResolution r, NitrogenPassPlan p) =>
    r.optionFor(p)!;

double _nShare(NutritionGuide g, String stage) =>
    g.ruleForStage(stage)?.seasonShare[AgroMetricKey.n] ?? 0.0;

void main() {
  group('opciones · maíz (2 mín., 1 en arcilla, 3 en arena)', () {
    test('sin textura: la única no aplica, dos y tres sí, ★ en tres', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('maize'),
      );
      expect(r.planPasses, 3);
      expect(r.effectiveMinPasses, 2);
      expect(_opt(r, NitrogenPassPlan.single).enabled, isFalse);
      expect(_opt(r, NitrogenPassPlan.single).disabledReasonEs, contains('al menos 2'));
      expect(_opt(r, NitrogenPassPlan.two).enabled, isTrue);
      expect(_opt(r, NitrogenPassPlan.threeOrMore).enabled, isTrue);
      expect(_opt(r, NitrogenPassPlan.threeOrMore).recommended, isTrue);
      // La cuarta tarjeta siempre está y nunca lleva ★.
      expect(_opt(r, NitrogenPassPlan.alreadyDone).enabled, isTrue);
      expect(_opt(r, NitrogenPassPlan.alreadyDone).recommended, isFalse);
      expect(r.options.last.plan, NitrogenPassPlan.alreadyDone);
      expect(r.canDeclare, isTrue);
      expect(r.declarationApplied, isFalse);
      expect(identical(r.guide, r.baseGuide), isTrue, reason: 'sin cambios: misma guía');
      // Sin declaración, el plan conserva las tres ventanas de la guía.
      expect(r.keptStageKeys, <String>['germination', 'vegearly', 'vegadvanced']);
      expect(r.keptWindowLabelsEs.first, 'Fertilización de fondo');
    });

    test('arcilla relaja a 1: la única se habilita con la salvedad positiva', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('maize'),
        texture: SoilTexture.clay,
      );
      expect(r.textureClass, SoilTextureClass.fine);
      expect(r.effectiveMinPasses, 1);
      final NitrogenPassOption single = _opt(r, NitrogenPassPlan.single);
      expect(single.enabled, isTrue);
      expect(single.warningEs, contains('suelo pesado'));
    });

    test('arena escala a 3: solo queda el plan completo y no hay nada que preguntar', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('maize'),
        texture: SoilTexture.sandyLoam,
      );
      expect(r.effectiveMinPasses, 3);
      expect(_opt(r, NitrogenPassPlan.single).enabled, isFalse);
      expect(_opt(r, NitrogenPassPlan.single).disabledReasonEs, contains('se lava'));
      expect(_opt(r, NitrogenPassPlan.two).enabled, isFalse);
      expect(_opt(r, NitrogenPassPlan.threeOrMore).enabled, isTrue);
      expect(
        r.canDeclare,
        isFalse,
        reason: '«ya fertilicé» está disponible pero no justifica preguntar',
      );
    });
  });

  group('plegado · maíz', () {
    test('prioridad agronómica: V6–V8 antes que la siembra y que V10–V12', () {
      final NutritionGuide maize = _guide('maize');
      expect(
        maize.nitrogenRulesByPriority.map((r) => r.labelEs!).toList(),
        <String>[
          'Segunda fertilización (V6–V8)',
          'Fertilización de fondo',
          'Tercera fertilización (V10–V12)',
        ],
      );
      // La opción «una sola vez» lo dice en su ayuda.
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: maize,
        texture: SoilTexture.clay,
      );
      expect(_opt(r, NitrogenPassPlan.single).helperEs, contains('V6–V8'));
      expect(_opt(r, NitrogenPassPlan.two).helperEs, 'fertilización de fondo y segunda fertilización (V6–V8)');
    });

    test('«una sola vez» en arcilla: todo el N cae en V6–V8, no en la siembra', () {
      final NutritionGuide base = _guide('maize');
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: base,
        texture: SoilTexture.clay,
        declaration: _decl('maize', NitrogenPassPlan.single),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(r.declarationApplied, isTrue);
      final NutritionGuide g = r.guide!;
      expect(identical(g, base), isFalse);

      // V6–V8 absorbe 0.33 (fondo) + 0.40 + 0.27 (V10–V12) = 1.00.
      expect(_nShare(g, 'vegEarly'), closeTo(1.0, 1e-9));
      expect(_nShare(g, 'germination'), 0.0);
      expect(_nShare(g, 'vegAdvanced'), 0.0);
      expect(r.foldedStageKeys, <String>{'germination', 'vegadvanced'});
      expect(r.keptStageKeys, <String>['vegearly']);
      expect(r.keptWindowLabelsEs, <String>['Segunda fertilización (V6–V8)']);
      expect(
        r.planNoteEs,
        'Según tu plan (una sola vez), el nitrógeno de Maíz va en «Segunda '
        'fertilización (V6–V8)».',
      );

      // V6–V8 abre ventana de N; V10–V12 ya no abre nada; el fondo sigue
      // abierto para fósforo y potasio, sin nitrógeno.
      expect(g.ruleForStage('vegMid')!.windowNutrients, contains(AgroMetricKey.n));
      expect(g.ruleForStage('vegMid')!.isCritical, isTrue);
      expect(g.ruleForStage('vegAdvanced')!.windowNutrients, isEmpty);
      expect(g.ruleForStage('vegAdvanced')!.isCritical, isFalse, reason: 'sin ventana no pesa');
      expect(g.ruleForStage('vegAdvanced')!.rationaleEs, startsWith('Según tu plan (una sola vez)'));
      expect(g.ruleForStage('vegAdvanced')!.rationaleEs, contains('no toca aplicar nitrógeno'));
      expect(
        g.ruleForStage('germination')!.windowNutrients,
        <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.k},
      );

      // La dosis de la pasada única es el plan completo: 160–240 kg N/ha.
      final NutritionDoseRange dose = g.windowDoseFor(
        nutrient: AgroMetricKey.n,
        stageKey: 'vegEarly',
      )!;
      expect(dose.min, closeTo(160, 1e-6));
      expect(dose.max, closeTo(240, 1e-6));
      expect(dose.unit, DoseUnit.kgPerHectare);
      expect(dose.commercialEquivalentEs!.toLowerCase(), contains('urea'));
      expect(g.windowDoseFor(nutrient: AgroMetricKey.n, stageKey: 'germination'), isNull);

      // Y la regla de incorporación va primero.
      final StageNutritionRule v6 = g.ruleForStage('vegEarly')!;
      expect(v6.rulesEs.first, NutritionWindowPlanResolver.incorporationRuleEs);
      expect(v6.rationaleEs, startsWith('Según tu plan (una sola vez), aquí va todo el nitrógeno'));
      expect(r.reasonsEs.single, contains('una sola ventana'));

      // P y K no se tocan.
      final StageNutritionRule fondo = g.ruleForStage('germination')!;
      expect(fondo.seasonShare[AgroMetricKey.p], 1.0);
      expect(fondo.seasonShare[AgroMetricKey.k], 1.0);
      expect(fondo.seasonShare.containsKey(AgroMetricKey.n), isFalse);
    });

    test('«ya fertilicé»: ninguna ventana de N queda por delante', () {
      final NutritionGuide base = _guide('maize');
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: base,
        declaration: _decl('maize', NitrogenPassPlan.alreadyDone),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(r.declarationApplied, isTrue);
      expect(r.isAlreadyDone, isTrue);
      expect(r.keptStageKeys, isEmpty);
      expect(r.foldedStageKeys, <String>{'germination', 'vegearly', 'vegadvanced'});
      final NutritionGuide g = r.guide!;
      expect(g.nitrogenPassCount, 0);
      for (final String stage in <String>['germination', 'vegEarly', 'vegAdvanced']) {
        expect(g.ruleForStage(stage)!.windowNutrients, isNot(contains(AgroMetricKey.n)), reason: stage);
        expect(g.windowDoseFor(nutrient: AgroMetricKey.n, stageKey: stage), isNull, reason: stage);
      }
      // El fondo sigue abierto para fósforo y potasio; V6–V8 y V10–V12 ya
      // no abren nada ni pesan.
      expect(g.ruleForStage('germination')!.windowNutrients, isNotEmpty);
      expect(g.ruleForStage('vegMid')!.windowNutrients, isEmpty);
      expect(g.ruleForStage('vegMid')!.isCritical, isFalse);
      expect(r.planNoteEs, contains('ya fertilizaste'));
      expect(r.reasonsEs.single, contains('no queda ninguna ventana de nitrógeno'));
      // La declaración se refleja en la opción vigente.
      expect(r.activeOption?.plan, NitrogenPassPlan.alreadyDone);
    });

    test('«dos veces»: la segunda absorbe la tercera (0.40 + 0.27)', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('maize'),
        texture: SoilTexture.loam,
        declaration: _decl('maize', NitrogenPassPlan.two),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(r.declarationApplied, isTrue);
      final NutritionGuide g = r.guide!;
      expect(_nShare(g, 'germination'), closeTo(0.33, 1e-9));
      expect(_nShare(g, 'vegEarly'), closeTo(0.67, 1e-9));
      expect(_nShare(g, 'vegAdvanced'), 0.0);
      expect(r.foldedStageKeys, <String>{'vegadvanced'});
      expect(r.keptStageKeys, <String>['germination', 'vegearly']);
      expect(g.ruleForStage('vegEarly')!.isCritical, isTrue, reason: 'conserva su criticidad');
      expect(
        g.ruleForStage('vegEarly')!.rationaleEs,
        startsWith(
          'Según tu plan (dos veces), aquí va también el nitrógeno de '
          '«Tercera fertilización (V10–V12)».',
        ),
      );
      expect(r.reasonsEs.single, contains('«Fertilización de fondo» y «Segunda fertilización (V6–V8)»'));
    });

    test('el N de una ventana plegada va a la conservada anterior más cercana', () {
      // Tomate «dos veces»: se conservan vegetativo y floración (las dos
      // mejores). El N del trasplante (antes de ambas) sube a vegetativo; el
      // del llenado (después) baja a floración.
      final NutritionPlanResolution tomato = NutritionWindowPlanResolver.resolve(
        guide: _guide('tomato'),
        texture: SoilTexture.clay,
        declaration: _decl('tomato', NitrogenPassPlan.two),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(tomato.declarationApplied, isTrue);
      expect(tomato.keptStageKeys, <String>['vegetativo', 'floracion']);
      expect(_nShare(tomato.guide!, 'vegetativo'), closeTo(0.13 + 0.27, 1e-9));
      expect(_nShare(tomato.guide!, 'floracion'), closeTo(0.35 + 0.25, 1e-9));
      expect(_nShare(tomato.guide!, 'germinacion'), 0.0);
      expect(_nShare(tomato.guide!, 'llenado'), 0.0);
      // El trasplante sigue abriendo fósforo; el llenado sigue abriendo potasio.
      expect(tomato.guide!.ruleForStage('germinacion')!.windowNutrients, contains(AgroMetricKey.p));
      expect(tomato.guide!.ruleForStage('llenado')!.windowNutrients, contains(AgroMetricKey.k));

      // Nogal «dos veces»: marzo + junio; el 20 % de agosto baja a junio
      // (≈ 55/45, como INIFAP PT-0008, NMSU y UGA).
      final NutritionPlanResolution pecan = NutritionWindowPlanResolver.resolve(
        guide: _guide('walnut_tree'),
        texture: SoilTexture.loam,
        declaration: _decl('walnut_tree', NitrogenPassPlan.two),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(pecan.keptStageKeys, <String>['budbreak', 'flowering']);
      expect(_nShare(pecan.guide!, 'budbreak'), closeTo(0.55, 1e-9));
      expect(_nShare(pecan.guide!, 'fruit_set'), closeTo(0.45, 1e-9));
      expect(_nShare(pecan.guide!, 'fruit_fill'), 0.0);
      expect(pecan.guide!.ruleForStage('fruit_fill')!.windowNutrients, <AgroMetricKey>{AgroMetricKey.k});

      // Pistache «dos veces»: crecimiento del fruto + llenado, 50/50 (CDFA).
      final NutritionPlanResolution pist = NutritionWindowPlanResolver.resolve(
        guide: _guide('pistachio_tree'),
        declaration: _decl('pistachio_tree', NitrogenPassPlan.two),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(pist.keptStageKeys, <String>['flowering', 'fruitfill']);
      expect(_nShare(pist.guide!, 'fruit_set'), closeTo(0.5, 1e-9));
      expect(_nShare(pist.guide!, 'fruit_fill'), closeTo(0.5, 1e-9));

      // Mango «dos veces»: post-cosecha (la grande) + cuajado; el 10 % de
      // brotación sube al cuajado (después: antes no hay ninguna).
      final NutritionPlanResolution mango = NutritionWindowPlanResolver.resolve(
        guide: _guide('mango_tree'),
        declaration: _decl('mango_tree', NitrogenPassPlan.two),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(mango.keptStageKeys, <String>['fruitset', 'postharvest'], reason: 'claves normalizadas');
      expect(_nShare(mango.guide!, 'fruit_set'), closeTo(0.35, 1e-9));
      expect(_nShare(mango.guide!, 'post_harvest'), closeTo(0.65, 1e-9));
    });

    test('«tres o más» coincide con el plan: guía intacta', () {
      final NutritionGuide base = _guide('maize');
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: base,
        declaration: _decl('maize', NitrogenPassPlan.threeOrMore),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(r.declarationApplied, isTrue);
      expect(identical(r.guide, base), isTrue);
      expect(r.foldedStageKeys, isEmpty);
    });

    test('la declaración guardada con el id de la app (crop_…) sí aplica', () {
      // Regresión (14 sep 2026): la app guarda `crop_avocado_tree` y la guía
      // se llama `avocado_tree`; comparar los textos crudos hacía que la
      // pregunta volviera a salir cada vez que se entraba a NPK.
      final NutritionGuide base = _guide('avocado_tree');
      for (final String stored in <String>[
        'crop_avocado_tree',
        'avocado_tree',
        'avocadoTree',
        'AVOCADO_TREE',
      ]) {
        final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
          guide: base,
          declaration: _decl(stored, NitrogenPassPlan.threeOrMore),
          seasonKey: 'dev|crop|2026-04-01',
        );
        expect(r.declarationApplied, isTrue, reason: 'cropKey guardado: $stored');
      }
      // Otro cultivo sigue sin aplicar.
      final NutritionPlanResolution other = NutritionWindowPlanResolver.resolve(
        guide: base,
        declaration: _decl('crop_maize', NitrogenPassPlan.threeOrMore),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(other.declarationApplied, isFalse);
    });

    test('la declaración de otra temporada no aplica', () {
      final NutritionGuide base = _guide('maize');
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: base,
        texture: SoilTexture.clay,
        declaration: _decl('maize', NitrogenPassPlan.single, seasonKey: 'dev|crop|2025-04-01'),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(r.declarationApplied, isFalse);
      expect(identical(r.guide, base), isTrue);
    });

    test('una declaración que dejó de aplicar (arena) se ignora y se explica', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('maize'),
        texture: SoilTexture.sandy,
        declaration: _decl('maize', NitrogenPassPlan.single),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(r.declarationApplied, isFalse);
      expect(r.reasonsEs.single, contains('ya no aplica'));
    });
  });

  group('guardarraíles por cultivo', () {
    test('cebolla: la única no cabe; dos sí en suelo medio y pesado, tres en arena', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('onion'),
      );
      expect(r.effectiveMinPasses, 2);
      expect(_opt(r, NitrogenPassPlan.single).enabled, isFalse);
      expect(_opt(r, NitrogenPassPlan.two).enabled, isTrue);
      // El tope de 112 kg N/ha vale para cada pasada (PNW 546 / CDFA): con
      // el plan al máximo la pasada grande (0.65 × 200 = 130) lo rebasa, y
      // la opción lo avisa sin cerrarse (al mínimo, 0.65 × 150 = 98, cabe).
      expect(_opt(r, NitrogenPassPlan.two).warningEs, contains('112'));
      expect(_opt(r, NitrogenPassPlan.two).warningEs, contains('130'));
      expect(_opt(r, NitrogenPassPlan.threeOrMore).enabled, isTrue);
      expect(_opt(r, NitrogenPassPlan.threeOrMore).recommended, isTrue);
      expect(r.canDeclare, isTrue);
      // «Dos veces» conserva hoja + inicio de bulbo (las dos mejores), y el
      // N del fondo sube a la de hoja; el aviso del tope viaja con esa regla.
      final NutritionPlanResolution two = NutritionWindowPlanResolver.resolve(
        guide: _guide('onion'),
        declaration: _decl('onion', NitrogenPassPlan.two),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(two.keptStageKeys, <String>['vegetativo', 'induccionbulbificacion']);
      expect(_nShare(two.guide!, 'vegetativo'), closeTo(0.65, 1e-9));
      expect(_nShare(two.guide!, 'induccionBulbificacion'), closeTo(0.35, 1e-9));
      expect(two.guide!.ruleForStage('vegetativo')!.rulesEs.any((s) => s.contains('112')), isTrue);
      // En lechuga el tope de 45 es de arranque, no de cobertera: «dos veces»
      // no se cierra por él.
      final NutritionPlanResolution lettuce = NutritionWindowPlanResolver.resolve(
        guide: _guide('lettuce'),
      );
      expect(_opt(lettuce, NitrogenPassPlan.two).enabled, isTrue);
      expect(_opt(lettuce, NitrogenPassPlan.two).warningEs, isNull);

      final NutritionPlanResolution sand = NutritionWindowPlanResolver.resolve(
        guide: _guide('onion'),
        texture: SoilTexture.sandy,
      );
      expect(sand.effectiveMinPasses, 3);
      expect(_opt(sand, NitrogenPassPlan.two).enabled, isFalse);
      expect(sand.canDeclare, isFalse, reason: 'una sola opción de número: no se pregunta');
    });

    test('cítricos: conviene fraccionar, mínimo 2 (3 en arena), ★ en tres', () {
      for (final String key in <String>['orange_tree', 'lemon_tree']) {
        final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(guide: _guide(key));
        expect(_opt(r, NitrogenPassPlan.single).enabled, isFalse, reason: key);
        expect(_opt(r, NitrogenPassPlan.two).enabled, isTrue, reason: key);
        expect(_opt(r, NitrogenPassPlan.threeOrMore).recommended, isTrue, reason: key);
        expect(r.canDeclare, isTrue, reason: key);
        final NutritionPlanResolution sand = NutritionWindowPlanResolver.resolve(
          guide: _guide(key),
          texture: SoilTexture.sandyLoam,
        );
        expect(_opt(sand, NitrogenPassPlan.two).enabled, isFalse, reason: key);
      }
    });

    test('trigo (2 ventanas): la única no aplica y «dos» es el plan → nada que preguntar', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('wheat'),
      );
      expect(r.planPasses, 2);
      expect(r.options.map((o) => o.plan), <NitrogenPassPlan>[
        NitrogenPassPlan.single,
        NitrogenPassPlan.two,
        NitrogenPassPlan.alreadyDone,
      ]);
      expect(_opt(r, NitrogenPassPlan.single).enabled, isFalse);
      expect(_opt(r, NitrogenPassPlan.two).recommended, isTrue);
      expect(r.canDeclare, isFalse);
    });

    test('cebada maltera: ★ en la única (NDSU) y «dos» también vale', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('barley'),
      );
      expect(_opt(r, NitrogenPassPlan.single).enabled, isTrue);
      expect(_opt(r, NitrogenPassPlan.single).recommended, isTrue);
      expect(_opt(r, NitrogenPassPlan.single).warningEs, isNull);
      expect(_opt(r, NitrogenPassPlan.single).helperEs, contains('siembra'));
      expect(_opt(r, NitrogenPassPlan.two).enabled, isTrue);
      expect(r.canDeclare, isTrue);
      // La única cae en la siembra (NDSU, INIFAP Alina, CINVESTAV ¹⁵N).
      final NutritionPlanResolution one = NutritionWindowPlanResolver.resolve(
        guide: _guide('barley'),
        declaration: _decl('barley', NitrogenPassPlan.single),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(one.keptStageKeys, <String>['germination']);
      expect(_nShare(one.guide!, 'germination'), closeTo(1.0, 1e-9));
      expect(one.guide!.ruleForStage('tillering')!.windowNutrients, isEmpty);
    });

    test('frijol «una sola vez» cae en vegetativo (Henson & Bliss), no en la siembra', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('bean'),
        declaration: _decl('bean', NitrogenPassPlan.single),
        seasonKey: 'dev|crop|2026-04-01',
      );
      expect(r.declarationApplied, isTrue);
      final NutritionGuide g = r.guide!;
      expect(_nShare(g, 'vegEarly'), closeTo(1.0, 1e-9));
      expect(_nShare(g, 'germination'), 0.0);
      expect(g.ruleForStage('germination')!.windowNutrients, isNot(contains(AgroMetricKey.n)));
      expect(_opt(r, NitrogenPassPlan.single).helperEs, contains('escarda'));
    });

    test('nogal en arcilla: la única se habilita con el tope de 120 kg N/ha', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('walnut_tree'),
        texture: SoilTexture.clayLoam,
      );
      final NitrogenPassOption single = _opt(r, NitrogenPassPlan.single);
      expect(single.enabled, isTrue);
      expect(single.warningEs, contains('120'));
    });

    test('sin clasificación (rosal, girasol) no hay opciones ni plegado', () {
      for (final String key in <String>['rose', 'sunflower', 'marigold']) {
        final NutritionGuide base = _guide(key);
        final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
          guide: base,
          declaration: _decl(key, NitrogenPassPlan.single),
          seasonKey: 'dev|crop|2026-04-01',
        );
        expect(r.options, isEmpty, reason: key);
        expect(r.canDeclare, isFalse, reason: key);
        expect(identical(r.guide, base), isTrue, reason: key);
      }
    });

    test('sin guía: resolución vacía', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(guide: null);
      expect(r.guide, isNull);
      expect(r.options, isEmpty);
      expect(r.canDeclare, isFalse);
    });
  });

  group('tono tras respuesta mayor de lo habitual (sin declaración)', () {
    NutritionWindowRecord greater(String stageKey) => NutritionWindowRecord(
      id: 'w-$stageKey',
      seasonKey: 'dev|crop|2026-04-01',
      deviceId: 'dev',
      cropKey: 'maize',
      stageKey: stageKey,
      stageLabelEs: stageKey,
      nutrients: const <AgroMetricKey>[AgroMetricKey.n],
      isCritical: true,
      openedAt: DateTime(2026, 5, 1),
      closedAt: DateTime(2026, 5, 20),
      outcome: NutritionWindowOutcome.attendedDetected,
      responseVerdict: ResponseVerdict.greater,
    );

    test('la siguiente ventana de N se degrada a orientativa y cambia de tono', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('maize'),
        windows: <NutritionWindowRecord>[greater('vegmid')],
        seasonKey: 'dev|crop|2026-04-01',
        currentStageKey: 'vegAdvanced',
      );
      expect(r.demotedStageKey, 'vegadvanced');
      final StageNutritionRule rule = r.guide!.ruleForStage('vegAdvanced')!;
      expect(rule.isCritical, isFalse);
      expect(rule.windowNutrients, contains(AgroMetricKey.n), reason: 'sigue observando');
      expect(rule.rationaleEs, contains('mayor de lo habitual'));
      expect(rule.rulesEs.first, contains('no mide kilos'));
      expect(r.reasonsEs.single, contains('no convierte la magnitud en kilos'));
    });

    test('solo la ventana inmediata: una respuesta mayor en fondo no degrada V10–V12', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('maize'),
        windows: <NutritionWindowRecord>[greater('germination')],
        seasonKey: 'dev|crop|2026-04-01',
        currentStageKey: 'vegAdvanced',
      );
      expect(r.demotedStageKey, isNull);
    });

    test('una respuesta habitual no degrada nada', () {
      final NutritionWindowRecord w = greater('vegmid').copyWith(
        responseVerdict: ResponseVerdict.compatible,
      );
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('maize'),
        windows: <NutritionWindowRecord>[w],
        seasonKey: 'dev|crop|2026-04-01',
        currentStageKey: 'vegAdvanced',
      );
      expect(r.demotedStageKey, isNull);
    });

    test('con declaración manda la declaración, no el tono', () {
      final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
        guide: _guide('maize'),
        texture: SoilTexture.clay,
        declaration: _decl('maize', NitrogenPassPlan.two),
        windows: <NutritionWindowRecord>[greater('vegmid')],
        seasonKey: 'dev|crop|2026-04-01',
        currentStageKey: 'vegAdvanced',
      );
      expect(r.declarationApplied, isTrue);
      expect(r.demotedStageKey, isNull);
    });
  });

  group('declarar a mitad de una ventana abierta', () {
    NutritionWindowRecord open(String stageKey, {bool critical = true}) =>
        NutritionWindowRecord(
          id: 'w-$stageKey',
          seasonKey: 'dev|crop|2026-04-01',
          deviceId: 'dev',
          cropKey: 'maize',
          stageKey: stageKey,
          stageLabelEs: stageKey,
          nutrients: const <AgroMetricKey>[AgroMetricKey.n],
          isCritical: critical,
          openedAt: DateTime(2026, 5, 1),
          outcome: NutritionWindowOutcome.open,
        );

    test('la ventana V10–V12 ya abierta deja de ser importante: cierra sin pesar', () {
      final NutritionPlanResolution plan = NutritionWindowPlanResolver.resolve(
        guide: _guide('maize'),
        texture: SoilTexture.clay,
        declaration: _decl('maize', NitrogenPassPlan.single),
        seasonKey: 'dev|crop|2026-04-01',
        currentStageKey: 'vegAdvanced',
      );
      final List<NutritionWindowRecord> before = <NutritionWindowRecord>[open('vegadvanced')];
      final List<NutritionWindowRecord> after =
          NutritionReadinessEngine.neutralizeFoldedWindows(before, plan);
      expect(identical(after, before), isFalse);
      expect(after.single.isCritical, isFalse);
      expect(after.single.penalizes, isFalse);
      expect(after.single.evidenceEs.last, contains('cubierto por tu plan'));
    });

    test('sin plegado, el libro pasa intacto (misma instancia)', () {
      final NutritionPlanResolution plan = NutritionWindowPlanResolver.resolve(
        guide: _guide('maize'),
        seasonKey: 'dev|crop|2026-04-01',
        currentStageKey: 'vegMid',
      );
      final List<NutritionWindowRecord> before = <NutritionWindowRecord>[open('vegmid')];
      expect(
        identical(NutritionReadinessEngine.neutralizeFoldedWindows(before, plan), before),
        isTrue,
      );
    });
  });

  group('todas las guías comestibles están clasificadas', () {
    const List<String> edible = <String>[
      'maize', 'wheat', 'barley', 'oat', 'bean', 'tomato', 'chili', 'eggplant',
      'cucumber', 'squash', 'lettuce', 'spinach', 'onion', 'garlic',
      'apple_tree', 'pear_tree', 'peach_tree', 'walnut_tree', 'pistachio_tree',
      'orange_tree', 'lemon_tree', 'mango_tree', 'avocado_tree',
    ];

    test('clasificación, mínimo coherente con el plan y nota citable', () {
      for (final String key in edible) {
        final NutritionGuide g = _guide(key);
        expect(g.splitRequirement.isClassified, isTrue, reason: key);
        expect(g.minNitrogenPasses, greaterThanOrEqualTo(1), reason: key);
        expect(
          g.minNitrogenPasses,
          lessThanOrEqualTo(g.nitrogenPassCount),
          reason: '$key: el mínimo defendible no puede exceder las ventanas del plan',
        );
        expect((g.splitNotesEs ?? '').length, greaterThan(40), reason: key);
        final int? fine = g.minNitrogenPassesFine;
        if (fine != null) {
          expect(fine, lessThanOrEqualTo(g.minNitrogenPasses), reason: key);
        }
        final int? coarse = g.minNitrogenPassesCoarse;
        if (coarse != null) {
          expect(coarse, greaterThanOrEqualTo(g.minNitrogenPasses), reason: key);
        }
        expect(
          coarse ?? (g.minNitrogenPasses + 1),
          lessThanOrEqualTo(g.nitrogenPassCount),
          reason: '$key: ni en arena el mínimo puede exceder las ventanas del plan',
        );
        final String? hint = g.singlePassStageKey;
        if (hint != null) {
          expect(g.ruleForStage(hint), isNotNull, reason: '$key: la pista señala una regla');
        }
        // Prioridad agronómica: cada guía comestible la declara, cada clave
        // señala una ventana de N distinta, y ordena todas las ventanas.
        expect(g.nitrogenPassPriority, isNotEmpty, reason: key);
        final List<StageNutritionRule> nRules = g.nitrogenWindowRules;
        final Set<StageNutritionRule> seen = <StageNutritionRule>{};
        for (final String p in g.nitrogenPassPriority) {
          final StageNutritionRule rule = nRules.firstWhere(
            (StageNutritionRule r) => r.matchesStage(p),
            orElse: () => throw StateError('$key: «$p» no es una ventana de N'),
          );
          expect(seen.add(rule), isTrue, reason: '$key: «$p» repetida');
        }
        expect(seen.length, nRules.length, reason: '$key: la prioridad ordena todas las ventanas');
        expect(g.nitrogenRulesByPriority.length, nRules.length, reason: key);
      }
    });

    test('las opciones se calculan sin error para las 23 guías y las 8 texturas', () {
      for (final String key in edible) {
        for (final SoilTexture t in SoilTexture.values) {
          final NutritionPlanResolution r = NutritionWindowPlanResolver.resolve(
            guide: _guide(key),
            texture: t,
          );
          expect(r.options, isNotEmpty, reason: '$key/$t');
          expect(
            r.options.any((o) => o.enabled),
            isTrue,
            reason: '$key/$t: siempre hay al menos una opción válida (el plan)',
          );
          expect(r.recommendedOption, isNotNull, reason: '$key/$t');
          expect(
            r.options.where((o) => o.recommended).length,
            1,
            reason: '$key/$t: exactamente una ★',
          );
        }
      }
    });
  });
}
