// test/core/agro/nutrition/nutrition_timeline_vm_test.dart
//
// La línea de tiempo: un nodo por etapa, un marcador por ventana de la guía
// efectiva, cinco estados. La verdad del sensor manda sobre el marcador; la
// declaración del productor decide qué ventanas SON fertilización (17 sep
// 2026: las plegadas ya no llevan marcador; sin declaración, con algo que
// contestar, la línea sale en gris y sin marcadores).
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guides.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_plan_resolver.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_season_declaration.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_timeline_vm.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/agro/water/soil_water_scale.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_stage_schedule.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:flutter_test/flutter_test.dart';

const String _season = 'dev|maize|2026-04-01';

CropStageSchedule _maizeSchedule() {
  final CropDefinition def = CropRegistry.byKey(CropKey.maize)!;
  return CropStageSchedule(
    axis: CropStageAxis.days,
    cropKey: 'maize',
    slots: CropStageScheduleResolver.sample(
      engine: def.engine,
      profile: def.resolveProfile()!,
      sowing: DateTime.utc(2026, 4, 1),
    ),
  );
}

NutritionWindowRecord _record(
  String stageKey,
  NutritionWindowOutcome outcome, {
  bool critical = true,
  ResponseVerdict? verdict,
}) => NutritionWindowRecord(
  id: 'w-$stageKey',
  seasonKey: _season,
  deviceId: 'dev',
  cropKey: 'maize',
  stageKey: stageKey,
  stageLabelEs: stageKey,
  nutrients: const <AgroMetricKey>[AgroMetricKey.n],
  isCritical: critical,
  openedAt: DateTime(2026, 4, 10),
  closedAt: outcome == NutritionWindowOutcome.open ? null : DateTime(2026, 4, 30),
  outcome: outcome,
  responseVerdict: verdict,
  evidenceEs: const <String>['CE subió 27 % sobre la referencia'],
);

TimelineNodeVm _node(NutritionTimelineVm vm, String stageKey) =>
    vm.nodes.firstWhere((n) => n.stageKey == stageKey);

void main() {
  setUp(CropStageScheduleResolver.clearCache);

  test('sin calendario: vacía', () {
    expect(NutritionTimelineVm.build(schedule: null, currentStageKey: 'x').isEmpty, isTrue);
  });

  test('sin guía: solo fenología (fases y progreso), ningún marcador', () {
    final NutritionTimelineVm vm = NutritionTimelineVm.build(
      schedule: _maizeSchedule(),
      currentStageKey: 'vegMid',
      currentProgress01: 0.4,
    );
    expect(vm.nodes.length, 9);
    expect(vm.currentIndex, 3);
    expect(vm.hasGuide, isFalse);
    expect(vm.markerCount, 0);
    expect(_node(vm, 'germination').phase, TimelinePhase.past);
    expect(_node(vm, 'vegMid').phase, TimelinePhase.current);
    expect(_node(vm, 'vegMid').progress01, closeTo(0.4, 1e-9));
    expect(_node(vm, 'tasseling').phase, TimelinePhase.future);
    expect(_node(vm, 'germination').progress01, isNull);
    expect(vm.stageCountEs, 'Etapa 4 de 9');
    expect(vm.currentNode!.stageKey, 'vegMid');
    expect(_node(vm, 'maturitySenescence').shortLabelEs, 'Maduración');
    expect(_node(vm, 'flowerSet').shortLabelEs, 'Floración y cuajado');
  });

  test('nombre corto: corta en « / », « (» y guiones largos', () {
    expect(TimelineNodeVm.shortLabel('Reposo funcional / preparación'), 'Reposo funcional');
    expect(TimelineNodeVm.shortLabel('Emergencia / establecimiento'), 'Emergencia');
    expect(TimelineNodeVm.shortLabel('Segunda fertilización (V6–V8)'), 'Segunda fertilización');
    expect(TimelineNodeVm.shortLabel('Vegetativa temprana'), 'Vegetativa temprana');
  });

  test('sin declaración y con algo que contestar: en gris, sin marcadores', () {
    // Suelo medio: «dos» y «tres» son válidas → hay pregunta pendiente.
    final NutritionPlanResolution plan = NutritionWindowPlanResolver.resolve(
      guide: kNutritionGuides['maize'],
      texture: SoilTexture.loam,
      seasonKey: _season,
      currentStageKey: 'vegMid',
    );
    expect(plan.canDeclare, isTrue);
    final NutritionTimelineVm vm = NutritionTimelineVm.build(
      schedule: _maizeSchedule(),
      currentStageKey: 'vegMid',
      plan: plan,
      seasonKey: _season,
    );
    expect(vm.awaitingDeclaration, isTrue);
    expect(vm.hasGuide, isTrue);
    expect(vm.markerCount, 0);
    expect(vm.nodes.length, 9, reason: 'la fenología sí se muestra');
    expect(vm.currentIndex, 3);
    expect(vm.planSummaryEs, 'Plan sin elegir');
  });

  test('con guía y sin libro: el estado del marcador sale de la fase', () {
    // Arena: solo «tres o más» es válida → nada que preguntar, plan de la guía.
    final NutritionPlanResolution plan = NutritionWindowPlanResolver.resolve(
      guide: kNutritionGuides['maize'],
      texture: SoilTexture.sandy,
      seasonKey: _season,
      currentStageKey: 'vegMid',
    );
    expect(plan.canDeclare, isFalse);
    final NutritionTimelineVm vm = NutritionTimelineVm.build(
      schedule: _maizeSchedule(),
      currentStageKey: 'vegMid',
      plan: plan,
      seasonKey: _season,
    );
    expect(vm.hasGuide, isTrue);
    expect(vm.awaitingDeclaration, isFalse);
    // Tres reglas con ventana (fondo, V6–V8, V10–V12); espigamiento no abre.
    expect(vm.markerCount, 3);
    expect(_node(vm, 'germination').marker!.state, NutritionMarkerState.informative);
    expect(_node(vm, 'germination').marker!.noteEs, contains('Sin registro'));
    // V6–V8 abarca vegEarly y vegMid: se ancla en vegEarly pero está ABIERTA
    // porque la etapa actual (vegMid) cae dentro.
    final NutritionMarkerVm v6 = _node(vm, 'vegEarly').marker!;
    expect(v6.state, NutritionMarkerState.open);
    expect(v6.labelEs, 'Segunda fertilización (V6–V8)');
    expect(v6.isCritical, isTrue);
    expect(v6.stageSpanEs, contains('–'));
    expect(_node(vm, 'vegMid').hasMarker, isFalse, reason: 'misma regla, un solo marcador');
    expect(_node(vm, 'vegAdvanced').marker!.state, NutritionMarkerState.pending);
    expect(_node(vm, 'tasseling').hasMarker, isFalse);
    // Dosis de la ventana abierta: 40 % de 160–240 kg N/ha.
    final TimelineDose n = v6.doses.single;
    expect(n.nutrient, AgroMetricKey.n);
    expect(n.range.min, closeTo(64, 1e-6));
    expect(n.range.max, closeTo(96, 1e-6));
    expect(vm.planSummaryEs, '3 fertilizaciones de nitrógeno · plan de la guía');
  });

  test('el libro manda: atendida, sin evidencia (importante) y cerrada sin pesar', () {
    final NutritionPlanResolution plan = NutritionWindowPlanResolver.resolve(
      guide: kNutritionGuides['maize'],
      texture: SoilTexture.sandy,
      seasonKey: _season,
      currentStageKey: 'tasseling',
    );
    final NutritionTimelineVm vm = NutritionTimelineVm.build(
      schedule: _maizeSchedule(),
      currentStageKey: 'tasseling',
      plan: plan,
      seasonKey: _season,
      windows: <NutritionWindowRecord>[
        _record('germination', NutritionWindowOutcome.unattended, critical: false),
        _record('vegmid', NutritionWindowOutcome.attendedDetected, verdict: ResponseVerdict.compatible),
        _record('vegadvanced', NutritionWindowOutcome.unattended),
      ],
    );
    expect(_node(vm, 'germination').marker!.state, NutritionMarkerState.informative);
    expect(_node(vm, 'germination').marker!.noteEs, contains('no pesa'));
    final NutritionMarkerVm v6 = _node(vm, 'vegEarly').marker!;
    expect(v6.state, NutritionMarkerState.attended, reason: 'registro en vegmid ≡ regla V6–V8');
    expect(v6.noteEs, ResponseVerdict.compatible.labelEs);
    expect(v6.evidenceEs, isNotEmpty);
    expect(_node(vm, 'vegAdvanced').marker!.state, NutritionMarkerState.unattended);
  });

  test('declaración «una sola vez» en arcilla: un solo marcador de N, en V6–V8', () {
    final NutritionPlanResolution plan = NutritionWindowPlanResolver.resolve(
      guide: kNutritionGuides['maize'],
      texture: SoilTexture.clay,
      declaration: NutritionSeasonDeclaration(
        deviceId: 'dev',
        seasonKey: _season,
        cropKey: 'maize',
        passes: NitrogenPassPlan.single,
        declaredAt: DateTime(2026, 4, 2),
      ),
      seasonKey: _season,
      currentStageKey: 'vegMid',
    );
    final NutritionTimelineVm vm = NutritionTimelineVm.build(
      schedule: _maizeSchedule(),
      currentStageKey: 'vegMid',
      plan: plan,
      seasonKey: _season,
      windows: <NutritionWindowRecord>[
        _record('germination', NutritionWindowOutcome.attendedDetected, critical: false),
      ],
    );
    expect(vm.awaitingDeclaration, isFalse);
    // Exactamente UNA fertilización de nitrógeno en la línea: V6–V8, con el
    // plan completo. El fondo sigue como ventana de fósforo y potasio (sin
    // N) y V10–V12 desaparece: ya no es una fertilización.
    expect(vm.markerCount, 2);
    final NutritionMarkerVm fondo = _node(vm, 'germination').marker!;
    expect(fondo.state, NutritionMarkerState.attended);
    expect(fondo.nutrients, <AgroMetricKey>[AgroMetricKey.p, AgroMetricKey.k]);
    expect(fondo.isFolded, isTrue);
    expect(fondo.noteEs, contains('va en otra pasada según tu plan'));
    expect(fondo.doses.map((d) => d.nutrient), isNot(contains(AgroMetricKey.n)));

    final NutritionMarkerVm v6 = _node(vm, 'vegEarly').marker!;
    expect(v6.state, NutritionMarkerState.open);
    expect(v6.isFolded, isFalse);
    expect(v6.nutrients, <AgroMetricKey>[AgroMetricKey.n]);
    final TimelineDose n = v6.doses.single;
    expect(n.range.min, closeTo(160, 1e-6));
    expect(n.range.max, closeTo(240, 1e-6));
    expect(_node(vm, 'vegAdvanced').hasMarker, isFalse, reason: 'plegada del todo: sin marcador');
    expect(
      vm.nodes.where((TimelineNodeVm x) => x.marker?.nutrients.contains(AgroMetricKey.n) ?? false).length,
      1,
      reason: 'una sola vez = una insignia de N',
    );
    expect(vm.planSummaryEs, '1 fertilización de nitrógeno · tu plan');
  });

  test('declaración «ya fertilicé»: ninguna insignia de N, el fondo queda como P y K', () {
    final NutritionPlanResolution plan = NutritionWindowPlanResolver.resolve(
      guide: kNutritionGuides['maize'],
      texture: SoilTexture.loam,
      declaration: NutritionSeasonDeclaration(
        deviceId: 'dev',
        seasonKey: _season,
        cropKey: 'maize',
        passes: NitrogenPassPlan.alreadyDone,
        declaredAt: DateTime(2026, 5, 20),
      ),
      seasonKey: _season,
      currentStageKey: 'vegAdvanced',
    );
    final NutritionTimelineVm vm = NutritionTimelineVm.build(
      schedule: _maizeSchedule(),
      currentStageKey: 'vegAdvanced',
      plan: plan,
      seasonKey: _season,
    );
    expect(vm.isAlreadyDone, isTrue);
    expect(vm.awaitingDeclaration, isFalse);
    expect(vm.markerCount, 1);
    expect(_node(vm, 'germination').marker!.nutrients, <AgroMetricKey>[AgroMetricKey.p, AgroMetricKey.k]);
    expect(_node(vm, 'germination').marker!.noteEs, contains('ya fertilizaste'));
    expect(_node(vm, 'vegEarly').hasMarker, isFalse);
    expect(_node(vm, 'vegAdvanced').hasMarker, isFalse);
    expect(vm.planSummaryEs, 'Nitrógeno ya aplicado · tu plan');
  });

  test('en huerto la dosis se muestra en g/m²', () {
    final NutritionPlanResolution plan = NutritionWindowPlanResolver.resolve(
      guide: kNutritionGuides['maize'],
      texture: SoilTexture.sandy,
      seasonKey: _season,
      currentStageKey: 'vegMid',
    );
    final NutritionTimelineVm vm = NutritionTimelineVm.build(
      schedule: _maizeSchedule(),
      currentStageKey: 'vegMid',
      plan: plan,
      seasonKey: _season,
      cultivationScaleId: 'orchard',
    );
    final TimelineDose n = _node(vm, 'vegEarly').marker!.doses.single;
    expect(n.range.unit, DoseUnit.gramsPerSquareMeter);
    expect(n.range.min, closeTo(6.4, 1e-6));
  });
}
