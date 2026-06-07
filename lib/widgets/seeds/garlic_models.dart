import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

/// Destino comercial dentro del cultivo madre ajo.
///
/// `flexible` se usa para AG-GEN: BIO-G no asume color, origen ni sistema
/// hasta que el usuario confirme el perfil. La variedad comercial es alias,
/// no un cultivo nuevo.
enum GarlicUseType {
  curedBulbFresh,
  storageBulb,
  seedClove,
  processing,
  flexible,
}

/// Tipo comercial UX dentro de `CropKey.garlic`.
enum GarlicMarketType {
  generic, // AG-GEN
  whitePearl, // AG-01
  jaspeadoCalera, // AG-02
  purple, // AG-03
  creoleRegional, // AG-04
  chineseKorean, // AG-05
}

/// Modo de establecimiento. El ajo se propaga por diente-semilla.
enum GarlicEstablishmentMode { clove, sproutedClove, unknown }

/// Necesidad relativa de frio/vernalizacion para diferenciar bulbo/dientes.
enum GarlicColdRequirementClass { low, medium, mediumHigh, high, unknown }

/// Morfologia de cuello/escapo usada como sensibilidad, no como subtipo.
enum GarlicNeckClass { softneck, semiHardneck, hardneck, unknown }

/// Etapas operativas BIO-G de ajo.
///
/// La vernalizacion es una ventana fisiologica critica: BIO-G no la corrige
/// con NPK. El escapo/canuto/escobeteado se modela como evento de riesgo o
/// perdida de calidad, no como etapa productiva deseada.
enum GarlicStageKey {
  clovePlanting,
  emergenceEstablishment,
  vegetativeLeafDevelopment,
  coldInductionVernalization,
  bulbDifferentiation,
  bulbFilling,
  bulbMaturation,
  harvest,
  curingRest,
  scapeBrooming,
}

enum GarlicScapeRisk { bajo, medio, alto, critico }

class GarlicProfile extends CropProfile {
  final GarlicMarketType marketType;
  final GarlicUseType garlicUseType;
  final GarlicEstablishmentMode defaultEstablishmentMode;
  final GarlicColdRequirementClass coldRequirementClass;
  final GarlicNeckClass neckClass;

  // Limites de fin de etapa (dias desde plantacion del diente).
  final int e2EndDay; // emergencia / establecimiento
  final int e3EndDay; // desarrollo vegetativo
  final int e4EndDay; // induccion por frio / vernalizacion
  final int e5EndDay; // diferenciacion de bulbo/dientes
  final int e6EndDay; // llenado de bulbo
  final int e7EndDay; // maduracion
  final int e8EndDay; // cosecha
  final int e9EndDay; // curado / reposo
  final int scapeEventDays;

  final RangeInt cycleDays;
  final RangeInt densityPlantsPerHa;
  final RangeDouble referenceYieldTHa;

  final bool isGenericProfile;
  final bool isStorageFocused;
  final bool isPremiumBulb;

  /// Sensibilidad relativa a mala vernalizacion (0..1).
  final double vernalizationSensitivity01;

  /// Sensibilidad relativa a escapo/canuto/escobeteado no esperado (0..1).
  final double scapeSensitivity01;

  /// Sensibilidad relativa a calibre, curado, descarte y almacenamiento (0..1).
  final double bulbQualitySensitivity01;

  /// Sensibilidad relativa a salinidad/CE (0..1).
  final double salinitySensitivity01;

  /// Riesgo relativo por diente-semilla de mala calidad o sanitario (0..1).
  final double seedCloveRisk01;

  const GarlicProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.marketType = GarlicMarketType.generic,
    this.garlicUseType = GarlicUseType.flexible,
    this.defaultEstablishmentMode = GarlicEstablishmentMode.clove,
    this.coldRequirementClass = GarlicColdRequirementClass.unknown,
    this.neckClass = GarlicNeckClass.unknown,
    required this.e2EndDay,
    required this.e3EndDay,
    required this.e4EndDay,
    required this.e5EndDay,
    required this.e6EndDay,
    required this.e7EndDay,
    required this.e8EndDay,
    required this.e9EndDay,
    this.scapeEventDays = 18,
    this.cycleDays = const RangeInt(0, 0),
    this.densityPlantsPerHa = const RangeInt(0, 0),
    this.referenceYieldTHa = const RangeDouble(0, 0),
    this.isGenericProfile = false,
    this.isStorageFocused = false,
    this.isPremiumBulb = false,
    this.vernalizationSensitivity01 = 0.75,
    this.scapeSensitivity01 = 0.55,
    this.bulbQualitySensitivity01 = 0.78,
    this.salinitySensitivity01 = 0.82,
    this.seedCloveRisk01 = 0.55,
  }) : super(cropKey: CropKey.garlic);
}

class GarlicStageBounds {
  final GarlicStageKey key;
  final int startDay;
  final int endDay;

  const GarlicStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  })  : assert(startDay >= 1),
        assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

class GarlicStageResult {
  final GarlicProfile profile;
  final GarlicStageKey stage;
  final int daySinceAnchor;
  final GarlicEstablishmentMode establishmentMode;
  final RangeInt harvestBand;
  final RangeInt curingBand;
  final int expectedHarvestStartDay;
  final int expectedEndDay;
  final int expectedDaysToEnd;
  final int daysToHarvestMin;
  final int daysToHarvestMax;
  final double stageProgressPct;
  final List<SeedWindowKey> windowsNow;
  final String stageLabelEs;
  final String heroAsset;
  final String helperCaption;

  const GarlicStageResult({
    required this.profile,
    required this.stage,
    required this.daySinceAnchor,
    required this.establishmentMode,
    required this.harvestBand,
    required this.curingBand,
    required this.expectedHarvestStartDay,
    required this.expectedEndDay,
    required this.expectedDaysToEnd,
    required this.daysToHarvestMin,
    required this.daysToHarvestMax,
    required this.stageProgressPct,
    required this.windowsNow,
    required this.stageLabelEs,
    required this.heroAsset,
    required this.helperCaption,
  });
}
