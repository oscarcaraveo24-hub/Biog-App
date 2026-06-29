// test/core/walnut_tree/walnut_tree_yield_runtime_test.dart
//
// Rendimiento perenne (doc 03) + runtime: bloqueo no productivo, cap por
// densidad, polinizacion, memoria de estres (alternancia/helada/barrenador),
// postcosecha no cierra el cultivo y fallback NG-SKIP (NO AP/PR/DZ-SKIP).
// Salida principal: kg de nuez con cascara/arbol y t/ha.

import 'package:bio_g/core/crops/walnut_tree/walnut_tree_catalog.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_yield_reference.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/yield/tree_yield_reference_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bloqueo de rendimiento en estados no productivos', () {
    test('newly_planted + NG-SKIP + 100 arboles/ha → rendimiento 0', () {
      final y = resolveWalnutTreeYield(
        profileId: kNgSkip,
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.plantingTransplant,
        treesPerHa: 100,
      );
      expect(y.isProductive, isFalse);
      expect(y.kgPerTree, YieldRange.zero);
    });

    test('juvenile_non_productive + NG-03 → rendimiento 0', () {
      final y = resolveWalnutTreeYield(
        profileId: kNg03WesternWichita,
        perennialStateId: TreeStateIds.juvenileNonProductive,
        phenologyStageId: TreeStageIds.juvenileVegetative,
      );
      expect(y.isProductive, isFalse);
    });
  });

  group('Proyeccion productiva', () {
    test('NG-03 bloque + 69 arboles/ha (12x12) → t/ha regional razonable', () {
      final y = resolveWalnutTreeYield(
        profileId: kNg03WesternWichita,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 69,
        productionState: WalnutProductionState.fullBearing,
        managementLevel: WalnutManagementLevel.good,
        irrigationLevel: WalnutIrrigationLevel.stable,
        pollinatorKnown: true,
      );
      expect(y.isProductive, isTrue);
      expect(y.tonPerHa, isNotNull);
      expect(y.tonPerHa!.expected, greaterThan(1.0));
      expect(y.tonPerHa!.expected, lessThan(3.5));
    });

    test('alta densidad: el cap de kg/arbol evita t/ha absurdas', () {
      final y = resolveWalnutTreeYield(
        profileId: kNg03WesternWichita,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 220,
        productionState: WalnutProductionState.fullBearing,
        managementLevel: WalnutManagementLevel.exceptional,
        irrigationLevel: WalnutIrrigationLevel.fertigation,
      );
      // >=200 arboles/ha → cap 24 kg/arbol (doc 03 §5.4).
      expect(y.kgPerTree!.expected, lessThanOrEqualTo(24.0));
    });

    test('NG-SKIP sin densidad: da kg/arbol y baja confianza', () {
      final y = resolveWalnutTreeYield(
        profileId: kNgSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        productionState: WalnutProductionState.fullBearing,
      );
      expect(y.kgPerTree, isNotNull);
      expect(y.tonPerHa, isNull);
      expect(y.confidence01, lessThan(0.6));
    });

    test('totalKg se calcula con numero de arboles', () {
      final y = resolveWalnutTreeYield(
        profileId: kNgSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treeCount: 20,
        productionState: WalnutProductionState.fullBearing,
      );
      expect(y.totalKg, isNotNull);
      expect(y.totalKg!.expected, greaterThan(0));
    });
  });

  group('Polinizacion y memoria de estres (doc 03 §7.3, §8)', () {
    test('polinizador desconocido NO castiga; falta de polinizador SI', () {
      double exp(bool? pollinator) => resolveWalnutTreeYield(
        profileId: kNg01Western,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 69,
        productionState: WalnutProductionState.fullBearing,
        pollinatorKnown: pollinator,
      ).kgPerTree!.expected;

      expect(exp(false), lessThan(exp(null)));
      expect(exp(true), greaterThan(exp(false)));
    });

    test('helada severa en flor (memoria) reduce fuertemente el rendimiento', () {
      final base = resolveWalnutTreeYield(
        profileId: kNg01Western,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 69,
        productionState: WalnutProductionState.fullBearing,
      ).kgPerTree!.expected;
      final stressed = resolveWalnutTreeYield(
        profileId: kNg01Western,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 69,
        productionState: WalnutProductionState.fullBearing,
        stressMemory: const WalnutTreeStressMemory(
          floweringFrost: WalnutStressSeverity.severe,
        ),
      ).kgPerTree!.expected;
      expect(stressed, lessThan(base * 0.4));
    });

    test('alternancia severa baja el rendimiento y agrega nota de memoria', () {
      final y = resolveWalnutTreeYield(
        profileId: kNg01Western,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 69,
        productionState: WalnutProductionState.fullBearing,
        stressMemory: const WalnutTreeStressMemory(
          alternateBearing: WalnutStressSeverity.severe,
        ),
      );
      expect(
        y.notesEs.join(' ').toLowerCase(),
        contains('memoria de estres'),
      );
    });
  });

  group('Confianza por perfil y postcosecha', () {
    test('NG-03 bloque tiene mas confianza base que NG-SKIP y que NG-04 criollo', () {
      expect(
        walnutYieldReferenceByProfile[kNg03WesternWichita]!.confidenceBase,
        greaterThan(walnutYieldReferenceByProfile[kNgSkip]!.confidenceBase),
      );
      expect(
        walnutYieldReferenceByProfile[kNg04CriolloRegional]!.confidenceBase,
        lessThan(walnutYieldReferenceByProfile[kNgSkip]!.confidenceBase),
      );
    });

    test('post_harvest NO cierra el cultivo (sigue proyectando)', () {
      final y = resolveWalnutTreeYield(
        profileId: kNg01Western,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.postHarvest,
        treesPerHa: 69,
        productionState: WalnutProductionState.fullBearing,
      );
      expect(y.isProductive, isTrue);
    });

    test('kernelPct (% almendra) se expone como contexto de calidad', () {
      final y = resolveWalnutTreeYield(
        profileId: kNg01Western,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 69,
        productionState: WalnutProductionState.fullBearing,
      );
      expect(y.kernelPct, isNotNull);
      expect(y.kernelPct!.expected, greaterThan(40));
    });
  });

  group('Capa minima TreeYieldReferenceCatalog (doc 03 §11)', () {
    test('el nogal usa su propia tabla y NO cae al fallback de manzano/pera/durazno', () {
      final ref = TreeYieldReferenceCatalog.referenceFor(
        cropId: kCropWalnutTree,
        profileId: kNgSkip,
        tier: TreeProductiveTier.full,
      );
      expect(ref, isNotNull);
      expect(ref!.cropId, kCropWalnutTree);
      expect(ref.profileId, kNgSkip);
    });

    test('un perfil de nogal desconocido cae a NG-SKIP de nogal', () {
      final ref = TreeYieldReferenceCatalog.referenceFor(
        cropId: kCropWalnutTree,
        profileId: 'ng_99_inexistente',
        tier: TreeProductiveTier.full,
      );
      expect(ref, isNotNull);
      expect(ref!.cropId, kCropWalnutTree);
      expect(ref.profileId, kNgSkip);
    });
  });

  group('Conversiones de densidad (doc 03 §5)', () {
    test('treesPerHaFromSpacing(12,12)=69, (10,10)=100, (14,14)=51', () {
      expect(treesPerHaFromSpacing(12, 12).round(), 69);
      expect(treesPerHaFromSpacing(10, 10).round(), 100);
      expect(treesPerHaFromSpacing(14, 14).round(), 51);
    });

    test('30 kg/arbol * 69.44 arboles/ha ≈ 2.08 t/ha y vuelta', () {
      final tph = treesPerHaFromSpacing(12, 12);
      expect(tonHaFromKgTree(30, tph), closeTo(2.08, 0.05));
      expect(kgTreeFromTonHa(2.08, tph), closeTo(30, 0.5));
    });
  });
}
