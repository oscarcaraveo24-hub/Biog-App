// test/core/walnut_tree/walnut_tree_catalog_test.dart
//
// Catalogo, aliases, SKIP, migracion y alta en registry/catalog del Nogal.
// Reglas: NG-SKIP es general/migrable; pecan/nuez NO inventan NG-06; el alias
// legacy `walnut_tree` resuelve al cropId canonico `crop_walnut_tree`.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_catalog.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_crop_definition.dart';
import 'package:bio_g/core/crops/tree_profile_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Alta en catalogo y registry', () {
    test('crop_walnut_tree existe y es categoria tree', () {
      final crop = CropCatalog.cropById(kCropWalnutTree);
      expect(crop, isNotNull);
      expect(crop!.categoryId, CropCatalog.treeCategoryId);
      expect(crop.label, 'Nogal');
      expect(crop.defaultProfileId, kNgSkip);
    });

    test('cropId canonico + alias legacy + humanos resuelven a crop_walnut_tree', () {
      for (final raw in <String>[
        'crop_walnut_tree',
        'walnut_tree',
        'walnut',
        'walnuttree',
        'nogal',
        'nogal pecanero',
        'pecan',
        'nuez',
        'nuez pecana',
        'Nogales',
      ]) {
        expect(CropCatalog.canonicalCropKey(raw), kCropWalnutTree, reason: raw);
      }
    });

    test('CropRegistry resuelve el nogal por key y por cropId/alias', () {
      expect(
        CropRegistry.byKey(CropKey.walnutTree),
        isA<WalnutTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('crop_walnut_tree'),
        isA<WalnutTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('walnut_tree'),
        isA<WalnutTreeCropDefinition>(),
      );
      expect(CropRegistry.byKeyName('nogal'), isA<WalnutTreeCropDefinition>());
      expect(CropRegistry.byKeyName('nuez'), isA<WalnutTreeCropDefinition>());
    });

    test('el nogal NO contamina a manzano, pera ni durazno', () {
      expect(CropCatalog.canonicalCropKey('manzano'), CropCatalog.appleTreeCropId);
      expect(CropCatalog.canonicalCropKey('pera'), CropCatalog.pearTreeCropId);
      expect(CropCatalog.canonicalCropKey('durazno'), CropCatalog.peachTreeCropId);
      expect(CropCatalog.cropById('durazno')!.label, 'Durazno');
    });
  });

  group('Perfiles NG y resolucion por alias', () {
    test('ng_skip existe, es el default y es generico/migrable', () {
      final skip = CropCatalog.profileById(kCropWalnutTree, kNgSkip);
      expect(skip, isNotNull);
      expect(CropCatalog.cropById(kCropWalnutTree)!.defaultProfileId, kNgSkip);
    });

    test('ng_skip queda al final y las etiquetas visibles no filtran codigos', () {
      final profiles = CropCatalog.profilesForCrop(kCropWalnutTree);
      expect(profiles.last.id, kNgSkip);

      final visibleLabels = profiles
          .map(
            (p) => TreeProfilePresentation.displayLabel(
              kCropWalnutTree,
              p.id,
              fallbackLabel: p.label,
            ),
          )
          .toList();
      final joined = visibleLabels.join(' ');

      expect(visibleLabels.last, 'No sé / Nogal general');
      expect(joined, isNot(contains('NG-')));
      expect(joined, isNot(contains('NG-SKIP')));
      expect(joined, isNot(contains('ng_')));
      expect(joined, isNot(contains('SKIP')));
    });

    test('perfiles NG-01..NG-05 existen', () {
      for (final id in <String>[
        kNg01Western,
        kNg02Wichita,
        kNg03WesternWichita,
        kNg04CriolloRegional,
        kNg05TempranoPawneeKanza,
      ]) {
        expect(CropCatalog.profileById(kCropWalnutTree, id), isNotNull, reason: id);
      }
    });

    test('aliases comerciales resuelven al perfil correcto', () {
      final cases = <String, String>{
        'western': kNg01Western,
        'western schley': kNg01Western,
        'occidental': kNg01Western,
        'wichita': kNg02Wichita,
        'grande': kNg02Wichita,
        'western/wichita': kNg03WesternWichita,
        'bloque norte': kNg03WesternWichita,
        'criollo': kNg04CriolloRegional,
        'nativo': kNg04CriolloRegional,
        'huerto viejo': kNg04CriolloRegional,
        'pawnee': kNg05TempranoPawneeKanza,
        'kanza': kNg05TempranoPawneeKanza,
        'cheyenne': kNg05TempranoPawneeKanza,
        'temprano': kNg05TempranoPawneeKanza,
        'ng_05_temprano_pawnee_kanza': kNg05TempranoPawneeKanza,
      };
      cases.forEach((alias, expectedId) {
        final profile = CropCatalog.profileByAny(kCropWalnutTree, alias);
        expect(profile?.id, expectedId, reason: alias);
      });
    });

    test('pecan / nuez genericos NO inventan NG-06: caen a ng_skip', () {
      for (final raw in <String>['Pecan', 'Nuez', 'Nuez pecana', 'Nogal pecanero']) {
        final profile = CropCatalog.profileByAny(kCropWalnutTree, raw);
        expect(profile?.id, kNgSkip, reason: raw);
      }
    });

    test('CropDefinition.resolveProfile usa ng_skip como fallback', () {
      final def = WalnutTreeCropDefinition();
      expect(def.resolveProfile(profileId: 'no_existe')!.id, kNgSkip);
      expect(
        def.resolveProfile(varietyAlias: 'wichita')!.id,
        kNg02Wichita,
      );
      // Nunca cae a un perfil de manzano (ap_), pera (pr_) ni durazno (dz_).
      expect(def.resolveProfile()!.id.startsWith('ng_'), isTrue);
    });
  });
}
