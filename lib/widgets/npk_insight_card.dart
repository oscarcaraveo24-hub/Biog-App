import 'dart:ui';
import 'package:flutter/material.dart';

/// Chip de tendencia de un canal nativo para la tarjeta de nutrición.
///
/// `direction`: 1 al alza, 0 estable, -1 a la baja. La tarjeta no interpreta
/// nada: recibe el vocabulario ya decidido por el motor de nutrición.
class NpkTrendChipData {
  const NpkTrendChipData({
    required this.label,
    required this.direction,
  });

  final String label;
  final int direction;
}

/// Tono con el que se pinta la etiqueta de estado de la tarjeta.
enum NpkTagTone { neutral, action, response, attended, warning, learning }

class NpkInsightCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String assetIcon;
  final VoidCallback? onTap;

  /// Etiqueta corta del estado nutricional («Ventana», «Respuesta»…). Vacía
  /// cuando no hay decisión del motor.
  final String tag;
  final NpkTagTone tagTone;

  /// Tendencia de N, P y K (en ese orden), o vacío cuando no hay lecturas.
  final List<NpkTrendChipData> trends;

  const NpkInsightCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.assetIcon,
    this.onTap,
    this.tag = '',
    this.tagTone = NpkTagTone.neutral,
    this.trends = const <NpkTrendChipData>[],
  });

  @override
  State<NpkInsightCard> createState() => _NpkInsightCardState();
}

class _NpkInsightCardState extends State<NpkInsightCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  Color get _tagColor => switch (widget.tagTone) {
    NpkTagTone.neutral => const Color(0xFF5B6470),
    NpkTagTone.action => const Color(0xFFB9761A),
    NpkTagTone.response => const Color(0xFF1F7FA8),
    NpkTagTone.attended => const Color(0xFF2E7D5A),
    NpkTagTone.warning => const Color(0xFFB4433A),
    NpkTagTone.learning => const Color(0xFF4C63B6),
  };

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    final scale = _pressed ? 1.02 : 1.0;
    final opacity = _pressed ? 0.96 : 1.0;
    final Color tagColor = _tagColor;

    final shell = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
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
                color: const Color(0xFF00BCD4).withValues(alpha: 0.08),
                blurRadius: 110,
                spreadRadius: 0,
                offset: const Offset(0, 56),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFF0F2F5).withValues(alpha: 0.94),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.96),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: Transform.scale(
                          scale: 2.8,
                          child: Image.asset(
                            widget.assetIcon,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.eco, size: 26),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  widget.title,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    height: 1.12,
                                  ),
                                ),
                              ),
                              if (widget.tag.trim().isNotEmpty) ...<Widget>[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tagColor.withValues(alpha: 0.11),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    widget.tag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: tagColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle,
                            // Dos líneas: la primera frase de la decisión del
                            // motor de nutrición —la dosis orientativa
                            // («N: 107–161 kg/ha (≈ 235–350 kg/ha de
                            // urea)»)— debe leerse completa.
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withValues(alpha: 0.58),
                              height: 1.2,
                            ),
                          ),
                          if (widget.trends.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: <Widget>[
                                for (final NpkTrendChipData t in widget.trends)
                                  _TrendChip(data: t),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Colors.black.withValues(alpha: 0.32),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!enabled) return shell;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: shell,
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.data});

  final NpkTrendChipData data;

  @override
  Widget build(BuildContext context) {
    // Al alza y a la baja se pintan con un acento discreto (no alarman: una
    // tendencia no es un diagnóstico); estable queda en gris.
    final Color color = switch (data.direction) {
      > 0 => const Color(0xFF1F7FA8),
      < 0 => const Color(0xFFB9761A),
      _ => const Color(0xFF5B6470),
    };
    final IconData icon = switch (data.direction) {
      > 0 => Icons.north_east_rounded,
      < 0 => Icons.south_east_rounded,
      _ => Icons.horizontal_rule_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
