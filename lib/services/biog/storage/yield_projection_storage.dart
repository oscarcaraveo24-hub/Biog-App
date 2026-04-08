import 'package:bio_g/models/yield_projection_config.dart';

abstract class YieldProjectionStorage {
  Future<Map<String, YieldProjectionConfig>> loadAll();
  Future<void> save(YieldProjectionConfig config);
  Future<void> delete(String deviceId);
  Future<void> clearAll();
}
