import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/notifications/notification_dispatcher.dart';
import 'package:bio_g/core/telemetry/telemetry_ingest_service.dart';
import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/services/biog/events/crop_event_local_storage.dart';
import 'package:bio_g/services/biog/events/crop_event_recorder.dart';
import 'package:bio_g/services/biog/sync/pending_sync_queue.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/models/yield_projection_config.dart';
import 'package:bio_g/services/biog/biog_repository.dart';
import 'package:bio_g/services/biog/hybrid_biog_repository.dart';
import 'package:bio_g/services/biog/storage/crop_context_storage.dart';
import 'package:bio_g/services/biog/storage/crop_context_supabase_sync.dart';
import 'package:bio_g/services/biog/storage/shared_prefs_crop_context_storage.dart';
import 'package:bio_g/services/biog/storage/shared_prefs_yield_projection_storage.dart';
import 'package:bio_g/services/biog/storage/crop_care_history_sync.dart';
import 'package:bio_g/services/biog/storage/yield_projection_storage.dart';
import 'package:bio_g/services/biog/storage/yield_projection_supabase_sync.dart';

const bool kBioGMisBioGStoreDebugLogs = true;

class BioGStore extends ChangeNotifier {
  BioGStore(
    this._repo, {
    CropContextStorage? cropContextStorage,
    CropContextSupabaseSync? cropContextSync,
    YieldProjectionStorage? yieldProjectionStorage,
    YieldProjectionSupabaseSync? yieldProjectionSync,
    CropCareHistorySync? cropCareHistorySync,
  }) : _cropContextStorage =
           cropContextStorage ?? SharedPrefsCropContextStorage(),
       _cropContextSync = cropContextSync ?? CropContextSupabaseSync(),
       _yieldProjectionStorage =
           yieldProjectionStorage ?? SharedPrefsYieldProjectionStorage(),
       _yieldProjectionSync =
           yieldProjectionSync ?? YieldProjectionSupabaseSync(),
       _cropCareHistorySync = cropCareHistorySync ?? CropCareHistorySync() {
    _subs.add(
      _repo.watchDevices().listen((v) {
        devices = v;
        _cleanupMissingDeviceSeeds(v);
        notifyListeners();
      }),
    );

    _subs.add(
      _repo.watchActiveDevice().listen((v) {
        activeDevice = v;
        notifyListeners();
      }),
    );

    _subs.add(
      _repo.watchLiveTelemetry().listen((v) {
        live = v;
        notifyListeners();
        // Deja constancia de los eventos del cultivo aunque nadie tenga la
        // pantalla abierta. No altera nada de lo que se muestra.
        unawaited(_cropEventRecorder.recordFromStore(this));
      }),
    );

    _subs.add(
      _repo.watchAlerts(limit: 20).listen((v) {
        latestAlerts = v;
        notifyListeners();
      }),
    );
  }

  final BioGRepository _repo;
  final CropContextStorage _cropContextStorage;
  final CropContextSupabaseSync _cropContextSync;
  final YieldProjectionStorage _yieldProjectionStorage;
  final YieldProjectionSupabaseSync _yieldProjectionSync;
  final CropCareHistorySync _cropCareHistorySync;
  final List<StreamSubscription<dynamic>> _subs =
      <StreamSubscription<dynamic>>[];

  /// The user whose local cache slice currently lives in the
  /// in-memory maps (`_cropByDevice`, `_yieldByDevice`). Null while
  /// no one is bound yet, and during an explicit guest session.
  ///
  /// All storage reads and writes are namespaced with this value so
  /// signing out of user A and signing in as user B cannot leak A's
  /// crop context or yield config into B's session.
  String? _currentUserId;

  /// Exposed for read-only inspection. Persistent writes must go
  /// through [bindUser] / [unbindUser] to keep the namespacing
  /// invariant intact.
  String? get currentUserId => _currentUserId;

  /// Hydrate the store from local storage only. This runs before
  /// [bindUser] and exclusively loads the *guest* slot, so the UI has
  /// something to render immediately on cold start before auth has
  /// resolved. Once [bindUser] runs with a real userId, the guest
  /// slice is discarded and replaced with the authenticated user's.
  Future<void> init() async {
    await _loadLocalCacheFor(userId: null);
    _currentUserId = null;
    notifyListeners();
  }

  /// Replace the in-memory crop context / yield config maps with
  /// whatever the per-user local cache holds for [userId]. Used by
  /// both [init] (guest) and [bindUser] (authenticated).
  Future<void> _loadLocalCacheFor({required String? userId}) async {
    final Map<String, DeviceCropContext> localContexts =
        await _cropContextStorage.loadAll(userId: userId);

    _cropByDevice
      ..clear()
      ..addAll(
        localContexts.map(
          (deviceId, context) => MapEntry<String, DeviceCropContext>(
            deviceId,
            _normalizeContextForStorage(context),
          ),
        ),
      );

    final Map<String, YieldProjectionConfig> localYields =
        await _yieldProjectionStorage.loadAll(userId: userId);

    _yieldByDevice
      ..clear()
      ..addAll(
        localYields.map(
          (deviceId, config) => MapEntry<String, YieldProjectionConfig>(
            deviceId,
            _normalizeYieldConfigForStorage(config),
          ),
        ),
      );

    _dropYieldConfigsWithoutCropContext();
  }

  /// Hydrate user-scoped real state (devices + identity) and merge
  /// remote crop contexts / yield configs using last-write-wins by
  /// `updatedAt`. Call this on login and on every auth change.
  ///
  /// Offline-first: if the network call fails, the local state
  /// remains authoritative and we try again on the next call.
  ///
  /// User isolation: before anything else, the in-memory maps are
  /// replaced with the per-user local cache slice for [userId]. This
  /// prevents leaking state from a previously-bound user into the
  /// current session — a particularly nasty bug when the LWW merge
  /// runs with contaminated `local` and ends up pushing user A's
  /// crop context up to Supabase under user B's account.
  ///
  /// Conflict resolution (explicit):
  ///   For every deviceId present in both local and remote:
  ///     - if remote.updatedAt > local.updatedAt → remote wins, the
  ///       per-user local cache is overwritten.
  ///     - otherwise → local wins and is pushed back to remote.
  Future<void> bindUser({required String? userId}) async {
    // 0) Switch the in-memory slice to the new user BEFORE any merge
    //    logic runs. Same user = instant re-render from their own
    //    cache; different user = starts from a clean, isolated slot.
    _currentUserId = userId;
    _pendingSync.bindUser(userId);
    unawaited(_pendingSync.drain());

    // Reintenta las lecturas que quedaron sin confirmar en la nube. Es el
    // llamador vivo de `uploadBatch`, que hasta ahora no tenía ninguno.
    unawaited(telemetryIngest.flushPending());

    // Carga la bandeja de avisos guardada. Sin esto, los avisos de la sesión
    // anterior no aparecen hasta que llegue la primera lectura nueva: la
    // bandeja sería "persistente" pero no se leería en frío.
    unawaited(notifications.hydrate());
    await _loadLocalCacheFor(userId: userId);
    notifyListeners();

    // 1) Drive identity. The hybrid repo rehydrates its own device
    //    cache and emits fresh device streams.
    final repo = _repo;
    if (repo is HybridBioGRepository) {
      await repo.bindUser(
        userId: userId,
        seedResolver: (deviceId) => seedInstallForDevice(deviceId),
      );
      // 1.5) Si algún dispositivo cambió de id al migrar del formato de texto
      //      antiguo a UUID, hay que mover con él su cultivo y su proyección.
      await _applyLegacyDeviceIdMigration(repo.lastLegacyIdMigration);
    }

    // 2) Pull remote crop contexts and merge with local using LWW.
    //    Note: `_currentUserId` is the authoritative namespace here —
    //    if auth state flipped while we were awaiting, we abort so
    //    we don't write user A's merged data into user B's cache.
    if (userId != null && userId.isNotEmpty) {
      try {
        final remoteContexts = await _cropContextSync.downloadAll();
        if (_currentUserId != userId) return;

        final merged = _mergeCropContextsLWW(
          local: Map<String, DeviceCropContext>.from(_cropByDevice),
          remote: remoteContexts,
        );

        _cropByDevice
          ..clear()
          ..addAll(
            merged.map(
              (k, v) => MapEntry<String, DeviceCropContext>(
                k,
                _normalizeContextForStorage(v),
              ),
            ),
          );

        // Persist the merged winners locally under this user's slot.
        for (final v in _cropByDevice.values) {
          unawaited(_cropContextStorage.save(v, userId: userId));
        }

        // Push anything where local was newer (or missing on remote).
        for (final entry in _cropByDevice.entries) {
          final remote = remoteContexts[entry.key];
          if (remote == null ||
              entry.value.updatedAt.isAfter(remote.updatedAt)) {
            unawaited(_queueCropContextUpload(entry.value));
          }
        }
      } catch (_) {
        // Best-effort; local stays authoritative.
      }

      try {
        final remoteYields = await _yieldProjectionSync.downloadAll();
        if (_currentUserId != userId) return;

        final mergedYields = _mergeYieldConfigsLWW(
          local: Map<String, YieldProjectionConfig>.from(_yieldByDevice),
          remote: remoteYields,
        );

        _yieldByDevice
          ..clear()
          ..addAll(
            mergedYields.map(
              (k, v) => MapEntry<String, YieldProjectionConfig>(
                k,
                _normalizeYieldConfigForStorage(v),
              ),
            ),
          );

        _dropYieldConfigsWithoutCropContext();

        for (final v in _yieldByDevice.values) {
          unawaited(_yieldProjectionStorage.save(v, userId: userId));
        }

        for (final entry in _yieldByDevice.entries) {
          final remote = remoteYields[entry.key];
          if (remote == null ||
              entry.value.updatedAt.isAfter(remote.updatedAt)) {
            unawaited(_queueYieldUpload(entry.value));
          }
        }
      } catch (_) {
        // Best-effort; local stays authoritative.
      }
    }

    notifyListeners();
  }

  /// Drop user-scoped runtime state.
  ///
  /// In-memory crop context / yield config maps are cleared so the
  /// next sign-in (possibly a *different* user) starts from a clean
  /// slate. The on-disk per-user cache slots are preserved intact,
  /// so if the same user signs back in their own slice is re-loaded
  /// instantly via [bindUser] → [_loadLocalCacheFor].
  void unbindUser() {
    final repo = _repo;
    if (repo is HybridBioGRepository) {
      repo.unbindUser();
    }

    // Purga del historial agronómico y de los avisos del usuario que sale.
    //
    // Antes esto solo limpiaba siete mapas en memoria. La tabla `crop_events`
    // no tenía dueño y nadie la borraba, así que cambiar de cuenta en el mismo
    // teléfono dejaba el historial del usuario anterior en disco: fuga de
    // datos y un incumplimiento del derecho de supresión que hay que declarar
    // en las tiendas.
    final String? outgoingUserId = _currentUserId;
    unawaited(_cropEventRecorder.purgeForUser(outgoingUserId));

    _currentUserId = null;
    _cropByDevice.clear();
    _yieldByDevice.clear();
    _alertsStateByDevice.clear();
    _agroEvalByDevice.clear();
    _cropCareAvgByDevice.clear();
    _telemetryStreamsByDevice.clear();
    _loggedTelemetryIds.clear();
    notifyListeners();
  }

  /// Last-write-wins merge for crop contexts by `updatedAt`.
  Map<String, DeviceCropContext> _mergeCropContextsLWW({
    required Map<String, DeviceCropContext> local,
    required Map<String, DeviceCropContext> remote,
  }) {
    final result = <String, DeviceCropContext>{...local};
    for (final entry in remote.entries) {
      final existing = result[entry.key];
      if (existing == null) {
        result[entry.key] = entry.value;
      } else if (entry.value.updatedAt.isAfter(existing.updatedAt)) {
        result[entry.key] = _preserveUnsyncedOrnamentalFields(
          remoteWinner: entry.value,
          localExisting: existing,
        );
      }
    }
    return result;
  }

  /// La tabla remota todavía no tiene columnas ornamentales propias: la etapa
  /// viaja en los slots perennes. Si el remoto gana por `updatedAt` pero llega
  /// sin los campos ornamentales, se conservan los locales.
  DeviceCropContext _preserveUnsyncedOrnamentalFields({
    required DeviceCropContext remoteWinner,
    required DeviceCropContext localExisting,
  }) {
    if (!isEstablishmentMaintenanceContext(remoteWinner) ||
        !isEstablishmentMaintenanceContext(localExisting)) {
      return remoteWinner;
    }

    return remoteWinner.copyWith(
      lifecycleModeId:
          remoteWinner.lifecycleModeId ?? localExisting.lifecycleModeId,
      ornamentalStageId:
          remoteWinner.ornamentalStageId ??
          remoteWinner.perennialStateId ??
          localExisting.ornamentalStageId,
      ornamentalAnchorDate:
          remoteWinner.ornamentalAnchorDate ??
          remoteWinner.perennialAnchorDate ??
          localExisting.ornamentalAnchorDate,
      ornamentalAnchorTypeId:
          remoteWinner.ornamentalAnchorTypeId ??
          remoteWinner.perennialAnchorTypeId ??
          localExisting.ornamentalAnchorTypeId,
      ornamentalAnchorDateConfidence:
          remoteWinner.ornamentalAnchorDateConfidence ??
          localExisting.ornamentalAnchorDateConfidence,
      ornamentalStageConfidence:
          remoteWinner.ornamentalStageId == localExisting.ornamentalStageId
          ? localExisting.ornamentalStageConfidence ??
                remoteWinner.ornamentalStageConfidence
          : remoteWinner.ornamentalStageConfidence ??
                localExisting.ornamentalStageConfidence,
    );
  }

  /// Last-write-wins merge for yield projection configs by `updatedAt`.
  Map<String, YieldProjectionConfig> _mergeYieldConfigsLWW({
    required Map<String, YieldProjectionConfig> local,
    required Map<String, YieldProjectionConfig> remote,
  }) {
    final result = <String, YieldProjectionConfig>{...local};
    for (final entry in remote.entries) {
      final existing = result[entry.key];
      if (existing == null) {
        result[entry.key] = entry.value;
      } else if (entry.value.updatedAt.isAfter(existing.updatedAt)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  List<BioGDevice> devices = const <BioGDevice>[];
  BioGDevice? activeDevice;
  BioGTelemetry? live;
  List<BioGAlert> latestAlerts = const <BioGAlert>[];

  final Map<String, DeviceCropContext> _cropByDevice =
      <String, DeviceCropContext>{};
  final Map<String, YieldProjectionConfig> _yieldByDevice =
      <String, YieldProjectionConfig>{};
  final Map<String, AlertsState> _alertsStateByDevice = <String, AlertsState>{};
  final Map<String, AgroEvalResult> _agroEvalByDevice =
      <String, AgroEvalResult>{};
  final Map<String, double> _cropCareAvgByDevice = <String, double>{};
  final Map<String, Stream<BioGTelemetry?>> _telemetryStreamsByDevice =
      <String, Stream<BioGTelemetry?>>{};
  final Set<String> _loggedTelemetryIds = <String>{};

  DeviceCropContext? get activeCropContext {
    final device = activeDevice;
    if (device == null) return null;
    return _cropByDevice[device.id];
  }

  YieldProjectionConfig? get activeYieldProjectionConfig {
    final device = activeDevice;
    if (device == null) return null;
    if (isEstablishmentMaintenanceContext(_cropByDevice[device.id])) return null;
    return _yieldByDevice[device.id];
  }

  bool get hasSeedInstalled => activeCropContext != null;

  bool get hasActiveYieldProjection =>
      activeYieldProjectionConfig?.isReadyForProjection ?? false;

  Map<String, DeviceCropContext> get cropByDevice =>
      Map<String, DeviceCropContext>.unmodifiable(_cropByDevice);

  Map<String, YieldProjectionConfig> get yieldProjectionByDevice =>
      Map<String, YieldProjectionConfig>.unmodifiable(_yieldByDevice);

  DeviceCropContext? cropContextForDevice(String deviceId) {
    return _cropByDevice[deviceId];
  }

  YieldProjectionConfig? yieldProjectionForDevice(String deviceId) {
    if (isEstablishmentMaintenanceContext(_cropByDevice[deviceId])) return null;
    return _yieldByDevice[deviceId];
  }

  SeedInstall? get activeSeed {
    final context = activeCropContext;
    if (context == null) return null;
    return SeedInstall.fromDeviceCropContext(context);
  }

  Map<String, SeedInstall> get seedByDevice {
    return Map<String, SeedInstall>.unmodifiable(
      _cropByDevice.map(
        (key, value) => MapEntry<String, SeedInstall>(
          key,
          SeedInstall.fromDeviceCropContext(value),
        ),
      ),
    );
  }

  SeedInstall? seedForDevice(String deviceId) {
    final context = _cropByDevice[deviceId];
    if (context == null) return null;
    return SeedInstall.fromDeviceCropContext(context);
  }

  SeedInstall? seedInstallForDevice(String deviceId) {
    final context = _cropByDevice[deviceId];
    if (context == null) return null;
    return SeedInstall.fromDeviceCropContext(context);
  }

  /// Memoria persistente de los eventos del cultivo.
  final CropEventRecorder _cropEventRecorder = CropEventRecorder();

  /// Acceso de solo lectura al historial de eventos registrado.
  CropEventLocalStorage get cropEventStorage => _cropEventRecorder.storage;

  /// Bandeja de avisos, ya filtrada por las preferencias del usuario.
  NotificationDispatcher get notifications => _cropEventRecorder.notifications;

  /// Camino operativo de ingesta de telemetría.
  ///
  /// Aquí es donde se enchufa un [TelemetryTransport] cuando exista el BLE:
  /// `store.telemetryIngest.bindTransport(miTransporteBle)`. Mientras tanto ya
  /// tiene una función real: reintentar las subidas que quedaron pendientes.
  final TelemetryIngestService telemetryIngest = TelemetryIngestService();

  /// Bandeja de salida hacia Supabase.
  ///
  /// Todo lo que hay que subir se apunta aquí primero. Antes cada escritura
  /// remota era un `unawaited(...)` con un `catch` vacío: sin señal, el cambio
  /// se perdía para siempre y el usuario nunca se enteraba.
  late final PendingSyncQueue _pendingSync = PendingSyncQueue(
    handler: _handlePendingSyncOp,
  );

  /// Ejecuta una operación pendiente. La cola no conoce Supabase: sólo sabe
  /// reintentar; quien traduce la operación a una llamada real es esto.
  Future<void> _handlePendingSyncOp(PendingSyncOp op) async {
    if (op.entity == SyncEntity.cropContext) {
      if (op.op == SyncOp.upsert) {
        final Map<String, dynamic>? payload = op.payload;
        if (payload == null) return;
        await _cropContextSync.upload(DeviceCropContext.fromJson(payload));
      } else {
        await _cropContextSync.delete(op.entityId);
      }
      return;
    }

    if (op.op == SyncOp.upsert) {
      final Map<String, dynamic>? payload = op.payload;
      if (payload == null) return;
      await _yieldProjectionSync.upload(
        YieldProjectionConfig.fromJson(payload),
      );
    } else {
      await _yieldProjectionSync.delete(op.entityId);
    }
  }

  Future<void> _queueCropContextUpload(DeviceCropContext c) {
    return _pendingSync.enqueue(
      PendingSyncOp(
        entity: SyncEntity.cropContext,
        op: SyncOp.upsert,
        entityId: c.deviceId,
        payload: c.toJson(),
      ),
    );
  }

  Future<void> _queueCropContextDelete(String deviceId) {
    return _pendingSync.enqueue(
      PendingSyncOp(
        entity: SyncEntity.cropContext,
        op: SyncOp.delete,
        entityId: deviceId,
      ),
    );
  }

  Future<void> _queueYieldUpload(YieldProjectionConfig c) {
    return _pendingSync.enqueue(
      PendingSyncOp(
        entity: SyncEntity.yieldProjection,
        op: SyncOp.upsert,
        entityId: c.deviceId,
        payload: c.toJson(),
      ),
    );
  }

  Future<void> _queueYieldDelete(String deviceId) {
    return _pendingSync.enqueue(
      PendingSyncOp(
        entity: SyncEntity.yieldProjection,
        op: SyncOp.delete,
        entityId: deviceId,
      ),
    );
  }

  /// Re-etiqueta el contexto de cultivo y la proyección de rendimiento cuando
  /// un dispositivo cambió de id al pasar del formato de texto antiguo a UUID.
  ///
  /// Sin esto el usuario conservaría el dispositivo pero perdería el cultivo
  /// que había configurado, que es justo lo que veníamos a evitar.
  Future<void> _applyLegacyDeviceIdMigration(
    Map<String, String> mapping,
  ) async {
    if (mapping.isEmpty) return;

    for (final MapEntry<String, String> entry in mapping.entries) {
      final String oldId = entry.key;
      final String newId = entry.value;

      final DeviceCropContext? crop = _cropByDevice.remove(oldId);
      if (crop != null) {
        final DeviceCropContext moved = crop.copyWith(deviceId: newId);
        _cropByDevice[newId] = moved;
        try {
          await _cropContextStorage.save(moved, userId: _currentUserId);
          await _cropContextStorage.delete(oldId, userId: _currentUserId);
          unawaited(_queueCropContextUpload(moved));
        } catch (e) {
          debugPrint('[biog] no se pudo mover el cultivo de $oldId: $e');
        }
      }

      final YieldProjectionConfig? projection = _yieldByDevice.remove(oldId);
      if (projection != null) {
        final YieldProjectionConfig movedProjection =
            projection.copyWith(deviceId: newId);
        _yieldByDevice[newId] = movedProjection;
        try {
          await _yieldProjectionStorage.save(
            movedProjection,
            userId: _currentUserId,
          );
          await _yieldProjectionStorage.delete(oldId, userId: _currentUserId);
          unawaited(_queueYieldUpload(movedProjection));
        } catch (e) {
          debugPrint('[biog] no se pudo mover la proyección de $oldId: $e');
        }
      }
    }

    notifyListeners();
  }

  /// Guarda el contexto de cultivo de un dispositivo.
  ///
  /// [markSetupCompleted] sella el alta: pasa `setup_status` de `draft` a
  /// `completed` y estampa la fecha. Se pone en true SÓLO desde el cierre de
  /// los wizards. Antes nadie escribía esa columna, así que todos los
  /// registros quedaban en borrador para siempre y era imposible saber qué
  /// usuarios habían terminado de configurar su cultivo.
  Future<void> saveCropContext(
    DeviceCropContext context, {
    bool markSetupCompleted = false,
  }) async {
    final DeviceCropContext sealed = markSetupCompleted
        ? context.copyWith(
            setupStatus: kCropSetupCompleted,
            setupCompletedAt:
                context.setupCompletedAt ?? DateTime.now().toUtc(),
          )
        : context;
    final previous = _cropByDevice[sealed.deviceId];
    final normalized = _normalizeContextForStorage(sealed);
    _cropByDevice[normalized.deviceId] = normalized;
    await _cropContextStorage.save(normalized, userId: _currentUserId);
    unawaited(_queueCropContextUpload(normalized));

    final previousCropId = _normalizeCropKey(previous?.cropId);
    final nextCropId = _normalizeCropKey(normalized.cropId);

    final cropChanged =
        previousCropId != null &&
        nextCropId != null &&
        previousCropId != nextCropId;

    if (isEstablishmentMaintenanceContext(normalized) ||
        isEstablishmentMaintenanceContext(previous)) {
      _cropCareAvgByDevice.remove(normalized.deviceId);
    }

    if (cropChanged ||
        normalized.lifecycleStatus == CropLifecycleStatus.fallow ||
        isEstablishmentMaintenanceContext(normalized)) {
      await clearYieldProjectionConfig(normalized.deviceId, notify: false);
    }

    if (activeDevice?.id == normalized.deviceId) {
      _resetAgroState();
    }

    notifyListeners();
  }

  Future<void> clearCropContext(String deviceId) async {
    final removed = _cropByDevice.remove(deviceId);
    if (removed == null) return;

    _alertsStateByDevice.remove(deviceId);
    _agroEvalByDevice.remove(deviceId);
    _cropCareAvgByDevice.remove(deviceId);
    await _cropContextStorage.delete(deviceId, userId: _currentUserId);
    unawaited(_queueCropContextDelete(deviceId));
    await clearYieldProjectionConfig(deviceId, notify: false);

    if (activeDevice?.id == deviceId) {
      _resetAgroState();
    }

    notifyListeners();
  }

  Future<void> saveYieldProjectionConfig(YieldProjectionConfig config) async {
    final normalized = _normalizeYieldConfigForStorage(config);
    final context = _cropByDevice[normalized.deviceId];

    if (context == null) {
      throw StateError(
        'No se puede guardar YieldProjectionConfig sin DeviceCropContext.',
      );
    }

    final normalizedCropId = _normalizeCropKey(normalized.cropId);
    final contextCropId = _normalizeCropKey(context.cropId);

    if (normalizedCropId == null || contextCropId == null) {
      throw StateError(
        'YieldProjectionConfig requiere cropId canónico válido.',
      );
    }

    if (normalizedCropId != contextCropId) {
      throw StateError(
        'YieldProjectionConfig.cropId no coincide con el cultivo activo del dispositivo.',
      );
    }

    if (isEstablishmentMaintenanceContext(context)) {
      throw StateError(
        'Las plantas ornamentales no admiten proyección de rendimiento ni '
        'cosecha.',
      );
    }

    _yieldByDevice[normalized.deviceId] = normalized;
    await _yieldProjectionStorage.save(normalized, userId: _currentUserId);
    unawaited(_queueYieldUpload(normalized));
    notifyListeners();
  }

  Future<void> clearYieldProjectionConfig(
    String deviceId, {
    bool notify = true,
  }) async {
    final removed = _yieldByDevice.remove(deviceId);
    if (removed == null) return;

    await _yieldProjectionStorage.delete(deviceId, userId: _currentUserId);
    unawaited(_queueYieldDelete(deviceId));

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> setSeedForDevice(String deviceId, SeedInstall seed) async {
    assert(
      seed.deviceId == deviceId,
      'SeedInstall.deviceId debe coincidir con el deviceId asignado.',
    );

    final previous = _cropByDevice[deviceId];
    final resolvedCropId = _requireResolvedCropId(
      requestedCropKey: seed.cropKey,
      previous: previous,
      caller: 'BioGStore.setSeedForDevice',
    );

    final sameCrop = _isSameCanonicalCrop(previous, resolvedCropId);
    final catalogCrop = CropCatalog.cropById(resolvedCropId);

    final normalizedSeed = seed.copyWith(
      deviceId: deviceId,
      cropKey: resolvedCropId,
    );

    final context = normalizedSeed.toDeviceCropContext(
      cropCategoryId:
          catalogCrop?.categoryId ??
          previous?.cropCategoryId ??
          CropCatalog.grainCategoryId,
      timezone: previous?.timezone,
      regionCode: previous?.regionCode,
      cycleLabel: previous?.cycleLabel,
      calendarTypeId: CropCatalog.resolveCalendarId(
        cropId: resolvedCropId,
        requested: null,
        previousCalendarId: sameCrop ? previous?.calendarTypeId : null,
      ),
      sowingModeId: null,
      catalogVersion: CropCatalog.version,
      source: CropConfigSource.wizard,
      configuredAt: sameCrop ? previous?.configuredAt : null,
      updatedAt: DateTime.now(),
    );

    await saveCropContext(context);
  }

  Future<void> setActiveSeed(SeedInstall seed) async {
    final device = activeDevice;
    if (device == null) return;

    final normalizedSeed = seed.deviceId == device.id
        ? seed
        : seed.copyWith(deviceId: device.id);

    await setSeedForDevice(device.id, normalizedSeed);
  }

  Future<void> setSeedSkipForDevice(String deviceId, {String? cropKey}) async {
    final previous = _cropByDevice[deviceId];
    final resolvedCropId = _maybeResolvedCropId(
      requestedCropKey: cropKey,
      previous: previous,
    );

    if (resolvedCropId == null) {
      await clearCropContext(deviceId);
      return;
    }

    final sameCrop = _isSameCanonicalCrop(previous, resolvedCropId);
    final catalogCrop = CropCatalog.cropById(resolvedCropId);
    final resolvedProfileId = CropCatalog.resolveProfileId(
      cropId: resolvedCropId,
      varietyId: null,
      explicitProfileId: null,
    );

    await saveCropContext(
      DeviceCropContext(
        deviceId: deviceId,
        cropCategoryId:
            catalogCrop?.categoryId ??
            previous?.cropCategoryId ??
            CropCatalog.grainCategoryId,
        cropId: resolvedCropId,
        profileId: resolvedProfileId,
        brandId: null,
        varietyId: null,
        varietyAlias: 'generic',
        calendarTypeId: CropCatalog.resolveCalendarId(
          cropId: resolvedCropId,
          requested: null,
          previousCalendarId: sameCrop ? previous?.calendarTypeId : null,
        ),
        lifecycleStatus: CropLifecycleStatus.fallow,
        sowingDate: null,
        plannedSowingDate: null,
        sowingDateConfidence: DateConfidence.unknown,
        sowingModeId: 'skip',
        timezone: previous?.timezone,
        regionCode: previous?.regionCode,
        cycleLabel: previous?.cycleLabel,
        catalogVersion: CropCatalog.version,
        source: CropConfigSource.wizard,
        configuredAt: sameCrop
            ? (previous?.configuredAt ?? DateTime.now())
            : DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> clearSeedForDevice(String deviceId) async {
    await clearCropContext(deviceId);
  }

  void _cleanupMissingDeviceSeeds(List<BioGDevice> currentDevices) {
    // Guard against the cold-start race: the devices stream often emits an
    // empty list before the hybrid repo finishes hydrating real devices from
    // Supabase. Running cleanup then would delete still-valid crop contexts
    // from BOTH local cache and Supabase. An empty device list is treated as
    // "not loaded yet", never as "user owns no devices", so we skip cleanup.
    // Orphans (if any) are reconciled on the next non-empty emission.
    if (currentDevices.isEmpty) return;

    final validIds = currentDevices.map((d) => d.id).toSet();
    final toRemove = <String>{
      ..._cropByDevice.keys.where((id) => !validIds.contains(id)),
      ..._yieldByDevice.keys.where((id) => !validIds.contains(id)),
    }.toList();

    if (toRemove.isEmpty) return;

    for (final id in toRemove) {
      _cropByDevice.remove(id);
      _yieldByDevice.remove(id);
      _alertsStateByDevice.remove(id);
      _agroEvalByDevice.remove(id);
      _cropCareAvgByDevice.remove(id);
      unawaited(_cropContextStorage.delete(id, userId: _currentUserId));
      unawaited(_yieldProjectionStorage.delete(id, userId: _currentUserId));
      unawaited(_queueCropContextDelete(id));
      unawaited(_queueYieldDelete(id));
    }

    final activeId = activeDevice?.id;
    if (activeId != null && !validIds.contains(activeId)) {
      _resetAgroState();
    }
  }

  void _dropYieldConfigsWithoutCropContext() {
    final orphanIds = _yieldByDevice.keys.where((deviceId) {
      final context = _cropByDevice[deviceId];
      return context == null || isEstablishmentMaintenanceContext(context);
    }).toList();

    if (orphanIds.isEmpty) return;

    for (final deviceId in orphanIds) {
      _yieldByDevice.remove(deviceId);
      unawaited(
        _yieldProjectionStorage.delete(deviceId, userId: _currentUserId),
      );
      unawaited(_queueYieldDelete(deviceId));
    }
  }

  AlertsState get alertsState {
    final String? deviceId = activeDevice?.id;
    if (deviceId == null) return const AlertsState();
    return _alertsStateByDevice[deviceId] ?? const AlertsState();
  }

  AgroEvalResult? get lastAgroEval {
    final String? deviceId = activeDevice?.id;
    if (deviceId == null) return null;
    return _agroEvalByDevice[deviceId];
  }

  AlertsState alertsStateForDevice(String deviceId) {
    return _alertsStateByDevice[deviceId] ?? const AlertsState();
  }

  AgroEvalResult? agroEvalForDevice(String deviceId) {
    return _agroEvalByDevice[deviceId];
  }

  void setAgroEval(AgroEvalResult eval, {String? deviceId}) {
    final String? resolvedDeviceId = deviceId ?? activeDevice?.id;
    if (resolvedDeviceId == null) return;
    _agroEvalByDevice[resolvedDeviceId] = eval;
    notifyListeners();

    // Upload today's score and refresh the lifetime average.
    final cropContext = _cropByDevice[resolvedDeviceId];
    if (cropContext != null) {
      unawaited(
        _syncCropCareScore(
          resolvedDeviceId,
          cropContext.cropId,
          eval.soilControlScore01,
        ),
      );
    }
  }

  Future<void> _syncCropCareScore(
    String deviceId,
    String cropId,
    double score01,
  ) async {
    await _cropCareHistorySync.uploadDailyScore(
      deviceId: deviceId,
      cropId: cropId,
      score01: score01,
    );
    final avg = await _cropCareHistorySync.fetchLifetimeAverage(
      deviceId: deviceId,
      cropId: cropId,
    );
    if (avg != null) {
      _cropCareAvgByDevice[deviceId] = avg;
      notifyListeners();
    }
  }

  /// Lifetime average crop care score (0.0–1.0) for the active device.
  ///
  /// Returns `null` while the average hasn't been fetched yet.
  double? get cropCareAverage {
    final String? deviceId = activeDevice?.id;
    if (deviceId == null) return null;
    return _cropCareAvgByDevice[deviceId];
  }

  /// Preload the lifetime average for a device+crop from Supabase.
  Future<void> loadCropCareAverage(String deviceId, String cropId) async {
    final avg = await _cropCareHistorySync.fetchLifetimeAverage(
      deviceId: deviceId,
      cropId: cropId,
    );
    if (avg != null) {
      _cropCareAvgByDevice[deviceId] = avg;
      notifyListeners();
    }
  }

  void setAlertsState(AlertsState s, {String? deviceId}) {
    final String? resolvedDeviceId = deviceId ?? activeDevice?.id;
    if (resolvedDeviceId == null) return;
    _alertsStateByDevice[resolvedDeviceId] = s;
    notifyListeners();
  }

  void clearAgroState({String? deviceId}) {
    _resetAgroState(deviceId: deviceId);
    notifyListeners();
  }

  Stream<BioGTelemetry?> watchLive() => _repo.watchLiveTelemetry();

  /// Per-device live telemetry stream.
  ///
  /// Unlike [watchLive], this is NOT scoped to the active device. Each
  /// device ID gets its own offline-first stream backed by the local
  /// telemetry cache and refreshed from Supabase. Used by Cuenta > Mis
  /// Bio-G so every device row reflects its own real battery / signal,
  /// even when it is not the active one.
  Stream<BioGTelemetry?> watchTelemetryForDevice(String deviceId) {
    final repo = _repo;
    if (repo is HybridBioGRepository) {
      final telemetryDeviceId = telemetryDeviceIdForDeviceId(deviceId);
      if (telemetryDeviceId == null) {
        _logTelemetry(
          'invalid telemetry id skipped ui_id=${deviceId.trim()} '
          'reason=not_uuid',
          onceKey: 'invalid:${deviceId.trim()}',
        );
        return Stream<BioGTelemetry?>.value(null);
      }

      _logTelemetry(
        'using telemetry id ui_id=${deviceId.trim()} '
        'telemetry_device_id=$telemetryDeviceId',
        onceKey: 'using:$telemetryDeviceId',
      );

      return _telemetryStreamsByDevice.putIfAbsent(
        telemetryDeviceId,
        () => repo.telemetrySource.watchLive(telemetryDeviceId),
      );
    }
    return Stream<BioGTelemetry?>.value(null);
  }

  Future<void> refreshTelemetryForDevice(String deviceId) async {
    final repo = _repo;
    if (repo is! HybridBioGRepository) return;

    final telemetryDeviceId = telemetryDeviceIdForDeviceId(deviceId);
    if (telemetryDeviceId == null) {
      _logTelemetry(
        'manual refresh skipped ui_id=${deviceId.trim()} reason=not_uuid',
        onceKey: 'manual_invalid:${deviceId.trim()}',
      );
      return;
    }

    await repo.telemetrySource.refresh(telemetryDeviceId);
  }

  String? telemetryDeviceIdForDeviceId(String deviceId) {
    final normalized = deviceId.trim();
    if (BioGDevice.isTelemetryDeviceId(normalized)) return normalized;

    for (final device in devices) {
      if (device.id == normalized) {
        return device.telemetryDeviceId;
      }
    }

    return null;
  }

  Stream<List<BioGTelemetry>> watchHistory(Duration? window) =>
      _repo.watchHistory(window: window);

  Stream<List<BioGAlert>> watchAlerts({int limit = 50}) =>
      _repo.watchAlerts(limit: limit);

  Stream<List<BioGDevice>> watchDevices() => _repo.watchDevices();

  Stream<BioGDevice?> watchActiveDevice() => _repo.watchActiveDevice();

  Future<void> setActiveDevice(String id) async {
    // Invalidate the previous device's live telemetry IMMEDIATELY, before the
    // repository swaps streams. When the active BioG changes the dashboard must
    // clear stale humidity / pH / temperature / NPK at once — it must not wait
    // for the new device's stream (or for a Supabase failure) to catch up.
    //
    // The new device's live stream re-populates `live` only if it actually has
    // telemetry; a BioG without a valid telemetryDeviceId leaves this at null,
    // so the dashboard stays in its "sin datos" (`--`) state.
    if (activeDevice?.id != id) {
      live = null;
      notifyListeners();
    }
    await _repo.setActiveDevice(id);
  }

  Future<BioGDevice> addDevice({
    String? seedId,
    String? profileId,
    String? locationName,
    String? name,
    String? hardwareDeviceId,
    String? deviceModelId,
  }) {
    return _repo.addDevice(
      seedId: seedId,
      profileId: profileId,
      locationName: locationName,
      name: name,
      hardwareDeviceId: hardwareDeviceId,
      deviceModelId: deviceModelId,
    );
  }

  Future<void> removeDevice(String id) async {
    _cropByDevice.remove(id);
    _yieldByDevice.remove(id);
    _alertsStateByDevice.remove(id);
    _agroEvalByDevice.remove(id);
    _cropCareAvgByDevice.remove(id);
    await _cropContextStorage.delete(id, userId: _currentUserId);
    await _yieldProjectionStorage.delete(id, userId: _currentUserId);
    unawaited(_queueCropContextDelete(id));
    unawaited(_queueYieldDelete(id));

    if (activeDevice?.id == id) {
      _resetAgroState();
    }

    notifyListeners();
    await _repo.removeDevice(id);
  }

  void _resetAgroState({String? deviceId}) {
    final String? resolvedDeviceId = deviceId ?? activeDevice?.id;
    if (resolvedDeviceId == null) return;
    _agroEvalByDevice.remove(resolvedDeviceId);
    _alertsStateByDevice.remove(resolvedDeviceId);
  }

  String? _normalizeCropKey(String? value) =>
      CropCatalog.canonicalCropKeyOrNull(value);

  bool _isSameCanonicalCrop(DeviceCropContext? previous, String cropId) {
    return _normalizeCropKey(previous?.cropId) == cropId;
  }

  String? _maybeResolvedCropId({
    required String? requestedCropKey,
    required DeviceCropContext? previous,
  }) {
    return _normalizeCropKey(requestedCropKey) ??
        _normalizeCropKey(previous?.cropId);
  }

  String _requireResolvedCropId({
    required String? requestedCropKey,
    required DeviceCropContext? previous,
    required String caller,
  }) {
    final resolved = _maybeResolvedCropId(
      requestedCropKey: requestedCropKey,
      previous: previous,
    );

    if (resolved == null) {
      throw StateError(
        '$caller requiere un cropId canónico o un contexto previo válido.',
      );
    }

    return resolved;
  }

  DeviceCropContext _normalizeContextForStorage(DeviceCropContext context) {
    final String cropId = CropCatalog.canonicalCropKey(context.cropId);
    if (cropId.isEmpty) return context;

    final cropEntry = CropCatalog.cropById(cropId);
    final String cropCategoryId =
        _normalizeNullable(context.cropCategoryId) ??
        cropEntry?.categoryId ??
        CropCatalog.grainCategoryId;
    final bool isOrnamental = isEstablishmentMaintenanceCrop(
      cropId: cropId,
      cropCategoryId: cropCategoryId,
    );
    final bool isFallow =
        context.lifecycleStatus == CropLifecycleStatus.fallow && !isOrnamental;
    final CropLifecycleStatus lifecycleStatus =
        isOrnamental && context.lifecycleStatus == CropLifecycleStatus.fallow
        ? CropLifecycleStatus.planted
        : context.lifecycleStatus;

    final String? ornamentalSelectionId = isOrnamental
        ? _resolveOrnamentalSelectionId(
            cropId: cropId,
            profileId: context.profileId,
            varietyId: context.varietyId,
            varietyAlias: context.varietyAlias,
          )
        : null;
    final String? rawVarietyValue = isFallow
        ? null
        : (isOrnamental
              ? ornamentalSelectionId
              : (context.varietyId ?? context.varietyAlias));

    final String? resolvedVarietyId = isFallow
        ? null
        : isOrnamental
        ? ornamentalSelectionId
        : CropCatalog.resolveVarietyId(
            cropId: cropId,
            rawValue: rawVarietyValue,
          );

    final String resolvedProfileId = isOrnamental
        ? (ornamentalSelectionId ?? ornamentalDefaultProfileId(cropId))
        : CropCatalog.resolveProfileId(
            cropId: cropId,
            varietyId: resolvedVarietyId,
            explicitProfileId: isFallow
                ? null
                : _normalizeNullable(context.profileId),
          );

    final DateTime? ornamentalAnchorDate = isOrnamental
        ? context.ornamentalAnchorDate ??
              context.perennialAnchorDate ??
              context.sowingDate
        : context.ornamentalAnchorDate;
    final OrnamentalStageEstimate? ornamentalEstimate = isOrnamental
        ? estimateOrnamentalStageFromDate(
            cropId: cropId,
            plantingDate: ornamentalAnchorDate,
            now: DateTime.now(),
            profileId: resolvedProfileId,
          )
        : null;

    return context.copyWith(
      cropCategoryId: isOrnamental
          ? CropCatalog.ornamentalCategoryId
          : cropCategoryId,
      cropId: cropId,
      profileId: resolvedProfileId,
      lifecycleStatus: lifecycleStatus,
      brandId: _resolveBrandId(
        cropId: cropId,
        explicitBrandId: isFallow || isOrnamental ? null : context.brandId,
        varietyId: resolvedVarietyId,
      ),
      varietyId: resolvedVarietyId,
      varietyAlias: _resolvedVarietyAlias(
        cropId: cropId,
        lifecycleStatus: lifecycleStatus,
        rawVarietyAlias: context.varietyAlias,
        resolvedVarietyId: resolvedVarietyId,
        resolvedProfileId: resolvedProfileId,
      ),
      calendarTypeId: CropCatalog.resolveCalendarId(
        cropId: cropId,
        requested: context.calendarTypeId,
      ),
      sowingDate:
          !isOrnamental && context.lifecycleStatus == CropLifecycleStatus.planted
          ? context.sowingDate
          : null,
      plannedSowingDate:
          !isOrnamental && context.lifecycleStatus == CropLifecycleStatus.planned
          ? context.plannedSowingDate
          : null,
      cultivationScaleId: isOrnamental ? null : context.cultivationScaleId,
      sowingModeId: isOrnamental
          ? null
          : _normalizeNullable(context.sowingModeId) ??
                _defaultSowingModeId(context.lifecycleStatus),
      perennialStateId: isOrnamental ? null : context.perennialStateId,
      phenologyStageId: isOrnamental ? null : context.phenologyStageId,
      perennialAnchorDate: isOrnamental ? null : context.perennialAnchorDate,
      perennialAnchorTypeId: isOrnamental
          ? null
          : context.perennialAnchorTypeId,
      lifecycleModeId: isOrnamental
          ? ornamentalLifecycleMode(cropId)
          : context.lifecycleModeId,
      ornamentalStageId: isOrnamental
          ? normalizeOrnamentalStageId(
              cropId,
              context.ornamentalStageId ??
                  context.perennialStateId ??
                  ornamentalEstimate?.stageId,
            )
          : context.ornamentalStageId,
      ornamentalAnchorDate: ornamentalAnchorDate,
      ornamentalAnchorTypeId: isOrnamental
          ? normalizeOrnamentalAnchorTypeId(
              cropId,
              context.ornamentalAnchorTypeId ??
                  context.perennialAnchorTypeId ??
                  ornamentalEstimate?.anchorTypeId,
            )
          : context.ornamentalAnchorTypeId,
      ornamentalAnchorDateConfidence: isOrnamental
          ? context.ornamentalAnchorDateConfidence ??
                (ornamentalAnchorDate == null
                    ? DateConfidence.unknown
                    : context.sowingDateConfidence)
          : context.ornamentalAnchorDateConfidence,
      ornamentalStageConfidence: isOrnamental
          ? context.ornamentalStageConfidence ??
                ornamentalEstimate?.confidence ??
                0.25
          : context.ornamentalStageConfidence,
    );
  }

  YieldProjectionConfig _normalizeYieldConfigForStorage(
    YieldProjectionConfig config,
  ) {
    final normalizedCropId = _normalizeCropKey(config.cropId) ?? config.cropId;
    return config.copyWith(
      deviceId: config.deviceId.trim(),
      cropId: normalizedCropId.trim(),
      cultivationScaleId: _normalizeNullable(config.cultivationScaleId),
      notes: _normalizeNullable(config.notes),
      updatedAt: config.updatedAt,
    );
  }

  String? _resolveBrandId({
    required String cropId,
    required String? explicitBrandId,
    required String? varietyId,
  }) {
    if (varietyId != null && varietyId.isNotEmpty) {
      final variety = CropCatalog.varietyById(cropId, varietyId);
      final fromVariety = _normalizeNullable(variety?.brandId);
      if (fromVariety != null) return fromVariety;
    }

    final normalizedExplicit = _normalizeNullable(explicitBrandId);
    if (normalizedExplicit == null) return null;

    final valid = CropCatalog.brandsForCrop(
      cropId,
    ).any((brand) => brand.id == normalizedExplicit);
    return valid ? normalizedExplicit : null;
  }

  String? _resolvedVarietyAlias({
    required String cropId,
    required CropLifecycleStatus lifecycleStatus,
    required String? rawVarietyAlias,
    required String? resolvedVarietyId,
    required String resolvedProfileId,
  }) {
    if (lifecycleStatus == CropLifecycleStatus.fallow) {
      return 'generic';
    }

    if (isEstablishmentMaintenanceCrop(cropId: cropId)) {
      return CropCatalog.profileByAny(cropId, resolvedProfileId)?.label ??
          ornamentalGeneralProfileLabel(cropId);
    }

    if (resolvedVarietyId != null) {
      final variety = CropCatalog.varietyById(cropId, resolvedVarietyId);
      if (variety != null) {
        return variety.isGeneric ? 'generic' : variety.label;
      }
    }

    if (CropCatalog.isGenericAlias(rawVarietyAlias) ||
        CropCatalog.isGenericProfileId(resolvedProfileId)) {
      return 'generic';
    }

    return _normalizeNullable(rawVarietyAlias);
  }

  /// Una selección específica superviviente repara un perfil general heredado.
  String? _resolveOrnamentalSelectionId({
    required String cropId,
    String? profileId,
    String? varietyId,
    String? varietyAlias,
  }) {
    final fromProfile = CropCatalog.profileByAny(cropId, profileId);
    final fromVariety = CropCatalog.profileByAny(cropId, varietyId);
    final fromAlias = CropCatalog.profileByAny(cropId, varietyAlias);

    final String generalProfileId = ornamentalDefaultProfileId(cropId);
    for (final entry in [fromVariety, fromProfile, fromAlias]) {
      if (entry != null && entry.id != generalProfileId) {
        return entry.id;
      }
    }
    return fromProfile?.id ?? fromVariety?.id ?? fromAlias?.id;
  }

  String _defaultSowingModeId(CropLifecycleStatus status) {
    return switch (status) {
      CropLifecycleStatus.planned => 'planned',
      CropLifecycleStatus.planted => 'planted',
      CropLifecycleStatus.fallow => 'skip',
    };
  }

  String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  void pauseSync() {
    final repo = _repo;
    if (repo is HybridBioGRepository) repo.pause();
  }

  void resumeSync() {
    final repo = _repo;
    if (repo is HybridBioGRepository) repo.resume();
  }

  bool get isSyncPaused {
    final repo = _repo;
    if (repo is HybridBioGRepository) return repo.isPaused;
    return false;
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _telemetryStreamsByDevice.clear();
    _loggedTelemetryIds.clear();
    unawaited(telemetryIngest.dispose());
    _cropEventRecorder.notifications.dispose();
    _repo.dispose();
    super.dispose();
  }

  void _logTelemetry(String message, {required String onceKey}) {
    if (!_loggedTelemetryIds.add(onceKey)) return;
    if (!kBioGMisBioGStoreDebugLogs) return;
    assert(() {
      debugPrint('[BioG/HardwareFlow] $message');
      return true;
    }());
  }
}

class BioGScope extends InheritedNotifier<BioGStore> {
  const BioGScope({super.key, required BioGStore store, required Widget child})
    : super(notifier: store, child: child);

  static BioGStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BioGScope>();
    assert(
      scope != null,
      'BioGScope no encontrado. Envuelve tu app con BioGScope.',
    );
    return scope!.notifier!;
  }
}
