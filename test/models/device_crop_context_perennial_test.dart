// test/models/device_crop_context_perennial_test.dart
//
// Valida que los campos perennes (árboles) sobrevivan la serialización
// toJson/fromJson y que contextos antiguos sin esos campos carguen sin truene
// (todos null), sin afectar a cultivos anuales.

import 'package:bio_g/models/device_crop_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('perennial fields survive toJson/fromJson', () {
    final original = DeviceCropContext(
      deviceId: 'tree-device',
      cropCategoryId: 'tree',
      cropId: 'apple_tree',
      profileId: 'ap_01_golden',
      lifecycleStatus: CropLifecycleStatus.planted,
      sowingDateConfidence: DateConfidence.unknown,
      catalogVersion: 'v1',
      source: CropConfigSource.wizard,
      configuredAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 7),
      perennialStateId: 'productive_season',
      phenologyStageId: 'flowering',
      perennialAnchorDate: DateTime(2026, 5, 31),
      perennialAnchorTypeId: 'stage_start',
    );

    final decoded = DeviceCropContext.fromJson(original.toJson());

    test('perennialStateId round-trips', () {
      expect(decoded.perennialStateId, 'productive_season');
    });

    test('phenologyStageId round-trips', () {
      expect(decoded.phenologyStageId, 'flowering');
    });

    test('perennialAnchorDate round-trips', () {
      expect(decoded.perennialAnchorDate, DateTime(2026, 5, 31));
    });

    test('perennialAnchorTypeId round-trips', () {
      expect(decoded.perennialAnchorTypeId, 'stage_start');
    });

    test('encode/decode (string) also preserves the fields', () {
      final roundTripped = DeviceCropContext.decode(original.encode());
      expect(roundTripped.perennialStateId, 'productive_season');
      expect(roundTripped.phenologyStageId, 'flowering');
      expect(roundTripped.perennialAnchorTypeId, 'stage_start');
    });
  });

  group('copyWith keeps perennial fields unless explicitly changed', () {
    final base = DeviceCropContext(
      deviceId: 'tree-device',
      cropCategoryId: 'tree',
      cropId: 'apple_tree',
      profileId: 'ap_skip',
      lifecycleStatus: CropLifecycleStatus.planted,
      sowingDateConfidence: DateConfidence.unknown,
      catalogVersion: 'v1',
      source: CropConfigSource.wizard,
      configuredAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
      perennialStateId: 'established',
      phenologyStageId: 'dormancy',
      perennialAnchorTypeId: 'stage_start',
    );

    test('untouched copyWith preserves perennial fields', () {
      final copy = base.copyWith(updatedAt: DateTime(2026, 6, 8));
      expect(copy.perennialStateId, 'established');
      expect(copy.phenologyStageId, 'dormancy');
      expect(copy.perennialAnchorTypeId, 'stage_start');
    });

    test('copyWith can null-out a perennial field explicitly', () {
      final copy = base.copyWith(phenologyStageId: null);
      expect(copy.phenologyStageId, isNull);
      // Other perennial fields untouched.
      expect(copy.perennialStateId, 'established');
    });
  });

  group('legacy JSON without perennial keys still loads', () {
    test(
      'annual context without perennial keys → all perennial fields null',
      () {
        final legacyJson = <String, dynamic>{
          'deviceId': 'maize-device',
          'cropCategoryId': 'grain',
          'cropId': 'maize',
          'profileId': 'mzg_gen_b',
          'lifecycleStatus': 'planted',
          'sowingDate': '2026-01-15T00:00:00.000',
          'sowingDateConfidence': 'exact',
          'catalogVersion': 'v1',
          'source': 'wizard',
          'configuredAt': '2026-01-10T00:00:00.000',
          'updatedAt': '2026-01-10T00:00:00.000',
          // NOTE: no perennial* keys at all (pre-tree contexts).
        };

        final decoded = DeviceCropContext.fromJson(legacyJson);

        expect(decoded.cropId, 'maize');
        expect(decoded.perennialStateId, isNull);
        expect(decoded.phenologyStageId, isNull);
        expect(decoded.perennialAnchorDate, isNull);
        expect(decoded.perennialAnchorTypeId, isNull);
      },
    );
  });
}
