import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/succulent/succulent_catalog.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Dominio del ciclo de vida ORNAMENTAL de la Suculenta (Documento A del
/// paquete SU v1.0). Espejo ESTRUCTURAL de `cactus_lifecycle.dart`: mismo modo
/// (`establishment_maintenance`), misma arquitectura… y biología propia.
///
/// Reglas no negociables (Doc A §0.2, §5.6, §5.7):
/// - `maintenance` NUNCA se convierte en fin de ciclo (no `cycle_complete`).
/// - NO hay rendimiento ni cosecha (supportsYieldProjection=false).
/// - Estrés, recuperación, pudrición y declive NO son etapas.
/// - `rest` no se infiere por calendario: requiere confirmación.
/// - Cambiar de perfil NO reinicia la edad de la planta.
class SucculentLifecycle {
  const SucculentLifecycle._();

  /// Modo de ciclo. No es siembra→cosecha: es establecimiento y luego
  /// mantenimiento indefinido.
  static const String lifecycleMode = 'establishment_maintenance';

  // ── Capacidades congeladas (Doc A §0.2 · Doc B §0.3 · Doc C §0.3) ──────────
  static const bool supportsYieldProjection = false;
  static const bool supportsHarvest = false;
  static const bool supportsRecurringBloom = false;

  /// DESCARTADO en v1 (Guía de Ornamentales §7.2). El microciclo hídrico exige
  /// un baseline por dispositivo que BIO-G no tiene. El agua se interpreta con
  /// la lectura real de humedad contra los targets de la etapa, igual que en
  /// frijol.
  static const bool supportsHydricCycle = false;

  /// DESCARTADO en v1 (Doc C §0.3). No se declara una capacidad que no existe.
  static const bool supportsStressMemory = false;
}

/// Intenciones del wizard de Suculenta. **Solo dos** (Doc A §6.2).
///
/// No se agrega "la voy a cambiar de maceta", "es joven", "es un esqueje",
/// "está estresada" ni "está recuperándose": no son formas de dar de alta una
/// planta. Un contexto antiguo con `repot` se lee como "ya está plantada".
class SucculentSetupIntentIds {
  const SucculentSetupIntentIds._();

  static const String plannedPlant = 'planned_plant';
  static const String alreadyPlanted = 'already_planted';

  static const Set<String> all = <String>{plannedPlant, alreadyPlanted};
}

/// Acepta los IDs actuales y los heredados. Un valor desconocido se trata de
/// forma conservadora como una planta que ya existe, nunca como una plantación
/// futura.
String normalizeSucculentSetupIntentId(String? intentId) {
  final value = intentId?.trim().toLowerCase();
  return switch (value) {
    SucculentSetupIntentIds.plannedPlant ||
    'planned' ||
    'plant' => SucculentSetupIntentIds.plannedPlant,
    SucculentSetupIntentIds.alreadyPlanted ||
    'planted' ||
    'growing' ||
    'repot' ||
    'transplant' => SucculentSetupIntentIds.alreadyPlanted,
    _ => SucculentSetupIntentIds.alreadyPlanted,
  };
}

/// Solo "la voy a plantar" pide una fecha futura.
bool succulentSetupIntentRequiresFutureDate(String? intentId) {
  return normalizeSucculentSetupIntentId(intentId) ==
      SucculentSetupIntentIds.plannedPlant;
}

/// Etapas de vida (Doc A §5.1). Estrés, recuperación y declive NO están aquí:
/// no son etapas, son observaciones de sanidad.
class SucculentStageIds {
  const SucculentStageIds._();

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
class SucculentAnchorTypeIds {
  const SucculentAnchorTypeIds._();

  static const String installation = 'installation';
  static const String repot = 'repot';
  static const String stageStart = 'stage_start';
  static const String manualStage = 'manual_stage';
  static const String unknown = 'unknown';
}

/// Confianza interna de una etapa estimada por fecha. NUNCA se muestra al
/// usuario (Doc A §3, Doc C §2.2: nada de "confianza 0.42").
class SucculentStageConfidence {
  const SucculentStageConfidence._();

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
class SucculentStageEstimate {
  const SucculentStageEstimate({
    required this.stageId,
    required this.anchorTypeId,
    required this.confidence,
  });

  final String stageId;
  final String anchorTypeId;
  final double confidence;
}

// ── Ventanas por fecha (Doc A §5.4) ──────────────────────────────────────────
//
// Son defaults de implementación, no límites biológicos universales. NO son los
// del cactus: la suculenta arraiga antes (~8 semanas) y su empuje de
// crecimiento se acota a ~9 meses antes de estabilizarse.
//
//    0 - 14 d    Recién plantada
//   15 - 56 d    Echando raíz      (~8 semanas)
//   57 - 270 d   Creciendo         (aquí el NPK pesa de verdad)
//     > 270 d    Estable           ← AQUÍ SE QUEDA PARA SIEMPRE
const int _kInstallationMaxDays = 14;
const int _kRootMaxDays = 56;
const int _kActiveGrowthMaxDays = 270;

double _dateInferenceConfidence(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  return id == kSuSkip ? 0.40 : 0.45;
}

/// Propone la etapa a partir de la fecha de plantación.
///
/// **Es una progresión de UNA SOLA PASADA, no un ciclo.** Avanza y desemboca en
/// `maintenance`, donde se queda para siempre. No hay reinicio, ni día terminal.
///
/// ```
/// Recién plantada → Echando raíz → Creciendo → Estable ──┐
///    (0-14 d)        (15-56 d)     (57-270 d)  (>270 d)  │
///                                                  ▲      │
///                                                  └──────┘
///                                             aquí se queda
/// ```
///
/// `rest` (En reposo) NO se infiere por fecha ni por mes: hay suculentas de
/// reposo invernal y otras de reposo estival (Doc A §5.3). Solo por
/// confirmación.
SucculentStageEstimate estimateSucculentStageFromDate({
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
}) {
  if (plantingDate == null) {
    return const SucculentStageEstimate(
      stageId: SucculentStageIds.unknown,
      anchorTypeId: SucculentAnchorTypeIds.unknown,
      confidence: SucculentStageConfidence.unknown,
    );
  }

  final int days = now
      .difference(
        DateTime(plantingDate.year, plantingDate.month, plantingDate.day),
      )
      .inDays;

  // Fecha futura (planeada) o el mismo día: recién colocada.
  if (days <= 0) {
    return SucculentStageEstimate(
      stageId: SucculentStageIds.installationEstablishment,
      anchorTypeId: SucculentAnchorTypeIds.installation,
      confidence: _dateInferenceConfidence(profileId),
    );
  }

  // 1) Recién plantada: la raíz todavía no trabaja.
  if (days <= _kInstallationMaxDays) {
    return SucculentStageEstimate(
      stageId: SucculentStageIds.installationEstablishment,
      anchorTypeId: SucculentAnchorTypeIds.installation,
      confidence: _dateInferenceConfidence(profileId),
    );
  }

  // 2) Echando raíz: ~8 semanas de arraigo.
  if (days <= _kRootMaxDays) {
    return SucculentStageEstimate(
      stageId: SucculentStageIds.rootEstablishment,
      anchorTypeId: SucculentAnchorTypeIds.stageStart,
      confidence: _dateInferenceConfidence(
        profileId,
      ).clamp(0.0, 0.40).toDouble(),
    );
  }

  // 3) Creciendo: ya arraigó. Es la etapa donde el NPK pesa de verdad.
  if (days <= _kActiveGrowthMaxDays) {
    return const SucculentStageEstimate(
      stageId: SucculentStageIds.activeGrowth,
      anchorTypeId: SucculentAnchorTypeIds.stageStart,
      confidence: SucculentStageConfidence.byEstablishmentWindow,
    );
  }

  // 4) Estable. AQUÍ SE QUEDA PARA SIEMPRE. No hay fin de ciclo ni reinicio.
  return const SucculentStageEstimate(
    stageId: SucculentStageIds.maintenance,
    anchorTypeId: SucculentAnchorTypeIds.installation,
    confidence: SucculentStageConfidence.byMaintenanceWindow,
  );
}

/// FUENTE ÚNICA de la etapa que resulta del wizard (Doc A §6.3). La usan tanto
/// el onboarding (`bootstrap_gate`) como el wizard de cuenta
/// (`configure_seed_wizard_screen`). La UI no duplica reglas de fechas.
///
/// Reglas:
/// - **"La voy a plantar"** → siempre `installation_establishment`.
/// - **"Ya está plantada"** → se respeta la etapa previa si el usuario ya la
///   había confirmado; si no, se estima por la fecha; y si no hay fecha, se
///   asume `maintenance` (estable), porque el usuario acaba de declarar que la
///   planta ya existe (Doc A §6.4). NUNCA se queda en "Etapa por confirmar".
SucculentStageEstimate resolveSucculentSetupStage({
  required String? intentId,
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
  String? previousStageId,
}) {
  final String intent = normalizeSucculentSetupIntentId(intentId);

  if (intent == SucculentSetupIntentIds.plannedPlant) {
    return SucculentStageEstimate(
      stageId: SucculentStageIds.installationEstablishment,
      anchorTypeId: SucculentAnchorTypeIds.installation,
      confidence: plantingDate == null
          ? SucculentStageConfidence.unknown
          : SucculentStageConfidence.byRecentAnchor,
    );
  }

  // Ya está plantada. Si el usuario ya había confirmado una etapa, se respeta.
  final String previous = normalizeSucculentStageId(previousStageId);
  if (previous != SucculentStageIds.unknown) {
    return SucculentStageEstimate(
      stageId: previous,
      anchorTypeId: SucculentAnchorTypeIds.installation,
      confidence: succulentStageConfidence(
        stageId: previous,
        anchorDate: plantingDate,
        anchorTypeId: SucculentAnchorTypeIds.installation,
      ),
    );
  }

  if (plantingDate != null) {
    return estimateSucculentStageFromDate(
      plantingDate: plantingDate,
      now: now,
      profileId: profileId,
    );
  }

  // "Ya está plantada" pero no recuerda la fecha: está establecida.
  return const SucculentStageEstimate(
    stageId: SucculentStageIds.maintenance,
    anchorTypeId: SucculentAnchorTypeIds.unknown,
    confidence: SucculentStageConfidence.unknown,
  );
}

/// Normaliza un id de etapa (acepta alias heredados). Desconocido → `unknown`.
String normalizeSucculentStageId(String? stageId) {
  final value = stageId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return SucculentStageIds.unknown;
  if (SucculentStageIds.all.contains(value)) return value;
  switch (value) {
    case 'planned':
    case 'installation':
    case 'repot':
    case 'transplant':
      return SucculentStageIds.installationEstablishment;
    case 'rooting':
    case 'establishing':
      return SucculentStageIds.rootEstablishment;
    case 'growing':
    case 'active':
      return SucculentStageIds.activeGrowth;
    case 'stable':
    case 'established':
      return SucculentStageIds.maintenance;
    case 'dormant':
    case 'resting':
      return SucculentStageIds.rest;
  }
  return SucculentStageIds.unknown;
}

String normalizeSucculentAnchorTypeId(String? anchorTypeId) {
  final value = anchorTypeId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return SucculentAnchorTypeIds.unknown;
  switch (value) {
    case SucculentAnchorTypeIds.installation:
    case SucculentAnchorTypeIds.repot:
    case SucculentAnchorTypeIds.stageStart:
    case SucculentAnchorTypeIds.manualStage:
    case SucculentAnchorTypeIds.unknown:
      return value;
  }
  return SucculentAnchorTypeIds.unknown;
}

/// Nombre de la etapa, en lenguaje de agricultor (Doc A §5.2). Sin jerga.
String succulentStageDisplayName(String? stageId) {
  final id = normalizeSucculentStageId(stageId);
  return switch (id) {
    SucculentStageIds.installationEstablishment => 'Recién plantada',
    SucculentStageIds.rootEstablishment => 'Echando raíz',
    SucculentStageIds.activeGrowth => 'Creciendo',
    SucculentStageIds.maintenance => 'Estable',
    SucculentStageIds.rest => 'En reposo',
    _ => 'Etapa por confirmar',
  };
}

/// Ventana crítica de la etapa.
String? succulentCriticalWindowLabel(String? stageId) {
  final id = normalizeSucculentStageId(stageId);
  return switch (id) {
    SucculentStageIds.installationEstablishment =>
      'Ventana crítica: recién plantada',
    SucculentStageIds.rootEstablishment => 'Ventana crítica: echando raíz',
    SucculentStageIds.rest => 'Ventana importante: reposo',
    _ => null,
  };
}

/// Prioridad de cuidado por etapa (Doc B §10).
String succulentStagePriorityText(String? stageId) {
  final id = normalizeSucculentStageId(stageId);
  return switch (id) {
    SucculentStageIds.installationEstablishment =>
      'Prioridad: evitar tierra encharcada y sustrato apretado',
    SucculentStageIds.rootEstablishment =>
      'Prioridad: raíz firme, buen drenaje y temperatura estable',
    SucculentStageIds.activeGrowth =>
      'Creciendo: agua medida, sin encharcar y sales bajo control',
    SucculentStageIds.maintenance =>
      'Estable: no riegues por calendario y cuida la acumulación de sales',
    SucculentStageIds.rest =>
      'Reposo: protégela del frío húmedo y no la fuerces a crecer',
    _ => 'BIO-G interpreta tus sensores según el estado de la planta',
  };
}

/// Confianza (0..1) de una etapa ya persistida + su ancla. Uso interno.
double succulentStageConfidence({
  required String? stageId,
  required DateTime? anchorDate,
  required String? anchorTypeId,
}) {
  final id = normalizeSucculentStageId(stageId);
  if (id == SucculentStageIds.unknown) return SucculentStageConfidence.unknown;
  final anchorType = normalizeSucculentAnchorTypeId(anchorTypeId);
  if (anchorDate == null) {
    return switch (id) {
      SucculentStageIds.activeGrowth => 0.85,
      SucculentStageIds.maintenance => 0.65,
      SucculentStageIds.rest => 0.50,
      SucculentStageIds.installationEstablishment ||
      SucculentStageIds.rootEstablishment =>
        anchorType == SucculentAnchorTypeIds.manualStage ? 0.75 : 0.40,
      _ => SucculentStageConfidence.unknown,
    };
  }
  if (anchorType == SucculentAnchorTypeIds.manualStage) return 0.80;
  return switch (id) {
    SucculentStageIds.installationEstablishment =>
      SucculentStageConfidence.byRecentAnchor,
    SucculentStageIds.rootEstablishment =>
      SucculentStageConfidence.byEstablishmentWindow,
    SucculentStageIds.maintenance =>
      SucculentStageConfidence.byMaintenanceWindow,
    _ => 0.35,
  };
}

/// Transiciones permitidas (Doc A §5.5). Ninguna vuelve a instalación: eso
/// sería un reinicio de vida, y una planta de maceta no vuelve a nacer.
const Map<String, Set<String>> succulentAllowedStageTransitions =
    <String, Set<String>>{
      SucculentStageIds.installationEstablishment: <String>{
        SucculentStageIds.rootEstablishment,
      },
      SucculentStageIds.rootEstablishment: <String>{
        SucculentStageIds.activeGrowth,
        SucculentStageIds.maintenance,
      },
      SucculentStageIds.activeGrowth: <String>{
        SucculentStageIds.maintenance,
        SucculentStageIds.rest,
      },
      SucculentStageIds.maintenance: <String>{
        SucculentStageIds.activeGrowth,
        SucculentStageIds.rest,
      },
      SucculentStageIds.rest: <String>{
        SucculentStageIds.activeGrowth,
        SucculentStageIds.maintenance,
      },
      SucculentStageIds.unknown: SucculentStageIds.all,
    };

bool isAllowedSucculentStageTransition(String? from, String? to) {
  final source = normalizeSucculentStageId(from);
  final target = normalizeSucculentStageId(to);
  if (source == target) return true;
  return succulentAllowedStageTransitions[source]?.contains(target) ?? false;
}

/// True cuando el cultivo es Suculenta. La categoría ornamental por sí sola no
/// basta: así ninguna otra ornamental hereda accidentalmente esta biología.
bool isSucculentCrop({
  String? cropId,
  String? cropCategoryId,
  CropCategory? category,
}) {
  final canonicalCropId = CropCatalog.canonicalCropKey(cropId);
  if (canonicalCropId == kSucculentCropId) return true;

  if (category == CropCategory.ornamental) {
    return false;
  }

  final normalizedCategory = cropCategoryId?.trim().toLowerCase();
  if (normalizedCategory == kSucculentOrnamentalCategoryId) {
    return CropCatalog.cropById(canonicalCropId)?.cropId == kSucculentCropId;
  }
  return false;
}

bool isSucculentContext(DeviceCropContext? context) {
  if (context == null) return false;
  return isSucculentCrop(
    cropId: context.cropId,
    cropCategoryId: context.cropCategoryId,
  );
}

/// Id canónico del cultivo suculenta y de la categoría ornamental.
const String kSucculentCropId = kCropSucculent;
const String kSucculentOrnamentalCategoryId = 'ornamental';
