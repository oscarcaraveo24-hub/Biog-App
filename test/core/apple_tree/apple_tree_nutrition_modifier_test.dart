// test/core/apple_tree/apple_tree_nutrition_modifier_test.dart

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/apple_tree_nutrition_modifier.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

const _profileIds = <String>[
  kApSkip,
  kAp01Golden,
  kAp02Red,
  kAp03CriollaRayada,
  kAp04Gala,
  kAp05LowChill,
];

void _expectNoHarvestLanguage(String text) {
  expect(text, isNot(contains('cosecha')));
  expect(text, isNot(contains('madurez')));
  expect(text, isNot(contains('retrase')));
}

void main() {
  group('AppleTreeNutritionModifier UX por etapa', () {
    test('Golden separa llenado de madurez/cosecha en copy práctico', () {
      final golden = resolveAppleTreeNutritionModifier(profileId: kAp01Golden);

      final fruitFill = golden
          .practicalCaution(AgroMetricKey.n, TreeStageIds.fruitFill)
          .toLowerCase();
      final harvest = golden
          .practicalCaution(AgroMetricKey.n, TreeStageIds.harvestMaturity)
          .toLowerCase();

      expect(fruitFill, contains('llenado'));
      expect(fruitFill, contains('calibre'));
      expect(fruitFill, contains('acabado'));
      expect(fruitFill, contains('firmeza'));
      expect(fruitFill, contains('balance n-k-ca/mg'));
      expect(fruitFill, contains('vigor vegetativo'));
      _expectNoHarvestLanguage(fruitFill);

      expect(harvest, contains('madurez/cosecha'));
      expect(harvest, contains('retrase madurez'));
      expect(harvest, contains('color'));
      expect(harvest, contains('azúcar'));
      expect(harvest, contains('firmeza final'));
      expect(harvest, contains('almacenamiento'));
      expect(fruitFill, isNot(harvest));
    });

    test('todos los perfiles separan N en fruit_fill vs harvest_maturity', () {
      for (final profileId in _profileIds) {
        final modifier = resolveAppleTreeNutritionModifier(profileId: profileId);
        final fruitFill = modifier
            .practicalCaution(AgroMetricKey.n, TreeStageIds.fruitFill)
            .toLowerCase();
        final harvest = modifier
            .practicalCaution(AgroMetricKey.n, TreeStageIds.harvestMaturity)
            .toLowerCase();

        expect(fruitFill, contains('llenado'), reason: profileId);
        expect(fruitFill, contains('calibre'), reason: profileId);
        expect(fruitFill, contains('firmeza'), reason: profileId);
        _expectNoHarvestLanguage(fruitFill);

        expect(harvest, anyOf(contains('madurez'), contains('cosecha')));
        expect(
          harvest,
          anyOf(
            contains('color'),
            contains('azúcares'),
            contains('firmeza final'),
            contains('almacenamiento'),
            contains('anaquel'),
          ),
          reason: profileId,
        );
        expect(fruitFill, isNot(harvest), reason: profileId);
      }
    });

    test('K en fruit_fill no hereda copy de N alto ni de cosecha', () {
      for (final profileId in _profileIds) {
        final copy = resolveAppleTreeNutritionModifier(profileId: profileId)
            .practicalCaution(AgroMetricKey.k, TreeStageIds.fruitFill)
            .toLowerCase();

        expect(copy, contains('llenado'), reason: profileId);
        expect(copy, contains('k'), reason: profileId);
        expect(copy, contains('calibre'), reason: profileId);
        expect(copy, contains('firmeza'), reason: profileId);
        expect(copy, contains('ca/mg'), reason: profileId);
        expect(copy, isNot(contains('n alto')), reason: profileId);
        _expectNoHarvestLanguage(copy);
      }
    });

    test('P usa cautela de disponibilidad y no copy de N/K', () {
      for (final profileId in _profileIds) {
        final copy = resolveAppleTreeNutritionModifier(profileId: profileId)
            .practicalCaution(AgroMetricKey.p, TreeStageIds.fruitFill)
            .toLowerCase();

        expect(copy, contains('p'), reason: profileId);
        expect(copy, anyOf(contains('ph'), contains('disponibilidad')));
        expect(copy, isNot(contains('n alto')), reason: profileId);
        expect(copy, isNot(contains('k sostiene')), reason: profileId);
        expect(copy, isNot(contains('cosecha')), reason: profileId);
      }
    });
  });
}
