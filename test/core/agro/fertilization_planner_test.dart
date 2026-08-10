import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/fertilization_planner.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Congela el comportamiento del motor de dosis: el cálculo por el que se
/// vende BIO-G.
///
/// Hasta hoy `FertilizationPlanner` tenía cero pruebas. Es la pieza con más
/// consecuencia económica de toda la aplicación —un número de más o de menos
/// aquí es dinero real del agricultor y fertilizante en el suelo— y era también
/// la única sin red de seguridad.
///
/// Estas pruebas NO juzgan si la agronomía es la correcta: eso lo decide la
/// validación de campo que pide el Fundacional 2.1 §14.2. Lo que hacen es
/// **fijar lo que el motor hace hoy**, para que ningún cambio futuro
/// (densidad, profundidad, targets, refactor) mueva una dosis sin que alguien
/// lo vea y lo decida a propósito.
///
/// Si una de estas pruebas falla, no significa necesariamente "hay un error".
/// Significa: *cambiaste una dosis*. Confírmalo antes de actualizar el número.
void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // Utilidades de armado
  // ───────────────────────────────────────────────────────────────────────────

  const AgroRange dummy = AgroRange(
    lowMax: 0,
    optimalMin: 0,
    optimalMax: 100,
    highMin: 100,
  );

  /// Construye targets con un rango de suelo explícito para N.
  ///
  /// El motor compara la lectura contra el **punto medio** del rango óptimo.
  /// Con `optimalMin: 60` y `optimalMax: 80` el punto medio es 70 mg/kg.
  StageTargets targetsN({
    required double optimalMin,
    required double optimalMax,
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
      nSoilPpmRange: AgroRange(
        lowMax: optimalMin,
        optimalMin: optimalMin,
        optimalMax: optimalMax,
        highMin: optimalMax,
      ),
    );
  }

  /// Pide una guía de nitrógeno con un déficit exacto.
  ///
  /// `deficitPpm` se logra fijando el punto medio del target y restando la
  /// lectura cruda: mid − raw = déficit.
  NutrientDoseGuide? guideForNitrogen({
    required double deficitPpm,
    String? cropKey,
    String? stageKey,
    String? scaleId,
    NutrientPriorityLabel label = NutrientPriorityLabel.actionRecommended,
    double rawPpm = 10.0,
  }) {
    final double mid = rawPpm + deficitPpm;
    return FertilizationPlanner.buildGuide(
      nutrient: AgroMetricKey.n,
      label: label,
      rawPpm: rawPpm,
      cropKey: cropKey,
      stageKey: stageKey,
      cultivationScaleId: scaleId,
      targets: targetsN(optimalMin: mid - 10.0, optimalMax: mid + 10.0),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. CASO DE CAMPO REAL — la única calibración que BIO-G tiene hoy
  // ───────────────────────────────────────────────────────────────────────────

  group('Caso de campo real · maíz, Chihuahua, ciclo 2026', () {
    /// Registro de la primera validación real del motor, hecha por el fundador
    /// sobre su propia parcela de maíz:
    ///
    /// > "para un rendimiento fuerte, al maíz le metemos 300 kg/ha de urea.
    /// > Cuando el maíz llegó a la etapa en la que tenía que ser fertilizado,
    /// > la aplicación me recomendó 300 kg/ha. Exactamente lo que yo le ponía
    /// > antes de la aplicación y que me ha funcionado bastante."
    ///
    /// Es UN punto: un cultivo, un suelo, una etapa. No prueba que el motor
    /// sea correcto en general —eso sigue pendiente de la bitácora de campo
    /// del §14.2— pero sí es el único anclaje con la realidad que existe, y
    /// cae justo en el cultivo y la etapa de mayor consecuencia económica.
    ///
    /// Por eso se congela aquí: cualquier cambio a la densidad aparente, a la
    /// profundidad, a la ley de la urea o a los targets del maíz que mueva
    /// este número tiene que romper esta prueba y obligar a una decisión
    /// explícita. Si algún día la bitácora de campo dice otra cosa, se cambia
    /// el número **y se anota por qué**.
    ///
    /// Aritmética del caso:
    ///   déficit 57.5 mg/kg × 2.4          = 138 kg/ha de N puro
    ///   138 kg/ha ÷ 0.46 (urea 46-0-0)    = 300 kg/ha de urea
    test('déficit de 57.5 mg/kg de N ⇒ ~300 kg/ha de urea', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 57.5,
        cropKey: 'maize',
        stageKey: 'vegMid',
        scaleId: 'field',
      );

      expect(guide, isNotNull);
      expect(guide!.doseGuideEs, contains('~138 kg/ha de Nitrógeno puro'));
      expect(
        guide.fertilizerEquivalentEs,
        contains('~300 kg/ha de Urea (46-0-0)'),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 2. LA FÓRMULA PUENTE (mg/kg → kg/ha)
  // ───────────────────────────────────────────────────────────────────────────

  group('Fórmula puente mg/kg → kg/ha', () {
    /// El corazón aritmético del motor:
    ///   kg/ha = déficit mg/kg × densidad aparente × profundidad cm ÷ 10
    ///         = déficit × 1.2 × 20 ÷ 10
    ///         = déficit × 2.4
    ///
    /// El 2.4 es una **convención**, no una constante universal: sale de
    /// suponer un suelo mineral de 1.2 g/cm³ muestreado a 20 cm. Con otra
    /// densidad u otra profundidad el factor cambia (la literatura publica
    /// desde 1.5 hasta 2.7). Hoy es fijo para todos los suelos.
    ///
    /// Esta prueba existe para que el día que se vuelva configurable —o que
    /// se decida cambiarlo— el cambio sea visible y deliberado.
    test('1 mg/kg de déficit equivale a 2.4 kg/ha', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 10.0,
        scaleId: 'field',
      );

      // 10 mg/kg × 2.4 = 24 kg/ha
      expect(guide, isNotNull);
      expect(guide!.doseGuideEs, contains('~24 kg/ha de Nitrógeno puro'));
    });

    /// El texto que ve el agricultor tiene que decir de dónde sale el número.
    /// Es un requisito de transparencia, no cosmético: sin los supuestos a la
    /// vista, una dosis parece un dato medido cuando en realidad es un dato
    /// calculado sobre una suposición de suelo.
    test('el texto declara los supuestos: 20 cm y 1.2 g/cm³', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 30.0,
        cropKey: 'maize',
        stageKey: 'vegMid',
        scaleId: 'field',
      );

      expect(guide?.fertilizerEquivalentEs, contains('20 cm'));
      expect(guide?.fertilizerEquivalentEs, contains('1.2 g/cm³'));
      expect(guide?.fertilizerEquivalentEs, contains('Déficit estimado'));
    });

    /// La dosis comercial de campo se redondea a múltiplos de 5 kg/ha:
    /// nadie compra 104.3 kg de urea, y fingir esa precisión es engañoso.
    ///
    ///   20 mg/kg × 2.4 = 48 kg/ha de N puro
    ///   48 ÷ 0.46      = 104.3 kg/ha de urea → se presenta 105
    test('la dosis comercial de campo se redondea a múltiplos de 5', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 20.0,
        scaleId: 'field',
      );

      expect(guide!.doseGuideEs, contains('~48 kg/ha de Nitrógeno puro'));
      expect(guide.fertilizerEquivalentEs, contains('~105 kg/ha'));
      expect(guide.fertilizerEquivalentEs, isNot(contains('104')));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 3. LA UNIDAD DEPENDE DE LA FORMA DEL CULTIVO
  // ───────────────────────────────────────────────────────────────────────────

  group('Unidad de la dosis según la forma de cultivo', () {
    /// Este grupo cubre el bug que motivó la reparación: el id canónico `bed`
    /// no coincidía con ninguna rama del formateador, así que una cama de
    /// huerto recibía la dosis en kg/ha de campo abierto. Un agricultor de
    /// traspatio leía "aplica 240 kg/ha" para un cantero de dos metros.
    ///
    /// Cada escala tiene que hablar en la unidad en que esa persona compra y
    /// aplica el fertilizante.
    test('campo abierto habla en kg/ha', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 100.0,
        scaleId: 'field',
      );
      expect(guide!.doseGuideEs, contains('kg/ha'));
    });

    test('huerto/cama habla en g/m² (id canónico "bed")', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 100.0,
        scaleId: 'bed',
      );
      expect(guide!.doseGuideEs, contains('g/m²'));
      expect(guide.doseGuideEs, isNot(contains('kg/ha')));
    });

    test('maceta habla en gramos por maceta', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 100.0,
        scaleId: 'pot',
      );
      expect(guide!.doseGuideEs, contains('por maceta'));
      expect(guide.doseGuideEs, isNot(contains('kg/ha')));
    });

    test('planta o árbol habla en gramos por planta', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 100.0,
        scaleId: 'plant',
      );
      expect(guide!.doseGuideEs, contains('por planta'));
      expect(guide.doseGuideEs, isNot(contains('kg/ha')));
    });

    /// Los ids que escribieron versiones anteriores del wizard tienen que
    /// seguir resolviendo igual. Si dejan de hacerlo, un usuario con un
    /// cultivo guardado hace meses empieza a recibir dosis de campo abierto
    /// sin haber cambiado nada.
    test('los alias e ids compuestos antiguos siguen resolviendo', () {
      for (final String alias in <String>['maceta', 'contenedor', 'scale_maceta_v1']) {
        expect(
          guideForNitrogen(deficitPpm: 100.0, scaleId: alias)!.doseGuideEs,
          contains('por maceta'),
          reason: 'el alias "$alias" debería resolver a maceta',
        );
      }
      for (final String alias in <String>['huerto', 'cama', 'm2', 'orchard']) {
        expect(
          guideForNitrogen(deficitPpm: 100.0, scaleId: alias)!.doseGuideEs,
          contains('g/m²'),
          reason: 'el alias "$alias" debería resolver a cama/huerto',
        );
      }
      for (final String alias in <String>['planta', 'arbol', 'árbol', 'tree']) {
        expect(
          guideForNitrogen(deficitPpm: 100.0, scaleId: alias)!.doseGuideEs,
          contains('por planta'),
          reason: 'el alias "$alias" debería resolver a planta',
        );
      }
      for (final String alias in <String>['campo', 'parcela']) {
        expect(
          guideForNitrogen(deficitPpm: 100.0, scaleId: alias)!.doseGuideEs,
          contains('kg/ha'),
          reason: 'el alias "$alias" debería resolver a campo abierto',
        );
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 4. MASA DE SUELO SUPUESTA POR ESCALA
  // ───────────────────────────────────────────────────────────────────────────

  group('Masa de suelo efectiva por escala', () {
    /// Maceta: 15 kg de sustrato. Planta/árbol: 5 kg de zona radicular.
    ///
    /// Son supuestos, igual que la densidad y la profundidad. Una maceta de
    /// balcón no tiene 15 kg, y un nogal adulto explora mucho más que 5 kg.
    /// Se congelan aquí para que el día que se parametricen quede claro qué
    /// número se movió.
    ///
    ///   maceta: 100 mg/kg × 15 kg ÷ 1000 = 1.5 g
    ///   planta: 100 mg/kg ×  5 kg ÷ 1000 = 0.5 g
    test('la maceta supone 15 kg de sustrato', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 100.0,
        scaleId: 'pot',
      );
      expect(guide!.doseGuideEs, contains('1.5 g de Nitrógeno puro por maceta'));
    });

    test('la planta supone 5 kg de zona radicular', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 100.0,
        scaleId: 'plant',
      );
      expect(guide!.doseGuideEs, contains('0.5 g de Nitrógeno puro por planta'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 5. FORMA DE CULTIVO DESCONOCIDA — comportamiento actual, a propósito
  // ───────────────────────────────────────────────────────────────────────────

  group('Forma de cultivo desconocida', () {
    /// Hoy, cuando no se sabe la forma del cultivo, el motor asume campo
    /// abierto y emite kg/ha. Eso NO es lo que pide el Fundacional 2.1 §9.3,
    /// que exige no emitir una dosis cuando falta el contexto para
    /// interpretarla.
    ///
    /// La prueba congela el comportamiento **actual**, no el deseado. Existe
    /// para que cuando se implemente la abstención ("no sé, dime la forma de
    /// tu cultivo") el cambio rompa esta prueba y se actualice a conciencia,
    /// en lugar de que el fallback cambie sin que nadie lo note.
    ///
    /// Nota: con el QR del hardware, la forma dejará de ser desconocida en la
    /// práctica —el dispositivo dirá si es campo, huerto o maceta— y este
    /// camino quedará solo para cultivos capturados a mano.
    test('sin escala, hoy asume campo abierto (pendiente §9.3)', () {
      final NutrientDoseGuide? sinEscala = guideForNitrogen(
        deficitPpm: 100.0,
        scaleId: null,
      );
      expect(sinEscala!.doseGuideEs, contains('kg/ha'));

      final NutrientDoseGuide? escalaVacia = guideForNitrogen(
        deficitPpm: 100.0,
        scaleId: '   ',
      );
      expect(escalaVacia!.doseGuideEs, contains('kg/ha'));

      final NutrientDoseGuide? escalaRara = guideForNitrogen(
        deficitPpm: 100.0,
        scaleId: 'no_es_una_escala',
      );
      expect(escalaRara!.doseGuideEs, contains('kg/ha'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 6. CUÁNDO EL MOTOR NO DEBE RECETAR
  // ───────────────────────────────────────────────────────────────────────────

  group('Casos en que no se emite dosis', () {
    test('sin etiqueta de acción no hay guía', () {
      for (final NutrientPriorityLabel label in <NutrientPriorityLabel>[
        NutrientPriorityLabel.unknown,
        NutrientPriorityLabel.noPriority,
        NutrientPriorityLabel.lowPriority,
      ]) {
        expect(
          guideForNitrogen(deficitPpm: 100.0, scaleId: 'field', label: label),
          isNull,
          reason: 'la etiqueta $label no debería producir una dosis',
        );
      }
    });

    test('sin targets de etapa no hay guía', () {
      final NutrientDoseGuide? guide = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 10.0,
        cropKey: 'maize',
        stageKey: 'vegMid',
        cultivationScaleId: 'field',
        targets: null,
      );
      expect(guide, isNull);
    });

    test('un déficit menor a 2 mg/kg se considera ruido, no receta', () {
      expect(
        guideForNitrogen(deficitPpm: 1.0, scaleId: 'field'),
        isNull,
      );
      expect(
        guideForNitrogen(deficitPpm: 0.0, scaleId: 'field'),
        isNull,
      );
    });

    test('lectura por encima del target no genera dosis', () {
      final NutrientDoseGuide? guide = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 200.0,
        cropKey: 'maize',
        stageKey: 'vegMid',
        cultivationScaleId: 'field',
        targets: targetsN(optimalMin: 60, optimalMax: 80),
      );
      expect(guide, isNull);
    });

    test('exceso detectado ⇒ pausa, y sin número de dosis', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 100.0,
        cropKey: 'maize',
        stageKey: 'vegMid',
        scaleId: 'field',
        label: NutrientPriorityLabel.possibleExcess,
      );

      expect(guide, isNotNull);
      expect(guide!.doseGuideEs.toLowerCase(), contains('pausa'));
      expect(guide.doseGuideEs, isNot(contains('kg/ha')));
      expect(guide.fertilizerEquivalentEs ?? '', isNot(contains('kg/ha')));
    });

    /// Fertilizar en madurez o cosecha es dinero tirado: la planta ya no lo
    /// va a usar. El motor tiene que decirlo, no calcular una dosis.
    test('maíz en etapa tardía no recibe dosis, recibe consejo de ciclo', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 100.0,
        cropKey: 'maize',
        stageKey: 'harvestMaturity',
        scaleId: 'field',
      );

      expect(guide, isNotNull);
      expect(guide!.doseGuideEs, isNot(contains('kg/ha')));
      expect(guide.doseGuideEs.toLowerCase(), contains('ciclo'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 7. LEYES DE LOS FERTILIZANTES COMERCIALES
  // ───────────────────────────────────────────────────────────────────────────

  group('Ley del fertilizante comercial', () {
    /// La conversión de nutriente puro a producto de saco:
    ///   Urea 46-0-0 → 46 % de N
    ///   DAP  18-46-0 → 46 % de P₂O₅
    ///   KCl  0-0-60  → 60 % de K₂O
    ///
    /// Un error aquí se traduce directo en sacos de más o de menos.
    test('la urea se calcula al 46 % de nitrógeno', () {
      // 50 mg/kg × 2.4 = 120 kg/ha de N puro; 120 ÷ 0.46 = 260.9 → 260
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 50.0,
        scaleId: 'field',
      );
      expect(guide!.doseGuideEs, contains('~120 kg/ha de Nitrógeno puro'));
      expect(guide.fertilizerEquivalentEs, contains('~260 kg/ha'));
    });

    test('el KCl se calcula al 60 % de K₂O', () {
      // 50 mg/kg × 2.4 = 120 kg/ha de K₂O puro; 120 ÷ 0.60 = 200
      final NutrientDoseGuide? guide = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.k,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 10.0,
        cropKey: null,
        stageKey: null,
        cultivationScaleId: 'field',
        targets: const StageTargets(
          moistureRaw: dummy,
          soilTemp: dummy,
          ph: dummy,
          ec: dummy,
          resistance: dummy,
          nIndex: dummy,
          pIndex: dummy,
          kIndex: dummy,
          kSoilPpmRange: AgroRange(
            lowMax: 50,
            optimalMin: 50,
            optimalMax: 70,
            highMin: 70,
          ),
        ),
      );

      expect(guide!.doseGuideEs, contains('~120 kg/ha de Potasio (K₂O) puro'));
      expect(guide.fertilizerEquivalentEs, contains('~200 kg/ha'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 7-bis. VENTANA DE APLICACIÓN ≠ VENTANA DE DEMANDA
  // ───────────────────────────────────────────────────────────────────────────

  group('Maíz · cuándo aplicar no es cuándo lo consume', () {
    /// El maíz absorbe más de la mitad de su nitrógeno entre el estirón y el
    /// espigamiento, en un tramo que puede durar apenas 30 días. Por eso la
    /// recomendación tiene que llegar **antes**: en el estirón, no en el pico.
    test('en el estirón se recomienda por anticipado', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 57.5,
        cropKey: 'maize',
        stageKey: 'vegMid',
        scaleId: 'field',
      );

      expect(guide!.doseGuideEs, contains('estirón'));
      expect(guide.doseGuideEs, contains('ahora'));
      expect(guide.fertilizerEquivalentEs, contains('ventana buena'));
      // La dosis del caso de campo real no se movió.
      expect(guide.fertilizerEquivalentEs, contains('~300 kg/ha de Urea'));
    });

    /// Para cuando la milpa espiga ya absorbió el 63–67 % de su nitrógeno, y
    /// el número de hileras de grano quedó fijado semanas antes. Sigue
    /// habiendo respuesta si la carencia es real —Kentucky recuperó potencial
    /// en 8 de 13 sitios— pero Purdue midió que el valor se parte a la mitad
    /// respecto a aplicar en el estirón.
    ///
    /// El motor tiene que decirlo, no tratar el espigamiento como si fuera la
    /// misma oportunidad.
    test('en espigamiento se recomienda como rescate, no como plan', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 57.5,
        cropKey: 'maize',
        stageKey: 'tasseling',
        scaleId: 'field',
      );

      expect(guide, isNotNull);
      expect(guide!.doseGuideEs, contains('espigando'));
      expect(guide.fertilizerEquivalentEs!.toLowerCase(), contains('rescate'));
      expect(
        guide.doseGuideEs,
        isNot(contains('estirón')),
        reason: 'el espigamiento no debe presentarse como la ventana buena',
      );
      // Sigue dando el número: es rescate, no prohibición.
      expect(guide.doseGuideEs, contains('~138 kg/ha de Nitrógeno puro'));
    });

    test('el ciclo cerrado sigue sin recibir dosis', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 57.5,
        cropKey: 'maize',
        stageKey: 'harvestMaturity',
        scaleId: 'field',
      );
      expect(guide!.doseGuideEs, isNot(contains('kg/ha')));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 8. ÁRBOLES FRUTALES — nunca una dosis de campo abierto
  // ───────────────────────────────────────────────────────────────────────────

  group('Árboles frutales', () {
    /// Los nueve frutales perennes que el motor de recomendación reconoce como
    /// árbol (`_isFruitTreeCrop`) comparten una regla: **no se les receta una
    /// dosis en kg/ha**. Un árbol no se fertiliza por hectárea de suelo removido
    /// a 20 cm; se corrige de forma gradual, mirando etapa, agua, sales y pH, y
    /// se confirma con análisis de suelo y hoja.
    ///
    /// Manzano y pera eran los dos únicos de la lista sin guía propia en el
    /// planner: tenían catálogo, motor de score, modificador de nutrición y
    /// recomendación práctica propios, pero al llegar la dosis caían al genérico
    /// y salían con kg/ha de campo abierto.
    ///
    /// Esta prueba recorre los nueve. Si mañana se agrega un frutal nuevo y se
    /// olvida su guía, el mismo agujero se abre otra vez — agrégalo aquí.
    const List<String> frutales = <String>[
      'manzano',
      'apple_tree',
      'peral',
      'pear_tree',
      'durazno',
      'nogal',
      'pistache',
      'naranjo',
      'limon',
      'mango',
      'aguacate',
    ];

    test('ningún frutal recibe una dosis en kg/ha ni en g/m²', () {
      for (final String crop in frutales) {
        final NutrientDoseGuide? guide = guideForNitrogen(
          deficitPpm: 100.0,
          cropKey: crop,
          stageKey: 'fruit_fill',
          scaleId: 'field',
        );

        expect(guide, isNotNull, reason: '$crop debería recibir guía de árbol');
        expect(
          guide!.doseGuideEs,
          isNot(contains('kg/ha')),
          reason: '$crop no debe recibir una dosis de campo abierto',
        );
        expect(
          guide.doseGuideEs,
          isNot(contains('g/m²')),
          reason: '$crop no debe recibir una dosis de cama de huerto',
        );
        expect(
          guide.requiresConfirmation,
          isTrue,
          reason: '$crop debe pedir confirmación antes de aplicar',
        );
      }
    });

    test('el manzano habla de manzano y advierte del calcio', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 100.0,
        cropKey: 'manzano',
        stageKey: 'fruit_fill',
        scaleId: 'field',
      );

      expect(guide!.doseGuideEs, contains('manzano'));
      expect(guide.doseGuideEs, contains('potasio'));
      expect(guide.fertilizerEquivalentEs, contains('calcio'));
      expect(guide.fertilizerEquivalentEs, contains('análisis'));
    });

    test('el peral advierte del fuego bacteriano por exceso de N', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 100.0,
        cropKey: 'peral',
        stageKey: 'budbreak',
        scaleId: 'field',
        label: NutrientPriorityLabel.possibleExcess,
      );

      expect(guide!.doseGuideEs, contains('peral'));
      expect(guide.doseGuideEs, contains('fuego bacteriano'));
      expect(guide.doseGuideEs, isNot(contains('kg/ha')));
    });

    /// El exceso en un árbol tampoco puede salir con número: tiene que salir
    /// con un "no apliques más".
    /// Con la cosecha esperada en mano, el frutal deja de dar solo criterio y
    /// pasa a dar cantidad. Sin ella, se comporta exactamente como antes.
    test('con cosecha esperada, el manzano da gramos por árbol', () {
      final NutrientDoseGuide? guide = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 10.0,
        cropKey: 'manzano',
        stageKey: 'fruit_fill',
        cultivationScaleId: 'field',
        targets: targetsN(optimalMin: 100, optimalMax: 120),
        kgFruitPerTree: 40.0,
      );

      // 40 kg × 0.60 ÷ 0.38 × 1.5 ÷ 0.65 = 146 g de N ⇒ 150 redondeado
      expect(guide!.doseGuideEs, contains('150 g por árbol'));
      expect(guide.doseGuideEs, contains('320 g de Urea'));
      expect(guide.doseGuideEs, isNot(contains('kg/ha')));
      // La transparencia declara la cosecha y la fuente del coeficiente.
      expect(guide.fertilizerEquivalentEs, contains('40 kg'));
      expect(guide.fertilizerEquivalentEs, contains('WSU'));
    });

    /// Guardia de regresión: si nadie pasa la cosecha esperada —que es el caso
    /// de los quince motores de score hoy— la salida no cambia ni un carácter.
    test('sin cosecha esperada, el comportamiento es el de antes', () {
      final NutrientDoseGuide? guide = guideForNitrogen(
        deficitPpm: 100.0,
        cropKey: 'manzano',
        stageKey: 'fruit_fill',
        scaleId: 'field',
      );

      expect(guide!.doseGuideEs, isNot(contains('g por árbol')));
      expect(guide.doseGuideEs, contains('manzano'));
    });

    /// La ventana de aplicación no es la ventana de demanda.
    ///
    /// En brotación y floración el árbol vive de las reservas que cargó el
    /// ciclo pasado: en manzano, el 87 % del nitrógeno del crecimiento nuevo
    /// viene de reserva, y a 8 °C de suelo la raíz no absorbe hasta 21 días
    /// después de la brotación. Poner un número aquí sería cobrarle al
    /// agricultor por algo que el árbol no puede tomar.
    test('en floración se calla el número y explica por qué', () {
      final NutrientDoseGuide? guide = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 10.0,
        cropKey: 'manzano',
        stageKey: 'flowering',
        cultivationScaleId: 'field',
        targets: targetsN(optimalMin: 100, optimalMax: 120),
        kgFruitPerTree: 40.0,
      );

      expect(guide!.doseGuideEs, isNot(contains('g por árbol')));
      expect(guide.doseGuideEs, contains('reservas'));
    });

    test('cerca de la cosecha tampoco se pone número de nitrógeno', () {
      final NutrientDoseGuide? guide = FertilizationPlanner.buildGuide(
        nutrient: AgroMetricKey.n,
        label: NutrientPriorityLabel.actionRecommended,
        rawPpm: 10.0,
        cropKey: 'peral',
        stageKey: 'harvest_maturity',
        cultivationScaleId: 'field',
        targets: targetsN(optimalMin: 100, optimalMax: 120),
        kgFruitPerTree: 35.0,
      );

      expect(guide!.doseGuideEs, isNot(contains('g por árbol')));
      expect(guide.doseGuideEs.toLowerCase(), contains('madurez'));
    });

    test('exceso en frutal ⇒ pausa razonada, sin dosis', () {
      for (final String crop in <String>['manzano', 'peral']) {
        final NutrientDoseGuide? guide = guideForNitrogen(
          deficitPpm: 100.0,
          cropKey: crop,
          stageKey: 'fruit_fill',
          scaleId: 'field',
          label: NutrientPriorityLabel.reviewAccumulation,
        );

        expect(guide!.doseGuideEs, contains('alto'));
        expect(guide.doseGuideEs.toLowerCase(), contains('no apliques'));
        expect(guide.doseGuideEs, isNot(contains('kg/ha')));
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Anexo v1.5 — Contrato de interoperabilidad etapa/NPK/copy/UI
  // ───────────────────────────────────────────────────────────────────────────
  //
  // "Queda prohibido agrupar etapas para copy UX cuando esa agrupacion borra
  //  diferencias agronomicas reales, especialmente fruit_fill vs
  //  harvest_maturity."
  //
  // Estas pruebas no juzgan agronomía: fijan el CONTRATO. Si una falla, alguien
  // volvió a mezclar cuajado, llenado, madurez o postcosecha en un solo texto.
  group('Anexo v1.5 · identidad de etapa en la guía de los nueve frutales', () {
    const List<String> arboles = <String>[
      'apple_tree',
      'pear_tree',
      'peach_tree',
      'walnut_tree',
      'pistachio_tree',
      'orange_tree',
      'lemon_tree',
      'mango_tree',
      'avocado_tree',
    ];

    String guia(String crop, String stage) {
      final NutrientDoseGuide? g = guideForNitrogen(
        deficitPpm: 100.0,
        cropKey: crop,
        stageKey: stage,
        scaleId: 'field',
      );
      expect(g, isNotNull, reason: '$crop/$stage debe recibir guía de árbol');
      return g!.doseGuideEs;
    }

    /// Deja solo lo que comunica IDENTIDAD de etapa.
    ///
    /// "postcosecha" es el nombre de otra etapa, no una fuga. Y "todavía no
    /// cosecha" es el desambiguador explícito que el anexo premia: negar la
    /// cosecha es cumplir el contrato, no romperlo.
    String soloIdentidad(String texto) => texto
        .toLowerCase()
        .replaceAll('postcosecha', '')
        .replaceAll('poscosecha', '')
        .replaceAll('todavía no cosecha', '')
        .replaceAll('todavia no cosecha', '');

    test('llenado nunca se comunica como cosecha ni como madurez', () {
      for (final String crop in arboles) {
        final String texto = soloIdentidad(guia(crop, 'fruit_fill'));
        for (final String prohibido in const <String>[
          'cerca de cosecha',
          'cosecha',
          'madurez',
          'maduracion',
          'maduración',
        ]) {
          expect(
            texto,
            isNot(contains(prohibido)),
            reason: '$crop en llenado no puede decir "$prohibido"',
          );
        }
        expect(texto, contains('llenado'), reason: crop);
      }
    });

    test('cuajado no se comunica como llenado avanzado ni como cosecha', () {
      for (final String crop in arboles) {
        final String texto = soloIdentidad(guia(crop, 'fruit_set'));
        expect(texto, isNot(contains('llenado')), reason: crop);
        expect(texto, isNot(contains('cosecha')), reason: crop);
        expect(texto, isNot(contains('madurez')), reason: crop);
        expect(
          texto,
          anyOf(contains('cuajado'), contains('amarre')),
          reason: crop,
        );
      }
    });

    test('madurez conserva copy propio', () {
      for (final String crop in arboles) {
        expect(
          guia(crop, 'harvest_maturity').toLowerCase(),
          anyOf(contains('madurez'), contains('cosecha')),
          reason: crop,
        );
      }
    });

    test('postcosecha habla de reservas, no de cultivo cerrado', () {
      for (final String crop in arboles) {
        final String texto = guia(crop, 'post_harvest').toLowerCase();
        expect(texto, contains('postcosecha'), reason: crop);
        expect(
          texto,
          anyOf(contains('reserva'), contains('hoja')),
          reason: crop,
        );
      }
    });

    test('cuajado, llenado y madurez dan TRES textos distintos', () {
      for (final String crop in arboles) {
        final String set = guia(crop, 'fruit_set');
        final String fill = guia(crop, 'fruit_fill');
        final String harvest = guia(crop, 'harvest_maturity');
        expect(set, isNot(fill), reason: '$crop: cuajado ≠ llenado');
        expect(fill, isNot(harvest), reason: '$crop: llenado ≠ madurez');
        expect(set, isNot(harvest), reason: '$crop: cuajado ≠ madurez');
      }
    });

    test('los caducifolios tienen rama propia de reposo', () {
      // Duraznero, nogal y pistachero caían al texto genérico, el mismo que una
      // etapa desconocida. Manzano y peral sí la tenían.
      for (final String crop in const <String>[
        'apple_tree',
        'pear_tree',
        'peach_tree',
        'walnut_tree',
        'pistachio_tree',
      ]) {
        final String reposo = guia(crop, 'dormancy');
        expect(reposo, isNot(guia(crop, 'unknown')), reason: crop);
        expect(reposo.toLowerCase(), contains('reposo'), reason: crop);
      }
    });

    test('un id de etapa no cerrado NO hereda el copy de una etapa real', () {
      // "Copy UX debe derivarse de la etapa normalizada, no de cadenas
      //  ambiguas como stage.contains(...) cuando existen IDs cerrados."
      for (final String falso in const <String>[
        'fruit_fill_tardio',
        'pre_fruit_set',
        'harvest_maturity_2',
      ]) {
        final String texto = guia('apple_tree', falso);
        expect(texto, isNot(contains('En llenado')), reason: falso);
        expect(texto, isNot(contains('En cuajado')), reason: falso);
        expect(texto, isNot(contains('En madurez')), reason: falso);
      }
    });
  });
}
