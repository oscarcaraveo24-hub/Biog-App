import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

/// Órgano/destino comercial dentro del cultivo madre lechuga.
///
/// `flexible` se usa para LE-GEN: BIO-G no asume cabeza ni baby leaf hasta
/// que el usuario confirma el tipo comercial.
enum LettuceUseType { headLeaf, looseLeaf, babyLeaf, flexible }

/// Tipo comercial UX dentro de `CropKey.lettuce`.
///
/// IMPORTANTE: en BIO-G v1 NO existe crop_romaine, crop_iceberg ni
/// crop_baby_leaf. Todos los nombres culturales (romana, cos, orejona,
/// bola, mantequilla, Little Gem, etc.) viven dentro de `CropKey.lettuce`
/// con perfil distinto LE-01..LE-05 / LE-GEN.
enum LettuceMarketType {
  generic, // LE-GEN
  romaine, // LE-01
  miniRomaine, // LE-02
  iceberg, // LE-03
  butterhead, // LE-04
  looseLeaf, // LE-05
}

/// Modo de establecimiento (dayZeroType del Perfil Universal §4).
enum LettuceEstablishmentMode { directSeed, transplant, unknown }

/// Etapas fenológicas BIO-G de lechuga.
///
/// La lechuga es hortaliza de hoja/cabeza: NO tiene floración productiva,
/// amarre ni llenado de fruto. Forzar esas etapas dispararía alertas
/// falsas, por eso `CropKey.lettuce` define su propio set de 6 etapas:
///   E1 germinación · E2 establecimiento · E3 desarrollo vegetativo ·
///   E4 formación de cabeza / madurez comercial · E5 ventana de cosecha ·
///   E6 sobre-madurez / senescencia.
///
/// El espigado (E7 del Perfil Universal) NO es una etapa productiva: es
/// un evento de falla fisiológica y se modela como [LettuceBoltingRisk]
/// en el motor AgroScore.
enum LettuceStageKey {
  germinacion, // E1
  establecimiento, // E2
  desarrolloVegetativo, // E3
  formacionCabeza, // E4
  ventanaCosecha, // E5
  sobremadurez, // E6
}

/// Nivel de riesgo de espigado / bolting (E7 como evento de falla).
enum LettuceBoltingRisk { bajo, medio, alto, critico }

/// Estado de la ventana de cosecha para mensajes de calidad.
enum LettuceHarvestStatus {
  aunNo, // falta para ventana
  cercana, // pre-cosecha, revisar campo
  enVentana, // punto óptimo
  urgente, // cosechar pronto (calor / bolting inminente)
  pasada, // sobre-madurez
}

/// Perfil biológico de lechuga dentro de `CropKey.lettuce`.
///
/// Todos los LE-XX comparten esta clase; `marketType` y `formsHead`
/// definen si la lectura se interpreta como cabeza, roseta o baby leaf.
/// Los anclajes de etapa (`e2EndDay`..`e5EndDay`) son días calendario
/// para siembra directa; en trasplante el motor suma `nurseryAgeDays`
/// para no tratar la planta como germinación desde cero.
class LettuceProfile extends CropProfile {
  final LettuceMarketType marketType;
  final LettuceUseType lettuceUseType;
  final LettuceEstablishmentMode defaultEstablishmentMode;

  /// True si el perfil forma cabeza/cogollo compacto (LE-01..LE-04).
  /// LE-05 hoja suelta = false: E4 se interpreta como madurez de roseta.
  final bool formsHead;

  /// Edad de plántula asumida al trasplantar (Perfil Universal §4).
  final int nurseryAgeDays;

  /// Fin de E2 establecimiento (día calendario, siembra directa).
  final int e2EndDay;

  /// Fin de E3 desarrollo vegetativo.
  final int e3EndDay;

  /// Fin de E4 formación de cabeza / madurez comercial temprana.
  final int e4EndDay;

  /// Fin de E5 ventana de cosecha; después comienza E6 sobre-madurez.
  final int e5EndDay;

  /// Duración orientativa de E6 sobre-madurez antes de cerrar ciclo.
  final int overMatureDays;

  /// Ciclo comercial orientativo para tarjetas (no es promesa).
  final RangeInt cycleDays;

  /// Peso fresco orientativo por planta (g) — contexto, no garantía.
  final RangeInt plantWeightG;

  final RangeInt densityPlantsPerHa;
  final RangeDouble referenceYieldTHa;

  final bool isGenericProfile;

  /// LE-05: hoja suelta / baby leaf. Puede ser 1 corte o multicorte.
  final bool isLooseLeaf;

  const LettuceProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.marketType = LettuceMarketType.generic,
    this.lettuceUseType = LettuceUseType.flexible,
    this.defaultEstablishmentMode = LettuceEstablishmentMode.transplant,
    this.formsHead = false,
    this.nurseryAgeDays = 21,
    required this.e2EndDay,
    required this.e3EndDay,
    required this.e4EndDay,
    required this.e5EndDay,
    this.overMatureDays = 18,
    this.cycleDays = const RangeInt(0, 0),
    this.plantWeightG = const RangeInt(0, 0),
    this.densityPlantsPerHa = const RangeInt(0, 0),
    this.referenceYieldTHa = const RangeDouble(0, 0),
    this.isGenericProfile = false,
    this.isLooseLeaf = false,
  }) : super(cropKey: CropKey.lettuce);
}

/// Límites de una etapa fenológica de lechuga en días calendario.
class LettuceStageBounds {
  final LettuceStageKey key;
  final int startDay;
  final int endDay;

  const LettuceStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  })  : assert(startDay >= 1),
        assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

/// Resultado fenológico calculado por `LettuceEngine`.
class LettuceStageResult {
  final LettuceProfile profile;
  final LettuceStageKey stage;
  final int daySinceAnchor;
  final LettuceEstablishmentMode establishmentMode;

  /// Ventana de cosecha estimada (días desde día 0).
  final RangeInt harvestBand;

  /// Inicio de sobre-madurez estimado.
  final RangeInt overMatureBand;

  final int expectedHarvestStartDay;
  final int expectedEndDay;
  final int expectedDaysToEnd;

  /// Rango de días faltantes para cosecha (no fecha única).
  final int daysToHarvestMin;
  final int daysToHarvestMax;

  final double stageProgressPct;
  final List<SeedWindowKey> windowsNow;

  final String stageLabelEs;
  final String heroAsset;
  final String helperCaption;

  const LettuceStageResult({
    required this.profile,
    required this.stage,
    required this.daySinceAnchor,
    required this.establishmentMode,
    required this.harvestBand,
    required this.overMatureBand,
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
