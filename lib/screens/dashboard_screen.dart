import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/seasonal_bulb/seasonal_bulb_crops.dart';
import 'package:bio_g/core/crops/annual_ornamental/annual_ornamental_crops.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/features/reporting/pdf_preview_screen.dart';
import 'package:bio_g/features/reporting/pdf_report_builder.dart';
import 'package:bio_g/features/reporting/quick_report_builder.dart';
import 'package:bio_g/screens/dashboard/dashboard_presenter.dart';
import 'package:bio_g/screens/dashboard/dashboard_sections.dart';
import 'package:bio_g/screens/notifications_screen.dart';
import 'package:bio_g/screens/plant_health/crop_risk_intro_screen.dart';
import 'package:bio_g/screens/yield/yield_projection_setup_screen.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/bottom_nav.dart';
import 'package:bio_g/widgets/shared/connectivity_banner.dart';

class DashboardScreen extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavTap;

  const DashboardScreen({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  static const int _dashboardTabIndex = 4;

  static bool _hasAnimatedThisSession = false;

  final DashboardScreenPresenter _presenter = DashboardScreenPresenter();

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1320),
      value: _hasAnimatedThisSession ? 1.0 : 0.0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final bool isActiveNow = widget.currentIndex == _dashboardTabIndex;

      if (isActiveNow && !_hasAnimatedThisSession) {
        _entranceController.forward(from: 0);
        _hasAnimatedThisSession = true;
      }
    });
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool wasActiveBefore = oldWidget.currentIndex == _dashboardTabIndex;
    final bool isActiveNow = widget.currentIndex == _dashboardTabIndex;

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
    _entranceController.dispose();
    super.dispose();
  }

  void _applyResolvedAgroStateSync({
    required BioGStore store,
    required DashboardSyncPlan plan,
    required dynamic resolvedEval,
    required dynamic nextAlertsState,
  }) {
    if (!plan.hasChanges) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (plan.shouldSetEval) {
        store.setAgroEval(resolvedEval);
      }

      if (plan.shouldSetAlerts) {
        store.setAlertsState(nextAlertsState);
      }
    });
  }

  Future<void> _handleExportTap() async {
    final BioGStore store = BioGScope.of(context);
    final DateTime now = DateTime.now();
    final String fileName =
        'BioG_Reporte_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfPreviewScreen.generate(
          fileName: fileName,
          minimumLoadingDuration: const Duration(seconds: 3),
          onLoadPdf: () async {
            final runtime = CropRuntimeResolver.resolve(
              device: store.activeDevice,
              seed: store.activeSeed,
              cropContext: store.activeCropContext,
              live: store.live,
              alertsState: store.alertsState,
              now: now,
            );

            final reportData = await const QuickReportBuilder().build(
              store: store,
              runtime: runtime,
              now: now,
            );

            final Uint8List pdfBytes = await const PdfReportBuilder().build(
              data: reportData,
              telemetry: runtime.live ?? store.live,
            );

            return pdfBytes;
          },
        ),
      ),
    );
  }

  Future<void> _handleYieldProjectionTap() async {
    // Las ornamentales NO tienen proyección de rendimiento
    // (supportsYieldProjection=false). No se invoca YieldProjection: se abre el
    // seguimiento de la planta (estado / cuidados) en su lugar.
    final BioGStore store = BioGScope.of(context);
    if (isEstablishmentMaintenanceContext(store.activeCropContext) ||
        isEstablishmentMaintenanceCrop(cropId: store.activeSeed?.cropKey) ||
        // Tulipán (seasonal_bulb): no proyecta rendimiento; el tap abre sanidad.
        isSeasonalBulbContext(store.activeCropContext) ||
        isSeasonalBulbCrop(cropId: store.activeSeed?.cropKey) ||
        // Girasol (annual_ornamental): no proyecta rendimiento; el tap abre
        // sanidad, como las demás ornamentales.
        isAnnualOrnamentalContext(store.activeCropContext) ||
        isAnnualOrnamentalCrop(cropId: store.activeSeed?.cropKey)) {
      await _handlePlantHealthTap();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const YieldProjectionSetupScreen(),
      ),
    );
  }

  Future<void> _handlePlantHealthTap() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CropRiskIntroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BioGStore store = BioGScope.of(context);

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final DateTime today = DateTime.now();

        final runtime = CropRuntimeResolver.resolve(
          device: store.activeDevice,
          seed: store.activeSeed,
          cropContext: store.activeCropContext,
          live: store.live,
          alertsState: store.alertsState,
          now: today,
        );

        final DashboardSyncPlan syncPlan = _presenter.buildSyncPlan(
          store: store,
          resolvedEval: runtime.eval,
          nextAlertsState: runtime.nextAlertsState,
        );

        _applyResolvedAgroStateSync(
          store: store,
          plan: syncPlan,
          resolvedEval: runtime.eval,
          nextAlertsState: runtime.nextAlertsState,
        );

        final DashboardViewData viewData = _presenter.buildViewData(
          store: store,
          runtime: runtime,
          today: today,
        );

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: ConnectivityBanner(
            enabled: widget.currentIndex == _dashboardTabIndex,
            child: Stack(
              children: <Widget>[
                const DashboardBackground(),
                SafeArea(
                  top: true,
                  bottom: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        DashboardReveal(
                          controller: _entranceController,
                          intervalStart: 0.00,
                          intervalEnd: 0.16,
                          yOffset: 16,
                          beginScale: 0.988,
                          child: DashboardHeaderSection(
                            cropLabel: viewData.cropLabel,
                            fieldLabel: viewData.fieldLabel,
                            cropIconAsset: viewData.cropIconAsset,
                            hasNotifications: viewData.events.isNotEmpty,
                            onNotificationTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => NotificationsScreen(
                                    events: viewData.events,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        DashboardReveal(
                          controller: _entranceController,
                          intervalStart: 0.08,
                          intervalEnd: 0.34,
                          yOffset: 18,
                          beginScale: 0.978,
                          child: DashboardSoilHealthSection(
                            percent: viewData.soilHealth,
                            label: viewData.soilHealthLabel,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DashboardReveal(
                          controller: _entranceController,
                          intervalStart: 0.32,
                          intervalEnd: 0.50,
                          yOffset: 18,
                          beginScale: 0.984,
                          child: DashboardNpkSection(
                            title: viewData.npkTitle,
                            subtitle: viewData.npkSubtitle,
                          ),
                        ),
                        const SizedBox(height: 13),
                        DashboardMetricsGridSection(
                          moisture: viewData.moisture,
                          temperature: viewData.temperature,
                          ph: viewData.ph,
                          resistance: viewData.resistance,
                          controller: _entranceController,
                        ),
                        const SizedBox(height: 12),
                        DashboardReveal(
                          controller: _entranceController,
                          intervalStart: 0.78,
                          intervalEnd: 1.00,
                          yOffset: 18,
                          beginScale: 0.983,
                          child: DashboardQuickActionsSection(
                            onExportTap: _handleExportTap,
                            onCropJourneyTap: _handleYieldProjectionTap,
                            onClimateTap: _handlePlantHealthTap,
                            cropJourneyTitle: viewData.cropJourneyTitle,
                          ),
                        ),
                        SizedBox(
                          height:
                              24 + MediaQuery.of(context).viewPadding.bottom,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BioGBottomNav(
            currentIndex: widget.currentIndex,
            onTap: widget.onNavTap,
          ),
        );
      },
    );
  }
}
