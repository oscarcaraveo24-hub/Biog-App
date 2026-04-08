import 'package:bio_g/core/plant_health/plant_health_stage_bucket.dart';

enum PlantHealthSeverity { low, medium, high, critical }

enum PlantHealthUrgency { monitor72h, review48h, review24h, sameDay, immediate }

class PlantHealthDiagnosis {
  final String id;
  final String labelEs;
  final String scientificName;
  final String type;
  final String summaryEs;

  /// Señales que empujan específicamente este diferencial dentro del síndrome.
  final Set<String> confirmatorySignalIds;

  /// Señales que le restan fuerza a este diferencial dentro del síndrome.
  final Set<String> contradictorySignalIds;

  const PlantHealthDiagnosis({
    required this.id,
    required this.labelEs,
    this.scientificName = '',
    required this.type,
    required this.summaryEs,
    this.confirmatorySignalIds = const <String>{},
    this.contradictorySignalIds = const <String>{},
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label_es': labelEs,
    'scientific_name': scientificName,
    'type': type,
    'summary_es': summaryEs,
    'confirmatory_signal_ids': confirmatorySignalIds.toList(growable: false),
    'contradictory_signal_ids': contradictorySignalIds.toList(growable: false),
  };
}

class VarietyModifier {
  final String cropId;
  final Set<String> varietyIds;
  final Set<String> diagnosisIds;
  final int scoreDelta;
  final String rationaleEs;
  final bool isProxy;
  final bool requiresCaution;

  const VarietyModifier({
    required this.cropId,
    required this.varietyIds,
    required this.diagnosisIds,
    required this.scoreDelta,
    required this.rationaleEs,
    this.isProxy = false,
    this.requiresCaution = false,
  });
}

class PlantHealthSyndrome {
  final String id;
  final String cropId;
  final String labelEs;
  final Set<PlantHealthStageBucket> stages;
  final Set<String> organIds;
  final String primarySymptomId;
  final Set<String> strongSignals;
  final Set<String> weakSignals;
  final Set<String> conflictingSignals;
  final List<PlantHealthDiagnosis> probableDiagnoses;
  final List<String> confirmationChecksEs;
  final PlantHealthSeverity severity;
  final PlantHealthUrgency urgency;
  final List<String> baseActionsEs;
  final String disclaimerEs;
  final List<VarietyModifier> varietyModifiers;
  final bool favorsHighHumidity;
  final bool favorsCoolDewyWindow;
  final bool favorsVectorPressure;
  final bool favorsRecentStress;

  const PlantHealthSyndrome({
    required this.id,
    required this.cropId,
    required this.labelEs,
    required this.stages,
    required this.organIds,
    required this.primarySymptomId,
    this.strongSignals = const <String>{},
    this.weakSignals = const <String>{},
    this.conflictingSignals = const <String>{},
    this.probableDiagnoses = const <PlantHealthDiagnosis>[],
    this.confirmationChecksEs = const <String>[],
    required this.severity,
    required this.urgency,
    this.baseActionsEs = const <String>[],
    this.disclaimerEs = '',
    this.varietyModifiers = const <VarietyModifier>[],
    this.favorsHighHumidity = false,
    this.favorsCoolDewyWindow = false,
    this.favorsVectorPressure = false,
    this.favorsRecentStress = false,
  });
}

class PlantHealthInput {
  final String deviceId;
  final String cropId;
  final String? varietyId;
  final PlantHealthStageBucket? stageBucket;
  final String organId;
  final String primarySymptomId;
  final Set<String> secondarySignalIds;
  final String? cultivationScaleId;
  final bool? highHumidity;
  final bool? coolDewyWindow;
  final bool? recentStress;
  final bool? vectorPressure;

  const PlantHealthInput({
    required this.deviceId,
    required this.cropId,
    required this.organId,
    required this.primarySymptomId,
    this.varietyId,
    this.stageBucket,
    this.secondarySignalIds = const <String>{},
    this.cultivationScaleId,
    this.highHumidity,
    this.coolDewyWindow,
    this.recentStress,
    this.vectorPressure,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'device_id': deviceId,
    'crop_id': cropId,
    'variety_id': varietyId,
    'stage_bucket': stageBucket?.name,
    'organ_id': organId,
    'primary_symptom_id': primarySymptomId,
    'secondary_signal_ids': secondarySignalIds.toList(growable: false),
    'cultivation_scale_id': cultivationScaleId,
    'high_humidity': highHumidity,
    'cool_dewy_window': coolDewyWindow,
    'recent_stress': recentStress,
    'vector_pressure': vectorPressure,
  };
}

class RankedDiagnosis {
  final PlantHealthDiagnosis diagnosis;

  /// Score crudo interno del motor antes de normalizar contra competidores.
  final double rawScore;

  /// Confianza absoluta del cuadro/síndrome ganador.
  /// Sirve como señal interna de qué tan sólido estuvo el match clínico base.
  final double confidence01;

  /// Probabilidad relativa para mostrar al usuario.
  /// Esta es la que debe pintar la UI como porcentaje final.
  final double displayProbability01;

  final List<String> whyEs;
  final bool varietyAdjusted;
  final bool requiresCaution;

  const RankedDiagnosis({
    required this.diagnosis,
    required this.rawScore,
    required this.confidence01,
    required this.displayProbability01,
    required this.whyEs,
    this.varietyAdjusted = false,
    this.requiresCaution = false,
  });

  /// Alias legado para minimizar rompimientos si algo externo todavía lee `score`.
  double get score => rawScore;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'diagnosis': diagnosis.toJson(),
    'raw_score': rawScore,
    'score': rawScore,
    'confidence_01': confidence01,
    'display_probability_01': displayProbability01,
    'why_es': whyEs,
    'variety_adjusted': varietyAdjusted,
    'requires_caution': requiresCaution,
  };
}

class PlantHealthResult {
  final String syndromeId;
  final String syndromeLabelEs;
  final PlantHealthSeverity severity;
  final PlantHealthUrgency urgency;
  final List<RankedDiagnosis> topDiagnoses;
  final List<String> confirmationChecksEs;
  final List<String> baseActionsEs;
  final String disclaimerEs;
  final List<String> engineNotesEs;

  const PlantHealthResult({
    required this.syndromeId,
    required this.syndromeLabelEs,
    required this.severity,
    required this.urgency,
    required this.topDiagnoses,
    required this.confirmationChecksEs,
    required this.baseActionsEs,
    required this.disclaimerEs,
    this.engineNotesEs = const <String>[],
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'syndrome_id': syndromeId,
    'syndrome_label_es': syndromeLabelEs,
    'severity': severity.name,
    'urgency': urgency.name,
    'top_diagnoses': topDiagnoses
        .map((d) => d.toJson())
        .toList(growable: false),
    'confirmation_checks_es': confirmationChecksEs,
    'base_actions_es': baseActionsEs,
    'disclaimer_es': disclaimerEs,
    'engine_notes_es': engineNotesEs,
  };
}

class PlantHealthReportSnapshot {
  final String title;
  final String topDiagnosis;
  final String confidenceLabel;
  final String severityLabel;
  final String urgencyLabel;
  final List<String> confirmationChecks;
  final List<String> baseActions;

  const PlantHealthReportSnapshot({
    required this.title,
    required this.topDiagnosis,
    required this.confidenceLabel,
    required this.severityLabel,
    required this.urgencyLabel,
    required this.confirmationChecks,
    required this.baseActions,
  });
}
