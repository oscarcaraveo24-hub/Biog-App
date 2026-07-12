// test/core/pistachio_tree/pistachio_tree_finalize_test.dart
//
// Cierre de integracion del Pistache: assets reales, fallback seguro de
// respaldo, copy pistachero de etapas (dioico,
// fruit_fill != harvest), NpkCaps (130/95/220), K protagonista en fruit_fill,
// prioridades por etapa, guardas NPK (EC/humedad/pH mandan, con umbral de sal
// mas alto que el nogal porque el pistache tolera mas sales) y migracion de PS.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_assets.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_catalog.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_universal_profile.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_yield_reference.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Assets del pistache (arte real + fallback de respaldo)', () {
    test('icono general y perfiles PS usan los PNG finales', () {
      expect(
        PistachioTreeAssets.genericTreeFallback,
        'assets/icons/wizard/ic_tree.png',
      );
      expect(PistachioTreeAssets.cropIcon, PistachioTreeAssets.iconTree);
      expect(PistachioTreeAssets.neutralIcon, PistachioTreeAssets.iconGeneric);
      expect(pistachioTreeProfileIcon(kPsSkip), PistachioTreeAssets.iconGeneric);
      expect(
        pistachioTreeProfileIcon(kPs01KermanPeters),
        PistachioTreeAssets.iconKerman,
      );
      expect(
        pistachioTreeProfileIcon(kPs02GoldenHillsRandy),
        PistachioTreeAssets.iconGoldenHills,
      );
      expect(
        pistachioTreeProfileIcon(kPs03LostHillsRandy),
        PistachioTreeAssets.iconLostHills,
      );
      expect(
        pistachioTreeProfileIcon(kPs04SiroraCompatible),
        PistachioTreeAssets.iconSirora,
      );
      expect(
        pistachioTreeProfileIcon(kPs05LarnakaMateurLowChill),
        PistachioTreeAssets.iconMediterraneanLowChill,
      );
    });

    test('toda etapa devuelve su asset fenologico real', () {
      final expected = <String, String>{
        TreeStageIds.plantingTransplant:
            PistachioTreeAssets.stagePlantingTransplant,
        TreeStageIds.rootEstablishment:
            PistachioTreeAssets.stageRootEstablishment,
        TreeStageIds.juvenileVegetative:
            PistachioTreeAssets.stageJuvenileVegetative,
        TreeStageIds.dormancy: PistachioTreeAssets.stageDormancy,
        TreeStageIds.budbreak: PistachioTreeAssets.stageBudbreak,
        TreeStageIds.vegetativeGrowth:
            PistachioTreeAssets.stageVegetativeGrowth,
        TreeStageIds.flowering: PistachioTreeAssets.stageFlowering,
        TreeStageIds.fruitSet: PistachioTreeAssets.stageFruitSet,
        TreeStageIds.fruitFill: PistachioTreeAssets.stageFruitFill,
        TreeStageIds.harvestMaturity:
            PistachioTreeAssets.stageHarvestMaturity,
        TreeStageIds.postHarvest: PistachioTreeAssets.stagePostHarvest,
        TreeStageIds.unknown: PistachioTreeAssets.stageUnknown,
      };

      for (final entry in expected.entries) {
        expect(
          pistachioTreeStageImageOrNeutral(entry.key),
          entry.value,
          reason: entry.key,
        );
        expect(entry.value, startsWith('assets/seeds/pistachio/'));
      }
    });

    test('las rutas finales esperadas estan cableadas', () {
      expect(
        PistachioTreeAssets.iconTree,
        'assets/icons/wizard/ic_pistachio_tree.png',
      );
      expect(
        pistachioTreeStageImage(TreeStageIds.fruitFill),
        'assets/seeds/pistachio/pistachio_stage_fruit_fill.png',
      );
    });
  });

  group('Copy pistachero de etapas (presentacion, sin cambiar StageIds)', () {
    test('etapas clave del pistache usan lenguaje pistachero/dioico', () {
      expect(
        treeStageDisplayNameForCrop(kCropPistachioTree, TreeStageIds.flowering),
        'Floración macho/hembra',
      );
      expect(
        treeStageDisplayNameForCrop(kCropPistachioTree, TreeStageIds.fruitSet),
        'Cuajado / amarre',
      );
      expect(
        treeStageDisplayNameForCrop(kCropPistachioTree, TreeStageIds.fruitFill),
        'Llenado de pistache / kernel',
      );
      expect(
        treeStageDisplayNameForCrop(
          kCropPistachioTree,
          TreeStageIds.harvestMaturity,
        ),
        'Pistache abriendo / cosecha',
      );
    });

    test('fruit_fill del pistache NO dice cosecha; harvest_maturity SI', () {
      final fill = treeStageDisplayNameForCrop(
        kCropPistachioTree,
        TreeStageIds.fruitFill,
      ).toLowerCase();
      expect(fill, contains('llenado'));
      expect(fill, isNot(contains('cosecha')));
      expect(fill, isNot(contains('abriendo')));

      final harvest = treeStageDisplayNameForCrop(
        kCropPistachioTree,
        TreeStageIds.harvestMaturity,
      ).toLowerCase();
      expect(harvest, anyOf(contains('cosecha'), contains('abriendo')));
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

  group('NpkCaps del pistache (doc 05 §5)', () {
    test('N=130, P=95, K=220 para todos los alias', () {
      for (final crop in const <String>[
        'pistachio_tree',
        'crop_pistachio_tree',
        'pistache',
        'pistacho',
        'pistachio',
      ]) {
        expect(
          NpkCaps.forCropMetric(cropKey: crop, metricKey: AgroMetricKey.n),
          130.0,
          reason: '$crop N',
        );
        expect(
          NpkCaps.forCropMetric(cropKey: crop, metricKey: AgroMetricKey.p),
          95.0,
          reason: '$crop P',
        );
        expect(
          NpkCaps.forCropMetric(cropKey: crop, metricKey: AgroMetricKey.k),
          220.0,
          reason: '$crop K',
        );
      }
    });
  });

  group('Prioridades NPK por etapa (doc 05 §11)', () {
    test('en fruit_fill K domina sobre N y N sobre P', () {
      final p = resolvePistachioTreeNutritionPriorities(TreeStageIds.fruitFill);
      expect(p.kPriority01, greaterThan(p.nPriority01));
      expect(p.nPriority01, greaterThan(p.pPriority01));
      expect(p.dominantNutrient, AgroMetricKey.k);
    });

    test('en establecimiento P es el dominante (raiz primero)', () {
      final p = resolvePistachioTreeNutritionPriorities(
        TreeStageIds.rootEstablishment,
      );
      expect(p.dominantNutrient, AgroMetricKey.p);
    });

    test('en vegetative_growth N es el dominante', () {
      final p = resolvePistachioTreeNutritionPriorities(
        TreeStageIds.vegetativeGrowth,
      );
      expect(p.dominantNutrient, AgroMetricKey.n);
    });
  });

  group('Guardas NPK del pistache (EC/humedad/pH mandan antes que NPK)', () {
    NutrientInterpretationResult interpretK({
      required double ec,
      required double soilMoisturePct,
      required double ph,
      String stage = TreeStageIds.fruitFill,
    }) {
      return NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.k,
        rawPpm: 20, // K bajo
        cropKey: 'pistachio_tree',
        stageKey: stage,
        profileId: kPs01KermanPeters,
        targets: resolvePistachioTreeTargets(stage),
        weights: resolvePistachioTreeStageWeights(stage),
        ph: ph,
        ec: ec,
        soilMoisturePct: soilMoisturePct,
      );
    }

    test('EC alta (>4.5, umbral pistache) encabeza con guarda de sales', () {
      final r = interpretK(ec: 5.0, soilMoisturePct: 70, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(msg, anyOf(contains('salinidad'), contains('sales')));
      expect(msg, anyOf(contains('lavado'), contains('drenaje')));
    });

    test('EC moderada (3.0) NO bloquea: el pistache tolera mas sal que el nogal', () {
      final r = interpretK(ec: 3.0, soilMoisturePct: 70, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      // A 3.0 dS/m no se dispara la guarda dura del pistache; habla de potasio.
      expect(msg, contains('potasio'));
    });

    test('humedad critica baja: agua primero (raiz estresada)', () {
      final r = interpretK(ec: 0.5, soilMoisturePct: 35, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(msg, contains('humedad'));
      expect(msg, anyOf(contains('kernel'), contains('estabiliza')));
    });

    test('humedad saturada: oxigeno/raiz/drenaje, no mas fertilizante', () {
      final r = interpretK(ec: 0.5, soilMoisturePct: 95, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(
        msg,
        anyOf(contains('saturado'), contains('oxígeno'), contains('drenaje')),
      );
    });

    test('pH alto (>8.2): advierte bloqueo de hierro/zinc/cobre, no N', () {
      final r = interpretK(ec: 0.5, soilMoisturePct: 70, ph: 8.3);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(
        msg,
        anyOf(contains('zinc'), contains('hierro'), contains('disponibilidad')),
      );
    });

    test('suelo OK: NO se dispara guarda; habla de potasio/kernel', () {
      final r = interpretK(ec: 0.5, soilMoisturePct: 72, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(msg, contains('potasio'));
      expect(msg, isNot(contains('saturado')));
    });
  });

  group('N bajo tardio: no empujar N en cosecha/postcosecha (doc 05 §8.1)', () {
    NutrientInterpretationResult interpretLowN(String stage) {
      return NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: 10, // N bajo
        cropKey: 'pistachio_tree',
        stageKey: stage,
        profileId: kPs01KermanPeters,
        targets: resolvePistachioTreeTargets(stage),
        weights: resolvePistachioTreeStageWeights(stage),
        ph: 7.0,
        ec: 0.5,
        soilMoisturePct: 70,
      );
    }

    test('harvest_maturity: no empuja N; cuida calidad y manda a postcosecha', () {
      final msg = interpretLowN(TreeStageIds.harvestMaturity)
          .practicalRecommendation
          .toLowerCase();
      expect(msg, anyOf(contains('cosecha'), contains('madurez')));
      expect(msg, contains('postcosecha'));
      expect(msg, isNot(contains('aplica una corrección')));
    });

    test('post_harvest: no asume que el arbol pide N (solo si hoja activa)', () {
      final msg = interpretLowN(TreeStageIds.postHarvest)
          .practicalRecommendation
          .toLowerCase();
      expect(msg, contains('postcosecha'));
      expect(msg, anyOf(contains('hoja'), contains('reservas')));
      expect(msg, isNot(contains('aplica una corrección')));
    });

    test('fruit_fill: N bajo SI puede corregir ligero (no es etapa tardia)', () {
      final msg = interpretLowN(TreeStageIds.fruitFill)
          .practicalRecommendation
          .toLowerCase();
      expect(msg, contains('llenado'));
      expect(msg, isNot(contains('postcosecha')));
    });
  });

  group('Rendimiento del pistache (doc 03): perenne, dioico, alternancia', () {
    test('estado no productivo proyecta 0 y no cierra cultivo', () {
      final proj = resolvePistachioTreeYield(
        profileId: kPsSkip,
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.plantingTransplant,
        treeCount: 300,
      );
      expect(proj.isProductive, isFalse);
      expect(proj.kgPerTree, YieldRange.zero);
    });

    test('falta de macho castiga fuerte el amarre (polinizacion central)', () {
      final withMale = resolvePistachioTreeYield(
        profileId: kPs01KermanPeters,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 316,
        productionState: PistachioProductionState.fullBearing,
        pollinationStatus: PistachioPollinationStatus.compatibleMalePresent,
      );
      final noMale = resolvePistachioTreeYield(
        profileId: kPs01KermanPeters,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 316,
        productionState: PistachioProductionState.fullBearing,
        pollinationStatus: PistachioPollinationStatus.noMaleKnown,
      );
      expect(
        noMale.kgPerTree!.expected,
        lessThan(withMale.kgPerTree!.expected),
      );
    });

    test('post_harvest permite calculo (no cierra el cultivo)', () {
      final proj = resolvePistachioTreeYield(
        profileId: kPs02GoldenHillsRandy,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.postHarvest,
        treesPerHa: 316,
      );
      expect(proj.isProductive, isTrue);
    });

    test('alias previo de perfil conserva historial (no cae a SKIP)', () {
      final proj = resolvePistachioTreeYield(
        profileId: 'ps_02_golden_hills',
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 316,
        productionState: PistachioProductionState.fullBearing,
      );
      expect(proj.profileId, kPs02GoldenHillsRandy);
    });
  });
}
