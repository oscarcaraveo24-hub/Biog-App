import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bio_g/widgets/shared/animated_value_text.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;

  /// ✅ Nuevo: icono PNG (recomendado)
  /// Ej: 'assets/icons/metrics/ic_moisture.png'
  final String? assetIcon;

  /// (Legacy) si aún quieres usar IconData en algunos casos
  final IconData? icon;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    this.assetIcon,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = _MetricStyle.from(title: title, status: status);

    // ✅ SHADOW AFUERA (NO CLIP) -> drop shadow real como Insight
    final shell = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.18),
            blurRadius: 34,
            spreadRadius: 0,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha:0.10),
            blurRadius: 90,
            spreadRadius: 0,
            offset: const Offset(0, 46),
          ),
          BoxShadow(
            color: const Color(0xFF00BCD4).withValues(alpha:0.10),
            blurRadius: 110,
            spreadRadius: 0,
            offset: const Offset(0, 56),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFF2F4F6).withValues(alpha:0.92),
              border: Border.all(color: Colors.white.withValues(alpha:0.96)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Icono (PNG) + título
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, 8),
                      child: Transform.scale(
                        scale: 4.5,
                        child: _MetricIcon(
                          assetIcon: assetIcon,
                          icon: icon,
                          color: style.iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 17),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          height: 0.9,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: AnimatedValueText(
                    value: value,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: Colors.black87,
                      height: 1.0,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ✅ Fila inferior: pill abajo izquierda (y los dots van dentro del pill)
               SizedBox(
  height: 21,
  child: Transform.translate(
    offset: const Offset(0, -1), // 👈 sube 1px (visual)
    child: Row(
      children: [
        _StatusPill(
          text: status,
          bg: style.pillBg,
          fg: style.pillFg,
          dotColor: style.dotColor,
        ),
        const Spacer(),
      ],
    ),
  ),
),

              ],
            ),
          ),
        ),
      ),
    );

    return shell;
  }
}

/// ✅ Icono para MetricCard: PNG (recomendado) o IconData fallback
class _MetricIcon extends StatelessWidget {
  final String? assetIcon;
  final IconData? icon;
  final Color color;

  const _MetricIcon({
    required this.assetIcon,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (assetIcon != null) {
      return Image.asset(
        assetIcon!,
        width: 22,
        height: 22,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.circle, size: 22, color: color),
      );
    }

    return Icon(icon ?? Icons.circle, size: 22, color: color);
  }
}

/// ✅ Pastilla de estado (más larga) + 4 dots dentro (NO usa Spacer interno)
class _StatusPill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final Color dotColor;

  const _StatusPill({
    required this.text,
    required this.bg,
    required this.fg,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ ancho FINITO (clave para evitar unbounded width)
    return SizedBox(
      width: 146, // 👈 hazla más larga aquí (152/160 si quieres)
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical:3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ sin Spacer
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
            _MetricDots(color: dotColor),
          ],
        ),
      ),
    );
  }
}

/// ✅ Dots decorativos (4) con opacidad diferente (anti-clip abajo)
class _MetricDots extends StatelessWidget {
  final Color color;
  const _MetricDots({required this.color});

  @override
  Widget build(BuildContext context) {
    const ops = [1.0, 0.65, 0.38, 0.18];

    return Transform.translate(
      offset: const Offset(0, -1), // ✅ sube 1px para que NO se corte abajo
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          return Container(
            width: 5,
            height: 5,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha:ops[i]),
            ),
          );
        }),
      ),
    );
  }
}

/// Estilos por métrica
class _MetricStyle {
  final Color iconColor;
  final Color pillBg;
  final Color pillFg;
  final Color dotColor;

  const _MetricStyle({
    required this.iconColor,
    required this.pillBg,
    required this.pillFg,
    required this.dotColor,
  });

  static _MetricStyle from({required String title, required String status}) {
    final t = title.toLowerCase();
    final s = status.toLowerCase();

    final isGood = s.contains('ópt') || s.contains('opt');
    final isLow = s.contains('baj');
    final isHigh = s.contains('alt');

    final pillBg = isGood
        ? const Color(0xFFDFF3E2)
        : (isLow || isHigh)
            ? const Color(0xFFF6E3B4)
            : Colors.white.withValues(alpha:0.65);

    final pillFg = isGood
        ? const Color(0xFF2E7D32)
        : (isLow || isHigh)
            ? const Color(0xFF7A5A00)
            : Colors.black.withValues(alpha:0.60);

    // ✅ dots siguen el “tono” del estado (visual)
    final dotColor = isGood
        ? const Color(0xFF2E7D32)
        : (isLow || isHigh)
            ? const Color(0xFF7A5A00)
            : Colors.black.withValues(alpha:0.35);

    Color iconColor = Colors.black87;
    if (t.contains('humedad')) iconColor = const Color(0xFF00B8D4);
    if (t.contains('temper')) iconColor = const Color(0xFFF2C94C);
    if (t == 'ph' || t.contains('ph')) iconColor = const Color(0xFF8EC9D7);
    if (t.contains('resist')) iconColor = const Color(0xFF6BBF59);

    return _MetricStyle(
      iconColor: iconColor,
      pillBg: pillBg,
      pillFg: pillFg,
      dotColor: dotColor,
    );
  }
}
