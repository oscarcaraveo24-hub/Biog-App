import 'package:bio_g/models/biog_telemetry.dart';

class HistorySeries {
  final List<double> values;
  final List<String> labels;

  const HistorySeries({required this.values, required this.labels});
}

class HistoryNpkSeriesSet {
  final List<String> labels;
  final List<double> nValues;
  final List<double> pValues;
  final List<double> kValues;

  const HistoryNpkSeriesSet({
    required this.labels,
    required this.nValues,
    required this.pValues,
    required this.kValues,
  });
}

enum HistoryRange { h24, d7, d30, all }

class HistorySeriesBuilder {
  const HistorySeriesBuilder();

  Duration windowForRange(HistoryRange range) => switch (range) {
    HistoryRange.h24 => const Duration(hours: 24),
    HistoryRange.d7 => const Duration(days: 7),
    HistoryRange.d30 => const Duration(days: 30),
    HistoryRange.all => const Duration(days: 365),
  };

  double currentLiveForMetric(String metric, BioGTelemetry? live) {
    if (live == null) return 0.0;

    return switch (metric) {
      'Humedad' => live.soilMoisturePct,
      'pH' => live.ph,
      'RT' => live.resistance,
      'Temp' => live.soilTempC,
      'NPK' => (live.n + live.p + live.k) / 3.0,
      _ => 0.0,
    };
  }

  HistorySeries buildMetricSeries({
    required String metric,
    required HistoryRange range,
    required List<BioGTelemetry> telemetry,
    DateTime? now,
  }) {
    final _HistoryAxis axis = _buildAxis(range, now ?? DateTime.now());
    final List<BioGTelemetry> sorted = _sortedTelemetry(telemetry);

    return HistorySeries(
      values: _bucketize(
        sorted: sorted,
        bucketEnds: axis.bucketEnds,
        valueOf: (t) => _valueForMetric(metric, t),
      ),
      labels: axis.labels,
    );
  }

  HistoryNpkSeriesSet buildNpkSeries({
    required HistoryRange range,
    required List<BioGTelemetry> telemetry,
    DateTime? now,
  }) {
    final _HistoryAxis axis = _buildAxis(range, now ?? DateTime.now());
    final List<BioGTelemetry> sorted = _sortedTelemetry(telemetry);

    return HistoryNpkSeriesSet(
      labels: axis.labels,
      nValues: _bucketize(
        sorted: sorted,
        bucketEnds: axis.bucketEnds,
        valueOf: (t) => _valueForNpkKey('n', t),
      ),
      pValues: _bucketize(
        sorted: sorted,
        bucketEnds: axis.bucketEnds,
        valueOf: (t) => _valueForNpkKey('p', t),
      ),
      kValues: _bucketize(
        sorted: sorted,
        bucketEnds: axis.bucketEnds,
        valueOf: (t) => _valueForNpkKey('k', t),
      ),
    );
  }

  List<BioGTelemetry> _sortedTelemetry(List<BioGTelemetry> telemetry) {
    final List<BioGTelemetry> sorted = <BioGTelemetry>[...telemetry];
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  List<double> _bucketize({
    required List<BioGTelemetry> sorted,
    required List<DateTime> bucketEnds,
    required double Function(BioGTelemetry t) valueOf,
  }) {
    DateTime prevEnd = DateTime.fromMillisecondsSinceEpoch(0);
    final List<double> values = <double>[];
    double? lastKnown;

    for (final DateTime end in bucketEnds) {
      final List<BioGTelemetry> bucket = sorted
          .where(
            (e) => e.timestamp.isAfter(prevEnd) && !e.timestamp.isAfter(end),
          )
          .toList();

      double value;
      if (bucket.isEmpty) {
        value = lastKnown ?? 0.0;
      } else {
        final double sum = bucket.fold<double>(
          0.0,
          (acc, e) => acc + valueOf(e),
        );
        value = sum / bucket.length;
        lastKnown = value;
      }

      values.add(value);
      prevEnd = end;
    }

    return values;
  }

  double _valueForMetric(String metric, BioGTelemetry t) {
    return switch (metric) {
      'Humedad' => t.soilMoisturePct,
      'pH' => t.ph,
      'RT' => t.resistance,
      'Temp' => t.soilTempC,
      'NPK' => (t.n + t.p + t.k) / 3.0,
      _ => 0.0,
    };
  }

  double _valueForNpkKey(String key, BioGTelemetry t) {
    final double value = switch (key) {
      'n' => t.n,
      'p' => t.p,
      'k' => t.k,
      _ => 0.0,
    };

    return value < 0 ? 0.0 : value.toDouble();
  }

  _HistoryAxis _buildAxis(HistoryRange range, DateTime now) {
    late final List<String> labels;
    late final List<DateTime> bucketEnds;

    switch (range) {
      case HistoryRange.h24:
        labels = List<String>.generate(13, (i) => '${i * 2}');
        bucketEnds = List<DateTime>.generate(13, (i) {
          final int hoursBack = 24 - (i * 2);
          return now.subtract(Duration(hours: hoursBack));
        });

      case HistoryRange.d7:
        labels = const <String>['L', 'M', 'M', 'J', 'V', 'S', 'D'];
        bucketEnds = List<DateTime>.generate(7, (i) {
          final int daysBack = 6 - i;
          final DateTime day = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: daysBack));
          return day.add(const Duration(hours: 23, minutes: 59));
        });

      case HistoryRange.d30:
        final List<int> ticks = <int>[];
        for (int d = 1; d <= 30; d += 2) {
          ticks.add(d);
        }
        if (ticks.isEmpty || ticks.last != 30) {
          ticks.add(30);
        }

        labels = ticks.map((d) => '$d').toList();
        bucketEnds = List<DateTime>.generate(labels.length, (i) {
          final int daysBack = 30 - ticks[i];
          final DateTime day = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: daysBack));
          return day.add(const Duration(hours: 23, minutes: 59));
        });

      case HistoryRange.all:
        labels = const <String>[
          'E',
          'F',
          'M',
          'A',
          'M',
          'J',
          'J',
          'A',
          'S',
          'O',
          'N',
          'D',
        ];
        bucketEnds = List<DateTime>.generate(12, (i) {
          final int monthOffset = 11 - i;
          final DateTime monthStart = DateTime(
            now.year,
            now.month - monthOffset,
            1,
          );
          return DateTime(
            monthStart.year,
            monthStart.month + 1,
            1,
          ).subtract(const Duration(seconds: 1));
        });
    }

    return _HistoryAxis(labels: labels, bucketEnds: bucketEnds);
  }
}

class _HistoryAxis {
  final List<String> labels;
  final List<DateTime> bucketEnds;

  const _HistoryAxis({required this.labels, required this.bucketEnds});
}
