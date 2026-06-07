import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/garlic_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

/// Motor fenologico de ajo (`CropKey.garlic`).
///
/// Resuelve etapas desde plantacion del diente. La vernalizacion se modela
/// como ventana critica de diferenciacion; no como algo que NPK pueda rescatar.
class GarlicEngine {
  static const int _plantingEndDay = 10;

  // Assets fenologicos reales en assets/seeds/Garlic/ (declarados en pubspec).
  // No existe asset propio de "plantacion del diente": se reutiliza el de
  // germinacion. Cosecha y curado/reposo comparten el asset harvest_curing.
  static const String _stageClovePlanting =
      'assets/seeds/Garlic/garlic_stage_germination.png';
  static const String _stageEmergence =
      'assets/seeds/Garlic/garlic_stage_emergence_establishment.png';
  static const String _stageVegetative =
      'assets/seeds/Garlic/garlic_stage_vegetative_leaf_growth.png';
  static const String _stageVernalization =
      'assets/seeds/Garlic/garlic_stage_vernalization_window.png';
  static const String _stageBulbDifferentiation =
      'assets/seeds/Garlic/garlic_stage_clove_differentiation.png';
  static const String _stageBulbFilling =
      'assets/seeds/Garlic/garlic_stage_bulb_filling.png';
  static const String _stageMaturation =
      'assets/seeds/Garlic/garlic_stage_maturation_drydown.png';
  static const String _stageHarvest =
      'assets/seeds/Garlic/garlic_stage_harvest_curing.png';
  static const String _stageCuring =
      'assets/seeds/Garlic/garlic_stage_harvest_curing.png';
  static const String _stageBrooming =
      'assets/seeds/Garlic/garlic_stage_scape_bolting.png';

  static const List<String> availableStageAssets = <String>[
    _stageClovePlanting,
    _stageEmergence,
    _stageVegetative,
    _stageVernalization,
    _stageBulbDifferentiation,
    _stageBulbFilling,
    _stageMaturation,
    _stageHarvest,
    _stageCuring,
    _stageBrooming,
  ];

  static String heroAssetForStage(GarlicStageKey stage) {
    switch (stage) {
      case GarlicStageKey.clovePlanting:
        return _stageClovePlanting;
      case GarlicStageKey.emergenceEstablishment:
        return _stageEmergence;
      case GarlicStageKey.vegetativeLeafDevelopment:
        return _stageVegetative;
      case GarlicStageKey.coldInductionVernalization:
        return _stageVernalization;
      case GarlicStageKey.bulbDifferentiation:
        return _stageBulbDifferentiation;
      case GarlicStageKey.bulbFilling:
        return _stageBulbFilling;
      case GarlicStageKey.bulbMaturation:
        return _stageMaturation;
      case GarlicStageKey.harvest:
        return _stageHarvest;
      case GarlicStageKey.curingRest:
        return _stageCuring;
      case GarlicStageKey.scapeBrooming:
        return _stageBrooming;
    }
  }

  static String labelEs(GarlicStageKey stage) {
    switch (stage) {
      case GarlicStageKey.clovePlanting:
        return 'Plantacion del diente';
      case GarlicStageKey.emergenceEstablishment:
        return 'Emergencia / establecimiento';
      case GarlicStageKey.vegetativeLeafDevelopment:
        return 'Desarrollo vegetativo foliar';
      case GarlicStageKey.coldInductionVernalization:
        return 'Frio fisiologico / vernalizacion';
      case GarlicStageKey.bulbDifferentiation:
        return 'Diferenciacion de bulbo y dientes';
      case GarlicStageKey.bulbFilling:
        return 'Llenado de bulbo';
      case GarlicStageKey.bulbMaturation:
        return 'Maduracion';
      case GarlicStageKey.harvest:
        return 'Cosecha';
      case GarlicStageKey.curingRest:
        return 'Curado / reposo';
      case GarlicStageKey.scapeBrooming:
        return 'Escapo / canuto / escobeteado';
    }
  }

  static List<SeedWindowKey> _windows(GarlicStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];

    final nutritionActive =
        stage == GarlicStageKey.emergenceEstablishment ||
            stage == GarlicStageKey.vegetativeLeafDevelopment ||
            stage == GarlicStageKey.coldInductionVernalization ||
            stage == GarlicStageKey.bulbDifferentiation ||
            stage == GarlicStageKey.bulbFilling;
    if (nutritionActive) {
      windows.add(SeedWindowKey.nutrition);
    }

    if (stage == GarlicStageKey.coldInductionVernalization ||
        stage == GarlicStageKey.bulbDifferentiation ||
        stage == GarlicStageKey.bulbFilling ||
        stage == GarlicStageKey.bulbMaturation ||
        stage == GarlicStageKey.harvest ||
        stage == GarlicStageKey.curingRest ||
        stage == GarlicStageKey.scapeBrooming) {
      windows.add(SeedWindowKey.critical);
    }

    return windows;
  }

  static List<GarlicStageBounds> _buildBounds(GarlicProfile profile) {
    return <GarlicStageBounds>[
      GarlicStageBounds(
        key: GarlicStageKey.clovePlanting,
        startDay: 1,
        endDay: _plantingEndDay,
      ),
      GarlicStageBounds(
        key: GarlicStageKey.emergenceEstablishment,
        startDay: _plantingEndDay + 1,
        endDay: math.max(_plantingEndDay + 2, profile.e2EndDay),
      ),
      GarlicStageBounds(
        key: GarlicStageKey.vegetativeLeafDevelopment,
        startDay: math.max(_plantingEndDay + 3, profile.e2EndDay + 1),
        endDay: math.max(profile.e2EndDay + 2, profile.e3EndDay),
      ),
      GarlicStageBounds(
        key: GarlicStageKey.coldInductionVernalization,
        startDay: math.max(profile.e2EndDay + 3, profile.e3EndDay + 1),
        endDay: math.max(profile.e3EndDay + 2, profile.e4EndDay),
      ),
      GarlicStageBounds(
        key: GarlicStageKey.bulbDifferentiation,
        startDay: math.max(profile.e3EndDay + 3, profile.e4EndDay + 1),
        endDay: math.max(profile.e4EndDay + 2, profile.e5EndDay),
      ),
      GarlicStageBounds(
        key: GarlicStageKey.bulbFilling,
        startDay: math.max(profile.e4EndDay + 3, profile.e5EndDay + 1),
        endDay: math.max(profile.e5EndDay + 2, profile.e6EndDay),
      ),
      GarlicStageBounds(
        key: GarlicStageKey.bulbMaturation,
        startDay: math.max(profile.e5EndDay + 3, profile.e6EndDay + 1),
        endDay: math.max(profile.e6EndDay + 2, profile.e7EndDay),
      ),
      GarlicStageBounds(
        key: GarlicStageKey.harvest,
        startDay: math.max(profile.e6EndDay + 3, profile.e7EndDay + 1),
        endDay: math.max(profile.e7EndDay + 2, profile.e8EndDay),
      ),
      GarlicStageBounds(
        key: GarlicStageKey.curingRest,
        startDay: math.max(profile.e7EndDay + 3, profile.e8EndDay + 1),
        endDay: math.max(profile.e8EndDay + 2, profile.e9EndDay),
      ),
      GarlicStageBounds(
        key: GarlicStageKey.scapeBrooming,
        startDay: math.max(profile.e8EndDay + 3, profile.e9EndDay + 1),
        endDay: math.max(
          profile.e9EndDay + 2,
          profile.e9EndDay + profile.scapeEventDays,
        ),
      ),
    ];
  }

  static GarlicStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required GarlicProfile profile,
    GarlicEstablishmentMode? establishmentMode,
    int stressDelayDays = 0,
    int? debugOverrideDaySinceAnchor,
  }) {
    final mode = establishmentMode ?? profile.defaultEstablishmentMode;
    final rawDay = debugOverrideDaySinceAnchor ??
        (today.difference(sowingDate).inDays + 1);
    final sproutOffset =
        mode == GarlicEstablishmentMode.sproutedClove ? 7 : 0;
    final effectiveDay = _clampInt(
      rawDay + sproutOffset + stressDelayDays,
      min: 1,
      max: 999999,
    );

    final bounds = _buildBounds(profile);
    GarlicStageBounds current = bounds.first;
    for (final bound in bounds) {
      current = bound;
      if (bound.contains(effectiveDay)) break;
    }

    final denom = (current.endDay - current.startDay).clamp(1, 999999);
    final progress =
        ((effectiveDay - current.startDay) / denom).clamp(0.0, 1.0);

    final harvestStart = math.max(1, profile.e7EndDay + 1 - sproutOffset);
    final harvestEnd = math.max(harvestStart, profile.e8EndDay - sproutOffset);
    final curingStart = math.max(harvestEnd + 1, profile.e8EndDay + 1);
    final curingEnd = math.max(curingStart, profile.e9EndDay);

    final daysToHarvestMin = _clampInt(
      (profile.e7EndDay + 1) - effectiveDay,
      min: 0,
      max: 999999,
    );
    final daysToHarvestMax = _clampInt(
      profile.e8EndDay - effectiveDay,
      min: 0,
      max: 999999,
    );
    final expectedDaysToEnd = _clampInt(
      profile.e8EndDay - effectiveDay,
      min: 0,
      max: 999999,
    );

    return GarlicStageResult(
      profile: profile,
      stage: current.key,
      daySinceAnchor: rawDay,
      establishmentMode: mode,
      harvestBand: RangeInt(harvestStart, harvestEnd),
      curingBand: RangeInt(curingStart, curingEnd),
      expectedHarvestStartDay: harvestStart,
      expectedEndDay: harvestEnd,
      expectedDaysToEnd: expectedDaysToEnd,
      daysToHarvestMin: daysToHarvestMin,
      daysToHarvestMax: daysToHarvestMax,
      stageProgressPct: progress,
      windowsNow: _windows(current.key),
      stageLabelEs: labelEs(current.key),
      heroAsset: heroAssetForStage(current.key),
      helperCaption: _helperCaption(current.key, profile),
    );
  }

  static String _helperCaption(GarlicStageKey stage, GarlicProfile profile) {
    switch (stage) {
      case GarlicStageKey.clovePlanting:
        return 'El diente-semilla manda el arranque: revisa sanidad, calibre, profundidad, humedad pareja y baja salinidad antes de pensar en N.';
      case GarlicStageKey.emergenceEstablishment:
        return 'Raiz y stand en formacion. P de arranque y humedad estable pesan mas que empujar nitrogeno en planta joven.';
      case GarlicStageKey.vegetativeLeafDevelopment:
        return 'La hoja construye la fabrica del bulbo. N temprano ayuda, pero el exceso deja tejido blando y complica la maduracion.';
      case GarlicStageKey.coldInductionVernalization:
        return 'Ventana critica: el frio fisiologico define la diferenciacion. Fertilizante no corrige una vernalizacion mala.';
      case GarlicStageKey.bulbDifferentiation:
        return 'Empiezan a definirse bulbo y dientes. Baja intensidad de N, cuida agua estable, CE y K si el suelo lo permite.';
      case GarlicStageKey.bulbFilling:
        return 'Ventana de calibre y firmeza. K y agua pareja ayudan, pero salinidad o anoxia pueden parecer falta de nutriente.';
      case GarlicStageKey.bulbMaturation:
        return 'Cierre de bulbo. Deten N fuerte y riegos tardios: maduracion y curado pesan mas que seguir verde.';
      case GarlicStageKey.harvest:
        return 'Cosecha comercial: calibre, descarte, sanidad y madurez real importan mas que biomasa total.';
      case GarlicStageKey.curingRest:
        return 'Curado y reposo definen almacenamiento. Evita golpes, asoleado, cuello humedo y mezcla de bulbos enfermos.';
      case GarlicStageKey.scapeBrooming:
        return 'Escapo, canuto o escobeteado es evento de riesgo. Registra frio, variedad, N tardio y estres; no lo trates como falta de NPK.';
    }
  }

  static int _clampInt(int value, {required int min, required int max}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
