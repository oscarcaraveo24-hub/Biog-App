/// Capa COMPARTIDA de las ornamentales ANUALES VERDADERAS en modo
/// `annual_ornamental` (Girasol y Cempasúchil hoy; más adelante otras anuales
/// de flor de temporada).
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
/// siembra explícita (Girasol Documento A §0, §8; Cempasúchil Documento A §0.3,
/// §10.11).
///
/// Regla: aquí NO vive agronomía. Solo despacho por cultivo.
///
/// REGLA DURA DE SEGURIDAD (Cempasúchil Documento A §2.2): `_kind()` NUNCA cae
/// en Girasol por defecto. Un cropId anual desconocido resuelve al miembro
/// `unknown` del enum y cada helper devuelve un valor NEUTRAL, jamás un texto,
/// un asset, un perfil o un cap de otro cultivo.
library;

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/marigold/marigold_assets.dart';
import 'package:bio_g/core/crops/marigold/marigold_catalog.dart';
import 'package:bio_g/core/crops/marigold/marigold_lifecycle.dart';
import 'package:bio_g/core/crops/marigold/marigold_universal_profile.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_assets.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_catalog.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_lifecycle.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_universal_profile.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/widgets/seeds/marigold_models.dart';
import 'package:bio_g/widgets/seeds/marigold_profiles.dart';
import 'package:bio_g/widgets/seeds/sunflower_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_profiles.dart';

/// Id del modo de ciclo compartido.
const String kAnnualOrnamentalLifecycleModeId = 'annual_ornamental';

/// Id de la categoría ornamental (fuente de verdad compartida).
const String kAnnualOrnamentalCategoryIdShared = 'ornamental';

/// Cultivos que usan el runtime ORNAMENTAL ANUAL VERDADERO.
const Set<String> kAnnualOrnamentalCropIds = <String>{
  kCropSunflower,
  kCropMarigold,
};

/// Fallback compartido (planta genérica del wizard).
const String kAnnualOrnamentalGenericPlantFallback =
    'assets/icons/wizard/ic_planta_generica.png';

/// True cuando el cultivo debe usar el runtime ORNAMENTAL ANUAL VERDADERO. La
/// categoría ornamental por sí sola NO basta: cactus/suculenta/sábila/maguey
/// (establecimiento), el rosal (floración recurrente) y el tulipán (bulboso
/// estacional) NO heredan este modelo. En particular,
/// `isEstablishmentMaintenanceCrop(crop_sunflower) == false` y
/// `isEstablishmentMaintenanceCrop(crop_marigold) == false`.
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

/// Cultivo concreto detrás del `cropId`. El miembro `unknown` es la red de
/// seguridad: obliga a resolver cada rama al sumar otra anual y evita que un
/// cropId no reconocido herede la identidad, los assets o la agronomía del
/// Girasol (Cempasúchil Documento A §2.2).
enum _AnnualOrnamentalKind { sunflower, marigold, unknown }

_AnnualOrnamentalKind _kind(String? cropId) {
  final canonical = CropCatalog.canonicalCropKey(cropId);
  switch (canonical) {
    case kCropSunflower:
      return _AnnualOrnamentalKind.sunflower;
    case kCropMarigold:
      return _AnnualOrnamentalKind.marigold;
    default:
      return _AnnualOrnamentalKind.unknown;
  }
}

// ── Identidad ────────────────────────────────────────────────────────────────

String annualOrnamentalLifecycleMode(String? cropId) => switch (_kind(cropId)) {
  _AnnualOrnamentalKind.sunflower => kSunflowerLifecycleModeId,
  _AnnualOrnamentalKind.marigold => kMarigoldLifecycleModeId,
  _AnnualOrnamentalKind.unknown => kAnnualOrnamentalLifecycleModeId,
};

String annualOrnamentalCropDisplayName(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => 'Girasol',
      _AnnualOrnamentalKind.marigold => 'Cempasúchil',
      _AnnualOrnamentalKind.unknown => 'Planta ornamental',
    };

String annualOrnamentalDefaultProfileId(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => kGiSkip,
      _AnnualOrnamentalKind.marigold => kCsSkip,
      _AnnualOrnamentalKind.unknown => '',
    };

String annualOrnamentalGeneralProfileLabel(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => 'No sé / Girasol general',
      _AnnualOrnamentalKind.marigold => 'No sé / Cempasúchil general',
      _AnnualOrnamentalKind.unknown => 'No sé / Perfil general',
    };

String annualOrnamentalGeneralShortLabel(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => 'Girasol general',
      _AnnualOrnamentalKind.marigold => 'Cempasúchil general',
      _AnnualOrnamentalKind.unknown => 'Perfil general',
    };

// ── Etapas ───────────────────────────────────────────────────────────────────

String normalizeAnnualOrnamentalStageId(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => normalizeSunflowerStageId(stageId),
      _AnnualOrnamentalKind.marigold => normalizeMarigoldStageId(stageId),
      // Sin cultivo resuelto no se normaliza contra la taxonomía de nadie: se
      // devuelve la banda conservadora compartida.
      _AnnualOrnamentalKind.unknown => 'unknown',
    };

String annualOrnamentalStageDisplayName(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => sunflowerStageDisplayName(stageId),
      _AnnualOrnamentalKind.marigold => marigoldStageDisplayName(stageId),
      _AnnualOrnamentalKind.unknown => 'Etapa por confirmar',
    };

String annualOrnamentalStageCareNoteEs(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => sunflowerStageCareNoteEs(stageId),
      _AnnualOrnamentalKind.marigold => marigoldStageCareNoteEs(stageId),
      _AnnualOrnamentalKind.unknown =>
        'Confirma el cultivo y la fecha para mostrar recomendaciones de '
            'cuidado.',
    };

String annualOrnamentalUnknownStageId(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => SunflowerStageIds.unknown,
      _AnnualOrnamentalKind.marigold => MarigoldStageIds.unknown,
      _AnnualOrnamentalKind.unknown => 'unknown',
    };

// ── Assets ───────────────────────────────────────────────────────────────────

String annualOrnamentalCropIcon(String? cropId) => switch (_kind(cropId)) {
  _AnnualOrnamentalKind.sunflower => SunflowerAssets.cropIcon,
  _AnnualOrnamentalKind.marigold => MarigoldAssets.cropIcon,
  _AnnualOrnamentalKind.unknown => kAnnualOrnamentalGenericPlantFallback,
};

String annualOrnamentalProfileIcon(String? cropId, String? profileId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => SunflowerAssets.profileIcon(profileId),
      _AnnualOrnamentalKind.marigold => MarigoldAssets.profileIcon(profileId),
      _AnnualOrnamentalKind.unknown => kAnnualOrnamentalGenericPlantFallback,
    };

String annualOrnamentalStageImage(String? cropId, String? stageId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower =>
        SunflowerAssets.stageImageOrNeutral(stageId),
      _AnnualOrnamentalKind.marigold =>
        MarigoldAssets.stageImageOrNeutral(stageId),
      _AnnualOrnamentalKind.unknown => kAnnualOrnamentalGenericPlantFallback,
    };

String annualOrnamentalStageUnknownImage(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => SunflowerAssets.stageUnknown,
      _AnnualOrnamentalKind.marigold => MarigoldAssets.stageUnknown,
      _AnnualOrnamentalKind.unknown => kAnnualOrnamentalGenericPlantFallback,
    };

// ── Wizard: intenciones de alta (reutiliza el patrón de granos) ──────────────
//
// Ni el Girasol ni el Cempasúchil usan un wizard visual de estado con arte
// propio. Su alta reutiliza el flujo de granos ("lo voy a sembrar" / "ya está
// sembrado") con una fecha ancla. Estos helpers solo dan los textos con el
// género correcto.

String annualOrnamentalTypeQuestion(String? cropId) => switch (_kind(cropId)) {
  _AnnualOrnamentalKind.sunflower => '¿Qué tipo de girasol es?',
  _AnnualOrnamentalKind.marigold => '¿Qué tipo de Cempasúchil es?',
  _AnnualOrnamentalKind.unknown => '¿Qué tipo de planta es?',
};

String annualOrnamentalGeneralProfileHint(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower =>
        'Recomendado si no sabes el tipo de girasol',
      _AnnualOrnamentalKind.marigold => 'Recomendado si no conoces el tipo',
      _AnnualOrnamentalKind.unknown => 'Recomendado si no conoces el tipo',
    };

String annualOrnamentalPlannedOptionTitle(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => 'Lo voy a sembrar',
      _AnnualOrnamentalKind.marigold => 'Lo voy a sembrar',
      _AnnualOrnamentalKind.unknown => 'Lo voy a sembrar',
    };

String annualOrnamentalPlantedOptionTitle(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower => 'Ya está sembrado o plantado',
      _AnnualOrnamentalKind.marigold => 'Ya está sembrado o plantado',
      _AnnualOrnamentalKind.unknown => 'Ya está sembrado o plantado',
    };

/// Subtítulo de la tarjeta de riego en el dashboard.
String annualOrnamentalIrrigationSubtitle(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower =>
        'El girasol pide humedad estable; el botón y la flor son las etapas '
            'más sensibles al déficit',
      _AnnualOrnamentalKind.marigold =>
        'El cempasúchil pide humedad estable y aire en la raíz; el botón y la '
            'flor son las etapas más sensibles al déficit',
      _AnnualOrnamentalKind.unknown =>
        'Mantén una humedad estable y revisa el drenaje',
    };

/// Texto de fin de ciclo: invita a registrar una nueva siembra, nunca a
/// "reiniciar" o "salir de dormancia" (Girasol Documento A §8.4; Cempasúchil
/// Documento A §10.11, §15.6).
String annualOrnamentalCycleCompleteHelper(String? cropId) =>
    switch (_kind(cropId)) {
      _AnnualOrnamentalKind.sunflower =>
        'Este Girasol terminó su ciclo. Para cultivar otro, registra una nueva '
            'siembra.',
      _AnnualOrnamentalKind.marigold =>
        'Este Cempasúchil terminó su ciclo. Para cultivar otro, registra una '
            'nueva siembra.',
      _AnnualOrnamentalKind.unknown =>
        'Esta planta terminó su ciclo. Para cultivar otra, registra una nueva '
            'siembra.',
    };

/// Referencia al cap NPK del cultivo (orientativo, nunca dosis).
double annualOrnamentalNCap(String? cropId) => switch (_kind(cropId)) {
  _AnnualOrnamentalKind.sunflower => SunflowerUniversalProfile.capN,
  _AnnualOrnamentalKind.marigold => MarigoldUniversalProfile.capN,
  _AnnualOrnamentalKind.unknown => 120.0,
};

/// True cuando el perfil elegido es de FLOR DE CORTE. Se usa solo para el
/// rótulo de la línea de ciclo ("Ventana de corte" en vez de "Ventana de
/// floración"). NO activa cosecha ni rendimiento en ningún cultivo, y en el
/// Cempasúchil cortar una flor tampoco cierra el ciclo (Documento A §6.2,
/// §9.4).
bool annualOrnamentalIsCutFlowerProfile(String? cropId, String? profileId) {
  final id = profileId?.trim().toLowerCase() ?? '';
  if (id.isEmpty) return false;
  return switch (_kind(cropId)) {
    _AnnualOrnamentalKind.sunflower => id == kGi04CutFlowerSingleStem,
    _AnnualOrnamentalKind.marigold => id == kCs02TallCutFlower,
    _AnnualOrnamentalKind.unknown => false,
  };
}
