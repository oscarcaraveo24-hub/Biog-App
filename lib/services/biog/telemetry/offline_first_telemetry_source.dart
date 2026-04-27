import 'dart:async';

import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/services/biog/storage/telemetry_local_storage.dart';
import 'package:bio_g/services/biog/storage/telemetry_supabase_sync.dart';
import 'package:bio_g/services/biog/telemetry/telemetry_source.dart';

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
    Duration pollingInterval = const Duration(seconds: 60),
  }) : _localStorage = localStorage ?? TelemetryLocalStorage(),
       _cloudSync = cloudSync ?? TelemetrySupabaseSync(),
       _pollingInterval = pollingInterval;

  final TelemetryLocalStorage _localStorage;
  final TelemetrySupabaseSync _cloudSync;
  final Duration _pollingInterval;

  final Map<String, StreamController<BioGTelemetry?>> _liveControllers = {};
  final Map<String, StreamController<List<BioGTelemetry>>> _historyControllers =
      {};
  final Map<String, Timer> _pollingTimers = {};
  final Set<String> _refreshingDevices = {};

  bool _disposed = false;

  @override
  Stream<BioGTelemetry?> watchLive(String deviceId) {
    final controller = _liveControllers.putIfAbsent(
      deviceId,
      () => StreamController<BioGTelemetry?>.broadcast(
        onListen: () => _startDevice(deviceId),
        onCancel: () => _maybeStopDevice(deviceId),
      ),
    );

    _emitLocalLatest(deviceId);
    _refreshDevice(deviceId);

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
        onListen: () => _startDevice(deviceId),
        onCancel: () => _maybeStopDevice(deviceId),
      ),
    );

    _emitLocalHistory(deviceId, window: window);
    _refreshDevice(deviceId, window: window);

    return controller.stream;
  }

  @override
  Future<void> refresh(
    String deviceId, {
    Duration window = const Duration(days: 7),
  }) {
    return _refreshDevice(deviceId, window: window);
  }

  Future<void> _startDevice(String deviceId) async {
    if (_disposed) return;

    _emitLocalLatest(deviceId);
    await _emitAllLocalHistoriesForDevice(deviceId);
    unawaited(_refreshDevice(deviceId));

    _pollingTimers.putIfAbsent(
      deviceId,
      () => Timer.periodic(
        _pollingInterval,
        (_) => unawaited(_refreshDevice(deviceId)),
      ),
    );
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

  Future<void> _refreshDevice(
    String deviceId, {
    Duration window = const Duration(days: 7),
  }) async {
    if (_disposed) return;
    if (_refreshingDevices.contains(deviceId)) return;

    _refreshingDevices.add(deviceId);

    try {
      final cloudLatest = await _cloudSync.downloadLatest(deviceId);

      final since = DateTime.now().toUtc().subtract(window);
      final cloudHistory = await _cloudSync.downloadSince(
        deviceId,
        since: since,
      );

      final incoming = <BioGTelemetry>[
        if (cloudLatest != null) cloudLatest,
        ...cloudHistory,
      ];

      if (incoming.isNotEmpty) {
        await _localStorage.mergeAndSave(deviceId, incoming);
      }

      _emitLocalLatest(deviceId);
      await _emitAllLocalHistoriesForDevice(deviceId);
    } catch (_) {
      // Offline-first rule:
      // Cloud failures must never break the app.
      _emitLocalLatest(deviceId);
      await _emitAllLocalHistoriesForDevice(deviceId);
    } finally {
      _refreshingDevices.remove(deviceId);
    }
  }

  Future<void> _emitLocalLatest(String deviceId) async {
    if (_disposed) return;

    final controller = _liveControllers[deviceId];
    if (controller == null || controller.isClosed) return;

    try {
      final latest = await _localStorage.latest(deviceId);
      if (!controller.isClosed) {
        controller.add(latest);
      }
    } catch (_) {
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

  Future<void> _emitAllLocalHistoriesForDevice(String deviceId) async {
    final windows = _historyControllers.keys
        .where((key) => key.startsWith('$deviceId|'))
        .map(_windowFromHistoryKey)
        .whereType<Duration>()
        .toSet();

    for (final window in windows) {
      await _emitLocalHistory(deviceId, window: window);
    }
  }

  String _historyKey(String deviceId, Duration window) {
    return '$deviceId|${window.inSeconds}';
  }

  Duration? _windowFromHistoryKey(String key) {
    final parts = key.split('|');
    if (parts.length != 2) return null;

    final seconds = int.tryParse(parts.last);
    if (seconds == null) return null;

    return Duration(seconds: seconds);
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
    _refreshingDevices.clear();
  }
}
