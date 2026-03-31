import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bio_g/theme/bio_g_theme.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

class DashboardQuickActionCard extends StatefulWidget {
  final String assetIconPath;
  final String title;
  final VoidCallback onTap;
  final double assetScale;
  final double assetWidth;
  final double assetHeight;

  const DashboardQuickActionCard({
    super.key,
    required this.assetIconPath,
    required this.title,
    required this.onTap,
    this.assetScale = 1.0,
    this.assetWidth = 22,
    this.assetHeight = 22,
  });

  @override
  State<DashboardQuickActionCard> createState() =>
      _DashboardQuickActionCardState();
}

class _DashboardQuickActionCardState extends State<DashboardQuickActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double outerRadius = 17;
    const double innerRadius = 15;

    return Semantics(
      button: true,
      label: widget.title.replaceAll('\n', ' '),
      child: SizedBox.expand(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(outerRadius),
            splashColor: BioGTheme.brandTop.withValues(alpha: 0.05),
            highlightColor: Colors.white.withValues(alpha: 0.03),
            child: AnimatedBuilder(
              animation: _ringController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AnimatedBorderSweepPainter(
                    progress: _ringController.value,
                    radius: outerRadius,
                    strokeWidth: 1.55,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: BioGGlassCard(
                      radius: innerRadius,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                      backgroundColor: const Color(
                        0xFFF7FBF8,
                      ).withValues(alpha: 0.92),
                      borderColor: Colors.white.withValues(alpha: 0.95),
                      boxShadows: <BoxShadow>[
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            0,
                            0,
                            0,
                          ).withValues(alpha: 0.177),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(innerRadius - 1),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              const Color(0xFFEAF7F0).withValues(alpha: 0.70),
                              const Color(0xFFF4FBF7).withValues(alpha: 0.62),
                              Colors.white.withValues(alpha: 0.58),
                            ],
                          ),
                        ),
                        child: SizedBox.expand(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              const SizedBox(height: 2),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Transform.scale(
                                  scale: widget.assetScale,
                                  child: Image.asset(
                                    widget.assetIconPath,
                                    width: widget.assetWidth,
                                    height: widget.assetHeight,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.image_not_supported_rounded,
                                        size: widget.assetWidth,
                                        color: BioGTheme.ink,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 6,
                                  bottom: 2,
                                ),
                                child: Text(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.10,
                                    fontWeight: FontWeight.w800,
                                    color: BioGTheme.ink,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBorderSweepPainter extends CustomPainter {
  final double progress;
  final double radius;
  final double strokeWidth;

  const _AnimatedBorderSweepPainter({
    required this.progress,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final Rect rect = Offset.zero & size;
    final RRect borderRRect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    final Paint baseBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;

    canvas.drawRRect(borderRRect, baseBorder);

    final double rotation = (progress * math.pi * 2) - (math.pi / 2);

    final Shader sweepShader = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      transform: GradientRotation(rotation),
      colors: <Color>[
        Colors.transparent,
        Colors.transparent,
        BioGTheme.brandTop.withValues(alpha: 0.00),
        BioGTheme.brandTop.withValues(alpha: 0.25),
        BioGTheme.brandTop.withValues(alpha: 0.95),
        BioGTheme.brandMid.withValues(alpha: 0.90),
        BioGTheme.brandTop.withValues(alpha: 0.35),
        Colors.transparent,
        Colors.transparent,
      ],
      stops: const <double>[
        0.00,
        0.62,
        0.72,
        0.78,
        0.82,
        0.85,
        0.89,
        0.95,
        1.00,
      ],
    ).createShader(rect);

    final Paint glowPaint = Paint()
      ..shader = sweepShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1.1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);

    final Paint ringPaint = Paint()
      ..shader = sweepShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(borderRRect, glowPaint);
    canvas.drawRRect(borderRRect, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedBorderSweepPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
