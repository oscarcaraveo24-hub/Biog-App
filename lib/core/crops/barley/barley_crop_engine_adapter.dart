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

    final stage = _resolveStage(barleyProfile, effectiveDay);
    final expectedEnd = math.max(1, barleyProfile.endWindowDays.mid);
    final remaining = (expectedEnd - effectiveDay).clamp(0, 999999);

    return CropStageResult(
      stageKey: stage.name,
      stageLabelEs: _labelEs(stage),
      expectedDaysToEnd: remaining,
      windowsNow: _windows(stage),
      heroAsset: _heroAsset(stage),
      helperCaption: _helperCaption(stage),
    );
  }

  static BarleyStageKey _resolveStage(BarleyProfile p, int day) {
    final germEnd = math.max(1, p.germinationDays.max);
    final emergEnd = math.max(germEnd, p.emergenceDays.max);
    final vegEnd = math.max(emergEnd, p.vegEarlyDays.max);
    final flowerStart = math.max(vegEnd + 1, p.floweringDays.min);
    final flowerEnd = math.max(flowerStart, p.floweringDays.max);
    final endStart = math.max(flowerEnd + 1, p.endWindowDays.min);

    if (day <= germEnd) return BarleyStageKey.germination;
    if (day <= emergEnd) return BarleyStageKey.emergence;
    if (day <= vegEnd) return BarleyStageKey.vegEarly;

    final midRange = math.max(1, flowerStart - vegEnd);
    final tillerEnd = math.max(vegEnd, vegEnd + (midRange * 0.30).round());
    final elongEnd = math.max(tillerEnd, vegEnd + (midRange * 0.55).round());
    final bootEnd = math.max(elongEnd, vegEnd + (midRange * 0.75).round());
    final headEnd = math.max(bootEnd, flowerStart - 1);

    if (day <= tillerEnd) return BarleyStageKey.tillering;
    if (day <= elongEnd) return BarleyStageKey.elongation;
    if (day <= bootEnd) return BarleyStageKey.booting;
    if (day <= headEnd) return BarleyStageKey.heading;
    if (day <= flowerEnd) return BarleyStageKey.flowering;

    final postFlower = math.max(1, endStart - flowerEnd);
    final grainEnd = math.max(flowerEnd, flowerEnd + (postFlower * 0.65).round());
    final matEnd = math.max(grainEnd, endStart - 1);

    if (day <= grainEnd) return BarleyStageKey.grainFill;
    if (day <= matEnd) return BarleyStageKey.physiologicalMaturity;
    return BarleyStageKey.harvest;
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
        return 'assets/seeds/barley/barley_stage_veg_advanced.png';
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
    final nutritionHeavy = stage == BarleyStageKey.tillering ||
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
        return 'Antesis — polinización. Cebada es autógama pero sensible a calor extremo.';
      case BarleyStageKey.grainFill:
        return 'Llenado de grano — mantén humedad. En maltera, evita N excesivo (baja calidad).';
      case BarleyStageKey.physiologicalMaturity:
        return 'Madurez fisiológica — reduce riego. Grano secando en planta.';
      case BarleyStageKey.harvest:
        return 'Cosecha — humedad de grano <13% ideal. Maltera requiere grano uniforme.';
    }
  }
}
