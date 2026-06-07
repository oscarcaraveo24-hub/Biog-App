import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/screens/history/history_series_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HistorySeriesBuilder', () {
    test('all range requests history without a time cutoff', () {
      expect(
        const HistorySeriesBuilder().windowForRange(HistoryRange.all),
        isNull,
      );
    });

    test('24h buckets start inside the requested window without fake zeros', () {
      final DateTime now = DateTime(2026, 6, 1, 8);
      final HistoryNpkSeriesSet series = const HistorySeriesBuilder()
          .buildNpkSeries(
            range: HistoryRange.h24,
            telemetry: <BioGTelemetry>[
              _telemetry(now.toUtc().subtract(const Duration(hours: 25)), n: 999),
              _telemetry(
                now.toUtc().subtract(const Duration(hours: 23, minutes: 30)),
                n: 10,
                p: 0,
                k: 0,
                hasPhosphorusData: false,
              ),
              _telemetry(
                now.toUtc().subtract(const Duration(hours: 23, minutes: 15)),
                n: 20,
                p: 30,
                k: 0,
              ),
              _telemetry(
                now.toUtc().subtract(const Duration(hours: 20)),
                n: 40,
                p: 50,
                k: 60,
              ),
            ],
            now: now,
          );

      expect(series.labels, hasLength(24));
      expect(series.nValues.first, 15);
      expect(series.pValues.first, 30);
      expect(series.kValues.first, 0);
      expect(series.nValues[1], isNull);
      expect(series.nValues[4], 40);
      expect(series.nValues, isNot(contains(999)));
    });

    test('missing NPK channels stay null independently', () {
      final DateTime now = DateTime.utc(2026, 6, 1, 12);
      final HistoryNpkSeriesSet series = const HistorySeriesBuilder()
          .buildNpkSeries(
            range: HistoryRange.h24,
            telemetry: <BioGTelemetry>[
              _telemetry(
                now.subtract(const Duration(minutes: 30)),
                n: 12,
                p: 0,
                k: 0,
                hasPhosphorusData: false,
                hasPotassiumData: false,
              ),
            ],
            now: now,
          );

      expect(series.nValues.last, 12);
      expect(series.pValues.last, isNull);
      expect(series.kValues.last, isNull);
    });

    test('generic metrics distinguish a missing value from a real zero', () {
      final DateTime now = DateTime.utc(2026, 6, 1, 12);
      final HistorySeries series = const HistorySeriesBuilder()
          .buildMetricSeries(
            metric: 'Temp',
            range: HistoryRange.h24,
            telemetry: <BioGTelemetry>[
              _telemetry(
                now.subtract(const Duration(hours: 2)),
                n: 10,
                soilTempC: 0,
                hasSoilTempData: false,
              ),
              _telemetry(
                now.subtract(const Duration(minutes: 30)),
                n: 10,
                soilTempC: 0,
              ),
            ],
            now: now,
          );

      expect(series.values[11], isNull);
      expect(series.values.last, 0);
    });

    test('all range exposes missing calendar months as null', () {
      final DateTime now = DateTime.utc(2026, 6, 15, 12);
      final HistorySeries series = const HistorySeriesBuilder()
          .buildMetricSeries(
            metric: 'Temp',
            range: HistoryRange.all,
            telemetry: <BioGTelemetry>[
              _telemetry(DateTime.utc(2025, 8, 10), n: 10, soilTempC: 18),
              _telemetry(DateTime.utc(2026, 6, 10), n: 10, soilTempC: 24),
            ],
            now: now,
          );

      expect(series.labels, <String>[
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
      ]);
      expect(series.values, hasLength(11));
      expect(series.values.first, 18);
      expect(series.values.last, 24);
      expect(series.values.sublist(1, 10).every((value) => value == null), isTrue);
    });

    test('all range summarizes dense history by calendar month', () {
      final DateTime start = DateTime.utc(2026, 4, 27);
      final List<BioGTelemetry> telemetry = List<BioGTelemetry>.generate(
        24,
        (i) => _telemetry(
          start.add(Duration(days: i)),
          n: 10,
          soilTempC: 10 + i.toDouble(),
        ),
      );
      final HistorySeries series = const HistorySeriesBuilder()
          .buildMetricSeries(
            metric: 'Temp',
            range: HistoryRange.all,
            telemetry: telemetry,
          );

      expect(series.labels, <String>['Abr', 'May']);
      expect(series.values, hasLength(2));
      expect(series.values.whereType<double>(), hasLength(2));
    });
  });

  test('BioGTelemetry preserves nutrient presence through local JSON', () {
    final BioGTelemetry parsed = BioGTelemetry.fromJson(<String, dynamic>{
      'device_id': 'device-001',
      'timestamp': '2026-06-01T12:00:00Z',
      'n': 0,
    });

    expect(parsed.n, 0);
    expect(parsed.hasNitrogenData, isTrue);
    expect(parsed.hasPhosphorusData, isFalse);
    expect(parsed.hasPotassiumData, isFalse);

    final BioGTelemetry roundTrip = BioGTelemetry.fromJson(parsed.toJson());
    expect(roundTrip.hasNitrogenData, isTrue);
    expect(roundTrip.hasPhosphorusData, isFalse);
    expect(roundTrip.hasPotassiumData, isFalse);
  });
}

BioGTelemetry _telemetry(
  DateTime timestamp, {
  required double n,
  double p = 20,
  double k = 30,
  double soilTempC = 18,
  bool hasSoilTempData = true,
  bool hasNitrogenData = true,
  bool hasPhosphorusData = true,
  bool hasPotassiumData = true,
}) {
  return BioGTelemetry(
    deviceId: 'device-001',
    timestamp: timestamp,
    airTempC: 20,
    airHumidityPct: 70,
    soilMoisturePct: 50,
    soilTempC: soilTempC,
    ph: 6.5,
    ec: 1,
    resistance: 0.8,
    n: n,
    p: p,
    k: k,
    hasSoilTempData: hasSoilTempData,
    hasNitrogenData: hasNitrogenData,
    hasPhosphorusData: hasPhosphorusData,
    hasPotassiumData: hasPotassiumData,
    batteryPct: 90,
    signalRssi: -50,
  );
}
