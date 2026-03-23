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

enum NpkNutrient { n, p, k }

class FakeBioGRepository implements BioGRepository {
  FakeBioGRepository({
    this.tick = const Duration(seconds: 2),
    int historyCap = 2000,
    SeedInstall? Function(String deviceId)? seedResolver,
  }) : _historyCap = historyCap,
       _seedResolver = seedResolver {
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

  void attachSeedResolver(SeedInstall? Function(String deviceId) resolver) {
    _seedResolver = resolver;
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

  void _tickAllDevices() {
    if (_devices.isEmpty) return;

    final DateTime now = DateTime.now();

    for (final device in _devices) {
      _tickDevice(device, now);
    }

    _emitActiveDeviceSnapshots();
  }

  void _tickDevice(BioGDevice device, DateTime now) {
    final String deviceId = device.id;
    _ensureDeviceState(deviceId);

    double noise(double amp) => (_rng.nextDouble() * 2 - 1) * amp;
    double clamp(double v, double a, double b) => v < a ? a : (v > b ? b : v);

    final BioGTelemetry? prev = _lastByDevice[deviceId];

    final double phase = (_phaseByDevice[deviceId] ?? 0.0) + 0.12;
    _phaseByDevice[deviceId] = phase;

    final StageTargets? targets = _resolveStageTargets(device, now);

    final double baseAirT = 26 + 3 * math.sin(phase * 0.6) + noise(0.4);
    final double baseAirH = 58 + 8 * math.sin(phase * 0.35 + 1.1) + noise(1.2);

    final double baseSoilT = 24 + 2 * math.sin(phase * 0.5 + 0.8) + noise(0.3);
    final double baseSoilM =
        (prev?.soilMoisturePct ?? (45 + 6 * math.sin(phase * 0.25))) +
        noise(1.4);

    final double basePh =
        (prev?.ph ?? (6.4 + 0.25 * math.sin(phase * 0.12))) + noise(0.03);
    final double baseEc =
        (prev?.ec ?? (1.3 + 0.35 * math.sin(phase * 0.15 + 0.4))) + noise(0.04);

    final double baseResMpa =
        (prev?.resistance ?? (1.10 + 0.25 * math.sin(phase * 0.18 + 2.0))) +
        noise(0.05);

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
        ? 6.0
        : _ampPpmForStage(targets, NpkNutrient.n);
    final double pAmp = targets == null
        ? 4.0
        : _ampPpmForStage(targets, NpkNutrient.p);
    final double kAmp = targets == null
        ? 6.0
        : _ampPpmForStage(targets, NpkNutrient.k);

    final double prevN = prev?.n.toDouble() ?? (nTarget + noise(nAmp));
    final double prevP = prev?.p.toDouble() ?? (pTarget + noise(pAmp));
    final double prevK = prev?.k.toDouble() ?? (kTarget + noise(kAmp));

    final double nNext =
        _smoothToward(
          prev: prevN,
          target:
              nTarget +
              math.sin(phase * 0.10) * (nAmp * 0.9) +
              noise(nAmp * 0.35),
          maxStep: 1.6,
        ) +
        noise(0.25);

    final double pNext =
        _smoothToward(
          prev: prevP,
          target:
              pTarget +
              math.sin(phase * 0.09 + 0.6) * (pAmp * 0.9) +
              noise(pAmp * 0.35),
          maxStep: 1.0,
        ) +
        noise(0.18);

    final double kNext =
        _smoothToward(
          prev: prevK,
          target:
              kTarget +
              math.sin(phase * 0.11 + 1.7) * (kAmp * 0.9) +
              noise(kAmp * 0.35),
          maxStep: 1.8,
        ) +
        noise(0.25);

    final double battery = clamp(
      (prev?.batteryPct ?? 96.0) - 0.03 + noise(0.02),
      10,
      100,
    );
    final int rssi = ((prev?.signalRssi ?? -55) + noise(2.0).round()).clamp(
      -95,
      -35,
    );

    final BioGTelemetry t = BioGTelemetry(
      deviceId: deviceId,
      timestamp: now,
      airTempC: clamp(baseAirT, 10, 45),
      airHumidityPct: clamp(baseAirH, 10, 100),
      soilMoisturePct: clamp(baseSoilM, 5, 85),
      soilTempC: clamp(baseSoilT, 8, 40),
      ph: clamp(basePh, 4.5, 8.8),
      ec: clamp(baseEc, 0.4, 3.2),
      resistance: clamp(baseResMpa, 0.20, 2.80),
      n: clamp(nNext, 5, 120),
      p: clamp(pNext, 2, 80),
      k: clamp(kNext, 5, 140),
      batteryPct: battery,
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
    _devicesCtrl.close();
    _activeDeviceCtrl.close();
    _liveCtrl.close();
    _historyCtrl.close();
    _alertsCtrl.close();
  }
}
