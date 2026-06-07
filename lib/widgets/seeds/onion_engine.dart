import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/onion_models.dart';

/// Motor fenologico de cebolla (`CropKey.onion`).
///
/// Resuelve las 8 etapas operativas desde siembra/trasplante/set y perfil
/// ON, mas el evento de espigado. La floracion/espigado se mantiene como
/// cierre por perdida de calidad, no como floracion productiva. El organo
/// objetivo es el bulbo (hoja + base en cambray ON-05).
class OnionEngine {
  static const int _germinationEndDay = 7;

  static const String _stageGerm =
      'assets/seeds/Onion/onion_stage_germination.png';
  static const String _stageEstabEarly =
      'assets/seeds/Onion/onion_stage_establishment_early.png';
  static const String _stageEstab =
      'assets/seeds/Onion/onion_stage_establishment.png';
  static const String _stageVegetative =
      'assets/seeds/Onion/onion_stage_vegetative.png';
  static const String _stagePreBulbing =
      'assets/seeds/Onion/onion_stage_pre_bulbing.png';
  static const String _stageBulbInitiation =
      'assets/seeds/Onion/onion_stage_bulb_initiation.png';
  static const String _stageBulbFill =
      'assets/seeds/Onion/onion_stage_bulb_fill.png';
  static const String _stageMaturityHarvest =
      'assets/seeds/Onion/onion_stage_maturity_harvest.png';
  static const String _stageBoltingEvent =
      'assets/seeds/Onion/onion_stage_bolting_event.png';

  static const List<String> availableStageAssets = <String>[
    _stageGerm,
    _stageEstabEarly,
    _stageEstab,
    _stageVegetative,
    _stagePreBulbing,
    _stageBulbInitiation,
    _stageBulbFill,
    _stageMaturityHarvest,
    _stageBoltingEvent,
  ];

  static String heroAssetForStage(OnionStageKey stage) {
    switch (stage) {
      case OnionStageKey.germinacion:
        return _stageGerm;
      case OnionStageKey.emergencia:
        return _stageEstabEarly;
      case OnionStageKey.establecimiento:
        return _stageEstab;
      case OnionStageKey.vegetativo:
        return _stageVegetative;
      case OnionStageKey.induccionBulbificacion:
        return _stagePreBulbing;
      case OnionStageKey.inicioBulbo:
        return _stageBulbInitiation;
      case OnionStageKey.llenadoBulbo:
        return _stageBulbFill;
      case OnionStageKey.maduracionCosecha:
        return _stageMaturityHarvest;
      case OnionStageKey.espigado:
        return _stageBoltingEvent;
    }
  }

  static String labelEs(OnionStageKey stage, OnionProfile profile) {
    switch (stage) {
      case OnionStageKey.germinacion:
        return 'Germinacion';
      case OnionStageKey.emergencia:
        return 'Emergencia / plantula';
      case OnionStageKey.establecimiento:
        return 'Establecimiento';
      case OnionStageKey.vegetativo:
        return profile.isBunching
            ? 'Desarrollo de hoja y base'
            : 'Desarrollo vegetativo foliar';
      case OnionStageKey.induccionBulbificacion:
        return profile.isBunching
            ? 'Pre-cosecha de manojo'
            : 'Induccion a bulbificacion';
      case OnionStageKey.inicioBulbo:
        return profile.isBunching
            ? 'Engrosamiento de base'
            : 'Inicio de bulbo';
      case OnionStageKey.llenadoBulbo:
        return profile.isBunching
            ? 'Llenado de base / cambray'
            : 'Llenado de bulbo';
      case OnionStageKey.maduracionCosecha:
        return profile.isBunching
            ? 'Cosecha de manojo'
            : 'Maduracion / cuello / cosecha';
      case OnionStageKey.espigado:
        return 'Espigado / tallo floral';
    }
  }

  static List<SeedWindowKey> _windows(OnionStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];

    final nutritionActive = stage == OnionStageKey.establecimiento ||
        stage == OnionStageKey.vegetativo ||
        stage == OnionStageKey.induccionBulbificacion ||
        stage == OnionStageKey.inicioBulbo ||
        stage == OnionStageKey.llenadoBulbo;
    if (nutritionActive) {
      windows.add(SeedWindowKey.nutrition);
    }

    // Etapas criticas: induccion (fotoperiodo), llenado (calibre) y
    // maduracion/cosecha (cuello/curado). El espigado es evento de cierre.
    if (stage == OnionStageKey.induccionBulbificacion ||
        stage == OnionStageKey.inicioBulbo ||
        stage == OnionStageKey.llenadoBulbo ||
        stage == OnionStageKey.maduracionCosecha ||
        stage == OnionStageKey.espigado) {
      windows.add(SeedWindowKey.critical);
    }

    return windows;
  }

  static List<OnionStageBounds> _buildBounds(OnionProfile profile) {
    return <OnionStageBounds>[
      OnionStageBounds(
        key: OnionStageKey.germinacion,
        startDay: 1,
        endDay: _germinationEndDay,
      ),
      OnionStageBounds(
        key: OnionStageKey.emergencia,
        startDay: _germinationEndDay + 1,
        endDay: math.max(_germinationEndDay + 2, profile.e2EndDay),
      ),
      OnionStageBounds(
        key: OnionStageKey.establecimiento,
        startDay: math.max(_germinationEndDay + 3, profile.e2EndDay + 1),
        endDay: math.max(profile.e2EndDay + 2, profile.e3EndDay),
      ),
      OnionStageBounds(
        key: OnionStageKey.vegetativo,
        startDay: math.max(profile.e2EndDay + 3, profile.e3EndDay + 1),
        endDay: math.max(profile.e3EndDay + 2, profile.e4EndDay),
      ),
      OnionStageBounds(
        key: OnionStageKey.induccionBulbificacion,
        startDay: math.max(profile.e3EndDay + 3, profile.e4EndDay + 1),
        endDay: math.max(profile.e4EndDay + 2, profile.e5EndDay),
      ),
      OnionStageBounds(
        key: OnionStageKey.inicioBulbo,
        startDay: math.max(profile.e4EndDay + 3, profile.e5EndDay + 1),
        endDay: math.max(profile.e5EndDay + 2, profile.e6EndDay),
      ),
      OnionStageBounds(
        key: OnionStageKey.llenadoBulbo,
        startDay: math.max(profile.e5EndDay + 3, profile.e6EndDay + 1),
        endDay: math.max(profile.e6EndDay + 2, profile.e7EndDay),
      ),
      OnionStageBounds(
        key: OnionStageKey.maduracionCosecha,
        startDay: math.max(profile.e6EndDay + 3, profile.e7EndDay + 1),
        endDay: math.max(profile.e7EndDay + 2, profile.e8EndDay),
      ),
      OnionStageBounds(
        key: OnionStageKey.espigado,
        startDay: math.max(profile.e7EndDay + 3, profile.e8EndDay + 1),
        endDay: math.max(
          profile.e8EndDay + 2,
          profile.e8EndDay + profile.boltingEventDays,
        ),
      ),
    ];
  }

  static OnionStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required OnionProfile profile,
    OnionEstablishmentMode? establishmentMode,
    int stressDelayDays = 0,
    int? debugOverrideDaySinceAnchor,
  }) {
    final mode = establishmentMode ?? profile.defaultEstablishmentMode;
    final rawDay = debugOverrideDaySinceAnchor ??
        (today.difference(sowingDate).inDays + 1);

    // Trasplante/set adelantan el reloj fenologico segun edad de plantula.
    final nurseryOffset = (mode == OnionEstablishmentMode.transplant ||
            mode == OnionEstablishmentMode.set)
        ? profile.nurseryAgeDays
        : 0;
    final effectiveDay = _clampInt(
      rawDay + nurseryOffset + stressDelayDays,
      min: 1,
      max: 999999,
    );

    final bounds = _buildBounds(profile);
    OnionStageBounds current = bounds.first;
    for (final bound in bounds) {
      current = bound;
      if (bound.contains(effectiveDay)) break;
    }

    final denom = (current.endDay - current.startDay).clamp(1, 999999);
    final progress =
        ((effectiveDay - current.startDay) / denom).clamp(0.0, 1.0);

    // En cebolla de bulbo, la "cosecha" es la etapa de maduracion/cuello.
    final harvestStartRaw = math.max(1, profile.e7EndDay + 1 - nurseryOffset);
    final harvestEndRaw =
        math.max(harvestStartRaw, profile.e8EndDay - nurseryOffset);
    final qualityDeclineStartRaw =
        math.max(harvestEndRaw + 1, profile.e8EndDay + 1 - nurseryOffset);
    final qualityDeclineEndRaw = math.max(
      qualityDeclineStartRaw,
      profile.e8EndDay + profile.boltingEventDays - nurseryOffset,
    );

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

    return OnionStageResult(
      profile: profile,
      stage: current.key,
      daySinceAnchor: rawDay,
      establishmentMode: mode,
      harvestBand: RangeInt(harvestStartRaw, harvestEndRaw),
      qualityDeclineBand:
          RangeInt(qualityDeclineStartRaw, qualityDeclineEndRaw),
      expectedHarvestStartDay: harvestStartRaw,
      expectedEndDay: harvestEndRaw,
      expectedDaysToEnd: expectedDaysToEnd,
      daysToHarvestMin: daysToHarvestMin,
      daysToHarvestMax: daysToHarvestMax,
      stageProgressPct: progress,
      windowsNow: _windows(current.key),
      stageLabelEs: labelEs(current.key, profile),
      heroAsset: heroAssetForStage(current.key),
      helperCaption: _helperCaption(current.key, profile),
    );
  }

  static String _helperCaption(OnionStageKey stage, OnionProfile profile) {
    switch (stage) {
      case OnionStageKey.germinacion:
        return 'Manda la cama de siembra: humedad fina y pareja, sin costra, baja salinidad y temperatura adecuada. La comida aun no es la prioridad.';
      case OnionStageKey.emergencia:
        return 'Plantula joven de "latigo" muy sensible a costra, encharque, sales y maleza. Cuide stand uniforme antes de empujar nitrogeno.';
      case OnionStageKey.establecimiento:
        return 'Raiz superficial en formacion. P de arranque y humedad estable pesan mas que el N; evite sales cerca de la raiz joven.';
      case OnionStageKey.vegetativo:
        return profile.isBunching
            ? 'La hoja y base tierna son el producto en cambray. N moderado y agua pareja; cuide trips, minador y pudricion de base.'
            : 'La hoja es la fabrica del bulbo. N suficiente pero controlado; demasiado N tarde engruesa cuello y retrasa madurez.';
      case OnionStageKey.induccionBulbificacion:
        return profile.isBunching
            ? 'Acercandose a cosecha de manojo. Priorice hoja limpia y turgente; no busque bulbo seco completo.'
            : 'Etapa critica: el fotoperiodo manda. Si el dia no corresponde al tipo, mas fertilizante no hace bulbo. Mantenga agua estable.';
      case OnionStageKey.inicioBulbo:
        return profile.isBunching
            ? 'Base engrosando. Cosecha joven; vigile calor y exceso de humedad que ablandan el manojo.'
            : 'El bulbo empieza a definirse. Baje intensidad de N, mantenga agua pareja y vigile CE: el calibre se juega aqui.';
      case OnionStageKey.llenadoBulbo:
        return profile.isBunching
            ? 'Ultima ventana de manojo tierno. Coseche oportuno: el calor y la fibra bajan calidad comercial.'
            : 'Ventana de calibre: K, agua estable y salinidad controlada definen el bulbo. El deficit no siempre se ve como marchitez.';
      case OnionStageKey.maduracionCosecha:
        return profile.isBunching
            ? 'Coseche el manojo en su punto. Evite calor, golpe y deshidratacion de hoja.'
            : 'Cierre de ciclo: cuello cae y seca. No empuje N ni riego tardio; proteja maduracion, curado y evite pudriciones de cuello.';
      case OnionStageKey.espigado:
        return 'El espigado no es etapa productiva: es perdida de calidad. Decida cosecha/cierre y registre la causa (frio, edad, variedad, estres) para el siguiente ciclo.';
    }
  }

  static int _clampInt(int value, {required int min, required int max}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
