// lib/core/billing/biog_plan.dart
//
// Planes Básico / Pro y lo que cada uno habilita.
//
// Qué había antes: `UserProfile.subscriptionStatus`, un `String` libre con
// valor por defecto `'trial'` que se leía de Supabase, se propagaba en
// `copyWith` y **ningún `if` de la aplicación evaluaba**. Cero gating, cero
// tipos, cero límites. Era una bandera muerta, exactamente igual que
// `requiresConfirmation` en el planificador de fertilización.
//
// Nota de la auditoría: el plan de cierre señalaba `isGenericMode` como el
// campo sobrecargado que representaba suscripción, cultivo y dispositivo a la
// vez. No es cierto: `isGenericMode` es puramente agronómico ("no hay cultivo
// ni variedad concreta") y sus 25 usos son de perfil de cultivo. El campo que
// hay que cablear es `subscriptionStatus`, y es lo que hace este archivo.
//
// Principio de degradación (Fundacional 2.1): que una suscripción caduque
// NUNCA borra configuración ni historial local. Se apaga lo que el plan cubría,
// se conserva todo lo que el agricultor capturó. Volver a pagar restaura, no
// reconstruye.

import 'package:flutter/foundation.dart';

enum BiogPlan {
  /// Lecturas crudas, unidades, gráficas, historial local y clima.
  basico,

  /// Todo lo de Básico más interpretación agronómica por cultivo y etapa,
  /// motor de riego y nutrición, alertas personalizadas, nube, consulta remota
  /// y portal.
  pro,
}

extension BiogPlanX on BiogPlan {
  String get labelEs {
    switch (this) {
      case BiogPlan.basico:
        return 'Básico';
      case BiogPlan.pro:
        return 'Pro';
    }
  }

  String get storageKey {
    switch (this) {
      case BiogPlan.basico:
        return 'basico';
      case BiogPlan.pro:
        return 'pro';
    }
  }
}

/// Estado del ciclo de vida de la suscripción, independiente del plan.
enum BiogPlanStatus {
  /// Periodo de prueba inicial.
  trial,

  /// Pagado y vigente.
  active,

  /// Venció pero sigue dentro del periodo de gracia: se conserva el acceso.
  grace,

  /// Venció y se agotó la gracia. Se degrada a Básico sin borrar nada.
  expired,

  /// Nunca hubo suscripción.
  none,
}

extension BiogPlanStatusX on BiogPlanStatus {
  String get labelEs {
    switch (this) {
      case BiogPlanStatus.trial:
        return 'Prueba';
      case BiogPlanStatus.active:
        return 'Activa';
      case BiogPlanStatus.grace:
        return 'Por vencer';
      case BiogPlanStatus.expired:
        return 'Vencida';
      case BiogPlanStatus.none:
        return 'Sin suscripción';
    }
  }

  /// True si el estado da derecho a las funciones del plan contratado.
  bool get grantsPlanFeatures =>
      this == BiogPlanStatus.trial ||
      this == BiogPlanStatus.active ||
      this == BiogPlanStatus.grace;
}

/// Lo que el usuario puede hacer ahora mismo.
///
/// Objeto de solo lectura derivado del plan y su estado. La interfaz pregunta
/// aquí, nunca compara cadenas de estado por su cuenta.
@immutable
class BiogEntitlements {
  const BiogEntitlements({
    required this.plan,
    required this.status,
    required this.canSeeRawReadings,
    required this.canSeeLocalHistory,
    required this.canSeeWeather,
    required this.canSeeCropInterpretation,
    required this.canUseIrrigationEngine,
    required this.canUseNutritionPlanner,
    required this.canUseCustomAlerts,
    required this.canSyncToCloud,
    required this.canUseRemoteConsultation,
    required this.canExportData,
    required this.fixedDeviceLimit,
  });

  final BiogPlan plan;
  final BiogPlanStatus status;

  // Básico
  final bool canSeeRawReadings;
  final bool canSeeLocalHistory;
  final bool canSeeWeather;

  // Pro
  final bool canSeeCropInterpretation;
  final bool canUseIrrigationEngine;
  final bool canUseNutritionPlanner;
  final bool canUseCustomAlerts;
  final bool canSyncToCloud;
  final bool canUseRemoteConsultation;
  final bool canExportData;

  /// Cuántos Bio-G fijos caben en la cuenta.
  ///
  /// Los portátiles no ocupan plaza: ver [occupiesFixedSlot].
  ///
  /// El 4 de Pro sí está en el documento (Fundacional 2.1 §7.1: "la cuenta Pro
  /// incluye hasta cuatro equipos fijos"). **El 1 de Básico NO**: el documento
  /// solo dice "consulta local por dispositivo", sin cifra. Es un valor de
  /// ingeniería.
  ///
  /// Y falta lo más importante: el documento **no define qué pasa al superar
  /// el límite** —si se bloquea el alta, si solo se avisa, o si se degrada—.
  /// Hasta que lo defina, este número no debe usarse para impedir dar de alta
  /// un equipo: el §7.3 es tajante en que "BIO-G nunca bloquea el hardware
  /// comprado". Sirve para avisar y para dimensionar, no para prohibir.
  final int fixedDeviceLimit;

  /// Entitlements de Básico. Es también el suelo al que se degrada un Pro
  /// vencido: nunca se cae por debajo de esto.
  static const BiogEntitlements basico = BiogEntitlements(
    plan: BiogPlan.basico,
    status: BiogPlanStatus.active,
    canSeeRawReadings: true,
    canSeeLocalHistory: true,
    canSeeWeather: true,
    canSeeCropInterpretation: false,
    canUseIrrigationEngine: false,
    canUseNutritionPlanner: false,
    canUseCustomAlerts: false,
    canSyncToCloud: false,
    canUseRemoteConsultation: false,
    canExportData: false,
    fixedDeviceLimit: 1,
  );

  static const BiogEntitlements pro = BiogEntitlements(
    plan: BiogPlan.pro,
    status: BiogPlanStatus.active,
    canSeeRawReadings: true,
    canSeeLocalHistory: true,
    canSeeWeather: true,
    canSeeCropInterpretation: true,
    canUseIrrigationEngine: true,
    canUseNutritionPlanner: true,
    canUseCustomAlerts: true,
    canSyncToCloud: true,
    canUseRemoteConsultation: true,
    canExportData: true,
    fixedDeviceLimit: 4,
  );

  BiogEntitlements _withStatus(BiogPlanStatus next) => BiogEntitlements(
    plan: plan,
    status: next,
    canSeeRawReadings: canSeeRawReadings,
    canSeeLocalHistory: canSeeLocalHistory,
    canSeeWeather: canSeeWeather,
    canSeeCropInterpretation: canSeeCropInterpretation,
    canUseIrrigationEngine: canUseIrrigationEngine,
    canUseNutritionPlanner: canUseNutritionPlanner,
    canUseCustomAlerts: canUseCustomAlerts,
    canSyncToCloud: canSyncToCloud,
    canUseRemoteConsultation: canUseRemoteConsultation,
    canExportData: canExportData,
    fixedDeviceLimit: fixedDeviceLimit,
  );

  /// Un Bio-G portátil no ocupa plaza fija.
  ///
  /// Regla del Fundacional 2.1 §7.2: "un BIO-G Móvil vinculado a una cuenta
  /// con Pro activo puede sincronizar sus lecturas puntuales al historial de
  /// la cuenta, sin ocupar uno de los cuatro espacios de equipo fijo".
  ///
  /// Detectar la categoría por subcadena del modelo es frágil: el documento
  /// define DOS categorías de hardware —fija y portátil— y "maceta" es un caso
  /// de uso, no una categoría. Lo correcto a futuro es un campo de categoría
  /// explícito en el contrato de telemetría (§6.5: "identidad de dispositivo
  /// compartida entre las dos categorías"). Mientras tanto, esto.
  static bool occupiesFixedSlot(String? deviceModelId) {
    final id = deviceModelId?.trim().toLowerCase();
    if (id == null || id.isEmpty) return true;
    if (id.contains('portatil') ||
        id.contains('portátil') ||
        id.contains('portable') ||
        id.contains('maceta')) {
      return false;
    }
    return true;
  }

  String get summaryEs {
    switch (status) {
      case BiogPlanStatus.trial:
        return 'Prueba de ${plan.labelEs}';
      case BiogPlanStatus.active:
        return plan.labelEs;
      case BiogPlanStatus.grace:
        return '${plan.labelEs} por vencer';
      case BiogPlanStatus.expired:
        return 'Básico (${plan.labelEs} vencido)';
      case BiogPlanStatus.none:
        return 'Básico';
    }
  }
}

/// La suscripción de una cuenta, con sus fechas.
@immutable
class BiogSubscription {
  const BiogSubscription({
    required this.plan,
    required this.status,
    this.activatedAt,
    this.expiresAt,
    this.graceEndsAt,
    this.rawStatus,
  });

  final BiogPlan plan;
  final BiogPlanStatus status;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final DateTime? graceEndsAt;

  /// Valor original de `profiles.subscription_status`, conservado para
  /// diagnóstico y para no perder información al escribir de vuelta.
  final String? rawStatus;

  /// Doce meses. Es el único plazo que el Fundacional 2.1 §7.1 fija con
  /// número: "la compra inicial de un equipo fijo incluye doce meses de Pro".
  static const Duration initialTerm = Duration(days: 365);

  /// Periodo de gracia tras el vencimiento.
  ///
  /// **Estos 30 días son un valor de ingeniería, no una lectura del documento.**
  /// El Fundacional 2.1 §7.1 dice que "habrá avisos persistentes y un periodo
  /// de gracia antes de degradar a Básico", y su §22 lista el "periodo exacto
  /// de gracia por cobro fallido" entre las decisiones PENDIENTES. Cuando se
  /// decida, manda el documento y esta constante se ajusta.
  static const Duration gracePeriod = Duration(days: 30);

  static const BiogSubscription basic = BiogSubscription(
    plan: BiogPlan.basico,
    status: BiogPlanStatus.active,
  );

  /// Interpreta `profiles.subscription_status`.
  ///
  /// Acepta las variantes que ya podrían existir en la base y cae siempre en
  /// Básico ante un valor desconocido: un estado que no se entiende jamás debe
  /// abrir funciones de pago, pero tampoco debe romper la app.
  factory BiogSubscription.fromStatusString(
    String? raw, {
    DateTime? activatedAt,
    DateTime? expiresAt,
  }) {
    final value = raw?.trim().toLowerCase() ?? '';

    BiogPlan plan;
    BiogPlanStatus status;

    switch (value) {
      case 'pro':
      case 'pro_active':
      case 'premium':
        plan = BiogPlan.pro;
        status = BiogPlanStatus.active;
        break;
      case 'trial':
      case 'pro_trial':
        plan = BiogPlan.pro;
        status = BiogPlanStatus.trial;
        break;
      case 'grace':
      case 'pro_grace':
      case 'past_due':
        plan = BiogPlan.pro;
        status = BiogPlanStatus.grace;
        break;
      case 'expired':
      case 'pro_expired':
      case 'canceled':
      case 'cancelled':
        plan = BiogPlan.pro;
        status = BiogPlanStatus.expired;
        break;
      case 'basic':
      case 'basico':
      case 'básico':
      case 'free':
        plan = BiogPlan.basico;
        status = BiogPlanStatus.active;
        break;
      case '':
      case 'none':
        plan = BiogPlan.basico;
        status = BiogPlanStatus.none;
        break;
      default:
        plan = BiogPlan.basico;
        status = BiogPlanStatus.none;
    }

    return BiogSubscription(
      plan: plan,
      status: status,
      activatedAt: activatedAt,
      expiresAt: expiresAt,
      graceEndsAt: expiresAt?.add(gracePeriod),
      rawStatus: raw,
    );
  }

  /// Interpreta una fila de `public.subscriptions`.
  ///
  /// Esa tabla es la fuente de verdad *real* del plan: tiene `plan_code`,
  /// `status`, `starts_at` y `ends_at` como columnas propias, en vez de una
  /// sola cadena de texto. Hasta ahora la app no podía leerla —la única
  /// política de RLS comparaba `auth.uid()` contra un UUID escrito a mano— así
  /// que deducía el plan de `profiles.subscription_status`. Con la política de
  /// lectura propia ya en su sitio, esta fábrica existe para cuando empiece a
  /// haber filas.
  ///
  /// Sigue habiendo dos orígenes posibles, pero ya no dos verdades: ver
  /// [resolve], que fija la precedencia.
  factory BiogSubscription.fromSubscriptionRow(Map<String, Object?> row) {
    // Lectura tolerante a tipos. `as String?` lanzaba TypeError con un
    // `plan_code` numérico o un jsonb, y el error subía al llamador ANTES de
    // llegar al respaldo de perfil, justo al revés de lo que promete
    // [resolve]. Una fila rara debe degradar al respaldo, no tumbar la app.
    final planCode = _asText(row['plan_code'])?.toLowerCase();
    final rawStatus = _asText(row['status'])?.toLowerCase() ?? '';

    final BiogPlan plan;
    switch (planCode) {
      case 'pro':
      case 'premium':
        plan = BiogPlan.pro;
        break;
      default:
        // Un `plan_code` desconocido no abre funciones de pago. Misma regla
        // que en `fromStatusString`.
        plan = BiogPlan.basico;
    }

    final BiogPlanStatus status;
    switch (rawStatus) {
      case 'active':
      case 'activa':
      case 'paid':
        status = BiogPlanStatus.active;
        break;
      case 'trial':
      case 'trialing':
        status = BiogPlanStatus.trial;
        break;
      case 'past_due':
      case 'grace':
      case 'unpaid':
        status = BiogPlanStatus.grace;
        break;
      case 'canceled':
      case 'cancelled':
      case 'expired':
      case 'incomplete_expired':
        status = BiogPlanStatus.expired;
        break;
      default:
        status = BiogPlanStatus.none;
    }

    final starts = _parseUtc(row['starts_at']);
    final ends = _parseUtc(row['ends_at']);

    return BiogSubscription(
      plan: status == BiogPlanStatus.none ? BiogPlan.basico : plan,
      status: status,
      activatedAt: starts,
      expiresAt: ends,
      graceEndsAt: ends?.add(gracePeriod),
      rawStatus: _asText(row['status']),
    );
  }

  /// Fija la precedencia entre los dos orígenes del plan.
  ///
  /// `subscriptions` manda cuando hay fila: es la tabla que escribe el backend
  /// de cobros y la que lleva fechas. `profiles.subscription_status` queda como
  /// respaldo para las cuentas dadas de alta antes de que existiera la tabla
  /// —hoy, todas— y para el caso en que RLS o la red impidan leerla.
  ///
  /// Con [subscriptionRow] en null el comportamiento es idéntico al de antes,
  /// carácter por carácter. Por eso esto se puede desplegar sin esperar a que
  /// haya un solo registro de cobro.
  static BiogSubscription resolve({
    Map<String, Object?>? subscriptionRow,
    String? profileStatus,
    DateTime? profileActivatedAt,
    DateTime? profileExpiresAt,
  }) {
    if (subscriptionRow != null && subscriptionRow.isNotEmpty) {
      final fromTable = BiogSubscription.fromSubscriptionRow(subscriptionRow);
      // Una fila que no se entiende (`status` desconocido y sin fechas) no
      // debe degradar a una cuenta que la columna de perfil sí reconoce.
      final bool usable =
          fromTable.status != BiogPlanStatus.none || fromTable.expiresAt != null;
      if (usable) return fromTable;
    }

    return BiogSubscription.fromStatusString(
      profileStatus,
      activatedAt: profileActivatedAt,
      expiresAt: profileExpiresAt,
    );
  }

  static String? _asText(Object? value) {
    if (value == null) return null;
    final text = value is String ? value.trim() : value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _parseUtc(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.toUtc();
  }

  /// Estado real en un momento dado, aplicando vencimiento y gracia.
  ///
  /// La fecha manda sobre la cadena guardada: un `'pro'` con `expiresAt` del
  /// año pasado no da acceso Pro por mucho que la columna lo diga.
  BiogPlanStatus statusAt(DateTime now) {
    final expiry = expiresAt;
    if (expiry == null) return status;
    if (now.isBefore(expiry)) return status;

    final graceEnd = graceEndsAt ?? expiry.add(gracePeriod);
    if (now.isBefore(graceEnd)) return BiogPlanStatus.grace;
    return BiogPlanStatus.expired;
  }

  /// Lo que la cuenta puede hacer en [now].
  BiogEntitlements entitlementsAt(DateTime now) {
    final effective = statusAt(now);

    if (!effective.grantsPlanFeatures) {
      // Degradación: se apagan las funciones de Pro y NO se toca ni la
      // configuración del cultivo ni el historial local.
      return BiogEntitlements.basico._withStatus(effective);
    }

    switch (plan) {
      case BiogPlan.pro:
        return BiogEntitlements.pro._withStatus(effective);
      case BiogPlan.basico:
        return BiogEntitlements.basico._withStatus(effective);
    }
  }

  /// Días que faltan para el vencimiento. Negativo si ya venció.
  int? daysUntilExpiry(DateTime now) {
    final expiry = expiresAt;
    if (expiry == null) return null;
    return expiry.difference(now).inDays;
  }

  /// Activación manual, que es la vía prevista para V1-A mientras no hay
  /// pasarela de cobro ni compras dentro de la app.
  BiogSubscription activateManually({
    required DateTime now,
    BiogPlan targetPlan = BiogPlan.pro,
    Duration term = initialTerm,
  }) {
    final expiry = now.add(term);
    return BiogSubscription(
      plan: targetPlan,
      status: BiogPlanStatus.active,
      activatedAt: now,
      expiresAt: expiry,
      graceEndsAt: expiry.add(gracePeriod),
      rawStatus: targetPlan.storageKey,
    );
  }

  /// Valor a escribir en `profiles.subscription_status`.
  String toStatusString() {
    switch (status) {
      case BiogPlanStatus.trial:
        return 'trial';
      case BiogPlanStatus.active:
        return plan.storageKey;
      case BiogPlanStatus.grace:
        return 'grace';
      case BiogPlanStatus.expired:
        return 'expired';
      case BiogPlanStatus.none:
        return 'none';
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'plan': plan.storageKey,
    'status': status.name,
    'activatedAt': activatedAt?.toUtc().toIso8601String(),
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
    'graceEndsAt': graceEndsAt?.toUtc().toIso8601String(),
  };
}
