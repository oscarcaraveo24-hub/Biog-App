// test/core/apple_tree/apple_tree_plant_health_test.dart
//
// Integración del manzano con el módulo Plant Health (doc 04): el catálogo
// queda registrado y las etapas perennes mapean a buckets del motor.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Registro de síndromes del manzano', () {
    test('crop_apple_tree tiene catálogo de riesgos registrado', () {
      final catalog = PlantHealthRegistry.catalogForCrop(
        CropCatalog.appleTreeCropId,
      );
      expect(catalog, isNotEmpty);
      expect(PlantHealthRegistry.isSupportedCrop('apple_tree'), isTrue);
    });

    test('todos los síndromes son del manzano y orientan (no recetan)', () {
      final catalog = PlantHealthRegistry.catalogForCrop('apple_tree');
      for (final s in catalog) {
        expect(s.cropId, CropCatalog.appleTreeCropId);
        expect(s.disclaimerEs, isNotEmpty);
      }
    });

    test(
      'cubre las familias clave (tizón de fuego, sarna, palomilla, etc.)',
      () {
        final ids = PlantHealthRegistry.catalogForCrop(
          'apple_tree',
        ).map((s) => s.id).toSet();
        expect(ids, contains('apple_fire_blight_01'));
        expect(ids, contains('apple_scab_01'));
        expect(ids, contains('apple_codling_moth_01'));
        expect(ids, contains('apple_woolly_aphid_01'));
        expect(ids, contains('apple_bitter_pit_01'));
      },
    );
  });

  group('Mapeo de etapa perenne a bucket de sanidad', () {
    PlantHealthStageBucket? bucket(String stage) =>
        PlantHealthStageAdapter.fromCropStage(
          cropId: 'apple_tree',
          stageKey: stage,
          daySinceSowing: null,
        );

    test('floración → reproductiveEarly; cuajado → reproductiveMid', () {
      expect(
        bucket(TreeStageIds.flowering),
        PlantHealthStageBucket.reproductiveEarly,
      );
      expect(
        bucket(TreeStageIds.fruitSet),
        PlantHealthStageBucket.reproductiveMid,
      );
    });

    test('llenado/cosecha → grainFill; reposo/postcosecha → lateSeason', () {
      expect(bucket(TreeStageIds.fruitFill), PlantHealthStageBucket.grainFill);
      expect(
        bucket(TreeStageIds.harvestMaturity),
        PlantHealthStageBucket.grainFill,
      );
      expect(bucket(TreeStageIds.dormancy), PlantHealthStageBucket.lateSeason);
      expect(
        bucket(TreeStageIds.postHarvest),
        PlantHealthStageBucket.lateSeason,
      );
    });

    test('unknown no fuerza bucket (devuelve null)', () {
      expect(bucket(TreeStageIds.unknown), isNull);
    });
  });
}
