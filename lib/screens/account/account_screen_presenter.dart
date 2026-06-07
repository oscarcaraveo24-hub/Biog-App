import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_presentation_resolver.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/screens/account/biog_hardware_health.dart';
import 'package:bio_g/services/biog/biog_store.dart';

// Re-export para que account_screen.dart no necesite import adicional.
export 'package:bio_g/models/device_crop_context.dart' show CropLifecycleStatus;

class AccountDeviceCardUiModel {
  final String title;
  final String subtitle;
  final String trailingText;
  final Color trailingColor;
  final Color deviceIconTint;

  const AccountDeviceCardUiModel({
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.trailingColor,
    required this.deviceIconTint,
  });
}

class AccountScreenPresenter {
  static const Color kBrandMid = Color(0xFF3FAF6E);
  static const bool kBioGAccountPreviewDebugLogs = true;

  final Set<String> _loggedPreviewStates = <String>{};

  DeviceCropContext? cropContextForDevice(BioGStore store, String deviceId) {
    return store.cropContextForDevice(deviceId);
  }

  AccountDeviceCardUiModel deviceCardUiModel({
    required BioGDevice device,
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
    required bool isActive,
    required int index,
  }) {
    return deviceCardUiModelFromTelemetry(
      device: device,
      cropContext: cropContext,
      seed: seed,
      isActive: isActive,
      telemetry: null,
    );
  }

  /// Real-data variant of [deviceCardUiModel].
  ///
  /// When [telemetry] is provided we drive the trailing chip and icon
  /// tint from the actual battery / signal / recency. When it is null
  /// after the telemetry source has refreshed, signal degrades to
  /// "Sin señal" instead of inventing numbers.
  AccountDeviceCardUiModel deviceCardUiModelFromTelemetry({
    required BioGDevice device,
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
    required bool isActive,
    required BioGTelemetry? telemetry,
    DateTime? now,
  }) {
    final BioGHardwareHealth health = BioGHardwareHealth.fromTelemetry(
      telemetry,
      now: now,
    );

    final String trailingText;
    final Color trailingColor;

    if (!health.hasReading || !health.hasSignalData) {
      trailingText = 'Sin señal';
      trailingColor = BioGHealthColors.gray;
    } else {
      trailingText = health.signalSubtitle;
      trailingColor = BioGHealthColors.forSignal(health.signalLevel);
    }

    _logPreview(
      'device_id=${device.id} active=$isActive '
      'battery_pct=${health.batteryPct} signal_rssi=${health.signalRssi} '
      'signal=$trailingText sensors_detected=${health.hasSensorData} '
      'system_ok=${health.systemOk} timestamp=${health.lastSeen?.toIso8601String()}',
      onceKey:
          '${device.id}|${health.lastSeen?.toIso8601String()}|${health.signalRssi}|${health.systemOk}',
    );

    return AccountDeviceCardUiModel(
      title: device.name,
      subtitle: deviceSubtitle(
        cropContext: cropContext,
        seed: seed,
        isActive: isActive,
      ),
      trailingText: trailingText,
      trailingColor: trailingColor,
      deviceIconTint: deviceIconTintFromHealth(
        cropContext: cropContext,
        seed: seed,
        status: health.status,
      ),
    );
  }

  Map<String, dynamic> payloadForDevice(
    BioGDevice device,
    int index, {
    required bool isActive,
  }) {
    return <String, dynamic>{
      'id': device.id,
      'telemetryDeviceId': device.telemetryDeviceId,
      'name': device.name,
      'source': 'repo',
      'locationName': device.locationName,
      'isActive': isActive,
    };
  }

  bool hasConfiguredCrop({
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
  }) {
    return CropPresentationResolver.resolve(
      cropContext: cropContext,
      seed: seed,
    ).hasConfiguredCrop;
  }

  String cropHeadline({
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
  }) {
    return CropPresentationResolver.resolve(
      cropContext: cropContext,
      seed: seed,
    ).headlineLabel;
  }

  String cropStageLabel({
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
  }) {
    if (!hasConfiguredCrop(cropContext: cropContext, seed: seed)) {
      return 'Pendiente';
    }

    if (isFallowMode(cropContext: cropContext, seed: seed)) {
      return 'Descanso del suelo';
    }

    // Preferimos lifecycleStatus del contexto formal; fallback a seed legacy.
    if (cropContext != null) {
      switch (cropContext.lifecycleStatus) {
        case CropLifecycleStatus.planted:
          return 'Ya sembrado';
        case CropLifecycleStatus.planned:
          return 'Aún no siembro';
        case CropLifecycleStatus.fallow:
          return 'Descanso del suelo';
      }
    }

    if (seed?.status == SowingStatus.planted) return 'Ya sembrado';
    if (seed?.status == SowingStatus.planned) return 'Aún no siembro';

    return 'Configurado';
  }

  String deviceSubtitle({
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
    required bool isActive,
  }) {
    if (!hasConfiguredCrop(cropContext: cropContext, seed: seed)) {
      return isActive
          ? 'Mostrándose ahora · Sin cultivo configurado'
          : 'Pendiente · Sin cultivo configurado';
    }

    final headline = cropHeadline(cropContext: cropContext, seed: seed);
    final stage = cropStageLabel(cropContext: cropContext, seed: seed);

    if (isActive) {
      return 'Mostrándose ahora · $headline · $stage';
    }

    return '$headline · $stage';
  }

  int severityFromBattery(int batteryPct) {
    if (batteryPct < 10) return 2;
    if (batteryPct < 45) return 1;
    return 0;
  }

  int severityFromSignal(String signalLabel) {
    final t = signalLabel.trim().toLowerCase();
    if (t.contains('sin')) return 2;
    if (t.contains('baja')) return 2;
    if (t.contains('media')) return 1;
    return 0;
  }

  int severityFromSensors(String sensorsLabel) {
    final t = sensorsLabel.trim().toLowerCase();
    if (t.isEmpty || t == '—' || t.contains('fallo') || t.contains('error')) {
      return 2;
    }
    if (t.contains('inestable') || t.contains('atenc')) return 1;
    return 0;
  }

  int severityFromSystem(String systemLabel) {
    final t = systemLabel.trim().toLowerCase();
    if (t.contains('crít') || t.contains('crit') || t.contains('error')) {
      return 2;
    }
    if (t.contains('atenc') || t.contains('warning') || t.contains('warn')) {
      return 1;
    }
    return 0;
  }

  String healthFromMetrics({
    required int batteryPct,
    required String signalLabel,
    required String sensorsLabel,
    required String systemLabel,
  }) {
    final worst = <int>[
      severityFromBattery(batteryPct),
      severityFromSignal(signalLabel),
      severityFromSensors(sensorsLabel),
      severityFromSystem(systemLabel),
    ].reduce((a, b) => a > b ? a : b);

    if (worst >= 2) return 'bad';
    if (worst == 1) return 'warn';
    return 'good';
  }

  Color leafTintFromHealth(String health) {
    final h = health.toLowerCase();
    if (h == 'bad') return const Color(0xFFB2554E);
    if (h == 'warn') return const Color(0xFFB58B2B);
    return kBrandMid;
  }

  Color deviceIconTint({
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
    required String health,
  }) {
    if (!hasConfiguredCrop(cropContext: cropContext, seed: seed)) {
      return Colors.black38;
    }
    return leafTintFromHealth(health);
  }

  Color deviceIconTintFromHealth({
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
    required BioGHardwareStatus status,
  }) {
    if (!hasConfiguredCrop(cropContext: cropContext, seed: seed)) {
      return Colors.black38;
    }
    return BioGHealthColors.forStatus(status);
  }

  int stableHash(String value) {
    int h = 0;
    for (int i = 0; i < value.length; i++) {
      h = (h * 31 + value.codeUnitAt(i)) & 0x7fffffff;
    }
    return h;
  }

  int clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  String normalizedCropId(String? raw) => CropCatalog.canonicalCropKey(raw);

  String cropDisplayName(String cropId) => CropCatalog.cropDisplayName(cropId);

  bool isLegacyGenericAlias(String raw) {
    final normalized = raw.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'generic' ||
        normalized == 'genérico' ||
        normalized == 'generico' ||
        normalized == 'generic_maize' ||
        normalized == 'generic_corn' ||
        normalized == 'perfil genérico' ||
        normalized == 'generic_bean' ||
        normalized == 'generic_wheat' ||
        normalized == 'generic_barley' ||
        normalized == 'generic_oat';
  }

  bool isFallowMode({
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
  }) {
    // Fuente autoritativa: lifecycleStatus del contexto formal.
    if (cropContext != null) {
      return cropContext.lifecycleStatus == CropLifecycleStatus.fallow;
    }

    // Fallback legacy: seed status.
    return seed?.status == SowingStatus.skip;
  }

  void _logPreview(String message, {required String onceKey}) {
    if (!_loggedPreviewStates.add(onceKey)) return;
    if (!kDebugMode) return;
    if (!kBioGAccountPreviewDebugLogs) return;
    debugPrint('[BioG/AccountPreview] $message');
  }
}
