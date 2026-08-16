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
import 'package:bio_g/core/agro/water/soil_profile_resolver.dart';
import 'package:bio_g/core/agro/water/soil_texture_source.dart';
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
    this.wettedAreaM2PerPlant,
    this.textureSource = SoilTextureSource.unknown,
  });

  final AgroRange range;
  final SoilTexture texture;

  /// De dónde salió la textura. Va al registro auditable: no es lo mismo que
  /// el productor la haya declarado a que la hayamos deducido del equipo.
  final SoilTextureSource textureSource;

  final CropWaterPolicy policy;

  /// MAD ya ajustado por etapa.
  final double effectiveDepletion;

  /// Listo para pasar al motor: ya lleva θcc, θpmp, profundidad y eficiencia.
  /// Esto es lo que hace que `supportsWaterBalance` sea true por primera vez.
  final SoilContext soilContext;

  /// Qué no sabemos. Va a la decisión, no a la basura.
  final List<String> limitationsEs;

  /// Solo la limitación de TEXTURA, si la hay.
  ///
  /// Existe separada porque es la única que corresponde al código de motivo
  /// `soilProfileMissing`. Volcar la lista entera bajo ese código etiquetaría
  /// «sin cultivo declarado» y «no sabemos cómo riegas» como problemas de
  /// perfil de suelo, que no lo son.
  String? get textureLimitationEs =>
      isFallbackTexture && limitationsEs.isNotEmpty ? limitationsEs.first : null;

  final bool isFallbackTexture;
  final bool isFallbackCrop;

  /// Superficie mojada por planta, ya resuelta: la del llamador si la impuso,
  /// la del cultivo si no. Estaba declarada como parámetro y no se leía nunca,
  /// así que imponerla no tenía efecto.
  final double? wettedAreaM2PerPlant;

  /// Confianza que se debe restar por lo que se asumió.
  double get confidencePenalty {
    var p = 0.0;
    if (isFallbackTexture) p += 0.15;
    if (isFallbackCrop) p += 0.10;
    return p;
  }

  /// En cuál de los cinco estados cae una lectura, con esta textura y este
  /// coeficiente de agotamiento ya ajustado por etapa.
  SoilMoistureState stateFor(double vwcPct) => SoilWaterScale.stateOf(
    vwcPct: vwcPct,
    texture: texture,
    allowableDepletionFraction: effectiveDepletion,
  );

  /// Lo que hay que guardar junto a la decisión para poder auditarla después.
  ///
  /// Es la capa intermedia del historial de tres capas: la telemetría es
  /// inmutable porque es un hecho físico; **esto también es inmutable**, porque
  /// se adjunta a la decisión en el momento de tomarla. Si el productor corrige
  /// su textura dos meses después, la gráfica puede reinterpretarse; la
  /// decisión, no.
  Map<String, Object?> toDecisionContextJson() => <String, Object?>{
    'soilTextureId': texture.id,
    'soilTextureSource': textureSource.id,
    'isFallbackTexture': isFallbackTexture,
    'isFallbackCrop': isFallbackCrop,
    'waterModelVersion': SoilWaterScale.contractVersion,
    'moistureTargetResolverVersion': MoistureTargetResolver.version,
    'cropWaterPolicyVersion': CropWaterPolicies.version,
    'soilProfileResolverVersion': SoilProfileResolver.version,
    'waterGroup': policy.group.name,
    'effectiveDepletion': effectiveDepletion,
    'rootDepthCm': soilContext.rootDepthCm,
    'fieldCapacityPct': soilContext.fieldCapacityPct,
    'wiltingPointPct': soilContext.wiltingPointPct,
    'confidencePenalty': confidencePenalty,
    'limitationsEs': List<String>.of(limitationsEs),
  };
}

abstract final class MoistureTargetResolver {
  static const String version = 'moisture-target-resolver-1.0';

  /// Cuánto por debajo del punto de reposición empieza el estrés real.
  /// 1.5 × MAD es el criterio conservador: entre `optimalMin` y `lowMax` la
  /// planta ya está trabajando de más, pero todavía no hay daño irreversible.
  static const double _criticalFactor = 1.5;

  /// Punto de entrada preferido: recibe el medio **ya resuelto** por
  /// [SoilProfileResolver], que es quien conoce la jerarquía equipo → escala →
  /// textura declarada. Así la regla de «el hardware manda» vive en un solo
  /// sitio y este archivo solo hace aritmética.
  static ResolvedMoistureTarget resolveForSoilProfile({
    required ResolvedSoilProfile soilProfile,
    required CropKey? cropKey,
    String? stageKey,
    double? rootDepthCmOverride,
    IrrigationSystem system = IrrigationSystem.unknown,
    double? wettedAreaM2PerPlantOverride,
  }) {
    return _build(
      cropKey: cropKey,
      stageKey: stageKey,
      effectiveTexture: soilProfile.texture,
      textureSource: soilProfile.source,
      isFallbackTexture: soilProfile.isFallback,
      extraLimitations: soilProfile.limitationsEs,
      rootDepthCmOverride: rootDepthCmOverride,
      system: system,
      wettedAreaM2PerPlantOverride: wettedAreaM2PerPlantOverride,
    );
  }

  static ResolvedMoistureTarget resolve({
    required CropKey? cropKey,
    String? stageKey,
    SoilTexture texture = SoilTexture.unknown,
    bool isPotted = false,
    SoilTextureSource? textureSource,
    double? rootDepthCmOverride,
    IrrigationSystem system = IrrigationSystem.unknown,
    double? wettedAreaM2PerPlantOverride,
  }) {
    // Maceta manda sobre textura declarada: un cactus en maceta vive en
    // sustrato aunque el productor haya dicho que su tierra es arcillosa.
    final effectiveTexture = isPotted ? SoilTexture.pottingMix : texture;

    return _build(
      cropKey: cropKey,
      stageKey: stageKey,
      effectiveTexture: effectiveTexture,
      textureSource:
          textureSource ??
          (isPotted
              ? SoilTextureSource.derivedFromScale
              : effectiveTexture == SoilTexture.unknown
              ? SoilTextureSource.unknown
              : SoilTextureSource.declared),
      isFallbackTexture: !isPotted && SoilWaterScale.isFallback(effectiveTexture),
      extraLimitations: const <String>[],
      rootDepthCmOverride: rootDepthCmOverride,
      system: system,
      wettedAreaM2PerPlantOverride: wettedAreaM2PerPlantOverride,
    );
  }

  static ResolvedMoistureTarget _build({
    required CropKey? cropKey,
    required String? stageKey,
    required SoilTexture effectiveTexture,
    required SoilTextureSource textureSource,
    required bool isFallbackTexture,
    required List<String> extraLimitations,
    required double? rootDepthCmOverride,
    required IrrigationSystem system,
    required double? wettedAreaM2PerPlantOverride,
  }) {
    final isFallbackCrop = CropWaterPolicies.isGenericFallback(cropKey);

    final c = SoilWaterScale.constantsOf(effectiveTexture);
    final policy = CropWaterPolicies.forCrop(cropKey);
    final mad = CropWaterPolicies.allowableDepletionForStage(
      policy,
      stageKey,
      cropKey: cropKey,
    );

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
    for (final l in extraLimitations) {
      if (l.trim().isNotEmpty && !limitations.contains(l)) limitations.add(l);
    }
    if (isFallbackTexture) {
      const fallbackText =
          'No sabemos qué tierra tienes, así que usamos la más común (media). '
          'Si es muy arenosa o muy pesada, los umbrales cambian bastante.';
      if (!limitations.contains(fallbackText)) limitations.add(fallbackText);
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
      textureSource: textureSource,
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
        isFallbackTexture: isFallbackTexture,
      ),
      limitationsEs: List.unmodifiable(limitations),
      isFallbackTexture: isFallbackTexture,
      isFallbackCrop: isFallbackCrop,
      wettedAreaM2PerPlant:
          wettedAreaM2PerPlantOverride ?? policy.wettedAreaM2PerPlant,
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

    // ── La banda no es una cortesía: es el número ────────────────────────────
    //
    // La exactitud declarada del canal de humedad es de ±3 puntos de contenido
    // volumétrico en el rango bajo y ±5 por encima de 53 %. Sobre una zona
    // radicular de 40 cm, ±3 puntos son ±12 mm de lámina; sobre una lámina neta
    // calculada de 40 mm, eso es **±30 %**. Un tercio.
    //
    // Decir «aplica 40 mm» comunica una precisión que el instrumento no tiene,
    // antes siquiera de contar el error de la textura elegida a mano y el de la
    // profundidad radicular estimada.
    final uncertaintyPoints = vwcPct > 53.0 ? 5.0 : 3.0;
    final rootMm = (soil.rootDepthCm ?? 0) * 10.0;
    var uncertaintyMm = (uncertaintyPoints / 100.0) * rootMm;
    final eff = soil.systemEfficiency01;
    if (eff != null && eff > 0 && eff <= 1) uncertaintyMm = uncertaintyMm / eff;

    return IrrigationDepth(
      netMm: net,
      grossMm: mm,
      uncertaintyMm: uncertaintyMm,
      litersPerSquareMeter: SoilWaterScale.litersPerSquareMeter(mm),
      cubicMetersPerHectare: SoilWaterScale.cubicMetersPerHectare(mm),
      litersPerPlant: SoilWaterScale.litersPerPlant(
        mm,
        target.wettedAreaM2PerPlant,
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
    this.uncertaintyMm = 0,
    this.litersPerPlant,
  });

  /// Lo que le falta al suelo.
  final double netMm;

  /// Lo que hay que aplicar contando pérdidas del sistema.
  final double grossMm;

  /// Media anchura de la banda, en mm, propagada desde la exactitud declarada
  /// del sensor. Nunca se muestra sola: se muestra como banda.
  final double uncertaintyMm;

  final double litersPerSquareMeter;
  final double cubicMetersPerHectare;
  final double? litersPerPlant;
  final bool includesSystemLosses;

  double get lowMm {
    final v = grossMm - uncertaintyMm;
    return v < 0 ? 0 : v;
  }

  double get highMm => grossMm + uncertaintyMm;

  /// True cuando la banda es tan ancha que dar dos números es más honesto que
  /// dar uno. Por debajo de eso, «unos X mm» ya comunica la aproximación.
  bool get needsBand => uncertaintyMm > 0 && uncertaintyMm / grossMm >= 0.12;

  /// Cómo se lo decimos al productor. Se elige la unidad que él usa, no la
  /// que es técnicamente más elegante: milímetros para parcela, litros por
  /// planta para huerto y maceta.
  ///
  /// **Nunca una cifra cerrada.** O «unos 40 mm» o «entre 30 y 50 mm».
  String headlineEs({bool preferPerPlant = false}) {
    final lpp = litersPerPlant;
    if (preferPerPlant && lpp != null) {
      return 'Riega unos ${_fmt(lpp)} litros por planta';
    }
    if (needsBand) {
      return 'Riega entre ${_fmt(lowMm)} y ${_fmt(highMm)} mm '
          '(${_fmt(lowMm)}–${_fmt(highMm)} litros por m²)';
    }
    return 'Riega unos ${_fmt(grossMm)} mm '
        '(${litersPerSquareMeter.toStringAsFixed(0)} litros por m²)';
  }

  /// Solo la banda, para cuando la tarjeta ya trae su propio verbo.
  String bandEs() => needsBand
      ? 'entre ${_fmt(lowMm)} y ${_fmt(highMm)} mm'
      : 'unos ${_fmt(grossMm)} mm';

  static String _fmt(double v) => v.toStringAsFixed(v < 10 ? 1 : 0);

  Map<String, Object?> toJson() => <String, Object?>{
    'netMm': netMm,
    'grossMm': grossMm,
    'uncertaintyMm': uncertaintyMm,
    'lowMm': lowMm,
    'highMm': highMm,
    'litersPerM2': litersPerSquareMeter,
    'm3PerHa': cubicMetersPerHectare,
    'litersPerPlant': litersPerPlant,
    'includesSystemLosses': includesSystemLosses,
  };
}
