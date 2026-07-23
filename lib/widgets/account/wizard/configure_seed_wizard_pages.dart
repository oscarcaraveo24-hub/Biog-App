import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/apple_tree/apple_tree_assets.dart';
import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/recurring_bloom/recurring_bloom_crops.dart';
// Tulipán (seasonal_bulb): textos/íconos del modo bulboso estacional.
import 'package:bio_g/core/crops/seasonal_bulb/seasonal_bulb_crops.dart';
// Girasol (annual_ornamental): textos/íconos del modo anual ornamental.
import 'package:bio_g/core/crops/annual_ornamental/annual_ornamental_crops.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_components.dart';
import 'package:bio_g/widgets/shared/bio_g_button.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/widgets/shared/bio_g_wheel_date_picker.dart';

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
              '¿Que vas a monitorear?',
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
                  'Selecciona el cultivo o arbol que tienes en tu campo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.4,
                    height: 1.34,
                    color: Colors.black.withValues(alpha: 0.45),
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
              title: 'Arbol',
              subtitle: 'Manzano, pera y otros frutales perennes',
              selected: category == 'tree',
              enabled: true,
              onTap: () => onSelect('tree'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 255,
            child: WizardLongPill(
              iconPath: ConfigureSeedWizardAssets.categoryOrnamental,
              title: 'Planta ornamental',
              subtitle: 'Cactus, suculentas y sábila · más ornamentales próximamente',
              selected: category == 'ornamental',
              enabled: true,
              onTap: () => onSelect('ornamental'),
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
    this.isTreeFlow = false,
    this.isOrnamentalFlow = false,
    this.ornamentalCropId,
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
  final bool isTreeFlow;

  /// Flujo ornamental (cactus, suculenta…): la "variedad" es un PERFIL.
  final bool isOrnamentalFlow;

  /// cropId canónico de la ornamental, para textos con el género correcto.
  final String? ornamentalCropId;
  final bool cropUsesBrands;
  final String? cropIconPath;
  final String? varietyIconPath;
  final Widget? summary;
  final VoidCallback onTapCrop;
  final VoidCallback onTapVariety;

  String get _subtitleText {
    if (isOrnamentalFlow) {
      return ornamentalVarietyFlowSubtitle(ornamentalCropId);
    }
    if (isTreeFlow) {
      return 'Selecciona el árbol y su variedad.';
    }
    if (_isChiliCrop) {
      return 'Selecciona el cultivo y el tipo de chile.';
    }
    if (_isEggplantCrop) {
      return 'Selecciona el cultivo y el tipo de berenjena.';
    }
    if (cropUsesBrands) {
      return 'Selecciona el cultivo y la semilla.';
    }
    return 'Selecciona el cultivo y la variedad.';
  }

  String get _varietyPillTitle {
    if (isOrnamentalFlow) {
      return 'Perfil';
    }
    if (isTreeFlow) {
      return 'Variedad';
    }
    if (_isChiliCrop) {
      return 'Tipo de chile';
    }
    if (_isEggplantCrop) {
      return 'Tipo de berenjena';
    }
    if (cropUsesBrands) {
      return 'Marca y semilla';
    }
    return 'Variedad';
  }

  bool get _isChiliCrop => cropLabel.trim().toLowerCase() == 'chile';

  bool get _isEggplantCrop => cropLabel.trim().toLowerCase() == 'berenjena';

  String get _helperText {
    if (isOrnamentalFlow) {
      return ornamentalVarietyFlowHelper(ornamentalCropId);
    }
    if (isTreeFlow) {
      return 'Si no sabes la variedad, usa la opción general. Es migrable, no descanso del suelo.';
    }
    if (cropUsesBrands) {
      return 'Si no conoces tu semilla exacta, podras elegir un perfil generico.';
    }
    if (_isChiliCrop) {
      return 'Si no sabes el tipo de chile, puedes usar No se / Otro chile.';
    }
    if (_isEggplantCrop) {
      return 'Si no sabes el tipo, puedes usar No se / Otra berenjena.';
    }
    return 'Usa perfil generico si no sabes la variedad.';
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
              '¿Que vas a monitorear?',
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
                    color: Colors.black.withValues(alpha: 0.45),
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
              fallbackAsset: isOrnamentalFlow
                  ? kOrnamentalGenericPlantFallback
                  : 'assets/icons/wizard/ic_tree.png',
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
              fallbackAsset: isOrnamentalFlow
                  ? kOrnamentalGenericPlantFallback
                  : 'assets/icons/wizard/ic_tree.png',
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
              _helperText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.6,
                height: 1.32,
                color: Colors.black.withValues(alpha: 0.48),
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
      case 'Pepino':
        return ConfigureSeedWizardAssets.cropCucumber;
      case 'Chile':
        return ConfigureSeedWizardAssets.cropChili;
      case 'Berenjena':
        return ConfigureSeedWizardAssets.cropEggplant;
      case 'Manzano':
        return AppleTreeAssets.cropIcon;
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
      case 'Árboles':
      case 'Arbol':
      case 'Arboles':
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
                color: Colors.black.withValues(alpha: 0.45),
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
            StaggerIn(delay: 90 + brands.length * 55 + 40, child: summary!),
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
                color: Colors.black.withValues(alpha: 0.45),
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
    this.ornamentalMode = false,
    this.ornamentalCropId,
    this.seasonalBulbMode = false,
    this.seasonalBulbCropId,
    this.annualOrnamentalMode = false,
    this.annualOrnamentalCropId,
  });

  final String? stage;
  final Widget? summary;
  final ValueChanged<String> onSelect;

  /// Modo ornamental (cactus, suculenta…): SOLO dos intenciones de alta.
  /// NO muestra cosecha ni descanso del suelo.
  final bool ornamentalMode;

  /// cropId canónico de la ornamental, para textos con el género correcto.
  final String? ornamentalCropId;

  /// Modo bulboso estacional (Tulipán / seasonal_bulb): SOLO dos opciones de
  /// alta ("Lo voy a plantar" / "Ya está plantado"), SIN descanso del suelo (un
  /// bulbo entra en dormancia, no en fallow). A diferencia del modo ornamental,
  /// emite los MISMOS valores que el grano ('planned' / 'planted') para que la
  /// fecha y la persistencia corran por la ruta de grano y conserven el
  /// sowingDate como ancla real.
  final bool seasonalBulbMode;

  /// cropId canónico del bulboso estacional, para textos con su nombre.
  final String? seasonalBulbCropId;

  /// Modo anual ornamental (Girasol / annual_ornamental): SOLO dos opciones de
  /// alta ("Lo voy a sembrar" / "Ya está sembrado o plantado"), SIN descanso
  /// del suelo. Igual que el modo bulboso estacional, emite los MISMOS valores
  /// que el grano ('planned' / 'planted') para que la fecha y la persistencia
  /// corran por la ruta de grano y conserven el sowingDate como ancla real.
  final bool annualOrnamentalMode;

  /// cropId canónico de la ornamental anual, para textos con su nombre.
  final String? annualOrnamentalCropId;

  @override
  Widget build(BuildContext context) {
    return CenteredWizardPage(
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(),
          const SizedBox(height: 22),
          StaggerIn(
            delay: 0,
            child: Text(
              ornamentalMode
                  ? ornamentalStateQuestion(ornamentalCropId)
                  : seasonalBulbMode
                  ? '¿En qué etapa está tu '
                        '${seasonalBulbCropDisplayName(seasonalBulbCropId).toLowerCase()}?'
                  : annualOrnamentalMode
                  ? '¿En qué etapa está tu '
                        '${annualOrnamentalCropDisplayName(annualOrnamentalCropId).toLowerCase()}?'
                  : '¿En qué etapa está tu cultivo?',
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
          const SizedBox(height: 24),
          // Ornamental: SOLO dos opciones (la voy a plantar / ya está plantada) y
          // los MISMOS iconos de wizard que usa el grano. Nunca imágenes de
          // etapa, que no son iconos de menú.
          StaggerIn(
            delay: 90,
            child: WizardLongPill(
              iconPath: ConfigureSeedWizardAssets.stagePlanned,
              title: ornamentalMode
                  ? ornamentalPlannedOptionTitle(ornamentalCropId)
                  : seasonalBulbMode
                  ? seasonalBulbPlannedOptionTitle(seasonalBulbCropId)
                  : annualOrnamentalMode
                  ? annualOrnamentalPlannedOptionTitle(annualOrnamentalCropId)
                  : 'Aún no siembro /\nestoy por sembrar',
              subtitle: '',
              selected: ornamentalMode
                  ? stage == kOrnamentalIntentPlannedPlant
                  : stage == 'planned',
              enabled: true,
              fallbackAsset: 'assets/icons/wizard/ic_tree.png',
              onTap: () => onSelect(
                ornamentalMode ? kOrnamentalIntentPlannedPlant : 'planned',
              ),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 145,
            child: WizardLongPill(
              iconPath: ConfigureSeedWizardAssets.stagePlanted,
              title: ornamentalMode
                  ? ornamentalPlantedOptionTitle(ornamentalCropId)
                  : seasonalBulbMode
                  ? seasonalBulbPlantedOptionTitle(seasonalBulbCropId)
                  : annualOrnamentalMode
                  ? annualOrnamentalPlantedOptionTitle(annualOrnamentalCropId)
                  : 'Ya sembrado y creciendo',
              subtitle: '',
              selected: ornamentalMode
                  ? stage == kOrnamentalIntentAlreadyPlanted
                  : stage == 'planted',
              enabled: true,
              fallbackAsset: 'assets/icons/wizard/ic_tree.png',
              onTap: () => onSelect(
                ornamentalMode ? kOrnamentalIntentAlreadyPlanted : 'planted',
              ),
            ),
          ),
          // El descanso del suelo (fallow) NO aplica al tulipán ni al girasol:
          // su cierre es dormancia (bulbo) o cycle_complete (anual), no suelo en
          // reposo. Por eso ambos modos ocultan esta tercera opción, igual que
          // el ornamental.
          if (!ornamentalMode &&
              !seasonalBulbMode &&
              !annualOrnamentalMode) ...[
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
          ],
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
    this.firstDate,
    this.lastDate,
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
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final defaultFirstDate = DateTime(2020);
    final defaultLastDate = DateTime(2100);
    final effectiveFirstDate =
        firstDate ??
        (selectedDate.isBefore(defaultFirstDate)
            ? selectedDate
            : defaultFirstDate);
    final effectiveLastDate =
        lastDate ??
        (selectedDate.isAfter(defaultLastDate)
            ? selectedDate
            : defaultLastDate);
    final hasExplicitBounds = firstDate != null || lastDate != null;
    final effectiveSelectedDate = !hasExplicitBounds
        ? selectedDate
        : selectedDate.isBefore(effectiveFirstDate)
        ? effectiveFirstDate
        : selectedDate.isAfter(effectiveLastDate)
        ? effectiveLastDate
        : selectedDate;
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
                child: BioGWheelDatePicker(
                  initialDate: effectiveSelectedDate,
                  firstDate: effectiveFirstDate,
                  lastDate: effectiveLastDate,
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
                    assetPath:
                        cropIconPath ??
                        ConfigureSeedWizardAssets.categoryGeneric,
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
                        color: Colors.black.withValues(alpha: 0.58),
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

class TreeAnchorWizardOptionIds {
  const TreeAnchorWizardOptionIds._();

  static const String today = 'today';
  static const String oneWeek = 'one_week';
  static const String twoThreeWeeks = 'two_three_weeks';
  static const String oneMonth = 'one_month';
  static const String thisWeek = 'this_week';
  static const String lessThanOneMonth = 'less_than_one_month';
  static const String oneToThreeMonths = 'one_to_three_months';
  static const String threeToSixMonths = 'three_to_six_months';
  static const String unknown = 'unknown';
  static const String custom = 'custom';

  // ── Ancla de inicio de etapa (rama productiva / primera floración, 3B) ──────
  static const String twoWeeks = 'two_weeks';

  // ── Ancla de plantación (rama "solo creciendo", 3A) ─────────────────────────
  static const String plantedThisMonth = 'planted_this_month';
  static const String plantedSixMonths = 'planted_six_months';
  static const String plantedOneYear = 'planted_one_year';
  static const String plantedTwoYearsPlus = 'planted_two_years_plus';
}

/// Señal reproductiva visible para árboles que "todavía no producen" (Pantalla
/// 2B). Solo dirige el ruteo del wizard; no se persiste en el contexto.
class TreeReproSignalOptionIds {
  const TreeReproSignalOptionIds._();

  static const String growingOnly = 'growing_only';
  static const String hasFlower = 'has_flower';
  static const String hasFruitSet = 'has_fruit_set';
  static const String hasFruitFill = 'has_fruit_fill';
  static const String notSure = 'not_sure';
}

/// Traduce una señal reproductiva (Pantalla 2B) a la etapa fenológica visible
/// que debe alimentar a [resolveTreeVisibleStageSelection]. Devuelve `null`
/// cuando el arbol "solo esta creciendo" o el agricultor no esta seguro. El
/// caller distingue `notSure` con [treeReproSignalIsUnknown]; solo
/// `growingOnly` usa la rama de fecha de plantacion.
String? treeReproSignalVisibleStageId(String? signalId) {
  return switch (signalId) {
    TreeReproSignalOptionIds.hasFlower => TreeStageIds.flowering,
    TreeReproSignalOptionIds.hasFruitSet => TreeStageIds.fruitSet,
    TreeReproSignalOptionIds.hasFruitFill => TreeStageIds.fruitFill,
    _ => null,
  };
}

bool treeReproSignalIsUnknown(String? signalId) {
  return signalId == TreeReproSignalOptionIds.notSure;
}

String treeReproSignalIconPath(String? signalId) {
  return switch (signalId) {
    TreeReproSignalOptionIds.growingOnly =>
      ConfigureSeedWizardAssets.treeGrowingOnly,
    TreeReproSignalOptionIds.hasFlower =>
      ConfigureSeedWizardAssets.treeHasFlower,
    TreeReproSignalOptionIds.hasFruitSet =>
      ConfigureSeedWizardAssets.treeTinyFruit,
    TreeReproSignalOptionIds.hasFruitFill =>
      ConfigureSeedWizardAssets.treeFruitGrowing,
    _ => ConfigureSeedWizardAssets.treeUnknownState,
  };
}

/// Resuelve la fecha de una opción rápida de anclaje. En la rama de plantación
/// (3A) las opciones son antigüedades del árbol; en la de inicio de etapa (3B)
/// son tiempos relativos cortos. Devuelve `null` para opciones sin fecha
/// directa (`unknown`/`custom`) o no reconocidas. Pura y testeable.
DateTime? treeAnchorDateForOption(
  String optionId,
  DateTime now, {
  required bool isPlanting,
}) {
  if (isPlanting) {
    return switch (optionId) {
      TreeAnchorWizardOptionIds.plantedThisMonth => now.subtract(
        const Duration(days: 15),
      ),
      TreeAnchorWizardOptionIds.plantedSixMonths => now.subtract(
        const Duration(days: 182),
      ),
      TreeAnchorWizardOptionIds.plantedOneYear => now.subtract(
        const Duration(days: 365),
      ),
      TreeAnchorWizardOptionIds.plantedTwoYearsPlus => now.subtract(
        const Duration(days: 800),
      ),
      _ => null,
    };
  }

  return switch (optionId) {
    TreeAnchorWizardOptionIds.today => now,
    TreeAnchorWizardOptionIds.thisWeek => now.subtract(const Duration(days: 5)),
    TreeAnchorWizardOptionIds.oneWeek => now.subtract(const Duration(days: 7)),
    TreeAnchorWizardOptionIds.twoWeeks => now.subtract(
      const Duration(days: 14),
    ),
    TreeAnchorWizardOptionIds.twoThreeWeeks => now.subtract(
      const Duration(days: 18),
    ),
    TreeAnchorWizardOptionIds.oneMonth => now.subtract(
      const Duration(days: 30),
    ),
    _ => null,
  };
}

class TreeStatePage extends StatelessWidget {
  const TreeStatePage({
    super.key,
    required this.productionStatusId,
    required this.iconForStatus,
    required this.summary,
    required this.onSelect,
  });

  final String? productionStatusId;
  final String Function(String statusId) iconForStatus;
  final Widget? summary;
  final ValueChanged<String> onSelect;

  static const List<_TreeWizardOptionData> _options = <_TreeWizardOptionData>[
    _TreeWizardOptionData(
      id: TreeProductionStatusIds.nonProductive,
      title: 'Todavía no',
      subtitle: 'Es un árbol joven.',
      iconPath: ConfigureSeedWizardAssets.treeYoungNotFruiting,
    ),
    _TreeWizardOptionData(
      id: TreeProductionStatusIds.productiveOrProduced,
      title: 'Sí, ya produce',
      subtitle: 'o ya ha dado antes.',
      iconPath: ConfigureSeedWizardAssets.categoryTree,
    ),
    _TreeWizardOptionData(
      id: TreeProductionStatusIds.unknown,
      title: 'No estoy seguro',
      subtitle:
          'BIO-G usará un perfil general y ajustará la interpretación con los sensores.',
      iconPath: ConfigureSeedWizardAssets.treeUnknownState,
    ),
  ];

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
              '¿Tu árbol ya da fruta?',
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
          ..._options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: StaggerIn(
                delay: 90 + index * 45,
                child: WizardLongPill(
                  iconPath: iconForStatus(option.id),
                  title: option.title,
                  subtitle: option.subtitle,
                  selected: productionStatusId == option.id,
                  enabled: true,
                  onTap: () => onSelect(option.id),
                ),
              ),
            );
          }),
          if (summary != null) ...[
            const SizedBox(height: 4),
            StaggerIn(delay: 340, child: summary!),
          ],
        ],
      ),
    );
  }
}

/// Wizard visual "¿Cómo está tu <planta> ahora?" para ornamentales de floración
/// recurrente (rosal hoy; tulipán y otras después). Config-driven: recibe la
/// lista de opciones desde `recurringBloomVisualStateOptions(cropId)`, así que no
/// codifica ninguna planta en concreto.
class RecurringBloomStatePage extends StatelessWidget {
  const RecurringBloomStatePage({
    super.key,
    required this.question,
    required this.helper,
    required this.options,
    required this.selectedOptionId,
    required this.summary,
    required this.onSelect,
  });

  final String question;
  final String helper;
  final List<RecurringBloomStateOption> options;
  final String? selectedOptionId;
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
              question,
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
          if (helper.isNotEmpty) ...[
            const SizedBox(height: 10),
            StaggerIn(
              delay: 40,
              child: Text(
                helper,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: Color(0xFF6B7A77),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: StaggerIn(
                delay: 90 + (index.clamp(0, 8)) * 35,
                child: WizardLongPill(
                  iconPath: option.iconPath,
                  title: option.title,
                  subtitle: option.subtitle,
                  selected: selectedOptionId == option.id,
                  enabled: true,
                  onTap: () => onSelect(option.id),
                ),
              ),
            );
          }),
          if (summary != null) ...[
            const SizedBox(height: 4),
            StaggerIn(delay: 390, child: summary!),
          ],
        ],
      ),
    );
  }
}

class TreePhenologyStagePage extends StatelessWidget {
  const TreePhenologyStagePage({
    super.key,
    required this.productionStatusId,
    required this.stageId,
    required this.iconForStage,
    required this.summary,
    required this.onSelect,
  });

  final String? productionStatusId;
  final String? stageId;
  final String Function(String stageId) iconForStage;
  final Widget? summary;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = _optionsForProductionStatus(productionStatusId);

    return CenteredWizardPage(
      scrollable: true,
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(),
          const SizedBox(height: 22),
          const StaggerIn(
            delay: 0,
            child: Text(
              '¿Cómo se ve tu árbol hoy?',
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
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: StaggerIn(
                delay: 90 + (index.clamp(0, 8)) * 35,
                child: WizardLongPill(
                  iconPath: iconForStage(option.id),
                  title: option.title,
                  subtitle: option.subtitle,
                  selected: stageId == option.id,
                  enabled: true,
                  onTap: () => onSelect(option.id),
                ),
              ),
            );
          }),
          if (summary != null) ...[
            const SizedBox(height: 4),
            StaggerIn(delay: 390, child: summary!),
          ],
        ],
      ),
    );
  }

  static List<_TreeWizardOptionData> _optionsForProductionStatus(
    String? productionStatusId,
  ) {
    switch (normalizeTreeProductionStatusId(productionStatusId)) {
      case TreeProductionStatusIds.nonProductive:
        return const <_TreeWizardOptionData>[
          _TreeWizardOptionData(
            id: TreeStageIds.plantingTransplant,
            title: 'Recién plantado o trasplantado',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeYoungNotFruiting,
          ),
          _TreeWizardOptionData(
            id: TreeStageIds.rootEstablishment,
            title: 'Se está estableciendo / agarrando raíz',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeYoungNotFruiting,
          ),
          _TreeWizardOptionData(
            id: TreeStageIds.juvenileVegetative,
            title: 'Está creciendo con hojas nuevas',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
          ),
          _TreeWizardOptionData(
            id: TreeStageIds.dormancy,
            title: 'Está sin hojas / en reposo',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeDormantLeafless,
          ),
          _TreeWizardOptionData(
            id: TreeStageIds.unknown,
            title: 'No lo sé',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeUnknownState,
          ),
        ];
      case TreeProductionStatusIds.productiveOrProduced:
        return const <_TreeWizardOptionData>[
          _TreeWizardOptionData(
            id: TreeStageIds.dormancy,
            title: 'En reposo / Sin hojas',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeDormantLeafless,
          ),
          _TreeWizardOptionData(
            id: TreeStageIds.budbreak,
            title: 'Brotando / Sacando hojitas',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeBudding,
          ),
          _TreeWizardOptionData(
            id: TreeStageIds.vegetativeGrowth,
            title: 'Puro follaje / Lleno de hoja',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeFullFoliage,
          ),
          _TreeWizardOptionData(
            id: TreeStageIds.flowering,
            title: 'En floración',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeFlowering,
          ),
          _TreeWizardOptionData(
            id: TreeStageIds.fruitSet,
            title: 'Frutito amarrado / Tirando flor',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeFruitSetFlowerDrop,
          ),
          _TreeWizardOptionData(
            id: TreeStageIds.fruitFill,
            title: 'Fruto verde / Creciendo',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeGreenFruitGrowing,
          ),
          _TreeWizardOptionData(
            id: TreeStageIds.harvestMaturity,
            title: 'Listo para la pisca / Cosecha',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeReadyHarvest,
          ),
          _TreeWizardOptionData(
            id: TreeStageIds.postHarvest,
            title: 'Acabo de cosechar',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeAfterHarvest,
          ),
          _TreeWizardOptionData(
            id: TreeStageIds.unknown,
            title: 'No lo sé',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeUnknownState,
          ),
        ];
      case TreeProductionStatusIds.unknown:
        return const <_TreeWizardOptionData>[
          _TreeWizardOptionData(
            id: TreeStageIds.unknown,
            title: 'No lo sé',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeUnknownState,
          ),
        ];
      default:
        return const <_TreeWizardOptionData>[];
    }
  }
}

/// Pantalla 2B — Señal reproductiva. Solo se muestra cuando el agricultor dijo
/// que el árbol "todavía no" produce, para blindar el caso de primera floración
/// (un árbol que nunca dio fruta pero ya está reproductivo este año).
///
/// BLOQUE REMOVIBLE: si se decide shipear estricto a 3 pantallas, elimina esta
/// página y rutea "Todavía no" directo a la fecha de plantación (3A).
class TreeReproSignalPage extends StatelessWidget {
  const TreeReproSignalPage({
    super.key,
    required this.selectedOptionId,
    required this.iconForSignal,
    required this.summary,
    required this.onSelect,
  });

  final String? selectedOptionId;
  final String Function(String signalId) iconForSignal;
  final Widget? summary;
  final ValueChanged<String> onSelect;

  static const List<_TreeWizardOptionData> _options = <_TreeWizardOptionData>[
    _TreeWizardOptionData(
      id: TreeReproSignalOptionIds.growingOnly,
      title: 'No, solo está creciendo',
      subtitle: '',
      iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
    ),
    _TreeWizardOptionData(
      id: TreeReproSignalOptionIds.hasFlower,
      title: 'Sí, tiene flor',
      subtitle: '',
      iconPath: ConfigureSeedWizardAssets.treeHasFlower,
    ),
    _TreeWizardOptionData(
      id: TreeReproSignalOptionIds.hasFruitSet,
      title: 'Sí, tiene frutito chiquito',
      subtitle: '',
      iconPath: ConfigureSeedWizardAssets.treeTinyFruit,
    ),
    _TreeWizardOptionData(
      id: TreeReproSignalOptionIds.hasFruitFill,
      title: 'Sí, fruto creciendo',
      subtitle: '',
      iconPath: ConfigureSeedWizardAssets.treeFruitGrowing,
    ),
    _TreeWizardOptionData(
      id: TreeReproSignalOptionIds.notSure,
      title: 'No estoy seguro',
      subtitle: '',
      iconPath: ConfigureSeedWizardAssets.treeUnknownState,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CenteredWizardPage(
      scrollable: true,
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(),
          const SizedBox(height: 22),
          const StaggerIn(
            delay: 0,
            child: Text(
              '¿Ahorita le ves flor o frutito?',
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
          ..._options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: StaggerIn(
                delay: 90 + index * 40,
                child: WizardLongPill(
                  iconPath: iconForSignal(option.id),
                  title: option.title,
                  subtitle: option.subtitle,
                  selected: selectedOptionId == option.id,
                  enabled: true,
                  onTap: () => onSelect(option.id),
                ),
              ),
            );
          }),
          if (summary != null) ...[
            const SizedBox(height: 4),
            StaggerIn(delay: 320, child: summary!),
          ],
        ],
      ),
    );
  }
}

class TreeAnchorPage extends StatelessWidget {
  const TreeAnchorPage({
    super.key,
    required this.stateId,
    required this.stageId,
    required this.anchorTypeId,
    required this.selectedOptionId,
    required this.selectedDate,
    required this.cropIconPath,
    required this.summary,
    required this.saving,
    required this.onSelectOption,
    required this.onDateChanged,
    required this.onSave,
  });

  final String? stateId;
  final String? stageId;
  final String? anchorTypeId;
  final String? selectedOptionId;
  final DateTime selectedDate;
  final String cropIconPath;
  final Widget? summary;
  final bool saving;
  final ValueChanged<String> onSelectOption;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback? onSave;

  /// Rama 3A: el anclaje es la fecha de plantación (el estado/etapa se derivan
  /// de la antigüedad). Las demás ramas anclan el inicio de la etapa visible.
  bool get _isPlantingAnchor =>
      (anchorTypeId ?? '').trim().toLowerCase() == TreeAnchorTypeIds.planting;

  // El perfil general (sin fecha) solo aplica a la rama de inicio de etapa
  // cuando la etapa visible es desconocida; nunca en la rama de plantación.
  bool get _isUnknownStage =>
      !_isPlantingAnchor &&
      normalizeTreeStageId(stageId) == TreeStageIds.unknown;

  String get _title {
    if (_isUnknownStage) return 'Seguimiento general del árbol';
    if (_isPlantingAnchor) return '¿Cuándo lo plantaste en tierra?';
    return switch (normalizeTreeStageId(stageId)) {
      TreeStageIds.flowering => '¿Hace cuánto notaste la flor?',
      TreeStageIds.dormancy => '¿Hace cuánto tiró la hoja?',
      TreeStageIds.harvestMaturity => '¿Hace cuánto cosechaste?',
      TreeStageIds.postHarvest => '¿Hace cuánto cosechaste?',
      _ => '¿Hace cuánto empezó a verse así?',
    };
  }

  String get _subtitle {
    if (_isUnknownStage) {
      return 'BIO-G usará ajustes generales, sin fecha de etapa.';
    }
    if (_isPlantingAnchor) {
      return 'Con esto BIO-G calcula la edad y la etapa aproximada del árbol.';
    }
    return 'Esta fecha se guarda como anclaje de etapa, no como edad del árbol.';
  }

  List<_TreeWizardOptionData> get _options {
    if (_isUnknownStage) return const <_TreeWizardOptionData>[];
    if (_isPlantingAnchor) {
      return const <_TreeWizardOptionData>[
        _TreeWizardOptionData(
          id: TreeAnchorWizardOptionIds.custom,
          title: 'Elegir fecha exacta',
          subtitle: '',
          iconPath: ConfigureSeedWizardAssets.exactDateCalendarClock,
        ),
        _TreeWizardOptionData(
          id: TreeAnchorWizardOptionIds.plantedThisMonth,
          title: 'Apenas este mes',
          subtitle: '',
          iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
        ),
        _TreeWizardOptionData(
          id: TreeAnchorWizardOptionIds.plantedSixMonths,
          title: 'Hace unos 6 meses',
          subtitle: '',
          iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
        ),
        _TreeWizardOptionData(
          id: TreeAnchorWizardOptionIds.plantedOneYear,
          title: 'Hace 1 año',
          subtitle: '',
          iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
        ),
        _TreeWizardOptionData(
          id: TreeAnchorWizardOptionIds.plantedTwoYearsPlus,
          title: 'Hace 2 años o más',
          subtitle: '',
          iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
        ),
        _TreeWizardOptionData(
          id: TreeAnchorWizardOptionIds.unknown,
          title: 'No lo recuerdo',
          subtitle: '',
          iconPath: ConfigureSeedWizardAssets.treeUnknownState,
        ),
      ];
    }
    return const <_TreeWizardOptionData>[
      _TreeWizardOptionData(
        id: TreeAnchorWizardOptionIds.custom,
        title: 'Elegir fecha exacta',
        subtitle: '',
        iconPath: ConfigureSeedWizardAssets.exactDateCalendarClock,
      ),
      _TreeWizardOptionData(
        id: TreeAnchorWizardOptionIds.thisWeek,
        title: 'Apenas esta semana',
        subtitle: '',
        iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
      ),
      _TreeWizardOptionData(
        id: TreeAnchorWizardOptionIds.twoWeeks,
        title: 'Hace unas 2 semanas',
        subtitle: '',
        iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
      ),
      _TreeWizardOptionData(
        id: TreeAnchorWizardOptionIds.oneMonth,
        title: 'Hace 1 mes',
        subtitle: '',
        iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
      ),
    ];
  }

  String _iconForAnchorOption(String optionId, String fallbackIconPath) {
    switch (optionId) {
      case TreeAnchorWizardOptionIds.custom:
        return fallbackIconPath;
      case TreeAnchorWizardOptionIds.unknown:
        return ConfigureSeedWizardAssets.treeUnknownState;
      default:
        return _isPlantingAnchor
            ? ConfigureSeedWizardAssets.treeGrowingOnly
            : ConfigureSeedWizardAssets.treeStageIconFor(stageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showCalendar = selectedOptionId == TreeAnchorWizardOptionIds.custom;

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
              _title,
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
              _subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.4,
                height: 1.34,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: 24),
          for (final entry in _options.asMap().entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: StaggerIn(
                delay: 90 + (entry.key.clamp(0, 7)) * 40,
                child: WizardLongPill(
                  iconPath: _iconForAnchorOption(
                    entry.value.id,
                    entry.value.iconPath,
                  ),
                  title: entry.value.title,
                  subtitle: entry.value.subtitle,
                  selected: selectedOptionId == entry.value.id,
                  enabled: true,
                  onTap: () => onSelectOption(entry.value.id),
                ),
              ),
            ),
            // El selector se muestra justo debajo de "Elegir fecha exacta".
            if (showCalendar &&
                entry.value.id == TreeAnchorWizardOptionIds.custom) ...[
              StaggerIn(
                delay: 130,
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
                    child: BioGWheelDatePicker(
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      onDateChanged: onDateChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
          const SizedBox(height: 14),
          StaggerIn(
            delay: 360,
            child: BioGGlassCard(
              radius: 22,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WizardAssetIcon(
                    assetPath: cropIconPath,
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
                      'BIO-G interpretara tus sensores segun el estado y etapa visible del arbol.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.black.withValues(alpha: 0.58),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (summary != null) ...[
            const SizedBox(height: 16),
            StaggerIn(delay: 410, child: summary!),
          ],
          const SizedBox(height: 18),
          StaggerIn(
            delay: 460,
            child: BioGButton(
              label: 'Guardar configuracion',
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

class _TreeWizardOptionData {
  const _TreeWizardOptionData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconPath,
  });

  final String id;
  final String title;
  final String subtitle;
  final String iconPath;
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
          color: Colors.black.withValues(alpha: 0.32),
        ),
      ),
    );
  }
}
