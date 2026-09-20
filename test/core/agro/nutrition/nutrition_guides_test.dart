// test/core/agro/nutrition/nutrition_guides_test.dart
//
// Invariantes de la tabla de guías curadas (Guía v0.4, fase 2 y §10, con la
// decisión de producto del 6 sep 2026): todas entran como `proposed`, sus
// rangos SÍ se muestran —siempre como orientativos, con fuente y estatus—,
// los repartos por ventana no rebasan el plan (en frutales, el plan anual de la huerta)
// y las claves de etapa coinciden con las que emiten los motores de cada
// cultivo.
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guide.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guide_catalog.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guides.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/widgets/seeds/barley_models.dart';
import 'package:bio_g/widgets/seeds/bean_models.dart';
import 'package:bio_g/widgets/seeds/chili_models.dart';
import 'package:bio_g/widgets/seeds/cucumber_models.dart';
import 'package:bio_g/widgets/seeds/eggplant_models.dart';
import 'package:bio_g/widgets/seeds/garlic_models.dart';
import 'package:bio_g/widgets/seeds/lettuce_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/oat_models.dart';
import 'package:bio_g/widgets/seeds/onion_models.dart';
import 'package:bio_g/widgets/seeds/spinach_models.dart';
import 'package:bio_g/widgets/seeds/squash_models.dart';
import 'package:bio_g/widgets/seeds/tomato_models.dart';
import 'package:bio_g/widgets/seeds/wheat_models.dart';
import 'package:flutter_test/flutter_test.dart';

Set<String> _norm(Iterable<String> keys) =>
    keys.map(StageNutritionRule.normalizeStageKey).toSet();

/// Claves de etapa válidas por cultivo, tomadas de los enums de cada motor.
final Map<String, Set<String>> _validStageKeys = <String, Set<String>>{
  'maize': _norm(MaizeStageKey.values.map((e) => e.name)),
  'wheat': _norm(WheatStageKey.values.map((e) => e.name)),
  'barley': _norm(BarleyStageKey.values.map((e) => e.name)),
  'oat': _norm(OatStageKey.values.map((e) => e.name)),
  'bean': _norm(BeanStageKey.values.map((e) => e.name)),
  'tomato': _norm(TomatoStageKey.values.map((e) => e.name)),
  'chili': _norm(ChiliStageKey.values.map((e) => e.name)),
  'cucumber': _norm(CucumberStageKey.values.map((e) => e.name)),
  'eggplant': _norm(EggplantStageKey.values.map((e) => e.name)),
  'squash': _norm(SquashStageKey.values.map((e) => e.name)),
  'lettuce': _norm(LettuceStageKey.values.map((e) => e.name)),
  'spinach': _norm(SpinachStageKey.values.map((e) => e.name)),
  'onion': _norm(OnionStageKey.values.map((e) => e.name)),
  'garlic': _norm(GarlicStageKey.values.map((e) => e.name)),
  for (final String tree in <String>[
    'apple_tree',
    'pear_tree',
    'peach_tree',
    'walnut_tree',
    'pistachio_tree',
    'orange_tree',
    'lemon_tree',
    'mango_tree',
    'avocado_tree',
  ])
    tree: _norm(<String>[
      TreeStageIds.plantingTransplant,
      TreeStageIds.rootEstablishment,
      TreeStageIds.juvenileVegetative,
      TreeStageIds.dormancy,
      TreeStageIds.budbreak,
      TreeStageIds.vegetativeGrowth,
      TreeStageIds.flowering,
      TreeStageIds.fruitSet,
      TreeStageIds.fruitFill,
      TreeStageIds.harvestMaturity,
      TreeStageIds.postHarvest,
    ]),
};

const List<String> _trees = <String>[
  'apple_tree',
  'pear_tree',
  'peach_tree',
  'walnut_tree',
  'pistachio_tree',
  'orange_tree',
  'lemon_tree',
  'mango_tree',
  'avocado_tree',
];

bool _isTree(String cropKey) => _trees.contains(cropKey);

void main() {
  group('kNutritionGuides · invariantes', () {
    test('cubre los 32 cultivos del catálogo (todos menos genérico) con claves canónicas', () {
      expect(kNutritionGuides.length, 32);
      for (final MapEntry<String, NutritionGuide> e in kNutritionGuides.entries) {
        expect(e.value.cropKey, e.key, reason: 'la clave del mapa y de la guía coinciden');
        expect(e.key.startsWith('crop_'), isFalse, reason: 'sin prefijo crop_');
      }
    });

    test('todas las guías entran como proposed y sus rangos se muestran como orientativos', () {
      for (final NutritionGuide g in kNutritionGuides.values) {
        expect(g.auditStatus, GuideAuditStatus.proposed, reason: g.cropKey);
        expect(g.auditStatus.canShowDose, isTrue, reason: g.cropKey);
        for (final SeasonNutrientPlan p in g.seasonPlan.values) {
          expect(p.audit, GuideAuditStatus.proposed, reason: '${g.cropKey}/${p.form}');
          expect(p.minKgPerHa, lessThanOrEqualTo(p.maxKgPerHa), reason: g.cropKey);
          expect(p.minKgPerHa, greaterThanOrEqualTo(0), reason: g.cropKey);
          expect(p.form.nutrient, p.nutrient);
        }
        for (final StageNutritionRule r in g.stageRules) {
          for (final AgroMetricKey n in const <AgroMetricKey>[
            AgroMetricKey.n,
            AgroMetricKey.p,
            AgroMetricKey.k,
          ]) {
            for (final String s in r.stageKeys) {
              final NutritionDoseRange? d = g.windowDoseFor(nutrient: n, stageKey: s);
              // Reparto con plan = dosis, abra ventana (foco) o no
              // (acompañamiento: «acompaña con K₂O …»).
              final bool expected =
                  g.seasonPlan.containsKey(n) && (r.seasonShare[n] ?? 0) > 0;
              expect(
                d != null,
                expected,
                reason: '${g.cropKey}/$s/$n: dosis ${expected ? 'esperada' : 'no esperada'}',
              );
              if (d == null) continue;
              expect(d.unit, DoseUnit.kgPerHectare, reason: '${g.cropKey}/$s/$n');
              expect(d.max, greaterThan(0), reason: '${g.cropKey}/$s/$n');
              expect(
                d.transparencyEs,
                allOf(contains('orientativo'), contains('pendiente de revisión final')),
                reason: '${g.cropKey}/$s/$n: el rango se etiqueta como orientativo',
              );
              expect(
                d.commercialEquivalentEs,
                isNotNull,
                reason: '${g.cropKey}/$s/$n: siempre hay equivalente comercial',
              );
              // Un plan con mínimo 0 solo se muestra como condición.
              expect(
                d.isConditional,
                g.seasonPlan[n]!.minKgPerHa <= 0,
                reason: '${g.cropKey}/$s/$n',
              );
              if (d.isConditional) {
                expect(d.conditionEs, contains('análisis de suelo'));
                expect(d.labelEs, startsWith('hasta '));
              }
            }
          }
        }
      }
    });

    test('el reparto por ventana no rebasa el plan de temporada (ciclo de carga en frutales)', () {
      for (final NutritionGuide g in kNutritionGuides.values) {
        final Map<AgroMetricKey, double> total = <AgroMetricKey, double>{};
        for (final StageNutritionRule r in g.stageRules) {
          // Frutales: el establecimiento es el año de plantación, no el ciclo
          // de carga; su P no suma con las ventanas del año productivo.
          if (_isTree(g.cropKey) && r.matchesStage('planting_transplant')) continue;
          for (final MapEntry<AgroMetricKey, double> e in r.seasonShare.entries) {
            expect(e.value, greaterThan(0), reason: '${g.cropKey}/${r.labelEs}');
            total[e.key] = (total[e.key] ?? 0) + e.value;
          }
        }
        for (final MapEntry<AgroMetricKey, double> e in total.entries) {
          expect(e.value, lessThanOrEqualTo(1.0 + 1e-9), reason: '${g.cropKey}/${e.key}');
          expect(
            g.seasonPlan.containsKey(e.key),
            isTrue,
            reason: '${g.cropKey}: reparte ${e.key} sin plan de temporada',
          );
        }
        // Con plan en kg/ha, toda ventana que abre un nutriente lo dosifica:
        // el copy nunca dice «aplica N» sin poder decir cuánto.
        if (g.hasSeasonPlan) {
          for (final StageNutritionRule r in g.stageRules) {
            for (final AgroMetricKey n in r.windowNutrients) {
              expect(
                (r.seasonShare[n] ?? 0) > 0 && g.seasonPlan.containsKey(n),
                isTrue,
                reason: '${g.cropKey}/${r.labelEs}: abre $n sin reparto o sin plan',
              );
            }
          }
        }
      }
    });

    test('maíz V6–V8: 40 % del plan de N con su equivalente en urea', () {
      final NutritionGuide maize = kNutritionGuides['maize']!;
      final NutritionDoseRange d = maize.windowDoseFor(
        nutrient: AgroMetricKey.n,
        stageKey: 'vegMid',
      )!;
      expect(d.min, closeTo(160 * 0.40, 1e-9));
      expect(d.max, closeTo(240 * 0.40, 1e-9));
      expect(d.labelEs, '64–96 kg/ha de N');
      expect(d.commercialEquivalentEs, '≈ 140–210 kg/ha de urea');

      // La cobertera se partió en dos: el resto entra en V10–V12, que es
      // donde el maíz tiene su pico de consumo diario.
      final NutritionDoseRange late = maize.windowDoseFor(
        nutrient: AgroMetricKey.n,
        stageKey: 'vegAdvanced',
      )!;
      expect(late.min, closeTo(160 * 0.27, 1e-9));
      expect(late.labelEs, '43–65 kg/ha de N');
      expect(d.isConditional, isFalse);

      final NutritionDoseRange k = maize.windowDoseFor(
        nutrient: AgroMetricKey.k,
        stageKey: 'germination',
      )!;
      expect(k.isConditional, isTrue);
      expect(k.labelEs, 'hasta 60 kg/ha de K₂O');
      expect(k.commercialEquivalentEs, '≈ hasta 100 kg/ha de cloruro de potasio');
      expect(
        NutrientDose(nutrient: AgroMetricKey.k, range: k).lineEs,
        'K₂O: hasta 60 kg/ha (≈ hasta 100 kg/ha de cloruro de potasio), '
        'solo si tu análisis de suelo sale bajo en potasio',
      );
      expect(maize.nextWindowRuleAfterAny('germination')?.labelEs, 'Segunda fertilización (V6–V8)');
      expect(maize.nextWindowRuleAfterAny('vegMid')?.labelEs, 'Tercera fertilización (V10–V12)');
      expect(maize.nextWindowRuleAfterAny('vegAdvanced'), isNull, reason: 'espigamiento no abre');
      expect(maize.nextWindowRuleAfterAny('harvest'), isNull, reason: 'etapa fuera de la guía');
      expect(maize.nextWindowRuleAfter('harvest', AgroMetricKey.n), isNull);
    });

    test('tomate vegetativo: N es el foco y P/K acompañan con su reparto', () {
      final NutritionGuide tomato = kNutritionGuides['tomato']!;
      final StageNutritionRule veg = tomato.ruleForStage('vegetativo')!;
      expect(veg.windowNutrients, <AgroMetricKey>{AgroMetricKey.n});
      expect(tomato.windowDoseFor(nutrient: AgroMetricKey.n, stageKey: 'vegetativo')?.labelEs, '49–65 kg/ha de N');
      expect(tomato.windowDoseFor(nutrient: AgroMetricKey.k, stageKey: 'vegetativo')?.labelEs, '18–27 kg/ha de K₂O');
      expect(tomato.windowDoseFor(nutrient: AgroMetricKey.p, stageKey: 'vegetativo')?.labelEs, '12–20 kg/ha de P₂O₅');
    });

    test('las claves de etapa existen en el motor del cultivo y no se repiten', () {
      for (final MapEntry<String, Set<String>> e in _validStageKeys.entries) {
        final NutritionGuide? g = kNutritionGuides[e.key];
        expect(g, isNotNull, reason: e.key);
        final Set<String> seen = <String>{};
        for (final StageNutritionRule r in g!.stageRules) {
          for (final String raw in r.stageKeys) {
            final String k = StageNutritionRule.normalizeStageKey(raw);
            expect(e.value, contains(k), reason: '${e.key}: etapa desconocida «$raw»');
            expect(seen.add(k), isTrue, reason: '${e.key}: etapa «$raw» en dos reglas');
          }
        }
      }
    });

    test('una ventana crítica siempre abre al menos un nutriente', () {
      for (final NutritionGuide g in kNutritionGuides.values) {
        for (final StageNutritionRule r in g.stageRules) {
          if (r.isCritical) {
            expect(r.windowNutrients, isNotEmpty, reason: '${g.cropKey}/${r.labelEs}');
          }
        }
      }
    });

    test('los frutales llevan plan anual de huerta en kg/ha, no restitución por cosecha', () {
      // Decisión de producto (6 sep 2026): la dosis de un frutal sale de su
      // guía y no de la cosecha esperada por árbol.
      for (final String k in _trees) {
        final NutritionGuide g = kNutritionGuides[k]!;
        expect(g.seasonPlan.length, 3, reason: k);
        expect(g.hasSeasonPlan, isTrue, reason: k);
        expect(g.sources, isNotEmpty, reason: k);
        // El ciclo de carga reparte N y K completos; el P va de una vez.
        for (final AgroMetricKey n in const <AgroMetricKey>[
          AgroMetricKey.n,
          AgroMetricKey.p,
          AgroMetricKey.k,
        ]) {
          double sum = 0;
          for (final StageNutritionRule r in g.stageRules) {
            if (r.matchesStage('planting_transplant')) continue;
            sum += r.seasonShare[n] ?? 0;
          }
          expect(sum, closeTo(1.0, 1e-9), reason: '$k/$n');
        }
      }
      for (final String k in <String>['maize', 'tomato', 'onion']) {
        expect(kNutritionGuides[k]!.seasonPlan.length, 3, reason: k);
      }
    });

    test('manzano: el N va por mitades, primavera y post-cosecha', () {
      final NutritionGuide apple = kNutritionGuides['apple_tree']!;
      final NutritionDoseRange n = apple.windowDoseFor(
        nutrient: AgroMetricKey.n,
        stageKey: 'budbreak',
      )!;
      // Plan 70–140 kg N/ha (17 sep 2026: el mínimo bajó de 100 a 70 con
      // WSU, Wisconsin y Cornell) × 50 % de la ventana.
      expect(n.labelEs, '35–70 kg/ha de N');
      expect(n.unit, DoseUnit.kgPerHectare);
      expect(n.commercialEquivalentEs, isNotNull);
      expect(n.transparencyEs, contains('50 %'));
      expect(apple.windowDoseFor(nutrient: AgroMetricKey.k, stageKey: 'budbreak'), isNull);
      expect(apple.windowDoseFor(nutrient: AgroMetricKey.n, stageKey: 'dormancy'), isNull);
      // Nogal pecanero: la nuez toma N también en el llenado, y la ventana de
      // post-cosecha se eliminó porque en Chihuahua se cosecha sin hoja.
      final NutritionGuide pecan = kNutritionGuides['walnut_tree']!;
      expect(pecan.ruleForStage('fruit_fill')!.windowNutrients, contains(AgroMetricKey.n));
      expect(pecan.ruleForStage('post_harvest')!.windowNutrients, isEmpty);
      expect(
        pecan.windowDoseFor(nutrient: AgroMetricKey.n, stageKey: 'post_harvest'),
        isNull,
        reason: 'sin hoja no hay absorción: el N post-cosecha se fue',
      );
      // …y el potasio se movió al reposo, que es cuando toca.
      expect(
        pecan.ruleForStage('dormancy')!.windowNutrients,
        contains(AgroMetricKey.k),
      );
    });

    test('cada plan de temporada trae fuente y cada guía con plan trae fuentes citables', () {
      for (final NutritionGuide g in kNutritionGuides.values) {
        for (final SeasonNutrientPlan p in g.seasonPlan.values) {
          expect(p.sourceEs.trim(), isNotEmpty, reason: '${g.cropKey}/${p.form}');
        }
        if (g.seasonPlan.isNotEmpty) {
          expect(g.sources, isNotEmpty, reason: g.cropKey);
        }
      }
    });
  });

  group('NutritionGuideCatalog', () {
    test('resuelve claves canónicas, con prefijo crop_, alias y CropKey.name', () {
      expect(NutritionGuideCatalog.forCrop('maize')?.cropKey, 'maize');
      expect(NutritionGuideCatalog.forCrop('crop_maize')?.cropKey, 'maize');
      expect(NutritionGuideCatalog.forCrop('Maíz')?.cropKey, 'maize');
      expect(NutritionGuideCatalog.forCrop('crop_apple_tree')?.cropKey, 'apple_tree');
      expect(NutritionGuideCatalog.forCrop('appleTree')?.cropKey, 'apple_tree');
      expect(NutritionGuideCatalog.forCrop('jitomate')?.cropKey, 'tomato');
      expect(NutritionGuideCatalog.forCrop('crop_nopal')?.cropKey, 'nopal');
      expect(NutritionGuideCatalog.forCrop(''), isNull);
      expect(NutritionGuideCatalog.forCrop(null), isNull);
      expect(NutritionGuideCatalog.forCrop('cultivo_inexistente'), isNull);
    });

    test('ruleForStage y nextWindowRuleAfter siguen el orden fenológico', () {
      final NutritionGuide maize = kNutritionGuides['maize']!;
      final StageNutritionRule? germ = maize.ruleForStage('germination');
      expect(germ?.windowNutrients, contains(AgroMetricKey.p));
      expect(germ?.isCritical, isFalse);

      final StageNutritionRule? v6 = maize.ruleForStage('vegEarly');
      expect(v6?.isCritical, isTrue);
      expect(v6?.windowNutrients, <AgroMetricKey>{AgroMetricKey.n});

      final StageNutritionRule? next = maize.nextWindowRuleAfter('emergence', AgroMetricKey.n);
      expect(next, same(v6));
      expect(maize.nextWindowRuleAfter('tasseling', AgroMetricKey.n), isNull);
      expect(maize.ruleForStage('harvest'), isNull);
    });
  });

  group('windowDoseFor con guía auditada', () {
    test('multiplica plan × reparto y explica la transparencia', () {
      const NutritionGuide g = NutritionGuide(
        cropKey: 'demo',
        cropLabelEs: 'Demo',
        auditStatus: GuideAuditStatus.audited,
        seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
          AgroMetricKey.n: SeasonNutrientPlan(
            form: NutrientForm.n,
            minKgPerHa: 100,
            maxKgPerHa: 200,
            sourceEs: 'Fuente demo',
            audit: GuideAuditStatus.audited,
          ),
        },
        stageRules: <StageNutritionRule>[
          StageNutritionRule(
            stageKeys: <String>{'veg_early'},
            windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
            seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.5},
          ),
        ],
      );
      final NutritionDoseRange? d = g.windowDoseFor(
        nutrient: AgroMetricKey.n,
        stageKey: 'vegEarly',
      );
      expect(d, isNotNull);
      expect(d!.min, 50);
      expect(d.max, 100);
      expect(d.form, NutrientForm.n);
      expect(d.unit, DoseUnit.kgPerHectare);
      expect(d.transparencyEs, contains('50 %'));
      expect(g.windowDoseFor(nutrient: AgroMetricKey.p, stageKey: 'vegEarly'), isNull);
      expect(g.windowDoseFor(nutrient: AgroMetricKey.n, stageKey: 'harvest'), isNull);
    });
  });
}
