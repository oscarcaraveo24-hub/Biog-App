// test/core/apple_tree/apple_tree_universal_profile_test.dart
//
// Targets / pesos / prioridades NPK por etapa (doc 05) y su cableado en
// AppleTreeCropDefinition.resolveTargets.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_crop_definition.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_universal_profile.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void _expectRange(
  AgroRange range,
  double lowMax,
  double optimalMin,
  double optimalMax,
  double highMin, {
  required String reason,
}) {
  expect(range.lowMax, lowMax, reason: '$reason lowMax');
  expect(range.optimalMin, optimalMin, reason: '$reason optimalMin');
  expect(range.optimalMax, optimalMax, reason: '$reason optimalMax');
  expect(range.highMin, highMin, reason: '$reason highMin');
}

void main() {
  group('Prioridades NPK por etapa (doc 05)', () {
    test('fruit_fill: K es el nutriente dominante y el agua pesa', () {
      final nutrition = resolveAppleTreeNutritionPriorities(
        TreeStageIds.fruitFill,
      );
      expect(nutrition.dominantNutrient, AgroMetricKey.k);
      expect(nutrition.kPriority01, greaterThan(nutrition.nPriority01));
      expect(nutrition.kPriority01, greaterThan(nutrition.pPriority01));

      final weights = resolveAppleTreeStageWeights(TreeStageIds.fruitFill);
      // El agua sigue pesando fuerte en llenado.
      expect(weights.moisture, greaterThanOrEqualTo(0.2));
      // NPK es protagonista (K) en llenado.
      expect(weights.npk, greaterThanOrEqualTo(0.3));
    });

    test('dormancy baja el peso de NPK respecto a etapas activas', () {
      final dormancy = resolveAppleTreeStageWeights(TreeStageIds.dormancy);
      final fruitFill = resolveAppleTreeStageWeights(TreeStageIds.fruitFill);
      final vegetative = resolveAppleTreeStageWeights(
        TreeStageIds.vegetativeGrowth,
      );
      expect(dormancy.npk, lessThan(fruitFill.npk!));
      expect(dormancy.npk, lessThan(vegetative.npk!));

      final dormancyNutrition = resolveAppleTreeNutritionPriorities(
        TreeStageIds.dormancy,
      );
      // Demanda baja en reposo.
      expect(dormancyNutrition.nPriority01, lessThan(0.3));
    });

    test('planting/establecimiento: P pesa más que N', () {
      final planting = resolveAppleTreeNutritionPriorities(
        TreeStageIds.plantingTransplant,
      );
      expect(planting.pPriority01, greaterThan(planting.nPriority01));
      final root = resolveAppleTreeNutritionPriorities(
        TreeStageIds.rootEstablishment,
      );
      expect(root.pPriority01, greaterThan(root.nPriority01));
    });

    test('harvest_maturity: N bajo (calidad/color, no vigor)', () {
      final harvest = resolveAppleTreeNutritionPriorities(
        TreeStageIds.harvestMaturity,
      );
      expect(harvest.nPriority01, lessThan(0.25));
      expect(harvest.kPriority01, greaterThan(harvest.nPriority01));
    });

    test(
      'post_harvest es etapa activa: N/K con prioridad real, no simbólica',
      () {
        final post = resolveAppleTreeNutritionPriorities(
          TreeStageIds.postHarvest,
        );
        expect(post.nPriority01, greaterThan(0.4));
        expect(post.kPriority01, greaterThan(0.4));
      },
    );

    test('unknown usa confianza baja (conservador)', () {
      final unknown = resolveAppleTreeNutritionPriorities(TreeStageIds.unknown);
      expect(unknown.confidence, 'low');
    });
  });

  group('Etapa crítica de floración', () {
    test('flowering y fruit_set son ventanas críticas', () {
      expect(isTreeCriticalStage(TreeStageIds.flowering), isTrue);
      expect(isTreeCriticalStage(TreeStageIds.fruitSet), isTrue);
    });
  });

  group('StageTargets cableados', () {
    test('cada etapa real produce targets con pH universal 6.0–6.8', () {
      for (final stage in <String>[
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
      ]) {
        final targets = resolveAppleTreeTargets(stage);
        expect(targets.ph.lowMax, 5.0, reason: 'pH lowMax en $stage');
        expect(targets.ph.optimalMin, 6.0, reason: 'pH min en $stage');
        expect(targets.ph.optimalMax, 6.8, reason: 'pH max en $stage');
        expect(targets.ph.highMin, 8.0, reason: 'pH highMin en $stage');
      }
    });

    test('humedad por etapa usa zonas operativas y extremos reales', () {
      final expected = <String, List<double>>{
        TreeStageIds.plantingTransplant: <double>[45, 60, 80, 90],
        TreeStageIds.rootEstablishment: <double>[45, 65, 85, 90],
        TreeStageIds.juvenileVegetative: <double>[45, 60, 85, 90],
        TreeStageIds.dormancy: <double>[45, 45, 70, 90],
        TreeStageIds.budbreak: <double>[45, 55, 80, 90],
        TreeStageIds.vegetativeGrowth: <double>[45, 55, 80, 90],
        TreeStageIds.flowering: <double>[45, 60, 80, 90],
        TreeStageIds.fruitSet: <double>[45, 65, 85, 90],
        TreeStageIds.fruitFill: <double>[45, 65, 85, 90],
        TreeStageIds.harvestMaturity: <double>[45, 55, 75, 90],
        TreeStageIds.postHarvest: <double>[45, 55, 75, 90],
        TreeStageIds.unknown: <double>[45, 55, 80, 90],
      };

      for (final entry in expected.entries) {
        final values = entry.value;
        _expectRange(
          resolveAppleTreeTargets(entry.key).moistureRaw,
          values[0],
          values[1],
          values[2],
          values[3],
          reason: 'humedad en ${entry.key}',
        );
      }
    });

    test('temperatura de suelo por etapa usa extremos no agresivos', () {
      final expected = <String, List<double>>{
        TreeStageIds.plantingTransplant: <double>[7, 10, 24, 35],
        TreeStageIds.rootEstablishment: <double>[7, 10, 24, 35],
        TreeStageIds.juvenileVegetative: <double>[7, 10, 26, 35],
        TreeStageIds.dormancy: <double>[-2, 4, 16, 35],
        TreeStageIds.budbreak: <double>[7, 8, 22, 35],
        TreeStageIds.vegetativeGrowth: <double>[7, 10, 26, 35],
        TreeStageIds.flowering: <double>[7, 10, 24, 35],
        TreeStageIds.fruitSet: <double>[7, 12, 26, 35],
        TreeStageIds.fruitFill: <double>[7, 12, 28, 35],
        TreeStageIds.harvestMaturity: <double>[7, 10, 28, 35],
        TreeStageIds.postHarvest: <double>[7, 8, 25, 35],
        TreeStageIds.unknown: <double>[7, 8, 26, 35],
      };

      for (final entry in expected.entries) {
        final values = entry.value;
        _expectRange(
          resolveAppleTreeTargets(entry.key).soilTemp,
          values[0],
          values[1],
          values[2],
          values[3],
          reason: 'temperatura de suelo en ${entry.key}',
        );
      }
    });

    test('suelo activo conserva zona de observacion baja y alta', () {
      for (final stage in <String>[
        TreeStageIds.plantingTransplant,
        TreeStageIds.rootEstablishment,
        TreeStageIds.juvenileVegetative,
        TreeStageIds.budbreak,
        TreeStageIds.vegetativeGrowth,
        TreeStageIds.flowering,
        TreeStageIds.fruitSet,
        TreeStageIds.fruitFill,
        TreeStageIds.harvestMaturity,
        TreeStageIds.postHarvest,
        TreeStageIds.unknown,
      ]) {
        final targets = resolveAppleTreeTargets(stage);
        expect(
          targets.moistureRaw.lowMax,
          lessThan(targets.moistureRaw.optimalMin),
          reason: 'zona baja humedad en $stage',
        );
        expect(
          targets.moistureRaw.optimalMax,
          lessThan(targets.moistureRaw.highMin),
          reason: 'zona alta humedad en $stage',
        );
        expect(
          targets.soilTemp.lowMax,
          lessThan(targets.soilTemp.optimalMin),
          reason: 'zona baja temperatura en $stage',
        );
        expect(
          targets.soilTemp.optimalMax,
          lessThan(targets.soilTemp.highMin),
          reason: 'zona alta temperatura en $stage',
        );
      }
    });

    test('CE y resistencia son high-only con critico alto en 3.0', () {
      for (final stage in <String>[
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
      ]) {
        final targets = resolveAppleTreeTargets(stage);
        expect(targets.ec.lowMax, 0.0, reason: 'CE lowMax en $stage');
        expect(targets.ec.optimalMin, 0.0, reason: 'CE optimalMin en $stage');
        expect(targets.ec.highMin, 3.0, reason: 'CE highMin en $stage');
        expect(
          targets.resistance.lowMax,
          0.0,
          reason: 'resistencia lowMax en $stage',
        );
        expect(
          targets.resistance.optimalMin,
          0.0,
          reason: 'resistencia optimalMin en $stage',
        );
        expect(
          targets.resistance.highMin,
          3.0,
          reason: 'resistencia highMin en $stage',
        );
      }
    });

    test('AppleTreeCropDefinition.resolveTargets ya NO devuelve null', () {
      final definition = AppleTreeCropDefinition();
      const stage = CropStageResult(
        stageKey: TreeStageIds.fruitFill,
        stageLabelEs: 'Llenado de fruto',
        expectedDaysToEnd: 0,
        windowsNow: <dynamic>[],
        heroAsset: '',
      );
      final targets = definition.resolveTargets(stage);
      expect(targets, isNotNull);
      // En llenado, la prioridad de K es la más alta.
      expect(
        targets!.resolvedKPriority01,
        greaterThan(targets.resolvedNPriority01),
      );
    });
  });

  group('Definición expone weights/nutrition desde el perfil universal', () {
    final definition = AppleTreeCropDefinition();
    CropStageResult stageOf(String id) => CropStageResult(
      stageKey: id,
      stageLabelEs: id,
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: '',
    );

    test(
      'resolveStageWeights y resolveNutritionPriorities delegan al doc 05',
      () {
        final weights = definition.resolveStageWeights(
          stageOf(TreeStageIds.fruitFill),
        );
        // Misma fuente que resolveAppleTreeStageWeights.
        expect(
          weights.npk,
          resolveAppleTreeStageWeights(TreeStageIds.fruitFill).npk,
        );

        final nutrition = definition.resolveNutritionPriorities(
          stageOf(TreeStageIds.fruitFill),
        );
        expect(nutrition.dominantNutrient, AgroMetricKey.k);
      },
    );

    test('root_establishment pondera agua, EC y resistencia (suelo/raíz)', () {
      final w = resolveAppleTreeStageWeights(TreeStageIds.rootEstablishment);
      // Agua manda en establecimiento.
      expect(w.moisture, greaterThanOrEqualTo(0.25));
      // EC y resistencia pesan por encima del NPK (raíz fina, baja salinidad).
      expect(w.ec, greaterThan(w.npk!));
      expect(w.resistance, greaterThan(w.npk!));
    });

    test('flowering prioriza agua/temperatura por encima de NPK', () {
      final w = resolveAppleTreeStageWeights(TreeStageIds.flowering);
      expect(w.moisture, greaterThan(w.npk!));
      expect(w.soilTemp, greaterThanOrEqualTo(w.npk!));
    });
  });
}
