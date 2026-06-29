// test/core/peach_tree/peach_tree_catalog_test.dart
//
// Catálogo, aliases, SKIP, migración y alta en registry/catalog del Durazno.
// Reglas: DZ-SKIP es general/migrable; nectarina/pelón/pavía NO inventan DZ-06;
// el alias legacy `peach_tree` resuelve al cropId canónico `crop_peach_tree`.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_crop_definition.dart';
import 'package:bio_g/core/crops/tree_profile_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Alta en catálogo y registry', () {
    test('crop_peach_tree existe y es categoría tree', () {
      final crop = CropCatalog.cropById(kCropPeachTree);
      expect(crop, isNotNull);
      expect(crop!.categoryId, CropCatalog.treeCategoryId);
      expect(crop.label, 'Durazno');
      expect(crop.defaultProfileId, kDzSkip);
    });

    test('cropId canónico + alias legacy + humanos resuelven a crop_peach_tree', () {
      for (final raw in <String>[
        'crop_peach_tree',
        'peach_tree',
        'peach',
        'peachtree',
        'durazno',
        'duraznero',
        'melocoton',
        'melocotón',
        'melocotonero',
        'Duraznos',
      ]) {
        expect(CropCatalog.canonicalCropKey(raw), kCropPeachTree, reason: raw);
      }
    });

    test('CropRegistry resuelve el durazno por key y por cropId/alias', () {
      expect(
        CropRegistry.byKey(CropKey.peachTree),
        isA<PeachTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('crop_peach_tree'),
        isA<PeachTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('peach_tree'),
        isA<PeachTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('peachtree'),
        isA<PeachTreeCropDefinition>(),
      );
      expect(CropRegistry.byKeyName('durazno'), isA<PeachTreeCropDefinition>());
    });

    test('el durazno NO contamina a manzano ni a pera', () {
      expect(
        CropCatalog.canonicalCropKey('manzano'),
        CropCatalog.appleTreeCropId,
      );
      expect(CropCatalog.canonicalCropKey('pera'), CropCatalog.pearTreeCropId);
      expect(CropCatalog.cropById('manzano')!.label, 'Manzano');
      expect(CropCatalog.cropById('pera')!.label, 'Pera');
    });
  });

  group('Perfiles DZ y resolución por alias', () {
    test('dz_skip existe, es el default y es genérico/migrable', () {
      final skip = CropCatalog.profileById(kCropPeachTree, kDzSkip);
      expect(skip, isNotNull);
      expect(CropCatalog.cropById(kCropPeachTree)!.defaultProfileId, kDzSkip);
    });

    test('dz_skip queda al final y las etiquetas visibles no filtran codigos', () {
      final profiles = CropCatalog.profilesForCrop(kCropPeachTree);
      expect(profiles.last.id, kDzSkip);

      final visibleLabels = profiles
          .map(
            (p) => TreeProfilePresentation.displayLabel(
              kCropPeachTree,
              p.id,
              fallbackLabel: p.label,
            ),
          )
          .toList();
      final joined = visibleLabels.join(' ');

      expect(visibleLabels.last, 'No sé / Durazno general');
      expect(joined, isNot(contains('DZ-')));
      expect(joined, isNot(contains('DZ-SKIP')));
      expect(joined, isNot(contains('dz_')));
      expect(joined, isNot(contains('SKIP')));
    });

    test('perfiles DZ-01..DZ-05 existen', () {
      for (final id in <String>[
        kDz01CriolloRegional,
        kDz02TempranoBajoFrio,
        kDz03AmarilloComercial,
        kDz04BlancoDulce,
        kDz05TardioIndustria,
      ]) {
        expect(CropCatalog.profileById(kCropPeachTree, id), isNotNull, reason: id);
      }
    });

    test('aliases comerciales resuelven al perfil correcto', () {
      final cases = <String, String>{
        'criollo': kDz01CriolloRegional,
        'regional': kDz01CriolloRegional,
        'tradicional': kDz01CriolloRegional,
        'bajo frio': kDz02TempranoBajoFrio,
        'temprano': kDz02TempranoBajoFrio,
        'Flordaprince': kDz02TempranoBajoFrio,
        'amarillo comercial': kDz03AmarilloComercial,
        'Redhaven': kDz03AmarilloComercial,
        'blanco': kDz04BlancoDulce,
        'dulce': kDz04BlancoDulce,
        'donut': kDz04BlancoDulce,
        'tardio': kDz05TardioIndustria,
        'industria': kDz05TardioIndustria,
        'conserva': kDz05TardioIndustria,
      };
      cases.forEach((alias, expectedId) {
        final profile = CropCatalog.profileByAny(kCropPeachTree, alias);
        expect(profile?.id, expectedId, reason: alias);
      });
    });

    test('nectarina / pelón / pavía NO inventan DZ-06: caen a dz_skip', () {
      for (final raw in <String>['Nectarina', 'Pelon', 'Pavia', 'Durazno sin pelusa']) {
        final profile = CropCatalog.profileByAny(kCropPeachTree, raw);
        expect(profile?.id, kDzSkip, reason: raw);
      }
    });

    test('CropDefinition.resolveProfile usa dz_skip como fallback', () {
      final def = PeachTreeCropDefinition();
      expect(def.resolveProfile(profileId: 'no_existe')!.id, kDzSkip);
      expect(
        def.resolveProfile(varietyAlias: 'criollo')!.id,
        kDz01CriolloRegional,
      );
      // Nunca cae a un perfil de manzano (ap_) ni de pera (pr_).
      expect(def.resolveProfile()!.id.startsWith('dz_'), isTrue);
    });
  });
}
