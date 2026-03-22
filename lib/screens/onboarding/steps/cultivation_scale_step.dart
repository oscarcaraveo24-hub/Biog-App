import 'package:flutter/material.dart';

import 'package:bio_g/widgets/onboarding/onboarding_asset_badge.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/widgets/onboarding/onboarding_header.dart';
import 'package:bio_g/widgets/onboarding/onboarding_primary_button.dart';
import 'package:bio_g/widgets/onboarding/onboarding_shell.dart';

class CultivationScaleStep extends StatelessWidget {
  final String? selectedScale;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onContinue;
  final bool showScaffold;
  final bool showContinueButton;

  const CultivationScaleStep({
    super.key,
    this.selectedScale,
    this.onChanged,
    this.onContinue,
    this.showScaffold = true,
    this.showContinueButton = true,
  });

  bool get _canContinue => selectedScale?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const OnboardingHeader(
          logoAsset: OnboardingUiAssets.logo,
          title: '¿Qué tipo de cultivo es?',
          subtitle:
              'Esto nos ayuda a entender la escala y manejo de tu cultivo.',
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _ScaleCard(
                title: 'Campo',
                assetPath: OnboardingUiAssets.assetForScale('field'),
                selected: selectedScale == 'field',
                onTap: () => onChanged?.call('field'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScaleCard(
                title: 'Huerto',
                assetPath: OnboardingUiAssets.assetForScale('orchard'),
                selected: selectedScale == 'orchard',
                onTap: () => onChanged?.call('orchard'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScaleCard(
                title: 'Maceta',
                assetPath: OnboardingUiAssets.assetForScale('pot'),
                selected: selectedScale == 'pot',
                onTap: () => onChanged?.call('pot'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Selecciona la opción que mejor describa cómo cultivas hoy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: Color(0xFF66747C),
            ),
          ),
        ),
      ],
    );

    if (!showScaffold) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          content,
          if (showContinueButton) ...<Widget>[
            const SizedBox(height: 28),
            OnboardingPrimaryButton(
              label: 'Continuar',
              onPressed: _canContinue ? onContinue : null,
              enabled: _canContinue,
            ),
          ],
        ],
      );
    }

    return OnboardingShell(
      bottomAction: showContinueButton
          ? OnboardingPrimaryButton(
              label: 'Continuar',
              onPressed: _canContinue ? onContinue : null,
              enabled: _canContinue,
            )
          : null,
      child: content,
    );
  }
}

class _ScaleCard extends StatelessWidget {
  final String title;
  final String assetPath;
  final bool selected;
  final VoidCallback? onTap;

  const _ScaleCard({
    required this.title,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 218,
      child: BioGGlassCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
        backgroundColor: selected
            ? const Color(0xFFF0F7EE).withValues(alpha:0.96)
            : const Color(0xFFF7F8F8).withValues(alpha:0.94),
        borderColor: selected
            ? const Color(0xFF8EB07C)
            : Colors.white.withValues(alpha:0.94),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          const Color(0xFFD7F1FF),
                          selected
                              ? const Color(0xFFEAF8D8)
                              : const Color(0xFFF5F8FB),
                        ],
                      ),
                    ),
                    child: Center(
                      child: OnboardingAssetBadge(
                        assetPath: assetPath,
                        size: 92,
                        imageScale: 0.86,
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.all(6),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    color: const Color(0xFF2D3941),
                  ),
                ),
                const SizedBox(height: 10),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: selected
                      ? const Color(0xFF91C46D)
                      : const Color(0xFFD0D8DC),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
