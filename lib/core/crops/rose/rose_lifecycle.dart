import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/rose/rose_catalog.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Dominio del ciclo de vida del Rosal (primera ornamental de floración
/// RECURRENTE de BIO-G). Comparte con las ornamentales de establecimiento la
/// idea de "no hay siembra→cosecha", pero su ciclo es distinto: tras
/// establecerse entra en una repetición abierta de estados de floración que NO
/// se infieren por fecha (Doc A §3).
///
/// Reglas no negociables (Doc A §0.1, §3.3, §9.4):
/// - NO hay rendimiento, cosecha, kg/planta ni t/ha (supportsYieldProjection=false).
/// - `recurring_bloom` NUNCA se convierte en fin de ciclo: un rosal de 20 años
///   sigue activo. No hay etapa terminal, no se reinicia a "recién plantado" por
///   antigüedad ni por un cambio de perfil.
/// - El establecimiento (recién plantado → echando raíz) SÍ se infiere por fecha.
/// - Tras el establecimiento, la etapa (brotando / botones / floración /
///   post-floración / reposo) NO se infiere por fecha: la confirma el usuario de
///   forma visual, o queda `unknown` hasta que la confirme.
/// - NUNCA cae al modelo del Cactus (Doc A §17.5).
class RoseLifecycle {
  const RoseLifecycle._();

  /// Modo de ciclo del rosal. No es siembra→cosecha ni
  /// establecimiento→mantenimiento: es establecimiento y luego un ciclo de
  /// floración recurrente y abierto.
  static const String lifecycleMode = 'recurring_bloom';

  // ── Capacidades congeladas (Doc A §1, §3) ───────────────────────────────────
  static const bool supportsYieldProjection = false;
  static const bool supportsHarvest = false;

  /// El rosal SÍ tiene floración recurrente: es justo lo que lo diferencia de
  /// cactus/suculenta/sábila/maguey y lo que habilita el wizard visual de estado.
  static const bool supportsRecurringBloom = true;

  static const bool supportsHydricCycle = false;
  static const bool supportsStressMemory = false;
}

/// Intenciones del wizard de Rosal. **Solo dos.** Igual que las ornamentales de
/// establecimiento: ¿lo vas a plantar, o ya está plantado?
class RoseSetupIntentIds {
  const RoseSetupIntentIds._();

  static const String plannedPlant = 'planned_plant';
  static const String alreadyPlanted = 'already_planted';

  static const Set<String> all = <String>{plannedPlant, alreadyPlanted};
}

/// Acepta los IDs actuales y los de versiones anteriores del wizard. Un valor
/// desconocido se trata de forma conservadora como una planta que ya existe.
String normalizeRoseSetupIntentId(String? intentId) {
  final value = intentId?.trim().toLowerCase();
  return switch (value) {
    RoseSetupIntentIds.plannedPlant ||
    'planned' ||
    'plant' => RoseSetupIntentIds.plannedPlant,
    RoseSetupIntentIds.alreadyPlanted ||
    'planted' ||
    'growing' ||
    'repot' ||
    'transplant' => RoseSetupIntentIds.alreadyPlanted,
    _ => RoseSetupIntentIds.alreadyPlanted,
  };
}

/// Solo "lo voy a plantar" pide una fecha futura.
bool roseSetupIntentRequiresFutureDate(String? intentId) {
  return normalizeRoseSetupIntentId(intentId) ==
      RoseSetupIntentIds.plannedPlant;
}

/// Etapas del rosal (Doc A §9.2). Dos estructurales (establecimiento, por
/// fecha), cuatro recurrentes (por confirmación visual), una estacional
/// (reposo) y el respaldo `unknown`.
class RoseStageIds {
  const RoseStageIds._();

  // Estructurales (una sola vez, por fecha).
  static const String installationEstablishment = 'installation_establishment';
  static const String rootEstablishment = 'root_establishment';

  // Recurrentes (por confirmación visual del usuario).
  static const String vegetativeFlush = 'vegetative_flush';
  static const String budFormation = 'bud_formation';
  static const String flowering = 'flowering';
  static const String postBloomRecovery = 'post_bloom_recovery';

  // Estacional.
  static const String rest = 'rest';

  // Respaldo.
  static const String unknown = 'unknown';

  static const Set<String> all = <String>{
    installationEstablishment,
    rootEstablishment,
    vegetativeFlush,
    budFormation,
    flowering,
    postBloomRecovery,
    rest,
    unknown,
  };

  /// Estados recurrentes que el usuario confirma visualmente (no por fecha).
  static const Set<String> recurringStates = <String>{
    vegetativeFlush,
    budFormation,
    flowering,
    postBloomRecovery,
    rest,
  };

  /// Estados de establecimiento que SÍ se infieren por fecha.
  static const Set<String> establishmentStages = <String>{
    installationEstablishment,
    rootEstablishment,
  };
}

/// Tipos de anclaje temporal del rosal (Doc A §5). NO es fecha de siembra: es
/// plantación o el inicio aproximado de un estado confirmado por el usuario.
class RoseAnchorTypeIds {
  const RoseAnchorTypeIds._();

  static const String installation = 'installation';
  static const String stageStart = 'stage_start';
  static const String manualStage = 'manual_stage';
  static const String unknown = 'unknown';
}

/// Confianza de una etapa. La derivada de fecha (establecimiento) está topada;
/// la confirmada visualmente por el usuario es alta.
class RoseStageConfidence {
  const RoseStageConfidence._();

  static const double byManualState = 0.80;
  static const double byRecentAnchor = 0.45;
  static const double byEstablishmentWindow = 0.40;
  static const double unknown = 0.25;

  static String labelFor(double confidence) {
    if (confidence >= 0.60) return 'alta';
    if (confidence >= 0.40) return 'media';
    return 'baja';
  }
}

/// Resultado de estimar/resolver la etapa del rosal.
class RoseStageEstimate {
  const RoseStageEstimate({
    required this.stageId,
    required this.anchorTypeId,
    required this.confidence,
  });

  final String stageId;
  final String anchorTypeId;
  final double confidence;
}

// ── Ventanas de establecimiento por fecha (Doc A §3.1) ───────────────────────
//
// SOLO cubren el establecimiento. Después de la raíz, la fecha ya NO decide el
// estado: entra el ciclo recurrente por confirmación visual.
//
//   0 - 14 d    Recién plantado   (installation_establishment)
//  15 - 84 d    Echando raíz      (root_establishment, ~12 semanas)
//    > 84 d     La fecha ya no decide → unknown (el usuario confirma el estado)
const int _kInstallationMaxDays = 14;
const int _kRootMaxDays = 84;

double _dateInferenceConfidence(String? profileId) {
  final id = profileId?.trim().toLowerCase();
  return id == kRoSkip ? 0.40 : 0.45;
}

/// Propone la etapa a partir de la fecha de plantación.
///
/// **Solo cubre el establecimiento.** A diferencia del cactus, el rosal NO
/// desemboca en una etapa "estable" por antigüedad: pasado el establecimiento la
/// fecha no puede decir si está brotando, con botones, floreciendo, en
/// post-floración o en reposo (Doc A §3.3). Por eso, más allá de la ventana de
/// raíz, devuelve `unknown` para que el usuario confirme el estado visualmente.
RoseStageEstimate estimateRoseStageFromDate({
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
}) {
  if (plantingDate == null) {
    return const RoseStageEstimate(
      stageId: RoseStageIds.unknown,
      anchorTypeId: RoseAnchorTypeIds.unknown,
      confidence: RoseStageConfidence.unknown,
    );
  }

  final int days = now
      .difference(
        DateTime(plantingDate.year, plantingDate.month, plantingDate.day),
      )
      .inDays;

  // Fecha futura (planeado) o el mismo día: recién plantado.
  if (days <= 0) {
    return RoseStageEstimate(
      stageId: RoseStageIds.installationEstablishment,
      anchorTypeId: RoseAnchorTypeIds.installation,
      confidence: _dateInferenceConfidence(profileId),
    );
  }

  // 1) Recién plantado: la raíz todavía no trabaja.
  if (days <= _kInstallationMaxDays) {
    return RoseStageEstimate(
      stageId: RoseStageIds.installationEstablishment,
      anchorTypeId: RoseAnchorTypeIds.installation,
      confidence: _dateInferenceConfidence(profileId),
    );
  }

  // 2) Echando raíz: ~12 semanas de arraigo.
  if (days <= _kRootMaxDays) {
    return RoseStageEstimate(
      stageId: RoseStageIds.rootEstablishment,
      anchorTypeId: RoseAnchorTypeIds.stageStart,
      confidence: _dateInferenceConfidence(
        profileId,
      ).clamp(0.0, 0.40).toDouble(),
    );
  }

  // 3) Ya se estableció: la fecha NO puede decidir el estado recurrente. Queda
  //    por confirmar visualmente.
  return const RoseStageEstimate(
    stageId: RoseStageIds.unknown,
    anchorTypeId: RoseAnchorTypeIds.unknown,
    confidence: RoseStageConfidence.unknown,
  );
}

/// FUENTE ÚNICA de la etapa que resulta del wizard. La usan tanto el onboarding
/// (`bootstrap_gate`) como el wizard de cuenta (`configure_seed_wizard_screen`).
///
/// Reglas (Doc A §3, §9.4):
/// - **"Lo voy a plantar"** → siempre `installation_establishment`.
/// - **"Ya está plantado"** → se respeta el estado que el usuario ya confirmó
///   (incluidos los estados recurrentes); si no hay estado confirmado, se estima
///   por fecha SOLO dentro del establecimiento; y si ya pasó el establecimiento
///   sin estado confirmado, queda `unknown` (el usuario debe confirmarlo).
RoseStageEstimate resolveRoseSetupStage({
  required String? intentId,
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
  String? previousStageId,
}) {
  final String intent = normalizeRoseSetupIntentId(intentId);

  if (intent == RoseSetupIntentIds.plannedPlant) {
    return RoseStageEstimate(
      stageId: RoseStageIds.installationEstablishment,
      anchorTypeId: RoseAnchorTypeIds.installation,
      confidence: plantingDate == null
          ? RoseStageConfidence.unknown
          : RoseStageConfidence.byRecentAnchor,
    );
  }

  // Ya está plantado. Si el usuario ya había confirmado un estado, se respeta
  // (incluye los estados recurrentes, que la fecha nunca podría inferir).
  final String previous = normalizeRoseStageId(previousStageId);
  if (previous != RoseStageIds.unknown) {
    return RoseStageEstimate(
      stageId: previous,
      anchorTypeId: RoseStageIds.recurringStates.contains(previous)
          ? RoseAnchorTypeIds.manualStage
          : RoseAnchorTypeIds.installation,
      confidence: roseStageConfidence(
        stageId: previous,
        anchorDate: plantingDate,
        anchorTypeId: RoseStageIds.recurringStates.contains(previous)
            ? RoseAnchorTypeIds.manualStage
            : RoseAnchorTypeIds.installation,
      ),
    );
  }

  if (plantingDate != null) {
    return estimateRoseStageFromDate(
      plantingDate: plantingDate,
      now: now,
      profileId: profileId,
    );
  }

  // "Ya está plantado" pero sin fecha ni estado confirmado: la fecha no puede
  // decidir el estado del rosal. Queda por confirmar (NUNCA "estable" como el
  // cactus: el rosal no tiene etapa terminal por antigüedad).
  return const RoseStageEstimate(
    stageId: RoseStageIds.unknown,
    anchorTypeId: RoseAnchorTypeIds.unknown,
    confidence: RoseStageConfidence.unknown,
  );
}

/// Normaliza un id de etapa del rosal (acepta alias legacy). Desconocido →
/// `unknown`.
String normalizeRoseStageId(String? stageId) {
  final value = stageId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return RoseStageIds.unknown;
  if (RoseStageIds.all.contains(value)) return value;
  switch (value) {
    case 'planned':
    case 'installation':
    case 'recien_plantado':
    case 'repot':
    case 'transplant':
      return RoseStageIds.installationEstablishment;
    case 'rooting':
    case 'establishing':
    case 'root':
      return RoseStageIds.rootEstablishment;
    case 'sprouting':
    case 'flush':
    case 'brotando':
    case 'vegetative':
    case 'vegetative_growth':
    case 'growing':
    case 'active':
    case 'active_growth':
      return RoseStageIds.vegetativeFlush;
    case 'bud':
    case 'buds':
    case 'budding':
    case 'boton':
    case 'botones':
      return RoseStageIds.budFormation;
    case 'bloom':
    case 'blooming':
    case 'floracion':
    case 'floración':
    case 'en_floracion':
      return RoseStageIds.flowering;
    case 'post_bloom':
    case 'postbloom':
    case 'recovery':
    case 'deadheading':
    case 'despues_de_floracion':
      return RoseStageIds.postBloomRecovery;
    case 'dormant':
    case 'dormancy':
    case 'resting':
    case 'reposo':
      return RoseStageIds.rest;
  }
  return RoseStageIds.unknown;
}

String normalizeRoseAnchorTypeId(String? anchorTypeId) {
  final value = anchorTypeId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return RoseAnchorTypeIds.unknown;
  switch (value) {
    case RoseAnchorTypeIds.installation:
    case RoseAnchorTypeIds.stageStart:
    case RoseAnchorTypeIds.manualStage:
    case RoseAnchorTypeIds.unknown:
      return value;
  }
  return RoseAnchorTypeIds.unknown;
}

/// Nombre de la etapa, en lenguaje de agricultor. Sin jerga interna.
String roseStageDisplayName(String? stageId) {
  final id = normalizeRoseStageId(stageId);
  return switch (id) {
    RoseStageIds.installationEstablishment => 'Recién plantado',
    RoseStageIds.rootEstablishment => 'Echando raíz',
    RoseStageIds.vegetativeFlush => 'Brotando',
    RoseStageIds.budFormation => 'Formando botones',
    RoseStageIds.flowering => 'En floración',
    RoseStageIds.postBloomRecovery => 'Después de floración',
    RoseStageIds.rest => 'En reposo',
    _ => 'Etapa por confirmar',
  };
}

/// Ventana crítica de la etapa.
String? roseCriticalWindowLabel(String? stageId) {
  final id = normalizeRoseStageId(stageId);
  return switch (id) {
    RoseStageIds.installationEstablishment =>
      'Ventana crítica: recién plantado',
    RoseStageIds.rootEstablishment => 'Ventana crítica: echando raíz',
    RoseStageIds.budFormation => 'Ventana importante: formando botones',
    RoseStageIds.flowering => 'Ventana importante: floración',
    RoseStageIds.rest => 'Ventana importante: reposo',
    _ => null,
  };
}

/// Prioridad de cuidado por etapa, en lenguaje de agricultor (Doc B §4).
String roseStagePriorityText(String? stageId) {
  final id = normalizeRoseStageId(stageId);
  return switch (id) {
    RoseStageIds.installationEstablishment =>
      'Recién plantado: riega con medida y que el sustrato drene bien',
    RoseStageIds.rootEstablishment =>
      'Echando raíz: deja secar entre riegos mientras arraiga',
    RoseStageIds.vegetativeFlush =>
      'Brotando: el nitrógeno impulsa los brotes nuevos',
    RoseStageIds.budFormation =>
      'Formando botones: sube el potasio para una buena floración',
    RoseStageIds.flowering =>
      'En floración: el potasio es la clave; no fuerces el nitrógeno',
    RoseStageIds.postBloomRecovery =>
      'Después de florecer: recupera con nitrógeno y potasio equilibrados',
    RoseStageIds.rest =>
      'En reposo: riega mucho menos y cuida el frío con humedad',
    _ => 'BIO-G interpreta tus sensores según el estado de la planta',
  };
}

/// Confianza (0..1) de una etapa del rosal ya persistida + su ancla.
double roseStageConfidence({
  required String? stageId,
  required DateTime? anchorDate,
  required String? anchorTypeId,
}) {
  final id = normalizeRoseStageId(stageId);
  if (id == RoseStageIds.unknown) return RoseStageConfidence.unknown;
  final anchorType = normalizeRoseAnchorTypeId(anchorTypeId);

  // Un estado recurrente confirmado visualmente es alta confianza: el usuario lo
  // vio. La fecha no lo altera.
  if (RoseStageIds.recurringStates.contains(id)) {
    if (anchorType == RoseAnchorTypeIds.manualStage) {
      return RoseStageConfidence.byManualState;
    }
    return anchorDate != null ? 0.70 : 0.65;
  }

  if (anchorType == RoseAnchorTypeIds.manualStage) {
    return RoseStageConfidence.byManualState;
  }
  if (anchorDate == null) {
    return switch (id) {
      RoseStageIds.installationEstablishment ||
      RoseStageIds.rootEstablishment => 0.40,
      _ => RoseStageConfidence.unknown,
    };
  }
  return switch (id) {
    RoseStageIds.installationEstablishment =>
      RoseStageConfidence.byRecentAnchor,
    RoseStageIds.rootEstablishment => RoseStageConfidence.byEstablishmentWindow,
    _ => 0.35,
  };
}

/// Transiciones permitidas del ciclo del rosal (Doc A §9.4). Es un LOOP abierto,
/// no una progresión hacia un fin.
const Map<String, Set<String>> roseAllowedStageTransitions =
    <String, Set<String>>{
      RoseStageIds.installationEstablishment: <String>{
        RoseStageIds.rootEstablishment,
      },
      RoseStageIds.rootEstablishment: <String>{RoseStageIds.vegetativeFlush},
      RoseStageIds.vegetativeFlush: <String>{
        RoseStageIds.budFormation,
        RoseStageIds.rest,
      },
      RoseStageIds.budFormation: <String>{
        RoseStageIds.flowering,
        RoseStageIds.vegetativeFlush,
        RoseStageIds.rest,
      },
      RoseStageIds.flowering: <String>{
        RoseStageIds.postBloomRecovery,
        RoseStageIds.rest,
      },
      RoseStageIds.postBloomRecovery: <String>{
        RoseStageIds.vegetativeFlush,
        RoseStageIds.rest,
      },
      RoseStageIds.rest: <String>{RoseStageIds.vegetativeFlush},
      RoseStageIds.unknown: RoseStageIds.all,
    };

bool isAllowedRoseStageTransition(String? from, String? to) {
  final source = normalizeRoseStageId(from);
  final target = normalizeRoseStageId(to);
  if (source == target) return true;
  return roseAllowedStageTransitions[source]?.contains(target) ?? false;
}

/// True cuando el cultivo es el Rosal (modo `recurring_bloom`). La categoría
/// ornamental por sí sola NO basta: así ninguna otra ornamental hereda por
/// accidente este modelo (Doc A §17.5).
bool isRoseCrop({
  String? cropId,
  String? cropCategoryId,
  CropCategory? category,
}) {
  final canonicalCropId = CropCatalog.canonicalCropKey(cropId);
  if (canonicalCropId == kRoseCropId) return true;

  if (category == CropCategory.ornamental) {
    return false;
  }

  final normalizedCategory = cropCategoryId?.trim().toLowerCase();
  if (normalizedCategory == kRoseOrnamentalCategoryId) {
    return CropCatalog.cropById(canonicalCropId)?.cropId == kRoseCropId;
  }
  return false;
}

bool isRoseContext(DeviceCropContext? context) {
  if (context == null) return false;
  return isRoseCrop(
    cropId: context.cropId,
    cropCategoryId: context.cropCategoryId,
  );
}

/// Id canónico del cultivo rosal y de la categoría ornamental (fuente de verdad
/// de ids, compartida con el catálogo).
const String kRoseCropId = 'crop_rose';
const String kRoseOrnamentalCategoryId = 'ornamental';
