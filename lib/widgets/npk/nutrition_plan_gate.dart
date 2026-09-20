// lib/widgets/npk/nutrition_plan_gate.dart
//
// «¿Cómo vas a fertilizar esta temporada?» — la única pregunta que BIO-G le
// hace al productor sobre nutrición (decisión de producto, 13 sep 2026;
// forma final acordada el 14 sep: PANTALLA COMPLETA hasta contestar, con el
// mismo lenguaje visual del onboarding —fondo, cabecera con el icono del
// cultivo, tarjetas de tres columnas como «¿Qué tipo de cultivo es?» y botón
// «Continuar»— para que se sienta parte de la app y no un diálogo suelto).
//
// Cubre la pantalla NPK la primera vez que se entra con un cultivo sembrado y
// algo que decidir. No deja ver NPK sin contestar (sin la respuesta las dosis
// no se pueden repartir a la forma de trabajar del productor); volver al
// Panel con la flecha sí se puede siempre: la pregunta espera a la próxima
// entrada. Una vez contestada, la pantalla NPK aparece tal cual y la
// respuesta queda guardada por temporada; el icono de ajustes de la barra
// vuelve a abrir esta pantalla, ahora con cierre.
//
// Reglas de diseño, con su evidencia:
//   · Con la RAZÓN visible: explicar por qué se pregunta pesa más que cuándo
//     (Elbitar et al. 2021, OR 2.73 vs 1.48).
//   · Ninguna opción pre-marcada; la recomendada lleva ★. Un default que
//     nadie corrige se vuelve error permanente (ASHE, Forth et al.).
//   · Las opciones que no aplican se muestran deshabilitadas CON su razón,
//     no se esconden: el productor aprende por qué.
//   · Categórica (una / dos / tres o más / ya fertilicé), nunca kilos. Se
//     elige y se confirma con «Continuar»: dos pasos, como el resto del
//     onboarding.
//   · El número de pasadas se VE antes de leerse: una, dos o tres esferas de
//     nitrógeno (el mismo icono `ic_nitrogen` de la gráfica del historial);
//     «ya fertilicé» es una esfera con palomita.
//   · Cuatro tarjetas en dos filas de dos (17 sep 2026): la cuarta, «Ya
//     fertilicé», es para quien dio su nitrógeno antes de instalar el Bio-G
//     y no va a volver a aplicar. Con tres columnas no cabían.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/nutrition/nutrition_plan_resolver.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_season_declaration.dart';
import 'package:bio_g/theme/bio_g_theme.dart';
import 'package:bio_g/widgets/onboarding/onboarding_asset_badge.dart';
import 'package:bio_g/widgets/onboarding/onboarding_background.dart';
import 'package:bio_g/widgets/onboarding/onboarding_header.dart';
import 'package:bio_g/widgets/onboarding/onboarding_primary_button.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

class NutritionPlanGate extends StatefulWidget {
  const NutritionPlanGate({
    super.key,
    required this.plan,
    required this.onSelect,
    this.cropIconAsset,
    this.busy = false,
    this.onClose,
  });

  final NutritionPlanResolution plan;
  final Future<void> Function(NitrogenPassPlan plan) onSelect;

  /// Icono del cultivo (el mismo del Panel y del onboarding), arriba del
  /// título. Null → logo de BIO-G.
  final String? cropIconAsset;

  /// Guardando: las tarjetas y el botón no responden.
  final bool busy;

  /// Solo cuando ya hay respuesta y el productor vino a cambiarla: permite
  /// salir sin tocar nada. La primera vez es null: hay que contestar.
  final VoidCallback? onClose;

  /// Hay algo que preguntar: dos o más opciones válidas para este cultivo y
  /// este suelo.
  static bool isRelevant(NutritionPlanResolution plan) => plan.canDeclare;

  /// Esfera de nitrógeno de la app (la misma de la gráfica NPK del
  /// historial): con ella se cuenta «una, dos, tres» pasadas.
  static const String nitrogenIconAsset = 'assets/icons/metrics/ic_nitrogen.png';

  @override
  State<NutritionPlanGate> createState() => _NutritionPlanGateState();
}

class _NutritionPlanGateState extends State<NutritionPlanGate> {
  /// Opción elegida (todavía sin confirmar con «Continuar»).
  NitrogenPassPlan? _selected;

  /// Opción deshabilitada que el productor tocó: su razón se muestra.
  NitrogenPassPlan? _explaining;

  @override
  void initState() {
    super.initState();
    // Al volver a abrir, arranca en lo que ya está guardado.
    _seedFromPlan();
  }

  @override
  void didUpdateWidget(covariant NutritionPlanGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si una declaración llega por detrás (otra pantalla, la sincronización)
    // mientras la pregunta está abierta y aún no se tocó nada, se refleja.
    if (_selected == null && widget.plan != oldWidget.plan) _seedFromPlan();
  }

  void _seedFromPlan() {
    final NutritionPlanResolution plan = widget.plan;
    if (plan.declarationApplied) _selected = plan.declaration?.passes;
  }

  void _tap(NitrogenPassOption option) {
    if (widget.busy) return;
    setState(() {
      if (option.enabled) {
        _selected = option.plan;
        _explaining = null;
      } else {
        _explaining = option.plan;
      }
    });
  }

  Future<void> _confirm() async {
    final NitrogenPassPlan? chosen = _selected;
    if (chosen == null || widget.busy) return;
    await widget.onSelect(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final NutritionPlanResolution plan = widget.plan;
    final String crop = plan.guide?.cropLabelEs ?? 'tu cultivo';
    final NitrogenPassOption? selectedOption =
        _selected == null ? null : plan.optionFor(_selected!);
    final NitrogenPassOption? explained =
        _explaining == null ? null : plan.optionFor(_explaining!);
    final NitrogenPassOption? recommended = plan.recommendedOption;
    final bool canContinue = selectedOption != null &&
        selectedOption.enabled &&
        !widget.busy;
    final bool firstTime = widget.onClose == null;
    final double bottomPad = MediaQuery.of(context).padding.bottom;

    return OnboardingBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                // La barra de la pantalla NPK es transparente y va por encima
                // del cuerpo (flecha para volver): se deja su alto libre.
                padding: const EdgeInsets.fromLTRB(24, kToolbarHeight - 6, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!firstTime)
                      Align(
                        alignment: Alignment.centerRight,
                        child: _CloseButton(
                          onTap: widget.busy ? null : widget.onClose,
                        ),
                      ),
                    OnboardingHeader(
                      logoAsset: widget.cropIconAsset ?? OnboardingUiAssets.logo,
                      logoHeight: 88,
                      title: '¿Cómo vas a fertilizar esta temporada?',
                      subtitle:
                          'Así BIO-G reparte las dosis de $crop a tu forma de '
                          'trabajar, no al revés.',
                    ),
                    const SizedBox(height: 22),
                    // Dos filas de dos tarjetas (la última fila puede quedar
                    // con una sola, centrada a la izquierda con su hueco).
                    for (int row = 0; row * 2 < plan.options.length; row++) ...[
                      if (row > 0) const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int col = 0; col < 2; col++) ...[
                            if (col > 0) const SizedBox(width: 12),
                            Expanded(
                              child: row * 2 + col < plan.options.length
                                  ? _PassCard(
                                      option: plan.options[row * 2 + col],
                                      selected: _selected ==
                                          plan.options[row * 2 + col].plan,
                                      dimmed: widget.busy,
                                      onTap: () =>
                                          _tap(plan.options[row * 2 + col]),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    _Explanation(
                      selected: selectedOption,
                      explained: explained,
                      recommended: recommended,
                      cropLabelEs: crop,
                    ),
                    const SizedBox(height: 16),
                    _Footnote(
                      textureKnown: plan.textureClass != SoilTextureClass.unknown,
                      textureLabelEs: plan.textureClass.labelEs,
                      firstTime: firstTime,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + bottomPad * 0.25),
              child: OnboardingPrimaryButton(
                label: firstTime ? 'Continuar' : 'Guardar cambio',
                onPressed: canContinue ? _confirm : null,
                enabled: selectedOption != null && selectedOption.enabled,
                loading: widget.busy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de una opción: mismo cascarón, colores y proporciones que las
/// tarjetas «Campo / Huerto / Maceta» del onboarding; arriba las esferas de
/// nitrógeno que cuentan las pasadas, abajo el nombre y la marca.
class _PassCard extends StatelessWidget {
  const _PassCard({
    required this.option,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final NitrogenPassOption option;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = option.enabled;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: enabled
          ? option.plan.labelEs
          : '${option.plan.labelEs}, no disponible para este cultivo',
      child: AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: dimmed ? 0.65 : 1,
      child: SizedBox(
        height: 188,
        child: BioGGlassCard(
          radius: 22,
          useBackdropBlur: false,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
          backgroundColor: !enabled
              ? const Color(0xFFF3F5F6).withValues(alpha: 0.86)
              : selected
                  ? const Color(0xFFF0F7EE).withValues(alpha: 0.96)
                  : const Color(0xFFF7F8F8).withValues(alpha: 0.94),
          borderColor: !enabled
              ? Colors.white.withValues(alpha: 0.80)
              : selected
                  ? const Color(0xFF8EB07C)
                  : Colors.white.withValues(alpha: 0.94),
          boxShadows: selected
              ? [
                  BoxShadow(
                    color: BioGTheme.brandTop.withValues(alpha: 0.20),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            enabled
                                ? const Color(0xFFD7F1FF)
                                : const Color(0xFFE6EBEE),
                            !enabled
                                ? const Color(0xFFF0F2F4)
                                : selected
                                    ? const Color(0xFFEAF8D8)
                                    : const Color(0xFFF5F8FB),
                          ],
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: _NitrogenCluster(
                              plan: option.plan,
                              enabled: enabled,
                              selected: selected,
                            ),
                          ),
                          if (option.recommended)
                            Positioned(
                              left: 6,
                              top: 6,
                              child: _StarChip(enabled: enabled),
                            ),
                          if (!enabled)
                            Positioned(
                              right: 7,
                              top: 7,
                              child: Icon(
                                Icons.lock_rounded,
                                size: 15,
                                color: Colors.black.withValues(alpha: 0.30),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    option.plan.labelEs,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.12,
                      letterSpacing: -0.1,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      color: enabled
                          ? const Color(0xFF2D3941)
                          : const Color(0xFF2D3941).withValues(alpha: 0.40),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: !enabled
                        ? const Color(0xFFE1E6E9)
                        : selected
                            ? const Color(0xFF91C46D)
                            : const Color(0xFFD0D8DC),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// Una, dos o tres esferas de nitrógeno (y un «+» en «tres o más»). Las
/// esferas no leen kilos: cuentan pasadas, que es lo único que se pregunta.
class _NitrogenCluster extends StatelessWidget {
  const _NitrogenCluster({
    required this.plan,
    required this.enabled,
    required this.selected,
  });

  final NitrogenPassPlan plan;
  final bool enabled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double w = c.maxWidth;
        final double h = c.maxHeight;
        final double cx = w / 2;
        final double cy = h / 2 + 2;

        final List<Widget> balls = switch (plan) {
          NitrogenPassPlan.single => <Widget>[
              _ball(cx, cy, math.min(w, h) * 0.56, enabled),
            ],
          NitrogenPassPlan.two => <Widget>[
              _ball(cx - w * 0.20, cy + h * 0.06, math.min(w, h) * 0.42, enabled),
              _ball(cx + w * 0.20, cy - h * 0.06, math.min(w, h) * 0.42, enabled),
            ],
          NitrogenPassPlan.threeOrMore => <Widget>[
              _ball(cx - w * 0.19, cy + h * 0.12, math.min(w, h) * 0.37, enabled),
              _ball(cx + w * 0.19, cy + h * 0.12, math.min(w, h) * 0.37, enabled),
              _ball(cx, cy - h * 0.15, math.min(w, h) * 0.37, enabled),
            ],
          // «Ya fertilicé»: una esfera ya puesta, con su palomita.
          NitrogenPassPlan.alreadyDone => <Widget>[
              _ball(cx, cy, math.min(w, h) * 0.50, enabled),
            ],
        };

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Halo suave detrás de las esferas cuando la tarjeta está elegida.
            if (selected && enabled)
              Positioned(
                left: cx - math.min(w, h) * 0.40,
                top: cy - math.min(w, h) * 0.40,
                width: math.min(w, h) * 0.80,
                height: math.min(w, h) * 0.80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        BioGTheme.brandTop.withValues(alpha: 0.22),
                        BioGTheme.brandTop.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ...balls,
            if (plan == NitrogenPassPlan.threeOrMore)
              Positioned(
                right: w * 0.10,
                top: h * 0.10,
                child: _PlusChip(enabled: enabled),
              ),
            if (plan == NitrogenPassPlan.alreadyDone)
              Positioned(
                right: w * 0.12,
                bottom: h * 0.12,
                child: _CheckChip(enabled: enabled),
              ),
          ],
        );
      },
    );
  }

  /// Esfera centrada en (x, y) con diámetro [d]. La imagen del icono trae
  /// aire alrededor de la esfera (la esfera ocupa ~55 % del ancho del
  /// archivo, centrada): se escala para que la ESFERA mida [d], y el aire
  /// transparente desborda sin dibujar nada.
  static Widget _ball(double x, double y, double d, bool enabled) {
    final double imgW = d / 0.548;
    final double imgH = imgW * 1.25; // proporción del archivo (540 × 675)
    Widget img = Image.asset(
      NutritionPlanGate.nitrogenIconAsset,
      width: imgW,
      height: imgH,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return Center(
          child: Container(
            width: d,
            height: d,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFB38A2E),
            ),
            alignment: Alignment.center,
            child: Text(
              'N',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: d * 0.5,
              ),
            ),
          ),
        );
      },
    );
    if (!enabled) {
      img = Opacity(
        opacity: 0.55,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: img,
        ),
      );
    }
    return Positioned(
      left: x - d / 2,
      top: y - d / 2,
      width: d,
      height: d,
      child: OverflowBox(
        maxWidth: imgW,
        maxHeight: imgH,
        alignment: Alignment.center,
        child: img,
      ),
    );
  }
}

/// «+» de «tres o más».
class _PlusChip extends StatelessWidget {
  const _PlusChip({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[BioGTheme.brandTop, BioGTheme.brandMid],
              )
            : null,
        color: enabled ? null : Colors.black.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.92), width: 1.5),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: BioGTheme.brandMid.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: const Text(
        '+',
        style: TextStyle(
          fontSize: 14,
          height: 1.0,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// «✓» de «ya fertilicé».
class _CheckChip extends StatelessWidget {
  const _CheckChip({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled ? BioGTheme.green700 : Colors.black.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.92), width: 1.5),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: BioGTheme.green700.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
    );
  }
}

class _StarChip extends StatelessWidget {
  const _StarChip({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: BioGTheme.green700.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '★ Guía',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          color: enabled ? BioGTheme.green700 : Colors.black.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

/// Bajo las tarjetas: qué significa la opción elegida (o la recomendada si no
/// hay elección), o por qué la tocada no aplica.
class _Explanation extends StatelessWidget {
  const _Explanation({
    required this.selected,
    required this.explained,
    required this.recommended,
    required this.cropLabelEs,
  });

  final NitrogenPassOption? selected;
  final NitrogenPassOption? explained;
  final NitrogenPassOption? recommended;
  final String cropLabelEs;

  @override
  Widget build(BuildContext context) {
    final NitrogenPassOption? why = explained;
    if (why != null && !why.enabled) {
      final NitrogenPassOption? keep = selected;
      final String reason =
          why.disabledReasonEs ?? 'No disponible para este cultivo.';
      return _InfoBox(
        icon: Icons.lock_rounded,
        color: BioGTheme.warn,
        title: '${why.plan.labelEs}: no aplica aquí',
        text: keep == null
            ? reason
            : '$reason Tu elección sigue siendo «${keep.plan.labelEs}».',
      );
    }
    final NitrogenPassOption? s = selected;
    if (s != null) {
      if (s.plan.isAlreadyDone) {
        return const _InfoBox(
          icon: Icons.check_circle_rounded,
          color: BioGTheme.green700,
          title: 'Ya fertilicé: no queda nitrógeno por aplicar este ciclo',
          text:
              'BIO-G no te pedirá aplicar nitrógeno esta temporada ni contará '
              'ninguna ventana como «sin evidencia»; solo observa el suelo. '
              'Si vuelves a fertilizar, cámbialo aquí.',
        );
      }
      final String warn = (s.warningEs ?? '').trim();
      return _InfoBox(
        icon: Icons.check_circle_rounded,
        color: BioGTheme.green700,
        title: '${s.plan.labelEs}: ${s.helperEs}',
        text: warn.isNotEmpty
            ? warn
            : (s.recommended
                ? 'Es lo que recomienda la guía de $cropLabelEs.'
                : 'BIO-G pone el nitrógeno de la temporada en esas ventanas, '
                    'las mejores según la guía; las demás ya no cuentan como '
                    'fertilización.'),
      );
    }
    final NitrogenPassOption? r = recommended;
    if (r != null) {
      return _InfoBox(
        icon: Icons.star_rounded,
        color: BioGTheme.green700,
        title: 'La guía de $cropLabelEs recomienda ${r.plan.labelEs.toLowerCase()}',
        text: _cap(r.helperEs),
      );
    }
    return const SizedBox.shrink();
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: BioGGlassCard(
        key: ValueKey<String>('$title|$text'),
        radius: 20,
        useBackdropBlur: false,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        backgroundColor: Colors.white.withValues(alpha: 0.78),
        borderColor: color.withValues(alpha: 0.20),
        boxShadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.10),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.4,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 12.8,
                      height: 1.42,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF61717A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote({
    required this.textureKnown,
    required this.textureLabelEs,
    required this.firstTime,
  });

  final bool textureKnown;
  final String textureLabelEs;
  final bool firstTime;

  @override
  Widget build(BuildContext context) {
    final List<String> lines = <String>[
      if (textureKnown) 'Las opciones ya toman en cuenta tu $textureLabelEs.',
      firstTime
          ? 'Tu respuesta se guarda para esta temporada. La puedes cambiar '
              'cuando quieras desde el icono de ajustes de la pantalla NPK.'
          : 'El cambio aplica desde ahora a las ventanas que faltan.',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final String l in lines)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.6,
                  height: 1.45,
                  color: Colors.black.withValues(alpha: 0.44),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Botón redondo de cierre, solo cuando ya hay respuesta guardada.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.88),
          border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Icons.close_rounded,
          size: 18,
          color: Colors.black.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
