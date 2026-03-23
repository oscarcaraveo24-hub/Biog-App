// lib/widgets/seeds/oat_models.dart
// Modelos puros (Dart) para Avena. NO depende de Flutter.

import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

// ---------------------------------------------------------------------------
// Tipo de uso del perfil — para filtrar en wizard y label de acción final.
// ---------------------------------------------------------------------------
enum OatUseType {
  forage,       // Forraje  → acción final: 'Corte'
  grain,        // Grano    → acción final: 'Cosecha'
  dualPurpose,  // Doble propósito → acción final: 'Corte / Cosecha'
}

enum OatStageKey {
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

class OatProfile extends CropProfile {
  /// Días a espigamiento/floración (heading/anthesis) desde siembra.
  final RangeInt floweringDays;

  /// Días a acción final (cosecha grano o corte forraje) desde siembra.
  final RangeInt endWindowDays;

  /// Etiqueta de la acción final: 'Cosecha', 'Corte', 'Corte / Cosecha'.
  final String endActionLabel;

  final RangeDouble plantHeightM;

  final RangeInt germinationDays;
  final RangeInt emergenceDays;
  final RangeInt vegEarlyDays;

  final OatUseType oatUseType;

  const OatProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.oatUseType = OatUseType.forage,
    this.floweringDays = const RangeInt(0, 0),
    this.endWindowDays = const RangeInt(0, 0),
    this.endActionLabel = '',
    this.plantHeightM = const RangeDouble(0, 0),
    this.germinationDays = const RangeInt(0, 0),
    this.emergenceDays = const RangeInt(0, 0),
    this.vegEarlyDays = const RangeInt(0, 0),
  }) : super(cropKey: CropKey.oat);
}

class OatStageBounds {
  final OatStageKey key;
  final int startDay;
  final int endDay;

  const OatStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  }) : assert(startDay >= 1),
       assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

class OatStageResult {
  final OatProfile profile;
  final OatStageKey stage;
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

  const OatStageResult({
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
