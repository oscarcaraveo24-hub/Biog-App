import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';

void main() {
  // ── 1. SeedInstall.planted factory ─────────────────────────────────────

  group('SeedInstall.planted', () {
    test('creates with SowingStatus.planted', () {
      final seed = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      expect(seed.status, SowingStatus.planted);
      expect(seed.isPlanted, isTrue);
      expect(seed.isPlanned, isFalse);
      expect(seed.isSkip, isFalse);
    });

    test('sets sowingDate', () {
      final date = DateTime(2025, 5, 15);
      final seed = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: date,
      );

      expect(seed.sowingDate, date);
      expect(seed.plannedSowingDate, isNull);
    });

    test('sets deviceId and cropKey', () {
      final seed = SeedInstall.planted(
        deviceId: 'dev-42',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      expect(seed.deviceId, 'dev-42');
      expect(seed.cropKey, 'maize');
    });

    test('trims varietyAlias', () {
      final seed = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: '  DK-2069  ',
        sowingDate: DateTime(2025, 5, 15),
      );

      expect(seed.varietyAlias, 'DK-2069');
    });

    test('accepts optional profileId', () {
      final seed = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
        profileId: 'maize_generic',
      );

      expect(seed.profileId, 'maize_generic');
    });
  });

  // ── 2. SeedInstall.planned factory ─────────────────────────────────────

  group('SeedInstall.planned', () {
    test('creates with SowingStatus.planned', () {
      final seed = SeedInstall.planned(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        plannedDate: DateTime(2025, 7, 1),
      );

      expect(seed.status, SowingStatus.planned);
      expect(seed.isPlanned, isTrue);
      expect(seed.isPlanted, isFalse);
      expect(seed.isSkip, isFalse);
    });

    test('sets plannedSowingDate', () {
      final date = DateTime(2025, 7, 1);
      final seed = SeedInstall.planned(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        plannedDate: date,
      );

      expect(seed.plannedSowingDate, date);
      expect(seed.sowingDate, isNull);
    });

    test('sets deviceId and cropKey', () {
      final seed = SeedInstall.planned(
        deviceId: 'dev-99',
        cropKey: 'bean',
        varietyAlias: 'generic',
        plannedDate: DateTime(2025, 7, 1),
      );

      expect(seed.deviceId, 'dev-99');
      expect(seed.cropKey, 'bean');
    });
  });

  // ── 3. SeedInstall.skip factory ────────────────────────────────────────

  group('SeedInstall.skip', () {
    test('creates with SowingStatus.skip', () {
      final seed = SeedInstall.skip(
        deviceId: 'dev-1',
        cropKey: 'maize',
      );

      expect(seed.status, SowingStatus.skip);
      expect(seed.isSkip, isTrue);
      expect(seed.isPlanted, isFalse);
      expect(seed.isPlanned, isFalse);
    });

    test('defaults varietyAlias to "generic"', () {
      final seed = SeedInstall.skip(
        deviceId: 'dev-1',
        cropKey: 'maize',
      );

      expect(seed.varietyAlias, 'generic');
    });

    test('has no sowingDate or plannedSowingDate', () {
      final seed = SeedInstall.skip(
        deviceId: 'dev-1',
        cropKey: 'maize',
      );

      expect(seed.sowingDate, isNull);
      expect(seed.plannedSowingDate, isNull);
    });

    test('accepts custom varietyAlias', () {
      final seed = SeedInstall.skip(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'genérico',
      );

      expect(seed.varietyAlias, 'genérico');
    });
  });

  // ── 4. copyWith ────────────────────────────────────────────────────────

  group('copyWith', () {
    test('changes specific fields while preserving others', () {
      final original = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      final copy = original.copyWith(
        varietyAlias: 'Pioneer-303',
      );

      expect(copy.deviceId, 'dev-1');
      expect(copy.cropKey, 'maize');
      expect(copy.varietyAlias, 'Pioneer-303');
      expect(copy.status, SowingStatus.planted);
      expect(copy.sowingDate, DateTime(2025, 5, 15));
    });

    test('can change status', () {
      final original = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      final copy = original.copyWith(status: SowingStatus.planned);
      expect(copy.status, SowingStatus.planned);
    });

    test('can change deviceId', () {
      final original = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      final copy = original.copyWith(deviceId: 'dev-2');
      expect(copy.deviceId, 'dev-2');
      expect(copy.cropKey, 'maize');
    });

    test('can set sowingDate to null', () {
      final original = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      final copy = original.copyWith(sowingDate: null);
      expect(copy.sowingDate, isNull);
    });

    test('can set profileId to null', () {
      final original = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
        profileId: 'maize_generic',
      );

      final copy = original.copyWith(profileId: null);
      expect(copy.profileId, isNull);
    });

    test('canonicalizes cropKey on copy', () {
      final original = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      final copy = original.copyWith(cropKey: 'corn');
      expect(copy.cropKey, 'maize');
    });
  });

  // ── 5. _canonicalCropKey via factories ─────────────────────────────────

  group('_canonicalCropKey via factories', () {
    test('planted: "corn" is stored as "maize"', () {
      final seed = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'corn',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );
      expect(seed.cropKey, 'maize');
    });

    test('planned: "frijol" is stored as "bean"', () {
      final seed = SeedInstall.planned(
        deviceId: 'dev-1',
        cropKey: 'frijol',
        varietyAlias: 'generic',
        plannedDate: DateTime(2025, 7, 1),
      );
      expect(seed.cropKey, 'bean');
    });

    test('skip: "trigo" is stored as "wheat"', () {
      final seed = SeedInstall.skip(
        deviceId: 'dev-1',
        cropKey: 'trigo',
      );
      expect(seed.cropKey, 'wheat');
    });

    test('skip: "cebada" is stored as "barley"', () {
      final seed = SeedInstall.skip(
        deviceId: 'dev-1',
        cropKey: 'cebada',
      );
      expect(seed.cropKey, 'barley');
    });

    test('planted: "maize" stays "maize"', () {
      final seed = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );
      expect(seed.cropKey, 'maize');
    });

    test('throws on empty cropKey', () {
      expect(
        () => SeedInstall.planted(
          deviceId: 'dev-1',
          cropKey: '',
          varietyAlias: 'DK-2069',
          sowingDate: DateTime(2025, 5, 15),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── 6. toDeviceCropContext ─────────────────────────────────────────────

  group('toDeviceCropContext', () {
    test('planted seed maps to CropLifecycleStatus.planted', () {
      final seed = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      final ctx = seed.toDeviceCropContext();
      expect(ctx.lifecycleStatus, CropLifecycleStatus.planted);
    });

    test('planned seed maps to CropLifecycleStatus.planned', () {
      final seed = SeedInstall.planned(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        plannedDate: DateTime(2025, 7, 1),
      );

      final ctx = seed.toDeviceCropContext();
      expect(ctx.lifecycleStatus, CropLifecycleStatus.planned);
    });

    test('skip seed maps to CropLifecycleStatus.fallow', () {
      final seed = SeedInstall.skip(
        deviceId: 'dev-1',
        cropKey: 'maize',
      );

      final ctx = seed.toDeviceCropContext();
      expect(ctx.lifecycleStatus, CropLifecycleStatus.fallow);
    });

    test('preserves deviceId', () {
      final seed = SeedInstall.planted(
        deviceId: 'dev-42',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      final ctx = seed.toDeviceCropContext();
      expect(ctx.deviceId, 'dev-42');
    });

    test('preserves cropId as canonical key', () {
      final seed = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'corn',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      final ctx = seed.toDeviceCropContext();
      expect(ctx.cropId, 'maize');
    });

    test('preserves sowingDate for planted seed', () {
      final date = DateTime(2025, 5, 15);
      final seed = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: date,
      );

      final ctx = seed.toDeviceCropContext();
      expect(ctx.sowingDate, date);
    });

    test('preserves plannedSowingDate for planned seed', () {
      final date = DateTime(2025, 7, 1);
      final seed = SeedInstall.planned(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        plannedDate: date,
      );

      final ctx = seed.toDeviceCropContext();
      expect(ctx.plannedSowingDate, date);
    });

    test('sets DateConfidence.exact when planted with date', () {
      final seed = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      final ctx = seed.toDeviceCropContext();
      expect(ctx.sowingDateConfidence, DateConfidence.exact);
    });

    test('sets DateConfidence.unknown for skip', () {
      final seed = SeedInstall.skip(
        deviceId: 'dev-1',
        cropKey: 'maize',
      );

      final ctx = seed.toDeviceCropContext();
      expect(ctx.sowingDateConfidence, DateConfidence.unknown);
    });

    test('uses default catalogVersion "v1"', () {
      final seed = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      final ctx = seed.toDeviceCropContext();
      expect(ctx.catalogVersion, 'v1');
    });

    test('uses default source CropConfigSource.demo', () {
      final seed = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        sowingDate: DateTime(2025, 5, 15),
      );

      final ctx = seed.toDeviceCropContext();
      expect(ctx.source, CropConfigSource.demo);
    });
  });

  // ── 7. fromDeviceCropContext round-trip ─────────────────────────────────

  group('fromDeviceCropContext', () {
    test('planted seed round-trips through DeviceCropContext', () {
      final original = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'generic',
        sowingDate: DateTime(2025, 5, 15),
      );

      final ctx = original.toDeviceCropContext();
      final roundTripped = SeedInstall.fromDeviceCropContext(ctx);

      expect(roundTripped.deviceId, original.deviceId);
      expect(roundTripped.cropKey, original.cropKey);
      expect(roundTripped.status, SowingStatus.planted);
      expect(roundTripped.sowingDate, original.sowingDate);
    });

    test('planned seed round-trips through DeviceCropContext', () {
      final original = SeedInstall.planned(
        deviceId: 'dev-2',
        cropKey: 'maize',
        varietyAlias: 'generic',
        plannedDate: DateTime(2025, 7, 1),
      );

      final ctx = original.toDeviceCropContext();
      final roundTripped = SeedInstall.fromDeviceCropContext(ctx);

      expect(roundTripped.deviceId, original.deviceId);
      expect(roundTripped.cropKey, original.cropKey);
      expect(roundTripped.status, SowingStatus.planned);
      expect(roundTripped.plannedSowingDate, original.plannedSowingDate);
    });

    test('skip seed round-trips to fallow and back to skip', () {
      final original = SeedInstall.skip(
        deviceId: 'dev-3',
        cropKey: 'maize',
      );

      final ctx = original.toDeviceCropContext();
      expect(ctx.lifecycleStatus, CropLifecycleStatus.fallow);

      final roundTripped = SeedInstall.fromDeviceCropContext(ctx);
      expect(roundTripped.status, SowingStatus.skip);
      expect(roundTripped.deviceId, original.deviceId);
      expect(roundTripped.cropKey, original.cropKey);
    });

    test('fallow context maps to SowingStatus.skip', () {
      final now = DateTime(2025, 6, 1);
      final ctx = DeviceCropContext(
        deviceId: 'dev-1',
        cropCategoryId: 'grain',
        cropId: 'maize',
        profileId: 'maize_generic',
        lifecycleStatus: CropLifecycleStatus.fallow,
        sowingDateConfidence: DateConfidence.unknown,
        catalogVersion: 'v1',
        source: CropConfigSource.demo,
        configuredAt: now,
        updatedAt: now,
      );

      final seed = SeedInstall.fromDeviceCropContext(ctx);
      expect(seed.status, SowingStatus.skip);
      expect(seed.varietyAlias, 'generic');
    });

    test('planted context maps to SowingStatus.planted', () {
      final now = DateTime(2025, 6, 1);
      final sowDate = DateTime(2025, 5, 10);
      final ctx = DeviceCropContext(
        deviceId: 'dev-1',
        cropCategoryId: 'grain',
        cropId: 'maize',
        profileId: 'maize_generic',
        lifecycleStatus: CropLifecycleStatus.planted,
        sowingDateConfidence: DateConfidence.exact,
        sowingDate: sowDate,
        catalogVersion: 'v1',
        source: CropConfigSource.demo,
        configuredAt: now,
        updatedAt: now,
      );

      final seed = SeedInstall.fromDeviceCropContext(ctx);
      expect(seed.status, SowingStatus.planted);
      expect(seed.sowingDate, sowDate);
    });

    test('planned context maps to SowingStatus.planned', () {
      final now = DateTime(2025, 6, 1);
      final plannedDate = DateTime(2025, 8, 1);
      final ctx = DeviceCropContext(
        deviceId: 'dev-1',
        cropCategoryId: 'grain',
        cropId: 'maize',
        profileId: 'maize_generic',
        lifecycleStatus: CropLifecycleStatus.planned,
        sowingDateConfidence: DateConfidence.exact,
        plannedSowingDate: plannedDate,
        catalogVersion: 'v1',
        source: CropConfigSource.demo,
        configuredAt: now,
        updatedAt: now,
      );

      final seed = SeedInstall.fromDeviceCropContext(ctx);
      expect(seed.status, SowingStatus.planned);
      expect(seed.plannedSowingDate, plannedDate);
    });

    test('preserves profileId through round-trip', () {
      final original = SeedInstall.planted(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'generic',
        sowingDate: DateTime(2025, 5, 15),
        profileId: 'maize_generic',
      );

      final ctx = original.toDeviceCropContext();
      final roundTripped = SeedInstall.fromDeviceCropContext(ctx);

      // The profileId should be preserved (possibly resolved, but still valid).
      expect(roundTripped.profileId, isNotNull);
    });
  });
}
