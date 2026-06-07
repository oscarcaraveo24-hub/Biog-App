import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/services/biog/storage/telemetry_local_storage.dart';
import 'package:bio_g/services/biog/storage/telemetry_supabase_sync.dart';
import 'package:bio_g/services/biog/telemetry/offline_first_telemetry_source.dart';

void main() {
  const deviceId = '7c2a9632-2da5-4a53-9238-6dd561e978ef';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('replays cached telemetry to late listeners and on TTL cache hits',
      () async {
    final telemetry = _telemetry(deviceId);
    final cloud = _FakeTelemetrySupabaseSync(<BioGTelemetry?>[telemetry]);
    final source = OfflineFirstTelemetrySource(
      localStorage: TelemetryLocalStorage(),
      cloudSync: cloud,
      pollingInterval: const Duration(days: 1),
      latestTtl: const Duration(hours: 1),
    );
    addTearDown(source.dispose);

    final stream = source.watchLive(deviceId);
    final firstListenerEvents = <BioGTelemetry?>[];
    final firstSubscription = stream.listen(firstListenerEvents.add);
    addTearDown(firstSubscription.cancel);

    await _waitUntil(() => firstListenerEvents.any((value) => value != null));
    expect(cloud.downloadLatestCalls, 1);

    final beforeCacheHit = firstListenerEvents.length;
    await source.refresh(deviceId);
    await _waitUntil(() => firstListenerEvents.length > beforeCacheHit);
    expect(cloud.downloadLatestCalls, 1);

    final lateTelemetry = await stream
        .firstWhere((value) => value != null)
        .timeout(const Duration(seconds: 1));

    expect(lateTelemetry?.timestamp, telemetry.timestamp);
    expect(lateTelemetry?.batteryPct, 95.2);
    expect(lateTelemetry?.signalRssi, -54);
  });

  test('does not let an empty TTL cache block a later remote retry', () async {
    final telemetry = _telemetry(deviceId);
    final cloud = _FakeTelemetrySupabaseSync(<BioGTelemetry?>[null, telemetry]);
    final source = OfflineFirstTelemetrySource(
      localStorage: TelemetryLocalStorage(),
      cloudSync: cloud,
      pollingInterval: const Duration(days: 1),
      latestTtl: const Duration(hours: 1),
    );
    addTearDown(source.dispose);

    await source.refresh(deviceId);
    expect(cloud.downloadLatestCalls, 1);

    await source.refresh(deviceId);
    expect(cloud.downloadLatestCalls, 2);
  });

  test('null history window downloads all available telemetry', () async {
    final oldTelemetry = _telemetry(
      deviceId,
      timestamp: DateTime.utc(2024, 1, 15),
    );
    final newTelemetry = _telemetry(
      deviceId,
      timestamp: DateTime.utc(2026, 5, 31),
    );
    final cloud = _FakeTelemetrySupabaseSync(
      <BioGTelemetry?>[newTelemetry],
      allResults: <BioGTelemetry>[oldTelemetry, newTelemetry],
    );
    final source = OfflineFirstTelemetrySource(
      localStorage: TelemetryLocalStorage(),
      cloudSync: cloud,
      pollingInterval: const Duration(days: 1),
      latestTtl: const Duration(hours: 1),
    );
    addTearDown(source.dispose);

    final history = await source
        .watchHistory(deviceId, window: null)
        .firstWhere((samples) => samples.length == 2)
        .timeout(const Duration(seconds: 1));

    expect(history.first.timestamp, oldTelemetry.timestamp);
    expect(history.last.timestamp, newTelemetry.timestamp);
    expect(cloud.downloadAllCalls, 1);
    expect(cloud.downloadSinceCalls, 0);
  });
}

BioGTelemetry _telemetry(String deviceId, {DateTime? timestamp}) {
  return BioGTelemetry(
    deviceId: deviceId,
    timestamp: timestamp ?? DateTime.utc(2026, 5, 31, 2, 2, 43),
    airTempC: 19.9,
    airHumidityPct: 74.82,
    soilMoisturePct: 58.54,
    soilTempC: 17.74,
    ph: 6.51,
    ec: 1.08,
    resistance: 0.85,
    n: 69.9,
    p: 30.3,
    k: 84.1,
    batteryPct: 95.2,
    signalRssi: -54,
  );
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (int i = 0; i < 100; i++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not met before timeout.');
}

class _FakeTelemetrySupabaseSync extends TelemetrySupabaseSync {
  _FakeTelemetrySupabaseSync(
    this._latestResults, {
    this.allResults = const <BioGTelemetry>[],
  });

  final List<BioGTelemetry?> _latestResults;
  final List<BioGTelemetry> allResults;
  int downloadLatestCalls = 0;
  int downloadSinceCalls = 0;
  int downloadAllCalls = 0;

  @override
  Future<BioGTelemetry?> downloadLatest(String deviceId) async {
    final index = downloadLatestCalls < _latestResults.length
        ? downloadLatestCalls
        : _latestResults.length - 1;
    downloadLatestCalls++;
    return _latestResults[index];
  }

  @override
  Future<List<BioGTelemetry>> downloadSince(
    String deviceId, {
    required DateTime since,
    int limit = 2000,
  }) async {
    downloadSinceCalls++;
    return const <BioGTelemetry>[];
  }

  @override
  Future<List<BioGTelemetry>> downloadAll(
    String deviceId, {
    int limit = TelemetrySupabaseSync.allHistoryLimit,
  }) async {
    downloadAllCalls++;
    return allResults;
  }
}
