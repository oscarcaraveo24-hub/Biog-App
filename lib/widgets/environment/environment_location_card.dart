import 'package:flutter/material.dart';
import 'package:bio_g/widgets/environment/environment_asset_icon.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

class EnvironmentLocationCard extends StatelessWidget {
  final String fieldLabel;
  final String zoneLabel;
  final String updatedLabel;

  final double leafIconScale;
  final double locationIconScale;

  const EnvironmentLocationCard({
    super.key,
    required this.fieldLabel,
    required this.zoneLabel,
    required this.updatedLabel,
    this.leafIconScale = 0.85,
    this.locationIconScale = 1.35,
  });

  static const Color _kBrandGreen = Color(0xFF3FAF6E);

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RowLine(
            icon: _AssetIcon(
              path: 'assets/icons/metrics/nav_power.png',
              scale: leafIconScale,
              size: 18,
              tint: _kBrandGreen,
            ),
            label: 'Campo:',
            value: fieldLabel,
          ),
          const SizedBox(height: 6),
          _RowLine(
            icon: _AssetIcon(
              path: 'assets/icons/metrics/ic_location.png',
              scale: locationIconScale,
              size: 18,
              tint: null,
            ),
            label: 'Zona:',
            value: zoneLabel,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3FAF6E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3FAF6E).withValues(alpha:0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  updatedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha:0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowLine extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;

  const _RowLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  static const Color _kInk = Color(0xFF0E1A16);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 22, height: 22, child: Center(child: icon)),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: _kInk.withValues(alpha:0.92),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Colors.black.withValues(alpha:0.55),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssetIcon extends StatelessWidget {
  final String path;
  final double scale;
  final double size;
  final Color? tint;

  const _AssetIcon({
    required this.path,
    this.scale = 1.0,
    this.size = 18,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final img = EnvironmentAssetIcon(
      assetPath: path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (tint == null) return Transform.scale(scale: scale, child: img);

    return Transform.scale(
      scale: scale,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(tint!, BlendMode.srcIn),
        child: img,
      ),
    );
  }
}
