// lib/core/agro/agro_types.dart
import 'package:bio_g/models/biog_telemetry.dart';

/// Métricas que el motor interpreta (solo “controlable del suelo” + NPK).
enum AgroMetricKey { soilMoisture, soilTemp, ph, ec, resistance, n, p, k }

/// Banda agronómica para UI.
enum AgroBand { low, optimal, high, critical, unknown }

/// Rango con zona óptima y zonas de degradación.
///
/// Interpretación:
/// - value < lowMax          -> critical (muy bajo)
/// - lowMax..optimalMin      -> low
/// - optimalMin..optimalMax  -> optimal
/// - optimalMax..highMin     -> high
/// - value > highMin         -> critical (muy alto)
class AgroRange {
  const AgroRange({
    required this.lowMax,
    required this.optimalMin,
    required this.optimalMax,
    required this.highMin,
  });

  final double lowMax;
  final double optimalMin;
  final double optimalMax;
  final double highMin;
}

class AgroMetricEval {
  const AgroMetricEval({
    required this.band,
    required this.score01,
    required this.labelEs,
    this.value,
  });

  final AgroBand band;
  final double score01; // 0..1
  final String labelEs; // “Bajo/Óptimo/Alto/Crítico/—”
  final double? value;
}

class AgroEvalResult {
  const AgroEvalResult({
    required this.soilControlScore01,
    required this.metrics,
    required this.alerts,
    required this.suggestedAlertKeys,
  });

  final double soilControlScore01; // 0..1
  final Map<AgroMetricKey, AgroMetricEval> metrics;

  /// Alertas ya construidas (listas para UI/panel).
  final List<BioGAlert> alerts;

  /// Llaves internas para debug/telemetría/anti-spam.
  final List<String> suggestedAlertKeys;
}

/// Calibración por dispositivo (opcional) — v1 simple pero útil.
class Calibration {
  const Calibration({
    this.moistureDryRaw,
    this.moistureWetRaw,
    this.nMinRaw,
    this.nMaxRaw,
    this.pMinRaw,
    this.pMaxRaw,
    this.kMinRaw,
    this.kMaxRaw,
    this.resistanceMinRaw,
    this.resistanceMaxRaw,
  });

  // Humedad: 2 puntos por instalación (raw% del sensor).
  final double? moistureDryRaw;
  final double? moistureWetRaw;

  // NPK: clamps por sensor/instalación (ppm reales).
  final double? nMinRaw;
  final double? nMaxRaw;
  final double? pMinRaw;
  final double? pMaxRaw;
  final double? kMinRaw;
  final double? kMaxRaw;

  // Resistencia: si no es 0..100 real.
  final double? resistanceMinRaw;
  final double? resistanceMaxRaw;
}

/// Estado de “anti-spam” para no repetir la misma alerta cada tick.
/// Esto lo puedes guardar en tu Store o en tu Repository.
class AlertsState {
  const AlertsState({this.lastByType = const {}});

  final Map<BioGAlertType, DateTime> lastByType;

  AlertsState copyWith({Map<BioGAlertType, DateTime>? lastByType}) =>
      AlertsState(lastByType: lastByType ?? this.lastByType);
}

/// Resultado de construir alertas con estado actualizado.
class AlertsBuildResult {
  const AlertsBuildResult({required this.alerts, required this.state});

  final List<BioGAlert> alerts;
  final AlertsState state;
}
