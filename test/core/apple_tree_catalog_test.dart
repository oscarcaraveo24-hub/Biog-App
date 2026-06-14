// test/core/apple_tree_catalog_test.dart
//
// Fija el desbloqueo del Manzano en el catálogo y el mapeo seguro de los ids
// legacy del onboarding viejo (apple_rojo/apple_verde/apple_generic) a los
// perfiles reales AP-SKIP/AP-01..05. AP-SKIP es perfil general, no fallow.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tree / apple_tree están habilitados y son seleccionables', () {
    test('la categoría Árboles está enabled', () {
      final tree = CropCatalog.categoryById(CropCatalog.treeCategoryId);
      expect(tree, isNotNull);
      expect(tree!.enabled, isTrue);
    });

    test('Manzano (apple_tree) está enabled', () {
      final apple = CropCatalog.cropById(CropCatalog.appleTreeCropId);
      expect(apple, isNotNull);
      expect(apple!.enabled, isTrue);
      expect(apple.label, 'Manzano');
      expect(apple.categoryId, CropCatalog.treeCategoryId);
    });

    test('Manzano aparece en cropsByCategory(tree, enabledOnly:true)', () {
      final enabled = CropCatalog.cropsByCategory(
        CropCatalog.treeCategoryId,
        enabledOnly: true,
      ).map((c) => c.cropId);
      expect(enabled, contains(CropCatalog.appleTreeCropId));
    });

    test('Manzano NO aparece bajo grano ni hortaliza', () {
      final grain = CropCatalog.cropsByCategory(
        CropCatalog.grainCategoryId,
      ).map((c) => c.cropId);
      final veg = CropCatalog.cropsByCategory(
        CropCatalog.vegetableCategoryId,
      ).map((c) => c.cropId);
      expect(grain, isNot(contains(CropCatalog.appleTreeCropId)));
      expect(veg, isNot(contains(CropCatalog.appleTreeCropId)));
    });
  });

  group('perfiles reales del Manzano', () {
    test('el perfil por defecto es AP-SKIP', () {
      expect(CropCatalog.appleTreeDefaultProfileId, 'ap_skip');
    });

    test('los 6 perfiles AP existen y resuelven por id', () {
      for (final id in <String>[
        'ap_skip',
        'ap_01_golden',
        'ap_02_red',
        'ap_03_criolla_rayada',
        'ap_04_gala',
        'ap_05_low_chill',
      ]) {
        expect(
          CropCatalog.profileById(CropCatalog.appleTreeCropId, id)?.id,
          id,
          reason: '$id debería existir en el catálogo del manzano',
        );
      }
    });
  });

  group('ids legacy del onboarding viejo se normalizan a perfiles reales', () {
    String? resolve(String legacy) =>
        CropCatalog.profileByAny(CropCatalog.appleTreeCropId, legacy)?.id;

    test('apple_rojo → ap_02_red', () {
      expect(resolve('apple_rojo'), 'ap_02_red');
    });

    test('apple_generic → ap_skip (perfil general, no fallow)', () {
      expect(resolve('apple_generic'), 'ap_skip');
    });

    test('apple_verde → ap_skip (sin inventar perfil nuevo)', () {
      expect(resolve('apple_verde'), 'ap_skip');
    });

    test('resolveProfileId con id legacy cae a un perfil AP válido', () {
      final resolved = CropCatalog.resolveProfileId(
        cropId: CropCatalog.appleTreeCropId,
        explicitProfileId: 'apple_generic',
      );
      expect(resolved, 'ap_skip');
    });
  });
}
