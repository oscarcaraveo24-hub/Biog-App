import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/chili_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class ChiliEngine {
  static String heroAssetForStage(ChiliStageKey stage) {
    switch (stage) {
      case ChiliStageKey.germinacion:
        return 'assets/seeds/chili/chili_stage_germination.png';
      case ChiliStageKey.establecimiento:
        return 'assets/seeds/chili/chili_stage_establishment.png';
      case ChiliStageKey.vegetativo:
        return 'assets/seeds/chili/chili_stage_vegetative.png';
      case ChiliStageKey.floracion:
        return 'assets/seeds/chili/chili_stage_flowering.png';
      case ChiliStageKey.cuajado:
        return 'assets/seeds/chili/chili_stage_fruit_set.png';
      case ChiliStageKey.llenado:
        return 'assets/seeds/chili/chili_stage_fruit_fill.png';
      case ChiliStageKey.cosechaProgresiva:
        return 'assets/seeds/chili/chili_stage_progressive_harvest.png';
      case ChiliStageKey.finCiclo:
        return 'assets/seeds/chili/chili_stage_senescence.png';
    }
  }

  static String labelEs(ChiliStageKey stage) {
    switch (stage) {
      case ChiliStageKey.germinacion:
        return 'Germinacion';
      case ChiliStageKey.establecimiento:
        return 'Emergencia / establecimiento';
      case ChiliStageKey.vegetativo:
        return 'Desarrollo vegetativo';
      case ChiliStageKey.floracion:
        return 'Floracion';
      case ChiliStageKey.cuajado:
        return 'Amarre / cuajado';
      case ChiliStageKey.llenado:
        return 'Llenado de fruto';
      case ChiliStageKey.cosechaProgresiva:
        return 'Cosecha progresiva';
      case ChiliStageKey.finCiclo:
        return 'Fin de ciclo / senescencia';
    }
  }

  static String productiveStateLabelEs(ChiliStageKey state) {
    switch (state) {
      case ChiliStageKey.floracion:
        return 'Floracion activa';
      case ChiliStageKey.cuajado:
        return 'Cuajado activo';
      case ChiliStageKey.llenado:
        return 'Llenado activo';
      case ChiliStageKey.cosechaProgresiva:
        return 'Cosecha activa';
      default:
        return '';
    }
  }

  static (double, double) _heightPctBounds(ChiliStageKey stage) {
    switch (stage) {
      case ChiliStageKey.germinacion:
        return (0.00, 0.03);
      case ChiliStageKey.establecimiento:
        return (0.03, 0.20);
      case ChiliStageKey.vegetativo:
        return (0.20, 0.68);
      case ChiliStageKey.floracion:
        return (0.68, 0.82);
      case ChiliStageKey.cuajado:
        return (0.82, 0.92);
      case ChiliStageKey.llenado:
        return (0.92, 0.98);
      case ChiliStageKey.cosechaProgresiva:
        return (0.98, 1.00);
      case ChiliStageKey.finCiclo:
        return (1.00, 1.00);
    }
  }

  static List<SeedWindowKey> _windows(ChiliStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];

    final nutritionActive = stage == ChiliStageKey.establecimiento ||
        stage == ChiliStageKey.vegetativo ||
        stage == ChiliStageKey.floracion ||
        stage == ChiliStageKey.cuajado ||
        stage == ChiliStageKey.llenado ||
        stage == ChiliStageKey.cosechaProgresiva;

    if (nutritionActive) windows.add(SeedWindowKey.nutrition);

    if (stage == ChiliStageKey.floracion || stage == ChiliStageKey.cuajado) {
      windows.add(SeedWindowKey.critical);
    }

    return windows;
  }

  static List<ChiliStageBounds> _buildBounds(
    ChiliProfile profile,
    ChiliEstablishmentMode mode,
  ) {
    final bool isDirectSeed = mode == ChiliEstablishmentMode.directSeed;
    final int germEnd = isDirectSeed ? 8 : 1;
    final int establishmentEnd = isDirectSeed ? 25 : 14;

    final floweringStart = profile.floweringDays.min;
    final vegEnd = _clampInt(
      floweringStart - 1,
      min: establishmentEnd + 1,
      max: math.max(establishmentEnd + 1, floweringStart - 1),
    );

    final floweringEnd = _endAtLeast(
      profile.floweringDays.max,
      floweringStart,
    );

    final harvestStart = profile.harvestStartDays.min;
    final cuajadoStart = floweringEnd + 1;
    final cuajadoEnd = _clampInt(
      harvestStart - 10,
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
    final endWindowStart = profile.endWindowDays.min;
    final endWindowEnd = _endAtLeast(
      profile.endWindowDays.max,
      endWindowStart,
    );
    final cosechaEnd = math.max(cosechaStart, endWindowStart - 1);

    return <ChiliStageBounds>[
      ChiliStageBounds(
        key: ChiliStageKey.germinacion,
        startDay: 1,
        endDay: germEnd,
      ),
      ChiliStageBounds(
        key: ChiliStageKey.establecimiento,
        startDay: germEnd + 1,
        endDay: establishmentEnd,
      ),
      ChiliStageBounds(
        key: ChiliStageKey.vegetativo,
        startDay: establishmentEnd + 1,
        endDay: vegEnd,
      ),
      ChiliStageBounds(
        key: ChiliStageKey.floracion,
        startDay: floweringStart,
        endDay: floweringEnd,
      ),
      ChiliStageBounds(
        key: ChiliStageKey.cuajado,
        startDay: cuajadoStart,
        endDay: cuajadoEnd,
      ),
      ChiliStageBounds(
        key: ChiliStageKey.llenado,
        startDay: llenadoStart,
        endDay: llenadoEnd,
      ),
      ChiliStageBounds(
        key: ChiliStageKey.cosechaProgresiva,
        startDay: cosechaStart,
        endDay: _endAtLeast(cosechaEnd, cosechaStart),
      ),
      ChiliStageBounds(
        key: ChiliStageKey.finCiclo,
        startDay: endWindowStart,
        endDay: endWindowEnd,
      ),
    ];
  }

  static ChiliStageKey? _productiveStateFor(ChiliStageKey dominant) {
    switch (dominant) {
      case ChiliStageKey.cuajado:
        return ChiliStageKey.floracion;
      case ChiliStageKey.llenado:
        return ChiliStageKey.cuajado;
      case ChiliStageKey.cosechaProgresiva:
        return ChiliStageKey.llenado;
      default:
        return null;
    }
  }

  static ChiliStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required ChiliProfile profile,
    ChiliEstablishmentMode? establishmentMode,
    int stressDelayDays = 0,
    int? debugOverrideDaySinceAnchor,
  }) {
    final mode = establishmentMode ?? profile.defaultEstablishmentMode;

    final rawDay = debugOverrideDaySinceAnchor ??
        (today.difference(sowingDate).inDays + 1);

    final effectiveDay = _clampInt(
      rawDay + stressDelayDays,
      min: 1,
      max: 999999,
    );

    final bounds = _buildBounds(profile, mode);

    ChiliStageBounds current = bounds.first;
    for (final bound in bounds) {
      current = bound;
      if (bound.contains(effectiveDay)) break;
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

    final floweringBand = RangeInt(
      profile.floweringDays.min,
      profile.floweringDays.max,
    );
    final harvestStartBand = RangeInt(
      profile.harvestStartDays.min,
      profile.harvestStartDays.max,
    );
    final endBand = RangeInt(
      profile.endWindowDays.min,
      profile.endWindowDays.max,
    );

    final expectedEnd = endBand.mid;
    final remaining = (expectedEnd - effectiveDay).clamp(0, 999999);
    final productive = _productiveStateFor(current.key);

    return ChiliStageResult(
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
      productiveStateLabelEs:
          productive == null ? '' : productiveStateLabelEs(productive),
      heroAsset: heroAssetForStage(current.key),
      helperCaption: _helperCaption(current.key, profile),
    );
  }

  static int _clampInt(int value, {required int min, required int max}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static int _endAtLeast(int end, int start) => end < start ? start : end;

  static String _helperCaption(ChiliStageKey stage, ChiliProfile profile) {
    final habaneroNote = profile.isCapsicumChinense
        ? ' Habanero pide mas calor estable y sufre mas con frio o sales.'
        : '';

    switch (stage) {
      case ChiliStageKey.germinacion:
        return 'Arranque sensible: humedad uniforme, suelo tibio y EC baja.$habaneroNote';
      case ChiliStageKey.establecimiento:
        return 'Raiz y pegue de trasplante. P disponible, drenaje limpio y cero encharques.';
      case ChiliStageKey.vegetativo:
        return 'Follaje y arquitectura. N importante, pero sin empujar exceso antes de flor.';
      case ChiliStageKey.floracion:
        return 'Ventana critica: proteger flor contra calor, frio, salinidad y seca. N moderado.';
      case ChiliStageKey.cuajado:
        return 'Amarre de fruto: humedad pareja, K y Ca suben mucho; evitar golpes de sales.';
      case ChiliStageKey.llenado:
        return 'Llenado y calidad de fruto. K domina, Ca sostiene pared y firmeza.';
      case ChiliStageKey.cosechaProgresiva:
        return 'Cortes continuos con nueva flor arriba. Mantener K, Ca, agua y monitoreo de vectores.';
      case ChiliStageKey.finCiclo:
        return 'Senescencia y cierre. Bajar riegos gradualmente y documentar sanidad para el siguiente ciclo.';
    }
  }
}
