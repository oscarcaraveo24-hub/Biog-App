import 'dart:async';

import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/services/biog/biog_repository.dart';
import 'package:bio_g/services/biog/identity/device_identity_repository.dart';
import 'package:bio_g/services/biog/identity/supabase_device_identity_repository.dart';
import 'package:bio_g/services/biog/telemetry/offline_first_telemetry_source.dart';
import 'package:bio_g/services/biog/telemetry/sensor_simulator.dart';
import 'package:bio_g/services/biog/telemetry/telemetry_source.dart';

/// Transitional implementation of [BioGRepository] that combines:
///
///   - a REAL [DeviceIdentityRepository] for: devices, memberships,
///     active-device persistence, offline-first caching.
///
///   - an OFFLINE-FIRST [TelemetrySource] for: live telemetry and history.
///
///   - a SIMULATED [SensorSimulator] for: derived alerts while the alert
///     engine is still being extracted from simulator code.
///
/// This keeps the app offline-first:
///   Supabase/Bluetooth/future hardware -> local cache -> repository -> UI.
///
/// Active device is owned by the identity layer. This repo re-emits
/// active-device-scoped telemetry streams whenever the active device changes,
/// so the UI contract is preserved.
class HybridBioGRepository implements BioGRepository {
  HybridBioGRepository({
    DeviceIdentityRepository? identity,
    SensorSimulator? simulator,
    TelemetrySource? telemetrySource,
  }) : _identity = identity ?? SupabaseDeviceIdentityRepository(),
       _simulator = simulator ?? SensorSimulator(),
       _telemetrySource = telemetrySource ?? OfflineFirstTelemetrySource();

  final DeviceIdentityRepository _identity;

  /// Temporary alert source.
  ///
  /// Live telemetry and history no longer come from this simulator.
  /// It remains only to avoid breaking watchAlerts until alerts are moved
  /// to a dedicated alert/evaluation engine.
  final SensorSimulator _simulator;

  /// Offline-first telemetry source.
  ///
  /// This should read local cache first and then refresh from Supabase/cloud.
  /// Future Bluetooth sync should also merge into the same local cache.
  final TelemetrySource _telemetrySource;

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
  TelemetrySource get telemetrySource => _telemetrySource;

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
  ///   4. Keep simulator alive only for alert generation fallback.
  ///   5. Refresh telemetry source for the active device.
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

      unawaited(_telemetrySource.refresh(active.id));
    } else {
      _activeDevice = null;
      _activeDeviceCtrl.add(null);
    }

    // 4) Keep simulator configured for alert fallback only.
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

    // Simulator stays configured for temporary alert fallback.
    _simulator.configureDevices(_devices);

    if (preserveActive && _activeDevice != null) {
      // Keep the active device pinned if it still exists.
      final match = _devices.where((d) => d.id == _activeDevice!.id);

      if (match.isNotEmpty) {
        _activeDevice = match.first;
        _activeDeviceCtrl.add(_activeDevice);
        unawaited(_telemetrySource.refresh(_activeDevice!.id));
        return;
      }
    }

    // Otherwise fall back to first device (or null).
    _activeDevice = _devices.isEmpty ? null : _devices.first;
    _activeDeviceCtrl.add(_activeDevice);

    final active = _activeDevice;
    if (active != null) {
      unawaited(_telemetrySource.refresh(active.id));
    }
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

    // Re-pipe the offline-first active-device live stream every time the
    // active device changes. This stream reads local first and refreshes cloud.
    await for (final active in _activeDeviceSelections()) {
      if (active == null) {
        yield null;
        continue;
      }

      unawaited(_telemetrySource.refresh(active.id));

      await for (final t in _telemetrySource.watchLive(active.id)) {
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

      unawaited(_telemetrySource.refresh(active.id, window: window));

      await for (final list in _telemetrySource.watchHistory(
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
    // TEMPORARY:
    // Alerts still come from SensorSimulator until the alert engine is extracted.
    // Do not remove this yet, or several UI flows may lose alert data.
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

    unawaited(_telemetrySource.refresh(deviceId));
  }

  @override
  Future<BioGDevice> addDevice({
    String? seedId,
    String? profileId,
    String? locationName,
    String? name,
  }) async {
    final DateTime now = DateTime.now();

    // NOTE:
    // This legacy client-generated id flow is still kept for compatibility.
    // Real paired devices should eventually come from Supabase devices.id UUID
    // via QR/serial_number pairing instead of generating text ids here.
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

      unawaited(_telemetrySource.refresh(_activeDevice!.id));
    }
  }

  // ---------------------------------------------------------------------------
  // Simulator control pass-through
  // ---------------------------------------------------------------------------

  bool get isPaused => _simulator.isPaused;

  /// Pauses only the temporary simulator alert fallback.
  ///
  /// Offline-first telemetry from Supabase/local storage is not paused here.
  void pause() => _simulator.pause();

  /// Resumes only the temporary simulator alert fallback.
  ///
  /// Offline-first telemetry from Supabase/local storage is not paused here.
  void resume() => _simulator.resume();

  @override
  void dispose() {
    _telemetrySource.dispose();
    _simulator.dispose();
    _devicesCtrl.close();
    _activeDeviceCtrl.close();
  }
}
