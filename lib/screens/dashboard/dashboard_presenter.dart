// lib/screens/dashboard/dashboard_presenter.dart
import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_event_input_factory.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/agro/event_engine.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart'; // <-- IMPORTANTE: Lo usamos para las dosis en vivo
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/services/biog/biog_store.dart';

class DashboardMetricUiData {
  final String title;
  final String value;
  final String status;
  final String assetIcon;

  const DashboardMetricUiData({
    required this.title,
    required this.value,
    required this.status,
    required this.assetIcon,
  });
}

class DashboardInsightUiData {
  final String assetIcon;
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;

  const DashboardInsightUiData({
    required this.assetIcon,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
  });
}

class DashboardViewData {
  final String fieldLabel;
  final String cropLabel;
  final String cropIconAsset;
  final double soilHealth;
  final String soilHealthLabel;
  final String npkTitle;
  final String npkSubtitle;
  final DashboardMetricUiData moisture;
  final DashboardMetricUiData temperature;
  final DashboardMetricUiData ph;
  final DashboardMetricUiData resistance;
  final DashboardInsightUiData irrigation;
  final List<AgronomicEvent> events;

  const DashboardViewData({
    required this.fieldLabel,
    required this.cropLabel,
    required this.cropIconAsset,
    required this.soilHealth,
    required this.soilHealthLabel,
    required this.npkTitle,
    required this.npkSubtitle,
    required this.moisture,
    required this.temperature,
    required this.ph,
    required this.resistance,
    required this.irrigation,
    this.events = const <AgronomicEvent>[],
  });
}

class DashboardSyncPlan {
  final bool shouldSetEval;
  final bool shouldSetAlerts;

  const DashboardSyncPlan({
    required this.shouldSetEval,
    required this.shouldSetAlerts,
  });

  bool get hasChanges => shouldSetEval || shouldSetAlerts;
}

class DashboardScreenPresenter {
  static const String kRiegoIcon = 'assets/icons/metrics/ic_riego.png';

  DashboardViewData buildViewData({
    required BioGStore store,
    required CropRuntimeSnapshot runtime,
    required DateTime today,
  }) {
    final BioGTelemetry? telemetry = runtime.live;
    final CropStageResult? stageResult = runtime.stageResult;
    final StageTargets? targets = runtime.targets;

    final bool isPlanted = runtime.isPlanted;
    final bool isPlanned = runtime.isPlanned;
    final bool isGenericMode = runtime.isGenericMode;

    final AgroEvalResult? effectiveEval = isPlanted
        ? (runtime.eval ?? store.lastAgroEval)
        : null;
    final bool hasCropAwareEval = effectiveEval != null;

    final DateTime? plannedDate =
        runtime.cropContext?.plannedSowingDate ??
        runtime.seed?.plannedSowingDate;

    final int plannedDaysLeft = plannedDate == null
        ? 0
        : DateTime(
            plannedDate.year,
            plannedDate.month,
            plannedDate.day,
          ).difference(DateTime(today.year, today.month, today.day)).inDays;

    final List<AgronomicEvent> dashboardEvents = _buildDashboardEvents(
      store: store,
      runtime: runtime,
      effectiveEval: effectiveEval,
      stageResult: stageResult,
      isGenericMode: isGenericMode,
      now: today,
    );

    final AgronomicEvent? primaryDashboardEvent = _pickPrimaryDashboardEvent(
      dashboardEvents,
    );

    final double soilHealth = isPlanted
        ? _calcSoilHealthRealistic(
            t: telemetry,
            eval: effectiveEval,
            targets: targets,
            cropKey: runtime.cropKeyName,
          )
        : _calcPreSowingSoilHealth(telemetry);

    final String moistureValue = telemetry == null
        ? '--'
        : '${telemetry.soilMoisturePct.toStringAsFixed(0)}%';
    final String tempValue = telemetry == null
        ? '--'
        : '${telemetry.soilTempC.toStringAsFixed(0)}°C';
    final String phValue = telemetry == null
        ? '--'
        : telemetry.ph.toStringAsFixed(1);
    final String resistanceValue = telemetry == null
        ? '--'
        : '${telemetry.resistance.toStringAsFixed(1)} MPa';

    final String moistureStatus = telemetry == null
        ? '—'
        : isGenericMode
        ? 'Lectura actual'
        : isPlanted
        ? ((effectiveEval != null)
              ? (effectiveEval.metrics[AgroMetricKey.soilMoisture]?.labelEs ??
                    '—')
              : ((targets != null)
                    ? _rawMetricStatusFromTargets(
                        value: telemetry.soilMoisturePct,
                        range: targets.moistureRaw,
                      )
                    : 'Monitoreo'))
        : _preSowingMoistureStatus(telemetry.soilMoisturePct);

    final String tempStatus = telemetry == null
        ? '—'
        : isGenericMode
        ? 'Lectura actual'
        : isPlanted
        ? ((effectiveEval != null)
              ? (effectiveEval.metrics[AgroMetricKey.soilTemp]?.labelEs ?? '—')
              : ((targets != null)
                    ? _rawMetricStatusFromTargets(
                        value: telemetry.soilTempC,
                        range: targets.soilTemp,
                      )
                    : 'Monitoreo'))
        : _soilTempStatus(telemetry.soilTempC);

    final String phStatus = telemetry == null
        ? '—'
        : isGenericMode
        ? 'Lectura actual'
        : isPlanted
        ? ((effectiveEval != null)
              ? (effectiveEval.metrics[AgroMetricKey.ph]?.labelEs ?? '—')
              : ((targets != null)
                    ? _rawMetricStatusFromTargets(
                        value: telemetry.ph,
                        range: targets.ph,
                      )
                    : 'Monitoreo'))
        : _preSowingPhStatus(telemetry.ph);

    final String resistanceStatus = telemetry == null
        ? '—'
        : isGenericMode
        ? 'Lectura actual'
        : isPlanted
        ? ((effectiveEval != null)
              ? (effectiveEval.metrics[AgroMetricKey.resistance]?.labelEs ??
                    '—')
              : ((targets != null)
                    ? _rawMetricStatusFromTargets(
                        value: telemetry.resistance,
                        range: targets.resistance,
                      )
                    : 'Monitoreo'))
        : _preSowingResistanceStatus(telemetry.resistance);

    // ==========================================
    // NUEVA LÓGICA DE TEXTOS NPK EN DASHBOARD
    // ==========================================
    String npkTitle = 'Nutrición (NPK)';
    String npkSubtitle = 'Sin evaluación actual';

    if (isPlanted && telemetry != null) {
      final nInt = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: telemetry.n.toDouble(),
        cropKey: runtime.cropKeyName,
        stageKey: stageResult?.stageKey,
        profileId: runtime.profile?.id,
        targets: targets,
      );
      final pInt = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.p,
        rawPpm: telemetry.p.toDouble(),
        cropKey: runtime.cropKeyName,
        stageKey: stageResult?.stageKey,
        profileId: runtime.profile?.id,
        targets: targets,
      );
      final kInt = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.k,
        rawPpm: telemetry.k.toDouble(),
        cropKey: runtime.cropKeyName,
        stageKey: stageResult?.stageKey,
        profileId: runtime.profile?.id,
        targets: targets,
      );

      // Usamos las etiquetas premium cortas para el title
      npkTitle = 'N: ${nInt.labelEs} · P: ${pInt.labelEs} · K: ${kInt.labelEs}';

      // Buscamos el nutriente con más urgencia
      final allInts = [nInt, pInt, kInt]
        ..sort((a, b) => b.priorityScore01.compareTo(a.priorityScore01));
      final top = allInts.first;

      // Si hay una guía de dosis matemática, la mostramos. Si no, mostramos la alerta.
      if (top.doseGuideEs != null && top.doseGuideEs!.isNotEmpty) {
        npkSubtitle =
            top.doseGuideEs!.split('.').first +
            '.'; // Extrae la frase exacta "Aplica ~45 kg/ha..."
      } else {
        npkSubtitle = top.shortRecommendation;
      }
    } else if (isPlanned) {
      npkSubtitle = 'Disponible tras la siembra';
    } else {
      npkSubtitle = 'Modo genérico activo';
    }

    // ==========================================

    late final String irrigationTitle;
    late final String irrigationSubtitle;
    late final String irrigationTag;

    if (isPlanted) {
      irrigationTitle = hasCropAwareEval
          ? _irrigationTitleFromEval(effectiveEval!)
          : ((telemetry != null && targets != null)
                ? _irrigationTitleFromTargets(
                    soilMoisturePct: telemetry.soilMoisturePct,
                    targets: targets,
                  )
                : 'Recomendación pendiente');
      irrigationSubtitle = hasCropAwareEval
          ? 'Basado en humedad del suelo y modelo Bio-G'
          : ((telemetry != null && targets != null)
                ? 'Basado en humedad del suelo y etapa actual'
                : 'Sin evaluación agronómica actual');
      irrigationTag = hasCropAwareEval
          ? _irrigationTagFromEval(effectiveEval!)
          : ((telemetry != null && targets != null)
                ? _irrigationTagFromTargets(
                    soilMoisturePct: telemetry.soilMoisturePct,
                    targets: targets,
                  )
                : '—');
    } else if (isPlanned) {
      irrigationTitle = _plannedInsightTitle(plannedDaysLeft, telemetry);
      irrigationSubtitle =
          'Preparación previa a siembra basada en condición actual del suelo';
      irrigationTag = plannedDaysLeft <= 0 ? 'Hoy' : '${plannedDaysLeft}d';
    } else {
      if (primaryDashboardEvent != null &&
          primaryDashboardEvent.type != AgronomicEventType.genericMode) {
        irrigationTitle = primaryDashboardEvent.title;
        irrigationSubtitle = primaryDashboardEvent.message;
        irrigationTag = _tagFromEvent(primaryDashboardEvent);
      } else {
        irrigationTitle = 'Configura cultivo para recomendaciones precisas';
        irrigationSubtitle =
            'Asigna un cultivo para adaptar sensores y alertas por etapa';
        irrigationTag = 'Setup';
      }
    }

    return DashboardViewData(
      fieldLabel: _buildFieldLabel(runtime.device),
      cropLabel: runtime.cropLabel,
      cropIconAsset: runtime.cropIconAsset,
      soilHealth: soilHealth,
      soilHealthLabel: isPlanted
          ? 'Índice de salud del suelo'
          : isPlanned
          ? 'Índice de preparación de suelo'
          : 'Lectura general del suelo',
      npkTitle: npkTitle,
      npkSubtitle: npkSubtitle,
      moisture: const DashboardMetricUiData(
        title: 'Humedad',
        value: '',
        status: '',
        assetIcon: 'assets/icons/metrics/ic_moisture.png',
      ).copyWith(value: moistureValue, status: moistureStatus),
      temperature: const DashboardMetricUiData(
        title: 'Temp suelo',
        value: '',
        status: '',
        assetIcon: 'assets/icons/metrics/ic_temperature.png',
      ).copyWith(value: tempValue, status: tempStatus),
      ph: const DashboardMetricUiData(
        title: 'pH',
        value: '',
        status: '',
        assetIcon: 'assets/icons/metrics/ic_ph.png',
      ).copyWith(value: phValue, status: phStatus),
      resistance: const DashboardMetricUiData(
        title: 'Resistencia',
        value: '',
        status: '',
        assetIcon: 'assets/icons/metrics/ic_resistance.png',
      ).copyWith(value: resistanceValue, status: resistanceStatus),
      irrigation: DashboardInsightUiData(
        assetIcon: kRiegoIcon,
        icon: Icons.water_drop_rounded,
        title: irrigationTitle,
        subtitle: irrigationSubtitle,
        tag: irrigationTag,
      ),
      events: dashboardEvents,
    );
  }

  DashboardSyncPlan buildSyncPlan({
    required BioGStore store,
    required AgroEvalResult? resolvedEval,
    required AlertsState nextAlertsState,
  }) {
    if (resolvedEval == null)
      return const DashboardSyncPlan(
        shouldSetEval: false,
        shouldSetAlerts: false,
      );
    return DashboardSyncPlan(
      shouldSetEval: !_sameAgroEval(store.lastAgroEval, resolvedEval),
      shouldSetAlerts: !_sameAlertsState(store.alertsState, nextAlertsState),
    );
  }

  List<AgronomicEvent> _buildDashboardEvents({
    required BioGStore store,
    required CropRuntimeSnapshot runtime,
    required AgroEvalResult? effectiveEval,
    required CropStageResult? stageResult,
    required bool isGenericMode,
    required DateTime now,
  }) {
    final input = AgroEventInputFactory.build(
      timestamp: now,
      deviceId: runtime.device?.id ?? store.activeDevice?.id,
      seed: runtime.seed,
      cropContext: runtime.cropContext,
      live: runtime.live,
      effectiveEval: effectiveEval,
      stageResult: stageResult,
      isGenericMode: isGenericMode,
      history: const <EventTelemetryPoint>[],
      previousBands: const <String, AgroBand>{},
      previousStageKey: _previousDashboardStage(runtime, now)?.stageKey,
      previousStageLabel: _previousDashboardStage(runtime, now)?.stageLabelEs,
    );
    return EventEngine.build(input);
  }

  CropStageResult? _previousDashboardStage(
    CropRuntimeSnapshot runtime,
    DateTime now,
  ) {
    if (!runtime.isPlanted) return null;
    final definition = runtime.definition;
    final profile = runtime.profile;
    final sowingDate =
        runtime.engineSowingDate ?? runtime.effectiveLifecycleDate;
    if (definition == null || profile == null || sowingDate == null)
      return null;
    return definition.engine.compute(
      sowingDate: sowingDate,
      today: now.subtract(const Duration(days: 1)),
      profile: profile,
      stressDelayDays: 0,
    );
  }

  AgronomicEvent? _pickPrimaryDashboardEvent(List<AgronomicEvent> events) {
    for (final AgronomicEvent event in events) {
      if (event.type == AgronomicEventType.irrigationRecommended ||
          event.type == AgronomicEventType.fertilizationRecommended ||
          event.type == AgronomicEventType.combinedStress ||
          event.type == AgronomicEventType.soilCompaction ||
          event.type == AgronomicEventType.heatStress ||
          event.type == AgronomicEventType.coldStress ||
          event.type == AgronomicEventType.lowMoisture ||
          event.type == AgronomicEventType.highMoisture) {
        return event;
      }
    }
    for (final AgronomicEvent event in events) {
      if (event.type != AgronomicEventType.genericMode) return event;
    }
    return events.isEmpty ? null : events.first;
  }

  String _tagFromEvent(AgronomicEvent event) {
    switch (event.severity) {
      case AgronomicEventSeverity.critical:
        return 'Crítico';
      case AgronomicEventSeverity.warning:
        return 'Alerta';
      case AgronomicEventSeverity.caution:
        return 'Atención';
      case AgronomicEventSeverity.info:
        return 'Info';
    }
  }

  bool _sameAgroEval(AgroEvalResult? a, AgroEvalResult? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if ((a.soilControlScore01 - b.soilControlScore01).abs() > 0.0001)
      return false;
    if (a.metrics.length != b.metrics.length) return false;
    if (a.alerts.length != b.alerts.length) return false;
    if (a.suggestedAlertKeys.length != b.suggestedAlertKeys.length)
      return false;
    for (int i = 0; i < a.alerts.length; i++)
      if (a.alerts[i].id != b.alerts[i].id) return false;
    for (int i = 0; i < a.suggestedAlertKeys.length; i++)
      if (a.suggestedAlertKeys[i] != b.suggestedAlertKeys[i]) return false;
    for (final AgroMetricKey key in a.metrics.keys) {
      final AgroMetricEval? av = a.metrics[key];
      final AgroMetricEval? bv = b.metrics[key];
      if (av == null || bv == null) return false;
      if (av.band != bv.band) return false;
      if (av.labelEs != bv.labelEs) return false;
      if ((av.score01 - bv.score01).abs() > 0.0001) return false;
      if (av.value != bv.value) return false;
    }
    return true;
  }

  bool _sameAlertsState(AlertsState a, AlertsState b) {
    if (identical(a, b)) return true;
    if (a.lastByType.length != b.lastByType.length) return false;
    for (final MapEntry<BioGAlertType, DateTime> entry
        in a.lastByType.entries) {
      if (b.lastByType[entry.key] != entry.value) return false;
    }
    return true;
  }

  String _buildFieldLabel(BioGDevice? device) {
    if (device == null) return 'Sin BioG';
    if (device.name.trim().isNotEmpty) return device.name.trim();
    if (device.locationName.trim().isNotEmpty)
      return device.locationName.trim();
    return 'BioG';
  }

  double _calcPreSowingSoilHealth(BioGTelemetry? telemetry) {
    if (telemetry == null) return 0.0;
    double score(
      double val,
      double okMin,
      double okMax,
      double hMin,
      double hMax,
    ) {
      if (val <= hMin || val >= hMax) return 0.0;
      if (val >= okMin && val <= okMax) return 1.0;
      if (val < okMin) return ((val - hMin) / (okMin - hMin)).clamp(0.0, 1.0);
      return ((hMax - val) / (hMax - okMax)).clamp(0.0, 1.0);
    }

    return ((score(telemetry.soilMoisturePct, 28, 55, 5, 85) +
                score(telemetry.ph, 5.8, 7.2, 4.5, 8.8) +
                score(telemetry.resistance, 0.3, 1.2, 0.1, 2.8) +
                score(telemetry.ec, 0.8, 2.0, 0.4, 3.2)) /
            4.0)
        .clamp(0.0, 1.0);
  }

  String _preSowingMoistureStatus(double value) => value < 25
      ? 'Seco'
      : value > 65
      ? 'Húmedo'
      : 'Apta';
  String _preSowingPhStatus(double value) => value < 5.8
      ? 'Bajo'
      : value > 7.2
      ? 'Alto'
      : 'Apto';
  String _preSowingResistanceStatus(double value) => value > 2.0
      ? 'Compactado'
      : value < 0.25
      ? 'Suelto'
      : 'Apto';

  String _plannedInsightTitle(int plannedDaysLeft, BioGTelemetry? telemetry) {
    if (telemetry == null)
      return plannedDaysLeft <= 0
          ? 'Valida el suelo antes de sembrar'
          : 'Monitorea condiciones antes de la siembra';
    if (telemetry.resistance > 2.0)
      return 'La resistencia del suelo sigue alta para siembra';
    if (telemetry.soilMoisturePct < 25)
      return 'Aumenta humedad antes de sembrar';
    if (plannedDaysLeft <= 0)
      return 'Condiciones cercanas para iniciar siembra';
    return 'Sigue preparando el suelo para la siembra';
  }

  double _ppmCapFor({required String? cropKey, required AgroMetricKey key}) =>
      NpkCaps.forCropMetric(cropKey: cropKey, metricKey: key);
  double _toIndex0to100(
    double ppm,
    AgroMetricKey key, {
    required String? cropKey,
  }) => ((ppm / _ppmCapFor(cropKey: cropKey, key: key)) * 100.0).clamp(
    0.0,
    100.0,
  );

  String _labelFromRangeTuned({
    required double index0to100,
    required AgroRange range,
  }) {
    if (index0to100 < range.lowMax) return 'Crítico';
    if (index0to100 < range.optimalMin)
      return (range.optimalMin - index0to100).abs() <=
              ((range.optimalMin - range.lowMax).abs() * 0.10)
          ? 'Ajuste leve'
          : 'Bajo';
    if (index0to100 <= range.optimalMax) return 'Óptimo';
    if (index0to100 <= range.highMin)
      return (index0to100 - range.optimalMax).abs() <=
              ((range.highMin - range.optimalMax).abs() * 0.10)
          ? 'Ajuste leve'
          : 'Alto';
    return 'Crítico';
  }

  String _rawMetricStatusFromTargets({
    required double value,
    required AgroRange range,
  }) => _labelFromRangeTuned(index0to100: value, range: range);
  double _scoreFromRawRange({
    required double value,
    required AgroRange range,
  }) => _scoreFromIndexRange(index0to100: value, range: range);

  double _scoreFromIndexRange({
    required double index0to100,
    required AgroRange range,
  }) {
    if (index0to100 <= range.lowMax || index0to100 >= range.highMin) return 0.0;
    if (index0to100 >= range.optimalMin && index0to100 <= range.optimalMax)
      return 1.0;
    if (index0to100 < range.optimalMin)
      return ((index0to100 - range.lowMax) /
              (range.optimalMin - range.lowMax).abs())
          .clamp(0.0, 1.0);
    return ((range.highMin - index0to100) /
            (range.highMin - range.optimalMax).abs())
        .clamp(0.0, 1.0);
  }

  String _irrigationTitleFromEval(AgroEvalResult eval) {
    final metric = eval.metrics[AgroMetricKey.soilMoisture];
    if (metric == null) return 'Recomendación pendiente';
    switch (metric.band) {
      case AgroBand.critical:
      case AgroBand.low:
        return 'Riega dentro de las próximas 24 horas';
      case AgroBand.high:
        return 'Evita riego por ahora';
      case AgroBand.optimal:
        return 'Humedad estable: monitorea';
      case AgroBand.unknown:
        return 'Recomendación pendiente';
    }
  }

  String _irrigationTagFromEval(AgroEvalResult eval) {
    final metric = eval.metrics[AgroMetricKey.soilMoisture];
    if (metric == null) return '—';
    switch (metric.band) {
      case AgroBand.critical:
      case AgroBand.low:
        return '24h';
      case AgroBand.high:
        return 'OK';
      case AgroBand.optimal:
        return 'Auto';
      case AgroBand.unknown:
        return '—';
    }
  }

  String _irrigationTitleFromTargets({
    required double soilMoisturePct,
    required StageTargets targets,
  }) {
    switch (_rawMetricStatusFromTargets(
      value: soilMoisturePct,
      range: targets.moistureRaw,
    )) {
      case 'Crítico':
      case 'Bajo':
        return 'Riega dentro de las próximas 24 horas';
      case 'Alto':
        return 'Evita riego por ahora';
      case 'Óptimo':
        return 'Humedad estable: monitorea';
      default:
        return 'Monitorea humedad del suelo';
    }
  }

  String _irrigationTagFromTargets({
    required double soilMoisturePct,
    required StageTargets targets,
  }) {
    switch (_rawMetricStatusFromTargets(
      value: soilMoisturePct,
      range: targets.moistureRaw,
    )) {
      case 'Crítico':
      case 'Bajo':
        return '24h';
      case 'Alto':
        return 'OK';
      case 'Óptimo':
        return 'Auto';
      default:
        return 'Mon';
    }
  }

  double _calcSoilHealthRealistic({
    required BioGTelemetry? t,
    required AgroEvalResult? eval,
    required StageTargets? targets,
    required String? cropKey,
  }) {
    if (eval != null) return eval.soilControlScore01.clamp(0.0, 1.0);
    if (t == null || targets == null) return 0.0;
    return (((_scoreFromRawRange(
                      value: t.soilMoisturePct,
                      range: targets.moistureRaw,
                    ) +
                    _scoreFromRawRange(
                      value: t.soilTempC,
                      range: targets.soilTemp,
                    ) +
                    _scoreFromRawRange(value: t.ph, range: targets.ph) +
                    _scoreFromRawRange(value: t.ec, range: targets.ec) +
                    _scoreFromRawRange(
                      value: t.resistance,
                      range: targets.resistance,
                    )) /
                5.0) +
            ((_scoreFromIndexRange(
                          index0to100: _toIndex0to100(
                            t.n.toDouble(),
                            AgroMetricKey.n,
                            cropKey: cropKey,
                          ),
                          range: targets.nIndex,
                        ) +
                        _scoreFromIndexRange(
                          index0to100: _toIndex0to100(
                            t.p.toDouble(),
                            AgroMetricKey.p,
                            cropKey: cropKey,
                          ),
                          range: targets.pIndex,
                        ) +
                        _scoreFromIndexRange(
                          index0to100: _toIndex0to100(
                            t.k.toDouble(),
                            AgroMetricKey.k,
                            cropKey: cropKey,
                          ),
                          range: targets.kIndex,
                        )) /
                    3.0) /
                2.0)
        .clamp(0.0, 1.0);
  }

  String _soilTempStatus(double value) => value < 14
      ? 'Baja'
      : value > 36
      ? 'Alta'
      : 'Óptima';
}

extension on DashboardMetricUiData {
  DashboardMetricUiData copyWith({
    String? title,
    String? value,
    String? status,
    String? assetIcon,
  }) {
    return DashboardMetricUiData(
      title: title ?? this.title,
      value: value ?? this.value,
      status: status ?? this.status,
      assetIcon: assetIcon ?? this.assetIcon,
    );
  }
}
