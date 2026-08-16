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
import 'package:bio_g/core/agro/water/moisture_target_resolver.dart';
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
            // La humedad de este sensor viene calibrada de fábrica y el modelo
            // de agua declara que NO necesita calibración de usuario. La rama
            // seco/mojado se retiró de [Calibration] —tenía dos consumidores y
            // cero productores—, así que aquí no hay nada que consultar: este
            // indicador describe una calibración de USUARIO que no existe ni
            // debe existir para este canal.
            isCalibrated: false,
          );


    // ── El contexto de suelo ya viene resuelto ──────────────────────────────
    //
    // Hasta aquí, este parámetro nunca se pasaba: el coordinador omitía `soil:`
    // y el motor recibía `SoilContext.unknown` de forma permanente. Con eso,
    // `supportsWaterBalance` no podía ser true nunca, y la lámina —que estaba
    // escrita, probada y con su hueco reservado en el modelo— no tenía forma
    // de encenderse.
    //
    // El que llega por parámetro gana, para que las pruebas puedan inyectar uno.
    final resolved = runtime.resolvedMoisture;
    final SoilContext effectiveSoil = soil.isEmpty
        ? (resolved?.soilContext ?? soil)
        : soil;

    // ── «¿Esto es maceta?» se responde una sola vez ─────────────────────────
    //
    // Antes había dos respuestas en la misma decisión: aquí una comparación de
    // subcadenas sobre `cultivationScaleId`, y en `SoilProfileResolver` la
    // jerarquía equipo → escala. Un BIO-G Maceta cuya escala declarada dijera
    // «campo» recibía política de suelo abierto Y constantes hidráulicas de
    // sustrato en el mismo `IrrigationEngineInput`.
    //
    // Ahora manda el medio ya resuelto, que es quien sabe que el hardware pesa
    // más que la escala. El respaldo por escala solo actúa si no hay medio
    // resuelto —que en la práctica no ocurre—.
    final isPotted =
        resolved?.texture.isSubstrate ??
        _isPottedScale(context?.cultivationScaleId?.trim().toLowerCase());

    var decision = _engine.decide(
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
        // `runtime.targets.moistureRaw` YA es la banda derivada de la textura:
        // se sobrescribe en el centro, en `CropRuntimeResolver`. El
        // `resolved.range` de respaldo cubre el caso sin objetivos de etapa
        // (modo guía o sin cultivo), donde antes no había banda ninguna.
        moistureTarget: runtime.targets?.moistureRaw ?? resolved?.range,
        moistureBand: runtime.eval?.metrics[AgroMetricKey.soilMoisture]?.band,
        soil: effectiveSoil,
        lastIrrigationAt: lastIrrigationAt,
        policy: isPotted ? IrrigationPolicy.potted : IrrigationPolicy.standard,
        isUnderCover: isPotted,
      ),
    );

    if (resolved != null) {
      decision = _withSoilContext(
        decision: decision,
        resolved: resolved,
        live: live,
      );
    }

    return decision;
  }

  /// Adjunta a la decisión lo que hace falta para explicarla y auditarla: la
  /// lámina en banda, las limitaciones declaradas, la penalización de confianza
  /// y el contexto de suelo completo.
  ///
  /// Es la capa intermedia del historial de tres capas. La telemetría es
  /// inmutable porque es un hecho físico; **esto también**, porque se adjunta a
  /// la decisión en el momento de tomarla. Si el productor corrige su textura
  /// dos meses después, la gráfica puede reinterpretarse con la configuración
  /// vigente; la decisión que se tomó aquel martes, no. Si BIO-G dijo «riega»
  /// con la información que tenía ese martes, el historial debe poder mostrar
  /// exactamente eso, junto con qué supuestos usó y cuánta confianza declaró.
  IrrigationDecision _withSoilContext({
    required IrrigationDecision decision,
    required ResolvedMoistureTarget resolved,
    required BioGTelemetry? live,
  }) {
    // Solo la limitación de TEXTURA lleva el código `soilProfileMissing`.
    // Volcar la lista entera bajo ese código etiquetaría «sin cultivo
    // declarado» y «no sabemos cómo riegas» como problemas de perfil de suelo,
    // que no lo son —y el motor ya declara las suyas—.
    List<IrrigationReason> reasons = decision.reasons;
    final String? textureLimitation = resolved.textureLimitationEs;
    if (textureLimitation != null &&
        !reasons.any((r) => r.textEs == textureLimitation)) {
      reasons = List<IrrigationReason>.unmodifiable(<IrrigationReason>[
        ...reasons,
        IrrigationReason(
          code: IrrigationReasonCode.soilProfileMissing,
          textEs: textureLimitation,
          isLimitation: true,
        ),
      ]);
    }

    // ── La lámina solo cuando hay algo que aplicar ──────────────────────────
    //
    // Tres condiciones, todas necesarias:
    //
    //  · lectura de humedad presente —un 0.0 sintetizado no es suelo seco—;
    //  · la decisión efectivamente recomienda regar. `depthFor` devuelve un
    //    número para CUALQUIER lectura por debajo de capacidad de campo, pero
    //    la banda «no hace falta regar» va de `optimalMin` a `optimalMax`: sin
    //    esta condición, una decisión de «no regar, humedad dentro del
    //    objetivo» habría llegado a la pantalla con una tarjeta que dice
    //    «riega entre 8 y 20 mm», y ese número se habría guardado en el
    //    registro auditable;
    //  · y la decisión no está bloqueada por dato ausente o vencido.
    IrrigationDepthEstimate? depth;
    final bool wantsWater = decision.action == IrrigationAction.regar;
    if (wantsWater && live != null && live.hasSoilMoistureData) {
      final d = MoistureTargetResolver.depthFor(
        vwcPct: live.soilMoisturePct,
        target: resolved,
      );
      if (d != null) {
        depth = IrrigationDepthEstimate(
          millimeters: d.grossMm,
          lowMillimeters: d.needsBand ? d.lowMm : null,
          highMillimeters: d.needsBand ? d.highMm : null,
          includesSystemLosses: d.includesSystemLosses,
          basisEs:
              'Calculada con tierra ${resolved.texture.shortLabelEs.toLowerCase()} '
              '(campo ${resolved.soilContext.fieldCapacityPct?.toStringAsFixed(0)} %, '
              'marchitez ${resolved.soilContext.wiltingPointPct?.toStringAsFixed(0)} %) '
              'y raíz de ${resolved.soilContext.rootDepthCm?.toStringAsFixed(0)} cm.',
          litersPerSquareMeter: d.litersPerSquareMeter,
          // En maceta y huerto los milímetros no significan nada al productor:
          // la pregunta real es cuántos litros por planta. La interfaz elige la
          // unidad; aquí se ofrecen las dos.
          litersPerPlant: d.litersPerPlant,
        );
      }
    }

    // La confianza NO se toca aquí. La penalización por textura de respaldo la
    // aplica el propio motor, antes de sus compuertas —el mínimo para
    // recomendar y el umbral de confirmación—, porque restarla después dejaba
    // pasar un `regar` con confianza por debajo del mínimo y un
    // `requiresConfirmation` en falso cuando ya debía estar en verdadero.
    return decision.copyWith(
      reasons: reasons,
      depth: depth,
      evidence: <String, Object?>{
        ...decision.evidence,
        'soilDecision': <String, Object?>{
          ...resolved.toDecisionContextJson(),
          // Cuál de los CINCO estados era. Sin esto, el historial no puede
          // distinguir «drenando» de «encharcado» sobre la misma lectura, que
          // es precisamente la confusión que generaba la alarma falsa.
          if (live != null && live.hasSoilMoistureData)
            'moistureState': resolved.stateFor(live.soilMoisturePct).name,
        },
      },
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
            // Mismo criterio que `adviseFromRuntime`: sin esto, las dos
            // entradas grababan valores opuestos de `moistureCalibrated` en el
            // registro auditable para el mismo sensor.
            isCalibrated: false,
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

}
