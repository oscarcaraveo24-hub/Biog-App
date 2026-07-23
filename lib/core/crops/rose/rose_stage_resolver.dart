import 'package:bio_g/core/crops/rose/rose_assets.dart';
import 'package:bio_g/core/crops/rose/rose_lifecycle.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Resolver de etapa para el Rosal (modo `recurring_bloom`).
///
/// A diferencia de las ornamentales de establecimiento, el rosal NO progresa por
/// fecha hacia un estado "estable": tras el establecimiento entra en un ciclo de
/// floración recurrente cuyo estado (brotando / botones / floración /
/// post-floración / reposo) NO puede inferirse por la fecha (Doc A §3.3).
///
/// Lógica:
///  - Si hay un estado guardado (elegido por el usuario en el wizard visual), se
///    respeta. Un `unknown` guardado NO cuenta: se re-estima por fecha (auto-
///    reparación de contextos con el bug histórico).
///  - Sin estado guardado, solo se estima el ESTABLECIMIENTO por fecha
///    (recién plantado / echando raíz). Pasado el establecimiento sin estado
///    confirmado, queda `unknown` para que el usuario lo confirme visualmente.
///  - Nunca hay día terminal: `expectedDaysToEnd` = 0.
class RoseStageResolver {
  const RoseStageResolver._();

  static CropStageResult resolve({
    required DeviceCropContext context,
    DateTime? today,
  }) {
    final DateTime now = today ?? DateTime.now();

    // El estado del rosal vive en los campos ornamentales de DeviceCropContext
    // (reutilizados por el modo recurring_bloom). Se leen los perennes solo como
    // compatibilidad de entrada de integraciones provisionales.
    final String? storedStage =
        context.ornamentalStageId ?? context.perennialStateId;

    // Un `unknown` guardado NO cuenta como etapa (auto-reparación).
    final bool hasStoredStage =
        storedStage != null &&
        storedStage.trim().isNotEmpty &&
        normalizeRoseStageId(storedStage) != RoseStageIds.unknown;

    String stageId;
    double confidence;

    if (hasStoredStage) {
      stageId = normalizeRoseStageId(storedStage);
      confidence =
          context.ornamentalStageConfidence ??
          roseStageConfidence(
            stageId: stageId,
            anchorDate:
                context.ornamentalAnchorDate ?? context.perennialAnchorDate,
            anchorTypeId:
                context.ornamentalAnchorTypeId ?? context.perennialAnchorTypeId,
          );
    } else {
      // Sin estado guardado (o guardado 'unknown'): misma fuente única que el
      // wizard. Solo estima el establecimiento por fecha; el resto queda
      // 'unknown' para confirmación visual.
      final estimate = resolveRoseSetupStage(
        intentId: context.lifecycleStatus == CropLifecycleStatus.planned
            ? RoseSetupIntentIds.plannedPlant
            : RoseSetupIntentIds.alreadyPlanted,
        plantingDate:
            context.ornamentalAnchorDate ??
            context.perennialAnchorDate ??
            context.sowingDate,
        now: now,
        profileId: context.profileId,
      );
      stageId = estimate.stageId;
      confidence = estimate.confidence;
    }

    // Eje temporal: días desde que lo plantaste (no es "días desde siembra").
    final DateTime? anchor =
        context.ornamentalAnchorDate ??
        context.perennialAnchorDate ??
        context.sowingDate;
    final int? daysSincePlanting = anchor == null
        ? null
        : now.difference(DateTime(anchor.year, anchor.month, anchor.day)).inDays;

    return CropStageResult(
      stageKey: stageId,
      stageLabelEs: roseStageDisplayName(stageId),
      // El rosal no tiene día terminal: la floración recurrente no cierra ciclo.
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: RoseAssets.stageImageOrNeutral(stageId),
      helperCaption: _helperCaption(
        context: context,
        now: now,
        stageId: stageId,
        confidence: confidence,
      ),
      daySinceSowing: (daysSincePlanting != null && daysSincePlanting >= 0)
          ? daysSincePlanting
          : null,
      stageProgressPct: null,
      productiveState: null,
      productiveStateLabelEs: null,
    );
  }

  static String _helperCaption({
    required DeviceCropContext context,
    required DateTime now,
    required String stageId,
    required double confidence,
  }) {
    final parts = <String>[roseStagePriorityText(stageId)];

    final anchor = context.ornamentalAnchorDate ?? context.perennialAnchorDate;
    if (anchor != null) {
      final days = now
          .difference(DateTime(anchor.year, anchor.month, anchor.day))
          .inDays;
      if (days > 0) {
        parts.add('lo plantaste hace $days días');
      } else if (days == 0) {
        parts.add('lo plantaste hoy');
      } else {
        parts.add('lo plantas en ${days.abs()} días');
      }
    }

    return parts.join(' · ');
  }
}
