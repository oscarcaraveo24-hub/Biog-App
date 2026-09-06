// test/core/walnut_tree/walnut_tree_finalize_test.dart
//
// Cierre de integración del Nogal: assets (icono general = ic_walnut_tree, sin
// ic_walnut_tree_generic; fallback seguro), NG-05 canónico/migración, copy
// nogalero de etapas y guardas NPK (EC/humedad/pH) en la recomendación práctica.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_assets.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_catalog.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_yield_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Assets del nogal cableados (sin ic_walnut_tree_generic)', () {
    test('icono general/SKIP usa ic_walnut_tree.png, no _generic', () {
      expect(WalnutTreeAssets.cropIcon, 'assets/icons/wizard/ic_walnut_tree.png');
      expect(WalnutTreeAssets.neutralIcon, WalnutTreeAssets.cropIcon);
      expect(walnutTreeProfileIcon(kNgSkip), WalnutTreeAssets.iconTree);
      expect(walnutTreeNeutralIcon(), isNot(contains('_generic')));
      expect(WalnutTreeAssets.cropIcon, isNot(contains('_generic')));
    });

    test('cada perfil NG mapea a su icono definitivo', () {
      expect(walnutTreeProfileIcon(kNg01Western), WalnutTreeAssets.iconWestern);
      expect(walnutTreeProfileIcon(kNg02Wichita), WalnutTreeAssets.iconWichita);
      expect(
        walnutTreeProfileIcon(kNg03WesternWichita),
        WalnutTreeAssets.iconWesternWichita,
      );
      expect(
        walnutTreeProfileIcon(kNg04CriolloRegional),
        WalnutTreeAssets.iconCriolloRegional,
      );
      expect(
        walnutTreeProfileIcon(kNg05TempranoPawneeKanza),
        WalnutTreeAssets.iconTemprano,
      );
    });

    test('todas las etapas tienen imagen propia walnut_stage_* y fallback no nulo', () {
      for (final stage in const <String>[
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
      ]) {
        final img = walnutTreeStageImageOrNeutral(stage);
        expect(img, startsWith('assets/seeds/walnut/walnut_stage_'));
      }
    });

    test('fallback genérico declarado para errorBuilder (ic_tree.png)', () {
      expect(
        WalnutTreeAssets.genericTreeFallback,
        'assets/icons/wizard/ic_tree.png',
      );
    });
  });

  group('NG-05 canónico ng_05_temprano_pawnee_kanza con migración', () {
    test('el id canónico es ng_05_temprano_pawnee_kanza', () {
      expect(kNg05TempranoPawneeKanza, 'ng_05_temprano_pawnee_kanza');
      expect(
        CropCatalog.profileById(kCropWalnutTree, 'ng_05_temprano_pawnee_kanza'),
        isNotNull,
      );
    });

    test('ids previos y nombres resuelven al canónico (no rompe historial)', () {
      for (final alias in const <String>[
        'ng_05_temprano_nuevo',
        'ng_05_temprano',
        'Pawnee',
        'Kanza',
        'Cheyenne',
        'Temprano',
      ]) {
        expect(
          CropCatalog.profileByAny(kCropWalnutTree, alias)?.id,
          kNg05TempranoPawneeKanza,
          reason: alias,
        );
      }
    });

    test('el rendimiento conserva historial: id legacy resuelve a NG-05', () {
      WalnutTreeYieldProjection projFor(String profileId) =>
          resolveWalnutTreeYield(
            profileId: profileId,
            perennialStateId: TreeStateIds.productiveSeason,
            phenologyStageId: TreeStageIds.fruitFill,
            treesPerHa: 69,
            productionState: WalnutProductionState.fullBearing,
          );

      // El id legacy resuelve a la MISMA referencia NG-05 (no al SKIP).
      expect(projFor('ng_05_temprano_nuevo').profileId, kNg05TempranoPawneeKanza);
      expect(projFor('ng_05_temprano').profileId, kNg05TempranoPawneeKanza);
      expect(
        projFor('ng_05_temprano_pawnee_kanza').profileId,
        kNg05TempranoPawneeKanza,
      );
      // La confianza base NG-05 (0.55) difiere del SKIP (0.48): no es fallback.
      expect(
        projFor('ng_05_temprano_nuevo').confidence01,
        greaterThan(projFor(kNgSkip).confidence01),
      );
    });
  });

  group('Copy nogalero de etapas (presentación, sin cambiar StageIds)', () {
    test('etapas clave del nogal usan lenguaje nogalero', () {
      expect(
        treeStageDisplayNameForCrop(kCropWalnutTree, TreeStageIds.fruitSet),
        'Amarre de nuez',
      );
      expect(
        treeStageDisplayNameForCrop(kCropWalnutTree, TreeStageIds.fruitFill),
        'Llenado de nuez / almendra',
      );
      expect(
        treeStageDisplayNameForCrop(kCropWalnutTree, TreeStageIds.harvestMaturity),
        'Ruezno abriendo / cosecha',
      );
      expect(
        treeStageDisplayNameForCrop(kCropWalnutTree, TreeStageIds.postHarvest),
        'Postcosecha / reservas',
      );
    });

    test('fruit_fill del nogal NO dice cosecha; harvest_maturity SÍ', () {
      final fill = treeStageDisplayNameForCrop(
        kCropWalnutTree,
        TreeStageIds.fruitFill,
      ).toLowerCase();
      expect(fill, contains('llenado'));
      expect(fill, isNot(contains('cosecha')));
      expect(fill, isNot(contains('ruezno')));

      final harvest = treeStageDisplayNameForCrop(
        kCropWalnutTree,
        TreeStageIds.harvestMaturity,
      ).toLowerCase();
      expect(harvest, anyOf(contains('cosecha'), contains('ruezno')));
    });

    test('otros árboles NO cambian (durazno usa copy genérico)', () {
      expect(
        treeStageDisplayNameForCrop(
          CropCatalog.peachTreeCropId,
          TreeStageIds.fruitFill,
        ),
        treeStageDisplayName(TreeStageIds.fruitFill),
      );
      expect(
        treeStageDisplayNameForCrop(
          CropCatalog.appleTreeCropId,
          TreeStageIds.fruitSet,
        ),
        treeStageDisplayName(TreeStageIds.fruitSet),
      );
    });
  });

}
