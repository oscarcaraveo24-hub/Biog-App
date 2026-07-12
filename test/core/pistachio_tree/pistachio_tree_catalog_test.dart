// test/core/pistachio_tree/pistachio_tree_catalog_test.dart
//
// Catalogo, aliases, SKIP, migracion y alta en registry/catalog del Pistache.
// Reglas: PS-SKIP es general/migrable; pistache/pistacho NO inventan PS-06; el
// alias legacy `pistachio_tree` resuelve al cropId canonico
// `crop_pistachio_tree`. El fallback NUNCA cae a manzano/pera/durazno/nogal.

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_catalog.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_crop_definition.dart';
import 'package:bio_g/core/crops/tree_profile_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Alta en catalogo y registry', () {
    test('crop_pistachio_tree existe y es categoria tree', () {
      final crop = CropCatalog.cropById(kCropPistachioTree);
      expect(crop, isNotNull);
      expect(crop!.categoryId, CropCatalog.treeCategoryId);
      expect(crop.label, 'Pistache');
      expect(crop.defaultProfileId, kPsSkip);
    });

    test(
      'cropId canonico + alias legacy + humanos resuelven a crop_pistachio_tree',
      () {
        for (final raw in <String>[
          'crop_pistachio_tree',
          'pistachio_tree',
          'pistachio',
          'pistachiotree',
          'pistache',
          'pistacho',
          'pistachero',
          'alfoncigo',
          'Pistaches',
        ]) {
          expect(
            CropCatalog.canonicalCropKey(raw),
            kCropPistachioTree,
            reason: raw,
          );
        }
      },
    );

    test('CropRegistry resuelve el pistache por key y por cropId/alias', () {
      expect(
        CropRegistry.byKey(CropKey.pistachioTree),
        isA<PistachioTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('crop_pistachio_tree'),
        isA<PistachioTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('pistachio_tree'),
        isA<PistachioTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('pistache'),
        isA<PistachioTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('pistacho'),
        isA<PistachioTreeCropDefinition>(),
      );
    });

    test('el pistache NO contamina a manzano, pera, durazno ni nogal', () {
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
      expect(CropCatalog.cropById('nogal')!.label, 'Nogal');
    });
  });

  group('Perfiles PS y resolucion por alias', () {
    test('ps_skip existe, es el default y es generico/migrable', () {
      final skip = CropCatalog.profileById(kCropPistachioTree, kPsSkip);
      expect(skip, isNotNull);
      expect(
        CropCatalog.cropById(kCropPistachioTree)!.defaultProfileId,
        kPsSkip,
      );
    });

    test(
      'ps_skip queda al final y las etiquetas visibles no filtran codigos',
      () {
        final profiles = CropCatalog.profilesForCrop(kCropPistachioTree);
        expect(profiles.last.id, kPsSkip);

        final visibleLabels = profiles
            .map(
              (p) => TreeProfilePresentation.displayLabel(
                kCropPistachioTree,
                p.id,
                fallbackLabel: p.label,
              ),
            )
            .toList();
        final joined = visibleLabels.join(' ');

        expect(visibleLabels.last, 'No sé / Pistache general');
        expect(joined, isNot(contains('PS-')));
        expect(joined, isNot(contains('PS-SKIP')));
        expect(joined, isNot(contains('ps_')));
        expect(joined, isNot(contains('SKIP')));
      },
    );

    test('perfiles PS-01..PS-05 existen', () {
      for (final id in <String>[
        kPs01KermanPeters,
        kPs02GoldenHillsRandy,
        kPs03LostHillsRandy,
        kPs04SiroraCompatible,
        kPs05LarnakaMateurLowChill,
      ]) {
        expect(
          CropCatalog.profileById(kCropPistachioTree, id),
          isNotNull,
          reason: id,
        );
      }
    });

    test('aliases comerciales resuelven al perfil correcto', () {
      final cases = <String, String>{
        'kerman': kPs01KermanPeters,
        'peters': kPs01KermanPeters,
        'kerman tradicional': kPs01KermanPeters,
        'golden hills': kPs02GoldenHillsRandy,
        'golden': kPs02GoldenHillsRandy,
        'randy': kPs02GoldenHillsRandy,
        'lost hills': kPs03LostHillsRandy,
        'calibre grande': kPs03LostHillsRandy,
        'sirora': kPs04SiroraCompatible,
        'larnaka': kPs05LarnakaMateurLowChill,
        'mateur': kPs05LarnakaMateurLowChill,
        'mediterraneo': kPs05LarnakaMateurLowChill,
        // Migracion de ids previos (no romper historial).
        'ps_01_kerman': kPs01KermanPeters,
        'ps_02_golden': kPs02GoldenHillsRandy,
        'ps_03_lost': kPs03LostHillsRandy,
      };
      cases.forEach((alias, expectedId) {
        final profile = CropCatalog.profileByAny(kCropPistachioTree, alias);
        expect(profile?.id, expectedId, reason: alias);
      });
    });

    test('pistache / pistacho genericos NO inventan PS-06: caen a ps_skip', () {
      for (final raw in <String>[
        'Pistache',
        'Pistacho',
        'Pistache general',
        'alfoncigo',
      ]) {
        final profile = CropCatalog.profileByAny(kCropPistachioTree, raw);
        expect(profile?.id, kPsSkip, reason: raw);
      }
    });

    test('CropDefinition.resolveProfile usa ps_skip como fallback', () {
      final def = PistachioTreeCropDefinition();
      expect(def.resolveProfile(profileId: 'no_existe')!.id, kPsSkip);
      expect(
        def.resolveProfile(varietyAlias: 'golden hills')!.id,
        kPs02GoldenHillsRandy,
      );
      // Nunca cae a un perfil de manzano (ap_), pera (pr_), durazno (dz_) ni
      // nogal (ng_).
      expect(def.resolveProfile()!.id.startsWith('ps_'), isTrue);
    });
  });
}
