import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/tree_nutrition_modifier.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Grupo de perfil de la pera para matices nutricionales (doc 05 §16).
///
/// Espeja el patrón del manzano: NO cambia la estructura fenológica ni los
/// targets base; solo ajusta presión fenológica y mensajes según el perfil PR.
enum PearTreeNutritionGroup {
  generic,
  bartlettWilliams,
  anjou,
  bosc,
  seckelComice,
  kiefferRustic,
}

class PearTreeNutritionModifier implements TreeNutritionModifier {
  const PearTreeNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
  });

  final String profileId;
  final PearTreeNutritionGroup group;
  final String labelEs;
  final String summaryEs;

  bool get isGeneric => group == PearTreeNutritionGroup.generic;

  /// Perfiles donde el N alto tardío castiga más por calidad/almacenamiento
  /// (doc 05 §16): Anjou, Bosc y Seckel/Comice (mercado de conservación/premium;
  /// OSU reporta que el exceso de N baja color, sólidos solubles y sabor en
  /// Anjou).
  bool get isQualityStorageSensitive =>
      group == PearTreeNutritionGroup.anjou ||
      group == PearTreeNutritionGroup.bosc ||
      group == PearTreeNutritionGroup.seckelComice;

  /// Delta de presión fenológica por nutriente/etapa (doc 05 §8, §16).
  ///
  /// - P: pesa más en raíz/brotación/floración.
  /// - K: sube tras cuajado (fruit_set, fruit_fill, harvest_maturity).
  /// - N: en llenado/madurez NO es prioridad de déficit (se relaja levemente);
  ///   el riesgo real ahí es el EXCESO, penalizado por el motor del árbol.
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
        // K pesa fuerte en pera; un poco más que en manzano en cuajado/llenado.
        return isFruitK ? 0.06 : 0.0;
      case AgroMetricKey.n:
        return isLateNitrogenRisk ? -0.03 : 0.0;
      default:
        return 0.0;
    }
  }

  /// Penalización EXTRA (multiplicador ≤ 1.0) por N en EXCESO real tardío
  /// (llenado/madurez). Mayor en perfiles de calidad/almacenamiento. Es un
  /// concepto de scoring, NO una identidad de etapa ni copy de cosecha (v1.5).
  @override
  double lateNitrogenExcessPenaltyFactor(String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isLateNitrogenRisk =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;
    if (!isLateNitrogenRisk) return 1.0;
    return isQualityStorageSensitive ? 0.82 : 0.92;
  }

  /// Matiz UX por perfil para la recomendación práctica (doc 05 §16).
  @override
  String practicalCaution(AgroMetricKey nutrient, String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isFruitFill = stage == TreeStageIds.fruitFill;
    final isHarvestMaturity = stage == TreeStageIds.harvestMaturity;

    if (nutrient == AgroMetricKey.n) {
      return _nitrogenCaution(
        isFruitFill: isFruitFill,
        isHarvestMaturity: isHarvestMaturity,
      );
    }
    if (nutrient == AgroMetricKey.k) {
      return _potassiumCaution(
        isFruitFill: isFruitFill,
        isHarvestMaturity: isHarvestMaturity,
      );
    }
    if (nutrient == AgroMetricKey.p) {
      return _phosphorusCaution();
    }
    return _generalCaution(
      isFruitFill: isFruitFill,
      isHarvestMaturity: isHarvestMaturity,
    );
  }

  String _nitrogenCaution({
    required bool isFruitFill,
    required bool isHarvestMaturity,
  }) {
    switch (group) {
      case PearTreeNutritionGroup.generic:
        if (isFruitFill) {
          return 'Pera general: en llenado manda el fruto; evita follaje de más.';
        }
        if (isHarvestMaturity) {
          return 'Pera general: cerca de cosecha cuida firmeza y conservación.';
        }
        return 'Pera general: ajusta N sin empujar brotes tiernos de más.';
      case PearTreeNutritionGroup.bartlettWilliams:
        if (isFruitFill) {
          return 'Bartlett/Williams: en llenado cuida calibre y firmeza.';
        }
        if (isHarvestMaturity) {
          return 'Bartlett/Williams: N tarde ablanda fruta y mueve la ventana de corte.';
        }
        return 'Bartlett/Williams: no empujes N si BioG ya lo marca alto.';
      case PearTreeNutritionGroup.anjou:
        if (isHarvestMaturity) {
          return "D'Anjou: N alto tarde baja sabor, firmeza y vida en almacén.";
        }
        if (isFruitFill) {
          return "D'Anjou: en llenado cuida calibre y firmeza para conservación.";
        }
        return "D'Anjou: N controlado para conservar calidad.";
      case PearTreeNutritionGroup.bosc:
        if (isHarvestMaturity) {
          return 'Bosc: evita N tarde; cuida firmeza para conservación.';
        }
        if (isFruitFill) {
          return 'Bosc: en llenado cuida calibre y evita brotes tiernos.';
        }
        return 'Bosc: calidad firme; evita N de más.';
      case PearTreeNutritionGroup.seckelComice:
        if (isHarvestMaturity) {
          return 'Seckel/Comice: N alto castiga sabor y conservación.';
        }
        if (isFruitFill) {
          return 'Seckel/Comice: protege uniformidad, calibre y firmeza.';
        }
        return 'Seckel/Comice: calidad primero, vigor después.';
      case PearTreeNutritionGroup.kiefferRustic:
        if (isFruitFill) {
          return 'Kieffer/rústica: en llenado cuida riego parejo y K.';
        }
        if (isHarvestMaturity) {
          return 'Kieffer/rústica: para proceso también importan tamaño y firmeza.';
        }
        return 'Kieffer/rústica: no sobreactúes con desviaciones pequeñas.';
    }
  }

  String _potassiumCaution({
    required bool isFruitFill,
    required bool isHarvestMaturity,
  }) {
    if (isFruitFill || isHarvestMaturity) {
      return '$labelEs: K sostiene calibre y firmeza; no lo subas si hay sales altas.';
    }
    return '$labelEs: maneja K con riego parejo y sin excederte.';
  }

  String _phosphorusCaution() {
    if (group == PearTreeNutritionGroup.generic) {
      return 'Pera general: P ayuda más al arranque, raíz y floración.';
    }
    return '$labelEs: corrige P solo si la lectura se sostiene baja.';
  }

  String _generalCaution({
    required bool isFruitFill,
    required bool isHarvestMaturity,
  }) {
    if (isFruitFill) {
      return '$labelEs en llenado: prioriza fruto, K y riego parejo.';
    }
    if (isHarvestMaturity) {
      return '$labelEs en madurez/cosecha: cuida firmeza y conservación.';
    }
    return '$labelEs: ajusta según etapa y lectura BioG.';
  }
}

/// Resuelve el modificador de la pera desde perfil/variedad/alias (doc 01).
/// Desconocido → perfil general (sin alto rendimiento ni calidad asumidos).
PearTreeNutritionModifier resolvePearTreeNutritionModifier({
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

  final canonical = _canonicalPearProfile(tokens);

  switch (canonical) {
    case kPr01BartlettWilliams:
      return const PearTreeNutritionModifier(
        profileId: kPr01BartlettWilliams,
        group: PearTreeNutritionGroup.bartlettWilliams,
        labelEs: 'Bartlett / Williams',
        summaryEs:
            'Pera europea clásica; tamaño y firmeza sufren con N tardío.',
      );
    case kPr02Anjou:
      return const PearTreeNutritionModifier(
        profileId: kPr02Anjou,
        group: PearTreeNutritionGroup.anjou,
        labelEs: "Anjou / D'Anjou",
        summaryEs: 'Conservación/almacenaje; calidad sufre con N alto.',
      );
    case kPr03Bosc:
      return const PearTreeNutritionModifier(
        profileId: kPr03Bosc,
        group: PearTreeNutritionGroup.bosc,
        labelEs: 'Bosc',
        summaryEs: 'Piel russet; vigilar Mg y calidad de almacenamiento.',
      );
    case kPr04SeckelComice:
      return const PearTreeNutritionModifier(
        profileId: kPr04SeckelComice,
        group: PearTreeNutritionGroup.seckelComice,
        labelEs: 'Seckel / Comice',
        summaryEs: 'Premium/nicho; calidad primero, vigor después.',
      );
    case kPr05KiefferRustic:
      return const PearTreeNutritionModifier(
        profileId: kPr05KiefferRustic,
        group: PearTreeNutritionGroup.kiefferRustic,
        labelEs: 'Kieffer / rústicas',
        summaryEs: 'Rústica/proceso; manejo claro, sin sobreactuar.',
      );
    default:
      return const PearTreeNutritionModifier(
        profileId: kPrSkip,
        group: PearTreeNutritionGroup.generic,
        labelEs: 'Pera general',
        summaryEs: 'Pera general; manejo claro y sin exceso de N.',
      );
  }
}

String _canonicalPearProfile(List<String> tokens) {
  for (final token in tokens) {
    switch (token) {
      case kPr01BartlettWilliams:
      case kPr02Anjou:
      case kPr03Bosc:
      case kPr04SeckelComice:
      case kPr05KiefferRustic:
      case kPrSkip:
        return token;
    }
    for (final entry in pearTreeProfileEntries) {
      if (entry.id == token) return entry.id;
      if (entry.aliases.any((a) => a.trim().toLowerCase() == token)) {
        return entry.id;
      }
    }
  }
  return kPrSkip;
}
