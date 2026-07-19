import 'package:bio_g/core/crops/cactus/cactus_assets.dart';
import 'package:bio_g/core/crops/cactus/cactus_lifecycle.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/models/device_crop_context.dart';

/// Resolver de etapa para el Cactus ornamental (modo establishment_maintenance).
///
/// Espejo de `PerennialStageResolver` pero sin cosecha ni producción: el cactus
/// no tiene un día terminal de ciclo. Si la etapa está guardada (elección del
/// usuario en el wizard), se usa; si solo hay una fecha de plantación/cambio de
/// maceta, solo se propone instalación/raíz dentro de una ventana plausible
/// (doc 01 §4.7, §5.2); una fecha antigua queda `unknown` y nunca se convierte
/// por sí sola en mantenimiento. `maintenance` permanece abierto
/// indefinidamente cuando fue confirmado (doc 03 §0.1).
class CactusStageResolver {
  const CactusStageResolver._();

  static CropStageResult resolve({
    required DeviceCropContext context,
    DateTime? today,
  }) {
    final DateTime now = today ?? DateTime.now();

    // Los campos perennes solo se leen como compatibilidad de entrada para
    // contextos creados por la integración provisional. Toda salida nueva usa
    // los campos ornamentales de DeviceCropContext.
    final String? storedStage =
        context.ornamentalStageId ?? context.perennialStateId;

    // Un `unknown` guardado NO cuenta como etapa: es justo lo que producía el
    // bug anterior (el wizard persistía 'unknown' y la planta se quedaba pegada
    // en "Etapa por confirmar" para siempre). Si lo que hay guardado es
    // 'unknown', se vuelve a estimar por la fecha. Así los contextos ya
    // guardados con el bug se auto-reparan al abrir la app.
    final bool hasStoredStage =
        storedStage != null &&
        storedStage.trim().isNotEmpty &&
        normalizeCactusStageId(storedStage) != CactusStageIds.unknown;

    String stageId;
    double confidence;

    if (hasStoredStage) {
      // El usuario/onboarding fijó la etapa: se respeta y su confianza deriva
      // del ancla (doc 05 §5.3).
      stageId = normalizeCactusStageId(storedStage);
      confidence =
          context.ornamentalStageConfidence ??
          cactusStageConfidence(
            stageId: stageId,
            anchorDate:
                context.ornamentalAnchorDate ?? context.perennialAnchorDate,
            anchorTypeId:
                context.ornamentalAnchorTypeId ?? context.perennialAnchorTypeId,
          );
    } else {
      // Sin etapa guardada (o guardada como 'unknown'): se resuelve con la misma
      // fuente única que usa el wizard, para que la etapa mostrada SIEMPRE
      // corresponda con lo que el usuario eligió.
      final estimate = resolveCactusSetupStage(
        intentId: context.lifecycleStatus == CropLifecycleStatus.planned
            ? CactusSetupIntentIds.plannedPlant
            : CactusSetupIntentIds.alreadyPlanted,
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

    // El cactus SÍ tiene un eje temporal: los días desde que lo plantaste.
    // No es "días desde siembra" (no se siembra), pero ocupa el mismo campo del
    // contrato compartido para que la SeedsScreen pueda mostrar "Día: 72" igual
    // que en frijol, en vez de un genérico "Estado: Activo".
    final DateTime? anchor =
        context.ornamentalAnchorDate ??
        context.perennialAnchorDate ??
        context.sowingDate;
    final int? daysSincePlanting = anchor == null
        ? null
        : now.difference(DateTime(anchor.year, anchor.month, anchor.day)).inDays;

    return CropStageResult(
      stageKey: stageId,
      stageLabelEs: cactusStageDisplayName(stageId),
      // El cactus no tiene día terminal: el mantenimiento no cierra el ciclo.
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: CactusAssets.stageImageOrNeutral(stageId),
      helperCaption: _helperCaption(
        context: context,
        now: now,
        stageId: stageId,
        confidence: confidence,
      ),
      // Días desde la plantación (negativo/null si aún no la planta).
      daySinceSowing: (daysSincePlanting != null && daysSincePlanting >= 0)
          ? daysSincePlanting
          : null,
      stageProgressPct: null,
      productiveState: null,
      productiveStateLabelEs: null,
    );
  }

  /// Pie de ayuda, en lenguaje de agricultor. Sin jerga: nada de "microciclo
  /// hídrico", "seguimiento ornamental" ni "confianza: 0.25".
  static String _helperCaption({
    required DeviceCropContext context,
    required DateTime now,
    required String stageId,
    required double confidence,
  }) {
    final parts = <String>[cactusStagePriorityText(stageId)];

    final anchor = context.ornamentalAnchorDate ?? context.perennialAnchorDate;
    if (anchor != null) {
      final days = now
          .difference(DateTime(anchor.year, anchor.month, anchor.day))
          .inDays;
      if (days > 0) {
        parts.add('la plantaste hace $days días');
      } else if (days == 0) {
        parts.add('la plantaste hoy');
      } else {
        parts.add('la plantas en ${days.abs()} días');
      }
    }

    return parts.join(' · ');
  }
}
