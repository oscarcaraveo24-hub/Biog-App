// lib/screens/environment/environment_forecast_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bio_g/models/environment_models.dart';
import 'package:bio_g/services/environment_service.dart';
import 'package:bio_g/widgets/environment/environment_asset_icon.dart';
import 'package:bio_g/widgets/environment/environment_location_card.dart';
import 'package:bio_g/widgets/environment/environment_now_summary_card.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/screens/environment/environment_forecast_24h_screen.dart';
import 'package:bio_g/widgets/shared/bio_g_page_route.dart';

class EnvironmentForecastScreen extends StatefulWidget {
  final List<EnvironmentDaily> days;

  // ✅ header tipo mockup
  final EnvironmentLocation location;
  final EnvironmentNow now;

  final String? footerNote;

  const EnvironmentForecastScreen({
    super.key,
    required this.days,
    required this.location,
    required this.now,
    this.footerNote,
  });

  @override
  State<EnvironmentForecastScreen> createState() =>
      _EnvironmentForecastScreenState();

  // ===== knobs =====
  static const double kSide = 16;
  static const double kTopPad = 10;
  static const double kRowGap = 10;

  // ✅ clima icons: tamaño estilo mockup
  static const double kForecastIconScale = 2.15;

  // ✅ rows compactas
  static const EdgeInsets kRowPadding = EdgeInsets.fromLTRB(14, 12, 14, 12);

  // ✅ “surface” interior
  static const double kRowSurfaceOpacity = 0.78;

  // ✅ “Hoy” un poco más sólido
  static const double kTodaySurfaceOpacity = 0.92;
}

class _EnvironmentForecastScreenState extends State<EnvironmentForecastScreen>
    with SingleTickerProviderStateMixin {
  late final Future<List<EnvironmentDaily>> _futureDays7;

  late final AnimationController _listAnim;
  int _lastAnimatedCount = -1;

  @override
  void initState() {
    super.initState();

    // ✅ Esta pantalla SIEMPRE pide 7 días reales.
    _futureDays7 = _fetch7Days();

    // ✅ controlador para animación stagger de rows (cuando YA tenga data real)
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
  }

  @override
  void dispose() {
    _listAnim.dispose();
    super.dispose();
  }

  Future<List<EnvironmentDaily>> _fetch7Days() async {
    final payload = await const EnvironmentService().fetchEnvironment(
      location: widget.location,
      dailyLimit: 7,
    );
    return payload.nextDays;
  }

  void _restartListAnimIfNeeded(int count) {
    if (_lastAnimatedCount == count) return;
    _lastAnimatedCount = count;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _listAnim.stop();
      _listAnim.value = 0;
      _listAnim.forward();
    });
  }

  DateTime _dateForIndex(int i) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.add(Duration(days: i));
  }

  void _open24h(BuildContext context, DateTime selectedDate) {
    Navigator.of(context).push(
      BioGPageRoute(
        builder: (_) => EnvironmentForecast24hScreenDark(
          location: widget.location,
          selectedDate: selectedDate,
        ),
      ),
    );
  }

  String _updatedLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Actualizado hace unos segundos';
    if (diff.inMinutes < 60) return 'Actualizado hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Actualizado hace ${diff.inHours} h';
    return 'Actualizado hace ${diff.inDays} días';
  }

  String _labelForCondition(EnvCondition c) {
    switch (c) {
      case EnvCondition.sunny:
        return 'Soleado';
      case EnvCondition.night:
        return 'Despejado';
      case EnvCondition.partlyCloudy:
        return 'Parcialmente nublado';
      case EnvCondition.cloudy:
        return 'Nublado';
      case EnvCondition.fog:
        return 'Neblina';
      case EnvCondition.drizzle:
        return 'Llovizna';
      case EnvCondition.rain:
        return 'Lluvia';
      case EnvCondition.thunder:
        return 'Tormenta';
      case EnvCondition.stormStrong:
        return 'Tormenta fuerte';
      case EnvCondition.snow:
        return 'Nieve';
      case EnvCondition.frost:
        return 'Helada';
      case EnvCondition.heatwave:
        return 'Calor extremo';
      case EnvCondition.unknown:
      default:
        return 'Clima';
    }
  }

  // ✅ Subtexto “relevante del día”
  // Ejemplos:
  // - "Tormenta • 80% lluvia"
  // - "Viento fuerte • Sin lluvia"
  // - "Nublado • Viento moderado"
  String _daySummary(EnvironmentDaily d) {
    final parts = <String>[];

    // 1) Fenómeno fuerte primero
    final condLabel = _labelForCondition(d.condition);
    final condIsInteresting =
        d.condition != EnvCondition.sunny &&
        d.condition != EnvCondition.unknown;

    if (d.condition == EnvCondition.thunder ||
        d.condition == EnvCondition.stormStrong ||
        d.condition == EnvCondition.frost ||
        d.condition == EnvCondition.snow ||
        d.condition == EnvCondition.rain ||
        d.condition == EnvCondition.drizzle) {
      parts.add(condLabel);
    } else if (condIsInteresting && d.rainProbPct < 40) {
      // si no es lluvia fuerte pero está nublado/neblina, sí vale como resumen
      parts.add(condLabel);
    }

    // 2) Lluvia (si aplica)
    if (d.rainProbPct >= 40) {
      parts.add('${d.rainProbPct}% lluvia');
    } else {
      // si no hay lluvia relevante, lo declaramos al final
      // (lo ponemos después de viento para "Viento fuerte • Sin lluvia")
    }

    // 3) Viento (si aplica)
    if (d.windKmh >= 24) {
      parts.add('Viento fuerte');
    } else if (d.windKmh >= 12) {
      parts.add('Viento moderado');
    }

    // 4) Sin lluvia (si no hubo lluvia relevante)
    if (d.rainProbPct < 40) {
      parts.add('Sin lluvia');
    }

    // Si se quedó vacío (caso raro), fallback
    if (parts.isEmpty) return 'Sin lluvia';

    // Orden preferido: fenómeno → lluvia% → viento → sin lluvia
    // Ya está más o menos así; pero si quedó "Sin lluvia" al final se ve bien.
    return parts.join(' • ');
  }

  String _footerAuto(List<EnvironmentDaily> list) {
    if (list.isEmpty) return 'Mantén monitoreo del entorno.';
    final maxRain = list
        .map((e) => e.rainProbPct)
        .reduce((a, b) => a > b ? a : b);

    if (maxRain >= 80) return 'Toma precauciones si se espera\nlluvia fuerte.';
    if (maxRain >= 50) {
      return 'Atento a probabilidad de lluvia\nen próximos días.';
    }
    return 'Condiciones estables.\nMantén monitoreo y riego programado.';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _ForecastSoftBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ================= TOP BAR =================
                Padding(
                  padding: const EdgeInsets.only(
                    top: EnvironmentForecastScreen.kTopPad,
                  ),
                  child: SizedBox(
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 0,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                              color: Colors.black.withValues(alpha:0.65),
                            ),
                          ),
                        ),
                        const Center(
                          child: Text(
                            'Pronóstico',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0E1A16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: FutureBuilder<List<EnvironmentDaily>>(
                    future: _futureDays7,
                    builder: (context, snap) {
                      final isLoading =
                          snap.connectionState == ConnectionState.waiting;
                      final hasRefreshError = !isLoading && snap.hasError;

                      // ✅ FIX “3 → 7”:
                      // - Mientras carga: NO usamos widget.days (evita ver 3 y luego 7)
                      // - Mostramos skeletons (7 filas) y ya.
                      final List<EnvironmentDaily> week =
                          (!isLoading && snap.hasData)
                          ? (snap.data!.take(7).toList())
                          : hasRefreshError
                          ? widget.days.take(7).toList()
                          : const [];

                      if (week.isNotEmpty)
                        _restartListAnimIfNeeded(week.length);

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // ================= HEADER CARDS =================
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: EnvironmentForecastScreen.kSide,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  EnvironmentLocationCard(
                                    fieldLabel: widget.location.fieldName,
                                    zoneLabel: widget.location.zoneLabel,
                                    updatedLabel: _updatedLabel(
                                      widget.location.updatedAt,
                                    ),
                                    leafIconScale: 0.78,
                                    locationIconScale: 1.55,
                                  ),
                                  const SizedBox(height: 10),

                                  // ✅ Sin clip / sin “box anti-shadow”
                                  EnvironmentNowSummaryCard(
                                    condition: widget.now.condition,
                                    weatherCode: widget.now.weatherCode,
                                    observedAt: widget.now.observedAt,
                                    isDay: widget.now.isDay,
                                    precipitationMm:
                                        widget.now.precipitationMm,
                                    shortwaveRadiation:
                                        widget.now.shortwaveWm2,
                                    temperatureC: widget.now.tempC,
                                    title: widget.now.conditionLabel,
                                    subtitle: widget.now.agroNote,
                                    weatherIconScale: 3.6,
                                  ),

                                  const SizedBox(height: 14),
                                ],
                              ),
                            ),
                          ),

                          // ================= WEEK LIST =================
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: EnvironmentForecastScreen.kSide,
                            ),
                            sliver: isLoading
                                ? SliverList.separated(
                                    itemCount: 7,
                                    separatorBuilder: (_, __) => const SizedBox(
                                      height: EnvironmentForecastScreen.kRowGap,
                                    ),
                                    itemBuilder: (context, i) {
                                      return const _SkeletonDayRow();
                                    },
                                  )
                                : SliverList.separated(
                                    itemCount: week.length,
                                    separatorBuilder: (_, __) => const SizedBox(
                                      height: EnvironmentForecastScreen.kRowGap,
                                    ),
                                    itemBuilder: (context, i) {
                                      final d = week[i];
                                      final selectedDate =
                                          d.forecastDate ?? _dateForIndex(i);
                                      final iconPath =
                                          EnvironmentIconMapper.iconForDailyForecastWeather(
                                            weatherCode: d.weatherCode,
                                            day: selectedDate,
                                            fallbackCondition: d.condition,
                                            precipitationProbability:
                                                d.rainProbPct,
                                            precipitationMm:
                                                d.precipitationMm,
                                          );

                                      return _StaggerIn(
                                        controller: _listAnim,
                                        index: i,
                                        child: _DayRowCard(
                                          day: d,
                                          iconPath: iconPath,
                                          isToday: i == 0,
                                          subtitle: _daySummary(d),
                                          onTap: () =>
                                              _open24h(context, selectedDate),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // ================= FOOTER NOTE =================
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              EnvironmentForecastScreen.kSide,
                              12,
                              EnvironmentForecastScreen.kSide,
                              0,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: BioGGlassCard(
                                padding: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cloud_outlined,
                                        size: 18,
                                        color: Colors.black.withValues(alpha:0.55),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          widget.footerNote ??
                                              (hasRefreshError
                                                  ? week.isEmpty
                                                        ? 'No se pudo cargar el pronóstico. Intenta de nuevo más tarde.'
                                                        : 'No se pudo actualizar. Mostrando datos guardados.'
                                                  : week.isEmpty
                                                  ? 'No hay pronóstico disponible.'
                                                  : _footerAuto(week)),
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black.withValues(alpha:
                                              0.62,
                                            ),
                                            height: 1.15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: SizedBox(height: 28 + bottomPad),
                          ),
                        ],
                      );
                    },
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

/* ===================== ROW CARD (tap) ===================== */

class _DayRowCard extends StatelessWidget {
  final EnvironmentDaily day;
  final String iconPath;
  final String subtitle;
  final bool isToday;
  final VoidCallback onTap;

  const _DayRowCard({
    required this.day,
    required this.iconPath,
    required this.subtitle,
    required this.onTap,
    this.isToday = false,
  });

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final surfaceOpacity = isToday
        ? EnvironmentForecastScreen.kTodaySurfaceOpacity
        : EnvironmentForecastScreen.kRowSurfaceOpacity;

    return BioGGlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              color: Colors.white.withValues(alpha:surfaceOpacity),
              border: Border.all(
                color: Colors.white.withValues(alpha:isToday ? 0.75 : 0.65),
              ),
            ),
            child: Padding(
              padding: EnvironmentForecastScreen.kRowPadding,
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Center(
                      child: _ForecastIcon(
                        path: iconPath,
                        scale: EnvironmentForecastScreen.kForecastIconScale,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.dayLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0E1A16),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withValues(alpha:0.52),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${day.maxC}° / ${day.minC}°',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0E1A16),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.water_drop_outlined,
                            size: 14,
                            color: Colors.black.withValues(alpha:0.40),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${day.rainProbPct}% lluvia',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.black.withValues(alpha:0.52),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(width: 6),

                  Icon(
                    Icons.chevron_right,
                    color: Colors.black.withValues(alpha:0.30),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================== SKELETON ROW ===================== */

class _SkeletonDayRow extends StatelessWidget {
  const _SkeletonDayRow();

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          color: Colors.white.withValues(alpha:0.72),
          border: Border.all(color: Colors.white.withValues(alpha:0.65)),
        ),
        child: Padding(
          padding: EnvironmentForecastScreen.kRowPadding,
          child: Row(
            children: [
              Container(
                width: 34,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withValues(alpha:0.07),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withValues(alpha:0.07),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withValues(alpha:0.06),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    height: 12,
                    width: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withValues(alpha:0.07),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withValues(alpha:0.06),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: Colors.black.withValues(alpha:0.05),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===================== STAGGER ANIM ===================== */

class _StaggerIn extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _StaggerIn({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.08).clamp(0.0, 0.75);
    final end = (start + 0.35).clamp(0.0, 1.0);

    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (_, c) {
        final t = curved.value;
        final dy = (1 - t) * 10.0;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, dy), child: c),
        );
      },
    );
  }
}

/* ===================== ICON ===================== */

class _ForecastIcon extends StatelessWidget {
  final String path;
  final double scale;

  const _ForecastIcon({required this.path, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Transform.translate(
            offset: const Offset(0, 1.2),
            child: Opacity(
              opacity: 0.18,
              child: Transform.scale(
                scale: scale,
                child: EnvironmentAssetIcon(
                  assetPath: path,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  color: Colors.black,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        Transform.scale(
          scale: scale,
          child: EnvironmentAssetIcon(
            assetPath: path,
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

/* ===================== BACKGROUND ===================== */

class _ForecastSoftBackground extends StatelessWidget {
  const _ForecastSoftBackground();

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

/* ===================== NEXT SCREEN (placeholder) ===================== */
