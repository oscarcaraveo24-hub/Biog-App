import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/catalog/apple_tree_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/barley_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/bean_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/cactus_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/succulent_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/aloe_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/agave_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/nopal_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/rose_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/tulip_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/sunflower_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/marigold_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/chili_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/maize_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/cucumber_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/eggplant_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/garlic_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/lettuce_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/oat_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/onion_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/peach_tree_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/pear_tree_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/walnut_tree_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/pistachio_tree_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/orange_tree_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/lemon_tree_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/mango_tree_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/avocado_tree_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/spinach_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/squash_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/tomato_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/wheat_syndromes.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';

class PlantHealthRegistry {
  const PlantHealthRegistry._();

  static List<PlantHealthSyndrome> catalogForCrop(String cropId) {
    switch (CropCatalog.canonicalCropKey(cropId)) {
      case CropCatalog.oatCropId:
        return oatSyndromes;
      case CropCatalog.maizeCropId:
        return maizeSyndromes;
      case CropCatalog.wheatCropId:
        return wheatSyndromes;
      case CropCatalog.barleyCropId:
        return barleySyndromes;
      case CropCatalog.beanCropId:
        return beanSyndromes;
      case CropCatalog.cactusCropId:
        return cactusSyndromes;
      case CropCatalog.succulentCropId:
        return succulentSyndromes;
      case CropCatalog.aloeCropId:
        return aloeSyndromes;
      case CropCatalog.agaveCropId:
        return agaveSyndromes;
      case CropCatalog.nopalCropId:
        return nopalSyndromes;
      case CropCatalog.roseCropId:
        return roseSyndromes;
      case CropCatalog.tomatoCropId:
        return tomatoSyndromes;
      case CropCatalog.cucumberCropId:
        return cucumberSyndromes;
      case CropCatalog.chiliCropId:
        return chiliSyndromes;
      case CropCatalog.eggplantCropId:
        return eggplantSyndromes;
      case CropCatalog.squashCropId:
        return squashSyndromes;
      case CropCatalog.lettuceCropId:
        return lettuceSyndromes;
      case CropCatalog.spinachCropId:
        return spinachSyndromes;
      case CropCatalog.onionCropId:
        return onionSyndromes;
      case CropCatalog.garlicCropId:
        return garlicSyndromes;
      case CropCatalog.appleTreeCropId:
        return appleTreeSyndromes;
      case CropCatalog.pearTreeCropId:
        return pearTreeSyndromes;
      case CropCatalog.peachTreeCropId:
        return peachTreeSyndromes;
      case CropCatalog.walnutTreeCropId:
        return walnutTreeSyndromes;
      case CropCatalog.pistachioTreeCropId:
        return pistachioTreeSyndromes;
      case CropCatalog.orangeTreeCropId:
        return orangeTreeSyndromes;
      case CropCatalog.lemonTreeCropId:
        return lemonTreeSyndromes;
      case CropCatalog.mangoTreeCropId:
        return mangoTreeSyndromes;
      case CropCatalog.avocadoTreeCropId:
        return avocadoTreeSyndromes;
      case CropCatalog.tulipCropId:
        return tulipSyndromes;
      case CropCatalog.sunflowerCropId:
        return sunflowerSyndromes;
      case CropCatalog.marigoldCropId:
        // Rama EXPLÍCITA (Doc C §36): crop_marigold jamás cae al catálogo del
        // Girasol ni reutiliza ids con prefijo `sunflower_`.
        return marigoldSyndromes;
      default:
        return const <PlantHealthSyndrome>[];
    }
  }

  static bool isSupportedCrop(String cropId) =>
      catalogForCrop(cropId).isNotEmpty;
}
