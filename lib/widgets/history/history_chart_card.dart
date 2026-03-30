import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

class HistoryChartCard extends StatelessWidget {
  const HistoryChartCard({
    super.key,
    this.title,
    this.values = const [52, 54, 51, 48, 44, 40, 65],
    this.days = const ['L', 'M', 'M', 'J', 'V', 'S', 'D'],

    /// presente fijo (NO depende del rango)
    this.currentValue = 24.0,

    /// formateo por métrica
    this.valueFormatter,

    /// si el eje es % (0..100)
    this.isPercentScale = true,

    /// radio zoom (lo mandas por métrica)
    this.zoomRadius = 25,

    /// mínimo span para que no quede plana (pH: 6 => ±3)
    this.minSpan = 0,

    /// bandas por métrica (stops en unidades reales: % / pH / °C / RT)
    this.bandStops,

    /// colores explícitos para las bandas (derivados del cultivo)
    this.bandColors,

    this.forceFullRangeIfSpanOver = 40,
    this.roundZoomTo5 = true,
  });

  final String? title;
  final List<double> values;
  final List<String> days;

  final double currentValue;

  final String Function(double)? valueFormatter;
  final bool isPercentScale;

  final double zoomRadius;
  final double minSpan;
  final List<double>? bandStops;
  final List<Color>? bandColors;

  final double forceFullRangeIfSpanOver;
  final bool roundZoomTo5;

  @override
  Widget build(BuildContext context) {
    final fmt =
        valueFormatter ??
        ((v) => isPercentScale ? '${v.round()}%' : v.toStringAsFixed(1));

    return BioGGlassCard(
      radius: 18,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? 'Humedad (últimos 7 días)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final size = Size(c.maxWidth, 210);

              final double effectiveCurrent = currentValue.toDouble();

              final List<double> drawValues = _valuesWithLastAsCurrent(
                values,
                effectiveCurrent,
              );

              final yRange = _resolveZoomRange(
                values: drawValues,
                current: effectiveCurrent,
                radius: zoomRadius,
                minSpan: minSpan,
                fullIfSpanOver: forceFullRangeIfSpanOver,
                roundTo5: roundZoomTo5,
                isPercentScale: isPercentScale,
              );

              final geom = _ChartGeometry(
                size: size,
                values: drawValues,
                yMin: yRange.start,
                yMax: yRange.end,
              );

              final last = geom.basePoints.isNotEmpty
                  ? geom.basePoints.last
                  : Offset.zero;

              final double bubbleLeft = (last.dx + 14)
                  .clamp(8.0, size.width - 120)
                  .toDouble();
              final double bubbleTop = (last.dy - 18)
                  .clamp(8.0, size.height - 60)
                  .toDouble();

              final bubbleText = fmt(effectiveCurrent);

              return Stack(
                children: [
                  SizedBox(
                    height: size.height,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _HistoryChartPainter(
                        labels: days,
                        geom: geom,
                        yRange: yRange,
                        valueFormatter: valueFormatter,
                        isPercentScale: isPercentScale,
                        bandStops: bandStops,
                        bandColors: bandColors,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  if (geom.basePoints.isNotEmpty)
                    Positioned(
                      left: bubbleLeft,
                      top: bubbleTop,
                      child: _BubbleEntrance(
                        key: ValueKey(bubbleText),
                        child: _LiquidPillBubble(
                          value: bubbleText,
                          showPointer: true,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          const Text(
            'Valor actual',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            fmt(currentValue.toDouble()),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  static List<double> _valuesWithLastAsCurrent(
    List<double> src,
    double current,
  ) {
    if (src.length < 2) return src;
    final out = List<double>.from(src);
    out[out.length - 1] = current;
    return out;
  }

  RangeValues _resolveZoomRange({
    required List<double> values,
    required double current,
    required double radius,
    required double minSpan,
    required double fullIfSpanOver,
    required bool roundTo5,
    required bool isPercentScale,
  }) {
    final clampMin = isPercentScale ? 0.0 : -double.infinity;
    final clampMax = isPercentScale ? 100.0 : double.infinity;

    double half = radius;
    if (minSpan > 0) {
      final need = minSpan / 2.0;
      if (half < need) half = need;
    }

    double lo = current - half;
    double hi = current + half;

    if (values.isNotEmpty) {
      final minV = values.reduce((a, b) => a < b ? a : b);
      final maxV = values.reduce((a, b) => a > b ? a : b);
      final span = (maxV - minV).abs();

      if (isPercentScale && span >= fullIfSpanOver) {
        lo = 0;
        hi = 100;
      } else {
        if (minV < lo) {
          final shift = lo - minV;
          lo -= shift;
          hi -= shift;
        }
        if (maxV > hi) {
          final shift = maxV - hi;
          lo += shift;
          hi += shift;
        }

        if (minSpan > 0 && (hi - lo) < minSpan) {
          final mid = (hi + lo) / 2;
          lo = mid - minSpan / 2;
          hi = mid + minSpan / 2;
        }
      }
    }

    if (isPercentScale) {
      lo = lo.clamp(0.0, 100.0);
      hi = hi.clamp(0.0, 100.0);

      if (roundTo5) {
        lo = _roundDownTo(lo, 5).clamp(0.0, 100.0).toDouble();
        hi = _roundUpTo(hi, 5).clamp(0.0, 100.0).toDouble();
        if (hi <= lo) return const RangeValues(0, 100);
      }
    } else {
      lo = lo.clamp(clampMin, clampMax).toDouble();
      hi = hi.clamp(clampMin, clampMax).toDouble();
      if ((hi - lo).abs() < 0.0001) {
        hi = lo + 1.0;
      }
    }

    return RangeValues(lo, hi);
  }

  static double _roundDownTo(double v, double step) =>
      (v / step).floorToDouble() * step;

  static double _roundUpTo(double v, double step) =>
      (v / step).ceilToDouble() * step;
}

class _BubbleEntrance extends StatelessWidget {
  const _BubbleEntrance({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final opacity = (t * 1.0).clamp(0.0, 1.0);
        final dy = (1.0 - t) * 10.0;
        final scale = 0.98 + (0.02 * t);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _LiquidPillBubble extends StatelessWidget {
  const _LiquidPillBubble({required this.value, this.showPointer = true});

  final String value;
  final bool showPointer;

  @override
  Widget build(BuildContext context) {
    const tint = Color(0xFF5BC8A4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha:0.95),
                    tint.withValues(alpha:0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha:0.55)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0E1412),
                    ),
                  ),
                  if (showPointer) ...[
                    const SizedBox(width: 6),
                    const _ChevronPointer(color: Color.fromARGB(255, 0, 0, 0)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChevronPointer extends StatelessWidget {
  const _ChevronPointer({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(10, 10),
      painter: _ChevronPainter(color),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha:0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(2, 2)
      ..lineTo(size.width - 2, size.height / 2)
      ..lineTo(2, size.height - 2);

    final glow = Paint()
      ..color = Colors.white.withValues(alpha:0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) => false;
}

class _ChartGeometry {
  final Size size;
  final Rect plot;
  final List<Offset> basePoints;
  final List<Offset> smoothPoints;
  final double yMin;
  final double yMax;

  _ChartGeometry({
    required this.size,
    required List<double> values,
    required this.yMin,
    required this.yMax,
  }) : plot = _plotRect(size),
       basePoints = values.length >= 2
           ? _toPoints(_plotRect(size), values, yMin, yMax)
           : const <Offset>[],
       smoothPoints = values.length >= 2
           ? _sampleSmooth(
               _toPoints(_plotRect(size), values, yMin, yMax),
               samplesPerSegment: 40,
             )
           : const <Offset>[];

  static Rect _plotRect(Size size) {
    const leftPad = 42.0;
    const rightPad = 14.0;
    const topPad = 18.0;
    const bottomPad = 34.0;
    return Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad,
    );
  }

  static List<Offset> _toPoints(
    Rect plot,
    List<double> values,
    double yMin,
    double yMax,
  ) {
    final dx = plot.width / (values.length - 1);
    final span = (yMax - yMin).abs().clamp(0.0001, 99999999.0);

    return List.generate(values.length, (i) {
      final v = values[i];
      final t = ((v - yMin) / span).clamp(0.0, 1.0);
      final y = plot.bottom - (t * plot.height);
      final x = plot.left + dx * i;
      return Offset(x, y);
    });
  }

  static List<Offset> _sampleSmooth(
    List<Offset> pts, {
    int samplesPerSegment = 24,
  }) {
    if (pts.length < 2) return pts;

    Offset get(int i) {
      if (i < 0) return pts.first;
      if (i >= pts.length) return pts.last;
      return pts[i];
    }

    final out = <Offset>[];
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = get(i - 1);
      final p1 = get(i);
      final p2 = get(i + 1);
      final p3 = get(i + 2);

      for (int s = 0; s < samplesPerSegment; s++) {
        final t = s / samplesPerSegment;
        out.add(_catmullRom(p0, p1, p2, p3, t));
      }
    }
    out.add(pts.last);
    return out;
  }

  static Offset _catmullRom(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;

    final x =
        0.5 *
        ((2 * p1.dx) +
            (-p0.dx + p2.dx) * t +
            (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
            (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);

    final y =
        0.5 *
        ((2 * p1.dy) +
            (-p0.dy + p2.dy) * t +
            (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
            (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

    return Offset(x, y);
  }
}

class _HistoryChartPainter extends CustomPainter {
  static const _greenLine = Color(0xFF3E9F86);

  final List<String> labels;
  final _ChartGeometry geom;
  final RangeValues yRange;

  final String Function(double)? valueFormatter;
  final bool isPercentScale;
  final List<double>? bandStops;
  final List<Color>? bandColors;

  const _HistoryChartPainter({
    required this.labels,
    required this.geom,
    required this.yRange,
    required this.valueFormatter,
    required this.isPercentScale,
    required this.bandStops,
    this.bandColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha:0.0), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    _drawBands(canvas, geom.plot);
    _drawGrid(canvas, geom.plot);

    if (geom.smoothPoints.isNotEmpty) {
      final smoothPts = geom.smoothPoints;

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha:0.06)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final linePaint = Paint()
        ..color = _greenLine.withValues(alpha:0.92)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(smoothPts.first.dx, smoothPts.first.dy);
      for (final p in smoothPts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }

      canvas.save();
      canvas.translate(0, 1);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();

      canvas.drawPath(path, linePaint);

      final micro = Paint()..color = _greenLine.withValues(alpha:0.16);
      for (int i = 0; i < smoothPts.length; i++) {
        canvas.drawCircle(smoothPts[i], 1.8, micro);
      }
    }

    if (geom.basePoints.isNotEmpty) {
      final basePts = geom.basePoints;
      final dotFill = Paint()..color = Colors.white;
      final dotStroke = Paint()
        ..color = _greenLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (final p in basePts) {
        canvas.drawCircle(p, 6, dotFill);
        canvas.drawCircle(p, 6, dotStroke);
      }

      final last = basePts.last;
      final lastHalo = Paint()..color = _greenLine.withValues(alpha:0.12);
      canvas.drawCircle(last, 12, lastHalo);
    }

    canvas.restore();

    _drawYAxisLabels(canvas, geom.plot, yRange);
    _drawXAxisLabels(canvas, geom.plot, labels);
  }

  List<Color> _paletteForStops(List<double> stops) {
    final min = stops.first;
    final max = stops.last;

    final looksLikePH =
        (max <= 14.0 && min >= 0.0 && stops.any((s) => (s - 6.5).abs() < 0.8));
    if (looksLikePH) {
      return const [
        Color(0xFFE85B5B),
        Color(0xFFF08A5B),
        Color(0xFFF2C94C),
        Color(0xFF7ED9BE),
        Color(0xFFF2C94C),
        Color(0xFFF08A5B),
        Color(0xFFE85B5B),
      ];
    }

    final looksLikeTemp =
        (max <= 80.0 && min >= -30.0 && stops.any((s) => (s - 24).abs() < 4.0));
    if (looksLikeTemp) {
      return const [
        Color(0xFF4A90E2),
        Color(0xFF5BC8A4),
        Color(0xFFB7E6A5),
        Color(0xFFF2C94C),
        Color(0xFFF08A5B),
        Color(0xFFE85B5B),
        Color(0xFFB00020),
      ];
    }

    if (isPercentScale || (min <= 0.0 && max >= 100.0)) {
      return const [
        Color(0xFFE85B5B),
        Color(0xFFF08A5B),
        Color(0xFFF2C94C),
        Color(0xFFF5E27A),
        Color(0xFFB7E6A5),
        Color(0xFF7ED9BE),
        Color(0xFF5BC8A4),
      ];
    }

    return const [
      Color(0xFFE85B5B),
      Color(0xFFF08A5B),
      Color(0xFFF2C94C),
      Color(0xFFB7E6A5),
      Color(0xFF7ED9BE),
      Color(0xFF5BC8A4),
      Color(0xFF3E9F86),
    ];
  }

  void _drawBands(Canvas canvas, Rect plot) {
    final stopsRaw = bandStops ?? const [0, 15, 30, 50, 70, 85, 100];
    final colorsRaw = bandColors ?? _paletteForStops(stopsRaw);

    final colors = (colorsRaw.length == stopsRaw.length)
        ? colorsRaw
        : List.generate(
            stopsRaw.length,
            (i) =>
                colorsRaw[(i * (colorsRaw.length - 1) / (stopsRaw.length - 1))
                    .round()],
          );

    final span = (yRange.end - yRange.start).abs().clamp(0.0001, 99999999.0);

    final stops = <double>[];
    final gradientColors = <Color>[];

    for (int i = 0; i < stopsRaw.length; i++) {
      final v = stopsRaw[i];
      if (v < yRange.start || v > yRange.end) continue;

      final t = ((v - yRange.start) / span).clamp(0.0, 1.0);
      final stop = (1.0 - t).clamp(0.0, 1.0);

      stops.add(stop);
      gradientColors.add(colors[i].withValues(alpha:0.34));
    }

    if (stops.length < 2) {
      stops
        ..clear()
        ..addAll([0.0, 1.0]);
      gradientColors
        ..clear()
        ..addAll([
          const Color(0xFF5BC8A4).withValues(alpha:0.24),
          const Color(0xFFF2C94C).withValues(alpha:0.24),
        ]);
    } else {
      final zipped = List.generate(
        stops.length,
        (i) => (stops[i], gradientColors[i]),
      )..sort((a, b) => a.$1.compareTo(b.$1));
      stops
        ..clear()
        ..addAll(zipped.map((e) => e.$1));
      gradientColors
        ..clear()
        ..addAll(zipped.map((e) => e.$2));
    }

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
        stops: stops,
      ).createShader(plot);

    canvas.drawRect(plot, paint);

    final sideFade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha:0.10),
          Colors.white.withValues(alpha:0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.18, 0.82, 1.0],
      ).createShader(plot);
    canvas.drawRect(plot, sideFade);

    final vignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha:0.16),
          Colors.white.withValues(alpha:0.00),
          Colors.white.withValues(alpha:0.00),
          Colors.white.withValues(alpha:0.10),
        ],
        stops: const [0.0, 0.22, 0.78, 1.0],
      ).createShader(plot);
    canvas.drawRect(plot, vignette);
  }

  void _drawGrid(Canvas canvas, Rect plot) {
    final grid = Paint()
      ..color = Colors.black.withValues(alpha:0.03)
      ..strokeWidth = 1;

    final ys = [
      plot.top + plot.height * 0.12,
      plot.top + plot.height * 0.50,
      plot.top + plot.height * 0.88,
    ];

    for (final y in ys) {
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }
  }

  void _drawYAxisLabels(Canvas canvas, Rect plot, RangeValues r) {
    final a = r.start;
    final b = r.end;
    final mid = (a + b) / 2;

    String fmt(double v) {
      final f =
          valueFormatter ??
          ((x) => isPercentScale ? '${x.round()}%' : x.toStringAsFixed(1));
      return f(v);
    }

    final labels = [fmt(b), fmt(mid), fmt(a)];
    final ys = [plot.top, plot.top + plot.height * 0.50, plot.bottom];

    for (int i = 0; i < labels.length; i++) {
      _tp(
        labels[i],
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0x88000000),
        ),
      ).paint(canvas, Offset(12, ys[i] - 8));
    }
  }

  void _drawXAxisLabels(Canvas canvas, Rect plot, List<String> labels) {
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: Colors.black.withValues(alpha:0.35),
    );

    if (labels.length < 2) return;

    final n = labels.length;
    final bool isMonths = (n == 12 && labels.first == 'E');
    final int maxVisible = isMonths ? 12 : 7;

    final step = (n <= maxVisible) ? 1 : ((n - 1) / (maxVisible - 1)).ceil();

    final dx = plot.width / (n - 1);
    final y = plot.bottom + 14;

    void paintAt(int i) {
      final tp = _tp(labels[i], style);
      final x = plot.left + dx * i - (tp.width / 2);
      tp.paint(canvas, Offset(x, y));
    }

    for (int i = 0; i < n; i += step) {
      paintAt(i);
    }
    if (((n - 1) % step) != 0) {
      paintAt(n - 1);
    }
  }

  TextPainter _tp(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp;
  }

  @override
  bool shouldRepaint(covariant _HistoryChartPainter oldDelegate) => true;
}
