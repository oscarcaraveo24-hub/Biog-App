import 'package:bio_g/core/agro/agro_event_input_factory.dart';
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/agro/event_engine.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/screens/history/history_series_builder.dart';

class HistoryHeaderUiData {
  final String subtitle;
  final String modeLabel;

  const HistoryHeaderUiData({required this.subtitle, required this.modeLabel});
}

class HistoryMetricChartUiData {
  final String title;
  final double currentValue;
  final String Function(double) valueFormatter;
  final bool isPercentScale;
  final double minSpan;
  final double zoomRadius;
  final List<double> bandStops;

  const HistoryMetricChartUiData({
    required this.title,
    required this.currentValue,
    required this.valueFormatter,
    required this.isPercentScale,
    required this.minSpan,
    required this.zoomRadius,
    required this.bandStops,
  });
}

class HistoryNpkChartUiData {
  final String title;

  const HistoryNpkChartUiData({required this.title});
}

class HistoryScreenPresenter {
  static const List<String> metrics = <String>[
    'Humedad',
    'pH',
    'RT',
    'Temp',
    'NPK',
  ];

  const HistoryScreenPresenter();

  String metricForIndex(int index) {
    if (index < 0 || index >= metrics.length) return metrics.first;
    return metrics[index];
  }

  HistoryRange rangeFromIndex(int index) => switch (index) {
    0 => HistoryRange.h24,
    1 => HistoryRange.d7,
    2 => HistoryRange.d30,
    _ => HistoryRange.all,
  };

  HistoryHeaderUiData buildHeader({
    required int rangeIndex,
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
  }) {
    return HistoryHeaderUiData(
      subtitle: _subtitleForRange(rangeIndex),
      modeLabel: _historyModeLabel(seed, cropContext),
    );
  }

  HistoryMetricChartUiData buildMetricChart({
    required String metric,
    required int rangeIndex,
    required BioGTelemetry? live,
    required HistorySeriesBuilder seriesBuilder,
  }) {
    return HistoryMetricChartUiData(
      title:
          '${_metricTitleForChart(metric)} (${_rangeTitleForChart(rangeIndex)})',
      currentValue: seriesBuilder.currentLiveForMetric(metric, live),
      valueFormatter: _valueFormatterForMetric(metric),
      isPercentScale: _isPercentMetric(metric),
      minSpan: _minSpanForMetric(metric),
      zoomRadius: _zoomRadiusForMetric(metric),
      bandStops: _bandStopsForMetric(metric),
    );
  }

  HistoryNpkChartUiData buildNpkChart({required int rangeIndex}) {
    return HistoryNpkChartUiData(
      title: 'NPK (Análisis NPK · ${_subtitleForRange(rangeIndex)})',
    );
  }

  List<AgronomicEvent> buildAgronomicEvents({
    required BioGStore store,
    required CropRuntimeSnapshot runtime,
    required List<BioGTelemetry> telemetry,
  }) {
    final DateTime now = DateTime.now();

    final EventEngineInput input = AgroEventInputFactory.build(
      timestamp: now,
      deviceId: runtime.device?.id ?? store.activeDevice?.id,
      seed: runtime.seed,
      cropContext: runtime.cropContext,
      live: runtime.live,
      effectiveEval: runtime.eval,
      stageResult: runtime.stageResult,
      isGenericMode: runtime.isGenericMode,
      history: _historyToEventPoints(telemetry),
      previousBands: const <String, AgroBand>{},
    );

    return EventEngine.build(input);
  }

  List<EventTelemetryPoint> _historyToEventPoints(
    List<BioGTelemetry> telemetry,
  ) {
    return telemetry
        .map(
          (t) => EventTelemetryPoint(
            timestamp: t.timestamp,
            soilMoisture: t.soilMoisturePct,
            ph: t.ph,
            resistance: t.resistance,
            soilTemp: t.soilTempC,
            n: t.n.toDouble(),
            p: t.p.toDouble(),
            k: t.k.toDouble(),
          ),
        )
        .toList();
  }

  String _subtitleForRange(int index) => switch (index) {
    0 => 'Últimas 24 horas',
    1 => 'Últimos 7 días',
    2 => 'Últimos 30 días',
    _ => 'Todo el tiempo',
  };

  String _rangeTitleForChart(int index) => switch (index) {
    0 => 'últimas 24 horas',
    1 => 'últimos 7 días',
    2 => 'últimos 30 días',
    _ => 'todo el tiempo',
  };

  String _metricTitleForChart(String metric) => switch (metric) {
    'Humedad' => 'Humedad',
    'pH' => 'pH',
    'RT' => 'Resistencia',
    'Temp' => 'Temperatura de suelo',
    'NPK' => 'NPK',
    _ => metric,
  };

  String Function(double) _valueFormatterForMetric(String metric) =>
      switch (metric) {
        'Humedad' => (v) => '${v.round()}%',
        'NPK' => (v) => '${v.round()} ppm',
        'pH' => (v) => v.toStringAsFixed(1),
        'Temp' => (v) => '${v.round()}°C',
        'RT' => (v) => '${v.toStringAsFixed(1)} MPa',
        _ => (v) => v.round().toString(),
      };

  bool _isPercentMetric(String metric) => switch (metric) {
    'Humedad' => true,
    'NPK' => false,
    _ => false,
  };

  double _minSpanForMetric(String metric) => switch (metric) {
    'pH' => 6.0,
    'Temp' => 10.0,
    'RT' => 1.5,
    'Humedad' => 30.0,
    'NPK' => 80.0,
    _ => 14.0,
  };

  double _zoomRadiusForMetric(String metric) => switch (metric) {
    'pH' => 3.0,
    'Temp' => 5.0,
    'RT' => 0.8,
    'Humedad' => 25.0,
    'NPK' => 40.0,
    _ => 10.0,
  };

  List<double> _bandStopsForMetric(String metric) => switch (metric) {
    'Humedad' => const <double>[0, 15, 30, 50, 70, 85, 100],
    'NPK' => const <double>[0, 20, 40, 60, 80, 100, 140],
    'pH' => const <double>[3.0, 4.5, 5.5, 6.5, 7.5, 8.5, 10.0],
    'Temp' => const <double>[0, 10, 18, 24, 30, 36, 45],
    'RT' => const <double>[0.0, 0.3, 0.8, 1.2, 1.8, 2.2, 2.8],
    _ => const <double>[0, 15, 30, 50, 70, 85, 100],
  };

  String _historyModeLabel(SeedInstall? seed, DeviceCropContext? cropContext) {
    if (cropContext != null) {
      return switch (cropContext.lifecycleStatus) {
        CropLifecycleStatus.planted => 'Seguimiento del cultivo',
        CropLifecycleStatus.planned => 'Pre-siembra',
        CropLifecycleStatus.fallow => 'Descanso del suelo',
      };
    }

    if (seed == null) return 'Sin cultivo configurado';

    return switch (seed.status) {
      SowingStatus.planted => 'Seguimiento del cultivo',
      SowingStatus.planned => 'Pre-siembra',
      SowingStatus.skip => 'Descanso del suelo',
    };
  }
}
