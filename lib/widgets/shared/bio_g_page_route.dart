import 'package:flutter/material.dart';

/// Fade + slide-up page transition used across the app.
///
/// ```dart
/// Navigator.of(context).push(BioGPageRoute(builder: (_) => const MyScreen()));
/// ```
class BioGPageRoute<T> extends PageRouteBuilder<T> {
  BioGPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 340),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.22, 1.0, 0.36, 1.0),
              reverseCurve: const Cubic(0.36, 0.0, 0.66, -0.56),
            );

            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
