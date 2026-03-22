import 'package:flutter/material.dart';

class OnboardingPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final double height;

  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.height = 62,
  });

  bool get _isEnabled => enabled && !loading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = _isEnabled;
    const BorderRadius radius = BorderRadius.all(Radius.circular(24));

    const Color brandTop = Color(0xFF40BB5F);
    const Color brandMid = Color(0xFF3FAF6E);
    const Color brandDeep = Color(0xFF0E6F5E);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isEnabled ? 1 : 0.62,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: brandTop.withValues(alpha:0.22),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha:0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isEnabled
                  ? const <Color>[brandTop, brandMid, brandDeep]
                  : const <Color>[
                      Color(0xFFB7DCC1),
                      Color(0xFFAFD3C3),
                      Color(0xFF98B8B2),
                    ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha:0.22)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: isEnabled ? onPressed : null,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.white.withValues(alpha:0.14),
                              Colors.white.withValues(alpha:0.00),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: loading
                          ? const SizedBox(
                              key: ValueKey<String>('loading'),
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              label,
                              key: const ValueKey<String>('label'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.25,
                                shadows: <Shadow>[
                                  Shadow(
                                    color: Color(0x33000000),
                                    blurRadius: 12,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
