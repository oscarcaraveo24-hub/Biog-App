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
//   Guía auditada ............... `NutritionGuide` (fuentes, timing, 3R, rangos)
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
// COPY DEL FLUJO (decisión de producto, sep 2026):
//   «Esta etapa necesita nutrición.»
//   «Estoy observando la respuesta del suelo.»
//   «Respuesta compatible con fertilización detectada.»
//   «Esta ventana nutricional no mostró evidencia suficiente de haber sido
//    atendida.»
import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/fertilization_signature_scanner.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guide.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_variety_modifiers.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_window_ledger.dart';
import 'package:bio_g/core/agro/nutrition/site_learning.dart';
import 'package:bio_g/core/agro/soil_reaction.dart';
import 'package:bio_g/core/agro/traceability/engine_versions.dart';
import 'package:bio_g/core/agro/tree_restitution_planner.dart';
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
    this.kgFruitPerTree,
    this.soilSupplyLevel,
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

  final bool isPerennial;

  /// Cosecha esperada por árbol (kg). Solo frutales.
  final double? kgFruitPerTree;

  /// Nivel de un análisis de suelo del productor, si existe. Nunca de la sonda.
  final SoilSupplyLevel? soilSupplyLevel;

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
    final String seasonKey =
        input.seasonKey ?? '${input.deviceId ?? 'device'}|$crop|-';
    final String deviceId = input.deviceId ?? 'device';
    final String stageKey = StageNutritionRule.normalizeStageKey(input.stageKey);

    CurrentWindowSpec? spec;
    if (windowCandidates.isNotEmpty && stageKey.isNotEmpty) {
      spec = CurrentWindowSpec(
        stageKey: stageKey,
        stageLabelEs: input.stageLabelEs ?? input.stageKey ?? stageKey,
        nutrients: windowCandidates.map((p) => p.nutrient).toList(),
        isCritical: windowCandidates.any((p) => p.isCriticalWindow),
        startedAt: input.stageStartedAt ?? input.now,
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
    final _Upcoming? upcoming = _upcomingWindow(input, variety);

    // ── 6. Estado ────────────────────────────────────────────────────────
    NutritionState state;
    NutrientStagePriority? focus;
    bool awaitingEvidence = false;

    final String windowStageLabel =
        window?.stageLabelEs ?? input.stageLabelEs ?? 'esta etapa';
    if (detectedSignature != null && following) {
      state = NutritionState.responseWindow;
      reasons.add(
        'Firma compatible con fertilización detectada el '
        '${_fmtDate(detectedSignature.startedAt)} (confianza '
        '${detectedSignature.confidenceLabelEs}, '
        '${detectedSignature.kind.labelEs.toLowerCase()}); la ventana de '
        '«$windowStageLabel» queda atendida y se sigue la respuesta hasta el '
        '${_fmtDate(detectedSignature.responseHorizonEndsAt)}.',
      );
    } else if (detectedSignature != null) {
      state = NutritionState.monitor;
      reasons.add(
        'La ventana de «$windowStageLabel» fue atendida (firma del '
        '${_fmtDate(detectedSignature.startedAt)}); la respuesta ya se evaluó: '
        '${response?.verdict.labelEs ?? 'sin veredicto'}.',
      );
    } else if (spec != null) {
      focus = windowCandidates.first;
      awaitingEvidence = true;
      state = conditions.allowsApplication
          ? NutritionState.actionWindow
          : NutritionState.prepare;
      reasons.add(
        'La etapa «${spec.stageLabelEs}» tiene prioridad alta de '
        '${focus.labelEs.toLowerCase()} (${_pct(focus.priority01)})'
        '${spec.isCritical ? ', ventana agronómicamente importante' : ''}; '
        'el sensor observa la respuesta del suelo desde el '
        '${_fmtDate(spec.startedAt)}.',
      );
      if (possibleSignature != null) {
        reasons.add(
          'Hay un cambio en la zona radicular que podría ser una fertilización '
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
        'Se aproxima una etapa de alta demanda de '
        '${upcoming.priority.labelEs.toLowerCase()} '
        '(${upcoming.stageLabelEs}) en ~${upcoming.inDays} días.',
      );
    } else if (input.learning.isLearning) {
      state = NutritionState.learning;
      reasons.add(
        'Sitio en aprendizaje inicial (día ${input.learning.daysSinceStart + 1} '
        'de ${SiteLearningStatus.learningDays}).',
      );
    } else {
      state = NutritionState.monitor;
      reasons.add('Sin ventana nutricional relevante en la etapa actual.');
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
        'Ventana «${r.stageLabelEs}» (${r.nutrientsLabelEs}) cerrada: '
        '${r.outcome.labelEs.toLowerCase()}.',
      );
    }

    // ── 8. Recomendación ─────────────────────────────────────────────────
    NutritionRecommendation? recommendation;
    if (focus != null) {
      recommendation = _buildRecommendation(
        input: input,
        focus: focus,
        rule: rule,
        guide: guide,
        variety: variety,
        conditions: conditions,
        limitations: limitations,
        possible: possibleSignature,
      );
    } else if (state == NutritionState.prepare && upcoming != null) {
      recommendation = NutritionRecommendation(
        nutrient: upcoming.priority.nutrient,
        headlineEs:
            'Se aproxima la ventana de ${upcoming.priority.labelEs.toLowerCase()}',
        detailEs:
            'En ~${upcoming.inDays} días entra «${upcoming.stageLabelEs}», etapa de '
            'alta demanda de ${upcoming.priority.labelEs.toLowerCase()}. '
            'Revisa que tengas producto y que el suelo llegue con humedad '
            'pareja; BIO-G abrirá la ventana al entrar la etapa.',
        audit: audit,
        timingEs: 'Antes de que empiece «${upcoming.stageLabelEs}».',
        sourceOptionsEs:
            guide?.sourceOptionsEs[upcoming.priority.nutrient] ?? const <String>[],
      );
    }

    if (guide == null) {
      limitations.add(
        'Sin guía curada para este cultivo: la prioridad sale del perfil '
        'fenológico y no se emiten rangos de dosis.',
      );
    } else if (!audit.canShowDose && !guide.usesTreeRestitution) {
      limitations.add(
        'La guía de ${guide.cropLabelEs} está pendiente de auditoría: los '
        'rangos de dosis no se muestran hasta que se marque como auditada.',
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
      upcoming: upcoming,
      possible: possible,
      recentlyUnattended: recentlyUnattended,
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
  // PRIORIDADES
  // ═════════════════════════════════════════════════════════════════════════

  static List<NutrientStagePriority> _buildPriorities({
    required NutritionReadinessInput input,
    required StageNutritionRule? rule,
    required VarietyNutritionAdjustment variety,
  }) {
    final StageTargets? targets = input.targets;
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
      // La guía curada puede abrir la ventana aunque el perfil quede en medio.
      final double effective = ruleOpens
          ? math.max(adjusted, NutritionPriorityX.kHighPriorityThreshold01)
          : adjusted;
      final NutritionPriority level = NutritionPriorityX.fromPriority01(
        effective,
      );
      final bool critical =
          (ruleOpens && (rule?.isCritical ?? false)) ||
          effective >= NutritionPriorityX.kCriticalPriorityThreshold01;

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
        'Respuesta habitual de este sitio: ${_fmtZ(typical)} MAD; esta firma: '
            '${_fmtZ(signature.ecPeakMad)} MAD.',
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
            'Estoy observando la respuesta del suelo. La carga iónica de la zona '
            'radicular subió de forma compatible con una fertilización '
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

  static _Upcoming? _upcomingWindow(
    NutritionReadinessInput input,
    VarietyNutritionAdjustment variety,
  ) {
    final int? days = input.daysToStageEnd;
    if (days == null || days > upcomingWindowDays) return null;

    // Primero la guía curada: siguiente regla con ventana.
    final NutritionGuide? guide = input.guide;
    if (guide != null) {
      for (final AgroMetricKey key in const <AgroMetricKey>[
        AgroMetricKey.n,
        AgroMetricKey.p,
        AgroMetricKey.k,
      ]) {
        final StageNutritionRule? next = guide.nextWindowRuleAfter(
          input.stageKey,
          key,
        );
        if (next != null &&
            input.nextStageKey != null &&
            next.matchesStage(input.nextStageKey)) {
          return _Upcoming(
            priority: NutrientStagePriority(
              nutrient: key,
              priority: NutritionPriority.high,
              priority01: NutritionPriorityX.kHighPriorityThreshold01,
              windowLabelEs: next.labelEs ?? _defaultWindowLabel(key, NutritionPriority.high),
              rationaleEs: next.rationaleEs ?? '',
              isCriticalWindow: next.isCritical,
            ),
            stageLabelEs: input.nextStageLabelEs ?? input.nextStageKey!,
            inDays: math.max(1, days),
          );
        }
      }
    }

    // Después el perfil de la etapa siguiente, si el runtime la anticipó.
    final StageTargets? next = input.nextTargets;
    if (next == null) return null;
    NutrientStagePriority? best;
    for (final AgroMetricKey key in const <AgroMetricKey>[
      AgroMetricKey.n,
      AgroMetricKey.p,
      AgroMetricKey.k,
    ]) {
      final double p = variety
          .adjustPriority(next.resolvedPriorityFor(key), key, input.nextStageKey)
          .clamp(0.0, 1.0);
      if (p < NutritionPriorityX.kHighPriorityThreshold01) continue;
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
      priority: best,
      stageLabelEs: input.nextStageLabelEs ?? input.nextStageKey ?? 'siguiente etapa',
      inDays: math.max(1, days),
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

  static NutritionRecommendation _buildRecommendation({
    required NutritionReadinessInput input,
    required NutrientStagePriority focus,
    required StageNutritionRule? rule,
    required NutritionGuide? guide,
    required VarietyNutritionAdjustment variety,
    required NutritionConditionCheck conditions,
    required List<String> limitations,
    FertilizationSignature? possible,
  }) {
    final AgroMetricKey nutrient = focus.nutrient;
    final String nutrientName = nutrient.labelEs.toLowerCase();
    final GuideAuditStatus audit = guide?.auditStatus ?? GuideAuditStatus.pending;

    NutritionDoseRange? dose;
    String? noDoseReason;

    if (input.isPerennial || (guide?.usesTreeRestitution ?? false)) {
      final TreeRestitutionResult? r = TreeRestitutionPlanner.compute(
        nutrient: nutrient,
        cropKey: input.cropKey,
        kgFruitPerTree: input.kgFruitPerTree,
        soilLevel: input.soilSupplyLevel,
      );
      if (r != null) {
        final int lo = TreeRestitutionPlanner.roundForDisplay(
          r.gramsPerTreeNutrient * 0.85,
        );
        final int hi = TreeRestitutionPlanner.roundForDisplay(
          r.gramsPerTreeNutrient * 1.15,
        );
        final int comLo = TreeRestitutionPlanner.roundForDisplay(
          r.gramsPerTreeCommercial * 0.85,
        );
        final int comHi = TreeRestitutionPlanner.roundForDisplay(
          r.gramsPerTreeCommercial * 1.15,
        );
        dose = NutritionDoseRange(
          min: lo.toDouble(),
          max: hi.toDouble(),
          form: switch (nutrient) {
            AgroMetricKey.p => NutrientForm.p2o5,
            AgroMetricKey.k => NutrientForm.k2o,
            _ => NutrientForm.n,
          },
          unit: DoseUnit.gramsPerPlant,
          sourceEs:
              'Restitución por extracción (${r.coefficients.sourceEs})',
          commercialEquivalentEs:
              '≈ $comLo–$comHi g de ${r.commercialSourceEs} por árbol y ciclo',
          transparencyEs: r.transparencyEs,
        );
      } else if (!TreeRestitutionPlanner.hasCoefficients(input.cropKey)) {
        noDoseReason =
            'Este cultivo no tiene coeficientes de extracción cargados; la dosis '
            'queda para la guía auditada.';
      } else {
        noDoseReason =
            'Para calcular gramos por árbol falta la cosecha esperada por árbol. '
            'Regístrala en la proyección de rendimiento y BIO-G te da la dosis '
            'por restitución.';
      }
    } else if (guide != null) {
      final NutritionDoseRange? fromGuide = guide.windowDoseFor(
        nutrient: nutrient,
        stageKey: input.stageKey,
      );
      if (fromGuide != null) {
        dose = _scaleDose(fromGuide, input.cultivationScaleId, limitations);
      } else if (!audit.canShowDose) {
        noDoseReason =
            'La guía de ${guide.cropLabelEs} está pendiente de auditoría: '
            'BIO-G no muestra un rango de dosis hasta que se valide cultivo por '
            'cultivo. Usa la etiqueta del producto o tu asesor mientras tanto.';
      } else {
        noDoseReason =
            'La guía auditada no reparte $nutrientName en esta etapa; la '
            'prioridad es alta pero el rango se define en la ventana que la guía '
            'sí sostiene.';
      }
    } else {
      noDoseReason =
          'Sin guía curada para este cultivo: BIO-G no inventa una cifra. La '
          'prioridad es fenológica; la dosis, de tu asesor o la etiqueta del '
          'producto.';
    }

    // Fuentes y reglas 3R.
    final List<String> sources = <String>[
      ...(guide?.sourceOptionsEs[nutrient] ?? const <String>[]),
    ];
    if (sources.isEmpty) sources.addAll(_defaultSources(nutrient));

    final List<String> rules = <String>[
      ...(rule?.rulesEs ?? const <String>[]),
      ...(guide?.generalRulesEs ?? const <String>[]),
    ];
    final String? caution = variety.cautionFor(nutrient, input.stageKey);
    if (caution != null) rules.add(caution);
    final BioGTelemetry? t = input.live;
    if (t != null && t.hasPhData) {
      final SoilReaction reaction = soilReactionFromPh(t.ph);
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
    rules.addAll(conditions.cautionsEs);

    final String headline = conditions.allowsApplication
        ? 'Esta etapa necesita nutrición: $nutrientName'
        : 'Esta etapa necesita nutrición: prepara, todavía no apliques';
    final StringBuffer detail = StringBuffer()
      ..write(focus.rationaleEs.trim().isEmpty
          ? 'La etapa demanda $nutrientName.'
          : focus.rationaleEs.trim());
    if (dose != null) {
      detail.write(' Rango orientativo: ${dose.labelEs}.');
    } else if (noDoseReason != null) {
      detail.write(' $noDoseReason');
    }
    if (!conditions.allowsApplication) {
      detail.write(' ${conditions.blockersEs.join(' ')}');
    }
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
      nutrient: nutrient,
      headlineEs: headline,
      detailEs: detail.toString(),
      audit: audit,
      doseRange: dose,
      doseUnavailableReasonEs: dose == null ? noDoseReason : null,
      sourceOptionsEs: List<String>.unmodifiable(sources),
      rulesEs: List<String>.unmodifiable(_dedupe(rules)),
      timingEs: rule?.timingEs,
    );
  }

  /// Traduce un rango en kg/ha a la escala del productor. Campo: igual. Cama:
  /// g/m². Maceta: no hay conversión defendible sin masa de sustrato.
  static NutritionDoseRange _scaleDose(
    NutritionDoseRange field,
    String? scaleId,
    List<String> limitations,
  ) {
    final String scale = (scaleId ?? '').trim().toLowerCase();
    if (scale == 'bed' || scale == 'huerto' || scale == 'cama') {
      return NutritionDoseRange(
        min: field.min * 0.1,
        max: field.max * 0.1,
        form: field.form,
        unit: DoseUnit.gramsPerSquareMeter,
        sourceEs: field.sourceEs,
        commercialEquivalentEs: field.commercialEquivalentEs,
        transparencyEs: '${field.transparencyEs ?? ''} (1 kg/ha = 0.1 g/m²).',
      );
    }
    if (scale == 'pot' || scale == 'maceta' || scale == 'contenedor') {
      limitations.add(
        'En maceta el rango en kg/ha no se traduce sin conocer el volumen de '
        'sustrato; se muestra la referencia de campo.',
      );
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
    required _Upcoming? upcoming,
    required bool possible,
    required NutritionWindowRecord? recentlyUnattended,
  }) {
    final String stage = input.stageLabelEs ?? 'esta etapa';
    switch (state) {
      case NutritionState.responseWindow:
        return (
          headline: 'Respuesta compatible con fertilización detectada',
          detail: response?.summaryEs ??
              'Estoy observando la respuesta del suelo. La carga iónica de la '
                  'zona radicular subió de forma compatible con una fertilización; '
                  'la ventana de «$stage» queda atendida sin que registres nada.',
        );
      case NutritionState.actionWindow:
        return (
          headline: recommendation?.headlineEs ??
              'Esta etapa necesita nutrición',
          detail: recommendation?.detailEs ??
              'La etapa abre una ventana de manejo nutricional. Estoy observando '
                  'la respuesta del suelo para reconocer cuándo se atienda.',
        );
      case NutritionState.prepare:
        if (focus != null) {
          return (
            headline: 'Esta etapa necesita nutrición: prepara, todavía no apliques',
            detail:
                'La etapa «$stage» ya demanda ${focus.labelEs.toLowerCase()}, '
                'pero las condiciones del suelo aún no son ideales: '
                '${conditions.blockersEs.join(' ')}'
                '${possible ? ' Hay además un cambio en la zona radicular que estoy observando.' : ''}',
          );
        }
        return (
          headline: 'Se aproxima una ventana de ${upcoming?.priority.labelEs.toLowerCase() ?? 'nutrición'}',
          detail: recommendation?.detailEs ??
              'En unos días entra una etapa de alta demanda. Ten el producto listo.',
        );
      case NutritionState.learning:
        return (
          headline: 'Aprendiendo esta zona',
          detail: SiteLearningStatus.learningCopyEs,
        );
      case NutritionState.monitor:
        if (window != null &&
            window.outcome == NutritionWindowOutcome.attendedDetected &&
            signature != null) {
          return (
            headline: 'Nutrición atendida en «${window.stageLabelEs}»',
            detail: response?.summaryEs ??
                'Respuesta compatible con fertilización detectada el '
                    '${_fmtDate(signature.startedAt)}. BIO-G no empuja más dosis '
                    'en esta etapa.',
          );
        }
        if (recentlyUnattended != null) {
          return (
            headline:
                'Esta ventana nutricional no mostró evidencia suficiente de haber '
                'sido atendida',
            detail:
                'La ventana de ${recentlyUnattended.nutrientsLabelEs} en '
                '«${recentlyUnattended.stageLabelEs}» terminó sin que la sonda viera '
                'una respuesta compatible con fertilización. Pesa en el score '
                'histórico y en la proyección de este ciclo. No es una certeza de '
                'que no fertilizaste: el producto pudo quedar fuera del alcance de '
                'la sonda o llegar con poca agua.',
          );
        }
        final NutrientStagePriority? top = priorities.isEmpty ? null : priorities.first;
        if (top != null && top.priority == NutritionPriority.medium) {
          return (
            headline: '${top.labelEs} importante en esta etapa',
            detail:
                '${top.rationaleEs} No hay ventana de aplicación abierta; BIO-G '
                'sigue la tendencia de la zona radicular.',
          );
        }
        return (
          headline: 'Sin ventana nutricional en «$stage»',
          detail:
              'Ningún nutriente está en alta demanda ahora. BIO-G sigue las '
              'tendencias del suelo y avisará al acercarse la próxima ventana.',
        );
    }
  }

  static String _pct(double v) => '${(v * 100).round()} %';

  static String _fmtZ(double z) => (z >= 0 ? '+' : '') + z.toStringAsFixed(1);

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

class _Upcoming {
  const _Upcoming({
    required this.priority,
    required this.stageLabelEs,
    required this.inDays,
  });

  final NutrientStagePriority priority;
  final String stageLabelEs;
  final int inDays;
}
