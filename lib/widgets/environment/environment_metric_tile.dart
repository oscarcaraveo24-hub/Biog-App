import 'package:flutter/material.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

class EnvironmentMetricTile extends StatelessWidget {
  final String title;
  final String value;

  final String chip;
  final Color chipColor;

  final String footer;

  // Icon options
  final String? assetPath;
  final IconData? icon;

  /// Scale del icon (PNG o material icon)
  final double iconScale;

  /// ✅ Para micro-ajustar solo el icon (como lo estabas usando)
  final double iconYOffset;

  /// ✅ Para micro-ajustar el padding interno por tile
  final EdgeInsets contentPadding;

  const EnvironmentMetricTile({
    super.key,
    required this.title,
    required this.value,
    required this.chip,
    required this.chipColor,
    required this.footer,
    this.assetPath,
    this.icon,
    this.iconScale = 1.0,
    this.iconYOffset = 5.0,
    this.contentPadding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
  }) : assert(
         assetPath != null || icon != null,
         'Debes pasar assetPath o icon',
       );

  static const Color _kInk = Color(0xFF0E1A16);

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      radius: 22,
      // ✅ usa tu BioGGlassCard (más blanco por default)
      // si quisieras todavía más blanco: backgroundColor: Colors.white.withValues(alpha:0.88),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= TOP (DASHBOARD-LIKE) =================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: Offset(0, iconYOffset),
                  child: _IconBox(
                    assetPath: assetPath,
                    icon: icon,
                    scale: iconScale,
                  ),
                ),
                const SizedBox(width: 10),

                // ✅ todo el contenido a la derecha del icon
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: _kInk.withValues(alpha:0.92),
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _kInk,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ================= CHIP =================
            _ChipPill(text: chip, color: chipColor),

            const Spacer(),

            // ================= FOOTER =================
            Text(
              footer,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha:0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final String? assetPath;
  final IconData? icon;
  final double scale;

  const _IconBox({
    required this.assetPath,
    required this.icon,
    required this.scale,
  });

  static const double _box = 30;

  @override
  Widget build(BuildContext context) {
    Widget child;

    // ✅ PNG sin tint (para que no se “pinte”)
    if (assetPath != null && assetPath!.trim().isNotEmpty) {
      child = Transform.scale(
        scale: scale,
        child: Image.asset(
          assetPath!,
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      );
    } else {
      child = Transform.scale(
        scale: scale,
        child: Icon(icon, size: 22, color: Colors.black.withValues(alpha:0.70)),
      );
    }

    return SizedBox(
      width: _box,
      height: _box,
      child: Center(child: child),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final String text;
  final Color color;

  const _ChipPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha:0.70)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          height: 1.0,
          fontWeight: FontWeight.w900,
          color: Colors.black.withValues(alpha:0.62),
        ),
      ),
    );
  }
}
