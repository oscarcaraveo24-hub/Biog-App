// test/core/apple_tree/apple_tree_catalog_test.dart
//
// Catálogo del Manzano: categoría tree, perfiles AP, aliases, resolución de
// conflictos (Dorsett Golden → bajo frío) e íconos por perfil.

import 'package:bio_g/core/crops/apple_tree/apple_tree_assets.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_crop_definition.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final definition = AppleTreeCropDefinition();

  String? resolvedProfileId(String alias) =>
      definition.resolveProfile(varietyAlias: alias)?.id;

  group('cropId canónico crop_apple_tree + alias legacy apple_tree', () {
    test('el cropId canónico oficial es crop_apple_tree', () {
      expect(CropCatalog.appleTreeCropId, 'crop_apple_tree');
      expect(kCropAppleTree, 'crop_apple_tree');
    });

    test('apple_tree (legacy) canonicaliza a crop_apple_tree', () {
      expect(CropCatalog.canonicalCropKey('apple_tree'), 'crop_apple_tree');
      expect(
        CropCatalog.canonicalCropKey('crop_apple_tree'),
        'crop_apple_tree',
      );
      expect(CropCatalog.canonicalCropKey('manzano'), 'crop_apple_tree');
    });

    test('ambos ids resuelven al MISMO Manzano (sin duplicar)', () {
      final byCanonical = CropCatalog.cropById('crop_apple_tree');
      final byLegacy = CropCatalog.cropById('apple_tree');
      expect(byCanonical, isNotNull);
      expect(byLegacy, isNotNull);
      expect(byLegacy!.cropId, byCanonical!.cropId);
      expect(byCanonical.cropId, 'crop_apple_tree');
    });

    test('no hay doble Manzano en la categoría tree', () {
      final trees = CropCatalog.cropsByCategory(CropCatalog.treeCategoryId);
      final manzanos = trees
          .where((c) => c.cropId == CropCatalog.appleTreeCropId)
          .toList();
      expect(manzanos.length, 1);
    });

    test('CropRegistry resuelve canónico y legacy a la misma definición', () {
      final byCanonical = CropRegistry.byKeyName('crop_apple_tree');
      final byLegacy = CropRegistry.byKeyName('apple_tree');
      expect(byCanonical, isNotNull);
      expect(byLegacy, isNotNull);
      expect(byCanonical!.cropKey, CropKey.appleTree);
      expect(byLegacy!.cropKey, CropKey.appleTree);
    });

    test('isTreeCrop reconoce ambos ids', () {
      expect(isTreeCrop(cropId: 'crop_apple_tree'), isTrue);
      expect(isTreeCrop(cropId: 'apple_tree'), isTrue);
    });
  });

  group('Manzano — alta de cultivo', () {
    test('existe como cultivo de categoría tree', () {
      final crop = CropCatalog.cropById(CropCatalog.appleTreeCropId);
      expect(crop, isNotNull);
      expect(crop!.categoryId, CropCatalog.treeCategoryId);
      expect(isTreeCrop(cropId: 'apple_tree'), isTrue);
    });

    test('se muestra como "Manzano"', () {
      expect(CropCatalog.cropDisplayName('apple_tree'), 'Manzano');
      expect(definition.displayName, 'Manzano');
      expect(definition.category, CropCategory.tree);
    });

    test('está registrado en CropRegistry', () {
      expect(CropRegistry.byKey(CropKey.appleTree), isNotNull);
      expect(CropRegistry.byKeyName('apple_tree'), isNotNull);
    });

    test('ícono principal del cultivo es ic_apple_tree.png', () {
      expect(AppleTreeAssets.cropIcon, 'assets/icons/wizard/ic_apple_tree.png');
    });
  });

  group('Perfil AP-SKIP', () {
    test('existe y es el perfil por defecto del manzano', () {
      expect(CropCatalog.appleTreeDefaultProfileId, kApSkip);
      expect(appleTreeProfiles.containsKey(kApSkip), isTrue);
    });

    test('usa ícono neutro ic_apple_tree_generic.png', () {
      expect(appleTreeProfileIcon(kApSkip), AppleTreeAssets.neutralIcon);
      expect(
        AppleTreeAssets.neutralIcon,
        'assets/icons/wizard/ic_apple_tree_generic.png',
      );
    });

    test('"Manzano" / "No sé" / "No se" resuelven a AP-SKIP', () {
      expect(resolvedProfileId('Manzano'), kApSkip);
      expect(resolvedProfileId('No sé'), kApSkip);
      expect(resolvedProfileId('No se'), kApSkip);
    });
  });

  group('Resolución de aliases por variedad', () {
    test('Golden / Golden Delicious / amarilla → AP-01', () {
      expect(resolvedProfileId('Golden'), kAp01Golden);
      expect(resolvedProfileId('Golden Delicious'), kAp01Golden);
      expect(resolvedProfileId('manzana amarilla'), kAp01Golden);
    });

    test('Red / Top Red / Starkrimson / roja → AP-02', () {
      expect(resolvedProfileId('Red'), kAp02Red);
      expect(resolvedProfileId('Red Delicious'), kAp02Red);
      expect(resolvedProfileId('Top Red'), kAp02Red);
      expect(resolvedProfileId('Starkrimson'), kAp02Red);
      expect(resolvedProfileId('manzana roja'), kAp02Red);
    });

    test('Criolla / Rayada / Regional → AP-03', () {
      expect(resolvedProfileId('Criolla'), kAp03CriollaRayada);
      expect(resolvedProfileId('Rayada'), kAp03CriollaRayada);
      expect(resolvedProfileId('Regional'), kAp03CriollaRayada);
    });

    test('Gala / Royal Gala → AP-04', () {
      expect(resolvedProfileId('Gala'), kAp04Gala);
      expect(resolvedProfileId('Royal Gala'), kAp04Gala);
    });

    test('Anna / Bajo frío / Tropical → AP-05', () {
      expect(resolvedProfileId('Anna'), kAp05LowChill);
      expect(resolvedProfileId('Bajo frío'), kAp05LowChill);
      expect(resolvedProfileId('Tropical'), kAp05LowChill);
    });

    test(
      'CONFLICTO: "Dorsett Golden" / "Golden Dorsett" → bajo frío, NO Golden',
      () {
        expect(resolvedProfileId('Dorsett Golden'), kAp05LowChill);
        expect(resolvedProfileId('Golden Dorsett'), kAp05LowChill);
        // También por las rutas del catálogo (presentación/íconos).
        expect(
          CropCatalog.profileByAny('apple_tree', 'Dorsett Golden')?.id,
          kAp05LowChill,
        );
        expect(
          appleTreeProfileIcon('Dorsett Golden'),
          isNot(equals('assets/icons/wizard/ic_apple_golden.png')),
        );
      },
    );

    test('alias desconocido cae al perfil general (AP-SKIP)', () {
      expect(resolvedProfileId('cultivar inexistente xyz'), kApSkip);
    });
  });

  group('Íconos por perfil AP', () {
    test('cada perfil AP tiene su ícono correcto', () {
      expect(
        appleTreeProfileIcon(kAp01Golden),
        'assets/icons/wizard/ic_apple_golden.png',
      );
      expect(
        appleTreeProfileIcon(kAp02Red),
        'assets/icons/wizard/ic_apple_red.png',
      );
      expect(
        appleTreeProfileIcon(kAp03CriollaRayada),
        'assets/icons/wizard/ic_apple_criolla_rayada.png',
      );
      expect(
        appleTreeProfileIcon(kAp04Gala),
        'assets/icons/wizard/ic_apple_gala.png',
      );
      expect(
        appleTreeProfileIcon(kAp05LowChill),
        'assets/icons/wizard/ic_apple_low_chill.png',
      );
    });
  });

  group('Regresión de cultivos anuales', () {
    test('los cultivos anuales no son árboles', () {
      expect(isTreeCrop(cropId: 'onion'), isFalse);
      expect(isTreeCrop(cropId: 'garlic'), isFalse);
      expect(isTreeCrop(cropId: 'eggplant'), isFalse);
      expect(isTreeCrop(cropId: 'squash'), isFalse);
    });

    test('el registro de cultivos anuales sigue intacto', () {
      expect(CropRegistry.byKey(CropKey.onion), isNotNull);
      expect(CropRegistry.byKey(CropKey.garlic), isNotNull);
      expect(CropRegistry.byKey(CropKey.maize), isNotNull);
      expect(CropRegistry.byKey(CropKey.eggplant), isNotNull);
    });
  });
}
