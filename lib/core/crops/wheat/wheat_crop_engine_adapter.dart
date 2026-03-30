import 'dart:math' as math;

import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/wheat_models.dart';

class WheatCropEngineAdapter implements CropEngine {
  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final wheatProfile = profile as WheatProfile;
    final daySince = today.difference(sowingDate).inDays + 1;
    final effectiveDay = (daySince + stressDelayDays).clamp(1, 999999);

    final bounds = _bounds(wheatProfile);
    final current = bounds.firstWhere(
      (b) => b.contains(effectiveDay),
      orElse: () => bounds.last,
    );
    final expectedEnd = math.max(1, wheatProfile.endWindowDays.mid);
    final remaining = (expectedEnd - effectiveDay).clamp(0, 999999);
    final span = math.max(1, current.endDay - current.startDay + 1);
    final stageProgressPct =
        ((effectiveDay - current.startDay + 1) / span).clamp(0.0, 1.0);

    return CropStageResult(
      stageKey: current.key.name,
      stageLabelEs: _labelEs(current.key),
      expectedDaysToEnd: remaining,
      windowsNow: _windows(current.key),
      heroAsset: _heroAsset(current.key),
      helperCaption: _helperCaption(current.key),
      daySinceSowing: daySince,
      stageProgressPct: stageProgressPct,
    );
  }

  static List<WheatStageBounds> _bounds(WheatProfile p) {
    final germEnd = math.max(1, p.germinationDays.max);
    final emergEnd = math.max(germEnd + 1, p.emergenceDays.max);
    final vegEnd = math.max(emergEnd + 1, p.vegEarlyDays.max);
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

    return <WheatStageBounds>[
      WheatStageBounds(
        key: WheatStageKey.germination,
        startDay: 1,
        endDay: germEnd,
      ),
      WheatStageBounds(
        key: WheatStageKey.emergence,
        startDay: germEnd + 1,
        endDay: emergEnd,
      ),
      WheatStageBounds(
        key: WheatStageKey.vegEarly,
        startDay: emergEnd + 1,
        endDay: vegEnd,
      ),
      WheatStageBounds(
        key: WheatStageKey.tillering,
        startDay: vegEnd + 1,
        endDay: math.max(vegEnd + 1, tillerEnd),
      ),
      WheatStageBounds(
        key: WheatStageKey.elongation,
        startDay: math.max(vegEnd + 2, tillerEnd + 1),
        endDay: math.max(math.max(vegEnd + 2, tillerEnd + 1), elongEnd),
      ),
      WheatStageBounds(
        key: WheatStageKey.booting,
        startDay: math.max(vegEnd + 3, elongEnd + 1),
        endDay: math.max(math.max(vegEnd + 3, elongEnd + 1), bootEnd),
      ),
      WheatStageBounds(
        key: WheatStageKey.heading,
        startDay: math.max(vegEnd + 4, bootEnd + 1),
        endDay: math.max(math.max(vegEnd + 4, bootEnd + 1), headEnd),
      ),
      WheatStageBounds(
        key: WheatStageKey.flowering,
        startDay: math.max(headEnd + 1, flowerStart),
        endDay: flowerEnd,
      ),
      WheatStageBounds(
        key: WheatStageKey.grainFill,
        startDay: flowerEnd + 1,
        endDay: math.max(flowerEnd + 1, grainEnd),
      ),
      WheatStageBounds(
        key: WheatStageKey.physiologicalMaturity,
        startDay: math.max(flowerEnd + 2, grainEnd + 1),
        endDay: math.max(math.max(flowerEnd + 2, grainEnd + 1), matEnd),
      ),
      WheatStageBounds(
        key: WheatStageKey.harvest,
        startDay: math.max(matEnd + 1, endStart),
        endDay: math.max(math.max(matEnd + 1, endStart), p.endWindowDays.max),
      ),
    ];
  }

  static String _labelEs(WheatStageKey stage) {
    switch (stage) {
      case WheatStageKey.germination:
        return 'Germinación';
      case WheatStageKey.emergence:
        return 'Emergencia';
      case WheatStageKey.vegEarly:
        return 'Vegetativa temprana';
      case WheatStageKey.tillering:
        return 'Macollamiento';
      case WheatStageKey.elongation:
        return 'Encañe';
      case WheatStageKey.booting:
        return 'Embuchamiento';
      case WheatStageKey.heading:
        return 'Espigamiento';
      case WheatStageKey.flowering:
        return 'Floración / antesis';
      case WheatStageKey.grainFill:
        return 'Llenado de grano';
      case WheatStageKey.physiologicalMaturity:
        return 'Madurez fisiológica';
      case WheatStageKey.harvest:
        return 'Cosecha';
    }
  }

  static String _heroAsset(WheatStageKey stage) {
    switch (stage) {
      case WheatStageKey.germination:
        return 'assets/seeds/wheat/wheat_stage_germination.png';
      case WheatStageKey.emergence:
        return 'assets/seeds/wheat/wheat_stage_emergence.png';
      case WheatStageKey.vegEarly:
        return 'assets/seeds/wheat/wheat_stage_veg_early.png';
      case WheatStageKey.tillering:
        return 'assets/seeds/wheat/wheat_stage_veg_mid.png';
      case WheatStageKey.elongation:
      case WheatStageKey.booting:
        return 'assets/seeds/wheat/wheat_stage_tasseling.png';
      case WheatStageKey.heading:
      case WheatStageKey.flowering:
        return 'assets/seeds/wheat/wheat_stage_flower_set.png';
      case WheatStageKey.grainFill:
        return 'assets/seeds/wheat/wheat_stage_veg_advanced.png';
      case WheatStageKey.physiologicalMaturity:
        return 'assets/seeds/wheat/wheat_stage_maturity_senescence.png';
      case WheatStageKey.harvest:
        return 'assets/seeds/wheat/wheat_stage_harvest.png';
    }
  }

  static List<SeedWindowKey> _windows(WheatStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];
    final nutritionHeavy =
        stage == WheatStageKey.tillering ||
        stage == WheatStageKey.elongation ||
        stage == WheatStageKey.booting ||
        stage == WheatStageKey.heading ||
        stage == WheatStageKey.flowering ||
        stage == WheatStageKey.grainFill;
    if (nutritionHeavy) windows.add(SeedWindowKey.nutrition);
    if (stage == WheatStageKey.booting ||
        stage == WheatStageKey.heading ||
        stage == WheatStageKey.flowering ||
        stage == WheatStageKey.grainFill) {
      windows.add(SeedWindowKey.critical);
    }
    return windows;
  }

  static String _helperCaption(WheatStageKey stage) {
    switch (stage) {
      case WheatStageKey.germination:
        return 'Mantén humedad constante para imbibición. Temp suelo >10 °C acelera emergencia.';
      case WheatStageKey.emergence:
        return 'Vigila costra superficial. Plántula sensible a salinidad.';
      case WheatStageKey.vegEarly:
        return 'Inicio de macollamiento — N disponible define potencial de macollos.';
      case WheatStageKey.tillering:
        return 'Macollamiento activo. Aplicación de N fraccionada. Monitorea compactación.';
      case WheatStageKey.elongation:
        return 'Encañe — demanda hídrica sube. Vigila enfermedades foliares.';
      case WheatStageKey.booting:
        return 'Embuchamiento — etapa crítica. Estrés aquí reduce espigas fértiles.';
      case WheatStageKey.heading:
        return 'Espigamiento — máxima sensibilidad a heladas y estrés hídrico.';
      case WheatStageKey.flowering:
        return 'Antesis — polinización activa. Evita estrés térmico e hídrico.';
      case WheatStageKey.grainFill:
        return 'Llenado de grano — mantén humedad. Calor excesivo reduce peso de grano.';
      case WheatStageKey.physiologicalMaturity:
        return 'Madurez fisiológica — reduce riego. Grano secando en planta.';
      case WheatStageKey.harvest:
        return 'Cosecha — humedad de grano <14% ideal. Evita lluvias post-madurez.';
    }
  }
}
