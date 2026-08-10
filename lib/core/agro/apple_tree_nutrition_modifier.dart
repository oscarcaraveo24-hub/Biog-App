import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/tree_nutrition_modifier.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Grupo de perfil del manzano para matices nutricionales (doc 05 §3, §11).
///
/// Espeja el patrón de `eggplant_nutrition_modifier` / `chili_nutrition_modifier`:
/// NO cambia la estructura fenológica ni los targets base; sólo ajusta presión
/// fenológica y mensajes según la variedad/perfil AP.
enum AppleTreeNutritionGroup {
  generic,
  golden,
  red,
  criollaRayada,
  gala,
  lowChill,
}

class AppleTreeNutritionModifier implements TreeNutritionModifier {
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
    final isLateNitrogenRisk =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;

    switch (nutrient) {
      case AgroMetricKey.p:
        return isEarlyP ? 0.04 : 0.0;
      case AgroMetricKey.k:
        return isFruitK ? 0.05 : 0.0;
      case AgroMetricKey.n:
        return isLateNitrogenRisk ? -0.03 : 0.0;
      default:
        return 0.0;
    }
  }

  @override
  double adjustStagePressure(
    double base, {
    required AgroMetricKey nutrient,
    required String? stageKey,
  }) {
    return (base + stagePressureDelta(nutrient, stageKey)).clamp(0.0, 1.0);
  }

  /// Penalización EXTRA (multiplicador ≤ 1.0) que el motor del árbol aplica
  /// cuando el N está en EXCESO real en etapas tardías (llenado/madurez).
  /// Es un concepto de scoring, no una etiqueta para copy UX.
  ///
  /// Doc 05 §3.4 + §11.2: el N alto tardío retrasa madurez, baja color rojo y
  /// firmeza; en AP-02 Red y AP-04 Gala la calidad por color castiga más.
  /// Fuera de llenado/madurez devuelve 1.0 (sin penalización adicional).
  @override
  double lateNitrogenExcessPenaltyFactor(String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isLateNitrogenRisk =
        stage == TreeStageIds.fruitFill ||
        stage == TreeStageIds.harvestMaturity;
    if (!isLateNitrogenRisk) return 1.0;
    return isColorQualitySensitive ? 0.82 : 0.92;
  }

  /// Matiz UX por variedad para la recomendación práctica (doc 05 §13).
  @override
  String practicalCaution(AgroMetricKey nutrient, String? stageKey) {
    final stage = normalizeTreeStageId(stageKey);
    final isFruitFill = stage == TreeStageIds.fruitFill;
    final isHarvestMaturity = stage == TreeStageIds.harvestMaturity;
    // Contrato v1.5 §9.3 pt8: postcosecha tiene identidad propia —reservas del
    // siguiente ciclo, hoja y raíz activas—. Sin esta rama caía al texto por
    // defecto, el MISMO que reposo: se comunicaba como dormancia pasiva, que
    // es justo lo que el anexo prohíbe.
    final isPostHarvest = stage == TreeStageIds.postHarvest;

    if (nutrient == AgroMetricKey.n) {
      return _nitrogenCaution(
        isFruitFill: isFruitFill,
        isHarvestMaturity: isHarvestMaturity,
        isPostHarvest: isPostHarvest,
      );
    }

    if (nutrient == AgroMetricKey.k) {
      return _potassiumCaution(
        isFruitFill: isFruitFill,
        isHarvestMaturity: isHarvestMaturity,
        isPostHarvest: isPostHarvest,
      );
    }

    if (nutrient == AgroMetricKey.p) {
      return _phosphorusCaution(
        isFruitFill: isFruitFill,
        isHarvestMaturity: isHarvestMaturity,
        isPostHarvest: isPostHarvest,
      );
    }

    return _generalCaution(
      isFruitFill: isFruitFill,
      isHarvestMaturity: isHarvestMaturity,
      isPostHarvest: isPostHarvest,
    );
  }

  String _nitrogenCaution({
    required bool isFruitFill,
    required bool isHarvestMaturity,
    required bool isPostHarvest,
  }) {
    switch (group) {
      case AppleTreeNutritionGroup.generic:
        if (isFruitFill) {
          return 'Manzano general: en llenado manda el fruto: calibre y firmeza. Cuida el balance N-K-Ca/Mg; el follaje de más compite con el fruto.';
        }
        if (isHarvestMaturity) {
          return 'Manzano general: cerca de cosecha cuida color y firmeza.';
        }
        if (isPostHarvest) {
          return 'Manzano general: en postcosecha el N solo suma si queda hoja activa; es la reserva de la próxima floración, no un cultivo cerrado.';
        }
        return 'Manzano general: ajusta N con calma, sin empujar brotes de más.';
      case AppleTreeNutritionGroup.golden:
        if (isFruitFill) {
          return 'Golden: en llenado cuida calibre, acabado y firmeza; sostén el balance N-K-Ca/Mg y no dejes que el follaje le gane al fruto.';
        }
        if (isHarvestMaturity) {
          return 'Golden: N alto cerca de cosecha retrasa madurez y baja firmeza.';
        }
        if (isPostHarvest) {
          return 'Golden: en postcosecha alimenta reservas con hoja activa y riego parejo; el árbol sigue trabajando.';
        }
        return 'Golden: no empujes N si BioG ya lo marca alto.';
      case AppleTreeNutritionGroup.red:
        if (isHarvestMaturity) {
          return 'Red: N alto cerca de cosecha apaga color y baja firmeza.';
        }
        if (isFruitFill) {
          return 'Red: en llenado protege calibre y firmeza; cuida el balance N-K-Ca/Mg y no dejes que el follaje dé sombra al fruto.';
        }
        if (isPostHarvest) {
          return 'Red: en postcosecha la hoja activa carga la reserva del próximo ciclo; no lo des por cerrado.';
        }
        return 'Red: prioriza color y firmeza antes que más follaje.';
      case AppleTreeNutritionGroup.gala:
        if (isHarvestMaturity) {
          return 'Gala: N alto tarde pega en color, madurez y firmeza.';
        }
        if (isFruitFill) {
          return 'Gala: en llenado protege calibre, azúcares y firmeza; cuida el balance N-K-Ca/Mg y el vigor que compite con el fruto.';
        }
        if (isPostHarvest) {
          return 'Gala: en postcosecha el N solo si hay hoja activa y raíz activa; es reserva para el próximo ciclo.';
        }
        return 'Gala: maneja N corto y claro; no busques vigor de más.';
      case AppleTreeNutritionGroup.criollaRayada:
        if (isFruitFill) {
          return 'Criolla/rayada: en llenado cuida riego parejo, calibre y firmeza; el balance N-K-Ca/Mg pesa más que subir N.';
        }
        if (isHarvestMaturity) {
          return 'Criolla/rayada: cerca de cosecha evita N tarde para no perder firmeza.';
        }
        if (isPostHarvest) {
          return 'Criolla/rayada: en postcosecha mantén hoja y raíz activas con humedad pareja; ahí se carga la reserva.';
        }
        return 'Criolla/rayada: responde mejor a manejo parejo que a jalones de N.';
      case AppleTreeNutritionGroup.lowChill:
        if (isFruitFill) {
          return 'Bajo frío: en llenado el ciclo va rápido; protege calibre y firmeza y cuida el balance N-K-Ca/Mg sin pasarte de N.';
        }
        if (isHarvestMaturity) {
          return 'Bajo frío: cerca de cosecha no retrases madurez con N.';
        }
        if (isPostHarvest) {
          return 'Bajo frío: en postcosecha la ventana de reservas es corta; aprovéchala con hoja activa y humedad pareja.';
        }
        return 'Bajo frío: usa N temprano, no tarde.';
    }
  }

  String _potassiumCaution({
    required bool isFruitFill,
    required bool isHarvestMaturity,
    required bool isPostHarvest,
  }) {
    if (isPostHarvest) {
      // §9.2 postcosecha: reservas, hoja y raíz activas, humedad, sales bajas.
      // El K deja de mandar calidad de fruto porque ya no hay fruto.
      return '$labelEs en postcosecha: el K baja de prioridad; sostén hoja y raíz activas con humedad pareja y sales bajas para cargar la reserva.';
    }
    switch (group) {
      case AppleTreeNutritionGroup.generic:
        if (isFruitFill) {
          return 'Manzano general: K ayuda a calibre y firmeza; mantén riego parejo.';
        }
        if (isHarvestMaturity) {
          return 'Manzano general: K ayuda a firmeza final; evita subir sales.';
        }
        return 'Manzano general: maneja K con riego parejo y sin excederte.';
      case AppleTreeNutritionGroup.golden:
        if (isFruitFill) {
          return 'Golden: K apoya calibre, acabado y firmeza.';
        }
        if (isHarvestMaturity) {
          return 'Golden: K sostiene firmeza; no lo subas si hay sales altas.';
        }
        return 'Golden: K con mesura para calibre y acabado.';
      case AppleTreeNutritionGroup.red:
        if (isFruitFill) {
          return 'Red: K apoya calibre, firmeza y color.';
        }
        if (isHarvestMaturity) {
          return 'Red: K ayuda a color y firmeza, sin pasarte.';
        }
        return 'Red: K acompaña color y firmeza.';
      case AppleTreeNutritionGroup.gala:
        if (isFruitFill) {
          return 'Gala: K apoya calibre y firmeza.';
        }
        if (isHarvestMaturity) {
          return 'Gala: K ayuda a firmeza final; evita exceso.';
        }
        return 'Gala: K sí ayuda, pero no lo uses de más.';
      case AppleTreeNutritionGroup.criollaRayada:
        if (isFruitFill) {
          return 'Criolla/rayada: K acompaña calibre y firmeza con riego parejo.';
        }
        if (isHarvestMaturity) {
          return 'Criolla/rayada: K sostiene firmeza; evita sales altas.';
        }
        return 'Criolla/rayada: K funciona mejor con humedad pareja.';
      case AppleTreeNutritionGroup.lowChill:
        if (isFruitFill) {
          return 'Bajo frío: K pesa temprano en calibre y firmeza.';
        }
        if (isHarvestMaturity) {
          return 'Bajo frío: K ayuda a firmeza final; evita sales altas.';
        }
        return 'Bajo frío: adelanta el K al ritmo del fruto.';
    }
  }

  /// Cautela de fósforo: matiz varietal + el vínculo pH ↔ disponibilidad.
  ///
  /// El P del manzano casi nunca falla por cantidad, falla por disponibilidad:
  /// en suelo calizo o con pH alto se fija y el árbol no lo toma aunque la
  /// lectura suba. `soil_reaction.dart` ya desplaza la banda objetivo por
  /// reacción del suelo, así que el número que ve el agricultor sale bien —
  /// pero nadie se lo explicaba. Nogal, aguacate, limón y mango sí lo dicen;
  /// al manzano se le había quedado fuera en las seis variedades.
  String _phosphorusCaution({
    required bool isFruitFill,
    required bool isHarvestMaturity,
    required bool isPostHarvest,
  }) {
    final varietal = _phosphorusVarietalCaution(
      isFruitFill: isFruitFill,
      isHarvestMaturity: isHarvestMaturity,
      isPostHarvest: isPostHarvest,
    );
    return '$varietal En suelo calizo o pH alto, revisa disponibilidad antes '
        'que cantidad.';
  }

  String _phosphorusVarietalCaution({
    required bool isFruitFill,
    required bool isHarvestMaturity,
    required bool isPostHarvest,
  }) {
    if (isPostHarvest) {
      return '$labelEs en postcosecha: el P acompaña raíz activa y las reservas del próximo ciclo, no la calidad del fruto.';
    }
    switch (group) {
      case AppleTreeNutritionGroup.generic:
        if (isFruitFill || isHarvestMaturity) {
          return 'Manzano general: en fruto, P no manda; corrige solo si BioG lo mantiene bajo.';
        }
        return 'Manzano general: P ayuda más al arranque, raíz y floración.';
      case AppleTreeNutritionGroup.golden:
        return 'Golden: no persigas P para mejorar acabado; manda más el riego y K.';
      case AppleTreeNutritionGroup.red:
        return 'Red: el color no se arregla con más P; cuida N, K y riego.';
      case AppleTreeNutritionGroup.gala:
        return 'Gala: usa P como apoyo, no como rescate de calidad.';
      case AppleTreeNutritionGroup.criollaRayada:
        return 'Criolla/rayada: corrige P solo si la lectura se sostiene baja.';
      case AppleTreeNutritionGroup.lowChill:
        return 'Bajo frío: P pesa temprano; después no lo fuerces.';
    }
  }

  String _generalCaution({
    required bool isFruitFill,
    required bool isHarvestMaturity,
    required bool isPostHarvest,
  }) {
    if (isFruitFill) {
      return '$labelEs en llenado: prioriza fruto, calibre, K y riego parejo, cuidando el balance N-K-Ca/Mg.';
    }
    if (isHarvestMaturity) {
      return '$labelEs en madurez/cosecha: cuida color, firmeza y corte.';
    }
    if (isPostHarvest) {
      return '$labelEs en postcosecha: sostén hoja y raíz activas con humedad pareja; ahí se carga la reserva del próximo ciclo.';
    }
    return '$labelEs: ajusta según etapa y lectura BioG.';
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
        labelEs: 'Golden',
        summaryEs: 'Manzana Golden / amarilla.',
      );
    case kAp02Red:
      return const AppleTreeNutritionModifier(
        profileId: kAp02Red,
        group: AppleTreeNutritionGroup.red,
        labelEs: 'Red Delicious / roja',
        summaryEs: 'Roja; color y firmeza sufren con N tardío.',
      );
    case kAp03CriollaRayada:
      return const AppleTreeNutritionModifier(
        profileId: kAp03CriollaRayada,
        group: AppleTreeNutritionGroup.criollaRayada,
        labelEs: 'Criolla / rayada',
        summaryEs: 'Criolla o rayada regional, manejo rústico.',
      );
    case kAp04Gala:
      return const AppleTreeNutritionModifier(
        profileId: kAp04Gala,
        group: AppleTreeNutritionGroup.gala,
        labelEs: 'Gala',
        summaryEs: 'Gala; color y firmeza sufren con N tardío.',
      );
    case kAp05LowChill:
      return const AppleTreeNutritionModifier(
        profileId: kAp05LowChill,
        group: AppleTreeNutritionGroup.lowChill,
        labelEs: 'Bajo frío',
        summaryEs: 'Variedades low-chill; ciclo adelantado.',
      );
    default:
      return const AppleTreeNutritionModifier(
        profileId: kApSkip,
        group: AppleTreeNutritionGroup.generic,
        labelEs: 'Manzano general',
        summaryEs: 'Manzano general; manejo claro y sin exceso de N.',
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
