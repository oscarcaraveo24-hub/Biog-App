// lib/core/agro/event_engine.dart

import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/agronomic_event.dart';

/// ============================================================
/// EVENT ENGINE
/// ============================================================
///
/// Este motor NO dibuja nada.
/// Este motor NO dispara notificaciones.
/// Este motor solo responde:
///
/// "¿Qué está pasando agronómicamente?"
///
/// Devuelve una lista de [AgronomicEvent] farmer-friendly
/// que luego pueden consumir:
///
/// - History
/// - Dashboard
/// - Notifications
/// - Crop Care
///
/// ------------------------------------------------------------
/// Filosofía:
/// - Inputs normalizados
/// - Sin dependencia de widgets
/// - Reusable para varios cultivos
/// - Fácil de extender
/// ============================================================

class EventEngine {
  const EventEngine._();

  /// Punto principal de entrada.
  static List<AgronomicEvent> build(EventEngineInput input) {
    final events = <AgronomicEvent>[];

    final now = input.timestamp;

    // =========================================================
    // 1) CONTEXTO GENERAL
    // =========================================================
    if (input.isGenericMode) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.genericMode,
          severity: AgronomicEventSeverity.info,
          title: 'Modo genérico',
          message:
              'Aún no hay un cultivo configurado para este BioG, por eso la app solo muestra lecturas sin interpretación agronómica específica.',
          timestamp: now,
          deviceId: input.deviceId,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isInformative: true,
          metadata: const {'source': 'event_engine', 'group': 'context'},
        ),
      );
    }

    if (input.sowingDate != null && input.sowingDate!.isAfter(now)) {
      final days = input.sowingDate!
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;

      events.add(
        AgronomicEvent(
          type: AgronomicEventType.preSowing,
          severity: AgronomicEventSeverity.info,
          title: 'Pre-siembra',
          message: days <= 0
              ? 'El cultivo está marcado como próximo a sembrarse.'
              : 'La siembra está programada para dentro de $days día${days == 1 ? '' : 's'}.',
          timestamp: now,
          deviceId: input.deviceId,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isInformative: true,
          metadata: {
            'source': 'event_engine',
            'group': 'context',
            'daysUntilSowing': days,
          },
        ),
      );
    }

    if (!input.isGenericMode &&
        input.seedAlias != null &&
        input.seedAlias!.trim().isNotEmpty &&
        (input.sowingDate == null || !input.sowingDate!.isAfter(now))) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.cropActivated,
          severity: AgronomicEventSeverity.info,
          title: 'Cultivo activo',
          message:
              input.stageLabel != null && input.stageLabel!.trim().isNotEmpty
              ? 'El cultivo ${input.seedAlias} se está interpretando en etapa ${input.stageLabel}.'
              : 'El cultivo ${input.seedAlias} ya está activo en este BioG.',
          timestamp: now,
          deviceId: input.deviceId,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isInformative: true,
          metadata: const {'source': 'event_engine', 'group': 'context'},
        ),
      );
    }

    if (_hasStageTransition(input)) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.stageTransition,
          severity: AgronomicEventSeverity.info,
          title: 'Cambio de etapa',
          message:
              'El cultivo pasó de ${input.previousStageLabel ?? 'la etapa anterior'} a ${input.stageLabel ?? 'una nueva etapa'}.',
          timestamp: now,
          deviceId: input.deviceId,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isInformative: true,
          metadata: {
            'source': 'event_engine',
            'group': 'context',
            'fromStage': input.previousStageLabel,
            'toStage': input.stageLabel,
          },
        ),
      );
    }

    // =========================================================
    // 2) HUMEDAD
    // =========================================================
    final moistureBand = input.bandOf(EventMetricKeys.soilMoisture);
    if (moistureBand != null) {
      if (moistureBand.isLowish) {
        events.add(
          AgronomicEvent(
            type: AgronomicEventType.lowMoisture,
            severity: moistureBand.toSeverity(isLow: true),
            title: 'Humedad baja',
            message: input.soilMoisture != null
                ? 'La humedad de suelo está baja (${_fmt(input.soilMoisture)}%). Conviene revisar riego o retención de humedad.'
                : 'La humedad de suelo se detecta por debajo del rango esperado.',
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.soilMoisture,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            isCritical: moistureBand == AgroBand.critical,
            metadata: {
              'source': 'event_engine',
              'group': 'moisture',
              'value': input.soilMoisture,
              'band': moistureBand.name,
            },
          ),
        );
      } else if (moistureBand.isHighish) {
        events.add(
          AgronomicEvent(
            type: AgronomicEventType.highMoisture,
            severity: moistureBand.toSeverity(isLow: false),
            title: 'Humedad alta',
            message: input.soilMoisture != null
                ? 'La humedad de suelo está alta (${_fmt(input.soilMoisture)}%). Conviene vigilar exceso de agua o drenaje.'
                : 'La humedad de suelo se detecta por encima del rango esperado.',
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.soilMoisture,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            isCritical: moistureBand == AgroBand.critical,
            metadata: {
              'source': 'event_engine',
              'group': 'moisture',
              'value': input.soilMoisture,
              'band': moistureBand.name,
            },
          ),
        );
      } else if (_isStableMetric(
        history: input.history,
        selector: (r) => r.soilMoisture,
        currentBand: moistureBand,
        tolerance: input.rules.moistureStableTolerance,
        minSamples: input.rules.minStableSamples,
      )) {
        events.add(
          AgronomicEvent(
            type: AgronomicEventType.stableMoisture,
            severity: AgronomicEventSeverity.info,
            title: 'Humedad estable',
            message: 'La humedad se ha mantenido estable recientemente.',
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.soilMoisture,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            isInformative: true,
            metadata: const {'source': 'event_engine', 'group': 'moisture'},
          ),
        );
      }
    }

    // =========================================================
    // 3) pH
    // =========================================================
    final phBand = input.bandOf(EventMetricKeys.ph);
    if (phBand != null) {
      if (phBand.isLowish) {
        events.add(
          AgronomicEvent(
            type: AgronomicEventType.lowPh,
            severity: phBand.toSeverity(isLow: true),
            title: 'pH bajo',
            message: input.ph != null
                ? 'El pH está por debajo del rango esperado (${_fmt(input.ph)}). Conviene revisar acidez del suelo.'
                : 'El pH está por debajo del rango esperado.',
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.ph,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            isCritical: phBand == AgroBand.critical,
            metadata: {
              'source': 'event_engine',
              'group': 'ph',
              'value': input.ph,
              'band': phBand.name,
            },
          ),
        );
      } else if (phBand.isHighish) {
        events.add(
          AgronomicEvent(
            type: AgronomicEventType.highPh,
            severity: phBand.toSeverity(isLow: false),
            title: 'pH alto',
            message: input.ph != null
                ? 'El pH está por encima del rango esperado (${_fmt(input.ph)}). Conviene revisar alcalinidad del suelo.'
                : 'El pH está por encima del rango esperado.',
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.ph,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            isCritical: phBand == AgroBand.critical,
            metadata: {
              'source': 'event_engine',
              'group': 'ph',
              'value': input.ph,
              'band': phBand.name,
            },
          ),
        );
      } else if (_isStableMetric(
        history: input.history,
        selector: (r) => r.ph,
        currentBand: phBand,
        tolerance: input.rules.phStableTolerance,
        minSamples: input.rules.minStableSamples,
      )) {
        events.add(
          AgronomicEvent(
            type: AgronomicEventType.stablePh,
            severity: AgronomicEventSeverity.info,
            title: 'pH estable',
            message: 'El pH se ha mantenido estable recientemente.',
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.ph,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            isInformative: true,
            metadata: const {'source': 'event_engine', 'group': 'ph'},
          ),
        );
      }
    }

    // =========================================================
    // 4) RESISTENCIA / COMPACTACIÓN
    // =========================================================
    final resistanceBand = input.bandOf(EventMetricKeys.resistance);
    if (resistanceBand != null) {
      if (resistanceBand.isHighish) {
        events.add(
          AgronomicEvent(
            type: AgronomicEventType.soilCompaction,
            severity: resistanceBand.toSeverity(isLow: false),
            title: 'Suelo compacto',
            message: input.resistance != null
                ? 'La resistencia del suelo está alta (${_fmt(input.resistance)}). Podría haber compactación que limite raíz o infiltración.'
                : 'Se detecta una resistencia alta del suelo, posible compactación.',
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.resistance,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            isCritical: resistanceBand == AgroBand.critical,
            metadata: {
              'source': 'event_engine',
              'group': 'resistance',
              'value': input.resistance,
              'band': resistanceBand.name,
            },
          ),
        );
      } else if (resistanceBand == AgroBand.optimal &&
          input.resistance != null &&
          input.resistance! <= input.rules.goodStructureMaxResistance) {
        events.add(
          AgronomicEvent(
            type: AgronomicEventType.goodSoilStructure,
            severity: AgronomicEventSeverity.info,
            title: 'Estructura cómoda',
            message:
                'La resistencia del suelo luce cómoda para el desarrollo radicular.',
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.resistance,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            isInformative: true,
            metadata: {
              'source': 'event_engine',
              'group': 'resistance',
              'value': input.resistance,
              'band': resistanceBand.name,
            },
          ),
        );
      }
    }

    // =========================================================
    // 5) TEMPERATURA DE SUELO
    // =========================================================
    final tempBand = input.bandOf(EventMetricKeys.soilTemp);
    if (tempBand != null) {
      if (tempBand.isHighish) {
        events.add(
          AgronomicEvent(
            type: AgronomicEventType.heatStress,
            severity: tempBand.toSeverity(isLow: false),
            title: 'Calor alto',
            message: input.soilTemp != null
                ? 'La temperatura del suelo está elevada (${_fmt(input.soilTemp)}°C). Conviene vigilar estrés térmico.'
                : 'La temperatura del suelo está por encima del rango esperado.',
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.soilTemp,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            isCritical: tempBand == AgroBand.critical,
            metadata: {
              'source': 'event_engine',
              'group': 'soilTemp',
              'value': input.soilTemp,
              'band': tempBand.name,
            },
          ),
        );
      } else if (tempBand.isLowish) {
        events.add(
          AgronomicEvent(
            type: AgronomicEventType.coldStress,
            severity: tempBand.toSeverity(isLow: true),
            title: 'Frío en suelo',
            message: input.soilTemp != null
                ? 'La temperatura del suelo está baja (${_fmt(input.soilTemp)}°C). Conviene vigilar freno fisiológico.'
                : 'La temperatura del suelo está por debajo del rango esperado.',
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.soilTemp,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            isCritical: tempBand == AgroBand.critical,
            metadata: {
              'source': 'event_engine',
              'group': 'soilTemp',
              'value': input.soilTemp,
              'band': tempBand.name,
            },
          ),
        );
      } else if (_isStableMetric(
        history: input.history,
        selector: (r) => r.soilTemp,
        currentBand: tempBand,
        tolerance: input.rules.soilTempStableTolerance,
        minSamples: input.rules.minStableSamples,
      )) {
        events.add(
          AgronomicEvent(
            type: AgronomicEventType.stableSoilTemp,
            severity: AgronomicEventSeverity.info,
            title: 'Temperatura estable',
            message:
                'La temperatura del suelo se ha mantenido estable recientemente.',
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.soilTemp,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            isInformative: true,
            metadata: const {'source': 'event_engine', 'group': 'soilTemp'},
          ),
        );
      }
    }

    // =========================================================
    // 6) NPK
    // =========================================================
    if (input.hasAnyNpk) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.npkReading,
          severity: AgronomicEventSeverity.info,
          title: 'Lectura NPK reciente',
          message:
              'Se registró lectura nutrimental de NPK${_buildNpkInline(input)}.',
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: EventMetricKeys.npk,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isInformative: true,
          metadata: {
            'source': 'event_engine',
            'group': 'npk',
            'n': input.n,
            'p': input.p,
            'k': input.k,
          },
        ),
      );
    }

    final nBand = input.bandOf(EventMetricKeys.n);
    final pBand = input.bandOf(EventMetricKeys.p);
    final kBand = input.bandOf(EventMetricKeys.k);

    final nIsExcess = input.excessNutrientKeys.contains(EventMetricKeys.n);
    final pIsExcess = input.excessNutrientKeys.contains(EventMetricKeys.p);
    final kIsExcess = input.excessNutrientKeys.contains(EventMetricKeys.k);

    // ── Nitrógeno ──
    if (nBand != null && nBand.isLowish && !nIsExcess) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.nitrogenLow,
          severity: nBand.toSeverity(isLow: true),
          title: 'Nitrógeno bajo',
          message: input.n != null
              ? 'El nitrógeno aparece por debajo del rango esperado (${_fmt(input.n)} mg/kg).'
              : 'El nitrógeno aparece por debajo del rango esperado.',
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: EventMetricKeys.n,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isCritical: nBand == AgroBand.critical,
          metadata: {
            'source': 'event_engine',
            'group': 'npk',
            'value': input.n,
            'band': nBand.name,
          },
        ),
      );
    } else if (nBand != null && nIsExcess) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.nitrogenHigh,
          severity: nBand.toSeverity(isLow: false),
          title: 'Nitrógeno en exceso',
          message: input.n != null
              ? 'El nitrógeno aparece por encima del rango esperado (${_fmt(input.n)} mg/kg). Conviene reducir aportes nitrogenados.'
              : 'El nitrógeno aparece por encima del rango esperado.',
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: EventMetricKeys.n,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isCritical: false,
          metadata: {
            'source': 'event_engine',
            'group': 'npk',
            'value': input.n,
            'band': nBand.name,
            'excess': true,
          },
        ),
      );
    }

    // ── Fósforo ──
    if (pBand != null && pBand.isLowish && !pIsExcess) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.phosphorusLow,
          severity: pBand.toSeverity(isLow: true),
          title: 'Fósforo bajo',
          message: input.p != null
              ? 'El fósforo aparece por debajo del rango esperado (${_fmt(input.p)} mg/kg).'
              : 'El fósforo aparece por debajo del rango esperado.',
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: EventMetricKeys.p,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isCritical: pBand == AgroBand.critical,
          metadata: {
            'source': 'event_engine',
            'group': 'npk',
            'value': input.p,
            'band': pBand.name,
          },
        ),
      );
    } else if (pBand != null && pIsExcess) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.phosphorusHigh,
          severity: pBand.toSeverity(isLow: false),
          title: 'Fósforo en exceso',
          message: input.p != null
              ? 'El fósforo aparece por encima del rango esperado (${_fmt(input.p)} mg/kg). Conviene reducir aportes fosfatados.'
              : 'El fósforo aparece por encima del rango esperado.',
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: EventMetricKeys.p,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isCritical: false,
          metadata: {
            'source': 'event_engine',
            'group': 'npk',
            'value': input.p,
            'band': pBand.name,
            'excess': true,
          },
        ),
      );
    }

    // ── Potasio ──
    if (kBand != null && kBand.isLowish && !kIsExcess) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.potassiumLow,
          severity: kBand.toSeverity(isLow: true),
          title: 'Potasio bajo',
          message: input.k != null
              ? 'El potasio aparece por debajo del rango esperado (${_fmt(input.k)} mg/kg).'
              : 'El potasio aparece por debajo del rango esperado.',
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: EventMetricKeys.k,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isCritical: kBand == AgroBand.critical,
          metadata: {
            'source': 'event_engine',
            'group': 'npk',
            'value': input.k,
            'band': kBand.name,
          },
        ),
      );
    } else if (kBand != null && kIsExcess) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.potassiumHigh,
          severity: kBand.toSeverity(isLow: false),
          title: 'Potasio en exceso',
          message: input.k != null
              ? 'El potasio aparece por encima del rango esperado (${_fmt(input.k)} mg/kg). Conviene reducir aportes potásicos.'
              : 'El potasio aparece por encima del rango esperado.',
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: EventMetricKeys.k,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isCritical: false,
          metadata: {
            'source': 'event_engine',
            'group': 'npk',
            'value': input.k,
            'band': kBand.name,
            'excess': true,
          },
        ),
      );
    }

    if (_hasNutrientImbalance(nBand, pBand, kBand)) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.nutrientImbalance,
          severity: _nutrientImbalanceSeverity(nBand, pBand, kBand),
          title: 'Desbalance nutrimental',
          message:
              'Las lecturas NPK muestran desbalance respecto al rango esperado para el cultivo o la etapa.',
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: EventMetricKeys.npk,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isCritical: [nBand, pBand, kBand].contains(AgroBand.critical),
          metadata: {
            'source': 'event_engine',
            'group': 'npk',
            'nBand': nBand?.name,
            'pBand': pBand?.name,
            'kBand': kBand?.name,
          },
        ),
      );
    }

    // =========================================================
    // 7) TENDENCIA Y ESTADO COMBINADO
    // =========================================================
    final currentProblemCount = _countProblemMetrics(input.currentBands);
    final previousProblemCount = _countProblemMetrics(input.previousBands);

    if (_isStableSoil(input)) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.stableSoil,
          severity: AgronomicEventSeverity.info,
          title: 'Suelo estable',
          message:
              'Las métricas principales del suelo se han mantenido con buen comportamiento reciente.',
          timestamp: now,
          deviceId: input.deviceId,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isInformative: true,
          metadata: const {'source': 'event_engine', 'group': 'trend'},
        ),
      );
    }

    if (currentProblemCount >= input.rules.minProblemMetricsForCombinedStress) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.combinedStress,
          severity: currentProblemCount >= 3
              ? AgronomicEventSeverity.critical
              : AgronomicEventSeverity.warning,
          title: 'Estrés combinado',
          message:
              'Se detectan varias métricas fuera de rango al mismo tiempo. Conviene revisar el sistema de manera integral.',
          timestamp: now,
          deviceId: input.deviceId,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isCritical: currentProblemCount >= 3,
          metadata: {
            'source': 'event_engine',
            'group': 'trend',
            'problemCount': currentProblemCount,
          },
        ),
      );
    }

    if (previousProblemCount > currentProblemCount &&
        currentProblemCount <= input.rules.maxProblemMetricsForRecovery &&
        input.history.length >= input.rules.minRecoverySamples) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.recovery,
          severity: AgronomicEventSeverity.info,
          title: 'Recuperación',
          message:
              'El cultivo muestra señales de recuperación frente a lecturas recientes más comprometidas.',
          timestamp: now,
          deviceId: input.deviceId,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isInformative: true,
          metadata: {
            'source': 'event_engine',
            'group': 'trend',
            'previousProblemCount': previousProblemCount,
            'currentProblemCount': currentProblemCount,
          },
        ),
      );
    }

    // =========================================================
    // 8) AMBIENTE (aire)
    // =========================================================
    if (input.airTemp != null && input.airTemp! <= input.rules.frostThresholdC) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.frostWarning,
          severity: input.airTemp! <= 0
              ? AgronomicEventSeverity.critical
              : AgronomicEventSeverity.warning,
          title: 'Riesgo de helada',
          message: 'La temperatura ambiente es de ${_fmt(input.airTemp)}°C. '
              'Temperaturas cercanas o bajo cero pueden dañar tejidos vegetales y raíces superficiales.',
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: 'airTemp',
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isCritical: input.airTemp! <= 0,
          metadata: {
            'source': 'event_engine',
            'group': 'environment',
            'value': input.airTemp,
          },
        ),
      );
    } else if (input.airTemp != null &&
        input.airTemp! >= input.rules.highAirTempThresholdC) {
      final isCriticalAirTemp =
          input.airTemp! >= input.rules.criticalAirTempThresholdC;
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.highAirTemp,
          severity: isCriticalAirTemp
              ? AgronomicEventSeverity.critical
              : AgronomicEventSeverity.warning,
          title: 'Temperatura ambiente alta',
          message: _highAirTempMessage(input, isCriticalAirTemp),
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: 'airTemp',
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isCritical: isCriticalAirTemp,
          metadata: {
            'source': 'event_engine',
            'group': 'environment',
            'value': input.airTemp,
          },
        ),
      );
    }

    if (input.airHumidity != null &&
        input.airHumidity! <= input.rules.lowAirHumidityThresholdPct) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.lowAirHumidity,
          severity: AgronomicEventSeverity.caution,
          title: 'Humedad ambiente baja',
          message: 'La humedad relativa del aire es de ${_fmt(input.airHumidity)}%. '
              'Niveles bajos aceleran la evapotranspiración y pueden requerir más riego.',
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: 'airHumidity',
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          metadata: {
            'source': 'event_engine',
            'group': 'environment',
            'value': input.airHumidity,
          },
        ),
      );
    } else if (input.airHumidity != null &&
        input.airHumidity! >= input.rules.highAirHumidityThresholdPct) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.highAirHumidity,
          severity: AgronomicEventSeverity.caution,
          title: 'Humedad ambiente alta',
          message: _highAirHumidityMessage(input),
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: 'airHumidity',
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          metadata: {
            'source': 'event_engine',
            'group': 'environment',
            'value': input.airHumidity,
          },
        ),
      );
    }

    // =========================================================
    // 9) RECOMENDACIONES (eventos tipo recomendación)
    // =========================================================
    if (_shouldRecommendIrrigation(input, moistureBand)) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.irrigationRecommended,
          severity: moistureBand == AgroBand.critical
              ? AgronomicEventSeverity.critical
              : AgronomicEventSeverity.caution,
          title: 'Riego recomendado',
          message: _irrigationRecommendationMessage(input, moistureBand),
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: EventMetricKeys.soilMoisture,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          metadata: {
            'source': 'event_engine',
            'group': 'recommendation',
            'value': input.soilMoisture,
            'band': moistureBand?.name,
          },
        ),
      );
    }

    if (_shouldRecommendFertilization(input, nBand, pBand, kBand)) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.fertilizationRecommended,
          severity: [nBand, pBand, kBand].contains(AgroBand.critical)
              ? AgronomicEventSeverity.warning
              : AgronomicEventSeverity.caution,
          title: _isLettuce(input) ||
                  _isSpinach(input) ||
                  _isOnion(input) ||
                  _isGarlic(input)
              ? 'Revisión nutricional'
              : 'Fertilización recomendada',
          message: _fertilizationRecommendationMessage(input, nBand, pBand, kBand),
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: EventMetricKeys.npk,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          metadata: {
            'source': 'event_engine',
            'group': 'recommendation',
            'nBand': nBand?.name,
            'pBand': pBand?.name,
            'kBand': kBand?.name,
          },
        ),
      );
    }

    // =========================================================
    // LIMPIEZA FINAL
    // =========================================================
    return _dedupeAndSort(events);
  }

  static bool _hasStageTransition(EventEngineInput input) {
    final prev = input.previousStageLabel?.trim();
    final curr = input.stageLabel?.trim();

    if (prev == null || prev.isEmpty) return false;
    if (curr == null || curr.isEmpty) return false;
    return prev != curr;
  }

  static bool _isStableMetric({
    required List<EventTelemetryPoint> history,
    required double? Function(EventTelemetryPoint point) selector,
    required AgroBand currentBand,
    required double tolerance,
    required int minSamples,
  }) {
    if (currentBand != AgroBand.optimal) return false;

    final values = history
        .map(selector)
        .whereType<double>()
        .toList(growable: false);

    if (values.length < minSamples) return false;

    final range = values.reduce(math.max) - values.reduce(math.min);
    return range <= tolerance;
  }

  static bool _hasNutrientImbalance(
    AgroBand? nBand,
    AgroBand? pBand,
    AgroBand? kBand,
  ) {
    // `unknown` significa "no hay dato", no "hay problema".
    //
    // `whereType<AgroBand>()` filtra los null pero NO los `unknown`, y como
    // `unknown != optimal`, dos nutrientes ausentes bastaban para emitir
    // "Desbalance nutrimental" sobre sensores que no reportaron nada.
    final bands = [nBand, pBand, kBand]
        .whereType<AgroBand>()
        .where((b) => b != AgroBand.unknown)
        .toList();
    if (bands.isEmpty) return false;

    final problemCount = bands.where((b) => b != AgroBand.optimal).length;
    return problemCount >= 2 || bands.contains(AgroBand.critical);
  }

  static AgronomicEventSeverity _nutrientImbalanceSeverity(
    AgroBand? nBand,
    AgroBand? pBand,
    AgroBand? kBand,
  ) {
    final bands = [nBand, pBand, kBand];
    if (bands.contains(AgroBand.critical)) {
      return AgronomicEventSeverity.warning;
    }
    return AgronomicEventSeverity.caution;
  }

  static int _countProblemMetrics(Map<String, AgroBand> bands) {
    return bands.values.where((band) {
      return band == AgroBand.low ||
          band == AgroBand.high ||
          band == AgroBand.critical;
    }).length;
  }

  static bool _isStableSoil(EventEngineInput input) {
    if (input.history.length < input.rules.minStableSamples) return false;

    final optimalCount = input.currentBands.values
        .where((b) => b == AgroBand.optimal)
        .length;

    if (optimalCount < input.rules.minOptimalMetricsForStableSoil) {
      return false;
    }

    final moistureOk =
        _rangeOf(
          input.history.map((e) => e.soilMoisture).whereType<double>(),
        ) <=
        input.rules.moistureStableTolerance;

    final phOk =
        _rangeOf(input.history.map((e) => e.ph).whereType<double>()) <=
        input.rules.phStableTolerance;

    final tempOk =
        _rangeOf(input.history.map((e) => e.soilTemp).whereType<double>()) <=
        input.rules.soilTempStableTolerance;

    return moistureOk && phOk && tempOk;
  }

  static bool _shouldRecommendIrrigation(
    EventEngineInput input,
    AgroBand? moistureBand,
  ) {
    if (input.isGenericMode) return false;
    if (moistureBand == null) return false;
    return moistureBand == AgroBand.low || moistureBand == AgroBand.critical;
  }

  static bool _shouldRecommendFertilization(
    EventEngineInput input,
    AgroBand? nBand,
    AgroBand? pBand,
    AgroBand? kBand,
  ) {
    if (input.isGenericMode) return false;

    final bands = [nBand, pBand, kBand].whereType<AgroBand>().toList();
    if (bands.isEmpty) return false;

    final badCount = bands.where((b) => b.isLowish || b.isHighish).length;
    return badCount >= 1;
  }

  static String _highAirTempMessage(
    EventEngineInput input,
    bool isCriticalAirTemp,
  ) {
    final value = _fmt(input.airTemp);
    if (_isLettuce(input)) {
      final stage = input.stageLabel?.trim();
      final stageText = stage != null && stage.isNotEmpty ? ' en $stage' : '';
      if (isCriticalAirTemp) {
        return 'La temperatura ambiente es de ${value}°C. Para lechuga$stageText '
            'esto puede acelerar espigado, amargor y pérdida de calidad; revisa '
            'sombra, ventilación, riego y oportunidad de cosecha.';
      }
      return 'La temperatura ambiente es de ${value}°C. La lechuga$stageText '
          'empieza a salir de su rango fresco; vigila turgencia y tallo central.';
    }
    if (_isSpinach(input)) {
      final stage = input.stageLabel?.trim();
      final stageText = stage != null && stage.isNotEmpty ? ' en $stage' : '';
      if (isCriticalAirTemp) {
        return 'La temperatura ambiente es de ${value} C. Para espinaca$stageText '
            'esto puede disparar espigado y perdida de calidad de hoja; revisa '
            'riego, sombra, ventilacion y oportunidad de corte.';
      }
      return 'La temperatura ambiente es de ${value} C. La espinaca$stageText '
          'empieza a salir de su rango fresco; vigila turgencia, tallo central '
          'y avance de cosecha.';
    }
    if (_isOnion(input)) {
      final stage = input.stageLabel?.trim();
      final stageText = stage != null && stage.isNotEmpty ? ' en $stage' : '';
      if (isCriticalAirTemp) {
        return 'La temperatura ambiente es de ${value} C. Para cebolla$stageText '
            'el calor fuerte puede acelerar madurez y dejar bulbos mas chicos; '
            'manten humedad estable y vigila avance de cuello.';
      }
      return 'La temperatura ambiente es de ${value} C. La cebolla$stageText '
          'empieza a salir de su rango; el calor en induccion/llenado reduce '
          'calibre, asi que cuida el agua de la zona de raiz.';
    }
    if (_isGarlic(input)) {
      final stage = input.stageLabel?.trim();
      final stageText = stage != null && stage.isNotEmpty ? ' en $stage' : '';
      if (isCriticalAirTemp) {
        return 'La temperatura ambiente es de ${value} C. Para ajo$stageText '
            'el calor fuerte puede acelerar madurez, reducir calibre y complicar '
            'curado; no se corrige con fertilizante si falto frio.';
      }
      return 'La temperatura ambiente es de ${value} C. El ajo$stageText '
          'empieza a salir de su rango; cuida agua estable, CE y avance de bulbo.';
    }

    return 'La temperatura ambiente es de ${value}°C. '
        'El calor extremo puede provocar estrés hídrico y reducir la fotosíntesis.';
  }

  static String _highAirHumidityMessage(EventEngineInput input) {
    final value = _fmt(input.airHumidity);
    if (_isLettuce(input)) {
      return 'La humedad relativa del aire es de $value%. En lechuga, la HR alta '
          'favorece mildiu velloso, Botrytis, tip burn y pudriciones si hay '
          'mojado foliar o poca ventilación.';
    }

    if (_isSpinach(input)) {
      return 'La humedad relativa del aire es de $value%. En espinaca, la HR alta '
          'favorece mildiu, Botrytis y manchas foliares; revisa enves, dosel '
          'mojado y ventilacion porque la hoja es el producto comercial.';
    }

    if (_isOnion(input)) {
      return 'La humedad relativa del aire es de $value%. En cebolla, la HR alta '
          'con hoja mojada favorece mildiu, Botrytis, mancha purpura y '
          'pudriciones de cuello; revisa hojas, cuello y curado del bulbo.';
    }

    if (_isGarlic(input)) {
      return 'La humedad relativa del aire es de $value%. En ajo, la HR alta '
          'con hoja o cuello mojado favorece roya, mildiu, Botrytis y pudriciones; '
          'revisa hojas, cuello, bulbo, curado y almacenamiento.';
    }

    return 'La humedad relativa del aire es de $value%. '
        'Niveles altos favorecen enfermedades fúngicas y dificultan la transpiración.';
  }

  static String _irrigationRecommendationMessage(
    EventEngineInput input,
    AgroBand? moistureBand,
  ) {
    final stage = input.stageLabel?.trim();
    final value = input.soilMoisture != null
        ? ' (${_fmt(input.soilMoisture)}%)'
        : '';

    if (_isLettuce(input)) {
      final stageText = stage != null && stage.isNotEmpty
          ? ' en $stage'
          : '';
      if (moistureBand == AgroBand.critical) {
        return 'La humedad$value está en déficit crítico para lechuga$stageText. '
            'Conviene revisar riego hoy: la pérdida de turgencia puede traer '
            'amargor, estrés y espigado.';
      }
      return 'La humedad$value sugiere ajustar riego para mantener estable la '
          'lechuga$stageText. Evita secados fuertes y encharcamientos: ambos '
          'pegan directo en calidad de hoja.';
    }

    if (_isSpinach(input)) {
      final stageText = stage != null && stage.isNotEmpty
          ? ' en $stage'
          : '';
      if (moistureBand == AgroBand.critical) {
        return 'La humedad$value esta en deficit critico para espinaca$stageText. '
            'Conviene revisar riego hoy: la hoja pierde turgencia y el estres '
            'puede parecer falta de nutriente.';
      }
      return 'La humedad$value sugiere estabilizar riego en espinaca$stageText. '
          'Evita secados fuertes y saturacion: ambos reducen calidad de hoja y '
          'pueden favorecer espigado o pudriciones.';
    }

    if (_isOnion(input)) {
      final stageText = stage != null && stage.isNotEmpty
          ? ' en $stage'
          : '';
      if (moistureBand == AgroBand.critical) {
        return 'La humedad$value esta en deficit critico para cebolla$stageText. '
            'En induccion/llenado el agua define calibre; la cebolla no siempre '
            'se marchita, asi que revisa la zona de raiz (10-30 cm) hoy.';
      }
      return 'La humedad$value sugiere estabilizar riego en cebolla$stageText. '
          'Evita deficit en bulbo y saturacion del cuello: el exceso sube '
          'pudriciones y retrasa el curado.';
    }

    if (_isGarlic(input)) {
      final stageText = stage != null && stage.isNotEmpty
          ? ' en $stage'
          : '';
      if (moistureBand == AgroBand.critical) {
        return 'La humedad$value esta en deficit critico para ajo$stageText. '
            'En diferenciacion y llenado baja calibre y dientes; revisa raiz y '
            'humedad sin confundir estres hidrico con falta de nutriente.';
      }
      return 'La humedad$value sugiere estabilizar riego en ajo$stageText. '
          'Evita deficit en bulbo y exceso de humedad/anoxia: ambos reducen '
          'calibre y el exceso favorece pudriciones y mal curado.';
    }

    if (stage != null && stage.isNotEmpty) {
      if (_containsAny(stage.toLowerCase(), const <String>['flor', 'cuaj', 'vaina', 'espig', 'antes', 'llenado'])) {
        return 'La humedad$value sugiere proteger la etapa $stage. Conviene revisar riego hoy y evitar oscilaciones bruscas de humedad.';
      }
      if (_containsAny(stage.toLowerCase(), const <String>['germin', 'emerg'])) {
        return 'La humedad$value sugiere revisar un riego ligero o la retención superficial. En $stage conviene evitar tanto secado como encharcamiento.';
      }
      return 'La humedad$value sugiere revisar riego o disponibilidad de agua para mantener estable la etapa $stage.';
    }

    return 'La lectura de humedad$value sugiere que conviene revisar riego o disponibilidad de agua.';
  }

  static String _fertilizationRecommendationMessage(
    EventEngineInput input,
    AgroBand? nBand,
    AgroBand? pBand,
    AgroBand? kBand,
  ) {
    final stage = input.stageLabel?.trim();
    final shortages = <String>[];
    final excesses = <String>[];

    void pushMetric(String label, AgroBand? band) {
      if (band == null) return;
      if (band.isLowish) shortages.add(label);
      if (band.isHighish) excesses.add(label);
    }

    pushMetric('N', nBand);
    pushMetric('P', pBand);
    pushMetric('K', kBand);

    final issueText = [
      if (shortages.isNotEmpty) 'bajos en ${shortages.join('/')}',
      if (excesses.isNotEmpty) 'altos en ${excesses.join('/')}',
    ].join(' y ');

    if (_isLettuce(input)) {
      final stageText = stage != null && stage.isNotEmpty
          ? ' en $stage'
          : '';
      final issue = issueText.isEmpty
          ? 'un desbalance posible de NPK'
          : 'niveles $issueText';
      return 'Las lecturas muestran $issue$stageText. En lechuga BIO-G v1 '
          'lo interpreta como riesgo de desequilibrio, no como receta de '
          'dosis: revisa historial, humedad, pH, CE y calidad de hoja antes '
          'de ajustar el manejo.';
    }
    if (_isSpinach(input)) {
      final stageText = stage != null && stage.isNotEmpty
          ? ' en $stage'
          : '';
      final issue = issueText.isEmpty
          ? 'un desbalance posible de NPK'
          : 'niveles $issueText';
      return 'Las lecturas muestran $issue$stageText. En espinaca BIO-G v1 '
          'lo interpreta como riesgo de desequilibrio, no como receta de dosis: '
          'confirma humedad estable, pH, CE y calidad de hoja antes de ajustar.';
    }

    if (_isOnion(input)) {
      final stageText = stage != null && stage.isNotEmpty
          ? ' en $stage'
          : '';
      final issue = issueText.isEmpty
          ? 'un desbalance posible de NPK'
          : 'niveles $issueText';
      return 'Las lecturas muestran $issue$stageText. En cebolla BIO-G v1 '
          'lo interpreta como riesgo de desequilibrio, no como receta de dosis: '
          'recuerda que el N tardio engruesa cuello y el fotoperiodo manda la '
          'bulbificacion. Confirma agua, CE, etapa y maduracion antes de ajustar.';
    }

    if (_isGarlic(input)) {
      final stageText = stage != null && stage.isNotEmpty
          ? ' en $stage'
          : '';
      final issue = issueText.isEmpty
          ? 'un desbalance posible de NPK'
          : 'niveles $issueText';
      return 'Las lecturas muestran $issue$stageText. En ajo BIO-G v1 '
          'lo interpreta como riesgo de desequilibrio, no como receta de dosis: '
          'N tardio puede favorecer escobeteado/canutos, mala maduracion y mal '
          'curado; la vernalizacion no se corrige con fertilizante. Confirma '
          'agua, CE, etapa, diente-semilla y sanidad antes de ajustar.';
    }

    if (stage != null && stage.isNotEmpty) {
      if (_containsAny(stage.toLowerCase(), const <String>['germin', 'emerg', 'tempr', 'macoll', 'veg'])) {
        return issueText.isEmpty
            ? 'Las lecturas nutrimentales sugieren revisar fertilización de arranque o nutrición vegetativa en $stage.'
            : 'Las lecturas nutrimentales muestran niveles $issueText. Conviene revisar fertilización de arranque o nutrición vegetativa en $stage.';
      }
      if (_containsAny(stage.toLowerCase(), const <String>['flor', 'cuaj', 'vaina', 'espig', 'antes', 'llenado'])) {
        return issueText.isEmpty
            ? 'Las lecturas nutrimentales sugieren revisar nutrición de soporte para $stage y evitar estrés durante esta fase crítica.'
            : 'Las lecturas nutrimentales muestran niveles $issueText. Conviene ajustar la estrategia nutricional para sostener $stage.';
      }
      return issueText.isEmpty
          ? 'Las lecturas nutrimentales sugieren revisar fertilización o estrategia de nutrición para $stage.'
          : 'Las lecturas nutrimentales muestran niveles $issueText. Conviene revisar fertilización o estrategia de nutrición para $stage.';
    }

    return issueText.isEmpty
        ? 'Las lecturas nutrimentales sugieren revisar fertilización o estrategia de nutrición.'
        : 'Las lecturas nutrimentales muestran niveles $issueText. Conviene revisar fertilización o estrategia de nutrición.';
  }

  static bool _containsAny(String value, List<String> patterns) {
    for (final pattern in patterns) {
      if (value.contains(pattern)) return true;
    }
    return false;
  }

  static bool _isLettuce(EventEngineInput input) {
    final cropId = input.cropId?.trim().toLowerCase();
    if (cropId == 'lettuce' || cropId == 'crop_lettuce') return true;

    final seedAlias = input.seedAlias?.trim().toLowerCase() ?? '';
    return seedAlias.contains('lechuga') || seedAlias.contains('lettuce');
  }

  static bool _isSpinach(EventEngineInput input) {
    final cropId = input.cropId?.trim().toLowerCase();
    if (cropId == 'spinach' || cropId == 'crop_spinach' || cropId == 'espinaca') {
      return true;
    }

    final seedAlias = input.seedAlias?.trim().toLowerCase() ?? '';
    return seedAlias.contains('espinaca') || seedAlias.contains('spinach');
  }

  static bool _isOnion(EventEngineInput input) {
    final cropId = input.cropId?.trim().toLowerCase();
    if (cropId == 'onion' || cropId == 'crop_onion' || cropId == 'cebolla') {
      return true;
    }

    final seedAlias = input.seedAlias?.trim().toLowerCase() ?? '';
    return seedAlias.contains('cebolla') || seedAlias.contains('onion');
  }

  static bool _isGarlic(EventEngineInput input) {
    final cropId = input.cropId?.trim().toLowerCase();
    if (cropId == 'garlic' || cropId == 'crop_garlic' || cropId == 'ajo') {
      return true;
    }

    final seedAlias = input.seedAlias?.trim().toLowerCase() ?? '';
    return seedAlias.contains('ajo') || seedAlias.contains('garlic');
  }

  static List<AgronomicEvent> _dedupeAndSort(List<AgronomicEvent> events) {
    final seen = <String>{};
    final deduped = <AgronomicEvent>[];

    for (final event in events) {
      final key = [
        event.type.name,
        event.severity.name,
        event.title,
        event.message,
        event.metricKey ?? '',
        event.stageKey ?? '',
        event.stageLabel ?? '',
      ].join('|');

      if (seen.add(key)) {
        deduped.add(event);
      }
    }

    deduped.sort((a, b) {
      final severityCmp = b.severity.rank.compareTo(a.severity.rank);
      if (severityCmp != 0) return severityCmp;
      return b.timestamp.compareTo(a.timestamp);
    });

    return deduped;
  }

  static double _rangeOf(Iterable<double> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) return 999999;
    return list.reduce(math.max) - list.reduce(math.min);
  }

  static String _fmt(double? value) {
    if (value == null) return '--';
    final rounded = value.toStringAsFixed(1);
    if (rounded.endsWith('.0')) {
      return rounded.substring(0, rounded.length - 2);
    }
    return rounded;
  }

  static String _buildNpkInline(EventEngineInput input) {
    final chunks = <String>[];

    if (input.n != null) chunks.add('N ${_fmt(input.n)}');
    if (input.p != null) chunks.add('P ${_fmt(input.p)}');
    if (input.k != null) chunks.add('K ${_fmt(input.k)}');

    if (chunks.isEmpty) return '';
    return ' (${chunks.join(' · ')} mg/kg)';
  }
}

/// ============================================================
/// INPUT NORMALIZADO DEL MOTOR
/// ============================================================

class EventEngineInput {
  const EventEngineInput({
    required this.timestamp,
    this.deviceId,
    this.cropId,
    this.seedProfileId,
    this.seedAlias,
    this.sowingDate,
    this.isGenericMode = false,
    this.stageKey,
    this.stageLabel,
    this.previousStageKey,
    this.previousStageLabel,
    this.soilMoisture,
    this.ph,
    this.resistance,
    this.soilTemp,
    this.airTemp,
    this.airHumidity,
    this.n,
    this.p,
    this.k,
    this.currentBands = const <String, AgroBand>{},
    this.previousBands = const <String, AgroBand>{},
    this.excessNutrientKeys = const <String>{},
    this.history = const <EventTelemetryPoint>[],
    this.rules = const EventEngineRules(),
  });

  final DateTime timestamp;

  final String? deviceId;
  final String? cropId;
  final String? seedProfileId;
  final String? seedAlias;
  final DateTime? sowingDate;

  final bool isGenericMode;

  final String? stageKey;
  final String? stageLabel;

  /// Opcional: ayuda a detectar cambios de etapa.
  final String? previousStageKey;
  final String? previousStageLabel;

  final double? soilMoisture;
  final double? ph;
  final double? resistance;
  final double? soilTemp;
  final double? airTemp;
  final double? airHumidity;
  final double? n;
  final double? p;
  final double? k;

  /// Bandas actuales ya calculadas por AgroScoreEngine o capa superior.
  ///
  /// Keys sugeridas:
  /// - EventMetricKeys.soilMoisture
  /// - EventMetricKeys.ph
  /// - EventMetricKeys.resistance
  /// - EventMetricKeys.soilTemp
  /// - EventMetricKeys.n
  /// - EventMetricKeys.p
  /// - EventMetricKeys.k
  final Map<String, AgroBand> currentBands;

  /// Bandas previas opcionales. Útiles para recovery.
  final Map<String, AgroBand> previousBands;

  /// Nutrientes cuya banda es por exceso (no por déficit).
  /// Keys: EventMetricKeys.n / .p / .k
  final Set<String> excessNutrientKeys;

  /// Historial ya normalizado.
  final List<EventTelemetryPoint> history;

  /// Reglas de sensibilidad del motor.
  final EventEngineRules rules;

  AgroBand? bandOf(String key) => currentBands[key];

  bool get hasAnyNpk => n != null || p != null || k != null;
}

/// ============================================================
/// PUNTO DE HISTORIAL NORMALIZADO
/// ============================================================

class EventTelemetryPoint {
  const EventTelemetryPoint({
    required this.timestamp,
    this.soilMoisture,
    this.ph,
    this.resistance,
    this.soilTemp,
    this.n,
    this.p,
    this.k,
  });

  final DateTime timestamp;
  final double? soilMoisture;
  final double? ph;
  final double? resistance;
  final double? soilTemp;
  final double? n;
  final double? p;
  final double? k;
}

/// ============================================================
/// REGLAS DEL MOTOR
/// ============================================================

class EventEngineRules {
  const EventEngineRules({
    this.minStableSamples = 4,
    this.minRecoverySamples = 4,
    this.minOptimalMetricsForStableSoil = 3,
    this.minProblemMetricsForCombinedStress = 2,
    this.maxProblemMetricsForRecovery = 1,
    this.moistureStableTolerance = 6.0,
    this.phStableTolerance = 0.35,
    this.soilTempStableTolerance = 3.5,
    this.goodStructureMaxResistance = 35.0,
    this.frostThresholdC = 4.0,
    this.highAirTempThresholdC = 38.0,
    this.criticalAirTempThresholdC = 42.0,
    this.lowAirHumidityThresholdPct = 20.0,
    this.highAirHumidityThresholdPct = 90.0,
  });

  /// Cuántas muestras mínimas pedimos para declarar estabilidad.
  final int minStableSamples;

  /// Cuántas muestras mínimas pedimos para declarar recuperación.
  final int minRecoverySamples;

  /// Cuántas métricas deben estar óptimas para decir "suelo estable".
  final int minOptimalMetricsForStableSoil;

  /// Cuántas métricas problemáticas al mismo tiempo cuentan como estrés combinado.
  final int minProblemMetricsForCombinedStress;

  /// Para declarar recovery, cuántas métricas problemáticas máximas debe haber ahora.
  final int maxProblemMetricsForRecovery;

  /// Tolerancias de estabilidad.
  final double moistureStableTolerance;
  final double phStableTolerance;
  final double soilTempStableTolerance;

  /// Heurística simple de "estructura cómoda".
  final double goodStructureMaxResistance;

  /// Umbrales de ambiente.
  final double frostThresholdC;
  final double highAirTempThresholdC;
  final double criticalAirTempThresholdC;
  final double lowAirHumidityThresholdPct;
  final double highAirHumidityThresholdPct;
}

/// ============================================================
/// KEYS DE MÉTRICAS
/// ============================================================

abstract final class EventMetricKeys {
  static const soilMoisture = 'soilMoisture';
  static const ph = 'ph';
  static const resistance = 'resistance';
  static const soilTemp = 'soilTemp';
  static const n = 'n';
  static const p = 'p';
  static const k = 'k';
  static const npk = 'npk';
}

/// ============================================================
/// EXTENSIONS
/// ============================================================

extension _AgroBandEventX on AgroBand {
  bool get isLowish => this == AgroBand.low || this == AgroBand.critical;

  bool get isHighish => this == AgroBand.high || this == AgroBand.critical;

  AgronomicEventSeverity toSeverity({required bool isLow}) {
    switch (this) {
      case AgroBand.critical:
        return AgronomicEventSeverity.critical;
      case AgroBand.low:
      case AgroBand.high:
        return AgronomicEventSeverity.warning;
      case AgroBand.optimal:
        return AgronomicEventSeverity.info;
      case AgroBand.unknown:
        return AgronomicEventSeverity.info;
    }
  }
}

extension _AgronomicSeverityRankX on AgronomicEventSeverity {
  int get rank {
    switch (this) {
      case AgronomicEventSeverity.info:
        return 0;
      case AgronomicEventSeverity.caution:
        return 1;
      case AgronomicEventSeverity.warning:
        return 2;
      case AgronomicEventSeverity.critical:
        return 3;
    }
  }
}
