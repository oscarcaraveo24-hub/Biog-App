import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/util/uuid_v4.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/services/biog/biog_repository.dart';
import 'package:bio_g/services/biog/identity/device_identity_repository.dart';
import 'package:bio_g/services/biog/identity/supabase_device_identity_repository.dart';
import 'package:bio_g/services/biog/telemetry/offline_first_telemetry_source.dart';
import 'package:bio_g/services/biog/telemetry/telemetry_source.dart';

const bool kBioGHardwareFlowRepositoryDebugLogs = true;

/// Transitional implementation of [BioGRepository] that combines:
///
///   - a REAL [DeviceIdentityRepository] for: devices, memberships,
///     active-device persistence, offline-first caching.
///
///   - an OFFLINE-FIRST [TelemetrySource] for: live telemetry and history.
///
/// This keeps the app offline-first:
///   Bluetooth -> local cache -> repository/UI, then Supabase sync.
///
/// Active device is owned by the identity layer. This repo re-emits
/// active-device-scoped telemetry streams whenever the active device changes,
/// so the UI contract is preserved.
class HybridBioGRepository implements BioGRepository {
  HybridBioGRepository({
    DeviceIdentityRepository? identity,
    TelemetrySource? telemetrySource,
  }) : _identity = identity ?? SupabaseDeviceIdentityRepository(),
       _telemetrySource = telemetrySource ?? OfflineFirstTelemetrySource();

  final DeviceIdentityRepository _identity;

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
  int _bindGeneration = 0;
  int _selectionRevision = 0;
  final Set<String> _loggedHardwareFlowStates = <String>{};

  DeviceIdentityRepository get identity => _identity;
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
  ///   4. Refresh telemetry source for the active device.
  Future<void> bindUser({required String? userId}) async {
    final int generation = ++_bindGeneration;
    _currentUserId = userId;
    _selectionRevision++;
    _activeDevice = null;
    _activeDeviceCtrl.add(null);

    // 1) Local cache first (instant render).
    final identity = _identity;
    if (identity is SupabaseDeviceIdentityRepository) {
      final cached = await identity.loadLocalCache(userId: userId);
      if (!_isCurrentBind(generation, userId)) return;
      _publishDevices(cached, preserveActive: false, resolveActive: false);
    }

    // 2) Remote load (LWW merge against local).
    final fresh = await _identity.loadDevices(userId: userId);
    if (!_isCurrentBind(generation, userId)) return;
    _publishDevices(fresh, preserveActive: false, resolveActive: false);

    // 2.5) Reasignar UUID a los dispositivos con id de texto heredado.
    _lastLegacyIdMigration = await _migrateLegacyDeviceIds(userId);
    if (!_isCurrentBind(generation, userId)) return;

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

      if (!_isCurrentBind(generation, userId)) return;

      _refreshTelemetryForDevice(active);
    } else {
      _activeDevice = null;
      _activeDeviceCtrl.add(null);
      _logHardwareFlowOnce(
        'active device resolved device_id=null reason=no_device',
        onceKey: 'active:none',
      );
    }
  }

  /// Drop every user-scoped state. Local caches are preserved so the
  /// same user can re-hydrate instantly next time.
  void unbindUser() {
    _bindGeneration++;
    _selectionRevision++;
    _currentUserId = null;
    _identity.clearInMemory();

    _devices = const <BioGDevice>[];
    _activeDevice = null;

    _devicesCtrl.add(const <BioGDevice>[]);
    _activeDeviceCtrl.add(null);
  }

  void _publishDevices(
    List<BioGDevice> devices, {
    required bool preserveActive,
    bool resolveActive = true,
  }) {
    _devices = List<BioGDevice>.unmodifiable(devices);
    _devicesCtrl.add(_devices);

    if (!resolveActive) return;

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

  bool _isCurrentBind(int generation, String? userId) {
    return generation == _bindGeneration && _currentUserId == userId;
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
              if (boundTelemetryId != nextId || out.isClosed) return;
              if (t != null && t.deviceId.toLowerCase() != nextId) return;
              out.add(t);
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
              if (boundTelemetryId != nextId || out.isClosed) return;
              out.add(
                List<BioGTelemetry>.unmodifiable(
                  list.where(
                    (BioGTelemetry sample) =>
                        sample.deviceId.toLowerCase() == nextId,
                  ),
                ),
              );
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
    // Alerts are derived by BioGStore from real measurements. There is no
    // synthetic runtime fallback here.
    return Stream<List<BioGAlert>>.value(const <BioGAlert>[]);
  }

  @override
  Future<void> setActiveDevice(String deviceId) async {
    final match = _devices.where((d) => d.id == deviceId);
    if (match.isEmpty) return;

    final int revision = ++_selectionRevision;
    final BioGDevice selected = match.first;
    _activeDevice = selected;
    _activeDeviceCtrl.add(selected);
    _refreshTelemetryForDevice(selected);

    await _identity.setActiveDeviceId(
      userId: _currentUserId,
      deviceId: deviceId,
    );

    if (revision != _selectionRevision) {
      final BioGDevice? current = _activeDevice;
      if (current == null) {
        await _identity.clearActiveDeviceId(userId: _currentUserId);
      } else {
        await _identity.setActiveDeviceId(
          userId: _currentUserId,
          deviceId: current.id,
        );
      }
    }
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

      _publishDevices(next, preserveActive: false, resolveActive: false);

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
    String? hardwareDeviceId,
    String? deviceModelId,
  }) async {
    final DateTime now = DateTime.now();

    // El id DEBE ser un UUID: `devices.id` en Supabase es de tipo `uuid` y
    // `BioGDevice.telemetryDeviceId` descarta cualquier otro formato, de modo
    // que un id de texto produce un dispositivo que ni sube a la nube ni puede
    // leer telemetría. Ver lib/core/util/uuid_v4.dart.
    //
    // Si el aparato declaró su propia identidad, ESA manda. Generar un UUID en
    // el teléfono e ignorar el que trae el hardware era la razón de fondo por
    // la que emparejar un Bio-G real no podía funcionar: la app consultaba
    // `telemetry` con un id que el dispositivo nunca había escrito.
    final String? declaredId = _normalizedHardwareId(hardwareDeviceId);

    // Si ese Bio-G ya está dado de alta, se activa el existente en vez de
    // crear un duplicado.
    //
    // Sin esta comprobación, volver a escanear el mismo QR añadía una segunda
    // entrada a `_devices` (que hace `add()` a ciegas) y el `upsert` con
    // `onConflict: 'id'` machacaba en Supabase el nombre, la ubicación y el
    // cultivo del dispositivo original.
    if (declaredId != null) {
      // Comparación insensible a mayúsculas: `_normalizedHardwareId` baja el
      // id a minúsculas, pero un UUID guardado en mayúsculas (llegado de
      // fuera) no coincidiría y se duplicaría el dispositivo.
      final int existingIndex = _devices.indexWhere(
        (d) => d.id.toLowerCase() == declaredId,
      );
      if (existingIndex >= 0) {
        final BioGDevice existing = _devices[existingIndex];

        // Rellenar el modelo que faltaba. Un equipo dado de alta antes de que
        // el QR llevara el modelo dentro se queda con `deviceModelId` nulo
        // para siempre si esta rama devuelve el existente sin mirar: volver a
        // escanearlo es la única oportunidad de recuperar la identidad, y la
        // estaba tirando.
        //
        // Solo se RELLENA, nunca se sobrescribe: si el equipo ya declaró un
        // modelo, una etiqueta mal impresa no puede cambiárselo.
        final String? incomingModel = deviceModelId?.trim();
        if (existing.deviceModelId == null &&
            incomingModel != null &&
            incomingModel.isNotEmpty) {
          final BioGDevice patched = existing.copyWith(
            deviceModelId: incomingModel,
            updatedAt: now,
          );
          await _identity.upsertDevice(userId: _currentUserId, device: patched);
          final next = List<BioGDevice>.from(_devices);
          next[existingIndex] = patched;
          _publishDevices(next, preserveActive: true);
          await setActiveDevice(patched.id);
          return patched;
        }

        await setActiveDevice(existing.id);
        return existing;
      }
    }

    final String id = declaredId ?? generateUuidV4();

    final BioGDevice device = BioGDevice(
      id: id,
      name: name ?? 'BioG',
      locationName: locationName ?? 'Parcela',
      seedId: seedId ?? 'UNCONFIGURED',
      profileId: profileId ?? 'unconfigured',
      deviceModelId: deviceModelId,
      // Redundante cuando `id` ya es el del hardware, pero deja constancia
      // explícita de que la identidad vino del aparato y no del teléfono.
      telemetryDeviceIdOverride: declaredId,
      status: BioGDeviceStatus.active,
      createdAt: now,
    );

    await _identity.upsertDevice(userId: _currentUserId, device: device);

    final next = List<BioGDevice>.from(_devices)..add(device);
    _publishDevices(next, preserveActive: true);

    // An explicit add/pair action always selects the device just added.
    await setActiveDevice(device.id);

    return device;
  }

  /// Devuelve el id del hardware solo si es un UUID válido.
  ///
  /// Un QR con texto libre (`BIOG-QR-001`) no sirve como `telemetry.device_id`
  /// y se descarta aquí, para que el fallo sea "no se reconoció la identidad"
  /// y no una fila que jamás encontrará su telemetría.
  static String? _normalizedHardwareId(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (!BioGDevice.isTelemetryDeviceId(trimmed)) return null;
    return trimmed.toLowerCase();
  }

  @override
  Future<void> removeDevice(String deviceId) async {
    final BioGDevice? removed = _devices.cast<BioGDevice?>().firstWhere(
      (BioGDevice? device) => device?.id == deviceId,
      orElse: () => null,
    );
    if (removed == null) return;
    _selectionRevision++;

    final String? telemetryDeviceId = removed.telemetryDeviceId;
    if (telemetryDeviceId != null) {
      await _telemetrySource.forgetDevice(telemetryDeviceId);
    }

    await _identity.removeDevice(userId: _currentUserId, deviceId: deviceId);

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
    } else if (removedActive) {
      await _identity.clearActiveDeviceId(userId: _currentUserId);
    }
  }

  // Compatibility no-ops retained for the existing app lifecycle API.
  bool get isPaused => false;

  void pause() {}

  void resume() {}

  @override
  void dispose() {
    _telemetrySource.dispose();
    _devicesCtrl.close();
    _activeDeviceCtrl.close();
    _loggedHardwareFlowStates.clear();
  }
}
