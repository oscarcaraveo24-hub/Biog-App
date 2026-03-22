// lib/widgets/environment/environment_forecast_preview_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:bio_g/models/environment_models.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

class EnvironmentForecastPreviewCard extends StatelessWidget {
  final List<EnvironmentDaily> days;
  final VoidCallback onTap;

  /// ✅ Para controlar el espacio externo (por defecto 0).
  final EdgeInsets margin;

  /// ✅ Para anular el padding default del BioGGlassCard (12,8,12,8).
  /// Si no lo pasas, usamos EdgeInsets.zero para que NO meta aire extra.
  final EdgeInsets outerPadding;

  /// ✅ Padding interno del contenido (el que tú ya tenías).
  final EdgeInsets contentPadding;

  /// ✅ Súbelo o bájalo sin tocar screen (negativo = sube)
  final double topLift;

  /// ✅ knob global para tamaño del icono por día
  final double forecastIconScale;

  const EnvironmentForecastPreviewCard({
    super.key,
    required this.days,
    required this.onTap,
    this.margin = EdgeInsets.zero,
    this.outerPadding =
        EdgeInsets.zero, // 👈 mata padding default del glasscard
    this.contentPadding = const EdgeInsets.fromLTRB(14, 12, 14, 14),
    this.topLift = 0,
    this.forecastIconScale = 2.2, // 🔥 default grande
  });

  @override
  Widget build(BuildContext context) {
    Widget card = BioGGlassCard(
      margin: margin,
      padding: outerPadding, // ✅ importantísimo
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.black.withValues(alpha:0.04),
          highlightColor: Colors.black.withValues(alpha:0.03),
          child: Padding(
            padding: contentPadding,
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Pronóstico próximos días',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0E1A16),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.black.withValues(alpha:0.35),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 👇 3 columns como antes (clamp 0..3)
                Row(
                  children: List.generate(
                    days.length.clamp(0, 3),
                    (i) => Expanded(
                      child: _DayCol(
                        day: days[i],
                        isLast: i == 2,
                        iconScale: forecastIconScale,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (topLift == 0) return card;

    return Transform.translate(offset: Offset(0, topLift), child: card);
  }
}

class _DayCol extends StatelessWidget {
  final EnvironmentDaily day;
  final bool isLast;
  final double iconScale;

  const _DayCol({
    required this.day,
    this.isLast = false,
    required this.iconScale,
  });

  String _shortDay(String s) {
    final t = s.trim().toLowerCase();
    if (t.startsWith('lunes')) return 'Lun';
    if (t.startsWith('martes')) return 'Mar';
    if (t.startsWith('miércoles') || t.startsWith('miercoles')) return 'Mié';
    if (t.startsWith('jueves')) return 'Jue';
    if (t.startsWith('viernes')) return 'Vie';
    if (t.startsWith('sábado') || t.startsWith('sabado')) return 'Sáb';
    if (t.startsWith('domingo')) return 'Dom';
    return s.length > 4 ? s.substring(0, 3) : s;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ antes tenías un hack con "Miércoles". Mejor: usa isLast.
    final rightPad = isLast ? 0.0 : 8.0;

    final iconPath = EnvironmentIconMapper.iconForCondition(day.condition);
    Transform.translate(
      offset: const Offset(0, -2), // ✅ un poco arriba (menos flat)
      child: Stack(
        alignment: Alignment.center,
        children: [
          // sombra suave
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
            child: Transform.translate(
              offset: const Offset(0, 1.2),
              child: Opacity(
                opacity: 0.20,
                child: Transform.scale(
                  scale: iconScale,
                  child: Image.asset(
                    iconPath,
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                    color: Colors.black,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // icon real
          Transform.scale(
            scale: iconScale,
            child: Image.asset(
              iconPath,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(right: rightPad),
      child: Column(
        children: [
          Text(
            _shortDay(day.dayLabel),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0E1A16),
            ),
          ),
          const SizedBox(height: 8),

          // ✅ PNG dinámico según condición (no Material icons)
          Transform.translate(
            offset: const Offset(0, -2), // 🔥 súbelo 2px
            child: Transform.scale(
              scale: iconScale,
              child: Image.asset(
                iconPath,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${day.maxC}°/${day.minC}°',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '${day.rainProbPct}% lluvia',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha:0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day.windLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha:0.55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
