import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/squash_models.dart';

/// Motor fenológico de calabaza.
///
/// Resuelve la etapa BIO-G a partir de fecha de siembra/trasplante,
/// modo de establecimiento, perfil CA-XX y un retraso opcional por
/// estrés acumulado (regla del Perfil Universal v2 §11).
///
/// Nota sobre assets:
/// Calabaza ya tiene PNGs dedicados para todas sus etapas BIO-G:
/// germinación, establecimiento, vegetativo, floración, cuajado,
/// llenado, cosecha progresiva y senescencia.
class SquashEngine {
  static const int _seedGerminationEndDay = 10;
  static const int _seedEstablishmentEndDay = 28;
  static const int _transplantEstablishmentEndDay = 18;
  static const int _seedFloweringStartOffsetDays = 0;
  static const int _seedFloweringEndOffsetDays = 0;
  static const int _seedHarvestStartOffsetDays = 0;
  static const int _seedHarvestEndOffsetDays = 0;
  static const int _seedEndWindowOffsetDays = 0;

  // ───────────────────────────────────────────────────────────────────
  // Asset paths definitivos disponibles hoy. La carpeta real es `Squash`.
  // ───────────────────────────────────────────────────────────────────
  static const String _stageGerm =
      'assets/seeds/Squash/squash_stage_germination.png';
  static const String _stageEstab =
      'assets/seeds/Squash/squash_stage_establishment.png';
  static const String _stageVeg =
      'assets/seeds/Squash/squash_stage_vegetative.png';
  static const String _stageFlower =
      'assets/seeds/Squash/squash_stage_flowering.png';
  static const String _stageFruitSet =
      'assets/seeds/Squash/squash_stage_fruit_set.png';
  static const String _stageFruitFill =
      'assets/seeds/Squash/squash_stage_fruit_fill.png';
  static const String _stageFruitHarvest =
      'assets/seeds/Squash/squash_stage_progressive_harvest.png';
  static const String _stageSenescence =
      'assets/seeds/Squash/squash_stage_senescence.png';

  static const List<String> availableStageAssets = <String>[
    _stageGerm,
    _stageEstab,
    _stageVeg,
    _stageFlower,
    _stageFruitSet,
    _stageFruitFill,
    _stageFruitHarvest,
    _stageSenescence,
  ];

  /// Devuelve el asset visible para una etapa fenológica de calabaza.
  static String heroAssetForStage(SquashStageKey stage) {
    switch (stage) {
      case SquashStageKey.germinacion:
        return _stageGerm;
      case SquashStageKey.establecimiento:
        return _stageEstab;
      case SquashStageKey.vegetativo:
        return _stageVeg;
      case SquashStageKey.floracion:
        return _stageFlower;
      case SquashStageKey.cuajado:
        return _stageFruitSet;
      case SquashStageKey.llenado:
        return _stageFruitFill;
      case SquashStageKey.cosechaProgresiva:
        return _stageFruitHarvest;
      case SquashStageKey.finCiclo:
        return _stageSenescence;
    }
  }

  static String labelEs(SquashStageKey stage) {
    switch (stage) {
      case SquashStageKey.germinacion:
        return 'Germinación';
      case SquashStageKey.establecimiento:
        return 'Emergencia / establecimiento';
      case SquashStageKey.vegetativo:
        return 'Desarrollo vegetativo';
      case SquashStageKey.floracion:
        return 'Floración';
      case SquashStageKey.cuajado:
        return 'Cuajado / polinización';
      case SquashStageKey.llenado:
        return 'Desarrollo de fruto';
      case SquashStageKey.cosechaProgresiva:
        return 'Cosecha';
      case SquashStageKey.finCiclo:
        return 'Fin de ciclo / senescencia';
    }
  }

  static String productiveStateLabelEs(SquashStageKey state) {
    switch (state) {
      case SquashStageKey.floracion:
        return 'Floración activa';
      case SquashStageKey.cuajado:
        return 'Cuajado activo';
      case SquashStageKey.llenado:
        return 'Llenado activo';
      case SquashStageKey.cosechaProgresiva:
        return 'Cosecha activa';
      default:
        return '';
    }
  }

  static (double, double) _heightPctBounds(SquashStageKey stage) {
    switch (stage) {
      case SquashStageKey.germinacion:
        return (0.00, 0.05);
      case SquashStageKey.establecimiento:
        return (0.05, 0.25);
      case SquashStageKey.vegetativo:
        return (0.25, 0.70);
      case SquashStageKey.floracion:
        return (0.70, 0.85);
      case SquashStageKey.cuajado:
        return (0.85, 0.93);
      case SquashStageKey.llenado:
        return (0.93, 0.98);
      case SquashStageKey.cosechaProgresiva:
        return (0.98, 1.00);
      case SquashStageKey.finCiclo:
        return (1.00, 1.00);
    }
  }

  static List<SeedWindowKey> _windows(SquashStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];

    final nutritionActive =
        stage == SquashStageKey.establecimiento ||
        stage == SquashStageKey.vegetativo ||
        stage == SquashStageKey.floracion ||
        stage == SquashStageKey.cuajado ||
        stage == SquashStageKey.llenado ||
        stage == SquashStageKey.cosechaProgresiva;

    if (nutritionActive) {
      windows.add(SeedWindowKey.nutrition);
    }

    if (stage == SquashStageKey.floracion || stage == SquashStageKey.cuajado) {
      windows.add(SeedWindowKey.critical);
    }

    return windows;
  }

  static List<SquashStageBounds> _buildBounds(
    SquashProfile profile,
    SquashEstablishmentMode mode,
  ) {
    final isSeed =
        mode == SquashEstablishmentMode.seed ||
        mode == SquashEstablishmentMode.unknown;

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
    final int establishmentEnd = isSeed
        ? _seedEstablishmentEndDay
        : _transplantEstablishmentEndDay;

    final floweringStart = math.max(floweringBand.min, establishmentEnd + 1);
    final vegEnd = _clampInt(
      floweringStart - 1,
      min: establishmentEnd + 1,
      max: math.max(establishmentEnd + 1, floweringStart - 1),
    );

    final floweringEnd = _endAtLeast(floweringBand.max, floweringStart);

    final harvestStart = math.max(harvestBand.min, floweringEnd + 1);
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
    final endWindowStart = math.max(endBand.min, cosechaStart);
    final endWindowEnd = _endAtLeast(endBand.max, endWindowStart);
    final cosechaEnd = math.max(cosechaStart, endWindowStart - 1);

    final bounds = <SquashStageBounds>[];

    if (isSeed) {
      bounds.add(
        SquashStageBounds(
          key: SquashStageKey.germinacion,
          startDay: 1,
          endDay: _seedGerminationEndDay,
        ),
      );
    }

    bounds.addAll(<SquashStageBounds>[
      SquashStageBounds(
        key: SquashStageKey.establecimiento,
        startDay: establishmentStart,
        endDay: establishmentEnd,
      ),
      SquashStageBounds(
        key: SquashStageKey.vegetativo,
        startDay: establishmentEnd + 1,
        endDay: vegEnd,
      ),
      SquashStageBounds(
        key: SquashStageKey.floracion,
        startDay: floweringStart,
        endDay: floweringEnd,
      ),
      SquashStageBounds(
        key: SquashStageKey.cuajado,
        startDay: cuajadoStart,
        endDay: cuajadoEnd,
      ),
      SquashStageBounds(
        key: SquashStageKey.llenado,
        startDay: llenadoStart,
        endDay: llenadoEnd,
      ),
      SquashStageBounds(
        key: SquashStageKey.cosechaProgresiva,
        startDay: cosechaStart,
        endDay: _endAtLeast(cosechaEnd, cosechaStart),
      ),
      SquashStageBounds(
        key: SquashStageKey.finCiclo,
        startDay: endWindowStart,
        endDay: endWindowEnd,
      ),
    ]);

    return bounds;
  }

  static SquashStageKey? _productiveStateFor(SquashStageKey dominant) {
    switch (dominant) {
      case SquashStageKey.cuajado:
        return SquashStageKey.floracion;
      case SquashStageKey.llenado:
        return SquashStageKey.cuajado;
      case SquashStageKey.cosechaProgresiva:
        return SquashStageKey.llenado;
      default:
        return null;
    }
  }

  static SquashStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required SquashProfile profile,
    SquashEstablishmentMode? establishmentMode,
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
    SquashStageBounds current = bounds.first;
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

    return SquashStageResult(
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

  static int _endAtLeast(int end, int start) => end < start ? start : end;

  static RangeInt _bandForMode(
    RangeInt band,
    SquashEstablishmentMode mode, {
    required int seedStartOffset,
    required int seedEndOffset,
  }) {
    if (mode == SquashEstablishmentMode.transplant) {
      return RangeInt(math.max(1, band.min - 7), math.max(1, band.max - 7));
    }
    return RangeInt(band.min + seedStartOffset, band.max + seedEndOffset);
  }

  /// Caption diferente según destino (tierno / maduro / pepita).
  ///
  /// CA-GEN entrega lectura "flexible": si el usuario no confirma corte
  /// tierno, deja abierta la ruta de fruto maduro sin reiniciar.
  static String _helperCaption(SquashStageKey stage, SquashProfile profile) {
    final isSeed = profile.isSeedFocused;
    final isMature = profile.squashUseType == SquashUseType.fruitMature;
    final isFlexible = profile.squashUseType == SquashUseType.flexible;
    final extra = isFlexible
        ? ' Sigue como CA-GEN: si después confirmas tierno, maduro o pepita, el historial no se reinicia.'
        : '';

    switch (stage) {
      case SquashStageKey.germinacion:
        return 'Suelo cálido y humedad pareja. Calabaza es de estación cálida y germina lento bajo 15-16 °C.$extra';
      case SquashStageKey.establecimiento:
        return 'Cuida raíz, drenaje y compactación. Cucurbitáceas resienten anoxia temprana más que falta de fertilizante.';
      case SquashStageKey.vegetativo:
        return 'Construir guía y hoja. N suficiente, pero sin exceder: la planta puede frenar floración si se va a follaje.';
      case SquashStageKey.floracion:
        return 'Ventana crítica: aparecen flores macho y luego hembra. Calor, lluvia y baja actividad de abejas reducen cuajado.';
      case SquashStageKey.cuajado:
        return 'El amarre depende de polinización efectiva. Agua estable y K al alza; N exagerado castiga el cuaje.';
      case SquashStageKey.llenado:
        if (isSeed) {
          return 'CA-07: el órgano objetivo es la pepita. K y agua estable mandan; Mg/S quedan como contexto de balance. N alto al final castiga la semilla.';
        }
        return 'K manda llenado y calidad. Riego constante y sanidad foliar protegen peso, color y vida de almacén.';
      case SquashStageKey.cosechaProgresiva:
        if (isSeed) {
          return 'CA-07: cosecha cuando el fruto madure y la pepita esté firme. Manejo de secado y separación importa.';
        }
        if (isMature) {
          return 'Cosecha de fruto maduro: cáscara endurecida y planta cerrando. Cuida lluvia y contacto con suelo húmedo.';
        }
        return 'Cosecha progresiva: cortar tierno cada 2-3 días sostiene calidad y continuidad de producción.';
      case SquashStageKey.finCiclo:
        return 'Cierre y aprendizaje. Documenta sanidad, rendimiento y notas para ajustar el próximo ciclo.';
    }
  }
}
