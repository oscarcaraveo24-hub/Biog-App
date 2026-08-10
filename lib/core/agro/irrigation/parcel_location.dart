// lib/core/agro/irrigation/parcel_location.dart
//
// Dónde está la parcela. Una sola respuesta para toda la app.
//
// ═════════════════════════════════════════════════════════════════════════════
// EL BUG QUE ESTE ARCHIVO EXISTE PARA CERRAR
// ═════════════════════════════════════════════════════════════════════════════
//
// La ubicación vivía en DOS sitios que nunca se hablaron:
//
//   1. `SharedPreferences` bajo `profile_location_*`
//      · la escriben el onboarding y la pantalla de Ubicación de la Cuenta
//      · la lee la pantalla de Entorno  ................................ ✅
//
//   2. `DeviceCropContext.geoLat/geoLng` (columna `geo_lat` en la nube)
//      · la escribe SOLO el onboarding, y solo si el borrador traía coordenadas
//      · la lee `IrrigationAdvisor.parcelCoordinates`, o sea el motor de riego
//
// Resultado observado en producción: la fila activa de `device_crop_contexts`
// tenía `geo_lat = NULL` mientras Entorno mostraba el clima perfectamente. El
// coordinador de riego pedía coordenadas, recibía null, NO llamaba a
// `ensureFresh`, y el repositorio de clima se quedaba vacío para siempre. El
// motor recibía `AgronomicWeatherSnapshot.unavailable` en cada evaluación y
// respondía lo único honesto que podía responder: *"revisar: hay déficit
// moderado, pero sin clima no se puede saber si conviene regar"*.
//
// No era un fallo de red ni del pronóstico. Era que la mitad de la app no
// sabía dónde estaba la parcela.
//
// ═════════════════════════════════════════════════════════════════════════════
// LA REGLA
// ═════════════════════════════════════════════════════════════════════════════
//
// **Manda lo último que el usuario eligió**, que es lo que hay en
// preferencias: es lo que escribe la pantalla de Ubicación, el único sitio de
// la app donde se puede cambiar la ubicación después del onboarding. El
// contexto de cultivo es un espejo de eso, no una fuente rival.
//
//   efectiva = preferencias ?? contexto
//
// Y cuando las dos difieren, el contexto se corrige. Importa más de lo que
// parece: `RecommendationRecorder` guarda `parcelLat`/`parcelLon` desde el
// contexto, así que un contexto vacío deja el registro auditable sin parcela,
// y el ERP y el panel web leen esa misma columna.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bio_g/models/device_crop_context.dart';

/// De dónde salieron las coordenadas que se están usando.
enum ParcelLocationSource {
  /// Del contexto de cultivo, que es donde deberían vivir siempre.
  cropContext,

  /// Del perfil en preferencias. Es el respaldo, y también la señal de que el
  /// contexto se quedó atrás y hay que corregirlo.
  profilePreferences,
}

@immutable
class ParcelLocation {
  const ParcelLocation({
    required this.lat,
    required this.lon,
    required this.source,
    this.label,
  });

  final double lat;
  final double lon;
  final ParcelLocationSource source;
  final String? label;

  /// True si estas coordenadas vienen del perfil y por tanto el contexto de
  /// cultivo debería actualizarse para que coincida.
  bool get needsContextSync =>
      source == ParcelLocationSource.profilePreferences;

  /// Dos ubicaciones se consideran la misma parcela si caen dentro de unos
  /// pocos metros. 1e-5 grados son ~1.1 m: por debajo de eso la diferencia es
  /// ruido de GPS y reescribir el contexto sería puro tráfico.
  static const double _epsilon = 1e-5;

  bool sameSpotAs(double? otherLat, double? otherLon) {
    if (otherLat == null || otherLon == null) return false;
    return (lat - otherLat).abs() < _epsilon &&
        (lon - otherLon).abs() < _epsilon;
  }

  @override
  String toString() {
    final String tail = label == null ? '' : ', $label';
    return 'ParcelLocation($lat, $lon, ${source.name}$tail)';
  }
}

/// Las claves de preferencias donde vive la ubicación del perfil.
///
/// Estaban repetidas como constantes privadas en cuatro archivos —onboarding,
/// Entorno, la pantalla de Ubicación y el asistente—. Aquí quedan escritas una
/// vez para que quien las lea desde el motor no tenga que adivinarlas ni
/// arriesgarse a teclear una distinta.
abstract final class ParcelLocationKeys {
  static const String label = 'profile_location_label';
  static const String lat = 'profile_location_lat';
  static const String lng = 'profile_location_lng';
}

/// Resuelve la ubicación de la parcela.
abstract final class ParcelLocationResolver {
  /// Coordenadas guardadas en el contexto de cultivo, ya validadas.
  static ParcelLocation? fromCropContext(DeviceCropContext? context) {
    return _build(
      lat: context?.geoLat,
      lon: context?.geoLng,
      label: context?.locationLabel,
      source: ParcelLocationSource.cropContext,
    );
  }

  /// Coordenadas guardadas en el perfil del usuario.
  ///
  /// Es la misma lectura que hace la pantalla de Entorno, sobre las mismas
  /// claves. Si Entorno puede pintar el clima, esto devuelve algo.
  static Future<ParcelLocation?> fromProfilePreferences() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return _build(
        lat: prefs.getDouble(ParcelLocationKeys.lat),
        lon: prefs.getDouble(ParcelLocationKeys.lng),
        label: prefs.getString(ParcelLocationKeys.label),
        source: ParcelLocationSource.profilePreferences,
      );
    } catch (_) {
      // Preferencias rotas o no disponibles: no es motivo para tumbar una
      // decisión de riego. Se responde "no sé" y el motor ya sabe qué hacer.
      return null;
    }
  }

  /// La ubicación efectiva, aplicando la regla de arriba.
  static Future<ParcelLocation?> resolve(DeviceCropContext? context) async {
    final ParcelLocation? profile = await fromProfilePreferences();
    if (profile != null) return profile;
    return fromCropContext(context);
  }

  /// Devuelve el contexto con la ubicación puesta, o null si no hay nada que
  /// corregir.
  ///
  /// Devolver null cuando ya coinciden es lo que evita el bucle: quien llame a
  /// esto guarda solo si recibe algo, y guardar dispara una reconstrucción que
  /// vuelve a llamar aquí.
  static DeviceCropContext? contextHealedWith(
    DeviceCropContext? context,
    ParcelLocation location,
  ) {
    if (context == null) return null;
    if (location.sameSpotAs(context.geoLat, context.geoLng)) return null;

    final String? label = location.label?.trim();
    return context.copyWith(
      geoLat: location.lat,
      geoLng: location.lon,
      locationLabel: (label != null && label.isNotEmpty)
          ? label
          : context.locationLabel,
      locationSource: context.locationSource ?? 'profile',
    );
  }

  static ParcelLocation? _build({
    required double? lat,
    required double? lon,
    required String? label,
    required ParcelLocationSource source,
  }) {
    if (lat == null || lon == null) return null;
    if (!lat.isFinite || !lon.isFinite) return null;
    // (0, 0) es el marcador de "sin ubicación" en este proyecto, y además cae
    // en medio del Atlántico: como parcela no existe.
    if (lat == 0 && lon == 0) return null;
    if (lat < -90 || lat > 90) return null;
    if (lon < -180 || lon > 180) return null;

    final String? clean = label?.trim();
    return ParcelLocation(
      lat: lat,
      lon: lon,
      source: source,
      label: (clean == null || clean.isEmpty) ? null : clean,
    );
  }
}
