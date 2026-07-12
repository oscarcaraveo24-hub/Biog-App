// test/core/lemon_tree/lemon_tree_catalog_test.dart
//
// Catalogo, aliases, SKIP, migracion y alta en registry/catalog del Limon.
// Reglas: LM-SKIP es general/migrable; limon/limonero NO inventan LM-06; los
// alias legacy `lemon_tree`/`lime_tree`/`lime` resuelven al cropId canonico
// `crop_lemon_tree`. El fallback NUNCA cae a manzano/pera/durazno/nogal/
// pistache ni NARANJO (el limon NO es un naranjo pequeno).

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_catalog.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_crop_definition.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_crop_definition.dart';
import 'package:bio_g/core/crops/tree_profile_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Alta en catalogo y registry', () {
    test('crop_lemon_tree existe y es categoria tree', () {
      final crop = CropCatalog.cropById(kCropLemonTree);
      expect(crop, isNotNull);
      expect(crop!.categoryId, CropCatalog.treeCategoryId);
      expect(crop.label, 'Limón');
      expect(crop.defaultProfileId, kLmSkip);
    });

    test(
      'cropId canonico + alias legacy (lime) + humanos resuelven a '
      'crop_lemon_tree',
      () {
        for (final raw in <String>[
          'crop_lemon_tree',
          'lemon_tree',
          'lemon',
          'lemontree',
          'crop_lime_tree',
          'lime_tree',
          'lime',
          'limon',
          'limón',
          'limonero',
          'lima',
          'Limones',
          'limón persa',
          'limon mexicano',
        ]) {
          expect(
            CropCatalog.canonicalCropKey(raw),
            kCropLemonTree,
            reason: raw,
          );
        }
      },
    );

    test('CropRegistry resuelve el limon por key y por cropId/alias', () {
      expect(
        CropRegistry.byKey(CropKey.lemonTree),
        isA<LemonTreeCropDefinition>(),
      );
      for (final raw in <String>[
        'crop_lemon_tree',
        'lemon_tree',
        'lime_tree',
        'limon',
        'limonero',
        'lima',
      ]) {
        expect(
          CropRegistry.byKeyName(raw),
          isA<LemonTreeCropDefinition>(),
          reason: raw,
        );
      }
    });

    test('el limon NO se confunde con el naranjo ni contamina otros arboles', () {
      // Limon y naranjo son cultivos distintos (NO naranjo pequeno).
      expect(
        CropCatalog.canonicalCropKey('naranjo'),
        CropCatalog.orangeTreeCropId,
      );
      expect(
        CropCatalog.canonicalCropKey('limonero'),
        CropCatalog.lemonTreeCropId,
      );
      expect(
        CropRegistry.byKeyName('naranjo'),
        isA<OrangeTreeCropDefinition>(),
      );
      expect(
        CropRegistry.byKeyName('limon'),
        isA<LemonTreeCropDefinition>(),
      );
      expect(
        CropCatalog.canonicalCropKey('manzano'),
        CropCatalog.appleTreeCropId,
      );
      expect(CropCatalog.canonicalCropKey('pera'), CropCatalog.pearTreeCropId);
    });
  });

  group('Perfiles LM y resolucion por alias', () {
    test('lm_skip existe, es el default y es generico/migrable', () {
      final skip = CropCatalog.profileById(kCropLemonTree, kLmSkip);
      expect(skip, isNotNull);
      expect(
        CropCatalog.cropById(kCropLemonTree)!.defaultProfileId,
        kLmSkip,
      );
    });

    test(
      'lm_skip queda al final y las etiquetas visibles no filtran codigos',
      () {
        final profiles = CropCatalog.profilesForCrop(kCropLemonTree);
        expect(profiles.last.id, kLmSkip);

        final visibleLabels = profiles
            .map(
              (p) => TreeProfilePresentation.displayLabel(
                kCropLemonTree,
                p.id,
                fallbackLabel: p.label,
              ),
            )
            .toList();
        final joined = visibleLabels.join(' ');

        expect(visibleLabels.last, 'No sé / Limón general');
        expect(joined, isNot(contains('LM-')));
        expect(joined, isNot(contains('LM-SKIP')));
        expect(joined, isNot(contains('lm_')));
        expect(joined, isNot(contains('SKIP')));
      },
    );

    test('perfiles LM-01..LM-05 existen', () {
      for (final id in <String>[
        kLm01PersaTahiti,
        kLm02MexicanoColima,
        kLm03AmarilloEurekaLisbon,
        kLm04TropicalContinuo,
        kLm05DesfaseInducido,
      ]) {
        expect(
          CropCatalog.profileById(kCropLemonTree, id),
          isNotNull,
          reason: id,
        );
      }
    });

    test('aliases comerciales resuelven al perfil correcto', () {
      final cases = <String, String>{
        'persa': kLm01PersaTahiti,
        'tahiti': kLm01PersaTahiti,
        'persian lime': kLm01PersaTahiti,
        'limón sin semilla': kLm01PersaTahiti,
        'mexicano': kLm02MexicanoColima,
        'colima': kLm02MexicanoColima,
        'key lime': kLm02MexicanoColima,
        'limón agrio': kLm02MexicanoColima,
        'eureka': kLm03AmarilloEurekaLisbon,
        'lisbon': kLm03AmarilloEurekaLisbon,
        'limón amarillo': kLm03AmarilloEurekaLisbon,
        'tropical': kLm04TropicalContinuo,
        'producción continua': kLm04TropicalContinuo,
        'desfase': kLm05DesfaseInducido,
        'inducido': kLm05DesfaseInducido,
        // Migracion de ids previos de los docs 01/03 (no romper historial).
        'lm_01_persa': kLm01PersaTahiti,
        'lm_02_key_lime': kLm02MexicanoColima,
        'lm_03_eureka': kLm03AmarilloEurekaLisbon,
      };
      cases.forEach((alias, expectedId) {
        final profile = CropCatalog.profileByAny(kCropLemonTree, alias);
        expect(profile?.id, expectedId, reason: alias);
      });
    });

    test('limon / limonero genericos NO inventan LM-06: caen a lm_skip', () {
      for (final raw in <String>[
        'Limón',
        'Limonero',
        'Limón general',
        'limón común',
      ]) {
        final profile = CropCatalog.profileByAny(kCropLemonTree, raw);
        expect(profile?.id, kLmSkip, reason: raw);
      }
    });

    test('CropDefinition.resolveProfile usa lm_skip como fallback', () {
      final def = LemonTreeCropDefinition();
      expect(def.resolveProfile(profileId: 'no_existe')!.id, kLmSkip);
      expect(
        def.resolveProfile(varietyAlias: 'persa')!.id,
        kLm01PersaTahiti,
      );
      // Nunca cae a un perfil de otro arbol (ap_/pr_/dz_/ng_/ps_/or_).
      expect(def.resolveProfile()!.id.startsWith('lm_'), isTrue);
    });
  });
}
