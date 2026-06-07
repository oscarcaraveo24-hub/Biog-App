import 'package:bio_g/core/agro/event_engine.dart';

class EventEngineRulesResolver {
  const EventEngineRulesResolver._();

  static EventEngineRules resolve({
    required String? cropId,
    required String? stageKey,
  }) {
    final crop = (cropId ?? '').trim().toLowerCase();
    final stage = (stageKey ?? '').trim().toLowerCase();

    if (crop == 'lettuce' || crop == 'crop_lettuce') {
      final qualityStage = _containsAny(stage, const <String>[
        'formacioncabeza',
        'formacion_cabeza',
        'head',
        'cabeza',
        'compact',
        'ventanacosecha',
        'ventana_cosecha',
        'harvest',
        'cosecha',
        'sobremadurez',
        'madur',
      ]);

      return EventEngineRules(
        frostThresholdC: 0.0,
        highAirTempThresholdC: qualityStage ? 27.0 : 28.0,
        criticalAirTempThresholdC: qualityStage ? 30.0 : 31.0,
        lowAirHumidityThresholdPct: 35.0,
        highAirHumidityThresholdPct: 85.0,
        goodStructureMaxResistance: 2.0,
        moistureStableTolerance: 5.0,
      );
    }

    if (crop == 'spinach' || crop == 'crop_spinach' || crop == 'espinaca') {
      final qualityStage = _containsAny(stage, const <String>[
        'expansion',
        'foliar',
        'madurez',
        'commercial',
        'comercial',
        'ventana',
        'cosecha',
        'harvest',
        'perdida',
        'decline',
        'espig',
        'bolting',
        'senesc',
      ]);

      return EventEngineRules(
        frostThresholdC: 0.0,
        highAirTempThresholdC: qualityStage ? 25.0 : 26.0,
        criticalAirTempThresholdC: qualityStage ? 28.0 : 30.0,
        lowAirHumidityThresholdPct: 40.0,
        highAirHumidityThresholdPct: 85.0,
        goodStructureMaxResistance: 1.5,
        moistureStableTolerance: 5.0,
      );
    }

    if (crop == 'onion' || crop == 'crop_onion' || crop == 'cebolla') {
      final criticalStage = _containsAny(stage, const <String>[
        'induccion',
        'bulbo',
        'llenado',
        'maduracion',
        'cosecha',
        'cuello',
        'espig',
        'bolting',
        'senesc',
      ]);

      return EventEngineRules(
        frostThresholdC: 0.0,
        highAirTempThresholdC: criticalStage ? 28.0 : 30.0,
        criticalAirTempThresholdC: criticalStage ? 30.0 : 33.0,
        lowAirHumidityThresholdPct: 30.0,
        highAirHumidityThresholdPct: 85.0,
        goodStructureMaxResistance: 1.5,
        moistureStableTolerance: 5.0,
      );
    }

    if (crop == 'garlic' || crop == 'crop_garlic' || crop == 'ajo') {
      final criticalStage = _containsAny(stage, const <String>[
        'vernal',
        'frio',
        'cold',
        'diferenci',
        'bulbo',
        'bulb',
        'diente',
        'llenado',
        'fill',
        'maduracion',
        'matur',
        'cosecha',
        'harvest',
        'curado',
        'curing',
        'escapo',
        'canuto',
        'escobete',
        'broom',
        'scape',
        'senesc',
      ]);

      return EventEngineRules(
        frostThresholdC: 0.0,
        highAirTempThresholdC: criticalStage ? 28.0 : 30.0,
        criticalAirTempThresholdC: criticalStage ? 30.0 : 33.0,
        lowAirHumidityThresholdPct: 30.0,
        highAirHumidityThresholdPct: 85.0,
        goodStructureMaxResistance: 1.5,
        moistureStableTolerance: 5.0,
      );
    }

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
