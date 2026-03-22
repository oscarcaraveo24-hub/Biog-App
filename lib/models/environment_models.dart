// lib/models/environment_models.dart
import 'package:flutter/foundation.dart';

/// =======================
/// 1) CONDICIONES INTERNAS
/// =======================
enum EnvCondition {
  sunny,
  night,
  partlyCloudy,
  cloudy,
  fog,
  drizzle,
  rain,
  thunder,
  stormStrong,
  snow,
  frost,
  heatwave,
  unknown,
}

/// =======================
/// 2) MAPPER CENTRAL
///    Google -> EnvCondition
///    EnvCondition -> icon asset
///    Insight -> icon asset
/// =======================
class EnvironmentIconMapper {
  static const String _weatherBase = 'assets/icons/weather/';
  static const String _metricBase = 'assets/icons/metrics/';

  /// ✅ Ícono dinámico para el estado del clima (Now + Forecast)
  static String iconForCondition(EnvCondition condition) {
    switch (condition) {
      case EnvCondition.sunny:
        return '${_weatherBase}ic_weather_sunny.png';
      case EnvCondition.night:
        return '${_weatherBase}ic_weather_night.png';
      case EnvCondition.partlyCloudy:
        return '${_weatherBase}ic_weather_partly_cloudy.png';
      case EnvCondition.cloudy:
        return '${_weatherBase}ic_weather_cloudy.png';
      case EnvCondition.fog:
        return '${_weatherBase}ic_weather_fog.png';
      case EnvCondition.drizzle:
      case EnvCondition.rain:
        return '${_weatherBase}ic_weather_rain.png';
      case EnvCondition.thunder:
        return '${_weatherBase}ic_weather_thunder.png';
      case EnvCondition.stormStrong:
        return '${_weatherBase}ic_weather_storm_strong.png';
      case EnvCondition.snow:
        return '${_weatherBase}ic_weather_snow.png';
      case EnvCondition.frost:
        return '${_weatherBase}ic_weather_frost.png';
      case EnvCondition.heatwave:
        return '${_weatherBase}ic_weather_heatwave.png';
      case EnvCondition.unknown:
        return '${_weatherBase}ic_weather_partly_cloudy.png';
    }
  }

  /// ✅ Ícono para “condiciones estables / warning / critical”
  /// - ok -> ic_balance
  /// - warn/critical -> ic_error (por ahora)
  static String iconForInsightLevel(EnvInsightLevel level) {
    switch (level) {
      case EnvInsightLevel.ok:
        return '${_metricBase}ic_balance.png';
      case EnvInsightLevel.warn:
      case EnvInsightLevel.critical:
        return '${_metricBase}ic_error.png';
    }
  }

  /// ==========================
  /// 3) NORMALIZACIÓN GOOGLE
  /// ==========================
  /// Google a veces manda:
  /// - textos: "Partly cloudy", "Light rain", "Overcast"
  /// - o claves: "CLOUDY", "RAIN", etc.
  ///
  /// Esta función intenta mapear cualquier string "crudo" a tu enum.
  static EnvCondition conditionFromGoogle(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s.isEmpty) return EnvCondition.unknown;

    // Night / clear night
    if (s.contains('night') ||
        s.contains('clear_night') ||
        s.contains('moon')) {
      return EnvCondition.night;
    }

    // Heat / hot
    if (s.contains('heat') || s.contains('hot') || s.contains('heatwave')) {
      return EnvCondition.heatwave;
    }

    // Frost / freezing
    if (s.contains('frost') || s.contains('freeze') || s.contains('freezing')) {
      return EnvCondition.frost;
    }

    // Snow
    if (s.contains('snow') || s.contains('sleet') || s.contains('blizzard')) {
      return EnvCondition.snow;
    }

    // Thunder / storm
    if (s.contains('thunder') || s.contains('lightning')) {
      return EnvCondition.thunder;
    }
    if (s.contains('storm') ||
        s.contains('hurricane') ||
        s.contains('cyclone') ||
        s.contains('severe')) {
      return EnvCondition.stormStrong;
    }

    // Rain / drizzle
    if (s.contains('drizzle')) return EnvCondition.drizzle;
    if (s.contains('rain') || s.contains('shower') || s.contains('sprinkle')) {
      return EnvCondition.rain;
    }

    // Fog / mist / haze
    if (s.contains('fog') ||
        s.contains('mist') ||
        s.contains('haze') ||
        s.contains('smoke')) {
      return EnvCondition.fog;
    }

    // Cloudy variants
    if (s.contains('partly') || s.contains('partly_cloudy')) {
      return EnvCondition.partlyCloudy;
    }
    if (s.contains('overcast') || s.contains('cloudy') || s == 'cloud') {
      return EnvCondition.cloudy;
    }

    // Sunny / clear
    if (s.contains('sunny') || s.contains('clear') || s == 'sun') {
      return EnvCondition.sunny;
    }

    return EnvCondition.unknown;
  }
}

/// =======================
/// 4) MODELOS
/// =======================
@immutable
class EnvironmentLocation {
  final String fieldName;
  final String zoneLabel;
  final DateTime updatedAt;
  final double lat;
  final double lon;

  const EnvironmentLocation({
    required this.fieldName,
    required this.zoneLabel,
    required this.updatedAt,
    required this.lat,
    required this.lon,
  });

  EnvironmentLocation copyWith({
    String? fieldName,
    String? zoneLabel,
    DateTime? updatedAt,
    double? lat,
    double? lon,
  }) {
    return EnvironmentLocation(
      fieldName: fieldName ?? this.fieldName,
      zoneLabel: zoneLabel ?? this.zoneLabel,
      updatedAt: updatedAt ?? this.updatedAt,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }
}

@immutable
class EnvironmentNow {
  final EnvCondition condition;
  final String conditionLabel; // "Soleado"
  final String agroNote; // "Sensación estable para el cultivo"

  final double tempC;
  final int humidityPct;
  final double windKmh;

  /// radiación solar (W/m²) o null si provider no lo da
  final double? shortwaveWm2;

  const EnvironmentNow({
    required this.condition,
    required this.conditionLabel,
    required this.agroNote,
    required this.tempC,
    required this.humidityPct,
    required this.windKmh,
    required this.shortwaveWm2,
  });
}

@immutable
class EnvironmentDaily {
  final String dayLabel; // "Hoy", "Martes", etc.
  final EnvCondition condition;
  final int maxC;
  final int minC;
  final int rainProbPct;
  final String windLabel; // "Viento bajo/moderado"
  final double windKmh;

  const EnvironmentDaily({
    required this.dayLabel,
    required this.condition,
    required this.maxC,
    required this.minC,
    required this.rainProbPct,
    required this.windLabel,
    required this.windKmh,
  });
}

@immutable
class EnvironmentInsight {
  final String text;
  final EnvInsightLevel level;

  const EnvironmentInsight({required this.text, required this.level});
}

enum EnvInsightLevel { ok, warn, critical }

@immutable
class EnvironmentPayload {
  final EnvironmentLocation location;
  final EnvironmentNow now;
  final List<EnvironmentDaily> nextDays;
  final EnvironmentInsight insight;

  const EnvironmentPayload({
    required this.location,
    required this.now,
    required this.nextDays,
    required this.insight,
  });
}
