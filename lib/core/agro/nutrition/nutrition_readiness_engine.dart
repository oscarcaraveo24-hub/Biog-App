// lib/core/agro/nutrition/nutrition_readiness_engine.dart
//
// NUTRITION READINESS ENGINE — V1 (Guía oficial del nuevo motor nutricional
// v0.4, §9–§11, §35 fase 5) con detección automática de fertilización.
//
// La pregunta que responde: «¿Qué manejo nutricional corresponde ahora, y qué
// parece haber ocurrido en la zona radicular?».
//
// DE DÓNDE SALE CADA COSA
// -----------------------
//   Cultivo y etapa ............. runtime del cultivo (fenología ya resuelta)
//   Prioridades fenológicas ..... perfil (`StageTargets`) + modificador de variedad
//   Guía curada ................. `NutritionGuide` (fuentes, timing, 3R, rangos
//                                 en kg/ha; también en frutales)
//   Qué ocurrió ................. `FertilizationSignatureScanner` sobre la
//                                 telemetría (CE normalizada + N/P/K + VWC)
//   Memoria del ciclo ........... `NutritionWindowLedger` (ventanas atendidas /
//                                 sin evidencia / inconclusas)
//   Condiciones físicas ......... evaluación del suelo (bandas de humedad,
//                                 sales, temperatura, pH) con presencia
//
// LO QUE NUNCA HACE (Guía v0.4, §37): comparar N/P/K crudos contra un
// objetivo, declarar «bajo/alto», calcular déficit ni derivar una dosis de la
// sonda. Y NO acepta registros manuales de fertilización: la única fuente de
// «se atendió» es la firma que el sensor detecta.
//
// ESTADOS: LEARNING → MONITOR → PREPARE → ACTION WINDOW → RESPONSE WINDOW. El
// aprendizaje no bloquea: si hay una ventana abierta en la primera semana, la
// ventana manda y el aprendizaje se anota como matiz.
//
// COPY DEL FLUJO (decisión de producto, 6 sep 2026): nada de «esta etapa
// necesita nutrición». Cada titular nombra el nutriente y la ventana de la
// guía, y el detalle abre con la dosis orientativa:
//   «Aplica nitrógeno: segunda fertilización (V6–V8)»
//     → «Dosis orientativa (guía curada): N: 107–161 kg/ha (≈ 235–350 kg/ha
//        de urea). Momento: entre V6 y V8 … Cuando apliques no necesitas
//        registrar nada …»
//   «Prepara nitrógeno: segunda fertilización (V6–V8), todavía no apliques»
//   «Se acerca nitrógeno: amacollamiento (primer riego de auxilio)»
//   «Respuesta compatible con fertilización detectada» (frase oficial; la
//     ventana va en el detalle)
//   «Nutrición atendida: segunda fertilización (V6–V8)»
//   «Sin evidencia de fertilización: segunda fertilización (V6–V8)» (el
//     detalle conserva la frase oficial «esta ventana nutricional no mostró
//     evidencia suficiente de haber sido atendida»)
//   «Tendencia al alza en nitrógeno» / «Suelo estable, sin necesidades
//     nutrimentales por ahora» en seguimiento.
// Los titulares de recomendación se arman en `NutritionRecommendation.headlineFor`.
import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/fertilization_signature_scanner.dart';
import 'package:bio_g/core/agro/nutrition/fertilizer_products.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guide.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_variety_modifiers.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_window_ledger.dart';
import 'package:bio_g/core/agro/nutrition/site_learning.dart';
import 'package:bio_g/core/agro/soil_reaction.dart';
import 'package:bio_g/core/agro/traceability/engine_versions.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Todo lo que el motor necesita, ya resuelto. El motor es puro: no toca red,
/// disco ni reloj.
class NutritionReadinessInput {
  const NutritionReadinessInput({
    required this.now,
    required this.isPlanted,
    this.isGuideMode = false,
    this.isGenericMode = false,
    this.cropKey,
    this.cropLabel,
    this.stageKey,
    this.stageLabelEs,
    this.daysToStageEnd,
    this.stageProgress01,
    this.stageStartedAt,
    this.targets,
    this.nextStageKey,
    this.nextStageLabelEs,
    this.nextTargets,
    this.guide,
    this.live,
    this.eval,
    this.cultivationScaleId,
    this.profileId,
    this.varietyId,
    this.varietyAlias,
    this.calendarId,
    this.isPerennial = false,
    this.deviceId,
    this.seasonKey,
    this.epochId,
    this.windows = const <NutritionWindowRecord>[],
    this.history = const <BioGTelemetry>[],
    this.learning = SiteLearningStatus.unknown,
    this.compensateEcTemperature = false,
  });

  final DateTime now;
  final bool isPlanted;
  final bool isGuideMode;
  final bool isGenericMode;

  final String? cropKey;
  final String? cropLabel;
  final String? stageKey;
  final String? stageLabelEs;
  final int? daysToStageEnd;
  final double? stageProgress01;

  /// Inicio estimado de la etapa actual. Es desde cuándo se barre la ventana.
  final DateTime? stageStartedAt;

  final StageTargets? targets;

  /// Etapa siguiente, cuando el runtime puede anticiparla (anuales).
  final String? nextStageKey;
  final String? nextStageLabelEs;
  final StageTargets? nextTargets;

  final NutritionGuide? guide;

  final BioGTelemetry? live;
  final AgroEvalResult? eval;

  final String? cultivationScaleId;
  final String? profileId;
  final String? varietyId;
  final String? varietyAlias;
  final String? calendarId;

  /// Frutal. Informativo: la dosis de un frutal sale de su guía (plan anual
  /// de huerta × ventana), nunca de la cosecha esperada por árbol (decisión
  /// de producto, 6 sep 2026).
  final bool isPerennial;

  /// Identidad del sitio y del ciclo, para el libro de ventanas.
  final String? deviceId;
  final String? seasonKey;
  final String? epochId;

  /// Libro de ventanas de la temporada, tal como está persistido.
  final List<NutritionWindowRecord> windows;

  /// Telemetría disponible (idealmente todo el historial local).
  final List<BioGTelemetry> history;

  final SiteLearningStatus learning;

  /// Contrato del sensor: la CE llega sin compensar por temperatura.
  final bool compensateEcTemperature;
}

/// Salida del motor: la decisión y el libro de ventanas reconciliado.
class NutritionEvaluation {
  const NutritionEvaluation({
    required this.decision,
    required this.windows,
    required this.changedWindows,
  });

  final NutritionDecision decision;

  /// Libro completo de la temporada tras esta evaluación.
  final List<NutritionWindowRecord> windows;

  /// Filas que cambiaron y hay que persistir.
  final List<NutritionWindowRecord> changedWindows;
}

class NutritionReadinessEngine {
  const NutritionReadinessEngine._();

  /// Días de anticipación con los que una ventana próxima pasa a PREPARE.
  static const int upcomingWindowDays = 10;

  /// Tope de prioridad para un nutriente que la guía curada NO reparte en la
  /// etapa: justo debajo del umbral de ventana. Sigue pudiendo ser «media»
  /// (importa, se sigue la tendencia) pero nunca abre ventana ni penaliza.
  static const double kGuideCappedPriority01 =
      NutritionPriorityX.kHighPriorityThreshold01 - 0.01;

  /// Temperatura de suelo por debajo de la cual la actividad radicular y la
  /// mineralización se frenan: no bloquea, advierte.
  static const double coldSoilCautionC = 10.0;

  /// Por encima de esta razón contra lo habitual, la respuesta es «mayor».
  static const double greaterResponseRatio = 1.5;

  /// Por debajo de esta razón contra lo habitual, la respuesta es «menor».
  static const double minorResponseRatio = 0.6;

  static NutritionEvaluation? evaluate(NutritionReadinessInput input) {
    final String crop = (input.cropKey ?? '').trim().toLowerCase();
    if (!input.isPlanted || input.isGuideMode || input.isGenericMode) {
      return null;
    }
    if (crop.isEmpty) return null;

    final List<String> reasons = <String>[];
    final List<String> limitations = <String>[];
    final NutritionGuide? guide = input.guide;
    final GuideAuditStatus audit = guide?.auditStatus ?? GuideAuditStatus.pending;

    // ── 1. Prioridades fenológicas de la etapa ────────────────────────────
    final VarietyNutritionAdjustment variety = VarietyNutritionAdjustment.resolve(
      cropKey: crop,
      profileId: input.profileId,
      varietyId: input.varietyId,
      varietyAlias: input.varietyAlias,
      calendarId: input.calendarId,
    );
    final StageNutritionRule? rule = guide?.ruleForStage(input.stageKey);
    final List<NutrientStagePriority> priorities = _buildPriorities(
      input: input,
      rule: rule,
      variety: variety,
    );
    if (input.targets == null) {
      limitations.add(
        'Sin objetivos de etapa resueltos: las prioridades salen de valores '
        'neutros.',
      );
    }

    // ── 2. Condiciones físicas ───────────────────────────────────────────
    final NutritionConditionCheck conditions = _checkConditions(input);

    // ── 3. Ventana de la etapa y libro de ventanas ───────────────────────
    final List<NutrientStagePriority> windowCandidates = priorities
        .where((p) => p.priority == NutritionPriority.high)
        .toList();
    // La ventana se nombra y se dosifica en orden N, P, K, que es como el
    // agricultor lee una fórmula; la prioridad ordena las pantallas, no esto.
    final List<AgroMetricKey> windowNutrients = NutritionRecommendation.orderNpk(
      windowCandidates.map((NutrientStagePriority p) => p.nutrient),
    );
    final String seasonKey =
        input.seasonKey ?? '${input.deviceId ?? 'device'}|$crop|-';
    final String deviceId = input.deviceId ?? 'device';
    final String stageKey = StageNutritionRule.normalizeStageKey(input.stageKey);
    final String? guideWindowLabel =
        (rule != null && rule.windowNutrients.isNotEmpty) ? rule.labelEs : null;

    CurrentWindowSpec? spec;
    if (windowNutrients.isNotEmpty && stageKey.isNotEmpty) {
      spec = CurrentWindowSpec(
        stageKey: stageKey,
        stageLabelEs: input.stageLabelEs ?? input.stageKey ?? stageKey,
        nutrients: windowNutrients,
        isCritical: windowCandidates.any((p) => p.isCriticalWindow),
        startedAt: input.stageStartedAt ?? input.now,
        labelEs: guideWindowLabel,
      );
    }
    final String? currentId = spec == null
        ? null
        : NutritionWindowRecord.buildId(
            seasonKey: seasonKey,
            stageKey: spec.stageKey,
            nutrients: spec.nutrients,
          );
    final double? typical = NutritionWindowLedger.typicalEcPeakMad(
      input.windows,
      epochId: input.epochId,
      excludeWindowId: currentId,
    );

    final LedgerReconciliation ledger = NutritionWindowLedger.reconcile(
      records: input.windows,
      seasonKey: seasonKey,
      deviceId: deviceId,
      cropKey: crop,
      current: spec,
      now: input.now,
      learning: input.learning,
      epochId: input.epochId,
      scanner: ({required DateTime windowStart, DateTime? observeUntil}) {
        return FertilizationSignatureScanner.scan(
          SignatureScanRequest(
            history: input.history,
            windowStart: windowStart,
            now: input.now,
            observeUntil: observeUntil,
            siteTypicalEcPeakMad: typical,
            isLearningSite: input.learning.isLearning,
            compensateEcTemperature: input.compensateEcTemperature,
          ),
        );
      },
    );

    NutritionWindowRecord? window = ledger.current;
    final FertilizationSignatureScan? scan = ledger.currentScan;
    final List<NutritionWindowRecord> changed = <NutritionWindowRecord>[
      ...ledger.changed,
    ];

    final FertilizationSignature? signature = window?.signature;

    /// Firma COMPATIBLE que atendió la ventana (null si no la hay).
    final FertilizationSignature? detectedSignature =
        (window != null &&
                window.outcome == NutritionWindowOutcome.attendedDetected)
            ? signature
            : null;

    /// Firma «posible»: hay un cambio, pero aún no alcanza para atender.
    final FertilizationSignature? possibleSignature =
        (detectedSignature == null && signature != null && signature.isPossible)
            ? signature
            : null;
    final bool possible = possibleSignature != null;
    final bool following = detectedSignature != null &&
        detectedSignature.isFollowingResponseAt(input.now);

    // ── 4. Respuesta del sitio a la firma detectada ──────────────────────
    NutritionResponseEvaluation? response;
    if (detectedSignature != null) {
      response = _evaluateResponse(
        signature: detectedSignature,
        now: input.now,
        following: following,
        typical: typical,
      );
      if (response.verdict.isFinal &&
          window != null &&
          window.responseVerdict != response.verdict) {
        final NutritionWindowRecord updated = window.copyWith(
          responseVerdict: response.verdict,
        );
        window = updated;
        changed.removeWhere((NutritionWindowRecord r) => r.id == updated.id);
        changed.add(updated);
      }
    }

    // ── 5. Ventana próxima ───────────────────────────────────────────────
    // Solo cuando la etapa actual NO abre ventana: con una abierta (aunque el
    // suelo no deje aplicar) la próxima no debe desplazar su aviso.
    final _Upcoming? upcoming = spec == null
        ? _upcomingWindow(input, variety)
        : null;

    // ── 6. Estado ────────────────────────────────────────────────────────
    NutritionState state;
    NutrientStagePriority? focus;
    bool awaitingEvidence = false;

    final String windowName = window?.displayLabelEs ??
        input.stageLabelEs ??
        'esta etapa';
    if (detectedSignature != null && following) {
      state = NutritionState.responseWindow;
      reasons.add(
        'Firma compatible con fertilización detectada el '
        '${_fmtDate(detectedSignature.startedAt)} (confianza '
        '${detectedSignature.confidenceLabelEs}, '
        '${detectedSignature.kind.labelEs.toLowerCase()}); la ventana '
        '«$windowName» queda atendida y se sigue la respuesta hasta el '
        '${_fmtDate(detectedSignature.responseHorizonEndsAt)}.',
      );
    } else if (detectedSignature != null) {
      state = NutritionState.monitor;
      reasons.add(
        'La ventana «$windowName» fue atendida (firma del '
        '${_fmtDate(detectedSignature.startedAt)}); la respuesta ya se evaluó: '
        '${response?.verdict.labelEs ?? 'sin veredicto'}.',
      );
    } else if (spec != null) {
      focus = windowCandidates.first;
      awaitingEvidence = true;
      state = conditions.allowsApplication
          ? NutritionState.actionWindow
          : NutritionState.prepare;
      final String who = NutritionRecommendation.joinNutrientsEs(windowNutrients);
      reasons.add(
        guide != null && guideWindowLabel != null
            ? 'La guía de ${guide.cropLabelEs} abre la ventana '
                  '«$guideWindowLabel» de $who en «${spec.stageLabelEs}»'
                  '${spec.isCritical ? ' (ventana agronómicamente importante)' : ''}; '
                  'el sensor observa la respuesta del suelo desde el '
                  '${_fmtDate(spec.startedAt)}.'
            : 'La etapa «${spec.stageLabelEs}» tiene prioridad alta de $who '
                  '(${focus.labelEs.toLowerCase()}: ${_pct(focus.priority01)})'
                  '${spec.isCritical ? ', ventana agronómicamente importante' : ''}; '
                  'el sensor observa la respuesta del suelo desde el '
                  '${_fmtDate(spec.startedAt)}.',
      );
      if (possibleSignature != null) {
        reasons.add(
          'Hay un cambio en la zona de raíces que podría ser una fertilización '
          '(confianza ${possibleSignature.confidenceLabelEs}); se necesita que '
          'se sostenga para confirmarlo.',
        );
      }
      if (!conditions.allowsApplication) {
        reasons.add(
          'Las condiciones físicas no permiten aplicar todavía: '
          '${conditions.blockersEs.join(' ')}',
        );
      }
    } else if (upcoming != null) {
      state = NutritionState.prepare;
      reasons.add(
        'Se acerca la ventana «${upcoming.windowNameEs}» de '
        '${NutritionRecommendation.joinNutrientsEs(upcoming.nutrients)} '
        '(etapa «${upcoming.stageLabelEs}») en ~${upcoming.inDays} días.',
      );
    } else if (input.learning.isLearning) {
      state = NutritionState.learning;
      reasons.add(
        'Sitio en aprendizaje inicial (día ${input.learning.daysSinceStart + 1} '
        'de ${SiteLearningStatus.learningDays}).',
      );
    } else {
      state = NutritionState.monitor;
      if (guide != null && rule != null) {
        final String why = (rule.rationaleEs ?? '').trim();
        reasons.add(
          'La guía de ${guide.cropLabelEs} no abre ventana en '
          '«${rule.labelEs ?? input.stageLabelEs ?? input.stageKey}»'
          '${why.isEmpty ? '.' : ': ${_lowerFirst(why)}'}',
        );
      } else {
        reasons.add('Sin ventana nutricional relevante en la etapa actual.');
      }
    }

    // ── 7. Memoria del ciclo: lo único que puede pesar en el score ───────
    final int unattended = NutritionWindowLedger.unattendedCriticalCount(
      ledger.records,
    );
    final double scoreFactor = NutritionWindowLedger.seasonScoreFactor(
      ledger.records,
    );
    final NutritionWindowRecord? recentlyUnattended =
        NutritionWindowLedger.recentlyUnattended(ledger.records, input.now);
    if (unattended > 0) {
      reasons.add(
        '$unattended ventana${unattended == 1 ? '' : 's'} importante'
        '${unattended == 1 ? '' : 's'} del ciclo terminó sin evidencia '
        'suficiente de haber sido atendida: factor ${scoreFactor.toStringAsFixed(2)} '
        'sobre el estado general y la proyección.',
      );
    }
    for (final NutritionWindowRecord r in ledger.justResolved) {
      reasons.add(
        'Ventana «${r.displayLabelEs}» (${r.nutrientsLabelEs}) cerrada: '
        '${r.outcome.labelEs.toLowerCase()}.',
      );
    }

    // ── 8. Recomendación ─────────────────────────────────────────────────
    NutritionRecommendation? recommendation;
    if (focus != null && spec != null) {
      recommendation = _buildRecommendation(
        input: input,
        nutrients: windowNutrients,
        priorities: priorities,
        rule: rule,
        guide: guide,
        variety: variety,
        conditions: conditions,
        limitations: limitations,
        possible: possibleSignature,
        windowLabelEs: guideWindowLabel,
        stageLabelEs: spec.stageLabelEs,
      );
    } else if (state == NutritionState.prepare && upcoming != null) {
      recommendation = _buildUpcomingRecommendation(
        input: input,
        upcoming: upcoming,
        guide: guide,
        limitations: limitations,
      );
    }

    if (guide == null) {
      limitations.add(
        'Sin guía curada para este cultivo: la prioridad sale del perfil '
        'fenológico y no se emiten rangos de dosis.',
      );
    } else if (!audit.canShowDose) {
      limitations.add(
        'La guía de ${guide.cropLabelEs} está pendiente: los rangos de dosis '
        'no se muestran hasta que se cure cultivo por cultivo.',
      );
    } else if (rule == null) {
      limitations.add(
        'La guía de ${guide.cropLabelEs} no contempla la etapa '
        '«${input.stageLabelEs ?? input.stageKey}»: no se abre ventana y el '
        'perfil fenológico solo aporta el matiz de prioridad.',
      );
    }
    if (scan != null && !scan.observability.isOk) {
      limitations.add('Observación de la ventana: ${scan.observability.labelEs}.');
    } else if (scan != null && scan.observedFraction < FertilizationSignatureScanner.minObservedFraction) {
      limitations.add(
        'Cobertura de lecturas en la ventana: ${(scan.observedFraction * 100).round()} %; '
        'con huecos así el cierre sería inconcluso, no «sin evidencia».',
      );
    }
    if (input.history.isEmpty) {
      limitations.add(
        'Sin historial de telemetría: no se puede observar la respuesta del '
        'suelo a una fertilización.',
      );
    }
    limitations.addAll(conditions.cautionsEs);

    // ── 9. Copy de la tarjeta ────────────────────────────────────────────
    final NutritionWindowRecord? finalWindow = window;
    final List<NutritionWindowRecord> records = <NutritionWindowRecord>[
      for (final NutritionWindowRecord r in ledger.records)
        if (finalWindow != null && r.id == finalWindow.id) finalWindow else r,
    ];

    // ── 9. Tendencia de los canales nativos (única lectura de N/P/K) ────
    final List<NutrientTrend> trends = nativeTrends(input.history, input.now);

    final ({String headline, String detail}) copy = _copyFor(
      state: state,
      input: input,
      focus: focus,
      recommendation: recommendation,
      response: response,
      signature: signature,
      window: window,
      conditions: conditions,
      priorities: priorities,
      trends: trends,
      upcoming: upcoming,
      possible: possible,
      recentlyUnattended: recentlyUnattended,
      guide: guide,
      rule: rule,
    );

    final NutritionDecision decision = NutritionDecision(
      state: state,
      decidedAt: input.now,
      headlineEs: copy.headline,
      detailEs: copy.detail,
      cropKey: crop,
      cropLabel: input.cropLabel,
      stageKey: input.stageKey,
      stageLabelEs: input.stageLabelEs,
      priorities: priorities,
      recommendation: recommendation,
      conditions: conditions,
      response: response,
      window: window,
      seasonWindows: List<NutritionWindowRecord>.unmodifiable(records),
      awaitingEvidence: awaitingEvidence,
      unattendedCriticalWindows: unattended,
      scoreFactor: scoreFactor,
      recentlyUnattendedWindow: recentlyUnattended,
      isLearningSite: input.learning.isLearning,
      learningDaysLeft: input.learning.isLearning
          ? input.learning.daysLeft
          : null,
      upcomingWindowLabelEs: upcoming?.stageLabelEs,
      upcomingWindowInDays: upcoming?.inDays,
      trends: List<NutrientTrend>.unmodifiable(trends),
      reasons: List<String>.unmodifiable(reasons),
      limitations: List<String>.unmodifiable(limitations),
      guideAudit: audit,
      engineVersion: BioGEngineVersions.nutrition,
    );

    return NutritionEvaluation(
      decision: decision,
      windows: List<NutritionWindowRecord>.unmodifiable(records),
      changedWindows: List<NutritionWindowRecord>.unmodifiable(changed),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TENDENCIAS NATIVAS
  // ═════════════════════════════════════════════════════════════════════════

  /// Tendencia de 7 días de N, P y K a partir del historial, en ese orden.
  /// Solo entran lecturas con bandera de presencia: un canal ausente no
  /// fabrica un cero (Guía v0.4, §37.9).
  static List<NutrientTrend> nativeTrends(
    List<BioGTelemetry> history,
    DateTime now,
  ) {
    List<({DateTime at, double value})> pick(
      bool Function(BioGTelemetry) has,
      num Function(BioGTelemetry) value,
    ) => <({DateTime at, double value})>[
      for (final BioGTelemetry t in history)
        if (has(t)) (at: t.timestamp, value: value(t).toDouble()),
    ];
    return <NutrientTrend>[
      NutrientTrend.compute(
        nutrient: AgroMetricKey.n,
        samples: pick((t) => t.hasNitrogenData, (t) => t.n),
        now: now,
      ),
      NutrientTrend.compute(
        nutrient: AgroMetricKey.p,
        samples: pick((t) => t.hasPhosphorusData, (t) => t.p),
        now: now,
      ),
      NutrientTrend.compute(
        nutrient: AgroMetricKey.k,
        samples: pick((t) => t.hasPotassiumData, (t) => t.k),
        now: now,
      ),
    ];
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PRIORIDADES
  // ═════════════════════════════════════════════════════════════════════════

  /// Prioridad por nutriente en la etapa, con la regla de autoridad:
  ///
  ///   · CON guía curada, SOLO sus reglas abren ventanas. Un nutriente que la
  ///     regla reparte queda al menos en prioridad alta (y es «importante»
  ///     solo si la regla lo dice); uno que la regla no reparte se queda por
  ///     debajo del umbral de ventana aunque el perfil heredado lo marque
  ///     alto. Sin esto, el perfil abría ventanas que la guía no contempla
  ///     (K en llenado de cebada, N en espigamiento de trigo o avena…) y las
  ///     sentenciaba «sin evidencia» contra el productor.
  ///   · SIN guía, manda el perfil fenológico tal cual (con modificador de
  ///     variedad), como hasta ahora.
  static List<NutrientStagePriority> _buildPriorities({
    required NutritionReadinessInput input,
    required StageNutritionRule? rule,
    required VarietyNutritionAdjustment variety,
  }) {
    final StageTargets? targets = input.targets;
    final bool guideDecides = input.guide != null;
    final List<NutrientStagePriority> out = <NutrientStagePriority>[];

    for (final AgroMetricKey key in const <AgroMetricKey>[
      AgroMetricKey.n,
      AgroMetricKey.p,
      AgroMetricKey.k,
    ]) {
      final double base = targets?.resolvedPriorityFor(key) ?? 0.5;
      final double adjusted = variety
          .adjustPriority(base, key, input.stageKey)
          .clamp(0.0, 1.0);
      final bool ruleOpens = rule?.windowNutrients.contains(key) ?? false;

      final double effective;
      final bool critical;
      if (guideDecides) {
        if (ruleOpens) {
          effective = math.max(
            adjusted,
            NutritionPriorityX.kHighPriorityThreshold01,
          );
          critical = rule?.isCritical ?? false;
        } else {
          effective = math.min(adjusted, kGuideCappedPriority01);
          critical = false;
        }
      } else {
        effective = adjusted;
        critical = effective >= NutritionPriorityX.kCriticalPriorityThreshold01;
      }
      final NutritionPriority level = NutritionPriorityX.fromPriority01(
        effective,
      );

      final String window =
          (ruleOpens ? rule?.labelEs : null) ??
          targets?.windowLabelFor(key) ??
          _defaultWindowLabel(key, level);
      final String rationale =
          (ruleOpens ? rule?.rationaleEs : null) ??
          targets?.shortGuidanceFor(key) ??
          _defaultRationale(key, level, input.stageLabelEs);

      out.add(
        NutrientStagePriority(
          nutrient: key,
          priority: level,
          priority01: effective,
          windowLabelEs: window,
          rationaleEs: rationale,
          guidanceEs: targets?.shortGuidanceFor(key),
          isCriticalWindow: critical,
        ),
      );
    }

    out.sort((a, b) {
      final int byLevel = b.priority.rank.compareTo(a.priority.rank);
      if (byLevel != 0) return byLevel;
      return b.priority01.compareTo(a.priority01);
    });
    return out;
  }

  static String _defaultWindowLabel(AgroMetricKey key, NutritionPriority p) {
    final String n = key.labelEs.toLowerCase();
    return switch (p) {
      NutritionPriority.high => 'Alta demanda de $n',
      NutritionPriority.medium => 'Demanda moderada de $n',
      NutritionPriority.low => 'Baja demanda de $n',
    };
  }

  static String _defaultRationale(
    AgroMetricKey key,
    NutritionPriority p,
    String? stageLabel,
  ) {
    final String n = key.labelEs.toLowerCase();
    final String stage = stageLabel == null ? 'esta etapa' : '«$stageLabel»';
    return switch (p) {
      NutritionPriority.high =>
        'En $stage el cultivo toma $n con fuerza: es el momento en que una '
            'aplicación rinde más.',
      NutritionPriority.medium =>
        'En $stage el $n acompaña el crecimiento sin ser el factor limitante.',
      NutritionPriority.low =>
        'En $stage el cultivo usa poco $n; aplicar ahora rinde poco.',
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  // RESPUESTA DEL SITIO
  // ═════════════════════════════════════════════════════════════════════════

  static NutritionResponseEvaluation _evaluateResponse({
    required FertilizationSignature signature,
    required DateTime now,
    required bool following,
    required double? typical,
  }) {
    final int days = math.max(0, now.difference(signature.startedAt).inDays);
    final List<String> evidence = <String>[
      ...signature.evidenceEs,
      if (typical != null)
        _compareWithTypicalEs(signature.ecPeakMad, typical),
    ];

    if (following) {
      final int left = math.max(
        0,
        signature.responseHorizonEndsAt.difference(now).inDays,
      );
      return NutritionResponseEvaluation(
        verdict: ResponseVerdict.pending,
        signature: signature,
        daysSinceDetection: days,
        typicalEcPeakMad: typical,
        evidenceEs: evidence,
        summaryEs:
            'Estoy observando la respuesta del suelo. Las sales de la zona de '
            'raíces subieron de forma compatible con una fertilización '
            '(${signature.kind.labelEs.toLowerCase()}, confianza '
            '${signature.confidenceLabelEs}); la observación sigue '
            '${left <= 0 ? 'unas horas más' : left == 1 ? 'un día más' : '$left días más'} '
            'para conocer la magnitud completa. No hace falta que registres nada.',
      );
    }

    if (typical == null || typical <= 0) {
      return NutritionResponseEvaluation(
        verdict: ResponseVerdict.compatible,
        signature: signature,
        daysSinceDetection: days,
        typicalEcPeakMad: null,
        evidenceEs: evidence,
        summaryEs:
            'Respuesta compatible con fertilización detectada. Este sitio aún no '
            'tiene suficientes ventanas anteriores para decir si la magnitud fue '
            'la habitual; con las próximas, BIO-G podrá compararla.',
      );
    }

    final double ratio = signature.ecPeakMad / typical;
    if (ratio >= greaterResponseRatio) {
      return NutritionResponseEvaluation(
        verdict: ResponseVerdict.greater,
        signature: signature,
        daysSinceDetection: days,
        typicalEcPeakMad: typical,
        evidenceEs: evidence,
        summaryEs:
            'La respuesta fue mayor de lo habitual en este sitio. Puede deberse '
            'a la dosis, al agua, a la distribución o a otras condiciones; no se '
            'atribuye una causa automáticamente.',
      );
    }
    if (ratio <= minorResponseRatio) {
      return NutritionResponseEvaluation(
        verdict: ResponseVerdict.minor,
        signature: signature,
        daysSinceDetection: days,
        typicalEcPeakMad: typical,
        evidenceEs: evidence,
        summaryEs:
            'La respuesta observada fue menor de lo habitual en este sitio. '
            'Revisa distribución del agua, ubicación de la sonda respecto a la '
            'aplicación y condiciones del suelo.',
      );
    }
    return NutritionResponseEvaluation(
      verdict: ResponseVerdict.compatible,
      signature: signature,
      daysSinceDetection: days,
      typicalEcPeakMad: typical,
      evidenceEs: evidence,
      summaryEs:
          'Respuesta compatible con fertilización detectada, con una magnitud '
          'dentro de lo habitual para este sitio.',
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // VENTANA PRÓXIMA
  // ═════════════════════════════════════════════════════════════════════════

  /// Ventana que abre la SIGUIENTE etapa, si el runtime la anticipó y falta
  /// poco. Con guía curada solo cuentan sus reglas (misma autoridad que en
  /// la etapa actual); sin guía, el perfil de la etapa siguiente.
  static _Upcoming? _upcomingWindow(
    NutritionReadinessInput input,
    VarietyNutritionAdjustment variety,
  ) {
    final int? days = input.daysToStageEnd;
    if (days == null || days > upcomingWindowDays) return null;
    final String? nextStageKey = input.nextStageKey;
    if (nextStageKey == null || nextStageKey.trim().isEmpty) return null;
    final String nextLabel = input.nextStageLabelEs ?? nextStageKey;

    final NutritionGuide? guide = input.guide;
    if (guide != null) {
      final StageNutritionRule? next = guide.ruleForStage(nextStageKey);
      // La misma regla cubre varias etapas (V6–V8 = vegEarly + vegMid): si la
      // etapa siguiente cae en la regla actual, no es una ventana nueva.
      if (next == null ||
          next.windowNutrients.isEmpty ||
          next.matchesStage(input.stageKey)) {
        return null;
      }
      final List<AgroMetricKey> nutrients = NutritionRecommendation.orderNpk(
        next.windowNutrients,
      );
      final AgroMetricKey first = nutrients.first;
      return _Upcoming(
        nutrients: nutrients,
        rule: next,
        stageKey: nextStageKey,
        stageLabelEs: nextLabel,
        inDays: math.max(1, days),
        priority: NutrientStagePriority(
          nutrient: first,
          priority: NutritionPriority.high,
          priority01: NutritionPriorityX.kHighPriorityThreshold01,
          windowLabelEs:
              next.labelEs ?? _defaultWindowLabel(first, NutritionPriority.high),
          rationaleEs: next.rationaleEs ?? '',
          isCriticalWindow: next.isCritical,
        ),
      );
    }

    // Sin guía: el perfil de la etapa siguiente, todos los nutrientes altos.
    final StageTargets? next = input.nextTargets;
    if (next == null) return null;
    NutrientStagePriority? best;
    final List<AgroMetricKey> high = <AgroMetricKey>[];
    for (final AgroMetricKey key in const <AgroMetricKey>[
      AgroMetricKey.n,
      AgroMetricKey.p,
      AgroMetricKey.k,
    ]) {
      final double p = variety
          .adjustPriority(next.resolvedPriorityFor(key), key, nextStageKey)
          .clamp(0.0, 1.0);
      if (p < NutritionPriorityX.kHighPriorityThreshold01) continue;
      high.add(key);
      if (best == null || p > best.priority01) {
        best = NutrientStagePriority(
          nutrient: key,
          priority: NutritionPriority.high,
          priority01: p,
          windowLabelEs:
              next.windowLabelFor(key) ??
              _defaultWindowLabel(key, NutritionPriority.high),
          rationaleEs: next.shortGuidanceFor(key) ?? '',
          isCriticalWindow: p >= NutritionPriorityX.kCriticalPriorityThreshold01,
        );
      }
    }
    if (best == null) return null;
    return _Upcoming(
      nutrients: high,
      rule: null,
      stageKey: nextStageKey,
      stageLabelEs: nextLabel,
      inDays: math.max(1, days),
      priority: best,
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // CONDICIONES FÍSICAS
  // ═════════════════════════════════════════════════════════════════════════

  static NutritionConditionCheck _checkConditions(NutritionReadinessInput input) {
    final BioGTelemetry? t = input.live;
    final AgroEvalResult? eval = input.eval;
    if (t == null) return NutritionConditionCheck.unknown;

    final List<String> blockers = <String>[];
    final List<String> cautions = <String>[];
    int evaluated = 0;

    final AgroMetricEval? moisture = eval?.metrics[AgroMetricKey.soilMoisture];
    if (t.hasSoilMoistureData && moisture != null && moisture.band.isKnown) {
      evaluated++;
      final double vwc = t.soilMoisturePct;
      if (moisture.band == AgroBand.critical) {
        final bool wet = vwc > (input.targets?.moistureRaw.optimalMax ?? 35.0);
        if (wet) {
          blockers.add(
            'El suelo está saturado (${vwc.toStringAsFixed(0)} % de humedad): '
            'aplicar ahora arriesga lavado y pérdida del producto.',
          );
        } else {
          blockers.add(
            'El suelo está muy seco (${vwc.toStringAsFixed(0)} % de humedad): '
            'sin agua el fertilizante no se mueve a la raíz. Riega primero.',
          );
        }
      } else if (moisture.band == AgroBand.low) {
        cautions.add(
          'Humedad baja (${vwc.toStringAsFixed(0)} %): aplica junto con un riego '
          'o justo antes de uno para que el producto llegue a la raíz.',
        );
      } else if (moisture.band == AgroBand.high) {
        cautions.add(
          'Humedad alta (${vwc.toStringAsFixed(0)} %): evita dosis fuertes '
          'hasta que drene; una parte se perdería por lavado.',
        );
      }
    } else if (t.hasSoilMoistureData && vwcBelowGate(t)) {
      evaluated++;
      blockers.add(
        'El suelo está muy seco (${t.soilMoisturePct.toStringAsFixed(0)} % de '
        'humedad): sin agua el fertilizante no se mueve a la raíz.',
      );
    }

    final AgroMetricEval? ec = eval?.metrics[AgroMetricKey.ec];
    if (t.hasEcData && ec != null && ec.band.isKnown) {
      evaluated++;
      final double ecOptMax = input.targets?.ec.optimalMax ?? 2.0;
      final bool high = t.ec > ecOptMax;
      if (ec.band == AgroBand.critical && high) {
        blockers.add(
          'Sales altas (CE ${t.ec.toStringAsFixed(1)} mS/cm): agregar más '
          'fertilizante empeora la salinidad. Baja la CE con riego antes.',
        );
      } else if (ec.band == AgroBand.high) {
        cautions.add(
          'CE en zona alta (${t.ec.toStringAsFixed(1)} mS/cm): prefiere fuentes '
          'de bajo índice salino y dosis partidas.',
        );
      }
    }

    if (t.hasSoilTempData) {
      evaluated++;
      if (t.soilTempC < coldSoilCautionC) {
        cautions.add(
          'Suelo frío (${t.soilTempC.toStringAsFixed(0)} °C): la raíz toma poco '
          'y la urea tarda en transformarse. Espera a que suba la temperatura '
          'si puedes, o usa una fuente nítrica.',
        );
      }
    }

    if (t.hasPhData) {
      evaluated++;
      final SoilReaction reaction = soilReactionFromPh(t.ph);
      if (reaction == SoilReaction.calcareous) {
        cautions.add(
          'pH ${t.ph.toStringAsFixed(1)}: suelo calcáreo. El fósforo se fija '
          'con el calcio (colócalo cerca de la raíz) y la urea al voleo pierde '
          'amoniaco al aire (incorpórala o riega después).',
        );
      } else if (reaction == SoilReaction.acidic && t.ph < 5.5) {
        cautions.add(
          'pH ${t.ph.toStringAsFixed(1)}: suelo ácido. La disponibilidad de '
          'fósforo baja y puede haber toxicidad por aluminio; revisa encalado '
          'con tu asesor antes de subir dosis.',
        );
      }
    }

    if (t.hasResistanceData) evaluated++;

    return NutritionConditionCheck(
      allowsApplication: blockers.isEmpty,
      blockersEs: List<String>.unmodifiable(blockers),
      cautionsEs: List<String>.unmodifiable(cautions),
      evaluatedSignals: evaluated,
    );
  }

  static bool vwcBelowGate(BioGTelemetry t) =>
      t.hasSoilMoistureData &&
      t.soilMoisturePct < FertilizationSignatureScanner.vwcHardGatePct;

  // ═════════════════════════════════════════════════════════════════════════
  // RECOMENDACIÓN
  // ═════════════════════════════════════════════════════════════════════════

  /// Recomendación de la ventana ABIERTA: todos sus nutrientes (orden N, P,
  /// K), cada uno con su rango orientativo si la guía lo sostiene, y un
  /// titular que nombra nutriente y ventana. La dosis nace de cultivo +
  /// etapa + guía (también en frutales: plan anual de huerta), nunca de la
  /// sonda ni de la cosecha esperada por árbol.
  static NutritionRecommendation _buildRecommendation({
    required NutritionReadinessInput input,
    required List<AgroMetricKey> nutrients,
    required List<NutrientStagePriority> priorities,
    required StageNutritionRule? rule,
    required NutritionGuide? guide,
    required VarietyNutritionAdjustment variety,
    required NutritionConditionCheck conditions,
    required List<String> limitations,
    FertilizationSignature? possible,
    String? windowLabelEs,
    String? stageLabelEs,
  }) {
    final GuideAuditStatus audit = guide?.auditStatus ?? GuideAuditStatus.pending;
    final AgroMetricKey primary = nutrients.first;

    // ── Dosis por nutriente ────────────────────────────────────────────────
    final List<NutrientDose> doses = <NutrientDose>[];
    final List<String> noDoseReasons = <String>[];
    for (final AgroMetricKey nutrient in nutrients) {
      final _DoseLookup d = _doseFor(
        input: input,
        nutrient: nutrient,
        stageKey: input.stageKey,
        rule: rule,
        guide: guide,
        limitations: limitations,
      );
      if (d.range != null) {
        doses.add(NutrientDose(nutrient: nutrient, range: d.range!));
      } else if (d.reasonEs != null) {
        noDoseReasons.add(d.reasonEs!);
      }
    }
    // Acompañamiento: nutrientes que la guía reparte en esta etapa sin
    // abrirles ventana (fertirriego de fondo). Se dosifican, no se observan.
    final List<NutrientDose> companions = <NutrientDose>[];
    for (final AgroMetricKey nutrient in _companionNutrients(rule, nutrients)) {
      final _DoseLookup d = _doseFor(
        input: input,
        nutrient: nutrient,
        stageKey: input.stageKey,
        rule: rule,
        guide: guide,
        limitations: limitations,
      );
      if (d.range != null) {
        companions.add(NutrientDose(nutrient: nutrient, range: d.range!));
      }
    }
    NutritionDoseRange? primaryDose;
    for (final NutrientDose d in doses) {
      if (d.nutrient == primary) {
        primaryDose = d.range;
        break;
      }
    }

    // ── Fuentes y reglas 3R ────────────────────────────────────────────────
    final List<String> sources = <String>[];
    for (final AgroMetricKey nutrient in <AgroMetricKey>[
      ...nutrients,
      for (final NutrientDose c in companions) c.nutrient,
    ]) {
      final List<String> forNutrient =
          guide?.sourceOptionsEs[nutrient] ?? const <String>[];
      sources.addAll(forNutrient.isEmpty ? _defaultSources(nutrient) : forNutrient);
    }

    final List<String> rules = <String>[
      ...(rule?.rulesEs ?? const <String>[]),
      ...(guide?.generalRulesEs ?? const <String>[]),
    ];
    for (final AgroMetricKey nutrient in nutrients) {
      final String? caution = variety.cautionFor(nutrient, input.stageKey);
      if (caution != null) rules.add(caution);
    }
    final BioGTelemetry? t = input.live;
    if (t != null && t.hasPhData) {
      final SoilReaction reaction = soilReactionFromPh(t.ph);
      for (final AgroMetricKey nutrient in nutrients) {
        final String? urea = ureaVolatilizationWarningEs(
          nutrient: nutrient,
          reaction: reaction,
          ph: t.ph,
        );
        if (urea != null) rules.add(urea);
        final String? pNote = soilReactionNoteEs(
          nutrient: nutrient,
          reaction: reaction,
          ph: t.ph,
        );
        if (pNote != null) rules.add(pNote);
      }
    }
    rules.addAll(conditions.cautionsEs);

    // ── Copy ───────────────────────────────────────────────────────────────
    final NutritionRecommendationKind kind = conditions.allowsApplication
        ? NutritionRecommendationKind.apply
        : NutritionRecommendationKind.prepare;
    // Un nutriente cuyo plan admite «puede no hacer falta» (mínimo 0) no va
    // en el titular si hay otros firmes: «Aplica nitrógeno y fósforo» y el
    // potasio condicionado se explica en la dosis.
    final List<AgroMetricKey> firm = <AgroMetricKey>[
      for (final AgroMetricKey n in nutrients)
        if (!doses.any((NutrientDose d) => d.nutrient == n && d.range.isConditional))
          n,
    ];
    final String headline = NutritionRecommendation.headlineFor(
      kind: kind,
      nutrients: firm.isEmpty ? nutrients : firm,
      windowLabelEs: windowLabelEs,
      stageLabelEs: stageLabelEs,
    );

    final String? rationale = _windowRationale(rule, priorities, primary);
    final String crop = input.cropLabel ?? guide?.cropLabelEs ?? 'El cultivo';
    final String stage = stageLabelEs ?? input.stageLabelEs ?? 'esta etapa';
    final String qualifier = audit.canShowDose
        ? (audit == GuideAuditStatus.audited ? 'guía auditada' : 'guía curada')
        : 'guía';

    final StringBuffer detail = StringBuffer();
    // 1. Lo que el productor necesita primero: qué y cuánto.
    if (doses.isNotEmpty) {
      detail.write(
        'Dosis orientativa ($qualifier): '
        '${doses.map((NutrientDose d) => d.lineEs).join('; ')}.',
      );
    }
    if (noDoseReasons.isNotEmpty) {
      if (detail.isNotEmpty) detail.write(' ');
      detail.write(_dedupe(noDoseReasons).join(' '));
    }
    if (companions.isNotEmpty) {
      detail.write(
        ' Acompaña con: '
        '${companions.map((NutrientDose d) => d.lineEs).join('; ')}.',
      );
    }
    // 2. Cuándo, dentro de la ventana.
    final String? timing = rule?.timingEs?.trim();
    if (timing != null && timing.isNotEmpty) {
      detail.write(' Momento: ${_lowerFirst(timing)}');
      if (!timing.endsWith('.')) detail.write('.');
    }
    // 3. Por qué (agronomía de la guía o del perfil).
    if (rationale != null && rationale.isNotEmpty) {
      detail.write(' $crop en «$stage»: ${_lowerFirst(rationale)}');
      if (!rationale.endsWith('.')) detail.write('.');
    }
    // 4. Lo que impide aplicar hoy.
    if (!conditions.allowsApplication) {
      detail.write(' Todavía no apliques: ${conditions.blockersEs.join(' ')}');
    }
    // 5. Qué hace BIO-G mientras tanto.
    if (possible != null) {
      detail.write(
        ' Estoy observando la respuesta del suelo: hay un cambio en la zona '
        'radicular que podría corresponder a una fertilización; necesito que se '
        'sostenga unas horas más para confirmarlo.',
      );
    } else {
      detail.write(
        ' Cuando apliques no necesitas registrar nada: BIO-G observa la '
        'respuesta del suelo para reconocer cuándo se atendió esta ventana.',
      );
    }

    return NutritionRecommendation(
      nutrient: primary,
      kind: kind,
      nutrients: List<AgroMetricKey>.unmodifiable(nutrients),
      headlineEs: headline,
      detailEs: detail.toString().trim(),
      audit: audit,
      doseRange: primaryDose,
      doses: List<NutrientDose>.unmodifiable(<NutrientDose>[...doses, ...companions]),
      doseUnavailableReasonEs: doses.isEmpty && noDoseReasons.isNotEmpty
          ? _dedupe(noDoseReasons).join(' ')
          : null,
      sourceOptionsEs: List<String>.unmodifiable(_dedupe(sources)),
      rulesEs: List<String>.unmodifiable(_dedupe(rules)),
      timingEs: rule?.timingEs,
      windowLabelEs: windowLabelEs,
      stageLabelEs: stageLabelEs,
      cropLabelEs: input.cropLabel ?? guide?.cropLabelEs,
    );
  }

  /// Recomendación de la ventana que SE ACERCA: mismo nutriente, ventana y
  /// dosis que tendrá al abrir, en tono de preparación. Sin días en el
  /// titular (cambiaría cada día y repetiría avisos); los días van en el
  /// detalle.
  static NutritionRecommendation _buildUpcomingRecommendation({
    required NutritionReadinessInput input,
    required _Upcoming upcoming,
    required NutritionGuide? guide,
    required List<String> limitations,
  }) {
    final GuideAuditStatus audit = guide?.auditStatus ?? GuideAuditStatus.pending;
    final List<NutrientDose> doses = <NutrientDose>[];
    final List<NutrientDose> companions = <NutrientDose>[];
    for (final AgroMetricKey nutrient in <AgroMetricKey>[
      ...upcoming.nutrients,
      ..._companionNutrients(upcoming.rule, upcoming.nutrients),
    ]) {
      final _DoseLookup d = _doseFor(
        input: input,
        nutrient: nutrient,
        stageKey: upcoming.stageKey,
        rule: upcoming.rule,
        guide: guide,
        limitations: limitations,
      );
      if (d.range == null) continue;
      final NutrientDose dose = NutrientDose(nutrient: nutrient, range: d.range!);
      if (upcoming.nutrients.contains(nutrient)) {
        doses.add(dose);
      } else {
        companions.add(dose);
      }
    }
    final List<String> sources = <String>[
      for (final AgroMetricKey n in upcoming.nutrients)
        ...(guide?.sourceOptionsEs[n] ?? _defaultSources(n)),
    ];
    final String who = NutritionRecommendation.joinNutrientsEs(upcoming.nutrients);
    final String days = upcoming.inDays == 1 ? '1 día' : '${upcoming.inDays} días';
    final String ruleWhy = (upcoming.rule?.rationaleEs ?? '').trim();
    final String rationale =
        ruleWhy.isNotEmpty ? ruleWhy : upcoming.priority.rationaleEs.trim();

    // Si la guía llama a la ventana igual que a la etapa («Brotación»), no se
    // repite el nombre.
    final String? windowLabel = upcoming.rule?.labelEs;
    final bool sameName =
        windowLabel == null ||
        windowLabel.trim().toLowerCase() == upcoming.stageLabelEs.trim().toLowerCase();
    final StringBuffer detail = StringBuffer(
      'En ~$days entra «${upcoming.stageLabelEs}» y BIO-G abre la ventana '
      '${sameName ? '' : '«$windowLabel» '}de $who.',
    );
    if (doses.isNotEmpty) {
      detail.write(
        ' Dosis orientativa prevista: '
        '${doses.map((NutrientDose d) => d.lineEs).join('; ')}.',
      );
    }
    if (companions.isNotEmpty) {
      detail.write(
        ' Acompaña con: '
        '${companions.map((NutrientDose d) => d.lineEs).join('; ')}.',
      );
    }
    if (rationale.isNotEmpty) {
      detail.write(' $rationale');
      if (!rationale.endsWith('.')) detail.write('.');
    }
    detail.write(
      ' Ten el producto listo y el suelo con humedad pareja; no hace falta '
      'registrar nada cuando apliques.',
    );

    return NutritionRecommendation(
      nutrient: upcoming.nutrients.first,
      kind: NutritionRecommendationKind.upcoming,
      nutrients: List<AgroMetricKey>.unmodifiable(upcoming.nutrients),
      headlineEs: NutritionRecommendation.headlineFor(
        kind: NutritionRecommendationKind.upcoming,
        nutrients: upcoming.nutrients,
        windowLabelEs: upcoming.rule?.labelEs,
        stageLabelEs: upcoming.stageLabelEs,
      ),
      detailEs: detail.toString(),
      audit: audit,
      doseRange: doses.isEmpty ? null : doses.first.range,
      doses: List<NutrientDose>.unmodifiable(<NutrientDose>[...doses, ...companions]),
      timingEs:
          upcoming.rule?.timingEs ??
          'Antes de que empiece «${upcoming.stageLabelEs}».',
      sourceOptionsEs: List<String>.unmodifiable(_dedupe(sources)),
      rulesEs: List<String>.unmodifiable(
        _dedupe(<String>[
          ...(upcoming.rule?.rulesEs ?? const <String>[]),
          ...(guide?.generalRulesEs ?? const <String>[]),
        ]),
      ),
      windowLabelEs: upcoming.rule?.labelEs,
      stageLabelEs: upcoming.stageLabelEs,
      cropLabelEs: input.cropLabel ?? guide?.cropLabelEs,
      inDays: upcoming.inDays,
    );
  }

  /// Nutrientes que la regla reparte en la etapa sin abrirles ventana, en
  /// orden N, P, K. Vacío sin regla o sin reparto.
  static List<AgroMetricKey> _companionNutrients(
    StageNutritionRule? rule,
    List<AgroMetricKey> focus,
  ) {
    if (rule == null) return const <AgroMetricKey>[];
    return NutritionRecommendation.orderNpk(<AgroMetricKey>[
      for (final MapEntry<AgroMetricKey, double> e in rule.seasonShare.entries)
        if (e.value > 0 && !focus.contains(e.key)) e.key,
    ]);
  }

  /// Rango de UN nutriente para una ventana (actual o próxima), o el motivo
  /// por el que no hay cifra: plan de temporada de la guía × fracción de la
  /// ventana (también en frutales: plan anual de huerta en producción); sin
  /// guía o sin plan, se explica en lenguaje del agricultor.
  static _DoseLookup _doseFor({
    required NutritionReadinessInput input,
    required AgroMetricKey nutrient,
    required String? stageKey,
    required StageNutritionRule? rule,
    required NutritionGuide? guide,
    required List<String> limitations,
  }) {
    final String nutrientName = nutrient.labelEs.toLowerCase();
    final GuideAuditStatus audit = guide?.auditStatus ?? GuideAuditStatus.pending;
    final List<String> sources =
        guide?.sourceOptionsEs[nutrient] ?? _defaultSources(nutrient);

    if (guide == null) {
      return const _DoseLookup(
        reasonEs:
            'Para este cultivo BIO-G todavía no tiene guía de dosis: usa la '
            'etiqueta del producto o pregúntale a tu asesor.',
      );
    }
    if (!audit.canShowDose) {
      return _DoseLookup(
        reasonEs:
            'La guía de ${guide.cropLabelEs} todavía está en revisión: usa la '
            'etiqueta del producto o tu asesor mientras tanto.',
      );
    }
    if (!guide.hasSeasonPlan) {
      final String notes = (guide.notesEs ?? '').trim();
      return _DoseLookup(
        reasonEs:
            'La guía de ${guide.cropLabelEs} no fija kg/ha: aplica en dosis '
            'ligera según la etiqueta del producto y con riego.'
            '${notes.isEmpty ? '' : ' $notes'}',
      );
    }
    final NutritionDoseRange? fromGuide = guide.windowDoseFor(
      nutrient: nutrient,
      stageKey: stageKey,
    );
    if (fromGuide != null) {
      return _DoseLookup(
        range: _scaleDose(fromGuide, input.cultivationScaleId, sources, limitations),
      );
    }
    if (!guide.seasonPlan.containsKey(nutrient)) {
      return _DoseLookup(
        reasonEs:
            'La guía de ${guide.cropLabelEs} no fija cantidad de $nutrientName: '
            'decide con tu análisis de suelo.',
      );
    }
    return _DoseLookup(
      reasonEs:
          'La cantidad de $nutrientName va en otra etapa del ciclo, según la '
          'guía de ${guide.cropLabelEs}.',
    );
  }

  /// Por qué importa la ventana: la regla de la guía o, sin ella, el porqué
  /// del nutriente principal en el perfil.
  static String? _windowRationale(
    StageNutritionRule? rule,
    List<NutrientStagePriority> priorities,
    AgroMetricKey primary,
  ) {
    final String fromRule = (rule?.rationaleEs ?? '').trim();
    if (fromRule.isNotEmpty) return fromRule;
    for (final NutrientStagePriority p in priorities) {
      if (p.nutrient == primary && p.rationaleEs.trim().isNotEmpty) {
        return p.rationaleEs.trim();
      }
    }
    return null;
  }

  /// Traduce un rango en kg/ha a la escala del productor. Campo: igual. Cama:
  /// g/m² (y el equivalente comercial se recalcula en g/m²). Maceta: no hay
  /// conversión defendible sin masa de sustrato; se muestra la referencia de
  /// campo.
  static NutritionDoseRange _scaleDose(
    NutritionDoseRange field,
    String? scaleId,
    List<String> sourceOptionsEs,
    List<String> limitations,
  ) {
    final String scale = (scaleId ?? '').trim().toLowerCase();
    if (scale == 'bed' || scale == 'huerto' || scale == 'cama') {
      final double min = field.min * 0.1;
      final double max = field.max * 0.1;
      return NutritionDoseRange(
        min: min,
        max: max,
        form: field.form,
        unit: DoseUnit.gramsPerSquareMeter,
        sourceEs: field.sourceEs,
        commercialEquivalentEs: FertilizerProducts.equivalentEs(
          form: field.form,
          minKg: min,
          maxKg: max,
          sourceOptionsEs: sourceOptionsEs,
          unitEs: DoseUnit.gramsPerSquareMeter.labelEs,
        ),
        conditionEs: field.conditionEs,
        transparencyEs: '${field.transparencyEs ?? ''} (1 kg/ha = 0.1 g/m²).',
      );
    }
    if (scale == 'pot' || scale == 'maceta' || scale == 'contenedor') {
      const String note =
          'En maceta el rango en kg/ha no se traduce sin conocer el volumen de '
          'sustrato; se muestra la referencia de campo.';
      // Se llama una vez por nutriente: la nota va una sola vez.
      if (!limitations.contains(note)) limitations.add(note);
    }
    return field;
  }

  static List<String> _defaultSources(AgroMetricKey nutrient) => switch (nutrient) {
    AgroMetricKey.n => const <String>[
      'Urea (46-0-0)',
      'Sulfato de amonio (21-0-0)',
      'Nitrato de calcio (15.5-0-0)',
    ],
    AgroMetricKey.p => const <String>[
      'DAP (18-46-0)',
      'MAP (11-52-0)',
      'Superfosfato triple (0-46-0)',
    ],
    AgroMetricKey.k => const <String>[
      'Cloruro de potasio (0-0-60)',
      'Sulfato de potasio (0-0-50)',
      'Nitrato de potasio (13-0-46)',
    ],
    _ => const <String>[],
  };

  static List<String> _dedupe(List<String> items) {
    final Set<String> seen = <String>{};
    final List<String> out = <String>[];
    for (final String s in items) {
      final String t = s.trim();
      if (t.isEmpty || !seen.add(t)) continue;
      out.add(t);
    }
    return out;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // COPY DE TARJETA
  // ═════════════════════════════════════════════════════════════════════════

  static ({String headline, String detail}) _copyFor({
    required NutritionState state,
    required NutritionReadinessInput input,
    required NutrientStagePriority? focus,
    required NutritionRecommendation? recommendation,
    required NutritionResponseEvaluation? response,
    required FertilizationSignature? signature,
    required NutritionWindowRecord? window,
    required NutritionConditionCheck conditions,
    required List<NutrientStagePriority> priorities,
    required List<NutrientTrend> trends,
    required _Upcoming? upcoming,
    required bool possible,
    required NutritionWindowRecord? recentlyUnattended,
    required NutritionGuide? guide,
    required StageNutritionRule? rule,
  }) {
    final String stage = input.stageLabelEs ?? 'esta etapa';
    switch (state) {
      case NutritionState.responseWindow:
        final String who = window == null
            ? ''
            : ' (${NutritionRecommendation.joinNutrientsEs(window.nutrients)})';
        final String lead = window == null
            ? ''
            : 'Ventana «${window.displayLabelEs}»$who atendida'
                  '${signature == null ? '' : ' desde el ${_fmtDate(signature.startedAt)}'}. ';
        return (
          headline: 'Respuesta compatible con fertilización detectada',
          detail:
              '$lead${response?.summaryEs ?? 'Estoy observando la respuesta del suelo. Las sales de la zona de raíces subieron de forma compatible con una fertilización; no hace falta que registres nada.'}',
        );
      case NutritionState.actionWindow:
        return (
          headline: recommendation?.headlineEs ??
              NutritionRecommendation.headlineFor(
                kind: NutritionRecommendationKind.apply,
                nutrients: <AgroMetricKey>[
                  if (focus != null) focus.nutrient else AgroMetricKey.n,
                ],
                windowLabelEs: window?.windowLabelEs,
                stageLabelEs: stage,
              ),
          detail: recommendation?.detailEs ??
              'La etapa abre una ventana de manejo nutricional. Estoy observando '
                  'la respuesta del suelo para reconocer cuándo se atienda.',
        );
      case NutritionState.prepare:
        if (focus != null) {
          // Ventana abierta pero el suelo no deja aplicar: el titular y el
          // detalle ya los trae la recomendación (kind = prepare).
          return (
            headline: recommendation?.headlineEs ??
                NutritionRecommendation.headlineFor(
                  kind: NutritionRecommendationKind.prepare,
                  nutrients: <AgroMetricKey>[focus.nutrient],
                  windowLabelEs: window?.windowLabelEs,
                  stageLabelEs: stage,
                ),
            detail: recommendation?.detailEs ??
                'La etapa «$stage» ya demanda ${focus.labelEs.toLowerCase()}, '
                    'pero las condiciones del suelo aún no son ideales: '
                    '${conditions.blockersEs.join(' ')}'
                    '${possible ? ' Hay además un cambio en la zona de raíces que estoy observando.' : ''}',
          );
        }
        return (
          headline: recommendation?.headlineEs ??
              (upcoming == null
                  ? 'Se acerca una ventana de fertilización'
                  : NutritionRecommendation.headlineFor(
                      kind: NutritionRecommendationKind.upcoming,
                      nutrients: upcoming.nutrients,
                      windowLabelEs: upcoming.rule?.labelEs,
                      stageLabelEs: upcoming.stageLabelEs,
                    )),
          detail: recommendation?.detailEs ??
              'En unos días entra una etapa de alta demanda. Ten el producto listo.',
        );
      case NutritionState.learning:
        final int? left = input.learning.isLearning ? input.learning.daysLeft : null;
        return (
          headline: 'BIO-G está conociendo tu suelo',
          detail: left == null || left <= 0
              ? SiteLearningStatus.learningCopyEs
              : 'Primeros días del sensor en esta zona: está construyendo la '
                  'referencia de tu suelo. En $left día${left == 1 ? '' : 's'} '
                  'las comparaciones y las tendencias serán confiables.',
        );
      case NutritionState.monitor:
        if (window != null &&
            window.outcome == NutritionWindowOutcome.attendedDetected &&
            signature != null) {
          return (
            headline: 'Nutrición atendida: ${_windowNameOf(window)}',
            detail: response?.summaryEs ??
                'Respuesta compatible con fertilización detectada el '
                    '${_fmtDate(signature.startedAt)} en la ventana '
                    '«${window.displayLabelEs}». BIO-G no empuja más dosis '
                    'en esta etapa.',
          );
        }
        if (recentlyUnattended != null) {
          return (
            headline:
                'Sin evidencia de fertilización: ${_windowNameOf(recentlyUnattended)}',
            detail:
                'Esta ventana nutricional no mostró evidencia suficiente de haber '
                'sido atendida: la ventana «${recentlyUnattended.displayLabelEs}» '
                '(${NutritionRecommendation.joinNutrientsEs(recentlyUnattended.nutrients)}) '
                'terminó sin que la sonda viera una respuesta compatible con '
                'fertilización. Pesa en el score histórico y en la proyección de '
                'este ciclo. No es una certeza de que no fertilizaste: el producto '
                'pudo quedar fuera del alcance de la sonda o llegar con poca agua.',
          );
        }
        // Sin ventana abierta: lo que importa es hacia dónde va el suelo. Si
        // un nutriente que pesa en la etapa se mueve, ese es el titular; si
        // todo está quieto, se dice con claridad que no hace falta nada, con
        // el porqué de la guía y la próxima ventana del ciclo.
        final NutrientTrend? notable = _notableTrend(priorities, trends);
        final NutrientStagePriority? top = priorities.isEmpty ? null : priorities.first;
        final String closedNote = _closedWindowNoteEs(guide, rule, input);
        final String nextNote = _nextWindowNoteEs(guide, input);
        if (notable != null) {
          final String stageNote = closedNote.isNotEmpty
              ? ' $closedNote'
              : (top != null && top.priority == NutritionPriority.medium
                    ? ' En «$stage» el ${top.labelEs.toLowerCase()} importa: ${_lowerFirst(top.rationaleEs)}'
                    : '');
          return (
            headline: notable.sentenceEs,
            detail:
                '${notable.detailEs} No hay ventana de aplicación abierta en '
                '«$stage»; BIO-G sigue la tendencia.$stageNote$nextNote',
          );
        }
        if (closedNote.isNotEmpty) {
          return (
            headline: 'Suelo estable, sin necesidades nutrimentales por ahora',
            detail:
                'Las señales del suelo se mantienen estables. $closedNote$nextNote',
          );
        }
        if (top != null && top.priority == NutritionPriority.medium) {
          return (
            headline: 'Suelo estable, sin necesidades nutrimentales por ahora',
            detail:
                'Las señales del suelo se mantienen estables en «$stage». El '
                '${top.labelEs.toLowerCase()} importa en esta etapa '
                '(${_lowerFirst(top.rationaleEs)}), pero no hay ventana de '
                'aplicación abierta; BIO-G sigue la tendencia.$nextNote',
          );
        }
        return (
          headline: 'Suelo estable, sin necesidades nutrimentales por ahora',
          detail:
              'En «$stage» ningún nutriente está en alta demanda y las señales '
              'del suelo se mantienen estables. BIO-G sigue las tendencias y '
              'avisará al acercarse la próxima ventana.$nextNote',
        );
    }
  }

  /// «segunda fertilización (V6–V8)» o ««Vegetativo medio»» para titulares.
  static String _windowNameOf(NutritionWindowRecord w) =>
      NutritionRecommendation.windowNameFor(
        windowLabelEs: w.windowLabelEs,
        stageLabelEs: w.stageLabelEs,
      );

  /// Por qué la guía cierra la ventana en esta etapa («En «Espigamiento y
  /// floración» la guía de Maíz no reparte fertilizante: …»). Vacío sin guía
  /// o sin regla.
  static String _closedWindowNoteEs(
    NutritionGuide? guide,
    StageNutritionRule? rule,
    NutritionReadinessInput input,
  ) {
    if (guide == null || rule == null || rule.windowNutrients.isNotEmpty) {
      return '';
    }
    final String name = rule.labelEs ?? input.stageLabelEs ?? 'esta etapa';
    final String why = (rule.rationaleEs ?? '').trim();
    return 'En «$name» la guía de ${guide.cropLabelEs} no reparte fertilizante'
        '${why.isEmpty ? '.' : ': ${_lowerFirst(why)}${why.endsWith('.') ? '' : '.'}'}';
  }

  /// « Próxima ventana: amacollamiento (nitrógeno), al entrar la etapa.» o
  /// « No quedan ventanas de fertilización en este ciclo.» Vacío sin guía.
  static String _nextWindowNoteEs(NutritionGuide? guide, NutritionReadinessInput input) {
    // Etapa fuera de la guía (cosecha, fin de ciclo): no hay «siguiente».
    if (guide == null || guide.ruleForStage(input.stageKey) == null) return '';
    final StageNutritionRule? next = guide.nextWindowRuleAfterAny(input.stageKey);
    if (next == null) return ' No quedan ventanas de fertilización en este ciclo.';
    final String? label = next.labelEs;
    if (label == null || label.trim().isEmpty) return '';
    final String who = NutritionRecommendation.joinNutrientsEs(
      NutritionRecommendation.orderNpk(next.windowNutrients),
    );
    final String name = NutritionRecommendation.windowNameFor(
      windowLabelEs: label,
    );
    return ' Próxima ventana: $name ($who), al entrar la etapa.';
  }

  /// Nutriente que se mueve y además pesa en la etapa (prioridad media o
  /// alta); si ninguno pesa, cualquiera que se mueva.
  static NutrientTrend? _notableTrend(
    List<NutrientStagePriority> priorities,
    List<NutrientTrend> trends,
  ) {
    NutrientTrend? find(AgroMetricKey key) {
      for (final NutrientTrend t in trends) {
        if (t.nutrient == key && t.trend.isMoving) return t;
      }
      return null;
    }
    for (final NutrientStagePriority p in priorities) {
      if (p.priority == NutritionPriority.low) continue;
      final NutrientTrend? t = find(p.nutrient);
      if (t != null) return t;
    }
    for (final NutrientTrend t in trends) {
      if (t.trend.isMoving) return t;
    }
    return null;
  }

  /// Baja la inicial para encajar la frase tras dos puntos, sin tocar siglas
  /// ni símbolos («N en espigamiento…», «V6», «MAP»): solo cuando el segundo
  /// carácter es una letra minúscula.
  static String _lowerFirst(String s) {
    final String t = s.trim();
    if (t.length < 2) return t;
    final String second = t[1];
    final bool secondIsLowerLetter =
        second.toLowerCase() == second && second.toUpperCase() != second;
    if (!secondIsLowerLetter) return t;
    return t[0].toLowerCase() + t.substring(1);
  }

  static String _pct(double v) => '${(v * 100).round()} %';

  /// Compara la magnitud de esta firma con la habitual del sitio en lenguaje
  /// de campo; el número (MAD) se queda en los campos de la firma.
  static String _compareWithTypicalEs(double peak, double typical) {
    if (typical <= 0) return 'Es la primera respuesta comparable de este sitio.';
    final double ratio = peak / typical;
    if (ratio >= greaterResponseRatio) {
      return 'La respuesta fue mayor que la habitual de este sitio.';
    }
    if (ratio <= minorResponseRatio) {
      return 'La respuesta fue menor que la habitual de este sitio.';
    }
    return 'La respuesta fue parecida a la habitual de este sitio.';
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

/// Resultado de buscar la dosis de un nutriente: el rango, o por qué no hay.
class _DoseLookup {
  const _DoseLookup({this.range, this.reasonEs});

  final NutritionDoseRange? range;
  final String? reasonEs;
}

class _Upcoming {
  const _Upcoming({
    required this.nutrients,
    required this.rule,
    required this.stageKey,
    required this.stageLabelEs,
    required this.inDays,
    required this.priority,
  });

  /// Nutrientes que abrirá la ventana, en orden N, P, K.
  final List<AgroMetricKey> nutrients;

  /// Regla de la guía que la abre (null cuando viene del perfil).
  final StageNutritionRule? rule;

  final String stageKey;
  final String stageLabelEs;
  final int inDays;

  /// Prioridad principal (para pantallas que muestran una sola).
  final NutrientStagePriority priority;

  /// «amacollamiento (primer riego de auxilio)» o «la etapa «Floración»».
  String get windowNameEs => NutritionRecommendation.windowNameFor(
    windowLabelEs: rule?.labelEs,
    stageLabelEs: stageLabelEs,
  );
}
