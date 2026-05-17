import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:bio_g/models/biog_telemetry.dart';

/// Battery state buckets used by Cuenta > Mis Bio-G.
enum BioGBatteryLevel { unknown, critical, low, medium, good }

/// Signal/RSSI buckets used by Cuenta > Mis Bio-G.
enum BioGSignalLevel { unknown, weak, fair, good, excellent }

/// Connection recency buckets derived from `telemetry.timestamp`.
enum BioGConnectionState { unknown, active, recent, stale }

/// Aggregate hardware health used to color the row chip / icon.
enum BioGHardwareStatus { unknown, offline, critical, warning, stable }

/// Temporary, safe debug traces for Cuenta > Mis BioG hardware state.
/// Flip to false when the data path has been verified in QA.
const bool kBioGHardwareDebugLogs = true;

/// Pure value object that classifies the latest telemetry reading of a
/// Bio-G device into the human-readable buckets the UI needs.
///
/// Source of truth: a [BioGTelemetry] from Supabase (or its offline
/// cache). When the reading is null OR too old, we degrade gracefully
/// to "unknown / offline" rather than inventing data.
@immutable
class BioGHardwareHealth {
  const BioGHardwareHealth({
    required this.batteryPct,
    required this.signalRssi,
    required this.lastSeen,
    required this.batteryLevel,
    required this.signalLevel,
    required this.connectionState,
    required this.status,
    required this.summaryText,
    required this.connectionText,
    required this.batterySubtitle,
    required this.signalSubtitle,
    required this.hasReading,
    required this.hasBatteryData,
    required this.hasSignalData,
    required this.hasSensorData,
    required this.hasRecentReading,
    required this.systemOk,
  });

  /// Real battery percent from telemetry, clamped to [0, 100]. Null when
  /// no reading exists.
  final double? batteryPct;

  /// Real RSSI from telemetry. Null when no reading exists.
  final int? signalRssi;

  /// Timestamp of the latest reading (UTC). Null when no reading exists.
  final DateTime? lastSeen;

  final BioGBatteryLevel batteryLevel;
  final BioGSignalLevel signalLevel;
  final BioGConnectionState connectionState;
  final BioGHardwareStatus status;

  /// One-line summary safe to put in headers / chips.
  /// Example: "Sistema estable" / "Sin datos recientes" / "Batería baja".
  final String summaryText;

  /// Friendly recency line. Example: "Activo ahora",
  /// "Última lectura hace 3 min", "Sin datos recientes".
  final String connectionText;

  /// Friendly battery subtitle. Example: "Óptima", "Media", "Baja",
  /// "Crítica", "Sin datos".
  final String batterySubtitle;

  /// Friendly signal subtitle. Example: "Excelente", "Buena", "Regular",
  /// "Débil", "Sin datos".
  final String signalSubtitle;

  /// `true` when a real telemetry reading exists for this device,
  /// regardless of how old it is. Old readings still display their
  /// values; only the recency text and the overall connection state
  /// change. Mirrors what Dashboard does with `store.live` (it shows
  /// the latest known values without hiding them by age).
  final bool hasReading;

  /// Real telemetry row includes battery_pct.
  final bool hasBatteryData;

  /// Real telemetry row includes signal_rssi.
  final bool hasSignalData;

  /// Real telemetry row includes at least one sensor value.
  final bool hasSensorData;

  /// Latest telemetry is fresh enough for connection/system state.
  final bool hasRecentReading;

  /// System-level OK derived from recent reading + battery + signal +
  /// sensors, with no critical battery/signal condition.
  final bool systemOk;

  /// Recency thresholds.
  ///
  /// `kActiveWindow` is the upper bound for "Activo ahora". The remote
  /// telemetry source polls Supabase every ~60s, and a hardware cadence
  /// can realistically be 1–2 readings per minute, so 5 minutes is the
  /// practical edge of "live".
  ///
  /// `kStaleAfter` is when we stop calling the device "connected" and
  /// switch to "Sin datos recientes". The values themselves keep
  /// rendering — only the chip color and the recency text change.
  static const Duration kActiveWindow = Duration(minutes: 5);
  static const Duration kStaleAfter = Duration(hours: 6);
  static final Set<String> _loggedDebugStates = <String>{};

  factory BioGHardwareHealth.unknown() {
    return const BioGHardwareHealth(
      batteryPct: null,
      signalRssi: null,
      lastSeen: null,
      batteryLevel: BioGBatteryLevel.unknown,
      signalLevel: BioGSignalLevel.unknown,
      connectionState: BioGConnectionState.unknown,
      status: BioGHardwareStatus.unknown,
      summaryText: 'Sin datos',
      connectionText: 'Sin datos',
      batterySubtitle: 'Sin datos',
      signalSubtitle: 'Sin datos',
      hasReading: false,
      hasBatteryData: false,
      hasSignalData: false,
      hasSensorData: false,
      hasRecentReading: false,
      systemOk: false,
    );
  }

  /// Build a hardware-health snapshot from the latest telemetry reading.
  ///
  /// Important contract: when [telemetry] is non-null, we ALWAYS surface
  /// its real values (battery/RSSI/lastSeen). Even if the reading is
  /// hours old, we still show the last known values — exactly like
  /// Dashboard does — and only adjust the connection text and overall
  /// status to communicate the recency. This mirrors the user's spec:
  /// "Sin datos" is reserved for the case where no reading has ever
  /// been received for this device, NOT for stale readings.
  factory BioGHardwareHealth.fromTelemetry(
    BioGTelemetry? telemetry, {
    DateTime? now,
  }) {
    if (telemetry == null) {
      return BioGHardwareHealth.unknown();
    }

    final DateTime reference = (now ?? DateTime.now()).toUtc();
    final DateTime lastSeen = telemetry.timestamp.toUtc();
    final Duration age = reference.difference(lastSeen);

    final BioGConnectionState connection;
    if (age.isNegative || age <= kActiveWindow) {
      connection = BioGConnectionState.active;
    } else if (age <= kStaleAfter) {
      connection = BioGConnectionState.recent;
    } else {
      connection = BioGConnectionState.stale;
    }

    final double? rawBattery = telemetry.batteryPct;
    final double? battery = rawBattery == null
        ? null
        : rawBattery.clamp(0.0, 100.0).toDouble();
    final BioGBatteryLevel batteryLevel = battery == null
        ? BioGBatteryLevel.unknown
        : _batteryLevelFor(battery);

    final int? rssi = telemetry.signalRssi;
    final BioGSignalLevel signalLevel = rssi == null
        ? BioGSignalLevel.unknown
        : _signalLevelFor(rssi);
    final bool hasBatteryData = battery != null;
    final bool hasSignalData = rssi != null;
    final bool hasSensorData =
        telemetry.hasSensorData || _telemetryHasSensorValues(telemetry);
    final bool hasRecentReading =
        connection == BioGConnectionState.active ||
        connection == BioGConnectionState.recent;
    final bool systemOk =
        hasRecentReading &&
        hasBatteryData &&
        hasSignalData &&
        hasSensorData &&
        batteryLevel != BioGBatteryLevel.critical &&
        batteryLevel != BioGBatteryLevel.low &&
        signalLevel != BioGSignalLevel.weak;

    final BioGHardwareStatus status = _statusFor(
      connection: connection,
      battery: batteryLevel,
      signal: signalLevel,
      hasBatteryData: hasBatteryData,
      hasSignalData: hasSignalData,
      hasSensorData: hasSensorData,
    );

    _log(
      'device_id=${telemetry.deviceId} '
      'timestamp=${lastSeen.toIso8601String()} '
      'battery_pct=$battery signal_rssi=$rssi '
      'sensors_detected=$hasSensorData recent=$hasRecentReading '
      'system_ok=$systemOk connection=$connection status=$status',
      onceKey:
          '${telemetry.deviceId}|${lastSeen.toIso8601String()}|$battery|$rssi|$hasSensorData|$systemOk|$connection',
    );

    return BioGHardwareHealth(
      batteryPct: battery,
      signalRssi: rssi,
      lastSeen: lastSeen,
      batteryLevel: batteryLevel,
      signalLevel: signalLevel,
      connectionState: connection,
      status: status,
      summaryText: _summaryTextFor(
        connection: connection,
        battery: batteryLevel,
        signal: signalLevel,
        hasBatteryData: hasBatteryData,
        hasSignalData: hasSignalData,
        hasSensorData: hasSensorData,
        systemOk: systemOk,
      ),
      connectionText: _connectionTextFor(connection: connection, age: age),
      batterySubtitle: _batterySubtitleFor(batteryLevel),
      signalSubtitle: _signalSubtitleFor(signalLevel),
      hasReading: true,
      hasBatteryData: hasBatteryData,
      hasSignalData: hasSignalData,
      hasSensorData: hasSensorData,
      hasRecentReading: hasRecentReading,
      systemOk: systemOk,
    );
  }

  static BioGBatteryLevel _batteryLevelFor(double batteryPct) {
    if (batteryPct < 15) return BioGBatteryLevel.critical;
    if (batteryPct < 30) return BioGBatteryLevel.low;
    if (batteryPct < 60) return BioGBatteryLevel.medium;
    return BioGBatteryLevel.good;
  }

  static BioGSignalLevel _signalLevelFor(int rssi) {
    if (rssi >= -65) return BioGSignalLevel.excellent;
    if (rssi >= -75) return BioGSignalLevel.good;
    if (rssi >= -85) return BioGSignalLevel.fair;
    return BioGSignalLevel.weak;
  }

  static bool _telemetryHasSensorValues(BioGTelemetry telemetry) {
    for (final value in <double>[
      telemetry.airTempC,
      telemetry.airHumidityPct,
      telemetry.soilMoisturePct,
      telemetry.soilTempC,
      telemetry.ph,
      telemetry.ec,
      telemetry.resistance,
      telemetry.n,
      telemetry.p,
      telemetry.k,
    ]) {
      if (value.isFinite && value != 0) return true;
    }
    return false;
  }

  static BioGHardwareStatus _statusFor({
    required BioGConnectionState connection,
    required BioGBatteryLevel battery,
    required BioGSignalLevel signal,
    required bool hasBatteryData,
    required bool hasSignalData,
    required bool hasSensorData,
  }) {
    if (connection == BioGConnectionState.unknown) {
      return BioGHardwareStatus.unknown;
    }

    // Stale (>30 min) trumps everything: we know there's a reading,
    // but the device hasn't reported in a long time, so call it offline
    // even if the last known battery was 100%.
    if (connection == BioGConnectionState.stale) {
      return BioGHardwareStatus.offline;
    }

    if (!hasBatteryData && !hasSignalData && !hasSensorData) {
      return BioGHardwareStatus.unknown;
    }

    if (!hasBatteryData || !hasSignalData || !hasSensorData) {
      return BioGHardwareStatus.warning;
    }

    if (battery == BioGBatteryLevel.critical ||
        signal == BioGSignalLevel.weak) {
      return BioGHardwareStatus.critical;
    }

    if (battery == BioGBatteryLevel.low) {
      return BioGHardwareStatus.warning;
    }

    if (battery == BioGBatteryLevel.unknown &&
        signal == BioGSignalLevel.unknown) {
      return BioGHardwareStatus.unknown;
    }

    if (battery == BioGBatteryLevel.unknown ||
        signal == BioGSignalLevel.unknown) {
      return BioGHardwareStatus.warning;
    }

    return BioGHardwareStatus.stable;
  }

  static String _summaryTextFor({
    required BioGConnectionState connection,
    required BioGBatteryLevel battery,
    required BioGSignalLevel signal,
    required bool hasBatteryData,
    required bool hasSignalData,
    required bool hasSensorData,
    required bool systemOk,
  }) {
    if (connection == BioGConnectionState.stale) {
      return 'Sin datos recientes';
    }
    if (connection == BioGConnectionState.unknown) return 'Sin datos';
    if (!hasBatteryData && !hasSignalData && !hasSensorData) {
      return 'Sin datos';
    }
    if (systemOk) {
      return 'Sistema OK';
    }
    if (battery == BioGBatteryLevel.critical) {
      return 'Batería crítica';
    }
    if (signal == BioGSignalLevel.weak) {
      return 'Revisar señal';
    }
    if (battery == BioGBatteryLevel.low) {
      return 'Batería baja';
    }
    if (!hasSensorData) {
      return hasBatteryData || hasSignalData
          ? 'Telemetría recibida'
          : 'Sensores sin datos';
    }
    if (!hasBatteryData || !hasSignalData) {
      return 'Datos parciales';
    }
    return 'Funcionando';
  }

  static String _connectionTextFor({
    required BioGConnectionState connection,
    required Duration age,
  }) {
    switch (connection) {
      case BioGConnectionState.active:
        return 'Activo ahora';
      case BioGConnectionState.recent:
        if (age.inHours >= 1) {
          final h = age.inHours;
          return 'Última lectura hace $h h';
        }
        final minutes = age.inMinutes.clamp(1, 999);
        return 'Última lectura hace $minutes min';
      case BioGConnectionState.stale:
        if (age.inDays >= 1) {
          final d = age.inDays;
          return 'Sin datos recientes · $d d';
        }
        if (age.inHours >= 1) {
          final h = age.inHours;
          return 'Sin datos recientes · $h h';
        }
        final m = age.inMinutes.clamp(1, 999);
        return 'Sin datos recientes · $m min';
      case BioGConnectionState.unknown:
        return 'Sin datos';
    }
  }

  static String _batterySubtitleFor(BioGBatteryLevel level) {
    switch (level) {
      case BioGBatteryLevel.good:
        return 'Óptima';
      case BioGBatteryLevel.medium:
        return 'Media';
      case BioGBatteryLevel.low:
        return 'Baja';
      case BioGBatteryLevel.critical:
        return 'Crítica';
      case BioGBatteryLevel.unknown:
        return 'Sin datos';
    }
  }

  static String _signalSubtitleFor(BioGSignalLevel level) {
    switch (level) {
      case BioGSignalLevel.excellent:
        return 'Excelente';
      case BioGSignalLevel.good:
        return 'Buena';
      case BioGSignalLevel.fair:
        return 'Regular';
      case BioGSignalLevel.weak:
        return 'Débil';
      case BioGSignalLevel.unknown:
        return 'Sin datos';
    }
  }

  static void _log(String message, {required String onceKey}) {
    if (!_loggedDebugStates.add(onceKey)) return;
    if (!kDebugMode) return;
    if (!kBioGHardwareDebugLogs) return;
    debugPrint('[BioG/Hardware] $message');
  }
}

/// Brand-aware color tokens for the hardware health visualization.
class BioGHealthColors {
  static const Color brandMid = Color(0xFF3FAF6E);
  static const Color brandSoft = Color(0xFF6FC58E);
  static const Color amber = Color(0xFFB58B2B);
  static const Color amberSoft = Color(0xFFD4A646);
  static const Color red = Color(0xFFB2554E);
  static const Color redSoft = Color(0xFFD06D64);
  static const Color gray = Color(0xFF8B9A93);

  static Color forBattery(BioGBatteryLevel level) {
    switch (level) {
      case BioGBatteryLevel.good:
        return brandMid;
      case BioGBatteryLevel.medium:
        return amber;
      case BioGBatteryLevel.low:
        return amberSoft;
      case BioGBatteryLevel.critical:
        return red;
      case BioGBatteryLevel.unknown:
        return gray;
    }
  }

  static Color forSignal(BioGSignalLevel level) {
    switch (level) {
      case BioGSignalLevel.excellent:
        return brandMid;
      case BioGSignalLevel.good:
        return brandSoft;
      case BioGSignalLevel.fair:
        return amber;
      case BioGSignalLevel.weak:
        return redSoft;
      case BioGSignalLevel.unknown:
        return gray;
    }
  }

  static Color forStatus(BioGHardwareStatus status) {
    switch (status) {
      case BioGHardwareStatus.stable:
        return brandMid;
      case BioGHardwareStatus.warning:
        return amber;
      case BioGHardwareStatus.critical:
        return red;
      case BioGHardwareStatus.offline:
      case BioGHardwareStatus.unknown:
        return gray;
    }
  }
}
