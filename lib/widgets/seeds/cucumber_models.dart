import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

/// Tipo de uso agronómico del pepino.
///
/// En v1 solo se soporta suelo (campo abierto o protegido en suelo).
/// Hidroponía y sustratos quedan fuera de frontier v1.
enum CucumberUseType { fresh, process }

/// Tipo comercial del pepino (UX).
///
/// - slicer: americano largo / criollo de rebanada (PE-01)
/// - european: europeo / inglés protegido (PE-02)
/// - persianMini: persa / mini / beit-alfa protegido (PE-03)
/// - pickler: cornichón / encurtido (PE-04)
/// - generic: sin tipo seleccionado (PE-GEN)
enum CucumberMarketType { slicer, european, persianMini, pickler, generic }

/// Modo de establecimiento.
///
/// El reloj biológico del pepino se ancla al trasplante cuando aplica;
/// en campo abierto pickler/slicer es común la siembra directa.
enum CucumberEstablishmentMode { directSeed, transplant }

/// 8 etapas fenológicas del pepino, alineadas a la doctrina BIO-G.
///
/// Misma cardinalidad que tomate para reutilizar pesos del ring de control
/// y mantener uniformidad de UX.
enum CucumberStageKey {
  germinacion,
  establecimiento,
  vegetativo,
  floracion,
  cuajado,
  llenado,
  cosechaProgresiva,
  finCiclo,
}

/// Perfil de pepino con anclaje temporal y rangos productivos.
///
/// Los días son relativos al inicio real del ciclo:
/// siembra directa o trasplante, según corresponda.
///
/// A diferencia de tomate, el material BIO-G de pepino maneja el día 0 como
/// "siembra/trasplante", así que las bandas de floración/cosecha NO se
/// desplazan artificialmente entre modos.
class CucumberProfile extends CropProfile {
  /// Tipo comercial (UX). PE-GEN usa [CucumberMarketType.generic].
  final CucumberMarketType marketType;

  /// Uso: fresh (consumo en fresco) o process (industrial / encurtido).
  final CucumberUseType cucumberUseType;

  /// Modo de establecimiento por defecto del perfil.
  final CucumberEstablishmentMode defaultEstablishmentMode;

  /// Ventana de inicio de floración (DDT / DDS según modo).
  final RangeInt floweringDays;

  /// Ventana de inicio de cosecha (DDT / DDS según modo).
  final RangeInt harvestStartDays;

  /// Ventana de fin de ciclo productivo.
  final RangeInt endWindowDays;

  final String endActionLabel;

  /// Altura final esperada (m). En guiado vertical (espalderado) los
  /// indeterminados pueden superar 2 m; en rastrero 0.4–0.6 m.
  final RangeDouble plantHeightM;

  /// Rango de densidad típica (plantas/ha).
  final RangeInt densityPlantsPerHa;

  /// Rendimiento de referencia orientativo (t/ha).
  ///
  /// NO usado para proyección dura cuando [isGenericProfile] es true.
  final RangeDouble referenceYieldTHa;

  /// Indica si el perfil es genérico (PE-GEN).
  final bool isGenericProfile;

  const CucumberProfile({
    required super.id,
    required super.label,
    required super.useType,
    this.marketType = CucumberMarketType.generic,
    this.cucumberUseType = CucumberUseType.fresh,
    this.defaultEstablishmentMode = CucumberEstablishmentMode.transplant,
    this.floweringDays = const RangeInt(0, 0),
    this.harvestStartDays = const RangeInt(0, 0),
    this.endWindowDays = const RangeInt(0, 0),
    this.endActionLabel = 'Fin de ciclo',
    this.plantHeightM = const RangeDouble(0, 0),
    this.densityPlantsPerHa = const RangeInt(0, 0),
    this.referenceYieldTHa = const RangeDouble(0, 0),
    this.isGenericProfile = false,
  }) : super(cropKey: CropKey.cucumber);
}

/// Límites temporales de una etapa en el ciclo del pepino.
class CucumberStageBounds {
  final CucumberStageKey key;
  final int startDay;
  final int endDay;

  const CucumberStageBounds({
    required this.key,
    required this.startDay,
    required this.endDay,
  })  : assert(startDay >= 1),
        assert(startDay <= endDay);

  bool contains(int day) => day >= startDay && day <= endDay;
}

/// Resultado de cómputo de etapa para pepino.
///
/// Pepino, igual que tomate indeterminado, presenta traslape estructural:
/// durante cosechaProgresiva pueden existir floración y cuajado simultáneos
/// en nudos superiores. `productiveState` expone ese estado complementario.
class CucumberStageResult {
  final CucumberProfile profile;
  final CucumberStageKey stage;
  final int daySinceAnchor;
  final CucumberEstablishmentMode establishmentMode;

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
  final CucumberStageKey? productiveState;

  final RangeDouble expectedPlantHeightTodayM;

  final String stageLabelEs;
  final String productiveStateLabelEs;
  final String heroAsset;
  final String helperCaption;

  const CucumberStageResult({
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
