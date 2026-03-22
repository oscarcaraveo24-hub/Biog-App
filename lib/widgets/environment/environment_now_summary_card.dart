// lib/widgets/environment/environment_now_summary_card.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bio_g/models/environment_models.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

class EnvironmentNowSummaryCard extends StatelessWidget {
  final EnvCondition condition;
  final String title;
  final String subtitle;

  /// ✅ knob para agrandar/reducir el icon sin tocar layout
  final double weatherIconScale;

  const EnvironmentNowSummaryCard({
    super.key,
    required this.condition,
    required this.title,
    required this.subtitle,
    this.weatherIconScale = 4.0, // 🔥 default grande
  });

  bool get _isNight {
    final hour = DateTime.now().hour;
    return hour < 6 || hour >= 19; // 🌙 simple por hora local
  }

  bool get _isClearLikeByTitle {
    final t = title.trim().toLowerCase();
    // ✅ detecta los copies que equivalen a "cielo despejado"
    return t == 'soleado' || t == 'despejado';
  }

  String _resolvedTitle() {
    // ✅ Si llega "Soleado", aquí lo normalizamos a "Despejado"
    if (_isClearLikeByTitle) return 'Despejado';
    return title;
  }

  String _resolvedIconPath() {
    // ✅ Para "Despejado/Soleado", usa iconos día/noche del proyecto
    if (_isClearLikeByTitle) {
      return _isNight
          ? 'assets/icons/weather/ic_weather_night.png'
          : 'assets/icons/weather/ic_weather_sunny.png';
    }

    // 🔁 Para lo demás, usa tu mapper actual
    return EnvironmentIconMapper.iconForCondition(condition);
  }

  @override
  Widget build(BuildContext context) {
    final iconPath = _resolvedIconPath();

    return BioGGlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _BigIcon(iconPath: iconPath, scale: weatherIconScale),

            // ✅ más aire icon-texto
            const SizedBox(width: 33),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _resolvedTitle(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0E1A16),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha:0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigIcon extends StatelessWidget {
  final String iconPath;
  final double scale;

  const _BigIcon({required this.iconPath, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(6, -1), // ✅ derecha + leve lift
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ✅ sombra suave (copia del icon, negro con opacidad + blur)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2.6, sigmaY: 2.6),
            child: Transform.translate(
              offset: const Offset(0, 1.4), // sombra hacia abajo
              child: Opacity(
                opacity: 0.22,
                child: Transform.scale(
                  scale: scale,
                  child: Image.asset(
                    iconPath,
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                    color: Colors.black,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // ✅ icon real encima
          Transform.scale(
            scale: scale,
            child: Image.asset(
              iconPath,
              width: 26,
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
