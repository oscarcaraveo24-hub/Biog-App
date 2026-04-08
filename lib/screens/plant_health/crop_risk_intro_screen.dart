import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/plant_health/plant_health_assets.dart';
import 'package:bio_g/core/plant_health/plant_health_engine.dart';
import 'package:bio_g/core/plant_health/plant_health_ids.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/core/plant_health/plant_health_registry.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_adapter.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';
import 'package:bio_g/screens/plant_health/plant_health_result_screen.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/theme/bio_g_theme.dart';
import 'package:bio_g/widgets/shared/bio_g_button.dart';

class CropRiskIntroScreen extends StatefulWidget {
  const CropRiskIntroScreen({super.key});

  @override
  State<CropRiskIntroScreen> createState() => _CropRiskIntroScreenState();
}

enum _RiskWizardStep { organ, symptom, signals, context }

class _CropRiskIntroScreenState extends State<CropRiskIntroScreen> {
  static const List<_RiskWizardStep> _steps = <_RiskWizardStep>[
    _RiskWizardStep.organ,
    _RiskWizardStep.symptom,
    _RiskWizardStep.signals,
    _RiskWizardStep.context,
  ];

  static const Color _screenBackground = Color(0xFFF6F8F7);

  final Set<String> _secondarySignals = <String>{};

  String? _organId;
  String? _primarySymptomId;

  bool _highHumidity = false;
  bool _coolDewyWindow = false;
  bool _recentStress = false;
  bool _vectorPressure = false;

  _RiskWizardStep _currentStep = _RiskWizardStep.organ;
  bool _resolving = false;
  int _transitionDirection = 1;

  bool get _isFirstStep => _currentStep == _steps.first;
  bool get _isLastStep => _currentStep == _steps.last;

  @override
  Widget build(BuildContext context) {
    final BioGStore store = BioGScope.of(context);
    final DateTime now = DateTime.now();

    if (store.activeDevice == null) {
      return Scaffold(
        backgroundColor: _screenBackground,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                      child: _RiskWizardTopBar(
                        currentStepIndex: 0,
                        totalSteps: _steps.length,
                        onBack: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'No hay dispositivo activo para analizar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3835),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final CropRuntimeSnapshot runtime = CropRuntimeResolver.resolve(
      device: store.activeDevice,
      seed: store.activeSeed,
      cropContext: store.activeCropContext,
      live: store.live,
      alertsState: store.alertsState,
      now: now,
    );

    final String cropId = CropCatalog.canonicalCropKey(runtime.cropKeyName);
    final List<PlantHealthSyndrome> catalog =
        PlantHealthRegistry.catalogForCrop(cropId);

    final PlantHealthStageBucket? stageBucket =
        PlantHealthStageAdapter.fromCropStage(
          cropId: cropId,
          stageKey: runtime.stageResult?.stageKey,
          daySinceSowing: runtime.stageResult?.daySinceSowing,
        );

    final List<PlantHealthSyndrome> visibleCatalog = _catalogForStage(
      catalog,
      stageBucket,
    );

    final List<String> organOptions = _organIdsFor(visibleCatalog);
    final List<String> symptomOptions = _symptomIdsFor(
      catalog: visibleCatalog,
      organId: _organId,
    );
    final List<String> supportingSignalOptions = _supportingSignalIdsFor(
      catalog: visibleCatalog,
      organId: _organId,
      symptomId: _primarySymptomId,
    );
    final List<String> contradictorySignalOptions =
        _conflictingSignalIdsFor(
              catalog: visibleCatalog,
              organId: _organId,
              symptomId: _primarySymptomId,
            )
            .where((String id) => !supportingSignalOptions.contains(id))
            .toList(growable: false);

    final String cropLabel = runtime.cropLabel.trim().isNotEmpty
        ? runtime.cropLabel
        : 'Cultivo';
    final String varietyLabel = _resolveVarietyLabel(runtime);
    final String scaleLabel = _resolveScaleLabel(runtime);

    final _IntroCopy introCopy = _buildIntroCopy(
      cropLabel: cropLabel,
      stageLabel: runtime.stageLabel,
      stageBucket: stageBucket,
      catalog: visibleCatalog,
    );

    final List<String> heroAssetCandidates = _heroAssetCandidates(
      cropId: cropId,
      primaryAsset: runtime.stageResult?.heroAsset,
      fallbackAsset: runtime.cropIconAsset,
    );

    final bool canContinue = _canContinueFromCurrentStep(
      selectedOrgan: _organId,
      selectedSymptom: _primarySymptomId,
    );

    final String continueLabel = _continueLabel(
      selectedOrgan: _organId,
      selectedSymptom: _primarySymptomId,
    );

    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewport) {
            final bool compactHeight = viewport.maxHeight < 780;
            final bool veryCompactHeight = viewport.maxHeight < 715;
            final double topGap = veryCompactHeight
                ? 8
                : (compactHeight ? 10 : 12);
            final double heroGap = veryCompactHeight
                ? 12
                : (compactHeight ? 14 : 18);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                        child: _RiskWizardTopBar(
                          currentStepIndex: _steps.indexOf(_currentStep),
                          totalSteps: _steps.length,
                          onBack: _handleBack,
                        ),
                      ),
                      SizedBox(height: topGap),
                      _RiskHeroHeader(
                        cropLabel: cropLabel,
                        stageLabel: runtime.stageLabel,
                        varietyLabel: varietyLabel,
                        scaleLabel: scaleLabel,
                        introCopy: introCopy,
                        heroAssetCandidates: heroAssetCandidates,
                        compactHeight: compactHeight,
                        veryCompactHeight: veryCompactHeight,
                      ),
                      SizedBox(height: heroGap),
                      Expanded(
                        child: catalog.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: _EmptyCatalogView(),
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 420),
                                layoutBuilder:
                                    (
                                      Widget? currentChild,
                                      List<Widget> previousChildren,
                                    ) {
                                      final List<Widget> children = <Widget>[
                                        ...previousChildren,
                                      ];
                                      if (currentChild != null) {
                                        children.add(currentChild);
                                      }
                                      return Stack(
                                        alignment: Alignment.topCenter,
                                        children: children,
                                      );
                                    },
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) => _buildStepTransition(
                                      child: child,
                                      animation: animation,
                                    ),
                                child: KeyedSubtree(
                                  key: ValueKey<_RiskWizardStep>(_currentStep),
                                  child: _buildCurrentStepView(
                                    currentStep: _currentStep,
                                    organOptions: organOptions,
                                    symptomOptions: symptomOptions,
                                    supportingSignalOptions:
                                        supportingSignalOptions,
                                    contradictorySignalOptions:
                                        contradictorySignalOptions,
                                    compactHeight: compactHeight,
                                  ),
                                ),
                              ),
                      ),
                      _RiskFooter(
                        isLastStep: _isLastStep,
                        continueLabel: continueLabel,
                        resolving: _resolving,
                        compactHeight: compactHeight,
                        veryCompactHeight: veryCompactHeight,
                        onContinue: canContinue && !_resolving
                            ? () => _handleContinue(
                                context: context,
                                store: store,
                                runtime: runtime,
                                catalog: visibleCatalog.isNotEmpty
                                    ? visibleCatalog
                                    : catalog,
                                cropId: cropId,
                                stageBucket: stageBucket,
                                organId: _organId,
                                symptomId: _primarySymptomId,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    final bool isIncoming =
        child.key == ValueKey<_RiskWizardStep>(_currentStep);

    final Animation<double> fade = CurvedAnimation(
      parent: animation,
      curve: isIncoming ? Curves.easeOutCubic : Curves.easeOutCubic,
    );

    final Animation<double> moveProgress = CurvedAnimation(
      parent: isIncoming ? animation : ReverseAnimation(animation),
      curve: isIncoming ? Curves.easeOutCubic : Curves.easeInOutCubic,
    );

    final Animation<double> scaleProgress = CurvedAnimation(
      parent: isIncoming ? animation : ReverseAnimation(animation),
      curve: isIncoming ? Curves.easeOutCubic : Curves.easeInOutCubic,
    );

    final Animation<Offset> offset = Tween<Offset>(
      begin: isIncoming ? Offset(_transitionDirection * 0.075, 0) : Offset.zero,
      end: isIncoming ? Offset.zero : Offset(-_transitionDirection * 0.04, 0),
    ).animate(moveProgress);

    final Animation<double> scale = Tween<double>(
      begin: isIncoming ? 0.988 : 1.0,
      end: isIncoming ? 1.0 : 0.994,
    ).animate(scaleProgress);

    return ClipRect(
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: offset,
          child: ScaleTransition(scale: scale, child: child),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView({
    required _RiskWizardStep currentStep,
    required List<String> organOptions,
    required List<String> symptomOptions,
    required List<String> supportingSignalOptions,
    required List<String> contradictorySignalOptions,
    required bool compactHeight,
  }) {
    switch (currentStep) {
      case _RiskWizardStep.organ:
        return _RiskWizardPage(
          title: '¿Qué parte de tu cultivo ves afectada?',
          subtitle:
              'Selecciona la parte donde el problema se ve más claro para empezar el diagnóstico.',
          summary: null,
          compactHeight: compactHeight,
          child: _RiskPillColumn(
            options: organOptions,
            selected: _organId,
            labelOf: PlantHealthIds.organLabel,
            assetOf: PlantHealthAssets.forOrgan,
            fallbackIconOf: _fallbackIconForOrgan,
            onTap: (String value) {
              setState(() {
                _organId = value;
                _primarySymptomId = null;
                _secondarySignals.clear();
              });
            },
          ),
        );

      case _RiskWizardStep.symptom:
        return _RiskWizardPage(
          title: '¿Qué estás observando?',
          subtitle: _organId == null
              ? 'Primero selecciona la parte afectada.'
              : 'Ahora elige el síntoma principal que ves en ${PlantHealthIds.organLabel(_organId!).toLowerCase()}.',
          summary: _organId == null
              ? null
              : <_SelectionSummaryData>[
                  _SelectionSummaryData(
                    label: 'Parte',
                    value: PlantHealthIds.organLabel(_organId!),
                  ),
                ],
          compactHeight: compactHeight,
          child: _RiskPillColumn(
            options: symptomOptions,
            selected: _primarySymptomId,
            labelOf: PlantHealthIds.symptomLabel,
            assetOf: PlantHealthAssets.forSymptom,
            fallbackIconOf: _fallbackIconForSymptom,
            onTap: (String value) {
              setState(() {
                _primarySymptomId = value;
                _secondarySignals.clear();
              });
            },
          ),
        );

      case _RiskWizardStep.signals:
        return _RiskWizardPage(
          title: '¿Qué otras señales notas?',
          subtitle:
              'Marca lo que sí esté presente. También puedes marcar señales que ayudan a descartar otros diferenciales para bajar falsos positivos.',
          summary: <_SelectionSummaryData>[
            if (_organId != null)
              _SelectionSummaryData(
                label: 'Parte',
                value: PlantHealthIds.organLabel(_organId!),
              ),
            if (_primarySymptomId != null)
              _SelectionSummaryData(
                label: 'Síntoma',
                value: PlantHealthIds.symptomLabel(_primarySymptomId!),
              ),
          ],
          compactHeight: compactHeight,
          child: Column(
            children: <Widget>[
              _RiskMultiPillColumn(
                options: supportingSignalOptions,
                selected: _secondarySignals,
                labelOf: PlantHealthIds.signalLabel,
                assetOf: PlantHealthAssets.forSignal,
                fallbackIconOf: _fallbackIconForSignal,
                onTap: (String value) {
                  setState(() {
                    if (_secondarySignals.contains(value)) {
                      _secondarySignals.remove(value);
                    } else {
                      _secondarySignals.add(value);
                    }
                  });
                },
              ),
              if (contradictorySignalOptions.isNotEmpty) ...<Widget>[
                SizedBox(height: compactHeight ? 14 : 16),
                _SignalGroupBlock(
                  title: 'Señales que ayudan a descartar',
                  subtitle:
                      'Marcar estas observaciones también le dice al motor qué alternativas pierden fuerza.',
                  child: _RiskMultiPillColumn(
                    options: contradictorySignalOptions,
                    selected: _secondarySignals,
                    labelOf: PlantHealthIds.signalLabel,
                    assetOf: PlantHealthAssets.forSignal,
                    fallbackIconOf: _fallbackIconForSignal,
                    onTap: (String value) {
                      setState(() {
                        if (_secondarySignals.contains(value)) {
                          _secondarySignals.remove(value);
                        } else {
                          _secondarySignals.add(value);
                        }
                      });
                    },
                  ),
                ),
              ],
              SizedBox(height: compactHeight ? 10 : 12),
              Text(
                'Si todavía no estás seguro, puedes continuar sin marcar señales adicionales, pero el resultado saldrá con más cautela.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compactHeight ? 12.8 : 13.2,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.46),
                ),
              ),
            ],
          ),
        );

      case _RiskWizardStep.context:
        return _RiskWizardPage(
          title: 'Cuéntame un poco más del contexto',
          subtitle:
              'Estas condiciones no definen solas el problema, pero sí ayudan a BIO-G a ponderar mejor el resultado.',
          summary: <_SelectionSummaryData>[
            if (_organId != null)
              _SelectionSummaryData(
                label: 'Parte',
                value: PlantHealthIds.organLabel(_organId!),
              ),
            if (_primarySymptomId != null)
              _SelectionSummaryData(
                label: 'Síntoma',
                value: PlantHealthIds.symptomLabel(_primarySymptomId!),
              ),
            _SelectionSummaryData(
              label: 'Señales',
              value: _secondarySignals.isEmpty
                  ? 'Sin marcar'
                  : '${_secondarySignals.length} seleccionadas',
            ),
          ],
          compactHeight: compactHeight,
          child: Column(
            children: <Widget>[
              _RiskTogglePill(
                assetPath: PlantHealthAssets.contextHumidity,
                fallbackIcon: Icons.water_drop_outlined,
                title: 'Humedad alta o follaje húmedo',
                selected: _highHumidity,
                onTap: () {
                  setState(() => _highHumidity = !_highHumidity);
                },
              ),
              SizedBox(height: compactHeight ? 10 : 12),
              _RiskTogglePill(
                assetPath: PlantHealthAssets.contextCoolDew,
                fallbackIcon: Icons.cloud_outlined,
                title: 'Ventana fresca con rocío prolongado',
                selected: _coolDewyWindow,
                onTap: () {
                  setState(() => _coolDewyWindow = !_coolDewyWindow);
                },
              ),
              SizedBox(height: compactHeight ? 10 : 12),
              _RiskTogglePill(
                assetPath: PlantHealthAssets.contextRecentStress,
                fallbackIcon: Icons.bolt_outlined,
                title: 'Estrés reciente o cuadro atípico',
                selected: _recentStress,
                onTap: () {
                  setState(() => _recentStress = !_recentStress);
                },
              ),
              SizedBox(height: compactHeight ? 10 : 12),
              _RiskTogglePill(
                assetPath: PlantHealthAssets.contextVectorPressure,
                fallbackIcon: Icons.bug_report_outlined,
                title: 'Presencia o presión de vector',
                selected: _vectorPressure,
                onTap: () {
                  setState(() => _vectorPressure = !_vectorPressure);
                },
              ),
            ],
          ),
        );
    }
  }

  bool _canContinueFromCurrentStep({
    required String? selectedOrgan,
    required String? selectedSymptom,
  }) {
    switch (_currentStep) {
      case _RiskWizardStep.organ:
        return selectedOrgan != null;
      case _RiskWizardStep.symptom:
        return selectedSymptom != null;
      case _RiskWizardStep.signals:
        return true;
      case _RiskWizardStep.context:
        return selectedOrgan != null && selectedSymptom != null;
    }
  }

  String _continueLabel({
    required String? selectedOrgan,
    required String? selectedSymptom,
  }) {
    switch (_currentStep) {
      case _RiskWizardStep.organ:
        return selectedOrgan == null
            ? 'Selecciona la parte afectada'
            : 'Continuar';
      case _RiskWizardStep.symptom:
        return selectedSymptom == null ? 'Selecciona el síntoma' : 'Continuar';
      case _RiskWizardStep.signals:
        return 'Continuar';
      case _RiskWizardStep.context:
        return 'Ver resultado probable';
    }
  }

  Future<void> _handleContinue({
    required BuildContext context,
    required BioGStore store,
    required CropRuntimeSnapshot runtime,
    required List<PlantHealthSyndrome> catalog,
    required String cropId,
    required PlantHealthStageBucket? stageBucket,
    required String? organId,
    required String? symptomId,
  }) async {
    if (_resolving) return;

    if (!_canContinueFromCurrentStep(
      selectedOrgan: organId,
      selectedSymptom: symptomId,
    )) {
      return;
    }

    if (!_isLastStep) {
      final int currentIndex = _steps.indexOf(_currentStep);
      setState(() {
        _transitionDirection = 1;
        _currentStep = _steps[currentIndex + 1];
      });
      return;
    }

    if (organId == null || symptomId == null) return;

    setState(() => _resolving = true);
    try {
      await _resolve(
        context: context,
        store: store,
        runtime: runtime,
        catalog: catalog,
        cropId: cropId,
        stageBucket: stageBucket,
        organId: organId,
        symptomId: symptomId,
      );
    } finally {
      if (!mounted) return;
      setState(() => _resolving = false);
    }
  }

  void _handleBack() {
    if (_resolving) return;

    if (_isFirstStep) {
      Navigator.of(context).maybePop();
      return;
    }

    final int currentIndex = _steps.indexOf(_currentStep);
    setState(() {
      _transitionDirection = -1;
      _currentStep = _steps[currentIndex - 1];
    });
  }

  Future<void> _resolve({
    required BuildContext context,
    required BioGStore store,
    required CropRuntimeSnapshot runtime,
    required List<PlantHealthSyndrome> catalog,
    required String cropId,
    required PlantHealthStageBucket? stageBucket,
    required String organId,
    required String symptomId,
  }) async {
    final device = store.activeDevice;
    if (device == null) return;

    final PlantHealthInput input = PlantHealthInput(
      deviceId: device.id,
      cropId: cropId,
      varietyId: runtime.effectiveVarietyId,
      stageBucket: stageBucket,
      organId: organId,
      primarySymptomId: symptomId,
      secondarySignalIds: Set<String>.from(_secondarySignals),
      cultivationScaleId: runtime.cropContext?.cultivationScaleId,
      highHumidity: _highHumidity,
      coolDewyWindow: _coolDewyWindow,
      recentStress: _recentStress,
      vectorPressure: _vectorPressure,
    );

    final PlantHealthResult? result = const PlantHealthEngine().resolve(
      input: input,
      catalog: catalog,
    );

    if (result == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No encontré una coincidencia suficientemente útil. Revisa el órgano, el síntoma o las señales de confirmación.',
            ),
          ),
        );
      return;
    }

    if (!mounted) return;
    await showPlantHealthResultDialog(
      context: context,
      result: result,
      cropLabel: runtime.cropLabel,
      varietyLabel: _resolveVarietyLabel(runtime),
      stageLabel: runtime.stageLabel,
    );
  }

  List<PlantHealthSyndrome> _catalogForStage(
    List<PlantHealthSyndrome> catalog,
    PlantHealthStageBucket? stageBucket,
  ) {
    if (stageBucket == null) return catalog;
    final List<PlantHealthSyndrome> filtered = catalog
        .where((PlantHealthSyndrome s) => s.stages.contains(stageBucket))
        .toList(growable: false);
    return filtered.isEmpty ? catalog : filtered;
  }

  List<String> _organIdsFor(List<PlantHealthSyndrome> catalog) {
    final Set<String> ids = <String>{};
    for (final PlantHealthSyndrome s in catalog) {
      ids.addAll(s.organIds);
    }
    final List<String> sorted = ids.toList(growable: false)
      ..sort(
        (String a, String b) => PlantHealthIds.organLabel(
          a,
        ).compareTo(PlantHealthIds.organLabel(b)),
      );
    return sorted;
  }

  List<String> _symptomIdsFor({
    required List<PlantHealthSyndrome> catalog,
    required String? organId,
  }) {
    Iterable<PlantHealthSyndrome> relevant = catalog;
    if (organId != null) {
      relevant = relevant.where(
        (PlantHealthSyndrome s) => s.organIds.contains(organId),
      );
    }
    final Set<String> ids = <String>{};
    for (final PlantHealthSyndrome s in relevant) {
      ids.add(s.primarySymptomId);
    }
    final List<String> sorted = ids.toList(growable: false)
      ..sort(
        (String a, String b) => PlantHealthIds.symptomLabel(
          a,
        ).compareTo(PlantHealthIds.symptomLabel(b)),
      );
    return sorted;
  }

  List<String> _supportingSignalIdsFor({
    required List<PlantHealthSyndrome> catalog,
    required String? organId,
    required String? symptomId,
  }) {
    Iterable<PlantHealthSyndrome> relevant = catalog;
    if (organId != null) {
      relevant = relevant.where(
        (PlantHealthSyndrome s) => s.organIds.contains(organId),
      );
    }
    if (symptomId != null) {
      relevant = relevant.where(
        (PlantHealthSyndrome s) => s.primarySymptomId == symptomId,
      );
    }
    final Set<String> ids = <String>{};
    for (final PlantHealthSyndrome s in relevant) {
      ids.addAll(s.strongSignals);
      ids.addAll(s.weakSignals);
    }
    final List<String> sorted = ids.toList(growable: false)
      ..sort(
        (String a, String b) => PlantHealthIds.signalLabel(
          a,
        ).compareTo(PlantHealthIds.signalLabel(b)),
      );
    return sorted;
  }

  List<String> _conflictingSignalIdsFor({
    required List<PlantHealthSyndrome> catalog,
    required String? organId,
    required String? symptomId,
  }) {
    Iterable<PlantHealthSyndrome> relevant = catalog;
    if (organId != null) {
      relevant = relevant.where(
        (PlantHealthSyndrome s) => s.organIds.contains(organId),
      );
    }
    if (symptomId != null) {
      relevant = relevant.where(
        (PlantHealthSyndrome s) => s.primarySymptomId == symptomId,
      );
    }
    final Set<String> ids = <String>{};
    for (final PlantHealthSyndrome s in relevant) {
      ids.addAll(s.conflictingSignals);
    }
    final List<String> sorted = ids.toList(growable: false)
      ..sort(
        (String a, String b) => PlantHealthIds.signalLabel(
          a,
        ).compareTo(PlantHealthIds.signalLabel(b)),
      );
    return sorted;
  }

  _IntroCopy _buildIntroCopy({
    required String cropLabel,
    required String stageLabel,
    required PlantHealthStageBucket? stageBucket,
    required List<PlantHealthSyndrome> catalog,
  }) {
    final String crop = cropLabel.trim();
    final String? topSuspicion = catalog.isNotEmpty
        ? catalog.first.labelEs
        : null;

    final String suspicionLine = topSuspicion != null
        ? 'Para $crop en $stageLabel, uno de los cuadros que conviene revisar es $topSuspicion.'
        : 'BIO-G ya ajustó el análisis a tu contexto actual.';

    switch (stageBucket) {
      case PlantHealthStageBucket.seedling:
      case PlantHealthStageBucket.vegetativeEarly:
        return _IntroCopy(
          tagLabel: 'Contexto activo',
          title:
              '$suspicionLine En esta etapa conviene revisar hoy mismo las señales más visibles.',
        );
      case PlantHealthStageBucket.vegetativeMid:
      case PlantHealthStageBucket.vegetativeLate:
        return _IntroCopy(
          tagLabel: 'Contexto activo',
          title:
              '$suspicionLine Aquí ya conviene diferenciar mejor entre daño foliar, presión de plaga y otros problemas.',
        );
      case PlantHealthStageBucket.reproductiveEarly:
      case PlantHealthStageBucket.reproductiveMid:
      case PlantHealthStageBucket.grainFill:
      case PlantHealthStageBucket.lateSeason:
        return _IntroCopy(
          tagLabel: 'Etapa crítica',
          title:
              '$suspicionLine En esta etapa la urgencia puede subir si ya se compromete hoja funcional o llenado.',
        );
      case null:
        return const _IntroCopy(
          tagLabel: 'Contexto activo',
          title:
              'BIO-G va a ayudarte a confirmar el riesgo más probable con base en lo que marques aquí.',
        );
    }
  }

  String _resolveVarietyLabel(CropRuntimeSnapshot runtime) {
    final String? varietyId = runtime.effectiveVarietyId;
    final String? alias = runtime.effectiveVarietyAlias;
    final String cropId = CropCatalog.canonicalCropKey(runtime.cropKeyName);
    return CropCatalog.varietyByAny(cropId, varietyId)?.label ??
        alias?.trim() ??
        'No definida';
  }

  String _resolveScaleLabel(CropRuntimeSnapshot runtime) {
    final String? scaleId = runtime.cropContext?.cultivationScaleId;
    if (scaleId == null || scaleId.trim().isEmpty) return 'No definido';
    switch (scaleId.trim().toLowerCase()) {
      case 'field':
        return 'Campo';
      case 'bed':
        return 'Huerto';
      case 'pot':
        return 'Maceta';
      default:
        return scaleId;
    }
  }

  List<String> _heroAssetCandidates({
    required String cropId,
    required String? primaryAsset,
    required String fallbackAsset,
  }) {
    final List<String> out = <String>[];

    void add(String? asset) {
      final String? normalized = asset?.trim();
      if (normalized == null || normalized.isEmpty) return;
      if (!out.contains(normalized)) {
        out.add(normalized);
      }
    }

    add(primaryAsset);
    add(fallbackAsset);

    final String? normalizedPrimary = primaryAsset?.trim();
    if (normalizedPrimary == null || normalizedPrimary.isEmpty) {
      return out;
    }

    if (cropId == CropCatalog.beanCropId) {
      final Set<String> variants = <String>{normalizedPrimary};

      for (final String candidate in List<String>.from(variants)) {
        variants.add(
          candidate.replaceAll('assets/seeds/bean/', 'assets/seeds/Bean/'),
        );
        variants.add(
          candidate.replaceAll('assets/seeds/Bean/', 'assets/seeds/bean/'),
        );
      }

      for (final String candidate in List<String>.from(variants)) {
        variants.add(
          candidate.replaceAll(
            'bean_stage_tasseling.png',
            'bean_stage_flower_set.png',
          ),
        );
        variants.add(
          candidate.replaceAll(
            'bean_stage_veg_advanced.png',
            'bean_stage_maturity_senescence.png',
          ),
        );
        variants.add(
          candidate.replaceAll(
            'bean_stage_grain_fill.png',
            'bean_stage_maturity_senescence.png',
          ),
        );
      }

      for (final String candidate in variants) {
        add(candidate);
      }
    }

    if (cropId == CropCatalog.oatCropId) {
      final Set<String> variants = <String>{normalizedPrimary};

      for (final String candidate in List<String>.from(variants)) {
        variants.add(
          candidate.replaceAll('assets/seeds/Oat/', 'assets/seeds/oat/'),
        );
        variants.add(
          candidate.replaceAll('assets/seeds/oat/', 'assets/seeds/Oat/'),
        );
      }

      for (final String candidate in List<String>.from(variants)) {
        variants.add(
          candidate.replaceAll(
            'oat_stage_tasseling.png',
            'oat_stage_flower_set.png',
          ),
        );
        variants.add(
          candidate.replaceAll(
            'oat_stage_veg_advanced.png',
            'oat_stage_elongation.png',
          ),
        );
      }

      for (final String candidate in variants) {
        add(candidate);
      }
    }

    if (cropId == CropCatalog.wheatCropId ||
        cropId == CropCatalog.barleyCropId) {
      final Set<String> variants = <String>{normalizedPrimary};

      for (final String candidate in List<String>.from(variants)) {
        variants.add(
          candidate.replaceAll('_stage_veg.png', '_stage_veg_early.png'),
        );
        variants.add(
          candidate.replaceAll('_stage_flowering.png', '_stage_heading.png'),
        );
        variants.add(
          candidate.replaceAll('_stage_maturity.png', '_stage_grain_fill.png'),
        );
        variants.add(
          candidate.replaceAll(
            '_stage_maturity.png',
            '_stage_physiological_maturity.png',
          ),
        );
      }

      for (final String candidate in variants) {
        add(candidate);
      }
    }

    return out;
  }

  static IconData _fallbackIconForOrgan(String value) {
    final String label = PlantHealthIds.organLabel(value).toLowerCase();
    if (label.contains('hoja')) return Icons.eco_outlined;
    if (label.contains('cogollo')) return Icons.filter_vintage_outlined;
    if (label.contains('tallo')) return Icons.linear_scale_rounded;
    if (label.contains('raíz') || label.contains('raiz')) {
      return Icons.spa_outlined;
    }
    if (label.contains('mazorca') ||
        label.contains('espiga') ||
        label.contains('grano') ||
        label.contains('fruto')) {
      return Icons.grain_outlined;
    }
    return Icons.local_florist_outlined;
  }

  static IconData _fallbackIconForSymptom(String value) {
    final String label = PlantHealthIds.symptomLabel(value).toLowerCase();
    if (label.contains('amarill')) return Icons.wb_sunny_outlined;
    if (label.contains('marchit')) return Icons.air_outlined;
    if (label.contains('mancha')) return Icons.blur_on_outlined;
    if (label.contains('seca') || label.contains('necros')) {
      return Icons.whatshot_outlined;
    }
    if (label.contains('pudric')) return Icons.water_damage_outlined;
    if (label.contains('deform') || label.contains('enchina')) {
      return Icons.change_circle_outlined;
    }
    return Icons.search_rounded;
  }

  static IconData _fallbackIconForSignal(String value) {
    final String label = PlantHealthIds.signalLabel(value).toLowerCase();
    if (label.contains('vector') || label.contains('insect')) {
      return Icons.bug_report_outlined;
    }
    if (label.contains('humed') ||
        label.contains('rocío') ||
        label.contains('rocio')) {
      return Icons.water_drop_outlined;
    }
    if (label.contains('polvo') || label.contains('espor')) {
      return Icons.grain_outlined;
    }
    if (label.contains('lesión') || label.contains('lesion')) {
      return Icons.adjust_outlined;
    }
    return Icons.checklist_rounded;
  }
}

class _IntroCopy {
  final String tagLabel;
  final String title;

  const _IntroCopy({required this.tagLabel, required this.title});
}

class _RiskFooter extends StatelessWidget {
  final bool isLastStep;
  final String continueLabel;
  final bool resolving;
  final bool compactHeight;
  final bool veryCompactHeight;
  final VoidCallback? onContinue;

  const _RiskFooter({
    required this.isLastStep,
    required this.continueLabel,
    required this.resolving,
    required this.compactHeight,
    required this.veryCompactHeight,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        4,
        veryCompactHeight ? 6 : (compactHeight ? 8 : 12),
        4,
        (veryCompactHeight ? 4 : (compactHeight ? 6 : 10)) +
            MediaQuery.of(context).padding.bottom * 0.12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F7),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BioGButton(
            label: continueLabel,
            onTap: onContinue,
            loading: resolving,
            height: veryCompactHeight ? 50 : (compactHeight ? 52 : 56),
            radius: 18,
          ),
          SizedBox(height: veryCompactHeight ? 5 : (compactHeight ? 6 : 8)),
          Text(
            isLastStep
                ? 'BIO-G calculará el resultado con base en lo que seleccionaste.'
                : 'Selecciona una opción para continuar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: veryCompactHeight
                  ? 11.9
                  : (compactHeight ? 12.2 : 12.8),
              height: 1.26,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8E9894),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskWizardTopBar extends StatelessWidget {
  final int currentStepIndex;
  final int totalSteps;
  final VoidCallback onBack;

  const _RiskWizardTopBar({
    required this.currentStepIndex,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _RiskSurface(
          radius: 16,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white.withValues(alpha: 0.74),
          borderColor: Colors.white.withValues(alpha: 0.92),
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
        _RiskSurface(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          backgroundColor: Colors.white.withValues(alpha: 0.72),
          borderColor: Colors.white.withValues(alpha: 0.90),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              totalSteps,
              (int index) => AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: index == currentStepIndex ? 18 : 7,
                height: 7,
                margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: index == currentStepIndex
                      ? BioGTheme.brandMid
                      : index < currentStepIndex
                      ? BioGTheme.brandMid.withValues(alpha: 0.34)
                      : const Color(0xFFD6DEDA),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(width: 42, height: 42),
      ],
    );
  }
}

class _RiskHeroHeader extends StatelessWidget {
  final String cropLabel;
  final String stageLabel;
  final String varietyLabel;
  final String scaleLabel;
  final _IntroCopy introCopy;
  final List<String> heroAssetCandidates;
  final bool compactHeight;
  final bool veryCompactHeight;

  const _RiskHeroHeader({
    required this.cropLabel,
    required this.stageLabel,
    required this.varietyLabel,
    required this.scaleLabel,
    required this.introCopy,
    required this.heroAssetCandidates,
    required this.compactHeight,
    required this.veryCompactHeight,
  });

  String get _heroTitle {
    final String trimmedVariety = varietyLabel.trim();
    if (trimmedVariety.isEmpty || trimmedVariety == 'No definida') {
      return cropLabel;
    }
    return '$cropLabel ($trimmedVariety)';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = veryCompactHeight
            ? (width < 360 ? 182 : 190)
            : compactHeight
            ? (width < 360 ? 194 : 206)
            : (width < 360
                  ? 222
                  : width < 430
                  ? 234
                  : 244);

        final bool tight = height <= 206;

        final double imageWidthFactor = veryCompactHeight
            ? 0.37
            : (compactHeight ? 0.395 : 0.44);

        final double textStartFactor = veryCompactHeight
            ? 0.285
            : (compactHeight ? 0.305 : 0.34);

        final double imageScale = veryCompactHeight
            ? 1.26
            : (compactHeight ? 1.36 : 1.52);

        final double leftInset = veryCompactHeight
            ? -34
            : (compactHeight ? -44 : -56);

        final double topInset = tight ? 12 : 16;
        final double sideInset = tight ? 16 : 18;
        final double bottomInset = tight ? 12 : 18;

        final double titleSize = veryCompactHeight
            ? 18.2
            : (compactHeight ? 19.6 : 22);

        final double metaSize = veryCompactHeight ? 12.0 : 12.8;
        final double bodySize = veryCompactHeight
            ? 11.8
            : (compactHeight ? 12.3 : 13.0);

        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.90)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFFEAF5ED),
                Color(0xFFDFEEE4),
                Color(0xFFD6E8DA),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: leftInset,
                  top: tight ? 0 : -4,
                  bottom: 0,
                  width: width * imageWidthFactor,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.scale(
                      scale: imageScale,
                      alignment: Alignment.centerLeft,
                      child: _AssetFallbackImage(
                        assetCandidates: heroAssetCandidates,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.78),
                          Colors.black.withValues(alpha: 0.62),
                          Colors.black.withValues(alpha: 0.24),
                          Colors.transparent,
                        ],
                        stops: const <double>[0.0, 0.42, 0.74, 1.0],
                      ),
                    ),
                  ),
                ),

                // Tag separado para que no empuje el bloque inferior
                Positioned(
                  top: topInset,
                  left: width * textStartFactor,
                  right: sideInset,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _HeroTag(text: introCopy.tagLabel),
                  ),
                ),

                // Bloque inferior comprimible
                Positioned(
                  left: width * textStartFactor,
                  right: sideInset,
                  bottom: bottomInset,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _heroTitle,
                        maxLines: tight ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleSize,
                          height: 1.04,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.25,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: tight ? 6 : 10),
                      _HeroMetaRow(
                        label: 'Etapa',
                        value: stageLabel,
                        fontSize: metaSize,
                      ),
                      const SizedBox(height: 3),
                      _HeroMetaRow(
                        label: 'Variedad',
                        value: varietyLabel,
                        fontSize: metaSize,
                      ),
                      const SizedBox(height: 3),
                      _HeroMetaRow(
                        label: 'Sistema',
                        value: scaleLabel,
                        fontSize: metaSize,
                      ),
                      SizedBox(height: tight ? 7 : 12),
                      Text(
                        introCopy.title,
                        maxLines: tight ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: bodySize,
                          height: 1.32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroTag extends StatelessWidget {
  final String text;

  const _HeroTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: BioGTheme.brandMid.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: BioGTheme.brandMid.withValues(alpha: 0.44)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.8,
          fontWeight: FontWeight.w800,
          color: BioGTheme.green100,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}

class _HeroMetaRow extends StatelessWidget {
  final String label;
  final String value;
  final double fontSize;

  const _HeroMetaRow({
    required this.label,
    required this.value,
    this.fontSize = 12.8,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.18,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.92),
      ),
    );
  }
}

class _RiskWizardPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_SelectionSummaryData>? summary;
  final Widget child;
  final bool compactHeight;

  const _RiskWizardPage({
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.child,
    required this.compactHeight,
  });

  @override
  Widget build(BuildContext context) {
    final double titleSize = compactHeight ? 19.2 : 20.5;
    final double subtitleSize = compactHeight ? 13.2 : 14.0;

    return Column(
      key: ValueKey<String>(title),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: titleSize,
            height: 1.18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
            color: const Color(0xFF293533),
          ),
        ),
        SizedBox(height: compactHeight ? 6 : 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: subtitleSize,
            height: 1.36,
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.48),
          ),
        ),
        if (summary != null && summary!.isNotEmpty) ...<Widget>[
          SizedBox(height: compactHeight ? 12 : 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: summary!
                .map(
                  (_SelectionSummaryData item) => _SelectionSummaryPill(
                    label: item.label,
                    value: item.value,
                  ),
                )
                .toList(growable: false),
          ),
        ],
        SizedBox(height: compactHeight ? 14 : 18),
        Expanded(
          child: ScrollConfiguration(
            behavior: const _NoGlowScrollBehavior(),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: compactHeight ? 6 : 10),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignalGroupBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SignalGroupBlock({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 14.2,
              height: 1.18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C3835),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 12.8,
              height: 1.36,
              color: Colors.black.withValues(alpha: 0.46),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SelectionSummaryData {
  final String label;
  final String value;

  const _SelectionSummaryData({required this.label, required this.value});
}

class _SelectionSummaryPill extends StatelessWidget {
  final String label;
  final String value;

  const _SelectionSummaryPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return _RiskSurface(
      radius: 999,
      backgroundColor: const Color(0xFFF2F5F3),
      borderColor: Colors.white.withValues(alpha: 0.88),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: RichText(
        text: TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6A7671),
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFF293533),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskPillColumn extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final String Function(String value) labelOf;
  final String? Function(String value) assetOf;
  final IconData Function(String value) fallbackIconOf;
  final ValueChanged<String> onTap;

  const _RiskPillColumn({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.assetOf,
    required this.fallbackIconOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const _EmptyOptionsCard();
    }

    return Column(
      children: options
          .map(
            (String value) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RiskChoicePill(
                assetPath: assetOf(value),
                fallbackIcon: fallbackIconOf(value),
                title: labelOf(value),
                selected: selected == value,
                onTap: () => onTap(value),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _RiskMultiPillColumn extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final String Function(String value) labelOf;
  final String? Function(String value) assetOf;
  final IconData Function(String value) fallbackIconOf;
  final ValueChanged<String> onTap;

  const _RiskMultiPillColumn({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.assetOf,
    required this.fallbackIconOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const _EmptyOptionsCard();
    }

    return Column(
      children: options
          .map(
            (String value) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RiskChoicePill(
                assetPath: assetOf(value),
                fallbackIcon: fallbackIconOf(value),
                title: labelOf(value),
                selected: selected.contains(value),
                onTap: () => onTap(value),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _RiskChoicePill extends StatelessWidget {
  final String? assetPath;
  final IconData fallbackIcon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  /// Scale applied to the asset image inside the icon slot.
  /// Matches the onboarding wizard convention (~1.95).
  static const double _assetScale = 1.56;

  const _RiskChoicePill({
    this.assetPath,
    this.fallbackIcon = Icons.local_florist_outlined,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected
        ? BioGTheme.brandMid.withValues(alpha: 0.28)
        : Colors.black.withValues(alpha: 0.06);

    final Color backgroundColor = selected
        ? const Color(0xFFF1F7F2)
        : Colors.white.withValues(alpha: 0.82);

    final Color iconColor = selected
        ? BioGTheme.brandMid
        : const Color(0xFF788781);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 42,
                height: 42,
                child: _buildIconContent(iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.6,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: Color(0xFF303836),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.92,
                        end: 1,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  key: ValueKey<bool>(selected),
                  color: selected
                      ? BioGTheme.brandMid
                      : const Color(0xFF9AA79F),
                  size: selected ? 20 : 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContent(Color iconColor) {
    if (assetPath == null) {
      return Center(child: Icon(fallbackIcon, size: 21, color: iconColor));
    }
    return Center(
      child: Transform.scale(
        scale: _assetScale,
        child: Image.asset(
          assetPath!,
          width: 42,
          height: 42,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return Icon(fallbackIcon, size: 21, color: iconColor);
              },
        ),
      ),
    );
  }
}

class _RiskTogglePill extends StatelessWidget {
  final String? assetPath;
  final IconData fallbackIcon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  static const double _assetScale = 1.56;

  const _RiskTogglePill({
    this.assetPath,
    this.fallbackIcon = Icons.local_florist_outlined,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected
        ? BioGTheme.brandMid.withValues(alpha: 0.28)
        : Colors.black.withValues(alpha: 0.06);

    final Color backgroundColor = selected
        ? const Color(0xFFF1F7F2)
        : Colors.white.withValues(alpha: 0.82);

    final Color iconColor = selected
        ? BioGTheme.brandMid
        : const Color(0xFF788781);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 42,
                height: 42,
                child: _buildIconContent(iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.4,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: Color(0xFF303836),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.92,
                        end: 1,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  key: ValueKey<bool>(selected),
                  color: selected
                      ? BioGTheme.brandMid
                      : const Color(0xFF9AA79F),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContent(Color iconColor) {
    if (assetPath == null) {
      return Center(child: Icon(fallbackIcon, size: 21, color: iconColor));
    }
    return Center(
      child: Transform.scale(
        scale: _assetScale,
        child: Image.asset(
          assetPath!,
          width: 42,
          height: 42,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return Icon(fallbackIcon, size: 21, color: iconColor);
              },
        ),
      ),
    );
  }
}

class _EmptyCatalogView extends StatelessWidget {
  const _EmptyCatalogView();

  @override
  Widget build(BuildContext context) {
    return _RiskSurface(
      radius: 24,
      backgroundColor: Colors.white.withValues(alpha: 0.76),
      borderColor: Colors.white.withValues(alpha: 0.90),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: const Text(
        'El catálogo sanitario para este cultivo aún no tiene datos cargados. Estamos trabajando en ello.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: BioGTheme.charcoal,
        ),
      ),
    );
  }
}

class _EmptyOptionsCard extends StatelessWidget {
  const _EmptyOptionsCard();

  @override
  Widget build(BuildContext context) {
    return _RiskSurface(
      radius: 20,
      backgroundColor: Colors.white.withValues(alpha: 0.78),
      borderColor: Colors.white.withValues(alpha: 0.90),
      padding: const EdgeInsets.all(16),
      child: const Text(
        'No hay opciones cargadas para esta combinación todavía.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13.4,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: BioGTheme.charcoal,
        ),
      ),
    );
  }
}

class _RiskSurface extends StatelessWidget {
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  const _RiskSurface({
    required this.radius,
    required this.padding,
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _AssetFallbackImage extends StatefulWidget {
  final List<String> assetCandidates;
  final BoxFit fit;
  final Alignment alignment;

  const _AssetFallbackImage({
    required this.assetCandidates,
    required this.fit,
    required this.alignment,
  });

  @override
  State<_AssetFallbackImage> createState() => _AssetFallbackImageState();
}

class _AssetFallbackImageState extends State<_AssetFallbackImage> {
  int _assetIndex = 0;
  bool _queuedAdvance = false;

  @override
  Widget build(BuildContext context) {
    if (widget.assetCandidates.isEmpty ||
        _assetIndex >= widget.assetCandidates.length) {
      return const SizedBox.shrink();
    }

    final String asset = widget.assetCandidates[_assetIndex];

    return Image.asset(
      asset,
      fit: widget.fit,
      alignment: widget.alignment,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            if (!_queuedAdvance &&
                _assetIndex < widget.assetCandidates.length - 1) {
              _queuedAdvance = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _assetIndex += 1;
                  _queuedAdvance = false;
                });
              });
            }
            return const SizedBox.shrink();
          },
    );
  }
}
