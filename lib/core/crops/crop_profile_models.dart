import 'package:bio_g/core/crops/crop_types.dart';

class CropProfile {
  final String id;
  final CropKey cropKey;
  final String label;
  final String useType;

  const CropProfile({
    required this.id,
    required this.cropKey,
    required this.label,
    required this.useType,
  });
}
