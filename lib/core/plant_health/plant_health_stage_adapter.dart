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
      case CropCatalog.tomatoCropId:
        return _fromTomato(stage, daySinceSowing);
      case CropCatalog.cucumberCropId:
        return _fromCucumber(stage, daySinceSowing);
      case CropCatalog.chiliCropId:
        return _fromChili(stage, daySinceSowing);
      case CropCatalog.eggplantCropId:
        return _fromEggplant(stage, daySinceSowing);
      case CropCatalog.squashCropId:
        return _fromSquash(stage, daySinceSowing);
      case CropCatalog.lettuceCropId:
        return _fromLettuce(stage, daySinceSowing);
    }
    return null;
  }

  /// Lechuga: hortaliza de hoja con 6 etapas BIO-G. El bucket
  /// reproductiveEarly representa la formación de cabeza (E4) y
  /// reproductiveMid/grainFill la ventana de cosecha (E5).
  static PlantHealthStageBucket _fromLettuce(String stage, int? day) {
    if (_matches(stage, const <String>['germin'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['establec', 'emerg', 'transplant'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['cabeza', 'formacion', 'head'])) {
      return PlantHealthStageBucket.reproductiveEarly;
    }
    if (_matches(stage, const <String>[
      'sobremadur',
      'senesc',
      'cierre',
      'end',
    ])) {
      return PlantHealthStageBucket.lateSeason;
    }
    if (_matches(stage, const <String>['cosecha', 'ventana', 'harvest'])) {
      return PlantHealthStageBucket.reproductiveMid;
    }
    if (_matches(stage, const <String>['vegetativo', 'vegetative'])) {
      if (day != null) {
        if (day <= 18) return PlantHealthStageBucket.vegetativeEarly;
        if (day <= 32) return PlantHealthStageBucket.vegetativeMid;
      }
      return PlantHealthStageBucket.vegetativeLate;
    }
    if (day != null) {
      if (day <= 7) return PlantHealthStageBucket.seedling;
      if (day <= 21) return PlantHealthStageBucket.vegetativeEarly;
      if (day <= 38) return PlantHealthStageBucket.vegetativeMid;
      if (day <= 50) return PlantHealthStageBucket.vegetativeLate;
      if (day <= 64) return PlantHealthStageBucket.reproductiveEarly;
      if (day <= 85) return PlantHealthStageBucket.reproductiveMid;
    }
    return PlantHealthStageBucket.lateSeason;
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

  static PlantHealthStageBucket _fromCucumber(String stage, int? day) {
    if (_matches(stage, const <String>['germin'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['establec', 'transplant'])) {
      return PlantHealthStageBucket.vegetativeEarly;
    }
    if (_matches(stage, const <String>['vegetativo', 'vegetative'])) {
      if (day != null) {
        if (day <= 18) return PlantHealthStageBucket.vegetativeEarly;
        if (day <= 32) return PlantHealthStageBucket.vegetativeMid;
      }
      return PlantHealthStageBucket.vegetativeLate;
    }
    if (_matches(stage, const <String>['flor', 'flower'])) {
      return PlantHealthStageBucket.reproductiveEarly;
    }
    if (_matches(stage, const <String>['cuaj', 'fruitset'])) {
      return PlantHealthStageBucket.reproductiveMid;
    }
    if (_matches(stage, const <String>['llen'])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>['cosecha', 'progresiva', 'harvest'])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>['fin', 'cierre', 'end', 'senesc'])) {
      return PlantHealthStageBucket.lateSeason;
    }
    if (day != null) {
      if (day <= 10) return PlantHealthStageBucket.seedling;
      if (day <= 20) return PlantHealthStageBucket.vegetativeEarly;
      if (day <= 32) return PlantHealthStageBucket.vegetativeMid;
      if (day <= 45) return PlantHealthStageBucket.vegetativeLate;
      if (day <= 58) return PlantHealthStageBucket.reproductiveEarly;
      if (day <= 72) return PlantHealthStageBucket.reproductiveMid;
      if (day <= 110) return PlantHealthStageBucket.grainFill;
    }
    return PlantHealthStageBucket.lateSeason;
  }

  static PlantHealthStageBucket _fromChili(String stage, int? day) {
    if (_matches(stage, const <String>['germin'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['establec', 'emerg', 'transplant'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['vegetativo', 'vegetative'])) {
      if (day != null) {
        if (day <= 35) return PlantHealthStageBucket.vegetativeEarly;
        if (day <= 55) return PlantHealthStageBucket.vegetativeMid;
      }
      return PlantHealthStageBucket.vegetativeLate;
    }
    if (_matches(stage, const <String>['flor', 'flower'])) {
      return PlantHealthStageBucket.reproductiveEarly;
    }
    if (_matches(stage, const <String>['cuaj', 'amarre', 'fruitset'])) {
      return PlantHealthStageBucket.reproductiveMid;
    }
    if (_matches(stage, const <String>['llen'])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>['cosecha', 'progresiv', 'harvest'])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>['fin', 'cierre', 'end', 'senesc'])) {
      return PlantHealthStageBucket.lateSeason;
    }
    if (day != null) {
      if (day <= 18) return PlantHealthStageBucket.seedling;
      if (day <= 35) return PlantHealthStageBucket.vegetativeEarly;
      if (day <= 55) return PlantHealthStageBucket.vegetativeMid;
      if (day <= 75) return PlantHealthStageBucket.vegetativeLate;
      if (day <= 95) return PlantHealthStageBucket.reproductiveEarly;
      if (day <= 115) return PlantHealthStageBucket.reproductiveMid;
      if (day <= 160) return PlantHealthStageBucket.grainFill;
    }
    return PlantHealthStageBucket.lateSeason;
  }

  static PlantHealthStageBucket _fromEggplant(String stage, int? day) {
    if (_matches(stage, const <String>['germin'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['establec', 'emerg', 'transplant'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['vegetativo', 'vegetative'])) {
      if (day != null) {
        if (day <= 35) return PlantHealthStageBucket.vegetativeEarly;
        if (day <= 55) return PlantHealthStageBucket.vegetativeMid;
      }
      return PlantHealthStageBucket.vegetativeLate;
    }
    if (_matches(stage, const <String>['flor', 'flower'])) {
      return PlantHealthStageBucket.reproductiveEarly;
    }
    if (_matches(stage, const <String>['cuaj', 'amarre', 'fruitset'])) {
      return PlantHealthStageBucket.reproductiveMid;
    }
    if (_matches(stage, const <String>['llen'])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>['cosecha', 'progresiv', 'harvest'])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>['fin', 'cierre', 'end', 'senesc'])) {
      return PlantHealthStageBucket.lateSeason;
    }
    if (day != null) {
      if (day <= 18) return PlantHealthStageBucket.seedling;
      if (day <= 35) return PlantHealthStageBucket.vegetativeEarly;
      if (day <= 55) return PlantHealthStageBucket.vegetativeMid;
      if (day <= 75) return PlantHealthStageBucket.vegetativeLate;
      if (day <= 95) return PlantHealthStageBucket.reproductiveEarly;
      if (day <= 115) return PlantHealthStageBucket.reproductiveMid;
      if (day <= 160) return PlantHealthStageBucket.grainFill;
    }
    return PlantHealthStageBucket.lateSeason;
  }

  static PlantHealthStageBucket _fromTomato(String stage, int? day) {
    if (_matches(stage, const <String>['germ'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['establec', 'transplant'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['vegetativo', 'vegetative'])) {
      if (day != null) {
        if (day <= 35) return PlantHealthStageBucket.vegetativeEarly;
        if (day <= 55) return PlantHealthStageBucket.vegetativeMid;
      }
      return PlantHealthStageBucket.vegetativeLate;
    }
    if (_matches(stage, const <String>['flor', 'flower'])) {
      return PlantHealthStageBucket.reproductiveEarly;
    }
    if (_matches(stage, const <String>['cuaj', 'fruitset'])) {
      return PlantHealthStageBucket.reproductiveMid;
    }
    if (_matches(stage, const <String>['llen', 'harvest', 'progresiv'])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>['fin', 'cierre', 'end'])) {
      return PlantHealthStageBucket.lateSeason;
    }
    if (day != null) {
      if (day <= 18) return PlantHealthStageBucket.seedling;
      if (day <= 35) return PlantHealthStageBucket.vegetativeEarly;
      if (day <= 55) return PlantHealthStageBucket.vegetativeMid;
      if (day <= 75) return PlantHealthStageBucket.reproductiveEarly;
      if (day <= 95) return PlantHealthStageBucket.reproductiveMid;
      if (day <= 145) return PlantHealthStageBucket.grainFill;
    }
    return PlantHealthStageBucket.lateSeason;
  }

  static PlantHealthStageBucket _fromSquash(String stage, int? day) {
    if (_matches(stage, const <String>['germin'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['establec', 'emerg', 'transplant'])) {
      return PlantHealthStageBucket.vegetativeEarly;
    }
    if (_matches(stage, const <String>['vegetativo', 'vegetative'])) {
      if (day != null) {
        if (day <= 28) return PlantHealthStageBucket.vegetativeEarly;
        if (day <= 45) return PlantHealthStageBucket.vegetativeMid;
      }
      return PlantHealthStageBucket.vegetativeLate;
    }
    if (_matches(stage, const <String>['flor', 'flower'])) {
      return PlantHealthStageBucket.reproductiveEarly;
    }
    if (_matches(stage, const <String>['cuaj', 'amarre', 'fruitset'])) {
      return PlantHealthStageBucket.reproductiveMid;
    }
    if (_matches(stage, const <String>['llen'])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>['cosecha', 'progresiv', 'harvest'])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>['fin', 'cierre', 'end', 'senesc'])) {
      return PlantHealthStageBucket.lateSeason;
    }
    if (day != null) {
      if (day <= 10) return PlantHealthStageBucket.seedling;
      if (day <= 28) return PlantHealthStageBucket.vegetativeEarly;
      if (day <= 45) return PlantHealthStageBucket.vegetativeMid;
      if (day <= 65) return PlantHealthStageBucket.vegetativeLate;
      if (day <= 90) return PlantHealthStageBucket.reproductiveEarly;
      if (day <= 120) return PlantHealthStageBucket.reproductiveMid;
      if (day <= 180) return PlantHealthStageBucket.grainFill;
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
