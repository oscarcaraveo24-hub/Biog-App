// lib/core/agro/nutrition/fertilizer_products.dart
//
// EQUIVALENTE COMERCIAL DE UNA DOSIS (Guía v0.4, §9 «3R» y §10).
//
// La guía habla en N, P₂O₅ y K₂O; el agricultor compra sacos. Aquí vive la
// única tabla de riquezas de los productos que las guías respaldan, para
// traducir «107–161 kg/ha de N» en «≈ 235–350 kg/ha de urea». Es aritmética
// de etiqueta, no agronomía: nunca ajusta la dosis, solo la expresa.
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
}
