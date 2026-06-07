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
  static const Duration _remoteLatestTimeout = Duration(seconds: 12);
  static const Duration _remoteHistoryTimeout = Duration(seconds: 12);

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
  final Map<String, List<BioGTelemetry>> _historyCacheByKey =
      <String, List<BioGTelemetry>>{};
  final Set<String> _loggedInvalidTelemetryIds = <String>{};
  final Set<String> _loggedFlowStates = <String>{};

  bool _disposed = false;

  @override
  Stream<BioGTelemetry?> watchLive(String deviceId) {
    final normalizedDeviceId = deviceId.trim();
    final controller = _liveControllers.putIfAbsent(
      normalizedDeviceId,
      () => StreamController<BioGTelemetry?>.broadcast(
        onListen: () => unawaited(_startDevice(normalizedDeviceId)),
        onCancel: () => _maybeStopDevice(normalizedDeviceId),
      ),
    );

    _logOnce(
      'load requested source=watch_live device_id=$normalizedDeviceId',
      onceKey: 'watch_live:$normalizedDeviceId',
    );

    // The shared controller is broadcast so Account rows and the detail
    // screen can listen at the same time. Broadcast streams do not replay
    // their last event to late listeners, therefore each subscriber gets a
    // direct memory/local snapshot before continuing with live emissions.
    return Stream<BioGTelemetry?>.multi((listener) {
      bool forwardedLiveEvent = false;
      final subscription = controller.stream.listen(
        (value) {
          forwardedLiveEvent = true;
          listener.add(value);
        },
        onError: listener.addError,
        onDone: listener.close,
      );

      listener.onPause = subscription.pause;
      listener.onResume = subscription.resume;
      listener.onCancel = subscription.cancel;

      unawaited(
        _replayLatestForListener(
          normalizedDeviceId,
          listener,
          shouldEmit: () => !forwardedLiveEvent,
        ),
      );
    }, isBroadcast: true);
  }

  @override
  Stream<List<BioGTelemetry>> watchHistory(
    String deviceId, {
    required Duration? window,
  }) {
    final normalizedDeviceId = deviceId.trim();
    final key = _historyKey(normalizedDeviceId, window);

    final controller = _historyControllers.putIfAbsent(
      key,
      () => StreamController<List<BioGTelemetry>>.broadcast(
        onListen: () {
          unawaited(_startDevice(normalizedDeviceId));
          unawaited(_startHistory(normalizedDeviceId, window));
        },
        onCancel: () => _maybeStopDevice(normalizedDeviceId),
      ),
    );

    return Stream<List<BioGTelemetry>>.multi((listener) {
      bool forwardedHistoryEvent = false;
      final subscription = controller.stream.listen(
        (value) {
          forwardedHistoryEvent = true;
          listener.add(value);
        },
        onError: listener.addError,
        onDone: listener.close,
      );

      listener.onPause = subscription.pause;
      listener.onResume = subscription.resume;
      listener.onCancel = subscription.cancel;

      unawaited(
        _replayHistoryForListener(
          normalizedDeviceId,
          window: window,
          listener: listener,
          shouldEmit: () => !forwardedHistoryEvent,
        ),
      );
    }, isBroadcast: true);
  }

  @override
  Future<void> refresh(
    String deviceId, {
    Duration? window = const Duration(days: 7),
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

  Future<void> _startHistory(String deviceId, Duration? window) async {
    if (_disposed) return;
    // Keep the caller's last stable chart visible while an uncached range is
    // loading. An empty local cache is provisional until cloud refresh ends.
    // For "all", the persisted cache may be capped and therefore partial;
    // wait for the uncapped in-memory cloud result or the explicit fallback.
    if (window != null) {
      await _emitLocalHistory(deviceId, window: window, emitEmpty: false);
    }
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
      if (age < _latestTtl && cached.telemetry != null) {
        _logOnce(
          'cache hit hasData=true device_id=$normalizedDeviceId '
          'age=${age.inSeconds}s',
          onceKey:
              'latest_hit:$normalizedDeviceId:${cached.fetchedAt.toIso8601String()}',
        );
        _emitLatestValue(normalizedDeviceId, cached.telemetry);
        return cached.telemetry;
      }

      _logOnce(
        'cache miss device_id=$normalizedDeviceId '
        'reason=${cached.telemetry == null ? 'empty_payload' : 'expired'}',
        onceKey:
            'latest_miss:$normalizedDeviceId:${cached.fetchedAt.toIso8601String()}',
      );
    } else {
      _logOnce(
        'cache miss device_id=$normalizedDeviceId reason=not_loaded',
        onceKey: 'latest_miss:$normalizedDeviceId:not_loaded',
      );
    }

    final inFlight = _inFlightLatestRequests[normalizedDeviceId];
    if (inFlight != null) {
      _logOnce(
        'joining in-flight latest request device_id=$normalizedDeviceId',
        onceKey: 'latest_in_flight:$normalizedDeviceId',
      );
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
    _log('remote fetch start device_id=$deviceId');

    try {
      final cloudLatest = await _cloudSync
          .downloadLatest(deviceId)
          .timeout(_remoteLatestTimeout);
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
        'remote fetch success device_id=$deviceId hasData=${latest != null} '
        'timestamp=${latest?.timestamp.toIso8601String()} '
        'battery_pct=${latest?.batteryPct} signal_rssi=${latest?.signalRssi}',
      );

      return latest;
    } catch (e) {
      // Offline-first rule:
      // Cloud failures must never break the app.
      _log(
        'remote fetch failed device_id=$deviceId fallback=local '
        'type=${e.runtimeType} message=$e',
      );
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
    required Duration? window,
  }) async {
    if (_disposed) return const <BioGTelemetry>[];

    final normalizedDeviceId = deviceId.trim();
    if (normalizedDeviceId.isEmpty) return const <BioGTelemetry>[];

    if (!TelemetrySupabaseSync.isValidTelemetryDeviceId(normalizedDeviceId)) {
      _logInvalidTelemetryId(normalizedDeviceId);
      await _emitLocalHistory(normalizedDeviceId, window: window);
      return _loadLocalHistory(normalizedDeviceId, window: window);
    }

    final key = _historyKey(normalizedDeviceId, window);
    final now = DateTime.now().toUtc();
    final fetchedAt = _historyFetchedAtByKey[key];
    if (fetchedAt != null) {
      final age = now.difference(fetchedAt);
      if (age < _latestTtl) {
        final cachedHistory =
            _historyCacheByKey[key] ??
            await _loadLocalHistory(normalizedDeviceId, window: window);
        if (cachedHistory.isNotEmpty) {
          _emitHistoryValue(normalizedDeviceId, window, cachedHistory);
          return cachedHistory;
        }
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
    required Duration? window,
  }) async {
    _log(
      'fetching history telemetry device_id=$deviceId '
      'window=${_historyWindowLabel(window)}',
    );

    try {
      final List<BioGTelemetry> cloudHistory;
      if (window == null) {
        cloudHistory = await _cloudSync
            .downloadAll(deviceId)
            .timeout(_remoteHistoryTimeout);
      } else {
        final since = DateTime.now().toUtc().subtract(window);
        cloudHistory = await _cloudSync
            .downloadSince(deviceId, since: since)
            .timeout(_remoteHistoryTimeout);
      }

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

      if (window == null && cloudHistory.isNotEmpty) {
        final localHistory = await _localStorage.load(deviceId);
        final allHistory = _mergeHistoryForRead(
          deviceId,
          <BioGTelemetry>[...localHistory, ...cloudHistory],
        );
        _emitHistoryValue(deviceId, window, allHistory);
        return allHistory;
      }

      await _emitLocalHistory(deviceId, window: window);
      return _loadLocalHistory(deviceId, window: window);
    } catch (e) {
      _log(
        'history cloud error device_id=$deviceId '
        'window=${_historyWindowLabel(window)} fallback=local error=$e',
      );
      _historyFetchedAtByKey[_historyKey(deviceId, window)] = DateTime.now()
          .toUtc();
      await _emitLocalHistory(deviceId, window: window);
      return _loadLocalHistory(deviceId, window: window);
    }
  }

  void _emitLatestValue(String deviceId, BioGTelemetry? latest) {
    if (_disposed) return;
    final controller = _liveControllers[deviceId];
    if (controller == null || controller.isClosed) return;
    controller.add(latest);
    _logOnce(
      'emit state loading=false hasHardware=${latest != null} '
      'error=false device_id=$deviceId',
      onceKey:
          'latest_emit:$deviceId:${latest?.timestamp.toIso8601String() ?? 'null'}',
    );
  }

  Future<void> _replayLatestForListener(
    String deviceId,
    MultiStreamController<BioGTelemetry?> listener, {
    required bool Function() shouldEmit,
  }) async {
    if (_disposed || listener.isClosed) return;

    try {
      final cached = _latestCache[deviceId];
      final latest = cached?.telemetry ?? await _localStorage.latest(deviceId);
      if (_disposed || listener.isClosed || !shouldEmit()) return;
      listener.add(latest);
      _logOnce(
        'cache replay hasData=${latest != null} device_id=$deviceId',
        onceKey:
            'latest_replay:$deviceId:${latest?.timestamp.toIso8601String() ?? 'null'}',
      );
    } catch (e) {
      if (_disposed || listener.isClosed || !shouldEmit()) return;
      listener.add(null);
      _logOnce(
        'cache replay failed device_id=$deviceId '
        'type=${e.runtimeType} message=$e',
        onceKey: 'latest_replay_error:$deviceId:${e.runtimeType}',
      );
    }
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

  Future<void> _replayHistoryForListener(
    String deviceId, {
    required Duration? window,
    required MultiStreamController<List<BioGTelemetry>> listener,
    required bool Function() shouldEmit,
  }) async {
    if (_disposed || listener.isClosed) return;

    try {
      final key = _historyKey(deviceId, window);
      final history =
          _historyCacheByKey[key] ??
          await _loadLocalHistory(deviceId, window: window);
      final bool hasStableEmptyResult = _historyFetchedAtByKey.containsKey(
        key,
      );
      final bool hasStableAllResult =
          window != null ||
          hasStableEmptyResult ||
          _historyCacheByKey.containsKey(key);
      if (_disposed ||
          listener.isClosed ||
          !shouldEmit() ||
          !hasStableAllResult ||
          (history.isEmpty && !hasStableEmptyResult)) {
        return;
      }
      listener.add(history);
    } catch (_) {
      // The shared controller will publish the stable fallback after refresh.
    }
  }

  Future<void> _emitLocalHistory(
    String deviceId, {
    required Duration? window,
    bool emitEmpty = true,
  }) async {
    if (_disposed) return;

    final key = _historyKey(deviceId, window);
    final controller = _historyControllers[key];

    if (controller == null || controller.isClosed) return;

    try {
      final history = await _loadLocalHistory(deviceId, window: window);

      if (history.isEmpty && !emitEmpty) return;
      if (!controller.isClosed) {
        _emitHistoryValue(deviceId, window, history);
      }
    } catch (_) {
      if (!emitEmpty) return;
      if (!controller.isClosed) {
        controller.add(<BioGTelemetry>[]);
      }
    }
  }

  Future<List<BioGTelemetry>> _loadLocalHistory(
    String deviceId, {
    required Duration? window,
  }) {
    if (window == null) return _localStorage.load(deviceId);
    return _localStorage.loadWindow(deviceId, window: window);
  }

  void _emitHistoryValue(
    String deviceId,
    Duration? window,
    List<BioGTelemetry> history,
  ) {
    if (_disposed) return;
    final key = _historyKey(deviceId, window);
    final controller = _historyControllers[key];
    if (controller == null || controller.isClosed) return;

    final stable = List<BioGTelemetry>.unmodifiable(history);
    _historyCacheByKey[key] = stable;
    controller.add(stable);
    _log(
      'history emit device_id=$deviceId '
      'window=${_historyWindowLabel(window)} ${_historyBounds(stable)}',
    );
  }

  List<BioGTelemetry> _mergeHistoryForRead(
    String deviceId,
    List<BioGTelemetry> readings,
  ) {
    final byTimestamp = <String, BioGTelemetry>{};
    for (final reading in readings) {
      if (reading.deviceId != deviceId) continue;
      byTimestamp[reading.timestamp.toUtc().toIso8601String()] = reading;
    }
    return byTimestamp.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  String _historyBounds(List<BioGTelemetry> history) {
    if (history.isEmpty) return 'count=0 oldest=null newest=null';
    return 'count=${history.length} '
        'oldest=${history.first.timestamp.toIso8601String()} '
        'newest=${history.last.timestamp.toIso8601String()}';
  }

  String _historyWindowLabel(Duration? window) {
    return window == null ? 'all' : '${window.inMinutes}m';
  }

  String _historyKey(String deviceId, Duration? window) {
    return '$deviceId|${window?.inSeconds ?? 'all'}';
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
      print('[BioG/HardwareFlow] $message');
      return true;
    }());
  }

  void _logOnce(String message, {required String onceKey}) {
    if (!_loggedFlowStates.add(onceKey)) return;
    _log(message);
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
    _historyCacheByKey.clear();
    _loggedInvalidTelemetryIds.clear();
    _loggedFlowStates.clear();
  }
}

class _CachedTelemetry {
  const _CachedTelemetry({required this.telemetry, required this.fetchedAt});

  final BioGTelemetry? telemetry;
  final DateTime fetchedAt;
}
