// lib/screens/dashboard/dashboard_presenter.dart
import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_event_input_factory.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/agro/event_engine.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart'; // <-- IMPORTANTE: Lo usamos para las dosis en vivo
import 'package:bio_g/core/agro/nutrient_target_range_resolver.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
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

class DashboardTreeStatusUiData {
  final String title;
  final String stateLabel;
  final String profileLabel;
  final String stageLabel;
  final String anchorText;
  final String priorityText;
  final String helperText;
  final String? criticalLabel;
  final String? precisionLabel;

  const DashboardTreeStatusUiData({
    required this.title,
    required this.stateLabel,
    required this.profileLabel,
    required this.stageLabel,
    required this.anchorText,
    required this.priorityText,
    required this.helperText,
    this.criticalLabel,
    this.precisionLabel,
  });
}

class DashboardViewData {
  final String fieldLabel;
  final String cropLabel;
  final String cropIconAsset;

  /// Soil-health ring value (0.0–1.0), or `null` when there is no telemetry.
  /// Null renders as "--" instead of a misleading 0%.
  final double? soilHealth;
  final String soilHealthLabel;
  final String npkTitle;
  final String npkSubtitle;
  final DashboardMetricUiData moisture;
  final DashboardMetricUiData temperature;
  final DashboardMetricUiData ph;
  final DashboardMetricUiData resistance;
  final DashboardInsightUiData irrigation;
  final DashboardTreeStatusUiData? treeStatus;
  final String cropJourneyTitle;
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
    this.treeStatus,
    this.cropJourneyTitle = 'Rendimiento\nestimado',
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
    final bool isTree = isTreeContext(runtime.cropContext);
    final treeContext = runtime.cropContext;

    final AgroEvalResult? effectiveEval = isPlanted
        ? (isTree ? runtime.eval : (runtime.eval ?? store.lastAgroEval))
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

    final DashboardTreeStatusUiData? treeStatus = isTree && treeContext != null
        ? _buildTreeStatus(treeContext)
        : null;

    // No telemetry → no soil-health reading. Returning null (instead of 0.0)
    // keeps the ring from rendering a misleading "0%" that reads like a real
    // bad-soil score. The ring shows "--" for null, matching the metric tiles.
    final double? soilHealth = telemetry == null
        ? null
        : (isPlanted
              ? _calcSoilHealthRealistic(
                  t: telemetry,
                  eval: effectiveEval,
                  targets: targets,
                  cropKey: runtime.cropKeyName,
                )
              : _calcPreSowingSoilHealth(telemetry));

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

    if (isPlanted && telemetry != null && !isTree) {
      final scaleId = runtime.cropContext?.cultivationScaleId;
      final cropContext = runtime.cropContext;

      final nInt = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.n,
        rawPpm: telemetry.n.toDouble(),
        cropKey: runtime.cropKeyName,
        stageKey: stageResult?.stageKey,
        profileId: runtime.profile?.id,
        varietyId: cropContext?.varietyId,
        varietyAlias: cropContext?.varietyAlias,
        calendarId: cropContext?.calendarTypeId,
        targets: targets,
        cultivationScaleId: scaleId,
      );
      final pInt = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.p,
        rawPpm: telemetry.p.toDouble(),
        cropKey: runtime.cropKeyName,
        stageKey: stageResult?.stageKey,
        profileId: runtime.profile?.id,
        varietyId: cropContext?.varietyId,
        varietyAlias: cropContext?.varietyAlias,
        calendarId: cropContext?.calendarTypeId,
        targets: targets,
        cultivationScaleId: scaleId,
      );
      final kInt = NutrientRecommendationEngine.interpret(
        nutrient: AgroMetricKey.k,
        rawPpm: telemetry.k.toDouble(),
        cropKey: runtime.cropKeyName,
        stageKey: stageResult?.stageKey,
        profileId: runtime.profile?.id,
        varietyId: cropContext?.varietyId,
        varietyAlias: cropContext?.varietyAlias,
        calendarId: cropContext?.calendarTypeId,
        targets: targets,
        cultivationScaleId: scaleId,
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

    if (isTree && treeContext != null) {
      // Fuente \u00daNICA = motor del \u00e1rbol (apple_tree_crop_definition). Mostramos
      // el estado real N\u00b7P\u00b7K (igual que granos) leyendo el mismo `effectiveEval`
      // que alimenta el ring de salud, para que dashboard y detalle NUNCA se
      // contradigan. No usamos NutrientRecommendationEngine (motor de granos)
      // porque no tiene perfil de \u00e1rbol y produce verdictos falsos.
      if (effectiveEval != null) {
        final String nL =
            effectiveEval.metrics[AgroMetricKey.n]?.labelEs ?? '\u2014';
        final String pL =
            effectiveEval.metrics[AgroMetricKey.p]?.labelEs ?? '\u2014';
        final String kL =
            effectiveEval.metrics[AgroMetricKey.k]?.labelEs ?? '\u2014';
        npkTitle = 'N: $nL \u00b7 P: $pL \u00b7 K: $kL';
        npkSubtitle = _treeNpkStatusSubtitle(effectiveEval, treeContext);
      } else {
        npkTitle = 'Niveles NPK del \u00e1rbol';
        npkSubtitle = _treeNpkSubtitle(treeContext);
      }
    }

    late final String irrigationTitle;
    late final String irrigationSubtitle;
    late final String irrigationTag;

    if (isTree && treeContext != null) {
      irrigationTitle = _treeIrrigationTitle(treeContext, effectiveEval);
      irrigationSubtitle = treeStagePriorityText(treeContext.phenologyStageId);
      irrigationTag =
          treeCriticalWindowLabel(treeContext.phenologyStageId) != null
          ? 'Cr\u00edtica'
          : '\u00c1rbol';
    } else if (isPlanted) {
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
      cropLabel: isTree && treeContext != null
          ? treeCropDisplayTitle(treeContext)
          : runtime.cropLabel,
      cropIconAsset: runtime.cropIconAsset,
      soilHealth: soilHealth,
      soilHealthLabel: isTree
          ? 'Monitoreo continuo del \u00e1rbol'
          : telemetry == null
          ? 'Sin datos del sensor'
          : isPlanted
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
      treeStatus: treeStatus,
      cropJourneyTitle: isTree
          ? 'Rendimiento aproximado\ndel \u00e1rbol'
          : 'Rendimiento\nestimado',
      events: dashboardEvents,
    );
  }

  DashboardTreeStatusUiData _buildTreeStatus(DeviceCropContext context) {
    final String stateId = normalizeTreeStateId(context.perennialStateId);
    final String stageId = normalizeTreeStageId(context.phenologyStageId);
    final String profileLabel = treeProfileDisplayName(context.profileId);
    final bool hasGeneralProfile = profileLabel == 'Perfil general';
    final bool hasUnknownState = stateId == TreeStateIds.unknown;
    final bool hasUnknownStage = stageId == TreeStageIds.unknown;

    return DashboardTreeStatusUiData(
      title: treeCropDisplayTitle(context),
      stateLabel: 'Estado: ${treeStateDisplayName(stateId)}',
      profileLabel: 'Perfil: $profileLabel',
      stageLabel: 'Etapa: ${treeStageDisplayName(stageId)}',
      anchorText: treeAnchorDisplayText(
        context.perennialAnchorDate,
        context.perennialAnchorTypeId,
      ),
      priorityText: treeStagePriorityText(stageId),
      criticalLabel: treeCriticalWindowLabel(stageId),
      precisionLabel: hasGeneralProfile || hasUnknownState || hasUnknownStage
          ? 'Precisi\u00f3n media'
          : null,
      helperText: hasGeneralProfile || hasUnknownState || hasUnknownStage
          ? 'Puedes ajustar variedad, estado o etapa despu\u00e9s.'
          : 'BIO-G interpreta tus sensores seg\u00fan la etapa visible del \u00e1rbol.',
    );
  }

  String _treeNpkSubtitle(DeviceCropContext context) {
    final String stageId = normalizeTreeStageId(context.phenologyStageId);
    if (stageId == TreeStageIds.unknown ||
        normalizeTreeStateId(context.perennialStateId) ==
            TreeStateIds.unknown) {
      return 'Perfil general: puedes ajustar variedad, estado o etapa despu\u00e9s.';
    }
    if (treeCriticalWindowLabel(stageId) != null) {
      return 'La etapa visible aumenta la importancia de agua, suelo y nutrici\u00f3n.';
    }
    return treeStagePriorityText(stageId);
  }

  /// Subtítulo de la card NPK del árbol basado en el peor nutriente del propio
  /// eval del árbol (misma fuente que el ring y el detalle). Si todos están
  /// óptimos o sin dato, cae al texto de etapa.
  String _treeNpkStatusSubtitle(
    AgroEvalResult eval,
    DeviceCropContext context,
  ) {
    final List<AgroMetricEval> nutrients =
        <AgroMetricEval?>[
          eval.metrics[AgroMetricKey.n],
          eval.metrics[AgroMetricKey.p],
          eval.metrics[AgroMetricKey.k],
        ].whereType<AgroMetricEval>().toList();

    if (nutrients.isEmpty) return _treeNpkSubtitle(context);

    nutrients.sort((a, b) => a.score01.compareTo(b.score01));
    final AgroMetricEval worst = nutrients.first;

    if (worst.band == AgroBand.optimal || worst.band == AgroBand.unknown) {
      return _treeNpkSubtitle(context);
    }

    final String? rec = worst.shortRecommendationEs;
    if (rec != null && rec.trim().isNotEmpty) return rec;
    return _treeNpkSubtitle(context);
  }

  String _treeIrrigationTitle(DeviceCropContext context, AgroEvalResult? eval) {
    final String stageId = normalizeTreeStageId(context.phenologyStageId);
    final AgroBand? moistureBand =
        eval?.metrics[AgroMetricKey.soilMoisture]?.band;
    if (moistureBand == AgroBand.low || moistureBand == AgroBand.critical) {
      return switch (stageId) {
        TreeStageIds.flowering => 'Protege humedad en floraci\u00f3n',
        TreeStageIds.fruitSet => 'Evita d\u00e9ficit en cuajado',
        TreeStageIds.fruitFill => 'Sost\u00e9n llenado de fruto',
        TreeStageIds.postHarvest => 'Cuida recuperaci\u00f3n post-cosecha',
        TreeStageIds.rootEstablishment => 'Mant\u00e9n humedad estable',
        _ => 'Revisa humedad del \u00e1rbol',
      };
    }

    return switch (stageId) {
      TreeStageIds.rootEstablishment => 'Mant\u00e9n humedad estable',
      TreeStageIds.flowering => 'Ventana cr\u00edtica activa',
      TreeStageIds.fruitSet => 'Evita estr\u00e9s en cuajado',
      TreeStageIds.fruitFill => 'Sost\u00e9n llenado de fruto',
      TreeStageIds.postHarvest => 'Cuida post-cosecha',
      TreeStageIds.dormancy => 'Monitoreo pasivo',
      _ => 'Monitoreo del \u00e1rbol',
    };
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
    if (isTreeContext(runtime.cropContext) && runtime.cropContext != null) {
      return _buildTreeDashboardEvents(
        runtime: runtime,
        effectiveEval: effectiveEval,
        stageResult: stageResult,
        now: now,
      );
    }

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

  List<AgronomicEvent> _buildTreeDashboardEvents({
    required CropRuntimeSnapshot runtime,
    required AgroEvalResult? effectiveEval,
    required CropStageResult? stageResult,
    required DateTime now,
  }) {
    final context = runtime.cropContext;
    if (context == null) return const <AgronomicEvent>[];

    final telemetry = runtime.live;
    final String stageId = normalizeTreeStageId(context.phenologyStageId);
    final String stageLabel =
        stageResult?.stageLabelEs ?? treeStageDisplayName(stageId);
    final String cropTitle = treeCropDisplayTitle(context);
    final events = <AgronomicEvent>[
      AgronomicEvent(
        type: AgronomicEventType.cropActivated,
        severity: AgronomicEventSeverity.info,
        title: cropTitle,
        message:
            'BIO-G interpreta tus sensores seg\u00fan el estado y etapa visible del \u00e1rbol.',
        timestamp: now,
        deviceId: runtime.device?.id,
        seedProfileId: context.profileId,
        seedAlias: treeProfileDisplayName(context.profileId),
        stageKey: stageId,
        stageLabel: stageLabel,
        isInformative: true,
        metadata: const <String, Object?>{
          'source': 'dashboard_tree',
          'group': 'context',
        },
      ),
    ];

    final metrics =
        effectiveEval?.metrics ?? const <AgroMetricKey, AgroMetricEval>{};
    final moisture = metrics[AgroMetricKey.soilMoisture]?.band;
    final soilTemp = metrics[AgroMetricKey.soilTemp]?.band;
    final resistance = metrics[AgroMetricKey.resistance]?.band;
    final ec = metrics[AgroMetricKey.ec]?.band;
    final nutrientLow =
        <AgroMetricKey>[AgroMetricKey.n, AgroMetricKey.p, AgroMetricKey.k].any((
          key,
        ) {
          final band = metrics[key]?.band;
          return band == AgroBand.low || band == AgroBand.critical;
        });

    bool lowish(AgroBand? band) =>
        band == AgroBand.low || band == AgroBand.critical;
    bool highish(AgroBand? band) =>
        band == AgroBand.high || band == AgroBand.critical;
    AgronomicEventSeverity severityFor(AgroBand? band) =>
        band == AgroBand.critical
        ? AgronomicEventSeverity.critical
        : AgronomicEventSeverity.warning;

    void push({
      required AgronomicEventType type,
      required AgronomicEventSeverity severity,
      required String title,
      required String message,
      String? metricKey,
      bool isCritical = false,
    }) {
      events.add(
        AgronomicEvent(
          type: type,
          severity: severity,
          title: title,
          message: message,
          timestamp: now,
          deviceId: runtime.device?.id,
          metricKey: metricKey,
          seedProfileId: context.profileId,
          seedAlias: treeProfileDisplayName(context.profileId),
          stageKey: stageId,
          stageLabel: stageLabel,
          isCritical: isCritical || severity == AgronomicEventSeverity.critical,
          metadata: const <String, Object?>{
            'source': 'dashboard_tree',
            'group': 'tree_alert',
          },
        ),
      );
    }

    switch (stageId) {
      case TreeStageIds.rootEstablishment:
        if (lowish(moisture)) {
          push(
            type: AgronomicEventType.lowMoisture,
            severity: severityFor(moisture),
            title: 'Humedad baja en establecimiento',
            message:
                'El \u00e1rbol est\u00e1 en establecimiento. Mant\u00e9n humedad estable y evita saturaci\u00f3n del suelo.',
            metricKey: EventMetricKeys.soilMoisture,
          );
        } else if (highish(moisture)) {
          push(
            type: AgronomicEventType.highMoisture,
            severity: severityFor(moisture),
            title: 'Exceso de humedad en establecimiento',
            message:
                'Exceso de humedad en establecimiento. Revisa drenaje y evita saturaci\u00f3n.',
            metricKey: EventMetricKeys.soilMoisture,
          );
        }
        if (highish(resistance)) {
          push(
            type: AgronomicEventType.soilCompaction,
            severity: severityFor(resistance),
            title: 'Suelo resistente para ra\u00edz',
            message:
                'El \u00e1rbol est\u00e1 formando ra\u00edz. Revisa compactaci\u00f3n sin hacer labores agresivas junto al tronco.',
            metricKey: EventMetricKeys.resistance,
          );
        }
        break;
      case TreeStageIds.flowering:
        if ((telemetry?.airTempC ?? 99) <= 4) {
          push(
            type: AgronomicEventType.frostWarning,
            severity: (telemetry?.airTempC ?? 99) <= 0
                ? AgronomicEventSeverity.critical
                : AgronomicEventSeverity.warning,
            title: 'Riesgo de estr\u00e9s durante floraci\u00f3n',
            message:
                'Floraci\u00f3n activa: peque\u00f1as desviaciones pueden afectar la producci\u00f3n de la temporada.',
            metricKey: EventMetricKeys.soilTemp,
          );
        }
        if (lowish(moisture)) {
          push(
            type: AgronomicEventType.lowMoisture,
            severity: severityFor(moisture),
            title: 'D\u00e9ficit h\u00eddrico en floraci\u00f3n',
            message:
                'Floraci\u00f3n activa: peque\u00f1as desviaciones pueden afectar la producci\u00f3n de la temporada.',
            metricKey: EventMetricKeys.soilMoisture,
          );
        }
        if ((telemetry?.airHumidityPct ?? 0) >= 85) {
          push(
            type: AgronomicEventType.highAirHumidity,
            severity: AgronomicEventSeverity.warning,
            title: 'Humedad alta durante floraci\u00f3n',
            message:
                'Humedad ambiental elevada durante floraci\u00f3n. Revisa el \u00e1rbol y mant\u00e9n monitoreo.',
          );
        }
        break;
      case TreeStageIds.fruitSet:
        if (lowish(moisture)) {
          push(
            type: AgronomicEventType.lowMoisture,
            severity: severityFor(moisture),
            title: 'D\u00e9ficit h\u00eddrico en cuajado',
            message:
                'Cuajado activo: evita estr\u00e9s h\u00eddrico o t\u00e9rmico. Esta etapa tiene poca tolerancia al estr\u00e9s.',
            metricKey: EventMetricKeys.soilMoisture,
          );
        }
        if ((telemetry?.airTempC ?? 0) >= 35 || highish(soilTemp)) {
          push(
            type: AgronomicEventType.heatStress,
            severity: severityFor(soilTemp),
            title: 'Calor durante cuajado',
            message:
                'Cuajado activo: evita estr\u00e9s h\u00eddrico o t\u00e9rmico.',
            metricKey: EventMetricKeys.soilTemp,
          );
        }
        if (highish(ec)) {
          push(
            type: AgronomicEventType.nutrientImbalance,
            severity: severityFor(ec),
            title: 'CE alta en cuajado',
            message:
                'Cuajado activo: revisa salinidad si la lectura se mantiene alta.',
          );
        }
        break;
      case TreeStageIds.fruitFill:
        if (lowish(moisture) ||
            (telemetry?.airTempC ?? 0) >= 35 ||
            highish(soilTemp)) {
          push(
            type: lowish(moisture)
                ? AgronomicEventType.lowMoisture
                : AgronomicEventType.heatStress,
            severity: lowish(moisture)
                ? severityFor(moisture)
                : severityFor(soilTemp),
            title: 'Estr\u00e9s en llenado de fruto',
            message:
                'Llenado de fruto: el \u00e1rbol necesita estabilidad para sostener calidad y tama\u00f1o.',
            metricKey: lowish(moisture)
                ? EventMetricKeys.soilMoisture
                : EventMetricKeys.soilTemp,
          );
        }
        if (nutrientLow) {
          push(
            type: AgronomicEventType.nutrientImbalance,
            severity: AgronomicEventSeverity.caution,
            title: 'Nutrici\u00f3n a revisar',
            message:
                'Llenado de fruto: revisa la lectura nutrimental junto con humedad, pH y CE.',
            metricKey: EventMetricKeys.npk,
          );
        }
        break;
      case TreeStageIds.postHarvest:
        if (lowish(moisture) || nutrientLow) {
          push(
            type: lowish(moisture)
                ? AgronomicEventType.lowMoisture
                : AgronomicEventType.nutrientImbalance,
            severity: lowish(moisture)
                ? severityFor(moisture)
                : AgronomicEventSeverity.caution,
            title: 'Post-cosecha con estr\u00e9s',
            message:
                'Post-cosecha: el \u00e1rbol recupera reservas para el siguiente ciclo.',
            metricKey: lowish(moisture)
                ? EventMetricKeys.soilMoisture
                : EventMetricKeys.npk,
          );
        }
        break;
      case TreeStageIds.dormancy:
        if (moisture == AgroBand.critical || soilTemp == AgroBand.critical) {
          push(
            type: AgronomicEventType.recovery,
            severity: AgronomicEventSeverity.warning,
            title: 'Extremo durante reposo',
            message:
                'Reposo: monitoreo pasivo del \u00e1rbol. Solo conviene actuar si las lecturas extremas se mantienen.',
          );
        }
        break;
      default:
        if (lowish(moisture)) {
          push(
            type: AgronomicEventType.lowMoisture,
            severity: severityFor(moisture),
            title: 'Humedad baja en el \u00e1rbol',
            message:
                'Revisa esta lectura dentro del estado visible del \u00e1rbol.',
            metricKey: EventMetricKeys.soilMoisture,
          );
        }
        break;
    }

    return events;
  }

  CropStageResult? _previousDashboardStage(
    CropRuntimeSnapshot runtime,
    DateTime now,
  ) {
    if (!runtime.isPlanted) return null;
    if (isTreeContext(runtime.cropContext)) return null;
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

  double _scoreNutrientAgainstTarget({
    required double value,
    required AgroMetricKey key,
    required String? cropKey,
    required StageTargets targets,
  }) {
    final AgroRange? comparableRange =
        NutrientTargetRangeResolver.comparableRange(
          nutrient: key,
          cropKey: cropKey,
          targets: targets,
        );

    if (comparableRange != null) {
      return _scoreFromRawRange(value: value, range: comparableRange);
    }

    final double cap = NpkCaps.forCropMetric(cropKey: cropKey, metricKey: key);
    final double index0to100 = cap <= 0
        ? 0.0
        : ((value / cap) * 100.0).clamp(0.0, 100.0);

    final AgroRange legacyRange = switch (key) {
      AgroMetricKey.n => targets.nIndex,
      AgroMetricKey.p => targets.pIndex,
      AgroMetricKey.k => targets.kIndex,
      _ => targets.nIndex,
    };

    return _scoreFromIndexRange(index0to100: index0to100, range: legacyRange);
  }

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
            ((_scoreNutrientAgainstTarget(
                          value: t.n.toDouble(),
                          key: AgroMetricKey.n,
                          cropKey: cropKey,
                          targets: targets,
                        ) +
                        _scoreNutrientAgainstTarget(
                          value: t.p.toDouble(),
                          key: AgroMetricKey.p,
                          cropKey: cropKey,
                          targets: targets,
                        ) +
                        _scoreNutrientAgainstTarget(
                          value: t.k.toDouble(),
                          key: AgroMetricKey.k,
                          cropKey: cropKey,
                          targets: targets,
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
