// test/core/walnut_tree/walnut_tree_finalize_test.dart
//
// Cierre de integración del Nogal: assets (icono general = ic_walnut_tree, sin
// ic_walnut_tree_generic; fallback seguro), NG-05 canónico/migración, copy
// nogalero de etapas y guardas NPK (EC/humedad/pH) en la recomendación práctica.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_assets.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_catalog.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_universal_profile.dart';
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

  group('Guardas NPK del nogal (EC/humedad/pH mandan antes que NPK)', () {
    NutrientInterpretationResult interpretK({
      required double ec,
      required double soilMoisturePct,
      required double ph,
      String stage = TreeStageIds.fruitFill,
    }) {
      return NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.k,
        rawPpm: 20, // K bajo
        cropKey: 'walnut_tree',
        stageKey: stage,
        profileId: kNg01Western,
        targets: resolveWalnutTreeTargets(stage),
        weights: resolveWalnutTreeStageWeights(stage),
        ph: ph,
        ec: ec,
        soilMoisturePct: soilMoisturePct,
      );
    }

    test('EC alta en llenado: la guarda de sales encabeza la recomendación', () {
      final r = interpretK(ec: 3.0, soilMoisturePct: 70, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      // La guarda manda: habla de salinidad/sales y de no fertilizar fuerte.
      expect(msg, anyOf(contains('salinidad'), contains('sales')));
      expect(
        msg,
        anyOf(contains('lavado'), contains('lixiviación'), contains('drenaje')),
      );
    });

    test('humedad crítica baja: agua primero (raíz estresada)', () {
      final r = interpretK(ec: 0.5, soilMoisturePct: 35, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(msg, contains('humedad'));
      expect(msg, anyOf(contains('llenado de almendra'), contains('estabiliza')));
    });

    test('humedad saturada: oxígeno/raíz/drenaje, no más fertilizante', () {
      final r = interpretK(ec: 0.5, soilMoisturePct: 95, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(msg, anyOf(contains('saturado'), contains('oxígeno'), contains('drenaje')));
    });

    test('pH alto: advierte disponibilidad de zinc/hierro/fósforo, no N', () {
      final r = interpretK(ec: 0.5, soilMoisturePct: 70, ph: 7.9);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(msg, anyOf(contains('zinc'), contains('disponibilidad')));
    });

    test('suelo OK: NO se dispara guarda; habla de potasio/llenado', () {
      final r = interpretK(ec: 0.5, soilMoisturePct: 72, ph: 6.8);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(msg, contains('potasio'));
      expect(msg, isNot(contains('saturado')));
    });
  });
}
