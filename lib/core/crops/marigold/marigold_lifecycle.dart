// lib/core/crops/marigold/marigold_lifecycle.dart
//
// Identidad de ciclo y helpers del reloj/onboarding del Cempasúchil (Documento
// A §9, §13, §15). El Cempasúchil es una ANUAL VERDADERA en modo
// `annual_ornamental` con motor temporal `annual_stage_clock`: la fecha ancla
// es `sowingDate` y el final `cycle_complete` es TERMINAL. Este archivo NO
// contiene agronomía (targets/pesos viven en `marigold_universal_profile.dart`)
// ni sanidad (`marigold_risk_catalog.dart`); solo la identidad de modo, las
// estimaciones de fecha del wizard (trasplante y planta comprada) y el contexto
// declarado de luz nocturna.
library;

import 'package:bio_g/widgets/seeds/marigold_models.dart';
import 'package:bio_g/widgets/seeds/marigold_profiles.dart';

/// Id del modo de ciclo (Documento A §0.1, §9.1). Se persiste como
/// `lifecycleModeId` para identificar el modo; la ETAPA se resuelve por
/// `sowingDate`, no por este campo.
const String kMarigoldLifecycleModeId = 'annual_ornamental';

/// Motor temporal declarado (Documento A §0.1, §9.1). Uso documental/interno;
/// nunca se muestra al usuario.
const String kMarigoldTemporalEngine = 'annual_stage_clock';

/// En v1 no se retrasa la etapa por lecturas aisladas de sensor ni por
/// fotoperiodo (Documento A §9.4, §12.6). El runtime pasa este valor al motor.
const int kMarigoldStressDelayDays = 0;

/// Estados visuales que ofrece el wizard para una planta comprada / sin fecha
/// conocida (Documento A §13.4). NO reemplazan el reloj: solo producen una
/// `sowingDate` estimada; después de guardar, la fecha vuelve a ser la fuente
/// única.
enum MarigoldVisualState {
  seedling,
  severalLeaves,
  formedNoBud,
  withBud,
  flowerOpen,
  flowerAging,
  plantDrying,
  unsure,
}

/// Mapea una respuesta visual a la etapa usada para estimar (Documento A
/// §13.4).
String marigoldVisualStateToStageId(MarigoldVisualState state) {
  switch (state) {
    case MarigoldVisualState.seedling:
      return MarigoldStageIds.earlyVegetativeGrowth;
    case MarigoldVisualState.severalLeaves:
      return MarigoldStageIds.activeVegetativeGrowth;
    case MarigoldVisualState.formedNoBud:
      return MarigoldStageIds.stemElongation;
    case MarigoldVisualState.withBud:
      return MarigoldStageIds.budFormation;
    case MarigoldVisualState.flowerOpen:
      return MarigoldStageIds.flowering;
    case MarigoldVisualState.flowerAging:
      return MarigoldStageIds.postBloom;
    case MarigoldVisualState.plantDrying:
      return MarigoldStageIds.senescence;
    case MarigoldVisualState.unsure:
      return MarigoldStageIds.unknown;
  }
}

/// Etiqueta visible de cada estado visual del wizard (Documento A §13.4).
String marigoldVisualStateLabelEs(MarigoldVisualState state) {
  switch (state) {
    case MarigoldVisualState.seedling:
      return 'Es una plántula con pocas hojas';
    case MarigoldVisualState.severalLeaves:
      return 'Tiene varias hojas y está ramificando';
    case MarigoldVisualState.formedNoBud:
      return 'Ya tomó forma, pero no veo botones';
    case MarigoldVisualState.withBud:
      return 'Ya tiene botones';
    case MarigoldVisualState.flowerOpen:
      return 'Ya tiene flores abiertas';
    case MarigoldVisualState.flowerAging:
      return 'La mayoría de las flores está envejeciendo';
    case MarigoldVisualState.plantDrying:
      return 'La planta completa se está secando';
    case MarigoldVisualState.unsure:
      return 'No estoy seguro';
  }
}

MarigoldVisualState? marigoldVisualStateFromId(String? raw) {
  final v = raw?.trim().toLowerCase();
  switch (v) {
    case 'seedling':
    case 'plantula':
    case 'plántula':
      return MarigoldVisualState.seedling;
    case 'several_leaves':
    case 'severalleaves':
    case 'varias_hojas':
      return MarigoldVisualState.severalLeaves;
    case 'formed_no_bud':
    case 'formednobud':
    case 'sin_boton':
    case 'sin_botones':
      return MarigoldVisualState.formedNoBud;
    case 'with_bud':
    case 'withbud':
    case 'con_boton':
    case 'con_botones':
      return MarigoldVisualState.withBud;
    case 'flower_open':
    case 'floweropen':
    case 'flor_abierta':
    case 'flores_abiertas':
      return MarigoldVisualState.flowerOpen;
    case 'flower_aging':
    case 'floweraging':
    case 'flor_envejeciendo':
    case 'flores_envejeciendo':
      return MarigoldVisualState.flowerAging;
    case 'plant_drying':
    case 'plantdrying':
    case 'drying':
    case 'secandose':
      return MarigoldVisualState.plantDrying;
    case 'unsure':
    case 'no_estoy_seguro':
      return MarigoldVisualState.unsure;
    default:
      return null;
  }
}

/// Texto UX del perfil general (Documento A §6.5). Se muestra al elegir
/// "No sé / Cempasúchil general": deja claro que el tipo puede precisarse
/// después SIN perder historial (Documento A §7 reglas de compatibilidad). No
/// es el subtítulo de la opción del wizard, que es más corto.
const String kMarigoldGeneralProfileUxNoteEs =
    'Este es un perfil general de Cempasúchil. Si después sabes si es '
    'tradicional, de corte, compacto o para paisaje, puedes cambiar el tipo '
    'sin perder el historial.';

/// Rango de días [inicio, fin] de una etapa dentro del calendario de un perfil.
/// Reproduce las fronteras del `MarigoldEngine` (1-based, `sowing` en el día 1).
({int startDay, int endDay}) marigoldStageDayRange(
  MarigoldProfile p,
  String stageId,
) {
  final id = normalizeMarigoldStageId(stageId);
  final sowingEnd = p.sowingEndDay < 1 ? 1 : p.sowingEndDay;
  final germStart = sowingEnd + 1;
  final germEnd = germStart > p.germinationEndDay
      ? germStart
      : p.germinationEndDay;
  final emergStart = germEnd + 1;
  final emergEnd = emergStart > p.emergenceEndDay
      ? emergStart
      : p.emergenceEndDay;
  final earlyStart = emergEnd + 1;
  final earlyEnd = earlyStart > p.earlyVegetativeEndDay
      ? earlyStart
      : p.earlyVegetativeEndDay;
  final activeStart = earlyEnd + 1;
  final activeEnd = activeStart > p.activeVegetativeEndDay
      ? activeStart
      : p.activeVegetativeEndDay;
  final stemStart = activeEnd + 1;
  final stemEnd = stemStart > p.stemElongationEndDay
      ? stemStart
      : p.stemElongationEndDay;
  final budStart = stemEnd + 1;
  final budEnd = budStart > p.budFormationEndDay
      ? budStart
      : p.budFormationEndDay;
  final flowerStart = budEnd + 1;
  final flowerEnd = flowerStart > p.floweringEndDay
      ? flowerStart
      : p.floweringEndDay;
  final postStart = flowerEnd + 1;
  final postEnd = postStart > p.postBloomEndDay ? postStart : p.postBloomEndDay;
  final senStart = postEnd + 1;
  final senEnd = senStart > p.senescenceEndDay ? senStart : p.senescenceEndDay;
  final cycleStart = senEnd + 1;

  switch (id) {
    case MarigoldStageIds.sowing:
      return (startDay: 1, endDay: sowingEnd);
    case MarigoldStageIds.germination:
      return (startDay: germStart, endDay: germEnd);
    case MarigoldStageIds.emergence:
      return (startDay: emergStart, endDay: emergEnd);
    case MarigoldStageIds.earlyVegetativeGrowth:
      return (startDay: earlyStart, endDay: earlyEnd);
    case MarigoldStageIds.activeVegetativeGrowth:
      return (startDay: activeStart, endDay: activeEnd);
    case MarigoldStageIds.stemElongation:
      return (startDay: stemStart, endDay: stemEnd);
    case MarigoldStageIds.budFormation:
      return (startDay: budStart, endDay: budEnd);
    case MarigoldStageIds.flowering:
      return (startDay: flowerStart, endDay: flowerEnd);
    case MarigoldStageIds.postBloom:
      return (startDay: postStart, endDay: postEnd);
    case MarigoldStageIds.senescence:
      return (startDay: senStart, endDay: senEnd);
    default:
      // cycle_complete / unknown: el inicio del cierre.
      return (startDay: cycleStart, endDay: cycleStart);
  }
}

/// Estimación de `sowingDate` a partir de la fecha de TRASPLANTE (Documento A
/// §13.3). El reloj sigue anclado a la SIEMBRA: se resta la edad típica de la
/// plántula del perfil. Es una estimación de onboarding, no una afirmación de
/// edad real; el trasplante NUNCA reinicia el ciclo (§9.4).
DateTime estimateMarigoldSowingDateFromTransplant({
  required String? profileId,
  required DateTime transplantDate,
}) {
  final profile = _profileOrSkip(profileId);
  return transplantDate.subtract(
    Duration(days: profile.transplantAgeOffsetDays),
  );
}

/// Estimación de `sowingDate` a partir del ESTADO VISUAL de una planta comprada
/// (Documento A §13.4). Retrocalcula desde el punto medio de la etapa del
/// perfil. Devuelve null cuando el estado es "No estoy seguro" (→ etapa
/// `unknown` y fecha por completar).
DateTime? estimateMarigoldSowingDateFromVisualState({
  required String? profileId,
  required MarigoldVisualState state,
  required DateTime now,
}) {
  if (state == MarigoldVisualState.unsure) return null;
  final profile = _profileOrSkip(profileId);
  final stageId = marigoldVisualStateToStageId(state);
  final range = marigoldStageDayRange(profile, stageId);
  final midDay = ((range.startDay + range.endDay) / 2).round();
  final effectiveDay = midDay < 1 ? 1 : midDay;
  // sowingDate = now - (día efectivo - 1): el día 1 es el día de la siembra.
  return now.subtract(Duration(days: effectiveDay - 1));
}

// ── Luz nocturna declarada (Documento A §2.4, §11, §15.4) ────────────────────
//
// La sonda BIO-G mide suelo: NO puede saber si hay un poste, un foco de patio o
// una lámpara de vivero encendida por la noche. Por eso la exposición nocturna
// es un CONTEXTO CONFIRMADO POR EL USUARIO, nunca una lectura automática, y no
// modifica el AgroScore ni la etapa (Documento B §19.1, §24.4). En v1 solo
// alimenta textos y diferenciales de sanidad.

/// Exposición a luz artificial nocturna, declarada por la persona.
enum MarigoldNightLightExposure {
  noneConfirmed,
  occasional,
  nearbyLight,
  greenhouseControlled,
  unknown,
}

/// Id canónico persistible de `nightLightExposureId` (Documento A §2.4).
String marigoldNightLightExposureId(MarigoldNightLightExposure value) {
  switch (value) {
    case MarigoldNightLightExposure.noneConfirmed:
      return 'none_confirmed';
    case MarigoldNightLightExposure.occasional:
      return 'occasional';
    case MarigoldNightLightExposure.nearbyLight:
      return 'nearby_light';
    case MarigoldNightLightExposure.greenhouseControlled:
      return 'greenhouse_controlled';
    case MarigoldNightLightExposure.unknown:
      return 'unknown';
  }
}

MarigoldNightLightExposure marigoldNightLightExposureFromId(String? raw) {
  final v = raw?.trim().toLowerCase();
  switch (v) {
    case 'none_confirmed':
    case 'none':
    case 'no':
      return MarigoldNightLightExposure.noneConfirmed;
    case 'occasional':
    case 'algunas_noches':
      return MarigoldNightLightExposure.occasional;
    case 'nearby_light':
    case 'nearbylight':
    case 'casi_todas_las_noches':
      return MarigoldNightLightExposure.nearbyLight;
    case 'greenhouse_controlled':
    case 'greenhousecontrolled':
    case 'invernadero':
      return MarigoldNightLightExposure.greenhouseControlled;
    default:
      return MarigoldNightLightExposure.unknown;
  }
}

/// Pregunta del wizard (Documento A §15.4). Es opcional: nunca bloquea el alta.
const String kMarigoldNightLightQuestionEs =
    '¿La planta recibe luz de un foco, ventana o poste durante la noche?';

/// Texto de ayuda de la pregunta (Documento A §15.4). Prohibido decir "sin 12
/// horas exactas no florecerá" (§11.2).
const String kMarigoldNightLightHelperEs =
    'Algunos tipos de Cempasúchil florecen más tarde cuando se interrumpe la '
    'oscuridad nocturna. La respuesta cambia según la variedad.';

/// Etiqueta visible de cada opción (Documento A §15.4).
String marigoldNightLightLabelEs(MarigoldNightLightExposure value) {
  switch (value) {
    case MarigoldNightLightExposure.noneConfirmed:
      return 'No';
    case MarigoldNightLightExposure.occasional:
      return 'Sí, algunas noches';
    case MarigoldNightLightExposure.nearbyLight:
      return 'Sí, casi todas las noches';
    case MarigoldNightLightExposure.greenhouseControlled:
      return 'Está en invernadero con luz controlada';
    case MarigoldNightLightExposure.unknown:
      return 'No lo sé';
  }
}

/// Aviso prudente sobre fotoperiodo (Documento A §11.2). Solo se muestra cuando
/// la persona reporta luz nocturna y los botones tardan; NUNCA afirma una causa
/// ni promete una fecha de floración.
const String kMarigoldPhotoperiodCautionEs =
    'Si los botones tardan en aparecer y la planta recibe luz de un foco o '
    'poste por la noche, revisa esa exposición. La luz nocturna puede retrasar '
    'algunos tipos.';

/// Aviso específico del perfil de corte (Documento A §11.2, §19.2 del
/// Documento B): los días cortos tempranos pueden adelantar la floración a
/// costa de la longitud del tallo.
const String kMarigoldShortDayCutFlowerCautionEs =
    'En Cempasúchil de corte, los días cortos demasiado temprano pueden '
    'adelantar la floración y dejar tallos más cortos.';

MarigoldProfile _profileOrSkip(String? profileId) {
  final canonical =
      resolveCanonicalMarigoldProfileId((profileId ?? '').trim()) ?? kCsSkip;
  return marigoldProfiles[canonical] ?? marigoldProfiles[kCsSkip]!;
}
