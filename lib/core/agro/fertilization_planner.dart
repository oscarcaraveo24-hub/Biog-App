import 'dart:math' as math;
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
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

    final range = switch (nutrient) {
      AgroMetricKey.n => targets.nIndex,
      AgroMetricKey.p => targets.pIndex,
      AgroMetricKey.k => targets.kIndex,
      _ => null,
    };
    if (range == null) return null;

    final cap = NpkCaps.forCropMetric(cropKey: cropKey, metricKey: nutrient);
    final targetMidPpm =
        ((range.optimalMin + range.optimalMax) / 2.0 / 100.0) * cap;

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

  static bool _isLateStage(String stage) =>
      stage.contains('matur') ||
      stage.contains('senesc') ||
      stage.contains('harvest') ||
      stage.contains('cosech') ||
      stage.contains('late');
}
