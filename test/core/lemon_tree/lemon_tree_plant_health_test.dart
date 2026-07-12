// test/core/lemon_tree/lemon_tree_plant_health_test.dart
//
// Sanidad/Plant Health del Limon por etapa fenologica (doc 04). Catalogo propio
// de citrico siempreverde: HLB/psilido, gomosis/Phytophthora, salinidad,
// minador/chupadores, floracion/cuajado/desfase, antracnosis (mexicano),
// enfermedades foliares/fruto, desordenes abioticos, clima, nutricion aparente y
// memoria perenne. NO reusa el catalogo del naranjo (el limon NO es un naranjo
// pequeno). post_harvest y dormancy NO se apagan; unknown conservador. BIO-G
// orienta, NO cierra HLB/VTC/cancro/Phytophthora.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<PlantHealthSyndrome> catalog = PlantHealthRegistry.catalogForCrop(
    CropCatalog.lemonTreeCropId,
  );

  PlantHealthStageBucket? bucket(String stage) =>
      PlantHealthStageAdapter.fromCropStage(
        cropId: 'lemon_tree',
        stageKey: stage,
        daySinceSowing: null,
      );

  Set<String> activeAt(String stage) {
    final b = bucket(stage);
    if (b == null) return <String>{};
    return catalog.where((s) => s.stages.contains(b)).map((s) => s.id).toSet();
  }

  group('Registro de sindromes del limon', () {
    test('crop_lemon_tree tiene catalogo y soporta alias humano', () {
      expect(catalog, isNotEmpty);
      expect(PlantHealthRegistry.isSupportedCrop('lemon_tree'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('limon'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('limonero'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('lime_tree'), isTrue);
    });

    test('todos orientan (no recetan) y son del limon', () {
      for (final s in catalog) {
        expect(s.cropId, CropCatalog.lemonTreeCropId);
        expect(s.disclaimerEs, isNotEmpty);
      }
    });

    test('catalogo propio de limon: HLB, psilido, gomosis, antracnosis, desfase', () {
      final allText = catalog
          .map((s) => s.probableDiagnoses.map((d) => d.id).join(' '))
          .join(' ')
          .toLowerCase();
      // No reusa identidades del pistache/nogal/pepita/hueso ni del naranjo
      // (navel drop es del naranjo, no del limon).
      expect(allText, isNot(contains('navel_orange_fruit_drop_context')));
      expect(allText, isNot(contains('hickory_shuckworm')));
      // Identidades propias del limon/citrico.
      expect(allText, contains('huanglongbing_hlb_context'));
      expect(allText, contains('asian_citrus_psyllid_vector'));
      expect(allText, contains('phytophthora_gummosis_foot_rot'));
      expect(allText, contains('anthracnose_flower_fruit_shoot_complex'));
      expect(allText, contains('induced_bloom_stress_mismanagement'));
      expect(allText, contains('dry_fruit_low_juice_context'));
    });

    test('HLB/cancro/VTC se manejan como contexto, no diagnostico cerrado', () {
      final hlb = catalog.firstWhere(
        (s) => s.id == 'lemon_hlb_psyllid_regulated_01',
      );
      expect(hlb.severity, PlantHealthSeverity.critical);
      expect(hlb.disclaimerEs.toLowerCase(), contains('confirm'));
      expect(hlb.favorsVectorPressure, isTrue);
    });
  });

  group('Adaptacion por etapa fenologica del limon', () {
    test('el limon SI tiene adaptacion por etapa', () {
      expect(bucket(TreeStageIds.flowering), isNotNull);
      expect(bucket(TreeStageIds.fruitSet), isNotNull);
      expect(bucket(TreeStageIds.fruitFill), isNotNull);
      expect(bucket(TreeStageIds.postHarvest), isNotNull);
    });

    test('flowering prioriza floracion/cuajado/desfase', () {
      expect(
        bucket(TreeStageIds.flowering),
        PlantHealthStageBucket.reproductiveEarly,
      );
      final ids = activeAt(TreeStageIds.flowering);
      expect(ids, contains('lemon_flowering_set_drop_desfase_01'));
    });

    test('budbreak prioriza brotacion tierna (minador/psilido/pulgones)', () {
      expect(
        bucket(TreeStageIds.budbreak),
        PlantHealthStageBucket.vegetativeEarly,
      );
      final ids = activeAt(TreeStageIds.budbreak);
      expect(ids, contains('lemon_flush_pests_01'));
    });

    test('fruit_fill prioriza fruto/HLB, antracnosis y desordenes abioticos', () {
      expect(
        bucket(TreeStageIds.fruitFill),
        PlantHealthStageBucket.reproductiveMid,
      );
      final ids = activeAt(TreeStageIds.fruitFill);
      expect(ids, contains('lemon_hlb_psyllid_regulated_01'), reason: 'HLB');
      expect(
        ids,
        contains('lemon_abiotic_fruit_disorders_01'),
        reason: 'rajado/seco/sunburn',
      );
      expect(
        ids,
        contains('lemon_nutrition_availability_01'),
        reason: 'Fe/Zn/Mn/K/salinidad',
      );
    });

    test('harvest_maturity prioriza pudriciones/mosca y memoria de corte', () {
      expect(
        bucket(TreeStageIds.harvestMaturity),
        PlantHealthStageBucket.grainFill,
      );
      final ids = activeAt(TreeStageIds.harvestMaturity);
      expect(ids, contains('lemon_fruit_rot_quality_01'));
      expect(ids, contains('lemon_postharvest_memory_01'));
    });

    test('post_harvest NO queda apagada: memoria/chupadores/nutricion siguen', () {
      expect(
        bucket(TreeStageIds.postHarvest),
        PlantHealthStageBucket.lateSeason,
      );
      final ids = activeAt(TreeStageIds.postHarvest);
      expect(ids, isNotEmpty);
      expect(ids, contains('lemon_postharvest_memory_01'));
      expect(ids, contains('lemon_sucking_pests_sooty_mold_mites_01'));
      expect(ids, contains('lemon_nutrition_availability_01'));
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

  group('Perfiles LM ajustan sensibilidad (varietyModifiers)', () {
    test('LM-02 mexicano sube la antracnosis (eje propio del mexicano)', () {
      final anthracnose = catalog.firstWhere(
        (s) => s.id == 'lemon_anthracnose_flower_fruit_dieback_01',
      );
      final hasMexican = anthracnose.varietyModifiers.any(
        (m) =>
            m.varietyIds.contains(kLm02MexicanoColima) &&
            m.diagnosisIds.contains('anthracnose_flower_fruit_shoot_complex'),
      );
      expect(hasMexican, isTrue);
    });

    test('LM-05 desfase sube el estres inducido mal aplicado', () {
      final bloom = catalog.firstWhere(
        (s) => s.id == 'lemon_flowering_set_drop_desfase_01',
      );
      final hasDesfase = bloom.varietyModifiers.any(
        (m) =>
            m.varietyIds.contains(kLm05DesfaseInducido) &&
            m.diagnosisIds.contains('induced_bloom_stress_mismanagement'),
      );
      expect(hasDesfase, isTrue);
    });

    test('LM-04 tropical / LM-05 desfase suben el agotamiento de reservas', () {
      final memory = catalog.firstWhere(
        (s) => s.id == 'lemon_postharvest_memory_01',
      );
      final hasTropicalOrDesfase = memory.varietyModifiers.any(
        (m) =>
            m.varietyIds.contains(kLm04TropicalContinuo) ||
            m.varietyIds.contains(kLm05DesfaseInducido),
      );
      expect(hasTropicalOrDesfase, isTrue);
    });
  });
}
