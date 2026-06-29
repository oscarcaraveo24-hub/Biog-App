// test/core/peach_tree/peach_tree_universal_profile_test.dart
//
// Contrato AgroRange v1.4/v1.5 (lowMax != optimalMin, optimalMax != highMin en
// suelo/ambiente) y jerarquía de StageWeights/prioridades por etapa (doc 05).

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_universal_profile.dart';
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
        final t = resolvePeachTreeTargets(stage);
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
        final t = resolvePeachTreeTargets(stage);
        for (final entry in <String, AgroRange>{
          'ec': t.ec,
          'resistance': t.resistance,
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

    test('rangos relativos N/P/K también son suaves (no pegados)', () {
      for (final stage in _allStages) {
        final t = resolvePeachTreeTargets(stage);
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

  group('Jerarquía de StageWeights por etapa (doc 05 §11)', () {
    test('floración pondera agua/temperatura/EC por encima de N', () {
      final w = resolvePeachTreeStageWeights(TreeStageIds.flowering);
      expect(w.moisture, greaterThan(w.nutrientN));
      expect(w.soilTemp, greaterThan(w.nutrientN));
      expect(w.ec, greaterThan(w.nutrientN));
    });

    test('cuajado pondera agua/EC por encima de N y K por encima de N', () {
      final w = resolvePeachTreeStageWeights(TreeStageIds.fruitSet);
      expect(w.moisture, greaterThan(w.nutrientN));
      expect(w.ec, greaterThan(w.nutrientN));
      expect(w.nutrientK, greaterThan(w.nutrientN));
    });

    test('llenado: K es el nutriente dominante (doc 05 §11)', () {
      final w = resolvePeachTreeStageWeights(TreeStageIds.fruitFill);
      expect(w.nutrientK, greaterThan(w.nutrientN));
      expect(w.nutrientK, greaterThan(w.nutrientP));
      expect(w.nutrientK, greaterThan(0.18));
    });

    test('madurez/cosecha: K sigue dominante entre nutrientes', () {
      final w = resolvePeachTreeStageWeights(TreeStageIds.harvestMaturity);
      expect(w.nutrientK, greaterThan(w.nutrientN));
      expect(w.nutrientK, greaterThan(w.nutrientP));
    });

    test('dormancia reduce el peso NPK frente a suelo/clima', () {
      final w = resolvePeachTreeStageWeights(TreeStageIds.dormancy);
      expect(w.nutrientsSum, lessThan(w.moisture + w.soilTemp));
    });

    test('establecimiento radicular pondera resistencia/EC/agua', () {
      final w = resolvePeachTreeStageWeights(TreeStageIds.rootEstablishment);
      expect(w.resistance, greaterThan(w.nutrientN));
      expect(w.ec, greaterThan(w.nutrientN));
      expect(w.moisture, greaterThan(w.nutrientK));
    });
  });

  group('Prioridades NPK relativas por etapa (doc 05 §8)', () {
    test('llenado: K es la prioridad máxima', () {
      final p = resolvePeachTreeNutritionPriorities(TreeStageIds.fruitFill);
      expect(p.dominantNutrient, AgroMetricKey.k);
      expect(p.kPriority01, greaterThan(p.nPriority01));
      expect(p.kPriority01, greaterThan(0.85));
    });

    test('establecimiento/plantación: P por encima de N', () {
      for (final stage in <String>[
        TreeStageIds.plantingTransplant,
        TreeStageIds.rootEstablishment,
      ]) {
        final p = resolvePeachTreeNutritionPriorities(stage);
        expect(p.dominantNutrient, AgroMetricKey.p, reason: stage);
        expect(p.pPriority01, greaterThan(p.nPriority01), reason: stage);
      }
    });

    test('post_harvest mantiene prioridad N/K real (etapa activa de reservas)', () {
      final p = resolvePeachTreeNutritionPriorities(TreeStageIds.postHarvest);
      expect(p.nPriority01, greaterThan(0.3));
      expect(p.kPriority01, greaterThan(0.3));
    });

    test('cuajado: K ya domina sobre N y P (durazno muy sensible a K)', () {
      final p = resolvePeachTreeNutritionPriorities(TreeStageIds.fruitSet);
      expect(p.dominantNutrient, AgroMetricKey.k);
    });
  });

  group('Contrato v1.5 de copy por etapa (fruit_fill != harvest_maturity)', () {
    test('la guía de fruit_fill habla de llenado, NUNCA de cosecha/madurez', () {
      final guidance = peachTreeStageGuidanceEs(TreeStageIds.fruitFill).toLowerCase();
      expect(guidance, contains('llenado'));
      for (final forbidden in <String>['cosecha', 'madurez', 'maduración', 'maduracion']) {
        expect(guidance, isNot(contains(forbidden)), reason: forbidden);
      }
    });

    test('la guía de harvest_maturity sí puede hablar de cosecha/madurez', () {
      final guidance =
          peachTreeStageGuidanceEs(TreeStageIds.harvestMaturity).toLowerCase();
      expect(guidance, anyOf(contains('cosecha'), contains('madurez')));
    });

    test('la guía de post_harvest habla de reservas/siguiente ciclo', () {
      final guidance =
          peachTreeStageGuidanceEs(TreeStageIds.postHarvest).toLowerCase();
      expect(guidance, anyOf(contains('reserva'), contains('siguiente ciclo')));
    });
  });
}
