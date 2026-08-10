import 'dart:io';

import 'package:bio_g/bootstrap_gate.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/onboarding/onboarding_draft.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/widgets/account/wizard/wizard_crop_context_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 12);

  DeviceCropContext resolveTreeDraft({
    required String productionStatusId,
    required String stageId,
    DateTime? selectedDate,
    bool useFlexibleDate = false,
    String profileId = CropCatalog.appleTreeDefaultProfileId,
  }) {
    final draft = OnboardingDraft(
      cropCategory: CropCatalog.treeCategoryId,
      cropId: CropCatalog.appleTreeCropId,
      varietyId: profileId,
      varietyAlias: profileId,
      treeProductionStatusId: productionStatusId,
      stage: stageId,
      selectedDate: selectedDate,
      useFlexibleDate: useFlexibleDate,
    );

    return resolveOnboardingTreeDraftContext(
      deviceId: 'tree-device',
      draft: draft,
      cropId: CropCatalog.appleTreeCropId,
      stage: stageId,
      now: now,
    );
  }

  DeviceCropContext resolvePearTreeDraft({
    required String productionStatusId,
    required String stageId,
    DateTime? selectedDate,
    bool useFlexibleDate = false,
    String? profileId,
  }) {
    final draft = OnboardingDraft(
      cropCategory: CropCatalog.treeCategoryId,
      cropId: CropCatalog.pearTreeCropId,
      varietyId: profileId,
      varietyAlias: profileId,
      treeProductionStatusId: productionStatusId,
      stage: stageId,
      selectedDate: selectedDate,
      useFlexibleDate: useFlexibleDate,
    );

    return resolveOnboardingTreeDraftContext(
      deviceId: 'pear-tree-device',
      draft: draft,
      cropId: CropCatalog.pearTreeCropId,
      stage: stageId,
      now: now,
    );
  }

  void expectActiveTreeContext(DeviceCropContext context) {
    expect(context.cropCategoryId, CropCatalog.treeCategoryId);
    expect(context.cropId, CropCatalog.appleTreeCropId);
    expect(context.lifecycleStatus, CropLifecycleStatus.planted);
    expect(context.lifecycleStatus, isNot(CropLifecycleStatus.fallow));

    final seed = SeedInstall.fromDeviceCropContext(context);
    expect(seed.status, SowingStatus.planted);
    expect(seed.status, isNot(SowingStatus.skip));
  }

  void expectActivePearTreeContext(DeviceCropContext context) {
    expect(context.cropCategoryId, CropCatalog.treeCategoryId);
    expect(context.cropId, CropCatalog.pearTreeCropId);
    expect(context.lifecycleStatus, CropLifecycleStatus.planted);
    expect(context.lifecycleStatus, isNot(CropLifecycleStatus.fallow));

    final seed = SeedInstall.fromDeviceCropContext(context);
    expect(seed.cropKey, CropCatalog.pearTreeCropId);
    expect(seed.status, SowingStatus.planted);
    expect(seed.status, isNot(SowingStatus.skip));
  }

  group('onboarding manzano -> contexto perenne canonico', () {
    test('ya produce + floracion guarda productive_season/flowering', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        stageId: TreeStageIds.flowering,
        selectedDate: now.subtract(const Duration(days: 5)),
      );

      expect(context.perennialStateId, TreeStateIds.productiveSeason);
      expect(context.phenologyStageId, TreeStageIds.flowering);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.stageStart);
      expectActiveTreeContext(context);
    });

    test('ya produce + fruto madurando sigue activo', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        stageId: TreeStageIds.harvestMaturity,
        selectedDate: now.subtract(const Duration(days: 14)),
      );

      expect(context.perennialStateId, TreeStateIds.productiveSeason);
      expect(context.phenologyStageId, TreeStageIds.harvestMaturity);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.stageStart);
      expectActiveTreeContext(context);
    });

    test('ya produce + despues de cosecha sigue activo', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        stageId: TreeStageIds.postHarvest,
        selectedDate: now.subtract(const Duration(days: 30)),
      );

      expect(context.perennialStateId, TreeStateIds.established);
      expect(context.phenologyStageId, TreeStageIds.postHarvest);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.stageStart);
      expectActiveTreeContext(context);
    });

    test('ya produce + reposo sigue activo', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        stageId: TreeStageIds.dormancy,
        selectedDate: now.subtract(const Duration(days: 30)),
      );

      expect(context.perennialStateId, TreeStateIds.established);
      expect(context.phenologyStageId, TreeStageIds.dormancy);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.stageStart);
      expectActiveTreeContext(context);
    });

    test('todavia no produce + solo creciendo + 1 ano usa ancla planting', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        stageId: TreeStageIds.juvenileVegetative,
        selectedDate: now.subtract(const Duration(days: 365)),
      );

      expect(context.perennialStateId, TreeStateIds.juvenileNonProductive);
      expect(context.phenologyStageId, TreeStageIds.juvenileVegetative);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
      expect(
        context.perennialAnchorDate,
        now.subtract(const Duration(days: 365)),
      );
      expectActiveTreeContext(context);
    });

    test('todavia no produce + plantado hace 13 dias usa trasplante', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        stageId: TreeStageIds.juvenileVegetative,
        selectedDate: now.subtract(const Duration(days: 13)),
      );

      expect(context.perennialStateId, TreeStateIds.newlyPlanted);
      expect(context.phenologyStageId, TreeStageIds.plantingTransplant);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
      expectActiveTreeContext(context);
    });

    test('todavia no produce + plantado hace 15 dias usa agarrando raiz', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        stageId: TreeStageIds.juvenileVegetative,
        selectedDate: now.subtract(const Duration(days: 15)),
      );

      expect(context.perennialStateId, TreeStateIds.newlyPlanted);
      expect(context.phenologyStageId, TreeStageIds.rootEstablishment);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
      expectActiveTreeContext(context);
    });

    test('todavia no produce + solo creciendo + no recuerda fecha es juvenil', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        stageId: TreeStageIds.juvenileVegetative,
        useFlexibleDate: true,
      );

      expect(context.perennialStateId, TreeStateIds.juvenileNonProductive);
      expect(context.phenologyStageId, TreeStageIds.juvenileVegetative);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
      expect(context.perennialAnchorDate, isNull);
      expect(context.perennialStateId, isNot(TreeStateIds.newlyPlanted));
      expect(context.phenologyStageId, isNot(TreeStageIds.rootEstablishment));
      expectActiveTreeContext(context);
    });

    test('todavia no produce + tiene flor protege primera floracion', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        stageId: TreeStageIds.flowering,
        selectedDate: now.subtract(const Duration(days: 5)),
      );

      expect(context.perennialStateId, TreeStateIds.productiveSeason);
      expect(context.phenologyStageId, TreeStageIds.flowering);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.stageStart);
      expectActiveTreeContext(context);
    });

    test('todavia no produce + frutito chiquito protege primer cuajado', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        stageId: TreeStageIds.fruitSet,
        selectedDate: now.subtract(const Duration(days: 5)),
      );

      expect(context.perennialStateId, TreeStateIds.productiveSeason);
      expect(context.phenologyStageId, TreeStageIds.fruitSet);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.stageStart);
      expectActiveTreeContext(context);
    });

    test('no estoy seguro guarda perfil general seguro', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.unknown,
        stageId: TreeStageIds.unknown,
        useFlexibleDate: true,
      );

      expect(context.profileId, CropCatalog.appleTreeDefaultProfileId);
      expect(context.perennialStateId, TreeStateIds.unknown);
      expect(context.phenologyStageId, TreeStageIds.unknown);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.unknown);
      expect(context.perennialAnchorDate, isNull);
      expectActiveTreeContext(context);
    });

    test('AP-SKIP es perfil general activo, no SeedInstall.skip', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        stageId: TreeStageIds.flowering,
        selectedDate: now.subtract(const Duration(days: 5)),
      );

      expect(context.profileId, CropCatalog.appleTreeDefaultProfileId);
      expect(context.profileId, 'ap_skip');
      expectActiveTreeContext(context);
    });

    test('manzano, pera y limon estan habilitados', () {
      final treeCrops = CropCatalog.cropsByCategory(
        CropCatalog.treeCategoryId,
        enabledOnly: true,
      );

      expect(
        treeCrops.map((crop) => crop.cropId),
        containsAll([CropCatalog.appleTreeCropId, CropCatalog.pearTreeCropId]),
      );
      // El limón se habilitó a propósito (séptimo árbol, segundo cítrico) y
      // tiene motor, catálogo y pruebas propias. Esperar que NO se active era
      // un gate de "todavía no lo enviamos" que caducó. La aserción nueva es
      // más fuerte: falla si se deshabilita Y si el resolutor mezclara cultivos.
      expect(contextOrNullForLemon()?.cropId, CropCatalog.lemonTreeCropId);
    });
  });

  group('onboarding pera -> contexto perenne canonico', () {
    test('PR-03 + llenado de fruto guarda crop/profile de pera', () {
      final context = resolvePearTreeDraft(
        profileId: kPr03Bosc,
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        stageId: TreeStageIds.fruitFill,
        selectedDate: now.subtract(const Duration(days: 7)),
      );

      expect(context.cropId, CropCatalog.pearTreeCropId);
      expect(context.profileId, kPr03Bosc);
      expect(context.profileId, isNot(CropCatalog.appleTreeDefaultProfileId));
      expect(context.perennialStateId, TreeStateIds.productiveSeason);
      expect(context.phenologyStageId, TreeStageIds.fruitFill);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.stageStart);
      expect(context.sowingDate, isNull);
      expectActivePearTreeContext(context);
    });

    test('sin perfil usa PR-SKIP activo, nunca AP-SKIP ni fallow', () {
      final context = resolvePearTreeDraft(
        productionStatusId: TreeProductionStatusIds.unknown,
        stageId: TreeStageIds.unknown,
        useFlexibleDate: true,
      );

      expect(context.profileId, kPrSkip);
      expect(context.profileId, isNot(CropCatalog.appleTreeDefaultProfileId));
      expect(context.perennialStateId, TreeStateIds.unknown);
      expect(context.phenologyStageId, TreeStageIds.unknown);
      expectActivePearTreeContext(context);
    });

    test('post_harvest sigue activo y no cierra el peral', () {
      final context = resolvePearTreeDraft(
        profileId: kPr01BartlettWilliams,
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        stageId: TreeStageIds.postHarvest,
        selectedDate: now.subtract(const Duration(days: 18)),
      );

      expect(context.perennialStateId, TreeStateIds.established);
      expect(context.phenologyStageId, TreeStageIds.postHarvest);
      expect(context.lifecycleStatus, CropLifecycleStatus.planted);
      expectActivePearTreeContext(context);
    });
  });

  // #4 / #1 / #12 — Dos ejes temporales distintos: sowingDate = memoria/edad
  // (fecha de plantación con su precisión), perennialAnchorDate = evento de
  // etapa. Deben poder coexistir y persistirse por separado.
  group('ejes temporales: plantación (sowingDate) vs evento (anchor)', () {
    test('rama plantación persiste sowingDate y anchor por separado', () {
      final plantingDate = now.subtract(const Duration(days: 365));
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        stageId: TreeStageIds.juvenileVegetative,
        selectedDate: plantingDate,
      );

      // Eje memoria/edad.
      expect(context.sowingDate, plantingDate);
      // Eje evento de etapa (en la rama plantación coincide con la fecha).
      expect(context.perennialAnchorDate, plantingDate);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
      // Precisión: el usuario dio una fecha → exacta (reusa sowing_date_confidence).
      expect(context.sowingDateConfidence, DateConfidence.exact);
    });

    test('recién plantado (-13d) también guarda la fecha como sowingDate', () {
      final plantingDate = now.subtract(const Duration(days: 13));
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        stageId: TreeStageIds.juvenileVegetative,
        selectedDate: plantingDate,
      );

      expect(context.perennialStateId, TreeStateIds.newlyPlanted);
      expect(context.sowingDate, plantingDate);
      expect(context.sowingDateConfidence, DateConfidence.exact);
    });

    test('no recuerda fecha → sin sowingDate y precisión unknown', () {
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        stageId: TreeStageIds.juvenileVegetative,
        useFlexibleDate: true,
      );

      expect(context.sowingDate, isNull);
      expect(context.perennialAnchorDate, isNull);
      expect(context.sowingDateConfidence, DateConfidence.unknown);
    });

    test('etapa productiva: la fecha es evento, no plantación (sowingDate null)', () {
      final eventDate = now.subtract(const Duration(days: 5));
      final context = resolveTreeDraft(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        stageId: TreeStageIds.flowering,
        selectedDate: eventDate,
      );

      // Sin memoria previa de plantación, el eje edad queda vacío; el evento se
      // guarda en el anclaje perenne.
      expect(context.sowingDate, isNull);
      expect(context.perennialAnchorDate, eventDate);
      expect(context.perennialAnchorTypeId, TreeAnchorTypeIds.stageStart);
    });
  });

  // #14 — Transición "no produce" → "ya produce": no destructiva. La memoria de
  // plantación (sowingDate/edad) debe sobrevivir; solo cambia estado/etapa/ancla.
  group('transición no-produce → produce conserva memoria', () {
    test('sowingDate de plantación sobrevive al pasar a producción', () {
      final plantingDate = now.subtract(const Duration(days: 800));

      // Estado previo: juvenil que aún no produce, con su fecha de plantación.
      final previous = resolveOnboardingTreeDraftContext(
        deviceId: 'tree-device',
        draft: OnboardingDraft(
          cropCategory: CropCatalog.treeCategoryId,
          cropId: CropCatalog.appleTreeCropId,
          varietyId: CropCatalog.appleTreeDefaultProfileId,
          varietyAlias: CropCatalog.appleTreeDefaultProfileId,
          treeProductionStatusId: TreeProductionStatusIds.nonProductive,
          stage: TreeStageIds.juvenileVegetative,
          selectedDate: plantingDate,
        ),
        cropId: CropCatalog.appleTreeCropId,
        stage: TreeStageIds.juvenileVegetative,
        now: now,
      );

      expect(previous.perennialStateId, TreeStateIds.juvenileNonProductive);
      expect(previous.sowingDate, plantingDate);

      // Transición: ahora el árbol ya muestra floración (primera producción).
      final transitioned = resolveOnboardingTreeDraftContext(
        deviceId: 'tree-device',
        draft: OnboardingDraft(
          cropCategory: CropCatalog.treeCategoryId,
          cropId: CropCatalog.appleTreeCropId,
          varietyId: CropCatalog.appleTreeDefaultProfileId,
          varietyAlias: CropCatalog.appleTreeDefaultProfileId,
          treeProductionStatusId: TreeProductionStatusIds.productiveOrProduced,
          stage: TreeStageIds.flowering,
          selectedDate: now.subtract(const Duration(days: 3)),
        ),
        cropId: CropCatalog.appleTreeCropId,
        stage: TreeStageIds.flowering,
        previous: previous,
        now: now,
      );

      // Estado/etapa avanzan...
      expect(transitioned.perennialStateId, TreeStateIds.productiveSeason);
      expect(transitioned.phenologyStageId, TreeStageIds.flowering);
      // ...pero la memoria de plantación (edad) NO se pierde.
      expect(transitioned.sowingDate, plantingDate);
      // El evento de etapa queda trazado por el anclaje perenne.
      expect(
        transitioned.perennialAnchorDate,
        now.subtract(const Duration(days: 3)),
      );
      expect(transitioned.perennialAnchorTypeId, TreeAnchorTypeIds.stageStart);
    });
  });

  group('regresion anual de onboarding', () {
    const resolver = WizardCropContextResolver();

    test('anual planted conserva sowingDate y no campos perennes', () {
      final sowingDate = DateTime(2026, 1, 15);
      final context = resolver.resolve(
        deviceId: 'annual-device',
        cropCategoryId: CropCatalog.grainCategoryId,
        cropId: CropCatalog.maizeCropId,
        lifecycleStatus: CropLifecycleStatus.planted,
        dateConfidence: DateConfidence.exact,
        now: now,
        varietyAlias: 'generic',
        selectedDate: sowingDate,
      );

      expect(context.lifecycleStatus, CropLifecycleStatus.planted);
      expect(context.sowingDate, sowingDate);
      expect(context.plannedSowingDate, isNull);
      expect(context.perennialStateId, isNull);
      expect(context.phenologyStageId, isNull);
      expect(context.perennialAnchorDate, isNull);
      expect(context.perennialAnchorTypeId, isNull);
    });

    test('anual planned conserva plannedSowingDate', () {
      final plannedDate = DateTime(2026, 2, 1);
      final context = resolver.resolve(
        deviceId: 'annual-device',
        cropCategoryId: CropCatalog.grainCategoryId,
        cropId: CropCatalog.maizeCropId,
        lifecycleStatus: CropLifecycleStatus.planned,
        dateConfidence: DateConfidence.exact,
        now: now,
        varietyAlias: 'generic',
        selectedDate: plannedDate,
      );

      expect(context.lifecycleStatus, CropLifecycleStatus.planned);
      expect(context.sowingDate, isNull);
      expect(context.plannedSowingDate, plannedDate);
    });

    test('anual fallow sigue siendo fallow/skip legacy', () {
      final context = resolver.resolve(
        deviceId: 'annual-device',
        cropCategoryId: CropCatalog.grainCategoryId,
        cropId: CropCatalog.maizeCropId,
        lifecycleStatus: CropLifecycleStatus.fallow,
        dateConfidence: DateConfidence.unknown,
        now: now,
      );

      expect(context.lifecycleStatus, CropLifecycleStatus.fallow);
      expect(context.sowingDate, isNull);
      expect(
        SeedInstall.fromDeviceCropContext(context).status,
        SowingStatus.skip,
      );
    });
  });

  group('IDs legacy de arbol no son ruta principal', () {
    test('el resolver de onboarding no acepta bandas viejas como etapas', () {
      for (final legacyStage in <String>[
        'growing_tree',
        'near_production',
        'productive',
        'dormant',
      ]) {
        final selection = resolveOnboardingTreeSelection(
          productionStatusId: TreeProductionStatusIds.productiveOrProduced,
          phenologyStageId: legacyStage,
          plantingDate: now,
          now: now,
        );

        expect(selection.perennialStateId, TreeStateIds.unknown);
        expect(selection.phenologyStageId, TreeStageIds.unknown);
        expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.unknown);
      }
    });

    test('onboarding activo y bootstrap no contienen IDs viejos', () {
      final activeFiles = <String>[
        'lib/screens/onboarding/onboarding_wizard_screen.dart',
        'lib/bootstrap_gate.dart',
      ];
      for (final path in activeFiles) {
        final contents = File(path).readAsStringSync();
        expect(contents, isNot(contains("'growing_tree'")));
        expect(contents, isNot(contains("'near_production'")));
        expect(contents, isNot(contains("'productive'")));
        expect(contents, isNot(contains("'dormant'")));
        expect(contents, isNot(contains('_onboardingTreeStageMapping')));
      }
    });
  });
}

DeviceCropContext? contextOrNullForLemon() {
  final crop = CropCatalog.cropById('lemon_tree');
  if (crop == null || !crop.enabled) return null;

  return resolveOnboardingTreeDraftContext(
    deviceId: 'lemon-device',
    draft: const OnboardingDraft(
      cropCategory: CropCatalog.treeCategoryId,
      cropId: 'lemon_tree',
      treeProductionStatusId: TreeProductionStatusIds.unknown,
      stage: TreeStageIds.unknown,
      useFlexibleDate: true,
    ),
    cropId: 'lemon_tree',
    stage: TreeStageIds.unknown,
    now: DateTime(2026, 6, 12),
  );
}
