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
      case CropCatalog.spinachCropId:
        return _fromSpinach(stage, daySinceSowing);
      case CropCatalog.onionCropId:
        return _fromOnion(stage, daySinceSowing);
      case CropCatalog.garlicCropId:
        return _fromGarlic(stage, daySinceSowing);
      case CropCatalog.appleTreeCropId:
        return _fromAppleTree(stage);
      case CropCatalog.pearTreeCropId:
        return _fromPearTree(stage);
      case CropCatalog.peachTreeCropId:
        return _fromPeachTree(stage);
      case CropCatalog.walnutTreeCropId:
        return _fromWalnutTree(stage);
    }
    return null;
  }

  /// Manzano / árbol perenne: las etapas fenológicas del árbol no usan
  /// `daySinceSowing` (sowingDate no es el eje). Se mapean los TreeStageIds a
  /// los buckets genéricos del motor de sanidad. `unknown` no fuerza bucket.
  static PlantHealthStageBucket? _fromAppleTree(String stage) {
    if (_matches(stage, const <String>['planting_transplant', 'root_establish'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['juvenile', 'budbreak'])) {
      return PlantHealthStageBucket.vegetativeEarly;
    }
    if (_matches(stage, const <String>['vegetative_growth'])) {
      return PlantHealthStageBucket.vegetativeMid;
    }
    if (_matches(stage, const <String>['flowering'])) {
      return PlantHealthStageBucket.reproductiveEarly;
    }
    if (_matches(stage, const <String>['fruit_set'])) {
      return PlantHealthStageBucket.reproductiveMid;
    }
    if (_matches(stage, const <String>['fruit_fill', 'harvest_maturity'])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>['dormancy', 'post_harvest'])) {
      return PlantHealthStageBucket.lateSeason;
    }
    return null;
  }

  /// Pera / peral perenne (doc 04 §6): mapea los TreeStageIds del peral a los
  /// buckets del motor de sanidad para que cada etapa fenológica filtre/pondere
  /// sus riesgos propios, sin reusar el mapeo del manzano.
  ///
  /// Decisiones clave frente al manzano:
  /// - `flowering` → reproductiveEarly: prioriza fuego bacteriano, helada y
  ///   polinización (familia flor/bacterias del catálogo de pera).
  /// - `fruit_fill` → reproductiveMid (no grainFill): mantiene activos psila y
  ///   roña/Fabraea (foliares) JUNTO con carpocapsa, ácaros, golpe de sol,
  ///   cork spot y pudriciones (fruto), tal como pide el doc para llenado.
  /// - `post_harvest` NO se apaga: cae en lateSeason, que el catálogo de pera
  ///   cubre con psila tardía, ácaros/defoliación y pudriciones residuales.
  /// - `unknown` devuelve null: el motor opera conservador y con menor confianza
  ///   (sin bono de etapa), no bloquea.
  static PlantHealthStageBucket? _fromPearTree(String stage) {
    if (_matches(stage, const <String>['planting_transplant', 'root_establish'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['juvenile', 'budbreak'])) {
      return PlantHealthStageBucket.vegetativeEarly;
    }
    if (_matches(stage, const <String>['vegetative_growth'])) {
      return PlantHealthStageBucket.vegetativeMid;
    }
    if (_matches(stage, const <String>['flowering'])) {
      return PlantHealthStageBucket.reproductiveEarly;
    }
    // fruit_set y fruit_fill comparten bucket reproductiveMid: ambos conservan
    // riesgos foliares (psila/roña) y de fruto (carpocapsa/calidad).
    if (_matches(stage, const <String>['fruit_set', 'fruit_fill'])) {
      return PlantHealthStageBucket.reproductiveMid;
    }
    // post_harvest debe evaluarse ANTES que harvest (contiene "harvest").
    if (_matches(stage, const <String>['post_harvest', 'dormancy'])) {
      return PlantHealthStageBucket.lateSeason;
    }
    if (_matches(stage, const <String>['harvest_maturity', 'harvest'])) {
      return PlantHealthStageBucket.grainFill;
    }
    return null;
  }

  /// Durazno / duraznero perenne (doc 04 §12): mapea los TreeStageIds del
  /// durazno a los buckets del motor de sanidad para que cada etapa fenológica
  /// filtre/pondere sus riesgos propios, sin reusar el mapeo del manzano/pera.
  ///
  /// Decisiones clave (frutal de hueso/carozo):
  /// - `flowering` → reproductiveEarly: prioriza helada en flor, Monilinia
  ///   (blossom blight) y bajo cuajado (familia flor del catálogo de durazno).
  /// - `fruit_set` y `fruit_fill` → reproductiveMid: mantienen activos riesgos
  ///   foliares (torque/leaf curl, tiro de munición, mancha bacteriana, ácaros)
  ///   JUNTO con plagas/desórdenes de fruto (palomilla oriental, barrenador,
  ///   golpe de sol, split pit). El endurecimiento de hueso es subventana de
  ///   `fruit_fill`, no un stageId nuevo.
  /// - `post_harvest` NO se apaga: cae en lateSeason (reservas, ácaros,
  ///   defoliación, roya/tiro de munición, barrenadores, cancros residuales).
  /// - `harvest_maturity` → grainFill: pudrición café/Monilinia, pudriciones de
  ///   almacén, golpe de sol, rajado y daño de fruto cerca de cosecha.
  /// - `unknown` devuelve null: el motor opera conservador y con menor confianza
  ///   (sin bono de etapa), no bloquea.
  static PlantHealthStageBucket? _fromPeachTree(String stage) {
    if (_matches(stage, const <String>['planting_transplant', 'root_establish'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['juvenile', 'budbreak'])) {
      return PlantHealthStageBucket.vegetativeEarly;
    }
    if (_matches(stage, const <String>['vegetative_growth'])) {
      return PlantHealthStageBucket.vegetativeMid;
    }
    if (_matches(stage, const <String>['flowering'])) {
      return PlantHealthStageBucket.reproductiveEarly;
    }
    // fruit_set y fruit_fill comparten bucket reproductiveMid: ambos conservan
    // riesgos foliares (torque/shot hole) y de fruto (palomilla/calibre/calidad).
    if (_matches(stage, const <String>['fruit_set', 'fruit_fill'])) {
      return PlantHealthStageBucket.reproductiveMid;
    }
    // post_harvest debe evaluarse ANTES que harvest (contiene "harvest").
    if (_matches(stage, const <String>['post_harvest', 'dormancy'])) {
      return PlantHealthStageBucket.lateSeason;
    }
    if (_matches(stage, const <String>['harvest_maturity', 'harvest'])) {
      return PlantHealthStageBucket.grainFill;
    }
    return null;
  }

  /// Nogal pecanero perenne (doc 04 §11): mapea los TreeStageIds del nogal a los
  /// buckets del motor de sanidad para que cada etapa fenológica filtre/pondere
  /// sus riesgos propios, sin reusar el mapeo del manzano/pera/durazno.
  ///
  /// Decisiones clave (frutal de nuez):
  /// - `flowering` → reproductiveEarly: prioriza helada en flor, desincronía
  ///   floral/falta de polinizador y frío insuficiente (familia flor del nogal).
  /// - `fruit_set` y `fruit_fill` → reproductiveMid: mantienen activos riesgos
  ///   foliares (zinc/roseta, pulgón amarillo/negro, ácaros) JUNTO con plagas y
  ///   desórdenes de nuez/ruezno (barrenador de la nuez/ruezno, chinches, shuck
  ///   decline, estrés hídrico). El estado acuoso/endurecimiento de cáscara/
  ///   llenado de almendra son subventanas de `fruit_fill`, no stageIds nuevos.
  /// - `post_harvest` NO se apaga: cae en lateSeason (reservas, pulgón negro/
  ///   ácaros tardíos, defoliación, alternancia).
  /// - `harvest_maturity` → grainFill: shuckworm, picudo, chinches, decaimiento
  ///   de ruezno, manchado de almendra y sticktights cerca de cosecha.
  /// - `unknown` devuelve null: el motor opera conservador y con menor confianza
  ///   (sin bono de etapa), no bloquea.
  static PlantHealthStageBucket? _fromWalnutTree(String stage) {
    if (_matches(stage, const <String>['planting_transplant', 'root_establish'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['juvenile', 'budbreak'])) {
      return PlantHealthStageBucket.vegetativeEarly;
    }
    if (_matches(stage, const <String>['vegetative_growth'])) {
      return PlantHealthStageBucket.vegetativeMid;
    }
    if (_matches(stage, const <String>['flowering'])) {
      return PlantHealthStageBucket.reproductiveEarly;
    }
    if (_matches(stage, const <String>['fruit_set', 'fruit_fill'])) {
      return PlantHealthStageBucket.reproductiveMid;
    }
    // post_harvest debe evaluarse ANTES que harvest (contiene "harvest").
    if (_matches(stage, const <String>['post_harvest', 'dormancy'])) {
      return PlantHealthStageBucket.lateSeason;
    }
    if (_matches(stage, const <String>['harvest_maturity', 'harvest'])) {
      return PlantHealthStageBucket.grainFill;
    }
    return null;
  }

  static PlantHealthStageBucket _fromGarlic(String stage, int? day) {
    if (_matches(stage, const <String>['plant', 'clove', 'diente'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['emerg', 'establec'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['veget', 'foliar'])) {
      if (day != null) {
        if (day <= 35) return PlantHealthStageBucket.vegetativeEarly;
        if (day <= 70) return PlantHealthStageBucket.vegetativeMid;
      }
      return PlantHealthStageBucket.vegetativeMid;
    }
    if (_matches(stage, const <String>['vernal', 'frio', 'cold'])) {
      return PlantHealthStageBucket.vegetativeLate;
    }
    if (_matches(stage, const <String>['diferenci', 'clove_diff'])) {
      return PlantHealthStageBucket.reproductiveEarly;
    }
    if (_matches(stage, const <String>['llenado', 'bulb_fill', 'fill'])) {
      return PlantHealthStageBucket.reproductiveMid;
    }
    if (_matches(stage, const <String>[
      'madur',
      'matur',
      'cosech',
      'harvest',
      'curado',
      'curing',
    ])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>[
      'escapo',
      'canuto',
      'escobete',
      'broom',
      'scape',
      'senesc',
    ])) {
      return PlantHealthStageBucket.lateSeason;
    }
    if (day != null) {
      if (day <= 14) return PlantHealthStageBucket.seedling;
      if (day <= 45) return PlantHealthStageBucket.vegetativeEarly;
      if (day <= 80) return PlantHealthStageBucket.vegetativeMid;
      if (day <= 115) return PlantHealthStageBucket.vegetativeLate;
      if (day <= 145) return PlantHealthStageBucket.reproductiveEarly;
      if (day <= 175) return PlantHealthStageBucket.reproductiveMid;
      if (day <= 205) return PlantHealthStageBucket.grainFill;
    }
    return PlantHealthStageBucket.lateSeason;
  }

  /// Cebolla: hortaliza de bulbo fotoperiodica con 8 etapas + espigado. No
  /// hay floracion productiva: la induccion y el bulbo se mapean a buckets
  /// vegetativos tardios y reproductivos; maduracion/cosecha cae en
  /// grainFill (organ fill del bulbo) y el espigado en lateSeason.
  static PlantHealthStageBucket _fromOnion(String stage, int? day) {
    if (_matches(stage, const <String>['germin'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['emerg'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['establec', 'transplant'])) {
      return PlantHealthStageBucket.vegetativeEarly;
    }
    if (_matches(stage, const <String>['induccion', 'pre_bulb', 'prebulb'])) {
      return PlantHealthStageBucket.vegetativeLate;
    }
    if (_matches(stage, const <String>['iniciobulbo', 'bulb_init', 'initiation'])) {
      return PlantHealthStageBucket.reproductiveEarly;
    }
    if (_matches(stage, const <String>['llenado', 'bulb_fill', 'fill'])) {
      return PlantHealthStageBucket.reproductiveMid;
    }
    if (_matches(stage, const <String>[
      'madur',
      'maturity',
      'cosech',
      'harvest',
      'cuello',
      'curado',
    ])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>['espig', 'bolting', 'seedstalk', 'senesc'])) {
      return PlantHealthStageBucket.lateSeason;
    }
    if (_matches(stage, const <String>['vegetativo', 'vegetative', 'foliar'])) {
      if (day != null) {
        if (day <= 28) return PlantHealthStageBucket.vegetativeEarly;
        if (day <= 60) return PlantHealthStageBucket.vegetativeMid;
      }
      return PlantHealthStageBucket.vegetativeLate;
    }
    if (day != null) {
      if (day <= 10) return PlantHealthStageBucket.seedling;
      if (day <= 28) return PlantHealthStageBucket.vegetativeEarly;
      if (day <= 60) return PlantHealthStageBucket.vegetativeMid;
      if (day <= 90) return PlantHealthStageBucket.vegetativeLate;
      if (day <= 120) return PlantHealthStageBucket.reproductiveEarly;
      if (day <= 140) return PlantHealthStageBucket.grainFill;
    }
    return PlantHealthStageBucket.lateSeason;
  }

  /// Espinaca: hortaliza de hoja con 8 etapas. No se mapea a floracion
  /// productiva; madurez/ventana son buckets vegetativos tardios y el
  /// espigado cae en lateSeason.
  static PlantHealthStageBucket _fromSpinach(String stage, int? day) {
    if (_matches(stage, const <String>['germin'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['establec', 'emerg', 'transplant'])) {
      return PlantHealthStageBucket.seedling;
    }
    if (_matches(stage, const <String>['temprano', 'early'])) {
      return PlantHealthStageBucket.vegetativeEarly;
    }
    if (_matches(stage, const <String>['expansion', 'foliar'])) {
      return PlantHealthStageBucket.vegetativeMid;
    }
    if (_matches(stage, const <String>['madurez', 'maturity', 'comercial'])) {
      return PlantHealthStageBucket.vegetativeLate;
    }
    if (_matches(stage, const <String>['cosecha', 'ventana', 'harvest'])) {
      return PlantHealthStageBucket.grainFill;
    }
    if (_matches(stage, const <String>[
      'perdida',
      'sobremadur',
      'decline',
      'espig',
      'bolting',
      'senesc',
      'cierre',
    ])) {
      return PlantHealthStageBucket.lateSeason;
    }
    if (_matches(stage, const <String>['vegetativo', 'vegetative'])) {
      if (day != null) {
        if (day <= 18) return PlantHealthStageBucket.vegetativeEarly;
        if (day <= 34) return PlantHealthStageBucket.vegetativeMid;
      }
      return PlantHealthStageBucket.vegetativeLate;
    }
    if (day != null) {
      if (day <= 10) return PlantHealthStageBucket.seedling;
      if (day <= 22) return PlantHealthStageBucket.vegetativeEarly;
      if (day <= 38) return PlantHealthStageBucket.vegetativeMid;
      if (day <= 50) return PlantHealthStageBucket.vegetativeLate;
      if (day <= 68) return PlantHealthStageBucket.grainFill;
    }
    return PlantHealthStageBucket.lateSeason;
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
