import 'package:bio_g/models/device_crop_context.dart';

abstract class CropContextStorage {
  Future<Map<String, DeviceCropContext>> loadAll();
  Future<void> save(DeviceCropContext context);
  Future<void> delete(String deviceId);
  Future<void> clearAll();
}
