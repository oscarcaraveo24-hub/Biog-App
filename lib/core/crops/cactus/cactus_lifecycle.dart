import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Dominio del ciclo de vida ORNAMENTAL del Cactus (primera ornamental oficial
/// de BIO-G). Espejo estructural de `tree_lifecycle.dart`, pero con la semántica
/// propia de una planta ornamental xerófita en modo `establishment_maintenance`
/// (docs 01-05 del paquete Cactus CA v1.1).
///
/// Reglas no negociables (doc 01 §0.1, doc 03 §0.1):
/// - `maintenance` NUNCA se convierte en fin de ciclo (no `cycle_complete`).
/// - NO hay rendimiento, cosecha, kg/planta ni t/ha (supportsYieldProjection=false).
/// - El microciclo hídrico y los targets se interpretan con el HARDWARE como
///   fuente de verdad; la etapa solo modula la interpretación.
/// - `active_growth`, `rest`, estrés, recuperación, pudrición y declive NO se
///   infieren por fecha durante el onboarding: quedan disponibles en el dominio
///   para confirmación manual o reglas autorizadas posteriores.
class CactusLifecycle {
  const CactusLifecycle._();

  /// Modo de ciclo del cactus. No es siembra→cosecha: es establecimiento y
  /// luego mantenimiento indefinido.
  static const String lifecycleMode = 'establishment_maintenance';

  // ── Capacidades congeladas ──────────────────────────────────────────────────
  // Ver docs/ornamentales/GUIA_ORNAMENTALES_BIOG.md §7.2.
  static const bool supportsYieldProjection = false;
  static const bool supportsHarvest = false;
  static const bool supportsRecurringBloom = false;

  /// DESCARTADO en v1 (Guía §7.2). El microciclo hídrico (riego reciente,
  /// drenando, secándose, sequedad prolongada…) exige un baseline por
  /// dispositivo que BIO-G no tiene. La integración anterior persistía el estado
  /// sin calcularlo nunca: la UI mostraba eternamente "Patrón por aprender".
  /// El agua del cactus se interpreta con la lectura real de humedad contra los
  /// targets de la etapa, igual que en frijol.
  static const bool supportsHydricCycle = false;

  /// DESCARTADO en v1. La memoria de estrés nunca se computó: se persistía una
  /// lista vacía. No se declara una capacidad que no existe.
  static const bool supportsStressMemory = false;
}

/// Intenciones del wizard de Cactus. **Solo dos.**
///
/// Al agricultor se le pregunta lo mínimo: ¿la vas a plantar, o ya está
/// plantada? Nada más.
///
/// El "voy a cambiarlo de maceta" se ELIMINÓ: un cambio de maceta no es una
/// forma de dar de alta una planta, es un evento de mantenimiento de una planta
/// que YA está plantada. Ponerlo como tercera opción de alta confundía al
/// usuario y no aportaba nada al motor (producía el mismo contexto `planted`).
/// Los contextos antiguos que traigan `repot` se leen como `already_planted`.
class CactusSetupIntentIds {
  const CactusSetupIntentIds._();

  static const String plannedPlant = 'planned_plant';
  static const String alreadyPlanted = 'already_planted';

  static const Set<String> all = <String>{plannedPlant, alreadyPlanted};
}

/// Acepta los IDs actuales y los de versiones anteriores del wizard. Un valor
/// desconocido —incluido el `repot` ya retirado— se trata de forma conservadora
/// como una planta que ya existe, nunca como una plantación futura.
String normalizeCactusSetupIntentId(String? intentId) {
  final value = intentId?.trim().toLowerCase();
  return switch (value) {
    CactusSetupIntentIds.plannedPlant ||
    'planned' ||
    'plant' => CactusSetupIntentIds.plannedPlant,
    // 'repot' / 'transplant': intención retirada. La planta ya existe.
    CactusSetupIntentIds.alreadyPlanted ||
    'planted' ||
    'growing' ||
    'repot' ||
    'transplant' => CactusSetupIntentIds.alreadyPlanted,
    _ => CactusSetupIntentIds.alreadyPlanted,
  };
}

/// Solo "la voy a plantar" pide una fecha futura. "Ya está plantada" pide una
/// fecha pasada (o ninguna).
bool cactusSetupIntentRequiresFutureDate(String? intentId) {
  return normalizeCactusSetupIntentId(intentId) ==
      CactusSetupIntentIds.plannedPlant;
}

/// Etapas de vida ornamentales (doc 01 §2.1). Capa A: estado estable de vida.
class CactusStageIds {
  const CactusStageIds._();

  static const String installationEstablishment = 'installation_establishment';
  static const String rootEstablishment = 'root_establishment';
  static const String activeGrowth = 'active_growth';
  static const String maintenance = 'maintenance';
  static const String rest = 'rest';
  static const String unknown = 'unknown';

  static const Set<String> all = <String>{
    installationEstablishment,
    rootEstablishment,
    activeGrowth,
    maintenance,
    rest,
    unknown,
  };
}

/// Tipos de anclaje temporal del ciclo ornamental (doc 01 §5.1). NO es fecha de
/// siembra: es plantación/cambio de maceta o inicio aproximado de una etapa.
class CactusAnchorTypeIds {
  const CactusAnchorTypeIds._();

  static const String installation = 'installation';
  static const String repot = 'repot';
  static const String stageStart = 'stage_start';
  static const String manualStage = 'manual_stage';
  static const String unknown = 'unknown';
}

/// Confianza de una etapa estimada por fecha. La etapa derivada de la fecha es
/// SIEMPRE una estimación: su confianza está topada.
///
/// NOTA: el "microciclo hídrico" (riego reciente / drenando / secándose /
/// sequedad prolongada) fue ELIMINADO. Nunca se calculaba: el estado se
/// persistía como `unknown` y ningún motor lo actualizaba, así que la UI
/// mostraba siempre "Patrón por aprender · confianza baja". El agua del cactus
/// se interpreta ahora con la lectura real de humedad contra los targets de la
/// etapa, exactamente igual que en frijol.
class CactusStageConfidence {
  const CactusStageConfidence._();

  /// Etapa elegida/derivada con evento + fecha reciente (instalación).
  static const double byRecentAnchor = 0.45;

  /// Etapa derivada de la ventana de establecimiento por fecha.
  static const double byEstablishmentWindow = 0.40;

  /// Compatibilidad para una etapa de mantenimiento ya confirmada. La edad de
  /// una fecha nunca selecciona esta etapa automáticamente.
  static const double byMaintenanceWindow = 0.45;

  /// Sin fecha suficiente ("no lo recuerdo" / sin ancla).
  static const double unknown = 0.25;

  static String labelFor(double confidence) {
    if (confidence >= 0.60) return 'alta';
    if (confidence >= 0.40) return 'media';
    return 'baja';
  }
}

/// Resultado de estimar la etapa ornamental por fecha.
class CactusStageEstimate {
  const CactusStageEstimate({
    required this.stageId,
    required this.anchorTypeId,
    required this.confidence,
  });

  final String stageId;
  final String anchorTypeId;
  final double confidence;
}

// ── Ventanas orientativas por fecha (doc 01 §5.2) ────────────────────────────
//
// NO son transiciones automáticas: solo estiman la etapa inicial provisional en
// el onboarding. El columnar/ejemplar grande de paisaje establece más lento.

// Ventanas de la vida de la planta. NO es un ciclo: es una progresión que
// avanza una sola vez y desemboca en `maintenance`, donde se queda para
// siempre. No hay reinicio, no hay año que la regrese al principio.
//
//   0 - 14 d    Recién plantada   (28 d si es un ejemplar columnar grande)
//  15 - 84 d    Echando raíz      (~12 semanas)
//  85 - 365 d   Creciendo         (ya arraigó; es cuando el NPK pesa de verdad)
//    > 365 d    Estable           ← AQUÍ SE QUEDA PARA SIEMPRE
const int _kStandardInstallationMaxDays = 14; // contenedor pequeño/mediano
const int _kLargeInstallationMaxDays = 28; // columnar / ejemplar grande
const int _kStandardRootMaxDays = 84; // ~12 semanas
const int _kActiveGrowthMaxDays = 365; // primer año tras arraigar

bool _isLargeSpecimenProfile(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  return id == 'ca_03_columnar_landscape';
}

double _dateInferenceConfidence(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  return id == 'ca_skip' ? 0.40 : 0.45;
}

/// Propone la etapa a partir de la fecha de plantación.
///
/// **Es una progresión de UNA SOLA PASADA, no un ciclo.** Avanza y desemboca en
/// `maintenance`, donde se queda para siempre. No hay reinicio, ni año que la
/// regrese al principio, ni día terminal.
///
/// ```
/// Recién plantada → Echando raíz → Creciendo → Estable ──┐
///    (0-14 d)        (15-84 d)     (85-365 d)   (>365 d) │
///                                                   ▲     │
///                                                   └─────┘
///                                              aquí se queda
/// ```
///
/// - sin fecha → `unknown` (quien llama decide; ver [resolveCactusSetupStage])
///
/// `rest` (En reposo) NO se infiere por fecha: es estacional (invierno), no
/// depende de la edad de la planta. Queda disponible para confirmación manual.
CactusStageEstimate estimateCactusStageFromDate({
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
}) {
  if (plantingDate == null) {
    return const CactusStageEstimate(
      stageId: CactusStageIds.unknown,
      anchorTypeId: CactusAnchorTypeIds.unknown,
      confidence: CactusStageConfidence.unknown,
    );
  }

  final int days = now
      .difference(
        DateTime(plantingDate.year, plantingDate.month, plantingDate.day),
      )
      .inDays;

  // Fecha futura (planeado) o el mismo día: recién colocada.
  if (days <= 0) {
    return CactusStageEstimate(
      stageId: CactusStageIds.installationEstablishment,
      anchorTypeId: CactusAnchorTypeIds.installation,
      confidence: _dateInferenceConfidence(profileId),
    );
  }

  final bool large = _isLargeSpecimenProfile(profileId);
  final int installationMax = large
      ? _kLargeInstallationMaxDays
      : _kStandardInstallationMaxDays;

  // 1) Recién plantada: la raíz todavía no trabaja.
  if (days <= installationMax) {
    return CactusStageEstimate(
      stageId: CactusStageIds.installationEstablishment,
      anchorTypeId: CactusAnchorTypeIds.installation,
      confidence: _dateInferenceConfidence(profileId),
    );
  }

  // 2) Echando raíz: ~12 semanas de arraigo.
  if (days <= _kStandardRootMaxDays) {
    return CactusStageEstimate(
      stageId: CactusStageIds.rootEstablishment,
      anchorTypeId: CactusAnchorTypeIds.stageStart,
      confidence: _dateInferenceConfidence(
        profileId,
      ).clamp(0.0, 0.40).toDouble(),
    );
  }

  // 3) Creciendo: ya arraigó. Es la ÚNICA etapa donde el NPK pesa de verdad
  //    (wN sube a 0.11). Antes esta etapa existía en el enum, tenía targets,
  //    pesos y hasta imagen... pero NO había forma de llegar a ella: la
  //    progresión saltaba de "Echando raíz" directo a "Estable". Etapa muerta.
  if (days <= _kActiveGrowthMaxDays) {
    return const CactusStageEstimate(
      stageId: CactusStageIds.activeGrowth,
      anchorTypeId: CactusAnchorTypeIds.stageStart,
      confidence: CactusStageConfidence.byEstablishmentWindow,
    );
  }

  // 4) Estable: más de un año en el mismo lugar. AQUÍ SE QUEDA PARA SIEMPRE.
  //    No hay siguiente etapa. No hay fin de ciclo. No hay reinicio.
  return const CactusStageEstimate(
    stageId: CactusStageIds.maintenance,
    anchorTypeId: CactusAnchorTypeIds.installation,
    confidence: CactusStageConfidence.byMaintenanceWindow,
  );
}

/// FUENTE ÚNICA de la etapa que resulta del wizard. La usan tanto el onboarding
/// (`bootstrap_gate`) como el wizard de cuenta (`configure_seed_wizard_screen`).
///
/// Antes cada pantalla resolvía la etapa por su cuenta, y ambas tenían el mismo
/// bug: para "ya está plantado" hacían `normalizeCactusStageId(previous?...)`,
/// que con un contexto nuevo devuelve el **string** `'unknown'` (no `null`). Ese
/// `'unknown'` explícito pisaba la estimación por fecha, y el usuario terminaba
/// viendo **"Etapa por confirmar"** aunque hubiera dicho que la planta ya estaba
/// plantada y hubiera dado la fecha.
///
/// Reglas:
/// - **"La voy a plantar"** → siempre `installation_establishment`.
/// - **"Ya está plantada"** → se respeta la etapa previa si el usuario ya la
///   había confirmado; si no, se estima por la fecha; y si no hay fecha, se
///   asume `maintenance` (estable), porque el usuario acaba de decir que la
///   planta ya existe.
CactusStageEstimate resolveCactusSetupStage({
  required String? intentId,
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
  String? previousStageId,
}) {
  final String intent = normalizeCactusSetupIntentId(intentId);

  if (intent == CactusSetupIntentIds.plannedPlant) {
    return CactusStageEstimate(
      stageId: CactusStageIds.installationEstablishment,
      anchorTypeId: CactusAnchorTypeIds.installation,
      confidence: plantingDate == null
          ? CactusStageConfidence.unknown
          : CactusStageConfidence.byRecentAnchor,
    );
  }

  // Ya está plantada. Si el usuario ya había confirmado una etapa, se respeta.
  final String previous = normalizeCactusStageId(previousStageId);
  if (previous != CactusStageIds.unknown) {
    return CactusStageEstimate(
      stageId: previous,
      anchorTypeId: CactusAnchorTypeIds.installation,
      confidence: cactusStageConfidence(
        stageId: previous,
        anchorDate: plantingDate,
        anchorTypeId: CactusAnchorTypeIds.installation,
      ),
    );
  }

  if (plantingDate != null) {
    return estimateCactusStageFromDate(
      plantingDate: plantingDate,
      now: now,
      profileId: profileId,
    );
  }

  // "Ya está plantada" pero no recuerda la fecha: está establecida.
  return const CactusStageEstimate(
    stageId: CactusStageIds.maintenance,
    anchorTypeId: CactusAnchorTypeIds.unknown,
    confidence: CactusStageConfidence.unknown,
  );
}

/// Normaliza un id de etapa ornamental (acepta alias legacy). Desconocido →
/// `unknown`.
String normalizeCactusStageId(String? stageId) {
  final value = stageId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return CactusStageIds.unknown;
  if (CactusStageIds.all.contains(value)) return value;
  // Alias tolerantes de estados de onboarding heredados.
  switch (value) {
    case 'planned':
    case 'installation':
    case 'repot':
    case 'transplant':
      return CactusStageIds.installationEstablishment;
    case 'rooting':
    case 'establishing':
      return CactusStageIds.rootEstablishment;
    case 'growing':
    case 'active':
      return CactusStageIds.activeGrowth;
    case 'stable':
    case 'established':
      return CactusStageIds.maintenance;
    case 'dormant':
    case 'resting':
      return CactusStageIds.rest;
  }
  return CactusStageIds.unknown;
}

String normalizeCactusAnchorTypeId(String? anchorTypeId) {
  final value = anchorTypeId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return CactusAnchorTypeIds.unknown;
  switch (value) {
    case CactusAnchorTypeIds.installation:
    case CactusAnchorTypeIds.repot:
    case CactusAnchorTypeIds.stageStart:
    case CactusAnchorTypeIds.manualStage:
    case CactusAnchorTypeIds.unknown:
      return value;
  }
  return CactusAnchorTypeIds.unknown;
}

/// Nombre de la etapa, en lenguaje de agricultor. Sin jerga interna.
String cactusStageDisplayName(String? stageId) {
  final id = normalizeCactusStageId(stageId);
  return switch (id) {
    CactusStageIds.installationEstablishment => 'Recién plantada',
    CactusStageIds.rootEstablishment => 'Echando raíz',
    CactusStageIds.activeGrowth => 'Creciendo',
    CactusStageIds.maintenance => 'Estable',
    CactusStageIds.rest => 'En reposo',
    _ => 'Etapa por confirmar',
  };
}

/// Ventana crítica de la etapa. Espejo de `treeCriticalWindowLabel`.
String? cactusCriticalWindowLabel(String? stageId) {
  final id = normalizeCactusStageId(stageId);
  return switch (id) {
    CactusStageIds.installationEstablishment =>
      'Ventana crítica: recién plantada',
    CactusStageIds.rootEstablishment => 'Ventana crítica: echando raíz',
    CactusStageIds.rest => 'Ventana importante: reposo',
    _ => null,
  };
}

/// Prioridad de cuidado por etapa. Espejo de `treeStagePriorityText`.
String cactusStagePriorityText(String? stageId) {
  final id = normalizeCactusStageId(stageId);
  return switch (id) {
    CactusStageIds.installationEstablishment =>
      'Prioridad: poca agua y que el sustrato drene bien',
    CactusStageIds.rootEstablishment =>
      'Prioridad: dejar secar entre riegos, sin encharcar',
    CactusStageIds.activeGrowth =>
      'Creciendo: riega por pulsos, sin saturar el sustrato',
    CactusStageIds.maintenance =>
      'Estable: vigila el exceso de agua y la acumulación de sal',
    CactusStageIds.rest =>
      'Reposo: riega mucho menos. Frío con humedad pudre la raíz',
    _ => 'BIO-G interpreta tus sensores según el estado de la planta',
  };
}

/// Confianza (0..1) de una etapa ornamental ya persistida + su ancla.
///
/// La etapa por fecha es una estimación: si el ancla es de instalación reciente
/// la confianza sube; sin ancla queda baja. `maintenance` elegido/derivado sin
/// evidencia visual nunca es alta.
double cactusStageConfidence({
  required String? stageId,
  required DateTime? anchorDate,
  required String? anchorTypeId,
}) {
  final id = normalizeCactusStageId(stageId);
  if (id == CactusStageIds.unknown) return CactusStageConfidence.unknown;
  final anchorType = normalizeCactusAnchorTypeId(anchorTypeId);
  if (anchorDate == null) {
    return switch (id) {
      CactusStageIds.activeGrowth => 0.85,
      CactusStageIds.maintenance => 0.65,
      CactusStageIds.rest => 0.50,
      CactusStageIds.installationEstablishment ||
      CactusStageIds.rootEstablishment =>
        anchorType == CactusAnchorTypeIds.manualStage ? 0.75 : 0.40,
      _ => CactusStageConfidence.unknown,
    };
  }
  if (anchorType == CactusAnchorTypeIds.manualStage) return 0.80;
  return switch (id) {
    CactusStageIds.installationEstablishment =>
      CactusStageConfidence.byRecentAnchor,
    CactusStageIds.rootEstablishment =>
      CactusStageConfidence.byEstablishmentWindow,
    CactusStageIds.maintenance => CactusStageConfidence.byMaintenanceWindow,
    _ => 0.35,
  };
}

const Map<String, Set<String>> cactusAllowedStageTransitions =
    <String, Set<String>>{
      CactusStageIds.installationEstablishment: <String>{
        CactusStageIds.rootEstablishment,
      },
      CactusStageIds.rootEstablishment: <String>{
        CactusStageIds.activeGrowth,
        CactusStageIds.maintenance,
      },
      CactusStageIds.activeGrowth: <String>{
        CactusStageIds.maintenance,
        CactusStageIds.rest,
      },
      CactusStageIds.maintenance: <String>{
        CactusStageIds.activeGrowth,
        CactusStageIds.rest,
      },
      CactusStageIds.rest: <String>{
        CactusStageIds.activeGrowth,
        CactusStageIds.maintenance,
      },
      CactusStageIds.unknown: CactusStageIds.all,
    };

bool isAllowedCactusStageTransition(String? from, String? to) {
  final source = normalizeCactusStageId(from);
  final target = normalizeCactusStageId(to);
  if (source == target) return true;
  return cactusAllowedStageTransitions[source]?.contains(target) ?? false;
}

/// True cuando el cultivo debe usar el runtime ORNAMENTAL de establecimiento/
/// mantenimiento (cactus v1). La categoría ornamental por sí sola no basta:
/// así una ornamental futura nunca hereda accidentalmente el modelo Cactus.
bool isCactusCrop({
  String? cropId,
  String? cropCategoryId,
  CropCategory? category,
}) {
  final canonicalCropId = CropCatalog.canonicalCropKey(cropId);
  if (canonicalCropId == kCactusCropId) return true;

  if (category == CropCategory.ornamental) {
    return false;
  }

  final normalizedCategory = cropCategoryId?.trim().toLowerCase();
  if (normalizedCategory == kOrnamentalCategoryId) {
    return CropCatalog.cropById(canonicalCropId)?.cropId == kCactusCropId;
  }
  return false;
}

// NOTA: `isEstablishmentMaintenanceCrop()` YA NO vive aquí.
//
// Era un alias de `isCactusCrop()`, y eso convertía al cactus en el único
// cultivo posible del modo ornamental: la segunda ornamental (suculenta) no
// habría entrado nunca al runtime. La pregunta "¿usa el runtime de
// establecimiento + mantenimiento?" es del MODO, no de esta planta, así que vive
// en `lib/core/crops/ornamental/ornamental_crops.dart`.

bool isCactusContext(DeviceCropContext? context) {
  if (context == null) return false;
  return isCactusCrop(
    cropId: context.cropId,
    cropCategoryId: context.cropCategoryId,
  );
}

/// Id canónico del cultivo cactus y de la categoría ornamental (fuente de
/// verdad de ids, compartida con el catálogo).
const String kCactusCropId = 'crop_cactus';
const String kOrnamentalCategoryId = 'ornamental';
