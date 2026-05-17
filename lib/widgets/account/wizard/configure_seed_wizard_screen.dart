import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/core/crops/maize/maize_catalog.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_components.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_dialogs.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_pages.dart';
import 'package:bio_g/widgets/account/wizard/wizard_crop_context_resolver.dart';

enum WizardPage { category, cropVariety, brand, variety, stage, date }

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

  DateTime _selectedDate = DateTime.now();
  bool _useFlexibleDate = false;
  bool _saving = false;
  bool _didShowIntro = false;

  /// Whether the current crop uses the brand→variety flow (only maize for now).
  bool get _cropUsesBrands => _crop == CropCatalog.maizeCropId;

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

    String? stage;
    DateTime selectedDate = DateTime.now();
    bool flexibleDate = false;

    switch (cropContext.lifecycleStatus) {
      case CropLifecycleStatus.fallow:
        stage = 'skip';
        flexibleDate = false;
        break;
      case CropLifecycleStatus.planned:
        stage = 'planned';
        selectedDate = cropContext.plannedSowingDate ?? DateTime.now();
        flexibleDate =
            cropContext.sowingDateConfidence != DateConfidence.exact ||
            cropContext.plannedSowingDate == null;
        break;
      case CropLifecycleStatus.planted:
        stage = 'planted';
        selectedDate = cropContext.sowingDate ?? DateTime.now();
        flexibleDate = cropContext.sowingDateConfidence != DateConfidence.exact;
        break;
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
      case WizardPage.date:
        return _cropUsesBrands ? 4 : 3;
    }
  }

  String get _dateQuestionTitle {
    if (_stage == 'planned') {
      return '¿Tienes una fecha\nestimada para sembrar?';
    }
    if (_stage == 'planted') {
      return '¿Recuerdas aproximadamente\ncuándo sembraste?';
    }
    return 'Fecha';
  }

  String get _dateFlexibleLabel {
    if (_stage == 'planned') {
      return 'No tengo fecha aún';
    }
    if (_stage == 'planted') {
      return 'No lo recuerdo muy bien';
    }
    return 'No aplica';
  }

  String get _dateFlexibleDescription {
    if (_stage == 'planned') {
      return 'Bio-G usará una referencia flexible y podrás actualizarla después.';
    }
    if (_stage == 'planted') {
      return 'Usaremos la fecha seleccionada como aproximada para interpretar mejor tu etapa.';
    }
    return '';
  }

  String get _dateHelperText {
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
                    totalSteps: _cropUsesBrands ? 5 : 4,
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
              _category == CropCatalog.vegetableCategoryId,
          cropUsesBrands: _cropUsesBrands,
          cropIconPath: _resolvedCropIconPath,
          varietyIconPath: _varietyId != null ? _resolvedCropIconPath : null,
          summary: _buildSelectionSummary(),
          onTapCrop: _openCropSelector,
          onTapVariety: _cropUsesBrands
              ? _openBrandSelector
              : _openVarietySelector,
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
          summary: _buildSelectionSummary(),
          onSelect: _onSelectStage,
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
        value != CropCatalog.vegetableCategoryId) {
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
    });

    _animateToPage(WizardPage.cropVariety);
  }

  Future<void> _openCropSelector() async {
    if (_category != CropCatalog.grainCategoryId &&
        _category != CropCatalog.vegetableCategoryId) {
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

  Future<void> _openVarietySelector() async {
    final cropId = _crop;
    if (cropId == null) return;

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
        _selectedDate = DateTime.now();
      }
    });

    if (value == 'skip') {
      unawaited(_save(BioGScope.of(context)));
      return;
    }

    _animateToPage(WizardPage.date);
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
      case WizardPage.date:
        setState(() {
          _page = WizardPage.stage;
        });
        break;
    }
  }

  Future<void> _save(BioGStore store) async {
    final device = store.activeDevice;
    if (device == null) return;
    if (_stage == null) return;
    if (_crop == null && _stage != 'skip') return;
    if (_stage != 'skip' && _varietyId == null) return;

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

      if (_stage == 'skip') {
        await store.setSeedSkipForDevice(device.id, cropKey: resolvedCropId);
      } else {
        final isPlanned = _stage == 'planned';
        final lifecycleStatus = isPlanned
            ? CropLifecycleStatus.planned
            : CropLifecycleStatus.planted;

        final dateConfidence = isPlanned
            ? (_useFlexibleDate ? DateConfidence.unknown : DateConfidence.exact)
            : (_useFlexibleDate
                  ? DateConfidence.estimated
                  : DateConfidence.exact);

        final selectedDate = isPlanned
            ? (_useFlexibleDate ? null : _selectedDate)
            : _selectedDate;

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
          selectedDate: selectedDate,
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

    final variety = CropCatalog.varietyById(cropId, varietyId);
    if (variety != null) return variety.label;

    final byAny = CropCatalog.varietyByAny(cropId, varietyId);
    if (byAny != null) return byAny.label;

    return 'Seleccionar';
  }

  String _stageLabel(String? value) {
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
      default:
        return _genericCropIconPath;
    }
  }

  /// Returns the maize-type icon that matches the currently selected variety,
  /// or falls back to the generic crop icon when no variety is picked yet.
  String get _resolvedCropIconPath {
    final cropId = _crop;
    if (cropId == null) return _genericCropIconPath;

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
      }
    }

    return _cropIconPath(cropId);
  }
}
