// lib/core/agro/agro_types.dart
import 'package:bio_g/models/biog_telemetry.dart';

/// Métricas que el motor interpreta.
enum AgroMetricKey { soilMoisture, soilTemp, ph, ec, resistance, n, p, k }

extension AgroMetricKeyX on AgroMetricKey {
  bool get isNutrient =>
      this == AgroMetricKey.n ||
      this == AgroMetricKey.p ||
      this == AgroMetricKey.k;

  String get labelEs {
    switch (this) {
      case AgroMetricKey.soilMoisture:
        return 'Humedad';
      case AgroMetricKey.soilTemp:
        return 'Temperatura';
      case AgroMetricKey.ph:
        return 'pH';
      case AgroMetricKey.ec:
        return 'CE';
      case AgroMetricKey.resistance:
        return 'Resistencia';
      case AgroMetricKey.n:
        return 'Nitrógeno';
      case AgroMetricKey.p:
        return 'Fósforo';
      case AgroMetricKey.k:
        return 'Potasio';
    }
  }

  String get shortLabel {
    switch (this) {
      case AgroMetricKey.soilMoisture:
        return 'Humedad';
      case AgroMetricKey.soilTemp:
        return 'Temp';
      case AgroMetricKey.ph:
        return 'pH';
      case AgroMetricKey.ec:
        return 'CE';
      case AgroMetricKey.resistance:
        return 'Resist';
      case AgroMetricKey.n:
        return 'N';
      case AgroMetricKey.p:
        return 'P';
      case AgroMetricKey.k:
        return 'K';
    }
  }

  String get defaultUnit {
    switch (this) {
      case AgroMetricKey.soilMoisture:
        return '%';
      case AgroMetricKey.soilTemp:
        return '°C';
      case AgroMetricKey.ph:
        return 'pH';
      case AgroMetricKey.ec:
        return 'mS/cm';
      case AgroMetricKey.resistance:
        return 'MPa';
      case AgroMetricKey.n:
      case AgroMetricKey.p:
      case AgroMetricKey.k:
        return 'mg/kg';
    }
  }
}

enum AgroBand { low, optimal, high, critical, unknown }

extension AgroBandX on AgroBand {
  String get labelEs {
    switch (this) {
      case AgroBand.low:
        return 'Bajo';
      case AgroBand.optimal:
        return 'Óptimo';
      case AgroBand.high:
        return 'Alto';
      case AgroBand.critical:
        return 'Crítico';
      case AgroBand.unknown:
        return '—';
    }
  }

  bool get isKnown => this != AgroBand.unknown;
}

/// Nuevo lenguaje operativo para NPK (PREMIUM Y CORTO)
enum NutrientPriorityLabel {
  noPriority,
  lowPriority,
  mediumPriority,
  highPriority,
  reviewManagement,
  actionRecommended,
  possibleExcess,
  reviewAccumulation,
  unknown,
}

extension NutrientPriorityLabelX on NutrientPriorityLabel {
  String get labelEs {
    switch (this) {
      case NutrientPriorityLabel.noPriority:
        return 'Óptimo'; // Antes: Lectura favorable
      case NutrientPriorityLabel.lowPriority:
        return 'Vigilar'; // Antes: Seguimiento activo
      case NutrientPriorityLabel.mediumPriority:
        return 'Atención'; // Antes: Punto de atención
      case NutrientPriorityLabel.highPriority:
        return 'Falta Nutriente'; // Antes: Nutriente clave
      case NutrientPriorityLabel.reviewManagement:
        return 'Ajustar Dosis'; // Antes: Ajuste recomendado
      case NutrientPriorityLabel.actionRecommended:
        return 'Urge Aplicar'; // Antes: Acción sugerida
      case NutrientPriorityLabel.possibleExcess:
        return 'Pausar (Exceso)'; // Antes: Posible acumulación
      case NutrientPriorityLabel.reviewAccumulation:
        return 'Alerta Exceso'; // Antes: Revisar acumulación
      case NutrientPriorityLabel.unknown:
        return '—';
    }
  }

  int get severityRank {
    switch (this) {
      case NutrientPriorityLabel.noPriority:
        return 0;
      case NutrientPriorityLabel.lowPriority:
        return 1;
      case NutrientPriorityLabel.mediumPriority:
        return 2;
      case NutrientPriorityLabel.highPriority:
        return 3;
      case NutrientPriorityLabel.reviewManagement:
        return 4;
      case NutrientPriorityLabel.actionRecommended:
        return 5;
      case NutrientPriorityLabel.possibleExcess:
        return 4;
      case NutrientPriorityLabel.reviewAccumulation:
        return 3;
      case NutrientPriorityLabel.unknown:
        return -1;
    }
  }

  bool get isKnown => this != NutrientPriorityLabel.unknown;
  bool get suggestsAction =>
      this == NutrientPriorityLabel.actionRecommended ||
      this == NutrientPriorityLabel.highPriority ||
      this == NutrientPriorityLabel.reviewManagement;

  /// Severidad operativa para scoring global.
  ///
  /// A diferencia del motor de interpretación, este helper sí trata
  /// `noPriority` como 0.0 para que una lectura sana no castigue el score.
  double severityScore01({double stagePressure01 = 0.0}) {
    final pressure = stagePressure01.clamp(0.0, 1.0);

    final base = switch (this) {
      NutrientPriorityLabel.noPriority => 0.00,
      NutrientPriorityLabel.lowPriority => 0.08,
      NutrientPriorityLabel.mediumPriority => 0.24,
      NutrientPriorityLabel.highPriority => 0.48,
      NutrientPriorityLabel.reviewManagement => 0.58,
      NutrientPriorityLabel.actionRecommended => 0.78,
      NutrientPriorityLabel.possibleExcess => 0.46,
      NutrientPriorityLabel.reviewAccumulation => 0.68,
      NutrientPriorityLabel.unknown => 1.00,
    };

    final pressureExtra = switch (this) {
      NutrientPriorityLabel.noPriority => 0.00,
      NutrientPriorityLabel.lowPriority => 0.00,
      NutrientPriorityLabel.mediumPriority => 0.04 * pressure,
      NutrientPriorityLabel.highPriority => 0.08 * pressure,
      NutrientPriorityLabel.reviewManagement => 0.06 * pressure,
      NutrientPriorityLabel.actionRecommended => 0.10 * pressure,
      NutrientPriorityLabel.possibleExcess => 0.05 * pressure,
      NutrientPriorityLabel.reviewAccumulation => 0.08 * pressure,
      NutrientPriorityLabel.unknown => 0.00,
    };

    return (base + pressureExtra).clamp(0.0, 1.0);
  }

  double healthScore01({double stagePressure01 = 0.0}) {
    return (1.0 - severityScore01(stagePressure01: stagePressure01)).clamp(
      0.0,
      1.0,
    );
  }

  AgroBand get agroBand {
    switch (this) {
      case NutrientPriorityLabel.noPriority:
        return AgroBand.optimal;
      case NutrientPriorityLabel.lowPriority:
      case NutrientPriorityLabel.mediumPriority:
      case NutrientPriorityLabel.highPriority:
        return AgroBand.low;
      case NutrientPriorityLabel.possibleExcess:
        return AgroBand.high;
      case NutrientPriorityLabel.reviewManagement:
      case NutrientPriorityLabel.actionRecommended:
      case NutrientPriorityLabel.reviewAccumulation:
        return AgroBand.critical;
      case NutrientPriorityLabel.unknown:
        return AgroBand.unknown;
    }
  }
}

enum AgroScoreKind { soilControl, nutrientPriority }

class AgroRange {
  const AgroRange({
    required this.lowMax,
    required this.optimalMin,
    required this.optimalMax,
    required this.highMin,
  });

  final double lowMax;
  final double optimalMin;
  final double optimalMax;
  final double highMin;
}

class AgroMetricEval {
  const AgroMetricEval({
    required this.band,
    required this.score01,
    required this.labelEs,
    this.value,
    this.priorityLabel,
    this.stageKey,
    this.stageLabelEs,
    this.demandWindowLabelEs,
    this.shortRecommendationEs,
    this.practicalRecommendationEs,
    this.doseGuideEs,
    this.fertilizerEquivalentEs,
    this.justificationEs,
    this.stagePressure01,
    this.contextModifier01,
    this.trendModifier01,
  });

  final AgroBand band;
  final double score01;
  final String labelEs;
  final double? value;
  final NutrientPriorityLabel? priorityLabel;
  final String? stageKey;
  final String? stageLabelEs;
  final String? demandWindowLabelEs;
  final String? shortRecommendationEs;
  final String? practicalRecommendationEs;
  final String? doseGuideEs;
  final String? fertilizerEquivalentEs;
  final String? justificationEs;
  final double? stagePressure01;
  final double? contextModifier01;
  final double? trendModifier01;

  bool get hasNutrientInterpretation => priorityLabel != null;
  bool get isNutrientActionable =>
      priorityLabel != null && priorityLabel!.suggestsAction;

  AgroMetricEval copyWith({
    AgroBand? band,
    double? score01,
    String? labelEs,
    double? value,
    NutrientPriorityLabel? priorityLabel,
    String? stageKey,
    String? stageLabelEs,
    String? demandWindowLabelEs,
    String? shortRecommendationEs,
    String? practicalRecommendationEs,
    String? doseGuideEs,
    String? fertilizerEquivalentEs,
    String? justificationEs,
    double? stagePressure01,
    double? contextModifier01,
    double? trendModifier01,
  }) {
    return AgroMetricEval(
      band: band ?? this.band,
      score01: score01 ?? this.score01,
      labelEs: labelEs ?? this.labelEs,
      value: value ?? this.value,
      priorityLabel: priorityLabel ?? this.priorityLabel,
      stageKey: stageKey ?? this.stageKey,
      stageLabelEs: stageLabelEs ?? this.stageLabelEs,
      demandWindowLabelEs: demandWindowLabelEs ?? this.demandWindowLabelEs,
      shortRecommendationEs:
          shortRecommendationEs ?? this.shortRecommendationEs,
      practicalRecommendationEs:
          practicalRecommendationEs ?? this.practicalRecommendationEs,
      doseGuideEs: doseGuideEs ?? this.doseGuideEs,
      fertilizerEquivalentEs:
          fertilizerEquivalentEs ?? this.fertilizerEquivalentEs,
      justificationEs: justificationEs ?? this.justificationEs,
      stagePressure01: stagePressure01 ?? this.stagePressure01,
      contextModifier01: contextModifier01 ?? this.contextModifier01,
      trendModifier01: trendModifier01 ?? this.trendModifier01,
    );
  }
}

class AgroEvalResult {
  const AgroEvalResult({
    required this.soilControlScore01,
    required this.metrics,
    required this.alerts,
    required this.suggestedAlertKeys,
    this.primaryScoreKind = AgroScoreKind.soilControl,
    this.nutrientPriorityScore01,
  });

  final double soilControlScore01;
  final double? nutrientPriorityScore01;
  final AgroScoreKind primaryScoreKind;
  final Map<AgroMetricKey, AgroMetricEval> metrics;
  final List<BioGAlert> alerts;
  final List<String> suggestedAlertKeys;

  AgroMetricEval? metricOf(AgroMetricKey key) => metrics[key];
  AgroMetricEval? get nitrogen => metrics[AgroMetricKey.n];
  AgroMetricEval? get phosphorus => metrics[AgroMetricKey.p];
  AgroMetricEval? get potassium => metrics[AgroMetricKey.k];
}

class Calibration {
  const Calibration({
    this.moistureDryRaw,
    this.moistureWetRaw,
    this.nMinRaw,
    this.nMaxRaw,
    this.pMinRaw,
    this.pMaxRaw,
    this.kMinRaw,
    this.kMaxRaw,
    this.resistanceMinRaw,
    this.resistanceMaxRaw,
  });

  final double? moistureDryRaw;
  final double? moistureWetRaw;
  final double? nMinRaw;
  final double? nMaxRaw;
  final double? pMinRaw;
  final double? pMaxRaw;
  final double? kMinRaw;
  final double? kMaxRaw;
  final double? resistanceMinRaw;
  final double? resistanceMaxRaw;
}

class AlertsState {
  const AlertsState({this.lastByType = const {}});
  final Map<BioGAlertType, DateTime> lastByType;

  AlertsState copyWith({Map<BioGAlertType, DateTime>? lastByType}) =>
      AlertsState(lastByType: lastByType ?? this.lastByType);
}

class AlertsBuildResult {
  const AlertsBuildResult({required this.alerts, required this.state});
  final List<BioGAlert> alerts;
  final AlertsState state;
}
