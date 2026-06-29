// test/core/pear_tree/pear_tree_plant_health_test.dart
//
// Sanidad/Plant Health de la Pera por etapa fenológica (doc 04 §6). Antes de
// esta pasada el adapter no mapeaba la pera y devolvía null en todas las etapas;
// ahora cada etapa filtra/pondera sus riesgos propios sin reusar el manzano.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<PlantHealthSyndrome> catalog = PlantHealthRegistry.catalogForCrop(
    CropCatalog.pearTreeCropId,
  );

  PlantHealthStageBucket? bucket(String stage) =>
      PlantHealthStageAdapter.fromCropStage(
        cropId: 'pear_tree',
        stageKey: stage,
        daySinceSowing: null,
      );

  // Síndromes de pera "activos" (con bono de etapa) en una etapa fenológica.
  Set<String> activeAt(String stage) {
    final b = bucket(stage);
    if (b == null) return <String>{};
    return catalog
        .where((s) => s.stages.contains(b))
        .map((s) => s.id)
        .toSet();
  }

  group('Registro de síndromes de la pera', () {
    test('crop_pear_tree tiene catálogo y soporta alias humano', () {
      expect(catalog, isNotEmpty);
      expect(PlantHealthRegistry.isSupportedCrop('pear_tree'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('pera'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('peral'), isTrue);
    });

    test('todos orientan (no recetan) y son de la pera', () {
      for (final s in catalog) {
        expect(s.cropId, CropCatalog.pearTreeCropId);
        expect(s.disclaimerEs, isNotEmpty);
      }
    });
  });

  group('Adaptación por etapa fenológica de la pera', () {
    test('la pera SÍ tiene adaptación por etapa (no null como antes)', () {
      expect(bucket(TreeStageIds.flowering), isNotNull);
      expect(bucket(TreeStageIds.fruitSet), isNotNull);
      expect(bucket(TreeStageIds.fruitFill), isNotNull);
      expect(bucket(TreeStageIds.postHarvest), isNotNull);
    });

    test('flowering prioriza fuego bacteriano, polinización y helada', () {
      expect(bucket(TreeStageIds.flowering), PlantHealthStageBucket.reproductiveEarly);
      final ids = activeAt(TreeStageIds.flowering);
      expect(ids, contains('pear_fire_blight_01'));
      expect(ids, contains('pear_frost_pollination_01'));
    });

    test('fruit_fill prioriza psila/carpocapsa/roña y calidad de fruto', () {
      expect(bucket(TreeStageIds.fruitFill), PlantHealthStageBucket.reproductiveMid);
      final ids = activeAt(TreeStageIds.fruitFill);
      expect(ids, contains('pear_psylla_01'), reason: 'psila');
      expect(ids, contains('pear_codling_moth_01'), reason: 'carpocapsa');
      expect(ids, contains('pear_scab_leaf_spot_01'), reason: 'roña/Fabraea');
      expect(ids, contains('pear_mites_russet_01'), reason: 'calidad/russeting');
      expect(ids, contains('pear_sunburn_01'), reason: 'golpe de sol');
    });

    test('post_harvest NO queda apagada: psila y sanidad residual siguen', () {
      expect(bucket(TreeStageIds.postHarvest), PlantHealthStageBucket.lateSeason);
      final ids = activeAt(TreeStageIds.postHarvest);
      expect(ids, isNotEmpty);
      expect(ids, contains('pear_psylla_01'));
      expect(ids, contains('pear_scab_leaf_spot_01'));
    });

    test('post_harvest se evalúa antes que harvest (contiene "harvest")', () {
      expect(bucket(TreeStageIds.postHarvest), PlantHealthStageBucket.lateSeason);
      expect(bucket(TreeStageIds.harvestMaturity), PlantHealthStageBucket.grainFill);
    });

    test('unknown es conservador: sin bono de etapa (bucket null)', () {
      expect(bucket(TreeStageIds.unknown), isNull);
    });
  });
}
