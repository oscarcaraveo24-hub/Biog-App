import 'package:flutter/material.dart';

import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_components.dart';
import 'package:bio_g/widgets/shared/bio_g_button.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

Future<void> showWizardAnimatedDialog({
  required BuildContext context,
  required String barrierLabel,
  required String title,
  required String message,
  required String iconAssetPath,
  required String actionLabel,
  Color? iconTint,
  double iconBaseScale = 1.18,
  double barrierOpacity = 0.34,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: Colors.black.withValues(alpha: barrierOpacity),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return WizardAnimatedDialog(
        title: title,
        message: message,
        iconAssetPath: iconAssetPath,
        iconTint: iconTint,
        actionLabel: actionLabel,
        iconBaseScale: iconBaseScale,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      final scale = Tween<double>(
        begin: 0.90,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}

Future<T?> showWizardSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<WizardSheetOption<T>> options,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final media = MediaQuery.of(context);
      final maxSheetHeight = media.size.height * 0.58;

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: BioGGlassCard(
            radius: 28,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            backgroundColor: const Color(0xFFF3F6F4).withValues(alpha: 0.97),
            boxShadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 26,
                spreadRadius: 0,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 48,
                spreadRadius: 0,
                offset: const Offset(0, 22),
              ),
            ],
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Selecciona',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.35,
                      color: Color(0xFF7C8A86),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: Color(0xFF213431),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: Scrollbar(
                      thumbVisibility: options.length > 5,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return StaggerIn(
                            delay: 40 + (index * 45),
                            child: WizardSheetSelectionTile<T>(
                              option: option,
                              onTap: option.enabled
                                  ? () =>
                                        Navigator.of(context).pop(option.value)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class WizardAnimatedDialog extends StatefulWidget {
  const WizardAnimatedDialog({
    super.key,
    required this.title,
    required this.message,
    required this.iconAssetPath,
    required this.actionLabel,
    this.iconTint,
    this.iconBaseScale = 1.18,
  });

  final String title;
  final String message;
  final String iconAssetPath;
  final String actionLabel;
  final Color? iconTint;
  final double iconBaseScale;

  @override
  State<WizardAnimatedDialog> createState() => _WizardAnimatedDialogState();
}

class _WizardAnimatedDialogState extends State<WizardAnimatedDialog>
    with TickerProviderStateMixin {
  late final AnimationController _dialogC;
  late final Animation<double> _dialogFade;
  late final Animation<double> _dialogScale;

  late final AnimationController _iconC;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();

    _dialogC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _dialogFade = CurvedAnimation(parent: _dialogC, curve: Curves.easeOutCubic);

    _dialogScale = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _dialogC, curve: Curves.easeOutCubic));

    _iconC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.12,
          end: 0.98,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.98,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
    ]).animate(_iconC);

    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      _dialogC.forward();
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _iconC.forward();
    });
  }

  @override
  void dispose() {
    _dialogC.dispose();
    _iconC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _dialogFade,
            child: ScaleTransition(
              scale: _dialogScale,
              child: Material(
                color: Colors.transparent,
                child: BioGGlassCard(
                  radius: 28,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _iconC,
                        builder: (context, _) {
                          return Opacity(
                            opacity: (_iconC.value == 0) ? 0.0 : 1.0,
                            child: Transform.scale(
                              scale: _iconScale.value * widget.iconBaseScale,
                              child: Image.asset(
                                widget.iconAssetPath,
                                width: 54,
                                height: 54,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                color: widget.iconTint,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: Color(0xFF213431),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.8,
                          height: 1.38,
                          color: Colors.black.withValues(alpha: 0.60),
                        ),
                      ),
                      const SizedBox(height: 16),
                      BioGButton(
                        label: widget.actionLabel,
                        height: 48,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
