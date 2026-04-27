import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/eggplant_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class EggplantEngine {
  static const int _seedGerminationEndDay = 14;
  static const int _seedEstablishmentEndDay = 28;
  static const int _transplantEstablishmentEndDay = 20;
  static const int _seedFloweringStartOffsetDays = 15;
  static const int _seedFloweringEndOffsetDays = 20;
  static const int _seedHarvestStartOffsetDays = 20;
  static const int _seedHarvestEndOffsetDays = 25;
  static const int _seedEndWindowOffsetDays = 25;

  static String heroAssetForStage(EggplantStageKey stage) {
    switch (stage) {
      case EggplantStageKey.germinacion:
        return 'assets/seeds/eggplant/eggplant_stage_germination.png';
      case EggplantStageKey.establecimiento:
        return 'assets/seeds/eggplant/eggplant_stage_establishment.png';
      case EggplantStageKey.vegetativo:
        return 'assets/seeds/eggplant/eggplant_stage_vegetative.png';
      case EggplantStageKey.floracion:
        return 'assets/seeds/eggplant/eggplant_stage_flowering.png';
      case EggplantStageKey.cuajado:
        return 'assets/seeds/eggplant/eggplant_stage_fruit_set.png';
      case EggplantStageKey.llenado:
        return 'assets/seeds/eggplant/eggplant_stage_fruit_fill.png';
      case EggplantStageKey.cosechaProgresiva:
        return 'assets/seeds/eggplant/eggplant_stage_progressive_harvest.png';
      case EggplantStageKey.finCiclo:
        return 'assets/seeds/eggplant/eggplant_stage_senescence.png';
    }
  }

  static String labelEs(EggplantStageKey stage) {
    switch (stage) {
      case EggplantStageKey.germinacion:
        return 'Germinación';
      case EggplantStageKey.establecimiento:
        return 'Emergencia / establecimiento';
      case EggplantStageKey.vegetativo:
        return 'Desarrollo vegetativo';
      case EggplantStageKey.floracion:
        return 'Floración';
      case EggplantStageKey.cuajado:
        return 'Amarre / cuajado';
      case EggplantStageKey.llenado:
        return 'Llenado de fruto';
      case EggplantStageKey.cosechaProgresiva:
        return 'Cosecha progresiva';
      case EggplantStageKey.finCiclo:
        return 'Fin de ciclo / senescencia';
    }
  }

  static String productiveStateLabelEs(EggplantStageKey state) {
    switch (state) {
      case EggplantStageKey.floracion:
        return 'Floración activa';
      case EggplantStageKey.cuajado:
        return 'Cuajado activo';
      case EggplantStageKey.llenado:
        return 'Llenado activo';
      case EggplantStageKey.cosechaProgresiva:
        return 'Cosecha activa';
      default:
        return '';
    }
  }

  static (double, double) _heightPctBounds(EggplantStageKey stage) {
    switch (stage) {
      case EggplantStageKey.germinacion:
        return (0.00, 0.03);
      case EggplantStageKey.establecimiento:
        return (0.03, 0.22);
      case EggplantStageKey.vegetativo:
        return (0.22, 0.68);
      case EggplantStageKey.floracion:
        return (0.68, 0.82);
      case EggplantStageKey.cuajado:
        return (0.82, 0.92);
      case EggplantStageKey.llenado:
        return (0.92, 0.98);
      case EggplantStageKey.cosechaProgresiva:
        return (0.98, 1.00);
      case EggplantStageKey.finCiclo:
        return (1.00, 1.00);
    }
  }

  static List<SeedWindowKey> _windows(EggplantStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];

    final nutritionActive =
        stage == EggplantStageKey.establecimiento ||
        stage == EggplantStageKey.vegetativo ||
        stage == EggplantStageKey.floracion ||
        stage == EggplantStageKey.cuajado ||
        stage == EggplantStageKey.llenado ||
        stage == EggplantStageKey.cosechaProgresiva;

    if (nutritionActive) {
      windows.add(SeedWindowKey.nutrition);
    }

    if (stage == EggplantStageKey.floracion ||
        stage == EggplantStageKey.cuajado) {
      windows.add(SeedWindowKey.critical);
    }

    return windows;
  }

  static List<EggplantStageBounds> _buildBounds(
    EggplantProfile profile,
    EggplantEstablishmentMode mode,
  ) {
    final isSeed = mode == EggplantEstablishmentMode.seed;
    final floweringBand = _bandForMode(
      profile.floweringDays,
      mode,
      seedStartOffset: _seedFloweringStartOffsetDays,
      seedEndOffset: _seedFloweringEndOffsetDays,
    );
    final harvestBand = _bandForMode(
      profile.harvestStartDays,
      mode,
      seedStartOffset: _seedHarvestStartOffsetDays,
      seedEndOffset: _seedHarvestEndOffsetDays,
    );
    final endBand = _bandForMode(
      profile.endWindowDays,
      mode,
      seedStartOffset: _seedEndWindowOffsetDays,
      seedEndOffset: _seedEndWindowOffsetDays,
    );

    final int establishmentStart = isSeed ? _seedGerminationEndDay + 1 : 1;
    final int establishmentEnd =
        isSeed ? _seedEstablishmentEndDay : _transplantEstablishmentEndDay;

    final floweringStart = floweringBand.min;
    final vegEnd = _clampInt(
      floweringStart - 1,
      min: establishmentEnd + 1,
      max: math.max(establishmentEnd + 1, floweringStart - 1),
    );

    final floweringEnd = _endAtLeast(floweringBand.max, floweringStart);

    final harvestStart = harvestBand.min;
    final cuajadoStart = floweringEnd + 1;
    final cuajadoEnd = _clampInt(
      harvestStart - 9,
      min: cuajadoStart,
      max: math.max(cuajadoStart, harvestStart - 1),
    );

    final llenadoStart = cuajadoEnd + 1;
    final llenadoEnd = _clampInt(
      harvestStart - 1,
      min: llenadoStart,
      max: math.max(llenadoStart, harvestStart - 1),
    );

    final cosechaStart = harvestStart;
    final endWindowStart = endBand.min;
    final endWindowEnd = _endAtLeast(endBand.max, endWindowStart);
    final cosechaEnd = math.max(cosechaStart, endWindowStart - 1);

    final bounds = <EggplantStageBounds>[];

    if (isSeed) {
      bounds.add(EggplantStageBounds(
        key: EggplantStageKey.germinacion,
        startDay: 1,
        endDay: _seedGerminationEndDay,
      ));
    }

    bounds.addAll(<EggplantStageBounds>[
      EggplantStageBounds(
        key: EggplantStageKey.establecimiento,
        startDay: establishmentStart,
        endDay: establishmentEnd,
      ),
      EggplantStageBounds(
        key: EggplantStageKey.vegetativo,
        startDay: establishmentEnd + 1,
        endDay: vegEnd,
      ),
      EggplantStageBounds(
        key: EggplantStageKey.floracion,
        startDay: floweringStart,
        endDay: floweringEnd,
      ),
      EggplantStageBounds(
        key: EggplantStageKey.cuajado,
        startDay: cuajadoStart,
        endDay: cuajadoEnd,
      ),
      EggplantStageBounds(
        key: EggplantStageKey.llenado,
        startDay: llenadoStart,
        endDay: llenadoEnd,
      ),
      EggplantStageBounds(
        key: EggplantStageKey.cosechaProgresiva,
        startDay: cosechaStart,
        endDay: _endAtLeast(cosechaEnd, cosechaStart),
      ),
      EggplantStageBounds(
        key: EggplantStageKey.finCiclo,
        startDay: endWindowStart,
        endDay: endWindowEnd,
      ),
    ]);

    return bounds;
  }

  static EggplantStageKey? _productiveStateFor(EggplantStageKey dominant) {
    switch (dominant) {
      case EggplantStageKey.cuajado:
        return EggplantStageKey.floracion;
      case EggplantStageKey.llenado:
        return EggplantStageKey.cuajado;
      case EggplantStageKey.cosechaProgresiva:
        return EggplantStageKey.llenado;
      default:
        return null;
    }
  }

  static EggplantStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required EggplantProfile profile,
    EggplantEstablishmentMode? establishmentMode,
    int stressDelayDays = 0,
    int? debugOverrideDaySinceAnchor,
  }) {
    final mode = establishmentMode ?? profile.defaultEstablishmentMode;

    final rawDay =
        debugOverrideDaySinceAnchor ??
        (today.difference(sowingDate).inDays + 1);

    final effectiveDay = _clampInt(
      rawDay + stressDelayDays,
      min: 1,
      max: 999999,
    );

    final bounds = _buildBounds(profile, mode);
    EggplantStageBounds current = bounds.first;

    for (final bound in bounds) {
      current = bound;
      if (bound.contains(effectiveDay)) {
        break;
      }
    }

    final denom = (current.endDay - current.startDay).clamp(1, 999999);
    final progress = ((effectiveDay - current.startDay) / denom).clamp(
      0.0,
      1.0,
    );

    final (startPct, endPct) = _heightPctBounds(current.key);
    final pct = startPct + (endPct - startPct) * progress;

    final heightToday = RangeDouble(
      profile.plantHeightM.min * pct,
      profile.plantHeightM.max * pct,
    );

    final floweringBand = _bandForMode(
      profile.floweringDays,
      mode,
      seedStartOffset: _seedFloweringStartOffsetDays,
      seedEndOffset: _seedFloweringEndOffsetDays,
    );

    final harvestStartBand = _bandForMode(
      profile.harvestStartDays,
      mode,
      seedStartOffset: _seedHarvestStartOffsetDays,
      seedEndOffset: _seedHarvestEndOffsetDays,
    );

    final endBand = _bandForMode(
      profile.endWindowDays,
      mode,
      seedStartOffset: _seedEndWindowOffsetDays,
      seedEndOffset: _seedEndWindowOffsetDays,
    );

    final expectedEnd = endBand.mid;
    final remaining = (expectedEnd - effectiveDay).clamp(0, 999999);
    final productive = _productiveStateFor(current.key);

    return EggplantStageResult(
      profile: profile,
      stage: current.key,
      daySinceAnchor: rawDay,
      establishmentMode: mode,
      floweringBand: floweringBand,
      harvestStartBand: harvestStartBand,
      endBand: endBand,
      expectedFloweringDay: floweringBand.mid,
      expectedHarvestStartDay: harvestStartBand.mid,
      expectedEndDay: expectedEnd,
      expectedDaysToEnd: remaining,
      stageProgressPct: progress,
      windowsNow: _windows(current.key),
      productiveState: productive,
      expectedPlantHeightTodayM: heightToday,
      stageLabelEs: labelEs(current.key),
      productiveStateLabelEs: productive == null
          ? ''
          : productiveStateLabelEs(productive),
      heroAsset: heroAssetForStage(current.key),
      helperCaption: _helperCaption(current.key, profile),
    );
  }

  static int _clampInt(int value, {required int min, required int max}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static int _endAtLeast(int end, int start) {
    return end < start ? start : end;
  }

  static RangeInt _bandForMode(
    RangeInt band,
    EggplantEstablishmentMode mode, {
    required int seedStartOffset,
    required int seedEndOffset,
  }) {
    if (mode != EggplantEstablishmentMode.seed) return band;
    return RangeInt(band.min + seedStartOffset, band.max + seedEndOffset);
  }

  static String _helperCaption(
    EggplantStageKey stage,
    EggplantProfile profile,
  ) {
    final qualityNote = profile.visualQualitySensitive
        ? ' Este tipo exige más cuidado visual: manchas, sol y roces pegan al precio.'
        : '';

    switch (stage) {
      case EggplantStageKey.germinacion:
        return 'Arranque sensible: humedad uniforme, suelo tibio y sales bajas.$qualityNote';
      case EggplantStageKey.establecimiento:
        return 'Raíz y pegue de trasplante. P disponible, drenaje limpio y evitar sales cerca de raíz joven.';
      case EggplantStageKey.vegetativo:
        return 'Construir planta y hoja activa. N importa, pero sin exceso vegetativo.';
      case EggplantStageKey.floracion:
        return 'Ventana crítica: agua estable, temperatura sin extremos y balance P/K.';
      case EggplantStageKey.cuajado:
        return 'Amarre de fruto: evitar calor, salinidad y déficit hídrico. K y agua estable mandan.';
      case EggplantStageKey.llenado:
        return 'Llenado y calidad: K alto, Ca/Mg balanceados y CE bajo vigilancia.';
      case EggplantStageKey.cosechaProgresiva:
        return 'Cortes continuos: reposición sostenida sin disparar N y monitoreo sanitario.';
      case EggplantStageKey.finCiclo:
        return 'Senescencia y cierre. No sobreinvertir; documentar sanidad y nutrición para el siguiente ciclo.';
    }
  }
}
