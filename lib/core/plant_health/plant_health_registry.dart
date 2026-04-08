import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/catalog/barley_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/bean_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/maize_syndromes.dart';
import 'package:bio_g/core/plant_health/catalog/oat_syndromes.dart';
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
      default:
        return const <PlantHealthSyndrome>[];
    }
  }

  static bool isSupportedCrop(String cropId) => catalogForCrop(cropId).isNotEmpty;
}
