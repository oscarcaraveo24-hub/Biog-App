import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Grupo de perfil del manzano para matices nutricionales (doc 05 §3, §11).
///
/// Espeja el patrón de `eggplant_nutrition_modifier` / `chili_nutrition_modifier`:
/// NO cambia la estructura fenológica ni los targets base; sólo ajusta presión
/// fenológica y mensajes según la variedad/perfil AP.
enum AppleTreeNutritionGroup { generic, golden, red, criollaRayada, gala, lowChill }

class AppleTreeNutritionModifier {
  const AppleTreeNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
  });

  final String profileId;
  final AppleTreeNutritionGroup group;
  final String labelEs;
  final String summaryEs;

  bool get isGeneric => group == AppleTreeNutritionGroup.generic;

  /// Variedades donde el color/calidad de fruto castiga más el N tardío
  /// (doc 05 §3.4: "N alto en AP-02 Red y AP-04 Gala cerca de madurez debe
  /// penalizar más por color/calidad").
  bool get isColorQualitySensitive =>
      group == AppleTreeNutritionGroup.red ||
      group == AppleTreeNutritionGroup.gala;

  /// Delta de presión fenológica por nutriente/etapa (doc 05 §8, §11).
  ///
  /// - P: pesa más en raíz/brotación/floración (planting, root, budbreak,
  ///   flowering).
  /// - K: sube tras cuajado (fruit_set, fruit_fill, harvest_maturity).
  /// - N: en llenado/madurez NO es prioridad de déficit (se relaja levemente);
  ///   el riesgo real ahí es el EXCESO, que se penaliza en el motor del árbol.
  double stagePressureDelta(AgroMetricKey nutrient, String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isEarlyP =
        stage == TreeStageIds.plantingTransplant ||
        stage == TreeStageIds.rootEstablishment ||
        stage == TreeStageIds.budbreak ||
        stage == TreeStageIds.flowering;
    final isFruitK =
        stage == TreeStageIds.fruitSet ||
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;
    final isLateN =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;

    switch (nutrient) {
      case AgroMetricKey.p:
        return isEarlyP ? 0.04 : 0.0;
      case AgroMetricKey.k:
        return isFruitK ? 0.05 : 0.0;
      case AgroMetricKey.n:
        return isLateN ? -0.03 : 0.0;
      default:
        return 0.0;
    }
  }

  double adjustStagePressure(
    double base, {
    required AgroMetricKey nutrient,
    required String? stageKey,
  }) {
    return (base + stagePressureDelta(nutrient, stageKey)).clamp(0.0, 1.0);
  }

  /// Penalización EXTRA (multiplicador ≤ 1.0) que el motor del árbol aplica
  /// cuando el N está en EXCESO real en etapas tardías (llenado/madurez).
  ///
  /// Doc 05 §3.4 + §11.2: el N alto tardío retrasa madurez, baja color rojo y
  /// firmeza; en AP-02 Red y AP-04 Gala la calidad por color castiga más.
  /// Fuera de llenado/madurez devuelve 1.0 (sin penalización adicional).
  double lateNitrogenExcessPenaltyFactor(String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isLate =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;
    if (!isLate) return 1.0;
    return isColorQualitySensitive ? 0.82 : 0.92;
  }

  /// Matiz UX por variedad para la recomendación práctica (doc 05 §13).
  String practicalCaution(AgroMetricKey nutrient, String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isLate =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;

    switch (group) {
      case AppleTreeNutritionGroup.generic:
        return 'Perfil general del manzano: lectura conservadora; precisa la '
            'variedad para afinar color, calidad y manejo tardío de N.';
      case AppleTreeNutritionGroup.golden:
        return 'Golden: cuida calibre y acabado; evita N tardío alto que '
            'retrase madurez.';
      case AppleTreeNutritionGroup.red:
        return isLate
            ? 'Red: cerca de madurez el N alto apaga el color rojo y la '
                  'firmeza. Frena el N y cuida K vs Ca/Mg.'
            : 'Red: prioriza color y firmeza; evita empujar N hacia llenado.';
      case AppleTreeNutritionGroup.gala:
        return isLate
            ? 'Gala: el color y la calidad sufren con N tardío. Mantén N bajo '
                  'y vigila K vs Ca/Mg para evitar bitter pit.'
            : 'Gala: calidad sensible; N controlado y balance K-Ca-Mg.';
      case AppleTreeNutritionGroup.criollaRayada:
        return 'Criolla/rayada (regional): manejo rústico; prioriza suelo, '
            'agua y balance antes que empujar fertilización.';
      case AppleTreeNutritionGroup.lowChill:
        return 'Bajo requerimiento de frío: ciclo adelantado; ajusta ventanas '
            'de N temprano y K en fruto a su calendario local.';
    }
  }
}

/// Resuelve el modificador del manzano desde perfil/variedad/alias (doc 01).
/// Desconocido → perfil general (sin alto rendimiento ni color asumidos).
AppleTreeNutritionModifier resolveAppleTreeNutritionModifier({
  String? profileId,
  String? varietyId,
  String? alias,
  String? calendarId,
}) {
  final tokens = <String?>[profileId, varietyId, alias, calendarId]
      .whereType<String>()
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  final canonical = _canonicalAppleProfile(tokens);

  switch (canonical) {
    case kAp01Golden:
      return const AppleTreeNutritionModifier(
        profileId: kAp01Golden,
        group: AppleTreeNutritionGroup.golden,
        labelEs: 'AP-01 Golden',
        summaryEs: 'Manzana Golden / amarilla.',
      );
    case kAp02Red:
      return const AppleTreeNutritionModifier(
        profileId: kAp02Red,
        group: AppleTreeNutritionGroup.red,
        labelEs: 'AP-02 Red',
        summaryEs: 'Roja; color y firmeza sensibles a N tardío.',
      );
    case kAp03CriollaRayada:
      return const AppleTreeNutritionModifier(
        profileId: kAp03CriollaRayada,
        group: AppleTreeNutritionGroup.criollaRayada,
        labelEs: 'AP-03 Criolla / Rayada',
        summaryEs: 'Criolla o rayada regional, manejo rústico.',
      );
    case kAp04Gala:
      return const AppleTreeNutritionModifier(
        profileId: kAp04Gala,
        group: AppleTreeNutritionGroup.gala,
        labelEs: 'AP-04 Gala',
        summaryEs: 'Gala; calidad/color sensibles a N tardío.',
      );
    case kAp05LowChill:
      return const AppleTreeNutritionModifier(
        profileId: kAp05LowChill,
        group: AppleTreeNutritionGroup.lowChill,
        labelEs: 'AP-05 Bajo requerimiento de frío',
        summaryEs: 'Variedades low-chill; ciclo adelantado.',
      );
    default:
      return const AppleTreeNutritionModifier(
        profileId: kApSkip,
        group: AppleTreeNutritionGroup.generic,
        labelEs: 'AP-SKIP Manzano general',
        summaryEs: 'Perfil general, migrable y conservador.',
      );
  }
}

String _canonicalAppleProfile(List<String> tokens) {
  for (final token in tokens) {
    // Coincidencia directa por id de perfil.
    switch (token) {
      case kAp01Golden:
      case kAp02Red:
      case kAp03CriollaRayada:
      case kAp04Gala:
      case kAp05LowChill:
      case kApSkip:
        return token;
    }
    // Coincidencia por alias del catálogo (igualdad exacta, como el wizard).
    for (final entry in appleTreeProfileEntries) {
      if (entry.id == token) return entry.id;
      if (entry.aliases.any((a) => a.trim().toLowerCase() == token)) {
        return entry.id;
      }
    }
  }
  return kApSkip;
}
