// lib/core/agro/water/soil_water_scale.dart
//
// EL CONTRATO DE UNIDAD DE HUMEDAD. Fuente única de verdad.
//
// ─────────────────────────────────────────────────────────────────────────────
// QUÉ ES `soilMoisturePct`
// ─────────────────────────────────────────────────────────────────────────────
//
// Es **contenido volumétrico de agua (VWC)** expresado en por ciento, es decir
// m³ de agua por m³ de suelo × 100. Lo entrega el sensor ya convertido: el
// aparato mide por FDR (reflectometría en dominio de frecuencia) la constante
// dieléctrica del suelo y aplica su propia calibración de fábrica.
//
// Ficha del sensor comercial 8-en-1 RS485 que monta el prototipo:
//
//     Humedad del suelo ..... 0–100 % (m³/m³)   ±2 %   resolución 0.1 %
//     Temperatura ........... −40 a 80 °C       ±0.3 °C
//     CE .................... 0–20 000 µS/cm    ±3 %
//     pH .................... 3–10              ±0.2
//     N / P / K ............. 0–1999 mg/kg      ±3 %   (ver nota abajo)
//
// NO es un índice relativo aire/agua. NO es porcentaje de agua disponible.
// NO requiere calibración de dos puntos por parte del usuario para la humedad.
//
// ─────────────────────────────────────────────────────────────────────────────
// POR QUÉ ESTE ARCHIVO EXISTE
// ─────────────────────────────────────────────────────────────────────────────
//
// Antes de escribirlo, el repositorio declaraba la escala de cuatro maneras
// incompatibles: "// %" a secas en el modelo de telemetría, "humedad
// volumétrica" en las entradas del motor de riego, "agua disponible" en el
// perfil de lechuga, y una banda de firmware que llamaba *saturado* a >60
// mientras el catálogo usaba 60 como piso del óptimo.
//
// La consecuencia era concreta y grave: los objetivos de humedad de los
// cultivos de suelo se autoraron contra una escala de sustrato de maceta. Un
// huerto de manzano en suelo franco perfectamente regado lee **28 % VWC** y el
// catálogo pedía 60–80 %. La app habría dicho "riega" el 95 % del tiempo, para
// siempre, y la alarma de encharcamiento —cuyo umbral estaba en 90 %— era
// físicamente inalcanzable, porque ningún suelo mineral del planeta llega ahí.
//
// Regla a partir de hoy: **nadie compara un VWC crudo contra un número escrito
// a mano.** Todo objetivo de humedad se deriva de la textura del suelo, y de
// ahí a % de agotamiento, que es la variable en la que sí habla la agronomía.
//
// ─────────────────────────────────────────────────────────────────────────────
// NOTA SOBRE N, P y K — no pertenece a este archivo pero se anota aquí porque
// es el mismo sensor y la misma clase de error
// ─────────────────────────────────────────────────────────────────────────────
//
// Los canales N, P y K de este sensor **se derivan de la conductividad
// eléctrica; no se miden químicamente**. El propio fabricante los declara
// aptos "para registro de tendencias, no como valores absolutos de nutriente".
// El ±3 % de la ficha es repetibilidad del aparato, no concordancia con un
// laboratorio. Trabajo revisado por pares sobre sondas capacitivas encuentra
// señal significativa solo para potasio; para nitrógeno y fósforo, ninguna.
//
// El motor nutrimental sigue siendo válido —la agronomía que hay escrita ahí
// es buena—, pero su entrada es un índice, no un análisis. Ver los barandales
// añadidos en `fertilization_planner.dart`.

import 'package:flutter/foundation.dart';

/// Texturas de suelo reconocidas, con sus constantes hídricas.
///
/// Los valores son los de referencia de extensión agrícola (USDA / METER
/// Group / Oklahoma State), en % VWC. Son promedios de clase textural: sirven
/// para decidir riego con un margen sano, no para un estudio de suelos.
///
/// [pottingMix] existe porque **no es un error del catálogo**: los perfiles de
/// ornamentales y cactáceas se autoraron contra sustrato de maceta (turba /
/// coco), y ahí una capacidad de campo de 55–80 % VWC es correcta. Lo que
/// estaba mal era aplicar esa misma escala a un manzano en suelo. Al separar
/// las dos texturas, el trabajo de ornamentales se conserva íntegro.
enum SoilTexture {
  sandy,
  sandyLoam,
  loam,
  clayLoam,
  clay,
  pottingMix,
  unknown;

  /// Etiqueta para el productor. Deliberadamente sin jerga: nadie en campo
  /// dice "franco-arcilloso", dice "tierra pesada".
  String get labelEs => switch (this) {
    SoilTexture.sandy => 'Arenosa (se escurre rápido)',
    SoilTexture.sandyLoam => 'Ligera (arenosa con algo de tierra)',
    SoilTexture.loam => 'Media (la más común)',
    SoilTexture.clayLoam => 'Pesada (se hace terrón)',
    SoilTexture.clay => 'Muy pesada (barro, se agrieta al secar)',
    SoilTexture.pottingMix => 'Sustrato de maceta',
    SoilTexture.unknown => 'No la sé',
  };

  /// Pista para el wizard: cómo reconocerla apretando un puño de tierra
  /// húmeda. Es la prueba de campo estándar y no necesita instrumento.
  String get fieldHintEs => switch (this) {
    SoilTexture.sandy => 'Se deshace en cuanto abres la mano.',
    SoilTexture.sandyLoam => 'Forma bolita pero se rompe al tocarla.',
    SoilTexture.loam => 'Forma bolita que aguanta y se puede alisar un poco.',
    SoilTexture.clayLoam => 'Forma una cinta corta al aplastarla entre dedos.',
    SoilTexture.clay => 'Forma una cinta larga y brillosa; se pega.',
    SoilTexture.pottingMix => 'Mezcla comprada en bolsa, ligera y esponjosa.',
    SoilTexture.unknown => '',
  };

  String get id => name;

  static SoilTexture fromId(String? raw) {
    final v = raw?.trim().toLowerCase();
    if (v == null || v.isEmpty) return SoilTexture.unknown;
    for (final t in SoilTexture.values) {
      if (t.name.toLowerCase() == v) return t;
    }
    // Alias tolerantes: la app y BioG Admin han usado nombres distintos.
    return switch (v) {
      'arenoso' || 'arenosa' || 'sand' => SoilTexture.sandy,
      'franco_arenoso' || 'ligero' || 'ligera' => SoilTexture.sandyLoam,
      'franco' || 'medio' || 'media' || 'loamy' => SoilTexture.loam,
      'franco_arcilloso' || 'pesado' || 'pesada' => SoilTexture.clayLoam,
      'arcilloso' || 'arcillosa' || 'barro' => SoilTexture.clay,
      'maceta' || 'sustrato' || 'potting' || 'pot' => SoilTexture.pottingMix,
      _ => SoilTexture.unknown,
    };
  }
}

/// Constantes hídricas de una textura, en % VWC.
@immutable
class SoilWaterConstants {
  const SoilWaterConstants({
    required this.wiltingPointPct,
    required this.fieldCapacityPct,
    required this.saturationPct,
  });

  /// Punto de marchitez permanente. Debajo de aquí la planta ya no puede
  /// extraer agua aunque quede humedad en el suelo.
  final double wiltingPointPct;

  /// Capacidad de campo: lo que el suelo retiene contra la gravedad, 24–48 h
  /// después de un riego pesado. Es el "lleno" del depósito.
  final double fieldCapacityPct;

  /// Saturación ≈ porosidad total. Todos los poros con agua, cero aire.
  /// Sostenido, esto asfixia raíces y es la puerta de entrada de *Phytophthora*.
  final double saturationPct;

  /// Agua disponible total: lo que la planta puede usar.
  double get availableWaterPct => fieldCapacityPct - wiltingPointPct;
}

/// La escala. Todo lo que convierte VWC en algo agronómico pasa por aquí.
abstract final class SoilWaterScale {
  /// Versión del contrato. Va dentro de cada registro de trazabilidad: si
  /// estas constantes cambian, las recomendaciones viejas no se reescriben.
  static const String contractVersion = 'moisture-vwc-1.0';

  /// Unidad declarada, para que aparezca literal en la evidencia y en el PDF.
  static const String unitEs = '% VWC (m³ de agua por m³ de suelo)';

  static const Map<SoilTexture, SoilWaterConstants> _table = {
    SoilTexture.sandy: SoilWaterConstants(
      wiltingPointPct: 5,
      fieldCapacityPct: 12,
      saturationPct: 38,
    ),
    SoilTexture.sandyLoam: SoilWaterConstants(
      wiltingPointPct: 8,
      fieldCapacityPct: 18,
      saturationPct: 43,
    ),
    SoilTexture.loam: SoilWaterConstants(
      wiltingPointPct: 13,
      fieldCapacityPct: 28,
      saturationPct: 48,
    ),
    SoilTexture.clayLoam: SoilWaterConstants(
      wiltingPointPct: 19,
      fieldCapacityPct: 34,
      saturationPct: 50,
    ),
    SoilTexture.clay: SoilWaterConstants(
      wiltingPointPct: 25,
      fieldCapacityPct: 40,
      saturationPct: 53,
    ),
    // Turba / coco. Retiene muchísimo más y satura más alto: por eso los
    // perfiles de ornamentales en maceta viven en otro mundo numérico y
    // estaban bien como estaban.
    SoilTexture.pottingMix: SoilWaterConstants(
      wiltingPointPct: 22,
      fieldCapacityPct: 62,
      saturationPct: 85,
    ),
  };

  /// Constantes de una textura. [SoilTexture.unknown] cae a franco porque es
  /// la clase textural más común y la que menos daño hace si se equivoca: sus
  /// umbrales quedan entre los de arena y los de arcilla.
  ///
  /// Quien use este fallback DEBE declararlo en las limitaciones de la
  /// decisión y bajar la confianza. Ver [isFallback].
  static SoilWaterConstants constantsOf(SoilTexture texture) =>
      _table[texture] ?? _table[SoilTexture.loam]!;

  static bool isFallback(SoilTexture texture) =>
      texture == SoilTexture.unknown || !_table.containsKey(texture);

  /// Fracción de agua disponible que queda: 1.0 = capacidad de campo,
  /// 0.0 = punto de marchitez. Recortada a [0, 1] porque por encima de
  /// capacidad de campo el exceso no es agua *disponible*, es agua drenando.
  static double availableWater01(double vwcPct, SoilTexture texture) {
    final c = constantsOf(texture);
    final aw = c.availableWaterPct;
    if (aw <= 0) return 0;
    final f = (vwcPct - c.wiltingPointPct) / aw;
    if (f.isNaN || !f.isFinite) return 0;
    return f.clamp(0.0, 1.0);
  }

  /// Agotamiento en %: 0 = depósito lleno, 100 = punto de marchitez.
  /// Es la variable en la que está escrita la literatura de riego.
  static double depletionPct(double vwcPct, SoilTexture texture) =>
      (1.0 - availableWater01(vwcPct, texture)) * 100.0;

  /// True si el suelo está encharcado de verdad.
  ///
  /// El corte en 0.90 × saturación no es arbitrario: por encima de ~90 % de la
  /// porosidad total el aire remanente ya no basta para la respiración
  /// radicular, y es el umbral que importa para *Phytophthora* en aguacate,
  /// cítrico y nogal. Con las constantes de arriba, un franco dispara a 43.2 %
  /// VWC — un valor que un sensor real alcanza tras una lluvia fuerte, que es
  /// justo el punto: **la alarma tiene que ser alcanzable.**
  static double waterloggingThresholdPct(SoilTexture texture) =>
      constantsOf(texture).saturationPct * 0.90;

  static bool isWaterlogged(double vwcPct, SoilTexture texture) =>
      vwcPct >= waterloggingThresholdPct(texture);

  /// Lámina de riego neta, en milímetros: cuánta agua falta para volver a
  /// capacidad de campo.
  ///
  ///     lámina (mm) = (θcc − θactual) / 100 × profundidad radicular (mm)
  ///
  /// Ejemplo: suelo franco (θcc 28 %) leyendo 20 %, raíz de 40 cm →
  /// (0.28 − 0.20) × 400 mm = **32 mm**, que son 32 L/m² y 320 m³/ha.
  ///
  /// Devuelve `null` cuando falta cualquier ingrediente o cuando el suelo ya
  /// está por encima de capacidad de campo: en ese caso no hay lámina que
  /// aplicar y fingir un número sería peor que callarse.
  static double? netIrrigationDepthMm({
    required double vwcPct,
    required SoilTexture texture,
    required double? rootDepthCm,
  }) {
    if (rootDepthCm == null || rootDepthCm <= 0) return null;
    final c = constantsOf(texture);
    final deficitPct = c.fieldCapacityPct - vwcPct;
    if (deficitPct <= 0) return null;
    final mm = (deficitPct / 100.0) * (rootDepthCm * 10.0);
    if (!mm.isFinite || mm <= 0) return null;
    return mm;
  }

  /// Lámina bruta: la que hay que aplicar contando las pérdidas del sistema.
  /// Sin eficiencia declarada devuelve la neta, y quien la muestre debe decir
  /// que no incluye pérdidas.
  static double? grossIrrigationDepthMm({
    required double vwcPct,
    required SoilTexture texture,
    required double? rootDepthCm,
    double? systemEfficiency01,
  }) {
    final net = netIrrigationDepthMm(
      vwcPct: vwcPct,
      texture: texture,
      rootDepthCm: rootDepthCm,
    );
    if (net == null) return null;
    final eff = systemEfficiency01;
    if (eff == null || eff <= 0 || eff > 1) return net;
    return net / eff;
  }

  /// 1 mm de lámina = 1 litro por metro cuadrado. Identidad exacta, no
  /// aproximación: 1 L sobre 1 m² son 0.001 m³ / 1 m² = 1 mm de altura.
  static double litersPerSquareMeter(double mm) => mm;

  /// Metros cúbicos por hectárea. 1 mm × 10 000 m² = 10 m³.
  static double cubicMetersPerHectare(double mm) => mm * 10.0;

  /// Litros por planta, para huerto y maceta, donde "milímetros" no significa
  /// nada para el productor. Necesita la superficie que moja cada planta.
  static double? litersPerPlant(double mm, double? wettedAreaM2PerPlant) {
    if (wettedAreaM2PerPlant == null || wettedAreaM2PerPlant <= 0) return null;
    return mm * wettedAreaM2PerPlant;
  }
}

/// Eficiencias de aplicación por sistema de riego. Valores de referencia de
/// FAO / extensión; conservadores a propósito, porque quedarse corto en la
/// lámina se corrige con el siguiente riego y pasarse se pierde por lixiviación
/// —llevándose el nitrógeno—.
enum IrrigationSystem {
  drip(0.90, 'Goteo'),
  microSprinkler(0.85, 'Microaspersión'),
  sprinkler(0.75, 'Aspersión'),
  furrow(0.60, 'Rodado / surcos'),
  flood(0.50, 'Inundación'),
  manual(0.70, 'Manguera o regadera'),
  unknown(0.75, 'No lo sé');

  const IrrigationSystem(this.efficiency01, this.labelEs);
  final double efficiency01;
  final String labelEs;

  static IrrigationSystem fromId(String? raw) {
    final v = raw?.trim().toLowerCase();
    if (v == null || v.isEmpty) return IrrigationSystem.unknown;
    for (final s in IrrigationSystem.values) {
      if (s.name.toLowerCase() == v) return s;
    }
    return switch (v) {
      'goteo' => IrrigationSystem.drip,
      'microaspersion' || 'microaspersión' => IrrigationSystem.microSprinkler,
      'aspersion' || 'aspersión' => IrrigationSystem.sprinkler,
      'rodado' || 'surcos' || 'gravedad' => IrrigationSystem.furrow,
      'inundacion' || 'inundación' || 'melgas' => IrrigationSystem.flood,
      'manguera' || 'manual' || 'regadera' => IrrigationSystem.manual,
      _ => IrrigationSystem.unknown,
    };
  }
}
