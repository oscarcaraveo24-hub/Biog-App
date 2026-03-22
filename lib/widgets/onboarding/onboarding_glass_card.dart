import 'dart:ui';

import 'package:flutter/material.dart';

class OnboardingGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurSigma;

  const OnboardingGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.backgroundColor,
    this.borderColor,
    this.blurSigma = 16,
  });

  @override
  Widget build(BuildContext context) {
    final Color resolvedBackground =
        backgroundColor ?? const Color(0xFFFDFEFE).withValues(alpha:0.74);
    final Color resolvedBorder =
        borderColor ?? const Color(0xFFFFFFFF).withValues(alpha:0.88);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFFB7C9D5).withValues(alpha:0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: resolvedBackground,
              border: Border.all(color: resolvedBorder, width: 1.1),
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

