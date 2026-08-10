// lib/widgets/soil_health_ring.dart
//
// El anillo de estado general del suelo.
//
// ═════════════════════════════════════════════════════════════════════════════
// EL CORTE DE COLOR: LA CAUSA REAL
// ═════════════════════════════════════════════════════════════════════════════
//
// Durante tres intentos se buscó el problema en la paleta —menos anclas, tonos
// más juntos, rampa monótona— y el corte seguía ahí, siempre en el mismo sitio:
// **las tres en punto**. No era el color. Era el shader.
//
// El código usaba, desde su primera versión:
//
//     SweepGradient(startAngle: -pi / 2, endAngle: -pi / 2 + 2 * pi, ...)
//
// Flutter **normaliza el ángulo de cada punto a [0, 2π) antes** de mapearlo
// contra ese rango. Con un `startAngle` negativo eso rompe la continuidad:
//
//     reloj    θ      t = (θ − inicio) / (fin − inicio)
//     12:00   270°    1.000
//      1:30   315°    1.125  → recortado a 1.000
//      2:59   359°    1.247  → recortado a 1.000
//      3:00     0°    0.250  ← SALTO
//
// De las 12 a las 3 el parámetro se sale del rango y `TileMode.clamp` lo
// congela en el color final. Al cruzar las tres el ángulo envuelve a cero y el
// parámetro **cae de golpe a 0.25**. Ahí está el canto duro, y no hay paleta
// que lo arregle: el arco salta de un color al otro en un píxel.
//
// La solución es no usar ángulos negativos. Se rota el lienzo −90° para que el
// eje local +x apunte a las 12, y el degradado se define limpio de 0 a 2π. El
// parámetro recorre 0→1 de forma continua toda la vuelta, y la única junta
// posible —donde el final se encuentra con el principio— queda a las 12 en
// punto, justo debajo del badge, que la tapa.
//
// ═════════════════════════════════════════════════════════════════════════════
// EL BORDE QUE PERDÍA OPACIDAD
// ═════════════════════════════════════════════════════════════════════════════
//
// El aro blanco se pintaba ANTES que el arco, y la capa de fusión del arco
// —un trazo ancho y desenfocado— lo alcanzaba y lo teñía de verde. Por eso el
// borde se veía menos opaco justo en el tramo ya cargado.
//
// Ahora el aro se pinta en dos tiempos: su resplandor va debajo del arco, y el
// trazo sólido va **encima de todo**, donde nada puede lavarlo.
//
// ═════════════════════════════════════════════════════════════════════════════
// GEOMETRÍA
// ═════════════════════════════════════════════════════════════════════════════
//
// Todo se deriva de las constantes de abajo y hay un `assert` que comprueba
// que nada se salga del lienzo. La versión vieja pintaba el aro hasta 147.5 y
// el badge hasta 160.5 dentro de una caja de radio 140: por eso se recortaba.

import 'dart:math';

import 'package:flutter/material.dart';

class SoilHealthRing extends StatefulWidget {
  final double? percent; // 0.0 a 1.0 · null = sin datos
  final String label;
  final VoidCallback? onBadgeTap;

  /// True cuando la pantalla que lo contiene es la visible.
  ///
  /// Existe porque `AppShell` usa un `IndexedStack`: el Panel se construye una
  /// vez y se mantiene vivo, así que `initState` corre **una sola vez en toda
  /// la vida de la app**. Sin esta bandera el arco se llenaba en el primer
  /// arranque y nunca más, ni al volver a la pestaña ni al reabrir la app.
  final bool isActive;

  const SoilHealthRing({
    super.key,
    required this.percent,
    required this.label,
    this.onBadgeTap,
    this.isActive = true,
  });

  @override
  State<SoilHealthRing> createState() => _SoilHealthRingState();
}

class _SoilHealthRingState extends State<SoilHealthRing>
    with SingleTickerProviderStateMixin {
  // ── Geometría ──────────────────────────────────────────────────────────────

  /// Lienzo total. Es también el espacio que ocupa en la pantalla.
  static const double _canvas = 300;
  static const double _center = _canvas / 2; // 150

  static const double _ringStroke = 20;
  static const double _ringRadius = 118; // eje del trazo del arco
  static const double _frameGap = 6;
  static const double _frameStroke = 8; // más grueso que antes (era 6)
  static const double _badgeSize = 58;

  static const double _ringOuterEdge = _ringRadius + (_ringStroke / 2); // 128
  static const double _ringInnerEdge = _ringRadius - (_ringStroke / 2); // 108
  static const double _frameRadius = _ringOuterEdge + _frameGap; // 134
  static const double _frameOuterEdge = _frameRadius + (_frameStroke / 2); // 138
  static const double _badgeOuterEdge = _ringRadius + (_badgeSize / 2); // 147

  /// Borde blanco interior. Canto nítido, metido 1 px bajo el arco para que no
  /// quede una rendija de fondo entre ambos.
  static const double _haloRadius = _ringInnerEdge + 1; // 109
  static const double _grassRadius = _haloRadius - 5; // 104

  late final AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();

    // Si alguien cambia una constante y algo deja de caber, que salte aquí en
    // debug y no en la pantalla de un agricultor.
    assert(
      _badgeOuterEdge <= _center && _frameOuterEdge <= _center,
      'La geometria del anillo se sale del lienzo: badge=$_badgeOuterEdge '
      'marco=$_frameOuterEdge limite=$_center',
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _anim = _tween(0.0, _target);
    _controller.forward();
  }

  double get _target => (widget.percent ?? 0.0).clamp(0.0, 1.0);

  Animation<double> _tween(double begin, double end, {Curve? curve}) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: _controller,
        curve: curve ?? Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SoilHealthRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Volver a la pestaña vuelve a pintar el arco desde cero. Es el gesto que
    // hace que el Panel se sienta vivo cada vez que entras.
    if (widget.isActive && !oldWidget.isActive) {
      _anim = _tween(0.0, _target);
      _controller
        ..reset()
        ..forward();
      return;
    }

    if (oldWidget.percent != widget.percent) {
      _anim = _tween(_anim.value, _target, curve: Curves.easeOutCubic);
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      // Red de seguridad para pantallas angostas: en un teléfono de 320 px el
      // ancho útil queda en ~284 y el lienzo mide 300. `scaleDown` solo actúa
      // cuando hace falta.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: RepaintBoundary(
          child: SizedBox(
            width: _canvas,
            height: _canvas,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double p = _anim.value;

                final Offset badgeCenter = _badgeCenterForPercent(
                  percent: p,
                  center: const Offset(_center, _center),
                  radius: _ringRadius,
                );

                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // 1 · Resplandor ambiental, muy difuso.
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(
                              0xFF4CAF50,
                            ).withValues(alpha: 0.20),
                            blurRadius: 34,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    // 2 · Parte blanda del aro: sombra y resplandor. Va DEBAJO
                    //     del arco a propósito.
                    const CustomPaint(
                      size: Size(_canvas, _canvas),
                      painter: _FramePainter(
                        radius: _frameRadius,
                        stroke: _frameStroke,
                        crisp: false,
                      ),
                    ),

                    // 3 · Canal del arco.
                    const CustomPaint(
                      size: Size(_canvas, _canvas),
                      painter: _BaseRingPainter(
                        radius: _ringRadius,
                        stroke: _ringStroke,
                      ),
                    ),

                    // 4 · El progreso.
                    CustomPaint(
                      size: const Size(_canvas, _canvas),
                      painter: _ActiveRingPainter(
                        percent: p,
                        radius: _ringRadius,
                        stroke: _ringStroke,
                      ),
                    ),

                    // 5 · El aro blanco sólido. ENCIMA del arco: así ninguna
                    //     capa de fusión puede lavarle la opacidad, que era
                    //     justo lo que pasaba en el tramo ya cargado.
                    const CustomPaint(
                      size: Size(_canvas, _canvas),
                      painter: _FramePainter(
                        radius: _frameRadius,
                        stroke: _frameStroke,
                        crisp: true,
                      ),
                    ),

                    // 6 · Borde blanco interior. Canto limpio contra el verde.
                    Container(
                      width: _haloRadius * 2,
                      height: _haloRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.94),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            blurRadius: 16,
                            spreadRadius: -4,
                            color: Colors.black.withValues(alpha: 0.06),
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),

                    // 7 · El globo: pasto disuelto hacia el borde.
                    SizedBox(
                      width: _grassRadius * 2,
                      height: _grassRadius * 2,
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (Rect rect) {
                          return const RadialGradient(
                            colors: <Color>[
                              Colors.white,
                              Colors.white,
                              Colors.transparent,
                            ],
                            // El desvanecido arranca mucho mas afuera que
                            // antes (0.68): la foto se ve casi entera y solo
                            // se disuelve en el ultimo tramo contra el borde.
                            stops: <double>[0.0, 0.86, 1.0],
                          ).createShader(rect);
                        },
                        child: ClipOval(
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              Image.asset(
                                'assets/images/circle_grass.png',
                                fit: BoxFit.cover,
                              ),
                              // Velo minimo. Antes iba al 0.12 y lavaba la
                              // foto; ahora apenas la asienta bajo el texto.
                              Container(
                                color: Colors.white.withValues(alpha: 0.04),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 8 · Cifra y etiqueta.
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // Desplazada 5 px a la derecha: el simbolo % pesa
                          // menos que los digitos, asi que el centro optico de
                          // "53%" cae a la izquierda del geometrico. Esto lo
                          // compensa y la cifra se ve centrada de verdad.
                          Transform.translate(
                            offset: const Offset(5, 0),
                            child: Text(
                            widget.percent == null
                                ? '--'
                                : '${(p * 100).round()}%',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.3,
                              height: 0.94,
                              color: Colors.black.withValues(alpha: 0.86),
                              shadows: <Shadow>[
                                Shadow(
                                  blurRadius: 14,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                                Shadow(
                                  blurRadius: 12,
                                  color: Colors.black.withValues(alpha: 0.08),
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          ),
                          const SizedBox(height: 7),
                          SizedBox(
                            width: _grassRadius * 1.62,
                            child: Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                                color: Colors.black.withValues(alpha: 0.66),
                                height: 1.16,
                                shadows: <Shadow>[
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.white.withValues(alpha: 0.60),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 9 · El badge, siguiendo la cabeza del progreso.
                    Positioned(
                      left: badgeCenter.dx - (_badgeSize / 2),
                      top: badgeCenter.dy - (_badgeSize / 2),
                      child: _RingBadge(
                        size: _badgeSize,
                        onTap: widget.onBadgeTap,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

Offset _badgeCenterForPercent({
  required double percent,
  required Offset center,
  required double radius,
}) {
  final double p = percent.clamp(0.0, 1.0);
  final double angle = (-pi / 2) + (2 * pi * p);
  return Offset(
    center.dx + radius * cos(angle),
    center.dy + radius * sin(angle),
  );
}

/// El aro blanco exterior, en dos tiempos.
///
/// Con `crisp: false` pinta la sombra y el resplandor, que van **debajo** del
/// arco. Con `crisp: true` pinta el trazo sólido, que va **encima de todo**.
///
/// Están separados por una razón concreta: antes el aro se pintaba entero
/// antes que el arco, y la capa de fusión del arco —ancha y desenfocada— lo
/// alcanzaba y lo teñía. El borde se veía translúcido justo en el tramo ya
/// cargado y opaco en el resto.
class _FramePainter extends CustomPainter {
  const _FramePainter({
    required this.radius,
    required this.stroke,
    required this.crisp,
  });

  final double radius;
  final double stroke;
  final bool crisp;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);

    if (crisp) {
      // El aro. Sólido y opaco: es el borde que se veía perder fuerza.
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.96)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..isAntiAlias = true,
      );
      return;
    }

    // Sombra de apoyo: da la sensación de que el aro flota por encima.
    canvas.drawCircle(
      center.translate(0, 4),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Resplandor hacia afuera: la fusión con el fondo. Los factores están
    // calculados para que el desenfoque quepa en el lienzo — con el aro en
    // 134, el alcance a tres sigmas es 148.8 y el radio disponible es 150.
    canvas.drawCircle(
      center,
      radius + stroke * 0.25,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 1.1
        ..isAntiAlias = true
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.stroke != stroke ||
      oldDelegate.crisp != crisp;
}

/// Canal sobre el que corre el progreso.
class _BaseRingPainter extends CustomPainter {
  const _BaseRingPainter({required this.radius, required this.stroke});

  final double radius;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.045)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _BaseRingPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.stroke != stroke;
}

/// El progreso.
///
/// Ver la nota de cabecera del archivo: el degradado se define de 0 a 2π sobre
/// un lienzo rotado −90°, **nunca con un `startAngle` negativo**. Esa era la
/// causa del corte a las tres en punto que tres rampas distintas no lograron
/// quitar.
class _ActiveRingPainter extends CustomPainter {
  const _ActiveRingPainter({
    required this.percent,
    required this.radius,
    required this.stroke,
  });

  final double percent;
  final double radius;
  final double stroke;

  static const int _rampSteps = 64;

  /// Anclas del degradado: verde claro → verde pino → turquesa → azul →
  /// morado, tal como debe leerse el recorrido del 0 al 100 %.
  ///
  /// El azul va antes que el morado a propósito: en la rueda de tonos el
  /// camino natural del verde al morado pasa por turquesa y azul. Meter el
  /// morado antes obligaría a retroceder, y una reversa de tono se ve como un
  /// pliegue en el color. Si lo prefieres al revés, se intercambian los dos
  /// últimos tonos y ya.
  static const List<List<double>> _anchors = <List<double>>[
    <double>[0.00, 105, 0.55, 0.82], // verde claro
    <double>[0.28, 148, 0.62, 0.62], // verde pino
    <double>[0.58, 182, 0.62, 0.62], // turquesa
    <double>[0.80, 222, 0.60, 0.68], // azul
    <double>[1.00, 272, 0.52, 0.66], // morado
  ];

  /// Color exacto en cualquier punto del recorrido.
  ///
  /// Se interpola en HSV, no en RGB: entre dos tonos lejanos la interpolación
  /// RGB pasa por un gris sucio en el punto medio, y ese punto se lee como el
  /// canto de una banda. En HSV el tono gira y la saturación se mantiene.
  static Color colorAt(double t) {
    final double u = t.clamp(0.0, 1.0);
    for (int i = 0; i < _anchors.length - 1; i++) {
      final List<double> a = _anchors[i];
      final List<double> b = _anchors[i + 1];
      if (u <= b[0] || i == _anchors.length - 2) {
        final double span = b[0] - a[0];
        final double k = span <= 0
            ? 0.0
            : ((u - a[0]) / span).clamp(0.0, 1.0);
        return HSVColor.fromAHSV(
          1.0,
          a[1] + (b[1] - a[1]) * k,
          a[2] + (b[2] - a[2]) * k,
          a[3] + (b[3] - a[3]) * k,
        ).toColor();
      }
    }
    return const Color(0xFF4CAF50);
  }

  /// 65 paradas: el paso máximo de tono entre contiguas es 3.9°, así que la
  /// transición es continua aunque el recorrido total sea de 167°.
  static final List<Color> _ramp = List<Color>.generate(
    _rampSteps + 1,
    (int i) => colorAt(i / _rampSteps),
  );

  /// La misma rampa con alfa bajo, para la capa de fusión.
  ///
  /// Hace falta una lista aparte —y no basta con bajar `Paint.color`— porque
  /// **cuando un `Paint` lleva `shader`, Flutter ignora su `color`**.
  static final List<Color> _rampSoft = _ramp
      .map((Color c) => c.withValues(alpha: 0.34))
      .toList(growable: false);

  static final List<double> _rampStops = List<double>.generate(
    _rampSteps + 1,
    (int i) => i / _rampSteps,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final double p = percent.clamp(0.0, 1.0);
    if (p <= 0.0) return;

    final Offset center = size.center(Offset.zero);
    final double sweep = 2 * pi * p;

    // ── Sombra ────────────────────────────────────────────────────────────
    // Sin degradado, así que se dibuja fuera de la rotación: es un color
    // plano y el desplazamiento vertical se lee mejor en coordenadas de
    // pantalla.
    canvas.save();
    canvas.translate(0, 4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweep,
      false,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.restore();

    // ── Arco con degradado ────────────────────────────────────────────────
    // Se rota el lienzo −90°: el eje local +x pasa a apuntar a las 12. Así el
    // degradado puede definirse limpio de 0 a 2π y su parámetro recorre 0→1
    // de forma continua toda la vuelta, sin el envolvimiento que producía el
    // corte. La única junta queda en el origen —las 12— tapada por el badge.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-pi / 2);

    final Rect rect = Rect.fromCircle(center: Offset.zero, radius: radius);

    Shader shaderOf(List<Color> colors) => SweepGradient(
      startAngle: 0.0,
      endAngle: 2 * pi,
      colors: colors,
      stops: _rampStops,
      tileMode: TileMode.clamp,
    ).createShader(rect);

    // Fusión: el mismo degradado, más ancho y desenfocado. Hace que el arco
    // sangre luz sobre el fondo en vez de recortarse contra él.
    canvas.drawArc(
      rect,
      0.0,
      sweep,
      false,
      Paint()
        ..shader = shaderOf(_rampSoft)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 1.3
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.25),
    );

    // El trazo nítido. Es el dato, y el dato no se difumina.
    //
    // Remate PLANO a propósito. Con `StrokeCap.round` el remate de inicio se
    // extiende hacia atrás del ángulo 0, esos píxeles caen en ~359° y el
    // parámetro del degradado los lee como t≈1.0: **el arranque del arco se
    // pintaba con el color del final**. Era el trocito claro que se veía al
    // principio del anillo.
    canvas.drawArc(
      rect,
      0.0,
      sweep,
      false,
      Paint()
        ..shader = shaderOf(_ramp)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..isAntiAlias = true,
    );

    // Las tapas redondas se dibujan a mano, cada una con SU color: la de
    // inicio con el primero de la rampa y la de la cabeza con el que
    // corresponde al avance. Así el remate es redondo y además correcto.
    final double capR = stroke / 2;
    canvas.drawCircle(
      Offset(radius, 0),
      capR,
      Paint()
        ..color = colorAt(0.0)
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      Offset(radius * cos(sweep), radius * sin(sweep)),
      capR,
      Paint()
        ..color = colorAt(p)
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ActiveRingPainter oldDelegate) =>
      oldDelegate.percent != percent ||
      oldDelegate.radius != radius ||
      oldDelegate.stroke != stroke;
}

/// La gota que viaja con el progreso.
class _RingBadge extends StatelessWidget {
  const _RingBadge({required this.size, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double innerSize = size * 0.67;

    final Widget badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.96),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.97),
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF00BCD4).withValues(alpha: 0.16),
            blurRadius: 24,
            spreadRadius: -14,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF22D3EE), Color(0xFF14B8A6)],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: -9,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.water_drop, size: 21, color: Colors.white),
        ),
      ),
    );

    if (onTap == null) return badge;
    return GestureDetector(onTap: onTap, child: badge);
  }
}
