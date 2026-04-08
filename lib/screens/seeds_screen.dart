import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/bottom_nav.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

class SeedsScreen extends StatefulWidget {
  final DateTime? sowingDate;
  final String? varietyAlias;

  final int currentIndex;
  final ValueChanged<int> onNavTap;

  const SeedsScreen({
    super.key,
    this.sowingDate,
    this.varietyAlias,
    this.currentIndex = 2,
    required this.onNavTap,
  });

  static const String routeName = '/seeds';

  @override
  State<SeedsScreen> createState() => _SeedsScreenState();
}

class _SeedsScreenState extends State<SeedsScreen>
    with SingleTickerProviderStateMixin {
  static const int _seedsTabIndex = 2;

  /// Solo vive mientras la app siga abierta.
  static bool _hasAnimatedThisSession = false;

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1280),
      value: _hasAnimatedThisSession ? 1.0 : 0.0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final bool isActiveNow = widget.currentIndex == _seedsTabIndex;

      if (isActiveNow && !_hasAnimatedThisSession) {
        _entranceController.forward(from: 0);
        _hasAnimatedThisSession = true;
      }
    });
  }

  @override
  void didUpdateWidget(covariant SeedsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool wasActiveBefore = oldWidget.currentIndex == _seedsTabIndex;
    final bool isActiveNow = widget.currentIndex == _seedsTabIndex;

    if (!wasActiveBefore && isActiveNow && !_hasAnimatedThisSession) {
      _entranceController
        ..stop()
        ..reset();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _entranceController.forward(from: 0);
        _hasAnimatedThisSession = true;
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final store = BioGScope.of(context);
    final activeDevice = store.activeDevice;
    final cropContext = store.activeCropContext;
    final seed = store.activeSeed;
    final today = DateTime.now();

    // Preload the historical crop-care average if not cached yet.
    if (activeDevice != null && cropContext != null && store.cropCareAverage == null) {
      store.loadCropCareAverage(activeDevice.id, cropContext.cropId);
    }

    final runtime = CropRuntimeResolver.resolve(
      device: activeDevice,
      seed: seed,
      cropContext: cropContext,
      live: store.live,
      alertsState: store.alertsState,
      now: today,
    );

    final String? routeVarietyAlias = SeedsScreenLogic.routeVarietyAlias(
      widgetVarietyAlias: widget.varietyAlias,
      args: args,
    );

    final DateTime? routeSowingDate = SeedsScreenLogic.routeSowingDate(
      widgetSowingDate: widget.sowingDate,
      args: args,
    );

    final String resolvedCropId = SeedsScreenLogic.resolvedCropId(
      cropContext: cropContext,
      seed: seed,
      runtimeCropKeyName: runtime.cropKeyName,
    );

    final String cropDisplayName = SeedsScreenLogic.cropDisplayName(
      cropId: resolvedCropId,
    );

    final String resolvedVarietyAlias = SeedsScreenLogic.resolvedVarietyAlias(
      cropId: resolvedCropId,
      cropContext: cropContext,
      seed: seed,
      routeVarietyAlias: routeVarietyAlias,
    );

    final DateTime? resolvedSowingDate =
        cropContext?.sowingDate ?? seed?.sowingDate ?? routeSowingDate;

    final DateTime? resolvedPlannedDate =
        cropContext?.plannedSowingDate ??
        seed?.plannedSowingDate ??
        ((routeSowingDate != null && routeSowingDate.isAfter(today))
            ? routeSowingDate
            : null);

    final bool hasConfiguredCrop = cropContext != null || seed != null;
    final bool isMaizeRuntime =
        resolvedCropId == CropCatalog.maizeCropId &&
        runtime.profile is MaizeProfile;

    final bool isGenericProfile = runtime.isGenericMode || !hasConfiguredCrop;

    final String topCardTitle = SeedsScreenLogic.topCardTitle(
      runtime: runtime,
      cropDisplayName: cropDisplayName,
      varietyAlias: resolvedVarietyAlias,
      isGenericSelection: isGenericProfile,
      hasConfiguredCrop: hasConfiguredCrop,
    );

    final String topCardIconAsset = SeedsScreenLogic.topCardIconAsset(
      runtime: runtime,
      cropId: resolvedCropId,
      isGenericSelection: isGenericProfile,
      hasConfiguredCrop: hasConfiguredCrop,
    );

    final double topCardIconScale = SeedsScreenLogic.iconScaleForAsset(
      asset: topCardIconAsset,
      cropId: resolvedCropId,
    );

    final int? cropScore = SeedsScreenLogic.resolveCropCareScore(
      store: store,
      runtimeEval: runtime.eval,
    );
    final bool hasCropCareScore = cropScore != null;
    final careState = hasCropCareScore
        ? SeedsScreenLogic.careState(cropScore ?? 0)
        : CareState.attention;
    final careLabel = hasCropCareScore
        ? SeedsScreenLogic.careLabelFromState(careState)
        : 'Sin evaluación';
    final careColor = hasCropCareScore
        ? SeedsScreenLogic.careColor(careState)
        : const Color(0xFF6F7F79);
    final String careScoreText = cropScore != null
        ? '${cropScore.clamp(0, 100)} / 100'
        : '-- / 100';

    late final String stageTitle;
    late final String statusChip;
    late final String topSubtitle;
    late final String dayPrefix;
    late final int dayValue;
    late final String daySuffix;
    late final String harvestText;
    late final String windowText;
    late final int estHeightCm;
    late final int growthCmPerWeek;
    String? heroAsset;

    if (isMaizeRuntime &&
        runtime.isPlanted &&
        runtime.stageResult != null &&
        resolvedSowingDate != null) {
      final MaizeProfile profile = runtime.profile! as MaizeProfile;
      final stageResult = runtime.stageResult!;

      final daySinceSowing = math.max(
        1,
        today.difference(resolvedSowingDate).inDays + 1,
      );

      final est = SeedsScreenLogic.estimateHeightAndGrowthCm(
        profile: profile,
        daySinceSowing: daySinceSowing,
        expectedDaysToEnd: stageResult.expectedDaysToEnd,
      );

      final windowsNow = stageResult.windowsNow
          .whereType<SeedWindowKey>()
          .toList(growable: false);

      stageTitle = stageResult.stageLabelEs;
      statusChip = 'Activo';
      topSubtitle = activeDevice?.locationName ?? 'Campo sin ubicación';
      dayPrefix = 'Día:';
      dayValue = daySinceSowing;
      daySuffix = 'desde siembra';
      harvestText = '${stageResult.expectedDaysToEnd} días';
      windowText = SeedsScreenLogic.windowsText(windowsNow);
      estHeightCm = est.heightCm;
      growthCmPerWeek = est.growthCmPerWeek;
      heroAsset = stageResult.heroAsset;
    } else if (runtime.isPlanted) {
      final int daySinceSowing = resolvedSowingDate == null
          ? 0
          : math.max(1, today.difference(resolvedSowingDate).inDays + 1);

      stageTitle = runtime.hasResolvedRuntime
          ? runtime.stageLabel
          : 'Cultivo configurado';
      statusChip = 'Activo';
      topSubtitle = activeDevice?.locationName ?? 'Seguimiento general';
      dayPrefix = resolvedSowingDate == null ? 'Estado:' : 'Día:';
      dayValue = daySinceSowing;
      daySuffix = resolvedSowingDate == null
          ? 'seguimiento fenológico pendiente'
          : 'desde siembra';
      harvestText = runtime.stageResult != null
          ? '${runtime.stageResult!.expectedDaysToEnd} días'
          : 'Pendiente';

      final windowsNow =
          runtime.stageResult?.windowsNow.whereType<SeedWindowKey>().toList(
            growable: false,
          ) ??
          const <SeedWindowKey>[];

      windowText = windowsNow.isEmpty
          ? 'Seguimiento general'
          : SeedsScreenLogic.windowsText(windowsNow);

      estHeightCm = 0;
      growthCmPerWeek = 0;
      heroAsset = runtime.stageResult?.heroAsset.trim().isNotEmpty == true
          ? runtime.stageResult!.heroAsset
          : null;
    } else if (runtime.isPlanned) {
      final plannedDate = resolvedPlannedDate ?? today;
      final daysUntil = math.max(0, plannedDate.difference(today).inDays);

      stageTitle = daysUntil == 0
          ? 'Listo para siembra'
          : 'Preparación para siembra';
      statusChip = 'Planeado';
      topSubtitle = activeDevice?.locationName ?? 'Campo en preparación';
      dayPrefix = daysUntil == 0 ? 'Hoy:' : 'Faltan:';
      dayValue = daysUntil;
      daySuffix = daysUntil == 0 ? 'siembra sugerida' : 'días para siembra';
      harvestText = 'Pendiente';
      windowText = 'Preparación / Validación';
      estHeightCm = 0;
      growthCmPerWeek = 0;
      heroAsset = null;
    } else if (hasConfiguredCrop) {
      stageTitle = 'Descanso del suelo';
      statusChip = 'Descanso';
      topSubtitle = activeDevice?.locationName ?? 'Modo básico';
      dayPrefix = 'Estado:';
      dayValue = 0;
      daySuffix = 'sin siembra activa';
      harvestText = '—';
      windowText = 'Monitoreo general';
      estHeightCm = 0;
      growthCmPerWeek = 0;
      heroAsset = null;
    } else {
      stageTitle = 'Sin cultivo configurado';
      statusChip = 'Sin cultivo';
      topSubtitle = activeDevice?.locationName ?? 'Configura un cultivo';
      dayPrefix = 'Estado:';
      dayValue = 0;
      daySuffix = 'configuración pendiente';
      harvestText = '—';
      windowText = 'Monitoreo general';
      estHeightCm = 0;
      growthCmPerWeek = 0;
      heroAsset = null;
    }

    final List<String> heroAssetCandidates =
        SeedsScreenLogic.heroAssetCandidates(
          cropId: resolvedCropId,
          primaryAsset: heroAsset,
        );

    final size = MediaQuery.of(context).size;
    final topBgHeight = (size.height * SeedsScreenLayout.topBgHeightFactor)
        .clamp(240.0, size.height);

    final panelTop = topBgHeight + SeedsScreenLayout.panelLiftPx;
    final panelBottom = panelTop + SeedsScreenLayout.panelMinHeight;
    final stackHeight =
        (math.max(topBgHeight, panelBottom) + SeedsScreenLayout.extraScrollPx)
            .clamp(240.0, 5000.0);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color.fromARGB(209, 255, 255, 255),
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          height: stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: topBgHeight,
                child: _SeedsReveal(
                  controller: _entranceController,
                  intervalStart: 0.00,
                  intervalEnd: 0.30,
                  fadeOnly: true,
                  child: _AnimatedBackgroundLayer(
                    controller: _entranceController,
                    child: IgnorePointer(
                      child: ShaderMask(
                        shaderCallback: (rect) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: const [
                              Colors.white,
                              Colors.white,
                              Colors.transparent,
                            ],
                            stops: [0.0, SeedsScreenLayout.bgFadeStart, 1.0],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ClipRect(
                          child: Transform.translate(
                            offset: const Offset(0, SeedsScreenLayout.topBgDy),
                            child: Transform.scale(
                              scale: SeedsScreenLayout.topBgScale,
                              child: Image.asset(
                                SeedsScreenLayout.bgAsset,
                                fit: BoxFit.cover,
                                alignment: SeedsScreenLayout.topBgAlignment,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: SeedsScreenLayout.topCardSide,
                right: SeedsScreenLayout.topCardSide,
                top: SeedsScreenLayout.topCardTop,
                child: _SeedsReveal(
                  controller: _entranceController,
                  intervalStart: 0.08,
                  intervalEnd: 0.28,
                  yOffset: -14,
                  xOffset: 0,
                  beginScale: 0.992,
                  child: _CompactFieldCard(
                    title: topCardTitle,
                    subtitle: topSubtitle,
                    iconAsset: topCardIconAsset,
                    iconScale: topCardIconScale,
                    titleSize: SeedsScreenLayout.topCardTitleSize,
                    subSize: SeedsScreenLayout.topCardSubSize,
                    padH: SeedsScreenLayout.topCardPadH,
                    padV: SeedsScreenLayout.topCardPadV,
                    textShadowBlur: SeedsScreenLayout.topCardTextShadowBlur,
                    textShadowOffset: SeedsScreenLayout.topCardTextShadowOffset,
                  ),
                ),
              ),
              if (heroAssetCandidates.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  top: SeedsScreenLayout.heroTopPadding,
                  height: topBgHeight - SeedsScreenLayout.heroTopPadding,
                  child: _SeedsReveal(
                    controller: _entranceController,
                    intervalStart: 0.12,
                    intervalEnd: 0.42,
                    yOffset: 28,
                    xOffset: 0,
                    beginScale: 1.035,
                    child: _AnimatedHeroLayer(
                      controller: _entranceController,
                      child: IgnorePointer(
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Transform.translate(
                              offset: const Offset(
                                SeedsScreenLayout.heroDx,
                                SeedsScreenLayout.heroDy,
                              ),
                              child: Transform.scale(
                                scale: SeedsScreenLayout.heroScale,
                                child: ShaderMask(
                                  shaderCallback: (rect) {
                                    return LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: const [
                                        Colors.white,
                                        Colors.white,
                                        Colors.transparent,
                                      ],
                                      stops: [
                                        0.0,
                                        SeedsScreenLayout.heroFadeStart,
                                        SeedsScreenLayout.heroFadeEnd,
                                      ],
                                    ).createShader(rect);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: _AssetFallbackImage(
                                    assetCandidates: heroAssetCandidates,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topCenter,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: SeedsScreenLayout.panelSide,
                right: SeedsScreenLayout.panelSide,
                top: panelTop,
                child: _SeedsReveal(
                  controller: _entranceController,
                  intervalStart: 0.24,
                  intervalEnd: 0.62,
                  yOffset: 42,
                  xOffset: 0,
                  beginScale: 0.985,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: SeedsScreenLayout.panelMinHeight,
                    ),
                    child: _StageContainerCard(
                      stageTitle: stageTitle,
                      statusChip: statusChip,
                      outerPadH: SeedsScreenLayout.stageOuterPadH,
                      outerPadV: SeedsScreenLayout.stageOuterPadV,
                      stageTitleSize: SeedsScreenLayout.stageTitleSize,
                      stageTitleMaxLines: SeedsScreenLayout.stageTitleMaxLines,
                      stageToInnerGap: SeedsScreenLayout.stageToInnerGap,
                      innerInsetSide: SeedsScreenLayout.innerInsetSide,
                      stageChipFontSize: SeedsScreenLayout.stageChipFontSize,
                      stageChipPadding: SeedsScreenLayout.stageChipPadding,
                      extraBottomSpace: SeedsScreenLayout.stageExtraBottomSpace,
                      chipDotSize: SeedsScreenLayout.chipDotSize,
                      chipDotColor: careColor.withValues(alpha: 0.90),
                      chipRevealController: _entranceController,
                      innerChild: _CareCardInner(
                        revealController: _entranceController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: SeedsScreenLayout.carePadH,
                          vertical: SeedsScreenLayout.carePadV,
                        ),
                        careScore: cropScore ?? 0,
                        careScoreText: careScoreText,
                        careLabel: careLabel,
                        careColor: careColor,
                        dayPrefix: dayPrefix,
                        dayValue: dayValue,
                        daySuffix: daySuffix,
                        harvestText: harvestText,
                        windowText: windowText,
                        progress: hasCropCareScore ? (cropScore! / 100.0) : 0.0,
                        headerSize: SeedsScreenLayout.careHeaderSize,
                        headerIconSize: SeedsScreenLayout.careHeaderIconSize,
                        scoreSize: SeedsScreenLayout.careScoreSize,
                        scoreIconSize: SeedsScreenLayout.careScoreIconSize,
                        lineLabelSize: SeedsScreenLayout.careLineLabelSize,
                        lineValueSize: SeedsScreenLayout.careLineValueSize,
                        dayNumberExtraSize:
                            SeedsScreenLayout.dayNumberExtraSize,
                        progressHeight: SeedsScreenLayout.progressHeight,
                        progressRadius: SeedsScreenLayout.progressRadius,
                        progressBgOpacity: SeedsScreenLayout.progressBgOpacity,
                        barGradient: SeedsScreenLogic.careGradient(careState),
                        estHeightCm: estHeightCm,
                        growthCmPerWeek: growthCmPerWeek,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BioGBottomNav(
        currentIndex: widget.currentIndex,
        onTap: widget.onNavTap,
      ),
    );
  }
}

class SeedsScreenLayout {
  static const String genericPlantIconAsset =
      'assets/icons/wizard/ic_planta_generica.png';
  static const double genericPlantIconScale = 3.0;

  static const String maizeIconAsset = 'assets/icons/wizard/ic_maiz.png';
  static const double maizeIconScale = 2.5;

  static const String beanIconAsset = 'assets/icons/wizard/ic_frijol.png';
  static const double beanIconScale = 2.55;

  static const String wheatIconAsset = 'assets/icons/wizard/ic_trigo.png';
  static const double wheatIconScale = 2.65;

  static const String barleyIconAsset = 'assets/icons/wizard/ic_cebada.png';
  static const double barleyIconScale = 2.65;

  static const String oatIconAsset = 'assets/icons/wizard/ic_avena.png';
  static const double oatIconScale = 2.65;

  static const String bgAsset = 'assets/images/bg_image_seeds.png';
  static const double topBgHeightFactor = 1.0;
  static const double topBgDy = -20;
  static const double topBgScale = 1.0;
  static const Alignment topBgAlignment = Alignment.topCenter;
  static const double bgFadeStart = 0.70;

  static const double heroScale = 1.4;
  static const double heroDx = 0;
  static const double heroDy = 60;
  static const double heroTopPadding = 70;
  static const double heroFadeStart = 0.55;
  static const double heroFadeEnd = 0.95;

  static const double topCardSide = 14;
  static const double topCardTop = 82;
  static const double topCardPadH = 12;
  static const double topCardPadV = 10;
  static const double topCardTitleSize = 16;
  static const double topCardSubSize = 13;
  static const double topCardTextShadowBlur = 10;
  static const Offset topCardTextShadowOffset = Offset(0, 2);

  static const double panelSide = 4;
  static const double panelLiftPx = -350;
  static const double panelMinHeight = 380;

  static const double stageOuterPadH = 2;
  static const double stageOuterPadV = 2;

  static const double stageTitleSize = 15;
  static const int stageTitleMaxLines = 1;

  static const double stageChipFontSize = 13;
  static const EdgeInsets stageChipPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );

  static const double stageToInnerGap = 6;
  static const double innerInsetSide = 0;
  static const double stageExtraBottomSpace = 100;

  static const double carePadH = 2;
  static const double carePadV = 8;

  static const double careHeaderSize = 16;
  static const double careHeaderIconSize = 20;

  static const double careScoreSize = 16;
  static const double careScoreIconSize = 18;

  static const double careLineLabelSize = 15;
  static const double careLineValueSize = 15;

  static const double dayNumberExtraSize = 4;

  static const double progressHeight = 10;
  static const double progressRadius = 999;
  static const double progressBgOpacity = 0.10;

  static const double chipDotSize = 8;

  static const double extraScrollPx = 80;
}

class SeedsScreenLogic {
  static int? resolveCropCareScore({
    required BioGStore store,
    AgroEvalResult? runtimeEval,
  }) {
    // Prefer the historical lifetime average from Supabase.
    final double? historicalAvg = store.cropCareAverage;
    if (historicalAvg != null) {
      return (historicalAvg * 100).round().clamp(0, 100);
    }

    // Fallback: use today's score while the average loads.
    final eval = runtimeEval ?? store.lastAgroEval;
    if (eval == null) return null;

    final score = (eval.soilControlScore01 * 100).round();
    return score.clamp(0, 100).toInt();
  }

  static String? routeVarietyAlias({
    required String? widgetVarietyAlias,
    required Object? args,
  }) {
    if (widgetVarietyAlias != null && widgetVarietyAlias.trim().isNotEmpty) {
      return widgetVarietyAlias.trim();
    }

    if (args is SeedsScreenArgs && args.varietyAlias.trim().isNotEmpty) {
      return args.varietyAlias.trim();
    }

    if (args is Map) {
      final dynamic raw = args['varietyAlias'];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }

    return null;
  }

  static DateTime? routeSowingDate({
    required DateTime? widgetSowingDate,
    required Object? args,
  }) {
    if (widgetSowingDate != null) return widgetSowingDate;

    if (args is SeedsScreenArgs) return args.sowingDate;

    if (args is Map) {
      final dynamic raw = args['sowingDate'];
      if (raw is DateTime) return raw;
    }

    return null;
  }

  static String resolvedCropId({
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
    required String runtimeCropKeyName,
  }) {
    final raw =
        cropContext?.cropId ??
        seed?.cropKey ??
        (runtimeCropKeyName.trim().isNotEmpty ? runtimeCropKeyName : null);

    return CropCatalog.canonicalCropKeyOrNull(raw) ?? '';
  }

  static String cropDisplayName({required String cropId}) {
    final catalog = CropCatalog.cropById(cropId);
    if (catalog != null) return catalog.label;

    switch (cropId) {
      case 'maize':
        return 'Maíz';
      case 'bean':
        return 'Frijol';
      case 'wheat':
        return 'Trigo';
      case 'barley':
        return 'Cebada';
      case 'oat':
        return 'Avena';
      case '':
        return 'Cultivo';
      default:
        return 'Cultivo';
    }
  }

  static String resolvedVarietyAlias({
    required String cropId,
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
    required String? routeVarietyAlias,
  }) {
    if (cropId.isNotEmpty) {
      final variety = CropCatalog.varietyByAny(
        cropId,
        cropContext?.varietyId ??
            cropContext?.varietyAlias ??
            seed?.varietyAlias ??
            routeVarietyAlias,
      );
      if (variety != null) {
        return variety.label;
      }
    }

    final alias =
        cropContext?.varietyAlias ?? seed?.varietyAlias ?? routeVarietyAlias;

    final normalized = alias?.trim();
    if (normalized == null || normalized.isEmpty) return '';

    return normalized;
  }

  static bool isGenericSelection({
    required String cropId,
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
    required CropRuntimeSnapshot runtime,
    required String fallbackVarietyAlias,
    required bool hasConfiguredCrop,
  }) {
    if (!hasConfiguredCrop) return true;
    if (runtime.isFallowMode) return true;
    if (cropId.isEmpty) return true;

    final String? rawVarietyValue =
        cropContext?.varietyId ??
        cropContext?.varietyAlias ??
        seed?.varietyAlias ??
        fallbackVarietyAlias;

    final variety = CropCatalog.varietyByAny(cropId, rawVarietyValue);
    if (variety != null) {
      return variety.isGeneric;
    }

    final alias =
        (cropContext?.varietyAlias ??
                seed?.varietyAlias ??
                fallbackVarietyAlias)
            .trim()
            .toLowerCase();

    if (alias.isNotEmpty) {
      return CropCatalog.isGenericAlias(alias) || alias.startsWith('generic_');
    }

    final profile = CropCatalog.profileByAny(
      cropId,
      cropContext?.profileId ?? seed?.profileId,
    );
    if (profile != null) {
      return CropCatalog.isGenericProfileId(profile.id);
    }

    return false;
  }

  static String topCardTitle({
    required CropRuntimeSnapshot runtime,
    required String cropDisplayName,
    required String varietyAlias,
    required bool isGenericSelection,
    required bool hasConfiguredCrop,
  }) {
    if (!hasConfiguredCrop) {
      return 'Sin cultivo configurado';
    }

    if (runtime.isFallowMode) {
      return 'Descanso del suelo';
    }

    if (isGenericSelection) {
      return '$cropDisplayName – Perfil genérico';
    }

    final normalizedVariety = varietyAlias.trim();
    if (normalizedVariety.isNotEmpty) {
      return '$cropDisplayName – $normalizedVariety';
    }

    return cropDisplayName;
  }

  static String topCardIconAsset({
    required CropRuntimeSnapshot runtime,
    required String cropId,
    required bool isGenericSelection,
    required bool hasConfiguredCrop,
  }) {
    if (!hasConfiguredCrop || runtime.isFallowMode) {
      return SeedsScreenLayout.genericPlantIconAsset;
    }

    if (runtime.cropIconAsset.trim().isNotEmpty &&
        runtime.cropIconAsset != SeedsScreenLayout.genericPlantIconAsset) {
      return runtime.cropIconAsset;
    }

    if (isGenericSelection) {
      switch (cropId) {
        case CropCatalog.maizeCropId:
          return SeedsScreenLayout.maizeIconAsset;
        case CropCatalog.beanCropId:
          return SeedsScreenLayout.beanIconAsset;
        case CropCatalog.wheatCropId:
          return SeedsScreenLayout.wheatIconAsset;
        case CropCatalog.barleyCropId:
          return SeedsScreenLayout.barleyIconAsset;
        case CropCatalog.oatCropId:
          return SeedsScreenLayout.oatIconAsset;
        default:
          return SeedsScreenLayout.genericPlantIconAsset;
      }
    }

    switch (cropId) {
      case CropCatalog.maizeCropId:
        return SeedsScreenLayout.maizeIconAsset;
      case CropCatalog.beanCropId:
        return SeedsScreenLayout.beanIconAsset;
      case CropCatalog.wheatCropId:
        return SeedsScreenLayout.wheatIconAsset;
      case CropCatalog.barleyCropId:
        return SeedsScreenLayout.barleyIconAsset;
      case CropCatalog.oatCropId:
        return SeedsScreenLayout.oatIconAsset;
      default:
        return SeedsScreenLayout.genericPlantIconAsset;
    }
  }

  static double iconScaleForAsset({
    required String asset,
    required String cropId,
  }) {
    if (asset == SeedsScreenLayout.maizeIconAsset ||
        cropId == CropCatalog.maizeCropId) {
      return SeedsScreenLayout.maizeIconScale;
    }

    if (asset == SeedsScreenLayout.beanIconAsset ||
        cropId == CropCatalog.beanCropId) {
      return SeedsScreenLayout.beanIconScale;
    }

    if (asset == SeedsScreenLayout.wheatIconAsset ||
        cropId == CropCatalog.wheatCropId) {
      return SeedsScreenLayout.wheatIconScale;
    }

    if (asset == SeedsScreenLayout.barleyIconAsset ||
        cropId == CropCatalog.barleyCropId) {
      return SeedsScreenLayout.barleyIconScale;
    }

    if (asset == SeedsScreenLayout.oatIconAsset ||
        cropId == CropCatalog.oatCropId) {
      return SeedsScreenLayout.oatIconScale;
    }

    return SeedsScreenLayout.genericPlantIconScale;
  }

  static List<String> heroAssetCandidates({
    required String cropId,
    required String? primaryAsset,
  }) {
    final out = <String>[];

    void add(String? asset) {
      final normalized = asset?.trim();
      if (normalized == null || normalized.isEmpty) return;
      if (!out.contains(normalized)) {
        out.add(normalized);
      }
    }

    add(primaryAsset);
    if (primaryAsset == null || primaryAsset.trim().isEmpty) {
      return out;
    }

    if (cropId == CropCatalog.beanCropId) {
      final variants = <String>{primaryAsset.trim()};

      for (final candidate in List<String>.from(variants)) {
        variants.add(
          candidate.replaceAll('assets/seeds/bean/', 'assets/seeds/Bean/'),
        );
        variants.add(
          candidate.replaceAll('assets/seeds/Bean/', 'assets/seeds/bean/'),
        );
      }

      for (final candidate in List<String>.from(variants)) {
        variants.add(
          candidate.replaceAll(
            'bean_stage_tasseling.png',
            'bean_stage_flower_set.png',
          ),
        );
        variants.add(
          candidate.replaceAll(
            'bean_stage_veg_advanced.png',
            'bean_stage_maturity_senescence.png',
          ),
        );
        variants.add(
          candidate.replaceAll(
            'bean_stage_grain_fill.png',
            'bean_stage_maturity_senescence.png',
          ),
        );
      }

      for (final candidate in variants) {
        add(candidate);
      }
    }

    if (cropId == CropCatalog.oatCropId) {
      final variants = <String>{primaryAsset.trim()};

      for (final candidate in List<String>.from(variants)) {
        variants.add(
          candidate.replaceAll('assets/seeds/Oat/', 'assets/seeds/oat/'),
        );
        variants.add(
          candidate.replaceAll('assets/seeds/oat/', 'assets/seeds/Oat/'),
        );
      }

      for (final candidate in List<String>.from(variants)) {
        variants.add(
          candidate.replaceAll(
            'oat_stage_tasseling.png',
            'oat_stage_flower_set.png',
          ),
        );
        variants.add(
          candidate.replaceAll(
            'oat_stage_veg_advanced.png',
            'oat_stage_elongation.png',
          ),
        );
      }

      for (final candidate in variants) {
        add(candidate);
      }
    }

    if (cropId == CropCatalog.wheatCropId ||
        cropId == CropCatalog.barleyCropId) {
      final variants = <String>{primaryAsset.trim()};

      for (final candidate in List<String>.from(variants)) {
        variants.add(
          candidate.replaceAll('_stage_veg.png', '_stage_veg_early.png'),
        );
        variants.add(
          candidate.replaceAll('_stage_flowering.png', '_stage_heading.png'),
        );
        variants.add(
          candidate.replaceAll('_stage_maturity.png', '_stage_grain_fill.png'),
        );
        variants.add(
          candidate.replaceAll(
            '_stage_maturity.png',
            '_stage_physiological_maturity.png',
          ),
        );
      }

      for (final candidate in variants) {
        add(candidate);
      }
    }

    return out;
  }

  static CareState careState(int score) {
    final s = score.clamp(0, 100);
    if (s <= 20) return CareState.critical;
    if (s <= 45) return CareState.warning;
    if (s <= 70) return CareState.attention;
    return CareState.good;
  }

  static String careLabelFromState(CareState state) {
    switch (state) {
      case CareState.good:
        return 'Bien';
      case CareState.attention:
        return 'Atención';
      case CareState.warning:
        return 'Riesgo';
      case CareState.critical:
        return 'Crítico';
    }
  }

  static Color careColor(CareState state) {
    switch (state) {
      case CareState.good:
        return const Color(0xFF2E7D5A);
      case CareState.attention:
        return const Color(0xFFB68918);
      case CareState.warning:
        return const Color(0xFFE08A2E);
      case CareState.critical:
        return const Color(0xFFD64545);
    }
  }

  static LinearGradient careGradient(CareState state) {
    switch (state) {
      case CareState.good:
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFB8D84A), Color(0xFF3FAF6E), Color(0xFF2E7D5A)],
        );
      case CareState.attention:
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF2D06B), Color(0xFFE7B84B), Color(0xFFB68918)],
        );
      case CareState.warning:
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFC36A), Color(0xFFF2B34A), Color(0xFFE08A2E)],
        );
      case CareState.critical:
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFF8A8A), Color(0xFFF05B5B), Color(0xFFD64545)],
        );
    }
  }

  static String windowsText(List<SeedWindowKey> windows) {
    final parts = <String>[];
    if (windows.contains(SeedWindowKey.irrigation)) parts.add('Riego');
    if (windows.contains(SeedWindowKey.nutrition)) parts.add('Nutrientes');
    if (windows.contains(SeedWindowKey.scouting)) parts.add('Monitoreo');
    if (windows.contains(SeedWindowKey.critical)) parts.add('Crítica');
    return parts.isEmpty ? '—' : parts.join(' / ');
  }

  static _Estimation estimateHeightAndGrowthCm({
    required MaizeProfile profile,
    required int daySinceSowing,
    required int expectedDaysToEnd,
  }) {
    final totalCycleDays = daySinceSowing + expectedDaysToEnd;
    if (totalCycleDays <= 0) {
      return const _Estimation(heightCm: 0, growthCmPerWeek: 0);
    }

    final p = (daySinceSowing / totalCycleDays).clamp(0.0, 1.0);

    // S-curve (smoothstep): slow start, rapid mid-growth, plateau at maturity.
    double sCurve(double x) => x * x * (3.0 - 2.0 * x);

    final avgMaxM = (profile.plantHeightM.min + profile.plantHeightM.max) / 2;
    final nowM = avgMaxM * sCurve(p);

    final prevDay = (daySinceSowing - 7).clamp(1, 1000000);
    final pp = (prevDay / totalCycleDays).clamp(0.0, 1.0);
    final prevM = avgMaxM * sCurve(pp);

    final heightCm = (nowM * 100).round();
    final growthWeekCm = ((nowM - prevM) * 100).round();

    return _Estimation(heightCm: heightCm, growthCmPerWeek: growthWeekCm);
  }
}

class _Estimation {
  final int heightCm;
  final int growthCmPerWeek;

  const _Estimation({required this.heightCm, required this.growthCmPerWeek});
}

enum CareState { good, attention, warning, critical }

class SeedsScreenArgs {
  final DateTime sowingDate;
  final String varietyAlias;

  const SeedsScreenArgs({required this.sowingDate, required this.varietyAlias});
}

class _AssetFallbackImage extends StatefulWidget {
  final List<String> assetCandidates;
  final BoxFit fit;
  final Alignment alignment;

  const _AssetFallbackImage({
    required this.assetCandidates,
    required this.fit,
    required this.alignment,
  });

  @override
  State<_AssetFallbackImage> createState() => _AssetFallbackImageState();
}

class _AssetFallbackImageState extends State<_AssetFallbackImage> {
  int _assetIndex = 0;
  bool _queuedAdvance = false;

  @override
  Widget build(BuildContext context) {
    if (widget.assetCandidates.isEmpty ||
        _assetIndex >= widget.assetCandidates.length) {
      return const SizedBox.shrink();
    }

    final asset = widget.assetCandidates[_assetIndex];

    return Image.asset(
      asset,
      fit: widget.fit,
      alignment: widget.alignment,
      errorBuilder: (context, error, stackTrace) {
        if (!_queuedAdvance &&
            _assetIndex < widget.assetCandidates.length - 1) {
          _queuedAdvance = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _assetIndex += 1;
              _queuedAdvance = false;
            });
          });
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SeedsReveal extends StatelessWidget {
  final AnimationController controller;
  final double intervalStart;
  final double intervalEnd;
  final double yOffset;
  final double xOffset;
  final double beginScale;
  final bool fadeOnly;
  final Widget child;

  const _SeedsReveal({
    required this.controller,
    required this.intervalStart,
    required this.intervalEnd,
    required this.child,
    this.yOffset = 18,
    this.xOffset = 0,
    this.beginScale = 0.988,
    this.fadeOnly = false,
  });

  static const Curve _positionCurve = Cubic(0.20, 0.92, 0.28, 1.0);
  static const Curve _opacityCurve = Cubic(0.16, 0.84, 0.24, 1.0);

  @override
  Widget build(BuildContext context) {
    final motion = CurvedAnimation(
      parent: controller,
      curve: Interval(intervalStart, intervalEnd, curve: _positionCurve),
    );

    final opacityMotion = CurvedAnimation(
      parent: controller,
      curve: Interval(
        intervalStart,
        intervalStart + ((intervalEnd - intervalStart) * 0.78),
        curve: _opacityCurve,
      ),
    );

    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(opacityMotion);
    final translateY = Tween<double>(begin: yOffset, end: 0.0).animate(motion);
    final translateX = Tween<double>(begin: xOffset, end: 0.0).animate(motion);
    final scale = Tween<double>(begin: beginScale, end: 1.0).animate(motion);

    if (fadeOnly) {
      return FadeTransition(opacity: opacity, child: child);
    }

    return FadeTransition(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(translateX.value, translateY.value),
            child: Transform.scale(
              scale: scale.value,
              alignment: Alignment.topCenter,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedBackgroundLayer extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const _AnimatedBackgroundLayer({
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final motion = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.00, 0.55, curve: Cubic(0.22, 0.84, 0.22, 1.0)),
    );

    final scale = Tween<double>(begin: 1.045, end: 1.0).animate(motion);
    final dy = Tween<double>(begin: -8.0, end: 0.0).animate(motion);

    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, dy.value),
          child: Transform.scale(
            scale: scale.value,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
    );
  }
}

class _AnimatedHeroLayer extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const _AnimatedHeroLayer({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    final motion = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.10, 0.62, curve: Cubic(0.20, 0.88, 0.22, 1.0)),
    );

    final extraScale = Tween<double>(begin: 1.05, end: 1.0).animate(motion);
    final dy = Tween<double>(begin: 14.0, end: 0.0).animate(motion);

    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, dy.value),
          child: Transform.scale(
            scale: extraScale.value,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
    );
  }
}

class _CompactFieldCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconAsset;
  final double iconScale;
  final double titleSize;
  final double subSize;
  final double padH;
  final double padV;
  final double textShadowBlur;
  final Offset textShadowOffset;

  const _CompactFieldCard({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.iconScale,
    required this.titleSize,
    required this.subSize,
    required this.padH,
    required this.padV,
    required this.textShadowBlur,
    required this.textShadowOffset,
  });

  @override
  Widget build(BuildContext context) {
    final shadow = [
      Shadow(
        blurRadius: textShadowBlur,
        offset: textShadowOffset,
        color: Colors.black.withValues(alpha: 0.18),
      ),
    ];

    return BioGGlassCard(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: Transform.scale(
                  scale: iconScale,
                  child: Image.asset(
                    iconAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      shadows: shadow,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: subSize,
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                      shadows: shadow,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black54,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _StageContainerCard extends StatelessWidget {
  final String stageTitle;
  final String statusChip;

  final double outerPadH;
  final double outerPadV;

  final double stageTitleSize;
  final int stageTitleMaxLines;

  final double stageToInnerGap;
  final double innerInsetSide;

  final double stageChipFontSize;
  final EdgeInsets stageChipPadding;

  final double extraBottomSpace;

  final double chipDotSize;
  final Color chipDotColor;

  final AnimationController chipRevealController;

  final Widget innerChild;

  const _StageContainerCard({
    required this.stageTitle,
    required this.statusChip,
    required this.outerPadH,
    required this.outerPadV,
    required this.stageTitleSize,
    required this.stageTitleMaxLines,
    required this.stageToInnerGap,
    required this.innerInsetSide,
    required this.stageChipFontSize,
    required this.stageChipPadding,
    required this.extraBottomSpace,
    required this.chipDotSize,
    required this.chipDotColor,
    required this.chipRevealController,
    required this.innerChild,
  });

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          outerPadH,
          outerPadV,
          outerPadH,
          outerPadV + extraBottomSpace,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stageTitle,
                    maxLines: stageTitleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: stageTitleSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _PillChipDot(
                  text: statusChip,
                  fontSize: stageChipFontSize,
                  padding: stageChipPadding,
                  dotSize: chipDotSize,
                  dotColor: chipDotColor,
                  revealController: chipRevealController,
                ),
              ],
            ),
            SizedBox(height: stageToInnerGap),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: innerInsetSide),
              child: innerChild,
            ),
          ],
        ),
      ),
    );
  }
}

class _CareCardInner extends StatelessWidget {
  final AnimationController revealController;
  final EdgeInsets padding;

  final int careScore;
  final String careScoreText;
  final String careLabel;
  final Color careColor;

  final String dayPrefix;
  final int dayValue;
  final String daySuffix;

  final String harvestText;
  final String windowText;
  final double progress;

  final double headerSize;
  final double headerIconSize;

  final double scoreSize;
  final double scoreIconSize;

  final double lineLabelSize;
  final double lineValueSize;

  final double dayNumberExtraSize;

  final double progressHeight;
  final double progressRadius;
  final double progressBgOpacity;

  final LinearGradient barGradient;

  final int estHeightCm;
  final int growthCmPerWeek;

  const _CareCardInner({
    required this.revealController,
    required this.padding,
    required this.careScore,
    required this.careScoreText,
    required this.careLabel,
    required this.careColor,
    required this.dayPrefix,
    required this.dayValue,
    required this.daySuffix,
    required this.harvestText,
    required this.windowText,
    required this.progress,
    required this.headerSize,
    required this.headerIconSize,
    required this.scoreSize,
    required this.scoreIconSize,
    required this.lineLabelSize,
    required this.lineValueSize,
    required this.dayNumberExtraSize,
    required this.progressHeight,
    required this.progressRadius,
    required this.progressBgOpacity,
    required this.barGradient,
    required this.estHeightCm,
    required this.growthCmPerWeek,
  });

  @override
  Widget build(BuildContext context) {
    final growthStr = growthCmPerWeek == 0 ? '—' : '+$growthCmPerWeek cm/sem';
    final heightStr = estHeightCm <= 0 ? '—' : '$estHeightCm cm';

    return BioGGlassCard(
      child: Padding(
        padding: padding,
        child: _SeedsReveal(
          controller: revealController,
          intervalStart: 0.40,
          intervalEnd: 0.82,
          yOffset: 16,
          xOffset: 0,
          beginScale: 0.992,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: headerIconSize,
                    color: careColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cuidado del cultivo',
                    style: TextStyle(
                      fontSize: headerSize,
                      fontWeight: FontWeight.w900,
                      color: careColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _GradientProgressBar(
                value: progress.clamp(0.0, 1.0),
                height: progressHeight,
                radius: progressRadius,
                backgroundOpacity: progressBgOpacity,
                gradient: barGradient,
                revealController: revealController,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    careScoreText,
                    style: TextStyle(
                      fontSize: scoreSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    ' – ',
                    style: TextStyle(
                      fontSize: scoreSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    careLabel,
                    style: TextStyle(
                      fontSize: scoreSize,
                      fontWeight: FontWeight.w900,
                      color: careColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.circle, size: 10, color: careColor),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    dayPrefix,
                    style: TextStyle(
                      fontSize: lineLabelSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$dayValue',
                    style: TextStyle(
                      fontSize: lineValueSize + dayNumberExtraSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      daySuffix,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: lineValueSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _LineRow(
                label: 'Estimado a cosecha:',
                value: harvestText,
                labelSize: lineLabelSize,
                valueSize: lineValueSize,
                valueColor: const Color(0xFF2E7D5A),
                valueBold: true,
              ),
              const SizedBox(height: 8),
              _LineRow(
                label: 'Ventana actual:',
                value: windowText,
                labelSize: lineLabelSize,
                valueSize: lineValueSize,
                valueColor: const Color(0xFF2E7D5A),
                valueBold: true,
              ),
              const SizedBox(height: 8),
              _LineRow(
                label: 'Altura estimada:',
                value: heightStr,
                labelSize: lineLabelSize,
                valueSize: lineValueSize,
                valueColor: const Color(0xFF2E7D5A),
                valueBold: true,
              ),
              const SizedBox(height: 8),
              _LineRow(
                label: 'Crecimiento:',
                value: growthStr,
                labelSize: lineLabelSize,
                valueSize: lineValueSize,
                valueColor: const Color(0xFF2E7D5A),
                valueBold: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final double radius;
  final double backgroundOpacity;
  final LinearGradient gradient;
  final AnimationController revealController;

  const _GradientProgressBar({
    required this.value,
    required this.height,
    required this.radius,
    required this.backgroundOpacity,
    required this.gradient,
    required this.revealController,
  });

  @override
  Widget build(BuildContext context) {
    final widthFactor = CurvedAnimation(
      parent: revealController,
      curve: const Interval(0.52, 0.92, curve: Cubic(0.22, 1.0, 0.36, 1.0)),
    );

    return AnimatedBuilder(
      animation: revealController,
      builder: (context, _) {
        final animatedValue = value.clamp(0.0, 1.0) * widthFactor.value;

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.black.withValues(alpha: backgroundOpacity),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: animatedValue.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(gradient: gradient),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PillChipDot extends StatelessWidget {
  final String text;
  final double fontSize;
  final EdgeInsets padding;
  final double dotSize;
  final Color dotColor;
  final AnimationController revealController;

  const _PillChipDot({
    required this.text,
    required this.fontSize,
    required this.padding,
    required this.dotSize,
    required this.dotColor,
    required this.revealController,
  });

  @override
  Widget build(BuildContext context) {
    final scaleMotion = CurvedAnimation(
      parent: revealController,
      curve: const Interval(0.34, 0.62, curve: Cubic(0.20, 0.95, 0.28, 1.0)),
    );

    final fadeMotion = CurvedAnimation(
      parent: revealController,
      curve: const Interval(0.30, 0.52, curve: Curves.easeOut),
    );

    final scale = Tween<double>(begin: 0.92, end: 1.0).animate(scaleMotion);
    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(fadeMotion);

    return AnimatedBuilder(
      animation: revealController,
      builder: (context, _) {
        return Opacity(
          opacity: opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale.value,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: const Color(0xFFF4E7B5).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      fontSize: fontSize,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LineRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelSize;
  final double valueSize;
  final Color? valueColor;
  final bool valueBold;

  const _LineRow({
    required this.label,
    required this.value,
    required this.labelSize,
    required this.valueSize,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final vStyle = TextStyle(
      fontSize: valueSize,
      fontWeight: valueBold ? FontWeight.w900 : FontWeight.w700,
      color: valueColor ?? Colors.black87,
    );

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: vStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
