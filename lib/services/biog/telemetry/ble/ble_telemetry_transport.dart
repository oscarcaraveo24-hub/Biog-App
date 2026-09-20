// lib/services/biog/telemetry/ble/ble_telemetry_transport.dart
//
// Implementacion BLE real de [TelemetryTransport]. Es la unica clase del
// proyecto que sabe que existe flutter_blue_plus.
//
// Lo que entra por aqui sale ya convertido en [TelemetryEnvelope] y se va por
// `envelopes`, donde TelemetryIngestService lo recoge y hace el resto del
// camino: validar -> guardar local -> marcar pendiente -> subir -> confirmar.
// Ese camino ya estaba escrito y probado; esto solo lo alimenta.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:bio_g/core/telemetry/telemetry_contract.dart';
import 'package:bio_g/core/telemetry/telemetry_transport.dart';
import 'package:bio_g/services/biog/telemetry/ble/biog_ble_codec.dart';
import 'package:bio_g/services/biog/telemetry/ble/biog_ble_config.dart';

/// Por que el enlace no esta disponible. La pantalla lo usa para decirle al
/// usuario que hacer en vez de mostrar una lista vacia.
enum BleUnavailableReason {
  /// El telefono no tiene BLE o la plataforma no lo soporta.
  unsupported,

  /// El usuario no concedio los permisos de Bluetooth.
  unauthorized,

  /// El Bluetooth esta apagado.
  adapterOff,

  /// Disponible.
  none,
}

class BleTelemetryTransport implements TelemetryTransport {
  BleTelemetryTransport();

  final StreamController<TelemetryEnvelope> _envelopes =
      StreamController<TelemetryEnvelope>.broadcast();
  final StreamController<TelemetryLinkState> _states =
      StreamController<TelemetryLinkState>.broadcast();

  TelemetryLinkState _state = TelemetryLinkState.disconnected;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _telemetryChr;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  /// Identidad declarada por el aparato conectado.
  ///
  /// Es lo que la pantalla necesita para devolver un `deviceId` real en vez de
  /// la MAC. Se puebla al conectar, leyendo la caracteristica de Identidad.
  TelemetryDeviceIdentity? _identity;
  TelemetryDeviceIdentity? get connectedIdentity => _identity;

  /// RSSI del ultimo escaneo. Lo pone el telefono, no el aparato: pedirle al
  /// ESP32 que reporte su propia potencia recibida no tendria sentido.
  int? _lastRssi;

  /// Ultimo fallo de escaneo, en crudo.
  ///
  /// Existe porque el modo de fallo tipico aqui es mudo: en Android, si los
  /// servicios de ubicacion estan apagados, la capa nativa lanza y el usuario
  /// solo veria una lista vacia y un "no encontre nada" que miente sobre la
  /// causa. Mejor ensenar el error real.
  String? lastScanError;

  /// MTU realmente acordado con el aparato. **No se asume que sea el pedido.**
  int? _negotiatedMtu;
  int? get negotiatedMtu => _negotiatedMtu;

  /// Bytes utiles por notificacion con el MTU vigente (MTU - 3 de cabecera
  /// ATT). Es el numero que decide si un sobre de telemetria cabe entero.
  int? get notificationPayloadBytes =>
      _negotiatedMtu == null ? null : _negotiatedMtu! - 3;

  /// Aviso cuando el MTU acordado se quedo corto para la telemetria.
  ///
  /// No aborta la conexion: un sobre pequeno todavia puede caber. Pero deja
  /// de ser un fallo mudo, que era el riesgo real.
  String? mtuWarning;

  bool _disposed = false;

  @override
  String get name => 'ble';

  @override
  TelemetryLinkState get state => _state;

  @override
  Stream<TelemetryLinkState> get stateChanges => _states.stream;

  @override
  Stream<TelemetryEnvelope> get envelopes => _envelopes.stream;

  // ── Disponibilidad ─────────────────────────────────────────────────────────

  /// Comprueba si se puede usar la radio, y por que no si no se puede.
  ///
  /// En Android, flutter_blue_plus pide los permisos de runtime por su cuenta
  /// desde el lado nativo al arrancar un escaneo. Lo que no hace es contarnos
  /// como fue: si el usuario los niega, el adaptador se queda en
  /// `unauthorized`. Por eso el permiso se comprueba mirando el estado del
  /// adaptador y no con un paquete de permisos aparte.
  Future<BleUnavailableReason> checkAvailability({
    Duration settleTimeout = const Duration(seconds: 4),
  }) async {
    if (!await FlutterBluePlus.isSupported) {
      return BleUnavailableReason.unsupported;
    }

    var adapter = FlutterBluePlus.adapterStateNow;

    // Al arrancar en frio el estado tarda un momento en resolverse.
    if (adapter == BluetoothAdapterState.unknown ||
        adapter == BluetoothAdapterState.turningOn) {
      try {
        adapter = await FlutterBluePlus.adapterState
            .where(
              (s) =>
                  s != BluetoothAdapterState.unknown &&
                  s != BluetoothAdapterState.turningOn,
            )
            .first
            .timeout(settleTimeout);
      } on TimeoutException {
        adapter = FlutterBluePlus.adapterStateNow;
      }
    }

    switch (adapter) {
      case BluetoothAdapterState.on:
        return BleUnavailableReason.none;
      case BluetoothAdapterState.unauthorized:
        return BleUnavailableReason.unauthorized;
      case BluetoothAdapterState.unavailable:
        return BleUnavailableReason.unsupported;
      case BluetoothAdapterState.off:
      case BluetoothAdapterState.turningOff:
      case BluetoothAdapterState.turningOn:
      case BluetoothAdapterState.unknown:
        return BleUnavailableReason.adapterOff;
    }
  }

  /// Pide encender el Bluetooth. Solo funciona en Android; en iOS el sistema
  /// no permite que una app lo encienda.
  Future<void> requestAdapterOn() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await FlutterBluePlus.turnOn(timeout: 20);
    } catch (_) {
      // Si el usuario cancela el dialogo del sistema no es un error nuestro.
    }
  }

  // ── Escaneo ────────────────────────────────────────────────────────────────

  @override
  Future<List<DiscoveredDevice>> scan({
    Duration timeout = BioGBleConfig.defaultScanTimeout,
  }) async {
    if (await checkAvailability() != BleUnavailableReason.none) {
      return const <DiscoveredDevice>[];
    }

    _setState(TelemetryLinkState.scanning);
    lastScanError = null;

    final Map<String, DiscoveredDevice> found = <String, DiscoveredDevice>{};
    StreamSubscription<List<ScanResult>>? sub;

    try {
      sub = FlutterBluePlus.onScanResults.listen((results) {
        for (final r in results) {
          if (!_looksLikeBioG(r)) continue;
          final address = r.device.remoteId.str;
          found[address] = DiscoveredDevice(
            // La MAC es SOLO la direccion de transporte. No es, y no puede
            // convertirse en, el deviceId: ese lo declara el aparato en su
            // caracteristica de Identidad y se lee al conectar.
            transportAddress: address,
            displayName: _displayNameOf(r),
            rssi: r.rssi,
          );
        }
      });

      // Escaneo SIN filtro de plataforma, a proposito.
      //
      // Lo natural seria `withServices: [serviceUuid]`, pero un UUID de 128
      // bits ocupa 18 de los 31 bytes del paquete de advertising y el nombre
      // `BIO-G-DEV-001` ocupa otros 15: no caben juntos. Si el firmware deja
      // el UUID fuera del paquete primario (que es lo normal en un ESP32),
      // un filtro por servicio en la plataforma haria que el aparato NO
      // apareciera nunca, y el respaldo por nombre de `_looksLikeBioG` seria
      // codigo muerto porque esos resultados jamas llegarian hasta aqui.
      //
      // Se filtra en Dart por servicio O por prefijo de nombre. Cuesta un
      // escaneo mas ancho durante unos segundos; a cambio funciona con las
      // dos formas de anunciarse.
      await FlutterBluePlus.startScan(timeout: timeout);

      // `startScan` con timeout vuelve enseguida; hay que esperar a que el
      // escaneo termine de verdad antes de devolver la lista. El `timeout` de
      // aqui es una red de seguridad: si la plataforma no avisara del final,
      // esta espera colgaria la pantalla para siempre.
      await FlutterBluePlus.isScanning
          .where((on) => on == false)
          .first
          .timeout(timeout + const Duration(seconds: 5));
    } on TimeoutException {
      lastScanError =
          'El escaneo no reporto su final a tiempo. Vuelve a intentar.';
    } catch (e) {
      lastScanError = e.toString();
    } finally {
      await sub?.cancel();
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
      if (_state == TelemetryLinkState.scanning) {
        _setState(
          _device != null && _device!.isConnected
              ? TelemetryLinkState.connected
              : TelemetryLinkState.disconnected,
        );
      }
    }

    final list = found.values.toList()
      ..sort((a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999));
    return List<DiscoveredDevice>.unmodifiable(list);
  }

  /// Doble red: el filtro por UUID de servicio es el fiable, pero firmware que
  /// todavia no mete el servicio en el paquete de advertising se atrapa por el
  /// prefijo del nombre.
  bool _looksLikeBioG(ScanResult r) {
    if (r.advertisementData.serviceUuids.contains(BioGBleConfig.serviceUuid)) {
      return true;
    }
    final name = _displayNameOf(r).toUpperCase();
    return name.startsWith(BioGBleConfig.advertisedNamePrefix);
  }

  String _displayNameOf(ScanResult r) {
    final adv = r.advertisementData.advName.trim();
    if (adv.isNotEmpty) return adv;
    final platform = r.device.platformName.trim();
    if (platform.isNotEmpty) return platform;
    return r.device.remoteId.str;
  }

  // ── Conexion ───────────────────────────────────────────────────────────────

  @override
  Future<bool> connect(DiscoveredDevice device) async {
    await _teardownConnection();

    final target = BluetoothDevice.fromId(device.transportAddress);
    _device = target;
    _lastRssi = device.rssi;

    try {
      // `mtu: null` a proposito: el MTU se negocia explicitamente en el paso
      // siguiente. Dejar que `connect` lo pida por su cuenta quitaria el
      // control sobre el orden y sobre el valor realmente acordado.
      await target.connect(
        license: BioGBleConfig.license,
        timeout: BioGBleConfig.connectTimeout,
        mtu: null,
      );

      _connSub = target.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          _identity = null;
          _setState(TelemetryLinkState.disconnected);
        }
      });

      // ── 1) MTU, inmediatamente despues de conectar ────────────────────────
      //
      // Antes de descubrir servicios, no despues. Es el orden que el propio
      // paquete espera: su `predelay` interno existe justamente para evitar
      // la carrera entre una actualizacion automatica de MTU que manda el
      // periferico al conectar y un `discoverServices` posterior.
      //
      // `desiredMtu` es una PETICION, no un hecho. Lo que vale de aqui en
      // adelante es [_negotiatedMtu], que es lo que el enlace acordo de
      // verdad. Un ESP32 puede conceder 185, 247 o quedarse en 23.
      _negotiatedMtu = await _negotiateMtu(target);

      // ── 2) Descubrimiento de servicios ────────────────────────────────────
      final services = await target.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid == BioGBleConfig.serviceUuid,
        orElse: () =>
            throw StateError('El aparato no expone el servicio de BIO-G'),
      );

      final identityChr = _findCharacteristic(
        service,
        BioGBleConfig.identityCharacteristicUuid,
      );
      final telemetryChr = _findCharacteristic(
        service,
        BioGBleConfig.telemetryCharacteristicUuid,
      );
      if (identityChr == null || telemetryChr == null) {
        throw StateError('Faltan caracteristicas de BIO-G en el servicio');
      }

      // ── 3) Identidad ──────────────────────────────────────────────────────
      final identityBytes = await identityChr.read();
      final identity = BioGBleCodec.decodeIdentity(identityBytes);

      // ── 4) Validar antes de abrir el grifo ────────────────────────────────
      //
      // Si el aparato no declara un deviceId usable, no se suscribe Notify.
      // Recibir telemetria que no se puede atribuir a nadie no solo es
      // inutil: es como se acaba con lecturas huerfanas en la nube.
      if (identity == null) {
        throw StateError(
          'El aparato no declaro un deviceId valido en Identidad',
        );
      }
      _identity = identity;

      // ── 5) Y hasta ahora, Notify ──────────────────────────────────────────
      //
      // Las notificaciones NO se fragmentan: cada una cabe en
      // (MTU - 3) bytes y lo que sobre se pierde en silencio. Por eso el MTU
      // se negocio en el paso 1 y por eso, si quedo corto, se avisa en vez de
      // dejar que lleguen JSON cortados que el codec descartara sin explicar.
      _telemetryChr = telemetryChr;
      _notifySub = telemetryChr.onValueReceived.listen(_onTelemetryBytes);
      await telemetryChr.setNotifyValue(true);

      // La conexion se deja ABIERTA a proposito al volver de la pantalla: es
      // lo que hace que las notificaciones empiecen a entrar en la ingesta de
      // inmediato. Se cierra con `disconnect()` o al destruir el store.
      _setState(TelemetryLinkState.connected);
      return true;
    } catch (_) {
      await _teardownConnection();
      _setState(TelemetryLinkState.disconnected);
      return false;
    }
  }

  /// Negocia el MTU y devuelve **el valor realmente acordado**.
  ///
  /// `requestMtu` solo existe en Android; en las demas plataformas el sistema
  /// lo negocia solo y aqui unicamente se consulta. En ambos casos el numero
  /// que sale de esta funcion es el efectivo, nunca el pedido.
  Future<int> _negotiateMtu(BluetoothDevice target) async {
    mtuWarning = null;

    int mtu;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        mtu = await target.requestMtu(BioGBleConfig.desiredMtu);
      } catch (_) {
        // El periferico puede rechazar la peticion o ya haber fijado su MTU.
        // No es motivo para abortar la conexion: se sigue con el que haya.
        mtu = target.mtuNow;
      }
    } else {
      mtu = target.mtuNow;
    }

    // `requestMtu` devuelve lo que reporto el evento; `mtuNow` es lo que la
    // capa nativa tiene cacheado. Si difieren, mandan los bytes: se toma el
    // menor, porque pasarse es lo que corta notificaciones.
    final cached = target.mtuNow;
    if (cached > 0 && cached < mtu) mtu = cached;

    if (mtu - 3 < BioGBleConfig.minUsableNotificationBytes) {
      mtuWarning =
          'El enlace quedo en MTU $mtu (${mtu - 3} bytes utiles por '
          'notificacion). El sobre de telemetria puede no caber y llegar '
          'cortado. Revisa que el firmware acepte la peticion de MTU.';
    }
    return mtu;
  }

  BluetoothCharacteristic? _findCharacteristic(
    BluetoothService service,
    Guid uuid,
  ) {
    for (final c in service.characteristics) {
      if (c.uuid == uuid) return c;
    }
    return null;
  }

  void _onTelemetryBytes(List<int> bytes) {
    final identity = _identity;
    if (identity == null || _envelopes.isClosed) return;

    final envelope = BioGBleCodec.decodeTelemetry(
      bytes,
      identity: identity,
      receivedAt: DateTime.now(),
      signalRssi: _lastRssi,
    );
    if (envelope == null) return;
    _envelopes.add(envelope);
  }

  @override
  Future<void> disconnect() async {
    await _teardownConnection();
    _setState(TelemetryLinkState.disconnected);
  }

  Future<void> _teardownConnection() async {
    await _notifySub?.cancel();
    _notifySub = null;
    final BluetoothCharacteristic? telemetryChr = _telemetryChr;
    _telemetryChr = null;
    if (telemetryChr != null) {
      try {
        await telemetryChr.setNotifyValue(false);
      } catch (_) {
        // Puede haberse desconectado antes de desactivar Notify.
      }
    }
    await _connSub?.cancel();
    _connSub = null;
    _identity = null;

    final d = _device;
    _device = null;
    if (d != null) {
      try {
        await d.disconnect();
      } catch (_) {}
    }
  }

  // ── Backlog ────────────────────────────────────────────────────────────────

  /// Todavia no hay comando de backlog en el firmware.
  ///
  /// Devuelve 0 y lo dice, en vez de fingir que reclamo algo. Cuando el ESP32
  /// exponga una caracteristica de escritura para pedir su memoria pendiente,
  /// se implementa aqui y el resto del sistema no cambia.
  @override
  Future<int> requestBacklog() async => 0;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _teardownConnection();
    await _envelopes.close();
    await _states.close();
  }

  void _setState(TelemetryLinkState next) {
    if (_state == next) return;
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }
}
