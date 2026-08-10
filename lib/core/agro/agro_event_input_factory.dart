import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/event_engine.dart';
import 'package:bio_g/core/agro/event_engine_rules_resolver.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';

class AgroEventInputFactory {
  const AgroEventInputFactory._();

  /// Bandas actuales listas para el motor de eventos.
  ///
  /// [live] es opcional pero **debe pasarse** siempre que exista telemetría:
  /// es lo que permite anular una banda calculada sobre un dato que en
  /// realidad no llegó.
  ///
  /// El motor de score evalúa el `double` crudo de `BioGTelemetry`, que vale
  /// 0.0 cuando la métrica vino ausente. Ese 0.0 cae por debajo del umbral
  /// bajo y produce `AgroBand.critical`, que aguas abajo se convierte en
  /// "Riego recomendado" con severidad crítica sobre un sensor inexistente.
  /// Aquí esa banda se degrada a `unknown`, que el motor de eventos ya sabe
  /// tratar como "no recomendar nada".
  static Map<String, AgroBand> safeCurrentBands(
    AgroEvalResult? eval, {
    BioGTelemetry? live,
  }) {
    if (eval == null) return const <String, AgroBand>{};

    AgroBand bandFor(AgroMetricKey key, bool hasData) {
      if (!hasData) return AgroBand.unknown;
      return eval.metrics[key]?.band ?? AgroBand.unknown;
    }

    // Sin telemetría no hay banderas que consultar: se conserva el
    // comportamiento anterior para no alterar a los llamadores que solo
    // tienen la evaluación.
    final bool hasLive = live != null;

    return <String, AgroBand>{
      EventMetricKeys.soilMoisture: bandFor(
        AgroMetricKey.soilMoisture,
        !hasLive || live.hasSoilMoistureData,
      ),
      EventMetricKeys.ph: bandFor(
        AgroMetricKey.ph,
        !hasLive || live.hasPhData,
      ),
      EventMetricKeys.resistance: bandFor(
        AgroMetricKey.resistance,
        !hasLive || live.hasResistanceData,
      ),
      EventMetricKeys.soilTemp: bandFor(
        AgroMetricKey.soilTemp,
        !hasLive || live.hasSoilTempData,
      ),
      EventMetricKeys.n: bandFor(
        AgroMetricKey.n,
        !hasLive || live.hasNitrogenData,
      ),
      EventMetricKeys.p: bandFor(
        AgroMetricKey.p,
        !hasLive || live.hasPhosphorusData,
      ),
      EventMetricKeys.k: bandFor(
        AgroMetricKey.k,
        !hasLive || live.hasPotassiumData,
      ),
    };
  }

  /// Devuelve el set de claves de nutrientes cuya interpretación es exceso.
  static Set<String> safeExcessNutrientKeys(AgroEvalResult? eval) {
    if (eval == null) return const <String>{};
    final keys = <String>{};
    if (eval.metrics[AgroMetricKey.n]?.priorityLabel?.isExcessSide == true) {
      keys.add(EventMetricKeys.n);
    }
    if (eval.metrics[AgroMetricKey.p]?.priorityLabel?.isExcessSide == true) {
      keys.add(EventMetricKeys.p);
    }
    if (eval.metrics[AgroMetricKey.k]?.priorityLabel?.isExcessSide == true) {
      keys.add(EventMetricKeys.k);
    }
    return keys;
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
    String? previousStageKey,
    String? previousStageLabel,
    // Autoridad unica del riego. Opcional a proposito: quien no la tenga
    // simplemente no obtiene eventos de riego, en vez de deducirlos mal.
    IrrigationDecision? irrigationDecision,
  }) {
    final String? cropId = cropContext?.cropId ?? seed?.cropKey;

    return EventEngineInput(
      timestamp: timestamp,
      deviceId: deviceId,
      cropId: cropId,
      seedProfileId: cropContext?.profileId ?? seed?.profileId,
      seedAlias: cropContext?.varietyAlias ?? seed?.varietyAlias,
      sowingDate: eventContextDate(seed, cropContext),
      isGenericMode: isGenericMode,
      stageKey: stageResult?.stageKey,
      stageLabel: stageResult?.stageLabelEs,
      previousStageKey: previousStageKey,
      previousStageLabel: previousStageLabel,
      // Banderas de presencia en TODAS las métricas, no solo en NPK.
      //
      // Antes, N/P/K se protegían con `hasXData` y humedad, pH, resistencia y
      // temperatura de suelo se pasaban crudas —líneas contiguas del mismo
      // archivo—. Como `BioGTelemetry` rellena con 0.0 lo que llega ausente,
      // un sensor de humedad desconectado entraba al motor como 0 %, caía por
      // debajo del umbral bajo y disparaba "Riego recomendado" con severidad
      // crítica sobre un sensor que no existe. El `null` es la única forma de
      // que el motor sepa que no hay dato.
      soilMoisture: live?.hasSoilMoistureData == true
          ? live!.soilMoisturePct
          : null,
      ph: live?.hasPhData == true ? live!.ph : null,
      resistance: live?.hasResistanceData == true ? live!.resistance : null,
      soilTemp: live?.hasSoilTempData == true ? live!.soilTempC : null,
      // Aire con bandera, igual que suelo y NPK. Sin esto, un sensor de aire
      // ausente entra como 0 °C y dispara "Riesgo de helada" con severidad
      // crítica: `frostThresholdC` vale entre 0 y 7 °C según el cultivo, así
      // que `0.0 <= 0.0` se cumple. Lo mismo con humedad de aire = 0 % y el
      // umbral de humedad ambiente baja (20-40 %).
      airTemp: live?.hasAirTempData == true ? live!.airTempC : null,
      airHumidity: live?.hasAirHumidityData == true
          ? live!.airHumidityPct
          : null,
      n: live?.hasNitrogenData == true ? live!.n.toDouble() : null,
      p: live?.hasPhosphorusData == true ? live!.p.toDouble() : null,
      k: live?.hasPotassiumData == true ? live!.k.toDouble() : null,
      currentBands: isGenericMode
          ? const <String, AgroBand>{}
          : safeCurrentBands(effectiveEval, live: live),
      excessNutrientKeys: isGenericMode
          ? const <String>{}
          : safeExcessNutrientKeys(effectiveEval),
      previousBands: previousBands,
      history: history,
      rules: EventEngineRulesResolver.resolve(
        cropId: cropId,
        stageKey: stageResult?.stageKey,
      ),
      irrigationDecision: irrigationDecision,
    );
  }
}
