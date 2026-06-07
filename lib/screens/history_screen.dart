import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/screens/history/history_presenter.dart';
import 'package:bio_g/screens/history/history_sections.dart';
import 'package:bio_g/screens/history/history_series_builder.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/screens/notifications_screen.dart';
import 'package:bio_g/widgets/bottom_nav.dart';
import 'package:bio_g/widgets/history/history_chart_card.dart';
import 'package:bio_g/widgets/history/history_events_list.dart';
import 'package:bio_g/widgets/history/history_metric_tabs.dart';
import 'package:bio_g/widgets/history/history_npk_chart_card.dart';
import 'package:bio_g/widgets/history/history_range_selector.dart';

const bool kBioGHistoryChartDebugLogs = true;

class HistoryScreen extends StatefulWidget {
  final int currentIndex;
  final void Function(int) onNavTap;

  const HistoryScreen({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  static const int _historyTabIndex = 0;

  static bool _hasAnimatedThisSession = false;

  final HistorySeriesBuilder _seriesBuilder = const HistorySeriesBuilder();
  final HistoryScreenPresenter _presenter = const HistoryScreenPresenter();

  late final AnimationController _entranceController;

  int _rangeIndex = 1;
  int _renderedRangeIndex = 1;
  int _metricIndex = 0;
  int _historyRequestVersion = 0;
  int _historyRevision = 0;

  BioGStore? _store;
  StreamSubscription<List<BioGTelemetry>>? _historySubscription;
  String? _boundActiveDeviceId;
  bool _historyLoading = true;
  List<BioGTelemetry> _stableTelemetry = const <BioGTelemetry>[];
  HistorySeriesBundle? _preparedSeries;
  String? _eventsCacheKey;
  List<AgronomicEvent> _cachedEvents = const <AgronomicEvent>[];

  bool get _isNpk => _presenter.metricForIndex(_metricIndex) == 'NPK';

  void _playEntranceOnceIfNeeded() {
    final bool isActiveNow = widget.currentIndex == _historyTabIndex;

    if (!isActiveNow || _hasAnimatedThisSession) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasAnimatedThisSession) return;

      _entranceController.forward(from: 0);
      _hasAnimatedThisSession = true;
    });
  }

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
      value: _hasAnimatedThisSession ? 1.0 : 0.0,
    );

    _playEntranceOnceIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final BioGStore nextStore = BioGScope.of(context);
    if (identical(nextStore, _store)) return;

    _store?.removeListener(_handleStoreChanged);
    unawaited(_historySubscription?.cancel());

    _store = nextStore;
    _boundActiveDeviceId = nextStore.activeDevice?.id;
    nextStore.addListener(_handleStoreChanged);
    _startHistoryLoad(clearStable: true, notify: false);
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool wasActiveBefore = oldWidget.currentIndex == _historyTabIndex;
    final bool isActiveNow = widget.currentIndex == _historyTabIndex;

    if (!wasActiveBefore && isActiveNow) {
      _playEntranceOnceIfNeeded();
    }
  }

  @override
  void dispose() {
    _store?.removeListener(_handleStoreChanged);
    unawaited(_historySubscription?.cancel());
    _entranceController.dispose();
    super.dispose();
  }

  void _handleStoreChanged() {
    final String? activeDeviceId = _store?.activeDevice?.id;
    if (activeDeviceId == _boundActiveDeviceId) return;

    _boundActiveDeviceId = activeDeviceId;
    _startHistoryLoad(clearStable: true);
  }

  void _selectRange(int index) {
    if (_rangeIndex == index) return;
    _rangeIndex = index;
    _startHistoryLoad(clearStable: false);
  }

  void _startHistoryLoad({required bool clearStable, bool notify = true}) {
    final BioGStore? store = _store;
    if (store == null) return;

    final int requestVersion = ++_historyRequestVersion;
    final int requestedRangeIndex = _rangeIndex;
    final String? requestedDeviceId = store.activeDevice?.id;
    final HistoryRange requestedRange = _presenter.rangeFromIndex(
      requestedRangeIndex,
    );
    final Duration? window = _seriesBuilder.windowForRange(requestedRange);

    _logHistory(
      'request version=$requestVersion range=${requestedRange.name} '
      'window=${_windowLabel(window)} ui_device_id=$requestedDeviceId '
      'telemetry_device_id=${store.activeDevice?.telemetryDeviceId}',
    );

    unawaited(_historySubscription?.cancel());

    _historyLoading = true;
    if (clearStable) {
      _stableTelemetry = const <BioGTelemetry>[];
      _preparedSeries = _seriesBuilder.buildSeriesBundle(
        range: requestedRange,
        telemetry: _stableTelemetry,
      );
      _renderedRangeIndex = requestedRangeIndex;
      _invalidateEvents();
    }

    _historySubscription = store.watchHistory(window).listen(
      (telemetry) {
        if (!mounted ||
            requestVersion != _historyRequestVersion ||
            requestedRangeIndex != _rangeIndex ||
            requestedDeviceId != _store?.activeDevice?.id) {
          return;
        }

        final List<BioGTelemetry> stable = List<BioGTelemetry>.unmodifiable(
          telemetry,
        );
        final DateTime seriesNow = DateTime.now();
        final HistorySeriesBundle prepared = _seriesBuilder.buildSeriesBundle(
          range: requestedRange,
          telemetry: stable,
          now: seriesNow,
        );
        _logHistory(
          'response version=$requestVersion range=${requestedRange.name} '
          'window=${_windowLabel(window)} ui_device_id=$requestedDeviceId '
          'telemetry_device_id=${store.activeDevice?.telemetryDeviceId}',
        );
        for (final line in _seriesBuilder.debugSummaryLines(
          range: requestedRange,
          telemetry: stable,
          bundle: prepared,
          now: seriesNow,
        )) {
          _logHistory(line);
        }

        setState(() {
          _stableTelemetry = stable;
          _preparedSeries = prepared;
          _renderedRangeIndex = requestedRangeIndex;
          _historyLoading = false;
          _invalidateEvents();
        });
      },
      onError: (Object error, StackTrace _) {
        if (!mounted ||
            requestVersion != _historyRequestVersion ||
            requestedRangeIndex != _rangeIndex ||
            requestedDeviceId != _store?.activeDevice?.id) {
          return;
        }

        _logHistory(
          'error version=$requestVersion range=${requestedRange.name} '
          'window=${_windowLabel(window)} ui_device_id=$requestedDeviceId '
          'error=$error',
        );
        setState(() {
          _historyLoading = false;
          if (clearStable) {
            _stableTelemetry = const <BioGTelemetry>[];
            _preparedSeries = _seriesBuilder.buildSeriesBundle(
              range: requestedRange,
              telemetry: _stableTelemetry,
            );
            _renderedRangeIndex = requestedRangeIndex;
            _invalidateEvents();
          }
        });
      },
    );

    if (notify && mounted) {
      setState(() {});
    }
  }

  void _invalidateEvents() {
    _historyRevision++;
    _eventsCacheKey = null;
  }

  String _windowLabel(Duration? window) {
    return window == null ? 'all' : '${window.inMinutes}m';
  }

  void _logHistory(String message) {
    if (!kDebugMode || !kBioGHistoryChartDebugLogs) return;
    debugPrint('[BioG/HistoryChart] $message');
  }

  List<AgronomicEvent> _buildAgronomicEvents({
    required BioGStore store,
    required CropRuntimeSnapshot runtime,
  }) {
    final String cacheKey = <Object?>[
      store.activeDevice?.id,
      runtime.live?.timestamp.toIso8601String(),
      _historyRevision,
      identityHashCode(runtime.cropContext),
      identityHashCode(runtime.seed),
      identityHashCode(store.alertsState),
    ].join('|');

    if (_eventsCacheKey != cacheKey) {
      _cachedEvents = _presenter.buildAgronomicEvents(
        store: store,
        runtime: runtime,
        telemetry: _stableTelemetry,
      );
      _eventsCacheKey = cacheKey;
    }

    return _cachedEvents;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPad = 140 + MediaQuery.of(context).viewPadding.bottom;
    final BioGStore store = BioGScope.of(context);

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final BioGTelemetry? live = store.live;
        final DeviceCropContext? cropContext = store.activeCropContext;
        final SeedInstall? seed = store.activeSeed;

        final runtime = CropRuntimeResolver.resolve(
          device: store.activeDevice,
          seed: seed,
          cropContext: cropContext,
          live: live,
          alertsState: store.alertsState,
        );

        final String metric = _presenter.metricForIndex(_metricIndex);
        final HistoryHeaderUiData headerData = _presenter.buildHeader(
          rangeIndex: _rangeIndex,
          seed: seed,
          cropContext: cropContext,
        );

        final HistoryMetricChartUiData metricChartData = _presenter
            .buildMetricChart(
              metric: metric,
              rangeIndex: _renderedRangeIndex,
              live: live,
              seriesBuilder: _seriesBuilder,
              targets: runtime.targets,
            );

        final HistoryNpkChartUiData npkChartData = _presenter.buildNpkChart(
          rangeIndex: _renderedRangeIndex,
        );

        final HistorySeriesBundle prepared =
            _preparedSeries ??
            _seriesBuilder.buildSeriesBundle(
              range: _presenter.rangeFromIndex(_renderedRangeIndex),
              telemetry: _stableTelemetry,
            );
        final HistorySeries series = prepared.seriesForMetric(metric);
        final HistoryNpkSeriesSet npkSeries = prepared.npk;
        final List<AgronomicEvent> events = _buildAgronomicEvents(
          store: store,
          runtime: runtime,
        );

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              const HistoryPageBackground(),
              SafeArea(
                top: true,
                bottom: false,
                child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          HistoryReveal(
                            controller: _entranceController,
                            intervalStart: 0.00,
                            intervalEnd: 0.22,
                            yOffset: 6,
                            shadowOpacityBegin: 0.00,
                            shadowOpacityEnd: 0.02,
                            child: HistoryTopBarSection(
                              subtitle: headerData.subtitle,
                              modeLabel: headerData.modeLabel,
                            ),
                          ),
                          const SizedBox(height: 12),
                          HistoryReveal(
                            controller: _entranceController,
                            intervalStart: 0.10,
                            intervalEnd: 0.62,
                            yOffset: 12,
                            shadowOpacityBegin: 0.00,
                            shadowOpacityEnd: 0.06,
                            child: HistoryRangeSelector(
                              selectedIndex: _rangeIndex,
                              onChanged: _selectRange,
                            ),
                          ),
                          const SizedBox(height: 12),
                          HistoryReveal(
                            controller: _entranceController,
                            intervalStart: 0.10,
                            intervalEnd: 0.62,
                            yOffset: 12,
                            shadowOpacityBegin: 0.00,
                            shadowOpacityEnd: 0.06,
                            child: HistoryMetricTabs(
                              selectedIndex: _metricIndex,
                              onChanged: (i) =>
                                  setState(() => _metricIndex = i),
                            ),
                          ),
                          const SizedBox(height: 14),
                          HistoryReveal(
                            controller: _entranceController,
                            intervalStart: 0.10,
                            intervalEnd: 0.62,
                            yOffset: 16,
                            shadowOpacityBegin: 0.00,
                            shadowOpacityEnd: 0.08,
                            child: Stack(
                              children: <Widget>[
                                if (!_isNpk)
                                  HistoryChartCard(
                                    title: metricChartData.title,
                                    values: series.values,
                                    days: series.labels,
                                    currentValue: metricChartData.currentValue,
                                    valueFormatter:
                                        metricChartData.valueFormatter,
                                    isPercentScale:
                                        metricChartData.isPercentScale,
                                    minSpan: metricChartData.minSpan,
                                    zoomRadius: metricChartData.zoomRadius,
                                    bandStops: metricChartData.bandStops,
                                    bandColors: metricChartData.bandColors,
                                  )
                                else
                                  HistoryNpkChartCard(
                                    title: npkChartData.title,
                                    labels: npkSeries.labels,
                                    nValues: npkSeries.nValues,
                                    pValues: npkSeries.pValues,
                                    kValues: npkSeries.kValues,
                                    liveN: live?.hasNitrogenData == true
                                        ? live?.n.toDouble()
                                        : null,
                                    liveP: live?.hasPhosphorusData == true
                                        ? live?.p.toDouble()
                                        : null,
                                    liveK: live?.hasPotassiumData == true
                                        ? live?.k.toDouble()
                                        : null,
                                  ),
                                if (_historyLoading)
                                  const Positioned(
                                    top: 12,
                                    right: 12,
                                    child: _HistoryLoadingChip(),
                                  ),
                                if (!_historyLoading &&
                                    _stableTelemetry.isEmpty)
                                  const Positioned(
                                    top: 12,
                                    right: 12,
                                    child: _HistoryEmptyChip(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          HistoryReveal(
                            controller: _entranceController,
                            intervalStart: 0.10,
                            intervalEnd: 0.62,
                            yOffset: 16,
                            shadowOpacityBegin: 0.00,
                            shadowOpacityEnd: 0.08,
                            child: HistoryEventsList(
                              events: events,
                              onViewAll: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => NotificationsScreen(
                                      events: events,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BioGBottomNav(
            currentIndex: widget.currentIndex,
            onTap: widget.onNavTap,
          ),
        );
      },
    );
  }
}

class _HistoryLoadingChip extends StatelessWidget {
  const _HistoryLoadingChip();

  @override
  Widget build(BuildContext context) {
    return const _HistoryStatusChip(
      label: 'Actualizando',
      leading: SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _HistoryEmptyChip extends StatelessWidget {
  const _HistoryEmptyChip();

  @override
  Widget build(BuildContext context) {
    return const _HistoryStatusChip(
      label: 'Sin datos para este rango',
      leading: Icon(Icons.info_outline_rounded, size: 14),
    );
  }
}

class _HistoryStatusChip extends StatelessWidget {
  const _HistoryStatusChip({required this.label, required this.leading});

  final String label;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            leading,
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
