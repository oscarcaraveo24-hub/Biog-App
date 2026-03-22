// lib/widgets/seeds/maize_models.dart
// Modelos puros (Dart). NO depende de Flutter.

import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';

// ---------------------------------------------------------------------------
// Tipo de uso del perfil — para filtrar en wizard y label de acción final.
// ---------------------------------------------------------------------------
enum MaizeUseType {
  grain,   // Grano  → acción final: 'Cosecha'
  forage,  // Forraje → acción final: 'Corte'
  elote,   // Elote  → acción final: 'Cosecha elote'
}

enum MaizeStageKey {
  germination,
  emergence,
  vegEarly,
  vegMid,
  vegAdvanced,
  tasseling,
  flowerSet,
  maturitySenescence,
  harvest,
}

enum SeedWindowKey { irrigation, nutrition, scouting, critical }

class RangeInt {
  final int min;
  final int max;

  const RangeInt(this.min, this.max) : assert(min <= max);

  int get mid => ((min + max) / 2).round();

  RangeInt clampMinMax(int minValue, int maxValue) {
    final newMin = min.clamp(minValue, maxValue);
    final newMax = max.clamp(minValue, maxValue);
    return RangeInt(newMin, newMax < newMin ? newMin : newMax);
  }

  @override
  String toString() => 'RangeInt($min..$max)';
}

class RangeDouble {
  final double min;
  final double max;

  const RangeDouble(this.min, this.max) : assert(min <= max);

  @override
  String toString() => 'RangeDouble($min..$max)';
}

class MaizeProfile extends CropProfile {
  final RangeInt r1Days;
  final RangeInt endWindowDays;
  final String endActionLabel;

  final RangeDouble plantHeightM;
  final RangeDouble earHeightM;

  final RangeInt germinationDays;
  final RangeInt emergenceDays;
  final RangeInt vegEarlyDays;

  /// Tipo de uso tipado — complementa el `useType: String` del padre.
  /// Permite filtrar perfiles en el wizard sin comparar strings.
  final MaizeUseType maizeUseType;

  const MaizeProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.maizeUseType = MaizeUseType.grain,
    this.r1Days = const RangeInt(0, 0),
    this.endWindowDays = const RangeInt(0, 0),
    this.endActionLabel = '',
    this.plantHeightM = const RangeDouble(0, 0),
    this.earHeightM = const RangeDouble(0, 0),
    this.germinationDays = const RangeInt(0, 0),
    this.emergenceDays = const RangeInt(0, 0),
    this.vegEarlyDays = const RangeInt(0, 0),
  }) : super(cropKey: CropKey.maize);
}

class StageBounds {
  final MaizeStageKey key;
  final int startDay;
  final int endDay;

  const StageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  }) : assert(startDay >= 1),
       assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

class SeedStageResult {
  final MaizeProfile profile;
  final MaizeStageKey stage;
  final int daySinceSowing;

  final RangeInt r1Band;
  final RangeInt endBand;

  final int expectedR1Day;
  final int expectedEndDay;

  final int expectedDaysToEnd;
  final double stageProgressPct;
  final List<SeedWindowKey> windowsNow;

  final RangeDouble expectedPlantHeightTodayM;

  final String stageLabelEs;
  final String heroAsset;
  final String helperCaption;

  const SeedStageResult({
    required this.profile,
    required this.stage,
    required this.daySinceSowing,
    required this.r1Band,
    required this.endBand,
    required this.expectedR1Day,
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
