import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

enum EggplantUseType { fresh }

/// Market/UX profile used by the biological engine.
///
/// Important:
/// - "Berenjena italiana / clásica morada" is NOT a separate biological
///   engine in v1.
/// - It maps to [ovalRound] / BE-02 because it behaves as a classic purple
///   oval/large-fruit eggplant profile.
enum EggplantMarketType { generic, longPurple, ovalRound, striped, white }

enum EggplantEstablishmentMode { seed, transplant, unknown }

enum EggplantStageKey {
  germinacion,
  establecimiento,
  vegetativo,
  floracion,
  cuajado,
  llenado,
  cosechaProgresiva,
  finCiclo,
}

class EggplantProfile extends CropProfile {
  final EggplantMarketType marketType;
  final EggplantUseType eggplantUseType;
  final EggplantEstablishmentMode defaultEstablishmentMode;
  final RangeInt floweringDays;
  final RangeInt harvestStartDays;
  final RangeInt endWindowDays;
  final String endActionLabel;
  final RangeDouble plantHeightM;
  final RangeInt densityPlantsPerHa;
  final RangeDouble referenceYieldTHa;
  final bool isGenericProfile;
  final bool visualQualitySensitive;

  const EggplantProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.marketType = EggplantMarketType.generic,
    this.eggplantUseType = EggplantUseType.fresh,
    this.defaultEstablishmentMode = EggplantEstablishmentMode.transplant,
    this.floweringDays = const RangeInt(0, 0),
    this.harvestStartDays = const RangeInt(0, 0),
    this.endWindowDays = const RangeInt(0, 0),
    this.endActionLabel = 'Fin de ciclo',
    this.plantHeightM = const RangeDouble(0, 0),
    this.densityPlantsPerHa = const RangeInt(0, 0),
    this.referenceYieldTHa = const RangeDouble(0, 0),
    this.isGenericProfile = false,
    this.visualQualitySensitive = false,
  }) : super(cropKey: CropKey.eggplant);
}

class EggplantStageBounds {
  final EggplantStageKey key;
  final int startDay;
  final int endDay;

  const EggplantStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  }) : assert(startDay >= 1),
       assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

class EggplantStageResult {
  final EggplantProfile profile;
  final EggplantStageKey stage;
  final int daySinceAnchor;
  final EggplantEstablishmentMode establishmentMode;
  final RangeInt floweringBand;
  final RangeInt harvestStartBand;
  final RangeInt endBand;
  final int expectedFloweringDay;
  final int expectedHarvestStartDay;
  final int expectedEndDay;
  final int expectedDaysToEnd;
  final double stageProgressPct;
  final List<SeedWindowKey> windowsNow;
  final EggplantStageKey? productiveState;
  final RangeDouble expectedPlantHeightTodayM;
  final String stageLabelEs;
  final String productiveStateLabelEs;
  final String heroAsset;
  final String helperCaption;

  const EggplantStageResult({
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
