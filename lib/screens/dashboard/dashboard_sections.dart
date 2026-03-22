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

  const DashboardHeaderSection({
    super.key,
    required this.cropLabel,
    required this.fieldLabel,
    required this.cropIconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ClipRect(
            child: Align(
              alignment: Alignment.center,
              widthFactor: 0.60,
              heightFactor: 0.60,
              child: Image.asset(
                'assets/images/logo_bio_g.png',
                height: 150,
                fit: BoxFit.contain,
              ),
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
      child: SizedBox(
        height: 65,
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
