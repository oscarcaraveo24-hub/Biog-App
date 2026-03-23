// lib/widgets/seeds/barley_models.dart
// Modelos puros (Dart) para Cebada. NO depende de Flutter.

import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

// ---------------------------------------------------------------------------
// Tipo de uso del perfil — para filtrar en wizard y label de acción final.
// ---------------------------------------------------------------------------
enum BarleyUseType {
  grain,   // Grano      → acción final: 'Cosecha'
  malt,    // Maltera    → acción final: 'Cosecha' (calidad maltera)
  forage,  // Forrajera  → acción final: 'Corte'
}

enum BarleyStageKey {
  germination,
  emergence,
  vegEarly,
  tillering,
  elongation,
  booting,
  heading,
  flowering,
  grainFill,
  physiologicalMaturity,
  harvest,
}

class BarleyProfile extends CropProfile {
  /// Días a floración/antesis desde siembra.
  final RangeInt floweringDays;

  /// Días a acción final (cosecha o corte) desde siembra.
  final RangeInt endWindowDays;

  /// Etiqueta de la acción final: 'Cosecha', 'Corte'.
  final String endActionLabel;

  final RangeDouble plantHeightM;

  /// Altura de la espiga (solo relevante para grano/maltera).
  final RangeDouble spikeHeightM;

  final RangeInt germinationDays;
  final RangeInt emergenceDays;
  final RangeInt vegEarlyDays;

  final BarleyUseType barleyUseType;

  const BarleyProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.barleyUseType = BarleyUseType.grain,
    this.floweringDays = const RangeInt(0, 0),
    this.endWindowDays = const RangeInt(0, 0),
    this.endActionLabel = '',
    this.plantHeightM = const RangeDouble(0, 0),
    this.spikeHeightM = const RangeDouble(0, 0),
    this.germinationDays = const RangeInt(0, 0),
    this.emergenceDays = const RangeInt(0, 0),
    this.vegEarlyDays = const RangeInt(0, 0),
  }) : super(cropKey: CropKey.barley);
}

class BarleyStageBounds {
  final BarleyStageKey key;
  final int startDay;
  final int endDay;

  const BarleyStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  }) : assert(startDay >= 1),
       assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

class BarleyStageResult {
  final BarleyProfile profile;
  final BarleyStageKey stage;
  final int daySinceSowing;

  final RangeInt floweringBand;
  final RangeInt endBand;

  final int expectedFloweringDay;
  final int expectedEndDay;

  final int expectedDaysToEnd;
  final double stageProgressPct;
  final List<SeedWindowKey> windowsNow;

  final RangeDouble expectedPlantHeightTodayM;

  final String stageLabelEs;
  final String heroAsset;
  final String helperCaption;

  const BarleyStageResult({
    required this.profile,
    required this.stage,
    required this.daySinceSowing,
    required this.floweringBand,
    required this.endBand,
    required this.expectedFloweringDay,
    required this.expectedEndDay,
    required this.expectedDaysToEnd,
    required this.stageProgressPct,
    required this.windowsNow,
    required this.expectedPlantHeightTodayM,
    required this.stageLabelEs,
    required this.heroAsset,
    required this.helperCaption,
  });
}
