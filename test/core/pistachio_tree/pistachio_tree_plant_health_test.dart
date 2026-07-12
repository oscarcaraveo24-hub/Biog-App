// test/core/pistachio_tree/pistachio_tree_plant_health_test.dart
//
// Sanidad/Plant Health del Pistache por etapa fenologica (doc 04). Catalogo
// propio de frutal de nuez DIOICO: falta/desfase de macho, frio insuficiente,
// blanks/non-split, navel orangeworm, Botryosphaeria/Alternaria, salinidad/early
// split. No reusa el catalogo de nogal. post_harvest NO se apaga (momias,
// reservas, alternancia); unknown conservador.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<PlantHealthSyndrome> catalog = PlantHealthRegistry.catalogForCrop(
    CropCatalog.pistachioTreeCropId,
  );

  PlantHealthStageBucket? bucket(String stage) =>
      PlantHealthStageAdapter.fromCropStage(
        cropId: 'pistachio_tree',
        stageKey: stage,
        daySinceSowing: null,
      );

  Set<String> activeAt(String stage) {
    final b = bucket(stage);
    if (b == null) return <String>{};
    return catalog.where((s) => s.stages.contains(b)).map((s) => s.id).toSet();
  }

  group('Registro de sindromes del pistache', () {
    test('crop_pistachio_tree tiene catalogo y soporta alias humano', () {
      expect(catalog, isNotEmpty);
      expect(PlantHealthRegistry.isSupportedCrop('pistachio_tree'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('pistache'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('pistacho'), isTrue);
    });

    test('todos orientan (no recetan) y son del pistache', () {
      for (final s in catalog) {
        expect(s.cropId, CropCatalog.pistachioTreeCropId);
        expect(s.disclaimerEs, isNotEmpty);
      }
    });

    test('catalogo propio de pistache: macho/hembra, NOW, Botryosphaeria, blanks', () {
      final allText = catalog
          .map((s) => s.probableDiagnoses.map((d) => d.id).join(' '))
          .join(' ')
          .toLowerCase();
      // No reusa identidades de nogal/pepita/hueso.
      expect(allText, isNot(contains('hickory_shuckworm')));
      expect(allText, isNot(contains('pecan_nut_casebearer')));
      expect(allText, isNot(contains('peach_leaf_curl')));
      // Identidades propias del pistache.
      expect(allText, contains('missing_or_mismatched_male_pollination'));
      expect(allText, contains('navel_orangeworm'));
      expect(allText, contains('botryosphaeria_panicle_shoot_blight'));
      expect(allText, contains('blank_nuts_pollination_chill'));
    });
  });

  group('Adaptacion por etapa fenologica del pistache', () {
    test('el pistache SI tiene adaptacion por etapa', () {
      expect(bucket(TreeStageIds.flowering), isNotNull);
      expect(bucket(TreeStageIds.fruitSet), isNotNull);
      expect(bucket(TreeStageIds.fruitFill), isNotNull);
      expect(bucket(TreeStageIds.postHarvest), isNotNull);
    });

    test('flowering prioriza macho/hembra, frio y polinizacion (dioico)', () {
      expect(
        bucket(TreeStageIds.flowering),
        PlantHealthStageBucket.reproductiveEarly,
      );
      final ids = activeAt(TreeStageIds.flowering);
      expect(ids, contains('pistachio_chill_frost_pollination_01'));
    });

    test('budbreak prioriza micronutrientes (zinc/Fe/Cu)', () {
      expect(
        bucket(TreeStageIds.budbreak),
        PlantHealthStageBucket.vegetativeEarly,
      );
      final ids = activeAt(TreeStageIds.budbreak);
      expect(ids, contains('pistachio_micronutrient_chlorosis_01'));
    });

    test('fruit_fill prioriza blanks, NOW/chinches, enfermedades y salinidad', () {
      expect(
        bucket(TreeStageIds.fruitFill),
        PlantHealthStageBucket.reproductiveMid,
      );
      final ids = activeAt(TreeStageIds.fruitFill);
      expect(ids, contains('pistachio_blanks_nonsplit_01'), reason: 'blanks');
      expect(ids, contains('pistachio_now_bug_kernel_01'), reason: 'NOW/chinches');
      expect(
        ids,
        contains('pistachio_panicle_shoot_blight_01'),
        reason: 'Botryosphaeria/Alternaria',
      );
      expect(
        ids,
        contains('pistachio_salinity_water_quality_01'),
        reason: 'salinidad/early split',
      );
    });

    test('harvest_maturity prioriza NOW/mummies y apertura/calidad', () {
      expect(
        bucket(TreeStageIds.harvestMaturity),
        PlantHealthStageBucket.grainFill,
      );
      final ids = activeAt(TreeStageIds.harvestMaturity);
      expect(ids, contains('pistachio_now_bug_kernel_01'));
      expect(ids, contains('pistachio_postharvest_alternance_01'));
    });

    test('post_harvest NO queda apagada: momias/alternancia/chupadores siguen', () {
      expect(
        bucket(TreeStageIds.postHarvest),
        PlantHealthStageBucket.lateSeason,
      );
      final ids = activeAt(TreeStageIds.postHarvest);
      expect(ids, isNotEmpty);
      expect(ids, contains('pistachio_postharvest_alternance_01'));
      expect(ids, contains('pistachio_sucking_pests_mites_01'));
      expect(ids, contains('pistachio_salinity_water_quality_01'));
    });

    test('post_harvest se evalua antes que harvest (contiene "harvest")', () {
      expect(
        bucket(TreeStageIds.postHarvest),
        PlantHealthStageBucket.lateSeason,
      );
      expect(
        bucket(TreeStageIds.harvestMaturity),
        PlantHealthStageBucket.grainFill,
      );
    });

    test('unknown es conservador: sin bono de etapa (bucket null)', () {
      expect(bucket(TreeStageIds.unknown), isNull);
    });
  });

  group('Perfiles PS ajustan sensibilidad (varietyModifiers)', () {
    test('PS-01 Kerman sube el frio insuficiente en floracion', () {
      final bloom = catalog.firstWhere(
        (s) => s.id == 'pistachio_chill_frost_pollination_01',
      );
      final hasKerman = bloom.varietyModifiers.any(
        (m) => m.varietyIds.contains(kPs01KermanPeters),
      );
      expect(hasKerman, isTrue);
    });

    test('PS-05 bajo-frio sube la helada en brotacion/floracion', () {
      final bloom = catalog.firstWhere(
        (s) => s.id == 'pistachio_chill_frost_pollination_01',
      );
      final hasLowChill = bloom.varietyModifiers.any(
        (m) => m.varietyIds.contains(kPs05LarnakaMateurLowChill),
      );
      expect(hasLowChill, isTrue);
    });
  });
}
