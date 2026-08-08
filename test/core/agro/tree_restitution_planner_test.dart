import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/tree_restitution_planner.dart';
import 'package:flutter_test/flutter_test.dart';

/// Congela el motor de restitución para perennes.
///
/// La prueba central de este archivo no comprueba aritmética: comprueba que
/// el resultado **cae dentro del rango que publica NMSU** para un manzano
/// real. Es la primera vez que un motor de BIO-G se valida contra una fuente
/// externa en todo su recorrido, de árbol joven a huerto maduro, en vez de en
/// un solo punto.
///
/// Los otros bloques congelan las cuatro correcciones que salieron de la
/// investigación. Cada una de ellas era un error que movía dinero real, y
/// ninguna debe volver a colarse sin que alguien lo decida a propósito.
void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // 1. VALIDACIÓN CONTRA FUENTE EXTERNA — el manzano frente a NMSU
  // ───────────────────────────────────────────────────────────────────────────

  group('Manzano · validación contra NMSU', () {
    /// New Mexico State University publica, por edad del árbol:
    ///   años 3–5   → ¼ a ⅓ lb de N por árbol  = 113 a 151 g
    ///   años 6–7   → ½ lb de N por árbol      = 227 g
    ///   maduros    → 150–200 lb N/acre        = 168–224 kg N/ha
    ///
    /// Un manzano de 40 kg de fruta es un árbol joven en producción; uno de
    /// 100 kg es un huerto maduro de buena carga. Si el motor está bien
    /// construido, debe caer dentro de ambos rangos **sin haberlos usado para
    /// calibrarse** — los coeficientes salen de medición de composición de
    /// fruta, no de las dosis de NMSU.
    test('árbol joven de 40 kg cae en el rango de años 3–5', () {
      final TreeRestitutionResult? r = TreeRestitutionPlanner.compute(
        nutrient: AgroMetricKey.n,
        cropKey: 'manzano',
        kgFruitPerTree: 40.0,
        soilLevel: SoilSupplyLevel.bajo,
      );

      expect(r, isNotNull);
      expect(
        r!.gramsPerTreeNutrient,
        inInclusiveRange(113.0, 151.0),
        reason: 'NMSU publica 113–151 g de N por árbol para años 3–5',
      );
      // Valor exacto congelado: 40 × 0.60 ÷ 0.38 × 1.5 ÷ 0.65
      expect(r.gramsPerTreeNutrient, closeTo(145.7, 1.0));
    });

    test('huerto maduro de 100 kg cae en el rango de árboles maduros', () {
      final TreeRestitutionResult? r = TreeRestitutionPlanner.compute(
        nutrient: AgroMetricKey.n,
        cropKey: 'manzano',
        kgFruitPerTree: 100.0,
        soilLevel: SoilSupplyLevel.bajo,
      );

      // 168–224 kg N/ha repartidos entre 500 árboles/ha = 336–448 g por árbol.
      expect(
        r!.gramsPerTreeNutrient,
        inInclusiveRange(336.0, 448.0),
        reason: 'NMSU publica 150–200 lb N/acre para huertos maduros',
      );
      expect(r.gramsPerTreeNutrient, closeTo(364.4, 1.0));
    });

    test('la dosis sube con la cosecha y baja con el suelo', () {
      double doseFor(double kg, SoilSupplyLevel soil) =>
          TreeRestitutionPlanner.compute(
            nutrient: AgroMetricKey.n,
            cropKey: 'manzano',
            kgFruitPerTree: kg,
            soilLevel: soil,
          )!.gramsPerTreeNutrient;

      // Más fruta, más dosis.
      expect(
        doseFor(80, SoilSupplyLevel.medio),
        greaterThan(doseFor(40, SoilSupplyLevel.medio)),
      );
      // Mejor suelo, menos dosis.
      expect(
        doseFor(40, SoilSupplyLevel.alto),
        lessThan(doseFor(40, SoilSupplyLevel.medio)),
      );
      expect(
        doseFor(40, SoilSupplyLevel.medio),
        lessThan(doseFor(40, SoilSupplyLevel.bajo)),
      );
    });

    test('entrega también el producto comercial', () {
      final TreeRestitutionResult r = TreeRestitutionPlanner.compute(
        nutrient: AgroMetricKey.n,
        cropKey: 'manzano',
        kgFruitPerTree: 40.0,
        soilLevel: SoilSupplyLevel.bajo,
      )!;

      expect(r.commercialSourceEs, contains('Urea'));
      // 145.7 g de N puro ÷ 0.46 de ley
      expect(r.gramsPerTreeCommercial, closeTo(316.8, 2.0));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 2. SEGUNDA VALIDACIÓN EXTERNA — el pistache, en el otro extremo
  // ───────────────────────────────────────────────────────────────────────────

  group('Pistache · validación contra UC ANR', () {
    /// El pistache es el caso opuesto al manzano: coeficiente de extracción
    /// 47 veces mayor, densidad de plantación mucho menor. Si el motor solo
    /// funcionara para pomáceas, aquí se rompería.
    ///
    /// UC ANR publica para año ON: 200–225 lb N/acre = 224–252 kg N/ha.
    /// A 120 árboles/ha —la densidad que cita la propia guía de BIO-G— son
    /// 1 870 a 2 100 g de N por árbol.
    test('árbol de 20 kg queda en el orden publicado por UC ANR', () {
      final TreeRestitutionResult? r = TreeRestitutionPlanner.compute(
        nutrient: AgroMetricKey.n,
        cropKey: 'pistache',
        kgFruitPerTree: 20.0,
        soilLevel: SoilSupplyLevel.medio,
      );

      expect(r, isNotNull);
      expect(
        r!.gramsPerTreeNutrient,
        inInclusiveRange(1700.0, 2600.0),
        reason: 'UC ANR sitúa el año ON en ~1 870–2 100 g de N por árbol',
      );
    });

    test('el pistache se mide en seco con cáscara, no en grano', () {
      final TreeExtractionCoefficients c =
          TreeRestitutionPlanner.coefficientsFor('pistache')!;
      expect(c.basis, TreeYieldBasis.secoConCascara);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 3. LAS CUATRO CORRECCIONES — que no vuelvan a entrar
  // ───────────────────────────────────────────────────────────────────────────

  group('Correcciones de la investigación', () {
    /// El documento interno decía 64 kg K₂O/t. UC Davis publica 29.
    /// El error se rastreó: «29 lb por 1000 lb» es una razón de masa, así que
    /// equivale a 29 kg/t sin convertir. Herogra multiplicó por 2.2046 solo el
    /// numerador — 29 × 2.2046 = 63.9 ≈ 64 — y en la misma página dejó el
    /// P₂O₅ en 7, sin convertir. Esa inconsistencia delata el error.
    ///
    /// Consecuencia práctica: se venía sobrefertilizando potasio 2.2 veces.
    test('pistache · K₂O es 29, no 64', () {
      final TreeExtractionCoefficients c =
          TreeRestitutionPlanner.coefficientsFor('pistache')!;
      expect(c.k2oKgPerTon, 29.0);
      expect(c.k2oKgPerTon, lessThan(40.0), reason: 'el 64 era un error de unidades');
      expect(c.p2o5KgPerTon, 7.0);
    });

    /// El documento interno traía «8–10 kg de N por cada 100 kg de nuez»
    /// = 80–100 kg N/t, tomado como extracción. Es la regla de dosis de UGA,
    /// no un coeficiente de remoción. La remoción real es ~10× menor: la
    /// almendra tiene 9.3 g de proteína por 100 g, y un estudio isotópico con
    /// ¹⁵N midió que la cosecha remueve el 4 % del N aplicado.
    test('nogal · N es ~9 kg/t, no 80–100', () {
      final TreeExtractionCoefficients c =
          TreeRestitutionPlanner.coefficientsFor('nogal')!;
      expect(c.nKgPerTon, closeTo(9.0, 1.5));
      expect(c.nKgPerTon, lessThan(20.0), reason: 'el 80–100 era una dosis, no extracción');
      expect(c.basis, TreeYieldBasis.nuezConCascara);
    });

    /// El documento interno traía 3.31 N / 1.41 P₂O₅ / 4.19 K₂O, que son
    /// 2–4× la remoción real. Es una dosis de INIA Chile («kg a aplicar por
    /// tonelada producida») usada como si fuera extracción. La propia Haifa
    /// publica la remoción: 1.2 N / 0.15 P / 2.5 K elemental.
    test('durazno · los coeficientes bajaron a la remoción real', () {
      final TreeExtractionCoefficients c =
          TreeRestitutionPlanner.coefficientsFor('durazno')!;
      expect(c.nKgPerTon, 1.30);
      expect(c.nKgPerTon, lessThan(2.0), reason: 'el 3.31 era una dosis');
      expect(c.k2oKgPerTon, 2.50);
    });

    /// El documento interno traía 0.42 kg de P por tonelada, pero la fuente
    /// real (Terra Latinoamericana, limón mexicano) dice 0.17. El 0.42 venía
    /// de otro paper, de limón persa: la fila mezclaba dos especies.
    test('limón · el fósforo bajó a la fuente correcta', () {
      final TreeExtractionCoefficients c =
          TreeRestitutionPlanner.coefficientsFor('limon')!;
      // 0.17 kg P elemental × 2.291 = 0.39 kg P₂O₅
      expect(c.p2o5KgPerTon, closeTo(0.39, 0.02));
      expect(c.nKgPerTon, 1.86, reason: 'el N sí coincidía con la fuente');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 4. INVARIANTES DE TODA LA TABLA
  // ───────────────────────────────────────────────────────────────────────────

  group('Invariantes de los nueve cultivos', () {
    const List<String> nueve = <String>[
      'manzano',
      'peral',
      'durazno',
      'nogal',
      'pistache',
      'naranjo',
      'limon',
      'mango',
      'aguacate',
    ];

    test('los nueve tienen coeficientes cargados', () {
      for (final String crop in nueve) {
        expect(
          TreeRestitutionPlanner.hasCoefficients(crop),
          isTrue,
          reason: 'falta el coeficiente de $crop',
        );
      }
    });

    /// En fruta fresca el potasio siempre supera al fósforo, casi siempre por
    /// mucho. Si esta invariante se rompe, lo más probable es que alguien
    /// cargó un valor elemental donde el código espera óxido, o al revés.
    ///
    /// El nogal queda fuera a propósito, y no por error: la nuez pecana es
    /// tan rica en fósforo que al pasar a óxidos (P × 2.291 contra K × 1.205)
    /// el P₂O₅ termina por encima del K₂O. Es química real, no una
    /// equivocación de unidades — comprobado contra la composición USDA de la
    /// almendra. Se prueba aparte, abajo.
    test('en fruta fresca el potasio supera al fósforo', () {
      for (final String crop in <String>['manzano', 'peral', 'durazno',
          'naranjo', 'limon', 'mango', 'aguacate', 'pistache']) {
        final TreeExtractionCoefficients c =
            TreeRestitutionPlanner.coefficientsFor(crop)!;
        expect(
          c.k2oKgPerTon,
          greaterThan(c.p2o5KgPerTon),
          reason: '$crop: K₂O (${c.k2oKgPerTon}) debería superar a P₂O₅ '
              '(${c.p2o5KgPerTon}); revisa si hay confusión elemental/óxido',
        );
      }
    });

    /// La excepción documentada, congelada para que nadie la "arregle".
    test('el nogal es la excepción: P₂O₅ por encima de K₂O', () {
      final TreeExtractionCoefficients c =
          TreeRestitutionPlanner.coefficientsFor('nogal')!;
      expect(
        c.p2o5KgPerTon,
        greaterThan(c.k2oKgPerTon),
        reason: 'la nuez pecana es rica en P; en óxidos el P₂O₅ rebasa al K₂O',
      );
      // 1.6 kg P elemental × 2.291 = 3.67 ; 2.3 kg K × 1.205 = 2.77
      expect(c.p2o5KgPerTon, closeTo(3.67, 0.05));
      expect(c.k2oKgPerTon, closeTo(2.77, 0.05));
    });

    test('ningún coeficiente es cero ni negativo', () {
      for (final String crop in nueve) {
        final TreeExtractionCoefficients c =
            TreeRestitutionPlanner.coefficientsFor(crop)!;
        expect(c.nKgPerTon, greaterThan(0), reason: crop);
        expect(c.p2o5KgPerTon, greaterThan(0), reason: crop);
        expect(c.k2oKgPerTon, greaterThan(0), reason: crop);
      }
    });

    test('todos declaran fuente citable', () {
      for (final String crop in nueve) {
        final TreeExtractionCoefficients c =
            TreeRestitutionPlanner.coefficientsFor(crop)!;
        expect(c.sourceEs.length, greaterThan(10), reason: crop);
      }
    });

    /// Los frutales de fruta fresca se mueven en un orden de magnitud; las
    /// nueces, en otro. Mezclarlos sería señal de que alguien copió un
    /// coeficiente de la fila equivocada.
    test('las nueces y la fruta fresca no se confunden', () {
      for (final String crop in <String>['manzano', 'peral', 'durazno',
          'naranjo', 'limon', 'mango', 'aguacate']) {
        final TreeExtractionCoefficients c =
            TreeRestitutionPlanner.coefficientsFor(crop)!;
        expect(c.basis, TreeYieldBasis.frutaFresca, reason: crop);
        expect(c.nKgPerTon, lessThan(5.0), reason: '$crop es fruta fresca');
      }
      for (final String crop in <String>['nogal', 'pistache']) {
        final TreeExtractionCoefficients c =
            TreeRestitutionPlanner.coefficientsFor(crop)!;
        expect(c.nKgPerTon, greaterThan(5.0), reason: '$crop es nuez');
      }
    });

    test('todos producen una dosis con un árbol cargado y suelo bajo', () {
      for (final String crop in nueve) {
        for (final AgroMetricKey nut in <AgroMetricKey>[
          AgroMetricKey.n,
          AgroMetricKey.p,
          AgroMetricKey.k,
        ]) {
          final TreeRestitutionResult? r = TreeRestitutionPlanner.compute(
            nutrient: nut,
            cropKey: crop,
            kgFruitPerTree: 30.0,
            soilLevel: SoilSupplyLevel.bajo,
          );
          expect(r, isNotNull, reason: '$crop / ${nut.name} devolvió null');
          expect(r!.gramsPerTreeNutrient, greaterThan(0), reason: '$crop');
          expect(r.gramsPerTreeNutrient.isFinite, isTrue, reason: '$crop');
        }
      }
    });

    test('los alias humanos resuelven al mismo coeficiente', () {
      final TreeExtractionCoefficients base =
          TreeRestitutionPlanner.coefficientsFor('apple_tree')!;
      for (final String alias in <String>['manzano', 'manzana', 'apple', 'MANZANO']) {
        expect(
          TreeRestitutionPlanner.coefficientsFor(alias)!.nKgPerTon,
          base.nKgPerTon,
          reason: 'el alias "$alias" no resolvió a manzano',
        );
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 5. CUÁNDO EL MOTOR SE CALLA
  // ───────────────────────────────────────────────────────────────────────────

  group('El motor dice "no sé"', () {
    TreeRestitutionResult? call({
      String? crop = 'manzano',
      double? kg = 40.0,
      SoilSupplyLevel? soil = SoilSupplyLevel.bajo,
      AgroMetricKey nutrient = AgroMetricKey.n,
    }) {
      return TreeRestitutionPlanner.compute(
        nutrient: nutrient,
        cropKey: crop,
        kgFruitPerTree: kg,
        soilLevel: soil,
      );
    }

    test('cultivo que no es árbol', () {
      expect(call(crop: 'maize'), isNull);
      expect(call(crop: 'frijol'), isNull);
      expect(call(crop: null), isNull);
      expect(call(crop: '   '), isNull);
    });

    test('sin cosecha esperada no hay dosis', () {
      expect(call(kg: null), isNull);
      expect(call(kg: 0), isNull);
      expect(call(kg: -5), isNull);
      expect(call(kg: double.nan), isNull);
      expect(call(kg: double.infinity), isNull);
    });

    test('sin nivel de suelo no hay dosis', () {
      expect(call(soil: null), isNull);
    });

    /// Regla textual de la guía de pera: «si el nivel es muy alto, no aportar».
    test('suelo muy alto ⇒ dosis cero, expresada como ausencia', () {
      expect(call(soil: SoilSupplyLevel.muyAlto), isNull);
    });

    test('nutriente que no es N, P ni K', () {
      expect(call(nutrient: AgroMetricKey.ph), isNull);
      expect(call(nutrient: AgroMetricKey.ec), isNull);
      expect(call(nutrient: AgroMetricKey.soilMoisture), isNull);
    });

    test('una cosecha diminuta no genera una dosis fingida', () {
      // Un árbol de 100 g de fruta no merece una recomendación de fósforo.
      expect(call(kg: 0.1, nutrient: AgroMetricKey.p), isNull);
    });

    test('etiqueta desconocida no se traduce a nivel de suelo', () {
      expect(
        TreeRestitutionPlanner.soilLevelFor(NutrientPriorityLabel.unknown),
        isNull,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 6. TRADUCCIÓN DE LA ETIQUETA DEL MOTOR AL NIVEL DE SUELO
  // ───────────────────────────────────────────────────────────────────────────

  group('Etiqueta del motor → nivel de suelo', () {
    test('acción recomendada y prioridad alta ⇒ suelo bajo', () {
      expect(
        TreeRestitutionPlanner.soilLevelFor(NutrientPriorityLabel.actionRecommended),
        SoilSupplyLevel.bajo,
      );
      expect(
        TreeRestitutionPlanner.soilLevelFor(NutrientPriorityLabel.highPriority),
        SoilSupplyLevel.bajo,
      );
    });

    test('posible exceso ⇒ suelo alto; acumulación ⇒ muy alto', () {
      expect(
        TreeRestitutionPlanner.soilLevelFor(NutrientPriorityLabel.possibleExcess),
        SoilSupplyLevel.alto,
      );
      expect(
        TreeRestitutionPlanner.soilLevelFor(NutrientPriorityLabel.reviewAccumulation),
        SoilSupplyLevel.muyAlto,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 7. PRESENTACIÓN
  // ───────────────────────────────────────────────────────────────────────────

  group('Presentación del número', () {
    test('el redondeo no finge precisión que el número no tiene', () {
      expect(TreeRestitutionPlanner.roundForDisplay(47.3), 45);
      expect(TreeRestitutionPlanner.roundForDisplay(48.0), 50);
      expect(TreeRestitutionPlanner.roundForDisplay(316.8), 320);
      expect(TreeRestitutionPlanner.roundForDisplay(2267.0), 2250);
    });

    test('el texto de transparencia declara cosecha, coeficiente y fuente', () {
      final TreeRestitutionResult r = TreeRestitutionPlanner.compute(
        nutrient: AgroMetricKey.n,
        cropKey: 'manzano',
        kgFruitPerTree: 40.0,
        soilLevel: SoilSupplyLevel.bajo,
      )!;

      expect(r.transparencyEs, contains('40 kg'));
      expect(r.transparencyEs, contains('0.60 kg/t'));
      expect(r.transparencyEs, contains('WSU'));
      expect(r.transparencyEs, contains('150 %'));
    });

    test('el kg/ha solo aparece si se conoce la densidad', () {
      final TreeRestitutionResult r = TreeRestitutionPlanner.compute(
        nutrient: AgroMetricKey.n,
        cropKey: 'manzano',
        kgFruitPerTree: 40.0,
        soilLevel: SoilSupplyLevel.bajo,
      )!;

      expect(r.kgPerHectare(null), isNull);
      expect(r.kgPerHectare(0), isNull);
      // 145.7 g × 500 árboles ÷ 1000 = 72.9 kg/ha
      expect(r.kgPerHectare(500), closeTo(72.9, 1.0));
    });
  });
}
