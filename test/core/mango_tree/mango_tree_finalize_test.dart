// test/core/mango_tree/mango_tree_finalize_test.dart
//
// Cierre de integracion del Mango: assets reales de Mango (iconos por perfil y
// etapas en assets/seeds/mango), dormancy = reposo funcional, NO arbol pelon,
// copy propio de
// etapas (fruit_fill != cosecha; panicula/manguito; el mango NO es limon/naranjo),
// NpkCaps (115/95/190, K menor que citricos pero mayor que durazno), K
// protagonista en fruit_fill, prioridades por etapa, guardas NPK (EC/humedad/pH
// mandan; reposo funcional NO se castiga por seco), N tardio (no N en madurez de
// cambio de color; postcosecha = reservas), rendimiento (no-floracion valida,
// alternancia, cap por densidad) y migracion MG. El mango NO es limon, NO es
// naranjo, NO es manzano.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_assets.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_catalog.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_universal_profile.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_yield_reference.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Catalogo y registro del mango', () {
    test('crop_mango_tree resuelve a un arbol propio (no limon/naranjo)', () {
      expect(CropRegistry.byKeyName('crop_mango_tree')?.cropKey,
          CropKey.mangoTree);
      expect(CropRegistry.byKeyName('mango')?.cropKey, CropKey.mangoTree);
      expect(CropRegistry.byKeyName('mangifera')?.cropKey, CropKey.mangoTree);
      expect(CropRegistry.byKeyName('árbol_mango')?.cropKey, CropKey.mangoTree);
    });

    test('canonicalCropKey mapea alias a crop_mango_tree', () {
      for (final alias in const <String>[
        'mango',
        'mangos',
        'mango_tree',
        'crop_mango',
        'mangifera',
        'mangifera_indica',
        'arbol_mango',
      ]) {
        expect(CropCatalog.canonicalCropKey(alias),
            CropCatalog.mangoTreeCropId, reason: alias);
      }
    });

    test('el catalogo expone Mango como cultivo habilitado de arbol', () {
      final crop = CropCatalog.cropById(CropCatalog.mangoTreeCropId);
      expect(crop, isNotNull);
      expect(crop!.enabled, isTrue);
      expect(crop.categoryId, CropCatalog.treeCategoryId);
      expect(crop.defaultProfileId, kMgSkip);
      expect(crop.label, 'Mango');
    });

    test('perfiles MG: skip general + 5 variedades', () {
      final ids = mangoTreeProfileEntries.map((e) => e.id).toSet();
      expect(ids, containsAll(<String>{
        kMgSkip,
        kMg01AtaulfoManila,
        kMg02TommyAtkins,
        kMg03Kent,
        kMg04Keitt,
        kMg05CriolloRegional,
      }));
    });
  });

  group('Assets del mango (arte final)', () {
    test('icono general y perfiles MG resuelven PNG reales de mango', () {
      expect(
        MangoTreeAssets.genericTreeFallback,
        'assets/icons/wizard/ic_mango_tree.png',
      );
      expect(MangoTreeAssets.cropIcon, MangoTreeAssets.iconTree);
      expect(mangoTreeProfileIcon(kMgSkip), MangoTreeAssets.cropIcon);
      expect(
        mangoTreeProfileIcon(kMg01AtaulfoManila),
        'assets/icons/wizard/ic_mango_ataulfo_manila.png',
      );
      expect(
        mangoTreeProfileIcon('mg_01_ataulfo'),
        'assets/icons/wizard/ic_mango_ataulfo_manila.png',
      );
      expect(
        mangoTreeProfileIcon(kMg02TommyAtkins),
        'assets/icons/wizard/ic_mango_tommy_atkins.png',
      );
      expect(
        mangoTreeProfileIcon(kMg03Kent),
        'assets/icons/wizard/ic_mango_kent.png',
      );
      expect(
        mangoTreeProfileIcon(kMg04Keitt),
        'assets/icons/wizard/ic_mango_keitt.png',
      );
      expect(
        mangoTreeProfileIcon(kMg05CriolloRegional),
        'assets/icons/wizard/ic_mango_criollo_regional.png',
      );
    });

    test('dormancy NO usa arbol pelon: reposo funcional de mango', () {
      // Regla mango (doc 01 §0.6): reposo funcional NO es arbol pelon.
      final asset = mangoTreeStageImageOrNeutral(TreeStageIds.dormancy);
      expect(asset, isNot(contains('leafless')));
      expect(asset, 'assets/seeds/mango/mango_stage_dormancy.png');
    });

    test('toda etapa devuelve el PNG final esperado', () {
      const expectedAssets = <String, String>{
        TreeStageIds.plantingTransplant:
            'assets/seeds/mango/mango_stage_planting_transplant.png',
        TreeStageIds.rootEstablishment:
            'assets/seeds/mango/mango_stage_root_establishment.png',
        TreeStageIds.juvenileVegetative:
            'assets/seeds/mango/mango_stage_juvenile_vegetative.png',
        TreeStageIds.dormancy:
            'assets/seeds/mango/mango_stage_dormancy.png',
        TreeStageIds.budbreak:
            'assets/seeds/mango/mango_stage_budbreak.png',
        TreeStageIds.vegetativeGrowth:
            'assets/seeds/mango/mango_stage_vegetative_growth.png',
        TreeStageIds.flowering:
            'assets/seeds/mango/mango_stage_flowering.png',
        TreeStageIds.fruitSet:
            'assets/seeds/mango/mango_stage_fruit_set.png',
        TreeStageIds.fruitFill:
            'assets/seeds/mango/mango_stage_fruit_fill.png',
        TreeStageIds.harvestMaturity:
            'assets/seeds/mango/mango_stage_harvest_maturity.png',
        TreeStageIds.postHarvest:
            'assets/seeds/mango/mango_stage_post_harvest.png',
        TreeStageIds.unknown:
            'assets/seeds/mango/mango_stage_unknown.png',
      };

      for (final entry in expectedAssets.entries) {
        final asset = mangoTreeStageImageOrNeutral(entry.key);
        expect(asset, entry.value, reason: entry.key);
      }
    });
  });

  group('Copy de etapas del mango (presentacion, sin cambiar StageIds)', () {
    test('etapas clave usan lenguaje propio de mango', () {
      expect(
        treeStageDisplayNameForCrop(kCropMangoTree, TreeStageIds.dormancy),
        'Reposo funcional / preparación',
      );
      expect(
        treeStageDisplayNameForCrop(kCropMangoTree, TreeStageIds.flowering),
        'Floración / panícula',
      );
      expect(
        treeStageDisplayNameForCrop(kCropMangoTree, TreeStageIds.fruitSet),
        'Cuajado / amarre del manguito',
      );
      expect(
        treeStageDisplayNameForCrop(kCropMangoTree, TreeStageIds.fruitFill),
        'Mango creciendo / llenando',
      );
    });

    test('fruit_fill NO dice cosecha; post_harvest NO cierra', () {
      final fill = treeStageDisplayNameForCrop(
        kCropMangoTree,
        TreeStageIds.fruitFill,
      ).toLowerCase();
      expect(fill, anyOf(contains('llenando'), contains('creciendo')));
      expect(fill, isNot(contains('cosecha')));

      expect(
        treeStageDisplayNameForCrop(kCropMangoTree, TreeStageIds.postHarvest),
        'Postcosecha / recuperación',
      );
    });

    test('el mango NO es limon ni naranjo: copy de floracion propio', () {
      // Panicula (mango) != azahar (citricos).
      expect(
        treeStageDisplayNameForCrop(kCropMangoTree, TreeStageIds.flowering),
        isNot(
          treeStageDisplayNameForCrop(
            CropCatalog.lemonTreeCropId,
            TreeStageIds.flowering,
          ),
        ),
      );
      expect(
        treeStageDisplayNameForCrop(kCropMangoTree, TreeStageIds.fruitFill),
        isNot(
          treeStageDisplayNameForCrop(
            CropCatalog.orangeTreeCropId,
            TreeStageIds.fruitFill,
          ),
        ),
      );
    });

    test('perfil general se muestra como "Mango general"', () {
      expect(treeProfileDisplayName(kMgSkip, cropId: kCropMangoTree),
          'Mango general');
    });
  });

  group('NpkCaps del mango (doc 05 §2): N=115, P=95, K=190', () {
    test('N=115, P=95, K=190 para todos los alias', () {
      for (final crop in const <String>[
        'mango_tree',
        'crop_mango_tree',
        'crop_mango',
        'mango',
        'mangos',
        'mangifera',
        'mangifera_indica',
        'arbol_mango',
        'árbol_mango',
      ]) {
        expect(NpkCaps.forCropMetric(cropKey: crop, metricKey: AgroMetricKey.n),
            115.0, reason: '$crop N');
        expect(NpkCaps.forCropMetric(cropKey: crop, metricKey: AgroMetricKey.p),
            95.0, reason: '$crop P');
        expect(NpkCaps.forCropMetric(cropKey: crop, metricKey: AgroMetricKey.k),
            190.0, reason: '$crop K');
      }
    });

    test('K del mango (190) < citricos (naranjo 200/limon 210) y > durazno (180)',
        () {
      final mangoK =
          NpkCaps.forCropMetric(cropKey: 'mango_tree', metricKey: AgroMetricKey.k);
      expect(
        mangoK,
        lessThan(NpkCaps.forCropMetric(
            cropKey: 'orange_tree', metricKey: AgroMetricKey.k)),
      );
      expect(
        mangoK,
        greaterThan(NpkCaps.forCropMetric(
            cropKey: 'peach_tree', metricKey: AgroMetricKey.k)),
      );
    });
  });

  group('StageTargets del mango (doc 05 §5.2 + §0.0.3 v1.1)', () {
    test('contrato AgroRange: sin rangos pegados en suelo/ambiente', () {
      for (final stage in <String>[
        TreeStageIds.flowering,
        TreeStageIds.fruitSet,
        TreeStageIds.fruitFill,
        TreeStageIds.dormancy,
        TreeStageIds.postHarvest,
      ]) {
        final t = resolveMangoTreeTargets(stage);
        expect(t.moistureRaw.lowMax, lessThan(t.moistureRaw.optimalMin),
            reason: stage);
        expect(t.moistureRaw.optimalMax, lessThan(t.moistureRaw.highMin),
            reason: stage);
        expect(t.soilTemp.lowMax, lessThan(t.soilTemp.optimalMin), reason: stage);
      }
    });

    test('v1.1: en reposo/induccion el N alto es riesgo (highMin bajo)', () {
      final dormancy = resolveMangoTreeTargets(TreeStageIds.dormancy);
      // Nrel v1.1 dormancy = 6/12/28/55: frontera de exceso mas baja que la de K.
      expect(dormancy.nIndex.highMin, 55);
      expect(dormancy.kIndex.highMin, greaterThan(dormancy.nIndex.highMin));
    });

    test('v1.1: en llenado el K es protagonista (banda alta)', () {
      final fill = resolveMangoTreeTargets(TreeStageIds.fruitFill);
      expect(fill.kIndex.optimalMax, 92);
      expect(fill.kIndex.highMin, 99);
      expect(fill.kIndex.optimalMin, greaterThan(fill.nIndex.optimalMin));
    });
  });

  group('Prioridades NPK por etapa (doc 05 §7)', () {
    test('en fruit_fill K domina', () {
      final p = resolveMangoTreeNutritionPriorities(TreeStageIds.fruitFill);
      expect(p.dominantNutrient, AgroMetricKey.k);
      expect(p.kPriority01, greaterThan(p.nPriority01));
    });

    test('en establecimiento P es el dominante (raiz primero)', () {
      final p =
          resolveMangoTreeNutritionPriorities(TreeStageIds.rootEstablishment);
      expect(p.dominantNutrient, AgroMetricKey.p);
    });

    test('en vegetative_growth N es el dominante', () {
      final p =
          resolveMangoTreeNutritionPriorities(TreeStageIds.vegetativeGrowth);
      expect(p.dominantNutrient, AgroMetricKey.n);
    });

    test('en fruit_set K ya manda sobre N y P (cuajado fragil)', () {
      final p = resolveMangoTreeNutritionPriorities(TreeStageIds.fruitSet);
      expect(p.dominantNutrient, AgroMetricKey.k);
    });
  });

  group('Guardas NPK del mango (EC/humedad/pH mandan antes que NPK)', () {
    NutrientInterpretationResult interpretK({
      required double ec,
      required double soilMoisturePct,
      required double ph,
      String stage = TreeStageIds.fruitFill,
    }) {
      return NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.k,
        rawPpm: 20,
        cropKey: 'mango_tree',
        stageKey: stage,
        profileId: kMg01AtaulfoManila,
        targets: resolveMangoTreeTargets(stage),
        weights: resolveMangoTreeStageWeights(stage),
        ph: ph,
        ec: ec,
        soilMoisturePct: soilMoisturePct,
      );
    }

    test('EC alta en reproduccion (>=1.8) encabeza con guarda de sales', () {
      final msg = interpretK(ec: 1.9, soilMoisturePct: 70, ph: 7.0)
          .practicalRecommendation
          .toLowerCase();
      expect(msg, anyOf(contains('salinidad'), contains('sales')));
    });

    test('humedad critica baja en llenado (<50): agua primero', () {
      final msg = interpretK(ec: 0.5, soilMoisturePct: 45, ph: 7.0)
          .practicalRecommendation
          .toLowerCase();
      expect(msg, contains('humedad'));
    });

    test('suelo saturado (>=90): raiz/drenaje, no mas fertilizante', () {
      final msg = interpretK(ec: 0.5, soilMoisturePct: 92, ph: 7.0)
          .practicalRecommendation
          .toLowerCase();
      expect(msg, anyOf(contains('saturado'), contains('drenaje')));
    });

    test('pH alto (>=7.8): advierte Fe/Zn/Mn, no N', () {
      final msg = interpretK(ec: 0.5, soilMoisturePct: 70, ph: 8.0)
          .practicalRecommendation
          .toLowerCase();
      expect(msg,
          anyOf(contains('zinc'), contains('hierro'), contains('nervadura')));
    });

    test('suelo OK: NO se dispara guarda; habla de potasio/calibre', () {
      final msg = interpretK(ec: 0.5, soilMoisturePct: 72, ph: 7.0)
          .practicalRecommendation
          .toLowerCase();
      expect(msg, contains('potasio'));
      expect(msg, isNot(contains('saturado')));
    });

    test('reposo funcional con seco moderado NO se castiga como estres', () {
      // dormancy no es etapa critica reproductiva: la humedad baja NO dispara
      // la guarda de agua (doc 05 §0.0.3, §7.4).
      final msg = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.k,
        rawPpm: 40,
        cropKey: 'mango_tree',
        stageKey: TreeStageIds.dormancy,
        profileId: kMgSkip,
        targets: resolveMangoTreeTargets(TreeStageIds.dormancy),
        weights: resolveMangoTreeStageWeights(TreeStageIds.dormancy),
        ph: 7.0,
        ec: 0.5,
        soilMoisturePct: 45,
      ).practicalRecommendation.toLowerCase();
      expect(msg, isNot(contains('estabiliza la humedad')));
    });
  });

  group('N por etapa: reposo/madurez/postcosecha (doc 05 §7, §0.0.2)', () {
    String interpretN(String stage, double rawPpm) {
      return NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: rawPpm,
        cropKey: 'mango_tree',
        stageKey: stage,
        profileId: kMg03Kent,
        targets: resolveMangoTreeTargets(stage),
        weights: resolveMangoTreeStageWeights(stage),
        ph: 7.0,
        ec: 0.5,
        soilMoisturePct: 70,
      ).practicalRecommendation.toLowerCase();
    }

    test('N alto en reposo/induccion advierte brote/floracion', () {
      final msg = interpretN(TreeStageIds.dormancy, 95);
      expect(msg, anyOf(contains('brote'), contains('inducción'),
          contains('floración')));
    });

    test('harvest_maturity: no empuja N; deja el ajuste para postcosecha', () {
      final msg = interpretN(TreeStageIds.harvestMaturity, 8);
      expect(msg, contains('postcosecha'));
    });

    test('post_harvest: recuperacion/reservas (no se apaga el arbol)', () {
      final msg = interpretN(TreeStageIds.postHarvest, 20);
      expect(msg, contains('postcosecha'));
      expect(msg, anyOf(contains('reserva'), contains('recuperación'),
          contains('hoja')));
    });
  });

  group('Rendimiento del mango (doc 03): perenne, episodico, con memoria', () {
    test('estado no productivo proyecta 0 y no cierra cultivo', () {
      final proj = resolveMangoTreeYield(
        profileId: kMgSkip,
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.plantingTransplant,
        treeCount: 300,
      );
      expect(proj.isProductive, isFalse);
      expect(proj.kgPerTree, YieldRange.zero);
    });

    test('no-floracion probable baja fuerte y agrega nota (estado valido)', () {
      final good = resolveMangoTreeYield(
        profileId: kMgSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 300,
        productionState: MangoProductionState.fullBearing,
        bloomSetStatus: MangoBloomSetStatus.goodBloomGoodSet,
      );
      final noBloom = resolveMangoTreeYield(
        profileId: kMgSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 300,
        productionState: MangoProductionState.fullBearing,
        bloomSetStatus: MangoBloomSetStatus.noFloweringLikely,
      );
      expect(noBloom.kgPerTree!.expected, lessThan(good.kgPerTree!.expected));
      expect(noBloom.notesEs.join(' ').toLowerCase(), contains('no florear'));
    });

    test('alta densidad capea kg/arbol (no multiplica como arbol amplio)', () {
      final proj = resolveMangoTreeYield(
        profileId: kMg04Keitt,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 1111, // 800-1250 => cap 50 kg/arbol
        productionState: MangoProductionState.fullBearing,
        managementLevel: MangoManagementLevel.high,
      );
      expect(proj.kgPerTree!.expected, lessThanOrEqualTo(50.0));
    });

    test('SKIP nunca supera confianza 0.60', () {
      final proj = resolveMangoTreeYield(
        profileId: kMgSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 300,
        productionState: MangoProductionState.fullBearing,
        cropLoadStatus: MangoCropLoadStatus.balanced,
        managementLevel: MangoManagementLevel.high,
      );
      expect(proj.confidence01, lessThanOrEqualTo(0.60));
    });

    test('alias previo de perfil conserva historial (no cae a SKIP)', () {
      final proj = resolveMangoTreeYield(
        profileId: 'mg_01_ataulfo',
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 300,
        productionState: MangoProductionState.fullBearing,
      );
      expect(proj.profileId, kMg01AtaulfoManila);
    });

    test('memoria de estres severa (antracnosis en flor) baja el rendimiento', () {
      final base = resolveMangoTreeYield(
        profileId: kMgSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 300,
        productionState: MangoProductionState.fullBearing,
      );
      final stressed = resolveMangoTreeYield(
        profileId: kMgSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 300,
        productionState: MangoProductionState.fullBearing,
        stressMemory: const MangoTreeStressMemory(
          anthracnoseOrPowderyMildewBloomLoss: MangoStressSeverity.severe,
        ),
      );
      expect(stressed.kgPerTree!.expected, lessThan(base.kgPerTree!.expected));
    });

    test('post_harvest permite calculo (no cierra el cultivo)', () {
      final proj = resolveMangoTreeYield(
        profileId: kMg02TommyAtkins,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.postHarvest,
        treesPerHa: 300,
      );
      expect(proj.isProductive, isTrue);
    });

    test('el mango NO hereda kg/arbol de otro arbol (referencia propia)', () {
      expect(mangoYieldReferenceByProfile[kMg02TommyAtkins]!.fullKgPerTree.expected,
          70);
      expect(mangoYieldReferenceByProfile[kMg04Keitt]!.fullKgPerTree.high, 140);
    });
  });
}
