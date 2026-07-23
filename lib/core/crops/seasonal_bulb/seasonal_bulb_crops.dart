/// Capa COMPARTIDA de las ornamentales bulbosas en modo `seasonal_bulb`
/// (Tulipán hoy; más adelante otras geófitas de temporada anual).
///
/// Existe por la misma razón que `ornamental_crops.dart` y
/// `recurring_bloom_crops.dart`: `isSeasonalBulbCrop()` NO puede ser un alias
/// de `isTulipCrop()`. La infraestructura compartida (runtime, persistencia,
/// wizards, pantallas) pregunta por el MODO DE CICLO; cada planta conserva su
/// biología (targets, pesos, ventanas, textos, sanidad) en su propio módulo.
///
/// Diferencia con `establishment_maintenance` (cactus/suculenta/sábila/maguey)
/// y con `recurring_bloom` (rosal): el `seasonal_bulb` usa un RELOJ ANUAL tipo
/// granos. La etapa SÍ se resuelve por fecha ancla + días transcurridos, igual
/// que Frijol/Maíz/Avena. Por eso el Tulipán CONSERVA su `sowingDate` (a
/// diferencia de las ornamentales de establecimiento, cuyo `sowingDate` se
/// anula) y NO usa un wizard visual de estado. La única diferencia con un grano
/// es el final: la última etapa es `dormancy` (bulbo en reposo), el registro
/// sobrevive y puede iniciar otra temporada (Documento A §0, §2.4, §6).
///
/// Regla: aquí NO vive agronomía. Solo despacho por cultivo.
library;

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/tulip/tulip_assets.dart';
import 'package:bio_g/core/crops/tulip/tulip_catalog.dart';
import 'package:bio_g/core/crops/tulip/tulip_universal_profile.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/widgets/seeds/tulip_models.dart';
import 'package:bio_g/widgets/seeds/tulip_profiles.dart';

/// Id del modo de ciclo compartido.
const String kSeasonalBulbLifecycleModeId = 'seasonal_bulb';

/// Id de la categoría ornamental (fuente de verdad compartida).
const String kSeasonalBulbCategoryIdShared = 'ornamental';

/// Cultivos que usan el runtime bulboso estacional.
const Set<String> kSeasonalBulbCropIds = <String>{
  kCropTulip,
};

/// Fallback compartido (planta genérica del wizard).
const String kSeasonalBulbGenericPlantFallback =
    'assets/icons/wizard/ic_planta_generica.png';

/// True cuando el cultivo debe usar el runtime BULBOSO ESTACIONAL. La
/// categoría ornamental por sí sola NO basta: cactus/suculenta/sábila/maguey
/// (establecimiento) ni el rosal (floración recurrente) heredan este modelo.
bool isSeasonalBulbCrop({
  String? cropId,
  String? cropCategoryId,
  CropCategory? category,
}) {
  final canonical = CropCatalog.canonicalCropKey(cropId);
  return kSeasonalBulbCropIds.contains(canonical);
}

bool isSeasonalBulbContext(DeviceCropContext? context) {
  if (context == null) return false;
  return isSeasonalBulbCrop(
    cropId: context.cropId,
    cropCategoryId: context.cropCategoryId,
  );
}

/// Id canónico del cultivo bulboso estacional, o `null` si no lo es.
String? seasonalBulbCropIdOrNull(String? cropId) {
  final canonical = CropCatalog.canonicalCropKey(cropId);
  return kSeasonalBulbCropIds.contains(canonical) ? canonical : null;
}

/// Cultivo concreto detrás del `cropId`. Único miembro en v1 (tulipán); el
/// enum obliga a resolver cada rama al sumar otra geófita.
enum _SeasonalBulbKind { tulip }

_SeasonalBulbKind _kind(String? cropId) {
  return _SeasonalBulbKind.tulip;
}

// ── Identidad ────────────────────────────────────────────────────────────────

String seasonalBulbLifecycleMode(String? cropId) => switch (_kind(cropId)) {
  _SeasonalBulbKind.tulip => kSeasonalBulbLifecycleModeId,
};

String seasonalBulbCropDisplayName(String? cropId) => switch (_kind(cropId)) {
  _SeasonalBulbKind.tulip => 'Tulipán',
};

String seasonalBulbDefaultProfileId(String? cropId) => switch (_kind(cropId)) {
  _SeasonalBulbKind.tulip => kTuSkip,
};

String seasonalBulbGeneralProfileLabel(String? cropId) =>
    switch (_kind(cropId)) {
      _SeasonalBulbKind.tulip => 'No sé / Tulipán general',
    };

String seasonalBulbGeneralShortLabel(String? cropId) => switch (_kind(cropId)) {
  _SeasonalBulbKind.tulip => 'Tulipán general',
};

// ── Etapas ───────────────────────────────────────────────────────────────────

String normalizeSeasonalBulbStageId(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _SeasonalBulbKind.tulip => normalizeTulipStageId(stageId),
    };

String seasonalBulbStageDisplayName(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _SeasonalBulbKind.tulip => tulipStageDisplayName(stageId),
    };

String seasonalBulbStageCareNoteEs(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _SeasonalBulbKind.tulip => tulipStageCareNoteEs(stageId),
    };

String seasonalBulbUnknownStageId(String? cropId) => switch (_kind(cropId)) {
  _SeasonalBulbKind.tulip => TulipStageIds.fallback,
};

// ── Assets ───────────────────────────────────────────────────────────────────

String seasonalBulbCropIcon(String? cropId) => switch (_kind(cropId)) {
  _SeasonalBulbKind.tulip => TulipAssets.cropIcon,
};

String seasonalBulbProfileIcon(String? cropId, String? profileId) =>
    switch (_kind(cropId)) {
      _SeasonalBulbKind.tulip => TulipAssets.profileIcon(profileId),
    };

String seasonalBulbStageImage(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _SeasonalBulbKind.tulip => TulipAssets.stageImageOrNeutral(stageId),
    };

String seasonalBulbStageUnknownImage(String? cropId) =>
    switch (_kind(cropId)) {
      _SeasonalBulbKind.tulip => TulipAssets.stageUnknown,
    };

// ── Wizard: intenciones de alta (reutiliza el patrón de granos) ──────────────
//
// El Tulipán NO usa un wizard visual de estado. Su alta reutiliza el flujo de
// granos ("lo voy a plantar" / "ya está plantado") con una fecha ancla. Estos
// helpers solo dan los textos con el género correcto.

String seasonalBulbTypeQuestion(String? cropId) => switch (_kind(cropId)) {
  _SeasonalBulbKind.tulip => '¿Qué tipo de tulipán es?',
};

String seasonalBulbGeneralProfileHint(String? cropId) =>
    switch (_kind(cropId)) {
      _SeasonalBulbKind.tulip => 'Recomendado si no sabes el tipo de tulipán',
    };

String seasonalBulbPlannedOptionTitle(String? cropId) =>
    switch (_kind(cropId)) {
      _SeasonalBulbKind.tulip => 'Lo voy a plantar',
    };

String seasonalBulbPlantedOptionTitle(String? cropId) =>
    switch (_kind(cropId)) {
      _SeasonalBulbKind.tulip => 'Ya está plantado',
    };

/// Subtítulo de la tarjeta de riego en el dashboard.
String seasonalBulbIrrigationSubtitle(String? cropId) =>
    switch (_kind(cropId)) {
      _SeasonalBulbKind.tulip =>
        'El tulipán pide humedad estable, pero el exceso deteriora el bulbo',
    };
