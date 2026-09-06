// lib/core/agro/event_engine.dart

import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';

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
                // Describe el estado, no ordena regar: la orden de riego es
                // competencia exclusiva de IrrigationEngine.
                ? 'La humedad de suelo está baja (${_fmt(input.soilMoisture)}%). Conviene revisar la retención de humedad del suelo.'
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
    // 5b) CONDUCTIVIDAD ELÉCTRICA (sales)
    // =========================================================
    //
    // La CE es la señal física que sustituye a las bandas NPK: se juzga como
    // salinidad de la zona radicular, nunca como «falta o sobra fertilizante»
    // (Guía v0.4, §2 y §8). La banda viene del motor de score del cultivo.
    final ecBand = input.bandOf(EventMetricKeys.ec);
    if (ecBand != null && ecBand.isHighish) {
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.highSalinity,
          severity: ecBand.toSeverity(isLow: false),
          title: 'Sales altas en el suelo',
          message: input.ec != null
              ? 'La conductividad eléctrica del suelo está alta (${_fmt(input.ec)} mS/cm). '
                    'Si se sostiene, conviene revisar la calidad del agua de riego '
                    'y dar una lámina de lavado antes de cualquier aporte.'
              : 'La conductividad eléctrica del suelo está por encima del rango '
                    'esperado para esta etapa.',
          timestamp: now,
          deviceId: input.deviceId,
          metricKey: EventMetricKeys.ec,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: input.stageKey,
          stageLabel: input.stageLabel,
          isCritical: ecBand == AgroBand.critical,
          metadata: {
            'source': 'event_engine',
            'group': 'ec',
            'value': input.ec,
            'band': ecBand.name,
          },
        ),
      );
    }

    // =========================================================
    // 6) NUTRICIÓN
    // =========================================================
    //
    // Este motor NO interpreta N/P/K. La sonda 7-en-1 deriva esos canales de la
    // CE y no puede sostener «bajo/alto» (Guía v0.4, §2). La única lectura
    // nutrimental que se emite es la constancia de la señal nativa; el juicio
    // agronómico llega ya tomado en [EventEngineInput.nutritionDecision], igual
    // que el riego llega en [EventEngineInput.irrigationDecision].
    if (!input.isGenericMode && input.hasAnyNpk) {
      final String trendSummary = input.nutritionDecision?.trendSummaryEs ?? '';
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.npkReading,
          severity: AgronomicEventSeverity.info,
          title: 'Lectura N/P/K registrada',
          message:
              'La sonda registró N, P y K${_buildNpkInline(input)}.'
              '${trendSummary.isEmpty ? '' : ' Últimos 7 días: $trendSummary.'}'
              ' $kNativeSignalDisclaimerEs.',
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
            'nativeSignal': true,
          },
        ),
      );
    }

    events.addAll(_nutritionEvents(input));

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
    if (_shouldRecommendIrrigation(input)) {
      // No nulo por construccion: _shouldRecommendIrrigation ya exigio que la
      // decision existiera y que su accion fuera regar.
      final IrrigationDecision decision = input.irrigationDecision!;
      events.add(
        AgronomicEvent(
          type: AgronomicEventType.irrigationRecommended,
          // La urgencia la gradua el motor de riego, no la banda de humedad.
          // Una banda critica con lluvia encima no es una urgencia critica.
          severity:
              decision.urgency == IrrigationUrgency.critical ||
                  decision.urgency == IrrigationUrgency.high
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
            // Trazabilidad: deja constancia de que este aviso proviene de una
            // decision del motor de riego y de cual.
            'decisionAction': decision.action.name,
            'decisionUrgency': decision.urgency.name,
            'engineVersion': decision.engineVersion,
          },
        ),
      );
    }

    // =========================================================
    // LIMPIEZA FINAL
    // =========================================================
    return _dedupeAndSort(events);
  }

  /// Convierte la decisión del motor de nutrición en eventos. No decide nada:
  /// traduce (Guía v0.4, §9 y fase 8).
  static List<AgronomicEvent> _nutritionEvents(EventEngineInput input) {
    if (input.isGenericMode) return const <AgronomicEvent>[];
    final NutritionDecision? d = input.nutritionDecision;
    if (d == null) return const <AgronomicEvent>[];

    final now = input.timestamp;
    final out = <AgronomicEvent>[];
    final Map<String, Object?> trace = <String, Object?>{
      'source': 'event_engine',
      'group': 'nutrition',
      'decisionState': d.state.name,
      'engineVersion': d.engineVersion,
      'windowOutcome': d.window?.outcome.name,
      'awaitingEvidence': d.awaitingEvidence,
      'scoreFactor': d.scoreFactor,
    };

    switch (d.state) {
      case NutritionState.actionWindow:
        // El título es el de la recomendación —«Aplica nitrógeno: segunda
        // fertilización (V6–V8)»— y el mensaje abre con la dosis orientativa.
        final NutritionRecommendation? rec = d.recommendation;
        out.add(
          AgronomicEvent(
            type: AgronomicEventType.fertilizationRecommended,
            severity: (d.window?.isCritical ?? false)
                ? AgronomicEventSeverity.warning
                : AgronomicEventSeverity.caution,
            title: rec?.headlineEs ?? d.headlineEs,
            message: rec?.detailEs ?? d.detailEs,
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.npk,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            metadata: <String, Object?>{
              ...trace,
              'nutrient': rec?.nutrient.name,
              'nutrients': rec?.allNutrients.map((k) => k.name).toList(),
              'windowLabel': rec?.windowLabelEs,
              'hasDose': rec?.hasDose ?? false,
              'doses': rec?.doses.map((dose) => dose.lineEs).toList(),
              'guideAudit': d.guideAudit.name,
            },
          ),
        );
      case NutritionState.responseWindow:
        out.add(
          AgronomicEvent(
            type: AgronomicEventType.nutritionResponseDetected,
            severity: AgronomicEventSeverity.info,
            title: 'Respuesta compatible con fertilización detectada',
            message: d.detailEs,
            timestamp: now,
            deviceId: input.deviceId,
            metricKey: EventMetricKeys.npk,
            seedProfileId: input.seedProfileId,
            seedAlias: input.seedAlias,
            stageKey: input.stageKey,
            stageLabel: input.stageLabel,
            isInformative: true,
            metadata: <String, Object?>{
              ...trace,
              'confidence01': d.signature?.confidence01,
              'signatureKind': d.signature?.kind.name,
              'detectedAt': d.signature?.startedAt.toUtc().toIso8601String(),
            },
          ),
        );
      case NutritionState.prepare:
        if (d.upcomingWindowInDays != null && d.recommendation != null) {
          out.add(
            AgronomicEvent(
              type: AgronomicEventType.nutritionUpcomingWindow,
              severity: AgronomicEventSeverity.info,
              title: d.recommendation!.headlineEs,
              message: d.recommendation!.detailEs,
              timestamp: now,
              deviceId: input.deviceId,
              metricKey: EventMetricKeys.npk,
              seedProfileId: input.seedProfileId,
              seedAlias: input.seedAlias,
              stageKey: input.stageKey,
              stageLabel: input.stageLabel,
              isInformative: true,
              metadata: <String, Object?>{
                ...trace,
                'inDays': d.upcomingWindowInDays,
                'nextStage': d.upcomingWindowLabelEs,
              },
            ),
          );
        } else if (d.awaitingEvidence) {
          // Ventana abierta pero el suelo no permite aplicar todavía: es una
          // recomendación de preparación, no de aplicación.
          out.add(
            AgronomicEvent(
              type: AgronomicEventType.fertilizationRecommended,
              severity: AgronomicEventSeverity.caution,
              title: d.headlineEs,
              message: d.detailEs,
              timestamp: now,
              deviceId: input.deviceId,
              metricKey: EventMetricKeys.npk,
              seedProfileId: input.seedProfileId,
              seedAlias: input.seedAlias,
              stageKey: input.stageKey,
              stageLabel: input.stageLabel,
              metadata: <String, Object?>{...trace, 'blockedByConditions': true},
            ),
          );
        }
      case NutritionState.monitor:
      case NutritionState.learning:
        break;
    }

    // Una ventana importante que TERMINÓ sin evidencia es el único hecho
    // nutrimental que pesa: se avisa una vez, con su porqué.
    final NutritionWindowRecord? unattended = d.recentlyUnattendedWindow;
    if (unattended != null) {
      final String windowName = NutritionRecommendation.windowNameFor(
        windowLabelEs: unattended.windowLabelEs,
        stageLabelEs: unattended.stageLabelEs,
      );
      final String who = NutritionRecommendation.joinNutrientsEs(
        unattended.nutrients,
      );
      out.add(
        AgronomicEvent(
          type: AgronomicEventType.nutritionWindowUnattended,
          severity: AgronomicEventSeverity.warning,
          title: 'Sin evidencia de fertilización: $windowName',
          message:
              'Esta ventana nutricional no mostró evidencia suficiente de haber '
              'sido atendida: la ventana «${unattended.displayLabelEs}» ($who) '
              'terminó sin que la sonda viera una respuesta compatible con '
              'fertilización. Pesa en el score histórico y en la proyección de este '
              'ciclo. No es una certeza de que no fertilizaste: el producto pudo '
              'quedar fuera del alcance de la sonda o llegar con poca agua.',
          timestamp: unattended.resolvedAt ?? now,
          deviceId: input.deviceId,
          metricKey: EventMetricKeys.npk,
          seedProfileId: input.seedProfileId,
          seedAlias: input.seedAlias,
          stageKey: unattended.stageKey,
          stageLabel: unattended.stageLabelEs,
          metadata: <String, Object?>{
            ...trace,
            'windowId': unattended.id,
            'nutrients': unattended.nutrients.map((k) => k.name).toList(),
            'observedFraction': unattended.observedFraction,
          },
        ),
      );
    }

    return out;
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

  /// El riego NO se decide aquí. Se consume la decisión de [IrrigationEngine].
  ///
  /// La versión anterior devolvía true con solo ver la banda de humedad en
  /// `low` o `critical`. Ese atajo ignoraba la lluvia pronosticada, la vigencia
  /// de la lectura y la confianza, así que podía ordenar riego justo cuando el
  /// motor había decidido esperar. Ver la nota de [EventEngineInput.irrigationDecision].
  static bool _shouldRecommendIrrigation(EventEngineInput input) {
    if (input.isGenericMode) return false;
    final IrrigationDecision? decision = input.irrigationDecision;
    if (decision == null) return false;
    return decision.action == IrrigationAction.regar;
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
    return ' (${chunks.join(' · ')})';
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
    this.ec,
    this.airTemp,
    this.airHumidity,
    this.n,
    this.p,
    this.k,
    this.currentBands = const <String, AgroBand>{},
    this.previousBands = const <String, AgroBand>{},
    this.history = const <EventTelemetryPoint>[],
    this.rules = const EventEngineRules(),
    this.irrigationDecision,
    this.nutritionDecision,
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

  /// Conductividad eléctrica del suelo en mS/cm (la única unidad de CE de la
  /// app, fijada en el contrato del sensor). Null si el canal no reportó.
  final double? ec;
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
  ///
  /// N/P/K ya no viajan como banda: son señal nativa sin interpretación
  /// (Guía v0.4, §2 y §8).
  final Map<String, AgroBand> currentBands;

  /// Bandas previas opcionales. Útiles para recovery.
  final Map<String, AgroBand> previousBands;

  /// Historial ya normalizado.
  final List<EventTelemetryPoint> history;

  /// Reglas de sensibilidad del motor.
  final EventEngineRules rules;

  /// Decisión ya tomada por [IrrigationEngine]. Autoridad única del riego.
  ///
  /// Este motor no tiene clima, ni pronóstico, ni vigencia de lectura, ni
  /// confianza: con solo la banda de humedad no puede saber si conviene regar.
  /// Antes lo deducía por su cuenta (`banda low o critical => riega`) y eso
  /// producía la contradicción que el agricultor veía: el Panel decía "espera,
  /// se espera lluvia" mientras el Historial y la campana decían "riego
  /// recomendado" por la misma lectura.
  ///
  /// Null significa "no hay decisión disponible": entonces no se emite consejo
  /// de riego. Callar es correcto; inventar una segunda verdad agronómica, no.
  final IrrigationDecision? irrigationDecision;

  /// Decisión ya tomada por el motor de nutrición. Autoridad única del manejo
  /// nutricional (Guía v0.4, §9).
  ///
  /// Este motor no conoce la etapa fenológica a fondo, ni la guía auditada, ni
  /// el libro de ventanas, ni la firma que el sensor detectó: con las lecturas
  /// crudas de N/P/K no puede —ni debe— deducir nada nutrimental. Null significa
  /// «no hay decisión disponible»: entonces no se emite ningún evento de
  /// nutrición. Callar es correcto; inventar una segunda verdad, no.
  final NutritionDecision? nutritionDecision;

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
  });

  final DateTime timestamp;
  final double? soilMoisture;
  final double? ph;
  final double? resistance;
  final double? soilTemp;
  // N/P/K no viajan aquí: el motor de eventos no lee nutrientes del
  // historial; la nutrición entra ya decidida en `EventEngineInput.nutritionDecision`.
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
  static const ec = 'ec';
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
