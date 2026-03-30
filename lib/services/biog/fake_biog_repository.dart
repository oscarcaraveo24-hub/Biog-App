import 'dart:async';
import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/services/biog/biog_repository.dart';
import 'package:bio_g/services/biog/storage/telemetry_local_storage.dart';
import 'package:bio_g/services/biog/storage/telemetry_supabase_sync.dart';

enum NpkNutrient { n, p, k }

class FakeBioGRepository implements BioGRepository {
  FakeBioGRepository({
    this.tick = const Duration(seconds: 1),
    int historyCap = 2000,
    SeedInstall? Function(String deviceId)? seedResolver,
    TelemetryLocalStorage? localStorage,
    TelemetrySupabaseSync? supabaseSync,
  }) : _historyCap = historyCap,
       _seedResolver = seedResolver,
       _localStorage = localStorage ?? TelemetryLocalStorage(),
       _supabaseSync = supabaseSync ?? TelemetrySupabaseSync() {
    final d0 = BioGDevice(
      id: 'BIOG-DEMO-001',
      name: 'BioG Demo',
      locationName: 'Parcela Demo',
      seedId: _legacyUnconfiguredSeedId,
      profileId: _legacyUnconfiguredProfileId,
      status: BioGDeviceStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
    );

    _devices = [d0];
    _activeDeviceId = d0.id;

    _devicesCtrl.add(List.unmodifiable(_devices));
    _activeDeviceCtrl.add(d0);
  }

  static const String _legacyUnconfiguredSeedId = 'UNCONFIGURED';
  static const String _legacyUnconfiguredProfileId = 'unconfigured';

  final Duration tick;
  final int _historyCap;
  final TelemetryLocalStorage _localStorage;
  final TelemetrySupabaseSync _supabaseSync;

  SeedInstall? Function(String deviceId)? _seedResolver;

  final math.Random _rng = math.Random();
  Timer? _timer;

  late List<BioGDevice> _devices;
  String? _activeDeviceId;

  final Map<String, List<BioGTelemetry>> _historyByDevice =
      <String, List<BioGTelemetry>>{};
  final Map<String, List<BioGAlert>> _alertsByDevice =
      <String, List<BioGAlert>>{};
  final Map<String, BioGTelemetry> _lastByDevice = <String, BioGTelemetry>{};
  final Map<String, AlertsState> _alertsStateByDevice = <String, AlertsState>{};
  final Map<String, double> _phaseByDevice = <String, double>{};

  final StreamController<List<BioGDevice>> _devicesCtrl =
      StreamController<List<BioGDevice>>.broadcast();
  final StreamController<BioGDevice?> _activeDeviceCtrl =
      StreamController<BioGDevice?>.broadcast();
  final StreamController<BioGTelemetry?> _liveCtrl =
      StreamController<BioGTelemetry?>.broadcast();
  final StreamController<List<BioGTelemetry>> _historyCtrl =
      StreamController<List<BioGTelemetry>>.broadcast();
  final StreamController<List<BioGAlert>> _alertsCtrl =
      StreamController<List<BioGAlert>>.broadcast();

  bool _started = false;
  int _ticksSinceLastSave = 0;
  int _ticksSinceLastSync = 0;
  bool _savingLocal = false;
  bool _syncingRemote = false;

  /// How many ticks between local saves (~60s at 1s tick).
  static const int _saveEveryNTicks = 60;

  /// How many ticks between Supabase syncs (~120s at 1s tick).
  static const int _syncEveryNTicks = 120;

  void attachSeedResolver(SeedInstall? Function(String deviceId) resolver) {
    _seedResolver = resolver;
  }

  /// Loads persisted history from local storage, falling back to Supabase
  /// if local is empty. Call this before [start].
  Future<void> loadPersistedHistory() async {
    for (final device in _devices) {
      _ensureDeviceState(device.id);

      List<BioGTelemetry> local = await _localStorage.load(device.id);

      if (local.isEmpty) {
        // Fallback: try to recover from Supabase backup.
        local = await _supabaseSync.download(device.id);
        if (local.isNotEmpty) {
          await _localStorage.save(device.id, local);
        }
      }

      if (local.isNotEmpty) {
        _historyByDevice[device.id] = local;
        _lastByDevice[device.id] = local.last;
      }
    }

    _emitActiveDeviceSnapshots();
  }

  void start() {
    if (_started) return;
    _started = true;
    _start();
  }

  bool _paused = false;

  bool get isPaused => _paused;

  void pause() {
    if (!_paused) {
      _paused = true;
      _timer?.cancel();
      _timer = null;
    }
  }

  void resume() {
    if (_paused && _started) {
      _paused = false;
      _timer = Timer.periodic(tick, (_) => _tickAllDevices());
    }
  }

  void _start() {
    for (final d in _devices) {
      _ensureDeviceState(d.id);
    }

    _timer = Timer.periodic(tick, (_) => _tickAllDevices());
    _tickAllDevices();
  }

  void _ensureDeviceState(String deviceId) {
    _historyByDevice.putIfAbsent(deviceId, () => <BioGTelemetry>[]);
    _alertsByDevice.putIfAbsent(deviceId, () => <BioGAlert>[]);
    _alertsStateByDevice.putIfAbsent(deviceId, () => const AlertsState());
    _phaseByDevice.putIfAbsent(deviceId, () => _rng.nextDouble() * math.pi * 2);
  }

  SeedInstall? _seedForDevice(String deviceId) {
    return _seedResolver?.call(deviceId);
  }

  bool _isSkip(SeedInstall seed) => seed.status == SowingStatus.skip;
  bool _isPlanted(SeedInstall seed) => seed.status == SowingStatus.planted;

  String _canonicalCropKey(String? raw) => CropCatalog.canonicalCropKey(raw);

  bool _hasUsableCropKey(SeedInstall? seed) {
    final raw = _canonicalCropKey(seed?.cropKey);
    return raw.isNotEmpty &&
        raw != _legacyUnconfiguredProfileId.toLowerCase() &&
        raw != _legacyUnconfiguredSeedId.toLowerCase();
  }

  CropDefinition? _resolveCropDefinition(BioGDevice device) {
    final seed = _seedForDevice(device.id);
    if (seed == null) return null;
    if (!_hasUsableCropKey(seed)) return null;
    if (_isSkip(seed)) return null;

    final canonicalCropKey = _canonicalCropKey(seed.cropKey);
    if (canonicalCropKey.isEmpty) return null;

    return CropRegistry.byKeyName(canonicalCropKey);
  }

  CropProfile? _resolveCropProfile(BioGDevice device) {
    final seed = _seedForDevice(device.id);
    final definition = _resolveCropDefinition(device);

    if (seed == null || definition == null) return null;
    if (_isSkip(seed)) return null;

    final String canonicalCropKey = _canonicalCropKey(seed.cropKey);
    if (canonicalCropKey.isEmpty) return null;

    final String? resolvedVarietyId = CropCatalog.resolveVarietyId(
      cropId: canonicalCropKey,
      rawValue: seed.varietyAlias,
    );

    final String resolvedProfileId = CropCatalog.resolveProfileId(
      cropId: canonicalCropKey,
      varietyId: resolvedVarietyId,
      explicitProfileId: seed.profileId,
    );

    return definition.resolveProfile(
      profileId: resolvedProfileId,
      varietyAlias: seed.varietyAlias,
    );
  }

  DateTime? _resolveSowingDate(BioGDevice device) {
    final seed = _seedForDevice(device.id);
    if (seed == null) return null;

    if (_isPlanted(seed) && seed.sowingDate != null) {
      return seed.sowingDate;
    }

    return null;
  }

  CropStageResult? _resolveCropStageResult(BioGDevice device, DateTime now) {
    final seed = _seedForDevice(device.id);
    if (seed == null) return null;
    if (!_isPlanted(seed)) return null;

    final definition = _resolveCropDefinition(device);
    final profile = _resolveCropProfile(device);
    final sowingDate = _resolveSowingDate(device);

    if (definition == null || profile == null || sowingDate == null) {
      return null;
    }

    return definition.engine.compute(
      sowingDate: sowingDate,
      today: now,
      profile: profile,
      stressDelayDays: 0,
    );
  }

  StageTargets? _resolveStageTargets(BioGDevice device, DateTime now) {
    final definition = _resolveCropDefinition(device);
    final stage = _resolveCropStageResult(device, now);

    if (definition == null || stage == null) return null;
    return definition.resolveTargets(stage);
  }

  double _ppmCap(NpkNutrient n) {
    switch (n) {
      case NpkNutrient.n:
        return 120.0;
      case NpkNutrient.p:
        return 80.0;
      case NpkNutrient.k:
        return 140.0;
    }
  }

  AgroRange _rangeFor(StageTargets targets, NpkNutrient n) {
    switch (n) {
      case NpkNutrient.n:
        return targets.nIndex;
      case NpkNutrient.p:
        return targets.pIndex;
      case NpkNutrient.k:
        return targets.kIndex;
    }
  }

  double _indexToPpm(NpkNutrient n, double index0to100) {
    final cap = _ppmCap(n);
    return (index0to100.clamp(0.0, 100.0) / 100.0) * cap;
  }

  double _targetPpmForStage(StageTargets targets, NpkNutrient n) {
    final AgroRange r = _rangeFor(targets, n);
    final double midIdx = (r.optimalMin + r.optimalMax) / 2.0;
    return _indexToPpm(n, midIdx);
  }

  double _ampPpmForStage(StageTargets targets, NpkNutrient n) {
    final AgroRange r = _rangeFor(targets, n);

    final double optWidthIdx = (r.optimalMax - r.optimalMin).abs();
    final double optWidthPpm = _indexToPpm(n, optWidthIdx);

    final double base = math.max(3.0, optWidthPpm * 0.18);
    return base.clamp(3.0, 10.0);
  }

  double _smoothToward({
    required double prev,
    required double target,
    required double maxStep,
  }) {
    final double d = target - prev;
    if (d.abs() <= maxStep) return target;
    return prev + d.sign * maxStep;
  }

  double _roundTo(double value, int decimals) {
    final double mod = math.pow(10, decimals).toDouble();
    return (value * mod).roundToDouble() / mod;
  }

  double _boundedDelta({
    required double prev,
    required double next,
    required double maxDelta,
  }) {
    final double delta = next - prev;
    if (delta.abs() <= maxDelta) return next;
    return prev + delta.sign * maxDelta;
  }

  void _tickAllDevices() {
    if (_devices.isEmpty) return;

    final DateTime now = DateTime.now();

    for (final device in _devices) {
      _tickDevice(device, now);
    }

    _emitActiveDeviceSnapshots();

    // Periodic local save.
    _ticksSinceLastSave++;
    if (_ticksSinceLastSave >= _saveEveryNTicks) {
      _ticksSinceLastSave = 0;
      _persistAllLocal();
    }

    // Periodic Supabase sync.
    _ticksSinceLastSync++;
    if (_ticksSinceLastSync >= _syncEveryNTicks) {
      _ticksSinceLastSync = 0;
      _syncAllToSupabase();
    }
  }

  Future<void> _persistAllLocal() async {
    if (_savingLocal) return; // previous save still running
    _savingLocal = true;
    try {
      for (final device in _devices) {
        final hist = _historyByDevice[device.id];
        if (hist != null && hist.isNotEmpty) {
          await _localStorage.save(device.id, hist);
        }
      }
    } finally {
      _savingLocal = false;
    }
  }

  Future<void> _syncAllToSupabase() async {
    if (_syncingRemote) return; // previous sync still running
    _syncingRemote = true;
    try {
      for (final device in _devices) {
        final hist = _historyByDevice[device.id];
        if (hist != null && hist.isNotEmpty) {
          // Upload only the last reading as a single-row sync.
          _supabaseSync.uploadBatch([hist.last]);
        }
      }
    } finally {
      _syncingRemote = false;
    }
  }

  void _tickDevice(BioGDevice device, DateTime now) {
    final String deviceId = device.id;
    _ensureDeviceState(deviceId);

    double noise(double amp) => (_rng.nextDouble() * 2 - 1) * amp;
    double clamp(double v, double a, double b) => v < a ? a : (v > b ? b : v);

    final BioGTelemetry? prev = _lastByDevice[deviceId];

    final double phase = (_phaseByDevice[deviceId] ?? 0.0) + 0.025;
    _phaseByDevice[deviceId] = phase;

    final StageTargets? targets = _resolveStageTargets(device, now);

    final double airTempTarget =
        26.0 + 1.8 * math.sin(phase * 0.35) + noise(0.15);

    final double airHumidityTarget =
        60.0 + 4.5 * math.sin(phase * 0.22 + 1.1) + noise(0.5);

    final double soilTempTarget =
        23.5 + 1.2 * math.sin(phase * 0.28 + 0.8) + noise(0.12);

    final double soilMoistureTarget =
        46.0 + 3.0 * math.sin(phase * 0.16 + 0.5) + noise(0.6);

    final double phTarget = 6.45 + 0.10 * math.sin(phase * 0.08) + noise(0.01);

    final double ecTarget =
        1.25 + 0.12 * math.sin(phase * 0.10 + 0.4) + noise(0.015);

    final double resistanceTarget =
        1.10 + 0.10 * math.sin(phase * 0.12 + 2.0) + noise(0.015);

    final double prevAirT = prev?.airTempC ?? 26.0;
    final double prevAirH = prev?.airHumidityPct ?? 60.0;
    final double prevSoilT = prev?.soilTempC ?? 23.5;
    final double prevSoilM = prev?.soilMoisturePct ?? 46.0;
    final double prevPh = prev?.ph ?? 6.45;
    final double prevEc = prev?.ec ?? 1.25;
    final double prevRes = prev?.resistance ?? 1.10;

    final double airTemp = _boundedDelta(
      prev: prevAirT,
      next: _smoothToward(prev: prevAirT, target: airTempTarget, maxStep: 0.18),
      maxDelta: 0.22,
    );

    final double airHumidity = _boundedDelta(
      prev: prevAirH,
      next: _smoothToward(
        prev: prevAirH,
        target: airHumidityTarget,
        maxStep: 0.7,
      ),
      maxDelta: 0.9,
    );

    final double soilTemp = _boundedDelta(
      prev: prevSoilT,
      next: _smoothToward(
        prev: prevSoilT,
        target: soilTempTarget,
        maxStep: 0.10,
      ),
      maxDelta: 0.14,
    );

    final double soilMoisture = _boundedDelta(
      prev: prevSoilM,
      next: _smoothToward(
        prev: prevSoilM,
        target: soilMoistureTarget,
        maxStep: 0.7,
      ),
      maxDelta: 0.9,
    );

    final double ph = _boundedDelta(
      prev: prevPh,
      next: _smoothToward(prev: prevPh, target: phTarget, maxStep: 0.015),
      maxDelta: 0.02,
    );

    final double ec = _boundedDelta(
      prev: prevEc,
      next: _smoothToward(prev: prevEc, target: ecTarget, maxStep: 0.025),
      maxDelta: 0.03,
    );

    final double resistance = _boundedDelta(
      prev: prevRes,
      next: _smoothToward(
        prev: prevRes,
        target: resistanceTarget,
        maxStep: 0.02,
      ),
      maxDelta: 0.025,
    );

    final double nTarget = targets == null
        ? 60.0
        : _targetPpmForStage(targets, NpkNutrient.n);
    final double pTarget = targets == null
        ? 30.0
        : _targetPpmForStage(targets, NpkNutrient.p);
    final double kTarget = targets == null
        ? 70.0
        : _targetPpmForStage(targets, NpkNutrient.k);

    final double nAmp = targets == null
        ? 3.0
        : (_ampPpmForStage(targets, NpkNutrient.n) * 0.45).clamp(2.0, 5.0);
    final double pAmp = targets == null
        ? 2.0
        : (_ampPpmForStage(targets, NpkNutrient.p) * 0.45).clamp(1.5, 4.0);
    final double kAmp = targets == null
        ? 3.0
        : (_ampPpmForStage(targets, NpkNutrient.k) * 0.45).clamp(2.0, 5.0);

    final double prevN = prev?.n.toDouble() ?? nTarget;
    final double prevP = prev?.p.toDouble() ?? pTarget;
    final double prevK = prev?.k.toDouble() ?? kTarget;

    final double nNext = _boundedDelta(
      prev: prevN,
      next: _smoothToward(
        prev: prevN,
        target: nTarget + math.sin(phase * 0.07) * nAmp + noise(nAmp * 0.12),
        maxStep: 0.8,
      ),
      maxDelta: 1.0,
    );

    final double pNext = _boundedDelta(
      prev: prevP,
      next: _smoothToward(
        prev: prevP,
        target:
            pTarget + math.sin(phase * 0.065 + 0.6) * pAmp + noise(pAmp * 0.12),
        maxStep: 0.55,
      ),
      maxDelta: 0.7,
    );

    final double kNext = _boundedDelta(
      prev: prevK,
      next: _smoothToward(
        prev: prevK,
        target:
            kTarget + math.sin(phase * 0.075 + 1.7) * kAmp + noise(kAmp * 0.12),
        maxStep: 0.9,
      ),
      maxDelta: 1.1,
    );

    final double battery = clamp(
      (prev?.batteryPct ?? 96.0) - 0.01 + noise(0.005),
      20,
      100,
    );

    final int rssi = ((prev?.signalRssi ?? -55) + noise(1.0).round()).clamp(
      -75,
      -40,
    );

    final BioGTelemetry t = BioGTelemetry(
      deviceId: deviceId,
      timestamp: now,
      airTempC: _roundTo(clamp(airTemp, 18, 34), 1),
      airHumidityPct: _roundTo(clamp(airHumidity, 35, 80), 1),
      soilMoisturePct: _roundTo(clamp(soilMoisture, 25, 65), 1),
      soilTempC: _roundTo(clamp(soilTemp, 16, 30), 1),
      ph: _roundTo(clamp(ph, 5.8, 7.2), 2),
      ec: _roundTo(clamp(ec, 0.8, 2.0), 2),
      resistance: _roundTo(clamp(resistance, 0.7, 1.8), 2),
      n: _roundTo(clamp(nNext, 8, 120), 1),
      p: _roundTo(clamp(pNext, 4, 80), 1),
      k: _roundTo(clamp(kNext, 8, 140), 1),
      batteryPct: _roundTo(battery, 1),
      signalRssi: rssi,
    );

    _lastByDevice[deviceId] = t;

    final List<BioGTelemetry> hist = _historyByDevice.putIfAbsent(
      deviceId,
      () => <BioGTelemetry>[],
    );
    hist.add(t);

    if (hist.length > _historyCap) {
      hist.removeRange(0, hist.length - _historyCap);
    }

    _emitAgroAlerts(deviceId: deviceId, t: t, today: now);
  }

  void _emitActiveDeviceSnapshots() {
    final String? activeId = _activeDeviceId;
    if (activeId == null) return;

    _liveCtrl.add(_lastByDevice[activeId]);

    _historyCtrl.add(
      List<BioGTelemetry>.unmodifiable(
        _historyByDevice[activeId] ?? const <BioGTelemetry>[],
      ),
    );

    _alertsCtrl.add(
      List<BioGAlert>.unmodifiable(
        _alertsByDevice[activeId] ?? const <BioGAlert>[],
      ),
    );
  }

  void _emitAgroAlerts({
    required String deviceId,
    required BioGTelemetry t,
    required DateTime today,
  }) {
    final BioGDevice? device = _devices.cast<BioGDevice?>().firstWhere(
      (d) => d?.id == deviceId,
      orElse: () => null,
    );
    if (device == null) return;

    final CropDefinition? definition = _resolveCropDefinition(device);
    final CropProfile? profile = _resolveCropProfile(device);
    final CropStageResult? stage = _resolveCropStageResult(device, today);
    final StageTargets? targets = _resolveStageTargets(device, today);

    if (definition == null || profile == null || stage == null) return;

    final AlertsState prevState =
        _alertsStateByDevice[deviceId] ?? const AlertsState();

    final out = definition.evaluateTelemetry(
      telemetry: t,
      stage: stage,
      profile: profile,
      targetsOverride: targets,
      alertsState: prevState,
    );

    _alertsStateByDevice[deviceId] = out.nextAlertsState;

    final List<BioGAlert> newAlerts = out.eval.alerts;
    if (newAlerts.isEmpty) return;

    final List<BioGAlert> list = _alertsByDevice.putIfAbsent(
      deviceId,
      () => <BioGAlert>[],
    );

    for (final a in newAlerts) {
      final bool exists = list.any((x) => x.id == a.id);
      if (!exists) {
        list.insert(0, a);
      }
    }

    if (list.length > 200) {
      list.removeRange(200, list.length);
    }
  }

  @override
  Stream<List<BioGDevice>> watchDevices() async* {
    yield List<BioGDevice>.unmodifiable(_devices);
    yield* _devicesCtrl.stream;
  }

  @override
  Stream<BioGDevice?> watchActiveDevice() async* {
    final List<BioGDevice> active = _devices
        .where((d) => d.id == _activeDeviceId)
        .toList();
    yield active.isEmpty ? null : active.first;
    yield* _activeDeviceCtrl.stream;
  }

  @override
  Stream<BioGTelemetry?> watchLiveTelemetry() async* {
    final String? activeId = _activeDeviceId;
    yield activeId == null ? null : _lastByDevice[activeId];
    yield* _liveCtrl.stream;
  }

  @override
  Stream<List<BioGTelemetry>> watchHistory({required Duration window}) async* {
    final String? activeId = _activeDeviceId;
    if (activeId == null) {
      yield const <BioGTelemetry>[];
    } else {
      final DateTime cutoff = DateTime.now().subtract(window);
      final List<BioGTelemetry> current =
          _historyByDevice[activeId] ?? const <BioGTelemetry>[];
      yield current
          .where((e) => e.timestamp.isAfter(cutoff))
          .toList(growable: false);
    }

    await for (final list in _historyCtrl.stream) {
      final DateTime cutoff = DateTime.now().subtract(window);
      yield list
          .where((e) => e.timestamp.isAfter(cutoff))
          .toList(growable: false);
    }
  }

  @override
  Stream<List<BioGAlert>> watchAlerts({int limit = 50}) async* {
    final String? activeId = _activeDeviceId;
    if (activeId == null) {
      yield const <BioGAlert>[];
    } else {
      final List<BioGAlert> current =
          _alertsByDevice[activeId] ?? const <BioGAlert>[];
      yield current.take(limit).toList(growable: false);
    }

    await for (final list in _alertsCtrl.stream) {
      yield list.take(limit).toList(growable: false);
    }
  }

  @override
  Future<void> setActiveDevice(String deviceId) async {
    final List<BioGDevice> found = _devices
        .where((d) => d.id == deviceId)
        .toList();
    if (found.isEmpty) return;

    _activeDeviceId = deviceId;
    _activeDeviceCtrl.add(found.first);
    _emitActiveDeviceSnapshots();
  }

  @override
  Future<BioGDevice> addFakeDevice({
    String? seedId,
    String? profileId,
    String? locationName,
    String? name,
  }) async {
    final int nextIndex = _devices.length + 1;
    final String id = 'BIOG-DEMO-${nextIndex.toString().padLeft(3, '0')}';

    final BioGDevice d = BioGDevice(
      id: id,
      name: name ?? 'BioG $nextIndex',
      locationName: locationName ?? 'Parcela $nextIndex',
      seedId: seedId ?? _legacyUnconfiguredSeedId,
      profileId: profileId ?? _legacyUnconfiguredProfileId,
      status: BioGDeviceStatus.active,
      createdAt: DateTime.now().subtract(Duration(days: 20 + _rng.nextInt(25))),
    );

    _devices = <BioGDevice>[..._devices, d];
    _ensureDeviceState(d.id);

    _devicesCtrl.add(List<BioGDevice>.unmodifiable(_devices));
    await setActiveDevice(d.id);
    return d;
  }

  @override
  Future<void> removeDevice(String deviceId) async {
    if (_devices.length <= 1) return;

    _devices = _devices.where((d) => d.id != deviceId).toList(growable: false);

    _historyByDevice.remove(deviceId);
    _alertsByDevice.remove(deviceId);
    _lastByDevice.remove(deviceId);
    _alertsStateByDevice.remove(deviceId);
    _phaseByDevice.remove(deviceId);

    _localStorage.delete(deviceId);
    _supabaseSync.delete(deviceId);

    if (_activeDeviceId == deviceId) {
      _activeDeviceId = _devices.first.id;
      _activeDeviceCtrl.add(_devices.first);
    }

    _devicesCtrl.add(List<BioGDevice>.unmodifiable(_devices));
    _emitActiveDeviceSnapshots();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Final save before shutdown.
    _persistAllLocal();
    _syncAllToSupabase();
    _devicesCtrl.close();
    _activeDeviceCtrl.close();
    _liveCtrl.close();
    _historyCtrl.close();
    _alertsCtrl.close();
  }
}
