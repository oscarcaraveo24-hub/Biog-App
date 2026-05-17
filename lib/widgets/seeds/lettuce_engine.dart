import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/lettuce_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

/// Motor fenológico de lechuga (`CropKey.lettuce`).
///
/// Resuelve la etapa BIO-G E1..E6 a partir de la fecha de día 0
/// (siembra directa o trasplante), el modo de establecimiento, el perfil
/// LE-XX y un retraso opcional por estrés acumulado.
///
/// En trasplante el día 0 es la fecha de trasplante; el motor suma
/// `profile.nurseryAgeDays` para no tratar la planta como germinación
/// desde cero (Perfil Universal §4). El espigado NO se modela aquí: es
/// un evento de falla que resuelve `LettuceAgroScoreEngine`.
class LettuceEngine {
  static const int _germinationEndDay = 7;

  // Assets de etapa. Carpeta `assets/seeds/lettuce/`; si el PNG aún no
  // existe, la UI cae al ícono de respaldo (errorBuilder).
  static const String _stageGerm =
      'assets/seeds/lettuce/lettuce_stage_germination.png';
  static const String _stageEstab =
      'assets/seeds/lettuce/lettuce_stage_establishment.png';
  static const String _stageVeg =
      'assets/seeds/lettuce/lettuce_stage_vegetative.png';
  static const String _stageHead =
      'assets/seeds/lettuce/lettuce_stage_head_formation.png';
  static const String _stageHarvest =
      'assets/seeds/lettuce/lettuce_stage_harvest_window.png';
  static const String _stageSenescence =
      'assets/seeds/lettuce/lettuce_stage_senescence.png';

  static const List<String> availableStageAssets = <String>[
    _stageGerm,
    _stageEstab,
    _stageVeg,
    _stageHead,
    _stageHarvest,
    _stageSenescence,
  ];

  /// Asset visible para una etapa fenológica de lechuga.
  static String heroAssetForStage(LettuceStageKey stage) {
    switch (stage) {
      case LettuceStageKey.germinacion:
        return _stageGerm;
      case LettuceStageKey.establecimiento:
        return _stageEstab;
      case LettuceStageKey.desarrolloVegetativo:
        return _stageVeg;
      case LettuceStageKey.formacionCabeza:
        return _stageHead;
      case LettuceStageKey.ventanaCosecha:
        return _stageHarvest;
      case LettuceStageKey.sobremadurez:
        return _stageSenescence;
    }
  }

  /// Label en español, sensible al perfil: LE-05 (hoja suelta) no forma
  /// cabeza, así que E4 se nombra como madurez comercial de hoja.
  static String labelEs(LettuceStageKey stage, LettuceProfile profile) {
    switch (stage) {
      case LettuceStageKey.germinacion:
        return 'Germinación';
      case LettuceStageKey.establecimiento:
        return 'Emergencia / establecimiento';
      case LettuceStageKey.desarrolloVegetativo:
        return 'Desarrollo vegetativo';
      case LettuceStageKey.formacionCabeza:
        return profile.formsHead
            ? 'Formación de cabeza'
            : 'Madurez comercial de hoja';
      case LettuceStageKey.ventanaCosecha:
        return 'Ventana de cosecha';
      case LettuceStageKey.sobremadurez:
        return 'Sobre-madurez / senescencia';
    }
  }

  static List<SeedWindowKey> _windows(LettuceStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];

    final nutritionActive = stage == LettuceStageKey.establecimiento ||
        stage == LettuceStageKey.desarrolloVegetativo ||
        stage == LettuceStageKey.formacionCabeza ||
        stage == LettuceStageKey.ventanaCosecha;
    if (nutritionActive) {
      windows.add(SeedWindowKey.nutrition);
    }

    // Ventana de calidad: formación de cabeza y cosecha deciden el valor
    // comercial; el espigado es riesgo crítico en ambas (Perfil §8).
    if (stage == LettuceStageKey.formacionCabeza ||
        stage == LettuceStageKey.ventanaCosecha) {
      windows.add(SeedWindowKey.critical);
    }

    return windows;
  }

  static List<LettuceStageBounds> _buildBounds(LettuceProfile profile) {
    return <LettuceStageBounds>[
      LettuceStageBounds(
        key: LettuceStageKey.germinacion,
        startDay: 1,
        endDay: _germinationEndDay,
      ),
      LettuceStageBounds(
        key: LettuceStageKey.establecimiento,
        startDay: _germinationEndDay + 1,
        endDay: math.max(_germinationEndDay + 2, profile.e2EndDay),
      ),
      LettuceStageBounds(
        key: LettuceStageKey.desarrolloVegetativo,
        startDay: math.max(_germinationEndDay + 3, profile.e2EndDay + 1),
        endDay: math.max(profile.e2EndDay + 2, profile.e3EndDay),
      ),
      LettuceStageBounds(
        key: LettuceStageKey.formacionCabeza,
        startDay: math.max(profile.e2EndDay + 3, profile.e3EndDay + 1),
        endDay: math.max(profile.e3EndDay + 2, profile.e4EndDay),
      ),
      LettuceStageBounds(
        key: LettuceStageKey.ventanaCosecha,
        startDay: math.max(profile.e3EndDay + 3, profile.e4EndDay + 1),
        endDay: math.max(profile.e4EndDay + 2, profile.e5EndDay),
      ),
      LettuceStageBounds(
        key: LettuceStageKey.sobremadurez,
        startDay: math.max(profile.e4EndDay + 3, profile.e5EndDay + 1),
        endDay: math.max(
          profile.e5EndDay + 2,
          profile.e5EndDay + profile.overMatureDays,
        ),
      ),
    ];
  }

  static LettuceStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required LettuceProfile profile,
    LettuceEstablishmentMode? establishmentMode,
    int stressDelayDays = 0,
    int? debugOverrideDaySinceAnchor,
  }) {
    final mode = establishmentMode ?? profile.defaultEstablishmentMode;

    final rawDay = debugOverrideDaySinceAnchor ??
        (today.difference(sowingDate).inDays + 1);

    // En trasplante el día 0 es el trasplante: la plántula ya trae edad
    // de almácigo. Sumarla evita tratar el cultivo como germinación.
    final nurseryOffset = mode == LettuceEstablishmentMode.transplant
        ? profile.nurseryAgeDays
        : 0;

    final effectiveDay = _clampInt(
      rawDay + nurseryOffset + stressDelayDays,
      min: 1,
      max: 999999,
    );

    final bounds = _buildBounds(profile);
    LettuceStageBounds current = bounds.first;
    for (final bound in bounds) {
      current = bound;
      if (bound.contains(effectiveDay)) break;
    }

    final denom = (current.endDay - current.startDay).clamp(1, 999999);
    final progress =
        ((effectiveDay - current.startDay) / denom).clamp(0.0, 1.0);

    // Bandas reportadas al usuario en espacio de día 0 (rawDay): se
    // restituye el offset de almácigo para que "faltan X días" sea real.
    final harvestStartRaw = math.max(1, profile.e4EndDay + 1 - nurseryOffset);
    final harvestEndRaw = math.max(harvestStartRaw, profile.e5EndDay - nurseryOffset);
    final overMatureStartRaw = math.max(harvestEndRaw + 1, profile.e5EndDay + 1 - nurseryOffset);
    final overMatureEndRaw = math.max(
      overMatureStartRaw,
      profile.e5EndDay + profile.overMatureDays - nurseryOffset,
    );

    final daysToHarvestMin = _clampInt(
      (profile.e4EndDay + 1) - effectiveDay,
      min: 0,
      max: 999999,
    );
    final daysToHarvestMax = _clampInt(
      profile.e5EndDay - effectiveDay,
      min: 0,
      max: 999999,
    );
    final expectedDaysToEnd = _clampInt(
      profile.e5EndDay - effectiveDay,
      min: 0,
      max: 999999,
    );

    return LettuceStageResult(
      profile: profile,
      stage: current.key,
      daySinceAnchor: rawDay,
      establishmentMode: mode,
      harvestBand: RangeInt(harvestStartRaw, harvestEndRaw),
      overMatureBand: RangeInt(overMatureStartRaw, overMatureEndRaw),
      expectedHarvestStartDay: harvestStartRaw,
      expectedEndDay: harvestEndRaw,
      expectedDaysToEnd: expectedDaysToEnd,
      daysToHarvestMin: daysToHarvestMin,
      daysToHarvestMax: daysToHarvestMax,
      stageProgressPct: progress,
      windowsNow: _windows(current.key),
      stageLabelEs: labelEs(current.key, profile),
      heroAsset: !profile.formsHead &&
              heroAssetForStage(current.key) ==
                  'assets/seeds/lettuce/lettuce_stage_head_formation.png'
          ? 'assets/seeds/lettuce/lettuce_stage_vegetative.png'
          : heroAssetForStage(current.key),
      helperCaption: _helperCaption(current.key, profile),
    );
  }

  /// Caption agrónomo-amigable por etapa y perfil. Lenguaje de hortaliza
  /// de hoja: turgencia, calidad y cosecha oportuna, nunca lenguaje de
  /// fruto ni de grano.
  static String _helperCaption(LettuceStageKey stage, LettuceProfile profile) {
    final isLoose = !profile.formsHead;
    switch (stage) {
      case LettuceStageKey.germinacion:
        return 'Mantén el suelo fresco y húmedo parejo. Arriba de 26-28 °C la lechuga germina mal por termoinhibición.';
      case LettuceStageKey.establecimiento:
        return 'Cuida raíz superficial, drenaje y costra. La chupadera (damping-off) se favorece con exceso de agua y poca ventilación.';
      case LettuceStageKey.desarrolloVegetativo:
        return 'Expansión de hojas: agua estable y nitrógeno suficiente sin excederse. El exceso de N ablanda la hoja y abre la puerta a hongos.';
      case LettuceStageKey.formacionCabeza:
        if (isLoose) {
          return 'Madurez de roseta: la hoja llega a tamaño comercial. Vigila calor, tip burn y espigado; el K apoya turgencia.';
        }
        return 'Compactación de cabeza: ventana de calidad. Calor sostenido y estrés pueden adelantar el espigado y dar amargor.';
      case LettuceStageKey.ventanaCosecha:
        return 'Punto máximo de calidad: turgencia, color y firmeza. Revisa el campo y cosecha en ventana; el calor la acorta.';
      case LettuceStageKey.sobremadurez:
        return 'La lechuga pasó su punto: hoja dura, sabor intenso y riesgo de espigado. Cosecha o cierra el ciclo cuanto antes.';
    }
  }

  static int _clampInt(int value, {required int min, required int max}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
