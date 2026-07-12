import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/tree_nutrition_modifier.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Grupo de perfil del aguacate para matices nutricionales (doc 05 §8, doc 04
/// §6.2 varietyModifiers).
///
/// Espeja el patron de los demas arboles: NO cambia la estructura fenologica ni
/// los targets base; solo ajusta presion fenologica y mensajes segun el perfil
/// AG. El aguacate NO es mango, NO es citrico y NO es manzano: N pesa en
/// juvenil/brote/postcosecha; en reposo/induccion y llenado/madurez el N alto es
/// riesgo; K manda en cuajado/llenado/calidad, pero en floracion NO al maximo
/// (primero cuaja); la raiz/salinidad manda antes que el NPK.
enum AvocadoTreeNutritionGroup {
  generic,
  hassExport,
  mendezCarmenEarly,
  criolloMexicano,
  fuertePielVerdeTypeB,
  antillanoTropical,
  tardioLambReed,
}

class AvocadoTreeNutritionModifier implements TreeNutritionModifier {
  const AvocadoTreeNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
  });

  final String profileId;
  final AvocadoTreeNutritionGroup group;
  final String labelEs;
  final String summaryEs;

  bool get isGeneric => group == AvocadoTreeNutritionGroup.generic;

  /// Perfiles donde la calidad de fruto y el N tardío pesan más (doc 05 §8):
  /// Hass y Méndez/Carmen (calibre/materia seca/exportación) y Tardío/Lamb/Reed
  /// (llenado muy largo, especialidad). En estos el N tardío castiga más la
  /// calidad, la piel y la poscosecha (doc 05 §0.0.1 pt2, §0.0.2 pt10).
  bool get isFruitQualitySensitive =>
      group == AvocadoTreeNutritionGroup.hassExport ||
      group == AvocadoTreeNutritionGroup.mendezCarmenEarly ||
      group == AvocadoTreeNutritionGroup.tardioLambReed;

  /// Delta de presion fenologica por nutriente/etapa (doc 05 §7, §8).
  ///
  /// - P: +0.04 en raíz/establecimiento/floración (energía, raíz fina, polen).
  /// - K: +0.06 en cuajado/llenado/madurez (fruit_set, fruit_fill,
  ///   harvest_maturity): el K manda amarre, calibre y calidad. NO se sube en
  ///   floración (doc 05 §0.0.1 pt4: en plena flor K no debe dominar; primero
  ///   cuaja). Se aplica a todos los perfiles.
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
  /// (llenado/madurez). Mayor en perfiles de calidad/exportación (doc 05
  /// §0.0.2 pt10, §8). Es un concepto de scoring, NO una identidad de etapa ni
  /// copy de cosecha (v1.5).
  @override
  double lateNitrogenExcessPenaltyFactor(String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isLate =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;
    if (!isLate) return 1.0;
    return switch (group) {
      AvocadoTreeNutritionGroup.hassExport => 0.80,
      AvocadoTreeNutritionGroup.mendezCarmenEarly => 0.82,
      AvocadoTreeNutritionGroup.tardioLambReed => 0.80,
      AvocadoTreeNutritionGroup.fuertePielVerdeTypeB => 0.86,
      AvocadoTreeNutritionGroup.antillanoTropical => 0.86,
      AvocadoTreeNutritionGroup.criolloMexicano => 0.88,
      AvocadoTreeNutritionGroup.generic => 0.90,
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
    final isFruitSet = stage == TreeStageIds.fruitSet;

    if (nutrient == AgroMetricKey.n) {
      if (isDormancy) {
        return '$labelEs: en reposo/inducción el N alto empuja brote y puede competir con la floración; no lo tomes como bueno.';
      }
      if (isFruitFill) {
        return '$labelEs: en llenado el N solo ayuda con carga y hoja sana; en exceso mete brote y resta calibre/materia seca.';
      }
      if (isHarvest) {
        return '$labelEs: cerca del corte evita empujar N; mete brote y complica la poscosecha (el aguacate madura después del corte).';
      }
      return '$labelEs: ajusta N por carga, agua y salinidad; más N no es más aguacate.';
    }
    if (nutrient == AgroMetricKey.k) {
      if (isFlowering) {
        return '$labelEs: en floración el K aún no manda: primero cuaja. Agua, clima y polinización pesan más.';
      }
      if (isFruitFill) {
        return '$labelEs: el K manda calibre y calidad; no lo subas si la EC está alta o falta agua (el aguacate es sensible a sales).';
      }
      if (isHarvest) {
        return '$labelEs: el K sostiene calidad final, pero no subas K con EC alta ni con cloruros.';
      }
      return '$labelEs: maneja K en la zona mojada y con raíz oxigenada; el amarre y el llenado lo piden.';
    }
    if (nutrient == AgroMetricKey.p) {
      if (isFlowering || isFruitSet) {
        return '$labelEs: P acompaña floración/cuajado, pero agua, temperatura, polinización y Ca/B/Zn mandan el amarre.';
      }
      return '$labelEs: P pesa más en raíz y arranque; en suelo calizo revisa disponibilidad antes de corregir.';
    }
    return '$labelEs: interpreta NPK junto con agua, EC, pH, raíz, salinidad, sanidad, carga y etapa.';
  }
}

/// Resuelve el modificador del aguacate desde perfil/variedad/alias (doc 05 §8).
/// Desconocido → perfil general (sin variedad ni tipo floral asumido).
AvocadoTreeNutritionModifier resolveAvocadoTreeNutritionModifier({
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

  final canonical = _canonicalAvocadoProfile(tokens);

  switch (canonical) {
    case kAg01Hass:
      return const AvocadoTreeNutritionModifier(
        profileId: kAg01Hass,
        group: AvocadoTreeNutritionGroup.hassExport,
        labelEs: 'Hass',
        summaryEs:
            'Exportación/tipo A: K en amarre/llenado y calidad; Ca/B/Zn/Mg '
            'contexto fuerte para flor/cuajado/firmeza/poscosecha. N alto en '
            'reposo/inducción o llenado se penaliza más (calibre, materia seca, '
            'alternancia). Muy sensible a salinidad/cloruros y a Phytophthora: '
            'raíz y EC mandan antes que el NPK. Exportación es calidad, no más '
            'toneladas.',
      );
    case kAg02MendezCarmen:
      return const AvocadoTreeNutritionModifier(
        profileId: kAg02MendezCarmen,
        group: AvocadoTreeNutritionGroup.mendezCarmenEarly,
        labelEs: 'Méndez/Carmen',
        summaryEs:
            'Hass temprano / floración desfasada («flor loca»): ventana '
            'temprana de valor, pero la floración fuera de temporada puede tirar '
            'fruta si clima/agua/raíz fallan. Misma cautela de Hass en raíz, '
            'salinidad y calidad; no copiar su manejo al 100%.',
      );
    case kAg03CriolloMexicano:
      return const AvocadoTreeNutritionModifier(
        profileId: kAg03CriolloMexicano,
        group: AvocadoTreeNutritionGroup.criolloMexicano,
        labelEs: 'Criollo/mexicano',
        summaryEs:
            'Variabilidad alta y manejo local: tolera rangos amplios sin '
            'sobreestimar rendimiento. Tipo floral desconocido. NPK orienta, '
            'pero agua, sales, pH, raíz, drenaje y sanidad mandan primero. Menor '
            'agresividad ante desviaciones pequeñas.',
      );
    case kAg04FuertePielVerde:
      return const AvocadoTreeNutritionModifier(
        profileId: kAg04FuertePielVerde,
        group: AvocadoTreeNutritionGroup.fuertePielVerdeTypeB,
        labelEs: 'Fuerte/piel verde',
        summaryEs:
            'Tipo B y posible polinizador de Hass si coincide la floración: '
            'puede alternar o ser irregular. Piel verde confunde la madurez '
            'visual. K en amarre/llenado; misma cautela de raíz/salinidad. No '
            'tratarlo como Hass negro de exportación.',
      );
    case kAg05AntillanoTropical:
      return const AvocadoTreeNutritionModifier(
        profileId: kAg05AntillanoTropical,
        group: AvocadoTreeNutritionGroup.antillanoTropical,
        labelEs: 'Antillano/tropical',
        summaryEs:
            'Costa/clima cálido y húmedo: fruto grande puede subir kg/árbol, '
            'pero no equivale a Hass exportación. En trópico húmedo mandan '
            'drenaje, raíz y sanidad (antracnosis/roña); vigila calidad externa '
            'y poscosecha. K en llenado, pero raíz/EC primero.',
      );
    case kAg06TardioLambReed:
      return const AvocadoTreeNutritionModifier(
        profileId: kAg06TardioLambReed,
        group: AvocadoTreeNutritionGroup.tardioLambReed,
        labelEs: 'Tardío/Lamb Hass/Reed',
        summaryEs:
            'Ventana extendida/especialidad, llenado muy largo: memoria, carga '
            'sostenida y postcosecha pesan más. K sostenido, agua estable y EC '
            'baja; N alto tarde castiga calidad. Fruta presente más tiempo no '
            'garantiza rendimiento; no marcar inmaduro solo porque sigue verde.',
      );
    default:
      return const AvocadoTreeNutritionModifier(
        profileId: kAgSkip,
        group: AvocadoTreeNutritionGroup.generic,
        labelEs: 'Aguacate general',
        summaryEs:
            'Perfil general: no asume Hass, Méndez/Carmen, Criollo, Fuerte, '
            'Antillano ni Tardío, ni tipo floral A/B. NPK orienta, pero agua, '
            'sales (EC), pH, raíz, drenaje y sanidad mandan primero (el aguacate '
            'es muy sensible a salinidad y a raíz sin oxígeno). La floración y el '
            'cuajado son el cuello de botella; la inducción no se receta. Menor '
            'agresividad ante desviaciones pequeñas.',
      );
  }
}

String _canonicalAvocadoProfile(List<String> tokens) {
  for (final token in tokens) {
    switch (token) {
      case kAg01Hass:
      case kAg02MendezCarmen:
      case kAg03CriolloMexicano:
      case kAg04FuertePielVerde:
      case kAg05AntillanoTropical:
      case kAg06TardioLambReed:
      case kAgSkip:
        return token;
    }
    for (final entry in avocadoTreeProfileEntries) {
      if (entry.id == token) return entry.id;
      if (entry.aliases.any((a) => a.trim().toLowerCase() == token)) {
        return entry.id;
      }
    }
    // Heuristica por palabra clave (doc 05 §8): tolera texto libre del wizard.
    if (token.contains('hass')) {
      if (token.contains('mendez') ||
          token.contains('méndez') ||
          token.contains('carmen') ||
          token.contains('temprano')) {
        return kAg02MendezCarmen;
      }
      if (token.contains('lamb')) return kAg06TardioLambReed;
      return kAg01Hass;
    }
    if (token.contains('mendez') ||
        token.contains('méndez') ||
        token.contains('carmen') ||
        token.contains('flor loca')) {
      return kAg02MendezCarmen;
    }
    if (token.contains('criol') ||
        token.contains('mexicano') ||
        token.contains('nacional') ||
        token.contains('regional') ||
        token.contains('patio') ||
        token.contains('semilla')) {
      return kAg03CriolloMexicano;
    }
    if (token.contains('fuerte') ||
        token.contains('piel verde') ||
        token.contains('green_skin')) {
      return kAg04FuertePielVerde;
    }
    if (token.contains('antillano') ||
        token.contains('tropical') ||
        token.contains('costa') ||
        token.contains('west_indian')) {
      return kAg05AntillanoTropical;
    }
    if (token.contains('reed') ||
        token.contains('lamb') ||
        token.contains('tardio') ||
        token.contains('tardío') ||
        token.contains('especialidad')) {
      return kAg06TardioLambReed;
    }
  }
  return kAgSkip;
}
