// test/core/peach_tree/peach_tree_plant_health_test.dart
//
// Sanidad/Plant Health del Durazno por etapa fenológica (doc 04). Catálogo
// propio de frutal de hueso: torque/lepra, pudrición café (Monilinia), tiro de
// munición, barrenador (goma+aserrín), palomilla oriental, split pit. No reusa
// el catálogo de manzano/pera. post_harvest NO se apaga; unknown es conservador.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<PlantHealthSyndrome> catalog = PlantHealthRegistry.catalogForCrop(
    CropCatalog.peachTreeCropId,
  );

  PlantHealthStageBucket? bucket(String stage) =>
      PlantHealthStageAdapter.fromCropStage(
        cropId: 'peach_tree',
        stageKey: stage,
        daySinceSowing: null,
      );

  Set<String> activeAt(String stage) {
    final b = bucket(stage);
    if (b == null) return <String>{};
    return catalog
        .where((s) => s.stages.contains(b))
        .map((s) => s.id)
        .toSet();
  }

  group('Registro de síndromes del durazno', () {
    test('crop_peach_tree tiene catálogo y soporta alias humano', () {
      expect(catalog, isNotEmpty);
      expect(PlantHealthRegistry.isSupportedCrop('peach_tree'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('durazno'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('duraznero'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('melocoton'), isTrue);
    });

    test('todos orientan (no recetan) y son del durazno', () {
      for (final s in catalog) {
        expect(s.cropId, CropCatalog.peachTreeCropId);
        expect(s.disclaimerEs, isNotEmpty);
      }
    });

    test('el catálogo es propio de hueso: no reusa fuego bacteriano ni psila', () {
      final allText = catalog
          .map((s) => s.probableDiagnoses.map((d) => d.id).join(' '))
          .join(' ')
          .toLowerCase();
      expect(allText, isNot(contains('fire_blight')));
      expect(allText, isNot(contains('pear_psylla')));
      expect(allText, contains('peach_leaf_curl_taphrina'));
      expect(allText, contains('brown_rot_monilinia'));
      expect(allText, contains('peachtree_borer'));
    });
  });

  group('Adaptación por etapa fenológica del durazno', () {
    test('el durazno SÍ tiene adaptación por etapa', () {
      expect(bucket(TreeStageIds.flowering), isNotNull);
      expect(bucket(TreeStageIds.fruitSet), isNotNull);
      expect(bucket(TreeStageIds.fruitFill), isNotNull);
      expect(bucket(TreeStageIds.postHarvest), isNotNull);
    });

    test('flowering prioriza helada en flor y Monilinia (blossom blight)', () {
      expect(bucket(TreeStageIds.flowering), PlantHealthStageBucket.reproductiveEarly);
      final ids = activeAt(TreeStageIds.flowering);
      expect(ids, contains('peach_frost_bloom_01'));
    });

    test('budbreak prioriza torque/lepra (Taphrina)', () {
      expect(bucket(TreeStageIds.budbreak), PlantHealthStageBucket.vegetativeEarly);
      final ids = activeAt(TreeStageIds.budbreak);
      expect(ids, contains('peach_leaf_curl_01'));
    });

    test('fruit_fill prioriza carga/raleo, palomilla, foliares y golpe de sol', () {
      expect(bucket(TreeStageIds.fruitFill), PlantHealthStageBucket.reproductiveMid);
      final ids = activeAt(TreeStageIds.fruitFill);
      expect(ids, contains('peach_overcrop_split_pit_01'), reason: 'carga/split pit');
      expect(ids, contains('peach_oriental_fruit_moth_01'), reason: 'palomilla');
      expect(ids, contains('peach_shot_hole_bacterial_spot_01'), reason: 'foliar');
      expect(ids, contains('peach_mites_01'), reason: 'ácaros');
      expect(ids, contains('peach_sunburn_01'), reason: 'golpe de sol');
    });

    test('harvest_maturity prioriza pudrición café / Monilinia', () {
      expect(bucket(TreeStageIds.harvestMaturity), PlantHealthStageBucket.grainFill);
      final ids = activeAt(TreeStageIds.harvestMaturity);
      expect(ids, contains('peach_brown_rot_01'));
    });

    test('post_harvest NO queda apagada: ácaros/foliares/barrenadores siguen', () {
      expect(bucket(TreeStageIds.postHarvest), PlantHealthStageBucket.lateSeason);
      final ids = activeAt(TreeStageIds.postHarvest);
      expect(ids, isNotEmpty);
      expect(ids, contains('peach_mites_01'));
      expect(ids, contains('peach_shot_hole_bacterial_spot_01'));
      expect(ids, contains('peach_peachtree_borer_01'));
    });

    test('post_harvest se evalúa antes que harvest (contiene "harvest")', () {
      expect(bucket(TreeStageIds.postHarvest), PlantHealthStageBucket.lateSeason);
      expect(bucket(TreeStageIds.harvestMaturity), PlantHealthStageBucket.grainFill);
    });

    test('unknown es conservador: sin bono de etapa (bucket null)', () {
      expect(bucket(TreeStageIds.unknown), isNull);
    });
  });

  group('Perfiles DZ ajustan sensibilidad (varietyModifiers)', () {
    test('DZ-02 temprano/bajo frío sube la helada en floración', () {
      final frost = catalog.firstWhere((s) => s.id == 'peach_frost_bloom_01');
      final hasDz02 = frost.varietyModifiers.any(
        (m) => m.varietyIds.contains('dz_02_temprano_bajo_frio'),
      );
      expect(hasDz02, isTrue);
    });
  });
}
