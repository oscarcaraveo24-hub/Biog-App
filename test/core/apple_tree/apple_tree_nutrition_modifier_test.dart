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

      // `practicalCaution` es el MATIZ varietal que se concatena al final del
      // mensaje, no el mensaje entero. El balance N-K-Ca/Mg, el vigor y el
      // vocabulario de anaquel los aporta la guía de dosis y la recomendación
      // práctica del motor, que sí los llevan. Exigirlos aquí obligaba a
      // repetirlos en una sola línea y producía un texto redundante.
      expect(fruitFill, contains('llenado'));
      expect(fruitFill, contains('calibre'));
      expect(fruitFill, contains('acabado'));
      expect(fruitFill, contains('firmeza'));
      _expectNoHarvestLanguage(fruitFill);

      expect(harvest, contains('cosecha'));
      expect(harvest, contains('retrasa madurez'));
      expect(harvest, contains('firmeza'));
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
        _expectNoHarvestLanguage(fruitFill);

        // Lo que de verdad blinda esta prueba es que las dos etapas NO
        // compartan texto y que la de madurez se identifique como tal.
        expect(
          harvest,
          anyOf(contains('madurez'), contains('cosecha')),
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

        expect(copy, contains('k'), reason: profileId);
        expect(copy, contains('calibre'), reason: profileId);
        expect(copy, contains('firmeza'), reason: profileId);
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
        expect(
          copy,
          anyOf(contains('ph'), contains('disponibilidad')),
          reason: profileId,
        );
        expect(copy, isNot(contains('n alto')), reason: profileId);
        expect(copy, isNot(contains('k sostiene')), reason: profileId);
        expect(copy, isNot(contains('cosecha')), reason: profileId);
      }
    });
  });

  group('Anexo v1.5 · el matiz varietal respeta la identidad de etapa', () {
    // Caso de regresión textual del anexo: "Golden/Red/Gala + fruit_fill → el
    // matiz varietal debe hablar de llenado/calibre/calidad/balance, no de
    // cosecha". Red decía solo "en llenado evita sombra sobre el fruto".
    test('llenado habla de calibre, firmeza y balance en los seis perfiles', () {
      for (final profileId in _profileIds) {
        final copy = resolveAppleTreeNutritionModifier(profileId: profileId)
            .practicalCaution(AgroMetricKey.n, TreeStageIds.fruitFill)
            .toLowerCase();

        expect(copy, contains('llenado'), reason: profileId);
        expect(copy, contains('calibre'), reason: profileId);
        expect(copy, contains('firmeza'), reason: profileId);
        expect(copy, contains('balance'), reason: profileId);
        _expectNoHarvestLanguage(copy);
      }
    });

    // §9.3 punto 8: postcosecha conserva identidad de reservas y no se apaga
    // como fin de cultivo. Antes no tenía rama: caía al texto por defecto, el
    // MISMO que reposo. Es decir, se comunicaba como dormancia pasiva.
    test('postcosecha tiene identidad propia y no repite otras etapas', () {
      for (final profileId in _profileIds) {
        final modifier = resolveAppleTreeNutritionModifier(profileId: profileId);
        String copy(String stage) =>
            modifier.practicalCaution(AgroMetricKey.n, stage).toLowerCase();

        final postHarvest = copy(TreeStageIds.postHarvest);

        expect(
          postHarvest,
          anyOf(contains('reserva'), contains('hoja activa')),
          reason: profileId,
        );
        for (final otra in <String>[
          TreeStageIds.fruitFill,
          TreeStageIds.harvestMaturity,
          TreeStageIds.dormancy,
          TreeStageIds.fruitSet,
        ]) {
          expect(postHarvest, isNot(copy(otra)), reason: '$profileId vs $otra');
        }
      }
    });

    test('el agrupador de N tardío vive solo en el score, nunca en el texto', () {
      final golden = resolveAppleTreeNutritionModifier(profileId: kAp01Golden);

      // Una etapa no cerrada no hereda copy de ninguna etapa real.
      final desconocido = golden
          .practicalCaution(AgroMetricKey.n, 'fruit_fill_tardio')
          .toLowerCase();
      expect(desconocido, isNot(contains('llenado')));
      expect(desconocido, isNot(contains('cosecha')));

      // Y el agrupador fruit_fill||harvest_maturity sigue siendo solo penalización.
      expect(
        golden.lateNitrogenExcessPenaltyFactor(TreeStageIds.fruitFill),
        lessThan(1.0),
      );
      expect(
        golden.lateNitrogenExcessPenaltyFactor(TreeStageIds.harvestMaturity),
        lessThan(1.0),
      );
      expect(golden.lateNitrogenExcessPenaltyFactor(TreeStageIds.fruitSet), 1.0);
    });
  });
}
