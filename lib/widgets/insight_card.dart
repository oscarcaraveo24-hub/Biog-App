import 'dart:ui';
import 'package:flutter/material.dart';

class InsightCard extends StatelessWidget {
  /// ✅ PNG opcional (recomendado)
  /// Ej: 'assets/icons/metrics/ic_riego.png'
  final String? assetIcon;

  /// ✅ Fallback material icon
  final IconData? icon;

  /// ✅ Slot reservado (no infla el card)
  final double iconSlot;

  /// ✅ Escala visual (2.5x tipo Apple)
  final double iconScale;

  final String title;
  final String subtitle;

  /// Ej: "24h", "Alta", "Hoy"
  final String? tag;

  /// Color de acento (agua=teal, alerta=amarillo, riesgo=rojo)
  final Color accent;

  final VoidCallback? onTap;

  const InsightCard({
    super.key,
    this.assetIcon,
    this.icon,
    this.iconSlot = 34,     // 👈 slot compacto (no cambia altura)
    this.iconScale = 2.5,   // 👈 “2.5x” real sin inflar layout
    required this.title,
    required this.subtitle,
    this.tag,
    this.accent = const Color(0xFF00B8D4),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shell = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.20),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha:0.12),
            blurRadius: 90,
            spreadRadius: 0,
            offset: const Offset(0, 52),
          ),
          BoxShadow(
            color: accent.withValues(alpha:0.10),
            blurRadius: 110,
            spreadRadius: 0,
            offset: const Offset(0, 64),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Container(
            // Emparejado con `NpkInsightCard`.
            //
            // Las dos tarjetas viven en el Panel una a cada lado del grid de
            // metricas y deben leerse como piezas del mismo sistema. El ancho
            // ya coincidia —las dos son hijas directas de la columna con
            // `stretch`—, pero el alto no: NPK usa `vertical: 12` y esta usaba
            // `vertical: 9`. Esos 6 px de menos se veian como una tarjeta mas
            // delgada.
            //
            // Con 12 las dos miden ~58 px con titulo y subtitulo de una linea.
            // Si tocas este valor, toca el de `npk_insight_card.dart` igual.
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFF0F2F5).withValues(alpha:0.94),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.96),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✅ Reglas “HistoryEventTile”: slot fijo + overflow + scale
                SizedBox(
                  width: iconSlot,
                  height: iconSlot,
                  child: Center(
                    child: OverflowBox(
                      minWidth: 0,
                      minHeight: 0,
                      maxWidth: 120,
                      maxHeight: 120,
                      child: Transform.translate(
                        offset: const Offset(0, 1), // micro ajuste visual
                        child: Transform.scale(
                          scale: iconScale, // 👈 aquí 2.5x
                          child: _InsightIconBase(
                            assetIcon: assetIcon,
                            icon: icon,
                            accent: accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha:0.58),
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),

                if (tag != null) ...[
                  const SizedBox(width: 10),
                  _TagChip(text: tag!, accent: accent),
                ],

                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.black.withValues(alpha:0.32),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return shell;
    return GestureDetector(onTap: onTap, child: shell);
  }
}

/// ✅ Icono base “normalizado”
/// Igual que en HistoryEventTile:
/// - base pequeño
/// - ClipRect + FittedBox(BoxFit.cover) recorta padding interno del PNG
class _InsightIconBase extends StatelessWidget {
  final String? assetIcon;
  final IconData? icon;
  final Color accent;

  const _InsightIconBase({
    required this.assetIcon,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const double base = 22; // base pequeño (el tamaño real lo da Transform.scale)

    if (assetIcon != null) {
      return SizedBox(
        width: base,
        height: base,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover, // ✅ recorta aire del PNG => se ve grande consistente
            alignment: Alignment.center,
            child: Image.asset(
              assetIcon!,
              width: base,
              height: base,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Icon(
                icon ?? Icons.circle,
                size: base,
                color: accent.withValues(alpha:0.98),
              ),
            ),
          ),
        ),
      );
    }

    return Icon(
      icon ?? Icons.circle,
      size: base,
      color: accent.withValues(alpha:0.98),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color accent;

  const _TagChip({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha:0.14),
        border: Border.all(color: accent.withValues(alpha:0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
          color: accent.withValues(alpha:0.98),
        ),
      ),
    );
  }
}
