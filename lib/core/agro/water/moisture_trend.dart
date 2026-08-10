// lib/core/agro/water/moisture_trend.dart
//
// Tendencia de humedad y tiempo estimado hasta nivel crítico.
//
// ═════════════════════════════════════════════════════════════════════════════
// POR QUÉ ESTO NO ES INVENTAR
// ═════════════════════════════════════════════════════════════════════════════
//
// Todo lo demás que muestra BIO-G sale de una lectura o de un catálogo. Esto
// es lo primero que **deriva** algo nuevo, así que tiene que ser especialmente
// honesto o no vale la pena tenerlo.
//
// La única afirmación que hace es: *"a este ritmo"*. No modela el suelo, no
// asume textura, no supone evapotranspiración. Ajusta una recta a las lecturas
// reales de las últimas horas y la extiende. Es exactamente lo que haría un
// productor mirando su historial, hecho con aritmética.
//
// Y se calla en cuanto la recta deja de describir los datos:
//
//   · menos de [_minSamples] lecturas ..................... sin tendencia
//   · menos de [_minSpan] de recorrido .................... sin tendencia
//   · pendiente casi plana ................................ "estable", sin proyección
//   · R² por debajo de [_minR2ForProjection] .............. tendencia sí, proyección no
//   · proyección más allá de [_maxProjection] ............. "más de una semana"
//
// El R² es la clave: si los puntos no caen cerca de la recta —porque llovió, se
// regó, o el sensor va a saltos— el ajuste no describe nada y proyectarlo sería
// exactamente el tipo de precisión falsa que esta app existe para evitar.

import 'package:flutter/foundation.dart';

import 'package:bio_g/models/biog_telemetry.dart';

enum MoistureTrendDirection {
  /// El suelo se está secando.
  drying,

  /// El suelo está ganando humedad: riego reciente o lluvia.
  wetting,

  /// Ni una cosa ni la otra dentro del ruido del sensor.
  stable,

  /// No hay lecturas suficientes para decir nada.
  unknown,
}

extension MoistureTrendDirectionX on MoistureTrendDirection {
  String get labelEs => switch (this) {
    MoistureTrendDirection.drying => 'Bajando',
    MoistureTrendDirection.wetting => 'Subiendo',
    MoistureTrendDirection.stable => 'Estable',
    MoistureTrendDirection.unknown => 'Sin tendencia',
  };

  bool get isKnown => this != MoistureTrendDirection.unknown;
}

@immutable
class MoistureTrend {
  const MoistureTrend({
    required this.direction,
    required this.slopePctPerHour,
    required this.samples,
    required this.span,
    required this.fit01,
    this.timeToCritical,
    this.criticalThresholdPct,
  });

  const MoistureTrend.unknown()
    : direction = MoistureTrendDirection.unknown,
      slopePctPerHour = 0,
      samples = 0,
      span = Duration.zero,
      fit01 = 0,
      timeToCritical = null,
      criticalThresholdPct = null;

  final MoistureTrendDirection direction;

  /// Puntos porcentuales por hora. Negativo = secándose.
  final double slopePctPerHour;

  /// Cuántas lecturas válidas entraron en el ajuste.
  final int samples;

  /// Ventana real que cubren esas lecturas.
  final Duration span;

  /// Coeficiente de determinación (R²) del ajuste, 0..1. Es la medida de si la
  /// recta describe de verdad los datos.
  final double fit01;

  /// Cuánto falta, al ritmo actual, para tocar el umbral crítico. Null cuando
  /// no procede proyectar.
  final Duration? timeToCritical;

  /// El umbral contra el que se proyectó, para poder explicarlo.
  final double? criticalThresholdPct;

  bool get hasProjection => timeToCritical != null;

  /// Cambio acumulado en la ventana observada.
  double get deltaPct => slopePctPerHour * span.inMinutes / 60.0;

  // ── Umbrales del método ────────────────────────────────────────────────

  static const int _minSamples = 4;
  static const Duration _minSpan = Duration(hours: 4);

  /// Por debajo de esto la pendiente se confunde con el ruido del sensor: la
  /// ficha declara ±2 % de exactitud en humedad.
  static const double _stableSlope = 0.08;

  /// Sin este ajuste mínimo hay tendencia (la dirección se ve) pero no
  /// proyección (el número mentiría).
  static const double _minR2ForProjection = 0.35;

  static const Duration _maxProjection = Duration(days: 7);

  /// Ventana de análisis. Más largo suaviza riegos y lluvias puntuales; más
  /// corto reacciona antes. 48 h es el compromiso: cubre un ciclo día-noche
  /// completo, que es donde la humedad tiene su oscilación natural.
  static const Duration analysisWindow = Duration(hours: 48);

  /// Calcula la tendencia sobre lecturas reales.
  ///
  /// [criticalThresholdPct] es el `lowMax` del objetivo de la etapa: el punto
  /// por debajo del cual el catálogo considera que hay estrés.
  static MoistureTrend from(
    List<BioGTelemetry> readings, {
    required DateTime now,
    double? criticalThresholdPct,
    Duration window = analysisWindow,
  }) {
    // Solo lecturas con dato real. La bandera manda: sin ella el valor es el
    // 0.0 sintetizado y metería una caída falsa en la recta.
    final DateTime from = now.subtract(window);
    final List<BioGTelemetry> valid =
        readings
            .where(
              (BioGTelemetry t) =>
                  t.hasSoilMoistureData &&
                  t.soilMoisturePct.isFinite &&
                  t.timestamp.isAfter(from) &&
                  !t.timestamp.isAfter(now),
            )
            .toList()
          ..sort(
            (BioGTelemetry a, BioGTelemetry b) =>
                a.timestamp.compareTo(b.timestamp),
          );

    if (valid.length < _minSamples) return const MoistureTrend.unknown();

    final DateTime t0 = valid.first.timestamp;
    final Duration span = valid.last.timestamp.difference(t0);
    if (span < _minSpan) return const MoistureTrend.unknown();

    // Mínimos cuadrados sobre (horas desde t0, humedad).
    final int n = valid.length;
    double sx = 0, sy = 0, sxy = 0, sxx = 0;
    for (final BioGTelemetry t in valid) {
      final double x = t.timestamp.difference(t0).inMinutes / 60.0;
      final double y = t.soilMoisturePct;
      sx += x;
      sy += y;
      sxy += x * y;
      sxx += x * x;
    }
    final double denom = (n * sxx) - (sx * sx);
    if (denom.abs() < 1e-9) return const MoistureTrend.unknown();

    final double slope = ((n * sxy) - (sx * sy)) / denom;
    final double intercept = (sy - slope * sx) / n;

    // R²: cuánto de la variación explica la recta.
    final double meanY = sy / n;
    double ssTot = 0, ssRes = 0;
    for (final BioGTelemetry t in valid) {
      final double x = t.timestamp.difference(t0).inMinutes / 60.0;
      final double y = t.soilMoisturePct;
      final double yHat = intercept + slope * x;
      ssTot += (y - meanY) * (y - meanY);
      ssRes += (y - yHat) * (y - yHat);
    }
    final double r2 = ssTot <= 1e-9 ? 0.0 : (1 - (ssRes / ssTot)).clamp(0.0, 1.0);

    final MoistureTrendDirection dir = slope.abs() < _stableSlope
        ? MoistureTrendDirection.stable
        : (slope < 0
              ? MoistureTrendDirection.drying
              : MoistureTrendDirection.wetting);

    // ── Proyección ───────────────────────────────────────────────────────
    Duration? toCritical;
    if (dir == MoistureTrendDirection.drying &&
        r2 >= _minR2ForProjection &&
        criticalThresholdPct != null) {
      final double current = valid.last.soilMoisturePct;
      final double gap = current - criticalThresholdPct;
      if (gap > 0) {
        final double hours = gap / slope.abs();
        if (hours.isFinite && hours > 0) {
          final Duration d = Duration(minutes: (hours * 60).round());
          toCritical = d > _maxProjection ? _maxProjection : d;
        }
      } else {
        // Ya está por debajo del umbral: no hay nada que proyectar.
        toCritical = Duration.zero;
      }
    }

    return MoistureTrend(
      direction: dir,
      slopePctPerHour: slope,
      samples: n,
      span: span,
      fit01: r2,
      timeToCritical: toCritical,
      criticalThresholdPct: criticalThresholdPct,
    );
  }

  /// "en 2 días", "en 14 h", "ya está por debajo".
  String? projectionLabelEs() {
    final Duration? d = timeToCritical;
    if (d == null) return null;
    if (d == Duration.zero) return 'ya está por debajo';
    if (d >= _maxProjection) return 'en más de una semana';
    if (d.inHours < 1) return 'en menos de 1 h';
    if (d.inHours < 36) return 'en ${d.inHours} h';
    return 'en ${(d.inHours / 24).round()} días';
  }

  /// "0.4 % por hora". Se redondea a una decimal porque el sensor declara
  /// ±2 % de exactitud: más cifras serían precisión inventada.
  String rateLabelEs() =>
      '${slopePctPerHour.abs().toStringAsFixed(1)} % por hora';
}
