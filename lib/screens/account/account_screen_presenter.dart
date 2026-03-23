import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_presentation_resolver.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';
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
    final metrics = simulatedMetricsForDevice(
      device,
      index,
      isActive: isActive,
    );

    final int battery = (metrics['batteryPct'] ?? 92) as int;
    final String signal = (metrics['signalLabel'] ?? 'Buena').toString();
    final String sensors = (metrics['sensorsLabel'] ?? 'OK').toString();
    final String system = (metrics['systemLabel'] ?? 'Estable').toString();

    final health = healthFromMetrics(
      batteryPct: battery,
      signalLabel: signal,
      sensorsLabel: sensors,
      systemLabel: system,
    );

    final trailingText = isActive
        ? 'Activo'
        : (health == 'bad')
        ? 'Crítico'
        : (health == 'warn')
        ? 'Atención'
        : '';

    return AccountDeviceCardUiModel(
      title: device.name,
      subtitle: deviceSubtitle(
        cropContext: cropContext,
        seed: seed,
        isActive: isActive,
      ),
      trailingText: trailingText,
      trailingColor: isActive ? kBrandMid : leafTintFromHealth(health),
      deviceIconTint: deviceIconTint(
        cropContext: cropContext,
        seed: seed,
        health: health,
      ),
    );
  }

  Map<String, dynamic> payloadForDevice(
    BioGDevice device,
    int index, {
    required bool isActive,
  }) {
    final metrics = simulatedMetricsForDevice(
      device,
      index,
      isActive: isActive,
    );

    final int battery = (metrics['batteryPct'] ?? 92) as int;
    final String signal = (metrics['signalLabel'] ?? 'Buena').toString();
    final String sensors = (metrics['sensorsLabel'] ?? 'OK').toString();
    final String system = (metrics['systemLabel'] ?? 'Estable').toString();

    final String health = healthFromMetrics(
      batteryPct: battery,
      signalLabel: signal,
      sensorsLabel: sensors,
      systemLabel: system,
    );

    return <String, dynamic>{
      'id': device.id,
      'name': device.name,
      'health': health,
      'batteryPct': battery,
      'signalLabel': signal,
      'sensorsLabel': sensors,
      'systemLabel': system,
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

  String statusLabelFromDevice(BioGDevice device, {required bool isActive}) {
    final raw = device.status.toString().toLowerCase();

    if (raw.contains('connecting') || raw.contains('conectando')) {
      return 'Conectando';
    }
    if (raw.contains('error')) return 'Error';
    if (raw.contains('offline') || raw.contains('sin')) return 'Sin señal';
    if (raw.contains('warn') || raw.contains('atenc')) return 'Atención';

    if (isActive) return 'Conectado';
    return 'Pendiente';
  }

  Map<String, dynamic> simulatedMetricsForDevice(
    BioGDevice device,
    int index, {
    required bool isActive,
  }) {
    if (index == 0 && isActive) {
      return <String, dynamic>{
        'batteryPct': 92,
        'signalLabel': 'Buena',
        'sensorsLabel': 'OK',
        'systemLabel': 'Estable',
      };
    }

    final status = statusLabelFromDevice(
      device,
      isActive: isActive,
    ).toLowerCase();

    final seed = stableHash(device.id);

    int battery = 92;
    String signal = 'Buena';
    String sensors = 'OK';
    String system = 'Estable';

    if (status.contains('conectando')) {
      battery = 68;
      signal = 'Media';
      sensors = 'OK';
      system = 'Atención';
    } else if (status.contains('atención') || status.contains('atenc')) {
      battery = 38;
      signal = 'Media';
      sensors = 'Inestable';
      system = 'Atención';
    } else if (status.contains('sin señal')) {
      battery = 23;
      signal = 'Sin señal';
      sensors = '—';
      system = 'Atención';
    } else if (status.contains('error')) {
      battery = 7;
      signal = 'Sin señal';
      sensors = 'Fallo';
      system = 'Crítico';
    } else if (status.contains('pendiente')) {
      battery = 99;
      signal = 'Media';
      sensors = '—';
      system = 'Estable';
    } else if (status.contains('conectado')) {
      battery = 86;
      signal = 'Buena';
      sensors = 'OK';
      system = 'Estable';
    }

    final deltaB = (seed % 41) - 20;
    battery = clampInt(battery + deltaB, 1, 100);

    if (!signal.toLowerCase().contains('sin')) {
      final sigPick = seed % 6;
      signal = (sigPick == 0 || sigPick == 3) ? 'Media' : 'Buena';
    }

    if (sensors != '—' && !sensors.toLowerCase().contains('fallo')) {
      final senPick = (seed ~/ 7) % 10;
      sensors = (senPick == 0) ? 'Inestable' : 'OK';
    }

    if (!system.toLowerCase().contains('crít') &&
        !system.toLowerCase().contains('crit')) {
      final sysPick = (seed ~/ 13) % 12;
      system = (sysPick == 0) ? 'Atención' : 'Estable';
    }

    if (battery < 10) {
      system = 'Crítico';
    } else if (battery < 45 && system == 'Estable') {
      system = 'Atención';
    }

    if (status.contains('pendiente')) {
      sensors = '—';
    }

    return <String, dynamic>{
      'batteryPct': battery,
      'signalLabel': signal,
      'sensorsLabel': sensors,
      'systemLabel': system,
    };
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
}
