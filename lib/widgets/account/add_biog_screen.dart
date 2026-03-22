import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/account/bluetooth_scan_screen.dart';
import 'package:bio_g/widgets/account/qr_scan_screen.dart';
import 'package:bio_g/widgets/shared/bio_g_page_route.dart';

class AddBioGScreen extends StatelessWidget {
  const AddBioGScreen({super.key});

  static const Color kBrandTop = Color(0xFF40BB5F);
  static const Color kBrandMid = Color(0xFF3FAF6E);
  static const Color kBrandBase = Color.fromARGB(137, 43, 126, 101);

  Future<void> _confirmAndAdd(
    BuildContext context, {
    required Map<String, dynamic> payload,
  }) async {
    final String name = (payload['name'] ?? 'Bio-G').toString().trim();
    final String incomingId = (payload['id'] ?? 'BIOG-XXX').toString().trim();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Confirmar Bio-G',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            '¿Agregar este dispositivo?\n\n$name\n$incomingId',
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Agregar',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true || !context.mounted) return;

    final store = BioGScope.of(context);

    try {
      final created = await store.addDemoDevice(
        name: name.isEmpty ? 'Bio-G' : name,
        locationName: _defaultLocationNameFromName(name),
        seedId: null,
        profileId: null,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bio-G agregado: ${created.name}')),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo agregar el Bio-G')),
      );
    }
  }

  String _defaultLocationNameFromName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'Parcela nueva';
    return 'Ubicación de $clean';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _SoftBackground(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                        'Agregar Bio-G',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0E1A16),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 72),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Selecciona una opción para agregar un Bio-G.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Código QR',
                    child: _ActionTile(
                      icon: Icons.qr_code_2_rounded,
                      label: 'Escanear código QR',
                      onTap: () async {
                        final res = await Navigator.of(context)
                            .push<Map<String, dynamic>>(
                              BioGPageRoute(
                                builder: (_) => const QrScanScreen(),
                              ),
                            );

                        if (res == null) return;
                        await _confirmAndAdd(context, payload: res);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Buscar por Bluetooth',
                    child: _ActionTile(
                      icon: Icons.bluetooth_rounded,
                      iconBg: kBrandMid.withValues(alpha: 0.18),
                      iconFg: kBrandMid.withValues(alpha: 0.95),
                      label: 'Encontrar dispositivos cercanos',
                      onTap: () async {
                        final res = await Navigator.of(context)
                            .push<Map<String, dynamic>>(
                              BioGPageRoute(
                                builder: (_) => const BluetoothScanScreen(),
                              ),
                            );

                        if (res == null) return;
                        await _confirmAndAdd(context, payload: res);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconBg;
  final Color? iconFg;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconBg,
    this.iconFg,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.992 : 1.0;
    final overlayOpacity = _pressed ? 0.04 : 0.0;

    final bg = widget.iconBg ?? Colors.black.withValues(alpha: 0.06);
    final fg = widget.iconFg ?? Colors.black.withValues(alpha: 0.75);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.white.withValues(alpha: 0.70),
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: _setPressed,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Stack(
              children: [
                AnimatedOpacity(
                  opacity: overlayOpacity,
                  duration: const Duration(milliseconds: 120),
                  child: Container(color: Colors.black),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Icon(widget.icon, color: fg, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0E1A16),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 18),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1,
              ),
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
          color: _brandMid.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
