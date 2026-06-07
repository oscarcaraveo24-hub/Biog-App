import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bio_g/models/environment_models.dart';
import 'package:bio_g/screens/environment/environment_forecast_screen.dart';
import 'package:bio_g/services/environment_service.dart';
import 'package:bio_g/widgets/bottom_nav.dart';
import 'package:bio_g/widgets/environment/environment_forecast_preview_card.dart';
import 'package:bio_g/widgets/environment/environment_insight_card.dart';
import 'package:bio_g/widgets/environment/environment_location_card.dart';
import 'package:bio_g/widgets/environment/environment_metric_tile.dart';
import 'package:bio_g/widgets/environment/environment_now_summary_card.dart';
import 'package:bio_g/widgets/shared/bio_g_page_route.dart';
import 'package:bio_g/widgets/shared/connectivity_banner.dart';

class EnvironmentScreen extends StatefulWidget {
  final int currentIndex;
  final bool isActive;
  final ValueChanged<int> onNavTap;

  const EnvironmentScreen({
    super.key,
    required this.currentIndex,
    required this.isActive,
    required this.onNavTap,
  });

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Duration _cacheTtl = Duration(minutes: 30);
  static const Duration _forecastRetryCooldown = Duration(minutes: 5);
  static const bool _debugEnvironmentLogs = false;

  /// Vive solo mientras la app sigue abierta.
  static bool _hasAnimatedThisSession = false;

  static const String _kPrefLocLabel = 'profile_location_label';
  static const String _kPrefLocLat = 'profile_location_lat';
  static const String _kPrefLocLng = 'profile_location_lng';

  static const double _kDefLat = 25.7913; // Los Mochis
  static const double _kDefLng = -108.9859;

  final EnvironmentService _service = const EnvironmentService();

  bool _loading = false;
  bool _hasLoadedOnce = false;
  String? _error;
  String? _lastRefreshError;
  EnvironmentPayload? _payload;
  DateTime? _lastSuccessfulLoadAt;
  Future<void>? _inFlightLoad;
  Future<void>? _inFlightForecastLoad;
  bool _forecastNeedsRefresh = true;
  bool _forecastLoading = false;
  DateTime? _lastForecastFailureAt;
  bool _lastRefreshErrorIsForecast = false;
  int _currentRevision = 0;
  String? _lastBuildLog;

  Timer? _autoRefreshTimer;
  late final AnimationController _entranceController;

  // =========================================================
  // ✅ KNOBS UI
  // =========================================================
  static const double kSide = 16;
  static const double kTopPad = 10;
  static const double kGap = 12;

  static const double kGridMainGap = 14;
  static const double kGridCrossGap = 14;
  static const double kGridAspect = 1.08;

  static const double kBetweenCards = 10;

  static const double kAssetIconScale = 4.5;
  static const double kMaterialIconScale = 1.0;

  bool get _isActive => widget.isActive;

  bool get _hasFreshPayload {
    final loadedAt = _lastSuccessfulLoadAt;
    return _payload != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < _cacheTtl;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1260),
      value: _hasAnimatedThisSession ? 1.0 : 0.0,
    );

    _scheduleLoadIfNeeded(reason: 'init');

    _autoRefreshTimer = Timer.periodic(const Duration(hours: 1), (_) {
      if (_isActive) {
        unawaited(_bootstrap(reason: 'auto-refresh'));
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_isActive && !_hasAnimatedThisSession) {
        _entranceController.forward(from: 0);
        _hasAnimatedThisSession = true;
      }
    });
  }

  @override
  void didUpdateWidget(covariant EnvironmentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool wasActiveBefore = oldWidget.isActive;
    final bool isActiveNow = widget.isActive;

    if (oldWidget.currentIndex != widget.currentIndex ||
        wasActiveBefore != isActiveNow) {
      _logTabState(reason: 'tab-update');
    }

    if (!wasActiveBefore && isActiveNow) {
      _scheduleLoadIfNeeded(reason: 'tab-activated');
    }

    if (!wasActiveBefore && isActiveNow && !_hasAnimatedThisSession) {
      _entranceController
        ..stop()
        ..reset();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _entranceController.forward(from: 0);
        _hasAnimatedThisSession = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  bool get _isForecastRetryCoolingDown {
    final failedAt = _lastForecastFailureAt;
    return failedAt != null &&
        DateTime.now().difference(failedAt) < _forecastRetryCooldown;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleLoadIfNeeded(reason: 'app-resumed');
    }
  }

  void _scheduleLoadIfNeeded({required String reason}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _logTabState(reason: reason);
      if (!_isActive) {
        _logFlow('bootstrap skipped reason=inactive trigger=$reason');
        return;
      }
      if (_payload != null &&
          _hasFreshPayload &&
          _error == null &&
          _lastRefreshError == null &&
          !_forecastNeedsRefresh) {
        _logFlow('bootstrap skipped reason=cache trigger=$reason');
        return;
      }
      if (_payload != null && _hasFreshPayload) {
        unawaited(
          _refreshForecast(
            location: _payload!.location,
            reason: '$reason-forecast',
          ),
        );
        return;
      }
      unawaited(_bootstrap(reason: reason));
    });
  }

  Future<void> _bootstrap({String reason = 'manual'}) {
    _logFlow(
      'bootstrap called reason=$reason active=$_isActive '
      'currentIndex=${widget.currentIndex} '
      'environmentIndex=${BioGTabIndex.environment}',
    );
    if (!mounted) return Future<void>.value();
    if (!_isActive) {
      _logFlow('bootstrap skipped reason=inactive trigger=$reason');
      return Future<void>.value();
    }

    final current = _inFlightLoad;
    if (current != null) {
      _logFlow('bootstrap skipped reason=inflight trigger=$reason');
      return current;
    }

    late final Future<void> tracked;
    tracked = _bootstrapInternal().whenComplete(() {
      if (identical(_inFlightLoad, tracked)) {
        _inFlightLoad = null;
      }
    });
    _inFlightLoad = tracked;
    return tracked;
  }

  Future<void> _bootstrapInternal() async {
    final bool hasPreviousPayload = _payload != null;
    final previousForecastError = _lastRefreshErrorIsForecast
        ? _lastRefreshError
        : null;
    setState(() {
      _loading = !hasPreviousPayload;
      _error = null;
      _lastRefreshError = previousForecastError;
      _lastRefreshErrorIsForecast = previousForecastError != null;
    });
    _logStateUpdate();

    try {
      final prefs = await SharedPreferences.getInstance();
      final label = (prefs.getString(_kPrefLocLabel) ?? '').trim();
      final savedLat = prefs.getDouble(_kPrefLocLat);
      final savedLon = prefs.getDouble(_kPrefLocLng);
      final hasSavedLocation = savedLat != null && savedLon != null;
      final lat = hasSavedLocation ? savedLat! : _kDefLat;
      final lon = hasSavedLocation ? savedLon! : _kDefLng;
      final coordinateSource = hasSavedLocation ? 'preferences' : 'fallback';
      final zoneLabel = hasSavedLocation
          ? (label.isEmpty ? 'Ubicación seleccionada' : label)
          : 'Los Mochis, Sinaloa (predeterminada)';
      _logFlow(
        'fetch starting lat=$lat lng=$lon coordinateSource=$coordinateSource',
      );

      final location = EnvironmentLocation(
        fieldName: 'Bio-G Field #001',
        zoneLabel: zoneLabel,
        updatedAt: DateTime.now(),
        lat: lat,
        lon: lon,
      );

      final data = await _service.fetchCurrentEnvironment(location: location);

      if (!mounted) return;
      final previousPayload = _payload;
      setState(() {
        _payload = EnvironmentPayload(
          location: data.location,
          now: data.now,
          nextDays: previousPayload?.nextDays ?? const <EnvironmentDaily>[],
          insight: previousPayload?.nextDays.isNotEmpty == true
              ? previousPayload!.insight
              : data.insight,
        );
        _hasLoadedOnce = true;
        _currentRevision += 1;
        _forecastNeedsRefresh = true;
        _lastSuccessfulLoadAt = DateTime.now();
        _loading = false;
        _error = null;
        _lastRefreshError = previousForecastError;
        _lastRefreshErrorIsForecast = previousForecastError != null;
      });
      _logFlow(
        'current success tempC=${data.now.tempC} '
        'humidityPct=${data.now.humidityPct} '
        'forecastDays=${_payload!.nextDays.length}',
      );
      _logStateUpdate();
      _scheduleForecastRefresh(
        location: data.location,
        reason: 'after-current',
      );
    } catch (e, st) {
      _logFlowError('current failed type=${e.runtimeType} message=$e', st);
      if (!mounted) return;
      final message = _messageForError(e);
      setState(() {
        _loading = false;
        if (_hasLoadedOnce && _payload != null) {
          _error = null;
          _lastRefreshError = message;
          _lastRefreshErrorIsForecast = false;
        } else {
          _error = message;
          _lastRefreshError = null;
          _lastRefreshErrorIsForecast = false;
        }
      });
      _logStateUpdate();
    }
  }

  void _scheduleForecastRefresh({
    required EnvironmentLocation location,
    required String reason,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isActive) {
        _logFlow('forecast skipped reason=inactive trigger=$reason');
        return;
      }
      unawaited(_refreshForecast(location: location, reason: reason));
    });
  }

  Future<void> _refreshForecast({
    required EnvironmentLocation location,
    required String reason,
    bool force = false,
  }) {
    if (!mounted || !_isActive) {
      _logFlow('forecast skipped reason=inactive trigger=$reason');
      return Future<void>.value();
    }

    final current = _inFlightForecastLoad;
    if (current != null) {
      _logFlow('forecast skipped reason=inflight trigger=$reason');
      return current;
    }

    if (!force && _isForecastRetryCoolingDown) {
      _logFlow('forecast skipped reason=cooldown trigger=$reason');
      return Future<void>.value();
    }

    late final Future<void> tracked;
    tracked = _refreshForecastInternal(location: location, reason: reason)
        .whenComplete(() {
          if (identical(_inFlightForecastLoad, tracked)) {
            _inFlightForecastLoad = null;
          }
        });
    _inFlightForecastLoad = tracked;
    return tracked;
  }

  Future<void> _refreshForecastInternal({
    required EnvironmentLocation location,
    required String reason,
  }) async {
    final currentRevisionAtStart = _currentRevision;
    setState(() {
      _forecastLoading = true;
      _lastRefreshError = null;
      _lastRefreshErrorIsForecast = false;
    });
    _logStateUpdate();
    _logFlow(
      'forecast starting reason=$reason lat=${location.lat} lng=${location.lon}',
    );

    try {
      final data = await _service.fetchEnvironment(location: location);
      if (!mounted) return;
      if (currentRevisionAtStart != _currentRevision) {
        setState(() {
          _forecastLoading = false;
          _forecastNeedsRefresh = true;
        });
        _scheduleForecastRefresh(
          location: _payload?.location ?? location,
          reason: 'after-stale-forecast',
        );
        return;
      }
      setState(() {
        _payload = data;
        _hasLoadedOnce = true;
        _forecastNeedsRefresh = false;
        _forecastLoading = false;
        _lastForecastFailureAt = null;
        _lastSuccessfulLoadAt = DateTime.now();
        _error = null;
        _lastRefreshError = null;
        _lastRefreshErrorIsForecast = false;
      });
      _logFlow(
        'forecast success days=${data.nextDays.length} '
        'hasRadiation=${data.now.shortwaveWm2 != null}',
      );
      _logStateUpdate();
    } catch (e, st) {
      _logFlowError('forecast failed type=${e.runtimeType} message=$e', st);
      if (!mounted) return;
      if (currentRevisionAtStart != _currentRevision) {
        setState(() {
          _forecastLoading = false;
          _forecastNeedsRefresh = true;
        });
        _scheduleForecastRefresh(
          location: _payload?.location ?? location,
          reason: 'after-stale-forecast-error',
        );
        return;
      }
      setState(() {
        _forecastNeedsRefresh = true;
        _forecastLoading = false;
        _lastForecastFailureAt = DateTime.now();
        _error = null;
        _lastRefreshError = _messageForError(e);
        _lastRefreshErrorIsForecast = true;
      });
      _logStateUpdate();
    }
  }

  void _retryForecastManually() {
    final payload = _payload;
    if (payload == null) return;
    unawaited(
      _refreshForecast(
        location: payload.location,
        reason: 'manual-forecast-retry',
        force: true,
      ),
    );
  }

  void _retryLastRefresh() {
    if (_lastRefreshErrorIsForecast) {
      _retryForecastManually();
      return;
    }
    unawaited(_bootstrap(reason: 'manual-warning-retry'));
  }

  String _messageForError(Object error) {
    if (error is EnvironmentServiceException) {
      switch (error.kind) {
        case EnvironmentFailureKind.invalidCoordinates:
          return 'Falta configurar una ubicación válida para consultar el clima.';
        case EnvironmentFailureKind.timeout:
          return 'El clima tardó demasiado en responder. Intenta de nuevo.';
        case EnvironmentFailureKind.network:
          return 'No se pudo conectar con el servicio de clima. Revisa tu conexión.';
        case EnvironmentFailureKind.http:
          return 'El servicio de clima respondió con error. Intenta de nuevo.';
        case EnvironmentFailureKind.parse:
          return 'No se pudo interpretar la respuesta del clima. Intenta de nuevo.';
      }
    }
    if (error is TimeoutException) {
      return 'El clima tardó demasiado en responder. Intenta de nuevo.';
    }
    if (error is FormatException) {
      return 'No se pudo interpretar la respuesta del clima. Intenta de nuevo.';
    }
    return 'No se pudo actualizar el clima. Intenta de nuevo.';
  }

  void _logTabState({required String reason}) {
    _logFlow(
      'tab active=$_isActive currentIndex=${widget.currentIndex} '
      'environmentIndex=${BioGTabIndex.environment} reason=$reason',
    );
  }

  void _logStateUpdate() {
    _logFlow(
      'state update loading=$_loading hasPayload=${_payload != null} '
      'forecastNeedsRefresh=$_forecastNeedsRefresh '
      'forecastLoading=$_forecastLoading '
      'error=${_error ?? 'none'} '
      'refreshError=${_lastRefreshError ?? 'none'}',
    );
  }

  void _logBuildStateIfChanged() {
    if (!kDebugMode || !_debugEnvironmentLogs) return;
    final signature =
        'active=$_isActive currentIndex=${widget.currentIndex} '
        'loading=$_loading hasPayload=${_payload != null} '
        'forecastNeedsRefresh=$_forecastNeedsRefresh '
        'forecastLoading=$_forecastLoading '
        'error=${_error ?? 'none'} '
        'refreshError=${_lastRefreshError ?? 'none'}';
    if (_lastBuildLog == signature) return;
    _lastBuildLog = signature;
    _logFlow('build state $signature');
  }

  void _logFlow(String message) {
    if (!kDebugMode || !_debugEnvironmentLogs) return;
    debugPrint('[BioG/EnvironmentFlow] $message');
  }

  void _logFlowError(String message, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint('[BioG/EnvironmentFlow] $message');
    if (_debugEnvironmentLogs) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String _updatedLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Actualizado hace unos segundos';
    if (diff.inMinutes < 60) return 'Actualizado hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Actualizado hace ${diff.inHours} h';
    return 'Actualizado hace ${diff.inDays} días';
  }

  Color _chipOk() => const Color(0xFFDCEFE2);
  Color _chipWarn() => const Color(0xFFFFE9C1);

  String _tempChip(double t) =>
      (t < 7 || t > 33) ? (t < 7 ? 'Baja' : 'Alta') : 'Óptima';
  Color _tempChipColor(double t) => (t < 7 || t > 33) ? _chipWarn() : _chipOk();

  String _humidityChip(int h) {
    if (h < 25) return 'Baja';
    if (h < 60) return 'Media';
    return 'Alta';
  }

  Color _humidityChipColor(int h) => (h < 25) ? _chipWarn() : _chipOk();

  String _windChip(double w) {
    if (w < 12) return 'Suave';
    if (w < 24) return 'Moderado';
    return 'Fuerte';
  }

  Color _windChipColor(double w) => (w >= 24) ? _chipWarn() : _chipOk();

  String _solarLabel(double? wm2) {
    if (wm2 == null) return 'Pendiente';
    if (wm2 < 150) return 'Baja';
    if (wm2 < 700) return 'Óptima';
    return 'Alta';
  }

  Color _solarChipColor(double? wm2) {
    if (wm2 == null) return _chipOk();
    if (wm2 < 150 || wm2 > 900) return _chipWarn();
    return _chipOk();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    final payload = _payload;
    _logBuildStateIfChanged();

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: BioGBottomNav(
        currentIndex: widget.currentIndex,
        onTap: widget.onNavTap,
      ),
      body: ConnectivityBanner(
        enabled: _isActive,
        child: Stack(
          children: [
            const _EnvironmentSoftBackground(),
            SafeArea(
              top: true,
              bottom: false,
              child: payload == null
                  ? (_loading || _error == null)
                        ? const _LoadingBody()
                        : BioGErrorState(message: _error!, onRetry: _bootstrap)
                  : RefreshIndicator(
                      onRefresh: _bootstrap,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _EnvironmentReveal(
                              controller: _entranceController,
                              intervalStart: 0.00,
                              intervalEnd: 0.14,
                              yOffset: 14,
                              beginScale: 0.992,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  kSide,
                                  kTopPad,
                                  kSide,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Entorno',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.2,
                                          color: Color(0xFF0E1A16),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _bootstrap,
                                      icon: Icon(
                                        Icons.refresh,
                                        size: 20,
                                        color: Colors.black.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: kSide,
                              ),
                              child: Column(
                                children: [
                                  if (_lastRefreshError != null) ...[
                                    _RefreshWarning(
                                      message: _lastRefreshError!,
                                      onRetry: _retryLastRefresh,
                                    ),
                                    const SizedBox(height: kGap),
                                  ],
                                  _EnvironmentReveal(
                                    controller: _entranceController,
                                    intervalStart: 0.08,
                                    intervalEnd: 0.24,
                                    yOffset: 16,
                                    beginScale: 0.986,
                                    child: EnvironmentLocationCard(
                                      fieldLabel: payload.location.fieldName,
                                      zoneLabel: payload.location.zoneLabel,
                                      updatedLabel: _updatedLabel(
                                        payload.location.updatedAt,
                                      ),
                                      leafIconScale: 0.78,
                                      locationIconScale: 1.65,
                                    ),
                                  ),
                                  const SizedBox(height: kGap),
                                  _EnvironmentReveal(
                                    controller: _entranceController,
                                    intervalStart: 0.16,
                                    intervalEnd: 0.32,
                                    yOffset: 16,
                                    beginScale: 0.987,
                                    child: EnvironmentNowSummaryCard(
                                      condition: payload.now.condition,
                                      weatherCode: payload.now.weatherCode,
                                      observedAt: payload.now.observedAt,
                                      isDay: payload.now.isDay,
                                      precipitationMm:
                                          payload.now.precipitationMm,
                                      shortwaveRadiation:
                                          payload.now.shortwaveWm2,
                                      temperatureC: payload.now.tempC,
                                      title: payload.now.conditionLabel,
                                      subtitle: payload.now.agroNote,
                                    ),
                                  ),
                                  const SizedBox(height: kGap),
                                  GridView.count(
                                    crossAxisCount: 2,
                                    shrinkWrap: true,
                                    primary: false,
                                    padding: EdgeInsets.zero,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    mainAxisSpacing: kGridMainGap,
                                    crossAxisSpacing: kGridCrossGap,
                                    childAspectRatio: kGridAspect,
                                    children: [
                                      _EnvironmentReveal(
                                        controller: _entranceController,
                                        intervalStart: 0.30,
                                        intervalEnd: 0.46,
                                        yOffset: 18,
                                        beginScale: 0.986,
                                        child: EnvironmentMetricTile(
                                          assetPath:
                                              'assets/icons/metrics/ic_temperature.png',
                                          iconScale: kAssetIconScale,
                                          title: 'Temperatura',
                                          value:
                                              '${payload.now.tempC.round()}°C',
                                          chip: _tempChip(payload.now.tempC),
                                          chipColor: _tempChipColor(
                                            payload.now.tempC,
                                          ),
                                          footer:
                                              'Influye en crecimiento\ndel cultivo',
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                14,
                                                12,
                                                14,
                                                12,
                                              ),
                                        ),
                                      ),
                                      _EnvironmentReveal(
                                        controller: _entranceController,
                                        intervalStart: 0.36,
                                        intervalEnd: 0.52,
                                        yOffset: 18,
                                        beginScale: 0.986,
                                        child: EnvironmentMetricTile(
                                          assetPath:
                                              'assets/icons/weather/ic_air_moisture.png',
                                          iconScale: kAssetIconScale * 0.82,
                                          iconYOffset: 11.0,
                                          title: 'Humedad del aire',
                                          value: '${payload.now.humidityPct} %',
                                          chip: _humidityChip(
                                            payload.now.humidityPct,
                                          ),
                                          chipColor: _humidityChipColor(
                                            payload.now.humidityPct,
                                          ),
                                          footer: 'Afecta la transpiración',
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                18,
                                                12,
                                                12,
                                                12,
                                              ),
                                        ),
                                      ),
                                      _EnvironmentReveal(
                                        controller: _entranceController,
                                        intervalStart: 0.42,
                                        intervalEnd: 0.58,
                                        yOffset: 18,
                                        beginScale: 0.986,
                                        child: EnvironmentMetricTile(
                                          assetPath:
                                              'assets/icons/weather/ic_solar_uv.png',
                                          iconScale: kAssetIconScale,
                                          title: 'Radiación solar',
                                          value: _solarLabel(
                                            payload.now.shortwaveWm2,
                                          ),
                                          chip: _solarLabel(
                                            payload.now.shortwaveWm2,
                                          ),
                                          chipColor: _solarChipColor(
                                            payload.now.shortwaveWm2,
                                          ),
                                          footer: 'Clave para fotosíntesis',
                                        ),
                                      ),
                                      _EnvironmentReveal(
                                        controller: _entranceController,
                                        intervalStart: 0.48,
                                        intervalEnd: 0.64,
                                        yOffset: 18,
                                        beginScale: 0.986,
                                        child: EnvironmentMetricTile(
                                          assetPath:
                                              'assets/icons/weather/ic_wind.png',
                                          iconScale: kAssetIconScale,
                                          title: 'Viento',
                                          value:
                                              '${payload.now.windKmh.round()} km/h',
                                          chip: _windChip(payload.now.windKmh),
                                          chipColor: _windChipColor(
                                            payload.now.windKmh,
                                          ),
                                          footer: 'Impacta evapotranspiración',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: kBetweenCards),
                                  _EnvironmentReveal(
                                    controller: _entranceController,
                                    intervalStart: 0.62,
                                    intervalEnd: 0.80,
                                    yOffset: 18,
                                    beginScale: 0.985,
                                    child: payload.nextDays.isEmpty
                                        ? _ForecastStatusCard(
                                            isLoading: _forecastLoading,
                                            onRetry: _retryForecastManually,
                                          )
                                        : EnvironmentForecastPreviewCard(
                                            days: payload.nextDays,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                BioGPageRoute(
                                                  builder: (_) =>
                                                      EnvironmentForecastScreen(
                                                        days: payload.nextDays,
                                                        location:
                                                            payload.location,
                                                        now: payload.now,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  const SizedBox(height: kBetweenCards),
                                  _EnvironmentReveal(
                                    controller: _entranceController,
                                    intervalStart: 0.74,
                                    intervalEnd: 0.96,
                                    yOffset: 18,
                                    beginScale: 0.985,
                                    child: EnvironmentInsightCard(
                                      text: payload.insight.text,
                                      level: payload.insight.level,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: 140 + bottomPad),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastStatusCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRetry;

  const _ForecastStatusCard({required this.isLoading, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.cloud_queue_outlined,
              size: 18,
              color: Color(0xFF3FAF6E),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLoading
                  ? 'Cargando pronóstico detallado...'
                  : 'Pronóstico detallado pendiente de actualización.',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E1A16),
              ),
            ),
          ),
          if (!isLoading)
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Reintentar',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

class _RefreshWarning extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RefreshWarning({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF4D8),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 17,
              color: Color(0xFF986A1C),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$message Mostrando los datos guardados.',
                style: const TextStyle(
                  color: Color(0xFF76500F),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            IconButton(
              onPressed: onRetry,
              tooltip: 'Reintentar',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Color(0xFF986A1C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvironmentReveal extends StatelessWidget {
  final AnimationController controller;
  final double intervalStart;
  final double intervalEnd;
  final double yOffset;
  final double beginScale;
  final Widget child;

  const _EnvironmentReveal({
    required this.controller,
    required this.intervalStart,
    required this.intervalEnd,
    required this.child,
    this.yOffset = 18,
    this.beginScale = 0.986,
  });

  static const Curve _premiumCurve = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Curve _opacityCurve = Cubic(0.18, 0.84, 0.24, 1.0);

  @override
  Widget build(BuildContext context) {
    final positionCurve = CurvedAnimation(
      parent: controller,
      curve: Interval(intervalStart, intervalEnd, curve: _premiumCurve),
    );

    final opacityCurveAnim = CurvedAnimation(
      parent: controller,
      curve: Interval(
        intervalStart,
        intervalStart + ((intervalEnd - intervalStart) * 0.82),
        curve: _opacityCurve,
      ),
    );

    final opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(opacityCurveAnim);

    final translateY = Tween<double>(
      begin: yOffset,
      end: 0.0,
    ).animate(positionCurve);

    final scale = Tween<double>(
      begin: beginScale,
      end: 1.0,
    ).animate(positionCurve);

    return FadeTransition(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, translateY.value),
            child: Transform.scale(
              scale: scale.value,
              alignment: Alignment.topCenter,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/* ===================== BACKGROUND ===================== */

class _EnvironmentSoftBackground extends StatelessWidget {
  const _EnvironmentSoftBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6FAF8), Color(0xFFEFF6F2), Color(0xFFF6FAF8)],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -120,
            left: -80,
            child: _GlowBlob(size: 260, opacity: 0.18),
          ),
          Positioned(
            top: 160,
            right: -110,
            child: _GlowBlob(size: 300, opacity: 0.14),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: _GlowBlob(size: 340, opacity: 0.16),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowBlob({required this.size, required this.opacity});

  static const Color _brandMid = Color(0xFF3FAF6E);

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _brandMid.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

/* ===================== LOADING / ERROR ===================== */

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 38,
        height: 38,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            const Color(0xFF3FAF6E).withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
