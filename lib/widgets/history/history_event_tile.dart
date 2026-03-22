import 'package:flutter/material.dart';

class HistoryEventTile extends StatelessWidget {
  final String? assetIcon;
  final IconData? icon;
  final Color iconBg;

  final String title;
  final String timeRight;
  final bool isAlert;
  final bool subtleDots;

  const HistoryEventTile({
    super.key,
    this.assetIcon,
    this.icon,
    required this.iconBg,
    required this.title,
    required this.timeRight,
    this.isAlert = false,
    this.subtleDots = false,
  });

  // ✅ RUTAS CORRECTAS

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ Slot fijo (no infla el card)
              SizedBox(
                width: 34,
                height: 34,
                child: Center(
                  child: OverflowBox(
                    maxWidth: 90,
                    maxHeight: 90,
                    child: Transform.scale(
                      scale: 2.6, // 👈 aquí controlas tamaño real
                      child: _EventIconBase(
                        assetIcon: assetIcon,
                        icon: icon,
                        isAlert: isAlert,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (subtleDots) const _MiniDots(),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Text(
                timeRight,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventIconBase extends StatelessWidget {
  final String? assetIcon;
  final IconData? icon;
  final bool isAlert;

  const _EventIconBase({
    required this.assetIcon,
    required this.icon,
    required this.isAlert,
  });

  static const String _kAlertIcon = 'assets/icons/metrics/ic_alert.png';

  @override
  Widget build(BuildContext context) {
    final String? effectiveAsset = isAlert ? _kAlertIcon : assetIcon;

    const double base = 22;

    if (effectiveAsset != null) {
      return Image.asset(
        effectiveAsset,
        width: base,
        height: base,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) =>
            Icon(icon ?? Icons.circle, size: base, color: _fallbackColor()),
      );
    }

    return Icon(icon ?? Icons.circle, size: base, color: _fallbackColor());
  }

  Color _fallbackColor() {
    return isAlert ? Colors.orange : const Color(0xFF3E9F86);
  }
}

class _MiniDots extends StatelessWidget {
  const _MiniDots();

  @override
  Widget build(BuildContext context) {
    Widget dot(double o) => Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha:o),
        shape: BoxShape.circle,
      ),
    );

    return Row(
      children: [dot(0.25), dot(0.40), dot(0.55), dot(0.70), dot(0.85)],
    );
  }
}
