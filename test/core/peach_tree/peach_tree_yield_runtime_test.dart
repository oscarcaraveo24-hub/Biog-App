// test/core/peach_tree/peach_tree_yield_runtime_test.dart
//
// Rendimiento perenne (doc 03) + runtime: bloqueo no productivo, cap por
// densidad, regla propia del durazno (floración NO infiere plena producción),
// fruta visible, carga/raleo, memoria de estrés, postcosecha no cierra el
// cultivo y fallback DZ-SKIP (NO AP-SKIP de manzano ni PR-SKIP de pera).

import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_yield_reference.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/yield/tree_yield_reference_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bloqueo de rendimiento en estados no productivos', () {
    test('newly_planted + DZ-SKIP + 1000 árboles/ha → rendimiento 0', () {
      final y = resolvePeachTreeYield(
        profileId: kDzSkip,
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.plantingTransplant,
        treesPerHa: 1000,
      );
      expect(y.isProductive, isFalse);
      expect(y.kgPerTree, YieldRange.zero);
    });

    test('juvenile_non_productive + DZ-03 → rendimiento 0', () {
      final y = resolvePeachTreeYield(
        profileId: kDz03AmarilloComercial,
        perennialStateId: TreeStateIds.juvenileNonProductive,
        phenologyStageId: TreeStageIds.juvenileVegetative,
      );
      expect(y.isProductive, isFalse);
    });
  });

  group('Proyección productiva', () {
    test('productive_season + DZ-03 + 600 árboles/ha → t/ha razonable', () {
      final y = resolvePeachTreeYield(
        profileId: kDz03AmarilloComercial,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 600,
        productionState: PeachProductionState.fullBearing,
      );
      expect(y.isProductive, isTrue);
      expect(y.tonPerHa, isNotNull);
      expect(y.tonPerHa!.expected, greaterThan(10));
      expect(y.tonPerHa!.expected, lessThan(45));
    });

    test('muy alta densidad: el cap de kg/árbol evita t/ha absurdas', () {
      final y = resolvePeachTreeYield(
        profileId: kDz03AmarilloComercial,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 3500,
        productionState: PeachProductionState.fullBearing,
      );
      // >3000 árboles/ha → cap 18 kg/árbol (doc 03 §10.6).
      expect(y.kgPerTree!.expected, lessThanOrEqualTo(18.0));
      expect(y.tonPerHa!.expected, lessThan(70));
    });

    test('DZ-SKIP sin densidad: da kg/árbol y baja confianza', () {
      final y = resolvePeachTreeYield(
        profileId: kDzSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        productionState: PeachProductionState.fullBearing,
      );
      expect(y.kgPerTree, isNotNull);
      expect(y.tonPerHa, isNull);
      expect(y.confidence01, lessThan(0.6));
    });
  });

  group('Regla propia del durazno (doc 03 §11)', () {
    test('productive_season + flowering NO infiere plena producción', () {
      final flowering = resolvePeachTreeYield(
        profileId: kDz03AmarilloComercial,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.flowering,
        treesPerHa: 600,
      );
      final fruitFill = resolvePeachTreeYield(
        profileId: kDz03AmarilloComercial,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 600,
      );
      // En floración el estado inferido es unknown (mucha flor ≠ cosecha), así
      // que el esperado debe ser menor que con fruto visible en llenado.
      expect(flowering.productionState, PeachProductionState.unknown);
      expect(fruitFill.productionState, PeachProductionState.fullBearing);
      expect(
        flowering.kgPerTree!.expected,
        lessThan(fruitFill.kgPerTree!.expected),
      );
    });

    test('fruta visible en llenado sube la confianza vs floración', () {
      double conf(String stage) => resolvePeachTreeYield(
        profileId: kDz03AmarilloComercial,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: stage,
        treesPerHa: 600,
        productionState: PeachProductionState.fullBearing,
      ).confidence01;

      expect(
        conf(TreeStageIds.fruitFill),
        greaterThan(conf(TreeStageIds.flowering)),
      );
    });
  });

  group('Carga/raleo y memoria de estrés', () {
    test('helada severa en flor (memoria) reduce fuertemente el rendimiento', () {
      final base = resolvePeachTreeYield(
        profileId: kDz03AmarilloComercial,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 600,
        productionState: PeachProductionState.fullBearing,
      ).kgPerTree!.expected;
      final stressed = resolvePeachTreeYield(
        profileId: kDz03AmarilloComercial,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 600,
        productionState: PeachProductionState.fullBearing,
        stressMemory: const PeachTreeStressMemory(
          floweringFrost: PeachStressSeverity.severe,
        ),
      ).kgPerTree!.expected;
      expect(stressed, lessThan(base * 0.5));
    });

    test('sobrecarga sin raleo: kg biológico se mantiene pero baja calidad comercial', () {
      final y = resolvePeachTreeYield(
        profileId: kDz03AmarilloComercial,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 600,
        productionState: PeachProductionState.fullBearing,
        cropLoadStatus: PeachCropLoadStatus.heavy,
      );
      expect(y.isProductive, isTrue);
      expect(y.commercialQualityFactor, lessThan(1.0));
    });

    test('carga ligera baja el rango esperado', () {
      final light = resolvePeachTreeYield(
        profileId: kDz03AmarilloComercial,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 600,
        productionState: PeachProductionState.fullBearing,
        cropLoadStatus: PeachCropLoadStatus.light,
      ).kgPerTree!.expected;
      final balanced = resolvePeachTreeYield(
        profileId: kDz03AmarilloComercial,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 600,
        productionState: PeachProductionState.fullBearing,
        cropLoadStatus: PeachCropLoadStatus.balanced,
      ).kgPerTree!.expected;
      expect(light, lessThan(balanced));
    });
  });

  group('Confianza por perfil y postcosecha', () {
    test('DZ-03 amarillo comercial tiene más confianza base que DZ-SKIP', () {
      expect(
        peachYieldReferenceByProfile[kDz03AmarilloComercial]!.confidenceBase,
        greaterThan(peachYieldReferenceByProfile[kDzSkip]!.confidenceBase),
      );
    });

    test('DZ-02 temprano/bajo frío no supera a DZ-03 por default', () {
      expect(
        peachYieldReferenceByProfile[kDz02TempranoBajoFrio]!.expectedTonPerHa.expected,
        lessThanOrEqualTo(
          peachYieldReferenceByProfile[kDz03AmarilloComercial]!.expectedTonPerHa.expected,
        ),
      );
    });

    test('post_harvest NO cierra el cultivo (sigue proyectando)', () {
      final y = resolvePeachTreeYield(
        profileId: kDz03AmarilloComercial,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.postHarvest,
        treesPerHa: 600,
        productionState: PeachProductionState.fullBearing,
      );
      expect(y.isProductive, isTrue);
    });
  });

  group('Capa mínima TreeYieldReferenceCatalog (doc 03 §10.4)', () {
    test('el durazno usa su propia tabla y NO cae al fallback de manzano/pera', () {
      final ref = TreeYieldReferenceCatalog.referenceFor(
        cropId: kCropPeachTree,
        profileId: kDzSkip,
        tier: TreeProductiveTier.full,
      );
      expect(ref, isNotNull);
      expect(ref!.cropId, kCropPeachTree);
      expect(ref.profileId, kDzSkip);
    });

    test('un perfil de durazno desconocido cae a DZ-SKIP de durazno', () {
      final ref = TreeYieldReferenceCatalog.referenceFor(
        cropId: kCropPeachTree,
        profileId: 'dz_99_inexistente',
        tier: TreeProductiveTier.full,
      );
      expect(ref, isNotNull);
      expect(ref!.cropId, kCropPeachTree);
      expect(ref.profileId, kDzSkip);
    });
  });

  group('Conversiones de densidad (doc 03 §3, §5)', () {
    test('treesPerHaFromSpacing(5,4)=500, (4,4)=625, (4,3)=833', () {
      expect(treesPerHaFromSpacing(5, 4).round(), 500);
      expect(treesPerHaFromSpacing(4, 4).round(), 625);
      expect(treesPerHaFromSpacing(4, 3).round(), 833);
    });

    test('40 kg/árbol * 500 árboles/ha = 20 t/ha y vuelta', () {
      expect(tonHaFromKgTree(40, 500), 20);
      expect(kgTreeFromTonHa(20, 500), 40);
    });
  });
}
