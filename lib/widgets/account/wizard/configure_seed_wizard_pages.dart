import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_components.dart';
import 'package:bio_g/widgets/shared/bio_g_button.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({
    super.key,
    required this.category,
    required this.summary,
    required this.onSelect,
  });

  final String? category;
  final Widget? summary;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return CenteredWizardPage(
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(),
          const SizedBox(height: 22),
          const StaggerIn(
            delay: 0,
            child: Text(
              '¿Qué vas a sembrar en tu campo?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                height: 1.18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: Color(0xFF293533),
              ),
            ),
          ),
          const SizedBox(height: 10),
          StaggerIn(
            delay: 40,
            child: Builder(
              builder: (context) {
                return Text(
                  'Selecciona la planta que tienes o planeas sembrar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.4,
                    height: 1.34,
                    color: Colors.black.withValues(alpha:0.45),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          StaggerIn(
            delay: 90,
            child: WizardLongPill(
              iconPath: ConfigureSeedWizardAssets.categoryGrain,
              title: 'Grano',
              subtitle: 'Maíz, trigo, sorgo...',
              selected: category == 'grain',
              enabled: true,
              onTap: () => onSelect('grain'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 145,
            child: WizardLongPill(
              iconPath: ConfigureSeedWizardAssets.categoryVegetable,
              title: 'Hortaliza',
              subtitle: 'Tomate, cebolla, lechuga...',
              selected: category == 'vegetable',
              enabled: true,
              onTap: () => onSelect('vegetable'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 200,
            child: WizardLongPill(
              iconPath: ConfigureSeedWizardAssets.categoryTree,
              title: 'Árbol',
              subtitle: 'Pino, manzano, limón...',
              selected: category == 'tree',
              enabled: false,
              onTap: null,
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 255,
            child: WizardLongPill(
              iconPath: ConfigureSeedWizardAssets.categoryOrnamental,
              title: 'Planta ornamental',
              subtitle: 'Cactus, rosa, helecho...',
              selected: category == 'ornamental',
              enabled: false,
              onTap: null,
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 310,
            child: WizardLongPill(
              iconPath: ConfigureSeedWizardAssets.categoryGeneric,
              title: 'Otro / genérico',
              subtitle: 'Próximamente',
              selected: category == 'generic',
              enabled: false,
              onTap: null,
            ),
          ),
          if (summary != null) ...[
            const SizedBox(height: 18),
            StaggerIn(delay: 360, child: summary!),
          ],
        ],
      ),
    );
  }
}

class CropVarietyPage extends StatelessWidget {
  const CropVarietyPage({
    super.key,
    required this.categoryLabel,
    required this.cropLabel,
    required this.varietyLabel,
    required this.cropSelected,
    required this.varietySelected,
    required this.cropEnabled,
    this.cropUsesBrands = false,
    this.cropIconPath,
    this.varietyIconPath,
    required this.summary,
    required this.onTapCrop,
    required this.onTapVariety,
  });

  final String categoryLabel;
  final String cropLabel;
  final String varietyLabel;
  final bool cropSelected;
  final bool varietySelected;
  final bool cropEnabled;
  final bool cropUsesBrands;
  final String? cropIconPath;
  final String? varietyIconPath;
  final Widget? summary;
  final VoidCallback onTapCrop;
  final VoidCallback onTapVariety;

  String get _subtitleText {
    if (cropUsesBrands) {
      return 'Selecciona el cultivo y la semilla.';
    }
    return 'Selecciona el cultivo y la variedad.';
  }

  String get _varietyPillTitle {
    if (cropUsesBrands) {
      return 'Marca y semilla';
    }
    return 'Variedad';
  }

  @override
  Widget build(BuildContext context) {
    return CenteredWizardPage(
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(),
          const SizedBox(height: 22),
          const StaggerIn(
            delay: 0,
            child: Text(
              '¿Qué vas a sembrar en tu campo?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                height: 1.18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: Color(0xFF293533),
              ),
            ),
          ),
          const SizedBox(height: 10),
          StaggerIn(
            delay: 40,
            child: Builder(
              builder: (context) {
                return Text(
                  _subtitleText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.4,
                    height: 1.34,
                    color: Colors.black.withValues(alpha:0.45),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          StaggerIn(
            delay: 95,
            child: SelectionPill(
              iconPath: _categoryIconForLabel(categoryLabel),
              title: 'Categoría',
              value: categoryLabel,
              selected: true,
              onTap: null,
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 150,
            child: SelectionPill(
              iconPath: cropIconPath ?? _cropIconPath(cropLabel),
              title: 'Cultivo',
              value: cropLabel,
              selected: cropSelected,
              onTap: cropEnabled ? onTapCrop : null,
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 205,
            child: SelectionPill(
              iconPath: varietyIconPath ?? ConfigureSeedWizardAssets.variety,
              title: _varietyPillTitle,
              value: varietyLabel,
              selected: varietySelected,
              onTap: cropSelected ? onTapVariety : null,
            ),
          ),
          const SizedBox(height: 18),
          StaggerIn(
            delay: 255,
            child: Text(
              cropUsesBrands
                  ? 'Si no conoces tu semilla exacta, podrás elegir un perfil genérico.'
                  : 'Usa perfil genérico si no sabes la variedad.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.6,
                height: 1.32,
                color: Colors.black.withValues(alpha:0.48),
              ),
            ),
          ),
          if (summary != null) ...[
            const SizedBox(height: 18),
            StaggerIn(delay: 300, child: summary!),
          ],
        ],
      ),
    );
  }

  static String _cropIconPath(String cropLabel) {
    switch (cropLabel) {
      case 'Maíz':
        return ConfigureSeedWizardAssets.cropMaize;
      case 'Trigo':
        return ConfigureSeedWizardAssets.cropWheat;
      case 'Cebada':
        return ConfigureSeedWizardAssets.cropBarley;
      case 'Frijol':
        return ConfigureSeedWizardAssets.cropBean;
      case 'Avena':
        return ConfigureSeedWizardAssets.cropOat;
      case 'Tomate':
        return ConfigureSeedWizardAssets.cropTomato;
      default:
        return ConfigureSeedWizardAssets.categoryGeneric;
    }
  }

  static String _categoryIconForLabel(String categoryLabel) {
    switch (categoryLabel) {
      case 'Hortaliza':
      case 'Hortalizas':
        return ConfigureSeedWizardAssets.categoryVegetable;
      case 'Árbol':
      case 'Arbol':
        return ConfigureSeedWizardAssets.categoryTree;
      case 'Planta ornamental':
      case 'Ornamental':
        return ConfigureSeedWizardAssets.categoryOrnamental;
      case 'Grano':
        return ConfigureSeedWizardAssets.categoryGrain;
      default:
        return ConfigureSeedWizardAssets.categoryGrain;
    }
  }
}

// ─── Brand selection page (maize only) ────────────────────────────────────────

class BrandPage extends StatelessWidget {
  const BrandPage({
    super.key,
    required this.brands,
    required this.selectedBrandId,
    required this.summary,
    required this.onSelect,
  });

  final List<CropBrandEntry> brands;
  final String? selectedBrandId;
  final Widget? summary;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return CenteredWizardPage(
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(),
          const SizedBox(height: 22),
          const StaggerIn(
            delay: 0,
            child: Text(
              'Selecciona la marca\nde tu semilla',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                height: 1.18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: Color(0xFF293533),
              ),
            ),
          ),
          const SizedBox(height: 10),
          StaggerIn(
            delay: 40,
            child: Text(
              '¿De qué casa semillera es tu maíz?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.4,
                height: 1.34,
                color: Colors.black.withValues(alpha:0.45),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...brands.asMap().entries.map((entry) {
            final index = entry.key;
            final brand = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: StaggerIn(
                delay: 90 + index * 55,
                child: WizardLongPill(
                  iconPath: ConfigureSeedWizardAssets.variety,
                  title: brand.label,
                  subtitle: '',
                  selected: selectedBrandId == brand.id,
                  enabled: brand.enabled,
                  onTap: brand.enabled ? () => onSelect(brand.id) : null,
                ),
              ),
            );
          }),
          if (summary != null) ...[
            const SizedBox(height: 18),
            StaggerIn(
              delay: 90 + brands.length * 55 + 40,
              child: summary!,
            ),
          ],
          const SizedBox(height: 14),
          StaggerIn(
            delay: 90 + brands.length * 55 + 80,
            child: const _TrademarkDisclaimer(),
          ),
        ],
      ),
    );
  }
}

// ─── Variety selection page (after brand for maize) ───────────────────────────

class VarietyPage extends StatelessWidget {
  const VarietyPage({
    super.key,
    required this.varieties,
    required this.selectedVarietyId,
    required this.brandLabel,
    required this.summary,
    required this.onSelect,
  });

  final List<CropVarietyEntry> varieties;
  final String? selectedVarietyId;
  final String brandLabel;
  final Widget? summary;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return CenteredWizardPage(
      scrollable: true,
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(),
          const SizedBox(height: 22),
          StaggerIn(
            delay: 0,
            child: Text(
              'Selecciona tu semilla\n$brandLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                height: 1.18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: Color(0xFF293533),
              ),
            ),
          ),
          const SizedBox(height: 10),
          StaggerIn(
            delay: 40,
            child: Text(
              'Elige la variedad comercial que sembraste o vas a sembrar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.4,
                height: 1.34,
                color: Colors.black.withValues(alpha:0.45),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...varieties.asMap().entries.map((entry) {
            final index = entry.key;
            final variety = entry.value;
            final iconPath = ConfigureSeedWizardAssets.maizeIconForVariety(
              useTypeId: variety.useTypeId,
              marketTypeId: variety.marketTypeId,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: StaggerIn(
                delay: 90 + (index.clamp(0, 8)) * 35,
                child: WizardLongPill(
                  iconPath: iconPath,
                  title: variety.label,
                  subtitle: variety.subtitle ?? '',
                  selected: selectedVarietyId == variety.id,
                  enabled: variety.enabled,
                  onTap: variety.enabled ? () => onSelect(variety.id) : null,
                ),
              ),
            );
          }),
          if (summary != null) ...[
            const SizedBox(height: 18),
            StaggerIn(delay: 400, child: summary!),
          ],
          const SizedBox(height: 14),
          const _TrademarkDisclaimer(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class StagePage extends StatelessWidget {
  const StagePage({
    super.key,
    required this.stage,
    required this.summary,
    required this.onSelect,
  });

  final String? stage;
  final Widget? summary;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return CenteredWizardPage(
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(),
          const SizedBox(height: 22),
          const StaggerIn(
            delay: 0,
            child: Text(
              '¿En qué etapa está tu cultivo?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                height: 1.18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: Color(0xFF293533),
              ),
            ),
          ),
          const SizedBox(height: 24),
          StaggerIn(
            delay: 90,
            child: WizardLongPill(
              iconPath: ConfigureSeedWizardAssets.stagePlanned,
              title: 'Aún no siembro /\nestoy por sembrar',
              subtitle: '',
              selected: stage == 'planned',
              enabled: true,
              onTap: () => onSelect('planned'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 145,
            child: WizardLongPill(
              iconPath: ConfigureSeedWizardAssets.stagePlanted,
              title: 'Ya sembrado y creciendo',
              subtitle: '',
              selected: stage == 'planted',
              enabled: true,
              onTap: () => onSelect('planted'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 200,
            child: WizardLongPill(
              iconPath: ConfigureSeedWizardAssets.stageSkip,
              title: 'Ya coseché / descanso del suelo',
              subtitle: '',
              selected: stage == 'skip',
              enabled: true,
              onTap: () => onSelect('skip'),
            ),
          ),
          if (summary != null) ...[
            const SizedBox(height: 18),
            StaggerIn(delay: 250, child: summary!),
          ],
        ],
      ),
    );
  }
}

class DatePage extends StatelessWidget {
  const DatePage({
    super.key,
    required this.title,
    required this.selectedDate,
    required this.flexibleDate,
    required this.flexibleLabel,
    required this.flexibleDescription,
    required this.helperText,
    this.cropIconPath,
    required this.summary,
    required this.saving,
    required this.onDateChanged,
    required this.onFlexibleChanged,
    required this.onSave,
  });

  final String title;
  final DateTime selectedDate;
  final bool flexibleDate;
  final String flexibleLabel;
  final String flexibleDescription;
  final String helperText;
  final String? cropIconPath;
  final Widget? summary;
  final bool saving;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<bool> onFlexibleChanged;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return CenteredWizardPage(
      scrollable: true,
      topPadding: 4,
      child: Column(
        children: [
          const BrandMark(),
          const SizedBox(height: 18),
          StaggerIn(
            delay: 0,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                height: 1.18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: Color(0xFF293533),
              ),
            ),
          ),
          const SizedBox(height: 18),
          StaggerIn(
            delay: 70,
            child: BioGGlassCard(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: const Color(0xFF86A97D),
                    onPrimary: Colors.white,
                    onSurface: const Color(0xFF3C4845),
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  onDateChanged: onDateChanged,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          StaggerIn(
            delay: 130,
            child: FlexibleDateCard(
              label: flexibleLabel,
              description: flexibleDescription,
              selected: flexibleDate,
              onTap: () => onFlexibleChanged(!flexibleDate),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 190,
            child: BioGGlassCard(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WizardAssetIcon(
                    assetPath: cropIconPath ?? ConfigureSeedWizardAssets.categoryGeneric,
                    slotWidth: 34,
                    slotHeight: 34,
                    imageWidth: 34,
                    imageHeight: 34,
                    scale: 1.75,
                    offsetX: -4,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      helperText,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.black.withValues(alpha:0.58),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (summary != null) ...[
            const SizedBox(height: 16),
            StaggerIn(delay: 240, child: summary!),
          ],
          const SizedBox(height: 18),
          StaggerIn(
            delay: 290,
            child: BioGButton(
              label: 'Guardar configuración',
              height: 54,
              loading: saving,
              onTap: onSave,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TrademarkDisclaimer extends StatelessWidget {
  const _TrademarkDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        'Las marcas y denominaciones comerciales mencionadas pertenecen '
        'a sus respectivos titulares y se muestran únicamente con fines '
        'de identificación del cultivo o semilla reportada por el usuario.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          height: 1.38,
          color: Colors.black.withValues(alpha:0.32),
        ),
      ),
    );
  }
}
