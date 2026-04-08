import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

class PlantHealthStageAdapter {
  const PlantHealthStageAdapter._();

  static PlantHealthStageBucket? fromCropStage({
    required String cropId,
    required String? stageKey,
    required int? daySinceSowing,
  }) {
    final normalizedCropId = CropCatalog.canonicalCropKeyOrNull(cropId);
    final stage = stageKey?.trim().toLowerCase() ?? '';
    if (normalizedCropId == null) return null;
    if (stage.isEmpty && daySinceSowing == null) return null;

    switch (normalizedCropId) {
      case CropCatalog.maizeCropId:
        return _fromMaize(stage, daySinceSowing);
      case CropCatalog.wheatCropId:
      case CropCatalog.barleyCropId:
      case CropCatalog.oatCropId:
        return _fromCereal(stage, daySinceSowing);
      case CropCatalog.beanCropId:
        return _fromBean(stage, daySinceSowing);
    }
    return null;
  }

  static PlantHealthStageBucket _fromMaize(String stage, int? day) {
    if (_matches(stage, const <String>['germ', 'emerg']))
      return PlantHealthStageBucket.seedling;
    if (_matches(stage, const <String>['v1', 'v2', 'vegearly', 'veg_early']))
      return PlantHealthStageBucket.vegetativeEarly;
    if (_matches(stage, const <String>[
      'v3',
      'v4',
      'v5',
      'v6',
      'vegmid',
      'veg_mid',
    ]))
      return PlantHealthStageBucket.vegetativeMid;
    if (_matches(stage, const <String>[
      'v7',
      'v8',
      'v9',
      'vegadvanced',
      'veg_advanced',
    ]))
      return PlantHealthStageBucket.vegetativeLate;
    if (_matches(stage, const <String>[
      'vt',
      'tassel',
      'tasseling',
      'flowerset',
      'flower_set',
      'r1',
    ]))
      return PlantHealthStageBucket.reproductiveEarly;
    if (_matches(stage, const <String>['r2', 'r3']))
      return PlantHealthStageBucket.reproductiveMid;
    if (_matches(stage, const <String>['r4', 'r5']))
      return PlantHealthStageBucket.grainFill;
    if (_matches(stage, const <String>[
      'maturity',
      'senescence',
      'r6',
      'harvest',
    ]))
      return PlantHealthStageBucket.lateSeason;
    if (day != null) {
      if (day <= 10) return PlantHealthStageBucket.seedling;
      if (day <= 30) return PlantHealthStageBucket.vegetativeEarly;
      if (day <= 55) return PlantHealthStageBucket.vegetativeMid;
      if (day <= 75) return PlantHealthStageBucket.vegetativeLate;
      if (day <= 95) return PlantHealthStageBucket.reproductiveEarly;
      if (day <= 110) return PlantHealthStageBucket.reproductiveMid;
      if (day <= 130) return PlantHealthStageBucket.grainFill;
    }
    return PlantHealthStageBucket.lateSeason;
  }

  static PlantHealthStageBucket _fromCereal(String stage, int? day) {
    if (_matches(stage, const <String>['germ', 'emerg']))
      return PlantHealthStageBucket.seedling;
    if (_matches(stage, const <String>['vegearly', 'veg_early']))
      return PlantHealthStageBucket.vegetativeEarly;
    if (_matches(stage, const <String>['tiller', 'macoll']))
      return PlantHealthStageBucket.vegetativeMid;
    if (_matches(stage, const <String>['elong', 'boot', 'embu']))
      return PlantHealthStageBucket.vegetativeLate;
    if (_matches(stage, const <String>['head', 'espig', 'flower', 'anthesis']))
      return PlantHealthStageBucket.reproductiveEarly;
    if (_matches(stage, const <String>['grainfill', 'grain_fill', 'llenado']))
      return PlantHealthStageBucket.grainFill;
    if (_matches(stage, const <String>[
      'maturity',
      'madurez',
      'harvest',
      'cosecha',
    ]))
      return PlantHealthStageBucket.lateSeason;
    if (day != null) {
      if (day <= 10) return PlantHealthStageBucket.seedling;
      if (day <= 25) return PlantHealthStageBucket.vegetativeEarly;
      if (day <= 50) return PlantHealthStageBucket.vegetativeMid;
      if (day <= 72) return PlantHealthStageBucket.vegetativeLate;
      if (day <= 92) return PlantHealthStageBucket.reproductiveEarly;
      if (day <= 112) return PlantHealthStageBucket.grainFill;
    }
    return PlantHealthStageBucket.lateSeason;
  }

  static PlantHealthStageBucket _fromBean(String stage, int? day) {
    if (_matches(stage, const <String>['germ', 'emerg']))
      return PlantHealthStageBucket.seedling;
    if (_matches(stage, const <String>['vegearly', 'veg_early']))
      return PlantHealthStageBucket.vegetativeEarly;
    if (_matches(stage, const <String>['vegadvanced', 'veg_advanced']))
      return PlantHealthStageBucket.vegetativeMid;
    if (_matches(stage, const <String>['flower']))
      return PlantHealthStageBucket.reproductiveEarly;
    if (_matches(stage, const <String>['podset', 'pod_set']))
      return PlantHealthStageBucket.reproductiveMid;
    if (_matches(stage, const <String>['grainfill', 'grain_fill']))
      return PlantHealthStageBucket.grainFill;
    if (_matches(stage, const <String>['maturity', 'harvest']))
      return PlantHealthStageBucket.lateSeason;
    if (day != null) {
      if (day <= 8) return PlantHealthStageBucket.seedling;
      if (day <= 22) return PlantHealthStageBucket.vegetativeEarly;
      if (day <= 38) return PlantHealthStageBucket.vegetativeMid;
      if (day <= 55) return PlantHealthStageBucket.reproductiveEarly;
      if (day <= 72) return PlantHealthStageBucket.reproductiveMid;
      if (day <= 88) return PlantHealthStageBucket.grainFill;
    }
    return PlantHealthStageBucket.lateSeason;
  }

  static bool _matches(String stage, List<String> patterns) {
    for (final pattern in patterns) {
      if (stage.contains(pattern)) return true;
    }
    return false;
  }
}
