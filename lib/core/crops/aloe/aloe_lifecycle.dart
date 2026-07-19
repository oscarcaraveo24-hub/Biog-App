import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/aloe/aloe_catalog.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Dominio del ciclo de vida ORNAMENTAL de la Sábila / Aloe (Documento A del
/// paquete SA v1.0). Espejo ESTRUCTURAL de `succulent_lifecycle.dart`: mismo
/// modo (`establishment_maintenance`), misma arquitectura… y biología propia.
///
/// Reglas no negociables (Doc A §5.6, §5.7):
/// - `maintenance` NUNCA se convierte en fin de ciclo (no `cycle_complete`).
/// - NO hay rendimiento ni cosecha (supportsYieldProjection=false). Cortar
///   hojas para gel es un evento, no cosecha ni etapa.
/// - Estrés, recuperación, pudrición, floración y emisión de hijuelos NO son
///   etapas.
/// - `rest` no se infiere por calendario/mes: requiere confirmación.
/// - Cambiar de perfil NO reinicia la edad de la planta.
class AloeLifecycle {
  const AloeLifecycle._();

  /// Modo de ciclo. No es siembra→cosecha: es establecimiento y luego
  /// mantenimiento indefinido.
  static const String lifecycleMode = 'establishment_maintenance';

  // ── Capacidades congeladas (Doc A §0.2, §5.7) ──────────────────────────────
  static const bool supportsYieldProjection = false;
  static const bool supportsHarvest = false;
  static const bool supportsRecurringBloom = false;

  /// DESCARTADO en v1 (Doc A §0.3 #15). El microciclo hídrico exige un baseline
  /// por dispositivo que BIO-G no tiene. El agua se interpreta con la lectura
  /// real de humedad contra los targets de la etapa.
  static const bool supportsHydricCycle = false;

  /// DESCARTADO en v1 (Doc A §0.3 #15, Doc C §0.3). No se declara una capacidad
  /// que no existe.
  static const bool supportsStressMemory = false;
}

/// Intenciones del wizard de Sábila. **Solo dos** (Doc A §6.2).
///
/// No se agrega "la voy a cambiar de maceta", "es un hijuelo", "es joven",
/// "está estresada" ni "la voy a cortar": no son formas de dar de alta una
/// planta. Un contexto antiguo con `repot` se lee como "ya está plantada".
class AloeSetupIntentIds {
  const AloeSetupIntentIds._();

  static const String plannedPlant = 'planned_plant';
  static const String alreadyPlanted = 'already_planted';

  static const Set<String> all = <String>{plannedPlant, alreadyPlanted};
}

/// Acepta los IDs actuales y los heredados. Un valor desconocido se trata de
/// forma conservadora como una planta que ya existe, nunca como una plantación
/// futura.
String normalizeAloeSetupIntentId(String? intentId) {
  final value = intentId?.trim().toLowerCase();
  return switch (value) {
    AloeSetupIntentIds.plannedPlant ||
    'planned' ||
    'plant' => AloeSetupIntentIds.plannedPlant,
    AloeSetupIntentIds.alreadyPlanted ||
    'planted' ||
    'growing' ||
    'repot' ||
    'transplant' => AloeSetupIntentIds.alreadyPlanted,
    _ => AloeSetupIntentIds.alreadyPlanted,
  };
}

/// Solo "la voy a plantar" pide una fecha futura.
bool aloeSetupIntentRequiresFutureDate(String? intentId) {
  return normalizeAloeSetupIntentId(intentId) ==
      AloeSetupIntentIds.plannedPlant;
}

/// Etapas de vida (Doc A §5.1). Estrés, recuperación y declive NO están aquí:
/// no son etapas, son observaciones de sanidad.
class AloeStageIds {
  const AloeStageIds._();

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
class AloeAnchorTypeIds {
  const AloeAnchorTypeIds._();

  static const String installation = 'installation';
  static const String repot = 'repot';
  static const String stageStart = 'stage_start';
  static const String manualStage = 'manual_stage';
  static const String unknown = 'unknown';
}

/// Confianza interna de una etapa estimada por fecha. NUNCA se muestra al
/// usuario (Doc A §8: nada de "confianza 0.42").
class AloeStageConfidence {
  const AloeStageConfidence._();

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
class AloeStageEstimate {
  const AloeStageEstimate({
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
// Son defaults de implementación, no límites biológicos universales. Coinciden
// con las del cactus (0-14 / 15-84 / 85-365) porque la evidencia de la sábila
// cae en los mismos cortes, NO por copiar-pegar (Doc A §5.4):
//
//    0 - 14 d     Recién plantada   (suberización + arranque)
//   15 - 84 d     Echando raíz      (12 semanas = techo del "establecimiento 1-3 meses")
//   85 - 365 d    Creciendo         (aquí el NPK pesa de verdad)
//     > 365 d     Estable           ← AQUÍ SE QUEDA PARA SIEMPRE
const int _kInstallationMaxDays = 14;
const int _kRootMaxDays = 84;
const int _kActiveGrowthMaxDays = 365;

double _dateInferenceConfidence(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  return id == kSaSkip ? 0.40 : 0.45;
}

/// Propone la etapa a partir de la fecha de plantación.
///
/// **Es una progresión de UNA SOLA PASADA, no un ciclo.** Avanza y desemboca en
/// `maintenance`, donde se queda para siempre. No hay reinicio, ni día terminal.
///
/// ```
/// Recién plantada → Echando raíz → Creciendo → Estable ──┐
///    (0-14 d)        (15-84 d)     (85-365 d)  (>365 d)  │
///                                                  ▲      │
///                                                  └──────┘
///                                             aquí se queda
/// ```
///
/// `rest` (En reposo) NO se infiere por fecha ni por mes: la sábila tiene reposo
/// invernal documentado, pero BIO-G opera de Ensenada a Mérida y no tiene modelo
/// climático por región (Doc A §5.3). Solo por confirmación.
AloeStageEstimate estimateAloeStageFromDate({
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
}) {
  if (plantingDate == null) {
    return const AloeStageEstimate(
      stageId: AloeStageIds.unknown,
      anchorTypeId: AloeAnchorTypeIds.unknown,
      confidence: AloeStageConfidence.unknown,
    );
  }

  final int days = now
      .difference(
        DateTime(plantingDate.year, plantingDate.month, plantingDate.day),
      )
      .inDays;

  // Fecha futura (planeada) o el mismo día: recién colocada.
  if (days <= 0) {
    return AloeStageEstimate(
      stageId: AloeStageIds.installationEstablishment,
      anchorTypeId: AloeAnchorTypeIds.installation,
      confidence: _dateInferenceConfidence(profileId),
    );
  }

  // 1) Recién plantada: la raíz todavía se suberiza y arranca.
  if (days <= _kInstallationMaxDays) {
    return AloeStageEstimate(
      stageId: AloeStageIds.installationEstablishment,
      anchorTypeId: AloeAnchorTypeIds.installation,
      confidence: _dateInferenceConfidence(profileId),
    );
  }

  // 2) Echando raíz: hasta ~12 semanas de establecimiento radicular.
  if (days <= _kRootMaxDays) {
    return AloeStageEstimate(
      stageId: AloeStageIds.rootEstablishment,
      anchorTypeId: AloeAnchorTypeIds.stageStart,
      confidence: _dateInferenceConfidence(
        profileId,
      ).clamp(0.0, 0.40).toDouble(),
    );
  }

  // 3) Creciendo: ya arraigó. Es la etapa donde el NPK pesa de verdad.
  if (days <= _kActiveGrowthMaxDays) {
    return const AloeStageEstimate(
      stageId: AloeStageIds.activeGrowth,
      anchorTypeId: AloeAnchorTypeIds.stageStart,
      confidence: AloeStageConfidence.byEstablishmentWindow,
    );
  }

  // 4) Estable. AQUÍ SE QUEDA PARA SIEMPRE. No hay fin de ciclo ni reinicio.
  return const AloeStageEstimate(
    stageId: AloeStageIds.maintenance,
    anchorTypeId: AloeAnchorTypeIds.installation,
    confidence: AloeStageConfidence.byMaintenanceWindow,
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
AloeStageEstimate resolveAloeSetupStage({
  required String? intentId,
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
  String? previousStageId,
}) {
  final String intent = normalizeAloeSetupIntentId(intentId);

  if (intent == AloeSetupIntentIds.plannedPlant) {
    return AloeStageEstimate(
      stageId: AloeStageIds.installationEstablishment,
      anchorTypeId: AloeAnchorTypeIds.installation,
      confidence: plantingDate == null
          ? AloeStageConfidence.unknown
          : AloeStageConfidence.byRecentAnchor,
    );
  }

  // Ya está plantada. Si el usuario ya había confirmado una etapa, se respeta.
  final String previous = normalizeAloeStageId(previousStageId);
  if (previous != AloeStageIds.unknown) {
    return AloeStageEstimate(
      stageId: previous,
      anchorTypeId: AloeAnchorTypeIds.installation,
      confidence: aloeStageConfidence(
        stageId: previous,
        anchorDate: plantingDate,
        anchorTypeId: AloeAnchorTypeIds.installation,
      ),
    );
  }

  if (plantingDate != null) {
    return estimateAloeStageFromDate(
      plantingDate: plantingDate,
      now: now,
      profileId: profileId,
    );
  }

  // "Ya está plantada" pero no recuerda la fecha: está establecida.
  return const AloeStageEstimate(
    stageId: AloeStageIds.maintenance,
    anchorTypeId: AloeAnchorTypeIds.unknown,
    confidence: AloeStageConfidence.unknown,
  );
}

/// Normaliza un id de etapa (acepta alias heredados). Desconocido → `unknown`.
String normalizeAloeStageId(String? stageId) {
  final value = stageId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return AloeStageIds.unknown;
  if (AloeStageIds.all.contains(value)) return value;
  switch (value) {
    case 'planned':
    case 'installation':
    case 'repot':
    case 'transplant':
      return AloeStageIds.installationEstablishment;
    case 'rooting':
    case 'establishing':
      return AloeStageIds.rootEstablishment;
    case 'growing':
    case 'active':
      return AloeStageIds.activeGrowth;
    case 'stable':
    case 'established':
      return AloeStageIds.maintenance;
    case 'dormant':
    case 'resting':
      return AloeStageIds.rest;
  }
  return AloeStageIds.unknown;
}

String normalizeAloeAnchorTypeId(String? anchorTypeId) {
  final value = anchorTypeId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return AloeAnchorTypeIds.unknown;
  switch (value) {
    case AloeAnchorTypeIds.installation:
    case AloeAnchorTypeIds.repot:
    case AloeAnchorTypeIds.stageStart:
    case AloeAnchorTypeIds.manualStage:
    case AloeAnchorTypeIds.unknown:
      return value;
  }
  return AloeAnchorTypeIds.unknown;
}

/// Nombre de la etapa, en lenguaje de agricultor (Doc A §5.2). Sin jerga.
String aloeStageDisplayName(String? stageId) {
  final id = normalizeAloeStageId(stageId);
  return switch (id) {
    AloeStageIds.installationEstablishment => 'Recién plantada',
    AloeStageIds.rootEstablishment => 'Echando raíz',
    AloeStageIds.activeGrowth => 'Creciendo',
    AloeStageIds.maintenance => 'Estable',
    AloeStageIds.rest => 'En reposo',
    _ => 'Etapa por confirmar',
  };
}

/// Ventana crítica de la etapa.
String? aloeCriticalWindowLabel(String? stageId) {
  final id = normalizeAloeStageId(stageId);
  return switch (id) {
    AloeStageIds.installationEstablishment =>
      'Ventana crítica: recién plantada',
    AloeStageIds.rootEstablishment => 'Ventana crítica: echando raíz',
    AloeStageIds.rest => 'Ventana importante: reposo',
    _ => null,
  };
}

/// Prioridad de cuidado por etapa (Doc B §8).
String aloeStagePriorityText(String? stageId) {
  final id = normalizeAloeStageId(stageId);
  return switch (id) {
    AloeStageIds.installationEstablishment =>
      'Prioridad: evitar tierra encharcada y sustrato apretado',
    AloeStageIds.rootEstablishment =>
      'Prioridad: raíz firme, buen drenaje y temperatura estable',
    AloeStageIds.activeGrowth =>
      'Creciendo: agua medida, sin encharcar y sales bajo control',
    AloeStageIds.maintenance =>
      'Estable: no riegues por calendario y cuida la acumulación de sales',
    AloeStageIds.rest =>
      'Reposo: protégela del frío húmedo y no la fuerces a crecer',
    _ => 'BIO-G interpreta tus sensores según el estado de la planta',
  };
}

/// Confianza (0..1) de una etapa ya persistida + su ancla. Uso interno.
double aloeStageConfidence({
  required String? stageId,
  required DateTime? anchorDate,
  required String? anchorTypeId,
}) {
  final id = normalizeAloeStageId(stageId);
  if (id == AloeStageIds.unknown) return AloeStageConfidence.unknown;
  final anchorType = normalizeAloeAnchorTypeId(anchorTypeId);
  if (anchorDate == null) {
    return switch (id) {
      AloeStageIds.activeGrowth => 0.85,
      AloeStageIds.maintenance => 0.65,
      AloeStageIds.rest => 0.50,
      AloeStageIds.installationEstablishment ||
      AloeStageIds.rootEstablishment =>
        anchorType == AloeAnchorTypeIds.manualStage ? 0.75 : 0.40,
      _ => AloeStageConfidence.unknown,
    };
  }
  if (anchorType == AloeAnchorTypeIds.manualStage) return 0.80;
  return switch (id) {
    AloeStageIds.installationEstablishment =>
      AloeStageConfidence.byRecentAnchor,
    AloeStageIds.rootEstablishment =>
      AloeStageConfidence.byEstablishmentWindow,
    AloeStageIds.maintenance =>
      AloeStageConfidence.byMaintenanceWindow,
    _ => 0.35,
  };
}

/// Transiciones permitidas (Doc A §5.5). Ninguna vuelve a instalación: eso
/// sería un reinicio de vida, y una planta de maceta no vuelve a nacer.
const Map<String, Set<String>> aloeAllowedStageTransitions =
    <String, Set<String>>{
      AloeStageIds.installationEstablishment: <String>{
        AloeStageIds.rootEstablishment,
      },
      AloeStageIds.rootEstablishment: <String>{
        AloeStageIds.activeGrowth,
        AloeStageIds.maintenance,
      },
      AloeStageIds.activeGrowth: <String>{
        AloeStageIds.maintenance,
        AloeStageIds.rest,
      },
      AloeStageIds.maintenance: <String>{
        AloeStageIds.activeGrowth,
        AloeStageIds.rest,
      },
      AloeStageIds.rest: <String>{
        AloeStageIds.activeGrowth,
        AloeStageIds.maintenance,
      },
      AloeStageIds.unknown: AloeStageIds.all,
    };

bool isAllowedAloeStageTransition(String? from, String? to) {
  final source = normalizeAloeStageId(from);
  final target = normalizeAloeStageId(to);
  if (source == target) return true;
  return aloeAllowedStageTransitions[source]?.contains(target) ?? false;
}

/// True cuando el cultivo es Sábila. La categoría ornamental por sí sola no
/// basta: así ninguna otra ornamental hereda accidentalmente esta biología.
bool isAloeCrop({
  String? cropId,
  String? cropCategoryId,
  CropCategory? category,
}) {
  final canonicalCropId = CropCatalog.canonicalCropKey(cropId);
  if (canonicalCropId == kAloeCropId) return true;

  if (category == CropCategory.ornamental) {
    return false;
  }

  final normalizedCategory = cropCategoryId?.trim().toLowerCase();
  if (normalizedCategory == kAloeOrnamentalCategoryId) {
    return CropCatalog.cropById(canonicalCropId)?.cropId == kAloeCropId;
  }
  return false;
}

bool isAloeContext(DeviceCropContext? context) {
  if (context == null) return false;
  return isAloeCrop(
    cropId: context.cropId,
    cropCategoryId: context.cropCategoryId,
  );
}

/// Id canónico del cultivo sábila y de la categoría ornamental.
const String kAloeCropId = kCropAloe;
const String kAloeOrnamentalCategoryId = 'ornamental';
