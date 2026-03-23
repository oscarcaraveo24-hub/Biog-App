import 'dart:ui';
import 'package:flutter/material.dart';

/// ✅ Base reusable para TODAS las cards (MetricCard-style)
/// - Shadow FUERA del ClipRRect (no se corta)
/// - Backdrop blur sigma 8
/// - Fondo glass suave
/// - Border blanco
/// - Radius default 18
class BioGGlassCard extends StatelessWidget {
  final Widget child;

  /// Defaults clonados de MetricCard
  final double radius;
  final EdgeInsets padding;

  /// Margen exterior (por si quieres separar cards sin meter SizedBox fuera)
  final EdgeInsets margin;

  /// Si alguna card requiere un color distinto, puedes sobreescribir
  /// (si no, usa exactamente el de MetricCard)
  final Color? backgroundColor;

  /// Border override (si no, usa el de MetricCard)
  final Color? borderColor;

  /// Blur override (si no, usa el de MetricCard)
  final double blurSigma;

  /// Permite suavizar o quitar sombras en contextos como modals/sheets
  /// donde la sombra default puede verse demasiado pesada.
  final List<BoxShadow>? boxShadows;

  const BioGGlassCard({
    super.key,
    required this.child,
    this.radius = 18,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 12, 8),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.borderColor,
    this.blurSigma = 8,
    this.boxShadows,
  });

  @override
  Widget build(BuildContext context) {
    final bg =
        backgroundColor ?? const Color(0xFFF2F4F6).withValues(alpha: 0.92);
    final br = borderColor ?? Colors.white.withValues(alpha: 0.96);
    final resolvedShadows =
        boxShadows ??
        <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 34,
            spreadRadius: 0,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 90,
            spreadRadius: 0,
            offset: const Offset(0, 46),
          ),
          BoxShadow(
            color: const Color(0xFF00BCD4).withValues(alpha: 0.10),
            blurRadius: 110,
            spreadRadius: 0,
            offset: const Offset(0, 56),
          ),
        ];

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: resolvedShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: bg,
              border: Border.all(color: br),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
