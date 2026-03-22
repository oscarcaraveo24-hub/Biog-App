import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_event_input_factory.dart';
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/agro/event_engine.dart';
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
        ? _calcSoilHealthRealistic(t: telemetry, eval: effectiveEval)
        : _calcPreSowingSoilHealth(telemetry);

    final String moistureValue = telemetry == null
        ? '--'
        : '${telemetry.soilMoisturePct.toStringAsFixed(0)}%';

    final String moistureStatus = telemetry == null
        ? '—'
        : isGenericMode
        ? 'Lectura actual'
        : isPlanted
        ? ((effectiveEval != null)
              ? (effectiveEval.metrics[AgroMetricKey.soilMoisture]?.labelEs ??
                    '—')
              : _soilMoistureStatus(telemetry.soilMoisturePct))
        : _preSowingMoistureStatus(telemetry.soilMoisturePct);

    final String tempValue = telemetry == null
        ? '--'
        : '${telemetry.soilTempC.toStringAsFixed(0)}°C';

    final String tempStatus = telemetry == null
        ? '—'
        : isGenericMode
        ? 'Lectura actual'
        : _soilTempStatus(telemetry.soilTempC);

    final String phValue = telemetry == null
        ? '--'
        : telemetry.ph.toStringAsFixed(1);

    final String phStatus = telemetry == null
        ? '—'
        : isGenericMode
        ? 'Lectura actual'
        : isPlanted
        ? ((effectiveEval != null)
              ? (effectiveEval.metrics[AgroMetricKey.ph]?.labelEs ?? '—')
              : _phStatus(telemetry.ph))
        : _preSowingPhStatus(telemetry.ph);

    final String resistanceValue = telemetry == null
        ? '--'
        : '${telemetry.resistance.toStringAsFixed(1)} MPa';

    final String resistanceStatus = telemetry == null
        ? '—'
        : isGenericMode
        ? 'Lectura actual'
        : isPlanted
        ? ((effectiveEval != null)
              ? (effectiveEval.metrics[AgroMetricKey.resistance]?.labelEs ??
                    '—')
              : _resistanceStatus(telemetry.resistance))
        : _preSowingResistanceStatus(telemetry.resistance);

    final String npkTitle = isPlanted
        ? ((telemetry != null && targets != null)
              ? _npkTitleFromTargets(t: telemetry, targets: targets)
              : (telemetry == null ? 'NPK  ·  —' : _npkTitle(telemetry)))
        : 'NPK  ·  Pendiente por etapa';

    final String npkSubtitle = isPlanted
        ? ((telemetry != null && targets != null)
              ? _npkSubtitleFromTargets(t: telemetry, targets: targets)
              : (telemetry == null ? '—' : _npkSubtitle(telemetry)))
        : (isPlanned ? 'Disponible tras siembra' : 'Modo genérico');

    late final String irrigationTitle;
    late final String irrigationSubtitle;
    late final String irrigationTag;

    if (isPlanted) {
      irrigationTitle = (effectiveEval != null)
          ? _irrigationTitleFromEval(effectiveEval)
          : (telemetry == null
                ? 'Recomendación pendiente'
                : _irrigationTitle(telemetry.soilMoisturePct));

      irrigationSubtitle = 'Basado en humedad del suelo y modelo Bio-G';

      irrigationTag = (effectiveEval != null)
          ? _irrigationTagFromEval(effectiveEval)
          : (telemetry == null
                ? '—'
                : _irrigationTag(telemetry.soilMoisturePct));
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
            'Asigna una semilla y calendario para adaptar sensores y alertas';
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
    );
  }

  DashboardSyncPlan buildSyncPlan({
    required BioGStore store,
    required AgroEvalResult? resolvedEval,
    required AlertsState nextAlertsState,
  }) {
    if (resolvedEval == null) {
      return const DashboardSyncPlan(
        shouldSetEval: false,
        shouldSetAlerts: false,
      );
    }

    final bool shouldSetEval = !_sameAgroEval(store.lastAgroEval, resolvedEval);
    final bool shouldSetAlerts = !_sameAlertsState(
      store.alertsState,
      nextAlertsState,
    );

    return DashboardSyncPlan(
      shouldSetEval: shouldSetEval,
      shouldSetAlerts: shouldSetAlerts,
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
    );

    return EventEngine.build(input);
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

    if ((a.soilControlScore01 - b.soilControlScore01).abs() > 0.0001) {
      return false;
    }

    if (a.metrics.length != b.metrics.length) return false;
    if (a.alerts.length != b.alerts.length) return false;
    if (a.suggestedAlertKeys.length != b.suggestedAlertKeys.length) {
      return false;
    }

    for (int i = 0; i < a.alerts.length; i++) {
      if (a.alerts[i].id != b.alerts[i].id) return false;
    }

    for (int i = 0; i < a.suggestedAlertKeys.length; i++) {
      if (a.suggestedAlertKeys[i] != b.suggestedAlertKeys[i]) return false;
    }

    for (final AgroMetricKey key in a.metrics.keys) {
      final AgroMetricEval? av = a.metrics[key];
      final AgroMetricEval? bv = b.metrics[key];

      if (av == null || bv == null) return false;
      if (av.band != bv.band) return false;
      if (av.labelEs != bv.labelEs) return false;
      if ((av.score01 - bv.score01).abs() > 0.0001) return false;

      final double? aValue = av.value;
      final double? bValue = bv.value;

      if (aValue == null || bValue == null) {
        if (aValue != bValue) return false;
      } else if ((aValue - bValue).abs() > 0.0001) {
        return false;
      }
    }

    return true;
  }

  bool _sameAlertsState(AlertsState a, AlertsState b) {
    if (identical(a, b)) return true;
    if (a.lastByType.length != b.lastByType.length) return false;

    for (final MapEntry<BioGAlertType, DateTime> entry
        in a.lastByType.entries) {
      final DateTime? other = b.lastByType[entry.key];
      if (other == null) return false;
      if (other != entry.value) return false;
    }

    return true;
  }

  String _buildFieldLabel(BioGDevice? device) {
    if (device == null) return 'Sin BioG';

    final String name = device.name.trim();
    if (name.isNotEmpty) return name;

    final String location = device.locationName.trim();
    if (location.isNotEmpty) return location;

    return 'BioG';
  }

  double _calcPreSowingSoilHealth(BioGTelemetry? telemetry) {
    if (telemetry == null) return 0.0;

    double score01Legacy(
      double value,
      double minOk,
      double maxOk,
      double hardMin,
      double hardMax,
    ) {
      if (value <= hardMin || value >= hardMax) return 0.0;
      if (value >= minOk && value <= maxOk) return 1.0;

      if (value < minOk) {
        final double x = (value - hardMin) / (minOk - hardMin);
        return x.clamp(0.0, 1.0);
      }

      final double x = (hardMax - value) / (hardMax - maxOk);
      return x.clamp(0.0, 1.0);
    }

    final double moisture01 = score01Legacy(
      telemetry.soilMoisturePct,
      28,
      55,
      5,
      85,
    );
    final double ph01 = score01Legacy(telemetry.ph, 5.8, 7.2, 4.5, 8.8);
    final double resistance01 = score01Legacy(
      telemetry.resistance,
      0.3,
      1.2,
      0.1,
      2.8,
    );
    final double ec01 = score01Legacy(telemetry.ec, 0.8, 2.0, 0.4, 3.2);

    return ((moisture01 + ph01 + resistance01 + ec01) / 4.0).clamp(0.0, 1.0);
  }

  String _preSowingMoistureStatus(double value) {
    if (value < 25) return 'Seco';
    if (value > 65) return 'Húmedo';
    return 'Apta';
  }

  String _preSowingPhStatus(double value) {
    if (value < 5.8) return 'Bajo';
    if (value > 7.2) return 'Alto';
    return 'Apto';
  }

  String _preSowingResistanceStatus(double value) {
    if (value > 2.0) return 'Compactado';
    if (value < 0.25) return 'Suelto';
    return 'Apto';
  }

  String _plannedInsightTitle(int plannedDaysLeft, BioGTelemetry? telemetry) {
    if (telemetry == null) {
      return plannedDaysLeft <= 0
          ? 'Valida el suelo antes de sembrar'
          : 'Monitorea condiciones antes de la siembra';
    }

    if (telemetry.resistance > 2.0) {
      return 'La resistencia del suelo sigue alta para siembra';
    }

    if (telemetry.soilMoisturePct < 25) {
      return 'Aumenta humedad antes de sembrar';
    }

    if (plannedDaysLeft <= 0) {
      return 'Condiciones cercanas para iniciar siembra';
    }

    return 'Sigue preparando el suelo para la siembra';
  }

  double _ppmCapFor(AgroMetricKey key) {
    switch (key) {
      case AgroMetricKey.n:
        return 120.0;
      case AgroMetricKey.p:
        return 80.0;
      case AgroMetricKey.k:
        return 140.0;
      default:
        return 100.0;
    }
  }

  double _toIndex0to100(double ppm, AgroMetricKey key) {
    return ((ppm / _ppmCapFor(key)) * 100.0).clamp(0.0, 100.0);
  }

  String _labelFromRangeTuned({
    required double index0to100,
    required AgroRange range,
  }) {
    final double value = index0to100;

    final double lowSpan = (range.optimalMin - range.lowMax).abs();
    final double highSpan = (range.highMin - range.optimalMax).abs();

    final double nearLow = lowSpan <= 0.0001 ? 0.0 : (lowSpan * 0.10);
    final double nearHigh = highSpan <= 0.0001 ? 0.0 : (highSpan * 0.10);

    if (value < range.lowMax) return 'Crítico';

    if (value < range.optimalMin) {
      final double delta = (range.optimalMin - value).abs();
      return (delta <= nearLow) ? 'Ajuste leve' : 'Bajo';
    }

    if (value <= range.optimalMax) return 'Óptimo';

    if (value <= range.highMin) {
      final double delta = (value - range.optimalMax).abs();
      return (delta <= nearHigh) ? 'Ajuste leve' : 'Alto';
    }

    return 'Crítico';
  }

  String _npkTitleFromTargets({
    required BioGTelemetry t,
    required StageTargets targets,
  }) {
    final String nLab = _labelFromRangeTuned(
      index0to100: _toIndex0to100(t.n.toDouble(), AgroMetricKey.n),
      range: targets.nIndex,
    );
    final String pLab = _labelFromRangeTuned(
      index0to100: _toIndex0to100(t.p.toDouble(), AgroMetricKey.p),
      range: targets.pIndex,
    );
    final String kLab = _labelFromRangeTuned(
      index0to100: _toIndex0to100(t.k.toDouble(), AgroMetricKey.k),
      range: targets.kIndex,
    );

    return 'NPK  ·  N $nLab · P $pLab · K $kLab';
  }

  String _npkSubtitleFromTargets({
    required BioGTelemetry t,
    required StageTargets targets,
  }) {
    final String nLab = _labelFromRangeTuned(
      index0to100: _toIndex0to100(t.n.toDouble(), AgroMetricKey.n),
      range: targets.nIndex,
    );
    final String pLab = _labelFromRangeTuned(
      index0to100: _toIndex0to100(t.p.toDouble(), AgroMetricKey.p),
      range: targets.pIndex,
    );
    final String kLab = _labelFromRangeTuned(
      index0to100: _toIndex0to100(t.k.toDouble(), AgroMetricKey.k),
      range: targets.kIndex,
    );

    final bool anyCritical =
        nLab == 'Crítico' || pLab == 'Crítico' || kLab == 'Crítico';
    if (anyCritical) return 'Crítico';

    final bool allOptimal =
        nLab == 'Óptimo' && pLab == 'Óptimo' && kLab == 'Óptimo';
    if (allOptimal) return 'Óptimo';

    return 'Ajuste leve';
  }

  String _irrigationTitleFromEval(AgroEvalResult eval) {
    final AgroMetricEval? metric = eval.metrics[AgroMetricKey.soilMoisture];
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
    final AgroMetricEval? metric = eval.metrics[AgroMetricKey.soilMoisture];
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

  double _calcSoilHealthRealistic({
    required BioGTelemetry? t,
    required AgroEvalResult? eval,
  }) {
    if (t == null && eval == null) return 0.0;

    double score01Legacy(
      double value,
      double minOk,
      double maxOk,
      double hardMin,
      double hardMax,
    ) {
      if (value <= hardMin || value >= hardMax) return 0.0;
      if (value >= minOk && value <= maxOk) return 1.0;

      if (value < minOk) {
        final double x = (value - hardMin) / (minOk - hardMin);
        return x.clamp(0.0, 1.0);
      }

      final double x = (hardMax - value) / (hardMax - maxOk);
      return x.clamp(0.0, 1.0);
    }

    late final double soilMoist01;
    late final double ph01;
    late final double ec01;
    late final double res01;

    if (eval != null) {
      soilMoist01 = (eval.metrics[AgroMetricKey.soilMoisture]?.score01 ?? 0.0)
          .clamp(0.0, 1.0);
      ph01 = (eval.metrics[AgroMetricKey.ph]?.score01 ?? 0.0).clamp(0.0, 1.0);
      ec01 = (eval.metrics[AgroMetricKey.ec]?.score01 ?? 0.0).clamp(0.0, 1.0);
      res01 = (eval.metrics[AgroMetricKey.resistance]?.score01 ?? 0.0).clamp(
        0.0,
        1.0,
      );
    } else {
      final BioGTelemetry telemetry = t!;
      soilMoist01 = score01Legacy(telemetry.soilMoisturePct, 30, 60, 5, 85);
      ph01 = score01Legacy(telemetry.ph, 5.8, 7.4, 4.5, 8.8);
      ec01 = score01Legacy(telemetry.ec, 0.9, 2.2, 0.4, 3.2);
      res01 = score01Legacy(telemetry.resistance, 0.3, 1.2, 0.1, 2.8);
    }

    final double soilConditions01 = ((soilMoist01 + ph01 + ec01 + res01) / 4.0)
        .clamp(0.0, 1.0);

    late final double n01;
    late final double p01;
    late final double k01;

    if (eval != null) {
      n01 = (eval.metrics[AgroMetricKey.n]?.score01 ?? 0.0).clamp(0.0, 1.0);
      p01 = (eval.metrics[AgroMetricKey.p]?.score01 ?? 0.0).clamp(0.0, 1.0);
      k01 = (eval.metrics[AgroMetricKey.k]?.score01 ?? 0.0).clamp(0.0, 1.0);
    } else {
      final BioGTelemetry telemetry = t!;
      n01 = (telemetry.n / 80.0).clamp(0.0, 1.0);
      p01 = (telemetry.p / 40.0).clamp(0.0, 1.0);
      k01 = (telemetry.k / 70.0).clamp(0.0, 1.0);
    }

    final double minNpk01 = <double>[
      n01,
      p01,
      k01,
    ].reduce((a, b) => a < b ? a : b);
    final double avgNpk01 = ((n01 + p01 + k01) / 3.0).clamp(0.0, 1.0);

    final double npkComposite01 = (0.70 * minNpk01 + 0.30 * avgNpk01).clamp(
      0.0,
      1.0,
    );

    const double soilW = 0.60;
    const double npkW = 0.40;

    double base01 = (soilW * soilConditions01 + npkW * npkComposite01).clamp(
      0.0,
      1.0,
    );

    const double threshold = 0.35;
    const double maxPenalty = 0.15;

    if (minNpk01 < threshold) {
      final double severity = ((threshold - minNpk01) / threshold).clamp(
        0.0,
        1.0,
      );
      base01 = (base01 - maxPenalty * severity).clamp(0.0, 1.0);
    }

    return base01;
  }

  String _soilMoistureStatus(double value) {
    if (value < 25) return 'Bajo';
    if (value > 70) return 'Alto';
    return 'Óptima';
  }

  String _soilTempStatus(double value) {
    if (value < 14) return 'Baja';
    if (value > 36) return 'Alta';
    return 'Óptima';
  }

  String _phStatus(double value) {
    if (value < 5.8) return 'Bajo';
    if (value > 7.4) return 'Alto';
    return 'Óptimo';
  }

  String _resistanceStatus(double value) {
    if (value < 0.3) return 'Baja';
    if (value > 2.0) return 'Alta';
    return 'Óptima';
  }

  String _bandLabel(String channel, double value, double low, double high) {
    if (value < low) return '$channel Bajo';
    if (value > high) return '$channel Alto';
    return '$channel Medio';
  }

  String _npkTitle(BioGTelemetry telemetry) {
    final String nLabel = _bandLabel('N', telemetry.n, 40, 70);
    final String pLabel = _bandLabel('P', telemetry.p, 18, 32);
    final String kLabel = _bandLabel('K', telemetry.k, 35, 55);
    return 'NPK  ·  $nLabel · $pLabel · $kLabel';
  }

  String _npkSubtitle(BioGTelemetry telemetry) {
    final bool nOk = telemetry.n >= 40 && telemetry.n <= 70;
    final bool pOk = telemetry.p >= 18 && telemetry.p <= 32;
    final bool kOk = telemetry.k >= 35 && telemetry.k <= 55;

    if (nOk && pOk && kOk) return 'Balanceado';
    return 'Desequilibrado';
  }

  String _irrigationTitle(double soilMoisturePct) {
    if (soilMoisturePct < 24) {
      return 'Riega dentro de las próximas 24 horas';
    }
    if (soilMoisturePct < 30) return 'Considera riego hoy';
    if (soilMoisturePct > 72) return 'Evita riego por ahora';
    return 'Humedad estable: monitorea';
  }

  String _irrigationTag(double soilMoisturePct) {
    if (soilMoisturePct < 24) return '24h';
    if (soilMoisturePct < 30) return 'Hoy';
    if (soilMoisturePct > 72) return 'OK';
    return 'Auto';
  }
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
