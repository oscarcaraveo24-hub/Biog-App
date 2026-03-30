import 'package:flutter/material.dart';

import 'package:bio_g/screens/dashboard/dashboard_presenter.dart';
import 'package:bio_g/screens/npk/npk_screen.dart';
import 'package:bio_g/widgets/insight_card.dart';
import 'package:bio_g/widgets/metric_card.dart';
import 'package:bio_g/widgets/npk_insight_card.dart';
import 'package:bio_g/widgets/shared/bio_g_page_route.dart';
import 'package:bio_g/widgets/soil_health_ring.dart';

class DashboardBackground extends StatelessWidget {
  const DashboardBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Image.asset('assets/images/bg_sky.png', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0x00000000),
                  Color(0x55FFFFFF),
                  Color(0xCCFFFFFF),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardReveal extends StatelessWidget {
  final AnimationController controller;
  final double intervalStart;
  final double intervalEnd;
  final double yOffset;
  final double beginScale;
  final Widget child;

  const DashboardReveal({
    super.key,
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
    final CurvedAnimation positionCurve = CurvedAnimation(
      parent: controller,
      curve: Interval(intervalStart, intervalEnd, curve: _premiumCurve),
    );

    final CurvedAnimation opacityCurveAnim = CurvedAnimation(
      parent: controller,
      curve: Interval(
        intervalStart,
        intervalStart + ((intervalEnd - intervalStart) * 0.82),
        curve: _opacityCurve,
      ),
    );

    final Animation<double> opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(opacityCurveAnim);
    final Animation<double> translateY = Tween<double>(
      begin: yOffset,
      end: 0.0,
    ).animate(positionCurve);
    final Animation<double> scale = Tween<double>(
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

class DashboardHeaderSection extends StatelessWidget {
  final String cropLabel;
  final String fieldLabel;
  final String cropIconAsset;
  final bool hasNotifications;
  final VoidCallback? onNotificationTap;

  const DashboardHeaderSection({
    super.key,
    required this.cropLabel,
    required this.fieldLabel,
    required this.cropIconAsset,
    this.hasNotifications = false,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SizedBox(
            height: 100,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                Center(
                  child: Transform.scale(
                    scale: 1.5,
                    child: Image.asset(
                      'assets/images/logo_bio_g.png',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (onNotificationTap != null)
                  Positioned(
                    right: 17,
                    top: 24,
                    child: _NotificationBellButton(
                      hasNotifications: hasNotifications,
                      onTap: onNotificationTap!,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Transform.translate(
              offset: const Offset(0, -9),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Transform.scale(
                    scale: 1.7,
                    child: Image.asset(
                      cropIconAsset,
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -12),
                child: Text(
                  cropLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Transform.translate(
                offset: const Offset(-8, -12),
                child: Text(
                  fieldLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: <Shadow>[
                      Shadow(
                        blurRadius: 14,
                        color: Colors.black.withValues(alpha: 0.45),
                        offset: const Offset(0, 4),
                      ),
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black.withValues(alpha: 0.35),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DashboardSoilHealthSection extends StatelessWidget {
  final double percent;
  final String label;

  const DashboardSoilHealthSection({
    super.key,
    required this.percent,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SoilHealthRing(percent: percent, label: label);
  }
}

class DashboardNpkSection extends StatelessWidget {
  final String title;
  final String subtitle;

  const DashboardNpkSection({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      // ✅ FIX: Quitamos el SizedBox estricto de 65 de altura que cortaba los textos largos
      child: NpkInsightCard(
        assetIcon: 'assets/icons/metrics/ic_npk.png',
        title: title,
        subtitle: subtitle,
        onTap: () {
          Navigator.of(
            context,
          ).push(BioGPageRoute(builder: (_) => const NpkScreen()));
        },
      ),
    );
  }
}

class DashboardMetricsGridSection extends StatelessWidget {
  final DashboardMetricUiData moisture;
  final DashboardMetricUiData temperature;
  final DashboardMetricUiData ph;
  final DashboardMetricUiData resistance;
  final AnimationController controller;

  const DashboardMetricsGridSection({
    super.key,
    required this.moisture,
    required this.temperature,
    required this.ph,
    required this.resistance,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: DashboardReveal(
                controller: controller,
                intervalStart: 0.46,
                intervalEnd: 0.62,
                yOffset: 20,
                beginScale: 0.985,
                child: MetricCard(
                  title: moisture.title,
                  value: moisture.value,
                  status: moisture.status,
                  assetIcon: moisture.assetIcon,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardReveal(
                controller: controller,
                intervalStart: 0.52,
                intervalEnd: 0.68,
                yOffset: 20,
                beginScale: 0.985,
                child: MetricCard(
                  title: temperature.title,
                  value: temperature.value,
                  status: temperature.status,
                  assetIcon: temperature.assetIcon,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: DashboardReveal(
                controller: controller,
                intervalStart: 0.60,
                intervalEnd: 0.76,
                yOffset: 20,
                beginScale: 0.985,
                child: MetricCard(
                  title: ph.title,
                  value: ph.value,
                  status: ph.status,
                  assetIcon: ph.assetIcon,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardReveal(
                controller: controller,
                intervalStart: 0.66,
                intervalEnd: 0.84,
                yOffset: 20,
                beginScale: 0.985,
                child: MetricCard(
                  title: resistance.title,
                  value: resistance.value,
                  status: resistance.status,
                  assetIcon: resistance.assetIcon,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DashboardInsightSection extends StatelessWidget {
  final DashboardInsightUiData insight;
  const DashboardInsightSection({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      assetIcon: insight.assetIcon,
      icon: insight.icon,
      title: insight.title,
      subtitle: insight.subtitle,
      tag: insight.tag,
    );
  }
}

class _NotificationBellButton extends StatefulWidget {
  final bool hasNotifications;
  final VoidCallback onTap;

  const _NotificationBellButton({
    required this.hasNotifications,
    required this.onTap,
  });

  @override
  State<_NotificationBellButton> createState() =>
      _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<_NotificationBellButton>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0, end: 0.15), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.12), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.08), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.05), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -0.05, end: 0), weight: 1),
      ],
    ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseOpacity = Tween<double>(
      begin: 0.28,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    if (widget.hasNotifications) {
      _startShakeLoop();
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _NotificationBellButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.hasNotifications && !oldWidget.hasNotifications) {
      _startShakeLoop();
      _pulseController.repeat();
    } else if (!widget.hasNotifications && oldWidget.hasNotifications) {
      _shakeController.stop();
      _shakeController.reset();
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _startShakeLoop() {
    _shakeController.forward(from: 0).then((_) {
      if (!mounted || !widget.hasNotifications) return;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && widget.hasNotifications) _startShakeLoop();
      });
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _shakeAnimation,
          _pulseController,
        ]),
        builder: (context, child) {
          return Transform.rotate(
            angle: _shakeAnimation.value,
            child: SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Center(
                    child: Transform.scale(
                      scale: 1.9,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 12,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Opacity(
                          opacity: 0.75,
                          child: Image.asset(
                            'assets/icons/metrics/ic_notification_dashboard.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (widget.hasNotifications)
                    Positioned(
                      right: 7,
                      top: 7,
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Transform.scale(
                              scale: _pulseScale.value,
                              child: Opacity(
                                opacity: _pulseOpacity.value,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF4D4F),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D4F),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF4D4F,
                                    ).withValues(alpha: 0.45),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
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
        },
      ),
    );
  }
}
