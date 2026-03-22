import 'package:flutter/material.dart';

import 'package:bio_g/widgets/onboarding/onboarding_asset_badge.dart';
import 'package:bio_g/widgets/onboarding/onboarding_header.dart';
import 'package:bio_g/widgets/onboarding/onboarding_primary_button.dart';
import 'package:bio_g/widgets/onboarding/onboarding_shell.dart';

class LocationStep extends StatelessWidget {
  final String? selectedSource;
  final String? selectedLabel;
  final VoidCallback? onUseCurrentLocation;
  final VoidCallback? onPickOnMap;
  final VoidCallback? onContinue;
  final bool showScaffold;
  final bool showContinueButton;

  const LocationStep({
    super.key,
    this.selectedSource,
    this.selectedLabel,
    this.onUseCurrentLocation,
    this.onPickOnMap,
    this.onContinue,
    this.showScaffold = true,
    this.showContinueButton = true,
  });

  bool get _canContinue =>
      (selectedSource?.isNotEmpty ?? false) || (selectedLabel?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const OnboardingHeader(
          logoAsset: OnboardingUiAssets.logo,
          logoWidth: 274,
          title: '¿Dónde está tu cultivo?',
          subtitle:
              'Usamos tu ubicación para adaptar clima, riego y recomendaciones.',
        ),
        const SizedBox(height: 28),
        _LocationActionCard(
          title: 'Usar mi ubicación',
          subtitle: selectedSource == 'gps'
              ? (selectedLabel ?? 'Ubicación actual seleccionada')
              : 'Activa una ubicación aproximada para este cultivo',
          icon: Icons.location_on_rounded,
          selected: selectedSource == 'gps',
          onTap: onUseCurrentLocation,
        ),
        const SizedBox(height: 22),
        const _OrDivider(),
        const SizedBox(height: 22),
        _LocationActionCard(
          title: 'Seleccionar en el mapa',
          subtitle: selectedSource == 'map'
              ? (selectedLabel ?? 'Punto manual seleccionado')
              : 'Marca la zona de cultivo manualmente',
          icon: Icons.map_rounded,
          selected: selectedSource == 'map',
          onTap: onPickOnMap,
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

class _LocationActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _LocationActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(22);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: selected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double t, Widget? _) {
        // Background gradient
        final Color bgStart = Color.lerp(
          const Color(0xFFF7F8F8),
          const Color(0xFF40BB5F),
          t,
        )!;
        final Color bgEnd = Color.lerp(
          const Color(0xFFF7F8F8),
          const Color(0xFF2B9E6A),
          t,
        )!;

        // Border
        final Color borderColor = Color.lerp(
          const Color(0xFFE8ECEE),
          const Color(0xFF3FAF6E),
          t,
        )!;

        // Icon container
        final Color iconBg = Color.lerp(
          const Color(0xFFF1F7F5),
          const Color(0x2EFFFFFF),
          t,
        )!;
        final Color iconColor = Color.lerp(
          const Color(0xFF63B69B),
          Colors.white,
          t,
        )!;

        // Text
        final Color titleColor = Color.lerp(
          const Color(0xFF303836),
          Colors.white,
          t,
        )!;
        final Color subtitleColor = Color.lerp(
          const Color(0xFF303836).withAlpha(112),
          const Color(0xFFFFFFFF).withAlpha(224),
          t,
        )!;

        // Trailing icon
        final Color trailingColor = Color.lerp(
          const Color(0xFF9AB58A),
          const Color(0xFFFFFFFF).withAlpha(230),
          t,
        )!;

        return Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[bgStart, bgEnd],
            ),
            border: Border.all(
              color: borderColor.withAlpha((255 * (1 - t * 0.6)).round()),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            child: InkWell(
              borderRadius: borderRadius,
              splashColor: const Color(0x14FFFFFF),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: iconBg,
                      ),
                      child: Icon(icon, size: 26, color: iconColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16.2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13.6,
                              height: 1.35,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      child: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.chevron_right_rounded,
                        key: ValueKey<bool>(selected),
                        size: 18,
                        color: trailingColor,
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
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(height: 1, color: const Color(0xFFDDE5E8)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC9D1D9), width: 2),
            color: const Color(0xC7FFFFFF),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: const Color(0xFFDDE5E8)),
        ),
      ],
    );
  }
}
