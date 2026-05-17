import 'dart:math' as math;
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/chili_nutrition_modifier.dart';
import 'package:bio_g/core/agro/eggplant_nutrition_modifier.dart';
import 'package:bio_g/core/agro/lettuce_nutrition_modifier.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/squash_nutrition_modifier.dart';
import 'package:bio_g/core/agro/nutrient_target_range_resolver.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';

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

    return _genericGuide(nutrient, deficitPpm, cultivationScaleId);
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
    final scale = (scaleId ?? '').toLowerCase();

    if (scale.contains('maceta') || scale.contains('pot')) {
      final gPuros = (deficitPpm * _masaMacetaKg) / 1000.0;
      return '${gPuros.toStringAsFixed(1)} g de $nutrientName por maceta';
    } else if (scale.contains('planta') ||
        scale.contains('arbol') ||
        scale.contains('árbol')) {
      final gPuros = (deficitPpm * _masaPlantaKg) / 1000.0;
      return '${gPuros.toStringAsFixed(1)} g de $nutrientName por planta';
    } else if (scale.contains('huerto') ||
        scale.contains('cama') ||
        scale.contains('m2') ||
        scale.contains('orchard')) {
      final gM2Puros = _kgHaPuro(deficitPpm) * 0.1;
      return '${gM2Puros.toStringAsFixed(1)} g/m² de $nutrientName';
    } else {
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
    final scale = (scaleId ?? '').toLowerCase();

    if (scale.contains('maceta') || scale.contains('pot')) {
      final gPuros = (deficitPpm * _masaMacetaKg) / 1000.0;
      final gComercial = gPuros / leyFertilizante;
      return '${gComercial.toStringAsFixed(1)} g de $sourceName por maceta';
    } else if (scale.contains('planta') ||
        scale.contains('arbol') ||
        scale.contains('árbol')) {
      final gPuros = (deficitPpm * _masaPlantaKg) / 1000.0;
      final gComercial = gPuros / leyFertilizante;
      return '${gComercial.toStringAsFixed(1)} g de $sourceName por planta';
    } else if (scale.contains('huerto') ||
        scale.contains('cama') ||
        scale.contains('m2') ||
        scale.contains('orchard')) {
      final gM2Comercial = (_kgHaPuro(deficitPpm) * 0.1) / leyFertilizante;
      return '${gM2Comercial.toStringAsFixed(1)} g/m² de $sourceName';
    } else {
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
