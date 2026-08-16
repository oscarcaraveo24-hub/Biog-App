import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/cultivation_scale.dart';
import 'package:bio_g/core/hardware/biog_serial.dart';

class QrScanScreen extends StatelessWidget {
  const QrScanScreen({super.key});

  /// Contenido simulado de la etiqueta, con el formato real —el mismo que va a
  /// imprimirse—. El stub emite lo que emitirá el escáner de verdad para que el
  /// resto de la cadena ya esté ejercitada cuando llegue la cámara: hasta hoy
  /// devolvía `BIOG-QR-001`, que ni es un UUID válido ni lleva modelo dentro,
  /// así que el repositorio lo descartaba y el equipo nacía sin identidad.
  static String get simulatedQrContent {
    // Campo, no maceta. Un stub que fija el modelo decide el MEDIO DE CULTIVO
    // de quien lo escanea: con `maceta` aquí, cualquier alta de parcela abierta
    // terminaba con perfil de sustrato y su textura mineral declarada quedaba
    // guardada pero ignorada. Cuando esta pantalla lea la cámara de verdad, el
    // modelo saldrá de la etiqueta y esta constante desaparece.
    final serial = BioGSerial.build(
      model: BioGDeviceModel.campo,
      year: 2026,
      isoWeek: 32,
      sequenceNumber: 1,
    );
    return BioGQrPayload.encodeUrl(
      serial: serial,
      telemetryDeviceId: '9f1c2d3e-4a5b-4c6d-8e7f-0a1b2c3d4e5f',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla stub: simula un “QR leído”
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
                              color: Colors.black.withValues(alpha:0.55),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Escanear QR',
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
                    'Stub: aquí irá la cámara y lector QR.\nPor ahora puedes simular un QR leído.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha:0.55),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha:0.05),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.black.withValues(alpha:0.06),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              size: 82,
                              color: Colors.black.withValues(alpha:0.25),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _PrimaryButton(
                          label: 'Simular QR leído',
                          onTap: () {
                            // El payload se interpreta con el mismo parser que
                            // usará la cámara. Así el modelo, la serie y el
                            // UUID de telemetría viajan enteros hasta el
                            // almacén, en vez de perderse en el camino.
                            final payload = BioGQrPayload.parse(
                              simulatedQrContent,
                            );
                            Navigator.pop(
                              context,
                              payload.toScanResult(source: 'qr'),
                            );
                          },
                        ),
                      ],
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

/* ---------- button ---------- */

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  static const Color kBrandTop = Color(0xFF40BB5F);
  static const Color kBrandMid = Color(0xFF3FAF6E);
  static const Color kBrandBase = Color.fromARGB(137, 43, 126, 101);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kBrandTop.withValues(alpha:0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Ink(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kBrandTop, kBrandMid, kBrandBase],
              ),
            ),
            // ❗️ANTES era const y hardcodeaba el texto.
            // ✅ Ahora respeta `label` sin cambiar UI.
            child: SizedBox(
              height: 46,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
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
