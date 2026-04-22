import 'package:bio_g/models/yield_projection_config.dart';

/// Per-user local store for [YieldProjectionConfig] records.
///
/// See [CropContextStorage] for the namespacing contract — same rules
/// apply here: writes are scoped per userId and a guest slot exists
/// for unauthenticated sessions.
abstract class YieldProjectionStorage {
  Future<Map<String, YieldProjectionConfig>> loadAll({required String? userId});
  Future<void> save(YieldProjectionConfig config, {required String? userId});
  Future<void> delete(String deviceId, {required String? userId});
  Future<void> clearAll({required String? userId});
}
