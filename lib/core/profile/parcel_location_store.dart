// lib/core/profile/parcel_location_store.dart
//
// Guardar y recuperar DÓNDE ESTÁ LA PARCELA. Una sola puerta.
//
// ═════════════════════════════════════════════════════════════════════════════
// LOS DOS BUGS QUE ESTE ARCHIVO CIERRA
// ═════════════════════════════════════════════════════════════════════════════
//
// ── 1. La etiqueta se guardaba bajo DOS claves distintas ─────────────────────
//
//   `profile_location`        ← la escribe Editar perfil, la lee la Cuenta
//   `profile_location_label`  ← la escribe la pantalla de Ubicación
//
// Elegir un punto en el mapa y pulsar «Guardar» escribía solo la segunda. La
// primera —la que se pinta en la fila «Ubicación» de la Cuenta— seguía con el
// valor viejo salvo que el usuario, además, pulsara el «Guardar» de Editar
// perfil. Salir con «Cancelar» después de haber guardado en el mapa dejaba el
// motor de riego apuntando al sitio nuevo y la interfaz enseñando el viejo.
// Desde fuera se veía exactamente como «no se guarda la ubicación».
//
// Aquí se escriben LAS DOS a la vez, siempre, en la misma operación.
//
// ── 2. Las coordenadas no salían nunca del teléfono ──────────────────────────
//
// `profiles.location` guardaba el texto en la nube; la latitud y la longitud
// vivían solo en `SharedPreferences`. Reinstalar la app, cambiar de teléfono o
// que el sistema limpiara los datos dejaba al usuario con la etiqueta correcta
// en la nube y sin coordenadas — el peor estado posible, porque la interfaz
// afirma saber dónde está la parcela y el motor de clima no puede pedir nada.
//
// ═════════════════════════════════════════════════════════════════════════════
// EL ORDEN DE ESCRITURA, Y POR QUÉ
// ═════════════════════════════════════════════════════════════════════════════
//
//   1. preferencias  (rápido, sin red, nunca falla)
//   2. Supabase      (durable, puede fallar)
//
// Primero lo local. Si la red falla, el usuario se queda con su ubicación
// funcionando y la nube se pone al día la próxima vez que se guarde algo. Al
// revés —nube primero— un guardado sin cobertura no dejaría nada y el usuario
// vería el mismo «no se guardó» que veníamos a arreglar.
//
// `save` NO lanza por un fallo de nube: devuelve si logró espejar. Quien llame
// decide si lo menciona, pero jamás debe deshacer el guardado local por ello.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bio_g/core/agro/irrigation/parcel_location.dart';
import 'package:bio_g/core/profile/profile_repository.dart';
import 'package:bio_g/models/user_profile.dart';
import 'package:bio_g/services/profile/profile_local_service.dart';

/// De dónde salió la ubicación que se está guardando.
///
/// Los identificadores tienen que coincidir con
/// `profiles_location_source_check` en la base de datos.
enum ParcelLocationOrigin {
  gps('gps'),
  map('map'),
  search('search'),
  onboarding('onboarding');

  const ParcelLocationOrigin(this.id);
  final String id;

  static ParcelLocationOrigin? fromId(String? raw) {
    if (raw == null) return null;
    for (final ParcelLocationOrigin o in ParcelLocationOrigin.values) {
      if (o.id == raw) return o;
    }
    return null;
  }
}

/// Una ubicación completa: dónde, cómo se llama, de dónde salió y cuándo.
@immutable
class StoredParcelLocation {
  const StoredParcelLocation({
    required this.lat,
    required this.lng,
    required this.label,
    this.origin,
    this.updatedAt,
  });

  final double lat;
  final double lng;
  final String label;
  final ParcelLocationOrigin? origin;
  final DateTime? updatedAt;

  /// Mismo punto dentro de ~1.1 m (1e-5 grados). Por debajo de eso la
  /// diferencia es ruido y reescribir sería puro tráfico. Es el mismo epsilon
  /// que usa `ParcelLocation.sameSpotAs`, a propósito.
  bool sameSpotAs(double? otherLat, double? otherLng) {
    if (otherLat == null || otherLng == null) return false;
    return (lat - otherLat).abs() < 1e-5 && (lng - otherLng).abs() < 1e-5;
  }

  @override
  String toString() => 'StoredParcelLocation($lat, $lng, "$label")';
}

abstract final class ParcelLocationStore {
  /// Rechaza lo que no puede ser una parcela.
  ///
  /// Misma regla que `ParcelLocationResolver._build`, incluido (0,0): en este
  /// proyecto es el marcador de «sin ubicación» y además cae en mitad del
  /// Atlántico.
  static bool areUsableCoordinates(double lat, double lng) {
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat == 0 && lng == 0) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }

  // ── Lectura local ─────────────────────────────────────────────────────────

  /// Lo último que el usuario eligió, según el teléfono. Sin red.
  static Future<StoredParcelLocation?> readLocal() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return _fromPrefs(prefs);
    } catch (_) {
      return null;
    }
  }

  static StoredParcelLocation? _fromPrefs(SharedPreferences prefs) {
    final double? lat = prefs.getDouble(ParcelLocationKeys.lat);
    final double? lng = prefs.getDouble(ParcelLocationKeys.lng);
    if (lat == null || lng == null) return null;
    if (!areUsableCoordinates(lat, lng)) return null;

    final String label =
        prefs.getString(ParcelLocationKeys.label)?.trim() ??
        prefs.getString(ProfileLocalService.kLocationKey)?.trim() ??
        '';

    final int? millis = prefs.getInt(_kPrefUpdatedAt);

    return StoredParcelLocation(
      lat: lat,
      lng: lng,
      label: label,
      origin: ParcelLocationOrigin.fromId(prefs.getString(_kPrefOrigin)),
      updatedAt: millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true),
    );
  }

  /// Metadatos que no existían antes de la sincronización con la nube. Van
  /// aparte de `ParcelLocationKeys` porque aquellas tres claves las lee medio
  /// proyecto y no conviene ampliar ese contrato.
  static const String _kPrefOrigin = 'profile_location_source';
  static const String _kPrefUpdatedAt = 'profile_location_updated_at_ms';

  // ── Escritura ─────────────────────────────────────────────────────────────

  /// Guarda la ubicación elegida y la espeja a la nube.
  ///
  /// Devuelve true si además logró escribirla en Supabase. Un false NO
  /// significa que no se haya guardado: lo local ya está escrito cuando esta
  /// llamada termina.
  static Future<bool> save({
    required double lat,
    required double lng,
    required String label,
    required ParcelLocationOrigin origin,
    ProfileRepository? repository,
  }) async {
    if (!areUsableCoordinates(lat, lng)) {
      throw ArgumentError('Coordenadas no utilizables como parcela: $lat, $lng');
    }

    final String cleanLabel = label.trim();
    final DateTime now = DateTime.now().toUtc();

    // 1) Local. Las dos claves de etiqueta, siempre juntas: es el bug nº 1.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(ParcelLocationKeys.lat, lat);
    await prefs.setDouble(ParcelLocationKeys.lng, lng);
    await prefs.setString(_kPrefOrigin, origin.id);
    await prefs.setInt(_kPrefUpdatedAt, now.millisecondsSinceEpoch);

    // Una etiqueta vacía NO borra la que hubiera.
    //
    // Antes sí: se limpiaban las dos claves y, más abajo, se mandaba cadena
    // vacía a `updateProfile`, que la convierte en NULL. Guardar un punto
    // válido cuyo nombre no se pudo resolver —sin red, sin llave de Google—
    // dejaba coordenadas buenas y el sitio sin nombre, en el teléfono y en la
    // nube. Vacío significa «no tengo nombre nuevo», nunca «olvida el que
    // había».
    if (cleanLabel.isNotEmpty) {
      await prefs.setString(ParcelLocationKeys.label, cleanLabel);
      await prefs.setString(ProfileLocalService.kLocationKey, cleanLabel);
    }

    // 2) Nube. Best-effort: sin sesión o sin red no hay nada que hacer aquí,
    //    y lo local ya quedó bien.
    //
    // El `try` empieza en `Supabase.instance`, no después. Estaba fuera, y
    // `Supabase.instance` lanza si el cliente todavía no se inicializó: la
    // excepción salía de `save` y la pantalla de Ubicación la recogía en su
    // `catch` para decir «No se pudo guardar la ubicación» — sobre un guardado
    // local que acababa de completarse sin un rasguño. Aquí dentro, cualquier
    // fallo de nube es lo que siempre quiso ser: un `false`.
    try {
      final SupabaseClient client = Supabase.instance.client;
      if (client.auth.currentUser == null) return false;

      final ProfileRepository repo = repository ?? ProfileRepository(client);
      await repo.updateProfile(
        location: cleanLabel.isEmpty ? null : cleanLabel,
        locationLat: lat,
        locationLng: lng,
        locationSource: origin.id,
        locationUpdatedAt: now,
      );
      return true;
    } catch (e) {
      debugPrint('[BioG/ParcelLocationStore] no se pudo espejar a Supabase: $e');
      return false;
    }
  }

  // ── Rehidratación desde la nube ───────────────────────────────────────────

  /// Recupera la ubicación de la nube cuando el teléfono no la tiene.
  ///
  /// Es lo que hace que una reinstalación no pierda la parcela. Se llama al
  /// arrancar con sesión abierta.
  ///
  /// ── Por qué lo remoto NO pisa a lo local por defecto ──────────────────────
  ///
  /// Porque lo local es lo último que el usuario eligió con el dedo, y puede
  /// haberse guardado sin cobertura y no haber llegado todavía a la nube. Pisarlo
  /// con una fila remota vieja devolvería al usuario a una ubicación que ya
  /// cambió. Solo gana lo remoto cuando no hay nada local, o cuando lo remoto
  /// es demostrablemente más reciente ([preferNewest]).
  ///
  /// Devuelve la ubicación que quedó vigente, o null si no hay ninguna.
  static Future<StoredParcelLocation?> hydrateFromCloud({
    ProfileRepository? repository,
    bool preferNewest = true,
    UserProfile? knownProfile,
  }) async {
    final SupabaseClient client = Supabase.instance.client;
    if (client.auth.currentUser == null) return readLocal();

    final StoredParcelLocation? local = await readLocal();

    // Quien ya tenga el perfil en la mano lo pasa en [knownProfile] y se
    // ahorra la segunda descarga. La pantalla de Cuenta lo acaba de pedir
    // para el teléfono y el avatar: volver a pedirlo aquí sería la misma
    // consulta dos veces por cada entrada a la pantalla.
    UserProfile? profile = knownProfile;
    if (profile == null) {
      try {
        final ProfileRepository repo = repository ?? ProfileRepository(client);
        profile = await repo.getMyProfile();
      } catch (e) {
        debugPrint('[BioG/ParcelLocationStore] no se pudo leer el perfil: $e');
        return local;
      }
    }

    final double? remoteLat = profile?.locationLat;
    final double? remoteLng = profile?.locationLng;

    if (profile == null ||
        remoteLat == null ||
        remoteLng == null ||
        !areUsableCoordinates(remoteLat, remoteLng)) {
      // La nube no tiene coordenadas. Si el teléfono sí, se suben: es el caso
      // de un perfil creado antes de que estas columnas existieran.
      if (local != null) {
        await _backfillToCloud(local, repository: repository, client: client);
      }
      return local;
    }

    final StoredParcelLocation remote = StoredParcelLocation(
      lat: remoteLat,
      lng: remoteLng,
      label: (profile.location ?? '').trim(),
      origin: ParcelLocationOrigin.fromId(profile.locationSource),
      updatedAt: profile.locationUpdatedAt?.toUtc(),
    );

    if (local == null) {
      await _writeLocal(remote);
      return remote;
    }

    if (!preferNewest) {
      await _pushIfDifferent(
        local,
        remote,
        repository: repository,
        client: client,
      );
      return local;
    }

    final DateTime? localAt = local.updatedAt;
    final DateTime? remoteAt = remote.updatedAt;

    // Sin marca de tiempo local no se puede comparar, y ante la duda gana el
    // teléfono: es donde el usuario tocó por última vez.
    if (localAt == null || remoteAt == null || !remoteAt.isAfter(localAt)) {
      await _pushIfDifferent(
        local,
        remote,
        repository: repository,
        client: client,
      );
      return local;
    }

    await _writeLocal(remote);
    return remote;
  }

  /// Sube al perfil lo que tiene el teléfono cuando la nube dice otra cosa y
  /// manda el teléfono.
  ///
  /// ── El agujero que esto tapa ───────────────────────────────────────────
  ///
  /// `save` espeja a Supabase, pero es best-effort: sin cobertura devuelve
  /// false y la ubicación se queda solo en el teléfono. La rehidratación era
  /// la única segunda oportunidad, y solo subía cuando la nube no tenía
  /// NINGUNA coordenada. Si arriba había un punto viejo —el caso normal en
  /// cuanto el usuario mueve su parcela por segunda vez— la comparación
  /// concluía «gana el teléfono» y se marchaba sin escribir nada.
  ///
  /// El resultado era el peor posible para quien mira desde fuera: la app
  /// enseña la parcela nueva, el motor de riego usa la parcela nueva, y el
  /// panel sigue pintando el pin en el sitio anterior. Desde el teléfono es
  /// indistinguible de «no se guardó».
  ///
  /// Solo escribe si de verdad hay diferencia, para que la siguiente
  /// rehidratación no vuelva a subir lo mismo.
  static Future<void> _pushIfDifferent(
    StoredParcelLocation local,
    StoredParcelLocation remote, {
    required SupabaseClient client,
    ProfileRepository? repository,
  }) async {
    final String localLabel = local.label.trim();

    final bool sameSpot = local.sameSpotAs(remote.lat, remote.lng);

    // Una etiqueta local vacía no contradice a la de la nube: es «no tengo
    // nombre», no «el nombre es ninguno». Contarla como diferencia haría subir
    // un vacío que borraría el nombre bueno que ya está arriba.
    final bool sameLabel =
        localLabel.isEmpty || localLabel == remote.label.trim();

    if (sameSpot && sameLabel) return;

    await _backfillToCloud(local, repository: repository, client: client);
  }

  static Future<void> _writeLocal(StoredParcelLocation location) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(ParcelLocationKeys.lat, location.lat);
      await prefs.setDouble(ParcelLocationKeys.lng, location.lng);

      final String label = location.label.trim();
      if (label.isNotEmpty) {
        await prefs.setString(ParcelLocationKeys.label, label);
        await prefs.setString(ProfileLocalService.kLocationKey, label);
      }

      final ParcelLocationOrigin? origin = location.origin;
      if (origin != null) await prefs.setString(_kPrefOrigin, origin.id);

      final DateTime? at = location.updatedAt;
      if (at != null) {
        await prefs.setInt(_kPrefUpdatedAt, at.toUtc().millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('[BioG/ParcelLocationStore] no se pudo escribir local: $e');
    }
  }

  static Future<void> _backfillToCloud(
    StoredParcelLocation location, {
    required SupabaseClient client,
    ProfileRepository? repository,
  }) async {
    try {
      final ProfileRepository repo = repository ?? ProfileRepository(client);
      final String label = location.label.trim();
      await repo.updateProfile(
        // Null significa «no toques la etiqueta». Mandar cadena vacía la
        // pondría a NULL en la fila y dejaría coordenadas buenas con el sitio
        // sin nombre: un pin anónimo en el panel.
        location: label.isEmpty ? null : label,
        locationLat: location.lat,
        locationLng: location.lng,
        locationSource: (location.origin ?? ParcelLocationOrigin.map).id,
        locationUpdatedAt: location.updatedAt ?? DateTime.now().toUtc(),
      );
    } catch (e) {
      debugPrint('[BioG/ParcelLocationStore] backfill fallido: $e');
    }
  }
}
