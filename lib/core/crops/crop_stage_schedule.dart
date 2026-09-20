// lib/core/crops/crop_stage_schedule.dart
//
// CALENDARIO DE ETAPAS de un cultivo: la lista ORDENADA de etapas del ciclo,
// con su rango de días esperado cuando el eje es la siembra.
//
// Por qué existe: los motores fenológicos solo calculan la etapa ACTUAL
// (`CropEngine.compute`). La línea de tiempo de la pantalla de cultivo y la
// vista del plan nutricional necesitan el ciclo completo —qué etapas hay,
// en qué orden, cuál es la de hoy— sin duplicar las tablas de días que cada
// motor ya tiene.
//
// Cómo lo resuelve sin tocar 17 motores: MUESTREA el propio motor día a día
// desde la siembra y registra las transiciones. Es la misma función pura que
// el runtime ya llama para anticipar la etapa siguiente
// (`NutritionCoordinator.buildInput`), así que el calendario coincide con lo
// que el motor decide, incluidos los modos de establecimiento (trasplante
// omite «germinación» en berenjena y calabaza) y los perfiles por variedad.
//
// Árboles y ornamentales no tienen eje de días: su lista sale de la máquina
// de etapas del árbol (`TreeStageIds`, ciclo completo) o de sus ids ordenados,
// y la etapa la declara el productor.
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/recurring_bloom/recurring_bloom_crops.dart';
import 'package:bio_g/core/crops/rose/rose_lifecycle.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';

/// Qué eje ordena las etapas.
enum CropStageAxis {
  /// Días desde la siembra (anuales, bulbos, ornamentales anuales).
  days,

  /// Ciclo anual del árbol: la última etapa vuelve a la primera.
  perennialCycle,

  /// Etapas declaradas/confirmadas por el productor sin reloj (ornamentales
  /// de establecimiento, rosal).
  declared,
}

/// Una etapa del ciclo.
class CropStageSlot {
  const CropStageSlot({
    required this.stageKey,
    required this.labelEs,
    this.dayStart,
    this.dayEnd,
    this.hasNutritionWindow = false,
  });

  /// Clave tal como la emite el motor (`vegEarly`, `fruit_fill`…).
  final String stageKey;
  final String labelEs;

  /// Primer y último día del ciclo (base 1) en que el motor reporta esta
  /// etapa. `dayEnd` null = abierta (la última etapa no termina).
  final int? dayStart;
  final int? dayEnd;

  /// El motor fenológico marca ventana de nutrición en esta etapa (solo
  /// informativo: la ventana real la abre la guía).
  final bool hasNutritionWindow;

  bool get isOpenEnded => dayStart != null && dayEnd == null;

  CropStageSlot copyWith({int? dayEnd}) => CropStageSlot(
    stageKey: stageKey,
    labelEs: labelEs,
    dayStart: dayStart,
    dayEnd: dayEnd ?? this.dayEnd,
    hasNutritionWindow: hasNutritionWindow,
  );

  /// `vegEarly`, `veg_early`, `VEG-EARLY` → `vegearly`.
  static String normalizeKey(String? raw) => (raw ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s_\-]+'), '');

  bool matches(String? stageKey) =>
      normalizeKey(this.stageKey) == normalizeKey(stageKey);
}

/// El ciclo completo, ordenado.
class CropStageSchedule {
  const CropStageSchedule({
    required this.axis,
    required this.slots,
    required this.cropKey,
    this.cycleStartIndex,
  });

  final CropStageAxis axis;
  final List<CropStageSlot> slots;
  final String cropKey;

  /// En un árbol, índice de la etapa donde arranca el ciclo anual (reposo):
  /// la última etapa vuelve a esta, no a la primera (plantación). Null si el
  /// ciclo no da la vuelta.
  final int? cycleStartIndex;

  bool get isEmpty => slots.isEmpty;
  int get length => slots.length;

  /// Posición de la etapa en el ciclo, o −1.
  int indexOf(String? stageKey) {
    for (int i = 0; i < slots.length; i++) {
      if (slots[i].matches(stageKey)) return i;
    }
    return -1;
  }

  CropStageSlot? slotFor(String? stageKey) {
    final int i = indexOf(stageKey);
    return i < 0 ? null : slots[i];
  }

  /// Días del ciclo hasta el inicio de la última etapa (null sin eje de días).
  int? get lastStageStartDay => axis == CropStageAxis.days && slots.isNotEmpty
      ? slots.last.dayStart
      : null;
}

class CropStageScheduleResolver {
  const CropStageScheduleResolver._();

  /// Tope de muestreo: el ciclo más largo del catálogo (ajo, ~280 días) cabe
  /// con holgura; tulipán entra en dormancia abierta y se corta aquí.
  static const int maxSampledDays = 420;

  static final Map<String, CropStageSchedule> _cache = <String, CropStageSchedule>{};
  static const int _cacheLimit = 12;

  /// Calendario del runtime actual, o null si no hay cultivo/perfil.
  static CropStageSchedule? resolve(CropRuntimeSnapshot runtime) {
    final String cropId = runtime.cropKeyName;
    if (cropId.isEmpty || runtime.isGenericMode || runtime.isGuideMode) {
      return null;
    }
    final String? categoryId = runtime.cropContext?.cropCategoryId;
    final category = runtime.definition?.category;

    if (isPerennialCrop(cropId: cropId, cropCategoryId: categoryId, category: category)) {
      return _tree(cropId);
    }
    if (isRecurringBloomCrop(cropId: cropId, cropCategoryId: categoryId, category: category)) {
      return _rose(cropId);
    }
    if (isEstablishmentMaintenanceCrop(cropId: cropId, cropCategoryId: categoryId, category: category)) {
      return _ornamental(cropId);
    }

    final definition = runtime.definition;
    final CropProfile? profile = runtime.profile;
    if (definition == null || profile == null) return null;
    final DateTime? sowing = runtime.engineSowingDate ??
        runtime.cropContext?.sowingDate ??
        runtime.effectiveLifecycleDate;
    if (sowing == null) return null;

    final DateTime anchor = DateTime.utc(sowing.year, sowing.month, sowing.day);
    final String key = '$cropId|${profile.id}|${anchor.toIso8601String()}';
    final CropStageSchedule? cached = _cache[key];
    if (cached != null) return cached;

    final List<CropStageSlot> slots = sample(
      engine: definition.engine,
      profile: profile,
      sowing: anchor,
    );
    if (slots.isEmpty) return null;
    final CropStageSchedule schedule = CropStageSchedule(
      axis: CropStageAxis.days,
      slots: List<CropStageSlot>.unmodifiable(slots),
      cropKey: cropId,
    );
    if (_cache.length >= _cacheLimit) _cache.remove(_cache.keys.first);
    _cache[key] = schedule;
    return schedule;
  }

  /// Muestrea el motor día a día y devuelve las etapas en orden de aparición.
  /// Público para las pruebas.
  static List<CropStageSlot> sample({
    required CropEngine engine,
    required CropProfile profile,
    required DateTime sowing,
    int maxDays = maxSampledDays,
  }) {
    final List<CropStageSlot> slots = <CropStageSlot>[];
    String? lastKey;
    for (int day = 1; day <= maxDays; day++) {
      CropStageResult result;
      try {
        result = engine.compute(
          sowingDate: sowing,
          today: sowing.add(Duration(days: day - 1)),
          profile: profile,
          stressDelayDays: 0,
        );
      } catch (_) {
        break;
      }
      final String stageKey = result.stageKey.trim();
      if (stageKey.isEmpty) continue;
      if (stageKey == lastKey) continue;
      // Un motor que «retrocede» a una etapa ya vista (no debería) no
      // duplica la fila: se ignora la transición.
      if (slots.any((CropStageSlot s) => s.stageKey == stageKey)) continue;
      if (slots.isNotEmpty) {
        slots[slots.length - 1] = slots.last.copyWith(dayEnd: day - 1);
      }
      slots.add(
        CropStageSlot(
          stageKey: stageKey,
          labelEs: result.stageLabelEs.trim().isEmpty
              ? stageKey
              : result.stageLabelEs.trim(),
          dayStart: day,
          hasNutritionWindow: _hasNutrition(result.windowsNow),
        ),
      );
      lastKey = stageKey;
    }
    return slots;
  }

  static bool _hasNutrition(List<dynamic> windows) {
    for (final dynamic w in windows) {
      final String s = w.toString().toLowerCase();
      if (s == 'nutrition' || s.endsWith('.nutrition')) return true;
    }
    return false;
  }

  // ── Árboles ───────────────────────────────────────────────────────────────

  static const List<String> _treeCycleOrder = <String>[
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

  /// Índice de «reposo» en [_treeCycleOrder]: donde arranca el ciclo anual.
  static const int _treeCycleStart = 3;

  /// Árboles: el ciclo COMPLETO y cronológico (decisión de producto, 14 sep
  /// 2026): plantación → establecimiento radicular → juvenil, y después el
  /// ciclo anual que da la vuelta (reposo → brotación → … → post-cosecha).
  /// Un árbol recién plantado ve por delante todo lo que le falta; uno en
  /// producción ve de dónde viene. La etapa actual la señala el productor.
  static CropStageSchedule _tree(String cropId) {
    return CropStageSchedule(
      axis: CropStageAxis.perennialCycle,
      cropKey: cropId,
      cycleStartIndex: _treeCycleStart,
      slots: List<CropStageSlot>.unmodifiable(<CropStageSlot>[
        for (final String k in _treeCycleOrder)
          CropStageSlot(
            stageKey: k,
            labelEs: treeStageDisplayNameForCrop(cropId, k),
          ),
      ]),
    );
  }

  // ── Ornamentales ──────────────────────────────────────────────────────────

  static const List<String> _establishmentOrder = <String>[
    'installation_establishment',
    'root_establishment',
    'active_growth',
    'maintenance',
    'rest',
  ];

  static CropStageSchedule _ornamental(String cropId) {
    return CropStageSchedule(
      axis: CropStageAxis.declared,
      cropKey: cropId,
      slots: List<CropStageSlot>.unmodifiable(<CropStageSlot>[
        for (final String k in _establishmentOrder)
          CropStageSlot(
            stageKey: k,
            labelEs: ornamentalStageDisplayName(cropId, k),
          ),
      ]),
    );
  }

  static const List<String> _roseOrder = <String>[
    RoseStageIds.installationEstablishment,
    RoseStageIds.rootEstablishment,
    RoseStageIds.vegetativeFlush,
    RoseStageIds.budFormation,
    RoseStageIds.flowering,
    RoseStageIds.postBloomRecovery,
    RoseStageIds.rest,
  ];

  static CropStageSchedule _rose(String cropId) {
    return CropStageSchedule(
      axis: CropStageAxis.declared,
      cropKey: cropId,
      slots: List<CropStageSlot>.unmodifiable(<CropStageSlot>[
        for (final String k in _roseOrder)
          CropStageSlot(stageKey: k, labelEs: roseStageDisplayName(k)),
      ]),
    );
  }

  /// Solo para pruebas.
  static void clearCache() => _cache.clear();
}
