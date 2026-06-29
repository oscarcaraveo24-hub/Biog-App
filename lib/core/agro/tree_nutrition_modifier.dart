import 'package:bio_g/core/agro/agro_types.dart';

/// Contrato común de modificadores nutricionales por perfil/variedad de árbol
/// perenne (manzano, pera, …).
///
/// Permite que el motor AgroScore compartido ([TreeAgroScoreEngine]) y el motor
/// NPK trabajen con cualquier árbol sin hardcodear un cultivo: cada árbol
/// implementa este contrato y el motor lo recibe ya resuelto.
///
/// Reglas no negociables (estándar v1.5):
/// - El modificador NO cambia la etapa fenológica ni los targets base; solo
///   ajusta sensibilidad/presión y tono de mensaje.
/// - `lateNitrogenExcessPenaltyFactor` es un concepto de scoring/penalización,
///   NUNCA una identidad de etapa ni copy de cosecha.
abstract class TreeNutritionModifier {
  /// Ajusta la presión fenológica base por nutriente/etapa (≤/≥ según variedad).
  double adjustStagePressure(
    double base, {
    required AgroMetricKey nutrient,
    required String? stageKey,
  });

  /// Penalización EXTRA (multiplicador ≤ 1.0) cuando el N está en EXCESO real en
  /// etapas tardías (llenado/madurez). Fuera de esas etapas devuelve 1.0.
  double lateNitrogenExcessPenaltyFactor(String? stageKey);

  /// Matiz UX por variedad para la recomendación práctica de un nutriente.
  String practicalCaution(AgroMetricKey nutrient, String? stageKey);
}
