// lib/core/notifications/notification_preferences.dart
//
// Preferencias de notificación con significado real.
//
// Lo que había: un interruptor "Notificaciones" en Cuenta que persistía un
// `bool` en SharedPreferences y que **nadie leía** salvo para volver a
// pintarse a sí mismo. Encenderlo o apagarlo no cambiaba absolutamente nada.
//
// Lo que hay ahora: preferencias por categoría, umbral de severidad y horario
// silencioso, que la capa de entrega consulta antes de mostrar cualquier cosa.
// Funciona hoy con avisos dentro de la app; cuando se integre push o
// notificaciones locales, esas capas leen estas mismas preferencias y el
// comportamiento que el usuario configuró se respeta sin volver a tocarlo.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bio_g/core/agro/agronomic_event.dart';

/// Familias de aviso que el usuario puede activar por separado.
enum NotificationCategory {
  /// Riego: regar, esperar, revisar.
  irrigation,

  /// Nutrición y fertilización.
  nutrition,

  /// Riesgos ambientales: helada, calor, lluvia intensa.
  environment,

  /// Estado del equipo: batería, señal, sensor sin reportar.
  hardware,

  /// Cambios de etapa y avisos del ciclo del cultivo.
  cropCycle,

  /// Cuenta y suscripción.
  account,
}

extension NotificationCategoryX on NotificationCategory {
  String get labelEs {
    switch (this) {
      case NotificationCategory.irrigation:
        return 'Riego';
      case NotificationCategory.nutrition:
        return 'Nutrición';
      case NotificationCategory.environment:
        return 'Clima y riesgos';
      case NotificationCategory.hardware:
        return 'Estado del Bio-G';
      case NotificationCategory.cropCycle:
        return 'Ciclo del cultivo';
      case NotificationCategory.account:
        return 'Cuenta';
    }
  }

  String get storageKey => 'biog_notif_cat_${name}_v1';

  /// Categoría a la que pertenece un evento agronómico.
  static NotificationCategory fromEventType(AgronomicEventType type) {
    switch (type) {
      case AgronomicEventType.irrigationRecommended:
      case AgronomicEventType.lowMoisture:
      case AgronomicEventType.highMoisture:
      case AgronomicEventType.stableMoisture:
        return NotificationCategory.irrigation;

      case AgronomicEventType.fertilizationRecommended:
      case AgronomicEventType.npkReading:
      case AgronomicEventType.nutrientImbalance:
      case AgronomicEventType.nitrogenLow:
      case AgronomicEventType.nitrogenHigh:
      case AgronomicEventType.phosphorusLow:
      case AgronomicEventType.phosphorusHigh:
      case AgronomicEventType.potassiumLow:
      case AgronomicEventType.potassiumHigh:
        return NotificationCategory.nutrition;

      case AgronomicEventType.frostWarning:
      case AgronomicEventType.highAirTemp:
      case AgronomicEventType.lowAirHumidity:
      case AgronomicEventType.highAirHumidity:
      case AgronomicEventType.heatStress:
      case AgronomicEventType.coldStress:
        return NotificationCategory.environment;

      case AgronomicEventType.genericMode:
      case AgronomicEventType.preSowing:
      case AgronomicEventType.cropActivated:
      case AgronomicEventType.stageTransition:
        return NotificationCategory.cropCycle;

      case AgronomicEventType.lowPh:
      case AgronomicEventType.highPh:
      case AgronomicEventType.stablePh:
      case AgronomicEventType.soilCompaction:
      case AgronomicEventType.goodSoilStructure:
      case AgronomicEventType.stableSoilTemp:
      case AgronomicEventType.stableSoil:
      case AgronomicEventType.combinedStress:
      case AgronomicEventType.recovery:
        return NotificationCategory.cropCycle;
    }
  }
}

/// Umbral mínimo de severidad para molestar al usuario.
enum NotificationSeverityThreshold { all, cautionAndAbove, warningAndAbove, criticalOnly }

extension NotificationSeverityThresholdX on NotificationSeverityThreshold {
  String get labelEs {
    switch (this) {
      case NotificationSeverityThreshold.all:
        return 'Todo';
      case NotificationSeverityThreshold.cautionAndAbove:
        return 'Atención o más';
      case NotificationSeverityThreshold.warningAndAbove:
        return 'Advertencia o más';
      case NotificationSeverityThreshold.criticalOnly:
        return 'Solo crítico';
    }
  }

  int get minRank {
    switch (this) {
      case NotificationSeverityThreshold.all:
        return 0;
      case NotificationSeverityThreshold.cautionAndAbove:
        return 1;
      case NotificationSeverityThreshold.warningAndAbove:
        return 2;
      case NotificationSeverityThreshold.criticalOnly:
        return 3;
    }
  }

  static int rankOf(AgronomicEventSeverity severity) {
    switch (severity) {
      case AgronomicEventSeverity.info:
        return 0;
      case AgronomicEventSeverity.caution:
        return 1;
      case AgronomicEventSeverity.warning:
        return 2;
      case AgronomicEventSeverity.critical:
        return 3;
    }
  }
}

@immutable
class NotificationPreferences {
  const NotificationPreferences({
    this.enabled = true,
    this.categories = const <NotificationCategory>{
      NotificationCategory.irrigation,
      NotificationCategory.nutrition,
      NotificationCategory.environment,
      NotificationCategory.hardware,
      NotificationCategory.cropCycle,
      NotificationCategory.account,
    },
    this.threshold = NotificationSeverityThreshold.cautionAndAbove,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 6,
    this.quietHoursEnabled = true,
  });

  /// Interruptor maestro. Es el mismo que ya existía en Cuenta, ahora con
  /// consecuencias.
  final bool enabled;

  final Set<NotificationCategory> categories;
  final NotificationSeverityThreshold threshold;

  /// Horario silencioso, en hora local 0-23. Puede cruzar la medianoche.
  final int quietHoursStart;
  final int quietHoursEnd;
  final bool quietHoursEnabled;

  static const NotificationPreferences defaults = NotificationPreferences();

  bool isQuietAt(DateTime localTime) {
    if (!quietHoursEnabled) return false;
    final h = localTime.hour;
    if (quietHoursStart == quietHoursEnd) return false;
    if (quietHoursStart < quietHoursEnd) {
      return h >= quietHoursStart && h < quietHoursEnd;
    }
    // Cruza medianoche: 22 -> 6.
    return h >= quietHoursStart || h < quietHoursEnd;
  }

  /// Decide si un evento debe entregarse.
  ///
  /// Lo crítico atraviesa el horario silencioso a propósito: una helada a las
  /// tres de la madrugada es exactamente el aviso que justifica despertar a
  /// alguien. Lo demás espera.
  bool shouldDeliver(AgronomicEvent event, {required DateTime localTime}) {
    if (!enabled) return false;

    final category = NotificationCategoryX.fromEventType(event.type);
    if (!categories.contains(category)) return false;

    final rank = NotificationSeverityThresholdX.rankOf(event.severity);
    if (rank < threshold.minRank) return false;

    final isCritical =
        event.severity == AgronomicEventSeverity.critical || event.isCritical;
    if (isQuietAt(localTime) && !isCritical) return false;

    return true;
  }

  NotificationPreferences copyWith({
    bool? enabled,
    Set<NotificationCategory>? categories,
    NotificationSeverityThreshold? threshold,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool? quietHoursEnabled,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      categories: categories ?? this.categories,
      threshold: threshold ?? this.threshold,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    );
  }

  NotificationPreferences withCategory(
    NotificationCategory category, {
    required bool active,
  }) {
    final next = Set<NotificationCategory>.from(categories);
    if (active) {
      next.add(category);
    } else {
      next.remove(category);
    }
    return copyWith(categories: next);
  }
}

/// Persistencia de las preferencias.
class NotificationPreferencesStore {
  static const String _enabledKey = 'profile_notifications';
  static const String _thresholdKey = 'biog_notif_threshold_v1';
  static const String _quietEnabledKey = 'biog_notif_quiet_enabled_v1';
  static const String _quietStartKey = 'biog_notif_quiet_start_v1';
  static const String _quietEndKey = 'biog_notif_quiet_end_v1';

  /// Carga las preferencias guardadas.
  ///
  /// Reutiliza a propósito la clave `profile_notifications` que ya existía,
  /// para que quien tenga el interruptor apagado lo siga teniendo apagado tras
  /// actualizar.
  Future<NotificationPreferences> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final enabled = prefs.getBool(_enabledKey) ?? true;

      final thresholdName = prefs.getString(_thresholdKey);
      final threshold = NotificationSeverityThreshold.values.firstWhere(
        (t) => t.name == thresholdName,
        orElse: () => NotificationSeverityThreshold.cautionAndAbove,
      );

      final active = <NotificationCategory>{};
      for (final c in NotificationCategory.values) {
        if (prefs.getBool(c.storageKey) ?? true) active.add(c);
      }

      return NotificationPreferences(
        enabled: enabled,
        categories: active,
        threshold: threshold,
        quietHoursEnabled: prefs.getBool(_quietEnabledKey) ?? true,
        quietHoursStart: prefs.getInt(_quietStartKey) ?? 22,
        quietHoursEnd: prefs.getInt(_quietEndKey) ?? 6,
      );
    } catch (_) {
      return NotificationPreferences.defaults;
    }
  }

  Future<void> save(NotificationPreferences value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value.enabled);
      await prefs.setString(_thresholdKey, value.threshold.name);
      await prefs.setBool(_quietEnabledKey, value.quietHoursEnabled);
      await prefs.setInt(_quietStartKey, value.quietHoursStart);
      await prefs.setInt(_quietEndKey, value.quietHoursEnd);
      for (final c in NotificationCategory.values) {
        await prefs.setBool(c.storageKey, value.categories.contains(c));
      }
    } catch (_) {
      // Guardar preferencias no puede tumbar la pantalla de ajustes.
    }
  }
}
