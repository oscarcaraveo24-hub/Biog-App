// lib/services/biog/biog_repository.dart
import 'package:bio_g/models/biog_telemetry.dart';

/// Runtime-facing façade over the BioG ecosystem.
///
/// This interface is intentionally UI-oriented: the [BioGStore] and all
/// screens consume it without caring whether the data comes from real
/// Supabase tables, a local cache, or the transitional sensor simulator.
///
/// In the current hybrid architecture, [HybridBioGRepository] implements
/// this interface by combining:
///   - a real [DeviceIdentityRepository] for devices / active device
///   - a [SensorSimulator] for live telemetry / history / alerts
///
/// When real hardware replaces the simulator, only the implementation
/// changes — this contract stays stable.
abstract class BioGRepository {
  /// Devices the current user has access to.
  Stream<List<BioGDevice>> watchDevices();

  /// Currently selected device for the app.
  Stream<BioGDevice?> watchActiveDevice();

  /// Live telemetry for the active device.
  Stream<BioGTelemetry?> watchLiveTelemetry();

  /// History for the active device. A null window requests all available data.
  Stream<List<BioGTelemetry>> watchHistory({required Duration? window});

  /// Latest alerts for the active device.
  Stream<List<BioGAlert>> watchAlerts({int limit = 50});

  /// Persist the new active device selection.
  Future<void> setActiveDevice(String deviceId);

  /// Create / register a new device in the user's scope. The legacy
  /// naming (`addFakeDevice`) was kept as an alias for compatibility
  /// during the transition away from the monolithic fake repo.
  Future<BioGDevice> addDevice({
    String? seedId,
    String? profileId,
    String? locationName,
    String? name,
  });

  /// Remove a device from the user's scope.
  Future<void> removeDevice(String deviceId);

  /// Tear down long-lived resources (timers, streams, caches).
  void dispose();
}
