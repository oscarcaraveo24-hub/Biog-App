// test/core/crops/tree_profile_presentation_test.dart
//
// UX de arboles: el productor ve nombres humanos de variedad (no codigos
// PR-/AP-/DZ-/SKIP ni "Perfil"), el perfil general/SKIP queda AL FINAL y la
// pregunta del selector habla de "variedad de manzano/peral/duraznero".

import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_profile_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Etiquetas humanas de variedad', () {
    test('Pera: perfiles PR resuelven a nombre humano', () {
      expect(
        TreeProfilePresentation.displayLabel(CropCatalog.pearTreeCropId, kPrSkip),
        'No sé / Pera general',
      );
      expect(
        TreeProfilePresentation.displayLabel(
          CropCatalog.pearTreeCropId,
          kPr01BartlettWilliams,
        ),
        'Bartlett / Williams',
      );
      expect(
        TreeProfilePresentation.displayLabel(CropCatalog.pearTreeCropId, kPr03Bosc),
        'Bosc',
      );
    });

    test('Manzano: perfiles AP resuelven a nombre humano', () {
      expect(
        TreeProfilePresentation.displayLabel(CropCatalog.appleTreeCropId, kApSkip),
        'No sé / Manzano general',
      );
      expect(
        TreeProfilePresentation.displayLabel(CropCatalog.appleTreeCropId, kAp01Golden),
        'Golden',
      );
      expect(
        TreeProfilePresentation.displayLabel(CropCatalog.appleTreeCropId, kAp02Red),
        'Red Delicious / Roja',
      );
    });

    test('Durazno: perfiles DZ resuelven a nombre humano', () {
      expect(
        TreeProfilePresentation.displayLabel(CropCatalog.peachTreeCropId, kDzSkip),
        'No sé / Durazno general',
      );
      expect(
        TreeProfilePresentation.displayLabel(
          CropCatalog.peachTreeCropId,
          kDz01CriolloRegional,
        ),
        'Criollo / regional',
      );
      expect(
        TreeProfilePresentation.displayLabel(
          CropCatalog.peachTreeCropId,
          kDz03AmarilloComercial,
        ),
        'Amarillo comercial',
      );
    });

    test('ningun label visible de arbol contiene codigos internos', () {
      for (final cropId in <String>[
        CropCatalog.pearTreeCropId,
        CropCatalog.appleTreeCropId,
        CropCatalog.peachTreeCropId,
      ]) {
        for (final p in CropCatalog.profilesForCrop(cropId)) {
          final label = TreeProfilePresentation.displayLabel(
            cropId,
            p.id,
            fallbackLabel: p.label,
          );
          expect(label, isNot(contains('PR-')), reason: '${p.id}: $label');
          expect(label, isNot(contains('AP-')), reason: '${p.id}: $label');
          expect(label, isNot(contains('DZ-')), reason: '${p.id}: $label');
          expect(label.toUpperCase(), isNot(contains('SKIP')), reason: p.id);
          expect(label.toLowerCase(), isNot(contains('perfil')), reason: p.id);
        }
      }
    });
  });

  group('Perfil general/SKIP va al final', () {
    test('Pera: PR-SKIP es la ultima opcion', () {
      final ordered = TreeProfilePresentation.genericLast(
        CropCatalog.profilesForCrop(CropCatalog.pearTreeCropId),
        CropCatalog.pearTreeCropId,
      );
      expect(ordered.last.id, kPrSkip);
      expect(ordered.first.id, isNot(kPrSkip));
      expect(ordered.map((CropProfileEntry e) => e.id), contains(kPr01BartlettWilliams));
    });

    test('Manzano: AP-SKIP es la ultima opcion', () {
      final ordered = TreeProfilePresentation.genericLast(
        CropCatalog.profilesForCrop(CropCatalog.appleTreeCropId),
        CropCatalog.appleTreeCropId,
      );
      expect(ordered.last.id, kApSkip);
      expect(ordered.first.id, isNot(kApSkip));
    });

    test('Durazno: DZ-SKIP es la ultima opcion', () {
      final ordered = TreeProfilePresentation.genericLast(
        CropCatalog.profilesForCrop(CropCatalog.peachTreeCropId),
        CropCatalog.peachTreeCropId,
      );
      expect(ordered.last.id, kDzSkip);
      expect(ordered.first.id, isNot(kDzSkip));
      expect(ordered.map((CropProfileEntry e) => e.id), contains(kDz03AmarilloComercial));
    });
  });

  group('Pregunta humana del selector de variedad', () {
    test('arboles usan "Que variedad de ... tienes?"', () {
      expect(
        TreeProfilePresentation.varietyQuestion(CropCatalog.pearTreeCropId),
        '¿Qué variedad de peral tienes?',
      );
      expect(
        TreeProfilePresentation.varietyQuestion(CropCatalog.appleTreeCropId),
        '¿Qué variedad de manzano tienes?',
      );
      expect(
        TreeProfilePresentation.varietyQuestion(CropCatalog.peachTreeCropId),
        '¿Qué variedad de duraznero tienes?',
      );
      expect(
        TreeProfilePresentation.varietyQuestion('pera'),
        '¿Qué variedad de peral tienes?',
      );
    });
  });

  group('Aliases humanos de arbol', () {
    test('CropRegistry.byKeyName reconoce pera/peral', () {
      final pear = CropRegistry.byKey(CropKey.pearTree);
      expect(CropRegistry.byKeyName('pera'), same(pear));
      expect(CropRegistry.byKeyName('peral'), same(pear));
      expect(CropRegistry.byKeyName('pear'), same(pear));
    });

    test('CropRegistry.byKeyName reconoce manzano/manzana', () {
      final apple = CropRegistry.byKey(CropKey.appleTree);
      expect(CropRegistry.byKeyName('manzano'), same(apple));
      expect(CropRegistry.byKeyName('manzana'), same(apple));
    });

    test('CropRegistry.byKeyName reconoce durazno/duraznero/peach', () {
      final peach = CropRegistry.byKey(CropKey.peachTree);
      expect(CropRegistry.byKeyName('durazno'), same(peach));
      expect(CropRegistry.byKeyName('duraznero'), same(peach));
      expect(CropRegistry.byKeyName('peach'), same(peach));
      expect(CropRegistry.byKeyName('peachtree'), same(peach));
    });
  });
}
