// test/core/crops/crop_stage_schedule_test.dart
//
// El calendario de etapas se obtiene MUESTREANDO el motor de cada cultivo:
// debe salir ordenado, contiguo en días y con la última etapa abierta. Para
// árboles sale de la máquina de estados, sin días.
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_stage_schedule.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:flutter_test/flutter_test.dart';

const List<CropKey> _dayAxisCrops = <CropKey>[
  CropKey.maize,
  CropKey.wheat,
  CropKey.barley,
  CropKey.bean,
  CropKey.oat,
  CropKey.tomato,
  CropKey.cucumber,
  CropKey.chili,
  CropKey.eggplant,
  CropKey.squash,
  CropKey.lettuce,
  CropKey.spinach,
  CropKey.onion,
  CropKey.garlic,
  CropKey.tulip,
  CropKey.sunflower,
  CropKey.marigold,
];

List<CropStageSlot> _sampleFor(CropKey key) {
  final CropDefinition def = CropRegistry.byKey(key)!;
  final CropProfile profile = def.resolveProfile()!;
  return CropStageScheduleResolver.sample(
    engine: def.engine,
    profile: profile,
    sowing: DateTime.utc(2026, 4, 1),
  );
}

CropRuntimeSnapshot _treeRuntime({
  required CropKey key,
  required String cropKeyName,
  required String stageKey,
  required String stateId,
}) {
  final CropDefinition def = CropRegistry.byKey(key)!;
  return CropRuntimeSnapshot(
    device: null,
    live: null,
    seed: null,
    cropContext: null,
    definition: def,
    profile: null,
    stageResult: CropStageResult(
      stageKey: stageKey,
      stageLabelEs: stageKey,
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: '',
      productiveState: stateId,
    ),
    targets: null,
    eval: null,
    nextAlertsState: const AlertsState(),
    cropKeyName: cropKeyName,
    cropLabel: cropKeyName,
    cropIconAsset: '',
    stageLabel: stageKey,
    sowingStatus: SowingStatus.planted,
    engineSowingDate: null,
    hasSeed: true,
    isPlanted: true,
    isPlanned: false,
    isGenericMode: false,
  );
}

void main() {
  setUp(CropStageScheduleResolver.clearCache);

  group('muestreo de motores de siembra', () {
    for (final CropKey key in _dayAxisCrops) {
      test('$key: etapas ordenadas, contiguas y con final abierto', () {
        final List<CropStageSlot> slots = _sampleFor(key);
        expect(slots.length, greaterThanOrEqualTo(3), reason: '$key');
        expect(slots.first.dayStart, 1, reason: '$key: arranca el día 1');
        for (int i = 0; i < slots.length; i++) {
          final CropStageSlot s = slots[i];
          expect(s.stageKey, isNotEmpty, reason: '$key[$i]');
          expect(s.labelEs, isNotEmpty, reason: '$key[$i]');
          expect(s.dayStart, isNotNull, reason: '$key[$i]');
          if (i + 1 < slots.length) {
            expect(s.dayEnd, isNotNull, reason: '$key[$i] cierra');
            expect(s.dayEnd! + 1, slots[i + 1].dayStart, reason: '$key[$i] contiguo');
            expect(s.dayEnd!, greaterThanOrEqualTo(s.dayStart!), reason: '$key[$i]');
          } else {
            expect(s.dayEnd, isNull, reason: '$key: la última etapa queda abierta');
          }
        }
        final Set<String> unique = slots.map((s) => s.stageKey).toSet();
        expect(unique.length, slots.length, reason: '$key: sin etapas repetidas');
      });
    }

    test('maíz recorre sus nueve etapas en el orden del motor', () {
      final List<String> keys = _sampleFor(CropKey.maize).map((s) => s.stageKey).toList();
      expect(keys, MaizeStageKey.values.map((e) => e.name).toList());
      final CropStageSlot vegMid = _sampleFor(CropKey.maize)[3];
      expect(vegMid.stageKey, 'vegMid');
      expect(vegMid.hasNutritionWindow, isTrue);
    });
  });

  group('árboles y ornamentales', () {
    const List<String> fullTreeCycle = <String>[
      TreeStageIds.plantingTransplant,
      TreeStageIds.rootEstablishment,
      TreeStageIds.juvenileVegetative,
      TreeStageIds.dormancy,
      TreeStageIds.budbreak,
      TreeStageIds.vegetativeGrowth,
      TreeStageIds.flowering,
      TreeStageIds.fruitSet,
      TreeStageIds.fruitFill,
      TreeStageIds.harvestMaturity,
      TreeStageIds.postHarvest,
    ];

    test('nogal establecido: las once etapas cronológicas, sin días, con ciclo', () {
      final CropStageSchedule s = CropStageScheduleResolver.resolve(
        _treeRuntime(
          key: CropKey.walnutTree,
          cropKeyName: 'walnut_tree',
          stageKey: TreeStageIds.fruitFill,
          stateId: TreeStateIds.established,
        ),
      )!;
      expect(s.axis, CropStageAxis.perennialCycle);
      expect(s.slots.map((e) => e.stageKey).toList(), fullTreeCycle);
      expect(s.cycleStartIndex, 3, reason: 'el ciclo anual arranca en reposo');
      expect(s.indexOf(TreeStageIds.fruitFill), 8);
      expect(s.slots.every((e) => e.dayStart == null), isTrue);
      expect(s.slots[8].labelEs, contains('nuez'), reason: 'dialecto del nogal');
    });

    test('árbol recién plantado: también ve el ciclo completo por delante', () {
      final CropStageSchedule s = CropStageScheduleResolver.resolve(
        _treeRuntime(
          key: CropKey.avocadoTree,
          cropKeyName: 'avocado_tree',
          stageKey: TreeStageIds.rootEstablishment,
          stateId: TreeStateIds.newlyPlanted,
        ),
      )!;
      expect(s.slots.map((e) => e.stageKey).toList(), fullTreeCycle);
      expect(s.length, 11);
      expect(s.indexOf('root_establishment'), 1);
      expect(s.slots[1].labelEs, 'Establecimiento radicular');
    });

    test('cactus: cinco etapas declaradas', () {
      final CropStageSchedule s = CropStageScheduleResolver.resolve(
        _treeRuntime(
          key: CropKey.cactus,
          cropKeyName: 'cactus',
          stageKey: 'active_growth',
          stateId: 'unknown',
        ),
      )!;
      expect(s.axis, CropStageAxis.declared);
      expect(s.length, 5);
      expect(s.indexOf('active_growth'), 2);
    });
  });

  test('normalización de claves: vegEarly ≡ veg_early ≡ VEG-EARLY', () {
    const CropStageSlot slot = CropStageSlot(stageKey: 'vegEarly', labelEs: 'x');
    expect(slot.matches('veg_early'), isTrue);
    expect(slot.matches('VEG-EARLY'), isTrue);
    expect(slot.matches('vegMid'), isFalse);
  });
}
