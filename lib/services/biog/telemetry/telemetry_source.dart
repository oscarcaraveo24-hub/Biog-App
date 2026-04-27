import 'package:bio_g/models/biog_telemetry.dart';

/// Abstraction for telemetry providers.
///
/// The UI should not care if telemetry came from:
/// - local storage
/// - Supabase/cloud sync
/// - Bluetooth
/// - simulator/dev mode
///
/// Implementations should keep the app offline-first whenever possible.
abstract class TelemetrySource {
  /// Watches the latest telemetry reading for a device.
  Stream<BioGTelemetry?> watchLive(String deviceId);

  /// Watches historical telemetry for a device inside a time window.
  Stream<List<BioGTelemetry>> watchHistory(
    String deviceId, {
    required Duration window,
  });

  /// Refresh telemetry for a device from its backing source.
  ///
  /// For a cloud source, this means downloading from Supabase.
  /// For Bluetooth, this may mean pulling buffered readings from hardware.
  /// For local-only/dev mode, this may be a no-op.
  Future<void> refresh(
    String deviceId, {
    Duration window = const Duration(days: 7),
  });

  /// Release stream controllers, timers, and subscriptions.
  void dispose();
}
