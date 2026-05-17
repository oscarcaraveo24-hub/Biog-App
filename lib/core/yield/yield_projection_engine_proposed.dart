import 'dart:math' as math;

import 'package:bio_g/models/yield_projection_config.dart';
import 'package:bio_g/core/yield/yield_reference_catalog.dart';

/// Modo de salida seleccionado por el usuario en la calculadora.
enum YieldOutputMode { grain, forage }

/// Cultivos que soportan cada modo de salida.
class YieldOutputModeSupport {
  const YieldOutputModeSupport._();

  /// Devuelve los modos válidos para un cropId.
  static List<YieldOutputMode> supportedModes(String? cropId) {
    return switch (cropId) {
      'maize' => [YieldOutputMode.grain, YieldOutputMode.forage],
      'wheat' => [YieldOutputMode.grain, YieldOutputMode.forage],
      'barley' => [YieldOutputMode.grain, YieldOutputMode.forage],
      'oat' => [YieldOutputMode.grain, YieldOutputMode.forage],
      'bean' => [YieldOutputMode.grain],
      _ => [YieldOutputMode.grain],
    };
  }

  /// True si el cultivo soporta ambos modos.
  static bool supportsBothModes(String? cropId) =>
      supportedModes(cropId).length > 1;

  /// Etiqueta corta en español.
  static String labelEs(YieldOutputMode mode) => switch (mode) {
    YieldOutputMode.grain => 'Grano',
    YieldOutputMode.forage => 'Forraje / Materia verde',
  };

  /// Etiqueta compacta para chips.
  static String shortLabelEs(YieldOutputMode mode) => switch (mode) {
    YieldOutputMode.grain => 'Grano',
    YieldOutputMode.forage => 'Forraje',
  };
}

enum YieldFamily {
  maizeGrain,
  maizeForage,
  maizeElote,
  cerealGrain,
  cerealForage,
  beanGrain,
  tomatoFresh,
  cucumberFresh,
  chiliFruit,
  eggplantFruit,
  squashFruit,
  squashSeed,
  lettuceLeaf,
  other,
}

class YieldProjectionEstimate {
  final YieldReference reference;
  final double areaHa;
  final double densitySeedsPerHa;
  final double blendedCareScore01;
  final double populationFactor01;
  final double managementFactor01;
  final double projectedLowTonPerHa;
  final double projectedHighTonPerHa;
  final double projectedMidTonPerHa;
  final double projectedLowTotalTon;
  final double projectedHighTotalTon;
  final double projectedMidTotalTon;

  const YieldProjectionEstimate({
    required this.reference,
    required this.areaHa,
    required this.densitySeedsPerHa,
    required this.blendedCareScore01,
    required this.populationFactor01,
    required this.managementFactor01,
    required this.projectedLowTonPerHa,
    required this.projectedHighTonPerHa,
    required this.projectedMidTonPerHa,
    required this.projectedLowTotalTon,
    required this.projectedHighTotalTon,
    required this.projectedMidTotalTon,
  });

  bool get isFreshMatter => reference.isFreshMatter;
  String get perHaUnitLabel => isFreshMatter ? 't MV/ha' : 't/ha';
  String get totalUnitLabel => isFreshMatter ? 't MV' : 't';
}

class YieldProjectionEngine {
  static const double _defaultCareScore01 = 0.68;

  static YieldProjectionEstimate? estimate({
    required YieldReference reference,
    required YieldProjectionConfig config,
    double? historicalCareScore01,
    double? currentCareScore01,
  }) {
    final areaHa = config.areaInHectares;
    final density = config.estimatedPopulationPerHa;

    if (areaHa == null || areaHa <= 0) return null;
    if (density == null || density <= 0) return null;

    final blendedCare = _blendCareScore(
      historicalCareScore01: historicalCareScore01,
      currentCareScore01: currentCareScore01,
    );
    final populationFactor = _populationFactor(
      densitySeedsPerHa: density,
      reference: reference,
    );
    final managementFactor = _managementFactor(
      careScore01: blendedCare,
      family: _familyFor(reference),
    );

    final yieldLow =
        _expandedLow(reference) * populationFactor * managementFactor;
    final yieldHigh =
        _expandedHigh(reference) * populationFactor * managementFactor;
    final yieldMid = (yieldLow + yieldHigh) / 2.0;

    return YieldProjectionEstimate(
      reference: reference,
      areaHa: areaHa,
      densitySeedsPerHa: density,
      blendedCareScore01: blendedCare,
      populationFactor01: populationFactor,
      managementFactor01: managementFactor,
      projectedLowTonPerHa: yieldLow,
      projectedHighTonPerHa: yieldHigh,
      projectedMidTonPerHa: yieldMid,
      projectedLowTotalTon: yieldLow * areaHa,
      projectedHighTotalTon: yieldHigh * areaHa,
      projectedMidTotalTon: yieldMid * areaHa,
    );
  }

  static double _blendCareScore({
    double? historicalCareScore01,
    double? currentCareScore01,
  }) {
    final history = _clamp01OrNull(historicalCareScore01);
    final current = _clamp01OrNull(currentCareScore01);

    if (history != null && current != null) {
      return ((history * 0.65) + (current * 0.35)).clamp(0.0, 1.0);
    }
    return history ?? current ?? _defaultCareScore01;
  }

  static double _populationFactor({
    required double densitySeedsPerHa,
    required YieldReference reference,
  }) {
    final lo = reference.seedsLowPerHa;
    final hi = reference.seedsHighPerHa;
    final family = _familyFor(reference);
    final p = _params(family);

    if (densitySeedsPerHa < lo) {
      final gap01 = ((lo - densitySeedsPerHa) / lo).clamp(0.0, 10.0);
      return math.max(
        0.25,
        1.0 - p.alphaLow * math.pow(gap01, p.betaLow).toDouble(),
      );
    }

    if (densitySeedsPerHa > hi) {
      final excess01 = ((densitySeedsPerHa - hi) / hi).clamp(0.0, 10.0);
      return math.max(
        0.25,
        1.0 - p.alphaHigh * math.pow(excess01, p.betaHigh).toDouble(),
      );
    }

    return 1.0;
  }

  static double _managementFactor({
    required double careScore01,
    required YieldFamily family,
  }) {
    final p = _params(family);
    final s = careScore01.clamp(0.0, 1.0);
    return (p.managementFloor +
            (1.0 - p.managementFloor) *
                math.pow(s, p.managementGamma).toDouble())
        .clamp(0.0, 1.0);
  }

  static double _expandedLow(YieldReference reference) {
    final low = reference.yieldLowTonPerHa;
    final high = reference.yieldHighTonPerHa;
    if ((high - low).abs() > 0.0001) return low;
    final spread = switch (reference.confidence) {
      YieldDataConfidence.validated => 0.04,
      YieldDataConfidence.calibrated => 0.08,
      YieldDataConfidence.modeled => 0.12,
    };
    return low * (1.0 - spread);
  }

  static double _expandedHigh(YieldReference reference) {
    final low = reference.yieldLowTonPerHa;
    final high = reference.yieldHighTonPerHa;
    if ((high - low).abs() > 0.0001) return high;
    final spread = switch (reference.confidence) {
      YieldDataConfidence.validated => 0.04,
      YieldDataConfidence.calibrated => 0.08,
      YieldDataConfidence.modeled => 0.12,
    };
    return high * (1.0 + spread);
  }

  static YieldFamily _familyFor(YieldReference reference) {
    switch (reference.cropId) {
      case 'maize':
        switch (reference.useType) {
          case 'forage':
            return YieldFamily.maizeForage;
          case 'elote':
            return YieldFamily.maizeElote;
          default:
            return YieldFamily.maizeGrain;
        }
      case 'wheat':
      case 'barley':
      case 'oat':
        return reference.useType == 'forage'
            ? YieldFamily.cerealForage
            : YieldFamily.cerealGrain;
      case 'bean':
        return YieldFamily.beanGrain;
      case 'tomato':
        return YieldFamily.tomatoFresh;
      case 'cucumber':
        return YieldFamily.cucumberFresh;
      case 'chili':
        return YieldFamily.chiliFruit;
      case 'eggplant':
        return YieldFamily.eggplantFruit;
      case 'squash':
        return reference.useType == 'seed'
            ? YieldFamily.squashSeed
            : YieldFamily.squashFruit;
      case 'lettuce':
        return YieldFamily.lettuceLeaf;
      default:
        return YieldFamily.other;
    }
  }

  static _YieldFamilyParams _params(YieldFamily family) {
    return switch (family) {
      YieldFamily.maizeGrain => const _YieldFamilyParams(
        alphaLow: 1.25,
        betaLow: 1.60,
        alphaHigh: 1.00,
        betaHigh: 1.35,
        managementGamma: 1.35,
        managementFloor: 0.22,
      ),
      YieldFamily.maizeForage => const _YieldFamilyParams(
        alphaLow: 1.00,
        betaLow: 1.45,
        alphaHigh: 0.70,
        betaHigh: 1.25,
        managementGamma: 1.15,
        managementFloor: 0.28,
      ),
      YieldFamily.maizeElote => const _YieldFamilyParams(
        alphaLow: 1.10,
        betaLow: 1.50,
        alphaHigh: 0.85,
        betaHigh: 1.30,
        managementGamma: 1.20,
        managementFloor: 0.25,
      ),
      YieldFamily.cerealGrain => const _YieldFamilyParams(
        alphaLow: 0.75,
        betaLow: 1.30,
        alphaHigh: 0.95,
        betaHigh: 1.30,
        managementGamma: 1.25,
        managementFloor: 0.24,
      ),
      YieldFamily.cerealForage => const _YieldFamilyParams(
        alphaLow: 0.65,
        betaLow: 1.20,
        alphaHigh: 0.70,
        betaHigh: 1.20,
        managementGamma: 1.10,
        managementFloor: 0.28,
      ),
      YieldFamily.beanGrain => const _YieldFamilyParams(
        alphaLow: 0.95,
        betaLow: 1.35,
        alphaHigh: 0.80,
        betaHigh: 1.25,
        managementGamma: 1.30,
        managementFloor: 0.22,
      ),
      // Tomate: alta sensibilidad a manejo (agua, poda, Ca), penalización
      // moderada por densidad desajustada. Techo conservador para TM-GEN.
      YieldFamily.tomatoFresh => const _YieldFamilyParams(
        alphaLow: 0.90,
        betaLow: 1.30,
        alphaHigh: 0.85,
        betaHigh: 1.25,
        managementGamma: 1.45,
        managementFloor: 0.20,
      ),
      // Pepino: más sensible a continuidad de agua, calor, sanidad y corte
      // progresivo; la densidad fuera de rango castiga rápido la proyección.
      YieldFamily.cucumberFresh => const _YieldFamilyParams(
        alphaLow: 0.95,
        betaLow: 1.35,
        alphaHigh: 0.82,
        betaHigh: 1.22,
        managementGamma: 1.50,
        managementFloor: 0.20,
      ),
      YieldFamily.chiliFruit => const _YieldFamilyParams(
        alphaLow: 0.95,
        betaLow: 1.35,
        alphaHigh: 0.86,
        betaHigh: 1.25,
        managementGamma: 1.48,
        managementFloor: 0.20,
      ),
      // Berenjena: PDF Rendimiento v1 sugiere managementGamma 1.35 y
      // managementFloor 0.24; algo menos punitivo que chile/pepino, pero
      // sigue siendo sensible a manejo en floracion/cuajado/llenado.
      YieldFamily.eggplantFruit => const _YieldFamilyParams(
        alphaLow: 0.92,
        betaLow: 1.32,
        alphaHigh: 0.84,
        betaHigh: 1.22,
        managementGamma: 1.35,
        managementFloor: 0.24,
      ),
      YieldFamily.squashFruit => const _YieldFamilyParams(
        alphaLow: 0.90,
        betaLow: 1.30,
        alphaHigh: 0.82,
        betaHigh: 1.22,
        managementGamma: 1.42,
        managementFloor: 0.22,
      ),
      // Calabaza CA-07 / pipián / pepita:
      // menos punitivo que fruto fresco porque el destino es semilla seca
      // y el rango ya carga mayor incertidumbre agronómica.
      YieldFamily.squashSeed => const _YieldFamilyParams(
        alphaLow: 0.80,
        betaLow: 1.25,
        alphaHigh: 0.78,
        betaHigh: 1.18,
        managementGamma: 1.30,
        managementFloor: 0.24,
      ),
      // Lechuga: hortaliza de hoja de ciclo corto. Muy sensible a manejo
      // (agua, calor, espigado) y a densidad fuera de rango; el techo se
      // mantiene conservador porque el valor real es calidad y ventana.
      YieldFamily.lettuceLeaf => const _YieldFamilyParams(
        alphaLow: 0.92,
        betaLow: 1.30,
        alphaHigh: 0.84,
        betaHigh: 1.22,
        managementGamma: 1.45,
        managementFloor: 0.22,
      ),
      YieldFamily.other => const _YieldFamilyParams(
        alphaLow: 1.00,
        betaLow: 1.40,
        alphaHigh: 0.90,
        betaHigh: 1.30,
        managementGamma: 1.20,
        managementFloor: 0.22,
      ),
    };
  }

  static double? _clamp01OrNull(double? value) {
    if (value == null || value.isNaN) return null;
    return value.clamp(0.0, 1.0);
  }
}

class _YieldFamilyParams {
  final double alphaLow;
  final double betaLow;
  final double alphaHigh;
  final double betaHigh;
  final double managementGamma;
  final double managementFloor;

  const _YieldFamilyParams({
    required this.alphaLow,
    required this.betaLow,
    required this.alphaHigh,
    required this.betaHigh,
    required this.managementGamma,
    required this.managementFloor,
  });
}
