// lib/core/agro/nutrition/site_learning.dart
//
// MEMORIA DEL SITIO: época de instalación, aprendizaje inicial y estadística
// robusta para líneas base (Guía oficial del nuevo motor nutricional v0.4,
// §21, §22 y §31).
//
// Dos fenómenos distintos que antes se confundían:
//   · La estabilización electrónica de la sonda dura segundos o minutos y la
//     resuelve el firmware (warm-up de banco, §25). Aquí no aparece.
//   · El aprendizaje del SITIO dura días: variabilidad local, ciclos de riego,
//     patrones. Es lo que este archivo modela.
//
// BIO-G funciona desde el día 1. Lo que se limita durante LEARNING son las
// comparaciones históricas fuertes, no las funciones básicas (§21).
import 'dart:math' as math;

/// Época de instalación: desde cuándo la sonda observa ESTE punto.
///
/// Mover la sonda cambia el sitio observado y exige un baseline nuevo (§22).
/// El productor lo resuelve con una acción simple —«Reubicar BIO-G»— que cierra
/// la época anterior y abre una nueva. El historial viejo se conserva; la
/// nueva ubicación no se compara como si fuera el mismo punto.
class InstallationEpoch {
  const InstallationEpoch({
    required this.deviceId,
    required this.startedAt,
    this.epochId,
    this.reasonEs,
  });

  final String deviceId;
  final DateTime startedAt;

  /// Identificador estable de la época (para etiquetar lecturas y baselines).
  final String? epochId;

  /// «Instalación inicial», «Reubicación», etc.
  final String? reasonEs;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'deviceId': deviceId,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'epochId': epochId,
    'reasonEs': reasonEs,
  };

  static InstallationEpoch? tryFromJson(Map<String, dynamic> json) {
    final String? deviceId = json['deviceId']?.toString();
    final DateTime? startedAt = DateTime.tryParse(
      json['startedAt']?.toString() ?? '',
    )?.toLocal();
    if (deviceId == null || startedAt == null) return null;
    return InstallationEpoch(
      deviceId: deviceId,
      startedAt: startedAt,
      epochId: json['epochId']?.toString(),
      reasonEs: json['reasonEs']?.toString(),
    );
  }
}

/// Estado del aprendizaje inicial del sitio.
class SiteLearningStatus {
  const SiteLearningStatus({
    required this.isLearning,
    required this.daysSinceStart,
    required this.daysLeft,
    required this.startedAt,
  });

  /// Días que dura el aprendizaje inicial (Guía v0.4, §21: «alrededor de una
  /// semana»). Pasado este plazo el baseline inicial se considera maduro si
  /// además existe suficiente evidencia válida.
  static const int learningDays = 7;

  final bool isLearning;
  final int daysSinceStart;
  final int daysLeft;
  final DateTime? startedAt;

  static const SiteLearningStatus unknown = SiteLearningStatus(
    isLearning: false,
    daysSinceStart: 0,
    daysLeft: 0,
    startedAt: null,
  );

  /// Copy sugerido por la Guía (§21).
  static const String learningCopyEs =
      'BIO-G está aprendiendo esta zona. Puedes usar normalmente el '
      'dispositivo; las comparaciones con el historial se volverán más precisas '
      'durante los próximos días.';

  static SiteLearningStatus resolve({
    required DateTime? startedAt,
    required DateTime now,
  }) {
    if (startedAt == null) return unknown;
    // Un inicio en el futuro (reloj adelantado, lectura mal fechada) cuenta
    // como día 0: nunca «faltan» más días que el aprendizaje completo.
    final int days = math.max(0, now.difference(startedAt).inDays);
    final int left = math.max(0, learningDays - days);
    return SiteLearningStatus(
      isLearning: days < learningDays,
      daysSinceStart: days,
      daysLeft: left,
      startedAt: startedAt,
    );
  }
}

/// Estadística robusta para líneas base: mediana y MAD (Guía v0.4, §31
/// «Estadística robusta: mediana y MAD como base inicial»).
///
/// Se usa mediana/MAD y no media/desviación porque un fertirriego o una lluvia
/// fuerte son escalones reales que arruinarían una media, y porque el baseline
/// debe describir el sitio «en reposo», no sus eventos.
class RobustStats {
  const RobustStats({
    required this.median,
    required this.mad,
    required this.count,
  });

  final double median;

  /// Desviación absoluta mediana, escalada por 1.4826 para ser comparable con
  /// una desviación estándar bajo normalidad.
  final double mad;

  final int count;

  /// Mínimo de lecturas para que un baseline se considere utilizable.
  static const int minCount = 6;

  bool get isUsable => count >= minCount && mad.isFinite;

  /// Cuántas MAD se aleja [value] de la mediana. Con MAD nula se usa un piso
  /// relativo para no dividir entre cero ni declarar «infinito» por una serie
  /// perfectamente plana.
  double z(double value) {
    final double floor = math.max(mad, (median.abs() * 0.02).clamp(1e-6, double.infinity));
    return (value - median) / floor;
  }

  static RobustStats? fromValues(Iterable<double> raw) {
    final List<double> values = raw.where((double v) => v.isFinite).toList()
      ..sort();
    if (values.isEmpty) return null;
    final double med = _median(values);
    final List<double> dev = values.map((double v) => (v - med).abs()).toList()
      ..sort();
    final double mad = _median(dev) * 1.4826;
    return RobustStats(median: med, mad: mad, count: values.length);
  }

  static double _median(List<double> sorted) {
    final int n = sorted.length;
    if (n.isOdd) return sorted[n ~/ 2];
    return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2.0;
  }
}
