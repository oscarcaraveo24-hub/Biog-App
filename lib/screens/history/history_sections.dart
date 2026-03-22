import 'package:flutter/material.dart';

class HistoryPageBackground extends StatelessWidget {
  const HistoryPageBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: Container(color: const Color(0xFFF4F7F6)));
  }
}

class HistoryReveal extends StatelessWidget {
  final AnimationController controller;
  final double intervalStart;
  final double intervalEnd;
  final double yOffset;
  final double shadowOpacityBegin;
  final double shadowOpacityEnd;
  final Widget child;

  const HistoryReveal({
    super.key,
    required this.controller,
    required this.intervalStart,
    required this.intervalEnd,
    required this.child,
    this.yOffset = 12,
    this.shadowOpacityBegin = 0.0,
    this.shadowOpacityEnd = 0.08,
  });

  static const Curve _motionCurve = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Curve _opacityCurve = Cubic(0.18, 0.84, 0.24, 1.0);

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation motion = CurvedAnimation(
      parent: controller,
      curve: Interval(intervalStart, intervalEnd, curve: _motionCurve),
    );

    final CurvedAnimation opacityMotion = CurvedAnimation(
      parent: controller,
      curve: Interval(
        intervalStart,
        intervalStart + ((intervalEnd - intervalStart) * 0.84),
        curve: _opacityCurve,
      ),
    );

    final Animation<double> opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(opacityMotion);

    final Animation<double> translateY = Tween<double>(
      begin: yOffset,
      end: 0.0,
    ).animate(motion);

    final Animation<double> shadowOpacity = Tween<double>(
      begin: shadowOpacityBegin,
      end: shadowOpacityEnd,
    ).animate(motion);

    final Animation<double> shadowBlur = Tween<double>(
      begin: 0.0,
      end: 24.0,
    ).animate(motion);

    final Animation<double> shadowDy = Tween<double>(
      begin: 0.0,
      end: 14.0,
    ).animate(motion);

    return FadeTransition(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, translateY.value),
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: shadowOpacity.value.clamp(0.0, 0.20),
                    ),
                    blurRadius: shadowBlur.value,
                    offset: Offset(0, shadowDy.value),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class HistoryTopBarSection extends StatelessWidget {
  final String subtitle;
  final String modeLabel;

  const HistoryTopBarSection({
    super.key,
    required this.subtitle,
    required this.modeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Historial',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              _RangeSubtitle(text: subtitle),
              const SizedBox(height: 6),
              Text(
                modeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _IconChip(icon: Icons.tune_rounded),
      ],
    );
  }
}

class _RangeSubtitle extends StatelessWidget {
  final String text;

  const _RangeSubtitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(width: 6),
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: Colors.black54,
        ),
      ],
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;

  const _IconChip({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Icon(icon, color: Colors.black87),
    );
  }
}
