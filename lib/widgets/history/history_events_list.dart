import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

import 'history_event_tile.dart';

class HistoryEventsList extends StatefulWidget {
  final List<AgronomicEvent> events;
  final VoidCallback? onViewAll;

  const HistoryEventsList({super.key, required this.events, this.onViewAll});

  @override
  State<HistoryEventsList> createState() => _HistoryEventsListState();
}

class _HistoryEventsListState extends State<HistoryEventsList> {
  static const int _visibleCount = 3;

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
  static const String _kPotassiumIcon =
      'assets/icons/metrics/ic_potassium.png';
  static const String _kProtectionIcon =
      'assets/icons/metrics/ic_protection.png';
  static const String _kAlertIcon = 'assets/icons/metrics/ic_alert.png';

  @override
  Widget build(BuildContext context) {
    final mapped = widget.events.map(_mapEventToVm).toList();
    final visible = mapped.take(_visibleCount).toList();

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Eventos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            if (widget.onViewAll != null && mapped.isNotEmpty)
              _MoreChip(onTap: widget.onViewAll!),
          ],
        ),
        const SizedBox(height: 12),

        if (visible.isEmpty)
          BioGGlassCard(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.black.withValues(alpha:0.45),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aún no hay eventos relevantes para este periodo.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha:0.58),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...visible.map(
            (e) => BioGGlassCard(
              radius: 18,
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: HistoryEventTile(
                  assetIcon: e.assetIcon,
                  icon: e.icon,
                  iconBg: e.iconBg,
                  title: e.title,
                  timeRight: e.timeRight,
                  subtleDots: e.subtleDots,
                  isAlert: e.isAlert,
                ),
              ),
            ),
          ),
      ],
    );
  }

  _HistoryEventVM _mapEventToVm(AgronomicEvent event) {
    return _HistoryEventVM(
      assetIcon: _assetForEvent(event),
      icon: _iconForEvent(event),
      iconBg: _iconBgForEvent(event),
      title: event.title.isNotEmpty ? event.title : event.message,
      timeRight: _timeLabelForEvent(event),
      subtleDots: _subtleDotsForEvent(event),
      isAlert: _isAlertEvent(event),
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

      case AgronomicEventType.frostWarning:
        return Icons.ac_unit_rounded;

      case AgronomicEventType.highAirTemp:
        return Icons.thermostat_rounded;

      case AgronomicEventType.lowAirHumidity:
        return Icons.air_rounded;

      case AgronomicEventType.highAirHumidity:
        return Icons.cloud_rounded;

      case AgronomicEventType.irrigationRecommended:
        return Icons.water_drop_rounded;

      case AgronomicEventType.fertilizationRecommended:
        return Icons.eco_rounded;
    }
  }

  Color _iconBgForEvent(AgronomicEvent event) {
    if (event.severity == AgronomicEventSeverity.critical ||
        event.severity == AgronomicEventSeverity.warning) {
      return const Color(0xFFFFF3DF);
    }

    if (event.severity == AgronomicEventSeverity.caution) {
      return const Color(0xFFEAF3FF);
    }

    switch (event.type) {
      case AgronomicEventType.highMoisture:
      case AgronomicEventType.stableMoisture:
      case AgronomicEventType.stablePh:
      case AgronomicEventType.stableSoilTemp:
      case AgronomicEventType.recovery:
        return const Color(0xFFE9F7F2);

      default:
        return const Color(0xFFEAF3FF);
    }
  }

  bool _subtleDotsForEvent(AgronomicEvent event) {
    return event.type == AgronomicEventType.lowMoisture ||
        event.type == AgronomicEventType.combinedStress ||
        event.type == AgronomicEventType.irrigationRecommended ||
        event.severity == AgronomicEventSeverity.critical;
  }

  bool _isAlertEvent(AgronomicEvent event) {
    return event.isCritical ||
        event.severity == AgronomicEventSeverity.warning ||
        event.severity == AgronomicEventSeverity.critical;
  }

  String _timeLabelForEvent(AgronomicEvent event) {
    if (event.type == AgronomicEventType.genericMode) return 'Contexto';
    if (event.type == AgronomicEventType.preSowing) return 'Calendario';
    if (event.type == AgronomicEventType.cropActivated) return 'Ciclo';
    if (event.type == AgronomicEventType.stageTransition) return 'Etapa';
    if (event.type == AgronomicEventType.stableSoil) return 'Tendencia';
    if (event.type == AgronomicEventType.combinedStress) return 'Tendencia';
    if (event.type == AgronomicEventType.recovery) return 'Resumen';

    // `.toLocal()`: los eventos se guardan y se comparan en UTC, pero aquí se
    // pinta la hora que el agricultor lee en su reloj. Las gráficas de esta
    // misma pantalla ya convertían (`history_series_builder`), así que el eje
    // de tiempo y la lista de eventos iban desfasados seis horas en México.
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

    if (diff.inDays == 1) {
      return 'Ayer';
    }

    return 'Hace ${diff.inDays} días';
  }
}

class _HistoryEventVM {
  final String assetIcon;
  final IconData icon;
  final Color iconBg;
  final String title;
  final String timeRight;
  final bool subtleDots;
  final bool isAlert;

  const _HistoryEventVM({
    required this.assetIcon,
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.timeRight,
    this.subtleDots = false,
    this.isAlert = false,
  });
}

class _MoreChip extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text(
          'Ver más',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}
