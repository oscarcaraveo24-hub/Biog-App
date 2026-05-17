import 'package:bio_g/core/crops/barley/barley_crop_definition.dart';
import 'package:bio_g/core/crops/bean/bean_crop_definition.dart';
import 'package:bio_g/core/crops/chili/chili_crop_definition.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/cucumber/cucumber_crop_definition.dart';
import 'package:bio_g/core/crops/eggplant/eggplant_crop_definition.dart';
import 'package:bio_g/core/crops/lettuce/lettuce_crop_definition.dart';
import 'package:bio_g/core/crops/maize/maize_crop_definition.dart';
import 'package:bio_g/core/crops/oat/oat_crop_definition.dart';
import 'package:bio_g/core/crops/squash/squash_crop_definition.dart';
import 'package:bio_g/core/crops/tomato/tomato_crop_definition.dart';
import 'package:bio_g/core/crops/wheat/wheat_crop_definition.dart';

class CropRegistry {
  CropRegistry._();

  static final Map<CropKey, CropDefinition> _definitions = {
    CropKey.maize: MaizeCropDefinition(),
    CropKey.bean: BeanCropDefinition(),
    CropKey.oat: OatCropDefinition(),
    CropKey.barley: BarleyCropDefinition(),
    CropKey.wheat: WheatCropDefinition(),
    CropKey.tomato: TomatoCropDefinition(),
    CropKey.cucumber: CucumberCropDefinition(),
    CropKey.chili: ChiliCropDefinition(),
    CropKey.eggplant: EggplantCropDefinition(),
    CropKey.squash: SquashCropDefinition(),
    CropKey.lettuce: LettuceCropDefinition(),
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
