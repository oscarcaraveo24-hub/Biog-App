import 'package:bio_g/models/biog_telemetry.dart';

/// Real source of truth for the BioG ecosystem identity layer.
///
/// Responsibilities (real, not simulated):
///   - List the devices the current user has access to
///   - Create / update / remove devices
///   - Persist the active device selection per user
///   - Expose offline-first caches so the UI can render immediately
///     before any remote call completes
///
/// Everything in this layer is keyed by [BioGDevice.id] (the master
/// deviceId). Telemetry/history streams use [BioGDevice.telemetryDeviceId]
/// and belong to the real hardware/offline-first pipeline.
abstract class DeviceIdentityRepository {
  /// Synchronously return the cached devices list for [userId] (or the
  /// last known list when [userId] is null). Used to render UI
  /// instantly on bootstrap before any network round-trip.
  List<BioGDevice> cachedDevices({String? userId});

  /// Synchronously return the cached active device id for the current
  /// user, if any.
  String? cachedActiveDeviceId();

  /// Load all devices the user has access to from the remote store,
  /// falling back to the local cache on error.
  ///
  /// Refreshes the internal cache on success.
  Future<List<BioGDevice>> loadDevices({required String? userId});

  /// Upsert a device. Writes local cache first (offline-first), then
  /// upserts to the remote store in the background. The returned device
  /// reflects the authoritative state after local write.
  Future<BioGDevice> upsertDevice({
    required String? userId,
    required BioGDevice device,
  });

  /// Remove a device from the user's scope. Local cache is updated
  /// immediately; remote delete is best-effort.
  Future<void> removeDevice({
    required String? userId,
    required String deviceId,
  });

  /// Persist the active device selection for [userId].
  Future<void> setActiveDeviceId({
    required String? userId,
    required String deviceId,
  });

  /// Persist that the user currently has no active device.
  Future<void> clearActiveDeviceId({required String? userId});

  /// Clear the in-memory cache for the given user (e.g. on sign-out).
  /// Local persisted cache is preserved so the same user gets an
  /// instant render on next sign-in.
  void clearInMemory();
}
