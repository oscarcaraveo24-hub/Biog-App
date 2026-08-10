import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:bio_g/core/agro/agro_event_input_factory.dart';
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/agro/event_engine.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
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
  final double? currentValue;
  final String Function(double) valueFormatter;
  final bool isPercentScale;
  final double minSpan;
  final double zoomRadius;
  final List<double> bandStops;
  final List<Color>? bandColors;

  const HistoryMetricChartUiData({
    required this.title,
    required this.currentValue,
    required this.valueFormatter,
    required this.isPercentScale,
    required this.minSpan,
    required this.zoomRadius,
    required this.bandStops,
    this.bandColors,
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
    StageTargets? targets,
  }) {
    final bands = _resolveBands(metric, targets);
    return HistoryMetricChartUiData(
      title:
          '${_metricTitleForChart(metric)} (${_rangeTitleForChart(rangeIndex)})',
      currentValue: seriesBuilder.currentLiveForMetric(metric, live),
      valueFormatter: _valueFormatterForMetric(metric),
      isPercentScale: _isPercentMetric(metric),
      minSpan: _minSpanForMetric(metric),
      zoomRadius: _zoomRadiusForMetric(metric),
      bandStops: bands.stops,
      bandColors: bands.colors,
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
    // Decision vigente del motor de riego, si la hay. Sin ella no se emiten
    // eventos de riego: este camino no ve el clima y no puede decidirlo solo.
    IrrigationDecision? irrigationDecision,
  }) {
    final List<BioGTelemetry> sortedTelemetry = [...telemetry]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final DateTime now = runtime.live?.timestamp ??
        (sortedTelemetry.isNotEmpty ? sortedTelemetry.last.timestamp : DateTime.now());

    final _PreviousEventContext previousContext = _resolvePreviousContext(
      runtime: runtime,
      telemetry: sortedTelemetry,
    );

    final EventEngineInput input = AgroEventInputFactory.build(
      timestamp: now,
      deviceId: runtime.device?.id ?? store.activeDevice?.id,
      seed: runtime.seed,
      cropContext: runtime.cropContext,
      live: runtime.live,
      effectiveEval: runtime.eval,
      stageResult: runtime.stageResult,
      isGenericMode: runtime.isGenericMode,
      history: _historyToEventPoints(sortedTelemetry),
      previousBands: previousContext.previousBands,
      previousStageKey: previousContext.previousStage?.stageKey,
      previousStageLabel: previousContext.previousStage?.stageLabelEs,
      irrigationDecision: irrigationDecision,
    );

    return EventEngine.build(input);
  }


  _PreviousEventContext _resolvePreviousContext({
    required CropRuntimeSnapshot runtime,
    required List<BioGTelemetry> telemetry,
  }) {
    if (!runtime.isPlanted) return const _PreviousEventContext();

    final definition = runtime.definition;
    final profile = runtime.profile;
    final sowingDate = runtime.engineSowingDate ?? runtime.effectiveLifecycleDate;
    if (definition == null || profile == null || sowingDate == null) {
      return const _PreviousEventContext();
    }

    final BioGTelemetry? previousTelemetry = telemetry.length >= 2
        ? telemetry[telemetry.length - 2]
        : null;
    if (previousTelemetry == null) {
      return const _PreviousEventContext();
    }

    final CropStageResult previousStage = definition.engine.compute(
      sowingDate: sowingDate,
      today: previousTelemetry.timestamp,
      profile: profile,
      stressDelayDays: 0,
    );

    StageTargets? previousTargets = definition.resolveTargets(previousStage);
    if (previousTargets != null) {
      previousTargets = CropCatalog.adjustTargetsForCalendar(
        cropId: runtime.cropKeyName,
        calendarId: runtime.cropContext?.calendarTypeId,
        stageKey: previousStage.stageKey,
        baseTargets: previousTargets,
      );
    }

    final Map<String, AgroBand> previousBands;
    if (previousTargets != null) {
      final previousEvalOut = definition.evaluateTelemetry(
        telemetry: previousTelemetry,
        stage: previousStage,
        profile: profile,
        targetsOverride: previousTargets,
        alertsState: const AlertsState(),
      );
      // `live:` también aquí. Sin él, las bandas PREVIAS se calculaban sobre
      // los ceros sintetizados mientras las ACTUALES sí se degradaban a
      // `unknown`. Esa asimetría hacía que `previousProblemCount > 0` y
      // `currentProblemCount == 0`, y el Historial emitía "Recuperación" cada
      // vez que un sensor dejaba de reportar.
      previousBands = AgroEventInputFactory.safeCurrentBands(
        previousEvalOut.eval,
        live: previousTelemetry,
      );
    } else {
      previousBands = const <String, AgroBand>{};
    }

    return _PreviousEventContext(
      previousStage: previousStage,
      previousBands: previousBands,
    );
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
            n: t.hasNitrogenData ? t.n.toDouble() : null,
            p: t.hasPhosphorusData ? t.p.toDouble() : null,
            k: t.hasPotassiumData ? t.k.toDouble() : null,
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
        'NPK' => (v) => '${v.round()} mg/kg',
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

  // ── Bandas dinámicas según el cultivo seleccionado ──
  // Verde = Óptimo, Amarillo = Alto/Bajo, Rojo = Crítico

  static const Color _red = Color(0xFFE85B5B);
  static const Color _yellow = Color(0xFFF2C94C);
  static const Color _green = Color(0xFF4CAF50);

  ({List<double> stops, List<Color>? colors}) _resolveBands(
    String metric,
    StageTargets? targets,
  ) {
    if (targets == null) {
      return (stops: _bandStopsForMetric(metric), colors: null);
    }

    final AgroRange? range = switch (metric) {
      'Humedad' => targets.moistureRaw,
      'pH' => targets.ph,
      'Temp' => targets.soilTemp,
      'RT' => targets.resistance,
      _ => null,
    };

    if (range == null) {
      return (stops: _bandStopsForMetric(metric), colors: null);
    }

    final fc = _metricFloorCeil(metric);
    final floor = fc.$1;
    final ceil = fc.$2;
    final lowMax = math.max(floor + 0.001, range.lowMax);
    final optMin = math.max(lowMax + 0.001, range.optimalMin);

    return (
      stops: [floor, lowMax, optMin, range.optimalMax, range.highMin, ceil],
      colors: [_red, _yellow, _green, _green, _yellow, _red],
    );
  }

  static (double, double) _metricFloorCeil(String metric) => switch (metric) {
    'Humedad' => (0.0, 100.0),
    'pH' => (3.0, 10.0),
    'Temp' => (0.0, 45.0),
    'RT' => (0.0, 3.0),
    _ => (0.0, 100.0),
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


class _PreviousEventContext {
  final CropStageResult? previousStage;
  final Map<String, AgroBand> previousBands;

  const _PreviousEventContext({
    this.previousStage,
    this.previousBands = const <String, AgroBand>{},
  });
}
