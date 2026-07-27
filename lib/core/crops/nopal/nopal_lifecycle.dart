import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/nopal/nopal_catalog.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Dominio del ciclo de vida ORNAMENTAL del Nopal (Documento A del paquete
/// NO v1.0). Espejo ESTRUCTURAL de `agave_lifecycle.dart` y
/// `cactus_lifecycle.dart`: mismo modo (`establishment_maintenance`), misma
/// arquitectura… y biología propia (arraigo de penca rápido, mantenimiento de
/// décadas, eventos de floración y fruto que NO son etapas).
///
/// Reglas no negociables (Doc A §0.2, §0.3, §9):
/// - `maintenance` NUNCA se convierte en fin de ciclo (no `cycle_complete`); un
///   nopal plantado hace veinte años sigue en "Estable".
/// - NO hay rendimiento ni cosecha (supportsYieldProjection=false). La flor y la
///   tuna son eventos visibles, no etapas ni cosecha.
/// - Cortar una penca o retirar una tuna NO reinicia `installation_establishment`
///   ni cambia el stageId. Una penca separada solo inicia una planta nueva si el
///   usuario la registra como cultivo independiente.
/// - Estrés, recuperación, declive y pudrición NO son etapas: son condiciones
///   sanitarias del Documento C.
/// - `rest` no se infiere por calendario, mes ni sequedad: requiere confirmación.
/// - Cambiar de perfil NO cambia la etapa; cambiar de etapa NO cambia el perfil.
class NopalLifecycle {
  const NopalLifecycle._();

  /// Modo de ciclo. No es siembra→cosecha: es establecimiento y luego
  /// mantenimiento indefinido.
  static const String lifecycleMode = 'establishment_maintenance';

  // ── Capacidades congeladas (Doc A §0.1) ────────────────────────────────────
  static const bool supportsYieldProjection = false;
  static const bool supportsHarvest = false;
  static const bool supportsRecurringBloom = false;

  /// DESCARTADO en v1 (Doc A §0.1, §2.8). El microciclo hídrico exige un
  /// baseline por dispositivo que BIO-G no tiene. El agua se interpreta con la
  /// lectura real de humedad contra los targets de la etapa.
  static const bool supportsHydricCycle = false;

  /// DESCARTADO en v1 (Doc A §2.8). No se declara una capacidad que no existe.
  static const bool supportsStressMemory = false;

  /// Label de alcance visible (Doc A §0.3). NO activa ninguna capacidad
  /// productiva: es una aclaración de quién decide el aprovechamiento.
  static const String scopeLabelEs = 'Nopal ornamental · aprovechamiento manual';

  static const String scopeSubtitleEs =
      'BIO-G cuida la planta; tú decides cuándo cortar pencas o tunas.';
}

/// Intenciones del wizard de Nopal. **Solo dos** (Doc A §13).
///
/// No se agrega "es una penca", "lo voy a podar", "es joven" ni "ya dio tuna":
/// no son formas de dar de alta una planta. Un contexto antiguo con `repot` se
/// lee como "ya está plantado".
class NopalSetupIntentIds {
  const NopalSetupIntentIds._();

  static const String plannedPlant = 'planned_plant';
  static const String alreadyPlanted = 'already_planted';

  static const Set<String> all = <String>{plannedPlant, alreadyPlanted};
}

/// Acepta los IDs actuales y los heredados. Un valor desconocido se trata de
/// forma conservadora como una planta que ya existe, nunca como una plantación
/// futura.
String normalizeNopalSetupIntentId(String? intentId) {
  final value = intentId?.trim().toLowerCase();
  return switch (value) {
    NopalSetupIntentIds.plannedPlant ||
    'planned' ||
    'plant' => NopalSetupIntentIds.plannedPlant,
    NopalSetupIntentIds.alreadyPlanted ||
    'planted' ||
    'growing' ||
    'repot' ||
    'transplant' => NopalSetupIntentIds.alreadyPlanted,
    _ => NopalSetupIntentIds.alreadyPlanted,
  };
}

/// Solo "lo voy a plantar" pide una fecha futura.
bool nopalSetupIntentRequiresFutureDate(String? intentId) {
  return normalizeNopalSetupIntentId(intentId) ==
      NopalSetupIntentIds.plannedPlant;
}

/// Etapas de vida (Doc A §9.2). La floración, el fruto, la poda, el corte de
/// penca y el daño sanitario NO están aquí: no son etapas, son eventos u
/// observaciones.
class NopalStageIds {
  const NopalStageIds._();

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
class NopalAnchorTypeIds {
  const NopalAnchorTypeIds._();

  static const String installation = 'installation';
  static const String repot = 'repot';
  static const String stageStart = 'stage_start';
  static const String manualStage = 'manual_stage';
  static const String unknown = 'unknown';
}

/// Confianza interna de una etapa estimada por fecha. NUNCA se muestra al
/// usuario (Doc A §2.8: nada de "confianza 0.25").
class NopalStageConfidence {
  const NopalStageConfidence._();

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
class NopalStageEstimate {
  const NopalStageEstimate({
    required this.stageId,
    required this.anchorTypeId,
    required this.confidence,
  });

  final String stageId;
  final String anchorTypeId;
  final double confidence;
}

// ── Ventanas por fecha (Doc A §12.1) ─────────────────────────────────────────
//
// Son defaults de INGENIERÍA para el seguimiento ornamental, NO la edad de
// floración ni la edad productiva:
//
//   Perfil estándar              NO-02 (ejemplar grande)
//     0 -   21 d  Recién plantado    0 -   30 d  Recién plantado
//    22 -  120 d  Echando raíz      31 -  120 d  Echando raíz
//   121 -  540 d  Creciendo        121 -  540 d  Creciendo
//      > 540 d    Estable             > 540 d    Estable  ← AQUÍ SE QUEDA
//
// NO-02 recibe una ventana de instalación más larga porque un ejemplar grande
// trasplantado establece más lento (Doc A §12.1, §6.2). La fecha ayuda; la fecha
// NO demuestra por sí sola que la raíz esté establecida (Doc A §2.5).
const int _kInstallationMaxDaysStandard = 21;
const int _kInstallationMaxDaysLargeSpecimen = 30;
const int _kRootMaxDays = 120;
const int _kActiveGrowthMaxDays = 540;

/// NO-02 (nopal alto o de penca grande) usa la ventana larga de instalación.
int nopalInstallationWindowDays(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  return id == kNopal02UprightLargePadWarm
      ? _kInstallationMaxDaysLargeSpecimen
      : _kInstallationMaxDaysStandard;
}

double _dateInferenceConfidence(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  return id == kNopalSkip ? 0.40 : 0.45;
}

/// Propone la etapa a partir de la fecha de plantación.
///
/// **Es una progresión de UNA SOLA PASADA, no un ciclo.** Avanza y desemboca en
/// `maintenance`, donde se queda para siempre. No hay reinicio, ni día terminal
/// (Doc A §0.2, §0.5): a 1, 5, 20 o más años sigue en `maintenance`.
///
/// ```
/// Recién plantado → Echando raíz → Creciendo → Estable ─┐
///    (0-21 d)        (22-120 d)   (121-540 d)  (>540 d)  │
///                                                 ▲      │
///                                                 └──────┘
///                                            aquí se queda
/// ```
///
/// `rest` (En reposo) NO se infiere por fecha ni por mes: la estacionalidad
/// cambia por especie y clima, y BIO-G opera en todo México sin modelo climático
/// por región. Solo por confirmación (Doc A §9.4).
NopalStageEstimate estimateNopalStageFromDate({
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
}) {
  if (plantingDate == null) {
    return const NopalStageEstimate(
      stageId: NopalStageIds.unknown,
      anchorTypeId: NopalAnchorTypeIds.unknown,
      confidence: NopalStageConfidence.unknown,
    );
  }

  final int days = now
      .difference(
        DateTime(plantingDate.year, plantingDate.month, plantingDate.day),
      )
      .inDays;

  // Fecha futura (planeada) o el mismo día: recién colocado.
  if (days <= 0) {
    return NopalStageEstimate(
      stageId: NopalStageIds.installationEstablishment,
      anchorTypeId: NopalAnchorTypeIds.installation,
      confidence: _dateInferenceConfidence(profileId),
    );
  }

  // 1) Recién plantado: la penca o la raíz todavía no tiene contacto estable.
  //    NO-02 usa la ventana larga (30 d) por ser ejemplar grande.
  if (days <= nopalInstallationWindowDays(profileId)) {
    return NopalStageEstimate(
      stageId: NopalStageIds.installationEstablishment,
      anchorTypeId: NopalAnchorTypeIds.installation,
      confidence: _dateInferenceConfidence(profileId),
    );
  }

  // 2) Echando raíz: hasta ~4 meses de establecimiento radicular.
  if (days <= _kRootMaxDays) {
    return NopalStageEstimate(
      stageId: NopalStageIds.rootEstablishment,
      anchorTypeId: NopalAnchorTypeIds.stageStart,
      confidence: _dateInferenceConfidence(
        profileId,
      ).clamp(0.0, 0.40).toDouble(),
    );
  }

  // 3) Creciendo: ya arraigó. Es la etapa donde el NPK pesa de verdad y donde
  //    la emisión de pencas nuevas consume más agua.
  if (days <= _kActiveGrowthMaxDays) {
    return const NopalStageEstimate(
      stageId: NopalStageIds.activeGrowth,
      anchorTypeId: NopalAnchorTypeIds.stageStart,
      confidence: NopalStageConfidence.byEstablishmentWindow,
    );
  }

  // 4) Estable. AQUÍ SE QUEDA PARA SIEMPRE. No hay fin de ciclo, ni reinicio,
  //    ni proyección de tunas (Doc A §0.5, prueba de oro).
  return const NopalStageEstimate(
    stageId: NopalStageIds.maintenance,
    anchorTypeId: NopalAnchorTypeIds.installation,
    confidence: NopalStageConfidence.byMaintenanceWindow,
  );
}

/// FUENTE ÚNICA de la etapa que resulta del wizard (Doc A §13). La usan tanto el
/// onboarding (`bootstrap_gate`) como el wizard de cuenta
/// (`configure_seed_wizard_screen`). La UI no duplica reglas de fechas.
///
/// Reglas:
/// - **"Lo voy a plantar"** → siempre `installation_establishment`.
/// - **"Ya está plantado"** → se respeta la etapa previa si el usuario ya la
///   había confirmado; si no, se estima por la fecha; y si no hay fecha, se
///   asume `maintenance` (Estable), porque el usuario acaba de declarar que la
///   planta ya existe. NUNCA se queda en "Etapa por confirmar" (Doc A §12.3).
NopalStageEstimate resolveNopalSetupStage({
  required String? intentId,
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
  String? previousStageId,
}) {
  final String intent = normalizeNopalSetupIntentId(intentId);

  if (intent == NopalSetupIntentIds.plannedPlant) {
    return NopalStageEstimate(
      stageId: NopalStageIds.installationEstablishment,
      anchorTypeId: NopalAnchorTypeIds.installation,
      confidence: plantingDate == null
          ? NopalStageConfidence.unknown
          : NopalStageConfidence.byRecentAnchor,
    );
  }

  // Ya está plantado. Si el usuario ya había confirmado una etapa, se respeta.
  final String previous = normalizeNopalStageId(previousStageId);
  if (previous != NopalStageIds.unknown) {
    return NopalStageEstimate(
      stageId: previous,
      anchorTypeId: NopalAnchorTypeIds.installation,
      confidence: nopalStageConfidence(
        stageId: previous,
        anchorDate: plantingDate,
        anchorTypeId: NopalAnchorTypeIds.installation,
      ),
    );
  }

  if (plantingDate != null) {
    return estimateNopalStageFromDate(
      plantingDate: plantingDate,
      now: now,
      profileId: profileId,
    );
  }

  // "Ya está plantado" pero no recuerda la fecha: está establecido (Doc A §12.3).
  return const NopalStageEstimate(
    stageId: NopalStageIds.maintenance,
    anchorTypeId: NopalAnchorTypeIds.unknown,
    confidence: NopalStageConfidence.unknown,
  );
}

/// Normaliza un id de etapa (acepta alias heredados, incluidos los de las fichas
/// NP-*). Desconocido → `unknown`.
String normalizeNopalStageId(String? stageId) {
  final value = stageId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return NopalStageIds.unknown;
  if (NopalStageIds.all.contains(value)) return value;
  switch (value) {
    case 'planned':
    case 'installation':
    case 'repot':
    case 'transplant':
    // Ficha histórica NP-04 "Nopal joven / establecimiento": era un perfil de
    // edad y se convierte en etapa (Doc A §2.3, §8.3).
    case 'np-04':
    case 'np_04':
      return NopalStageIds.installationEstablishment;
    case 'rooting':
    case 'establishing':
      return NopalStageIds.rootEstablishment;
    case 'growing':
    case 'active':
      return NopalStageIds.activeGrowth;
    case 'stable':
    case 'established':
    case 'mature':
      return NopalStageIds.maintenance;
    case 'dormant':
    case 'resting':
      return NopalStageIds.rest;
  }
  return NopalStageIds.unknown;
}

String normalizeNopalAnchorTypeId(String? anchorTypeId) {
  final value = anchorTypeId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return NopalAnchorTypeIds.unknown;
  switch (value) {
    case NopalAnchorTypeIds.installation:
    case NopalAnchorTypeIds.repot:
    case NopalAnchorTypeIds.stageStart:
    case NopalAnchorTypeIds.manualStage:
    case NopalAnchorTypeIds.unknown:
      return value;
  }
  return NopalAnchorTypeIds.unknown;
}

/// Nombre de la etapa, en lenguaje de agricultor (Doc A §9.3). Sin jerga: nada
/// de "emisión de cladodios", "estado estético adulto" ni "fase vegetativa".
String nopalStageDisplayName(String? stageId) {
  final id = normalizeNopalStageId(stageId);
  return switch (id) {
    NopalStageIds.installationEstablishment => 'Recién plantado',
    NopalStageIds.rootEstablishment => 'Echando raíz',
    NopalStageIds.activeGrowth => 'Creciendo',
    NopalStageIds.maintenance => 'Estable',
    NopalStageIds.rest => 'En reposo',
    _ => 'Etapa por confirmar',
  };
}

/// Ventana crítica de la etapa.
String? nopalCriticalWindowLabel(String? stageId) {
  final id = normalizeNopalStageId(stageId);
  return switch (id) {
    NopalStageIds.installationEstablishment =>
      'Ventana crítica: recién plantado',
    NopalStageIds.rootEstablishment => 'Ventana crítica: echando raíz',
    NopalStageIds.rest => 'Ventana importante: reposo',
    _ => null,
  };
}

/// Prioridad de cuidado por etapa (Doc B §20). Nunca implica corte ni cosecha:
/// el aprovechamiento lo decide el usuario.
String nopalStagePriorityText(String? stageId) {
  final id = normalizeNopalStageId(stageId);
  return switch (id) {
    NopalStageIds.installationEstablishment =>
      'Prioridad: contacto con el suelo, drenaje y no regar de más',
    NopalStageIds.rootEstablishment =>
      'Prioridad: humedad pareja sin saturar, suelo suelto y temperatura estable',
    NopalStageIds.activeGrowth =>
      'Creciendo: puede pedir más agua al sacar pencas; vigila sales y drenaje',
    NopalStageIds.maintenance =>
      'Estable: no riegues por calendario y revisa las sales. Cortar una penca '
          'no cambia su etapa',
    NopalStageIds.rest =>
      'Reposo: protégelo del frío húmedo y no lo fuerces a crecer',
    _ => 'BIO-G interpreta tus sensores según el estado de la planta',
  };
}

/// Confianza (0..1) de una etapa ya persistida + su ancla. Uso interno.
double nopalStageConfidence({
  required String? stageId,
  required DateTime? anchorDate,
  required String? anchorTypeId,
}) {
  final id = normalizeNopalStageId(stageId);
  if (id == NopalStageIds.unknown) return NopalStageConfidence.unknown;
  final anchorType = normalizeNopalAnchorTypeId(anchorTypeId);
  if (anchorDate == null) {
    return switch (id) {
      NopalStageIds.activeGrowth => 0.85,
      NopalStageIds.maintenance => 0.65,
      NopalStageIds.rest => 0.50,
      NopalStageIds.installationEstablishment ||
      NopalStageIds.rootEstablishment =>
        anchorType == NopalAnchorTypeIds.manualStage ? 0.75 : 0.40,
      _ => NopalStageConfidence.unknown,
    };
  }
  if (anchorType == NopalAnchorTypeIds.manualStage) return 0.80;
  return switch (id) {
    NopalStageIds.installationEstablishment =>
      NopalStageConfidence.byRecentAnchor,
    NopalStageIds.rootEstablishment =>
      NopalStageConfidence.byEstablishmentWindow,
    NopalStageIds.maintenance => NopalStageConfidence.byMaintenanceWindow,
    _ => 0.35,
  };
}

/// Transiciones permitidas (Doc A §9.4). Ninguna vuelve a instalación de forma
/// automática: eso sería un reinicio de vida. `maintenance` nunca pasa a
/// `cycle_complete`.
///
/// Prohibido explícitamente (Doc A §9.4): floración → cosecha, fruto → cosecha,
/// poda → recién plantado, penca dañada → etapa de estrés, cambio de perfil →
/// recién plantado, año nuevo → recién plantado, edad alta → fin de ciclo,
/// morado → reposo automático, sequedad → creciendo, humedad → echando raíz.
const Map<String, Set<String>> nopalAllowedStageTransitions =
    <String, Set<String>>{
      NopalStageIds.installationEstablishment: <String>{
        NopalStageIds.rootEstablishment,
      },
      NopalStageIds.rootEstablishment: <String>{
        NopalStageIds.activeGrowth,
        NopalStageIds.maintenance,
      },
      NopalStageIds.activeGrowth: <String>{
        NopalStageIds.maintenance,
        NopalStageIds.rest,
      },
      NopalStageIds.maintenance: <String>{
        NopalStageIds.activeGrowth,
        NopalStageIds.rest,
      },
      NopalStageIds.rest: <String>{
        NopalStageIds.activeGrowth,
        NopalStageIds.maintenance,
      },
      NopalStageIds.unknown: NopalStageIds.all,
    };

bool isAllowedNopalStageTransition(String? from, String? to) {
  final source = normalizeNopalStageId(from);
  final target = normalizeNopalStageId(to);
  if (source == target) return true;
  return nopalAllowedStageTransitions[source]?.contains(target) ?? false;
}

/// True cuando el cultivo es Nopal. La categoría ornamental por sí sola no
/// basta: así ninguna otra ornamental hereda accidentalmente esta biología, y
/// Nopal nunca cae en el fallback de Cactus (Doc A §2.9).
bool isNopalCrop({
  String? cropId,
  String? cropCategoryId,
  CropCategory? category,
}) {
  final canonicalCropId = CropCatalog.canonicalCropKey(cropId);
  if (canonicalCropId == kNopalCropId) return true;

  if (category == CropCategory.ornamental) {
    return false;
  }

  final normalizedCategory = cropCategoryId?.trim().toLowerCase();
  if (normalizedCategory == kNopalOrnamentalCategoryId) {
    return CropCatalog.cropById(canonicalCropId)?.cropId == kNopalCropId;
  }
  return false;
}

bool isNopalContext(DeviceCropContext? context) {
  if (context == null) return false;
  return isNopalCrop(
    cropId: context.cropId,
    cropCategoryId: context.cropCategoryId,
  );
}

/// Id canónico del cultivo nopal y de la categoría ornamental.
const String kNopalCropId = kCropNopal;
const String kNopalOrnamentalCategoryId = 'ornamental';
