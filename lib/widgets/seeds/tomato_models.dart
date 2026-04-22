import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

/// Tipo de uso agronómico del tomate.
///
/// En v1 solo se soporta suelo (campo abierto o protegido en suelo).
/// Hidroponía y sustratos quedan fuera de frontier v1.
enum TomatoUseType { fresh, process }

/// Tipo comercial del tomate (UX).
///
/// - saladette: "Roma" / pera, redondos firmes
/// - bola: redondo grande
/// - cherry: racimo pequeño / uva
/// - tov: "truss on the vine" / racimo comercial
/// - generic: sin tipo seleccionado (usa TM-GEN)
enum TomatoMarketType { saladette, bola, cherry, tov, generic }

/// Modo de establecimiento.
///
/// El reloj biológico del tomate se ancla al trasplante cuando aplica,
/// no a la semilla.
enum TomatoEstablishmentMode { directSeed, transplant }

/// 8 etapas fenológicas oficiales del tomate (PDF v2).
enum TomatoStageKey {
  germinacion,
  establecimiento,
  vegetativo,
  floracion,
  cuajado,
  llenado,
  cosechaProgresiva,
  finCiclo,
}

/// Perfil de tomate con anclaje temporal y rangos productivos.
///
/// Los días son relativos al inicio de ciclo (trasplante si [establishmentMode]
/// = transplant; siembra directa si = directSeed).
class TomatoProfile extends CropProfile {
  /// Tipo comercial (UX). TM-GEN usa [TomatoMarketType.generic].
  final TomatoMarketType marketType;

  /// Uso: fresh (consumo en fresco) o process (industrial).
  final TomatoUseType tomatoUseType;

  /// Modo de establecimiento por defecto del perfil.
  final TomatoEstablishmentMode defaultEstablishmentMode;

  /// Ventana de inicio de floración (DDT / DDS según modo).
  final RangeInt floweringDays;

  /// Ventana de inicio de cosecha (DDT / DDS según modo).
  final RangeInt harvestStartDays;

  /// Ventana de fin de ciclo productivo.
  final RangeInt endWindowDays;

  final String endActionLabel;

  /// Altura final esperada (m).
  final RangeDouble plantHeightM;

  /// Rango de densidad típica (plantas/ha).
  final RangeInt densityPlantsPerHa;

  /// Rendimiento de referencia orientativo (t/ha).
  ///
  /// NO usado para proyección dura cuando [isGenericProfile] es true.
  final RangeDouble referenceYieldTHa;

  /// Indica si el perfil es genérico (TM-GEN).
  final bool isGenericProfile;

  const TomatoProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.marketType = TomatoMarketType.generic,
    this.tomatoUseType = TomatoUseType.fresh,
    this.defaultEstablishmentMode = TomatoEstablishmentMode.transplant,
    this.floweringDays = const RangeInt(0, 0),
    this.harvestStartDays = const RangeInt(0, 0),
    this.endWindowDays = const RangeInt(0, 0),
    this.endActionLabel = 'Fin de ciclo',
    this.plantHeightM = const RangeDouble(0, 0),
    this.densityPlantsPerHa = const RangeInt(0, 0),
    this.referenceYieldTHa = const RangeDouble(0, 0),
    this.isGenericProfile = false,
  }) : super(cropKey: CropKey.tomato);
}

/// Límites temporales de una etapa en el ciclo del tomate.
class TomatoStageBounds {
  final TomatoStageKey key;
  final int startDay;
  final int endDay;

  const TomatoStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  }) : assert(startDay >= 1),
       assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

/// Resultado de cómputo de etapa para tomate.
///
/// Incluye traslape: `productiveState` identifica estado productivo
/// complementario (por ejemplo, durante `cosechaProgresiva` puede haber
/// floración y cuajado simultáneos).
class TomatoStageResult {
  final TomatoProfile profile;
  final TomatoStageKey stage;
  final int daySinceAnchor;
  final TomatoEstablishmentMode establishmentMode;

  final RangeInt floweringBand;
  final RangeInt harvestStartBand;
  final RangeInt endBand;

  final int expectedFloweringDay;
  final int expectedHarvestStartDay;
  final int expectedEndDay;

  final int expectedDaysToEnd;
  final double stageProgressPct;
  final List<SeedWindowKey> windowsNow;

  /// Estado productivo complementario (para traslape).
  ///
  /// Valores posibles: `flowering_active`, `fruit_set_active`,
  /// `fruit_fill_active`, `harvest_active`. Null si no hay traslape.
  final TomatoStageKey? productiveState;

  final RangeDouble expectedPlantHeightTodayM;

  final String stageLabelEs;
  final String productiveStateLabelEs;
  final String heroAsset;
  final String helperCaption;

  const TomatoStageResult({
    required this.profile,
    required this.stage,
    required this.daySinceAnchor,
    required this.establishmentMode,
    required this.floweringBand,
    required this.harvestStartBand,
    required this.endBand,
    required this.expectedFloweringDay,
    required this.expectedHarvestStartDay,
    required this.expectedEndDay,
    required this.expectedDaysToEnd,
    required this.stageProgressPct,
    required this.windowsNow,
    required this.productiveState,
    required this.expectedPlantHeightTodayM,
    required this.stageLabelEs,
    required this.productiveStateLabelEs,
    required this.heroAsset,
    required this.helperCaption,
  });
}
