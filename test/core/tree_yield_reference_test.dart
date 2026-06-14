// test/core/tree_yield_reference_test.dart
//
// Decisión #11: rendimiento de árbol sin historial = tabla kg/árbol por tier
// productivo × número de árboles, con confianza baja (modeled) y conservadora.
// No agrega columnas a Supabase ni inventa IDs de lifecycle.

import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/yield/tree_yield_reference_catalog.dart';
import 'package:bio_g/core/yield/yield_reference_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catálogo base de manzano', () {
    test('cubre los tres tiers productivos y todos son modeled', () {
      final tiers = TreeYieldReferenceCatalog.byId.values
          .where((ref) => ref.cropId == kCropAppleTree)
          .map((ref) => ref.tier)
          .toSet();

      expect(tiers, <TreeProductiveTier>{
        TreeProductiveTier.young,
        TreeProductiveTier.firstProduction,
        TreeProductiveTier.full,
      });

      for (final ref in TreeYieldReferenceCatalog.byId.values) {
        expect(
          ref.confidence,
          YieldDataConfidence.modeled,
          reason: 'sin historial la confianza es baja',
        );
        expect(ref.sourceMethod, isNotEmpty);
        expect(ref.kgPerTreeLow, lessThanOrEqualTo(ref.kgPerTreeHigh));
      }
    });

    test('el rendimiento crece de joven a plena producción', () {
      final young = TreeYieldReferenceCatalog.referenceFor(
        cropId: kCropAppleTree,
        tier: TreeProductiveTier.young,
      )!;
      final full = TreeYieldReferenceCatalog.referenceFor(
        cropId: kCropAppleTree,
        tier: TreeProductiveTier.full,
      )!;

      expect(full.kgPerTreeHigh, greaterThan(young.kgPerTreeHigh));
    });
  });

  group('referenceFor: perfil cae al general (AP-SKIP)', () {
    test('un perfil sin tabla propia usa la base conservadora AP-SKIP', () {
      final ref = TreeYieldReferenceCatalog.referenceFor(
        cropId: kCropAppleTree,
        profileId: kAp01Golden,
        tier: TreeProductiveTier.full,
      );

      expect(ref, isNotNull);
      expect(ref!.profileId, kApSkip);
    });

    test('cultivo sin tabla de árbol devuelve null', () {
      final ref = TreeYieldReferenceCatalog.referenceFor(
        cropId: 'maize',
        tier: TreeProductiveTier.full,
      );
      expect(ref, isNull);
    });
  });

  group('tierForPerennialState', () {
    test('estados no productivos → null (SKIP conservador)', () {
      expect(
        TreeYieldReferenceCatalog.tierForPerennialState(
          TreeStateIds.newlyPlanted,
        ),
        isNull,
      );
      expect(
        TreeYieldReferenceCatalog.tierForPerennialState(
          TreeStateIds.juvenileNonProductive,
        ),
        isNull,
      );
      expect(
        TreeYieldReferenceCatalog.tierForPerennialState(TreeStateIds.unknown),
        isNull,
      );
    });

    test('established → primera producción, productive_season → plena', () {
      expect(
        TreeYieldReferenceCatalog.tierForPerennialState(
          TreeStateIds.established,
        ),
        TreeProductiveTier.firstProduction,
      );
      expect(
        TreeYieldReferenceCatalog.tierForPerennialState(
          TreeStateIds.productiveSeason,
        ),
        TreeProductiveTier.full,
      );
    });
  });

  group('estimateTotalKg', () {
    test('multiplica kg/árbol por número de árboles', () {
      final ref = TreeYieldReferenceCatalog.referenceFor(
        cropId: kCropAppleTree,
        tier: TreeProductiveTier.full,
      )!;

      final estimate = TreeYieldReferenceCatalog.estimateTotalKg(
        cropId: kCropAppleTree,
        tier: TreeProductiveTier.full,
        treeCount: 10,
      )!;

      expect(estimate.kgLow, ref.kgPerTreeLow * 10);
      expect(estimate.kgHigh, ref.kgPerTreeHigh * 10);
      expect(estimate.treeCount, 10);
      expect(estimate.confidence, YieldDataConfidence.modeled);
    });

    test('número de árboles no positivo → null', () {
      expect(
        TreeYieldReferenceCatalog.estimateTotalKg(
          cropId: kCropAppleTree,
          tier: TreeProductiveTier.full,
          treeCount: 0,
        ),
        isNull,
      );
    });
  });
}
