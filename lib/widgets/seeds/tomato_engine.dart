import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/tomato_models.dart';

/// Motor fenológico del tomate.
///
/// El reloj biológico ancla en trasplante cuando el modo es transplant,
/// y en siembra cuando es directSeed. Internamente, todos los cálculos
/// operan sobre DDT (días después del anclaje). Para siembra directa, se
/// aplica un offset adicional (~25 d) que representa vivero virtual,
/// de manera que las bandas (floración, cosecha, fin) mantienen el mismo
/// significado biológico sin importar el modo.
class TomatoEngine {
  /// Offset aplicado cuando el modo es siembra directa, para alinear el
  /// ciclo al "reloj biológico" del perfil (que está expresado en DDT).
  static const int _directSeedOffsetDays = 25;

  static String heroAssetForStage(TomatoStageKey stage) {
    switch (stage) {
      case TomatoStageKey.germinacion:
        return 'assets/seeds/tomato/tomato_stage_germination.png';
      case TomatoStageKey.establecimiento:
        return 'assets/seeds/tomato/tomato_stage_establishment.png';
      case TomatoStageKey.vegetativo:
        return 'assets/seeds/tomato/tomato_stage_vegetative.png';
      case TomatoStageKey.floracion:
        return 'assets/seeds/tomato/tomato_stage_flowering.png';
      case TomatoStageKey.cuajado:
        return 'assets/seeds/tomato/tomato_stage_fruit_set.png';
      case TomatoStageKey.llenado:
        return 'assets/seeds/tomato/tomato_stage_fruit_fill.png';
      case TomatoStageKey.cosechaProgresiva:
        return 'assets/seeds/tomato/tomato_stage_progressive_harvest.png';
      case TomatoStageKey.finCiclo:
        return 'assets/seeds/tomato/tomato_stage_senescence.png';
    }
  }

  static String labelEs(TomatoStageKey stage) {
    switch (stage) {
      case TomatoStageKey.germinacion:
        return 'Germinación';
      case TomatoStageKey.establecimiento:
        return 'Establecimiento';
      case TomatoStageKey.vegetativo:
        return 'Vegetativo';
      case TomatoStageKey.floracion:
        return 'Floración';
      case TomatoStageKey.cuajado:
        return 'Cuajado';
      case TomatoStageKey.llenado:
        return 'Llenado';
      case TomatoStageKey.cosechaProgresiva:
        return 'Cosecha progresiva';
      case TomatoStageKey.finCiclo:
        return 'Fin de ciclo';
    }
  }

  static String productiveStateLabelEs(TomatoStageKey state) {
    switch (state) {
      case TomatoStageKey.floracion:
        return 'Floración activa';
      case TomatoStageKey.cuajado:
        return 'Cuajado activo';
      case TomatoStageKey.llenado:
        return 'Llenado activo';
      case TomatoStageKey.cosechaProgresiva:
        return 'Cosecha activa';
      default:
        return '';
    }
  }

  static (double, double) _heightPctBounds(TomatoStageKey stage) {
    switch (stage) {
      case TomatoStageKey.germinacion:
        return (0.00, 0.02);
      case TomatoStageKey.establecimiento:
        return (0.02, 0.15);
      case TomatoStageKey.vegetativo:
        return (0.15, 0.55);
      case TomatoStageKey.floracion:
        return (0.55, 0.75);
      case TomatoStageKey.cuajado:
        return (0.75, 0.88);
      case TomatoStageKey.llenado:
        return (0.88, 0.97);
      case TomatoStageKey.cosechaProgresiva:
        return (0.97, 1.00);
      case TomatoStageKey.finCiclo:
        return (1.00, 1.00);
    }
  }

  static List<SeedWindowKey> _windows(TomatoStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];

    // Establecimiento incluido: P starter y Ca temprano son operativos
    // (coherente con pPriority=0.80 y caPriority=0.55 del universal profile).
    final nutritionHeavy =
        stage == TomatoStageKey.establecimiento ||
            stage == TomatoStageKey.vegetativo ||
            stage == TomatoStageKey.floracion ||
            stage == TomatoStageKey.cuajado ||
            stage == TomatoStageKey.llenado ||
            stage == TomatoStageKey.cosechaProgresiva;

    if (nutritionHeavy) windows.add(SeedWindowKey.nutrition);

    if (stage == TomatoStageKey.floracion ||
        stage == TomatoStageKey.cuajado) {
      windows.add(SeedWindowKey.critical);
    }

    return windows;
  }

  static List<TomatoStageBounds> _buildBounds(
    TomatoProfile profile,
    TomatoEstablishmentMode mode,
  ) {
    // Los perfiles declaran bandas en DDT (días post-trasplante). Para
    // siembra directa, desplazamos TODAS las bandas post-anclaje por el
    // offset virtual de vivero, y ensanchamos germinación/establecimiento
    // para cubrir la ventana real pre-trasplante (emergencia + plántula).
    final bool isDirectSeed = mode == TomatoEstablishmentMode.directSeed;
    final int offset = isDirectSeed ? _directSeedOffsetDays : 0;

    // Transplant: la planta ya emergió; germinación se colapsa a 1 día.
    // Direct seed: 7-10 d para emergencia (18-26 °C suelo).
    final int germEnd = isDirectSeed ? 8 : 1;
    // Transplant: ~2 semanas de anclaje post-trasplante.
    // Direct seed: pre-emergencia + plántula hasta alcanzar el "día 0 DDT".
    final int establishmentEnd = isDirectSeed ? _directSeedOffsetDays : 14;

    final floweringStart = profile.floweringDays.min + offset;
    final vegEnd = _clampInt(
      floweringStart - 1,
      min: establishmentEnd + 1,
      max: math.max(establishmentEnd + 1, floweringStart - 1),
    );

    final floweringEnd = _endAtLeast(
      profile.floweringDays.max + offset,
      floweringStart,
    );

    final harvestStart = profile.harvestStartDays.min + offset;
    final cuajadoStart = floweringEnd + 1;
    final cuajadoEnd = _clampInt(
      harvestStart - 8,
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
    final endWindowStart = profile.endWindowDays.min + offset;
    final endWindowEnd = _endAtLeast(
      profile.endWindowDays.max + offset,
      endWindowStart,
    );
    final cosechaEnd = math.max(cosechaStart, endWindowStart - 1);

    return <TomatoStageBounds>[
      TomatoStageBounds(
        key: TomatoStageKey.germinacion,
        startDay: 1,
        endDay: germEnd,
      ),
      TomatoStageBounds(
        key: TomatoStageKey.establecimiento,
        startDay: germEnd + 1,
        endDay: establishmentEnd,
      ),
      TomatoStageBounds(
        key: TomatoStageKey.vegetativo,
        startDay: establishmentEnd + 1,
        endDay: vegEnd,
      ),
      TomatoStageBounds(
        key: TomatoStageKey.floracion,
        startDay: floweringStart,
        endDay: floweringEnd,
      ),
      TomatoStageBounds(
        key: TomatoStageKey.cuajado,
        startDay: cuajadoStart,
        endDay: cuajadoEnd,
      ),
      TomatoStageBounds(
        key: TomatoStageKey.llenado,
        startDay: llenadoStart,
        endDay: llenadoEnd,
      ),
      TomatoStageBounds(
        key: TomatoStageKey.cosechaProgresiva,
        startDay: cosechaStart,
        endDay: _endAtLeast(cosechaEnd, cosechaStart),
      ),
      TomatoStageBounds(
        key: TomatoStageKey.finCiclo,
        startDay: endWindowStart,
        endDay: endWindowEnd,
      ),
    ];
  }

  /// Calcula estado productivo complementario (traslape).
  ///
  /// El tomate tiene traslape estructural: durante cuajado/llenado/cosecha
  /// pueden estar ocurriendo otras etapas productivas en ramas superiores.
  static TomatoStageKey? _productiveStateFor(TomatoStageKey dominant) {
    switch (dominant) {
      case TomatoStageKey.cuajado:
        return TomatoStageKey.floracion;
      case TomatoStageKey.llenado:
        return TomatoStageKey.cuajado;
      case TomatoStageKey.cosechaProgresiva:
        return TomatoStageKey.llenado;
      default:
        return null;
    }
  }

  static TomatoStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required TomatoProfile profile,
    TomatoEstablishmentMode? establishmentMode,
    int stressDelayDays = 0,
    int? debugOverrideDaySinceAnchor,
  }) {
    final mode = establishmentMode ?? profile.defaultEstablishmentMode;

    final rawDay = debugOverrideDaySinceAnchor ??
        (today.difference(sowingDate).inDays + 1);

    // Transplant: rawDay = DDT (día post-trasplante).
    // Direct seed: rawDay = día post-siembra; las bandas de _buildBounds
    // ya vienen desplazadas por _directSeedOffsetDays, así que no
    // aplicamos sustracción aquí.
    final effectiveDay = _clampInt(
      rawDay + stressDelayDays,
      min: 1,
      max: 999999,
    );

    final bounds = _buildBounds(profile, mode);

    TomatoStageBounds current = bounds.first;
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

    // Las bandas visibles (flor/cosecha/fin) se reportan en la misma
    // escala que daySinceAnchor: DDT en trasplante, días post-siembra en
    // siembra directa. Aplicamos el offset al exponerlas al UI.
    final int offset = mode == TomatoEstablishmentMode.directSeed
        ? _directSeedOffsetDays
        : 0;
    final floweringBandShifted = RangeInt(
      profile.floweringDays.min + offset,
      profile.floweringDays.max + offset,
    );
    final harvestStartBandShifted = RangeInt(
      profile.harvestStartDays.min + offset,
      profile.harvestStartDays.max + offset,
    );
    final endBandShifted = RangeInt(
      profile.endWindowDays.min + offset,
      profile.endWindowDays.max + offset,
    );

    final expectedEnd = endBandShifted.mid;
    final remaining = (expectedEnd - effectiveDay).clamp(0, 999999);

    final productive = _productiveStateFor(current.key);

    return TomatoStageResult(
      profile: profile,
      stage: current.key,
      daySinceAnchor: rawDay,
      establishmentMode: mode,
      floweringBand: floweringBandShifted,
      harvestStartBand: harvestStartBandShifted,
      endBand: endBandShifted,
      expectedFloweringDay: floweringBandShifted.mid,
      expectedHarvestStartDay: harvestStartBandShifted.mid,
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
      helperCaption: _helperCaption(current.key),
    );
  }

  static int _clampInt(int value, {required int min, required int max}) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static int _endAtLeast(int end, int start) => end < start ? start : end;

  static String _helperCaption(TomatoStageKey s) {
    switch (s) {
      case TomatoStageKey.germinacion:
        return 'Plántula iniciando. '
            'Humedad uniforme y EC baja. Evita salinidad de arranque.';
      case TomatoStageKey.establecimiento:
        return 'Anclaje radical y amortiguamiento de estrés de trasplante. '
            'P disponible y temperatura de suelo estable.';
      case TomatoStageKey.vegetativo:
        return 'Desarrollo de follaje y arquitectura. '
            'N moderado para no inducir exceso vegetativo.';
      case TomatoStageKey.floracion:
        return 'Formación de racimos. Sensibilidad alta a salinidad y '
            'estrés hídrico. Ca y B jugando un rol clave.';
      case TomatoStageKey.cuajado:
        return 'Fase crítica: cada fallo se paga en cosecha. '
            'Estabilidad hídrica y Ca para evitar BER.';
      case TomatoStageKey.llenado:
        return 'Llenado de frutos. Demanda alta de K y agua estable. '
            'N en descenso gradual.';
      case TomatoStageKey.cosechaProgresiva:
        return 'Cosecha activa con floración superior. '
            'Mantén K y Ca, cuida manejo de riego para evitar rajado.';
      case TomatoStageKey.finCiclo:
        return 'Cierre progresivo de ciclo. '
            'Reducción de riego y preparación para descanso/renovación.';
    }
  }
}
