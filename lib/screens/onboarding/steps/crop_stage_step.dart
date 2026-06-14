import 'package:flutter/material.dart';

import 'package:bio_g/widgets/onboarding/onboarding_asset_badge.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/widgets/onboarding/onboarding_header.dart';
import 'package:bio_g/widgets/onboarding/onboarding_primary_button.dart';
import 'package:bio_g/widgets/onboarding/onboarding_shell.dart';

class CropStageStep extends StatelessWidget {
  final String? selectedStage;
  final String? cropCategory;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onContinue;
  final bool showScaffold;
  final bool showContinueButton;

  const CropStageStep({
    super.key,
    this.selectedStage,
    this.cropCategory,
    this.onChanged,
    this.onContinue,
    this.showScaffold = true,
    this.showContinueButton = true,
  });

  bool get _canContinue => selectedStage?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final List<_StageOption> options = _optionsForCategory(cropCategory);
    final bool isTreeFlow = cropCategory == 'tree';
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OnboardingHeader(
          logoAsset: OnboardingUiAssets.logo,
          title: isTreeFlow
              ? '¿En qué estado está tu árbol?'
              : '¿En qué etapa está tu cultivo?',
          subtitle: isTreeFlow
              ? 'Selecciona la etapa que mejor describa su desarrollo actual.'
              : null,
        ),
        const SizedBox(height: 22),
        ...options.map(
          (_StageOption option) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _StageCard(
              title: option.title,
              subtitle: option.subtitle,
              assetPath: option.assetPath,
              selected: selectedStage == option.id,
              onTap: () => onChanged?.call(option.id),
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

  static List<_StageOption> _optionsForCategory(String? category) {
    if (category == 'tree') {
      // El flujo activo de árboles vive en OnboardingWizardScreen y usa el
      // modelo canónico de producción + fenología + ancla. Este step legacy se
      // conserva solo para anuales y no debe volver a emitir IDs viejos.
      return const <_StageOption>[];
    }

    return const <_StageOption>[
      _StageOption(
        id: 'planned',
        title: 'Aún no siembro / estoy por sembrar',
        subtitle: 'Preparación de suelo y planeación',
        assetPath: OnboardingUiAssets.planned,
      ),
      _StageOption(
        id: 'growing',
        title: 'Ya sembrado y creciendo',
        subtitle: 'Monitoreo activo del cultivo',
        assetPath: OnboardingUiAssets.planted,
      ),
      _StageOption(
        id: 'fallow',
        title: 'Ya coseché / descanso del suelo',
        subtitle: 'Temporada cerrada o suelo en reposo',
        assetPath: OnboardingUiAssets.harvested,
      ),
    ];
  }
}

class _StageOption {
  final String id;
  final String title;
  final String subtitle;
  final String assetPath;

  const _StageOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });
}

class _StageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String assetPath;
  final bool selected;
  final VoidCallback? onTap;

  const _StageCard({
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
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
          child: Row(
            children: <Widget>[
              OnboardingAssetBadge(
                assetPath: assetPath,
                size: 44,
                imageScale: 0.88,
                borderRadius: BorderRadius.circular(14),
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.6,
                        height: 1.35,
                        color: Colors.black.withValues(alpha:0.44),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
                color: selected
                    ? const Color(0xFF8DB379)
                    : const Color(0xFF9AB58A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
