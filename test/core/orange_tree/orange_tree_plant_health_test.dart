// test/core/orange_tree/orange_tree_plant_health_test.dart
//
// Sanidad/Plant Health del Naranjo por etapa fenologica (doc 04). Catalogo
// propio de citrico siempreverde: HLB/psilido, gomosis/Phytophthora, salinidad,
// minador/chupadores, caida de flor/frutito (Navel), enfermedades foliares y de
// fruto, desordenes abioticos, nutricion aparente y memoria perenne. No reusa el
// catalogo del pistache. post_harvest y dormancy NO se apagan; unknown
// conservador. BIO-G orienta, NO cierra HLB/VTC/cancro/Phytophthora.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<PlantHealthSyndrome> catalog = PlantHealthRegistry.catalogForCrop(
    CropCatalog.orangeTreeCropId,
  );

  PlantHealthStageBucket? bucket(String stage) =>
      PlantHealthStageAdapter.fromCropStage(
        cropId: 'orange_tree',
        stageKey: stage,
        daySinceSowing: null,
      );

  Set<String> activeAt(String stage) {
    final b = bucket(stage);
    if (b == null) return <String>{};
    return catalog.where((s) => s.stages.contains(b)).map((s) => s.id).toSet();
  }

  group('Registro de sindromes del naranjo', () {
    test('crop_orange_tree tiene catalogo y soporta alias humano', () {
      expect(catalog, isNotEmpty);
      expect(PlantHealthRegistry.isSupportedCrop('orange_tree'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('naranjo'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('naranja'), isTrue);
    });

    test('todos orientan (no recetan) y son del naranjo', () {
      for (final s in catalog) {
        expect(s.cropId, CropCatalog.orangeTreeCropId);
        expect(s.disclaimerEs, isNotEmpty);
      }
    });

    test('catalogo propio de naranjo: HLB, psilido, gomosis, Navel drop', () {
      final allText = catalog
          .map((s) => s.probableDiagnoses.map((d) => d.id).join(' '))
          .join(' ')
          .toLowerCase();
      // No reusa identidades del pistache/nogal/pepita/hueso.
      expect(allText, isNot(contains('missing_or_mismatched_male_pollination')));
      expect(allText, isNot(contains('botryosphaeria_panicle_shoot_blight')));
      expect(allText, isNot(contains('hickory_shuckworm')));
      expect(allText, isNot(contains('peach_leaf_curl')));
      // Identidades propias del naranjo/citrico.
      expect(allText, contains('huanglongbing_hlb_context'));
      expect(allText, contains('asian_citrus_psyllid_vector'));
      expect(allText, contains('phytophthora_gummosis_foot_rot'));
      expect(allText, contains('navel_orange_fruit_drop_context'));
      expect(allText, contains('flowering_heat_water_stress'));
      expect(allText, contains('iron_zinc_manganese_chlorosis_high_ph'));
    });

    test('HLB/VTC/cancro se manejan como contexto, no diagnostico cerrado', () {
      final hlb = catalog.firstWhere(
        (s) => s.id == 'orange_hlb_psyllid_context_01',
      );
      // Severidad critica con cautela; el disclaimer pide confirmacion.
      expect(hlb.severity, PlantHealthSeverity.critical);
      expect(hlb.disclaimerEs.toLowerCase(), contains('confirm'));
      expect(hlb.favorsVectorPressure, isTrue);
    });
  });

  group('Adaptacion por etapa fenologica del naranjo', () {
    test('el naranjo SI tiene adaptacion por etapa', () {
      expect(bucket(TreeStageIds.flowering), isNotNull);
      expect(bucket(TreeStageIds.fruitSet), isNotNull);
      expect(bucket(TreeStageIds.fruitFill), isNotNull);
      expect(bucket(TreeStageIds.postHarvest), isNotNull);
    });

    test('flowering prioriza floracion/cuajado, calor/helada y caida', () {
      expect(
        bucket(TreeStageIds.flowering),
        PlantHealthStageBucket.reproductiveEarly,
      );
      final ids = activeAt(TreeStageIds.flowering);
      expect(ids, contains('orange_flowering_set_drop_01'));
    });

    test('budbreak prioriza brotacion tierna (minador/psilido/pulgones)', () {
      expect(
        bucket(TreeStageIds.budbreak),
        PlantHealthStageBucket.vegetativeEarly,
      );
      final ids = activeAt(TreeStageIds.budbreak);
      expect(ids, contains('orange_flush_pests_01'));
    });

    test('fruit_fill prioriza fruto/HLB, enfermedades y desordenes abioticos', () {
      expect(
        bucket(TreeStageIds.fruitFill),
        PlantHealthStageBucket.reproductiveMid,
      );
      final ids = activeAt(TreeStageIds.fruitFill);
      expect(ids, contains('orange_hlb_psyllid_context_01'), reason: 'HLB');
      expect(
        ids,
        contains('orange_fruit_disease_rot_01'),
        reason: 'pudriciones de fruto',
      );
      expect(
        ids,
        contains('orange_abiotic_fruit_disorders_01'),
        reason: 'rajado/sunburn',
      );
      expect(
        ids,
        contains('orange_nutrition_availability_01'),
        reason: 'Fe/Zn/Mn/K/salinidad',
      );
    });

    test('harvest_maturity prioriza pudriciones/mosca y memoria de cosecha', () {
      expect(
        bucket(TreeStageIds.harvestMaturity),
        PlantHealthStageBucket.grainFill,
      );
      final ids = activeAt(TreeStageIds.harvestMaturity);
      expect(ids, contains('orange_fruit_disease_rot_01'));
      expect(ids, contains('orange_postharvest_memory_01'));
    });

    test('post_harvest NO queda apagada: memoria/chupadores/nutricion siguen', () {
      expect(
        bucket(TreeStageIds.postHarvest),
        PlantHealthStageBucket.lateSeason,
      );
      final ids = activeAt(TreeStageIds.postHarvest);
      expect(ids, isNotEmpty);
      expect(ids, contains('orange_postharvest_memory_01'));
      expect(ids, contains('orange_sucking_pests_sooty_01'));
      expect(ids, contains('orange_nutrition_availability_01'));
    });

    test('dormancy NO queda apagada (citrico siempreverde) y va a lateSeason', () {
      expect(bucket(TreeStageIds.dormancy), PlantHealthStageBucket.lateSeason);
      expect(activeAt(TreeStageIds.dormancy), isNotEmpty);
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

  group('Perfiles OR ajustan sensibilidad (varietyModifiers)', () {
    test('OR-02 Navel sube la caida de fruto en cuajado', () {
      final drop = catalog.firstWhere(
        (s) => s.id == 'orange_flowering_set_drop_01',
      );
      final hasNavel = drop.varietyModifiers.any(
        (m) =>
            m.varietyIds.contains(kOr02Navel) &&
            m.diagnosisIds.contains('navel_orange_fruit_drop_context'),
      );
      expect(hasNavel, isTrue);
    });

    test('OR-01 Valencia / OR-05 tropical suben el agotamiento de reservas', () {
      final memory = catalog.firstWhere(
        (s) => s.id == 'orange_postharvest_memory_01',
      );
      final hasValenciaOrTropical = memory.varietyModifiers.any(
        (m) =>
            m.varietyIds.contains(kOr01Valencia) ||
            m.varietyIds.contains(kOr05TropicalCalido),
      );
      expect(hasValenciaOrTropical, isTrue);
    });
  });
}
