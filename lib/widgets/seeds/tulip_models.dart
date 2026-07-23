// lib/widgets/seeds/tulip_models.dart
//
// Modelos puros (Dart) para Tulipán. NO depende de Flutter.
//
// El Tulipán es una ornamental bulbosa perenne que BIO-G ejecuta con un
// RELOJ ANUAL tipo granos (Documento A §0, §5): fecha ancla → días
// transcurridos → ventanas de etapa por perfil → etapa actual → días al
// cierre. La diferencia biológica se conserva al final: la última etapa es
// `dormancy` (bulbo en reposo), NO cosecha ni eliminación. El motor se
// queda en dormancia indefinidamente hasta que el usuario inicia una nueva
// temporada (Documento A §1.3, §5.11).
//
// Este archivo espeja el patrón de `oat_models.dart` / `maize_models.dart`.

import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

// ---------------------------------------------------------------------------
// Tipo funcional del perfil (Documento A §22.4).
// ---------------------------------------------------------------------------
enum TulipUseType {
  gardenExterior,
  decorativeContainer,
  forcedIndoor,
  cutFlower,
  specialPremium,
  generic,
}

// ---------------------------------------------------------------------------
// Modo de establecimiento (Documento A §2.6, §22.3). Interpreta la fecha
// ancla del ciclo. NO cambia el contrato del motor: se guarda como
// `sowingModeId` y determina qué etiqueta de día se muestra
// ("desde plantación / desde inicio del frío / desde activación").
// ---------------------------------------------------------------------------
enum TulipEstablishmentMode {
  bulbPlanting,
  coolingStart,
  prechilledActivation,
  alreadySprouted,
  unknown,
}

// ---------------------------------------------------------------------------
// Etapas canónicas de una temporada (Documento A §5.1). NO existe `unknown`
// como etapa normal del enum: el motor anual siempre resuelve una etapa real
// cuando hay perfil + fecha ancla + día efectivo. Un stage id inválido se
// repara con fallback (`stage.fallback`), nunca deja al usuario atrapado.
// ---------------------------------------------------------------------------
enum TulipStageKey {
  bulbPlanting,
  rootingChilling,
  shootEmergence,
  vegetativeGrowth,
  stemElongation,
  budFormation,
  flowering,
  bulbRecharge,
  foliageSenescence,
  dormancy,
}

/// Ids canónicos de etapa en snake_case. Son la fuente de verdad compartida
/// por assets, targets, sanidad y pantallas. `fallback` es SOLO protección
/// ante datos heredados / ids inválidos (Documento A §5.1, §12.5); no es una
/// etapa por la que el ciclo transite normalmente.
class TulipStageIds {
  const TulipStageIds._();

  static const String bulbPlanting = 'bulb_planting';
  static const String rootingChilling = 'rooting_chilling';
  static const String shootEmergence = 'shoot_emergence';
  static const String vegetativeGrowth = 'vegetative_growth';
  static const String stemElongation = 'stem_elongation';
  static const String budFormation = 'bud_formation';
  static const String flowering = 'flowering';
  static const String bulbRecharge = 'bulb_recharge';
  static const String foliageSenescence = 'foliage_senescence';
  static const String dormancy = 'dormancy';

  /// Banda conservadora por confirmar. NO es una etapa del ciclo.
  static const String fallback = 'fallback';

  static const List<String> ordered = <String>[
    bulbPlanting,
    rootingChilling,
    shootEmergence,
    vegetativeGrowth,
    stemElongation,
    budFormation,
    flowering,
    bulbRecharge,
    foliageSenescence,
    dormancy,
  ];
}

/// Id canónico snake_case de una etapa.
String tulipStageIdFor(TulipStageKey stage) {
  switch (stage) {
    case TulipStageKey.bulbPlanting:
      return TulipStageIds.bulbPlanting;
    case TulipStageKey.rootingChilling:
      return TulipStageIds.rootingChilling;
    case TulipStageKey.shootEmergence:
      return TulipStageIds.shootEmergence;
    case TulipStageKey.vegetativeGrowth:
      return TulipStageIds.vegetativeGrowth;
    case TulipStageKey.stemElongation:
      return TulipStageIds.stemElongation;
    case TulipStageKey.budFormation:
      return TulipStageIds.budFormation;
    case TulipStageKey.flowering:
      return TulipStageIds.flowering;
    case TulipStageKey.bulbRecharge:
      return TulipStageIds.bulbRecharge;
    case TulipStageKey.foliageSenescence:
      return TulipStageIds.foliageSenescence;
    case TulipStageKey.dormancy:
      return TulipStageIds.dormancy;
  }
}

/// Resuelve una `TulipStageKey` desde un id de texto libre (canónico,
/// nombre de enum camelCase, o alias legacy). Devuelve null si no coincide.
TulipStageKey? tulipStageKeyFromId(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return null;
  switch (v) {
    case 'bulb_planting':
    case 'bulbplanting':
    case 'planting':
    case 'plantacion':
    case 'plantación':
      return TulipStageKey.bulbPlanting;
    case 'rooting_chilling':
    case 'rootingchilling':
    case 'rooting':
    case 'chilling':
    case 'enraizado':
    case 'frio':
    case 'frío':
      return TulipStageKey.rootingChilling;
    case 'shoot_emergence':
    case 'shootemergence':
    case 'emergence':
    case 'emergencia':
    case 'brote':
      return TulipStageKey.shootEmergence;
    case 'vegetative_growth':
    case 'vegetativegrowth':
    case 'vegetative':
    case 'vegetativo':
    case 'hojas':
      return TulipStageKey.vegetativeGrowth;
    case 'stem_elongation':
    case 'stemelongation':
    case 'elongation':
    case 'elongacion':
    case 'elongación':
    case 'tallo':
      return TulipStageKey.stemElongation;
    case 'bud_formation':
    case 'budformation':
    case 'bud':
    case 'boton':
    case 'botón':
      return TulipStageKey.budFormation;
    case 'flowering':
    case 'flower':
    case 'floracion':
    case 'floración':
    case 'flor':
      return TulipStageKey.flowering;
    case 'bulb_recharge':
    case 'bulbrecharge':
    case 'recharge':
    case 'recarga':
      return TulipStageKey.bulbRecharge;
    case 'foliage_senescence':
    case 'foliagesenescence':
    case 'senescence':
    case 'senescencia':
    case 'amarillamiento':
      return TulipStageKey.foliageSenescence;
    case 'dormancy':
    case 'dormant':
    case 'dormancia':
    case 'reposo':
      return TulipStageKey.dormancy;
    default:
      return null;
  }
}

/// Normaliza cualquier id de etapa al canónico snake_case. Un id
/// desconocido devuelve `TulipStageIds.fallback` (protección, Documento A
/// §12.5), nunca lanza ni deja un id crudo.
String normalizeTulipStageId(String? raw) {
  final key = tulipStageKeyFromId(raw);
  if (key != null) return tulipStageIdFor(key);
  final v = raw?.trim().toLowerCase();
  if (v == 'fallback' || v == 'unknown' || v == 'desconocido') {
    return TulipStageIds.fallback;
  }
  return TulipStageIds.fallback;
}

/// Nombre visible en español de la etapa (Documento A §5). Nunca muestra el
/// id interno ni jerga.
String tulipStageDisplayName(String? stageId) {
  final key = tulipStageKeyFromId(stageId);
  switch (key) {
    case TulipStageKey.bulbPlanting:
      return 'Bulbo recién plantado';
    case TulipStageKey.rootingChilling:
      return 'Enraizando y acumulando frío';
    case TulipStageKey.shootEmergence:
      return 'Emergencia del brote';
    case TulipStageKey.vegetativeGrowth:
      return 'Crecimiento de hojas';
    case TulipStageKey.stemElongation:
      return 'Alargando el tallo';
    case TulipStageKey.budFormation:
      return 'Botón floral';
    case TulipStageKey.flowering:
      return 'Floración';
    case TulipStageKey.bulbRecharge:
      return 'Recargando el bulbo';
    case TulipStageKey.foliageSenescence:
      return 'Hojas amarilleando';
    case TulipStageKey.dormancy:
      return 'Bulbo en reposo';
    case null:
      return 'Etapa por confirmar';
  }
}

/// Etiqueta del día según el modo de ancla (Documento A §13.6): NO siempre
/// dice "desde siembra".
String tulipDayCounterLabel(TulipEstablishmentMode mode, int day) {
  switch (mode) {
    case TulipEstablishmentMode.coolingStart:
      return 'Día $day desde el inicio del frío';
    case TulipEstablishmentMode.prechilledActivation:
    case TulipEstablishmentMode.alreadySprouted:
      return 'Día $day desde la activación';
    case TulipEstablishmentMode.bulbPlanting:
    case TulipEstablishmentMode.unknown:
      return 'Día $day desde la plantación';
  }
}

/// Resuelve un `TulipEstablishmentMode` desde `sowingModeId` de texto libre.
TulipEstablishmentMode tulipEstablishmentModeFromId(String? raw) {
  final v = raw?.trim().toLowerCase();
  switch (v) {
    case 'cooling_start':
    case 'coolingstart':
      return TulipEstablishmentMode.coolingStart;
    case 'prechilled_activation':
    case 'prechilledactivation':
      return TulipEstablishmentMode.prechilledActivation;
    case 'already_sprouted':
    case 'alreadysprouted':
      return TulipEstablishmentMode.alreadySprouted;
    case 'bulb_planting':
    case 'bulbplanting':
      return TulipEstablishmentMode.bulbPlanting;
    default:
      return TulipEstablishmentMode.unknown;
  }
}

/// Id canónico de `sowingModeId` para un modo de establecimiento.
String tulipEstablishmentModeId(TulipEstablishmentMode mode) {
  switch (mode) {
    case TulipEstablishmentMode.bulbPlanting:
      return 'bulb_planting';
    case TulipEstablishmentMode.coolingStart:
      return 'cooling_start';
    case TulipEstablishmentMode.prechilledActivation:
      return 'prechilled_activation';
    case TulipEstablishmentMode.alreadySprouted:
      return 'already_sprouted';
    case TulipEstablishmentMode.unknown:
      return 'unknown';
  }
}

// ---------------------------------------------------------------------------
// Perfil del Tulipán (Documento A §10.1). Guarda límites de FIN de etapa
// (día absoluto desde la fecha ancla), como el Frijol guarda sus ventanas.
// La etapa `dormancy` empieza tras `senescenceEndDay` y no necesita un final.
// ---------------------------------------------------------------------------
class TulipProfile extends CropProfile {
  final TulipUseType tulipUseType;
  final TulipEstablishmentMode defaultEstablishmentMode;

  final int plantingEndDay;
  final int rootingChillingEndDay;
  final int emergenceEndDay;
  final int vegetativeEndDay;
  final int stemElongationEndDay;
  final int budEndDay;
  final int floweringEndDay;
  final int rechargeEndDay;
  final int senescenceEndDay;

  /// Ventana de floración esperada (día absoluto desde el ancla).
  final RangeInt floweringWindowDays;

  /// Pista de perennización (Documento A §8.2, §9.3): 'low' | 'medium' | 'high'.
  final String perennializingHint;

  /// El perfil expone una ventana de corte (solo flor de corte, Documento A
  /// §8.5, §16). NO activa proyección de rendimiento.
  final bool supportsCutWindow;

  const TulipProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.tulipUseType = TulipUseType.generic,
    this.defaultEstablishmentMode = TulipEstablishmentMode.unknown,
    required this.plantingEndDay,
    required this.rootingChillingEndDay,
    required this.emergenceEndDay,
    required this.vegetativeEndDay,
    required this.stemElongationEndDay,
    required this.budEndDay,
    required this.floweringEndDay,
    required this.rechargeEndDay,
    required this.senescenceEndDay,
    this.floweringWindowDays = const RangeInt(0, 0),
    this.perennializingHint = 'medium',
    this.supportsCutWindow = false,
  }) : super(cropKey: CropKey.tulip);

  /// Primer día de la ventana de floración (inicio de `flowering`).
  int get floweringStartDay => budEndDay + 1;

  /// Primer día de dormancia (día en que cierra la temporada aérea).
  int get dormancyStartDay => senescenceEndDay + 1;
}

// ---------------------------------------------------------------------------
// Límites de etapa (día absoluto desde el ancla).
// ---------------------------------------------------------------------------
class TulipStageBounds {
  final TulipStageKey key;
  final int startDay;
  final int endDay;

  const TulipStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  }) : assert(startDay >= 1),
       assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

// ---------------------------------------------------------------------------
// Resultado del motor para una lectura. Espeja `OatStageResult`, con las
// diferencias del bulbo: `stageProgressPct` es null en dormancia (no hay un
// final universal, Documento A §12.3) y no hay banda de "fin/cosecha".
// ---------------------------------------------------------------------------
class TulipStageResult {
  final TulipProfile profile;
  final TulipStageKey stage;

  /// Día desde la fecha ancla (1-based).
  final int daySinceAnchor;

  /// Modo de establecimiento efectivo (para la etiqueta del día).
  final TulipEstablishmentMode establishmentMode;

  final RangeInt floweringWindow;
  final int expectedFloweringDay;

  /// Día en que empieza la dormancia (cierre de la temporada aérea).
  final int expectedDormancyStartDay;

  /// Días aproximados al PRÓXIMO hito de la temporada (Documento A §13):
  /// a floración antes de florecer, a recarga/senescencia después, a
  /// dormancia en senescencia, y 0 en dormancia.
  final int expectedDaysToEnd;

  /// Progreso dentro de la etapa (0..1). Null en dormancia.
  final double? stageProgressPct;

  final List<SeedWindowKey> windowsNow;

  final String stageId;
  final String stageLabelEs;
  final String heroAsset;
  final String helperCaption;

  const TulipStageResult({
    required this.profile,
    required this.stage,
    required this.daySinceAnchor,
    required this.establishmentMode,
    required this.floweringWindow,
    required this.expectedFloweringDay,
    required this.expectedDormancyStartDay,
    required this.expectedDaysToEnd,
    required this.stageProgressPct,
    required this.windowsNow,
    required this.stageId,
    required this.stageLabelEs,
    required this.heroAsset,
    required this.helperCaption,
  });

  bool get isDormant => stage == TulipStageKey.dormancy;
  bool get isFlowering => stage == TulipStageKey.flowering;
}
