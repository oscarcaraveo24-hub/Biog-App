// lib/widgets/seeds/marigold_models.dart
//
// Modelos puros (Dart) para Cempasúchil. NO depende de Flutter.
//
// El Cempasúchil (Tagetes erecta L.) es una ORNAMENTAL ANUAL VERDADERA que
// BIO-G ejecuta con un RELOJ ANUAL tipo granos (Documento A §0.3, §9): fecha
// ancla (sowingDate) → días transcurridos → ventanas de etapa por perfil →
// etapa actual → progreso → días al final del ciclo.
//
// Comparte el MODO (`annual_ornamental`) y el ESQUELETO NOMINAL de etapas con
// el Girasol para no duplicar el motor compartido (Documento A §9.2), pero NO
// comparte su biología: calendarios, targets, textos, assets, riesgos y
// perfiles son propios (Documento A §2.3).
//
// Diferencias explícitas frente al Girasol (Documento A §0.2 corrección 3,
// §6.2, §10.8):
//   - la floración es una VENTANA con apertura escalonada dentro de un solo
//     ciclo: una flor marchita NO cambia la etapa y retirar flores NO reinicia
//     nada;
//   - NO existe terminación por corte de tallo único: cortar una flor jamás
//     cierra el ciclo (Documento A §9.4);
//   - el fotoperiodo es CONTEXTO y modificador de calendario, nunca una etapa
//     ni una regla binaria (Documento A §11).
//
// Igual que el Girasol, el final es `cycle_complete`: una etapa TERMINAL. La
// planta cierra su ciclo y NO reinicia por sí sola; una nueva temporada exige
// una nueva siembra explícita (Documento A §0.3, §10.11). No hay dormancia, no
// hay bulbo, no hay cosecha y no hay rendimiento.

import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

// ---------------------------------------------------------------------------
// Tipo funcional del perfil (Documento A §5, §6). Los perfiles se separan por
// ARQUITECTURA, contexto radicular, calendario y ventana floral — nunca por
// color, tamaño de flor aislado ni por la palabra "africano" (§0.2 corrección
// 4, §5).
// ---------------------------------------------------------------------------
enum MarigoldUseType {
  traditionalField,
  tallCutFlower,
  compactContainer,
  landscapeBedding,
  generic,
}

// ---------------------------------------------------------------------------
// Modo de establecimiento (Documento A §13). Interpreta la fecha ancla del
// ciclo. NO cambia el contrato del motor: se guarda como `establishmentModeId`
// y solo ajusta la ETIQUETA del día y la estimación de la fecha de siembra
// (siembra directa vs. trasplante vs. planta comprada).
// ---------------------------------------------------------------------------
enum MarigoldEstablishmentMode {
  directSowing,
  transplant,
  purchasedPlant,
  unknown,
}

// ---------------------------------------------------------------------------
// Etapas canónicas del ciclo anual (Documento A §9.2, §9.4). `cycleComplete`
// es TERMINAL: cuando el día supera todas las ventanas, el motor conserva esta
// etapa indefinidamente, con progreso = 1.0 y días restantes = 0. NO existe
// `unknown` como etapa normal del enum: el motor anual siempre resuelve una
// etapa real con perfil + fecha ancla + día efectivo. Un stage id inválido se
// repara con la banda "por confirmar" (Documento A §10.12), nunca deja al
// usuario atrapado.
//
// NO existe `floral_induction`: la inducción es un proceso interno que el
// usuario no puede confirmar (Documento A §0.2 corrección 2).
// ---------------------------------------------------------------------------
enum MarigoldStageKey {
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

/// Ids canónicos de etapa en snake_case (Documento A §9.2). Son la fuente de
/// verdad compartida por assets, targets, sanidad y pantallas. `unknown` es
/// SOLO protección ante datos heredados / ids inválidos (Documento A §10.12);
/// no es una etapa por la que el ciclo transite normalmente. Debe
/// auto-repararse cuando exista una fecha o una estimación válida.
class MarigoldStageIds {
  const MarigoldStageIds._();

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
  /// textos se muestra como "Etapa por confirmar" (Documento A §9.3).
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
String marigoldStageIdFor(MarigoldStageKey stage) {
  switch (stage) {
    case MarigoldStageKey.sowing:
      return MarigoldStageIds.sowing;
    case MarigoldStageKey.germination:
      return MarigoldStageIds.germination;
    case MarigoldStageKey.emergence:
      return MarigoldStageIds.emergence;
    case MarigoldStageKey.earlyVegetativeGrowth:
      return MarigoldStageIds.earlyVegetativeGrowth;
    case MarigoldStageKey.activeVegetativeGrowth:
      return MarigoldStageIds.activeVegetativeGrowth;
    case MarigoldStageKey.stemElongation:
      return MarigoldStageIds.stemElongation;
    case MarigoldStageKey.budFormation:
      return MarigoldStageIds.budFormation;
    case MarigoldStageKey.flowering:
      return MarigoldStageIds.flowering;
    case MarigoldStageKey.postBloom:
      return MarigoldStageIds.postBloom;
    case MarigoldStageKey.senescence:
      return MarigoldStageIds.senescence;
    case MarigoldStageKey.cycleComplete:
      return MarigoldStageIds.cycleComplete;
  }
}

/// Resuelve una `MarigoldStageKey` desde un id de texto libre (canónico,
/// nombre de enum camelCase, o alias legacy en español). Devuelve null si no
/// coincide.
MarigoldStageKey? marigoldStageKeyFromId(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return null;
  switch (v) {
    case 'sowing':
    case 'sow':
    case 'siembra':
    case 'por sembrar':
    case 'por_sembrar':
      return MarigoldStageKey.sowing;
    case 'germination':
    case 'germinacion':
    case 'germinación':
    case 'germinando':
      return MarigoldStageKey.germination;
    case 'emergence':
    case 'emergencia':
    case 'emergiendo':
    case 'brote':
      return MarigoldStageKey.emergence;
    case 'early_vegetative_growth':
    case 'earlyvegetativegrowth':
    case 'early_vegetative':
    case 'plantula':
    case 'plántula':
    case 'primeras_hojas':
      return MarigoldStageKey.earlyVegetativeGrowth;
    case 'active_vegetative_growth':
    case 'activevegetativegrowth':
    case 'active_vegetative':
    case 'vegetative':
    case 'vegetativo':
    case 'ramificando':
      return MarigoldStageKey.activeVegetativeGrowth;
    case 'stem_elongation':
    case 'stemelongation':
    case 'elongation':
    case 'elongacion':
    case 'elongación':
    case 'porte':
    case 'tallo':
      return MarigoldStageKey.stemElongation;
    case 'bud_formation':
    case 'budformation':
    case 'bud':
    case 'boton':
    case 'botón':
    case 'botones':
      return MarigoldStageKey.budFormation;
    case 'flowering':
    case 'flower':
    case 'floracion':
    case 'floración':
    case 'flor':
      return MarigoldStageKey.flowering;
    case 'post_bloom':
    case 'postbloom':
    case 'post-bloom':
    case 'posfloracion':
    case 'posfloración':
      return MarigoldStageKey.postBloom;
    case 'senescence':
    case 'senescencia':
    case 'secado':
      return MarigoldStageKey.senescence;
    case 'cycle_complete':
    case 'cyclecomplete':
    case 'cycle_end':
    case 'complete':
    case 'ciclo_terminado':
    case 'terminado':
      return MarigoldStageKey.cycleComplete;
    default:
      return null;
  }
}

/// Normaliza cualquier id de etapa al canónico snake_case. Un id desconocido
/// devuelve `MarigoldStageIds.unknown` (protección, Documento A §10.12), nunca
/// lanza, nunca deja un id crudo y NUNCA hereda una etapa del Girasol.
String normalizeMarigoldStageId(String? raw) {
  final key = marigoldStageKeyFromId(raw);
  if (key != null) return marigoldStageIdFor(key);
  return MarigoldStageIds.unknown;
}

/// Nombre visible en español de la etapa (Documento A §9.3). Nunca muestra el
/// id interno ni jerga (BBCH, antesis, inducción floral). El estado `planned`
/// sustituye la etiqueta de `sowing` por "Por sembrar" en la capa de
/// presentación.
String marigoldStageDisplayName(String? stageId) {
  final key = marigoldStageKeyFromId(stageId);
  switch (key) {
    case MarigoldStageKey.sowing:
      return 'Siembra';
    case MarigoldStageKey.germination:
      return 'Germinando';
    case MarigoldStageKey.emergence:
      return 'Emergiendo';
    case MarigoldStageKey.earlyVegetativeGrowth:
      return 'Plántula creciendo';
    case MarigoldStageKey.activeVegetativeGrowth:
      return 'Creciendo y ramificando';
    case MarigoldStageKey.stemElongation:
      return 'Tomando porte';
    case MarigoldStageKey.budFormation:
      return 'Formando botones';
    case MarigoldStageKey.flowering:
      return 'En floración';
    case MarigoldStageKey.postBloom:
      return 'Flores envejeciendo';
    case MarigoldStageKey.senescence:
      return 'Cerrando el ciclo';
    case MarigoldStageKey.cycleComplete:
      return 'Ciclo terminado';
    case null:
      return 'Etapa por confirmar';
  }
}

/// Etiqueta del día según el modo de establecimiento (Documento A §13.1, §13.3):
/// NO siempre dice "desde siembra". El reloj SIEMPRE está anclado a la siembra,
/// pero cuando la fecha se estimó por trasplante o por planta comprada la
/// etiqueta lo comunica con honestidad.
String marigoldDayCounterLabel(MarigoldEstablishmentMode mode, int day) {
  switch (mode) {
    case MarigoldEstablishmentMode.transplant:
      return 'Día $day desde la siembra (estimada por trasplante)';
    case MarigoldEstablishmentMode.purchasedPlant:
      return 'Día $day desde la siembra (estimada)';
    case MarigoldEstablishmentMode.directSowing:
    case MarigoldEstablishmentMode.unknown:
      return 'Día $day desde la siembra';
  }
}

/// Resuelve un `MarigoldEstablishmentMode` desde `establishmentModeId` /
/// `sowingModeId` de texto libre.
MarigoldEstablishmentMode marigoldEstablishmentModeFromId(String? raw) {
  final v = raw?.trim().toLowerCase();
  switch (v) {
    case 'transplant':
    case 'transplante':
    case 'trasplante':
      return MarigoldEstablishmentMode.transplant;
    case 'purchased_plant':
    case 'purchasedplant':
    case 'comprada':
    case 'planta_comprada':
      return MarigoldEstablishmentMode.purchasedPlant;
    case 'direct_sowing':
    case 'directsowing':
    case 'siembra_directa':
      return MarigoldEstablishmentMode.directSowing;
    default:
      return MarigoldEstablishmentMode.unknown;
  }
}

/// Id canónico de `establishmentModeId` para un modo de establecimiento.
String marigoldEstablishmentModeId(MarigoldEstablishmentMode mode) {
  switch (mode) {
    case MarigoldEstablishmentMode.directSowing:
      return 'direct_sowing';
    case MarigoldEstablishmentMode.transplant:
      return 'transplant';
    case MarigoldEstablishmentMode.purchasedPlant:
      return 'purchased_plant';
    case MarigoldEstablishmentMode.unknown:
      return 'unknown';
  }
}

// ---------------------------------------------------------------------------
// Contexto de cultivo (Documento A §15.5). Describe el MEDIO, no la
// arquitectura: `cultivationContext` puede estrechar el pH de campo al rango de
// maceta (Documento B §7 regla de contexto), pero NUNCA cambia el perfil por sí
// solo (Documento A §7 reglas de compatibilidad).
// ---------------------------------------------------------------------------
enum MarigoldCultivationContext {
  pot,
  planter,
  gardenBed,
  landscape,
  nursery,
  openGround,
  unknown,
}

/// Resuelve un `MarigoldCultivationContext` desde texto libre.
MarigoldCultivationContext marigoldCultivationContextFromId(String? raw) {
  final v = raw?.trim().toLowerCase();
  switch (v) {
    case 'pot':
    case 'maceta':
      return MarigoldCultivationContext.pot;
    case 'planter':
    case 'jardinera':
      return MarigoldCultivationContext.planter;
    case 'garden_bed':
    case 'gardenbed':
    case 'cama':
    case 'jardin':
    case 'jardín':
      return MarigoldCultivationContext.gardenBed;
    case 'landscape':
    case 'paisaje':
    case 'camellon':
    case 'camellón':
      return MarigoldCultivationContext.landscape;
    case 'nursery':
    case 'vivero':
      return MarigoldCultivationContext.nursery;
    case 'open_ground':
    case 'openground':
    case 'suelo_directo':
    case 'campo':
    case 'surco':
      return MarigoldCultivationContext.openGround;
    default:
      return MarigoldCultivationContext.unknown;
  }
}

/// True cuando el medio es un CONTENEDOR (maceta, jardinera o vivero): volumen
/// radicular reducido, secado y saturación rápidos, más acumulación de sales y
/// pH más estrecho (Documento B §23.1).
bool marigoldContextIsContainer(MarigoldCultivationContext ctx) {
  switch (ctx) {
    case MarigoldCultivationContext.pot:
    case MarigoldCultivationContext.planter:
    case MarigoldCultivationContext.nursery:
      return true;
    case MarigoldCultivationContext.gardenBed:
    case MarigoldCultivationContext.landscape:
    case MarigoldCultivationContext.openGround:
    case MarigoldCultivationContext.unknown:
      return false;
  }
}

// ---------------------------------------------------------------------------
// Perfil del Cempasúchil (Documento A §12). Guarda límites de FIN de etapa (día
// absoluto desde la fecha ancla), como el Girasol/Tulipán guardan sus ventanas.
// La etapa `cycleComplete` empieza tras `senescenceEndDay` y es TERMINAL: no
// necesita un final. Los offsets de trasplante (Documento A §13.3) también se
// guardan aquí para la estimación de fecha en el wizard.
//
// NO existe `supportsCutTermination`: en Cempasúchil cortar una flor —o incluso
// la planta— es un EVENTO, nunca una terminación automática del ciclo
// (Documento A §9.4, §10.11, §14 caso E/F).
// ---------------------------------------------------------------------------
class MarigoldProfile extends CropProfile {
  final MarigoldUseType marigoldUseType;
  final MarigoldEstablishmentMode defaultEstablishmentMode;

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
  /// lectura de la UI. NO promete una fecha exacta y NO garantiza floración
  /// para una fecha cultural (Documento A §12, §13.5).
  final RangeInt floweringWindowDays;

  /// Días típicos de plántula que se restan a la fecha de trasplante para
  /// estimar la siembra (Documento A §13.3). Estimación de onboarding, no una
  /// afirmación de edad real.
  final int transplantAgeOffsetDays;

  /// La lectura de la sonda describe una ZONA del surco o de la cama, no toda
  /// la parcela (Documento B §3.2, §15). Los perfiles de campo, corte y paisaje
  /// lo marcan; el compacto de maceta no lo necesita porque la sonda representa
  /// una fracción grande del volumen.
  final bool sensorLocalCaution;

  /// Limita la prioridad NPK a lenguaje de REVISIÓN: ninguna lectura aislada
  /// escala a "acción recomendada" (Documento B §15 CS-SKIP, §20.1).
  final bool limitNpkPriorityToReview;

  const MarigoldProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.marigoldUseType = MarigoldUseType.generic,
    this.defaultEstablishmentMode = MarigoldEstablishmentMode.unknown,
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
    this.sensorLocalCaution = false,
    this.limitNpkPriorityToReview = false,
  }) : super(cropKey: CropKey.marigold);

  /// Primer día de la ventana de floración (inicio de `flowering`).
  int get floweringStartDay => budFormationEndDay + 1;

  /// Primer día de `cycle_complete` (día en que el ciclo anual se da por
  /// terminado). Es también el "fin operativo" que usan los días restantes.
  int get cycleCompleteStartDay => senescenceEndDay + 1;
}

// ---------------------------------------------------------------------------
// Límites de etapa (día absoluto desde el ancla).
// ---------------------------------------------------------------------------
class MarigoldStageBounds {
  final MarigoldStageKey key;
  final int startDay;
  final int endDay;

  const MarigoldStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  }) : assert(startDay >= 1),
       assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

// ---------------------------------------------------------------------------
// Resultado del motor para una lectura. Espeja `SunflowerStageResult`: en
// `cycleComplete` el progreso es 1.0 (no null) y los días restantes son 0
// (Documento A §10.11).
// ---------------------------------------------------------------------------
class MarigoldStageResult {
  final MarigoldProfile profile;
  final MarigoldStageKey stage;

  /// Día desde la fecha ancla (1-based).
  final int daySinceAnchor;

  /// Modo de establecimiento efectivo (para la etiqueta del día).
  final MarigoldEstablishmentMode establishmentMode;

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

  const MarigoldStageResult({
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

  bool get isCycleComplete => stage == MarigoldStageKey.cycleComplete;
  bool get isFlowering => stage == MarigoldStageKey.flowering;
}
