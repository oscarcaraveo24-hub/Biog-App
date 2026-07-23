import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/apple_tree/apple_tree_assets.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/core/crops/maize/maize_catalog.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_assets.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_assets.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_assets.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_assets.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_assets.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_assets.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_assets.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_assets.dart';
import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/recurring_bloom/recurring_bloom_crops.dart';
// Tulipán (seasonal_bulb): capa compartida del modo bulboso estacional.
import 'package:bio_g/core/crops/seasonal_bulb/seasonal_bulb_crops.dart';
// Girasol (annual_ornamental): capa compartida del modo anual ornamental.
import 'package:bio_g/core/crops/annual_ornamental/annual_ornamental_crops.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/tree_profile_presentation.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_components.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_dialogs.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_pages.dart';
import 'package:bio_g/widgets/account/wizard/wizard_crop_context_resolver.dart';

enum WizardPage {
  category,
  cropVariety,
  brand,
  variety,
  stage,
  recurringBloomState,
  date,
  treeState,
  treeReproSignal,
  treePhenology,
  treeAnchor,
}

class ConfigureSeedWizardScreen extends StatefulWidget {
  final Future<void> Function()? onCompleted;

  const ConfigureSeedWizardScreen({super.key, this.onCompleted});

  @override
  State<ConfigureSeedWizardScreen> createState() =>
      _ConfigureSeedWizardScreenState();
}

class _ConfigureSeedWizardScreenState extends State<ConfigureSeedWizardScreen> {
  static const WizardCropContextResolver _contextResolver =
      WizardCropContextResolver();

  static const String _genericCropIconPath =
      'assets/icons/wizard/ic_planta_generica.png';

  WizardPage _page = WizardPage.category;

  String? _category;
  String? _crop;
  String? _brandId;
  String? _varietyId;
  String? _stage;
  String? _treeProductionStatusId;
  // Selección de la pantalla 2B (señal reproductiva). Solo dirige el ruteo de
  // UI; no se persiste en DeviceCropContext.
  String? _treeReproSignalId;
  String? _perennialStateId;
  String? _phenologyStageId;
  String? _treeAnchorOptionId;
  String? _perennialAnchorTypeId;
  DateTime? _perennialAnchorDate;

  DateTime _selectedDate = DateTime.now();
  bool _useFlexibleDate = false;
  bool _saving = false;
  bool _didShowIntro = false;

  /// Whether the current crop uses the brand→variety flow (only maize for now).
  bool get _cropUsesBrands => _crop == CropCatalog.maizeCropId;

  bool get _isTreeWizard =>
      isTreeCrop(cropId: _crop, cropCategoryId: _category);

  /// Ornamental (establishment_maintenance): mismo flujo sencillo que el
  /// onboarding (categoría → planta → tipo → estado → fecha).
  bool get _isOrnamentalWizard =>
      isEstablishmentMaintenanceCrop(cropId: _crop, cropCategoryId: _category);

  /// cropId canónico de la ornamental (para textos y assets con su género).
  String? get _ornamentalCropId => ornamentalCropIdOrNull(_crop);

  bool get _isOrnamentalFutureIntent =>
      _isOrnamentalWizard &&
      ornamentalSetupIntentRequiresFutureDate(_ornamentalCropId, _stage);

  /// Ornamental de floración recurrente (rosal): flujo con selección VISUAL de
  /// estado. Mismo número de pasos que una ornamental (categoría → planta+perfil
  /// → estado visual → fecha).
  bool get _isRecurringBloomWizard =>
      isRecurringBloomCrop(cropId: _crop, cropCategoryId: _category);

  /// Opción de estado visual seleccionada (guardada en `_stage`).
  RecurringBloomStateOption? get _selectedRecurringBloomOption {
    if (!_isRecurringBloomWizard || _stage == null) return null;
    for (final option in recurringBloomVisualStateOptions(_crop)) {
      if (option.id == _stage) return option;
    }
    return null;
  }

  bool get _isRecurringBloomFutureIntent =>
      _isRecurringBloomWizard &&
      (_selectedRecurringBloomOption?.requiresFutureDate ?? false);

  /// Tulipán (seasonal_bulb): ornamental bulbosa estacional. Elige PERFIL como
  /// una ornamental, pero su alta/fecha/persistencia siguen la ruta de GRANO
  /// (ancla real: conserva el sowingDate). Por eso NO es `_isOrnamentalWizard`.
  bool get _isSeasonalBulbWizard =>
      isSeasonalBulbCrop(cropId: _crop, cropCategoryId: _category);

  /// cropId canónico del bulboso estacional (para textos e íconos).
  String? get _seasonalBulbCropId => seasonalBulbCropIdOrNull(_crop);

  /// Girasol (annual_ornamental): ornamental anual verdadera. Elige PERFIL como
  /// una ornamental, pero su alta/fecha/persistencia siguen la ruta de GRANO
  /// (ancla real: conserva el sowingDate). Por eso NO es `_isOrnamentalWizard`.
  bool get _isAnnualOrnamentalWizard =>
      isAnnualOrnamentalCrop(cropId: _crop, cropCategoryId: _category);

  /// cropId canónico de la ornamental anual (para textos e íconos).
  String? get _annualOrnamentalCropId => annualOrnamentalCropIdOrNull(_crop);

  int get _totalSteps => _isTreeWizard ? 5 : (_cropUsesBrands ? 5 : 4);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateFromActiveContext();
      _showIntroIfNeeded();
    });
  }

  Future<void> _showIntroIfNeeded() async {
    if (!mounted || _didShowIntro) return;
    _didShowIntro = true;

    await showWizardAnimatedDialog(
      context: context,
      barrierLabel: 'Configurar cultivo',
      title: 'Configurar cultivo',
      message:
          'Define el contexto agronómico de este BioG para que Dashboard, historial y alertas se adapten a tu cultivo.',
      iconAssetPath: ConfigureSeedWizardAssets.introIcon,
      iconTint: const Color(0xFF198B64),
      actionLabel: 'Entendido',
      iconBaseScale: .7,
      barrierOpacity: 0.34,
    );
  }

  void _hydrateFromActiveContext() {
    if (!mounted) return;

    final store = BioGScope.of(context);
    final cropContext = store.activeCropContext;
    if (cropContext == null) return;

    final category = cropContext.cropCategoryId.trim().isEmpty
        ? CropCatalog.grainCategoryId
        : cropContext.cropCategoryId.trim();

    final crop = _normalizeCropId(cropContext.cropId);
    final isTreeContext = isTreeCrop(cropId: crop, cropCategoryId: category);
    final isOrnamentalCtx = isEstablishmentMaintenanceCrop(
      cropId: crop,
      cropCategoryId: category,
    );

    String? stage;
    DateTime selectedDate = DateTime.now();
    bool flexibleDate = false;

    switch (cropContext.lifecycleStatus) {
      case CropLifecycleStatus.fallow:
        // Compatibilidad de entrada: una ornamental legacy en fallow se restaura
        // como planta activa con datos por confirmar, nunca como descanso.
        if (isOrnamentalCtx) {
          stage = kOrnamentalIntentAlreadyPlanted;
          selectedDate = cropContext.ornamentalAnchorDate ?? DateTime.now();
          flexibleDate = cropContext.ornamentalAnchorDate == null;
        } else {
          stage = 'skip';
          flexibleDate = false;
        }
        break;
      case CropLifecycleStatus.planned:
        stage = isOrnamentalCtx ? kOrnamentalIntentPlannedPlant : 'planned';
        selectedDate =
            (isOrnamentalCtx
                ? cropContext.ornamentalAnchorDate
                : cropContext.plannedSowingDate) ??
            DateTime.now();
        if (isOrnamentalCtx && !selectedDate.isAfter(DateTime.now())) {
          selectedDate = DateTime.now().add(const Duration(days: 1));
        }
        flexibleDate = isOrnamentalCtx
            ? cropContext.ornamentalAnchorDateConfidence !=
                      DateConfidence.exact ||
                  cropContext.ornamentalAnchorDate == null
            : cropContext.sowingDateConfidence != DateConfidence.exact ||
                  cropContext.plannedSowingDate == null;
        break;
      case CropLifecycleStatus.planted:
        if (isOrnamentalCtx) {
          // Un contexto guardado con `repot` se reabre como "ya está plantada":
          // un cambio de maceta no es una forma de dar de alta la planta.
          stage = kOrnamentalIntentAlreadyPlanted;
        } else {
          stage = 'planted';
        }
        selectedDate = isOrnamentalCtx
            ? (cropContext.ornamentalAnchorDate ?? DateTime.now())
            : isTreeContext
            ? (cropContext.perennialAnchorDate ?? DateTime.now())
            : (cropContext.sowingDate ?? DateTime.now());
        flexibleDate = isOrnamentalCtx
            ? cropContext.ornamentalAnchorDate == null
            : isTreeContext
            ? cropContext.perennialAnchorDate == null
            : cropContext.sowingDateConfidence != DateConfidence.exact;
        break;
    }

    // Rosal (floración recurrente): reabre el estado VISUAL guardado. El id de
    // la opción coincide con el id de etapa recurrente; el establecimiento y el
    // "no estoy seguro" mapean a sus opciones dedicadas.
    final bool isRecurringBloomCtx = isRecurringBloomCrop(
      cropId: crop,
      cropCategoryId: category,
    );
    if (isRecurringBloomCtx) {
      final storedStage = normalizeRecurringBloomStageId(
        crop,
        cropContext.ornamentalStageId,
      );
      if (cropContext.lifecycleStatus == CropLifecycleStatus.planned) {
        stage = 'planned';
        selectedDate = cropContext.ornamentalAnchorDate ?? DateTime.now();
        if (!selectedDate.isAfter(DateTime.now())) {
          selectedDate = DateTime.now().add(const Duration(days: 1));
        }
      } else if (storedStage == 'installation_establishment' ||
          storedStage == 'root_establishment') {
        stage = 'recently_planted';
        selectedDate = cropContext.ornamentalAnchorDate ?? DateTime.now();
      } else if (storedStage == 'unknown') {
        stage = 'unsure';
        selectedDate = cropContext.ornamentalAnchorDate ?? DateTime.now();
      } else {
        stage = storedStage;
        selectedDate = cropContext.ornamentalAnchorDate ?? DateTime.now();
      }
      flexibleDate = cropContext.ornamentalAnchorDate == null;
    }

    final varietyId = crop == null
        ? null
        : _resolveWizardVarietySelectionFromContext(cropContext, crop);

    // Resolve brandId from the variety entry or from the saved context.
    String? brandId = cropContext.brandId;
    if (brandId == null && varietyId != null && crop != null) {
      final variety = CropCatalog.varietyById(crop, varietyId);
      brandId = variety?.brandId;
    }

    setState(() {
      _category = category;
      _crop = crop;
      _brandId = stage == 'skip' ? null : brandId;
      _varietyId = stage == 'skip' ? null : varietyId;
      _stage = stage;
      _selectedDate = selectedDate;
      _useFlexibleDate = flexibleDate;
      _perennialStateId = isTreeContext
          ? normalizeTreeStateId(cropContext.perennialStateId)
          : null;
      _phenologyStageId = isTreeContext
          ? safeTreeStageForState(
              perennialStateId: cropContext.perennialStateId,
              phenologyStageId: cropContext.phenologyStageId,
            )
          : null;
      _treeProductionStatusId = isTreeContext
          ? inferTreeProductionStatusId(
              perennialStateId: cropContext.perennialStateId,
              phenologyStageId: cropContext.phenologyStageId,
            )
          : null;
      _treeAnchorOptionId = isTreeContext
          ? (cropContext.perennialAnchorDate == null
                ? TreeAnchorWizardOptionIds.unknown
                : TreeAnchorWizardOptionIds.custom)
          : null;
      _perennialAnchorDate = isTreeContext
          ? cropContext.perennialAnchorDate
          : null;
      _perennialAnchorTypeId = isTreeContext
          ? (cropContext.perennialAnchorTypeId ?? TreeAnchorTypeIds.unknown)
          : null;
    });
  }

  Future<void> _showSuccessDialog() async {
    if (!mounted) return;

    await showWizardAnimatedDialog(
      context: context,
      barrierLabel: 'Guardado',
      title: 'Cambios guardados',
      message: 'Tu configuración se guardó con éxito.',
      iconAssetPath: ConfigureSeedWizardAssets.successIcon,
      actionLabel: 'Perfecto',
      iconBaseScale: 2.4,
      barrierOpacity: 0.30,
    );
  }

  int get _currentStepIndex {
    switch (_page) {
      case WizardPage.category:
        return 0;
      case WizardPage.cropVariety:
        return 1;
      case WizardPage.brand:
        return 1;
      case WizardPage.variety:
        return 2;
      case WizardPage.stage:
        return _cropUsesBrands ? 3 : 2;
      case WizardPage.recurringBloomState:
        return 2;
      case WizardPage.date:
        return _cropUsesBrands ? 4 : 3;
      case WizardPage.treeState:
        return 2;
      case WizardPage.treeReproSignal:
        return 3;
      case WizardPage.treePhenology:
        return 3;
      case WizardPage.treeAnchor:
        return 4;
    }
  }

  String get _dateQuestionTitle {
    if (_isRecurringBloomWizard) {
      return recurringBloomDateQuestionTitle(
        _crop,
        _selectedRecurringBloomOption?.intentId,
      );
    }
    if (_isOrnamentalWizard) {
      return ornamentalDateQuestionTitle(_ornamentalCropId, _stage);
    }
    if (_stage == 'planned') {
      return '¿Tienes una fecha\nestimada para sembrar?';
    }
    if (_stage == 'planted') {
      return '¿Recuerdas aproximadamente\ncuándo sembraste?';
    }
    return 'Fecha';
  }

  String get _dateFlexibleLabel {
    if (_isRecurringBloomWizard) {
      return recurringBloomDateFlexibleLabel(
        _crop,
        _selectedRecurringBloomOption?.intentId,
      );
    }
    if (_isOrnamentalWizard) {
      return ornamentalDateFlexibleLabel(_ornamentalCropId, _stage);
    }
    if (_stage == 'planned') {
      return 'No tengo fecha aún';
    }
    if (_stage == 'planted') {
      return 'No lo recuerdo muy bien';
    }
    return 'No aplica';
  }

  String get _dateFlexibleDescription {
    if (_isRecurringBloomWizard) {
      return recurringBloomDateFlexibleDescription(
        _crop,
        _selectedRecurringBloomOption?.intentId,
      );
    }
    if (_isOrnamentalWizard) {
      return ornamentalDateFlexibleDescription(_ornamentalCropId, _stage);
    }
    if (_stage == 'planned') {
      return 'Bio-G usará una referencia flexible y podrás actualizarla después.';
    }
    if (_stage == 'planted') {
      return 'Usaremos la fecha seleccionada como aproximada para interpretar mejor tu etapa.';
    }
    return '';
  }

  String get _dateHelperText {
    if (_isRecurringBloomWizard) {
      return recurringBloomDateHelperText(
        _crop,
        _selectedRecurringBloomOption?.intentId,
      );
    }
    if (_isOrnamentalWizard) {
      return ornamentalDateHelperText(_ornamentalCropId, _stage);
    }
    if (_stage == 'planned') {
      return 'Indicar una fecha nos ayuda a ajustar mejor las recomendaciones de Bio-G. Puede cambiarse en cualquier momento.';
    }
    return 'Indicar una fecha nos ayuda a ajustar mejor las recomendaciones de Bio-G. Si no lo recuerdas, coloca una fecha aproximada para darte los mejores resultados. Puede cambiarse en cualquier momento.';
  }

  @override
  Widget build(BuildContext context) {
    final store = BioGScope.of(context);
    final device = store.activeDevice;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: device == null
          ? const SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No hay dispositivo activo.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  WizardTopChrome(
                    showBack: _page != WizardPage.category,
                    currentIndex: _currentStepIndex,
                    totalSteps: _totalSteps,
                    onBack: _handleBack,
                    onClose: () {
                      final navigator = Navigator.of(context);
                      if (navigator.canPop()) {
                        navigator.pop();
                      }
                    },
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        final children = <Widget>[...previousChildren];

                        if (currentChild != null) {
                          children.add(currentChild);
                        }

                        return Stack(
                          alignment: Alignment.topCenter,
                          children: children,
                        );
                      },
                      transitionBuilder: (child, animation) {
                        final fade = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        );

                        final scale = Tween<double>(begin: 0.985, end: 1.0)
                            .animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            );

                        return FadeTransition(
                          opacity: fade,
                          child: ScaleTransition(scale: scale, child: child),
                        );
                      },
                      child: _buildPage(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case WizardPage.category:
        return CategoryPage(
          key: const ValueKey('category'),
          category: _category,
          summary: _buildSelectionSummary(),
          onSelect: _onSelectCategory,
        );

      case WizardPage.cropVariety:
        return CropVarietyPage(
          key: const ValueKey('cropVariety'),
          categoryLabel: _categoryLabel(_category),
          cropLabel: _cropLabel(_crop),
          varietyLabel: _varietyDisplayLabel(),
          cropSelected: _crop != null,
          varietySelected: _varietyId != null,
          cropEnabled:
              _category == CropCatalog.grainCategoryId ||
              _category == CropCatalog.vegetableCategoryId ||
              _category == CropCatalog.treeCategoryId ||
              _category == CropCatalog.ornamentalCategoryId,
          isTreeFlow: _isTreeWizard,
          isOrnamentalFlow: _isOrnamentalWizard,
          ornamentalCropId: _ornamentalCropId,
          cropUsesBrands: _cropUsesBrands,
          cropIconPath: _resolvedCropIconPath,
          varietyIconPath:
              _isTreeWizard || _isOrnamentalWizard || _varietyId != null
              ? _resolvedVarietyIconPath
              : null,
          summary: _buildSelectionSummary(),
          onTapCrop: _openCropSelector,
          onTapVariety: _isTreeWizard
              ? _openTreeProfileSelector
              : _isOrnamentalWizard
              ? _openOrnamentalProfileSelector
              : _isRecurringBloomWizard
              ? _openRecurringBloomProfileSelector
              // Tulipán (seasonal_bulb): elige PERFIL como una ornamental.
              : _isSeasonalBulbWizard
              ? _openSeasonalBulbProfileSelector
              // Girasol (annual_ornamental): elige PERFIL como una ornamental.
              : _isAnnualOrnamentalWizard
              ? _openAnnualOrnamentalProfileSelector
              : (_cropUsesBrands ? _openBrandSelector : _openVarietySelector),
        );

      case WizardPage.brand:
        return BrandPage(
          key: const ValueKey('brand'),
          brands: CropCatalog.brandsForCrop(_crop ?? ''),
          selectedBrandId: _brandId,
          summary: _buildSelectionSummary(),
          onSelect: _onSelectBrand,
        );

      case WizardPage.variety:
        return VarietyPage(
          key: const ValueKey('variety'),
          varieties: _varietiesForSelectedBrand(),
          selectedVarietyId: _varietyId,
          brandLabel: _brandLabel(_brandId),
          summary: _buildSelectionSummary(),
          onSelect: _onSelectVariety,
        );

      case WizardPage.stage:
        return StagePage(
          key: const ValueKey('stage'),
          stage: _stage,
          ornamentalMode: _isOrnamentalWizard,
          ornamentalCropId: _ornamentalCropId,
          // Tulipán (seasonal_bulb): 2 opciones (planned/planted), sin fallow.
          seasonalBulbMode: _isSeasonalBulbWizard,
          seasonalBulbCropId: _seasonalBulbCropId,
          // Girasol (annual_ornamental): 2 opciones (planned/planted), sin
          // fallow.
          annualOrnamentalMode: _isAnnualOrnamentalWizard,
          annualOrnamentalCropId: _annualOrnamentalCropId,
          summary: _buildSelectionSummary(),
          onSelect: _onSelectStage,
        );

      case WizardPage.recurringBloomState:
        return RecurringBloomStatePage(
          key: const ValueKey('recurringBloomState'),
          question: recurringBloomStateQuestion(_crop),
          helper: recurringBloomStateHelper(_crop),
          options: recurringBloomVisualStateOptions(_crop),
          selectedOptionId: _stage,
          summary: _buildSelectionSummary(),
          onSelect: _onSelectRecurringBloomState,
        );

      case WizardPage.date:
        return DatePage(
          key: const ValueKey('date'),
          title: _dateQuestionTitle,
          selectedDate: _selectedDate,
          flexibleDate: _useFlexibleDate,
          flexibleLabel: _dateFlexibleLabel,
          flexibleDescription: _dateFlexibleDescription,
          helperText: _dateHelperText,
          cropIconPath: _resolvedCropIconPath,
          summary: _buildSelectionSummary(),
          saving: _saving,
          firstDate: _isOrnamentalWizard
              ? (_isOrnamentalFutureIntent
                    ? _dateOnly(DateTime.now()).add(const Duration(days: 1))
                    : DateTime(1900))
              : _isRecurringBloomWizard
              ? (_isRecurringBloomFutureIntent
                    ? _dateOnly(DateTime.now()).add(const Duration(days: 1))
                    : DateTime(1900))
              : null,
          lastDate:
              (_isOrnamentalWizard && !_isOrnamentalFutureIntent) ||
                  (_isRecurringBloomWizard && !_isRecurringBloomFutureIntent)
              ? _dateOnly(DateTime.now())
              : null,
          onDateChanged: (value) {
            setState(() {
              _selectedDate = value;
            });
          },
          onFlexibleChanged: (value) {
            setState(() {
              _useFlexibleDate = value;
            });
          },
          onSave: _saving ? null : () => _save(BioGScope.of(context)),
        );

      case WizardPage.treeState:
        return TreeStatePage(
          key: const ValueKey('treeState'),
          productionStatusId: _treeProductionStatusId,
          iconForStatus: _treeProductionStatusIcon,
          summary: _buildSelectionSummary(),
          onSelect: _onSelectTreeProductionStatus,
        );

      case WizardPage.treeReproSignal:
        return TreeReproSignalPage(
          key: const ValueKey('treeReproSignal'),
          selectedOptionId: _treeReproSignalId,
          iconForSignal: _treeReproSignalIcon,
          summary: _buildSelectionSummary(),
          onSelect: _onSelectTreeReproSignal,
        );

      case WizardPage.treePhenology:
        return TreePhenologyStagePage(
          key: const ValueKey('treePhenology'),
          productionStatusId: _treeProductionStatusId,
          stageId: _phenologyStageId,
          iconForStage: _treeStageIcon,
          summary: _buildSelectionSummary(),
          onSelect: _onSelectTreePhenologyStage,
        );

      case WizardPage.treeAnchor:
        return TreeAnchorPage(
          key: const ValueKey('treeAnchor'),
          stateId: _perennialStateId,
          stageId: _phenologyStageId,
          anchorTypeId: _perennialAnchorTypeId,
          selectedOptionId: _treeAnchorOptionId,
          selectedDate: _selectedDate,
          cropIconPath: _resolvedCropIconPath,
          summary: _buildSelectionSummary(),
          saving: _saving,
          onSelectOption: _onSelectTreeAnchorOption,
          onDateChanged: _onTreeAnchorDateChanged,
          onSave: _saving || _treeAnchorOptionId == null
              ? null
              : () => _save(BioGScope.of(context)),
        );
    }
  }

  Widget? _buildSelectionSummary() {
    final chips = <String>[];

    if (_category != null) {
      chips.add(_categoryLabel(_category));
    }
    if (_crop != null) {
      chips.add(_cropLabel(_crop));
    }

    if (_isTreeWizard) {
      if (_varietyId != null) {
        chips.add(_varietyDisplayLabel());
      }
      if (_treeProductionStatusId != null) {
        chips.add(treeProductionStatusDisplayName(_treeProductionStatusId));
      }
      if (_phenologyStageId != null) {
        chips.add(treeStageDisplayNameForCrop(_crop, _phenologyStageId));
      }
      final anchorLabel = _treeAnchorDisplayLabel(_treeAnchorOptionId);
      if (anchorLabel != null) {
        chips.add(anchorLabel);
      }

      if (chips.isEmpty) return null;

      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: chips.map((label) => MiniStateChip(label: label)).toList(),
      );
    }

    if (_brandId != null) {
      chips.add(_brandLabel(_brandId));
    }
    if (_varietyId != null) {
      chips.add(_varietyDisplayLabel());
    }
    if (_stage != null) {
      chips.add(_stageLabel(_stage));
    }

    if (chips.isEmpty) return null;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: chips.map((label) => MiniStateChip(label: label)).toList(),
    );
  }

  void _animateToPage(WizardPage page) {
    if (!mounted) return;
    setState(() {
      _page = page;
    });
  }

  void _onSelectCategory(String value) {
    if (value != CropCatalog.grainCategoryId &&
        value != CropCatalog.vegetableCategoryId &&
        value != CropCatalog.treeCategoryId &&
        value != CropCatalog.ornamentalCategoryId) {
      return;
    }

    setState(() {
      _category = value;
      _crop = null;
      _brandId = null;
      _varietyId = null;
      _stage = null;
      _selectedDate = DateTime.now();
      _useFlexibleDate = false;
      _treeProductionStatusId = null;
      _treeReproSignalId = null;
      _perennialStateId = null;
      _phenologyStageId = null;
      _treeAnchorOptionId = null;
      _perennialAnchorDate = null;
      _perennialAnchorTypeId = null;
    });

    _animateToPage(WizardPage.cropVariety);
  }

  Future<void> _openCropSelector() async {
    if (_category != CropCatalog.grainCategoryId &&
        _category != CropCatalog.vegetableCategoryId &&
        _category != CropCatalog.treeCategoryId &&
        _category != CropCatalog.ornamentalCategoryId) {
      return;
    }

    final cropOptions = CropCatalog.cropsByCategory(
      _category ?? CropCatalog.grainCategoryId,
      enabledOnly: false,
    );

    final result = await showWizardSelectionSheet<String>(
      context: context,
      title: 'Selecciona el cultivo',
      options: cropOptions
          .map(
            (crop) => WizardSheetOption<String>(
              value: crop.cropId,
              title: crop.label,
              subtitle:
                  crop.subtitle ??
                  (crop.enabled ? 'Disponible ahora' : 'Próximamente'),
              iconPath: _cropIconPath(crop.cropId),
              fallbackAsset:
                  isEstablishmentMaintenanceCrop(cropId: crop.cropId)
                  ? kOrnamentalGenericPlantFallback
                  // Tulipán (seasonal_bulb): planta genérica ornamental, no árbol.
                  : isSeasonalBulbCrop(cropId: crop.cropId)
                  ? kSeasonalBulbGenericPlantFallback
                  // Girasol (annual_ornamental): planta genérica ornamental, no
                  // árbol.
                  : isAnnualOrnamentalCrop(cropId: crop.cropId)
                  ? kAnnualOrnamentalGenericPlantFallback
                  : 'assets/icons/wizard/ic_tree.png',
              enabled: crop.enabled,
            ),
          )
          .toList(growable: false),
    );

    if (result == null) return;

    setState(() {
      _crop = result;
      _brandId = null;
      _varietyId = null;
      _stage = null;
      _selectedDate = DateTime.now();
      _useFlexibleDate = false;
      _treeProductionStatusId = null;
      _treeReproSignalId = null;
      _perennialStateId = null;
      _phenologyStageId = null;
      _treeAnchorOptionId = null;
      _perennialAnchorDate = null;
      _perennialAnchorTypeId = null;
    });
  }

  // ── Brand selector (maize) ──────────────────────────────────────────────────

  Future<void> _openBrandSelector() async {
    final cropId = _crop;
    if (cropId == null) return;

    final brands = CropCatalog.brandsForCrop(cropId);
    if (brands.isEmpty) return;

    _animateToPage(WizardPage.brand);
  }

  void _onSelectBrand(String brandId) {
    setState(() {
      _brandId = brandId;
      _varietyId = null;
      _stage = null;
      _selectedDate = DateTime.now();
      _useFlexibleDate = false;
    });

    _animateToPage(WizardPage.variety);
  }

  // ── Variety selector ────────────────────────────────────────────────────────

  Future<void> _openTreeProfileSelector() async {
    final cropId = _normalizeCropId(_crop);
    if (cropId == null ||
        !isTreeCrop(cropId: cropId, cropCategoryId: _category)) {
      return;
    }

    final profiles = CropCatalog.profilesForCrop(cropId, enabledOnly: false);
    if (profiles.isEmpty) return;
    final defaultProfileId = CropCatalog.resolveProfileId(cropId: cropId);

    // El perfil general/SKIP va al final y la pregunta habla de "variedad".
    final orderedProfiles = TreeProfilePresentation.genericLast(
      profiles,
      cropId,
    );

    final result = await showWizardSelectionSheet<String>(
      context: context,
      title: TreeProfilePresentation.varietyQuestion(cropId),
      options: orderedProfiles
          .map(
            (profile) => WizardSheetOption<String>(
              value: profile.id,
              title: _treeProfileOptionTitle(cropId, profile.id, profile.label),
              subtitle: profile.id == defaultProfileId
                  ? TreeProfilePresentation.genericOptionSubtitle
                  : (profile.subtitle ?? 'Disponible'),
              iconPath: _treeProfileIcon(cropId, profile.id),
              enabled: true,
            ),
          )
          .toList(growable: false),
    );

    if (result == null) return;

    setState(() {
      _varietyId = result;
      _stage = 'planted';
      _treeProductionStatusId = null;
      _treeReproSignalId = null;
      _perennialStateId = null;
      _phenologyStageId = null;
      _treeAnchorOptionId = null;
      _perennialAnchorDate = null;
      _perennialAnchorTypeId = null;
      _selectedDate = DateTime.now();
      _useFlexibleDate = false;
    });

    _animateToPage(WizardPage.treeState);
  }

  /// Selector de tipo de la ornamental. El perfil general va AL FINAL (así lo
  /// ordena el catálogo) y nunca se muestran códigos ni "SKIP".
  Future<void> _openOrnamentalProfileSelector() async {
    final cropId = _normalizeCropId(_crop);
    if (cropId == null ||
        !isEstablishmentMaintenanceCrop(
          cropId: cropId,
          cropCategoryId: _category,
        )) {
      return;
    }

    final profiles = CropCatalog.profilesForCrop(cropId, enabledOnly: false);
    if (profiles.isEmpty) return;
    final defaultProfileId = CropCatalog.resolveProfileId(cropId: cropId);

    final result = await showWizardSelectionSheet<String>(
      context: context,
      title: ornamentalTypeQuestion(cropId),
      options: profiles
          .map(
            (profile) => WizardSheetOption<String>(
              value: profile.id,
              title: profile.label,
              subtitle: profile.id == defaultProfileId
                  ? ornamentalGeneralProfileHint(cropId)
                  : (profile.subtitle ?? 'Disponible'),
              iconPath: ornamentalProfileIcon(cropId, profile.id),
              fallbackAsset: kOrnamentalGenericPlantFallback,
              enabled: true,
            ),
          )
          .toList(growable: false),
    );

    if (result == null) return;

    setState(() {
      _varietyId = result;
      _stage = null;
      _selectedDate = DateTime.now();
      _useFlexibleDate = false;
    });

    _animateToPage(WizardPage.stage);
  }

  /// Selector de perfil del rosal (floración recurrente). Igual patrón que el
  /// ornamental, pero con los textos/íconos del rosal. Tras elegir el perfil,
  /// pasa a la pantalla de estado VISUAL.
  Future<void> _openRecurringBloomProfileSelector() async {
    final cropId = _normalizeCropId(_crop);
    if (cropId == null ||
        !isRecurringBloomCrop(cropId: cropId, cropCategoryId: _category)) {
      return;
    }

    final profiles = CropCatalog.profilesForCrop(cropId, enabledOnly: false);
    if (profiles.isEmpty) return;
    final defaultProfileId = CropCatalog.resolveProfileId(cropId: cropId);

    final result = await showWizardSelectionSheet<String>(
      context: context,
      title: recurringBloomTypeQuestion(cropId),
      options: profiles
          .map(
            (profile) => WizardSheetOption<String>(
              value: profile.id,
              title: profile.label,
              subtitle: profile.id == defaultProfileId
                  ? recurringBloomGeneralProfileHint(cropId)
                  : (profile.subtitle ?? 'Disponible'),
              iconPath: recurringBloomProfileIcon(cropId, profile.id),
              fallbackAsset: kRecurringBloomGenericPlantFallback,
              enabled: true,
            ),
          )
          .toList(growable: false),
    );

    if (result == null) return;

    setState(() {
      _varietyId = result;
      _stage = null;
      _selectedDate = DateTime.now();
      _useFlexibleDate = false;
    });

    _animateToPage(WizardPage.recurringBloomState);
  }

  /// Selector de tipo del Tulipán (seasonal_bulb). Espejo del selector
  /// ornamental (perfiles en ORDEN del catálogo con el general al final, íconos
  /// ic_tulip_*, nunca el id interno). Diferencia clave: al elegir NO entra al
  /// flujo ornamental, sino a la etapa de GRANO (2 opciones planned/planted) para
  /// conservar el sowingDate como ancla real.
  Future<void> _openSeasonalBulbProfileSelector() async {
    final cropId = _normalizeCropId(_crop);
    if (cropId == null ||
        !isSeasonalBulbCrop(cropId: cropId, cropCategoryId: _category)) {
      return;
    }

    final profiles = CropCatalog.profilesForCrop(cropId, enabledOnly: false);
    if (profiles.isEmpty) return;
    final defaultProfileId = CropCatalog.resolveProfileId(cropId: cropId);

    final result = await showWizardSelectionSheet<String>(
      context: context,
      title: seasonalBulbTypeQuestion(cropId),
      options: profiles
          .map(
            (profile) => WizardSheetOption<String>(
              value: profile.id,
              title: profile.label,
              subtitle: profile.id == defaultProfileId
                  ? seasonalBulbGeneralProfileHint(cropId)
                  : (profile.subtitle ?? 'Disponible'),
              iconPath: seasonalBulbProfileIcon(cropId, profile.id),
              fallbackAsset: kSeasonalBulbGenericPlantFallback,
              enabled: true,
            ),
          )
          .toList(growable: false),
    );

    if (result == null) return;

    setState(() {
      // En el tulipán, "tipo" es el perfil (tu_*). El alta sigue el flujo de
      // grano; la fecha se conserva como sowingDate.
      _varietyId = result;
      _stage = null;
      _selectedDate = DateTime.now();
      _useFlexibleDate = false;
    });

    _animateToPage(WizardPage.stage);
  }

  /// Selector de tipo del Girasol (annual_ornamental). Espejo del selector
  /// ornamental (perfiles en ORDEN del catálogo con el general al final, íconos
  /// ic_girasol_*, nunca el id interno). Diferencia clave: al elegir NO entra
  /// al flujo ornamental, sino a la etapa de GRANO (2 opciones planned/planted)
  /// para conservar el sowingDate como ancla real.
  Future<void> _openAnnualOrnamentalProfileSelector() async {
    final cropId = _normalizeCropId(_crop);
    if (cropId == null ||
        !isAnnualOrnamentalCrop(cropId: cropId, cropCategoryId: _category)) {
      return;
    }

    final profiles = CropCatalog.profilesForCrop(cropId, enabledOnly: false);
    if (profiles.isEmpty) return;
    final defaultProfileId = CropCatalog.resolveProfileId(cropId: cropId);

    final result = await showWizardSelectionSheet<String>(
      context: context,
      title: annualOrnamentalTypeQuestion(cropId),
      options: profiles
          .map(
            (profile) => WizardSheetOption<String>(
              value: profile.id,
              title: profile.label,
              subtitle: profile.id == defaultProfileId
                  ? annualOrnamentalGeneralProfileHint(cropId)
                  : (profile.subtitle ?? 'Disponible'),
              iconPath: annualOrnamentalProfileIcon(cropId, profile.id),
              fallbackAsset: kAnnualOrnamentalGenericPlantFallback,
              enabled: true,
            ),
          )
          .toList(growable: false),
    );

    if (result == null) return;

    setState(() {
      // En el girasol, "tipo" es el perfil (gi_*). El alta sigue el flujo de
      // grano; la fecha se conserva como sowingDate.
      _varietyId = result;
      _stage = null;
      _selectedDate = DateTime.now();
      _useFlexibleDate = false;
    });

    _animateToPage(WizardPage.stage);
  }

  Future<void> _openVarietySelector() async {
    final cropId = _crop;
    if (cropId == null) return;

    if (_isTreeWizard ||
        isTreeCrop(cropId: cropId, cropCategoryId: _category)) {
      await _openTreeProfileSelector();
      return;
    }

    if (_isOrnamentalWizard ||
        isEstablishmentMaintenanceCrop(
          cropId: cropId,
          cropCategoryId: _category,
        )) {
      await _openOrnamentalProfileSelector();
      return;
    }

    // Tulipán (seasonal_bulb): elige PERFIL como una ornamental (aunque su alta
    // siga el flujo de grano). Sin esta rama caería al selector de variedades de
    // semilla, que está vacío para el tulipán.
    if (_isSeasonalBulbWizard ||
        isSeasonalBulbCrop(cropId: cropId, cropCategoryId: _category)) {
      await _openSeasonalBulbProfileSelector();
      return;
    }

    // Girasol (annual_ornamental): elige PERFIL como una ornamental (aunque su
    // alta siga el flujo de grano). Sin esta rama caería al selector de
    // variedades de semilla, que está vacío para el girasol.
    if (_isAnnualOrnamentalWizard ||
        isAnnualOrnamentalCrop(cropId: cropId, cropCategoryId: _category)) {
      await _openAnnualOrnamentalProfileSelector();
      return;
    }

    final varieties = CropCatalog.varietiesForCrop(cropId, enabledOnly: false);
    if (varieties.isEmpty) return;

    final result = await showWizardSelectionSheet<String>(
      context: context,
      title: cropId == CropCatalog.chiliCropId
          ? 'Selecciona el tipo de chile'
          : cropId == CropCatalog.eggplantCropId
          ? 'Selecciona el tipo de berenjena'
          : cropId == CropCatalog.squashCropId
          ? 'Selecciona el tipo de calabaza'
          : cropId == CropCatalog.lettuceCropId
          ? 'Selecciona el tipo de lechuga'
          : cropId == CropCatalog.spinachCropId
          ? 'Selecciona el tipo de espinaca'
          : cropId == CropCatalog.onionCropId
          ? 'Selecciona el tipo de cebolla'
          : cropId == CropCatalog.garlicCropId
          ? 'Selecciona el tipo de ajo'
          : 'Selecciona la variedad',
      options: varieties
          .map(
            (variety) => WizardSheetOption<String>(
              value: variety.id,
              title: variety.label,
              subtitle:
                  variety.subtitle ??
                  (variety.enabled
                      ? (variety.isGeneric
                            ? (cropId == CropCatalog.chiliCropId
                                  ? 'Recomendado si no sabes el tipo de chile'
                                  : cropId == CropCatalog.eggplantCropId
                                  ? 'Recomendado si no sabes el tipo de berenjena'
                                  : cropId == CropCatalog.squashCropId
                                  ? 'Recomendado si no sabes el tipo de calabaza'
                                  : cropId == CropCatalog.lettuceCropId
                                  ? 'Recomendado si no sabes el tipo de lechuga'
                                  : cropId == CropCatalog.spinachCropId
                                  ? 'Recomendado si no sabes el tipo de espinaca'
                                  : cropId == CropCatalog.onionCropId
                                  ? 'Recomendado si no sabes el tipo de cebolla'
                                  : cropId == CropCatalog.garlicCropId
                                  ? 'Recomendado si no sabes el tipo de ajo'
                                  : 'Recomendado si no sabes la variedad')
                            : 'Disponible ahora')
                      : 'Próximamente'),
              iconPath: cropId == CropCatalog.maizeCropId
                  ? ConfigureSeedWizardAssets.maizeIconForVariety(
                      useTypeId: variety.useTypeId,
                      marketTypeId: variety.marketTypeId,
                    )
                  : cropId == CropCatalog.beanCropId
                  ? ConfigureSeedWizardAssets.beanIconForVariety(
                      varietyId: variety.id,
                      label: variety.label,
                    )
                  : cropId == CropCatalog.tomatoCropId
                  ? ConfigureSeedWizardAssets.tomatoIconForVariety(
                      varietyId: variety.id,
                      label: variety.label,
                    )
                  : cropId == CropCatalog.cucumberCropId
                  ? ConfigureSeedWizardAssets.cucumberTypedIconForVariety(
                      varietyId: variety.id,
                      label: variety.label,
                    )
                  : cropId == CropCatalog.chiliCropId
                  ? ConfigureSeedWizardAssets.chiliTypedIconForVariety(
                      varietyId: variety.id,
                      label: variety.label,
                    )
                  : cropId == CropCatalog.eggplantCropId
                  ? ConfigureSeedWizardAssets.eggplantTypedIconForVariety(
                      varietyId: variety.id,
                      label: variety.label,
                    )
                  : cropId == CropCatalog.squashCropId
                  ? ConfigureSeedWizardAssets.squashTypedIconForVariety(
                      varietyId: variety.id,
                      label: variety.label,
                    )
                  : cropId == CropCatalog.lettuceCropId
                  ? ConfigureSeedWizardAssets.lettuceTypedIconForVariety(
                      varietyId: variety.id,
                      label: variety.label,
                    )
                  : cropId == CropCatalog.spinachCropId
                  ? ConfigureSeedWizardAssets.spinachTypedIconForVariety(
                      varietyId: variety.id,
                      label: variety.label,
                    )
                  : cropId == CropCatalog.onionCropId
                  ? ConfigureSeedWizardAssets.onionTypedIconForVariety(
                      varietyId: variety.id,
                      label: variety.label,
                    )
                  : cropId == CropCatalog.garlicCropId
                  ? ConfigureSeedWizardAssets.garlicTypedIconForVariety(
                      varietyId: variety.id,
                      label: variety.label,
                    )
                  : ConfigureSeedWizardAssets.variety,
              enabled: variety.enabled,
            ),
          )
          .toList(growable: false),
    );

    if (result == null) return;

    setState(() {
      _varietyId = result;
      _stage = null;
      _selectedDate = DateTime.now();
      _useFlexibleDate = false;
    });

    _animateToPage(WizardPage.stage);
  }

  void _onSelectVariety(String varietyId) {
    setState(() {
      _varietyId = varietyId;
      _stage = null;
      _selectedDate = DateTime.now();
      _useFlexibleDate = false;
    });

    _animateToPage(WizardPage.stage);
  }

  void _onSelectStage(String value) {
    setState(() {
      _stage = value;
      _useFlexibleDate = false;
      if (value != 'skip') {
        _selectedDate =
            _isOrnamentalWizard &&
                ornamentalSetupIntentRequiresFutureDate(
                  _ornamentalCropId,
                  value,
                )
            ? _dateOnly(DateTime.now()).add(const Duration(days: 1))
            : DateTime.now();
      }
    });

    if (value == 'skip') {
      unawaited(_save(BioGScope.of(context)));
      return;
    }

    _animateToPage(WizardPage.date);
  }

  /// Selección del estado VISUAL del rosal. Guarda el id de la opción en
  /// `_stage` (reutilizado) y ajusta la fecha inicial según si la opción pide
  /// fecha futura ("lo voy a plantar").
  void _onSelectRecurringBloomState(String optionId) {
    setState(() {
      _stage = optionId;
      _useFlexibleDate = false;
      RecurringBloomStateOption? option;
      for (final candidate in recurringBloomVisualStateOptions(_crop)) {
        if (candidate.id == optionId) {
          option = candidate;
          break;
        }
      }
      _selectedDate = (option?.requiresFutureDate ?? false)
          ? _dateOnly(DateTime.now()).add(const Duration(days: 1))
          : DateTime.now();
    });

    _animateToPage(WizardPage.date);
  }

  void _onSelectTreeProductionStatus(String value) {
    final statusId = normalizeTreeProductionStatusId(value);

    // "No estoy seguro": perfil general, sin fecha. Se guarda directo.
    if (statusId == TreeProductionStatusIds.unknown) {
      setState(() {
        _treeProductionStatusId = statusId;
        _treeReproSignalId = null;
        _perennialStateId = TreeStateIds.unknown;
        _phenologyStageId = TreeStageIds.unknown;
        _treeAnchorOptionId = TreeAnchorWizardOptionIds.unknown;
        _perennialAnchorDate = null;
        _perennialAnchorTypeId = TreeAnchorTypeIds.unknown;
        _stage = 'planted';
        _selectedDate = DateTime.now();
        _useFlexibleDate = true;
      });

      unawaited(_save(BioGScope.of(context)));
      return;
    }

    setState(() {
      _treeProductionStatusId = statusId;
      _treeReproSignalId = null;
      _perennialStateId = null;
      _phenologyStageId = null;
      _treeAnchorOptionId = null;
      _perennialAnchorDate = null;
      _perennialAnchorTypeId = null;
      _stage = 'planted';
      _selectedDate = DateTime.now();
      _useFlexibleDate = false;
    });

    // "Todavía no" pasa por la señal reproductiva (blinda primera floración);
    // "Sí, ya produce" va directo a la etapa fenológica visible.
    _animateToPage(
      statusId == TreeProductionStatusIds.nonProductive
          ? WizardPage.treeReproSignal
          : WizardPage.treePhenology,
    );
  }

  void _onSelectTreeReproSignal(String value) {
    // Señal reproductiva → etapa visible de producción (primera floración).
    final String? reproStageId = treeReproSignalVisibleStageId(value);

    if (reproStageId != null) {
      final selection = resolveTreeVisibleStageSelection(
        productionStatusId: TreeProductionStatusIds.nonProductive,
        visibleStageId: reproStageId,
      );
      final stageId = safeTreeStageForState(
        perennialStateId: selection.perennialStateId,
        phenologyStageId: selection.phenologyStageId,
      );

      setState(() {
        _treeReproSignalId = value;
        _perennialStateId = selection.perennialStateId;
        _phenologyStageId = stageId;
        _treeAnchorOptionId = null;
        _perennialAnchorDate = null;
        _perennialAnchorTypeId = selection.perennialAnchorTypeId;
        _selectedDate = DateTime.now();
        _useFlexibleDate = false;
      });

      _animateToPage(WizardPage.treeAnchor);
      return;
    }

    if (treeReproSignalIsUnknown(value)) {
      setState(() {
        _treeReproSignalId = value;
        _perennialStateId = TreeStateIds.unknown;
        _phenologyStageId = TreeStageIds.unknown;
        _treeAnchorOptionId = TreeAnchorWizardOptionIds.unknown;
        _perennialAnchorDate = null;
        _perennialAnchorTypeId = TreeAnchorTypeIds.unknown;
        _selectedDate = DateTime.now();
        _useFlexibleDate = true;
      });

      unawaited(_save(BioGScope.of(context)));
      return;
    }

    // "Solo esta creciendo": el estado se deriva de la fecha de plantacion
    // (rama 3A). El estado/etapa quedan pendientes hasta que el agricultor
    // capture la fecha.
    setState(() {
      _treeReproSignalId = value;
      _perennialStateId = null;
      _phenologyStageId = null;
      _treeAnchorOptionId = null;
      _perennialAnchorDate = null;
      _perennialAnchorTypeId = TreeAnchorTypeIds.planting;
      _selectedDate = DateTime.now();
      _useFlexibleDate = false;
    });

    _animateToPage(WizardPage.treeAnchor);
  }

  void _onSelectTreePhenologyStage(String value) {
    final selection = resolveTreeVisibleStageSelection(
      productionStatusId: _treeProductionStatusId,
      visibleStageId: value,
    );
    final stageId = safeTreeStageForState(
      perennialStateId: selection.perennialStateId,
      phenologyStageId: selection.phenologyStageId,
    );
    final isUnknownStage = stageId == TreeStageIds.unknown;

    setState(() {
      _perennialStateId = selection.perennialStateId;
      _phenologyStageId = stageId;
      _treeAnchorOptionId = isUnknownStage
          ? TreeAnchorWizardOptionIds.unknown
          : null;
      _perennialAnchorDate = null;
      _perennialAnchorTypeId = isUnknownStage
          ? TreeAnchorTypeIds.unknown
          : selection.perennialAnchorTypeId;
      _selectedDate = DateTime.now();
      _useFlexibleDate = isUnknownStage;
    });

    _animateToPage(WizardPage.treeAnchor);
  }

  void _onSelectTreeAnchorOption(String value) {
    final now = DateTime.now();
    final isPlanting = _perennialAnchorTypeId == TreeAnchorTypeIds.planting;

    setState(() {
      _treeAnchorOptionId = value;
      _useFlexibleDate = value == TreeAnchorWizardOptionIds.unknown;

      if (value == TreeAnchorWizardOptionIds.unknown) {
        _perennialAnchorDate = null;
      } else if (value == TreeAnchorWizardOptionIds.custom) {
        // El usuario abrirá el calendario; conservamos la fecha actual.
        _perennialAnchorDate = _selectedDate;
      } else {
        final date = treeAnchorDateForOption(
          value,
          now,
          isPlanting: isPlanting,
        );
        _perennialAnchorDate = date;
        if (date != null) _selectedDate = date;
      }

      // En la rama de plantación (3A) el estado/etapa se derivan de la edad.
      if (isPlanting) {
        final effectiveDate = value == TreeAnchorWizardOptionIds.unknown
            ? null
            : (_perennialAnchorDate ?? _selectedDate);
        final selection = resolveTreePlantingAnchorSelection(
          plantingDate: effectiveDate,
          now: now,
        );
        _perennialStateId = selection.perennialStateId;
        _phenologyStageId = selection.phenologyStageId;
        _perennialAnchorTypeId = selection.perennialAnchorTypeId;
      }
    });
  }

  void _onTreeAnchorDateChanged(DateTime value) {
    final now = DateTime.now();
    final isPlanting = _perennialAnchorTypeId == TreeAnchorTypeIds.planting;

    setState(() {
      _selectedDate = value;
      _perennialAnchorDate = value;
      _treeAnchorOptionId = TreeAnchorWizardOptionIds.custom;
      _useFlexibleDate = false;

      if (isPlanting) {
        final selection = resolveTreePlantingAnchorSelection(
          plantingDate: value,
          now: now,
        );
        _perennialStateId = selection.perennialStateId;
        _phenologyStageId = selection.phenologyStageId;
        _perennialAnchorTypeId = selection.perennialAnchorTypeId;
      } else {
        _perennialAnchorTypeId = _treeAnchorTypeForCurrentSelection();
      }
    });
  }

  String _treeAnchorTypeForCurrentSelection() {
    final selection = resolveTreeVisibleStageSelection(
      productionStatusId: _treeProductionStatusId,
      visibleStageId: _phenologyStageId,
    );
    return selection.perennialAnchorTypeId;
  }

  void _handleBack() {
    switch (_page) {
      case WizardPage.category:
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
        break;
      case WizardPage.cropVariety:
        setState(() {
          _page = WizardPage.category;
        });
        break;
      case WizardPage.brand:
        setState(() {
          _page = WizardPage.cropVariety;
        });
        break;
      case WizardPage.variety:
        setState(() {
          _page = WizardPage.brand;
        });
        break;
      case WizardPage.stage:
        if (_cropUsesBrands) {
          setState(() {
            _page = WizardPage.variety;
          });
        } else {
          setState(() {
            _page = WizardPage.cropVariety;
          });
        }
        break;
      case WizardPage.recurringBloomState:
        setState(() {
          _page = WizardPage.cropVariety;
        });
        break;
      case WizardPage.date:
        setState(() {
          _page = _isRecurringBloomWizard
              ? WizardPage.recurringBloomState
              : WizardPage.stage;
        });
        break;
      case WizardPage.treeState:
        setState(() {
          _page = WizardPage.cropVariety;
        });
        break;
      case WizardPage.treeReproSignal:
        setState(() {
          _page = WizardPage.treeState;
        });
        break;
      case WizardPage.treePhenology:
        setState(() {
          _page = WizardPage.treeState;
        });
        break;
      case WizardPage.treeAnchor:
        setState(() {
          _page = switch (normalizeTreeProductionStatusId(
            _treeProductionStatusId,
          )) {
            TreeProductionStatusIds.nonProductive => WizardPage.treeReproSignal,
            TreeProductionStatusIds.productiveOrProduced =>
              WizardPage.treePhenology,
            _ => WizardPage.treeState,
          };
        });
        break;
    }
  }

  Future<void> _save(BioGStore store) async {
    final device = store.activeDevice;
    if (device == null) return;

    final isTreeSave = _isTreeWizard;
    if (isTreeSave) {
      if (_crop == null) return;
      if (_perennialStateId == null || _phenologyStageId == null) return;
      if (_treeAnchorOptionId == null) return;
    } else {
      if (_stage == null) return;
      if (_crop == null && _stage != 'skip') return;
      if (_stage != 'skip' && _varietyId == null) return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final previous = store.cropContextForDevice(device.id);
      final now = DateTime.now();

      final resolvedCropId =
          _normalizeCropId(_crop) ?? _normalizeCropId(previous?.cropId);

      if (resolvedCropId == null) {
        return;
      }

      if (isTreeSave) {
        final resolvedProfileId =
            CropCatalog.profileByAny(resolvedCropId, _varietyId)?.id ??
            CropCatalog.resolveProfileId(cropId: resolvedCropId);

        final resolvedStateId = normalizeTreeStateId(_perennialStateId);
        final resolvedStageId = safeTreeStageForState(
          perennialStateId: resolvedStateId,
          phenologyStageId: _phenologyStageId,
        );

        final resolvedAnchorTypeId =
            _perennialAnchorTypeId ?? _treeAnchorTypeForCurrentSelection();

        final resolvedContext = _contextResolver.resolve(
          deviceId: device.id,
          cropCategoryId: CropCatalog.treeCategoryId,
          cropId: resolvedCropId,
          lifecycleStatus: CropLifecycleStatus.planted,
          dateConfidence: DateConfidence.unknown,
          now: now,
          previous: previous,
          varietyId: resolvedProfileId,
          varietyAlias: resolvedProfileId,
          selectedDate: null,
          sowingModeId: 'planted',
          perennialStateId: resolvedStateId,
          phenologyStageId: resolvedStageId,
          perennialAnchorDate: _perennialAnchorDate,
          perennialAnchorTypeId: resolvedAnchorTypeId,
        );

        await store.saveCropContext(resolvedContext);
      } else if (_stage == 'skip') {
        await store.setSeedSkipForDevice(device.id, cropKey: resolvedCropId);
      } else if (_isRecurringBloomWizard) {
        // Rosal: guarda el estado VISUAL elegido (o deja que la fecha resuelva
        // el establecimiento). Sin cosecha ni rendimiento.
        final option = _selectedRecurringBloomOption;
        final bool isPlanned =
            option?.intentId == kRecurringBloomIntentPlannedPlant;
        final lifecycleStatus = isPlanned
            ? CropLifecycleStatus.planned
            : CropLifecycleStatus.planted;

        final bool requiresFuture = option?.requiresFutureDate ?? false;
        final today = _dateOnly(now);
        final pickedDay = _dateOnly(_selectedDate);
        final bool validDate = requiresFuture
            ? pickedDay.isAfter(today)
            : !pickedDay.isAfter(today);
        final DateTime? selectedDate = !_useFlexibleDate && validDate
            ? _selectedDate
            : null;

        final bool preserveExistingAnchor =
            !isPlanned &&
            selectedDate == null &&
            previous?.ornamentalAnchorDate != null;
        final DateTime? effectiveAnchorDate = preserveExistingAnchor
            ? previous!.ornamentalAnchorDate
            : selectedDate;

        final dateConfidence = preserveExistingAnchor
            ? (previous!.ornamentalAnchorDateConfidence ??
                  DateConfidence.unknown)
            : selectedDate == null
            ? DateConfidence.unknown
            : isPlanned
            ? DateConfidence.exact
            : DateConfidence.estimated;

        // Las opciones de establecimiento dejan que la fecha resuelva la etapa;
        // los estados recurrentes se guardan tal cual el usuario los vio.
        final bool usesDateEstimation = option?.usesDateEstimation ?? true;
        final String? passStageId = usesDateEstimation ? null : option?.stageId;
        final double? passConfidence = usesDateEstimation
            ? null
            : option?.stageConfidence;

        final resolvedContext = _contextResolver.resolve(
          deviceId: device.id,
          cropCategoryId:
              _category ??
              previous?.cropCategoryId ??
              CropCatalog.ornamentalCategoryId,
          cropId: resolvedCropId,
          lifecycleStatus: lifecycleStatus,
          dateConfidence: dateConfidence,
          now: now,
          previous: previous,
          varietyId: _varietyId,
          varietyAlias: _varietyId,
          selectedDate: effectiveAnchorDate,
          timezone: previous?.timezone,
          ornamentalStageId: passStageId,
          ornamentalAnchorDate: effectiveAnchorDate,
          ornamentalAnchorTypeId: option?.anchorTypeId,
          ornamentalStageConfidence: passConfidence,
        );

        await store.saveCropContext(resolvedContext);
      } else {
        final String? ornamentalIntentId = _isOrnamentalWizard
            ? normalizeOrnamentalSetupIntentId(_ornamentalCropId, _stage)
            : null;
        final isPlanned = _isOrnamentalWizard
            ? ornamentalIntentId == kOrnamentalIntentPlannedPlant
            : _stage == 'planned';
        final lifecycleStatus = isPlanned
            ? CropLifecycleStatus.planned
            : CropLifecycleStatus.planted;

        DateTime? selectedDate;
        if (_isOrnamentalWizard) {
          final today = _dateOnly(now);
          final pickedDay = _dateOnly(_selectedDate);
          final requiresFuture = ornamentalSetupIntentRequiresFutureDate(
            _ornamentalCropId,
            ornamentalIntentId,
          );
          final validDate = requiresFuture
              ? pickedDay.isAfter(today)
              : !pickedDay.isAfter(today);
          selectedDate = !_useFlexibleDate && validDate ? _selectedDate : null;
        } else {
          // Los anuales conservan su comportamiento previo.
          selectedDate = isPlanned
              ? (_useFlexibleDate ? null : _selectedDate)
              : _selectedDate;
        }

        final bool preserveExistingOrnamentalAnchor =
            _isOrnamentalWizard &&
            ornamentalIntentId == kOrnamentalIntentAlreadyPlanted &&
            selectedDate == null &&
            previous?.ornamentalAnchorDate != null;
        final DateTime? effectiveOrnamentalAnchorDate =
            preserveExistingOrnamentalAnchor
            ? previous!.ornamentalAnchorDate
            : selectedDate;

        final dateConfidence = _isOrnamentalWizard
            ? preserveExistingOrnamentalAnchor
                  ? previous!.ornamentalAnchorDateConfidence ??
                        DateConfidence.unknown
                  : selectedDate == null
                  ? DateConfidence.unknown
                  : ornamentalIntentId == kOrnamentalIntentAlreadyPlanted
                  ? DateConfidence.estimated
                  : DateConfidence.exact
            : isPlanned
            ? (_useFlexibleDate ? DateConfidence.unknown : DateConfidence.exact)
            : (_useFlexibleDate
                  ? DateConfidence.estimated
                  : DateConfidence.exact);

        String? ornamentalStageId;
        String? ornamentalAnchorTypeId;
        double? ornamentalStageConfidence;
        if (_isOrnamentalWizard) {
          // Misma FUENTE ÚNICA que el onboarding. Si esta pantalla vuelve a
          // resolver la etapa por su cuenta, se desincroniza (ya pasó: "ya está
          // plantada" daba 'unknown' → "Etapa por confirmar" eterna).
          final estimate = resolveOrnamentalSetupStage(
            cropId: _ornamentalCropId,
            intentId: ornamentalIntentId,
            plantingDate: effectiveOrnamentalAnchorDate,
            now: now,
            profileId: _varietyId,
            previousStageId: previous?.ornamentalStageId,
          );
          ornamentalStageId = estimate.stageId;
          ornamentalStageConfidence = estimate.confidence;
          ornamentalAnchorTypeId = preserveExistingOrnamentalAnchor
              ? normalizeOrnamentalAnchorTypeId(
                  _ornamentalCropId,
                  previous?.ornamentalAnchorTypeId,
                )
              : estimate.anchorTypeId;
        }

        final resolvedContext = _contextResolver.resolve(
          deviceId: device.id,
          cropCategoryId:
              _category ??
              previous?.cropCategoryId ??
              CropCatalog.grainCategoryId,
          cropId: resolvedCropId,
          lifecycleStatus: lifecycleStatus,
          dateConfidence: dateConfidence,
          now: now,
          previous: previous,
          brandId: _brandId,
          varietyId: _varietyId,
          varietyAlias: _isOrnamentalWizard ? _varietyId : null,
          selectedDate: selectedDate,
          timezone: previous?.timezone,
          cultivationScaleId: _isOrnamentalWizard
              ? null
              : previous?.cultivationScaleId,
          ornamentalStageId: ornamentalStageId,
          ornamentalAnchorDate: _isOrnamentalWizard
              ? effectiveOrnamentalAnchorDate
              : null,
          ornamentalAnchorTypeId: ornamentalAnchorTypeId,
          ornamentalStageConfidence: ornamentalStageConfidence,
        );

        await store.saveCropContext(resolvedContext);
      }

      if (!mounted) return;
      await _showSuccessDialog();

      if (widget.onCompleted != null) {
        await widget.onCompleted!.call();
      }

      if (!mounted) return;

      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop(true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ── Hydration helpers ───────────────────────────────────────────────────────

  String? _resolveWizardVarietySelectionFromContext(
    DeviceCropContext cropContext,
    String normalizedCropId,
  ) {
    if (isTreeCrop(cropId: normalizedCropId) ||
        isEstablishmentMaintenanceCrop(cropId: normalizedCropId) ||
        // Tulipán (seasonal_bulb): reabre el PERFIL guardado (tu_*) leyendo
        // profileId/varietyId/varietyAlias, igual que árboles y ornamentales.
        isSeasonalBulbCrop(cropId: normalizedCropId) ||
        // Girasol (annual_ornamental): reabre el PERFIL guardado (gi_*) leyendo
        // profileId/varietyId/varietyAlias, igual que árboles y ornamentales.
        isAnnualOrnamentalCrop(cropId: normalizedCropId)) {
      final profile =
          CropCatalog.profileByAny(normalizedCropId, cropContext.profileId) ??
          CropCatalog.profileByAny(normalizedCropId, cropContext.varietyId) ??
          CropCatalog.profileByAny(normalizedCropId, cropContext.varietyAlias);

      return profile?.id ??
          CropCatalog.resolveProfileId(cropId: normalizedCropId);
    }

    if (cropContext.varietyId != null &&
        cropContext.varietyId!.trim().isNotEmpty) {
      final fromVarietyId = CropCatalog.varietyById(
        normalizedCropId,
        cropContext.varietyId,
      );
      if (fromVarietyId != null) {
        return fromVarietyId.id;
      }
    }

    final rawAlias = (cropContext.varietyAlias ?? '').trim();
    if (rawAlias.isNotEmpty) {
      final fromAlias = CropCatalog.varietyByAny(normalizedCropId, rawAlias);
      if (fromAlias != null) {
        return fromAlias.id;
      }
    }

    final genericVarietyId = _genericVarietyIdForCrop(normalizedCropId);
    if (genericVarietyId != null) {
      final genericProfile = CropCatalog.profileByAny(
        normalizedCropId,
        cropContext.profileId,
      );
      if (CropCatalog.isGenericProfileId(
        genericProfile?.id ?? cropContext.profileId,
      )) {
        return genericVarietyId;
      }
    }

    return null;
  }

  String? _genericVarietyIdForCrop(String cropId) {
    final varieties = CropCatalog.varietiesForCrop(cropId, enabledOnly: false);
    for (final variety in varieties) {
      if (variety.isGeneric) {
        return variety.id;
      }
    }
    return null;
  }

  List<CropVarietyEntry> _varietiesForSelectedBrand() {
    final cropId = _crop;
    final brandId = _brandId;
    if (cropId == null || brandId == null) return const [];

    // Brand varieties + generics (always visible so user can pick "no sé")
    final brandVarieties = CropCatalog.maizeVarietiesForBrand(brandId);
    final generics = maizeGenericVarieties;
    return [...brandVarieties, ...generics];
  }

  // ── Display helpers ─────────────────────────────────────────────────────────

  String? _normalizeCropId(String? value) {
    return CropCatalog.canonicalCropKeyOrNull(value);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _categoryLabel(String? value) {
    return CropCatalog.categoryById(value)?.label ?? 'Seleccionar';
  }

  String _cropLabel(String? value) {
    return CropCatalog.cropById(value)?.label ?? 'Seleccionar';
  }

  String _brandLabel(String? brandId) {
    if (brandId == null) return 'Seleccionar';
    final brands = CropCatalog.brandsForCrop(_crop ?? '');
    for (final brand in brands) {
      if (brand.id == brandId) return brand.label;
    }
    return 'Seleccionar';
  }

  String _varietyDisplayLabel() {
    final cropId = _crop;
    final varietyId = _varietyId;
    if (cropId == null || varietyId == null) return 'Seleccionar';

    if (isTreeCrop(cropId: cropId, cropCategoryId: _category)) {
      final profile = CropCatalog.profileByAny(cropId, varietyId);
      if (profile != null) {
        return _treeProfileOptionTitle(cropId, profile.id, profile.label);
      }
    }

    // Ornamentales: etiqueta humana directa del catálogo (sin códigos CA-/SU-).
    if (isEstablishmentMaintenanceCrop(
      cropId: cropId,
      cropCategoryId: _category,
    )) {
      final profile = CropCatalog.profileByAny(cropId, varietyId);
      if (profile != null) return profile.label;
    }

    // Tulipán (seasonal_bulb): etiqueta humana directa del perfil (sin id tu_*).
    if (isSeasonalBulbCrop(cropId: cropId, cropCategoryId: _category)) {
      final profile = CropCatalog.profileByAny(cropId, varietyId);
      if (profile != null) return profile.label;
    }

    // Girasol (annual_ornamental): etiqueta humana directa del perfil (sin id
    // gi_*).
    if (isAnnualOrnamentalCrop(cropId: cropId, cropCategoryId: _category)) {
      final profile = CropCatalog.profileByAny(cropId, varietyId);
      if (profile != null) return profile.label;
    }

    final variety = CropCatalog.varietyById(cropId, varietyId);
    if (variety != null) return variety.label;

    final byAny = CropCatalog.varietyByAny(cropId, varietyId);
    if (byAny != null) return byAny.label;

    return 'Seleccionar';
  }

  String _treeProfileOptionTitle(
    String cropId,
    String profileId,
    String fallbackLabel,
  ) {
    // Lenguaje humano compartido por Manzano, Pera y futuros árboles: nunca
    // muestra códigos PR-/AP-/SKIP al productor.
    return TreeProfilePresentation.displayLabel(
      cropId,
      profileId,
      fallbackLabel: fallbackLabel,
    );
  }

  String? _treeAnchorDisplayLabel(String? optionId) {
    switch (optionId) {
      case TreeAnchorWizardOptionIds.today:
        return 'Hace pocos días';
      case TreeAnchorWizardOptionIds.oneWeek:
        return 'Hace una semana';
      case TreeAnchorWizardOptionIds.thisWeek:
        return 'Apenas esta semana';
      case TreeAnchorWizardOptionIds.twoWeeks:
      case TreeAnchorWizardOptionIds.twoThreeWeeks:
        return 'Hace unas 2 semanas';
      case TreeAnchorWizardOptionIds.oneMonth:
        return 'Hace 1 mes';
      case TreeAnchorWizardOptionIds.plantedThisMonth:
        return 'Plantado este mes';
      case TreeAnchorWizardOptionIds.plantedSixMonths:
        return 'Plantado hace ~6 meses';
      case TreeAnchorWizardOptionIds.plantedOneYear:
        return 'Plantado hace 1 año';
      case TreeAnchorWizardOptionIds.plantedTwoYearsPlus:
        return 'Plantado hace 2+ años';
      case TreeAnchorWizardOptionIds.unknown:
        return 'No lo recuerdo';
      case TreeAnchorWizardOptionIds.custom:
        return 'Fecha aproximada';
      default:
        return null;
    }
  }

  String _stageLabel(String? value) {
    if (_isOrnamentalWizard) {
      return normalizeOrnamentalSetupIntentId(_ornamentalCropId, value) ==
              kOrnamentalIntentPlannedPlant
          ? ornamentalPlannedOptionTitle(_ornamentalCropId)
          : ornamentalPlantedOptionTitle(_ornamentalCropId);
    }
    switch (value) {
      case 'planned':
        return 'Aún no siembro';
      case 'planted':
        return 'Ya sembrado';
      case 'skip':
        return 'Descanso del suelo';
      default:
        return 'Etapa';
    }
  }

  String _cropIconPath(String cropId) {
    switch (cropId) {
      case CropCatalog.maizeCropId:
        return ConfigureSeedWizardAssets.cropMaize;
      case CropCatalog.wheatCropId:
        return ConfigureSeedWizardAssets.cropWheat;
      case CropCatalog.barleyCropId:
        return ConfigureSeedWizardAssets.cropBarley;
      case CropCatalog.oatCropId:
        return ConfigureSeedWizardAssets.cropOat;
      case CropCatalog.beanCropId:
        return ConfigureSeedWizardAssets.cropBean;
      case CropCatalog.tomatoCropId:
        return ConfigureSeedWizardAssets.cropTomato;
      case CropCatalog.cucumberCropId:
        return ConfigureSeedWizardAssets.cropCucumber;
      case CropCatalog.chiliCropId:
        return ConfigureSeedWizardAssets.cropChili;
      case CropCatalog.eggplantCropId:
        return ConfigureSeedWizardAssets.cropEggplant;
      case CropCatalog.squashCropId:
        return ConfigureSeedWizardAssets.cropSquash;
      case CropCatalog.lettuceCropId:
        return ConfigureSeedWizardAssets.cropLettuce;
      case CropCatalog.spinachCropId:
        return ConfigureSeedWizardAssets.cropSpinach;
      case CropCatalog.onionCropId:
        return ConfigureSeedWizardAssets.cropOnion;
      case CropCatalog.garlicCropId:
        return ConfigureSeedWizardAssets.cropGarlic;
      case CropCatalog.appleTreeCropId:
        return AppleTreeAssets.cropIcon;
      case CropCatalog.pearTreeCropId:
        return PearTreeAssets.cropIcon;
      case CropCatalog.peachTreeCropId:
        return PeachTreeAssets.cropIcon;
      case CropCatalog.walnutTreeCropId:
        return WalnutTreeAssets.cropIcon;
      case CropCatalog.pistachioTreeCropId:
        return PistachioTreeAssets.cropIcon;
      case CropCatalog.orangeTreeCropId:
        return OrangeTreeAssets.cropIcon;
      case CropCatalog.lemonTreeCropId:
        return LemonTreeAssets.cropIcon;
      case CropCatalog.mangoTreeCropId:
        return MangoTreeAssets.cropIcon;
      case CropCatalog.avocadoTreeCropId:
        return AvocadoTreeAssets.cropIcon;
      case CropCatalog.cactusCropId:
      case CropCatalog.succulentCropId:
      case CropCatalog.aloeCropId:
      case CropCatalog.agaveCropId:
        return ornamentalCropIcon(CropCatalog.canonicalCropKey(cropId));
      // Tulipán (seasonal_bulb): arte propio del bulbo, no el árbol ni genérico.
      case CropCatalog.tulipCropId:
        return seasonalBulbCropIcon(CropCatalog.canonicalCropKey(cropId));
      // Girasol (annual_ornamental): arte propio de la anual, no el árbol ni
      // genérico.
      case CropCatalog.sunflowerCropId:
        return annualOrnamentalCropIcon(CropCatalog.canonicalCropKey(cropId));
      default:
        return _genericCropIconPath;
    }
  }

  String _treeCropIcon(String cropId) {
    switch (CropCatalog.canonicalCropKey(cropId)) {
      case CropCatalog.appleTreeCropId:
        return AppleTreeAssets.cropIcon;
      case CropCatalog.pearTreeCropId:
        return PearTreeAssets.cropIcon;
      case CropCatalog.peachTreeCropId:
        return PeachTreeAssets.cropIcon;
      case CropCatalog.walnutTreeCropId:
        return WalnutTreeAssets.cropIcon;
      case CropCatalog.pistachioTreeCropId:
        return PistachioTreeAssets.cropIcon;
      case CropCatalog.orangeTreeCropId:
        return OrangeTreeAssets.cropIcon;
      case CropCatalog.lemonTreeCropId:
        return LemonTreeAssets.cropIcon;
      case CropCatalog.mangoTreeCropId:
        return MangoTreeAssets.cropIcon;
      case CropCatalog.avocadoTreeCropId:
        return AvocadoTreeAssets.cropIcon;
      default:
        return ConfigureSeedWizardAssets.categoryTree;
    }
  }

  String _treeProfileIcon(String cropId, String? profileId) {
    switch (CropCatalog.canonicalCropKey(cropId)) {
      case CropCatalog.appleTreeCropId:
        return appleTreeProfileIcon(profileId);
      case CropCatalog.pearTreeCropId:
        return pearTreeProfileIcon(profileId);
      case CropCatalog.peachTreeCropId:
        return peachTreeProfileIcon(profileId);
      case CropCatalog.walnutTreeCropId:
        return walnutTreeProfileIcon(profileId);
      case CropCatalog.pistachioTreeCropId:
        return pistachioTreeProfileIcon(profileId);
      case CropCatalog.orangeTreeCropId:
        return orangeTreeProfileIcon(profileId);
      case CropCatalog.lemonTreeCropId:
        return lemonTreeProfileIcon(profileId);
      case CropCatalog.mangoTreeCropId:
        return mangoTreeProfileIcon(profileId);
      case CropCatalog.avocadoTreeCropId:
        return avocadoTreeProfileIcon(profileId);
      default:
        return _treeCropIcon(cropId);
    }
  }

  String _treeStageIcon(String? stageId) {
    return ConfigureSeedWizardAssets.treeStageIconFor(stageId);
  }

  String _treeProductionStatusIcon(String statusId) {
    return ConfigureSeedWizardAssets.treeProductionStatusIconFor(statusId);
  }

  String _treeReproSignalIcon(String signalId) {
    return treeReproSignalIconPath(signalId);
  }

  String get _resolvedVarietyIconPath {
    final cropId = _crop;
    if (cropId != null &&
        isTreeCrop(cropId: cropId, cropCategoryId: _category)) {
      return _treeProfileIcon(cropId, _varietyId);
    }
    if (cropId != null &&
        isEstablishmentMaintenanceCrop(
          cropId: cropId,
          cropCategoryId: _category,
        )) {
      return ornamentalProfileIcon(_ornamentalCropId, _varietyId);
    }
    // Tulipán (seasonal_bulb): ícono del PERFIL elegido (ic_tulip_*), no el árbol.
    if (cropId != null &&
        isSeasonalBulbCrop(cropId: cropId, cropCategoryId: _category)) {
      return seasonalBulbProfileIcon(_seasonalBulbCropId, _varietyId);
    }
    // Girasol (annual_ornamental): ícono del PERFIL elegido (ic_girasol_*), no
    // el árbol.
    if (cropId != null &&
        isAnnualOrnamentalCrop(cropId: cropId, cropCategoryId: _category)) {
      return annualOrnamentalProfileIcon(_annualOrnamentalCropId, _varietyId);
    }
    return _resolvedCropIconPath;
  }

  /// Returns the maize-type icon that matches the currently selected variety,
  /// or falls back to the generic crop icon when no variety is picked yet.
  String get _resolvedCropIconPath {
    final cropId = _crop;
    if (cropId == null) return _genericCropIconPath;

    if (isTreeCrop(cropId: cropId, cropCategoryId: _category)) {
      return _treeCropIcon(cropId);
    }

    if (_varietyId != null) {
      final variety = CropCatalog.varietyById(cropId, _varietyId);
      if (variety != null) {
        if (cropId == CropCatalog.maizeCropId) {
          return ConfigureSeedWizardAssets.maizeIconForVariety(
            useTypeId: variety.useTypeId,
            marketTypeId: variety.marketTypeId,
          );
        }
        if (cropId == CropCatalog.beanCropId) {
          return ConfigureSeedWizardAssets.beanIconForVariety(
            varietyId: variety.id,
            label: variety.label,
          );
        }
        if (cropId == CropCatalog.tomatoCropId) {
          return ConfigureSeedWizardAssets.tomatoIconForVariety(
            varietyId: variety.id,
            label: variety.label,
          );
        }
        if (cropId == CropCatalog.cucumberCropId) {
          return ConfigureSeedWizardAssets.cucumberTypedIconForVariety(
            varietyId: variety.id,
            label: variety.label,
          );
        }
        if (cropId == CropCatalog.chiliCropId) {
          return ConfigureSeedWizardAssets.chiliTypedIconForVariety(
            varietyId: variety.id,
            label: variety.label,
          );
        }
        if (cropId == CropCatalog.eggplantCropId) {
          return ConfigureSeedWizardAssets.eggplantTypedIconForVariety(
            varietyId: variety.id,
            label: variety.label,
          );
        }
        if (cropId == CropCatalog.squashCropId) {
          return ConfigureSeedWizardAssets.squashTypedIconForVariety(
            varietyId: variety.id,
            label: variety.label,
          );
        }
        if (cropId == CropCatalog.lettuceCropId) {
          return ConfigureSeedWizardAssets.lettuceTypedIconForVariety(
            varietyId: variety.id,
            label: variety.label,
          );
        }
        if (cropId == CropCatalog.spinachCropId) {
          return ConfigureSeedWizardAssets.spinachTypedIconForVariety(
            varietyId: variety.id,
            label: variety.label,
          );
        }
        if (cropId == CropCatalog.onionCropId) {
          return ConfigureSeedWizardAssets.onionTypedIconForVariety(
            varietyId: variety.id,
            label: variety.label,
          );
        }
        if (cropId == CropCatalog.garlicCropId) {
          return ConfigureSeedWizardAssets.garlicTypedIconForVariety(
            varietyId: variety.id,
            label: variety.label,
          );
        }
      }
    }

    return _cropIconPath(cropId);
  }
}
