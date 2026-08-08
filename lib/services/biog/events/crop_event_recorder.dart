import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/core/notifications/notification_dispatcher.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/screens/history/history_presenter.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/services/biog/events/crop_event_local_storage.dart';
import 'package:bio_g/services/biog/storage/telemetry_local_storage.dart';

/// Registra los eventos del cultivo para que existan aunque nadie tenga la
/// pantalla abierta.
///
/// Decisión de diseño deliberada: **reutiliza el mismo cálculo del Historial**,
/// `HistoryScreenPresenter.buildAgronomicEvents`, en lugar de reimplementarlo.
/// Ese presenter es una clase pura —constructor `const`, sin `BuildContext`, sin
/// dependencias de widget— así que puede llamarse desde aquí sin problema.
///
/// La razón de reusarlo y no copiarlo: garantiza que lo que se guarda sea
/// **idéntico** a lo que el agricultor ve en el Historial. Si algún día se
/// afinan las reglas de eventos, se afinan en un solo lugar y ambos siguen
/// coincidiendo. Duplicar la lógica habría creado dos verdades que se separan
/// con el tiempo.
///
/// Nada de esto altera el comportamiento visible: ni el Panel ni el Historial
/// cambian. Solo se agrega memoria.
class CropEventRecorder {
  CropEventRecorder({
    CropEventLocalStorage? storage,
    TelemetryLocalStorage? telemetryStorage,
    NotificationDispatcher? notificationDispatcher,
  }) : _storage = storage ?? CropEventLocalStorage(),
       _telemetryStorage = telemetryStorage ?? TelemetryLocalStorage(),
       _notifications = notificationDispatcher ?? NotificationDispatcher();

  static const HistoryScreenPresenter _presenter = HistoryScreenPresenter();

  final CropEventLocalStorage _storage;
  final TelemetryLocalStorage _telemetryStorage;

  /// Bandeja de avisos.
  ///
  /// Antes, guardar el evento era el final del camino y nadie volvía a
  /// leerlo. Ahora el mismo cálculo alimenta la bandeja, que aplica las
  /// preferencias del usuario y conserva lo que merece avisarse.
  final NotificationDispatcher _notifications;

  /// Evita recalcular sobre la misma lectura si el store notifica varias veces.
  String? _lastSignature;

  /// Impide que dos registros se solapen si llegan lecturas seguidas.
  bool _running = false;

  CropEventLocalStorage get storage => _storage;

  NotificationDispatcher get notifications => _notifications;

  /// Calcula y guarda los eventos nuevos a partir del estado actual del store.
  ///
  /// Es seguro llamarlo con cualquier frecuencia: si nada cambió desde la
  /// última vez, sale sin tocar disco. Cualquier fallo se traga a propósito —
  /// registrar la memoria del cultivo jamás debe interrumpir al usuario.
  Future<void> recordFromStore(BioGStore store) async {
    if (_running) return;

    final String? deviceId = store.activeDevice?.id;
    final BioGTelemetry? live = store.live;
    if (deviceId == null || live == null) return;

    // Firma del estado: si la lectura y el contexto son los mismos, no hay
    // eventos nuevos que calcular.
    final String signature = <Object?>[
      deviceId,
      live.timestamp.toUtc().millisecondsSinceEpoch,
      store.activeCropContext?.cropId,
      store.activeCropContext?.updatedAt.millisecondsSinceEpoch,
    ].join('|');
    if (signature == _lastSignature) return;

    _running = true;
    try {
      final String? telemetryId = store.activeDevice?.telemetryDeviceId;
      final List<BioGTelemetry> history = telemetryId == null
          ? const <BioGTelemetry>[]
          : await _telemetryStorage.load(telemetryId);

      final CropRuntimeSnapshot runtime = CropRuntimeResolver.resolve(
        device: store.activeDevice,
        seed: store.activeSeed,
        cropContext: store.activeCropContext,
        live: live,
        alertsState: store.alertsState,
      );

      final List<AgronomicEvent> events = _presenter.buildAgronomicEvents(
        store: store,
        runtime: runtime,
        telemetry: history,
      );

      // El `userId` es lo que permite purgar este historial al cerrar sesión.
      // Sin él, cambiar de cuenta en el mismo teléfono dejaba los eventos del
      // usuario anterior en disco sin ninguna ruta de borrado.
      await _storage.saveNew(deviceId, events, userId: store.currentUserId);

      // Y aquí el registro deja de ser de escritura pura: los mismos eventos
      // alimentan la bandeja de avisos, que decide qué merece molestar al
      // agricultor según lo que él configuró.
      await _notifications.ingestEvents(events);

      _lastSignature = signature;
    } catch (_) {
      // Silencio deliberado: este registro es memoria, no funcionalidad. Si
      // falla, el agricultor no debe enterarse ni ver nada distinto.
    } finally {
      _running = false;
    }
  }

  /// Limpia la firma al cambiar de usuario o de dispositivo activo.
  void reset() {
    _lastSignature = null;
  }

  /// Borra el historial de eventos y los avisos de un usuario.
  ///
  /// Se llama al cerrar sesión: el historial agronómico de una cuenta no puede
  /// quedar en el teléfono a la vista de la siguiente.
  Future<void> purgeForUser(String? userId) async {
    _lastSignature = null;
    if (userId != null && userId.isNotEmpty) {
      await _storage.deleteForUser(userId);
    }
    await _notifications.clear();
  }
}
