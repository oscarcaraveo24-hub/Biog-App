// test/core/orange_tree/orange_tree_catalog_test.dart
//
// Catalogo, aliases, SKIP, migracion y alta en registry/catalog del Naranjo.
// Reglas: OR-SKIP es general/migrable; naranjo/naranja NO inventan OR-06; el
// alias legacy `orange_tree` resuelve al cropId canonico `crop_orange_tree`. El
// fallback NUNCA cae a manzano/pera/durazno/nogal/pistache.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_catalog.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_crop_definition.dart';
import 'package:bio_g/core/crops/tree_profile_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Alta en catalogo y registry', () {
    test('crop_orange_tree existe y es categoria tree', () {
      final crop = CropCatalog.cropById(kCropOrangeTree);
      expect(crop, isNotNull);
      expect(crop!.categoryId, CropCatalog.treeCategoryId);
      expect(crop.label, 'Naranjo');
      expect(crop.defaultProfileId, kOrSkip);
    });

    test(
      'cropId canonico + alias legacy + humanos resuelven a crop_orange_tree',
      () {
        for (final raw in <String>[
          'crop_orange_tree',
          'orange_tree',
          'orange',
          'orangetree',
          'naranjo',
          'naranja',
          'naranja dulce',
          'sweet orange',
          'Naranjas',
        ]) {
          expect(
            CropCatalog.canonicalCropKey(raw),
            kCropOrangeTree,
            reason: raw,
          );
        }
      },
    );

    test('CropRegistry resuelve el naranjo por key y por cropId/alias', () {
      expect(
        CropRegistry.byKey(CropKey.orangeTree),
        isA<OrangeTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('crop_orange_tree'),
        isA<OrangeTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('orange_tree'),
        isA<OrangeTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('naranjo'),
        isA<OrangeTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('naranja'),
        isA<OrangeTreeCropDefinition>(),
      );
    });

    test('el naranjo NO contamina a los demas arboles', () {
      expect(
        CropCatalog.canonicalCropKey('manzano'),
        CropCatalog.appleTreeCropId,
      );
      expect(CropCatalog.canonicalCropKey('pera'), CropCatalog.pearTreeCropId);
      expect(
        CropCatalog.canonicalCropKey('durazno'),
        CropCatalog.peachTreeCropId,
      );
      expect(CropCatalog.canonicalCropKey('nogal'), CropCatalog.walnutTreeCropId);
      expect(
        CropCatalog.canonicalCropKey('pistache'),
        CropCatalog.pistachioTreeCropId,
      );
      expect(CropCatalog.cropById('pistache')!.label, 'Pistache');
    });
  });

  group('Perfiles OR y resolucion por alias', () {
    test('or_skip existe, es el default y es generico/migrable', () {
      final skip = CropCatalog.profileById(kCropOrangeTree, kOrSkip);
      expect(skip, isNotNull);
      expect(
        CropCatalog.cropById(kCropOrangeTree)!.defaultProfileId,
        kOrSkip,
      );
    });

    test(
      'or_skip queda al final y las etiquetas visibles no filtran codigos',
      () {
        final profiles = CropCatalog.profilesForCrop(kCropOrangeTree);
        expect(profiles.last.id, kOrSkip);

        final visibleLabels = profiles
            .map(
              (p) => TreeProfilePresentation.displayLabel(
                kCropOrangeTree,
                p.id,
                fallbackLabel: p.label,
              ),
            )
            .toList();
        final joined = visibleLabels.join(' ');

        expect(visibleLabels.last, 'No sé / Naranjo general');
        expect(joined, isNot(contains('OR-')));
        expect(joined, isNot(contains('OR-SKIP')));
        expect(joined, isNot(contains('or_')));
        expect(joined, isNot(contains('SKIP')));
      },
    );

    test('perfiles OR-01..OR-05 existen', () {
      for (final id in <String>[
        kOr01Valencia,
        kOr02Navel,
        kOr03Temprano,
        kOr04CriolloRegional,
        kOr05TropicalCalido,
      ]) {
        expect(
          CropCatalog.profileById(kCropOrangeTree, id),
          isNotNull,
          reason: id,
        );
      }
    });

    test('aliases comerciales resuelven al perfil correcto', () {
      final cases = <String, String>{
        'valencia': kOr01Valencia,
        'valencia late': kOr01Valencia,
        'naranja para jugo': kOr01Valencia,
        'navel': kOr02Navel,
        'washington navel': kOr02Navel,
        'naranja de ombligo': kOr02Navel,
        'hamlin': kOr03Temprano,
        'pineapple': kOr03Temprano,
        'temprana': kOr03Temprano,
        'criolla': kOr04CriolloRegional,
        'huerto viejo': kOr04CriolloRegional,
        'tropical': kOr05TropicalCalido,
        'clima calido': kOr05TropicalCalido,
        // Migracion de ids previos de los docs 01/03 (no romper historial).
        'or_01_valencia_tardia': kOr01Valencia,
        'or_02_navel_mesa': kOr02Navel,
        'or_03_temprano_hamlin_pineapple': kOr03Temprano,
      };
      cases.forEach((alias, expectedId) {
        final profile = CropCatalog.profileByAny(kCropOrangeTree, alias);
        expect(profile?.id, expectedId, reason: alias);
      });
    });

    test('naranjo / naranja genericos NO inventan OR-06: caen a or_skip', () {
      for (final raw in <String>[
        'Naranjo',
        'Naranja',
        'Naranjo general',
        'Naranja comun',
      ]) {
        final profile = CropCatalog.profileByAny(kCropOrangeTree, raw);
        expect(profile?.id, kOrSkip, reason: raw);
      }
    });

    test('CropDefinition.resolveProfile usa or_skip como fallback', () {
      final def = OrangeTreeCropDefinition();
      expect(def.resolveProfile(profileId: 'no_existe')!.id, kOrSkip);
      expect(
        def.resolveProfile(varietyAlias: 'navel')!.id,
        kOr02Navel,
      );
      // Nunca cae a un perfil de manzano (ap_), pera (pr_), durazno (dz_),
      // nogal (ng_) ni pistache (ps_).
      expect(def.resolveProfile()!.id.startsWith('or_'), isTrue);
    });
  });
}
