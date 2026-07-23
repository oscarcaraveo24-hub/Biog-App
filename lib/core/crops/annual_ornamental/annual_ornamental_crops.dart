/// Capa COMPARTIDA de las ornamentales ANUALES VERDADERAS en modo
/// `annual_ornamental` (Girasol hoy; más adelante otras anuales de flor de
/// temporada).
///
/// Existe por la misma razón que `ornamental_crops.dart`,
/// `recurring_bloom_crops.dart` y `seasonal_bulb_crops.dart`:
/// `isAnnualOrnamentalCrop()` NO puede ser un alias de `isSunflowerCrop()`. La
/// infraestructura compartida (runtime, persistencia, wizards, pantallas)
/// pregunta por el MODO DE CICLO; cada planta conserva su biología (targets,
/// pesos, ventanas, textos, sanidad) en su propio módulo.
///
/// Diferencia con `seasonal_bulb` (tulipán): ambos usan un RELOJ ANUAL tipo
/// granos (fecha ancla + días → etapa) y por eso CONSERVAN su `sowingDate` (a
/// diferencia de las ornamentales de establecimiento, cuyo `sowingDate` se
/// anula) y NO usan un wizard visual de estado. La ÚNICA diferencia es el final:
/// el bulboso estacional termina en `dormancy` (el registro sobrevive y puede
/// reiniciar temporada); la anual verdadera termina en `cycle_complete`
/// TERMINAL: la planta cierra su ciclo y una nueva temporada exige una nueva
/// siembra explícita (Documento A §0, §8).
///
/// Regla: aquí NO vive agronomía. Solo despacho por cultivo.
library;

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_assets.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_catalog.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_lifecycle.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_universal_profile.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/widgets/seeds/sunflower_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_profiles.dart';

/// Id del modo de ciclo compartido.
const String kAnnualOrnamentalLifecycleModeId = 'annual_ornamental';

/// Id de la categoría ornamental (fuente de verdad compartida).
const String kAnnualOrnamentalCategoryIdShared = 'ornamental';

/// Cultivos que usan el runtime ORNAMENTAL ANUAL VERDADERO.
const Set<String> kAnnualOrnamentalCropIds = <String>{
  kCropSunflower,
};

/// Fallback compartido (planta genérica del wizard).
const String kAnnualOrnamentalGenericPlantFallback =
    'assets/icons/wizard/ic_planta_generica.png';

/// True cuando el cultivo debe usar el runtime ORNAMENTAL ANUAL VERDADERO. La
/// categoría ornamental por sí sola NO basta: cactus/suculenta/sábila/maguey
/// (establecimiento), el rosal (floración recurrente) y el tulipán (bulboso
/// estacional) NO heredan este modelo. En particular,
/// `isEstablishmentMaintenanceCrop(crop_sunflower) == false` (Documento A §4.2).
bool isAnnualOrnamentalCrop({
  String? cropId,
  String? cropCategoryId,
  CropCategory? category,
}) {
  final canonical = CropCatalog.canonicalCropKey(cropId);
  return kAnnualOrnamentalCropIds.contains(canonical);
}

bool isAnnualOrnamentalContext(DeviceCropContext? context) {
  if (context == null) return false;
  return isAnnualOrnamentalCrop(
    cropId: context.cropId,
    cropCategoryId: context.cropCategoryId,
  );
}

/// Id canónico del cultivo ornamental anual, o `null` si no lo es.
String? annualOrnamentalCropIdOrNull(String? cropId) {
  final canonical = CropCatalog.canonicalCropKey(cropId);
  return kAnnualOrnamentalCropIds.contains(canonical) ? canonical : null;
}

/// Cultivo concreto detrás del `cropId`. Único miembro en v1 (girasol); el enum
/// obliga a resolver cada rama al sumar otra anual.
enum _AnnualOrnamentalKind { sunflower }

_AnnualOrnamentalKind _kind(String? cropId) {
  return _AnnualOrnamentalKind.sunflower;
}

// ── Identidad ────────────────────────────────────────────────────────────────

String annualOrnamentalLifecycleMode(String? cropId) => switch (_kind(cropId)) {
  _AnnualOrnamentalKind.sunflower => kSunflowerLifecycleModeId,
};

String annualOrnamentalCropDisplayName(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => 'Girasol',
    };

String annualOrnamentalDefaultProfileId(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => kGiSkip,
    };

String annualOrnamentalGeneralProfileLabel(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => 'No sé / Girasol general',
    };

String annualOrnamentalGeneralShortLabel(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => 'Girasol general',
    };

// ── Etapas ───────────────────────────────────────────────────────────────────

String normalizeAnnualOrnamentalStageId(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => normalizeSunflowerStageId(stageId),
    };

String annualOrnamentalStageDisplayName(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => sunflowerStageDisplayName(stageId),
    };

String annualOrnamentalStageCareNoteEs(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => sunflowerStageCareNoteEs(stageId),
    };

String annualOrnamentalUnknownStageId(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => SunflowerStageIds.unknown,
    };

// ── Assets ───────────────────────────────────────────────────────────────────

String annualOrnamentalCropIcon(String? cropId) => switch (_kind(cropId)) {
  _AnnualOrnamentalKind.sunflower => SunflowerAssets.cropIcon,
};

String annualOrnamentalProfileIcon(String? cropId, String? profileId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => SunflowerAssets.profileIcon(profileId),
    };

String annualOrnamentalStageImage(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower =>
        SunflowerAssets.stageImageOrNeutral(stageId),
    };

String annualOrnamentalStageUnknownImage(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => SunflowerAssets.stageUnknown,
    };

// ── Wizard: intenciones de alta (reutiliza el patrón de granos) ──────────────
//
// El Girasol NO usa un wizard visual de estado con arte propio. Su alta
// reutiliza el flujo de granos ("lo voy a sembrar" / "ya está sembrado") con una
// fecha ancla. Estos helpers solo dan los textos con el género correcto.

String annualOrnamentalTypeQuestion(String? cropId) => switch (_kind(cropId)) {
  _AnnualOrnamentalKind.sunflower => '¿Qué tipo de girasol es?',
};

String annualOrnamentalGeneralProfileHint(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower =>
        'Recomendado si no sabes el tipo de girasol',
    };

String annualOrnamentalPlannedOptionTitle(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => 'Lo voy a sembrar',
    };

String annualOrnamentalPlantedOptionTitle(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => 'Ya está sembrado o plantado',
    };

/// Subtítulo de la tarjeta de riego en el dashboard.
String annualOrnamentalIrrigationSubtitle(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower =>
        'El girasol pide humedad estable; el botón y la flor son las etapas '
            'más sensibles al déficit',
    };

/// Texto de fin de ciclo (Documento A §8.4): invita a registrar una nueva
/// siembra, nunca a "reiniciar" o "salir de dormancia".
String annualOrnamentalCycleCompleteHelper(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower =>
        'Este Girasol terminó su ciclo. Para cultivar otro, registra una nueva '
            'siembra.',
    };

/// Referencia al cap NPK del cultivo (orientativo, nunca dosis).
double annualOrnamentalNCap(String? cropId) => switch (_kind(cropId)) {
  _AnnualOrnamentalKind.sunflower => SunflowerUniversalProfile.capN,
};
