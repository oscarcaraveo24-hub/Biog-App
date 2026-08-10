import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/screens/recommendations/recommendations_screen.dart';
import 'package:bio_g/services/biog/biog_repository.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Envoltura mínima con [BioGScope].
///
/// `RecommendationsScreen.didChangeDependencies` resuelve el store, así que sin
/// scope la pantalla ni siquiera monta. Las dos pruebas fallaban por eso, no
/// por lo que querían comprobar.
Widget _scoped({required Widget child, required BioGStore store}) {
  return BioGScope(
    store: store,
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          disableAnimations: true,
          textScaler: TextScaler.linear(1.3),
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('mounts the irrigation recommendation on a narrow phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final DateTime now = DateTime(2026, 8, 9, 12);
    final IrrigationDecision decision = IrrigationDecision(
      action: IrrigationAction.regar,
      urgency: IrrigationUrgency.high,
      confidence01: 0.82,
      reasons: const <IrrigationReason>[
        IrrigationReason(
          code: IrrigationReasonCode.moistureBelowTarget,
          textEs: 'La humedad está por debajo del objetivo de la etapa.',
        ),
      ],
      headlineEs: 'Riega hoy',
      detailEs: 'El suelo necesita agua antes de que aumente el estrés.',
      decidedAt: now,
      validUntil: now.add(const Duration(hours: 6)),
      engineVersion: 'test',
    );

    final BioGStore store = BioGStore(_EmptyBioGRepository());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      _scoped(
        store: store,
        child: RecommendationsScreen(
          events: <AgronomicEvent>[
            AgronomicEvent(
              type: AgronomicEventType.frostWarning,
              severity: AgronomicEventSeverity.warning,
              title: 'Riesgo de helada',
              message: 'Protege el cultivo durante la madrugada.',
              timestamp: now,
            ),
          ],
          irrigationDecision: decision,
          cropLabel: 'Mango Ataulfo',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Recomendaciones'), findsOneWidget);
    expect(find.text('Riega hoy'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pump();

    expect(find.text('Riesgo de helada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the full optimal band without treating it as one point', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final BioGStore store = BioGStore(_EmptyBioGRepository());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      _scoped(
        store: store,
        child: const RecommendationsScreen(
          events: <AgronomicEvent>[],
          moisturePct: 60,
          moistureTarget: AgroRange(
            lowMax: 28,
            optimalMin: 45,
            optimalMax: 68,
            highMin: 84,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Óptimo'), findsWidgets);
    expect(find.text('45–68%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Repositorio vacío, copiado del test del Panel: el store solo tiene que
/// existir para que `BioGScope.of` no falle.
class _EmptyBioGRepository implements BioGRepository {
  @override
  Stream<List<BioGDevice>> watchDevices() =>
      Stream<List<BioGDevice>>.value(const <BioGDevice>[]);

  @override
  Stream<BioGDevice?> watchActiveDevice() => Stream<BioGDevice?>.value(null);

  @override
  Stream<BioGTelemetry?> watchLiveTelemetry() =>
      Stream<BioGTelemetry?>.value(null);

  @override
  Stream<List<BioGTelemetry>> watchHistory({required Duration? window}) =>
      Stream<List<BioGTelemetry>>.value(const <BioGTelemetry>[]);

  @override
  Stream<List<BioGAlert>> watchAlerts({int limit = 50}) =>
      Stream<List<BioGAlert>>.value(const <BioGAlert>[]);

  @override
  Future<void> setActiveDevice(String deviceId) async {}

  @override
  Future<BioGDevice> addDevice({
    String? seedId,
    String? profileId,
    String? locationName,
    String? name,
    String? hardwareDeviceId,
    String? deviceModelId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeDevice(String deviceId) async {}

  @override
  void dispose() {}
}
