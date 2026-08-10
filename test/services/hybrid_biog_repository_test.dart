import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/seed_install.dart';
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

/// Lectura de prueba, plausible y atada a un dispositivo concreto.
BioGTelemetry _sample(String deviceId, {Duration ago = Duration.zero}) {
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
    n: 60.0,
    p: 30.0,
    k: 70.0,
    batteryPct: 96.0,
    signalRssi: -55,
  );
}

/// Doble de la fuente de telemetría.
///
/// Estas dos pruebas expiraban a los 2 s y el diagnóstico fácil era culpar a
/// `kEnableSensorSimulator = false`. Es falso: el simulador NO alimenta
/// `watchHistory` ni `watchLiveTelemetry` —solo `watchAlerts`—, así que
/// encenderlo no habría arreglado nada y sí habría metido alertas agronómicas
/// sintéticas en un buzón que algún día se conectará a la interfaz.
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
  void dispose() {}
}
