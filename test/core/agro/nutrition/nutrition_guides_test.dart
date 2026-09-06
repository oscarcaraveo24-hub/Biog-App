// test/core/agro/nutrition/nutrition_guides_test.dart
//
// Invariantes de la tabla de guías curadas (Guía v0.4, fase 2 y §10):
// todas entran como `proposed`, ningún rango se muestra hasta auditar, los
// repartos por ventana no rebasan el plan y las claves de etapa coinciden con
// las que emiten los motores de cada cultivo.
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

void main() {
  group('kNutritionGuides · invariantes', () {
    test('cubre los 32 cultivos del catálogo (todos menos genérico) con claves canónicas', () {
      expect(kNutritionGuides.length, 32);
      for (final MapEntry<String, NutritionGuide> e in kNutritionGuides.entries) {
        expect(e.value.cropKey, e.key, reason: 'la clave del mapa y de la guía coinciden');
        expect(e.key.startsWith('crop_'), isFalse, reason: 'sin prefijo crop_');
      }
    });

    test('todas las guías y planes entran como proposed: ningún rango visible', () {
      for (final NutritionGuide g in kNutritionGuides.values) {
        expect(g.auditStatus, GuideAuditStatus.proposed, reason: g.cropKey);
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
              expect(
                g.windowDoseFor(nutrient: n, stageKey: s),
                isNull,
                reason: '${g.cropKey}/$s/$n no debe emitir dosis sin auditar',
              );
            }
          }
        }
      }
    });

    test('el reparto por ventana no rebasa el plan de temporada', () {
      for (final NutritionGuide g in kNutritionGuides.values) {
        final Map<AgroMetricKey, double> total = <AgroMetricKey, double>{};
        for (final StageNutritionRule r in g.stageRules) {
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
      }
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

    test('los frutales usan restitución y no plan en kg/ha', () {
      for (final String k in <String>[
        'apple_tree',
        'pear_tree',
        'peach_tree',
        'walnut_tree',
        'pistachio_tree',
        'orange_tree',
        'lemon_tree',
        'mango_tree',
        'avocado_tree',
      ]) {
        final NutritionGuide g = kNutritionGuides[k]!;
        expect(g.usesTreeRestitution, isTrue, reason: k);
        expect(g.seasonPlan, isEmpty, reason: k);
      }
      for (final String k in <String>['maize', 'tomato', 'onion']) {
        expect(kNutritionGuides[k]!.usesTreeRestitution, isFalse, reason: k);
        expect(kNutritionGuides[k]!.seasonPlan.length, 3, reason: k);
      }
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
