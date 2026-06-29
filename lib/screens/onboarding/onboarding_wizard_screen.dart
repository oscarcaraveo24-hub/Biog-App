import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bio_g/core/crops/apple_tree/apple_tree_assets.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_assets.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_assets.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_assets.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/tree_profile_presentation.dart';
import 'package:bio_g/models/onboarding/onboarding_draft.dart';
import 'package:bio_g/models/onboarding/onboarding_step.dart';
import 'package:bio_g/screens/onboarding/steps/location_step.dart';
import 'package:bio_g/screens/onboarding/steps/pair_biog_step.dart';
import 'package:bio_g/widgets/account/bluetooth_scan_screen.dart';
import 'package:bio_g/widgets/account/location_screen.dart';
import 'package:bio_g/widgets/account/qr_scan_screen.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_components.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_dialogs.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_pages.dart'
    show
        TreeAnchorWizardOptionIds,
        TreeReproSignalOptionIds,
        treeAnchorDateForOption,
        treeReproSignalIconPath,
        treeReproSignalIsUnknown,
        treeReproSignalVisibleStageId;
import 'package:bio_g/screens/onboarding/steps/cultivation_scale_step.dart';
import 'package:bio_g/widgets/shared/bio_g_button.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/widgets/shared/bio_g_page_route.dart';
import 'package:bio_g/widgets/shared/bio_g_wheel_date_picker.dart';

typedef OnboardingStepBuilder =
    Widget Function(BuildContext context, OnboardingStepController controller);

class OnboardingWizardScreen extends StatefulWidget {
  final OnboardingDraft initialDraft;
  final OnboardingStep initialStep;
  final Future<void> Function(OnboardingDraft draft)? onCompleted;
  final VoidCallback? onExited;
  final OnboardingStepBuilder? stepBuilder;

  const OnboardingWizardScreen({
    super.key,
    this.initialDraft = const OnboardingDraft(),
    this.initialStep = OnboardingStep.location,
    this.onCompleted,
    this.onExited,
    this.stepBuilder,
  });

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  static const List<OnboardingStep> _steps = <OnboardingStep>[
    OnboardingStep.location,
    OnboardingStep.cultivationScale,
    OnboardingStep.cropCategory,
    OnboardingStep.cropDetails,
    OnboardingStep.cropStage,
    OnboardingStep.cropDate,
    OnboardingStep.pairBioG,
  ];

  static const double _iconScale = 1.95;

  late OnboardingDraft _draft;
  late OnboardingStep _currentStep;
  bool _submitting = false;
  String? _pairedDeviceName;

  bool get _isFirstStep => _currentStep == _steps.first;
  bool get _isLastStep => _currentStep == _steps.last;
  bool get _isTreeDraft =>
      isTreeCrop(cropId: _draft.cropId, cropCategoryId: _draft.cropCategory);
  bool get _isTreeUnknownStageSelection =>
      _isTreeDraft &&
      (normalizeTreeProductionStatusId(_draft.treeProductionStatusId) ==
              TreeProductionStatusIds.unknown ||
          normalizeTreeStageId(_draft.stage) == TreeStageIds.unknown);
  bool get _isTreePlantingAnchor =>
      _isTreeDraft &&
      isOnboardingTreePlantingBranch(
        productionStatusId: _draft.treeProductionStatusId,
        phenologyStageId: _draft.stage,
      );

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
    _currentStep = widget.initialStep;
  }

  void _updateDraft(OnboardingDraft nextDraft) {
    if (!mounted) return;
    setState(() => _draft = nextDraft);
  }

  void _animateToStep(OnboardingStep step) {
    if (!mounted) return;
    setState(() => _currentStep = step);
  }

  Future<void> _handleContinue() async {
    if (!_canContinueFromCurrentStep || _submitting) return;

    if (_isLastStep) {
      await _finishFlow();
      return;
    }

    if (_currentStep == OnboardingStep.cropStage &&
        _isTreeUnknownStageSelection) {
      setState(() => _currentStep = OnboardingStep.pairBioG);
      return;
    }

    final int currentIndex = _steps.indexOf(_currentStep);
    setState(() => _currentStep = _steps[currentIndex + 1]);
  }

  void _handleBack() {
    if (_submitting) return;

    if (_isFirstStep) {
      if (widget.onExited != null) {
        widget.onExited!();
        return;
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (_currentStep == OnboardingStep.cropStage &&
        _isTreeDraft &&
        _draft.treeProductionStatusId != null) {
      _updateDraft(
        _draft.copyWith(
          treeProductionStatusId: null,
          stage: null,
          treeAnchorOptionId: null,
          selectedDate: null,
          useFlexibleDate: false,
        ),
      );
      return;
    }

    if (_currentStep == OnboardingStep.pairBioG &&
        _isTreeUnknownStageSelection) {
      setState(() => _currentStep = OnboardingStep.cropStage);
      return;
    }

    final int currentIndex = _steps.indexOf(_currentStep);
    setState(() => _currentStep = _steps[currentIndex - 1]);
  }

  Future<void> _finishFlow() async {
    if (widget.onCompleted == null) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(_draft);
      }
      return;
    }

    setState(() => _submitting = true);

    try {
      await widget.onCompleted!(_draft);
    } finally {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  bool get _canContinueFromCurrentStep {
    switch (_currentStep) {
      case OnboardingStep.location:
        return (_draft.locationSource?.isNotEmpty ?? false) ||
            (_draft.locationLabel?.isNotEmpty ?? false);
      case OnboardingStep.cultivationScale:
        return _draft.cultivationScale?.isNotEmpty ?? false;
      case OnboardingStep.cropCategory:
        return _draft.cropCategory?.isNotEmpty ?? false;
      case OnboardingStep.cropDetails:
        return (_draft.cropId?.isNotEmpty ?? false) &&
            ((_draft.varietyId?.isNotEmpty ?? false) ||
                (_draft.varietyAlias?.isNotEmpty ?? false));
      case OnboardingStep.cropStage:
        return _draft.stage?.isNotEmpty ?? false;
      case OnboardingStep.cropDate:
        return _draft.useFlexibleDate || _draft.selectedDate != null;
      case OnboardingStep.pairBioG:
        return true;
    }
  }

  String get _continueLabel => _isLastStep ? 'Finalizar' : 'Continuar';

  // ─── Handlers ───

  static const String _kMapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const String _kPrefLocLabel = 'profile_location_label';
  static const String _kPrefLocLat = 'profile_location_lat';
  static const String _kPrefLocLng = 'profile_location_lng';

  Future<void> _saveLocationToPrefs({
    required String label,
    required double lat,
    required double lng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefLocLabel, label);
    await prefs.setDouble(_kPrefLocLat, lat);
    await prefs.setDouble(_kPrefLocLng, lng);
  }

  Future<String> _reverseGeocodeLabel(double lat, double lng) async {
    if (_kMapsKey.isEmpty) return 'Ubicación actual';
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&key=$_kMapsKey'
        '&language=es',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return 'Ubicación actual';
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];
      if (results.isEmpty) return 'Ubicación actual';
      return (results.first['formatted_address'] ?? 'Ubicación actual')
          .toString();
    } catch (_) {
      return 'Ubicación actual';
    }
  }

  Future<void> _handleUseCurrentLocation() async {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activa los servicios de ubicación en tu dispositivo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se necesita permiso de ubicación para continuar.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permiso de ubicación denegado permanentemente. Habilítalo en ajustes.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 3. Get current position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      // 4. Reverse geocode for a readable label
      final label = await _reverseGeocodeLabel(lat, lng);

      // 5. Save to SharedPreferences (for environment screen)
      await _saveLocationToPrefs(label: label, lat: lat, lng: lng);

      if (!mounted) return;

      // 6. Update draft
      _updateDraft(
        _draft.copyWith(
          locationSource: 'gps',
          locationLabel: label,
          geoLat: lat,
          geoLng: lng,
          timezone: 'America/Mexico_City',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener tu ubicación. Intenta de nuevo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handlePickOnMap() async {
    final result = await Navigator.of(context).push<String>(
      BioGPageRoute<String>(
        builder: (_) => LocationScreen(
          initialValue: _draft.locationLabel ?? '',
          brandMid: const Color(0xFF3FAF6E),
        ),
      ),
    );

    if (result == null || !mounted) return;

    // Read saved coords from SharedPreferences (LocationScreen already saved them)
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_kPrefLocLat) ?? 19.4326;
    final lng = prefs.getDouble(_kPrefLocLng) ?? -99.1332;

    _updateDraft(
      _draft.copyWith(
        locationSource: 'map',
        locationLabel: result,
        geoLat: lat,
        geoLng: lng,
        timezone: 'America/Mexico_City',
      ),
    );
  }

  Future<void> _handleScanQr() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      BioGPageRoute<Map<String, dynamic>>(builder: (_) => const QrScanScreen()),
    );

    if (result == null || !mounted) return;

    final name = (result['name'] as String?) ?? 'Bio-G';
    setState(() => _pairedDeviceName = name);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name conectado correctamente.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleConnectBluetooth() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      BioGPageRoute<Map<String, dynamic>>(
        builder: (_) => const BluetoothScanScreen(),
      ),
    );

    if (result == null || !mounted) return;

    final name = (result['name'] as String?) ?? 'Bio-G';
    setState(() => _pairedDeviceName = name);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name conectado correctamente.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSkip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          '¿Omitir este paso?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF293533),
          ),
        ),
        content: const Text(
          'Podrás completar esta información más tarde desde tu cuenta. '
          'Bio-G usará valores genéricos mientras tanto.',
          style: TextStyle(
            fontSize: 14.4,
            height: 1.4,
            color: Color(0xFF5A6B6F),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF6D757A),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Omitir',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E6F5E),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (_isLastStep) {
      await _finishFlow();
      return;
    }

    final int currentIndex = _steps.indexOf(_currentStep);
    setState(() => _currentStep = _steps[currentIndex + 1]);
  }

  void _onSelectCategory(String value) {
    final bool changed = _draft.cropCategory != value;
    _updateDraft(
      _draft.copyWith(
        cropCategory: value,
        cropId: changed ? null : _draft.cropId,
        brandId: changed ? null : _draft.brandId,
        varietyId: changed ? null : _draft.varietyId,
        varietyAlias: changed ? null : _draft.varietyAlias,
        treeProductionStatusId: changed ? null : _draft.treeProductionStatusId,
        stage: changed ? null : _draft.stage,
        treeAnchorOptionId: changed ? null : _draft.treeAnchorOptionId,
        selectedDate: changed ? null : _draft.selectedDate,
        useFlexibleDate: changed ? false : _draft.useFlexibleDate,
      ),
    );

    _animateToStep(OnboardingStep.cropDetails);
  }

  Future<void> _openCropSelector() async {
    if (_draft.cropCategory != CropCatalog.grainCategoryId &&
        _draft.cropCategory != CropCatalog.vegetableCategoryId &&
        _draft.cropCategory != CropCatalog.treeCategoryId) {
      return;
    }

    final cropOptions = CropCatalog.cropsByCategory(
      _draft.cropCategory ?? CropCatalog.grainCategoryId,
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

    final bool changed = _draft.cropId != result;
    _updateDraft(
      _draft.copyWith(
        cropId: result,
        brandId: changed ? null : _draft.brandId,
        varietyId: changed ? null : _draft.varietyId,
        varietyAlias: changed ? null : _draft.varietyAlias,
        treeProductionStatusId: changed ? null : _draft.treeProductionStatusId,
        stage: changed ? null : _draft.stage,
        treeAnchorOptionId: changed ? null : _draft.treeAnchorOptionId,
        selectedDate: changed ? null : _draft.selectedDate,
        useFlexibleDate: changed ? false : _draft.useFlexibleDate,
      ),
    );
  }

  Future<void> _openVarietySelector() async {
    final cropId = _draft.cropId;
    if (cropId == null) return;

    // Árboles usan perfiles (AP-SKIP/AP-01..05), no variedades de semilla.
    if (isTreeCrop(cropId: cropId, cropCategoryId: _draft.cropCategory)) {
      await _openTreeProfileSelector();
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
          : 'Selecciona variedad o perfil',
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

    final selectedVariety = CropCatalog.varietyById(cropId, result);

    _updateDraft(
      _draft.copyWith(
        brandId: selectedVariety?.brandId,
        varietyId: selectedVariety?.id ?? result,
        varietyAlias: selectedVariety?.label ?? result,
        treeProductionStatusId: null,
        stage: null,
        treeAnchorOptionId: null,
        selectedDate: null,
        useFlexibleDate: false,
      ),
    );

    _animateToStep(OnboardingStep.cropStage);
  }

  Future<void> _openTreeProfileSelector() async {
    final cropId = _draft.cropId;
    if (cropId == null) return;

    final profiles = CropCatalog.profilesForCrop(cropId, enabledOnly: false);
    if (profiles.isEmpty) return;
    final defaultProfileId = CropCatalog.resolveProfileId(cropId: cropId);

    // Perfil general/SKIP al final; pregunta humana de "variedad".
    final orderedProfiles = TreeProfilePresentation.genericLast(profiles, cropId);

    final result = await showWizardSelectionSheet<String>(
      context: context,
      title: TreeProfilePresentation.varietyQuestion(cropId),
      options: orderedProfiles
          .map(
            (profile) => WizardSheetOption<String>(
              value: profile.id,
              title: _treeProfileTitle(cropId, profile.id, profile.label),
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

    _updateDraft(
      _draft.copyWith(
        // En árboles, "variedad" es el perfil perenne (AP-*/PR-*).
        varietyId: result,
        varietyAlias: result,
        treeProductionStatusId: null,
        stage: null,
        treeAnchorOptionId: null,
        selectedDate: null,
        useFlexibleDate: false,
      ),
    );

    _animateToStep(OnboardingStep.cropStage);
  }

  String _treeProfileTitle(
    String cropId,
    String profileId,
    String fallbackLabel,
  ) {
    // Lenguaje humano compartido (Manzano/Pera/futuros): sin códigos PR-/AP-.
    return TreeProfilePresentation.displayLabel(
      cropId,
      profileId,
      fallbackLabel: fallbackLabel,
    );
  }

  void _onSelectStage(String value) {
    final bool isRestStage = value == 'fallow' || value == 'skip';
    _updateDraft(
      _draft.copyWith(
        stage: value,
        selectedDate: isRestStage ? null : _draft.selectedDate,
        useFlexibleDate: isRestStage ? true : _draft.useFlexibleDate,
      ),
    );

    if (isRestStage) {
      _animateToStep(OnboardingStep.pairBioG);
    } else {
      _animateToStep(OnboardingStep.cropDate);
    }
  }

  // ─── Labels ───

  void _onSelectTreeProductionStatus(String value) {
    final statusId = normalizeTreeProductionStatusId(value);

    if (statusId == TreeProductionStatusIds.unknown) {
      _updateDraft(
        _draft.copyWith(
          treeProductionStatusId: statusId,
          stage: TreeStageIds.unknown,
          treeAnchorOptionId: TreeAnchorWizardOptionIds.unknown,
          selectedDate: null,
          useFlexibleDate: true,
        ),
      );
      _animateToStep(OnboardingStep.pairBioG);
      return;
    }

    _updateDraft(
      _draft.copyWith(
        treeProductionStatusId: statusId,
        stage: null,
        treeAnchorOptionId: null,
        selectedDate: null,
        useFlexibleDate: false,
      ),
    );
  }

  void _onSelectTreeVisibleStage(String value) {
    final selection = resolveTreeVisibleStageSelection(
      productionStatusId: _draft.treeProductionStatusId,
      visibleStageId: value,
    );
    final bool isUnknownStage =
        selection.phenologyStageId == TreeStageIds.unknown;

    _updateDraft(
      _draft.copyWith(
        stage: selection.phenologyStageId,
        treeAnchorOptionId: isUnknownStage
            ? TreeAnchorWizardOptionIds.unknown
            : null,
        selectedDate: null,
        useFlexibleDate: isUnknownStage,
      ),
    );

    _animateToStep(
      isUnknownStage ? OnboardingStep.pairBioG : OnboardingStep.cropDate,
    );
  }

  void _onSelectTreeReproSignal(String value) {
    final String? visibleStageId = treeReproSignalVisibleStageId(value);

    if (visibleStageId != null) {
      _onSelectTreeVisibleStage(visibleStageId);
      return;
    }

    final bool isUnknownSignal = treeReproSignalIsUnknown(value);
    _updateDraft(
      _draft.copyWith(
        stage: isUnknownSignal
            ? TreeStageIds.unknown
            : TreeStageIds.juvenileVegetative,
        treeAnchorOptionId: isUnknownSignal
            ? TreeAnchorWizardOptionIds.unknown
            : null,
        selectedDate: null,
        useFlexibleDate: isUnknownSignal,
      ),
    );

    _animateToStep(
      isUnknownSignal ? OnboardingStep.pairBioG : OnboardingStep.cropDate,
    );
  }

  void _onSelectTreeAnchorOption(String optionId) {
    final now = DateTime.now();
    final bool isPlanting = _isTreePlantingAnchor;
    final DateTime? resolvedDate = treeAnchorDateForOption(
      optionId,
      now,
      isPlanting: isPlanting,
    );
    final DateTime? anchorDate = optionId == TreeAnchorWizardOptionIds.custom
        ? (_draft.selectedDate ?? now)
        : resolvedDate;

    _updateDraft(
      _draft.copyWith(
        treeAnchorOptionId: optionId,
        selectedDate: anchorDate,
        useFlexibleDate: optionId == TreeAnchorWizardOptionIds.unknown,
      ),
    );
  }

  String _categoryLabel(String? value) {
    return CropCatalog.categoryById(value)?.label ?? 'Seleccionar';
  }

  String _categoryIconPath(String? value) {
    switch (value) {
      case CropCatalog.grainCategoryId:
        return ConfigureSeedWizardAssets.categoryGrain;
      case CropCatalog.vegetableCategoryId:
        return ConfigureSeedWizardAssets.categoryVegetable;
      case CropCatalog.treeCategoryId:
        return ConfigureSeedWizardAssets.categoryTree;
      case 'ornamental':
        return ConfigureSeedWizardAssets.categoryOrnamental;
      default:
        return ConfigureSeedWizardAssets.categoryGeneric;
    }
  }

  String _cropLabel(String? value) {
    return CropCatalog.cropById(value)?.label ?? 'Seleccionar';
  }

  String _varietyLabel(String? value) {
    final cropId = _draft.cropId;
    if (cropId == null) return 'Seleccionar';

    final variety = CropCatalog.varietyByAny(cropId, _draft.varietyId ?? value);
    if (variety != null) return variety.label;

    final profile = CropCatalog.profileByAny(cropId, value);
    if (profile != null) {
      return TreeProfilePresentation.displayLabel(
        cropId,
        profile.id,
        fallbackLabel: profile.label,
      );
    }

    return 'Seleccionar';
  }

  String get _dateQuestionTitle {
    if (_draft.cropCategory == CropCatalog.treeCategoryId) {
      if (_draft.stage == 'planned') {
        return '¿Tienes una fecha\nestimada para plantar?';
      }
      if (_draft.stage == 'newly_planted') {
        return '¿Cuándo lo plantaste\naproximadamente?';
      }
      return '¿Desde cuándo está\nen esta etapa?';
    }
    if (_draft.stage == 'planned') {
      return '¿Tienes una fecha\nestimada para sembrar?';
    }
    return '¿Recuerdas aproximadamente\ncuándo sembraste?';
  }

  String get _dateFlexibleLabel {
    if (_draft.stage == 'planned') return 'No tengo fecha aún';
    return 'No lo recuerdo muy bien';
  }

  String get _dateFlexibleDescription {
    if (_draft.stage == 'planned') {
      return 'Bio-G usará una referencia flexible y podrás actualizarla después.';
    }
    return 'Usaremos la fecha seleccionada como aproximada para interpretar mejor tu etapa.';
  }

  String get _dateHelperText {
    if (_draft.stage == 'planned') {
      return 'Indicar una fecha nos ayuda a ajustar mejor las recomendaciones de Bio-G. Puede cambiarse en cualquier momento.';
    }
    return 'Indicar una fecha nos ayuda a ajustar mejor las recomendaciones de Bio-G. Si no lo recuerdas, coloca una fecha aproximada para darte los mejores resultados.';
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
      default:
        return ConfigureSeedWizardAssets.categoryGeneric;
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
      default:
        return _cropIconPath(cropId);
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

  String _treeAnchorIcon(String optionId, String fallbackIconPath) {
    switch (optionId) {
      case TreeAnchorWizardOptionIds.custom:
        return fallbackIconPath;
      case TreeAnchorWizardOptionIds.unknown:
        return ConfigureSeedWizardAssets.treeUnknownState;
      default:
        return _isTreePlantingAnchor
            ? ConfigureSeedWizardAssets.treeGrowingOnly
            : ConfigureSeedWizardAssets.treeStageIconFor(_draft.stage);
    }
  }

  static String _cropIconPathFromLabel(String cropLabel) {
    switch (cropLabel) {
      case 'Maíz':
        return ConfigureSeedWizardAssets.cropMaize;
      case 'Trigo':
        return ConfigureSeedWizardAssets.cropWheat;
      case 'Cebada':
        return ConfigureSeedWizardAssets.cropBarley;
      case 'Avena':
        return ConfigureSeedWizardAssets.cropOat;
      case 'Frijol':
        return ConfigureSeedWizardAssets.cropBean;
      case 'Tomate':
        return ConfigureSeedWizardAssets.cropTomato;
      case 'Pepino':
        return ConfigureSeedWizardAssets.cropCucumber;
      case 'Chile':
        return ConfigureSeedWizardAssets.cropChili;
      case 'Berenjena':
        return ConfigureSeedWizardAssets.cropEggplant;
      case 'Calabaza':
        return ConfigureSeedWizardAssets.cropSquash;
      case 'Lechuga':
        return ConfigureSeedWizardAssets.cropLettuce;
      case 'Espinaca':
        return ConfigureSeedWizardAssets.cropSpinach;
      case 'Cebolla':
        return ConfigureSeedWizardAssets.cropOnion;
      case 'Ajo':
        return ConfigureSeedWizardAssets.cropGarlic;
      case 'Manzano':
        return AppleTreeAssets.cropIcon;
      default:
        return ConfigureSeedWizardAssets.categoryGeneric;
    }
  }

  // ─── Build ───

  Widget _buildDefaultStep(OnboardingStepController controller) {
    switch (controller.step) {
      case OnboardingStep.location:
        return LocationStep(
          selectedSource: controller.draft.locationSource,
          selectedLabel: controller.draft.locationLabel,
          showScaffold: false,
          showContinueButton: false,
          onUseCurrentLocation: _handleUseCurrentLocation,
          onPickOnMap: _handlePickOnMap,
        );

      case OnboardingStep.cultivationScale:
        return CultivationScaleStep(
          selectedScale: controller.draft.cultivationScale,
          showScaffold: false,
          showContinueButton: false,
          onChanged: (value) {
            _updateDraft(_draft.copyWith(cultivationScale: value));
          },
        );

      case OnboardingStep.cropCategory:
        return _buildCategoryPage();

      case OnboardingStep.cropDetails:
        return _buildCropVarietyPage();

      case OnboardingStep.cropStage:
        return _buildStagePage();

      case OnboardingStep.cropDate:
        return _buildDatePage();

      case OnboardingStep.pairBioG:
        return PairBioGStep(
          showScaffold: false,
          showContinueButton: false,
          pairedDeviceName: _pairedDeviceName,
          onScanQr: _handleScanQr,
          onConnectBluetooth: _handleConnectBluetooth,
        );
    }
  }

  Widget _buildCategoryPage() {
    final category = _draft.cropCategory;

    return CenteredWizardPage(
      horizontalPadding: 4,
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(width: 274),
          const SizedBox(height: 22),
          const StaggerIn(
            delay: 0,
            child: Text(
              '¿Qué piensas cultivar?',
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
              'Selecciona la planta que tienes o planeas sembrar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.4,
                height: 1.34,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: 24),
          StaggerIn(
            delay: 90,
            child: _wizardPill(
              iconPath: ConfigureSeedWizardAssets.categoryGrain,
              title: 'Grano',
              subtitle: 'Maíz, trigo, sorgo...',
              selected: category == 'grain',
              enabled: true,
              onTap: () => _onSelectCategory('grain'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 145,
            child: _wizardPill(
              iconPath: ConfigureSeedWizardAssets.categoryVegetable,
              title: 'Hortaliza',
              subtitle: 'Tomate, cebolla, lechuga...',
              selected: category == 'vegetable',
              enabled: true,
              onTap: () => _onSelectCategory('vegetable'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 200,
            child: _wizardPill(
              iconPath: ConfigureSeedWizardAssets.categoryTree,
              title: 'Árbol',
              subtitle: 'Manzano, pera y otros frutales perennes',
              selected: category == 'tree',
              enabled: true,
              onTap: () => _onSelectCategory('tree'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 255,
            child: _wizardPill(
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
            child: _wizardPill(
              iconPath: ConfigureSeedWizardAssets.categoryGeneric,
              title: 'Otro / genérico',
              subtitle: 'Próximamente',
              selected: category == 'generic',
              enabled: false,
              onTap: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropVarietyPage() {
    final cropId = _draft.cropId;
    final cropLabel = _cropLabel(cropId);

    final selectedVariety = cropId == null
        ? null
        : CropCatalog.varietyByAny(
            cropId,
            _draft.varietyId ?? _draft.varietyAlias,
          );

    final selectedVarietyLabel = _varietyLabel(
      _draft.varietyId ?? _draft.varietyAlias,
    );

    final selectedVarietyIconPath = cropId == CropCatalog.maizeCropId
        ? ConfigureSeedWizardAssets.maizeIconForVariety(
            useTypeId: selectedVariety?.useTypeId,
            marketTypeId: selectedVariety?.marketTypeId,
          )
        : cropId == CropCatalog.beanCropId
        ? ConfigureSeedWizardAssets.beanIconForVariety(
            varietyId: selectedVariety?.id ?? _draft.varietyAlias,
            label: selectedVariety?.label ?? selectedVarietyLabel,
          )
        : cropId == CropCatalog.tomatoCropId
        ? ConfigureSeedWizardAssets.tomatoIconForVariety(
            varietyId: selectedVariety?.id ?? _draft.varietyAlias,
            label: selectedVariety?.label ?? selectedVarietyLabel,
          )
        : cropId == CropCatalog.cucumberCropId
        ? ConfigureSeedWizardAssets.cucumberTypedIconForVariety(
            varietyId: selectedVariety?.id ?? _draft.varietyAlias,
            label: selectedVariety?.label ?? selectedVarietyLabel,
          )
        : cropId == CropCatalog.chiliCropId
        ? ConfigureSeedWizardAssets.chiliTypedIconForVariety(
            varietyId: selectedVariety?.id ?? _draft.varietyAlias,
            label: selectedVariety?.label ?? selectedVarietyLabel,
          )
        : cropId == CropCatalog.eggplantCropId
        ? ConfigureSeedWizardAssets.eggplantTypedIconForVariety(
            varietyId: selectedVariety?.id ?? _draft.varietyAlias,
            label: selectedVariety?.label ?? selectedVarietyLabel,
          )
        : cropId == CropCatalog.squashCropId
        ? ConfigureSeedWizardAssets.squashTypedIconForVariety(
            varietyId: selectedVariety?.id ?? _draft.varietyAlias,
            label: selectedVariety?.label ?? selectedVarietyLabel,
          )
        : cropId == CropCatalog.lettuceCropId
        ? ConfigureSeedWizardAssets.lettuceTypedIconForVariety(
            varietyId: selectedVariety?.id ?? _draft.varietyAlias,
            label: selectedVariety?.label ?? selectedVarietyLabel,
          )
        : cropId == CropCatalog.spinachCropId
        ? ConfigureSeedWizardAssets.spinachTypedIconForVariety(
            varietyId: selectedVariety?.id ?? _draft.varietyAlias,
            label: selectedVariety?.label ?? selectedVarietyLabel,
          )
        : cropId == CropCatalog.onionCropId
        ? ConfigureSeedWizardAssets.onionTypedIconForVariety(
            varietyId: selectedVariety?.id ?? _draft.varietyAlias,
            label: selectedVariety?.label ?? selectedVarietyLabel,
          )
        : cropId == CropCatalog.garlicCropId
        ? ConfigureSeedWizardAssets.garlicTypedIconForVariety(
            varietyId: selectedVariety?.id ?? _draft.varietyAlias,
            label: selectedVariety?.label ?? selectedVarietyLabel,
          )
        : cropId != null &&
              isTreeCrop(cropId: cropId, cropCategoryId: _draft.cropCategory)
        ? _treeProfileIcon(cropId, _draft.varietyId ?? _draft.varietyAlias)
        : ConfigureSeedWizardAssets.variety;

    return CenteredWizardPage(
      horizontalPadding: 4,
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(width: 274),
          const SizedBox(height: 22),
          const StaggerIn(
            delay: 0,
            child: Text(
              '¿Qué piensas cultivar?',
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
              _draft.cropCategory == CropCatalog.treeCategoryId
                  ? 'Selecciona el cultivo y su perfil perenne.'
                  : 'Selecciona el cultivo y la variedad o perfil de semilla.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.4,
                height: 1.34,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: 24),
          StaggerIn(
            delay: 95,
            child: _selectionPill(
              iconPath: _categoryIconPath(_draft.cropCategory),
              title: 'Categoría',
              value: _categoryLabel(_draft.cropCategory),
              selected: true,
              onTap: null,
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 150,
            child: _selectionPill(
              iconPath: cropId == null
                  ? ConfigureSeedWizardAssets.categoryGeneric
                  : _cropIconPath(cropId),
              title: 'Cultivo',
              value: cropLabel,
              selected: cropId != null,
              onTap:
                  (_draft.cropCategory == CropCatalog.grainCategoryId ||
                      _draft.cropCategory == CropCatalog.vegetableCategoryId ||
                      _draft.cropCategory == CropCatalog.treeCategoryId)
                  ? _openCropSelector
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 205,
            child: _selectionPill(
              iconPath: selectedVarietyIconPath,
              title: cropId != null &&
                      isTreeCrop(
                        cropId: cropId,
                        cropCategoryId: _draft.cropCategory,
                      )
                  ? 'Variedad'
                  : 'Variedad / perfil',
              value: selectedVarietyLabel,
              selected: _draft.varietyId != null || _draft.varietyAlias != null,
              onTap: cropId != null ? _openVarietySelector : null,
            ),
          ),
          const SizedBox(height: 18),
          StaggerIn(
            delay: 255,
            child: Text(
              'Usar perfil genérico (recomendado si no sabes la variedad).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.6,
                height: 1.32,
                color: Colors.black.withValues(alpha: 0.48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagePage() {
    if (_draft.cropCategory == CropCatalog.treeCategoryId) {
      return _buildTreeStagePage();
    }

    final stage = _draft.stage;

    return CenteredWizardPage(
      horizontalPadding: 4,
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(width: 274),
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
            child: _wizardPill(
              iconPath: ConfigureSeedWizardAssets.stagePlanned,
              title: 'Aún no siembro /estoy por sembrar',
              subtitle: '',
              selected: stage == 'planned',
              enabled: true,
              onTap: () => _onSelectStage('planned'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 145,
            child: _wizardPill(
              iconPath: ConfigureSeedWizardAssets.stagePlanted,
              title: 'Ya sembrado y creciendo',
              subtitle: '',
              selected: stage == 'planted' || stage == 'growing',
              enabled: true,
              onTap: () => _onSelectStage('planted'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 200,
            child: _wizardPill(
              iconPath: ConfigureSeedWizardAssets.stageSkip,
              title: 'Ya coseché / descanso del suelo',
              subtitle: '',
              selected: stage == 'skip' || stage == 'fallow',
              enabled: true,
              onTap: () => _onSelectStage('fallow'),
            ),
          ),
        ],
      ),
    );
  }

  /// Estados del árbol en onboarding. Cada id alimenta el resolver canónico de
  /// árbol/perenne; el árbol nunca va a fallow.
  static const List<_OnboardingTreeOptionData>
  _treeProductionStatusOptions = <_OnboardingTreeOptionData>[
    _OnboardingTreeOptionData(
      id: TreeProductionStatusIds.nonProductive,
      title: 'Aún no produce',
      subtitle:
          'Para árboles recién plantados, jóvenes o que todavía no han dado fruta.',
      iconPath: ConfigureSeedWizardAssets.treeYoungNotFruiting,
    ),
    _OnboardingTreeOptionData(
      id: TreeProductionStatusIds.productiveOrProduced,
      title: 'Ya produce o ya ha producido',
      subtitle:
          'Para árboles establecidos, aunque ahora estén sin hojas, en floración, con fruto o después de cosecha.',
      iconPath: ConfigureSeedWizardAssets.categoryTree,
    ),
    _OnboardingTreeOptionData(
      id: TreeProductionStatusIds.unknown,
      title: 'No estoy seguro',
      subtitle:
          'BIO-G usará un perfil general y ajustará la interpretación con los sensores.',
      iconPath: ConfigureSeedWizardAssets.treeUnknownState,
    ),
  ];

  static List<_OnboardingTreeOptionData> _treeVisibleStageOptions(
    String? productionStatusId,
  ) {
    switch (normalizeTreeProductionStatusId(productionStatusId)) {
      case TreeProductionStatusIds.nonProductive:
        // Pantalla 2B (señal reproductiva): blinda la primera floración. Las
        // opciones mapean a TreeReproSignalOptionIds, no a etapas directas.
        return const <_OnboardingTreeOptionData>[
          _OnboardingTreeOptionData(
            id: TreeReproSignalOptionIds.growingOnly,
            title: 'No, solo está creciendo',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
          ),
          _OnboardingTreeOptionData(
            id: TreeReproSignalOptionIds.hasFlower,
            title: 'Sí, tiene flor',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeHasFlower,
          ),
          _OnboardingTreeOptionData(
            id: TreeReproSignalOptionIds.hasFruitSet,
            title: 'Sí, tiene frutito chiquito',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeTinyFruit,
          ),
          _OnboardingTreeOptionData(
            id: TreeReproSignalOptionIds.hasFruitFill,
            title: 'Sí, fruto creciendo',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeFruitGrowing,
          ),
          _OnboardingTreeOptionData(
            id: TreeReproSignalOptionIds.notSure,
            title: 'No estoy seguro',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeUnknownState,
          ),
        ];
      case TreeProductionStatusIds.productiveOrProduced:
        return const <_OnboardingTreeOptionData>[
          _OnboardingTreeOptionData(
            id: TreeStageIds.dormancy,
            title: 'Sin hojas / en reposo',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeDormantLeafless,
          ),
          _OnboardingTreeOptionData(
            id: TreeStageIds.budbreak,
            title: 'Brotando',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeBudding,
          ),
          _OnboardingTreeOptionData(
            id: TreeStageIds.vegetativeGrowth,
            title: 'Con hojas en desarrollo',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeFullFoliage,
          ),
          _OnboardingTreeOptionData(
            id: TreeStageIds.flowering,
            title: 'En floración',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeFlowering,
          ),
          _OnboardingTreeOptionData(
            id: TreeStageIds.fruitSet,
            title: 'Fruto recién amarrado',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeFruitSetFlowerDrop,
          ),
          _OnboardingTreeOptionData(
            id: TreeStageIds.fruitFill,
            title: 'Fruto creciendo',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeGreenFruitGrowing,
          ),
          _OnboardingTreeOptionData(
            id: TreeStageIds.harvestMaturity,
            title: 'Fruto madurando / cosecha',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeReadyHarvest,
          ),
          _OnboardingTreeOptionData(
            id: TreeStageIds.postHarvest,
            title: 'Después de cosecha',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeAfterHarvest,
          ),
          _OnboardingTreeOptionData(
            id: TreeStageIds.unknown,
            title: 'No lo sé',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeUnknownState,
          ),
        ];
      default:
        return const <_OnboardingTreeOptionData>[
          _OnboardingTreeOptionData(
            id: TreeStageIds.unknown,
            title: 'No lo sé',
            subtitle: '',
            iconPath: ConfigureSeedWizardAssets.treeUnknownState,
          ),
        ];
    }
  }

  static List<_OnboardingTreeOptionData> _treeAnchorOptions({
    required bool isPlanting,
  }) {
    if (isPlanting) {
      return const <_OnboardingTreeOptionData>[
        _OnboardingTreeOptionData(
          id: TreeAnchorWizardOptionIds.custom,
          title: 'Elegir fecha exacta',
          subtitle: '',
          iconPath: ConfigureSeedWizardAssets.exactDateCalendarClock,
        ),
        _OnboardingTreeOptionData(
          id: TreeAnchorWizardOptionIds.plantedThisMonth,
          title: 'Este mes',
          subtitle: '',
          iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
        ),
        _OnboardingTreeOptionData(
          id: TreeAnchorWizardOptionIds.plantedSixMonths,
          title: 'Hace unos 6 meses',
          subtitle: '',
          iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
        ),
        _OnboardingTreeOptionData(
          id: TreeAnchorWizardOptionIds.plantedOneYear,
          title: 'Hace aproximadamente 1 año',
          subtitle: '',
          iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
        ),
        _OnboardingTreeOptionData(
          id: TreeAnchorWizardOptionIds.plantedTwoYearsPlus,
          title: 'Hace más de 2 años',
          subtitle: '',
          iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
        ),
        _OnboardingTreeOptionData(
          id: TreeAnchorWizardOptionIds.unknown,
          title: 'No lo recuerdo',
          subtitle: '',
          iconPath: ConfigureSeedWizardAssets.treeUnknownState,
        ),
      ];
    }

    return const <_OnboardingTreeOptionData>[
      _OnboardingTreeOptionData(
        id: TreeAnchorWizardOptionIds.custom,
        title: 'Elegir fecha exacta',
        subtitle: '',
        iconPath: ConfigureSeedWizardAssets.exactDateCalendarClock,
      ),
      _OnboardingTreeOptionData(
        id: TreeAnchorWizardOptionIds.thisWeek,
        title: 'Hace pocos días',
        subtitle: '',
        iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
      ),
      _OnboardingTreeOptionData(
        id: TreeAnchorWizardOptionIds.oneWeek,
        title: 'Hace una semana',
        subtitle: '',
        iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
      ),
      _OnboardingTreeOptionData(
        id: TreeAnchorWizardOptionIds.twoWeeks,
        title: 'Hace dos semanas',
        subtitle: '',
        iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
      ),
      _OnboardingTreeOptionData(
        id: TreeAnchorWizardOptionIds.oneMonth,
        title: 'Hace un mes',
        subtitle: '',
        iconPath: ConfigureSeedWizardAssets.treeGrowingOnly,
      ),
      _OnboardingTreeOptionData(
        id: TreeAnchorWizardOptionIds.unknown,
        title: 'No lo recuerdo',
        subtitle: '',
        iconPath: ConfigureSeedWizardAssets.treeUnknownState,
      ),
    ];
  }

  Widget _buildTreeStagePage() {
    final stage = _draft.stage;
    final productionStatusId = _draft.treeProductionStatusId;
    final showingProductionQuestion =
        productionStatusId == null ||
        normalizeTreeProductionStatusId(productionStatusId) ==
            TreeProductionStatusIds.unknown;
    final bool isNonProductive =
        normalizeTreeProductionStatusId(productionStatusId) ==
        TreeProductionStatusIds.nonProductive;
    final options = showingProductionQuestion
        ? _treeProductionStatusOptions
        : _treeVisibleStageOptions(productionStatusId);

    final String title = showingProductionQuestion
        ? '¿Tu árbol ya da fruta?'
        : (isNonProductive
              ? '¿Ahorita le ves flor o frutito?'
              : '¿Cómo se ve tu árbol hoy?');

    return CenteredWizardPage(
      scrollable: true,
      horizontalPadding: 4,
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(width: 274),
          const SizedBox(height: 22),
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
          const SizedBox(height: 24),
          ...options.asMap().entries.map((entry) {
            final option = entry.value;
            final selected = showingProductionQuestion
                ? productionStatusId == option.id
                : (isNonProductive
                      ? _draft.treeAnchorOptionId == null &&
                            _reproSignalMatchesDraft(option.id)
                      : stage == option.id);
            final iconPath = showingProductionQuestion
                ? _treeProductionStatusIcon(option.id)
                : (isNonProductive
                      ? _treeReproSignalIcon(option.id)
                      : _treeStageIcon(option.id));
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: StaggerIn(
                delay: 90 + (entry.key.clamp(0, 8)) * 40,
                child: _wizardPill(
                  iconPath: iconPath,
                  title: option.title,
                  subtitle: option.subtitle,
                  selected: selected,
                  enabled: true,
                  onTap: () => showingProductionQuestion
                      ? _onSelectTreeProductionStatus(option.id)
                      : (isNonProductive
                            ? _onSelectTreeReproSignal(option.id)
                            : _onSelectTreeVisibleStage(option.id)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Marca la tarjeta de señal reproductiva seleccionada en la pantalla 2B.
  /// Como la señal no se persiste, se infiere del estado derivado en el draft.
  bool _reproSignalMatchesDraft(String signalId) {
    final stage = normalizeTreeStageId(_draft.stage);
    return switch (signalId) {
      TreeReproSignalOptionIds.hasFlower => stage == TreeStageIds.flowering,
      TreeReproSignalOptionIds.hasFruitSet => stage == TreeStageIds.fruitSet,
      TreeReproSignalOptionIds.hasFruitFill => stage == TreeStageIds.fruitFill,
      TreeReproSignalOptionIds.growingOnly => isOnboardingTreePlantingBranch(
        productionStatusId: _draft.treeProductionStatusId,
        phenologyStageId: _draft.stage,
      ),
      TreeReproSignalOptionIds.notSure => stage == TreeStageIds.unknown,
      _ => false,
    };
  }

  String _treeAnchorQuestionTitle({required bool isPlanting}) {
    if (isPlanting) {
      return '¿Cuándo lo plantaste o trasplantaste?';
    }

    return switch (normalizeTreeStageId(_draft.stage)) {
      TreeStageIds.flowering => '¿Hace cuánto empezó a florear?',
      TreeStageIds.budbreak => '¿Hace cuánto empezó a brotar?',
      TreeStageIds.fruitSet => '¿Hace cuánto viste el frutito?',
      TreeStageIds.fruitFill => '¿Hace cuánto empezó a crecer el fruto?',
      TreeStageIds.harvestMaturity =>
        '¿Hace cuánto empezó a madurar o estar listo para pisca?',
      TreeStageIds.postHarvest => '¿Hace cuánto cosechaste?',
      TreeStageIds.dormancy => '¿Hace cuánto tiró la hoja?',
      _ => '¿Hace cuánto empezó esta etapa?',
    };
  }

  Widget _buildDatePage() {
    if (_isTreeDraft) {
      return _buildTreeAnchorPage();
    }

    final selectedDate = _draft.selectedDate ?? DateTime.now();

    return CenteredWizardPage(
      scrollable: true,
      horizontalPadding: 4,
      topPadding: 4,
      child: Column(
        children: [
          const BrandMark(width: 274),
          const SizedBox(height: 18),
          StaggerIn(
            delay: 0,
            child: Text(
              _dateQuestionTitle,
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
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  onDateChanged: (DateTime value) {
                    _updateDraft(
                      _draft.copyWith(
                        selectedDate: value,
                        useFlexibleDate: false,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          StaggerIn(
            delay: 130,
            child: FlexibleDateCard(
              label: _dateFlexibleLabel,
              description: _dateFlexibleDescription,
              selected: _draft.useFlexibleDate,
              onTap: () {
                _updateDraft(
                  _draft.copyWith(useFlexibleDate: !_draft.useFlexibleDate),
                );
              },
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
                  const WizardAssetIcon(
                    assetPath: ConfigureSeedWizardAssets.categoryGeneric,
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
                      _dateHelperText,
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTreeAnchorPage() {
    final selectedDate = _draft.selectedDate ?? DateTime.now();
    final bool isPlanting = _isTreePlantingAnchor;
    final options = _treeAnchorOptions(isPlanting: isPlanting);
    final showCalendar =
        _draft.treeAnchorOptionId == TreeAnchorWizardOptionIds.custom;

    return CenteredWizardPage(
      scrollable: true,
      horizontalPadding: 4,
      topPadding: 4,
      child: Column(
        children: [
          const BrandMark(width: 274),
          const SizedBox(height: 18),
          StaggerIn(
            delay: 0,
            child: Text(
              _treeAnchorQuestionTitle(isPlanting: isPlanting),
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
          for (final entry in options.asMap().entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: StaggerIn(
                delay: 90 + entry.key * 40,
                child: _wizardPill(
                  iconPath: _treeAnchorIcon(
                    entry.value.id,
                    entry.value.iconPath,
                  ),
                  title: entry.value.title,
                  subtitle: entry.value.subtitle,
                  selected: _draft.treeAnchorOptionId == entry.value.id,
                  enabled: true,
                  onTap: () => _onSelectTreeAnchorOption(entry.value.id),
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
                      onDateChanged: (DateTime value) {
                        _updateDraft(
                          _draft.copyWith(
                            treeAnchorOptionId:
                                TreeAnchorWizardOptionIds.custom,
                            selectedDate: value,
                            useFlexibleDate: false,
                          ),
                        );
                      },
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
                    assetPath: _draft.cropId == null
                        ? ConfigureSeedWizardAssets.categoryTree
                        : _cropIconPath(_draft.cropId!),
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
                      isPlanting
                          ? 'Con esto BIO-G calcula la edad y la etapa aproximada del árbol.'
                          : 'Esta fecha se guarda como anclaje de etapa, no como edad del árbol.',
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Pill builders with doubled icon scale ───

  Widget _wizardPill({
    required String iconPath,
    required String title,
    required String subtitle,
    required bool selected,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final borderColor = selected
        ? const Color(0xFF8EB07C)
        : Colors.white.withValues(alpha: 0.94);

    final bgColor = selected
        ? const Color(0xFFF0F7EE).withValues(alpha: 0.96)
        : const Color(0xFFF7F8F8).withValues(alpha: 0.94);

    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: BioGGlassCard(
          radius: 22,
          backgroundColor: bgColor,
          borderColor: borderColor,
          padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
          child: Row(
            children: [
              WizardAssetIcon(
                assetPath: iconPath,
                slotWidth: 44,
                slotHeight: 44,
                imageWidth: 44,
                imageHeight: 44,
                scale: _iconScale,
                offsetX: -10,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.2,
                        height: 1.18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: Color(0xFF303836),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.6,
                          color: Colors.black.withValues(alpha: 0.44),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : enabled
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
                color: selected
                    ? const Color(0xFF8DB379)
                    : const Color(0xFF9AB58A),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectionPill({
    required String iconPath,
    required String title,
    required String value,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final selectedBg = const Color(0xFFF0F7EE).withValues(alpha: 0.96);
    final normalBg = const Color(0xFFF7F8F8).withValues(alpha: 0.94);

    return Opacity(
      opacity: onTap == null && !selected ? 0.84 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: BioGGlassCard(
          radius: 22,
          backgroundColor: selected ? selectedBg : normalBg,
          borderColor: selected
              ? const Color(0xFF8EB07C)
              : Colors.white.withValues(alpha: 0.94),
          padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
          child: Row(
            children: [
              WizardAssetIcon(
                assetPath: iconPath,
                slotWidth: 44,
                slotHeight: 44,
                imageWidth: 44,
                imageHeight: 44,
                scale: _iconScale,
                offsetX: -10,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                              color: Color(0xFF303836),
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7EE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Listo',
                              style: TextStyle(
                                fontSize: 10.8,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B8E62),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.black.withValues(alpha: 0.50),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                onTap == null
                    ? (selected
                          ? Icons.check_circle_rounded
                          : Icons.lock_outline_rounded)
                    : Icons.chevron_right_rounded,
                color: selected
                    ? const Color(0xFF8DB379)
                    : const Color(0xFF9AB58A),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final OnboardingStepController controller = OnboardingStepController(
      step: _currentStep,
      draft: _draft,
      onChanged: _updateDraft,
      onContinue: _handleContinue,
      onBack: _handleBack,
      canContinue: _canContinueFromCurrentStep,
      isFirstStep: _isFirstStep,
      isLastStep: _isLastStep,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _WizardTopBar(
                      currentStepIndex: _steps.indexOf(_currentStep),
                      totalSteps: _steps.length,
                      onBack: _handleBack,
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeInQuart,
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
                        return FadeTransition(
                          opacity: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutQuart,
                          ),
                          child: child,
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<OnboardingStep>(_currentStep),
                        child: widget.stepBuilder != null
                            ? widget.stepBuilder!(context, controller)
                            : _buildDefaultStep(controller),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                8,
                0,
                8,
                12 + MediaQuery.of(context).padding.bottom * 0.25,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  BioGButton(
                    label: _continueLabel,
                    onTap: _canContinueFromCurrentStep ? _handleContinue : null,
                    loading: _submitting,
                    height: 54,
                    radius: 18,
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _submitting ? null : _handleSkip,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Omitir',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A9399),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingStepController {
  final OnboardingStep step;
  final OnboardingDraft draft;
  final ValueChanged<OnboardingDraft> onChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final bool canContinue;
  final bool isFirstStep;
  final bool isLastStep;

  const OnboardingStepController({
    required this.step,
    required this.draft,
    required this.onChanged,
    required this.onContinue,
    required this.onBack,
    required this.canContinue,
    required this.isFirstStep,
    required this.isLastStep,
  });

  void updateDraft(OnboardingDraft nextDraft) => onChanged(nextDraft);
}

class _OnboardingTreeOptionData {
  const _OnboardingTreeOptionData({
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

class _WizardTopBar extends StatelessWidget {
  final int currentStepIndex;
  final int totalSteps;
  final VoidCallback onBack;

  const _WizardTopBar({
    required this.currentStepIndex,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
      child: Row(
        children: <Widget>[
          BioGGlassCard(
            radius: 16,
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 42,
              height: 42,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF274A44),
                ),
              ),
            ),
          ),
          const Spacer(),
          BioGGlassCard(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                totalSteps,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: index == currentStepIndex ? 18 : 7,
                  height: 7,
                  margin: EdgeInsets.only(
                    right: index == totalSteps - 1 ? 0 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: index == currentStepIndex
                        ? const Color(0xFF82A775)
                        : index < currentStepIndex
                        ? const Color(0xFF82A775).withValues(alpha: 0.40)
                        : Colors.black.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 42, height: 42),
        ],
      ),
    );
  }
}
