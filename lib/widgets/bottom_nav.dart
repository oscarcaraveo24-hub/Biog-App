import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BioGBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const BioGBottomNav({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  static const String _kNavHistory = 'assets/icons/metrics/nav_history.png';
  static const String _kNavAccount = 'assets/icons/metrics/nav_account.png';
  static const String _kNavSeeds = 'assets/icons/metrics/nav_seeds.png';
  static const String _kNavEnvironment = 'assets/icons/metrics/nav_environment.png';
  static const String _kNavPower = 'assets/icons/metrics/nav_power.png';

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewPadding.bottom;

    const double navHeight = 110;

    const double ctaDiameter = 72;
    const double ringThickness = 7;
    const double ctaOuter = ctaDiameter + ringThickness * 2;
    const double ctaInner = ctaDiameter;
    const double ctaLift = 18;

    const double edgeLift = 10;
    const double waveDepth = 22;

    final double notchRadius = (ctaDiameter / 2) + ringThickness + 10;
    final totalHeight = navHeight + bottomInset;

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // ================= NAV BAR =================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipPath(
                  clipper: _BioGWaveNotchClipper(
                    waveDepth: waveDepth,
                    edgeLift: edgeLift,
                    notchRadius: notchRadius,
                  ),
                  child: Container(
                    height: totalHeight,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.55, 1.0],
                        colors: [
                          
  Color.fromARGB(185, 64, 187, 95),
  Color.fromARGB(255, 63, 175, 110),
  Color(0xFF2B7E65),


                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        8,
                        18,
                        10 + bottomInset,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _NavItem(
                              iconPath: _kNavHistory,
                              label: 'Historial',
                              active: currentIndex == 0,
                              onTap: onTap == null ? null : () => onTap!(0),
                            ),
                          ),
                          Expanded(
                            child: _NavItem(
                              iconPath: _kNavAccount,
                              label: 'Cuenta',
                              active: currentIndex == 1,
                              onTap: onTap == null ? null : () => onTap!(1),
                            ),
                          ),
                          const SizedBox(width: ctaOuter),
                          Expanded(
                            child: _NavItem(
                              iconPath: _kNavSeeds,
                              label: 'Semillas',
                              active: currentIndex == 2,
                              onTap: onTap == null ? null : () => onTap!(2),
                            ),
                          ),
                          Expanded(
                            child: _NavItem(
                              iconPath: _kNavEnvironment,
                              label: 'Entorno',
                              active: currentIndex == 3,
                              onTap: onTap == null ? null : () => onTap!(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ================= CENTER CTA =================
            Positioned(
              bottom: bottomInset + ctaLift,
              child: _CenterCTATapTarget(
                size: ctaOuter + 30,
                onTap: onTap == null ? null : () => onTap!(4),
                child: _CenterCTA(
                  outerSize: ctaOuter,
                  innerSize: ctaInner,
                  ringThickness: ringThickness,
                  iconPath: _kNavPower,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String iconPath;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.iconPath,
    required this.label,
    required this.active,
    this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  static const double _kIconVisualSize = 96;
  static const double _kCrop = 0.44;
  static const double _kYOffset = -8;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _scaleCtrl.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _scaleCtrl.reverse();
  }

  void _handleTapCancel() {
    _scaleCtrl.reverse();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: widget.active ? 1.0 : 0.92);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : _handleTapDown,
      onTapUp: widget.onTap == null ? null : _handleTapUp,
      onTapCancel: widget.onTap == null ? null : _handleTapCancel,
      onTap: widget.onTap == null ? null : _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Transform.translate(
          offset: const Offset(0, _kYOffset),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  widthFactor: _kCrop,
                  heightFactor: _kCrop,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    child: Image.asset(
                      widget.iconPath,
                      width: _kIconVisualSize,
                      height: _kIconVisualSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  height: 1.0,
                  fontWeight: widget.active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterCTATapTarget extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final Widget child;

  const _CenterCTATapTarget({
    required this.size,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onTap!();
            },
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}


class _CenterCTA extends StatelessWidget {
  final double outerSize;
  final double innerSize;
  final double ringThickness;
  final String iconPath;

  const _CenterCTA({
    required this.outerSize,
    required this.innerSize,
    required this.ringThickness,
    required this.iconPath,
  });

  static const double _kCtaIconSize = 30;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🔥 Glow verde suave
          Container(
            width: outerSize + 18,
            height: outerSize + 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2F8D76).withValues(alpha:0.25),
            ),
          ),

          // 🔥 Halo blanco sutil
          Container(
            width: outerSize,
            height: outerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha:0.95),
                width: ringThickness,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.20),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
          ),

          // Botón interno
          Container(
            width: innerSize,
            height: innerSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
               colors: [
  Color.fromARGB(255, 69, 202, 102), // más luminoso pero no neón
  Color.fromARGB(255, 47, 141, 94), // mantiene el bosque
],

              ),
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: _kCtaIconSize,
                height: _kCtaIconSize,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BioGWaveNotchClipper extends CustomClipper<Path> {
  final double waveDepth;
  final double edgeLift;
  final double notchRadius;

  const _BioGWaveNotchClipper({
    required this.waveDepth,
    required this.edgeLift,
    required this.notchRadius,
  });

  @override
  Path getClip(Size size) {
    final W = size.width;
    final H = size.height;
    final cx = W / 2;

    final edgeY = 0.0;
    final midY = waveDepth + edgeLift;

    final bar = Path()
      ..moveTo(0, edgeY)
      ..lineTo(W * 0.45, midY)
      ..lineTo(W * 0.55, midY)
      ..lineTo(W, edgeY)
      ..lineTo(W, H)
      ..lineTo(0, H)
      ..close();

    final hole = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(cx, midY - 2),
          radius: notchRadius,
        ),
      );

    return Path.combine(PathOperation.difference, bar, hole);
  }

  @override
  bool shouldReclip(covariant _BioGWaveNotchClipper old) =>
      old.waveDepth != waveDepth ||
      old.edgeLift != edgeLift ||
      old.notchRadius != notchRadius;
}
