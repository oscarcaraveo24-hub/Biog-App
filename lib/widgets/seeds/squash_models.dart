import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

/// Destinos comerciales que CA-XX puede asumir.
///
/// `flexible` se usa para CA-GEN: el sistema no decide tierno, maduro o
/// pepita hasta que el usuario confirme corte o tipo.
enum SquashUseType { fruitTender, fruitMature, seedDry, flexible }

/// Tipo UX dentro del cultivo madre crop_squash.
///
/// IMPORTANTE: en BIO-G v1 NO existe CropKey.pumpkin separado. Todos los
/// nombres culturales (calabacita, Castilla, butternut, chilacayote,
/// pipián, etc.) viven dentro de `CropKey.squash` con perfil distinto.
enum SquashMarketType {
  generic,
  italianZucchini,
  criollaMilpa,
  ballRound,
  castillaPumpkin,
  butternut,
  chilacayote,
  pipianSeed,
}

enum SquashEstablishmentMode { seed, transplant, unknown }

/// Etapas BIO-G compatibles con el resto de hortalizas de fruto.
///
/// La rama `cosechaProgresiva` cubre tanto cortes repetidos de calabacita
/// tierna (CA-01/02/03) como cosechas únicas de fruto maduro
/// (CA-04/05/06/07): la lógica de planner decide el tono del mensaje.
enum SquashStageKey {
  germinacion,
  establecimiento,
  vegetativo,
  floracion,
  cuajado,
  llenado,
  cosechaProgresiva,
  finCiclo,
}

/// Perfil biológico de calabaza dentro de CropKey.squash.
///
/// Todos los CA-XX comparten esta clase; `marketType` y `useType` definen
/// si la lectura debe leerse como fruto tierno, fruto maduro o pepita.
class SquashProfile extends CropProfile {
  final SquashMarketType marketType;
  final SquashUseType squashUseType;
  final SquashEstablishmentMode defaultEstablishmentMode;
  final RangeInt floweringDays;
  final RangeInt harvestStartDays;
  final RangeInt endWindowDays;
  final String endActionLabel;
  final RangeDouble plantHeightM;
  final RangeInt densityPlantsPerHa;
  final RangeDouble referenceYieldTHa;
  final bool isGenericProfile;

  /// Indica que el perfil produce semilla seca (CA-07 pipián por defecto).
  ///
  /// El motor de rendimiento usa este flag para resolver la familia
  /// `squashSeed` y NO mezclar con t/ha de fruto fresco.
  final bool isSeedFocused;

  /// Tipos vigorosos / guía rastrera larga (CA-04/05/06/07): habilita
  /// densidad baja sin penalizar score.
  final bool isLongVining;

  /// Calabacitas de corte tierno con cosecha continua (CA-01/02/03).
  /// La cosecha progresiva debe leerse como activa, no como senescencia.
  final bool isContinuousHarvest;

  const SquashProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.marketType = SquashMarketType.generic,
    this.squashUseType = SquashUseType.flexible,
    this.defaultEstablishmentMode = SquashEstablishmentMode.seed,
    this.floweringDays = const RangeInt(0, 0),
    this.harvestStartDays = const RangeInt(0, 0),
    this.endWindowDays = const RangeInt(0, 0),
    this.endActionLabel = 'Fin de ciclo',
    this.plantHeightM = const RangeDouble(0, 0),
    this.densityPlantsPerHa = const RangeInt(0, 0),
    this.referenceYieldTHa = const RangeDouble(0, 0),
    this.isGenericProfile = false,
    this.isSeedFocused = false,
    this.isLongVining = false,
    this.isContinuousHarvest = false,
  }) : super(cropKey: CropKey.squash);
}

class SquashStageBounds {
  final SquashStageKey key;
  final int startDay;
  final int endDay;

  const SquashStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  })  : assert(startDay >= 1),
        assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

class SquashStageResult {
  final SquashProfile profile;
  final SquashStageKey stage;
  final int daySinceAnchor;
  final SquashEstablishmentMode establishmentMode;
  final RangeInt floweringBand;
  final RangeInt harvestStartBand;
  final RangeInt endBand;
  final int expectedFloweringDay;
  final int expectedHarvestStartDay;
  final int expectedEndDay;
  final int expectedDaysToEnd;
  final double stageProgressPct;
  final List<SeedWindowKey> windowsNow;
  final SquashStageKey? productiveState;
  final RangeDouble expectedPlantHeightTodayM;
  final String stageLabelEs;
  final String productiveStateLabelEs;
  final String heroAsset;
  final String helperCaption;

  const SquashStageResult({
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
