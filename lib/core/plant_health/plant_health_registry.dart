import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/catalog/apple_tree_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/barley_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/bean_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/chili_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/maize_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/cucumber_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/eggplant_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/garlic_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/lettuce_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/oat_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/onion_syndromes.dart';
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
      default:
        return const <PlantHealthSyndrome>[];
    }
  }

  static bool isSupportedCrop(String cropId) => catalogForCrop(cropId).isNotEmpty;
}
