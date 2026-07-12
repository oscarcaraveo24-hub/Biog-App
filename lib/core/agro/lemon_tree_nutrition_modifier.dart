import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/tree_nutrition_modifier.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Grupo de perfil del limón para matices nutricionales (doc 05 §8).
///
/// Espeja el patron de los demas arboles: NO cambia la estructura fenologica ni
/// los targets base; solo ajusta presion fenologica y mensajes segun el perfil
/// LM. El limón NO es un naranjo pequeño: su K pesa más y la producción es
/// frecuente/escalonada.
enum LemonTreeNutritionGroup {
  generic,
  persianTahitiExport,
  mexicanColimaKey,
  yellowEurekaLisbon,
  tropicalContinuous,
  inducedOffSeason,
}

class LemonTreeNutritionModifier implements TreeNutritionModifier {
  const LemonTreeNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
  });

  final String profileId;
  final LemonTreeNutritionGroup group;
  final String labelEs;
  final String summaryEs;

  bool get isGeneric => group == LemonTreeNutritionGroup.generic;

  /// Perfiles donde la calidad externa y el N tardío pesan más (doc 05 §8):
  /// Persa (exportación/calibre/color verde) y Amarillo (color amarillo/nicho).
  bool get isFreshQualitySensitive =>
      group == LemonTreeNutritionGroup.persianTahitiExport ||
      group == LemonTreeNutritionGroup.yellowEurekaLisbon;

  /// Delta de presion fenologica por nutriente/etapa (doc 05 §8).
  ///
  /// - P: +0.04 en raíz/establecimiento/floración.
  /// - K: +0.08 en amarre/llenado/madurez (fruit_set, fruit_fill,
  ///   harvest_maturity): el K del limón pesa fuerte en calibre, jugo y calidad
  ///   para persa/tropical/desfase; se aplica a todos los perfiles.
  /// - N: -0.04 en llenado/madurez para persa/amarillo/desfase (perfiles
  ///   sensibles a calidad externa); el riesgo real ahí es el EXCESO tardío.
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
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;
    final penalizesLateN =
        group == LemonTreeNutritionGroup.persianTahitiExport ||
        group == LemonTreeNutritionGroup.yellowEurekaLisbon ||
        group == LemonTreeNutritionGroup.inducedOffSeason;

    switch (nutrient) {
      case AgroMetricKey.p:
        return (base + (isRootOrFlower ? 0.04 : 0.0)).clamp(0.0, 1.0);
      case AgroMetricKey.k:
        return (base + (isFruitK ? 0.08 : 0.0)).clamp(0.0, 1.0);
      case AgroMetricKey.n:
        return (base + (isLateN && penalizesLateN ? -0.04 : 0.0)).clamp(
          0.0,
          1.0,
        );
      default:
        return base;
    }
  }

  /// Penalizacion EXTRA (multiplicador <= 1.0) por N en EXCESO real tardio
  /// (llenado/madurez). Mayor en perfiles de calidad externa y ventana de
  /// desfase (doc 05 §8). Es un concepto de scoring, NO una identidad de etapa
  /// ni copy de cosecha (v1.5).
  @override
  double lateNitrogenExcessPenaltyFactor(String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isLate =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;
    if (!isLate) return 1.0;
    return switch (group) {
      LemonTreeNutritionGroup.inducedOffSeason => 0.80,
      LemonTreeNutritionGroup.yellowEurekaLisbon => 0.82,
      LemonTreeNutritionGroup.persianTahitiExport => 0.84,
      LemonTreeNutritionGroup.tropicalContinuous => 0.87,
      LemonTreeNutritionGroup.mexicanColimaKey => 0.88,
      LemonTreeNutritionGroup.generic => 0.92,
    };
  }

  /// Matiz UX por perfil para la recomendacion practica (doc 05 §8).
  @override
  String practicalCaution(AgroMetricKey nutrient, String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isFruitFill = stage == TreeStageIds.fruitFill;
    final isHarvest = stage == TreeStageIds.harvestMaturity;
    final isFlowering = stage == TreeStageIds.flowering;

    if (nutrient == AgroMetricKey.n) {
      if (isFruitFill) {
        return '$labelEs: en llenado el N solo ayuda con carga y hoja sana; con baja carga se va a puro brote tierno y atrae psílido/minador.';
      }
      if (isHarvest) {
        return '$labelEs: cerca del corte evita empujar N; puede dar brote blando, caída y bajar calidad.';
      }
      return '$labelEs: ajusta N por carga, agua y salinidad; más N no es más limón.';
    }
    if (nutrient == AgroMetricKey.k) {
      if (isFruitFill) {
        return '$labelEs: el K manda en calibre y jugo; no lo subas si la EC está alta o falta agua.';
      }
      if (isHarvest) {
        return '$labelEs: el K sostiene calidad final, pero no subas K con EC alta.';
      }
      return '$labelEs: maneja K en la zona mojada y con raíz activa.';
    }
    if (nutrient == AgroMetricKey.p) {
      if (isFlowering) {
        return '$labelEs: P acompaña floración, pero agua, temperatura y sales mandan el cuajado.';
      }
      return '$labelEs: P pesa más en raíz y arranque; en suelo calizo revisa disponibilidad antes de corregir.';
    }
    return '$labelEs: interpreta NPK junto con agua, EC, pH, raíz, sanidad y carga.';
  }
}

/// Resuelve el modificador del limón desde perfil/variedad/alias (doc 05 §8).
/// Desconocido → perfil general (sin variedad ni destino asumido).
LemonTreeNutritionModifier resolveLemonTreeNutritionModifier({
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

  final canonical = _canonicalLemonProfile(tokens);

  switch (canonical) {
    case kLm01PersaTahiti:
      return const LemonTreeNutritionModifier(
        profileId: kLm01PersaTahiti,
        group: LemonTreeNutritionGroup.persianTahitiExport,
        labelEs: 'Persa/Tahití',
        summaryEs:
            'Exportación/fresco, verde comercial, sin semilla: K fuerte en '
            'calibre/jugo/calidad externa. EC/salinidad muy crítica. N tardío '
            'con cuidado por brote y calidad.',
      );
    case kLm02MexicanoColima:
      return const LemonTreeNutritionModifier(
        profileId: kLm02MexicanoColima,
        group: LemonTreeNutritionGroup.mexicanColimaKey,
        labelEs: 'Mexicano/Colima',
        summaryEs:
            'Con semilla, producción frecuente, sensible a frío y HLB/PAC. '
            'Brotes frecuentes: N útil pero con presión de vector. K y Mg '
            'contexto; en HLB baja la confianza del NPK.',
      );
    case kLm03AmarilloEurekaLisbon:
      return const LemonTreeNutritionModifier(
        profileId: kLm03AmarilloEurekaLisbon,
        group: LemonTreeNutritionGroup.yellowEurekaLisbon,
        labelEs: 'Amarillo/Eureka-Lisbon',
        summaryEs:
            'Limón amarillo/nicho: sensible a frío/helada y calidad externa. '
            'El corte sí habla de color amarillo. N tardío puede alterar color '
            'y calidad.',
      );
    case kLm04TropicalContinuo:
      return const LemonTreeNutritionModifier(
        profileId: kLm04TropicalContinuo,
        group: LemonTreeNutritionGroup.tropicalContinuous,
        labelEs: 'Tropical/continuo',
        summaryEs:
            'Floración/corte repetidos: agua y EC pesan todo el año. K '
            'sostenido, N fraccionado/moderado. Postcosecha es entre cortes, no '
            'fin del cultivo.',
      );
    case kLm05DesfaseInducido:
      return const LemonTreeNutritionModifier(
        profileId: kLm05DesfaseInducido,
        group: LemonTreeNutritionGroup.inducedOffSeason,
        labelEs: 'Desfase/inducido',
        summaryEs:
            'Manejo/calendario, no especie: mueve la ventana, no sube el '
            'potencial. No premiar estrés; vigilar recuperación, agua y sales. '
            'N alto en inducción rompe balance y empuja vegetativo.',
      );
    default:
      return const LemonTreeNutritionModifier(
        profileId: kLmSkip,
        group: LemonTreeNutritionGroup.generic,
        labelEs: 'Limón general',
        summaryEs:
            'Perfil general: no asume Persa, Mexicano ni Amarillo. NPK orienta, '
            'pero agua, sales, pH y raíz mandan primero. Menor agresividad ante '
            'desviaciones pequeñas.',
      );
  }
}

String _canonicalLemonProfile(List<String> tokens) {
  for (final token in tokens) {
    switch (token) {
      case kLm01PersaTahiti:
      case kLm02MexicanoColima:
      case kLm03AmarilloEurekaLisbon:
      case kLm04TropicalContinuo:
      case kLm05DesfaseInducido:
      case kLmSkip:
        return token;
    }
    for (final entry in lemonTreeProfileEntries) {
      if (entry.id == token) return entry.id;
      if (entry.aliases.any((a) => a.trim().toLowerCase() == token)) {
        return entry.id;
      }
    }
    // Heuristica por palabra clave (doc 05 §8): tolera texto libre del wizard.
    if (token.contains('persa') ||
        token.contains('tahit') ||
        token.contains('persian') ||
        token.contains('sin semilla')) {
      return kLm01PersaTahiti;
    }
    if (token.contains('mexican') ||
        token.contains('colima') ||
        token.contains('criol') ||
        token.contains('key lime') ||
        token.contains('agrio')) {
      return kLm02MexicanoColima;
    }
    if (token.contains('amarill') ||
        token.contains('eureka') ||
        token.contains('lisbon') ||
        token.contains('lisboa') ||
        token.contains('italian')) {
      return kLm03AmarilloEurekaLisbon;
    }
    if (token.contains('tropical') || token.contains('continuo')) {
      return kLm04TropicalContinuo;
    }
    if (token.contains('desfase') ||
        token.contains('induc') ||
        token.contains('invierno') ||
        token.contains('programad')) {
      return kLm05DesfaseInducido;
    }
  }
  return kLmSkip;
}
