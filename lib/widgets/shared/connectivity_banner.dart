import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  final Duration checkInterval;
  final bool enabled;

  const ConnectivityBanner({
    super.key,
    required this.child,
    this.checkInterval = const Duration(seconds: 15),
    this.enabled = true,
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
        setState(() => _offline = false);
      }
      return;
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
    if (_offline != !hasConnection) {
      setState(() => _offline = !hasConnection);
    }
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
