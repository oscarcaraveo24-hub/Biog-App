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
        expect(targets.ph.optimalMin, 6.0, reason: 'pH min en $stage');
        expect(targets.ph.optimalMax, 6.8, reason: 'pH max en $stage');
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
