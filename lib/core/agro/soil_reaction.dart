/// =========================================================================
/// REACCIÓN DEL SUELO Y CALIBRACIÓN DEL FÓSFORO
/// =========================================================================
///
/// EL PROBLEMA
/// -----------
/// Un rango de fósforo en suelo sin declarar el método de extracción del
/// laboratorio es casi ruido. Para el mismo cultivo y el mismo estado:
///
///   Olsen ......................... «alto» empieza en 25 ppm
///   Bray-1 ........................ «alto» empieza en 40 ppm
///   Mehlich-3, suelo ácido ........ «alto» empieza en 45 ppm
///   Mehlich-3, suelo calcáreo ..... «alto» empieza en 113 ppm
///
/// Un abanico de 4.5×. Y no es que unos midan mejor que otros: miden cosas
/// distintas. En suelo calcáreo el calcio fija el fósforo, así que la misma
/// cifra de laboratorio representa **menos fósforo disponible** para la
/// planta. Por eso el umbral tiene que subir.
///
/// LA CONSECUENCIA PARA BIO-G
/// --------------------------
/// Los rangos de fósforo de los perfiles están calibrados contra la tabla de
/// suelo mineral. En un suelo calcáreo —Chihuahua lo es, y buena parte del
/// norte de México también— el motor lee «óptimo» donde el laboratorio local
/// diría «bajo», y **deja de recomendar fósforo que sí hacía falta**.
///
/// No es un error de programación: es una calibración que faltaba.
///
/// LA SOLUCIÓN, Y POR QUÉ NO PIDE NADA AL USUARIO
/// ----------------------------------------------
/// UF/IFAS publica las dos calibraciones Mehlich-3 del mismo cultivo:
///
///   suelo mineral ácido ..... bajo ≤25 · medio 26–45 · alto >45 ppm
///   suelo calcáreo .......... bajo ≤76 · medio 77–104 · alto >104 ppm
///
/// Y el pH ya viene en cada lectura del sensor. No hay que preguntar nada.
/// =========================================================================
library;

import 'package:bio_g/core/agro/agro_types.dart';

/// Reacción del suelo, deducida del pH que ya mide el sensor.
enum SoilReaction {
  /// pH por debajo de 6.5. El fósforo se fija con hierro y aluminio.
  acidic,

  /// pH entre 6.5 y 7.2. La zona de mayor disponibilidad de fósforo.
  neutral,

  /// pH de 7.3 en adelante. Presencia probable de carbonatos libres; el
  /// calcio fija el fósforo y baja su disponibilidad.
  calcareous,

  /// Sin lectura de pH utilizable. El motor no supone: se comporta como si
  /// el suelo fuera neutro y no ajusta nada.
  unknown,
}

/// Deduce la reacción del suelo a partir del pH.
///
/// **Esto es un indicio, no una medición de carbonatos.** Lo estricto sería
/// una prueba de efervescencia con ácido o un análisis de carbonato de calcio
/// equivalente. Pero un pH sostenido por encima de 7.3 en suelo agrícola
/// prácticamente siempre significa carbonatos libres, y el pH es lo que el
/// sensor tiene.
///
/// El corte se puso en 7.3 y no en 7.0 a propósito: se prefiere **no ajustar
/// de más**. Un suelo neutro clasificado como calcáreo recibiría fósforo de
/// sobra, y pasarse tiene costo. Quedarse corto solo mantiene el
/// comportamiento actual.
SoilReaction soilReactionFromPh(double? ph) {
  if (ph == null || !ph.isFinite) return SoilReaction.unknown;
  if (ph <= 0 || ph >= 14) return SoilReaction.unknown;
  if (ph < 6.5) return SoilReaction.acidic;
  if (ph <= 7.2) return SoilReaction.neutral;
  return SoilReaction.calcareous;
}

/// Etiqueta en español, para el texto de transparencia.
String soilReactionLabelEs(SoilReaction r) => switch (r) {
  SoilReaction.acidic => 'ácido',
  SoilReaction.neutral => 'neutro',
  SoilReaction.calcareous => 'calcáreo',
  SoilReaction.unknown => 'sin determinar',
};

/// Factor que desplaza la banda objetivo de fósforo según la reacción.
///
/// DE DÓNDE SALE EL 1.75
/// ---------------------
/// Se calibra contra la banda calcárea publicada por UF/IFAS (medio 77–104,
/// punto medio 90.5) partiendo del punto medio de la banda de fósforo que
/// BIO-G usa en la etapa de referencia —floración de hortaliza, 42–62, punto
/// medio 52:
///
///     90.5 ÷ 52 ≈ 1.74  →  se adopta 1.75
///
/// Se aplica el **mismo factor a todas las etapas**, no uno por etapa. Así se
/// conserva intacta la forma de la curva fenológica que ya estaba afinada, y
/// solo se desplaza el nivel completo. Si algún día se calibra etapa por
/// etapa, este es el número que hay que sustituir.
///
/// NO SE TOCAN NITRÓGENO NI POTASIO
/// --------------------------------
/// El efecto de los carbonatos sobre el fósforo está publicado y cuantificado
/// —son dos tablas distintas del mismo servicio de extensión—. Para N y K no
/// existe una calibración calcárea equivalente, así que ajustarlos sería
/// inventar. Se quedan como están.
const double kPhosphorusCalcareousFactor = 1.75;

double phosphorusTargetFactor(SoilReaction reaction) {
  return reaction == SoilReaction.calcareous
      ? kPhosphorusCalcareousFactor
      : 1.0;
}

/// Aplica el desplazamiento calcáreo a un rango de fósforo.
///
/// Devuelve el mismo rango sin tocar cuando el nutriente no es fósforo o
/// cuando el suelo no es calcáreo. Es deliberadamente aburrido: un ajuste que
/// se aplica donde no debe es peor que no tener ajuste.
AgroRange adjustRangeForSoilReaction({
  required AgroRange range,
  required AgroMetricKey nutrient,
  required SoilReaction reaction,
}) {
  if (nutrient != AgroMetricKey.p) return range;
  final double f = phosphorusTargetFactor(reaction);
  if (f == 1.0) return range;

  return AgroRange(
    lowMax: range.lowMax * f,
    optimalMin: range.optimalMin * f,
    optimalMax: range.optimalMax * f,
    highMin: range.highMin * f,
  );
}

/// Frase que explica el ajuste, para que el número no aparezca sin motivo.
///
/// Devuelve `null` cuando no hubo ajuste: no se le cuenta al agricultor algo
/// que no pasó.
String? soilReactionNoteEs({
  required AgroMetricKey nutrient,
  required SoilReaction reaction,
  double? ph,
}) {
  if (nutrient != AgroMetricKey.p) return null;
  if (reaction != SoilReaction.calcareous) return null;

  final String phText = ph == null ? '' : ' (pH ${ph.toStringAsFixed(1)})';
  return 'Tu suelo se leyó calcáreo$phText. En suelo calcáreo el calcio fija '
      'el fósforo, así que hace falta más fósforo en el análisis para que la '
      'planta tenga el mismo disponible: BIO-G subió la meta de fósforo en '
      'consecuencia. Si tu laboratorio reporta con método Olsen, compara '
      'contra su escala, no contra esta.';
}

// ═══════════════════════════════════════════════════════════════════════════
// VOLATILIZACIÓN DE UREA
// ═══════════════════════════════════════════════════════════════════════════

/// Advierte cuando aplicar urea al voleo va a perder una parte grande.
///
/// En suelo calcáreo la urea aplicada en superficie y sin incorporar pierde
/// **40 % a pH 7.0 y 44 % a pH 7.5 en diez días** por volatilización de
/// amoniaco. No es una pérdida menor: de cada saco, cuatro décimas partes se
/// van al aire.
///
/// El motor ya lee el pH en cada lectura, así que puede avisarlo sin pedir
/// nada. La corrección práctica no es cambiar la dosis: es **incorporar,
/// regar después de aplicar, o cambiar de fuente**.
///
/// Solo aplica al nitrógeno y solo cuando la fuente es urea o similar.
String? ureaVolatilizationWarningEs({
  required AgroMetricKey nutrient,
  required SoilReaction reaction,
  double? ph,
}) {
  if (nutrient != AgroMetricKey.n) return null;
  if (reaction != SoilReaction.calcareous) return null;

  final String pct = (ph != null && ph >= 7.4) ? '44 %' : '40 %';
  return 'Cuidado con la urea en este suelo: aplicada en superficie y sin '
      'incorporar, en suelo calcáreo se pierde alrededor de $pct en diez días '
      'por evaporación de amoniaco. Incorpórala, riega justo después de '
      'aplicar, o usa una fuente que no se volatilice.';
}
