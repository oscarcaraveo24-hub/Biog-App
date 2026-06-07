// lib/screens/environment/environment_forecast_24h_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bio_g/models/environment_models.dart';
import 'package:bio_g/services/environment_service.dart';
import 'package:bio_g/widgets/environment/environment_asset_icon.dart';
import 'package:bio_g/widgets/environment/environment_location_card.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/widgets/shared/connectivity_banner.dart';

class EnvironmentForecast24hScreenDark extends StatefulWidget {
  final EnvironmentLocation location;
  final DateTime selectedDate;

  const EnvironmentForecast24hScreenDark({
    super.key,
    required this.location,
    required this.selectedDate,
  });

  @override
  State<EnvironmentForecast24hScreenDark> createState() =>
      _EnvironmentForecast24hScreenDarkState();
}

class _EnvironmentForecast24hScreenDarkState
    extends State<EnvironmentForecast24hScreenDark>
    with SingleTickerProviderStateMixin {
  late Future<List<_HourRow>> _future;
  final ScrollController _scroll = ScrollController();

  // ===== knobs (match ForecastScreen) =====
  static const double kSide = 16;
  static const double kTopPad = 10;
  static const double kRowGap = 10;

  static const double kForecastIconScale = 3.3;
  static const EdgeInsets kRowPadding = EdgeInsets.fromLTRB(14, 10, 14, 10);

  static const double kRowSurfaceOpacity = 0.78;
  static const double kNowSurfaceOpacity = 0.92;

  // para jump inicial (aprox)
  static const double _rowApproxHeight = 76;

  late final AnimationController _listAnim;
  int _lastAnimatedCount = -1;

  @override
  void initState() {
    super.initState();
    _future = _load();

    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _listAnim.dispose();
    super.dispose();
  }

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ✅ regla simple de noche (ajústala si quieres)
  bool _isNightHour(DateTime dt) {
    final h = dt.hour;
    return h < 6 || h >= 19;
  }

  String _dayName(DateTime dt) {
    const names = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return names[(dt.weekday - 1).clamp(0, 6)];
  }

  String _titleDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final iso = '$y-$m-$day';

    final today = _isSameDay(d, DateTime.now());
    return today ? 'Hoy • $iso' : '${_dayName(d)} • $iso';
  }

  String _hourLabel(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:00';

  Future<List<_HourRow>> _load() async {
    final raw = await const EnvironmentService().fetchHourly24h(
      location: widget.location,
      day: widget.selectedDate,
    );

    final selectedStart = _dayStart(widget.selectedDate);

    // Convertimos + filtramos: ✅ SOLO horas del mismo día (0–23)
    final rows = <_HourRow>[];
    for (final m in raw) {
      final iso = (m['timeIso'] ?? '').toString();
      final dt = DateTime.tryParse(iso);
      if (dt == null) continue;

      // ✅ filtro duro (evita que se cuele el día siguiente)
      if (!_isSameDay(dt, selectedStart)) continue;

      final temp = (m['tempC'] as num?)?.toDouble() ?? 0;
      final wind = (m['windKmh'] as num?)?.toDouble() ?? 0;
      final pop = (m['rainProbPct'] as int?) ?? 0;
      final precipitation = (m['precipitationMm'] as num?)?.toDouble();
      final weatherCode = (m['weatherCode'] as int?) ?? 0;
      final isDay = m['isDay'] as bool?;

      final cond = m['condition'] is EnvCondition
          ? (m['condition'] as EnvCondition)
          : EnvCondition.unknown;

      rows.add(
        _HourRow(
          time: dt,
          tempC: temp,
          windKmh: wind,
          rainProbPct: pop.clamp(0, 100),
          precipitationMm: precipitation,
          weatherCode: weatherCode,
          isDay: isDay,
          condition: cond,
        ),
      );
    }

    // orden por hora
    rows.sort((a, b) => a.time.compareTo(b.time));

    // ✅ animación cuando ya hay data
    if (rows.isNotEmpty) _restartListAnimIfNeeded(rows.length);

    // ✅ si es HOY: auto-scroll 4 horas atrás
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final isToday = _isSameDay(selectedStart, DateTime.now());
      if (!isToday || rows.isEmpty) return;

      final now = DateTime.now();
      final nowHour = DateTime(now.year, now.month, now.day, now.hour);

      int idx = rows.indexWhere(
        (r) =>
            r.time.year == nowHour.year &&
            r.time.month == nowHour.month &&
            r.time.day == nowHour.day &&
            r.time.hour == nowHour.hour,
      );
      if (idx < 0) idx = 0;

      final target = (idx - 4).clamp(0, rows.length - 1);
      final offset = target * _rowApproxHeight;

      if (_scroll.hasClients) {
        _scroll.jumpTo(offset.clamp(0.0, _scroll.position.maxScrollExtent));
      }
    });

    return rows;
  }

  void _retry() {
    setState(() {
      _future = _load();
    });
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

  String _condLabel(EnvCondition c) {
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

  // ✅ resumen por hora (mejorado):
  // - Si es soleado y no llueve, ya NO queda solo "Sin lluvia"
  // - Ahora muestra "Soleado • Sin lluvia" (o "Despejado • Sin lluvia" de noche)
  String _summaryForHour(_HourRow r) {
    final parts = <String>[];

    final isNight = _isNightHour(r.time);

    // 1) Condición (siempre para evitar “Sin lluvia” repetitivo)
    if (r.condition == EnvCondition.sunny) {
      parts.add(isNight ? 'Despejado' : 'Soleado');
    } else if (r.condition != EnvCondition.unknown) {
      parts.add(_condLabel(r.condition));
    }

    // 2) Lluvia
    if (r.rainProbPct >= 40) {
      parts.add('${r.rainProbPct}% lluvia');
    } else {
      parts.add('Sin lluvia');
    }

    // 3) Viento
    if (r.windKmh >= 24) {
      parts.add('Viento fuerte');
    } else if (r.windKmh >= 12) {
      parts.add('Viento moderado');
    }

    // Fallback por si algo raro viniera vacío
    if (parts.isEmpty) return 'Sin lluvia';

    return parts.join(' • ');
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
                  padding: const EdgeInsets.only(top: kTopPad),
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
                              color: Colors.black.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                        const Center(
                          child: Text(
                            '24 horas',
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
                  child: FutureBuilder<List<_HourRow>>(
                    future: _future,
                    builder: (context, snap) {
                      final isLoading =
                          snap.connectionState == ConnectionState.waiting;

                      if (!isLoading && snap.hasError) {
                        return BioGErrorState(
                          message:
                              'No se pudo cargar el pronóstico por hora. Intenta de nuevo.',
                          onRetry: _retry,
                        );
                      }

                      final rows = (!isLoading && snap.hasData)
                          ? snap.data!
                          : const <_HourRow>[];

                      if (!isLoading && rows.isEmpty) {
                        return BioGErrorState(
                          message:
                              'No hay datos disponibles para este día. Intenta de nuevo.',
                          onRetry: _retry,
                        );
                      }

                      return CustomScrollView(
                        controller: _scroll,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // ================= HEADER =================
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSide,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  EnvironmentLocationCard(
                                    fieldLabel: widget.location.fieldName,
                                    zoneLabel: widget.location.zoneLabel,
                                    updatedLabel: _titleDate(
                                      widget.selectedDate,
                                    ),
                                    leafIconScale: 0.78,
                                    locationIconScale: 1.55,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              ),
                            ),
                          ),

                          // ================= LIST =================
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSide,
                            ),
                            sliver: isLoading
                                ? SliverList.separated(
                                    itemCount: 10,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: kRowGap),
                                    itemBuilder: (_, __) =>
                                        const _SkeletonHourRow(),
                                  )
                                : SliverList.separated(
                                    itemCount: rows.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: kRowGap),
                                    itemBuilder: (context, i) {
                                      final r = rows[i];

                                      final now = DateTime.now();
                                      final isToday = _isSameDay(
                                        _dayStart(widget.selectedDate),
                                        _dayStart(now),
                                      );
                                      final isNowHour =
                                          isToday &&
                                          r.time.year == now.year &&
                                          r.time.month == now.month &&
                                          r.time.day == now.day &&
                                          r.time.hour == now.hour;

                                      final iconPath =
                                          EnvironmentIconMapper.iconForForecastWeather(
                                            weatherCode: r.weatherCode,
                                            time: r.time,
                                            fallbackCondition: r.condition,
                                            isDay: r.isDay,
                                            precipitationProbability:
                                                r.rainProbPct,
                                            precipitationMm: r.precipitationMm,
                                          );

                                      return _StaggerIn(
                                        controller: _listAnim,
                                        index: i,
                                        child: _HourRowCard(
                                          timeLabel: _hourLabel(r.time),
                                          iconPath: iconPath,
                                          tempLabel: '${r.tempC.round()}°',
                                          subtitle: _summaryForHour(r),
                                          rainProbPct: r.rainProbPct,
                                          windKmh: r.windKmh,
                                          highlight: isNowHour,
                                        ),
                                      );
                                    },
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

/* ===================== DATA MODEL (LOCAL UI) ===================== */

class _HourRow {
  final DateTime time;
  final double tempC;
  final double windKmh;
  final int rainProbPct;
  final double? precipitationMm;
  final int weatherCode;
  final bool? isDay;
  final EnvCondition condition;

  const _HourRow({
    required this.time,
    required this.tempC,
    required this.windKmh,
    required this.rainProbPct,
    required this.precipitationMm,
    required this.weatherCode,
    required this.isDay,
    required this.condition,
  });
}

/* ===================== ROW CARD ===================== */

class _HourRowCard extends StatelessWidget {
  final String timeLabel;
  final String iconPath;
  final String tempLabel;
  final String subtitle;
  final int rainProbPct;
  final double windKmh;
  final bool highlight;

  const _HourRowCard({
    required this.timeLabel,
    required this.iconPath,
    required this.tempLabel,
    required this.subtitle,
    required this.rainProbPct,
    required this.windKmh,
    required this.highlight,
  });

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final surfaceOpacity = highlight
        ? _EnvironmentForecast24hScreenDarkState.kNowSurfaceOpacity
        : _EnvironmentForecast24hScreenDarkState.kRowSurfaceOpacity;

    return BioGGlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          color: Colors.white.withValues(alpha: surfaceOpacity),
          border: Border.all(
            color: Colors.white.withValues(alpha: highlight ? 0.75 : 0.65),
          ),
        ),
        child: Padding(
          padding: _EnvironmentForecast24hScreenDarkState.kRowPadding,
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0E1A16),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              SizedBox(
                width: 36,
                child: Center(
                  child: _ForecastIcon(
                    path: iconPath,
                    scale: _EnvironmentForecast24hScreenDarkState
                        .kForecastIconScale,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tempLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0E1A16),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha: 0.52),
                        height: 1.10,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        size: 14,
                        color: Colors.black.withValues(alpha: 0.40),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$rainProbPct%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withValues(alpha: 0.52),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${windKmh.round()} km/h',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===================== SKELETON ===================== */

class _SkeletonHourRow extends StatelessWidget {
  const _SkeletonHourRow();

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          color: Colors.white.withValues(alpha: 0.72),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        ),
        child: Padding(
          padding: _EnvironmentForecast24hScreenDarkState.kRowPadding,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withValues(alpha: 0.07),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withValues(alpha: 0.07),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 190,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withValues(alpha: 0.06),
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
                    height: 10,
                    width: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withValues(alpha: 0.07),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ],
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
    final start = (index * 0.06).clamp(0.0, 0.75);
    final end = (start + 0.35).clamp(0.0, 1.0);

    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

    return FadeTransition(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (_, c) {
          final dy = (1 - curved.value) * 10.0;
          return Transform.translate(offset: Offset(0, dy), child: c);
        },
      ),
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

/* ===================== BACKGROUND (match) ===================== */

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
          color: _brandMid.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
