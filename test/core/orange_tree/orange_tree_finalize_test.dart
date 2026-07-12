// test/core/orange_tree/orange_tree_finalize_test.dart
//
// Cierre de integracion del Naranjo: assets reales (dormancy usa reposo
// relativo verde, NO arbol pelon, por ser citrico siempreverde), copy citrico
// de etapas (fruit_fill != harvest; dormancy = reposo relativo), NpkCaps
// (120/95/200), K protagonista en fruit_fill, prioridades por etapa, guardas NPK
// (EC/humedad/pH mandan, con umbral de sal MAS BAJO que nogal/pistache porque el
// citrico es sensible a sales) y migracion de OR.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
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

  group('NpkCaps del naranjo (doc 05 §0.3)', () {
    test('N=120, P=95, K=200 para todos los alias', () {
      for (final crop in const <String>[
        'orange_tree',
        'crop_orange_tree',
        'naranjo',
        'naranja',
        'orange',
      ]) {
        expect(
          NpkCaps.forCropMetric(cropKey: crop, metricKey: AgroMetricKey.n),
          120.0,
          reason: '$crop N',
        );
        expect(
          NpkCaps.forCropMetric(cropKey: crop, metricKey: AgroMetricKey.p),
          95.0,
          reason: '$crop P',
        );
        expect(
          NpkCaps.forCropMetric(cropKey: crop, metricKey: AgroMetricKey.k),
          200.0,
          reason: '$crop K',
        );
      }
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

  group('Guardas NPK del naranjo (EC/humedad/pH mandan antes que NPK)', () {
    NutrientInterpretationResult interpretK({
      required double ec,
      required double soilMoisturePct,
      required double ph,
      String stage = TreeStageIds.fruitFill,
    }) {
      return NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.k,
        rawPpm: 20, // K bajo
        cropKey: 'orange_tree',
        stageKey: stage,
        profileId: kOr01Valencia,
        targets: resolveOrangeTreeTargets(stage),
        weights: resolveOrangeTreeStageWeights(stage),
        ph: ph,
        ec: ec,
        soilMoisturePct: soilMoisturePct,
      );
    }

    test('EC alta (>2.0, umbral citrico sensible) encabeza con guarda de sales', () {
      final r = interpretK(ec: 2.4, soilMoisturePct: 70, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(msg, anyOf(contains('salinidad'), contains('sales')));
      expect(msg, anyOf(contains('lavado'), contains('drenaje')));
    });

    test('EC 1.5 NO bloquea aun: habla de potasio (umbral citrico ~2.0)', () {
      final r = interpretK(ec: 1.5, soilMoisturePct: 70, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(msg, contains('potasio'));
    });

    test('humedad critica baja: agua primero (raiz estresada)', () {
      final r = interpretK(ec: 0.5, soilMoisturePct: 35, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(msg, contains('humedad'));
      expect(msg, anyOf(contains('naranja'), contains('estabiliza')));
    });

    test('humedad saturada: gomosis/raiz/drenaje, no mas fertilizante', () {
      final r = interpretK(ec: 0.5, soilMoisturePct: 95, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(
        msg,
        anyOf(contains('saturado'), contains('gomosis'), contains('drenaje')),
      );
    });

    test('pH alto (>8.0): advierte Fe/Zn/Mn, no N', () {
      final r = interpretK(ec: 0.5, soilMoisturePct: 70, ph: 8.2);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(
        msg,
        anyOf(contains('zinc'), contains('hierro'), contains('nervadura')),
      );
    });

    test('suelo OK: NO se dispara guarda; habla de potasio/calibre', () {
      final r = interpretK(ec: 0.5, soilMoisturePct: 72, ph: 7.0);
      final msg = r.practicalRecommendation.toLowerCase();
      expect(msg, contains('potasio'));
      expect(msg, isNot(contains('saturado')));
    });
  });

  group('N bajo tardio: no empujar N en cosecha/postcosecha (doc 05 §8.10)', () {
    NutrientInterpretationResult interpretLowN(String stage) {
      return NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: 8, // N bajo
        cropKey: 'orange_tree',
        stageKey: stage,
        profileId: kOr02Navel,
        targets: resolveOrangeTreeTargets(stage),
        weights: resolveOrangeTreeStageWeights(stage),
        ph: 7.0,
        ec: 0.5,
        soilMoisturePct: 70,
      );
    }

    test('harvest_maturity: no empuja N; cuida color/calidad y va a postcosecha', () {
      final msg = interpretLowN(TreeStageIds.harvestMaturity)
          .practicalRecommendation
          .toLowerCase();
      expect(msg, anyOf(contains('cosecha'), contains('color')));
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
