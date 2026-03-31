import 'dart:math' as math;

import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/widgets/seeds/barley_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class BarleyCropEngineAdapter implements CropEngine {
  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    final barleyProfile = profile as BarleyProfile;
    final daySince = today.difference(sowingDate).inDays + 1;
    final effectiveDay = (daySince + stressDelayDays).clamp(1, 999999);

    final bounds = _bounds(barleyProfile);
    final current = bounds.firstWhere(
      (b) => b.contains(effectiveDay),
      orElse: () => bounds.last,
    );
    final expectedEnd = math.max(1, barleyProfile.endWindowDays.mid);
    final remaining = (expectedEnd - effectiveDay).clamp(0, 999999);
    final span = math.max(1, current.endDay - current.startDay + 1);
    final stageProgressPct = ((effectiveDay - current.startDay + 1) / span)
        .clamp(0.0, 1.0);

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

  static List<BarleyStageBounds> _bounds(BarleyProfile p) {
    final germEnd = math.max(1, p.germinationDays.max);
    final emergEnd = math.max(germEnd + 1, p.emergenceDays.max);
    final vegEnd = math.max(emergEnd + 1, p.vegEarlyDays.max);
    final flowerStart = math.max(vegEnd + 4, p.floweringDays.min);
    final flowerEnd = math.max(flowerStart, p.floweringDays.max);
    final endStart = math.max(flowerEnd + 1, p.endWindowDays.min);

    final midRange = math.max(4, flowerStart - vegEnd);
    final tillerEnd = vegEnd + (midRange * 0.35).round();
    final elongEnd = vegEnd + (midRange * 0.58).round();
    final bootEnd = vegEnd + (midRange * 0.78).round();
    final headEnd = math.max(bootEnd + 1, flowerStart - 1);

    final postFlower = math.max(3, endStart - flowerEnd);
    final grainEnd = flowerEnd + (postFlower * 0.60).round();
    final matEnd = math.max(grainEnd + 1, endStart - 1);

    return <BarleyStageBounds>[
      BarleyStageBounds(
        key: BarleyStageKey.germination,
        startDay: 1,
        endDay: germEnd,
      ),
      BarleyStageBounds(
        key: BarleyStageKey.emergence,
        startDay: germEnd + 1,
        endDay: emergEnd,
      ),
      BarleyStageBounds(
        key: BarleyStageKey.vegEarly,
        startDay: emergEnd + 1,
        endDay: vegEnd,
      ),
      BarleyStageBounds(
        key: BarleyStageKey.tillering,
        startDay: vegEnd + 1,
        endDay: math.max(vegEnd + 1, tillerEnd),
      ),
      BarleyStageBounds(
        key: BarleyStageKey.elongation,
        startDay: math.max(vegEnd + 2, tillerEnd + 1),
        endDay: math.max(math.max(vegEnd + 2, tillerEnd + 1), elongEnd),
      ),
      BarleyStageBounds(
        key: BarleyStageKey.booting,
        startDay: math.max(vegEnd + 3, elongEnd + 1),
        endDay: math.max(math.max(vegEnd + 3, elongEnd + 1), bootEnd),
      ),
      BarleyStageBounds(
        key: BarleyStageKey.heading,
        startDay: math.max(vegEnd + 4, bootEnd + 1),
        endDay: math.max(math.max(vegEnd + 4, bootEnd + 1), headEnd),
      ),
      BarleyStageBounds(
        key: BarleyStageKey.flowering,
        startDay: math.max(headEnd + 1, flowerStart),
        endDay: flowerEnd,
      ),
      BarleyStageBounds(
        key: BarleyStageKey.grainFill,
        startDay: flowerEnd + 1,
        endDay: math.max(flowerEnd + 1, grainEnd),
      ),
      BarleyStageBounds(
        key: BarleyStageKey.physiologicalMaturity,
        startDay: math.max(flowerEnd + 2, grainEnd + 1),
        endDay: math.max(math.max(flowerEnd + 2, grainEnd + 1), matEnd),
      ),
      BarleyStageBounds(
        key: BarleyStageKey.harvest,
        startDay: math.max(matEnd + 1, endStart),
        endDay: math.max(math.max(matEnd + 1, endStart), p.endWindowDays.max),
      ),
    ];
  }

  static String _labelEs(BarleyStageKey stage) {
    switch (stage) {
      case BarleyStageKey.germination:
        return 'Germinación';
      case BarleyStageKey.emergence:
        return 'Emergencia';
      case BarleyStageKey.vegEarly:
        return 'Vegetativa temprana';
      case BarleyStageKey.tillering:
        return 'Macollamiento';
      case BarleyStageKey.elongation:
        return 'Encañe';
      case BarleyStageKey.booting:
        return 'Embuchamiento';
      case BarleyStageKey.heading:
        return 'Espigamiento';
      case BarleyStageKey.flowering:
        return 'Floración / antesis';
      case BarleyStageKey.grainFill:
        return 'Llenado de grano';
      case BarleyStageKey.physiologicalMaturity:
        return 'Madurez fisiológica';
      case BarleyStageKey.harvest:
        return 'Cosecha';
    }
  }

  static String _heroAsset(BarleyStageKey stage) {
    switch (stage) {
      case BarleyStageKey.germination:
        return 'assets/seeds/barley/barley_stage_germination.png';
      case BarleyStageKey.emergence:
        return 'assets/seeds/barley/barley_stage_emergence.png';
      case BarleyStageKey.vegEarly:
        return 'assets/seeds/barley/barley_stage_veg_early.png';
      case BarleyStageKey.tillering:
        return 'assets/seeds/barley/barley_stage_veg_mid.png';
      case BarleyStageKey.elongation:
      case BarleyStageKey.booting:
        return 'assets/seeds/barley/barley_stage_tasseling.png';
      case BarleyStageKey.heading:
      case BarleyStageKey.flowering:
        return 'assets/seeds/barley/barley_stage_flower_set.png';
      case BarleyStageKey.grainFill:
        return 'assets/seeds/barley/barley_stage_maturity_senescence.png';
      case BarleyStageKey.physiologicalMaturity:
        return 'assets/seeds/barley/barley_stage_maturity_senescence.png';
      case BarleyStageKey.harvest:
        return 'assets/seeds/barley/barley_stage_harvest.png';
    }
  }

  static List<SeedWindowKey> _windows(BarleyStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];
    final nutritionHeavy =
        stage == BarleyStageKey.tillering ||
        stage == BarleyStageKey.elongation ||
        stage == BarleyStageKey.booting ||
        stage == BarleyStageKey.heading ||
        stage == BarleyStageKey.flowering ||
        stage == BarleyStageKey.grainFill;
    if (nutritionHeavy) windows.add(SeedWindowKey.nutrition);
    if (stage == BarleyStageKey.booting ||
        stage == BarleyStageKey.heading ||
        stage == BarleyStageKey.flowering) {
      windows.add(SeedWindowKey.critical);
    }
    return windows;
  }

  static String _helperCaption(BarleyStageKey stage) {
    switch (stage) {
      case BarleyStageKey.germination:
        return 'Mantén humedad constante. Temp suelo >4 °C para germinar, óptimo 12-25 °C.';
      case BarleyStageKey.emergence:
        return 'Vigila costra superficial. Cebada emerge rápido con buen contacto suelo-semilla.';
      case BarleyStageKey.vegEarly:
        return 'Inicio de macollamiento — N disponible define potencial de macollos.';
      case BarleyStageKey.tillering:
        return 'Macollamiento activo. Aplicación de N fraccionada. Cebada macolla más que trigo.';
      case BarleyStageKey.elongation:
        return 'Encañe — demanda hídrica sube. Vigila roya y oídio.';
      case BarleyStageKey.booting:
        return 'Embuchamiento — etapa crítica. Estrés reduce espigas fértiles.';
      case BarleyStageKey.heading:
        return 'Espigamiento — sensible a heladas y estrés hídrico.';
      case BarleyStageKey.flowering:
        return 'Antesis — cebada autógama, pero sensible a calor extremo.';
      case BarleyStageKey.grainFill:
        return 'Llenado de grano — mantén humedad. En maltera, evita N excesivo.';
      case BarleyStageKey.physiologicalMaturity:
        return 'Madurez fisiológica — reduce riego. Grano secando en planta.';
      case BarleyStageKey.harvest:
        return 'Cosecha — humedad de grano <13% ideal. Maltera requiere uniformidad.';
    }
  }
}
