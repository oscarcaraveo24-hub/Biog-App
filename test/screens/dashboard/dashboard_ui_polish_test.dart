import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/screens/dashboard/dashboard_presenter.dart';
import 'package:bio_g/screens/dashboard/dashboard_sections.dart';
import 'package:bio_g/services/biog/biog_repository.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/npk_insight_card.dart';
import 'package:bio_g/widgets/soil_health_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard presenter UI polish', () {
    late BioGStore store;

    setUp(() {
      store = BioGStore(_EmptyBioGRepository());
    });

    tearDown(() {
      store.dispose();
    });

    test('uses compact NPK bands and preserves the detailed explanation', () {
      const eval = AgroEvalResult(
        soilControlScore01: 0.81,
        metrics: <AgroMetricKey, AgroMetricEval>{
          AgroMetricKey.n: AgroMetricEval(
            band: AgroBand.high,
            score01: 0.72,
            labelEs: 'Alto útil',
            priorityLabel: NutrientPriorityLabel.possibleExcess,
            shortRecommendationEs: 'Nitrógeno alto en mango.',
          ),
          AgroMetricKey.p: AgroMetricEval(
            band: AgroBand.low,
            score01: 0.42,
            labelEs: 'Falta Nutriente',
            priorityLabel: NutrientPriorityLabel.highPriority,
            shortRecommendationEs: 'Fósforo bajo en mango.',
          ),
          AgroMetricKey.k: AgroMetricEval(
            band: AgroBand.low,
            score01: 0.56,
            labelEs: 'Vigilar',
            priorityLabel: NutrientPriorityLabel.lowPriority,
            shortRecommendationEs: 'Potasio bajo en mango.',
          ),
        },
        alerts: <BioGAlert>[],
        suggestedAlertKeys: <String>[],
      );

      final data = DashboardScreenPresenter().buildViewData(
        store: store,
        runtime: _runtime(eval: eval, telemetry: _telemetry()),
        today: DateTime(2026, 8, 8),
      );

      expect(data.soilHealth, 0.81);
      expect(data.soilHealthLabel, 'Estado general del suelo');
      expect(
        data.npkTitle,
        'N\u00a0—\u00a0Alto · P\u00a0—\u00a0Bajo · K\u00a0—\u00a0Bajo',
      );
      expect(data.npkSubtitle, 'Fósforo bajo en mango.');
    });

    test(
      'keeps an absent nutrient unknown instead of using the raw fallback',
      () {
        const eval = AgroEvalResult(
          soilControlScore01: 0.70,
          metrics: <AgroMetricKey, AgroMetricEval>{
            AgroMetricKey.n: AgroMetricEval(
              band: AgroBand.unknown,
              score01: 0.5,
              labelEs: '—',
            ),
            AgroMetricKey.p: AgroMetricEval(
              band: AgroBand.optimal,
              score01: 1,
              labelEs: 'Óptimo',
              priorityLabel: NutrientPriorityLabel.noPriority,
            ),
            AgroMetricKey.k: AgroMetricEval(
              band: AgroBand.optimal,
              score01: 1,
              labelEs: 'Óptimo',
              priorityLabel: NutrientPriorityLabel.noPriority,
            ),
          },
          alerts: <BioGAlert>[],
          suggestedAlertKeys: <String>[],
        );

        final data = DashboardScreenPresenter().buildViewData(
          store: store,
          runtime: _runtime(
            eval: eval,
            telemetry: _telemetry(n: 0, p: 30, k: 30, hasNitrogenData: false),
            targets: _targets,
          ),
          today: DateTime(2026, 8, 8),
        );

        expect(
          data.npkTitle,
          'N\u00a0—\u00a0— · P\u00a0—\u00a0Óptimo · K\u00a0—\u00a0Óptimo',
        );
      },
    );
  });

  group('Dashboard responsive UI polish', () {
    testWidgets('NPK summary wraps without ellipsis on a narrow viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const title =
          'N\u00a0—\u00a0Crítico · P\u00a0—\u00a0Crítico · K\u00a0—\u00a0Crítico';
      const subtitle =
          'Potasio bajo en mango. Revisa la recomendación agronómica vigente.';

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: const Scaffold(
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: NpkInsightCard(
                    title: title,
                    subtitle: subtitle,
                    assetIcon: 'assets/icons/metrics/ic_npk.png',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final titleWidget = tester.widget<Text>(find.text(title));
      expect(titleWidget.maxLines, isNull);
      expect(titleWidget.overflow, isNull);
      expect(find.text(subtitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ring keeps the requested label without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SoilHealthRing(
                percent: 0.78,
                label: 'Estado general del suelo',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('78%'), findsOneWidget);
      expect(find.text('Estado general del suelo'), findsOneWidget);
      // 50, no 46: el anillo subió el tamaño del porcentaje y la prueba se
      // quedó con la cifra vieja. Se fija el valor que de verdad se envía.
      expect(tester.widget<Text>(find.text('78%')).style?.fontSize, 50);
      expect(
        tester
            .widget<Text>(find.text('Estado general del suelo'))
            .style
            ?.fontSize,
        13,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('background pauses when inactive and for reduced motion', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_backgroundHarness(enabled: true));
      expect(
        find.byKey(const ValueKey<String>('dashboard-nature-particles')),
        findsOneWidget,
      );
      final initial = _firstTransform(tester);
      await tester.pump(const Duration(seconds: 6));
      final animated = _firstTransform(tester);
      expect(animated, isNot(equals(initial)));

      await tester.pumpWidget(_backgroundHarness(enabled: false));
      final paused = _firstTransform(tester);
      await tester.pump(const Duration(seconds: 6));
      expect(_firstTransform(tester), equals(paused));

      await tester.pumpWidget(
        _backgroundHarness(enabled: true, disableAnimations: true),
      );
      final reducedMotion = _firstTransform(tester);
      await tester.pump(const Duration(seconds: 6));
      expect(_firstTransform(tester), equals(reducedMotion));
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _backgroundHarness({
  required bool enabled,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: DashboardBackground(enabled: enabled)),
    ),
  );
}

List<double> _firstTransform(WidgetTester tester) {
  return tester
      .widget<Transform>(find.byType(Transform).first)
      .transform
      .storage
      .toList(growable: false);
}

CropRuntimeSnapshot _runtime({
  required AgroEvalResult eval,
  required BioGTelemetry telemetry,
  StageTargets? targets,
}) {
  final sowingDate = DateTime(2026, 4, 1);
  final seed = SeedInstall.planted(
    deviceId: telemetry.deviceId,
    cropKey: 'mango',
    varietyAlias: 'Ataulfo',
    sowingDate: sowingDate,
  );

  return CropRuntimeSnapshot(
    device: null,
    live: telemetry,
    seed: seed,
    definition: null,
    profile: null,
    stageResult: null,
    targets: targets,
    eval: eval,
    nextAlertsState: const AlertsState(),
    cropKeyName: 'mango',
    cropLabel: 'Mango',
    cropIconAsset: 'assets/icons/wizard/ic_mango_tree.png',
    stageLabel: 'Floración',
    sowingStatus: SowingStatus.planted,
    engineSowingDate: sowingDate,
    hasSeed: true,
    isPlanted: true,
    isPlanned: false,
    isGenericMode: false,
  );
}

BioGTelemetry _telemetry({
  double n = 180,
  double p = 20,
  double k = 80,
  bool hasNitrogenData = true,
}) {
  return BioGTelemetry(
    deviceId: 'dashboard-test-device',
    timestamp: DateTime(2026, 8, 8),
    airTempC: 25,
    airHumidityPct: 58,
    soilMoisturePct: 42,
    soilTempC: 24,
    ph: 6.5,
    ec: 1.1,
    resistance: 1.0,
    n: n,
    p: p,
    k: k,
    batteryPct: 90,
    signalRssi: -48,
    hasNitrogenData: hasNitrogenData,
  );
}

const AgroRange _range = AgroRange(
  lowMax: 10,
  optimalMin: 20,
  optimalMax: 40,
  highMin: 50,
);

const StageTargets _targets = StageTargets(
  moistureRaw: _range,
  soilTemp: _range,
  ph: _range,
  ec: _range,
  resistance: _range,
  nIndex: _range,
  pIndex: _range,
  kIndex: _range,
  nSoilPpmRange: _range,
  pSoilPpmRange: _range,
  kSoilPpmRange: _range,
);

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
