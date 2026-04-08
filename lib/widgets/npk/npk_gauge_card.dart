import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

enum NpkChannel { n, p, k }

class NpkGaugeCard extends StatelessWidget {
  const NpkGaugeCard({
    super.key,
    required this.channel,
    required this.percent, // 0..1 (posición del arco)
    required this.title,
    required this.description,
    this.showDescription = true,
    this.targetMin,
    this.targetMax,
    this.statusLabel,
    required this.centerValue,
    this.centerUnit = 'mg/kg',
    this.cropCapPpm,
  });

  final NpkChannel channel;
  final double percent; // 0..1
  final String title;
  final String description;
  final bool showDescription;

  /// Estos targets siguen viniendo en escala 0..100 para el painter.
  final int? targetMin;
  final int? targetMax;

  final String? statusLabel;

  final int centerValue;
  final String centerUnit;

  /// Cap de ppm específico por cultivo. Si es null, usa el cap genérico.
  final double? cropCapPpm;

  Color _accent() {
    switch (channel) {
      case NpkChannel.n:
        return const Color(0xFFB38A2E);
      case NpkChannel.p:
        return const Color(0xFF2FAF63);
      case NpkChannel.k:
        return const Color(0xFF2B7EBB);
    }
  }

  List<Color> _gradient() {
    final a = _accent();
    return [a.withValues(alpha:0.85), a.withValues(alpha:0.98), a.withValues(alpha:0.92)];
  }

  /// Cap efectivo: usa el del cultivo si viene, si no, el genérico del canal.
  double _effectiveCapPpm() {
    if (cropCapPpm != null && cropCapPpm! > 0) return cropCapPpm!;
    switch (channel) {
      case NpkChannel.n:
        return 120.0;
      case NpkChannel.p:
        return 80.0;
      case NpkChannel.k:
        return 140.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
    final pctClamped = percent.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: pctClamped),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Column(
          children: [
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w900,
                color: Colors.black.withValues(alpha:0.70),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: _NpkGaugePainter(
                      channel: channel,
                      percent: v,
                      accent: accent,
                      gradient: _gradient(),
                      targetMin: targetMin,
                      targetMax: targetMax,
                      capPpm: _effectiveCapPpm(),
                    ),
                    child: _GaugeCenter(
                      bigText: '$centerValue',
                      unitText: centerUnit,
                      accent: accent,
                      statusLabel: statusLabel,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (showDescription)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.6,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: Colors.black.withValues(alpha:0.58),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GaugeCenter extends StatelessWidget {
  const _GaugeCenter({
    required this.bigText,
    required this.unitText,
    required this.accent,
    this.statusLabel,
  });

  final String bigText;
  final String unitText;
  final Color accent;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.black.withValues(alpha:0.74),
                height: 1.0,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(text: bigText),
                TextSpan(
                  text: ' $unitText',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withValues(alpha:0.42),
                  ),
                ),
              ],
            ),
          ),
          if ((statusLabel ?? '').isNotEmpty) const SizedBox(height: 8),
          if ((statusLabel ?? '').isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: accent.withValues(alpha:0.08),
                border: Border.all(color: Colors.white.withValues(alpha:0.80)),
              ),
              child: Text(
                statusLabel!,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withValues(alpha:0.55),
                  height: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NpkGaugePainter extends CustomPainter {
  _NpkGaugePainter({
    required this.channel,
    required this.percent,
    required this.accent,
    required this.gradient,
    required this.capPpm,
    this.targetMin,
    this.targetMax,
  });

  final NpkChannel channel;
  final double percent;
  final Color accent;
  final List<Color> gradient;
  final double capPpm;

  final int? targetMin;
  final int? targetMax;

  static const double _startDeg = 120;
  static const double _sweepDeg = 300;
  static const double _stroke = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;

    final rect = Rect.fromCircle(center: c, radius: r - 10);
    final start = _degToRad(_startDeg);
    final sweep = _degToRad(_sweepDeg);
    final pSweep = sweep * percent.clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha:0.08);

    canvas.drawArc(rect, start, sweep, false, trackPaint);

    _drawTicksAndLabels(canvas, c, r, start, sweep);
    _drawTargetBand(canvas, rect, start, sweep);

    final progPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: [gradient[0], gradient[1], gradient[2]],
        stops: const [0.0, 0.55, 1.0],
        transform: GradientRotation(start),
      ).createShader(rect);

    final glowOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke + 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..color = accent.withValues(alpha:0.22);

    final glowInner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = accent.withValues(alpha:0.16);

    if (pSweep > 0.001) {
      canvas.drawArc(rect, start, pSweep, false, glowOuter);
      canvas.drawArc(rect, start, pSweep, false, glowInner);
      canvas.drawArc(rect, start, pSweep, false, progPaint);
    }

    _drawMarker(canvas, c, r, start + pSweep);

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha:0.65);
    canvas.drawCircle(c, r - 10 - _stroke / 2, inner);
  }

  void _drawTicksAndLabels(
    Canvas canvas,
    Offset c,
    double r,
    double start,
    double sweep,
  ) {
    final tickOuter = r - 10 + 1;

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha:0.10);

    final majorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha:0.14);

    for (int v = 0; v <= 100; v += 5) {
      final t = v / 100.0;
      final ang = start + sweep * t;

      final isMajor = (v % 20 == 0);
      final len = isMajor ? 14.0 : 8.0;

      final o = Offset(
        c.dx + math.cos(ang) * tickOuter,
        c.dy + math.sin(ang) * tickOuter,
      );
      final i = Offset(
        c.dx + math.cos(ang) * (tickOuter - len),
        c.dy + math.sin(ang) * (tickOuter - len),
      );

      canvas.drawLine(i, o, isMajor ? majorPaint : tickPaint);

      if (isMajor) {
        _drawLabel(canvas, c, ang, r, v);
      }
    }
  }

  void _drawLabel(Canvas canvas, Offset c, double ang, double r, int scalePct) {
    final ppmValue = ((scalePct / 100.0) * capPpm).round();

    final tp = TextPainter(
      text: TextSpan(
        text: ppmValue.toString(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: Colors.black.withValues(alpha:0.38),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelR = r - 10 + 22;
    final pos = Offset(
      c.dx + math.cos(ang) * labelR - tp.width / 2,
      c.dy + math.sin(ang) * labelR - tp.height / 2,
    );

    tp.paint(canvas, pos);
  }

  void _drawTargetBand(Canvas canvas, Rect rect, double start, double sweep) {
    final min = targetMin;
    final max = targetMax;
    if (min == null || max == null) return;

    final a = (min.clamp(0, 100)) / 100.0;
    final b = (max.clamp(0, 100)) / 100.0;
    if (b <= a) return;

    final bandStart = start + sweep * a;
    final bandSweep = sweep * (b - a);

    final bandPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke - 6
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha:0.14);

    final bandGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke + 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = accent.withValues(alpha:0.08);

    canvas.drawArc(rect, bandStart, bandSweep, false, bandGlow);
    canvas.drawArc(rect, bandStart, bandSweep, false, bandPaint);
  }

  void _drawMarker(Canvas canvas, Offset c, double r, double ang) {
    final markerR = r - 10;
    final p = Offset(
      c.dx + math.cos(ang) * markerR,
      c.dy + math.sin(ang) * markerR,
    );

    final glow = Paint()
      ..color = accent.withValues(alpha:0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final core = Paint()..color = Colors.white.withValues(alpha:0.95);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent.withValues(alpha:0.72);

    canvas.drawCircle(p, 7.2, glow);
    canvas.drawCircle(p, 5.2, core);
    canvas.drawCircle(p, 5.2, edge);
  }

  double _degToRad(double d) => d * (math.pi / 180.0);

  @override
  bool shouldRepaint(covariant _NpkGaugePainter old) {
    return old.channel != channel ||
        old.percent != percent ||
        old.accent != accent ||
        old.capPpm != capPpm ||
        old.targetMin != targetMin ||
        old.targetMax != targetMax;
  }
}
