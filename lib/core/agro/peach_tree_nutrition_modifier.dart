import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/tree_nutrition_modifier.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Grupo de perfil del durazno para matices nutricionales (doc 05 §15-§16).
///
/// Espeja el patrón de manzano/pera: NO cambia la estructura fenológica ni los
/// targets base; solo ajusta presión fenológica y mensajes según el perfil DZ.
enum PeachTreeNutritionGroup {
  generic,
  criolloRegional,
  tempranoBajoFrio,
  amarilloComercial,
  blancoDulce,
  tardioIndustria,
}

class PeachTreeNutritionModifier implements TreeNutritionModifier {
  const PeachTreeNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
  });

  final String profileId;
  final PeachTreeNutritionGroup group;
  final String labelEs;
  final String summaryEs;

  bool get isGeneric => group == PeachTreeNutritionGroup.generic;

  /// Perfiles donde el N alto tardío castiga más por calidad (doc 05 §16):
  /// amarillo comercial (color/calibre) y blanco/dulce (sabor, firmeza,
  /// pudriciones). En durazno el N alto cerca de madurez baja color y firmeza.
  bool get isQualityStorageSensitive =>
      group == PeachTreeNutritionGroup.amarilloComercial ||
      group == PeachTreeNutritionGroup.blancoDulce;

  /// Delta de presión fenológica por nutriente/etapa (doc 05 §8, §15-§16).
  ///
  /// - P: pesa más en raíz/establecimiento/brotación/floración.
  /// - K: sube tras cuajado (fruit_set, fruit_fill, harvest_maturity); en
  ///   durazno el K del fruto es protagonista, un poco más que en pepita.
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
        // Durazno tiene alta sensibilidad a deficiencia de K en fruto.
        return isFruitK ? 0.07 : 0.0;
      case AgroMetricKey.n:
        return isLateNitrogenRisk ? -0.03 : 0.0;
      default:
        return 0.0;
    }
  }

  /// Penalización EXTRA (multiplicador ≤ 1.0) por N en EXCESO real tardío
  /// (llenado/madurez). Mayor en perfiles de calidad. Es un concepto de
  /// scoring, NO una identidad de etapa ni copy de cosecha (v1.5).
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
      case PeachTreeNutritionGroup.generic:
        if (isFruitFill) {
          return 'Durazno general: en llenado manda el fruto; evita follaje de más.';
        }
        if (isHarvestMaturity) {
          return 'Durazno general: cerca de cosecha cuida color y firmeza.';
        }
        return 'Durazno general: ajusta N sin empujar brotes tiernos de más.';
      case PeachTreeNutritionGroup.criolloRegional:
        if (isFruitFill) {
          return 'Criollo/regional: en llenado cuida riego parejo, K y calibre.';
        }
        if (isHarvestMaturity) {
          return 'Criollo/regional: no fuerces N tarde; cuida firmeza y sanidad.';
        }
        return 'Criollo/regional: responde mejor a manejo parejo que a jalones de N.';
      case PeachTreeNutritionGroup.tempranoBajoFrio:
        if (isFruitFill) {
          return 'Temprano/bajo frío: en llenado sostén K y riego sin empujar brotes.';
        }
        if (isHarvestMaturity) {
          return 'Temprano/bajo frío: ventana corta; evita N tarde y cuida firmeza.';
        }
        return 'Temprano/bajo frío: no uses N para forzar floración.';
      case PeachTreeNutritionGroup.amarilloComercial:
        if (isFruitFill) {
          return 'Amarillo comercial: K y riego sostienen calibre; N alto resta color.';
        }
        if (isHarvestMaturity) {
          return 'Amarillo comercial: N alto baja color, retrasa madurez y resta firmeza.';
        }
        return 'Amarillo comercial: calidad visual primero, follaje después.';
      case PeachTreeNutritionGroup.blancoDulce:
        if (isFruitFill) {
          return 'Blanco/dulce: protege firmeza y sabor; evita exceso de N.';
        }
        if (isHarvestMaturity) {
          return 'Blanco/dulce: N alto castiga dulzor, firmeza y vida de anaquel.';
        }
        return 'Blanco/dulce: calidad primero, vigor después.';
      case PeachTreeNutritionGroup.tardioIndustria:
        if (isFruitFill) {
          return 'Tardío/industria: llenado largo; sostén K y riego sin subir sales.';
        }
        if (isHarvestMaturity) {
          return 'Tardío/industria: cuida firmeza y sanidad; no metas N tarde.';
        }
        return 'Tardío/industria: ciclo largo; K y riego parejo pesan más que N tarde.';
    }
  }

  String _potassiumCaution({
    required bool isFruitFill,
    required bool isHarvestMaturity,
  }) {
    if (isFruitFill || isHarvestMaturity) {
      return '$labelEs: K sostiene tamaño, firmeza y dulzor; no lo subas si hay sales altas.';
    }
    return '$labelEs: maneja K con riego parejo y sin excederte.';
  }

  String _phosphorusCaution() {
    if (group == PeachTreeNutritionGroup.generic) {
      return 'Durazno general: P ayuda más al arranque, raíz y floración.';
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
      return '$labelEs en madurez/cosecha: cuida color, firmeza y corte.';
    }
    return '$labelEs: ajusta según etapa y lectura BioG.';
  }
}

/// Resuelve el modificador del durazno desde perfil/variedad/alias (doc 01).
/// Desconocido → perfil general (sin alto rendimiento ni calidad asumidos).
PeachTreeNutritionModifier resolvePeachTreeNutritionModifier({
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

  final canonical = _canonicalPeachProfile(tokens);

  switch (canonical) {
    case kDz01CriolloRegional:
      return const PeachTreeNutritionModifier(
        profileId: kDz01CriolloRegional,
        group: PeachTreeNutritionGroup.criolloRegional,
        labelEs: 'Criollo / regional',
        summaryEs: 'Huertos tradicionales: riego parejo, K y sanidad antes que más N.',
      );
    case kDz02TempranoBajoFrio:
      return const PeachTreeNutritionModifier(
        profileId: kDz02TempranoBajoFrio,
        group: PeachTreeNutritionGroup.tempranoBajoFrio,
        labelEs: 'Temprano / bajo frío',
        summaryEs: 'Ciclo adelantado; cosecha concentrada y N temprano.',
      );
    case kDz03AmarilloComercial:
      return const PeachTreeNutritionModifier(
        profileId: kDz03AmarilloComercial,
        group: PeachTreeNutritionGroup.amarilloComercial,
        labelEs: 'Amarillo comercial',
        summaryEs: 'Fresco comercial; K y riego sostienen calibre, N alto resta color.',
      );
    case kDz04BlancoDulce:
      return const PeachTreeNutritionModifier(
        profileId: kDz04BlancoDulce,
        group: PeachTreeNutritionGroup.blancoDulce,
        labelEs: 'Blanco / dulce',
        summaryEs: 'Premium/nicho; calidad y firmeza pesan más que vigor.',
      );
    case kDz05TardioIndustria:
      return const PeachTreeNutritionModifier(
        profileId: kDz05TardioIndustria,
        group: PeachTreeNutritionGroup.tardioIndustria,
        labelEs: 'Tardío / industria',
        summaryEs: 'Ciclo largo; K y riego sostenidos, cuidado con N tardío.',
      );
    default:
      return const PeachTreeNutritionModifier(
        profileId: kDzSkip,
        group: PeachTreeNutritionGroup.generic,
        labelEs: 'Durazno general',
        summaryEs: 'Perfil general; manejo claro y sin exceso de N.',
      );
  }
}

String _canonicalPeachProfile(List<String> tokens) {
  for (final token in tokens) {
    switch (token) {
      case kDz01CriolloRegional:
      case kDz02TempranoBajoFrio:
      case kDz03AmarilloComercial:
      case kDz04BlancoDulce:
      case kDz05TardioIndustria:
      case kDzSkip:
        return token;
    }
    for (final entry in peachTreeProfileEntries) {
      if (entry.id == token) return entry.id;
      if (entry.aliases.any((a) => a.trim().toLowerCase() == token)) {
        return entry.id;
      }
    }
  }
  return kDzSkip;
}
