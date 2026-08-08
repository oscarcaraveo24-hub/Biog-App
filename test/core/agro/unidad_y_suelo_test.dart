import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/dose_expression.dart';
import 'package:bio_g/core/agro/fertilization_planner.dart';
import 'package:bio_g/core/agro/nutrient_target_range_resolver.dart';
import 'package:bio_g/core/agro/soil_reaction.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Congela las dos capas nuevas:
///
///   1. **La unidad elegible.** El motor calcula una sola cosa —kilos de
///      nutriente puro por hectárea— y esta capa lo dice en el idioma del
///      productor. El número no cambia; cambia cómo se dice.
///
///   2. **La reacción del suelo.** El pH ya viene en cada lectura, así que el
///      motor puede saber si el suelo es calcáreo sin preguntar nada, subir la
///      meta de fósforo en consecuencia, y advertir de la volatilización de
///      urea.
///
/// La prueba más importante de todo el archivo es la primera del grupo 3:
/// verifica que **el productor de campo abierto no vea ningún cambio.** Una
/// capa nueva que altera lo que ya funcionaba no es una mejora.
void main() {
  const AgroRange dummy = AgroRange(
    lowMax: 0,
    optimalMin: 0,
    optimalMax: 100,
    highMin: 100,
  );

  StageTargets targetsFor({
    AgroRange? n,
    AgroRange? p,
    AgroRange? k,
  }) {
    return StageTargets(
      moistureRaw: dummy,
      soilTemp: dummy,
      ph: dummy,
      ec: dummy,
      resistance: dummy,
      nIndex: dummy,
      pIndex: dummy,
      kIndex: dummy,
      nSoilPpmRange: n,
      pSoilPpmRange: p,
      kSoilPpmRange: k,
    );
  }

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
  // 3. EL MOTOR, DE PUNTA A PUNTA
  // ═══════════════════════════════════════════════════════════════════════════

  group('El motor con la unidad elegible', () {
    final StageTargets t = targetsFor(
      n: const AgroRange(
        lowMax: 40,
        optimalMin: 60,
        optimalMax: 80,
        highMin: 100,
      ),
    );

    /// **La prueba más importante del archivo.** Si esta falla, la capa nueva
    /// rompió a los productores que ya tenía BIO-G.
    test('sin contexto, el campo abierto no cambia ni un carácter', () {
      final NutrientDoseGuide? g = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 12.5,
        cropKey: 'maize',
        stageKey: 'vegMid',
        cultivationScaleId: 'field',
        targets: targetsFor(
          n: const AgroRange(
            lowMax: 50,
            optimalMin: 60,
            optimalMax: 80,
            highMin: 90,
          ),
        ),
      );

      // El caso de campo validado del maíz, intacto.
      expect(g!.doseGuideEs, contains('~138 kg/ha de Nitrógeno puro'));
      expect(g.fertilizerEquivalentEs, contains('~300 kg/ha de Urea (46-0-0)'));
    });

    test('con fertirriego y densidad, el mismo cálculo sale por planta', () {
      final NutrientDoseGuide? g = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 20.0,
        cropKey: 'tomato',
        stageKey: 'floracion',
        cultivationScaleId: 'field',
        targets: t,
        doseContext: const DoseContext(
          method: ApplicationMethod.fertigation,
          plantsPerHectare: 25000,
        ),
      );

      // meta 70, lectura 20 ⇒ déficit 50 ⇒ 120 kg/ha ⇒ 4.8 g por planta
      expect(g, isNotNull);
      expect(g!.doseGuideEs, contains('4.8 g'),
          reason: '120 kg/ha ÷ 25 000 plantas × 1000 = 4.8 g por planta');
      expect(g.doseGuideEs, contains('por planta'));
      expect(g.fertilizerEquivalentEs, contains('25000 plantas por hectárea'),
          reason: 'la conversión tiene que quedar a la vista');
    });

    test('fertirriego sin densidad cae a kg/ha y no inventa', () {
      final NutrientDoseGuide? g = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 20.0,
        cropKey: 'tomato',
        stageKey: 'floracion',
        cultivationScaleId: 'field',
        targets: t,
        doseContext: const DoseContext(
          method: ApplicationMethod.fertigation,
        ),
      );
      expect(g!.doseGuideEs, contains('kg/ha'));
      expect(g.doseGuideEs, isNot(contains('por planta')));
    });

    /// La maceta no pasa por esta capa: su base no es el área sino la masa de
    /// sustrato. Se verifica que siga intacta.
    test('la maceta no se ve afectada', () {
      final NutrientDoseGuide? g = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 20.0,
        cropKey: null,
        stageKey: null,
        cultivationScaleId: 'pot',
        targets: t,
        doseContext: const DoseContext(
          method: ApplicationMethod.fertigation,
          plantsPerHectare: 25000,
        ),
      );
      expect(g!.doseGuideEs, contains('por maceta'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. LA REACCIÓN DEL SUELO
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

    /// El factor 1.75 se calibra contra la banda calcárea de UF/IFAS
    /// (medio 77–104, punto medio 90.5) partiendo del punto medio de la banda
    /// de fósforo de BIO-G en floración de hortaliza (42–62, medio 52):
    ///     90.5 ÷ 52 ≈ 1.74
    test('el desplazamiento del fósforo aterriza en la banda de UF/IFAS', () {
      const AgroRange base = AgroRange(
        lowMax: 35,
        optimalMin: 42,
        optimalMax: 62,
        highMin: 72,
      );
      final AgroRange ajustado = adjustRangeForSoilReaction(
        range: base,
        nutrient: AgroMetricKey.p,
        reaction: SoilReaction.calcareous,
      );

      final double medio = (ajustado.optimalMin + ajustado.optimalMax) / 2;
      expect(medio, closeTo(91.0, 3.0),
          reason: 'UF/IFAS pone el medio calcáreo en 77–104, centro 90.5');
      expect(ajustado.optimalMin, closeTo(73.5, 1.0));
      expect(ajustado.optimalMax, closeTo(108.5, 1.0));
    });

    test('solo se toca el fósforo, nunca N ni K', () {
      const AgroRange base = AgroRange(
        lowMax: 35,
        optimalMin: 42,
        optimalMax: 62,
        highMin: 72,
      );
      for (final AgroMetricKey nut in <AgroMetricKey>[
        AgroMetricKey.n,
        AgroMetricKey.k,
      ]) {
        final AgroRange r = adjustRangeForSoilReaction(
          range: base,
          nutrient: nut,
          reaction: SoilReaction.calcareous,
        );
        expect(r.optimalMin, base.optimalMin,
            reason: '${nut.name}: no hay calibración calcárea publicada, '
                'ajustarlo sería inventar');
        expect(r.optimalMax, base.optimalMax);
      }
    });

    test('en suelo ácido o neutro no se ajusta nada', () {
      const AgroRange base = AgroRange(
        lowMax: 35,
        optimalMin: 42,
        optimalMax: 62,
        highMin: 72,
      );
      for (final SoilReaction r in <SoilReaction>[
        SoilReaction.acidic,
        SoilReaction.neutral,
        SoilReaction.unknown,
      ]) {
        expect(
          adjustRangeForSoilReaction(
            range: base,
            nutrient: AgroMetricKey.p,
            reaction: r,
          ).optimalMin,
          base.optimalMin,
        );
      }
    });

    /// El ajuste vive en un solo lugar —`comparableRange`— para que la banda
    /// que se pinta en pantalla y la dosis que se calcula salgan del mismo
    /// número. Si vivieran en dos sitios podrían contradecirse.
    test('la banda mostrada y la dosis usan el mismo número', () {
      final StageTargets t = targetsFor(
        p: const AgroRange(
          lowMax: 35,
          optimalMin: 42,
          optimalMax: 62,
          highMin: 72,
        ),
      );

      final AgroRange? normal = NutrientTargetRangeResolver.comparableRange(
        nutrient: AgroMetricKey.p,
        cropKey: 'tomato',
        targets: t,
      );
      final AgroRange? calcareo = NutrientTargetRangeResolver.comparableRange(
        nutrient: AgroMetricKey.p,
        cropKey: 'tomato',
        targets: t,
        soilReaction: SoilReaction.calcareous,
      );

      expect(normal!.optimalMin, 42);
      expect(calcareo!.optimalMin, closeTo(73.5, 0.5));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. LO QUE VE EL PRODUCTOR DE SUELO CALCÁREO
  // ═══════════════════════════════════════════════════════════════════════════

  group('El motor en suelo calcáreo', () {
    final StageTargets t = targetsFor(
      p: const AgroRange(
        lowMax: 35,
        optimalMin: 42,
        optimalMax: 62,
        highMin: 72,
      ),
      n: const AgroRange(
        lowMax: 40,
        optimalMin: 60,
        optimalMax: 80,
        highMin: 100,
      ),
    );

    /// El caso que motivó todo: una lectura de 60 ppm de fósforo.
    /// En suelo ácido está en el óptimo y no hace falta nada.
    /// En suelo calcáreo, con la banda de UF/IFAS, todavía es **bajo**.
    test('60 ppm de P: óptimo en suelo ácido, deficiente en calcáreo', () {
      final NutrientDoseGuide? acido = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.p,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 60.0,
        cropKey: 'tomato',
        stageKey: 'floracion',
        cultivationScaleId: 'field',
        targets: t,
        ph: 6.2,
      );
      expect(acido, isNull,
          reason: 'en suelo ácido 60 ppm está en meta: no hay dosis');

      final NutrientDoseGuide? calcareo = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.p,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 60.0,
        cropKey: 'tomato',
        stageKey: 'floracion',
        cultivationScaleId: 'field',
        targets: t,
        ph: 7.8,
      );
      expect(calcareo, isNotNull,
          reason: 'en suelo calcáreo esa misma lectura sí pide fósforo');
      expect(calcareo!.fertilizerEquivalentEs, contains('calcáreo'));
      expect(calcareo.fertilizerEquivalentEs, contains('Olsen'),
          reason: 'hay que avisar que la escala del laboratorio es otra');
    });

    /// La urea al voleo en suelo calcáreo pierde 40 % a pH 7.0 y 44 % a
    /// pH 7.5 en diez días. El motor ya lee el pH; ahora lo dice.
    test('avisa de la volatilización de urea', () {
      final NutrientDoseGuide? g = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 20.0,
        cropKey: 'maize',
        stageKey: 'vegMid',
        cultivationScaleId: 'field',
        targets: t,
        ph: 7.8,
      );

      expect(g!.fertilizerEquivalentEs!.toLowerCase(), contains('urea'));
      expect(g.fertilizerEquivalentEs, contains('44 %'));
      expect(g.fertilizerEquivalentEs!.toLowerCase(), contains('incorpór'));
    });

    test('a pH 7.4 el aviso baja al 40 %', () {
      final NutrientDoseGuide? g = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 20.0,
        cropKey: 'maize',
        stageKey: 'vegMid',
        cultivationScaleId: 'field',
        targets: t,
        ph: 7.35,
      );
      expect(g!.fertilizerEquivalentEs, contains('40 %'));
    });

    test('sin pH no aparece ningún aviso de suelo', () {
      final NutrientDoseGuide? g = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 20.0,
        cropKey: 'maize',
        stageKey: 'vegMid',
        cultivationScaleId: 'field',
        targets: t,
      );
      expect(g!.fertilizerEquivalentEs, isNot(contains('calcáreo')));
      expect(g.fertilizerEquivalentEs, isNot(contains('volatiliza')));
    });

    test('en suelo ácido tampoco', () {
      final NutrientDoseGuide? g = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 20.0,
        cropKey: 'maize',
        stageKey: 'vegMid',
        cultivationScaleId: 'field',
        targets: t,
        ph: 6.0,
      );
      expect(g!.fertilizerEquivalentEs, isNot(contains('calcáreo')));
    });
  });
}
