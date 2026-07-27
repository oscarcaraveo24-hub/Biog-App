import 'dart:math' as math;
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/chili_nutrition_modifier.dart';
import 'package:bio_g/core/agro/eggplant_nutrition_modifier.dart';
import 'package:bio_g/core/agro/garlic_nutrition_modifier.dart';
import 'package:bio_g/core/agro/lettuce_nutrition_modifier.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/onion_nutrition_modifier.dart';
import 'package:bio_g/core/agro/spinach_nutrition_modifier.dart';
import 'package:bio_g/core/agro/squash_nutrition_modifier.dart';
import 'package:bio_g/core/agro/nutrient_target_range_resolver.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';

/// Forma de cultivo efectiva para expresar una dosis.
///
/// No coincide 1:1 con `CultivationScale`: aquí se distingue además la planta
/// o árbol individual ([plant]), cuya masa de suelo efectiva es distinta a la
/// de una maceta. `CultivationScale` sólo tiene `field | bed | pot`.
enum _DoseForm { pot, plant, bed, field }

/// Resuelve la forma de dosis a partir del id de escala persistido.
///
/// Acepta los ids canónicos que escribe el wizard (`field`, `bed`, `pot`) y los
/// alias legacy que puedan venir de contextos antiguos o de imports.
///
/// Devuelve `null` cuando el id está vacío o no se puede resolver; el llamador
/// decide qué hacer en ese caso.
///
/// Nota: antes esta resolución vivía duplicada dentro de los dos formateadores
/// de dosis como una cadena de `contains`, y el id canónico `'bed'` no
/// coincidía con ninguna rama, por lo que una cama de huerto terminaba
/// recibiendo dosis en kg/ha de campo abierto.
_DoseForm? _resolveDoseForm(String? scaleId) {
  final raw = (scaleId ?? '').trim().toLowerCase();
  if (raw.isEmpty) return null;

  // 1) Ids canónicos y alias conocidos: coincidencia exacta.
  switch (raw) {
    case 'pot':
    case 'maceta':
    case 'contenedor':
      return _DoseForm.pot;
    case 'plant':
    case 'planta':
    case 'arbol':
    case 'árbol':
    case 'tree':
      return _DoseForm.plant;
    case 'bed':
    case 'huerto':
    case 'cama':
    case 'm2':
    case 'orchard':
      return _DoseForm.bed;
    case 'field':
    case 'campo':
    case 'parcela':
      return _DoseForm.field;
  }

  // 2) Compatibilidad con ids compuestos antiguos (p. ej. 'scale_maceta_v1').
  //    Se conserva el orden histórico de evaluación para no alterar resultados.
  if (raw.contains('maceta') || raw.contains('pot')) return _DoseForm.pot;
  if (raw.contains('planta') ||
      raw.contains('arbol') ||
      raw.contains('árbol')) {
    return _DoseForm.plant;
  }
  if (raw.contains('huerto') ||
      raw.contains('cama') ||
      raw.contains('m2') ||
      raw.contains('orchard')) {
    return _DoseForm.bed;
  }
  if (raw.contains('campo') || raw.contains('field')) return _DoseForm.field;

  return null;
}

class NutrientDoseGuide {
  const NutrientDoseGuide({
    required this.doseGuideEs,
    this.fertilizerEquivalentEs,
    this.requiresConfirmation = true,
  });

  final String doseGuideEs;
  final String? fertilizerEquivalentEs;
  final bool requiresConfirmation;
}

/// =========================================================================
/// FERTILIZATION PLANNER
/// =========================================================================
///
/// Convierte el déficit de nutrientes (mg/kg) a dosis práctica por escala.
///
/// FÓRMULA PUENTE (mg/kg → kg/ha):
///   kg/ha = (Δ mg/kg × densidad_aparente × profundidad_cm) / 10
///
/// Defaults conservadores (suelo mineral promedio):
///   densidad aparente = 1.2 g/cm³
///   profundidad       = 20 cm
///
/// Con estos defaults:
///   1 mg/kg ≈ 2.4 kg/ha  →  kg/ha = Δ mg/kg × 2.4
///
/// Derivación útil:
///   1 mg/kg = 1 ppm = 0.001 g/kg de suelo
///
/// Nota importante:
/// Este planner usa el default operativo BIO-G de 20 cm para convertir a dosis
/// práctica. Eso NO equivale a la profundidad de diagnóstico agronómico que a
/// veces se usa en literatura (ej. N-NO3 0-60 cm en trigo). Aquí el objetivo
/// es mantener una salida práctica y consistente del motor.
///
/// Factores de escala:
///   campo abierto  → kg/ha
///   huerto / cama  → g/m²   (1 kg/ha = 0.1 g/m²)
///   maceta         → g/maceta (15 kg de sustrato efectivo)
///   planta / árbol → g/planta (5 kg de zona radicular efectiva)
///
/// Ley fertilizante (fracción de nutriente útil en fuente comercial):
///   Urea (46-0-0):         N = 0.46
///   DAP  (18-46-0):      P₂O₅ = 0.46
///   MAP  (11-52-0):      P₂O₅ = 0.52
///   MOP / KCl (0-0-60):  K₂O = 0.60
/// =========================================================================
class FertilizationPlanner {
  FertilizationPlanner._();

  // Constantes agronómicas base.
  static const double _densidadAparente = 1.2; // g/cm³
  static const double _profundidadCm = 20.0; // cm

  /// 1 mg/kg ≈ 2.4 kg/ha con los defaults anteriores.
  static const double _mgkgToKgHa =
      (_densidadAparente * _profundidadCm) / 10.0; // = 2.4

  // Ley fertilizante (fracción de nutriente útil).
  static const double _leyUrea = 0.46; // 46% N
  static const double _leyDap = 0.46; // 46% P₂O₅
  static const double _leyMop = 0.60; // 60% K₂O

  // Masa de suelo por escala (kg).
  static const double _masaMacetaKg = 15.0;
  static const double _masaPlantaKg = 5.0;

  static NutrientDoseGuide? buildGuide({
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
    required double rawPpm,
    required String? cropKey,
    required String? stageKey,
    String? profileId,
    String? varietyId,
    String? varietyAlias,
    String? calendarId,
    StageTargets? targets,
    String? cultivationScaleId,
  }) {
    if (label == NutrientPriorityLabel.unknown ||
        label == NutrientPriorityLabel.noPriority ||
        label == NutrientPriorityLabel.lowPriority) {
      return null;
    }

    final crop = (cropKey ?? '').trim().toLowerCase();

    if (label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation) {
      if (crop == 'chili' ||
          crop == 'chile' ||
          crop == 'pepper' ||
          crop == 'pimiento') {
        final modifier = resolveChiliNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId ?? cultivationScaleId,
        );
        return NutrientDoseGuide(
          doseGuideEs:
              'Nivel alto detectado. Pausa este nutriente en chile para evitar bloqueo, salinidad o desbalance en flor/fruto.',
          fertilizerEquivalentEs: modifier.guideCaution(nutrient, stageKey),
        );
      }
      if (crop == 'eggplant' ||
          crop == 'berenjena' ||
          crop == 'aubergine') {
        final modifier = resolveEggplantNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId ?? cultivationScaleId,
        );
        return NutrientDoseGuide(
          doseGuideEs:
              'Nivel alto detectado. Pausa este nutriente en berenjena para evitar salinidad, bloqueo o fruto marcado.',
          fertilizerEquivalentEs: modifier.guideCaution(nutrient, stageKey),
        );
      }
      if (crop == 'squash' || crop == 'calabaza' || crop == 'pumpkin') {
        final modifier = resolveSquashNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId ?? cultivationScaleId,
        );
        return NutrientDoseGuide(
          doseGuideEs:
              'Nivel alto detectado. Pausa este nutriente en calabaza para evitar salinidad, bloqueo o fruto marcado.',
          fertilizerEquivalentEs: modifier.guideCaution(nutrient, stageKey),
        );
      }
      if (crop == 'lettuce' || crop == 'lechuga' || crop == 'crop_lettuce') {
        final modifier = resolveLettuceNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId ?? cultivationScaleId,
        );
        return NutrientDoseGuide(
          doseGuideEs:
              'Nivel alto detectado. Pausa este nutriente en lechuga: el exceso puede bloquear absorcion, subir salinidad o ablandar la hoja. Revisa CE y manejo antes de agregar mas.',
          fertilizerEquivalentEs: modifier.guideCaution(nutrient, stageKey),
        );
      }
      if (crop == 'spinach' || crop == 'espinaca' || crop == 'crop_spinach') {
        final modifier = resolveSpinachNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId ?? cultivationScaleId,
        );
        return NutrientDoseGuide(
          doseGuideEs:
              'Nivel alto detectado. Pausa este nutriente en espinaca: puede subir salinidad, ablandar hoja, elevar nitratos o bajar vida de anaquel. Revisa CE y agua antes de agregar mas.',
          fertilizerEquivalentEs: modifier.guideCaution(nutrient, stageKey),
        );
      }
      if (crop == 'onion' || crop == 'cebolla' || crop == 'crop_onion') {
        final modifier = resolveOnionNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId ?? cultivationScaleId,
        );
        return NutrientDoseGuide(
          doseGuideEs:
              'Nivel alto detectado. Pausa este nutriente en cebolla: el exceso puede subir salinidad, engrosar cuello, retrasar madurez o bajar conservacion del bulbo. Revisa CE y agua antes de agregar mas.',
          fertilizerEquivalentEs: modifier.guideCaution(nutrient, stageKey),
        );
      }
      if (crop == 'garlic' || crop == 'ajo' || crop == 'crop_garlic') {
        final modifier = resolveGarlicNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId ?? cultivationScaleId,
        );
        return NutrientDoseGuide(
          doseGuideEs:
              'Nivel alto detectado. Pausa este nutriente en ajo: el exceso puede subir salinidad, provocar vigor tardio, escobeteado/canutos, mala maduracion, pudriciones o curado deficiente. Revisa CE, agua y etapa antes de agregar mas.',
          fertilizerEquivalentEs: modifier.guideCaution(nutrient, stageKey),
        );
      }
      if (_isPeachTreeCrop(crop)) {
        return _peachTreeConservativeGuide(
          nutrient: nutrient,
          label: label,
          stageKey: stageKey,
        );
      }
      if (_isWalnutTreeCrop(crop)) {
        return _walnutTreeConservativeGuide(
          nutrient: nutrient,
          label: label,
          stageKey: stageKey,
        );
      }
      if (_isPistachioTreeCrop(crop)) {
        return _pistachioTreeConservativeGuide(
          nutrient: nutrient,
          label: label,
          stageKey: stageKey,
        );
      }
      if (_isOrangeTreeCrop(crop)) {
        return _orangeTreeConservativeGuide(
          nutrient: nutrient,
          label: label,
          stageKey: stageKey,
        );
      }
      if (_isLemonTreeCrop(crop)) {
        return _lemonTreeConservativeGuide(
          nutrient: nutrient,
          label: label,
          stageKey: stageKey,
        );
      }
      if (_isMangoTreeCrop(crop)) {
        return _mangoTreeConservativeGuide(
          nutrient: nutrient,
          label: label,
          stageKey: stageKey,
        );
      }
      if (_isAvocadoTreeCrop(crop)) {
        return _avocadoTreeConservativeGuide(
          nutrient: nutrient,
          label: label,
          stageKey: stageKey,
        );
      }
      if ((crop == 'barley' || crop == 'cebada') &&
          nutrient == AgroMetricKey.n &&
          _isBarleyMalt(profileId)) {
        return const NutrientDoseGuide(
          doseGuideEs:
              '¡NO APLIQUES MÁS NITRÓGENO! Te van a rechazar el grano en la maltera por exceso de proteína.',
        );
      }
      return const NutrientDoseGuide(
        doseGuideEs:
            'Niveles altos detectados en el suelo. Pausa las aplicaciones de este nutriente para evitar bloqueos en la tierra.',
      );
    }

    final deficitPpm = _calculateDeficitPpm(nutrient, rawPpm, cropKey, targets);
    if (deficitPpm == null || deficitPpm < 2.0) return null;

    if (_isPeachTreeCrop(crop)) {
      return _peachTreeConservativeGuide(
        nutrient: nutrient,
        label: label,
        stageKey: stageKey,
      );
    }

    if (_isWalnutTreeCrop(crop)) {
      return _walnutTreeConservativeGuide(
        nutrient: nutrient,
        label: label,
        stageKey: stageKey,
      );
    }

    if (_isPistachioTreeCrop(crop)) {
      return _pistachioTreeConservativeGuide(
        nutrient: nutrient,
        label: label,
        stageKey: stageKey,
      );
    }

    if (_isOrangeTreeCrop(crop)) {
      return _orangeTreeConservativeGuide(
        nutrient: nutrient,
        label: label,
        stageKey: stageKey,
      );
    }

    if (_isLemonTreeCrop(crop)) {
      return _lemonTreeConservativeGuide(
        nutrient: nutrient,
        label: label,
        stageKey: stageKey,
      );
    }

    if (_isMangoTreeCrop(crop)) {
      return _mangoTreeConservativeGuide(
        nutrient: nutrient,
        label: label,
        stageKey: stageKey,
      );
    }

    if (_isAvocadoTreeCrop(crop)) {
      return _avocadoTreeConservativeGuide(
        nutrient: nutrient,
        label: label,
        stageKey: stageKey,
      );
    }

    if (crop == 'maize' || crop == 'maiz' || crop == 'corn') {
      return _maizeGuide(nutrient, stageKey, deficitPpm, cultivationScaleId);
    }
    if (crop == 'bean' || crop == 'frijol') {
      return _beanGuide(nutrient, stageKey, deficitPpm, cultivationScaleId);
    }
    if (crop == 'barley' || crop == 'cebada') {
      return _barleyGuide(
        nutrient,
        stageKey,
        profileId,
        deficitPpm,
        cultivationScaleId,
      );
    }
    if (crop == 'wheat' || crop == 'trigo') {
      return _wheatGuide(
        nutrient,
        stageKey,
        profileId,
        deficitPpm,
        cultivationScaleId,
      );
    }
    if (crop == 'oat' || crop == 'avena') {
      return _oatGuide(nutrient, stageKey, deficitPpm, cultivationScaleId);
    }
    if (crop == 'tomato' || crop == 'tomate' || crop == 'jitomate') {
      return _tomatoGuide(nutrient, stageKey, deficitPpm, cultivationScaleId);
    }
    if (crop == 'cucumber' || crop == 'pepino') {
      return _cucumberGuide(nutrient, stageKey, deficitPpm, cultivationScaleId);
    }
    if (crop == 'chili' ||
        crop == 'chile' ||
        crop == 'pepper' ||
        crop == 'pimiento') {
      return _chiliGuide(
        nutrient,
        stageKey,
        deficitPpm,
        cultivationScaleId,
        profileId: profileId,
        varietyId: varietyId,
        varietyAlias: varietyAlias,
        calendarId: calendarId,
      );
    }
    if (crop == 'eggplant' ||
        crop == 'berenjena' ||
        crop == 'aubergine') {
      return _eggplantGuide(
        nutrient,
        stageKey,
        deficitPpm,
        cultivationScaleId,
        profileId: profileId,
        varietyId: varietyId,
        varietyAlias: varietyAlias,
        calendarId: calendarId,
      );
    }
    if (crop == 'squash' || crop == 'calabaza' || crop == 'pumpkin') {
      return _squashGuide(
        nutrient,
        stageKey,
        deficitPpm,
        cultivationScaleId,
        profileId: profileId,
        varietyId: varietyId,
        varietyAlias: varietyAlias,
        calendarId: calendarId,
      );
    }
    if (crop == 'lettuce' || crop == 'lechuga' || crop == 'crop_lettuce') {
      return _lettuceGuide(
        nutrient,
        stageKey,
        cultivationScaleId,
        profileId: profileId,
        varietyId: varietyId,
        varietyAlias: varietyAlias,
        calendarId: calendarId,
      );
    }
    if (crop == 'spinach' || crop == 'espinaca' || crop == 'crop_spinach') {
      return _spinachGuide(
        nutrient,
        stageKey,
        cultivationScaleId,
        profileId: profileId,
        varietyId: varietyId,
        varietyAlias: varietyAlias,
        calendarId: calendarId,
      );
    }
    if (crop == 'onion' || crop == 'cebolla' || crop == 'crop_onion') {
      return _onionGuide(
        nutrient,
        stageKey,
        cultivationScaleId,
        profileId: profileId,
        varietyId: varietyId,
        varietyAlias: varietyAlias,
        calendarId: calendarId,
      );
    }
    if (crop == 'garlic' || crop == 'ajo' || crop == 'crop_garlic') {
      return _garlicGuide(
        nutrient,
        stageKey,
        cultivationScaleId,
        profileId: profileId,
        varietyId: varietyId,
        varietyAlias: varietyAlias,
        calendarId: calendarId,
      );
    }

    return _genericGuide(nutrient, deficitPpm, cultivationScaleId);
  }

  static bool _isPeachTreeCrop(String crop) {
    return crop == 'peach_tree' ||
        crop == 'crop_peach_tree' ||
        crop == 'peach' ||
        crop == 'peachtree' ||
        crop == 'durazno' ||
        crop == 'duraznero' ||
        crop == 'melocoton' ||
        crop == 'melocotón' ||
        crop == 'melocotonero';
  }

  static NutrientDoseGuide _peachTreeConservativeGuide({
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
    required String? stageKey,
  }) {
    final bool isHigh =
        label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation;
    final nutrientName = switch (nutrient) {
      AgroMetricKey.n => 'nitrógeno',
      AgroMetricKey.p => 'fósforo',
      AgroMetricKey.k => 'potasio',
      _ => 'nutriente',
    };
    final opening = isHigh
        ? '$nutrientName alto en duraznero. BioG detecta más $nutrientName del necesario para esta etapa.'
        : '$nutrientName bajo en duraznero. BioG detecta menos $nutrientName del que pide esta etapa.';

    return NutrientDoseGuide(
      doseGuideEs:
          '$opening ${_peachTreeNutrientGuide(nutrient, isHigh: isHigh)} ${_peachTreeStageGuide(stageKey)}',
      fertilizerEquivalentEs:
          'Actúa con cuidado: evita fertilizar fuerte si el suelo está muy seco, encharcado, frío o con sales altas. Si la lectura se repite varios días, valida con análisis.',
      requiresConfirmation: true,
    );
  }

  static String _peachTreeNutrientGuide(
    AgroMetricKey nutrient, {
    required bool isHigh,
  }) {
    if (isHigh) {
      return switch (nutrient) {
        AgroMetricKey.n =>
          'No apliques más nitrógeno por ahora: puede empujar follaje de más, retrasar madurez y bajar firmeza.',
        AgroMetricKey.p =>
          'Pausa fósforo extra: más P no mejora el fruto y puede bloquear otros nutrientes.',
        AgroMetricKey.k =>
          'No subas más potasio por ahora: demasiado K puede subir sales y bajar firmeza.',
        _ => 'Pausa este nutriente y sigue la tendencia de BioG.',
      };
    }
    return switch (nutrient) {
      AgroMetricKey.n =>
        'Corrige N de forma ligera si el árbol se ve débil; evita pasarte cerca de cosecha.',
      AgroMetricKey.p =>
        'Corrige P con mesura, sobre todo en raíz, brotación o floración.',
      AgroMetricKey.k =>
        'Refuerza K de forma gradual: ayuda a tamaño, firmeza, dulzor y llenado del fruto.',
      _ => 'Ajusta este nutriente de forma gradual y revisa la respuesta del árbol.',
    };
  }

  static String _peachTreeStageGuide(String? stageKey) {
    final stage = (stageKey ?? '').trim().toLowerCase();
    if (stage.contains('post_harvest')) {
      return 'En postcosecha, solo corrige si el árbol sigue con hoja y riego parejo; no metas N si ya va a reposo.';
    }
    if (stage.contains('fruit_fill') ||
        stage.contains('fruit_set') ||
        stage.contains('harvest_maturity')) {
      return 'En cuajado, llenado o madurez, mantén riego parejo y evita N tardío que ablande fruta.';
    }
    if (stage.contains('root') ||
        stage.contains('planting') ||
        stage.contains('budbreak') ||
        stage.contains('flower')) {
      return 'En raíz, brotación y floración, corrige poco a poco y cuida que el suelo no esté frío, seco o encharcado.';
    }
    return 'Haz ajustes graduales y revisa si la lectura mejora en los siguientes riegos.';
  }

  static bool _isWalnutTreeCrop(String crop) {
    return crop == 'walnut_tree' ||
        crop == 'crop_walnut_tree' ||
        crop == 'walnut' ||
        crop == 'walnuttree' ||
        crop == 'nogal' ||
        crop == 'nogal pecanero' ||
        crop == 'pecan' ||
        crop == 'nuez' ||
        crop == 'nuez pecana';
  }

  static NutrientDoseGuide _walnutTreeConservativeGuide({
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
    required String? stageKey,
  }) {
    final bool isHigh =
        label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation;
    final nutrientName = switch (nutrient) {
      AgroMetricKey.n => 'nitrógeno',
      AgroMetricKey.p => 'fósforo',
      AgroMetricKey.k => 'potasio',
      _ => 'nutriente',
    };
    final opening = isHigh
        ? '$nutrientName alto en nogal. BioG detecta más $nutrientName del necesario para esta etapa.'
        : '$nutrientName bajo en nogal. BioG detecta menos $nutrientName del que pide esta etapa.';

    return NutrientDoseGuide(
      doseGuideEs:
          '$opening ${_walnutTreeNutrientGuide(nutrient, isHigh: isHigh)} ${_walnutTreeStageGuide(stageKey)}',
      fertilizerEquivalentEs:
          'Actúa con cuidado: en nogal manda primero agua, raíz, salinidad (EC) y pH. Evita fertilizar fuerte si el suelo está seco, encharcado, frío o con sales altas. El zinc es contexto clave pero no lo mide este sensor. Si la lectura se repite, valida con análisis de suelo/foliar.',
      requiresConfirmation: true,
    );
  }

  static String _walnutTreeNutrientGuide(
    AgroMetricKey nutrient, {
    required bool isHigh,
  }) {
    if (isHigh) {
      return switch (nutrient) {
        AgroMetricKey.n =>
          'No apliques más nitrógeno por ahora: en nogal más N no es más nuez, puede empujar follaje, sombra y sales.',
        AgroMetricKey.p =>
          'Pausa fósforo extra: más P no mejora la nuez y en suelo calizo puede bloquear zinc/hierro.',
        AgroMetricKey.k =>
          'No subas más potasio por ahora: demasiado K puede subir sales y desbalancear magnesio/calcio.',
        _ => 'Pausa este nutriente y sigue la tendencia de BioG.',
      };
    }
    return switch (nutrient) {
      AgroMetricKey.n =>
        'Corrige N de forma ligera si la hoja se ve débil; evita pasarte y no metas N tardío cerca de cosecha.',
      AgroMetricKey.p =>
        'Corrige P con mesura y análisis, sobre todo en raíz, brotación o floración.',
      AgroMetricKey.k =>
        'Refuerza K de forma gradual: ayuda al crecimiento de nuez y al llenado de almendra; cuida el riego parejo.',
      _ => 'Ajusta este nutriente de forma gradual y revisa la respuesta del árbol.',
    };
  }

  static String _walnutTreeStageGuide(String? stageKey) {
    final stage = (stageKey ?? '').trim().toLowerCase();
    if (stage.contains('post_harvest')) {
      return 'En postcosecha, solo corrige si el nogal sigue con hoja activa y riego parejo: la hoja carga reservas para el siguiente ciclo. No metas N si ya va a reposo.';
    }
    if (stage.contains('fruit_fill')) {
      return 'En llenado de nuez/almendra, el potasio y el agua mandan; no empujes N que se vaya a follaje. (Esto es llenado, todavía no cosecha.)';
    }
    if (stage.contains('fruit_set') || stage.contains('harvest_maturity')) {
      return 'En amarre y madurez/ruezno, mantén riego parejo y evita N tardío que retrase madurez o ablande el árbol.';
    }
    if (stage.contains('root') ||
        stage.contains('planting') ||
        stage.contains('budbreak') ||
        stage.contains('flower')) {
      return 'En raíz, brotación y floración, corrige poco a poco; cuida zinc contextual y que el suelo no esté frío, seco o con sales.';
    }
    return 'Haz ajustes graduales y revisa si la lectura mejora en los siguientes riegos.';
  }

  static bool _isPistachioTreeCrop(String crop) {
    return crop == 'pistachio_tree' ||
        crop == 'crop_pistachio_tree' ||
        crop == 'pistachio' ||
        crop == 'pistachiotree' ||
        crop == 'pistache' ||
        crop == 'pistacho' ||
        crop == 'pistachero';
  }

  static bool _isOrangeTreeCrop(String crop) {
    return crop == 'orange_tree' ||
        crop == 'crop_orange_tree' ||
        crop == 'orange' ||
        crop == 'orangetree' ||
        crop == 'naranjo' ||
        crop == 'naranja';
  }

  static bool _isLemonTreeCrop(String crop) {
    return crop == 'lemon_tree' ||
        crop == 'crop_lemon_tree' ||
        crop == 'lemontree' ||
        crop == 'lime_tree' ||
        crop == 'crop_lime_tree' ||
        crop == 'lemon' ||
        crop == 'lime' ||
        crop == 'limon' ||
        crop == 'limón' ||
        crop == 'limonero' ||
        crop == 'lima';
  }

  static bool _isMangoTreeCrop(String crop) {
    return crop == 'mango_tree' ||
        crop == 'crop_mango_tree' ||
        crop == 'mangotree' ||
        crop == 'crop_mango' ||
        crop == 'mango' ||
        crop == 'mangos' ||
        crop == 'mangifera' ||
        crop == 'mangifera_indica' ||
        crop == 'arbol_mango' ||
        crop == 'árbol_mango';
  }

  static bool _isAvocadoTreeCrop(String crop) {
    return crop == 'avocado_tree' ||
        crop == 'crop_avocado_tree' ||
        crop == 'avocadotree' ||
        crop == 'crop_avocado' ||
        crop == 'avocado' ||
        crop == 'avocados' ||
        crop == 'aguacate' ||
        crop == 'aguacates' ||
        crop == 'aguacatero' ||
        crop == 'palta' ||
        crop == 'palto' ||
        crop == 'persea' ||
        crop == 'persea_americana' ||
        crop == 'arbol_aguacate' ||
        crop == 'árbol_aguacate' ||
        crop == 'arbol de aguacate' ||
        crop == 'árbol de aguacate';
  }

  static NutrientDoseGuide _pistachioTreeConservativeGuide({
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
    required String? stageKey,
  }) {
    final bool isHigh =
        label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation;
    final nutrientName = switch (nutrient) {
      AgroMetricKey.n => 'nitrógeno',
      AgroMetricKey.p => 'fósforo',
      AgroMetricKey.k => 'potasio',
      _ => 'nutriente',
    };
    final opening = isHigh
        ? '$nutrientName alto en pistache. BioG detecta más $nutrientName del necesario para esta etapa.'
        : '$nutrientName bajo en pistache. BioG detecta menos $nutrientName del que pide esta etapa.';

    return NutrientDoseGuide(
      doseGuideEs:
          '$opening ${_pistachioTreeNutrientGuide(nutrient, isHigh: isHigh)} ${_pistachioTreeStageGuide(stageKey)}',
      fertilizerEquivalentEs:
          'El pistache no se fertiliza a ciegas: manda primero agua, raíz, salinidad (EC) y pH. Aguanta más sal que otros frutales, pero EC alta sigue bloqueando. El boro y el zinc son contexto clave pero no los mide este sensor. Si vas a mover fuerte N, P o K, confirma con análisis de suelo, agua y hoja.',
      requiresConfirmation: true,
    );
  }

  static String _pistachioTreeNutrientGuide(
    AgroMetricKey nutrient, {
    required bool isHigh,
  }) {
    if (isHigh) {
      return switch (nutrient) {
        AgroMetricKey.n =>
          'No apliques más nitrógeno por ahora: en pistache más N no es más pistache, con baja carga se va a puro follaje.',
        AgroMetricKey.p =>
          'Pausa fósforo extra: en adulto el P no se aplica por costumbre y en suelo calizo puede bloquear zinc/hierro.',
        AgroMetricKey.k =>
          'No subas más potasio por ahora: con sales altas el K puede sumar estrés osmótico y desbalancear magnesio/calcio.',
        _ => 'Pausa este nutriente y sigue la tendencia de BioG.',
      };
    }
    return switch (nutrient) {
      AgroMetricKey.n =>
        'Corrige N de forma ligera y por carga si la hoja se ve débil; evita N tardío que retrase la latencia o favorezca helada.',
      AgroMetricKey.p =>
        'Corrige P con mesura y análisis, sobre todo en raíz, brotación o floración; en pistache no es protagonista adulto.',
      AgroMetricKey.k =>
        'Refuerza K de forma gradual en la zona mojada: ayuda al kernel, la apertura (split) y la calidad; cuida el riego parejo y la EC.',
      _ => 'Ajusta este nutriente de forma gradual y revisa la respuesta del árbol.',
    };
  }

  static String _pistachioTreeStageGuide(String? stageKey) {
    final stage = (stageKey ?? '').trim().toLowerCase();
    if (stage.contains('post_harvest')) {
      return 'En postcosecha, solo corrige si el pistache sigue con hoja activa y riego parejo: la hoja carga reservas para el siguiente ciclo. No todo huerto necesita N postcosecha.';
    }
    if (stage.contains('fruit_fill')) {
      return 'En llenado de kernel, el potasio y el agua mandan; no empujes N que se vaya a follaje. (Esto es llenado, todavía no cosecha.)';
    }
    if (stage.contains('fruit_set') || stage.contains('harvest_maturity')) {
      return 'En amarre y madurez/apertura, mantén riego parejo y evita N tardío; si no amarró, revisa macho/hembra, frío y clima antes de fertilizar.';
    }
    if (stage.contains('root') ||
        stage.contains('planting') ||
        stage.contains('budbreak') ||
        stage.contains('flower')) {
      return 'En raíz, brotación y floración, corrige poco a poco; cuida boro/zinc contextual y que el suelo no esté frío, seco o con sales. En floración manda macho/hembra y clima, no el NPK.';
    }
    return 'Haz ajustes graduales y revisa si la lectura mejora en los siguientes riegos.';
  }

  static NutrientDoseGuide _orangeTreeConservativeGuide({
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
    required String? stageKey,
  }) {
    final bool isHigh =
        label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation;
    final nutrientName = switch (nutrient) {
      AgroMetricKey.n => 'nitrógeno',
      AgroMetricKey.p => 'fósforo',
      AgroMetricKey.k => 'potasio',
      _ => 'nutriente',
    };
    final opening = isHigh
        ? '$nutrientName alto en naranjo. BioG detecta más $nutrientName del necesario para esta etapa.'
        : '$nutrientName bajo en naranjo. BioG detecta menos $nutrientName del que pide esta etapa.';

    return NutrientDoseGuide(
      doseGuideEs:
          '$opening ${_orangeTreeNutrientGuide(nutrient, isHigh: isHigh)} ${_orangeTreeStageGuide(stageKey)}',
      fertilizerEquivalentEs:
          'El naranjo no se fertiliza a ciegas: manda primero agua, raíz, salinidad (EC) y pH. Es sensible a sales, así que EC alta bloquea la lectura. El hierro, zinc y manganeso son contexto clave con pH alto, pero no los mide este sensor. Si vas a mover fuerte N, P o K, confirma con análisis de suelo, agua y hoja.',
      requiresConfirmation: true,
    );
  }

  static String _orangeTreeNutrientGuide(
    AgroMetricKey nutrient, {
    required bool isHigh,
  }) {
    if (isHigh) {
      return switch (nutrient) {
        AgroMetricKey.n =>
          'No apliques más nitrógeno por ahora: en naranjo más N no es más naranja, con baja carga se va a follaje, cáscara gruesa y retraso de color.',
        AgroMetricKey.p =>
          'Pausa fósforo extra: en adulto el P no se aplica por costumbre y en suelo calizo puede bloquear zinc/hierro.',
        AgroMetricKey.k =>
          'No subas más potasio por ahora: con sales altas el K puede sumar estrés osmótico y desbalancear magnesio/calcio.',
        _ => 'Pausa este nutriente y sigue la tendencia de BioG.',
      };
    }
    return switch (nutrient) {
      AgroMetricKey.n =>
        'Corrige N de forma ligera y por carga si la hoja se ve débil; evita N tardío que retrase el color o engrose la cáscara.',
      AgroMetricKey.p =>
        'Corrige P con mesura y análisis, sobre todo en raíz, arranque o floración; en naranjo adulto no es protagonista.',
      AgroMetricKey.k =>
        'Refuerza K de forma gradual en la zona mojada: ayuda al calibre, el jugo y la calidad; cuida el riego parejo y la EC.',
      _ => 'Ajusta este nutriente de forma gradual y revisa la respuesta del árbol.',
    };
  }

  static String _orangeTreeStageGuide(String? stageKey) {
    final stage = (stageKey ?? '').trim().toLowerCase();
    if (stage.contains('post_harvest')) {
      return 'En postcosecha, solo corrige si el naranjo sigue con hoja activa y riego parejo: la hoja carga reservas para la siguiente floración. La cosecha no apaga el árbol.';
    }
    if (stage.contains('fruit_fill')) {
      return 'En llenado, el potasio y el agua mandan calibre y jugo; no empujes N que se vaya a follaje. (Esto es llenado, todavía no cosecha.)';
    }
    if (stage.contains('fruit_set')) {
      return 'En cuajado/amarre, mantén riego parejo y evita el estrés: si se cae el frutito, revisa calor, agua, sales y raíz antes de fertilizar.';
    }
    if (stage.contains('harvest_maturity')) {
      return 'En madurez/cosecha cuida color, calibre, jugo y calidad; no empujes N tardío. En Valencia el color externo puede engañar.';
    }
    if (stage.contains('dormancy')) {
      return 'En reposo relativo el naranjo sigue verde (no es árbol pelón): baja la presión de NPK y cuida raíz, humedad y sales.';
    }
    if (stage.contains('root') ||
        stage.contains('planting') ||
        stage.contains('budbreak') ||
        stage.contains('flower')) {
      return 'En raíz, brotación y floración, corrige poco a poco; cuida Fe/Zn/Mn contextual y que el suelo no esté frío, seco o con sales. En floración manda el agua y el clima, no el NPK.';
    }
    return 'Haz ajustes graduales y revisa si la lectura mejora en los siguientes riegos.';
  }

  static NutrientDoseGuide _lemonTreeConservativeGuide({
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
    required String? stageKey,
  }) {
    final bool isHigh =
        label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation;
    final nutrientName = switch (nutrient) {
      AgroMetricKey.n => 'nitrógeno',
      AgroMetricKey.p => 'fósforo',
      AgroMetricKey.k => 'potasio',
      _ => 'nutriente',
    };
    final opening = isHigh
        ? '$nutrientName alto en limón. BioG detecta más $nutrientName del necesario para esta etapa.'
        : '$nutrientName bajo en limón. BioG detecta menos $nutrientName del que pide esta etapa.';

    return NutrientDoseGuide(
      doseGuideEs:
          '$opening ${_lemonTreeNutrientGuide(nutrient, isHigh: isHigh)} ${_lemonTreeStageGuide(stageKey)}',
      fertilizerEquivalentEs:
          'El limón no se fertiliza a ciegas: manda primero agua, raíz, salinidad (EC) y pH. Es sensible a sales, así que EC alta bloquea la lectura. El hierro, zinc, manganeso, magnesio y azufre son contexto clave (pH alto/HLB), pero no los mide este sensor. Con HLB, gomosis o raíz dañada baja la confianza del NPK. Si vas a mover fuerte N, P o K, confirma con análisis de suelo, agua y hoja.',
      requiresConfirmation: true,
    );
  }

  static String _lemonTreeNutrientGuide(
    AgroMetricKey nutrient, {
    required bool isHigh,
  }) {
    if (isHigh) {
      return switch (nutrient) {
        AgroMetricKey.n =>
          'No apliques más nitrógeno por ahora: en limón más N no es más limón, con baja carga se va a puro brote tierno y atrae psílido/minador.',
        AgroMetricKey.p =>
          'Pausa fósforo extra: en adulto el P no se aplica por costumbre y en suelo calizo puede bloquear zinc/hierro.',
        AgroMetricKey.k =>
          'No subas más potasio por ahora: con sales altas el K puede sumar estrés osmótico y desbalancear magnesio/calcio.',
        _ => 'Pausa este nutriente y sigue la tendencia de BioG.',
      };
    }
    return switch (nutrient) {
      AgroMetricKey.n =>
        'Corrige N de forma ligera y por carga si la hoja se ve débil; evita N tardío que dé brote blando, caída o baje calidad.',
      AgroMetricKey.p =>
        'Corrige P con mesura y análisis, sobre todo en raíz, arranque o floración; en limón adulto no es protagonista.',
      AgroMetricKey.k =>
        'Refuerza K de forma gradual en la zona mojada: manda calibre, jugo y calidad; cuida el riego parejo y la EC (el limón es sensible a sales).',
      _ => 'Ajusta este nutriente de forma gradual y revisa la respuesta del árbol.',
    };
  }

  static String _lemonTreeStageGuide(String? stageKey) {
    final stage = (stageKey ?? '').trim().toLowerCase();
    if (stage.contains('post_harvest')) {
      return 'En postcosecha/entre cortes, solo corrige si el limón sigue con hoja activa y riego parejo: la hoja carga reservas para la siguiente floración o corte. La cosecha no apaga el árbol.';
    }
    if (stage.contains('fruit_fill')) {
      return 'En llenado, el potasio y el agua mandan calibre y jugo; no empujes N que se vaya a brote tierno. (Esto es llenado, todavía no cosecha.)';
    }
    if (stage.contains('fruit_set')) {
      return 'En cuajado/amarre del limoncito, mantén riego parejo y evita el estrés: si se cae el frutito, revisa calor, agua, sales y raíz antes de fertilizar.';
    }
    if (stage.contains('harvest_maturity')) {
      return 'Cerca del corte cuida calibre, jugo y calidad; no empujes N tardío. En persa/mexicano el limón comercial puede seguir verde.';
    }
    if (stage.contains('dormancy')) {
      return 'En reposo relativo/entre cortes el limón sigue verde (no es árbol pelón): baja la presión de NPK y cuida raíz, humedad y sales.';
    }
    if (stage.contains('root') ||
        stage.contains('planting') ||
        stage.contains('budbreak') ||
        stage.contains('flower')) {
      return 'En raíz, brotación y floración, corrige poco a poco; cuida Fe/Zn/Mn contextual y que el suelo no esté frío, seco o con sales. En floración manda el agua y el clima, no el NPK. El brote tierno atrae psílido/minador.';
    }
    return 'Haz ajustes graduales y revisa si la lectura mejora en los siguientes riegos.';
  }

  static NutrientDoseGuide _mangoTreeConservativeGuide({
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
    required String? stageKey,
  }) {
    final bool isHigh =
        label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation;
    final nutrientName = switch (nutrient) {
      AgroMetricKey.n => 'nitrógeno',
      AgroMetricKey.p => 'fósforo',
      AgroMetricKey.k => 'potasio',
      _ => 'nutriente',
    };
    final opening = isHigh
        ? '$nutrientName alto en mango. BioG detecta más $nutrientName del necesario para esta etapa.'
        : '$nutrientName bajo en mango. BioG detecta menos $nutrientName del que pide esta etapa.';

    return NutrientDoseGuide(
      doseGuideEs:
          '$opening ${_mangoTreeNutrientGuide(nutrient, isHigh: isHigh)} ${_mangoTreeStageGuide(stageKey)}',
      fertilizerEquivalentEs:
          'El mango no se fertiliza a ciegas: manda primero agua, raíz, salinidad (EC) y pH. Es sensible a sales, así que EC alta bloquea la lectura. El calcio, boro, magnesio, azufre y zinc son contexto clave (flor, cuajado, firmeza, poscosecha), pero no los mide este sensor. La sanidad (antracnosis, cenicilla, mosca de fruta) baja la confianza del NPK. Si vas a mover fuerte N, P o K, confirma con análisis de suelo, agua y hoja. La inducción floral no se receta.',
      requiresConfirmation: true,
    );
  }

  static String _mangoTreeNutrientGuide(
    AgroMetricKey nutrient, {
    required bool isHigh,
  }) {
    if (isHigh) {
      return switch (nutrient) {
        AgroMetricKey.n =>
          'No apliques más nitrógeno por ahora: en mango más N no es más mango; en reposo/inducción empuja brote y rompe la floración, y tarde mete follaje y baja calidad.',
        AgroMetricKey.p =>
          'Pausa fósforo extra: en adulto el P no se aplica por costumbre y en suelo calizo puede bloquear zinc/hierro.',
        AgroMetricKey.k =>
          'No subas más potasio por ahora: con sales altas el K puede sumar estrés osmótico y desbalancear magnesio/calcio.',
        _ => 'Pausa este nutriente y sigue la tendencia de BioG.',
      };
    }
    return switch (nutrient) {
      AgroMetricKey.n =>
        'Corrige N de forma ligera y por carga si la hoja se ve débil; evita N tardío que meta brote o baje color/firmeza. En reposo/inducción, un N bajo no es problema.',
      AgroMetricKey.p =>
        'Corrige P con mesura y análisis, sobre todo en raíz, arranque o floración; en mango adulto no es protagonista.',
      AgroMetricKey.k =>
        'Refuerza K de forma gradual en la zona mojada: manda amarre, calibre y calidad; cuida el riego parejo y la EC (el mango es sensible a sales).',
      _ => 'Ajusta este nutriente de forma gradual y revisa la respuesta del árbol.',
    };
  }

  static String _mangoTreeStageGuide(String? stageKey) {
    final stage = (stageKey ?? '').trim().toLowerCase();
    if (stage.contains('post_harvest')) {
      return 'En postcosecha, solo corrige si el mango sigue con hoja activa y riego parejo: es la ventana fuerte de reservas para la siguiente floración. La cosecha no apaga el árbol.';
    }
    if (stage.contains('fruit_fill')) {
      return 'En llenado, el potasio y el agua mandan calibre y calidad; no empujes N que se vaya a brote. (Esto es llenado, todavía no cosecha.)';
    }
    if (stage.contains('fruit_set')) {
      return 'En cuajado/amarre del manguito, mantén riego parejo y evita el estrés: si se cae el frutito, revisa calor, agua, sales, sanidad de panícula y raíz antes de fertilizar.';
    }
    if (stage.contains('harvest_maturity')) {
      return 'Cerca del corte cuida calibre, madurez y calidad; no empujes N tardío. No decidas la madurez solo por el color externo (Kent/Keitt pueden verse verdes).';
    }
    if (stage.contains('dormancy')) {
      return 'En reposo funcional/inducción el mango sigue verde (no es árbol pelón): baja la presión de N (empuja brote y rompe flor) y cuida raíz, humedad y sales. La inducción no se receta.';
    }
    if (stage.contains('root') ||
        stage.contains('planting') ||
        stage.contains('budbreak') ||
        stage.contains('flower')) {
      return 'En raíz, brotación y floración, corrige poco a poco; cuida Ca/B/Fe/Zn contextual y que el suelo no esté frío, seco o con sales. En floración mandan agua, HR, sanidad de panícula y clima, no el NPK.';
    }
    return 'Haz ajustes graduales y revisa si la lectura mejora en los siguientes riegos.';
  }

  static NutrientDoseGuide _avocadoTreeConservativeGuide({
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
    required String? stageKey,
  }) {
    final bool isHigh =
        label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation;
    final nutrientName = switch (nutrient) {
      AgroMetricKey.n => 'nitrógeno',
      AgroMetricKey.p => 'fósforo',
      AgroMetricKey.k => 'potasio',
      _ => 'nutriente',
    };
    final opening = isHigh
        ? '$nutrientName alto en aguacate. BioG detecta más $nutrientName del necesario para esta etapa.'
        : '$nutrientName bajo en aguacate. BioG detecta menos $nutrientName del que pide esta etapa.';

    return NutrientDoseGuide(
      doseGuideEs:
          '$opening ${_avocadoTreeNutrientGuide(nutrient, isHigh: isHigh)} ${_avocadoTreeStageGuide(stageKey)}',
      fertilizerEquivalentEs:
          'El aguacate no se fertiliza a ciegas: manda primero raíz, drenaje, agua, salinidad (EC) y pH. Es MUY sensible a sales, cloruros, sodio y boro, así que EC alta o suelo saturado bloquean la lectura y pueden empeorar el árbol. El calcio, boro, magnesio, azufre y zinc son contexto clave (flor, cuajado, firmeza, poscosecha), pero no los mide este sensor. La sanidad (Phytophthora, antracnosis, roña) baja la confianza del NPK. Si vas a mover fuerte N, P o K, confirma con análisis de suelo, agua y hoja. La inducción floral no se receta.',
      requiresConfirmation: true,
    );
  }

  static String _avocadoTreeNutrientGuide(
    AgroMetricKey nutrient, {
    required bool isHigh,
  }) {
    if (isHigh) {
      return switch (nutrient) {
        AgroMetricKey.n =>
          'No apliques más nitrógeno por ahora: en aguacate más N no es más aguacate; en reposo/inducción empuja brote y compite con la floración, y tarde mete follaje y baja calidad/poscosecha.',
        AgroMetricKey.p =>
          'Pausa fósforo extra: en adulto el P no se aplica por costumbre y en suelo calizo puede bloquear zinc/hierro.',
        AgroMetricKey.k =>
          'No subas más potasio por ahora: con sales/cloruros altos el K suma estrés osmótico y desbalancea magnesio/calcio. En floración el K aún no manda: primero cuaja.',
        _ => 'Pausa este nutriente y sigue la tendencia de BioG.',
      };
    }
    return switch (nutrient) {
      AgroMetricKey.n =>
        'Corrige N de forma ligera y por carga si la hoja se ve débil; evita N tardío que meta brote o complique la poscosecha. En reposo/inducción, un N bajo no es problema.',
      AgroMetricKey.p =>
        'Corrige P con mesura y análisis, sobre todo en raíz, arranque o floración; en aguacate adulto no es protagonista.',
      AgroMetricKey.k =>
        'Refuerza K de forma gradual en la zona mojada: manda amarre, calibre y calidad; cuida el riego parejo y la EC (el aguacate es muy sensible a sales/cloruros).',
      _ => 'Ajusta este nutriente de forma gradual y revisa la respuesta del árbol.',
    };
  }

  static String _avocadoTreeStageGuide(String? stageKey) {
    final stage = (stageKey ?? '').trim().toLowerCase();
    if (stage.contains('post_harvest')) {
      return 'En postcosecha, solo corrige si el aguacate sigue con hoja activa y riego parejo: es la ventana viva de reservas para la siguiente floración. La cosecha no apaga el árbol.';
    }
    if (stage.contains('fruit_fill')) {
      return 'En llenado, el potasio y el agua mandan calibre y materia seca; no empujes N que se vaya a brote. (Esto es llenado, todavía no cosecha; madura después del corte.)';
    }
    if (stage.contains('fruit_set')) {
      return 'En cuajado/amarre del aguacatito, mantén riego parejo, baja EC y raíz oxigenada: si se cae el frutito, revisa calor, agua, sales, polinización y raíz antes de fertilizar. Ca/B/Zn son contexto.';
    }
    if (stage.contains('harvest_maturity')) {
      return 'Cerca del corte cuida madurez fisiológica, materia seca y calidad; no empujes N tardío. No decidas la madurez solo por el color externo (el aguacate madura después del corte).';
    }
    if (stage.contains('dormancy')) {
      return 'En reposo funcional/inducción el aguacate sigue verde (es siempreverde, no árbol pelón): baja la presión de N (empuja brote y compite con la flor) y cuida raíz, humedad y sales. La inducción no se receta.';
    }
    if (stage.contains('flower')) {
      return 'En floración manda agua, temperatura, polinización (tipo A/B) y Ca/B/Zn contextual, no el NPK. El K aún no va al máximo: primero cuaja. Corrige poco a poco.';
    }
    if (stage.contains('root') ||
        stage.contains('planting') ||
        stage.contains('budbreak')) {
      return 'En raíz, plantación y brotación corrige poco a poco; la raíz fina del aguacate no tolera sales ni saturación. Cuida drenaje, EC baja y Ca/B/Fe/Zn contextual.';
    }
    return 'Haz ajustes graduales y revisa si la lectura mejora en los siguientes riegos.';
  }

  // ==========================================
  // CÁLCULO DE DÉFICIT REAL (mg/kg)
  // ==========================================
  /// Compara la lectura cruda contra el punto medio del rango óptimo
  /// de la etapa actual y devuelve el déficit en mg/kg.
  static double? _calculateDeficitPpm(
    AgroMetricKey nutrient,
    double rawPpm,
    String? cropKey,
    StageTargets? targets,
  ) {
    if (targets == null) return null;

    final range = NutrientTargetRangeResolver.comparableRange(
      nutrient: nutrient,
      cropKey: cropKey,
      targets: targets,
    );
    if (range == null) return null;

    final targetMidPpm = (range.optimalMin + range.optimalMax) / 2.0;

    return math.max(0.0, targetMidPpm - rawPpm);
  }

  // ==========================================
  // HELPERS DE CONVERSIÓN Y TEXTO
  // ==========================================

  static double _kgHaPuro(double deficitPpm) => deficitPpm * _mgkgToKgHa;

  static double _gKgSoil(double deficitPpm) => deficitPpm / 1000.0;

  static String _formatPureDoseText(
    double deficitPpm,
    String nutrientName,
    String? scaleId,
  ) {
    // Sin escala resoluble se conserva el comportamiento histórico (campo
    // abierto). TODO(BIO-G): el Fundacional 2.1 §9.3 pide no emitir dosis
    // cuando la forma de cultivo no se conoce; cambiar a retorno nulo cuando
    // existan las pruebas del bloque 3.
    final form = _resolveDoseForm(scaleId) ?? _DoseForm.field;

    switch (form) {
      case _DoseForm.pot:
        final gPuros = (deficitPpm * _masaMacetaKg) / 1000.0;
        return '${gPuros.toStringAsFixed(1)} g de $nutrientName por maceta';
      case _DoseForm.plant:
        final gPuros = (deficitPpm * _masaPlantaKg) / 1000.0;
        return '${gPuros.toStringAsFixed(1)} g de $nutrientName por planta';
      case _DoseForm.bed:
        final gM2Puros = _kgHaPuro(deficitPpm) * 0.1;
        return '${gM2Puros.toStringAsFixed(1)} g/m² de $nutrientName';
      case _DoseForm.field:
        final kgHaPuros = _kgHaPuro(deficitPpm);
        return '~${kgHaPuros.round()} kg/ha de $nutrientName';
    }
  }

  static String _formatCommercialDoseText(
    double deficitPpm,
    double leyFertilizante,
    String sourceName,
    String? scaleId,
  ) {
    // Ver nota en _formatPureDoseText sobre el fallback a campo abierto.
    final form = _resolveDoseForm(scaleId) ?? _DoseForm.field;

    switch (form) {
      case _DoseForm.pot:
        final gPuros = (deficitPpm * _masaMacetaKg) / 1000.0;
        final gComercial = gPuros / leyFertilizante;
        return '${gComercial.toStringAsFixed(1)} g de $sourceName por maceta';
      case _DoseForm.plant:
        final gPuros = (deficitPpm * _masaPlantaKg) / 1000.0;
        final gComercial = gPuros / leyFertilizante;
        return '${gComercial.toStringAsFixed(1)} g de $sourceName por planta';
      case _DoseForm.bed:
        final gM2Comercial = (_kgHaPuro(deficitPpm) * 0.1) / leyFertilizante;
        return '${gM2Comercial.toStringAsFixed(1)} g/m² de $sourceName';
      case _DoseForm.field:
        final kgHaComercial =
            ((_kgHaPuro(deficitPpm) / leyFertilizante) / 5).round() * 5;
        return '~$kgHaComercial kg/ha de $sourceName';
    }
  }

  static String _formatSoilBridgeText(double deficitPpm) {
    final gKg = _gKgSoil(deficitPpm);
    final kgHaPuros = _kgHaPuro(deficitPpm);
    final gKgText = gKg < 0.1 ? gKg.toStringAsFixed(3) : gKg.toStringAsFixed(2);

    return 'Déficit estimado: ${deficitPpm.toStringAsFixed(1)} mg/kg (~$gKgText g/kg de suelo; ~${kgHaPuros.round()} kg/ha de nutriente puro con el default BIO-G de 20 cm y 1.2 g/cm³).';
  }

  static String _joinExtra(String base, String extra) => '$base $extra';

  // ==========================================
  // GUÍAS POR CULTIVO
  // ==========================================

  static NutrientDoseGuide _maizeGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    double deficitPpm,
    String? scale,
  ) {
    final stage = (stageKey ?? '').toLowerCase();
    final isPeakN = _isPeakNitrogenStage(stage);
    final isEarly = _isEarlyStage(stage);
    final isLate = _isLateStage(stage);
    final bridge = _formatSoilBridgeText(deficitPpm);

    if (isLate) {
      return const NutrientDoseGuide(
        doseGuideEs:
            'El ciclo ya cerró. Usa esta lectura del suelo para planear tu pre-siembra del próximo ciclo.',
        fertilizerEquivalentEs:
            'Aplicar fertilizante en madurez/cosecha es un desperdicio económico.',
      );
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        final eqUrea = _formatCommercialDoseText(
          deficitPpm,
          _leyUrea,
          'Urea (46-0-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Nitrógeno puro',
          scale,
        );
        if (isPeakN) {
          return NutrientDoseGuide(
            doseGuideEs:
                '¡Viene el estirón de la milpa! Aplica $puroText para que la mazorca llene.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a aplicar $eqUrea.',
              bridge,
            ),
          );
        }
        if (isEarly) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arrancador de N: aplica $puroText para que la plántula agarre fuerza.',
            fertilizerEquivalentEs: _joinExtra('Con $eqUrea la armas.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs: 'Para emparejar tu tierra a la meta, aplica $puroText.',
          fertilizerEquivalentEs: _joinExtra('Con $eqUrea la armas.', bridge),
        );

      case AgroMetricKey.p:
        final eqDap = _formatCommercialDoseText(
          deficitPpm,
          _leyDap,
          'DAP (18-46-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Fósforo (P₂O₅) puro',
          scale,
        );
        if (isEarly) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arranque vital: aplica $puroText al lado de la semilla para que eche raíz.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a aplicar $eqDap.',
              bridge,
            ),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs: 'Aplica $puroText para que no se atrase la milpa.',
          fertilizerEquivalentEs: _joinExtra('Aplícale $eqDap.', bridge),
        );

      case AgroMetricKey.k:
        final eqMop = _formatCommercialDoseText(
          deficitPpm,
          _leyMop,
          'KCl (0-0-60)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Potasio (K₂O) puro',
          scale,
        );
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para fortalecer la caña y evitar que se acame.',
          fertilizerEquivalentEs: _joinExtra(
            'Equivale a aplicar $eqMop.',
            bridge,
          ),
        );

      default:
        return const NutrientDoseGuide(doseGuideEs: 'Falta nutriente.');
    }
  }

  static NutrientDoseGuide _beanGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    double deficitPpm,
    String? scale,
  ) {
    final stage = (stageKey ?? '').toLowerCase();
    final isEarly = _isEarlyStage(stage);
    final isFlowering = stage.contains('flower') || stage.contains('flor');
    final isPodFill =
        stage.contains('pod') ||
        stage.contains('grain') ||
        stage.contains('vaina') ||
        stage.contains('llenado');
    final isLate = _isLateStage(stage);
    final bridge = _formatSoilBridgeText(deficitPpm);

    if (isLate) {
      return const NutrientDoseGuide(
        doseGuideEs:
            'El frijol ya está en fase final. Deja secar la vaina y guarda esta lectura para planear el próximo ciclo.',
        fertilizerEquivalentEs: null,
      );
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        final eqUrea = _formatCommercialDoseText(
          deficitPpm,
          _leyUrea,
          'Urea',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Nitrógeno puro',
          scale,
        );
        if (isEarly) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arrancador: aplica $puroText mientras la planta todavía no fija su propio nitrógeno.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
          );
        }
        if (isFlowering) {
          return NutrientDoseGuide(
            doseGuideEs:
                'La planta está en floración y no alcanza a fijar suficiente N. Aplica $puroText para evitar aborto de flor.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para complementar la fijación biológica.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
        );

      case AgroMetricKey.p:
        final eqDap = _formatCommercialDoseText(
          deficitPpm,
          _leyDap,
          'DAP',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Fósforo (P₂O₅) puro',
          scale,
        );
        if (isEarly) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Fósforo VITAL para nodular. Aplica $puroText al sembrar, enterrado al lado de la semilla.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqDap.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs: 'Aplica $puroText para reforzar raíz y nodulación.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqDap.', bridge),
        );

      case AgroMetricKey.k:
        final eqMop = _formatCommercialDoseText(
          deficitPpm,
          _leyMop,
          'KCl',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Potasio (K₂O) puro',
          scale,
        );
        if (isFlowering || isPodFill) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Llenado de vaina: aplica $puroText para que el grano pese en la báscula.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqMop.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs: 'Aplica $puroText para preparar reservas de Potasio.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqMop.', bridge),
        );

      default:
        return const NutrientDoseGuide(doseGuideEs: 'Falta nutriente.');
    }
  }

  static NutrientDoseGuide _barleyGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    String? profileId,
    double deficitPpm,
    String? scale,
  ) {
    final isMalt = _isBarleyMalt(profileId);
    final stage = (stageKey ?? '').toLowerCase();
    final isEarly = _isEarlyStage(stage);
    final isTillering = stage.contains('tiller') || stage.contains('macoll');
    final isLate = _isLateStage(stage);
    final bridge = _formatSoilBridgeText(deficitPpm);

    if (isLate) {
      return const NutrientDoseGuide(
        doseGuideEs:
            'El ciclo de la cebada ya cerró. Usa esta lectura para planear tu pre-siembra.',
      );
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        final eqUrea = _formatCommercialDoseText(
          deficitPpm,
          _leyUrea,
          'Urea',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Nitrógeno puro',
          scale,
        );
        if (isMalt &&
            (stage.contains('head') ||
                stage.contains('espig') ||
                stage.contains('flower') ||
                stage.contains('flor') ||
                stage.contains('grain') ||
                stage.contains('llenado'))) {
          return const NutrientDoseGuide(
            doseGuideEs:
                'Prohibido aplicar N tarde en cebada maltera: sube la proteína y te rechazan el grano.',
          );
        }
        if (isEarly || isTillering) {
          return NutrientDoseGuide(
            doseGuideEs: isMalt
                ? 'Aplica $puroText en macollamiento para amarrar espigas sin subir proteína al final.'
                : 'Aplica $puroText temprano para maximizar macollos y forraje.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs: 'Aplica $puroText para ajustar la meta de la etapa.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
        );

      case AgroMetricKey.p:
        final eqDap = _formatCommercialDoseText(
          deficitPpm,
          _leyDap,
          'DAP',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Fósforo (P₂O₅) puro',
          scale,
        );
        if (isEarly || isTillering) {
          return NutrientDoseGuide(
            doseGuideEs:
                'La cebada necesita P para echar raíz fuerte. Aplica $puroText lo antes posible.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqDap.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'La corrección de Fósforo fuera de la etapa temprana es poco eficiente. Si puedes, aplícalo en pre-siembra del próximo ciclo.',
          fertilizerEquivalentEs: bridge,
        );

      case AgroMetricKey.k:
        final eqMop = _formatCommercialDoseText(
          deficitPpm,
          _leyMop,
          'KCl',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Potasio (K₂O) puro',
          scale,
        );
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para prevenir encamado y fortalecer el tallo.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqMop.', bridge),
        );

      default:
        return const NutrientDoseGuide(doseGuideEs: 'Falta nutriente.');
    }
  }

  static NutrientDoseGuide _wheatGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    String? profileId,
    double deficitPpm,
    String? scale,
  ) {
    final stage = (stageKey ?? '').toLowerCase();
    final isForage = _isWheatForage(profileId);

    final isEarly = _isEarlyStage(stage);
    final isTillering = stage.contains('tiller') || stage.contains('macoll');
    final isElongation =
        stage.contains('elong') ||
        stage.contains('encañ') ||
        stage.contains('encane');
    final isBooting = stage.contains('boot') || stage.contains('embuch');
    final isHeading = stage.contains('head') || stage.contains('espig');
    final isFlowering =
        stage.contains('flower') ||
        stage.contains('flor') ||
        stage.contains('antes');
    final isGrainFill = stage.contains('grain') || stage.contains('llenado');
    final isLate = _isLateStage(stage);

    final isPeakN = isTillering || isElongation || isBooting;
    final isProteinWindow = isHeading || isFlowering;
    final isReproductive = isProteinWindow || isGrainFill;
    final bridge = _formatSoilBridgeText(deficitPpm);

    if (isLate) {
      return const NutrientDoseGuide(
        doseGuideEs:
            'El ciclo del trigo ya cerró. Usa esta lectura para planear pre-siembra y no para perseguir una corrección tardía.',
        fertilizerEquivalentEs:
            'En madurez o cosecha, el retorno de una aplicación suele ser muy bajo.',
      );
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        final eqUrea = _formatCommercialDoseText(
          deficitPpm,
          _leyUrea,
          'Urea (46-0-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Nitrógeno puro',
          scale,
        );

        if (isEarly) {
          return NutrientDoseGuide(
            doseGuideEs: isForage
                ? 'Arranque moderado en trigo forrajero: aplica $puroText sin cargar toda la siembra. Guarda margen para macollamiento.'
                : 'Arranque moderado: aplica $puroText sin cargar toda la siembra. En trigo conviene guardar la mayor parte del N para macollamiento.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a aplicar $eqUrea. El trigo aprovecha mejor el N cuando se fracciona.',
              bridge,
            ),
          );
        }

        if (isPeakN) {
          return NutrientDoseGuide(
            doseGuideEs: isForage
                ? 'Ventana fuerte de N en trigo forrajero: aplica $puroText. Aquí se amarra el empuje vegetativo y la producción de forraje.'
                : 'Ventana fuerte de N en trigo: aplica $puroText. Aquí se definen macollos, espigas y gran parte del potencial de rendimiento.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a aplicar $eqUrea. En trigo, el N conviene fraccionarlo: arrancador moderado y grueso en macollamiento/encañe.',
              bridge,
            ),
          );
        }

        if (isProteinWindow) {
          return NutrientDoseGuide(
            doseGuideEs: isForage
                ? 'Hay déficit de N, pero el cultivo ya va avanzado para corte. Corrige solo con criterio agronómico.'
                : 'Hay déficit de N, pero cerca de espigamiento/antesis el retorno va más a proteína y calidad que a levantar mucho rendimiento.',
            fertilizerEquivalentEs: _joinExtra(
              'Como referencia, eso equivale a $eqUrea. Úsalo con criterio para no empujar proteína o acame de forma innecesaria.',
              bridge,
            ),
          );
        }

        if (isReproductive) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Hay déficit de N, pero el trigo ya va en fase avanzada. Corrige con prudencia; no conviene perseguir N tardío como si valiera lo mismo que en macollaje.',
            fertilizerEquivalentEs: _joinExtra(
              'Como referencia, eso equivale a $eqUrea. Usa la lectura también para planear mejor la base del siguiente ciclo.',
              bridge,
            ),
          );
        }

        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para sostener el desarrollo del trigo sin quedarte corto antes de la etapa fuerte.',
          fertilizerEquivalentEs: _joinExtra(
            'Equivale a aplicar $eqUrea. Conviene repartir el N en lugar de cargarlo todo de una sola vez.',
            bridge,
          ),
        );

      case AgroMetricKey.p:
        final eqDap = _formatCommercialDoseText(
          deficitPpm,
          _leyDap,
          'DAP (18-46-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Fósforo (P₂O₅) puro',
          scale,
        );

        if (isEarly || isTillering) {
          return NutrientDoseGuide(
            doseGuideEs:
                'El fósforo pesa fuerte al arranque del trigo. Aplica $puroText desde siembra o muy temprano para raíz, implantación y macollaje parejo.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a aplicar $eqDap. En trigo, el P rinde mejor cuando se coloca cerca de la línea y no cuando se persigue tarde.',
              bridge,
            ),
          );
        }

        return NutrientDoseGuide(
          doseGuideEs:
              'La lectura sugiere déficit de P, pero fuera de la etapa temprana la corrección pierde eficiencia. Tómalo como referencia y fortalece la base del siguiente ciclo.',
          fertilizerEquivalentEs: _joinExtra(
            'Como referencia práctica, equivale a $eqDap. Si la aplicación va al voleo, suele requerir más criterio que una buena colocación de arranque.',
            bridge,
          ),
        );

      case AgroMetricKey.k:
        final eqMop = _formatCommercialDoseText(
          deficitPpm,
          _leyMop,
          'KCl (0-0-60)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Potasio (K₂O) puro',
          scale,
        );

        if (isProteinWindow || isGrainFill) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Si el suelo realmente viene corto, aplica $puroText para sostener balance, firmeza de tallo y llenado. En trigo, el K ayuda más como nutriente de sostén que como protagonista universal.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a aplicar $eqMop.',
              bridge,
            ),
          );
        }

        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para mantener disponibilidad de K y sostener balance del cultivo, sobre todo si el suelo viene ligero o justo de reservas.',
          fertilizerEquivalentEs: _joinExtra(
            'Equivale a aplicar $eqMop. En trigo, el K se corrige con más criterio que rutina.',
            bridge,
          ),
        );

      default:
        return const NutrientDoseGuide(doseGuideEs: 'Falta nutriente.');
    }
  }

  static NutrientDoseGuide _oatGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    double deficitPpm,
    String? scale,
  ) {
    final stage = (stageKey ?? '').toLowerCase();
    final isEarly = _isEarlyStage(stage);
    final isTillering = stage.contains('tiller') || stage.contains('macoll');
    final isElongation = stage.contains('elong');
    final isBooting = stage.contains('boot') || stage.contains('embuch');
    final isHeading = stage.contains('head') || stage.contains('espig');
    final isFlowering = stage.contains('flower') || stage.contains('flor');
    final isGrainFill = stage.contains('grain') || stage.contains('llenado');
    final isLate = _isLateStage(stage);

    final isPeakN = isTillering || isElongation || isBooting;
    final isReproductive = isHeading || isFlowering || isGrainFill;
    final bridge = _formatSoilBridgeText(deficitPpm);

    if (isLate) {
      return const NutrientDoseGuide(
        doseGuideEs:
            'La avena ya cerró el ciclo. Usa esta lectura para ajustar la base del próximo ciclo, no para perseguir una corrección tardía.',
        fertilizerEquivalentEs:
            'En madurez o cosecha, el retorno de una aplicación es muy bajo.',
      );
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        final eqUrea = _formatCommercialDoseText(
          deficitPpm,
          _leyUrea,
          'Urea (46-0-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Nitrógeno puro',
          scale,
        );

        if (isPeakN) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Ventana fuerte de N en avena: aplica $puroText. Aquí conviene sostener el empuje vegetativo y el macollamiento.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a aplicar $eqUrea. En avena, el N conviene fraccionarlo: una parte al arranque y otra en macollamiento.',
              bridge,
            ),
          );
        }

        if (isEarly) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arranque moderado: aplica $puroText sin sobrecargar la etapa temprana. En avena, primero manda el establecimiento.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a aplicar $eqUrea. Usa N con prudencia y deja margen para el macollamiento.',
              bridge,
            ),
          );
        }

        if (isReproductive) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Hay déficit de N, pero la avena ya va avanzada. Corrige solo con criterio; no conviene perseguir N tardío solo por alcanzar un número.',
            fertilizerEquivalentEs: _joinExtra(
              'Como referencia, eso equivale a $eqUrea. Usa la lectura también para planear mejor la base del siguiente ciclo.',
              bridge,
            ),
          );
        }

        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para sostener el desarrollo de la avena sin quedarte corto antes de la etapa fuerte.',
          fertilizerEquivalentEs: _joinExtra(
            'Equivale a aplicar $eqUrea. Conviene repartir el N en lugar de cargarlo todo de una sola vez.',
            bridge,
          ),
        );

      case AgroMetricKey.p:
        final eqDap = _formatCommercialDoseText(
          deficitPpm,
          _leyDap,
          'DAP (18-46-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Fósforo (P₂O₅) puro',
          scale,
        );

        if (isEarly) {
          return NutrientDoseGuide(
            doseGuideEs:
                'El fósforo pesa fuerte al arranque. Aplica $puroText desde inicio para raíz, establecimiento y salida pareja.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a aplicar $eqDap. En avena, el P debe estar disponible desde la siembra.',
              bridge,
            ),
          );
        }

        return NutrientDoseGuide(
          doseGuideEs:
              'La lectura sugiere déficit de P, pero fuera de la etapa temprana la corrección pierde eficiencia. Usa esta referencia con criterio.',
          fertilizerEquivalentEs: _joinExtra(
            'Como referencia práctica, equivale a $eqDap. Si la etapa ya va avanzada, conviene reforzar la base del siguiente ciclo.',
            bridge,
          ),
        );

      case AgroMetricKey.k:
        final eqMop = _formatCommercialDoseText(
          deficitPpm,
          _leyMop,
          'KCl (0-0-60)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Potasio (K₂O) puro',
          scale,
        );

        if (isHeading || isFlowering || isGrainFill) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Aplica $puroText para sostener balance, firmeza y llenado. En esta fase el K gana protagonismo en avena.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a aplicar $eqMop.',
              bridge,
            ),
          );
        }

        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para mantener disponibilidad de K desde etapas tempranas y sostener el balance del cultivo.',
          fertilizerEquivalentEs: _joinExtra(
            'Equivale a aplicar $eqMop. El K acompaña estabilidad, vigor y respuesta del cultivo.',
            bridge,
          ),
        );

      default:
        return const NutrientDoseGuide(doseGuideEs: 'Falta nutriente.');
    }
  }

  // ==========================================
  // TOMATE
  // ==========================================
  // Leyes fertilizante adicionales usadas en tomate:
  //   MAP  (11-52-0):        P₂O₅ = 0.52
  //   Nitrato de potasio (13-0-46): K₂O = 0.46
  //
  // Racional agronómico:
  // - N fraccionado en fertirriego (nunca pulsos altos en flor/cuajado).
  // - P starter post-trasplante; MAP preferido sobre DAP por pH ácido leve.
  // - K dominante en llenado; preferir nitrato de K en reproductivo
  //   (aporte sinérgico de N + K, y mejor balance con Ca frente a KCl).
  static NutrientDoseGuide _tomatoGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    double deficitPpm,
    String? scale,
  ) {
    final stage = (stageKey ?? '').toLowerCase();
    final isGerm = stage.contains('germin');
    final isEstablishment = stage.contains('establec');
    final isVeg = stage.contains('vegetativo');
    final isFlowering = stage.contains('floracion') || stage.contains('flor');
    final isFruitSet = stage.contains('cuajado');
    final isFilling = stage.contains('llenado');
    final isHarvest = stage.contains('progresiv');
    final isLate = _isLateStage(stage);
    final isReproductive = isFlowering || isFruitSet || isFilling || isHarvest;
    final bridge = _formatSoilBridgeText(deficitPpm);

    if (isLate) {
      return const NutrientDoseGuide(
        doseGuideEs:
            'El ciclo del tomate ya está cerrando. Guarda esta lectura para ajustar el arrancador del próximo trasplante.',
        fertilizerEquivalentEs:
            'A estas alturas corregir ya no paga: el valor está en planear mejor el siguiente ciclo.',
      );
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        final eqUrea = _formatCommercialDoseText(
          deficitPpm,
          _leyUrea,
          'Urea (46-0-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Nitrógeno puro',
          scale,
        );
        if (isFlowering || isFruitSet) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Aplica $puroText REPARTIDO en el riego (3 a 4 veces en la semana). Evita dosis altas de un solo golpe: te tumban la flor.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqUrea repartido durante la semana.',
              bridge,
            ),
          );
        }
        if (isGerm || isEstablishment) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arranque moderado: aplica $puroText para acompañar el fósforo inicial sin disparar follaje.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqUrea.',
              bridge,
            ),
          );
        }
        if (isFilling || isHarvest) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Apoyo MÍNIMO de nitrógeno en llenado/cosecha: $puroText solo si la lectura lo justifica. Aquí lo que manda es el potasio.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqUrea; a estas alturas el nitrógeno rinde poco.',
              bridge,
            ),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText repartido en el riego (varias veces, no de un solo jalón). El tomate no aguanta dosis altas de nitrógeno.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
        );

      case AgroMetricKey.p:
        final eqMap = _formatCommercialDoseText(
          deficitPpm,
          0.52,
          'MAP (11-52-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Fósforo puro',
          scale,
        );
        if (isEstablishment || isGerm) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arrancador de fósforo después del trasplante: aplica $puroText al pie de la planta (empapado al suelo o directo a la raíz) para que la planta agarre.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqMap (conviene usar fosfato monoamónico en lugar de diamónico porque cuida mejor el pH).',
              bridge,
            ),
          );
        }
        if (isReproductive) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Fósforo en flor y fruto: aplica $puroText como corrección de base. La respuesta será moderada.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqMap.',
              bridge,
            ),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText como base de fósforo. En tomate la respuesta fuerte del fósforo es al inicio, después del trasplante.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqMap.', bridge),
        );

      case AgroMetricKey.k:
        final eqMop = _formatCommercialDoseText(
          deficitPpm,
          _leyMop,
          'KCl / MOP',
          scale,
        );
        final eqKnit = _formatCommercialDoseText(
          deficitPpm,
          0.46,
          'Nitrato de K (13-0-46)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Potasio puro',
          scale,
        );
        if (isFilling || isHarvest) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Etapa de mucho potasio: aplica $puroText metiéndolo POCO A POCO en el riego. Nada de jalones fuertes: detonan el rajado del fruto.',
            fertilizerEquivalentEs: _joinExtra(
              'Conviene $eqKnit antes que KCl; si el suelo es salino, usa sulfato de potasio. También equivale a $eqMop.',
              bridge,
            ),
          );
        }
        if (isFlowering || isFruitSet) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Potasio en flor/cuajado: aplica $puroText repartido en el riego, manteniendo la humedad del suelo PAREJA, para que el potasio no le compita al calcio y no salga pudrición en la punta del fruto.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqKnit (el nitrato de potasio es lo más recomendado aquí). Alternativa: $eqMop.',
              bridge,
            ),
          );
        }
        if (isVeg) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Refuerza reservas de potasio con $puroText antes de que llegue la demanda fuerte de floración.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqMop.',
              bridge,
            ),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs: 'Aplica $puroText preparando reservas para la demanda fuerte del llenado.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqMop.', bridge),
        );

      default:
        return const NutrientDoseGuide(doseGuideEs: 'Falta nutriente.');
    }
  }

  // ==========================================
  // PEPINO
  // ==========================================
  // Racional agronómico base:
  // - P pesa fuerte al arranque y vuelve a pesar en floración.
  // - N sube en vegetativo, pero en flor/cuajado se modera para no tirar flor.
  // - K es el cuello real desde floración, y domina cuajado, llenado y cosecha.
  // - En cucurbitáceas la estabilidad hídrica importa tanto como la dosis:
  //   un "jalón" de sales o de seca pega rápido en deformidad y amargor.
  static NutrientDoseGuide _cucumberGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    double deficitPpm,
    String? scale,
  ) {
    final stage = (stageKey ?? '').toLowerCase();
    final isGerm = stage.contains('germin');
    final isEstablishment = stage.contains('establec');
    final isVeg = stage.contains('vegetativo') || stage.contains('vegetative');
    final isFlowering = stage.contains('floracion') || stage.contains('flor');
    final isFruitSet =
        stage.contains('cuajado') ||
        stage.contains('fruitset') ||
        stage.contains('amarre');
    final isFilling = stage.contains('llenado') || stage.contains('fill');
    final isHarvest =
        stage.contains('progresiv') || stage.contains('harvest');
    final isLate = _isLateStage(stage);
    final isReproductive =
        isFlowering || isFruitSet || isFilling || isHarvest;
    final bridge = _formatSoilBridgeText(deficitPpm);

    if (isLate) {
      return const NutrientDoseGuide(
        doseGuideEs:
            'El ciclo del pepino ya va de salida. Usa esta lectura para corregir la base del siguiente ciclo, no para perseguir una respuesta tardía.',
        fertilizerEquivalentEs:
            'En fin de ciclo el valor está más en aprender del suelo que en meter una corrección grande.',
      );
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        final eqUrea = _formatCommercialDoseText(
          deficitPpm,
          _leyUrea,
          'Urea (46-0-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Nitrógeno puro',
          scale,
        );
        if (isFlowering || isFruitSet) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Aplica $puroText FRACCIONADO. En flor y cuajado el pepino no quiere jalones altos de nitrógeno porque se vegeta y aborta flor.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqUrea, mejor repartido en varios riegos o eventos cortos.',
              bridge,
            ),
          );
        }
        if (isGerm || isEstablishment) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arranque moderado de nitrógeno: aplica $puroText sin excederte. Aquí primero manda el fósforo y que la raíz agarre.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqUrea.',
              bridge,
            ),
          );
        }
        if (isFilling || isHarvest) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Apoyo moderado de nitrógeno: $puroText solo para sostener guía y follaje productivo. En esta ventana manda mucho más el potasio.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqUrea; evita perseguir N como si fuera el cuello principal.',
              bridge,
            ),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText con criterio para sostener el vegetativo del pepino sin disparar exceso.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
        );

      case AgroMetricKey.p:
        final eqMap = _formatCommercialDoseText(
          deficitPpm,
          0.52,
          'MAP (11-52-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Fósforo puro',
          scale,
        );
        if (isGerm || isEstablishment) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arrancador de fósforo: aplica $puroText cerca de la zona radical para que la plántula agarre y no se quede frenada.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqMap. En pepino el P temprano sí se siente.',
              bridge,
            ),
          );
        }
        if (isFlowering) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Fósforo de sostén en floración: aplica $puroText si la lectura está corta. Aquí acompaña energía reproductiva, pero ya no rinde como al arranque.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqMap.',
              bridge,
            ),
          );
        }
        if (isReproductive) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Usa $puroText como corrección de base, no como rescate. En pepino el fósforo pesa más al inicio y vuelve a pesar en floración.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqMap.',
              bridge,
            ),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para reforzar el arranque y la base fisiológica del cultivo.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqMap.', bridge),
        );

      case AgroMetricKey.k:
        final eqMop = _formatCommercialDoseText(
          deficitPpm,
          _leyMop,
          'KCl / MOP',
          scale,
        );
        final eqKnit = _formatCommercialDoseText(
          deficitPpm,
          0.46,
          'Nitrato de K (13-0-46)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Potasio puro',
          scale,
        );
        if (isFlowering || isFruitSet) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Sube el potasio ya: aplica $puroText repartido en el riego con humedad pareja. En pepino, cuajado flojo y deformidad arrancan cuando K cae aquí.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqKnit; si el suelo viene salino, considera una fuente más amable que KCl. Referencia alternativa: $eqMop.',
              bridge,
            ),
          );
        }
        if (isFilling || isHarvest) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Ventana fuerte de potasio: aplica $puroText POCO A POCO en el riego. Nada de cargas bruscas: en pepino disparan amargor, deformidad y estrés osmótico.',
            fertilizerEquivalentEs: _joinExtra(
              'Conviene $eqKnit o, si hace falta bajar cloruros, una fuente de sulfato de potasio. También equivale a $eqMop.',
              bridge,
            ),
          );
        }
        if (isVeg) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Refuerza reservas de potasio con $puroText antes de entrar a floración y cuajado con el tanque vacío.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqMop.',
              bridge,
            ),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText preparando la demanda fuerte de potasio del pepino.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqMop.', bridge),
        );

      default:
        return const NutrientDoseGuide(doseGuideEs: 'Falta nutriente.');
    }
  }

  // ==========================================
  // CHILE
  // ==========================================
  // Racional BIO-G:
  // - CH-GEN usa un plan conservador y migrable.
  // - N sube en vegetativo, pero floracion/cuajado no toleran jalones altos.
  // - P pesa en raiz, establecimiento y soporte de floracion.
  // - K y Ca dominan desde amarre, llenado y cosecha progresiva.
  static NutrientDoseGuide _chiliGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    double deficitPpm,
    String? scale, {
    String? profileId,
    String? varietyId,
    String? varietyAlias,
    String? calendarId,
  }) {
    final stage = (stageKey ?? '').toLowerCase();
    final modifier = resolveChiliNutritionModifier(
      profileId: profileId,
      varietyId: varietyId,
      alias: varietyAlias,
      calendarId: calendarId ?? scale,
    );
    final isGerm = stage.contains('germin');
    final isEstablishment =
        stage.contains('establec') || stage.contains('emerg');
    final isVeg = stage.contains('vegetativo') || stage.contains('vegetative');
    final isFlowering = stage.contains('floracion') || stage.contains('flor');
    final isFruitSet =
        stage.contains('cuajado') ||
        stage.contains('amarre') ||
        stage.contains('fruitset');
    final isFilling = stage.contains('llenado') || stage.contains('fill');
    final isHarvest = stage.contains('progresiv') || stage.contains('harvest');
    final isLate = _isLateStage(stage);
    final isReproductive =
        isFlowering || isFruitSet || isFilling || isHarvest;
    final bridge = _joinExtra(
      _formatSoilBridgeText(deficitPpm),
      modifier.guideCaution(nutrient, stageKey),
    );

    if (isLate) {
      return NutrientDoseGuide(
        doseGuideEs:
            'El ciclo del chile ya esta cerrando. Guarda esta lectura para ajustar el plan del siguiente ciclo.',
        fertilizerEquivalentEs: _joinExtra(
          'En senescencia conviene aprender del suelo, no forzar una correccion tardia.',
          modifier.guideCaution(nutrient, stageKey),
        ),
      );
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        final eqUrea = _formatCommercialDoseText(
          deficitPpm,
          _leyUrea,
          'Urea (46-0-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Nitrogeno puro',
          scale,
        );
        if (isFlowering || isFruitSet) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Aplica $puroText FRACCIONADO. En floracion y amarre, el chile no debe recibir jalones altos de N porque tira flor y cuaja mal.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqUrea, repartido en varios riegos o eventos cortos.',
              bridge,
            ),
          );
        }
        if (isFilling || isHarvest) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Apoyo moderado de N: $puroText solo si la lectura lo justifica. En llenado y cosecha manda mucho mas el potasio.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqUrea; evita perseguir follaje cuando el fruto ya esta demandando K y Ca.',
              bridge,
            ),
          );
        }
        if (isGerm || isEstablishment) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arranque moderado de N: aplica $puroText sin excederte; primero importan raiz, P y humedad estable.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText con criterio para sostener vegetativo sin llegar a floracion con exceso de follaje.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
        );

      case AgroMetricKey.p:
        final eqMap = _formatCommercialDoseText(
          deficitPpm,
          0.52,
          'MAP (11-52-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Fosforo puro',
          scale,
        );
        if (isGerm || isEstablishment) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arrancador de fosforo: aplica $puroText cerca de la zona radical para que la planta agarre y no retrase floracion.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqMap. En chile el P temprano si se siente.',
              bridge,
            ),
          );
        }
        if (isFlowering) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Fosforo de sosten en floracion: aplica $puroText si la lectura esta corta, como soporte de energia reproductiva.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqMap.', bridge),
          );
        }
        if (isReproductive) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Usa $puroText como correccion de base, no como rescate. La respuesta del P baja despues del establecimiento.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqMap.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para reforzar raiz y base fisiologica antes de la ventana reproductiva.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqMap.', bridge),
        );

      case AgroMetricKey.k:
        final eqMop = _formatCommercialDoseText(
          deficitPpm,
          _leyMop,
          'KCl / MOP',
          scale,
        );
        final eqKnit = _formatCommercialDoseText(
          deficitPpm,
          0.46,
          'Nitrato de K (13-0-46)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Potasio puro',
          scale,
        );
        if (isFlowering || isFruitSet) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Sube K con cuidado: aplica $puroText repartido en el riego y con humedad pareja. En chile, flor y amarre son la ventana cara de fallar.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqKnit; si el suelo viene salino, considera una fuente mas amable que KCl. Referencia alternativa: $eqMop.',
              bridge,
            ),
          );
        }
        if (isFilling || isHarvest) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Ventana fuerte de K: aplica $puroText poco a poco en el riego. Tambien vigila Ca para firmeza y calidad de fruto.',
            fertilizerEquivalentEs: _joinExtra(
              'Conviene $eqKnit o sulfato de potasio si hace falta bajar cloruros. Tambien equivale a $eqMop.',
              bridge,
            ),
          );
        }
        if (isVeg) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Refuerza reservas de potasio con $puroText antes de floracion y cuajado.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqMop.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText preparando la demanda fuerte de potasio del chile.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqMop.', bridge),
        );

      default:
        return const NutrientDoseGuide(doseGuideEs: 'Falta nutriente.');
    }
  }

  // ==========================================
  // BERENJENA
  // ==========================================
  // Racional BIO-G:
  // - BE-GEN usa plan conservador y migrable.
  // - P pesa en establecimiento/raiz y vuelve como soporte de floracion.
  // - N sube en vegetativo, pero debe moderarse desde floracion.
  // - K domina cuajado, llenado y cosecha; Ca/Mg y agua pareja sostienen
  //   firmeza y calidad visual.
  static NutrientDoseGuide _eggplantGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    double deficitPpm,
    String? scale, {
    String? profileId,
    String? varietyId,
    String? varietyAlias,
    String? calendarId,
  }) {
    final stage = (stageKey ?? '').toLowerCase();
    final modifier = resolveEggplantNutritionModifier(
      profileId: profileId,
      varietyId: varietyId,
      alias: varietyAlias,
      calendarId: calendarId ?? scale,
    );
    final isGerm = stage.contains('germin');
    final isEstablishment =
        stage.contains('establec') || stage.contains('emerg');
    final isVeg = stage.contains('vegetativo') || stage.contains('vegetative');
    final isFlowering = stage.contains('floracion') || stage.contains('flor');
    final isFruitSet =
        stage.contains('cuajado') ||
        stage.contains('amarre') ||
        stage.contains('fruitset');
    final isFilling = stage.contains('llenado') || stage.contains('fill');
    final isHarvest = stage.contains('progresiv') || stage.contains('harvest');
    final isLate = _isLateStage(stage);
    final isReproductive =
        isFlowering || isFruitSet || isFilling || isHarvest;
    final bridge = _joinExtra(
      _formatSoilBridgeText(deficitPpm),
      modifier.guideCaution(nutrient, stageKey),
    );

    if (isLate) {
      return NutrientDoseGuide(
        doseGuideEs:
            'El ciclo de berenjena ya esta cerrando. Guarda esta lectura para ajustar la base del siguiente ciclo.',
        fertilizerEquivalentEs: _joinExtra(
          'En senescencia conviene aprender del suelo, no forzar una correccion tardia.',
          modifier.guideCaution(nutrient, stageKey),
        ),
      );
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        final eqUrea = _formatCommercialDoseText(
          deficitPpm,
          _leyUrea,
          'Urea (46-0-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Nitrogeno puro',
          scale,
        );
        if (isFlowering || isFruitSet) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Aplica $puroText FRACCIONADO. En floracion y cuajado, la berenjena necesita equilibrio: mucho N vegeta la planta y baja el amarre.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqUrea, repartido en varios riegos o eventos cortos.',
              bridge,
            ),
          );
        }
        if (isFilling || isHarvest) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Apoyo moderado de N: $puroText solo si la lectura lo justifica. En llenado y cosecha mandan mas K, Ca/Mg y humedad estable.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqUrea; evita perseguir follaje cuando el fruto ya exige calidad.',
              bridge,
            ),
          );
        }
        if (isGerm || isEstablishment) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arranque moderado de N: aplica $puroText sin excederte; primero importan raiz, P, baja salinidad y pegue.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para sostener vegetativo, cuidando no llegar a floracion con exceso de follaje.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
        );

      case AgroMetricKey.p:
        final eqMap = _formatCommercialDoseText(
          deficitPpm,
          0.52,
          'MAP (11-52-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Fosforo puro',
          scale,
        );
        if (isGerm || isEstablishment) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arrancador de fosforo: aplica $puroText cerca de la zona radical para que el trasplante agarre y no retrase floracion.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqMap. En berenjena el P temprano si se siente.',
              bridge,
            ),
          );
        }
        if (isFlowering) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Fosforo de sosten en floracion: aplica $puroText si la lectura esta corta, como soporte de energia reproductiva.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqMap.', bridge),
          );
        }
        if (isReproductive) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Usa $puroText como correccion de base, no como rescate. La respuesta del P baja despues del establecimiento.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqMap.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para reforzar raiz y base fisiologica antes de floracion.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqMap.', bridge),
        );

      case AgroMetricKey.k:
        final eqMop = _formatCommercialDoseText(
          deficitPpm,
          _leyMop,
          'KCl / MOP',
          scale,
        );
        final eqKnit = _formatCommercialDoseText(
          deficitPpm,
          0.46,
          'Nitrato de K (13-0-46)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Potasio puro',
          scale,
        );
        if (isFlowering || isFruitSet) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Sube K con cuidado: aplica $puroText repartido en el riego y con humedad pareja. En berenjena, flor y amarre fallan rapido con deficit hidrico o CE alta.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqKnit; si el suelo viene salino, considera una fuente mas amable que KCl. Referencia alternativa: $eqMop.',
              bridge,
            ),
          );
        }
        if (isFilling || isHarvest) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Ventana fuerte de K: aplica $puroText poco a poco en el riego. Vigila Ca/Mg para firmeza, brillo y vida de anaquel.',
            fertilizerEquivalentEs: _joinExtra(
              'Conviene $eqKnit o sulfato de potasio si hace falta bajar cloruros. Tambien equivale a $eqMop.',
              bridge,
            ),
          );
        }
        if (isVeg) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Refuerza reservas de potasio con $puroText antes de floracion y cuajado.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqMop.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText preparando la demanda fuerte de potasio de la berenjena.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqMop.', bridge),
        );

      default:
        return const NutrientDoseGuide(doseGuideEs: 'Falta nutriente.');
    }
  }

  // ==========================================
  // CALABAZA
  // ==========================================
  // Racional BIO-G v1 (Guia Tecnica de Fertilizacion v2):
  // - CA-GEN: plan conservador y migrable; si faltan datos, pedir
  //   analisis antes de subir dosis exacta.
  // - P pesa en establecimiento/raiz; rara vez es rescate tarde.
  // - N moderado en vegetativo; bajar en floracion para no perder
  //   relacion macho/hembra ni cuajado.
  // - K manda desde cuajado, llenado y cosecha; en CA-07/pipian, la
  //   demanda de K sostiene peso de semilla; Mg/S quedan como contexto.
  // - Calabaza tropical (UPR) acepta pH 5.5+; rangos generales
  //   6.0-7.2.
  static NutrientDoseGuide _squashGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    double deficitPpm,
    String? scale, {
    String? profileId,
    String? varietyId,
    String? varietyAlias,
    String? calendarId,
  }) {
    final stage = (stageKey ?? '').toLowerCase();
    final modifier = resolveSquashNutritionModifier(
      profileId: profileId,
      varietyId: varietyId,
      alias: varietyAlias,
      calendarId: calendarId ?? scale,
    );
    final isGerm = stage.contains('germin');
    final isEstablishment =
        stage.contains('establec') || stage.contains('emerg');
    final isVeg = stage.contains('vegetativo') || stage.contains('vegetative');
    final isFlowering = stage.contains('floracion') || stage.contains('flor');
    final isFruitSet = stage.contains('cuajado') ||
        stage.contains('amarre') ||
        stage.contains('fruitset') ||
        stage.contains('poliniz');
    final isFilling = stage.contains('llenado') || stage.contains('fill');
    final isHarvest = stage.contains('progresiv') || stage.contains('harvest');
    final isLate = _isLateStage(stage);
    final isReproductive =
        isFlowering || isFruitSet || isFilling || isHarvest;
    final isSeedFocused = modifier.isSeedFocused;
    final isMature = modifier.isMatureFruit;

    final bridge = _joinExtra(
      _formatSoilBridgeText(deficitPpm),
      modifier.guideCaution(nutrient, stageKey),
    );

    if (isLate) {
      return NutrientDoseGuide(
        doseGuideEs:
            'El ciclo de calabaza ya esta cerrando. Guarda esta lectura para ajustar la base del siguiente ciclo.',
        fertilizerEquivalentEs: _joinExtra(
          'En senescencia, conviene aprender del suelo, no forzar correccion tardia.',
          modifier.guideCaution(nutrient, stageKey),
        ),
      );
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        final eqUrea = _formatCommercialDoseText(
          deficitPpm,
          _leyUrea,
          'Urea (46-0-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Nitrogeno puro',
          scale,
        );
        if (isFlowering || isFruitSet) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Aplica $puroText FRACCIONADO. En floracion y cuajado, la calabaza necesita equilibrio: mucho N puede tirar flor o fallar el amarre.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqUrea, repartido en varios riegos cortos.',
              bridge,
            ),
          );
        }
        if (isFilling || isHarvest) {
          if (isMature) {
            return NutrientDoseGuide(
              doseGuideEs:
                  'En fruto maduro conviene bajar N para no retrasar madurez ni endurecimiento de cascara. Si la planta lo necesita, $puroText fraccionado y suave.',
              fertilizerEquivalentEs:
                  _joinExtra('Equivale a $eqUrea.', bridge),
            );
          }
          if (isSeedFocused) {
            return NutrientDoseGuide(
              doseGuideEs:
                  'CA-07 pipian: N alto al final castiga peso de semilla. Si la lectura lo justifica, $puroText muy moderado.',
              fertilizerEquivalentEs:
                  _joinExtra('Equivale a $eqUrea.', bridge),
            );
          }
          return NutrientDoseGuide(
            doseGuideEs:
                'Apoyo moderado de N: $puroText solo si la lectura lo justifica. En llenado y cosecha mandan mas K, agua estable y sanidad foliar.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqUrea; evita perseguir follaje cuando el fruto ya exige calidad.',
              bridge,
            ),
          );
        }
        if (isGerm || isEstablishment) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arranque moderado de N: aplica $puroText sin excederte. Primero importan suelo calido, raiz, P y baja salinidad.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para sostener vegetativo, sin llegar a floracion con exceso de follaje.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqUrea.', bridge),
        );

      case AgroMetricKey.p:
        final eqMap = _formatCommercialDoseText(
          deficitPpm,
          0.52,
          'MAP (11-52-0)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Fosforo puro',
          scale,
        );
        if (isGerm || isEstablishment) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Arrancador de fosforo: aplica $puroText cerca de la zona radical para que la plantula agarre y no retrase floracion.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqMap. En calabaza el P temprano si se siente.',
              bridge,
            ),
          );
        }
        if (isFlowering) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Fosforo de sosten en floracion: aplica $puroText si la lectura esta corta, como soporte de energia reproductiva.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqMap.', bridge),
          );
        }
        if (isReproductive) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Usa $puroText como correccion de base, no como rescate. La respuesta del P baja despues del establecimiento.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqMap.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText para reforzar raiz y base fisiologica antes de floracion.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqMap.', bridge),
        );

      case AgroMetricKey.k:
        final eqMop = _formatCommercialDoseText(
          deficitPpm,
          _leyMop,
          'KCl / MOP',
          scale,
        );
        final eqKnit = _formatCommercialDoseText(
          deficitPpm,
          0.46,
          'Nitrato de K (13-0-46)',
          scale,
        );
        final puroText = _formatPureDoseText(
          deficitPpm,
          'Potasio puro',
          scale,
        );
        if (isFlowering || isFruitSet) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Sube K con cuidado: aplica $puroText repartido en el riego y con humedad pareja. En calabaza, flor y amarre fallan rapido con deficit hidrico, calor o baja polinizacion.',
            fertilizerEquivalentEs: _joinExtra(
              'Equivale a $eqKnit; si el suelo viene salino, considera una fuente mas amable que KCl. Referencia alternativa: $eqMop.',
              bridge,
            ),
          );
        }
        if (isFilling || isHarvest) {
          if (isSeedFocused) {
            return NutrientDoseGuide(
              doseGuideEs:
                  'CA-07 pipian: K manda llenado de semilla. Aplica $puroText fraccionado y vigila agua estable; Mg/S quedan como contexto de balance.',
              fertilizerEquivalentEs: _joinExtra(
                'Conviene $eqKnit o sulfato de potasio si hace falta bajar cloruros. Tambien equivale a $eqMop.',
                bridge,
              ),
            );
          }
          return NutrientDoseGuide(
            doseGuideEs:
                'Ventana fuerte de K: aplica $puroText poco a poco en el riego. Vigila balance con Ca/Mg y CE para firmeza, color y vida de almacen.',
            fertilizerEquivalentEs: _joinExtra(
              'Conviene $eqKnit o sulfato de potasio si hay sales. Tambien equivale a $eqMop.',
              bridge,
            ),
          );
        }
        if (isVeg) {
          return NutrientDoseGuide(
            doseGuideEs:
                'Refuerza reservas de potasio con $puroText antes de floracion y cuajado.',
            fertilizerEquivalentEs: _joinExtra('Equivale a $eqMop.', bridge),
          );
        }
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica $puroText preparando la demanda fuerte de potasio de la calabaza.',
          fertilizerEquivalentEs: _joinExtra('Equivale a $eqMop.', bridge),
        );

      default:
        return const NutrientDoseGuide(doseGuideEs: 'Falta nutriente.');
    }
  }

  // ==========================================
  // GUÍA LECHUGA — sin dosis cerradas (NPK v1 conservador)
  // ==========================================
  /// A diferencia de los cultivos de fruto y grano, BIO-G v1 NO entrega
  /// dosis en kg/ha para lechuga. El documento de Fertilización v1.1
  /// indica que la app debe recomendar revisión, análisis de suelo/agua
  /// y manejo de mantenimiento con técnico: la lectura es señal de riesgo
  /// y desequilibrio, no una receta cerrada.
  static NutrientDoseGuide _lettuceGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    String? scale, {
    String? profileId,
    String? varietyId,
    String? varietyAlias,
    String? calendarId,
  }) {
    final stage = (stageKey ?? '').toLowerCase();
    final modifier = resolveLettuceNutritionModifier(
      profileId: profileId,
      varietyId: varietyId,
      alias: varietyAlias,
      calendarId: calendarId ?? scale,
    );
    final isHarvest = stage.contains('cosecha') || stage.contains('ventana');
    final isEstablishment = stage.contains('establec') ||
        stage.contains('emerg') ||
        stage.contains('germin');

    String base;
    switch (nutrient) {
      case AgroMetricKey.n:
        base = isHarvest
            ? 'La lectura de nitrogeno viene baja, pero estas cerca de cosecha. BIO-G no recomienda N fuerte tardio en lechuga: prioriza calidad, turgencia y corte oportuno, y valida con tecnico si la hoja pierde vigor.'
            : 'La lectura de nitrogeno viene corta para la etapa. En lechuga BIO-G no fija dosis cerradas: revisa color y crecimiento, apoyate en analisis de suelo y valora mantenimiento fraccionado con tu tecnico. Evita el exceso que ablanda la hoja.';
        break;
      case AgroMetricKey.p:
        base = isEstablishment
            ? 'La lectura de fosforo viene corta justo en el arranque, la ventana clave para la raiz superficial. BIO-G no fija dosis: revisa P de base o starter segun analisis de suelo y criterio tecnico.'
            : 'La lectura de fosforo viene corta. En lechuga el P rinde mas colocado en el establecimiento; revisa pH y analisis de suelo antes de ajustar, sin dosis ciega.';
        break;
      case AgroMetricKey.k:
        base =
            'La lectura de potasio viene corta. El K sostiene turgencia y calidad de hoja; revisa con analisis de suelo y mantenimiento prudente, cuidando no subir la salinidad.';
        break;
      default:
        base =
            'Revisa la nutricion de la lechuga con apoyo de analisis de suelo y criterio tecnico local.';
    }

    return NutrientDoseGuide(
      doseGuideEs: base,
      fertilizerEquivalentEs: modifier.guideCaution(nutrient, stageKey),
    );
  }

  /// Espinaca: la lectura NPK es riesgo/desequilibrio, no receta. BIO-G v1
  /// prioriza suelo, agua, CE y calidad de hoja; no entrega kg/ha cerrados.
  static NutrientDoseGuide _spinachGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    String? scale, {
    String? profileId,
    String? varietyId,
    String? varietyAlias,
    String? calendarId,
  }) {
    final stage = (stageKey ?? '').toLowerCase();
    final modifier = resolveSpinachNutritionModifier(
      profileId: profileId,
      varietyId: varietyId,
      alias: varietyAlias,
      calendarId: calendarId ?? scale,
    );
    final isHarvest = stage.contains('madurez') ||
        stage.contains('cosecha') ||
        stage.contains('ventana');
    final isLate = stage.contains('perdida') ||
        stage.contains('espig') ||
        stage.contains('senesc');
    final isEstablishment = stage.contains('establec') ||
        stage.contains('emerg') ||
        stage.contains('germin');

    String base;
    switch (nutrient) {
      case AgroMetricKey.n:
        if (isLate) {
          base =
              'La lectura de nitrogeno viene baja, pero la espinaca ya esta en perdida de calidad o espigado. BIO-G no recomienda N tardio: cosecha/cierra y registra causa.';
        } else if (isHarvest) {
          base =
              'La lectura de nitrogeno viene baja cerca de corte. En espinaca no conviene empujar N fuerte: prioriza turgencia, sanidad y cosecha oportuna; valida solo si la hoja pierde vigor.';
        } else {
          base =
              'La lectura de nitrogeno viene corta para expansion de hoja. BIO-G no fija dosis cerradas: primero confirma humedad estable, CE y color de hoja; evita exceso que ablanda tejido o sube nitratos.';
        }
        break;
      case AgroMetricKey.p:
        base = isEstablishment
            ? 'La lectura de fosforo viene corta en arranque, la ventana clave para raiz temprana. Revisa P de base o starter segun analisis de suelo y criterio tecnico, sin dosis ciega.'
            : 'La lectura de fosforo viene corta. En espinaca el P rinde mas al establecimiento; revisa pH y analisis de suelo antes de ajustar.';
        break;
      case AgroMetricKey.k:
        base =
            'La lectura de potasio viene corta. El K sostiene turgencia y calidad de hoja; revisa con analisis de suelo y mantenimiento prudente, cuidando no subir salinidad.';
        break;
      default:
        base =
            'Revisa la nutricion de la espinaca con apoyo de analisis de suelo, agua y criterio tecnico local.';
    }

    return NutrientDoseGuide(
      doseGuideEs: base,
      fertilizerEquivalentEs: modifier.guideCaution(nutrient, stageKey),
    );
  }

  /// Cebolla: la lectura NPK es riesgo/desequilibrio, no receta. El organo
  /// objetivo es el bulbo: N temprano con control y detener tarde, P para
  /// arranque/raiz, K para llenado/calidad. El fotoperiodo manda y no se
  /// corrige con fertilizante. BIO-G v1 no entrega kg/ha cerrados.
  static NutrientDoseGuide _onionGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    String? scale, {
    String? profileId,
    String? varietyId,
    String? varietyAlias,
    String? calendarId,
  }) {
    final stage = (stageKey ?? '').toLowerCase();
    final modifier = resolveOnionNutritionModifier(
      profileId: profileId,
      varietyId: varietyId,
      alias: varietyAlias,
      calendarId: calendarId ?? scale,
    );
    final isBulb = stage.contains('llenado') ||
        stage.contains('iniciobulbo') ||
        stage.contains('bulbo') ||
        stage.contains('induccion');
    final isLate = stage.contains('maduracion') ||
        stage.contains('cosecha') ||
        stage.contains('curado') ||
        stage.contains('espig') ||
        stage.contains('senesc');
    final isEstablishment = stage.contains('establec') ||
        stage.contains('emerg') ||
        stage.contains('germin');

    String base;
    switch (nutrient) {
      case AgroMetricKey.n:
        if (isLate) {
          base =
              'La lectura de nitrogeno viene baja, pero la cebolla ya esta en maduracion/cuello o espigado. BIO-G no recomienda N tardio: detener N protege cuello, curado y conservacion.';
        } else if (isBulb) {
          base =
              'La lectura de nitrogeno viene baja en etapa de bulbo. No conviene empujar N fuerte: el exceso engruesa cuello y retrasa madurez. Prioriza agua pareja, K y fotoperiodo correcto; valida solo si la hoja pierde vigor.';
        } else {
          base =
              'La lectura de nitrogeno viene corta para construir hoja (la fabrica del bulbo). BIO-G no fija dosis cerradas: fracciona el N, confirma humedad estable y CE, y evita el exceso que ablanda tejido o sube cuello grueso.';
        }
        break;
      case AgroMetricKey.p:
        base = isEstablishment
            ? 'La lectura de fosforo viene corta en arranque, la ventana clave para raiz superficial. Revisa P de base o starter segun analisis de suelo, sobre todo en suelo frio o alcalino, sin dosis ciega.'
            : 'La lectura de fosforo viene corta. En cebolla el P rinde mas al establecimiento; revisa pH, micorrizas y analisis de suelo antes de ajustar.';
        break;
      case AgroMetricKey.k:
        base =
            'La lectura de potasio viene corta. El K es el nutriente del bulbo: sostiene agua, turgencia, calibre y firmeza. Revisa con analisis de suelo y CE, sin subir salinidad.';
        break;
      default:
        base =
            'Revisa la nutricion de la cebolla con apoyo de analisis de suelo, agua y criterio tecnico local.';
    }

    return NutrientDoseGuide(
      doseGuideEs: base,
      fertilizerEquivalentEs: modifier.guideCaution(nutrient, stageKey),
    );
  }

  /// Ajo: Allium de bulbo propagado por diente. N temprano con control,
  /// P por analisis al arranque, K para diferenciacion/llenado y calidad.
  /// Vernalizacion, salinidad, anoxia, diente-semilla y curado no se corrigen
  /// con fertilizante. BIO-G v1 mantiene NPK como motor activo.
  static NutrientDoseGuide _garlicGuide(
    AgroMetricKey nutrient,
    String? stageKey,
    String? scale, {
    String? profileId,
    String? varietyId,
    String? varietyAlias,
    String? calendarId,
  }) {
    final stage = (stageKey ?? '').toLowerCase();
    final modifier = resolveGarlicNutritionModifier(
      profileId: profileId,
      varietyId: varietyId,
      alias: varietyAlias,
      calendarId: calendarId ?? scale,
    );
    final isEstablishment = stage.contains('plant') ||
        stage.contains('clove') ||
        stage.contains('diente') ||
        stage.contains('emerg') ||
        stage.contains('establec');
    final isVegetative = stage.contains('veget') || stage.contains('foliar');
    final isVernalization = stage.contains('vernal') ||
        stage.contains('frio') ||
        stage.contains('cold');
    final isBulb = stage.contains('diferenci') ||
        stage.contains('llenado') ||
        stage.contains('bulb') ||
        stage.contains('bulbo') ||
        stage.contains('fill');
    final isLate = stage.contains('maduracion') ||
        stage.contains('matur') ||
        stage.contains('cosecha') ||
        stage.contains('harvest') ||
        stage.contains('curado') ||
        stage.contains('curing') ||
        stage.contains('escapo') ||
        stage.contains('canuto') ||
        stage.contains('escobete') ||
        stage.contains('scape') ||
        stage.contains('broom') ||
        stage.contains('senesc');

    String base;
    switch (nutrient) {
      case AgroMetricKey.n:
        if (isLate) {
          base =
              'La lectura de nitrogeno viene baja, pero el ajo ya esta en maduracion/cosecha/curado o evento de escapo. BIO-G no recomienda N tardio: detener N protege maduracion, curado, descarte y almacenamiento.';
        } else if (isVernalization) {
          base =
              'La lectura de nitrogeno viene corta durante vernalizacion. No uses NPK para corregir frio insuficiente: confirma temperatura acumulada, humedad, CE y sanidad antes de tocar el plan.';
        } else if (isBulb) {
          base =
              'La lectura de nitrogeno viene baja en diferenciacion/llenado. Maneja con mucha cautela: N alto tarde favorece exceso de hoja, escobeteado/canutos, mala maduracion, pudriciones y mal curado.';
        } else if (isVegetative) {
          base =
              'La lectura de nitrogeno viene corta en desarrollo foliar. Puede apoyar hoja temprana si se fracciona y se confirma agua/CE; evita llevar N fuerte hacia bulbo.';
        } else {
          base =
              'La lectura de nitrogeno viene corta. Primero confirma diente-semilla sano, raiz, humedad y salinidad; planta joven de ajo no necesita N agresivo.';
        }
        break;
      case AgroMetricKey.p:
        base = isEstablishment
            ? 'La lectura de fosforo viene corta en plantacion/emergencia. Es la ventana clave para raiz del diente; valida con analisis de suelo, pH y humedad antes de aplicar.'
            : 'La lectura de fosforo viene corta. En ajo el P rinde mas al establecimiento; fuera de esa ventana revisa pH/disponibilidad y no lo uses como rescate de frio o bulbo.';
        break;
      case AgroMetricKey.k:
        base = isBulb || isVernalization
            ? 'La lectura de potasio viene corta en diferenciacion/llenado. K apoya firmeza, calibre y calidad de bulbo, pero si CE/salinidad o agua estan mal, no subas fertilizante como primera respuesta.'
            : 'La lectura de potasio viene corta. Prepara el llenado de bulbo con manejo moderado, agua estable y CE baja; el K no compensa anoxia, diente malo ni mala vernalizacion.';
        break;
      default:
        base =
            'Revisa la nutricion del ajo con analisis de suelo, agua, CE, etapa fisiologica y criterio tecnico local.';
    }

    return NutrientDoseGuide(
      doseGuideEs: base,
      fertilizerEquivalentEs: modifier.guideCaution(nutrient, stageKey),
    );
  }

  static NutrientDoseGuide _genericGuide(
    AgroMetricKey nutrient,
    double deficitPpm,
    String? scale,
  ) {
    final bridge = _formatSoilBridgeText(deficitPpm);

    switch (nutrient) {
      case AgroMetricKey.n:
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica ${_formatPureDoseText(deficitPpm, 'Nitrógeno puro', scale)}.',
          fertilizerEquivalentEs: _joinExtra(
            'Equivale a ${_formatCommercialDoseText(deficitPpm, _leyUrea, 'Urea', scale)}.',
            bridge,
          ),
        );
      case AgroMetricKey.p:
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica ${_formatPureDoseText(deficitPpm, 'Fósforo (P₂O₅) puro', scale)}.',
          fertilizerEquivalentEs: _joinExtra(
            'Equivale a ${_formatCommercialDoseText(deficitPpm, _leyDap, 'DAP', scale)}.',
            bridge,
          ),
        );
      case AgroMetricKey.k:
        return NutrientDoseGuide(
          doseGuideEs:
              'Aplica ${_formatPureDoseText(deficitPpm, 'Potasio (K₂O) puro', scale)}.',
          fertilizerEquivalentEs: _joinExtra(
            'Equivale a ${_formatCommercialDoseText(deficitPpm, _leyMop, 'KCl', scale)}.',
            bridge,
          ),
        );
      default:
        return const NutrientDoseGuide(doseGuideEs: 'Aplica fertilizante.');
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================

  static bool _isBarleyMalt(String? profileId) =>
      profileId != null &&
      (profileId.toLowerCase().contains('cb02') ||
          profileId.toLowerCase().contains('malt'));

  static bool _isWheatForage(String? profileId) =>
      profileId != null &&
      (profileId.toLowerCase().contains('tr_for') ||
          profileId.toLowerCase().contains('forraje') ||
          profileId.toLowerCase().contains('forage'));

  static bool _isEarlyStage(String stage) =>
      stage.contains('germin') ||
      stage.contains('emerg') ||
      stage.contains('vegearly') ||
      stage.contains('early');

  static bool _isPeakNitrogenStage(String stage) =>
      stage.contains('vegmid') ||
      stage.contains('vegadvanced') ||
      stage.contains('tass') ||
      stage.contains('elong') ||
      stage.contains('boot');

  static bool _isLateStage(String stage) {
    // Tomate indeterminado: cosecha progresiva es activamente productiva,
    // NO es tardía (sigue cuajando fruto en ramas superiores).
    if (stage.contains('progresiv')) return false;
    return stage.contains('matur') ||
        stage.contains('senesc') ||
        stage.contains('harvest') ||
        stage.contains('cosech') ||
        stage.contains('late') ||
        // Tomate: finCiclo es el cierre real.
        stage.contains('fincic') ||
        stage.contains('fin_cic') ||
        stage.contains('fin cic');
  }
}
