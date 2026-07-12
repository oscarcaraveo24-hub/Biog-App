import 'package:bio_g/core/crops/apple_tree/apple_tree_assets.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_assets.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_assets.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_assets.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_assets.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_assets.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_assets.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_assets.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_assets.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/device_crop_context.dart';

class PerennialStageResolver {
  const PerennialStageResolver._();

  static CropStageResult resolve({
    required DeviceCropContext context,
    DateTime? today,
  }) {
    final DateTime effectiveToday = today ?? DateTime.now();
    final bool missingState = context.perennialStateId == null ||
        context.perennialStateId!.trim().isEmpty;
    final String stateId = normalizeTreeStateId(context.perennialStateId);
    final String stageId = missingState
        ? TreeStageIds.unknown
        : safeTreeStageForState(
            perennialStateId: stateId,
            phenologyStageId: context.phenologyStageId,
          );

    final bool productionEnabled = isTreeProductionEnabled(stateId);
    final bool isCritical = isTreeCriticalStage(stageId);
    final String confidence = missingState
        ? 'inferred'
        : treeStageConfidence(
            perennialStateId: stateId,
            phenologyStageId: context.phenologyStageId,
          );

    return CropStageResult(
      stageKey: stageId,
      stageLabelEs: treeStageDisplayNameForCrop(context.cropId, stageId),
      // Trees do not have a terminal crop-cycle day. Harvest maturity,
      // post-harvest and dormancy remain active biological stages.
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: _heroAssetForStage(context.cropId, stageId),
      helperCaption: _helperCaption(
        context: context,
        today: effectiveToday,
        stageId: stageId,
        productionEnabled: productionEnabled,
        isCritical: isCritical,
        confidence: confidence,
      ),
      // For perennials this is intentionally null: sowingDate is not the
      // logical axis for tree phenology.
      daySinceSowing: null,
      stageProgressPct: null,
      productiveState: stateId,
      productiveStateLabelEs: treeStateDisplayName(stateId),
    );
  }

  /// Imagen hero por etapa. Para manzano usa la imagen fenológica real; si la
  /// etapa es `unknown` (o el cultivo no tiene imágenes de etapa propias) cae a
  /// un ícono neutro — nunca se inventa un `*_stage_unknown.png`.
  static String _heroAssetForStage(String? cropId, String stageId) {
    final canonicalCropId = CropCatalog.canonicalCropKey(cropId);
    if (canonicalCropId == CropCatalog.appleTreeCropId) {
      return appleTreeStageImageOrNeutral(stageId);
    }
    if (canonicalCropId == CropCatalog.pearTreeCropId) {
      return pearTreeStageImageOrNeutral(stageId);
    }
    if (canonicalCropId == CropCatalog.peachTreeCropId) {
      return peachTreeStageImageOrNeutral(stageId);
    }
    if (canonicalCropId == CropCatalog.walnutTreeCropId) {
      return walnutTreeStageImageOrNeutral(stageId);
    }
    if (canonicalCropId == CropCatalog.pistachioTreeCropId) {
      return pistachioTreeStageImageOrNeutral(stageId);
    }
    if (canonicalCropId == CropCatalog.orangeTreeCropId) {
      return orangeTreeStageImageOrNeutral(stageId);
    }
    if (canonicalCropId == CropCatalog.lemonTreeCropId) {
      return lemonTreeStageImageOrNeutral(stageId);
    }
    if (canonicalCropId == CropCatalog.mangoTreeCropId) {
      return mangoTreeStageImageOrNeutral(stageId);
    }
    if (canonicalCropId == CropCatalog.avocadoTreeCropId) {
      return avocadoTreeStageImageOrNeutral(stageId);
    }
    return 'assets/icons/wizard/ic_tree.png';
  }

  static String _helperCaption({
    required DeviceCropContext context,
    required DateTime today,
    required String stageId,
    required bool productionEnabled,
    required bool isCritical,
    required String confidence,
  }) {
    final List<String> parts = <String>[
      'Seguimiento perenne activo',
      productionEnabled ? 'produccion habilitada' : 'produccion no habilitada',
      isCritical ? 'ventana critica' : 'ventana general',
      'confianza: $confidence',
    ];

    final String? anchorText = _anchorText(
      anchorDate: context.perennialAnchorDate,
      anchorTypeId: context.perennialAnchorTypeId,
      today: today,
    );
    if (anchorText != null) parts.add(anchorText);

    if (stageId == TreeStageIds.harvestMaturity) {
      parts.add('la cosecha no cierra el arbol');
    } else if (stageId == TreeStageIds.postHarvest ||
        stageId == TreeStageIds.dormancy) {
      parts.add('etapa activa del ciclo perenne');
    }

    return parts.join(' | ');
  }

  static String? _anchorText({
    required DateTime? anchorDate,
    required String? anchorTypeId,
    required DateTime today,
  }) {
    if (anchorDate == null) return null;

    final int days = today
        .difference(DateTime(anchorDate.year, anchorDate.month, anchorDate.day))
        .inDays;
    final String anchorType = _normalizeAnchorType(anchorTypeId);
    final String dayText = days == 0
        ? 'hoy'
        : days > 0
            ? 'hace $days dias'
            : 'en ${days.abs()} dias';
    return 'anclaje $anchorType $dayText';
  }

  static String _normalizeAnchorType(String? anchorTypeId) {
    final value = anchorTypeId?.trim().toLowerCase();
    if (value == null || value.isEmpty) return TreeAnchorTypeIds.unknown;
    switch (value) {
      case TreeAnchorTypeIds.planting:
      case TreeAnchorTypeIds.stageStart:
      case TreeAnchorTypeIds.budbreak:
      case TreeAnchorTypeIds.flowering:
      case TreeAnchorTypeIds.harvest:
      case TreeAnchorTypeIds.postHarvest:
      case TreeAnchorTypeIds.manualStage:
      case TreeAnchorTypeIds.unknown:
        return value;
    }
    return TreeAnchorTypeIds.unknown;
  }
}

typedef TreeStageResolver = PerennialStageResolver;
