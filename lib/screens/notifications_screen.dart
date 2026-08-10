import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/notifications/notification_dispatcher.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/widgets/history/history_event_tile.dart';

/// Bandeja de avisos.
///
/// Antes recibía una lista de [AgronomicEvent] por constructor, y cada pantalla
/// le pasaba la suya: el Panel una calculada sin historial de telemetría y el
/// Historial otra distinta. Abrir la campana desde un sitio o desde otro daba
/// contenidos diferentes, y ninguno coincidía con lo que la bandeja real había
/// decidido entregar.
///
/// Ahora la fuente es única: [NotificationDispatcher], que es quien aplica las
/// preferencias del agricultor —umbral de severidad, categorías, horario
/// silencioso— y persiste lo que de verdad se avisó.
///
/// La distinción del Fundacional se conserva intacta: un **evento** es algo que
/// ocurrió y vive en el Historial; una **notificación** es lo que BIO-G decidió
/// comunicar y vive aquí. Por eso el Historial legítimamente muestra más cosas
/// que esta pantalla.
///
/// Esa misma distinción obliga a dos entradas, no a una:
///
/// - [NotificationsScreen] — la campana. Fuente: el despachador.
/// - [NotificationsScreen.events] — el "Ver más" del Historial. Fuente: la
///   lista de eventos que esa pantalla ya está mostrando, porque el Historial
///   solo pinta tres y necesita una vía para verlos todos.
///
/// Comparten el mismo render a propósito: es la misma clase de contenido con
/// distinto criterio de inclusión. Lo que NO puede volver a pasar es que la
/// campana se alimente de eventos recalculados, que era el origen de que
/// mostrara una cosa por fuera y otra por dentro.
class NotificationsScreen extends StatefulWidget {
  /// Bandeja real. Nulo en el modo de solo eventos.
  final NotificationDispatcher? dispatcher;

  /// Eventos fijos a mostrar. Nulo en el modo bandeja.
  final List<AgronomicEvent>? events;

  // Los `assert` sostienen el invariante que el sistema de tipos no puede:
  // exactamente una de las dos fuentes, nunca ninguna.
  const NotificationsScreen({super.key, required this.dispatcher})
    : events = null,
      assert(dispatcher != null, 'La campana necesita el despachador');

  const NotificationsScreen.events({super.key, required this.events})
    : dispatcher = null,
      assert(events != null, 'El modo lista necesita los eventos');

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _filterIndex = 0;

  static const List<String> _filterLabels = ['Todos', 'Alertas', 'Info'];

  @override
  void initState() {
    super.initState();
    // Visitar la bandeja es leerla: apaga la campana y lo persiste.
    // `markRead`/`markAllRead` existían y no los llamaba nadie, así que
    // `unreadCount` solo podía crecer y el punto rojo no se apagaba jamás.
    //
    // Se hidrata antes de marcar: en un arranque en frío la bandeja de disco
    // puede no estar leída todavía, y marcar sobre una lista vacía no tendría
    // efecto útil. `hydrate()` es idempotente.
    final NotificationDispatcher? dispatcher = widget.dispatcher;
    if (dispatcher == null) return; // Modo solo eventos: no hay nada que leer.

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await dispatcher.hydrate();
      if (!mounted) return;
      await dispatcher.markAllRead();
    });
  }

  /// Evento de presentación reconstruido desde la notificación.
  ///
  /// Los tiles siguen recibiendo un [AgronomicEvent], así que el render queda
  /// idéntico: no se toca ni un widget. `payload` conserva el tipo y la métrica
  /// del evento de origen, y el `id` de la notificación es `deviceId|dedupKey`,
  /// que es la misma llave con la que el evento quedó archivado en el Historial.
  static AgronomicEvent _asDisplayEvent(BiogNotification n) {
    return AgronomicEvent(
      type: AgronomicEventType.values.firstWhere(
        (AgronomicEventType t) => t.name == n.payload['eventType'],
        orElse: () => AgronomicEventType.genericMode,
      ),
      severity: n.severity,
      title: n.title,
      message: n.body,
      timestamp: n.createdAt,
      deviceId: n.deviceId,
      metricKey: n.payload['metricKey'] as String?,
      stageKey: n.payload['stageKey'] as String?,
      isCritical: n.severity == AgronomicEventSeverity.critical,
      isInformative: n.severity == AgronomicEventSeverity.info,
    );
  }

  List<AgronomicEvent> get _all {
    final List<AgronomicEvent>? fixed = widget.events;
    if (fixed != null) return fixed;

    return widget.dispatcher!.notifications
        .where(
          (BiogNotification n) =>
              n.state != NotificationDeliveryState.dismissed,
        )
        .map(_asDisplayEvent)
        .toList(growable: false);
  }

  List<AgronomicEvent> _filteredFrom(List<AgronomicEvent> all) {
    switch (_filterIndex) {
      case 1:
        return all.where((e) => e.isAlertLike || e.isCritical).toList();
      case 2:
        return all.where((e) => !e.isAlertLike && !e.isCritical).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final NotificationDispatcher? dispatcher = widget.dispatcher;
    // En modo solo eventos la lista es fija: no hay a qué suscribirse.
    if (dispatcher == null) return _buildContent(context);

    // Repinta cuando la bandeja cambia: al marcar leído, al descartar o al
    // llegar un aviso nuevo mientras la pantalla está abierta.
    return AnimatedBuilder(
      animation: dispatcher,
      builder: (BuildContext context, Widget? _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final all = _all;
    final filtered = _filteredFrom(all);
    final bottomPad = MediaQuery.of(context).viewPadding.bottom + 24;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Header --
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  _GlassBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Notificaciones',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Text(
                    '${all.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // -- Filter pills (same style as history range selector) --
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _NotificationPillBar(
                labels: _filterLabels,
                selectedIndex: _filterIndex,
                onSelect: (i) {
                  if (i == _filterIndex) return;
                  HapticFeedback.selectionClick();
                  setState(() => _filterIndex = i);
                },
              ),
            ),

            const SizedBox(height: 14),

            // -- Event list --
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: Colors.black.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin notificaciones',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No hay eventos para este filtro.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withValues(alpha: 0.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(18, 0, 18, bottomPad),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final event = filtered[index];
                        return BioGGlassCard(
                          radius: 18,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _NotificationExpandableTile(event: event),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tile that shows the event title; tapping it expands to show the message.
class _NotificationExpandableTile extends StatefulWidget {
  final AgronomicEvent event;

  const _NotificationExpandableTile({required this.event});

  @override
  State<_NotificationExpandableTile> createState() =>
      _NotificationExpandableTileState();
}

class _NotificationExpandableTileState
    extends State<_NotificationExpandableTile> {
  bool _expanded = false;

  static const String _kRiegoIcon = 'assets/icons/metrics/ic_riego.png';
  static const String _kBalanceIcon = 'assets/icons/metrics/ic_balance.png';
  static const String _kTempIcon = 'assets/icons/metrics/ic_temperature.png';
  static const String _kPhIcon = 'assets/icons/metrics/ic_ph.png';
  static const String _kResistanceIcon =
      'assets/icons/metrics/ic_resistance.png';
  static const String _kNpkIcon = 'assets/icons/metrics/ic_npk.png';
  static const String _kMoistureIcon = 'assets/icons/metrics/ic_moisture.png';
  static const String _kNitrogenIcon = 'assets/icons/metrics/ic_nitrogen.png';
  static const String _kPhosphorusIcon =
      'assets/icons/metrics/ic_phosphorus.png';
  static const String _kPotassiumIcon = 'assets/icons/metrics/ic_potassium.png';
  static const String _kProtectionIcon =
      'assets/icons/metrics/ic_protection.png';
  static const String _kAlertIcon = 'assets/icons/metrics/ic_alert.png';

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isAlert = event.isAlertLike || event.isCritical;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: Center(
                      child: OverflowBox(
                        maxWidth: 98,
                        maxHeight: 98,
                        child: Transform.scale(
                          scale: 2.86,
                          child: HistoryEventTile.buildIconBase(
                            assetIcon: _assetForEvent(event),
                            icon: _iconForEvent(event),
                            isAlert: isAlert,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      event.title.isNotEmpty ? event.title : event.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Severity badge
                  _SeverityBadge(severity: event.severity),
                  const SizedBox(width: 6),
                  // Time
                  Text(
                    _timeLabelForEvent(event),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              // Expanded message
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(left: 46, top: 8, right: 8),
                  child: Text(
                    event.message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _assetForEvent(AgronomicEvent event) {
    switch (event.type) {
      case AgronomicEventType.lowMoisture:
      case AgronomicEventType.irrigationRecommended:
        return _kRiegoIcon;

      case AgronomicEventType.highMoisture:
      case AgronomicEventType.stableMoisture:
        return _kMoistureIcon;

      case AgronomicEventType.lowPh:
      case AgronomicEventType.highPh:
      case AgronomicEventType.stablePh:
        return _kPhIcon;

      case AgronomicEventType.soilCompaction:
      case AgronomicEventType.goodSoilStructure:
        return _kResistanceIcon;

      case AgronomicEventType.heatStress:
      case AgronomicEventType.coldStress:
      case AgronomicEventType.stableSoilTemp:
      case AgronomicEventType.frostWarning:
      case AgronomicEventType.highAirTemp:
        return _kTempIcon;

      case AgronomicEventType.lowAirHumidity:
      case AgronomicEventType.highAirHumidity:
        return _kMoistureIcon;

      case AgronomicEventType.nitrogenLow:
      case AgronomicEventType.nitrogenHigh:
        return _kNitrogenIcon;
      case AgronomicEventType.phosphorusLow:
      case AgronomicEventType.phosphorusHigh:
        return _kPhosphorusIcon;
      case AgronomicEventType.potassiumLow:
      case AgronomicEventType.potassiumHigh:
        return _kPotassiumIcon;

      case AgronomicEventType.npkReading:
      case AgronomicEventType.nutrientImbalance:
      case AgronomicEventType.fertilizationRecommended:
        return _kNpkIcon;

      case AgronomicEventType.combinedStress:
        return _kAlertIcon;

      case AgronomicEventType.stableSoil:
      case AgronomicEventType.recovery:
        return _kProtectionIcon;

      case AgronomicEventType.genericMode:
      case AgronomicEventType.preSowing:
      case AgronomicEventType.cropActivated:
      case AgronomicEventType.stageTransition:
        return _kBalanceIcon;
    }
  }

  IconData _iconForEvent(AgronomicEvent event) {
    switch (event.type) {
      case AgronomicEventType.genericMode:
        return Icons.info_outline_rounded;
      case AgronomicEventType.preSowing:
        return Icons.event_available_rounded;
      case AgronomicEventType.cropActivated:
        return Icons.agriculture_rounded;
      case AgronomicEventType.stageTransition:
        return Icons.swap_horiz_rounded;
      case AgronomicEventType.lowMoisture:
        return Icons.warning_amber_rounded;
      case AgronomicEventType.highMoisture:
        return Icons.water_drop_rounded;
      case AgronomicEventType.stableMoisture:
        return Icons.check_circle_outline_rounded;
      case AgronomicEventType.lowPh:
      case AgronomicEventType.highPh:
        return Icons.warning_amber_rounded;
      case AgronomicEventType.stablePh:
        return Icons.check_circle_outline_rounded;
      case AgronomicEventType.soilCompaction:
        return Icons.warning_amber_rounded;
      case AgronomicEventType.goodSoilStructure:
        return Icons.trending_up_rounded;
      case AgronomicEventType.heatStress:
        return Icons.thermostat_rounded;
      case AgronomicEventType.coldStress:
        return Icons.ac_unit_rounded;
      case AgronomicEventType.stableSoilTemp:
        return Icons.check_circle_outline_rounded;
      case AgronomicEventType.npkReading:
        return Icons.science_rounded;
      case AgronomicEventType.nutrientImbalance:
        return Icons.balance_rounded;
      case AgronomicEventType.nitrogenLow:
      case AgronomicEventType.phosphorusLow:
      case AgronomicEventType.potassiumLow:
      case AgronomicEventType.nitrogenHigh:
      case AgronomicEventType.phosphorusHigh:
      case AgronomicEventType.potassiumHigh:
        return Icons.warning_amber_rounded;
      case AgronomicEventType.stableSoil:
        return Icons.trending_up_rounded;
      case AgronomicEventType.combinedStress:
        return Icons.priority_high_rounded;
      case AgronomicEventType.recovery:
        return Icons.restart_alt_rounded;
      case AgronomicEventType.irrigationRecommended:
        return Icons.water_drop_rounded;
      case AgronomicEventType.fertilizationRecommended:
        return Icons.eco_rounded;
      case AgronomicEventType.frostWarning:
        return Icons.ac_unit_rounded;
      case AgronomicEventType.highAirTemp:
        return Icons.thermostat_rounded;
      case AgronomicEventType.lowAirHumidity:
        return Icons.air_rounded;
      case AgronomicEventType.highAirHumidity:
        return Icons.cloud_rounded;
    }
  }

  String _timeLabelForEvent(AgronomicEvent event) {
    if (event.type == AgronomicEventType.genericMode) return 'Contexto';
    if (event.type == AgronomicEventType.preSowing) return 'Calendario';
    if (event.type == AgronomicEventType.cropActivated) return 'Ciclo';
    if (event.type == AgronomicEventType.stageTransition) return 'Etapa';
    if (event.type == AgronomicEventType.stableSoil) return 'Tendencia';
    if (event.type == AgronomicEventType.combinedStress) return 'Tendencia';
    if (event.type == AgronomicEventType.recovery) return 'Resumen';

    // `.toLocal()`: los timestamps se persisten y se comparan en UTC, pero la
    // hora que lee el agricultor tiene que ser la de su reloj. Sin esto la
    // bandeja mostraba las horas corridas por el huso (seis horas en México).
    final dt = event.timestamp.toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inHours < 24) {
      final hour = dt.hour == 0
          ? 12
          : dt.hour > 12
          ? dt.hour - 12
          : dt.hour;
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'pm' : 'am';
      return 'Hoy · $hour:$min $ampm';
    }

    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays} días';
  }
}

class _SeverityBadge extends StatelessWidget {
  final AgronomicEventSeverity severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (severity) {
      AgronomicEventSeverity.critical => (
        const Color(0xFFFFE0E0),
        const Color(0xFFD32F2F),
      ),
      AgronomicEventSeverity.warning => (
        const Color(0xFFFFF3DF),
        const Color(0xFFE6870E),
      ),
      AgronomicEventSeverity.caution => (
        const Color(0xFFEAF3FF),
        const Color(0xFF2979FF),
      ),
      AgronomicEventSeverity.info => (
        const Color(0xFFE9F7F2),
        const Color(0xFF3E9F86),
      ),
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: fg,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: bg, blurRadius: 4, spreadRadius: 1)],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sliding pill bar (mirrors HistoryRangeSelector style)
// ---------------------------------------------------------------------------

class _NotificationPillBar extends StatefulWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _NotificationPillBar({
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<_NotificationPillBar> createState() => _NotificationPillBarState();
}

class _NotificationPillBarState extends State<_NotificationPillBar> {
  final _rowKey = GlobalKey();
  late final List<GlobalKey> _pillKeys;

  double _pillLeft = 0;
  double _pillWidth = 0;

  @override
  void initState() {
    super.initState();
    _pillKeys = List.generate(widget.labels.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalcPill());
  }

  @override
  void didUpdateWidget(covariant _NotificationPillBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recalcPill());
    }
  }

  void _recalcPill() {
    final rowCtx = _rowKey.currentContext;
    final tabCtx = _pillKeys[widget.selectedIndex].currentContext;
    if (rowCtx == null || tabCtx == null) return;

    final rowBox = rowCtx.findRenderObject() as RenderBox;
    final tabBox = tabCtx.findRenderObject() as RenderBox;

    final tabPos = tabBox.localToGlobal(Offset.zero, ancestor: rowBox);
    if (!mounted) return;
    setState(() {
      _pillLeft = tabPos.dx;
      _pillWidth = tabBox.size.width;
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    final tabRadius = BorderRadius.circular(22);

    return Align(
      alignment: Alignment.center,
      child: IntrinsicWidth(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Sliding green pill
                    if (_pillWidth > 0)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        left: _pillLeft,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: _pillWidth,
                          decoration: BoxDecoration(
                            borderRadius: tabRadius,
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF40BB5F),
                                Color(0xFF3FAF6E),
                                Color.fromARGB(137, 43, 126, 101),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF40BB5F,
                                ).withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: tabRadius,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: tabRadius,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.center,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.14),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Pill labels row
                    Row(
                      key: _rowKey,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(widget.labels.length, (i) {
                        return _PillTap(
                          key: _pillKeys[i],
                          onTap: () => widget.onSelect(i),
                          child: SizedBox(
                            width: 82,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                widget.labels[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: widget.selectedIndex == i
                                      ? Colors.white
                                      : Colors.black87,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTap extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _PillTap({super.key, required this.onTap, required this.child});

  @override
  State<_PillTap> createState() => _PillTapState();
}

class _PillTapState extends State<_PillTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: Colors.black.withValues(alpha: 0.035),
        highlightColor: Colors.black.withValues(alpha: 0.02),
        onHighlightChanged: (v) {
          if (_pressed == v) return;
          setState(() => _pressed = v);
        },
        child: AnimatedScale(
          scale: _pressed ? 0.992 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GlassBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.black12),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Colors.black87,
        ),
      ),
    );
  }
}
