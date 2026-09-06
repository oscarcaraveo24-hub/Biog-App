// test/core/orange_tree/orange_tree_finalize_test.dart
//
// Cierre de integracion del Naranjo: assets reales (dormancy usa reposo
// relativo verde, NO arbol pelon, por ser citrico siempreverde), copy citrico
// de etapas (fruit_fill != harvest; dormancy = reposo relativo), K protagonista
// en fruit_fill, prioridades por etapa y migracion de OR.
//
// Las pruebas de topes ppm y de interpretacion NPK por lectura se retiraron
// con el reset del motor nutricional (Guia v0.4).

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_assets.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_catalog.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_universal_profile.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_yield_reference.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Assets del naranjo (arte real + fallback de respaldo)', () {
    test('icono general y perfiles OR usan los PNG finales', () {
      expect(
        OrangeTreeAssets.genericTreeFallback,
        'assets/icons/wizard/ic_tree.png',
      );
      expect(OrangeTreeAssets.cropIcon, OrangeTreeAssets.iconTree);
      expect(OrangeTreeAssets.neutralIcon, OrangeTreeAssets.iconGeneric);
      expect(orangeTreeProfileIcon(kOrSkip), OrangeTreeAssets.iconGeneric);
      expect(
        orangeTreeProfileIcon(kOr01Valencia),
        OrangeTreeAssets.iconValencia,
      );
      expect(orangeTreeProfileIcon(kOr02Navel), OrangeTreeAssets.iconNavel);
      expect(
        orangeTreeProfileIcon(kOr03Temprano),
        OrangeTreeAssets.iconTemprano,
      );
      expect(
        orangeTreeProfileIcon(kOr04CriolloRegional),
        OrangeTreeAssets.iconCriolloRegional,
      );
      expect(
        orangeTreeProfileIcon(kOr05TropicalCalido),
        OrangeTreeAssets.iconTropicalCalido,
      );
    });

    test('dormancy NO usa arbol pelon: citrico siempreverde con hoja', () {
      // Regla citrica (doc 01 §0.5): reposo relativo NO es arbol caducifolio.
      expect(
        orangeTreeStageImageOrNeutral(TreeStageIds.dormancy),
        'assets/seeds/orange/orange_stage_dormancy.png',
      );
      expect(
        orangeTreeStageImageOrNeutral(TreeStageIds.dormancy),
        isNot(contains('leafless')),
      );
      expect(
        orangeTreeStageImageOrNeutral(TreeStageIds.dormancy),
        isNot(contains('dormant_leafless')),
      );
    });

    test('toda etapa devuelve su asset fenologico real', () {
      for (final stage in <String>[
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
        final asset = orangeTreeStageImageOrNeutral(stage);
        expect(asset, startsWith('assets/seeds/orange/'), reason: stage);
        expect(asset, endsWith('.png'), reason: stage);
      }
      // fruit_fill = fruta creciendo (verde), harvest = lista para cortar.
      expect(
        orangeTreeStageImageOrNeutral(TreeStageIds.fruitFill),
        'assets/seeds/orange/orange_stage_fruit_fill.png',
      );
      expect(
        orangeTreeStageImageOrNeutral(TreeStageIds.harvestMaturity),
        'assets/seeds/orange/orange_stage_harvest_maturity.png',
      );
    });

    test('las rutas finales esperadas estan cableadas', () {
      expect(
        OrangeTreeAssets.iconTree,
        'assets/icons/wizard/ic_orange_tree.png',
      );
      expect(
        orangeTreeProfileIcon(kOr02Navel),
        'assets/icons/wizard/ic_orange_navel.png',
      );
      expect(
        orangeTreeStageImage(TreeStageIds.unknown),
        'assets/seeds/orange/orange_stage_unknown.png',
      );
    });
  });

  group('Copy citrico de etapas (presentacion, sin cambiar StageIds)', () {
    test('etapas clave del naranjo usan lenguaje citrico', () {
      expect(
        treeStageDisplayNameForCrop(kCropOrangeTree, TreeStageIds.dormancy),
        'Reposo relativo / baja actividad',
      );
      expect(
        treeStageDisplayNameForCrop(kCropOrangeTree, TreeStageIds.flowering),
        'Floración / azahar',
      );
      expect(
        treeStageDisplayNameForCrop(kCropOrangeTree, TreeStageIds.fruitFill),
        'Naranja creciendo / llenando',
      );
      expect(
        treeStageDisplayNameForCrop(
          kCropOrangeTree,
          TreeStageIds.harvestMaturity,
        ),
        'Naranja madura / cosecha',
      );
    });

    test('fruit_fill del naranjo NO dice cosecha; harvest_maturity SI', () {
      final fill = treeStageDisplayNameForCrop(
        kCropOrangeTree,
        TreeStageIds.fruitFill,
      ).toLowerCase();
      expect(fill, anyOf(contains('llenando'), contains('creciendo')));
      expect(fill, isNot(contains('cosecha')));
      expect(fill, isNot(contains('madura')));

      final harvest = treeStageDisplayNameForCrop(
        kCropOrangeTree,
        TreeStageIds.harvestMaturity,
      ).toLowerCase();
      expect(harvest, anyOf(contains('cosecha'), contains('madura')));
    });

    test('dormancy del naranjo NO se pinta como arbol pelon', () {
      final dorm = treeStageDisplayNameForCrop(
        kCropOrangeTree,
        TreeStageIds.dormancy,
      ).toLowerCase();
      expect(dorm, contains('reposo'));
      expect(dorm, isNot(contains('pelón')));
      expect(dorm, isNot(contains('pelon')));
    });

    test('otros arboles NO cambian (durazno usa copy generico)', () {
      expect(
        treeStageDisplayNameForCrop(
          CropCatalog.peachTreeCropId,
          TreeStageIds.fruitFill,
        ),
        treeStageDisplayName(TreeStageIds.fruitFill),
      );
    });
  });

  group('Prioridades NPK por etapa (doc 05 §11)', () {
    test('en fruit_fill K domina sobre N y N sobre P', () {
      final p = resolveOrangeTreeNutritionPriorities(TreeStageIds.fruitFill);
      expect(p.kPriority01, greaterThan(p.nPriority01));
      expect(p.nPriority01, greaterThan(p.pPriority01));
      expect(p.dominantNutrient, AgroMetricKey.k);
    });

    test('en establecimiento P es el dominante (raiz primero)', () {
      final p = resolveOrangeTreeNutritionPriorities(
        TreeStageIds.rootEstablishment,
      );
      expect(p.dominantNutrient, AgroMetricKey.p);
    });

    test('en vegetative_growth N es el dominante', () {
      final p = resolveOrangeTreeNutritionPriorities(
        TreeStageIds.vegetativeGrowth,
      );
      expect(p.dominantNutrient, AgroMetricKey.n);
    });

    test('en fruit_set K empieza a mandar sobre N y P', () {
      final p = resolveOrangeTreeNutritionPriorities(TreeStageIds.fruitSet);
      expect(p.dominantNutrient, AgroMetricKey.k);
    });
  });

  group('Rendimiento del naranjo (doc 03): perenne, citrico, siempreverde', () {
    test('estado no productivo proyecta 0 y no cierra cultivo', () {
      final proj = resolveOrangeTreeYield(
        profileId: kOrSkip,
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.plantingTransplant,
        treeCount: 300,
      );
      expect(proj.isProductive, isFalse);
      expect(proj.kgPerTree, YieldRange.zero);
    });

    test('mala floracion/cuajado castiga el amarre (no polinizacion macho)', () {
      final goodSet = resolveOrangeTreeYield(
        profileId: kOr01Valencia,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 350,
        productionState: OrangeProductionState.fullBearing,
        bloomSetStatus: OrangeBloomSetStatus.goodBloomGoodSet,
      );
      final poorSet = resolveOrangeTreeYield(
        profileId: kOr01Valencia,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 350,
        productionState: OrangeProductionState.fullBearing,
        bloomSetStatus: OrangeBloomSetStatus.frostHeatRainSetLoss,
      );
      expect(
        poorSet.kgPerTree!.expected,
        lessThan(goodSet.kgPerTree!.expected),
      );
    });

    test('alta densidad capea kg/arbol (no multiplica como arbol amplio)', () {
      final proj = resolveOrangeTreeYield(
        profileId: kOr01Valencia,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 700, // >650 => cap 55 kg/arbol
        productionState: OrangeProductionState.fullBearing,
        managementLevel: OrangeManagementLevel.high,
        irrigationLevel: OrangeIrrigationLevel.fertigation,
      );
      expect(proj.kgPerTree!.expected, lessThanOrEqualTo(55.0));
    });

    test('post_harvest permite calculo (no cierra el cultivo)', () {
      final proj = resolveOrangeTreeYield(
        profileId: kOr02Navel,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.postHarvest,
        treesPerHa: 350,
      );
      expect(proj.isProductive, isTrue);
    });

    test('alias previo de perfil conserva historial (no cae a SKIP)', () {
      final proj = resolveOrangeTreeYield(
        profileId: 'or_01_valencia_tardia',
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 350,
        productionState: OrangeProductionState.fullBearing,
      );
      expect(proj.profileId, kOr01Valencia);
    });

    test('EC/salinidad severa en memoria baja la proyeccion', () {
      final base = resolveOrangeTreeYield(
        profileId: kOrSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 350,
        productionState: OrangeProductionState.fullBearing,
      );
      final salted = resolveOrangeTreeYield(
        profileId: kOrSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 350,
        productionState: OrangeProductionState.fullBearing,
        stressMemory: const OrangeTreeStressMemory(
          salinityOrSodicityStress: OrangeStressSeverity.severe,
        ),
      );
      expect(
        salted.kgPerTree!.expected,
        lessThan(base.kgPerTree!.expected),
      );
    });
  });
}
