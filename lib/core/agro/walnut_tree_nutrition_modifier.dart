import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/tree_nutrition_modifier.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Grupo de perfil del nogal para matices nutricionales (doc 05 §17).
///
/// Espeja el patron de manzano/pera/durazno: NO cambia la estructura fenologica
/// ni los targets base; solo ajusta presion fenologica y mensajes segun el
/// perfil NG.
enum WalnutTreeNutritionGroup {
  generic,
  western,
  wichita,
  westernWichita,
  criolloRegional,
  tempranoNuevo,
}

class WalnutTreeNutritionModifier implements TreeNutritionModifier {
  const WalnutTreeNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
  });

  final String profileId;
  final WalnutTreeNutritionGroup group;
  final String labelEs;
  final String summaryEs;

  bool get isGeneric => group == WalnutTreeNutritionGroup.generic;

  /// Perfiles vigorosos donde el N alto se va a follaje/sombra mas facil
  /// (doc 05 §17): Wichita y el bloque Western/Wichita. En nogal "mas N no es
  /// mas nuez": el exceso compite con el llenado de almendra.
  bool get isVigorProne =>
      group == WalnutTreeNutritionGroup.wichita ||
      group == WalnutTreeNutritionGroup.westernWichita;

  /// Perfiles con mayor sensibilidad a zinc (doc 05 §3.6, §17): Wichita y los
  /// tempranos tipo Pawnee en suelos alcalinos/calizos.
  bool get isZincSensitive =>
      group == WalnutTreeNutritionGroup.wichita ||
      group == WalnutTreeNutritionGroup.tempranoNuevo;

  /// Delta de presion fenologica por nutriente/etapa (doc 05 §10, §17).
  ///
  /// - P: pesa mas en raiz/establecimiento/brotacion/floracion.
  /// - K: protagonista del fruto desde amarre (fruit_set, fruit_fill,
  ///   harvest_maturity); en nogal el K del llenado de almendra es central.
  /// - N: en llenado/madurez NO es prioridad de deficit (se relaja levemente);
  ///   el riesgo real ahi es el EXCESO (vigor/sombra), penalizado por el motor.
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
        // El nogal es muy sensible a K bajo en llenado de almendra (doc 05 §0.3).
        return isFruitK ? 0.07 : 0.0;
      case AgroMetricKey.n:
        return isLateNitrogenRisk ? -0.03 : 0.0;
      default:
        return 0.0;
    }
  }

  /// Penalizacion EXTRA (multiplicador <= 1.0) por N en EXCESO real tardio
  /// (llenado/madurez). Mayor en perfiles vigorosos. Es un concepto de scoring,
  /// NO una identidad de etapa ni copy de cosecha (v1.5).
  @override
  double lateNitrogenExcessPenaltyFactor(String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isLateNitrogenRisk =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;
    if (!isLateNitrogenRisk) return 1.0;
    return isVigorProne ? 0.85 : 0.92;
  }

  /// Matiz UX por perfil para la recomendacion practica (doc 05 §17).
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
      case WalnutTreeNutritionGroup.generic:
        if (isFruitFill) {
          return 'Nogal general: en llenado de almendra manda la nuez; mas N no es mas nuez.';
        }
        if (isHarvestMaturity) {
          return 'Nogal general: cerca de cosecha evita N tardio que retrase madurez.';
        }
        return 'Nogal general: ajusta N sin empujar brotes tiernos; vigila zinc y agua.';
      case WalnutTreeNutritionGroup.western:
        if (isFruitFill) {
          return 'Western: el llenado depende de agua, hoja funcional y K; el N de mas no llena nuez.';
        }
        if (isHarvestMaturity) {
          return 'Western: no fuerces N tarde; cuida calidad de almendra y alternancia.';
        }
        return 'Western responde a manejo fino de agua/N/Zn; no todo se resuelve con mas N.';
      case WalnutTreeNutritionGroup.wichita:
        if (isFruitFill) {
          return 'Wichita: vigorosa; con N alto y poca carga se va a follaje. Cuida K, agua y zinc.';
        }
        if (isHarvestMaturity) {
          return 'Wichita: evita N tardio; mas vigor sube sticktights y desordenes.';
        }
        return 'Wichita responde mucho a N, pero requiere balance para no irse a puro vigor.';
      case WalnutTreeNutritionGroup.westernWichita:
        if (isFruitFill) {
          return 'Bloque Western/Wichita: en llenado prioriza K, agua y carga; no empujes N.';
        }
        if (isHarvestMaturity) {
          return 'Bloque Western/Wichita: cuida calidad y postcosecha; evita N tardio.';
        }
        return 'Bloque Western/Wichita: balancea N con carga real de nuez para no sobre-vegetar.';
      case WalnutTreeNutritionGroup.criolloRegional:
        if (isFruitFill) {
          return 'Criollo/regional: suelo, agua y memoria pesan tanto como NPK; cuida llenado.';
        }
        if (isHarvestMaturity) {
          return 'Criollo/regional: no fuerces N tarde; el huerto viejo arrastra alternancia.';
        }
        return 'Criollo/regional: responde mejor a manejo parejo (agua/raiz/Zn) que a jalones de N.';
      case WalnutTreeNutritionGroup.tempranoNuevo:
        if (isFruitFill) {
          return 'Temprano/Pawnee-Kanza: el ciclo se adelanta; sostiene K y agua sin empujar N.';
        }
        if (isHarvestMaturity) {
          return 'Temprano/Pawnee-Kanza: cosecha temprana deja postcosecha larga; corta N a tiempo.';
        }
        return 'Temprano/Pawnee-Kanza: cuida zinc en el arranque y no uses N para forzar floracion.';
    }
  }

  String _potassiumCaution({
    required bool isFruitFill,
    required bool isHarvestMaturity,
  }) {
    if (isFruitFill || isHarvestMaturity) {
      return '$labelEs: K sostiene tamano de nuez, llenado de almendra y calidad; no lo subas si hay sales altas.';
    }
    return '$labelEs: maneja K con riego parejo y sin excederte; vigila la salinidad.';
  }

  String _phosphorusCaution() {
    if (group == WalnutTreeNutritionGroup.generic) {
      return 'Nogal general: P ayuda mas en raiz, arranque y floracion; en pH alto revisa disponibilidad.';
    }
    return '$labelEs: corrige P solo con analisis; en suelo calizo el problema suele ser disponibilidad.';
  }

  String _generalCaution({
    required bool isFruitFill,
    required bool isHarvestMaturity,
  }) {
    if (isFruitFill) {
      return '$labelEs en llenado: prioriza nuez, K, agua y zinc contextual.';
    }
    if (isHarvestMaturity) {
      return '$labelEs en madurez/cosecha: cuida calidad de almendra, ruezno y secado.';
    }
    return '$labelEs: ajusta segun etapa y lectura BioG; agua y zinc primero.';
  }
}

/// Resuelve el modificador del nogal desde perfil/variedad/alias (doc 01).
/// Desconocido → perfil general (sin variedad ni alto rendimiento asumidos).
WalnutTreeNutritionModifier resolveWalnutTreeNutritionModifier({
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

  final canonical = _canonicalWalnutProfile(tokens);

  switch (canonical) {
    case kNg01Western:
      return const WalnutTreeNutritionModifier(
        profileId: kNg01Western,
        group: WalnutTreeNutritionGroup.western,
        labelEs: 'Western Schley',
        summaryEs:
            'Base del norte: manejo fino de agua, N eficiente, zinc y K en llenado.',
      );
    case kNg02Wichita:
      return const WalnutTreeNutritionModifier(
        profileId: kNg02Wichita,
        group: WalnutTreeNutritionGroup.wichita,
        labelEs: 'Wichita',
        summaryEs:
            'Prolifica y vigorosa: balancea N con carga; alta sensibilidad a zinc.',
      );
    case kNg03WesternWichita:
      return const WalnutTreeNutritionModifier(
        profileId: kNg03WesternWichita,
        group: WalnutTreeNutritionGroup.westernWichita,
        labelEs: 'Bloque Western/Wichita',
        summaryEs:
            'Huerto comercial: carga de nuez, K en llenado, postcosecha y alternancia.',
      );
    case kNg04CriolloRegional:
      return const WalnutTreeNutritionModifier(
        profileId: kNg04CriolloRegional,
        group: WalnutTreeNutritionGroup.criolloRegional,
        labelEs: 'Criollo / regional',
        summaryEs:
            'Huerto viejo/variable: suelo, raiz, agua y memoria pesan tanto como NPK.',
      );
    case kNg05TempranoPawneeKanza:
      return const WalnutTreeNutritionModifier(
        profileId: kNg05TempranoPawneeKanza,
        group: WalnutTreeNutritionGroup.tempranoNuevo,
        labelEs: 'Temprano / Pawnee-Kanza',
        summaryEs:
            'Ciclo adelantado: zinc en arranque, K/agua en llenado, sin N tardio.',
      );
    default:
      return const WalnutTreeNutritionModifier(
        profileId: kNgSkip,
        group: WalnutTreeNutritionGroup.generic,
        labelEs: 'Nogal general',
        summaryEs: 'Perfil general; agua, raiz, salinidad y zinc antes que mas N.',
      );
  }
}

String _canonicalWalnutProfile(List<String> tokens) {
  for (final token in tokens) {
    switch (token) {
      case kNg01Western:
      case kNg02Wichita:
      case kNg03WesternWichita:
      case kNg04CriolloRegional:
      case kNg05TempranoPawneeKanza:
      case kNgSkip:
        return token;
    }
    for (final entry in walnutTreeProfileEntries) {
      if (entry.id == token) return entry.id;
      if (entry.aliases.any((a) => a.trim().toLowerCase() == token)) {
        return entry.id;
      }
    }
  }
  return kNgSkip;
}
