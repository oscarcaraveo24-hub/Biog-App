import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/widgets/onboarding/onboarding_asset_badge.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/widgets/onboarding/onboarding_header.dart';
import 'package:bio_g/widgets/onboarding/onboarding_primary_button.dart';
import 'package:bio_g/widgets/onboarding/onboarding_shell.dart';

class CropCategoryStep extends StatelessWidget {
  final String? selectedCategory;
  final String? cultivationScale;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onContinue;
  final bool showScaffold;
  final bool showContinueButton;

  const CropCategoryStep({
    super.key,
    this.selectedCategory,
    this.cultivationScale,
    this.onChanged,
    this.onContinue,
    this.showScaffold = true,
    this.showContinueButton = true,
  });

  bool get _canContinue => selectedCategory?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final String scaleLabel = _scaleLabel(cultivationScale);
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OnboardingHeader(
          logoAsset: OnboardingUiAssets.logo,
          title: '¿Qué vas a cultivar en tu $scaleLabel?',
          subtitle: 'Selecciona la planta que tienes o planeas sembrar.',
        ),
        const SizedBox(height: 24),
        ..._categories.map(
          (_CategoryOption option) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _CategoryCard(
              title: option.title,
              subtitle: option.subtitle,
              assetPath: option.assetPath,
              selected: selectedCategory == option.id,
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

  static String _scaleLabel(String? scale) {
    switch (scale) {
      case 'field':
        return 'campo';
      case 'orchard':
        return 'huerto';
      case 'pot':
        return 'maceta';
      default:
        return 'cultivo';
    }
  }

  static final List<_CategoryOption> _categories = <_CategoryOption>[
    _CategoryOption(
      id: CropCatalog.grainCategoryId,
      title: 'Grano',
      subtitle: 'Maíz, trigo, sorgo...',
      assetPath: OnboardingUiAssets.grain,
    ),
    const _CategoryOption(
      id: 'vegetable',
      title: 'Hortaliza',
      subtitle: 'Tomate, cebolla, lechuga...',
      assetPath: OnboardingUiAssets.vegetable,
    ),
    const _CategoryOption(
      id: 'tree',
      title: 'Árbol',
      subtitle: 'Pino, manzano, limón...',
      assetPath: OnboardingUiAssets.tree,
    ),
    const _CategoryOption(
      id: 'ornamental',
      title: 'Planta ornamental',
      subtitle: 'Cactus, rosa, helecho...',
      assetPath: OnboardingUiAssets.ornamental,
    ),
    const _CategoryOption(
      id: 'generic',
      title: 'Otro / genérico',
      subtitle: 'Continuar con perfil general',
      assetPath: OnboardingUiAssets.genericPlant,
    ),
  ];
}

class _CategoryOption {
  final String id;
  final String title;
  final String subtitle;
  final String assetPath;

  const _CategoryOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String assetPath;
  final bool selected;
  final VoidCallback? onTap;

  const _CategoryCard({
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
