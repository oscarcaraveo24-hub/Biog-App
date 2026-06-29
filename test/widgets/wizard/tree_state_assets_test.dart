// test/widgets/wizard/tree_state_assets_test.dart
//
// Los íconos de ESTADO GENERAL del wizard de árboles (brotación, flor, fruto,
// reposo, etc.) son compartidos por Manzano, Pera y futuros frutales: deben
// resolver a `ic_tree_*` y NO a los antiguos `ic_apple_tree_*` (renombrados).

import 'dart:io';

import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_components.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_pages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Estados generales del árbol → ic_tree_*.
  const treeStateIcons = <String, String>{
    'youngNotFruiting': ConfigureSeedWizardAssets.treeYoungNotFruiting,
    'unknownState': ConfigureSeedWizardAssets.treeUnknownState,
    'growingOnly': ConfigureSeedWizardAssets.treeGrowingOnly,
    'hasFlower': ConfigureSeedWizardAssets.treeHasFlower,
    'tinyFruit': ConfigureSeedWizardAssets.treeTinyFruit,
    'fruitGrowing': ConfigureSeedWizardAssets.treeFruitGrowing,
    'dormantLeafless': ConfigureSeedWizardAssets.treeDormantLeafless,
    'budding': ConfigureSeedWizardAssets.treeBudding,
    'fullFoliage': ConfigureSeedWizardAssets.treeFullFoliage,
    'flowering': ConfigureSeedWizardAssets.treeFlowering,
    'fruitSetFlowerDrop': ConfigureSeedWizardAssets.treeFruitSetFlowerDrop,
    'greenFruitGrowing': ConfigureSeedWizardAssets.treeGreenFruitGrowing,
    'readyHarvest': ConfigureSeedWizardAssets.treeReadyHarvest,
    'afterHarvest': ConfigureSeedWizardAssets.treeAfterHarvest,
  };

  group('Assets genéricos de estado del árbol', () {
    test('cada estado resuelve a ic_tree_* (no ic_apple_tree_*)', () {
      treeStateIcons.forEach((name, path) {
        expect(
          path,
          startsWith('assets/icons/wizard/ic_tree_'),
          reason: '$name → $path',
        );
        expect(path, isNot(contains('ic_apple_tree_')), reason: name);
      });
    });

    test('los PNG genéricos de árbol existen en disco', () {
      for (final path in treeStateIcons.values) {
        expect(File(path).existsSync(), isTrue, reason: 'falta $path');
      }
    });

    test('el ícono de categoría Árbol es ic_tree.png (no ic_arbol.png)', () {
      expect(
        ConfigureSeedWizardAssets.categoryTree,
        'assets/icons/wizard/ic_tree.png',
      );
      expect(
        File(ConfigureSeedWizardAssets.categoryTree).existsSync(),
        isTrue,
      );
    });

    test('el resolver de etapas usa solo iconos ic_tree_*', () {
      const expected = <String, String>{
        TreeStageIds.plantingTransplant:
            ConfigureSeedWizardAssets.treeYoungNotFruiting,
        TreeStageIds.rootEstablishment:
            ConfigureSeedWizardAssets.treeYoungNotFruiting,
        TreeStageIds.juvenileVegetative:
            ConfigureSeedWizardAssets.treeGrowingOnly,
        TreeStageIds.dormancy:
            ConfigureSeedWizardAssets.treeDormantLeafless,
        TreeStageIds.budbreak: ConfigureSeedWizardAssets.treeBudding,
        TreeStageIds.vegetativeGrowth:
            ConfigureSeedWizardAssets.treeFullFoliage,
        TreeStageIds.flowering: ConfigureSeedWizardAssets.treeFlowering,
        TreeStageIds.fruitSet:
            ConfigureSeedWizardAssets.treeFruitSetFlowerDrop,
        TreeStageIds.fruitFill:
            ConfigureSeedWizardAssets.treeGreenFruitGrowing,
        TreeStageIds.harvestMaturity:
            ConfigureSeedWizardAssets.treeReadyHarvest,
        TreeStageIds.postHarvest:
            ConfigureSeedWizardAssets.treeAfterHarvest,
        TreeStageIds.unknown: ConfigureSeedWizardAssets.treeUnknownState,
      };

      expected.forEach((stageId, expectedPath) {
        final path = ConfigureSeedWizardAssets.treeStageIconFor(stageId);
        expect(path, expectedPath, reason: stageId);
        expect(path, startsWith('assets/icons/wizard/ic_tree'), reason: stageId);
        expect(path, isNot(contains('assets/seeds/')), reason: stageId);
        expect(path, isNot(contains('ic_apple_')), reason: stageId);
        expect(path, isNot(contains('ic_pear_')), reason: stageId);
      });
    });

    test('los estados productivos generales no dependen del cultivo', () {
      expect(
        ConfigureSeedWizardAssets.treeProductionStatusIconFor(
          TreeProductionStatusIds.nonProductive,
        ),
        ConfigureSeedWizardAssets.treeYoungNotFruiting,
      );
      expect(
        ConfigureSeedWizardAssets.treeProductionStatusIconFor(
          TreeProductionStatusIds.productiveOrProduced,
        ),
        ConfigureSeedWizardAssets.categoryTree,
      );
      expect(
        ConfigureSeedWizardAssets.treeProductionStatusIconFor(
          TreeProductionStatusIds.unknown,
        ),
        ConfigureSeedWizardAssets.treeUnknownState,
      );
    });

    test('las senales reproductivas tienen iconos propios de pregunta', () {
      expect(
        treeReproSignalIconPath(TreeReproSignalOptionIds.growingOnly),
        ConfigureSeedWizardAssets.treeGrowingOnly,
      );
      expect(
        treeReproSignalIconPath(TreeReproSignalOptionIds.hasFlower),
        ConfigureSeedWizardAssets.treeHasFlower,
      );
      expect(
        treeReproSignalIconPath(TreeReproSignalOptionIds.hasFruitSet),
        ConfigureSeedWizardAssets.treeTinyFruit,
      );
      expect(
        treeReproSignalIconPath(TreeReproSignalOptionIds.hasFruitFill),
        ConfigureSeedWizardAssets.treeFruitGrowing,
      );
      expect(
        treeReproSignalIconPath(TreeReproSignalOptionIds.notSure),
        ConfigureSeedWizardAssets.treeUnknownState,
      );
    });
  });
}
