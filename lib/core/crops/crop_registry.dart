import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/maize/maize_crop_definition.dart';

class CropRegistry {
  CropRegistry._();

  static final Map<CropKey, CropDefinition> _definitions = {
    CropKey.maize: MaizeCropDefinition(),
  };

  static CropDefinition? byKey(CropKey key) => _definitions[key];

  static CropDefinition? byKeyName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final normalized = raw.trim().toLowerCase();

    for (final key in CropKey.values) {
      if (key.name.toLowerCase() == normalized) {
        return _definitions[key];
      }
    }

    return null;
  }
}
