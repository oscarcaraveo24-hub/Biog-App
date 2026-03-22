import 'dart:math';
import 'package:flutter/material.dart';

class FloatingParticles extends StatefulWidget {
  final int particleCount;
  final Color color;

  const FloatingParticles({
    super.key,
    this.particleCount = 25,
    this.color = const Color(0xFF40BB5F),
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _particles = _generateParticles();
  }

  List<_Particle> _generateParticles() {
    final Random rng = Random(42);
    final List<_Particle> particles = <_Particle>[];

    for (int i = 0; i < widget.particleCount; i++) {
      final bool isBokeh = i < 4; // first few are larger bokeh-like particles
      particles.add(
        _Particle(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          radius: isBokeh
              ? 8.0 + rng.nextDouble() * 6.0 // 8-14px for bokeh
              : 2.0 + rng.nextDouble() * 4.0, // 2-6px for normal
          opacity: isBokeh
              ? 0.03 + rng.nextDouble() * 0.04 // 0.03-0.07 for bokeh
              : 0.06 + rng.nextDouble() * 0.14, // 0.06-0.20 for normal
          speed: 0.03 + rng.nextDouble() * 0.06, // vertical speed factor
          swayAmplitude: 0.01 + rng.nextDouble() * 0.025,
          swayPhase: rng.nextDouble() * 2 * pi,
          swayFrequency: 0.8 + rng.nextDouble() * 1.4,
        ),
      );
    }

    return particles;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ParticlesPainter(
              particles: _particles,
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x; // 0..1 normalized horizontal position
  final double y; // 0..1 normalized starting vertical position
  final double radius;
  final double opacity;
  final double speed; // how fast it floats upward per cycle
  final double swayAmplitude; // horizontal sway range (normalized)
  final double swayPhase; // unique phase offset for sine wave
  final double swayFrequency; // how many oscillations per cycle

  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.speed,
    required this.swayAmplitude,
    required this.swayPhase,
    required this.swayFrequency,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0..1 animation progress
  final Color color;

  const _ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final _Particle p in particles) {
      // Vertical position: float upward, wrap around smoothly
      final double rawY = p.y - progress * p.speed * 12;
      final double y = (rawY % 1.0 + 1.0) % 1.0; // always positive mod

      // Horizontal sway via sine wave
      final double sway =
          sin(progress * 2 * pi * p.swayFrequency + p.swayPhase) *
              p.swayAmplitude;
      final double x = p.x + sway;

      final Offset center = Offset(x * size.width, y * size.height);
      final Paint paint = Paint()
        ..color = color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
