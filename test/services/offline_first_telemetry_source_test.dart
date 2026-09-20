import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bio_g/core/telemetry/telemetry_contract.dart';
import 'package:bio_g/core/telemetry/telemetry_ingest_service.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/services/biog/storage/telemetry_local_storage.dart';
import 'package:bio_g/services/biog/storage/telemetry_supabase_sync.dart';
import 'package:bio_g/services/biog/telemetry/offline_first_telemetry_source.dart';

void main() {
  const deviceId = '7c2a9632-2da5-4a53-9238-6dd561e978ef';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'replays cached telemetry to late listeners and on TTL cache hits',
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
    },
  );

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

  test(
    'BLE offline commits local and updates live before upload finishes',
    () async {
      final measuredAt = DateTime.utc(2026, 9, 6, 12);
      final local = _MemoryTelemetryLocalStorage();
      final cloud = _DelayedTelemetrySupabaseSync();
      final source = OfflineFirstTelemetrySource(
        localStorage: local,
        cloudSync: cloud,
        pollingInterval: const Duration(days: 1),
        latestTtl: const Duration(hours: 1),
      );
      final ingest = TelemetryIngestService(
        localStorage: local,
        cloudSync: cloud,
        clock: () => measuredAt.add(const Duration(seconds: 1)),
      );
      addTearDown(source.dispose);
      addTearDown(ingest.dispose);

      final events = <BioGTelemetry?>[];
      final subscription = source.watchLive(deviceId).listen(events.add);
      addTearDown(subscription.cancel);
      await _waitUntil(() => cloud.downloadLatestCalls == 1);

      final reading = _telemetry(
        deviceId,
        timestamp: measuredAt,
        n: 12,
        p: 6,
        k: 18,
        soilTempC: 24,
      );
      final ingestFuture = ingest.ingest(
        TelemetryEnvelope(
          identity: const TelemetryDeviceIdentity(deviceId: deviceId),
          measuredAt: measuredAt,
          receivedAt: measuredAt,
          reading: reading,
          sequenceNumber: 1,
          transport: TelemetryTransportKind.ble,
        ),
      );

      await _waitUntil(() => events.any((sample) => sample?.n == 12));
      expect(cloud.uploadBatchCalls, 1);
      expect((events.last!.n, events.last!.p, events.last!.k), (12, 6, 18));
      expect(events.last!.soilTempC, 24);

      // La red termina después de que LIVE ya mostró la lectura.
      cloud.uploadCompleter.complete(false);
      cloud.latestCompleter.complete(null);
      final result = await ingestFuture;
      expect(result.status, TelemetryIngestStatus.storedPendingSync);
    },
  );

  test(
    'an older cloud response finishing after BLE cannot replace live',
    () async {
      final local = _MemoryTelemetryLocalStorage();
      final cloud = _DelayedTelemetrySupabaseSync();
      final source = OfflineFirstTelemetrySource(
        localStorage: local,
        cloudSync: cloud,
        pollingInterval: const Duration(days: 1),
        latestTtl: const Duration(hours: 1),
      );
      addTearDown(source.dispose);

      final events = <BioGTelemetry?>[];
      final subscription = source.watchLive(deviceId).listen(events.add);
      addTearDown(subscription.cancel);
      await _waitUntil(() => cloud.downloadLatestCalls == 1);

      final bleNew = _telemetry(
        deviceId,
        timestamp: DateTime.utc(2026, 9, 6, 13),
        n: 12,
        p: 6,
        k: 18,
      );
      await local.append(deviceId, bleNew);
      await _waitUntil(() => events.last?.timestamp == bleNew.timestamp);

      final cloudOld = _telemetry(
        deviceId,
        timestamp: DateTime.utc(2026, 9, 6, 12),
        n: 34,
        p: 18,
        k: 27,
      );
      cloud.latestCompleter.complete(cloudOld);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(events.last?.timestamp, bleNew.timestamp);
      expect((events.last!.n, events.last!.p, events.last!.k), (12, 6, 18));
      expect(
        events.whereType<BioGTelemetry>().skipWhile((t) => t != bleNew),
        everyElement(
          predicate<BioGTelemetry>((t) => t.timestamp == bleNew.timestamp),
        ),
      );
    },
  );
}

BioGTelemetry _telemetry(
  String deviceId, {
  DateTime? timestamp,
  double n = 69.9,
  double p = 30.3,
  double k = 84.1,
  double soilTempC = 17.74,
}) {
  return BioGTelemetry(
    deviceId: deviceId,
    timestamp: timestamp ?? DateTime.utc(2026, 5, 31, 2, 2, 43),
    airTempC: 19.9,
    airHumidityPct: 74.82,
    soilMoisturePct: 58.54,
    soilTempC: soilTempC,
    ph: 6.51,
    ec: 1.08,
    resistance: 0.85,
    n: n,
    p: p,
    k: k,
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

class _DelayedTelemetrySupabaseSync extends TelemetrySupabaseSync {
  final Completer<BioGTelemetry?> latestCompleter = Completer<BioGTelemetry?>();
  final Completer<bool> uploadCompleter = Completer<bool>();
  int downloadLatestCalls = 0;
  int uploadBatchCalls = 0;

  @override
  Future<BioGTelemetry?> downloadLatest(String deviceId) {
    downloadLatestCalls++;
    return latestCompleter.future;
  }

  @override
  Future<bool> uploadBatch(List<BioGTelemetry> readings) {
    uploadBatchCalls++;
    return uploadCompleter.future;
  }
}

class _MemoryTelemetryLocalStorage extends TelemetryLocalStorage {
  final Map<String, List<BioGTelemetry>> _data =
      <String, List<BioGTelemetry>>{};
  final Map<String, StreamController<BioGTelemetry?>> _controllers =
      <String, StreamController<BioGTelemetry?>>{};

  String _id(String value) => value.trim().toLowerCase();

  @override
  Stream<BioGTelemetry?> watchLatest(String deviceId) => _controllers
      .putIfAbsent(
        _id(deviceId),
        () => StreamController<BioGTelemetry?>.broadcast(sync: true),
      )
      .stream;

  @override
  Future<List<BioGTelemetry>> load(String deviceId) async =>
      List<BioGTelemetry>.from(_data[_id(deviceId)] ?? const []);

  @override
  Future<List<BioGTelemetry>> loadWindow(
    String deviceId, {
    required Duration window,
  }) async {
    final since = DateTime.now().toUtc().subtract(window);
    return (await load(deviceId))
        .where((sample) => !sample.timestamp.toUtc().isBefore(since))
        .toList(growable: false);
  }

  @override
  Future<BioGTelemetry?> latest(String deviceId) async {
    final values = _data[_id(deviceId)] ?? const <BioGTelemetry>[];
    return values.isEmpty ? null : values.last;
  }

  @override
  Future<void> save(String deviceId, List<BioGTelemetry> history) async {
    final id = _id(deviceId);
    _data[id] =
        history
            .where((sample) => _id(sample.deviceId) == id)
            .toList(growable: true)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _emit(id);
  }

  @override
  Future<List<BioGTelemetry>> mergeAndSave(
    String deviceId,
    List<BioGTelemetry> incoming, {
    bool overwriteExisting = true,
  }) async {
    final id = _id(deviceId);
    final byTimestamp = <int, BioGTelemetry>{
      for (final sample in _data[id] ?? const <BioGTelemetry>[])
        sample.timestamp.toUtc().millisecondsSinceEpoch: sample,
    };
    for (final sample in incoming) {
      if (_id(sample.deviceId) != id) continue;
      final stamp = sample.timestamp.toUtc().millisecondsSinceEpoch;
      if (!overwriteExisting && byTimestamp.containsKey(stamp)) continue;
      byTimestamp[stamp] = sample.deviceId == id
          ? sample
          : sample.copyWith(deviceId: id);
    }
    _data[id] = byTimestamp.values.toList(growable: true)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _emit(id);
    return load(id);
  }

  @override
  Future<void> append(String deviceId, BioGTelemetry reading) =>
      mergeAndSave(deviceId, <BioGTelemetry>[reading]).then((_) {});

  @override
  Future<void> delete(String deviceId) async {
    final id = _id(deviceId);
    _data.remove(id);
    _controllers[id]?.add(null);
  }

  void _emit(String deviceId) {
    final values = _data[deviceId] ?? const <BioGTelemetry>[];
    _controllers[deviceId]?.add(values.isEmpty ? null : values.last);
  }
}
