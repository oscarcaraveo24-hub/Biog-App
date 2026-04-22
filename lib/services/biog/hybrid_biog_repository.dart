import 'dart:async';

import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/services/biog/biog_repository.dart';
import 'package:bio_g/services/biog/identity/device_identity_repository.dart';
import 'package:bio_g/services/biog/identity/supabase_device_identity_repository.dart';
import 'package:bio_g/services/biog/telemetry/sensor_simulator.dart';

/// Transitional implementation of [BioGRepository] that combines:
///
///   - a REAL [DeviceIdentityRepository] for: devices, memberships,
///     active-device persistence, offline-first caching.
///
///   - a SIMULATED [SensorSimulator] for: live telemetry, short-term
///     history window and derived alerts.
///
/// This is the boundary where the app's "demo soul" ends. When real
/// hardware arrives, only the simulator is swapped out — identity and
/// everything downstream keep working unchanged.
///
/// Active device is owned by the identity layer. This repo re-emits
/// the active-device-scoped telemetry streams whenever the active
/// device changes, so the UI contract (a single live/history/alerts
/// stream keyed to whatever is currently active) is preserved.
class HybridBioGRepository implements BioGRepository {
  HybridBioGRepository({
    DeviceIdentityRepository? identity,
    SensorSimulator? simulator,
  }) : _identity = identity ?? SupabaseDeviceIdentityRepository(),
       _simulator = simulator ?? SensorSimulator();

  final DeviceIdentityRepository _identity;
  final SensorSimulator _simulator;

  final StreamController<List<BioGDevice>> _devicesCtrl =
      StreamController<List<BioGDevice>>.broadcast();
  final StreamController<BioGDevice?> _activeDeviceCtrl =
      StreamController<BioGDevice?>.broadcast();

  List<BioGDevice> _devices = const <BioGDevice>[];
  BioGDevice? _activeDevice;
  String? _currentUserId;
  bool _simulatorStarted = false;

  DeviceIdentityRepository get identity => _identity;
  SensorSimulator get simulator => _simulator;

  /// Expose the current active device id synchronously. Used by the
  /// store to rehydrate the correct stream set on boot.
  String? get activeDeviceId => _activeDevice?.id;

  /// Hydrate everything for a given user. Called on bootstrap and on
  /// every auth change.
  ///
  /// Strategy (offline-first):
  ///   1. Load local cache instantly → emit so UI has data.
  ///   2. Load remote devices → LWW merge → emit again.
  ///   3. Restore the persisted active-device selection.
  ///   4. Attach the device set to the simulator and start/resume it.
  Future<void> bindUser({
    required String? userId,
    SeedInstall? Function(String deviceId)? seedResolver,
  }) async {
    _currentUserId = userId;

    if (seedResolver != null) {
      _simulator.attachSeedResolver(seedResolver);
    }

    // 1) Local cache first (instant render).
    final identity = _identity;
    if (identity is SupabaseDeviceIdentityRepository) {
      final cached = await identity.loadLocalCache(userId: userId);
      _publishDevices(cached, preserveActive: true);
    }

    // 2) Remote load (LWW merge against local).
    final fresh = await _identity.loadDevices(userId: userId);
    _publishDevices(fresh, preserveActive: true);

    // 3) Restore active device selection.
    final persistedActiveId = _identity.cachedActiveDeviceId();
    BioGDevice? active;
    if (persistedActiveId != null) {
      for (final d in _devices) {
        if (d.id == persistedActiveId) {
          active = d;
          break;
        }
      }
    }
    active ??= _devices.isEmpty ? null : _devices.first;

    if (active != null) {
      _activeDevice = active;
      _activeDeviceCtrl.add(active);
      await _identity.setActiveDeviceId(userId: userId, deviceId: active.id);
    } else {
      _activeDevice = null;
      _activeDeviceCtrl.add(null);
    }

    // 4) Simulator.
    _simulator.configureDevices(_devices);
    if (!_simulatorStarted) {
      _simulator.start();
      _simulatorStarted = true;
    }
  }

  /// Drop every user-scoped state. Local caches are preserved so the
  /// same user can re-hydrate instantly next time.
  void unbindUser() {
    _currentUserId = null;
    _identity.clearInMemory();
    _simulator.configureDevices(const <BioGDevice>[]);
    _devices = const <BioGDevice>[];
    _activeDevice = null;
    _devicesCtrl.add(const <BioGDevice>[]);
    _activeDeviceCtrl.add(null);
  }

  void _publishDevices(
    List<BioGDevice> devices, {
    required bool preserveActive,
  }) {
    _devices = List<BioGDevice>.unmodifiable(devices);
    _devicesCtrl.add(_devices);

    // Refresh the simulator's device set as soon as devices change so
    // history/alerts stay aligned with identity.
    _simulator.configureDevices(_devices);

    if (preserveActive && _activeDevice != null) {
      // Keep the active device pinned if it still exists.
      final match = _devices.where((d) => d.id == _activeDevice!.id);
      if (match.isNotEmpty) {
        _activeDevice = match.first;
        _activeDeviceCtrl.add(_activeDevice);
        return;
      }
    }

    // Otherwise fall back to first device (or null).
    _activeDevice = _devices.isEmpty ? null : _devices.first;
    _activeDeviceCtrl.add(_activeDevice);
  }

  Stream<BioGDevice?> _activeDeviceSelections() async* {
    yield _activeDevice;
    yield* _activeDeviceCtrl.stream;
  }

  // ---------------------------------------------------------------------------
  // BioGRepository
  // ---------------------------------------------------------------------------

  @override
  Stream<List<BioGDevice>> watchDevices() async* {
    yield _devices;
    yield* _devicesCtrl.stream;
  }

  @override
  Stream<BioGDevice?> watchActiveDevice() async* {
    yield _activeDevice;
    yield* _activeDeviceCtrl.stream;
  }

  @override
  Stream<BioGTelemetry?> watchLiveTelemetry() async* {
    // Emit an initial null so UI can render fast even before any device.
    yield null;

    // Re-pipe the simulator's active-device live stream every time the
    // active device changes. Also seed the current selection immediately
    // so late subscribers still attach to the already-active device.
    await for (final active in _activeDeviceSelections()) {
      if (active == null) {
        yield null;
        continue;
      }
      await for (final t in _simulator.watchLive(active.id)) {
        yield t;
        // Break out if active device changes again.
        if (_activeDevice?.id != active.id) break;
      }
    }
  }

  @override
  Stream<List<BioGTelemetry>> watchHistory({required Duration window}) async* {
    yield const <BioGTelemetry>[];

    await for (final active in _activeDeviceSelections()) {
      if (active == null) {
        yield const <BioGTelemetry>[];
        continue;
      }
      await for (final list in _simulator.watchHistory(
        active.id,
        window: window,
      )) {
        yield list;
        if (_activeDevice?.id != active.id) break;
      }
    }
  }

  @override
  Stream<List<BioGAlert>> watchAlerts({int limit = 50}) async* {
    yield const <BioGAlert>[];

    await for (final active in _activeDeviceSelections()) {
      if (active == null) {
        yield const <BioGAlert>[];
        continue;
      }
      await for (final list in _simulator.watchAlerts(
        active.id,
        limit: limit,
      )) {
        yield list;
        if (_activeDevice?.id != active.id) break;
      }
    }
  }

  @override
  Future<void> setActiveDevice(String deviceId) async {
    final match = _devices.where((d) => d.id == deviceId);
    if (match.isEmpty) return;

    _activeDevice = match.first;
    _activeDeviceCtrl.add(_activeDevice);

    await _identity.setActiveDeviceId(
      userId: _currentUserId,
      deviceId: deviceId,
    );
  }

  @override
  Future<BioGDevice> addDevice({
    String? seedId,
    String? profileId,
    String? locationName,
    String? name,
  }) async {
    final DateTime now = DateTime.now();

    // Generate a stable-ish id client-side. For unauthenticated flows
    // we namespace under GUEST; real users will get a proper UUID once
    // a dedicated pairing flow exists. Both are valid as deviceId.
    final String idPrefix = (_currentUserId == null || _currentUserId!.isEmpty)
        ? 'biog-guest-'
        : 'biog-${_currentUserId!.substring(0, 8)}-';
    final String id =
        '$idPrefix${now.microsecondsSinceEpoch.toRadixString(36)}';

    final BioGDevice device = BioGDevice(
      id: id,
      name: name ?? 'BioG',
      locationName: locationName ?? 'Parcela',
      seedId: seedId ?? 'UNCONFIGURED',
      profileId: profileId ?? 'unconfigured',
      status: BioGDeviceStatus.active,
      createdAt: now,
    );

    await _identity.upsertDevice(userId: _currentUserId, device: device);

    final next = List<BioGDevice>.from(_devices)..add(device);
    _publishDevices(next, preserveActive: true);

    // Auto-select if this is the first device.
    if (_activeDevice == null) {
      await setActiveDevice(device.id);
    }

    return device;
  }

  @override
  Future<void> removeDevice(String deviceId) async {
    if (_devices.length <= 1) return;

    await _identity.removeDevice(userId: _currentUserId, deviceId: deviceId);

    _simulator.forgetDevice(deviceId);

    final next = _devices
        .where((d) => d.id != deviceId)
        .toList(growable: false);

    final bool removedActive = _activeDevice?.id == deviceId;
    _publishDevices(next, preserveActive: !removedActive);

    if (removedActive && _activeDevice != null) {
      await _identity.setActiveDeviceId(
        userId: _currentUserId,
        deviceId: _activeDevice!.id,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Simulator control pass-through
  // ---------------------------------------------------------------------------

  bool get isPaused => _simulator.isPaused;
  void pause() => _simulator.pause();
  void resume() => _simulator.resume();

  @override
  void dispose() {
    _simulator.dispose();
    _devicesCtrl.close();
    _activeDeviceCtrl.close();
  }
}
