import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Renders environment assets without letting a missing PNG break the card.
///
/// Missing paths are logged only once in debug mode.
class EnvironmentAssetIcon extends StatelessWidget {
  static final Set<String> _reportedMissingAssets = <String>{};

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Widget? fallback;

  const EnvironmentAssetIcon({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.high,
    this.color,
    this.colorBlendMode,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      color: color,
      colorBlendMode: colorBlendMode,
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode && _reportedMissingAssets.add(assetPath)) {
          debugPrint(
            '[BioG/EnvironmentAssets] missing asset=$assetPath error=$error',
          );
        }
        return fallback ??
            Icon(
              Icons.cloud_outlined,
              size: _fallbackSize,
              color: Colors.black.withValues(alpha: 0.45),
            );
      },
    );
  }

  double get _fallbackSize {
    final sizes = <double>[];
    if (width != null) sizes.add(width!);
    if (height != null) sizes.add(height!);
    if (sizes.isEmpty) return 18;
    sizes.sort();
    return sizes.first;
  }
}
