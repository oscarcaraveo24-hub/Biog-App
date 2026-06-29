// test/core/walnut_tree/walnut_tree_plant_health_test.dart
//
// Sanidad/Plant Health del Nogal por etapa fenologica (doc 04). Catalogo propio
// de frutal de nuez: zinc/roseta, pudricion texana de raiz, barrenador de la
// nuez/ruezno, pulgon amarillo/negro, shuck decline, salinidad. No reusa el
// catalogo de manzano/pera/durazno. post_harvest NO se apaga; unknown conservador.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<PlantHealthSyndrome> catalog = PlantHealthRegistry.catalogForCrop(
    CropCatalog.walnutTreeCropId,
  );

  PlantHealthStageBucket? bucket(String stage) =>
      PlantHealthStageAdapter.fromCropStage(
        cropId: 'walnut_tree',
        stageKey: stage,
        daySinceSowing: null,
      );

  Set<String> activeAt(String stage) {
    final b = bucket(stage);
    if (b == null) return <String>{};
    return catalog.where((s) => s.stages.contains(b)).map((s) => s.id).toSet();
  }

  group('Registro de sindromes del nogal', () {
    test('crop_walnut_tree tiene catalogo y soporta alias humano', () {
      expect(catalog, isNotEmpty);
      expect(PlantHealthRegistry.isSupportedCrop('walnut_tree'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('nogal'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('pecan'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('nuez'), isTrue);
    });

    test('todos orientan (no recetan) y son del nogal', () {
      for (final s in catalog) {
        expect(s.cropId, CropCatalog.walnutTreeCropId);
        expect(s.disclaimerEs, isNotEmpty);
      }
    });

    test('catalogo propio de nuez: zinc, casebearer, shuckworm, pulgones', () {
      final allText = catalog
          .map((s) => s.probableDiagnoses.map((d) => d.id).join(' '))
          .join(' ')
          .toLowerCase();
      // No reusa identidades de pepita/hueso.
      expect(allText, isNot(contains('fire_blight')));
      expect(allText, isNot(contains('pear_psylla')));
      expect(allText, isNot(contains('peach_leaf_curl')));
      // Identidades propias del nogal.
      expect(allText, contains('zinc_deficiency_rosette_little_leaf'));
      expect(allText, contains('pecan_nut_casebearer'));
      expect(allText, contains('hickory_shuckworm'));
      expect(allText, contains('black_pecan_aphid'));
    });
  });

  group('Adaptacion por etapa fenologica del nogal', () {
    test('el nogal SI tiene adaptacion por etapa', () {
      expect(bucket(TreeStageIds.flowering), isNotNull);
      expect(bucket(TreeStageIds.fruitSet), isNotNull);
      expect(bucket(TreeStageIds.fruitFill), isNotNull);
      expect(bucket(TreeStageIds.postHarvest), isNotNull);
    });

    test('flowering prioriza helada en flor y polinizacion', () {
      expect(bucket(TreeStageIds.flowering), PlantHealthStageBucket.reproductiveEarly);
      final ids = activeAt(TreeStageIds.flowering);
      expect(ids, contains('walnut_frost_pollination_01'));
    });

    test('budbreak prioriza zinc/roseta', () {
      expect(bucket(TreeStageIds.budbreak), PlantHealthStageBucket.vegetativeEarly);
      final ids = activeAt(TreeStageIds.budbreak);
      expect(ids, contains('walnut_zinc_rosette_01'));
    });

    test('fruit_fill prioriza nuez/ruezno, pulgones, shuck decline y salinidad', () {
      expect(bucket(TreeStageIds.fruitFill), PlantHealthStageBucket.reproductiveMid);
      final ids = activeAt(TreeStageIds.fruitFill);
      expect(ids, contains('walnut_nut_shuck_pests_01'), reason: 'barrenadores');
      expect(ids, contains('walnut_aphids_mites_01'), reason: 'pulgones/acaros');
      expect(ids, contains('walnut_shuck_decline_01'), reason: 'shuck decline');
      expect(ids, contains('walnut_salinity_leaf_burn_01'), reason: 'salinidad');
    });

    test('harvest_maturity prioriza barrenador de ruezno y mancha de almendra', () {
      expect(bucket(TreeStageIds.harvestMaturity), PlantHealthStageBucket.grainFill);
      final ids = activeAt(TreeStageIds.harvestMaturity);
      expect(ids, contains('walnut_nut_shuck_pests_01'));
      expect(ids, contains('walnut_kernel_spot_01'));
    });

    test('post_harvest NO queda apagada: pulgones/salinidad/madera siguen', () {
      expect(bucket(TreeStageIds.postHarvest), PlantHealthStageBucket.lateSeason);
      final ids = activeAt(TreeStageIds.postHarvest);
      expect(ids, isNotEmpty);
      expect(ids, contains('walnut_aphids_mites_01'));
      expect(ids, contains('walnut_salinity_leaf_burn_01'));
      expect(ids, contains('walnut_trunk_borer_decline_01'));
    });

    test('post_harvest se evalua antes que harvest (contiene "harvest")', () {
      expect(bucket(TreeStageIds.postHarvest), PlantHealthStageBucket.lateSeason);
      expect(bucket(TreeStageIds.harvestMaturity), PlantHealthStageBucket.grainFill);
    });

    test('unknown es conservador: sin bono de etapa (bucket null)', () {
      expect(bucket(TreeStageIds.unknown), isNull);
    });
  });

  group('Perfiles NG ajustan sensibilidad (varietyModifiers)', () {
    test('NG-02 Wichita sube la deficiencia de zinc', () {
      final zinc = catalog.firstWhere((s) => s.id == 'walnut_zinc_rosette_01');
      final hasNg02 = zinc.varietyModifiers.any(
        (m) => m.varietyIds.contains('ng_02_wichita'),
      );
      expect(hasNg02, isTrue);
    });

    test('NG-05 temprano sube la helada en floracion', () {
      final frost = catalog.firstWhere(
        (s) => s.id == 'walnut_frost_pollination_01',
      );
      final hasNg05 = frost.varietyModifiers.any(
        (m) => m.varietyIds.contains('ng_05_temprano_pawnee_kanza'),
      );
      expect(hasNg05, isTrue);
    });
  });
}
