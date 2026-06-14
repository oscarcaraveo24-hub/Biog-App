// test/core/apple_tree/apple_tree_yield_test.dart
//
// Rendimiento aproximado del manzano (doc 03): bloqueo no productivo, t/ha por
// densidad, topes, memoria de estrés, confianza y conversiones.

import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_yield_reference.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bloqueo de rendimiento (no productivo)', () {
    test('newly_planted + Golden + 1111 árboles/ha → 0', () {
      final p = resolveAppleTreeYield(
        profileId: kAp01Golden,
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.rootEstablishment,
        treesPerHa: 1111,
      );
      expect(p.isProductive, isFalse);
      expect(p.kgPerTree!.expected, 0);
    });

    test('juvenile_non_productive + Gala → 0', () {
      final p = resolveAppleTreeYield(
        profileId: kAp04Gala,
        perennialStateId: TreeStateIds.juvenileNonProductive,
        phenologyStageId: TreeStageIds.juvenileVegetative,
      );
      expect(p.isProductive, isFalse);
      expect(p.kgPerTree!.expected, 0);
    });
  });

  group('Proyección productiva', () {
    test('productive_season + Golden + full_bearing + 1111 → ~61 t/ha', () {
      final p = resolveAppleTreeYield(
        profileId: kAp01Golden,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 1111,
        productionState: AppleProductionState.fullBearing,
      );
      expect(p.isProductive, isTrue);
      // kg/árbol esperado base Golden = 55, sin modificadores.
      expect(p.kgPerTree!.expected, closeTo(55, 0.01));
      expect(p.tonPerHa!.expected, closeTo(61.1, 1.0));
    });

    test('muy alta densidad limita kg/árbol (no infla t/ha)', () {
      final p = resolveAppleTreeYield(
        profileId: kAp04Gala,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 4000,
        productionState: AppleProductionState.fullBearing,
      );
      // Tope de muy alta densidad = 25 kg/árbol.
      expect(p.kgPerTree!.expected, lessThanOrEqualTo(25.0));
      // 25 * 4000 / 1000 = 100, nunca 70*4000/1000 = 280.
      expect(p.tonPerHa!.expected, lessThan(120));
    });

    test('cálculo por número de árboles: total kg = kg/árbol * árboles', () {
      final p = resolveAppleTreeYield(
        profileId: kAp02Red,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treeCount: 100,
        productionState: AppleProductionState.fullBearing,
      );
      // Red full_bearing = 48 kg/árbol esperado.
      expect(p.totalKg!.expected, closeTo(4800, 1.0));
    });

    test('post_harvest NO cierra el cultivo (sigue productivo)', () {
      final p = resolveAppleTreeYield(
        profileId: kAp01Golden,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.postHarvest,
        treesPerHa: 1111,
      );
      expect(p.isProductive, isTrue);
      expect(p.kgPerTree!.expected, greaterThan(0));
    });
  });

  group('AP-SKIP y confianza', () {
    test(
      'AP-SKIP sin densidad → rango por árbol y baja confianza, sin t/ha',
      () {
        final p = resolveAppleTreeYield(
          profileId: kApSkip,
          perennialStateId: TreeStateIds.productiveSeason,
          phenologyStageId: TreeStageIds.fruitFill,
          productionState: AppleProductionState.fullBearing,
        );
        expect(p.kgPerTree, isNotNull);
        expect(p.tonPerHa, isNull);
        expect(p.confidence01, lessThan(0.5));
      },
    );

    test('criolla/rayada tiene menor confianza que Golden', () {
      final golden = resolveAppleTreeYield(
        profileId: kAp01Golden,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 800,
        productionState: AppleProductionState.fullBearing,
      );
      final criolla = resolveAppleTreeYield(
        profileId: kAp03CriollaRayada,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 800,
        productionState: AppleProductionState.fullBearing,
      );
      expect(criolla.confidence01, lessThan(golden.confidence01));
    });
  });

  group('Memoria de estrés', () {
    test('helada severa en floración reduce fuertemente el rendimiento', () {
      const base = AppleTreeStressMemory();
      const severe = AppleTreeStressMemory(
        floweringFrost: AppleStressSeverity.severe,
      );
      final withoutStress = resolveAppleTreeYield(
        profileId: kAp01Golden,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 1111,
        productionState: AppleProductionState.fullBearing,
        stressMemory: base,
      );
      final withStress = resolveAppleTreeYield(
        profileId: kAp01Golden,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 1111,
        productionState: AppleProductionState.fullBearing,
        stressMemory: severe,
      );
      expect(
        withStress.kgPerTree!.expected,
        lessThan(withoutStress.kgPerTree!.expected * 0.5),
      );
    });
  });

  group('Conversiones oficiales', () {
    test('treesPerHaFromSpacing(3, 3) ≈ 1111', () {
      expect(treesPerHaFromSpacing(3, 3), closeTo(1111.1, 0.5));
    });

    test('tonHaFromKgTree y kgTreeFromTonHa son inversas', () {
      final tha = tonHaFromKgTree(55, 1111);
      expect(tha, closeTo(61.1, 0.1));
      expect(kgTreeFromTonHa(tha, 1111), closeTo(55, 0.01));
    });
  });
}
