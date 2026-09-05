import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/cultivation_scale.dart';
import 'package:bio_g/core/hardware/biog_serial.dart';
import 'package:bio_g/core/telemetry/telemetry_transport.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/services/biog/telemetry/ble/ble_telemetry_transport.dart';

/// Escaneo BLE real contra el hardware BIO-G.
///
/// La pantalla NO habla con flutter_blue_plus. Usa el `BleTelemetryTransport`
/// que vive en `BioGStore`, que es el mismo que alimenta la ingesta de
/// telemetria. Toda la logica de radio esta en la capa de transporte; aqui
/// solo se pinta lo que esa capa reporta.
///
/// El contrato de salida no cambio: sigue devolviendo el mismo
/// `Map<String, dynamic>` con `id`, `name`, `model`, `serial` y `source` que
/// ya consumian `add_biog_screen` y el wizard de onboarding.
///
/// Lo que SI cambio, y es el punto de todo esto: cuando el dispositivo es
/// real, `id` es el `deviceId` que el aparato declara en su caracteristica de
/// Identidad. **La MAC del BLE no se convierte nunca en deviceId**: viaja
/// aparte, como `transportAddress`, que es lo unico que es.
class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  /// Lista simulada, que se conserva como respaldo.
  ///
  /// Aparece cuando la radio no esta disponible (sin permisos, Bluetooth
  /// apagado, telefono sin BLE, o emulador) para que el flujo de alta se pueda
  /// seguir probando sin hardware. No se muestra junto a los equipos reales:
  /// mezclar aparatos de verdad con inventados en la misma lista es como se
  /// acaba dando de alta un fake por accidente.
  final List<Map<String, String>> _devices = <Map<String, String>>[
    <String, String>{
      'id': '1c9a7f30-51b2-4a8e-9b64-2d0f7a51c001',
      'name': 'Bio-G Campo #001',
      'model': 'campo',
      'serial': 'BIOG-C-2632-000001-?',
    },
    <String, String>{
      'id': '1c9a7f30-51b2-4a8e-9b64-2d0f7a51c002',
      'name': 'Bio-G Huerto #002',
      'model': 'huerto',
      'serial': 'BIOG-H-2632-000002-?',
    },
    <String, String>{
      'id': '1c9a7f30-51b2-4a8e-9b64-2d0f7a51c003',
      'name': 'Bio-G Maceta #003',
      'model': 'maceta',
      'serial': 'BIOG-M-2632-000003-?',
    },
  ];

  BleTelemetryTransport? _transport;

  List<DiscoveredDevice> _found = const <DiscoveredDevice>[];
  BleUnavailableReason _reason = BleUnavailableReason.none;
  bool _scanning = false;
  bool _showFakes = false;
  String? _connectingAddress;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_transport != null) return;
    _transport = BioGScope.of(context).bleTransport;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  // ── Escaneo ────────────────────────────────────────────────────────────────

  Future<void> _startScan() async {
    final transport = _transport;
    if (transport == null || _scanning) return;

    setState(() {
      _scanning = true;
      _error = null;
      _showFakes = false;
    });

    final reason = await transport.checkAvailability();
    if (!mounted) return;

    if (reason != BleUnavailableReason.none) {
      setState(() {
        _reason = reason;
        _scanning = false;
        _found = const <DiscoveredDevice>[];
        _showFakes = true;
      });
      return;
    }

    final found = await transport.scan();
    if (!mounted) return;

    setState(() {
      _reason = BleUnavailableReason.none;
      _found = found;
      _scanning = false;
      // Si la radio fallo, se dice por que en vez de fingir que no habia nadie.
      _error = found.isEmpty ? transport.lastScanError : null;
      // Solo se ofrece el respaldo simulado si no aparecio nada real.
      _showFakes = found.isEmpty;
    });
  }

  Future<void> _turnBluetoothOn() async {
    final transport = _transport;
    if (transport == null) return;
    await transport.requestAdapterOn();
    if (!mounted) return;
    await _startScan();
  }

  // ── Seleccion ──────────────────────────────────────────────────────────────

  /// Conecta de verdad, lee Identidad y devuelve el deviceId del aparato.
  Future<void> _selectReal(DiscoveredDevice d) async {
    final transport = _transport;
    if (transport == null || _connectingAddress != null) return;

    setState(() {
      _connectingAddress = d.transportAddress;
      _error = null;
    });

    final ok = await transport.connect(d);
    if (!mounted) return;

    final identity = transport.connectedIdentity;
    if (!ok || identity == null) {
      setState(() {
        _connectingAddress = null;
        _error =
            'Conecte pero el aparato no declaro una identidad valida. '
            'Revisa que el firmware exponga la caracteristica de Identidad '
            'con un deviceId en formato UUID.';
      });
      return;
    }

    setState(() => _connectingAddress = null);

    // El MTU acordado y su aviso van a la consola: hoy estas viendo un
    // `flutter run` con el aparato en la mano, y ahi es donde sirve. Si el
    // enlace quedo corto, el sobre de telemetria puede llegar cortado y el
    // codec lo descartaria sin decir por que.
    final int? mtu = transport.negotiatedMtu;
    final String? mtuWarning = transport.mtuWarning;
    debugPrint(
      '[BIO-G/BLE] conectado a ${d.displayName} (${d.transportAddress}) · '
      'deviceId=${identity.deviceId} · MTU=$mtu '
      '(${transport.notificationPayloadBytes} bytes utiles por notificacion)',
    );
    if (mtuWarning != null) debugPrint('[BIO-G/BLE] AVISO: $mtuWarning');

    Navigator.pop<Map<String, dynamic>>(context, <String, dynamic>{
      // El deviceId lo declara el APARATO. La MAC va aparte, abajo.
      'id': identity.deviceId,
      'name': d.displayName,
      'model': identity.deviceModelId,
      'serial': identity.hardwareSerial,
      'source': 'bluetooth',
      // Extras: los consumidores leen por clave, asi que anadirlos es seguro
      // y sirven para diagnostico del emparejamiento.
      'transportAddress': d.transportAddress,
      'firmwareVersion': identity.firmwareVersion,
      'negotiatedMtu': mtu,
      'mtuWarning': mtuWarning,
    });
  }

  /// Serie bien formada (con su digito de control) para cada modelo simulado.
  String? _serialFor(String? modelId, int index) {
    final model = deviceModelFromId(modelId);
    if (model == null) return null;
    return BioGSerial.build(
      model: model,
      year: 2026,
      isoWeek: 32,
      sequenceNumber: index + 1,
    ).raw;
  }

  void _selectDevice(Map<String, String> d) {
    final index = _devices.indexOf(d);
    Navigator.pop<Map<String, dynamic>>(context, <String, dynamic>{
      'id': d['id'] ?? 'BIOG-BLE-XXX',
      'name': d['name'] ?? 'Bio-G',
      // El modelo viaja: es lo que decide el medio de cultivo y lo que hasta
      // hoy se perdia entre esta pantalla y `addDevice`.
      'model': d['model'],
      'serial': _serialFor(d['model'], index < 0 ? 0 : index),
      'source': 'bluetooth',
    });
  }

  // ── Texto de estado ────────────────────────────────────────────────────────

  String get _statusText {
    if (_connectingAddress != null) {
      return 'Conectando y leyendo identidad del aparato...';
    }
    if (_scanning) return 'Buscando equipos BIO-G cerca...';
    if (_error != null) return _error!;
    switch (_reason) {
      case BleUnavailableReason.unsupported:
        return 'Este telefono no tiene Bluetooth de baja energia.\n'
            'Puedes continuar con un equipo simulado.';
      case BleUnavailableReason.unauthorized:
        return 'Falta el permiso de Bluetooth.\n'
            'Concedelo en Ajustes > Aplicaciones > BIO-G > Permisos y vuelve a buscar.';
      case BleUnavailableReason.adapterOff:
        return 'El Bluetooth esta apagado.';
      case BleUnavailableReason.none:
        if (_found.isEmpty) {
          return 'No encontre ningun BIO-G cerca.\n'
              'Revisa que el aparato este encendido y anunciando.';
        }
        return 'Selecciona tu equipo para leer su identidad y vincularlo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = _scanning || _connectingAddress != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _SoftBackground(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Bluetooth',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0E1A16),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 72,
                          child: busy
                              ? const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: _startScan,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      'Buscar',
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(
                                          0xFF3FAF6E,
                                        ).withValues(alpha: 0.95),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                    ),
                    if (_reason == BleUnavailableReason.adapterOff) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _turnBluetoothOn,
                        child: Text(
                          'Encender Bluetooth',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF3FAF6E).withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // ── Equipos reales ────────────────────────────────────
                    if (_found.isNotEmpty)
                      _GlassCard(
                        radius: 22,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          children: [
                            for (int i = 0; i < _found.length; i++) ...[
                              _DeviceTile(
                                name: _found[i].displayName,
                                id: _subtitleFor(_found[i]),
                                onTap: () => _selectReal(_found[i]),
                              ),
                              if (i != _found.length - 1) const _DividerLine(),
                            ],
                          ],
                        ),
                      ),

                    // ── Respaldo simulado ─────────────────────────────────
                    if (_showFakes) ...[
                      if (_found.isNotEmpty) const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Equipos simulados (sin hardware)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: Colors.black.withValues(alpha: 0.40),
                          ),
                        ),
                      ),
                      _GlassCard(
                        radius: 22,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          children: [
                            for (int i = 0; i < _devices.length; i++) ...[
                              _DeviceTile(
                                name: _devices[i]['name']!,
                                id: _devices[i]['id']!,
                                onTap: () => _selectDevice(_devices[i]),
                              ),
                              if (i != _devices.length - 1)
                                const _DividerLine(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Subtitulo del renglon: direccion de transporte + potencia.
  ///
  /// Se muestra la MAC a proposito, para que en el taller se sepa a que
  /// aparato fisico corresponde cada renglon. Es informacion de diagnostico,
  /// no identidad: la identidad se lee al conectar.
  String _subtitleFor(DiscoveredDevice d) {
    final rssi = d.rssi;
    if (_connectingAddress == d.transportAddress) {
      return '${d.transportAddress}  ·  conectando...';
    }
    if (rssi == null) return d.transportAddress;
    return '${d.transportAddress}  ·  $rssi dBm';
  }
}

/* ---------- tiles ---------- */

class _DeviceTile extends StatelessWidget {
  final String name;
  final String id;
  final VoidCallback onTap;

  const _DeviceTile({
    required this.name,
    required this.id,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF3FAF6E).withValues(alpha:0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha:0.06)),
              ),
              child: Icon(
                Icons.bluetooth_rounded,
                color: const Color(0xFF3FAF6E).withValues(alpha:0.95),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0E1A16),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    id,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha:0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.black.withValues(alpha:0.25),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Container(
        height: 1,
        width: double.infinity,
        color: Colors.black.withValues(alpha:0.06),
      ),
    );
  }
}

/* ---------- glass + bg ---------- */

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.14),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.62),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha:0.55)),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SoftBackground extends StatelessWidget {
  const _SoftBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6FAF8), Color(0xFFEFF6F2), Color(0xFFF6FAF8)],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -120,
            left: -80,
            child: _GlowBlob(size: 260, opacity: 0.18),
          ),
          Positioned(
            top: 160,
            right: -110,
            child: _GlowBlob(size: 300, opacity: 0.14),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: _GlowBlob(size: 340, opacity: 0.16),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowBlob({required this.size, required this.opacity});

  static const Color _brandMid = Color(0xFF3FAF6E);

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _brandMid.withValues(alpha:opacity),
        ),
      ),
    );
  }
}
