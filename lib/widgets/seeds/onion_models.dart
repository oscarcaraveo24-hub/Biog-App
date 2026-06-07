import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

/// Organo/destino comercial dentro del cultivo madre cebolla.
///
/// `flexible` se usa para ON-GEN: BIO-G no asume color, almacenamiento,
/// proceso ni cambray hasta que el usuario confirma el tipo comercial.
enum OnionUseType {
  dryBulbFresh,
  storageBulb,
  sweetFresh,
  processing,
  bunching,
  flexible,
}

/// Tipo comercial UX dentro de `CropKey.onion`.
///
/// En BIO-G v1 no existen cultivos separados por color ni por variedad
/// comercial. Todo vive dentro de `CropKey.onion` como perfil
/// ON-GEN..ON-05; las variedades son aliases hacia un perfil.
enum OnionMarketType {
  generic, // ON-GEN
  whiteShortDay, // ON-01
  yellowShortDay, // ON-02
  redShortDay, // ON-03
  intermediateTransition, // ON-04
  bunchingCambray, // ON-05
}

/// Modo de establecimiento. La edad por si sola NO garantiza bulbo en
/// cebolla; el modo cambia el reloj y la confianza del calendario.
enum OnionEstablishmentMode { directSeed, transplant, set, unknown }

/// Clase de fotoperiodo. Variable biologica dominante de cebolla: la
/// bulbificacion responde al largo del dia del grupo varietal, no solo
/// a la edad. `unknown` baja confianza y activa riesgo de no bulbificar.
enum OnionPhotoperiodClass { shortDay, intermediateDay, longDay, unknown }

/// Etapas operativas BIO-G de cebolla.
///
/// La cebolla es hortaliza de bulbo: la floracion/espigado NO es etapa
/// productiva; se modela como evento de perdida de calidad (espigado).
/// El organo objetivo es el bulbo (hoja + base en cambray ON-05).
enum OnionStageKey {
  germinacion, // E1
  emergencia, // E2 (establecimiento temprano)
  establecimiento, // E3
  vegetativo, // E4 (desarrollo foliar; fabrica del bulbo)
  induccionBulbificacion, // E5 (pre-bulbing; fotoperiodo manda)
  inicioBulbo, // E6 (bulb initiation)
  llenadoBulbo, // E7 (bulb fill; K/agua/calibre)
  maduracionCosecha, // E8 (cuello, maduracion, cosecha y curado)
  espigado, // Evento: seedstalk / bolting (perdida de calidad)
}

enum OnionBoltingRisk { bajo, medio, alto, critico }

enum OnionPhotoperiodMatch { compatible, watch, mismatch, unknown }

class OnionProfile extends CropProfile {
  final OnionMarketType marketType;
  final OnionUseType onionUseType;
  final OnionEstablishmentMode defaultEstablishmentMode;
  final OnionPhotoperiodClass photoperiodClass;

  /// Edad asumida si el usuario ancla el ciclo a trasplante.
  final int nurseryAgeDays;

  // Limites de fin de etapa (dias desde dia 0). La germinacion termina en
  // un dia fijo interno del motor; e2..e8 cierran las 7 etapas restantes.
  final int e2EndDay; // emergencia / establecimiento temprano
  final int e3EndDay; // establecimiento
  final int e4EndDay; // desarrollo vegetativo foliar
  final int e5EndDay; // induccion a bulbificacion
  final int e6EndDay; // inicio de bulbo
  final int e7EndDay; // llenado de bulbo
  final int e8EndDay; // maduracion / cuello / cosecha
  final int boltingEventDays;

  final RangeInt cycleDays;
  final RangeInt densityPlantsPerHa;
  final RangeDouble referenceYieldTHa;

  final bool isGenericProfile;

  /// ON-05: organo objetivo hoja + base; no exigir bulbo seco completo.
  final bool isBunching;

  /// ON-04 u otros perfiles con potencial de bodega/almacenamiento largo.
  final bool isStorageCapable;

  /// Sensibilidad relativa al fotoperiodo incorrecto (0..1). Alta para
  /// bulbo seco; baja para cambray/rama (cosecha joven).
  final double photoperiodSensitivity01;

  /// Sensibilidad relativa al espigado por frio/vernalizacion/edad (0..1).
  final double boltingSensitivity01;

  /// Sensibilidad relativa a calidad de bulbo: cuello, curado, color,
  /// pudriciones y descarte comercial (0..1).
  final double bulbQualitySensitivity01;

  /// Sensibilidad relativa a salinidad / CE (0..1). Cebolla es sensible.
  final double salinitySensitivity01;

  const OnionProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.marketType = OnionMarketType.generic,
    this.onionUseType = OnionUseType.flexible,
    this.defaultEstablishmentMode = OnionEstablishmentMode.unknown,
    this.photoperiodClass = OnionPhotoperiodClass.shortDay,
    this.nurseryAgeDays = 35,
    required this.e2EndDay,
    required this.e3EndDay,
    required this.e4EndDay,
    required this.e5EndDay,
    required this.e6EndDay,
    required this.e7EndDay,
    required this.e8EndDay,
    this.boltingEventDays = 14,
    this.cycleDays = const RangeInt(0, 0),
    this.densityPlantsPerHa = const RangeInt(0, 0),
    this.referenceYieldTHa = const RangeDouble(0, 0),
    this.isGenericProfile = false,
    this.isBunching = false,
    this.isStorageCapable = false,
    this.photoperiodSensitivity01 = 0.85,
    this.boltingSensitivity01 = 0.55,
    this.bulbQualitySensitivity01 = 0.75,
    this.salinitySensitivity01 = 0.80,
  }) : super(cropKey: CropKey.onion);
}

class OnionStageBounds {
  final OnionStageKey key;
  final int startDay;
  final int endDay;

  const OnionStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  })  : assert(startDay >= 1),
        assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

class OnionStageResult {
  final OnionProfile profile;
  final OnionStageKey stage;
  final int daySinceAnchor;
  final OnionEstablishmentMode establishmentMode;
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

  const OnionStageResult({
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
