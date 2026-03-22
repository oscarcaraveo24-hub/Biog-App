// lib/services/environment_service.dart
import 'dart:convert';

import 'package:bio_g/models/environment_models.dart';
import 'package:http/http.dart' as http;

class EnvironmentService {
  const EnvironmentService();

  /// ✅ Fetch principal (mantiene arquitectura/modelos actuales)
  /// - EnvironmentScreen: usa default (3 días)
  /// - EnvironmentForecastScreen: pide 7 días con dailyLimit: 7
  Future<EnvironmentPayload> fetchEnvironment({
    required EnvironmentLocation location,
    int dailyLimit = 3,
  }) async {
    // Open-Meteo: current + daily + hourly
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${location.lat}'
      '&longitude=${location.lon}'
      '&timezone=auto'
      '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code'
      '&hourly=precipitation_probability,shortwave_radiation'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code,wind_speed_10m_max'
      '&forecast_days=7',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Weather HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    // ---------- current ----------
    final current = (data['current'] as Map).cast<String, dynamic>();
    final temp = (current['temperature_2m'] as num).toDouble();
    final hum = (current['relative_humidity_2m'] as num).toInt();
    final wind = (current['wind_speed_10m'] as num).toDouble();
    final code = (current['weather_code'] as num).toInt();

    final cond = _mapWeatherCode(code);
    final condLabel = _labelForCondition(cond);
    final agroNote = _agroNoteForNow(cond, temp, hum, wind);

    // ---------- radiation (pick nearest hour) ----------
    double? shortwave;
    try {
      final hourly = (data['hourly'] as Map).cast<String, dynamic>();
      final times = (hourly['time'] as List).map((e) => e.toString()).toList();
      final radiation = (hourly['shortwave_radiation'] as List).map((e) {
        if (e == null) return 0.0;
        return (e as num).toDouble();
      }).toList();

      final nowIso = (current['time'] ?? '').toString();
      final idx = times.indexOf(nowIso);
      if (idx >= 0 && idx < radiation.length) {
        shortwave = radiation[idx];
      } else if (radiation.isNotEmpty) {
        shortwave = radiation.first;
      }
    } catch (_) {
      shortwave = null;
    }

    final nowModel = EnvironmentNow(
      condition: cond,
      conditionLabel: condLabel,
      agroNote: agroNote,
      tempC: temp,
      humidityPct: hum,
      windKmh: wind,
      shortwaveWm2: shortwave,
    );

    // ---------- daily (FULL 7 from API) ----------
    final daily = (data['daily'] as Map).cast<String, dynamic>();
    final dailyTimes = (daily['time'] as List)
        .map((e) => e.toString())
        .toList();

    final tMax = (daily['temperature_2m_max'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final tMin = (daily['temperature_2m_min'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final pMax = (daily['precipitation_probability_max'] as List).map((e) {
      if (e == null) return 0;
      return (e as num).toInt();
    }).toList();
    final wCode = (daily['weather_code'] as List)
        .map((e) => (e as num).toInt())
        .toList();
    final wMax = (daily['wind_speed_10m_max'] as List)
        .map((e) => (e as num).toDouble())
        .toList();

    final fullDays = <EnvironmentDaily>[];
    for (int i = 0; i < dailyTimes.length; i++) {
      final dCond = _mapWeatherCode(wCode[i]);
      final label = _dayLabelFromIso(dailyTimes[i], i);

      final windLabel = _windLabel(wMax[i]);
      fullDays.add(
        EnvironmentDaily(
          dayLabel: label,
          condition: dCond,
          maxC: tMax[i].round(),
          minC: tMin[i].round(),
          rainProbPct: pMax[i].clamp(0, 100),
          windLabel: windLabel,
          windKmh: wMax[i],
        ),
      );
    }

    // ✅ Aquí está el fix:
    // - Service ya tiene 7 reales (fullDays)
    // - PERO puedes pedir 3 o 7 según la pantalla con dailyLimit
    final limitedDays = fullDays
        .take(dailyLimit.clamp(1, fullDays.length))
        .toList();

    // ---------- insight ----------
    final insight = _buildInsight(limitedDays, nowModel);

    return EnvironmentPayload(
      location: location.copyWith(updatedAt: DateTime.now()),
      now: nowModel,
      nextDays: limitedDays,
      insight: insight,
    );
  }

  // ---------------------------------------------------------------------------
  // ✅ PREPARADO PARA LA SIGUIENTE PANTALLA (24 horas por día)
  //
  // No toca tus modelos actuales. Regresa una lista simple para que luego
  // decidas si creas un EnvironmentHourly model (en environment_models.dart).
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchHourly24h({
    required EnvironmentLocation location,
    required DateTime day,
  }) async {
    final start = _yyyyMmDd(day);
    final end = _yyyyMmDd(day.add(const Duration(days: 1)));

    // Pedimos 1 día exacto (24h) y variables útiles para UI
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${location.lat}'
      '&longitude=${location.lon}'
      '&timezone=auto'
      '&hourly=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation_probability,weather_code'
      '&start_date=$start'
      '&end_date=$end',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Hourly HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final hourly = (data['hourly'] as Map).cast<String, dynamic>();

    final times = (hourly['time'] as List).map((e) => e.toString()).toList();
    final temps = (hourly['temperature_2m'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final hums = (hourly['relative_humidity_2m'] as List)
        .map((e) => (e as num).toInt())
        .toList();
    final winds = (hourly['wind_speed_10m'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final pops = (hourly['precipitation_probability'] as List).map((e) {
      if (e == null) return 0;
      return (e as num).toInt();
    }).toList();
    final codes = (hourly['weather_code'] as List)
        .map((e) => (e as num).toInt())
        .toList();

    final out = <Map<String, dynamic>>[];
    final n = times.length;

    for (int i = 0; i < n; i++) {
      out.add({
        'timeIso': times[i],
        'tempC': temps[i],
        'humidityPct': hums[i],
        'windKmh': winds[i],
        'rainProbPct': pops[i].clamp(0, 100),
        'condition': _mapWeatherCode(codes[i]),
        'conditionLabel': _labelForCondition(_mapWeatherCode(codes[i])),
      });
    }

    return out;
  }

  String _yyyyMmDd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ---------------- helpers ----------------

  EnvCondition _mapWeatherCode(int code) {
    // Open-Meteo weather codes: https://open-meteo.com/en/docs
    if (code == 0) return EnvCondition.sunny;
    if (code == 1 || code == 2) return EnvCondition.partlyCloudy;
    if (code == 3) return EnvCondition.cloudy;
    if (code == 45 || code == 48) return EnvCondition.fog;
    if (code == 51 || code == 53 || code == 55) return EnvCondition.drizzle;
    if (code == 61 ||
        code == 63 ||
        code == 65 ||
        code == 80 ||
        code == 81 ||
        code == 82) {
      return EnvCondition.rain;
    }
    if (code == 95 || code == 96 || code == 99) return EnvCondition.thunder;
    if (code == 71 ||
        code == 73 ||
        code == 75 ||
        code == 77 ||
        code == 85 ||
        code == 86) {
      return EnvCondition.snow;
    }
    return EnvCondition.unknown;
  }

  String _labelForCondition(EnvCondition c) {
    switch (c) {
      case EnvCondition.sunny:
        return 'Soleado';
      case EnvCondition.partlyCloudy:
        return 'Parcialmente nublado';
      case EnvCondition.cloudy:
        return 'Nublado';
      case EnvCondition.fog:
        return 'Neblina';
      case EnvCondition.drizzle:
        return 'Llovizna';
      case EnvCondition.rain:
        return 'Lluvia';
      case EnvCondition.thunder:
        return 'Tormenta';
      case EnvCondition.snow:
        return 'Nieve';
      case EnvCondition.unknown:
      default:
        return 'Clima';
    }
  }

  String _agroNoteForNow(EnvCondition c, double t, int h, double wind) {
    if (c == EnvCondition.rain || c == EnvCondition.drizzle) {
      return 'Humedad elevada: vigila riego y hongos';
    }
    if (t >= 34) return 'Calor alto: riesgo de estrés térmico';
    if (t <= 6) return 'Frío: vigila helada';
    if (wind >= 28) return 'Viento fuerte: posible estrés mecánico';
    if (h <= 25) return 'Aire seco: mayor transpiración';
    return 'Sensación estable para el cultivo';
  }

  String _dayLabelFromIso(String iso, int i) {
    if (i == 0) return 'Hoy';

    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Día';

    const names = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return names[(dt.weekday - 1).clamp(0, 6)];
  }

  String _windLabel(double kmh) {
    if (kmh < 12) return 'Viento bajo';
    if (kmh < 24) return 'Viento moderado';
    return 'Viento fuerte';
  }

  EnvironmentInsight _buildInsight(
    List<EnvironmentDaily> nextDays,
    EnvironmentNow now,
  ) {
    for (final d in nextDays) {
      if (d.rainProbPct >= 60) {
        return EnvironmentInsight(
          level: EnvInsightLevel.ok,
          text:
              'Se espera lluvia el ${d.dayLabel.toLowerCase()}, considera ajustar riego.',
        );
      }
    }

    if (now.tempC >= 34) {
      return const EnvironmentInsight(
        level: EnvInsightLevel.warn,
        text: 'Temperatura alta: monitorea estrés térmico y riego.',
      );
    }

    return const EnvironmentInsight(
      level: EnvInsightLevel.ok,
      text: 'Condiciones estables. Mantén monitoreo y riego programado.',
    );
  }
}
