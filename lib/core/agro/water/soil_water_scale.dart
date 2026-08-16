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

  /// Sustrato drenante de cactácea: perlita, arena o pómez sobre poca materia
  /// orgánica. Existe porque **una sola fila de sustrato no puede servir para
  /// un cactus y para una lechuga en maceta**: no es un conflicto de números,
  /// es una diferencia de hidráulica. Drena rápido, retiene poco y se seca
  /// parejo. Sus constantes se calibraron contra los rangos que ya tenían
  /// escritos cactus, nopal, agave y suculentas (ver [SoilWaterScale._table]).
  ///
  /// Nunca se pregunta: se deriva del grupo hídrico del cultivo (xerófito) más
  /// el medio de maceta. Ver `SoilProfileResolver`.
  pottingMixDraining,
  unknown;

  /// Nombre técnico, el que va como protagonista en la pantalla de selección.
  /// Es el vocabulario del mapa de suelos, para quien ya lo conoce.
  String get displayNameEs => switch (this) {
    SoilTexture.sandy => 'Arenosa',
    SoilTexture.sandyLoam => 'Franco-arenosa',
    SoilTexture.loam => 'Franca',
    SoilTexture.clayLoam => 'Franco-arcillosa',
    SoilTexture.clay => 'Arcillosa',
    SoilTexture.pottingMix => 'Sustrato de maceta',
    SoilTexture.pottingMixDraining => 'Sustrato drenante',
    SoilTexture.unknown => 'No estoy seguro',
  };

  /// Nombre corto y cotidiano. Va debajo del técnico, en chip pequeño, y es el
  /// que se reutiliza en listas, resúmenes y chips de Cuenta.
  ///
  /// Existe como campo propio —y no parseando el paréntesis de [labelEs]— para
  /// que haya **una sola fuente de verdad para el texto**.
  String get shortLabelEs => switch (this) {
    SoilTexture.sandy => 'Arenosa',
    SoilTexture.sandyLoam => 'Ligera',
    SoilTexture.loam => 'Media',
    SoilTexture.clayLoam => 'Pesada',
    SoilTexture.clay => 'Muy pesada',
    SoilTexture.pottingMix => 'Sustrato',
    SoilTexture.pottingMixDraining => 'Drenante',
    SoilTexture.unknown => 'Sin definir',
  };

  /// Etiqueta larga, para donde haga falta la frase completa.
  ///
  /// `loam` ya NO dice «la más común». Presentar una opción como la más
  /// frecuente la convierte en la respuesta por defecto de quien no está
  /// seguro, y ese usuario debería marcar «No estoy seguro»: si no lo hace, el
  /// sistema pierde la capacidad de distinguir *este productor tiene suelo
  /// franco* de *este productor no sabe qué suelo tiene*, que es justo la
  /// distinción que decide si la recomendación lleva penalización de confianza.
  String get labelEs => switch (this) {
    SoilTexture.sandy => 'Arenosa — se escurre rápido',
    SoilTexture.sandyLoam => 'Ligera — arenosa con algo de barro',
    SoilTexture.loam => 'Media — tierra equilibrada',
    SoilTexture.clayLoam => 'Pesada — se hace terrones',
    SoilTexture.clay => 'Muy pesada — barro, se agrieta al secarse',
    SoilTexture.pottingMix => 'Sustrato de maceta',
    SoilTexture.pottingMixDraining => 'Sustrato drenante (cactáceas)',
    SoilTexture.unknown => 'No estoy seguro',
  };

  /// Pista para el wizard: cómo reconocerla apretando un puño de tierra
  /// húmeda. Es la prueba de campo estándar y no necesita instrumento.
  String get fieldHintEs => switch (this) {
    SoilTexture.sandy => 'No llega a formar bolita: se desmorona al abrir la mano.',
    SoilTexture.sandyLoam => 'Forma una bolita, pero se rompe fácilmente.',
    SoilTexture.loam => 'Forma una bolita firme y se puede alisar.',
    SoilTexture.clayLoam => 'Forma una tira corta entre los dedos.',
    SoilTexture.clay =>
      'Pegajosa, forma una tira larga y se agrieta al secarse.',
    SoilTexture.pottingMix => 'Mezcla comprada en bolsa, ligera y esponjosa.',
    SoilTexture.pottingMixDraining =>
      'Mezcla de cactácea: arena, perlita o pómez.',
    SoilTexture.unknown => '',
  };

  /// Cómo se ve la esfera del carrusel. **El color NO define la textura**: la
  /// diferencia visual viene de granulometría, cohesión, porosidad, bloques y
  /// microgrietas. Este texto acompaña al asset para que nadie convierta
  /// «arcillosa = roja» en una regla falsa.
  String get visualReadingEs => switch (this) {
    SoilTexture.sandy => 'Granos grandes, muy suelta, muchos espacios.',
    SoilTexture.sandyLoam => 'Granos y pequeños agregados, todavía suelta.',
    SoilTexture.loam => 'Agregados equilibrados, porosidad media.',
    SoilTexture.clayLoam => 'Bloques densos, grano fino, pocos huecos.',
    SoilTexture.clay => 'Masa fina, compacta, microgrietas discretas.',
    SoilTexture.pottingMix => 'Fibra esponjosa y oscura.',
    SoilTexture.pottingMixDraining => 'Mezcla gruesa con partícula mineral.',
    SoilTexture.unknown =>
      'Sin definir: BIO-G usará una tierra media hasta que lo sepas.',
  };

  /// La línea de una sola frase que va bajo el nombre en la pantalla de
  /// selección: dos rasgos separados por un punto medio. Es lo que el productor
  /// lee sin detenerse, así que no lleva vocabulario técnico ni cifras.
  String get plainDescriptionEs => switch (this) {
    SoilTexture.sandy => 'Suelta y granulada · El agua se va rápido',
    SoilTexture.sandyLoam => 'Ligera al tacto · Drena bien y guarda algo de humedad',
    SoilTexture.loam => 'Equilibrada · Ni muy suelta ni muy compacta',
    SoilTexture.clayLoam => 'Compacta · Forma terrones al secarse',
    SoilTexture.clay => 'Barrosa y pesada · Se agrieta al secarse',
    SoilTexture.pottingMix => 'Mezcla de maceta · Esponjosa y ligera',
    SoilTexture.pottingMixDraining => 'Mezcla de cactácea · Gruesa y mineral',
    SoilTexture.unknown => 'BIO-G usará valores medios mientras tanto',
  };

  /// Lectura cualitativa de retención de agua, de 1 a 5.
  ///
  /// Es material didáctico para que el agricultor **compare texturas entre
  /// sí**. NO es un porcentaje ni una segunda fuente de verdad agronómica: el
  /// motor sigue usando [SoilWaterScale] y sus constantes reales.
  int get waterRetention05 => switch (this) {
    SoilTexture.sandy => 1,
    SoilTexture.sandyLoam => 2,
    SoilTexture.loam => 3,
    SoilTexture.clayLoam => 4,
    SoilTexture.clay => 5,
    SoilTexture.pottingMix => 5,
    SoilTexture.pottingMixDraining => 2,
    SoilTexture.unknown => 0,
  };

  /// La palabra que acompaña a los cinco puntos de retención.
  ///
  /// Va como texto **además** del nivel pintado, nunca en su lugar: la pauta de
  /// accesibilidad del contrato prohíbe que el color o la posición sean el único
  /// portador del significado. Concuerda en femenino porque el sustantivo que la
  /// precede es «retención».
  String get retentionWordEs => switch (this) {
    SoilTexture.sandy => 'Muy baja',
    SoilTexture.sandyLoam => 'Baja',
    SoilTexture.loam => 'Media',
    SoilTexture.clayLoam => 'Alta',
    SoilTexture.clay => 'Muy alta',
    SoilTexture.pottingMix => 'Muy alta',
    SoilTexture.pottingMixDraining => 'Baja',
    SoilTexture.unknown => 'Variable',
  };

  /// La frase corta bajo los puntos de retención. Describe la consecuencia para
  /// el riego, que es lo único que el productor puede accionar.
  String get retentionSentenceEs => switch (this) {
    SoilTexture.sandy => 'Guarda poca agua: hay que regar seguido y poco.',
    SoilTexture.sandyLoam => 'Guarda algo de agua, pero se seca pronto.',
    SoilTexture.loam => 'Puede guardar buena cantidad de agua.',
    SoilTexture.clayLoam => 'Guarda mucha agua y la suelta despacio.',
    SoilTexture.clay => 'Guarda muchísima agua; tarda días en soltarla.',
    SoilTexture.pottingMix => 'La mezcla guarda mucha agua junto a la raíz.',
    SoilTexture.pottingMixDraining =>
      'Guarda poca agua a propósito, como en el desierto.',
    SoilTexture.unknown => 'Lo sabremos en cuanto definas tu tierra.',
  };

  /// Lectura cualitativa de drenaje, de 1 a 5. Misma advertencia que
  /// [waterRetention05]: es comparativa, no numérica.
  int get drainage05 => switch (this) {
    SoilTexture.sandy => 5,
    SoilTexture.sandyLoam => 4,
    SoilTexture.loam => 3,
    SoilTexture.clayLoam => 2,
    SoilTexture.clay => 1,
    SoilTexture.pottingMix => 2,
    SoilTexture.pottingMixDraining => 5,
    SoilTexture.unknown => 0,
  };

  /// La palabra que acompaña a los cinco puntos de drenaje. En masculino, por
  /// «drenaje», y en términos de velocidad —no de cantidad— para que nadie lea
  /// «alto drenaje» como «mucha agua».
  String get drainageWordEs => switch (this) {
    SoilTexture.sandy => 'Muy rápido',
    SoilTexture.sandyLoam => 'Rápido',
    SoilTexture.loam => 'Medio',
    SoilTexture.clayLoam => 'Lento',
    SoilTexture.clay => 'Muy lento',
    SoilTexture.pottingMix => 'Lento',
    SoilTexture.pottingMixDraining => 'Muy rápido',
    SoilTexture.unknown => 'Variable',
  };

  /// La frase corta bajo los puntos de drenaje.
  String get drainageSentenceEs => switch (this) {
    SoilTexture.sandy => 'El agua se va casi de inmediato.',
    SoilTexture.sandyLoam => 'El agua se infiltra rápido.',
    SoilTexture.loam => 'El agua se infiltra a un ritmo moderado.',
    SoilTexture.clayLoam => 'El agua tarda en bajar; cuidado con encharcar.',
    SoilTexture.clay => 'El agua se queda arriba y se hacen charcos.',
    SoilTexture.pottingMix => 'Drena solo por los orificios de la maceta.',
    SoilTexture.pottingMixDraining => 'El agua atraviesa la mezcla enseguida.',
    SoilTexture.unknown => 'Lo sabremos en cuanto definas tu tierra.',
  };

  /// Asset de la esfera. Los sustratos no tienen imagen propia porque **jamás
  /// se muestran**: se asignan por hardware o por escala, nunca se preguntan.
  String get assetPath => switch (this) {
    SoilTexture.sandy => 'assets/soil_textures/soil_texture_sandy.png',
    SoilTexture.sandyLoam =>
      'assets/soil_textures/soil_texture_sandy_loam.png',
    SoilTexture.loam => 'assets/soil_textures/soil_texture_loam.png',
    SoilTexture.clayLoam => 'assets/soil_textures/soil_texture_clay_loam.png',
    SoilTexture.clay => 'assets/soil_textures/soil_texture_clay.png',
    SoilTexture.pottingMix ||
    SoilTexture.pottingMixDraining ||
    SoilTexture.unknown => 'assets/soil_textures/soil_texture_unknown.png',
  };

  /// True para los sustratos de maceta. Se derivan del equipo o de la escala,
  /// nunca de una pregunta al usuario.
  bool get isSubstrate =>
      this == SoilTexture.pottingMix || this == SoilTexture.pottingMixDraining;

  /// Lo que se ofrece en el carrusel: las cinco texturas minerales de ligera a
  /// pesada, más «No estoy seguro». En este orden exacto.
  static const List<SoilTexture> selectable = <SoilTexture>[
    SoilTexture.sandy,
    SoilTexture.sandyLoam,
    SoilTexture.loam,
    SoilTexture.clayLoam,
    SoilTexture.clay,
    SoilTexture.unknown,
  ];

  String get id => name;

  static SoilTexture fromId(String? raw) {
    final v = raw?.trim().toLowerCase();
    if (v == null || v.isEmpty) return SoilTexture.unknown;
    for (final t in SoilTexture.values) {
      if (t.name.toLowerCase() == v) return t;
    }
    // Alias tolerantes: la app y BioG Admin han usado nombres distintos.
    return switch (v) {
      'arenoso' || 'arenosa' || 'sand' || 'sandy' => SoilTexture.sandy,
      'franco_arenoso' ||
      'franco-arenosa' ||
      'ligero' ||
      'ligera' => SoilTexture.sandyLoam,
      'franco' ||
      'franca' ||
      'medio' ||
      'media' ||
      'loamy' => SoilTexture.loam,
      'franco_arcilloso' ||
      'franco-arcillosa' ||
      'pesado' ||
      'pesada' => SoilTexture.clayLoam,
      'arcilloso' || 'arcillosa' || 'barro' => SoilTexture.clay,
      'maceta' || 'sustrato' || 'potting' || 'pot' => SoilTexture.pottingMix,
      'sustrato_drenante' ||
      'drenante' ||
      'potting_draining' ||
      'cactus_mix' => SoilTexture.pottingMixDraining,
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
    // ── Sustrato drenante ───────────────────────────────────────────────────
    //
    // NO son números inventados: se calibraron **hacia atrás** desde los rangos
    // que cactus, nopal y suculentas ya tenían escritos y que son correctos
    // hoy. Conectar el resolver sin hacer esto invertiría el consejo justo en
    // el grupo donde regar de más es lo que los mata.
    //
    // Con MAD xerófito 0,80 y estas constantes, el resolver reproduce el
    // catálogo vigente:
    //
    //   optimalMax = θcc                       = 52,0   (catálogo 48–54)
    //   AD         = 52 − 4                    = 48
    //   optimalMin = 52 − 0,80 × 48            = 13,6   (catálogo 10–14)
    //   lowMax     = 52 − 1,50 × 0,80 × 48     = −5,6 → tope en θpmp = 4,0
    //                                                   (catálogo 3–6)
    //   highMin    = 0,90 × 78                 = 70,2   (catálogo 68–72)
    //
    // Donde el nuevo cálculo se aparta del catálogo lo hace hacia el lado
    // seguro: exige regar antes en sábila (que la literatura pone cerca de
    // capacidad de campo) y declara «drenando» antes en suculenta.
    SoilTexture.pottingMixDraining: SoilWaterConstants(
      wiltingPointPct: 4,
      fieldCapacityPct: 52,
      saturationPct: 78,
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

  /// Clasifica una lectura en los **cinco** estados del modelo.
  ///
  /// Ver [SoilMoistureState] para por qué son cinco y no tres.
  static SoilMoistureState stateOf({
    required double vwcPct,
    required SoilTexture texture,
    required double allowableDepletionFraction,
  }) {
    final c = constantsOf(texture);
    if (vwcPct >= waterloggingThresholdPct(texture)) {
      return SoilMoistureState.waterlogged;
    }
    if (vwcPct > c.fieldCapacityPct) return SoilMoistureState.draining;

    final depletion01 = 1.0 - availableWater01(vwcPct, texture);
    if (depletion01 >= 1.0) return SoilMoistureState.belowWiltingPoint;
    if (depletion01 >= allowableDepletionFraction) {
      return SoilMoistureState.timeToIrrigate;
    }
    return SoilMoistureState.comfortable;
  }
}

/// Los cinco estados de humedad del suelo.
///
/// ─────────────────────────────────────────────────────────────────────────────
/// POR QUÉ CINCO Y NO TRES
/// ─────────────────────────────────────────────────────────────────────────────
///
/// El modelo tiene **tres cotas separadas** —capacidad de campo, saturación y
/// umbral de encharcamiento— y hay que usar las tres. Confundir «por encima de
/// capacidad de campo» con «encharcado» genera exactamente la alarma falsa que
/// este trabajo pretende eliminar.
///
/// El caso concreto: 18 % de humedad en suelo arenoso. Sus cotas son 12 / 38 /
/// 34,2. Esa lectura está por encima de capacidad de campo pero **dieciséis
/// puntos por debajo** del umbral de encharcamiento. Es el estado normal de un
/// suelo unas horas después de un riego o de una lluvia: el agua gravitacional
/// todavía se está yendo. Llamarlo anoxia es un error de lectura, no de sensor.
enum SoilMoistureState {
  /// Lectura ≥ umbral de encharcamiento. Riesgo real de anoxia y de enfermedad
  /// de raíz. Es la alerta que hoy no existe.
  waterlogged,

  /// Por encima de capacidad de campo pero por debajo del umbral. Estado normal
  /// tras un riego o una lluvia. **No es alarma.**
  draining,

  /// Agotamiento entre 0 y p. No hace falta regar.
  comfortable,

  /// Agotamiento ≥ p (coeficiente del cultivo, ajustado por etapa).
  timeToIrrigate,

  /// Agotamiento ≥ 1. Estrés severo: la planta ya no puede extraer agua.
  belowWiltingPoint;

  String get labelEs => switch (this) {
    SoilMoistureState.waterlogged => 'Encharcado',
    SoilMoistureState.draining => 'Drenando',
    SoilMoistureState.comfortable => 'Cómodo',
    SoilMoistureState.timeToIrrigate => 'Toca regar',
    SoilMoistureState.belowWiltingPoint => 'Bajo punto de marchitez',
  };

  /// Lo que se le dice al agricultor, en su idioma y sin dramatizar el estado
  /// que es normal.
  String get farmerCopyEs => switch (this) {
    SoilMoistureState.waterlogged =>
      'El suelo está encharcado. Hay riesgo real de asfixia de raíz: no riegues '
          'y revisa el drenaje.',
    SoilMoistureState.draining =>
      'El suelo tiene más agua de la que retiene. Es normal tras un riego o una '
          'lluvia: el agua de más se está yendo sola.',
    SoilMoistureState.comfortable => 'La humedad está donde debe. No hace falta regar.',
    SoilMoistureState.timeToIrrigate => 'Toca regar.',
    SoilMoistureState.belowWiltingPoint =>
      'La planta ya no puede sacar agua del suelo. Riega en cuanto puedas.',
  };

  /// Solo el encharcamiento y el marchitamiento son alarma. Los otros tres son
  /// información.
  bool get isAlarm =>
      this == SoilMoistureState.waterlogged ||
      this == SoilMoistureState.belowWiltingPoint;
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
