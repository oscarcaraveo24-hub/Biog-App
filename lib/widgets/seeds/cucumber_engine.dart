import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/cucumber_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

/// Motor fenológico del pepino.
///
/// El reloj biológico ancla en el inicio real del ciclo:
/// siembra directa o trasplante.
///
/// En pepino, a diferencia de tomate, los perfiles BIO-G se leen desde
/// "siembra/trasplante" como día 0, así que NO se desplazan artificialmente
/// las bandas de floración, cosecha y fin entre modos de establecimiento.
/// El modo solo altera la lectura temprana de germinación/establecimiento.
class CucumberEngine {
  static String heroAssetForStage(CucumberStageKey stage) {
    switch (stage) {
      case CucumberStageKey.germinacion:
        return 'assets/seeds/cucumber/cucumber_stage_germination.png';
      case CucumberStageKey.establecimiento:
        return 'assets/seeds/cucumber/cucumber_stage_establishment.png';
      case CucumberStageKey.vegetativo:
        return 'assets/seeds/cucumber/cucumber_stage_vegetative.png';
      case CucumberStageKey.floracion:
        return 'assets/seeds/cucumber/cucumber_stage_flowering.png';
      case CucumberStageKey.cuajado:
        return 'assets/seeds/cucumber/cucumber_stage_fruit_set.png';
      case CucumberStageKey.llenado:
        return 'assets/seeds/cucumber/cucumber_stage_fruit_fill.png';
      case CucumberStageKey.cosechaProgresiva:
        return 'assets/seeds/cucumber/cucumber_stage_progressive_harvest.png';
      case CucumberStageKey.finCiclo:
        return 'assets/seeds/cucumber/cucumber_stage_senescence.png';
    }
  }

  static String labelEs(CucumberStageKey stage) {
    switch (stage) {
      case CucumberStageKey.germinacion:
        return 'Germinación';
      case CucumberStageKey.establecimiento:
        return 'Establecimiento';
      case CucumberStageKey.vegetativo:
        return 'Vegetativo';
      case CucumberStageKey.floracion:
        return 'Floración';
      case CucumberStageKey.cuajado:
        return 'Cuajado';
      case CucumberStageKey.llenado:
        return 'Llenado';
      case CucumberStageKey.cosechaProgresiva:
        return 'Cosecha progresiva';
      case CucumberStageKey.finCiclo:
        return 'Fin de ciclo';
    }
  }

  static String productiveStateLabelEs(CucumberStageKey state) {
    switch (state) {
      case CucumberStageKey.floracion:
        return 'Floración activa';
      case CucumberStageKey.cuajado:
        return 'Cuajado activo';
      case CucumberStageKey.llenado:
        return 'Llenado activo';
      case CucumberStageKey.cosechaProgresiva:
        return 'Cosecha activa';
      default:
        return '';
    }
  }

  static (double, double) _heightPctBounds(CucumberStageKey stage) {
    switch (stage) {
      case CucumberStageKey.germinacion:
        return (0.00, 0.03);
      case CucumberStageKey.establecimiento:
        return (0.03, 0.18);
      case CucumberStageKey.vegetativo:
        return (0.18, 0.60);
      case CucumberStageKey.floracion:
        return (0.60, 0.78);
      case CucumberStageKey.cuajado:
        return (0.78, 0.90);
      case CucumberStageKey.llenado:
        return (0.90, 0.97);
      case CucumberStageKey.cosechaProgresiva:
        return (0.97, 1.00);
      case CucumberStageKey.finCiclo:
        return (1.00, 1.00);
    }
  }

  static List<SeedWindowKey> _windows(CucumberStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];

    final nutritionHeavy = stage == CucumberStageKey.establecimiento ||
        stage == CucumberStageKey.vegetativo ||
        stage == CucumberStageKey.floracion ||
        stage == CucumberStageKey.cuajado ||
        stage == CucumberStageKey.llenado ||
        stage == CucumberStageKey.cosechaProgresiva;

    if (nutritionHeavy) windows.add(SeedWindowKey.nutrition);

    if (stage == CucumberStageKey.floracion ||
        stage == CucumberStageKey.cuajado) {
      windows.add(SeedWindowKey.critical);
    }

    return windows;
  }

  static List<CucumberStageBounds> _buildBounds(
    CucumberProfile profile,
    CucumberEstablishmentMode mode,
  ) {
    final bool isDirectSeed = mode == CucumberEstablishmentMode.directSeed;

    // Trasplante: la fase de germinación ya ocurrió fuera del lote.
    // Siembra directa: emergencia real en campo.
    final int germEnd = isDirectSeed ? 6 : 1;
    final int establishmentEnd = isDirectSeed ? 14 : 10;

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
    // Pepino cuaja y llena rápido: ventana de cuajado ~5 d antes de cosecha.
    final cuajadoEnd = _clampInt(
      harvestStart - 5,
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

    return <CucumberStageBounds>[
      CucumberStageBounds(
        key: CucumberStageKey.germinacion,
        startDay: 1,
        endDay: germEnd,
      ),
      CucumberStageBounds(
        key: CucumberStageKey.establecimiento,
        startDay: germEnd + 1,
        endDay: establishmentEnd,
      ),
      CucumberStageBounds(
        key: CucumberStageKey.vegetativo,
        startDay: establishmentEnd + 1,
        endDay: vegEnd,
      ),
      CucumberStageBounds(
        key: CucumberStageKey.floracion,
        startDay: floweringStart,
        endDay: floweringEnd,
      ),
      CucumberStageBounds(
        key: CucumberStageKey.cuajado,
        startDay: cuajadoStart,
        endDay: cuajadoEnd,
      ),
      CucumberStageBounds(
        key: CucumberStageKey.llenado,
        startDay: llenadoStart,
        endDay: llenadoEnd,
      ),
      CucumberStageBounds(
        key: CucumberStageKey.cosechaProgresiva,
        startDay: cosechaStart,
        endDay: _endAtLeast(cosechaEnd, cosechaStart),
      ),
      CucumberStageBounds(
        key: CucumberStageKey.finCiclo,
        startDay: endWindowStart,
        endDay: endWindowEnd,
      ),
    ];
  }

  /// Calcula estado productivo complementario (traslape).
  ///
  /// Pepino indeterminado (PE-02, PE-03) tiene traslape estructural:
  /// durante cuajado/llenado/cosecha conviven otras etapas productivas en
  /// nudos superiores. PE-01 y PE-04 (determinados) también muestran
  /// traslape menor en cosecha.
  static CucumberStageKey? _productiveStateFor(CucumberStageKey dominant) {
    switch (dominant) {
      case CucumberStageKey.cuajado:
        return CucumberStageKey.floracion;
      case CucumberStageKey.llenado:
        return CucumberStageKey.cuajado;
      case CucumberStageKey.cosechaProgresiva:
        return CucumberStageKey.llenado;
      default:
        return null;
    }
  }

  static CucumberStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CucumberProfile profile,
    CucumberEstablishmentMode? establishmentMode,
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

    CucumberStageBounds current = bounds.first;
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

    final floweringBandShifted = RangeInt(
      profile.floweringDays.min,
      profile.floweringDays.max,
    );
    final harvestStartBandShifted = RangeInt(
      profile.harvestStartDays.min,
      profile.harvestStartDays.max,
    );
    final endBandShifted = RangeInt(
      profile.endWindowDays.min,
      profile.endWindowDays.max,
    );

    final expectedEnd = endBandShifted.mid;
    final remaining = (expectedEnd - effectiveDay).clamp(0, 999999);

    final productive = _productiveStateFor(current.key);

    return CucumberStageResult(
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

  static String _helperCaption(CucumberStageKey s) {
    switch (s) {
      case CucumberStageKey.germinacion:
        return 'Plántula iniciando. '
            'Suelo cálido (21–30 °C) y humedad uniforme. EC baja.';
      case CucumberStageKey.establecimiento:
        return 'Anclaje radical y arranque vegetativo. '
            'P starter y temperatura de suelo estable.';
      case CucumberStageKey.vegetativo:
        return 'Desarrollo de guía y follaje. '
            'N moderado-alto; preparar tutorado en indeterminados.';
      case CucumberStageKey.floracion:
        return 'Aparición de flores y primeros frutos. '
            'Sensibilidad a estrés hídrico. K empieza a subir.';
      case CucumberStageKey.cuajado:
        return 'Cuajado de frutos. Cucurbitácea muy hídrica: '
            'humedad estable y K en ascenso. Vigilar oídio.';
      case CucumberStageKey.llenado:
        return 'Llenado rápido de frutos. Demanda alta de K y agua. '
            'N en descenso gradual; corte cada 2-3 días.';
      case CucumberStageKey.cosechaProgresiva:
        return 'Cosecha continua con floración superior activa. '
            'Mantener K y humedad para evitar amargor y deformidad.';
      case CucumberStageKey.finCiclo:
        return 'Cierre de ciclo: cae rendimiento y aumenta presión sanitaria. '
            'Reducir riego y planificar cierre.';
    }
  }
}
