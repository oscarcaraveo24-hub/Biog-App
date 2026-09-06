import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/dose_expression.dart';
import 'package:bio_g/core/agro/soil_reaction.dart';
import 'package:flutter_test/flutter_test.dart';

/// Congela dos capas que sobrevivieron al reset del motor NPK (Guía oficial
/// del nuevo motor nutricional v0.4):
///
///   1. **La unidad elegible.** Un rango en kilos de nutriente puro por
///      hectárea se dice en el idioma del productor. El número no cambia;
///      cambia cómo se dice.
///
///   2. **La reacción del suelo.** El pH ya viene en cada lectura, así que el
///      motor puede saber si el suelo es calcáreo sin preguntar nada y
///      alimentar las reglas 3R: colocación del fósforo y volatilización de
///      urea. Lo que YA NO hace es desplazar una banda objetivo de fósforo
///      para comparar la lectura cruda de la sonda: esa banda no existe.
void main() {

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. LA ARITMÉTICA DE LA CONVERSIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  group('Conversión de unidades', () {
    /// La misma fórmula que aparece literal en las guías de nogal y durazno:
    ///     plantas/ha = 10 000 ÷ (distancia hileras × distancia plantas)
    test('el marco de plantación da las plantas por hectárea', () {
      // Invernadero de tomate en alta densidad: hileras a 1.6 m, plantas a
      // 0.25 m ⇒ 25 000 plantas/ha.
      expect(
        DoseExpression.plantsPerHectareFromSpacing(
          rowSpacingM: 1.6,
          plantSpacingM: 0.25,
        ),
        closeTo(25000, 1),
      );
      // Durazno a 5 × 5 m ⇒ 400 árboles/ha. Cifra del propio documento.
      expect(
        DoseExpression.plantsPerHectareFromSpacing(
          rowSpacingM: 5.0,
          plantSpacingM: 5.0,
        ),
        closeTo(400, 1),
      );
      // Durazno a 4 × 1.5 m ⇒ 1 666. El mismo documento lo usa para mostrar
      // que la densidad cambia el gramaje por árbol cuatro veces.
      expect(
        DoseExpression.plantsPerHectareFromSpacing(
          rowSpacingM: 4.0,
          plantSpacingM: 1.5,
        ),
        closeTo(1666, 2),
      );
    });

    test('sin marco válido no inventa densidad', () {
      expect(
        DoseExpression.plantsPerHectareFromSpacing(
          rowSpacingM: null,
          plantSpacingM: 0.25,
        ),
        isNull,
      );
      expect(
        DoseExpression.plantsPerHectareFromSpacing(
          rowSpacingM: 0,
          plantSpacingM: 0.25,
        ),
        isNull,
      );
      expect(
        DoseExpression.plantsPerHectareFromSpacing(
          rowSpacingM: -3,
          plantSpacingM: 0.25,
        ),
        isNull,
      );
    });

    /// El caso que validó todo el diseño:
    ///   tomate de invernadero, 10 kg de fruto por planta, 4.5 kg N/t
    ///   ⇒ 45 g de N por planta
    ///   ⇒ 45 × 25 000 ÷ 1000 = 1 125 kg N/ha para 250 t/ha
    ///
    /// Haifa publica 676 kg N/ha para 150 t/ha, que escalado da 1 127.
    /// Los dos caminos cierran, y por eso el mismo motor sirve para
    /// invernadero.
    test('el caso de Haifa cuadra por los dos caminos', () {
      final double? gPorPlanta = DoseExpression.gramsPerPlant(
        kgPerHectare: 1125.0,
        plantsPerHectare: 25000.0,
      );
      expect(gPorPlanta, closeTo(45.0, 0.5));

      // Y de vuelta: 45 g × 25 000 plantas ÷ 1000 = 1 125 kg/ha.
      expect(45.0 * 25000 / 1000, closeTo(1125, 1));

      // Haifa: 676 kg N/ha para 150 t/ha, escalado a 250 t/ha.
      expect(676.0 * 250 / 150, closeTo(1127, 2));
    });

    test('1 kg/ha son 0.1 g/m²', () {
      expect(DoseExpression.gramsPerSquareMeter(240.0), closeTo(24.0, 0.001));
    });

    test('el redondeo no finge precisión', () {
      expect(DoseExpression.formatGrams(0.437), '0.44');
      expect(DoseExpression.formatGrams(4.37), '4.4');
      expect(DoseExpression.formatGrams(47.3), '45');
      expect(DoseExpression.formatGrams(316.8), '320');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. CUÁNDO SE HABLA POR PLANTA
  // ═══════════════════════════════════════════════════════════════════════════

  group('El idioma se elige, no se adivina', () {
    /// Hacen falta las dos cosas: que el productor fertirriegue **y** que se
    /// conozca la densidad. Con una sola no alcanza — sin densidad el número
    /// por planta sería inventado, y sin fertirriego el de campo abierto
    /// prefiere su kg/ha de siempre.
    test('fertirriego con densidad ⇒ por planta', () {
      const DoseContext ctx = DoseContext(
        method: ApplicationMethod.fertigation,
        plantsPerHectare: 25000,
      );
      expect(ctx.expressPerPlant, isTrue);

      final String? txt = DoseExpression.renderPerPlant(
        kgPerHectarePure: 100.0,
        nutrientOrSourceName: 'Nitrógeno puro',
        ctx: ctx,
      );
      // 100 kg/ha × 1000 ÷ 25 000 = 4 g por planta
      expect(txt, contains('4.0 g de Nitrógeno puro por planta'));
    });

    test('fertirriego sin densidad ⇒ no se expresa por planta', () {
      const DoseContext ctx =
          DoseContext(method: ApplicationMethod.fertigation);
      expect(ctx.expressPerPlant, isFalse);
      expect(
        DoseExpression.renderPerPlant(
          kgPerHectarePure: 100.0,
          nutrientOrSourceName: 'Nitrógeno puro',
          ctx: ctx,
        ),
        isNull,
      );
    });

    test('campo abierto con densidad ⇒ tampoco', () {
      const DoseContext ctx = DoseContext(
        method: ApplicationMethod.broadcast,
        plantsPerHectare: 25000,
      );
      expect(ctx.expressPerPlant, isFalse);
    });

    /// El fertirriego se maneja por día, no por ciclo. Haifa ni siquiera
    /// publica sus tablas de invernadero en totales: las publica en kg/ha/día
    /// por fase.
    test('con días de fase se agrega el número diario', () {
      const DoseContext ctx = DoseContext(
        method: ApplicationMethod.fertigation,
        plantsPerHectare: 25000,
        phaseDays: 10,
        phaseLabelEs: 'floración',
      );
      expect(ctx.expressPerDay, isTrue);

      final String? txt = DoseExpression.renderPerPlant(
        kgPerHectarePure: 100.0,
        nutrientOrSourceName: 'Nitrógeno puro',
        ctx: ctx,
      );
      expect(txt, contains('4.0 g de Nitrógeno puro por planta'));
      expect(txt, contains('0.40 g por planta al día'));
      expect(txt, contains('10 días de floración'));
    });

    test('los alias de método resuelven', () {
      for (final String a in <String>[
        'fertirriego',
        'goteo',
        'invernadero',
        'drip',
        'hidroponia',
      ]) {
        expect(applicationMethodFromId(a), ApplicationMethod.fertigation,
            reason: 'el alias "$a" debería ser fertirriego');
      }
      expect(applicationMethodFromId('voleo'), ApplicationMethod.broadcast);
      expect(applicationMethodFromId('a_mano'), ApplicationMethod.manual);
      expect(applicationMethodFromId(null), ApplicationMethod.unknown);
      expect(applicationMethodFromId('cualquier cosa'),
          ApplicationMethod.unknown);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. LA REACCIÓN DEL SUELO
  // ═══════════════════════════════════════════════════════════════════════════

  group('Reacción del suelo desde el pH', () {
    test('el corte está en 7.3 y es deliberadamente conservador', () {
      expect(soilReactionFromPh(5.8), SoilReaction.acidic);
      expect(soilReactionFromPh(6.4), SoilReaction.acidic);
      expect(soilReactionFromPh(6.5), SoilReaction.neutral);
      expect(soilReactionFromPh(7.2), SoilReaction.neutral);
      expect(soilReactionFromPh(7.3), SoilReaction.calcareous);
      expect(soilReactionFromPh(8.1), SoilReaction.calcareous);
    });

    test('sin pH utilizable no supone nada', () {
      expect(soilReactionFromPh(null), SoilReaction.unknown);
      expect(soilReactionFromPh(double.nan), SoilReaction.unknown);
      expect(soilReactionFromPh(0), SoilReaction.unknown);
      expect(soilReactionFromPh(15), SoilReaction.unknown);
    });

    test('la nota de fósforo solo aparece en calcáreo y solo para P', () {
      final String? p = soilReactionNoteEs(
        nutrient: AgroMetricKey.p,
        reaction: SoilReaction.calcareous,
        ph: 7.9,
      );
      expect(p, isNotNull);
      expect(p!.toLowerCase(), contains('calcáreo'));
      expect(p, contains('7.9'));
      expect(p.toLowerCase(), contains('banda'));

      expect(
        soilReactionNoteEs(nutrient: AgroMetricKey.n, reaction: SoilReaction.calcareous),
        isNull,
      );
      expect(
        soilReactionNoteEs(nutrient: AgroMetricKey.p, reaction: SoilReaction.acidic),
        isNull,
      );
    });

    /// La urea al voleo en suelo calcáreo pierde 40 % a pH 7.0 y 44 % a
    /// pH 7.5 en diez días. El motor ya lee el pH; ahora lo dice.
    test('avisa de la volatilización de urea', () {
      final String? warn = ureaVolatilizationWarningEs(
        nutrient: AgroMetricKey.n,
        reaction: SoilReaction.calcareous,
        ph: 7.8,
      );
      expect(warn, isNotNull);
      expect(warn!.toLowerCase(), contains('urea'));
      expect(warn, contains('44 %'));
      expect(warn.toLowerCase(), contains('incorpór'));
    });

    test('a pH 7.4 el aviso baja al 40 %', () {
      final String? warn = ureaVolatilizationWarningEs(
        nutrient: AgroMetricKey.n,
        reaction: SoilReaction.calcareous,
        ph: 7.35,
      );
      expect(warn, contains('40 %'));
    });

    test('sin suelo calcáreo no aparece ningún aviso de urea', () {
      expect(
        ureaVolatilizationWarningEs(
          nutrient: AgroMetricKey.n,
          reaction: SoilReaction.unknown,
        ),
        isNull,
      );
      expect(
        ureaVolatilizationWarningEs(
          nutrient: AgroMetricKey.n,
          reaction: SoilReaction.acidic,
          ph: 6.0,
        ),
        isNull,
      );
    });

    test('el aviso de urea es solo para nitrógeno', () {
      expect(
        ureaVolatilizationWarningEs(
          nutrient: AgroMetricKey.k,
          reaction: SoilReaction.calcareous,
          ph: 8.0,
        ),
        isNull,
      );
    });
  });
}
