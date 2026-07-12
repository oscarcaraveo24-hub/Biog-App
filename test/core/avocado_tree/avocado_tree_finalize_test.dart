// test/core/avocado_tree/avocado_tree_finalize_test.dart
//
// Cierre de integracion del Aguacate: assets finales ic_avocado_* y
// assets/seeds/avocado, dormancy = reposo funcional NO arbol pelon (es
// siempreverde), copy propio de etapas (fruit_fill != cosecha; el aguacate
// madura DESPUES del corte; el aguacate NO es mango/citrico/manzano), NpkCaps
// (120/95/200, N como default pero P>default y K=naranjo), K protagonista en
// fruit_fill pero NO al maximo en floracion (primero cuaja), prioridades por
// etapa, guardas NPK (raiz/EC/humedad/pH mandan; muy sensible a sales; reposo
// funcional NO se castiga por seco), N tardio (no N en madurez; postcosecha =
// reservas), rendimiento (floracion fragil, alternancia, cap por densidad) y
// migracion AG.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_assets.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_catalog.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_universal_profile.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_yield_reference.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Catalogo y registro del aguacate', () {
    test('crop_avocado_tree resuelve a un arbol propio (no mango/citrico)', () {
      expect(CropRegistry.byKeyName('crop_avocado_tree')?.cropKey,
          CropKey.avocadoTree);
      expect(CropRegistry.byKeyName('aguacate')?.cropKey, CropKey.avocadoTree);
      expect(CropRegistry.byKeyName('avocado')?.cropKey, CropKey.avocadoTree);
      expect(CropRegistry.byKeyName('palta')?.cropKey, CropKey.avocadoTree);
      expect(CropRegistry.byKeyName('arbol de aguacate')?.cropKey,
          CropKey.avocadoTree);
      expect(CropRegistry.byKeyName('persea_americana')?.cropKey,
          CropKey.avocadoTree);
    });

    test('canonicalCropKey mapea alias a crop_avocado_tree', () {
      for (final alias in const <String>[
        'aguacate',
        'aguacates',
        'avocado',
        'avocado_tree',
        'crop_avocado',
        'palta',
        'palto',
        'persea_americana',
        'arbol_aguacate',
        'arbol de aguacate',
        'árbol de aguacate',
      ]) {
        expect(CropCatalog.canonicalCropKey(alias),
            CropCatalog.avocadoTreeCropId, reason: alias);
      }
    });

    test('el catalogo expone Aguacate como cultivo habilitado de arbol', () {
      final crop = CropCatalog.cropById(CropCatalog.avocadoTreeCropId);
      expect(crop, isNotNull);
      expect(crop!.enabled, isTrue);
      expect(crop.categoryId, CropCatalog.treeCategoryId);
      expect(crop.defaultProfileId, kAgSkip);
      expect(crop.label, 'Aguacate');
    });

    test('perfiles AG: skip general + 6 variedades', () {
      final ids = avocadoTreeProfileEntries.map((e) => e.id).toSet();
      expect(ids, containsAll(<String>{
        kAgSkip,
        kAg01Hass,
        kAg02MendezCarmen,
        kAg03CriolloMexicano,
        kAg04FuertePielVerde,
        kAg05AntillanoTropical,
        kAg06TardioLambReed,
      }));
      expect(ids.length, 7);
    });
  });

  group('Assets finales del aguacate', () {
    test('icono general y perfiles AG resuelven un PNG existente', () {
      expect(AvocadoTreeAssets.cropIcon, AvocadoTreeAssets.iconTree);
      expect(AvocadoTreeAssets.genericTreeFallback,
          'assets/icons/wizard/ic_avocado_tree.png');
      expect(avocadoTreeProfileIcon(kAgSkip), AvocadoTreeAssets.cropIcon);
      expect(avocadoTreeProfileIcon(kAg01Hass),
          'assets/icons/wizard/ic_avocado_hass.png');
      expect(avocadoTreeProfileIcon(kAg02MendezCarmen),
          'assets/icons/wizard/ic_avocado_mendez_carmen.png');
      expect(avocadoTreeProfileIcon(kAg03CriolloMexicano),
          'assets/icons/wizard/ic_avocado_criollo_mexicano.png');
      expect(avocadoTreeProfileIcon(kAg04FuertePielVerde),
          'assets/icons/wizard/ic_avocado_fuerte_piel_verde.png');
      expect(avocadoTreeProfileIcon(kAg05AntillanoTropical),
          'assets/icons/wizard/ic_avocado_antillano_tropical.png');
      expect(avocadoTreeProfileIcon(kAg06TardioLambReed),
          'assets/icons/wizard/ic_avocado_tardio_lamb_reed.png');
    });

    test('dormancy NO usa arbol pelon: aguacate siempreverde (reposo funcional)',
        () {
      // Regla aguacate (doc 01 §0.6): reposo funcional NO es arbol pelon; es
      // siempreverde.
      final asset = avocadoTreeStageImageOrNeutral(TreeStageIds.dormancy);
      expect(asset, isNot(contains('leafless')));
      expect(asset, 'assets/seeds/avocado/avocado_stage_dormancy.png');
    });

    test('toda etapa devuelve un PNG final no nulo', () {
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
        final asset = avocadoTreeStageImageOrNeutral(stage);
        expect(asset, startsWith('assets/seeds/avocado/avocado_stage_'),
            reason: stage);
        expect(asset, endsWith('.png'), reason: stage);
      }
    });
  });

  group('Copy de etapas del aguacate (presentacion, sin cambiar StageIds)', () {
    test('etapas clave usan lenguaje propio de aguacate', () {
      expect(
        treeStageDisplayNameForCrop(kCropAvocadoTree, TreeStageIds.dormancy),
        'Reposo funcional / preparación',
      );
      expect(
        treeStageDisplayNameForCrop(kCropAvocadoTree, TreeStageIds.fruitSet),
        'Cuajado / amarre del aguacatito',
      );
      expect(
        treeStageDisplayNameForCrop(kCropAvocadoTree, TreeStageIds.fruitFill),
        'Aguacate creciendo / llenando',
      );
    });

    test('fruit_fill NO dice cosecha; post_harvest NO cierra', () {
      final fill = treeStageDisplayNameForCrop(
        kCropAvocadoTree,
        TreeStageIds.fruitFill,
      ).toLowerCase();
      expect(fill, anyOf(contains('llenando'), contains('creciendo')));
      expect(fill, isNot(contains('cosecha')));

      expect(
        treeStageDisplayNameForCrop(kCropAvocadoTree, TreeStageIds.postHarvest),
        'Postcosecha / recuperación',
      );
    });

    test('el aguacate NO es mango: copy de cuajado propio (aguacatito)', () {
      expect(
        treeStageDisplayNameForCrop(kCropAvocadoTree, TreeStageIds.fruitSet),
        isNot(
          treeStageDisplayNameForCrop(
            CropCatalog.mangoTreeCropId,
            TreeStageIds.fruitSet,
          ),
        ),
      );
    });

    test('perfil general se muestra como "Aguacate general"', () {
      expect(treeProfileDisplayName(kAgSkip, cropId: kCropAvocadoTree),
          'Aguacate general');
    });
  });

  group('NpkCaps del aguacate (doc 05 §2): N=120, P=95, K=200', () {
    test('N=120, P=95, K=200 para todos los alias', () {
      for (final crop in const <String>[
        'avocado_tree',
        'crop_avocado_tree',
        'crop_avocado',
        'avocado',
        'aguacate',
        'palta',
        'palto',
        'persea_americana',
        'arbol_aguacate',
        'árbol_aguacate',
      ]) {
        expect(NpkCaps.forCropMetric(cropKey: crop, metricKey: AgroMetricKey.n),
            120.0, reason: '$crop N');
        expect(NpkCaps.forCropMetric(cropKey: crop, metricKey: AgroMetricKey.p),
            95.0, reason: '$crop P');
        expect(NpkCaps.forCropMetric(cropKey: crop, metricKey: AgroMetricKey.k),
            200.0, reason: '$crop K');
      }
    });

    test('K del aguacate (200) = naranjo, < limon (210) y > durazno (180)', () {
      final avoK = NpkCaps.forCropMetric(
          cropKey: 'avocado_tree', metricKey: AgroMetricKey.k);
      expect(avoK,
          NpkCaps.forCropMetric(cropKey: 'orange_tree', metricKey: AgroMetricKey.k));
      expect(avoK,
          lessThan(NpkCaps.forCropMetric(cropKey: 'lemon_tree', metricKey: AgroMetricKey.k)));
      expect(avoK,
          greaterThan(NpkCaps.forCropMetric(cropKey: 'peach_tree', metricKey: AgroMetricKey.k)));
    });
  });

  group('StageTargets del aguacate (doc 05 §5 + §0.0.3 v1.1)', () {
    test('contrato AgroRange: sin rangos pegados en suelo/ambiente', () {
      for (final stage in <String>[
        TreeStageIds.flowering,
        TreeStageIds.fruitSet,
        TreeStageIds.fruitFill,
        TreeStageIds.dormancy,
        TreeStageIds.postHarvest,
      ]) {
        final t = resolveAvocadoTreeTargets(stage);
        expect(t.moistureRaw.lowMax, lessThan(t.moistureRaw.optimalMin),
            reason: stage);
        expect(t.moistureRaw.optimalMax, lessThan(t.moistureRaw.highMin),
            reason: stage);
        expect(t.soilTemp.lowMax, lessThan(t.soilTemp.optimalMin), reason: stage);
      }
    });

    test('v1.1: en reposo/induccion el N alto es riesgo (highMin bajo)', () {
      final dormancy = resolveAvocadoTreeTargets(TreeStageIds.dormancy);
      // Nrel v1 dormancy = 5/12/28/55: frontera de exceso mas baja que la de K.
      expect(dormancy.nIndex.highMin, 55);
      expect(dormancy.kIndex.highMin, greaterThan(dormancy.nIndex.highMin));
    });

    test('v1.1: en llenado el K es protagonista (banda alta)', () {
      final fill = resolveAvocadoTreeTargets(TreeStageIds.fruitFill);
      expect(fill.kIndex.optimalMax, 94);
      expect(fill.kIndex.highMin, 99);
      expect(fill.kIndex.optimalMin, greaterThan(fill.nIndex.optimalMin));
    });

    test('v1.1: en floracion el K NO va al maximo (primero cuaja)', () {
      final flowering = resolveAvocadoTreeTargets(TreeStageIds.flowering);
      final fill = resolveAvocadoTreeTargets(TreeStageIds.fruitFill);
      // Krel floracion 24/45/68/88 < Krel llenado 45/70/94/99.
      expect(flowering.kIndex.optimalMax, lessThan(fill.kIndex.optimalMax));
    });
  });

  group('Prioridades NPK por etapa (doc 05 §7)', () {
    test('en fruit_fill K domina', () {
      final p = resolveAvocadoTreeNutritionPriorities(TreeStageIds.fruitFill);
      expect(p.dominantNutrient, AgroMetricKey.k);
      expect(p.kPriority01, greaterThan(p.nPriority01));
    });

    test('en establecimiento P es el dominante (raiz primero)', () {
      final p =
          resolveAvocadoTreeNutritionPriorities(TreeStageIds.rootEstablishment);
      expect(p.dominantNutrient, AgroMetricKey.p);
    });

    test('en vegetative_growth N es el dominante', () {
      final p =
          resolveAvocadoTreeNutritionPriorities(TreeStageIds.vegetativeGrowth);
      expect(p.dominantNutrient, AgroMetricKey.n);
    });

    test('en post_harvest N domina (recuperacion de reservas)', () {
      final p =
          resolveAvocadoTreeNutritionPriorities(TreeStageIds.postHarvest);
      expect(p.dominantNutrient, AgroMetricKey.n);
    });

    test('K en floracion < K en cuajado/llenado (primero cuaja)', () {
      final flowering =
          resolveAvocadoTreeNutritionPriorities(TreeStageIds.flowering);
      final fruitSet =
          resolveAvocadoTreeNutritionPriorities(TreeStageIds.fruitSet);
      final fruitFill =
          resolveAvocadoTreeNutritionPriorities(TreeStageIds.fruitFill);
      expect(flowering.kPriority01, lessThan(fruitSet.kPriority01));
      expect(flowering.kPriority01, lessThan(fruitFill.kPriority01));
    });
  });

  group('Guardas NPK del aguacate (raiz/EC/humedad/pH mandan antes que NPK)', () {
    NutrientInterpretationResult interpretK({
      required double ec,
      required double soilMoisturePct,
      required double ph,
      String stage = TreeStageIds.fruitFill,
    }) {
      return NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.k,
        rawPpm: 20,
        cropKey: 'avocado_tree',
        stageKey: stage,
        profileId: kAg01Hass,
        targets: resolveAvocadoTreeTargets(stage),
        weights: resolveAvocadoTreeStageWeights(stage),
        ph: ph,
        ec: ec,
        soilMoisturePct: soilMoisturePct,
      );
    }

    test('EC alta en reproduccion (>=1.6) encabeza con guarda de sales', () {
      final msg = interpretK(ec: 1.7, soilMoisturePct: 70, ph: 7.0)
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
      expect(msg, anyOf(contains('saturado'), contains('drenaje'),
          contains('raíz')));
    });

    test('pH alto (>=7.6): advierte Fe/Zn/Mn, no N', () {
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
      final msg = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.k,
        rawPpm: 40,
        cropKey: 'avocado_tree',
        stageKey: TreeStageIds.dormancy,
        profileId: kAgSkip,
        targets: resolveAvocadoTreeTargets(TreeStageIds.dormancy),
        weights: resolveAvocadoTreeStageWeights(TreeStageIds.dormancy),
        ph: 7.0,
        ec: 0.5,
        soilMoisturePct: 45,
      ).practicalRecommendation.toLowerCase();
      expect(msg, isNot(contains('estabiliza la humedad')));
    });
  });

  group('N por etapa: reposo/madurez/postcosecha (doc 05 §7, §0.0.8)', () {
    String interpretN(String stage, double rawPpm) {
      return NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: rawPpm,
        cropKey: 'avocado_tree',
        stageKey: stage,
        profileId: kAg01Hass,
        targets: resolveAvocadoTreeTargets(stage),
        weights: resolveAvocadoTreeStageWeights(stage),
        ph: 7.0,
        ec: 0.5,
        soilMoisturePct: 70,
      ).practicalRecommendation.toLowerCase();
    }

    test('N alto en reposo/induccion advierte brote/floracion', () {
      final msg = interpretN(TreeStageIds.dormancy, 110);
      expect(msg, anyOf(contains('brote'), contains('floración')));
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

  group('Rendimiento del aguacate (doc 03): fragil, con alternancia/memoria', () {
    test('estado no productivo proyecta 0 y no cierra cultivo', () {
      final proj = resolveAvocadoTreeYield(
        profileId: kAgSkip,
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.plantingTransplant,
        treeCount: 300,
      );
      expect(proj.isProductive, isFalse);
      expect(proj.kgPerTree, YieldRange.zero);
    });

    test('no-floracion probable baja fuerte y agrega nota (flor no es cosecha)',
        () {
      final good = resolveAvocadoTreeYield(
        profileId: kAgSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 300,
        productionState: AvocadoProductionState.fullBearing,
        bloomSetStatus: AvocadoBloomSetStatus.goodBloomGoodSet,
      );
      final noBloom = resolveAvocadoTreeYield(
        profileId: kAgSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 300,
        productionState: AvocadoProductionState.fullBearing,
        bloomSetStatus: AvocadoBloomSetStatus.noFloweringLikely,
      );
      expect(noBloom.kgPerTree!.expected, lessThan(good.kgPerTree!.expected));
      expect(noBloom.notesEs.join(' ').toLowerCase(),
          contains('mucha flor no significa cosecha'));
    });

    test('alta densidad capea kg/arbol (no multiplica como arbol amplio)', () {
      final proj = resolveAvocadoTreeYield(
        profileId: kAg05AntillanoTropical,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 1111, // 800-1200 => cap 36 kg/arbol
        productionState: AvocadoProductionState.fullBearing,
        managementLevel: AvocadoManagementLevel.high,
      );
      expect(proj.kgPerTree!.expected, lessThanOrEqualTo(36.0));
    });

    test('SKIP nunca supera confianza 0.60', () {
      final proj = resolveAvocadoTreeYield(
        profileId: kAgSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 300,
        productionState: AvocadoProductionState.fullBearing,
        cropLoadStatus: AvocadoCropLoadStatus.balanced,
        managementLevel: AvocadoManagementLevel.high,
      );
      expect(proj.confidence01, lessThanOrEqualTo(0.60));
    });

    test('alias previo de perfil conserva historial (no cae a SKIP)', () {
      final proj = resolveAvocadoTreeYield(
        profileId: 'hass',
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 300,
        productionState: AvocadoProductionState.fullBearing,
      );
      expect(proj.profileId, kAg01Hass);
    });

    test('raiz/Phytophthora severa baja fuerte (hard cap) el rendimiento', () {
      final base = resolveAvocadoTreeYield(
        profileId: kAgSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 300,
        productionState: AvocadoProductionState.fullBearing,
      );
      final stressed = resolveAvocadoTreeYield(
        profileId: kAgSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        treesPerHa: 300,
        productionState: AvocadoProductionState.fullBearing,
        stressMemory: const AvocadoTreeStressMemory(
          phytophthoraOrRootDecline: AvocadoStressSeverity.severe,
        ),
      );
      expect(stressed.kgPerTree!.expected, lessThan(base.kgPerTree!.expected));
      // Hard cap raiz severa <= 0.30 del potencial base.
      expect(stressed.kgPerTree!.expected,
          lessThanOrEqualTo(base.kgPerTree!.expected * 0.31));
    });

    test('post_harvest permite calculo (no cierra el cultivo)', () {
      final proj = resolveAvocadoTreeYield(
        profileId: kAg01Hass,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.postHarvest,
        treesPerHa: 300,
      );
      expect(proj.isProductive, isTrue);
    });

    test('el aguacate NO hereda kg/arbol de otro arbol (referencia propia)', () {
      expect(avocadoYieldReferenceByProfile[kAg01Hass]!.fullKgPerTree.expected,
          55);
      expect(avocadoYieldReferenceByProfile[kAg05AntillanoTropical]!
          .fullKgPerTree.high, 130);
    });
  });
}
