import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/onboarding/onboarding_asset_badge.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/widgets/onboarding/onboarding_header.dart';
import 'package:bio_g/widgets/onboarding/onboarding_primary_button.dart';
import 'package:bio_g/widgets/onboarding/onboarding_shell.dart';

class CropDetailsStep extends StatelessWidget {
  final String? cultivationScale;
  final String? cropCategory;
  final String? selectedCropId;
  final String? selectedVarietyId;
  final ValueChanged<String>? onCropChanged;
  final ValueChanged<String>? onVarietyChanged;
  final VoidCallback? onContinue;
  final bool showScaffold;
  final bool showContinueButton;

  const CropDetailsStep({
    super.key,
    this.cultivationScale,
    this.cropCategory,
    this.selectedCropId,
    this.selectedVarietyId,
    this.onCropChanged,
    this.onVarietyChanged,
    this.onContinue,
    this.showScaffold = true,
    this.showContinueButton = true,
  });

  bool get _canContinue => selectedCropId?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final List<_DetailOption> options = _optionsForCategory(cropCategory);
    _DetailOption? selectedOption;
    for (final _DetailOption option in options) {
      if (option.cropId == selectedCropId) {
        selectedOption = option;
        break;
      }
    }
    final List<_VarietyOption> varieties =
        selectedOption?.varieties ?? const <_VarietyOption>[];

    // Resolve visible label for the summary row.
    String varietySummaryLabel = 'Genérico';
    if (selectedVarietyId != null) {
      for (final v in varieties) {
        if (v.id == selectedVarietyId) {
          varietySummaryLabel = v.label;
          break;
        }
      }
    }

    // Resolve variety-aware icon for bean crops.
    final String resolvedCropAsset = (selectedCropId == 'bean' &&
            selectedVarietyId != null)
        ? OnboardingUiAssets.assetForBeanVariety(selectedVarietyId)
        : (selectedOption?.assetPath ??
            OnboardingUiAssets.assetForCategory(cropCategory));

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OnboardingHeader(
          logoAsset: OnboardingUiAssets.logo,
          title: _titleForSelection(cultivationScale, cropCategory),
          subtitle: _subtitleForSelection(cropCategory),
        ),
        const SizedBox(height: 24),
        BioGGlassCard(
          radius: 22,
          child: Column(
            children: <Widget>[
              _SummaryRow(
                label: 'Cultivo',
                value: selectedOption?.title ?? 'Selecciona un cultivo',
                assetPath: resolvedCropAsset,
              ),
              const Divider(height: 20, color: Color(0x1F76828A)),
              _SummaryRow(
                label: 'Tipo',
                value: selectedOption?.typeLabel ?? _typeLabel(cropCategory),
                assetPath: OnboardingUiAssets.configureCrop,
              ),
              const Divider(height: 20, color: Color(0x1F76828A)),
              _SummaryRow(
                label: 'Variedad',
                value: varietySummaryLabel,
                assetPath: OnboardingUiAssets.variety,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...options.map(
          (_DetailOption option) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _CropOptionCard(
              title: option.title,
              subtitle: option.subtitle,
              assetPath: option.assetPath,
              selected: selectedCropId == option.cropId,
              onTap: () => onCropChanged?.call(option.cropId),
            ),
          ),
        ),
        if (varieties.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          BioGGlassCard(
            radius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Variedad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334149),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: varieties
                      .map(
                        (_VarietyOption v) => _VarietyChip(
                          label: v.label,
                          selected: selectedVarietyId == v.id,
                          onTap: () => onVarietyChanged?.call(v.id),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ],
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

  static String _typeLabel(String? category) {
    switch (category) {
      case 'tree':
        return 'Frutal';
      case 'ornamental':
        return 'Ornamental';
      case 'vegetable':
        return 'Huerta';
      case CropCatalog.grainCategoryId:
        return 'Grano';
      default:
        return 'General';
    }
  }

  static String _titleForSelection(String? scale, String? category) {
    final String scaleLabel = _scaleLabel(scale);
    if (category == CropCatalog.grainCategoryId && scale == 'field') {
      return '¿Qué vas a sembrar en tu campo?';
    }
    return '¿Qué vas a cultivar en tu $scaleLabel?';
  }

  static String _subtitleForSelection(String? category) {
    switch (category) {
      case CropCatalog.grainCategoryId:
        return 'Selecciona el grano, tipo y variedad de semilla.';
      case 'tree':
        return 'Selecciona la especie y variedad más cercana a tu árbol.';
      case 'vegetable':
        return 'Selecciona la planta principal que quieres monitorear.';
      default:
        return 'Selecciona cultivo, tipo y variedad.';
    }
  }

  static List<_DetailOption> _optionsForCategory(String? category) {
    if (category == CropCatalog.grainCategoryId) {
      return CropCatalog.cropsByCategory(
        CropCatalog.grainCategoryId,
        enabledOnly: false,
      ).map(_fromCatalogCrop).toList(growable: false);
    }

    if (category == CropCatalog.vegetableCategoryId) {
      return CropCatalog.cropsByCategory(
        CropCatalog.vegetableCategoryId,
        enabledOnly: false,
      ).map(_fromCatalogCrop).toList(growable: false);
    }

    switch (category) {
      case 'tree':
        return const <_DetailOption>[
          _DetailOption(
            cropId: 'lemon_tree',
            title: 'Limón',
            subtitle: 'Árbol frutal para huerto o patio',
            typeLabel: 'Cítrico',
            assetPath: OnboardingUiAssets.tree,
            varieties: <_VarietyOption>[
              _VarietyOption(id: 'lemon_persa', label: 'Persa'),
              _VarietyOption(id: 'lemon_mexicano', label: 'Mexicano'),
              _VarietyOption(id: 'lemon_generic', label: 'Genérico'),
            ],
          ),
          _DetailOption(
            cropId: 'apple_tree',
            title: 'Manzano',
            subtitle: 'Producción general',
            typeLabel: 'Frutal',
            assetPath: OnboardingUiAssets.tree,
            varieties: <_VarietyOption>[
              _VarietyOption(id: 'apple_rojo', label: 'Rojo'),
              _VarietyOption(id: 'apple_verde', label: 'Verde'),
              _VarietyOption(id: 'apple_generic', label: 'Genérico'),
            ],
          ),
        ];
      case 'ornamental':
        return const <_DetailOption>[
          _DetailOption(
            cropId: 'rose',
            title: 'Rosa',
            subtitle: 'Planta ornamental de flor',
            typeLabel: 'Flor',
            assetPath: OnboardingUiAssets.ornamental,
            varieties: <_VarietyOption>[
              _VarietyOption(id: 'rose_mini', label: 'Mini'),
              _VarietyOption(id: 'rose_jardin', label: 'Jardín'),
              _VarietyOption(id: 'rose_generic', label: 'Genérico'),
            ],
          ),
          _DetailOption(
            cropId: 'cactus',
            title: 'Cactus',
            subtitle: 'Ornamental de bajo riego',
            typeLabel: 'Suculenta',
            assetPath: OnboardingUiAssets.ornamental,
            varieties: <_VarietyOption>[
              _VarietyOption(id: 'cactus_columnar', label: 'Columnar'),
              _VarietyOption(id: 'cactus_mini', label: 'Mini'),
              _VarietyOption(id: 'cactus_generic', label: 'Genérico'),
            ],
          ),
        ];
      default:
        return const <_DetailOption>[
          _DetailOption(
            cropId: 'generic',
            title: 'Otro / genérico',
            subtitle: 'Continuar con configuración base',
            typeLabel: 'General',
            assetPath: OnboardingUiAssets.genericPlant,
            varieties: <_VarietyOption>[
              _VarietyOption(id: 'generic', label: 'Genérico'),
            ],
          ),
        ];
    }
  }

  static _DetailOption _fromCatalogCrop(CropCatalogEntry crop) {
    final List<CropVarietyEntry> varieties = CropCatalog.varietiesForCrop(
      crop.cropId,
      enabledOnly: false,
    );

    return _DetailOption(
      cropId: crop.cropId,
      title: crop.label,
      subtitle: crop.subtitle ?? 'Disponible en el catálogo',
      typeLabel: _typeLabelForCategory(crop.categoryId),
      assetPath: OnboardingUiAssets.assetForCrop(
        crop.cropId,
        category: crop.categoryId,
      ),
      varieties: varieties.isEmpty
          ? const <_VarietyOption>[
              _VarietyOption(id: 'generic', label: 'Genérico'),
            ]
          : varieties
                .map((CropVarietyEntry item) =>
                    _VarietyOption(id: item.id, label: item.label))
                .toList(growable: false),
    );
  }

  static String _typeLabelForCategory(String categoryId) {
    switch (categoryId) {
      case CropCatalog.grainCategoryId:
        return 'Grano';
      case CropCatalog.vegetableCategoryId:
        return 'Hortaliza';
      default:
        return 'Cultivo';
    }
  }
}

class _VarietyOption {
  final String id;
  final String label;

  const _VarietyOption({required this.id, required this.label});
}

class _DetailOption {
  final String cropId;
  final String title;
  final String subtitle;
  final String typeLabel;
  final String assetPath;
  final List<_VarietyOption> varieties;

  const _DetailOption({
    required this.cropId,
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.assetPath,
    required this.varieties,
  });
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String assetPath;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        OnboardingAssetBadge(
          assetPath: assetPath,
          size: 40,
          imageScale: 0.86,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF87939A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF364249),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CropOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String assetPath;
  final bool selected;
  final VoidCallback? onTap;

  const _CropOptionCard({
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

class _VarietyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _VarietyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE7F6D8) : const Color(0xFFF2F5F6),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected
                  ? const Color(0xFF6F9652)
                  : const Color(0xFF68757D),
            ),
          ),
        ),
      ),
    );
  }
}
