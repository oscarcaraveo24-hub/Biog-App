import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
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

    NutritionDecision decision({
      required NutritionState state,
      double scoreFactor = 1.0,
      int unattended = 0,
      bool awaitingEvidence = false,
    }) {
      return NutritionDecision(
        state: state,
        decidedAt: DateTime(2026, 8, 8, 9),
        headlineEs: 'Esta etapa necesita nutrición: nitrógeno',
        detailEs:
            'En «Floración» el cultivo toma nitrógeno con fuerza. Cuando '
            'apliques no necesitas registrar nada: BIO-G observa la respuesta '
            'del suelo para reconocer cuándo se atendió esta ventana.',
        priorities: const <NutrientStagePriority>[
          NutrientStagePriority(
            nutrient: AgroMetricKey.n,
            priority: NutritionPriority.high,
            priority01: 0.8,
            windowLabelEs: 'Tramo fuerte de N',
            rationaleEs: 'En «Floración» el cultivo toma nitrógeno con fuerza.',
            isCriticalWindow: true,
          ),
        ],
        conditions: const NutritionConditionCheck(allowsApplication: true),
        engineVersion: 'test',
        scoreFactor: scoreFactor,
        unattendedCriticalWindows: unattended,
        awaitingEvidence: awaitingEvidence,
      );
    }

    const AgroEvalResult eval = AgroEvalResult(
      soilControlScore01: 0.81,
      metrics: <AgroMetricKey, AgroMetricEval>{
        AgroMetricKey.soilMoisture: AgroMetricEval(
          band: AgroBand.optimal,
          score01: 1.0,
          labelEs: 'Óptimo',
          value: 42,
        ),
        // N/P/K viajan como señal nativa: sin banda, sin prioridad.
        AgroMetricKey.n: AgroMetricEval(
          band: AgroBand.unknown,
          score01: 0.0,
          labelEs: 'Señal nativa',
          value: 180,
          isNativeSignal: true,
        ),
      },
      alerts: <BioGAlert>[],
      suggestedAlertKeys: <String>[],
      soilCoverage: SoilSignalCoverage(evaluable: 5, present: 5),
    );

    test('la tarjeta de nutrición repite la decisión del motor, no la lectura', () {
      final data = DashboardScreenPresenter().buildViewData(
        store: store,
        runtime: _runtime(eval: eval, telemetry: _telemetry()),
        today: DateTime(2026, 8, 8),
        nutritionDecision: decision(
          state: NutritionState.actionWindow,
          awaitingEvidence: true,
        ),
      );

      expect(data.soilHealth, closeTo(0.81, 0.0001));
      expect(data.soilHealthLabel, 'Estado general del suelo');
      expect(data.npkTitle, 'Esta etapa necesita nutrición: nitrógeno');
      expect(data.npkTag, 'Ventana');
      expect(data.npkSubtitle, startsWith('En «Floración» el cultivo toma'));
      // Ventana abierta sin firma todavía: NO penaliza el anillo.
      expect(data.nutritionDecision?.awaitingEvidence, isTrue);
    });

    test('solo una ventana importante que terminó sin evidencia baja el anillo', () {
      final data = DashboardScreenPresenter().buildViewData(
        store: store,
        runtime: _runtime(eval: eval, telemetry: _telemetry()),
        today: DateTime(2026, 8, 8),
        nutritionDecision: decision(
          state: NutritionState.monitor,
          scoreFactor: 0.94,
          unattended: 1,
        ),
      );

      expect(data.soilHealth, closeTo(0.81 * 0.94, 0.0001));
    });

    test('sin decisión no se inventa ninguna lectura N/P/K', () {
      final data = DashboardScreenPresenter().buildViewData(
        store: store,
        runtime: _runtime(
          eval: eval,
          telemetry: _telemetry(n: 0, p: 30, k: 30, hasNitrogenData: false),
          targets: _targets,
        ),
        today: DateTime(2026, 8, 8),
      );

      expect(data.npkTitle, 'Nutrición');
      expect(data.npkTag, isEmpty);
      expect(data.npkSubtitle.toLowerCase(), contains('tendencia de n, p y k'));
      expect(data.npkSubtitle, isNot(contains('Bajo')));
      expect(data.npkSubtitle, isNot(contains('Alto')));
    });
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
          'Esta ventana nutricional no mostró evidencia suficiente de haber sido atendida';
      const subtitle =
          'La ventana de N en «Floración» terminó sin que la sonda viera una respuesta compatible con fertilización.';

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
