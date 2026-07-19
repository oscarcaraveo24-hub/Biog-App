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
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_crop_definition.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_crop_definition.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_crop_definition.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_crop_definition.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_crop_definition.dart';
import 'package:bio_g/core/crops/cactus/cactus_crop_definition.dart';
import 'package:bio_g/core/crops/succulent/succulent_crop_definition.dart';
import 'package:bio_g/core/crops/aloe/aloe_crop_definition.dart';
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
    CropKey.pistachioTree: PistachioTreeCropDefinition(),
    CropKey.orangeTree: OrangeTreeCropDefinition(),
    CropKey.lemonTree: LemonTreeCropDefinition(),
    CropKey.mangoTree: MangoTreeCropDefinition(),
    CropKey.avocadoTree: AvocadoTreeCropDefinition(),
    CropKey.cactus: CactusCropDefinition(),
    CropKey.succulent: SucculentCropDefinition(),
    CropKey.aloe: AloeCropDefinition(),
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

    // Pistache: cropId canónico + alias legacy + aliases humanos resuelven a
    // Pistache, alineado con CropCatalog.canonicalCropKey.
    if (normalized == 'crop_pistachio_tree' ||
        normalized == 'pistachio_tree' ||
        normalized == 'pistachiotree' ||
        normalized == 'pistachio' ||
        normalized == 'pistache' ||
        normalized == 'pistacho' ||
        normalized == 'pistachero' ||
        normalized == 'alfoncigo' ||
        normalized == 'alfóncigo') {
      return _definitions[CropKey.pistachioTree];
    }

    // Naranjo: cropId canónico + alias legacy + aliases humanos resuelven a
    // Naranjo, alineado con CropCatalog.canonicalCropKey.
    if (normalized == 'crop_orange_tree' ||
        normalized == 'orange_tree' ||
        normalized == 'orangetree' ||
        normalized == 'orange' ||
        normalized == 'naranjo' ||
        normalized == 'naranja' ||
        normalized == 'naranja dulce' ||
        normalized == 'sweet orange') {
      return _definitions[CropKey.orangeTree];
    }

    // Limón: cropId canónico + alias legacy (lime) + aliases humanos resuelven a
    // Limón, alineado con CropCatalog.canonicalCropKey. NO cae en naranjo.
    if (normalized == 'crop_lemon_tree' ||
        normalized == 'lemon_tree' ||
        normalized == 'lemontree' ||
        normalized == 'crop_lime_tree' ||
        normalized == 'lime_tree' ||
        normalized == 'lemon' ||
        normalized == 'lime' ||
        normalized == 'limon' ||
        normalized == 'limón' ||
        normalized == 'limonero' ||
        normalized == 'lima') {
      return _definitions[CropKey.lemonTree];
    }

    // Mango: cropId canónico + alias legacy + aliases humanos resuelven a Mango,
    // alineado con CropCatalog.canonicalCropKey. NO cae en limón/naranjo.
    if (normalized == 'crop_mango_tree' ||
        normalized == 'mango_tree' ||
        normalized == 'mangotree' ||
        normalized == 'crop_mango' ||
        normalized == 'mango' ||
        normalized == 'mangos' ||
        normalized == 'mangifera' ||
        normalized == 'mangifera_indica' ||
        normalized == 'arbol_mango' ||
        normalized == 'árbol_mango') {
      return _definitions[CropKey.mangoTree];
    }

    // Aguacate: cropId canónico + alias legacy + aliases humanos resuelven a
    // Aguacate, alineado con CropCatalog.canonicalCropKey. NO cae en mango,
    // cítricos ni manzano.
    if (normalized == 'crop_avocado_tree' ||
        normalized == 'avocado_tree' ||
        normalized == 'avocadotree' ||
        normalized == 'crop_avocado' ||
        normalized == 'avocado' ||
        normalized == 'avocados' ||
        normalized == 'aguacate' ||
        normalized == 'aguacates' ||
        normalized == 'aguacatero' ||
        normalized == 'palta' ||
        normalized == 'palto' ||
        normalized == 'persea' ||
        normalized == 'persea_americana' ||
        normalized == 'arbol_aguacate' ||
        normalized == 'árbol_aguacate' ||
        normalized == 'arbol de aguacate' ||
        normalized == 'árbol de aguacate') {
      return _definitions[CropKey.avocadoTree];
    }

    // Cactus: cropId canónico + alias legacy + aliases humanos resuelven a
    // Cactus, alineado con CropCatalog.canonicalCropKey. Primera ornamental
    // oficial; ids provisionales previos (cactus_generic/mini/columnar) también
    // resuelven al cultivo cactus.
    if (normalized == 'crop_cactus' ||
        normalized == 'cactus' ||
        normalized == 'cactos' ||
        normalized == 'cacto' ||
        normalized == 'cactus_generic' ||
        normalized == 'cactus_mini' ||
        normalized == 'cactus_columnar') {
      return _definitions[CropKey.cactus];
    }

    // Suculenta: cropId canónico + alias legacy + aliases humanos resuelven a
    // Suculenta, alineado con CropCatalog.canonicalCropKey. Segunda ornamental
    // oficial. NO cae en cactus: comparten modo de ciclo, no biología.
    if (normalized == 'crop_succulent' ||
        normalized == 'succulent' ||
        normalized == 'succulents' ||
        normalized == 'suculenta' ||
        normalized == 'suculentas' ||
        normalized == 'planta suculenta' ||
        normalized == 'planta crasa' ||
        normalized == 'crasa') {
      return _definitions[CropKey.succulent];
    }

    // Sábila / Aloe: tercera ornamental oficial. cropId canónico + alias legacy
    // + aliases humanos resuelven a Sábila. NO cae en suculenta ni cactus:
    // comparten modo de ciclo, no biología.
    if (normalized == 'crop_aloe' ||
        normalized == 'aloe' ||
        normalized == 'sabila' ||
        normalized == 'sábila' ||
        normalized == 'zabila' ||
        normalized == 'zábila' ||
        normalized == 'aloe vera') {
      return _definitions[CropKey.aloe];
    }

    return null;
  }
}
