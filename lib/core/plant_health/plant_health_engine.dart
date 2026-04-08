import 'package:bio_g/core/plant_health/plant_health_confidence.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';

class PlantHealthEngine {
  const PlantHealthEngine();

  PlantHealthResult? resolve({
    required PlantHealthInput input,
    required List<PlantHealthSyndrome> catalog,
  }) {
    final List<_ScoredSyndrome> candidates = <_ScoredSyndrome>[];

    for (final PlantHealthSyndrome syndrome in catalog.where(
      (PlantHealthSyndrome s) => s.cropId == input.cropId,
    )) {
      int score = 0;
      final List<String> why = <String>[];

      bool matchedStage = false;
      bool matchedOrgan = false;
      bool matchedPrimary = false;
      int strongMatches = 0;
      int weakMatches = 0;
      int conflictingMatches = 0;

      if (input.stageBucket != null &&
          syndrome.stages.contains(input.stageBucket)) {
        matchedStage = true;
        score += 22;
        why.add('Coincide con la etapa observada.');
      }
      if (syndrome.organIds.contains(input.organId)) {
        matchedOrgan = true;
        score += 24;
        why.add('Coincide con el órgano afectado.');
      }
      if (syndrome.primarySymptomId == input.primarySymptomId) {
        matchedPrimary = true;
        score += 34;
        why.add('Coincide con el síntoma principal.');
      }

      for (final String signal in input.secondarySignalIds) {
        if (syndrome.strongSignals.contains(signal)) {
          strongMatches += 1;
          score += 18;
          why.add('Confirmador fuerte presente.');
        } else if (syndrome.weakSignals.contains(signal)) {
          weakMatches += 1;
          score += 8;
          why.add('Confirmador secundario presente.');
        } else if (syndrome.conflictingSignals.contains(signal)) {
          conflictingMatches += 1;
          score -= 14;
        }
      }

      final _EnvironmentEffect environmentEffect = _applyEnvironmentHints(
        syndrome: syndrome,
        input: input,
      );
      score += environmentEffect.scoreDelta;
      if (environmentEffect.notes.isNotEmpty) {
        why.addAll(environmentEffect.notes);
      }

      final _VarietyEffect varietyEffect = _applyVarietyModifiers(
        syndrome: syndrome,
        varietyId: input.varietyId,
      );
      score += varietyEffect.scoreDelta;
      if (varietyEffect.notes.isNotEmpty) why.addAll(varietyEffect.notes);

      if (score > 0) {
        candidates.add(
          _ScoredSyndrome(
            syndrome: syndrome,
            score: score,
            why: why,
            varietyEffect: varietyEffect,
            matchedStage: matchedStage,
            matchedOrgan: matchedOrgan,
            matchedPrimary: matchedPrimary,
            strongMatches: strongMatches,
            weakMatches: weakMatches,
            conflictingMatches: conflictingMatches,
            environmentMatches: environmentEffect.matchedHints,
            confidence01: _estimateSyndromeConfidence(
              matchedStage: matchedStage,
              matchedOrgan: matchedOrgan,
              matchedPrimary: matchedPrimary,
              strongMatches: strongMatches,
              weakMatches: weakMatches,
              conflictingMatches: conflictingMatches,
              environmentMatches: environmentEffect.matchedHints,
              varietyAdjusted: varietyEffect.adjusted,
            ),
          ),
        );
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final _ScoredSyndrome best = candidates.first;
    final List<RankedDiagnosis> ranked = _rankDiagnoses(
      best: best,
      input: input,
    );

    final String? scaleCaution = _scaleCautionNote(input.cultivationScaleId);

    return PlantHealthResult(
      syndromeId: best.syndrome.id,
      syndromeLabelEs: best.syndrome.labelEs,
      severity: best.syndrome.severity,
      urgency: best.syndrome.urgency,
      topDiagnoses: ranked,
      confirmationChecksEs: best.syndrome.confirmationChecksEs,
      baseActionsEs: best.syndrome.baseActionsEs,
      disclaimerEs: best.syndrome.disclaimerEs,
      engineNotesEs: <String>[
        if (best.why.isNotEmpty) best.why.first,
        if (input.secondarySignalIds.isEmpty)
          'Faltan señales secundarias para confirmar; toma el resultado como orientación inicial.',
        if (scaleCaution != null) scaleCaution,
        PlantHealthConfidence.hintEs(best.confidence01),
      ],
    );
  }

  _EnvironmentEffect _applyEnvironmentHints({
    required PlantHealthSyndrome syndrome,
    required PlantHealthInput input,
  }) {
    int delta = 0;
    int matchedHints = 0;
    final List<String> notes = <String>[];

    if (syndrome.favorsHighHumidity && input.highHumidity == true) {
      delta += 5;
      matchedHints += 1;
      notes.add('El ambiente húmedo favorece este cuadro.');
    }
    if (syndrome.favorsCoolDewyWindow && input.coolDewyWindow == true) {
      delta += 5;
      matchedHints += 1;
      notes.add('La ventana fresca con rocío prolongado favorece este cuadro.');
    }
    if (syndrome.favorsVectorPressure && input.vectorPressure == true) {
      delta += 6;
      matchedHints += 1;
      notes.add('La presión de vector empuja esta sospecha.');
    }
    if (syndrome.favorsRecentStress && input.recentStress == true) {
      delta += 3;
      matchedHints += 1;
      notes.add('El estrés reciente mantiene abierto el diferencial.');
    }

    return _EnvironmentEffect(
      scoreDelta: delta,
      matchedHints: matchedHints,
      notes: notes,
    );
  }

  _VarietyEffect _applyVarietyModifiers({
    required PlantHealthSyndrome syndrome,
    required String? varietyId,
  }) {
    if (varietyId == null || varietyId.trim().isEmpty) {
      return const _VarietyEffect();
    }

    int scoreDelta = 0;
    bool adjusted = false;
    bool requiresCaution = false;
    final List<String> notes = <String>[];
    final Map<String, int> diagnosisBoosts = <String, int>{};

    for (final VarietyModifier modifier in syndrome.varietyModifiers) {
      if (!modifier.varietyIds.contains(varietyId)) continue;

      adjusted = true;
      scoreDelta += modifier.scoreDelta;
      requiresCaution = requiresCaution || modifier.requiresCaution;
      notes.add(modifier.rationaleEs);

      for (final String diagnosisId in modifier.diagnosisIds) {
        diagnosisBoosts[diagnosisId] =
            (diagnosisBoosts[diagnosisId] ?? 0) + modifier.scoreDelta;
      }
    }

    return _VarietyEffect(
      scoreDelta: scoreDelta,
      diagnosisBoosts: diagnosisBoosts,
      notes: notes,
      adjusted: adjusted,
      requiresCaution: requiresCaution,
    );
  }

  double _estimateSyndromeConfidence({
    required bool matchedStage,
    required bool matchedOrgan,
    required bool matchedPrimary,
    required int strongMatches,
    required int weakMatches,
    required int conflictingMatches,
    required int environmentMatches,
    required bool varietyAdjusted,
  }) {
    double value = 0;

    if (matchedPrimary) value += 0.36;
    if (matchedOrgan) value += 0.24;
    if (matchedStage) value += 0.14;

    value += _capCount(strongMatches, max: 2) * 0.10;
    value += _capCount(weakMatches, max: 2) * 0.04;
    value += _capCount(environmentMatches, max: 2) * 0.04;

    if (varietyAdjusted) value += 0.03;

    value -= _capCount(conflictingMatches, max: 2) * 0.14;

    if (!matchedPrimary || !matchedOrgan) {
      value -= 0.08;
    }

    return PlantHealthConfidence.clamp01(value);
  }

  List<RankedDiagnosis> _rankDiagnoses({
    required _ScoredSyndrome best,
    required PlantHealthInput input,
  }) {
    final List<PlantHealthDiagnosis> diagnoses =
        best.syndrome.probableDiagnoses;
    if (diagnoses.isEmpty) return const <RankedDiagnosis>[];

    final List<_DiagnosisDraft> drafts = <_DiagnosisDraft>[];

    for (int index = 0; index < diagnoses.length; index++) {
      final PlantHealthDiagnosis diagnosis = diagnoses[index];
      final int varietyBoost =
          best.varietyEffect.diagnosisBoosts[diagnosis.id] ?? 0;

      final Set<String> effectiveConfirmers = _effectiveConfirmatorySignals(
        syndrome: best.syndrome,
        diagnosis: diagnosis,
        diagnosesCount: diagnoses.length,
      );
      final Set<String> effectiveContradictions =
          _effectiveContradictorySignals(
            syndrome: best.syndrome,
            diagnosis: diagnosis,
            diagnosesCount: diagnoses.length,
          );
      final int diagnosisConfirmers = input.secondarySignalIds
          .where(effectiveConfirmers.contains)
          .length;
      final int diagnosisContradictions = input.secondarySignalIds
          .where(effectiveContradictions.contains)
          .length;
      final bool hasDifferentialMetadata =
          effectiveConfirmers.isNotEmpty || effectiveContradictions.isNotEmpty;

      final double priorLogit = _diagnosisPriorLogit(
        index,
        hasDifferentialMetadata: hasDifferentialMetadata,
      );
      final double varietyLogit = _varietyLogit(varietyBoost);
      final double differentialLogit =
          (diagnosisConfirmers * 0.92) - (diagnosisContradictions * 1.05);

      final double rawScore =
          best.score.toDouble() +
          _diagnosisOrderBias(
            index,
            hasDifferentialMetadata: hasDifferentialMetadata,
          ) +
          varietyBoost.toDouble() +
          (diagnosisConfirmers * 11) -
          (diagnosisContradictions * 13);

      drafts.add(
        _DiagnosisDraft(
          diagnosis: diagnosis,
          rawScore: rawScore,
          logit: priorLogit + varietyLogit + differentialLogit,
          whyEs: <String>[
            diagnosis.summaryEs,
            ...best.why.take(3),
            if (diagnosisConfirmers > 0)
              'Hay señales observadas que empujan específicamente este diferencial.',
            if (diagnosisContradictions > 0)
              'Hay señales observadas que le restan fuerza frente a otros diferenciales.',
            if (varietyBoost != 0)
              'La bandera varietal modificó esta probabilidad relativa.',
          ],
          varietyAdjusted: best.varietyEffect.adjusted && varietyBoost != 0,
          requiresCaution: best.varietyEffect.requiresCaution,
        ),
      );
    }

    final List<double> logits = drafts
        .map((draft) => draft.logit)
        .toList(growable: false);

    final double temperature = _diagnosisTemperature(best.confidence01);
    List<double> probabilities = PlantHealthConfidence.softmax(
      logits,
      temperature: temperature,
    );

    final double competitionWeight = 0.38 + (best.confidence01 * 0.57);
    probabilities = PlantHealthConfidence.blendWithUniform(
      probabilities,
      weight: competitionWeight,
    );

    probabilities = PlantHealthConfidence.enforceTopCap(
      probabilities,
      cap: _topProbabilityCap(
        best: best,
        probabilities: probabilities,
        input: input,
      ),
    );

    final List<RankedDiagnosis> ranked = <RankedDiagnosis>[
      for (int i = 0; i < drafts.length; i++)
        RankedDiagnosis(
          diagnosis: drafts[i].diagnosis,
          rawScore: drafts[i].rawScore,
          confidence01: best.confidence01,
          displayProbability01: probabilities[i],
          whyEs: drafts[i].whyEs,
          varietyAdjusted: drafts[i].varietyAdjusted,
          requiresCaution: drafts[i].requiresCaution,
        ),
    ];

    ranked.sort(
      (RankedDiagnosis a, RankedDiagnosis b) =>
          b.displayProbability01.compareTo(a.displayProbability01),
    );

    return ranked.take(3).toList(growable: false);
  }

  double _capCount(int value, {required int max}) {
    if (value <= 0) return 0;
    if (value >= max) return max.toDouble();
    return value.toDouble();
  }

  Set<String> _effectiveConfirmatorySignals({
    required PlantHealthSyndrome syndrome,
    required PlantHealthDiagnosis diagnosis,
    required int diagnosesCount,
  }) {
    if (diagnosis.confirmatorySignalIds.isNotEmpty) {
      return diagnosis.confirmatorySignalIds;
    }
    if (diagnosesCount == 1) {
      return <String>{...syndrome.strongSignals, ...syndrome.weakSignals};
    }
    return const <String>{};
  }

  Set<String> _effectiveContradictorySignals({
    required PlantHealthSyndrome syndrome,
    required PlantHealthDiagnosis diagnosis,
    required int diagnosesCount,
  }) {
    if (diagnosis.contradictorySignalIds.isNotEmpty) {
      return diagnosis.contradictorySignalIds;
    }
    if (diagnosesCount == 1) {
      return syndrome.conflictingSignals;
    }
    return const <String>{};
  }

  double _varietyLogit(int varietyBoost) {
    if (varietyBoost == 0) return 0;
    final double scaled = varietyBoost / 9.0;
    if (scaled > 1.2) return 1.2;
    if (scaled < -1.2) return -1.2;
    return scaled;
  }

  double _diagnosisPriorLogit(
    int index, {
    required bool hasDifferentialMetadata,
  }) {
    if (hasDifferentialMetadata) {
      return switch (index) {
        0 => 0.42,
        1 => 0.00,
        2 => -0.24,
        _ => -0.42 - ((index - 3) * 0.18),
      };
    }

    return switch (index) {
      0 => 0.18,
      1 => 0.00,
      2 => -0.12,
      _ => -0.24 - ((index - 3) * 0.12),
    };
  }

  double _diagnosisOrderBias(
    int index, {
    required bool hasDifferentialMetadata,
  }) {
    final double base = switch (index) {
      0 => 3.0,
      1 => 0.0,
      2 => -2.2,
      _ => -3.4 - ((index - 3) * 1.1),
    };
    return hasDifferentialMetadata ? base : (base * 0.45);
  }

  double _diagnosisTemperature(double confidence01) {
    final double clamped = PlantHealthConfidence.clamp01(confidence01);
    return 1.55 + ((0.72 - 1.55) * clamped);
  }

  double _topProbabilityCap({
    required _ScoredSyndrome best,
    required List<double> probabilities,
    required PlantHealthInput input,
  }) {
    final double scaleCap = _scaleTopProbabilityCap(input.cultivationScaleId);
    if (probabilities.length <= 1) return scaleCap;
    if (input.secondarySignalIds.isEmpty) {
      return scaleCap < 0.60 ? scaleCap : 0.60;
    }

    final List<double> sorted = List<double>.from(probabilities)
      ..sort((a, b) => b.compareTo(a));

    final double top = sorted[0];
    final double second = sorted[1];
    final double gap = top - second;

    final bool allowRareHundred =
        best.strongMatches > 0 &&
        best.conflictingMatches == 0 &&
        best.confidence01 >= 0.94 &&
        gap >= 0.55;

    double cap;
    if (allowRareHundred) {
      cap = 0.995;
    } else if (best.conflictingMatches > 0) {
      cap = 0.82;
    } else if (best.strongMatches > 0 &&
        best.confidence01 >= 0.84 &&
        gap >= 0.28) {
      cap = 0.92;
    } else if (best.confidence01 >= 0.72) {
      cap = 0.88;
    } else {
      cap = 0.80;
    }

    return cap < scaleCap ? cap : scaleCap;
  }

  double _scaleTopProbabilityCap(String? cultivationScaleId) {
    final String scale = cultivationScaleId?.trim().toLowerCase() ?? '';
    return switch (scale) {
      'pot' => 0.78,
      'bed' => 0.88,
      _ => 0.995,
    };
  }

  String? _scaleCautionNote(String? cultivationScaleId) {
    final String scale = cultivationScaleId?.trim().toLowerCase() ?? '';
    return switch (scale) {
      'pot' =>
        'El resultado en maceta se muestra con cautela extra porque el motor está mejor calibrado para condiciones de lote.',
      'bed' =>
        'El resultado en huerto se muestra con cautela moderada; conviene confirmar señales antes de cerrar diagnóstico.',
      _ => null,
    };
  }
}

class _ScoredSyndrome {
  final PlantHealthSyndrome syndrome;
  final int score;
  final List<String> why;
  final _VarietyEffect varietyEffect;
  final bool matchedStage;
  final bool matchedOrgan;
  final bool matchedPrimary;
  final int strongMatches;
  final int weakMatches;
  final int conflictingMatches;
  final int environmentMatches;
  final double confidence01;

  const _ScoredSyndrome({
    required this.syndrome,
    required this.score,
    required this.why,
    required this.varietyEffect,
    required this.matchedStage,
    required this.matchedOrgan,
    required this.matchedPrimary,
    required this.strongMatches,
    required this.weakMatches,
    required this.conflictingMatches,
    required this.environmentMatches,
    required this.confidence01,
  });
}

class _VarietyEffect {
  final int scoreDelta;
  final Map<String, int> diagnosisBoosts;
  final List<String> notes;
  final bool adjusted;
  final bool requiresCaution;

  const _VarietyEffect({
    this.scoreDelta = 0,
    this.diagnosisBoosts = const <String, int>{},
    this.notes = const <String>[],
    this.adjusted = false,
    this.requiresCaution = false,
  });
}

class _EnvironmentEffect {
  final int scoreDelta;
  final int matchedHints;
  final List<String> notes;

  const _EnvironmentEffect({
    this.scoreDelta = 0,
    this.matchedHints = 0,
    this.notes = const <String>[],
  });
}

class _DiagnosisDraft {
  final PlantHealthDiagnosis diagnosis;
  final double rawScore;
  final double logit;
  final List<String> whyEs;
  final bool varietyAdjusted;
  final bool requiresCaution;

  const _DiagnosisDraft({
    required this.diagnosis,
    required this.rawScore,
    required this.logit,
    required this.whyEs,
    required this.varietyAdjusted,
    required this.requiresCaution,
  });
}
