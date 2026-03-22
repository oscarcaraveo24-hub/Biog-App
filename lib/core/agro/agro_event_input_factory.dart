import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/event_engine.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';

class AgroEventInputFactory {
  const AgroEventInputFactory._();

  static Map<String, AgroBand> safeCurrentBands(AgroEvalResult? eval) {
    if (eval == null) return const <String, AgroBand>{};

    return <String, AgroBand>{
      EventMetricKeys.soilMoisture:
          eval.metrics[AgroMetricKey.soilMoisture]?.band ?? AgroBand.unknown,
      EventMetricKeys.ph:
          eval.metrics[AgroMetricKey.ph]?.band ?? AgroBand.unknown,
      EventMetricKeys.resistance:
          eval.metrics[AgroMetricKey.resistance]?.band ?? AgroBand.unknown,
      EventMetricKeys.soilTemp:
          eval.metrics[AgroMetricKey.soilTemp]?.band ?? AgroBand.unknown,
      EventMetricKeys.n:
          eval.metrics[AgroMetricKey.n]?.band ?? AgroBand.unknown,
      EventMetricKeys.p:
          eval.metrics[AgroMetricKey.p]?.band ?? AgroBand.unknown,
      EventMetricKeys.k:
          eval.metrics[AgroMetricKey.k]?.band ?? AgroBand.unknown,
    };
  }

  static DateTime? eventContextDate(
    SeedInstall? seed,
    DeviceCropContext? cropContext,
  ) {
    if (cropContext != null) {
      switch (cropContext.lifecycleStatus) {
        case CropLifecycleStatus.planned:
          return cropContext.plannedSowingDate;
        case CropLifecycleStatus.planted:
          return cropContext.sowingDate;
        case CropLifecycleStatus.fallow:
          return null;
      }
    }

    if (seed == null) return null;

    switch (seed.status) {
      case SowingStatus.planned:
        return seed.plannedSowingDate;
      case SowingStatus.planted:
        return seed.sowingDate;
      case SowingStatus.skip:
        return null;
    }
  }

  static EventEngineInput build({
    required DateTime timestamp,
    required String? deviceId,
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
    required BioGTelemetry? live,
    required AgroEvalResult? effectiveEval,
    required CropStageResult? stageResult,
    required bool isGenericMode,
    List<EventTelemetryPoint> history = const <EventTelemetryPoint>[],
    Map<String, AgroBand> previousBands = const <String, AgroBand>{},
  }) {
    return EventEngineInput(
      timestamp: timestamp,
      deviceId: deviceId,
      seedProfileId: cropContext?.profileId ?? seed?.profileId,
      seedAlias: cropContext?.varietyAlias ?? seed?.varietyAlias,
      sowingDate: eventContextDate(seed, cropContext),
      isGenericMode: isGenericMode,
      stageKey: stageResult?.stageKey,
      stageLabel: stageResult?.stageLabelEs,
      previousStageKey: null,
      previousStageLabel: null,
      soilMoisture: live?.soilMoisturePct,
      ph: live?.ph,
      resistance: live?.resistance,
      soilTemp: live?.soilTempC,
      n: live?.n.toDouble(),
      p: live?.p.toDouble(),
      k: live?.k.toDouble(),
      currentBands: isGenericMode
          ? const <String, AgroBand>{}
          : safeCurrentBands(effectiveEval),
      previousBands: previousBands,
      history: history,
    );
  }
}
