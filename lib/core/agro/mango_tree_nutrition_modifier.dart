import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/tree_nutrition_modifier.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Grupo de perfil del mango para matices nutricionales (doc 05 §8).
///
/// Espeja el patron de los demas arboles: NO cambia la estructura fenologica ni
/// los targets base; solo ajusta presion fenologica y mensajes segun el perfil
/// MG. El mango NO es limón, NO es naranjo y NO es manzano: N y K tienen lógica
/// OPUESTA por etapa (N pesa en juvenil/brote/postcosecha; en reposo/inducción y
/// llenado/madurez el N alto es riesgo) y K manda en cuajado/llenado/calidad.
enum MangoTreeNutritionGroup {
  generic,
  ataulfoManilaEarly,
  tommyAtkinsVolume,
  kentLateQuality,
  keittVeryLate,
  criolloRegional,
}

class MangoTreeNutritionModifier implements TreeNutritionModifier {
  const MangoTreeNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
  });

  final String profileId;
  final MangoTreeNutritionGroup group;
  final String labelEs;
  final String summaryEs;

  bool get isGeneric => group == MangoTreeNutritionGroup.generic;

  /// Perfiles donde el N tardío y la calidad de fruto pesan más (doc 05 §8):
  /// Ataulfo/Manila (calibre/mancha/madurez premium), Kent y Keitt (llenado
  /// largo, calidad interna/exportación). En variedades con cambio de color el N
  /// tardío castiga color/firmeza/poscosecha (doc 05 §0.0.2 pt10).
  bool get isFruitQualitySensitive =>
      group == MangoTreeNutritionGroup.ataulfoManilaEarly ||
      group == MangoTreeNutritionGroup.kentLateQuality ||
      group == MangoTreeNutritionGroup.keittVeryLate;

  /// Delta de presion fenologica por nutriente/etapa (doc 05 §8).
  ///
  /// - P: +0.04 en raíz/establecimiento/floración.
  /// - K: +0.06 en floración/cuajado/llenado/madurez (flowering, fruit_set,
  ///   fruit_fill, harvest_maturity): el K manda amarre, calibre y calidad; se
  ///   aplica a todos los perfiles.
  /// - N: -0.05 en reposo/inducción y llenado/madurez (dormancy, fruit_fill,
  ///   harvest_maturity): ahí el riesgo real es el EXCESO (vegetativo/no flor,
  ///   brote en llenado, calidad/poscosecha en madurez).
  @override
  double adjustStagePressure(
    double base, {
    required AgroMetricKey nutrient,
    required String? stageKey,
  }) {
    final stage = normalizeTreeStageId(stageKey);
    final isRootOrFlower =
        stage == TreeStageIds.plantingTransplant ||
        stage == TreeStageIds.rootEstablishment ||
        stage == TreeStageIds.flowering;
    final isFruitK =
        stage == TreeStageIds.flowering ||
        stage == TreeStageIds.fruitSet ||
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;
    final isLateN =
        stage == TreeStageIds.dormancy ||
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;

    switch (nutrient) {
      case AgroMetricKey.p:
        return (base + (isRootOrFlower ? 0.04 : 0.0)).clamp(0.0, 1.0);
      case AgroMetricKey.k:
        return (base + (isFruitK ? 0.06 : 0.0)).clamp(0.0, 1.0);
      case AgroMetricKey.n:
        return (base + (isLateN ? -0.05 : 0.0)).clamp(0.0, 1.0);
      default:
        return base;
    }
  }

  /// Penalizacion EXTRA (multiplicador <= 1.0) por N en EXCESO real tardio
  /// (llenado/madurez). Mayor en perfiles de calidad/exportación y variedades de
  /// cambio de color (doc 05 §0.0.2 pt10, §8, §10). Es un concepto de scoring, NO
  /// una identidad de etapa ni copy de cosecha (v1.5).
  @override
  double lateNitrogenExcessPenaltyFactor(String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isLate =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;
    if (!isLate) return 1.0;
    return switch (group) {
      MangoTreeNutritionGroup.kentLateQuality => 0.80,
      MangoTreeNutritionGroup.keittVeryLate => 0.80,
      MangoTreeNutritionGroup.ataulfoManilaEarly => 0.82,
      MangoTreeNutritionGroup.tommyAtkinsVolume => 0.86,
      MangoTreeNutritionGroup.criolloRegional => 0.88,
      MangoTreeNutritionGroup.generic => 0.90,
    };
  }

  /// Matiz UX por perfil para la recomendacion practica (doc 05 §8).
  @override
  String practicalCaution(AgroMetricKey nutrient, String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isDormancy = stage == TreeStageIds.dormancy;
    final isFruitFill = stage == TreeStageIds.fruitFill;
    final isHarvest = stage == TreeStageIds.harvestMaturity;
    final isFlowering = stage == TreeStageIds.flowering;

    if (nutrient == AgroMetricKey.n) {
      if (isDormancy) {
        return '$labelEs: en reposo/inducción el N alto empuja brote y puede romper la floración; no lo tomes como bueno.';
      }
      if (isFruitFill) {
        return '$labelEs: en llenado el N solo ayuda con carga y hoja sana; en exceso mete brote y resta calibre/calidad.';
      }
      if (isHarvest) {
        return '$labelEs: cerca del corte evita empujar N; en variedades que cambian de color baja firmeza/color y complica poscosecha.';
      }
      return '$labelEs: ajusta N por carga, agua y salinidad; más N no es más mango.';
    }
    if (nutrient == AgroMetricKey.k) {
      if (isFruitFill) {
        return '$labelEs: el K manda calibre y calidad; no lo subas si la EC está alta o falta agua.';
      }
      if (isHarvest) {
        return '$labelEs: el K sostiene calidad final, pero no subas K con EC alta.';
      }
      return '$labelEs: maneja K en la zona mojada y con raíz activa; el amarre y el llenado lo piden.';
    }
    if (nutrient == AgroMetricKey.p) {
      if (isFlowering) {
        return '$labelEs: P acompaña floración, pero agua, temperatura, HR y sanidad mandan el cuajado.';
      }
      return '$labelEs: P pesa más en raíz y arranque; en suelo calizo revisa disponibilidad antes de corregir.';
    }
    return '$labelEs: interpreta NPK junto con agua, EC, pH, raíz, sanidad, carga y etapa.';
  }
}

/// Resuelve el modificador del mango desde perfil/variedad/alias (doc 05 §8).
/// Desconocido → perfil general (sin variedad ni destino asumido).
MangoTreeNutritionModifier resolveMangoTreeNutritionModifier({
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

  final canonical = _canonicalMangoProfile(tokens);

  switch (canonical) {
    case kMg01AtaulfoManila:
      return const MangoTreeNutritionModifier(
        profileId: kMg01AtaulfoManila,
        group: MangoTreeNutritionGroup.ataulfoManilaEarly,
        labelEs: 'Ataulfo/Manila',
        summaryEs:
            'Temprano/premium: K alto en amarre y llenado; B/Ca/Zn/Mg contexto '
            'fuerte para flor/cuajado/firmeza. N alto en reposo/inducción o '
            'llenado se penaliza más (calidad, mancha, calibre, poscosecha). '
            'Premium no significa más toneladas.',
      );
    case kMg02TommyAtkins:
      return const MangoTreeNutritionModifier(
        profileId: kMg02TommyAtkins,
        group: MangoTreeNutritionGroup.tommyAtkinsVolume,
        labelEs: 'Tommy Atkins',
        summaryEs:
            'Volumen/exportación: K en tamaño, color y firmeza. N alto puede '
            'meter vigor excesivo y romper inducción/floración; vigila cáscara, '
            'antracnosis y calidad. Buen potencial con riego y copa manejada.',
      );
    case kMg03Kent:
      return const MangoTreeNutritionModifier(
        profileId: kMg03Kent,
        group: MangoTreeNutritionGroup.kentLateQuality,
        labelEs: 'Kent',
        summaryEs:
            'Intermedio-tardío, calidad interna: K y agua fuertes durante el '
            'llenado largo; EC baja. N alto tarde penaliza calidad, color y '
            'poscosecha. Vigila madurez de corte y alternancia moderada.',
      );
    case kMg04Keitt:
      return const MangoTreeNutritionModifier(
        profileId: kMg04Keitt,
        group: MangoTreeNutritionGroup.keittVeryLate,
        labelEs: 'Keitt',
        summaryEs:
            'Muy tardío, fruto grande: llenado muy largo, así que memoria y '
            'postcosecha pesan más. K sostenido, agua estable y EC baja; N alto '
            'tarde castiga calidad. Fruta presente más tiempo no garantiza '
            'rendimiento.',
      );
    case kMg05CriolloRegional:
      return const MangoTreeNutritionModifier(
        profileId: kMg05CriolloRegional,
        group: MangoTreeNutritionGroup.criolloRegional,
        labelEs: 'Criollo/regional',
        summaryEs:
            'Variabilidad alta y manejo local: tolera rangos amplios sin '
            'sobreestimar rendimiento. NPK orienta, pero agua, sales, pH, raíz, '
            'sanidad y alternancia mandan primero. Menor agresividad ante '
            'desviaciones pequeñas.',
      );
    default:
      return const MangoTreeNutritionModifier(
        profileId: kMgSkip,
        group: MangoTreeNutritionGroup.generic,
        labelEs: 'Mango general',
        summaryEs:
            'Perfil general: no asume Ataulfo, Tommy, Kent, Keitt ni criollo. '
            'NPK orienta, pero agua, sales (EC), pH, raíz y sanidad mandan '
            'primero. La NO floración puede ser estado válido; la inducción no '
            'se receta. Menor agresividad ante desviaciones pequeñas.',
      );
  }
}

String _canonicalMangoProfile(List<String> tokens) {
  for (final token in tokens) {
    switch (token) {
      case kMg01AtaulfoManila:
      case kMg02TommyAtkins:
      case kMg03Kent:
      case kMg04Keitt:
      case kMg05CriolloRegional:
      case kMgSkip:
        return token;
    }
    for (final entry in mangoTreeProfileEntries) {
      if (entry.id == token) return entry.id;
      if (entry.aliases.any((a) => a.trim().toLowerCase() == token)) {
        return entry.id;
      }
    }
    // Heuristica por palabra clave (doc 05 §8): tolera texto libre del wizard.
    if (token.contains('ataulfo') ||
        token.contains('ataúlfo') ||
        token.contains('manila') ||
        token.contains('miel') ||
        token.contains('honey') ||
        token.contains('champagne')) {
      return kMg01AtaulfoManila;
    }
    if (token.contains('tommy') || token.contains('atkins')) {
      return kMg02TommyAtkins;
    }
    if (token.contains('kent')) {
      return kMg03Kent;
    }
    if (token.contains('keitt')) {
      return kMg04Keitt;
    }
    if (token.contains('criol') ||
        token.contains('regional') ||
        token.contains('patio') ||
        token.contains('huerto viejo')) {
      return kMg05CriolloRegional;
    }
  }
  return kMgSkip;
}
