// test/core/perennial_stage_resolver_test.dart
//
// Valida que el resolver perenne (árboles) no use sowingDate como eje, corrija
// etapas imposibles, no termine el árbol en cosecha y no truene con contexto
// desconocido. Corresponde a los casos A/B/C de la auditoría Fase 5.

import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/tree_stage_resolver.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:flutter_test/flutter_test.dart';

DeviceCropContext _treeContext({
  String profileId = 'ap_skip',
  String? perennialStateId,
  String? phenologyStageId,
  DateTime? anchorDate,
  String? anchorTypeId,
}) {
  return DeviceCropContext(
    deviceId: 'tree-device',
    cropCategoryId: 'tree',
    cropId: 'apple_tree',
    profileId: profileId,
    lifecycleStatus: CropLifecycleStatus.planted,
    sowingDateConfidence: DateConfidence.unknown,
    catalogVersion: 'v1',
    source: CropConfigSource.wizard,
    configuredAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    perennialStateId: perennialStateId,
    phenologyStageId: phenologyStageId,
    perennialAnchorDate: anchorDate,
    perennialAnchorTypeId: anchorTypeId,
  );
}

void main() {
  final today = DateTime(2026, 6, 7);

  group('Caso A — productive_season + flowering', () {
    final result = PerennialStageResolver.resolve(
      context: _treeContext(
        profileId: 'ap_01_golden',
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.flowering,
        anchorDate: today.subtract(const Duration(days: 7)),
        anchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      today: today,
    );

    test('resuelve a floración', () {
      expect(result.stageKey, TreeStageIds.flowering);
      expect(result.stageLabelEs, 'Floración');
    });

    test('estado productivo = en producción esta temporada', () {
      expect(result.productiveState, TreeStateIds.productiveSeason);
      expect(result.productiveStateLabelEs, 'En producción esta temporada');
    });

    test('NO usa sowingDate (daySinceSowing es null)', () {
      expect(result.daySinceSowing, isNull);
    });

    test(
      'no marca fin de cultivo (expectedDaysToEnd = 0, no negativo/terminal)',
      () {
        expect(result.expectedDaysToEnd, 0);
      },
    );
  });

  group('Caso B — newly_planted + flowering (inválido) se corrige', () {
    final result = PerennialStageResolver.resolve(
      context: _treeContext(
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.flowering,
      ),
      today: today,
    );

    test('NO truena y corrige a establecimiento radicular', () {
      expect(result.stageKey, TreeStageIds.rootEstablishment);
    });

    test('no muestra floración', () {
      expect(result.stageKey, isNot(TreeStageIds.flowering));
    });

    test('producción no habilitada en recién plantado', () {
      expect(isTreeProductionEnabled(TreeStateIds.newlyPlanted), isFalse);
    });
  });

  group('Caso C — unknown + unknown', () {
    final result = PerennialStageResolver.resolve(
      context: _treeContext(
        perennialStateId: TreeStateIds.unknown,
        phenologyStageId: TreeStageIds.unknown,
      ),
      today: today,
    );

    test('no truena; etapa no definida', () {
      expect(result.stageKey, TreeStageIds.unknown);
      expect(result.stageLabelEs, 'Etapa no definida');
    });

    test('estado general', () {
      expect(result.productiveState, TreeStateIds.unknown);
    });
  });

  group('harvest_maturity NO termina el árbol', () {
    final result = PerennialStageResolver.resolve(
      context: _treeContext(
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.harvestMaturity,
      ),
      today: today,
    );

    test('sigue siendo etapa activa, no cierre de ciclo', () {
      expect(result.stageKey, TreeStageIds.harvestMaturity);
      expect(result.stageLabelEs, 'Maduración / cosecha');
      expect(result.expectedDaysToEnd, 0);
    });
  });

  group('post_harvest y dormancy siguen activos', () {
    test('post_harvest se resuelve como etapa activa', () {
      final result = PerennialStageResolver.resolve(
        context: _treeContext(
          perennialStateId: TreeStateIds.established,
          phenologyStageId: TreeStageIds.postHarvest,
        ),
        today: today,
      );
      expect(result.stageKey, TreeStageIds.postHarvest);
      expect(result.stageLabelEs, 'Post-cosecha');
    });

    test('dormancy se resuelve como reposo activo', () {
      final result = PerennialStageResolver.resolve(
        context: _treeContext(
          perennialStateId: TreeStateIds.established,
          phenologyStageId: TreeStageIds.dormancy,
        ),
        today: today,
      );
      expect(result.stageKey, TreeStageIds.dormancy);
      expect(result.stageLabelEs, 'Reposo');
    });
  });

  group('estado nulo no truena', () {
    test('perennialStateId null → unknown sin excepción', () {
      final result = PerennialStageResolver.resolve(
        context: _treeContext(perennialStateId: null, phenologyStageId: null),
        today: today,
      );
      expect(result.stageKey, TreeStageIds.unknown);
      expect(result.daySinceSowing, isNull);
    });
  });
}
