import 'package:bio_g/core/plant_health/plant_health_models.dart';

class PlantHealthCase {
  final String deviceId;
  final DateTime createdAt;
  final PlantHealthInput input;
  final PlantHealthResult result;

  const PlantHealthCase({
    required this.deviceId,
    required this.createdAt,
    required this.input,
    required this.result,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'device_id': deviceId,
    'created_at': createdAt.toIso8601String(),
    'input': input.toJson(),
    'result': result.toJson(),
  };
}
