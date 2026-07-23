import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/agave/agave_assets.dart';
import 'package:bio_g/core/crops/agave/agave_lifecycle.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Resolver de etapa del Maguey / Agave (modo `establishment_maintenance`).
///
/// FUENTE ÚNICA que alimenta a las pantallas. Las pantallas NUNCA leen
/// `cropContext.ornamentalStageId` crudo: un `unknown` guardado dejaría la
/// planta clavada en "Etapa por confirmar" para siempre. Aquí un `unknown`
/// guardado NO cuenta como etapa: se re-estima por la fecha, así que los
/// contextos viejos se AUTO-REPARAN al abrir la app (Doc A §7.3, §13.3).
///
/// El maguey no tiene día terminal: `maintenance` (Maduro y estable) permanece
/// abierto indefinidamente (Doc A §7.9). El tallo floral / quiote NO se infiere
/// aquí: es un evento manual y no cambia el stageId.
class AgaveStageResolver {
  const AgaveStageResolver._();

  static CropStageResult resolve({
    required DeviceCropContext context,
    DateTime? today,
  }) {
    final DateTime now = today ?? DateTime.now();

    // Los campos perennes solo se leen como compatibilidad de ENTRADA (la tabla
    // remota todavía usa los slots perennes como puente ornamental).
    final String? storedStage =
        context.ornamentalStageId ?? context.perennialStateId;

    final bool hasStoredStage =
        storedStage != null &&
        storedStage.trim().isNotEmpty &&
        normalizeAgaveStageId(storedStage) != AgaveStageIds.unknown;

    String stageId;
    double confidence;

    if (hasStoredStage) {
      stageId = normalizeAgaveStageId(storedStage);
      confidence =
          context.ornamentalStageConfidence ??
          agaveStageConfidence(
            stageId: stageId,
            anchorDate:
                context.ornamentalAnchorDate ?? context.perennialAnchorDate,
            anchorTypeId:
                context.ornamentalAnchorTypeId ?? context.perennialAnchorTypeId,
          );
    } else {
      // Sin etapa guardada (o guardada como 'unknown'): se resuelve con la misma
      // FUENTE ÚNICA que usa el wizard, para que la etapa mostrada SIEMPRE
      // corresponda con lo que el usuario eligió.
      final estimate = resolveAgaveSetupStage(
        intentId: context.lifecycleStatus == CropLifecycleStatus.planned
            ? AgaveSetupIntentIds.plannedPlant
            : AgaveSetupIntentIds.alreadyPlanted,
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

    // Eje temporal: días desde que lo plantaste. No es "días desde siembra"
    // (no se siembra), pero ocupa el mismo campo del contrato compartido para
    // que la SeedsScreen muestre "Día: 72" igual que en frijol.
    final DateTime? anchor =
        context.ornamentalAnchorDate ??
        context.perennialAnchorDate ??
        context.sowingDate;
    final int? daysSincePlanting = anchor == null
        ? null
        : now.difference(DateTime(anchor.year, anchor.month, anchor.day)).inDays;

    return CropStageResult(
      stageKey: stageId,
      stageLabelEs: agaveStageDisplayName(stageId),
      // Sin día terminal: el mantenimiento no cierra el ciclo (Doc A §7.9).
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: AgaveAssets.stageImageOrNeutral(stageId),
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

  /// Pie de ayuda, en lenguaje de agricultor. Sin jerga: nada de "microciclo",
  /// "etapa fenológica" ni "confianza: 0.25" (Doc A §11.2).
  static String _helperCaption({
    required DeviceCropContext context,
    required DateTime now,
    required String stageId,
    required double confidence,
  }) {
    final parts = <String>[agaveStagePriorityText(stageId)];

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
