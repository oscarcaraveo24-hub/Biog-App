import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bio_g/screens/auth/auth_screen.dart';
import 'package:bio_g/widgets/onboarding/floating_particles.dart';
import 'package:bio_g/widgets/onboarding/onboarding_asset_badge.dart';
import 'package:bio_g/widgets/onboarding/onboarding_background.dart';
import 'package:bio_g/widgets/onboarding/onboarding_primary_button.dart';
import 'package:bio_g/widgets/shared/bio_g_page_route.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback? onStart;
  final VoidCallback? onSignIn;

  const WelcomeScreen({super.key, this.onStart, this.onSignIn});

  void _openSignUp(BuildContext context) {
    if (onStart != null) {
      onStart!();
      return;
    }

    Navigator.of(context).push(
      BioGPageRoute<void>(
        builder: (_) => const AuthScreen(initialMode: AuthMode.signUp),
      ),
    );
  }

  void _openSignIn(BuildContext context) {
    if (onSignIn != null) {
      onSignIn!();
      return;
    }

    Navigator.of(context).push(
      BioGPageRoute<void>(
        builder: (_) => const AuthScreen(initialMode: AuthMode.signIn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OnboardingBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double logoHeight = constraints.maxWidth < 380 ? 180 : 248;

            return Stack(
              children: <Widget>[
                const _WelcomeLandscape(),
                const Positioned.fill(child: FloatingParticles()),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const SizedBox(height: 40),
                            Transform.translate(
                              offset: const Offset(0, 50),
                              child: Center(
                                child: Image.asset(
                                  OnboardingUiAssets.logo,
                                  height: logoHeight,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const _PremiumTagline(),
                            const SizedBox(height: 36),
                            _WelcomeActions(
                              onStart: () => _openSignUp(context),
                              onSignIn: () => _openSignIn(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Premium tagline with staggered line-by-line fade + slide ───

class _PremiumTagline extends StatefulWidget {
  const _PremiumTagline();

  @override
  State<_PremiumTagline> createState() => _PremiumTaglineState();
}

class _PremiumTaglineState extends State<_PremiumTagline>
    with TickerProviderStateMixin {
  late final AnimationController _line1Controller;
  late final AnimationController _line2Controller;
  late final Animation<double> _line1Fade;
  late final Animation<Offset> _line1Slide;
  late final Animation<double> _line2Fade;
  late final Animation<Offset> _line2Slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _line1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _line2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _line1Fade = CurvedAnimation(
      parent: _line1Controller,
      curve: Curves.easeOutQuart,
    );
    _line1Slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _line1Controller, curve: Curves.easeOutQuart),
        );

    _line2Fade = CurvedAnimation(
      parent: _line2Controller,
      curve: Curves.easeOutQuart,
    );
    _line2Slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _line2Controller, curve: Curves.easeOutQuart),
        );

    // Stagger: line 1 first, line 2 after 280ms
    _line1Controller.forward();
    _timer = Timer(const Duration(milliseconds: 280), () {
      if (mounted) _line2Controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _line1Controller.dispose();
    _line2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FadeTransition(
          opacity: _line1Fade,
          child: SlideTransition(
            position: _line1Slide,
            child: const Text(
              'No solo se mide la tierra.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'InterDisplay',
                fontSize: 27,
                height: 1.22,
                fontWeight: FontWeight.w200,
                color: Color(0xFF3A4A52),
                letterSpacing: -0.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        FadeTransition(
          opacity: _line2Fade,
          child: SlideTransition(
            position: _line2Slide,
            child: const Text(
              'Se aprende de ella.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'InterDisplay',
                fontSize: 27,
                height: 1.22,
                fontWeight: FontWeight.w400,
                color: Color(0xFF2B3E36),
                letterSpacing: -0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Floating button + sign-in link with slide-from-left fade ───

class _WelcomeActions extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback onSignIn;

  const _WelcomeActions({required this.onStart, required this.onSignIn});

  @override
  State<_WelcomeActions> createState() => _WelcomeActionsState();
}

class _WelcomeActionsState extends State<_WelcomeActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    // Delay after tagline finishes
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF40BB5F).withAlpha(56),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: OnboardingPrimaryButton(
                  label: 'Comenzar',
                  onPressed: widget.onStart,
                  height: 64,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  const Text(
                    '¿Ya tienes cuenta?',
                    style: TextStyle(fontSize: 16, color: Color(0xFF6D757A)),
                  ),
                  TextButton(
                    onPressed: widget.onSignIn,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0E6F5E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeLandscape extends StatelessWidget {
  const _WelcomeLandscape();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: -8,
      child: IgnorePointer(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.42,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                OnboardingUiAssets.landscape,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      const Color(0xFFF7FBFD),
                      const Color(0x42FFFFFF),
                      const Color(0x0DFFFFFF),
                    ],
                    stops: const <double>[0.0, 0.28, 1.0],
                  ),
                ),
              ),
              CustomPaint(
                painter: _WelcomeLinesPainter(color: const Color(0x57FFFFFF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeLinesPainter extends CustomPainter {
  final Color color;

  const _WelcomeLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = color;

    final List<double> rows = <double>[
      size.height * 0.20,
      size.height * 0.42,
      size.height * 0.63,
      size.height * 0.82,
    ];

    for (final double y in rows) {
      final Path path = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * 0.16,
          y - 26,
          size.width * 0.34,
          y + 22,
          size.width * 0.56,
          y - 4,
        )
        ..cubicTo(
          size.width * 0.74,
          y - 22,
          size.width * 0.88,
          y + 20,
          size.width,
          y - 10,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WelcomeLinesPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
