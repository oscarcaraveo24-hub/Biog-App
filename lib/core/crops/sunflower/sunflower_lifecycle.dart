// lib/core/crops/sunflower/sunflower_lifecycle.dart
//
// Identidad de ciclo y helpers del reloj/onboarding del Girasol (Documento A
// §8, §9, §13). El Girasol es una ANUAL VERDADERA en modo `annual_ornamental`
// con motor temporal `annual_stage_clock`: la fecha ancla es `sowingDate` y el
// final `cycle_complete` es TERMINAL. Este archivo NO contiene agronomía
// (targets/pesos viven en `sunflower_universal_profile.dart`) ni sanidad
// (`sunflower_risk_catalog.dart`); solo la identidad de modo y las estimaciones
// de fecha del wizard (trasplante y planta comprada).
library;

import 'package:bio_g/widgets/seeds/sunflower_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_profiles.dart';

/// Id del modo de ciclo (Documento A §0.1, §4.1). Se persiste como
/// `lifecycleModeId` para identificar el modo; la ETAPA se resuelve por
/// `sowingDate`, no por este campo (Documento A §4.4).
const String kSunflowerLifecycleModeId = 'annual_ornamental';

/// Motor temporal declarado (Documento A §4.1). Uso documental/interno; nunca se
/// muestra al usuario (Documento A §14.3).
const String kSunflowerTemporalEngine = 'annual_stage_clock';

/// En v1 no se retrasa la etapa por lecturas aisladas de sensor (Documento A
/// §9.10). El runtime pasa este valor al motor.
const int kSunflowerStressDelayDays = 0;

/// Estados visuales que ofrece el wizard para una planta comprada / sin fecha
/// conocida (Documento A §9.7). NO reemplazan el reloj: solo producen una
/// `sowingDate` estimada; después de guardar, la fecha vuelve a ser la fuente
/// única (Documento A §9.7 regla crítica).
enum SunflowerVisualState {
  seedling,
  severalLeaves,
  tallNoBud,
  withBud,
  flowerOpen,
  flowerAging,
  drying,
  unsure,
}

/// Mapea una respuesta visual a la etapa usada para estimar (Documento A §9.7).
String sunflowerVisualStateToStageId(SunflowerVisualState state) {
  switch (state) {
    case SunflowerVisualState.seedling:
      return SunflowerStageIds.earlyVegetativeGrowth;
    case SunflowerVisualState.severalLeaves:
      return SunflowerStageIds.activeVegetativeGrowth;
    case SunflowerVisualState.tallNoBud:
      return SunflowerStageIds.stemElongation;
    case SunflowerVisualState.withBud:
      return SunflowerStageIds.budFormation;
    case SunflowerVisualState.flowerOpen:
      return SunflowerStageIds.flowering;
    case SunflowerVisualState.flowerAging:
      return SunflowerStageIds.postBloom;
    case SunflowerVisualState.drying:
      return SunflowerStageIds.senescence;
    case SunflowerVisualState.unsure:
      return SunflowerStageIds.unknown;
  }
}

/// Etiqueta visible de cada estado visual del wizard (Documento A §9.7).
String sunflowerVisualStateLabelEs(SunflowerVisualState state) {
  switch (state) {
    case SunflowerVisualState.seedling:
      return 'Es una plántula con pocas hojas';
    case SunflowerVisualState.severalLeaves:
      return 'Tiene varias hojas, pero aún no se alarga';
    case SunflowerVisualState.tallNoBud:
      return 'Ya está alta, sin botón visible';
    case SunflowerVisualState.withBud:
      return 'Ya tiene botón';
    case SunflowerVisualState.flowerOpen:
      return 'La flor está abierta';
    case SunflowerVisualState.flowerAging:
      return 'La flor ya está envejeciendo';
    case SunflowerVisualState.drying:
      return 'La planta ya se está secando';
    case SunflowerVisualState.unsure:
      return 'No estoy seguro';
  }
}

SunflowerVisualState? sunflowerVisualStateFromId(String? raw) {
  final v = raw?.trim().toLowerCase();
  switch (v) {
    case 'seedling':
    case 'plantula':
    case 'plántula':
      return SunflowerVisualState.seedling;
    case 'several_leaves':
    case 'severalleaves':
    case 'varias_hojas':
      return SunflowerVisualState.severalLeaves;
    case 'tall_no_bud':
    case 'tallnobud':
    case 'alta_sin_boton':
      return SunflowerVisualState.tallNoBud;
    case 'with_bud':
    case 'withbud':
    case 'con_boton':
      return SunflowerVisualState.withBud;
    case 'flower_open':
    case 'floweropen':
    case 'flor_abierta':
      return SunflowerVisualState.flowerOpen;
    case 'flower_aging':
    case 'floweraging':
    case 'flor_envejeciendo':
      return SunflowerVisualState.flowerAging;
    case 'drying':
    case 'secandose':
      return SunflowerVisualState.drying;
    case 'unsure':
    case 'no_estoy_seguro':
      return SunflowerVisualState.unsure;
    default:
      return null;
  }
}

/// Rango de días [inicio, fin] de una etapa dentro del calendario de un perfil.
/// Reproduce las fronteras del `SunflowerEngine` (1-based, `sowing` en el día 1).
({int startDay, int endDay}) sunflowerStageDayRange(
  SunflowerProfile p,
  String stageId,
) {
  final id = normalizeSunflowerStageId(stageId);
  final sowingEnd = p.sowingEndDay < 1 ? 1 : p.sowingEndDay;
  final germStart = sowingEnd + 1;
  final germEnd = germStart > p.germinationEndDay ? germStart : p.germinationEndDay;
  final emergStart = germEnd + 1;
  final emergEnd = emergStart > p.emergenceEndDay ? emergStart : p.emergenceEndDay;
  final earlyStart = emergEnd + 1;
  final earlyEnd =
      earlyStart > p.earlyVegetativeEndDay ? earlyStart : p.earlyVegetativeEndDay;
  final activeStart = earlyEnd + 1;
  final activeEnd =
      activeStart > p.activeVegetativeEndDay ? activeStart : p.activeVegetativeEndDay;
  final stemStart = activeEnd + 1;
  final stemEnd =
      stemStart > p.stemElongationEndDay ? stemStart : p.stemElongationEndDay;
  final budStart = stemEnd + 1;
  final budEnd = budStart > p.budFormationEndDay ? budStart : p.budFormationEndDay;
  final flowerStart = budEnd + 1;
  final flowerEnd =
      flowerStart > p.floweringEndDay ? flowerStart : p.floweringEndDay;
  final postStart = flowerEnd + 1;
  final postEnd = postStart > p.postBloomEndDay ? postStart : p.postBloomEndDay;
  final senStart = postEnd + 1;
  final senEnd = senStart > p.senescenceEndDay ? senStart : p.senescenceEndDay;
  final cycleStart = senEnd + 1;

  switch (id) {
    case SunflowerStageIds.sowing:
      return (startDay: 1, endDay: sowingEnd);
    case SunflowerStageIds.germination:
      return (startDay: germStart, endDay: germEnd);
    case SunflowerStageIds.emergence:
      return (startDay: emergStart, endDay: emergEnd);
    case SunflowerStageIds.earlyVegetativeGrowth:
      return (startDay: earlyStart, endDay: earlyEnd);
    case SunflowerStageIds.activeVegetativeGrowth:
      return (startDay: activeStart, endDay: activeEnd);
    case SunflowerStageIds.stemElongation:
      return (startDay: stemStart, endDay: stemEnd);
    case SunflowerStageIds.budFormation:
      return (startDay: budStart, endDay: budEnd);
    case SunflowerStageIds.flowering:
      return (startDay: flowerStart, endDay: flowerEnd);
    case SunflowerStageIds.postBloom:
      return (startDay: postStart, endDay: postEnd);
    case SunflowerStageIds.senescence:
      return (startDay: senStart, endDay: senEnd);
    default:
      // cycle_complete / unknown: el inicio del cierre.
      return (startDay: cycleStart, endDay: cycleStart);
  }
}

/// Estimación de `sowingDate` a partir de la fecha de TRASPLANTE (Documento A
/// §9.6). El reloj sigue anclado a la SIEMBRA: se resta la edad típica de la
/// plántula del perfil. Es una estimación de onboarding, no una afirmación de
/// edad real.
DateTime estimateSunflowerSowingDateFromTransplant({
  required String? profileId,
  required DateTime transplantDate,
}) {
  final profile = _profileOrSkip(profileId);
  return transplantDate.subtract(
    Duration(days: profile.transplantAgeOffsetDays),
  );
}

/// Estimación de `sowingDate` a partir del ESTADO VISUAL de una planta comprada
/// (Documento A §9.7). Retrocalcula desde el punto medio de la etapa del perfil.
/// Devuelve null cuando el estado es "No estoy seguro" (→ etapa `unknown` y
/// fecha por completar).
DateTime? estimateSunflowerSowingDateFromVisualState({
  required String? profileId,
  required SunflowerVisualState state,
  required DateTime now,
}) {
  if (state == SunflowerVisualState.unsure) return null;
  final profile = _profileOrSkip(profileId);
  final stageId = sunflowerVisualStateToStageId(state);
  final range = sunflowerStageDayRange(profile, stageId);
  final midDay = ((range.startDay + range.endDay) / 2).round();
  final effectiveDay = midDay < 1 ? 1 : midDay;
  // sowingDate = now - (día efectivo - 1): el día 1 es el día de la siembra.
  return now.subtract(Duration(days: effectiveDay - 1));
}

/// True si el perfil permite el evento explícito "Ya corté la flor" que cierra
/// el ciclo (solo corte de tallo único, Documento A §6.4, §13.8). El corte es
/// una TERMINACIÓN ornamental explícita, nunca una cosecha productiva.
bool sunflowerSupportsCutTermination(String? profileId) {
  final canonical =
      resolveCanonicalSunflowerProfileId((profileId ?? '').trim()) ?? kGiSkip;
  return sunflowerProfiles[canonical]?.supportsCutTermination ?? false;
}

SunflowerProfile _profileOrSkip(String? profileId) {
  final canonical =
      resolveCanonicalSunflowerProfileId((profileId ?? '').trim()) ?? kGiSkip;
  return sunflowerProfiles[canonical] ?? sunflowerProfiles[kGiSkip]!;
}
