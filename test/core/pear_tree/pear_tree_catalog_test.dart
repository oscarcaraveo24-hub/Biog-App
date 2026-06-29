// test/core/pear_tree/pear_tree_catalog_test.dart
//
// Catálogo, aliases, SKIP, migración y alta en registry/catalog de la Pera.
// Reglas: PR-SKIP es general/migrable; pera asiática/nashi NO inventa PR-06;
// el alias legacy `pear_tree` resuelve al cropId canónico `crop_pear_tree`.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_crop_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Alta en catálogo y registry', () {
    test('crop_pear_tree existe y es categoría tree', () {
      final crop = CropCatalog.cropById(kCropPearTree);
      expect(crop, isNotNull);
      expect(crop!.categoryId, CropCatalog.treeCategoryId);
      expect(crop.label, 'Pera');
      expect(crop.defaultProfileId, kPrSkip);
    });

    test('cropId canónico + alias legacy resuelven a crop_pear_tree', () {
      for (final raw in <String>[
        'crop_pear_tree',
        'pear_tree',
        'pear',
        'pera',
        'peral',
        'Peras',
      ]) {
        expect(CropCatalog.canonicalCropKey(raw), kCropPearTree, reason: raw);
      }
    });

    test('CropRegistry resuelve la pera por key y por cropId', () {
      expect(
        CropRegistry.byKey(CropKey.pearTree),
        isA<PearTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('crop_pear_tree'),
        isA<PearTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('pear_tree'),
        isA<PearTreeCropDefinition>(),
      );
    });

    test('la pera NO contamina al manzano (cultivos existentes intactos)', () {
      expect(
        CropCatalog.canonicalCropKey('manzano'),
        CropCatalog.appleTreeCropId,
      );
      expect(
        CropCatalog.canonicalCropKey('apple_tree'),
        CropCatalog.appleTreeCropId,
      );
      expect(CropCatalog.cropById('manzano')!.label, 'Manzano');
    });
  });

  group('Perfiles PR y resolución por alias', () {
    test('pr_skip existe, es el default y es genérico/migrable', () {
      final skip = CropCatalog.profileById(kCropPearTree, kPrSkip);
      expect(skip, isNotNull);
      expect(CropCatalog.cropById(kCropPearTree)!.defaultProfileId, kPrSkip);
    });

    test('aliases comerciales resuelven al perfil correcto', () {
      final cases = <String, String>{
        'Bartlett': kPr01BartlettWilliams,
        'Williams': kPr01BartlettWilliams,
        'Pera de agua': kPr01BartlettWilliams,
        "D'Anjou": kPr02Anjou,
        'Anjou': kPr02Anjou,
        'Red Anjou': kPr02Anjou,
        'Green Anjou': kPr02Anjou,
        'Bosc': kPr03Bosc,
        'Mantecosa Bosc': kPr03Bosc,
        'Beurre Bosc': kPr03Bosc,
        'Seckel': kPr04SeckelComice,
        'Comice': kPr04SeckelComice,
        'Premium': kPr04SeckelComice,
        'Dulce': kPr04SeckelComice,
        'Kieffer': kPr05KiefferRustic,
        'Rustica': kPr05KiefferRustic,
        'Para proceso': kPr05KiefferRustic,
      };
      cases.forEach((alias, expectedId) {
        final profile = CropCatalog.profileByAny(kCropPearTree, alias);
        expect(profile?.id, expectedId, reason: alias);
      });
    });

    test('pera asiática / nashi NO inventa PR-06: cae a pr_skip', () {
      for (final raw in <String>[
        'Pera asiatica',
        'Nashi',
        'Pera manzana',
        'Asian pear',
      ]) {
        final profile = CropCatalog.profileByAny(kCropPearTree, raw);
        expect(profile?.id, kPrSkip, reason: raw);
      }
    });

    test('CropDefinition.resolveProfile usa pr_skip como fallback', () {
      final def = PearTreeCropDefinition();
      expect(def.resolveProfile(profileId: 'no_existe')!.id, kPrSkip);
      expect(
        def.resolveProfile(varietyAlias: 'Bartlett')!.id,
        kPr01BartlettWilliams,
      );
      // Nunca cae a un perfil de manzano.
      expect(def.resolveProfile()!.id.startsWith('pr_'), isTrue);
    });
  });
}
