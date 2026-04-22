import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/services/biog/hybrid_biog_repository.dart';
import 'package:bio_g/services/biog/identity/device_identity_repository.dart';
import 'package:bio_g/services/biog/telemetry/sensor_simulator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HybridBioGRepository late subscribers', () {
    test('watchHistory attaches to the already-active device', () async {
      final device = _testDevice(id: 'device-001');
      final identity = _FakeDeviceIdentityRepository(
        devices: <BioGDevice>[device],
        activeDeviceId: device.id,
      );

      final repo = HybridBioGRepository(
        identity: identity,
        simulator: SensorSimulator(
          tick: const Duration(milliseconds: 20),
          historyCap: 64,
        ),
      );
      addTearDown(repo.dispose);

      await repo.bindUser(
        userId: 'user-001',
        seedResolver: (_) => SeedInstall.planted(
          deviceId: device.id,
          cropKey: 'maize',
          varietyAlias: 'generic',
          sowingDate: DateTime.now().subtract(const Duration(days: 21)),
        ),
      );

      final history = await repo
          .watchHistory(window: const Duration(days: 7))
          .firstWhere((samples) => samples.isNotEmpty)
          .timeout(const Duration(seconds: 2));

      expect(history, isNotEmpty);
      expect(history.every((sample) => sample.deviceId == device.id), isTrue);
    });

    test('watchLiveTelemetry emits for the already-active device', () async {
      final device = _testDevice(id: 'device-002');
      final identity = _FakeDeviceIdentityRepository(
        devices: <BioGDevice>[device],
        activeDeviceId: device.id,
      );

      final repo = HybridBioGRepository(
        identity: identity,
        simulator: SensorSimulator(
          tick: const Duration(milliseconds: 20),
          historyCap: 64,
        ),
      );
      addTearDown(repo.dispose);

      await repo.bindUser(
        userId: 'user-002',
        seedResolver: (_) => SeedInstall.planted(
          deviceId: device.id,
          cropKey: 'maize',
          varietyAlias: 'generic',
          sowingDate: DateTime.now().subtract(const Duration(days: 21)),
        ),
      );

      final live = await repo
          .watchLiveTelemetry()
          .firstWhere((sample) => sample != null)
          .timeout(const Duration(seconds: 2));

      expect(live, isNotNull);
      expect(live!.deviceId, device.id);
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

  @override
  List<BioGDevice> cachedDevices({String? userId}) {
    return List<BioGDevice>.from(_devices);
  }

  @override
  String? cachedActiveDeviceId() => _activeDeviceId;

  @override
  void clearInMemory() {}

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
