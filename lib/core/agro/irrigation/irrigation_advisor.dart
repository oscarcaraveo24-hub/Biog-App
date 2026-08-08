// lib/core/agro/irrigation/irrigation_advisor.dart
//
// Puente entre el estado de la app y el motor de riego.
//
// El motor ([IrrigationEngine]) es puro y no conoce el store, el runtime del
// cultivo ni la telemetría. Este adaptador es el único punto donde se traducen
// los objetos de la aplicación a las entradas del motor.
//
// Está separado a propósito: mantiene el motor probable sin montar media app,
// y concentra en un solo archivo la conversión más delicada del sistema —la de
// telemetría a lectura—, que es donde nacía el bug del cero sintetizado.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_engine.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_inputs.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';

class IrrigationAdvisor {
  const IrrigationAdvisor({IrrigationEngine engine = const IrrigationEngine()})
    : _engine = engine;

  final IrrigationEngine _engine;

  /// Produce la decisión de riego a partir del runtime del cultivo.
  ///
  /// [weather] nunca debe ser null: cuando no hay clima se pasa
  /// `AgronomicWeatherSnapshot.unavailable(...)`, para que el motor decida
  /// explícitamente qué hacer sin él en vez de recibir un hueco silencioso.
  IrrigationDecision adviseFromRuntime({
    required CropRuntimeSnapshot runtime,
    required AgronomicWeatherSnapshot weather,
    required DateTime now,
    DateTime? lastIrrigationAt,
    SoilContext soil = SoilContext.unknown,
    Calibration? calibration,
  }) {
    final live = runtime.live;
    final context = runtime.cropContext;

    final moisture = live == null
        ? const MoistureReading.absent()
        : MoistureReading.fromTelemetry(
            // La bandera manda. Si `hasSoilMoistureData` es false, el valor
            // numérico es el 0.0 que sintetiza `tryFromJson` y NO representa
            // suelo seco; la lectura se marca como ausente.
            rawPercent: live.soilMoisturePct,
            hasData: live.hasSoilMoistureData,
            measuredAt: live.timestamp,
            isCalibrated: _hasMoistureCalibration(calibration),
          );

    final scaleId = context?.cultivationScaleId?.trim().toLowerCase();
    final isPotted = _isPottedScale(scaleId);

    return _engine.decide(
      IrrigationEngineInput(
        now: now,
        moisture: moisture,
        weather: weather,
        deviceId: runtime.device?.id,
        cropId: runtime.cropKeyName,
        cropLabel: runtime.cropLabel,
        // Sin cultivo concreto no hay objetivo por etapa; el motor lo trata
        // como bloqueo de dato, no como suelo seco.
        isGenericMode: runtime.isGenericMode || !runtime.isPlanted,
        stageKey: runtime.stageResult?.stageKey,
        stageLabel: runtime.stageLabel,
        moistureTarget: runtime.targets?.moistureRaw,
        moistureBand: runtime.eval?.metrics[AgroMetricKey.soilMoisture]?.band,
        soil: soil,
        lastIrrigationAt: lastIrrigationAt,
        policy: isPotted ? IrrigationPolicy.potted : IrrigationPolicy.standard,
        isUnderCover: isPotted,
      ),
    );
  }

  /// Variante directa, sin runtime de cultivo. Útil en pruebas y en pantallas
  /// que ya tienen la telemetría y el objetivo resueltos.
  IrrigationDecision adviseFromTelemetry({
    required BioGTelemetry? telemetry,
    required AgroRange? moistureTarget,
    required AgronomicWeatherSnapshot weather,
    required DateTime now,
    String? deviceId,
    String? cropId,
    String? stageKey,
    String? stageLabel,
    bool isGenericMode = false,
    AgroBand? moistureBand,
    DateTime? lastIrrigationAt,
    SoilContext soil = SoilContext.unknown,
    IrrigationPolicy policy = IrrigationPolicy.standard,
    bool isUnderCover = false,
  }) {
    final moisture = telemetry == null
        ? const MoistureReading.absent()
        : MoistureReading.fromTelemetry(
            rawPercent: telemetry.soilMoisturePct,
            hasData: telemetry.hasSoilMoistureData,
            measuredAt: telemetry.timestamp,
          );

    return _engine.decide(
      IrrigationEngineInput(
        now: now,
        moisture: moisture,
        weather: weather,
        deviceId: deviceId,
        cropId: cropId,
        isGenericMode: isGenericMode,
        stageKey: stageKey,
        stageLabel: stageLabel,
        moistureTarget: moistureTarget,
        moistureBand: moistureBand,
        soil: soil,
        lastIrrigationAt: lastIrrigationAt,
        policy: policy,
        isUnderCover: isUnderCover,
      ),
    );
  }

  /// Coordenadas de la parcela para pedir el clima. Devuelve null cuando el
  /// usuario nunca capturó ubicación: sin coordenadas no hay pronóstico, y eso
  /// el motor lo tiene que saber.
  static ({double lat, double lon})? parcelCoordinates(
    DeviceCropContext? context,
  ) {
    final lat = context?.geoLat;
    final lon = context?.geoLng;
    if (lat == null || lon == null) return null;
    if (!lat.isFinite || !lon.isFinite) return null;
    if (lat == 0 && lon == 0) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    return (lat: lat, lon: lon);
  }

  static bool _isPottedScale(String? scaleId) {
    if (scaleId == null || scaleId.isEmpty) return false;
    return scaleId.contains('pot') || scaleId.contains('maceta');
  }

  static bool _hasMoistureCalibration(Calibration? calibration) {
    if (calibration == null) return false;
    return calibration.moistureDryRaw != null &&
        calibration.moistureWetRaw != null;
  }
}
