/// Capa COMPARTIDA de las ornamentales en modo `recurring_bloom` (Rosal hoy;
/// más adelante Tulipán y otras de floración recurrente o estacional).
///
/// Existe por la misma razón que `ornamental_crops.dart`:
/// `isRecurringBloomCrop()` NO puede ser un alias de `isRoseCrop()`. La
/// infraestructura compartida (runtime, persistencia, wizards, pantallas)
/// pregunta por el MODO DE CICLO; cada planta conserva su biología (targets,
/// pesos, ventanas, textos, sanidad) en su propio módulo.
///
/// Diferencia con el modo `establishment_maintenance`: tras el establecimiento,
/// la etapa NO se infiere por fecha. Entra un ciclo recurrente cuyo estado
/// (brotando / botones / floración / post-floración / reposo) el usuario confirma
/// de forma VISUAL. Este archivo expone justo eso de forma reutilizable:
/// `recurringBloomVisualStateOptions(cropId)` alimenta el wizard visual sin
/// codificar el rosal a mano, para que Tulipán se sume declarando su propio
/// módulo + una rama en `_RecurringBloomKind`.
///
/// Regla: aquí NO vive agronomía. Solo despacho por cultivo.
library;

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/rose/rose_assets.dart';
import 'package:bio_g/core/crops/rose/rose_catalog.dart';
import 'package:bio_g/core/crops/rose/rose_lifecycle.dart';
import 'package:bio_g/core/crops/rose/rose_stage_resolver.dart';
import 'package:bio_g/core/crops/rose/rose_universal_profile.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Id del modo de ciclo compartido.
const String kRecurringBloomLifecycleModeId = 'recurring_bloom';

/// Cultivos que usan el runtime de floración recurrente.
const Set<String> kRecurringBloomCropIds = <String>{
  kCropRose,
};

/// Id de la categoría ornamental (fuente de verdad compartida).
const String kRecurringBloomCategoryIdShared = 'ornamental';

/// True cuando el cultivo debe usar el runtime de FLORACIÓN RECURRENTE. La
/// categoría ornamental por sí sola NO basta: una ornamental de establecimiento
/// (cactus/suculenta/sábila/maguey) nunca hereda este modelo por accidente.
bool isRecurringBloomCrop({
  String? cropId,
  String? cropCategoryId,
  CropCategory? category,
}) {
  return isRoseCrop(
    cropId: cropId,
    cropCategoryId: cropCategoryId,
    category: category,
  );
}

bool isRecurringBloomContext(DeviceCropContext? context) {
  if (context == null) return false;
  return isRecurringBloomCrop(
    cropId: context.cropId,
    cropCategoryId: context.cropCategoryId,
  );
}

/// Id canónico del cultivo de floración recurrente, o `null` si no lo es.
String? recurringBloomCropIdOrNull(String? cropId) {
  final canonical = CropCatalog.canonicalCropKey(cropId);
  return kRecurringBloomCropIds.contains(canonical) ? canonical : null;
}

/// Cultivo concreto detrás del `cropId`. El default es `rose` (único miembro en
/// v1); el enum obliga a resolver cada rama explícitamente al sumar Tulipán.
enum _RecurringBloomKind { rose }

_RecurringBloomKind _kind(String? cropId) {
  // Único cultivo del modo en v1. Cuando entre Tulipán, añade su rama aquí.
  return _RecurringBloomKind.rose;
}

// ── Identidad ────────────────────────────────────────────────────────────────

String recurringBloomLifecycleMode(String? cropId) => switch (_kind(cropId)) {
  _RecurringBloomKind.rose => RoseLifecycle.lifecycleMode,
};

String recurringBloomCropDisplayName(String? cropId) => switch (_kind(cropId)) {
  _RecurringBloomKind.rose => 'Rosal',
};

String recurringBloomDefaultProfileId(String? cropId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => kRoSkip,
    };

String recurringBloomGeneralProfileLabel(String? cropId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => 'No sé / rosal general',
    };

String recurringBloomGeneralShortLabel(String? cropId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => 'Rosal general',
    };

// ── Etapas ───────────────────────────────────────────────────────────────────

String normalizeRecurringBloomStageId(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => normalizeRoseStageId(stageId),
    };

String normalizeRecurringBloomAnchorTypeId(
  String? cropId,
  String? anchorTypeId,
) => switch (_kind(cropId)) {
  _RecurringBloomKind.rose => normalizeRoseAnchorTypeId(anchorTypeId),
};

String recurringBloomStageDisplayName(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => roseStageDisplayName(stageId),
    };

String? recurringBloomCriticalWindowLabel(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => roseCriticalWindowLabel(stageId),
    };

String recurringBloomStagePriorityText(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => roseStagePriorityText(stageId),
    };

String recurringBloomStageCareNoteEs(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => roseStageCareNoteEs(stageId),
    };

String recurringBloomUnknownStageId(String? cropId) => switch (_kind(cropId)) {
  _RecurringBloomKind.rose => RoseStageIds.unknown,
};

/// Resuelve la etapa RUNTIME. Es la única fuente que deben leer las pantallas.
CropStageResult resolveRecurringBloomStageResult({
  required DeviceCropContext context,
  DateTime? today,
}) {
  return switch (_kind(context.cropId)) {
    _RecurringBloomKind.rose => RoseStageResolver.resolve(
      context: context,
      today: today,
    ),
  };
}

// ── Wizard: intenciones y estimación de etapa ────────────────────────────────

/// Estimación de etapa, común a las ornamentales de floración recurrente.
class RecurringBloomStageEstimate {
  const RecurringBloomStageEstimate({
    required this.stageId,
    required this.anchorTypeId,
    required this.confidence,
  });

  final String stageId;
  final String anchorTypeId;
  final double confidence;
}

const String kRecurringBloomIntentPlannedPlant = 'planned_plant';
const String kRecurringBloomIntentAlreadyPlanted = 'already_planted';

const Set<String> kRecurringBloomSetupIntentIds = <String>{
  kRecurringBloomIntentPlannedPlant,
  kRecurringBloomIntentAlreadyPlanted,
};

String normalizeRecurringBloomSetupIntentId(String? cropId, String? intentId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => normalizeRoseSetupIntentId(intentId),
    };

bool recurringBloomSetupIntentRequiresFutureDate(
  String? cropId,
  String? intentId,
) => switch (_kind(cropId)) {
  _RecurringBloomKind.rose => roseSetupIntentRequiresFutureDate(intentId),
};

RecurringBloomStageEstimate estimateRecurringBloomStageFromDate({
  required String? cropId,
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
}) {
  switch (_kind(cropId)) {
    case _RecurringBloomKind.rose:
      final e = estimateRoseStageFromDate(
        plantingDate: plantingDate,
        now: now,
        profileId: profileId,
      );
      return RecurringBloomStageEstimate(
        stageId: e.stageId,
        anchorTypeId: e.anchorTypeId,
        confidence: e.confidence,
      );
  }
}

/// FUENTE ÚNICA de la etapa que resulta del wizard (onboarding y cuenta).
RecurringBloomStageEstimate resolveRecurringBloomSetupStage({
  required String? cropId,
  required String? intentId,
  required DateTime? plantingDate,
  required DateTime now,
  String? profileId,
  String? previousStageId,
}) {
  switch (_kind(cropId)) {
    case _RecurringBloomKind.rose:
      final e = resolveRoseSetupStage(
        intentId: intentId,
        plantingDate: plantingDate,
        now: now,
        profileId: profileId,
        previousStageId: previousStageId,
      );
      return RecurringBloomStageEstimate(
        stageId: e.stageId,
        anchorTypeId: e.anchorTypeId,
        confidence: e.confidence,
      );
  }
}

// ── Wizard visual de estado actual (config-driven, reutilizable) ─────────────

/// Una opción del wizard visual "¿Cómo está tu <planta> ahora?".
///
/// Reúne todo lo que el wizard necesita para pintar la tarjeta y persistir la
/// elección, sin que el wizard conozca al rosal en concreto. Al sumar Tulipán,
/// solo hay que devolver su propia lista desde [recurringBloomVisualStateOptions].
class RecurringBloomStateOption {
  const RecurringBloomStateOption({
    required this.id,
    required this.stageId,
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.intentId,
    required this.anchorTypeId,
    required this.requiresFutureDate,
    required this.usesDateEstimation,
    required this.stageConfidence,
  });

  /// Id de la opción (único dentro de la lista).
  final String id;

  /// Id de etapa canónico a persistir. Cuando [usesDateEstimation] es true, se
  /// ignora y el resolver estima el establecimiento por fecha.
  final String stageId;

  final String title;
  final String subtitle;
  final String iconPath;

  /// Intención de alta resultante (`planned_plant` | `already_planted`).
  final String intentId;

  final String anchorTypeId;

  /// La opción pide una fecha futura (solo "lo voy a plantar").
  final bool requiresFutureDate;

  /// La etapa se deriva de la fecha (establecimiento), no del estado elegido.
  final bool usesDateEstimation;

  /// Confianza a persistir cuando el estado es confirmado visualmente.
  final double stageConfidence;
}

/// Pregunta encabezado del wizard visual de estado.
String recurringBloomStateQuestion(String? cropId) => switch (_kind(cropId)) {
  _RecurringBloomKind.rose => '¿Cómo está tu rosal ahora?',
};

/// Ayuda bajo la pregunta de estado visual.
String recurringBloomStateHelper(String? cropId) => switch (_kind(cropId)) {
  _RecurringBloomKind.rose =>
    'Elige lo que ves hoy. Después de establecerse, el rosal no sigue un '
        'calendario fijo: cambia de estado según brota y florece.',
};

/// Opciones del wizard visual, en orden de presentación. Config-driven: el
/// wizard solo pinta esta lista y persiste lo que trae cada opción.
List<RecurringBloomStateOption> recurringBloomVisualStateOptions(
  String? cropId,
) {
  switch (_kind(cropId)) {
    case _RecurringBloomKind.rose:
      return const <RecurringBloomStateOption>[
        RecurringBloomStateOption(
          id: 'planned',
          stageId: RoseStageIds.installationEstablishment,
          title: 'Lo voy a plantar',
          subtitle: 'Todavía no está en la tierra.',
          iconPath: RoseAssets.cropIcon,
          intentId: kRecurringBloomIntentPlannedPlant,
          anchorTypeId: RoseAnchorTypeIds.installation,
          requiresFutureDate: true,
          usesDateEstimation: true,
          stageConfidence: 0.45,
        ),
        RecurringBloomStateOption(
          id: 'recently_planted',
          stageId: RoseStageIds.rootEstablishment,
          title: 'Recién lo planté',
          subtitle: 'Apenas está agarrando raíz.',
          iconPath: RoseAssets.stageRootEstablishment,
          intentId: kRecurringBloomIntentAlreadyPlanted,
          anchorTypeId: RoseAnchorTypeIds.installation,
          requiresFutureDate: false,
          usesDateEstimation: true,
          stageConfidence: 0.40,
        ),
        RecurringBloomStateOption(
          id: RoseStageIds.vegetativeFlush,
          stageId: RoseStageIds.vegetativeFlush,
          title: 'Está sacando brotes',
          subtitle: 'Brotes tiernos y hojas nuevas, sin botones aún.',
          iconPath: RoseAssets.stateVegetativeFlush,
          intentId: kRecurringBloomIntentAlreadyPlanted,
          anchorTypeId: RoseAnchorTypeIds.manualStage,
          requiresFutureDate: false,
          usesDateEstimation: false,
          stageConfidence: 0.80,
        ),
        RecurringBloomStateOption(
          id: RoseStageIds.budFormation,
          stageId: RoseStageIds.budFormation,
          title: 'Tiene botones cerrados',
          subtitle: 'Botones visibles, la mayoría sin abrir.',
          iconPath: RoseAssets.stateBudFormation,
          intentId: kRecurringBloomIntentAlreadyPlanted,
          anchorTypeId: RoseAnchorTypeIds.manualStage,
          requiresFutureDate: false,
          usesDateEstimation: false,
          stageConfidence: 0.80,
        ),
        RecurringBloomStateOption(
          id: RoseStageIds.flowering,
          stageId: RoseStageIds.flowering,
          title: 'Tiene flores abiertas',
          subtitle: 'Una o más flores abiertas: está en floración.',
          iconPath: RoseAssets.stateFlowering,
          intentId: kRecurringBloomIntentAlreadyPlanted,
          anchorTypeId: RoseAnchorTypeIds.manualStage,
          requiresFutureDate: false,
          usesDateEstimation: false,
          stageConfidence: 0.80,
        ),
        RecurringBloomStateOption(
          id: RoseStageIds.postBloomRecovery,
          stageId: RoseStageIds.postBloomRecovery,
          title: 'Terminó de florecer',
          subtitle: 'Flores agotadas o recién podadas, preparando el rebrote.',
          iconPath: RoseAssets.statePostBloomRecovery,
          intentId: kRecurringBloomIntentAlreadyPlanted,
          anchorTypeId: RoseAnchorTypeIds.manualStage,
          requiresFutureDate: false,
          usesDateEstimation: false,
          stageConfidence: 0.80,
        ),
        RecurringBloomStateOption(
          id: RoseStageIds.rest,
          stageId: RoseStageIds.rest,
          title: 'Está en reposo',
          subtitle: 'Sin brotes nuevos, detenido por la temporada.',
          iconPath: RoseAssets.stateRest,
          intentId: kRecurringBloomIntentAlreadyPlanted,
          anchorTypeId: RoseAnchorTypeIds.manualStage,
          requiresFutureDate: false,
          usesDateEstimation: false,
          stageConfidence: 0.80,
        ),
        RecurringBloomStateOption(
          id: 'unsure',
          stageId: RoseStageIds.unknown,
          title: 'No estoy seguro',
          subtitle: 'BIO-G lo tomará como estado por confirmar.',
          iconPath: RoseAssets.profileUnknown,
          intentId: kRecurringBloomIntentAlreadyPlanted,
          anchorTypeId: RoseAnchorTypeIds.unknown,
          requiresFutureDate: false,
          usesDateEstimation: false,
          stageConfidence: 0.25,
        ),
      ];
  }
}

// ── Assets ───────────────────────────────────────────────────────────────────

String recurringBloomCropIcon(String? cropId) => switch (_kind(cropId)) {
  _RecurringBloomKind.rose => RoseAssets.cropIcon,
};

String recurringBloomProfileIcon(String? cropId, String? profileId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => RoseAssets.profileIcon(profileId),
    };

String recurringBloomStageImage(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => RoseAssets.stageImageOrNeutral(stageId),
    };

String recurringBloomStateIcon(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => RoseAssets.stateIconForStage(stageId),
    };

String recurringBloomStageUnknownImage(String? cropId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => RoseAssets.stageUnknown,
    };

/// Fallback compartido (planta genérica del wizard).
const String kRecurringBloomGenericPlantFallback =
    'assets/icons/wizard/ic_planta_generica.png';

// ── Textos de wizard (lenguaje de agricultor, con el género correcto) ────────

String recurringBloomTypeQuestion(String? cropId) => switch (_kind(cropId)) {
  _RecurringBloomKind.rose => '¿Qué tipo de rosal es?',
};

String recurringBloomGeneralProfileHint(String? cropId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => 'Recomendado si no sabes el tipo de rosal',
    };

String recurringBloomPlannedOptionTitle(String? cropId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => 'Lo voy a plantar',
    };

String recurringBloomPlantedOptionTitle(String? cropId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose => 'Ya está plantado',
    };

String recurringBloomVarietyFlowSubtitle(String? cropId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose =>
        'Selecciona Rosal y el perfil que mejor lo describe.',
    };

String recurringBloomVarietyFlowHelper(String? cropId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose =>
        'Si no sabes el tipo, elige No sé / rosal general.',
    };

String recurringBloomDateQuestionTitle(String? cropId, String? intentId) {
  final planned =
      normalizeRecurringBloomSetupIntentId(cropId, intentId) ==
      kRecurringBloomIntentPlannedPlant;
  switch (_kind(cropId)) {
    case _RecurringBloomKind.rose:
      return planned
          ? '¿Cuándo piensas plantarlo?'
          : '¿Recuerdas cuándo\nlo plantaste?';
  }
}

String recurringBloomDateFlexibleLabel(String? cropId, String? intentId) {
  return recurringBloomSetupIntentRequiresFutureDate(cropId, intentId)
      ? 'No tengo fecha aún'
      : 'No lo recuerdo';
}

String recurringBloomDateFlexibleDescription(String? cropId, String? intentId) {
  return recurringBloomSetupIntentRequiresFutureDate(cropId, intentId)
      ? 'La plantación quedará pendiente y podrás agregar la fecha después.'
      : 'Sin fecha usamos el estado que elegiste. Puedes ajustarlo después.';
}

String recurringBloomDateHelperText(String? cropId, String? intentId) {
  return recurringBloomSetupIntentRequiresFutureDate(cropId, intentId)
      ? 'La fecha nos dice cuándo lo vas a plantar.'
      : 'Con la fecha contamos los días desde que lo plantaste.';
}

/// Subtítulo de la tarjeta de riego en el dashboard.
String recurringBloomIrrigationSubtitle(String? cropId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose =>
        'El rosal pide agua constante, pero el exceso favorece hongos',
    };

/// Texto de ayuda cuando la etapa está por confirmar.
String recurringBloomUnknownStageHelper(String? cropId) =>
    switch (_kind(cropId)) {
      _RecurringBloomKind.rose =>
        'Dinos cómo se ve tu rosal hoy para afinar el seguimiento.',
    };
