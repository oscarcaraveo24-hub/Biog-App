import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
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
  int _metricIndex = 0;

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
    _entranceController.dispose();
    super.dispose();
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
        final HistoryRange range = _presenter.rangeFromIndex(_rangeIndex);

        final HistoryHeaderUiData headerData = _presenter.buildHeader(
          rangeIndex: _rangeIndex,
          seed: seed,
          cropContext: cropContext,
        );

        final HistoryMetricChartUiData metricChartData = _presenter
            .buildMetricChart(
              metric: metric,
              rangeIndex: _rangeIndex,
              live: live,
              seriesBuilder: _seriesBuilder,
              targets: runtime.targets,
            );

        final HistoryNpkChartUiData npkChartData = _presenter.buildNpkChart(
          rangeIndex: _rangeIndex,
        );

        final Duration window = _seriesBuilder.windowForRange(range);

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              const HistoryPageBackground(),
              SafeArea(
                top: true,
                bottom: false,
                child: StreamBuilder<List<BioGTelemetry>>(
                  stream: store.watchHistory(window),
                  builder: (context, snap) {
                    final List<BioGTelemetry> telemetry =
                        snap.data ?? const <BioGTelemetry>[];

                    final DateTime now = DateTime.now();

                    final HistorySeries series = _seriesBuilder
                        .buildMetricSeries(
                          metric: metric,
                          range: range,
                          telemetry: telemetry,
                          now: now,
                        );

                    final HistoryNpkSeriesSet npkSeries = _seriesBuilder
                        .buildNpkSeries(
                          range: range,
                          telemetry: telemetry,
                          now: now,
                        );

                    final List<AgronomicEvent> events = _presenter
                        .buildAgronomicEvents(
                          store: store,
                          runtime: runtime,
                          telemetry: telemetry,
                        );

                    return SingleChildScrollView(
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
                              onChanged: (i) => setState(() => _rangeIndex = i),
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
                            child: !_isNpk
                                ? HistoryChartCard(
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
                                : HistoryNpkChartCard(
                                    title: npkChartData.title,
                                    labels: npkSeries.labels,
                                    nValues: npkSeries.nValues,
                                    pValues: npkSeries.pValues,
                                    kValues: npkSeries.kValues,
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
                    );
                  },
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
