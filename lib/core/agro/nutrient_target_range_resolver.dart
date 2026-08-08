import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/soil_reaction.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';

/// Resuelve el rango comparable de suficiencia para N/P/K en mg/kg.
///
/// Compatibilidad:
/// - Si el cultivo ya define un target explicito de suelo, se usa ese rango.
/// - Si todavia solo existe el rango legacy 0..100, se traduce con el cap del
///   cultivo para no romper pantallas ni motores compartidos.
class NutrientTargetRangeResolver {
  const NutrientTargetRangeResolver._();

  /// Rango comparable de suficiencia, ajustado por la reacción del suelo.
  ///
  /// El parámetro [soilReaction] es opcional y por omisión no ajusta nada, así
  /// que los catorce llamadores que ya existían siguen comportándose igual.
  /// Cuando llega `calcareous`, la banda de **fósforo** se desplaza hacia
  /// arriba: en suelo calcáreo el calcio fija el fósforo y hace falta más en
  /// el análisis para tener el mismo disponible. Ver `soil_reaction.dart`.
  ///
  /// Este es el único punto donde se aplica el ajuste, a propósito: así la
  /// banda que se muestra en pantalla y la dosis que se calcula salen del
  /// mismo número y no pueden contradecirse.
  static AgroRange? comparableRange({
    required AgroMetricKey nutrient,
    required String? cropKey,
    required StageTargets? targets,
    SoilReaction soilReaction = SoilReaction.unknown,
  }) {
    final AgroRange? explicit = targets?.soilPpmRangeFor(nutrient);
    if (explicit != null) {
      return adjustRangeForSoilReaction(
        range: explicit,
        nutrient: nutrient,
        reaction: soilReaction,
      );
    }

    final AgroRange? legacy = _legacyRangeFor(nutrient: nutrient, targets: targets);
    if (legacy == null) return null;

    final double cap = NpkCaps.forCropMetric(cropKey: cropKey, metricKey: nutrient);
    if (cap <= 0) return null;

    return adjustRangeForSoilReaction(
      range: AgroRange(
        lowMax: _legacyIndexToPpm(legacy.lowMax, cap),
        optimalMin: _legacyIndexToPpm(legacy.optimalMin, cap),
        optimalMax: _legacyIndexToPpm(legacy.optimalMax, cap),
        highMin: _legacyIndexToPpm(legacy.highMin, cap),
      ),
      nutrient: nutrient,
      reaction: soilReaction,
    );
  }

  static double? targetMidPpm({
    required AgroMetricKey nutrient,
    required String? cropKey,
    required StageTargets? targets,
    SoilReaction soilReaction = SoilReaction.unknown,
  }) {
    final AgroRange? range = comparableRange(
      nutrient: nutrient,
      cropKey: cropKey,
      targets: targets,
      soilReaction: soilReaction,
    );
    if (range == null) return null;
    return (range.optimalMin + range.optimalMax) / 2.0;
  }

  static bool usesExplicitSoilRange({
    required AgroMetricKey nutrient,
    required StageTargets? targets,
  }) {
    return targets?.soilPpmRangeFor(nutrient) != null;
  }

  static AgroRange? _legacyRangeFor({
    required AgroMetricKey nutrient,
    required StageTargets? targets,
  }) {
    if (targets == null) return null;

    switch (nutrient) {
      case AgroMetricKey.n:
        return targets.nIndex;
      case AgroMetricKey.p:
        return targets.pIndex;
      case AgroMetricKey.k:
        return targets.kIndex;
      default:
        return null;
    }
  }

  static double _legacyIndexToPpm(double index0to100, double cap) {
    return (index0to100.clamp(0.0, 100.0) / 100.0) * cap;
  }
}
