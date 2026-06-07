import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

/// Organo/destino comercial dentro del cultivo madre espinaca.
///
/// `flexible` se usa para SP-GEN: BIO-G no asume baby leaf, manojo ni
/// industria hasta que el usuario confirma el tipo comercial.
enum SpinachUseType { freshLeaf, babyLeaf, bunching, processing, flexible }

/// Tipo comercial UX dentro de `CropKey.spinach`.
///
/// En BIO-G v1 no existen cultivos separados como crop_baby_spinach ni
/// crop_processing_spinach. Todo vive dentro de `CropKey.spinach` como
/// perfil SP-GEN..SP-05.
enum SpinachMarketType {
  generic, // SP-GEN
  savoySummer, // SP-01
  savoyWinter, // SP-02
  smoothBaby, // SP-03
  orientalBunching, // SP-04
  processing, // SP-05
}

enum SpinachEstablishmentMode { directSeed, transplant, unknown }

/// Etapas operativas BIO-G de espinaca.
///
/// La espinaca es hortaliza de hoja: no tiene floracion productiva util.
/// El espigado / bolting se modela como evento de perdida de calidad.
enum SpinachStageKey {
  germinacion, // E1
  establecimiento, // E2
  vegetativoTemprano, // E3
  expansionFoliar, // E4
  madurezComercial, // E5
  ventanaCosecha, // E6
  perdidaCalidad, // E7
  espigadoSenescencia, // E8, cierre por calidad
}

enum SpinachBoltingRisk { bajo, medio, alto, critico }

enum SpinachHarvestStatus {
  aunNo,
  cercana,
  enVentana,
  urgente,
  pasada,
}

class SpinachProfile extends CropProfile {
  final SpinachMarketType marketType;
  final SpinachUseType spinachUseType;
  final SpinachEstablishmentMode defaultEstablishmentMode;

  /// Edad asumida si el usuario ancla el ciclo a trasplante.
  final int nurseryAgeDays;

  final int e2EndDay;
  final int e3EndDay;
  final int e4EndDay;
  final int e5EndDay;
  final int e6EndDay;
  final int e7EndDay;
  final int boltingSenescenceDays;

  final RangeInt cycleDays;
  final RangeInt densityPlantsPerHa;
  final RangeDouble referenceYieldTHa;

  final bool isGenericProfile;
  final bool isBabyLeaf;
  final bool isProcessing;
  final bool isBunching;

  /// Sensibilidad relativa a calidad visual/nitratos/CE (0..1).
  final double leafQualitySensitivity01;

  /// Sensibilidad relativa al espigado por calor/fotoperiodo/edad (0..1).
  final double boltingSensitivity01;

  /// Potencial de rebrote/cortes sucesivos en suelo (0..1).
  final double regrowthPotential01;

  const SpinachProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.marketType = SpinachMarketType.generic,
    this.spinachUseType = SpinachUseType.flexible,
    this.defaultEstablishmentMode = SpinachEstablishmentMode.directSeed,
    this.nurseryAgeDays = 18,
    required this.e2EndDay,
    required this.e3EndDay,
    required this.e4EndDay,
    required this.e5EndDay,
    required this.e6EndDay,
    required this.e7EndDay,
    this.boltingSenescenceDays = 14,
    this.cycleDays = const RangeInt(0, 0),
    this.densityPlantsPerHa = const RangeInt(0, 0),
    this.referenceYieldTHa = const RangeDouble(0, 0),
    this.isGenericProfile = false,
    this.isBabyLeaf = false,
    this.isProcessing = false,
    this.isBunching = false,
    this.leafQualitySensitivity01 = 0.75,
    this.boltingSensitivity01 = 0.70,
    this.regrowthPotential01 = 0.35,
  }) : super(cropKey: CropKey.spinach);
}

class SpinachStageBounds {
  final SpinachStageKey key;
  final int startDay;
  final int endDay;

  const SpinachStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  })  : assert(startDay >= 1),
        assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

class SpinachStageResult {
  final SpinachProfile profile;
  final SpinachStageKey stage;
  final int daySinceAnchor;
  final SpinachEstablishmentMode establishmentMode;
  final RangeInt harvestBand;
  final RangeInt qualityDeclineBand;
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

  const SpinachStageResult({
    required this.profile,
    required this.stage,
    required this.daySinceAnchor,
    required this.establishmentMode,
    required this.harvestBand,
    required this.qualityDeclineBand,
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
