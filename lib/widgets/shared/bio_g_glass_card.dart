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

  /// Si se dibuja el desenfoque de lo que hay DETRÁS de la tarjeta.
  ///
  /// ── Por qué se puede apagar sin que se note ──────────────────────────────
  ///
  /// `BackdropFilter` es de lo más caro que se puede pedir en Flutter: obliga
  /// al compositor a leer todo lo ya pintado debajo, desenfocarlo y guardarlo
  /// en una capa aparte, una vez por tarjeta y por frame.
  ///
  /// Con el fondo por defecto (`0xFFF2F4F6` al 92 %) lo desenfocado aporta el
  /// 8 % del color final. Sobre un degradado suave —el fondo de las pantallas
  /// de clima— la diferencia entre ese fondo y su versión desenfocada no llega
  /// a una unidad de RGB, y ese 8 % la deja en centésimas: no es que se note
  /// poco, es que no se puede representar en 8 bits por canal.
  ///
  /// Donde SÍ importa es sobre imágenes con detalle fino (el cielo del fondo
  /// compartido) o con fondos más translúcidos. Por eso el valor por defecto
  /// es true y esto se apaga a mano, tarjeta por tarjeta, no de forma global.
  ///
  /// Nada más cambia: mismo recorte, mismo color, mismo borde, mismas sombras.
  final bool useBackdropBlur;

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
    this.useBackdropBlur = true,
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

    final Widget surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: bg,
        border: Border.all(color: br),
      ),
      child: child,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: resolvedShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: useBackdropBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: surface,
              )
            : surface,
      ),
    );
  }
}
