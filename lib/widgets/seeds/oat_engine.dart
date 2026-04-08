// lib/widgets/seeds/oat_engine.dart
// Motor fenológico puro para avena. Mantiene el mismo patrón que maize/bean,
// y concentra stage, label, ventanas y heroAsset en un solo punto.

import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/oat_models.dart';

class OatEngine {
  OatEngine._();

  static OatStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required OatProfile profile,
    int stressDelayDays = 0,
  }) {
    final daySinceSowing = math.max(1, today.difference(sowingDate).inDays + 1);
    final effectiveDay = math.max(1, daySinceSowing + stressDelayDays);

    final stage = _resolveStage(profile, effectiveDay);
    final expectedFloweringDay = profile.floweringDays.mid;
    final expectedEndDay = profile.endWindowDays.mid;
    final expectedDaysToEnd = math.max(0, expectedEndDay - effectiveDay);

    final bounds = _bounds(profile);
    final currentBounds = bounds.firstWhere(
      (b) => b.contains(effectiveDay),
      orElse: () => bounds.last,
    );

    final stageSpan = math.max(
      1,
      currentBounds.endDay - currentBounds.startDay + 1,
    );
    final stageProgressPct =
        ((effectiveDay - currentBounds.startDay + 1) / stageSpan).clamp(
          0.0,
          1.0,
        );

    return OatStageResult(
      profile: profile,
      stage: stage,
      daySinceSowing: daySinceSowing,
      floweringBand: profile.floweringDays,
      endBand: profile.endWindowDays,
      expectedFloweringDay: expectedFloweringDay,
      expectedEndDay: expectedEndDay,
      expectedDaysToEnd: expectedDaysToEnd,
      stageProgressPct: stageProgressPct,
      windowsNow: _windows(stage),
      expectedPlantHeightTodayM: _heightForStage(
        profile,
        stage,
        stageProgressPct,
      ),
      stageLabelEs: _labelEs(stage),
      heroAsset: _heroAsset(stage),
      helperCaption: _helperCaption(profile, stage),
    );
  }

  static List<OatStageBounds> _bounds(OatProfile p) {
    final germStart = 1;
    final germEnd = p.germinationDays.max;
    final emergStart = germEnd + 1;
    final emergEnd = math.max(emergStart, p.emergenceDays.max);
    final vegStart = emergEnd + 1;
    final vegEnd = math.max(vegStart, p.vegEarlyDays.max);

    final flowerStart = math.max(vegEnd + 4, p.floweringDays.min);
    final flowerEnd = math.max(flowerStart, p.floweringDays.max);
    final endStart = math.max(flowerEnd + 1, p.endWindowDays.min);

    final midRange = math.max(4, flowerStart - vegEnd);
    final tillerEnd = vegEnd + (midRange * 0.30).round();
    final elongEnd = vegEnd + (midRange * 0.55).round();
    final bootEnd = vegEnd + (midRange * 0.75).round();
    final headEnd = math.max(bootEnd + 1, flowerStart - 1);

    final postFlower = math.max(3, endStart - flowerEnd);
    final grainEnd = flowerEnd + (postFlower * 0.65).round();
    final matEnd = math.max(grainEnd + 1, endStart - 1);

    return [
      OatStageBounds(
        key: OatStageKey.germination,
        startDay: germStart,
        endDay: germEnd,
      ),
      OatStageBounds(
        key: OatStageKey.emergence,
        startDay: emergStart,
        endDay: emergEnd,
      ),
      OatStageBounds(
        key: OatStageKey.vegEarly,
        startDay: vegStart,
        endDay: vegEnd,
      ),
      OatStageBounds(
        key: OatStageKey.tillering,
        startDay: vegEnd + 1,
        endDay: math.max(vegEnd + 1, tillerEnd),
      ),
      OatStageBounds(
        key: OatStageKey.elongation,
        startDay: math.max(vegEnd + 2, tillerEnd + 1),
        endDay: math.max(math.max(vegEnd + 2, tillerEnd + 1), elongEnd),
      ),
      OatStageBounds(
        key: OatStageKey.booting,
        startDay: math.max(vegEnd + 3, elongEnd + 1),
        endDay: math.max(math.max(vegEnd + 3, elongEnd + 1), bootEnd),
      ),
      OatStageBounds(
        key: OatStageKey.heading,
        startDay: math.max(vegEnd + 4, bootEnd + 1),
        endDay: math.max(math.max(vegEnd + 4, bootEnd + 1), headEnd),
      ),
      OatStageBounds(
        key: OatStageKey.flowering,
        startDay: math.max(headEnd + 1, flowerStart),
        endDay: flowerEnd,
      ),
      OatStageBounds(
        key: OatStageKey.grainFill,
        startDay: flowerEnd + 1,
        endDay: math.max(flowerEnd + 1, grainEnd),
      ),
      OatStageBounds(
        key: OatStageKey.physiologicalMaturity,
        startDay: math.max(flowerEnd + 2, grainEnd + 1),
        endDay: math.max(math.max(flowerEnd + 2, grainEnd + 1), matEnd),
      ),
      OatStageBounds(
        key: OatStageKey.harvest,
        startDay: math.max(matEnd + 1, endStart),
        endDay: math.max(math.max(matEnd + 1, endStart), p.endWindowDays.max),
      ),
    ];
  }

  static OatStageKey _resolveStage(OatProfile p, int day) {
    for (final b in _bounds(p)) {
      if (b.contains(day)) return b.key;
    }
    return OatStageKey.harvest;
  }

  static RangeDouble _heightForStage(
    OatProfile p,
    OatStageKey stage,
    double progress,
  ) {
    final (double startPct, double endPct) = switch (stage) {
      OatStageKey.germination => (0.00, 0.02),
      OatStageKey.emergence => (0.02, 0.05),
      OatStageKey.vegEarly => (0.05, 0.18),
      OatStageKey.tillering => (0.18, 0.38),
      OatStageKey.elongation => (0.38, 0.65),
      OatStageKey.booting => (0.65, 0.82),
      OatStageKey.heading => (0.82, 0.95),
      OatStageKey.flowering => (0.95, 1.00),
      OatStageKey.grainFill => (0.95, 1.00),
      OatStageKey.physiologicalMaturity => (0.95, 1.00),
      OatStageKey.harvest => (0.95, 1.00),
    };

    final pct = startPct + (endPct - startPct) * progress.clamp(0.0, 1.0);
    return RangeDouble(
      p.plantHeightM.min * pct,
      p.plantHeightM.max * pct,
    );
  }

  static String _labelEs(OatStageKey stage) {
    switch (stage) {
      case OatStageKey.germination:
        return 'Germinación';
      case OatStageKey.emergence:
        return 'Emergencia';
      case OatStageKey.vegEarly:
        return 'Vegetativa temprana';
      case OatStageKey.tillering:
        return 'Macollamiento';
      case OatStageKey.elongation:
        return 'Encañe';
      case OatStageKey.booting:
        return 'Embuchamiento';
      case OatStageKey.heading:
        return 'Espigamiento';
      case OatStageKey.flowering:
        return 'Floración';
      case OatStageKey.grainFill:
        return 'Llenado de grano';
      case OatStageKey.physiologicalMaturity:
        return 'Madurez fisiológica';
      case OatStageKey.harvest:
        return 'Cosecha';
    }
  }

  static String _heroAsset(OatStageKey stage) {
    switch (stage) {
      case OatStageKey.germination:
        return 'assets/seeds/Oat/oat_stage_germination.png';
      case OatStageKey.emergence:
        return 'assets/seeds/Oat/oat_stage_emergence.png';
      case OatStageKey.vegEarly:
        return 'assets/seeds/Oat/oat_stage_veg_early.png';
      case OatStageKey.tillering:
        return 'assets/seeds/Oat/oat_stage_veg_mid.png';
      case OatStageKey.elongation:
        return 'assets/seeds/Oat/oat_stage_veg_advanced.png';
      case OatStageKey.booting:
      case OatStageKey.heading:
        return 'assets/seeds/Oat/oat_stage_tasseling.png';
      case OatStageKey.flowering:
        return 'assets/seeds/Oat/oat_stage_flower_set.png';
      case OatStageKey.grainFill:
      case OatStageKey.physiologicalMaturity:
        return 'assets/seeds/Oat/oat_stage_maturity_senescence.png';
      case OatStageKey.harvest:
        return 'assets/seeds/Oat/oat_stage_harvest.png';
    }
  }

  static List<SeedWindowKey> _windows(OatStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];
    final nutritionHeavy =
        stage == OatStageKey.tillering ||
        stage == OatStageKey.elongation ||
        stage == OatStageKey.booting ||
        stage == OatStageKey.heading ||
        stage == OatStageKey.flowering ||
        stage == OatStageKey.grainFill;
    if (nutritionHeavy) windows.add(SeedWindowKey.nutrition);
    if (stage == OatStageKey.booting ||
        stage == OatStageKey.heading ||
        stage == OatStageKey.flowering) {
      windows.add(SeedWindowKey.critical);
    }
    return windows;
  }

  static String _helperCaption(OatProfile profile, OatStageKey stage) {
    final endAction = profile.endActionLabel.trim().isEmpty
        ? 'corte'
        : profile.endActionLabel.toLowerCase();
    switch (stage) {
      case OatStageKey.germination:
        return 'Validar humedad de arranque y uniformidad de emergencia.';
      case OatStageKey.emergence:
        return 'Verificar establecimiento parejo y daño inicial.';
      case OatStageKey.vegEarly:
        return 'Entrando a crecimiento vegetativo activo.';
      case OatStageKey.tillering:
        return 'Macollamiento: etapa fuerte para nutrición y densidad.';
      case OatStageKey.elongation:
        return 'Encañe: vigilar estrés hídrico y acame.';
      case OatStageKey.booting:
        return 'Embuchamiento: ventana sensible previa a espiga.';
      case OatStageKey.heading:
        return 'Espigamiento: monitoreo cercano de sanidad y estrés.';
      case OatStageKey.flowering:
        return 'Floración: etapa crítica para rendimiento y calidad.';
      case OatStageKey.grainFill:
        return 'Llenado: sostener hoja activa y humedad suficiente.';
      case OatStageKey.physiologicalMaturity:
        return 'Madurez fisiológica: preparar ${endAction}.';
      case OatStageKey.harvest:
        return 'Ventana de ${profile.endActionLabel.isEmpty ? 'cosecha' : profile.endActionLabel.toLowerCase()}.';
    }
  }
}
