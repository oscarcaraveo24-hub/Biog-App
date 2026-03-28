import 'package:bio_g/widgets/seeds/bean_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class BeanEngine {
  static String heroAssetForStage(BeanStageKey stage) {
    switch (stage) {
      case BeanStageKey.germination:
        return 'assets/seeds/bean/bean_stage_germination.png';
      case BeanStageKey.emergence:
        return 'assets/seeds/bean/bean_stage_emergence.png';
      case BeanStageKey.vegEarly:
        return 'assets/seeds/bean/bean_stage_veg_early.png';
      case BeanStageKey.vegAdvanced:
        return 'assets/seeds/bean/bean_stage_veg_mid.png';
      case BeanStageKey.flowering:
      case BeanStageKey.podSet:
        return 'assets/seeds/bean/bean_stage_flower_set.png';
      case BeanStageKey.grainFill:
      case BeanStageKey.physiologicalMaturity:
        return 'assets/seeds/bean/bean_stage_maturity_senescence.png';
      case BeanStageKey.harvest:
        return 'assets/seeds/bean/bean_stage_harvest.png';
    }
  }

  static String labelEs(BeanStageKey stage) {
    switch (stage) {
      case BeanStageKey.germination:
        return 'Germinación';
      case BeanStageKey.emergence:
        return 'Emergencia';
      case BeanStageKey.vegEarly:
        return 'Vegetativa temprana';
      case BeanStageKey.vegAdvanced:
        return 'Pre-floración';
      case BeanStageKey.flowering:
        return 'Floración';
      case BeanStageKey.podSet:
        return 'Amarre de vaina';
      case BeanStageKey.grainFill:
        return 'Llenado de grano';
      case BeanStageKey.physiologicalMaturity:
        return 'Maduración fisiológica';
      case BeanStageKey.harvest:
        return 'Cosecha';
    }
  }

  static RangeDouble _heightPct(BeanStageKey stage) {
    switch (stage) {
      case BeanStageKey.germination:
        return const RangeDouble(0.00, 0.02);
      case BeanStageKey.emergence:
        return const RangeDouble(0.02, 0.06);
      case BeanStageKey.vegEarly:
        return const RangeDouble(0.08, 0.28);
      case BeanStageKey.vegAdvanced:
        return const RangeDouble(0.28, 0.65);
      case BeanStageKey.flowering:
        return const RangeDouble(0.60, 0.80);
      case BeanStageKey.podSet:
        return const RangeDouble(0.75, 0.90);
      case BeanStageKey.grainFill:
        return const RangeDouble(0.85, 1.00);
      case BeanStageKey.physiologicalMaturity:
        return const RangeDouble(0.90, 1.00);
      case BeanStageKey.harvest:
        return const RangeDouble(0.90, 1.00);
    }
  }

  static List<SeedWindowKey> _windows(BeanStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];

    final nutritionHeavy =
        stage == BeanStageKey.vegEarly ||
        stage == BeanStageKey.vegAdvanced ||
        stage == BeanStageKey.flowering ||
        stage == BeanStageKey.podSet ||
        stage == BeanStageKey.grainFill;

    if (nutritionHeavy) {
      windows.add(SeedWindowKey.nutrition);
    }

    if (stage == BeanStageKey.flowering || stage == BeanStageKey.podSet) {
      windows.add(SeedWindowKey.critical);
    }

    return windows;
  }

  static List<BeanStageBounds> _buildBounds(BeanProfile profile) {
    final germEnd = profile.germinationDays.max;
    final emergenceEnd = _endAtLeast(profile.emergenceDays.max, germEnd + 1);
    final vegEarlyEnd = _endAtLeast(profile.vegEarlyDays.max, emergenceEnd + 1);

    final floweringStart = profile.floweringDays.min;
    final floweringEnd = _endAtLeast(profile.floweringDays.max, floweringStart);

    final vegAdvancedEnd = _clampInt(
      floweringStart - 1,
      min: vegEarlyEnd + 1,
      max: floweringStart - 1,
    );

    final harvestStart = profile.endWindowDays.min;
    final harvestEnd = _endAtLeast(profile.endWindowDays.max, harvestStart);

    final podSetStart = floweringEnd + 1;
    final podSetEnd = _clampInt(
      floweringEnd + 14,
      min: podSetStart,
      max: harvestStart - 10,
    );

    final grainFillStart = podSetEnd + 1;
    final grainFillEnd = _clampInt(
      harvestStart - 8,
      min: grainFillStart,
      max: harvestStart - 2,
    );

    final maturityStart = grainFillEnd + 1;
    final maturityEnd = _clampInt(
      harvestStart - 1,
      min: maturityStart,
      max: harvestStart - 1,
    );

    return <BeanStageBounds>[
      BeanStageBounds(
        key: BeanStageKey.germination,
        startDay: 1,
        endDay: _endAtLeast(germEnd, 1),
      ),
      BeanStageBounds(
        key: BeanStageKey.emergence,
        startDay: germEnd + 1,
        endDay: _endAtLeast(emergenceEnd, germEnd + 1),
      ),
      BeanStageBounds(
        key: BeanStageKey.vegEarly,
        startDay: emergenceEnd + 1,
        endDay: _endAtLeast(vegEarlyEnd, emergenceEnd + 1),
      ),
      BeanStageBounds(
        key: BeanStageKey.vegAdvanced,
        startDay: vegEarlyEnd + 1,
        endDay: _endAtLeast(vegAdvancedEnd, vegEarlyEnd + 1),
      ),
      BeanStageBounds(
        key: BeanStageKey.flowering,
        startDay: floweringStart,
        endDay: floweringEnd,
      ),
      BeanStageBounds(
        key: BeanStageKey.podSet,
        startDay: podSetStart,
        endDay: _endAtLeast(podSetEnd, podSetStart),
      ),
      BeanStageBounds(
        key: BeanStageKey.grainFill,
        startDay: grainFillStart,
        endDay: _endAtLeast(grainFillEnd, grainFillStart),
      ),
      BeanStageBounds(
        key: BeanStageKey.physiologicalMaturity,
        startDay: maturityStart,
        endDay: _endAtLeast(maturityEnd, maturityStart),
      ),
      BeanStageBounds(
        key: BeanStageKey.harvest,
        startDay: harvestStart,
        endDay: harvestEnd,
      ),
    ];
  }

  static BeanStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required BeanProfile profile,
    int stressDelayDays = 0,
    int? debugOverrideDaySinceSowing,
  }) {
    final daySince =
        debugOverrideDaySinceSowing ??
        (today.difference(sowingDate).inDays + 1);

    final effectiveDay = _clampInt(
      daySince + stressDelayDays,
      min: 1,
      max: 999999,
    );

    final bounds = _buildBounds(profile);

    BeanStageBounds current = bounds.first;
    for (final bound in bounds) {
      current = bound;
      if (bound.contains(effectiveDay)) break;
    }

    final denom = (current.endDay - current.startDay).clamp(1, 999999);
    final progress = ((effectiveDay - current.startDay) / denom).clamp(
      0.0,
      1.0,
    );

    final pct = _heightPct(current.key);
    final heightToday = RangeDouble(
      profile.plantHeightM.min * pct.min,
      profile.plantHeightM.max * pct.max,
    );

    final expectedEnd = profile.endWindowDays.mid;
    final remaining = (expectedEnd - effectiveDay).clamp(0, 999999);

    return BeanStageResult(
      profile: profile,
      stage: current.key,
      daySinceSowing: daySince,
      floweringBand: profile.floweringDays,
      endBand: profile.endWindowDays,
      expectedFloweringDay: profile.floweringDays.mid,
      expectedEndDay: expectedEnd,
      expectedDaysToEnd: remaining,
      stageProgressPct: progress,
      windowsNow: _windows(current.key),
      expectedPlantHeightTodayM: heightToday,
      stageLabelEs: labelEs(current.key),
      heroAsset: heroAssetForStage(current.key),
      helperCaption: _helperCaption(current.key),
    );
  }

  static int _clampInt(int value, {required int min, required int max}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static int _endAtLeast(int end, int start) => end < start ? start : end;

  static String _helperCaption(BeanStageKey s) {
    switch (s) {
      case BeanStageKey.germination:
        return 'Mantén humedad uniforme sin encharcamiento. '
            'Frijol es muy sensible a salinidad en esta etapa.';
      case BeanStageKey.emergence:
        return 'Vigila costra superficial y compactación. '
            'Plántula hipogea frágil, evita EC alta.';
      case BeanStageKey.vegEarly:
        return 'Desarrollo radical activo. '
            'Asegura P disponible para fijación de nódulos.';
      case BeanStageKey.vegAdvanced:
        return 'Pre-floración: la planta define potencial de vainas. '
            'N moderado para no inhibir nodulación.';
      case BeanStageKey.flowering:
        return 'Etapa crítica: estrés hídrico o térmico causa '
            'aborto floral. Mantén humedad estable.';
      case BeanStageKey.podSet:
        return 'Máxima sensibilidad al estrés. '
            'Mantén humedad alta y K disponible para llenado.';
      case BeanStageKey.grainFill:
        return 'Llenado activo de grano. '
            'K es prioritario; reducción gradual de riego.';
      case BeanStageKey.physiologicalMaturity:
        return 'Planta en senescencia. '
            'Reducir riego para favorecer secado uniforme.';
      case BeanStageKey.harvest:
        return 'Grano en secado. '
            'Humedad objetivo: 12–14 % para trilla.';
    }
  }
}
