// test/core/crop_runtime_resolver_test.dart

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const emptyAlertsState = AlertsState();

  // ═══════════════════════════════════════════════════════════════════════════
  // No seed, no context
  // ═══════════════════════════════════════════════════════════════════════════

  group('CropRuntimeResolver.resolve — no seed, no context', () {
    test('stageLabel is "Sin cultivo configurado"', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: null,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.stageLabel, 'Sin cultivo configurado');
    });

    test('hasSeed is false', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: null,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.hasSeed, isFalse);
    });

    test('isPlanted is false', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: null,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.isPlanted, isFalse);
    });

    test('isPlanned is false', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: null,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.isPlanned, isFalse);
    });

    test('cropKeyName is empty', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: null,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.cropKeyName, '');
    });

    test('definition is null', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: null,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.definition, isNull);
    });

    test('profile is null', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: null,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.profile, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Planted maize with sowing date
  // ═══════════════════════════════════════════════════════════════════════════

  group('CropRuntimeResolver.resolve — planted maize with sowing date', () {
    late SeedInstall plantedSeed;

    setUp(() {
      plantedSeed = SeedInstall.planted(
        deviceId: 'test-device-001',
        cropKey: 'maize',
        varietyAlias: 'generic',
        sowingDate: DateTime(2026, 1, 15),
      );
    });

    test('isPlanted is true', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: plantedSeed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 2, 20),
      );

      expect(snapshot.isPlanted, isTrue);
    });

    test('hasSeed is true', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: plantedSeed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 2, 20),
      );

      expect(snapshot.hasSeed, isTrue);
    });

    test('cropKeyName is "maize"', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: plantedSeed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 2, 20),
      );

      expect(snapshot.cropKeyName, 'maize');
    });

    test('sowingStatus is planted', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: plantedSeed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 2, 20),
      );

      expect(snapshot.sowingStatus, SowingStatus.planted);
    });

    test('definition is resolved (not null)', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: plantedSeed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 2, 20),
      );

      expect(snapshot.definition, isNotNull);
    });

    test('profile is resolved (not null)', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: plantedSeed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 2, 20),
      );

      expect(snapshot.profile, isNotNull);
    });

    test('stageResult is computed (not null)', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: plantedSeed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 2, 20),
      );

      expect(snapshot.stageResult, isNotNull);
    });

    test('stageLabel comes from computed stage result', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: plantedSeed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 2, 20),
      );

      // The label should be the Spanish stage label from the engine,
      // not one of the static fallback strings.
      expect(snapshot.stageLabel, isNotEmpty);
      expect(snapshot.stageLabel, isNot('Sin cultivo configurado'));
      expect(snapshot.stageLabel, isNot('Pre-siembra'));
      expect(snapshot.stageLabel, isNot('Descanso del suelo'));
    });

    test('isPlanned is false for planted seed', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: plantedSeed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 2, 20),
      );

      expect(snapshot.isPlanned, isFalse);
    });

    test('planted via DeviceCropContext also resolves correctly', () {
      final ctx = DeviceCropContext(
        deviceId: 'test-device-002',
        cropCategoryId: 'grain',
        cropId: 'maize',
        profileId: 'mzg_gen_b',
        lifecycleStatus: CropLifecycleStatus.planted,
        sowingDate: DateTime(2026, 1, 10),
        sowingDateConfidence: DateConfidence.exact,
        catalogVersion: 'v1',
        source: CropConfigSource.wizard,
        configuredAt: DateTime(2026, 1, 5),
        updatedAt: DateTime(2026, 1, 5),
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: ctx,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 2, 20),
      );

      expect(snapshot.isPlanted, isTrue);
      expect(snapshot.hasSeed, isTrue);
      expect(snapshot.cropKeyName, 'maize');
      expect(snapshot.stageResult, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Planned
  // ═══════════════════════════════════════════════════════════════════════════

  group('CropRuntimeResolver.resolve — planned', () {
    test('isPlanned is true via SeedInstall.planned', () {
      final seed = SeedInstall.planned(
        deviceId: 'test-device-003',
        cropKey: 'maize',
        varietyAlias: 'generic',
        plannedDate: DateTime(2026, 4, 1),
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: seed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 3, 1),
      );

      expect(snapshot.isPlanned, isTrue);
    });

    test('stageLabel is "Pre-siembra" for planned status', () {
      final seed = SeedInstall.planned(
        deviceId: 'test-device-003',
        cropKey: 'maize',
        varietyAlias: 'generic',
        plannedDate: DateTime(2026, 4, 1),
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: seed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 3, 1),
      );

      expect(snapshot.stageLabel, 'Pre-siembra');
    });

    test('isPlanted is false for planned seed', () {
      final seed = SeedInstall.planned(
        deviceId: 'test-device-003',
        cropKey: 'maize',
        varietyAlias: 'generic',
        plannedDate: DateTime(2026, 4, 1),
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: seed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 3, 1),
      );

      expect(snapshot.isPlanted, isFalse);
    });

    test('hasSeed is true for planned seed', () {
      final seed = SeedInstall.planned(
        deviceId: 'test-device-003',
        cropKey: 'maize',
        varietyAlias: 'generic',
        plannedDate: DateTime(2026, 4, 1),
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: seed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 3, 1),
      );

      expect(snapshot.hasSeed, isTrue);
    });

    test('stageResult is null for planned status (engine not invoked)', () {
      final seed = SeedInstall.planned(
        deviceId: 'test-device-003',
        cropKey: 'maize',
        varietyAlias: 'generic',
        plannedDate: DateTime(2026, 4, 1),
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: seed,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 3, 1),
      );

      expect(snapshot.stageResult, isNull);
    });

    test('isPlanned is true via DeviceCropContext with planned status', () {
      final ctx = DeviceCropContext(
        deviceId: 'test-device-004',
        cropCategoryId: 'grain',
        cropId: 'maize',
        profileId: 'mzg_gen_b',
        lifecycleStatus: CropLifecycleStatus.planned,
        plannedSowingDate: DateTime(2026, 4, 15),
        sowingDateConfidence: DateConfidence.estimated,
        catalogVersion: 'v1',
        source: CropConfigSource.wizard,
        configuredAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: ctx,
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 3, 15),
      );

      expect(snapshot.isPlanned, isTrue);
      expect(snapshot.stageLabel, 'Pre-siembra');
      expect(snapshot.isPlanted, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Fallow / skip
  // ═══════════════════════════════════════════════════════════════════════════

  group('CropRuntimeResolver.resolve — fallow / skip', () {
    test('SeedInstall.skip yields sowingStatus == skip', () {
      final seed = SeedInstall.skip(
        deviceId: 'test-device-005',
        cropKey: 'maize',
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: seed,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.sowingStatus, SowingStatus.skip);
    });

    test('fallow DeviceCropContext yields sowingStatus == skip', () {
      final ctx = DeviceCropContext(
        deviceId: 'test-device-006',
        cropCategoryId: 'grain',
        cropId: 'maize',
        profileId: 'mzg_gen_b',
        lifecycleStatus: CropLifecycleStatus.fallow,
        sowingDateConfidence: DateConfidence.unknown,
        catalogVersion: 'v1',
        source: CropConfigSource.wizard,
        configuredAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: ctx,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.sowingStatus, SowingStatus.skip);
    });

    test('isPlanted is false for skip/fallow', () {
      final seed = SeedInstall.skip(
        deviceId: 'test-device-005',
        cropKey: 'maize',
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: seed,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.isPlanted, isFalse);
    });

    test('isPlanned is false for skip/fallow', () {
      final seed = SeedInstall.skip(
        deviceId: 'test-device-005',
        cropKey: 'maize',
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: seed,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.isPlanned, isFalse);
    });

    test('stageLabel is "Descanso del suelo" for skip', () {
      final seed = SeedInstall.skip(
        deviceId: 'test-device-005',
        cropKey: 'maize',
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: seed,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.stageLabel, 'Descanso del suelo');
    });

    test('stageResult is null for skip/fallow', () {
      final seed = SeedInstall.skip(
        deviceId: 'test-device-005',
        cropKey: 'maize',
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: seed,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.stageResult, isNull);
    });

    test('isGenericMode is true for skip/fallow', () {
      final seed = SeedInstall.skip(
        deviceId: 'test-device-005',
        cropKey: 'maize',
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: seed,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.isGenericMode, isTrue);
    });

    test('hasSeed is true even for skip (seed object exists)', () {
      final seed = SeedInstall.skip(
        deviceId: 'test-device-005',
        cropKey: 'maize',
      );

      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: seed,
        live: null,
        alertsState: emptyAlertsState,
      );

      expect(snapshot.hasSeed, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Perennial / tree (apple_tree)
  // ═══════════════════════════════════════════════════════════════════════════

  group('CropRuntimeResolver.resolve — apple_tree (perennial)', () {
    DeviceCropContext treeCtx({
      String? perennialStateId,
      String? phenologyStageId,
    }) {
      return DeviceCropContext(
        deviceId: 'tree-device-001',
        cropCategoryId: 'tree',
        cropId: 'apple_tree',
        profileId: 'ap_01_golden',
        lifecycleStatus: CropLifecycleStatus.planted,
        sowingDateConfidence: DateConfidence.unknown,
        catalogVersion: 'v1',
        source: CropConfigSource.wizard,
        configuredAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        perennialStateId: perennialStateId,
        phenologyStageId: phenologyStageId,
      );
    }

    test('resolves the perennial branch without a sowing date', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: treeCtx(
          perennialStateId: 'productive_season',
          phenologyStageId: 'flowering',
        ),
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 6, 7),
      );

      expect(snapshot.isPlanted, isTrue);
      // El cropId legacy `apple_tree` (en treeCtx) se canonicaliza al oficial.
      expect(snapshot.cropKeyName, 'crop_apple_tree');
      expect(snapshot.definition, isNotNull);
      expect(snapshot.stageResult, isNotNull);
      // Trees do not use sowingDate as the axis.
      expect(snapshot.stageResult!.daySinceSowing, isNull);
      expect(snapshot.stageResult!.stageKey, 'flowering');
    });

    test(
      'invalid stage for state is corrected (newly_planted + flowering)',
      () {
        final snapshot = CropRuntimeResolver.resolve(
          device: null,
          seed: null,
          cropContext: treeCtx(
            perennialStateId: 'newly_planted',
            phenologyStageId: 'flowering',
          ),
          live: null,
          alertsState: emptyAlertsState,
          now: DateTime(2026, 6, 7),
        );

        expect(snapshot.stageResult, isNotNull);
        expect(snapshot.stageResult!.stageKey, 'root_establishment');
      },
    );

    test('unknown/unknown does not crash and stays active', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: treeCtx(
          perennialStateId: 'unknown',
          phenologyStageId: 'unknown',
        ),
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 6, 7),
      );

      expect(snapshot.isPlanted, isTrue);
      expect(snapshot.stageResult, isNotNull);
      expect(snapshot.stageResult!.stageKey, 'unknown');
    });

    test('harvest_maturity does not terminate the crop', () {
      final snapshot = CropRuntimeResolver.resolve(
        device: null,
        seed: null,
        cropContext: treeCtx(
          perennialStateId: 'productive_season',
          phenologyStageId: 'harvest_maturity',
        ),
        live: null,
        alertsState: emptyAlertsState,
        now: DateTime(2026, 6, 7),
      );

      // Still planted/active — harvest is not a terminal cycle for trees.
      expect(snapshot.isPlanted, isTrue);
      expect(snapshot.stageResult!.stageKey, 'harvest_maturity');
      expect(snapshot.stageLabel, 'Maduración / cosecha');
    });
  });
}
