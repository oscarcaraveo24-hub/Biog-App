// lib/core/agro/soil_condition_score.dart
//
// Puntaje de CONDICIÓN FÍSICA DEL SUELO compartido por los 26 motores de score.
//
// Es la pieza que hace real el §6 de la Guía oficial del nuevo motor
// nutricional v0.4 («Cómo queda el AgroScore»):
//
//   · N/P/K crudos NO pesan. Ni poco: cero. Una señal derivada de la
//     conductividad no puede castigar ni premiar el estado del suelo como si
//     fuera un análisis químico.
//   · Una señal AUSENTE no vale 0 ni 0.5: sale del denominador. Antes, un cable
//     flojo en el bus del pH tiraba el anillo del Panel de 98 % a 38 % y
//     publicaba «pH fuera de rango» sobre un dato que no existía.
//   · La cobertura viaja aparte, como número propio: «89 % · 4 de 5 señales».
//
// Lo que NO hace este módulo: no decide las penalizaciones críticas de cada
// cultivo. Esas son agronomía propia de cada motor (al maguey lo mata el exceso
// de agua; a la lechuga, el calor) y cada motor sigue componiendo su propio
// factor. Aquí se recibe ya multiplicado, y se aplica una sola vez.
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';

/// Resultado del cálculo compartido.
class SoilConditionScoreResult {
  const SoilConditionScoreResult({
    required this.score01,
    required this.rawScore01,
    required this.criticalPenalty,
    required this.coverage,
  });

  /// Puntaje final 0..1 (promedio ponderado × penalización crítica).
  final double score01;

  /// Promedio ponderado ANTES de la penalización crítica.
  final double rawScore01;

  /// Factor multiplicativo ≤ 1.0 que aportó el motor del cultivo.
  final double criticalPenalty;

  /// Con cuánta evidencia se calculó el puntaje.
  final SoilSignalCoverage coverage;
}

class SoilConditionScore {
  const SoilConditionScore._();

  /// Las cinco señales físicas que un motor de score sabe evaluar.
  ///
  /// El orden es el de las pestañas del Historial y no se altera: algunos
  /// consumidores lo usan para enumerar qué falta.
  static const List<AgroMetricKey> physicalSignals = <AgroMetricKey>[
    AgroMetricKey.soilMoisture,
    AgroMetricKey.soilTemp,
    AgroMetricKey.ph,
    AgroMetricKey.ec,
    AgroMetricKey.resistance,
  ];

  /// Promedio ponderado de las señales físicas PRESENTES.
  ///
  /// [metrics] puede traer también N/P/K: se ignoran aunque tengan valor. Una
  /// métrica física cuenta como presente cuando su banda es distinta de
  /// `unknown`, que es exactamente lo que los evaluadores de cada motor
  /// devuelven ante un valor no finito (NaN = «no llegó»).
  ///
  /// [criticalPenalty] es el factor ya compuesto por el motor del cultivo con
  /// sus propias reglas (humedad crítica × pH crítico × …). Se aplica una vez.
  ///
  /// Sin ninguna señal presente el puntaje es 0.0 y la cobertura lo declara:
  /// quien pinte ese número debe consultar `coverage.hasAnySignal` primero.
  static SoilConditionScoreResult compute({
    required Map<AgroMetricKey, AgroMetricEval> metrics,
    required StageWeights weights,
    double criticalPenalty = 1.0,
  }) {
    double weightedSum = 0.0;
    double weightSum = 0.0;
    int present = 0;
    final List<AgroMetricKey> missing = <AgroMetricKey>[];

    for (final AgroMetricKey key in physicalSignals) {
      final AgroMetricEval? eval = metrics[key];
      if (eval == null || !eval.band.isKnown) {
        missing.add(key);
        continue;
      }
      final double w = weights.weightFor(key);
      if (w <= 0) {
        // Peso cero declarado por el cultivo: la señal existe y se muestra,
        // pero el perfil decidió que no mueve el puntaje. Cuenta como presente
        // para la cobertura porque SÍ hay evidencia.
        present++;
        continue;
      }
      weightedSum += w * eval.score01.clamp(0.0, 1.0);
      weightSum += w;
      present++;
    }

    final SoilSignalCoverage coverage = SoilSignalCoverage(
      evaluable: physicalSignals.length,
      present: present,
      missing: List<AgroMetricKey>.unmodifiable(missing),
    );

    if (weightSum <= 0) {
      return SoilConditionScoreResult(
        score01: 0.0,
        rawScore01: 0.0,
        criticalPenalty: criticalPenalty.clamp(0.0, 1.0),
        coverage: coverage,
      );
    }

    final double raw = (weightedSum / weightSum).clamp(0.0, 1.0);
    final double penalty = criticalPenalty.clamp(0.0, 1.0);

    return SoilConditionScoreResult(
      score01: (raw * penalty).clamp(0.0, 1.0),
      rawScore01: raw,
      criticalPenalty: penalty,
      coverage: coverage,
    );
  }
}
