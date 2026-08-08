import 'dart:math' as math;
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/apple_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/chili_nutrition_modifier.dart';
import 'package:bio_g/core/agro/eggplant_nutrition_modifier.dart';
import 'package:bio_g/core/agro/fertilization_planner.dart';
import 'package:bio_g/core/agro/garlic_nutrition_modifier.dart';
import 'package:bio_g/core/agro/lettuce_nutrition_modifier.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/dose_expression.dart';
import 'package:bio_g/core/agro/soil_reaction.dart';
import 'package:bio_g/core/agro/onion_nutrition_modifier.dart';
import 'package:bio_g/core/agro/peach_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/pear_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/walnut_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/pistachio_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/orange_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/lemon_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/mango_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/avocado_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/spinach_nutrition_modifier.dart';
import 'package:bio_g/core/agro/squash_nutrition_modifier.dart';
import 'package:bio_g/core/agro/nutrient_target_range_resolver.dart';
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
    String? varietyId,
    String? varietyAlias,
    String? calendarId,
    StageTargets? targets,
    StageWeights? weights,
    String? cultivationScaleId,
    double? ph,
    double? ec,
    double? soilMoisturePct,
    double? trendPct,
    /// Cosecha esperada por árbol, en kg. Solo la usan los perennes.
    ///
    /// Opcional a propósito: los quince motores de score que llaman a este
    /// método no la pasan, y sin ella todo se comporta exactamente igual que
    /// antes. Cuando llega, el frutal deja de dar solo criterio y pasa a dar
    /// gramos por árbol.
    double? kgFruitPerTree,
    /// Cómo aplica el productor. Con fertirriego y densidad conocida, la
    /// dosis sale en gramos por planta en vez de kg/ha.
    DoseContext doseContext = DoseContext.none,
  }) {
    // El pH ya viene en cada lectura: de ahí sale si el suelo es calcáreo,
    // sin preguntarle nada al productor. En suelo calcáreo el calcio fija el
    // fósforo y la banda objetivo tiene que subir; si no, el motor lee
    // «óptimo» donde el laboratorio diría «bajo» y deja de recomendar fósforo
    // que sí hacía falta.
    final SoilReaction soilReaction = soilReactionFromPh(ph);
    assert(
      nutrient == AgroMetricKey.n ||
          nutrient == AgroMetricKey.p ||
          nutrient == AgroMetricKey.k,
      'NutrientRecommendationEngine only accepts N/P/K metrics.',
    );

    final cap = NpkCaps.forCropMetric(cropKey: cropKey, metricKey: nutrient);
    final rawRatio01 = cap <= 0 ? 0.0 : (rawPpm / cap).clamp(0.0, 1.25);

    final baseStagePressure01 = _resolveStagePressure01(
      nutrient: nutrient,
      cropKey: cropKey,
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

    final isChiliCrop = _isChiliCrop(cropKey);
    final chiliModifier = isChiliCrop
        ? resolveChiliNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isEggplantCrop = _isEggplantCrop(cropKey);
    final eggplantModifier = isEggplantCrop
        ? resolveEggplantNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isSquashCrop = _isSquashCrop(cropKey);
    final squashModifier = isSquashCrop
        ? resolveSquashNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isLettuceCrop = _isLettuceCrop(cropKey);
    final lettuceModifier = isLettuceCrop
        ? resolveLettuceNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isSpinachCrop = _isSpinachCrop(cropKey);
    final spinachModifier = isSpinachCrop
        ? resolveSpinachNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isOnionCrop = _isOnionCrop(cropKey);
    final onionModifier = isOnionCrop
        ? resolveOnionNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isGarlicCrop = _isGarlicCrop(cropKey);
    final garlicModifier = isGarlicCrop
        ? resolveGarlicNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isAppleTreeCrop = _isAppleTreeCrop(cropKey);
    final appleTreeModifier = isAppleTreeCrop
        ? resolveAppleTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isPearTreeCrop = _isPearTreeCrop(cropKey);
    final pearTreeModifier = isPearTreeCrop
        ? resolvePearTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isPeachTreeCrop = _isPeachTreeCrop(cropKey);
    final peachTreeModifier = isPeachTreeCrop
        ? resolvePeachTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isWalnutTreeCrop = _isWalnutTreeCrop(cropKey);
    final walnutTreeModifier = isWalnutTreeCrop
        ? resolveWalnutTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isPistachioTreeCrop = _isPistachioTreeCrop(cropKey);
    final pistachioTreeModifier = isPistachioTreeCrop
        ? resolvePistachioTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isOrangeTreeCrop = _isOrangeTreeCrop(cropKey);
    final orangeTreeModifier = isOrangeTreeCrop
        ? resolveOrangeTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isLemonTreeCrop = _isLemonTreeCrop(cropKey);
    final lemonTreeModifier = isLemonTreeCrop
        ? resolveLemonTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isMangoTreeCrop = _isMangoTreeCrop(cropKey);
    final mangoTreeModifier = isMangoTreeCrop
        ? resolveMangoTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;
    final isAvocadoTreeCrop = _isAvocadoTreeCrop(cropKey);
    final avocadoTreeModifier = isAvocadoTreeCrop
        ? resolveAvocadoTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId ?? cultivationScaleId,
          )
        : null;

    final combinedStagePressure01 = _combineStagePressure01(
      baseStagePressure01: baseStagePressure01,
      contextModifier01: contextModifier01,
      trendModifier01: trendModifier01,
    );
    final effectiveStagePressure01 =
        chiliModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        eggplantModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        squashModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        lettuceModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        spinachModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        onionModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        garlicModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        appleTreeModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        pearTreeModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        peachTreeModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        walnutTreeModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        pistachioTreeModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        orangeTreeModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        lemonTreeModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        mangoTreeModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        avocadoTreeModifier?.adjustStagePressure(
          combinedStagePressure01,
          nutrient: nutrient,
          stageKey: stageKey,
        ) ??
        combinedStagePressure01;

    final demandWindowLabel = _demandWindowLabel(
      nutrient: nutrient,
      cropKey: cropKey,
      stageKey: stageKey,
      targets: targets,
    );

    final comparableRange = NutrientTargetRangeResolver.comparableRange(
      nutrient: nutrient,
      cropKey: cropKey,
      targets: targets,
      soilReaction: soilReaction,
    );

    final label = _resolveLabel(
      rawPpm: rawPpm,
      range: comparableRange,
      stagePressure01: effectiveStagePressure01,
    );

    final priorityScore01 = _priorityScore01(
      label: label,
      stagePressure01: effectiveStagePressure01,
      contextModifier01: contextModifier01,
      trendModifier01: trendModifier01,
    );

    final doseGuide = FertilizationPlanner.buildGuide(
      nutrient: nutrient,
      label: label,
      rawPpm: rawPpm,
      cropKey: cropKey,
      stageKey: stageKey,
      profileId: profileId,
      varietyId: varietyId,
      varietyAlias: varietyAlias,
      calendarId: calendarId,
      targets: targets,
      cultivationScaleId: cultivationScaleId,
      kgFruitPerTree: kgFruitPerTree,
      doseContext: doseContext,
      ph: ph,
    );

    final practicalBase = _practicalRecommendation(
      nutrient: nutrient,
      label: label,
      cropKey: cropKey,
      stageKey: stageKey,
      trendPct: trendPct,
      stagePressure01: effectiveStagePressure01,
      targets: targets,
      ph: ph,
      ec: ec,
      soilMoisturePct: soilMoisturePct,
      chiliModifier: chiliModifier,
      eggplantModifier: eggplantModifier,
      squashModifier: squashModifier,
      lettuceModifier: lettuceModifier,
      spinachModifier: spinachModifier,
      onionModifier: onionModifier,
      garlicModifier: garlicModifier,
      appleTreeModifier: appleTreeModifier,
      pearTreeModifier: pearTreeModifier,
      peachTreeModifier: peachTreeModifier,
      walnutTreeModifier: walnutTreeModifier,
      pistachioTreeModifier: pistachioTreeModifier,
      orangeTreeModifier: orangeTreeModifier,
      lemonTreeModifier: lemonTreeModifier,
      mangoTreeModifier: mangoTreeModifier,
      avocadoTreeModifier: avocadoTreeModifier,
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
      stagePressure01: effectiveStagePressure01,
      contextModifier01: contextModifier01,
      trendModifier01: trendModifier01,
      label: label,
      labelEs: _displayLabelEs(label, cropKey: cropKey),
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

  static String _displayLabelEs(
    NutrientPriorityLabel label, {
    required String? cropKey,
  }) {
    if (_isFruitTreeCrop(cropKey) &&
        label == NutrientPriorityLabel.possibleExcess) {
      return 'Alto útil';
    }
    return label.labelEs;
  }

  // =========================================================================
  // PRESIÓN FENOLÓGICA (0..1)
  // =========================================================================
  static double _resolveStagePressure01({
    required AgroMetricKey nutrient,
    required String? cropKey,
    StageTargets? targets,
    StageWeights? weights,
  }) {
    final AgroRange? range = NutrientTargetRangeResolver.comparableRange(
      nutrient: nutrient,
      cropKey: cropKey,
      targets: targets,
    );

    final targetPriority01 = (targets?.resolvedPriorityFor(nutrient) ?? 0.50)
        .clamp(0.0, 1.0);

    final double rangeMid01;
    if (range == null) {
      rangeMid01 = 0.50;
    } else {
      final double cap = NpkCaps.forCropMetric(
        cropKey: cropKey,
        metricKey: nutrient,
      );
      if (cap <= 0) {
        rangeMid01 = 0.50;
      } else {
        rangeMid01 = (((range.optimalMin + range.optimalMax) / 2.0) / cap)
            .clamp(0.0, 1.0);
      }
    }

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

  static double _combineStagePressure01({
    required double baseStagePressure01,
    required double contextModifier01,
    required double trendModifier01,
  }) {
    return (baseStagePressure01 +
            (contextModifier01 * 0.45) +
            (trendModifier01 * 0.65))
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
    required AgroRange? range,
    required double stagePressure01,
  }) {
    if (range == null) return NutrientPriorityLabel.unknown;

    final targetMin = range.optimalMin;
    final targetMax = range.optimalMax;
    final targetMid = (targetMin + targetMax) / 2.0;
    final highMin = range.highMin;
    final lowMax = range.lowMax;

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
    required double contextModifier01,
    required double trendModifier01,
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

    return (base +
            (stagePressure01 * 0.08) +
            (contextModifier01 * 0.35) +
            (trendModifier01 * 0.45))
        .clamp(0.0, 1.0);
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
      if (_isFruitTreeCrop(cropKey) &&
          label == NutrientPriorityLabel.possibleExcess) {
        return _pepitaTreeHighUsefulShortRecommendation(nutrient);
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

    if (_isLettuceCrop(cropKey)) {
      return _lettuceShortRecommendation(
        nutrientName: nutrientName,
        label: label,
        isExcess: isExcess,
      );
    }

    if (_isSpinachCrop(cropKey)) {
      return _spinachShortRecommendation(
        nutrientName: nutrientName,
        label: label,
        isExcess: isExcess,
      );
    }

    if (_isOnionCrop(cropKey)) {
      return _onionShortRecommendation(
        nutrientName: nutrientName,
        label: label,
        isExcess: isExcess,
      );
    }

    if (_isGarlicCrop(cropKey)) {
      return _garlicShortRecommendation(
        nutrientName: nutrientName,
        label: label,
        isExcess: isExcess,
      );
    }

    if (_isFruitTreeCrop(cropKey) &&
        label == NutrientPriorityLabel.possibleExcess) {
      return _pepitaTreeHighUsefulShortRecommendation(nutrient);
    }

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

  static String _lettuceShortRecommendation({
    required String nutrientName,
    required NutrientPriorityLabel label,
    required bool isExcess,
  }) {
    if (isExcess) {
      return 'Pausa $nutrientName y revisa balance en lechuga.';
    }
    if (label == NutrientPriorityLabel.noPriority ||
        label == NutrientPriorityLabel.lowPriority) {
      return '$nutrientName en zona manejable para lechuga.';
    }
    if (label == NutrientPriorityLabel.mediumPriority) {
      return '$nutrientName va bajando; vigila calidad de hoja.';
    }
    if (label == NutrientPriorityLabel.highPriority ||
        label == NutrientPriorityLabel.actionRecommended ||
        label == NutrientPriorityLabel.reviewManagement) {
      return 'Revisa $nutrientName antes de ajustar manejo.';
    }
    return 'Faltan datos para evaluar $nutrientName en lechuga.';
  }

  static String _spinachShortRecommendation({
    required String nutrientName,
    required NutrientPriorityLabel label,
    required bool isExcess,
  }) {
    if (isExcess) {
      return 'Pausa $nutrientName y revisa CE, agua y calidad de hoja.';
    }
    if (label == NutrientPriorityLabel.noPriority ||
        label == NutrientPriorityLabel.lowPriority) {
      return '$nutrientName en zona manejable para espinaca.';
    }
    if (label == NutrientPriorityLabel.mediumPriority) {
      return '$nutrientName va bajando; vigila turgencia y hoja comercial.';
    }
    if (label == NutrientPriorityLabel.highPriority ||
        label == NutrientPriorityLabel.actionRecommended ||
        label == NutrientPriorityLabel.reviewManagement) {
      return 'Revisa $nutrientName antes de ajustar manejo.';
    }
    return 'Faltan datos para evaluar $nutrientName en espinaca.';
  }

  static String _onionShortRecommendation({
    required String nutrientName,
    required NutrientPriorityLabel label,
    required bool isExcess,
  }) {
    if (isExcess) {
      return 'Pausa $nutrientName y revisa CE, agua y etapa del bulbo.';
    }
    if (label == NutrientPriorityLabel.noPriority ||
        label == NutrientPriorityLabel.lowPriority) {
      return '$nutrientName en zona manejable para cebolla.';
    }
    if (label == NutrientPriorityLabel.mediumPriority) {
      return '$nutrientName va bajando; vigila etapa y calidad del bulbo.';
    }
    if (label == NutrientPriorityLabel.highPriority ||
        label == NutrientPriorityLabel.actionRecommended ||
        label == NutrientPriorityLabel.reviewManagement) {
      return 'Revisa $nutrientName antes de ajustar manejo.';
    }
    return 'Faltan datos para evaluar $nutrientName en cebolla.';
  }

  static String _garlicShortRecommendation({
    required String nutrientName,
    required NutrientPriorityLabel label,
    required bool isExcess,
  }) {
    if (isExcess) {
      return 'Pausa $nutrientName y revisa CE, agua, frio y curado del ajo.';
    }
    if (label == NutrientPriorityLabel.noPriority ||
        label == NutrientPriorityLabel.lowPriority) {
      return '$nutrientName en zona manejable para ajo.';
    }
    if (label == NutrientPriorityLabel.mediumPriority) {
      return '$nutrientName va bajando; vigila bulbo, frio y curado.';
    }
    if (label == NutrientPriorityLabel.highPriority ||
        label == NutrientPriorityLabel.actionRecommended ||
        label == NutrientPriorityLabel.reviewManagement) {
      return 'Revisa $nutrientName antes de ajustar manejo en ajo.';
    }
    return 'Faltan datos para evaluar $nutrientName en ajo.';
  }

  static String _pepitaTreeHighUsefulShortRecommendation(
    AgroMetricKey nutrient,
  ) {
    return switch (nutrient) {
      AgroMetricKey.n =>
        'N alto útil. No agregues más N por ahora; vigila follaje de más.',
      AgroMetricKey.p =>
        'P alto útil. Pausa fósforo extra y sigue la tendencia.',
      AgroMetricKey.k =>
        'K alto útil para fruto. No subas más K si el fruto va bien.',
      _ => 'Nutriente alto útil. Mantén monitoreo sin aplicar de más.',
    };
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
    // Contexto de suelo para guardas (hoy solo lo usa el nogal; otros cultivos
    // lo ignoran). Aditivo y opcional: no cambia el comportamiento existente.
    double? ph,
    double? ec,
    double? soilMoisturePct,
    ChiliNutritionModifier? chiliModifier,
    EggplantNutritionModifier? eggplantModifier,
    SquashNutritionModifier? squashModifier,
    LettuceNutritionModifier? lettuceModifier,
    SpinachNutritionModifier? spinachModifier,
    OnionNutritionModifier? onionModifier,
    GarlicNutritionModifier? garlicModifier,
    AppleTreeNutritionModifier? appleTreeModifier,
    PearTreeNutritionModifier? pearTreeModifier,
    PeachTreeNutritionModifier? peachTreeModifier,
    WalnutTreeNutritionModifier? walnutTreeModifier,
    PistachioTreeNutritionModifier? pistachioTreeModifier,
    OrangeTreeNutritionModifier? orangeTreeModifier,
    LemonTreeNutritionModifier? lemonTreeModifier,
    MangoTreeNutritionModifier? mangoTreeModifier,
    AvocadoTreeNutritionModifier? avocadoTreeModifier,
  }) {
    final stage = (stageKey ?? '').toLowerCase();
    final crop = (cropKey ?? '').toLowerCase();

    // Guardia para hortalizas de fruto SIN recomendación dedicada (pepino
    // hoy, frutales/ornamentales mañana) en fin de ciclo: evita que el
    // dispatch caiga al genérico "conviene corregir". Las hortalizas con
    // función propia (tomate/chile/berenjena/calabaza) hacen su propio
    // early-return de fin de ciclo más abajo y pueden añadir caution
    // de perfil (p.ej. "Calabacita en cierre").
    if (_isHortalizaFrutoSinHandler(crop) && _isLateStage(stage)) {
      return _hortalizaLateCycleMessage(nutrient: nutrient, label: label);
    }

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
    if (crop == 'wheat' || crop == 'trigo') {
      return _wheatPracticalRecommendation(
        nutrient,
        label,
        stage,
        stagePressure01,
        targets,
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
    if (crop == 'tomato' || crop == 'tomate' || crop == 'jitomate') {
      return _tomatoPracticalRecommendation(
        nutrient,
        label,
        stage,
        stagePressure01,
        targets,
      );
    }
    if (crop == 'chili' ||
        crop == 'chile' ||
        crop == 'pepper' ||
        crop == 'pimiento') {
      return _chiliPracticalRecommendation(
        nutrient,
        label,
        stage,
        stagePressure01,
        targets,
        chiliModifier,
      );
    }
    if (crop == 'eggplant' || crop == 'berenjena' || crop == 'aubergine') {
      return _eggplantPracticalRecommendation(
        nutrient,
        label,
        stage,
        stagePressure01,
        targets,
        eggplantModifier,
      );
    }
    if (crop == 'squash' ||
        crop == 'calabaza' ||
        crop == 'pumpkin' ||
        crop == 'zucchini' ||
        crop == 'calabacita') {
      return _squashPracticalRecommendation(
        nutrient,
        label,
        stage,
        stagePressure01,
        targets,
        squashModifier,
      );
    }
    if (crop == 'lettuce' || crop == 'lechuga' || crop == 'crop_lettuce') {
      return _lettucePracticalRecommendation(
        nutrient,
        label,
        stage,
        stagePressure01,
        targets,
        lettuceModifier,
      );
    }
    if (crop == 'spinach' || crop == 'espinaca' || crop == 'crop_spinach') {
      return _spinachPracticalRecommendation(
        nutrient,
        label,
        stage,
        stagePressure01,
        targets,
        spinachModifier,
      );
    }
    if (crop == 'onion' || crop == 'cebolla' || crop == 'crop_onion') {
      return _onionPracticalRecommendation(
        nutrient,
        label,
        stage,
        stagePressure01,
        targets,
        onionModifier,
      );
    }
    if (crop == 'garlic' || crop == 'ajo' || crop == 'crop_garlic') {
      return _garlicPracticalRecommendation(
        nutrient,
        label,
        stage,
        stagePressure01,
        targets,
        garlicModifier,
      );
    }
    if (_isAppleTreeCrop(crop)) {
      return _appleTreePracticalRecommendation(
        nutrient,
        label,
        stage,
        appleTreeModifier,
      );
    }
    if (_isPearTreeCrop(crop)) {
      return _pearTreePracticalRecommendation(
        nutrient,
        label,
        stage,
        pearTreeModifier,
      );
    }
    if (_isPeachTreeCrop(crop)) {
      return _peachTreePracticalRecommendation(
        nutrient,
        label,
        stage,
        peachTreeModifier,
      );
    }
    if (_isWalnutTreeCrop(crop)) {
      return _walnutTreePracticalRecommendation(
        nutrient,
        label,
        stage,
        walnutTreeModifier,
        ph: ph,
        ec: ec,
        soilMoisturePct: soilMoisturePct,
      );
    }
    if (_isPistachioTreeCrop(crop)) {
      return _pistachioTreePracticalRecommendation(
        nutrient,
        label,
        stage,
        pistachioTreeModifier,
        ph: ph,
        ec: ec,
        soilMoisturePct: soilMoisturePct,
      );
    }
    if (_isOrangeTreeCrop(crop)) {
      return _orangeTreePracticalRecommendation(
        nutrient,
        label,
        stage,
        orangeTreeModifier,
        ph: ph,
        ec: ec,
        soilMoisturePct: soilMoisturePct,
      );
    }
    if (_isLemonTreeCrop(crop)) {
      return _lemonTreePracticalRecommendation(
        nutrient,
        label,
        stage,
        lemonTreeModifier,
        ph: ph,
        ec: ec,
        soilMoisturePct: soilMoisturePct,
      );
    }
    if (_isMangoTreeCrop(crop)) {
      return _mangoTreePracticalRecommendation(
        nutrient,
        label,
        stage,
        mangoTreeModifier,
        ph: ph,
        ec: ec,
        soilMoisturePct: soilMoisturePct,
      );
    }
    if (_isAvocadoTreeCrop(crop)) {
      return _avocadoTreePracticalRecommendation(
        nutrient,
        label,
        stage,
        avocadoTreeModifier,
        ph: ph,
        ec: ec,
        soilMoisturePct: soilMoisturePct,
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

  // ── TRIGO ─────────────────────────────────────────────────────────────────
  static String _wheatPracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? stagePressure01,
    StageTargets? targets,
  ) {
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

    final profileHint = targets?.plannerHintFor(nutrient);
    final windowLabel = targets?.windowLabelFor(nutrient);

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Frena el nitrógeno. El trigo ya tiene reserva suficiente y seguir cargando N puede empujar proteína de más, acame o gasto innecesario.';
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isPeakN) {
            return 'El trigo está bien nutrido justo en su ventana fuerte de N. Mantén el manejo sin sobreaplicar.';
          }
          if (isEarly) {
            return 'Buen arranque. El trigo tiene N suficiente sin sobrecargar la siembra.';
          }
          if (isProteinWindow) {
            return 'El N está en rango para la fase de espigamiento/antesis. No hace falta perseguir una corrección de rutina.';
          }
          return 'El nitrógeno está en rango para esta etapa. No hace falta correr con otra aplicación.';
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isPeakN || (stagePressure01 ?? 0) > 0.60) {
            return 'Se acerca o ya arrancó la ventana fuerte de N en trigo. Conviene vigilar de cerca para no quedarte corto en macollamiento/encañe.';
          }
          return 'Por ahora el N no es la urgencia principal, pero no lo pierdas de vista.';
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isPeakN) {
            return 'El trigo ya está entrando en presión de N. Conviene preparar la corrección para no perder macollos, espigas y empuje vegetativo.';
          }
          if (isProteinWindow) {
            return 'Hay presión de N, pero en esta etapa el retorno va más a calidad/proteína que a subir mucho el rendimiento.';
          }
          if (isReproductive) {
            return 'La lectura marca presión de N, pero la etapa ya va avanzada. Úsala con prudencia y no como si valiera lo mismo que en macollaje.';
          }
          return 'El N va bajando y conviene revisar el plan antes de llegar a la etapa fuerte.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isPeakN) {
            return 'Aquí sí conviene actuar: el trigo está en macollamiento / encañe / embuche, la ventana donde más pesa llegar bien con N.';
          }
          if (isProteinWindow) {
            return 'Falta N, pero ya vas en espigamiento/antesis. Corrige con criterio: esta etapa mueve más calidad que puro rendimiento.';
          }
          if (isLate || isReproductive) {
            return 'Falta N, pero el trigo ya va cerrando etapa. Revisa manejo y evita perseguir nitrógeno tardío como si tuviera la misma eficiencia.';
          }
          if (isEarly) {
            return 'Le falta N para sostener un arranque parejo, pero no cargues toda la corrección aquí. En trigo conviene dejar margen para macollamiento.';
          }
          return 'Le falta nitrógeno para sostener el desarrollo. Conviene corregir antes de que el trigo llegue corto a su tramo fuerte.';
        }
        return profileHint ??
            windowLabel ??
            'Vigila el nitrógeno del trigo y ajusta con criterio según la etapa.';

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Fósforo de sobra. Pausa la aplicación y evita seguir cargando una corrección que ya no hace falta.';
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isEarly || isTillering) {
            return 'Buen nivel de fósforo para raíz, implantación y macollaje parejo. El trigo arranca con una base favorable.';
          }
          return 'El fósforo está en nivel suficiente para esta etapa.';
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          return isEarly || isTillering
              ? 'El fósforo todavía acompaña bien el arranque, pero conviene no descuidarlo porque trigo responde más temprano que tarde.'
              : 'El fósforo no es la urgencia principal en esta etapa.';
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          return isEarly || isTillering
              ? 'El fósforo empieza a quedarse corto justo donde más pesa: raíz, implantación y macollaje inicial. Conviene vigilarlo de cerca.'
              : 'La lectura sugiere revisar la base de P, aunque fuera de etapa temprana la corrección ya no rinde igual.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isEarly || isTillering) {
            return 'El fósforo sí merece atención al arranque del trigo. Sin buena disponibilidad de P, la raíz y la implantación se frenan desde temprano.';
          }
          return 'Falta fósforo, pero la eficiencia de corregirlo tarde ya no es la misma. Úsalo también para fortalecer la base del siguiente ciclo.';
        }
        return profileHint ??
            windowLabel ??
            'Revisa el fósforo del trigo, sobre todo si la etapa todavía es temprana.';

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Potasio de sobra. Pausa las aplicaciones para no desbalancear el manejo del cultivo.';
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isProteinWindow || isGrainFill) {
            return 'Buen nivel de K justo cuando el trigo necesita balance, turgencia y sostén de tallo/llenado.';
          }
          return 'El potasio está dentro de rango y sostiene bien el balance del cultivo.';
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isProteinWindow || isGrainFill) {
            return 'El K todavía alcanza, pero ya está entrando en la fase donde puede volverse más relevante como nutriente de balance y sostén.';
          }
          return 'Por ahora el K no es la urgencia principal, aunque conviene mantenerlo disponible.';
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isProteinWindow || isGrainFill) {
            return 'El potasio empieza a hacer falta justo en una etapa donde aporta balance, firmeza de tallo y sostén bajo estrés. Conviene revisarlo con atención.';
          }
          return 'El K va bajando y puede volverse más relevante conforme avance la etapa, sobre todo si el suelo viene corto.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isProteinWindow || isGrainFill) {
            return 'Aquí el K puede volverse relevante en trigo como nutriente de balance y sostén. Conviene actuar si la lectura realmente confirma un suelo corto.';
          }
          return 'Le falta potasio. Corrige para sostener estabilidad fisiológica y evitar que el trigo llegue desbalanceado a etapas posteriores.';
        }
        return profileHint ??
            windowLabel ??
            'Vigila el potasio como nutriente de balance y sostén en trigo.';

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

  // ── TOMATE ────────────────────────────────────────────────────────────────
  //
  // Fisiología de referencia:
  // - N: demanda moderada-alta, pero el exceso induce follaje y aborta flor.
  // - P: starter crítico en establecimiento (anclaje post-trasplante).
  // - K: pico en llenado; cuello real de calidad (Brix, firmeza, color, rajado).
  // - Balance N:K y disponibilidad estable de Ca (ligada a K) son los drivers
  //   principales de BER, rajado y calidad postcosecha.
  static String _tomatoPracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? stagePressure01,
    StageTargets? targets,
  ) {
    final isGerm = stage.contains('germin');
    final isEstablishment = stage.contains('establec');
    final isVeg = stage.contains('vegetativo') || stage.contains('vegetative');
    final isFlowering = stage.contains('floracion') || stage.contains('flor');
    final isFruitSet = stage.contains('cuajado') || stage.contains('fruitset');
    final isFilling = stage.contains('llenado');
    final isHarvest = stage.contains('progresiv') || stage.contains('harvest');
    final isLate = _isLateStage(stage);
    final isCritical = isFlowering || isFruitSet;

    // Guard de fin de ciclo / senescencia: prioritario sobre cualquier
    // mensaje productivo. Cosecha progresiva NO entra aquí (no es late).
    if (isLate) {
      return _hortalizaLateCycleMessage(nutrient: nutrient, label: label);
    }

    final profileHint = targets?.plannerHintFor(nutrient);
    final windowLabel = targets?.windowLabelFor(nutrient);

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isCritical) {
            return 'Traes nitrógeno de más justo en floración/cuajado. Riesgo alto de que se te caiga la flor, el fruto salga blando y el potasio ya no entre. Corta las aplicaciones de nitrógeno.';
          }
          if (isVeg) {
            return 'La planta está echando pura hoja por exceso de nitrógeno. Si no lo frenas ahora, la floración y el cuajado se van a resentir.';
          }
          return 'Pausa el nitrógeno. El tomate ya tiene con qué y seguir metiéndole solo desbalancea la planta.';
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isGerm || isEstablishment) {
            return 'Arranque correcto. Al tomate le conviene poco nitrógeno al inicio: deja que el fósforo haga el trabajo de que la raíz agarre.';
          }
          if (isVeg) {
            return 'Nitrógeno en su punto para armar follaje sin disparar crecimiento loco.';
          }
          if (isCritical || isFilling) {
            return 'Nitrógeno equilibrado en la ventana crítica. No le cargues más: aquí lo que manda es el calcio y el potasio.';
          }
          return 'Nitrógeno estable para esta etapa del tomate.';
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isVeg && (stagePressure01 ?? 0) > 0.5) {
            return 'El nitrógeno todavía alcanza, pero ya viene la etapa de follaje fuerte. Ten listo el plan para no llegar corto a floración.';
          }
          return 'Por ahora el nitrógeno no es la urgencia. Enfócate en fósforo al pegue del trasplante, o en potasio y calcio cuando haya flor y fruto.';
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isVeg) {
            return 'El nitrógeno va bajando. Revisa el plan antes de entrar a floración con la planta corta.';
          }
          if (isCritical) {
            return 'El nitrógeno está bajando en flor/cuajado. Un apoyo chico sí ayuda, pero NADA de cargas fuertes: un jalón alto aquí te tumba la flor.';
          }
          if (isFilling || isHarvest) {
            return 'El nitrógeno va a la baja; en llenado es lo esperado. Mejor acompaña con potasio fuerte, no persigas el nitrógeno.';
          }
          return 'El nitrógeno va bajando. Vigila según la etapa.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return 'El nitrógeno está bajo pero el ciclo ya está cerrando. Guarda la lectura para planear el próximo trasplante.';
          }
          if (isGerm || isEstablishment) {
            return 'Acompaña con un poquito de nitrógeno como arranque. En tomate no se empuja: solo se complementa el fósforo inicial con un toque.';
          }
          if (isVeg) {
            return 'Tomate en vegetativo con nitrógeno corto. Apóyalo con calma cuidando el balance con potasio: pasarte hoy se paga en la floración con flor caída.';
          }
          if (isCritical) {
            return 'Falta nitrógeno en flor/cuajado. Aplícalo POCO Y SEGUIDO en el riego (no de un solo golpe): una dosis alta aquí tumba la flor.';
          }
          if (isFilling) {
            return 'Nitrógeno bajo en llenado. Aporte MÍNIMO: aquí el verdadero cuello es el potasio, no el nitrógeno.';
          }
          if (isHarvest) {
            return 'Nitrógeno bajo en cosecha progresiva. Mantén aportes de sostén metidos en cada riego, nada de golpes secos.';
          }
          return 'Falta nitrógeno. Corrige con calma: el tomate no responde bien a picos.';
        }
        return profileHint ??
            windowLabel ??
            'Vigila el nitrógeno con criterio según la etapa del tomate.';

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return 'Fósforo de sobra. Pausa la aplicación: con exceso la planta batalla para absorber zinc y fierro, y el fruto pierde color.';
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isEstablishment || isGerm) {
            return 'Buen nivel de fósforo para que la raíz agarre y la planta supere el jalón del trasplante.';
          }
          if (isCritical) {
            return 'Fósforo en rango para sostener la energía de flor y fruto. No hace falta empujar más.';
          }
          return 'El fósforo está en nivel suficiente para esta etapa.';
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          return (isEstablishment || isGerm)
              ? 'El fósforo todavía acompaña el arranque, pero no lo descuides: si se queda corto después del trasplante, la floración se retrasa.'
              : 'El fósforo no es la prioridad en esta etapa del tomate.';
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isEstablishment) {
            return 'El fósforo se está quedando corto justo donde más importa: que la raíz agarre después del trasplante. Conviene corregir ya.';
          }
          return 'El fósforo va bajando. En tomate el riesgo real de quedarse corto está en el pegue, no al final.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return 'Fósforo bajo pero el ciclo cierra. Úsalo para planear el arrancador del próximo cultivo.';
          }
          if (isEstablishment || isGerm) {
            return 'Fósforo bajo después del trasplante: crítico. Aplícalo al pie de la planta como arrancador (fosfato monoamónico o diamónico) para que la raíz agarre.';
          }
          if (isVeg) {
            return 'Fósforo bajo en vegetativo. Corrígelo, pero la respuesta será moderada: la ventana donde el fósforo rinde fuerte ya pasó.';
          }
          if (isCritical || isFilling || isHarvest) {
            return 'Fósforo bajo en etapa reproductiva. Úsalo como corrección de base, no como rescate: la planta responde lento.';
          }
          return 'Fósforo bajo. Conviene corregirlo después del trasplante; más tarde rinde menos.';
        }
        return profileHint ??
            windowLabel ??
            'Revisa el fósforo del tomate, sobre todo después del trasplante.';

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isFilling || isHarvest) {
            return 'Potasio muy alto en llenado. Cuida el balance con calcio: demasiado potasio BLOQUEA la entrada de calcio y te saca pudrición en la punta del fruto.';
          }
          return 'Potasio alto. Pausa el potasio solo y revisa el balance con calcio y magnesio.';
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isFilling || isHarvest) {
            return 'Potasio en su punto justo donde más pesa en tomate: firmeza, color, dulzor del fruto y aguante después de cortar. Excelente.';
          }
          if (isCritical) {
            return 'Potasio en rango para flor/cuajado. Mantenlo disponible siempre: si baja aquí te arranca pudrición en la punta del fruto.';
          }
          return 'Niveles de potasio estables para esta etapa del tomate.';
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isVeg && (stagePressure01 ?? 0) > 0.5) {
            return 'El potasio todavía alcanza, pero ya viene flor/cuajado y la demanda se dispara. Prepara reservas.';
          }
          return 'El potasio no urge ahora, pero vigílalo: en tomate es el nutriente que más pide acumulado.';
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isCritical) {
            return 'Potasio bajando en flor/cuajado. Riesgo real de cuajado débil y pudrición en la punta del fruto. Corrige ya manteniendo humedad pareja en el suelo.';
          }
          if (isFilling) {
            return 'Potasio bajando en LLENADO: la peor etapa para que esto pase. Afecta directo calidad, dulzor, firmeza y color.';
          }
          if (isHarvest) {
            return 'Potasio bajando en cosecha progresiva. Sin potasio constante hay rajado y frutos blandos. Corrige sin jalones bruscos.';
          }
          return 'El potasio va bajando. Vigila: el tomate es muy demandante de potasio.';
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return 'Potasio bajo pero el ciclo cierra. Anótalo para ajustar la base del próximo trasplante.';
          }
          if (isGerm || isEstablishment) {
            return 'Apoyo moderado de potasio en arranque. La demanda fuerte llega más adelante.';
          }
          if (isVeg) {
            return 'Potasio bajo en vegetativo. Refuerza metiéndolo en el riego para llegar a floración sin cuello.';
          }
          if (isCritical) {
            return 'Potasio BAJO en flor/cuajado. Urge reforzar en el riego para evitar cuajado débil, caída de flor y pudrición en la punta del fruto.';
          }
          if (isFilling) {
            return 'Potasio BAJO en pleno llenado: la ventana más cara de fallar. Aplica potasio soluble metido en el riego (nada de golpes secos) con humedad pareja en el suelo.';
          }
          if (isHarvest) {
            return 'Potasio bajo en cosecha progresiva. Sostén constante en el riego para evitar rajado de fruto y caída de calidad.';
          }
          return 'Potasio bajo. Corrígelo metiéndolo poco a poco en el riego: el tomate no aguanta golpes fuertes de sales.';
        }
        return profileHint ??
            windowLabel ??
            'Vigila el potasio: es el nutriente cuello en tomate.';

      default:
        return 'Revisa el manejo de nutrientes del tomate.';
    }
  }

  // ── GENÉRICO ──────────────────────────────────────────────────────────────
  static String _chiliPracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? stagePressure01,
    StageTargets? targets,
    ChiliNutritionModifier? modifier,
  ) {
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
    final isCritical = isFlowering || isFruitSet;

    // Guard de fin de ciclo / senescencia: corta antes de mensajes productivos
    // y no anexa el caution del perfil para no confundir con cortes continuos.
    if (isLate) {
      return _hortalizaLateCycleMessage(nutrient: nutrient, label: label);
    }

    final profileHint = targets?.shortGuidanceFor(nutrient);
    final windowLabel = targets?.windowLabelFor(nutrient);
    final profileCaution = modifier?.practicalCaution(nutrient, stage);
    String withModifier(String base) {
      if (profileCaution == null || profileCaution.trim().isEmpty) {
        return base;
      }
      return '$base ${profileCaution.trim()}';
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isCritical || isFilling || isHarvest) {
            return withModifier(
              'Nitrogeno alto en etapa reproductiva. Frena el N: el chile puede tirar flor, cuajar mal o seguirse yendo a follaje.',
            );
          }
          return withModifier(
            'Nitrogeno alto. Pausa aplicaciones y revisa balance con K y Ca antes de floracion.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isVeg) {
            return withModifier('N en rango para sostener follaje sin exceso.');
          }
          if (isCritical) {
            return withModifier('N equilibrado para proteger flor y amarre.');
          }
          return withModifier('N suficiente para la etapa actual del chile.');
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          return withModifier(
            'Por ahora el N no es la prioridad; vigila que no baje antes de entrar a floracion.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isVeg) {
            return withModifier(
              'N va bajando en vegetativo. Corrige con mesura para no llegar a floracion con exceso.',
            );
          }
          if (isCritical) {
            return withModifier(
              'N empieza a faltar en flor/amarre. Corrige fraccionado, sin jalones fuertes.',
            );
          }
          return withModifier(
            'N va bajando. Ajusta sin perseguir follaje de mas.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return withModifier(
              'N bajo pero el ciclo cierra. Usalo para planear el siguiente cultivo.',
            );
          }
          if (isGerm || isEstablishment) {
            return withModifier(
              'N bajo en arranque. Corrige moderado, priorizando raiz, P y humedad estable.',
            );
          }
          if (isCritical) {
            return withModifier(
              'N bajo en flor/amarre. Aplica en eventos cortos; una dosis fuerte puede tumbar flor.',
            );
          }
          return withModifier(
            'N bajo para esta etapa. Corrige fraccionado y revisa que no haya bloqueo por salinidad o humedad.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Vigila el nitrogeno del chile.',
        );

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return withModifier(
            'Fosforo alto. Pausa P: el exceso puede bloquear micronutrientes y no mejora el cuaje.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isGerm || isEstablishment) {
            return withModifier(
              'Buen P para pegue y raiz. Esta es la ventana donde mas rinde.',
            );
          }
          return withModifier(
            'P suficiente para soporte fisiologico de la etapa.',
          );
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          return withModifier(
            (isGerm || isEstablishment)
                ? 'P aun acompana el arranque, pero no lo descuides si el trasplante viene lento.'
                : 'P no es la prioridad principal en esta etapa del chile.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isGerm || isEstablishment) {
            return withModifier(
              'P se esta quedando corto justo en pegue y raiz. Conviene corregir temprano.',
            );
          }
          return withModifier(
            'P va bajando. Corrige como base si la lectura o analisis lo confirma.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return withModifier(
              'P bajo pero el ciclo cierra. Guarda el dato para el arrancador del siguiente ciclo.',
            );
          }
          if (isGerm || isEstablishment) {
            return withModifier(
              'P bajo en arranque. Corrige cerca de raiz para evitar retraso de floracion.',
            );
          }
          if (isCritical) {
            return withModifier(
              'P bajo en ventana reproductiva. Corrige como soporte, pero no esperes una respuesta de rescate rapido.',
            );
          }
          return withModifier(
            'P bajo. Conviene ajustar la base del cultivo y revisar pH para disponibilidad.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el fosforo del chile.',
        );

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isCritical || isFilling || isHarvest) {
            return withModifier(
              'K muy alto. Cuida el balance con Ca y Mg: demasiado K puede bajar firmeza y calidad de fruto.',
            );
          }
          return withModifier(
            'K alto. Pausa potasio solo y revisa sales totales antes de subir mas.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isFilling || isHarvest) {
            return withModifier(
              'K en rango en la ventana fuerte: buena base para llenado, color y calidad.',
            );
          }
          if (isCritical) {
            return withModifier(
              'K en rango para flor y amarre. Mantener humedad pareja es tan importante como la dosis.',
            );
          }
          return withModifier('K estable para la etapa actual del chile.');
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isVeg && (stagePressure01 ?? 0) > 0.5) {
            return withModifier(
              'K aun alcanza, pero ya viene floracion y amarre. Prepara reserva.',
            );
          }
          return withModifier(
            'K no urge ahora, pero vigilalo: desde amarre domina la demanda.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isCritical) {
            return withModifier(
              'K bajando en flor/amarre. Riesgo de mal cuaje; corrige con humedad pareja y cuidando Ca.',
            );
          }
          if (isFilling || isHarvest) {
            return withModifier(
              'K bajando en llenado/cosecha. Esto pega directo en peso, firmeza y continuidad de cortes.',
            );
          }
          return withModifier(
            'K va bajando. Refuerza antes de entrar a la ventana reproductiva.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return withModifier(
              'K bajo pero el ciclo cierra. Anotalo para ajustar la base del siguiente ciclo.',
            );
          }
          if (isGerm || isEstablishment) {
            return withModifier(
              'K bajo en arranque. Apoya moderado sin subir sales.',
            );
          }
          if (isCritical) {
            return withModifier(
              'K bajo en flor/amarre. Urge reforzar, pero poco a poco para no meter golpe salino.',
            );
          }
          if (isFilling || isHarvest) {
            return withModifier(
              'K bajo en llenado/cosecha: ventana cara de fallar. Refuerza soluble, fraccionado y con humedad estable.',
            );
          }
          return withModifier(
            'K bajo. Corrige antes de floracion para no entrar a cuajado con el tanque vacio.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Vigila el potasio del chile.',
        );

      default:
        return 'Revisa el manejo de nutrientes del chile.';
    }
  }

  static String _eggplantPracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? stagePressure01,
    StageTargets? targets,
    EggplantNutritionModifier? modifier,
  ) {
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
    final isCritical = isFlowering || isFruitSet;

    if (isLate) {
      return _hortalizaLateCycleMessage(nutrient: nutrient, label: label);
    }

    final windowLabel = targets?.windowLabelFor(nutrient);
    final profileHint = targets?.plannerHintFor(nutrient);

    String withModifier(String base) {
      final caution = modifier?.practicalCaution(nutrient, stage);
      if (caution == null || caution.trim().isEmpty) return base;
      return '$base $caution';
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isCritical || isFilling || isHarvest) {
            return withModifier(
              'N alto. En berenjena esto puede vegetarla, tirar flor o bajar calidad; pausa N y revisa CE.',
            );
          }
          return withModifier(
            'N alto. Pausa nitrogeno y revisa si el vigor ya esta excesivo.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isVeg) {
            return withModifier(
              'N en rango para construir hoja activa sin exagerar vigor.',
            );
          }
          if (isFilling || isHarvest) {
            return withModifier(
              'N suficiente. En esta ventana ya no conviene perseguir follaje.',
            );
          }
          return withModifier('N estable para la etapa actual de berenjena.');
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isVeg && (stagePressure01 ?? 0) > 0.5) {
            return withModifier(
              'N aun alcanza, pero viene floracion. Prepara correccion suave si la tendencia cae.',
            );
          }
          return withModifier(
            'N no urge ahora; vigila que no caiga antes de floracion.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isCritical) {
            return withModifier(
              'N va bajando en flor/cuajado. Corrige solo fraccionado para no vegetarla.',
            );
          }
          if (isFilling || isHarvest) {
            return withModifier(
              'N bajando en llenado/cosecha. Apoya moderado si la planta pierde hoja funcional.',
            );
          }
          return withModifier(
            'N empieza a bajar. Ajusta antes de entrar a la ventana reproductiva.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return withModifier(
              'N bajo pero el ciclo cierra. Guarda el dato para el siguiente plan.',
            );
          }
          if (isGerm || isEstablishment) {
            return withModifier(
              'N bajo en arranque. Corrige moderado; no subas sales cerca de raiz joven.',
            );
          }
          if (isCritical) {
            return withModifier(
              'N bajo en flor/cuajado. Corrige con mucho fraccionamiento y estabilidad de riego.',
            );
          }
          return withModifier(
            'N bajo. Conviene corregir para sostener hoja activa y entrar fuerte a floracion.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el nitrogeno de la berenjena.',
        );

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return withModifier(
            'P alto. Evita seguir aplicando y revisa pH; mas P no corrige cuaje si el problema es agua, calor o raiz.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isEstablishment) {
            return withModifier('P en rango para pegue y raiz.');
          }
          return withModifier('P estable como soporte de la etapa.');
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          return withModifier(
            'P no urge, pero confirma disponibilidad si pH esta fuera de rango.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isGerm || isEstablishment) {
            return withModifier(
              'P se esta quedando corto justo en pegue y raiz. Conviene corregir temprano.',
            );
          }
          return withModifier(
            'P va bajando. Corrige como base si la lectura o analisis lo confirma.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return withModifier(
              'P bajo pero el ciclo cierra. Guarda el dato para el arrancador del siguiente ciclo.',
            );
          }
          if (isGerm || isEstablishment) {
            return withModifier(
              'P bajo en arranque. Corrige cerca de raiz para evitar retraso de floracion.',
            );
          }
          if (isCritical) {
            return withModifier(
              'P bajo en ventana reproductiva. Corrige como soporte; no lo trates como rescate rapido.',
            );
          }
          return withModifier(
            'P bajo. Ajusta la base y revisa pH para disponibilidad real.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el fosforo de la berenjena.',
        );

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isCritical || isFilling || isHarvest) {
            return withModifier(
              'K muy alto. Cuida balance con Ca/Mg y CE: demasiado K puede marcar fruto y bajar firmeza.',
            );
          }
          return withModifier(
            'K alto. Pausa potasio solo y revisa sales totales antes de subir mas.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isFilling || isHarvest) {
            return withModifier(
              'K en rango en la ventana fuerte: buena base para llenado, brillo y firmeza.',
            );
          }
          if (isCritical) {
            return withModifier(
              'K en rango para flor y amarre. Mantener humedad pareja es tan importante como la dosis.',
            );
          }
          return withModifier('K estable para la etapa actual de berenjena.');
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isVeg && (stagePressure01 ?? 0) > 0.5) {
            return withModifier(
              'K aun alcanza, pero ya viene floracion y amarre. Prepara reserva.',
            );
          }
          return withModifier(
            'K no urge ahora, pero vigilalo: desde amarre domina la demanda.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isCritical) {
            return withModifier(
              'K bajando en flor/amarre. Riesgo de mal cuaje; corrige con humedad pareja y cuidando Ca/Mg.',
            );
          }
          if (isFilling || isHarvest) {
            return withModifier(
              'K bajando en llenado/cosecha. Esto pega directo en peso, brillo y continuidad de cortes.',
            );
          }
          return withModifier(
            'K va bajando. Refuerza antes de entrar a la ventana reproductiva.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return withModifier(
              'K bajo pero el ciclo cierra. Anotalo para ajustar la base del siguiente ciclo.',
            );
          }
          if (isGerm || isEstablishment) {
            return withModifier(
              'K bajo en arranque. Apoya moderado sin subir sales.',
            );
          }
          if (isCritical) {
            return withModifier(
              'K bajo en flor/amarre. Urge reforzar, pero poco a poco para no meter golpe salino.',
            );
          }
          if (isFilling || isHarvest) {
            return withModifier(
              'K bajo en llenado/cosecha: ventana cara de fallar. Refuerza soluble, fraccionado y con humedad estable.',
            );
          }
          return withModifier(
            'K bajo. Corrige antes de floracion para no entrar a cuajado con el tanque vacio.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Vigila el potasio de la berenjena.',
        );

      default:
        return 'Revisa el manejo de nutrientes de la berenjena.';
    }
  }

  static String _squashPracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? stagePressure01,
    StageTargets? targets,
    SquashNutritionModifier? modifier,
  ) {
    final isGerm = stage.contains('germin');
    final isEstablishment =
        stage.contains('establec') || stage.contains('emerg');
    final isVeg = stage.contains('vegetativo') || stage.contains('vegetative');
    final isFlowering = stage.contains('floracion') || stage.contains('flor');
    final isFruitSet =
        stage.contains('cuajado') ||
        stage.contains('amarre') ||
        stage.contains('fruitset') ||
        stage.contains('poliniz');
    final isFilling = stage.contains('llenado') || stage.contains('fill');
    final isHarvest = stage.contains('progresiv') || stage.contains('harvest');
    final isLate = _isLateStage(stage);
    final isCritical = isFlowering || isFruitSet;
    final isProduction = isCritical || isFilling || isHarvest;

    // Guard de fin de ciclo / senescencia. En calabaza se anexa la frase del
    // perfil (p.ej. "Calabacita en cierre: ...") porque el perfil sí tiene
    // un mensaje específico de cierre por tipo (CA-01..CA-07, CA-GEN).
    if (isLate) {
      final base = _hortalizaLateCycleMessage(nutrient: nutrient, label: label);
      final caution = modifier?.practicalCaution(nutrient, stage);
      if (caution == null || caution.trim().isEmpty) return base;
      return '$base ${caution.trim()}';
    }

    final windowLabel = targets?.windowLabelFor(nutrient);
    final profileHint = targets?.plannerHintFor(nutrient);

    String withModifier(String base) {
      final caution = modifier?.practicalCaution(nutrient, stage);
      if (caution == null || caution.trim().isEmpty) return base;
      return '$base $caution';
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isProduction) {
            return withModifier(
              'N alto. En calabaza puede empujar guia y hoja cuando flor, amarre o pepita necesitan equilibrio; pausa N y revisa CE.',
            );
          }
          return withModifier(
            'N alto. Pausa nitrogeno y confirma si el vigor ya esta excesivo.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isFilling || isHarvest) {
            return withModifier(
              'N suficiente. En esta ventana no conviene perseguir follaje; cuida K, agua y sanidad foliar.',
            );
          }
          return withModifier('N estable para la etapa actual de calabaza.');
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isVeg && (stagePressure01 ?? 0) > 0.5) {
            return withModifier(
              'N aun alcanza, pero viene floracion. Prepara correccion suave si la tendencia cae.',
            );
          }
          return withModifier(
            'N no urge ahora; vigila que no llegue alto a floracion.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isCritical) {
            return withModifier(
              'N va bajando en flor/cuajado. Corrige solo fraccionado para no perder equilibrio de flor y amarre.',
            );
          }
          if (isFilling || isHarvest) {
            return withModifier(
              'N bajando en llenado/cosecha. Apoya moderado solo si la planta pierde hoja funcional.',
            );
          }
          return withModifier(
            'N empieza a bajar. Ajusta antes de que floracion y cuajado suban la demanda.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return withModifier(
              'N bajo pero el ciclo cierra. Guarda el dato para la base del siguiente ciclo.',
            );
          }
          if (isGerm || isEstablishment) {
            return withModifier(
              'N bajo en arranque. Corrige moderado; raiz joven y salinidad importan mas que empujar guia.',
            );
          }
          if (isCritical) {
            return withModifier(
              'N bajo en flor/cuajado. Corrige con fraccionamiento y riego estable, sin disparar follaje.',
            );
          }
          return withModifier(
            'N bajo. Conviene corregir para sostener hoja activa sin llegar pasado a floracion.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el nitrogeno de la calabaza.',
        );

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return withModifier(
            'P alto. Evita seguir aplicando; mas P no corrige polinizacion, agua o raiz limitada.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isEstablishment) {
            return withModifier('P en rango para pegue, raiz y arranque.');
          }
          return withModifier('P estable como soporte de la etapa.');
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          return withModifier(
            'P no urge, pero confirma disponibilidad si pH esta fuera de rango.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isGerm || isEstablishment) {
            return withModifier(
              'P se esta quedando corto justo en raiz. Conviene corregir temprano.',
            );
          }
          return withModifier(
            'P va bajando. Corrige como base si la lectura lo confirma; no es rescate tardio.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return withModifier(
              'P bajo pero el ciclo cierra. Usalo para ajustar el arrancador del siguiente ciclo.',
            );
          }
          if (isGerm || isEstablishment) {
            return withModifier(
              'P bajo en arranque. Corrige cerca de raiz para evitar retraso de floracion.',
            );
          }
          if (isCritical) {
            return withModifier(
              'P bajo en ventana reproductiva. Corrige como soporte de energia, sin esperar efecto inmediato en cuaje.',
            );
          }
          return withModifier(
            'P bajo. Ajusta la base y revisa pH para disponibilidad real.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el fosforo de la calabaza.',
        );

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isProduction) {
            return withModifier(
              'K muy alto. Pausa potasio y revisa CE; exceso de sales tambien tumba flor, amarre y calidad.',
            );
          }
          return withModifier(
            'K alto. Pausa potasio solo y revisa sales totales antes de subir mas.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isCritical) {
            return withModifier(
              'K en rango para flor y amarre. Mantener humedad pareja y polinizacion activa es igual de importante.',
            );
          }
          if (isFilling || isHarvest) {
            return withModifier(
              'K en rango en la ventana fuerte: buena base para llenado, firmeza o pepita.',
            );
          }
          return withModifier('K estable para la etapa actual de calabaza.');
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isVeg && (stagePressure01 ?? 0) > 0.5) {
            return withModifier(
              'K aun alcanza, pero ya viene floracion y amarre. Prepara reserva.',
            );
          }
          return withModifier(
            'K no urge ahora, pero vigilalo: desde cuajado domina la demanda.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isCritical) {
            return withModifier(
              'K bajando en flor/amarre. Riesgo de mal cuaje; corrige con humedad pareja y buena polinizacion.',
            );
          }
          if (isFilling || isHarvest) {
            return withModifier(
              'K bajando en llenado/cosecha. Esto pega directo en peso, firmeza y pepita.',
            );
          }
          return withModifier(
            'K va bajando. Refuerza antes de entrar a cuajado y llenado.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended) {
          if (isLate) {
            return withModifier(
              'K bajo pero el ciclo cierra. Anotalo para ajustar la base del siguiente ciclo.',
            );
          }
          if (isGerm || isEstablishment) {
            return withModifier(
              'K bajo en arranque. Apoya moderado sin subir sales.',
            );
          }
          if (isCritical) {
            return withModifier(
              'K bajo en flor/cuajado. Urge reforzar fraccionado y cuidar agua para no perder amarre.',
            );
          }
          if (isFilling || isHarvest) {
            return withModifier(
              'K bajo en llenado/cosecha: ventana cara de fallar. Refuerza fraccionado y con humedad estable.',
            );
          }
          return withModifier(
            'K bajo. Corrige antes de floracion para no entrar a cuajado con reserva corta.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Vigila el potasio de la calabaza.',
        );

      default:
        return 'Revisa el manejo de nutrientes de la calabaza.';
    }
  }

  // ── LECHUGA ───────────────────────────────────────────────────────────────
  // Hortaliza de hoja: la fertilizacion favorece hoja firme, turgente y
  // sana, no solo crecimiento rapido. Reglas conservadoras: N a la baja
  // cerca de cosecha, K de apoyo a turgencia en cabeza/cosecha, P clave en
  // establecimiento. Sin dosis cerradas.
  static String _lettucePracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? stagePressure01,
    StageTargets? targets,
    LettuceNutritionModifier? modifier,
  ) {
    final isGerm = stage.contains('germin');
    final isEstablishment =
        stage.contains('establec') || stage.contains('emerg');
    final isVeg = stage.contains('vegetativo') || stage.contains('vegetative');
    final isHead = stage.contains('cabeza') || stage.contains('formacion');
    final isHarvest = stage.contains('cosecha') || stage.contains('ventana');
    // `sobremadurez` no lo detecta _isLateStage; se cubre explicitamente.
    final isLate = stage.contains('sobremadur') || _isLateStage(stage);
    final isQualityWindow = isHead || isHarvest;

    // Guard de cierre de ciclo: prioritario sobre cualquier mensaje
    // productivo; se anexa la frase de cierre del perfil.
    if (isLate) {
      final base = _hortalizaLateCycleMessage(nutrient: nutrient, label: label);
      final caution = modifier?.practicalCaution(nutrient, stage);
      if (caution == null || caution.trim().isEmpty) return base;
      return '$base ${caution.trim()}';
    }

    final windowLabel = targets?.windowLabelFor(nutrient);
    final profileHint = targets?.plannerHintFor(nutrient);

    String withModifier(String base) {
      final caution = modifier?.practicalCaution(nutrient, stage);
      if (caution == null || caution.trim().isEmpty) return base;
      return '$base $caution';
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isQualityWindow) {
            return withModifier(
              'N alto cerca de cabeza o cosecha. En lechuga ablanda la hoja y sube tip burn y Botrytis; pausa N y revisa CE.',
            );
          }
          return withModifier(
            'N alto. Pausa nitrogeno y confirma si el follaje ya viene blando.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority) {
          if (isHarvest) {
            return withModifier(
              'N suficiente. Cerca de corte no conviene empujar crecimiento tierno; prioriza turgencia y sanidad.',
            );
          }
          return withModifier('N estable para la etapa actual de la lechuga.');
        }
        if (label == NutrientPriorityLabel.lowPriority) {
          if (isVeg && (stagePressure01 ?? 0) > 0.5) {
            return withModifier(
              'N aun alcanza, pero la expansion foliar pide mas demanda. Prepara revision suave si la tendencia cae.',
            );
          }
          return withModifier(
            'N no urge ahora; vigila que no llegue alto a cabeza ni a cosecha.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isHarvest) {
            return withModifier(
              'N va bajando cerca de cosecha. No empujes: prioriza calidad, turgencia y corte oportuno.',
            );
          }
          if (isVeg) {
            return withModifier(
              'N empieza a bajar en plena expansion foliar. Valora ajuste moderado para no frenar la hoja.',
            );
          }
          return withModifier(
            'N empieza a bajar. Revisa antes de que se note en el tamano de hoja.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.reviewManagement) {
          if (isGerm) {
            return withModifier(
              'N bajo en germinacion. No empujar N: la semilla usa reservas y las sales bajas mandan.',
            );
          }
          if (isEstablishment) {
            return withModifier(
              'N bajo en establecimiento. Revisa con cautela; raiz superficial y P pesan mas que empujar hoja.',
            );
          }
          if (isHarvest) {
            return withModifier(
              'N bajo cerca de cosecha. Valida solo si la hoja pierde vigor; BIO-G no recomienda N fuerte tardio.',
            );
          }
          if (isVeg) {
            return withModifier(
              'N bajo en expansion foliar. Conviene revisar manejo para sostener el crecimiento de hoja.',
            );
          }
          return withModifier(
            'N bajo. Conviene revisar balance sin excederse para no ablandar la hoja.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el nitrogeno de la lechuga.',
        );

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return withModifier(
            'P alto. Evita seguir aplicando; el exceso de P puede antagonizar Zn y Fe.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return withModifier(
            'P suficiente. En lechuga el P pesa sobre todo en el establecimiento de la raiz.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.reviewManagement ||
            label == NutrientPriorityLabel.mediumPriority) {
          if (isEstablishment || isGerm) {
            return withModifier(
              'P bajo en el arranque. Es la ventana clave: el P apoya la raiz superficial joven.',
            );
          }
          return withModifier(
            'P bajo. Revisa una correccion moderada con criterio tecnico; su mayor retorno estuvo en el establecimiento.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el fosforo de la lechuga.',
        );

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return withModifier(
            'K alto. Pausa potasio; el exceso puede antagonizar Ca y Mg.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return withModifier(
            'K suficiente para sostener turgencia y calidad de hoja.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.reviewManagement ||
            label == NutrientPriorityLabel.mediumPriority) {
          if (isQualityWindow) {
            return withModifier(
              'K bajo en cabeza o cosecha. Revisa balance junto con humedad pareja: el K sostiene turgencia, firmeza y calidad.',
            );
          }
          return withModifier(
            'K bajo. Valora apoyo moderado para preparar la turgencia de cara a la cabeza.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el potasio de la lechuga.',
        );

      case AgroMetricKey.soilMoisture:
      case AgroMetricKey.soilTemp:
      case AgroMetricKey.ph:
      case AgroMetricKey.ec:
      case AgroMetricKey.resistance:
        return withModifier('Revisa el manejo de nutrientes de la lechuga.');
    }
  }

  // Espinaca: hortaliza de hoja. N controlado, P temprano, K para
  // turgencia/calidad; no dosis cerradas ni empuje tardio.
  static String _spinachPracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? stagePressure01,
    StageTargets? targets,
    SpinachNutritionModifier? modifier,
  ) {
    final isGerm = stage.contains('germin');
    final isEstablishment =
        stage.contains('establec') || stage.contains('emerg');
    final isVeg =
        stage.contains('vegetativo') ||
        stage.contains('expansion') ||
        stage.contains('foliar');
    final isHarvest =
        stage.contains('madurez') ||
        stage.contains('cosecha') ||
        stage.contains('ventana');
    final isLate =
        stage.contains('perdida') ||
        stage.contains('espig') ||
        stage.contains('bolting') ||
        stage.contains('senesc') ||
        _isLateStage(stage);

    if (isLate) {
      final base = _hortalizaLateCycleMessage(nutrient: nutrient, label: label);
      final caution = modifier?.practicalCaution(nutrient, stage);
      if (caution == null || caution.trim().isEmpty) return base;
      return '$base ${caution.trim()}';
    }

    final windowLabel = targets?.windowLabelFor(nutrient);
    final profileHint = targets?.plannerHintFor(nutrient);

    String withModifier(String base) {
      final caution = modifier?.practicalCaution(nutrient, stage);
      if (caution == null || caution.trim().isEmpty) return base;
      return '$base $caution';
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isHarvest) {
            return withModifier(
              'N alto cerca de corte. En espinaca puede ablandar hoja, subir nitratos y bajar vida de anaquel; pausa N y revisa CE.',
            );
          }
          return withModifier(
            'N alto. Pausa nitrogeno y confirma si el follaje ya viene blando o la CE subio.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          if (isHarvest) {
            return withModifier(
              'N suficiente. Cerca de corte no conviene empujar crecimiento tierno; prioriza turgencia y sanidad.',
            );
          }
          return withModifier(
            'N en zona manejable para espinaca; vigila agua y salinidad.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isHarvest) {
            return withModifier(
              'N va bajando cerca de cosecha. No empujes por rutina: prioriza calidad y corte oportuno.',
            );
          }
          if (isVeg) {
            return withModifier(
              'N empieza a bajar en expansion foliar. Revisa manejo con cautela y confirma humedad estable.',
            );
          }
          return withModifier('N empieza a bajar. Vigila hoja y tendencia.');
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.reviewManagement) {
          if (isGerm) {
            return withModifier(
              'N bajo en germinacion. No empujar N: la semilla usa reservas y las sales bajas mandan.',
            );
          }
          if (isEstablishment) {
            return withModifier(
              'N bajo en establecimiento. Primero confirma raiz, humedad y P; el N fuerte en planta joven no es la prioridad.',
            );
          }
          if (isHarvest) {
            return withModifier(
              'N bajo cerca de cosecha. Valida solo si la hoja pierde vigor; BIO-G no recomienda N fuerte tardio.',
            );
          }
          return withModifier(
            'N bajo en expansion de hoja. Revisa manejo sin excederte para no ablandar tejido.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el nitrogeno de la espinaca.',
        );

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return withModifier(
            'P alto. Pausa fosforo; su exceso puede bloquear micronutrientes y no mejora la hoja al final.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return withModifier(
            'P suficiente. En espinaca pesa sobre todo en raiz y establecimiento.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.reviewManagement ||
            label == NutrientPriorityLabel.mediumPriority) {
          if (isEstablishment || isGerm) {
            return withModifier(
              'P bajo en arranque. Es la ventana clave para raiz temprana, especialmente en suelo fresco.',
            );
          }
          return withModifier(
            'P bajo fuera del arranque. Revisa con criterio tecnico; agua, CE y hoja comercial siguen mandando.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el fosforo de la espinaca.',
        );

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return withModifier(
            'K alto. Pausa potasio y revisa CE; en espinaca el golpe salino puede bajar turgencia.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return withModifier(
            'K suficiente para sostener turgencia y calidad de hoja.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.reviewManagement ||
            label == NutrientPriorityLabel.mediumPriority) {
          if (isHarvest || isVeg) {
            return withModifier(
              'K bajo en etapa de calidad. Revisa balance con humedad pareja: K ayuda a turgencia, pero no compensa salinidad ni falta de agua.',
            );
          }
          return withModifier(
            'K bajo. Valora apoyo moderado para preparar turgencia de hoja.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el potasio de la espinaca.',
        );

      case AgroMetricKey.soilMoisture:
      case AgroMetricKey.soilTemp:
      case AgroMetricKey.ph:
      case AgroMetricKey.ec:
      case AgroMetricKey.resistance:
        return withModifier('Revisa el manejo de nutrientes de la espinaca.');
    }
  }

  // Cebolla: hortaliza de bulbo. N temprano con control y detener tarde,
  // P para arranque/raiz, K para llenado/calidad; fotoperiodo manda y no
  // se corrige con fertilizante.
  static String _onionPracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? stagePressure01,
    StageTargets? targets,
    OnionNutritionModifier? modifier,
  ) {
    final isGerm = stage.contains('germin');
    final isEstablishment =
        stage.contains('establec') ||
        stage.contains('emergencia') ||
        stage.contains('emerg');
    final isVeg = stage.contains('vegetativo');
    final isInduction = stage.contains('induccion');
    final isBulbFill =
        stage.contains('llenado') ||
        stage.contains('iniciobulbo') ||
        stage.contains('bulbo');
    final isLate =
        stage.contains('maduracion') ||
        stage.contains('cosecha') ||
        stage.contains('curado') ||
        stage.contains('espig') ||
        stage.contains('senesc') ||
        _isLateStage(stage);

    if (isLate) {
      final base = _hortalizaLateCycleMessage(nutrient: nutrient, label: label);
      final caution = modifier?.practicalCaution(nutrient, stage);
      if (caution == null || caution.trim().isEmpty) return base;
      return '$base ${caution.trim()}';
    }

    final windowLabel = targets?.windowLabelFor(nutrient);
    final profileHint = targets?.plannerHintFor(nutrient);

    String withModifier(String base) {
      final caution = modifier?.practicalCaution(nutrient, stage);
      if (caution == null || caution.trim().isEmpty) return base;
      return '$base $caution';
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isBulbFill || isInduction) {
            return withModifier(
              'N alto en bulbo. El exceso de N tarde engruesa cuello, retrasa madurez y empeora conservacion; pausa N y revisa CE.',
            );
          }
          return withModifier(
            'N alto. Pausa nitrogeno y confirma si el follaje viene muy verde/blando o la CE subio.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          if (isBulbFill) {
            return withModifier(
              'N suficiente. En llenado no conviene empujar N: prioriza agua pareja y K; el calibre se juega aqui.',
            );
          }
          return withModifier(
            'N en zona manejable para cebolla; vigila agua, salinidad y fotoperiodo.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isInduction || isBulbFill) {
            return withModifier(
              'N va bajando en bulbo. No empujes por rutina: el fotoperiodo y el agua mandan, no mas hoja.',
            );
          }
          return withModifier('N empieza a bajar. Vigila hoja y tendencia.');
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.reviewManagement) {
          if (isGerm) {
            return withModifier(
              'N bajo en germinacion. No empujar N: manda la cama de siembra, humedad fina y baja salinidad.',
            );
          }
          if (isEstablishment) {
            return withModifier(
              'N bajo en establecimiento. Primero confirma raiz, humedad y P; planta joven no necesita N fuerte.',
            );
          }
          if (isVeg) {
            return withModifier(
              'N bajo en desarrollo foliar. La hoja es la fabrica del bulbo; aplica fraccionado sin excederte para no engrosar cuello.',
            );
          }
          return withModifier(
            'N bajo en etapa de bulbo. Valida solo si la hoja pierde vigor; BIO-G no recomienda N fuerte tardio.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el nitrogeno de la cebolla.',
        );

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return withModifier(
            'P alto. Pausa fosforo; su exceso puede bloquear micronutrientes (Zn) y no mejora el bulbo al final.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return withModifier(
            'P suficiente. En cebolla pesa sobre todo en raiz superficial y establecimiento.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.reviewManagement ||
            label == NutrientPriorityLabel.mediumPriority) {
          if (isEstablishment || isGerm) {
            return withModifier(
              'P bajo en arranque. Es la ventana clave para raiz temprana, sobre todo en suelo frio o alcalino; coloca cerca de raiz.',
            );
          }
          return withModifier(
            'P bajo fuera del arranque. Revisa pH y analisis de suelo; agua, CE y fotoperiodo siguen mandando.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el fosforo de la cebolla.',
        );

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return withModifier(
            'K alto. Pausa potasio y revisa CE; en cebolla el golpe salino baja calibre y absorcion de agua.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return withModifier(
            'K suficiente para sostener llenado, firmeza y calidad del bulbo.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.reviewManagement ||
            label == NutrientPriorityLabel.mediumPriority) {
          if (isBulbFill || isInduction) {
            return withModifier(
              'K bajo en llenado de bulbo. Apoya con humedad pareja: el K define calibre y firmeza, pero no compensa salinidad ni falta de agua.',
            );
          }
          return withModifier(
            'K bajo. Valora apoyo moderado para preparar el llenado del bulbo, cuidando CE.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el potasio de la cebolla.',
        );

      case AgroMetricKey.soilMoisture:
      case AgroMetricKey.soilTemp:
      case AgroMetricKey.ph:
      case AgroMetricKey.ec:
      case AgroMetricKey.resistance:
        return withModifier('Revisa el manejo de nutrientes de la cebolla.');
    }
  }

  static String _garlicPracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    double? stagePressure01,
    StageTargets? targets,
    GarlicNutritionModifier? modifier,
  ) {
    final isPlanting =
        stage.contains('plant') ||
        stage.contains('clove') ||
        stage.contains('diente');
    final isEstablishment =
        isPlanting || stage.contains('emerg') || stage.contains('establec');
    final isVeg = stage.contains('veget') || stage.contains('foliar');
    final isVernalization =
        stage.contains('vernal') ||
        stage.contains('frio') ||
        stage.contains('cold');
    final isBulb =
        stage.contains('diferenci') ||
        stage.contains('llenado') ||
        stage.contains('bulb') ||
        stage.contains('bulbo') ||
        stage.contains('fill');
    final isLate =
        stage.contains('maduracion') ||
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
        stage.contains('senesc') ||
        _isLateStage(stage);

    if (isLate) {
      final base = _hortalizaLateCycleMessage(nutrient: nutrient, label: label);
      final caution = modifier?.practicalCaution(nutrient, stage);
      if (caution == null || caution.trim().isEmpty) return base;
      return '$base ${caution.trim()}';
    }

    final windowLabel = targets?.windowLabelFor(nutrient);
    final profileHint = targets?.plannerHintFor(nutrient);

    String withModifier(String base) {
      final caution = modifier?.practicalCaution(nutrient, stage);
      if (caution == null || caution.trim().isEmpty) return base;
      return '$base $caution';
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          if (isVernalization || isBulb) {
            return withModifier(
              'N alto en ajo durante frio/bulbo. Pausa N: aumenta riesgo de vigor tardio, escobeteado, canutos, mala maduracion, pudriciones y curado pobre.',
            );
          }
          return withModifier(
            'N alto. Pausa nitrogeno y confirma CE, humedad, follaje excesivo y sanidad de cuello/bulbo.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          if (isBulb || isVernalization) {
            return withModifier(
              'N suficiente. No uses N para corregir frio insuficiente ni para forzar dientes; cuida agua, CE y K.',
            );
          }
          return withModifier(
            'N en zona manejable para ajo; vigila desarrollo foliar sin empujar vigor de mas.',
          );
        }
        if (label == NutrientPriorityLabel.mediumPriority) {
          if (isVernalization) {
            return withModifier(
              'N va bajando, pero la vernalizacion manda. No corrijas frio con fertilizante; confirma temperatura, agua y sanidad.',
            );
          }
          if (isBulb) {
            return withModifier(
              'N va bajando en bulbo. Maneja con cautela: mas hoja tarde puede bajar calidad y curado.',
            );
          }
          return withModifier(
            'N empieza a bajar. Vigila hoja activa, tendencia y humedad antes de ajustar.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.reviewManagement) {
          if (isEstablishment) {
            return withModifier(
              'N bajo en establecimiento. Primero confirma diente-semilla sano, raiz, humedad y P; evita N fuerte en planta joven.',
            );
          }
          if (isVeg) {
            return withModifier(
              'N bajo en desarrollo foliar. Puede apoyar hoja si va fraccionado y sin exceso; no lo lleves tarde a bulbo.',
            );
          }
          if (isVernalization || isBulb) {
            return withModifier(
              'N bajo en frio/bulbo. Revisa si es deficit real: agua, CE, anoxia, frio y sanidad pueden parecer falta de N.',
            );
          }
          return withModifier(
            'Revisa N con prudencia; en ajo el exceso tarde baja maduracion, curado y rendimiento comercial.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el nitrogeno del ajo.',
        );

      case AgroMetricKey.p:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return withModifier(
            'P alto. Pausa fosforo y confirma pH/analisis; exceso puede bloquear balance y no arregla vernalizacion.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return withModifier(
            'P suficiente. En ajo pesa mas al arranque, raiz y establecimiento del diente.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.reviewManagement ||
            label == NutrientPriorityLabel.mediumPriority) {
          if (isEstablishment) {
            return withModifier(
              'P bajo en arranque. Es la ventana clave para raiz; confirma analisis de suelo, pH y humedad antes de aplicar.',
            );
          }
          return withModifier(
            'P bajo fuera del arranque. Revisa pH y disponibilidad; no sustituye frio, diente sano ni manejo de agua.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el fosforo del ajo.',
        );

      case AgroMetricKey.k:
        if (label == NutrientPriorityLabel.possibleExcess ||
            label == NutrientPriorityLabel.reviewAccumulation) {
          return withModifier(
            'K alto. Pausa potasio y revisa CE/salinidad; en ajo la sal reduce absorcion, calibre y calidad de curado.',
          );
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return withModifier(
            'K suficiente para diferenciacion, llenado, firmeza y calidad de bulbo.',
          );
        }
        if (label == NutrientPriorityLabel.highPriority ||
            label == NutrientPriorityLabel.actionRecommended ||
            label == NutrientPriorityLabel.reviewManagement ||
            label == NutrientPriorityLabel.mediumPriority) {
          if (isBulb || isVernalization) {
            return withModifier(
              'K bajo en diferenciacion/llenado. Puede apoyar firmeza y calibre, pero primero confirma CE baja, agua estable y sanidad de raiz.',
            );
          }
          return withModifier(
            'K bajo. Prepara llenado de bulbo con manejo moderado y CE controlada.',
          );
        }
        return withModifier(
          profileHint ?? windowLabel ?? 'Revisa el potasio del ajo.',
        );

      case AgroMetricKey.soilMoisture:
      case AgroMetricKey.soilTemp:
      case AgroMetricKey.ph:
      case AgroMetricKey.ec:
      case AgroMetricKey.resistance:
        return withModifier('Revisa el manejo de nutrientes del ajo.');
    }
  }

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

    if (_isLettuceCrop(cropKey)) {
      return _lettuceJustification(
        nutrientName: nutrientName,
        rawPpm: rawPpm,
        targets: targets,
        cropKey: cropKey,
        nutrient: nutrient,
        label: label,
      );
    }

    if (_isSpinachCrop(cropKey)) {
      return _spinachJustification(
        nutrientName: nutrientName,
        rawPpm: rawPpm,
        targets: targets,
        cropKey: cropKey,
        nutrient: nutrient,
        label: label,
      );
    }

    if (_isOnionCrop(cropKey)) {
      return _onionJustification(
        nutrientName: nutrientName,
        rawPpm: rawPpm,
        targets: targets,
        cropKey: cropKey,
        nutrient: nutrient,
        label: label,
      );
    }

    if (_isGarlicCrop(cropKey)) {
      return _garlicJustification(
        nutrientName: nutrientName,
        rawPpm: rawPpm,
        targets: targets,
        cropKey: cropKey,
        nutrient: nutrient,
        label: label,
      );
    }

    if (label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation) {
      return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName. Tienes niveles súper altos. Meterle más fertilizante ahorita puede ser tóxico o bloquear otros nutrientes en la tierra.';
    }

    if (label == NutrientPriorityLabel.noPriority ||
        label == NutrientPriorityLabel.lowPriority) {
      return 'Tu sensor lee ${rawPpm.round()} mg/kg. Esto está dentro del rango óptimo que pide la planta hoy. Cuida tu bolsillo y no apliques de más.';
    }

    final range = NutrientTargetRangeResolver.comparableRange(
      nutrient: nutrient,
      cropKey: cropKey,
      targets: targets,
    );

    if (range != null) {
      final targetMidPpm = (range.optimalMin + range.optimalMax) / 2.0;
      final diff = math.max(0, (targetMidPpm - rawPpm)).round();

      if (diff > 0) {
        return 'Tu tierra tiene ${rawPpm.round()} mg/kg, pero la meta es llegar a ~${targetMidPpm.round()} mg/kg en esta etapa. Usamos esa diferencia de $diff puntos para calcular la dosis que te recomendamos aplicar.';
      }
    }

    return 'La planta va a requerir más $nutrientName pronto según su etapa de desarrollo.';
  }

  static String _lettuceJustification({
    required String nutrientName,
    required double rawPpm,
    required StageTargets? targets,
    required String? cropKey,
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
  }) {
    if (label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation) {
      return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName en lechuga. La lectura se toma como riesgo de desequilibrio: puede subir salinidad, ablandar hoja o bloquear balance. Pausa ese nutriente y confirma con CE, pH, agua e historial.';
    }

    if (label == NutrientPriorityLabel.noPriority ||
        label == NutrientPriorityLabel.lowPriority) {
      return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName. Para lechuga está en zona manejable; mantén monitoreo y evita empujar crecimiento por rutina.';
    }

    final range = NutrientTargetRangeResolver.comparableRange(
      nutrient: nutrient,
      cropKey: cropKey,
      targets: targets,
    );
    if (range != null) {
      final targetMidPpm = (range.optimalMin + range.optimalMax) / 2.0;
      final diff = math.max(0, (targetMidPpm - rawPpm)).round();
      if (diff > 0) {
        return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName y queda corto contra la referencia de la etapa. En lechuga BIO-G usa esa diferencia ($diff puntos) como señal de revisión de manejo, no como receta de dosis.';
      }
    }

    return 'La lechuga puede necesitar más $nutrientName según etapa y calidad observada. Confirma en campo antes de ajustar el plan.';
  }

  static String _spinachJustification({
    required String nutrientName,
    required double rawPpm,
    required StageTargets? targets,
    required String? cropKey,
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
  }) {
    if (label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation) {
      return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName en espinaca. La lectura se toma como riesgo de desequilibrio: puede subir CE, ablandar hoja, elevar nitratos o bajar vida de anaquel. Pausa ese nutriente y confirma con agua, pH, CE y etapa.';
    }

    if (label == NutrientPriorityLabel.noPriority ||
        label == NutrientPriorityLabel.lowPriority) {
      return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName. Para espinaca esta en zona manejable; mantenga monitoreo y no empuje crecimiento por rutina.';
    }

    final range = NutrientTargetRangeResolver.comparableRange(
      nutrient: nutrient,
      cropKey: cropKey,
      targets: targets,
    );
    if (range != null) {
      final targetMidPpm = (range.optimalMin + range.optimalMax) / 2.0;
      final diff = math.max(0, (targetMidPpm - rawPpm)).round();
      if (diff > 0) {
        return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName y queda corto contra la referencia de la etapa. En espinaca BIO-G usa esa diferencia ($diff puntos) como senal de revision de manejo, no como receta de dosis.';
      }
    }

    return 'La espinaca puede necesitar mas $nutrientName segun etapa, turgencia y calidad observada. Confirma agua, CE y hoja comercial antes de ajustar el plan.';
  }

  static String _onionJustification({
    required String nutrientName,
    required double rawPpm,
    required StageTargets? targets,
    required String? cropKey,
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
  }) {
    if (label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation) {
      return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName en cebolla. La lectura se toma como riesgo de desequilibrio: puede subir CE, engrosar cuello, retrasar madurez o bajar conservacion. Pausa ese nutriente y confirma con agua, pH, CE, etapa y fotoperiodo.';
    }

    if (label == NutrientPriorityLabel.noPriority ||
        label == NutrientPriorityLabel.lowPriority) {
      return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName. Para cebolla esta en zona manejable; manten monitoreo y no empujes crecimiento por rutina cerca del bulbo.';
    }

    final range = NutrientTargetRangeResolver.comparableRange(
      nutrient: nutrient,
      cropKey: cropKey,
      targets: targets,
    );
    if (range != null) {
      final targetMidPpm = (range.optimalMin + range.optimalMax) / 2.0;
      final diff = math.max(0, (targetMidPpm - rawPpm)).round();
      if (diff > 0) {
        return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName y queda corto contra la referencia de la etapa. En cebolla BIO-G usa esa diferencia ($diff puntos) como senal de revision de manejo, no como receta de dosis.';
      }
    }

    return 'La cebolla puede necesitar mas $nutrientName segun etapa, fotoperiodo y estado del bulbo. Confirma agua, CE, raiz y maduracion antes de ajustar el plan.';
  }

  static String _garlicJustification({
    required String nutrientName,
    required double rawPpm,
    required StageTargets? targets,
    required String? cropKey,
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
  }) {
    if (label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation) {
      return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName en ajo. La lectura se toma como riesgo de desequilibrio: puede subir CE, favorecer vigor tardio, escobeteado/canutos, mala maduracion, pudriciones o curado deficiente. Pausa ese nutriente y confirma agua, pH, CE, etapa, frio y sanidad.';
    }

    if (label == NutrientPriorityLabel.noPriority ||
        label == NutrientPriorityLabel.lowPriority) {
      return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName. Para ajo esta en zona manejable; manten monitoreo y no empujes crecimiento por rutina cerca de vernalizacion, bulbo o curado.';
    }

    final range = NutrientTargetRangeResolver.comparableRange(
      nutrient: nutrient,
      cropKey: cropKey,
      targets: targets,
    );
    if (range != null) {
      final targetMidPpm = (range.optimalMin + range.optimalMax) / 2.0;
      final diff = math.max(0, (targetMidPpm - rawPpm)).round();
      if (diff > 0) {
        return 'El sensor lee ${rawPpm.round()} mg/kg de $nutrientName y queda corto contra la referencia de la etapa. En ajo BIO-G usa esa diferencia ($diff puntos) como senal de revision de manejo, no como receta: vernalizacion, diente-semilla, agua, CE y curado pueden limitar mas que NPK.';
      }
    }

    return 'El ajo puede necesitar mas $nutrientName segun etapa y calidad de bulbo. Confirma diente-semilla, frio, agua, CE, raiz, sanidad y curado antes de ajustar el plan.';
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

    if (crop == 'wheat' || crop == 'trigo') {
      if (nutrient == AgroMetricKey.n) {
        if (_isEarlyStage(stage)) return 'Arranque moderado';
        if (stage.contains('tiller') ||
            stage.contains('macoll') ||
            stage.contains('elong') ||
            stage.contains('encañ') ||
            stage.contains('encane') ||
            stage.contains('boot') ||
            stage.contains('embuch')) {
          return 'Macollamiento y encañe';
        }
        if (stage.contains('head') ||
            stage.contains('espig') ||
            stage.contains('flower') ||
            stage.contains('flor') ||
            stage.contains('antes')) {
          return 'Proteína y calidad';
        }
        if (stage.contains('grain') || stage.contains('llenado')) {
          return 'Cierre de N';
        }
        return 'Demanda de N por etapa';
      }
      if (nutrient == AgroMetricKey.p) {
        if (_isEarlyStage(stage) ||
            stage.contains('tiller') ||
            stage.contains('macoll')) {
          return 'Raíz y macollaje';
        }
        return 'Base fosfatada';
      }
      if (nutrient == AgroMetricKey.k) {
        if (stage.contains('head') ||
            stage.contains('espig') ||
            stage.contains('flower') ||
            stage.contains('flor') ||
            stage.contains('antes') ||
            stage.contains('grain') ||
            stage.contains('llenado')) {
          return 'Balance, firmeza y llenado';
        }
        return 'Balance y tallo';
      }
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

    if (crop == 'tomato' || crop == 'tomate' || crop == 'jitomate') {
      if (nutrient == AgroMetricKey.n) {
        if (stage.contains('germin') || stage.contains('establec')) {
          return 'Arranque moderado';
        }
        if (stage.contains('vegetativo')) {
          return 'Follaje con mesura';
        }
        if (stage.contains('floracion') ||
            stage.contains('flor') ||
            stage.contains('cuajado')) {
          return 'Equilibrio para flor y fruto';
        }
        if (stage.contains('llenado') || stage.contains('progresiv')) {
          return 'Nitrógeno a la baja';
        }
        if (stage.contains('fincic')) return 'Cierre de ciclo';
        return 'Demanda de nitrógeno por etapa';
      }
      if (nutrient == AgroMetricKey.p) {
        if (stage.contains('germin') || stage.contains('establec')) {
          return 'Arranque: raíz que agarre';
        }
        if (stage.contains('vegetativo') ||
            stage.contains('floracion') ||
            stage.contains('cuajado')) {
          return 'Fósforo de sostén';
        }
        if (stage.contains('fincic')) return 'Cierre de ciclo';
        return 'Base de fósforo';
      }
      if (nutrient == AgroMetricKey.k) {
        if (stage.contains('floracion') || stage.contains('cuajado')) {
          return 'Cuajado: evita pudrición de punta';
        }
        if (stage.contains('llenado')) return 'Llenado: calidad y dulzor';
        if (stage.contains('progresiv'))
          return 'Cosecha: firmeza y anti-rajado';
        if (stage.contains('fincic')) return 'Cierre de ciclo';
        return 'Reserva de potasio';
      }
    }

    if (crop == 'chili' ||
        crop == 'chile' ||
        crop == 'pepper' ||
        crop == 'pimiento') {
      if (nutrient == AgroMetricKey.n) {
        if (stage.contains('germin') ||
            stage.contains('emerg') ||
            stage.contains('establec')) {
          return 'Arranque moderado';
        }
        if (stage.contains('vegetativo')) return 'Follaje con mesura';
        if (stage.contains('flor') ||
            stage.contains('cuaj') ||
            stage.contains('amarre')) {
          return 'Equilibrio para flor y amarre';
        }
        if (stage.contains('llen') || stage.contains('progresiv')) {
          return 'Nitrogeno a la baja';
        }
        if (stage.contains('fin') || stage.contains('senesc')) {
          return 'Cierre de ciclo';
        }
        return 'Demanda de N por etapa';
      }
      if (nutrient == AgroMetricKey.p) {
        if (stage.contains('germin') ||
            stage.contains('emerg') ||
            stage.contains('establec')) {
          return 'Raiz y pegue';
        }
        if (stage.contains('flor') || stage.contains('cuaj')) {
          return 'Energia reproductiva';
        }
        if (stage.contains('fin') || stage.contains('senesc')) {
          return 'Cierre de ciclo';
        }
        return 'Fosforo de sosten';
      }
      if (nutrient == AgroMetricKey.k) {
        if (stage.contains('flor') ||
            stage.contains('cuaj') ||
            stage.contains('amarre')) {
          return 'Amarre: K y Ca';
        }
        if (stage.contains('llen')) return 'Llenado y calidad';
        if (stage.contains('progresiv')) return 'Cosecha progresiva';
        if (stage.contains('fin') || stage.contains('senesc')) {
          return 'Cierre de ciclo';
        }
        return 'Reserva de potasio';
      }
    }

    if (crop == 'eggplant' || crop == 'berenjena' || crop == 'aubergine') {
      if (nutrient == AgroMetricKey.n) {
        if (stage.contains('germin') ||
            stage.contains('emerg') ||
            stage.contains('establec')) {
          return 'Arranque moderado';
        }
        if (stage.contains('vegetativo')) return 'Follaje con mesura';
        if (stage.contains('flor') ||
            stage.contains('cuaj') ||
            stage.contains('amarre')) {
          return 'Equilibrio para flor y amarre';
        }
        if (stage.contains('llen') || stage.contains('progresiv')) {
          return 'Nitrogeno a la baja';
        }
        if (stage.contains('fin') || stage.contains('senesc')) {
          return 'Cierre de ciclo';
        }
        return 'Demanda de N por etapa';
      }
      if (nutrient == AgroMetricKey.p) {
        if (stage.contains('germin') ||
            stage.contains('emerg') ||
            stage.contains('establec')) {
          return 'Raiz y pegue';
        }
        if (stage.contains('flor') || stage.contains('cuaj')) {
          return 'Energia reproductiva';
        }
        if (stage.contains('fin') || stage.contains('senesc')) {
          return 'Cierre de ciclo';
        }
        return 'Fosforo de sosten';
      }
      if (nutrient == AgroMetricKey.k) {
        if (stage.contains('flor') ||
            stage.contains('cuaj') ||
            stage.contains('amarre')) {
          return 'Amarre: K y Ca';
        }
        if (stage.contains('llen')) return 'Llenado y calidad';
        if (stage.contains('progresiv')) return 'Cosecha progresiva';
        if (stage.contains('fin') || stage.contains('senesc')) {
          return 'Cierre de ciclo';
        }
        return 'Reserva de potasio';
      }
    }

    if (crop == 'squash' ||
        crop == 'calabaza' ||
        crop == 'pumpkin' ||
        crop == 'zucchini' ||
        crop == 'calabacita') {
      if (nutrient == AgroMetricKey.n) {
        if (stage.contains('germin') ||
            stage.contains('emerg') ||
            stage.contains('establec')) {
          return 'Arranque moderado';
        }
        if (stage.contains('vegetativo')) return 'Guia y hoja con mesura';
        if (stage.contains('flor') ||
            stage.contains('cuaj') ||
            stage.contains('amarre')) {
          return 'Equilibrio para flor y amarre';
        }
        if (stage.contains('llen') || stage.contains('progresiv')) {
          return 'Nitrogeno a la baja';
        }
        if (stage.contains('fin') || stage.contains('senesc')) {
          return 'Cierre de ciclo';
        }
        return 'Demanda de N por etapa';
      }
      if (nutrient == AgroMetricKey.p) {
        if (stage.contains('germin') ||
            stage.contains('emerg') ||
            stage.contains('establec')) {
          return 'Raiz y pegue';
        }
        if (stage.contains('flor') || stage.contains('cuaj')) {
          return 'Energia reproductiva';
        }
        if (stage.contains('fin') || stage.contains('senesc')) {
          return 'Cierre de ciclo';
        }
        return 'Fosforo de sosten';
      }
      if (nutrient == AgroMetricKey.k) {
        if (stage.contains('flor') ||
            stage.contains('cuaj') ||
            stage.contains('amarre')) {
          return 'Flor, amarre y K';
        }
        if (stage.contains('llen')) return 'Llenado de fruto o pepita';
        if (stage.contains('progresiv')) return 'Cosecha y calidad';
        if (stage.contains('fin') || stage.contains('senesc')) {
          return 'Cierre de ciclo';
        }
        return 'Reserva de potasio';
      }
    }

    if (crop == 'spinach' || crop == 'espinaca' || crop == 'crop_spinach') {
      final early =
          stage.contains('germin') ||
          stage.contains('emerg') ||
          stage.contains('establec');
      final expansion =
          stage.contains('vegetativo') || stage.contains('expansion');
      final quality =
          stage.contains('madurez') ||
          stage.contains('cosecha') ||
          stage.contains('ventana');
      final late =
          stage.contains('perdida') ||
          stage.contains('espig') ||
          stage.contains('senesc');
      if (nutrient == AgroMetricKey.n) {
        if (early) return 'Arranque bajo en N';
        if (expansion) return 'Hoja con N controlado';
        if (quality || late) return 'N a la baja';
        return 'Demanda foliar controlada';
      }
      if (nutrient == AgroMetricKey.p) {
        if (early) return 'Raiz y establecimiento';
        if (late) return 'Cierre de P';
        return 'P de soporte';
      }
      if (nutrient == AgroMetricKey.k) {
        if (expansion || quality) return 'Turgencia y calidad de hoja';
        if (late) return 'Cierre de K';
        return 'Reserva de potasio';
      }
    }

    if (crop == 'onion' || crop == 'cebolla' || crop == 'crop_onion') {
      final early =
          stage.contains('germin') ||
          stage.contains('emerg') ||
          stage.contains('establec');
      final foliar = stage.contains('vegetativo');
      final induction = stage.contains('induccion');
      final bulb =
          stage.contains('llenado') ||
          stage.contains('iniciobulbo') ||
          stage.contains('bulbo');
      final late =
          stage.contains('maduracion') ||
          stage.contains('cosecha') ||
          stage.contains('espig') ||
          stage.contains('senesc');
      if (nutrient == AgroMetricKey.n) {
        if (early) return 'Arranque bajo en N';
        if (foliar) return 'Hoja con N controlado';
        if (induction) return 'N a la baja, fotoperiodo manda';
        if (bulb || late) return 'Detener N';
        return 'Demanda foliar controlada';
      }
      if (nutrient == AgroMetricKey.p) {
        if (early) return 'Raiz y arranque';
        if (late) return 'Cierre de P';
        return 'P de soporte';
      }
      if (nutrient == AgroMetricKey.k) {
        if (bulb || induction) return 'Llenado y calidad del bulbo';
        if (late) return 'Mantenimiento de K';
        return 'Reserva de potasio';
      }
    }

    if (crop == 'garlic' || crop == 'ajo' || crop == 'crop_garlic') {
      final early =
          stage.contains('plant') ||
          stage.contains('clove') ||
          stage.contains('diente') ||
          stage.contains('emerg') ||
          stage.contains('establec');
      final foliar = stage.contains('veget') || stage.contains('foliar');
      final vernalization =
          stage.contains('vernal') ||
          stage.contains('frio') ||
          stage.contains('cold');
      final bulb =
          stage.contains('diferenci') ||
          stage.contains('llenado') ||
          stage.contains('bulb') ||
          stage.contains('bulbo') ||
          stage.contains('fill');
      final late =
          stage.contains('maduracion') ||
          stage.contains('matur') ||
          stage.contains('cosecha') ||
          stage.contains('harvest') ||
          stage.contains('curado') ||
          stage.contains('curing') ||
          stage.contains('escapo') ||
          stage.contains('canuto') ||
          stage.contains('escobete') ||
          stage.contains('senesc');
      if (nutrient == AgroMetricKey.n) {
        if (early) return 'Arranque bajo en N';
        if (foliar) return 'Hoja con N controlado';
        if (vernalization) return 'N a la baja: frio manda';
        if (bulb || late) return 'Detener N';
        return 'Demanda foliar controlada';
      }
      if (nutrient == AgroMetricKey.p) {
        if (early) return 'Raiz y arranque';
        if (late) return 'Cierre de P';
        return 'P de soporte';
      }
      if (nutrient == AgroMetricKey.k) {
        if (bulb || vernalization) {
          return 'Diferenciacion/llenado y firmeza';
        }
        if (late) return 'Mantenimiento de K';
        return 'Reserva de potasio';
      }
    }

    return 'Demanda actual';
  }

  // =========================================================================
  // HELPERS DE ETAPA
  // =========================================================================
  static bool _isChiliCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
    return crop == 'chili' ||
        crop == 'chile' ||
        crop == 'pepper' ||
        crop == 'pimiento';
  }

  static bool _isEggplantCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
    return crop == 'eggplant' || crop == 'berenjena' || crop == 'aubergine';
  }

  static bool _isSquashCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
    return crop == 'squash' ||
        crop == 'calabaza' ||
        crop == 'pumpkin' ||
        crop == 'zucchini' ||
        crop == 'calabacita';
  }

  static bool _isLettuceCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
    return crop == 'lettuce' || crop == 'lechuga' || crop == 'crop_lettuce';
  }

  static bool _isSpinachCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
    return crop == 'spinach' || crop == 'espinaca' || crop == 'crop_spinach';
  }

  static bool _isOnionCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
    return crop == 'onion' || crop == 'cebolla' || crop == 'crop_onion';
  }

  static bool _isGarlicCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
    return crop == 'garlic' || crop == 'ajo' || crop == 'crop_garlic';
  }

  static bool _isAppleTreeCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
    return crop == 'apple_tree' ||
        crop == 'crop_apple_tree' ||
        crop == 'manzano';
  }

  static bool _isPearTreeCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
    return crop == 'pear_tree' ||
        crop == 'crop_pear_tree' ||
        crop == 'pera' ||
        crop == 'peral';
  }

  static bool _isPeachTreeCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
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

  static bool _isWalnutTreeCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
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

  static bool _isPistachioTreeCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
    return crop == 'pistachio_tree' ||
        crop == 'crop_pistachio_tree' ||
        crop == 'pistachio' ||
        crop == 'pistachiotree' ||
        crop == 'pistache' ||
        crop == 'pistacho' ||
        crop == 'pistachero';
  }

  static bool _isOrangeTreeCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
    return crop == 'orange_tree' ||
        crop == 'crop_orange_tree' ||
        crop == 'orange' ||
        crop == 'orangetree' ||
        crop == 'naranjo' ||
        crop == 'naranja';
  }

  static bool _isLemonTreeCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
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

  static bool _isMangoTreeCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
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

  static bool _isAvocadoTreeCrop(String? cropKey) {
    final crop = (cropKey ?? '').toLowerCase();
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

  /// Árbol frutal perenne (manzano/pera de pepita + durazno de hueso + nogal de
  /// nuez + pistache de nuez + naranjo/limón cítricos): comparten la semántica
  /// "alto útil" del modelo de 5 zonas (un valor por encima del óptimo pero por
  /// debajo de `highMin` no penaliza ni alerta). El limón es cítrico de fruto
  /// fresco, pero la lógica de bandas NPK del árbol es la misma.
  static bool _isFruitTreeCrop(String? cropKey) =>
      _isAppleTreeCrop(cropKey) ||
      _isPearTreeCrop(cropKey) ||
      _isPeachTreeCrop(cropKey) ||
      _isWalnutTreeCrop(cropKey) ||
      _isPistachioTreeCrop(cropKey) ||
      _isOrangeTreeCrop(cropKey) ||
      _isLemonTreeCrop(cropKey) ||
      _isMangoTreeCrop(cropKey) ||
      _isAvocadoTreeCrop(cropKey);

  // ── MANZANO ────────────────────────────────────────────────────────────────
  // Recomendaciones prácticas del manzano (doc 05 §11–§13). Reglas clave:
  // - N: "más N no es más fruta"; llenado y madurez no son la misma ventana.
  // - K: sube tras cuajado (calibre, azúcares, firmeza); cuidar K vs Ca/Mg.
  // - P: pesa en raíz/brotación/floración; en pH alto puede ser disponibilidad.
  static String _appleTreePracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    AppleTreeNutritionModifier? modifier,
  ) {
    final isEstablishment =
        stage.contains('planting') || stage.contains('root_establish');
    final isEarlyP =
        isEstablishment ||
        stage.contains('budbreak') ||
        stage.contains('flower');
    final isFruitSet = stage.contains('fruit_set');
    final isFruitFill = stage.contains('fruit_fill');
    final isHarvestMaturity =
        stage.contains('harvest_maturity') ||
        (stage.contains('harvest') && !stage.contains('post_harvest'));
    final isFruit = isFruitSet || isFruitFill || isHarvestMaturity;
    final isUsefulHigh = label == NutrientPriorityLabel.possibleExcess;
    final isRealExcess = label == NutrientPriorityLabel.reviewAccumulation;
    final caution = modifier?.practicalCaution(nutrient, stage);
    final cautionSuffix = caution == null ? '' : ' $caution';

    switch (nutrient) {
      case AgroMetricKey.n:
        if (isUsefulHigh) {
          if (isHarvestMaturity) {
            return 'BioG lee N alto para madurez de manzano. No agregues más '
                'nitrógeno por ahora: puede retrasar color, bajar firmeza y '
                'castigar calidad.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'BioG lee N alto en llenado de manzano. Frena N por ahora: '
                'mucho follaje le quita fuerza al fruto y puede bajar calibre '
                'o firmeza.$cautionSuffix';
          }
          return 'BioG lee N alto, todavía manejable. No apliques más N por '
              'costumbre; vigila brotes y sombra excesiva.$cautionSuffix';
        }
        if (isRealExcess) {
          if (isHarvestMaturity) {
            return 'Nitrógeno alto en manzano. Frena fertilizantes '
                'nitrogenados: cerca de cosecha retrasa madurez, apaga color '
                'y ablanda el fruto.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'Nitrógeno alto en llenado de manzano. No apliques más N: '
                'puede empujar demasiado follaje, quitar fuerza al fruto y '
                'bajar firmeza.$cautionSuffix';
          }
          return 'BioG detecta nitrógeno de sobra en manzano. Pausa N: más '
              'follaje no significa más fruta y puede bajar calidad.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Nitrógeno en rango para esta etapa del manzano. Mantén el '
              'plan y no apliques N extra por costumbre.';
        }
        if (isHarvestMaturity) {
          return 'BioG lee N bajo cerca de cosecha. No lo corrijas fuerte '
              'ahora: protege color y firmeza; ajusta después si sigue bajo.';
        }
        if (isFruitFill) {
          return 'BioG lee N bajo en llenado. Si el árbol se ve débil, corrige '
              'ligero; evita pasarte porque ahora el fruto y el K mandan.';
        }
        return 'BioG detecta poco N para sostener hoja y brote del manzano. '
            'Aplica una corrección ligera y evita excederte.';

      case AgroMetricKey.p:
        if (isUsefulHigh) {
          return 'BioG lee fósforo algo alto en manzano. No agregues más P por '
              'ahora; sigue la tendencia.';
        }
        if (isRealExcess) {
          return 'Fósforo alto en manzano. Pausa fertilizantes fosfatados: el '
              'exceso puede bloquear otros nutrientes y no baja rápido.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Fósforo en rango para esta etapa del manzano. Mantén el plan.';
        }
        if (isEarlyP) {
          return 'BioG detecta fósforo bajo en una etapa sensible. Corrige de '
              'forma moderada para apoyar raíz, brotación y floración.';
        }
        return 'Fósforo bajo en manzano. Corrige sin excederte; si el suelo '
            'está frío o seco, primero estabiliza humedad para que lo tome.';

      case AgroMetricKey.k:
        if (isUsefulHigh) {
          return 'BioG lee K alto pero útil para fruto. No subas más potasio si '
              'el desarrollo va bien; mantén riego parejo.$cautionSuffix';
        }
        if (isRealExcess) {
          return 'Potasio alto en manzano. Pausa K: demasiado potasio puede '
              'desbalancear calcio, subir sales y afectar firmeza.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Potasio en rango para esta etapa del manzano.';
        }
        if (isFruit) {
          return 'Potasio bajo en manzano. En esta etapa ayuda a calibre, '
              'azúcar y firmeza; refuerza K de forma gradual con riego '
              'parejo.$cautionSuffix';
        }
        return 'BioG lee potasio bajo en manzano. Prepara el árbol para '
            'cuajado y llenado con una corrección gradual.';

      default:
        return 'Revisa el manejo nutricional del árbol según su etapa.';
    }
  }

  // ── PERA ───────────────────────────────────────────────────────────────────
  // Recomendaciones prácticas de la pera (doc 05 §9, §12, §14). Reglas clave:
  // - N: "más N no es más fruta"; el exceso sube riesgo de fuego bacteriano,
  //   baja firmeza/calidad y retrasa madurez; llenado != madurez (v1.5).
  // - K: protagonista de fruto desde cuajado; cuidar K vs Ca/Mg (cork spot).
  // - P: pesa en raíz/brotación/floración; en árbol adulto responde poco.
  static String _pearTreePracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    PearTreeNutritionModifier? modifier,
  ) {
    final isEstablishment =
        stage.contains('planting') || stage.contains('root_establish');
    final isEarlyP =
        isEstablishment ||
        stage.contains('budbreak') ||
        stage.contains('flower');
    final isFruitSet = stage.contains('fruit_set');
    final isFruitFill = stage.contains('fruit_fill');
    final isHarvestMaturity =
        stage.contains('harvest_maturity') ||
        (stage.contains('harvest') && !stage.contains('post_harvest'));
    final isVegetative = stage.contains('vegetative_growth');
    final isFruit = isFruitSet || isFruitFill || isHarvestMaturity;
    final isUsefulHigh = label == NutrientPriorityLabel.possibleExcess;
    final isRealExcess = label == NutrientPriorityLabel.reviewAccumulation;
    final caution = modifier?.practicalCaution(nutrient, stage);
    final cautionSuffix = caution == null ? '' : ' $caution';

    switch (nutrient) {
      case AgroMetricKey.n:
        if (isUsefulHigh) {
          if (isHarvestMaturity) {
            return 'BioG lee N alto para madurez de peral. No agregues más '
                'nitrógeno por ahora: puede bajar firmeza, retrasar madurez y '
                'acortar conservación.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'BioG lee N alto en llenado de peral. Frena N por ahora: '
                'mucho follaje compite con calibre y firmeza del fruto.$cautionSuffix';
          }
          if (isVegetative) {
            return 'BioG lee N alto en crecimiento del peral. No empujes más '
                'brotes tiernos; eso sube riesgo de enfermedad.$cautionSuffix';
          }
          return 'BioG lee N alto, todavía manejable. No apliques más N por '
              'costumbre; vigila brotes tiernos y sombra.$cautionSuffix';
        }
        if (isRealExcess) {
          if (isHarvestMaturity) {
            return 'Nitrógeno alto en peral. Frena fertilizantes nitrogenados: '
                'cerca de cosecha baja firmeza, retrasa madurez y acorta '
                'conservación.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'Nitrógeno alto en llenado de peral. No apliques más N: '
                'puede mandar el árbol a follaje, restar calibre y bajar '
                'calidad.$cautionSuffix';
          }
          if (isVegetative) {
            return 'BioG detecta nitrógeno de sobra en peral. Pausa N: los '
                'brotes tiernos aumentan riesgo de fuego bacteriano.$cautionSuffix';
          }
          return 'BioG detecta nitrógeno de sobra en peral. Más N no es más '
              'fruta: sube follaje, sombra y riesgo sanitario.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Nitrógeno en rango para esta etapa del peral. Mantén el plan '
              'y no apliques N extra por costumbre.';
        }
        if (isHarvestMaturity) {
          return 'BioG lee N bajo cerca de cosecha. No lo corrijas fuerte '
              'ahora: cuida firmeza y ajusta después si sigue bajo.';
        }
        if (isFruitFill) {
          return 'BioG lee N bajo en llenado de peral. Si el árbol se ve débil, '
              'corrige ligero; evita pasarte porque ahora manda el fruto.';
        }
        return 'BioG detecta poco N para sostener hoja y brote del peral. '
            'Aplica una corrección ligera y cuida no disparar brotes tiernos.';

      case AgroMetricKey.p:
        if (isUsefulHigh) {
          return 'BioG lee fósforo algo alto en peral. No agregues más P por '
              'ahora; sigue la tendencia.';
        }
        if (isRealExcess) {
          return 'Fósforo alto en peral. Pausa fertilizantes fosfatados: el '
              'exceso puede bloquear otros nutrientes y no corrige el fruto.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Fósforo en rango para esta etapa del peral. Mantén el plan.';
        }
        if (isEarlyP) {
          return 'BioG detecta fósforo bajo en una etapa sensible. Corrige de '
              'forma moderada para apoyar raíz, brotación y floración.';
        }
        return 'Fósforo bajo en peral. Corrige sin excederte; si el suelo está '
            'frío o seco, primero estabiliza humedad para que lo tome.';

      case AgroMetricKey.k:
        if (isUsefulHigh) {
          return 'BioG lee K alto pero útil para fruto. No subas más potasio si '
              'el desarrollo va bien; mantén riego parejo.$cautionSuffix';
        }
        if (isRealExcess) {
          return 'Potasio alto en peral. Pausa K: demasiado potasio puede '
              'desbalancear calcio, subir sales y bajar firmeza.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Potasio en rango para esta etapa del peral.';
        }
        if (isFruit) {
          return 'Potasio bajo en peral. En esta etapa ayuda a calibre, firmeza '
              'y calidad; refuerza K de forma gradual con riego parejo.$cautionSuffix';
        }
        return 'BioG lee potasio bajo en peral. Prepara el árbol para cuajado '
            'y llenado con una corrección gradual.';

      default:
        return 'Revisa el manejo nutricional del árbol según su etapa.';
    }
  }

  // ── DURAZNO ──────────────────────────────────────────────────────────────
  // Recomendaciones prácticas del durazno (doc 05 §12–§16). Frutal de
  // HUESO/carozo. Reglas clave:
  // - N: necesario para hoja/madera, pero el exceso "roba fruta": vigor blando,
  //   sombra, peor color/firmeza y más presión sanitaria. No fire blight.
  // - K: protagonista del fruto desde cuajado; el durazno es muy sensible a la
  //   deficiencia de K (calibre, firmeza, azúcares).
  // - P: pesa en raíz/establecimiento/floración; en árbol adulto responde poco.
  // - Contrato v1.5: fruit_fill habla de LLENADO/calibre/carozo (NO cosecha);
  //   harvest_maturity sí habla de madurez/cosecha/color/firmeza final.
  static String _peachTreePracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    PeachTreeNutritionModifier? modifier,
  ) {
    final isEstablishment =
        stage.contains('planting') || stage.contains('root_establish');
    final isEarlyP =
        isEstablishment ||
        stage.contains('budbreak') ||
        stage.contains('flower');
    final isFruitSet = stage.contains('fruit_set');
    final isFruitFill = stage.contains('fruit_fill');
    final isHarvestMaturity =
        stage.contains('harvest_maturity') ||
        (stage.contains('harvest') && !stage.contains('post_harvest'));
    final isVegetative = stage.contains('vegetative_growth');
    final isFruit = isFruitSet || isFruitFill || isHarvestMaturity;
    final isUsefulHigh = label == NutrientPriorityLabel.possibleExcess;
    final isRealExcess = label == NutrientPriorityLabel.reviewAccumulation;
    final caution = modifier?.practicalCaution(nutrient, stage);
    final cautionSuffix = caution == null ? '' : ' $caution';

    switch (nutrient) {
      case AgroMetricKey.n:
        if (isUsefulHigh) {
          if (isHarvestMaturity) {
            return 'BioG lee N alto para madurez de duraznero. No agregues más '
                'nitrógeno por ahora: puede retrasar color, bajar firmeza y '
                'castigar calidad.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'BioG lee N alto en llenado de duraznero. Frena N por '
                'ahora: mucho follaje compite con el fruto y puede bajar '
                'calibre o firmeza.$cautionSuffix';
          }
          if (isVegetative) {
            return 'BioG lee N alto en crecimiento del duraznero. No empujes '
                'más brotes tiernos; eso da sombra y sube presión de plagas.$cautionSuffix';
          }
          return 'BioG lee N alto, todavía manejable. No apliques más N por '
              'costumbre; vigila follaje y sombra.$cautionSuffix';
        }
        if (isRealExcess) {
          if (isHarvestMaturity) {
            return 'Nitrógeno alto en duraznero. Frena fertilizantes '
                'nitrogenados: cerca de cosecha retrasa madurez, baja color y '
                'afloja el fruto.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'Nitrógeno alto en llenado de duraznero. No apliques más N: '
                'puede mandar el árbol a follaje, restar calibre y bajar '
                'calidad.$cautionSuffix';
          }
          if (isVegetative) {
            return 'BioG detecta nitrógeno de sobra en duraznero. Pausa N: los '
                'brotes tiernos dan sombra, bajan calidad y atraen más plaga.$cautionSuffix';
          }
          return 'BioG detecta nitrógeno de sobra en duraznero. Más N no es '
              'más fruta: sube follaje, sombra y riesgo sanitario.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Nitrógeno en rango para esta etapa del duraznero. Mantén el '
              'plan y no apliques N extra por costumbre.';
        }
        if (isHarvestMaturity) {
          return 'BioG lee N bajo cerca de cosecha. No lo corrijas fuerte '
              'ahora: cuida color y firmeza; ajusta después si sigue bajo.';
        }
        if (isFruitFill) {
          return 'BioG lee N bajo en llenado de duraznero. Si el árbol se ve '
              'débil, corrige ligero; evita pasarte porque ahora manda el fruto.';
        }
        return 'BioG detecta poco N para sostener hoja y brote del duraznero. '
            'Aplica una corrección ligera y evita disparar follaje.';

      case AgroMetricKey.p:
        if (isUsefulHigh) {
          return 'BioG lee fósforo algo alto en duraznero. No agregues más P '
              'por ahora; sigue la tendencia.';
        }
        if (isRealExcess) {
          return 'Fósforo alto en duraznero. Pausa fertilizantes fosfatados: '
              'el exceso puede bloquear otros nutrientes y no mejora el fruto.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Fósforo en rango para esta etapa del duraznero. Mantén el plan.';
        }
        if (isEarlyP) {
          return 'BioG detecta fósforo bajo en una etapa sensible. Corrige de '
              'forma moderada para apoyar raíz, brotación y floración.';
        }
        return 'Fósforo bajo en duraznero. Corrige sin excederte; si el suelo '
            'está frío o seco, primero estabiliza humedad para que lo tome.';

      case AgroMetricKey.k:
        if (isUsefulHigh) {
          return 'BioG lee K alto pero útil para fruto. No subas más potasio si '
              'el desarrollo va bien; mantén riego parejo.$cautionSuffix';
        }
        if (isRealExcess) {
          return 'Potasio alto en duraznero. Pausa K: demasiado potasio puede '
              'subir sales, desbalancear calcio y bajar firmeza.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Potasio en rango para esta etapa del duraznero.';
        }
        if (isFruit) {
          return 'Potasio bajo en duraznero. En esta etapa ayuda a tamaño, '
              'firmeza, dulzor y llenado; refuerza K de forma gradual con '
              'riego parejo.$cautionSuffix';
        }
        return 'BioG lee potasio bajo en duraznero. Prepara el árbol para '
            'cuajado y llenado con una corrección gradual.';

      default:
        return 'Revisa el manejo nutricional del árbol según su etapa.';
    }
  }

  // ── NOGAL PECANERO ─────────────────────────────────────────────────────────
  // Guardas de suelo del nogal (doc 05 §12.2, §3.1-§3.4). Devuelve un mensaje de
  // guarda cuando agua/raíz/salinidad/pH deben mandar ANTES que NPK; null si el
  // suelo no bloquea y se puede hablar de nutrición. Umbrales conservadores
  // (doc 05 §0.5): EC alta ~>2.0 dS/m; humedad crítica baja <45%; saturación
  // >90%; pH alto >7.5. NO son dosis; orientan y piden confirmar con análisis.
  static String? _walnutSoilGuard({
    required String stage,
    double? ph,
    double? ec,
    double? soilMoisturePct,
  }) {
    final isFruitFill = stage.contains('fruit_fill');
    final isFruit =
        isFruitFill ||
        stage.contains('fruit_set') ||
        stage.contains('harvest');

    // 1) Saturación: oxígeno/raíz/drenaje primero (no más agua ni fertilizante).
    if (soilMoisturePct != null && soilMoisturePct > 90) {
      return 'El suelo está saturado para el nogal. Más agua o fertilizante '
          'empeora el oxígeno de la raíz: revisa drenaje y aireación antes de '
          'tocar NPK.';
    }
    // 2) Humedad crítica baja: agua/absorción primero.
    if (soilMoisturePct != null && soilMoisturePct < 45) {
      final tail = isFruitFill
          ? ' En llenado, la nuez no perdona falta de agua: se juega el llenado '
                'de almendra.'
          : '';
      return 'Primero estabiliza la humedad: con raíz estresada el nogal '
          'aprovecha mal el NPK.$tail';
    }
    // 3) Salinidad alta: sales/agua/drenaje antes de fertilizar.
    if (ec != null && ec >= 2.0) {
      final tail = isFruit
          ? ' Con sales altas en amarre/llenado, empujar fertilizante agrava el '
                'estrés y castiga el llenado de almendra.'
          : '';
      return 'La salinidad (EC) está alta en el nogal. No apliques fertilización '
          'fuerte: prioriza riego de lavado/lixiviación, agua parejo y '
          'drenaje.$tail';
    }
    // 4) pH alto: disponibilidad de Zn/Fe/P, no más N.
    if (ph != null && ph > 7.5) {
      return 'El pH está alto para el nogal: puede haber bloqueo de zinc, hierro '
          'o fósforo aunque estén presentes. Revisa disponibilidad y zinc '
          'contextual antes de subir N. Confirma con análisis.';
    }
    return null;
  }

  // Recomendaciones prácticas del nogal (doc 05 §12, §14, §17). Frutal de NUEZ.
  // Reglas clave:
  // - N: protagonista de hoja/área foliar/reservas/llenado, pero "más N no es
  //   más nuez": el exceso se va a follaje/sombra, sube sales y desbalancea Zn.
  // - K: protagonista del crecimiento de nuez y el llenado de almendra (calibre,
  //   % almendra, calidad). Alta sensibilidad a K bajo en fruit_fill.
  // - P: pesa en raíz/establecimiento/floración; en suelo calizo el problema
  //   suele ser disponibilidad por pH, no falta total.
  // - Zinc es CONTEXTO crítico (no sensor v1): con pH alto + hoja chica/roseta,
  //   no diagnosticar "falta de N".
  // - Contrato v1.5: fruit_fill habla de LLENADO de nuez/almendra (NO cosecha);
  //   harvest_maturity sí habla de madurez/ruezno/cosecha/calidad final.
  static String _walnutTreePracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    WalnutTreeNutritionModifier? modifier, {
    double? ph,
    double? ec,
    double? soilMoisturePct,
  }) {
    // GUARDAS de Nogal (doc 05 §12.2 "bloqueos duros", §3.1-§3.4): agua, raíz,
    // salinidad y pH MANDAN antes que NPK. Si el contexto de suelo está fuera de
    // rango, BIO-G antepone la guarda y NO empuja fertilización agresiva. Es
    // orientación, no dosis. Umbrales conservadores alineados al doc 05 §0.5.
    final guard = _walnutSoilGuard(
      stage: stage,
      ph: ph,
      ec: ec,
      soilMoisturePct: soilMoisturePct,
    );
    if (guard != null) return guard;

    final isEstablishment =
        stage.contains('planting') || stage.contains('root_establish');
    final isEarlyP =
        isEstablishment ||
        stage.contains('budbreak') ||
        stage.contains('flower');
    final isFruitSet = stage.contains('fruit_set');
    final isFruitFill = stage.contains('fruit_fill');
    final isHarvestMaturity =
        stage.contains('harvest_maturity') ||
        (stage.contains('harvest') && !stage.contains('post_harvest'));
    final isVegetative = stage.contains('vegetative_growth');
    final isFruit = isFruitSet || isFruitFill || isHarvestMaturity;
    final isUsefulHigh = label == NutrientPriorityLabel.possibleExcess;
    final isRealExcess = label == NutrientPriorityLabel.reviewAccumulation;
    final caution = modifier?.practicalCaution(nutrient, stage);
    final cautionSuffix = caution == null ? '' : ' $caution';

    switch (nutrient) {
      case AgroMetricKey.n:
        if (isUsefulHigh) {
          if (isHarvestMaturity) {
            return 'BioG lee N alto en madurez del nogal. No agregues mas '
                'nitrogeno: cerca de cosecha el N tardio retrasa madurez y puede '
                'favorecer pre-germinacion y brote tierno.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'BioG lee N alto en llenado de nuez. Frena el N por ahora: '
                'mucho vigor compite con el llenado de almendra; revisa agua, K '
                'y zinc.$cautionSuffix';
          }
          if (isVegetative) {
            return 'BioG lee N alto en crecimiento del nogal. No empujes mas '
                'brotes tiernos: dan sombra y suben pulgon/acaros sin mas nuez.$cautionSuffix';
          }
          return 'BioG lee N alto, todavia manejable. En nogal mas N no es mas '
              'nuez; vigila follaje, sombra y carga.$cautionSuffix';
        }
        if (isRealExcess) {
          if (isHarvestMaturity) {
            return 'Nitrogeno alto en nogal. Frena fertilizantes nitrogenados: '
                'cerca de cosecha el N tardio castiga calidad y reservas.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'Nitrogeno alto en llenado de nuez. No apliques mas N: puede '
                'irse a follaje, restar llenado de almendra y subir alternancia.$cautionSuffix';
          }
          return 'BioG detecta nitrogeno de sobra en nogal. Mas N no es mas '
              'nuez: sube follaje, sombra, sales y presion de plagas.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Nitrogeno en rango para esta etapa del nogal. Manten el plan '
              'y no apliques N extra por costumbre.';
        }
        if (isHarvestMaturity) {
          return 'BioG lee N bajo cerca de cosecha. No lo corrijas fuerte ahora: '
              'cuida calidad de almendra; ajusta en postcosecha si sigue bajo.';
        }
        if (isFruitFill) {
          return 'BioG lee N bajo en llenado de nuez. Si la hoja se ve debil, '
              'corrige ligero junto con agua y K; no te pases porque ahora manda '
              'la nuez. Si hay pH alto y hoja chica, revisa zinc antes que N.';
        }
        return 'BioG detecta poco N para sostener hoja y brote del nogal. '
            'Aplica una correccion ligera y evita disparar follaje; revisa '
            'tambien agua, raiz y zinc contextual.';

      case AgroMetricKey.p:
        if (isUsefulHigh) {
          return 'BioG lee fosforo algo alto en nogal. No agregues mas P por '
              'ahora; en suelo calizo el P alto puede agravar disponibilidad de '
              'zinc/hierro.';
        }
        if (isRealExcess) {
          return 'Fosforo alto en nogal. Pausa fertilizantes fosfatados: el '
              'exceso puede bloquear micronutrientes (Zn/Fe) y no mejora la nuez.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Fosforo en rango para esta etapa del nogal. Manten el plan.';
        }
        if (isEarlyP) {
          return 'BioG detecta fosforo bajo en una etapa sensible. Corrige de '
              'forma moderada para apoyar raiz, brotacion y floracion; en pH '
              'alto confirma si es disponibilidad mas que falta total.';
        }
        return 'Fosforo bajo en nogal. Corrige sin excederte y con analisis; si '
            'el suelo esta frio o seco, primero estabiliza humedad para que lo tome.';

      case AgroMetricKey.k:
        if (isUsefulHigh) {
          return 'BioG lee K alto pero util para la nuez. No subas mas potasio '
              'si el llenado va bien; cuida que la salinidad no se dispare.$cautionSuffix';
        }
        if (isRealExcess) {
          return 'Potasio alto en nogal. Pausa K: demasiado potasio puede subir '
              'sales/EC y desbalancear magnesio y calcio.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Potasio en rango para esta etapa del nogal.';
        }
        if (isFruit) {
          return 'Potasio bajo en nogal. En crecimiento y llenado de nuez el K '
              'ayuda a calibre, llenado de almendra y calidad; refuerza K de '
              'forma gradual con riego parejo. Si la humedad esta baja, primero '
              'estabiliza agua.$cautionSuffix';
        }
        return 'BioG lee potasio bajo en nogal. Prepara el arbol para amarre y '
            'llenado de almendra con una correccion gradual.';

      default:
        return 'Revisa el manejo nutricional del nogal según su etapa.';
    }
  }

  // ── PISTACHE ───────────────────────────────────────────────────────────────
  // Guardas de suelo del pistache (doc 05 §0.2.12 E, §2.7, §8.7). Devuelve un
  // mensaje de guarda cuando agua/raíz/salinidad/pH deben mandar ANTES que NPK;
  // null si el suelo no bloquea. Umbrales: humedad crítica baja <45%; saturación
  // >90%; EC alta ~>4.5 dS/m (umbral CIAG; el pistache tolera más sal que otros
  // frutales, pero EC alta sigue bloqueando); pH alto >8.2. NO son dosis.
  static String? _pistachioSoilGuard({
    required String stage,
    double? ph,
    double? ec,
    double? soilMoisturePct,
  }) {
    final isFruitFill = stage.contains('fruit_fill');

    // 1) Saturación: oxígeno/raíz/drenaje primero. El pistache NO tolera mal
    // drenaje (no más agua ni fertilizante).
    if (soilMoisturePct != null && soilMoisturePct > 90) {
      return 'El suelo está saturado para el pistache, que no tolera mal '
          'drenaje. Más agua o fertilizante empeora el oxígeno de la raíz: '
          'revisa drenaje y aireación antes de tocar NPK.';
    }

    // 2) Humedad crítica baja: estabilizar agua antes que fertilizar.
    if (soilMoisturePct != null && soilMoisturePct < 45) {
      final tail = isFruitFill
          ? ' En llenado, el K sin agua no llena el pistache: se juega el '
                'kernel y la apertura.'
          : '';
      return 'Primero estabiliza la humedad: con raíz estresada el pistache '
          'aprovecha mal el NPK.$tail';
    }

    // 3) Salinidad alta (umbral CIAG ~4.5 dS/m): lavado/riego antes que NPK.
    if (ec != null && ec > 4.5) {
      final tail = isFruitFill
          ? ' Aunque el pistache aguanta sales, en llenado la EC alta castiga '
                'kernel y calidad.'
          : '';
      return 'La salinidad (EC) está alta en el pistache. Aguanta más sal que '
          'otros frutales, pero no apliques fertilización fuerte: prioriza '
          'riego de lavado, agua parejo y drenaje.$tail';
    }

    // 4) pH alto: disponibilidad de Fe/Zn/Cu/P, no más N.
    if (ph != null && ph > 8.2) {
      return 'El pH está alto para el pistache: puede haber bloqueo de hierro, '
          'zinc, cobre o fósforo aunque estén presentes. Revisa disponibilidad '
          'y micronutrientes contextuales antes de subir N. Confirma con '
          'análisis foliar.';
    }

    return null;
  }

  // Recomendaciones prácticas del pistache (doc 05 §8, §12, §19). Frutal de NUEZ
  // DIOICO. Reglas clave:
  // - N: motor de hoja/reservas/llenado, pero "más N no es más pistache": con
  //   baja carga se va a puro follaje; el N tardío retrasa latencia/helada.
  // - K: protagonista del kernel, split/open y calidad. Alta sensibilidad a K
  //   bajo en fruit_fill; K alto + EC alta NO se celebra.
  // - P: pesa en raíz/establecimiento/floración; en adulto no por costumbre.
  // - B/Zn/Cu/Fe contexto crítico (no sensor v1): con pH alto + hoja chica/
  //   clorosis no diagnosticar "falta de N".
  // - Contrato v1.5: fruit_fill habla de LLENADO de kernel (NO cosecha);
  //   harvest_maturity sí habla de apertura/cosecha/calidad/cerrados/vanos.
  static String _pistachioTreePracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    PistachioTreeNutritionModifier? modifier, {
    double? ph,
    double? ec,
    double? soilMoisturePct,
  }) {
    final guard = _pistachioSoilGuard(
      stage: stage,
      ph: ph,
      ec: ec,
      soilMoisturePct: soilMoisturePct,
    );
    if (guard != null) return guard;

    final isEstablishment =
        stage.contains('planting') || stage.contains('root_establish');
    final isEarlyP =
        isEstablishment ||
        stage.contains('budbreak') ||
        stage.contains('flower');
    final isFruitSet = stage.contains('fruit_set');
    final isFruitFill = stage.contains('fruit_fill');
    final isHarvestMaturity =
        stage.contains('harvest_maturity') ||
        (stage.contains('harvest') && !stage.contains('post_harvest'));
    final isPostHarvest = stage.contains('post_harvest');
    final isVegetative = stage.contains('vegetative_growth');
    final isFruit = isFruitSet || isFruitFill || isHarvestMaturity;
    final isUsefulHigh = label == NutrientPriorityLabel.possibleExcess;
    final isRealExcess = label == NutrientPriorityLabel.reviewAccumulation;
    final caution = modifier?.practicalCaution(nutrient, stage);
    final cautionSuffix = caution == null ? '' : ' $caution';

    switch (nutrient) {
      case AgroMetricKey.n:
        if (isUsefulHigh) {
          if (isHarvestMaturity) {
            return 'BioG lee N alto en madurez del pistache. No agregues más '
                'nitrógeno: cerca de cosecha el N tardío retrasa madurez, baja '
                'calidad y puede retrasar la latencia.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'BioG lee N alto en llenado de pistache. Frena el N: con '
                'poca carga se va a puro follaje y compite con el kernel; revisa '
                'agua, K y carga.$cautionSuffix';
          }
          if (isVegetative) {
            return 'BioG lee N alto en crecimiento del pistache. No empujes más '
                'brotes tiernos: dan sombra y vigor blando sin más pistache.$cautionSuffix';
          }
          return 'BioG lee N alto, todavía manejable. En pistache más N no es '
              'más pistache; vigila follaje, carga y sales.$cautionSuffix';
        }
        if (isRealExcess) {
          if (isHarvestMaturity) {
            return 'Nitrógeno alto en pistache. Frena fertilizantes '
                'nitrogenados: cerca de cosecha el N tardío castiga calidad y '
                'retrasa la entrada a reposo.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'Nitrógeno alto en llenado de pistache. No apliques más N: '
                'con baja carga se va a follaje y resta kernel; revisa carga, '
                'agua y EC.$cautionSuffix';
          }
          return 'BioG detecta nitrógeno de sobra en pistache. Más N no es más '
              'pistache: sube follaje, sombra y sales, y desbalancea con K.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Nitrógeno en rango para esta etapa del pistache. Mantén el '
              'plan y no apliques N extra por costumbre.';
        }
        if (isHarvestMaturity) {
          return 'BioG lee N bajo cerca de cosecha del pistache. No lo empujes '
              'ahora: el N tardío retrasa madurez y latencia y no llena un '
              'kernel ya hecho. Cuida calidad y, si la hoja sigue activa, deja '
              'el ajuste para postcosecha.';
        }
        if (isPostHarvest) {
          return 'BioG lee N bajo en postcosecha del pistache. No asumas que el '
              'árbol pide N: aporta solo ligero si la hoja sigue activa y la '
              'raíz trabaja, para reservas del próximo ciclo. Con hoja caída, '
              'frío de suelo o EC alta, mejor no fertilizar.';
        }
        if (isFruitFill) {
          return 'BioG lee N bajo en llenado de pistache. Si hay carga y la hoja '
              'se ve débil, corrige ligero junto con agua y K; no te pases '
              'porque ahora manda el kernel. Si hay pH alto y hoja chica, revisa '
              'zinc antes que N.';
        }
        return 'BioG detecta poco N para sostener hoja y brote del pistache. '
            'Aplica una corrección ligera por carga y evita disparar follaje; '
            'revisa también agua, raíz, EC y zinc contextual.';

      case AgroMetricKey.p:
        if (isUsefulHigh) {
          return 'BioG lee fósforo algo alto en pistache. No agregues más P por '
              'ahora; en suelo calizo el P alto puede agravar la disponibilidad '
              'de zinc/hierro.';
        }
        if (isRealExcess) {
          return 'Fósforo alto en pistache. Pausa fertilizantes fosfatados: el '
              'exceso puede bloquear micronutrientes (Zn/Fe) y no mejora el '
              'pistache.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Fósforo en rango para esta etapa del pistache. Mantén el plan; '
              'en adulto el P no se aplica por costumbre.';
        }
        if (isEarlyP) {
          return 'BioG detecta fósforo bajo en una etapa sensible. Corrige de '
              'forma moderada para apoyar raíz, brotación y floración; en pH '
              'alto confirma si es disponibilidad más que falta total. Si el '
              'pistache no amarró, primero revisa macho/hembra, frío y clima.';
        }
        return 'Fósforo bajo en pistache. Corrige sin excederte y con análisis; '
            'si el suelo está frío o seco, primero estabiliza humedad para que '
            'lo tome. En adulto rara vez es protagonista.';

      case AgroMetricKey.k:
        if (isUsefulHigh) {
          return 'BioG lee K alto pero útil para el pistache. No subas más '
              'potasio si el llenado va bien; cuida que la salinidad no se '
              'dispare.$cautionSuffix';
        }
        if (isRealExcess) {
          return 'Potasio alto en pistache. Pausa K: demasiado potasio puede '
              'subir sales/EC y desbalancear magnesio y calcio. No celebres K '
              'alto con EC alta.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Potasio en rango para esta etapa del pistache.';
        }
        if (isFruit) {
          return 'Potasio bajo en pistache. En cuajado y llenado el K ayuda al '
              'kernel, la apertura (split) y la calidad; refuérzalo de forma '
              'gradual en la zona mojada y con riego parejo. Si la humedad está '
              'baja, primero estabiliza agua.$cautionSuffix';
        }
        return 'BioG lee potasio bajo en pistache. Prepara el árbol para amarre '
            'y llenado de kernel con una corrección gradual.';

      default:
        return 'Revisa el manejo nutricional del pistache según su etapa.';
    }
  }

  // ── NARANJO ─────────────────────────────────────────────────────────────────
  // Guardas de suelo del naranjo (doc 05 §0.0.4 C-D, §3, §9). Devuelve un mensaje
  // de guarda cuando agua/raíz/salinidad/pH deben mandar ANTES que NPK; null si
  // el suelo no bloquea. Umbrales de sensor de campo: humedad crítica baja <45%;
  // saturación >90% (Phytophthora/gomosis/anoxia); EC alta >2.0 dS/m (el cítrico
  // es SENSIBLE a sales, umbral más bajo que nogal/pistache); pH alto >8.0
  // (bloqueo de Fe/Zn/Mn). NO son dosis.
  static String? _orangeSoilGuard({
    required String stage,
    double? ph,
    double? ec,
    double? soilMoisturePct,
  }) {
    final isFruitFill = stage.contains('fruit_fill');
    final isFruitSet = stage.contains('fruit_set');

    // 1) Saturación: oxígeno/raíz/drenaje primero. Suelo saturado favorece
    // Phytophthora/gomosis y anoxia; no más agua ni fertilizante.
    if (soilMoisturePct != null && soilMoisturePct > 90) {
      return 'El suelo está saturado para el naranjo: eso favorece gomosis, '
          'pudrición de raíz y anoxia. Marchito con suelo mojado NO es falta de '
          'agua: revisa drenaje, cuello y raíz antes de tocar NPK o regar más.';
    }

    // 2) Humedad crítica baja: estabilizar agua antes que fertilizar. En
    // floración/cuajado/llenado el naranjo no perdona el estrés hídrico.
    if (soilMoisturePct != null && soilMoisturePct < 45) {
      final tail = isFruitFill
          ? ' En llenado, el K sin agua no da calibre ni jugo: se juega la '
                'naranja.'
          : (isFruitSet
                ? ' En cuajado, la falta de agua tira frutito aunque el NPK esté '
                      'bien.'
                : '');
      return 'Primero estabiliza la humedad: con la raíz estresada el naranjo '
          'aprovecha mal el NPK.$tail';
    }

    // 3) Salinidad alta (cítrico sensible, ~>2.0 dS/m de sensor): lavado/riego
    // antes que NPK. Puede quemar borde de hoja y parecer falta de K.
    if (ec != null && ec > 2.0) {
      final tail = isFruitFill
          ? ' En llenado, la EC alta castiga calibre, jugo y hoja: no la '
                'confundas con falta de potasio.'
          : '';
      return 'La salinidad (EC) está alta para el naranjo, que es sensible a '
          'sales. No apliques fertilización fuerte: prioriza riego de lavado, '
          'agua pareja y drenaje. El sensor puede marcar nutrientes que el árbol '
          'no aprovecha.$tail';
    }

    // 4) pH alto: disponibilidad de Fe/Zn/Mn/P, no más N.
    if (ph != null && ph > 8.0) {
      return 'El pH está alto para el naranjo: puede haber bloqueo de hierro, '
          'zinc, manganeso o fósforo aunque estén presentes. Si la hoja nueva '
          'sale amarilla con nervadura verde, es contexto de micronutrientes, no '
          'falta de nitrógeno. Confirma con análisis foliar.';
    }

    return null;
  }

  // Recomendaciones prácticas del naranjo (doc 05 §8, §10, §14). Cítrico
  // SIEMPREVERDE de fruto fresco/jugo. Reglas clave:
  // - N: motor de hoja/brote/floración/soporte, pero "más N no es más naranja":
  //   con baja carga se va a follaje y cáscara; el N tardío retrasa color y baja
  //   calidad.
  // - K: protagonista de calibre, jugo, calidad y madurez. Alta sensibilidad a K
  //   bajo en fruit_fill; K alto + EC alta NO se celebra.
  // - P: pesa en raíz/establecimiento/floración; en adulto no por costumbre.
  // - Fe/Zn/Mn/B/Ca/Mg contexto (no sensor v1): con pH alto + hoja chica/
  //   clorosis internerval no diagnosticar "falta de N".
  // - Contrato v1.5: fruit_fill habla de LLENADO/calibre/jugo (NO cosecha);
  //   harvest_maturity sí habla de madurez/color/cosecha/calidad; dormancy es
  //   reposo relativo y post_harvest sigue activa (reservas).
  static String _orangeTreePracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    OrangeTreeNutritionModifier? modifier, {
    double? ph,
    double? ec,
    double? soilMoisturePct,
  }) {
    final guard = _orangeSoilGuard(
      stage: stage,
      ph: ph,
      ec: ec,
      soilMoisturePct: soilMoisturePct,
    );
    if (guard != null) return guard;

    final isEstablishment =
        stage.contains('planting') || stage.contains('root_establish');
    final isEarlyP =
        isEstablishment ||
        stage.contains('budbreak') ||
        stage.contains('flower');
    final isFruitSet = stage.contains('fruit_set');
    final isFruitFill = stage.contains('fruit_fill');
    final isHarvestMaturity =
        stage.contains('harvest_maturity') ||
        (stage.contains('harvest') && !stage.contains('post_harvest'));
    final isPostHarvest = stage.contains('post_harvest');
    final isVegetative = stage.contains('vegetative_growth');
    final isFruit = isFruitSet || isFruitFill || isHarvestMaturity;
    final isUsefulHigh = label == NutrientPriorityLabel.possibleExcess;
    final isRealExcess = label == NutrientPriorityLabel.reviewAccumulation;
    final caution = modifier?.practicalCaution(nutrient, stage);
    final cautionSuffix = caution == null ? '' : ' $caution';

    switch (nutrient) {
      case AgroMetricKey.n:
        if (isUsefulHigh) {
          if (isHarvestMaturity) {
            return 'BioG lee N alto en madurez del naranjo. No agregues más '
                'nitrógeno: cerca de cosecha el N tardío retrasa color, engrosa '
                'cáscara y baja calidad.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'BioG lee N alto en llenado de naranja. Frena el N: con poca '
                'carga se va a puro follaje y compite con el fruto; revisa agua, '
                'K y carga.$cautionSuffix';
          }
          if (isVegetative) {
            return 'BioG lee N alto en crecimiento del naranjo. No empujes más '
                'brotes tiernos: dan sombra, vigor blando y atraen psílido/'
                'minador sin más naranja.$cautionSuffix';
          }
          return 'BioG lee N alto, todavía manejable. En naranjo más N no es más '
              'naranja; vigila follaje, carga y sales.$cautionSuffix';
        }
        if (isRealExcess) {
          if (isHarvestMaturity) {
            return 'Nitrógeno alto en naranjo. Frena fertilizantes nitrogenados: '
                'cerca de cosecha el N tardío castiga color, cáscara y '
                'calidad.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'Nitrógeno alto en llenado de naranja. No apliques más N: con '
                'baja carga se va a follaje y resta calibre; revisa carga, agua y '
                'EC.$cautionSuffix';
          }
          return 'BioG detecta nitrógeno de sobra en naranjo. Más N no es más '
              'naranja: sube follaje, sombra y sales, y desbalancea con K.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Nitrógeno en rango para esta etapa del naranjo. Mantén el plan '
              'y no apliques N extra por costumbre.';
        }
        if (isHarvestMaturity) {
          return 'BioG lee N bajo cerca de cosecha del naranjo. No lo empujes '
              'ahora: el N tardío retrasa color y calidad y no llena una naranja '
              'ya hecha. Cuida calidad y, si la hoja sigue activa, deja el ajuste '
              'para postcosecha.';
        }
        if (isPostHarvest) {
          return 'BioG lee N bajo en postcosecha del naranjo. El árbol no se '
              'apaga: aporta solo ligero si la hoja sigue activa y la raíz '
              'trabaja, para reservas de la próxima floración. Con hoja caída, '
              'frío de suelo o EC alta, mejor no fertilizar.';
        }
        if (isFruitFill) {
          return 'BioG lee N bajo en llenado de naranja. Si hay carga y la hoja '
              'se ve débil, corrige ligero junto con agua y K; no te pases porque '
              'ahora manda el calibre. Si hay pH alto y hoja chica, revisa Fe/Zn/'
              'Mn antes que N.';
        }
        return 'BioG detecta poco N para sostener hoja y brote del naranjo. '
            'Aplica una corrección ligera por carga y evita disparar follaje; '
            'revisa también agua, raíz, EC y Fe/Zn/Mn contextual.';

      case AgroMetricKey.p:
        if (isUsefulHigh) {
          return 'BioG lee fósforo algo alto en naranjo. No agregues más P por '
              'ahora; en suelo calizo el P alto puede agravar la disponibilidad '
              'de zinc/hierro.';
        }
        if (isRealExcess) {
          return 'Fósforo alto en naranjo. Pausa fertilizantes fosfatados: el '
              'exceso puede bloquear micronutrientes (Zn/Fe) y no mejora la '
              'naranja.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Fósforo en rango para esta etapa del naranjo. Mantén el plan; '
              'en adulto el P no se aplica por costumbre.';
        }
        if (isEarlyP) {
          return 'BioG detecta fósforo bajo en una etapa sensible. Corrige de '
              'forma moderada para apoyar raíz, arranque y floración; en pH alto '
              'confirma si es disponibilidad más que falta total. En floración '
              'mandan agua y temperatura, no el fertilizante.';
        }
        return 'Fósforo bajo en naranjo. Corrige sin excederte y con análisis; si '
            'el suelo está frío o seco, primero estabiliza humedad para que lo '
            'tome. En adulto rara vez es protagonista.';

      case AgroMetricKey.k:
        if (isUsefulHigh) {
          return 'BioG lee K alto pero útil para el naranjo. No subas más potasio '
              'si el llenado va bien; cuida que la salinidad no se dispare.$cautionSuffix';
        }
        if (isRealExcess) {
          return 'Potasio alto en naranjo. Pausa K: demasiado potasio puede subir '
              'sales/EC y desbalancear magnesio y calcio. No celebres K alto con '
              'EC alta.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Potasio en rango para esta etapa del naranjo.';
        }
        if (isFruit) {
          return 'Potasio bajo en naranjo. En cuajado, llenado y madurez el K da '
              'calibre, jugo y calidad; refuérzalo de forma gradual en la zona '
              'mojada y con riego parejo. Si la humedad está baja o hay sales, '
              'primero estabiliza agua/sales.$cautionSuffix';
        }
        return 'BioG lee potasio bajo en naranjo. Prepara el árbol para el amarre '
            'y el llenado con una corrección gradual.';

      default:
        return 'Revisa el manejo nutricional del naranjo según su etapa.';
    }
  }

  // ── LIMÓN ───────────────────────────────────────────────────────────────────
  // Guardas de suelo del limón (doc 05 §9). Devuelve un mensaje de guarda cuando
  // agua/raíz/salinidad/pH deben mandar ANTES que NPK; null si el suelo no
  // bloquea. El limón es cítrico SENSIBLE a sales: umbral de EC más agresivo en
  // etapas reproductivas. Umbrales de sensor de campo: saturación >92%
  // (Phytophthora/gomosis/anoxia); humedad crítica baja <50% en floración/
  // cuajado/llenado, <42% en el resto; EC alta >=1.8 dS/m en reproducción,
  // >=2.1 en el resto; pH alto >=7.8 (bloqueo de Fe/Zn/Mn); compactación
  // (resistance) >=2.3. NO son dosis.
  static String? _lemonSoilGuard({
    required String stage,
    double? ph,
    double? ec,
    double? soilMoisturePct,
    double? resistance,
  }) {
    final isCriticalRepro =
        stage.contains('flower') ||
        stage.contains('fruit_set') ||
        stage.contains('fruit_fill');
    final isFruitFill = stage.contains('fruit_fill');
    final isFruitSet = stage.contains('fruit_set');

    // 1) Saturación: oxígeno/raíz/drenaje primero. Suelo saturado favorece
    // gomosis/Phytophthora y anoxia; no más agua ni fertilizante.
    if (soilMoisturePct != null && soilMoisturePct >= 92) {
      return 'El suelo está saturado para el limonero: eso favorece raíz '
          'asfixiada, gomosis y mala absorción. Marchito con suelo mojado NO es '
          'falta de agua: revisa drenaje y cuello antes de tocar NPK o regar '
          'más.';
    }

    // 2) Humedad crítica baja: estabilizar agua antes que fertilizar. En
    // floración/cuajado/llenado el limón no perdona el estrés hídrico.
    if (soilMoisturePct != null &&
        soilMoisturePct < (isCriticalRepro ? 50 : 42)) {
      final tail = isFruitFill
          ? ' En llenado, con flor, frutito o llenado la falta de agua tumba '
                'amarre y calibre aunque el NPK se vea corregible.'
          : (isFruitSet
                ? ' En cuajado, la falta de agua tira frutito aunque el NPK esté '
                      'bien.'
                : '');
      return 'Primero estabiliza la humedad: con la raíz estresada el limón '
          'aprovecha mal el NPK.$tail';
    }

    // 3) Salinidad alta (cítrico sensible): lavado/riego antes que NPK. Puede
    // quemar borde de hoja y parecer falta de K.
    if (ec != null && ec >= (isCriticalRepro ? 1.8 : 2.1)) {
      final tail = isCriticalRepro
          ? ' En floración/cuajado/llenado la EC alta castiga amarre, calibre, '
                'jugo y hoja: no la confundas con falta de potasio.'
          : '';
      return 'La salinidad (EC) está alta para el limón, que es sensible a '
          'sales. Puede haber nutrientes presentes que la raíz no toma bien: '
          'revisa agua, drenaje y acumulación de sales antes de subir NPK.$tail';
    }

    // 4) pH alto: disponibilidad de Fe/Zn/Mn/P, no más N.
    if (ph != null && ph >= 7.8) {
      return 'El pH está alto para el limón: puede bloquear hierro, zinc, '
          'manganeso o fósforo aunque estén presentes. Si la hoja nueva sale '
          'amarilla con nervadura verde, es contexto de micronutrientes, no '
          'falta de nitrógeno. Confirma con análisis foliar.';
    }

    // 5) Compactación: la raíz cítrica es superficial y necesita aire.
    if (resistance != null && resistance >= 2.3) {
      return 'El suelo está duro/compactado. La raíz del limón necesita aire y '
          'una zona mojada funcional; el NPK no resuelve la compactación.';
    }

    return null;
  }

  // Recomendaciones prácticas del limón (doc 05 §7, §10, §11). Cítrico
  // SIEMPREVERDE de producción frecuente. Reglas clave:
  // - N: motor de hoja/brote/floración/recuperación, pero "más N no es más
  //   limón": con baja carga se va a brote tierno y atrae psílido/minador; el N
  //   tardío da brote blando, caída y baja calidad.
  // - K: protagonista de amarre, calibre, jugo y calidad (cap más alto que
  //   naranjo). Alta sensibilidad a K bajo en fruit_fill; K alto + EC alta NO se
  //   celebra.
  // - P: pesa en raíz/establecimiento/floración; en adulto no por costumbre.
  // - Fe/Zn/Mn/B/Ca/Mg/S contexto (no sensor v1): con pH alto + hoja chica/
  //   clorosis internerval no diagnosticar "falta de N".
  // - Contrato v1.5: fruit_fill habla de LLENADO/calibre/jugo (NO cosecha);
  //   harvest_maturity puede ser corte verde comercial (persa/mexicano); dormancy
  //   es reposo relativo y post_harvest sigue activa (entre cortes).
  static String _lemonTreePracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    LemonTreeNutritionModifier? modifier, {
    double? ph,
    double? ec,
    double? soilMoisturePct,
  }) {
    final guard = _lemonSoilGuard(
      stage: stage,
      ph: ph,
      ec: ec,
      soilMoisturePct: soilMoisturePct,
    );
    if (guard != null) return guard;

    final isEstablishment =
        stage.contains('planting') || stage.contains('root_establish');
    final isEarlyP =
        isEstablishment ||
        stage.contains('budbreak') ||
        stage.contains('flower');
    final isFruitSet = stage.contains('fruit_set');
    final isFruitFill = stage.contains('fruit_fill');
    final isHarvestMaturity =
        stage.contains('harvest_maturity') ||
        (stage.contains('harvest') && !stage.contains('post_harvest'));
    final isPostHarvest = stage.contains('post_harvest');
    final isVegetative = stage.contains('vegetative_growth');
    final isFruit = isFruitSet || isFruitFill || isHarvestMaturity;
    final isUsefulHigh = label == NutrientPriorityLabel.possibleExcess;
    final isRealExcess = label == NutrientPriorityLabel.reviewAccumulation;
    final caution = modifier?.practicalCaution(nutrient, stage);
    final cautionSuffix = caution == null ? '' : ' $caution';

    switch (nutrient) {
      case AgroMetricKey.n:
        if (isUsefulHigh) {
          if (isHarvestMaturity) {
            return 'BioG lee N alto cerca del corte del limón. No agregues más '
                'nitrógeno: el N tardío da brote blando, caída y baja '
                'calidad.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'BioG lee N alto en llenado del limón. Frena el N: con poca '
                'carga se va a puro brote tierno y compite con el fruto; revisa '
                'agua, K y carga.$cautionSuffix';
          }
          if (isVegetative) {
            return 'BioG lee N alto en crecimiento del limón. No empujes más '
                'brote tierno: da follaje, vigor blando y atrae psílido/'
                'minador sin más limón.$cautionSuffix';
          }
          return 'BioG lee N alto, todavía manejable. En limón más N no es más '
              'limón; vigila brote tierno, carga y sales.$cautionSuffix';
        }
        if (isRealExcess) {
          if (isHarvestMaturity) {
            return 'Nitrógeno alto en limón. Frena fertilizantes nitrogenados: '
                'cerca del corte el N tardío castiga brote, caída y '
                'calidad.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'Nitrógeno alto en llenado del limón. No apliques más N: con '
                'baja carga se va a follaje y resta calibre; revisa carga, agua '
                'y EC.$cautionSuffix';
          }
          return 'BioG detecta nitrógeno de sobra en limón. Más N no es más '
              'limón: sube brote tierno, plagas y sales, y desbalancea con '
              'K.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Nitrógeno en rango para esta etapa del limón. Mantén el plan y '
              'no apliques N extra por costumbre.';
        }
        if (isHarvestMaturity) {
          return 'BioG lee N bajo cerca del corte del limón. No lo empujes '
              'ahora: el N tardío no llena un limón ya hecho y puede dar brote '
              'blando. Cuida calidad y, si la hoja sigue activa, deja el ajuste '
              'para postcosecha.';
        }
        if (isPostHarvest) {
          return 'BioG lee N bajo en postcosecha del limón. El árbol no se '
              'apaga: aporta solo ligero si la hoja sigue activa y la raíz '
              'trabaja, para reservas de la próxima floración/corte. Con hoja '
              'caída, frío de suelo o EC alta, mejor no fertilizar.';
        }
        if (isFruitFill) {
          return 'BioG lee N bajo en llenado del limón. Si hay carga y la hoja '
              'se ve débil, corrige ligero junto con agua y K; no te pases '
              'porque ahora manda el calibre. Si hay pH alto y hoja chica, '
              'revisa Fe/Zn/Mn antes que N.';
        }
        return 'BioG detecta poco N para sostener hoja y brote del limón. '
            'Aplica una corrección ligera por carga y evita disparar brote '
            'tierno; revisa también agua, raíz, EC y Fe/Zn/Mn contextual.';

      case AgroMetricKey.p:
        if (isUsefulHigh) {
          return 'BioG lee fósforo algo alto en limón. No agregues más P por '
              'ahora; en suelo calizo el P alto puede agravar la disponibilidad '
              'de zinc/hierro.';
        }
        if (isRealExcess) {
          return 'Fósforo alto en limón. Pausa fertilizantes fosfatados: el '
              'exceso puede bloquear micronutrientes (Zn/Fe) y no mejora el '
              'limón.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Fósforo en rango para esta etapa del limón. Mantén el plan; '
              'en adulto el P no se aplica por costumbre.';
        }
        if (isEarlyP) {
          return 'BioG detecta fósforo bajo en una etapa sensible. Corrige de '
              'forma moderada para apoyar raíz, arranque y floración; en pH alto '
              'confirma si es disponibilidad más que falta total. En floración '
              'mandan agua, temperatura y sales, no el fertilizante.';
        }
        return 'Fósforo bajo en limón. Corrige sin excederte y con análisis; si '
            'el suelo está frío o seco, primero estabiliza humedad para que lo '
            'tome. En adulto rara vez es protagonista.';

      case AgroMetricKey.k:
        if (isUsefulHigh) {
          return 'BioG lee K alto pero útil para el limón. No subas más potasio '
              'si el llenado va bien; cuida que la salinidad no se '
              'dispare.$cautionSuffix';
        }
        if (isRealExcess) {
          return 'Potasio alto en limón. Pausa K: demasiado potasio puede subir '
              'sales/EC y desbalancear magnesio y calcio. No celebres K alto con '
              'EC alta.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Potasio en rango para esta etapa del limón.';
        }
        if (isFruit) {
          return 'Potasio bajo en limón. En cuajado, llenado y madurez el K da '
              'calibre, jugo y calidad; refuérzalo de forma gradual en la zona '
              'mojada y con riego parejo. Si la humedad está baja o hay sales, '
              'primero estabiliza agua/sales.$cautionSuffix';
        }
        return 'BioG lee potasio bajo en limón. Prepara el árbol para el amarre '
            'y el llenado con una corrección gradual.';

      default:
        return 'Revisa el manejo nutricional del limón según su etapa.';
    }
  }

  // ── MANGO ─────────────────────────────────────────────────────────────────
  // Guardas de suelo del mango (doc 05 §9). Devuelve un mensaje de guarda cuando
  // agua/raíz/salinidad/pH deben mandar ANTES que NPK; null si el suelo no
  // bloquea. El mango es sensible a sales: umbral de EC más agresivo en etapas
  // reproductivas. Umbrales de sensor de campo: saturación >=90% (raíz/anoxia/
  // enfermedad); humedad crítica baja <50% en floración/cuajado/llenado; EC alta
  // >=1.8 dS/m en reproducción, >=2.0 en el resto; pH alto >=7.8 (bloqueo de
  // Fe/Zn/Mn/P); compactación (resistance) >=2.3. NO son dosis. El reposo
  // funcional NO se marca por humedad baja (puede tolerar más seco sin estrés).
  static String? _mangoSoilGuard({
    required String stage,
    double? ph,
    double? ec,
    double? soilMoisturePct,
    double? resistance,
  }) {
    final isCriticalRepro =
        stage.contains('flower') ||
        stage.contains('fruit_set') ||
        stage.contains('fruit_fill');
    final isFruitFill = stage.contains('fruit_fill');
    final isFruitSet = stage.contains('fruit_set');

    // 1) Saturación: oxígeno/raíz/drenaje primero. Suelo saturado favorece raíz
    // asfixiada y enfermedad; no más agua ni fertilizante.
    if (soilMoisturePct != null && soilMoisturePct >= 90) {
      return 'El suelo está saturado para el mango: eso favorece raíz asfixiada, '
          'pudrición y mala absorción. Marchito con suelo mojado NO es falta de '
          'agua: revisa drenaje y raíz antes de tocar NPK o regar más.';
    }

    // 2) Humedad crítica baja en reproducción: estabilizar agua antes que
    // fertilizar. En floración/cuajado/llenado el mango no perdona el estrés.
    if (isCriticalRepro && soilMoisturePct != null && soilMoisturePct < 50) {
      final tail = isFruitFill
          ? ' En llenado, la falta de agua se pega en calibre y calidad aunque '
                'el K se vea corregible.'
          : (isFruitSet
                ? ' En cuajado, la falta de agua tira el manguito aunque el NPK '
                      'esté bien.'
                : ' En floración, la falta de agua puede abortar flor aunque el '
                      'NPK esté bien.');
      return 'Primero estabiliza la humedad: con la raíz estresada el mango '
          'aprovecha mal el NPK.$tail';
    }

    // 3) Salinidad alta (sensible a sales): lavado/riego antes que NPK. Puede
    // quemar borde de hoja y parecer falta de K.
    if (ec != null && ec >= (isCriticalRepro ? 1.8 : 2.0)) {
      final tail = isCriticalRepro
          ? ' En floración/cuajado/llenado la EC alta castiga amarre, calibre y '
                'calidad: no la confundas con falta de potasio.'
          : '';
      return 'La salinidad (EC) está alta para el mango, que es sensible a '
          'sales. Puede haber nutrientes presentes que la raíz no toma bien: '
          'revisa agua, drenaje y acumulación de sales antes de subir NPK.$tail';
    }

    // 4) pH alto: disponibilidad de Fe/Zn/Mn/P, no más N.
    if (ph != null && ph >= 7.8) {
      return 'El pH está alto para el mango: puede bloquear hierro, zinc, '
          'manganeso o fósforo aunque estén presentes. Si la hoja nueva sale '
          'amarilla con nervadura verde, es contexto de micronutrientes, no '
          'falta de nitrógeno. Confirma con análisis foliar.';
    }

    // 5) Compactación: raíz funcional y drenaje mandan.
    if (resistance != null && resistance >= 2.3) {
      return 'El suelo está duro/compactado. La raíz del mango necesita aire y '
          'una zona mojada funcional; el NPK no resuelve la compactación.';
    }

    return null;
  }

  // Recomendaciones prácticas del mango (doc 05 §7, §10, §0.0.7). Árbol perenne
  // tropical de producción EPISÓDICA. Reglas clave:
  // - N: motor de hoja/brote/postcosecha, pero "más N no es más mango": en
  //   reposo/inducción el N alto empuja vegetativo y rompe la floración; en
  //   llenado mete brote y resta calibre; cerca del corte (variedades de cambio
  //   de color) baja color/firmeza/poscosecha.
  // - K: protagonista de amarre, calibre y calidad. Sensible a K bajo en
  //   fruit_fill; K alto + EC alta NO se celebra.
  // - P: pesa en raíz/establecimiento/floración; en adulto no por costumbre.
  // - Ca/B/Mg/Zn contexto (no sensor v1): en floración/cuajado/calidad; con pH
  //   alto + hoja chica/clorosis internerval no diagnosticar "falta de N".
  // - Contrato v1.5: fruit_fill habla de LLENADO/calibre (NO cosecha);
  //   harvest_maturity no decide madurez solo por color; dormancy es reposo
  //   funcional y post_harvest sigue activa (prepara la siguiente floración).
  static String _mangoTreePracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    MangoTreeNutritionModifier? modifier, {
    double? ph,
    double? ec,
    double? soilMoisturePct,
  }) {
    final guard = _mangoSoilGuard(
      stage: stage,
      ph: ph,
      ec: ec,
      soilMoisturePct: soilMoisturePct,
    );
    if (guard != null) return guard;

    final isEstablishment =
        stage.contains('planting') || stage.contains('root_establish');
    final isEarlyP =
        isEstablishment ||
        stage.contains('budbreak') ||
        stage.contains('flower');
    final isDormancy = stage.contains('dormancy');
    final isFruitSet = stage.contains('fruit_set');
    final isFruitFill = stage.contains('fruit_fill');
    final isHarvestMaturity =
        stage.contains('harvest_maturity') ||
        (stage.contains('harvest') && !stage.contains('post_harvest'));
    final isPostHarvest = stage.contains('post_harvest');
    final isVegetative = stage.contains('vegetative_growth');
    final isFruit = isFruitSet || isFruitFill || isHarvestMaturity;
    final isUsefulHigh = label == NutrientPriorityLabel.possibleExcess;
    final isRealExcess = label == NutrientPriorityLabel.reviewAccumulation;
    final caution = modifier?.practicalCaution(nutrient, stage);
    final cautionSuffix = caution == null ? '' : ' $caution';

    switch (nutrient) {
      case AgroMetricKey.n:
        if (isUsefulHigh) {
          if (isHarvestMaturity) {
            return 'BioG lee N alto cerca del corte del mango. No agregues más '
                'nitrógeno: en variedades que cambian de color el N tardío baja '
                'color, firmeza y calidad de poscosecha.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'BioG lee N alto en llenado del mango. Frena el N: con poca '
                'carga se va a brote y compite con el fruto; revisa agua, K y '
                'carga.$cautionSuffix';
          }
          if (isDormancy) {
            return 'BioG lee N alto en reposo/inducción del mango. No lo tomes '
                'como bueno: el N alto empuja brote vegetativo y puede romper la '
                'floración.$cautionSuffix';
          }
          if (isVegetative) {
            return 'BioG lee N alto en crecimiento del mango. No empujes más '
                'follaje: puede irse a puro brote y competir con la floración '
                'sin más mango.$cautionSuffix';
          }
          return 'BioG lee N alto, todavía manejable. En mango más N no es más '
              'mango; vigila brote, carga, etapa y sales.$cautionSuffix';
        }
        if (isRealExcess) {
          if (isHarvestMaturity) {
            return 'Nitrógeno alto en mango. Frena fertilizantes nitrogenados: '
                'cerca del corte el N tardío castiga color, firmeza y '
                'poscosecha.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'Nitrógeno alto en llenado del mango. No apliques más N: mete '
                'brote y resta calibre; revisa carga, agua y EC.$cautionSuffix';
          }
          if (isDormancy) {
            return 'Nitrógeno de sobra en reposo/inducción del mango. Puede '
                'mandar el árbol a puro brote y frenar la floración; no lo '
                'celebres.$cautionSuffix';
          }
          return 'BioG detecta nitrógeno de sobra en mango. Más N no es más '
              'mango: sube brote, plagas y sales, y desbalancea con '
              'K.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Nitrógeno en rango para esta etapa del mango. Mantén el plan y '
              'no apliques N extra por costumbre.';
        }
        if (isDormancy) {
          return 'BioG lee N bajo en reposo/inducción del mango. Aquí un N bajo '
              'no es problema: en preparación no conviene empujar brote. Cuida '
              'hoja madura y reservas, no fuerces N.';
        }
        if (isHarvestMaturity) {
          return 'BioG lee N bajo cerca del corte del mango. No lo empujes '
              'ahora: el N tardío no llena un mango ya hecho y puede bajar '
              'calidad/color. Deja el ajuste para postcosecha.';
        }
        if (isPostHarvest) {
          return 'BioG lee N bajo en postcosecha del mango. El árbol no se '
              'apaga: es la ventana fuerte de recuperación. Aporta N moderado si '
              'la hoja sigue activa y la raíz trabaja, para reservas de la '
              'próxima floración. Con hoja caída, EC alta o raíz mala, mejor no '
              'fertilizar.';
        }
        if (isFruitFill) {
          return 'BioG lee N bajo en llenado del mango. Si hay carga y la hoja '
              'se ve débil, corrige ligero junto con agua y K; no te pases '
              'porque ahora manda el calibre. Con pH alto y hoja chica, revisa '
              'Fe/Zn/Mn antes que N.';
        }
        return 'BioG detecta poco N para sostener hoja y brote del mango. '
            'Aplica una corrección ligera por carga y evita disparar puro brote; '
            'revisa también agua, raíz, EC y Fe/Zn/Mn contextual.';

      case AgroMetricKey.p:
        if (isUsefulHigh) {
          return 'BioG lee fósforo algo alto en mango. No agregues más P por '
              'ahora; en suelo calizo el P alto puede agravar la disponibilidad '
              'de zinc/hierro.';
        }
        if (isRealExcess) {
          return 'Fósforo alto en mango. Pausa fertilizantes fosfatados: el '
              'exceso puede bloquear micronutrientes (Zn/Fe) y no mejora el '
              'mango.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Fósforo en rango para esta etapa del mango. Mantén el plan; en '
              'adulto el P no se aplica por costumbre.';
        }
        if (isEarlyP) {
          return 'BioG detecta fósforo bajo en una etapa sensible. Corrige de '
              'forma moderada para apoyar raíz, arranque y floración; en pH alto '
              'confirma si es disponibilidad más que falta total. En floración '
              'mandan agua, temperatura, HR y sanidad, no el fertilizante.';
        }
        return 'Fósforo bajo en mango. Corrige sin excederte y con análisis; si '
            'el suelo está frío o seco, primero estabiliza humedad para que lo '
            'tome. En adulto rara vez es protagonista.';

      case AgroMetricKey.k:
        if (isUsefulHigh) {
          return 'BioG lee K alto pero útil para el mango. No subas más potasio '
              'si el llenado va bien; cuida que la salinidad no se '
              'dispare.$cautionSuffix';
        }
        if (isRealExcess) {
          return 'Potasio alto en mango. Pausa K: demasiado potasio puede subir '
              'sales/EC y desbalancear magnesio y calcio. No celebres K alto con '
              'EC alta.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Potasio en rango para esta etapa del mango.';
        }
        if (isFruit) {
          return 'Potasio bajo en mango. En cuajado, llenado y madurez el K da '
              'calibre y calidad; refuérzalo de forma gradual en la zona mojada '
              'y con riego parejo. Si la humedad está baja o hay sales, primero '
              'estabiliza agua/sales.$cautionSuffix';
        }
        return 'BioG lee potasio bajo en mango. Prepara el árbol para el amarre '
            'y el llenado con una corrección gradual.';

      default:
        return 'Revisa el manejo nutricional del mango según su etapa.';
    }
  }

  // ── AGUACATE ──────────────────────────────────────────────────────────────
  // Guardas de suelo del aguacate (doc 05 §0.3, §0.0.7). Devuelve un mensaje de
  // guarda cuando raíz/agua/salinidad/pH deben mandar ANTES que NPK; null si el
  // suelo no bloquea. El aguacate es MUY sensible a sales y a raíz sin oxígeno
  // (más que mango/cítricos): umbral de EC más agresivo. Umbrales de sensor de
  // campo: saturación >=90% (raíz/anoxia/Phytophthora); humedad crítica baja
  // <50% en floración/cuajado/llenado; EC alta >=1.6 dS/m en reproducción/raíz,
  // >=2.0 en el resto; pH alto >=7.6 (bloqueo de Fe/Zn/Mn/P/B); compactación
  // (resistance) >=2.2. NO son dosis. El reposo funcional NO se marca por humedad
  // baja (puede tolerar más seco sin estrés).
  static String? _avocadoSoilGuard({
    required String stage,
    double? ph,
    double? ec,
    double? soilMoisturePct,
    double? resistance,
  }) {
    final isRootEstablish = stage.contains('root_establish');
    final isCriticalRepro =
        stage.contains('flower') ||
        stage.contains('fruit_set') ||
        stage.contains('fruit_fill') ||
        isRootEstablish;
    final isFruitFill = stage.contains('fruit_fill');
    final isFruitSet = stage.contains('fruit_set');

    // 1) Saturación: oxígeno/raíz/drenaje primero. En aguacate el suelo saturado
    // favorece raíz asfixiada y Phytophthora; más agua puede EMPEORAR.
    if (soilMoisturePct != null && soilMoisturePct >= 90) {
      return 'El suelo está saturado para el aguacate: eso favorece raíz '
          'asfixiada, Phytophthora y mala absorción. Marchito con suelo mojado '
          'NO es falta de agua: revisa drenaje y raíz antes de tocar NPK o '
          'regar más.';
    }

    // 2) Humedad crítica baja en reproducción: estabilizar agua antes que
    // fertilizar. En floración/cuajado/llenado el aguacate no perdona el estrés.
    if (isCriticalRepro &&
        !isRootEstablish &&
        soilMoisturePct != null &&
        soilMoisturePct < 50) {
      final tail = isFruitFill
          ? ' En llenado, la falta de agua se pega en calibre y materia seca '
                'aunque el K se vea corregible.'
          : (isFruitSet
                ? ' En cuajado, la falta de agua tira el aguacatito aunque el '
                      'NPK esté bien.'
                : ' En floración, la falta de agua puede abortar flor aunque el '
                      'NPK esté bien.');
      return 'Primero estabiliza la humedad: con la raíz estresada el aguacate '
          'aprovecha mal el NPK.$tail';
    }

    // 3) Salinidad alta (muy sensible a sales/cloruros): lavado/agua antes que
    // NPK. Puede quemar borde de hoja vieja y parecer falta de K.
    if (ec != null && ec >= (isCriticalRepro ? 1.6 : 2.0)) {
      final tail = isCriticalRepro
          ? ' En floración/cuajado/llenado la EC alta castiga amarre, calibre y '
                'calidad: no la confundas con falta de potasio.'
          : '';
      return 'La salinidad (EC) está alta para el aguacate, que es muy sensible '
          'a sales, cloruros y sodio. Puede haber nutrientes presentes que la '
          'raíz no toma bien: revisa agua, drenaje y acumulación de sales antes '
          'de subir NPK. El sensor no distingue cloruro/sodio/boro.$tail';
    }

    // 4) pH alto: disponibilidad de Fe/Zn/Mn/P/B, no más N.
    if (ph != null && ph >= 7.6) {
      return 'El pH está alto para el aguacate: puede bloquear hierro, zinc, '
          'manganeso, fósforo o boro aunque estén presentes. Si la hoja nueva '
          'sale amarilla con nervadura verde, es contexto de micronutrientes, '
          'no falta de nitrógeno. Confirma con análisis foliar.';
    }

    // 5) Compactación: raíz fina superficial y drenaje mandan.
    if (resistance != null && resistance >= 2.2) {
      return 'El suelo está duro/compactado. La raíz fina y superficial del '
          'aguacate necesita aire y una zona mojada funcional; el NPK no '
          'resuelve la compactación.';
    }

    return null;
  }

  // Recomendaciones prácticas del aguacate (doc 05 §7, §0.0.8). Árbol perenne
  // subtropical siempreverde de cuajado FRÁGIL. Reglas clave:
  // - N: motor de hoja/brote/postcosecha, pero "más N no es más aguacate": en
  //   reposo/inducción el N alto empuja vegetativo y compite con la floración;
  //   en llenado mete brote y resta calibre/materia seca; cerca del corte mete
  //   brote y complica poscosecha (madura DESPUÉS del corte).
  // - K: protagonista de amarre, calibre y calidad. En floración NO al máximo
  //   (primero cuaja; doc 05 §0.0.1 pt4). Sensible a K bajo en fruit_fill; K
  //   alto + EC alta/cloruros NO se celebra.
  // - P: pesa en raíz/establecimiento/floración; en adulto no por costumbre.
  // - Ca/B/Mg/Zn contexto (no sensor v1): en floración/cuajado/calidad; con pH
  //   alto + hoja chica/clorosis internerval no diagnosticar "falta de N".
  // - Contrato v1.5: fruit_fill habla de LLENADO/calibre (NO cosecha);
  //   harvest_maturity no decide madurez solo por color; dormancy es reposo
  //   funcional (siempreverde) y post_harvest sigue activa.
  static String _avocadoTreePracticalRecommendation(
    AgroMetricKey nutrient,
    NutrientPriorityLabel label,
    String stage,
    AvocadoTreeNutritionModifier? modifier, {
    double? ph,
    double? ec,
    double? soilMoisturePct,
  }) {
    final guard = _avocadoSoilGuard(
      stage: stage,
      ph: ph,
      ec: ec,
      soilMoisturePct: soilMoisturePct,
    );
    if (guard != null) return guard;

    final isEstablishment =
        stage.contains('planting') || stage.contains('root_establish');
    final isEarlyP =
        isEstablishment ||
        stage.contains('budbreak') ||
        stage.contains('flower');
    final isDormancy = stage.contains('dormancy');
    final isFlowering =
        stage.contains('flower') && !stage.contains('fruit');
    final isFruitSet = stage.contains('fruit_set');
    final isFruitFill = stage.contains('fruit_fill');
    final isHarvestMaturity =
        stage.contains('harvest_maturity') ||
        (stage.contains('harvest') && !stage.contains('post_harvest'));
    final isPostHarvest = stage.contains('post_harvest');
    final isVegetative = stage.contains('vegetative_growth');
    final isFruit = isFruitSet || isFruitFill || isHarvestMaturity;
    final isUsefulHigh = label == NutrientPriorityLabel.possibleExcess;
    final isRealExcess = label == NutrientPriorityLabel.reviewAccumulation;
    final caution = modifier?.practicalCaution(nutrient, stage);
    final cautionSuffix = caution == null ? '' : ' $caution';

    switch (nutrient) {
      case AgroMetricKey.n:
        if (isUsefulHigh) {
          if (isHarvestMaturity) {
            return 'BioG lee N alto cerca del corte del aguacate. No agregues '
                'más nitrógeno: el N tardío mete brote y complica la poscosecha '
                '(el aguacate madura después del corte).$cautionSuffix';
          }
          if (isFruitFill) {
            return 'BioG lee N alto en llenado del aguacate. Frena el N: con '
                'poca carga se va a brote y compite con el fruto; revisa agua, K '
                'y carga.$cautionSuffix';
          }
          if (isDormancy) {
            return 'BioG lee N alto en reposo/inducción del aguacate. No lo '
                'tomes como bueno: el N alto empuja brote vegetativo y puede '
                'competir con la floración.$cautionSuffix';
          }
          if (isVegetative) {
            return 'BioG lee N alto en crecimiento del aguacate. No empujes más '
                'follaje: el exceso vegetativo compite con flor y '
                'fruto.$cautionSuffix';
          }
          return 'BioG lee N alto, todavía manejable. En aguacate más N no es '
              'más aguacate; vigila brote, carga, etapa y sales.$cautionSuffix';
        }
        if (isRealExcess) {
          if (isHarvestMaturity) {
            return 'Nitrógeno alto en aguacate. Frena fertilizantes '
                'nitrogenados: cerca del corte el N tardío mete brote y complica '
                'la poscosecha.$cautionSuffix';
          }
          if (isFruitFill) {
            return 'Nitrógeno alto en llenado del aguacate. No apliques más N: '
                'mete brote y resta calibre; revisa carga, agua y '
                'EC.$cautionSuffix';
          }
          if (isDormancy) {
            return 'Nitrógeno de sobra en reposo/inducción del aguacate. Puede '
                'mandar el árbol a puro brote y competir con la floración; no lo '
                'celebres.$cautionSuffix';
          }
          return 'BioG detecta nitrógeno de sobra en aguacate. Más N no es más '
              'aguacate: sube brote, plagas y sales, y desbalancea con Ca/K/'
              'Mg.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Nitrógeno en rango para esta etapa del aguacate. Mantén el '
              'plan y no apliques N extra por costumbre.';
        }
        if (isDormancy) {
          return 'BioG lee N bajo en reposo/inducción del aguacate. Aquí un N '
              'bajo no es problema: en preparación no conviene empujar brote. '
              'Cuida hoja madura, raíz y reservas, no fuerces N.';
        }
        if (isHarvestMaturity) {
          return 'BioG lee N bajo cerca del corte del aguacate. No lo empujes '
              'ahora: el N tardío no llena un aguacate ya hecho y puede meter '
              'brote. Deja el ajuste para postcosecha.';
        }
        if (isPostHarvest) {
          return 'BioG lee N bajo en postcosecha del aguacate. El árbol no se '
              'apaga: es la ventana viva de recuperación. Aporta N moderado si '
              'la hoja sigue activa y la raíz trabaja, para reservas de la '
              'próxima floración. Con hoja caída, EC alta o raíz mala, mejor no '
              'fertilizar.';
        }
        if (isFruitFill) {
          return 'BioG lee N bajo en llenado del aguacate. Si hay carga y la '
              'hoja se ve débil, corrige ligero junto con agua y K; no te pases '
              'porque ahora manda el calibre. Con pH alto y hoja chica, revisa '
              'Fe/Zn/Mn antes que N.';
        }
        return 'BioG detecta poco N para sostener hoja y brote del aguacate. '
            'Aplica una corrección ligera por carga y evita disparar puro brote; '
            'revisa también agua, raíz, EC y Fe/Zn/Mn contextual.';

      case AgroMetricKey.p:
        if (isUsefulHigh) {
          return 'BioG lee fósforo algo alto en aguacate. No agregues más P por '
              'ahora; en suelo calizo el P alto puede agravar la disponibilidad '
              'de zinc/hierro.';
        }
        if (isRealExcess) {
          return 'Fósforo alto en aguacate. Pausa fertilizantes fosfatados: el '
              'exceso puede bloquear micronutrientes (Zn/Fe) y no mejora el '
              'aguacate.';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Fósforo en rango para esta etapa del aguacate. Mantén el '
              'plan; en adulto el P no se aplica por costumbre.';
        }
        if (isEarlyP) {
          return 'BioG detecta fósforo bajo en una etapa sensible. Corrige de '
              'forma moderada para apoyar raíz, arranque y floración; en pH alto '
              'confirma si es disponibilidad más que falta total. En floración '
              'mandan agua, temperatura, polinización (A/B) y Ca/B/Zn, no el '
              'fertilizante.';
        }
        return 'Fósforo bajo en aguacate. Corrige sin excederte y con análisis; '
            'si el suelo está frío o seco, primero estabiliza humedad para que '
            'lo tome. En adulto rara vez es protagonista.';

      case AgroMetricKey.k:
        if (isUsefulHigh) {
          if (isFlowering) {
            return 'BioG lee K alto en floración del aguacate. Aquí el K aún no '
                'manda: primero cuaja. No lo celebres como si ya estuviera '
                'llenando fruta; cuida agua, clima y sales.$cautionSuffix';
          }
          return 'BioG lee K alto pero útil para el aguacate. No subas más '
              'potasio si el llenado va bien; cuida que la salinidad no se '
              'dispare (es muy sensible a cloruros).$cautionSuffix';
        }
        if (isRealExcess) {
          return 'Potasio alto en aguacate. Pausa K: demasiado potasio puede '
              'subir sales/EC y desbalancear magnesio y calcio. No celebres K '
              'alto con EC alta ni con cloruros.$cautionSuffix';
        }
        if (label == NutrientPriorityLabel.noPriority ||
            label == NutrientPriorityLabel.lowPriority) {
          return 'Potasio en rango para esta etapa del aguacate.';
        }
        if (isFruit) {
          return 'Potasio bajo en aguacate. En cuajado, llenado y madurez el K '
              'da calibre, materia seca y calidad; refuérzalo de forma gradual '
              'en la zona mojada y con riego parejo. Si la humedad está baja o '
              'hay sales, primero estabiliza agua/sales.$cautionSuffix';
        }
        return 'BioG lee potasio bajo en aguacate. Prepara el árbol para el '
            'amarre y el llenado con una corrección gradual, pero en floración '
            'aún mandan agua, polinización y clima.';

      default:
        return 'Revisa el manejo nutricional del aguacate según su etapa.';
    }
  }

  // Hortalizas de fruto SIN recomendación dedicada (cae al genérico).
  // Tomate, chile, berenjena y calabaza tienen su propio handler con
  // early-return de fin de ciclo y caution por perfil; no se incluyen aquí.
  static bool _isHortalizaFrutoSinHandler(String crop) {
    return crop == 'cucumber' || crop == 'pepino';
  }

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
    if (crop == 'wheat' || crop == 'trigo') {
      return s.contains('emerg') ||
          s.contains('vegearly') ||
          s.contains('early') ||
          s.contains('tiller') ||
          s.contains('macoll');
    }
    if (crop == 'oat' || crop == 'avena') {
      return s.contains('vegearly') ||
          s.contains('tiller') ||
          s.contains('macoll');
    }
    if (crop == 'tomato' || crop == 'tomate' || crop == 'jitomate') {
      // Antes de floración/cuajado la demanda sube fuerte (K, Ca).
      return s.contains('establec') || s.contains('vegetativo');
    }
    if (crop == 'chili' ||
        crop == 'chile' ||
        crop == 'pepper' ||
        crop == 'pimiento') {
      return s.contains('establec') ||
          s.contains('emerg') ||
          s.contains('vegetativo');
    }
    if (crop == 'eggplant' || crop == 'berenjena' || crop == 'aubergine') {
      return s.contains('establec') ||
          s.contains('emerg') ||
          s.contains('vegetativo');
    }
    if (crop == 'squash' ||
        crop == 'calabaza' ||
        crop == 'pumpkin' ||
        crop == 'zucchini' ||
        crop == 'calabacita') {
      return s.contains('establec') ||
          s.contains('emerg') ||
          s.contains('vegetativo');
    }
    return false;
  }

  static bool _isLateStage(String? stageKey) {
    final s = (stageKey ?? '').toLowerCase();
    // Hortalizas indeterminadas: cosecha progresiva es activamente productiva,
    // NO es late (sigue habiendo floración y cuajado en ramas/guías nuevas).
    if (s.contains('progresiv')) return false;
    return s.contains('matur') ||
        s.contains('senesc') ||
        s.contains('senescence') ||
        s.contains('harvest') ||
        s.contains('cosech') ||
        s.contains('late') ||
        s.contains('lateseason') ||
        s.contains('cierre') ||
        s.contains('cerrando') ||
        // finCiclo / fin_ciclo / fin ciclo en cualquier variante.
        s.contains('fincic') ||
        s.contains('fin_cic') ||
        s.contains('fin cic') ||
        s.contains('fin ciclo') ||
        s.contains('fin_ciclo');
  }

  // Mensaje compartido de cierre de ciclo para hortalizas de fruto.
  // No empuja N/P/K hacia floración/cuajado/llenado; pide guardar la lectura
  // para ajustar la base del siguiente ciclo.
  static String _hortalizaLateCycleMessage({
    required AgroMetricKey nutrient,
    required NutrientPriorityLabel label,
  }) {
    final isExcess =
        label == NutrientPriorityLabel.possibleExcess ||
        label == NutrientPriorityLabel.reviewAccumulation;

    if (isExcess) {
      return 'Hay acumulación al cierre del ciclo. No apliques más por ahora; '
          'registra el dato para evitar sales o desbalance en el siguiente ciclo.';
    }

    switch (nutrient) {
      case AgroMetricKey.n:
        return 'N bajo, pero el ciclo ya está cerrando. No conviene empujar follaje; '
            'guarda esta lectura para ajustar la base del siguiente ciclo.';
      case AgroMetricKey.p:
        return 'P bajo en cierre de ciclo. Úsalo como aprendizaje para el arrancador '
            'o base del próximo ciclo.';
      case AgroMetricKey.k:
        return 'K bajo, pero el ciclo ya está cerrando. No refuerces pensando en '
            'cuajado o llenado; guarda esta lectura para ajustar el siguiente ciclo.';
      default:
        return 'Lectura de cierre de ciclo: guárdala para ajustar la base del siguiente ciclo.';
    }
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
