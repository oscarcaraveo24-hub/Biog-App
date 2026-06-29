// test/core/walnut_tree/walnut_tree_universal_profile_test.dart
//
// Contrato AgroRange v1.4/v1.5 (lowMax != optimalMin, optimalMax != highMin en
// suelo/ambiente) y jerarquia de StageWeights/prioridades por etapa (doc 05).
// Contrato v1.5 de copy: fruit_fill habla de LLENADO de nuez/almendra, NUNCA de
// cosecha/ruezno; harvest_maturity si; post_harvest reservas.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_universal_profile.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> _allStages = <String>[
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
  TreeStageIds.unknown,
];

void main() {
  group('Contrato AgroRange (sin rangos pegados en suelo/ambiente)', () {
    test('moisture/soilTemp/pH: lowMax < optimalMin y optimalMax < highMin', () {
      for (final stage in _allStages) {
        final t = resolveWalnutTreeTargets(stage);
        for (final entry in <String, AgroRange>{
          'moisture': t.moistureRaw,
          'soilTemp': t.soilTemp,
          'ph': t.ph,
        }.entries) {
          expect(
            entry.value.lowMax < entry.value.optimalMin,
            isTrue,
            reason: '$stage ${entry.key}: lowMax==optimalMin',
          );
          expect(
            entry.value.optimalMax < entry.value.highMin,
            isTrue,
            reason: '$stage ${entry.key}: optimalMax==highMin',
          );
        }
      }
    });

    test('EC/resistance: lowMax (placeholder) < optimalMin y optimalMax < highMin', () {
      for (final stage in _allStages) {
        final t = resolveWalnutTreeTargets(stage);
        for (final entry in <String, AgroRange>{
          'ec': t.ec,
          'resistance': t.resistance,
        }.entries) {
          expect(entry.value.lowMax < entry.value.optimalMin, isTrue);
          expect(entry.value.optimalMax < entry.value.highMin, isTrue);
        }
      }
    });

    test('rangos relativos N/P/K también son suaves (no pegados)', () {
      for (final stage in _allStages) {
        final t = resolveWalnutTreeTargets(stage);
        for (final entry in <String, AgroRange>{
          'n': t.nIndex,
          'p': t.pIndex,
          'k': t.kIndex,
        }.entries) {
          expect(
            entry.value.optimalMax < entry.value.highMin,
            isTrue,
            reason: '$stage ${entry.key}: optimalMax==highMin',
          );
        }
      }
    });
  });

  group('Jerarquia de StageWeights por etapa (doc 05 §11)', () {
    test('floracion pondera agua/temperatura/EC por encima de N', () {
      final w = resolveWalnutTreeStageWeights(TreeStageIds.flowering);
      expect(w.moisture, greaterThan(w.nutrientN));
      expect(w.soilTemp, greaterThan(w.nutrientN));
      expect(w.ec, greaterThan(w.nutrientN));
    });

    test('amarre pondera agua/EC por encima de N y K por encima de N', () {
      final w = resolveWalnutTreeStageWeights(TreeStageIds.fruitSet);
      expect(w.moisture, greaterThan(w.nutrientN));
      expect(w.ec, greaterThan(w.nutrientN));
      expect(w.nutrientK, greaterThan(w.nutrientN));
    });

    test('llenado: K es el nutriente dominante (doc 05 §11)', () {
      final w = resolveWalnutTreeStageWeights(TreeStageIds.fruitFill);
      expect(w.nutrientK, greaterThan(w.nutrientN));
      expect(w.nutrientK, greaterThan(w.nutrientP));
      expect(w.nutrientK, greaterThan(0.16));
    });

    test('madurez/cosecha: K sigue dominante entre nutrientes', () {
      final w = resolveWalnutTreeStageWeights(TreeStageIds.harvestMaturity);
      expect(w.nutrientK, greaterThan(w.nutrientN));
      expect(w.nutrientK, greaterThan(w.nutrientP));
    });

    test('dormancia reduce el peso NPK frente a suelo/clima', () {
      final w = resolveWalnutTreeStageWeights(TreeStageIds.dormancy);
      expect(w.nutrientsSum, lessThan(w.moisture + w.soilTemp));
    });

    test('establecimiento radicular pondera resistencia/EC/agua', () {
      final w = resolveWalnutTreeStageWeights(TreeStageIds.rootEstablishment);
      expect(w.resistance, greaterThan(w.nutrientN));
      expect(w.ec, greaterThan(w.nutrientN));
      expect(w.moisture, greaterThan(w.nutrientK));
    });
  });

  group('Prioridades NPK relativas por etapa (doc 05 §10)', () {
    test('llenado: K es la prioridad maxima', () {
      final p = resolveWalnutTreeNutritionPriorities(TreeStageIds.fruitFill);
      expect(p.dominantNutrient, AgroMetricKey.k);
      expect(p.kPriority01, greaterThan(p.nPriority01));
      expect(p.kPriority01, greaterThan(0.85));
    });

    test('establecimiento/plantacion: P por encima de N', () {
      for (final stage in <String>[
        TreeStageIds.plantingTransplant,
        TreeStageIds.rootEstablishment,
      ]) {
        final p = resolveWalnutTreeNutritionPriorities(stage);
        expect(p.dominantNutrient, AgroMetricKey.p, reason: stage);
        expect(p.pPriority01, greaterThan(p.nPriority01), reason: stage);
      }
    });

    test('post_harvest mantiene prioridad N/K real (etapa activa de reservas)', () {
      final p = resolveWalnutTreeNutritionPriorities(TreeStageIds.postHarvest);
      expect(p.nPriority01, greaterThan(0.3));
      expect(p.kPriority01, greaterThan(0.3));
    });

    test('amarre: K ya domina sobre N y P (nogal sensible a K en nuez)', () {
      final p = resolveWalnutTreeNutritionPriorities(TreeStageIds.fruitSet);
      expect(p.dominantNutrient, AgroMetricKey.k);
    });

    test('vegetativo/juvenil: N domina (area foliar/estructura)', () {
      for (final stage in <String>[
        TreeStageIds.juvenileVegetative,
        TreeStageIds.vegetativeGrowth,
      ]) {
        final p = resolveWalnutTreeNutritionPriorities(stage);
        expect(p.dominantNutrient, AgroMetricKey.n, reason: stage);
      }
    });
  });

  group('Contrato v1.5 de copy por etapa (fruit_fill != harvest_maturity)', () {
    test('la guia de fruit_fill habla de llenado, NUNCA de cosecha/ruezno', () {
      final guidance = walnutTreeStageGuidanceEs(TreeStageIds.fruitFill).toLowerCase();
      expect(guidance, contains('llenado'));
      for (final forbidden in <String>['cosecha', 'madurez', 'ruezno', 'recoleccion']) {
        expect(guidance, isNot(contains(forbidden)), reason: forbidden);
      }
    });

    test('la guia de harvest_maturity si puede hablar de cosecha/madurez/ruezno', () {
      final guidance =
          walnutTreeStageGuidanceEs(TreeStageIds.harvestMaturity).toLowerCase();
      expect(
        guidance,
        anyOf(contains('cosecha'), contains('madurez'), contains('ruezno')),
      );
    });

    test('la guia de post_harvest habla de reservas/siguiente ciclo', () {
      final guidance =
          walnutTreeStageGuidanceEs(TreeStageIds.postHarvest).toLowerCase();
      expect(guidance, anyOf(contains('reserva'), contains('siguiente')));
    });

    test('lenguaje nogalero: la guia usa "nuez", no "fruto" generico', () {
      final guidance = walnutTreeStageGuidanceEs(TreeStageIds.fruitSet).toLowerCase();
      expect(guidance, contains('nuez'));
    });
  });
}
