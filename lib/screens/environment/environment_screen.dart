import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bio_g/models/environment_models.dart';
import 'package:bio_g/screens/environment/environment_forecast_screen.dart';
import 'package:bio_g/services/environment_service.dart';
import 'package:bio_g/widgets/bottom_nav.dart';
import 'package:bio_g/widgets/environment/environment_forecast_preview_card.dart';
import 'package:bio_g/widgets/environment/environment_insight_card.dart';
import 'package:bio_g/widgets/environment/environment_location_card.dart';
import 'package:bio_g/widgets/environment/environment_metric_tile.dart';
import 'package:bio_g/widgets/environment/environment_now_summary_card.dart';
import 'package:bio_g/widgets/shared/bio_g_page_route.dart';
import 'package:bio_g/widgets/shared/connectivity_banner.dart';

class EnvironmentScreen extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavTap;

  const EnvironmentScreen({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
  });

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen>
    with SingleTickerProviderStateMixin {
  static const int _environmentTabIndex = 3;

  /// Vive solo mientras la app sigue abierta.
  static bool _hasAnimatedThisSession = false;

  static const String _kPrefLocLabel = 'profile_location_label';
  static const String _kPrefLocLat = 'profile_location_lat';
  static const String _kPrefLocLng = 'profile_location_lng';

  static const double _kDefLat = 25.7913; // Los Mochis
  static const double _kDefLng = -108.9859;

  final EnvironmentService _service = const EnvironmentService();

  bool _loading = true;
  String? _error;
  late EnvironmentPayload _payload;

  Timer? _autoRefreshTimer;
  late final AnimationController _entranceController;

  // =========================================================
  // ✅ KNOBS UI
  // =========================================================
  static const double kSide = 16;
  static const double kTopPad = 10;
  static const double kGap = 12;

  static const double kGridMainGap = 14;
  static const double kGridCrossGap = 14;
  static const double kGridAspect = 1.08;

  static const double kBetweenCards = 10;

  static const double kAssetIconScale = 4.5;
  static const double kMaterialIconScale = 1.0;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1260),
      value: _hasAnimatedThisSession ? 1.0 : 0.0,
    );

    _bootstrap();

    _autoRefreshTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _bootstrap(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final bool isActiveNow = widget.currentIndex == _environmentTabIndex;

      if (isActiveNow && !_hasAnimatedThisSession) {
        _entranceController.forward(from: 0);
        _hasAnimatedThisSession = true;
      }
    });
  }

  @override
  void didUpdateWidget(covariant EnvironmentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool wasActiveBefore = oldWidget.currentIndex == _environmentTabIndex;
    final bool isActiveNow = widget.currentIndex == _environmentTabIndex;

    if (!wasActiveBefore && isActiveNow && !_hasAnimatedThisSession) {
      _entranceController
        ..stop()
        ..reset();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _entranceController.forward(from: 0);
        _hasAnimatedThisSession = true;
      });
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final label = (prefs.getString(_kPrefLocLabel) ?? 'Los Mochis, Sinaloa')
          .trim();
      final lat = prefs.getDouble(_kPrefLocLat) ?? _kDefLat;
      final lon = prefs.getDouble(_kPrefLocLng) ?? _kDefLng;

      final location = EnvironmentLocation(
        fieldName: 'Bio-G Field #001',
        zoneLabel: label.isEmpty ? 'Ubicación seleccionada' : label,
        updatedAt: DateTime.now(),
        lat: lat,
        lon: lon,
      );

      final data = await _service.fetchEnvironment(location: location);

      if (!mounted) return;
      setState(() {
        _payload = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el clima. Revisa conexión.';
        _loading = false;
      });
    }
  }

  String _updatedLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Actualizado hace unos segundos';
    if (diff.inMinutes < 60) return 'Actualizado hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Actualizado hace ${diff.inHours} h';
    return 'Actualizado hace ${diff.inDays} días';
  }

  Color _chipOk() => const Color(0xFFDCEFE2);
  Color _chipWarn() => const Color(0xFFFFE9C1);

  String _tempChip(double t) =>
      (t < 7 || t > 33) ? (t < 7 ? 'Baja' : 'Alta') : 'Óptima';
  Color _tempChipColor(double t) => (t < 7 || t > 33) ? _chipWarn() : _chipOk();

  String _humidityChip(int h) {
    if (h < 25) return 'Baja';
    if (h < 60) return 'Media';
    return 'Alta';
  }

  Color _humidityChipColor(int h) => (h < 25) ? _chipWarn() : _chipOk();

  String _windChip(double w) {
    if (w < 12) return 'Suave';
    if (w < 24) return 'Moderado';
    return 'Fuerte';
  }

  Color _windChipColor(double w) => (w >= 24) ? _chipWarn() : _chipOk();

  String _solarLabel(double? wm2) {
    if (wm2 == null) return 'Óptima';
    if (wm2 < 150) return 'Baja';
    if (wm2 < 700) return 'Óptima';
    return 'Alta';
  }

  Color _solarChipColor(double? wm2) {
    if (wm2 == null) return _chipOk();
    if (wm2 < 150 || wm2 > 900) return _chipWarn();
    return _chipOk();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: BioGBottomNav(
        currentIndex: widget.currentIndex,
        onTap: widget.onNavTap,
      ),
      body: ConnectivityBanner(
        child: Stack(
          children: [
            const _EnvironmentSoftBackground(),
            SafeArea(
              top: true,
              bottom: false,
              child: _loading
                  ? const _LoadingBody()
                  : (_error != null)
                  ? BioGErrorState(message: _error!, onRetry: _bootstrap)
                  : RefreshIndicator(
                    onRefresh: _bootstrap,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _EnvironmentReveal(
                            controller: _entranceController,
                            intervalStart: 0.00,
                            intervalEnd: 0.14,
                            yOffset: 14,
                            beginScale: 0.992,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                kSide,
                                kTopPad,
                                kSide,
                                10,
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Entorno',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.2,
                                        color: Color(0xFF0E1A16),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _bootstrap,
                                    icon: Icon(
                                      Icons.refresh,
                                      size: 20,
                                      color: Colors.black.withValues(alpha:0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kSide,
                            ),
                            child: Column(
                              children: [
                                _EnvironmentReveal(
                                  controller: _entranceController,
                                  intervalStart: 0.08,
                                  intervalEnd: 0.24,
                                  yOffset: 16,
                                  beginScale: 0.986,
                                  child: EnvironmentLocationCard(
                                    fieldLabel: _payload.location.fieldName,
                                    zoneLabel: _payload.location.zoneLabel,
                                    updatedLabel: _updatedLabel(
                                      _payload.location.updatedAt,
                                    ),
                                    leafIconScale: 0.78,
                                    locationIconScale: 1.65,
                                  ),
                                ),
                                const SizedBox(height: kGap),
                                _EnvironmentReveal(
                                  controller: _entranceController,
                                  intervalStart: 0.16,
                                  intervalEnd: 0.32,
                                  yOffset: 16,
                                  beginScale: 0.987,
                                  child: EnvironmentNowSummaryCard(
                                    condition: _payload.now.condition,
                                    title: _payload.now.conditionLabel,
                                    subtitle: _payload.now.agroNote,
                                  ),
                                ),
                                const SizedBox(height: kGap),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  primary: false,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: kGridMainGap,
                                  crossAxisSpacing: kGridCrossGap,
                                  childAspectRatio: kGridAspect,
                                  children: [
                                    _EnvironmentReveal(
                                      controller: _entranceController,
                                      intervalStart: 0.30,
                                      intervalEnd: 0.46,
                                      yOffset: 18,
                                      beginScale: 0.986,
                                      child: EnvironmentMetricTile(
                                        assetPath:
                                            'assets/icons/metrics/ic_temperature.png',
                                        iconScale: kAssetIconScale,
                                        title: 'Temperatura',
                                        value:
                                            '${_payload.now.tempC.round()}°C',
                                        chip: _tempChip(_payload.now.tempC),
                                        chipColor: _tempChipColor(
                                          _payload.now.tempC,
                                        ),
                                        footer:
                                            'Influye en crecimiento\ndel cultivo',
                                        contentPadding:
                                            const EdgeInsets.fromLTRB(
                                              14,
                                              12,
                                              14,
                                              12,
                                            ),
                                      ),
                                    ),
                                    _EnvironmentReveal(
                                      controller: _entranceController,
                                      intervalStart: 0.36,
                                      intervalEnd: 0.52,
                                      yOffset: 18,
                                      beginScale: 0.986,
                                      child: EnvironmentMetricTile(
                                        assetPath:
                                            'assets/icons/metrics/ic_moisture.png',
                                        iconScale: kAssetIconScale,
                                        title: 'Humedad del aire',
                                        value: '${_payload.now.humidityPct} %',
                                        chip: _humidityChip(
                                          _payload.now.humidityPct,
                                        ),
                                        chipColor: _humidityChipColor(
                                          _payload.now.humidityPct,
                                        ),
                                        footer: 'Afecta la transpiración',
                                        contentPadding:
                                            const EdgeInsets.fromLTRB(
                                              18,
                                              12,
                                              12,
                                              12,
                                            ),
                                      ),
                                    ),
                                    _EnvironmentReveal(
                                      controller: _entranceController,
                                      intervalStart: 0.42,
                                      intervalEnd: 0.58,
                                      yOffset: 18,
                                      beginScale: 0.986,
                                      child: EnvironmentMetricTile(
                                        assetPath:
                                            'assets/icons/weather/ic_solar_uv.png',
                                        iconScale: kAssetIconScale,
                                        title: 'Radiación solar',
                                        value: _solarLabel(
                                          _payload.now.shortwaveWm2,
                                        ),
                                        chip: _solarLabel(
                                          _payload.now.shortwaveWm2,
                                        ),
                                        chipColor: _solarChipColor(
                                          _payload.now.shortwaveWm2,
                                        ),
                                        footer: 'Clave para fotosíntesis',
                                      ),
                                    ),
                                    _EnvironmentReveal(
                                      controller: _entranceController,
                                      intervalStart: 0.48,
                                      intervalEnd: 0.64,
                                      yOffset: 18,
                                      beginScale: 0.986,
                                      child: EnvironmentMetricTile(
                                        assetPath:
                                            'assets/icons/weather/ic_wind.png',
                                        iconScale: kAssetIconScale,
                                        title: 'Viento',
                                        value:
                                            '${_payload.now.windKmh.round()} km/h',
                                        chip: _windChip(_payload.now.windKmh),
                                        chipColor: _windChipColor(
                                          _payload.now.windKmh,
                                        ),
                                        footer: 'Impacta evapotranspiración',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: kBetweenCards),
                                _EnvironmentReveal(
                                  controller: _entranceController,
                                  intervalStart: 0.62,
                                  intervalEnd: 0.80,
                                  yOffset: 18,
                                  beginScale: 0.985,
                                  child: EnvironmentForecastPreviewCard(
                                    days: _payload.nextDays,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        BioGPageRoute(
                                          builder: (_) =>
                                              EnvironmentForecastScreen(
                                                days: _payload.nextDays,
                                                location: _payload.location,
                                                now: _payload.now,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: kBetweenCards),
                                _EnvironmentReveal(
                                  controller: _entranceController,
                                  intervalStart: 0.74,
                                  intervalEnd: 0.96,
                                  yOffset: 18,
                                  beginScale: 0.985,
                                  child: EnvironmentInsightCard(
                                    text: _payload.insight.text,
                                    level: _payload.insight.level,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: 140 + bottomPad),
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

class _EnvironmentReveal extends StatelessWidget {
  final AnimationController controller;
  final double intervalStart;
  final double intervalEnd;
  final double yOffset;
  final double beginScale;
  final Widget child;

  const _EnvironmentReveal({
    required this.controller,
    required this.intervalStart,
    required this.intervalEnd,
    required this.child,
    this.yOffset = 18,
    this.beginScale = 0.986,
  });

  static const Curve _premiumCurve = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Curve _opacityCurve = Cubic(0.18, 0.84, 0.24, 1.0);

  @override
  Widget build(BuildContext context) {
    final positionCurve = CurvedAnimation(
      parent: controller,
      curve: Interval(intervalStart, intervalEnd, curve: _premiumCurve),
    );

    final opacityCurveAnim = CurvedAnimation(
      parent: controller,
      curve: Interval(
        intervalStart,
        intervalStart + ((intervalEnd - intervalStart) * 0.82),
        curve: _opacityCurve,
      ),
    );

    final opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(opacityCurveAnim);

    final translateY = Tween<double>(
      begin: yOffset,
      end: 0.0,
    ).animate(positionCurve);

    final scale = Tween<double>(
      begin: beginScale,
      end: 1.0,
    ).animate(positionCurve);

    return FadeTransition(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, translateY.value),
            child: Transform.scale(
              scale: scale.value,
              alignment: Alignment.topCenter,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/* ===================== BACKGROUND ===================== */

class _EnvironmentSoftBackground extends StatelessWidget {
  const _EnvironmentSoftBackground();

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

/* ===================== LOADING / ERROR ===================== */

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 38,
        height: 38,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            const Color(0xFF3FAF6E).withValues(alpha:0.9),
          ),
        ),
      ),
    );
  }
}

