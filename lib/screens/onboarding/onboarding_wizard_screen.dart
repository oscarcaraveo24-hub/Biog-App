import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'package:bio_g/core/crops/apple_tree/apple_tree_assets.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/generic/generic_guide.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_assets.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_assets.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_assets.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_assets.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_assets.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_assets.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_assets.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_assets.dart';
import 'package:bio_g/core/crops/cactus/cactus_assets.dart';
import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/recurring_bloom/recurring_bloom_crops.dart';
// Tulipán (seasonal_bulb): capa compartida del modo bulboso estacional.
import 'package:bio_g/core/crops/seasonal_bulb/seasonal_bulb_crops.dart';
// Girasol (annual_ornamental): capa compartida del modo anual ornamental.
import 'package:bio_g/core/crops/annual_ornamental/annual_ornamental_crops.dart';
import 'package:bio_g/core/crops/succulent/succulent_assets.dart';
import 'package:bio_g/core/crops/aloe/aloe_assets.dart';
import 'package:bio_g/core/crops/agave/agave_assets.dart';
import 'package:bio_g/core/agro/cultivation_scale.dart';
import 'package:bio_g/core/geo/geocoding_service.dart';
import 'package:bio_g/core/profile/parcel_location_store.dart';
import 'package:bio_g/core/agro/water/soil_texture_source.dart';
import 'package:bio_g/core/agro/water/soil_water_scale.dart';
import 'package:bio_g/core/hardware/biog_serial.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/tree_profile_presentation.dart';
import 'package:bio_g/models/onboarding/onboarding_draft.dart';
import 'package:bio_g/models/onboarding/onboarding_step.dart';
import 'package:bio_g/screens/onboarding/steps/location_step.dart';
import 'package:bio_g/screens/onboarding/steps/soil_texture_step.dart';
import 'package:bio_g/screens/onboarding/steps/pair_biog_step.dart';
import 'package:bio_g/widgets/onboarding/soil_texture_guide_sheet.dart';
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
    OnboardingStep.soilTexture,
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

  /// El paso de tierra se salta cuando la escala ya contestó la pregunta.
  ///
  /// En maceta el medio es sustrato, no suelo mineral, y preguntar por
  /// «arenosa o arcillosa» sería pedir un dato que no se va a usar: el resolver
  /// lo derivará del modelo del equipo o de la escala. A largo plazo el
  /// hardware es la autoridad, pero el emparejamiento ocurre **después** de
  /// este paso, así que aquí manda la escala y el emparejamiento final valida
  /// la compatibilidad.
  bool get _skipsSoilTextureStep =>
      // Se pregunta al MISMO conversor que usa el resolver. Duplicar aquí la
      // lista de alias ('pot', 'maceta', 'planta'…) garantizaría que las dos
      // definiciones de «esto es maceta» se separen con el tiempo.
      cultivationScaleFromId(_draft.cultivationScale) == CultivationScale.pot;

  /// Los pasos que el productor va a ver **de verdad**.
  ///
  /// `_steps` es el guion completo. En maceta el paso de tierra no se muestra, y
  /// contarlo igualmente hacía dos cosas mal a la vez: la barra decía «Paso 4 de
  /// 8» en una secuencia de siete pantallas, y el riel dibujaba un peldaño que
  /// nunca se pisa. El total tiene que ser el de la ruta real.
  List<OnboardingStep> get _visibleSteps => _skipsSoilTextureStep
      ? _steps
            .where((s) => s != OnboardingStep.soilTexture)
            .toList(growable: false)
      : _steps;

  bool get _isTreeDraft =>
      isTreeCrop(cropId: _draft.cropId, cropCategoryId: _draft.cropCategory);

  /// Guía general: "Otro". Ni cultivo, ni variedad, ni etapa, ni fecha.
  bool get _isGuideDraft =>
      isGuideCropId(_draft.cropId) || isGuideCropId(_draft.cropCategory);
  /// Ornamental de establecimiento + mantenimiento (cactus, suculenta…).
  bool get _isOrnamentalDraft => isEstablishmentMaintenanceCrop(
    cropId: _draft.cropId,
    cropCategoryId: _draft.cropCategory,
  );

  /// cropId canónico de la ornamental seleccionada (para textos y assets).
  String? get _ornamentalCropId => ornamentalCropIdOrNull(_draft.cropId);

  /// Tulipán (seasonal_bulb): ornamental bulbosa estacional. Elige PERFIL como
  /// una ornamental, pero su alta/fecha/persistencia siguen la ruta de GRANO
  /// (ancla real: conserva el sowingDate). Por eso NO es `_isOrnamentalDraft`.
  bool get _isSeasonalBulbDraft => isSeasonalBulbCrop(
    cropId: _draft.cropId,
    cropCategoryId: _draft.cropCategory,
  );

  /// cropId canónico del bulboso estacional seleccionado (para textos y assets).
  String? get _seasonalBulbCropId => seasonalBulbCropIdOrNull(_draft.cropId);

  /// Girasol (annual_ornamental): ornamental anual verdadera. Elige PERFIL como
  /// una ornamental, pero su alta/fecha/persistencia siguen la ruta de GRANO
  /// (ancla real: conserva el sowingDate). Por eso NO es `_isOrnamentalDraft`.
  bool get _isAnnualOrnamentalDraft => isAnnualOrnamentalCrop(
    cropId: _draft.cropId,
    cropCategoryId: _draft.cropCategory,
  );

  /// cropId canónico de la ornamental anual seleccionada (para textos y assets).
  String? get _annualOrnamentalCropId =>
      annualOrnamentalCropIdOrNull(_draft.cropId);

  /// Ornamental de floración recurrente (rosal): usa selección VISUAL de estado.
  bool get _isRecurringBloomDraft => isRecurringBloomCrop(
    cropId: _draft.cropId,
    cropCategoryId: _draft.cropCategory,
  );

  /// Opción de estado visual del rosal seleccionada (guardada en draft.stage).
  RecurringBloomStateOption? get _selectedRecurringBloomOption {
    if (!_isRecurringBloomDraft || _draft.stage == null) return null;
    for (final option in recurringBloomVisualStateOptions(_draft.cropId)) {
      if (option.id == _draft.stage) return option;
    }
    return null;
  }

  bool get _isRecurringBloomFutureIntent =>
      _isRecurringBloomDraft &&
      (_selectedRecurringBloomOption?.requiresFutureDate ?? false);
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

    // El contrato de la pantalla de tierra pide háptica de éxito al confirmar,
    // distinta del pulso ligero que acompaña a cada cambio de textura. Va acotada
    // a ese paso: dar la misma vibración en los ocho cambiaría el tacto del
    // wizard entero, que no es lo que se pidió.
    if (_currentStep == OnboardingStep.soilTexture) {
      HapticFeedback.mediumImpact();
    }

    if (_isLastStep) {
      await _finishFlow();
      return;
    }

    if (_currentStep == OnboardingStep.cropStage &&
        _isTreeUnknownStageSelection) {
      setState(() => _currentStep = OnboardingStep.pairBioG);
      return;
    }

    // Maceta: el medio ya está decidido por la escala. Se salta la pregunta y
    // se deja constancia de POR QUÉ no se preguntó, para que el historial
    // pueda distinguir «no se preguntó» de «no contestó».
    if (_currentStep == OnboardingStep.cultivationScale &&
        _skipsSoilTextureStep) {
      _updateDraft(
        _draft.copyWith(
          soilTextureId: null,
          soilTextureSource: SoilTextureSource.derivedFromScale.id,
        ),
      );
      setState(() => _currentStep = OnboardingStep.cropCategory);
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

    // Guía general: se saltó de categoría a emparejamiento, así que la vuelta
    // tiene que regresar a categoría y no al paso de fecha, que nunca se vio.
    if (_currentStep == OnboardingStep.pairBioG && _isGuideDraft) {
      setState(() => _currentStep = OnboardingStep.cropCategory);
      return;
    }

    // Simétrico del salto de maceta: si la tierra no se preguntó, la vuelta no
    // puede aterrizar en una pantalla que el usuario nunca vio.
    if (_currentStep == OnboardingStep.cropCategory && _skipsSoilTextureStep) {
      setState(() => _currentStep = OnboardingStep.cultivationScale);
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
      case OnboardingStep.soilTexture:
        // El estado inicial NO cuenta como respuesta. La pantalla muestra
        // Franca como vista inicial, pero el botón queda deshabilitado hasta
        // que hay una interacción explícita: quien no toca nada no ha
        // declarado nada, y esa diferencia decide si la recomendación lleva
        // penalización de confianza.
        return _draft.soilTextureId?.isNotEmpty ?? false;
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

  String get _continueLabel {
    if (_isLastStep) return 'Finalizar';
    if (_currentStep == OnboardingStep.soilTexture) return 'Usar esta tierra';
    return 'Continuar';
  }

  /// La nota al pie que sustituye a «Omitir» en el paso de tierra.
  ///
  /// Omitir aquí guardaría el hueco como «no contestó»: el resolver caería a
  /// media con penalización de confianza… que es exactamente lo que hace «No
  /// estoy seguro», con la diferencia de que esa opción **sí deja constancia de
  /// que se preguntó**. Dos caminos al mismo estado, uno de ellos mudo, es un
  /// camino de más y encima destruye la métrica de adopción. En su lugar se dice
  /// lo único que el productor necesita para no sentirse atrapado.
  String? get _footerNoteEs => _currentStep == OnboardingStep.soilTexture
      // Se nombra la ruta REAL. «Configuración de tu parcela» no existe en la
      // app; prometer reversibilidad señalando a una pantalla inventada es peor
      // que no prometer nada.
      ? 'Puedes cambiarlo después en Cuenta → Tipo de suelo.'
      : null;

  /// La «?» de la barra superior en el paso de tierra.
  ///
  /// La guía se abre **desde aquí** y no a través de una llave global sobre el
  /// estado del paso. `AnimatedSwitcher` conserva la pantalla saliente mientras
  /// se desvanece, así que ir y volver deprisa deja dos `SoilTextureStep` vivos
  /// a la vez: con `GlobalKey` eso es un fallo duro de framework, no un parpadeo.
  /// El paso ya reacciona a `selectedTextureId` desde `didUpdateWidget`, y sin
  /// volver a reportar —la procedencia correcta la escribe esta función—.
  Future<void> _handleSoilGuide() async {
    final SoilTexture? result = await showSoilTextureGuideSheet(context);
    if (result == null || !mounted) return;

    HapticFeedback.lightImpact();
    _updateDraft(
      _draft.copyWith(
        soilTextureId: result.id,
        soilTextureSource: SoilTextureSource.guidedEstimate.id,
      ),
    );
  }

  // ─── Handlers ───

  static const GeocodingService _geocoder = GeocodingService();

  /// Nombre legible del punto, o el respaldo genérico si no se puede saber.
  ///
  /// Aquí había una copia propia del geocodificado inverso que devolvía
  /// `formatted_address` tal cual. El mismo punto producía «Camino a Satevó
  /// s/n, Chihuahua, Chih., México» en la pantalla de Ubicación —que sí sabía
  /// reconstruir direcciones rurales— y «52JHG+Q8 Chihuahua, Chih., México»
  /// aquí, porque Google devuelve un plus code cuando el punto no cae sobre
  /// una dirección postal, que es el caso normal de una parcela.
  Future<String> _reverseGeocodeLabel(double lat, double lng) async {
    try {
      return await _geocoder.reverseGeocode(lat, lng);
    } on GeocodingException {
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

      // 5. Persistir. `ParcelLocationStore` escribe las dos claves de
      //    preferencias que lee la app (la del motor de clima y la que pinta
      //    la Cuenta) y espeja a Supabase, así que la ubicación elegida en el
      //    alta sobrevive a una reinstalación.
      await ParcelLocationStore.save(
        lat: lat,
        lng: lng,
        label: label,
        origin: ParcelLocationOrigin.gps,
      );

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

    // La pantalla de Ubicación ya persistió el punto al pulsar «Guardar»; aquí
    // solo se recoge para el borrador.
    final StoredParcelLocation? saved = await ParcelLocationStore.readLocal();
    final double? lat = saved?.lat;
    final double? lng = saved?.lng;

    // Si no hay coordenadas guardadas, no se inventan.
    //
    // Aquí había un respaldo `?? 19.4326 / ?? -99.1332` (CDMX) que se escribía
    // en `geoLat`/`geoLng` del borrador y de ahí pasaba al `DeviceCropContext`,
    // a la columna `geo_lat` de la nube y al motor de riego, que las trataba
    // como la parcela real del agricultor. Un borrador sin coordenadas el resto
    // de la app ya sabe manejarlo; uno con coordenadas falsas es indistinguible
    // de uno bueno.
    _updateDraft(
      (lat != null && lng != null)
          ? _draft.copyWith(
              locationSource: 'map',
              locationLabel: result,
              geoLat: lat,
              geoLng: lng,
              timezone: 'America/Mexico_City',
            )
          : _draft.copyWith(
              locationSource: 'map',
              locationLabel: result,
              // Nulos EXPLÍCITOS. `copyWith` usa centinela: omitir el campo
              // conserva el valor anterior, así que sin esto quedaría la
              // etiqueta nueva pegada a las coordenadas viejas — que es la
              // misma clase de dato falso que se acaba de quitar, solo que más
              // difícil de detectar.
              geoLat: null,
              geoLng: null,
              timezone: 'America/Mexico_City',
            ),
    );
  }

  Future<void> _handleScanQr() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      BioGPageRoute<Map<String, dynamic>>(builder: (_) => const QrScanScreen()),
    );

    if (result == null || !mounted) return;
    _adoptPairedDevice(result);
  }

  Future<void> _handleConnectBluetooth() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      BioGPageRoute<Map<String, dynamic>>(
        builder: (_) => const BluetoothScanScreen(),
      ),
    );

    if (result == null || !mounted) return;
    _adoptPairedDevice(result);
  }

  /// Conserva la identidad completa del equipo, no solo el nombre.
  ///
  /// Antes esta función guardaba `result['name']` y descartaba el resto. El
  /// efecto no se veía en pantalla —el usuario leía «conectado correctamente»—
  /// pero el dispositivo se creaba después sin modelo y con un UUID inventado
  /// por el teléfono, así que nunca encontraría su telemetría y el medio de
  /// cultivo quedaba indeterminado para siempre.
  ///
  /// El arreglo ya existía en la pantalla de Cuenta; aquí solo se replica.
  void _adoptPairedDevice(Map<String, dynamic> result) {
    final name = (result['name'] as String?)?.trim();
    final hardwareId = (result['id'] as String?)?.trim();
    final serial = (result['serial'] as String?)?.trim();

    // El modelo declarado se cruza contra la serie: si la etiqueta trae una
    // serie válida, ESA manda, porque va impresa en el aparato.
    final parsedSerial = BioGSerial.tryParse(serial);
    final String? modelId =
        parsedSerial?.deviceModelId ??
        (result['model'] ?? result['deviceModelId'])?.toString().trim();

    final resolvedName = (name == null || name.isEmpty) ? 'Bio-G' : name;

    setState(() {
      _pairedDeviceName = resolvedName;
      _draft = _draft.copyWith(
        pairedDeviceName: resolvedName,
        pairedHardwareId: (hardwareId == null || hardwareId.isEmpty)
            ? null
            : hardwareId,
        pairedDeviceModelId: (modelId == null || modelId.isEmpty)
            ? null
            : modelId,
      );
    });

    final model = deviceModelFromId(modelId);
    final modelLabel = model == null
        ? null
        : switch (model) {
            BioGDeviceModel.campo => 'Campo',
            BioGDeviceModel.huerto => 'Huerto',
            BioGDeviceModel.maceta => 'Maceta',
          };

    // ── La validación de compatibilidad que el paso de tierra promete ───────
    //
    // El paso de suelo se salta cuando la escala dice maceta, y se justifica
    // diciendo que «el emparejamiento final valida la compatibilidad». Aquí es
    // donde eso tiene que ocurrir: a largo plazo el hardware es la autoridad
    // sobre el medio, pero el emparejamiento pasa DESPUÉS de la pregunta, así
    // que una incompatibilidad hay que detectarla y decirla, no ignorarla.
    final scale = cultivationScaleFromId(_draft.cultivationScale);
    final bool mismatch =
        model != null &&
        scale != null &&
        ((model == BioGDeviceModel.maceta) != (scale == CultivationScale.pot));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: mismatch
            ? const Duration(seconds: 6)
            : const Duration(seconds: 4),
        content: Text(
          mismatch
              ? '$resolvedName es un BIO-G $modelLabel, y dijiste que cultivas '
                    'en ${scale == CultivationScale.pot ? 'maceta' : 'campo o huerto'}. '
                    'BIO-G usará lo que dice el equipo; puedes ajustar el resto '
                    'después desde Cuenta.'
              : '$resolvedName conectado correctamente'
                    '${modelLabel == null ? '' : ' · $modelLabel'}.',
        ),
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

    // Misma regla que en `_handleContinue`: omitir la escala con maceta ya
    // elegida no puede aterrizar en una pregunta que no aplica.
    if (_currentStep == OnboardingStep.cultivationScale &&
        _skipsSoilTextureStep) {
      _updateDraft(
        _draft.copyWith(
          soilTextureId: null,
          soilTextureSource: SoilTextureSource.derivedFromScale.id,
        ),
      );
      setState(() => _currentStep = OnboardingStep.cropCategory);
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

    // Guía general: no hay cultivo que elegir, ni variedad, ni etapa, ni fecha
    // de siembra. Se fija el cultivo centinela y se salta directo al
    // emparejamiento, igual que ya hace el flujo de árbol con etapa
    // desconocida.
    if (value == kGuideCategoryId) {
      _updateDraft(
        _draft.copyWith(
          cropCategory: kGuideCategoryId,
          cropId: kGuideCropId,
          brandId: null,
          varietyId: null,
          varietyAlias: null,
          treeProductionStatusId: null,
          stage: kGuideStageKey,
          treeAnchorOptionId: null,
          selectedDate: null,
          useFlexibleDate: false,
        ),
      );
      _animateToStep(OnboardingStep.pairBioG);
      return;
    }

    _animateToStep(OnboardingStep.cropDetails);
  }

  Future<void> _openCropSelector() async {
    if (_draft.cropCategory != CropCatalog.grainCategoryId &&
        _draft.cropCategory != CropCatalog.vegetableCategoryId &&
        _draft.cropCategory != CropCatalog.treeCategoryId &&
        _draft.cropCategory != CropCatalog.ornamentalCategoryId) {
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

    // Las ornamentales usan perfiles (CA-* / SU-*) mostrados como "tipos".
    if (isEstablishmentMaintenanceCrop(
      cropId: cropId,
      cropCategoryId: _draft.cropCategory,
    )) {
      await _openOrnamentalProfileSelector();
      return;
    }

    // El rosal (floración recurrente) también usa perfiles como "tipos".
    if (isRecurringBloomCrop(
      cropId: cropId,
      cropCategoryId: _draft.cropCategory,
    )) {
      await _openRecurringBloomProfileSelector();
      return;
    }

    // El tulipán (seasonal_bulb) también elige PERFIL como "tipo", aunque su alta
    // siga el flujo de grano. Sin esta rama caería al selector de variedades de
    // semilla, que está vacío para el tulipán.
    if (isSeasonalBulbCrop(
      cropId: cropId,
      cropCategoryId: _draft.cropCategory,
    )) {
      await _openSeasonalBulbProfileSelector();
      return;
    }

    // El girasol (annual_ornamental) también elige PERFIL como "tipo", aunque
    // su alta siga el flujo de grano. Sin esta rama caería al selector de
    // variedades de semilla, que está vacío para el girasol.
    if (isAnnualOrnamentalCrop(
      cropId: cropId,
      cropCategoryId: _draft.cropCategory,
    )) {
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

    // Perfiles ornamentales canónicos, con la opción general primero.
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

  /// Selector de tipo para las ornamentales. El perfil general va AL FINAL de la
  /// lista (el catálogo ya lo ordena así) y NUNCA se muestra "SKIP" ni el id.
  Future<void> _openOrnamentalProfileSelector() async {
    final cropId = _draft.cropId;
    if (cropId == null) return;

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

    _updateDraft(
      _draft.copyWith(
        // En una ornamental, "variedad/tipo" es el perfil (CA-* / SU-*).
        varietyId: result,
        varietyAlias: result,
        stage: null,
        selectedDate: null,
        useFlexibleDate: false,
      ),
    );

    _animateToStep(OnboardingStep.cropStage);
  }

  /// Selector de perfil del rosal (floración recurrente) en el onboarding.
  Future<void> _openRecurringBloomProfileSelector() async {
    final cropId = _draft.cropId;
    if (cropId == null) return;

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

    _updateDraft(
      _draft.copyWith(
        varietyId: result,
        varietyAlias: result,
        stage: null,
        selectedDate: null,
        useFlexibleDate: false,
      ),
    );

    _animateToStep(OnboardingStep.cropStage);
  }

  /// Selector de tipo del Tulipán (seasonal_bulb) en el onboarding. Espejo del
  /// selector ornamental (perfiles en ORDEN del catálogo con el general al final,
  /// íconos ic_tulip_*, nunca el id interno). Tras elegir, pasa a la etapa de
  /// GRANO (planned/planted) para conservar el sowingDate como ancla real.
  Future<void> _openSeasonalBulbProfileSelector() async {
    final cropId = _draft.cropId;
    if (cropId == null) return;

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

    _updateDraft(
      _draft.copyWith(
        // En el tulipán, "tipo" es el perfil (tu_*). El alta sigue el flujo de
        // grano; la fecha se conservará como sowingDate.
        varietyId: result,
        varietyAlias: result,
        stage: null,
        selectedDate: null,
        useFlexibleDate: false,
      ),
    );

    _animateToStep(OnboardingStep.cropStage);
  }

  /// Selector de tipo del Girasol (annual_ornamental) en el onboarding. Espejo
  /// del selector ornamental (perfiles en ORDEN del catálogo con el general al
  /// final, íconos ic_girasol_*, nunca el id interno). Tras elegir, pasa a la
  /// etapa de GRANO (planned/planted) para conservar el sowingDate como ancla
  /// real.
  Future<void> _openAnnualOrnamentalProfileSelector() async {
    final cropId = _draft.cropId;
    if (cropId == null) return;

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

    _updateDraft(
      _draft.copyWith(
        // En el girasol, "tipo" es el perfil (gi_*). El alta sigue el flujo de
        // grano; la fecha se conservará como sowingDate.
        varietyId: result,
        varietyAlias: result,
        stage: null,
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
    final bool isOrnamental = _isOrnamentalDraft;
    final bool ornamentalFutureIntent =
        isOrnamental &&
        ornamentalSetupIntentRequiresFutureDate(_ornamentalCropId, value);
    _updateDraft(
      _draft.copyWith(
        stage: value,
        selectedDate: isRestStage
            ? null
            : isOrnamental
            ? (ornamentalFutureIntent
                  ? DateTime.now().add(const Duration(days: 1))
                  : DateTime.now())
            : _draft.selectedDate,
        useFlexibleDate: isRestStage
            ? true
            : isOrnamental
            ? false
            : _draft.useFlexibleDate,
      ),
    );

    if (isRestStage) {
      _animateToStep(OnboardingStep.pairBioG);
    } else {
      _animateToStep(OnboardingStep.cropDate);
    }
  }

  /// Selección del estado VISUAL del rosal en el onboarding. Guarda el id de la
  /// opción en draft.stage y ajusta la fecha inicial según si pide fecha futura.
  void _onSelectRecurringBloomState(String optionId) {
    RecurringBloomStateOption? option;
    for (final candidate in recurringBloomVisualStateOptions(_draft.cropId)) {
      if (candidate.id == optionId) {
        option = candidate;
        break;
      }
    }
    final bool requiresFuture = option?.requiresFutureDate ?? false;
    _updateDraft(
      _draft.copyWith(
        stage: optionId,
        selectedDate: requiresFuture
            ? DateTime.now().add(const Duration(days: 1))
            : DateTime.now(),
        useFlexibleDate: false,
      ),
    );
    _animateToStep(OnboardingStep.cropDate);
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
      // Las ornamentales usan etiquetas humanas directas del catálogo (sin
      // códigos CA-/SU-).
      if (isEstablishmentMaintenanceCrop(
        cropId: cropId,
        cropCategoryId: _draft.cropCategory,
      )) {
        return profile.label;
      }
      // Tulipán (seasonal_bulb): etiqueta humana directa del perfil (sin id tu_*).
      if (isSeasonalBulbCrop(
        cropId: cropId,
        cropCategoryId: _draft.cropCategory,
      )) {
        return profile.label;
      }
      // Girasol (annual_ornamental): etiqueta humana directa del perfil (sin id
      // gi_*).
      if (isAnnualOrnamentalCrop(
        cropId: cropId,
        cropCategoryId: _draft.cropCategory,
      )) {
        return profile.label;
      }
      return TreeProfilePresentation.displayLabel(
        cropId,
        profile.id,
        fallbackLabel: profile.label,
      );
    }

    return 'Seleccionar';
  }

  String get _dateQuestionTitle {
    if (_isRecurringBloomDraft) {
      return recurringBloomDateQuestionTitle(
        _draft.cropId,
        _selectedRecurringBloomOption?.intentId,
      );
    }
    if (_isOrnamentalDraft) {
      return ornamentalDateQuestionTitle(_ornamentalCropId, _draft.stage);
    }
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
    if (_isOrnamentalDraft) {
      return ornamentalDateFlexibleLabel(_ornamentalCropId, _draft.stage);
    }
    if (_draft.stage == 'planned') return 'No tengo fecha aún';
    return 'No lo recuerdo muy bien';
  }

  String get _dateFlexibleDescription {
    if (_isOrnamentalDraft) {
      return ornamentalDateFlexibleDescription(_ornamentalCropId, _draft.stage);
    }
    if (_draft.stage == 'planned') {
      return 'Bio-G usará una referencia flexible y podrás actualizarla después.';
    }
    return 'Usaremos la fecha seleccionada como aproximada para interpretar mejor tu etapa.';
  }

  String get _dateHelperText {
    if (_isOrnamentalDraft) {
      return ornamentalDateHelperText(_ornamentalCropId, _draft.stage);
    }
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
        return CactusAssets.cropIcon;
      case CropCatalog.succulentCropId:
        return SucculentAssets.cropIcon;
      case CropCatalog.aloeCropId:
        return AloeAssets.cropIcon;
      case CropCatalog.agaveCropId:
        return AgaveAssets.cropIcon;
      // Nopal (establishment_maintenance): arte propio de la penca plana.
      case CropCatalog.nopalCropId:
        return ornamentalCropIcon(CropCatalog.canonicalCropKey(cropId));
      // Tulipán (seasonal_bulb): arte propio del bulbo, no el árbol ni genérico.
      case CropCatalog.tulipCropId:
        return seasonalBulbCropIcon(CropCatalog.canonicalCropKey(cropId));
      // Girasol y Cempasúchil (annual_ornamental): arte propio de cada anual,
      // no el árbol ni el genérico. `annualOrnamentalCropIcon` despacha por
      // cropId, así que ambos comparten el mismo cuerpo sin heredar arte.
      case CropCatalog.sunflowerCropId:
      case CropCatalog.marigoldCropId:
        return annualOrnamentalCropIcon(CropCatalog.canonicalCropKey(cropId));
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

      case OnboardingStep.soilTexture:
        // Los nombres locales («¿la conoces por otro nombre?») se retiraron de
        // la pantalla: no cambiaban ni la textura, ni la retención, ni el
        // drenaje, ni un solo cálculo del motor, y costaban el espacio vertical
        // que ahora ocupan retención y drenaje. Los campos del borrador siguen
        // existiendo y viajan intactos; simplemente ya no se capturan aquí.
        return SoilTextureStep(
          selectedTextureId: controller.draft.soilTextureId,
          onTextureChanged: (texture, source) {
            _updateDraft(
              _draft.copyWith(
                soilTextureId: texture.id,
                soilTextureSource: source.id,
              ),
            );
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
              subtitle: 'Cactus, suculentas y sábila · más ornamentales próximamente',
              selected: category == 'ornamental',
              enabled: true,
              onTap: () => _onSelectCategory('ornamental'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 310,
            child: _wizardPill(
              iconPath: ConfigureSeedWizardAssets.categoryGeneric,
              title: 'Otro / genérico',
              // Dice exactamente lo que entrega y lo que no. "Perfil general"
              // habría prometido nutrición, que es justo lo único que este modo
              // no puede dar.
              subtitle: 'Guía de suelo, sin recomendación de nutrición',
              selected: category == kGuideCategoryId,
              enabled: true,
              onTap: () => _onSelectCategory(kGuideCategoryId),
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
        : _isSeasonalBulbDraft
        ? seasonalBulbProfileIcon(
            _seasonalBulbCropId,
            _draft.varietyId ?? _draft.varietyAlias,
          )
        : _isAnnualOrnamentalDraft
        ? annualOrnamentalProfileIcon(
            _annualOrnamentalCropId,
            _draft.varietyId ?? _draft.varietyAlias,
          )
        : _isOrnamentalDraft
        ? ornamentalProfileIcon(
            _ornamentalCropId,
            _draft.varietyId ?? _draft.varietyAlias,
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
                  : _isOrnamentalDraft
                  ? ornamentalVarietyFlowSubtitle(_ornamentalCropId)
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
              fallbackAsset: _isOrnamentalDraft
                  ? kOrnamentalGenericPlantFallback
                  : _isSeasonalBulbDraft
                  ? kSeasonalBulbGenericPlantFallback
                  : _isAnnualOrnamentalDraft
                  ? kAnnualOrnamentalGenericPlantFallback
                  : 'assets/icons/wizard/ic_tree.png',
              title: 'Cultivo',
              value: cropLabel,
              selected: cropId != null,
              onTap:
                  (_draft.cropCategory == CropCatalog.grainCategoryId ||
                      _draft.cropCategory == CropCatalog.vegetableCategoryId ||
                      _draft.cropCategory == CropCatalog.treeCategoryId ||
                      _draft.cropCategory == CropCatalog.ornamentalCategoryId)
                  ? _openCropSelector
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 205,
            child: _selectionPill(
              iconPath: selectedVarietyIconPath,
              fallbackAsset: _isOrnamentalDraft
                  ? kOrnamentalGenericPlantFallback
                  : _isSeasonalBulbDraft
                  ? kSeasonalBulbGenericPlantFallback
                  : _isAnnualOrnamentalDraft
                  ? kAnnualOrnamentalGenericPlantFallback
                  : 'assets/icons/wizard/ic_tree.png',
              // Tulipán (seasonal_bulb) y Girasol (annual_ornamental): su "tipo"
              // es un PERFIL, igual que en las ornamentales.
              title:
                  _isOrnamentalDraft ||
                      _isSeasonalBulbDraft ||
                      _isAnnualOrnamentalDraft
                  ? 'Perfil'
                  : cropId != null &&
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
              _isOrnamentalDraft
                  ? ornamentalVarietyFlowHelper(_ornamentalCropId)
                  : 'Usar perfil genérico (recomendado si no sabes la variedad).',
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
    if (_isOrnamentalDraft) {
      return _buildOrnamentalStagePage();
    }
    if (_isRecurringBloomDraft) {
      return _buildRecurringBloomStagePage();
    }
    if (_isSeasonalBulbDraft) {
      return _buildSeasonalBulbStagePage();
    }
    if (_isAnnualOrnamentalDraft) {
      return _buildAnnualOrnamentalStagePage();
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

  /// Intención de alta de una ornamental. SOLO dos opciones: la voy a plantar /
  /// ya está plantada. "Cambio de maceta" NO es una forma de dar de alta una
  /// planta, y estrés, esqueje o juventud no son estados de alta.
  Widget _buildOrnamentalStagePage() {
    final stage = _draft.stage;
    final String? cropId = _ornamentalCropId;
    return CenteredWizardPage(
      horizontalPadding: 4,
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(width: 274),
          const SizedBox(height: 22),
          StaggerIn(
            delay: 0,
            child: Text(
              ornamentalStateQuestion(cropId),
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
          // Los MISMOS iconos de wizard que usa el grano (no imágenes de etapa).
          StaggerIn(
            delay: 90,
            child: _wizardPill(
              iconPath: 'assets/icons/wizard/ic_aun_no_siembro.png',
              title: ornamentalPlannedOptionTitle(cropId),
              subtitle: '',
              selected: stage == kOrnamentalIntentPlannedPlant,
              enabled: true,
              fallbackAsset: kOrnamentalGenericPlantFallback,
              onTap: () => _onSelectStage(kOrnamentalIntentPlannedPlant),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 145,
            child: _wizardPill(
              iconPath: 'assets/icons/wizard/ic_ya_sembrado.png',
              title: ornamentalPlantedOptionTitle(cropId),
              subtitle: '',
              selected: stage == kOrnamentalIntentAlreadyPlanted,
              enabled: true,
              fallbackAsset: kOrnamentalGenericPlantFallback,
              onTap: () => _onSelectStage(kOrnamentalIntentAlreadyPlanted),
            ),
          ),
        ],
      ),
    );
  }

  /// Alta del Tulipán (seasonal_bulb). Reutiliza el patrón de GRANO (ancla real):
  /// SOLO dos opciones — "Lo voy a plantar" / "Ya está plantado" — SIN descanso
  /// del suelo (un bulbo entra en dormancia, no en fallow). Emite los valores de
  /// grano 'planned'/'planted' para que el flujo de fecha y la persistencia
  /// corran por la ruta de grano y conserven la fecha como sowingDate.
  Widget _buildSeasonalBulbStagePage() {
    final stage = _draft.stage;
    final String? cropId = _seasonalBulbCropId;
    return CenteredWizardPage(
      horizontalPadding: 4,
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(width: 274),
          const SizedBox(height: 22),
          StaggerIn(
            delay: 0,
            child: Text(
              '¿En qué etapa está tu '
              '${seasonalBulbCropDisplayName(cropId).toLowerCase()}?',
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
          // Los MISMOS iconos de wizard que usa el grano (no imágenes de etapa).
          StaggerIn(
            delay: 90,
            child: _wizardPill(
              iconPath: 'assets/icons/wizard/ic_aun_no_siembro.png',
              title: seasonalBulbPlannedOptionTitle(cropId),
              subtitle: '',
              selected: stage == 'planned',
              enabled: true,
              fallbackAsset: kSeasonalBulbGenericPlantFallback,
              onTap: () => _onSelectStage('planned'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 145,
            child: _wizardPill(
              iconPath: 'assets/icons/wizard/ic_ya_sembrado.png',
              title: seasonalBulbPlantedOptionTitle(cropId),
              subtitle: '',
              selected: stage == 'planted' || stage == 'growing',
              enabled: true,
              fallbackAsset: kSeasonalBulbGenericPlantFallback,
              onTap: () => _onSelectStage('planted'),
            ),
          ),
        ],
      ),
    );
  }

  /// Alta del Girasol (annual_ornamental). Reutiliza el patrón de GRANO (ancla
  /// real): SOLO dos opciones — "Lo voy a sembrar" / "Ya está sembrado o
  /// plantado" — SIN descanso del suelo. Emite los valores de grano
  /// 'planned'/'planted' para que el flujo de fecha y la persistencia corran
  /// por la ruta de grano y conserven la fecha como sowingDate.
  Widget _buildAnnualOrnamentalStagePage() {
    final stage = _draft.stage;
    final String? cropId = _annualOrnamentalCropId;
    return CenteredWizardPage(
      horizontalPadding: 4,
      topPadding: 8,
      child: Column(
        children: [
          const BrandMark(width: 274),
          const SizedBox(height: 22),
          StaggerIn(
            delay: 0,
            child: Text(
              '¿En qué etapa está tu '
              '${annualOrnamentalCropDisplayName(cropId).toLowerCase()}?',
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
          // Los MISMOS iconos de wizard que usa el grano (no imágenes de etapa).
          StaggerIn(
            delay: 90,
            child: _wizardPill(
              iconPath: 'assets/icons/wizard/ic_aun_no_siembro.png',
              title: annualOrnamentalPlannedOptionTitle(cropId),
              subtitle: '',
              selected: stage == 'planned',
              enabled: true,
              fallbackAsset: kAnnualOrnamentalGenericPlantFallback,
              onTap: () => _onSelectStage('planned'),
            ),
          ),
          const SizedBox(height: 14),
          StaggerIn(
            delay: 145,
            child: _wizardPill(
              iconPath: 'assets/icons/wizard/ic_ya_sembrado.png',
              title: annualOrnamentalPlantedOptionTitle(cropId),
              subtitle: '',
              selected: stage == 'planted' || stage == 'growing',
              enabled: true,
              fallbackAsset: kAnnualOrnamentalGenericPlantFallback,
              onTap: () => _onSelectStage('planted'),
            ),
          ),
        ],
      ),
    );
  }

  /// Estado VISUAL del rosal en el onboarding: "¿Cómo está tu rosal ahora?".
  /// Config-driven desde `recurringBloomVisualStateOptions`.
  Widget _buildRecurringBloomStagePage() {
    final options = recurringBloomVisualStateOptions(_draft.cropId);
    final stage = _draft.stage;
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
              recurringBloomStateQuestion(_draft.cropId),
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
            final index = entry.key;
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: StaggerIn(
                delay: 90 + (index.clamp(0, 8)) * 40,
                child: _wizardPill(
                  iconPath: option.iconPath,
                  title: option.title,
                  subtitle: option.subtitle,
                  selected: stage == option.id,
                  enabled: true,
                  fallbackAsset: kRecurringBloomGenericPlantFallback,
                  onTap: () => _onSelectRecurringBloomState(option.id),
                ),
              ),
            );
          }),
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

    final today = DateTime.now();
    // Ornamental: "la voy a plantar" pide una fecha FUTURA; "ya está plantada"
    // solo admite una fecha pasada (o ninguna).
    // El rosal (floración recurrente) usa las mismas reglas de fecha que una
    // ornamental: "lo voy a plantar" pide fecha futura; los demás estados, fecha
    // pasada (o ninguna).
    final isOrnamentalDate = _isOrnamentalDraft || _isRecurringBloomDraft;
    final ornamentalFutureIntent =
        (_isOrnamentalDraft &&
            ornamentalSetupIntentRequiresFutureDate(
              _ornamentalCropId,
              _draft.stage,
            )) ||
        (_isRecurringBloomDraft && _isRecurringBloomFutureIntent);
    final ornamentalFirstDate = isOrnamentalDate && !ornamentalFutureIntent
        ? DateTime(1900)
        : isOrnamentalDate
        ? DateTime(
            today.year,
            today.month,
            today.day,
          ).add(const Duration(days: 1))
        : DateTime(2020);
    final ornamentalLastDate = isOrnamentalDate && !ornamentalFutureIntent
        ? DateTime(today.year, today.month, today.day)
        : DateTime(2100);
    final rawSelectedDate =
        _draft.selectedDate ??
        (ornamentalFutureIntent
            ? DateTime.now().add(const Duration(days: 1))
            : DateTime.now());
    final firstDate = isOrnamentalDate
        ? ornamentalFirstDate
        : rawSelectedDate.isBefore(ornamentalFirstDate)
        ? rawSelectedDate
        : ornamentalFirstDate;
    final lastDate = isOrnamentalDate
        ? ornamentalLastDate
        : rawSelectedDate.isAfter(ornamentalLastDate)
        ? rawSelectedDate
        : ornamentalLastDate;
    final selectedDate = !isOrnamentalDate
        ? rawSelectedDate
        : rawSelectedDate.isBefore(firstDate)
        ? firstDate
        : rawSelectedDate.isAfter(lastDate)
        ? lastDate
        : rawSelectedDate;

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
                  firstDate: firstDate,
                  lastDate: lastDate,
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
    String fallbackAsset = 'assets/icons/wizard/ic_tree.png',
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
                fallbackAsset: fallbackAsset,
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
    String fallbackAsset = 'assets/icons/wizard/ic_tree.png',
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
                fallbackAsset: fallbackAsset,
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

    final List<OnboardingStep> visibleSteps = _visibleSteps;
    final String? footerNote = _footerNoteEs;
    final bool isSoilStep = _currentStep == OnboardingStep.soilTexture;

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
                      currentStepIndex: visibleSteps.indexOf(_currentStep),
                      totalSteps: visibleSteps.length,
                      onBack: _handleBack,
                      // La ayuda solo existe donde hay algo que ayudar a
                      // decidir. Un icono presente y muerto en los otros siete
                      // pasos enseñaría a ignorarlo justo en el único donde
                      // sirve.
                      onHelp: isSoilStep ? _handleSoilGuide : null,
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
                    // El aro con palomita solo aparece cuando el botón está
                    // vivo: dibujarlo apagado prometería una confirmación que
                    // todavía no se puede dar.
                    trailing: isSoilStep && _canContinueFromCurrentStep
                        ? const _CtaCheck()
                        : null,
                  ),
                  const SizedBox(height: 6),
                  if (footerNote != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Lápiz y no candado: en este mismo archivo el
                          // candado ya significa «no puedes entrar aquí», y
                          // ponerlo junto a «puedes cambiarlo después» dice lo
                          // contrario de la frase que acompaña.
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 13,
                              color: Color(0xFF9AA5AA),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              footerNote,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11.6,
                                height: 1.32,
                                color: Color(0xFF8A9399),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
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

/// El aro con palomita del CTA «Usar esta tierra».
class _CtaCheck extends StatelessWidget {
  const _CtaCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1.4,
        ),
      ),
      child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BARRA SUPERIOR DEL WIZARD
// ═══════════════════════════════════════════════════════════════════════════
//
// Es UNA barra para los ocho pasos, no una versión especial para la pantalla de
// tierra. La instrucción de partida era explícita —reutilizar, no montar un
// sistema de diseño paralelo—, y un encabezado distinto en un solo paso es
// exactamente eso.
//
// Lo que cambia respecto de la versión anterior:
//
//  · «Paso 3 de 8» en texto. Los puntos decían *dónde* estás pero no *cuánto*
//    falta, y ese número es la única pregunta que se hace quien va a la mitad de
//    un formulario.
//  · Riel numerado en vez de puntos. Mismo espacio, más información: qué pasos
//    quedaron atrás (palomita), en cuál estás (número en verde lleno) y cuántos
//    faltan (números en aro).
//  · Una acción opcional a la derecha. El hueco de 42 px ya estaba reservado y
//    vacío desde siempre.

class _WizardTopBar extends StatelessWidget {
  final int currentStepIndex;
  final int totalSteps;
  final VoidCallback onBack;

  /// Acción opcional a la derecha. Nula en los pasos que no tienen ayuda.
  final VoidCallback? onHelp;

  const _WizardTopBar({
    required this.currentStepIndex,
    required this.totalSteps,
    required this.onBack,
    this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    // `indexOf` devuelve -1 si el paso actual no está en la ruta visible. No
    // debería ocurrir —solo se salta tierra y no se puede estar en ella y
    // saltarla a la vez—, pero «Paso 0 de 7» es un texto que no puede llegar a
    // producción por una condición de carrera de un `setState`.
    final int index = currentStepIndex < 0 ? 0 : currentStepIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _TopBarAction(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Atrás',
                onTap: onBack,
              ),
              Expanded(
                child: Text(
                  'Paso ${index + 1} de $totalSteps',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: Color(0xFF6B7A80),
                  ),
                ),
              ),
              if (onHelp != null)
                _TopBarAction(
                  icon: Icons.help_outline_rounded,
                  // Se nombra el destino, igual que la tarjeta de ayuda dentro
                  // del paso: dos puertas a la misma hoja tienen que decir que
                  // llevan al mismo sitio.
                  tooltip: 'Identifica tu tierra en 20 segundos',
                  onTap: onHelp!,
                )
              else
                const SizedBox(width: 44, height: 44),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressRail(current: index, total: totalSteps),
        ],
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          // 44 y no 42: es el mínimo táctil, y por aquí pasan el «atrás» del
          // wizard entero y la única puerta a la guía de tierra.
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 21, color: const Color(0xFF12201C)),
          ),
        ),
      ),
    );
  }
}

/// El riel numerado.
///
/// El diámetro se calcula, no se fija: con ocho pasos un círculo de 26 px no
/// cabe en un teléfono estrecho, y con cinco sobra sitio. `LayoutBuilder` reparte
/// lo que hay y los tramos absorben el resto, así que la fila no puede
/// desbordarse por ancho por muchos pasos que se le añadan al guion.
class _ProgressRail extends StatelessWidget {
  const _ProgressRail({required this.current, required this.total});

  final int current;
  final int total;

  static const Color _green = Color(0xFF2AA84A);
  static const Color _hair = Color(0xFFE3E9E5);
  static const double _minSegment = 8;

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox.shrink();

    return ExcludeSemantics(
      // El texto «Paso N de M» de arriba ya lo dice. Sin esto, el lector de
      // pantalla recitaría además ocho nodos numerados uno por uno.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double diameter =
              ((constraints.maxWidth - (total - 1) * _minSegment) / total)
                  .clamp(16.0, 26.0);

          final children = <Widget>[];
          for (var i = 0; i < total; i++) {
            if (i > 0) {
              children.add(
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i <= current ? _green : _hair,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              );
            }
            children.add(
              _RailNode(index: i, current: current, diameter: diameter),
            );
          }

          return Row(children: children);
        },
      ),
    );
  }
}

class _RailNode extends StatelessWidget {
  const _RailNode({
    required this.index,
    required this.current,
    required this.diameter,
  });

  final int index;
  final int current;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final bool done = index < current;
    final bool isCurrent = index == current;
    final bool filled = done || isCurrent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? _ProgressRail._green : Colors.white,
        border: Border.all(
          color: filled ? _ProgressRail._green : _ProgressRail._hair,
          width: 1.4,
        ),
        boxShadow: isCurrent
            ? <BoxShadow>[
                BoxShadow(
                  color: _ProgressRail._green.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Center(
        child: done
            ? Icon(
                Icons.check_rounded,
                size: diameter * 0.54,
                color: Colors.white,
              )
            : Text(
                '${index + 1}',
                style: TextStyle(
                  // Se calcula del diámetro y se acota: por debajo de 8 px el
                  // número deja de leerse y el riel pasa a ser decoración.
                  fontSize: (diameter * 0.44).clamp(8.0, 12.0),
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? Colors.white : const Color(0xFF9AA5AA),
                ),
              ),
      ),
    );
  }
}
