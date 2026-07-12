import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_yield_reference.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_yield_reference.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_yield_reference.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_yield_reference.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_yield_reference.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_yield_reference.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_yield_reference.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_yield_reference.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/yield_projection_config.dart';
import 'package:bio_g/core/yield/yield_projection_engine_proposed.dart';
import 'package:bio_g/core/yield/yield_reference_catalog.dart';
import 'package:bio_g/core/yield/tree_yield_reference_catalog.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/theme/bio_g_theme.dart';
import 'package:bio_g/widgets/onboarding/onboarding_asset_badge.dart';
import 'package:bio_g/widgets/shared/bio_g_button.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

// --- UTILIDAD GLOBAL ---
String formatNumber(double value, {int maxDecimals = 1}) {
  final fixed = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(maxDecimals);
  final parts = fixed.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final reverseIndex = whole.length - i;
    buffer.write(whole[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write(',');
  }
  return parts.length == 1
      ? buffer.toString()
      : '${buffer.toString()}.${parts[1].replaceFirst(RegExp(r'0+$'), '')}';
}

class YieldProjectionSetupScreen extends StatefulWidget {
  const YieldProjectionSetupScreen({super.key});

  static const String routeName = '/yield/setup';

  @override
  State<YieldProjectionSetupScreen> createState() =>
      _YieldProjectionSetupScreenState();
}

class _YieldProjectionSetupScreenState
    extends State<YieldProjectionSetupScreen> {
  static const String _surfaceIconAsset = 'assets/icons/metrics/ic_surface.png';
  static const String _seedsIconAsset =
      'assets/icons/wizard/ic_planta_generica.png';

  static const double _surfaceIconScale = 3.0;
  static const double _seedsIconScale = 3.0;
  static const double _cropIconScale = 3.0;

  late final TextEditingController _areaController;
  late final TextEditingController _populationController;

  YieldAreaUnit _areaUnit = YieldAreaUnit.hectare;
  YieldOutputMode _outputMode = YieldOutputMode.grain;

  bool _saving = false;
  bool _didLoadInitialValues = false;

  bool _isCalculated = false;
  int _calculationTrigger = 0;

  double _projectedYieldPerUnit = 0.0;
  double _projectedTotalYield = 0.0;
  double _projectedIncome = 0.0;

  String _yieldUnitLabel = 't/ha';
  String _totalUnitLabel = 't';

  @override
  void initState() {
    super.initState();
    _areaController = TextEditingController();
    _populationController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadInitialValues) return;

    final store = BioGScope.of(context);
    final existing = store.activeYieldProjectionConfig;
    final cropContext = store.activeCropContext;

    _areaUnit = existing?.areaUnit ?? _defaultAreaUnitForScale(cropContext);
    _outputMode = _defaultOutputModeForContext(cropContext);
    _areaController.text = _formatNullable(existing?.areaValue);
    _populationController.text = _formatNullable(
      _initialPopulationInputForConfig(existing, _areaUnit),
    );

    final areaVal = _parsePositive(_areaController.text);
    final populationInput = _parsePositive(_populationController.text);

    if (areaVal != null &&
        populationInput != null &&
        _areaUnit != YieldAreaUnit.pot) {
      final actualHealthScore = _getActualHealthScore(store);
      _calculateProjections(
        areaVal,
        populationInput,
        cropContext,
        actualHealthScore,
      );
      _isCalculated = true;
      _calculationTrigger++;
    }

    _didLoadInitialValues = true;
  }

  @override
  void dispose() {
    _areaController.dispose();
    _populationController.dispose();
    super.dispose();
  }

  BioGStore _readStore() => BioGScope.of(context);

  bool get _populationInputMeansEstablishedPlants {
    final cropId = CropCatalog.canonicalCropKey(
      _readStore().activeCropContext?.cropId,
    );
    return cropId == CropCatalog.squashCropId;
  }

  /// Para árboles/perennes (manzano) la "población" no es semilla sembrada
  /// sino árboles plantados. Solo cambia el copy visible; el cálculo de
  /// densidad por hectárea es el mismo.
  bool get _isTreeCrop => isTreeContext(_readStore().activeCropContext);

  double _getActualHealthScore(BioGStore store) {
    const double fallbackScore = 0.68;
    try {
      final double? average = (store as dynamic).cropCareAverage;
      return average ?? store.lastAgroEval?.soilControlScore01 ?? fallbackScore;
    } catch (_) {
      return store.lastAgroEval?.soilControlScore01 ?? fallbackScore;
    }
  }

  void _calculateProjections(
    double area,
    double populationInput,
    DeviceCropContext? ctx,
    double healthScore,
  ) {
    if (ctx == null) {
      _projectedTotalYield = 0.0;
      _projectedYieldPerUnit = 0.0;
      _projectedIncome = 0.0;
      _yieldUnitLabel = 't/ha';
      _totalUnitLabel = 't';
      return;
    }

    if (_areaUnit == YieldAreaUnit.pot) {
      _projectedTotalYield = 0.0;
      _projectedYieldPerUnit = 0.0;
      _projectedIncome = 0.0;
      _yieldUnitLabel = 'kg/maceta';
      _totalUnitLabel = 'kg';
      return;
    }

    if (isTreeContext(ctx)) {
      _calculateTreeProjections(area, populationInput, ctx);
      return;
    }

    final reference = _resolveYieldReference(ctx);
    if (reference == null) {
      _projectedTotalYield = 0.0;
      _projectedYieldPerUnit = 0.0;
      _projectedIncome = 0.0;
      _yieldUnitLabel = 't/ha';
      _totalUnitLabel = 't';
      return;
    }

    final now = DateTime.now();
    final tempConfig = _buildProjectionConfigForInput(
      deviceId: ctx.deviceId,
      cropId: ctx.cropId,
      cultivationScaleId: ctx.cultivationScaleId,
      areaValue: area,
      populationInput: populationInput,
      now: now,
    );

    final estimate = YieldProjectionEngine.estimate(
      reference: reference,
      config: tempConfig,
      historicalCareScore01: _readStore().cropCareAverage,
      currentCareScore01: healthScore,
    );

    if (estimate == null) {
      _projectedTotalYield = 0.0;
      _projectedYieldPerUnit = 0.0;
      _projectedIncome = 0.0;
      _yieldUnitLabel = 't/ha';
      _totalUnitLabel = 't';
      return;
    }

    if (_areaUnit == YieldAreaUnit.hectare) {
      _projectedYieldPerUnit = estimate.projectedMidTonPerHa;
      _projectedTotalYield = estimate.projectedMidTotalTon;
      _yieldUnitLabel = estimate.perHaUnitLabel;
      _totalUnitLabel = estimate.totalUnitLabel;
    } else if (_areaUnit == YieldAreaUnit.squareMeter) {
      _projectedYieldPerUnit = estimate.projectedMidTonPerHa * 0.1;
      _projectedTotalYield = estimate.projectedMidTotalTon * 1000.0;
      _yieldUnitLabel = estimate.isFreshMatter ? 'kg MV/m²' : 'kg/m²';
      _totalUnitLabel = estimate.isFreshMatter ? 'kg MV' : 'kg';
    }

    _projectedIncome = 0.0;
  }

  void _calculateTreeProjections(
    double area,
    double populationInput,
    DeviceCropContext ctx,
  ) {
    final cropId = CropCatalog.canonicalCropKey(ctx.cropId);
    final hectares = _treeAreaInHectares(area);
    final treesPerHa = _treeDensityPerHa(area, populationInput);
    final treeCount = _treeCountFromInput(area, populationInput);

    if (treeCount <= 0) {
      _setZeroTreeProjection();
      return;
    }

    if (cropId == CropCatalog.pearTreeCropId) {
      final projection = resolvePearTreeYield(
        profileId: ctx.profileId,
        perennialStateId: ctx.perennialStateId,
        phenologyStageId: ctx.phenologyStageId,
        treesPerHa: treesPerHa,
        hectares: hectares,
        treeCount: treeCount,
        fruitVisible:
            normalizeTreeStageId(ctx.phenologyStageId) ==
                TreeStageIds.fruitFill ||
            normalizeTreeStageId(ctx.phenologyStageId) ==
                TreeStageIds.harvestMaturity,
      );
      _setPearTreeProjection(projection, area);
      return;
    }

    if (cropId == CropCatalog.peachTreeCropId) {
      final projection = resolvePeachTreeYield(
        profileId: ctx.profileId,
        perennialStateId: ctx.perennialStateId,
        phenologyStageId: ctx.phenologyStageId,
        treesPerHa: treesPerHa,
        hectares: hectares,
        treeCount: treeCount,
        fruitVisible:
            normalizeTreeStageId(ctx.phenologyStageId) ==
                TreeStageIds.fruitFill ||
            normalizeTreeStageId(ctx.phenologyStageId) ==
                TreeStageIds.harvestMaturity,
      );
      _setPeachTreeProjection(projection, area);
      return;
    }

    if (cropId == CropCatalog.walnutTreeCropId) {
      final projection = resolveWalnutTreeYield(
        profileId: ctx.profileId,
        perennialStateId: ctx.perennialStateId,
        phenologyStageId: ctx.phenologyStageId,
        treesPerHa: treesPerHa,
        hectares: hectares,
        treeCount: treeCount,
      );
      _setWalnutTreeProjection(projection, area);
      return;
    }

    if (cropId == CropCatalog.pistachioTreeCropId) {
      final projection = resolvePistachioTreeYield(
        profileId: ctx.profileId,
        perennialStateId: ctx.perennialStateId,
        phenologyStageId: ctx.phenologyStageId,
        treesPerHa: treesPerHa,
        hectares: hectares,
        treeCount: treeCount,
      );
      _setPistachioTreeProjection(projection, area);
      return;
    }

    if (cropId == CropCatalog.orangeTreeCropId) {
      final projection = resolveOrangeTreeYield(
        profileId: ctx.profileId,
        perennialStateId: ctx.perennialStateId,
        phenologyStageId: ctx.phenologyStageId,
        treesPerHa: treesPerHa,
        hectares: hectares,
        treeCount: treeCount,
      );
      _setOrangeTreeProjection(projection, area);
      return;
    }

    if (cropId == CropCatalog.lemonTreeCropId) {
      final projection = resolveLemonTreeYield(
        profileId: ctx.profileId,
        perennialStateId: ctx.perennialStateId,
        phenologyStageId: ctx.phenologyStageId,
        treesPerHa: treesPerHa,
        hectares: hectares,
        treeCount: treeCount,
      );
      _setLemonTreeProjection(projection, area);
      return;
    }

    if (cropId == CropCatalog.mangoTreeCropId) {
      final projection = resolveMangoTreeYield(
        profileId: ctx.profileId,
        perennialStateId: ctx.perennialStateId,
        phenologyStageId: ctx.phenologyStageId,
        treesPerHa: treesPerHa,
        hectares: hectares,
        treeCount: treeCount,
      );
      _setMangoTreeProjection(projection, area);
      return;
    }

    if (cropId == CropCatalog.avocadoTreeCropId) {
      final projection = resolveAvocadoTreeYield(
        profileId: ctx.profileId,
        perennialStateId: ctx.perennialStateId,
        phenologyStageId: ctx.phenologyStageId,
        treesPerHa: treesPerHa,
        hectares: hectares,
        treeCount: treeCount,
      );
      _setAvocadoTreeProjection(projection, area);
      return;
    }

    final tier = TreeYieldReferenceCatalog.tierForPerennialState(
      ctx.perennialStateId,
    );
    if (tier == null) {
      _setZeroTreeProjection();
      return;
    }

    final estimate = TreeYieldReferenceCatalog.estimateTotalKg(
      cropId: cropId,
      profileId: ctx.profileId,
      tier: tier,
      treeCount: treeCount,
    );
    if (estimate == null) {
      _setZeroTreeProjection();
      return;
    }

    final expectedTotalKg = (estimate.kgLow + estimate.kgHigh) / 2.0;
    _projectedTotalYield = expectedTotalKg;
    _totalUnitLabel = 'kg';
    if (_areaUnit == YieldAreaUnit.hectare) {
      final perHaTon = hectares <= 0 ? 0.0 : expectedTotalKg / hectares / 1000.0;
      _projectedYieldPerUnit = perHaTon;
      _yieldUnitLabel = 't/ha';
    } else {
      _projectedYieldPerUnit = area <= 0 ? 0.0 : expectedTotalKg / area;
      _yieldUnitLabel = 'kg/m2';
    }
    _projectedIncome = 0.0;
  }

  double _treeAreaInHectares(double area) {
    return switch (_areaUnit) {
      YieldAreaUnit.hectare => area,
      YieldAreaUnit.squareMeter => area / 10000.0,
      YieldAreaUnit.pot => 0.0,
    };
  }

  double _treeDensityPerHa(double area, double populationInput) {
    return switch (_areaUnit) {
      YieldAreaUnit.hectare => populationInput,
      YieldAreaUnit.squareMeter => populationInput * 10000.0,
      YieldAreaUnit.pot => 0.0,
    };
  }

  int _treeCountFromInput(double area, double populationInput) {
    final total = switch (_areaUnit) {
      YieldAreaUnit.hectare => area * populationInput,
      YieldAreaUnit.squareMeter => area * populationInput,
      YieldAreaUnit.pot => populationInput,
    };
    return total.isFinite ? total.round() : 0;
  }

  void _setPearTreeProjection(PearTreeYieldProjection projection, double area) {
    final expectedTotalKg = projection.totalKg?.expected ?? 0.0;
    _projectedTotalYield = expectedTotalKg;
    _totalUnitLabel = 'kg';

    if (_areaUnit == YieldAreaUnit.hectare) {
      _projectedYieldPerUnit = projection.tonPerHa?.expected ?? 0.0;
      _yieldUnitLabel = 't/ha';
    } else {
      _projectedYieldPerUnit = area <= 0 ? 0.0 : expectedTotalKg / area;
      _yieldUnitLabel = 'kg/m2';
    }
    _projectedIncome = 0.0;
  }

  void _setPeachTreeProjection(PeachTreeYieldProjection projection, double area) {
    final expectedTotalKg = projection.totalKg?.expected ?? 0.0;
    _projectedTotalYield = expectedTotalKg;
    _totalUnitLabel = 'kg';

    if (_areaUnit == YieldAreaUnit.hectare) {
      _projectedYieldPerUnit = projection.tonPerHa?.expected ?? 0.0;
      _yieldUnitLabel = 't/ha';
    } else {
      _projectedYieldPerUnit = area <= 0 ? 0.0 : expectedTotalKg / area;
      _yieldUnitLabel = 'kg/m2';
    }
    _projectedIncome = 0.0;
  }

  void _setWalnutTreeProjection(
    WalnutTreeYieldProjection projection,
    double area,
  ) {
    final expectedTotalKg = projection.totalKg?.expected ?? 0.0;
    _projectedTotalYield = expectedTotalKg;
    _totalUnitLabel = 'kg';

    if (_areaUnit == YieldAreaUnit.hectare) {
      _projectedYieldPerUnit = projection.tonPerHa?.expected ?? 0.0;
      _yieldUnitLabel = 't/ha';
    } else {
      _projectedYieldPerUnit = area <= 0 ? 0.0 : expectedTotalKg / area;
      _yieldUnitLabel = 'kg/m2';
    }
    _projectedIncome = 0.0;
  }

  void _setPistachioTreeProjection(
    PistachioTreeYieldProjection projection,
    double area,
  ) {
    final expectedTotalKg = projection.totalKg?.expected ?? 0.0;
    _projectedTotalYield = expectedTotalKg;
    _totalUnitLabel = 'kg';

    if (_areaUnit == YieldAreaUnit.hectare) {
      _projectedYieldPerUnit = projection.tonPerHa?.expected ?? 0.0;
      _yieldUnitLabel = 't/ha';
    } else {
      _projectedYieldPerUnit = area <= 0 ? 0.0 : expectedTotalKg / area;
      _yieldUnitLabel = 'kg/m2';
    }
    _projectedIncome = 0.0;
  }

  void _setOrangeTreeProjection(
    OrangeTreeYieldProjection projection,
    double area,
  ) {
    final expectedTotalKg = projection.totalKg?.expected ?? 0.0;
    _projectedTotalYield = expectedTotalKg;
    _totalUnitLabel = 'kg';

    if (_areaUnit == YieldAreaUnit.hectare) {
      _projectedYieldPerUnit = projection.tonPerHa?.expected ?? 0.0;
      _yieldUnitLabel = 't/ha';
    } else {
      _projectedYieldPerUnit = area <= 0 ? 0.0 : expectedTotalKg / area;
      _yieldUnitLabel = 'kg/m2';
    }
    _projectedIncome = 0.0;
  }

  void _setLemonTreeProjection(
    LemonTreeYieldProjection projection,
    double area,
  ) {
    final expectedTotalKg = projection.totalKg?.expected ?? 0.0;
    _projectedTotalYield = expectedTotalKg;
    _totalUnitLabel = 'kg';

    if (_areaUnit == YieldAreaUnit.hectare) {
      _projectedYieldPerUnit = projection.tonPerHa?.expected ?? 0.0;
      _yieldUnitLabel = 't/ha';
    } else {
      _projectedYieldPerUnit = area <= 0 ? 0.0 : expectedTotalKg / area;
      _yieldUnitLabel = 'kg/m2';
    }
    _projectedIncome = 0.0;
  }

  void _setMangoTreeProjection(
    MangoTreeYieldProjection projection,
    double area,
  ) {
    final expectedTotalKg = projection.totalKg?.expected ?? 0.0;
    _projectedTotalYield = expectedTotalKg;
    _totalUnitLabel = 'kg';

    if (_areaUnit == YieldAreaUnit.hectare) {
      _projectedYieldPerUnit = projection.tonPerHa?.expected ?? 0.0;
      _yieldUnitLabel = 't/ha';
    } else {
      _projectedYieldPerUnit = area <= 0 ? 0.0 : expectedTotalKg / area;
      _yieldUnitLabel = 'kg/m2';
    }
    _projectedIncome = 0.0;
  }

  void _setAvocadoTreeProjection(
    AvocadoTreeYieldProjection projection,
    double area,
  ) {
    final expectedTotalKg = projection.totalKg?.expected ?? 0.0;
    _projectedTotalYield = expectedTotalKg;
    _totalUnitLabel = 'kg';

    if (_areaUnit == YieldAreaUnit.hectare) {
      _projectedYieldPerUnit = projection.tonPerHa?.expected ?? 0.0;
      _yieldUnitLabel = 't/ha';
    } else {
      _projectedYieldPerUnit = area <= 0 ? 0.0 : expectedTotalKg / area;
      _yieldUnitLabel = 'kg/m2';
    }
    _projectedIncome = 0.0;
  }

  void _setZeroTreeProjection() {
    _projectedTotalYield = 0.0;
    _projectedYieldPerUnit = 0.0;
    _projectedIncome = 0.0;
    _yieldUnitLabel = _areaUnit == YieldAreaUnit.hectare ? 't/ha' : 'kg/m2';
    _totalUnitLabel = 'kg';
  }

  YieldOutputMode _defaultOutputModeForContext(DeviceCropContext? ctx) {
    if (ctx == null) return YieldOutputMode.grain;
    final alias = (ctx.varietyAlias ?? '').toLowerCase();
    final profile = ctx.profileId.toLowerCase();
    if (alias.contains('forraj') || profile.contains('forage')) {
      return YieldOutputMode.forage;
    }
    return YieldOutputMode.grain;
  }

  YieldReference? _resolveYieldReference(DeviceCropContext? ctx) {
    final cropId = CropCatalog.canonicalCropKey(ctx?.cropId);
    if (cropId == 'chili') {
      final chiliReference = _resolveChiliYieldReference(ctx!);
      if (chiliReference != null) return chiliReference;
    }
    if (cropId == 'eggplant') {
      final eggplantReference = _resolveEggplantYieldReference(ctx!);
      if (eggplantReference != null) return eggplantReference;
    }
    if (cropId == CropCatalog.squashCropId) {
      final squashReference = _resolveSquashYieldReference(ctx!);
      if (squashReference != null) return squashReference;
    }
    if (cropId == CropCatalog.lettuceCropId) {
      final lettuceReference = _resolveLettuceYieldReference(ctx!);
      if (lettuceReference != null) return lettuceReference;
    }
    if (cropId == CropCatalog.spinachCropId) {
      final spinachReference = _resolveSpinachYieldReference(ctx!);
      if (spinachReference != null) return spinachReference;
    }
    if (cropId == CropCatalog.onionCropId) {
      final onionReference = _resolveOnionYieldReference(ctx!);
      if (onionReference != null) return onionReference;
    }
    if (cropId == CropCatalog.garlicCropId) {
      final garlicReference = _resolveGarlicYieldReference(ctx!);
      if (garlicReference != null) return garlicReference;
    }

    final varietyId = ctx?.varietyId?.trim();
    if (varietyId != null && varietyId.isNotEmpty) {
      final direct = YieldReferenceCatalog.byId[varietyId];
      if (direct != null) {
        if (_outputMode == YieldOutputMode.forage &&
            direct.useType != 'forage') {
          final forageId = varietyId.replaceAll('_grain', '_forage');
          final alt = YieldReferenceCatalog.byId[forageId];
          if (alt != null) return alt;
          return YieldReferenceCatalog.genericForage(ctx!.cropId) ?? direct;
        }
        if (_outputMode == YieldOutputMode.grain &&
            direct.useType == 'forage') {
          final grainId = varietyId.replaceAll('_forage', '_grain');
          final alt = YieldReferenceCatalog.byId[grainId];
          if (alt != null) return alt;
          return YieldReferenceCatalog.genericGrain(ctx!.cropId) ?? direct;
        }
        return direct;
      }
    }
    return _genericYieldReferenceForContext(ctx);
  }

  YieldReference? _resolveChiliYieldReference(DeviceCropContext ctx) {
    final profile = ctx.profileId.toLowerCase();
    final alias = (ctx.varietyAlias ?? '').toLowerCase();
    final variety = (ctx.varietyId ?? '').toLowerCase();
    final calendar = (ctx.calendarTypeId ?? '').toLowerCase();
    final scale = (ctx.cultivationScaleId ?? '').toLowerCase();
    final joined = '$profile $alias $variety $calendar $scale';

    final isGeneric = _containsAny(joined, const [
      'ch-gen',
      'ch_gen',
      'chgen',
      'chili_generic',
      'generico',
      'otro chile',
      'no se',
    ]);
    if (isGeneric) return YieldReferenceCatalog.byId['chili_generic'];

    final isProtected = _containsAny(joined, const [
      'protegido',
      'invernadero',
      'casa malla',
      'malla',
      'protected',
      'chili_protegido',
    ]);
    final wantsDry = _containsAny(joined, const [
      'seco',
      'dry',
      'deshidrat',
      'ancho seco',
      'mulato seco',
    ]);
    final wantsFresh = _containsAny(joined, const [
      'fresco',
      'fresh',
      'verde',
      'chilaca verde',
    ]);

    if (_containsAny(joined, const ['ch-01', 'ch_01', 'ch01', 'jalapeno'])) {
      return YieldReferenceCatalog.byId['chili_jalapeno'];
    }
    if (_containsAny(joined, const ['ch-02', 'ch_02', 'ch02', 'serrano'])) {
      return YieldReferenceCatalog.byId['chili_serrano'];
    }
    if (_containsAny(joined, const [
      'ch-03',
      'ch_03',
      'ch03',
      'poblano',
      'ancho',
      'mulato',
    ])) {
      final explicitDry =
          variety == 'chili_ancho_dry' ||
          wantsDry ||
          alias.contains('ancho seco') ||
          alias.contains('mulato seco');
      return explicitDry
          ? YieldReferenceCatalog.byId['chili_ancho_dry'] ??
                YieldReferenceCatalog.byId['chili_poblano_ancho']
          : YieldReferenceCatalog.byId['chili_poblano_ancho'];
    }
    if (_containsAny(joined, const [
      'ch-04',
      'ch_04',
      'ch04',
      'chilaca',
      'pasilla',
    ])) {
      final explicitFresh =
          variety == 'chili_chilaca_fresh' ||
          alias.contains('chilaca verde') ||
          (alias.contains('chilaca') &&
              wantsFresh &&
              !alias.contains('pasilla'));
      final explicitDry =
          variety == 'chili_chilaca_pasilla' ||
          alias.contains('pasilla') ||
          wantsDry;
      if (explicitFresh && !explicitDry) {
        return YieldReferenceCatalog.byId['chili_chilaca_fresh'] ??
            YieldReferenceCatalog.byId['chili_chilaca_pasilla'];
      }
      return YieldReferenceCatalog.byId['chili_chilaca_pasilla'];
    }
    if (_containsAny(joined, const [
      'ch-05',
      'ch_05',
      'ch05',
      'guajillo',
      'mirasol',
    ])) {
      return YieldReferenceCatalog.byId['chili_guajillo_mirasol'];
    }
    if (_containsAny(joined, const [
      'ch-06',
      'ch_06',
      'ch06',
      'arbol',
      'puya',
    ])) {
      if (variety == 'chili_arbol_fresh' || (wantsFresh && !wantsDry)) {
        return YieldReferenceCatalog.byId['chili_arbol_fresh'] ??
            YieldReferenceCatalog.byId['chili_arbol_puya_dry'] ??
            YieldReferenceCatalog.byId['chili_arbol_puya'];
      }
      return YieldReferenceCatalog.byId['chili_arbol_puya_dry'] ??
          YieldReferenceCatalog.byId['chili_arbol_puya'];
    }
    if (_containsAny(joined, const ['ch-07', 'ch_07', 'ch07', 'habanero'])) {
      return YieldReferenceCatalog.byId['chili_habanero'];
    }
    if (_containsAny(joined, const [
      'ch-08',
      'ch_08',
      'ch08',
      'morron',
      'pimiento',
      'chile gordo',
      'bell',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['chili_bell_pepper_protected'] ??
                YieldReferenceCatalog.byId['chili_bell_pepper']
          : YieldReferenceCatalog.byId['chili_bell_pepper'];
    }

    final direct = YieldReferenceCatalog.byId[variety];
    if (direct != null) return direct;
    return isProtected
        ? YieldReferenceCatalog.genericFreshProtected(ctx.cropId) ??
              YieldReferenceCatalog.genericFresh(ctx.cropId)
        : YieldReferenceCatalog.genericFresh(ctx.cropId);
  }

  YieldReference? _resolveEggplantYieldReference(DeviceCropContext ctx) {
    final profile = ctx.profileId.toLowerCase();
    final alias = (ctx.varietyAlias ?? '').toLowerCase();
    final variety = (ctx.varietyId ?? '').toLowerCase();
    final calendar = (ctx.calendarTypeId ?? '').toLowerCase();
    final scale = (ctx.cultivationScaleId ?? '').toLowerCase();
    final joined = '$profile $alias $variety $calendar $scale';

    final isGeneric = _containsAny(joined, const [
      'be-gen',
      'be_gen',
      'begen',
      'eggplant_generic',
      'generico',
      'generica',
      'otra berenjena',
      'no se',
      'no sé',
    ]);
    if (isGeneric) return YieldReferenceCatalog.byId['eggplant_generic'];

    final isProtected = _containsAny(joined, const [
      'protegido',
      'invernadero',
      'casa malla',
      'casa sombra',
      'malla',
      'malla sombra',
      'macro tunel',
      'macro túnel',
      'protected',
      'eggplant_protegido',
    ]);

    if (_containsAny(joined, const [
      'be-01',
      'be_01',
      'be01',
      'eggplant_long_purple',
      'larga',
      'semilarga',
      'barcelona',
      'dark night',
      'orestia',
      'napoli',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['eggplant_long_purple_protected'] ??
                YieldReferenceCatalog.byId['eggplant_long_purple_field']
          : YieldReferenceCatalog.byId['eggplant_long_purple_field'];
    }
    if (_containsAny(joined, const [
      'be-02',
      'be_02',
      'be02',
      'eggplant_oval_round',
      'eggplant_italian_purple',
      'eggplant_italian_black',
      'oval',
      'bola',
      'italiana',
      'italian',
      'clasica',
      'clásica',
      'morada clasica',
      'morada clásica',
      'black beauty',
      'night shadow',
      'emma',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['eggplant_oval_round_protected'] ??
                YieldReferenceCatalog.byId['eggplant_oval_round_field']
          : YieldReferenceCatalog.byId['eggplant_oval_round_field'];
    }
    if (_containsAny(joined, const [
      'be-03',
      'be_03',
      'be03',
      'eggplant_striped',
      'rayada',
      'listada',
      'graffiti',
      'grafiti',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['eggplant_striped_protected'] ??
                YieldReferenceCatalog.byId['eggplant_striped_field']
          : YieldReferenceCatalog.byId['eggplant_striped_field'];
    }
    if (_containsAny(joined, const [
      'be-04',
      'be_04',
      'be04',
      'eggplant_white',
      'blanca',
      'white egg',
      'white',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['eggplant_white_protected'] ??
                YieldReferenceCatalog.byId['eggplant_white_field']
          : YieldReferenceCatalog.byId['eggplant_white_field'];
    }

    final direct = YieldReferenceCatalog.byId[variety];
    if (direct != null) return direct;
    return isProtected
        ? YieldReferenceCatalog.genericFreshProtected(ctx.cropId) ??
              YieldReferenceCatalog.genericFresh(ctx.cropId)
        : YieldReferenceCatalog.genericFresh(ctx.cropId);
  }

  YieldReference? _resolveSquashYieldReference(DeviceCropContext ctx) {
    final profile = ctx.profileId.toLowerCase();
    final alias = (ctx.varietyAlias ?? '').toLowerCase();
    final variety = (ctx.varietyId ?? '').toLowerCase();
    final calendar = (ctx.calendarTypeId ?? '').toLowerCase();
    final scale = (ctx.cultivationScaleId ?? '').toLowerCase();
    final joined = '$profile $alias $variety $calendar $scale';

    final isProtected = _containsAny(joined, const [
      'protegido',
      'invernadero',
      'casa malla',
      'casa sombra',
      'malla',
      'malla sombra',
      'macro tunel',
      'protected',
      'squash_protegido',
    ]);

    final wantsFruit = _containsAny(joined, const [
      'fruto',
      'fruta',
      'verdura',
      'fresco',
      'fresh',
      'cosecha fruto',
    ]);
    final wantsSeed = _containsAny(joined, const [
      'semilla',
      'pepita',
      'seed',
      'seco',
      'dry',
      'pipian',
      'pipiana',
      'chihua',
    ]);

    final isGeneric = _containsAny(joined, const [
      'ca-gen',
      'ca_gen',
      'cagen',
      'squash_generic',
      'generico',
      'generica',
      'otra calabaza',
      'no se',
    ]);
    if (isGeneric) {
      return isProtected
          ? YieldReferenceCatalog.byId['squash_protected_soil_generic'] ??
                YieldReferenceCatalog.byId['squash_generic']
          : YieldReferenceCatalog.byId['squash_generic'];
    }

    if (_containsAny(joined, const [
      'ca-01',
      'ca_01',
      'ca01',
      'squash_zucchini',
      'zucchini',
      'calabacita italiana',
      'italiana',
      'calabacin',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['squash_zucchini_protected'] ??
                YieldReferenceCatalog.byId['squash_zucchini_field']
          : YieldReferenceCatalog.byId['squash_zucchini_field'];
    }

    if (_containsAny(joined, const [
      'ca-02',
      'ca_02',
      'ca02',
      'squash_criolla',
      'criolla',
      'huicha',
      'milpa',
      'temporal',
    ])) {
      return YieldReferenceCatalog.byId['squash_criolla_field'];
    }

    if (_containsAny(joined, const [
      'ca-03',
      'ca_03',
      'ca03',
      'squash_round',
      'bola',
      'redonda',
      'round zucchini',
    ])) {
      return YieldReferenceCatalog.byId['squash_round_field'];
    }

    if (_containsAny(joined, const [
      'ca-04',
      'ca_04',
      'ca04',
      'squash_castilla',
      'castilla',
      'pumpkin',
      'dulce',
      'altar',
    ])) {
      return YieldReferenceCatalog.byId['squash_castilla_mature'];
    }

    if (_containsAny(joined, const [
      'ca-05',
      'ca_05',
      'ca05',
      'squash_butternut',
      'butternut',
      'buchona',
      'mantequilla',
      'cacahuate',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['squash_butternut_intensive'] ??
                YieldReferenceCatalog.byId['squash_butternut_field']
          : YieldReferenceCatalog.byId['squash_butternut_field'];
    }

    if (_containsAny(joined, const [
      'ca-06',
      'ca_06',
      'ca06',
      'squash_chilacayote',
      'chilacayote',
      'chilacayota',
      'alcayota',
    ])) {
      return YieldReferenceCatalog.byId['squash_chilacayote_mature'];
    }

    if (_containsAny(joined, const [
      'ca-07',
      'ca_07',
      'ca07',
      'squash_pipian',
      'pipian',
      'pipiana',
      'pepita',
      'chihua',
    ])) {
      if (wantsFruit && !wantsSeed) {
        return YieldReferenceCatalog.byId['squash_pipian_fruit_mature'] ??
            YieldReferenceCatalog.byId['squash_pipian_seed_dry'];
      }
      return YieldReferenceCatalog.byId['squash_pipian_seed_dry'];
    }

    final direct = YieldReferenceCatalog.byId[variety];
    if (direct != null) return direct;
    return isProtected
        ? YieldReferenceCatalog.genericFreshProtected(ctx.cropId) ??
              YieldReferenceCatalog.genericFresh(ctx.cropId)
        : YieldReferenceCatalog.genericFresh(ctx.cropId);
  }

  YieldReference? _resolveLettuceYieldReference(DeviceCropContext ctx) {
    final profile = ctx.profileId.toLowerCase();
    final alias = (ctx.varietyAlias ?? '').toLowerCase();
    final variety = (ctx.varietyId ?? '').toLowerCase();
    final calendar = (ctx.calendarTypeId ?? '').toLowerCase();
    final scale = (ctx.cultivationScaleId ?? '').toLowerCase();
    final joined = '$profile $alias $variety $calendar $scale';

    final isProtected = _containsAny(joined, const [
      'protegido',
      'invernadero',
      'casa malla',
      'casa sombra',
      'malla',
      'malla sombra',
      'macro tunel',
      'protected',
      'lettuce_protegido',
    ]);

    final isGeneric = _containsAny(joined, const [
      'le-gen',
      'le_gen',
      'legen',
      'lettuce_generic',
      'generico',
      'generica',
      'otra lechuga',
      'no se',
      'no sé',
    ]);
    if (isGeneric) {
      return isProtected
          ? YieldReferenceCatalog.byId['lettuce_protected_soil_generic'] ??
                YieldReferenceCatalog.byId['lettuce_generic']
          : YieldReferenceCatalog.byId['lettuce_generic'];
    }

    if (_containsAny(joined, const [
      'le-01',
      'le_01',
      'le01',
      'lettuce_romaine',
      'romana',
      'romaine',
      'cos',
    ])) {
      return YieldReferenceCatalog.byId['lettuce_romaine_field'];
    }
    if (_containsAny(joined, const [
      'le-02',
      'le_02',
      'le02',
      'lettuce_mini_romaine',
      'mini romana',
      'corazon',
      'little gem',
      'gem',
    ])) {
      return YieldReferenceCatalog.byId['lettuce_mini_romaine_field'];
    }
    if (_containsAny(joined, const [
      'le-03',
      'le_03',
      'le03',
      'lettuce_iceberg',
      'iceberg',
      'bola',
      'crisphead',
    ])) {
      return YieldReferenceCatalog.byId['lettuce_iceberg_field'];
    }
    if (_containsAny(joined, const [
      'le-04',
      'le_04',
      'le04',
      'lettuce_butterhead',
      'butterhead',
      'mantequilla',
      'bibb',
      'boston',
    ])) {
      return YieldReferenceCatalog.byId['lettuce_butterhead_field'];
    }
    if (_containsAny(joined, const [
      'le-05',
      'le_05',
      'le05',
      'lettuce_looseleaf',
      'hoja suelta',
      'orejona',
      'looseleaf',
      'baby leaf',
      'green leaf',
      'red leaf',
    ])) {
      return YieldReferenceCatalog.byId['lettuce_looseleaf_field'];
    }

    final direct = YieldReferenceCatalog.byId[variety];
    if (direct != null) return direct;
    return isProtected
        ? YieldReferenceCatalog.genericFreshProtected(ctx.cropId) ??
              YieldReferenceCatalog.genericFresh(ctx.cropId)
        : YieldReferenceCatalog.genericFresh(ctx.cropId);
  }

  YieldReference? _resolveSpinachYieldReference(DeviceCropContext ctx) {
    final profile = ctx.profileId.toLowerCase();
    final alias = (ctx.varietyAlias ?? '').toLowerCase();
    final variety = (ctx.varietyId ?? '').toLowerCase();
    final calendar = (ctx.calendarTypeId ?? '').toLowerCase();
    final scale = (ctx.cultivationScaleId ?? '').toLowerCase();
    final joined = '$profile $alias $variety $calendar $scale';

    final isProtected = _containsAny(joined, const [
      'protegido',
      'invernadero',
      'casa malla',
      'casa sombra',
      'malla',
      'malla sombra',
      'macro tunel',
      'protected',
      'spinach_protegido',
      'suelo protegido',
    ]);

    final isMultiCut = _containsAny(joined, const [
      'multicorte',
      'multi corte',
      'recorte',
      'cortes',
      'cut and come again',
      'multiple cut',
    ]);

    final isGeneric = _containsAny(joined, const [
      'sp-gen',
      'sp_gen',
      'spgen',
      'spinach_generic',
      'generico',
      'generica',
      'otra espinaca',
      'no se',
    ]);
    if (isGeneric) {
      return isProtected
          ? YieldReferenceCatalog.byId['spinach_protected_soil'] ??
                YieldReferenceCatalog.byId['spinach_generic']
          : YieldReferenceCatalog.byId['spinach_generic'];
    }

    if (_containsAny(joined, const [
      'sp-01',
      'sp_01',
      'sp01',
      'spinach_savoy_summer',
      'saboya verano',
      'semi-saboya verano',
      'semi saboya verano',
      'calor',
      'summer',
      'heat',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['spinach_protected_soil'] ??
                YieldReferenceCatalog.byId['spinach_savoy_summer']
          : YieldReferenceCatalog.byId['spinach_savoy_summer'];
    }

    if (_containsAny(joined, const [
      'sp-02',
      'sp_02',
      'sp02',
      'spinach_savoy_winter',
      'saboya invierno',
      'semi-saboya invierno',
      'semi saboya invierno',
      'dias cortos',
      'winter',
      'short day',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['spinach_protected_soil'] ??
                YieldReferenceCatalog.byId['spinach_winter_field']
          : YieldReferenceCatalog.byId['spinach_winter_field'];
    }

    if (_containsAny(joined, const [
      'sp-03',
      'sp_03',
      'sp03',
      'spinach_smooth_baby',
      'lisa',
      'smooth',
      'baby',
      'baby leaf',
      'premium',
    ])) {
      if (isMultiCut) {
        return YieldReferenceCatalog.byId['spinach_multi_cut_soil'] ??
            YieldReferenceCatalog.byId['spinach_smooth_baby'];
      }
      if (_containsAny(joined, const ['madura', 'maduro', 'adult', 'mature'])) {
        return YieldReferenceCatalog.byId['spinach_smooth_mature'] ??
            YieldReferenceCatalog.byId['spinach_smooth_baby'];
      }
      return YieldReferenceCatalog.byId['spinach_smooth_baby'];
    }

    if (_containsAny(joined, const [
      'sp-04',
      'sp_04',
      'sp04',
      'spinach_oriental_bunching',
      'oriental',
      'manojo',
      'bunch',
      'erecta',
    ])) {
      return YieldReferenceCatalog.byId['spinach_oriental_bunch'];
    }

    if (_containsAny(joined, const [
      'sp-05',
      'sp_05',
      'sp05',
      'spinach_processing',
      'proceso',
      'industria',
      'industrial',
      'processing',
    ])) {
      return YieldReferenceCatalog.byId['spinach_process_field'];
    }

    final direct = YieldReferenceCatalog.byId[variety];
    if (direct != null) return direct;
    return isProtected
        ? YieldReferenceCatalog.genericFreshProtected(
                CropCatalog.spinachCropId,
              ) ??
              YieldReferenceCatalog.genericFresh(CropCatalog.spinachCropId)
        : YieldReferenceCatalog.genericFresh(CropCatalog.spinachCropId);
  }

  YieldReference? _resolveOnionYieldReference(DeviceCropContext ctx) {
    final profile = ctx.profileId.toLowerCase();
    final alias = (ctx.varietyAlias ?? '').toLowerCase();
    final variety = (ctx.varietyId ?? '').toLowerCase();
    final calendar = (ctx.calendarTypeId ?? '').toLowerCase();
    final scale = (ctx.cultivationScaleId ?? '').toLowerCase();
    final joined = '$profile $alias $variety $calendar $scale';

    // El destino/sistema pesa mas que el color en el rendimiento.
    final isProcessing = _containsAny(joined, const [
      'proceso',
      'industria',
      'deshidrat',
      'processing',
    ]);
    final isStorage = _containsAny(joined, const [
      'almacen',
      'almacenamiento',
      'bodega',
      'storage',
      'bulbo seco',
    ]);
    final isSweet = _containsAny(joined, const [
      'dulce',
      'sweet',
      'vidalia',
      'granex',
    ]);
    final isLowInput = _containsAny(joined, const [
      'bajo insumo',
      'temporal',
      'sin riego',
      'low input',
      'semiarido',
      'secano',
    ]);
    final isProtected = _containsAny(joined, const [
      'protegido',
      'invernadero',
      'malla',
      'casa sombra',
      'macro tunel',
      'protected',
      'onion_protegido',
      'suelo protegido',
    ]);

    // Cambray/rama: cosecha joven, no comparar contra bulbo seco.
    final isCambray = _containsAny(joined, const [
      'on-05',
      'on_05',
      'on05',
      'onion_cambray',
      'cambray',
      'rama',
      'cebollin',
      'manojo',
      'bunch',
      'green onion',
      'scallion',
    ]);
    if (isCambray) {
      return YieldReferenceCatalog.byId['onion_cambray_bunch'];
    }

    if (isProcessing) {
      return YieldReferenceCatalog.byId['onion_processing_field_run'];
    }

    final isGeneric = _containsAny(joined, const [
      'on-gen',
      'on_gen',
      'ongen',
      'onion_generic',
      'generico',
      'generica',
      'otra cebolla',
      'no se',
    ]);
    if (isGeneric) {
      if (isLowInput) {
        return YieldReferenceCatalog.byId['onion_low_input_or_semiarid'];
      }
      return isProtected
          ? YieldReferenceCatalog.byId['onion_protected_soil'] ??
                YieldReferenceCatalog.byId['onion_generic']
          : YieldReferenceCatalog.byId['onion_generic'];
    }

    // ON-01 blanca dia corto grano/bola
    if (_containsAny(joined, const [
      'on-01',
      'on_01',
      'on01',
      'onion_white',
      'blanca',
      'grano',
      'bola',
      'white',
    ])) {
      return YieldReferenceCatalog.byId['onion_white_short_day_grano'];
    }

    // ON-02 amarilla/dorada dia corto
    if (_containsAny(joined, const [
      'on-02',
      'on_02',
      'on02',
      'onion_yellow',
      'amarilla',
      'dorada',
      'yellow',
    ])) {
      if (isSweet) {
        return YieldReferenceCatalog.byId['onion_transplanted_sweet'];
      }
      return YieldReferenceCatalog.byId['onion_yellow_short_day_fresh'];
    }

    // ON-03 morada dia corto
    if (_containsAny(joined, const [
      'on-03',
      'on_03',
      'on03',
      'onion_purple',
      'onion_red',
      'morada',
      'roja',
      'red',
      'purple',
    ])) {
      return YieldReferenceCatalog.byId['onion_red_short_day_fresh'];
    }

    // ON-04 transicion / dia intermedio
    if (_containsAny(joined, const [
      'on-04',
      'on_04',
      'on04',
      'onion_transition',
      'onion_intermediate',
      'transicion',
      'intermedio',
      'altiplano',
      'intermediate',
    ])) {
      if (isStorage) {
        return YieldReferenceCatalog.byId['onion_storage_intensive'];
      }
      return YieldReferenceCatalog.byId['onion_intermediate_transition'];
    }

    if (isStorage) {
      return YieldReferenceCatalog.byId['onion_storage_intensive'];
    }
    if (isSweet) {
      return YieldReferenceCatalog.byId['onion_transplanted_sweet'];
    }
    if (isLowInput) {
      return YieldReferenceCatalog.byId['onion_low_input_or_semiarid'];
    }

    final direct = YieldReferenceCatalog.byId[variety];
    if (direct != null) return direct;
    return isProtected
        ? YieldReferenceCatalog.genericFreshProtected(
                CropCatalog.onionCropId,
              ) ??
              YieldReferenceCatalog.genericFresh(CropCatalog.onionCropId)
        : YieldReferenceCatalog.genericFresh(CropCatalog.onionCropId);
  }

  YieldReference? _resolveGarlicYieldReference(DeviceCropContext ctx) {
    final profile = ctx.profileId.toLowerCase();
    final alias = (ctx.varietyAlias ?? '').toLowerCase();
    final variety = (ctx.varietyId ?? '').toLowerCase();
    final calendar = (ctx.calendarTypeId ?? '').toLowerCase();
    final scale = (ctx.cultivationScaleId ?? '').toLowerCase();
    final joined = '$profile $alias $variety $calendar $scale';

    final direct = YieldReferenceCatalog.byId[variety];
    if (direct != null && direct.cropId == CropCatalog.garlicCropId) {
      return direct;
    }

    final isLowInput = _containsAny(joined, const [
      'bajo insumo',
      'temporal',
      'sin riego',
      'secano',
      'low input',
      'garlic_bajo_insumo',
      'garlic_temporal',
      'semilla mala',
      'diente malo',
    ]);
    if (isLowInput) return YieldReferenceCatalog.byId['garlic_low_input'];

    final isIntensive = _containsAny(joined, const [
      'intensivo',
      'goteo',
      'drip',
      'fertirriego',
      'riego',
      'alta tecnologia',
      'garlic_intensive_drip',
    ]);
    if (isIntensive) {
      return YieldReferenceCatalog.byId['garlic_intensive_drip'];
    }

    final isStorage = _containsAny(joined, const [
      'almacen',
      'almacenamiento',
      'storage',
      'curado',
      'curing',
      'semilla',
      'seed',
      'garlic_storage_quality',
    ]);
    if (isStorage) {
      return YieldReferenceCatalog.byId['garlic_storage_quality'];
    }

    if (_containsAny(joined, const ['orion', 'garlic_orion'])) {
      return YieldReferenceCatalog.byId['garlic_orion'];
    }

    if (_containsAny(joined, const [
      'san marqueno',
      'san marque',
      'garlic_san_marqueno',
    ])) {
      return YieldReferenceCatalog.byId['garlic_san_marqueno'];
    }

    if (_containsAny(joined, const [
      'cezac',
      'cezac 06',
      'cezac06',
      'garlic_cezac_06',
    ])) {
      return YieldReferenceCatalog.byId['garlic_cezac_06'];
    }

    if (_containsAny(joined, const ['barretero', 'garlic_barretero'])) {
      return YieldReferenceCatalog.byId['garlic_barretero'];
    }

    if (_containsAny(joined, const [
      'ag-02',
      'ag_02',
      'ag02',
      'jaspeado',
      'calera',
      'rayado',
      'inifap',
      'tacatzcuaro',
      'tinguindin',
      'garlic_jaspeado_calera',
    ])) {
      return YieldReferenceCatalog.byId['garlic_jaspeado_calera'];
    }

    if (_containsAny(joined, const [
      'ag-03',
      'ag_03',
      'ag03',
      'morado',
      'purple',
      'garlic_purple',
    ])) {
      return YieldReferenceCatalog.byId['garlic_purple'];
    }

    if (_containsAny(joined, const [
      'ag-04',
      'ag_04',
      'ag04',
      'criollo',
      'regional',
      'garlic_criollo_regional',
    ])) {
      return YieldReferenceCatalog.byId['garlic_criollo_regional'];
    }

    if (_containsAny(joined, const [
      'ag-05',
      'ag_05',
      'ag05',
      'chino',
      'coreano',
      'cedel',
      'garlic_chinese_korean',
    ])) {
      return YieldReferenceCatalog.byId['garlic_chinese_korean'];
    }

    if (_containsAny(joined, const [
      'ag-01',
      'ag_01',
      'ag01',
      'blanco',
      'perla',
      'diamante',
      'egipto',
      'garlic_white_pearl',
    ])) {
      return YieldReferenceCatalog.byId['garlic_white_pearl'];
    }

    if (_containsAny(joined, const [
      'ag-gen',
      'ag_gen',
      'aggen',
      'garlic_generic',
      'generico',
      'generica',
      'otro ajo',
      'otra variedad',
      'no se',
    ])) {
      return YieldReferenceCatalog.byId['garlic_generic'];
    }

    return YieldReferenceCatalog.genericFresh(CropCatalog.garlicCropId);
  }

  bool _containsAny(String source, List<String> needles) {
    for (final needle in needles) {
      if (source.contains(needle)) return true;
    }
    return false;
  }

  YieldReference? _genericYieldReferenceForContext(DeviceCropContext? ctx) {
    if (ctx == null) return null;

    if (_outputMode == YieldOutputMode.forage) {
      return YieldReferenceCatalog.genericForage(ctx.cropId) ??
          YieldReferenceCatalog.genericGrain(ctx.cropId);
    }

    switch (ctx.cropId) {
      case 'maize':
        final alias = (ctx.varietyAlias ?? '').toLowerCase();
        final profile = ctx.profileId.toLowerCase();

        if (alias.contains('elote') || profile.contains('elote')) {
          return YieldReferenceCatalog.byId['generic_maize_elote'];
        }
        if (alias.contains('amarill') || profile.contains('yellow')) {
          return YieldReferenceCatalog.byId['generic_maize_yellow_grain'];
        }
        return YieldReferenceCatalog.byId['generic_maize_white_grain'];

      case 'bean':
        return YieldReferenceCatalog.byId['bean_generic'];

      case 'wheat':
        return YieldReferenceCatalog.byId['wheat_generic'];

      case 'barley':
        return YieldReferenceCatalog.byId['barley_generic'];

      case 'oat':
        return YieldReferenceCatalog.byId['oat_generic'];

      case 'garlic':
        return YieldReferenceCatalog.byId['garlic_generic'];

      case 'tomato':
        // v1: suelo. Protegido vs campo abierto se discrimina por el perfil
        // oficial (TM-02 = protegido, TM-04/05 suelen ser protegido, TM-01
        // campo abierto). TM-GEN usa campo abierto como piso conservador.
        final profile = ctx.profileId.toLowerCase();
        final alias = (ctx.varietyAlias ?? '').toLowerCase();

        final isProtected =
            profile.contains('tm-02') ||
            profile.contains('tm_02') ||
            profile == 'tm02' ||
            profile.contains('protegido') ||
            alias.contains('protegido') ||
            alias.contains('invernadero') ||
            alias.contains('malla') ||
            profile.contains('tm-04') ||
            profile.contains('tm_04') ||
            profile == 'tm04' ||
            profile.contains('tm-05') ||
            profile.contains('tm_05') ||
            profile == 'tm05';

        return isProtected
            ? YieldReferenceCatalog.genericFreshProtected(ctx.cropId) ??
                  YieldReferenceCatalog.genericFresh(ctx.cropId)
            : YieldReferenceCatalog.genericFresh(ctx.cropId);

      case 'cucumber':
        final cucumberProfile = ctx.profileId.toLowerCase();
        final cucumberAlias = (ctx.varietyAlias ?? '').toLowerCase();

        final isGeneric =
            cucumberProfile.contains('pe-gen') ||
            cucumberProfile.contains('pe_gen') ||
            cucumberProfile == 'pegen' ||
            cucumberAlias.contains('generico') ||
            cucumberAlias.contains('genérico');

        if (isGeneric) {
          return YieldReferenceCatalog.byId['cucumber_generic'];
        }

        final isPickler =
            cucumberProfile.contains('pe-04') ||
            cucumberProfile.contains('pe_04') ||
            cucumberProfile == 'pe04' ||
            cucumberAlias.contains('pickler') ||
            cucumberAlias.contains('pickle') ||
            cucumberAlias.contains('pepinillo') ||
            cucumberAlias.contains('encurtido');
        if (isPickler) {
          return YieldReferenceCatalog.byId['cucumber_pickler'];
        }

        final cucumberIsProtected =
            cucumberProfile.contains('pe-02') ||
            cucumberProfile.contains('pe_02') ||
            cucumberProfile == 'pe02' ||
            cucumberProfile.contains('pe-03') ||
            cucumberProfile.contains('pe_03') ||
            cucumberProfile == 'pe03' ||
            cucumberProfile.contains('protegido') ||
            cucumberAlias.contains('protegido') ||
            cucumberAlias.contains('invernadero') ||
            cucumberAlias.contains('malla') ||
            cucumberAlias.contains('europeo') ||
            cucumberAlias.contains('ingles') ||
            cucumberAlias.contains('inglés') ||
            cucumberAlias.contains('persa') ||
            cucumberAlias.contains('mini') ||
            cucumberAlias.contains('beit');

        final isEuropean =
            cucumberProfile.contains('pe-02') ||
            cucumberProfile.contains('pe_02') ||
            cucumberProfile == 'pe02' ||
            cucumberAlias.contains('europeo') ||
            cucumberAlias.contains('ingles') ||
            cucumberAlias.contains('inglés');
        if (isEuropean) {
          return YieldReferenceCatalog.byId['cucumber_european_protected'];
        }

        final isPersian =
            cucumberProfile.contains('pe-03') ||
            cucumberProfile.contains('pe_03') ||
            cucumberProfile == 'pe03' ||
            cucumberAlias.contains('persa') ||
            cucumberAlias.contains('mini') ||
            cucumberAlias.contains('beit');
        if (isPersian) {
          return YieldReferenceCatalog.byId['cucumber_persian'];
        }

        return cucumberIsProtected
            ? YieldReferenceCatalog.genericFreshProtected(ctx.cropId) ??
                  YieldReferenceCatalog.genericFresh(ctx.cropId)
            : YieldReferenceCatalog.byId['cucumber_slicer_ca'] ??
                  YieldReferenceCatalog.genericFresh(ctx.cropId);

      case 'chili':
        final chiliProfile = ctx.profileId.toLowerCase();
        final chiliAlias = (ctx.varietyAlias ?? '').toLowerCase();

        final isGeneric =
            chiliProfile.contains('ch-gen') ||
            chiliProfile.contains('ch_gen') ||
            chiliProfile == 'chgen' ||
            chiliAlias.contains('generico') ||
            chiliAlias.contains('otro chile') ||
            chiliAlias.contains('no se');
        if (isGeneric) return YieldReferenceCatalog.byId['chili_generic'];

        final isProtected =
            chiliProfile.contains('protegido') ||
            chiliAlias.contains('protegido') ||
            chiliAlias.contains('invernadero') ||
            chiliAlias.contains('malla') ||
            chiliAlias.contains('casa malla');

        final wantsDry =
            chiliAlias.contains('seco') || chiliAlias.contains('deshidratado');

        if (chiliProfile.contains('ch-01') ||
            chiliProfile.contains('ch_01') ||
            chiliProfile == 'ch01' ||
            chiliAlias.contains('jalapeno') ||
            chiliAlias.contains('chipotle')) {
          return YieldReferenceCatalog.byId['chili_jalapeno'];
        }
        if (chiliProfile.contains('ch-02') ||
            chiliProfile.contains('ch_02') ||
            chiliProfile == 'ch02' ||
            chiliAlias.contains('serrano')) {
          return YieldReferenceCatalog.byId['chili_serrano'];
        }
        if (chiliProfile.contains('ch-03') ||
            chiliProfile.contains('ch_03') ||
            chiliProfile == 'ch03' ||
            chiliAlias.contains('poblano') ||
            chiliAlias.contains('ancho') ||
            chiliAlias.contains('mulato')) {
          // Destino seco para CH-03 -> ancho/mulato seco.
          if (wantsDry ||
              chiliAlias.contains('ancho') ||
              chiliAlias.contains('mulato')) {
            return YieldReferenceCatalog.byId['chili_ancho_dry'] ??
                YieldReferenceCatalog.byId['chili_poblano_ancho'];
          }
          return YieldReferenceCatalog.byId['chili_poblano_ancho'];
        }
        if (chiliProfile.contains('ch-04') ||
            chiliProfile.contains('ch_04') ||
            chiliProfile == 'ch04' ||
            chiliAlias.contains('chilaca') ||
            chiliAlias.contains('pasilla')) {
          // Chilaca verde fresca vs pasilla seco.
          if (chiliAlias.contains('chilaca') && !wantsDry) {
            return YieldReferenceCatalog.byId['chili_chilaca_fresh'] ??
                YieldReferenceCatalog.byId['chili_chilaca_pasilla'];
          }
          return YieldReferenceCatalog.byId['chili_chilaca_pasilla'];
        }
        if (chiliProfile.contains('ch-05') ||
            chiliProfile.contains('ch_05') ||
            chiliProfile == 'ch05' ||
            chiliAlias.contains('guajillo') ||
            chiliAlias.contains('mirasol')) {
          return YieldReferenceCatalog.byId['chili_guajillo_mirasol'];
        }
        if (chiliProfile.contains('ch-06') ||
            chiliProfile.contains('ch_06') ||
            chiliProfile == 'ch06' ||
            chiliAlias.contains('arbol') ||
            chiliAlias.contains('puya')) {
          final wantsFresh =
              chiliAlias.contains('fresco') ||
              chiliAlias.contains('fresh') ||
              chiliAlias.contains('verde');
          if (wantsFresh && !wantsDry) {
            return YieldReferenceCatalog.byId['chili_arbol_fresh'] ??
                YieldReferenceCatalog.byId['chili_arbol_puya_dry'] ??
                YieldReferenceCatalog.byId['chili_arbol_puya'];
          }
          return YieldReferenceCatalog.byId['chili_arbol_puya_dry'] ??
              YieldReferenceCatalog.byId['chili_arbol_puya'];
        }
        if (chiliProfile.contains('ch-07') ||
            chiliProfile.contains('ch_07') ||
            chiliProfile == 'ch07' ||
            chiliAlias.contains('habanero')) {
          return YieldReferenceCatalog.byId['chili_habanero'];
        }
        if (chiliProfile.contains('ch-08') ||
            chiliProfile.contains('ch_08') ||
            chiliProfile == 'ch08' ||
            chiliAlias.contains('morron') ||
            chiliAlias.contains('gordo') ||
            chiliAlias.contains('pimiento') ||
            chiliAlias.contains('bell')) {
          if (isProtected) {
            return YieldReferenceCatalog.byId['chili_bell_pepper_protected'] ??
                YieldReferenceCatalog.byId['chili_bell_pepper'];
          }
          return YieldReferenceCatalog.byId['chili_bell_pepper'];
        }

        return isProtected
            ? YieldReferenceCatalog.genericFreshProtected(ctx.cropId) ??
                  YieldReferenceCatalog.genericFresh(ctx.cropId)
            : YieldReferenceCatalog.genericFresh(ctx.cropId);

      case 'eggplant':
        return _resolveEggplantYieldReference(ctx) ??
            YieldReferenceCatalog.genericFresh(ctx.cropId);

      default:
        return null;
    }
  }

  void _changeOutputMode(YieldOutputMode mode) {
    if (_saving || mode == _outputMode) return;

    final store = _readStore();
    final cropContext = store.activeCropContext;
    final areaValue = _parsePositive(_areaController.text);
    final populationInput = _parsePositive(_populationController.text);
    final healthScore = _getActualHealthScore(store);

    setState(() {
      _outputMode = mode;
    });

    if (cropContext != null && areaValue != null && populationInput != null) {
      _calculateProjections(
        areaValue,
        populationInput,
        cropContext,
        healthScore,
      );

      setState(() {
        _isCalculated = true;
        _calculationTrigger++;
      });
    } else {
      setState(() {
        _isCalculated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = BioGScope.of(context);
    final activeDevice = store.activeDevice;
    final cropContext = store.activeCropContext;
    final canEdit = activeDevice != null && cropContext != null;

    final areaValue = _parsePositive(_areaController.text);
    final populationInput = _parsePositive(_populationController.text);
    final estimatedSeedsPerHa = _estimateSeedsPerHa(
      areaValue: areaValue,
      populationInput: populationInput,
      areaUnit: _areaUnit,
    );
    final estimatedTotalSeeds = _estimateTotalSeeds(
      areaValue: areaValue,
      populationInput: populationInput,
      areaUnit: _areaUnit,
    );

    final YieldReference? activeReference = _resolveYieldReference(cropContext);
    final bool isProjectionSupported = _areaUnit != YieldAreaUnit.pot;
    final bool isReadyToCalculate =
        isProjectionSupported && areaValue != null && populationInput != null;
    final double realHealthScore = _getActualHealthScore(store);
    final bool supportsBothModes =
        cropContext != null &&
        isProjectionSupported &&
        YieldOutputModeSupport.supportsBothModes(cropContext.cropId);

    return Scaffold(
      backgroundColor: BioGTheme.surface,
      appBar: AppBar(
        backgroundColor: BioGTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Calculadora de Rendimiento',
          style: TextStyle(fontWeight: FontWeight.w900, color: BioGTheme.ink),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _HeroProjectionCard(
                  hasManualBase: areaValue != null && populationInput != null,
                  isCalculated: _isCalculated,
                  isProjectionSupported: isProjectionSupported,
                  animationKey: _calculationTrigger,
                  cropName: _prettyCropName(cropContext?.cropId),
                  targetYieldPerUnit: _projectedYieldPerUnit,
                  yieldUnitLabel: _yieldUnitLabel,
                  targetTotalYield: _projectedTotalYield,
                  totalUnitLabel: _totalUnitLabel,
                  targetIncome: _projectedIncome,
                  healthScore: realHealthScore,
                  supportBadgeLabel: _referenceSupportBadgeLabel(
                    activeReference,
                  ),
                  manualBaseHint: _isTreeCrop
                      ? 'Ingresa la superficie y árboles abajo'
                      : 'Ingresa la superficie y semillas abajo',
                  yieldNoun: switch (CropCatalog.canonicalCropKey(
                    cropContext?.cropId,
                  )) {
                    CropCatalog.walnutTreeCropId =>
                      'rendimiento aproximado de nuez con cáscara',
                    CropCatalog.pistachioTreeCropId =>
                      'rendimiento aproximado de pistache seco con cáscara',
                    CropCatalog.orangeTreeCropId =>
                      'rendimiento aproximado de naranja fresca',
                    CropCatalog.lemonTreeCropId =>
                      'rendimiento aproximado de limón fresco',
                    CropCatalog.mangoTreeCropId =>
                      'rendimiento aproximado de mango fresco',
                    CropCatalog.avocadoTreeCropId =>
                      'rendimiento aproximado de aguacate fresco',
                    _ => 'rendimiento aproximado',
                  },
                ),
                const SizedBox(height: 24),

                _SectionHeaderWithMode(
                  title: 'Base manual del lote',
                  showModeSelector: supportsBothModes,
                  outputMode: _outputMode,
                  onModeChanged: _saving ? null : _changeOutputMode,
                ),

                const SizedBox(height: 12),

                if (!canEdit)
                  _buildMissingContextCard()
                else ...[
                  _OverviewInfoCard(
                    title: 'Superficie del lote',
                    value: areaValue == null
                        ? 'Aún sin capturar'
                        : '${formatNumber(areaValue)} ${_areaUnitLabelPlural(_areaUnit)}',
                    subtitle: _areaSubtitle(cropContext, _areaUnit),
                    leading: const _AssetGlyph(
                      assetPath: _surfaceIconAsset,
                      scale: _surfaceIconScale,
                      size: 24,
                      dx: 27,
                      dy: 20,
                    ),
                    trailing: _EditPillButton(
                      label: 'Editar',
                      onTap: _saving ? null : () => _editArea(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _OverviewInfoCard(
                    title: _populationCardTitle(_areaUnit),
                    value: populationInput == null
                        ? 'Aún sin capturar'
                        : _populationCardValue(
                            populationInput: populationInput,
                            areaUnit: _areaUnit,
                          ),
                    subtitle: _populationCardSubtitle(
                      areaValue: areaValue,
                      populationInput: populationInput,
                      estimatedSeedsPerHa: estimatedSeedsPerHa,
                      estimatedTotalSeeds: estimatedTotalSeeds,
                    ),
                    leading: const _AssetGlyph(
                      assetPath: _seedsIconAsset,
                      scale: _seedsIconScale,
                      size: 24,
                      dx: 25,
                      dy: 30,
                    ),
                    trailing: _EditPillButton(
                      label: 'Editar',
                      onTap: _saving ? null : () => _editPopulationInput(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _showVarietyInfoDialog,
                    child: _OverviewInfoCard(
                      title: _varietyCardTitle(cropContext),
                      value: _varietyTitle(cropContext),
                      subtitle: _varietySubtitle(cropContext),
                      leading: _AssetGlyph(
                        assetPath: _cropIconAssetFor(cropContext),
                        scale: _cropIconScale,
                        size: 24,
                        dx: 27,
                        dy: 20,
                      ),
                      trailing: const _ReadOnlyTag('Wizard'),
                    ),
                  ),
                ],

                const SizedBox(height: 18),
                _InlineInfoText(
                  ready: isReadyToCalculate,
                  isCalculated: _isCalculated,
                  unsupported: !isProjectionSupported,
                  supportNote: _projectionSupportNote(activeReference),
                  missingTargetLabel: _isTreeCrop ? 'Árboles' : 'Semillas',
                ),
              ],
            ),
          ),
          _buildStickyBottomBar(
            canEdit: canEdit,
            isReady: isReadyToCalculate,
            isProjectionSupported: isProjectionSupported,
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar({
    required bool canEdit,
    required bool isReady,
    required bool isProjectionSupported,
  }) {
    final label = !isProjectionSupported
        ? 'Proyección por maceta próximamente'
        : (_isCalculated ? 'Recalcular Proyección' : 'Calcular Proyección');

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: BioGTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BioGButton(
        label: label,
        loading: _saving,
        onTap: (!canEdit || !isReady || !isProjectionSupported || _saving)
            ? null
            : () => _save(),
      ),
    );
  }

  void _showVarietyInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: BioGGlassCard(
            radius: 26,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 76,
                  child: Center(
                    child: Transform.scale(
                      scale: 3.3,
                      child: Image.asset(
                        'assets/icons/wizard/ic_configurar_cultivo.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isTreeCrop ? 'Variedad del árbol' : 'Variedad Inteligente',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: BioGTheme.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isTreeCrop
                      ? 'El modelo matemático de BIO-G se adapta a la variedad y etapa de tu árbol.\n\nPara cambiar la variedad y ajustar el cálculo, debes reconfigurarla directamente desde el Wizard del dispositivo.'
                      : 'El modelo matemático de BIO-G se adapta a la genética específica de tu semilla.\n\nPara cambiar la variedad y ajustar el cálculo, debes reconfigurarla directamente desde el Wizard del dispositivo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: BioGTheme.ink.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(
                            color: BioGTheme.brandMid.withValues(alpha: 0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Entendido',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: BioGTheme.teal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BioGButton(
                        label: 'Ir al Wizard',
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pushNamed('/account');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissingContextCard() {
    return BioGGlassCard(
      radius: BioGTheme.rCard,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: BioGTheme.warmOrange,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Sin cultivo activo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: BioGTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Para usar la calculadora necesitas configurar el cultivo desde el wizard del dispositivo primero.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: BioGTheme.ink.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editArea() async {
    final result = await _showNumberEditor(
      title: 'Editar superficie del lote',
      helper:
          'La unidad se toma automáticamente desde el tipo de dispositivo. Aquí solo ajustas la cantidad.',
      label: 'Superficie (${_areaUnitLabelPlural(_areaUnit)})',
      initialValue: _areaController.text,
      hint: _areaHintForUnit(_areaUnit),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    if (!mounted || result == null) return;
    setState(() => _areaController.text = result);
    _resetCalculation();
  }

  Future<void> _editPopulationInput() async {
    final result = await _showNumberEditor(
      title: _populationEditorTitle(_areaUnit),
      helper: _populationEditorHelper(_areaUnit),
      label: _populationEditorLabel(_areaUnit),
      initialValue: _populationController.text,
      hint: _populationHintForUnit(_areaUnit),
      keyboardType: TextInputType.numberWithOptions(
        decimal: _areaUnit == YieldAreaUnit.squareMeter,
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _populationController.text = result);
    _resetCalculation();
  }

  void _resetCalculation() {
    if (_isCalculated) {
      setState(() => _isCalculated = false);
    }
  }

  Future<String?> _showNumberEditor({
    required String title,
    required String helper,
    required String label,
    required String initialValue,
    required String hint,
    required TextInputType keyboardType,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final controller = TextEditingController(text: initialValue);
        final formKey = GlobalKey<FormState>();

        return Padding(
          padding: EdgeInsets.fromLTRB(
            14,
            0,
            14,
            MediaQuery.of(sheetContext).viewInsets.bottom + 14,
          ),
          child: BioGGlassCard(
            radius: 26,
            padding: const EdgeInsets.all(22),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: BioGTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    helper,
                    style: TextStyle(
                      fontSize: 13.3,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: BioGTheme.ink.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: keyboardType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: BioGTheme.ink,
                    ),
                    validator: (value) {
                      if (_parsePositive(value) == null) {
                        return 'Captura un valor válido.';
                      }
                      return null;
                    },
                    decoration: _sheetInputDecoration(label: label, hint: hint),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            side: BorderSide(
                              color: BioGTheme.brandMid.withValues(alpha: 0.22),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                BioGTheme.rButton,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: BioGTheme.teal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BioGButton(
                          label: 'Aplicar',
                          onTap: () {
                            if (formKey.currentState?.validate() ?? false) {
                              Navigator.of(
                                sheetContext,
                              ).pop(controller.text.trim());
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _sheetInputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: BioGTheme.ink.withValues(alpha: 0.6),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: BioGTheme.brandMid.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: BioGTheme.brandMid, width: 2.0),
      ),
    );
  }

  Future<void> _save() async {
    final store = _readStore();
    final activeDevice = store.activeDevice;
    final cropContext = store.activeCropContext;
    final existing = store.activeYieldProjectionConfig;

    if (activeDevice == null || cropContext == null) return;
    if (_areaUnit == YieldAreaUnit.pot) {
      _showMessage(
        'La proyección para maceta aún no está disponible. Por ahora la calculadora proyecta campo y huerto.',
      );
      return;
    }

    final areaValue = _parsePositive(_areaController.text);
    final populationInput = _parsePositive(_populationController.text);

    if (areaValue == null || populationInput == null) return;

    final actualHealthScore = _getActualHealthScore(store);
    _calculateProjections(
      areaValue,
      populationInput,
      cropContext,
      actualHealthScore,
    );

    setState(() {
      _saving = true;
      _isCalculated = false;
    });

    try {
      final now = DateTime.now();
      final base =
          existing ??
          YieldProjectionConfig.initial(
            deviceId: activeDevice.id,
            cropId: cropContext.cropId,
            cultivationScaleId: cropContext.cultivationScaleId,
            areaUnit: _areaUnit,
            inputMethod: _inputMethodForAreaUnit(_areaUnit),
            now: now,
          );

      final projectionBase = _buildProjectionConfigForInput(
        deviceId: activeDevice.id,
        cropId: cropContext.cropId,
        cultivationScaleId: cropContext.cultivationScaleId,
        areaValue: areaValue,
        populationInput: populationInput,
        now: now,
      );

      final config = base.copyWith(
        cropId: cropContext.cropId,
        cultivationScaleId: cropContext.cultivationScaleId,
        areaValue: projectionBase.areaValue,
        areaUnit: projectionBase.areaUnit,
        inputMethod: projectionBase.inputMethod,
        targetPopulationPerHa: projectionBase.targetPopulationPerHa,
        totalSeedsSown: projectionBase.totalSeedsSown,
        updatedAt: now,
      );

      await store.saveYieldProjectionConfig(config);

      if (!mounted) return;

      setState(() {
        _saving = false;
        _isCalculated = true;
        _calculationTrigger++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Error al calcular la proyección.');
    }
  }

  YieldAreaUnit _defaultAreaUnitForScale(DeviceCropContext? cropContext) {
    switch (cropContext?.cultivationScaleId) {
      case 'bed':
        return YieldAreaUnit.squareMeter;
      case 'pot':
        return YieldAreaUnit.pot;
      default:
        return YieldAreaUnit.hectare;
    }
  }

  double? _initialPopulationInputForConfig(
    YieldProjectionConfig? existing,
    YieldAreaUnit areaUnit,
  ) {
    if (existing == null) return null;

    switch (existing.inputMethod) {
      case YieldInputMethod.populationPerArea:
        final perHa = existing.targetPopulationPerHa;
        if (perHa == null || perHa <= 0) return null;
        return switch (areaUnit) {
          YieldAreaUnit.hectare => perHa,
          YieldAreaUnit.squareMeter => perHa / 10000.0,
          YieldAreaUnit.pot =>
            existing.totalSeedsSown ?? existing.estimatedSeedsSown,
        };

      case YieldInputMethod.totalSeeds:
      case YieldInputMethod.bagsAndSeedsPerBag:
        final totalSeeds =
            existing.totalSeedsSown ?? existing.estimatedSeedsSown;
        if (totalSeeds == null || totalSeeds <= 0) return null;

        return switch (areaUnit) {
          YieldAreaUnit.hectare => _estimateSeedsPerHaFromTotalSeeds(
            areaValue: existing.areaValue,
            totalSeeds: totalSeeds,
            areaUnit: areaUnit,
          ),
          YieldAreaUnit.squareMeter =>
            _estimatePopulationPerSquareMeterFromTotalSeeds(
              areaValue: existing.areaValue,
              totalSeeds: totalSeeds,
              areaUnit: areaUnit,
            ),
          YieldAreaUnit.pot => totalSeeds,
        };
    }
  }

  YieldProjectionConfig _buildProjectionConfigForInput({
    required String deviceId,
    required String cropId,
    required String? cultivationScaleId,
    required double areaValue,
    required double populationInput,
    required DateTime now,
  }) {
    final inputMethod = _inputMethodForAreaUnit(_areaUnit);

    if (inputMethod == YieldInputMethod.populationPerArea) {
      return YieldProjectionConfig.initial(
        deviceId: deviceId,
        cropId: cropId,
        cultivationScaleId: cultivationScaleId,
        areaUnit: _areaUnit,
        inputMethod: YieldInputMethod.populationPerArea,
        now: now,
      ).copyWith(
        areaValue: areaValue,
        targetPopulationPerHa: _populationPerHaFromInput(
          populationInput: populationInput,
          areaUnit: _areaUnit,
        ),
        totalSeedsSown: null,
        updatedAt: now,
      );
    }

    return YieldProjectionConfig.initial(
      deviceId: deviceId,
      cropId: cropId,
      cultivationScaleId: cultivationScaleId,
      areaUnit: _areaUnit,
      inputMethod: YieldInputMethod.totalSeeds,
      now: now,
    ).copyWith(
      areaValue: areaValue,
      totalSeedsSown: populationInput,
      targetPopulationPerHa: null,
      updatedAt: now,
    );
  }

  YieldInputMethod _inputMethodForAreaUnit(YieldAreaUnit unit) {
    return unit == YieldAreaUnit.pot
        ? YieldInputMethod.totalSeeds
        : YieldInputMethod.populationPerArea;
  }

  double? _populationPerHaFromInput({
    required double? populationInput,
    required YieldAreaUnit areaUnit,
  }) {
    if (populationInput == null || populationInput <= 0) return null;
    return switch (areaUnit) {
      YieldAreaUnit.hectare => populationInput,
      YieldAreaUnit.squareMeter => populationInput * 10000.0,
      YieldAreaUnit.pot => null,
    };
  }

  double? _estimateSeedsPerHa({
    required double? areaValue,
    required double? populationInput,
    required YieldAreaUnit areaUnit,
  }) {
    if (populationInput == null) return null;
    return switch (areaUnit) {
      YieldAreaUnit.hectare => populationInput,
      YieldAreaUnit.squareMeter => populationInput * 10000.0,
      YieldAreaUnit.pot => _estimateSeedsPerHaFromTotalSeeds(
        areaValue: areaValue,
        totalSeeds: populationInput,
        areaUnit: areaUnit,
      ),
    };
  }

  double? _estimatePopulationPerSquareMeterFromTotalSeeds({
    required double? areaValue,
    required double? totalSeeds,
    required YieldAreaUnit areaUnit,
  }) {
    final perHa = _estimateSeedsPerHaFromTotalSeeds(
      areaValue: areaValue,
      totalSeeds: totalSeeds,
      areaUnit: areaUnit,
    );
    if (perHa == null) return null;
    return perHa / 10000.0;
  }

  double? _estimateSeedsPerHaFromTotalSeeds({
    required double? areaValue,
    required double? totalSeeds,
    required YieldAreaUnit areaUnit,
  }) {
    if (areaValue == null || totalSeeds == null) return null;
    final areaInHectares = switch (areaUnit) {
      YieldAreaUnit.hectare => areaValue,
      YieldAreaUnit.squareMeter => areaValue / 10000,
      YieldAreaUnit.pot => null,
    };
    if (areaInHectares == null || areaInHectares <= 0) return null;
    return totalSeeds / areaInHectares;
  }

  double? _estimateTotalSeeds({
    required double? areaValue,
    required double? populationInput,
    required YieldAreaUnit areaUnit,
  }) {
    if (areaValue == null || populationInput == null) return null;
    return switch (areaUnit) {
      YieldAreaUnit.hectare => populationInput * areaValue,
      YieldAreaUnit.squareMeter => populationInput * areaValue,
      YieldAreaUnit.pot => populationInput,
    };
  }

  String _populationCardTitle(YieldAreaUnit unit) {
    if (_isTreeCrop) {
      switch (unit) {
        case YieldAreaUnit.hectare:
          return 'Árboles por hectárea';
        case YieldAreaUnit.squareMeter:
          return 'Árboles por m²';
        case YieldAreaUnit.pot:
          return 'Árboles';
      }
    }
    if (_populationInputMeansEstablishedPlants) {
      switch (unit) {
        case YieldAreaUnit.hectare:
          return 'Plantas establecidas por hectarea';
        case YieldAreaUnit.squareMeter:
          return 'Plantas establecidas por m2';
        case YieldAreaUnit.pot:
          return 'Plantas establecidas';
      }
    }
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'Semillas sembradas por hectárea';
      case YieldAreaUnit.squareMeter:
        return 'Semillas sembradas por m²';
      case YieldAreaUnit.pot:
        return 'Semillas sembradas';
    }
  }

  String _populationCardValue({
    required double populationInput,
    required YieldAreaUnit areaUnit,
  }) {
    if (_isTreeCrop) {
      switch (areaUnit) {
        case YieldAreaUnit.hectare:
          return '${formatNumber(populationInput)} árboles/ha';
        case YieldAreaUnit.squareMeter:
          return '${formatNumber(populationInput, maxDecimals: 2)} árboles/m²';
        case YieldAreaUnit.pot:
          return '${formatNumber(populationInput)} árboles en total';
      }
    }
    if (_populationInputMeansEstablishedPlants) {
      switch (areaUnit) {
        case YieldAreaUnit.hectare:
          return '${formatNumber(populationInput)} plantas/ha';
        case YieldAreaUnit.squareMeter:
          return '${formatNumber(populationInput, maxDecimals: 2)} plantas/m2';
        case YieldAreaUnit.pot:
          return '${formatNumber(populationInput)} plantas en total';
      }
    }
    switch (areaUnit) {
      case YieldAreaUnit.hectare:
        return '${formatNumber(populationInput)} semillas/ha';
      case YieldAreaUnit.squareMeter:
        return '${formatNumber(populationInput, maxDecimals: 2)} semillas/m²';
      case YieldAreaUnit.pot:
        return '${formatNumber(populationInput)} semillas en total';
    }
  }

  String _populationCardSubtitle({
    required double? areaValue,
    required double? populationInput,
    required double? estimatedSeedsPerHa,
    required double? estimatedTotalSeeds,
  }) {
    if (_isTreeCrop) {
      if (populationInput == null) {
        return _areaUnit == YieldAreaUnit.pot
            ? 'Captura cuántos árboles tienes en total.'
            : 'Captura la densidad de árboles y BIO-G calculará el total del huerto.';
      }
      switch (_areaUnit) {
        case YieldAreaUnit.hectare:
          if (areaValue == null || estimatedTotalSeeds == null) {
            return 'BIO-G multiplicará esta densidad por tu superficie total.';
          }
          return '≈ ${formatNumber(estimatedTotalSeeds)} árboles en ${formatNumber(areaValue)} ha';
        case YieldAreaUnit.squareMeter:
          if (estimatedSeedsPerHa == null || estimatedTotalSeeds == null) {
            return 'BIO-G convertirá esta densidad a árboles por hectárea.';
          }
          return '≈ ${formatNumber(estimatedTotalSeeds)} árboles totales • ${formatNumber(estimatedSeedsPerHa)} árboles/ha';
        case YieldAreaUnit.pot:
          return 'Modo maceta: captura simple sin proyección agronómica por hectárea.';
      }
    }
    if (_populationInputMeansEstablishedPlants) {
      if (populationInput == null) {
        return _areaUnit == YieldAreaUnit.pot
            ? 'Captura plantas establecidas totales.'
            : 'Captura densidad de plantas establecidas; BIO-G no usa semilla bruta en calabaza.';
      }
      switch (_areaUnit) {
        case YieldAreaUnit.hectare:
          if (areaValue == null || estimatedTotalSeeds == null) {
            return 'BIO-G multiplicara esta densidad por tu superficie total.';
          }
          return 'Aprox. ${formatNumber(estimatedTotalSeeds)} plantas en ${formatNumber(areaValue)} ha';
        case YieldAreaUnit.squareMeter:
          if (estimatedSeedsPerHa == null || estimatedTotalSeeds == null) {
            return 'BIO-G convertira esta densidad a plantas por hectarea.';
          }
          return 'Aprox. ${formatNumber(estimatedTotalSeeds)} plantas totales - ${formatNumber(estimatedSeedsPerHa)} plantas/ha';
        case YieldAreaUnit.pot:
          return 'Modo maceta: captura simple sin proyeccion agronomica por hectarea.';
      }
    }
    if (populationInput == null) {
      return _areaUnit == YieldAreaUnit.pot
          ? 'Captura el total sembrado en tus macetas.'
          : 'Captura la densidad de siembra y BIO-G calculará el total del lote.';
    }

    switch (_areaUnit) {
      case YieldAreaUnit.hectare:
        if (areaValue == null || estimatedTotalSeeds == null) {
          return 'BIO-G multiplicará esta densidad por tu superficie total.';
        }
        return '≈ ${formatNumber(estimatedTotalSeeds)} semillas en ${formatNumber(areaValue)} ha';
      case YieldAreaUnit.squareMeter:
        if (estimatedSeedsPerHa == null || estimatedTotalSeeds == null) {
          return 'BIO-G convertirá esta densidad a población equivalente por hectárea.';
        }
        return '≈ ${formatNumber(estimatedTotalSeeds)} semillas totales • ${formatNumber(estimatedSeedsPerHa)} semillas/ha';
      case YieldAreaUnit.pot:
        return 'Modo maceta: captura simple sin proyección agronómica por hectárea.';
    }
  }

  String _populationEditorTitle(YieldAreaUnit unit) {
    if (_isTreeCrop) {
      switch (unit) {
        case YieldAreaUnit.hectare:
          return 'Editar árboles por hectárea';
        case YieldAreaUnit.squareMeter:
          return 'Editar árboles por m²';
        case YieldAreaUnit.pot:
          return 'Editar árboles';
      }
    }
    if (_populationInputMeansEstablishedPlants) {
      switch (unit) {
        case YieldAreaUnit.hectare:
          return 'Editar plantas por hectarea';
        case YieldAreaUnit.squareMeter:
          return 'Editar plantas por m2';
        case YieldAreaUnit.pot:
          return 'Editar plantas establecidas';
      }
    }
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'Editar semillas por hectárea';
      case YieldAreaUnit.squareMeter:
        return 'Editar semillas por m²';
      case YieldAreaUnit.pot:
        return 'Editar semillas sembradas';
    }
  }

  String _populationEditorHelper(YieldAreaUnit unit) {
    if (_isTreeCrop) {
      switch (unit) {
        case YieldAreaUnit.hectare:
          return 'Captura cuántos árboles tienes por cada hectárea. BIO-G multiplicará esa densidad por la superficie total del huerto.';
        case YieldAreaUnit.squareMeter:
          return 'Captura cuántos árboles tienes por cada metro cuadrado. BIO-G convertirá esta densidad al equivalente por hectárea.';
        case YieldAreaUnit.pot:
          return 'En maceta capturamos el total de árboles, sin aplicar todavía una proyección agronómica por superficie.';
      }
    }
    if (_populationInputMeansEstablishedPlants) {
      switch (unit) {
        case YieldAreaUnit.hectare:
          return 'Captura cuantas plantas establecidas tienes por hectarea. Para calabaza BIO-G usa poblacion real de plantas, no semilla bruta.';
        case YieldAreaUnit.squareMeter:
          return 'Captura cuantas plantas establecidas tienes por metro cuadrado. BIO-G lo convertira a plantas por hectarea.';
        case YieldAreaUnit.pot:
          return 'En maceta captura plantas establecidas totales; la proyeccion por hectarea no se aplica en esta escala.';
      }
    }
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'Captura cuántas semillas sembraste por cada hectárea. BIO-G multiplicará esa densidad por la superficie total del lote.';
      case YieldAreaUnit.squareMeter:
        return 'Captura cuántas semillas sembraste por cada metro cuadrado. BIO-G convertirá esta densidad al equivalente por hectárea para estimar el rendimiento.';
      case YieldAreaUnit.pot:
        return 'En maceta seguimos capturando el total sembrado, pero sin aplicar todavía una proyección agronómica por superficie.';
    }
  }

  String _populationEditorLabel(YieldAreaUnit unit) {
    if (_isTreeCrop) {
      switch (unit) {
        case YieldAreaUnit.hectare:
          return 'Árboles por hectárea';
        case YieldAreaUnit.squareMeter:
          return 'Árboles por m²';
        case YieldAreaUnit.pot:
          return 'Total de árboles';
      }
    }
    if (_populationInputMeansEstablishedPlants) {
      switch (unit) {
        case YieldAreaUnit.hectare:
          return 'Plantas por hectarea';
        case YieldAreaUnit.squareMeter:
          return 'Plantas por m2';
        case YieldAreaUnit.pot:
          return 'Total de plantas';
      }
    }
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'Semillas por hectárea';
      case YieldAreaUnit.squareMeter:
        return 'Semillas por m²';
      case YieldAreaUnit.pot:
        return 'Total de semillas';
    }
  }

  String _populationHintForUnit(YieldAreaUnit unit) {
    if (_isTreeCrop) {
      switch (unit) {
        case YieldAreaUnit.hectare:
          return 'Ej. 800';
        case YieldAreaUnit.squareMeter:
          return 'Ej. 0.08';
        case YieldAreaUnit.pot:
          return 'Ej. 1';
      }
    }
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'Ej. 80000';
      case YieldAreaUnit.squareMeter:
        return 'Ej. 8.0';
      case YieldAreaUnit.pot:
        return 'Ej. 24';
    }
  }

  String _areaSubtitle(DeviceCropContext? cropContext, YieldAreaUnit unit) {
    final scaleText = switch (cropContext?.cultivationScaleId) {
      'field' => 'Campo',
      'bed' => 'Huerto',
      'pot' => 'Maceta',
      _ => 'Lote',
    };
    return '$scaleText • ${_areaUnitLabelPlural(unit)} de cultivo';
  }

  String _cropIconAssetFor(DeviceCropContext? cropContext) {
    return OnboardingUiAssets.assetForCrop(cropContext?.cropId);
  }

  String _varietyCardTitle(DeviceCropContext? cropContext) {
    if (isTreeContext(cropContext)) {
      final cropId = CropCatalog.canonicalCropKey(cropContext?.cropId);
      return switch (cropId) {
        CropCatalog.appleTreeCropId => 'Variedad de manzano',
        CropCatalog.pearTreeCropId => 'Variedad de peral',
        CropCatalog.peachTreeCropId => 'Variedad de duraznero',
        CropCatalog.walnutTreeCropId => 'Variedad de nogal',
        CropCatalog.pistachioTreeCropId => 'Tipo de pistache',
        CropCatalog.orangeTreeCropId => 'Tipo de naranja',
        CropCatalog.lemonTreeCropId => 'Tipo de limón',
        CropCatalog.mangoTreeCropId => 'Tipo de mango',
        CropCatalog.avocadoTreeCropId => 'Tipo de aguacate',
        _ => 'Variedad',
      };
    }
    return 'Variedad de semilla';
  }

  String _varietyTitle(DeviceCropContext? cropContext) {
    if (cropContext == null) return 'Sin cultivo configurado';
    final cropId = CropCatalog.canonicalCropKey(cropContext.cropId);
    if (cropId == CropCatalog.squashCropId &&
        (CropCatalog.isGenericAlias(cropContext.varietyAlias) ||
            CropCatalog.isGenericProfileId(cropContext.profileId))) {
      return 'Calabaza generica';
    }
    return cropContext.varietyAlias ?? _prettyCropName(cropContext.cropId);
  }

  String _varietySubtitle(DeviceCropContext? cropContext) {
    if (cropContext == null) return 'Configura desde el wizard';
    final parts = <String>[_prettyCropName(cropContext.cropId)];
    final brand = _prettyId(cropContext.brandId);
    final calendar = _prettyId(cropContext.calendarTypeId);
    if (brand != null) parts.add(brand);
    if (calendar != null) parts.add(calendar);
    return parts.join(' • ');
  }

  String _prettyCropName(String? cropId) {
    switch (cropId) {
      case 'maize':
        return 'Maíz';
      case 'oat':
        return 'Avena';
      case 'wheat':
        return 'Trigo';
      case 'barley':
        return 'Cebada';
      case 'bean':
        return 'Frijol';
      case 'tomato':
        return 'Tomate';
      case 'cucumber':
        return 'Pepino';
      case 'chili':
        return 'Chile';
      case 'squash':
        return 'Calabaza';
      case 'garlic':
        return 'Ajo';
      default:
        return _prettyId(cropId) ?? 'Cultivo';
    }
  }

  String? _prettyId(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((r) => '${r[0].toUpperCase()}${r.substring(1)}')
        .join(' ');
  }

  String _areaHintForUnit(YieldAreaUnit unit) {
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'Ej. 3.5';
      case YieldAreaUnit.squareMeter:
        return 'Ej. 850';
      case YieldAreaUnit.pot:
        return 'Ej. 4';
    }
  }

  double? _parsePositive(String? raw) {
    if (raw == null) return null;
    final parsed = double.tryParse(raw.trim().replaceAll(',', ''));
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  String _formatNullable(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  String _areaUnitLabelPlural(YieldAreaUnit unit) {
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'hectáreas';
      case YieldAreaUnit.squareMeter:
        return 'm²';
      case YieldAreaUnit.pot:
        return 'macetas';
    }
  }

  String? _referenceSupportBadgeLabel(YieldReference? reference) {
    if (reference == null) return null;
    return switch (reference.confidence) {
      YieldDataConfidence.validated => 'Base validada',
      YieldDataConfidence.calibrated => 'Base calibrada',
      YieldDataConfidence.modeled => 'Base modelada',
    };
  }

  String? _projectionSupportNote(YieldReference? reference) {
    if (_areaUnit == YieldAreaUnit.pot) {
      return 'La escala maceta sigue capturando base manual, pero la proyección agronómica todavía no está soportada.';
    }
    if (reference == null) {
      return null;
    }
    if (reference.cropId == CropCatalog.garlicCropId) {
      return 'Ajo se proyecta como rendimiento comercial aproximado: descuenta calibre, curado, pudricion, diente-semilla malo, mala vernalizacion, salinidad, escobeteado y sanidad. No es promesa de toneladas.';
    }
    if (reference.useType == 'seed') {
      return 'CA-07 se proyecta como semilla seca / pepita. No compares este rango con toneladas de fruto fresco.';
    }
    if (reference.useType != 'forage') {
      return null;
    }
    return switch (reference.confidence) {
      YieldDataConfidence.validated =>
        'Modo forraje con base validada para este cultivo.',
      YieldDataConfidence.calibrated =>
        'Modo forraje con base calibrada. Úsalo como aproximación productiva y no como cierre comercial.',
      YieldDataConfidence.modeled =>
        'Modo forraje con base modelada. Tómalo como rango orientativo mientras se fortalece el catálogo.',
    };
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// --- SUBCOMPONENTES DE UI ---

class _CareVisualState {
  final int percent;
  final Color careColor;
  final String careLabel;
  final LinearGradient careGradient;

  const _CareVisualState({
    required this.percent,
    required this.careColor,
    required this.careLabel,
    required this.careGradient,
  });
}

_CareVisualState _careVisualStateFor(double healthScore) {
  final int percent = (healthScore.clamp(0.0, 1.0) * 100).round();

  Color careColor = BioGTheme.brandMid;
  String careLabel = 'Bien';
  LinearGradient careGradient = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFB8D84A), Color(0xFF3FAF6E), Color(0xFF2E7D5A)],
  );

  if (percent <= 20) {
    careColor = const Color(0xFFD64545);
    careLabel = 'Crítico';
    careGradient = const LinearGradient(
      colors: [Color(0xFFFF8A8A), Color(0xFFF05B5B), Color(0xFFD64545)],
    );
  } else if (percent <= 45) {
    careColor = const Color(0xFFE08A2E);
    careLabel = 'Riesgo';
    careGradient = const LinearGradient(
      colors: [Color(0xFFFFC36A), Color(0xFFF2B34A), Color(0xFFE08A2E)],
    );
  } else if (percent <= 70) {
    careColor = const Color(0xFFB68918);
    careLabel = 'Atención';
    careGradient = const LinearGradient(
      colors: [Color(0xFFF2D06B), Color(0xFFE7B84B), Color(0xFFB68918)],
    );
  }

  return _CareVisualState(
    percent: percent,
    careColor: careColor,
    careLabel: careLabel,
    careGradient: careGradient,
  );
}

class _HeroCareImpactBar extends StatelessWidget {
  final double healthScore;
  final bool animate;

  const _HeroCareImpactBar({
    super.key,
    required this.healthScore,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final state = _careVisualStateFor(healthScore);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.94),
              ),
              const SizedBox(width: 8),
              Text(
                'Impacto del cuidado',
                style: TextStyle(
                  fontSize: 13.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.96),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black.withValues(alpha: 0.18)),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: animate ? healthScore.clamp(0.0, 1.0) : 0.0,
                    ),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutExpo,
                    builder: (context, value, child) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: state.careGradient,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${state.percent} / 100',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const Text(
                ' • ',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                ),
              ),
              Text(
                state.careLabel,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.96),
                ),
              ),
              const SizedBox(width: 7),
              Icon(Icons.circle, size: 8, color: state.careColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tu manejo real ajusta esta proyección final.',
            style: TextStyle(
              fontSize: 12.2,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Widget leading;
  final Widget? trailing;

  const _OverviewInfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      radius: BioGTheme.rCard,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: BioGTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: BioGTheme.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: BioGTheme.ink.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _HeroProjectionCard extends StatelessWidget {
  final bool hasManualBase;
  final bool isCalculated;
  final bool isProjectionSupported;
  final int animationKey;
  final String cropName;
  final double targetYieldPerUnit;
  final String yieldUnitLabel;
  final double targetTotalYield;
  final String totalUnitLabel;
  final double targetIncome;
  final double healthScore;
  final String? supportBadgeLabel;
  final String manualBaseHint;

  /// Sustantivo del producto bajo el contador (p. ej. "rendimiento aproximado"
  /// genérico; en nogal "rendimiento aproximado de nuez con cáscara").
  final String yieldNoun;

  const _HeroProjectionCard({
    super.key,
    required this.hasManualBase,
    required this.isCalculated,
    required this.isProjectionSupported,
    required this.animationKey,
    required this.cropName,
    required this.targetYieldPerUnit,
    required this.yieldUnitLabel,
    required this.targetTotalYield,
    required this.totalUnitLabel,
    required this.targetIncome,
    required this.healthScore,
    required this.manualBaseHint,
    this.supportBadgeLabel,
    this.yieldNoun = 'rendimiento aproximado',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: BioGTheme.brandGradient,
        boxShadow: BioGTheme.cardShadow(strength: 1.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Proyección de Cosecha',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$cropName • estimación inteligente',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 24),

          if (!hasManualBase) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.calculate_rounded,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Esperando datos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    manualBaseHint,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!isProjectionSupported) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Proyección por maceta próximamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Seguimos capturando tu base manual, pero todavía no estimamos rendimiento final por maceta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (hasManualBase && !isCalculated) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.rocket_launch_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Listo para calcular',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Presiona el botón inferior',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _AnimatedCounterText(
                  key: ValueKey('unit_$animationKey'),
                  targetValue: targetYieldPerUnit,
                  fontSize: 62,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 6),
                  child: Text(
                    yieldUnitLabel,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.96),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              yieldNoun,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ],

          if (hasManualBase && isProjectionSupported) ...[
            const SizedBox(height: 18),
            _HeroCareImpactBar(healthScore: healthScore, animate: true),
          ],

          if (isProjectionSupported) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _HeroStatTile(
                    label: 'Prod. Total',
                    valueWidget: isCalculated
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              _AnimatedCounterText(
                                key: ValueKey('tot_$animationKey'),
                                targetValue: targetTotalYield,
                                fontSize: 19,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  totalUnitLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                if (targetIncome > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeroStatTile(
                      label: 'Ingreso Est.',
                      valueWidget: isCalculated
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '\$',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                _AnimatedCounterText(
                                  key: ValueKey('inc_$animationKey'),
                                  targetValue: targetIncome,
                                  fontSize: 19,
                                  isCurrency: true,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'MXN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 18),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                icon: Icons.verified_rounded,
                label: hasManualBase
                    ? 'Datos aprox.'
                    : 'Captura la base manual',
              ),
              if (supportBadgeLabel != null)
                _HeroPill(
                  icon: Icons.layers_rounded,
                  label: supportBadgeLabel!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedCounterText extends StatelessWidget {
  final double targetValue;
  final double fontSize;
  final bool isCurrency;

  const _AnimatedCounterText({
    super.key,
    required this.targetValue,
    this.fontSize = 68,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetValue),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) {
        String displayValue;
        if (isCurrency) {
          displayValue = formatNumber(value, maxDecimals: 0);
        } else {
          displayValue = value.toStringAsFixed(1);
        }

        return Text(
          displayValue,
          style: TextStyle(
            fontSize: fontSize,
            height: 0.95,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: fontSize > 20 ? -1.0 : -0.5,
          ),
        );
      },
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  final String label;
  final Widget? valueWidget;

  const _HeroStatTile({super.key, required this.label, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          valueWidget ??
              const Text(
                '—',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderWithMode extends StatelessWidget {
  final String title;
  final bool showModeSelector;
  final YieldOutputMode outputMode;
  final ValueChanged<YieldOutputMode>? onModeChanged;

  const _SectionHeaderWithMode({
    super.key,
    required this.title,
    required this.showModeSelector,
    required this.outputMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final selector = showModeSelector
            ? _InlineYieldModeSelector(
                mode: outputMode,
                onChanged: onModeChanged,
              )
            : null;

        if (selector == null) {
          return _SectionLabel(title);
        }

        final bool compactRow = constraints.maxWidth >= 350;

        if (compactRow) {
          return Row(
            children: [
              Expanded(child: _SectionLabel(title)),
              const SizedBox(width: 12),
              selector,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(title),
            const SizedBox(height: 10),
            selector,
          ],
        );
      },
    );
  }
}

class _InlineYieldModeSelector extends StatelessWidget {
  final YieldOutputMode mode;
  final ValueChanged<YieldOutputMode>? onChanged;

  const _InlineYieldModeSelector({
    super.key,
    required this.mode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: disabled ? 0.65 : 1,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: BioGTheme.brandMid.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InlineYieldModeOption(
              label: 'Grano',
              selected: mode == YieldOutputMode.grain,
              onTap: disabled
                  ? null
                  : () => onChanged?.call(YieldOutputMode.grain),
            ),
            const SizedBox(width: 4),
            _InlineYieldModeOption(
              label: 'Forraje',
              selected: mode == YieldOutputMode.forage,
              onTap: disabled
                  ? null
                  : () => onChanged?.call(YieldOutputMode.forage),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineYieldModeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _InlineYieldModeOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? Colors.white : BioGTheme.teal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? BioGTheme.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.4,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
              color: fg,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineInfoText extends StatelessWidget {
  final bool ready;
  final bool isCalculated;
  final bool unsupported;
  final String? supportNote;
  final String missingTargetLabel;

  const _InlineInfoText({
    super.key,
    required this.ready,
    required this.isCalculated,
    this.unsupported = false,
    this.supportNote,
    this.missingTargetLabel = 'Semillas',
  });

  @override
  Widget build(BuildContext context) {
    final message = unsupported
        ? 'La escala maceta todavía no tiene proyección agronómica. Puedes capturar base manual, pero aún no estimamos rendimiento final por maceta.'
        : (isCalculated
              ? 'Proyección guardada. Estos datos alimentarán tus métricas y alertas.'
              : (ready
                    ? 'Listo para calcular. BIO-G usará estos datos para proyectar un rango productivo.'
                    : 'Faltan parámetros. Toca sobre "Superficie" o "$missingTargetLabel" para usar la calculadora.'));

    final icon = unsupported
        ? Icons.hourglass_top_rounded
        : (isCalculated
              ? Icons.check_circle_rounded
              : (ready
                    ? Icons.info_outline_rounded
                    : Icons.pending_actions_rounded));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BioGTheme.brandMid.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BioGTheme.brandMid.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: BioGTheme.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              supportNote == null ? message : '$message\n\n$supportNote',
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: BioGTheme.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: BioGTheme.charcoal,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ReadOnlyTag extends StatelessWidget {
  final String text;

  const _ReadOnlyTag(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: BioGTheme.brandMid.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: BioGTheme.teal,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.open_in_new_rounded,
            size: 14,
            color: BioGTheme.teal,
          ),
        ],
      ),
    );
  }
}

class _EditPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _EditPillButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: BioGTheme.brandMid.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w800,
                  color: BioGTheme.teal,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded, size: 15, color: BioGTheme.teal),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetGlyph extends StatelessWidget {
  final String assetPath;
  final double scale;
  final double size;
  final double dx;
  final double dy;

  const _AssetGlyph({
    super.key,
    required this.assetPath,
    this.scale = 1.0,
    this.size = 24,
    this.dx = 0,
    this.dy = 0,
  });

  @override
  Widget build(BuildContext context) {
    final overflowSize = size * (scale < 1 ? 1 : scale);
    return SizedBox(
      width: size,
      height: size,
      child: OverflowBox(
        alignment: Alignment.centerRight,
        minWidth: size,
        minHeight: size,
        maxWidth: overflowSize,
        maxHeight: overflowSize,
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.centerRight,
            child: Image.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
