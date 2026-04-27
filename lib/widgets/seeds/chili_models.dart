import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

enum ChiliUseType { fresh, dry, process }

enum ChiliMarketType {
  generic,
  jalapeno,
  serrano,
  poblanoAncho,
  chilacaPasilla,
  guajilloMirasol,
  arbolPuya,
  habanero,
  bellPepper,
}

enum ChiliEstablishmentMode { directSeed, transplant }

enum ChiliStageKey {
  germinacion,
  establecimiento,
  vegetativo,
  floracion,
  cuajado,
  llenado,
  cosechaProgresiva,
  finCiclo,
}

class ChiliProfile extends CropProfile {
  final ChiliMarketType marketType;
  final ChiliUseType chiliUseType;
  final ChiliEstablishmentMode defaultEstablishmentMode;
  final RangeInt floweringDays;
  final RangeInt harvestStartDays;
  final RangeInt endWindowDays;
  final String endActionLabel;
  final RangeDouble plantHeightM;
  final RangeInt densityPlantsPerHa;
  final RangeDouble referenceYieldTHa;
  final bool isGenericProfile;
  final bool isCapsicumChinense;
  final bool isDryDestination;

  const ChiliProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.marketType = ChiliMarketType.generic,
    this.chiliUseType = ChiliUseType.fresh,
    this.defaultEstablishmentMode = ChiliEstablishmentMode.transplant,
    this.floweringDays = const RangeInt(0, 0),
    this.harvestStartDays = const RangeInt(0, 0),
    this.endWindowDays = const RangeInt(0, 0),
    this.endActionLabel = 'Fin de ciclo',
    this.plantHeightM = const RangeDouble(0, 0),
    this.densityPlantsPerHa = const RangeInt(0, 0),
    this.referenceYieldTHa = const RangeDouble(0, 0),
    this.isGenericProfile = false,
    this.isCapsicumChinense = false,
    this.isDryDestination = false,
  }) : super(cropKey: CropKey.chili);
}

class ChiliStageBounds {
  final ChiliStageKey key;
  final int startDay;
  final int endDay;

  const ChiliStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  })  : assert(startDay >= 1),
        assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

class ChiliStageResult {
  final ChiliProfile profile;
  final ChiliStageKey stage;
  final int daySinceAnchor;
  final ChiliEstablishmentMode establishmentMode;
  final RangeInt floweringBand;
  final RangeInt harvestStartBand;
  final RangeInt endBand;
  final int expectedFloweringDay;
  final int expectedHarvestStartDay;
  final int expectedEndDay;
  final int expectedDaysToEnd;
  final double stageProgressPct;
  final List<SeedWindowKey> windowsNow;
  final ChiliStageKey? productiveState;
  final RangeDouble expectedPlantHeightTodayM;
  final String stageLabelEs;
  final String productiveStateLabelEs;
  final String heroAsset;
  final String helperCaption;

  const ChiliStageResult({
    required this.profile,
    required this.stage,
    required this.daySinceAnchor,
    required this.establishmentMode,
    required this.floweringBand,
    required this.harvestStartBand,
    required this.endBand,
    required this.expectedFloweringDay,
    required this.expectedHarvestStartDay,
    required this.expectedEndDay,
    required this.expectedDaysToEnd,
    required this.stageProgressPct,
    required this.windowsNow,
    required this.productiveState,
    required this.expectedPlantHeightTodayM,
    required this.stageLabelEs,
    required this.productiveStateLabelEs,
    required this.heroAsset,
    required this.helperCaption,
  });
}
