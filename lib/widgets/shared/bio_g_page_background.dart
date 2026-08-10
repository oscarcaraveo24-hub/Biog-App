// lib/widgets/shared/bio_g_page_background.dart
//
// El fondo de BIO-G. Uno solo, para las cinco pestañas.
//
// ─────────────────────────────────────────────────────────────────────────────
// POR QUÉ EXISTE ESTE ARCHIVO
// ─────────────────────────────────────────────────────────────────────────────
//
// Hasta ahora cada pestaña traía su propio fondo: el Panel tenía cielo con
// parallax, Historial un gris plano (`0xFFF4F7F6`), Cuenta y Entorno cada una
// su degradado, y Cultivo un blanco translúcido. Cinco fondos distintos para
// una sola app.
//
// Ahora hay uno. Cada pantalla lo instancia igual y le dice si está visible.
//
// ─────────────────────────────────────────────────────────────────────────────
// ORDEN DE CAPAS (el z-index importa y es el motivo de que esté todo aquí)
// ─────────────────────────────────────────────────────────────────────────────
//
//   1. Cielo con parallax lento          ← el fondo de verdad
//   2. Velo blanco degradado             ← da legibilidad al texto de abajo
//   3. Partículas flotantes con glow     ← DELANTE del velo
//   ────────────────────────────────────────────────────────────────────────
//   4. (fuera de este widget) el contenido de la pantalla: cards, listas…
//
// Las partículas van DENTRO del fondo y como última capa suya. Eso las deja
// exactamente donde deben: **delante del cielo y del velo, detrás de las
// cards.** Como este widget siempre es el primer hijo del `Stack` de cada
// pantalla, el contenido queda encima sin que nadie tenga que pensar en ello.
//
// Si algún día alguien mete las partículas por fuera, se le pondrán encima de
// las tarjetas. Por eso viven aquí y no en un widget suelto.
//
// ─────────────────────────────────────────────────────────────────────────────
// RENDIMIENTO — leer antes de tocar
// ─────────────────────────────────────────────────────────────────────────────
//
// `AppShell` usa un `IndexedStack`, así que **las cinco pantallas están vivas
// al mismo tiempo**. Si las cinco animaran su fondo serían cinco tickers y
// cinco repintados por frame en un teléfono de gama media, al sol, en el
// campo. Por eso [enabled] no es un detalle: cada pantalla debe pasar si es
// la pestaña activa, y las que no lo son congelan sus controladores.
//
// Además:
//   · `RepaintBoundary` aísla el repintado del fondo del resto del árbol.
//   · El glow se dibuja con tres círculos concéntricos, no con
//     `MaskFilter.blur`. Se ve igual de suave y cuesta una fracción: el blur
//     obliga a Skia a hacer una pasada extra por partícula y por frame.
//   · Se respeta `MediaQuery.disableAnimations`: con movimiento reducido todo
//     se congela en una pose fija, no se apaga. La pantalla sigue viéndose
//     igual, simplemente no se mueve.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fondo compartido de las pantallas principales.
class BioGPageBackground extends StatefulWidget {
  const BioGPageBackground({
    super.key,
    this.enabled = true,
    this.veil = 1.0,
    this.showParticles = true,
    this.particleDensity = 1.0,
    this.particleIntensity = 1.0,
  });

  /// True solo cuando la pantalla es la pestaña visible.
  ///
  /// Con `false` los controladores se detienen y el fondo queda estático. No
  /// desaparece: sigue pintado, simplemente deja de consumir frames.
  final bool enabled;

  /// Multiplicador del velo blanco. 1.0 es el valor calibrado.
  ///
  /// Más bajo = se ve más cielo y hay más contraste; más alto = más lechoso.
  /// El valor anterior del Panel equivalía a ~1.25 aquí, y era justo lo que
  /// apagaba la imagen.
  final double veil;

  final bool showParticles;

  /// Multiplicador de la cantidad de partículas. Útil para pantallas muy
  /// cargadas de contenido, donde conviene bajar el ruido visual.
  final double particleDensity;

  /// Multiplicador de la opacidad de las partículas. 1.0 es el valor
  /// calibrado para que se vean sin competir con el contenido. Súbelo si las
  /// quieres más presentes; bájalo en pantallas muy llenas.
  final double particleIntensity;

  @override
  State<BioGPageBackground> createState() => _BioGPageBackgroundState();
}

class _BioGPageBackgroundState extends State<BioGPageBackground>
    with TickerProviderStateMixin {
  /// Parallax del cielo. Mismo periodo que tenía el Panel: no se toca para
  /// que el movimiento se sienta idéntico al que ya conocías.
  late final AnimationController _sky;

  /// Deriva de las partículas. Periodo largo y distinto del cielo a propósito:
  /// si coincidieran, el ojo detectaría el bucle.
  late final AnimationController _motes;

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _sky = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
    _motes = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 46),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _sync();
  }

  @override
  void didUpdateWidget(covariant BioGPageBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _sync();
  }

  void _sync() {
    if (_reduceMotion) {
      // Pose fija, elegida porque deja el cielo centrado y las partículas
      // repartidas. No es 0: en 0 varias partículas coinciden en el borde.
      _sky
        ..stop()
        ..value = 0.25;
      _motes
        ..stop()
        ..value = 0.32;
      return;
    }

    if (widget.enabled) {
      if (!_sky.isAnimating) _sky.repeat();
      if (!_motes.isAnimating) _motes.repeat();
    } else {
      _sky.stop();
      _motes.stop();
    }
  }

  @override
  void dispose() {
    _sky.dispose();
    _motes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: Stack(
            children: <Widget>[
              // ── Capa 1 · Cielo ──────────────────────────────────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _sky,
                  child: Image.asset(
                    'assets/images/bg_sky.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                  builder: (BuildContext context, Widget? child) {
                    final double progress =
                        (1 - math.cos(_sky.value * math.pi * 2)) / 2;
                    // El overscan evita revelar bordes durante el parallax.
                    final double scale = 1.034 + (progress * 0.020);
                    final Offset offset = Offset(
                      -5 + (progress * 10),
                      5 - (progress * 10),
                    );
                    return Transform.translate(
                      offset: offset,
                      child: Transform.scale(scale: scale, child: child),
                    );
                  },
                ),
              ),

              // ── Capa 2 · Velo blanco ────────────────────────────────────
              // Baja el contraste del cielo lo justo para que el texto oscuro
              // se lea encima. Calibrado más suave que el original: antes el
              // pie llegaba al 80 % de blanco y aplanaba la imagen entera.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const <double>[0.0, 0.42, 1.0],
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(
                          alpha: (0.22 * widget.veil).clamp(0.0, 1.0),
                        ),
                        Colors.white.withValues(
                          alpha: (0.66 * widget.veil).clamp(0.0, 1.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Capa 3 · Partículas ─────────────────────────────────────
              // Última capa del fondo = delante del velo, detrás del contenido.
              if (widget.showParticles)
                Positioned.fill(
                  // Punto de anclaje para las pruebas. La clave existía en el
                  // fondo propio del Panel y se perdió al unificar los fondos;
                  // desde entonces la prueba que comprueba que las partículas
                  // se pausan no encontraba nada que mirar. Una `Key` no pinta
                  // nada: no hay cambio visual.
                  key: const ValueKey<String>('dashboard-nature-particles'),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _BioGMotesPainter(
                        animation: _motes,
                        density: widget.particleDensity,
                        intensity: widget.particleIntensity,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una mota flotando.
///
/// Los valores se derivan del índice con una función determinista, no con
/// `Random()`: así el campo se ve orgánico pero es idéntico en cada build, en
/// cada hot reload y en cada dispositivo. Un `Random()` dentro del painter
/// haría que las partículas saltaran de sitio en cada repintado.
class _Mote {
  const _Mote({
    required this.x,
    required this.y0,
    required this.radius,
    required this.speed,
    required this.swayAmplitude,
    required this.swayPhase,
    required this.swayFrequency,
    required this.color,
    required this.opacity,
    required this.isBokeh,
  });

  final double x;
  final double y0;
  final double radius;
  final double speed;
  final double swayAmplitude;
  final double swayPhase;
  final double swayFrequency;
  final Color color;
  final double opacity;

  /// Las bokeh son grandes y muy tenues: dan la sensación de profundidad de
  /// campo, como si estuvieran fuera de foco delante del objetivo.
  final bool isBokeh;
}

/// El campo de partículas.
///
/// ─────────────────────────────────────────────────────────────────────────
/// POR QUÉ LA PRIMERA VERSIÓN NO SE VEÍA
/// ─────────────────────────────────────────────────────────────────────────
///
/// Dos errores, y el segundo era el grave:
///
/// 1. **Tamaño.** Los núcleos medían de 0.9 a 3.5 px. Las del login miden de
///    2 a 6, más cuatro bokeh de 8 a 14. A 2 px no hay opacidad que valga.
///
/// 2. **Color.** La paleta era mayoritariamente blanca... sobre un velo
///    blanco. Blanco sobre blanco no se ve. Las del login funcionan porque
///    son verdes sobre una fotografía oscura; aquí el fondo es un cielo claro
///    con velo, así que la paleta tiene que ser de tonos que contrasten
///    contra el blanco: verde de marca, verde profundo, dorado y turquesa.
///    El blanco queda solo como chispa diminuta dentro de las más grandes.
///
/// Un tercer factor menor: la opacidad se multiplicaba por `sin(pi·recorrido)`,
/// así que cada mota pasaba la mayor parte de su ciclo casi transparente.
/// Ahora la opacidad es constante y solo se atenúa en los bordes del lienzo,
/// que es lo que hace `FloatingParticles` en el login.
class _BioGMotesPainter extends CustomPainter {
  _BioGMotesPainter({
    required this.animation,
    this.density = 1.0,
    this.intensity = 1.0,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final double density;
  final double intensity;

  /// Tonos que contrastan contra el velo blanco. El verde de marca es el
  /// mismo `0xFF40BB5F` que usa `FloatingParticles` en el login, para que las
  /// dos pantallas se sientan del mismo producto.
  static const List<Color> _palette = <Color>[
    Color(0xFF40BB5F), // verde de marca
    Color(0xFF2E9E52), // verde profundo
    Color(0xFFE0A94A), // dorado de tarde
    Color(0xFF3FA9A0), // turquesa
    Color(0xFF7CC96B), // verde hoja claro
  ];

  static const int _maxMotes = 32;
  static const int _bokehCount = 5;

  static final List<_Mote> _field = _buildField();

  static List<_Mote> _buildField() {
    final List<_Mote> motes = <_Mote>[];
    for (int i = 0; i < _maxMotes; i++) {
      // Semillas irracionales: reparten sin caer en patrones visibles.
      final double h1 = _frac(i * 0.6180339887 + 0.13);
      final double h2 = _frac(i * 0.7548776662 + 0.37);
      final double h3 = _frac(i * 0.3819660113 + 0.71);
      final double h4 = _frac(i * 0.2360679775 + 0.29);

      final bool isBokeh = i < _bokehCount;

      motes.add(
        _Mote(
          x: h1,
          y0: h2,
          // Mismos rangos que el login, que es la referencia que funciona.
          radius: isBokeh ? 9.0 + h3 * 6.0 : 2.2 + h3 * 3.8,
          // Las bokeh, al ser enormes, van muy por debajo en opacidad.
          opacity: isBokeh ? 0.05 + h4 * 0.05 : 0.17 + h4 * 0.17,
          speed: 0.35 + h2 * 0.55,
          swayAmplitude: 0.012 + h1 * 0.030,
          swayPhase: h3 * 2 * math.pi,
          swayFrequency: 0.8 + h4 * 1.4,
          color: _palette[i % _palette.length],
          isBokeh: isBokeh,
        ),
      );
    }
    return List<_Mote>.unmodifiable(motes);
  }

  static double _frac(double v) => v - v.floorToDouble();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double t = animation.value;
    final int count = (_maxMotes * density).round().clamp(0, _maxMotes);

    for (int i = 0; i < count; i++) {
      final _Mote m = _field[i];

      // Deriva hacia arriba con envolvente: al salir por arriba reaparece por
      // abajo. El modulo doble garantiza positivo aunque el resultado sea
      // negativo, que es donde fallan estas cuentas.
      final double rawY = m.y0 - (t * m.speed);
      final double y01 = ((rawY % 1.0) + 1.0) % 1.0;

      final double sway =
          math.sin((t * 2 * math.pi * m.swayFrequency) + m.swayPhase) *
          m.swayAmplitude;

      final double dx = size.width * (m.x + sway);
      final double dy = size.height * y01;

      // Atenuacion solo en los bordes, para que no aparezcan ni desaparezcan
      // de golpe. En el 84 % central del lienzo la opacidad es plena, que es
      // exactamente lo que hace que se vean.
      double edge = 1.0;
      const double band = 0.08;
      if (y01 < band) {
        edge = y01 / band;
      } else if (y01 > 1 - band) {
        edge = (1 - y01) / band;
      }

      final double alpha = (m.opacity * edge * intensity).clamp(0.0, 1.0);
      if (alpha <= 0.004) continue;

      final double r = m.radius;

      canvas.save();
      canvas.translate(dx, dy);

      final Paint p = Paint()..isAntiAlias = true;

      if (m.isBokeh) {
        // Bokeh: un disco suave con un anillo apenas insinuado, como un
        // circulo de confusion real.
        p.color = m.color.withValues(alpha: alpha * 0.55);
        canvas.drawCircle(Offset.zero, r, p);
        p
          ..color = m.color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.18;
        canvas.drawCircle(Offset.zero, r * 0.92, p);
        p.style = PaintingStyle.fill;
      } else {
        // Glow en tres circulos concentricos. Tres `drawCircle` son ordenes
        // de magnitud mas baratos que un `MaskFilter.blur`, y a este tamano
        // el ojo no distingue la diferencia. Importa: esto corre en un
        // Android de gama media, al sol, en el campo.
        p.color = m.color.withValues(alpha: alpha * 0.16);
        canvas.drawCircle(Offset.zero, r * 3.4, p);

        p.color = m.color.withValues(alpha: alpha * 0.38);
        canvas.drawCircle(Offset.zero, r * 1.9, p);

        p.color = m.color.withValues(alpha: alpha);
        canvas.drawCircle(Offset.zero, r, p);

        // Chispa blanca en las mas grandes: da sensacion de luz propia.
        if (r > 4.6) {
          p.color = Colors.white.withValues(alpha: (alpha * 0.7).clamp(0, 1));
          canvas.drawCircle(Offset.zero, r * 0.38, p);
        }
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BioGMotesPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.density != density ||
        oldDelegate.intensity != intensity;
  }
}
