// test/widgets/account/wizard/configure_seed_wizard_logic_test.dart
//
// Congela la LÓGICA PURA del rediseño del wizard de árboles/manzano (Fase 3)
// sin montar widget tests pesados (el StatefulWidget necesita BioGScope, un
// dispositivo activo y diálogos modales — ver nota de deuda al final).
//
// Cubre:
//  - treeReproSignalVisibleStageId(): señal reproductiva → etapa visible.
//  - treeAnchorDateForOption(): opciones rápidas → fecha (3A plantación / 3B etapa).
//  - Composicion de rutas de arbol con resolveTreeVisibleStageSelection()
//    y resolveTreePlantingAnchorSelection(), que ejecuta el wizard.

import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_pages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // treeReproSignalVisibleStageId — Pantalla 2B → etapa visible.
  // ───────────────────────────────────────────────────────────────────────────
  group('treeReproSignalVisibleStageId', () {
    test('hasFlower → flowering', () {
      expect(
        treeReproSignalVisibleStageId(TreeReproSignalOptionIds.hasFlower),
        TreeStageIds.flowering,
      );
    });

    test('hasFruitSet → fruit_set', () {
      expect(
        treeReproSignalVisibleStageId(TreeReproSignalOptionIds.hasFruitSet),
        TreeStageIds.fruitSet,
      );
    });

    test('hasFruitFill → fruit_fill', () {
      expect(
        treeReproSignalVisibleStageId(TreeReproSignalOptionIds.hasFruitFill),
        TreeStageIds.fruitFill,
      );
    });

    test('growingOnly → null (rama de fecha de plantación)', () {
      expect(
        treeReproSignalVisibleStageId(TreeReproSignalOptionIds.growingOnly),
        isNull,
      );
    });

    test('notSure -> null y marca unknown seguro', () {
      expect(
        treeReproSignalVisibleStageId(TreeReproSignalOptionIds.notSure),
        isNull,
      );
      expect(
        treeReproSignalIsUnknown(TreeReproSignalOptionIds.notSure),
        isTrue,
      );
    });

    test('valor desconocido/null → null', () {
      expect(treeReproSignalVisibleStageId(null), isNull);
      expect(treeReproSignalVisibleStageId('basura'), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // PRIORIDAD 7 — Fechas rápidas de anclaje.
  // ───────────────────────────────────────────────────────────────────────────
  group('treeAnchorDateForOption — inicio de etapa (3B)', () {
    final now = DateTime(2026, 6, 12);

    test('thisWeek → hoy − 5 días', () {
      expect(
        treeAnchorDateForOption(
          TreeAnchorWizardOptionIds.thisWeek,
          now,
          isPlanting: false,
        ),
        now.subtract(const Duration(days: 5)),
      );
    });

    test('oneWeek → hoy − 7 días', () {
      expect(
        treeAnchorDateForOption(
          TreeAnchorWizardOptionIds.oneWeek,
          now,
          isPlanting: false,
        ),
        now.subtract(const Duration(days: 7)),
      );
    });

    test('twoWeeks → hoy − 14 días', () {
      expect(
        treeAnchorDateForOption(
          TreeAnchorWizardOptionIds.twoWeeks,
          now,
          isPlanting: false,
        ),
        now.subtract(const Duration(days: 14)),
      );
    });

    test('twoThreeWeeks → hoy − 18 días', () {
      expect(
        treeAnchorDateForOption(
          TreeAnchorWizardOptionIds.twoThreeWeeks,
          now,
          isPlanting: false,
        ),
        now.subtract(const Duration(days: 18)),
      );
    });

    test('oneMonth → hoy − 30 días', () {
      expect(
        treeAnchorDateForOption(
          TreeAnchorWizardOptionIds.oneMonth,
          now,
          isPlanting: false,
        ),
        now.subtract(const Duration(days: 30)),
      );
    });

    test('opciones sin fecha directa (unknown/custom) → null', () {
      expect(
        treeAnchorDateForOption(
          TreeAnchorWizardOptionIds.unknown,
          now,
          isPlanting: false,
        ),
        isNull,
      );
      expect(
        treeAnchorDateForOption(
          TreeAnchorWizardOptionIds.custom,
          now,
          isPlanting: false,
        ),
        isNull,
      );
    });

    test('una opción de plantación NO aplica en modo etapa → null', () {
      expect(
        treeAnchorDateForOption(
          TreeAnchorWizardOptionIds.plantedOneYear,
          now,
          isPlanting: false,
        ),
        isNull,
      );
    });
  });

  group('treeAnchorDateForOption — plantación (3A)', () {
    final now = DateTime(2026, 6, 12);

    test('plantedThisMonth → hoy − 15 días (dentro del mes)', () {
      final date = treeAnchorDateForOption(
        TreeAnchorWizardOptionIds.plantedThisMonth,
        now,
        isPlanting: true,
      );
      expect(date, now.subtract(const Duration(days: 15)));
      // Antigüedad menor a un mes.
      expect(now.difference(date!).inDays, lessThan(31));
    });

    test('plantedSixMonths → ~180 días (−182d)', () {
      final date = treeAnchorDateForOption(
        TreeAnchorWizardOptionIds.plantedSixMonths,
        now,
        isPlanting: true,
      );
      expect(date, now.subtract(const Duration(days: 182)));
      expect(now.difference(date!).inDays, inInclusiveRange(150, 210));
    });

    test('plantedOneYear → hoy − 365 días', () {
      expect(
        treeAnchorDateForOption(
          TreeAnchorWizardOptionIds.plantedOneYear,
          now,
          isPlanting: true,
        ),
        now.subtract(const Duration(days: 365)),
      );
    });

    test('plantedTwoYearsPlus → claramente más de 2 años (−800d)', () {
      final date = treeAnchorDateForOption(
        TreeAnchorWizardOptionIds.plantedTwoYearsPlus,
        now,
        isPlanting: true,
      );
      expect(date, now.subtract(const Duration(days: 800)));
      expect(now.difference(date!).inDays, greaterThan(730));
    });

    test('una opción de etapa NO aplica en modo plantación → null', () {
      expect(
        treeAnchorDateForOption(
          TreeAnchorWizardOptionIds.twoWeeks,
          now,
          isPlanting: true,
        ),
        isNull,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // PRIORIDAD 6 — Composición de las 4 rutas del wizard (lógica pura que el
  // StatefulWidget ejecuta paso a paso).
  // ───────────────────────────────────────────────────────────────────────────
  group('Rutas del wizard de árbol (composición)', () {
    final now = DateTime(2026, 6, 12);

    test('RUTA A — productiveOrProduced → phenology → anchor stage_start', () {
      // El usuario elige una etapa visible; el anclaje es de inicio de etapa.
      final selection = resolveTreeVisibleStageSelection(
        productionStatusId: TreeProductionStatusIds.productiveOrProduced,
        visibleStageId: TreeStageIds.flowering,
      );
      expect(selection.perennialStateId, TreeStateIds.productiveSeason);
      expect(selection.phenologyStageId, TreeStageIds.flowering);
      expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.stageStart);

      // En 3B las opciones rápidas son de inicio de etapa.
      expect(
        treeAnchorDateForOption(
          TreeAnchorWizardOptionIds.twoWeeks,
          now,
          isPlanting: false,
        ),
        now.subtract(const Duration(days: 14)),
      );
    });

    test('RUTA B — nonProductive → growingOnly → anchor planting', () {
      // "Solo está creciendo" no tiene etapa reproductiva visible.
      expect(
        treeReproSignalVisibleStageId(TreeReproSignalOptionIds.growingOnly),
        isNull,
      );

      // El estado se deriva de la fecha de plantación (3A).
      final plantedOneYearAgo = treeAnchorDateForOption(
        TreeAnchorWizardOptionIds.plantedOneYear,
        now,
        isPlanting: true,
      )!;
      final stateId = treeStateFromPlantingDate(plantedOneYearAgo, now);
      final stageId = inferredTreeStageForState(stateId);

      expect(stateId, TreeStateIds.juvenileNonProductive);
      expect(stageId, TreeStageIds.juvenileVegetative);
      // El anclaje de esta rama es de plantación, nunca de inicio de etapa.
      expect(isTreeStageAllowed(stateId, stageId), isTrue);
    });

    test('RUTA B — growingOnly + fecha desconocida no cae en recién plantado', () {
      final selection = resolveOnboardingTreeSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        phenologyStageId: TreeStageIds.juvenileVegetative,
        plantingDate: null,
        now: now,
      );

      expect(selection.perennialStateId, TreeStateIds.juvenileNonProductive);
      expect(selection.phenologyStageId, TreeStageIds.juvenileVegetative);
      expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
      expect(selection.perennialStateId, isNot(TreeStateIds.newlyPlanted));
      expect(selection.phenologyStageId, isNot(TreeStageIds.rootEstablishment));
    });

    test('RUTA B (joven) — plantación reciente → newly_planted', () {
      final plantedRecently = treeAnchorDateForOption(
        TreeAnchorWizardOptionIds.plantedThisMonth,
        now,
        isPlanting: true,
      )!;
      final stateId = treeStateFromPlantingDate(plantedRecently, now);
      expect(stateId, TreeStateIds.newlyPlanted);
      expect(
        inferredTreeStageForState(stateId),
        TreeStageIds.rootEstablishment,
      );
    });

    test('RUTA B - notSure guarda perfil general seguro', () {
      final selection = resolveTreeVisibleStageSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        visibleStageId: TreeStageIds.unknown,
      );

      expect(selection.perennialStateId, TreeStateIds.unknown);
      expect(selection.phenologyStageId, TreeStageIds.unknown);
      expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.unknown);
      expect(
        selection.perennialStateId,
        isNot(TreeStateIds.juvenileNonProductive),
      );
      expect(selection.perennialStateId, isNot(TreeStateIds.newlyPlanted));
      expect(selection.phenologyStageId, isNot(TreeStageIds.rootEstablishment));
    });

    test('RUTA B - menos de 14 dias -> recien plantado/trasplantado', () {
      final selection = resolveTreePlantingAnchorSelection(
        plantingDate: now.subtract(const Duration(days: 13)),
        now: now,
      );

      expect(selection.perennialStateId, TreeStateIds.newlyPlanted);
      expect(selection.phenologyStageId, TreeStageIds.plantingTransplant);
      expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
    });

    test('RUTA B - 15 dias a menos de 1 ano -> agarrando raiz', () {
      final selection = resolveTreePlantingAnchorSelection(
        plantingDate: now.subtract(const Duration(days: 15)),
        now: now,
      );

      expect(selection.perennialStateId, TreeStateIds.newlyPlanted);
      expect(selection.phenologyStageId, TreeStageIds.rootEstablishment);
      expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
    });

    test('RUTA B - 1 ano o mas -> juvenil vegetativo', () {
      final selection = resolveTreePlantingAnchorSelection(
        plantingDate: now.subtract(const Duration(days: 365)),
        now: now,
      );

      expect(selection.perennialStateId, TreeStateIds.juvenileNonProductive);
      expect(selection.phenologyStageId, TreeStageIds.juvenileVegetative);
      expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.planting);
    });

    test(
      'RUTA C — nonProductive → hasFlower → primera temporada productiva',
      () {
        // Caso delicado: el árbol que "todavía no" produce pero ya tiene flor.
        final visibleStage = treeReproSignalVisibleStageId(
          TreeReproSignalOptionIds.hasFlower,
        );
        expect(visibleStage, TreeStageIds.flowering);

        final selection = resolveTreeVisibleStageSelection(
          productionStatusId: TreeProductionStatusIds.nonProductive,
          visibleStageId: visibleStage,
        );
        expect(selection.perennialStateId, TreeStateIds.productiveSeason);
        expect(selection.phenologyStageId, TreeStageIds.flowering);
        expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.stageStart);
        // Y NO cae en unknown.
        expect(selection.perennialStateId, isNot(TreeStateIds.unknown));
      },
    );

    test(
      'RUTA C (frutito) — nonProductive → hasFruitSet → productive_season',
      () {
        final visibleStage = treeReproSignalVisibleStageId(
          TreeReproSignalOptionIds.hasFruitSet,
        );
        final selection = resolveTreeVisibleStageSelection(
          productionStatusId: TreeProductionStatusIds.nonProductive,
          visibleStageId: visibleStage,
        );
        expect(selection.perennialStateId, TreeStateIds.productiveSeason);
        expect(selection.phenologyStageId, TreeStageIds.fruitSet);
        expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.stageStart);
      },
    );

    test('RUTA D — unknown → perfil general sin anclaje', () {
      final selection = resolveTreeVisibleStageSelection(
        productionStatusId: TreeProductionStatusIds.unknown,
        visibleStageId: TreeStageIds.unknown,
      );
      expect(selection.perennialStateId, TreeStateIds.unknown);
      expect(selection.phenologyStageId, TreeStageIds.unknown);
      expect(selection.perennialAnchorTypeId, TreeAnchorTypeIds.unknown);
    });
  });
}
