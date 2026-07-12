// test/core/avocado_tree/avocado_tree_plant_health_test.dart
//
// Sanidad/Plant Health del Aguacate por etapa fenologica (doc 04). Catalogo
// propio de arbol subtropical con raiz muy sensible y memoria fuerte: raiz/
// drenaje/Phytophthora/salinidad, floracion A/B y bajo cuajado, caida de
// frutito, trips/acaros/lace bug, chupadores/fumagina, barrenadores regulados,
// antracnosis/stem-end rot/roña, cancro, sunblotch, golpe de sol, frio,
// fitotoxicidad y memoria/alternancia. NO reusa el catalogo de mango/citricos;
// usa IDs genericos de PlantHealthIds. dormancy/harvest/post_harvest NO se
// apagan. BIO-G orienta, NO cierra Phytophthora/plagas reguladas.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<PlantHealthSyndrome> catalog = PlantHealthRegistry.catalogForCrop(
    CropCatalog.avocadoTreeCropId,
  );

  PlantHealthStageBucket? bucket(String stage) =>
      PlantHealthStageAdapter.fromCropStage(
        cropId: 'avocado_tree',
        stageKey: stage,
        daySinceSowing: null,
      );

  Set<String> activeAt(String stage) {
    final b = bucket(stage);
    if (b == null) return <String>{};
    return catalog.where((s) => s.stages.contains(b)).map((s) => s.id).toSet();
  }

  group('Registro de sindromes del aguacate', () {
    test('crop_avocado_tree tiene catalogo y soporta alias humano', () {
      expect(catalog, isNotEmpty);
      expect(catalog.length, 18);
      expect(PlantHealthRegistry.isSupportedCrop('avocado_tree'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('aguacate'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('palta'), isTrue);
    });

    test('todos orientan (no recetan) y son del aguacate', () {
      for (final s in catalog) {
        expect(s.cropId, CropCatalog.avocadoTreeCropId);
        expect(s.disclaimerEs, isNotEmpty);
      }
    });

    test('catalogo propio: Phytophthora, salinidad, cuajado A/B, sunblotch, memoria',
        () {
      final allText = catalog
          .map((s) => s.probableDiagnoses.map((d) => d.id).join(' '))
          .join(' ')
          .toLowerCase();
      // No reusa identidades de mango ni citricos.
      expect(allText, isNot(contains('anastrepha_fruit_fly_context')));
      expect(allText, isNot(contains('mango_powdery_mildew_panicle')));
      expect(allText, isNot(contains('huanglongbing_hlb_context')));
      // Identidades propias del aguacate.
      expect(allText, contains('avocado_phytophthora_cinnamomi_context'));
      expect(allText, contains('avocado_chloride_sodium_tip_burn_context'));
      expect(allText, contains('avocado_low_fruit_set_pollination_context'));
      expect(allText, contains('avocado_flower_type_overlap_context'));
      expect(allText, contains('avocado_seed_borer_regulated_context'));
      expect(allText, contains('avocado_sunblotch_viroid_context'));
      expect(allText, contains('avocado_alternate_bearing_memory'));
    });

    test('raiz/Phytophthora: critica, orienta (no diagnostica por sensor)', () {
      final root = catalog.firstWhere(
        (s) => s.id == 'avocado_phytophthora_root_rot_syndrome',
      );
      expect(root.severity, PlantHealthSeverity.critical);
      expect(root.disclaimerEs.toLowerCase(), contains('confirm'));
    });

    test('barrenadores regulados: critica/inmediata, cautela oficial', () {
      final borer = catalog.firstWhere(
        (s) => s.id == 'avocado_regulated_borers_syndrome',
      );
      expect(borer.severity, PlantHealthSeverity.critical);
      expect(borer.urgency, PlantHealthUrgency.immediate);
      expect(borer.favorsVectorPressure, isTrue);
    });
  });

  group('Adaptacion por etapa fenologica del aguacate (doc 04 §2.5)', () {
    test('mapeo de StageIds a buckets del motor de sanidad', () {
      expect(bucket(TreeStageIds.plantingTransplant),
          PlantHealthStageBucket.seedling);
      expect(bucket(TreeStageIds.budbreak),
          PlantHealthStageBucket.vegetativeEarly);
      expect(bucket(TreeStageIds.vegetativeGrowth),
          PlantHealthStageBucket.vegetativeMid);
      expect(bucket(TreeStageIds.flowering),
          PlantHealthStageBucket.reproductiveEarly);
      expect(bucket(TreeStageIds.fruitSet),
          PlantHealthStageBucket.reproductiveMid);
      expect(bucket(TreeStageIds.fruitFill),
          PlantHealthStageBucket.grainFill);
    });

    test('dormancy NO queda apagada (reposo funcional, siempreverde)', () {
      expect(bucket(TreeStageIds.dormancy), PlantHealthStageBucket.lateSeason);
      expect(activeAt(TreeStageIds.dormancy), isNotEmpty);
    });

    test('post_harvest se evalua antes que harvest y NO queda apagada', () {
      expect(bucket(TreeStageIds.postHarvest),
          PlantHealthStageBucket.lateSeason);
      expect(activeAt(TreeStageIds.postHarvest), isNotEmpty);
    });

    test('harvest_maturity va a lateSeason (sanidad de cosecha/poscosecha)', () {
      expect(bucket(TreeStageIds.harvestMaturity),
          PlantHealthStageBucket.lateSeason);
    });

    test('en floracion aparece el bajo cuajado y la raiz/salinidad', () {
      final active = activeAt(TreeStageIds.flowering);
      expect(active, contains('avocado_flower_set_failure_syndrome'));
      expect(active, contains('avocado_phytophthora_root_rot_syndrome'));
    });

    test('en cosecha/poscosecha aparecen barrenadores y stem-end rot', () {
      final active = activeAt(TreeStageIds.harvestMaturity);
      expect(active, contains('avocado_regulated_borers_syndrome'));
      expect(active, contains('avocado_stem_end_rot_syndrome'));
    });

    test('unknown es conservador (bucket null, sin sindromes de etapa)', () {
      expect(bucket(TreeStageIds.unknown), isNull);
      expect(activeAt(TreeStageIds.unknown), isEmpty);
    });
  });

  group('Perfiles AG ajustan sensibilidad (varietyModifiers, doc 04 §6.2)', () {
    test('Hass sube el contexto de polinizacion A/B en bajo cuajado', () {
      final bloom = catalog.firstWhere(
        (s) => s.id == 'avocado_flower_set_failure_syndrome',
      );
      final hass = bloom.varietyModifiers.where(
        (m) =>
            m.varietyIds.contains(kAg01Hass) &&
            m.diagnosisIds.contains('avocado_flower_type_overlap_context'),
      );
      expect(hass, isNotEmpty);
      expect(hass.first.scoreDelta, greaterThan(0));
    });

    test('Fuerte (tipo B) sube el contexto de traslape floral', () {
      final bloom = catalog.firstWhere(
        (s) => s.id == 'avocado_flower_set_failure_syndrome',
      );
      final fuerte = bloom.varietyModifiers.where(
        (m) => m.varietyIds.contains(kAg04FuertePielVerde),
      );
      expect(fuerte, isNotEmpty);
      expect(fuerte.first.scoreDelta, greaterThan(0));
    });

    test('Antillano/tropical sube antracnosis y exceso de humedad/raiz', () {
      final anth = catalog.firstWhere(
        (s) => s.id == 'avocado_anthracnose_fruit_syndrome',
      );
      final antillano = anth.varietyModifiers.where(
        (m) => m.varietyIds.contains(kAg05AntillanoTropical),
      );
      expect(antillano, isNotEmpty);
      expect(antillano.first.scoreDelta, greaterThan(0));
    });
  });
}
