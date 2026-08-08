import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/fertilization_planner.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/crops/cucumber/cucumber_universal_profile.dart';
import 'package:bio_g/crops/tomato/tomato_universal_profile.dart';
import 'package:bio_g/widgets/seeds/cucumber_models.dart';
import 'package:bio_g/widgets/seeds/tomato_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Valida el motor de hortalizas contra la literatura publicada.
///
/// A diferencia de las otras pruebas de este proyecto, estas **no usan targets
/// inventados**: leen los perfiles reales del código —`cucumberUniversalV1` y
/// `tomatoUniversalV1`— y le piden al motor la dosis que le daría a un
/// agricultor de verdad, etapa por etapa.
///
/// Después contrastan ese número contra lo que publican UF/IFAS, Penn State,
/// UC Davis, UC IPM, Oregon State, Haifa e ICL.
///
/// EL RESULTADO, POR ADELANTADO
/// ----------------------------
/// · Fósforo y potasio: **coinciden** con la calibración Mehlich-3.
/// · Nitrógeno: el motor pide 2 a 5 veces más que los umbrales de NO₃-N
///   publicados. No es necesariamente un error —el sensor de BIO-G no mide
///   nitrato— pero es una diferencia que tiene que estar escrita, no
///   descubierta por un cliente.
///
/// Las pruebas que congelan esa diferencia están marcadas como
/// DESVIACIÓN CONOCIDA. Una desviación documentada vale más que una prueba
/// que no existe.
void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // Utilidades
  // ───────────────────────────────────────────────────────────────────────────

  /// Le pide al motor la dosis real, con los targets reales del perfil.
  ///
  /// [rawPpm] es lo que marcaría el sensor. El motor compara contra el punto
  /// medio del rango óptimo de esa etapa y devuelve la guía.
  NutrientDoseGuide? doseFor({
    required AgroMetricKey nutrient,
    required String cropKey,
    required String stageKey,
    required StageTargets targets,
    required double rawPpm,
  }) {
    return FertilizationPlanner.buildGuide(
      nutrient: nutrient,
      label: NutrientPriorityLabel.actionRecommended,
      rawPpm: rawPpm,
      cropKey: cropKey,
      stageKey: stageKey,
      cultivationScaleId: 'field',
      targets: targets,
    );
  }

  /// Extrae el número de kg/ha del texto comercial.
  ///
  /// El motor escribe «~145 kg/ha de Urea (46-0-0)»; aquí se recupera el 145
  /// para poder compararlo contra rangos publicados.
  double? kgHaFrom(String? text) {
    if (text == null) return null;
    final RegExpMatch? m =
        RegExp(r'~?(\d+(?:\.\d+)?)\s*kg/ha').firstMatch(text);
    return m == null ? null : double.parse(m.group(1)!);
  }

  /// Punto medio del rango óptimo de suelo — lo que el motor toma como meta.
  double midOf(AgroRange r) => (r.optimalMin + r.optimalMax) / 2.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. EL CASO QUE PIDIÓ EL FUNDADOR — pepino en etapa 4
  // ═══════════════════════════════════════════════════════════════════════════

  group('Pepino · etapa 4 (floración) · el caso de referencia', () {
    late StageTargets t;

    setUp(() {
      t = cucumberUniversalV1.byStage[CucumberStageKey.floracion]!;
    });

    /// Con el perfil real, la etapa 4 del pepino pide N entre 58 y 88 mg/kg,
    /// con meta en 73. Un sensor que marque 45 —justo en el techo de «bajo»—
    /// produce un déficit de 28 mg/kg.
    ///
    ///   28 × 2.4 = 67 kg/ha de N puro ⇒ ~145 kg/ha de urea
    ///
    /// Contraste con lo publicado para pepino, **temporada completa**:
    ///   UF/IFAS (Mehlich-3 bajo) ....... 168 kg N/ha
    ///   Haifa, 30–40 t/ha .............. 100 kg N/ha
    ///   ICL fertirriego ................ 200 kg N/ha
    ///
    /// O sea que una sola recomendación del motor equivale a entre el 33 % y
    /// el 67 % del nitrógeno de toda la temporada. Como aplicación fraccionada
    /// única es defendible; como número que se repite sin memoria, no.
    test('nitrógeno: ~145 kg/ha de urea con lectura de 45 mg/kg', () {
      final NutrientDoseGuide? g = doseFor(
        nutrient: AgroMetricKey.n,
        cropKey: 'cucumber',
        stageKey: 'floracion',
        targets: t,
        rawPpm: 45.0,
      );

      expect(g, isNotNull);
      expect(kgHaFrom(g!.doseGuideEs), closeTo(67, 2),
          reason: 'N puro: 28 mg/kg × 2.4');
      expect(kgHaFrom(g.fertilizerEquivalentEs), closeTo(145, 5),
          reason: 'urea: 67 ÷ 0.46, redondeado a múltiplo de 5');
    });

    test('la meta de la etapa 4 es 73 mg/kg de N', () {
      expect(midOf(t.nSoilPpmRange!), closeTo(73.0, 0.5));
    });

    /// Una sola dosis nunca debe pasarse de la temporada completa que publica
    /// la fuente más generosa. Es el techo absoluto: cruzarlo significaría que
    /// el motor recomienda de golpe más de lo que el cultivo lleva en el año.
    test('ninguna dosis de la etapa 4 rebasa la temporada publicada', () {
      final Map<AgroMetricKey, ({double raw, double techo, String fuente})>
          casos = <AgroMetricKey, ({double raw, double techo, String fuente})>{
        AgroMetricKey.n: (raw: 45.0, techo: 300.0, fuente: 'Haifa 170 t/ha'),
        AgroMetricKey.p: (raw: 35.0, techo: 250.0, fuente: 'Haifa invernadero'),
        AgroMetricKey.k: (raw: 95.0, techo: 1000.0, fuente: 'Haifa invernadero'),
      };

      casos.forEach((AgroMetricKey nut, ({double raw, double techo, String fuente}) c) {
        final NutrientDoseGuide? g = doseFor(
          nutrient: nut,
          cropKey: 'cucumber',
          stageKey: 'floracion',
          targets: t,
          rawPpm: c.raw,
        );
        final double? kg = kgHaFrom(g?.doseGuideEs);
        expect(kg, isNotNull, reason: '${nut.name} no produjo dosis');
        expect(kg!, lessThan(c.techo),
            reason: '${nut.name}: $kg kg/ha supera la temporada de ${c.fuente}');
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. BARRIDO COMPLETO — las ocho etapas, los tres nutrientes, dos cultivos
  // ═══════════════════════════════════════════════════════════════════════════

  group('Barrido de las ocho etapas', () {
    /// Recorre cada etapa de pepino y tomate con tres lecturas distintas:
    /// muy baja, en el techo de «bajo» y dentro del óptimo. En total 144
    /// evaluaciones del motor.
    ///
    /// Lo que se verifica en cada una no es un número exacto, sino que el
    /// motor se comporte con sentido: que dé más cuando falta más, que no dé
    /// nada cuando el suelo está en meta, y que nunca produzca un absurdo.
    void barrer({
      required String cropKey,
      required Map<int, StageTargets> etapas,
      required Map<int, String> nombres,
    }) {
      for (final MapEntry<int, StageTargets> e in etapas.entries) {
        final int n = e.key;
        final StageTargets t = e.value;
        final String stage = nombres[n]!;

        test('$cropKey · etapa $n ($stage) · coherencia', () {
          for (final AgroMetricKey nut in <AgroMetricKey>[
            AgroMetricKey.n,
            AgroMetricKey.p,
            AgroMetricKey.k,
          ]) {
            final AgroRange? r = t.soilPpmRangeFor(nut);
            expect(r, isNotNull,
                reason: '$cropKey etapa $n: falta rango de ${nut.name}');
            final double mid = midOf(r!);

            // a) Suelo en la meta ⇒ sin dosis.
            expect(
              doseFor(
                nutrient: nut,
                cropKey: cropKey,
                stageKey: stage,
                targets: t,
                rawPpm: mid,
              ),
              isNull,
              reason: '$cropKey etapa $n ${nut.name}: en meta no debe recetar',
            );

            // b) Suelo por encima de la meta ⇒ tampoco.
            expect(
              doseFor(
                nutrient: nut,
                cropKey: cropKey,
                stageKey: stage,
                targets: t,
                rawPpm: mid * 1.5,
              ),
              isNull,
              reason: '$cropKey etapa $n ${nut.name}: por encima no debe recetar',
            );

            // c) Con carencia siempre hay guía, aunque no siempre lleve
            //    número: en fin de ciclo el motor aconseja preparar la base
            //    del siguiente ciclo en vez de perseguir una respuesta tardía,
            //    y eso es correcto.
            final NutrientDoseGuide? gPoco = doseFor(
              nutrient: nut,
              cropKey: cropKey,
              stageKey: stage,
              targets: t,
              rawPpm: r.lowMax,
            );
            final NutrientDoseGuide? gMucho = doseFor(
              nutrient: nut,
              cropKey: cropKey,
              stageKey: stage,
              targets: t,
              rawPpm: r.lowMax * 0.4,
            );
            expect(gPoco, isNotNull, reason: '$cropKey $n ${nut.name}');
            expect(gMucho, isNotNull, reason: '$cropKey $n ${nut.name}');

            final double? poco = kgHaFrom(gPoco!.doseGuideEs);
            final double? mucho = kgHaFrom(gMucho!.doseGuideEs);

            if (poco == null) {
              // Etapa sin dosis por decisión agronómica: tiene que decir por qué.
              expect(gPoco.doseGuideEs.toLowerCase(), contains('ciclo'),
                  reason: '$cropKey etapa $n ${nut.name}: si no da número, '
                      'debe explicar que el ciclo ya va de salida');
              expect(mucho, isNull,
                  reason: '$cropKey etapa $n ${nut.name}: debe ser consistente');
              continue;
            }

            // d) A más carencia, más dosis. Nunca al revés.
            expect(mucho, isNotNull, reason: '$cropKey $n ${nut.name}');
            expect(mucho!, greaterThan(poco),
                reason: '$cropKey etapa $n ${nut.name}: la dosis debe subir '
                    'cuando la carencia es mayor');

            // e) Nunca un número sin sentido físico.
            expect(mucho, lessThan(2000),
                reason: '$cropKey etapa $n ${nut.name}: $mucho kg/ha es absurdo');
            expect(poco, greaterThan(0));
          }
        });
      }
    }

    barrer(
      cropKey: 'cucumber',
      etapas: <int, StageTargets>{
        1: cucumberUniversalV1.byStage[CucumberStageKey.germinacion]!,
        2: cucumberUniversalV1.byStage[CucumberStageKey.establecimiento]!,
        3: cucumberUniversalV1.byStage[CucumberStageKey.vegetativo]!,
        4: cucumberUniversalV1.byStage[CucumberStageKey.floracion]!,
        5: cucumberUniversalV1.byStage[CucumberStageKey.cuajado]!,
        6: cucumberUniversalV1.byStage[CucumberStageKey.llenado]!,
        7: cucumberUniversalV1.byStage[CucumberStageKey.cosechaProgresiva]!,
        8: cucumberUniversalV1.byStage[CucumberStageKey.finCiclo]!,
      },
      nombres: <int, String>{
        1: 'germinacion', 2: 'establecimiento', 3: 'vegetativo',
        4: 'floracion', 5: 'cuajado', 6: 'llenado',
        7: 'cosechaProgresiva', 8: 'finCiclo',
      },
    );

    barrer(
      cropKey: 'tomato',
      etapas: <int, StageTargets>{
        1: tomatoUniversalV1.byStage[TomatoStageKey.germinacion]!,
        2: tomatoUniversalV1.byStage[TomatoStageKey.establecimiento]!,
        3: tomatoUniversalV1.byStage[TomatoStageKey.vegetativo]!,
        4: tomatoUniversalV1.byStage[TomatoStageKey.floracion]!,
        5: tomatoUniversalV1.byStage[TomatoStageKey.cuajado]!,
        6: tomatoUniversalV1.byStage[TomatoStageKey.llenado]!,
        7: tomatoUniversalV1.byStage[TomatoStageKey.cosechaProgresiva]!,
        8: tomatoUniversalV1.byStage[TomatoStageKey.finCiclo]!,
      },
      nombres: <int, String>{
        1: 'germinacion', 2: 'establecimiento', 3: 'vegetativo',
        4: 'floracion', 5: 'cuajado', 6: 'llenado',
        7: 'cosechaProgresiva', 8: 'finCiclo',
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. CONTRASTE CONTRA LA LITERATURA — fósforo y potasio
  // ═══════════════════════════════════════════════════════════════════════════

  group('Fósforo · contra la calibración publicada', () {
    /// Penn State, laboratorio AASL, extractante Mehlich-3 (ICP):
    ///   pepino (cultivo 3109) y tomate (3036) → **óptimo 35–70 ppm**,
    ///   por encima de 70 la recomendación de P₂O₅ es cero.
    ///
    /// El motor de BIO-G pide, según la etapa, óptimos entre 36 y 74 ppm.
    /// Es prácticamente la misma banda. Este es el mejor resultado de toda
    /// la validación de hortalizas.
    test('el óptimo de P cae dentro de la banda Mehlich-3 de Penn State', () {
      void revisar(String crop, Iterable<StageTargets> etapas) {
        for (final StageTargets t in etapas) {
          final AgroRange r = t.pSoilPpmRangeFor()!;
          expect(r.optimalMin, inInclusiveRange(25.0, 60.0),
              reason: '$crop: el piso del óptimo de P se salió de Mehlich-3');
          expect(r.optimalMax, inInclusiveRange(40.0, 85.0),
              reason: '$crop: el techo del óptimo de P se salió de Mehlich-3');
        }
      }

      revisar('pepino', cucumberUniversalV1.byStage.values);
      revisar('tomate', tomatoUniversalV1.byStage.values);
    });

    /// UF/IFAS publica DOS tablas de Mehlich-3 para el mismo cultivo:
    ///   suelo mineral ácido ...... alto por encima de 45 ppm
    ///   suelo calcáreo ........... medio de 77 a 104 ppm
    ///
    /// Chihuahua es suelo calcáreo. El motor usa una sola banda, alineada con
    /// la tabla de suelo ácido. Consecuencia práctica: en un suelo calcáreo
    /// puede leer «alto» donde el laboratorio local diría «medio», y dejar de
    /// recomendar fósforo que sí hacía falta.
    ///
    /// Esta prueba no falla — congela el hecho para que la decisión de
    /// diferenciar por tipo de suelo se tome a la vista.
    test('DESVIACIÓN CONOCIDA · el P no distingue suelo ácido de calcáreo', () {
      final AgroRange r = cucumberUniversalV1
          .byStage[CucumberStageKey.floracion]!.pSoilPpmRangeFor()!;
      expect(r.highMin, lessThan(77.0),
          reason: 'hoy el umbral de «alto» corresponde a suelo ácido; en suelo '
              'calcáreo UF/IFAS pone el rango medio en 77–104 ppm');
    });
  });

  group('Potasio · contra la calibración publicada', () {
    /// Penn State Mehlich-3: óptimo 70–140 ppm.
    /// Oregon State (acetato de amonio): más de 100 ppm es adecuado y 200 ppm
    /// es la meta de mantenimiento.
    /// UF/IFAS Mehlich-3 calcáreo: medio 86–150, alto por encima de 150.
    ///
    /// El motor pide óptimos entre 75 y 185 ppm según la etapa. Queda por
    /// encima de Penn State en las etapas de fruto, pero dentro de la meta de
    /// mantenimiento de Oregon y de la banda calcárea de UF/IFAS.
    test('el óptimo de K queda dentro del abanico publicado', () {
      for (final StageTargets t in cucumberUniversalV1.byStage.values) {
        final AgroRange r = t.kSoilPpmRangeFor()!;
        expect(r.optimalMin, inInclusiveRange(60.0, 150.0));
        expect(r.optimalMax, inInclusiveRange(100.0, 210.0));
      }
    });

    /// El potasio del pepino debe subir de germinación a llenado: es el
    /// nutriente del fruto. Si esta curva se aplana o se invierte, algo se
    /// rompió en el perfil.
    test('el K sube de germinación a llenado', () {
      final double germ = midOf(cucumberUniversalV1
          .byStage[CucumberStageKey.germinacion]!.kSoilPpmRangeFor()!);
      final double llenado = midOf(cucumberUniversalV1
          .byStage[CucumberStageKey.llenado]!.kSoilPpmRangeFor()!);
      expect(llenado, greaterThan(germ * 1.4),
          reason: 'el K debe crecer marcadamente hacia el fruto');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. LA DESVIACIÓN REAL — nitrógeno
  // ═══════════════════════════════════════════════════════════════════════════

  group('Nitrógeno · la desviación que hay que conocer', () {
    /// Lo publicado, en NO₃-N de suelo:
    ///   UMass PSNT ......... más de 30 ppm ya es suficiente
    ///   UC Davis, tomate ... más de 16 ppm y no hay respuesta al N
    ///   UC IPM, tomate ..... más de 15 ppm ⇒ no más de 56 kg N/ha
    ///
    /// El motor de BIO-G pide, en las etapas de mayor demanda, metas de 73 a
    /// 80 ppm y considera «bajo» todo lo que esté por debajo de 45–50.
    /// Son de dos a cinco veces los umbrales publicados.
    ///
    /// POR QUÉ NO ES NECESARIAMENTE UN ERROR
    /// El PSNT mide nitrato específicamente, con extracción de laboratorio y
    /// muestreo de 0–30 cm. El sensor de BIO-G no mide nitrato: da una lectura
    /// electroquímica relativa que ni siquiera está en la misma escala. Es el
    /// mismo problema que con el fósforo, donde «alto» va de 25 ppm en Olsen a
    /// 104 en Mehlich-3 calcáreo — un factor de cuatro solo por cambiar de
    /// método.
    ///
    /// POR QUÉ IGUAL IMPORTA
    /// Porque el día que un agrónomo compare la pantalla de BIO-G con su
    /// análisis de laboratorio, va a ver dos números que no se parecen. Que
    /// esté escrito aquí convierte esa conversación en una explicación, no en
    /// una sorpresa.
    test('DESVIACIÓN CONOCIDA · las metas de N superan los umbrales de NO₃-N', () {
      final double metaVeg = midOf(cucumberUniversalV1
          .byStage[CucumberStageKey.vegetativo]!.nSoilPpmRangeFor()!);

      expect(metaVeg, greaterThan(30.0),
          reason: 'congelado: la meta de N del motor está por encima del '
              'umbral PSNT de 30 ppm de NO₃-N. La lectura del sensor no es '
              'nitrato de laboratorio y no son comparables directamente.');
      expect(metaVeg, closeTo(80.0, 5.0),
          reason: 'si este valor se mueve, la desviación cambia de tamaño y '
              'hay que volver a documentarla');
    });

    /// El nitrógeno del pepino debe bajar hacia el final del ciclo: en fruto
    /// el exceso de N alarga la planta a costa del fruto y retrasa madurez.
    /// Esta curva sí está bien puesta y hay que protegerla.
    test('el N baja de vegetativo a fin de ciclo', () {
      final double veg = midOf(cucumberUniversalV1
          .byStage[CucumberStageKey.vegetativo]!.nSoilPpmRangeFor()!);
      final double fin = midOf(cucumberUniversalV1
          .byStage[CucumberStageKey.finCiclo]!.nSoilPpmRangeFor()!);
      expect(fin, lessThan(veg * 0.6),
          reason: 'el N debe aflojar hacia el cierre del ciclo');
    });

    /// UC Davis: «Tomato plants take up less than 30% of their N before fruit
    /// set». El programa de goteo de UF/IFAS da 20 % antes del llenado.
    ///
    /// El motor no reparte una dosis anual —recomienda por lectura— así que no
    /// puede cumplir ese porcentaje directamente. Lo que sí puede, y hace, es
    /// que su meta de N sea más alta en vegetativo que en floración, para que
    /// el nitrógeno esté puesto antes de que el fruto lo pida.
    test('la meta de N es más alta antes de la floración que durante', () {
      final double veg = midOf(cucumberUniversalV1
          .byStage[CucumberStageKey.vegetativo]!.nSoilPpmRangeFor()!);
      final double flor = midOf(cucumberUniversalV1
          .byStage[CucumberStageKey.floracion]!.nSoilPpmRangeFor()!);
      expect(veg, greaterThan(flor),
          reason: 'el N debe estar disponible ANTES del pico de demanda');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. LO QUE EL MOTOR NO SABE Y HAY QUE VIGILAR
  // ═══════════════════════════════════════════════════════════════════════════

  group('Límites conocidos del motor', () {
    /// El motor recomienda por lectura, sin memoria de lo ya aplicado. Si el
    /// agricultor aplica y el sensor todavía no registra la subida, la
    /// siguiente lectura puede volver a recomendar.
    ///
    /// El seguro real es el propio sensor: cuando el suelo sube, el déficit
    /// baja y la dosis baja con él. Esta prueba verifica que ese lazo cierre.
    test('el lazo del sensor cierra: si el suelo sube, la dosis baja', () {
      final StageTargets t =
          cucumberUniversalV1.byStage[CucumberStageKey.floracion]!;
      final double mid = midOf(t.nSoilPpmRangeFor()!);

      final double? antes = kgHaFrom(doseFor(
        nutrient: AgroMetricKey.n,
        cropKey: 'cucumber',
        stageKey: 'floracion',
        targets: t,
        rawPpm: 45.0,
      )?.doseGuideEs);

      final double? despues = kgHaFrom(doseFor(
        nutrient: AgroMetricKey.n,
        cropKey: 'cucumber',
        stageKey: 'floracion',
        targets: t,
        rawPpm: 62.0,
      )?.doseGuideEs);

      expect(antes, isNotNull);
      expect(despues, isNotNull);
      expect(despues!, lessThan(antes!),
          reason: 'sin este lazo, el motor podría recomendar dos veces lo mismo');

      // Y al llegar a la meta se apaga por completo.
      expect(
        doseFor(
          nutrient: AgroMetricKey.n,
          cropKey: 'cucumber',
          stageKey: 'floracion',
          targets: t,
          rawPpm: mid,
        ),
        isNull,
      );
    });

    /// Suma de las ocho etapas si el motor recomendara en todas con el suelo
    /// en el techo de «bajo». No es un escenario real —el lazo del sensor lo
    /// impide— pero marca el techo teórico y conviene tenerlo medido.
    ///
    /// Publicado para pepino: 100–300 kg N/ha en campo, 450–500 en invernadero
    /// de 300 t/ha.
    test('el techo teórico acumulado queda dentro del rango de invernadero', () {
      double suma = 0;
      final Map<CucumberStageKey, String> etapas = <CucumberStageKey, String>{
        CucumberStageKey.germinacion: 'germinacion',
        CucumberStageKey.establecimiento: 'establecimiento',
        CucumberStageKey.vegetativo: 'vegetativo',
        CucumberStageKey.floracion: 'floracion',
        CucumberStageKey.cuajado: 'cuajado',
        CucumberStageKey.llenado: 'llenado',
        CucumberStageKey.cosechaProgresiva: 'cosechaProgresiva',
        CucumberStageKey.finCiclo: 'finCiclo',
      };

      etapas.forEach((CucumberStageKey k, String nombre) {
        final StageTargets t = cucumberUniversalV1.byStage[k]!;
        final double? kg = kgHaFrom(doseFor(
          nutrient: AgroMetricKey.n,
          cropKey: 'cucumber',
          stageKey: nombre,
          targets: t,
          rawPpm: t.nSoilPpmRangeFor()!.lowMax,
        )?.doseGuideEs);
        if (kg != null) suma += kg;
      });

      expect(suma, lessThan(600.0),
          reason: 'el acumulado teórico ($suma kg N/ha) no debe rebasar el '
              'techo de invernadero de alto rendimiento');
      expect(suma, greaterThan(200.0),
          reason: 'si baja de esto, el motor quedó por debajo de campo abierto');
    });
  });
}

/// Atajos de lectura de rangos de suelo, para que las pruebas se lean como
/// lo que quieren decir.
extension _SoilRanges on StageTargets {
  AgroRange? nSoilPpmRangeFor() => soilPpmRangeFor(AgroMetricKey.n);
  AgroRange? pSoilPpmRangeFor() => soilPpmRangeFor(AgroMetricKey.p);
  AgroRange? kSoilPpmRangeFor() => soilPpmRangeFor(AgroMetricKey.k);
}
