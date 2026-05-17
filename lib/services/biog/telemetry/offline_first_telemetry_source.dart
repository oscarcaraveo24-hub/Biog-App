import 'dart:async';

import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/services/biog/storage/telemetry_local_storage.dart';
import 'package:bio_g/services/biog/storage/telemetry_supabase_sync.dart';
import 'package:bio_g/services/biog/telemetry/telemetry_source.dart';

/// Temporary, controlled traces for Cuenta > Mis BioG telemetry flow.
/// Gated by `assert`, so it is silent in release builds.
const bool kBioGMisBioGTelemetryDebugLogs = true;

/// Offline-first telemetry source.
///
/// Local storage is always the app's primary source of truth.
/// Supabase is used only to refresh/fill local storage when internet is available.
///
/// Flow:
/// local cache -> UI immediately
/// Supabase refresh -> merge local -> UI updates
class OfflineFirstTelemetrySource implements TelemetrySource {
  OfflineFirstTelemetrySource({
    TelemetryLocalStorage? localStorage,
    TelemetrySupabaseSync? cloudSync,
    Duration pollingInterval = const Duration(minutes: 10),
    Duration latestTtl = const Duration(minutes: 10),
  }) : _localStorage = localStorage ?? TelemetryLocalStorage(),
       _cloudSync = cloudSync ?? TelemetrySupabaseSync(),
       _pollingInterval = pollingInterval,
       _latestTtl = latestTtl;

  final TelemetryLocalStorage _localStorage;
  final TelemetrySupabaseSync _cloudSync;
  final Duration _pollingInterval;
  final Duration _latestTtl;

  final Map<String, StreamController<BioGTelemetry?>> _liveControllers = {};
  final Map<String, StreamController<List<BioGTelemetry>>> _historyControllers =
      {};
  final Map<String, Timer> _pollingTimers = {};
  final Map<String, _CachedTelemetry> _latestCache =
      <String, _CachedTelemetry>{};
  final Map<String, Future<BioGTelemetry?>> _inFlightLatestRequests =
      <String, Future<BioGTelemetry?>>{};
  final Map<String, DateTime> _historyFetchedAtByKey = <String, DateTime>{};
  final Map<String, Future<List<BioGTelemetry>>> _inFlightHistoryRequests =
      <String, Future<List<BioGTelemetry>>>{};
  final Set<String> _loggedInvalidTelemetryIds = <String>{};

  bool _disposed = false;

  @override
  Stream<BioGTelemetry?> watchLive(String deviceId) {
    final controller = _liveControllers.putIfAbsent(
      deviceId,
      () => StreamController<BioGTelemetry?>.broadcast(
        onListen: () => unawaited(_startDevice(deviceId)),
        onCancel: () => _maybeStopDevice(deviceId),
      ),
    );

    _emitLocalLatest(deviceId, emitNull: true);

    return controller.stream;
  }

  @override
  Stream<List<BioGTelemetry>> watchHistory(
    String deviceId, {
    required Duration window,
  }) {
    final key = _historyKey(deviceId, window);

    final controller = _historyControllers.putIfAbsent(
      key,
      () => StreamController<List<BioGTelemetry>>.broadcast(
        onListen: () {
          _startDevice(deviceId);
          unawaited(_startHistory(deviceId, window));
        },
        onCancel: () => _maybeStopDevice(deviceId),
      ),
    );

    _emitLocalHistory(deviceId, window: window);

    return controller.stream;
  }

  @override
  Future<void> refresh(
    String deviceId, {
    Duration window = const Duration(days: 7),
  }) {
    return _refreshLatestIfNeeded(deviceId).then((_) {});
  }

  Future<void> _startDevice(String deviceId) async {
    if (_disposed) return;

    _emitLocalLatest(deviceId, emitNull: true);
    unawaited(_refreshLatestIfNeeded(deviceId));

    _pollingTimers.putIfAbsent(
      deviceId,
      () => Timer.periodic(
        _pollingInterval,
        (_) => unawaited(_refreshLatestIfNeeded(deviceId)),
      ),
    );
  }

  Future<void> _startHistory(String deviceId, Duration window) async {
    if (_disposed) return;
    await _emitLocalHistory(deviceId, window: window);
    unawaited(_refreshHistoryIfNeeded(deviceId, window: window));
  }

  void _maybeStopDevice(String deviceId) {
    final hasLiveListeners = _liveControllers[deviceId]?.hasListener ?? false;

    final hasHistoryListeners = _historyControllers.entries.any((entry) {
      if (!entry.key.startsWith('$deviceId|')) return false;
      return entry.value.hasListener;
    });

    if (hasLiveListeners || hasHistoryListeners) return;

    final timer = _pollingTimers.remove(deviceId);
    timer?.cancel();
  }

  Future<BioGTelemetry?> _refreshLatestIfNeeded(String deviceId) async {
    if (_disposed) return null;

    final normalizedDeviceId = deviceId.trim();
    if (normalizedDeviceId.isEmpty) return null;

    if (!TelemetrySupabaseSync.isValidTelemetryDeviceId(normalizedDeviceId)) {
      _logInvalidTelemetryId(normalizedDeviceId);
      await _emitLocalLatest(normalizedDeviceId, emitNull: false);
      return await _localStorage.latest(normalizedDeviceId);
    }

    final now = DateTime.now().toUtc();
    final cached = _latestCache[normalizedDeviceId];
    if (cached != null) {
      final age = now.difference(cached.fetchedAt);
      if (age < _latestTtl) {
        _log(
          'skipped fetch, cache still valid '
          'device_id=$normalizedDeviceId age=${age.inMinutes}m',
        );
        _emitLatestValue(normalizedDeviceId, cached.telemetry);
        return cached.telemetry;
      }
    }

    final inFlight = _inFlightLatestRequests[normalizedDeviceId];
    if (inFlight != null) {
      _log('joining in-flight latest request device_id=$normalizedDeviceId');
      return inFlight;
    }

    final future = _fetchLatest(normalizedDeviceId);
    _inFlightLatestRequests[normalizedDeviceId] = future;

    try {
      return await future;
    } finally {
      _inFlightLatestRequests.remove(normalizedDeviceId);
    }
  }

  Future<BioGTelemetry?> _fetchLatest(String deviceId) async {
    _log('fetching latest telemetry device_id=$deviceId');

    try {
      final cloudLatest = await _cloudSync.downloadLatest(deviceId);
      if (cloudLatest != null) {
        await _localStorage.mergeAndSave(deviceId, <BioGTelemetry>[
          cloudLatest,
        ]);
      }

      final latest = cloudLatest ?? await _localStorage.latest(deviceId);
      _latestCache[deviceId] = _CachedTelemetry(
        telemetry: latest,
        fetchedAt: DateTime.now().toUtc(),
      );
      _emitLatestValue(deviceId, latest);

      _log(
        'latest ready device_id=$deviceId '
        'timestamp=${latest?.timestamp.toIso8601String()} '
        'battery_pct=${latest?.batteryPct} signal_rssi=${latest?.signalRssi}',
      );

      return latest;
    } catch (e) {
      // Offline-first rule:
      // Cloud failures must never break the app.
      _log('latest cloud error device_id=$deviceId fallback=local error=$e');
      final latest = await _localStorage.latest(deviceId);
      _latestCache[deviceId] = _CachedTelemetry(
        telemetry: latest,
        fetchedAt: DateTime.now().toUtc(),
      );
      _emitLatestValue(deviceId, latest);
      return latest;
    }
  }

  Future<List<BioGTelemetry>> _refreshHistoryIfNeeded(
    String deviceId, {
    required Duration window,
  }) async {
    if (_disposed) return const <BioGTelemetry>[];

    final normalizedDeviceId = deviceId.trim();
    if (normalizedDeviceId.isEmpty) return const <BioGTelemetry>[];

    if (!TelemetrySupabaseSync.isValidTelemetryDeviceId(normalizedDeviceId)) {
      _logInvalidTelemetryId(normalizedDeviceId);
      await _emitLocalHistory(normalizedDeviceId, window: window);
      return await _localStorage.loadWindow(normalizedDeviceId, window: window);
    }

    final key = _historyKey(normalizedDeviceId, window);
    final now = DateTime.now().toUtc();
    final fetchedAt = _historyFetchedAtByKey[key];
    if (fetchedAt != null) {
      final age = now.difference(fetchedAt);
      if (age < _latestTtl) {
        _log(
          'skipped history fetch, cache still valid '
          'device_id=$normalizedDeviceId window=${window.inMinutes}m '
          'age=${age.inMinutes}m',
        );
        await _emitLocalHistory(normalizedDeviceId, window: window);
        return await _localStorage.loadWindow(
          normalizedDeviceId,
          window: window,
        );
      }
    }

    final inFlight = _inFlightHistoryRequests[key];
    if (inFlight != null) {
      _log('joining in-flight history request device_id=$normalizedDeviceId');
      return inFlight;
    }

    final future = _fetchHistory(normalizedDeviceId, window: window);
    _inFlightHistoryRequests[key] = future;

    try {
      return await future;
    } finally {
      _inFlightHistoryRequests.remove(key);
    }
  }

  Future<List<BioGTelemetry>> _fetchHistory(
    String deviceId, {
    required Duration window,
  }) async {
    _log(
      'fetching history telemetry device_id=$deviceId '
      'window=${window.inMinutes}m',
    );

    try {
      final since = DateTime.now().toUtc().subtract(window);
      final cloudHistory = await _cloudSync.downloadSince(
        deviceId,
        since: since,
      );

      if (cloudHistory.isNotEmpty) {
        await _localStorage.mergeAndSave(deviceId, cloudHistory);
        _latestCache[deviceId] = _CachedTelemetry(
          telemetry: cloudHistory.last,
          fetchedAt: DateTime.now().toUtc(),
        );
        _emitLatestValue(deviceId, cloudHistory.last);
      }

      _historyFetchedAtByKey[_historyKey(deviceId, window)] = DateTime.now()
          .toUtc();
      await _emitLocalHistory(deviceId, window: window);
      return await _localStorage.loadWindow(deviceId, window: window);
    } catch (e) {
      _log(
        'history cloud error device_id=$deviceId '
        'window=${window.inMinutes}m fallback=local error=$e',
      );
      _historyFetchedAtByKey[_historyKey(deviceId, window)] = DateTime.now()
          .toUtc();
      await _emitLocalHistory(deviceId, window: window);
      return await _localStorage.loadWindow(deviceId, window: window);
    }
  }

  void _emitLatestValue(String deviceId, BioGTelemetry? latest) {
    if (_disposed) return;
    final controller = _liveControllers[deviceId];
    if (controller == null || controller.isClosed) return;
    controller.add(latest);
  }

  Future<void> _emitLocalLatest(String deviceId, {bool emitNull = true}) async {
    if (_disposed) return;

    final controller = _liveControllers[deviceId];
    if (controller == null || controller.isClosed) return;

    try {
      final latest = await _localStorage.latest(deviceId);
      if (latest == null && !emitNull) return;
      if (!controller.isClosed) {
        controller.add(latest);
      }
    } catch (_) {
      if (!emitNull) return;
      if (!controller.isClosed) {
        controller.add(null);
      }
    }
  }

  Future<void> _emitLocalHistory(
    String deviceId, {
    required Duration window,
  }) async {
    if (_disposed) return;

    final key = _historyKey(deviceId, window);
    final controller = _historyControllers[key];

    if (controller == null || controller.isClosed) return;

    try {
      final history = await _localStorage.loadWindow(deviceId, window: window);

      if (!controller.isClosed) {
        controller.add(history);
      }
    } catch (_) {
      if (!controller.isClosed) {
        controller.add(<BioGTelemetry>[]);
      }
    }
  }

  String _historyKey(String deviceId, Duration window) {
    return '$deviceId|${window.inSeconds}';
  }

  void _logInvalidTelemetryId(String uiDeviceId) {
    if (!_loggedInvalidTelemetryIds.add(uiDeviceId)) return;
    _log(
      'invalid telemetry id skipped ui_id=$uiDeviceId '
      'reason=not_uuid',
    );
  }

  void _log(String message) {
    if (!kBioGMisBioGTelemetryDebugLogs) return;
    assert(() {
      // ignore: avoid_print
      print('[BioG/MisBioG] $message');
      return true;
    }());
  }

  @override
  void dispose() {
    _disposed = true;

    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }

    for (final controller in _liveControllers.values) {
      controller.close();
    }

    for (final controller in _historyControllers.values) {
      controller.close();
    }

    _pollingTimers.clear();
    _liveControllers.clear();
    _historyControllers.clear();
    _latestCache.clear();
    _inFlightLatestRequests.clear();
    _historyFetchedAtByKey.clear();
    _inFlightHistoryRequests.clear();
    _loggedInvalidTelemetryIds.clear();
  }
}

class _CachedTelemetry {
  const _CachedTelemetry({required this.telemetry, required this.fetchedAt});

  final BioGTelemetry? telemetry;
  final DateTime fetchedAt;
}
