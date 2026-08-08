/// =========================================================================
/// MOTOR DE RESTITUCIÓN PARA CULTIVOS PERENNES
/// =========================================================================
///
/// Calcula cuánto fertilizante necesita **un árbol**, en gramos por árbol.
///
/// POR QUÉ EXISTE
/// --------------
/// El `FertilizationPlanner` convierte un déficit de suelo (mg/kg) a dosis
/// mediante el puente `× 2.4`. Ese camino está validado en campo para maíz,
/// pero **ninguna de las nueve guías de fertilización de BIO-G lo respalda
/// para un árbol**. Las nueve niegan explícitamente que la lectura del sensor
/// sea una dosis ("Cap NO es dosis" aparece literal en nogal, durazno,
/// pistache, naranjo, limón y mango).
///
/// Lo que las nueve sí usan es **restitución**: no se pregunta cuánto le falta
/// al suelo, se pregunta cuánto se va a llevar la cosecha, y se repone eso,
/// modulado por lo que el suelo ya trae.
///
/// LA CADENA
/// ---------
/// ```
/// remoción   = kg de fruta por árbol × coeficiente de extracción
/// demanda    = remoción ÷ fracción que va al fruto
/// aporte     = demanda × factor de suelo        ← aquí entra el sensor BIO-G
/// dosis      = aporte ÷ eficiencia del fertilizante
/// ```
///
/// Cada factor tiene nombre, fuente y nivel de confianza. Ninguno es un número
/// inventado, y los que son derivados están marcados como tales.
///
/// QUÉ NO HACE
/// -----------
/// No toca el motor de anuales. Maíz, frijol, trigo, cebada y hortalizas
/// siguen con su camino de siempre. Este es un segundo carril, exclusivo para
/// perennes, y devuelve `null` en cuanto le falta un dato en vez de inventarlo.
/// =========================================================================
library;

import 'package:bio_g/core/agro/agro_types.dart';

/// Qué tan sólido es un coeficiente. Se propaga hasta la interfaz para que el
/// productor sepa si el número es firme o es una referencia.
enum TreeDataConfidence {
  /// Varias fuentes independientes coinciden dentro de un margen estrecho.
  alta,

  /// Fuente clara pero única, o coincidencia con dispersión notable.
  media,

  /// Derivado por cálculo, no medido. Debe revisarse con un agrónomo.
  derivado,
}

/// Base sobre la que se mide el producto cosechado.
///
/// Mezclar bases es el error que más caro sale: en nogal y pistache, pasar de
/// "con cáscara" a "grano" casi duplica el coeficiente.
enum TreeYieldBasis {
  /// Fruta fresca tal como sale del huerto.
  frutaFresca,

  /// Nuez con cáscara (in-shell), no almendra.
  nuezConCascara,

  /// Producto seco con cáscara, como se comercializa el pistache.
  secoConCascara,
}

/// Coeficiente de extracción de un cultivo, en kg de nutriente por tonelada de
/// producto cosechado.
///
/// **Todo se guarda en forma de óxido** (P₂O₅ y K₂O), nunca elemental. Las
/// fuentes mezclan las dos formas —a veces dentro del mismo documento— y el
/// factor entre ellas es 2.291 para el fósforo y 1.205 para el potasio. Un
/// coeficiente elemental cargado donde el código espera óxido deja el fósforo
/// 2.3 veces bajo, y el número sigue pareciendo razonable.
class TreeExtractionCoefficients {
  const TreeExtractionCoefficients({
    required this.nKgPerTon,
    required this.p2o5KgPerTon,
    required this.k2oKgPerTon,
    required this.basis,
    required this.confidence,
    required this.sourceEs,
  });

  /// kg de N por tonelada de producto cosechado.
  final double nKgPerTon;

  /// kg de P₂O₅ (óxido, no P elemental) por tonelada.
  final double p2o5KgPerTon;

  /// kg de K₂O (óxido, no K elemental) por tonelada.
  final double k2oKgPerTon;

  final TreeYieldBasis basis;
  final TreeDataConfidence confidence;

  /// Fuente citable. Va al texto de transparencia y a la bitácora auditable.
  final String sourceEs;

  double forNutrient(AgroMetricKey nutrient) => switch (nutrient) {
    AgroMetricKey.n => nKgPerTon,
    AgroMetricKey.p => p2o5KgPerTon,
    AgroMetricKey.k => k2oKgPerTon,
    _ => 0.0,
  };
}

/// Nivel de suministro del suelo, derivado de la lectura del sensor.
///
/// Esta es la contribución real de BIO-G al cálculo: nadie más tiene la banda
/// del suelo medida en la parcela cada dos horas. El sensor no fija la dosis
/// —eso lo hace la cosecha esperada— pero sí la modula, que es el papel que la
/// agronomía le reconoce.
enum SoilSupplyLevel { bajo, medio, alto, muyAlto }

class TreeRestitutionResult {
  const TreeRestitutionResult({
    required this.nutrient,
    required this.gramsPerTreeNutrient,
    required this.gramsPerTreeCommercial,
    required this.commercialSourceEs,
    required this.kgFruitPerTree,
    required this.coefficients,
    required this.soilLevel,
    required this.soilFactor,
  });

  /// Nutriente puro, en gramos por árbol y por ciclo.
  final double gramsPerTreeNutrient;

  /// Producto comercial equivalente (urea, DAP, KCl), en gramos por árbol.
  final double gramsPerTreeCommercial;

  final String commercialSourceEs;
  final AgroMetricKey nutrient;
  final double kgFruitPerTree;
  final TreeExtractionCoefficients coefficients;
  final SoilSupplyLevel soilLevel;
  final double soilFactor;

  /// kg/ha equivalentes. Solo tiene sentido si se conoce la densidad; por eso
  /// se calcula bajo demanda y no se guarda.
  double? kgPerHectare(double? treesPerHectare) {
    if (treesPerHectare == null || treesPerHectare <= 0) return null;
    return (gramsPerTreeNutrient * treesPerHectare) / 1000.0;
  }

  /// Texto que declara de dónde sale el número. No es adorno: sin los
  /// supuestos a la vista, una dosis calculada parece una dosis medida.
  String get transparencyEs {
    final String prod = switch (coefficients.basis) {
      TreeYieldBasis.frutaFresca => 'fruta',
      TreeYieldBasis.nuezConCascara => 'nuez con cáscara',
      TreeYieldBasis.secoConCascara => 'producto seco con cáscara',
    };
    return 'Calculado sobre ${kgFruitPerTree.toStringAsFixed(0)} kg de $prod '
        'por árbol y una extracción de '
        '${coefficients.forNutrient(nutrient).toStringAsFixed(2)} kg/t '
        '(${coefficients.sourceEs}). El suelo se leyó ${_soilLabel(soilLevel)}, '
        'que ajusta la dosis a ${(soilFactor * 100).round()} % de la demanda.';
  }

  static String _soilLabel(SoilSupplyLevel level) => switch (level) {
    SoilSupplyLevel.bajo => 'bajo',
    SoilSupplyLevel.medio => 'en rango',
    SoilSupplyLevel.alto => 'alto',
    SoilSupplyLevel.muyAlto => 'muy alto',
  };
}

class TreeRestitutionPlanner {
  TreeRestitutionPlanner._();

  // ══════════════════════════════════════════════════════════════════════════
  // 1. COEFICIENTES DE EXTRACCIÓN — kg por tonelada de producto cosechado
  // ══════════════════════════════════════════════════════════════════════════
  //
  // Todos en óxidos. Todos son REMOCIÓN por el producto que sale del huerto,
  // no demanda anual total del árbol: esa distinción se maneja aparte, en
  // `_fruitFraction`, para que cada supuesto quede a la vista por separado.
  //
  // Tres de estos coeficientes CORRIGEN el valor que traían los documentos
  // internos de BIO-G. Las correcciones están anotadas una por una porque son
  // errores que mueven dinero real.

  static const Map<String, TreeExtractionCoefficients>
  _coefficients = <String, TreeExtractionCoefficients>{
    // ── MANZANO ───────────────────────────────────────────────────────────
    // El único de los nueve que los documentos internos no publicaban.
    // K es el más firme: Cornell 1.32, Haifa 1.3, Yara 1.4, APAL 1.2 y un
    // estudio mexicano de portainjertos 1.20–1.44, todos en K elemental y
    // dentro de ±10 %.
    // Cuidado documentado: Intagri publica 2.0 kg N/t rotulado como extracción
    // de fruto. Eso exigiría 0.2 % de N en manzana fresca, cuando la USDA mide
    // 0.04 %. Es demanda total mal etiquetada; usarlo sobrestima el N ~4×.
    'apple_tree': TreeExtractionCoefficients(
      nKgPerTon: 0.60,
      p2o5KgPerTon: 0.30, // 0.13 kg P elemental × 2.291
      k2oKgPerTon: 1.63, // 1.35 kg K elemental × 1.205
      basis: TreeYieldBasis.frutaFresca,
      confidence: TreeDataConfidence.media,
      sourceEs: 'WSU Tree Fruit, Cornell (Cheng & Raba), Yara y Haifa',
    ),

    // ── PERA ──────────────────────────────────────────────────────────────
    // Los 0.73 y 2.78 que traía el documento interno resultaron ser P₂O₅ y
    // K₂O de **extracción total del árbol** (fruto + hoja + rama + tronco +
    // raíz), no remoción de fruta. Contra la composición real del fruto son
    // 2.65× y 1.99× más altos. Aquí se usa la remoción de fruta, coherente
    // con los otros ocho cultivos.
    'pear_tree': TreeExtractionCoefficients(
      nKgPerTon: 0.80,
      p2o5KgPerTon: 0.34,
      k2oKgPerTon: 1.60,
      basis: TreeYieldBasis.frutaFresca,
      confidence: TreeDataConfidence.media,
      sourceEs: 'Composición USDA de pera + literatura de pomáceas',
    ),

    // ── DURAZNO ───────────────────────────────────────────────────────────
    // CORRECCIÓN. El documento interno traía 3.31 / 1.41 / 4.19, que son
    // 2–4× la remoción real. No es error de óxido: es una **dosis de
    // fertilización** de INIA Chile ("kg de nutriente a aplicar por tonelada
    // producida", 4–5 N / 2–3 P₂O₅ / 6–8 K₂O) usada como si fuera extracción.
    // La propia Haifa publica la remoción: 1.2 N / 0.15 P / 2.5 K elemental.
    'peach_tree': TreeExtractionCoefficients(
      nKgPerTon: 1.30,
      p2o5KgPerTon: 0.40,
      k2oKgPerTon: 2.50,
      basis: TreeYieldBasis.frutaFresca,
      confidence: TreeDataConfidence.alta,
      sourceEs: 'UC Davis / CDFA, Haifa y Yara stone fruit',
    ),

    // ── NOGAL PECANERO ────────────────────────────────────────────────────
    // CORRECCIÓN GRANDE. El documento interno traía "8–10 kg de N por cada
    // 100 kg de nuez" = 80–100 kg N/t, tomado como extracción. No lo es: es
    // la regla de dosis de UGA ("10 lbs of nitrogen/acre for every 100 lbs of
    // expected crop"). La remoción real es ~10× menor.
    // Tres evidencias independientes: la almendra tiene 9.3 g de proteína por
    // 100 g, lo que da ~9.4 kg N/t con cáscara; Yara sitúa las nueces en
    // 8.5–50 kg N/t con el pecán en el piso; y un estudio isotópico con ¹⁵N
    // midió que la cosecha remueve el 4 % del N aplicado — con 80–100 kg N/t
    // habría removido más del 50 %.
    // P y K de UGA Extension, validados por composición USDA × 53.7 % de
    // rendimiento en almendra: el cálculo independiente da 1.50–1.96 kg P/t y
    // 2.23–2.27 kg K/t, y UGA publica 1.6 y 2.3.
    'walnut_tree': TreeExtractionCoefficients(
      nKgPerTon: 9.0,
      p2o5KgPerTon: 3.67, // 1.6 kg P elemental × 2.291
      k2oKgPerTon: 2.77, // 2.3 kg K elemental × 1.205
      basis: TreeYieldBasis.nuezConCascara,
      confidence: TreeDataConfidence.media,
      sourceEs: 'UGA Extension, validado con composición USDA y Yara',
    ),

    // ── PISTACHE ──────────────────────────────────────────────────────────
    // CORRECCIÓN. El K interno decía 64 kg K₂O/t; el valor real es 29.
    // El error se rastreó: Herogra cita a UC Davis, que publica "24 lbs of K
    // (29 lbs K2O) removed per 1000 lbs of marketable yield". Como lb por
    // 1000 lb es una razón de masa, 29 lb/1000 lb = 29 kg/t directo, sin
    // convertir. Herogra multiplicó por 2.2046 solo el numerador: 29 × 2.2046
    // = 63.9 ≈ 64. La prueba de que es error: en la misma página reportan
    // P₂O₅ = 7, el número idéntico de UC Davis, sin convertir.
    // Consecuencia práctica: se venía sobrefertilizando potasio 2.2×.
    'pistachio_tree': TreeExtractionCoefficients(
      nKgPerTon: 28.0,
      p2o5KgPerTon: 7.0,
      k2oKgPerTon: 29.0,
      basis: TreeYieldBasis.secoConCascara,
      confidence: TreeDataConfidence.alta,
      sourceEs: 'UC Davis / CDFA FREP',
    ),

    // ── NARANJO ───────────────────────────────────────────────────────────
    // Verificado sin cambios. La fuente original publica 1.18–1.90 kg N,
    // 0.17–0.25 kg P y 1.77–2.03 kg K por tonelada de naranja fresca, y
    // Molina & Morales (Valencia, Costa Rica) suben P a 0.30 y K a 2.33.
    // Aquí se toma el centro del rango documentado.
    'orange_tree': TreeExtractionCoefficients(
      nKgPerTon: 1.50,
      p2o5KgPerTon: 0.55,
      k2oKgPerTon: 2.60,
      basis: TreeYieldBasis.frutaFresca,
      confidence: TreeDataConfidence.alta,
      sourceEs: 'Repositorio UNAL y Molina & Morales (1994)',
    ),

    // ── LIMÓN ─────────────────────────────────────────────────────────────
    // CORRECCIÓN en fósforo. El documento interno traía 1.86 N / 0.42 P /
    // 2.49 K, pero la fuente real (Terra Latinoamericana, limón mexicano)
    // dice 1.86 N / **0.17** P / 2.25 K. El 0.42 y el 2.49 venían de otro
    // paper, de limón **persa**: la fila mezclaba dos especies.
    'lemon_tree': TreeExtractionCoefficients(
      nKgPerTon: 1.86,
      p2o5KgPerTon: 0.39, // 0.17 kg P elemental × 2.291
      k2oKgPerTon: 2.71, // 2.25 kg K elemental × 1.205
      basis: TreeYieldBasis.frutaFresca,
      confidence: TreeDataConfidence.media,
      sourceEs: 'Terra Latinoamericana, limón mexicano',
    ),

    // ── MANGO ─────────────────────────────────────────────────────────────
    // Ajustado a la baja. El 1.44 N interno queda por encima de todas las
    // mediciones mexicanas publicadas (Terra Latinoamericana 2019 mide
    // 0.78–1.2 kg N/t en siete combinaciones de cultivar y región). Sobrevive
    // solo contra el rango global, que incluye outliers. Se usa el centro del
    // rango mexicano.
    'mango_tree': TreeExtractionCoefficients(
      nKgPerTon: 1.10,
      p2o5KgPerTon: 0.34, // 0.15 kg P elemental × 2.291
      k2oKgPerTon: 2.05, // 1.70 kg K elemental × 1.205
      basis: TreeYieldBasis.frutaFresca,
      confidence: TreeDataConfidence.media,
      sourceEs: 'Terra Latinoamericana (2019) y National Mango Board',
    ),

    // ── AGUACATE ──────────────────────────────────────────────────────────
    // Verificado sin cambios, y es el mejor sustentado de los nueve.
    // Haifa publica la tabla "extracción por cada 20 toneladas de fruta
    // cosechada" = 51 N / 22 P₂O₅ / 94 K₂O, que dividida entre 20 da exacto
    // 2.55 / 1.10 / 4.70. Salazar-García (INIFAP, Hass en Nayarit) obtiene
    // 51.5 / 20.6 / 93.8 de forma independiente. Y el P elemental equivalente
    // (1.10 ÷ 2.291 = 0.48) coincide al centésimo con lo que reporta NZ
    // Avocado sobre fruta entera.
    // Nota: en potasio este valor es el piso del rango mundial; NZ da 6.16 y
    // UC Davis 7.2–8.4 kg K₂O/t. Se deja el conservador a propósito.
    'avocado_tree': TreeExtractionCoefficients(
      nKgPerTon: 2.55,
      p2o5KgPerTon: 1.10,
      k2oKgPerTon: 4.70,
      basis: TreeYieldBasis.frutaFresca,
      confidence: TreeDataConfidence.alta,
      sourceEs: 'Haifa y Salazar-García (INIFAP, Nayarit)',
    ),
  };

  // ══════════════════════════════════════════════════════════════════════════
  // 2. FRACCIÓN QUE VA AL FRUTO
  // ══════════════════════════════════════════════════════════════════════════
  //
  // La cosecha no es toda la demanda del árbol: cada año también construye
  // hoja, brote, madera y raíz. Fertilizar solo la remoción deja al árbol
  // corto.
  //
  // Cheng & Raba (Cornell) midieron el reparto en manzano: el fruto contiene
  // el 37.6 % del nitrógeno y el 71.3 % del potasio del crecimiento nuevo. La
  // diferencia entre los dos números es agronomía real, no ruido: el N se va
  // masivamente a la hoja, el K se concentra en el fruto.
  //
  // El fósforo NO tiene medición equivalente en la literatura consultada. El
  // 0.50 es un valor intermedio elegido por nosotros: es el número más débil
  // de todo el motor y está marcado como tal para que un agrónomo lo revise.
  static const double _fruitFractionN = 0.38;
  static const double _fruitFractionP = 0.50; // ← DERIVADO, el más débil
  static const double _fruitFractionK = 0.71;

  static double _fruitFraction(AgroMetricKey nutrient) => switch (nutrient) {
    AgroMetricKey.n => _fruitFractionN,
    AgroMetricKey.p => _fruitFractionP,
    AgroMetricKey.k => _fruitFractionK,
    _ => 1.0,
  };

  // ══════════════════════════════════════════════════════════════════════════
  // 3. FACTOR DE SUELO — la contribución del sensor
  // ══════════════════════════════════════════════════════════════════════════
  //
  // Regla textual de la guía de pera de BIO-G (§14B.4):
  //   «Si el nivel de P/K en suelo es bajo: aporte = exportación × 1.5.
  //    Si el nivel es medio: aporte = exportación. Si el nivel es alto: 50 %.
  //    Si el nivel es muy alto: no aportar.»
  //
  // Es la única regla completa de ajuste por suelo en las nueve guías, y
  // necesita exactamente lo que el sensor BIO-G entrega.
  static const Map<SoilSupplyLevel, double> _soilFactors =
      <SoilSupplyLevel, double>{
        SoilSupplyLevel.bajo: 1.5,
        SoilSupplyLevel.medio: 1.0,
        SoilSupplyLevel.alto: 0.5,
        SoilSupplyLevel.muyAlto: 0.0,
      };

  /// Traduce la etiqueta de prioridad del motor al nivel de suministro.
  ///
  /// Devuelve `null` cuando no hay información suficiente: el motor prefiere
  /// callarse antes que suponer que el suelo está en rango.
  static SoilSupplyLevel? soilLevelFor(NutrientPriorityLabel label) =>
      switch (label) {
        NutrientPriorityLabel.actionRecommended ||
        NutrientPriorityLabel.highPriority => SoilSupplyLevel.bajo,
        NutrientPriorityLabel.mediumPriority ||
        NutrientPriorityLabel.reviewManagement ||
        NutrientPriorityLabel.noPriority ||
        NutrientPriorityLabel.lowPriority => SoilSupplyLevel.medio,
        NutrientPriorityLabel.possibleExcess => SoilSupplyLevel.alto,
        NutrientPriorityLabel.reviewAccumulation => SoilSupplyLevel.muyAlto,
        NutrientPriorityLabel.unknown => null,
      };

  // ══════════════════════════════════════════════════════════════════════════
  // 4. EFICIENCIA DEL FERTILIZANTE
  // ══════════════════════════════════════════════════════════════════════════
  //
  // No todo lo aplicado llega a la raíz. Cifras de las guías internas de limón
  // (método de restitución, Morelos) y aguacate (Fertilab, riego localizado),
  // que coinciden en 65 % para nitrógeno.
  //
  // El fósforo es el que más se pierde por fijación en el suelo, con
  // diferencia — de ahí el 25 %. Mango cita rangos alternativos: N 30–50 %,
  // P 15–30 %, K 40–60 %.
  static const double _efficiencyN = 0.65;
  static const double _efficiencyP = 0.25;
  static const double _efficiencyK = 0.80;

  static double _efficiency(AgroMetricKey nutrient) => switch (nutrient) {
    AgroMetricKey.n => _efficiencyN,
    AgroMetricKey.p => _efficiencyP,
    AgroMetricKey.k => _efficiencyK,
    _ => 1.0,
  };

  // ══════════════════════════════════════════════════════════════════════════
  // 5. LEY DEL FERTILIZANTE COMERCIAL
  // ══════════════════════════════════════════════════════════════════════════
  static const double _leyUrea = 0.46; // 46-0-0
  static const double _leyDap = 0.46; // 18-46-0, fracción de P₂O₅
  static const double _leyMop = 0.60; // 0-0-60, fracción de K₂O

  static ({double ley, String nombre}) _commercialFor(AgroMetricKey nutrient) =>
      switch (nutrient) {
        AgroMetricKey.n => (ley: _leyUrea, nombre: 'Urea (46-0-0)'),
        AgroMetricKey.p => (ley: _leyDap, nombre: 'DAP (18-46-0)'),
        AgroMetricKey.k => (ley: _leyMop, nombre: 'KCl (0-0-60)'),
        _ => (ley: 1.0, nombre: 'fertilizante'),
      };

  // ══════════════════════════════════════════════════════════════════════════
  // API
  // ══════════════════════════════════════════════════════════════════════════

  /// ¿Este cultivo tiene coeficientes cargados?
  static bool hasCoefficients(String? cropKey) =>
      coefficientsFor(cropKey) != null;

  /// Coeficientes del cultivo, o `null` si no está cubierto.
  ///
  /// Acepta los alias humanos además del id canónico, igual que el resto de
  /// los motores.
  static TreeExtractionCoefficients? coefficientsFor(String? cropKey) {
    final String crop = (cropKey ?? '').trim().toLowerCase();
    if (crop.isEmpty) return null;

    final String? canonical = switch (crop) {
      'apple_tree' ||
      'crop_apple_tree' ||
      'appletree' ||
      'apple' ||
      'manzano' ||
      'manzana' ||
      'manzanos' => 'apple_tree',
      'pear_tree' ||
      'crop_pear_tree' ||
      'peartree' ||
      'pear' ||
      'pera' ||
      'peral' ||
      'peras' ||
      'perales' => 'pear_tree',
      'peach_tree' ||
      'crop_peach_tree' ||
      'peachtree' ||
      'peach' ||
      'durazno' ||
      'duraznero' ||
      'melocoton' ||
      'melocotón' ||
      'melocotonero' => 'peach_tree',
      'walnut_tree' ||
      'crop_walnut_tree' ||
      'walnuttree' ||
      'walnut' ||
      'nogal' ||
      'nogal pecanero' ||
      'pecan' ||
      'nuez' ||
      'nuez pecana' => 'walnut_tree',
      'pistachio_tree' ||
      'crop_pistachio_tree' ||
      'pistachiotree' ||
      'pistachio' ||
      'pistache' ||
      'pistacho' ||
      'pistachero' => 'pistachio_tree',
      'orange_tree' ||
      'crop_orange_tree' ||
      'orangetree' ||
      'orange' ||
      'naranjo' ||
      'naranja' => 'orange_tree',
      'lemon_tree' ||
      'crop_lemon_tree' ||
      'lemontree' ||
      'lime_tree' ||
      'crop_lime_tree' ||
      'lemon' ||
      'lime' ||
      'limon' ||
      'limón' ||
      'limonero' ||
      'lima' => 'lemon_tree',
      'mango_tree' ||
      'crop_mango_tree' ||
      'mangotree' ||
      'crop_mango' ||
      'mango' ||
      'mangos' => 'mango_tree',
      'avocado_tree' ||
      'crop_avocado_tree' ||
      'avocadotree' ||
      'crop_avocado' ||
      'avocado' ||
      'aguacate' ||
      'aguacatero' ||
      'palta' ||
      'palto' => 'avocado_tree',
      _ => null,
    };

    return canonical == null ? null : _coefficients[canonical];
  }

  /// Calcula la dosis de un nutriente para **un árbol**, en gramos.
  ///
  /// Devuelve `null` —y esto es una decisión, no un descuido— cuando:
  ///   · el cultivo no tiene coeficientes cargados,
  ///   · no se conoce cuánta fruta va a dar el árbol,
  ///   · el suelo está muy alto y no toca aplicar nada,
  ///   · o el resultado es tan pequeño que fingir precisión sería engañoso.
  ///
  /// El Fundacional 2.1 §9.3 pide exactamente esto: no emitir una dosis
  /// cuando falta el contexto para interpretarla.
  static TreeRestitutionResult? compute({
    required AgroMetricKey nutrient,
    required String? cropKey,
    required double? kgFruitPerTree,
    required SoilSupplyLevel? soilLevel,
  }) {
    if (nutrient != AgroMetricKey.n &&
        nutrient != AgroMetricKey.p &&
        nutrient != AgroMetricKey.k) {
      return null;
    }
    if (soilLevel == null) return null;

    final TreeExtractionCoefficients? coef = coefficientsFor(cropKey);
    if (coef == null) return null;

    final double? kg = kgFruitPerTree;
    if (kg == null || kg <= 0 || !kg.isFinite) return null;

    final double factor = _soilFactors[soilLevel] ?? 0.0;
    if (factor <= 0) return null; // suelo muy alto: no se aporta

    // remoción → demanda → aporte → dosis
    final double removalG = kg * coef.forNutrient(nutrient);
    final double demandG = removalG / _fruitFraction(nutrient);
    final double supplyG = demandG * factor;
    final double doseG = supplyG / _efficiency(nutrient);

    if (!doseG.isFinite || doseG < 1.0) return null;

    final ({double ley, String nombre}) commercial = _commercialFor(nutrient);

    return TreeRestitutionResult(
      nutrient: nutrient,
      gramsPerTreeNutrient: doseG,
      gramsPerTreeCommercial: doseG / commercial.ley,
      commercialSourceEs: commercial.nombre,
      kgFruitPerTree: kg,
      coefficients: coef,
      soilLevel: soilLevel,
      soilFactor: factor,
    );
  }

  /// Redondeo para presentación: nadie pesa 137.4 g de urea por árbol.
  ///
  /// Bajo 100 g se redondea a 5, arriba a 10, y pasando el kilo a 50 — la
  /// precisión que se muestra no debe superar la que el número tiene.
  static int roundForDisplay(double grams) {
    if (grams < 100) return (grams / 5).round() * 5;
    if (grams < 1000) return (grams / 10).round() * 10;
    return (grams / 50).round() * 50;
  }
}
