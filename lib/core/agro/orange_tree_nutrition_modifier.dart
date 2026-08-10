import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/tree_nutrition_modifier.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Grupo de perfil del naranjo para matices nutricionales (doc 05 §11-§12).
///
/// Espeja el patron de los demas arboles: NO cambia la estructura fenologica ni
/// los targets base; solo ajusta presion fenologica y mensajes segun el perfil
/// OR.
enum OrangeTreeNutritionGroup {
  generic,
  valenciaJuiceLate,
  navelFreshQuality,
  earlyOrange,
  regionalRustic,
  tropicalWarm,
}

class OrangeTreeNutritionModifier implements TreeNutritionModifier {
  const OrangeTreeNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
  });

  final String profileId;
  final OrangeTreeNutritionGroup group;
  final String labelEs;
  final String summaryEs;

  bool get isGeneric => group == OrangeTreeNutritionGroup.generic;

  /// Perfiles de fruta fresca/mesa donde la calidad externa y el N tardio pesan
  /// mas (doc 05 §11): Navel y Temprano. El N tardio penaliza mas fuerte.
  bool get isFreshQualitySensitive =>
      group == OrangeTreeNutritionGroup.navelFreshQuality ||
      group == OrangeTreeNutritionGroup.earlyOrange;

  /// Delta de presion fenologica por nutriente/etapa (doc 05 §11-§12).
  ///
  /// - P: pesa mas en raiz/establecimiento/floracion.
  /// - K: protagonista del fruto desde amarre (fruit_set, fruit_fill,
  ///   harvest_maturity): calibre, jugo, calidad.
  /// - N: en llenado/madurez NO es prioridad de deficit (se relaja levemente);
  ///   el riesgo real ahi es el EXCESO (follaje/cascara/color con baja carga).
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

    switch (nutrient) {
      case AgroMetricKey.p:
        return (base + (isRootOrFlower ? 0.04 : 0.0)).clamp(0.0, 1.0);
      case AgroMetricKey.k:
        return (base + (isFruitK ? 0.08 : 0.0)).clamp(0.0, 1.0);
      case AgroMetricKey.n:
        return (base + (isLateN ? -0.04 : 0.0)).clamp(0.0, 1.0);
      default:
        return base;
    }
  }

  /// Penalizacion EXTRA (multiplicador <= 1.0) por N en EXCESO real tardio
  /// (llenado/madurez). Mayor en perfiles de mesa/calidad y ventana corta. Es un
  /// concepto de scoring, NO una identidad de etapa ni copy de cosecha (v1.5).
  @override
  double lateNitrogenExcessPenaltyFactor(String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isLateNitrogenRisk =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;
    if (!isLateNitrogenRisk) return 1.0;
    return switch (group) {
      OrangeTreeNutritionGroup.navelFreshQuality => 0.82,
      OrangeTreeNutritionGroup.earlyOrange => 0.84,
      OrangeTreeNutritionGroup.valenciaJuiceLate => 0.88,
      OrangeTreeNutritionGroup.tropicalWarm => 0.88,
      OrangeTreeNutritionGroup.generic => 0.92,
      OrangeTreeNutritionGroup.regionalRustic => 0.94,
    };
  }

  /// Matiz UX por perfil para la recomendacion practica (doc 05 §11).
  @override
  String practicalCaution(AgroMetricKey nutrient, String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isFruitFill = stage == TreeStageIds.fruitFill;
    final isHarvest = stage == TreeStageIds.harvestMaturity;
    final isFlowering = stage == TreeStageIds.flowering;

    if (nutrient == AgroMetricKey.n) {
      if (isFruitFill) {
        return '$labelEs: en llenado el N solo ayuda si hay carga y hoja sana; con baja carga se va a puro follaje y cáscara.';
      }
      if (isHarvest) {
        return '$labelEs: cerca de cosecha evita empujar N; puede retrasar color, engrosar cáscara y bajar calidad.';
      }
      return '$labelEs: ajusta N por carga, agua y salinidad; más N no es más naranja.';
    }
    if (nutrient == AgroMetricKey.k) {
      if (isFruitFill) {
        return '$labelEs: el K manda en calibre y jugo; no lo subas si la EC está alta o falta agua.';
      }
      if (isHarvest) {
        return '$labelEs: el K sostiene calidad final, pero la cosecha se decide por color, calibre y sanidad.';
      }
      return '$labelEs: maneja K en la zona mojada y con raíz activa.';
    }
    if (nutrient == AgroMetricKey.p) {
      if (isFlowering) {
        return '$labelEs: P acompaña floración, pero agua, temperatura y clima mandan el cuajado.';
      }
      return '$labelEs: P pesa más en raíz y arranque; en suelo calizo revisa disponibilidad antes de corregir.';
    }
    return '$labelEs: interpreta NPK junto con agua, EC, pH, raíz, sanidad y carga.';
  }
}

/// Resuelve el modificador del naranjo desde perfil/variedad/alias (doc 05 §11).
/// Desconocido → perfil general (sin variedad ni destino mesa/jugo asumidos).
OrangeTreeNutritionModifier resolveOrangeTreeNutritionModifier({
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

  final canonical = _canonicalOrangeProfile(tokens);

  switch (canonical) {
    case kOr01Valencia:
      return const OrangeTreeNutritionModifier(
        profileId: kOr01Valencia,
        group: OrangeTreeNutritionGroup.valenciaJuiceLate,
        labelEs: 'Valencia/tardía',
        summaryEs:
            'Ciclo largo de jugo: K sostenido en llenado y madurez; N tardío '
            'con cuidado por color/calidad. Postcosecha importante.',
      );
    case kOr02Navel:
      return const OrangeTreeNutritionModifier(
        profileId: kOr02Navel,
        group: OrangeTreeNutritionGroup.navelFreshQuality,
        labelEs: 'Navel/mesa',
        summaryEs:
            'Fruta de mesa: calidad externa alta. Penaliza más el N alto tarde; '
            'K/Ca/Mg contexto para calidad, rajado y cáscara.',
      );
    case kOr03Temprano:
      return const OrangeTreeNutritionModifier(
        profileId: kOr03Temprano,
        group: OrangeTreeNutritionGroup.earlyOrange,
        labelEs: 'Temprano/Hamlin-Pineapple',
        summaryEs:
            'Ventana corta: adelanta cosecha. El exceso de N tarde penaliza más; '
            'K temprano en cuajado/llenado. Vigila caída fisiológica.',
      );
    case kOr04CriolloRegional:
      return const OrangeTreeNutritionModifier(
        profileId: kOr04CriolloRegional,
        group: OrangeTreeNutritionGroup.regionalRustic,
        labelEs: 'Criollo/regional',
        summaryEs:
            'Genética y manejo variables: menor confianza. No sobreactúes con '
            'desviaciones pequeñas; vigila salinidad, raíz y manejo irregular.',
      );
    case kOr05TropicalCalido:
      return const OrangeTreeNutritionModifier(
        profileId: kOr05TropicalCalido,
        group: OrangeTreeNutritionGroup.tropicalWarm,
        labelEs: 'Tropical/clima cálido',
        summaryEs:
            'Múltiples floraciones y calor: agua/EC pesan más. El N no debe '
            'empujar brotes todo el año sin carga; cuida caída por calor.',
      );
    default:
      return const OrangeTreeNutritionModifier(
        profileId: kOrSkip,
        group: OrangeTreeNutritionGroup.generic,
        labelEs: 'Naranjo general',
        summaryEs:
            'Perfil general: no asume variedad, destino mesa/jugo ni carga. NPK '
            'orienta, pero agua, sales, pH y raíz mandan primero.',
      );
  }
}

String _canonicalOrangeProfile(List<String> tokens) {
  for (final token in tokens) {
    switch (token) {
      case kOr01Valencia:
      case kOr02Navel:
      case kOr03Temprano:
      case kOr04CriolloRegional:
      case kOr05TropicalCalido:
      case kOrSkip:
        return token;
    }
    for (final entry in orangeTreeProfileEntries) {
      if (entry.id == token) return entry.id;
      if (entry.aliases.any((a) => a.trim().toLowerCase() == token)) {
        return entry.id;
      }
    }
    // Heuristica por palabra clave (doc 05 §11): tolera texto libre del wizard.
    if (token.contains('valencia') || token.contains('tardi')) {
      return kOr01Valencia;
    }
    if (token.contains('navel') || token.contains('ombligo')) {
      return kOr02Navel;
    }
    if (token.contains('hamlin') ||
        token.contains('pineapple') ||
        token.contains('tempran')) {
      return kOr03Temprano;
    }
    if (token.contains('criol') || token.contains('regional')) {
      return kOr04CriolloRegional;
    }
    if (token.contains('tropical') || token.contains('calid')) {
      return kOr05TropicalCalido;
    }
  }
  return kOrSkip;
}
