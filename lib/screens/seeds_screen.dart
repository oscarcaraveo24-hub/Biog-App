import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_cycle_display_resolver.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/tree_profile_presentation.dart';
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
    if (activeDevice != null &&
        cropContext != null &&
        store.cropCareAverage == null) {
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
    final bool isTreeRuntime =
        isTreeContext(cropContext) ||
        isTreeCrop(
          cropId: resolvedCropId,
          cropCategoryId: cropContext?.cropCategoryId,
        );
    // Ornamental (cactus, suculenta…): cultivo NO cíclico, sin cosecha.
    final bool isOrnamentalRuntime =
        isEstablishmentMaintenanceContext(cropContext) ||
        isEstablishmentMaintenanceCrop(cropId: resolvedCropId);
    final String? ornamentalCropId =
        ornamentalCropIdOrNull(cropContext?.cropId) ??
        ornamentalCropIdOrNull(resolvedCropId);

    final bool isGenericProfile = runtime.isGenericMode || !hasConfiguredCrop;

    final String topCardTitle = SeedsScreenLogic.topCardTitle(
      runtime: runtime,
      cropId: resolvedCropId,
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
    late final String harvestLabel;
    late final String harvestText;
    late final String windowText;
    late final int estHeightCm;
    late final int growthCmPerWeek;
    String? heroAsset;
    String? dayValueText;
    bool showGrowthRows = true;
    // Etiqueta de la fila de ventana. Los cultivos cíclicos hablan de "ventana"
    // (floración, llenado…); el cactus no tiene ventanas de ciclo, así que la
    // fila se reutiliza para la prioridad de cuidado.
    String windowLabel = 'Ventana actual:';

    // Ornamental: mismo patrón que el árbol (cultivo NO cíclico). Sin cosecha ni
    // rendimiento, pero CON los mismos datos vivos que frijol: etapa resuelta,
    // día desde la plantación, cuidado y prioridad.
    if (isOrnamentalRuntime &&
        (runtime.isPlanted || runtime.isPlanned) &&
        cropContext != null) {
      // La etapa se toma del RUNTIME RESUELTO, no del campo crudo del contexto.
      // Leer `cropContext.ornamentalStageId` a pelo era el bug: un contexto
      // guardado con 'unknown' dejaba la pantalla clavada en "Etapa por
      // confirmar" aunque el usuario hubiera dado la fecha. El resolver, además,
      // se auto-repara.
      final String stageId = normalizeOrnamentalStageId(
        ornamentalCropId,
        runtime.stageResult?.stageKey ?? cropContext.ornamentalStageId,
      );
      final String? criticalLabel = ornamentalCriticalWindowLabel(
        ornamentalCropId,
        stageId,
      );
      final int? daysSincePlanting = runtime.stageResult?.daySinceSowing;

      stageTitle = ornamentalStageDisplayName(ornamentalCropId, stageId);
      statusChip = runtime.isPlanned
          ? 'Planeado'
          : criticalLabel != null
          ? 'Ventana activa'
          : ornamentalCropDisplayName(ornamentalCropId);
      topSubtitle = activeDevice?.locationName ?? 'Monitoreo continuo';

      if (runtime.isPlanned) {
        dayPrefix = 'Estado:';
        dayValue = 0;
        dayValueText = 'Pendiente';
        daySuffix = 'aún no la plantas';
      } else if (daysSincePlanting != null) {
        // Igual que frijol: "Día: 72 desde que la plantaste".
        dayPrefix = 'Día:';
        dayValue = math.max(1, daysSincePlanting);
        dayValueText = null;
        daySuffix = 'desde que la plantaste';
      } else {
        dayPrefix = 'Estado:';
        dayValue = 0;
        dayValueText = 'Activo';
        daySuffix = 'sin fecha de plantación';
      }

      harvestLabel = 'Cuidado:';
      harvestText = ornamentalStageCareNoteEs(ornamentalCropId, stageId);
      windowLabel = 'Prioridad:';
      windowText =
          criticalLabel ??
          ornamentalStagePriorityText(ornamentalCropId, stageId);
      estHeightCm = 0;
      growthCmPerWeek = 0;
      heroAsset = runtime.stageResult?.heroAsset.trim().isNotEmpty == true
          ? runtime.stageResult!.heroAsset
          : ornamentalStageImage(ornamentalCropId, stageId);
      showGrowthRows = false;
    } else if (isTreeRuntime && runtime.isPlanted && cropContext != null) {
      final String stageId = normalizeTreeStageId(cropContext.phenologyStageId);
      final String? criticalLabel = treeCriticalWindowLabel(stageId);

      stageTitle = treeStageDisplayNameForCrop(cropContext.cropId, stageId);
      statusChip = criticalLabel != null ? 'Ventana activa' : 'Perenne';
      topSubtitle = activeDevice?.locationName ?? 'Monitoreo continuo';
      dayPrefix = 'Estado:';
      dayValue = 0;
      dayValueText = 'Activo';
      daySuffix = treeStateDisplayName(cropContext.perennialStateId);
      harvestLabel = 'Rendimiento aprox.:';
      harvestText = 'Monitoreo continuo';
      windowText = criticalLabel ?? treeStagePriorityText(stageId);
      estHeightCm = 0;
      growthCmPerWeek = 0;
      heroAsset = runtime.stageResult?.heroAsset.trim().isNotEmpty == true
          ? runtime.stageResult!.heroAsset
          : 'assets/icons/wizard/ic_tree.png';
      showGrowthRows = false;
    } else if (isMaizeRuntime &&
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
      final maizeCycleLine = resolveCycleDisplayLine(
        cropId: resolvedCropId,
        profileId: runtime.effectiveProfileId,
        stageKey: stageResult.stageKey,
        stageLabel: stageResult.stageLabelEs,
        expectedDaysToEnd: stageResult.expectedDaysToEnd,
      );
      harvestLabel = maizeCycleLine.label;
      harvestText = maizeCycleLine.value;
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
      final cycleLine = resolveCycleDisplayLine(
        cropId: resolvedCropId,
        profileId: runtime.effectiveProfileId,
        stageKey: runtime.stageResult?.stageKey,
        stageLabel: runtime.stageResult?.stageLabelEs ?? runtime.stageLabel,
        expectedDaysToEnd: runtime.stageResult?.expectedDaysToEnd,
      );
      harvestLabel = cycleLine.label;
      harvestText = cycleLine.value;

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
      harvestLabel = 'Estimado a cosecha:';
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
      harvestLabel = 'Seguimiento:';
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
      harvestLabel = 'Seguimiento:';
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

    // Fondo + posicion resueltos por cultivo (cebolla usa onionBg*).
    final bgSpec = SeedsScreenLayout.backgroundSpecForCrop(resolvedCropId);

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
                        child: ClipRect(child: _SeedsBgContent(spec: bgSpec)),
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
                        dayValueText: dayValueText,
                        daySuffix: daySuffix,
                        harvestLabel: harvestLabel,
                        harvestText: harvestText,
                        windowLabel: windowLabel,
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
                        showGrowthRows: showGrowthRows,
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

/// Fondo de SeedsScreen: asset + transform. Permite posicionar cada fondo
/// (por ejemplo el de cebolla) de forma independiente del resto.
class SeedsBackgroundSpec {
  const SeedsBackgroundSpec({
    required this.asset,
    required this.dy,
    required this.scale,
    required this.alignment,
    this.blurSigma = 0,
    this.blurStart = 0.5,
  });

  /// Ruta del PNG de fondo.
  final String asset;

  /// Desplazamiento vertical en px: POSITIVO baja la imagen, NEGATIVO la sube.
  final double dy;

  /// Escala de la imagen (1.0 = tamano normal).
  final double scale;

  /// Anclaje de la imagen dentro de su marco.
  final Alignment alignment;

  /// Intensidad del blur del corte inferior (0 = sin blur). Simula que el
  /// cultivo se hunde bajo tierra hacia el corte.
  final double blurSigma;

  /// Fraccion de altura (0..1) donde empieza a entrar el blur del corte.
  /// Menor = el blur sube mas; mayor = se concentra mas abajo.
  final double blurStart;
}

/// Contenido del fondo de SeedsScreen. Si [SeedsBackgroundSpec.blurSigma] > 0,
/// superpone una copia difuminada de la imagen, enmascarada hacia el corte
/// inferior (transparente arriba -> opaca abajo), para simular que el cultivo
/// (cebolla) se hunde bajo tierra. Si es 0, dibuja la imagen nitida (otros
/// cultivos quedan exactamente igual que antes).
class _SeedsBgContent extends StatelessWidget {
  const _SeedsBgContent({required this.spec});

  final SeedsBackgroundSpec spec;

  Widget _transformed({double blur = 0}) {
    Widget image = Image.asset(
      spec.asset,
      fit: BoxFit.cover,
      alignment: spec.alignment,
    );
    if (blur > 0) {
      image = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: image,
      );
    }
    return Transform.translate(
      offset: Offset(0, spec.dy),
      child: Transform.scale(scale: spec.scale, child: image),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget sharp = _transformed();
    if (spec.blurSigma <= 0) return sharp;

    final double start = spec.blurStart.clamp(0.0, 1.0).toDouble();
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        sharp,
        ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const <Color>[Colors.transparent, Colors.white],
              stops: <double>[start, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: _transformed(blur: spec.blurSigma),
        ),
      ],
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

  static const String tomatoIconAsset = 'assets/icons/wizard/ic_tomate.png';
  static const double tomatoIconScale = 2.55;

  static const String cucumberIconAsset = 'assets/icons/wizard/ic_cucumber.png';
  static const double cucumberIconScale = 2.55;
  static const List<String> cucumberHeroFallbackAssets = <String>[
    'assets/seeds/cucumber/cucumber_stage_flowering.png',
    'assets/seeds/cucumber/cucumber_stage_vegetative.png',
    'assets/seeds/cucumber/cucumber_stage_fruit_set.png',
    'assets/seeds/cucumber/cucumber_stage_fruit_fill.png',
    'assets/seeds/cucumber/cucumber_stage_progressive_harvest.png',
    'assets/seeds/cucumber/cucumber_stage_establishment.png',
    'assets/seeds/cucumber/cucumber_stage_germination.png',
    'assets/seeds/cucumber/cucumber_stage_senescence.png',
  ];

  static const String chiliIconAsset = 'assets/icons/wizard/ic_chili.png';
  static const double chiliIconScale = 2.55;
  static const List<String> chiliHeroFallbackAssets = <String>[
    'assets/seeds/chili/chili_stage_flowering.png',
    'assets/seeds/chili/chili_stage_vegetative.png',
    'assets/seeds/chili/chili_stage_fruit_set.png',
    'assets/seeds/chili/chili_stage_fruit_fill.png',
    'assets/seeds/chili/chili_stage_progressive_harvest.png',
    'assets/seeds/chili/chili_stage_establishment.png',
    'assets/seeds/chili/chili_stage_germination.png',
    'assets/seeds/chili/chili_stage_senescence.png',
  ];

  static const String eggplantIconAsset = 'assets/icons/wizard/ic_eggplant.png';
  static const double eggplantIconScale = 2.55;
  static const String squashIconAsset =
      'assets/icons/wizard/ic_squash_generic.png';
  static const double squashIconScale = 2.55;
  static const List<String> squashHeroFallbackAssets = <String>[
    'assets/seeds/Squash/squash_stage_flowering.png',
    'assets/seeds/Squash/squash_stage_vegetative.png',
    'assets/seeds/Squash/squash_stage_fruit_set.png',
    'assets/seeds/Squash/squash_stage_fruit_fill.png',
    'assets/seeds/Squash/squash_stage_progressive_harvest.png',
    'assets/seeds/Squash/squash_stage_establishment.png',
    'assets/seeds/Squash/squash_stage_germination.png',
    'assets/seeds/Squash/squash_stage_senescence.png',
  ];
  static const List<String> eggplantHeroFallbackAssets = <String>[
    'assets/seeds/eggplant/eggplant_stage_flowering.png',
    'assets/seeds/eggplant/eggplant_stage_vegetative.png',
    'assets/seeds/eggplant/eggplant_stage_fruit_set.png',
    'assets/seeds/eggplant/eggplant_stage_fruit_fill.png',
    'assets/seeds/eggplant/eggplant_stage_progressive_harvest.png',
    'assets/seeds/eggplant/eggplant_stage_establishment.png',
    'assets/seeds/eggplant/eggplant_stage_germination.png',
    'assets/seeds/eggplant/eggplant_stage_senescence.png',
  ];
  static const String lettuceIconAsset =
      'assets/icons/wizard/ic_lettuce_generic.png';
  static const double lettuceIconScale = 2.55;
  static const List<String> lettuceHeroFallbackAssets = <String>[
    'assets/seeds/lettuce/lettuce_stage_vegetative.png',
    'assets/seeds/lettuce/lettuce_stage_head_formation.png',
    'assets/seeds/lettuce/lettuce_stage_harvest_window.png',
    'assets/seeds/lettuce/lettuce_stage_establishment.png',
    'assets/seeds/lettuce/lettuce_stage_germination.png',
    'assets/seeds/lettuce/lettuce_stage_senescence.png',
  ];
  static const String spinachIconAsset = 'assets/icons/wizard/ic_spinach.png';
  static const double spinachIconScale = 2.55;
  static const List<String> spinachHeroFallbackAssets = <String>[
    'assets/seeds/spinach/spinach_stage_leaf_expansion.png',
    'assets/seeds/spinach/spinach_stage_commercial_maturity.png',
    'assets/seeds/spinach/spinach_stage_harvest_window.png',
    'assets/seeds/spinach/spinach_stage_vegetative_early.png',
    'assets/seeds/spinach/spinach_stage_establishment.png',
    'assets/seeds/spinach/spinach_stage_germination.png',
    'assets/seeds/spinach/spinach_stage_quality_decline.png',
    'assets/seeds/spinach/spinach_stage_bolting_senescence.png',
  ];
  static const String onionIconAsset =
      'assets/icons/wizard/ic_onion_generic.png';
  static const double onionIconScale = 2.55;
  static const List<String> onionHeroFallbackAssets = <String>[
    'assets/seeds/Onion/onion_stage_bulb_fill.png',
    'assets/seeds/Onion/onion_stage_bulb_initiation.png',
    'assets/seeds/Onion/onion_stage_pre_bulbing.png',
    'assets/seeds/Onion/onion_stage_vegetative.png',
    'assets/seeds/Onion/onion_stage_establishment.png',
    'assets/seeds/Onion/onion_stage_establishment_early.png',
    'assets/seeds/Onion/onion_stage_germination.png',
    'assets/seeds/Onion/onion_stage_maturity_harvest.png',
    'assets/seeds/Onion/onion_stage_bolting_event.png',
  ];
  static const String garlicIconAsset =
      'assets/icons/wizard/ic_garlic_generic.png';
  static const double garlicIconScale = 2.55;
  static const List<String> garlicHeroFallbackAssets = <String>[
    'assets/seeds/Garlic/garlic_stage_germination.png',
    'assets/seeds/Garlic/garlic_stage_emergence_establishment.png',
    'assets/seeds/Garlic/garlic_stage_vegetative_leaf_growth.png',
    'assets/seeds/Garlic/garlic_stage_vernalization_window.png',
    'assets/seeds/Garlic/garlic_stage_clove_differentiation.png',
    'assets/seeds/Garlic/garlic_stage_bulb_filling.png',
    'assets/seeds/Garlic/garlic_stage_maturation_drydown.png',
    'assets/seeds/Garlic/garlic_stage_harvest_curing.png',
    'assets/seeds/Garlic/garlic_stage_scape_bolting.png',
  ];

  static const String bgAsset = 'assets/images/bg_image_seeds.png';

  /// Fondo alterno para cebolla: a diferencia de hoja/fruto, el bulbo crece
  /// bajo tierra, por lo que usa una escena de hortaliza de bulbo.
  static const String bgAssetHortaliza =
      'assets/images/bg_image_seeds_hortaliza.png';

  // ── Posicion del fondo de CEBOLLA (perillas independientes) ────────────
  // Estas 3 perillas SOLO afectan al fondo de cebolla y son independientes
  // entre si y del fondo por defecto. Cambia una sin tocar las demas:
  //   onionBgDy        -> mueve vertical: POSITIVO baja, NEGATIVO sube (px).
  //   onionBgScale     -> tamano: 1.0 normal, 1.1 = 10% mas grande.
  //   onionBgAlignment -> anclaje de la imagen dentro de su marco.
  static const double onionBgDy = 100;
  static const double onionBgScale = 1.0;
  static const Alignment onionBgAlignment = Alignment.topCenter;

  // Blur del corte inferior SOLO para cebolla (simula el bulbo bajo tierra).
  // Independientes entre si y del resto:
  //   onionBgBlurSigma -> que tan difuminado: 0 = sin blur, 10-16 = fuerte.
  //   onionBgBlurStart -> 0..1, donde entra el blur (0.5 = mitad hacia abajo;
  //                       subelo para pegar el difuminado mas al corte).
  static const double onionBgBlurSigma = 10;
  static const double onionBgBlurStart = 0.5;

  /// Resuelve fondo + posicion de SeedsScreen segun el cultivo. SOLO cebolla
  /// y ajo usan la escena de bulbo bajo tierra; cualquier otro cultivo
  /// conserva el fondo por defecto.
  static SeedsBackgroundSpec backgroundSpecForCrop(String? cropId) {
    final canonicalCropId = CropCatalog.canonicalCropKey(cropId);
    final bool isUndergroundBulb =
        canonicalCropId == CropCatalog.onionCropId ||
        canonicalCropId == CropCatalog.garlicCropId;
    return isUndergroundBulb
        ? const SeedsBackgroundSpec(
            asset: bgAssetHortaliza,
            dy: onionBgDy,
            scale: onionBgScale,
            alignment: onionBgAlignment,
            blurSigma: onionBgBlurSigma,
            blurStart: onionBgBlurStart,
          )
        : const SeedsBackgroundSpec(
            asset: bgAsset,
            dy: topBgDy,
            scale: topBgScale,
            alignment: topBgAlignment,
          );
  }

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
      case 'cucumber':
        return 'Pepino';
      case 'chili':
        return 'Chile';
      case 'eggplant':
        return 'Berenjena';
      case 'squash':
        return 'Calabaza';
      case 'lettuce':
        return 'Lechuga';
      case 'spinach':
        return 'Espinaca';
      case 'onion':
        return 'Cebolla';
      case 'garlic':
        return 'Ajo';
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
    if (isTreeCrop(cropId: cropId, cropCategoryId: cropContext?.cropCategoryId)) {
      return _resolvedTreeProfileLabel(
        cropId: cropId,
        cropContext: cropContext,
        seed: seed,
        routeVarietyAlias: routeVarietyAlias,
      );
    }

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

  static String _resolvedTreeProfileLabel({
    required String cropId,
    required DeviceCropContext? cropContext,
    required SeedInstall? seed,
    required String? routeVarietyAlias,
  }) {
    final rawProfileValue =
        cropContext?.profileId ??
        seed?.profileId ??
        cropContext?.varietyId ??
        cropContext?.varietyAlias ??
        seed?.varietyAlias ??
        routeVarietyAlias;

    final profile = CropCatalog.profileByAny(cropId, rawProfileValue);
    if (profile != null) {
      return TreeProfilePresentation.displayLabel(
        cropId,
        profile.id,
        fallbackLabel: profile.label,
      );
    }

    final defaultProfileId = CropCatalog.cropById(cropId)?.defaultProfileId;
    return TreeProfilePresentation.displayLabel(
      cropId,
      rawProfileValue ?? defaultProfileId,
      fallbackLabel: rawProfileValue,
    );
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
    required String cropId,
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
      if (isTreeCrop(cropId: cropId)) {
        return TreeProfilePresentation.displayLabel(
          cropId,
          CropCatalog.cropById(cropId)?.defaultProfileId,
          fallbackLabel: cropDisplayName,
        );
      }
      if (cropId == CropCatalog.squashCropId) {
        return '$cropDisplayName - Calabaza generica';
      }
      if (cropId == CropCatalog.lettuceCropId) {
        return '$cropDisplayName - Lechuga generica';
      }
      if (cropId == CropCatalog.spinachCropId) {
        return '$cropDisplayName - Espinaca generica';
      }
      if (cropId == CropCatalog.garlicCropId) {
        return '$cropDisplayName - Ajo generico';
      }
      if (cropId == CropCatalog.onionCropId) {
        return '$cropDisplayName - Cebolla genérica';
      }
      if (isEstablishmentMaintenanceCrop(cropId: cropId)) {
        return '$cropDisplayName – ${ornamentalGeneralShortLabel(cropId)}';
      }
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
        case CropCatalog.tomatoCropId:
          return SeedsScreenLayout.tomatoIconAsset;
        case CropCatalog.cucumberCropId:
          return SeedsScreenLayout.cucumberIconAsset;
        case CropCatalog.chiliCropId:
          return SeedsScreenLayout.chiliIconAsset;
        case CropCatalog.eggplantCropId:
          return SeedsScreenLayout.eggplantIconAsset;
        case CropCatalog.squashCropId:
          return SeedsScreenLayout.squashIconAsset;
        case CropCatalog.lettuceCropId:
          return SeedsScreenLayout.lettuceIconAsset;
        case CropCatalog.spinachCropId:
          return SeedsScreenLayout.spinachIconAsset;
        case CropCatalog.onionCropId:
          return SeedsScreenLayout.onionIconAsset;
        case CropCatalog.garlicCropId:
          return SeedsScreenLayout.garlicIconAsset;
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
      case CropCatalog.tomatoCropId:
        return SeedsScreenLayout.tomatoIconAsset;
      case CropCatalog.cucumberCropId:
        return SeedsScreenLayout.cucumberIconAsset;
      case CropCatalog.chiliCropId:
        return SeedsScreenLayout.chiliIconAsset;
      case CropCatalog.eggplantCropId:
        return SeedsScreenLayout.eggplantIconAsset;
      case CropCatalog.squashCropId:
        return SeedsScreenLayout.squashIconAsset;
      case CropCatalog.lettuceCropId:
        return SeedsScreenLayout.lettuceIconAsset;
      case CropCatalog.spinachCropId:
        return SeedsScreenLayout.spinachIconAsset;
      case CropCatalog.onionCropId:
        return SeedsScreenLayout.onionIconAsset;
      case CropCatalog.garlicCropId:
        return SeedsScreenLayout.garlicIconAsset;
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

    if (asset == SeedsScreenLayout.tomatoIconAsset ||
        cropId == CropCatalog.tomatoCropId) {
      return SeedsScreenLayout.tomatoIconScale;
    }

    if (asset == SeedsScreenLayout.cucumberIconAsset ||
        cropId == CropCatalog.cucumberCropId) {
      return SeedsScreenLayout.cucumberIconScale;
    }

    if (asset == SeedsScreenLayout.chiliIconAsset ||
        cropId == CropCatalog.chiliCropId) {
      return SeedsScreenLayout.chiliIconScale;
    }

    if (asset == SeedsScreenLayout.eggplantIconAsset ||
        cropId == CropCatalog.eggplantCropId) {
      return SeedsScreenLayout.eggplantIconScale;
    }

    if (asset == SeedsScreenLayout.squashIconAsset ||
        cropId == CropCatalog.squashCropId) {
      return SeedsScreenLayout.squashIconScale;
    }

    if (asset == SeedsScreenLayout.lettuceIconAsset ||
        cropId == CropCatalog.lettuceCropId) {
      return SeedsScreenLayout.lettuceIconScale;
    }

    if (asset == SeedsScreenLayout.spinachIconAsset ||
        cropId == CropCatalog.spinachCropId) {
      return SeedsScreenLayout.spinachIconScale;
    }

    if (asset == SeedsScreenLayout.onionIconAsset ||
        cropId == CropCatalog.onionCropId) {
      return SeedsScreenLayout.onionIconScale;
    }

    if (asset == SeedsScreenLayout.garlicIconAsset ||
        cropId == CropCatalog.garlicCropId) {
      return SeedsScreenLayout.garlicIconScale;
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

    if (isEstablishmentMaintenanceCrop(cropId: cropId)) {
      add(ornamentalStageUnknownImage(cropId));
      add(ornamentalCropIcon(cropId));
    }

    if (cropId == CropCatalog.cucumberCropId) {
      for (final asset in SeedsScreenLayout.cucumberHeroFallbackAssets) {
        add(asset);
      }
    }

    if (cropId == CropCatalog.chiliCropId) {
      for (final asset in SeedsScreenLayout.chiliHeroFallbackAssets) {
        add(asset);
      }
    }

    if (cropId == CropCatalog.eggplantCropId) {
      for (final asset in SeedsScreenLayout.eggplantHeroFallbackAssets) {
        add(asset);
      }
    }

    if (cropId == CropCatalog.squashCropId) {
      for (final asset in SeedsScreenLayout.squashHeroFallbackAssets) {
        add(asset);
      }
      for (final asset in SeedsScreenLayout.cucumberHeroFallbackAssets) {
        add(asset);
      }
    }

    if (cropId == CropCatalog.lettuceCropId) {
      for (final asset in SeedsScreenLayout.lettuceHeroFallbackAssets) {
        add(asset);
      }
    }

    if (cropId == CropCatalog.spinachCropId) {
      for (final asset in SeedsScreenLayout.spinachHeroFallbackAssets) {
        add(asset);
      }
    }

    if (cropId == CropCatalog.onionCropId) {
      for (final asset in SeedsScreenLayout.onionHeroFallbackAssets) {
        add(asset);
      }
    }

    if (cropId == CropCatalog.garlicCropId) {
      for (final asset in SeedsScreenLayout.garlicHeroFallbackAssets) {
        add(asset);
      }
      for (final asset in SeedsScreenLayout.onionHeroFallbackAssets) {
        add(asset);
      }
    }

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
  final String? dayValueText;
  final String daySuffix;

  final String harvestLabel;
  final String harvestText;
  final String windowLabel;
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
  final bool showGrowthRows;

  const _CareCardInner({
    required this.revealController,
    required this.padding,
    required this.careScore,
    required this.careScoreText,
    required this.careLabel,
    required this.careColor,
    required this.dayPrefix,
    required this.dayValue,
    this.dayValueText,
    required this.daySuffix,
    required this.harvestLabel,
    required this.harvestText,
    this.windowLabel = 'Ventana actual:',
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
    this.showGrowthRows = true,
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
                    dayValueText ?? '$dayValue',
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
                label: harvestLabel,
                value: harvestText,
                labelSize: lineLabelSize,
                valueSize: lineValueSize,
                valueColor: const Color(0xFF2E7D5A),
                valueBold: true,
              ),
              const SizedBox(height: 8),
              _LineRow(
                label: windowLabel,
                value: windowText,
                labelSize: lineLabelSize,
                valueSize: lineValueSize,
                valueColor: const Color(0xFF2E7D5A),
                valueBold: true,
              ),
              if (showGrowthRows) ...[
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
