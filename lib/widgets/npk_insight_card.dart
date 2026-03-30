import 'dart:ui';
import 'package:flutter/material.dart';

class NpkInsightCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String assetIcon;
  final VoidCallback? onTap;

  const NpkInsightCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.assetIcon,
    this.onTap,
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

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    final scale = _pressed ? 1.02 : 1.0;
    final opacity = _pressed ? 0.96 : 1.0;

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
                ), // Un poquito más de aire vertical
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
                            errorBuilder: (_, __, ___) =>
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
                          Text(
                            widget.title,
                            maxLines: 1,
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
                            widget.subtitle,
                            // ✅ FIX: Le permitimos 2 líneas para que la recomendación en kg/ha se lea completa
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withValues(alpha: 0.58),
                              height: 1.2, // Mejor interlineado para 2 líneas
                            ),
                          ),
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
