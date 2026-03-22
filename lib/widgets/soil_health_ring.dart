import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class SoilHealthRing extends StatefulWidget {
  final double percent; // 0.0 a 1.0
  final String label;
  final VoidCallback? onBadgeTap;

  const SoilHealthRing({
    super.key,
    required this.percent,
    required this.label,
    this.onBadgeTap,
  });

  @override
  State<SoilHealthRing> createState() => _SoilHealthRingState();
}

class _SoilHealthRingState extends State<SoilHealthRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();

   _controller = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 2200),
);

_anim = Tween<double>(
  begin: 0.0,
  end: widget.percent.clamp(0.0, 1.0),
).animate(
  CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
);

_controller.forward();


    // ✅ dispara la animación al entrar
    Future.delayed(const Duration(milliseconds: 1000), () {
  if (mounted) {
    _controller.forward();
  }
});

  }

  @override
  void didUpdateWidget(covariant SoilHealthRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newEnd = widget.percent.clamp(0.0, 1.0);
    if (oldWidget.percent != widget.percent) {
      _anim = Tween<double>(begin: _anim.value, end: newEnd).animate(
  CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
);
_controller
  ..reset()
  ..forward();

    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 260;

    // 🎛️ Proporciones
    const double ringStroke = 22;
    const double grassFactor = 0.74;
    const double whiteHaloFactor = 0.82;

    // ✅ Radio del anillo
    final double ringRadius = (size / 2) - ringStroke / 2;

    // ⚪ Marco blanco EXTERIOR (engloba TODO el progress)
    const double outerFrameStroke = 10;
    const double outerFrameGap = 6;

    final double ringOuterRadius = ringRadius + (ringStroke / 2);
    final double outerFrameRadius = ringOuterRadius + outerFrameGap;

    // 🔘 Badge
    const double badgeSize = 66;
    final double badgeRadius = badgeSize / 2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final p = _anim.value;

        // ✅ LLAMADA CORRECTA (función global)
        final Offset badgeCenter = _badgeCenterForPercent(
          percent: p,
          center: const Offset(size / 2, size / 2),
          radius: ringRadius,
        );

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 🌟 GLOW EXTERIOR
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha:0.28),
                        blurRadius: 70,
                        spreadRadius: -22,
                      ),
                    ],
                  ),
                ),

                // ⚪ MARCO BLANCO EXTERIOR
                CustomPaint(
                  size: const Size(size, size),
                  painter: _OuterFrameRingPainter(
                    radius: outerFrameRadius,
                    stroke: outerFrameStroke,
                  ),
                ),

                // 🔘 ANILLO BASE
                CustomPaint(
                  size: const Size(size, size),
                  painter: _BaseRingPainter(ringStroke),
                ),

                // 🌈 ANILLO ACTIVO (ANIMADO)
                CustomPaint(
                  size: const Size(size, size),
                  painter: _ActiveRingPainter(p, ringStroke),
                ),

                // ⚪ HALO BLANCO CENTRAL
                Container(
                  width: size * whiteHaloFactor,
                  height: size * whiteHaloFactor,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha:0.88),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 26,
                        color: Colors.black.withValues(alpha:0.05),
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                ),

                // 🌱 PASTO
                ClipOval(
                  child: SizedBox(
                    width: size * grassFactor,
                    height: size * grassFactor,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, 0),
                          child: Image.asset(
                            'assets/images/circle_grass.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Container(color: Colors.white.withValues(alpha:0.10)),
                      ],
                    ),
                  ),
                ),

                // 🔢 TEXTO (ANIMADO)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
  offset: const Offset(0, -10),
  child: Text(
    '${(p * 100).round()}%',
    style: TextStyle(
      fontSize: 46,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.0,
      height: 0.95,
      color: Colors.black87,
      shadows: [
        // Sombra profunda suave
        Shadow(
          blurRadius: 22,
          color: Colors.black.withValues(alpha:0.10),
          offset: const Offset(0, 2),
        ),

        // Definición más cercana
        Shadow(
          blurRadius: 2,
          color: Colors.black.withValues(alpha:0.15),
          offset: const Offset(0, 1),
        ),
      ],
    ),
  ),
),

                    const SizedBox(height: 2),
                    Text(
  widget.label,
  textAlign: TextAlign.center,
  style: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Colors.black.withValues(alpha:0.60),
    height: 1.05,
    shadows: [
      // sombra principal (más “dura”)
      Shadow(
        blurRadius: 7,
        color: Colors.black.withValues(alpha:0.22),
        offset: const Offset(0, 2),
      ),
      // sombra de definición (más cercana)
      Shadow(
        blurRadius: 2,
        color: Colors.black.withValues(alpha:0.18),
        offset: const Offset(0, 1),
      ),
    ],
  ),
),

                  ],
                ),

                // ✅ BADGE (ANIMADO)
                Positioned(
                  left: badgeCenter.dx - badgeRadius,
                  top: badgeCenter.dy - badgeRadius,
                  child: _RingBadge(
                    size: badgeSize,
                    onTap: widget.onBadgeTap,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ✅ FUNCIÓN GLOBAL (afuera de la clase) para calcular el badge
Offset _badgeCenterForPercent({
  required double percent,
  required Offset center,
  required double radius,
}) {
  final p = percent.clamp(0.0, 1.0);
  final angle = (-pi / 2) + (2 * pi * p);

  final x = center.dx + radius * cos(angle);
  final y = center.dy + radius * sin(angle);

  return Offset(x, y);
}

/// ⚪ Marco blanco exterior que engloba TODO el progress + shadow suave
class _OuterFrameRingPainter extends CustomPainter {
  final double radius;
  final double stroke;

  _OuterFrameRingPainter({
    required this.radius,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha:0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.save();
    canvas.translate(0, 6);
    canvas.drawCircle(center, radius, shadowPaint);
    canvas.restore();

    final paint = Paint()
      ..color = Colors.white.withValues(alpha:0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _OuterFrameRingPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.stroke != stroke;
  }
}

/// 🔘 ANILLO BASE
class _BaseRingPainter extends CustomPainter {
  final double stroke;
  _BaseRingPainter(this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - stroke / 2;

    final paint = Paint()
      ..color = Colors.black.withValues(alpha:0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 🌈 ANILLO ACTIVO (degradado REAL sin cortes: se pinta por segmentos)
class _ActiveRingPainter extends CustomPainter {
  final double percent;
  final double stroke;

  _ActiveRingPainter(this.percent, this.stroke);

  static const _stops = <double>[0.00, 0.30, 0.55, 0.78, 1.00];
  static const _colors = <Color>[
    Color(0xFF4CAF50),
    Color(0xFF66BB6A),
    Color(0xFF81C784),
    Color(0xFF4DB6AC),
    Color(0xFF4CAF50),
  ];

  Color _colorAt(double t) {
    t = t.clamp(0.0, 1.0);
    for (int i = 0; i < _stops.length - 1; i++) {
      final a = _stops[i];
      final b = _stops[i + 1];
      if (t >= a && t <= b) {
        final localT = (t - a) / (b - a);
        return Color.lerp(_colors[i], _colors[i + 1], localT)!;
      }
    }
    return _colors.last;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width / 2) - stroke / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );

    final p = percent.clamp(0.0, 1.0);
    final sweepAngle = 2 * pi * p;

    final shadowPaint = Paint()
      ..color = const Color(0xFF00BCD4).withValues(alpha:0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.save();
    canvas.translate(0, 6);
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, shadowPaint);
    canvas.restore();

    const int segments = 220;
    final segSweep = sweepAngle / segments;
    const double overlap = 0.002;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    for (int i = 0; i < segments; i++) {
      final tMid = (i + 0.5) / segments;
      paint.color = _colorAt(tMid);
      final start = (-pi / 2) + segSweep * i;
      canvas.drawArc(rect, start, segSweep + overlap, false, paint);
    }

    // caps inicio/fin (premium)
    final capPaint = Paint()
      ..color = _colorAt(0.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(rect, -pi / 2, 0.0001, false, capPaint);

    capPaint.color = _colorAt(1.0);
    canvas.drawArc(rect, (-pi / 2) + sweepAngle - 0.0001, 0.0001, false, capPaint);
  }

  @override
  bool shouldRepaint(covariant _ActiveRingPainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.stroke != stroke;
  }
}

/// ✅ Badge circular (gota) que sigue el final del progreso
class _RingBadge extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const _RingBadge({
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = size * 0.67;

    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha:0.92),
        border: Border.all(color: Colors.white.withValues(alpha:0.95), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.18),
            blurRadius: 22,
            spreadRadius: -10,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF00BCD4).withValues(alpha:0.18),
            blurRadius: 34,
            spreadRadius: -18,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF22D3EE),
                Color(0xFF14B8A6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BCD4).withValues(alpha:0.35),
                blurRadius: 18,
                spreadRadius: -10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.water_drop,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );

    if (onTap == null) return badge;
    return GestureDetector(onTap: onTap, child: badge);
  }
}
