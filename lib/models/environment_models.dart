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

  /// Open-Meteo uses the WMO weather interpretation codes.
  ///
  /// Expected icon decisions:
  /// - code 0, POP 0 -> sunny/night
  /// - code 2, POP 20 -> partly cloudy
  /// - code 3, POP 20 -> cloudy
  /// - code 3, POP 55 -> rain
  /// - code 1, POP 75 -> rain
  /// - code 61, POP 30 -> rain
  /// - code 65, POP 80 -> rain (closest available asset for heavy rain)
  /// - code 80, POP 60 -> rain
  /// - code 95 -> thunder
  /// - code 96/99 -> strong storm
  /// - code 45/48 -> fog
  /// - code 71/73/75 -> snow
  /// - high radiation + code 0 -> heatwave
  /// - high radiation + code 61 -> rain
  static EnvCondition conditionFromWmoCode(int weatherCode) {
    if (weatherCode == 0) return EnvCondition.sunny;
    if (weatherCode == 1 || weatherCode == 2) {
      return EnvCondition.partlyCloudy;
    }
    if (weatherCode == 3) return EnvCondition.cloudy;
    if (weatherCode == 45 || weatherCode == 48) return EnvCondition.fog;
    if (weatherCode == 51 || weatherCode == 53 || weatherCode == 55) {
      return EnvCondition.drizzle;
    }
    if (weatherCode == 56 ||
        weatherCode == 57 ||
        weatherCode == 66 ||
        weatherCode == 67) {
      return EnvCondition.frost;
    }
    if (weatherCode == 61 ||
        weatherCode == 63 ||
        weatherCode == 65 ||
        weatherCode == 80 ||
        weatherCode == 81 ||
        weatherCode == 82) {
      return EnvCondition.rain;
    }
    if (weatherCode == 71 ||
        weatherCode == 73 ||
        weatherCode == 75 ||
        weatherCode == 77 ||
        weatherCode == 85 ||
        weatherCode == 86) {
      return EnvCondition.snow;
    }
    if (weatherCode == 95) return EnvCondition.thunder;
    if (weatherCode == 96 || weatherCode == 99) {
      return EnvCondition.stormStrong;
    }
    return EnvCondition.unknown;
  }

  /// Current weather represents what is happening now. Forecast POP must not
  /// turn a clear current observation into rain, but measured precipitation can.
  static String iconForCurrentWeather({
    required int weatherCode,
    required DateTime time,
    EnvCondition? fallbackCondition,
    bool? isDay,
    double? precipitationMm,
    double? shortwaveRadiation,
    double? temperatureC,
  }) {
    var condition = _baseCondition(weatherCode, fallbackCondition);
    final precipitation = precipitationMm ?? 0;

    if (_isGenericSky(condition) && precipitation > 0) {
      condition = precipitation >= 3 ? EnvCondition.rain : EnvCondition.drizzle;
    }

    if (_isGenericSky(condition) &&
        ((temperatureC ?? 0) >= 38 || (shortwaveRadiation ?? 0) >= 950)) {
      condition = EnvCondition.heatwave;
    }

    return iconForCondition(
      _withClearNight(condition, weatherCode, time, isDay: isDay),
    );
  }

  /// Forecast cards represent risk. POP and accumulated precipitation may
  /// override generic clear/cloud codes, but never severe WMO phenomena.
  static String iconForForecastWeather({
    required int weatherCode,
    required DateTime time,
    EnvCondition? fallbackCondition,
    bool? isDay,
    int? precipitationProbability,
    double? precipitationMm,
  }) {
    var condition = _baseCondition(weatherCode, fallbackCondition);
    final precipitation = precipitationMm ?? 0;
    final probability = precipitationProbability ?? 0;

    if (_isGenericSky(condition)) {
      condition =
          _forecastPrecipitationCondition(
            precipitation: precipitation,
            probability: probability,
          ) ??
          condition;
    }

    return iconForCondition(
      _withClearNight(condition, weatherCode, time, isDay: isDay),
    );
  }

  /// Daily rows represent the day as a whole, so a clear daily forecast uses
  /// the daytime icon even though the API date is serialized at midnight.
  static String iconForDailyForecastWeather({
    required int weatherCode,
    required DateTime day,
    EnvCondition? fallbackCondition,
    int? precipitationProbability,
    double? precipitationMm,
  }) {
    final midday = DateTime(day.year, day.month, day.day, 12);
    return iconForForecastWeather(
      weatherCode: weatherCode,
      time: midday,
      fallbackCondition: fallbackCondition,
      isDay: true,
      precipitationProbability: precipitationProbability,
      precipitationMm: precipitationMm,
    );
  }

  static EnvCondition _baseCondition(
    int weatherCode,
    EnvCondition? fallbackCondition,
  ) {
    final condition = conditionFromWmoCode(weatherCode);
    if (condition != EnvCondition.unknown || fallbackCondition == null) {
      return condition;
    }
    return fallbackCondition;
  }

  static bool _isGenericSky(EnvCondition condition) {
    return condition == EnvCondition.sunny ||
        condition == EnvCondition.night ||
        condition == EnvCondition.partlyCloudy ||
        condition == EnvCondition.cloudy ||
        condition == EnvCondition.unknown;
  }

  static EnvCondition? _forecastPrecipitationCondition({
    required double precipitation,
    required int probability,
  }) {
    // There are no dedicated light/heavy rain assets yet. Keep thresholds
    // explicit so new PNG variants can be introduced without changing policy.
    if (precipitation >= 10) return EnvCondition.rain;
    if (precipitation >= 3) return EnvCondition.rain;
    if (precipitation > 0) return EnvCondition.drizzle;
    if (probability >= 70) return EnvCondition.rain;
    if (probability >= 50) return EnvCondition.rain;
    return null;
  }

  static EnvCondition _withClearNight(
    EnvCondition condition,
    int weatherCode,
    DateTime time, {
    bool? isDay,
  }) {
    if (condition != EnvCondition.sunny || weatherCode != 0) return condition;
    if (isDay != null) return isDay ? condition : EnvCondition.night;
    final hour = time.hour;
    return hour < 6 || hour >= 19 ? EnvCondition.night : condition;
  }

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

  final int weatherCode;
  final DateTime? observedAt;
  final bool? isDay;
  final double? precipitationMm;

  final double tempC;
  final int humidityPct;
  final double windKmh;

  /// radiación solar (W/m²) o null si provider no lo da
  final double? shortwaveWm2;

  const EnvironmentNow({
    required this.condition,
    required this.conditionLabel,
    required this.agroNote,
    this.weatherCode = 0,
    this.observedAt,
    this.isDay,
    this.precipitationMm,
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
  final int weatherCode;
  final double? precipitationMm;
  final DateTime? forecastDate;
  final int maxC;
  final int minC;
  final int rainProbPct;
  final String windLabel; // "Viento bajo/moderado"
  final double windKmh;

  const EnvironmentDaily({
    required this.dayLabel,
    required this.condition,
    this.weatherCode = 0,
    this.precipitationMm,
    this.forecastDate,
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
