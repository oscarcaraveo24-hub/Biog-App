import 'dart:ui';

import 'package:flutter/material.dart';

class OnboardingBackground extends StatelessWidget {
  final Widget child;

  const OnboardingBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FBFD),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFFDFEFF),
            Color(0xFFF5FAFC),
            Color(0xFFF7FBF6),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _BlurOrb(
            alignment: Alignment.topLeft,
            color: Color(0xFFE2F5FF),
            size: 240,
            offset: Offset(-54, -28),
          ),
          const _BlurOrb(
            alignment: Alignment.topRight,
            color: Color(0xFFFCEFD9),
            size: 250,
            offset: Offset(48, 12),
          ),
          const _BlurOrb(
            alignment: Alignment.bottomCenter,
            color: Color(0xFFDCF5DE),
            size: 310,
            offset: Offset(0, 110),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _OnboardingWavePainter(
                lineColor: const Color(0xFFFFFFFF).withValues(alpha:0.58),
                softColor: const Color(0xFFDDEEF3).withValues(alpha:0.26),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.08),
                    radius: 1.05,
                    colors: <Color>[
                      Colors.white.withValues(alpha:0.0),
                      Colors.white.withValues(alpha:0.10),
                      Colors.white.withValues(alpha:0.44),
                    ],
                    stops: const <double>[0.40, 0.72, 1.0],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;
  final Offset offset;

  const _BlurOrb({
    required this.alignment,
    required this.color,
    required this.size,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: IgnorePointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 58, sigmaY: 58),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingWavePainter extends CustomPainter {
  final Color lineColor;
  final Color softColor;

  const _OnboardingWavePainter({
    required this.lineColor,
    required this.softColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = softColor;

    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = lineColor;

    final Path topGlow = Path()
      ..moveTo(0, size.height * 0.24)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.18,
        size.width * 0.44,
        size.height * 0.25,
      )
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.31,
        size.width,
        size.height * 0.22,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final Path horizon = Path()
      ..moveTo(0, size.height * 0.63)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.57,
        size.width * 0.35,
        size.height * 0.68,
        size.width * 0.53,
        size.height * 0.62,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.56,
        size.width * 0.85,
        size.height * 0.69,
        size.width,
        size.height * 0.61,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(topGlow, fillPaint);
    canvas.drawPath(horizon, fillPaint..color = softColor.withValues(alpha:0.32));

    final List<double> waveYs = <double>[
      size.height * 0.30,
      size.height * 0.70,
      size.height * 0.76,
      size.height * 0.82,
    ];

    for (final double y in waveYs) {
      final Path path = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * 0.20,
          y - 18,
          size.width * 0.34,
          y + 20,
          size.width * 0.50,
          y + 4,
        )
        ..cubicTo(
          size.width * 0.66,
          y - 12,
          size.width * 0.82,
          y + 12,
          size.width,
          y - 8,
        );
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingWavePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.softColor != softColor;
  }
}
