import 'package:flutter/material.dart';

enum BioGButtonVariant { primary, secondary, ghost }

class BioGButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  /// PNG (recomendado). Ej: 'assets/icons/metrics/ic_plus.png'
  final String? leadingIconAsset;

  /// Legacy: IconData opcional
  final IconData? leadingIcon;

  final BioGButtonVariant variant;

  final double height; // default 44
  final double radius; // default 18
  final EdgeInsetsGeometry padding; // default horizontal 16
  final bool fullWidth;

  final bool loading;

  /// ✅ Shadow en el texto (especialmente útil en primary)
  final bool labelShadow;

  const BioGButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leadingIconAsset,
    this.leadingIcon,
    this.variant = BioGButtonVariant.primary,
    this.height = 44,
    this.radius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.fullWidth = true,
    this.loading = false,
    this.labelShadow = true,
  });

  bool get _enabled => onTap != null && !loading;

  @override
  State<BioGButton> createState() => _BioGButtonState();
}

class _BioGButtonState extends State<BioGButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget._enabled;

    final borderRadius = BorderRadius.circular(widget.radius);
    final width = widget.fullWidth ? double.infinity : null;

    final isPrimary = widget.variant == BioGButtonVariant.primary;
    final isSecondary = widget.variant == BioGButtonVariant.secondary;
    final isGhost = widget.variant == BioGButtonVariant.ghost;

    // ===========================
    // ✅ PALETA OFICIAL (match Nav/Pills)
    // ===========================
    const brandTop = Color(0xFF40BB5F);
    const brandMid = Color(0xFF3FAF6E);
    const brandBaseA = Color.fromARGB(137, 43, 126, 101);

    const deep = Color(0xFF0E6F5E);

    // ====== Sombra premium (afuera, NO clip)
    final boxShadow = isGhost
        ? <BoxShadow>[]
        : [
            // glow verde sutil (marca)
            if (isPrimary && enabled)
              BoxShadow(
                color: brandTop.withValues(alpha:0.18),
                blurRadius: 22,
                offset: const Offset(0, 12),
                spreadRadius: 0,
              ),

            // profundidad principal
            BoxShadow(
              color: Colors.black.withValues(alpha:enabled ? 0.08 : 0.04),
              blurRadius: enabled ? 24 : 18,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ];

    // ====== Animación press
    final scale = (enabled && _pressed) ? 0.985 : 1.0;
    final overlayOpacity = (enabled && _pressed) ? 0.04 : 0.0;

    // ====== Background por variante
    final Decoration bg = () {
      if (isPrimary) {
        return BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled
                ? const [brandTop, brandMid, brandBaseA]
                : [
                    brandTop.withValues(alpha:0.14),
                    brandMid.withValues(alpha:0.14),
                    brandBaseA.withValues(alpha:0.14),
                  ],
          ),
        );
      }

      if (isSecondary) {
        return BoxDecoration(
          borderRadius: borderRadius,
          color: enabled
              ? Colors.white.withValues(alpha:0.78)
              : Colors.white.withValues(alpha:0.62),
          border: Border.all(
            color: enabled ? brandMid.withValues(alpha:0.18) : Colors.black.withValues(alpha:0.08),
            width: 1,
          ),
        );
      }

      // Ghost
      return BoxDecoration(
        borderRadius: borderRadius,
        color: Colors.transparent,
        border: Border.all(
          color: enabled ? brandMid.withValues(alpha:0.35) : Colors.black.withValues(alpha:0.08),
          width: 1,
        ),
      );
    }();

    // ====== Color de texto
    final Color labelColor = () {
      if (!enabled) return Colors.black.withValues(alpha:0.38);
      if (isPrimary) return Colors.white;
      return deep;
    }();

    // ✅ Shadow SOLO para primary (blanco) y solo si labelShadow = true
    final List<Shadow> labelShadows =
        (widget.labelShadow && isPrimary && enabled)
            ? [
                Shadow(
                  color: Colors.black.withValues(alpha:0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
                Shadow(
                  color: Colors.black.withValues(alpha:0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [];

    // ====== Leading
    Widget? leading;
    if (!widget.loading) {
      if (widget.leadingIconAsset != null) {
        leading = Image.asset(
          widget.leadingIconAsset!,
          height: 18,
          width: 18,
          fit: BoxFit.contain,
        );
      } else if (widget.leadingIcon != null) {
        leading = Icon(widget.leadingIcon, size: 18, color: labelColor);
      }
    }

    final spinner = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        valueColor: AlwaysStoppedAnimation<Color>(isPrimary ? Colors.white : deep),
      ),
    );

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        width: width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: boxShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: enabled ? widget.onTap : null,
            onHighlightChanged: _setPressed,
            borderRadius: borderRadius,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: bg,
              child: ClipRRect(
                borderRadius: borderRadius,
                child: Stack(
                  children: [
                    // ✅ “Blanqueado” sutil (sube/baja 0.04–0.08)
                    if (isPrimary) Container(color: Colors.white.withValues(alpha:0.06)),

                    // Overlay sutil al presionar
                    AnimatedOpacity(
                      opacity: overlayOpacity,
                      duration: const Duration(milliseconds: 120),
                      child: Container(color: Colors.black),
                    ),

                    // ✅ Centrado vertical REAL
                    Center(
                      child: Padding(
                        padding: widget.padding,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (leading != null) ...[
                              leading,
                              const SizedBox(width: 10),
                            ],
                            Flexible(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 160),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeOut,
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                                child: widget.loading
                                    ? spinner
                                    : Text(
                                        widget.label,
                                        key: ValueKey(widget.label),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: labelColor,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                          height: 1.0,
                                          shadows: labelShadows,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
