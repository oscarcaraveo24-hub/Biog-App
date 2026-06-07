import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/screens/account/biog_hardware_health.dart';
import 'package:bio_g/services/biog/biog_store.dart';

const bool kBioGHardwareFlowUiDebugLogs = true;

class StatusBioGScreen extends StatefulWidget {
  final Map<String, dynamic> device;

  const StatusBioGScreen({super.key, required this.device});

  @override
  State<StatusBioGScreen> createState() => _StatusBioGScreenState();
}

class _StatusBioGScreenState extends State<StatusBioGScreen> {
  static const Color kBrandTop = Color(0xFF40BB5F);

  static const String kHeroPng = 'assets/images/biog_image.png';

  static const String kIcBattery = 'assets/icons/metrics/ic_battery.png';
  static const String kIcSensors = 'assets/icons/metrics/ic_riego.png';
  static const String kIcSignal = 'assets/icons/metrics/ic_signal.png';
  static const String kIcSystem = 'assets/icons/metrics/ic_protection.png';

  static const double kHeroScale = 1.45;
  static const double kHeroHeight = 190;

  static const double kIconScale = 3.1;
  static const double kIconSize = 18;
  static const double kIconBox = 24;

  bool _isShowing = false;
  bool _loadingShowingState = true;

  Stream<BioGTelemetry?>? _telemetryStream;
  BioGTelemetry? _latestTelemetry;
  bool _firstSnapshotReceived = false;
  bool _retryingTelemetry = false;
  Timer? _ticker;
  final Set<String> _loggedHardwareStates = <String>{};

  Map<String, dynamic> get device => widget.device;
  String get _deviceId => (device['id'] ?? '').toString().trim();
  String get _telemetryDeviceId {
    final telemetryId = (device['telemetryDeviceId'] ?? '').toString().trim();
    if (telemetryId.isNotEmpty) return telemetryId;
    return _deviceId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshShowingState();
    _ensureTelemetrySubscription();
  }

  @override
  void initState() {
    super.initState();
    // Re-evaluate connection age once a minute so "Última lectura
    // hace X min" stays in sync without needing a new reading.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _ensureTelemetrySubscription() {
    if (_telemetryStream != null) return;
    if (_telemetryDeviceId.isEmpty) return;

    final store = BioGScope.of(context);
    _telemetryStream = store.watchTelemetryForDevice(_telemetryDeviceId);
  }

  void _refreshShowingState() {
    final id = _deviceId;
    final store = BioGScope.of(context);
    final activeId = store.activeDevice?.id ?? '';

    final nextIsShowing = id.isNotEmpty && activeId == id;

    if (_isShowing == nextIsShowing && !_loadingShowingState) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isShowing = nextIsShowing;
        _loadingShowingState = false;
      });
    });
  }

  Future<void> _setAsShowing() async {
    final id = _deviceId;
    if (id.isEmpty) return;

    final store = BioGScope.of(context);
    await store.setActiveDevice(id);

    if (!mounted) return;

    setState(() {
      _isShowing = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${device['name'] ?? 'Bio-G'} ahora se está mostrando'),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    Navigator.pop(context, {'changedDisplayed': true, 'deviceId': id});
  }

  Future<void> _retryTelemetry() async {
    if (_retryingTelemetry) return;

    setState(() => _retryingTelemetry = true);
    try {
      await BioGScope.of(context).refreshTelemetryForDevice(
        _telemetryDeviceId,
      );
    } finally {
      if (mounted) {
        setState(() => _retryingTelemetry = false);
      }
    }
  }

  Future<void> _deleteThisBioG() async {
    final id = _deviceId;
    final name = (device['name'] ?? 'Bio-G').toString();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '¿Eliminar Bio-G?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text('Se eliminará "$name" de tu lista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Color(0xFFB2554E),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final store = BioGScope.of(context);
    await store.removeDevice(id);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final name = (device['name'] ?? 'Bio-G').toString();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _SoftBackground(),
          SafeArea(
            bottom: false,
            child: StreamBuilder<BioGTelemetry?>(
              stream: _telemetryStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _latestTelemetry = snapshot.data;
                  _firstSnapshotReceived = true;
                } else if (snapshot.connectionState != ConnectionState.waiting) {
                  _firstSnapshotReceived = true;
                }

                final BioGTelemetry? telemetry =
                    _latestTelemetry ?? snapshot.data;
                final BioGHardwareHealth health =
                    BioGHardwareHealth.fromTelemetry(telemetry);
                final bool isLoading =
                    !_firstSnapshotReceived && telemetry == null;
                _logHardwareState(
                  loading: isLoading,
                  telemetry: telemetry,
                  error: snapshot.error,
                );

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(
                        titleLeft: 'Mis Bio-G',
                        titleBold: name,
                        isShowing: _isShowing,
                        loading: _loadingShowingState,
                        onBack: () => Navigator.pop(context, false),
                      ),
                      const SizedBox(height: 14),
                      _GlassCard(
                        radius: 22,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: kHeroHeight,
                              width: double.infinity,
                              child: Center(
                                child: Transform.scale(
                                  scale: kHeroScale,
                                  child: Image.asset(
                                    kHeroPng,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Estado del hardware',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0E1A16),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _HardwareSummaryLine(
                              health: health,
                              isLoading: isLoading,
                            ),
                            if (!isLoading && !health.hasReading) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _retryingTelemetry
                                      ? null
                                      : _retryTelemetry,
                                  icon: _retryingTelemetry
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.refresh_rounded),
                                  label: Text(
                                    _retryingTelemetry
                                        ? 'Reintentando...'
                                        : 'Reintentar',
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            _ChipsRow(health: health, isLoading: isLoading),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GlassCard(
                        radius: 22,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: _DisplaySelectorCard(
                          isShowing: _isShowing,
                          loading: _loadingShowingState,
                          onUseThis: _setAsShowing,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GlassCard(
                        radius: 22,
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                        child: _StatusRowsList(
                          health: health,
                          isLoading: isLoading,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _DangerButton(
                        label: 'Eliminar Bio-G',
                        onTap: _deleteThisBioG,
                      ),
                      SizedBox(
                        height: 24 + MediaQuery.of(context).padding.bottom,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _logHardwareState({
    required bool loading,
    required BioGTelemetry? telemetry,
    required Object? error,
  }) {
    final errorType = error?.runtimeType ?? 'none';
    final key = '$loading|${telemetry?.timestamp.toIso8601String()}|$errorType';
    if (!_loggedHardwareStates.add(key)) return;
    if (!kBioGHardwareFlowUiDebugLogs) return;
    assert(() {
      debugPrint(
        '[BioG/HardwareFlow] UI build loading=$loading '
        'hasHardware=${telemetry != null} error=$errorType '
        'ui_device_id=$_deviceId telemetry_device_id=$_telemetryDeviceId',
      );
      return true;
    }());
  }
}

class _HardwareSummaryLine extends StatelessWidget {
  final BioGHardwareHealth health;
  final bool isLoading;

  const _HardwareSummaryLine({required this.health, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final String text = isLoading
        ? 'Sincronizando datos del dispositivo…'
        : '${health.summaryText} · ${health.connectionText}';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      child: Text(
        text,
        key: ValueKey<String>(text),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black.withValues(alpha: 0.55),
          height: 1.25,
        ),
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  final BioGHardwareHealth health;
  final bool isLoading;

  const _ChipsRow({required this.health, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const <Widget>[
          _SkeletonChip(width: 96),
          _SkeletonChip(width: 86),
          _SkeletonChip(width: 92),
          _SkeletonChip(width: 96),
        ],
      );
    }

    final String batteryLabel = health.hasReading && health.batteryPct != null
        ? 'Batería ${health.batteryPct!.round()}%'
        : 'Batería —';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _AnimatedChipPill(
          label: batteryLabel,
          tint: BioGHealthColors.forBattery(health.batteryLevel),
        ),
        _AnimatedChipPill(
          label: 'Señal ${health.signalSubtitle}',
          tint: BioGHealthColors.forSignal(health.signalLevel),
        ),
        _AnimatedChipPill(
          label: 'Sensores ${_sensorsLabel(health)}',
          tint: _sensorsTint(health),
        ),
        _AnimatedChipPill(
          label: 'Sistema ${_systemLabel(health)}',
          tint: BioGHealthColors.forStatus(health.status),
        ),
      ],
    );
  }

  String _sensorsLabel(BioGHardwareHealth health) {
    if (!health.hasReading) return 'Sin datos';
    if (health.hasSensorData) return 'OK';
    if (health.hasBatteryData || health.hasSignalData) return 'Telemetría';
    return 'Sin datos';
  }

  Color _sensorsTint(BioGHardwareHealth health) {
    if (!health.hasReading) return BioGHealthColors.gray;
    if (health.hasSensorData) return BioGHealthColors.brandMid;
    if (health.hasBatteryData || health.hasSignalData) {
      return BioGHealthColors.amber;
    }
    return BioGHealthColors.gray;
  }

  String _systemLabel(BioGHardwareHealth health) {
    if (!health.hasReading) return 'Sin datos';
    if (!health.hasRecentReading) return 'Sin datos recientes';
    if (health.systemOk) return 'OK';
    if (!health.hasBatteryData ||
        !health.hasSignalData ||
        !health.hasSensorData) {
      return 'Datos parciales';
    }
    switch (health.status) {
      case BioGHardwareStatus.stable:
        return 'Estable';
      case BioGHardwareStatus.warning:
        return 'Atención';
      case BioGHardwareStatus.critical:
        return 'Crítico';
      case BioGHardwareStatus.offline:
        return 'Sin datos';
      case BioGHardwareStatus.unknown:
        return 'Sin datos';
    }
  }
}

class _StatusRowsList extends StatelessWidget {
  final BioGHardwareHealth health;
  final bool isLoading;

  const _StatusRowsList({required this.health, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: const <Widget>[
          _SkeletonRow(),
          _DividerLine(),
          _SkeletonRow(),
          _DividerLine(),
          _SkeletonRow(),
          _DividerLine(),
          _SkeletonRow(),
          _DividerLine(),
          _SkeletonRow(),
        ],
      );
    }

    final int? battery = health.batteryPct?.round();
    final Color batteryTint = BioGHealthColors.forBattery(health.batteryLevel);

    final String signalRight = health.hasReading && health.signalRssi != null
        ? '${health.signalSubtitle} · ${health.signalRssi} dBm'
        : health.signalSubtitle;
    final Color signalTint = BioGHealthColors.forSignal(health.signalLevel);

    final String sensorsLabel = _sensorsLabel(health);
    final Color sensorsTint = _sensorsTint(health);

    final String systemLabel = _systemLabel(health);
    final Color systemTint = BioGHealthColors.forStatus(health.status);
    final Color connectionTint = _connectionTint(health);

    return Column(
      children: [
        _BatteryStatusRow(
          asset: _StatusBioGScreenState.kIcBattery,
          batteryPct: battery,
          subtitle: health.batterySubtitle,
          tint: batteryTint,
          hasReading: health.hasReading,
        ),
        const _DividerLine(),
        _SignalStatusRow(
          asset: _StatusBioGScreenState.kIcSignal,
          rightText: signalRight,
          subtitle: health.signalSubtitle,
          tint: signalTint,
          hasReading: health.hasReading,
        ),
        const _DividerLine(),
        _StatusRowAssetPlain(
          asset: _StatusBioGScreenState.kIcSystem,
          iconScale: _StatusBioGScreenState.kIconScale,
          iconSize: _StatusBioGScreenState.kIconSize,
          iconBox: _StatusBioGScreenState.kIconBox,
          leftText: 'Última lectura',
          rightText: health.connectionText,
          rightTint: connectionTint,
        ),
        const _DividerLine(),
        _StatusRowAssetPlain(
          asset: _StatusBioGScreenState.kIcSensors,
          iconScale: _StatusBioGScreenState.kIconScale,
          iconSize: _StatusBioGScreenState.kIconSize,
          iconBox: _StatusBioGScreenState.kIconBox,
          leftText: 'Sensores',
          rightText: sensorsLabel,
          rightTint: sensorsTint,
        ),
        const _DividerLine(),
        _StatusRowAssetPlain(
          asset: _StatusBioGScreenState.kIcSystem,
          iconScale: _StatusBioGScreenState.kIconScale,
          iconSize: _StatusBioGScreenState.kIconSize,
          iconBox: _StatusBioGScreenState.kIconBox,
          leftText: 'Sistema',
          rightText: systemLabel,
          rightTint: systemTint,
        ),
      ],
    );
  }

  String _sensorsLabel(BioGHardwareHealth health) {
    if (!health.hasReading) return 'Sin datos';
    if (health.hasSensorData) return 'OK';
    if (health.hasBatteryData || health.hasSignalData) return 'Telemetría';
    return 'Sin datos';
  }

  Color _sensorsTint(BioGHardwareHealth health) {
    if (!health.hasReading) return BioGHealthColors.gray;
    if (health.hasSensorData) return BioGHealthColors.brandMid;
    if (health.hasBatteryData || health.hasSignalData) {
      return BioGHealthColors.amber;
    }
    return BioGHealthColors.gray;
  }

  String _systemLabel(BioGHardwareHealth health) {
    if (!health.hasReading) return 'Sin datos';
    if (!health.hasRecentReading) return 'Sin datos recientes';
    if (health.systemOk) return 'OK';
    if (!health.hasBatteryData ||
        !health.hasSignalData ||
        !health.hasSensorData) {
      return 'Datos parciales';
    }
    switch (health.status) {
      case BioGHardwareStatus.stable:
        return 'Estable';
      case BioGHardwareStatus.warning:
        return 'Atención';
      case BioGHardwareStatus.critical:
        return 'Crítico';
      case BioGHardwareStatus.offline:
        return 'Sin datos';
      case BioGHardwareStatus.unknown:
        return 'Sin datos';
    }
  }

  Color _connectionTint(BioGHardwareHealth health) {
    switch (health.connectionState) {
      case BioGConnectionState.active:
        return BioGHealthColors.brandMid;
      case BioGConnectionState.recent:
        return BioGHealthColors.amber;
      case BioGConnectionState.stale:
      case BioGConnectionState.unknown:
        return BioGHealthColors.gray;
    }
  }
}

class _BatteryStatusRow extends StatelessWidget {
  final String asset;
  final int? batteryPct;
  final String subtitle;
  final Color tint;
  final bool hasReading;

  const _BatteryStatusRow({
    required this.asset,
    required this.batteryPct,
    required this.subtitle,
    required this.tint,
    required this.hasReading,
  });

  @override
  Widget build(BuildContext context) {
    final double targetValue = (batteryPct ?? 0).clamp(0, 100).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: _StatusBioGScreenState.kIconBox,
            height: _StatusBioGScreenState.kIconBox,
            child: Center(
              child: Transform.scale(
                scale: _StatusBioGScreenState.kIconScale,
                child: Image.asset(
                  asset,
                  width: _StatusBioGScreenState.kIconSize,
                  height: _StatusBioGScreenState.kIconSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Batería',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0E1A16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (hasReading && batteryPct != null)
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: targetValue),
                        duration: const Duration(milliseconds: 720),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return TweenAnimationBuilder<Color?>(
                            tween: ColorTween(end: tint),
                            duration: const Duration(milliseconds: 360),
                            curve: Curves.easeOut,
                            builder: (context, color, _) {
                              return Text(
                                '${value.round()}%',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: color ?? tint,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _BatteryBar(
                  targetFraction: targetValue / 100.0,
                  tint: tint,
                  hasReading: hasReading,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: tint),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOut,
            builder: (context, color, _) {
              return Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color ?? tint,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BatteryBar extends StatelessWidget {
  final double targetFraction;
  final Color tint;
  final bool hasReading;

  const _BatteryBar({
    required this.targetFraction,
    required this.tint,
    required this.hasReading,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: Colors.black.withValues(alpha: 0.06),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: hasReading ? targetFraction : 0),
          duration: const Duration(milliseconds: 760),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: tint),
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOut,
                  builder: (context, color, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            (color ?? tint).withValues(alpha: 0.85),
                            (color ?? tint),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SignalStatusRow extends StatelessWidget {
  final String asset;
  final String rightText;
  final String subtitle;
  final Color tint;
  final bool hasReading;

  const _SignalStatusRow({
    required this.asset,
    required this.rightText,
    required this.subtitle,
    required this.tint,
    required this.hasReading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: _StatusBioGScreenState.kIconBox,
            height: _StatusBioGScreenState.kIconBox,
            child: Center(
              child: Transform.scale(
                scale: _StatusBioGScreenState.kIconScale,
                child: Image.asset(
                  asset,
                  width: _StatusBioGScreenState.kIconSize,
                  height: _StatusBioGScreenState.kIconSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                const Text(
                  'Señal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0E1A16),
                  ),
                ),
                const SizedBox(width: 10),
                _SignalBars(tint: tint, hasReading: hasReading),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: TweenAnimationBuilder<Color?>(
              key: ValueKey<String>(rightText),
              tween: ColorTween(end: tint),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOut,
              builder: (context, color, _) {
                return Text(
                  rightText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color ?? tint,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny RSSI-bar visualization that animates when the tint or
/// underlying level changes. No wifi icon — just a fluid set of
/// vertical bars to keep it discreet.
class _SignalBars extends StatefulWidget {
  final Color tint;
  final bool hasReading;

  const _SignalBars({required this.tint, required this.hasReading});

  @override
  State<_SignalBars> createState() => _SignalBarsState();
}

class _SignalBarsState extends State<_SignalBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.hasReading) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant _SignalBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasReading != widget.hasReading ||
        oldWidget.tint != widget.tint) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(4, (i) {
            final double progress = ((_ctrl.value * 4) - i).clamp(0.0, 1.0);
            final double height = 6 + (i * 2.5);
            final double opacity = widget.hasReading ? progress : 0.18;
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: widget.tint),
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOut,
                builder: (context, color, _) {
                  return Container(
                    width: 4,
                    height: height,
                    decoration: BoxDecoration(
                      color: (color ?? widget.tint).withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }

}

class _AnimatedChipPill extends StatelessWidget {
  final String label;
  final Color tint;

  const _AnimatedChipPill({required this.label, required this.tint});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: TweenAnimationBuilder<Color?>(
        key: ValueKey<String>(label),
        tween: ColorTween(end: tint),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOut,
        builder: (context, color, _) {
          final Color resolved = color ?? tint;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: resolved.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: resolved.withValues(alpha: 0.95),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonChip extends StatefulWidget {
  final double width;
  const _SkeletonChip({required this.width});

  @override
  State<_SkeletonChip> createState() => _SkeletonChipState();
}

class _SkeletonChipState extends State<_SkeletonChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final double t = 0.06 + (_ctrl.value * 0.10);
        return Container(
          width: widget.width,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: t),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      },
    );
  }
}

class _SkeletonRow extends StatefulWidget {
  const _SkeletonRow();

  @override
  State<_SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<_SkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final double t = 0.06 + (_ctrl.value * 0.08);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: t),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: t),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 70,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: t),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final String titleLeft;
  final String titleBold;
  final bool isShowing;
  final bool loading;
  final VoidCallback onBack;

  const _TopBar({
    required this.titleLeft,
    required this.titleBold,
    required this.isShowing,
    required this.loading,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onBack,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF0E1A16),
                  ),
                  children: [
                    TextSpan(
                      text: '$titleLeft · ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                    TextSpan(
                      text: titleBold,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (!loading)
                _TopStatusChip(
                  label: isShowing ? 'Mostrando' : 'Sin mostrar',
                  isShowing: isShowing,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopStatusChip extends StatelessWidget {
  final String label;
  final bool isShowing;

  const _TopStatusChip({required this.label, required this.isShowing});

  @override
  Widget build(BuildContext context) {
    final bg = isShowing ? const Color(0xFFEAF7EE) : const Color(0xFFFFF5DA);
    final border = isShowing
        ? const Color(0xFF9FD1AE)
        : const Color(0xFFE0C36B);
    final text = isShowing ? const Color(0xFF2F8F57) : const Color(0xFFB58B2B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border.withValues(alpha: 0.9)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.8,
          fontWeight: FontWeight.w900,
          color: text,
        ),
      ),
    );
  }
}

class _DisplaySelectorCard extends StatelessWidget {
  final bool isShowing;
  final bool loading;
  final Future<void> Function() onUseThis;

  const _DisplaySelectorCard({
    required this.isShowing,
    required this.loading,
    required this.onUseThis,
  });

  @override
  Widget build(BuildContext context) {
    final title = isShowing
        ? 'Este Bio-G se está mostrando ahora'
        : 'Este Bio-G no se está mostrando';
    final subtitle = isShowing
        ? 'Los datos visibles en la app corresponden actualmente a este dispositivo.'
        : 'Cámbialo para que la app muestre los datos de este Bio-G.';
    final chipLabel = isShowing ? 'Mostrando' : 'Sin mostrar';
    final chipBg = isShowing
        ? const Color(0xFFEAF7EE)
        : const Color(0xFFFFF5DA);
    final chipText = isShowing
        ? const Color(0xFF2F8F57)
        : const Color(0xFFB58B2B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visualización actual',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0E1A16),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                chipLabel,
                style: TextStyle(
                  fontSize: 11.8,
                  fontWeight: FontWeight.w900,
                  color: chipText,
                ),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.6,
                fontWeight: FontWeight.w800,
                color: Color(0xFF23312D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13.2,
            height: 1.34,
            color: Colors.black.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        if (loading)
          const SizedBox(
            height: 46,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          )
        else if (isShowing)
          Container(
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFEAF7EE),
              border: Border.all(color: const Color(0xFFB8DEC5)),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_rounded,
                    size: 18,
                    color: Color(0xFF2F8F57),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Se está mostrando ahora',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2F8F57),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _PrimaryShowButton(onTap: onUseThis),
      ],
    );
  }
}

class _PrimaryShowButton extends StatelessWidget {
  final Future<void> Function() onTap;

  const _PrimaryShowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3FAF6E).withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async => onTap(),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _StatusBioGScreenState.kBrandTop.withValues(alpha: 0.92),
                    const Color(0xFF2F9E62).withValues(alpha: 0.82),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.24),
                  width: 1,
                ),
              ),
              child: const SizedBox(
                height: 46,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Cambiar a mostrar este',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusRowAssetPlain extends StatelessWidget {
  final String asset;
  final double iconScale;
  final double iconSize;
  final double iconBox;
  final String leftText;
  final String rightText;
  final Color rightTint;

  const _StatusRowAssetPlain({
    required this.asset,
    required this.iconScale,
    required this.iconSize,
    required this.iconBox,
    required this.leftText,
    required this.rightText,
    required this.rightTint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: iconBox,
            height: iconBox,
            child: Center(
              child: Transform.scale(
                scale: iconScale,
                child: Image.asset(
                  asset,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              leftText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0E1A16),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: TweenAnimationBuilder<Color?>(
              key: ValueKey<String>(rightText),
              tween: ColorTween(end: rightTint),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOut,
              builder: (context, color, _) {
                return Text(
                  rightText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color ?? rightTint,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      color: Colors.black.withValues(alpha: 0.06),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 18),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SoftBackground extends StatelessWidget {
  const _SoftBackground();

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

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerButton({required this.label, required this.onTap});

  static const Color _red = Color(0xFFFF3B30);
  static const Color _deep = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _red.withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _red.withValues(alpha: 0.73),
                    _deep.withValues(alpha: 0.58),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
              child: SizedBox(
                height: 46,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
