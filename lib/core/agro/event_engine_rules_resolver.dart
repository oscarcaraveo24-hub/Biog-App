import 'package:bio_g/core/agro/event_engine.dart';

class EventEngineRulesResolver {
  const EventEngineRulesResolver._();

  static EventEngineRules resolve({
    required String? cropId,
    required String? stageKey,
  }) {
    final crop = (cropId ?? '').trim().toLowerCase();
    final stage = (stageKey ?? '').trim().toLowerCase();

    if (crop == 'maize') {
      if (_containsAny(stage, const <String>['tass', 'flower'])) {
        return const EventEngineRules(
          frostThresholdC: 6.0,
          highAirTempThresholdC: 36.0,
          lowAirHumidityThresholdPct: 25.0,
          highAirHumidityThresholdPct: 88.0,
        );
      }
      return const EventEngineRules(
        frostThresholdC: 4.0,
        highAirTempThresholdC: 39.0,
        lowAirHumidityThresholdPct: 20.0,
        highAirHumidityThresholdPct: 90.0,
      );
    }

    if (crop == 'bean') {
      if (_containsAny(stage, const <String>['flower', 'pod', 'grain'])) {
        return const EventEngineRules(
          frostThresholdC: 7.0,
          highAirTempThresholdC: 34.0,
          lowAirHumidityThresholdPct: 28.0,
          highAirHumidityThresholdPct: 86.0,
        );
      }
      return const EventEngineRules(
        frostThresholdC: 5.0,
        highAirTempThresholdC: 36.0,
        lowAirHumidityThresholdPct: 24.0,
        highAirHumidityThresholdPct: 88.0,
      );
    }

    if (crop == 'wheat' || crop == 'barley' || crop == 'oat') {
      if (_containsAny(stage, const <String>['boot', 'head', 'flower', 'grain'])) {
        return const EventEngineRules(
          frostThresholdC: 2.0,
          highAirTempThresholdC: 32.0,
          lowAirHumidityThresholdPct: 25.0,
          highAirHumidityThresholdPct: 85.0,
        );
      }
      return const EventEngineRules(
        frostThresholdC: 0.5,
        highAirTempThresholdC: 35.0,
        lowAirHumidityThresholdPct: 20.0,
        highAirHumidityThresholdPct: 88.0,
      );
    }

    return const EventEngineRules();
  }

  static bool _containsAny(String value, List<String> patterns) {
    for (final pattern in patterns) {
      if (value.contains(pattern)) return true;
    }
    return false;
  }
}
