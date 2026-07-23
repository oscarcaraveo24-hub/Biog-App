import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/agave/agave_catalog.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Dominio del ciclo de vida ORNAMENTAL del Maguey / Agave (Documento A del
/// paquete MG v1.0). Espejo ESTRUCTURAL de `aloe_lifecycle.dart` y
/// `succulent_lifecycle.dart`: mismo modo (`establishment_maintenance`), misma
/// arquitectura… y biología propia (ventanas más largas: décadas de vida).
///
/// Reglas no negociables (Doc A §7.7, §7.8, §0.4):
/// - `maintenance` NUNCA se convierte en fin de ciclo (no `cycle_complete`); un
///   maguey puede permanecer "Maduro y estable" durante décadas.
/// - "Maduro" es estabilidad ornamental, NO madurez reproductiva, industrial,
///   legal ni de cosecha. NO significa "listo para jima".
/// - NO hay rendimiento ni cosecha (supportsYieldProjection=false). El quiote y
///   la separación de hijuelos son eventos, no etapas ni cosecha.
/// - El quiote / tallo floral NO es una etapa automática: es un evento manual
///   (`agave.flower_stalk_observed`) y no cambia el stageId.
/// - `rest` no se infiere por calendario/mes ni por sequedad: requiere
///   confirmación.
/// - Cambiar de perfil NO reinicia la edad de la planta; un hijuelo separado sí
///   inicia su propio establecimiento.
class AgaveLifecycle {
  const AgaveLifecycle._();

  /// Modo de ciclo. No es siembra→cosecha: es establecimiento y luego
  /// mantenimiento indefinido.
  static const String lifecycleMode = 'establishment_maintenance';

  // ── Capacidades congeladas (Doc A §0.2, §7.9) ──────────────────────────────
  static const bool supportsYieldProjection = false;
  static const bool supportsHarvest = false;
  static const bool supportsRecurringBloom = false;

  /// DESCARTADO en v1 (Doc A §0.2). El microciclo hídrico exige un baseline por
  /// dispositivo que BIO-G no tiene. El agua se interpreta con la lectura real
  /// de humedad contra los targets de la etapa.
  static const bool supportsHydricCycle = false;

  /// DESCARTADO en v1 (Doc A §0.2, Doc C §0.3). No se declara una capacidad que
  /// no existe.
  static const bool supportsStressMemory = false;
}

/// Intenciones del wizard de Maguey. **Solo dos** (Doc A §9.2).
///
/// No se agrega "lo voy a cambiar de maceta", "es un hijuelo", "es joven",
/// "está para jima" ni "ya dio quiote": no son formas de dar de alta una planta.
/// Un contexto antiguo con `repot` se lee como "ya está plantado".
class AgaveSetupIntentIds {
  const AgaveSetupIntentIds._();

  static const String plannedPlant = 'planned_plant';
  static const String alreadyPlanted = 'already_planted';

  static const Set<String> all = <String>{plannedPlant, alreadyPlanted};
}

/// Acepta los IDs actuales y los heredados. Un valor desconocido se trata de
/// forma conservadora como una planta que ya existe, nunca como una plantación
/// futura.
String normalizeAgaveSetupIntentId(String? intentId) {
  final value = intentId?.trim().toLowerCase();
  return switch (value) {
    AgaveSetupIntentIds.plannedPlant ||
    'planned' ||
    'plant' => AgaveSetupIntentIds.plannedPlant,
    AgaveSetupIntentIds.alreadyPlanted ||
    'planted' ||
    'growing' ||
    'repot' ||
    'transplant' => AgaveSetupIntentIds.alreadyPlanted,
    _ => AgaveSetupIntentIds.alreadyPlanted,
  };
}

/// Solo "lo voy a plantar" pide una fecha futura.
bool agaveSetupIntentRequiresFutureDate(String? intentId) {
  return normalizeAgaveSetupIntentId(intentId) ==
      AgaveSetupIntentIds.plannedPlant;
}

/// Etapas de vida (Doc A §7.1). El quiote, la floración, la senescencia y la
/// emisión de hijuelos NO están aquí: no son etapas, son eventos/observaciones.
class AgaveStageIds {
  const AgaveStageIds._();

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

/// Tipos de anclaje temporal. NO es fecha de siembra: es plantación/alta o
/// inicio aproximado de una etapa.
class AgaveAnchorTypeIds {
  const AgaveAnchorTypeIds._();

  static const String installation = 'installation';
  static const String repot = 'repot';
  static const String stageStart = 'stage_start';
  static const String manualStage = 'manual_stage';
  static const String unknown = 'unknown';
}

/// Confianza interna de una etapa estimada por fecha. NUNCA se muestra al
/// usuario (Doc A §7.2, §11.2: nada de "confianza 0.42").
class AgaveStageConfidence {
  const AgaveStageConfidence._();

  static const double byRecentAnchor = 0.45;
  static const double byEstablishmentWindow = 0.40;
  static const double byMaintenanceWindow = 0.45;
  static const double unknown = 0.25;

  static String labelFor(double confidence) {
    if (confidence >= 0.60) return 'alta';
    if (confidence >= 0.40) return 'media';
    return 'baja';
  }
}

/// Resultado de estimar la etapa por fecha.
class AgaveStageEstimate {
  const AgaveStageEstimate({
    required this.stageId,
    required this.anchorTypeId,
    required this.confidence,
  });

  final String stageId;
  final String anchorTypeId;
  final double confidence;
}

// ── Ventanas por fecha (Doc A §7.4) ──────────────────────────────────────────
//
// Son defaults de INGENIERÍA para el seguimiento ornamental, NO la edad de
// floración ni la edad productiva. El maguey vive mucho más que la sábila o la
// suculenta, así que las ventanas son más anchas (Doc A §7.4, §7.5):
//
//     0 -   30 d   Recién plantado          (raíz perturbada; aclimatación)
//    31 -  180 d   Echando raíz             (establecimiento radicular)
//   181 - 1095 d   Creciendo y madurando    (≈3 años; aquí el NPK pesa)
//      > 1095 d    Maduro y estable         ← AQUÍ SE QUEDA (décadas)
//
// Usar 3 años como frontera de "maduro y estable" es una decisión ORNAMENTAL,
// no productiva: el ciclo de 7-12 años de A. tequilana NO se generaliza a todo
// el género (Doc A §7.5).
const int _kInstallationMaxDays = 30;
const int _kRootMaxDays = 180;
const int _kActiveGrowthMaxDays = 1095;

double _dateInferenceConfidence(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  return id == kAgaveSkip ? 0.40 : 0.45;
}

/// Propone la etapa a partir de la fecha de plantación.
///
/// **Es una progresión de UNA SOLA PASADA, no un ciclo.** Avanza y desemboca en
/// `maintenance`, donde se queda para siempre. No hay reinicio, ni día terminal
/// (Doc A §7.9): a 1, 5, 20, 40 o más años sigue en `maintenance`.
///
/// ```
/// Recién plantado → Echando raíz → Creciendo y madurando → Maduro y estable ─┐
///    (0-30 d)        (31-180 d)        (181-1095 d)            (>1095 d)      │
///                                                                 ▲           │
///                                                                 └───────────┘
///                                                            aquí se queda
/// ```
///
/// `rest` (En reposo) NO se infiere por fecha ni por mes: la estacionalidad
/// cambia por especie y clima, y BIO-G opera en todo México sin modelo climático
/// por región (Doc A §7.3). Solo por confirmación.
AgaveStageEstimate estimateAgaveStageFromDate({
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
}) {
  if (plantingDate == null) {
    return const AgaveStageEstimate(
      stageId: AgaveStageIds.unknown,
      anchorTypeId: AgaveAnchorTypeIds.unknown,
      confidence: AgaveStageConfidence.unknown,
    );
  }

  final int days = now
      .difference(
        DateTime(plantingDate.year, plantingDate.month, plantingDate.day),
      )
      .inDays;

  // Fecha futura (planeada) o el mismo día: recién colocado.
  if (days <= 0) {
    return AgaveStageEstimate(
      stageId: AgaveStageIds.installationEstablishment,
      anchorTypeId: AgaveAnchorTypeIds.installation,
      confidence: _dateInferenceConfidence(profileId),
    );
  }

  // 1) Recién plantado: la raíz pudo haber sido perturbada al plantar.
  if (days <= _kInstallationMaxDays) {
    return AgaveStageEstimate(
      stageId: AgaveStageIds.installationEstablishment,
      anchorTypeId: AgaveAnchorTypeIds.installation,
      confidence: _dateInferenceConfidence(profileId),
    );
  }

  // 2) Echando raíz: hasta ~6 meses de establecimiento radicular.
  if (days <= _kRootMaxDays) {
    return AgaveStageEstimate(
      stageId: AgaveStageIds.rootEstablishment,
      anchorTypeId: AgaveAnchorTypeIds.stageStart,
      confidence: _dateInferenceConfidence(
        profileId,
      ).clamp(0.0, 0.40).toDouble(),
    );
  }

  // 3) Creciendo y madurando: ya arraigó. Es la etapa donde el NPK pesa de
  //    verdad. Madurar aquí = consolidar la planta, NO estar listo para jima.
  if (days <= _kActiveGrowthMaxDays) {
    return const AgaveStageEstimate(
      stageId: AgaveStageIds.activeGrowth,
      anchorTypeId: AgaveAnchorTypeIds.stageStart,
      confidence: AgaveStageConfidence.byEstablishmentWindow,
    );
  }

  // 4) Maduro y estable. AQUÍ SE QUEDA PARA SIEMPRE. No hay fin de ciclo ni
  //    reinicio, ni jima, ni contenido de azúcar.
  return const AgaveStageEstimate(
    stageId: AgaveStageIds.maintenance,
    anchorTypeId: AgaveAnchorTypeIds.installation,
    confidence: AgaveStageConfidence.byMaintenanceWindow,
  );
}

/// FUENTE ÚNICA de la etapa que resulta del wizard (Doc A §9.4). La usan tanto
/// el onboarding (`bootstrap_gate`) como el wizard de cuenta
/// (`configure_seed_wizard_screen`). La UI no duplica reglas de fechas.
///
/// Reglas (Doc A §9.4, §9.5):
/// - **"Lo voy a plantar"** → siempre `installation_establishment`.
/// - **"Ya está plantado"** → se respeta la etapa previa si el usuario ya la
///   había confirmado; si no, se estima por la fecha; y si no hay fecha, se
///   asume `maintenance` (Maduro y estable), porque el usuario acaba de declarar
///   que la planta ya existe. NUNCA se queda en "Etapa por confirmar".
AgaveStageEstimate resolveAgaveSetupStage({
  required String? intentId,
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
  String? previousStageId,
}) {
  final String intent = normalizeAgaveSetupIntentId(intentId);

  if (intent == AgaveSetupIntentIds.plannedPlant) {
    return AgaveStageEstimate(
      stageId: AgaveStageIds.installationEstablishment,
      anchorTypeId: AgaveAnchorTypeIds.installation,
      confidence: plantingDate == null
          ? AgaveStageConfidence.unknown
          : AgaveStageConfidence.byRecentAnchor,
    );
  }

  // Ya está plantado. Si el usuario ya había confirmado una etapa, se respeta.
  final String previous = normalizeAgaveStageId(previousStageId);
  if (previous != AgaveStageIds.unknown) {
    return AgaveStageEstimate(
      stageId: previous,
      anchorTypeId: AgaveAnchorTypeIds.installation,
      confidence: agaveStageConfidence(
        stageId: previous,
        anchorDate: plantingDate,
        anchorTypeId: AgaveAnchorTypeIds.installation,
      ),
    );
  }

  if (plantingDate != null) {
    return estimateAgaveStageFromDate(
      plantingDate: plantingDate,
      now: now,
      profileId: profileId,
    );
  }

  // "Ya está plantado" pero no recuerda la fecha: está establecido (Doc A §9.5).
  return const AgaveStageEstimate(
    stageId: AgaveStageIds.maintenance,
    anchorTypeId: AgaveAnchorTypeIds.unknown,
    confidence: AgaveStageConfidence.unknown,
  );
}

/// Normaliza un id de etapa (acepta alias heredados). Desconocido → `unknown`.
String normalizeAgaveStageId(String? stageId) {
  final value = stageId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return AgaveStageIds.unknown;
  if (AgaveStageIds.all.contains(value)) return value;
  switch (value) {
    case 'planned':
    case 'installation':
    case 'repot':
    case 'transplant':
      return AgaveStageIds.installationEstablishment;
    case 'rooting':
    case 'establishing':
      return AgaveStageIds.rootEstablishment;
    case 'growing':
    case 'active':
      return AgaveStageIds.activeGrowth;
    case 'stable':
    case 'established':
    case 'mature':
      return AgaveStageIds.maintenance;
    case 'dormant':
    case 'resting':
      return AgaveStageIds.rest;
  }
  return AgaveStageIds.unknown;
}

String normalizeAgaveAnchorTypeId(String? anchorTypeId) {
  final value = anchorTypeId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return AgaveAnchorTypeIds.unknown;
  switch (value) {
    case AgaveAnchorTypeIds.installation:
    case AgaveAnchorTypeIds.repot:
    case AgaveAnchorTypeIds.stageStart:
    case AgaveAnchorTypeIds.manualStage:
    case AgaveAnchorTypeIds.unknown:
      return value;
  }
  return AgaveAnchorTypeIds.unknown;
}

/// Nombre de la etapa, en lenguaje de agricultor (Doc A §7.2). Sin jerga: nada
/// de "fase vegetativa", "ciclo semélparo" ni "jima readiness".
String agaveStageDisplayName(String? stageId) {
  final id = normalizeAgaveStageId(stageId);
  return switch (id) {
    AgaveStageIds.installationEstablishment => 'Recién plantado',
    AgaveStageIds.rootEstablishment => 'Echando raíz',
    AgaveStageIds.activeGrowth => 'Creciendo y madurando',
    AgaveStageIds.maintenance => 'Maduro y estable',
    AgaveStageIds.rest => 'En reposo',
    _ => 'Etapa por confirmar',
  };
}

/// Ventana crítica de la etapa.
String? agaveCriticalWindowLabel(String? stageId) {
  final id = normalizeAgaveStageId(stageId);
  return switch (id) {
    AgaveStageIds.installationEstablishment =>
      'Ventana crítica: recién plantado',
    AgaveStageIds.rootEstablishment => 'Ventana crítica: echando raíz',
    AgaveStageIds.rest => 'Ventana importante: reposo',
    _ => null,
  };
}

/// Prioridad de cuidado por etapa (Doc B §10). "Maduro" nunca implica jima.
String agaveStagePriorityText(String? stageId) {
  final id = normalizeAgaveStageId(stageId);
  return switch (id) {
    AgaveStageIds.installationEstablishment =>
      'Prioridad: contacto de raíz, drenaje y suelo suelto',
    AgaveStageIds.rootEstablishment =>
      'Prioridad: raíz firme, drenaje y temperatura estable',
    AgaveStageIds.activeGrowth =>
      'Creciendo y madurando: agua medida, raíz activa y sales bajo control',
    AgaveStageIds.maintenance =>
      'Maduro y estable: no riegues por calendario y vigila las sales. No es '
          'jima ni cosecha',
    AgaveStageIds.rest =>
      'Reposo: protégelo del frío húmedo y no lo fuerces a crecer',
    _ => 'BIO-G interpreta tus sensores según el estado de la planta',
  };
}

/// Confianza (0..1) de una etapa ya persistida + su ancla. Uso interno.
double agaveStageConfidence({
  required String? stageId,
  required DateTime? anchorDate,
  required String? anchorTypeId,
}) {
  final id = normalizeAgaveStageId(stageId);
  if (id == AgaveStageIds.unknown) return AgaveStageConfidence.unknown;
  final anchorType = normalizeAgaveAnchorTypeId(anchorTypeId);
  if (anchorDate == null) {
    return switch (id) {
      AgaveStageIds.activeGrowth => 0.85,
      AgaveStageIds.maintenance => 0.65,
      AgaveStageIds.rest => 0.50,
      AgaveStageIds.installationEstablishment ||
      AgaveStageIds.rootEstablishment =>
        anchorType == AgaveAnchorTypeIds.manualStage ? 0.75 : 0.40,
      _ => AgaveStageConfidence.unknown,
    };
  }
  if (anchorType == AgaveAnchorTypeIds.manualStage) return 0.80;
  return switch (id) {
    AgaveStageIds.installationEstablishment =>
      AgaveStageConfidence.byRecentAnchor,
    AgaveStageIds.rootEstablishment =>
      AgaveStageConfidence.byEstablishmentWindow,
    AgaveStageIds.maintenance =>
      AgaveStageConfidence.byMaintenanceWindow,
    _ => 0.35,
  };
}

/// Transiciones permitidas (Doc A §7.7, §7.8). Ninguna vuelve a instalación de
/// forma automática: eso sería un reinicio de vida. `maintenance` nunca pasa a
/// `cycle_complete`.
const Map<String, Set<String>> agaveAllowedStageTransitions =
    <String, Set<String>>{
      AgaveStageIds.installationEstablishment: <String>{
        AgaveStageIds.rootEstablishment,
      },
      AgaveStageIds.rootEstablishment: <String>{
        AgaveStageIds.activeGrowth,
        AgaveStageIds.maintenance,
      },
      AgaveStageIds.activeGrowth: <String>{
        AgaveStageIds.maintenance,
        AgaveStageIds.rest,
      },
      AgaveStageIds.maintenance: <String>{
        AgaveStageIds.activeGrowth,
        AgaveStageIds.rest,
      },
      AgaveStageIds.rest: <String>{
        AgaveStageIds.activeGrowth,
        AgaveStageIds.maintenance,
      },
      AgaveStageIds.unknown: AgaveStageIds.all,
    };

bool isAllowedAgaveStageTransition(String? from, String? to) {
  final source = normalizeAgaveStageId(from);
  final target = normalizeAgaveStageId(to);
  if (source == target) return true;
  return agaveAllowedStageTransitions[source]?.contains(target) ?? false;
}

/// True cuando el cultivo es Maguey. La categoría ornamental por sí sola no
/// basta: así ninguna otra ornamental hereda accidentalmente esta biología.
bool isAgaveCrop({
  String? cropId,
  String? cropCategoryId,
  CropCategory? category,
}) {
  final canonicalCropId = CropCatalog.canonicalCropKey(cropId);
  if (canonicalCropId == kAgaveCropId) return true;

  if (category == CropCategory.ornamental) {
    return false;
  }

  final normalizedCategory = cropCategoryId?.trim().toLowerCase();
  if (normalizedCategory == kAgaveOrnamentalCategoryId) {
    return CropCatalog.cropById(canonicalCropId)?.cropId == kAgaveCropId;
  }
  return false;
}

bool isAgaveContext(DeviceCropContext? context) {
  if (context == null) return false;
  return isAgaveCrop(
    cropId: context.cropId,
    cropCategoryId: context.cropCategoryId,
  );
}

/// Id canónico del cultivo maguey y de la categoría ornamental.
const String kAgaveCropId = kCropAgave;
const String kAgaveOrnamentalCategoryId = 'ornamental';
