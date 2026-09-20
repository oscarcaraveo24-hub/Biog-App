// lib/core/agro/nutrition/nutrition_timeline_vm.dart
//
// VIEW-MODEL DE LA LÍNEA DE TIEMPO NUTRICIONAL (pantalla de cultivo).
//
// Dos capas sobre un solo riel:
//   1. FENOLOGÍA: un nodo por etapa del ciclo (`CropStageSchedule`), con su
//      fase —pasada, actual, futura— y el progreso de la actual.
//   2. NUTRICIÓN: un marcador por VENTANA de la guía efectiva, anclado a la
//      primera etapa que la abre, con cinco estados: pendiente, abierta,
//      atendida, sin evidencia (solo si era importante) e informativa.
//
// El view-model es puro: recibe el calendario, el plan resuelto, el libro de
// ventanas y la decisión, y devuelve nodos listos para pintar. La verdad del
// sensor no se maquilla: «atendida» significa que el suelo respondió de forma
// compatible, nunca «aplicaste X kg». La dosis que muestra cada marcador es
// la RECOMENDADA por la guía efectiva, y se dice así.
//
// Dos reglas de producto del 17 sep 2026 (Oscar, con maíz en la mano):
//   · Una ventana que la declaración PLEGÓ del todo ya no es una
//     fertilización: no lleva marcador. «Una sola vez» = un marcador; antes
//     se pintaban las plegadas como «orientativas» y se leían como tres.
//   · Mientras el productor no haya contestado «¿cómo vas a fertilizar?» en
//     NPK (y haya algo que contestar), la línea sale sin marcadores y en
//     gris ([awaitingDeclaration]): no se le enseña un plan que todavía no
//     es suyo.
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guide.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_plan_resolver.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_readiness_engine.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/crops/crop_stage_schedule.dart';

enum TimelinePhase { past, current, future }

/// Estado visual del marcador de nutrición.
enum NutritionMarkerState {
  /// Ventana futura del plan.
  pending,

  /// Ventana de la etapa actual, abierta (aplica o prepara).
  open,

  /// El sensor vio una respuesta compatible con fertilización.
  attended,

  /// Terminó sin evidencia y era agronómicamente importante: pesa.
  unattended,

  /// No pesa: cubierta por tu plan, orientativa, o cerrada sin ser
  /// importante / sin observación suficiente.
  informative,
}

extension NutritionMarkerStateX on NutritionMarkerState {
  String get labelEs => switch (this) {
    NutritionMarkerState.pending => 'Pendiente',
    NutritionMarkerState.open => 'Ventana abierta',
    NutritionMarkerState.attended => 'Atendida',
    NutritionMarkerState.unattended => 'Sin evidencia',
    NutritionMarkerState.informative => 'Orientativa',
  };
}

/// Dosis recomendada de un nutriente en la ventana, ya en la escala del sitio.
class TimelineDose {
  const TimelineDose({required this.nutrient, required this.range});
  final AgroMetricKey nutrient;
  final NutritionDoseRange range;
}

/// Marcador de nutrición anclado a un nodo.
class NutritionMarkerVm {
  const NutritionMarkerVm({
    required this.state,
    required this.labelEs,
    required this.nutrients,
    required this.isCritical,
    required this.doses,
    this.timingEs,
    this.rationaleEs,
    this.rulesEs = const <String>[],
    this.noteEs,
    this.outcomeEs,
    this.evidenceEs = const <String>[],
    this.isFolded = false,
    this.isDemoted = false,
    this.stageSpanEs,
  });

  final NutritionMarkerState state;

  /// Nombre de la ventana («Segunda fertilización (V6–V8)»).
  final String labelEs;

  /// Nutrientes que abre la ventana efectiva, en orden N, P, K.
  final List<AgroMetricKey> nutrients;
  final bool isCritical;

  /// Dosis recomendadas (vacío si la guía calla).
  final List<TimelineDose> doses;

  final String? timingEs;
  final String? rationaleEs;
  final List<String> rulesEs;

  /// Una línea para el marcador («Cubierta por tu plan», «Cerró sin pesar»).
  final String? noteEs;

  /// Resultado del libro, si la ventana ya tiene registro.
  final String? outcomeEs;
  final List<String> evidenceEs;

  /// Dejó de abrir ventana de N por la declaración del productor.
  final bool isFolded;

  /// Degradada a orientativa por la respuesta mayor de la anterior.
  final bool isDemoted;

  /// «V6–V8 · Vegetativa temprana a media» cuando la ventana abarca varias
  /// etapas.
  final String? stageSpanEs;

  bool get hasDoses => doses.isNotEmpty;

  /// «N · P₂O₅ · K₂O» del marcador.
  String get nutrientsShortEs =>
      nutrients.map((AgroMetricKey k) => k.labelEs).join(' · ');
}

/// Un nodo del riel.
class TimelineNodeVm {
  const TimelineNodeVm({
    required this.stageKey,
    required this.labelEs,
    required this.phase,
    this.progress01,
    this.dayStart,
    this.dayEnd,
    this.marker,
  });

  final String stageKey;
  final String labelEs;
  final TimelinePhase phase;

  /// Progreso dentro de la etapa actual (solo en la actual).
  final double? progress01;
  final int? dayStart;
  final int? dayEnd;
  final NutritionMarkerVm? marker;

  bool get isCurrent => phase == TimelinePhase.current;
  bool get hasMarker => marker != null;

  /// Nombre corto para el nodo: lo que va antes de « / » o « (»
  /// («Reposo funcional / preparación» → «Reposo funcional»,
  /// «Maduración / senescencia» → «Maduración»). El completo va en la hoja.
  String get shortLabelEs => shortLabel(labelEs);

  static String shortLabel(String label) {
    String s = label.trim();
    for (final String sep in const <String>[' / ', ' (', ' — ', ' – ']) {
      final int i = s.indexOf(sep);
      if (i > 0) s = s.substring(0, i);
    }
    return s.trim();
  }
}

class NutritionTimelineVm {
  const NutritionTimelineVm({
    required this.nodes,
    required this.axis,
    required this.currentIndex,
    required this.hasGuide,
    this.planSummaryEs,
    this.cropLabelEs,
    this.cycleStartIndex,
    this.awaitingDeclaration = false,
    this.isAlreadyDone = false,
  });

  static const NutritionTimelineVm empty = NutritionTimelineVm(
    nodes: <TimelineNodeVm>[],
    axis: CropStageAxis.days,
    currentIndex: -1,
    hasGuide: false,
  );

  final List<TimelineNodeVm> nodes;
  final CropStageAxis axis;

  /// −1 si la etapa actual no está en el ciclo.
  final int currentIndex;

  /// Hay guía curada: la capa de nutrición existe.
  final bool hasGuide;

  /// «3 fertilizaciones de nitrógeno · plan de la guía» / «1 fertilización ·
  /// tu plan».
  final String? planSummaryEs;
  final String? cropLabelEs;

  /// Árboles: índice donde arranca el ciclo anual (la última etapa vuelve a
  /// esta). Null si no da la vuelta.
  final int? cycleStartIndex;

  /// El productor todavía no contestó «¿cómo vas a fertilizar?» en NPK y hay
  /// algo que contestar: la línea se pinta en gris, sin marcadores, con la
  /// invitación a contestar. Solo fenología.
  final bool awaitingDeclaration;

  /// Declaró «ya fertilicé»: no queda ninguna ventana de nitrógeno; solo
  /// pueden quedar marcadores de fósforo y potasio.
  final bool isAlreadyDone;

  bool get isEmpty => nodes.isEmpty;
  bool get isCycle => axis == CropStageAxis.perennialCycle;

  /// «Etapa 2 de 11» (o «11 etapas» cuando la actual no está en el ciclo).
  String get stageCountEs => currentIndex < 0
      ? '${nodes.length} etapas'
      : 'Etapa ${currentIndex + 1} de ${nodes.length}';

  /// Número de ventanas de fertilización que muestra la línea.
  int get fertilizationCount => markerCount;

  TimelineNodeVm? get currentNode =>
      currentIndex >= 0 && currentIndex < nodes.length ? nodes[currentIndex] : null;

  int get markerCount =>
      nodes.where((TimelineNodeVm n) => n.marker != null).length;

  /// Construye el view-model. Todo es opcional salvo el calendario: sin guía
  /// solo hay fenología; sin libro, los marcadores son pendientes/abiertos.
  static NutritionTimelineVm build({
    required CropStageSchedule? schedule,
    required String? currentStageKey,
    double? currentProgress01,
    NutritionPlanResolution plan = NutritionPlanResolution.none,
    List<NutritionWindowRecord> windows = const <NutritionWindowRecord>[],
    String? seasonKey,
    NutritionDecision? decision,
    String? cultivationScaleId,
    bool askable = true,
    bool memoryLoaded = true,
  }) {
    if (schedule == null || schedule.isEmpty) return empty;

    // Sin respuesta a «¿cómo vas a fertilizar?» (y con algo que contestar)
    // la capa de nutrición no se pinta: solo fenología, en gris. Mientras la
    // memoria del sitio no se haya leído tampoco: ahí «sin declaración» solo
    // significa «todavía no sé», y es mejor un gris breve que enseñar un
    // plan que quizá no es el del productor. Solo cuando la pregunta puede
    // hacerse ([askable]: cultivo sembrado); antes de sembrar se enseña el
    // plan de la guía.
    final bool awaiting = askable &&
        plan.hasGuide &&
        (!memoryLoaded || (plan.canDeclare && !plan.declarationApplied));
    final NutritionGuide? guide = awaiting ? null : plan.guide;
    final NutritionGuide? base = plan.baseGuide;
    final int currentIndex = schedule.indexOf(currentStageKey);
    final List<NutritionWindowRecord> seasonWindows = seasonKey == null
        ? windows
        : windows.where((NutritionWindowRecord w) => w.seasonKey == seasonKey).toList();

    final Set<int> usedRules = <int>{};
    final List<TimelineNodeVm> nodes = <TimelineNodeVm>[];
    for (int i = 0; i < schedule.slots.length; i++) {
      final CropStageSlot slot = schedule.slots[i];
      final TimelinePhase phase = currentIndex < 0
          ? TimelinePhase.future
          : i < currentIndex
              ? TimelinePhase.past
              : i == currentIndex
                  ? TimelinePhase.current
                  : TimelinePhase.future;

      NutritionMarkerVm? marker;
      if (guide != null) {
        final int ruleIdx = guide.ruleIndexFor(slot.stageKey);
        if (ruleIdx >= 0 && !usedRules.contains(ruleIdx)) {
          final StageNutritionRule rule = guide.stageRules[ruleIdx];
          final StageNutritionRule? baseRule = base == null
              ? null
              : (base.ruleIndexFor(slot.stageKey) >= 0
                    ? base.stageRules[base.ruleIndexFor(slot.stageKey)]
                    : null);
          marker = _marker(
            rule: rule,
            baseRule: baseRule,
            guide: guide,
            // La ventana puede abarcar varias etapas (V6–V8 = vegEarly y
            // vegMid): su fase es la del tramo completo, no la del primer
            // nodo donde se ancla.
            phase: _rulePhase(rule, schedule, currentIndex),
            plan: plan,
            windows: seasonWindows,
            decision: decision,
            schedule: schedule,
            cultivationScaleId: cultivationScaleId,
          );
          if (marker != null) usedRules.add(ruleIdx);
        }
      }

      nodes.add(
        TimelineNodeVm(
          stageKey: slot.stageKey,
          labelEs: slot.labelEs,
          phase: phase,
          progress01: phase == TimelinePhase.current
              ? (currentProgress01 ?? 0.0).clamp(0.0, 1.0)
              : null,
          dayStart: slot.dayStart,
          dayEnd: slot.dayEnd,
          marker: marker,
        ),
      );
    }

    return NutritionTimelineVm(
      nodes: List<TimelineNodeVm>.unmodifiable(nodes),
      axis: schedule.axis,
      currentIndex: currentIndex,
      hasGuide: plan.guide != null,
      planSummaryEs: awaiting ? 'Plan sin elegir' : _planSummary(plan),
      cropLabelEs: plan.guide?.cropLabelEs,
      cycleStartIndex: schedule.cycleStartIndex,
      awaitingDeclaration: awaiting,
      isAlreadyDone: plan.isAlreadyDone,
    );
  }

  static String? _planSummary(NutritionPlanResolution plan) {
    final NutritionGuide? guide = plan.guide;
    if (guide == null) return null;
    if (plan.isAlreadyDone) return 'Nitrógeno ya aplicado · tu plan';
    final int n = guide.nitrogenPassCount;
    if (n == 0) return null;
    final String count = n == 1
        ? '1 fertilización de nitrógeno'
        : '$n fertilizaciones de nitrógeno';
    return plan.declarationApplied ? '$count · tu plan' : '$count · plan de la guía';
  }

  static NutritionMarkerVm? _marker({
    required StageNutritionRule rule,
    required StageNutritionRule? baseRule,
    required NutritionGuide guide,
    required TimelinePhase phase,
    required NutritionPlanResolution plan,
    required List<NutritionWindowRecord> windows,
    required NutritionDecision? decision,
    required CropStageSchedule schedule,
    required String? cultivationScaleId,
  }) {
    final bool opensNow = rule.windowNutrients.isNotEmpty;
    // Plegada en N por la declaración (sigue abierta para fósforo/potasio).
    final bool folded = plan.foldedStageKeys.contains(rule.primaryStageKey) ||
        ((baseRule?.windowNutrients.contains(AgroMetricKey.n) ?? false) &&
            !rule.windowNutrients.contains(AgroMetricKey.n));
    final bool demoted = plan.demotedStageKey != null &&
        plan.demotedStageKey == rule.primaryStageKey;

    // Sin ventana ahora: no hay marcador. Incluye la ventana que la
    // declaración PLEGÓ del todo (ya no abre nada): dejó de ser una
    // fertilización y no se pinta (17 sep 2026); la regla solo explica por
    // qué no toca aplicar. Una ventana plegada solo en N pero que sigue
    // abierta para fósforo/potasio sí lleva marcador, sin la N.
    if (!opensNow) return null;

    final List<AgroMetricKey> nutrients = NutritionRecommendation.orderNpk(
      rule.windowNutrients,
    );
    final String label = (rule.labelEs ?? baseRule?.labelEs ?? '').trim();
    final String stageLabel = _stageSpan(rule, schedule);
    final String displayLabel = label.isNotEmpty ? label : stageLabel;

    // Registro del libro para esta regla (cualquiera de sus etapas).
    NutritionWindowRecord? record;
    for (final NutritionWindowRecord w in windows) {
      if (!rule.matchesStage(w.stageKey)) continue;
      if (record == null || w.openedAt.isAfter(record.openedAt)) record = w;
    }

    // Dosis recomendadas, en la escala del sitio.
    final List<TimelineDose> doses = <TimelineDose>[];
    {
      final String? stageKey = rule.stageKeys.isEmpty ? null : rule.stageKeys.first;
      final List<String> scratch = <String>[];
      for (final AgroMetricKey k in nutrients) {
        final NutritionDoseRange? field = guide.windowDoseFor(
          nutrient: k,
          stageKey: stageKey,
        );
        if (field == null) continue;
        doses.add(
          TimelineDose(
            nutrient: k,
            range: NutritionReadinessEngine.scaleDose(
              field,
              cultivationScaleId,
              guide.sourceOptionsEs[k] ?? const <String>[],
              scratch,
            ),
          ),
        );
      }
    }

    NutritionMarkerState state = NutritionMarkerState.pending;
    String? note;
    String? outcome;
    List<String> evidence = const <String>[];

    if (record != null) {
      outcome = record.outcome.labelEs;
      evidence = record.evidenceEs;
      switch (record.outcome) {
        case NutritionWindowOutcome.open:
          state = NutritionMarkerState.open;
          break;
        case NutritionWindowOutcome.attendedDetected:
          state = NutritionMarkerState.attended;
          note = record.responseVerdict == null
              ? 'El suelo respondió de forma compatible con una fertilización.'
              : record.responseVerdict!.labelEs;
          break;
        case NutritionWindowOutcome.unattended:
          if (record.isCritical && !demoted) {
            state = NutritionMarkerState.unattended;
            note = 'Terminó sin evidencia de fertilización; pesa en el estado general.';
          } else {
            state = NutritionMarkerState.informative;
            note = 'Terminó sin evidencia; no pesa.';
          }
          break;
        case NutritionWindowOutcome.inconclusive:
          state = NutritionMarkerState.informative;
          note = 'Observación insuficiente para saber si se atendió; no pesa.';
          break;
        case NutritionWindowOutcome.notComparable:
          state = NutritionMarkerState.informative;
          note = 'No se pudo comparar (sin CE, suelo seco o sitio nuevo); no pesa.';
          break;
      }
    } else {
      switch (phase) {
        case TimelinePhase.current:
          final NutritionState? s = decision?.state;
          state = NutritionMarkerState.open;
          if (s == NutritionState.prepare) {
            note = 'El suelo todavía no está listo para aplicar.';
          } else if (s == NutritionState.responseWindow) {
            state = NutritionMarkerState.attended;
            note = 'Observando la respuesta del suelo.';
          }
          break;
        case TimelinePhase.future:
          state = NutritionMarkerState.pending;
          break;
        case TimelinePhase.past:
          state = NutritionMarkerState.informative;
          note = 'Sin registro del sensor en esta ventana.';
          break;
      }
    }

    if (folded) {
      final String rest = NutritionRecommendation.joinNutrientsEs(nutrients);
      final String extra = plan.isAlreadyDone
          ? 'Según tu plan ya fertilizaste con nitrógeno; esta ventana sigue '
              'abierta para $rest.'
          : 'El nitrógeno de esta ventana va en otra pasada según tu plan; '
              'sigue abierta para $rest.';
      note = note == null ? extra : '$extra $note';
    }

    if (demoted && state != NutritionMarkerState.attended) {
      state = state == NutritionMarkerState.unattended
          ? NutritionMarkerState.informative
          : state;
      note = 'La aplicación anterior respondió más de lo habitual: esta ventana '
          'es orientativa y no pesa.';
    }

    return NutritionMarkerVm(
      state: state,
      labelEs: displayLabel,
      nutrients: nutrients,
      isCritical: opensNow && rule.isCritical,
      doses: List<TimelineDose>.unmodifiable(doses),
      timingEs: rule.timingEs,
      rationaleEs: rule.rationaleEs,
      rulesEs: rule.rulesEs,
      noteEs: note,
      outcomeEs: outcome,
      evidenceEs: evidence,
      isFolded: folded,
      isDemoted: demoted,
      stageSpanEs: stageLabel,
    );
  }

  /// Fase de una regla que puede abarcar varias etapas del calendario.
  static TimelinePhase _rulePhase(
    StageNutritionRule rule,
    CropStageSchedule schedule,
    int currentIndex,
  ) {
    if (currentIndex < 0) return TimelinePhase.future;
    bool anyPast = false;
    bool anyFuture = false;
    for (int i = 0; i < schedule.slots.length; i++) {
      if (!rule.matchesStage(schedule.slots[i].stageKey)) continue;
      if (i == currentIndex) return TimelinePhase.current;
      if (i < currentIndex) {
        anyPast = true;
      } else {
        anyFuture = true;
      }
    }
    if (anyPast && !anyFuture) return TimelinePhase.past;
    return TimelinePhase.future;
  }

  /// «Vegetativa temprana – Vegetativa media» para reglas que abarcan varias
  /// etapas del calendario; el nombre de la única etapa si es una.
  static String _stageSpan(StageNutritionRule rule, CropStageSchedule schedule) {
    final List<String> labels = <String>[];
    for (final CropStageSlot s in schedule.slots) {
      if (rule.matchesStage(s.stageKey)) labels.add(s.labelEs);
    }
    if (labels.isEmpty) return rule.stageKeys.isEmpty ? '' : rule.stageKeys.first;
    if (labels.length == 1) return labels.first;
    return '${labels.first} – ${labels.last}';
  }
}
