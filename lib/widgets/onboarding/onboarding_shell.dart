import 'package:flutter/material.dart';

import 'package:bio_g/widgets/onboarding/onboarding_background.dart';

class OnboardingShell extends StatelessWidget {
  final Widget child;
  final Widget? bottomAction;
  final EdgeInsetsGeometry contentPadding;
  final bool scrollable;
  final bool resizeToAvoidBottomInset;
  final CrossAxisAlignment crossAxisAlignment;

  const OnboardingShell({
    super.key,
    required this.child,
    this.bottomAction,
    this.contentPadding = const EdgeInsets.fromLTRB(24, 18, 24, 24),
    this.scrollable = true,
    this.resizeToAvoidBottomInset = true,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    Widget content = Padding(
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: <Widget>[
          child,
          const SizedBox(height: 24),
        ],
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? 12 : 0),
        child: content,
      );
    }

    final Widget body = SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(child: content),
          if (bottomAction != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                20 + MediaQuery.of(context).padding.bottom * 0.25,
              ),
              child: bottomAction,
            ),
        ],
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: Colors.transparent,
      body: OnboardingBackground(child: body),
    );
  }
}
