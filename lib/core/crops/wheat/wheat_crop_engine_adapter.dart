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

    final stage = _resolveStage(wheatProfile, effectiveDay);
    final expectedEnd = math.max(1, wheatProfile.endWindowDays.mid);
    final remaining = (expectedEnd - effectiveDay).clamp(0, 999999);

    return CropStageResult(
      stageKey: stage.name,
      stageLabelEs: _labelEs(stage),
      expectedDaysToEnd: remaining,
      windowsNow: _windows(stage),
      heroAsset: _heroAsset(stage),
    );
  }

  static WheatStageKey _resolveStage(WheatProfile p, int day) {
    final germEnd = math.max(1, p.germinationDays.max);
    final emergEnd = math.max(germEnd, p.emergenceDays.max);
    final vegEnd = math.max(emergEnd, p.vegEarlyDays.max);
    final flowerStart = math.max(vegEnd + 1, p.floweringDays.min);
    final flowerEnd = math.max(flowerStart, p.floweringDays.max);
    final endStart = math.max(flowerEnd + 1, p.endWindowDays.min);

    if (day <= germEnd) return WheatStageKey.germination;
    if (day <= emergEnd) return WheatStageKey.emergence;
    if (day <= vegEnd) return WheatStageKey.vegEarly;

    final midRange = math.max(1, flowerStart - vegEnd);
    final tillerEnd = math.max(vegEnd, vegEnd + (midRange * 0.30).round());
    final elongEnd = math.max(tillerEnd, vegEnd + (midRange * 0.55).round());
    final bootEnd = math.max(elongEnd, vegEnd + (midRange * 0.75).round());
    final headEnd = math.max(bootEnd, flowerStart - 1);

    if (day <= tillerEnd) return WheatStageKey.tillering;
    if (day <= elongEnd) return WheatStageKey.elongation;
    if (day <= bootEnd) return WheatStageKey.booting;
    if (day <= headEnd) return WheatStageKey.heading;
    if (day <= flowerEnd) return WheatStageKey.flowering;

    final postFlower = math.max(1, endStart - flowerEnd);
    final grainEnd = math.max(flowerEnd, flowerEnd + (postFlower * 0.65).round());
    final matEnd = math.max(grainEnd, endStart - 1);

    if (day <= grainEnd) return WheatStageKey.grainFill;
    if (day <= matEnd) return WheatStageKey.physiologicalMaturity;
    return WheatStageKey.harvest;
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
      case WheatStageKey.tillering:
        return 'assets/seeds/wheat/wheat_stage_veg.png';
      case WheatStageKey.elongation:
      case WheatStageKey.booting:
        return 'assets/seeds/wheat/wheat_stage_elongation.png';
      case WheatStageKey.heading:
      case WheatStageKey.flowering:
        return 'assets/seeds/wheat/wheat_stage_flowering.png';
      case WheatStageKey.grainFill:
      case WheatStageKey.physiologicalMaturity:
        return 'assets/seeds/wheat/wheat_stage_maturity.png';
      case WheatStageKey.harvest:
        return 'assets/seeds/wheat/wheat_stage_harvest.png';
    }
  }

  static List<SeedWindowKey> _windows(WheatStageKey stage) {
    final windows = <SeedWindowKey>[
      SeedWindowKey.irrigation,
      SeedWindowKey.scouting,
    ];
    final nutritionHeavy = stage == WheatStageKey.tillering ||
        stage == WheatStageKey.elongation ||
        stage == WheatStageKey.booting ||
        stage == WheatStageKey.heading ||
        stage == WheatStageKey.flowering ||
        stage == WheatStageKey.grainFill;
    if (nutritionHeavy) windows.add(SeedWindowKey.nutrition);
    if (stage == WheatStageKey.heading || stage == WheatStageKey.flowering) {
      windows.add(SeedWindowKey.critical);
    }
    return windows;
  }
}
