import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/tree_nutrition_modifier.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Grupo de perfil del pistache para matices nutricionales (doc 05 §13).
///
/// Espeja el patron de manzano/pera/durazno/nogal: NO cambia la estructura
/// fenologica ni los targets base; solo ajusta presion fenologica y mensajes
/// segun el perfil PS.
enum PistachioTreeNutritionGroup {
  generic,
  kermanPeters,
  goldenHillsRandy,
  lostHillsRandy,
  siroraCompatible,
  mediterraneanLowChill,
}

class PistachioTreeNutritionModifier implements TreeNutritionModifier {
  const PistachioTreeNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
  });

  final String profileId;
  final PistachioTreeNutritionGroup group;
  final String labelEs;
  final String summaryEs;

  bool get isGeneric => group == PistachioTreeNutritionGroup.generic;

  /// Cultivares modernos de ciclo adelantado (doc 05 §13.3, §13.4, §13.6):
  /// Golden Hills, Lost Hills y los mediterraneos bajo-frio. El N tardio
  /// penaliza mas porque el ciclo va mas adelantado.
  bool get isEarlyCycle =>
      group == PistachioTreeNutritionGroup.goldenHillsRandy ||
      group == PistachioTreeNutritionGroup.lostHillsRandy ||
      group == PistachioTreeNutritionGroup.mediterraneanLowChill;

  /// Kerman tradicional (doc 05 §13.2): alto frio, alternancia fuerte, mayor
  /// riesgo de cerrado/blanks.
  bool get isKermanTraditional =>
      group == PistachioTreeNutritionGroup.kermanPeters;

  /// Perfiles de calibre/kernel grande (doc 05 §13.3, §13.4): el llenado tira
  /// mas fuerte del K en fruit_fill.
  bool get isHighKernelDemand =>
      group == PistachioTreeNutritionGroup.goldenHillsRandy ||
      group == PistachioTreeNutritionGroup.lostHillsRandy;

  /// Delta de presion fenologica por nutriente/etapa (doc 05 §11, §13).
  ///
  /// - P: pesa mas en raiz/establecimiento/brotacion/floracion.
  /// - K: protagonista del kernel desde amarre (fruit_set, fruit_fill,
  ///   harvest_maturity); en pistache el K del llenado es central y se refuerza
  ///   en perfiles de kernel grande / Kerman en fruit_fill.
  /// - N: en llenado/madurez NO es prioridad de deficit (se relaja levemente);
  ///   el riesgo real ahi es el EXCESO (vigor/sombra/sales con baja carga).
  @override
  double adjustStagePressure(
    double base, {
    required AgroMetricKey nutrient,
    required String? stageKey,
  }) {
    return (base + _stagePressureDelta(nutrient, stageKey)).clamp(0.0, 1.0);
  }

  double _stagePressureDelta(AgroMetricKey nutrient, String? stageKey) {
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
    final isLateNitrogenRisk =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;

    switch (nutrient) {
      case AgroMetricKey.p:
        return isEarlyP ? 0.04 : 0.0;
      case AgroMetricKey.k:
        if (!isFruitK) return 0.0;
        if (isHighKernelDemand && stage == TreeStageIds.fruitFill) return 0.09;
        if (isKermanTraditional && stage == TreeStageIds.fruitFill) return 0.07;
        return 0.06;
      case AgroMetricKey.n:
        return isLateNitrogenRisk ? -0.03 : 0.0;
      default:
        return 0.0;
    }
  }

  /// Penalizacion EXTRA (multiplicador <= 1.0) por N en EXCESO real tardio
  /// (llenado/madurez). Mayor en perfiles de ciclo adelantado. Es un concepto
  /// de scoring, NO una identidad de etapa ni copy de cosecha (v1.5).
  @override
  double lateNitrogenExcessPenaltyFactor(String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isLateNitrogenRisk =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;
    if (!isLateNitrogenRisk) return 1.0;
    if (isEarlyCycle) return 0.86;
    if (isKermanTraditional) return 0.90;
    return 0.92;
  }

  /// Matiz UX por perfil para la recomendacion practica (doc 05 §13).
  @override
  String practicalCaution(AgroMetricKey nutrient, String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isFruitFill = stage == TreeStageIds.fruitFill;
    final isHarvest = stage == TreeStageIds.harvestMaturity;
    final isFlowering = stage == TreeStageIds.flowering;

    if (nutrient == AgroMetricKey.n) {
      if (isFruitFill) {
        return '$labelEs: en llenado el N solo ayuda si hay carga y raiz sana; con baja carga se va a puro follaje.';
      }
      if (isHarvest) {
        return '$labelEs: cerca de cosecha evita empujar N; ya no arregla un kernel mal llenado.';
      }
      return '$labelEs: ajusta N por carga, agua y salinidad; mas N no es mas pistache.';
    }
    if (nutrient == AgroMetricKey.k) {
      if (isFruitFill) {
        return '$labelEs: K es protagonista del kernel y la apertura futura; no lo subas si la EC esta alta.';
      }
      if (isHarvest) {
        return '$labelEs: K sostiene calidad final, pero la cosecha se decide por madurez, split y sanidad.';
      }
      return '$labelEs: maneja K en la zona mojada y con raiz activa.';
    }
    if (nutrient == AgroMetricKey.p) {
      if (isFlowering) {
        return '$labelEs: P acompana floracion, pero macho/hembra, frio y viento mandan el cuajado.';
      }
      return '$labelEs: P pesa mas en raiz y arranque; en suelo calizo revisa disponibilidad antes de corregir.';
    }
    return '$labelEs: interpreta NPK junto con agua, EC, pH, raiz, macho/hembra y carga.';
  }
}

/// Resuelve el modificador del pistache desde perfil/variedad/alias (doc 05
/// §16). Desconocido → perfil general (sin variedad, macho ni carga asumidos).
PistachioTreeNutritionModifier resolvePistachioTreeNutritionModifier({
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

  final canonical = _canonicalPistachioProfile(tokens);

  switch (canonical) {
    case kPs01KermanPeters:
      return const PistachioTreeNutritionModifier(
        profileId: kPs01KermanPeters,
        group: PistachioTreeNutritionGroup.kermanPeters,
        labelEs: 'Kerman/Peters',
        summaryEs:
            'Tradicional: alto frio, alternancia y K fuerte en llenado; cuidado '
            'con cerrado/blanks si falto frio o no coincidio Peters.',
      );
    case kPs02GoldenHillsRandy:
      return const PistachioTreeNutritionModifier(
        profileId: kPs02GoldenHillsRandy,
        group: PistachioTreeNutritionGroup.goldenHillsRandy,
        labelEs: 'Golden Hills/Randy',
        summaryEs:
            'Temprano moderno: adelanta ventanas de K/agua, alto potencial de '
            'split; corta N a tiempo porque el ciclo va adelantado.',
      );
    case kPs03LostHillsRandy:
      return const PistachioTreeNutritionModifier(
        profileId: kPs03LostHillsRandy,
        group: PistachioTreeNutritionGroup.lostHillsRandy,
        labelEs: 'Lost Hills/Randy',
        summaryEs:
            'Calibre/kernel grande: K, agua y calidad pesan fuerte; no subir K '
            'si la EC ya esta alta.',
      );
    case kPs04SiroraCompatible:
      return const PistachioTreeNutritionModifier(
        profileId: kPs04SiroraCompatible,
        group: PistachioTreeNutritionGroup.siroraCompatible,
        labelEs: 'Sirora compatible',
        summaryEs:
            'Intermedio/adaptable: usar confianza moderada; confirma variedad, '
            'macho y analisis antes de empujar fuerte.',
      );
    case kPs05LarnakaMateurLowChill:
      return const PistachioTreeNutritionModifier(
        profileId: kPs05LarnakaMateurLowChill,
        group: PistachioTreeNutritionGroup.mediterraneanLowChill,
        labelEs: 'Larnaka/Mateur bajo-frio relativo',
        summaryEs:
            'Temprano/bajo frio relativo: adelantar ventanas y cuidar heladas; '
            'bajo-frio NO es sin frio, no empujar N tarde.',
      );
    default:
      return const PistachioTreeNutritionModifier(
        profileId: kPsSkip,
        group: PistachioTreeNutritionGroup.generic,
        labelEs: 'Pistache general',
        summaryEs:
            'Perfil general: no asume variedad, macho ni carga. NPK orienta, '
            'pero no explica solo floracion/cuajado; agua y EC primero.',
      );
  }
}

String _canonicalPistachioProfile(List<String> tokens) {
  for (final token in tokens) {
    switch (token) {
      case kPs01KermanPeters:
      case kPs02GoldenHillsRandy:
      case kPs03LostHillsRandy:
      case kPs04SiroraCompatible:
      case kPs05LarnakaMateurLowChill:
      case kPsSkip:
        return token;
    }
    for (final entry in pistachioTreeProfileEntries) {
      if (entry.id == token) return entry.id;
      if (entry.aliases.any((a) => a.trim().toLowerCase() == token)) {
        return entry.id;
      }
    }
    // Heuristica por palabra clave (doc 05 §16): tolera texto libre del wizard.
    if (token.contains('kerman') || token.contains('peters')) {
      return kPs01KermanPeters;
    }
    if (token.contains('golden')) return kPs02GoldenHillsRandy;
    if (token.contains('lost')) return kPs03LostHillsRandy;
    if (token.contains('sirora')) return kPs04SiroraCompatible;
    if (token.contains('larnaka') ||
        token.contains('mateur') ||
        token.contains('low_chill') ||
        token.contains('mediterr')) {
      return kPs05LarnakaMateurLowChill;
    }
  }
  return kPsSkip;
}
