// test/core/agro/nutrition/fertilizer_products_test.dart
//
// El agricultor no compra nitrógeno: compra sacos. Y el saco de fósforo trae
// nitrógeno dentro. Estas pruebas congelan el descuento que evita que la
// recomendación se pase justo donde más se notaba: la siembra de frijol.
import 'package:bio_g/core/agro/nutrition/fertilizer_products.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FertilizerProducts · equivalente comercial', () {
    test('traduce N puro a urea redondeando a múltiplos de 5', () {
      expect(
        FertilizerProducts.equivalentEs(
          form: NutrientForm.n,
          minKg: 107.2,
          maxKg: 160.8,
          sourceOptionsEs: const <String>['Urea (46-0-0)'],
        ),
        '≈ 235–350 kg/ha de urea',
      );
    });

    test('un plan con mínimo 0 se dice «hasta»', () {
      expect(
        FertilizerProducts.equivalentEs(
          form: NutrientForm.k2o,
          minKg: 0,
          maxKg: 60,
          sourceOptionsEs: const <String>['Cloruro de potasio (0-0-60)'],
        ),
        '≈ hasta 100 kg/ha de cloruro de potasio',
      );
    });
  });

  group('FertilizerProducts · nitrógeno de acompañamiento', () {
    // Siembra de frijol: la guía pide 18–36 kg N/ha y 40–60 de P₂O₅. El DAP
    // que cubre el fósforo trae 18 % de nitrógeno, así que casi cubre la
    // ventana por su cuenta.
    final CarriedNitrogen frijol = FertilizerProducts.nitrogenCarriedBy(
      const <FertilizerRequirement>[
        FertilizerRequirement(
          form: NutrientForm.p2o5,
          minKg: 40,
          maxKg: 60,
          sourceOptionsEs: <String>['DAP (18-46-0)', 'MAP (11-52-0)'],
        ),
        FertilizerRequirement(
          form: NutrientForm.k2o,
          minKg: 0,
          maxKg: 40,
          sourceOptionsEs: <String>['Sulfato de potasio (0-0-50)'],
        ),
      ],
    );

    test('suma el N del fosfatado y no el del potásico, que no lleva', () {
      expect(frijol.minKg, closeTo((40 / 0.46) * 0.18, 1e-9));
      expect(frijol.maxKg, closeTo((60 / 0.46) * 0.18, 1e-9));
      expect(frijol.sourcesEs, <String>['DAP']);
    });

    test('un producto sin nitrógeno no arrastra nada ni genera nota', () {
      final CarriedNitrogen sinN = FertilizerProducts.nitrogenCarriedBy(
        const <FertilizerRequirement>[
          FertilizerRequirement(
            form: NutrientForm.p2o5,
            minKg: 40,
            maxKg: 60,
            sourceOptionsEs: <String>['Superfosfato triple'],
          ),
        ],
      );
      expect(sinN.isEmpty, isTrue);
      expect(
        FertilizerProducts.carriedNitrogenNoteEs(
          carried: sinN,
          nitrogenMaxKg: 36,
          nitrogenSourceOptionsEs: const <String>['Urea (46-0-0)'],
        ),
        isNull,
      );
    });

    test('la urea de la siembra de frijol baja de 40–80 a 5–25 kg/ha', () {
      expect(
        FertilizerProducts.equivalentEs(
          form: NutrientForm.n,
          minKg: 18,
          maxKg: 36,
          sourceOptionsEs: const <String>['Urea (46-0-0)'],
        ),
        '≈ 40–80 kg/ha de urea',
        reason: 'sin descontar: lo que la app decía antes',
      );
      expect(
        FertilizerProducts.nitrogenEquivalentEs(
          minKg: 18,
          maxKg: 36,
          sourceOptionsEs: const <String>['Urea (46-0-0)'],
          carried: frijol,
        ),
        '≈ 5–25 kg/ha de urea',
      );
    });

    test('explica el descuento nombrando el producto que lo aporta', () {
      expect(
        FertilizerProducts.carriedNitrogenNoteEs(
          carried: frijol,
          nitrogenMaxKg: 36,
          nitrogenSourceOptionsEs: const <String>['Urea (46-0-0)'],
        ),
        'El DAP de esta aplicación ya aporta 16–23 kg/ha de nitrógeno; la '
        'cifra de urea de arriba ya lo tiene descontado.',
      );
    });

    test('si el acompañamiento cubre la ventana, no se pide nitrogenado', () {
      expect(
        FertilizerProducts.nitrogenEquivalentEs(
          minKg: 10,
          maxKg: 20,
          sourceOptionsEs: const <String>['Urea (46-0-0)'],
          carried: frijol,
        ),
        isNull,
      );
      expect(
        FertilizerProducts.carriedNitrogenNoteEs(
          carried: frijol,
          nitrogenMaxKg: 20,
          nitrogenSourceOptionsEs: const <String>['Urea (46-0-0)'],
        ),
        'El DAP de esta aplicación ya aporta 16–23 kg/ha de nitrógeno y cubre '
        'la ventana: no apliques nitrogenado aparte.',
      );
    });

    test('un arrastre menor al 10 % de la ventana no se descuenta', () {
      final CarriedNitrogen migaja = FertilizerProducts.nitrogenCarriedBy(
        const <FertilizerRequirement>[
          FertilizerRequirement(
            form: NutrientForm.p2o5,
            minKg: 2,
            maxKg: 4,
            sourceOptionsEs: <String>['MAP (11-52-0)'],
          ),
        ],
      );
      expect(FertilizerProducts.shouldNetNitrogen(migaja, 160), isFalse);
      expect(FertilizerProducts.shouldNetNitrogen(frijol, 36), isTrue);
    });
  });
}
