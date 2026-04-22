import 'package:bio_g/models/device_crop_context.dart';

/// Per-user local store for [DeviceCropContext] records.
///
/// All methods take a nullable `userId` and are expected to namespace
/// their underlying storage by it — writes for user A must never be
/// visible to user B, even inside the same device, because signing out
/// of A and signing in as B must not leak crop context across accounts.
/// `null` / empty userId means "guest" and uses its own isolated slot.
abstract class CropContextStorage {
  Future<Map<String, DeviceCropContext>> loadAll({required String? userId});
  Future<void> save(DeviceCropContext context, {required String? userId});
  Future<void> delete(String deviceId, {required String? userId});
  Future<void> clearAll({required String? userId});
}
