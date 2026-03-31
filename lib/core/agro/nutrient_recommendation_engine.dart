import 'dart:math' as math;
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/fertilization_planner.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';

class NutrientInterpretationResult {
  const NutrientInterpretationResult({
    required this.nutrient,
    required this.rawPpm,
    required this.rawRatio01,
    required this.priorityScore01,
    required this.stagePressure01,
    required this.contextModifier01,
    required this.trendModifier01,
    required this.label,
    required this.labelEs,
    required this.demandWindowLabel,
    required this.shortRecommendation,
    required this.practicalRecommendation,
    required this.doseGuideEs,
    required this.fertilizerEquivalentEs,
    required this.justification,
    required this.isExcessSide,
  });

  final AgroMetricKey nutrient;
  final double rawPpm;
  final double rawRatio01;
  final double priorityScore01;
  final double stagePressure01;
  final double contextModifier01;
  final double trendModifier01;
  final NutrientPriorityLabel label;
  final String labelEs;
  final String demandWindowLabel;
  final String shortRecommendation;
  final String practicalRecommendation;
  final String? doseGuideEs;
  final String? fertilizerEquivalentEs;
  final String justification;
  final bool isExcessSide;
}

class NutrientRecommendationEngine {
  NutrientRecommendationEngine._();

  static NutrientInterpretationResult interpret({
    required AgroMetricKey nutrient,
    required double rawPpm,
    required String? cropKey,
    required String? stageKey,
    String? profileId,
    StageTargets? targets,
    StageWeights? weights,
    double? ph,
    double? ec,
    double? soilMoisturePct,
    double? trendPct,
  }) {
    assert(
      nutrient == AgroMetricKey.n ||
          nutrient == AgroMetricKey.p ||
          nutrient == AgroMetricKey.k,
      'NutrientRecommendationEngine only accepts N/P/K metrics.',
    );

    final cap = NpkCaps.forCropMetric(cropKey: cropKey, metricKey: nutrient);
    final rawRatio01 = cap <= 0 ? 0.0 : (rawPpm / cap).clamp(0.0, 1.25);

    final stagePressure01 = _resolveStagePressure01(
      nutrient: nutrient,
      targets: targets,
      weights: weights,
    );
    final contextModifier01 = _resolveContextModifier01(
      nutrient: nutrient,
      ph: ph,
      ec: ec,
      soilMoisturePct: soilMoisturePct,
    );
    final trendModifier01 = _resolveTrendModifier01(trendPct);

    final demandWindowLabel = _demandWindowLabel(
      nutrient: nutrient,
      cropKey: cropKey,
      stageKey: stageKey,
      targets: targets,
    );

    final range = switch (nutrient) {
      AgroMetricKey.n => targets?.nIndex,
      AgroMetricKey.p => targets?.pIndex,
      AgroMetricKey.k => targets?.kIndex,
      _ => null,
    };

    final label = _resolveLabel(
      rawPpm: rawPpm,
      cap: cap,
      range: range,
      stagePressure01: stagePressure01,
    );

    final priorityScore01 = _priorityScore01(
      label: label,
      stagePressure01: stagePressure01,
    );

    final doseGuide = FertilizationPlanner.buildGuide(
      nutrient: nutrient,
      label: label,
      rawPpm: rawPpm,
      cropKey: cropKey,
      stageKey: stageKey,
      profileId: profileId,
      targets: targets,
    );

    final practicalBase = _practicalRecommendation(
      nutrient: nutrient,
      label: label,
      cropKey: cropKey,
      stageKey: stageKey,
      trendPct: trendPct,
      stagePressure01: stagePressure01,
      targets: targets,
    );

    final practicalRecommendation = _mergePracticalAndDose(
      base: practicalBase,
      doseGuideEs: doseGuide?.doseGuideEs,
      label: label,
    );

    return NutrientInterpretationResult(
      nutrient: nutrient,
      rawPpm: rawPpm,
      rawRatio01: rawRatio01,
      priorityScore01: priorityScore01,
      stagePressure01: stagePressure01,
      contextModifier01: contextModifier01,
      trendModifier01: trendModifier01,
      label: label,
      labelEs: label.labelEs,
      demandWindowLabel: demandWindowLabel,
      shortRecommendation: _shortRecommendation(
        nutrient: nutrient,
        label: label,
        cropKey: cropKey,
        stageKey: stageKey,
        targets: targets,
      ),
      practicalRecommendation: practicalRecommendation,
      doseGuideEs: doseGuide?.doseGuideEs,
      fertilizerEquivalentEs: doseGuide?.fertilizerEquivalentEs,
      justification: _justification(
        nutrient: nutrient,
        rawPpm: rawPpm,
        targets: targets,
        cropKey: cropKey,
        label: label,
      ),
      isExcessSide:
          label == NutrientPriorityLabel.possibleExcess ||
          label == NutrientPriorityLabel.reviewAccumulation ||
          label == NutrientPriorityLabel.reviewManagement,
    );
  }

  // =========================================================================
  // PRESIÓN FENOLÓGICA (0..1)
  // =========================================================================
  static double _resolveStagePressure01({
    required AgroMetricKey nutrient,
    StageTargets? targets,
    StageWeights? weights,
  }) {
    final AgroRange? range = switch (nutrient) {
      AgroMetricKey.n => targets?.nIndex,
      AgroMetricKey.p => targets?.pIndex,
      AgroMetricKey.k => targets?.kIndex,
      _ => null,
    };

    final targetPriority01 = (targets?.resolvedPriorityFor(nutrient) ?? 0.50)
        .clamp(0.0, 1.0);

    final double rangeMid01 = range == null
        ? 0.50
        : (((range.optimalMin + range.optimalMax) / 2.0) / 100.0).clamp(
            0.0,
            1.0,
          );

    final double weightShare01;
    if (weights == null || weights.nutrientsSum <= 0) {
      weightShare01 = 0.50;
    } else {
      final nutrientWeight = switch (nutrient) {
        AgroMetricKey.n => weights.nutrientN,
        AgroMetricKey.p => weights.nutrientP,
        AgroMetricKey.k => weights.nutrientK,
        _ => 0.0,
      };
      weightShare01 = (nutrientWeight / weights.nutrientsSum).clamp(0.0, 1.0);
    }

    return (targetPriority01 * 0.70 + rangeMid01 * 0.18 + weightShare01 * 0.12)
        .clamp(0.0, 1.0);
  }

  // =========================================================================
  // MODIFICADORES DE CONTEXTO
  // =========================================================================
  static double _resolveContextModifier01({
    required AgroMetricKey nutrient,
    double? ph,
    double? ec,
    double? soilMoisturePct,
  }) {
    double modifier = 0.0;

    if (ph != null) {
      if (ph < 5.8 || ph > 7.2) {
        modifier += nutrient == AgroMetricKey.p ? 0.10 : 0.04;
      }
      if (ph < 5.5 || ph > 7.5) modifier += 0.04;
    }

    if (ec != null && ec > 2.2) {
      modifier += nutrient == AgroMetricKey.k ? 0.03 : 0.05;
    }

    if (soilMoisturePct != null && soilMoisturePct < 28) {
      modifier += nutrient == AgroMetricKey.k ? 0.07 : 0.04;
    }

    return modifier.clamp(0.0, 0.22);
  }

  static double _resolveTrendModifier01(double? trendPct) {
    if (trendPct == null || !trendPct.isFinite) return 0.0;
    if (trendPct <= -20) return 0.10;
    if (trendPct <= -10) return 0.06;
    if (trendPct <= -5) return 0.03;
    return 0.0;
  }

  // =========================================================================
  // ETIQUETA DE PRIORIDAD
  // =========================================================================
  static NutrientPriorityLabel _resolveLabel({
    required double rawPpm,
    required double cap,
    required AgroRange? range,
    required double stagePressure01,
  }) {
    if (range == null) return NutrientPriorityLabel.unknown;

    final targetMin = (range.optimalMin / 100.0) * cap;
    final targetMax = (range.optimalMax / 100.0) * cap;
    final targetMid = (targetMin + targetMax) / 2.0;
    final highMin = (range.highMin / 100.0) * cap;
    final lowMax = (range.lowMax / 100.0) * cap;

    if (rawPpm >= highMin) return NutrientPriorityLabel.reviewAccumulation;
    if (rawPpm > targetMax) return NutrientPriorityLabel.possibleExcess;

    if (rawPpm >= targetMin && rawPpm <= targetMax) {
      return NutrientPriorityLabel.noPriority;
    }

    final deficit = targetMid - rawPpm;
    if (deficit <= 0) return NutrientPriorityLabel.noPriority;

    final deficitPct = deficit / targetMid;
    final isCritical = stagePressure01 > 0.6;

    if (rawPpm <= lowMax) return NutrientPriorityLabel.actionRecommended;

    if (deficitPct > 0.30) {
      return isCritical
          ? NutrientPriorityLabel.actionRecommended
          : NutrientPriorityLabel.highPriority;
    }
    if (deficitPct > 0.15) {
      return isCritical
          ? NutrientPriorityLabel.highPriority
          : NutrientPriorityLabel.mediumPriority;
    }
    if (deficitPct > 0.05) return NutrientPriorityLabel.mediumPriority;

    return NutrientPriorityLabel.lowPriority;
  }

  static double _priorityScore01({
    required NutrientPriorityLabel label,
    required double stagePressure01,
  }) {
    final double base = switch (label) {
      NutrientPriorityLabel.noPriority => 0.14,
      NutrientPriorityLabel.lowPriority => 0.30,
      NutrientPriorityLabel.mediumPriority => 0.48,
      NutrientPriorityLabel.highPriority => 0.68,
      NutrientPriorityLabel.reviewManagement => 0.58,
      NutrientPriorityLabel.actionRecommended => 0.86,
      NutrientPriorityLabel.possibleExcess => 0.60,
      NutrientPriorityLabel.reviewAccumulation => 0.72,
      NutrientPriorityLabel.unknown => 0.0,
    };

    return (base + (stagePressure01 * 0.10)).clamp(0.0, 1.0);
  }

  static String _mergePracticalAndDose({
    required String base,
    required String? doseGuideEs,
    required NutrientPriorityLabel label,
  }) {
    if (doseGuideEs == null || doseGuideEs.trim().isEmpty) return base;
    return '$base\n\n${doseGuideEs.trim()}';
  }

  // =========================================================================
  // HEADLINE
  // =========================================================================
  static String _shortRecommendation({
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
    required String? cropKey,
    required String? stageKey,
    StageTargets? targets,
  }) {
    final fromProfile = targets?.shortGuidanceFor(nutrient);
    if (fromProfile != null && fromProfile.trim().isNotEmpty) {
      if (label == NutrientPriorityLabel.noPriority) {
        return 'Todo bien con ${_nutrientShortName(nutrient)}. Tierra nutrida.';
      }
      if (label == NutrientPriorityLabel.lowPriority) {
        return 'Por ahora ${_nutrientShortName(nutrient)} no es la prioridad.';
      }
      if (label == NutrientPriorityLabel.possibleExcess ||
          label == NutrientPriorityLabel.reviewAccumulation) {
        if (nutrient == AgroMetricKey.n) {
          return 'Frena el nitrógeno. Hay reserva de sobra.';
        }
        return '¡Alto! Tienes ${_nutrientShortName(nutrient)} de más en la tierra.';
      }
      return fromProfile;
    }

    final nutrientName = _nutrientShortName(nutrient);
    final crop = (cropKey ?? '').toLowerCase();
    final isExcess =
        label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation;

    if (isExcess) {
      if (nutrient == AgroMetricKey.n) {
        return 'Frena el nitrógeno. Hay reserva de sobra.';
      }
      return '¡Alto! Tienes $nutrientName de más en la tierra.';
    }

    if (label == NutrientPriorityLabel.noPriority) {
      return 'Todo bien con $nutrientName. Tierra nutrida.';
    }
    if (label == NutrientPriorityLabel.lowPriority) {
      return 'Por ahora $nutrientName no es la prioridad.';
    }

    if (label == NutrientPriorityLabel.mediumPriority) {
      if (_isPrePeakStage(stageKey, crop)) {
        return 'Ojo: viene una etapa fuerte y $nutrientName va bajando.';
      }
      return 'El nivel de $nutrientName empieza a bajar. Vigila.';
    }

    if (label == NutrientPriorityLabel.highPriority) {
      return 'El cultivo necesita $nutrientName. Conviene actuar.';
    }

    if (label == NutrientPriorityLabel.actionRecommended) {
      if (_isLateStage(stageKey)) {
        return 'Falta $nutrientName, pero el ciclo ya está cerrando.';
      }
      return '¡Urge aplicar $nutrientName! El cultivo lo necesita ya.';
    }

    if (label == NutrientPriorityLabel.reviewManagement) {
      return 'Revisa tu manejo de $nutrientName. Hay desajuste.';
    }

    return 'Faltan datos para evaluar $nutrientName.';
  }

  // =========================================================================
  // RECOMENDACIÓN PRÁCTICA
  // =========================================================================
  static String _practicalRecommendation({
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
    required String? cropKey,
    required String? stageKey,
    double? trendPct,
    double? stagePressure01,
    StageTargets? targets,
  }) {
    final stage = (stageKey ?? '').toLowerCase();
    final crop = (cropKey ?? '').toLowerCase();

    if (crop == 'maize' || crop == 'maiz' || crop == 'corn') {
      return _maizePracticalRecommendation(
        nutrient,
        label,
        stage,
        trendPct,
        stagePressure01,
      );
    }
    if (crop == 'bean' || crop == 'frijol') {
      return _beanPracticalRecommendation(
        nutrient,
        label,
        stage,
        stagePressure01,
      );
    }
    if (crop == 'barley' || crop == 'cebada') {
      return _barleyPracticalRecommendation(
        nutrient,
        label,
        stage,
        stagePressure01,
      );
    }
    if (crop == 'oat' || crop == 'avena') {
      return _oatPracticalRecommendation(
        nutrient,
        label,
        stage,
        stagePressure01,
        targets,
      );
    }

    return _genericPracticalRecommendation(nutrient, label);
  }

  // ── MAÍZ ──────────────────────────────────────────────────────────────────
  static String _maizePracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? trendPct,
    double? stagePressure01,
  ) {
    final isLate = _isLateStage(stage);
    final isPeak = _isPeakNitrogenStage(stage);
    final isEarly = _isEarlyStage(stage);
    final isVeg = _isVegStage(stage);
    final isDroppingFast = trendPct != null && trendPct <= -15.0;

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Frena el nitrógeno. Hay reserva suficiente y aplicar más aquí sería gastar de más. Guarda para cuando la milpa de verdad lo pida.';
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isEarly) {
            return 'El arranque va bien. La plántula tiene el nitrógeno que necesita para echar raíz y hoja.';
          }
          if (isPeak) {
            return 'Excelente: la milpa tiene la comida que necesita justo cuando más la pide. Sigue así.';
          }
          return 'Aquí no hace falta correr. El nitrógeno está en su punto para esta etapa.';
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isVeg && (stagePressure01 ?? 0) > 0.5) {
            return 'Por ahora el nivel alcanza, pero se acerca una etapa de alta demanda. Conviene ir preparando la aplicación.';
          }
          return 'Por ahora este nutriente no es la prioridad. El cultivo puede seguir avanzando sin apurarse con esta aplicación.';
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isDroppingFast) {
            return 'OJO: El nivel está bajando rapidísimo. La milpa se lo está comiendo. Prepárate para aplicar Urea pronto.';
          }
          if (isPeak) {
            return 'Aquí sí conviene actuar. La milpa entró en la etapa donde el nitrógeno define el tamaño de la mazorca.';
          }
          return 'El nivel va bajando. Ve preparando la próxima fertilizada para no quedarte corto.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isPeak) {
            return '¡Ahorita se define el tamaño de la mazorca! La milpa exige nitrógeno. Si no aplicas ya, tu rendimiento se va a caer feo.';
          }
          if (isLate) {
            return 'Ya es tarde para que la planta lo aproveche bien. La mazorca ya cerró. Usa esta lectura para planear el próximo ciclo.';
          }
          if (isEarly) {
            return 'Le falta nitrógeno para arrancar. Aplica pronto para que la plántula no se quede chaparra ni amarilla.';
          }
          return 'Le falta nitrógeno para sostener esta etapa. Corregir ahora ayuda a no perder empuje.';
        }
        return 'Mantente al tanto del nitrógeno. El nivel va bajando.';

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Fósforo de sobra. Pausa las aplicaciones; el exceso puede bloquear zinc y hierro.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          if (isEarly) {
            return 'El fósforo está en buen nivel para el arranque. La raíz tiene lo que necesita para establecerse.';
          }
          return 'Aquí no hace falta correr. Conviene enfocarse primero en establecimiento, humedad y uniformidad.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isEarly) {
            return 'El fósforo está corto para arranque y raíz. Buen momento para meter fertilizante de arranque (DAP) al lado de la semilla.';
          }
          return 'Nivel bajo de fósforo. Aunque ya enraizó, tener reservas bajas te pegará en floración y llenado.';
        }
        return 'El fósforo va bajando. Vigila y prepara corrección si sigue la tendencia.';

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Potasio de sobra. Pausa las aplicaciones para no desbalancear la relación con magnesio.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Potasio en niveles seguros. Caña fuerte, sin riesgo de acame. No gastes de más.';
        }
        if (label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.highPriority) {
          return 'Te falta potasio. Sin esto, la caña se hace aguada y con un ventarrón se te va a acostar la milpa entera.';
        }
        return 'El potasio va bajando. Vigila para evitar acame.';

      default:
        return 'Revisa tu manejo de nutrientes.';
    }
  }

  // ── FRIJOL ────────────────────────────────────────────────────────────────
  static String _beanPracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? stagePressure01,
  ) {
    final isEarly = _isEarlyStage(stage);
    final isFlowering = stage.contains('flower') || stage.contains('flor');
    final isPodFill =
        stage.contains('pod') ||
        stage.contains('grain') ||
        stage.contains('vaina') ||
        stage.contains('llenado');
    final isVeg = stage.contains('veg');
    final isLate = _isLateStage(stage);

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Demasiado nitrógeno. El frijol fija el suyo del aire; el exceso provoca mucha hoja y poca vaina. Frena la aplicación.';
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isEarly) {
            return 'Buen arranque. La plántula tiene nitrógeno para echar su primera raíz y hoja mientras empieza a nodular.';
          }
          if (isFlowering || isPodFill) {
            return 'El frijol está fijando su nitrógeno correctamente. Deja que los nódulos hagan su trabajo.';
          }
          return 'Niveles estables. Deja que la planta fije su propio nitrógeno del aire.';
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isVeg && (stagePressure01 ?? 0) > 0.5) {
            return 'Pronto llega la floración y la demanda sube. Si el nivel sigue bajando, conviene una ayudadita con arrancador.';
          }
          return 'Por ahora el nitrógeno no es la prioridad del frijol. La fijación biológica debería cubrir la demanda.';
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isFlowering) {
            return 'El frijol está en flor y no alcanza a fijar suficiente N. Vigila de cerca: si sigue bajando, conviene aplicar un apoyo.';
          }
          return 'El nitrógeno va bajando. Puede que la nodulación no esté funcionando al 100%. Vigila.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return 'Ya es tarde para corregir nitrógeno. Usa esta lectura para planear inoculante o arrancador en el próximo ciclo.';
          }
          if (isEarly) {
            return 'La plántula necesita un empujón de N mientras arranca la nodulación. Aplica una dosis pequeña de arrancador.';
          }
          if (isFlowering) {
            return 'El frijol no está agarrando suficiente nitrógeno del aire y está en floración. Urge una ayuda para evitar aborto de flor.';
          }
          return 'Le falta nitrógeno y la fijación no alcanza. Aplica una dosis de apoyo para que no se ponga amarillo.';
        }
        return 'Vigila el nitrógeno. Si la nodulación no responde, conviene apoyar.';

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Fósforo de sobra. Pausa la aplicación; el exceso puede afectar la absorción de zinc.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          if (isEarly) {
            return 'El fósforo está bien para que la raíz se establezca y los nódulos se formen correctamente.';
          }
          return 'Buen nivel de fósforo. La raíz y los nódulos tienen lo que necesitan.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isEarly) {
            return 'Fósforo muy bajo en arranque. Sin esto, la raíz no trabaja y los nódulos no se forman bien. Buen momento para DAP al sembrar.';
          }
          if (isFlowering || isPodFill) {
            return 'El fósforo está corto justo cuando la planta necesita energía para llenar vainas. Corrige ahora si puedes.';
          }
          return 'Fósforo bajo. Sin esto, la raíz no trabaja y la planta se atora.';
        }
        return 'El fósforo va bajando. Vigila especialmente si se acerca la floración.';

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Potasio de sobra. Pausa la aplicación para mantener el balance con calcio y magnesio.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          if (isPodFill) {
            return 'Buen nivel de potasio justo cuando más importa: el llenado de vaina. El grano va a pesar bien.';
          }
          return 'Potasio listo para cuando llegue el llenado de vaina. No gastes de más.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isPodFill || isFlowering) {
            return 'Le falta potasio justo en llenado. Urge para que la vaina llene bien y el grano pese en la báscula.';
          }
          if (isVeg && (stagePressure01 ?? 0) > 0.5) {
            return 'El potasio está corto y se acerca la etapa de llenado. Conviene corregir ahora para no llegar corto.';
          }
          return 'Le falta potasio. Corrige para que la planta tenga reservas cuando las necesite.';
        }
        return 'Potasio va bajando. Vigila para tener reservas en llenado de vaina.';

      default:
        return 'Revisa tu manejo de nutrientes.';
    }
  }

  // ── CEBADA ────────────────────────────────────────────────────────────────
  static String _barleyPracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? stagePressure01,
  ) {
    final isEarly = _isEarlyStage(stage);
    final isTillering = stage.contains('tiller') || stage.contains('macoll');
    final isBooting = stage.contains('boot') || stage.contains('embuch');
    final isHeading = stage.contains('head') || stage.contains('espig');
    final isFlowering = stage.contains('flower') || stage.contains('flor');
    final isGrainFill = stage.contains('grain') || stage.contains('llenado');
    final isLate = _isLateStage(stage);
    final isReproductive = isBooting || isHeading || isFlowering || isGrainFill;

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isReproductive || isLate) {
            return 'Demasiado nitrógeno en etapa tardía. Si es maltera, esto sube la proteína y te rechazan el grano. No apliques más.';
          }
          return 'Frena el nitrógeno. Hay suficiente reserva y aplicar más es tirar dinero.';
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isTillering) {
            return 'Excelente: la cebada tiene el nitrógeno para amarrar buenos macollos. Sigue así.';
          }
          return 'Niveles de nitrógeno al cien. No tires tu dinero echando más.';
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isEarly && (stagePressure01 ?? 0) > 0.4) {
            return 'El nivel alcanza, pero se acerca el macollamiento donde la cebada más pide N. Ve preparando.';
          }
          return 'Por ahora el nitrógeno no es la prioridad. La cebada puede seguir avanzando.';
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isTillering) {
            return 'El macollamiento es el momento clave para N. Corrige ahora para amarrar espigas.';
          }
          return 'El nitrógeno va bajando. Conviene preparar la aplicación.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate || isReproductive) {
            return 'Aplicar N tan tarde puede dañar la calidad maltera. Usa esta lectura para planear tu pre-siembra.';
          }
          if (isTillering || isEarly) {
            return 'La cebada está pasando hambre en la etapa que más define rendimiento. Aplica N ya para amarrar macollos.';
          }
          return 'Falta nitrógeno. Corrige la dosis para no afectar los kilos por hectárea.';
        }
        return 'Vigila el nitrógeno de la cebada.';

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Fósforo de sobra. Pausa las aplicaciones.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          if (isEarly || isTillering) {
            return 'Buen nivel de fósforo para que la raíz se establezca y los macollos arranquen con fuerza.';
          }
          return 'Fósforo en buen nivel. No necesitas aplicar más por ahora.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isEarly || isTillering) {
            return 'La cebada necesita fósforo para echar raíz fuerte. Aplica ahora que todavía lo aprovecha.';
          }
          return 'Fósforo bajo. Fuera de la etapa temprana la corrección es poco eficiente, pero aún puede ayudar.';
        }
        return 'El fósforo va bajando. Vigila en etapa temprana.';

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Potasio de sobra. Pausa la aplicación.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Potasio en niveles seguros. Tallo firme, sin riesgo de encamado. No gastes de más.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isBooting || isHeading) {
            return 'Le falta potasio justo cuando el tallo necesita firmeza para sostener la espiga. Corrige ahora.';
          }
          return 'Falta potasio. Sin esto, la cebada se encama con el primer ventarrón.';
        }
        return 'El potasio va bajando. Vigila para prevenir encamado.';

      default:
        return 'Revisa tu manejo de nutrientes.';
    }
  }

  // ── AVENA ─────────────────────────────────────────────────────────────────
  static String _oatPracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? stagePressure01,
    StageTargets? targets,
  ) {
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

    final profileHint = targets?.plannerHintFor(nutrient);
    final windowLabel = targets?.windowLabelFor(nutrient);

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Frena el nitrógeno. La avena ya tiene reserva suficiente y seguir cargando N puede desbalancear el manejo.';
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isPeakN) {
            return 'La avena está bien nutrida justo en su ventana fuerte de nitrógeno. Mantén el manejo sin sobreaplicar.';
          }
          if (isEarly) {
            return 'Buen arranque. La avena tiene N suficiente sin sobrecargar la etapa temprana.';
          }
          return 'El nitrógeno está en rango para esta etapa. No hace falta correr con otra aplicación.';
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isPeakN || (stagePressure01 ?? 0) > 0.60) {
            return 'Se acerca o ya arrancó la etapa fuerte de N en avena. Conviene vigilar de cerca para no quedarte corto.';
          }
          return 'Por ahora el N no es la urgencia principal, pero no lo pierdas de vista.';
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isPeakN) {
            return 'La avena ya está entrando en presión de N. Conviene preparar la corrección para sostener macollamiento y empuje vegetativo.';
          }
          if (isReproductive) {
            return 'Hay presión de N, pero la etapa ya va avanzada. Revisa el plan con prudencia y no persigas un número a cualquier costo.';
          }
          return 'El N va bajando y conviene revisar el plan antes de llegar a la etapa fuerte.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isPeakN) {
            return 'Aquí sí conviene actuar: la avena está en macollamiento / elongación / embuche, la ventana donde más pesa llegar bien con N.';
          }
          if (isLate || isReproductive) {
            return 'Falta N, pero la avena ya va cerrando etapa. Revisa manejo y evita perseguir nitrógeno tardío como si tuviera la misma eficiencia.';
          }
          if (isEarly) {
            return 'Le falta N para sostener un arranque parejo. Corrige con moderación y guarda margen para el macollamiento.';
          }
          return 'Le falta nitrógeno para sostener el desarrollo. Conviene corregir antes de que la avena pierda empuje.';
        }
        return profileHint ??
            windowLabel ??
            'Vigila el nitrógeno de la avena y ajusta con criterio según la etapa.';

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Fósforo de sobra. Pausa la aplicación y evita seguir cargando una corrección que ya no hace falta.';
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isEarly) {
            return 'Buen nivel de fósforo para raíz y establecimiento. La avena arranca con una base favorable.';
          }
          return 'El fósforo está en nivel suficiente para esta etapa.';
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          return isEarly
              ? 'El fósforo todavía acompaña el arranque, pero la presión operativa sigue siendo baja por ahora.'
              : 'El fósforo no es la urgencia principal en esta etapa.';
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          return isEarly
              ? 'El fósforo empieza a quedarse corto justo donde más pesa: raíz y establecimiento. Conviene vigilarlo de cerca.'
              : 'La lectura sugiere revisar la base de P, aunque fuera de etapa temprana la corrección ya no rinde igual.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isEarly) {
            return 'El fósforo sí merece atención en avena al arranque. Sin buena disponibilidad de P, la raíz y el establecimiento se frenan.';
          }
          return 'Falta fósforo, pero la eficiencia de corregirlo tarde ya no es la misma. Úsalo también para fortalecer la base del siguiente ciclo.';
        }
        return profileHint ??
            windowLabel ??
            'Revisa el fósforo de la avena, sobre todo si la etapa todavía es temprana.';

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Potasio de sobra. Pausa las aplicaciones para no desbalancear el manejo del cultivo.';
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isReproductive) {
            return 'Buen nivel de K justo cuando la avena necesita balance y sostén en su fase avanzada.';
          }
          return 'El potasio está dentro de rango y sostiene bien el balance del cultivo.';
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isHeading || isFlowering || isGrainFill) {
            return 'El K todavía alcanza, pero ya está entrando en la fase donde empieza a pesar más.';
          }
          return 'Por ahora el K no es la urgencia principal, aunque conviene mantenerlo disponible.';
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isHeading || isFlowering || isGrainFill) {
            return 'El potasio empieza a hacer falta justo en una etapa donde aporta balance, firmeza y sostén. Conviene revisarlo con atención.';
          }
          return 'El K va bajando y puede volverse más relevante conforme avance la etapa.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isHeading || isFlowering || isGrainFill) {
            return 'Aquí el K sí toma protagonismo en avena. Conviene actuar para sostener balance, firmeza y llenado.';
          }
          return 'Le falta potasio. Corrige para sostener estabilidad fisiológica y evitar que el cultivo llegue desbalanceado a etapas posteriores.';
        }
        return profileHint ??
            windowLabel ??
            'Vigila el potasio como nutriente de balance y sostén en avena.';

      default:
        return 'Revisa tu manejo de nutrientes.';
    }
  }

  // ── GENÉRICO ──────────────────────────────────────────────────────────────
  static String _genericPracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
  ) {
    if (label == NutrientPriorityLabel.noPriority ||
        label == NutrientPriorityLabel.lowPriority) {
      return 'Niveles dentro del rango. No gastes de más, cuida tu bolsillo.';
    }
    if (label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation) {
      return 'Niveles altos. Pausa la aplicación de este nutriente para no desbalancear el suelo.';
    }
    if (label == NutrientPriorityLabel.highPriority ||
        label == NutrientPriorityLabel.actionRecommended) {
      return 'Conviene corregir este nutriente para no perder rendimiento.';
    }
    return 'Vigila tus niveles y ajusta el plan nutricional según avance el cultivo.';
  }

  // =========================================================================
  // JUSTIFICACIÓN
  // =========================================================================
  static String _justification({
    required AgroMetricKey nutrient,
    required double rawPpm,
    StageTargets? targets,
    String? cropKey,
    required NutrientPriorityLabel label,
  }) {
    final nutrientName = _nutrientLongName(nutrient);

    if (label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation) {
      return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName. Tienes niveles súper altos. Meterle más fertilizante ahorita puede ser tóxico o bloquear otros nutrientes en la tierra.';
    }

    if (label == NutrientPriorityLabel.noPriority ||
        label == NutrientPriorityLabel.lowPriority) {
      return 'Tu sensor lee ${rawPpm.round()} mg/kg. Esto está dentro del rango óptimo que pide la planta hoy. Cuida tu bolsillo y no apliques de más.';
    }

    final range = switch (nutrient) {
      AgroMetricKey.n => targets?.nIndex,
      AgroMetricKey.p => targets?.pIndex,
      AgroMetricKey.k => targets?.kIndex,
      _ => null,
    };

    if (range != null) {
      final cap = NpkCaps.forCropMetric(cropKey: cropKey, metricKey: nutrient);
      final targetMidPpm =
          ((range.optimalMin + range.optimalMax) / 2.0 / 100.0) * cap;
      final diff = math.max(0, (targetMidPpm - rawPpm)).round();

      if (diff > 0) {
        return 'Tu tierra tiene ${rawPpm.round()} mg/kg, pero la meta es llegar a ~${targetMidPpm.round()} mg/kg en esta etapa. Usamos esa diferencia de $diff puntos para calcular la dosis que te recomendamos aplicar.';
      }
    }

    return 'La planta va a requerir más $nutrientName pronto según su etapa de desarrollo.';
  }

  // =========================================================================
  // VENTANA DE DEMANDA
  // =========================================================================
  static String _demandWindowLabel({
    required AgroMetricKey nutrient,
    required String? cropKey,
    required String? stageKey,
    StageTargets? targets,
  }) {
    final fromProfile = targets?.windowLabelFor(nutrient);
    if (fromProfile != null && fromProfile.trim().isNotEmpty) {
      return fromProfile;
    }

    final crop = (cropKey ?? '').toLowerCase();
    final stage = (stageKey ?? '').toLowerCase();

    if (crop == 'maize' || crop == 'maiz') {
      if (nutrient == AgroMetricKey.n) {
        if (_isEarlyStage(stage)) return 'Arranque y Establecimiento';
        if (_isPeakNitrogenStage(stage)) return 'Desarrollo de Hojas y Mazorca';
        if (_isLateStage(stage)) return 'Cierre de Ciclo';
        return 'Crecimiento Vegetativo';
      }
      if (nutrient == AgroMetricKey.p) {
        if (_isEarlyStage(stage)) return 'Enraizamiento y Arranque';
        return 'Reserva de Fósforo';
      }
      if (nutrient == AgroMetricKey.k) {
        if (_isPeakNitrogenStage(stage) || _isLateStage(stage)) {
          return 'Firmeza de Caña';
        }
        return 'Reserva de Potasio';
      }
    }

    if (crop == 'barley' || crop == 'cebada') {
      if (nutrient == AgroMetricKey.n) {
        if (_isEarlyStage(stage) ||
            stage.contains('tiller') ||
            stage.contains('macoll')) {
          return 'Macollamiento y Espigas';
        }
        if (stage.contains('boot') ||
            stage.contains('head') ||
            stage.contains('espig') ||
            stage.contains('embuch')) {
          return 'Espigamiento';
        }
        return 'Crecimiento General';
      }
      if (nutrient == AgroMetricKey.p) return 'Raíz Fuerte';
      if (nutrient == AgroMetricKey.k) return 'Tallo y Anti-encame';
    }

    if (crop == 'bean' || crop == 'frijol') {
      if (nutrient == AgroMetricKey.n) {
        if (_isEarlyStage(stage)) return 'Arranque (pre-nodulación)';
        if (stage.contains('flower') || stage.contains('flor')) {
          return 'Floración y Fijación';
        }
        return 'Fijación Biológica';
      }
      if (nutrient == AgroMetricKey.p) {
        if (_isEarlyStage(stage)) return 'Nodulación y Raíz';
        return 'Reserva de Fósforo';
      }
      if (nutrient == AgroMetricKey.k) {
        if (stage.contains('pod') ||
            stage.contains('grain') ||
            stage.contains('vaina') ||
            stage.contains('llenado')) {
          return 'Llenado de Vaina';
        }
        return 'Reserva de Potasio';
      }
    }

    if (crop == 'oat' || crop == 'avena') {
      if (nutrient == AgroMetricKey.n) {
        if (_isEarlyStage(stage)) return 'Arranque moderado';
        if (stage.contains('tiller') ||
            stage.contains('macoll') ||
            stage.contains('elong') ||
            stage.contains('boot') ||
            stage.contains('embuch')) {
          return 'Macollamiento y empuje vegetativo';
        }
        if (stage.contains('head') ||
            stage.contains('espig') ||
            stage.contains('flower') ||
            stage.contains('flor')) {
          return 'Cierre de N';
        }
        return 'Demanda de N por etapa';
      }
      if (nutrient == AgroMetricKey.p) {
        if (_isEarlyStage(stage)) return 'Arranque y raíz';
        return 'Base de fósforo';
      }
      if (nutrient == AgroMetricKey.k) {
        if (stage.contains('head') ||
            stage.contains('espig') ||
            stage.contains('flower') ||
            stage.contains('flor') ||
            stage.contains('grain') ||
            stage.contains('llenado')) {
          return 'Balance, firmeza y llenado';
        }
        return 'Balance vegetativo';
      }
    }

    return 'Demanda actual';
  }

  // =========================================================================
  // HELPERS DE ETAPA
  // =========================================================================
  static bool _isEarlyStage(String? stage) {
    final s = (stage ?? '').toLowerCase();
    return s.contains('germin') ||
        s.contains('emerg') ||
        s.contains('vegearly') ||
        s.contains('early');
  }

  static bool _isVegStage(String? stage) {
    final s = (stage ?? '').toLowerCase();
    return s.contains('veg');
  }

  static bool _isPeakNitrogenStage(String? stage) {
    final s = (stage ?? '').toLowerCase();
    return s.contains('vegmid') ||
        s.contains('vegadvanced') ||
        s.contains('tass') ||
        s.contains('elong') ||
        s.contains('boot');
  }

  static bool _isPrePeakStage(String? stageKey, String crop) {
    final s = (stageKey ?? '').toLowerCase();
    if (crop == 'maize' || crop == 'maiz') {
      return s.contains('vegearly') || s.contains('vegmid');
    }
    if (crop == 'bean' || crop == 'frijol') {
      return s.contains('vegadvanced') || s.contains('veg');
    }
    if (crop == 'barley' || crop == 'cebada') {
      return s.contains('vegearly') ||
          s.contains('tiller') ||
          s.contains('macoll');
    }
    if (crop == 'oat' || crop == 'avena') {
      return s.contains('vegearly') ||
          s.contains('tiller') ||
          s.contains('macoll');
    }
    return false;
  }

  static bool _isLateStage(String? stageKey) {
    final s = (stageKey ?? '').toLowerCase();
    return s.contains('matur') ||
        s.contains('senesc') ||
        s.contains('harvest') ||
        s.contains('cosech');
  }

  static String _nutrientShortName(AgroMetricKey nutrient) =>
      switch (nutrient) {
        AgroMetricKey.n => 'N',
        AgroMetricKey.p => 'P',
        AgroMetricKey.k => 'K',
        _ => 'nutriente',
      };

  static String _nutrientLongName(AgroMetricKey nutrient) => switch (nutrient) {
    AgroMetricKey.n => 'Nitrógeno',
    AgroMetricKey.p => 'Fósforo',
    AgroMetricKey.k => 'Potasio',
    _ => 'el nutriente',
  };
}
