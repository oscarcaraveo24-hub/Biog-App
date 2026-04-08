import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/models/yield_projection_config.dart';
import 'package:bio_g/services/biog/biog_repository.dart';
import 'package:bio_g/services/biog/fake_biog_repository.dart';
import 'package:bio_g/services/biog/storage/crop_context_storage.dart';
import 'package:bio_g/services/biog/storage/crop_context_supabase_sync.dart';
import 'package:bio_g/services/biog/storage/shared_prefs_crop_context_storage.dart';
import 'package:bio_g/services/biog/storage/shared_prefs_yield_projection_storage.dart';
import 'package:bio_g/services/biog/storage/crop_care_history_sync.dart';
import 'package:bio_g/services/biog/storage/yield_projection_storage.dart';
import 'package:bio_g/services/biog/storage/yield_projection_supabase_sync.dart';

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
       _cropCareHistorySync =
           cropCareHistorySync ?? CropCareHistorySync() {
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

  Future<void> init() async {
    Map<String, DeviceCropContext> loaded = await _cropContextStorage.loadAll();

    // Fallback: if local is empty, try to recover from Supabase.
    if (loaded.isEmpty) {
      final remote = await _cropContextSync.downloadAll();
      if (remote.isNotEmpty) {
        loaded = remote;
        for (final context in remote.values) {
          await _cropContextStorage.save(context);
        }
      }
    }

    _cropByDevice
      ..clear()
      ..addAll(
        loaded.map(
          (deviceId, context) => MapEntry<String, DeviceCropContext>(
            deviceId,
            _normalizeContextForStorage(context),
          ),
        ),
      );

    Map<String, YieldProjectionConfig> loadedYield =
        await _yieldProjectionStorage.loadAll();

    if (loadedYield.isEmpty) {
      final remoteYield = await _yieldProjectionSync.downloadAll();
      if (remoteYield.isNotEmpty) {
        loadedYield = remoteYield;
        for (final config in remoteYield.values) {
          await _yieldProjectionStorage.save(config);
        }
      }
    }

    _yieldByDevice
      ..clear()
      ..addAll(
        loadedYield.map(
          (deviceId, config) => MapEntry<String, YieldProjectionConfig>(
            deviceId,
            _normalizeYieldConfigForStorage(config),
          ),
        ),
      );

    _dropYieldConfigsWithoutCropContext();

    if (_cropByDevice.isNotEmpty) {
      unawaited(_cropContextSync.uploadAll(_cropByDevice));
    }

    if (_yieldByDevice.isNotEmpty) {
      unawaited(_yieldProjectionSync.uploadAll(_yieldByDevice));
    }

    notifyListeners();
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

  DeviceCropContext? get activeCropContext {
    final device = activeDevice;
    if (device == null) return null;
    return _cropByDevice[device.id];
  }

  YieldProjectionConfig? get activeYieldProjectionConfig {
    final device = activeDevice;
    if (device == null) return null;
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

  Future<void> saveCropContext(DeviceCropContext context) async {
    final previous = _cropByDevice[context.deviceId];
    final normalized = _normalizeContextForStorage(context);
    _cropByDevice[normalized.deviceId] = normalized;
    await _cropContextStorage.save(normalized);
    unawaited(_cropContextSync.upload(normalized));

    final previousCropId = _normalizeCropKey(previous?.cropId);
    final nextCropId = _normalizeCropKey(normalized.cropId);

    final cropChanged =
        previousCropId != null &&
        nextCropId != null &&
        previousCropId != nextCropId;

    if (cropChanged ||
        normalized.lifecycleStatus == CropLifecycleStatus.fallow) {
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
    await _cropContextStorage.delete(deviceId);
    unawaited(_cropContextSync.delete(deviceId));
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

    _yieldByDevice[normalized.deviceId] = normalized;
    await _yieldProjectionStorage.save(normalized);
    unawaited(_yieldProjectionSync.upload(normalized));
    notifyListeners();
  }

  Future<void> clearYieldProjectionConfig(
    String deviceId, {
    bool notify = true,
  }) async {
    final removed = _yieldByDevice.remove(deviceId);
    if (removed == null) return;

    await _yieldProjectionStorage.delete(deviceId);
    unawaited(_yieldProjectionSync.delete(deviceId));

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
      unawaited(_cropContextStorage.delete(id));
      unawaited(_yieldProjectionStorage.delete(id));
      unawaited(_cropContextSync.delete(id));
      unawaited(_yieldProjectionSync.delete(id));
    }

    final activeId = activeDevice?.id;
    if (activeId != null && !validIds.contains(activeId)) {
      _resetAgroState();
    }
  }

  void _dropYieldConfigsWithoutCropContext() {
    final orphanIds = _yieldByDevice.keys
        .where((deviceId) => !_cropByDevice.containsKey(deviceId))
        .toList();

    if (orphanIds.isEmpty) return;

    for (final deviceId in orphanIds) {
      _yieldByDevice.remove(deviceId);
      unawaited(_yieldProjectionStorage.delete(deviceId));
      unawaited(_yieldProjectionSync.delete(deviceId));
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
      unawaited(_syncCropCareScore(
        resolvedDeviceId,
        cropContext.cropId,
        eval.soilControlScore01,
      ));
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

  Stream<List<BioGTelemetry>> watchHistory(Duration window) =>
      _repo.watchHistory(window: window);

  Stream<List<BioGAlert>> watchAlerts({int limit = 50}) =>
      _repo.watchAlerts(limit: limit);

  Stream<List<BioGDevice>> watchDevices() => _repo.watchDevices();

  Stream<BioGDevice?> watchActiveDevice() => _repo.watchActiveDevice();

  Future<void> setActiveDevice(String id) async {
    await _repo.setActiveDevice(id);
  }

  Future<BioGDevice> addDemoDevice({
    String? seedId,
    String? profileId,
    String? locationName,
    String? name,
  }) {
    return _repo.addFakeDevice(
      seedId: seedId,
      profileId: profileId,
      locationName: locationName,
      name: name,
    );
  }

  Future<void> removeDevice(String id) async {
    _cropByDevice.remove(id);
    _yieldByDevice.remove(id);
    _alertsStateByDevice.remove(id);
    _agroEvalByDevice.remove(id);
    _cropCareAvgByDevice.remove(id);
    await _cropContextStorage.delete(id);
    await _yieldProjectionStorage.delete(id);
    unawaited(_cropContextSync.delete(id));
    unawaited(_yieldProjectionSync.delete(id));

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
    final bool isFallow = context.lifecycleStatus == CropLifecycleStatus.fallow;

    final String cropCategoryId =
        _normalizeNullable(context.cropCategoryId) ??
        cropEntry?.categoryId ??
        CropCatalog.grainCategoryId;

    final String? rawVarietyValue = isFallow
        ? null
        : (context.varietyId ?? context.varietyAlias);

    final String? resolvedVarietyId = isFallow
        ? null
        : CropCatalog.resolveVarietyId(
            cropId: cropId,
            rawValue: rawVarietyValue,
          );

    final String resolvedProfileId = CropCatalog.resolveProfileId(
      cropId: cropId,
      varietyId: resolvedVarietyId,
      explicitProfileId: isFallow
          ? null
          : _normalizeNullable(context.profileId),
    );

    return context.copyWith(
      cropCategoryId: cropCategoryId,
      cropId: cropId,
      profileId: resolvedProfileId,
      brandId: _resolveBrandId(
        cropId: cropId,
        explicitBrandId: isFallow ? null : context.brandId,
        varietyId: resolvedVarietyId,
      ),
      varietyId: resolvedVarietyId,
      varietyAlias: _resolvedVarietyAlias(
        cropId: cropId,
        lifecycleStatus: context.lifecycleStatus,
        rawVarietyAlias: context.varietyAlias,
        resolvedVarietyId: resolvedVarietyId,
        resolvedProfileId: resolvedProfileId,
      ),
      calendarTypeId: CropCatalog.resolveCalendarId(
        cropId: cropId,
        requested: context.calendarTypeId,
      ),
      sowingDate: context.lifecycleStatus == CropLifecycleStatus.planted
          ? context.sowingDate
          : null,
      plannedSowingDate: context.lifecycleStatus == CropLifecycleStatus.planned
          ? context.plannedSowingDate
          : null,
      sowingModeId:
          _normalizeNullable(context.sowingModeId) ??
          _defaultSowingModeId(context.lifecycleStatus),
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
    if (repo is FakeBioGRepository) repo.pause();
  }

  void resumeSync() {
    final repo = _repo;
    if (repo is FakeBioGRepository) repo.resume();
  }

  bool get isSyncPaused {
    final repo = _repo;
    if (repo is FakeBioGRepository) return repo.isPaused;
    return false;
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _repo.dispose();
    super.dispose();
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
