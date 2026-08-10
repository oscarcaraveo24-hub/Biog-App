// test/core/billing/biog_plan_test.dart
//
// Degradación de Pro y límites de plan. No existía ni un test porque no
// existía el gating: `subscriptionStatus` era un String sin lectores.

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/billing/biog_plan.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 8, 3);

  group('interpretación del estado guardado', () {
    test('reconoce las variantes de Pro', () {
      for (final raw in <String>['pro', 'PRO', 'premium', 'pro_active']) {
        final sub = BiogSubscription.fromStatusString(raw);
        expect(sub.plan, BiogPlan.pro, reason: raw);
        expect(sub.entitlementsAt(now).canUseIrrigationEngine, isTrue);
      }
    });

    test('un valor desconocido NUNCA abre funciones de pago', () {
      final sub = BiogSubscription.fromStatusString('lo_que_sea');
      expect(sub.plan, BiogPlan.basico);
      expect(sub.entitlementsAt(now).canUseIrrigationEngine, isFalse);
      expect(sub.entitlementsAt(now).canSyncToCloud, isFalse);
    });

    test('null y vacío caen en Básico sin romper', () {
      expect(BiogSubscription.fromStatusString(null).plan, BiogPlan.basico);
      expect(BiogSubscription.fromStatusString('').plan, BiogPlan.basico);
    });

    test('trial da acceso Pro mientras dura', () {
      final sub = BiogSubscription.fromStatusString('trial');
      expect(sub.entitlementsAt(now).canSeeCropInterpretation, isTrue);
      expect(sub.status, BiogPlanStatus.trial);
    });
  });

  group('degradación', () {
    test('Pro vencido cae a Básico y NO pierde lo de Básico', () {
      final sub = BiogSubscription.fromStatusString(
        'pro',
        expiresAt: now.subtract(const Duration(days: 90)),
      );
      final ent = sub.entitlementsAt(now);

      expect(sub.statusAt(now), BiogPlanStatus.expired);
      expect(ent.canUseIrrigationEngine, isFalse);
      expect(ent.canSyncToCloud, isFalse);

      // Lo que el agricultor capturó sigue siendo suyo.
      expect(ent.canSeeRawReadings, isTrue);
      expect(ent.canSeeLocalHistory, isTrue);
      expect(ent.canSeeWeather, isTrue);
    });

    test('dentro del periodo de gracia conserva el acceso', () {
      final sub = BiogSubscription.fromStatusString(
        'pro',
        expiresAt: now.subtract(const Duration(days: 10)),
      );

      expect(sub.statusAt(now), BiogPlanStatus.grace);
      expect(sub.entitlementsAt(now).canUseIrrigationEngine, isTrue);
    });

    test('la fecha manda sobre la cadena guardada', () {
      // Una columna que dice 'pro' con vencimiento del año pasado no da Pro.
      final sub = BiogSubscription.fromStatusString(
        'pro',
        expiresAt: DateTime.utc(2025, 1, 1),
      );
      expect(sub.entitlementsAt(now).canUseNutritionPlanner, isFalse);
    });

    test('sin fecha de vencimiento se respeta el estado declarado', () {
      final sub = BiogSubscription.fromStatusString('pro');
      expect(sub.statusAt(now), BiogPlanStatus.active);
    });
  });

  group('límite de equipos', () {
    test('Básico permite uno; Pro permite cuatro', () {
      expect(BiogEntitlements.basico.fixedDeviceLimit, 1);
      expect(BiogEntitlements.pro.fixedDeviceLimit, 4);
    });

    test('el portátil no ocupa plaza fija', () {
      expect(BiogEntitlements.occupiesFixedSlot('portatil'), isFalse);
      expect(BiogEntitlements.occupiesFixedSlot('maceta'), isFalse);
      expect(BiogEntitlements.occupiesFixedSlot('campo'), isTrue);
      expect(BiogEntitlements.occupiesFixedSlot('huerto'), isTrue);
      expect(BiogEntitlements.occupiesFixedSlot(null), isTrue);
    });
  });

  group('activación manual (V1-A)', () {
    test('activa un año y deja gracia después', () {
      final activated = BiogSubscription.basic.activateManually(now: now);

      expect(activated.plan, BiogPlan.pro);
      expect(activated.status, BiogPlanStatus.active);
      expect(activated.expiresAt, now.add(BiogSubscription.initialTerm));
      expect(activated.entitlementsAt(now).canUseIrrigationEngine, isTrue);

      final justAfterExpiry = activated.expiresAt!.add(
        const Duration(days: 5),
      );
      expect(activated.statusAt(justAfterExpiry), BiogPlanStatus.grace);

      final afterGrace = activated.expiresAt!.add(const Duration(days: 45));
      expect(activated.statusAt(afterGrace), BiogPlanStatus.expired);
    });

    test('lo que se escribe de vuelta es reinterpretable', () {
      final activated = BiogSubscription.basic.activateManually(now: now);
      final roundTrip = BiogSubscription.fromStatusString(
        activated.toStatusString(),
        expiresAt: activated.expiresAt,
      );
      expect(roundTrip.plan, BiogPlan.pro);
      expect(roundTrip.entitlementsAt(now).canUseIrrigationEngine, isTrue);
    });

    test('días restantes se calculan bien', () {
      final activated = BiogSubscription.basic.activateManually(now: now);
      expect(activated.daysUntilExpiry(now), 365);
      expect(
        activated.daysUntilExpiry(now.add(const Duration(days: 400))),
        lessThan(0),
      );
    });
  });

  group('fila real de public.subscriptions', () {
    test('una suscripción Pro activa concede las funciones de pago', () {
      final sub = BiogSubscription.fromSubscriptionRow(<String, Object?>{
        'plan_code': 'pro',
        'status': 'active',
        'starts_at': '2026-01-01T00:00:00Z',
        'ends_at': '2027-01-01T00:00:00Z',
      });
      expect(sub.plan, BiogPlan.pro);
      expect(sub.status, BiogPlanStatus.active);
      expect(sub.entitlementsAt(now).canUseIrrigationEngine, isTrue);
      expect(sub.expiresAt, DateTime.utc(2027, 1, 1));
    });

    test('la fecha manda sobre la cadena, igual que en el perfil', () {
      final sub = BiogSubscription.fromSubscriptionRow(<String, Object?>{
        'plan_code': 'pro',
        'status': 'active',
        'ends_at': '2026-01-01T00:00:00Z',
      });
      // Venció en enero y la gracia son 30 días: en agosto ya está expirada.
      expect(sub.statusAt(now), BiogPlanStatus.expired);
      expect(sub.entitlementsAt(now).canUseIrrigationEngine, isFalse);
    });

    test('un plan_code desconocido no abre funciones de pago', () {
      final sub = BiogSubscription.fromSubscriptionRow(<String, Object?>{
        'plan_code': 'plan_que_no_existe',
        'status': 'active',
      });
      expect(sub.plan, BiogPlan.basico);
      expect(sub.entitlementsAt(now).canUseIrrigationEngine, isFalse);
    });
  });

  group('precedencia entre orígenes', () {
    test('sin fila de suscripción se comporta EXACTAMENTE como antes', () {
      for (final raw in <String?>[
        null,
        '',
        'trial',
        'pro',
        'grace',
        'expired',
        'basico',
        'valor_raro',
      ]) {
        final resuelto = BiogSubscription.resolve(profileStatus: raw);
        final anterior = BiogSubscription.fromStatusString(raw);
        expect(resuelto.plan, anterior.plan, reason: 'plan para "$raw"');
        expect(resuelto.status, anterior.status, reason: 'estado para "$raw"');
      }
    });

    test('la tabla gana sobre la cadena del perfil', () {
      final resuelto = BiogSubscription.resolve(
        subscriptionRow: <String, Object?>{
          'plan_code': 'pro',
          'status': 'active',
          'ends_at': '2027-01-01T00:00:00Z',
        },
        profileStatus: 'expired',
      );
      expect(resuelto.status, BiogPlanStatus.active);
      expect(resuelto.entitlementsAt(now).canUseIrrigationEngine, isTrue);
    });

    test('una fila ilegible NO degrada a una cuenta que el perfil reconoce', () {
      final resuelto = BiogSubscription.resolve(
        subscriptionRow: <String, Object?>{'status': 'algo_incomprensible'},
        profileStatus: 'pro',
      );
      expect(resuelto.plan, BiogPlan.pro);
      expect(resuelto.status, BiogPlanStatus.active);
    });

    test('una fila vacía equivale a no tener fila', () {
      final resuelto = BiogSubscription.resolve(
        subscriptionRow: const <String, Object?>{},
        profileStatus: 'trial',
      );
      expect(resuelto.status, BiogPlanStatus.trial);
    });
  });
}
