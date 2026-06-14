import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_universal_profile.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class AppleTreeProfile extends CropProfile {
  const AppleTreeProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.appleTree);
}

final Map<String, AppleTreeProfile> appleTreeProfiles =
    <String, AppleTreeProfile>{
      for (final entry in appleTreeProfileEntries)
        entry.id: AppleTreeProfile(
          id: entry.id,
          label: entry.label,
          useType: 'tree',
        ),
    };

class AppleTreeCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.appleTree;

  @override
  CropCategory get category => CropCategory.tree;

  @override
  String get displayName => 'Manzano';

  @override
  CropEngine get engine => const AppleTreeCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final AppleTreeProfile? resolved = appleTreeProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in appleTreeProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any(
              (alias) => _normalize(alias) == normalizedAlias,
            )) {
          return appleTreeProfiles[entry.id];
        }
      }
    }

    return appleTreeProfiles[kApSkip] ??
        (appleTreeProfiles.isNotEmpty ? appleTreeProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) {
    // Targets de sensor + semántica NPK relativa por etapa (doc 05). NO son
    // dosis kg/ha; son prioridades fisiológicas y rangos del sensor BIO-G v1.
    return resolveAppleTreeTargets(stage.stageKey);
  }

  /// Pesos AgroScore por etapa (doc 05 §10). Misma fuente que usa
  /// [evaluateTelemetry] para ponderar el control de suelo.
  StageWeights resolveStageWeights(CropStageResult stage) =>
      resolveAppleTreeStageWeights(stage.stageKey);

  /// Prioridades NPK relativas + nota UX por etapa (doc 05 §8). NO son dosis.
  AppleTreeStageNutrition resolveNutritionPriorities(CropStageResult stage) =>
      resolveAppleTreeNutritionPriorities(stage.stageKey);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeTreeStageId(stage.stageKey);
    final _TreeStageSensitivity sensitivity = _TreeStageSensitivity.forStage(
      stageId,
    );

    final metrics = <AgroMetricKey, AgroMetricEval>{
      AgroMetricKey.soilMoisture: _metric(
        key: AgroMetricKey.soilMoisture,
        value: bioTelemetry.soilMoisturePct,
        band: _moistureBand(bioTelemetry.soilMoisturePct),
        stage: stage,
        sensitivity: sensitivity,
      ),
      AgroMetricKey.soilTemp: _metric(
        key: AgroMetricKey.soilTemp,
        value: bioTelemetry.soilTempC,
        band: _soilTempBand(bioTelemetry.soilTempC),
        stage: stage,
        sensitivity: sensitivity,
      ),
      AgroMetricKey.ph: _metric(
        key: AgroMetricKey.ph,
        value: bioTelemetry.ph,
        band: _phBand(bioTelemetry.ph),
        stage: stage,
        sensitivity: sensitivity,
      ),
      AgroMetricKey.ec: _metric(
        key: AgroMetricKey.ec,
        value: bioTelemetry.ec,
        band: _ecBand(bioTelemetry.ec),
        stage: stage,
        sensitivity: sensitivity,
      ),
      AgroMetricKey.resistance: _metric(
        key: AgroMetricKey.resistance,
        value: bioTelemetry.resistance,
        band: _resistanceBand(bioTelemetry.resistance),
        stage: stage,
        sensitivity: sensitivity,
      ),
      AgroMetricKey.n: _nutrientMetric(
        key: AgroMetricKey.n,
        value: bioTelemetry.n.toDouble(),
        hasData: bioTelemetry.hasNitrogenData,
        lowThreshold: 15,
        stage: stage,
        sensitivity: sensitivity,
      ),
      AgroMetricKey.p: _nutrientMetric(
        key: AgroMetricKey.p,
        value: bioTelemetry.p.toDouble(),
        hasData: bioTelemetry.hasPhosphorusData,
        lowThreshold: 8,
        stage: stage,
        sensitivity: sensitivity,
      ),
      AgroMetricKey.k: _nutrientMetric(
        key: AgroMetricKey.k,
        value: bioTelemetry.k.toDouble(),
        hasData: bioTelemetry.hasPotassiumData,
        lowThreshold: 80,
        stage: stage,
        sensitivity: sensitivity,
      ),
    };

    final alertBuild = _buildTreeAlerts(
      telemetry: bioTelemetry,
      stageId: stageId,
      stageLabel: stage.stageLabelEs,
      metrics: metrics,
      alertsState: alertsState,
    );

    return (
      eval: AgroEvalResult(
        soilControlScore01: _soilControlScore(metrics, stageId),
        nutrientPriorityScore01: _nutrientPriorityScore(metrics, sensitivity),
        primaryScoreKind: AgroScoreKind.soilControl,
        metrics: metrics,
        alerts: alertBuild.alerts,
        suggestedAlertKeys: _treeSuggestedKeys(stageId, metrics),
      ),
      nextAlertsState: alertBuild.state,
    );
  }

  static AgroMetricEval _metric({
    required AgroMetricKey key,
    required double value,
    required AgroBand band,
    required CropStageResult stage,
    required _TreeStageSensitivity sensitivity,
  }) {
    final bool focus = sensitivity.focusMetrics.contains(key);
    final double baseScore = _scoreForBand(band);
    final double pressurePenalty =
        focus && (band == AgroBand.low || band == AgroBand.high)
        ? 0.12 * sensitivity.stagePressure01
        : focus && band == AgroBand.critical
        ? 0.22 * sensitivity.stagePressure01
        : 0;

    return AgroMetricEval(
      band: band,
      score01: (baseScore - pressurePenalty).clamp(0.0, 1.0),
      labelEs: _treeBandLabel(band, focus),
      value: value,
      stageKey: stage.stageKey,
      stageLabelEs: stage.stageLabelEs,
      demandWindowLabelEs:
          treeCriticalWindowLabel(stage.stageKey) ??
          stage.productiveStateLabelEs,
      shortRecommendationEs: _metricRecommendation(
        key: key,
        band: band,
        stageId: stage.stageKey,
      ),
      stagePressure01: sensitivity.stagePressure01,
    );
  }

  static AgroMetricEval _nutrientMetric({
    required AgroMetricKey key,
    required double value,
    required bool hasData,
    required double lowThreshold,
    required CropStageResult stage,
    required _TreeStageSensitivity sensitivity,
  }) {
    if (!hasData) {
      return _metric(
        key: key,
        value: value,
        band: AgroBand.unknown,
        stage: stage,
        sensitivity: sensitivity,
      );
    }

    final band = value <= 0
        ? AgroBand.unknown
        : value < lowThreshold * 0.55
        ? AgroBand.critical
        : value < lowThreshold
        ? AgroBand.low
        : AgroBand.optimal;

    return _metric(
      key: key,
      value: value,
      band: band,
      stage: stage,
      sensitivity: sensitivity,
    );
  }

  static AlertsBuildResult _buildTreeAlerts({
    required BioGTelemetry telemetry,
    required String stageId,
    required String stageLabel,
    required Map<AgroMetricKey, AgroMetricEval> metrics,
    required AlertsState alertsState,
  }) {
    final nextMap = Map<BioGAlertType, DateTime>.from(alertsState.lastByType);
    final alerts = <BioGAlert>[];
    final now = telemetry.timestamp;

    void push({
      required BioGAlertType type,
      required BioGAlertSeverity severity,
      required String title,
      required String body,
    }) {
      final last = nextMap[type];
      if (last != null && now.difference(last) < const Duration(minutes: 60)) {
        return;
      }

      alerts.add(
        BioGAlert(
          id: '${telemetry.deviceId}_${type.name}_${now.millisecondsSinceEpoch}',
          deviceId: telemetry.deviceId,
          type: type,
          severity: severity,
          title: title,
          body: body,
          timestamp: now,
        ),
      );
      nextMap[type] = now;
    }

    final moisture = metrics[AgroMetricKey.soilMoisture]?.band;
    final resistance = metrics[AgroMetricKey.resistance]?.band;
    final soilTemp = metrics[AgroMetricKey.soilTemp]?.band;
    final ec = metrics[AgroMetricKey.ec]?.band;
    final nutrientLow =
        <AgroMetricKey>[AgroMetricKey.n, AgroMetricKey.p, AgroMetricKey.k].any(
          (key) =>
              metrics[key]?.band == AgroBand.low ||
              metrics[key]?.band == AgroBand.critical,
        );

    final moistureLow =
        moisture == AgroBand.low || moisture == AgroBand.critical;
    final moistureHigh =
        moisture == AgroBand.high || moisture == AgroBand.critical;
    final heat =
        telemetry.airTempC >= 35 ||
        soilTemp == AgroBand.high ||
        soilTemp == AgroBand.critical;
    final cold = telemetry.airTempC <= 4;
    final highHumidity = telemetry.airHumidityPct >= 85;
    final salinityHigh = ec == AgroBand.high || ec == AgroBand.critical;

    switch (stageId) {
      case TreeStageIds.rootEstablishment:
        if (moistureLow) {
          push(
            type: BioGAlertType.lowSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Humedad baja en establecimiento',
            body:
                'El arbol esta en establecimiento. Manten humedad estable y evita secados fuertes mientras forma raiz.',
          );
        } else if (moistureHigh) {
          push(
            type: BioGAlertType.highSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Exceso de humedad en establecimiento',
            body:
                'Exceso de humedad en establecimiento. Revisa drenaje y evita saturacion del suelo.',
          );
        }
        if (resistance == AgroBand.high || resistance == AgroBand.critical) {
          push(
            type: BioGAlertType.stageEvent,
            severity: BioGAlertSeverity.warning,
            title: 'Raiz con suelo resistente',
            body:
                'El arbol esta en establecimiento. Suelo muy resistente puede limitar raiz; revisa compactacion sin hacer labores agresivas junto al tronco.',
          );
        }
        break;
      case TreeStageIds.flowering:
        if (cold) {
          push(
            type: BioGAlertType.airTempExtreme,
            severity: telemetry.airTempC <= 0
                ? BioGAlertSeverity.critical
                : BioGAlertSeverity.warning,
            title: 'Riesgo de estres durante floracion',
            body:
                'Floracion activa: temperatura baja o helada puede afectar la produccion de la temporada.',
          );
        }
        if (moistureLow) {
          push(
            type: BioGAlertType.lowSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Deficit hidrico en floracion',
            body:
                'Floracion activa: pequenas desviaciones pueden afectar la produccion de la temporada. Revisa humedad y riego.',
          );
        }
        if (highHumidity) {
          push(
            type: BioGAlertType.highHumidity,
            severity: BioGAlertSeverity.warning,
            title: 'Humedad alta durante floracion',
            body:
                'Humedad ambiental elevada durante floracion. Revisa el arbol y mantén monitoreo.',
          );
        }
        break;
      case TreeStageIds.fruitSet:
        if (moistureLow) {
          push(
            type: BioGAlertType.lowSoilMoisture,
            severity: BioGAlertSeverity.warning,
            title: 'Deficit hidrico en cuajado',
            body:
                'Cuajado activo: evita estres hidrico o termico. Esta etapa tiene poca tolerancia al estres.',
          );
        }
        if (heat) {
          push(
            type: BioGAlertType.airTempExtreme,
            severity: BioGAlertSeverity.warning,
            title: 'Calor durante cuajado',
            body:
                'Cuajado activo: el calor puede aumentar estres. Mantén humedad estable y revisa el arbol.',
          );
        }
        if (salinityHigh) {
          push(
            type: BioGAlertType.ecOutOfRange,
            severity: BioGAlertSeverity.warning,
            title: 'Salinidad alta en cuajado',
            body:
                'Cuajado activo: revisa CE y acumulacion de sales si la lectura se mantiene alta.',
          );
        }
        break;
      case TreeStageIds.fruitFill:
        if (moistureLow || heat) {
          push(
            type: moistureLow
                ? BioGAlertType.lowSoilMoisture
                : BioGAlertType.airTempExtreme,
            severity: BioGAlertSeverity.warning,
            title: 'Estres en llenado de fruto',
            body:
                'Llenado de fruto: el arbol necesita estabilidad para sostener calidad y tamano.',
          );
        }
        break;
      case TreeStageIds.postHarvest:
        if (moistureLow || nutrientLow) {
          push(
            type: moistureLow
                ? BioGAlertType.lowSoilMoisture
                : BioGAlertType.stageEvent,
            severity: BioGAlertSeverity.warning,
            title: 'Post-cosecha con estres',
            body:
                'Post-cosecha: el arbol recupera reservas para el siguiente ciclo. Mantén monitoreo y evita estres sostenido.',
          );
        }
        break;
      case TreeStageIds.dormancy:
        if (moisture == AgroBand.critical || soilTemp == AgroBand.critical) {
          push(
            type: BioGAlertType.stageEvent,
            severity: BioGAlertSeverity.warning,
            title: 'Extremo durante reposo',
            body:
                'Reposo: monitoreo pasivo del arbol. Solo conviene actuar si las lecturas extremas se mantienen.',
          );
        }
        break;
      default:
        break;
    }

    return AlertsBuildResult(
      alerts: List<BioGAlert>.unmodifiable(alerts),
      state: alertsState.copyWith(lastByType: nextMap),
    );
  }

  static List<String> _treeSuggestedKeys(
    String stageId,
    Map<AgroMetricKey, AgroMetricEval> metrics,
  ) {
    final keys = <String>['tree.stage.$stageId'];
    for (final entry in metrics.entries) {
      if (entry.value.band == AgroBand.low ||
          entry.value.band == AgroBand.high ||
          entry.value.band == AgroBand.critical) {
        keys.add('tree.$stageId.${entry.key.name}.${entry.value.band.name}');
      }
    }
    return keys;
  }

  /// AgroScore de control de suelo. Los PESOS por etapa son ÚNICA fuente: vienen
  /// del perfil universal (doc 05 §10), no de una matriz duplicada aquí. El NPK
  /// combinado se reparte entre n/p/k vía [StageWeights.weightFor].
  static double _soilControlScore(
    Map<AgroMetricKey, AgroMetricEval> metrics,
    String stageId,
  ) {
    final weights = resolveAppleTreeStageWeights(stageId);
    double weighted = 0;
    double weightSum = 0;

    void add(AgroMetricKey key) {
      final metric = metrics[key];
      if (metric == null) return;
      final weight = weights.weightFor(key);
      weighted += metric.score01 * weight;
      weightSum += weight;
    }

    for (final key in AgroMetricKey.values) {
      add(key);
    }

    if (weightSum <= 0) return 0.5;
    return (weighted / weightSum).clamp(0.0, 1.0);
  }

  static double _nutrientPriorityScore(
    Map<AgroMetricKey, AgroMetricEval> metrics,
    _TreeStageSensitivity sensitivity,
  ) {
    final nutrientScores = <double>[
      metrics[AgroMetricKey.n]?.score01 ?? 0.5,
      metrics[AgroMetricKey.p]?.score01 ?? 0.5,
      metrics[AgroMetricKey.k]?.score01 ?? 0.5,
    ];
    final avgHealth =
        nutrientScores.reduce((a, b) => a + b) / nutrientScores.length;
    return ((1 - avgHealth) * sensitivity.stagePressure01).clamp(0.0, 1.0);
  }

  static AgroBand _moistureBand(double value) {
    if (value < 18) return AgroBand.critical;
    if (value < 28) return AgroBand.low;
    if (value <= 68) return AgroBand.optimal;
    if (value <= 82) return AgroBand.high;
    return AgroBand.critical;
  }

  static AgroBand _soilTempBand(double value) {
    if (value < 6) return AgroBand.critical;
    if (value < 12) return AgroBand.low;
    if (value <= 30) return AgroBand.optimal;
    if (value <= 36) return AgroBand.high;
    return AgroBand.critical;
  }

  static AgroBand _phBand(double value) {
    if (value < 5.0 || value > 8.4) return AgroBand.critical;
    if (value < 5.8) return AgroBand.low;
    if (value <= 7.6) return AgroBand.optimal;
    return AgroBand.high;
  }

  static AgroBand _ecBand(double value) {
    if (value < 0.2) return AgroBand.low;
    if (value <= 2.0) return AgroBand.optimal;
    if (value <= 3.0) return AgroBand.high;
    return AgroBand.critical;
  }

  static AgroBand _resistanceBand(double value) {
    if (value < 0.15) return AgroBand.low;
    if (value <= 1.6) return AgroBand.optimal;
    if (value <= 2.4) return AgroBand.high;
    return AgroBand.critical;
  }

  static double _scoreForBand(AgroBand band) {
    return switch (band) {
      AgroBand.optimal => 1.0,
      AgroBand.low || AgroBand.high => 0.58,
      AgroBand.critical => 0.18,
      AgroBand.unknown => 0.5,
    };
  }

  static String _treeBandLabel(AgroBand band, bool focus) {
    if (band == AgroBand.unknown) return 'Monitoreo';
    if (focus && band != AgroBand.optimal) return 'Prioridad';
    return band.labelEs;
  }

  static String _metricRecommendation({
    required AgroMetricKey key,
    required AgroBand band,
    required String stageId,
  }) {
    if (band == AgroBand.optimal) return treeStagePriorityText(stageId);
    if (band == AgroBand.unknown) {
      return 'Lectura disponible para seguimiento general del manzano.';
    }

    return switch (stageId) {
      TreeStageIds.rootEstablishment =>
        'El arbol esta en establecimiento. Mantén humedad estable y evita saturacion del suelo.',
      TreeStageIds.flowering =>
        'Floracion activa: pequenas desviaciones pueden afectar la produccion de la temporada.',
      TreeStageIds.fruitSet =>
        'Cuajado activo: evita estres hidrico o termico.',
      TreeStageIds.fruitFill =>
        'Llenado de fruto: el arbol necesita estabilidad para sostener calidad y tamano.',
      TreeStageIds.postHarvest =>
        'Post-cosecha: el arbol recupera reservas para el siguiente ciclo.',
      TreeStageIds.dormancy => 'Reposo: monitoreo pasivo del arbol.',
      _ => 'Revisa esta lectura dentro del estado visible del arbol.',
    };
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}

/// Sensibilidad interpretativa por etapa: SOLO presión fisiológica y métricas
/// "foco" (las que el doc 05 marca como prioritarias para penalizar/etiquetar).
/// Los PESOS numéricos del AgroScore ya NO viven aquí: son del perfil universal
/// (doc 05 §10) vía [resolveAppleTreeStageWeights]. Aquí solo queda el matiz
/// cualitativo (emphasis), que no es un peso de sensor.
class _TreeStageSensitivity {
  const _TreeStageSensitivity({
    required this.stagePressure01,
    required this.focusMetrics,
  });

  final double stagePressure01;
  final Set<AgroMetricKey> focusMetrics;

  static _TreeStageSensitivity forStage(String stageId) {
    return switch (normalizeTreeStageId(stageId)) {
      TreeStageIds.rootEstablishment => const _TreeStageSensitivity(
        stagePressure01: 0.9,
        focusMetrics: <AgroMetricKey>{
          AgroMetricKey.soilMoisture,
          AgroMetricKey.ec,
          AgroMetricKey.resistance,
        },
      ),
      TreeStageIds.flowering => const _TreeStageSensitivity(
        stagePressure01: 1.0,
        focusMetrics: <AgroMetricKey>{
          AgroMetricKey.soilMoisture,
          AgroMetricKey.soilTemp,
          AgroMetricKey.ec,
        },
      ),
      TreeStageIds.fruitSet => const _TreeStageSensitivity(
        stagePressure01: 0.9,
        focusMetrics: <AgroMetricKey>{
          AgroMetricKey.soilMoisture,
          AgroMetricKey.soilTemp,
          AgroMetricKey.ec,
          AgroMetricKey.k,
        },
      ),
      TreeStageIds.fruitFill => const _TreeStageSensitivity(
        stagePressure01: 0.75,
        focusMetrics: <AgroMetricKey>{
          AgroMetricKey.soilMoisture,
          AgroMetricKey.soilTemp,
          AgroMetricKey.k,
        },
      ),
      TreeStageIds.postHarvest => const _TreeStageSensitivity(
        stagePressure01: 0.7,
        focusMetrics: <AgroMetricKey>{
          AgroMetricKey.soilMoisture,
          AgroMetricKey.n,
          AgroMetricKey.p,
          AgroMetricKey.k,
        },
      ),
      TreeStageIds.dormancy => const _TreeStageSensitivity(
        stagePressure01: 0.2,
        focusMetrics: <AgroMetricKey>{},
      ),
      _ => const _TreeStageSensitivity(
        stagePressure01: 0.45,
        focusMetrics: <AgroMetricKey>{AgroMetricKey.soilMoisture},
      ),
    };
  }
}

class AppleTreeCropEngineAdapter implements CropEngine {
  const AppleTreeCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    // The runtime resolver bypasses this engine for trees because sowingDate
    // is not the logical axis for perennials. This fallback keeps the public
    // CropDefinition contract safe if a legacy caller invokes engine.compute.
    return CropStageResult(
      stageKey: TreeStageIds.unknown,
      stageLabelEs: treeStageDisplayName(TreeStageIds.unknown),
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: 'assets/icons/wizard/ic_arbol.png',
      helperCaption: 'Resolver perenne requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
