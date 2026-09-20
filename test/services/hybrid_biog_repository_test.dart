import 'dart:async';

import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/services/biog/hybrid_biog_repository.dart';
import 'package:bio_g/services/biog/identity/device_identity_repository.dart';
import 'package:bio_g/services/biog/telemetry/telemetry_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HybridBioGRepository late subscribers', () {
    test('watchHistory attaches to the already-active device', () async {
      final device = _testDevice(id: '11111111-1111-4111-8111-111111111111');
      final identity = _FakeDeviceIdentityRepository(
        devices: <BioGDevice>[device],
        activeDeviceId: device.id,
      );

      final repo = HybridBioGRepository(
        identity: identity,
        telemetrySource: _FakeTelemetrySource(<BioGTelemetry>[
          _sample(device.id, ago: const Duration(hours: 2)),
          _sample(device.id),
        ]),
      );
      addTearDown(repo.dispose);

      await repo.bindUser(userId: 'user-001');

      final history = await repo
          .watchHistory(window: const Duration(days: 7))
          .firstWhere((samples) => samples.isNotEmpty)
          .timeout(const Duration(seconds: 2));

      expect(history, isNotEmpty);
      expect(history.every((sample) => sample.deviceId == device.id), isTrue);
    });

    test('watchLiveTelemetry emits for the already-active device', () async {
      final device = _testDevice(id: '22222222-2222-4222-8222-222222222222');
      final identity = _FakeDeviceIdentityRepository(
        devices: <BioGDevice>[device],
        activeDeviceId: device.id,
      );

      final repo = HybridBioGRepository(
        identity: identity,
        telemetrySource: _FakeTelemetrySource(<BioGTelemetry>[
          _sample(device.id, ago: const Duration(hours: 2)),
          _sample(device.id),
        ]),
      );
      addTearDown(repo.dispose);

      await repo.bindUser(userId: 'user-002');

      final live = await repo
          .watchLiveTelemetry()
          .firstWhere((sample) => sample != null)
          .timeout(const Duration(seconds: 2));

      expect(live, isNotNull);
      expect(live!.deviceId, device.id);
    });

    test(
      'A -> B -> A clears immediately and never forwards the other device',
      () async {
        const aId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
        const bId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
        final identity = _FakeDeviceIdentityRepository(
          devices: <BioGDevice>[
            _testDevice(id: aId),
            _testDevice(id: bId),
          ],
          activeDeviceId: aId,
        );
        final telemetry = _PushTelemetrySource();
        final repo = HybridBioGRepository(
          identity: identity,
          telemetrySource: telemetry,
        );
        addTearDown(repo.dispose);
        await repo.bindUser(userId: 'user-switch');

        final events = <BioGTelemetry?>[];
        final sub = repo.watchLiveTelemetry().listen(events.add);
        addTearDown(sub.cancel);

        telemetry.emit(_sample(aId, n: 34, p: 18, k: 27));
        await _waitUntil(() => events.any((sample) => sample?.n == 34));
        expect(events.last?.deviceId, aId);

        await repo.setActiveDevice(bId);
        await _waitUntil(() => events.isNotEmpty && events.last == null);
        telemetry.emit(_sample(aId, n: 35, p: 19, k: 28));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(events.last, isNull);

        telemetry.emit(_sample(bId, n: 12, p: 6, k: 18));
        await _waitUntil(() => events.last?.deviceId == bId);
        expect((events.last!.n, events.last!.p, events.last!.k), (12, 6, 18));

        await repo.setActiveDevice(aId);
        await _waitUntil(() => events.last == null);
        telemetry.emit(_sample(bId, n: 13, p: 7, k: 19));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(events.last, isNull);

        telemetry.emit(_sample(aId, n: 34, p: 18, k: 27));
        await _waitUntil(() => events.last?.deviceId == aId);
        expect((events.last!.n, events.last!.p, events.last!.k), (34, 18, 27));
      },
    );

    test(
      'removing the last device leaves the valid zero-device state',
      () async {
        const id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
        final identity = _FakeDeviceIdentityRepository(
          devices: <BioGDevice>[_testDevice(id: id)],
          activeDeviceId: id,
        );
        final telemetry = _PushTelemetrySource();
        final repo = HybridBioGRepository(
          identity: identity,
          telemetrySource: telemetry,
        );
        addTearDown(repo.dispose);
        await repo.bindUser(userId: 'user-zero');

        final deviceLists = <List<BioGDevice>>[];
        final activeDevices = <BioGDevice?>[];
        final live = <BioGTelemetry?>[];
        final deviceSub = repo.watchDevices().listen(deviceLists.add);
        final activeSub = repo.watchActiveDevice().listen(activeDevices.add);
        final liveSub = repo.watchLiveTelemetry().listen(live.add);
        addTearDown(deviceSub.cancel);
        addTearDown(activeSub.cancel);
        addTearDown(liveSub.cancel);

        telemetry.emit(_sample(id, n: 34, p: 18, k: 27));
        await _waitUntil(() => live.any((sample) => sample != null));
        await repo.removeDevice(id);
        await _waitUntil(
          () =>
              deviceLists.isNotEmpty &&
              deviceLists.last.isEmpty &&
              activeDevices.isNotEmpty &&
              activeDevices.last == null &&
              live.last == null,
        );

        expect(identity.cachedDevices(userId: 'user-zero'), isEmpty);
        expect(identity.cachedActiveDeviceId(), isNull);
        expect(repo.activeDeviceId, isNull);
        expect(telemetry.forgottenDeviceIds, contains(id));
      },
    );

    test(
      'a late active-selection write cannot resurrect a removed device',
      () async {
        const id = 'ffffffff-ffff-4fff-8fff-ffffffffffff';
        final identity = _FakeDeviceIdentityRepository(
          devices: <BioGDevice>[_testDevice(id: id)],
          activeDeviceId: id,
        );
        final repo = HybridBioGRepository(
          identity: identity,
          telemetrySource: _PushTelemetrySource(),
        );
        addTearDown(repo.dispose);
        await repo.bindUser(userId: 'user-remove-race');

        final delayedWrite = Completer<void>();
        identity.nextSetActiveGate = delayedWrite;
        final selection = repo.setActiveDevice(id);
        await Future<void>.delayed(Duration.zero);

        await repo.removeDevice(id);
        delayedWrite.complete();
        await selection;

        expect(identity.cachedDevices(userId: 'user-remove-race'), isEmpty);
        expect(identity.cachedActiveDeviceId(), isNull);
        expect(repo.activeDeviceId, isNull);
      },
    );

    test('explicit Bluetooth add selects the new physical BIO-G', () async {
      const aId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
      const bId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
      final identity = _FakeDeviceIdentityRepository(
        devices: <BioGDevice>[_testDevice(id: aId)],
        activeDeviceId: aId,
      );
      final repo = HybridBioGRepository(
        identity: identity,
        telemetrySource: _PushTelemetrySource(),
      );
      addTearDown(repo.dispose);
      await repo.bindUser(userId: 'user-add');

      final added = await repo.addDevice(
        hardwareDeviceId: bId,
        name: 'BIO-G físico',
        locationName: 'Parcela B',
      );

      expect(added.id, bId);
      expect(added.telemetryDeviceId, bId);
      expect(repo.activeDeviceId, bId);
      expect(identity.cachedActiveDeviceId(), bId);
    });
  });
}

BioGDevice _testDevice({required String id}) {
  final now = DateTime.now();
  return BioGDevice(
    id: id,
    name: 'BioG Test',
    locationName: 'Parcela Test',
    seedId: 'UNCONFIGURED',
    profileId: 'unconfigured',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeDeviceIdentityRepository implements DeviceIdentityRepository {
  _FakeDeviceIdentityRepository({
    required List<BioGDevice> devices,
    required String? activeDeviceId,
  }) : _devices = List<BioGDevice>.from(devices),
       _activeDeviceId = activeDeviceId;

  List<BioGDevice> _devices;
  String? _activeDeviceId;
  Completer<void>? nextSetActiveGate;

  @override
  List<BioGDevice> cachedDevices({String? userId}) {
    return List<BioGDevice>.from(_devices);
  }

  @override
  String? cachedActiveDeviceId() => _activeDeviceId;

  @override
  void clearInMemory() {}

  @override
  Future<void> clearActiveDeviceId({required String? userId}) async {
    _activeDeviceId = null;
  }

  @override
  Future<List<BioGDevice>> loadDevices({required String? userId}) async {
    return List<BioGDevice>.from(_devices);
  }

  @override
  Future<void> removeDevice({
    required String? userId,
    required String deviceId,
  }) async {
    _devices = _devices.where((device) => device.id != deviceId).toList();
    if (_activeDeviceId == deviceId) {
      _activeDeviceId = _devices.isEmpty ? null : _devices.first.id;
    }
  }

  @override
  Future<void> setActiveDeviceId({
    required String? userId,
    required String deviceId,
  }) async {
    final gate = nextSetActiveGate;
    nextSetActiveGate = null;
    await gate?.future;
    _activeDeviceId = deviceId;
  }

  @override
  Future<BioGDevice> upsertDevice({
    required String? userId,
    required BioGDevice device,
  }) async {
    _devices = <BioGDevice>[
      ..._devices.where((existing) => existing.id != device.id),
      device,
    ];
    return device;
  }
}

/// Lectura de prueba, plausible y atada a un dispositivo concreto.
BioGTelemetry _sample(
  String deviceId, {
  Duration ago = Duration.zero,
  double n = 60,
  double p = 30,
  double k = 70,
}) {
  return BioGTelemetry(
    deviceId: deviceId,
    timestamp: DateTime.now().subtract(ago),
    airTempC: 24.5,
    airHumidityPct: 61.0,
    soilMoisturePct: 45.0,
    soilTempC: 22.0,
    ph: 6.4,
    ec: 1.2,
    resistance: 1.1,
    n: n,
    p: p,
    k: k,
    batteryPct: 96.0,
    signalRssi: -55,
  );
}

/// Doble de la fuente de telemetría.
///
/// La causa real es que sin `telemetrySource` el repositorio construye un
/// `OfflineFirstTelemetrySource`, que necesita sqflite (plugin de plataforma,
/// inexistente en `flutter test`) y una instancia de Supabase inicializada.
/// Ambos fallan, el error se traga, y el stream solo emite lista vacía o null.
///
/// Los ids también se cambiaron a UUID: `_migrateLegacyDeviceIds` reemplaza
/// cualquier id heredado por uno nuevo, así que `device-001` ni siquiera
/// existía ya cuando la prueba comparaba contra él.
class _FakeTelemetrySource implements TelemetrySource {
  _FakeTelemetrySource(this.samples);

  final List<BioGTelemetry> samples;

  List<BioGTelemetry> _forDevice(String deviceId) {
    return samples
        .where((BioGTelemetry s) => s.deviceId == deviceId)
        .toList(growable: false);
  }

  @override
  Stream<BioGTelemetry?> watchLive(String deviceId) {
    final List<BioGTelemetry> matches = _forDevice(deviceId);
    return Stream<BioGTelemetry?>.value(matches.isEmpty ? null : matches.last);
  }

  @override
  Stream<List<BioGTelemetry>> watchHistory(
    String deviceId, {
    required Duration? window,
  }) {
    return Stream<List<BioGTelemetry>>.value(_forDevice(deviceId));
  }

  @override
  Future<void> refresh(
    String deviceId, {
    Duration? window = const Duration(days: 7),
  }) async {}

  @override
  Future<void> forgetDevice(String deviceId) async {}

  @override
  void dispose() {}
}

class _PushTelemetrySource implements TelemetrySource {
  final Map<String, StreamController<BioGTelemetry?>> _live =
      <String, StreamController<BioGTelemetry?>>{};
  final Map<String, StreamController<List<BioGTelemetry>>> _history =
      <String, StreamController<List<BioGTelemetry>>>{};
  final Set<String> forgottenDeviceIds = <String>{};

  void emit(BioGTelemetry sample) {
    _live
        .putIfAbsent(
          sample.deviceId,
          () => StreamController<BioGTelemetry?>.broadcast(),
        )
        .add(sample);
  }

  @override
  Stream<BioGTelemetry?> watchLive(String deviceId) => _live
      .putIfAbsent(deviceId, () => StreamController<BioGTelemetry?>.broadcast())
      .stream;

  @override
  Stream<List<BioGTelemetry>> watchHistory(
    String deviceId, {
    required Duration? window,
  }) => _history
      .putIfAbsent(
        deviceId,
        () => StreamController<List<BioGTelemetry>>.broadcast(),
      )
      .stream;

  @override
  Future<void> refresh(
    String deviceId, {
    Duration? window = const Duration(days: 7),
  }) async {}

  @override
  Future<void> forgetDevice(String deviceId) async {
    forgottenDeviceIds.add(deviceId);
    _live[deviceId]?.add(null);
    _history[deviceId]?.add(const <BioGTelemetry>[]);
  }

  @override
  void dispose() {
    for (final controller in _live.values) {
      controller.close();
    }
    for (final controller in _history.values) {
      controller.close();
    }
  }
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (int i = 0; i < 100; i++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not met before timeout.');
}
