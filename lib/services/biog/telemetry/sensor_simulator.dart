import 'dart:async';
import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrient_target_range_resolver.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/seed_install.dart';

enum _NpkNutrient { n, p, k }

/// Temporary, sensor-only simulation of BioG hardware.
///
/// This class is the ONLY component in the runtime that still fabricates
/// data. It does not own devices, identity, active-device state, or any
/// persistence — it merely generates a live stream (and a short in-memory
/// window of history + derived alerts) for whichever [BioGDevice] ids it
/// has been told to track.
///
/// When real hardware arrives, this class is the single replacement
/// point: swap it for a driver that listens to the device radio and
/// the rest of the app keeps working.
class SensorSimulator {
  SensorSimulator({
    Duration tick = const Duration(seconds: 1),
    int historyCap = 2000,
  })  : _tick = tick,
        _historyCap = historyCap;

  static const String _legacyUnconfiguredSeedId = 'UNCONFIGURED';
  static const String _legacyUnconfiguredProfileId = 'unconfigured';

  final Duration _tick;
  final int _historyCap;
  final math.Random _rng = math.Random();

  Timer? _timer;
  bool _started = false;
  bool _paused = false;

  /// Devices currently being simulated, by id.
  final Map<String, BioGDevice> _devicesById = <String, BioGDevice>{};

  /// Last telemetry value for each device.
  final Map<String, BioGTelemetry> _lastByDevice = <String, BioGTelemetry>{};

  /// Rolling, in-memory history per device (capped).
  final Map<String, List<BioGTelemetry>> _historyByDevice =
      <String, List<BioGTelemetry>>{};

  /// In-memory alerts per device (capped).
  final Map<String, List<BioGAlert>> _alertsByDevice =
      <String, List<BioGAlert>>{};

  /// Per-device agronomic alert state (needed by the alerts engine).
  final Map<String, AlertsState> _alertsStateByDevice = <String, AlertsState>{};

  /// Per-device sinusoidal phase, for stable but non-identical signals.
  final Map<String, double> _phaseByDevice = <String, double>{};

  /// Optional resolver the caller uses to hand us the agronomic
  /// [SeedInstall] for a given device id, without coupling us to the
  /// store or to Supabase.
  SeedInstall? Function(String deviceId)? _seedResolver;

  // ---- Broadcast streams -----------------------------------------------------

  final Map<String, StreamController<BioGTelemetry?>> _liveCtrlByDevice =
      <String, StreamController<BioGTelemetry?>>{};
  final Map<String, StreamController<List<BioGTelemetry>>>
      _historyCtrlByDevice =
      <String, StreamController<List<BioGTelemetry>>>{};
  final Map<String, StreamController<List<BioGAlert>>> _alertsCtrlByDevice =
      <String, StreamController<List<BioGAlert>>>{};

  bool get isPaused => _paused;
  bool get isStarted => _started;

  /// Replace the set of devices currently being simulated. Devices not
  /// present in [devices] are cleanly torn down; new ones get fresh
  /// per-device state initialized.
  void configureDevices(List<BioGDevice> devices) {
    final Set<String> wantedIds = devices.map((d) => d.id).toSet();

    // Remove devices no longer present.
    final toRemove = _devicesById.keys
        .where((id) => !wantedIds.contains(id))
        .toList(growable: false);
    for (final id in toRemove) {
      _removeDeviceState(id);
    }

    // Ensure state exists for each new/kept device.
    for (final d in devices) {
      _devicesById[d.id] = d;
      _ensureDeviceState(d.id);
    }
  }

  void attachSeedResolver(SeedInstall? Function(String deviceId) resolver) {
    _seedResolver = resolver;
  }

  void start() {
    if (_started) return;
    _started = true;
    _timer = Timer.periodic(_tick, (_) => _tickAllDevices());
    _tickAllDevices();
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    if (!_paused || !_started) return;
    _paused = false;
    _timer = Timer.periodic(_tick, (_) => _tickAllDevices());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _started = false;

    for (final c in _liveCtrlByDevice.values) {
      c.close();
    }
    for (final c in _historyCtrlByDevice.values) {
      c.close();
    }
    for (final c in _alertsCtrlByDevice.values) {
      c.close();
    }

    _liveCtrlByDevice.clear();
    _historyCtrlByDevice.clear();
    _alertsCtrlByDevice.clear();
    _devicesById.clear();
    _historyByDevice.clear();
    _alertsByDevice.clear();
    _lastByDevice.clear();
    _alertsStateByDevice.clear();
    _phaseByDevice.clear();
  }

  // ---- Per-device streams ----------------------------------------------------

  Stream<BioGTelemetry?> watchLive(String deviceId) async* {
    _ensureDeviceState(deviceId);
    final ctrl = _liveCtrlByDevice.putIfAbsent(
      deviceId,
      () => StreamController<BioGTelemetry?>.broadcast(),
    );
    yield _lastByDevice[deviceId];
    yield* ctrl.stream;
  }

  Stream<List<BioGTelemetry>> watchHistory(
    String deviceId, {
    required Duration window,
  }) async* {
    _ensureDeviceState(deviceId);
    final ctrl = _historyCtrlByDevice.putIfAbsent(
      deviceId,
      () => StreamController<List<BioGTelemetry>>.broadcast(),
    );

    List<BioGTelemetry> slice() {
      final cutoff = DateTime.now().subtract(window);
      final current =
          _historyByDevice[deviceId] ?? const <BioGTelemetry>[];
      return current
          .where((e) => e.timestamp.isAfter(cutoff))
          .toList(growable: false);
    }

    yield slice();

    await for (final _ in ctrl.stream) {
      yield slice();
    }
  }

  Stream<List<BioGAlert>> watchAlerts(String deviceId, {int limit = 50}) async* {
    _ensureDeviceState(deviceId);
    final ctrl = _alertsCtrlByDevice.putIfAbsent(
      deviceId,
      () => StreamController<List<BioGAlert>>.broadcast(),
    );

    List<BioGAlert> slice() {
      final list = _alertsByDevice[deviceId] ?? const <BioGAlert>[];
      return list.take(limit).toList(growable: false);
    }

    yield slice();

    await for (final _ in ctrl.stream) {
      yield slice();
    }
  }

  /// Drop all simulated state for a single device (used on removal).
  void forgetDevice(String deviceId) => _removeDeviceState(deviceId);

  // ---- Internals -------------------------------------------------------------

  void _ensureDeviceState(String deviceId) {
    _historyByDevice.putIfAbsent(deviceId, () => <BioGTelemetry>[]);
    _alertsByDevice.putIfAbsent(deviceId, () => <BioGAlert>[]);
    _alertsStateByDevice.putIfAbsent(deviceId, () => const AlertsState());
    _phaseByDevice.putIfAbsent(
      deviceId,
      () => _rng.nextDouble() * math.pi * 2,
    );
  }

  void _removeDeviceState(String deviceId) {
    _devicesById.remove(deviceId);
    _historyByDevice.remove(deviceId);
    _alertsByDevice.remove(deviceId);
    _lastByDevice.remove(deviceId);
    _alertsStateByDevice.remove(deviceId);
    _phaseByDevice.remove(deviceId);

    _liveCtrlByDevice.remove(deviceId)?.close();
    _historyCtrlByDevice.remove(deviceId)?.close();
    _alertsCtrlByDevice.remove(deviceId)?.close();
  }

  void _tickAllDevices() {
    if (_devicesById.isEmpty) return;
    final DateTime now = DateTime.now();
    for (final device in _devicesById.values) {
      _tickDevice(device, now);
    }
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

  AgroMetricKey _metricKeyFor(_NpkNutrient n) {
    switch (n) {
      case _NpkNutrient.n:
        return AgroMetricKey.n;
      case _NpkNutrient.p:
        return AgroMetricKey.p;
      case _NpkNutrient.k:
        return AgroMetricKey.k;
    }
  }

  String? _resolvedCropKeyForDevice(BioGDevice device) {
    final SeedInstall? seed = _seedForDevice(device.id);
    if (seed == null) return null;
    final String cropKey = _canonicalCropKey(seed.cropKey);
    return cropKey.isEmpty ? null : cropKey;
  }

  double _targetPpmForStage(
    StageTargets targets,
    _NpkNutrient n, {
    required String? cropKey,
  }) {
    final AgroRange? r = NutrientTargetRangeResolver.comparableRange(
      nutrient: _metricKeyFor(n),
      cropKey: cropKey,
      targets: targets,
    );
    if (r == null) return 0.0;
    return (r.optimalMin + r.optimalMax) / 2.0;
  }

  double _ampPpmForStage(
    StageTargets targets,
    _NpkNutrient n, {
    required String? cropKey,
  }) {
    final AgroRange? r = NutrientTargetRangeResolver.comparableRange(
      nutrient: _metricKeyFor(n),
      cropKey: cropKey,
      targets: targets,
    );
    if (r == null) return 3.0;
    final double optWidthPpm = (r.optimalMax - r.optimalMin).abs();
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

  void _tickDevice(BioGDevice device, DateTime now) {
    final String deviceId = device.id;
    _ensureDeviceState(deviceId);

    double noise(double amp) => (_rng.nextDouble() * 2 - 1) * amp;
    double clamp(double v, double a, double b) =>
        v < a ? a : (v > b ? b : v);

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
      next: _smoothToward(
        prev: prevAirT,
        target: airTempTarget,
        maxStep: 0.18,
      ),
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

    final String? cropKey = _resolvedCropKeyForDevice(device);

    final double nTarget = targets == null
        ? 60.0
        : _targetPpmForStage(
            targets,
            _NpkNutrient.n,
            cropKey: cropKey,
          );
    final double pTarget = targets == null
        ? 30.0
        : _targetPpmForStage(
            targets,
            _NpkNutrient.p,
            cropKey: cropKey,
          );
    final double kTarget = targets == null
        ? 70.0
        : _targetPpmForStage(
            targets,
            _NpkNutrient.k,
            cropKey: cropKey,
          );

    final double nAmp = targets == null
        ? 3.0
        : (_ampPpmForStage(
                    targets,
                    _NpkNutrient.n,
                    cropKey: cropKey,
                  ) *
                  0.45)
              .clamp(2.0, 5.0);
    final double pAmp = targets == null
        ? 2.0
        : (_ampPpmForStage(
                    targets,
                    _NpkNutrient.p,
                    cropKey: cropKey,
                  ) *
                  0.45)
              .clamp(1.5, 4.0);
    final double kAmp = targets == null
        ? 3.0
        : (_ampPpmForStage(
                    targets,
                    _NpkNutrient.k,
                    cropKey: cropKey,
                  ) *
                  0.45)
              .clamp(2.0, 5.0);

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
        target: pTarget +
            math.sin(phase * 0.065 + 0.6) * pAmp +
            noise(pAmp * 0.12),
        maxStep: 0.55,
      ),
      maxDelta: 0.7,
    );

    final double kNext = _boundedDelta(
      prev: prevK,
      next: _smoothToward(
        prev: prevK,
        target: kTarget +
            math.sin(phase * 0.075 + 1.7) * kAmp +
            noise(kAmp * 0.12),
        maxStep: 0.9,
      ),
      maxDelta: 1.1,
    );

    final double battery = clamp(
      (prev?.batteryPct ?? 96.0) - 0.01 + noise(0.005),
      20,
      100,
    );

    final int rssi =
        ((prev?.signalRssi ?? -55) + noise(1.0).round()).clamp(-75, -40);

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

    _liveCtrlByDevice[deviceId]?.add(t);
    _historyCtrlByDevice[deviceId]?.add(
      List<BioGTelemetry>.unmodifiable(hist),
    );

    _emitAgroAlerts(deviceId: deviceId, device: device, t: t, today: now);
  }

  void _emitAgroAlerts({
    required String deviceId,
    required BioGDevice device,
    required BioGTelemetry t,
    required DateTime today,
  }) {
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

    bool changed = false;
    for (final a in newAlerts) {
      final bool exists = list.any((x) => x.id == a.id);
      if (!exists) {
        list.insert(0, a);
        changed = true;
      }
    }

    if (list.length > 200) {
      list.removeRange(200, list.length);
    }

    if (changed) {
      _alertsCtrlByDevice[deviceId]?.add(List<BioGAlert>.unmodifiable(list));
    }
  }
}
