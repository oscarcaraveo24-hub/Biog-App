// lib/widgets/nutrition/nutrition_timeline.dart
//
// LÍNEA DE TIEMPO DEL CULTIVO con la capa de nutrición (pantalla de cultivo).
// Forma final acordada el 14 sep 2026.
//
// Un riel horizontal que se desplaza: TODAS las etapas del ciclo en orden
// cronológico, cada una con su nombre debajo; la actual se ve grande, con
// glow y su arco de progreso; las pasadas van rellenas y las futuras huecas.
// Debajo de las etapas donde la guía abre ventana va una insignia de
// fertilización («N», «NPK») en uno de cinco estados, y al pie una leyenda
// con solo los estados presentes. Arriba: «Etapa 2 de 11» y cuántas
// fertilizaciones tiene el plan. El riel se centra solo en la etapa actual.
// Tocar una etapa abre la hoja con la ventana: dosis recomendada, cuándo,
// por qué, y lo que el sensor vio.
//
// Estética: la de la app (Inter del sistema, w900/w700, verdes de marca,
// glow con `MaskFilter.blur` como en el arco NPK). Movimiento reducido:
// respeta `disableAnimations` (requisito, no extra).
//
// Sin plan elegido (`vm.awaitingDeclaration`, 17 sep 2026): el riel se pinta
// en gris y sin pulso, sin insignias, y la leyenda invita a contestar en NPK;
// tocarlo lleva ahí (la pantalla que lo aloja pasa `onNodeTap`).
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_timeline_vm.dart';
import 'package:bio_g/theme/bio_g_theme.dart';

/// Colores semánticos de los marcadores. Mismos tonos que las píldoras NPK.
class NutritionTimelineColors {
  const NutritionTimelineColors._();

  static const Color railFuture = Color(0x33203A2F);
  static const Color nodeFuture = Color(0xFF9AA8A1);
  static const Color open = Color(0xFFB9761A);
  static const Color attended = Color(0xFF2E7D5A);
  static const Color unattended = Color(0xFFB4433A);
  static const Color pending = Color(0xFF6E7B75);
  static const Color informative = Color(0xFF8B9A93);

  static Color of(NutritionMarkerState s) => switch (s) {
    NutritionMarkerState.pending => pending,
    NutritionMarkerState.open => open,
    NutritionMarkerState.attended => attended,
    NutritionMarkerState.unattended => unattended,
    NutritionMarkerState.informative => informative,
  };

  /// Glifo del estado (leyenda e insignia).
  static String glyph(NutritionMarkerState s) => switch (s) {
    NutritionMarkerState.pending => '▲',
    NutritionMarkerState.open => '◆',
    NutritionMarkerState.attended => '✓',
    NutritionMarkerState.unattended => '!',
    NutritionMarkerState.informative => '⋯',
  };

  /// Palabra del estado para la leyenda.
  static String legendEs(NutritionMarkerState s) => switch (s) {
    NutritionMarkerState.pending => 'próxima',
    NutritionMarkerState.open => 'aplica ahora',
    NutritionMarkerState.attended => 'atendida',
    NutritionMarkerState.unattended => 'sin evidencia',
    NutritionMarkerState.informative => 'orientativa / sin peso',
  };
}

class NutritionTimeline extends StatefulWidget {
  const NutritionTimeline({
    super.key,
    required this.vm,
    required this.accentColor,
    this.nodeWidth = 78,
    this.onNodeTap,
  });

  final NutritionTimelineVm vm;

  /// Color del nodo actual (el del cuidado del cultivo, para que hable el
  /// mismo idioma que el chip de estado).
  final Color accentColor;

  /// Ancho de cada etapa en el riel.
  final double nodeWidth;

  /// Si es null, el toque abre [NutritionTimelineSheet].
  final void Function(TimelineNodeVm node)? onNodeTap;

  /// Alto total que ocupa el widget (cabecera + hueco + riel + hueco +
  /// leyenda), para que la pantalla que lo aloja presupueste su scroll.
  static const double blockHeight =
      _TimelineHeader.height +
      6 +
      _NodeColumn.height +
      4 +
      _TimelineLegend.height;

  @override
  State<NutritionTimeline> createState() => _NutritionTimelineState();
}

class _NutritionTimelineState extends State<NutritionTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  final ScrollController _scroll = ScrollController();
  int _centeredIndex = -2;
  double _viewport = 0;
  int _centerAttempts = 0;

  bool get _needsPulse =>
      !widget.vm.awaitingDeclaration &&
      widget.vm.nodes.any(
        (TimelineNodeVm n) =>
            n.isCurrent || n.marker?.state == NutritionMarkerState.open,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant NutritionTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
    if (oldWidget.vm.currentIndex != widget.vm.currentIndex ||
        oldWidget.vm.nodes.length != widget.vm.nodes.length) {
      _centeredIndex = -2;
      _scheduleCenter();
    }
  }

  void _syncPulse() {
    final bool reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced || !_needsPulse) {
      _pulse.stop();
      _pulse.value = 0.35;
      return;
    }
    if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
  }

  /// Centra la etapa actual en el riel (una vez por etapa y por ancho). El
  /// riel puede no estar adjunto todavía en el primer cuadro (va dentro del
  /// revelado de la pantalla): se reintenta unos cuadros, no indefinidamente.
  void _scheduleCenter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final int idx = widget.vm.currentIndex;
      if (idx < 0 || idx == _centeredIndex) return;
      if (!_scroll.hasClients || _viewport <= 0) {
        if (_centerAttempts < 8) {
          _centerAttempts++;
          _scheduleCenter();
        }
        return;
      }
      _centerAttempts = 0;
      final double target = widget.nodeWidth * (idx + 0.5) - _viewport / 2;
      final double max = _scroll.position.maxScrollExtent;
      final double offset = target.clamp(0.0, math.max(0.0, max));
      final bool reduced =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduced || (offset - _scroll.offset).abs() < 2) {
        _scroll.jumpTo(offset);
      } else {
        _scroll.animateTo(
          offset,
          duration: const Duration(milliseconds: 520),
          curve: const Cubic(0.20, 0.92, 0.28, 1.0),
        );
      }
      _centeredIndex = idx;
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _open(TimelineNodeVm node) {
    final void Function(TimelineNodeVm)? handler = widget.onNodeTap;
    if (handler != null) {
      handler(node);
    } else {
      NutritionTimelineSheet.show(context, vm: widget.vm, node: node);
    }
  }

  @override
  Widget build(BuildContext context) {
    final NutritionTimelineVm vm = widget.vm;
    if (vm.isEmpty) return const SizedBox.shrink();
    final double nodeW = widget.nodeWidth;
    final int n = vm.nodes.length;
    final double railWidth = nodeW * n + (vm.isCycle ? _LoopTail.width : 0);
    final bool greyed = vm.awaitingDeclaration;
    final Color accent = greyed
        ? NutritionTimelineColors.informative
        : widget.accentColor;

    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TimelineHeader(vm: vm, accent: accent),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double vw = c.maxWidth.isFinite ? c.maxWidth : 320;
            if (vw != _viewport) {
              _viewport = vw;
              _centeredIndex = -2;
              _scheduleCenter();
            }
            return SizedBox(
              height: _NodeColumn.height,
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: railWidth,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (BuildContext context, Widget? _) {
                              return CustomPaint(
                                painter: _NutritionRailPainter(
                                  vm: vm,
                                  accent: accent,
                                  nodeWidth: nodeW,
                                  pulse: Curves.easeInOut.transform(
                                    _pulse.value,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < n; i++)
                            _NodeColumn(
                              node: vm.nodes[i],
                              width: nodeW,
                              pulse: _pulse,
                              onTap: () => _open(vm.nodes[i]),
                            ),
                          if (vm.isCycle) const _LoopTail(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        _TimelineLegend(vm: vm),
      ],
    );
    if (!greyed) return column;
    // Sin plan elegido: todo en gris (sin color de marca ni glow) y algo
    // apagado, pero legible y tocable.
    return Semantics(
      button: true,
      label: 'Línea de tiempo del cultivo, plan de fertilización sin elegir. '
          'Toca para elegirlo en la pantalla de nutrientes.',
      child: Opacity(
        opacity: 0.62,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: column,
        ),
      ),
    );
  }
}

/// «ETAPA 2 DE 11 · Establecimiento radicular» y, a la derecha, el plan.
class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({required this.vm, required this.accent});

  final NutritionTimelineVm vm;
  final Color accent;

  /// Alto de la fila (una línea de 10.5 px con margen).
  static const double height = 16;

  @override
  Widget build(BuildContext context) {
    final int fert = vm.fertilizationCount;
    final String? plan = vm.planSummaryEs;
    final String right =
        plan ??
        (vm.hasGuide
            ? (fert == 1 ? '1 fertilización' : '$fert fertilizaciones')
            : '');
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            vm.stageCountEs.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w900,
              color: BioGTheme.green700,
            ),
          ),
          const Spacer(),
          if (right.isNotEmpty) ...[
            Icon(
              Icons.eco_rounded,
              size: 12,
              color: BioGTheme.green700.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(alpha: 0.52),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Una etapa del riel: el hueco donde el painter dibuja el punto, el nombre
/// corto y, si la guía abre ventana aquí, la insignia de fertilización.
class _NodeColumn extends StatelessWidget {
  const _NodeColumn({
    required this.node,
    required this.width,
    required this.pulse,
    required this.onTap,
  });

  final TimelineNodeVm node;
  final double width;
  final Animation<double> pulse;
  final VoidCallback onTap;

  /// Alto total de la fila del riel: punto + nombre (2 líneas) + insignia.
  static const double height = 96;

  /// Alto reservado arriba para el punto (lo pinta `_NutritionRailPainter`).
  static const double railZone = 34;

  @override
  Widget build(BuildContext context) {
    final NutritionMarkerVm? m = node.marker;
    final Color labelColor = switch (node.phase) {
      TimelinePhase.current => const Color(0xFF0E1A16),
      TimelinePhase.past => Colors.black.withValues(alpha: 0.58),
      TimelinePhase.future => Colors.black.withValues(alpha: 0.44),
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: railZone),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                node.shortLabelEs,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.6,
                  height: 1.15,
                  fontWeight: node.isCurrent
                      ? FontWeight.w900
                      : FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ),
            const SizedBox(height: 5),
            if (m != null) _FertBadge(marker: m, pulse: pulse),
          ],
        ),
      ),
    );
  }
}

/// Insignia de fertilización: glifo del estado + nutrientes («◆ N», «✓ NPK»).
class _FertBadge extends StatelessWidget {
  const _FertBadge({required this.marker, required this.pulse});

  final NutritionMarkerVm marker;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final NutritionMarkerState s = marker.state;
    final Color color = NutritionTimelineColors.of(s);
    final String letters = marker.nutrients.isEmpty
        ? 'N'
        : marker.nutrients.map(_letter).join();
    final bool filled =
        s == NutritionMarkerState.open ||
        s == NutritionMarkerState.attended ||
        s == NutritionMarkerState.unattended;
    final bool dotted = s == NutritionMarkerState.informative;

    Widget pill(double glow) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: filled
            ? color
            : Colors.white.withValues(alpha: dotted ? 0.55 : 0.9),
        border: Border.all(
          color: filled
              ? Colors.white.withValues(alpha: 0.75)
              : color.withValues(alpha: dotted ? 0.55 : 0.8),
          width: 1.1,
        ),
        boxShadow: glow <= 0
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.28 + glow * 0.22),
                  blurRadius: 10 + glow * 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Text(
        '${NutritionTimelineColors.glyph(s)} $letters',
        style: TextStyle(
          fontSize: 9.5,
          height: 1.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
          color: filled ? Colors.white : color,
        ),
      ),
    );

    if (s != NutritionMarkerState.open) return pill(0);
    return AnimatedBuilder(
      animation: pulse,
      builder: (BuildContext context, Widget? _) =>
          pill(Curves.easeInOut.transform(pulse.value)),
    );
  }

  static String _letter(AgroMetricKey k) => switch (k) {
    AgroMetricKey.n => 'N',
    AgroMetricKey.p => 'P',
    AgroMetricKey.k => 'K',
    _ => '',
  };
}

/// Flecha de ciclo al final del riel de un árbol: la última etapa vuelve al
/// reposo.
class _LoopTail extends StatelessWidget {
  const _LoopTail();

  static const double width = 30;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _NodeColumn.height,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Align(
          alignment: Alignment.topCenter,
          child: Icon(
            Icons.loop_rounded,
            size: 16,
            color: BioGTheme.green700.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

/// Leyenda con los estados presentes en el riel (solo esos).
class _TimelineLegend extends StatelessWidget {
  const _TimelineLegend({required this.vm});

  final NutritionTimelineVm vm;

  /// Alto reservado (una línea; con muchos estados puede envolver a dos, y
  /// el hueco inferior de la tarjeta lo absorbe).
  static const double height = 14;

  @override
  Widget build(BuildContext context) {
    final List<NutritionMarkerState> present = <NutritionMarkerState>[
      for (final NutritionMarkerState s in NutritionMarkerState.values)
        if (vm.nodes.any((TimelineNodeVm n) => n.marker?.state == s)) s,
    ];
    if (present.isEmpty) {
      return Text(
        vm.awaitingDeclaration
            ? 'Elige cómo vas a fertilizar en NPK para ver aquí tus ventanas.'
            : vm.isAlreadyDone
            ? 'Nitrógeno ya aplicado según tu plan · sin más ventanas.'
            : vm.hasGuide
            ? 'Sin ventanas de fertilización en este ciclo.'
            : 'Etapas del ciclo · sin guía nutricional curada.',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black.withValues(alpha: 0.42),
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 2,
      children: [
        for (final NutritionMarkerState s in present)
          Text(
            '${NutritionTimelineColors.glyph(s)} ${NutritionTimelineColors.legendEs(s)}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: NutritionTimelineColors.of(s),
            ),
          ),
      ],
    );
  }
}

/// Pinta el riel: tramo recorrido con glow, tramo futuro tenue, puntos de
/// etapa y el nodo actual con halo que respira y arco de progreso.
class _NutritionRailPainter extends CustomPainter {
  _NutritionRailPainter({
    required this.vm,
    required this.accent,
    required this.nodeWidth,
    required this.pulse,
  });

  final NutritionTimelineVm vm;
  final Color accent;
  final double nodeWidth;

  /// 0..1, late.
  final double pulse;

  static const double railY = 17;

  double _x(int i) => nodeWidth * (i + 0.5);

  @override
  void paint(Canvas canvas, Size size) {
    final List<TimelineNodeVm> nodes = vm.nodes;
    final int n = nodes.length;
    if (n == 0) return;
    final int cur = vm.currentIndex;
    final double x0 = _x(0);
    final double x1 = _x(n - 1);

    // ── Riel futuro ──────────────────────────────────────────────────────
    final Paint futurePaint = Paint()
      ..color = NutritionTimelineColors.railFuture
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x0, railY), Offset(x1, railY), futurePaint);

    // ── Ciclo anual (árboles): la última etapa vuelve al reposo ──────────
    // El riel sigue hasta la flecha de bucle y un arco punteado regresa por
    // encima hasta la etapa donde arranca el ciclo.
    final int? cycleStart = vm.cycleStartIndex;
    if (vm.isCycle && cycleStart != null && cycleStart >= 0 && cycleStart < n) {
      final double xTail = x1 + _LoopTail.width * 0.5;
      canvas.drawLine(Offset(x1, railY), Offset(xTail, railY), futurePaint);
      final double xBack = _x(cycleStart);
      final Path arc = Path()
        ..moveTo(xTail, railY - 2)
        ..quadraticBezierTo((xTail + xBack) / 2, railY - 30, xBack, railY - 8);
      _drawDashed(
        canvas,
        arc,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..color = BioGTheme.green700.withValues(alpha: 0.35),
      );
    }

    // ── Riel recorrido: hasta el nodo actual más su progreso ─────────────
    if (cur >= 0) {
      final double xc = _x(cur);
      final double prog = nodes[cur].progress01 ?? 0.0;
      final double xNext = cur + 1 < n ? _x(cur + 1) : xc;
      final double xEnd = xc + (xNext - xc) * prog;
      if (xEnd > x0) {
        final Rect r = Rect.fromLTWH(x0, railY - 3, math.max(1, xEnd - x0), 6);
        // Glow: el mismo degradado, translúcido y difuminado, debajo del
        // trazo sólido.
        canvas.drawLine(
          Offset(x0, railY),
          Offset(xEnd, railY),
          Paint()
            ..shader = LinearGradient(
              colors: [
                BioGTheme.brandTop.withValues(alpha: 0.38),
                BioGTheme.brandMid.withValues(alpha: 0.38),
                BioGTheme.green700.withValues(alpha: 0.38),
              ],
            ).createShader(r)
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        );
        canvas.drawLine(
          Offset(x0, railY),
          Offset(xEnd, railY),
          Paint()
            ..shader = const LinearGradient(
              colors: [
                BioGTheme.brandTop,
                BioGTheme.brandMid,
                BioGTheme.green700,
              ],
            ).createShader(r)
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ── Puntos ───────────────────────────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final TimelineNodeVm node = nodes[i];
      final Offset c = Offset(_x(i), railY);
      switch (node.phase) {
        case TimelinePhase.past:
          canvas.drawCircle(
            c,
            5.2,
            Paint()..color = BioGTheme.green700.withValues(alpha: 0.9),
          );
          canvas.drawCircle(
            c,
            5.2,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = Colors.white.withValues(alpha: 0.85),
          );
          break;
        case TimelinePhase.future:
          canvas.drawCircle(c, 4.6, Paint()..color = const Color(0xFFF7F8F8));
          canvas.drawCircle(
            c,
            4.6,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.7
              ..color = NutritionTimelineColors.nodeFuture,
          );
          break;
        case TimelinePhase.current:
          _drawCurrent(canvas, c, node.progress01 ?? 0.0);
          break;
      }
    }
  }

  void _drawCurrent(Canvas canvas, Offset c, double progress) {
    // Glow doble (patrón del arco NPK) que respira.
    final double breathe = 0.8 + pulse * 0.2;
    canvas.drawCircle(
      c,
      16 * breathe,
      Paint()
        ..color = accent.withValues(alpha: 0.16 + pulse * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      c,
      10.5,
      Paint()
        ..color = accent.withValues(alpha: 0.26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Anillo de progreso de la etapa.
    canvas.drawCircle(
      c,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: 0.95),
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 10),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..color = accent,
      );
    }
    canvas.drawCircle(c, 6.4, Paint()..color = accent);
    canvas.drawCircle(
      c.translate(-1.8, -1.8),
      1.9,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  /// Traza un camino a rayas (4 px de trazo, 4 px de hueco).
  static void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final PathMetric metric in path.computeMetrics()) {
      double at = 0;
      while (at < metric.length) {
        final double end = math.min(at + 4, metric.length);
        canvas.drawPath(metric.extractPath(at, end), paint);
        at += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NutritionRailPainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.vm != vm ||
      oldDelegate.accent != accent ||
      oldDelegate.nodeWidth != nodeWidth;
}

// ═══════════════════════════════════════════════════════════════════════════
// HOJA DE DETALLE
// ═══════════════════════════════════════════════════════════════════════════

/// Detalle de una etapa y de su ventana de nutrición.
class NutritionTimelineSheet extends StatelessWidget {
  const NutritionTimelineSheet({
    super.key,
    required this.vm,
    required this.node,
  });

  final NutritionTimelineVm vm;
  final TimelineNodeVm node;

  static Future<void> show(
    BuildContext context, {
    required NutritionTimelineVm vm,
    required TimelineNodeVm node,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NutritionTimelineSheet(vm: vm, node: node),
    );
  }

  String get _phaseEs => switch (node.phase) {
    TimelinePhase.past => 'Etapa pasada',
    TimelinePhase.current => 'Etapa actual',
    TimelinePhase.future => 'Etapa por venir',
  };

  @override
  Widget build(BuildContext context) {
    final NutritionMarkerVm? m = node.marker;
    final int idx = vm.nodes.indexOf(node);
    final String position = idx < 0
        ? ''
        : ' · ${idx + 1} de ${vm.nodes.length}';
    final String days = node.dayStart == null
        ? ''
        : node.dayEnd == null
        ? ' · desde el día ${node.dayStart}'
        : ' · días ${node.dayStart}–${node.dayEnd}';

    return DraggableScrollableSheet(
      initialChildSize: m == null ? 0.34 : 0.62,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (BuildContext context, ScrollController controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6FAF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$_phaseEs$position$days'.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withValues(alpha: 0.42),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                node.labelEs,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0E1A16),
                ),
              ),
              const SizedBox(height: 10),
              if (m == null)
                Text(
                  vm.hasGuide
                      ? 'En esta etapa la guía no reparte fertilizante. BIO-G '
                            'sigue observando el suelo.'
                      : 'Sin guía nutricional curada para este cultivo: la '
                            'línea muestra solo las etapas.',
                  style: TextStyle(
                    fontSize: 13.2,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.68),
                  ),
                )
              else
                _MarkerDetail(marker: m),
            ],
          ),
        );
      },
    );
  }
}

class _MarkerDetail extends StatelessWidget {
  const _MarkerDetail({required this.marker});

  final NutritionMarkerVm marker;

  @override
  Widget build(BuildContext context) {
    final NutritionMarkerVm m = marker;
    final Color color = NutritionTimelineColors.of(m.state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Chip(text: m.state.labelEs, color: color),
            if (m.isCritical)
              const _Chip(text: 'Ventana importante', color: Color(0xFF5B6470)),
            if (m.nutrients.isNotEmpty)
              _Chip(text: m.nutrientsShortEs, color: const Color(0xFF2E7D5A)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          m.labelEs,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0E1A16),
          ),
        ),
        if ((m.stageSpanEs ?? '').isNotEmpty && m.stageSpanEs != m.labelEs)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              m.stageSpanEs!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        if ((m.noteEs ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            m.noteEs!,
            style: TextStyle(
              fontSize: 13.2,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
        if (m.hasDoses) ...[
          const SizedBox(height: 14),
          const _SectionTitle('Dosis recomendada'),
          const SizedBox(height: 6),
          for (final TimelineDose d in m.doses)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DoseRow(dose: d),
            ),
          Text(
            'Es lo que recomienda la guía para esta ventana, no lo que el '
            'sensor midió. Ajústalo con tu análisis de suelo.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.48),
            ),
          ),
        ],
        if ((m.timingEs ?? '').isNotEmpty)
          _SectionLines(title: 'Cuándo', lines: <String>[m.timingEs!]),
        if ((m.rationaleEs ?? '').isNotEmpty)
          _SectionLines(title: 'Por qué', lines: <String>[m.rationaleEs!]),
        if (m.rulesEs.isNotEmpty)
          _SectionLines(title: 'Reglas', lines: m.rulesEs),
        if ((m.outcomeEs ?? '').isNotEmpty || m.evidenceEs.isNotEmpty)
          _SectionLines(
            title: 'Lo que vio el sensor',
            lines: <String>[
              if ((m.outcomeEs ?? '').isNotEmpty) m.outcomeEs!,
              ...m.evidenceEs,
            ],
          ),
      ],
    );
  }
}

class _DoseRow extends StatelessWidget {
  const _DoseRow({required this.dose});

  final TimelineDose dose;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (dose.nutrient) {
      AgroMetricKey.n => const Color(0xFFB38A2E),
      AgroMetricKey.p => const Color(0xFF2FAF63),
      AgroMetricKey.k => const Color(0xFF2B7EBB),
      _ => const Color(0xFF5B6470),
    };
    final String? eq = dose.range.commercialEquivalentEs;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dose.range.labelEs,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0E1A16),
                ),
              ),
              if (eq != null && eq.trim().isNotEmpty)
                Text(
                  eq,
                  style: TextStyle(
                    fontSize: 12.4,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.62),
                  ),
                ),
              if (dose.range.isConditional && dose.range.conditionEs != null)
                Text(
                  dose.range.conditionEs!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w900,
        color: Color(0xFF2E7D5A),
      ),
    );
  }
}

class _SectionLines extends StatelessWidget {
  const _SectionLines({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final List<String> clean = lines
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    if (clean.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          const SizedBox(height: 6),
          for (final String line in clean)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 12.6,
                        height: 1.32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
