/// =========================================================================
/// REACCIÓN DEL SUELO (pH) COMO CONTEXTO NUTRICIONAL
/// =========================================================================
///
/// QUÉ ES ESTO HOY
/// ---------------
/// El pH ya viene en cada lectura del sensor y de él se deduce, sin preguntarle
/// nada al productor, si el suelo se comporta como ácido, neutro o calcáreo.
/// Esa reacción es **contexto físico** para el motor de nutrición
/// (`NutritionReadinessEngine`), en dos frentes con respaldo publicado:
///
///   · Fósforo: en suelo calcáreo el calcio fija el fósforo y baja su
///     disponibilidad real. UF/IFAS publica dos calibraciones Mehlich-3 del
///     mismo cultivo —mineral ácido: bajo ≤25 · medio 26–45 · alto >45 ppm;
///     calcáreo: bajo ≤76 · medio 77–104 · alto >104 ppm— y la diferencia
///     (~1.75×) es el tamaño del efecto. Chihuahua y buena parte del norte de
///     México son calcáreos.
///   · Urea: aplicada en superficie sin incorporar, en suelo calcáreo pierde
///     alrededor de 40 % (pH 7.0) a 44 % (pH 7.5) en diez días por
///     volatilización de amoniaco.
///
/// QUÉ DEJÓ DE SER
/// ---------------
/// Hasta el NPK Interpretation Reset (Guía oficial del nuevo motor nutricional
/// v0.4, §4) este módulo también **desplazaba la banda objetivo de fósforo**
/// (`adjustRangeForSoilReaction`, factor 1.75) para comparar la lectura cruda
/// de la sonda contra un target corregido. Ese camino se eliminó del runtime
/// junto con los targets: la sonda 7-en-1 deriva N/P/K de la conductividad y
/// no hay banda que corregir. Lo que sobrevive es lo que sí puede afirmarse
/// desde el pH: la disponibilidad del fósforo es menor en calcáreo (fuente y
/// colocación importan más) y la urea al voleo se pierde. Eso alimenta las
/// reglas 3R —fuente, dosis, momento, lugar— de la guía, no una cifra de ppm.
///
/// NO SE TOCAN NITRÓGENO NI POTASIO
/// --------------------------------
/// El efecto de los carbonatos sobre el fósforo está publicado y cuantificado.
/// Para N y K no existe una calibración calcárea equivalente, así que afirmar
/// algo sería inventar. Solo se conserva el aviso de volatilización de urea,
/// que es un hecho de la fuente, no del suelo.
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
/// El corte se puso en 7.3 y no en 7.0 a propósito: se prefiere **no afirmar
/// de más**. Un suelo neutro clasificado como calcáreo recibiría avisos de
/// fósforo y urea que no le corresponden.
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

/// Nota de disponibilidad de fósforo en suelo calcáreo.
///
/// Devuelve `null` cuando no aplica: no se le cuenta al agricultor algo que no
/// pasó. No menciona metas ni ppm —ya no existen en el runtime—: habla de
/// fuente y colocación, que es lo que el productor sí puede decidir.
String? soilReactionNoteEs({
  required AgroMetricKey nutrient,
  required SoilReaction reaction,
  double? ph,
}) {
  if (nutrient != AgroMetricKey.p) return null;
  if (reaction != SoilReaction.calcareous) return null;

  final String phText = ph == null ? '' : ' (pH ${ph.toStringAsFixed(1)})';
  return 'Tu suelo se leyó calcáreo$phText. En suelo calcáreo el calcio fija '
      'el fósforo y la planta dispone de menos de lo que hay: conviene colocar '
      'el fósforo en banda o cerca de la raíz, no al voleo, y no esperar '
      'respuesta rápida de una aplicación superficial.';
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
