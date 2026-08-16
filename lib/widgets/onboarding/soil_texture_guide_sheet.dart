// lib/widgets/onboarding/soil_texture_guide_sheet.dart
//
// «Identifica tu tierra en 20 segundos» — la ayuda de tres preguntas.
//
// ─────────────────────────────────────────────────────────────────────────────
// POR QUÉ ESTO VIVE DENTRO DEL MISMO PASO
// ─────────────────────────────────────────────────────────────────────────────
//
// Es una hoja inferior interna, no una pantalla del wizard. Su progreso propio
// —«1 de 3»— NO toca el «Paso 3 de 8» del onboarding, y al cerrarla el usuario
// vuelve al carrusel exactamente donde estaba. Añadir un paso al onboarding
// para una ayuda opcional sería cobrarle al que no la necesita.
//
// ─────────────────────────────────────────────────────────────────────────────
// QUÉ ES Y QUÉ NO ES EL RESULTADO
// ─────────────────────────────────────────────────────────────────────────────
//
// Es la prueba de campo del listón, la misma que usa la extensión agrícola
// desde hace décadas: se amasa un puño de tierra húmeda y se mira qué hace.
// Es una **aproximación de campo, no una clasificación de laboratorio**, y se
// devuelve marcada como tal (`SoilTextureSource.guidedEstimate`) para que el
// historial pueda distinguirla de una declaración en firme.
//
// Por eso el texto del resultado dice «tu tierra parece», nunca «tu tierra es».

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bio_g/core/agro/water/soil_water_scale.dart';
import 'package:bio_g/theme/bio_g_theme.dart';
import 'package:bio_g/widgets/shared/bio_g_button.dart';

/// Abre la guía. Devuelve la textura estimada, o `null` si el usuario cerró sin
/// terminar: en ese caso el carrusel no se mueve.
Future<SoilTexture?> showSoilTextureGuideSheet(BuildContext context) {
  return showModalBottomSheet<SoilTexture>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.34),
    builder: (_) => const _SoilTextureGuideSheet(),
  );
}

// ── El modelo de la prueba ───────────────────────────────────────────────────

enum _GritAnswer { gritty, balanced, sticky }

enum _BallAnswer { crumbles, breaksEasily, holds }

enum _RibbonAnswer { none, short, long }

/// Tabla de decisión de la prueba del listón. No es una media ponderada: es la
/// misma cascada que usa la clave de campo estándar, donde el listón manda y la
/// sensación al tacto solo desempata.
SoilTexture _classify(_GritAnswer grit, _BallAnswer ball, _RibbonAnswer ribbon) {
  // Sin listón: hay poca arcilla. Lo que separa arenosa de franco-arenosa es si
  // la bolita llega siquiera a formarse.
  if (ribbon == _RibbonAnswer.none) {
    if (ball == _BallAnswer.crumbles) return SoilTexture.sandy;
    if (ball == _BallAnswer.holds && grit != _GritAnswer.gritty) {
      return SoilTexture.loam;
    }
    return SoilTexture.sandyLoam;
  }

  // Listón corto: familia franca. El tacto decide hacia qué lado.
  if (ribbon == _RibbonAnswer.short) {
    if (grit == _GritAnswer.gritty) return SoilTexture.sandyLoam;
    if (grit == _GritAnswer.sticky) return SoilTexture.clayLoam;
    return SoilTexture.loam;
  }

  // Listón largo y resistente: hay arcilla de sobra. Solo queda cuánta.
  if (grit == _GritAnswer.sticky) return SoilTexture.clay;
  if (grit == _GritAnswer.gritty) return SoilTexture.clayLoam;
  return ball == _BallAnswer.holds ? SoilTexture.clay : SoilTexture.clayLoam;
}

class _SoilTextureGuideSheet extends StatefulWidget {
  const _SoilTextureGuideSheet();

  @override
  State<_SoilTextureGuideSheet> createState() => _SoilTextureGuideSheetState();
}

class _SoilTextureGuideSheetState extends State<_SoilTextureGuideSheet> {
  int _step = 0;
  _GritAnswer? _grit;
  _BallAnswer? _ball;
  _RibbonAnswer? _ribbon;

  SoilTexture? get _result {
    final g = _grit;
    final b = _ball;
    final r = _ribbon;
    if (g == null || b == null || r == null) return null;
    return _classify(g, b, r);
  }

  void _advance() {
    HapticFeedback.selectionClick();
    if (_step < 3) setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.86),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFBFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              _Header(step: _step, onBack: _back),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildStep(),
                  ),
                ),
              ),
              if (_step == 3) _buildResultCta(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _Question<_GritAnswer>(
          key: const ValueKey<int>(0),
          title: 'Al frotarla húmeda entre los dedos, ¿cómo se siente?',
          help: 'Toma un puño de tierra, humedécela un poco y frótala.',
          value: _grit,
          options: const <_Option<_GritAnswer>>[
            _Option(
              value: _GritAnswer.gritty,
              label: 'Muy granulada',
              detail: 'Se sienten los granos, como arena.',
              icon: Icons.grain_rounded,
            ),
            _Option(
              value: _GritAnswer.balanced,
              label: 'Equilibrada',
              detail: 'Ni granulada ni pegajosa.',
              icon: Icons.blur_circular_rounded,
            ),
            _Option(
              value: _GritAnswer.sticky,
              label: 'Muy fina y pegajosa',
              detail: 'Se pega a los dedos y mancha.',
              icon: Icons.water_drop_outlined,
            ),
          ],
          onSelected: (v) {
            setState(() => _grit = v);
            _advance();
          },
        );
      case 1:
        return _Question<_BallAnswer>(
          key: const ValueKey<int>(1),
          title: 'Si haces una bolita, ¿qué pasa?',
          help: 'Apriétala en la palma y abre la mano.',
          value: _ball,
          options: const <_Option<_BallAnswer>>[
            _Option(
              value: _BallAnswer.crumbles,
              label: 'Se deshace',
              detail: 'No llega a formarse.',
              icon: Icons.scatter_plot_rounded,
            ),
            _Option(
              value: _BallAnswer.breaksEasily,
              label: 'Se forma pero rompe fácil',
              detail: 'Aguanta un momento y cede.',
              icon: Icons.circle_outlined,
            ),
            _Option(
              value: _BallAnswer.holds,
              label: 'Mantiene muy bien la forma',
              detail: 'Queda firme y se puede alisar.',
              icon: Icons.circle_rounded,
            ),
          ],
          onSelected: (v) {
            setState(() => _ball = v);
            _advance();
          },
        );
      case 2:
        return _Question<_RibbonAnswer>(
          key: const ValueKey<int>(2),
          title: 'Al presionarla entre pulgar e índice, ¿forma una tira?',
          help: 'Empuja la tierra hacia arriba con el pulgar, poco a poco.',
          value: _ribbon,
          options: const <_Option<_RibbonAnswer>>[
            _Option(
              value: _RibbonAnswer.none,
              label: 'No',
              detail: 'Se rompe antes de estirarse.',
              icon: Icons.remove_rounded,
            ),
            _Option(
              value: _RibbonAnswer.short,
              label: 'Corta',
              detail: 'Sale una tira de un par de centímetros.',
              icon: Icons.horizontal_rule_rounded,
            ),
            _Option(
              value: _RibbonAnswer.long,
              label: 'Larga y resistente',
              detail: 'Se estira bastante sin romperse.',
              icon: Icons.linear_scale_rounded,
            ),
          ],
          onSelected: (v) {
            setState(() => _ribbon = v);
            _advance();
          },
        );
      default:
        return _Result(key: const ValueKey<int>(3), texture: _result);
    }
  }

  Widget _buildResultCta() {
    final result = _result;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
      child: Column(
        children: <Widget>[
          BioGButton(
            label: 'Usar esta textura',
            height: 52,
            radius: 18,
            onTap: result == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(result);
                  },
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              setState(() {
                _step = 0;
                _grit = null;
                _ball = null;
                _ribbon = null;
              });
            },
            child: const Text(
              'Volver a empezar',
              style: TextStyle(
                fontSize: 13.4,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A9399),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isResult = step >= 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            iconSize: 22,
            tooltip: 'Atrás',
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF6D757A),
            ),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                const Text(
                  'Identifica tu tierra',
                  style: TextStyle(
                    fontSize: 15.4,
                    fontWeight: FontWeight.w700,
                    color: BioGTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Progreso INTERNO. No es el «Paso 3 de 8» del onboarding y
                  // no debe parecerlo.
                  isResult ? 'Resultado' : '${step + 1} de 3',
                  style: TextStyle(
                    fontSize: 11.6,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.36),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            iconSize: 22,
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close_rounded, color: Color(0xFF6D757A)),
          ),
        ],
      ),
    );
  }
}

class _Option<T> {
  const _Option({
    required this.value,
    required this.label,
    required this.detail,
    required this.icon,
  });

  final T value;
  final String label;
  final String detail;
  final IconData icon;
}

class _Question<T> extends StatelessWidget {
  const _Question({
    super.key,
    required this.title,
    required this.help,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final String help;
  final T? value;
  final List<_Option<T>> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18.4,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: BioGTheme.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          help,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.8,
            height: 1.35,
            color: Colors.black.withValues(alpha: 0.42),
          ),
        ),
        const SizedBox(height: 18),
        ...options.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionTile<T>(
              option: o,
              selected: value == o.value,
              onTap: () => onSelected(o.value),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _Option<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.label}. ${option.detail}',
      excludeSemantics: true,
      child: Material(
        color: selected ? BioGTheme.green200.withValues(alpha: 0.9) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? BioGTheme.green800.withValues(alpha: 0.55)
                    : Colors.black.withValues(alpha: 0.06),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : const Color(0xFFF2F5F3),
                  ),
                  child: Icon(
                    option.icon,
                    size: 19,
                    color: selected
                        ? BioGTheme.green700
                        : const Color(0xFF7C8A8E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 14.4,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? BioGTheme.green700
                              : BioGTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.detail,
                        style: TextStyle(
                          fontSize: 11.8,
                          height: 1.3,
                          color: Colors.black.withValues(alpha: 0.42),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: BioGTheme.green700,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({super.key, required this.texture});

  final SoilTexture? texture;

  @override
  Widget build(BuildContext context) {
    final t = texture;
    if (t == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: <Widget>[
        const SizedBox(height: 4),
        Image.asset(
          t.assetPath,
          width: 128,
          height: 128,
          cacheWidth: 320,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(height: 128),
        ),
        const SizedBox(height: 12),
        Text(
          // «Parece», no «es». La guía es una aproximación de campo y el texto
          // no puede sugerir certeza de laboratorio.
          //
          // En minúscula porque aquí el nombre va DENTRO de una frase.
          // `displayNameEs` está capitalizado para usarse suelto, como rótulo, y
          // pegarlo tal cual daba «Tu tierra parece Franco-arenosa».
          'Tu tierra parece ${t.displayNameEs.toLowerCase()}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: BioGTheme.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: BioGTheme.green200.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            t.shortLabelEs,
            style: const TextStyle(
              fontSize: 12.6,
              fontWeight: FontWeight.w700,
              color: BioGTheme.green700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.touch_app_outlined,
              size: 15,
              color: Colors.black.withValues(alpha: 0.36),
            ),
            const SizedBox(width: 6),
            Text(
              'Estimación por tacto',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.40),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            t.fieldHintEs,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
