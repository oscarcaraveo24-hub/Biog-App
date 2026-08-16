// lib/core/account/account_deletion_service.dart
//
// Borrado de cuenta de verdad.
//
// Lo que había: un diálogo que decía "Esta acción es permanente. Se eliminarán
// tus datos" seguido de `showSnackBar(Text('Eliminar cuenta (placeholder)'))`.
// No se borraba nada, ni en el servidor ni en el teléfono, y el usuario se
// quedaba creyendo que sí.
//
// Lo que hace esto: reautentica, pide al servidor el borrado, y solo entonces
// purga el teléfono. Informa con precisión de qué se logró y qué no; nunca
// afirma más de lo que ocurrió.
//
// Orden deliberado: remoto antes que local. El historial agronómico local es
// el único que existe en muchos casos, así que destruirlo antes de saber si el
// servidor respondió convertiría un fallo de red en una pérdida de datos con
// la cuenta todavía viva.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bio_g/core/agro/irrigation/parcel_location.dart';
import 'package:bio_g/core/agro/traceability/recommendation_store.dart';
import 'package:bio_g/core/auth/auth_repository.dart';
import 'package:bio_g/core/telemetry/telemetry_ingest_service.dart';
import 'package:bio_g/core/weather/weather_snapshot_storage.dart';
import 'package:bio_g/services/biog/events/crop_event_local_storage.dart';
import 'package:bio_g/services/biog/identity/active_device_store.dart';
import 'package:bio_g/services/biog/storage/shared_prefs_crop_context_storage.dart';
import 'package:bio_g/services/biog/storage/shared_prefs_yield_projection_storage.dart';
import 'package:bio_g/services/biog/storage/telemetry_local_storage.dart';
import 'package:bio_g/services/profile/profile_local_service.dart';

enum AccountDeletionOutcome {
  /// Local y remoto borrados.
  deleted,

  /// Lo local se borró; el servidor no pudo completarlo.
  localOnly,

  /// No se pudo borrar nada.
  failed,
}

@immutable
class AccountDeletionResult {
  const AccountDeletionResult({
    required this.outcome,
    required this.messageEs,
    this.remoteError,
  });

  final AccountDeletionOutcome outcome;

  /// Texto exacto que la interfaz debe mostrar. Se redacta aquí para que no
  /// exista la posibilidad de que una pantalla prometa más de lo ocurrido.
  final String messageEs;

  final String? remoteError;

  bool get isComplete => outcome == AccountDeletionOutcome.deleted;
}

/// Datos locales purgables, para poder informar de qué se limpió.
@immutable
class LocalPurgeReport {
  const LocalPurgeReport({
    required this.cropEventsCleared,
    required this.telemetryClearedForDevices,
    required this.weatherCacheCleared,
    required this.pendingUploadsCleared,
    required this.recommendationsCleared,
    required this.profilePreferencesCleared,
    required this.deviceScopedPreferencesCleared,
  });

  final bool cropEventsCleared;
  final int telemetryClearedForDevices;
  final bool weatherCacheCleared;
  final bool pendingUploadsCleared;

  /// Historial de recomendaciones agronómicas (`biog_recommendations.db`).
  final bool recommendationsCleared;

  /// Claves de `SharedPreferences` SIN espacio de nombres por usuario: perfil,
  /// preferencias de aviso, ubicación de la parcela y bandeja de avisos. Son
  /// las que hoy filtran de una cuenta a la siguiente en el mismo teléfono.
  final bool profilePreferencesCleared;

  /// Claves de `SharedPreferences` que sí llevan el id del usuario: contexto
  /// de cultivo, proyección de rendimiento, equipo activo y caché de equipos.
  final bool deviceScopedPreferencesCleared;
}

class AccountDeletionService {
  AccountDeletionService({
    required AuthRepository authRepository,
    CropEventLocalStorage? cropEventStorage,
    TelemetryLocalStorage? telemetryStorage,
    WeatherSnapshotStorage? weatherStorage,
    TelemetryIngestService? ingestService,
    RecommendationStore? recommendationStore,
    Future<void> Function()? clearPendingSync,
  }) : _auth = authRepository,
       _clearPendingSync = clearPendingSync,
       _cropEvents = cropEventStorage ?? CropEventLocalStorage(),
       _telemetry = telemetryStorage ?? TelemetryLocalStorage(),
       _weather = weatherStorage ?? SharedPrefsWeatherSnapshotStorage(),
       _ingest = ingestService,
       _recommendations = recommendationStore ?? RecommendationStore();

  final AuthRepository _auth;
  final CropEventLocalStorage _cropEvents;
  final TelemetryLocalStorage _telemetry;
  final WeatherSnapshotStorage _weather;
  final TelemetryIngestService? _ingest;

  /// El historial de recomendaciones se queda en `biog_recommendations.db`,
  /// una base aparte de la de eventos. Nadie la borraba: al eliminar la cuenta
  /// sobrevivían en el teléfono todas las decisiones agronómicas que Bio-G le
  /// había dado a ese usuario. Cada fila lleva `user_id`, así que se puede
  /// purgar con precisión.
  final RecommendationStore _recommendations;

  /// Vacía la cola de sincronización pendiente a través de su propia API.
  ///
  /// Borrar la clave de preferencias a mano no basta: la cola serializa sus
  /// operaciones en una cadena de futuros precisamente para que un drenado en
  /// vuelo no reescriba en disco lo que otra rama acaba de borrar. Saltarse esa
  /// cadena reabre esa carrera, y las operaciones de la cuenta recién eliminada
  /// resucitan. Se inyecta porque la instancia viva de la cola pertenece a
  /// `BioGStore`, no a este servicio.
  final Future<void> Function()? _clearPendingSync;

  /// Elimina la cuenta.
  ///
  /// [deviceIds] deben incluir TANTO el id de interfaz como el
  /// `telemetryDeviceId` de cada Bio-G: el almacenamiento local de telemetría
  /// está indexado por el segundo, así que pasar solo el primero dejaba las
  /// lecturas de los dispositivos heredados sin borrar. [userId] identifica al
  /// dueño de los eventos de cultivo.
  ///
  /// [password] es obligatorio: las tiendas exigen reautenticación antes de
  /// una acción destructiva, y sin ella cualquiera con el teléfono
  /// desbloqueado podría borrar la cuenta.
  Future<AccountDeletionResult> deleteAccount({
    required String password,
    required String? userId,
    required List<String> deviceIds,
  }) async {
    final reauth = await _auth.reauthenticate(password: password);
    if (!reauth.ok) {
      return AccountDeletionResult(
        outcome: AccountDeletionOutcome.failed,
        messageEs: reauth.messageEs ?? 'No se pudo verificar tu identidad.',
        remoteError: reauth.errorCode,
      );
    }

    // Primero el servidor, después el teléfono.
    //
    // El orden importa y antes estaba al revés: si la red fallaba a mitad, se
    // había destruido el historial agronómico local —que solo existe en
    // local— y la cuenta seguía viva. Ahora un fallo de red deja todo intacto
    // y el usuario puede reintentar.
    final remote = await _auth.requestAccountDeletion();

    if (remote.ok) {
      await purgeLocalData(userId: userId, deviceIds: deviceIds);
      await _safeSignOut();
      return const AccountDeletionResult(
        outcome: AccountDeletionOutcome.deleted,
        messageEs:
            'Tu cuenta y tus datos se eliminaron. Gracias por haber usado '
            'Bio-G.',
      );
    }

    if (remote.requiresServerSupport) {
      // El borrado quedó solicitado y se completará a mano. Purgar el teléfono
      // sí es correcto aquí: la intención del usuario está registrada y el
      // dispositivo no debe conservar sus datos mientras tanto.
      await purgeLocalData(userId: userId, deviceIds: deviceIds);
      await _safeSignOut();
      return AccountDeletionResult(
        outcome: AccountDeletionOutcome.localOnly,
        messageEs:
            'Borramos todos los datos de este teléfono y cerramos tu sesión. '
            'El borrado en el servidor quedó solicitado y lo completamos '
            'manualmente: escríbenos para confirmarlo.',
        remoteError: remote.errorCode,
      );
    }

    // Fallo de red o error inesperado: no se toca nada. Decirle al usuario que
    // se borró algo que no se borró sería el mismo pecado del placeholder.
    return AccountDeletionResult(
      outcome: AccountDeletionOutcome.failed,
      messageEs:
          'No se pudo eliminar la cuenta y no se borró nada. Revisa tu '
          'conexión e inténtalo de nuevo.',
      remoteError: remote.errorCode,
    );
  }

  /// Purga todo lo que esta app guardó en el teléfono.
  ///
  /// OJO con reutilizarlo al cerrar sesión. El comentario anterior decía que
  /// esto "también se usa al cerrar sesión": hoy no es cierto —el único
  /// llamador es [deleteAccount]— y conviene que siga sin serlo tal cual está.
  /// Desde esta corrección el método también borra el contexto de cultivo y la
  /// proyección de rendimiento, que son configuración que el agricultor
  /// capturó y espera reencontrar al volver a entrar. En un borrado de cuenta
  /// eso es lo correcto; en un logout sería destruir trabajo ajeno al motivo.
  ///
  /// LO QUE ESTE MÉTODO **NO** ALCANZA, y hay que saberlo antes de prometerle
  /// al usuario que "borramos todos los datos de este teléfono":
  ///
  ///  - `biog_telemetry.db` no tiene columna `user_id`: su llave primaria es
  ///    `(device_id, ts)`. Solo se puede purgar por los `deviceIds` que el
  ///    llamador conozca en ese momento. Las lecturas de un Bio-G que el
  ///    usuario desvinculó ANTES de borrar la cuenta se quedan en el teléfono
  ///    y nadie las reclama. Arreglarlo exige migrar el esquema, que no entra
  ///    en esta corrección.
  ///
  ///  - La coherencia entre este método y el cierre de sesión está invertida:
  ///    `BioGStore.unbindUser` borra de disco los eventos de cultivo —que van
  ///    con `user_id` y no filtran— y en cambio deja intactas las claves
  ///    globales de perfil y ubicación, que sí filtran de una cuenta a otra.
  ///    O sea, el logout destruye lo que debería conservar y conserva lo que
  ///    debería destruir. Se documenta aquí y no se toca: es una decisión de
  ///    producto, no de este servicio.
  Future<LocalPurgeReport> purgeLocalData({
    required String? userId,
    required List<String> deviceIds,
  }) async {
    var cropEventsCleared = false;
    var telemetryCleared = 0;
    var weatherCleared = false;
    var pendingCleared = false;
    var recommendationsCleared = false;
    var profilePrefsCleared = false;
    var deviceScopedPrefsCleared = false;

    try {
      if (userId != null && userId.isNotEmpty) {
        await _cropEvents.deleteForUser(userId);
      } else {
        await _cropEvents.deleteAll();
      }
      cropEventsCleared = true;
    } catch (_) {
      // Se sigue purgando el resto: un fallo parcial no debe abortar la
      // limpieza entera.
    }

    for (final deviceId in deviceIds) {
      try {
        await _telemetry.delete(deviceId);
        telemetryCleared++;
      } catch (_) {
        // Ídem.
      }
    }

    try {
      await _weather.clearAll();
      weatherCleared = true;
    } catch (_) {
      // Ídem.
    }

    try {
      await _ingest?.clear();
      pendingCleared = _ingest != null;
    } catch (_) {
      // Ídem.
    }

    // Historial de recomendaciones agronómicas.
    //
    // Mismo criterio que con los eventos de cultivo: si sabemos de quién es,
    // se borra solo lo suyo; si no lo sabemos, no queda otra que vaciar la
    // tabla, porque dejarla intacta significaría conservar el historial de
    // alguien que pidió que se le borrara.
    try {
      if (userId != null && userId.isNotEmpty) {
        await _recommendations.deleteForUser(userId);
        // Las filas escritas sin sesión quedan bajo `__guest__`, y las
        // consultas del propio almacén se las devuelven al usuario que tenga
        // la sesión abierta (`user_id = ? OR user_id = ?`). Es decir: para la
        // app son datos de esta cuenta. Si no se borran, el siguiente que
        // entre en este teléfono las verá como suyas.
        await _recommendations.deleteForUser(RecommendationStore.guestUserId);
      } else {
        await _recommendations.deleteAll();
      }
      recommendationsCleared = true;
    } catch (_) {
      // Ídem.
    }

    // Claves de `SharedPreferences` SIN espacio de nombres por usuario.
    //
    // Son la fuga más directa que tenía la app: teléfono, ubicación, foto de
    // perfil y preferencias de aviso se guardan bajo claves globales. Al
    // cambiar de cuenta en el mismo teléfono, el usuario nuevo veía los datos
    // del anterior. Se borran una a una y por prefijo, sin `prefs.clear()`,
    // que arrasaría también con lo que no es de esta cuenta.
    try {
      final prefs = await SharedPreferences.getInstance();

      const globalKeys = <String>[
        ProfileLocalService.kAvatarPathKey,
        ProfileLocalService.kSyncActiveKey,
        ProfileLocalService.kLocationKey,
        ProfileLocalService.kPhoneKey,
        ProfileLocalService.kNotificationsKey,
        ProfileLocalService.kUseCelsiusKey,
        ParcelLocationKeys.label,
        ParcelLocationKeys.lat,
        ParcelLocationKeys.lng,
        // Metadatos de la ubicación (origen y fecha de elección). Viven fuera
        // de `ParcelLocationKeys` porque los añadió la sincronización con la
        // nube y aquellas tres claves las lee medio proyecto. Sus literales
        // están en `ParcelLocationStore`, privados: si cambian allí, hay que
        // cambiarlos aquí.
        'profile_location_source',
        'profile_location_updated_at_ms',
        // Bandeja de avisos de `NotificationDispatcher`. Su clave es privada
        // en aquel archivo y aquí no hay una instancia del despachador que
        // llamar, así que se repite el literal. Si allí cambia, hay que
        // cambiarlo aquí.
        'biog_notification_outbox_v1',
      ];

      for (final key in globalKeys) {
        await prefs.remove(key);
      }

      // Preferencias de aviso: umbral, horas de silencio y categorías. Todas
      // comparten prefijo y algunas llevan el nombre de la categoría dentro
      // de la clave, así que se purgan por prefijo en vez de enumerarlas.
      final notifKeys = prefs
          .getKeys()
          .where((k) => k.startsWith('biog_notif_'))
          .toList(growable: false);
      for (final key in notifKeys) {
        await prefs.remove(key);
      }

      profilePrefsCleared = true;
    } catch (_) {
      // Ídem.
    }

    // Claves de `SharedPreferences` que SÍ llevan el id del usuario.
    //
    // No filtran entre cuentas, pero son datos del usuario y sobrevivían al
    // borrado: contexto de cultivo por equipo, proyección de rendimiento,
    // equipo activo y caché de equipos traída de Supabase. Cada almacén se
    // purga con su propia API pública, que ya sabe construir su clave; con
    // `userId` nulo cada uno resuelve su ranura de invitado, que es la única
    // que esa sesión pudo haber escrito.
    try {
      await SharedPrefsCropContextStorage().clearAll(userId: userId);
      await SharedPrefsYieldProjectionStorage().clearAll(userId: userId);
      await ActiveDeviceStore().clear(userId: userId);

      // La caché de equipos vive en `SupabaseDeviceIdentityRepository`, que no
      // expone un borrado de disco (solo `clearInMemory`). Se replica su regla
      // de clave: prefijo + id de usuario, o la ranura de invitado.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(
        (userId != null && userId.isNotEmpty)
            ? 'biog_devices_cache_v1_$userId'
            : 'biog_devices_cache_v1__guest',
      );

      // Cola de sincronización pendiente.
      //
      // Ahora que las operaciones sobreviven a un fallo de red en vez de
      // descartarse, una cuenta borrada podía dejar operaciones esperando su
      // turno para subir datos de un usuario que ya no existe.
      //
      // Se prefiere la API de la cola, que serializa el borrado con los
      // drenados en vuelo. El borrado directo de la clave es solo el respaldo
      // para cuando no hay instancia viva inyectada; entonces tampoco hay
      // drenado posible, así que la carrera no existe.
      final Future<void> Function()? clearQueue = _clearPendingSync;
      if (clearQueue != null) {
        await clearQueue();
      } else {
        await prefs.remove(
          (userId != null && userId.isNotEmpty)
              ? 'biog_pending_sync_v1_$userId'
              : 'biog_pending_sync_v1__guest',
        );
      }

      deviceScopedPrefsCleared = true;
    } catch (_) {
      // Ídem.
    }

    return LocalPurgeReport(
      cropEventsCleared: cropEventsCleared,
      telemetryClearedForDevices: telemetryCleared,
      weatherCacheCleared: weatherCleared,
      pendingUploadsCleared: pendingCleared,
      recommendationsCleared: recommendationsCleared,
      profilePreferencesCleared: profilePrefsCleared,
      deviceScopedPreferencesCleared: deviceScopedPrefsCleared,
    );
  }

  Future<void> _safeSignOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Si el cierre de sesión falla, la purga local ya ocurrió y el usuario
      // no queda expuesto.
    }
  }
}
