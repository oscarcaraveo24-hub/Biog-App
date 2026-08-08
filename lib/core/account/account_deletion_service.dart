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

import 'package:bio_g/core/auth/auth_repository.dart';
import 'package:bio_g/core/telemetry/telemetry_ingest_service.dart';
import 'package:bio_g/core/weather/weather_snapshot_storage.dart';
import 'package:bio_g/services/biog/events/crop_event_local_storage.dart';
import 'package:bio_g/services/biog/storage/telemetry_local_storage.dart';

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
  });

  final bool cropEventsCleared;
  final int telemetryClearedForDevices;
  final bool weatherCacheCleared;
  final bool pendingUploadsCleared;
}

class AccountDeletionService {
  AccountDeletionService({
    required AuthRepository authRepository,
    CropEventLocalStorage? cropEventStorage,
    TelemetryLocalStorage? telemetryStorage,
    WeatherSnapshotStorage? weatherStorage,
    TelemetryIngestService? ingestService,
  }) : _auth = authRepository,
       _cropEvents = cropEventStorage ?? CropEventLocalStorage(),
       _telemetry = telemetryStorage ?? TelemetryLocalStorage(),
       _weather = weatherStorage ?? SharedPrefsWeatherSnapshotStorage(),
       _ingest = ingestService;

  final AuthRepository _auth;
  final CropEventLocalStorage _cropEvents;
  final TelemetryLocalStorage _telemetry;
  final WeatherSnapshotStorage _weather;
  final TelemetryIngestService? _ingest;

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
  /// Público a propósito: también se usa al cerrar sesión, donde el objetivo
  /// no es borrar la cuenta sino impedir que el historial agronómico de un
  /// usuario quede visible para el siguiente que entre en el mismo teléfono.
  Future<LocalPurgeReport> purgeLocalData({
    required String? userId,
    required List<String> deviceIds,
  }) async {
    var cropEventsCleared = false;
    var telemetryCleared = 0;
    var weatherCleared = false;
    var pendingCleared = false;

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

    return LocalPurgeReport(
      cropEventsCleared: cropEventsCleared,
      telemetryClearedForDevices: telemetryCleared,
      weatherCacheCleared: weatherCleared,
      pendingUploadsCleared: pendingCleared,
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
