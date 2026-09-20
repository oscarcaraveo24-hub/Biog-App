// lib/core/agro/nutrition/fertilizer_products.dart
//
// EQUIVALENTE COMERCIAL DE UNA DOSIS (Guía v0.4, §9 «3R» y §10).
//
// La guía habla en N, P₂O₅ y K₂O; el agricultor compra sacos. Aquí vive la
// única tabla de riquezas de los productos que las guías respaldan, para
// traducir «107–161 kg/ha de N» en «≈ 235–350 kg/ha de urea». Es aritmética
// de etiqueta, no agronomía: nunca ajusta la dosis, solo la expresa.
//
// LO QUE SÍ RESUELVE: los tres nutrientes JUNTOS. El MAP lleva 11 % de N, el
// DAP 18 % y el nitrato de potasio 13 %; ese nitrógeno entra al suelo en la
// misma aplicación. Si no se descuenta del nitrogenado, la recomendación se
// pasa —en la siembra de frijol el DAP que cubre el fósforo ya aporta 16–23
// kg N/ha sobre una ventana de 18–36—. La dosis de la guía no cambia; cambia
// cuántos sacos de urea hay que comprar.
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';

/// Un producto comercial con su riqueza por forma de nutriente (fracción 0..1).
class FertilizerProduct {
  const FertilizerProduct({
    required this.matchEs,
    required this.shortNameEs,
    this.n = 0,
    this.p2o5 = 0,
    this.k2o = 0,
  });

  /// Texto (en minúsculas) que identifica al producto dentro de la opción de
  /// fuente de la guía («Urea (46-0-0)» → «urea»).
  final String matchEs;

  /// Nombre corto para el copy («urea», «MAP», «sulfato de potasio»).
  final String shortNameEs;

  final double n;
  final double p2o5;
  final double k2o;

  double fractionFor(NutrientForm form) => switch (form) {
    NutrientForm.n => n,
    NutrientForm.p2o5 => p2o5,
    NutrientForm.k2o => k2o,
  };
}

/// Una dosis ya resuelta que el productor va a comprar como producto.
///
/// Existe para poder razonar sobre TODA la aplicación a la vez —N, P₂O₅ y K₂O
/// juntos— en vez de traducir cada nutriente por su lado.
class FertilizerRequirement {
  const FertilizerRequirement({
    required this.form,
    required this.minKg,
    required this.maxKg,
    this.sourceOptionsEs = const <String>[],
  });

  final NutrientForm form;
  final double minKg;
  final double maxKg;

  /// Fuentes que la guía respalda para este nutriente, en orden de preferencia.
  final List<String> sourceOptionsEs;
}

/// Nitrógeno que llega con los productos de fósforo y de potasio.
///
/// No es un regalo ni un detalle contable: entra al suelo con la misma
/// aplicación y la planta lo toma igual. Cuenta.
class CarriedNitrogen {
  const CarriedNitrogen({
    required this.minKg,
    required this.maxKg,
    required this.sourcesEs,
  });

  static const CarriedNitrogen none = CarriedNitrogen(
    minKg: 0,
    maxKg: 0,
    sourcesEs: <String>[],
  );

  final double minKg;
  final double maxKg;

  /// Nombres cortos de los productos que lo aportan («DAP», «MAP», «nitrato
  /// de potasio»), en el orden en que se resolvieron.
  final List<String> sourcesEs;

  bool get isEmpty => maxKg <= 0 || sourcesEs.isEmpty;
}

class FertilizerProducts {
  const FertilizerProducts._();

  /// Riquezas típicas de etiqueta (México). Con orden de preferencia: los
  /// primeros son los más comunes en las guías.
  static const List<FertilizerProduct> catalog = <FertilizerProduct>[
    FertilizerProduct(matchEs: 'urea', shortNameEs: 'urea', n: 0.46),
    FertilizerProduct(
      matchEs: 'sulfato de amonio',
      shortNameEs: 'sulfato de amonio',
      n: 0.21,
    ),
    FertilizerProduct(
      matchEs: 'nitrato de amonio',
      shortNameEs: 'nitrato de amonio',
      n: 0.335,
    ),
    FertilizerProduct(
      matchEs: 'nitrato de calcio',
      shortNameEs: 'nitrato de calcio',
      n: 0.155,
    ),
    FertilizerProduct(matchEs: 'uan', shortNameEs: 'UAN 32', n: 0.32),
    FertilizerProduct(
      matchEs: 'amoniaco anhidro',
      shortNameEs: 'amoniaco anhidro',
      n: 0.82,
    ),
    FertilizerProduct(matchEs: 'map', shortNameEs: 'MAP', n: 0.11, p2o5: 0.52),
    FertilizerProduct(matchEs: 'dap', shortNameEs: 'DAP', n: 0.18, p2o5: 0.46),
    FertilizerProduct(
      matchEs: 'superfosfato triple',
      shortNameEs: 'superfosfato triple',
      p2o5: 0.46,
    ),
    FertilizerProduct(
      matchEs: 'ácido fosfórico',
      shortNameEs: 'ácido fosfórico (85 %)',
      p2o5: 0.61,
    ),
    FertilizerProduct(
      matchEs: 'cloruro de potasio',
      shortNameEs: 'cloruro de potasio',
      k2o: 0.60,
    ),
    FertilizerProduct(
      matchEs: 'sulfato de potasio',
      shortNameEs: 'sulfato de potasio',
      k2o: 0.50,
    ),
    FertilizerProduct(
      matchEs: 'nitrato de potasio',
      shortNameEs: 'nitrato de potasio',
      n: 0.13,
      k2o: 0.46,
    ),
  ];

  /// Producto que corresponde a una opción de fuente de la guía, o null.
  static FertilizerProduct? match(String sourceOptionEs) {
    final String key = sourceOptionEs.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final FertilizerProduct p in catalog) {
      if (key.contains(p.matchEs)) return p;
    }
    return null;
  }

  /// Primer producto de [sourceOptionsEs] que aporta [form]; si ninguno,
  /// el producto por defecto de esa forma (urea / MAP / cloruro de potasio).
  static FertilizerProduct? pickFor(
    NutrientForm form,
    List<String> sourceOptionsEs,
  ) {
    for (final String option in sourceOptionsEs) {
      final FertilizerProduct? p = match(option);
      if (p != null && p.fractionFor(form) > 0) return p;
    }
    for (final FertilizerProduct p in catalog) {
      if (p.fractionFor(form) > 0) return p;
    }
    return null;
  }

  /// «≈ 235–350 kg/ha de urea»; con mínimo 0, «≈ hasta 100 kg/ha de cloruro
  /// de potasio». En kg/ha redondea a múltiplos de 5; en otras unidades
  /// (g/m², g por planta) al entero.
  static String? equivalentEs({
    required NutrientForm form,
    required double minKg,
    required double maxKg,
    required List<String> sourceOptionsEs,
    String unitEs = 'kg/ha',
  }) {
    final FertilizerProduct? p = pickFor(form, sourceOptionsEs);
    if (p == null) return null;
    final double f = p.fractionFor(form);
    if (f <= 0 || maxKg <= 0) return null;
    final int step = unitEs == 'kg/ha' ? 5 : 1;
    final int lo = _roundTo(minKg / f, step);
    final int hi = _roundTo(maxKg / f, step);
    if (minKg <= 0) return '≈ hasta $hi $unitEs de ${p.shortNameEs}';
    final String range = lo == hi ? '$lo' : '$lo–$hi';
    return '≈ $range $unitEs de ${p.shortNameEs}';
  }

  static int _roundTo(double v, int step) =>
      ((v / step).round() * step).clamp(0, 1 << 30);

  // ═══════════════════════════════════════════════════════════════════════
  // NITRÓGENO DE ACOMPAÑAMIENTO
  // ═══════════════════════════════════════════════════════════════════════

  /// Por debajo de esta fracción de la ventana, el N que traen el fosfatado y
  /// el potásico es ruido contable: no cambia lo que el agricultor compra y
  /// explicarlo solo estorba.
  static const double _carriedNitrogenFloor = 0.10;

  /// Nitrógeno que arrastran los productos elegidos para P₂O₅ y K₂O.
  ///
  /// Recorre los requerimientos que NO son de nitrógeno, resuelve con qué
  /// producto se cubre cada uno y suma el N de su etiqueta. Los rangos se
  /// emparejan por escenario: el mínimo con el mínimo y el máximo con el
  /// máximo, porque así están construidos los planes de las guías.
  static CarriedNitrogen nitrogenCarriedBy(
    Iterable<FertilizerRequirement> requirements,
  ) {
    double min = 0;
    double max = 0;
    final List<String> sources = <String>[];
    for (final FertilizerRequirement r in requirements) {
      if (r.form == NutrientForm.n || r.maxKg <= 0) continue;
      final FertilizerProduct? p = pickFor(r.form, r.sourceOptionsEs);
      if (p == null || p.n <= 0) continue;
      final double richness = p.fractionFor(r.form);
      if (richness <= 0) continue;
      min += (r.minKg / richness) * p.n;
      max += (r.maxKg / richness) * p.n;
      if (!sources.contains(p.shortNameEs)) sources.add(p.shortNameEs);
    }
    if (max <= 0) return CarriedNitrogen.none;
    return CarriedNitrogen(minKg: min, maxKg: max, sourcesEs: sources);
  }

  /// ¿Vale la pena descontarlo y decírselo al agricultor?
  static bool shouldNetNitrogen(
    CarriedNitrogen carried,
    double nitrogenMaxKg,
  ) =>
      !carried.isEmpty &&
      nitrogenMaxKg > 0 &&
      carried.maxKg >= nitrogenMaxKg * _carriedNitrogenFloor;

  /// Equivalente del producto nitrogenado YA DESCONTADO el N que traen el
  /// fosfatado y el potásico. Null cuando esos productos ya cubren la ventana
  /// y no hace falta nitrogenado aparte.
  static String? nitrogenEquivalentEs({
    required double minKg,
    required double maxKg,
    required List<String> sourceOptionsEs,
    required CarriedNitrogen carried,
    String unitEs = 'kg/ha',
  }) {
    final double netMin = minKg - carried.minKg;
    final double netMax = maxKg - carried.maxKg;
    if (netMax <= 0) return null;
    return equivalentEs(
      form: NutrientForm.n,
      minKg: netMin < 0 ? 0 : netMin,
      maxKg: netMax,
      sourceOptionsEs: sourceOptionsEs,
      unitEs: unitEs,
    );
  }

  /// Por qué el nitrogenado baja —o desaparece— en esta aplicación.
  ///
  /// Sin esta frase el agricultor ve una cifra de urea más baja de lo que
  /// esperaba y no sabe si es un error.
  static String? carriedNitrogenNoteEs({
    required CarriedNitrogen carried,
    required double nitrogenMaxKg,
    required List<String> nitrogenSourceOptionsEs,
    String unitEs = 'kg/ha',
  }) {
    if (carried.isEmpty) return null;
    final String who = _joinSourcesEs(carried.sourcesEs);
    final String amount =
        '${_fmtAmount(carried.minKg)}–${_fmtAmount(carried.maxKg)} $unitEs';
    if (nitrogenMaxKg - carried.maxKg <= 0) {
      return '$who de esta aplicación ya aporta $amount de nitrógeno y cubre '
          'la ventana: no apliques nitrogenado aparte.';
    }
    final FertilizerProduct? n = pickFor(
      NutrientForm.n,
      nitrogenSourceOptionsEs,
    );
    final String name = n?.shortNameEs ?? 'fertilizante nitrogenado';
    return '$who de esta aplicación ya aporta $amount de nitrógeno; la cifra '
        'de $name de arriba ya lo tiene descontado.';
  }

  /// «El DAP», «El MAP y el nitrato de potasio».
  static String _joinSourcesEs(List<String> names) {
    if (names.length == 1) return 'El ${names.first}';
    final String head = names.sublist(0, names.length - 1).join(', el ');
    return 'El $head y el ${names.last}';
  }

  /// Misma precisión que `NutritionDoseRange`: no mostrar más dígitos de los
  /// que el número realmente tiene.
  static String _fmtAmount(double v) {
    if (v >= 100) return v.round().toString();
    if (v >= 10) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}
