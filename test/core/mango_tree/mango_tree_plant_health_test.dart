// test/core/mango_tree/mango_tree_plant_health_test.dart
//
// Sanidad/Plant Health del Mango por etapa fenologica (doc 04). Catalogo propio
// de arbol tropical con memoria fuerte: induccion/no-floracion, cenicilla/
// antracnosis de panicula, cuajado/caida de manguito, raiz/salinidad, mosca de
// la fruta (regulada), chupadores/fumagina, trips/acaros, malformacion/dieback,
// calidad de fruto, poscosecha/stem-end rot, clima/fitotoxicidad y memoria/
// alternancia. NO reusa el catalogo de citricos (el mango NO es limon/naranjo);
// usa IDs genericos de PlantHealthIds. dormancy/harvest/post_harvest NO se
// apagan. BIO-G orienta, NO cierra antracnosis/cenicilla/mosca/malformacion.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final List<PlantHealthSyndrome> catalog = PlantHealthRegistry.catalogForCrop(
    CropCatalog.mangoTreeCropId,
  );

  PlantHealthStageBucket? bucket(String stage) =>
      PlantHealthStageAdapter.fromCropStage(
        cropId: 'mango_tree',
        stageKey: stage,
        daySinceSowing: null,
      );

  Set<String> activeAt(String stage) {
    final b = bucket(stage);
    if (b == null) return <String>{};
    return catalog.where((s) => s.stages.contains(b)).map((s) => s.id).toSet();
  }

  group('Registro de sindromes del mango', () {
    test('crop_mango_tree tiene catalogo y soporta alias humano', () {
      expect(catalog, isNotEmpty);
      expect(catalog.length, 12);
      expect(PlantHealthRegistry.isSupportedCrop('mango_tree'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('mango'), isTrue);
      expect(PlantHealthRegistry.isSupportedCrop('mangifera'), isTrue);
    });

    test('todos orientan (no recetan) y son del mango', () {
      for (final s in catalog) {
        expect(s.cropId, CropCatalog.mangoTreeCropId);
        expect(s.disclaimerEs, isNotEmpty);
      }
    });

    test('catalogo propio: induccion, cenicilla/antracnosis, mosca fruta, memoria',
        () {
      final allText = catalog
          .map((s) => s.probableDiagnoses.map((d) => d.id).join(' '))
          .join(' ')
          .toLowerCase();
      // No reusa identidades citricas (HLB/gomosis son del limon/naranjo).
      expect(allText, isNot(contains('huanglongbing_hlb_context')));
      expect(allText, isNot(contains('phytophthora_gummosis_foot_rot')));
      // Identidades propias del mango.
      expect(allText, contains('poor_flower_induction_context'));
      expect(allText, contains('mango_powdery_mildew_panicle'));
      expect(allText, contains('mango_anthracnose_panicle_blossom'));
      expect(allText, contains('anastrepha_fruit_fly_context'));
      expect(allText, contains('mango_malformation_floral_vegetative'));
      expect(allText, contains('stem_end_rot_context'));
      expect(allText, contains('alternate_bearing_memory'));
    });

    test('mosca de la fruta: critica/regulada, no diagnostico cerrado', () {
      final fly = catalog.firstWhere(
        (s) => s.id == 'mango_fruit_fly_quarantine_01',
      );
      expect(fly.severity, PlantHealthSeverity.critical);
      expect(fly.favorsVectorPressure, isTrue);
      expect(fly.disclaimerEs.toLowerCase(), contains('confirm'));
    });

    test('la NO floracion es un estado valido (no falla del motor)', () {
      final induction = catalog.firstWhere(
        (s) => s.id == 'mango_induction_no_flowering_01',
      );
      final text = induction.probableDiagnoses
          .map((d) => d.summaryEs)
          .join(' ')
          .toLowerCase();
      expect(text, contains('estado válido'));
    });
  });

  group('Adaptacion por etapa fenologica del mango (doc 04 §2.3)', () {
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

    test('dormancy NO queda apagada (reposo funcional / induccion)', () {
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

    test('en floracion aparecen cenicilla/antracnosis y cuajado', () {
      final active = activeAt(TreeStageIds.flowering);
      expect(active, contains('mango_powdery_anthracnose_panicle_01'));
      expect(active, contains('mango_fruit_set_drop_01'));
    });

    test('en cosecha/poscosecha aparece la mosca de la fruta', () {
      expect(activeAt(TreeStageIds.harvestMaturity),
          contains('mango_fruit_fly_quarantine_01'));
    });

    test('unknown es conservador (bucket null, sin sindromes de etapa)', () {
      expect(bucket(TreeStageIds.unknown), isNull);
      expect(activeAt(TreeStageIds.unknown), isEmpty);
    });
  });

  group('Perfiles MG ajustan sensibilidad (varietyModifiers, doc 04 §8)', () {
    test('Ataulfo sube la antracnosis en panicula', () {
      final panicle = catalog.firstWhere(
        (s) => s.id == 'mango_powdery_anthracnose_panicle_01',
      );
      final ataulfo = panicle.varietyModifiers.where(
        (m) =>
            m.varietyIds.contains(kMg01AtaulfoManila) &&
            m.diagnosisIds.contains('mango_anthracnose_panicle_blossom'),
      );
      expect(ataulfo, isNotEmpty);
      expect(ataulfo.first.scoreDelta, greaterThan(0));
    });

    test('Keitt (muy tardio) sube la mosca de la fruta', () {
      final fly = catalog.firstWhere(
        (s) => s.id == 'mango_fruit_fly_quarantine_01',
      );
      final keitt = fly.varietyModifiers.where(
        (m) => m.varietyIds.contains(kMg04Keitt),
      );
      expect(keitt, isNotEmpty);
      expect(keitt.first.scoreDelta, greaterThan(0));
    });
  });
}
