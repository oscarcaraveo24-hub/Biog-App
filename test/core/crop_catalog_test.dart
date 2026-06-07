// test/core/crop_catalog_test.dart

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/maize_profiles.dart';
import 'package:bio_g/widgets/seeds/wheat_profiles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // canonicalCropKey
  // ═══════════════════════════════════════════════════════════════════════════

  group('CropCatalog.canonicalCropKey', () {
    group('maize aliases', () {
      test('"maize" returns "maize"', () {
        expect(CropCatalog.canonicalCropKey('maize'), 'maize');
      });

      test('"corn" returns "maize"', () {
        expect(CropCatalog.canonicalCropKey('corn'), 'maize');
      });

      test('"maiz" returns "maize"', () {
        expect(CropCatalog.canonicalCropKey('maiz'), 'maize');
      });

      test('case-insensitive: "MAIZE" returns "maize"', () {
        expect(CropCatalog.canonicalCropKey('MAIZE'), 'maize');
      });

      test('case-insensitive: "Corn" returns "maize"', () {
        expect(CropCatalog.canonicalCropKey('Corn'), 'maize');
      });
    });

    group('bean aliases', () {
      test('"bean" returns "bean"', () {
        expect(CropCatalog.canonicalCropKey('bean'), 'bean');
      });

      test('"beans" returns "bean"', () {
        expect(CropCatalog.canonicalCropKey('beans'), 'bean');
      });

      test('"frijol" returns "bean"', () {
        expect(CropCatalog.canonicalCropKey('frijol'), 'bean');
      });

      test('case-insensitive: "FRIJOL" returns "bean"', () {
        expect(CropCatalog.canonicalCropKey('FRIJOL'), 'bean');
      });
    });

    group('wheat aliases', () {
      test('"wheat" returns "wheat"', () {
        expect(CropCatalog.canonicalCropKey('wheat'), 'wheat');
      });

      test('"trigo" returns "wheat"', () {
        expect(CropCatalog.canonicalCropKey('trigo'), 'wheat');
      });

      test('case-insensitive: "TRIGO" returns "wheat"', () {
        expect(CropCatalog.canonicalCropKey('TRIGO'), 'wheat');
      });
    });

    group('barley aliases', () {
      test('"barley" returns "barley"', () {
        expect(CropCatalog.canonicalCropKey('barley'), 'barley');
      });

      test('"cebada" returns "barley"', () {
        expect(CropCatalog.canonicalCropKey('cebada'), 'barley');
      });

      test('case-insensitive: "CEBADA" returns "barley"', () {
        expect(CropCatalog.canonicalCropKey('CEBADA'), 'barley');
      });
    });

    group('oat aliases', () {
      test('"oat" returns "oat"', () {
        expect(CropCatalog.canonicalCropKey('oat'), 'oat');
      });

      test('"avena" returns "oat"', () {
        expect(CropCatalog.canonicalCropKey('avena'), 'oat');
      });

      test('case-insensitive: "AVENA" returns "oat"', () {
        expect(CropCatalog.canonicalCropKey('AVENA'), 'oat');
      });
    });

    group('unknown / passthrough', () {
      test('unknown crop key is returned as lowercase passthrough', () {
        expect(CropCatalog.canonicalCropKey('sorghum'), 'sorghum');
      });

      test('unknown crop with mixed case is lowercased', () {
        expect(CropCatalog.canonicalCropKey('Sorghum'), 'sorghum');
      });
    });

    group('null and blank handling', () {
      test('null returns empty string', () {
        expect(CropCatalog.canonicalCropKey(null), '');
      });

      test('empty string returns empty string', () {
        expect(CropCatalog.canonicalCropKey(''), '');
      });

      test('blank (whitespace-only) returns empty string', () {
        expect(CropCatalog.canonicalCropKey('   '), '');
      });
    });

    group('whitespace trimming', () {
      test('leading/trailing spaces are trimmed before matching', () {
        expect(CropCatalog.canonicalCropKey('  maize  '), 'maize');
      });

      test('leading/trailing spaces on alias', () {
        expect(CropCatalog.canonicalCropKey('  corn  '), 'maize');
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // canonicalCropKeyOrNull
  // ═══════════════════════════════════════════════════════════════════════════

  group('CropCatalog.canonicalCropKeyOrNull', () {
    test('null input returns null', () {
      expect(CropCatalog.canonicalCropKeyOrNull(null), isNull);
    });

    test('empty string returns null', () {
      expect(CropCatalog.canonicalCropKeyOrNull(''), isNull);
    });

    test('blank (whitespace-only) returns null', () {
      expect(CropCatalog.canonicalCropKeyOrNull('   '), isNull);
    });

    test('valid alias returns canonical key', () {
      expect(CropCatalog.canonicalCropKeyOrNull('corn'), 'maize');
    });

    test('valid key returns itself', () {
      expect(CropCatalog.canonicalCropKeyOrNull('wheat'), 'wheat');
    });

    test('unknown key returns passthrough (not null)', () {
      expect(CropCatalog.canonicalCropKeyOrNull('sorghum'), 'sorghum');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // cropDisplayName
  // ═══════════════════════════════════════════════════════════════════════════

  group('CropCatalog.cropDisplayName', () {
    test('maize returns "Maiz" (from catalog label)', () {
      expect(CropCatalog.cropDisplayName('maize'), 'Maíz');
    });

    test('wheat returns "Trigo"', () {
      expect(CropCatalog.cropDisplayName('wheat'), 'Trigo');
    });

    test('barley returns "Cebada"', () {
      expect(CropCatalog.cropDisplayName('barley'), 'Cebada');
    });

    test('bean returns "Frijol"', () {
      expect(CropCatalog.cropDisplayName('bean'), 'Frijol');
    });

    test('oat returns "Avena" (from fallback, not in catalog entries)', () {
      expect(CropCatalog.cropDisplayName('oat'), 'Avena');
    });

    test('unknown crop returns "Cultivo" (fallback)', () {
      expect(CropCatalog.cropDisplayName('sorghum'), 'Cultivo');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // cropById
  // ═══════════════════════════════════════════════════════════════════════════

  group('CropCatalog.cropById', () {
    test('returns maize entry for "maize"', () {
      final crop = CropCatalog.cropById('maize');
      expect(crop, isNotNull);
      expect(crop!.cropId, 'maize');
      expect(crop.label, 'Maíz');
      expect(crop.enabled, isTrue);
    });

    test('returns wheat entry for "wheat"', () {
      final crop = CropCatalog.cropById('wheat');
      expect(crop, isNotNull);
      expect(crop!.cropId, 'wheat');
      expect(crop.enabled, isTrue);
    });

    test('returns barley entry for "barley"', () {
      final crop = CropCatalog.cropById('barley');
      expect(crop, isNotNull);
      expect(crop!.cropId, 'barley');
    });

    test('returns bean entry for "bean"', () {
      final crop = CropCatalog.cropById('bean');
      expect(crop, isNotNull);
      expect(crop!.cropId, 'bean');
    });

    test('is case-insensitive', () {
      final crop = CropCatalog.cropById('MAIZE');
      expect(crop, isNotNull);
      expect(crop!.cropId, 'maize');
    });

    test('returns null for unknown crop id', () {
      expect(CropCatalog.cropById('sorghum'), isNull);
    });

    test('returns null for null', () {
      expect(CropCatalog.cropById(null), isNull);
    });

    test('returns null for empty string', () {
      expect(CropCatalog.cropById(''), isNull);
    });

    test('returns null for blank string', () {
      expect(CropCatalog.cropById('   '), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // resolveProfileId
  // ═══════════════════════════════════════════════════════════════════════════

  group('CropCatalog.resolveProfileId', () {
    test('explicit valid profile id is returned directly', () {
      // kMzg00 is a valid maize profile
      final result = CropCatalog.resolveProfileId(
        cropId: 'maize',
        explicitProfileId: kMzg00,
      );
      expect(result, kMzg00);
    });

    test('explicit profile takes precedence over variety default', () {
      // asgrow_antilope_forage defaults to kMzf01, but explicit should win
      final result = CropCatalog.resolveProfileId(
        cropId: 'maize',
        varietyId: 'asgrow_antilope_forage',
        explicitProfileId: kMzg03,
      );
      expect(result, kMzg03);
    });

    test('variety default profile is used when no explicit profile', () {
      // asgrow_antilope_grain has defaultProfileId = kMzg04
      final result = CropCatalog.resolveProfileId(
        cropId: 'maize',
        varietyId: 'asgrow_antilope_grain',
      );
      expect(result, kMzg04);
    });

    test('crop-level default profile used when no variety or explicit', () {
      // Maize crop defaultProfileId = kMzgGenB (mzg_gen_b)
      final result = CropCatalog.resolveProfileId(cropId: 'maize');
      expect(result, kMzgGenB);
    });

    test('crop-level default profile used for wheat (tr_gen)', () {
      // Trigo ya esta habilitado y tiene perfiles; su perfil por defecto es
      // tr_gen, asi que resuelve a el (no al sintetico "{cropId}_generic").
      final result = CropCatalog.resolveProfileId(cropId: 'wheat');
      expect(result, kTrGen);
    });

    test('unknown crop falls back to synthetic generic id', () {
      final result = CropCatalog.resolveProfileId(cropId: 'sorghum');
      expect(result, 'sorghum_generic');
    });

    test('null variety and null explicit still resolves via crop default', () {
      final result = CropCatalog.resolveProfileId(
        cropId: 'maize',
        varietyId: null,
        explicitProfileId: null,
      );
      expect(result, kMzgGenB);
    });

    test('invalid explicit profile id falls through to next level', () {
      final result = CropCatalog.resolveProfileId(
        cropId: 'maize',
        explicitProfileId: 'nonexistent_profile_id',
      );
      // Falls to crop default
      expect(result, kMzgGenB);
    });

    test('profile resolution via alias works for explicit profile', () {
      // kMzg07 has alias 'MZG-07'
      final result = CropCatalog.resolveProfileId(
        cropId: 'maize',
        explicitProfileId: 'MZG-07',
      );
      expect(result, kMzg07);
    });
  });
}
