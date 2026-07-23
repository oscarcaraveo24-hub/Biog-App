// lib/widgets/seeds/sunflower_models.dart
//
// Modelos puros (Dart) para Girasol. NO depende de Flutter.
//
// El Girasol (Helianthus annuus) es una ORNAMENTAL ANUAL VERDADERA que BIO-G
// ejecuta con un RELOJ ANUAL tipo granos (Documento A §0, §8, §9): fecha ancla
// (sowingDate) → días transcurridos → ventanas de etapa por perfil → etapa
// actual → progreso → días al final del ciclo. Espeja el patrón de
// `tulip_models.dart` / `oat_models.dart`, con UNA diferencia biológica clave
// frente al Tulipán: el final NO es dormancia sino `cycle_complete`, una etapa
// TERMINAL. La planta llega a senescencia, cierra su ciclo y NO reinicia por sí
// sola; una nueva temporada exige una nueva siembra explícita (Documento A §8.4,
// §8.5). No hay bulbo que sobreviva, no hay recarga y no hay reposo.

import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

// ---------------------------------------------------------------------------
// Tipo funcional del perfil (Documento A §5, §6).
// ---------------------------------------------------------------------------
enum SunflowerUseType {
  tallGarden,
  compactContainer,
  branchingOrnamental,
  cutFlowerSingleStem,
  generic,
}

// ---------------------------------------------------------------------------
// Modo de establecimiento (Documento A §4.4, §9.6, §9.7). Interpreta la fecha
// ancla del ciclo. NO cambia el contrato del motor: se guarda como
// `establishmentModeId` y solo ajusta la ETIQUETA del día y la estimación de la
// fecha de siembra (siembra directa vs. trasplante vs. planta comprada).
// ---------------------------------------------------------------------------
enum SunflowerEstablishmentMode {
  directSowing,
  transplant,
  purchasedPlant,
  unknown,
}

// ---------------------------------------------------------------------------
// Etapas canónicas del ciclo anual (Documento A §0.3, §10.1). `cycleComplete`
// es TERMINAL: cuando el día supera todas las ventanas, el motor conserva esta
// etapa indefinidamente, con progreso = 1.0 y días restantes = 0. NO existe
// `unknown` como etapa normal del enum: el motor anual siempre resuelve una
// etapa real con perfil + fecha ancla + día efectivo. Un stage id inválido se
// repara con `fallback` (Documento A §10.10), nunca deja al usuario atrapado.
// ---------------------------------------------------------------------------
enum SunflowerStageKey {
  sowing,
  germination,
  emergence,
  earlyVegetativeGrowth,
  activeVegetativeGrowth,
  stemElongation,
  budFormation,
  flowering,
  postBloom,
  senescence,
  cycleComplete,
}

/// Ids canónicos de etapa en snake_case (Documento A §0.3, §14.1). Son la fuente
/// de verdad compartida por assets, targets, sanidad y pantallas. `fallback` es
/// SOLO protección ante datos heredados / ids inválidos (Documento A §10.10); no
/// es una etapa por la que el ciclo transite normalmente. Debe auto-repararse
/// cuando exista una fecha o una estimación válida.
class SunflowerStageIds {
  const SunflowerStageIds._();

  static const String sowing = 'sowing';
  static const String germination = 'germination';
  static const String emergence = 'emergence';
  static const String earlyVegetativeGrowth = 'early_vegetative_growth';
  static const String activeVegetativeGrowth = 'active_vegetative_growth';
  static const String stemElongation = 'stem_elongation';
  static const String budFormation = 'bud_formation';
  static const String flowering = 'flowering';
  static const String postBloom = 'post_bloom';
  static const String senescence = 'senescence';
  static const String cycleComplete = 'cycle_complete';

  /// Banda conservadora "por confirmar". NO es una etapa del ciclo. En assets y
  /// textos se muestra como "Etapa por confirmar" (Documento A §14.1).
  static const String unknown = 'unknown';

  static const List<String> ordered = <String>[
    sowing,
    germination,
    emergence,
    earlyVegetativeGrowth,
    activeVegetativeGrowth,
    stemElongation,
    budFormation,
    flowering,
    postBloom,
    senescence,
    cycleComplete,
  ];
}

/// Id canónico snake_case de una etapa.
String sunflowerStageIdFor(SunflowerStageKey stage) {
  switch (stage) {
    case SunflowerStageKey.sowing:
      return SunflowerStageIds.sowing;
    case SunflowerStageKey.germination:
      return SunflowerStageIds.germination;
    case SunflowerStageKey.emergence:
      return SunflowerStageIds.emergence;
    case SunflowerStageKey.earlyVegetativeGrowth:
      return SunflowerStageIds.earlyVegetativeGrowth;
    case SunflowerStageKey.activeVegetativeGrowth:
      return SunflowerStageIds.activeVegetativeGrowth;
    case SunflowerStageKey.stemElongation:
      return SunflowerStageIds.stemElongation;
    case SunflowerStageKey.budFormation:
      return SunflowerStageIds.budFormation;
    case SunflowerStageKey.flowering:
      return SunflowerStageIds.flowering;
    case SunflowerStageKey.postBloom:
      return SunflowerStageIds.postBloom;
    case SunflowerStageKey.senescence:
      return SunflowerStageIds.senescence;
    case SunflowerStageKey.cycleComplete:
      return SunflowerStageIds.cycleComplete;
  }
}

/// Resuelve una `SunflowerStageKey` desde un id de texto libre (canónico, nombre
/// de enum camelCase, o alias legacy en español). Devuelve null si no coincide.
SunflowerStageKey? sunflowerStageKeyFromId(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return null;
  switch (v) {
    case 'sowing':
    case 'sow':
    case 'siembra':
    case 'por sembrar':
    case 'por_sembrar':
      return SunflowerStageKey.sowing;
    case 'germination':
    case 'germinacion':
    case 'germinación':
    case 'germinando':
      return SunflowerStageKey.germination;
    case 'emergence':
    case 'emergencia':
    case 'brote':
      return SunflowerStageKey.emergence;
    case 'early_vegetative_growth':
    case 'earlyvegetativegrowth':
    case 'early_vegetative':
    case 'primeras_hojas':
      return SunflowerStageKey.earlyVegetativeGrowth;
    case 'active_vegetative_growth':
    case 'activevegetativegrowth':
    case 'active_vegetative':
    case 'vegetative':
    case 'vegetativo':
      return SunflowerStageKey.activeVegetativeGrowth;
    case 'stem_elongation':
    case 'stemelongation':
    case 'elongation':
    case 'elongacion':
    case 'elongación':
    case 'tallo':
      return SunflowerStageKey.stemElongation;
    case 'bud_formation':
    case 'budformation':
    case 'bud':
    case 'boton':
    case 'botón':
      return SunflowerStageKey.budFormation;
    case 'flowering':
    case 'flower':
    case 'floracion':
    case 'floración':
    case 'flor':
      return SunflowerStageKey.flowering;
    case 'post_bloom':
    case 'postbloom':
    case 'post-bloom':
    case 'posfloracion':
    case 'posfloración':
      return SunflowerStageKey.postBloom;
    case 'senescence':
    case 'senescencia':
    case 'secado':
      return SunflowerStageKey.senescence;
    case 'cycle_complete':
    case 'cyclecomplete':
    case 'cycle_end':
    case 'complete':
    case 'ciclo_terminado':
    case 'terminado':
      return SunflowerStageKey.cycleComplete;
    default:
      return null;
  }
}

/// Normaliza cualquier id de etapa al canónico snake_case. Un id desconocido
/// devuelve `SunflowerStageIds.unknown` (protección, Documento A §10.10), nunca
/// lanza ni deja un id crudo.
String normalizeSunflowerStageId(String? raw) {
  final key = sunflowerStageKeyFromId(raw);
  if (key != null) return sunflowerStageIdFor(key);
  final v = raw?.trim().toLowerCase();
  if (v == 'unknown' || v == 'fallback' || v == 'desconocido') {
    return SunflowerStageIds.unknown;
  }
  return SunflowerStageIds.unknown;
}

/// Nombre visible en español de la etapa (Documento A §14.1). Nunca muestra el
/// id interno ni jerga (R1, BBCH, antesis). El estado `planned` sustituye la
/// etiqueta de `sowing` por "Por sembrar" en la capa de presentación.
String sunflowerStageDisplayName(String? stageId) {
  final key = sunflowerStageKeyFromId(stageId);
  switch (key) {
    case SunflowerStageKey.sowing:
      return 'Semilla recién sembrada';
    case SunflowerStageKey.germination:
      return 'Germinando';
    case SunflowerStageKey.emergence:
      return 'Emergencia del brote';
    case SunflowerStageKey.earlyVegetativeGrowth:
      return 'Primeras hojas';
    case SunflowerStageKey.activeVegetativeGrowth:
      return 'Creciendo con fuerza';
    case SunflowerStageKey.stemElongation:
      return 'Alargando el tallo';
    case SunflowerStageKey.budFormation:
      return 'Formando el botón';
    case SunflowerStageKey.flowering:
      return 'Floración';
    case SunflowerStageKey.postBloom:
      return 'Flor envejeciendo';
    case SunflowerStageKey.senescence:
      return 'Planta secándose';
    case SunflowerStageKey.cycleComplete:
      return 'Ciclo terminado';
    case null:
      return 'Etapa por confirmar';
  }
}

/// Etiqueta del día según el modo de establecimiento (Documento A §9.6): NO
/// siempre dice "desde siembra". El reloj SIEMPRE está anclado a la siembra,
/// pero cuando la fecha se estimó por trasplante o por planta comprada la
/// etiqueta lo comunica con honestidad.
String sunflowerDayCounterLabel(SunflowerEstablishmentMode mode, int day) {
  switch (mode) {
    case SunflowerEstablishmentMode.transplant:
      return 'Día $day desde la siembra (estimada por trasplante)';
    case SunflowerEstablishmentMode.purchasedPlant:
      return 'Día $day desde la siembra (estimada)';
    case SunflowerEstablishmentMode.directSowing:
    case SunflowerEstablishmentMode.unknown:
      return 'Día $day desde la siembra';
  }
}

/// Resuelve un `SunflowerEstablishmentMode` desde `establishmentModeId` /
/// `sowingModeId` de texto libre.
SunflowerEstablishmentMode sunflowerEstablishmentModeFromId(String? raw) {
  final v = raw?.trim().toLowerCase();
  switch (v) {
    case 'transplant':
    case 'transplante':
    case 'trasplante':
      return SunflowerEstablishmentMode.transplant;
    case 'purchased_plant':
    case 'purchasedplant':
    case 'comprada':
    case 'planta_comprada':
      return SunflowerEstablishmentMode.purchasedPlant;
    case 'direct_sowing':
    case 'directsowing':
    case 'siembra_directa':
      return SunflowerEstablishmentMode.directSowing;
    default:
      return SunflowerEstablishmentMode.unknown;
  }
}

/// Id canónico de `establishmentModeId` para un modo de establecimiento.
String sunflowerEstablishmentModeId(SunflowerEstablishmentMode mode) {
  switch (mode) {
    case SunflowerEstablishmentMode.directSowing:
      return 'direct_sowing';
    case SunflowerEstablishmentMode.transplant:
      return 'transplant';
    case SunflowerEstablishmentMode.purchasedPlant:
      return 'purchased_plant';
    case SunflowerEstablishmentMode.unknown:
      return 'unknown';
  }
}

// ---------------------------------------------------------------------------
// Perfil del Girasol (Documento A §11). Guarda límites de FIN de etapa (día
// absoluto desde la fecha ancla), como el Tulipán/Frijol guardan sus ventanas.
// La etapa `cycleComplete` empieza tras `senescenceEndDay` y es TERMINAL: no
// necesita un final. Los offsets de trasplante (Documento A §9.6) también se
// guardan aquí para la estimación de fecha en el wizard.
// ---------------------------------------------------------------------------
class SunflowerProfile extends CropProfile {
  final SunflowerUseType sunflowerUseType;
  final SunflowerEstablishmentMode defaultEstablishmentMode;

  final int sowingEndDay;
  final int germinationEndDay;
  final int emergenceEndDay;
  final int earlyVegetativeEndDay;
  final int activeVegetativeEndDay;
  final int stemElongationEndDay;
  final int budFormationEndDay;
  final int floweringEndDay;
  final int postBloomEndDay;
  final int senescenceEndDay;

  /// Ventana de floración esperada (día absoluto desde el ancla), solo para la
  /// lectura de la UI. NO promete una fecha exacta (Documento A §11.8).
  final RangeInt floweringWindowDays;

  /// Días típicos de plántula que se restan a la fecha de trasplante para
  /// estimar la siembra (Documento A §9.6). Estimación de onboarding, no una
  /// afirmación de edad real.
  final int transplantAgeOffsetDays;

  /// Perfil de corte de tallo único: habilita el evento explícito "Ya corté la
  /// flor" que cierra el ciclo (Documento A §6.4, §13.8). NO activa proyección
  /// de rendimiento ni cosecha.
  final bool supportsCutTermination;

  const SunflowerProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.sunflowerUseType = SunflowerUseType.generic,
    this.defaultEstablishmentMode = SunflowerEstablishmentMode.unknown,
    required this.sowingEndDay,
    required this.germinationEndDay,
    required this.emergenceEndDay,
    required this.earlyVegetativeEndDay,
    required this.activeVegetativeEndDay,
    required this.stemElongationEndDay,
    required this.budFormationEndDay,
    required this.floweringEndDay,
    required this.postBloomEndDay,
    required this.senescenceEndDay,
    this.floweringWindowDays = const RangeInt(0, 0),
    this.transplantAgeOffsetDays = 21,
    this.supportsCutTermination = false,
  }) : super(cropKey: CropKey.sunflower);

  /// Primer día de la ventana de floración (inicio de `flowering`).
  int get floweringStartDay => budFormationEndDay + 1;

  /// Primer día de `cycle_complete` (día en que el ciclo anual se da por
  /// terminado). Es también el "fin operativo" que usan los días restantes.
  int get cycleCompleteStartDay => senescenceEndDay + 1;
}

// ---------------------------------------------------------------------------
// Límites de etapa (día absoluto desde el ancla).
// ---------------------------------------------------------------------------
class SunflowerStageBounds {
  final SunflowerStageKey key;
  final int startDay;
  final int endDay;

  const SunflowerStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  }) : assert(startDay >= 1),
       assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

// ---------------------------------------------------------------------------
// Resultado del motor para una lectura. Espeja `TulipStageResult`, con las
// diferencias del anual verdadero: en `cycleComplete` el progreso es 1.0 (no
// null) y los días restantes son 0 (Documento A §11.9, §11.10).
// ---------------------------------------------------------------------------
class SunflowerStageResult {
  final SunflowerProfile profile;
  final SunflowerStageKey stage;

  /// Día desde la fecha ancla (1-based).
  final int daySinceAnchor;

  /// Modo de establecimiento efectivo (para la etiqueta del día).
  final SunflowerEstablishmentMode establishmentMode;

  final RangeInt floweringWindow;
  final int expectedFloweringDay;

  /// Día en que empieza `cycle_complete` (fin operativo del ciclo anual).
  final int expectedCycleCompleteDay;

  /// Días aproximados al fin del ciclo (0 en `cycle_complete`).
  final int expectedDaysToEnd;

  /// Progreso dentro de la etapa (0..1). Es 1.0 en `cycle_complete`.
  final double stageProgressPct;

  final List<SeedWindowKey> windowsNow;

  final String stageId;
  final String stageLabelEs;
  final String heroAsset;
  final String helperCaption;

  const SunflowerStageResult({
    required this.profile,
    required this.stage,
    required this.daySinceAnchor,
    required this.establishmentMode,
    required this.floweringWindow,
    required this.expectedFloweringDay,
    required this.expectedCycleCompleteDay,
    required this.expectedDaysToEnd,
    required this.stageProgressPct,
    required this.windowsNow,
    required this.stageId,
    required this.stageLabelEs,
    required this.heroAsset,
    required this.helperCaption,
  });

  bool get isCycleComplete => stage == SunflowerStageKey.cycleComplete;
  bool get isFlowering => stage == SunflowerStageKey.flowering;
}
