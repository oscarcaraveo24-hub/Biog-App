// lib/core/agro/water/moisture_target_resolver.dart
//
// El puente. Convierte (cultivo + etapa + textura) en un [AgroRange] de VWC.
//
// ─────────────────────────────────────────────────────────────────────────────
// POR QUÉ DEVUELVE UN AgroRange Y NO UN TIPO NUEVO
// ─────────────────────────────────────────────────────────────────────────────
//
// Porque así se enchufa sin cambiar ni una firma. El motor de riego ya recibe
// `moistureTarget: AgroRange?` y los motores de score ya comparan contra un
// `AgroRange`. Sustituir la fuente de ese objeto arregla los 85 cultivos de
// golpe, en dos puntos de llamada, sin tocar 85 archivos de perfil y sin
// arriesgar una regresión en el resto del catálogo.
//
// Los rangos de humedad escritos a mano en los perfiles quedan obsoletos para
// suelo. NO se borran todavía: los de maceta siguen siendo válidos y los de
// suelo se conservan como referencia histórica hasta que el prototipo confirme
// en campo las constantes de esta tabla.
//
// ─────────────────────────────────────────────────────────────────────────────
// CÓMO SE CONSTRUYEN LAS BANDAS
// ─────────────────────────────────────────────────────────────────────────────
//
//   AD  = agua disponible = θcc − θpmp          (depende de la TEXTURA)
//   MAD = agotamiento permisible                (depende del CULTIVO y ETAPA)
//
//   highMin    = 0.90 × saturación      ← encharcamiento. ALCANZABLE.
//   optimalMax = θcc                    ← el depósito lleno
//   optimalMin = θcc − MAD × AD         ← punto de reposición: regar aquí
//   lowMax     = θcc − 1.5 × MAD × AD   ← estrés real, con piso en θpmp
//
// Ejemplo, manzano (MAD 0.50) en suelo franco (θpmp 13, θcc 28, sat 48):
//
//   highMin 43.2 · optimalMax 28.0 · optimalMin 20.5 · lowMax 16.8
//
// Contrástalo con lo que había escrito a mano: 45 / 60 / 80 / 90. Ese huerto
// a capacidad de campo —28 % VWC, regado a la perfección— caía en CRÍTICO
// BAJO, y encharcado a 46 % seguía saliendo BAJO.

import 'package:flutter/foundation.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_inputs.dart';
import 'package:bio_g/core/agro/water/crop_water_policy.dart';
import 'package:bio_g/core/agro/water/soil_water_scale.dart';
import 'package:bio_g/core/crops/crop_types.dart';

/// Resultado del resolver: el rango, más todo lo que hace falta para que la
/// decisión pueda explicarse y auditarse.
@immutable
class ResolvedMoistureTarget {
  const ResolvedMoistureTarget({
    required this.range,
    required this.texture,
    required this.policy,
    required this.effectiveDepletion,
    required this.soilContext,
    required this.limitationsEs,
    required this.isFallbackTexture,
    required this.isFallbackCrop,
  });

  final AgroRange range;
  final SoilTexture texture;
  final CropWaterPolicy policy;

  /// MAD ya ajustado por etapa.
  final double effectiveDepletion;

  /// Listo para pasar al motor: ya lleva θcc, θpmp, profundidad y eficiencia.
  /// Esto es lo que hace que `supportsWaterBalance` sea true por primera vez.
  final SoilContext soilContext;

  /// Qué no sabemos. Va a la decisión, no a la basura.
  final List<String> limitationsEs;

  final bool isFallbackTexture;
  final bool isFallbackCrop;

  /// Confianza que se debe restar por lo que se asumió.
  double get confidencePenalty {
    var p = 0.0;
    if (isFallbackTexture) p += 0.15;
    if (isFallbackCrop) p += 0.10;
    return p;
  }
}

abstract final class MoistureTargetResolver {
  static const String version = 'moisture-target-resolver-1.0';

  /// Cuánto por debajo del punto de reposición empieza el estrés real.
  /// 1.5 × MAD es el criterio conservador: entre `optimalMin` y `lowMax` la
  /// planta ya está trabajando de más, pero todavía no hay daño irreversible.
  static const double _criticalFactor = 1.5;

  static ResolvedMoistureTarget resolve({
    required CropKey? cropKey,
    String? stageKey,
    SoilTexture texture = SoilTexture.unknown,
    bool isPotted = false,
    double? rootDepthCmOverride,
    IrrigationSystem system = IrrigationSystem.unknown,
    double? wettedAreaM2PerPlantOverride,
  }) {
    // Maceta manda sobre textura declarada: un cactus en maceta vive en
    // sustrato aunque el productor haya dicho que su tierra es arcillosa.
    final effectiveTexture = isPotted
        ? SoilTexture.pottingMix
        : texture;

    final isFallbackTexture =
        !isPotted && SoilWaterScale.isFallback(effectiveTexture);
    final isFallbackCrop = CropWaterPolicies.isGenericFallback(cropKey);

    final c = SoilWaterScale.constantsOf(effectiveTexture);
    final policy = CropWaterPolicies.forCrop(cropKey);
    final mad = CropWaterPolicies.allowableDepletionForStage(policy, stageKey);

    final aw = c.availableWaterPct;
    final optimalMax = c.fieldCapacityPct;
    final optimalMin = (c.fieldCapacityPct - mad * aw)
        .clamp(c.wiltingPointPct, optimalMax);
    final lowMax = (c.fieldCapacityPct - _criticalFactor * mad * aw)
        .clamp(c.wiltingPointPct, optimalMin);
    final highMin = SoilWaterScale.waterloggingThresholdPct(effectiveTexture)
        .clamp(optimalMax, c.saturationPct);

    final rootDepth = rootDepthCmOverride ?? policy.rootDepthCm;

    final limitations = <String>[];
    if (isFallbackTexture) {
      limitations.add(
        'No sabemos qué tierra tienes, así que usamos la más común (media). '
        'Si es muy arenosa o muy pesada, los umbrales cambian bastante.',
      );
    }
    if (isFallbackCrop) {
      limitations.add(
        'Sin cultivo declarado usamos un criterio conservador de riego.',
      );
    }
    if (system == IrrigationSystem.unknown) {
      limitations.add(
        'No sabemos cómo riegas, así que la lámina no incluye las pérdidas '
        'del sistema.',
      );
    }

    return ResolvedMoistureTarget(
      range: AgroRange(
        lowMax: _round1(lowMax),
        optimalMin: _round1(optimalMin),
        optimalMax: _round1(optimalMax),
        highMin: _round1(highMin),
      ),
      texture: effectiveTexture,
      policy: policy,
      effectiveDepletion: mad,
      soilContext: SoilContext(
        textureId: effectiveTexture.id,
        fieldCapacityPct: c.fieldCapacityPct,
        wiltingPointPct: c.wiltingPointPct,
        rootDepthCm: rootDepth,
        allowableDepletionFraction: mad,
        systemEfficiency01: system == IrrigationSystem.unknown
            ? null
            : system.efficiency01,
      ),
      limitationsEs: List.unmodifiable(limitations),
      isFallbackTexture: isFallbackTexture,
      isFallbackCrop: isFallbackCrop,
    );
  }

  /// La lámina, ya en el lenguaje del productor.
  ///
  /// Devuelve `null` si falta cualquier ingrediente o si el suelo no necesita
  /// agua. Nunca inventa un número: si no se puede calcular, la tarjeta debe
  /// decir "riega como acostumbras" en vez de fingir precisión.
  static IrrigationDepth? depthFor({
    required double vwcPct,
    required ResolvedMoistureTarget target,
  }) {
    final soil = target.soilContext;
    final net = SoilWaterScale.netIrrigationDepthMm(
      vwcPct: vwcPct,
      texture: target.texture,
      rootDepthCm: soil.rootDepthCm,
    );
    if (net == null) return null;

    final gross = SoilWaterScale.grossIrrigationDepthMm(
      vwcPct: vwcPct,
      texture: target.texture,
      rootDepthCm: soil.rootDepthCm,
      systemEfficiency01: soil.systemEfficiency01,
    );

    final mm = gross ?? net;
    return IrrigationDepth(
      netMm: net,
      grossMm: mm,
      litersPerSquareMeter: SoilWaterScale.litersPerSquareMeter(mm),
      cubicMetersPerHectare: SoilWaterScale.cubicMetersPerHectare(mm),
      litersPerPlant: SoilWaterScale.litersPerPlant(
        mm,
        target.policy.wettedAreaM2PerPlant,
      ),
      includesSystemLosses: soil.systemEfficiency01 != null,
    );
  }

  static double _round1(double v) => (v * 10).roundToDouble() / 10;
}

/// La lámina calculada, con todas sus presentaciones.
@immutable
class IrrigationDepth {
  const IrrigationDepth({
    required this.netMm,
    required this.grossMm,
    required this.litersPerSquareMeter,
    required this.cubicMetersPerHectare,
    required this.includesSystemLosses,
    this.litersPerPlant,
  });

  /// Lo que le falta al suelo.
  final double netMm;

  /// Lo que hay que aplicar contando pérdidas del sistema.
  final double grossMm;

  final double litersPerSquareMeter;
  final double cubicMetersPerHectare;
  final double? litersPerPlant;
  final bool includesSystemLosses;

  /// Cómo se lo decimos al productor. Se elige la unidad que él usa, no la
  /// que es técnicamente más elegante: milímetros para parcela, litros por
  /// planta para huerto y maceta.
  String headlineEs({bool preferPerPlant = false}) {
    final lpp = litersPerPlant;
    if (preferPerPlant && lpp != null) {
      return 'Riega unos ${lpp.toStringAsFixed(lpp < 10 ? 1 : 0)} litros '
          'por planta';
    }
    return 'Riega unos ${grossMm.toStringAsFixed(grossMm < 10 ? 1 : 0)} mm '
        '(${litersPerSquareMeter.toStringAsFixed(0)} litros por m²)';
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'netMm': netMm,
    'grossMm': grossMm,
    'litersPerM2': litersPerSquareMeter,
    'm3PerHa': cubicMetersPerHectare,
    'litersPerPlant': litersPerPlant,
    'includesSystemLosses': includesSystemLosses,
  };
}
