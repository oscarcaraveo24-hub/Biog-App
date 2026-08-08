// lib/core/weather/weather_snapshot_storage.dart
//
// Persistencia del último pronóstico válido.
//
// Sin esto, cerrar la app borraba el clima: al reabrir sin señal la única
// opción era decidir a ciegas o no decidir. Con esto, el motor arranca con el
// último snapshot conocido y su antigüedad real, y puede aplicar una política
// conservadora en vez de fingir que no sabe nada.
//
// Usa SharedPreferences (ya es dependencia del proyecto) porque el volumen es
// mínimo: un objeto por parcela. No amerita una base de datos.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';

abstract class WeatherSnapshotStorage {
  Future<AgronomicWeatherSnapshot?> load(String locationKey);
  Future<void> save(String locationKey, AgronomicWeatherSnapshot snapshot);
  Future<void> clear(String locationKey);
  Future<void> clearAll();
}

class SharedPrefsWeatherSnapshotStorage implements WeatherSnapshotStorage {
  static const String _prefix = 'biog_weather_snapshot_v1_';

  /// Clave estable para un par de coordenadas.
  ///
  /// Se redondea a 3 decimales (~110 m). Mover el teléfono unos metros no debe
  /// invalidar la caché, pero cambiar de parcela sí: el pronóstico del lote
  /// norte no vale para el invernadero.
  static String locationKey(double lat, double lon) {
    final la = lat.toStringAsFixed(3);
    final lo = lon.toStringAsFixed(3);
    return '$la,$lo';
  }

  @override
  Future<AgronomicWeatherSnapshot?> load(String locationKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$locationKey');
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final snapshot = AgronomicWeatherSnapshot.fromJson(
        decoded.cast<String, dynamic>(),
      );
      if (snapshot == null) return null;

      // Todo lo que sale de disco es, por definición, caché: se marca como tal
      // conservando su `fetchedAt` original para no mentir sobre la edad.
      return snapshot.asCached();
    } catch (_) {
      // Una caché ilegible no puede impedir que la app arranque.
      return null;
    }
  }

  @override
  Future<void> save(
    String locationKey,
    AgronomicWeatherSnapshot snapshot,
  ) async {
    // Un snapshot sin datos no se guarda: sobrescribiría un pronóstico bueno
    // con la ausencia de pronóstico.
    if (snapshot.isUnavailable) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefix$locationKey',
        jsonEncode(snapshot.toJson()),
      );
    } catch (_) {
      // Guardar la caché es una mejora, no un requisito.
    }
  }

  @override
  Future<void> clear(String locationKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$locationKey');
    } catch (_) {
      // Ídem.
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {
      // Ídem.
    }
  }
}

/// Implementación en memoria para pruebas.
class InMemoryWeatherSnapshotStorage implements WeatherSnapshotStorage {
  final Map<String, AgronomicWeatherSnapshot> _data =
      <String, AgronomicWeatherSnapshot>{};

  @override
  Future<AgronomicWeatherSnapshot?> load(String locationKey) async {
    final s = _data[locationKey];
    return s?.asCached();
  }

  @override
  Future<void> save(
    String locationKey,
    AgronomicWeatherSnapshot snapshot,
  ) async {
    if (snapshot.isUnavailable) return;
    _data[locationKey] = snapshot;
  }

  @override
  Future<void> clear(String locationKey) async {
    _data.remove(locationKey);
  }

  @override
  Future<void> clearAll() async {
    _data.clear();
  }
}
