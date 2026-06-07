import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/spinach_models.dart';

/// Motor fenologico de espinaca (`CropKey.spinach`).
///
/// Resuelve las 8 etapas operativas desde siembra/trasplante y perfil
/// SP. El espigado se mantiene como etapa de cierre por perdida de
/// calidad, no como floracion productiva.
class SpinachEngine {
  static const int _germinationEndDay = 7;

  static const String _stageGerm =
      'assets/seeds/spinach/spinach_stage_germination.png';
  static const String _stageEstab =
      'assets/seeds/spinach/spinach_stage_establishment.png';
  static const String _stageVegEarly =
      'assets/seeds/spinach/spinach_stage_vegetative_early.png';
  static const String _stageLeafExpansion =
      'assets/seeds/spinach/spinach_stage_leaf_expansion.png';
  static const String _stageCommercial =
      'assets/seeds/spinach/spinach_stage_commercial_maturity.png';
  static const String _stageHarvest =
      'assets/seeds/spinach/spinach_stage_harvest_window.png';
  static const String _stageQualityDecline =
      'assets/seeds/spinach/spinach_stage_quality_decline.png';
  static const String _stageBolting =
      'assets/seeds/spinach/spinach_stage_bolting_senescence.png';

  static const List<String> availableStageAssets = <String>[
    _stageGerm,
    _stageEstab,
    _stageVegEarly,
    _stageLeafExpansion,
    _stageCommercial,
    _stageHarvest,
    _stageQualityDecline,
    _stageBolting,
  ];

  static String heroAssetForStage(SpinachStageKey stage) {
    switch (stage) {
      case SpinachStageKey.germinacion:
        return _stageGerm;
      case SpinachStageKey.establecimiento:
        return _stageEstab;
      case SpinachStageKey.vegetativoTemprano:
        return _stageVegEarly;
      case SpinachStageKey.expansionFoliar:
        return _stageLeafExpansion;
      case SpinachStageKey.madurezComercial:
        return _stageCommercial;
      case SpinachStageKey.ventanaCosecha:
        return _stageHarvest;
      case SpinachStageKey.perdidaCalidad:
        return _stageQualityDecline;
      case SpinachStageKey.espigadoSenescencia:
        return _stageBolting;
    }
  }

  static String labelEs(SpinachStageKey stage, SpinachProfile profile) {
    switch (stage) {
      case SpinachStageKey.germinacion:
        return 'Germinacion';
      case SpinachStageKey.establecimiento:
        return 'Emergencia / establecimiento';
      case SpinachStageKey.vegetativoTemprano:
        return 'Vegetativo temprano';
      case SpinachStageKey.expansionFoliar:
        return 'Expansion foliar activa';
      case SpinachStageKey.madurezComercial:
        return profile.isBabyLeaf
            ? 'Madurez comercial baby leaf'
            : 'Madurez comercial de hoja';
      case SpinachStageKey.ventanaCosecha:
        return profile.regrowthPotential01 >= 0.55
            ? 'Ventana de cosecha / cortes'
            : 'Ventana de cosecha';
      case SpinachStageKey.perdidaCalidad:
        return 'Sobremadurez / perdida de calidad';
      case SpinachStageKey.espigadoSenescencia:
        return 'Espigado / senescencia';
    }
  }

  static List<SeedWindowKey> _windows(SpinachStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];

    final nutritionActive =
        stage == SpinachStageKey.establecimiento ||
            stage == SpinachStageKey.vegetativoTemprano ||
            stage == SpinachStageKey.expansionFoliar ||
            stage == SpinachStageKey.madurezComercial ||
            stage == SpinachStageKey.ventanaCosecha;
    if (nutritionActive) {
      windows.add(SeedWindowKey.nutrition);
    }

    if (stage == SpinachStageKey.expansionFoliar ||
        stage == SpinachStageKey.madurezComercial ||
        stage == SpinachStageKey.ventanaCosecha ||
        stage == SpinachStageKey.espigadoSenescencia) {
      windows.add(SeedWindowKey.critical);
    }

    return windows;
  }

  static List<SpinachStageBounds> _buildBounds(SpinachProfile profile) {
    return <SpinachStageBounds>[
      SpinachStageBounds(
        key: SpinachStageKey.germinacion,
        startDay: 1,
        endDay: _germinationEndDay,
      ),
      SpinachStageBounds(
        key: SpinachStageKey.establecimiento,
        startDay: _germinationEndDay + 1,
        endDay: math.max(_germinationEndDay + 2, profile.e2EndDay),
      ),
      SpinachStageBounds(
        key: SpinachStageKey.vegetativoTemprano,
        startDay: math.max(_germinationEndDay + 3, profile.e2EndDay + 1),
        endDay: math.max(profile.e2EndDay + 2, profile.e3EndDay),
      ),
      SpinachStageBounds(
        key: SpinachStageKey.expansionFoliar,
        startDay: math.max(profile.e2EndDay + 3, profile.e3EndDay + 1),
        endDay: math.max(profile.e3EndDay + 2, profile.e4EndDay),
      ),
      SpinachStageBounds(
        key: SpinachStageKey.madurezComercial,
        startDay: math.max(profile.e3EndDay + 3, profile.e4EndDay + 1),
        endDay: math.max(profile.e4EndDay + 2, profile.e5EndDay),
      ),
      SpinachStageBounds(
        key: SpinachStageKey.ventanaCosecha,
        startDay: math.max(profile.e4EndDay + 3, profile.e5EndDay + 1),
        endDay: math.max(profile.e5EndDay + 2, profile.e6EndDay),
      ),
      SpinachStageBounds(
        key: SpinachStageKey.perdidaCalidad,
        startDay: math.max(profile.e5EndDay + 3, profile.e6EndDay + 1),
        endDay: math.max(profile.e6EndDay + 2, profile.e7EndDay),
      ),
      SpinachStageBounds(
        key: SpinachStageKey.espigadoSenescencia,
        startDay: math.max(profile.e6EndDay + 3, profile.e7EndDay + 1),
        endDay: math.max(
          profile.e7EndDay + 2,
          profile.e7EndDay + profile.boltingSenescenceDays,
        ),
      ),
    ];
  }

  static SpinachStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required SpinachProfile profile,
    SpinachEstablishmentMode? establishmentMode,
    int stressDelayDays = 0,
    int? debugOverrideDaySinceAnchor,
  }) {
    final mode = establishmentMode ?? profile.defaultEstablishmentMode;
    final rawDay = debugOverrideDaySinceAnchor ??
        (today.difference(sowingDate).inDays + 1);

    final nurseryOffset = mode == SpinachEstablishmentMode.transplant
        ? profile.nurseryAgeDays
        : 0;
    final effectiveDay = _clampInt(
      rawDay + nurseryOffset + stressDelayDays,
      min: 1,
      max: 999999,
    );

    final bounds = _buildBounds(profile);
    SpinachStageBounds current = bounds.first;
    for (final bound in bounds) {
      current = bound;
      if (bound.contains(effectiveDay)) break;
    }

    final denom = (current.endDay - current.startDay).clamp(1, 999999);
    final progress =
        ((effectiveDay - current.startDay) / denom).clamp(0.0, 1.0);

    final harvestStartRaw = math.max(1, profile.e5EndDay + 1 - nurseryOffset);
    final harvestEndRaw =
        math.max(harvestStartRaw, profile.e6EndDay - nurseryOffset);
    final qualityDeclineStartRaw =
        math.max(harvestEndRaw + 1, profile.e6EndDay + 1 - nurseryOffset);
    final qualityDeclineEndRaw =
        math.max(qualityDeclineStartRaw, profile.e7EndDay - nurseryOffset);

    final daysToHarvestMin = _clampInt(
      (profile.e5EndDay + 1) - effectiveDay,
      min: 0,
      max: 999999,
    );
    final daysToHarvestMax = _clampInt(
      profile.e6EndDay - effectiveDay,
      min: 0,
      max: 999999,
    );
    final expectedDaysToEnd = _clampInt(
      profile.e6EndDay - effectiveDay,
      min: 0,
      max: 999999,
    );

    return SpinachStageResult(
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

  static String _helperCaption(SpinachStageKey stage, SpinachProfile profile) {
    switch (stage) {
      case SpinachStageKey.germinacion:
        return 'Mantenga humedad estable y suelo fresco. Suelo caliente puede frenar la emergencia y dejar nacencia dispareja.';
      case SpinachStageKey.establecimiento:
        return 'Raiz joven y cuello son sensibles a saturacion. Antes de fertilizar, confirme humedad pareja y buen drenaje.';
      case SpinachStageKey.vegetativoTemprano:
        return 'La planta arma roseta y raiz. N moderado, P temprano y riego estable pesan mas que empujar crecimiento rapido.';
      case SpinachStageKey.expansionFoliar:
        return 'Etapa de mayor expansion de hoja. Agua, temperatura y balance N/K controlado definen turgencia y calidad comercial.';
      case SpinachStageKey.madurezComercial:
        if (profile.isBabyLeaf) {
          return 'Baby leaf llega rapido a punto. Evite N tardio, CE alta y calor para cuidar color, textura y vida de anaquel.';
        }
        return 'La hoja llega a tamano comercial. Revise manchas, minador, pulgones y calor antes de atrasar el corte.';
      case SpinachStageKey.ventanaCosecha:
        return 'Punto de cosecha: priorice turgencia, hoja limpia y corte oportuno. Si aparece tallo floral, la calidad cae.';
      case SpinachStageKey.perdidaCalidad:
        return 'La espinaca empieza a perder valor: amarillamiento, hoja dura o manchas. Coseche pronto o documente causa.';
      case SpinachStageKey.espigadoSenescencia:
        return 'Espigado no es fase productiva. Coseche de inmediato si aun sirve, cierre ciclo y registre calor, edad o estres.';
    }
  }

  static int _clampInt(int value, {required int min, required int max}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
