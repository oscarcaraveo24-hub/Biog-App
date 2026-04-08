import 'dart:math' as math;

class PlantHealthConfidence {
  PlantHealthConfidence._();

  static double clamp01(double value) {
    if (value.isNaN) return 0;
    if (value <= 0) return 0;
    if (value >= 1) return 1;
    return value;
  }

  static double normalizeScore(int score) {
    if (score <= 0) return 0;
    if (score >= 100) return 1;
    return score / 100.0;
  }

  static List<double> softmax(List<double> logits, {double temperature = 1.0}) {
    if (logits.isEmpty) return const <double>[];
    final double safeTemperature = math.max(temperature, 0.05);
    final List<double> scaled = logits
        .map((double value) => value / safeTemperature)
        .toList(growable: false);
    final double maxLogit = scaled.reduce(math.max);
    final List<double> exps = scaled
        .map((double value) => math.exp(value - maxLogit))
        .toList(growable: false);
    final double sum = exps.fold<double>(0, (double a, double b) => a + b);
    if (sum <= 0) {
      return List<double>.filled(logits.length, 1 / logits.length);
    }
    return exps.map((double value) => value / sum).toList(growable: false);
  }

  static List<double> blendWithUniform(
    List<double> probabilities, {
    required double weight,
  }) {
    if (probabilities.isEmpty) return const <double>[];
    final int count = probabilities.length;
    final double clampedWeight = clamp01(weight);
    final double uniform = 1 / count;
    return probabilities
        .map(
          (double value) =>
              (uniform * (1 - clampedWeight)) + (value * clampedWeight),
        )
        .toList(growable: false);
  }

  static List<double> enforceTopCap(
    List<double> probabilities, {
    required double cap,
  }) {
    if (probabilities.length <= 1) return probabilities;
    final double safeCap = clamp01(cap);
    if (safeCap <= 0) return probabilities;

    int topIndex = 0;
    double topValue = probabilities.first;
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > topValue) {
        topValue = probabilities[i];
        topIndex = i;
      }
    }

    if (topValue <= safeCap) return probabilities;

    final List<double> adjusted = List<double>.from(probabilities);
    adjusted[topIndex] = safeCap;

    final double otherSum = probabilities
        .asMap()
        .entries
        .where((MapEntry<int, double> entry) => entry.key != topIndex)
        .fold<double>(
          0,
          (double sum, MapEntry<int, double> entry) => sum + entry.value,
        );

    final double remaining = 1 - safeCap;
    if (otherSum <= 0 || remaining <= 0) {
      for (int i = 0; i < adjusted.length; i++) {
        adjusted[i] = i == topIndex ? safeCap : 0;
      }
      return adjusted;
    }

    for (int i = 0; i < adjusted.length; i++) {
      if (i == topIndex) continue;
      adjusted[i] = (probabilities[i] / otherSum) * remaining;
    }
    return adjusted;
  }

  static String labelEs(double value) {
    if (value >= 0.75) return 'Alta';
    if (value >= 0.45) return 'Media';
    return 'Baja';
  }

  static String hintEs(double value) {
    if (value >= 0.75) {
      return 'Coincidencia fuerte con etapa, órgano y señales clave.';
    }
    if (value >= 0.45) {
      return 'Coincidencia parcial; conviene revisar confirmadores antes de actuar.';
    }
    return 'Diferencial abierto; usar como orientación inicial, no como cierre.';
  }
}
