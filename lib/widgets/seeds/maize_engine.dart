// lib/widgets/seeds/maize_engine.dart
import 'package:bio_g/widgets/seeds/maize_models.dart';

class MaizeEngine {
  static String heroAssetForStage(MaizeStageKey s) {
    switch (s) {
      case MaizeStageKey.germination:
        return 'assets/seeds/maize_stage_germination.png';
      case MaizeStageKey.emergence:
        return 'assets/seeds/maize_stage_emergence.png';
      case MaizeStageKey.vegEarly:
        return 'assets/seeds/maize_stage_veg_early.png';
      case MaizeStageKey.vegMid:
        return 'assets/seeds/maize_stage_veg_mid.png';
      case MaizeStageKey.vegAdvanced:
        return 'assets/seeds/maize_stage_veg_advanced.png';
      case MaizeStageKey.tasseling:
        return 'assets/seeds/maize_stage_tasseling.png';
      case MaizeStageKey.flowerSet:
        return 'assets/seeds/maize_stage_flower_set.png';
      case MaizeStageKey.maturitySenescence:
        return 'assets/seeds/maize_stage_maturity_senescence.png';
      case MaizeStageKey.harvest:
        return 'assets/seeds/maize_stage_harvest.png';
    }
  }

  static String labelEs(MaizeStageKey s) {
    switch (s) {
      case MaizeStageKey.germination:
        return 'Germinación';
      case MaizeStageKey.emergence:
        return 'Emergencia';
      case MaizeStageKey.vegEarly:
        return 'Vegetativa temprana';
      case MaizeStageKey.vegMid:
        return 'Vegetativa media';
      case MaizeStageKey.vegAdvanced:
        return 'Vegetativa avanzada';
      case MaizeStageKey.tasseling:
        return 'Espigado';
      case MaizeStageKey.flowerSet:
        return 'Floración y cuajado';
      case MaizeStageKey.maturitySenescence:
        return 'Maduración / senescencia';
      case MaizeStageKey.harvest:
        return 'Cosecha';
    }
  }

  static RangeDouble _heightPct(MaizeStageKey s) {
    switch (s) {
      case MaizeStageKey.germination:
        return const RangeDouble(0.00, 0.02);
      case MaizeStageKey.emergence:
        return const RangeDouble(0.02, 0.05);
      case MaizeStageKey.vegEarly:
        return const RangeDouble(0.10, 0.30);
      case MaizeStageKey.vegMid:
        return const RangeDouble(0.30, 0.55);
      case MaizeStageKey.vegAdvanced:
        return const RangeDouble(0.55, 0.70);
      case MaizeStageKey.tasseling:
        return const RangeDouble(0.70, 0.85);
      case MaizeStageKey.flowerSet:
        return const RangeDouble(0.80, 0.90);
      case MaizeStageKey.maturitySenescence:
        return const RangeDouble(0.90, 1.00);
      case MaizeStageKey.harvest:
        return const RangeDouble(0.95, 1.00);
    }
  }

  static List<SeedWindowKey> _windows(MaizeStageKey s) {
    final list = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];

    final hasActiveNutritionWindow =
        s == MaizeStageKey.vegEarly ||
        s == MaizeStageKey.vegMid ||
        s == MaizeStageKey.vegAdvanced ||
        s == MaizeStageKey.tasseling ||
        s == MaizeStageKey.flowerSet ||
        s == MaizeStageKey.maturitySenescence ||
        s == MaizeStageKey.harvest;

    if (hasActiveNutritionWindow) list.add(SeedWindowKey.nutrition);
    if (s == MaizeStageKey.tasseling || s == MaizeStageKey.flowerSet) {
      list.add(SeedWindowKey.critical);
    }

    return list;
  }

  static List<StageBounds> _buildBounds(MaizeProfile p) {
    final r1 = p.r1Days.mid;
    final endMid = p.endWindowDays.mid;

    final germEnd = p.germinationDays.max;
    final emerEnd = p.emergenceDays.max;
    final vegEarlyEnd = p.vegEarlyDays.max;

    final vegMidEnd = _clampInt(r1 - 12, min: vegEarlyEnd + 1, max: r1);
    final vegAdvEnd = _clampInt(r1 - 6, min: vegMidEnd + 1, max: r1);
    final tasselEnd = _clampInt(r1 - 1, min: vegAdvEnd + 1, max: r1);

    final flowerEnd = _clampInt(r1 + 7, min: r1, max: endMid);
    final maturityEnd = _clampInt(endMid - 1, min: flowerEnd + 1, max: endMid);

    final harvestStart = _clampInt(endMid, min: 1, max: p.endWindowDays.max);
    final harvestEnd = p.endWindowDays.max;

    return <StageBounds>[
      StageBounds(
        key: MaizeStageKey.germination,
        startDay: 1,
        endDay: _endAtLeast(germEnd, 1),
      ),
      StageBounds(
        key: MaizeStageKey.emergence,
        startDay: germEnd + 1,
        endDay: _endAtLeast(emerEnd, germEnd + 1),
      ),
      StageBounds(
        key: MaizeStageKey.vegEarly,
        startDay: emerEnd + 1,
        endDay: _endAtLeast(vegEarlyEnd, emerEnd + 1),
      ),
      StageBounds(
        key: MaizeStageKey.vegMid,
        startDay: vegEarlyEnd + 1,
        endDay: _endAtLeast(vegMidEnd, vegEarlyEnd + 1),
      ),
      StageBounds(
        key: MaizeStageKey.vegAdvanced,
        startDay: vegMidEnd + 1,
        endDay: _endAtLeast(vegAdvEnd, vegMidEnd + 1),
      ),
      StageBounds(
        key: MaizeStageKey.tasseling,
        startDay: vegAdvEnd + 1,
        endDay: _endAtLeast(tasselEnd, vegAdvEnd + 1),
      ),
      StageBounds(
        key: MaizeStageKey.flowerSet,
        startDay: r1,
        endDay: _endAtLeast(flowerEnd, r1),
      ),
      StageBounds(
        key: MaizeStageKey.maturitySenescence,
        startDay: flowerEnd + 1,
        endDay: _endAtLeast(maturityEnd, flowerEnd + 1),
      ),
      StageBounds(
        key: MaizeStageKey.harvest,
        startDay: harvestStart,
        endDay: _endAtLeast(harvestEnd, harvestStart),
      ),
    ];
  }

  static SeedStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required MaizeProfile profile,
    int stressDelayDays = 0,
    int? debugOverrideDaySinceSowing,
  }) {
    final daySince =
        debugOverrideDaySinceSowing ??
        (today.difference(sowingDate).inDays + 1);

    final effectiveDay = _clampInt(
      daySince - stressDelayDays,
      min: 1,
      max: 999999,
    );

    final bounds = _buildBounds(profile);

    StageBounds current = bounds.first;
    for (final b in bounds) {
      current = b;
      if (b.contains(effectiveDay)) break;
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

    final expectedEnd = profile.endWindowDays.max;
    final remaining = (expectedEnd - effectiveDay).clamp(0, 999999);

    return SeedStageResult(
      profile: profile,
      stage: current.key,
      daySinceSowing: daySince,
      r1Band: profile.r1Days,
      endBand: profile.endWindowDays,
      expectedR1Day: profile.r1Days.mid,
      expectedEndDay: expectedEnd,
      expectedDaysToEnd: remaining,
      stageProgressPct: progress,
      windowsNow: _windows(current.key),
      expectedPlantHeightTodayM: heightToday,
      stageLabelEs: labelEs(current.key),
      heroAsset: heroAssetForStage(current.key),
      helperCaption: _helperCaption(current.key, profile),
    );
  }

  static String _helperCaption(MaizeStageKey s, MaizeProfile profile) {
    switch (s) {
      case MaizeStageKey.germination:
        return 'Mantén humedad uniforme para asegurar imbibición. '
            'Evita costras en el suelo.';
      case MaizeStageKey.emergence:
        return 'Vigila compactación superficial: la plántula es frágil. '
            'Rango de temp. óptimo: 18–28 °C.';
      case MaizeStageKey.vegEarly:
        return 'Fase de desarrollo radical rápido. '
            'Asegura N disponible y humedad constante.';
      case MaizeStageKey.vegMid:
        return 'Máxima tasa de crecimiento foliar. '
            'Déficit hídrico aquí reduce área foliar final.';
      case MaizeStageKey.vegAdvanced:
        return 'Pre-espigado: la planta define potencial de mazorca. '
            'N y K son críticos.';
      case MaizeStageKey.tasseling:
        return 'Etapa crítica: estrés hídrico o térmico reduce '
            'polinización y cuajado de grano.';
      case MaizeStageKey.flowerSet:
        return 'Máxima sensibilidad al estrés. '
            'Mantén humedad alta y nutrientes estables.';
      case MaizeStageKey.maturitySenescence:
        switch (profile.maizeUseType) {
          case MaizeUseType.forage:
            return 'Acumulación final de biomasa. '
                'Mantén humedad funcional y vigila sanidad foliar antes del corte.';
          case MaizeUseType.elote:
            return 'Llenado comercial de mazorca. '
                'Mantén humedad uniforme y vigila calidad antes de cosecha de elote.';
          case MaizeUseType.grain:
            return 'Llenado de grano activo. '
                'Reducción gradual de riego; vigila sanidad foliar.';
        }
      case MaizeStageKey.harvest:
        switch (profile.maizeUseType) {
          case MaizeUseType.forage:
            return 'Ventana de corte cercana. '
                'Define momento por calidad de forraje, humedad y sanidad.';
          case MaizeUseType.elote:
            return 'Ventana de cosecha de elote. '
                'Busca uniformidad comercial y punto tierno de mazorca.';
          case MaizeUseType.grain:
            return 'Cultivo en secado. '
                'Humedad de grano objetivo: 14–15 % para cosecha.';
        }
    }
  }

  static int _clampInt(int v, {required int min, required int max}) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  static int _endAtLeast(int end, int start) => end < start ? start : end;
}
