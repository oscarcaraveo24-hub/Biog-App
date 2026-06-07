import 'package:bio_g/models/biog_telemetry.dart';

class HistorySeries {
  final List<double?> values;
  final List<String> labels;

  const HistorySeries({required this.values, required this.labels});
}

class HistoryNpkSeriesSet {
  final List<String> labels;
  final List<double?> nValues;
  final List<double?> pValues;
  final List<double?> kValues;

  const HistoryNpkSeriesSet({
    required this.labels,
    required this.nValues,
    required this.pValues,
    required this.kValues,
  });
}

class HistorySeriesBundle {
  final Map<String, HistorySeries> metrics;
  final HistoryNpkSeriesSet npk;

  const HistorySeriesBundle({required this.metrics, required this.npk});

  HistorySeries seriesForMetric(String metric) {
    return metrics[metric] ??
        HistorySeries(values: const <double?>[], labels: npk.labels);
  }
}

enum HistoryRange { h24, d7, d30, all }

class HistorySeriesBuilder {
  const HistorySeriesBuilder();

  static const List<String> supportedMetrics = <String>[
    'Humedad',
    'pH',
    'RT',
    'Temp',
    'NPK',
  ];

  Duration? windowForRange(HistoryRange range) => switch (range) {
    HistoryRange.h24 => const Duration(hours: 24),
    HistoryRange.d7 => const Duration(days: 7),
    HistoryRange.d30 => const Duration(days: 30),
    HistoryRange.all => null,
  };

  double? currentLiveForMetric(String metric, BioGTelemetry? live) {
    if (live == null) return null;

    return switch (metric) {
      'Humedad' => live.hasSoilMoistureData ? live.soilMoisturePct : null,
      'pH' => live.hasPhData ? live.ph : null,
      'RT' => live.hasResistanceData ? live.resistance : null,
      'Temp' => live.hasSoilTempData ? live.soilTempC : null,
      'NPK' => _averageExisting(<double?>[
        live.hasNitrogenData ? live.n : null,
        live.hasPhosphorusData ? live.p : null,
        live.hasPotassiumData ? live.k : null,
      ]),
      _ => null,
    };
  }

  HistorySeriesBundle buildSeriesBundle({
    required HistoryRange range,
    required List<BioGTelemetry> telemetry,
    DateTime? now,
  }) {
    final List<BioGTelemetry> sorted = _sortedTelemetry(telemetry);
    final _HistoryAxis axis = _buildAxis(range, now ?? DateTime.now(), sorted);
    final Map<String, HistorySeries> metrics = <String, HistorySeries>{};

    for (final String metric in supportedMetrics) {
      metrics[metric] = _buildMetricSeries(
        metric: metric,
        axis: axis,
        sorted: sorted,
      );
    }

    return HistorySeriesBundle(
      metrics: Map<String, HistorySeries>.unmodifiable(metrics),
      npk: _buildNpkSeries(axis: axis, sorted: sorted),
    );
  }

  HistorySeries buildMetricSeries({
    required String metric,
    required HistoryRange range,
    required List<BioGTelemetry> telemetry,
    DateTime? now,
  }) {
    final List<BioGTelemetry> sorted = _sortedTelemetry(telemetry);
    final _HistoryAxis axis = _buildAxis(range, now ?? DateTime.now(), sorted);
    return _buildMetricSeries(
      metric: metric,
      axis: axis,
      sorted: sorted,
    );
  }

  HistoryNpkSeriesSet buildNpkSeries({
    required HistoryRange range,
    required List<BioGTelemetry> telemetry,
    DateTime? now,
  }) {
    final List<BioGTelemetry> sorted = _sortedTelemetry(telemetry);
    final _HistoryAxis axis = _buildAxis(range, now ?? DateTime.now(), sorted);
    return _buildNpkSeries(axis: axis, sorted: sorted);
  }

  HistorySeries _buildMetricSeries({
    required String metric,
    required _HistoryAxis axis,
    required List<BioGTelemetry> sorted,
  }) {
    return HistorySeries(
      values: _bucketize(
        sorted: sorted,
        buckets: axis.buckets,
        valueOf: (t) => _valueForMetric(metric, t),
      ),
      labels: axis.labels,
    );
  }

  HistoryNpkSeriesSet _buildNpkSeries({
    required _HistoryAxis axis,
    required List<BioGTelemetry> sorted,
  }) {
    return HistoryNpkSeriesSet(
      labels: axis.labels,
      nValues: _bucketize(
        sorted: sorted,
        buckets: axis.buckets,
        valueOf: (t) => t.hasNitrogenData ? t.n : null,
      ),
      pValues: _bucketize(
        sorted: sorted,
        buckets: axis.buckets,
        valueOf: (t) => t.hasPhosphorusData ? t.p : null,
      ),
      kValues: _bucketize(
        sorted: sorted,
        buckets: axis.buckets,
        valueOf: (t) => t.hasPotassiumData ? t.k : null,
      ),
    );
  }

  List<BioGTelemetry> _sortedTelemetry(List<BioGTelemetry> telemetry) {
    final List<BioGTelemetry> sorted = <BioGTelemetry>[...telemetry];
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  List<double?> _bucketize({
    required List<BioGTelemetry> sorted,
    required List<_HistoryBucket> buckets,
    required double? Function(BioGTelemetry t) valueOf,
  }) {
    final List<double?> values = <double?>[];
    int telemetryIndex = 0;

    for (int bucketIndex = 0; bucketIndex < buckets.length; bucketIndex++) {
      final _HistoryBucket bucket = buckets[bucketIndex];
      final bool includeEnd = bucketIndex == buckets.length - 1;

      while (telemetryIndex < sorted.length &&
          sorted[telemetryIndex].timestamp.isBefore(bucket.start)) {
        telemetryIndex++;
      }

      int scanIndex = telemetryIndex;
      double sum = 0.0;
      int count = 0;

      while (scanIndex < sorted.length) {
        final BioGTelemetry reading = sorted[scanIndex];
        final bool beforeEnd = reading.timestamp.isBefore(bucket.end);
        final bool atIncludedEnd =
            includeEnd && reading.timestamp.isAtSameMomentAs(bucket.end);
        if (!beforeEnd && !atIncludedEnd) break;

        final double? value = valueOf(reading);
        if (value != null && value.isFinite) {
          sum += value;
          count++;
        }
        scanIndex++;
      }

      telemetryIndex = scanIndex;
      values.add(count == 0 ? null : sum / count);
    }

    return values;
  }

  double? _valueForMetric(String metric, BioGTelemetry t) {
    return switch (metric) {
      'Humedad' => t.hasSoilMoistureData ? t.soilMoisturePct : null,
      'pH' => t.hasPhData ? t.ph : null,
      'RT' => t.hasResistanceData ? t.resistance : null,
      'Temp' => t.hasSoilTempData ? t.soilTempC : null,
      'NPK' => _averageExisting(<double?>[
        t.hasNitrogenData ? t.n : null,
        t.hasPhosphorusData ? t.p : null,
        t.hasPotassiumData ? t.k : null,
      ]),
      _ => null,
    };
  }

  static double? _averageExisting(List<double?> values) {
    final List<double> existing = values.whereType<double>().toList();
    if (existing.isEmpty) return null;
    return existing.reduce((a, b) => a + b) / existing.length;
  }

  List<String> debugSummaryLines({
    required HistoryRange range,
    required List<BioGTelemetry> telemetry,
    required HistorySeriesBundle bundle,
    DateTime? now,
  }) {
    final List<BioGTelemetry> sorted = _sortedTelemetry(telemetry);
    final _HistoryAxis axis = _buildAxis(range, now ?? DateTime.now(), sorted);
    final List<int> readingCounts = _bucketReadingCounts(
      sorted: sorted,
      buckets: axis.buckets,
    );
    final List<String> lines = <String>[
      'range=${range.name} readings=${sorted.length} '
          'oldest=${sorted.isEmpty ? null : sorted.first.timestamp.toIso8601String()} '
          'newest=${sorted.isEmpty ? null : sorted.last.timestamp.toIso8601String()} '
          'buckets=${axis.buckets.length}',
    ];

    for (final entry in bundle.metrics.entries) {
      final int valued = entry.value.values.whereType<double>().length;
      lines.add(
        'metric=${entry.key} buckets_with_value=$valued '
        'buckets_null=${entry.value.values.length - valued}',
      );
    }
    for (final entry in <String, List<double?>>{
      'N': bundle.npk.nValues,
      'P': bundle.npk.pValues,
      'K': bundle.npk.kValues,
    }.entries) {
      final int valued = entry.value.whereType<double>().length;
      lines.add(
        'metric=${entry.key} buckets_with_value=$valued '
        'buckets_null=${entry.value.length - valued}',
      );
    }

    if (range == HistoryRange.h24) {
      for (int i = 0; i < axis.buckets.length; i++) {
        final bucket = axis.buckets[i];
        lines.add(
          'bucket[$i] start=${bucket.start.toUtc().toIso8601String()} '
          'end=${bucket.end.toUtc().toIso8601String()} '
          'readings=${readingCounts[i]}',
        );
      }
    }

    return lines;
  }

  List<int> _bucketReadingCounts({
    required List<BioGTelemetry> sorted,
    required List<_HistoryBucket> buckets,
  }) {
    return List<int>.generate(buckets.length, (bucketIndex) {
      final bucket = buckets[bucketIndex];
      final bool includeEnd = bucketIndex == buckets.length - 1;
      return sorted.where((reading) {
        final bool afterStart = !reading.timestamp.isBefore(bucket.start);
        final bool beforeEnd = reading.timestamp.isBefore(bucket.end);
        final bool atIncludedEnd =
            includeEnd && reading.timestamp.isAtSameMomentAs(bucket.end);
        return afterStart && (beforeEnd || atIncludedEnd);
      }).length;
    });
  }

  _HistoryAxis _buildAxis(
    HistoryRange range,
    DateTime now,
    List<BioGTelemetry> sorted,
  ) {
    switch (range) {
      case HistoryRange.h24:
        final DateTime start = now.subtract(const Duration(hours: 24));
        final List<_HistoryBucket> buckets = List<_HistoryBucket>.generate(
          24,
          (i) {
            final DateTime bucketStart = start.add(Duration(hours: i));
            return _HistoryBucket(
              start: bucketStart,
              end: bucketStart.add(const Duration(hours: 1)),
            );
          },
        );
        return _HistoryAxis(
          labels: buckets
              .map((bucket) => _hourLabel(bucket.start.toLocal()))
              .toList(growable: false),
          buckets: buckets,
        );

      case HistoryRange.d7:
        const List<String> dayAbbr = <String>[
          'L',
          'M',
          'M',
          'J',
          'V',
          'S',
          'D',
        ];
        final DateTime today = DateTime(now.year, now.month, now.day);
        final DateTime start = today.subtract(const Duration(days: 6));
        final List<_HistoryBucket> buckets = List<_HistoryBucket>.generate(
          7,
          (i) {
            final DateTime bucketStart = start.add(Duration(days: i));
            return _HistoryBucket(
              start: bucketStart,
              end: bucketStart.add(const Duration(days: 1)),
            );
          },
        );
        return _HistoryAxis(
          labels: buckets
              .map((bucket) => dayAbbr[bucket.start.weekday - 1])
              .toList(),
          buckets: buckets,
        );

      case HistoryRange.d30:
        final DateTime today = DateTime(now.year, now.month, now.day);
        final DateTime start = today.subtract(const Duration(days: 29));
        final List<_HistoryBucket> buckets = List<_HistoryBucket>.generate(
          15,
          (i) {
            final DateTime bucketStart = start.add(Duration(days: i * 2));
            return _HistoryBucket(
              start: bucketStart,
              end: bucketStart.add(const Duration(days: 2)),
            );
          },
        );
        return _HistoryAxis(
          labels: List<String>.generate(15, (i) => '${(i + 1) * 2}'),
          buckets: buckets,
        );

      case HistoryRange.all:
        return _buildAllAxis(sorted);
    }
  }

  _HistoryAxis _buildAllAxis(List<BioGTelemetry> sorted) {
    if (sorted.isEmpty) {
      return const _HistoryAxis(
        labels: <String>[],
        buckets: <_HistoryBucket>[],
      );
    }

    final DateTime firstMonth = _calendarMonthStart(
      sorted.first.timestamp.toLocal(),
    );
    final DateTime lastMonth = _calendarMonthStart(
      sorted.last.timestamp.toLocal(),
    );
    final int bucketCount =
        ((lastMonth.year - firstMonth.year) * 12) +
        lastMonth.month -
        firstMonth.month +
        1;
    final List<_HistoryBucket> buckets = List<_HistoryBucket>.generate(
      bucketCount,
      (i) {
        final DateTime start = DateTime(firstMonth.year, firstMonth.month + i);
        final DateTime end = DateTime(start.year, start.month + 1);
        return _HistoryBucket(start: start, end: end);
      },
    );

    return _HistoryAxis(
      labels: buckets
          .map((bucket) => _monthLabel(bucket.start))
          .toList(growable: false),
      buckets: buckets,
    );
  }

  String _hourLabel(DateTime timestamp) {
    final int hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final String period = timestamp.hour < 12 ? 'AM' : 'PM';
    return '$hour $period';
  }

  DateTime _calendarMonthStart(DateTime timestamp) =>
      DateTime(timestamp.year, timestamp.month);

  String _monthLabel(DateTime timestamp) => const <String>[
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ][timestamp.month - 1];
}

class _HistoryAxis {
  final List<String> labels;
  final List<_HistoryBucket> buckets;

  const _HistoryAxis({required this.labels, required this.buckets});
}

class _HistoryBucket {
  final DateTime start;
  final DateTime end;

  const _HistoryBucket({required this.start, required this.end});
}
