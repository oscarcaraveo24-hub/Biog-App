// test/core/tree_lifecycle_test.dart
//
// Validación de la base perenne (árboles). Cubre la tabla estado→etapas
// permitidas, normalizadores seguros, corrección de etapas imposibles y
// detección de cultivo de árbol. No incluye agronomía pesada del Manzano.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

/// Congela la traducción "estado de producción visible + etapa visible" →
/// (estado perenne interno, etapa fenológica, tipo de anclaje).
void _expectTreeSelection({
  required String productionStatusId,
  required String visibleStageId,
  required String stateId,
  required String stageId,
  String anchorTypeId = TreeAnchorTypeIds.stageStart,
}) {
  final selection = resolveTreeVisibleStageSelection(
    productionStatusId: productionStatusId,
    visibleStageId: visibleStageId,
  );

  expect(selection.perennialStateId, stateId);
  expect(selection.phenologyStageId, stageId);
  expect(selection.perennialAnchorTypeId, anchorTypeId);
}

void main() {
  group('isTreeCrop', () {
    test('apple_tree is a tree crop', () {
      expect(isTreeCrop(cropId: CropCatalog.appleTreeCropId), isTrue);
    });

    test('category tree marks a tree crop', () {
      expect(isTreeCrop(cropCategoryId: CropCatalog.treeCategoryId), isTrue);
    });

    test('manzano alias resolves to a tree crop', () {
      expect(isTreeCrop(cropId: 'manzano'), isTrue);
    });

    test('annual crops are NOT tree crops', () {
      expect(isTreeCrop(cropId: 'maize'), isFalse);
      expect(isTreeCrop(cropId: 'tomato'), isFalse);
      expect(isTreeCrop(cropId: 'garlic'), isFalse);
    });

    // #8: isTreeCrop ya no depende de un atajo hardcodeado al manzano. Un
    // árbol genérico (otra especie, aún sin catálogo) se reconoce por su
    // categoría, no por su cropId, de modo que la detección escala a futuros
    // frutales sin tocar este archivo.
    test('a generic non-apple tree is detected by category, not cropId', () {
      expect(
        isTreeCrop(cropId: 'cherry_tree', category: CropCategory.tree),
        isTrue,
      );
      expect(
        isTreeCrop(
          cropId: 'cherry_tree',
          cropCategoryId: CropCatalog.treeCategoryId,
        ),
        isTrue,
      );
    });

    test('an unknown crop without tree category is NOT a tree crop', () {
      expect(isTreeCrop(cropId: 'cherry_tree'), isFalse);
    });

    test('isPerennialCrop mirrors isTreeCrop', () {
      expect(isPerennialCrop(cropId: CropCatalog.appleTreeCropId), isTrue);
      expect(isPerennialCrop(cropId: 'wheat'), isFalse);
    });
  });

  group('state → production enabled', () {
    test('newly_planted and juvenile do NOT enable production', () {
      expect(isTreeProductionEnabled(TreeStateIds.newlyPlanted), isFalse);
      expect(
        isTreeProductionEnabled(TreeStateIds.juvenileNonProductive),
        isFalse,
      );
    });

    test('established and productive_season DO enable production', () {
      expect(isTreeProductionEnabled(TreeStateIds.established), isTrue);
      expect(isTreeProductionEnabled(TreeStateIds.productiveSeason), isTrue);
    });

    test('unknown is conservative (production not enabled)', () {
      expect(isTreeProductionEnabled(TreeStateIds.unknown), isFalse);
      expect(isTreeProductionEnabled(null), isFalse);
    });
  });

  group('state → allowed stages', () {
    test('newly_planted blocks reproductive stages', () {
      expect(
        isTreeStageAllowed(TreeStateIds.newlyPlanted, TreeStageIds.flowering),
        isFalse,
      );
      expect(
        isTreeStageAllowed(TreeStateIds.newlyPlanted, TreeStageIds.fruitSet),
        isFalse,
      );
      expect(
        isTreeStageAllowed(
          TreeStateIds.newlyPlanted,
          TreeStageIds.harvestMaturity,
        ),
        isFalse,
      );
    });

    test('newly_planted allows establishment stages', () {
      expect(
        isTreeStageAllowed(
          TreeStateIds.newlyPlanted,
          TreeStageIds.rootEstablishment,
        ),
        isTrue,
      );
    });

    test('juvenile_non_productive blocks harvest but allows dormancy', () {
      expect(
        isTreeStageAllowed(
          TreeStateIds.juvenileNonProductive,
          TreeStageIds.harvestMaturity,
        ),
        isFalse,
      );
      expect(
        isTreeStageAllowed(
          TreeStateIds.juvenileNonProductive,
          TreeStageIds.dormancy,
        ),
        isTrue,
      );
    });

    test('productive_season allows the full productive cycle', () {
      for (final stage in <String>[
        TreeStageIds.flowering,
        TreeStageIds.fruitSet,
        TreeStageIds.fruitFill,
        TreeStageIds.harvestMaturity,
        TreeStageIds.postHarvest,
        TreeStageIds.dormancy,
      ]) {
        expect(
          isTreeStageAllowed(TreeStateIds.productiveSeason, stage),
          isTrue,
          reason: '$stage should be allowed in productive_season',
        );
      }
    });

    test('an unknown/invalid stage id is never "allowed"', () {
      expect(
        isTreeStageAllowed(TreeStateIds.productiveSeason, 'not_a_real_stage'),
        isFalse,
      );
    });
  });

  group('UX visible del manzano -> estado perenne interno', () {
    void expectSelection({
      required String productionStatusId,
      required String visibleStageId,
      required String stateId,
      required String stageId,
      String anchorTypeId = TreeAnchorTypeIds.stageStart,
    }) {
      final selection = resolveTreeVisibleStageSelection(
        productionStatusId: productionStatusId,
        visibleStageId: visibleStageId,
      );

      expect(selection.perennialStateId, stateId);
      expect(selection.phenologyStageId, stageId);
      expect(selection.perennialAnchorTypeId, anchorTypeId);
    }

    test('Aun no produce -> recien plantado o trasplantado', () {
      expectSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        visibleStageId: TreeStageIds.plantingTransplant,
        stateId: TreeStateIds.newlyPlanted,
        stageId: TreeStageIds.plantingTransplant,
        anchorTypeId: TreeAnchorTypeIds.planting,
      );
    });

    test('Aun no produce -> se esta estableciendo', () {
      expectSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        visibleStageId: TreeStageIds.rootEstablishment,
        stateId: TreeStateIds.newlyPlanted,
        stageId: TreeStageIds.rootEstablishment,
      );
    });

    test('Aun no produce -> creciendo con hojas nuevas', () {
      expectSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        visibleStageId: TreeStageIds.juvenileVegetative,
        stateId: TreeStateIds.juvenileNonProductive,
        stageId: TreeStageIds.juvenileVegetative,
      );
    });

    test('Ya produce o ya ha producido -> floracion', () {
      expectSelection(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        visibleStageId: TreeStageIds.flowering,
        stateId: TreeStateIds.productiveSeason,
        stageId: TreeStageIds.flowering,
      );
    });

    test('Ya produce o ya ha producido -> harvest_maturity sigue activo', () {
      expectSelection(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        visibleStageId: TreeStageIds.harvestMaturity,
        stateId: TreeStateIds.productiveSeason,
        stageId: TreeStageIds.harvestMaturity,
      );
      expect(
        isTreeStageAllowed(
          TreeStateIds.productiveSeason,
          TreeStageIds.harvestMaturity,
        ),
        isTrue,
      );
    });

    test('Ya produce o ya ha producido -> despues de cosecha sigue activo', () {
      expectSelection(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        visibleStageId: TreeStageIds.postHarvest,
        stateId: TreeStateIds.established,
        stageId: TreeStageIds.postHarvest,
      );
      expect(
        isTreeStageAllowed(TreeStateIds.established, TreeStageIds.postHarvest),
        isTrue,
      );
    });

    test('No estoy seguro -> unknown sin anclaje', () {
      expectSelection(
        productionStatusId: TreeProductionStatusIds.unknown,
        visibleStageId: TreeStageIds.unknown,
        stateId: TreeStateIds.unknown,
        stageId: TreeStageIds.unknown,
        anchorTypeId: TreeAnchorTypeIds.unknown,
      );
    });
  });

  group('critical stages v1', () {
    test(
      'root_establishment, flowering, fruit_set, post_harvest are critical',
      () {
        expect(isTreeCriticalStage(TreeStageIds.rootEstablishment), isTrue);
        expect(isTreeCriticalStage(TreeStageIds.flowering), isTrue);
        expect(isTreeCriticalStage(TreeStageIds.fruitSet), isTrue);
        expect(isTreeCriticalStage(TreeStageIds.postHarvest), isTrue);
      },
    );

    test('dormancy and vegetative growth are NOT critical', () {
      expect(isTreeCriticalStage(TreeStageIds.dormancy), isFalse);
      expect(isTreeCriticalStage(TreeStageIds.vegetativeGrowth), isFalse);
    });
  });

  group('normalizers fall back safely', () {
    test('unknown / empty state normalizes to unknown', () {
      expect(normalizeTreeStateId(null), TreeStateIds.unknown);
      expect(normalizeTreeStateId(''), TreeStateIds.unknown);
      expect(normalizeTreeStateId('garbage'), TreeStateIds.unknown);
    });

    test('valid state passes through (case-insensitive)', () {
      expect(
        normalizeTreeStateId('PRODUCTIVE_SEASON'),
        TreeStateIds.productiveSeason,
      );
    });

    test('unknown / empty stage normalizes to unknown', () {
      expect(normalizeTreeStageId(null), TreeStageIds.unknown);
      expect(normalizeTreeStageId('garbage'), TreeStageIds.unknown);
    });
  });

  group('safeTreeStageForState corrects impossible stages', () {
    test('newly_planted + flowering → root_establishment', () {
      expect(
        safeTreeStageForState(
          perennialStateId: TreeStateIds.newlyPlanted,
          phenologyStageId: TreeStageIds.flowering,
        ),
        TreeStageIds.rootEstablishment,
      );
    });

    test('null stage infers a safe stage from state', () {
      expect(
        safeTreeStageForState(
          perennialStateId: TreeStateIds.newlyPlanted,
          phenologyStageId: null,
        ),
        TreeStageIds.rootEstablishment,
      );
      expect(
        safeTreeStageForState(
          perennialStateId: TreeStateIds.juvenileNonProductive,
          phenologyStageId: null,
        ),
        TreeStageIds.juvenileVegetative,
      );
      expect(
        safeTreeStageForState(
          perennialStateId: TreeStateIds.established,
          phenologyStageId: null,
        ),
        TreeStageIds.unknown,
      );
    });

    test('valid pairs are preserved', () {
      expect(
        safeTreeStageForState(
          perennialStateId: TreeStateIds.productiveSeason,
          phenologyStageId: TreeStageIds.flowering,
        ),
        TreeStageIds.flowering,
      );
    });

    test(
      'harvest_maturity is preserved (never forced to a terminal state)',
      () {
        expect(
          safeTreeStageForState(
            perennialStateId: TreeStateIds.productiveSeason,
            phenologyStageId: TreeStageIds.harvestMaturity,
          ),
          TreeStageIds.harvestMaturity,
        );
      },
    );
  });

  group('human display names', () {
    test('state labels', () {
      expect(
        treeStateDisplayName(TreeStateIds.newlyPlanted),
        'Recién plantado',
      );
      expect(
        treeStateDisplayName(TreeStateIds.productiveSeason),
        'En producción esta temporada',
      );
      expect(treeStateDisplayName(TreeStateIds.unknown), 'Estado general');
    });

    test('stage labels', () {
      expect(treeStageDisplayName(TreeStageIds.flowering), 'Floración');
      expect(
        treeStageDisplayName(TreeStageIds.harvestMaturity),
        'Maduración / cosecha',
      );
      expect(treeStageDisplayName(TreeStageIds.postHarvest), 'Post-cosecha');
      expect(treeStageDisplayName(TreeStageIds.dormancy), 'Reposo');
      expect(treeStageDisplayName(TreeStageIds.unknown), 'Etapa no definida');
    });

    test('AP-SKIP shows as a general profile, never as fallow/rest', () {
      final label = treeProfileDisplayName(
        CropCatalog.appleTreeDefaultProfileId,
      );
      expect(label, 'Perfil general');
      expect(label.toLowerCase(), isNot(contains('descanso')));
      expect(label.toLowerCase(), isNot(contains('fallow')));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // PRIORIDAD 1 — Primera floración / primer fruto.
  //
  // Ruta delicada de la Fase 3: el árbol "todavía no produce" pero AHORITA ya
  // muestra señal reproductiva. Debe entrar a producción de temporada y NO
  // volver a caer en `unknown`.
  // ───────────────────────────────────────────────────────────────────────────
  group('PRIMERA FLORACIÓN — non_productive + señal reproductiva', () {
    test('non_productive + flowering → productive_season/flowering', () {
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        visibleStageId: TreeStageIds.flowering,
        stateId: TreeStateIds.productiveSeason,
        stageId: TreeStageIds.flowering,
        anchorTypeId: TreeAnchorTypeIds.stageStart,
      );
    });

    test('non_productive + fruit_set → productive_season/fruit_set', () {
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        visibleStageId: TreeStageIds.fruitSet,
        stateId: TreeStateIds.productiveSeason,
        stageId: TreeStageIds.fruitSet,
        anchorTypeId: TreeAnchorTypeIds.stageStart,
      );
    });

    test('non_productive + fruit_fill → productive_season/fruit_fill', () {
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        visibleStageId: TreeStageIds.fruitFill,
        stateId: TreeStateIds.productiveSeason,
        stageId: TreeStageIds.fruitFill,
        anchorTypeId: TreeAnchorTypeIds.stageStart,
      );
    });

    test('las señales reproductivas NUNCA caen en unknown', () {
      for (final stage in <String>[
        TreeStageIds.flowering,
        TreeStageIds.fruitSet,
        TreeStageIds.fruitFill,
      ]) {
        final selection = resolveTreeVisibleStageSelection(
          productionStatusId: TreeProductionStatusIds.nonProductive,
          visibleStageId: stage,
        );
        expect(
          selection.perennialStateId,
          TreeStateIds.productiveSeason,
          reason: 'non_productive + $stage debe ser productive_season',
        );
        expect(selection.phenologyStageId, isNot(TreeStageIds.unknown));
        expect(selection.perennialStateId, isNot(TreeStateIds.unknown));
      }
    });

    test('la etapa reproductiva queda permitida en productive_season', () {
      for (final stage in <String>[
        TreeStageIds.flowering,
        TreeStageIds.fruitSet,
        TreeStageIds.fruitFill,
      ]) {
        expect(
          isTreeStageAllowed(TreeStateIds.productiveSeason, stage),
          isTrue,
          reason: '$stage debe ser válida en productive_season',
        );
        // safeTreeStageForState no la degrada.
        expect(
          safeTreeStageForState(
            perennialStateId: TreeStateIds.productiveSeason,
            phenologyStageId: stage,
          ),
          stage,
        );
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // PRIORIDAD 2 — Ruta no productiva vegetativa (sin señal reproductiva).
  // ───────────────────────────────────────────────────────────────────────────
  group('Ruta no productiva vegetativa', () {
    test('recién plantado → newly_planted/planting_transplant/planting', () {
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        visibleStageId: TreeStageIds.plantingTransplant,
        stateId: TreeStateIds.newlyPlanted,
        stageId: TreeStageIds.plantingTransplant,
        anchorTypeId: TreeAnchorTypeIds.planting,
      );
    });

    test('agarrando raíz → newly_planted/root_establishment', () {
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        visibleStageId: TreeStageIds.rootEstablishment,
        stateId: TreeStateIds.newlyPlanted,
        stageId: TreeStageIds.rootEstablishment,
      );
    });

    test(
      'creciendo con hojas → juvenile_non_productive/juvenile_vegetative',
      () {
        _expectTreeSelection(
          productionStatusId: TreeProductionStatusIds.nonProductive,
          visibleStageId: TreeStageIds.juvenileVegetative,
          stateId: TreeStateIds.juvenileNonProductive,
          stageId: TreeStageIds.juvenileVegetative,
        );
      },
    );

    test('sin hojas / en reposo → juvenile_non_productive/dormancy', () {
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        visibleStageId: TreeStageIds.dormancy,
        stateId: TreeStateIds.juvenileNonProductive,
        stageId: TreeStageIds.dormancy,
      );
    });

    test('etapas vegetativas NO van a productive_season', () {
      for (final stage in <String>[
        TreeStageIds.plantingTransplant,
        TreeStageIds.rootEstablishment,
        TreeStageIds.juvenileVegetative,
        TreeStageIds.dormancy,
      ]) {
        final selection = resolveTreeVisibleStageSelection(
          productionStatusId: TreeProductionStatusIds.nonProductive,
          visibleStageId: stage,
        );
        expect(
          selection.perennialStateId,
          isNot(TreeStateIds.productiveSeason),
          reason: '$stage no debe activar producción',
        );
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // PRIORIDAD 3 — Ruta productiva normal. Nada termina el árbol ni va a fallow.
  // ───────────────────────────────────────────────────────────────────────────
  group('Ruta productiva — etapas activas', () {
    test('productive_or_produced + dormancy → established/dormancy', () {
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        visibleStageId: TreeStageIds.dormancy,
        stateId: TreeStateIds.established,
        stageId: TreeStageIds.dormancy,
      );
    });

    test('productive_or_produced + budbreak → established/budbreak', () {
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        visibleStageId: TreeStageIds.budbreak,
        stateId: TreeStateIds.established,
        stageId: TreeStageIds.budbreak,
      );
    });

    test(
      'productive_or_produced + flowering → productive_season/flowering',
      () {
        _expectTreeSelection(
          productionStatusId: TreeProductionStatusIds.productiveOrProduced,
          visibleStageId: TreeStageIds.flowering,
          stateId: TreeStateIds.productiveSeason,
          stageId: TreeStageIds.flowering,
        );
      },
    );

    test(
      'productive_or_produced + fruit_set → productive_season/fruit_set',
      () {
        _expectTreeSelection(
          productionStatusId: TreeProductionStatusIds.productiveOrProduced,
          visibleStageId: TreeStageIds.fruitSet,
          stateId: TreeStateIds.productiveSeason,
          stageId: TreeStageIds.fruitSet,
        );
      },
    );

    test(
      'productive_or_produced + fruit_fill → productive_season/fruit_fill',
      () {
        _expectTreeSelection(
          productionStatusId: TreeProductionStatusIds.productiveOrProduced,
          visibleStageId: TreeStageIds.fruitFill,
          stateId: TreeStateIds.productiveSeason,
          stageId: TreeStageIds.fruitFill,
        );
      },
    );

    test('harvest_maturity → productive_season y NO termina el árbol', () {
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        visibleStageId: TreeStageIds.harvestMaturity,
        stateId: TreeStateIds.productiveSeason,
        stageId: TreeStageIds.harvestMaturity,
      );
      expect(
        isTreeStageAllowed(
          TreeStateIds.productiveSeason,
          TreeStageIds.harvestMaturity,
        ),
        isTrue,
      );
      expect(isTreeProductionEnabled(TreeStateIds.productiveSeason), isTrue);
    });

    test('post_harvest → established y sigue activo', () {
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        visibleStageId: TreeStageIds.postHarvest,
        stateId: TreeStateIds.established,
        stageId: TreeStageIds.postHarvest,
      );
      expect(
        isTreeStageAllowed(TreeStateIds.established, TreeStageIds.postHarvest),
        isTrue,
      );
      expect(isTreeProductionEnabled(TreeStateIds.established), isTrue);
    });

    test('dormancy sigue activo (no termina ni va a fallow)', () {
      expect(
        isTreeStageAllowed(TreeStateIds.established, TreeStageIds.dormancy),
        isTrue,
      );
      expect(
        isTreeStageAllowed(
          TreeStateIds.productiveSeason,
          TreeStageIds.dormancy,
        ),
        isTrue,
      );
    });

    test('ningún estado resuelto es unknown en la ruta productiva', () {
      for (final stage in <String>[
        TreeStageIds.dormancy,
        TreeStageIds.budbreak,
        TreeStageIds.vegetativeGrowth,
        TreeStageIds.flowering,
        TreeStageIds.fruitSet,
        TreeStageIds.fruitFill,
        TreeStageIds.harvestMaturity,
        TreeStageIds.postHarvest,
      ]) {
        final selection = resolveTreeVisibleStageSelection(
          productionStatusId: TreeProductionStatusIds.productiveOrProduced,
          visibleStageId: stage,
        );
        expect(selection.perennialStateId, isNot(TreeStateIds.unknown));
        expect(selection.phenologyStageId, stage);
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // PRIORIDAD 4 — Ruta unknown (perfil general). Sin anclaje, sin fallow/skip.
  // ───────────────────────────────────────────────────────────────────────────
  group('Ruta unknown — perfil general', () {
    test('production status unknown → unknown/unknown/unknown', () {
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.unknown,
        visibleStageId: TreeStageIds.unknown,
        stateId: TreeStateIds.unknown,
        stageId: TreeStageIds.unknown,
        anchorTypeId: TreeAnchorTypeIds.unknown,
      );
    });

    test('etapa desconocida con estado conocido → unknown/unknown/unknown', () {
      // Aunque el agricultor dijo "ya produce", si la etapa visible es unknown
      // se guarda perfil general sin anclaje.
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        visibleStageId: TreeStageIds.unknown,
        stateId: TreeStateIds.unknown,
        stageId: TreeStageIds.unknown,
        anchorTypeId: TreeAnchorTypeIds.unknown,
      );
      _expectTreeSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        visibleStageId: TreeStageIds.unknown,
        stateId: TreeStateIds.unknown,
        stageId: TreeStageIds.unknown,
        anchorTypeId: TreeAnchorTypeIds.unknown,
      );
    });

    test('AP-SKIP (perfil general) NO es fallow ni descanso', () {
      // El perfil general de manzano nunca debe presentarse como descanso del
      // suelo (eso es exclusivo de anuales con SeedInstall.skip).
      final label = treeProfileDisplayName(
        CropCatalog.appleTreeDefaultProfileId,
      );
      expect(label.toLowerCase(), isNot(contains('descanso')));
      expect(label.toLowerCase(), isNot(contains('skip')));
      expect(label.toLowerCase(), isNot(contains('fallow')));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // PRIORIDAD 5 — Políticas estado→etapa y degradación segura.
  // ───────────────────────────────────────────────────────────────────────────
  group('Políticas estado→etapa', () {
    test('productive_season permite todo el ciclo reproductivo', () {
      for (final stage in <String>[
        TreeStageIds.flowering,
        TreeStageIds.fruitSet,
        TreeStageIds.fruitFill,
        TreeStageIds.harvestMaturity,
      ]) {
        expect(
          isTreeStageAllowed(TreeStateIds.productiveSeason, stage),
          isTrue,
          reason: '$stage debe ser válida en productive_season',
        );
      }
    });

    test('established permite dormancy y post_harvest', () {
      expect(
        isTreeStageAllowed(TreeStateIds.established, TreeStageIds.dormancy),
        isTrue,
      );
      expect(
        isTreeStageAllowed(TreeStateIds.established, TreeStageIds.postHarvest),
        isTrue,
      );
    });

    test('etapa incompatible se degrada de forma segura (no rompe runtime)', () {
      // newly_planted no puede florear: se corrige a una etapa de su política.
      final corrected = safeTreeStageForState(
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.flowering,
      );
      expect(corrected, TreeStageIds.rootEstablishment);
      expect(isKnownTreeStageId(corrected), isTrue);
      expect(isTreeStageAllowed(TreeStateIds.newlyPlanted, corrected), isTrue);
    });

    test('un id de etapa basura nunca se reporta como permitido', () {
      expect(
        isTreeStageAllowed(TreeStateIds.productiveSeason, 'no_existe'),
        isFalse,
      );
      expect(
        safeTreeStageForState(
          perennialStateId: TreeStateIds.productiveSeason,
          phenologyStageId: 'no_existe',
        ),
        TreeStageIds.unknown,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // treeStateFromPlantingDate — antigüedad → estado perenne (rama 3A).
  // ───────────────────────────────────────────────────────────────────────────
  group('treeStateFromPlantingDate', () {
    final now = DateTime(2026, 6, 12);

    test('plantado este mes (−15d) → newly_planted', () {
      expect(
        treeStateFromPlantingDate(now.subtract(const Duration(days: 15)), now),
        TreeStateIds.newlyPlanted,
      );
    });

    test('plantado hace ~6 meses (−182d) → newly_planted', () {
      expect(
        treeStateFromPlantingDate(now.subtract(const Duration(days: 182)), now),
        TreeStateIds.newlyPlanted,
      );
    });

    test('justo antes de 1 año (−364d) → newly_planted', () {
      expect(
        treeStateFromPlantingDate(now.subtract(const Duration(days: 364)), now),
        TreeStateIds.newlyPlanted,
      );
    });

    test('1 año cumplido (−365d) → juvenile_non_productive', () {
      expect(
        treeStateFromPlantingDate(now.subtract(const Duration(days: 365)), now),
        TreeStateIds.juvenileNonProductive,
      );
    });

    test('2 años o más (−730d) → juvenile_non_productive', () {
      expect(
        treeStateFromPlantingDate(now.subtract(const Duration(days: 730)), now),
        TreeStateIds.juvenileNonProductive,
      );
    });
  });

  group('resolveTreePlantingAnchorSelection', () {
    final now = DateTime(2026, 6, 12);

    test('sin fecha -> juvenil vegetativo con ancla planting', () {
      final selection = resolveTreePlantingAnchorSelection(
        plantingDate: null,
        now: now,
      );

      expect(selection.perennialStateId, TreeStateIds.juvenileNonProductive);
      expect(selection.phenologyStageId, TreeStageIds.juvenileVegetative);
      expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
    });

    test('menos de 14 dias -> planting_transplant', () {
      final selection = resolveTreePlantingAnchorSelection(
        plantingDate: now.subtract(const Duration(days: 13)),
        now: now,
      );

      expect(selection.perennialStateId, TreeStateIds.newlyPlanted);
      expect(selection.phenologyStageId, TreeStageIds.plantingTransplant);
      expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
    });

    test('15 dias a menos de 1 ano -> root_establishment', () {
      final selection = resolveTreePlantingAnchorSelection(
        plantingDate: now.subtract(const Duration(days: 15)),
        now: now,
      );

      expect(selection.perennialStateId, TreeStateIds.newlyPlanted);
      expect(selection.phenologyStageId, TreeStageIds.rootEstablishment);
      expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
    });

    test('1 ano o mas -> juvenile_vegetative', () {
      final selection = resolveTreePlantingAnchorSelection(
        plantingDate: now.subtract(const Duration(days: 365)),
        now: now,
      );

      expect(selection.perennialStateId, TreeStateIds.juvenileNonProductive);
      expect(selection.phenologyStageId, TreeStageIds.juvenileVegetative);
      expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
    });
  });
}
