import 'package:bio_g/core/crops/apple_tree/apple_tree_crop_definition.dart';
import 'package:bio_g/core/crops/barley/barley_crop_definition.dart';
import 'package:bio_g/core/crops/bean/bean_crop_definition.dart';
import 'package:bio_g/core/crops/chili/chili_crop_definition.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/cucumber/cucumber_crop_definition.dart';
import 'package:bio_g/core/crops/eggplant/eggplant_crop_definition.dart';
import 'package:bio_g/core/crops/garlic/garlic_crop_definition.dart';
import 'package:bio_g/core/crops/lettuce/lettuce_crop_definition.dart';
import 'package:bio_g/core/crops/maize/maize_crop_definition.dart';
import 'package:bio_g/core/crops/oat/oat_crop_definition.dart';
import 'package:bio_g/core/crops/onion/onion_crop_definition.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_crop_definition.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_crop_definition.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_crop_definition.dart';
import 'package:bio_g/core/crops/spinach/spinach_crop_definition.dart';
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
    CropKey.spinach: SpinachCropDefinition(),
    CropKey.onion: OnionCropDefinition(),
    CropKey.garlic: GarlicCropDefinition(),
    CropKey.appleTree: AppleTreeCropDefinition(),
    CropKey.pearTree: PearTreeCropDefinition(),
    CropKey.peachTree: PeachTreeCropDefinition(),
    CropKey.walnutTree: WalnutTreeCropDefinition(),
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

    // cropId canónico oficial + alias legacy + aliases humanos: todos resuelven
    // a Manzano. Reconoce los mismos nombres comunes que CropCatalog para que un
    // caller con acceso directo al registro no se quede sin árbol.
    if (normalized == 'crop_apple_tree' ||
        normalized == 'apple_tree' ||
        normalized == 'apple' ||
        normalized == 'manzano' ||
        normalized == 'manzana') {
      return _definitions[CropKey.appleTree];
    }

    // Pera: cropId canónico oficial + alias legacy + aliases humanos
    // (`pera`/`peral`) resuelven a Pera, alineado con CropCatalog.canonicalCropKey.
    if (normalized == 'crop_pear_tree' ||
        normalized == 'pear_tree' ||
        normalized == 'pear' ||
        normalized == 'pera' ||
        normalized == 'peral') {
      return _definitions[CropKey.pearTree];
    }

    // Durazno: cropId canónico + alias legacy + aliases humanos resuelven a
    // Durazno, alineado con CropCatalog.canonicalCropKey.
    if (normalized == 'crop_peach_tree' ||
        normalized == 'peach_tree' ||
        normalized == 'peachtree' ||
        normalized == 'peach' ||
        normalized == 'durazno' ||
        normalized == 'duraznero' ||
        normalized == 'melocoton' ||
        normalized == 'melocotón' ||
        normalized == 'melocotonero') {
      return _definitions[CropKey.peachTree];
    }

    // Nogal pecanero: cropId canónico + alias legacy + aliases humanos resuelven
    // a Nogal, alineado con CropCatalog.canonicalCropKey.
    if (normalized == 'crop_walnut_tree' ||
        normalized == 'walnut_tree' ||
        normalized == 'walnuttree' ||
        normalized == 'walnut' ||
        normalized == 'nogal' ||
        normalized == 'nogal pecanero' ||
        normalized == 'pecan' ||
        normalized == 'nuez' ||
        normalized == 'nuez pecana') {
      return _definitions[CropKey.walnutTree];
    }

    return null;
  }
}
