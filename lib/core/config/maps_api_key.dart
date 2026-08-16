// lib/core/config/maps_api_key.dart
//
// Dónde está la llave de Google Maps. Una sola respuesta para toda la app.
//
// ═════════════════════════════════════════════════════════════════════════════
// EL PROBLEMA QUE ESTE ARCHIVO EXISTE PARA CERRAR
// ═════════════════════════════════════════════════════════════════════════════
//
// `String.fromEnvironment` se resuelve en tiempo de COMPILACIÓN. Si el binario
// se armó sin `--dart-define=GOOGLE_MAPS_API_KEY=...`, la constante vale cadena
// vacía para siempre y no hay manera de arreglarlo en caliente.
//
// Consecuencia en desarrollo: había que arrancar SIEMPRE con el flag. Un
// `flutter run` normal —o un hot restart desde el IDE, o el botón de Run de
// Android Studio— compilaba una app en la que el buscador de direcciones
// respondía «Falta GOOGLE_MAPS_API_KEY en --dart-define» y la ubicación
// guardada aparecía sin nombre. Los mosaicos del mapa sí se veían, porque esos
// los pinta el SDK nativo con la llave del AndroidManifest, y eso hacía el
// fallo aún más confuso: el mapa funciona, el texto no.
//
// ═════════════════════════════════════════════════════════════════════════════
// LA REGLA
// ═════════════════════════════════════════════════════════════════════════════
//
//   efectiva = --dart-define ?? última llave que vimos
//
// La primera vez que la app arranca con el flag, la llave queda guardada. A
// partir de ahí `flutter run` a secas la encuentra sola. Volver a pasar el flag
// con una llave distinta la reemplaza, así que rotarla sigue siendo una sola
// ejecución.
//
// ── Qué NO hace ──────────────────────────────────────────────────────────────
//
// No inventa una llave de respaldo. Sin llave, `resolve()` devuelve cadena
// vacía y quien llame debe decirlo en la interfaz, no fingir que geocodificó.
//
// ── Sobre guardarla en preferencias ──────────────────────────────────────────
//
// Es la misma llave que ya viaja en claro dentro del AndroidManifest de
// cualquier APK instalado, así que esto no la expone más de lo que ya está: un
// atacante con acceso al almacenamiento de la app tiene el APK entero. La
// protección real de una llave de Maps son las restricciones de la consola de
// Google (huella SHA-1 + nombre de paquete, y referrers para las HTTP APIs), no
// el sitio donde el cliente la guarda.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class MapsApiKey {
  /// Lo que se compiló con `--dart-define=GOOGLE_MAPS_API_KEY=...`.
  /// Cadena vacía si se armó sin el flag.
  static const String _fromDefine = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  static const String _prefKey = 'google_maps_api_key_cached';

  /// Copia en memoria para que las llamadas siguientes no toquen disco.
  ///
  /// Empieza siendo la del `--dart-define` cuando existe: así el primer
  /// `valueOrEmpty` de la sesión ya tiene algo aunque `resolve()` no haya
  /// terminado todavía.
  static String _cached = _fromDefine;

  static bool _loaded = false;

  /// La llave utilizable, o cadena vacía si no hay ninguna.
  ///
  /// Es idempotente y barata: solo la primera llamada de la sesión lee disco.
  static Future<String> resolve() async {
    if (_loaded) return _cached;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      if (_fromDefine.isNotEmpty) {
        // Arrancó con el flag: esta es la verdad y además se guarda para los
        // arranques que vengan sin él.
        _cached = _fromDefine;
        if (prefs.getString(_prefKey) != _fromDefine) {
          await prefs.setString(_prefKey, _fromDefine);
        }
      } else {
        final String? stored = prefs.getString(_prefKey)?.trim();
        _cached = (stored == null || stored.isEmpty) ? '' : stored;

        if (kDebugMode && _cached.isNotEmpty) {
          debugPrint(
            '[BioG/MapsApiKey] sin --dart-define; usando la llave guardada '
            'de un arranque anterior.',
          );
        }
      }
    } catch (_) {
      // Preferencias no disponibles: queda lo que trajera el binario. Sin
      // llave se responde vacío, nunca una inventada.
      _cached = _fromDefine;
    }

    _loaded = true;
    return _cached;
  }

  /// Lectura síncrona de lo último resuelto. Para `build()` y otros puntos
  /// donde no se puede esperar un Future.
  ///
  /// Devuelve cadena vacía hasta que [resolve] haya corrido al menos una vez
  /// en un arranque sin `--dart-define`.
  static String get valueOrEmpty => _cached;

  static bool get isAvailable => _cached.isNotEmpty;

  /// Solo para pruebas: olvida lo resuelto en esta sesión.
  @visibleForTesting
  static void resetForTest() {
    _cached = _fromDefine;
    _loaded = false;
  }
}
