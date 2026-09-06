// lib/core/agro/nutrition/nutrition_window_ledger.dart
//
// LIBRO DE VENTANAS NUTRICIONALES — la memoria que convierte «la etapa
// necesitaba nutrición» en «fue atendida / no mostró evidencia», sin que el
// agricultor registre nada.
//
// REGLA CENTRAL
//   La guía y la etapa dicen QUÉ debería ocurrir (se abre una ventana).
//   El sensor observa QUÉ parece haber ocurrido (firma de fertilización).
//   El historial ayuda a comparar si esa respuesta es normal para el sitio.
//   BIO-G decide el estado de la ventana automáticamente.
//
// CUÁNDO PENALIZA (y cuándo NO)
//   · Ventana abierta sin firma todavía ........... NO penaliza (observando).
//   · Firma compatible detectada ................... NO penaliza; atendida.
//   · Ventana terminó, observable, sin evidencia ... penaliza SOLO si era
//                                                    agronómicamente importante.
//   · Ventana terminó pero no fue observable ....... NO penaliza (inconclusa /
//                                                    no comparable).
// Nunca existe la regla «Nraw no subió → no fertilizó» (Guía v0.4, §6).
//
// GRACIA AL CIERRE: la urea responde con días de retraso (§30). Una ventana
// que termina no se sentencia el mismo día: se sigue observando unos días
// más antes de decidir.
import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/fertilization_signature_scanner.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/agro/nutrition/site_learning.dart';

/// Ventana que la etapa actual abre (o no), ya resuelta por el motor.
class CurrentWindowSpec {
  const CurrentWindowSpec({
    required this.stageKey,
    required this.stageLabelEs,
    required this.nutrients,
    required this.isCritical,
    required this.startedAt,
    this.labelEs,
  });

  final String stageKey;
  final String stageLabelEs;
  final List<AgroMetricKey> nutrients;
  final bool isCritical;

  /// Nombre de la ventana según la guía («Segunda fertilización (V6–V8)»),
  /// si la guía lo declara.
  final String? labelEs;

  /// Inicio estimado de la etapa (o momento en que BIO-G la pudo observar).
  final DateTime startedAt;
}

/// Resultado de reconciliar el libro con la situación actual.
class LedgerReconciliation {
  const LedgerReconciliation({
    required this.records,
    required this.changed,
    this.current,
    this.currentScan,
    this.justResolved = const <NutritionWindowRecord>[],
  });

  /// Libro completo de la temporada tras la reconciliación.
  final List<NutritionWindowRecord> records;

  /// Filas que cambiaron y hay que persistir.
  final List<NutritionWindowRecord> changed;

  /// Ventana de la etapa actual, si la etapa abre una.
  final NutritionWindowRecord? current;

  /// Barrido de la ventana actual.
  final FertilizationSignatureScan? currentScan;

  /// Ventanas cuyo resultado final se decidió en esta reconciliación.
  final List<NutritionWindowRecord> justResolved;
}

class NutritionWindowLedger {
  const NutritionWindowLedger._();

  /// Días que se sigue observando una ventana después de que termine su
  /// etapa, para no perder una respuesta tardía (urea, §30).
  static const int closeGraceDays = 4;

  /// Factor por cada ventana importante que terminó sin evidencia. 0.94 = seis
  /// puntos sobre 100. Deliberadamente suave: la nutrición debe notarse, no
  /// enmascarar la condición física del suelo. Pendiente de calibrar con
  /// datos reales (Guía v0.4, §38).
  static const double kUnattendedWindowScoreFactor = 0.94;

  /// Piso del factor acumulado en una temporada.
  static const double kMinSeasonScoreFactor = 0.85;

  /// Días durante los que una ventana recién sentenciada sin evidencia sigue
  /// apareciendo en la tarjeta con su copy propio.
  static const int recentlyUnattendedDays = 3;

  /// Reconcilia el libro de la temporada con la etapa actual y lo que el
  /// sensor observó.
  ///
  /// [scanner] barre un rango de tiempo del historial; se inyecta para que el
  /// libro no dependa de cómo se obtiene la telemetría (y para probarlo).
  static LedgerReconciliation reconcile({
    required List<NutritionWindowRecord> records,
    required String seasonKey,
    required String deviceId,
    required String cropKey,
    required CurrentWindowSpec? current,
    required DateTime now,
    required FertilizationSignatureScan Function({
      required DateTime windowStart,
      DateTime? observeUntil,
    })
    scanner,
    SiteLearningStatus learning = SiteLearningStatus.unknown,
    String? epochId,
  }) {
    final Map<String, NutritionWindowRecord> byId = <String, NutritionWindowRecord>{
      for (final NutritionWindowRecord r in records)
        if (r.seasonKey == seasonKey) r.id: r,
    };
    final List<NutritionWindowRecord> changed = <NutritionWindowRecord>[];
    final List<NutritionWindowRecord> resolved = <NutritionWindowRecord>[];
    FertilizationSignatureScan? currentScan;
    NutritionWindowRecord? currentRecord;

    // ── 1. Ventana de la etapa actual ─────────────────────────────────────────
    if (current != null && current.nutrients.isNotEmpty) {
      final String id = NutritionWindowRecord.buildId(
        seasonKey: seasonKey,
        stageKey: current.stageKey,
        nutrients: current.nutrients,
      );
      NutritionWindowRecord record = byId[id] ??
          NutritionWindowRecord(
            id: id,
            seasonKey: seasonKey,
            deviceId: deviceId,
            cropKey: cropKey,
            stageKey: current.stageKey,
            stageLabelEs: current.stageLabelEs,
            nutrients: current.nutrients,
            isCritical: current.isCritical,
            openedAt: current.startedAt,
            outcome: NutritionWindowOutcome.open,
            epochId: epochId,
            windowLabelEs: current.labelEs,
          );

      // Lo descriptivo se refresca en cada pase: la identidad de la ventana
      // es etapa × nutrientes, pero su importancia o su etiqueta pueden
      // resolverse después del primer cuadro (variedad, guía curada, época
      // creada tras el primer barrido).
      record = record.copyWith(
        isCritical: current.isCritical,
        stageLabelEs: current.stageLabelEs,
        epochId: epochId,
        windowLabelEs: current.labelEs,
      );

      // Si la etapa volvió (p. ej. corrección de fecha de siembra), la ventana
      // se reabre y se vuelve a observar.
      if (record.outcome.isClosed &&
          record.outcome != NutritionWindowOutcome.attendedDetected) {
        record = record.copyWith(reopen: true, clearSignature: true);
      } else if (record.closedAt != null) {
        // Volvió la etapa mientras la ventana estaba en gracia de cierre.
        record = record.copyWith(reopen: true, outcome: record.outcome);
      }

      final FertilizationSignatureScan scan = scanner(
        windowStart: record.openedAt,
        observeUntil: null,
      );
      currentScan = scan;
      final NutritionWindowRecord next = _applyScan(
        record,
        scan,
        now: now,
        learning: learning,
      );
      if (!_same(next, byId[id])) changed.add(next);
      byId[id] = next;
      currentRecord = next;
    }

    // ── 2. Ventanas de etapas anteriores que siguen abiertas ──────────────────
    for (final NutritionWindowRecord r in byId.values.toList()) {
      if (currentRecord != null && r.id == currentRecord.id) continue;
      if (r.outcome.isClosed && r.resolvedAt != null) continue;

      // La etapa terminó: se fija el cierre (si aún no estaba) y se observa la
      // gracia antes de sentenciar.
      final DateTime closedAt = r.closedAt ?? now;
      final DateTime graceEnd = closedAt.add(const Duration(days: closeGraceDays));
      final FertilizationSignatureScan scan = scanner(
        windowStart: r.openedAt,
        observeUntil: graceEnd,
      );
      NutritionWindowRecord next = _applyScan(
        r.copyWith(closedAt: closedAt),
        scan,
        now: now,
        learning: learning,
      );

      if (next.outcome == NutritionWindowOutcome.attendedDetected) {
        // Atendida: queda resuelta en cuanto cierre su horizonte de respuesta
        // o termine la gracia, lo que ocurra primero.
        final bool following = next.isFollowingResponseAt(now) && now.isBefore(graceEnd);
        if (!following && next.resolvedAt == null) {
          next = next.copyWith(resolvedAt: now);
          resolved.add(next);
        }
      } else if (!now.isBefore(graceEnd)) {
        // Terminó la gracia sin firma compatible: sentencia honesta.
        final NutritionWindowOutcome outcome = _closingOutcome(scan, learning);
        next = next.copyWith(
          outcome: outcome,
          resolvedAt: now,
          evidenceEs: <String>[
            ...scan.evidenceEs,
            scan.summaryEs,
            if (outcome == NutritionWindowOutcome.unattended)
              'La ventana fue observable y no apareció una respuesta compatible '
                  'con fertilización antes de terminar.',
            if (outcome == NutritionWindowOutcome.inconclusive)
              'Observación insuficiente durante la ventana: no se afirma que '
                  'faltó manejo.',
            if (outcome == NutritionWindowOutcome.notComparable)
              'La ventana no se pudo comparar (${scan.observability.labelEs.toLowerCase()}).',
          ],
        );
        resolved.add(next);
      }

      if (!_same(next, r)) changed.add(next);
      byId[r.id] = next;
    }

    final List<NutritionWindowRecord> all = byId.values.toList()
      ..sort((a, b) => a.openedAt.compareTo(b.openedAt));

    return LedgerReconciliation(
      records: List<NutritionWindowRecord>.unmodifiable(all),
      changed: List<NutritionWindowRecord>.unmodifiable(changed),
      current: currentRecord,
      currentScan: currentScan,
      justResolved: List<NutritionWindowRecord>.unmodifiable(resolved),
    );
  }

  /// Aplica lo que el barrido vio a una ventana: detecta, mantiene o deja
  /// abierta. Nunca sentencia «sin evidencia» aquí; eso ocurre solo al
  /// terminar la gracia de cierre.
  static NutritionWindowRecord _applyScan(
    NutritionWindowRecord record,
    FertilizationSignatureScan scan, {
    required DateTime now,
    required SiteLearningStatus learning,
  }) {
    final FertilizationSignature? best = scan.best;
    if (best != null && best.isCompatible) {
      // Una firma ya detectada no se «desdetecta» porque un barrido posterior
      // baje un poco la confianza: se conserva la mejor.
      final FertilizationSignature? prior = record.signature;
      final FertilizationSignature keep =
          (prior != null && prior.isCompatible && prior.confidence01 > best.confidence01)
              ? prior
              : best;
      return record.copyWith(
        outcome: NutritionWindowOutcome.attendedDetected,
        signature: keep,
        observability: scan.observability,
        observedFraction: scan.observedFraction,
        evidenceEs: <String>[...scan.evidenceEs, ...keep.evidenceEs],
      );
    }
    if (record.outcome == NutritionWindowOutcome.attendedDetected) {
      // Ya estaba atendida; el barrido de hoy no la toca.
      return record.copyWith(
        observability: scan.observability,
        observedFraction: scan.observedFraction,
      );
    }
    return record.copyWith(
      outcome: NutritionWindowOutcome.open,
      signature: best, // puede ser una firma «posible», o null
      clearSignature: best == null,
      observability: scan.observability,
      observedFraction: scan.observedFraction,
      evidenceEs: <String>[...scan.evidenceEs, if (best != null) ...best.evidenceEs],
    );
  }

  /// Sentencia al terminar la gracia. Solo `unattended` cuando de verdad se
  /// pudo observar; lo demás protege al productor de una acusación sin datos.
  static NutritionWindowOutcome _closingOutcome(
    FertilizationSignatureScan scan,
    SiteLearningStatus learning,
  ) {
    switch (scan.observability) {
      case ScanObservability.noReadings:
      case ScanObservability.noEcChannel:
      case ScanObservability.tooDry:
      case ScanObservability.insufficientBaseline:
        return NutritionWindowOutcome.notComparable;
      case ScanObservability.ok:
        if (learning.isLearning) return NutritionWindowOutcome.notComparable;
        if (scan.hasPossibleSignature) return NutritionWindowOutcome.inconclusive;
        return scan.canJudgeAbsence
            ? NutritionWindowOutcome.unattended
            : NutritionWindowOutcome.inconclusive;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // LECTURAS DEL LIBRO
  // ═════════════════════════════════════════════════════════════════════════

  /// Ventanas importantes de la temporada que terminaron sin evidencia.
  static int unattendedCriticalCount(Iterable<NutritionWindowRecord> records) =>
      records.where((r) => r.penalizes).length;

  /// Factor ≤ 1 para el estado general y la proyección. Única vía por la que
  /// la nutrición baja un score.
  static double seasonScoreFactor(Iterable<NutritionWindowRecord> records) {
    final int n = unattendedCriticalCount(records);
    if (n <= 0) return 1.0;
    return math.max(
      kMinSeasonScoreFactor,
      math.pow(kUnattendedWindowScoreFactor, n).toDouble(),
    );
  }

  /// Respuesta habitual del sitio: mediana de la magnitud de firmas
  /// compatibles anteriores (misma época de instalación). Null si hay menos
  /// de dos (§15 «No comparable»).
  static double? typicalEcPeakMad(
    Iterable<NutritionWindowRecord> records, {
    String? epochId,
    String? excludeWindowId,
  }) {
    final List<double> values = <double>[];
    for (final NutritionWindowRecord r in records) {
      if (r.id == excludeWindowId) continue;
      // Otra época (o época desconocida) es otro sitio físico: no compara.
      if (epochId != null && r.epochId != epochId) continue;
      final FertilizationSignature? s = r.signature;
      if (s == null || !s.isCompatible) continue;
      if (s.ecPeakMad.isFinite) values.add(s.ecPeakMad);
    }
    if (values.length < 2) return null;
    return RobustStats.fromValues(values)?.median;
  }

  /// Ventana sentenciada sin evidencia en los últimos días, para el copy.
  static NutritionWindowRecord? recentlyUnattended(
    Iterable<NutritionWindowRecord> records,
    DateTime now,
  ) {
    NutritionWindowRecord? latest;
    for (final NutritionWindowRecord r in records) {
      if (!r.penalizes || r.resolvedAt == null) continue;
      if (now.difference(r.resolvedAt!).inDays > recentlyUnattendedDays) continue;
      if (latest == null || r.resolvedAt!.isAfter(latest.resolvedAt!)) latest = r;
    }
    return latest;
  }

  static bool _same(NutritionWindowRecord a, NutritionWindowRecord? b) {
    if (b == null) return false;
    return a.outcome == b.outcome &&
        a.isCritical == b.isCritical &&
        a.stageLabelEs == b.stageLabelEs &&
        a.windowLabelEs == b.windowLabelEs &&
        a.epochId == b.epochId &&
        a.closedAt == b.closedAt &&
        a.resolvedAt == b.resolvedAt &&
        a.observability == b.observability &&
        _close(a.observedFraction, b.observedFraction) &&
        a.responseVerdict == b.responseVerdict &&
        a.signature?.startedAt == b.signature?.startedAt &&
        a.signature?.lastJumpAt == b.signature?.lastJumpAt &&
        _close(a.signature?.confidence01, b.signature?.confidence01) &&
        a.evidenceEs.length == b.evidenceEs.length;
  }

  static bool _close(double? a, double? b) {
    if (a == null || b == null) return a == b;
    return (a - b).abs() < 0.005;
  }
}
