import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/seasonal_bulb/seasonal_bulb_crops.dart';
import 'package:bio_g/core/crops/annual_ornamental/annual_ornamental_crops.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_coordinator.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/features/reporting/pdf_preview_screen.dart';
import 'package:bio_g/features/reporting/pdf_report_builder.dart';
import 'package:bio_g/features/reporting/quick_report_builder.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/screens/dashboard/dashboard_presenter.dart';
import 'package:bio_g/screens/dashboard/dashboard_sections.dart';
import 'package:bio_g/screens/recommendations/recommendations_screen.dart';
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

  // Instancia, NO estatica.
  //
  // Con `static` esta bandera se compartia entre todas las instancias y entre
  // todas las reconstrucciones, asi que la animacion de entrada corria **una
  // sola vez en toda la vida del proceso**: la primera. A partir de ahi el
  // controlador se creaba ya en 1.0 y la pantalla aparecia pintada de golpe,
  // sin reveal, al cambiar de pestaña o al reabrir la app.
  bool _hasAnimatedThisSession = false;

  final DashboardScreenPresenter _presenter = DashboardScreenPresenter();

  /// Orquesta clima → decisión de riego → registro auditable.
  ///
  /// Vive en el estado de la pantalla para que su ciclo de vida sea el de la
  /// pantalla y no haya que tocar el arranque de la app.
  /// El coordinador de riego.
  ///
  /// `late final` y no un inicializador de campo porque necesita `context`:
  /// cuando descubre que la parcela tiene ubicación en el perfil pero no en el
  /// contexto de cultivo, la escribe. Ese era el bug por el que el motor de
  /// riego nunca veía el clima aunque Entorno sí lo mostrara.
  late final IrrigationCoordinator _irrigation = IrrigationCoordinator(
    onParcelLocationRecovered: (DeviceCropContext healed) =>
        BioGScope.of(context).saveCropContext(healed),
  );

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

    if (!wasActiveBefore && isActiveNow) {
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
    _irrigation.dispose();
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
      // Escucha al store y al coordinador: cuando el clima termina de
      // descargarse, la tarjeta de riego debe repintarse aunque el store no
      // haya cambiado.
      animation: Listenable.merge(<Listenable>[
        store,
        _irrigation,
        // También la bandeja: un aviso nuevo debe encender la campana sin
        // esperar a que el store notifique por otra razón.
        store.notifications,
      ]),
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

        // Decisión de riego con el clima que ya está en memoria. Es una
        // llamada pura: no toca red ni disco, así que es segura dentro de
        // `build`.
        final IrrigationDecision? irrigationDecision = _irrigation.decisionFor(
          runtime,
          now: today,
        );

        // Publica la decisión para el resto del sistema.
        //
        // El coordinador vive aquí, en el estado de esta pantalla, pero el
        // registro de eventos corre en segundo plano cada vez que llega una
        // lectura. Sin este puente, ese registro no sabía qué había decidido el
        // motor y deducía el riego por su cuenta desde la banda de humedad: por
        // eso la campana podía decir "riego recomendado" mientras esta misma
        // tarjeta decía "espera, se espera lluvia".
        //
        // Es una asignación pura, sin `notifyListeners`, así que es segura
        // dentro de `build`.
        store.publishIrrigationDecision(irrigationDecision);

        // El refresco de clima y el registro auditable van fuera del frame:
        // son asíncronos y no deben retrasar el pintado. El coordinador sale
        // solo si el estado relevante no cambió.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(
            _irrigation.sync(runtime: runtime, userId: store.currentUserId),
          );
        });

        final DashboardViewData viewData = _presenter.buildViewData(
          store: store,
          runtime: runtime,
          today: today,
          irrigationDecision: irrigationDecision,
        );

        // Abre la pantalla de Recomendaciones con lo que el Panel ya calculo.
        // No recalcula nada: pasa la misma decision y los mismos eventos que
        // se estan mostrando, para que lo que se lee alli sea exactamente lo
        // que fundamenta la tarjeta de aqui.
        void openRecommendations() {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RecommendationsScreen(
                events: viewData.events,
                irrigationDecision: viewData.irrigationDecision,
                cropLabel: viewData.cropLabel,
                // La bandera manda: sin `hasSoilMoistureData` el valor es el
                // 0.0 sintetizado, y un cero fingido en el dial de humedad
                // seria justo el bug que el proyecto lleva meses cerrando.
                moisturePct: (runtime.live?.hasSoilMoistureData ?? false)
                    ? runtime.live!.soilMoisturePct
                    : null,
                // La MISMA banda que usa el motor de riego, con el mismo
                // respaldo. `runtime.targets` es null a proposito en modo guia
                // y sin cultivo; sin el `??` el dial y la barra de zonas
                // desaparecian de la pantalla mientras el motor seguia
                // decidiendo con la banda derivada — dos lecturas del mismo
                // dato, que es el defecto que este trabajo cierra.
                moistureTarget:
                    runtime.targets?.moistureRaw ??
                    runtime.resolvedMoisture?.range,
                // Contexto de la tarjeta de etapa: es la etapa la que mueve el
                // rango ideal, asi que el productor tiene que poder ver contra
                // cual se le esta midiendo.
                stageLabel: runtime.stageLabel,
                cropIconAsset: viewData.cropIconAsset,
                // Una ruta empujada no se reconstruye cuando el Panel lo hace.
                // Pasando el coordinador, la pantalla se entera de la decisión
                // que llegue después —tipicamente cuando baja el pronóstico— y
                // pide un refresco al abrirse.
                coordinator: _irrigation,
                onRefresh: () => _irrigation.refresh(
                  runtime: runtime,
                  userId: store.currentUserId,
                ),
                // El bloque del pronostico es un resumen. Quien quiera el
                // completo cierra esta ruta y cae en la pestana de Entorno,
                // que es donde vive de verdad.
                onOpenEnvironment: () {
                  Navigator.of(context).pop();
                  widget.onNavTap(BioGTabIndex.environment);
                },
              ),
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: ConnectivityBanner(
            enabled: widget.currentIndex == _dashboardTabIndex,
            // Al recuperar la señal, reintenta lo que quedó pendiente de subir.
            // Antes el único disparador era iniciar sesión: una edición hecha
            // sin cobertura esperaba en la cola hasta el siguiente arranque.
            onBackOnline: () => unawaited(store.drainPendingSync()),
            child: Stack(
              children: <Widget>[
                DashboardBackground(
                  enabled: widget.currentIndex == _dashboardTabIndex,
                ),
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
                            // La bandeja persistente es la ÚNICA fuente:
                            // aplica las preferencias del usuario y sobrevive
                            // al cierre de la app, cosa que la lista
                            // recalculada no.
                            //
                            // El `|| viewData.events.isNotEmpty` que había
                            // aquí mantenía la campana encendida siempre: el
                            // motor de eventos emite un evento de contexto en
                            // cada evaluación, y esos eventos son `info`, es
                            // decir, justo los que el umbral por defecto nunca
                            // deja pasar a la bandeja. La campana vibraba por
                            // avisos que tenían garantizado no existir.
                            hasNotifications:
                                store.notifications.unreadCount > 0,
                            onNotificationTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => NotificationsScreen(
                                    dispatcher: store.notifications,
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
                            isActive:
                                widget.currentIndex == _dashboardTabIndex,
                          ),
                        ),
                        // Separador anillo → tarjeta de riego.
                        //
                        // Heredaba los 12 px que vivian dentro de
                        // `DashboardNpkSection`; ahora que las dos tarjetas se
                        // intercambian de sitio, el margen pertenece a la
                        // posicion y no al widget.
                        //
                        // Baja a 6 porque el otro recorte —los 14 px de lienzo
                        // muerto del anillo, en `DashboardSoilHealthSection`—
                        // ya no compensa solo: entre los dos suben 20 px todo
                        // lo que va debajo del anillo.
                        const SizedBox(height: 6),
                        // Tarjeta de riego — primera posicion.
                        //
                        // Sube aqui desde debajo del grid. El riego es la
                        // decision de hoy y cambia con cada lectura; el NPK es
                        // decision de etapa y cambia en semanas. Lo que se
                        // mueve rapido va arriba.
                        //
                        // Conserva el intervalo de la posicion (0.32–0.50), no
                        // el suyo anterior: la cascada de entrada tiene que
                        // seguir corriendo de arriba hacia abajo.
                        //
                        // La franja amarilla de evidencia que iba debajo se
                        // mudo a la pantalla de Recomendaciones: alli cabe
                        // entera —motivos, clima usado, vigencia, confianza y
                        // limitaciones— sin competir con la recomendacion. El
                        // Panel se queda con lo unico que importa aqui: que
                        // hacer hoy.
                        DashboardReveal(
                          controller: _entranceController,
                          intervalStart: 0.32,
                          intervalEnd: 0.50,
                          yOffset: 18,
                          beginScale: 0.984,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: openRecommendations,
                            child: DashboardInsightSection(
                              insight: viewData.irrigation,
                            ),
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
                        // Tarjeta de NPK — baja detras del grid.
                        //
                        // Queda pegada a las otras cuatro metricas del suelo,
                        // que es su familia: el bloque de medicion completo va
                        // junto y sin que la decision lo interrumpa.
                        DashboardReveal(
                          controller: _entranceController,
                          intervalStart: 0.70,
                          intervalEnd: 0.94,
                          yOffset: 18,
                          beginScale: 0.983,
                          child: DashboardNpkSection(
                            title: viewData.npkTitle,
                            subtitle: viewData.npkSubtitle,
                          ),
                        ),
                        // El enlace "Ver por que y mas avisos" se retiro: la
                        // tarjeta de riego ya lleva a Recomendaciones y ahora
                        // esta arriba, asi que el enlace quedaba huerfano al
                        // final de la pantalla apuntando a algo que ya no
                        // estaba a su lado.
                        const SizedBox(height: 14),
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
