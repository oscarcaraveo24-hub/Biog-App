// test/core/pear_tree/pear_tree_yield_runtime_test.dart
//
// Rendimiento perenne (doc 03) + comportamiento de runtime: bloqueo no
// productivo, cap por densidad, polinización, fruta visible, confianza por
// perfil, postcosecha no cierra el cultivo y fallback PR-SKIP (no AP-SKIP).

import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_yield_reference.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/yield/tree_yield_reference_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bloqueo de rendimiento en estados no productivos', () {
    test('newly_planted + Bartlett + 1000 árboles/ha → rendimiento 0', () {
      final y = resolvePearTreeYield(
        profileId: kPr01BartlettWilliams,
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.plantingTransplant,
        treesPerHa: 1000,
      );
      expect(y.isProductive, isFalse);
      expect(y.kgPerTree, YieldRange.zero);
    });

    test('juvenile_non_productive + Anjou → rendimiento 0', () {
      final y = resolvePearTreeYield(
        profileId: kPr02Anjou,
        perennialStateId: TreeStateIds.juvenileNonProductive,
        phenologyStageId: TreeStageIds.juvenileVegetative,
      );
      expect(y.isProductive, isFalse);
    });
  });

  group('Proyección productiva', () {
    test('productive_season + Bartlett + 1000 árboles/ha → t/ha razonable', () {
      final y = resolvePearTreeYield(
        profileId: kPr01BartlettWilliams,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 1000,
        productionState: PearProductionState.fullBearing,
      );
      expect(y.isProductive, isTrue);
      expect(y.tonPerHa, isNotNull);
      expect(y.tonPerHa!.expected, greaterThan(40));
      expect(y.tonPerHa!.expected, lessThan(70));
    });

    test('muy alta densidad: el cap de kg/árbol evita t/ha absurdas', () {
      final y = resolvePearTreeYield(
        profileId: kPr01BartlettWilliams,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 3000,
        productionState: PearProductionState.fullBearing,
      );
      // 85 kg/árbol * 3000 = 255 t/ha sería absurdo: el cap (25) lo evita.
      expect(y.kgPerTree!.expected, lessThanOrEqualTo(25.0));
      expect(y.tonPerHa!.expected, lessThan(100));
    });

    test('PR-SKIP sin densidad: da kg/árbol y baja confianza', () {
      final y = resolvePearTreeYield(
        profileId: kPrSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        productionState: PearProductionState.fullBearing,
      );
      expect(y.kgPerTree, isNotNull);
      expect(y.tonPerHa, isNull);
      expect(y.confidence01, lessThan(0.6));
    });
  });

  group('Polinización y fruta visible (propio de la pera)', () {
    test('sin polinizador conocido en floración baja el rendimiento', () {
      double expected(bool? pollinator) => resolvePearTreeYield(
        profileId: kPr01BartlettWilliams,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.flowering,
        treesPerHa: 1000,
        productionState: PearProductionState.fullBearing,
        pollinatorKnown: pollinator,
      ).kgPerTree!.expected;

      expect(expected(false), lessThan(expected(true)));
      expect(expected(null), lessThan(expected(true)));
    });

    test('fruta visible en llenado sube la confianza vs floración', () {
      double conf(String stage) => resolvePearTreeYield(
        profileId: kPr01BartlettWilliams,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: stage,
        treesPerHa: 1000,
        productionState: PearProductionState.fullBearing,
      ).confidence01;

      expect(
        conf(TreeStageIds.fruitFill),
        greaterThan(conf(TreeStageIds.flowering)),
      );
    });

    test('estrés severo en memoria reduce fuertemente el rendimiento', () {
      final base = resolvePearTreeYield(
        profileId: kPr01BartlettWilliams,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 1000,
        productionState: PearProductionState.fullBearing,
      ).kgPerTree!.expected;
      final stressed = resolvePearTreeYield(
        profileId: kPr01BartlettWilliams,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 1000,
        productionState: PearProductionState.fullBearing,
        stressMemory: const PearTreeStressMemory(
          floweringFrost: PearStressSeverity.severe,
        ),
      ).kgPerTree!.expected;
      expect(stressed, lessThan(base * 0.5));
    });
  });

  group('Confianza por perfil y postcosecha', () {
    test('Seckel/Comice (premium) tiene confianza menor que Bartlett', () {
      expect(
        pearYieldReferenceByProfile[kPr04SeckelComice]!.confidenceBase,
        lessThan(
          pearYieldReferenceByProfile[kPr01BartlettWilliams]!.confidenceBase,
        ),
      );
    });

    test('post_harvest NO cierra el cultivo (sigue proyectando)', () {
      final y = resolvePearTreeYield(
        profileId: kPr01BartlettWilliams,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.postHarvest,
        treesPerHa: 1000,
        productionState: PearProductionState.fullBearing,
      );
      expect(y.isProductive, isTrue);
    });
  });

  group('Capa mínima TreeYieldReferenceCatalog (doc 03 §10.4)', () {
    test('la pera usa su propia tabla y NO cae al fallback de manzano', () {
      final ref = TreeYieldReferenceCatalog.referenceFor(
        cropId: kCropPearTree,
        profileId: kPrSkip,
        tier: TreeProductiveTier.full,
      );
      expect(ref, isNotNull);
      expect(ref!.cropId, kCropPearTree);
      expect(ref.profileId, kPrSkip);
    });

    test(
      'un perfil de pera desconocido cae a PR-SKIP de pera, no a AP-SKIP',
      () {
        final ref = TreeYieldReferenceCatalog.referenceFor(
          cropId: kCropPearTree,
          profileId: 'pr_99_inexistente',
          tier: TreeProductiveTier.full,
        );
        expect(ref, isNotNull);
        expect(ref!.cropId, kCropPearTree);
        expect(ref.profileId, kPrSkip);
      },
    );
  });
}
