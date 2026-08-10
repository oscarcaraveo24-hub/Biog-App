import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  final Duration checkInterval;
  final bool enabled;

  /// Se dispara UNA vez en cada transición sin señal → con señal.
  ///
  /// Este widget ya era el único punto de la app que se entera de que volvió
  /// la conectividad, pero sólo lo usaba para ocultar su propio banner. Sin
  /// este aviso, una operación de la bandeja de sincronización que falló se
  /// queda esperando a que alguien vuelva a encolar algo o a que se reinicie
  /// la sesión: el backoff largo no tiene quién lo despierte justo cuando por
  /// fin hay red.
  ///
  /// Opcional y sin ningún efecto visual: si nadie lo pasa, el banner se
  /// comporta exactamente igual que antes.
  final VoidCallback? onBackOnline;

  const ConnectivityBanner({
    super.key,
    required this.child,
    this.checkInterval = const Duration(seconds: 15),
    this.enabled = true,
    this.onBackOnline,
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  static const List<String> _connectivityHosts = <String>[
    'api.open-meteo.com',
    'google.com',
  ];

  bool _offline = false;
  bool _checking = false;

  /// La pestaña se desactivó mientras no había señal.
  ///
  /// Sirve para que la recuperación se detecte aunque haya ocurrido con el
  /// banner apagado. Ver la nota en [_syncChecks].
  bool _wasOfflineWhenDisabled = false;

  /// El próximo sondeo con red cuenta como recuperación aunque el estado
  /// visible ya diga "en línea". Evita tener que falsear `_offline`, que
  /// pintaría el aviso de sin-señal sin motivo.
  bool _pendingRecoveryProbe = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncChecks();
  }

  @override
  void didUpdateWidget(covariant ConnectivityBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.checkInterval != widget.checkInterval) {
      _syncChecks();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncChecks() {
    _timer?.cancel();
    _timer = null;

    if (!widget.enabled) {
      if (_offline && mounted) {
        // Se recuerda que la pestaña se apagó estando sin señal.
        //
        // El banner se oculta al perder el foco y `_offline` volvía a false,
        // así que al regresar con la red ya recuperada no había transición que
        // detectar y `onBackOnline` no llegaba a dispararse nunca: lo pendiente
        // se quedaba en la cola. El agricultor edita el cultivo en Semillas o
        // en Cuenta, que es justo donde no hay banner.
        _wasOfflineWhenDisabled = true;
        setState(() => _offline = false);
      }
      return;
    }

    // Al reactivarse tras haber estado sin señal, el primer sondeo se trata
    // como una posible recuperación. NO se toca `_offline`: falsearlo pintaría
    // el aviso de "sin conexión" al volver a la pestaña aunque la señal fuera
    // perfecta, y se quedaría ahí hasta que resolviera el sondeo.
    if (_wasOfflineWhenDisabled) {
      _wasOfflineWhenDisabled = false;
      _pendingRecoveryProbe = true;
    }

    unawaited(_check());
    _timer = Timer.periodic(
      widget.checkInterval,
      (_) => unawaited(_check()),
    );
  }

  Future<void> _check() async {
    if (!widget.enabled || _checking) return;
    _checking = true;
    bool hasConnection = false;

    try {
      for (final host in _connectivityHosts) {
        try {
          final result = await InternetAddress.lookup(
            host,
          ).timeout(const Duration(seconds: 4));

          hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
          if (hasConnection) break;
        } catch (_) {
          // Try the next host before showing the advisory banner.
        }
      }
    } finally {
      _checking = false;
    }

    if (!mounted || !widget.enabled) return;

    // Se anota ANTES de mover el estado: es la transición lo que interesa, no
    // el estado final. Así el aviso sale una sola vez por recuperación y no en
    // cada sondeo con red.
    //
    // `_pendingRecoveryProbe` cubre la recuperación que ocurrió con esta
    // pestaña apagada: entonces no hay transición visible que detectar, pero
    // la cola de pendientes sí necesita el empujón.
    final bool recoveredConnection =
        (_offline || _pendingRecoveryProbe) && hasConnection;
    _pendingRecoveryProbe = false;

    if (_offline != !hasConnection) {
      setState(() => _offline = !hasConnection);
    }
    if (recoveredConnection) widget.onBackOnline?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        IgnorePointer(
          ignoring: !_offline,
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedSlide(
              offset: _offline ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _offline ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Material(
                  color: const Color(0xFFB2554E),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Conectividad limitada. Algunos datos pueden tardar.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => unawaited(_check()),
                            child: const Text(
                              'Reintentar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BioGErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const BioGErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.black.withValues(alpha: 0.18)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3FAF6E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
