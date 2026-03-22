import 'package:flutter/material.dart';

import 'package:bio_g/widgets/onboarding/onboarding_asset_badge.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/widgets/onboarding/onboarding_header.dart';
import 'package:bio_g/widgets/onboarding/onboarding_primary_button.dart';
import 'package:bio_g/widgets/onboarding/onboarding_shell.dart';

class PairBioGStep extends StatelessWidget {
  final VoidCallback? onScanQr;
  final VoidCallback? onConnectBluetooth;
  final VoidCallback? onContinue;
  final bool showScaffold;
  final bool showContinueButton;
  final String primaryActionLabel;
  final String? pairedDeviceName;

  const PairBioGStep({
    super.key,
    this.onScanQr,
    this.onConnectBluetooth,
    this.onContinue,
    this.showScaffold = true,
    this.showContinueButton = false,
    this.primaryActionLabel = 'Finalizar',
    this.pairedDeviceName,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const OnboardingHeader(
          logoAsset: OnboardingUiAssets.logo,
          logoWidth: 274,
          title: 'Conecta tu Bio-G',
          subtitle: 'Ultimo paso para comenzar a monitorear tu cultivo.',
        ),
        const SizedBox(height: 38),
        _PairActionCard(
          title: 'Escanear código QR',
          subtitle: 'Escanea el código que viene en tu dispositivo Bio-G.',
          icon: Icons.qr_code_scanner_rounded,
          onTap: onScanQr,
        ),
        const SizedBox(height: 14),
        _PairActionCard(
          title: 'Conectar por Bluetooth',
          subtitle: 'Busca tu Bio-G cercano y enlázalo automáticamente.',
          icon: Icons.bluetooth_rounded,
          onTap: onConnectBluetooth,
        ),
        if (pairedDeviceName != null) ...<Widget>[
          const SizedBox(height: 18),
          BioGGlassCard(
            radius: 18,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFE6F7EC),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF40BB5F),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        pairedDeviceName!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF293533),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Dispositivo vinculado',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF78A15D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            pairedDeviceName != null
                ? 'Tu Bio-G está listo. Toca Finalizar para comenzar.'
                : 'Puedes conectar tu Bio-G más tarde desde tu cuenta.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF66737A),
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
            const SizedBox(height: 26),
            OnboardingPrimaryButton(
              label: primaryActionLabel,
              onPressed: onContinue,
            ),
          ],
        ],
      );
    }

    return OnboardingShell(
      bottomAction: showContinueButton
          ? OnboardingPrimaryButton(
              label: primaryActionLabel,
              onPressed: onContinue,
            )
          : null,
      child: content,
    );
  }
}

class _PairActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _PairActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0xFFF0F7E7),
                      Color(0xFFE6F0DA),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: const Color(0xFF78A15D),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: Color(0xFF303836),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.6,
                        height: 1.45,
                        color: Colors.black.withValues(alpha:0.44),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
