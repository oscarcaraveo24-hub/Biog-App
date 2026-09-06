// test/core/lemon_tree/lemon_tree_finalize_test.dart
//
// Cierre de integracion del Limon: assets (dormancy = reposo relativo verde, NO
// arbol pelon, por ser citrico siempreverde), copy citrico de etapas (fruit_fill
// != harvest; harvest puede ser corte verde comercial), K protagonista en
// fruit_fill, prioridades por etapa y migracion de LM. El limon NO es un
// naranjo pequeno.
//
// Las pruebas de topes ppm y de interpretacion NPK por lectura se retiraron
// con el reset del motor nutricional (Guia v0.4).

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_assets.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_catalog.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_universal_profile.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_yield_reference.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Assets del limon (placeholder citrico + fallback de respaldo)', () {
    test('icono general y perfiles LM resuelven un PNG', () {
      expect(
        LemonTreeAssets.genericTreeFallback,
        'assets/icons/wizard/ic_tree.png',
      );
      expect(LemonTreeAssets.cropIcon, LemonTreeAssets.iconTree);
      expect(LemonTreeAssets.neutralIcon, LemonTreeAssets.iconGeneric);
      expect(lemonTreeProfileIcon(kLmSkip), LemonTreeAssets.iconGeneric);
      expect(
        lemonTreeProfileIcon(kLm01PersaTahiti),
        LemonTreeAssets.iconPersaTahiti,
      );
      expect(
        lemonTreeProfileIcon(kLm02MexicanoColima),
        LemonTreeAssets.iconMexicanoColima,
      );
      expect(
        lemonTreeProfileIcon(kLm03AmarilloEurekaLisbon),
        LemonTreeAssets.iconAmarilloEurekaLisbon,
      );
      expect(
        lemonTreeProfileIcon(kLm04TropicalContinuo),
        LemonTreeAssets.iconTropicalContinuo,
      );
      expect(
        lemonTreeProfileIcon(kLm05DesfaseInducido),
        LemonTreeAssets.iconDesfaseInducido,
      );
    });

    test('dormancy NO usa arbol pelon: citrico siempreverde con hoja', () {
      // Regla citrica (doc 01 §0.6): reposo relativo NO es arbol caducifolio.
      expect(
        lemonTreeStageImageOrNeutral(TreeStageIds.dormancy),
        'assets/seeds/lemon/lemon_stage_dormancy.png',
      );
      expect(
        lemonTreeStageImageOrNeutral(TreeStageIds.dormancy),
        isNot(contains('leafless')),
      );
    });

    test('toda etapa devuelve su asset fenologico de limon', () {
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
        final asset = lemonTreeStageImageOrNeutral(stage);
        expect(asset, startsWith('assets/seeds/lemon/'), reason: stage);
        expect(asset, endsWith('.png'), reason: stage);
      }
    });
  });

  group('Copy citrico de etapas (presentacion, sin cambiar StageIds)', () {
    test('etapas clave del limon usan lenguaje citrico propio', () {
      expect(
        treeStageDisplayNameForCrop(kCropLemonTree, TreeStageIds.dormancy),
        'Reposo relativo / entre cortes',
      );
      expect(
        treeStageDisplayNameForCrop(kCropLemonTree, TreeStageIds.flowering),
        'Floración / azahar',
      );
      expect(
        treeStageDisplayNameForCrop(kCropLemonTree, TreeStageIds.fruitFill),
        'Limón creciendo / llenando',
      );
      expect(
        treeStageDisplayNameForCrop(
          kCropLemonTree,
          TreeStageIds.harvestMaturity,
        ),
        'Limón listo para corte',
      );
    });

    test('fruit_fill del limon NO dice cosecha; harvest_maturity habla de corte', () {
      final fill = treeStageDisplayNameForCrop(
        kCropLemonTree,
        TreeStageIds.fruitFill,
      ).toLowerCase();
      expect(fill, anyOf(contains('llenando'), contains('creciendo')));
      expect(fill, isNot(contains('cosecha')));

      final harvest = treeStageDisplayNameForCrop(
        kCropLemonTree,
        TreeStageIds.harvestMaturity,
      ).toLowerCase();
      expect(harvest, contains('corte'));
    });

    test('post_harvest del limon NO cierra: entre cortes', () {
      expect(
        treeStageDisplayNameForCrop(kCropLemonTree, TreeStageIds.postHarvest),
        'Postcosecha / entre cortes',
      );
    });

    test('el limon NO es un naranjo pequeno: copy propio distinto', () {
      // El copy del limon en fruit_fill/harvest difiere del naranjo.
      expect(
        treeStageDisplayNameForCrop(kCropLemonTree, TreeStageIds.fruitFill),
        isNot(
          treeStageDisplayNameForCrop(
            CropCatalog.orangeTreeCropId,
            TreeStageIds.fruitFill,
          ),
        ),
      );
    });
  });

  group('Prioridades NPK por etapa (doc 05 §7)', () {
    test('en fruit_fill K domina sobre N y N sobre P', () {
      final p = resolveLemonTreeNutritionPriorities(TreeStageIds.fruitFill);
      expect(p.kPriority01, greaterThan(p.nPriority01));
      expect(p.nPriority01, greaterThan(p.pPriority01));
      expect(p.dominantNutrient, AgroMetricKey.k);
    });

    test('en establecimiento P es el dominante (raiz primero)', () {
      final p = resolveLemonTreeNutritionPriorities(
        TreeStageIds.rootEstablishment,
      );
      expect(p.dominantNutrient, AgroMetricKey.p);
    });

    test('en vegetative_growth N es el dominante', () {
      final p = resolveLemonTreeNutritionPriorities(
        TreeStageIds.vegetativeGrowth,
      );
      expect(p.dominantNutrient, AgroMetricKey.n);
    });

    test('en fruit_set K empieza a mandar sobre N y P', () {
      final p = resolveLemonTreeNutritionPriorities(TreeStageIds.fruitSet);
      expect(p.dominantNutrient, AgroMetricKey.k);
    });
  });

  group('Rendimiento del limon (doc 03): perenne, citrico, siempreverde', () {
    test('estado no productivo proyecta 0 y no cierra cultivo', () {
      final proj = resolveLemonTreeYield(
        profileId: kLmSkip,
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.plantingTransplant,
        treeCount: 300,
      );
      expect(proj.isProductive, isFalse);
      expect(proj.kgPerTree, YieldRange.zero);
    });

    test('desfase mal aplicado (inducedBloomStressFailure) baja el amarre', () {
      final managed = resolveLemonTreeYield(
        profileId: kLm05DesfaseInducido,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 350,
        productionState: LemonProductionState.offSeasonInduced,
        bloomSetStatus: LemonBloomSetStatus.inducedBloomManaged,
      );
      final failure = resolveLemonTreeYield(
        profileId: kLm05DesfaseInducido,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 350,
        productionState: LemonProductionState.offSeasonInduced,
        bloomSetStatus: LemonBloomSetStatus.inducedBloomStressFailure,
      );
      expect(
        failure.kgPerTree!.expected,
        lessThan(managed.kgPerTree!.expected),
      );
    });

    test('alta densidad capea kg/arbol (no multiplica como arbol amplio)', () {
      final proj = resolveLemonTreeYield(
        profileId: kLm01PersaTahiti,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 800, // 650-900 => cap 55 kg/arbol
        productionState: LemonProductionState.fullBearing,
        managementLevel: LemonManagementLevel.high,
        irrigationLevel: LemonIrrigationLevel.fertigation,
      );
      expect(proj.kgPerTree!.expected, lessThanOrEqualTo(55.0));
    });

    test('post_harvest permite calculo (no cierra el cultivo)', () {
      final proj = resolveLemonTreeYield(
        profileId: kLm02MexicanoColima,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.postHarvest,
        treesPerHa: 350,
      );
      expect(proj.isProductive, isTrue);
    });

    test('alias previo de perfil conserva historial (no cae a SKIP)', () {
      final proj = resolveLemonTreeYield(
        profileId: 'lm_01_persa',
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 350,
        productionState: LemonProductionState.fullBearing,
      );
      expect(proj.profileId, kLm01PersaTahiti);
    });

    test('HLB severo en memoria baja fuerte la proyeccion (cap hard)', () {
      final base = resolveLemonTreeYield(
        profileId: kLmSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 350,
        productionState: LemonProductionState.fullBearing,
      );
      final hlb = resolveLemonTreeYield(
        profileId: kLmSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 350,
        productionState: LemonProductionState.fullBearing,
        stressMemory: const LemonTreeStressMemory(
          hlbOrCanopyDecline: LemonStressSeverity.severe,
        ),
      );
      expect(hlb.kgPerTree!.expected, lessThan(base.kgPerTree!.expected));
    });

    test('el limon NO hereda kg/arbol del naranjo (referencia propia)', () {
      // lm_01_persa kg/arbol adulto (35/70/115) difiere de or_01 (35/60/95).
      expect(
        lemonYieldReferenceByProfile[kLm01PersaTahiti]!.fullKgPerTree.expected,
        70,
      );
    });
  });
}
