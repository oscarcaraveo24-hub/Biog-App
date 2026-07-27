/// Capa COMPARTIDA de las ornamentales en modo `establishment_maintenance`
/// (cactus, suculenta, sábila, maguey, nopal y, más adelante, helecho /
/// palma).
///
/// Existe por una razón concreta que dejó escrita la guía de ornamentales:
/// `isEstablishmentMaintenanceCrop()` NO puede ser un alias de `isCactusCrop()`.
/// La infraestructura compartida (runtime, persistencia, wizards, pantallas)
/// pregunta por el MODO DE CICLO; cada planta conserva su biología (targets,
/// pesos, ventanas, textos, sanidad) en su propio módulo.
///
/// Regla: aquí NO vive agronomía. Solo despacho por cultivo.
///
/// Despacho por `cropId` canónico (no por un booleano de dos ramas): con la
/// cuarta ornamental (maguey) un `_isSucculent ? … : cactus` dejaría al maguey
/// cayendo en silencio a la rama del cactus. El enum `_OrnamentalKind` obliga a
/// resolver las cuatro ramas explícitamente.
library;

import 'package:bio_g/core/crops/aloe/aloe_assets.dart';
import 'package:bio_g/core/crops/aloe/aloe_catalog.dart';
import 'package:bio_g/core/crops/aloe/aloe_lifecycle.dart';
import 'package:bio_g/core/crops/aloe/aloe_stage_resolver.dart';
import 'package:bio_g/core/crops/aloe/aloe_universal_profile.dart';
import 'package:bio_g/core/crops/agave/agave_assets.dart';
import 'package:bio_g/core/crops/agave/agave_catalog.dart';
import 'package:bio_g/core/crops/agave/agave_lifecycle.dart';
import 'package:bio_g/core/crops/agave/agave_stage_resolver.dart';
import 'package:bio_g/core/crops/agave/agave_universal_profile.dart';
import 'package:bio_g/core/crops/cactus/cactus_assets.dart';
import 'package:bio_g/core/crops/cactus/cactus_catalog.dart';
import 'package:bio_g/core/crops/cactus/cactus_lifecycle.dart';
import 'package:bio_g/core/crops/cactus/cactus_stage_resolver.dart';
import 'package:bio_g/core/crops/cactus/cactus_universal_profile.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/nopal/nopal_assets.dart';
import 'package:bio_g/core/crops/nopal/nopal_catalog.dart';
import 'package:bio_g/core/crops/nopal/nopal_lifecycle.dart';
import 'package:bio_g/core/crops/nopal/nopal_stage_resolver.dart';
import 'package:bio_g/core/crops/nopal/nopal_universal_profile.dart';
import 'package:bio_g/core/crops/succulent/succulent_assets.dart';
import 'package:bio_g/core/crops/succulent/succulent_catalog.dart';
import 'package:bio_g/core/crops/succulent/succulent_lifecycle.dart';
import 'package:bio_g/core/crops/succulent/succulent_stage_resolver.dart';
import 'package:bio_g/core/crops/succulent/succulent_universal_profile.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Cultivos ornamentales que usan el runtime de establecimiento + mantenimiento.
const Set<String> kEstablishmentMaintenanceCropIds = <String>{
  kCropCactus,
  kCropSucculent,
  kCropAloe,
  kCropAgave,
  kCropNopal,
};

/// Id de la categoría ornamental (fuente de verdad compartida).
const String kOrnamentalCategoryIdShared = 'ornamental';

/// True cuando el cultivo debe usar el runtime ORNAMENTAL de establecimiento y
/// mantenimiento. La categoría ornamental por sí sola NO basta: una ornamental
/// futura de otro modo (rosal, tulipán…) nunca hereda este modelo por accidente.
bool isEstablishmentMaintenanceCrop({
  String? cropId,
  String? cropCategoryId,
  CropCategory? category,
}) {
  return isCactusCrop(
        cropId: cropId,
        cropCategoryId: cropCategoryId,
        category: category,
      ) ||
      isSucculentCrop(
        cropId: cropId,
        cropCategoryId: cropCategoryId,
        category: category,
      ) ||
      isAloeCrop(
        cropId: cropId,
        cropCategoryId: cropCategoryId,
        category: category,
      ) ||
      isAgaveCrop(
        cropId: cropId,
        cropCategoryId: cropCategoryId,
        category: category,
      ) ||
      isNopalCrop(
        cropId: cropId,
        cropCategoryId: cropCategoryId,
        category: category,
      );
}

bool isEstablishmentMaintenanceContext(DeviceCropContext? context) {
  if (context == null) return false;
  return isEstablishmentMaintenanceCrop(
    cropId: context.cropId,
    cropCategoryId: context.cropCategoryId,
  );
}

/// Id canónico del cultivo ornamental, o `null` si no es una ornamental de este
/// modo.
String? ornamentalCropIdOrNull(String? cropId) {
  final canonical = CropCatalog.canonicalCropKey(cropId);
  return kEstablishmentMaintenanceCropIds.contains(canonical)
      ? canonical
      : null;
}

/// Cultivo ornamental concreto detrás del `cropId`. El default es `cactus` para
/// conservar el comportamiento histórico de cualquier id ornamental no
/// reconocido (antes de la sábila el fallback binario ya caía en cactus).
enum _OrnamentalKind { cactus, succulent, aloe, agave, nopal }

_OrnamentalKind _kind(String? cropId) {
  final canonical = CropCatalog.canonicalCropKey(cropId);
  if (canonical == kCropSucculent) return _OrnamentalKind.succulent;
  if (canonical == kCropAloe) return _OrnamentalKind.aloe;
  if (canonical == kCropAgave) return _OrnamentalKind.agave;
  if (canonical == kCropNopal) return _OrnamentalKind.nopal;
  return _OrnamentalKind.cactus;
}

// ── Identidad ────────────────────────────────────────────────────────────────

String ornamentalLifecycleMode(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => SucculentLifecycle.lifecycleMode,
  _OrnamentalKind.aloe => AloeLifecycle.lifecycleMode,
  _OrnamentalKind.agave => AgaveLifecycle.lifecycleMode,
  _OrnamentalKind.nopal => NopalLifecycle.lifecycleMode,
  _OrnamentalKind.cactus => CactusLifecycle.lifecycleMode,
};

String ornamentalCropDisplayName(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => 'Suculenta',
  _OrnamentalKind.aloe => 'Sábila',
  _OrnamentalKind.agave => 'Maguey',
  _OrnamentalKind.nopal => 'Nopal',
  _OrnamentalKind.cactus => 'Cactus',
};

String ornamentalDefaultProfileId(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => kSuSkip,
  _OrnamentalKind.aloe => kSaSkip,
  _OrnamentalKind.agave => kAgaveSkip,
  _OrnamentalKind.nopal => kNopalSkip,
  _OrnamentalKind.cactus => kCaSkip,
};

String ornamentalGeneralProfileLabel(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => 'No sé / suculenta general',
  _OrnamentalKind.aloe => 'No sé / sábila general',
  _OrnamentalKind.agave => 'No sé / maguey general',
  _OrnamentalKind.nopal => 'No sé / nopal general',
  _OrnamentalKind.cactus => 'No sé / cactus general',
};

/// Etiqueta corta del perfil general para pantallas (sin "No sé /").
String ornamentalGeneralShortLabel(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => 'Suculenta general',
  _OrnamentalKind.aloe => 'Sábila general',
  _OrnamentalKind.agave => 'Maguey general',
  _OrnamentalKind.nopal => 'Nopal general',
  _OrnamentalKind.cactus => 'Cactus general',
};

// ── Etapas ───────────────────────────────────────────────────────────────────

String normalizeOrnamentalStageId(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _OrnamentalKind.succulent => normalizeSucculentStageId(stageId),
      _OrnamentalKind.aloe => normalizeAloeStageId(stageId),
      _OrnamentalKind.agave => normalizeAgaveStageId(stageId),
      _OrnamentalKind.nopal => normalizeNopalStageId(stageId),
      _OrnamentalKind.cactus => normalizeCactusStageId(stageId),
    };

String normalizeOrnamentalAnchorTypeId(String? cropId, String? anchorTypeId) =>
    switch (_kind(cropId)) {
      _OrnamentalKind.succulent => normalizeSucculentAnchorTypeId(anchorTypeId),
      _OrnamentalKind.aloe => normalizeAloeAnchorTypeId(anchorTypeId),
      _OrnamentalKind.agave => normalizeAgaveAnchorTypeId(anchorTypeId),
      _OrnamentalKind.nopal => normalizeNopalAnchorTypeId(anchorTypeId),
      _OrnamentalKind.cactus => normalizeCactusAnchorTypeId(anchorTypeId),
    };

String ornamentalStageDisplayName(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _OrnamentalKind.succulent => succulentStageDisplayName(stageId),
      _OrnamentalKind.aloe => aloeStageDisplayName(stageId),
      _OrnamentalKind.agave => agaveStageDisplayName(stageId),
      _OrnamentalKind.nopal => nopalStageDisplayName(stageId),
      _OrnamentalKind.cactus => cactusStageDisplayName(stageId),
    };

String? ornamentalCriticalWindowLabel(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _OrnamentalKind.succulent => succulentCriticalWindowLabel(stageId),
      _OrnamentalKind.aloe => aloeCriticalWindowLabel(stageId),
      _OrnamentalKind.agave => agaveCriticalWindowLabel(stageId),
      _OrnamentalKind.nopal => nopalCriticalWindowLabel(stageId),
      _OrnamentalKind.cactus => cactusCriticalWindowLabel(stageId),
    };

String ornamentalStagePriorityText(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _OrnamentalKind.succulent => succulentStagePriorityText(stageId),
      _OrnamentalKind.aloe => aloeStagePriorityText(stageId),
      _OrnamentalKind.agave => agaveStagePriorityText(stageId),
      _OrnamentalKind.nopal => nopalStagePriorityText(stageId),
      _OrnamentalKind.cactus => cactusStagePriorityText(stageId),
    };

String ornamentalStageCareNoteEs(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _OrnamentalKind.succulent => succulentStageCareNoteEs(stageId),
      _OrnamentalKind.aloe => aloeStageCareNoteEs(stageId),
      _OrnamentalKind.agave => agaveStageCareNoteEs(stageId),
      _OrnamentalKind.nopal => nopalStageCareNoteEs(stageId),
      _OrnamentalKind.cactus => cactusStageCareNoteEs(stageId),
    };

/// Etapa "por confirmar" del cultivo (misma clave en todos, resuelta por su
/// propio dominio).
String ornamentalUnknownStageId(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => SucculentStageIds.unknown,
  _OrnamentalKind.aloe => AloeStageIds.unknown,
  _OrnamentalKind.agave => AgaveStageIds.unknown,
  _OrnamentalKind.nopal => NopalStageIds.unknown,
  _OrnamentalKind.cactus => CactusStageIds.unknown,
};

/// Resuelve la etapa RUNTIME. Es la única fuente que deben leer las pantallas.
CropStageResult resolveOrnamentalStageResult({
  required DeviceCropContext context,
  DateTime? today,
}) {
  return switch (_kind(context.cropId)) {
    _OrnamentalKind.succulent => SucculentStageResolver.resolve(
      context: context,
      today: today,
    ),
    _OrnamentalKind.aloe => AloeStageResolver.resolve(
      context: context,
      today: today,
    ),
    _OrnamentalKind.agave => AgaveStageResolver.resolve(
      context: context,
      today: today,
    ),
    _OrnamentalKind.nopal => NopalStageResolver.resolve(
      context: context,
      today: today,
    ),
    _OrnamentalKind.cactus => CactusStageResolver.resolve(
      context: context,
      today: today,
    ),
  };
}

// ── Wizard: intenciones y estimación de etapa ────────────────────────────────

/// Estimación de etapa, común a todas las ornamentales de este modo.
class OrnamentalStageEstimate {
  const OrnamentalStageEstimate({
    required this.stageId,
    required this.anchorTypeId,
    required this.confidence,
  });

  final String stageId;
  final String anchorTypeId;
  final double confidence;
}

/// Las dos intenciones del wizard: plantar / ya plantada. No hay más.
const Set<String> kOrnamentalSetupIntentIds = <String>{
  'planned_plant',
  'already_planted',
};

const String kOrnamentalIntentPlannedPlant = 'planned_plant';
const String kOrnamentalIntentAlreadyPlanted = 'already_planted';

String normalizeOrnamentalSetupIntentId(String? cropId, String? intentId) =>
    switch (_kind(cropId)) {
      _OrnamentalKind.succulent => normalizeSucculentSetupIntentId(intentId),
      _OrnamentalKind.aloe => normalizeAloeSetupIntentId(intentId),
      _OrnamentalKind.agave => normalizeAgaveSetupIntentId(intentId),
      _OrnamentalKind.nopal => normalizeNopalSetupIntentId(intentId),
      _OrnamentalKind.cactus => normalizeCactusSetupIntentId(intentId),
    };

bool ornamentalSetupIntentRequiresFutureDate(
  String? cropId,
  String? intentId,
) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => succulentSetupIntentRequiresFutureDate(intentId),
  _OrnamentalKind.aloe => aloeSetupIntentRequiresFutureDate(intentId),
  _OrnamentalKind.agave => agaveSetupIntentRequiresFutureDate(intentId),
  _OrnamentalKind.nopal => nopalSetupIntentRequiresFutureDate(intentId),
  _OrnamentalKind.cactus => cactusSetupIntentRequiresFutureDate(intentId),
};

OrnamentalStageEstimate estimateOrnamentalStageFromDate({
  required String? cropId,
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
}) {
  switch (_kind(cropId)) {
    case _OrnamentalKind.succulent:
      final e = estimateSucculentStageFromDate(
        plantingDate: plantingDate,
        now: now,
        profileId: profileId,
      );
      return OrnamentalStageEstimate(
        stageId: e.stageId,
        anchorTypeId: e.anchorTypeId,
        confidence: e.confidence,
      );
    case _OrnamentalKind.aloe:
      final e = estimateAloeStageFromDate(
        plantingDate: plantingDate,
        now: now,
        profileId: profileId,
      );
      return OrnamentalStageEstimate(
        stageId: e.stageId,
        anchorTypeId: e.anchorTypeId,
        confidence: e.confidence,
      );
    case _OrnamentalKind.agave:
      final e = estimateAgaveStageFromDate(
        plantingDate: plantingDate,
        now: now,
        profileId: profileId,
      );
      return OrnamentalStageEstimate(
        stageId: e.stageId,
        anchorTypeId: e.anchorTypeId,
        confidence: e.confidence,
      );
    case _OrnamentalKind.nopal:
      final e = estimateNopalStageFromDate(
        plantingDate: plantingDate,
        now: now,
        profileId: profileId,
      );
      return OrnamentalStageEstimate(
        stageId: e.stageId,
        anchorTypeId: e.anchorTypeId,
        confidence: e.confidence,
      );
    case _OrnamentalKind.cactus:
      final e = estimateCactusStageFromDate(
        plantingDate: plantingDate,
        now: now,
        profileId: profileId,
      );
      return OrnamentalStageEstimate(
        stageId: e.stageId,
        anchorTypeId: e.anchorTypeId,
        confidence: e.confidence,
      );
  }
}

/// FUENTE ÚNICA de la etapa que resulta del wizard (onboarding y cuenta).
/// Si duplicas esta lógica en una pantalla, se desincroniza. No lo hagas.
OrnamentalStageEstimate resolveOrnamentalSetupStage({
  required String? cropId,
  required String? intentId,
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
  String? previousStageId,
}) {
  switch (_kind(cropId)) {
    case _OrnamentalKind.succulent:
      final e = resolveSucculentSetupStage(
        intentId: intentId,
        plantingDate: plantingDate,
        now: now,
        profileId: profileId,
        previousStageId: previousStageId,
      );
      return OrnamentalStageEstimate(
        stageId: e.stageId,
        anchorTypeId: e.anchorTypeId,
        confidence: e.confidence,
      );
    case _OrnamentalKind.aloe:
      final e = resolveAloeSetupStage(
        intentId: intentId,
        plantingDate: plantingDate,
        now: now,
        profileId: profileId,
        previousStageId: previousStageId,
      );
      return OrnamentalStageEstimate(
        stageId: e.stageId,
        anchorTypeId: e.anchorTypeId,
        confidence: e.confidence,
      );
    case _OrnamentalKind.agave:
      final e = resolveAgaveSetupStage(
        intentId: intentId,
        plantingDate: plantingDate,
        now: now,
        profileId: profileId,
        previousStageId: previousStageId,
      );
      return OrnamentalStageEstimate(
        stageId: e.stageId,
        anchorTypeId: e.anchorTypeId,
        confidence: e.confidence,
      );
    case _OrnamentalKind.nopal:
      final e = resolveNopalSetupStage(
        intentId: intentId,
        plantingDate: plantingDate,
        now: now,
        profileId: profileId,
        previousStageId: previousStageId,
      );
      return OrnamentalStageEstimate(
        stageId: e.stageId,
        anchorTypeId: e.anchorTypeId,
        confidence: e.confidence,
      );
    case _OrnamentalKind.cactus:
      final e = resolveCactusSetupStage(
        intentId: intentId,
        plantingDate: plantingDate,
        now: now,
        profileId: profileId,
        previousStageId: previousStageId,
      );
      return OrnamentalStageEstimate(
        stageId: e.stageId,
        anchorTypeId: e.anchorTypeId,
        confidence: e.confidence,
      );
  }
}

// ── Assets ───────────────────────────────────────────────────────────────────

String ornamentalCropIcon(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => SucculentAssets.cropIcon,
  _OrnamentalKind.aloe => AloeAssets.cropIcon,
  _OrnamentalKind.agave => AgaveAssets.cropIcon,
  _OrnamentalKind.nopal => NopalAssets.cropIcon,
  _OrnamentalKind.cactus => CactusAssets.cropIcon,
};

String ornamentalProfileIcon(String? cropId, String? profileId) =>
    switch (_kind(cropId)) {
      _OrnamentalKind.succulent => SucculentAssets.profileIcon(profileId),
      _OrnamentalKind.aloe => AloeAssets.profileIcon(profileId),
      _OrnamentalKind.agave => AgaveAssets.profileIcon(profileId),
      _OrnamentalKind.nopal => NopalAssets.profileIcon(profileId),
      _OrnamentalKind.cactus => CactusAssets.profileIcon(profileId),
    };

String ornamentalStageImage(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _OrnamentalKind.succulent => SucculentAssets.stageImageOrNeutral(stageId),
      _OrnamentalKind.aloe => AloeAssets.stageImageOrNeutral(stageId),
      _OrnamentalKind.agave => AgaveAssets.stageImageOrNeutral(stageId),
      _OrnamentalKind.nopal => NopalAssets.stageImageOrNeutral(stageId),
      _OrnamentalKind.cactus => CactusAssets.stageImageOrNeutral(stageId),
    };

String ornamentalStageUnknownImage(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => SucculentAssets.stageUnknown,
  _OrnamentalKind.aloe => AloeAssets.stageUnknown,
  _OrnamentalKind.agave => AgaveAssets.stageUnknown,
  _OrnamentalKind.nopal => NopalAssets.stageUnknown,
  _OrnamentalKind.cactus => CactusAssets.stageUnknown,
};

/// Fallback compartido de las ornamentales (planta genérica del wizard).
const String kOrnamentalGenericPlantFallback =
    'assets/icons/wizard/ic_planta_generica.png';

// ── Textos de wizard (lenguaje de agricultor, con el género correcto) ────────

String ornamentalTypeQuestion(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => '¿Qué tipo de suculenta es?',
  _OrnamentalKind.aloe => '¿Qué tipo de sábila es?',
  _OrnamentalKind.agave => '¿Qué tipo de maguey es?',
  _OrnamentalKind.nopal => '¿Qué tipo de nopal es?',
  _OrnamentalKind.cactus => '¿Qué tipo de cactus es?',
};

String ornamentalGeneralProfileHint(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => 'Recomendado si no sabes el tipo de suculenta',
  _OrnamentalKind.aloe => 'Recomendado si no sabes el tipo de sábila',
  _OrnamentalKind.agave => 'Recomendado si no sabes el tipo de maguey',
  _OrnamentalKind.nopal => 'Recomendado si no sabes el tipo de nopal',
  _OrnamentalKind.cactus => 'Recomendado si no sabes el tipo de cactus',
};

String ornamentalStateQuestion(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => '¿En qué estado está tu suculenta?',
  _OrnamentalKind.aloe => '¿En qué estado está tu sábila?',
  _OrnamentalKind.agave => '¿En qué estado está tu maguey?',
  _OrnamentalKind.nopal => '¿En qué estado está tu nopal?',
  _OrnamentalKind.cactus => '¿En qué estado está tu cactus?',
};

String ornamentalPlannedOptionTitle(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => 'La voy a plantar',
  _OrnamentalKind.aloe => 'La voy a plantar',
  _OrnamentalKind.agave => 'Lo voy a plantar',
  _OrnamentalKind.nopal => 'Lo voy a plantar',
  _OrnamentalKind.cactus => 'Lo voy a plantar',
};

String ornamentalPlantedOptionTitle(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent => 'Ya está plantada',
  _OrnamentalKind.aloe => 'Ya está plantada',
  _OrnamentalKind.agave => 'Ya está plantado',
  _OrnamentalKind.nopal => 'Ya está plantado',
  _OrnamentalKind.cactus => 'Ya está plantado',
};

String ornamentalVarietyFlowSubtitle(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent =>
    'Selecciona Suculenta y el perfil que mejor lo describe.',
  _OrnamentalKind.aloe =>
    'Selecciona Sábila y el perfil que mejor la describe.',
  _OrnamentalKind.agave =>
    'Selecciona Maguey y el perfil que mejor lo describe.',
  _OrnamentalKind.nopal =>
    'Selecciona Nopal y el perfil que mejor lo describe.',
  _OrnamentalKind.cactus =>
    'Selecciona Cactus y el perfil que mejor lo describe.',
};

String ornamentalVarietyFlowHelper(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent =>
    'Si no sabes el tipo, elige No sé / suculenta general.',
  _OrnamentalKind.aloe => 'Si no sabes el tipo, elige No sé / sábila general.',
  _OrnamentalKind.agave => 'Si no sabes el tipo, elige No sé / maguey general.',
  _OrnamentalKind.nopal =>
    'Si no sabes el tipo, elige No sé / nopal general.',
  _OrnamentalKind.cactus =>
    'Si no sabes el tipo, elige No sé / cactus general.',
};

String ornamentalDateQuestionTitle(String? cropId, String? intentId) {
  final planned =
      normalizeOrnamentalSetupIntentId(cropId, intentId) ==
      kOrnamentalIntentPlannedPlant;
  switch (_kind(cropId)) {
    case _OrnamentalKind.succulent:
    case _OrnamentalKind.aloe:
      return planned
          ? '¿Cuándo piensas plantarla?'
          : '¿Recuerdas cuándo\nla plantaste?';
    case _OrnamentalKind.agave:
    case _OrnamentalKind.nopal:
    case _OrnamentalKind.cactus:
      return planned
          ? '¿Cuándo piensas plantarlo?'
          : '¿Recuerdas cuándo\nlo plantaste?';
  }
}

String ornamentalDateFlexibleLabel(String? cropId, String? intentId) {
  return ornamentalSetupIntentRequiresFutureDate(cropId, intentId)
      ? 'No tengo fecha aún'
      : 'No lo recuerdo';
}

String ornamentalDateFlexibleDescription(String? cropId, String? intentId) {
  return ornamentalSetupIntentRequiresFutureDate(cropId, intentId)
      ? 'La plantación quedará pendiente y podrás agregar la fecha después.'
      : 'Sin fecha tomamos la planta como estable. Puedes ajustarlo después.';
}

String ornamentalDateHelperText(String? cropId, String? intentId) {
  return ornamentalSetupIntentRequiresFutureDate(cropId, intentId)
      ? 'La fecha nos dice cuándo la vas a plantar.'
      : 'Con la fecha sabemos si apenas está agarrando raíz o ya está estable.';
}

/// Subtítulo de la tarjeta de riego en el dashboard.
String ornamentalIrrigationSubtitle(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent =>
    'El exceso de agua es el mayor riesgo de una suculenta',
  _OrnamentalKind.aloe => 'El exceso de agua es el mayor riesgo de una sábila',
  _OrnamentalKind.agave => 'El exceso de agua es el mayor riesgo de un maguey',
  _OrnamentalKind.nopal =>
    'El exceso de agua es el mayor riesgo del nopal',
  _OrnamentalKind.cactus => 'El exceso de agua es el mayor riesgo del cactus',
};

/// Texto de ayuda de la tarjeta de estado cuando la etapa está por confirmar.
String ornamentalUnknownStageHelper(String? cropId) => switch (_kind(cropId)) {
  _OrnamentalKind.succulent =>
    'Puedes ajustar el tipo de suculenta y su etapa cuando quieras.',
  _OrnamentalKind.aloe =>
    'Puedes ajustar el tipo de sábila y su etapa cuando quieras.',
  _OrnamentalKind.agave =>
    'Puedes ajustar el tipo de maguey y su etapa cuando quieras.',
  _OrnamentalKind.nopal =>
    'Puedes ajustar el tipo de nopal y su etapa cuando quieras.',
  _OrnamentalKind.cactus =>
    'Puedes ajustar el tipo de cactus y su etapa cuando quieras.',
};
