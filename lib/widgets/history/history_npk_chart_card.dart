import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

enum NpkChannel { n, p, k }

class HistoryNpkChartCard extends StatelessWidget {
  const HistoryNpkChartCard({
    super.key,
    required this.title,
    required this.labels,
    required this.nValues,
    required this.pValues,
    required this.kValues,
    this.yMax,
    this.lastReadingText,
  });

  /// Límite inferior de la meta de la etapa
  final String title;
  final List<String> labels;
  final List<double> nValues;
  final List<double> pValues;
  final List<double> kValues;

  /// ppm max del chart. Si viene null, se calcula con base a datos.
  final double? yMax;

  /// Ej: "Hoy · 2:14 pm"
  final String? lastReadingText;

  static const String _icN = 'assets/icons/metrics/ic_nitrogen.png';
  static const String _icP = 'assets/icons/metrics/ic_phosphorus.png';
  static const String _icK = 'assets/icons/metrics/ic_potassium.png';

  @override
  Widget build(BuildContext context) {
    final nNow = (nValues.isNotEmpty ? nValues.last : 0)
        .clamp(0, 999999)
        .toDouble();
    final pNow = (pValues.isNotEmpty ? pValues.last : 0)
        .clamp(0, 999999)
        .toDouble();
    final kNow = (kValues.isNotEmpty ? kValues.last : 0)
        .clamp(0, 999999)
        .toDouble();

    final status = _neutralStatus(nNow, pNow, kNow);

    final tN = _trendFromSeries(nValues);
    final tP = _trendFromSeries(pValues);
    final tK = _trendFromSeries(kValues);

    final lr = lastReadingText ?? 'Reciente';

    final computedMax = _autoYMax([
      ...nValues,
      ...pValues,
      ...kValues,
    ], fallback: 120);
    final yMaxFinal = (yMax ?? computedMax).clamp(10.0, 999999.0);

    return BioGGlassCard(
      radius: 18,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final size = Size(c.maxWidth, 210);

              final geomN = _ChartGeometry(
                size: size,
                values: nValues,
                yMin: 0,
                yMax: yMaxFinal,
              );
              final geomP = _ChartGeometry(
                size: size,
                values: pValues,
                yMin: 0,
                yMax: yMaxFinal,
              );
              final geomK = _ChartGeometry(
                size: size,
                values: kValues,
                yMin: 0,
                yMax: yMaxFinal,
              );

              return SizedBox(
                height: size.height,
                width: double.infinity,
                child: CustomPaint(
                  painter: _NpkChartPainter(
                    labels: labels,
                    geomN: geomN,
                    geomP: geomP,
                    geomK: geomK,
                    yMax: yMaxFinal,
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _NpkWideChips(
            n: nNow,
            p: pNow,
            k: kNow,
            trendN: tN,
            trendP: tP,
            trendK: tK,
            iconN: _icN,
            iconP: _icP,
            iconK: _icK,
          ),
          const SizedBox(height: 12),
          _StatusInlineDot(
            label: 'Estado actual',
            value: status.label,
            color: status.color,
          ),
          const SizedBox(height: 8),
          _LastReadingRow(lastReading: lr),
        ],
      ),
    );
  }

  static double _autoYMax(List<double> values, {required double fallback}) {
    if (values.isEmpty) return fallback;
    final maxV = values.fold<double>(0.0, (m, v) => v > m ? v : m);
    if (maxV <= 0) return fallback;

    final padded = maxV * 1.15;
    final rounded = (padded / 10.0).ceil() * 10.0;
    return rounded.clamp(fallback, 999999.0);
  }

  static _NpkState _neutralStatus(double n, double p, double k) {
    final hasAny = n > 0 || p > 0 || k > 0;
    if (!hasAny) {
      return const _NpkState('Sin lectura suficiente', Color(0xFF8A8F98));
    }
    return const _NpkState('Lectura reciente', Color(0xFF3E9F86));
  }

  static _Trend _trendFromSeries(List<double> values) {
    if (values.length < 2) return _Trend.steady;

    double avg(List<double> xs) =>
        xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

    if (values.length >= 6) {
      final a = avg(values.sublist(values.length - 3));
      final b = avg(values.sublist(values.length - 6, values.length - 3));
      final diff = a - b;
      if (diff > 1.2) return _Trend.up;
      if (diff < -1.2) return _Trend.down;
      return _Trend.steady;
    } else {
      final diff = values.last - values[values.length - 2];
      if (diff > 1.2) return _Trend.up;
      if (diff < -1.2) return _Trend.down;
      return _Trend.steady;
    }
  }
}

class _NpkState {
  final String label;
  final Color color;
  const _NpkState(this.label, this.color);
}

enum _Trend { up, down, steady }

class _StatusInlineDot extends StatelessWidget {
  const _StatusInlineDot({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(width: 10),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
            color: color.withValues(alpha: 0.95),
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _LastReadingRow extends StatelessWidget {
  const _LastReadingRow({required this.lastReading});
  final String lastReading;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: Colors.black.withValues(alpha: 0.45),
      height: 1.0,
    );

    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 14,
          color: Colors.black.withValues(alpha: 0.35),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Última lectura: $lastReading',
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _NpkWideChips extends StatelessWidget {
  const _NpkWideChips({
    required this.n,
    required this.p,
    required this.k,
    required this.trendN,
    required this.trendP,
    required this.trendK,
    required this.iconN,
    required this.iconP,
    required this.iconK,
  });

  final double n, p, k;
  final _Trend trendN, trendP, trendK;
  final String iconN, iconP, iconK;

  static const _nColor = Color(0xFFC9A227);
  static const _pColor = Color(0xFF3E9F86);
  static const _kColor = Color(0xFF3A78D4);

  @override
  Widget build(BuildContext context) {
    Widget chip({
      required String iconPath,
      required double v,
      required Color accent,
      required _Trend trend,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ScaledAssetIcon(path: iconPath, size: 28, scale: 2.2),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${v.round()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _TrendArrow(trend: trend, color: accent, size: 17, stroke: 2.2),
              ],
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: _StaggerEntrance(
              delayMs: 0,
              child: chip(
                iconPath: iconN,
                v: n,
                accent: _nColor,
                trend: trendN,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StaggerEntrance(
              delayMs: 130,
              child: chip(
                iconPath: iconP,
                v: p,
                accent: _pColor,
                trend: trendP,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StaggerEntrance(
              delayMs: 260,
              child: chip(
                iconPath: iconK,
                v: k,
                accent: _kColor,
                trend: trendK,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScaledAssetIcon extends StatelessWidget {
  const _ScaledAssetIcon({
    required this.path,
    required this.size,
    required this.scale,
  });

  final String path;
  final double size;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Center(
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              path,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

class _StaggerEntrance extends StatelessWidget {
  const _StaggerEntrance({required this.child, this.delayMs = 0});

  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final tt = (t - (delayMs / 900)).clamp(0.0, 1.0);

        final opacity = tt;
        final dy = (1.0 - tt) * 12.0;
        final scale = 0.97 + (0.03 * tt);

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

class _TrendArrow extends StatelessWidget {
  const _TrendArrow({
    required this.trend,
    required this.color,
    this.size = 20,
    this.stroke = 3.2,
  });

  final _Trend trend;
  final Color color;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TrendArrowPainter(trend: trend, color: color, stroke: stroke),
    );
  }
}

class _TrendArrowPainter extends CustomPainter {
  const _TrendArrowPainter({
    required this.trend,
    required this.color,
    required this.stroke,
  });

  final _Trend trend;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    Path path() {
      final w = size.width;
      final h = size.height;

      switch (trend) {
        case _Trend.up:
          return Path()
            ..moveTo(w * 0.22, h * 0.62)
            ..lineTo(w * 0.50, h * 0.32)
            ..lineTo(w * 0.78, h * 0.62)
            ..moveTo(w * 0.50, h * 0.32)
            ..lineTo(w * 0.50, h * 0.82);

        case _Trend.down:
          return Path()
            ..moveTo(w * 0.22, h * 0.38)
            ..lineTo(w * 0.50, h * 0.68)
            ..lineTo(w * 0.78, h * 0.38)
            ..moveTo(w * 0.50, h * 0.68)
            ..lineTo(w * 0.50, h * 0.18);

        case _Trend.steady:
          return Path()
            ..moveTo(w * 0.18, h * 0.52)
            ..lineTo(w * 0.82, h * 0.52)
            ..moveTo(w * 0.82, h * 0.52)
            ..lineTo(w * 0.66, h * 0.36)
            ..moveTo(w * 0.82, h * 0.52)
            ..lineTo(w * 0.66, h * 0.68);
      }
    }

    final pp = path();
    canvas.drawPath(pp, glow);
    canvas.drawPath(pp, p);
  }

  @override
  bool shouldRepaint(covariant _TrendArrowPainter oldDelegate) {
    return oldDelegate.trend != trend ||
        oldDelegate.color != color ||
        oldDelegate.stroke != stroke;
  }
}

class _NpkChartPainter extends CustomPainter {
  final List<String> labels;
  final _ChartGeometry geomN;
  final _ChartGeometry geomP;
  final _ChartGeometry geomK;
  final double yMax;

  const _NpkChartPainter({
    required this.labels,
    required this.geomN,
    required this.geomP,
    required this.geomK,
    required this.yMax,
  });

  static const _n = Color(0xFFC9A227);
  static const _p = Color(0xFF3E9F86);
  static const _k = Color(0xFF3A78D4);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    final plot = geomN.plot;

    _drawBands(canvas, plot);
    _drawGrid(canvas, plot);

    _drawSeries(canvas, geomN, _n);
    _drawSeries(canvas, geomP, _p);
    _drawSeries(canvas, geomK, _k);

    canvas.restore();

    _drawYAxisLabels(canvas, plot);
    _drawXAxisLabels(canvas, plot);
  }

  void _drawBands(Canvas canvas, Rect plot) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _n.withValues(alpha: 0.18),
          _p.withValues(alpha: 0.14),
          _p.withValues(alpha: 0.11),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(plot);

    canvas.drawRect(plot, paint);

    final sideFade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.10),
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
          Colors.white.withValues(alpha: 0.14),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.10),
        ],
        stops: const [0.0, 0.75, 1.0],
      ).createShader(plot);
    canvas.drawRect(plot, vignette);
  }

  void _drawGrid(Canvas canvas, Rect plot) {
    final grid = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
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

  void _drawSeries(Canvas canvas, _ChartGeometry geom, Color color) {
    final pts = geom.smoothPoints;
    if (pts.isEmpty) return;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.045)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    canvas.save();
    canvas.translate(0, 1);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    canvas.drawPath(path, linePaint);

    if (geom.basePoints.isNotEmpty) {
      final basePts = geom.basePoints;

      final dotFill = Paint()..color = Colors.white.withValues(alpha: 0.92);
      final dotStroke = Paint()
        ..color = color.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (final p in basePts) {
        canvas.drawCircle(p, 6, dotFill);
        canvas.drawCircle(p, 6, dotStroke);
      }

      final last = basePts.last;
      final lastHalo = Paint()..color = color.withValues(alpha: 0.12);
      canvas.drawCircle(last, 12, lastHalo);
    }
  }

  void _drawYAxisLabels(Canvas canvas, Rect plot) {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0x88000000),
    );

    final top = yMax.round().toString();
    final mid = (yMax / 2).round().toString();

    _tp(top, style).paint(canvas, Offset(12, plot.top - 8));
    _tp(
      mid,
      style,
    ).paint(canvas, Offset(12, plot.top + plot.height * 0.50 - 8));
    _tp('0', style).paint(canvas, Offset(12, plot.bottom - 8));
  }

  void _drawXAxisLabels(Canvas canvas, Rect plot) {
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: Colors.black.withValues(alpha: 0.35),
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
  bool shouldRepaint(covariant _NpkChartPainter oldDelegate) => true;
}

class _ChartGeometry {
  final Size size;
  final Rect plot;
  final List<Offset> basePoints;
  final List<Offset> smoothPoints;

  _ChartGeometry({
    required this.size,
    required List<double> values,
    required double yMin,
    required double yMax,
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
