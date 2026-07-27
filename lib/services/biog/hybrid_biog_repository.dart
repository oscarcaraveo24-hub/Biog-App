import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/util/uuid_v4.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/services/biog/biog_repository.dart';
import 'package:bio_g/services/biog/identity/device_identity_repository.dart';
import 'package:bio_g/services/biog/identity/supabase_device_identity_repository.dart';
import 'package:bio_g/services/biog/telemetry/offline_first_telemetry_source.dart';
import 'package:bio_g/services/biog/telemetry/sensor_simulator.dart';
import 'package:bio_g/services/biog/telemetry/telemetry_source.dart';

const bool kBioGHardwareFlowRepositoryDebugLogs = true;

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

  /// Interruptor del simulador de sensor.
  ///
  /// El simulador tickea cada segundo, fabrica telemetría sintética y produce
  /// alertas que terminan en `BioGStore.latestAlerts`, un campo que hoy no lee
  /// ninguna pantalla: lo que ve el agricultor sale de `EventEngine` sobre
  /// telemetría real. Mantenerlo encendido en producción gasta batería del
  /// teléfono para llenar un buzón que nadie abre.
  ///
  /// Se deja apagado por defecto. Cámbialo a `true` para desarrollo local si
  /// necesitas datos sintéticos.
  static const bool kEnableSensorSimulator = false;

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
  final Set<String> _loggedHardwareFlowStates = <String>{};

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

    // 2.5) Reasignar UUID a los dispositivos con id de texto heredado.
    _lastLegacyIdMigration = await _migrateLegacyDeviceIds(userId);

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
      _logHardwareFlowOnce(
        'active device resolved ui_device_id=${active.id} '
        'telemetry_device_id=${active.telemetryDeviceId}',
        onceKey: 'active:${active.id}:${active.telemetryDeviceId}',
      );

      await _identity.setActiveDeviceId(userId: userId, deviceId: active.id);

      _refreshTelemetryForDevice(active);
    } else {
      _activeDevice = null;
      _activeDeviceCtrl.add(null);
      _logHardwareFlowOnce(
        'active device resolved device_id=null reason=no_device',
        onceKey: 'active:none',
      );
    }

    // 4) Keep simulator configured for alert fallback only.
    _simulator.configureDevices(_devices);

    if (kEnableSensorSimulator && !_simulatorStarted) {
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
        _refreshTelemetryForDevice(_activeDevice!);
        return;
      }
    }

    // Otherwise fall back to first device (or null).
    _activeDevice = _devices.isEmpty ? null : _devices.first;
    _activeDeviceCtrl.add(_activeDevice);

    final active = _activeDevice;
    if (active != null) {
      _refreshTelemetryForDevice(active);
    }
  }

  void _refreshTelemetryForDevice(
    BioGDevice device, {
    Duration window = const Duration(days: 7),
  }) {
    final telemetryDeviceId = device.telemetryDeviceId;
    if (telemetryDeviceId == null || telemetryDeviceId.isEmpty) {
      _logHardwareFlowOnce(
        'latest telemetry skipped ui_device_id=${device.id} '
        'reason=no_valid_telemetry_device_id',
        onceKey: 'telemetry_id_missing:${device.id}',
      );
      return;
    }
    unawaited(_telemetrySource.refresh(telemetryDeviceId, window: window));
  }

  void _logHardwareFlowOnce(String message, {required String onceKey}) {
    if (!_loggedHardwareFlowStates.add(onceKey)) return;
    if (!kDebugMode || !kBioGHardwareFlowRepositoryDebugLogs) return;
    debugPrint('[BioG/HardwareFlow] $message');
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
  Stream<BioGTelemetry?> watchLiveTelemetry() {
    // STALE-STATE FIX.
    //
    // The previous implementation used a NESTED `await for`: an outer loop
    // over active-device changes and an inner loop over the active device's
    // telemetry. The inner loop only re-checked the active device AFTER the
    // OLD device's telemetry stream emitted again. Because the offline-first
    // source only emits on refresh (TTL-throttled + 10-min polling), changing
    // the active device left the pipeline blocked on the previous device, so
    // the dashboard kept showing the prior BioG's values until the old stream
    // happened to tick.
    //
    // This version swaps the inner subscription the instant the active device
    // changes: it cancels the previous telemetry subscription, emits `null`
    // immediately (so the UI clears without waiting for Supabase), and only
    // re-subscribes when the new device has a valid telemetry device id.
    late final StreamController<BioGTelemetry?> out;
    StreamSubscription<BioGDevice?>? activeSub;
    StreamSubscription<BioGTelemetry?>? liveSub;
    String? boundTelemetryId;
    bool bound = false;

    void bindActive(BioGDevice? active) {
      if (out.isClosed) return;

      final String? raw = active?.telemetryDeviceId;
      final String? nextId = (raw == null || raw.isEmpty) ? null : raw;

      // Same telemetry identity as before → keep the live subscription.
      // Avoids a spurious `null` flicker when the devices list republishes
      // the same active device.
      if (bound && nextId == boundTelemetryId) return;
      bound = true;

      // The active device changed: the previous device's telemetry is invalid
      // as of now. Drop it and clear the UI immediately — never wait for the
      // network to fail first.
      liveSub?.cancel();
      liveSub = null;
      boundTelemetryId = nextId;
      out.add(null);

      // A device with no valid telemetry device id (e.g. a Bluetooth-added
      // BioG not linked to Supabase) stays at `null` — no telemetry.
      if (nextId == null) return;

      unawaited(_telemetrySource.refresh(nextId));
      liveSub = _telemetrySource
          .watchLive(nextId)
          .listen(
            (t) {
              if (boundTelemetryId == nextId && !out.isClosed) out.add(t);
            },
            onError: (Object _, StackTrace _) {
              if (boundTelemetryId == nextId && !out.isClosed) out.add(null);
            },
          );
    }

    out = StreamController<BioGTelemetry?>(
      onListen: () {
        // bindActive() always emits an initial value for the current active
        // device (null when there is none / no telemetry id).
        bindActive(_activeDevice);
        activeSub = _activeDeviceCtrl.stream.listen(bindActive);
      },
      onCancel: () async {
        await activeSub?.cancel();
        await liveSub?.cancel();
        activeSub = null;
        liveSub = null;
      },
    );

    return out.stream;
  }

  @override
  Stream<List<BioGTelemetry>> watchHistory({required Duration? window}) {
    // Same stale-state fix as watchLiveTelemetry: swap the history
    // subscription the moment the active device changes, instead of nesting
    // `await for` loops that stayed bound to the previous device's stream.
    late final StreamController<List<BioGTelemetry>> out;
    StreamSubscription<BioGDevice?>? activeSub;
    StreamSubscription<List<BioGTelemetry>>? historySub;
    String? boundTelemetryId;
    bool bound = false;

    void bindActive(BioGDevice? active) {
      if (out.isClosed) return;

      final String? raw = active?.telemetryDeviceId;
      final String? nextId = (raw == null || raw.isEmpty) ? null : raw;

      if (bound && nextId == boundTelemetryId) return;
      final bool activeDeviceChanged = bound;
      bound = true;

      historySub?.cancel();
      historySub = null;
      boundTelemetryId = nextId;

      // A blank history is a real invalidation only when the active BioG
      // changes. A newly-created stream for another range of the same BioG
      // must not force the UI through a transient empty state.
      if (activeDeviceChanged || nextId == null) {
        out.add(const <BioGTelemetry>[]);
      }

      if (nextId == null) return;

      unawaited(_telemetrySource.refresh(nextId, window: window));
      historySub = _telemetrySource
          .watchHistory(nextId, window: window)
          .listen(
            (list) {
              if (boundTelemetryId == nextId && !out.isClosed) out.add(list);
            },
            onError: (Object _, StackTrace _) {
              if (boundTelemetryId == nextId && !out.isClosed) {
                out.add(const <BioGTelemetry>[]);
              }
            },
          );
    }

    out = StreamController<List<BioGTelemetry>>(
      onListen: () {
        bindActive(_activeDevice);
        activeSub = _activeDeviceCtrl.stream.listen(bindActive);
      },
      onCancel: () async {
        await activeSub?.cancel();
        await historySub?.cancel();
        activeSub = null;
        historySub = null;
      },
    );

    return out.stream;
  }

  @override
  Stream<List<BioGAlert>> watchAlerts({int limit = 50}) {
    // TEMPORARY: alerts still come from SensorSimulator until the alert engine
    // is extracted. Same stale-state fix as the telemetry streams — swap the
    // alert subscription the moment the active device changes so a newly
    // selected BioG never inherits the previous device's alerts.
    late final StreamController<List<BioGAlert>> out;
    StreamSubscription<BioGDevice?>? activeSub;
    StreamSubscription<List<BioGAlert>>? alertsSub;
    String? boundDeviceId;
    bool bound = false;

    void bindActive(BioGDevice? active) {
      if (out.isClosed) return;

      final String? nextId = active?.id;

      if (bound && nextId == boundDeviceId) return;
      bound = true;

      alertsSub?.cancel();
      alertsSub = null;
      boundDeviceId = nextId;
      out.add(const <BioGAlert>[]);

      if (nextId == null) return;

      alertsSub = _simulator
          .watchAlerts(nextId, limit: limit)
          .listen(
            (list) {
              if (boundDeviceId == nextId && !out.isClosed) out.add(list);
            },
            onError: (Object _, StackTrace _) {
              if (boundDeviceId == nextId && !out.isClosed) {
                out.add(const <BioGAlert>[]);
              }
            },
          );
    }

    out = StreamController<List<BioGAlert>>(
      onListen: () {
        bindActive(_activeDevice);
        activeSub = _activeDeviceCtrl.stream.listen(bindActive);
      },
      onCancel: () async {
        await activeSub?.cancel();
        await alertsSub?.cancel();
        activeSub = null;
        alertsSub = null;
      },
    );

    return out.stream;
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

    _refreshTelemetryForDevice(_activeDevice!);
  }

  /// Mapa `idViejo -> idNuevo` de la última migración de ids heredados.
  /// Lo consume [BioGStore] para mover el contexto de cultivo y la
  /// proyección de rendimiento del dispositivo migrado.
  Map<String, String> get lastLegacyIdMigration => _lastLegacyIdMigration;
  Map<String, String> _lastLegacyIdMigration = const <String, String>{};

  /// Reasigna un UUID a los dispositivos guardados con el formato de texto
  /// antiguo (`biog-...`).
  ///
  /// Esos dispositivos están rotos por construcción: nunca subieron a
  /// Supabase —`devices.id` es de tipo `uuid` y rechazaba el insert— y nunca
  /// pudieron leer telemetría, porque `telemetryDeviceId` devuelve null para
  /// cualquier id que no sea UUID. Aquí se les da identidad válida sin que el
  /// usuario pierda su configuración.
  ///
  /// Va envuelto en try/catch a propósito: si la migración falla, la app
  /// arranca igual y el dispositivo se queda exactamente como estaba.
  Future<Map<String, String>> _migrateLegacyDeviceIds(String? userId) async {
    final List<BioGDevice> legacy = _devices
        .where((BioGDevice d) => !BioGDevice.isTelemetryDeviceId(d.id))
        .toList();
    if (legacy.isEmpty) return const <String, String>{};

    final Map<String, String> mapping = <String, String>{};
    final String? previousActiveId = _identity.cachedActiveDeviceId();

    try {
      List<BioGDevice> next = List<BioGDevice>.from(_devices);

      for (final BioGDevice old in legacy) {
        final String newId = generateUuidV4();
        final BioGDevice migrated = old.copyWith(id: newId);

        await _identity.upsertDevice(userId: userId, device: migrated);
        await _identity.removeDevice(userId: userId, deviceId: old.id);

        next = next
            .map((BioGDevice d) => d.id == old.id ? migrated : d)
            .toList();
        mapping[old.id] = newId;

        _logHardwareFlowOnce(
          'legacy device id migrated old=${old.id} new=$newId',
          onceKey: 'migrate:${old.id}',
        );
      }

      _publishDevices(next, preserveActive: false);

      final String? remappedActive = previousActiveId == null
          ? null
          : (mapping[previousActiveId] ?? previousActiveId);
      if (remappedActive != null) {
        await _identity.setActiveDeviceId(
          userId: userId,
          deviceId: remappedActive,
        );
      }
    } catch (e) {
      debugPrint('[biog] migración de ids heredados incompleta: $e');
    }

    return mapping;
  }

  @override
  Future<BioGDevice> addDevice({
    String? seedId,
    String? profileId,
    String? locationName,
    String? name,
  }) async {
    final DateTime now = DateTime.now();

    // El id DEBE ser un UUID: `devices.id` en Supabase es de tipo `uuid` y
    // `BioGDevice.telemetryDeviceId` descarta cualquier otro formato, de modo
    // que un id de texto produce un dispositivo que ni sube a la nube ni puede
    // leer telemetría. Ver lib/core/util/uuid_v4.dart.
    final String id = generateUuidV4();

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

      _refreshTelemetryForDevice(_activeDevice!);
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
    _loggedHardwareFlowStates.clear();
  }
}
