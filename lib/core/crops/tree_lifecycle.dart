import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/models/device_crop_context.dart';

class TreeStateIds {
  const TreeStateIds._();

  static const String newlyPlanted = 'newly_planted';
  static const String juvenileNonProductive = 'juvenile_non_productive';
  static const String established = 'established';
  static const String productiveSeason = 'productive_season';
  static const String unknown = 'unknown';
}

class TreeStageIds {
  const TreeStageIds._();

  static const String plantingTransplant = 'planting_transplant';
  static const String rootEstablishment = 'root_establishment';
  static const String juvenileVegetative = 'juvenile_vegetative';
  static const String dormancy = 'dormancy';
  static const String budbreak = 'budbreak';
  static const String vegetativeGrowth = 'vegetative_growth';
  static const String flowering = 'flowering';
  static const String fruitSet = 'fruit_set';
  static const String fruitFill = 'fruit_fill';
  static const String harvestMaturity = 'harvest_maturity';
  static const String postHarvest = 'post_harvest';
  static const String unknown = 'unknown';
}

class TreeAnchorTypeIds {
  const TreeAnchorTypeIds._();

  static const String planting = 'planting';
  static const String stageStart = 'stage_start';
  static const String budbreak = 'budbreak';
  static const String flowering = 'flowering';
  static const String harvest = 'harvest';
  static const String postHarvest = 'post_harvest';
  static const String manualStage = 'manual_stage';
  static const String unknown = 'unknown';
}

class TreeProductionStatusIds {
  const TreeProductionStatusIds._();

  static const String nonProductive = 'non_productive';
  static const String productiveOrProduced = 'productive_or_produced';
  static const String unknown = 'unknown';
}

class TreeVisibleStageSelection {
  const TreeVisibleStageSelection({
    required this.perennialStateId,
    required this.phenologyStageId,
    required this.perennialAnchorTypeId,
  });

  final String perennialStateId;
  final String phenologyStageId;
  final String perennialAnchorTypeId;

  bool get hasKnownStage =>
      perennialStateId != TreeStateIds.unknown &&
      phenologyStageId != TreeStageIds.unknown;
}

class TreeStateStagePolicy {
  final Set<String> allowedStages;
  final Set<String> blockedStages;
  final bool productionEnabled;
  final bool productionKnown;

  const TreeStateStagePolicy({
    required this.allowedStages,
    this.blockedStages = const <String>{},
    required this.productionEnabled,
    this.productionKnown = true,
  });
}

const Map<String, TreeStateStagePolicy> treeStateStagePolicies =
    <String, TreeStateStagePolicy>{
      TreeStateIds.newlyPlanted: TreeStateStagePolicy(
        allowedStages: <String>{
          TreeStageIds.plantingTransplant,
          TreeStageIds.rootEstablishment,
          TreeStageIds.juvenileVegetative,
          TreeStageIds.unknown,
        },
        blockedStages: <String>{
          TreeStageIds.flowering,
          TreeStageIds.fruitSet,
          TreeStageIds.fruitFill,
          TreeStageIds.harvestMaturity,
          TreeStageIds.postHarvest,
        },
        productionEnabled: false,
      ),
      TreeStateIds.juvenileNonProductive: TreeStateStagePolicy(
        allowedStages: <String>{
          TreeStageIds.juvenileVegetative,
          TreeStageIds.dormancy,
          TreeStageIds.vegetativeGrowth,
          TreeStageIds.unknown,
        },
        blockedStages: <String>{
          TreeStageIds.flowering,
          TreeStageIds.fruitSet,
          TreeStageIds.fruitFill,
          TreeStageIds.harvestMaturity,
        },
        productionEnabled: false,
      ),
      TreeStateIds.established: TreeStateStagePolicy(
        allowedStages: <String>{
          TreeStageIds.dormancy,
          TreeStageIds.budbreak,
          TreeStageIds.vegetativeGrowth,
          TreeStageIds.flowering,
          TreeStageIds.fruitSet,
          TreeStageIds.fruitFill,
          TreeStageIds.harvestMaturity,
          TreeStageIds.postHarvest,
          TreeStageIds.unknown,
        },
        productionEnabled: true,
      ),
      TreeStateIds.productiveSeason: TreeStateStagePolicy(
        allowedStages: <String>{
          TreeStageIds.dormancy,
          TreeStageIds.budbreak,
          TreeStageIds.vegetativeGrowth,
          TreeStageIds.flowering,
          TreeStageIds.fruitSet,
          TreeStageIds.fruitFill,
          TreeStageIds.harvestMaturity,
          TreeStageIds.postHarvest,
          TreeStageIds.unknown,
        },
        productionEnabled: true,
      ),
      TreeStateIds.unknown: TreeStateStagePolicy(
        allowedStages: <String>{
          TreeStageIds.unknown,
          TreeStageIds.dormancy,
          TreeStageIds.budbreak,
          TreeStageIds.vegetativeGrowth,
          TreeStageIds.flowering,
          TreeStageIds.fruitSet,
          TreeStageIds.fruitFill,
          TreeStageIds.harvestMaturity,
          TreeStageIds.postHarvest,
        },
        productionEnabled: false,
        productionKnown: false,
      ),
    };

bool isTreeCrop({
  String? cropId,
  String? cropCategoryId,
  CropCategory? category,
}) {
  if (category == CropCategory.tree) return true;

  final normalizedCategory = cropCategoryId?.trim().toLowerCase();
  if (normalizedCategory == CropCatalog.treeCategoryId) return true;

  // Sin atajo específico del manzano: la categoría manda. Cualquier cultivo
  // cuyo catálogo lo clasifique como árbol (incluido apple_tree y futuros
  // frutales) se detecta por su categoryId, no por un id hardcodeado.
  final canonicalCropId = CropCatalog.canonicalCropKey(cropId);
  final catalogCrop = CropCatalog.cropById(canonicalCropId);
  return catalogCrop?.categoryId == CropCatalog.treeCategoryId;
}

bool isPerennialCrop({
  String? cropId,
  String? cropCategoryId,
  CropCategory? category,
}) {
  return isTreeCrop(
    cropId: cropId,
    cropCategoryId: cropCategoryId,
    category: category,
  );
}

bool isTreeProductionEnabled(String? perennialStateId) {
  final stateId = normalizeTreeStateId(perennialStateId);
  return treeStateStagePolicies[stateId]?.productionEnabled ?? false;
}

String normalizeTreeProductionStatusId(String? productionStatusId) {
  final value = productionStatusId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return TreeProductionStatusIds.unknown;

  switch (value) {
    case TreeProductionStatusIds.nonProductive:
    case TreeProductionStatusIds.productiveOrProduced:
    case TreeProductionStatusIds.unknown:
      return value;
  }

  return TreeProductionStatusIds.unknown;
}

String inferTreeProductionStatusId({
  required String? perennialStateId,
  String? phenologyStageId,
}) {
  final stateId = normalizeTreeStateId(perennialStateId);
  switch (stateId) {
    case TreeStateIds.newlyPlanted:
    case TreeStateIds.juvenileNonProductive:
      return TreeProductionStatusIds.nonProductive;
    case TreeStateIds.established:
    case TreeStateIds.productiveSeason:
      return TreeProductionStatusIds.productiveOrProduced;
    case TreeStateIds.unknown:
      return TreeProductionStatusIds.unknown;
  }

  return TreeProductionStatusIds.unknown;
}

String treeProductionStatusDisplayName(String? productionStatusId) {
  final statusId = normalizeTreeProductionStatusId(productionStatusId);
  return switch (statusId) {
    TreeProductionStatusIds.nonProductive => 'Aún no produce',
    TreeProductionStatusIds.productiveOrProduced =>
      'Ya produce o ya ha producido',
    _ => 'No estoy seguro',
  };
}

TreeVisibleStageSelection resolveTreeVisibleStageSelection({
  required String? productionStatusId,
  required String? visibleStageId,
}) {
  final statusId = normalizeTreeProductionStatusId(productionStatusId);
  final stageId = normalizeTreeStageId(visibleStageId);

  if (statusId == TreeProductionStatusIds.unknown ||
      stageId == TreeStageIds.unknown) {
    return const TreeVisibleStageSelection(
      perennialStateId: TreeStateIds.unknown,
      phenologyStageId: TreeStageIds.unknown,
      perennialAnchorTypeId: TreeAnchorTypeIds.unknown,
    );
  }

  if (statusId == TreeProductionStatusIds.nonProductive) {
    return switch (stageId) {
      TreeStageIds.plantingTransplant => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.plantingTransplant,
        perennialAnchorTypeId: TreeAnchorTypeIds.planting,
      ),
      TreeStageIds.rootEstablishment => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.newlyPlanted,
        phenologyStageId: TreeStageIds.rootEstablishment,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      TreeStageIds.juvenileVegetative => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.juvenileNonProductive,
        phenologyStageId: TreeStageIds.juvenileVegetative,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      TreeStageIds.dormancy => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.juvenileNonProductive,
        phenologyStageId: TreeStageIds.dormancy,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      // Primera floración: un árbol que nunca había dado fruta pero que este
      // año ya muestra señal reproductiva entra a producción de temporada. La
      // fenología visible manda; el matiz de "primer año" es de rendimiento.
      TreeStageIds.flowering => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.flowering,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      TreeStageIds.fruitSet => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitSet,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      TreeStageIds.fruitFill => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      _ => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.unknown,
        phenologyStageId: TreeStageIds.unknown,
        perennialAnchorTypeId: TreeAnchorTypeIds.unknown,
      ),
    };
  }

  if (statusId == TreeProductionStatusIds.productiveOrProduced) {
    return switch (stageId) {
      TreeStageIds.dormancy => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.established,
        phenologyStageId: TreeStageIds.dormancy,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      TreeStageIds.budbreak => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.established,
        phenologyStageId: TreeStageIds.budbreak,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      TreeStageIds.vegetativeGrowth => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.established,
        phenologyStageId: TreeStageIds.vegetativeGrowth,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      TreeStageIds.flowering => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.flowering,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      TreeStageIds.fruitSet => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitSet,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      TreeStageIds.fruitFill => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.fruitFill,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      TreeStageIds.harvestMaturity => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.harvestMaturity,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      TreeStageIds.postHarvest => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.established,
        phenologyStageId: TreeStageIds.postHarvest,
        perennialAnchorTypeId: TreeAnchorTypeIds.stageStart,
      ),
      _ => const TreeVisibleStageSelection(
        perennialStateId: TreeStateIds.unknown,
        phenologyStageId: TreeStageIds.unknown,
        perennialAnchorTypeId: TreeAnchorTypeIds.unknown,
      ),
    };
  }

  return const TreeVisibleStageSelection(
    perennialStateId: TreeStateIds.unknown,
    phenologyStageId: TreeStageIds.unknown,
    perennialAnchorTypeId: TreeAnchorTypeIds.unknown,
  );
}

bool isTreeStageAllowed(String? perennialStateId, String? phenologyStageId) {
  final rawStage = phenologyStageId?.trim();
  if (rawStage != null &&
      rawStage.isNotEmpty &&
      !isKnownTreeStageId(rawStage)) {
    return false;
  }

  final stateId = normalizeTreeStateId(perennialStateId);
  final stageId = normalizeTreeStageId(phenologyStageId);
  final policy =
      treeStateStagePolicies[stateId] ??
      treeStateStagePolicies[TreeStateIds.unknown]!;
  return policy.allowedStages.contains(stageId);
}

bool isTreeCriticalStage(String? phenologyStageId) {
  final stageId = normalizeTreeStageId(phenologyStageId);
  return stageId == TreeStageIds.flowering ||
      stageId == TreeStageIds.fruitSet ||
      stageId == TreeStageIds.rootEstablishment ||
      stageId == TreeStageIds.postHarvest;
}

bool isTreeContext(DeviceCropContext? context) {
  if (context == null) return false;
  return isTreeCrop(
    cropId: context.cropId,
    cropCategoryId: context.cropCategoryId,
  );
}

String treeCropDisplayTitle(DeviceCropContext context) {
  final cropName = CropCatalog.cropDisplayName(context.cropId);
  final stageId = normalizeTreeStageId(context.phenologyStageId);
  if (stageId == TreeStageIds.unknown) {
    return '$cropName · Perfil general';
  }
  return '$cropName · ${treeStageDisplayName(stageId)}';
}

String treeStageDisplayName(String? phenologyStageId) {
  final stageId = normalizeTreeStageId(phenologyStageId);
  return switch (stageId) {
    TreeStageIds.plantingTransplant => 'Plantaci\u00f3n / trasplante',
    TreeStageIds.rootEstablishment => 'Establecimiento radicular',
    TreeStageIds.juvenileVegetative => 'Crecimiento juvenil',
    TreeStageIds.dormancy => 'Reposo',
    TreeStageIds.budbreak => 'Brotaci\u00f3n',
    TreeStageIds.vegetativeGrowth => 'Desarrollo vegetativo',
    TreeStageIds.flowering => 'Floraci\u00f3n',
    TreeStageIds.fruitSet => 'Cuajado',
    TreeStageIds.fruitFill => 'Llenado de fruto',
    TreeStageIds.harvestMaturity => 'Maduraci\u00f3n / cosecha',
    TreeStageIds.postHarvest => 'Post-cosecha',
    _ => 'Etapa no definida',
  };
}

String treeStateDisplayName(String? perennialStateId) {
  final stateId = normalizeTreeStateId(perennialStateId);
  return switch (stateId) {
    TreeStateIds.newlyPlanted => 'Reci\u00e9n plantado',
    TreeStateIds.juvenileNonProductive =>
      'En crecimiento, todav\u00eda no produce',
    TreeStateIds.established => '\u00c1rbol establecido',
    TreeStateIds.productiveSeason => 'En producci\u00f3n esta temporada',
    _ => 'Estado general',
  };
}

String treeProfileDisplayName(String? profileId) {
  final profile = CropCatalog.profileByAny(
    CropCatalog.appleTreeCropId,
    profileId,
  );
  final id = profile?.id ?? profileId?.trim().toLowerCase();

  return switch (id) {
    CropCatalog.appleTreeDefaultProfileId => 'Perfil general',
    'ap_01_golden' => 'Golden',
    'ap_02_red' => 'Red',
    'ap_03_criolla_rayada' => 'Criolla / Rayada',
    'ap_04_gala' => 'Gala',
    'ap_05_low_chill' => 'Bajo requerimiento de fr\u00edo',
    _ => profile?.label ?? 'Perfil general',
  };
}

String treeAnchorDisplayText(DateTime? anchorDate, String? anchorTypeId) {
  if (anchorDate == null) return 'Tiempo aproximado no recordado';

  final today = DateTime.now();
  final anchorDay = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  final days = todayDay.difference(anchorDay).inDays;
  final ageText = days <= 0
      ? 'hoy'
      : days == 1
      ? 'hace 1 d\u00eda'
      : days < 30
      ? 'hace $days d\u00edas'
      : days < 60
      ? 'hace 1 mes'
      : 'hace ${(days / 30).round()} meses';

  final typeId = (anchorTypeId ?? '').trim().toLowerCase();
  return switch (typeId) {
    TreeAnchorTypeIds.planting => 'Plantaci\u00f3n aproximada: $ageText',
    TreeAnchorTypeIds.budbreak => 'Brotaci\u00f3n aproximada: $ageText',
    TreeAnchorTypeIds.flowering => 'Floraci\u00f3n aproximada: $ageText',
    TreeAnchorTypeIds.harvest => 'Cosecha aproximada: $ageText',
    TreeAnchorTypeIds.postHarvest => 'Post-cosecha desde $ageText',
    TreeAnchorTypeIds.manualStage => 'Etapa ajustada $ageText',
    TreeAnchorTypeIds.stageStart => 'Etapa desde $ageText',
    _ => 'Referencia aproximada: $ageText',
  };
}

String? treeCriticalWindowLabel(String? phenologyStageId) {
  final stageId = normalizeTreeStageId(phenologyStageId);
  return switch (stageId) {
    TreeStageIds.flowering => 'Ventana cr\u00edtica: floraci\u00f3n',
    TreeStageIds.fruitSet => 'Ventana cr\u00edtica: cuajado',
    TreeStageIds.postHarvest =>
      'Ventana importante: recuperaci\u00f3n post-cosecha',
    TreeStageIds.rootEstablishment =>
      'Ventana cr\u00edtica: establecimiento radicular',
    _ => null,
  };
}

String treeStagePriorityText(String? phenologyStageId) {
  final stageId = normalizeTreeStageId(phenologyStageId);
  return switch (stageId) {
    TreeStageIds.rootEstablishment =>
      'Prioridad: humedad estable, suelo aireado y ra\u00edces',
    TreeStageIds.flowering =>
      'Floraci\u00f3n activa: peque\u00f1as desviaciones importan',
    TreeStageIds.fruitSet =>
      'Cuajado activo: evita estr\u00e9s h\u00eddrico o t\u00e9rmico',
    TreeStageIds.fruitFill =>
      'Llenado de fruto: estabilidad para calidad y tama\u00f1o',
    TreeStageIds.postHarvest => 'Post-cosecha: recuperaci\u00f3n de reservas',
    TreeStageIds.dormancy => 'Reposo: monitoreo pasivo del \u00e1rbol',
    _ =>
      'BIO-G interpreta sensores seg\u00fan el estado visible del \u00e1rbol',
  };
}

String normalizeTreeStateId(String? perennialStateId) {
  final value = perennialStateId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return TreeStateIds.unknown;
  if (treeStateStagePolicies.containsKey(value)) return value;
  return TreeStateIds.unknown;
}

String normalizeTreeStageId(String? phenologyStageId) {
  final value = phenologyStageId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return TreeStageIds.unknown;

  if (isKnownTreeStageId(value)) return value;

  return TreeStageIds.unknown;
}

bool isKnownTreeStageId(String? phenologyStageId) {
  final value = phenologyStageId?.trim().toLowerCase();
  if (value == null || value.isEmpty) return false;

  for (final policy in treeStateStagePolicies.values) {
    if (policy.allowedStages.contains(value) ||
        policy.blockedStages.contains(value)) {
      return true;
    }
  }

  return false;
}

/// Deriva el estado perenne desde la fecha de plantación: dentro de los
/// últimos 12 meses se considera recién plantado; a partir de 1 año cumplido,
/// juvenil que todavía no produce. Es dominio puro (sin UI) para que la rama
/// "solo está creciendo" del wizard quede congelada por tests.
String treeStateFromPlantingDate(DateTime plantingDate, DateTime now) {
  final days = now.difference(plantingDate).inDays;
  return days < 365
      ? TreeStateIds.newlyPlanted
      : TreeStateIds.juvenileNonProductive;
}

/// Resuelve la rama "solo creciendo" desde la fecha de plantacion.
///
/// Si no hay fecha, se guarda como juvenil vegetativo: el agricultor si dio la
/// senal de que aun no produce y solo crece, pero no conviene inventar que fue
/// recien plantado.
TreeVisibleStageSelection resolveTreePlantingAnchorSelection({
  required DateTime? plantingDate,
  required DateTime now,
}) {
  if (plantingDate == null) {
    return const TreeVisibleStageSelection(
      perennialStateId: TreeStateIds.juvenileNonProductive,
      phenologyStageId: TreeStageIds.juvenileVegetative,
      perennialAnchorTypeId: TreeAnchorTypeIds.planting,
    );
  }

  final days = now.difference(plantingDate).inDays;
  if (days < 14) {
    return const TreeVisibleStageSelection(
      perennialStateId: TreeStateIds.newlyPlanted,
      phenologyStageId: TreeStageIds.plantingTransplant,
      perennialAnchorTypeId: TreeAnchorTypeIds.planting,
    );
  }

  if (days < 365) {
    return const TreeVisibleStageSelection(
      perennialStateId: TreeStateIds.newlyPlanted,
      phenologyStageId: TreeStageIds.rootEstablishment,
      perennialAnchorTypeId: TreeAnchorTypeIds.planting,
    );
  }

  return const TreeVisibleStageSelection(
    perennialStateId: TreeStateIds.juvenileNonProductive,
    phenologyStageId: TreeStageIds.juvenileVegetative,
    perennialAnchorTypeId: TreeAnchorTypeIds.planting,
  );
}

/// True cuando el onboarding debe pedir la FECHA DE PLANTACIÓN (rama 3A): el
/// árbol todavía no produce y "solo está creciendo" (sin señal reproductiva ni
/// perfil general). En ese caso el estado perenne se deriva de la edad, no de
/// una etapa visible. Las señales reproductivas (primera floración) y el perfil
/// general usan su propia resolución.
bool isOnboardingTreePlantingBranch({
  String? productionStatusId,
  String? phenologyStageId,
}) {
  if (normalizeTreeProductionStatusId(productionStatusId) !=
      TreeProductionStatusIds.nonProductive) {
    return false;
  }
  final stage = normalizeTreeStageId(phenologyStageId);
  if (stage == TreeStageIds.unknown) return false;
  if (stage == TreeStageIds.flowering ||
      stage == TreeStageIds.fruitSet ||
      stage == TreeStageIds.fruitFill) {
    return false;
  }
  return true;
}

/// Resuelve el contexto perenne final (estado + etapa + tipo de anclaje) desde
/// las selecciones diferidas del onboarding de árbol, usando EXACTAMENTE el
/// mismo modelo canónico que account/configure. Es pura y testeable.
///
/// - status `unknown` o etapa `unknown` → perfil general (`unknown` x3).
/// - rama de plantación ("solo creciendo"): el estado se deriva de la edad y el
///   anclaje es de plantación.
/// - resto (etapa productiva visible o primera floración no productiva): se
///   delega en [resolveTreeVisibleStageSelection], que ya rutea la primera
///   floración a `productive_season`.
TreeVisibleStageSelection resolveOnboardingTreeSelection({
  required String? productionStatusId,
  required String? phenologyStageId,
  required DateTime? plantingDate,
  required DateTime now,
}) {
  final status = normalizeTreeProductionStatusId(productionStatusId);

  const TreeVisibleStageSelection unknownSelection = TreeVisibleStageSelection(
    perennialStateId: TreeStateIds.unknown,
    phenologyStageId: TreeStageIds.unknown,
    perennialAnchorTypeId: TreeAnchorTypeIds.unknown,
  );

  if (status == TreeProductionStatusIds.unknown) {
    return unknownSelection;
  }

  if (isOnboardingTreePlantingBranch(
    productionStatusId: status,
    phenologyStageId: phenologyStageId,
  )) {
    return resolveTreePlantingAnchorSelection(
      plantingDate: plantingDate,
      now: now,
    );
  }

  if (normalizeTreeStageId(phenologyStageId) == TreeStageIds.unknown) {
    return unknownSelection;
  }

  return resolveTreeVisibleStageSelection(
    productionStatusId: status,
    visibleStageId: phenologyStageId,
  );
}

String inferredTreeStageForState(String? perennialStateId) {
  final stateId = normalizeTreeStateId(perennialStateId);
  return switch (stateId) {
    TreeStateIds.newlyPlanted => TreeStageIds.rootEstablishment,
    TreeStateIds.juvenileNonProductive => TreeStageIds.juvenileVegetative,
    TreeStateIds.established => TreeStageIds.unknown,
    TreeStateIds.productiveSeason => TreeStageIds.unknown,
    _ => TreeStageIds.unknown,
  };
}

String safeTreeStageForState({
  required String? perennialStateId,
  required String? phenologyStageId,
}) {
  final stateId = normalizeTreeStateId(perennialStateId);
  final rawStage = phenologyStageId?.trim().toLowerCase();
  final stageId = normalizeTreeStageId(phenologyStageId);

  if (phenologyStageId == null || phenologyStageId.trim().isEmpty) {
    return inferredTreeStageForState(stateId);
  }

  if (rawStage != null &&
      isKnownTreeStageId(rawStage) &&
      isTreeStageAllowed(stateId, stageId)) {
    return stageId;
  }

  return switch (stateId) {
    TreeStateIds.newlyPlanted => TreeStageIds.rootEstablishment,
    TreeStateIds.juvenileNonProductive => TreeStageIds.juvenileVegetative,
    TreeStateIds.established => TreeStageIds.unknown,
    TreeStateIds.productiveSeason => TreeStageIds.unknown,
    _ => TreeStageIds.unknown,
  };
}

String treeStageConfidence({
  required String? perennialStateId,
  required String? phenologyStageId,
}) {
  final rawStage = phenologyStageId?.trim();
  if (rawStage == null || rawStage.isEmpty) return 'inferred';

  final stateId = normalizeTreeStateId(perennialStateId);
  if (!isKnownTreeStageId(rawStage)) return 'corrected';

  final stageId = normalizeTreeStageId(phenologyStageId);
  if (isTreeStageAllowed(stateId, stageId)) return 'explicit';
  return 'corrected';
}
