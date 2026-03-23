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

    final stage = _resolveStage(barleyProfile, effectiveDay);
    final expectedEnd = barleyProfile.endWindowDays.mid;
    final remaining = (expectedEnd - effectiveDay).clamp(0, 999999);

    return CropStageResult(
      stageKey: stage.name,
      stageLabelEs: _labelEs(stage),
      expectedDaysToEnd: remaining,
      windowsNow: _windows(stage),
      heroAsset: _heroAsset(stage),
    );
  }

  static BarleyStageKey _resolveStage(BarleyProfile p, int day) {
    final germEnd = p.germinationDays.max;
    final emergEnd = p.emergenceDays.max;
    final vegEnd = p.vegEarlyDays.max;
    final flowerStart = p.floweringDays.min;
    final flowerEnd = p.floweringDays.max;
    final endStart = p.endWindowDays.min;

    if (day <= germEnd) return BarleyStageKey.germination;
    if (day <= emergEnd) return BarleyStageKey.emergence;
    if (day <= vegEnd) return BarleyStageKey.vegEarly;

    final midRange = flowerStart - vegEnd;
    final tillerEnd = vegEnd + (midRange * 0.30).round();
    final elongEnd = vegEnd + (midRange * 0.55).round();
    final bootEnd = vegEnd + (midRange * 0.75).round();
    final headEnd = flowerStart - 1;

    if (day <= tillerEnd) return BarleyStageKey.tillering;
    if (day <= elongEnd) return BarleyStageKey.elongation;
    if (day <= bootEnd) return BarleyStageKey.booting;
    if (day <= headEnd) return BarleyStageKey.heading;
    if (day <= flowerEnd) return BarleyStageKey.flowering;

    final postFlower = endStart - flowerEnd;
    final grainEnd = flowerEnd + (postFlower * 0.65).round();
    final matEnd = endStart - 1;

    if (day <= grainEnd) return BarleyStageKey.grainFill;
    if (day <= matEnd) return BarleyStageKey.physiologicalMaturity;
    return BarleyStageKey.harvest;
  }

  static String _labelEs(BarleyStageKey stage) {
    switch (stage) {
      case BarleyStageKey.germination: return 'Germinación';
      case BarleyStageKey.emergence: return 'Emergencia';
      case BarleyStageKey.vegEarly: return 'Vegetativa temprana';
      case BarleyStageKey.tillering: return 'Macollamiento';
      case BarleyStageKey.elongation: return 'Encañe';
      case BarleyStageKey.booting: return 'Embuchamiento';
      case BarleyStageKey.heading: return 'Espigamiento';
      case BarleyStageKey.flowering: return 'Floración';
      case BarleyStageKey.grainFill: return 'Llenado de grano';
      case BarleyStageKey.physiologicalMaturity: return 'Madurez fisiológica';
      case BarleyStageKey.harvest: return 'Cosecha';
    }
  }

  static String _heroAsset(BarleyStageKey stage) {
    switch (stage) {
      case BarleyStageKey.germination: return 'assets/seeds/barley/barley_stage_germination.png';
      case BarleyStageKey.emergence: return 'assets/seeds/barley/barley_stage_emergence.png';
      case BarleyStageKey.vegEarly:
      case BarleyStageKey.tillering: return 'assets/seeds/barley/barley_stage_veg.png';
      case BarleyStageKey.elongation:
      case BarleyStageKey.booting: return 'assets/seeds/barley/barley_stage_elongation.png';
      case BarleyStageKey.heading:
      case BarleyStageKey.flowering: return 'assets/seeds/barley/barley_stage_flowering.png';
      case BarleyStageKey.grainFill:
      case BarleyStageKey.physiologicalMaturity: return 'assets/seeds/barley/barley_stage_maturity.png';
      case BarleyStageKey.harvest: return 'assets/seeds/barley/barley_stage_harvest.png';
    }
  }

  static List<SeedWindowKey> _windows(BarleyStageKey stage) {
    final windows = <SeedWindowKey>[SeedWindowKey.irrigation, SeedWindowKey.scouting];
    final nutritionHeavy = stage == BarleyStageKey.tillering ||
        stage == BarleyStageKey.elongation ||
        stage == BarleyStageKey.booting ||
        stage == BarleyStageKey.heading ||
        stage == BarleyStageKey.flowering ||
        stage == BarleyStageKey.grainFill;
    if (nutritionHeavy) windows.add(SeedWindowKey.nutrition);
    if (stage == BarleyStageKey.booting || stage == BarleyStageKey.heading || stage == BarleyStageKey.flowering) {
      windows.add(SeedWindowKey.critical);
    }
    return windows;
  }
}
