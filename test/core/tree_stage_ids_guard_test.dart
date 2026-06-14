// test/core/tree_stage_ids_guard_test.dart
//
// Guards de IDs de etapa perenne (#5 y #15):
//   #5  "Fruto madurando" NO crea un ID nuevo (fruit_ripening): se mapea a
//       harvest_maturity.
//   #15 Cosecha en curso = harvest_maturity; cosecha terminada = post_harvest.
//       Son dos IDs distintos; no existe un tercero.
//
// Estos tests congelan el conjunto de IDs para que nadie introduzca alias o
// estados nuevos por error.

import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('#5 — "madurando/ripening" no crea un ID nuevo', () {
    test('fruit_ripening NO es un ID de etapa conocido', () {
      expect(isKnownTreeStageId('fruit_ripening'), isFalse);
      expect(isKnownTreeStageId('ripening'), isFalse);
      expect(isKnownTreeStageId('fruto_madurando'), isFalse);
    });

    test('cualquier alias de madurando se normaliza a unknown, nunca a un ID propio', () {
      for (final alias in <String>[
        'fruit_ripening',
        'ripening',
        'madurando',
        'fruto_madurando',
      ]) {
        expect(
          normalizeTreeStageId(alias),
          TreeStageIds.unknown,
          reason: '$alias no debe crear un ID de etapa nuevo',
        );
      }
    });

    test('la maduración real vive en harvest_maturity', () {
      expect(isKnownTreeStageId(TreeStageIds.harvestMaturity), isTrue);
      expect(TreeStageIds.harvestMaturity, 'harvest_maturity');
      // No existe la constante fruit_ripening en el set de etapas.
      expect(
        _treeStageIdValues,
        isNot(contains('fruit_ripening')),
      );
    });
  });

  group('#15 — cosecha en curso vs terminada', () {
    test('harvest_maturity (en curso) y post_harvest (terminada) son distintos', () {
      expect(TreeStageIds.harvestMaturity, 'harvest_maturity');
      expect(TreeStageIds.postHarvest, 'post_harvest');
      expect(TreeStageIds.harvestMaturity, isNot(TreeStageIds.postHarvest));
    });

    test('ambos son etapas válidas y no hay un tercer ID de cosecha', () {
      expect(isKnownTreeStageId(TreeStageIds.harvestMaturity), isTrue);
      expect(isKnownTreeStageId(TreeStageIds.postHarvest), isTrue);

      final harvestRelated = _treeStageIdValues
          .where((id) => id.contains('harvest'))
          .toSet();
      expect(
        harvestRelated,
        <String>{'harvest_maturity', 'post_harvest'},
        reason: 'Solo deben existir dos IDs relacionados con cosecha',
      );
    });

    test('harvest_maturity NO degrada a un estado terminal (el árbol sigue activo)', () {
      expect(
        safeTreeStageForState(
          perennialStateId: TreeStateIds.productiveSeason,
          phenologyStageId: TreeStageIds.harvestMaturity,
        ),
        TreeStageIds.harvestMaturity,
      );
    });
  });
}

/// Conjunto de todos los IDs de etapa conocidos por la política estado→etapa.
final Set<String> _treeStageIdValues = <String>{
  TreeStageIds.plantingTransplant,
  TreeStageIds.rootEstablishment,
  TreeStageIds.juvenileVegetative,
  TreeStageIds.dormancy,
  TreeStageIds.budbreak,
  TreeStageIds.vegetativeGrowth,
  TreeStageIds.flowering,
  TreeStageIds.fruitSet,
  TreeStageIds.fruitFill,
  TreeStageIds.harvestMaturity,
  TreeStageIds.postHarvest,
  TreeStageIds.unknown,
};
