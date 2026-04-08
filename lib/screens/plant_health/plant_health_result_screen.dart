import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';

import 'package:bio_g/core/plant_health/plant_health_confidence.dart';
import 'package:bio_g/core/plant_health/plant_health_models.dart';
import 'package:bio_g/theme/bio_g_theme.dart';
import 'package:bio_g/widgets/shared/bio_g_button.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PUBLIC API — llamar desde CropRiskIntroScreen._resolve()
// ═══════════════════════════════════════════════════════════════════════════════

Future<void> showPlantHealthResultDialog({
  required BuildContext context,
  required PlantHealthResult result,
  required String cropLabel,
  required String varietyLabel,
  required String stageLabel,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Resultado sanidad',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return _PlantHealthResultPopup(
            result: result,
            cropLabel: cropLabel,
            varietyLabel: varietyLabel,
            stageLabel: stageLabel,
          );
        },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final CurvedAnimation fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          final Animation<double> scale = Tween<double>(begin: 0.92, end: 1.0)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// POPUP WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _PlantHealthResultPopup extends StatefulWidget {
  final PlantHealthResult result;
  final String cropLabel;
  final String varietyLabel;
  final String stageLabel;

  const _PlantHealthResultPopup({
    required this.result,
    required this.cropLabel,
    required this.varietyLabel,
    required this.stageLabel,
  });

  @override
  State<_PlantHealthResultPopup> createState() =>
      _PlantHealthResultPopupState();
}

class _PlantHealthResultPopupState extends State<_PlantHealthResultPopup>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _expandController;
  late final AnimationController _contentController;

  late final Animation<double> _ringProgress;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );

    _ringProgress = CurvedAnimation(
      parent: _ringController,
      curve: const Cubic(0.20, 0.84, 0.20, 1),
    );

    _ringController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        Future<void>.delayed(const Duration(milliseconds: 120), () {
          if (!mounted) return;
          _expandController.forward();
        });
      }
    });

    _expandController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        Future<void>.delayed(const Duration(milliseconds: 140), () {
          if (!mounted) return;
          _contentController.forward();
        });
      }
    });

    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      _ringController.forward();
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _expandController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    navigator.popUntil((Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final PlantHealthResult result = widget.result;

    final RankedDiagnosis? top = result.topDiagnoses.isEmpty
        ? null
        : result.topDiagnoses.first;

    final double confidence = (top?.displayProbability01 ?? 0.5).clamp(
      0.0,
      1.0,
    );
    final int confidencePercent = (confidence * 100).round();

    final String confidenceLabel = top == null
        ? 'Media'
        : PlantHealthConfidence.labelEs(confidence);

    final Color urgencyColor = _urgencyTextColor(result.urgency);
    final Color ringColor = _ringAccentColor(result.urgency);
    final Color pillFillColor = _urgencyFillColor(result.urgency);

    final String mainDiagnosis =
        (top?.diagnosis.labelEs.trim().isNotEmpty ?? false)
        ? top!.diagnosis.labelEs
        : result.syndromeLabelEs;

    final String scientificName = top?.diagnosis.scientificName.trim() ?? '';
    final bool hasScientific = scientificName.isNotEmpty;

    final String cropLabel = widget.cropLabel.trim().isEmpty
        ? 'Cultivo'
        : widget.cropLabel.trim();
    final String varietyLabel = widget.varietyLabel.trim().isEmpty
        ? 'No definida'
        : widget.varietyLabel.trim();
    final String stageLabel = widget.stageLabel.trim().isEmpty
        ? 'No definida'
        : widget.stageLabel.trim();

    final List<String> whyBullets = _normalizedBullets(
      top?.whyEs ?? const <String>[],
      max: 3,
      exclude: <String>{top?.diagnosis.summaryEs.trim() ?? ''},
    );

    final List<String> confirmationBullets = _normalizedBullets(
      result.confirmationChecksEs,
      max: 3,
    );

    final List<String> actionBullets = _normalizedBullets(
      result.baseActionsEs,
      max: 3,
    );

    final List<RankedDiagnosis> differentialDiagnoses =
        result.topDiagnoses.length <= 1
        ? const <RankedDiagnosis>[]
        : result.topDiagnoses.skip(1).take(2).toList(growable: false);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxHeight = MediaQuery.of(context).size.height * 0.84;

    final Listenable merged = Listenable.merge(<Listenable>[
      _ringController,
      _expandController,
      _contentController,
    ]);

    return AnimatedBuilder(
      animation: merged,
      builder: (BuildContext context, Widget? _) {
        final double expandT = _expandController.value;
        final double contentT = _contentController.value;

        final double compactWidth = math.min(screenWidth - 52, 322);
        final double expandedWidth = math.min(screenWidth - 36, 572);

        final double compactHeight = compactWidth + 6;
        final double expandedHeight = math.min(maxHeight, 716);

        final double cardWidth = lerpDouble(
          compactWidth,
          expandedWidth,
          expandT,
        )!;
        final double cardHeight = lerpDouble(
          compactHeight,
          expandedHeight,
          expandT,
        )!;

        int animatedPercent = (_ringProgress.value * confidencePercent).round();

        if (_ringController.value > 0 &&
            confidencePercent > 0 &&
            animatedPercent == 0) {
          animatedPercent = 1;
        }

        animatedPercent = animatedPercent.clamp(0, confidencePercent);

        final double ringAnimatedProgress = (_ringProgress.value * confidence)
            .clamp(0.0, confidence);

        final double ringSize = lerpDouble(184, 206, expandT)!;

        final double handleOpacity = _interval(
          expandT,
          0.18,
          0.70,
          curve: Curves.easeOutCubic,
        );

        final double loadingOpacity =
            1.0 - _interval(expandT, 0.00, 0.56, curve: Curves.easeOutCubic);

        final double confidencePillOpacity = math.max(
          _interval(expandT, 0.72, 1.00, curve: Curves.easeOutCubic),
          _interval(contentT, 0.00, 0.20, curve: Curves.easeOutCubic),
        );

        final bool showLoadingBlock = loadingOpacity > 0.01;
        final bool showConfidencePill = confidencePillOpacity > 0.01;

        final double contentOpacity = _interval(
          contentT,
          0.00,
          1.00,
          curve: Curves.easeOutCubic,
        );

        final double buttonOpacity = _interval(
          contentT,
          0.58,
          1.00,
          curve: Curves.easeOutCubic,
        );

        final String loadingMessage = _loadingMessage(_ringController.value);

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                child: _PremiumBackdrop(
                  accentColor: ringColor,
                  ambienceT: _ringController.value,
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Material(
                    color: Colors.transparent,
                    child: BioGGlassCard(
                      radius: 30,
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(
                        0xFFF7F8F7,
                      ).withValues(alpha: 0.955),
                      borderColor: Colors.white.withValues(alpha: 0.72),
                      boxShadows: <BoxShadow>[
                        BoxShadow(
                          color: ringColor.withValues(alpha: 0.08),
                          blurRadius: 34,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 58,
                          offset: const Offset(0, 24),
                        ),
                      ],
                      child: SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: <Color>[
                                        Colors.white.withValues(alpha: 0.18),
                                        Colors.white.withValues(alpha: 0.05),
                                        Colors.transparent,
                                      ],
                                      stops: const <double>[0.0, 0.22, 0.55],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (showLoadingBlock)
                              Positioned(
                                top: 28,
                                left: 28,
                                right: 28,
                                child: Opacity(
                                  opacity: loadingOpacity * 0.95,
                                  child: _HeaderScanLine(
                                    progress: _ringController.value,
                                    color: ringColor,
                                  ),
                                ),
                              ),
                            Column(
                              children: <Widget>[
                                const SizedBox(height: 14),
                                IgnorePointer(
                                  ignoring: true,
                                  child: Opacity(
                                    opacity: handleOpacity,
                                    child: Container(
                                      width: 42,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.07,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder:
                                        (
                                          BuildContext context,
                                          BoxConstraints constraints,
                                        ) {
                                          return SingleChildScrollView(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            padding: const EdgeInsets.fromLTRB(
                                              24,
                                              8,
                                              24,
                                              22,
                                            ),
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minHeight:
                                                    constraints.maxHeight,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: <Widget>[
                                                  const SizedBox(height: 2),
                                                  AnimatedSize(
                                                    duration: const Duration(
                                                      milliseconds: 260,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    alignment:
                                                        Alignment.topCenter,
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: <Widget>[
                                                        _ConfidenceRing(
                                                          size: ringSize,
                                                          percent:
                                                              animatedPercent,
                                                          progress:
                                                              ringAnimatedProgress,
                                                          accentColor:
                                                              ringColor,
                                                          isLoading:
                                                              showLoadingBlock,
                                                          sweepT:
                                                              _ringController
                                                                  .value,
                                                          pulseT:
                                                              _ringController
                                                                  .value,
                                                        ),
                                                        if (showLoadingBlock) ...<
                                                          Widget
                                                        >[
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Opacity(
                                                            opacity:
                                                                loadingOpacity,
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: <Widget>[
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            13,
                                                                        vertical:
                                                                            6,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: ringColor
                                                                        .withValues(
                                                                          alpha:
                                                                              0.08,
                                                                        ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          999,
                                                                        ),
                                                                    border: Border.all(
                                                                      color: ringColor.withValues(
                                                                        alpha:
                                                                            0.14,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    'Analizando coincidencia probable',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          11.4,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w800,
                                                                      color:
                                                                          ringColor,
                                                                      letterSpacing:
                                                                          0.10,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                                AnimatedSwitcher(
                                                                  duration:
                                                                      const Duration(
                                                                        milliseconds:
                                                                            260,
                                                                      ),
                                                                  switchInCurve:
                                                                      Curves
                                                                          .easeOutCubic,
                                                                  switchOutCurve:
                                                                      Curves
                                                                          .easeOutCubic,
                                                                  transitionBuilder:
                                                                      (
                                                                        Widget
                                                                        child,
                                                                        Animation<
                                                                          double
                                                                        >
                                                                        animation,
                                                                      ) {
                                                                        return FadeTransition(
                                                                          opacity:
                                                                              animation,
                                                                          child: SlideTransition(
                                                                            position:
                                                                                Tween<
                                                                                      Offset
                                                                                    >(
                                                                                      begin: const Offset(
                                                                                        0,
                                                                                        0.08,
                                                                                      ),
                                                                                      end: Offset.zero,
                                                                                    )
                                                                                    .animate(
                                                                                      animation,
                                                                                    ),
                                                                            child:
                                                                                child,
                                                                          ),
                                                                        );
                                                                      },
                                                                  child: Text(
                                                                    loadingMessage,
                                                                    key:
                                                                        ValueKey<
                                                                          String
                                                                        >(
                                                                          loadingMessage,
                                                                        ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          13.0,
                                                                      height:
                                                                          1.34,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: BioGTheme
                                                                          .charcoal
                                                                          .withValues(
                                                                            alpha:
                                                                                0.50,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ] else if (showConfidencePill) ...<
                                                          Widget
                                                        >[
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Opacity(
                                                            opacity:
                                                                confidencePillOpacity,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        13,
                                                                    vertical: 5,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    pillFillColor,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      999,
                                                                    ),
                                                                border: Border.all(
                                                                  color: urgencyColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.08,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Text(
                                                                '$confidenceLabel · ${_urgencyLabel(result.urgency)}',
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      11.4,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color:
                                                                      urgencyColor,
                                                                  letterSpacing:
                                                                      0.10,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Opacity(
                                                    opacity: contentOpacity,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: <Widget>[
                                                        _RevealIn(
                                                          progress: contentT,
                                                          start: 0.00,
                                                          end: 0.18,
                                                          child: Text(
                                                            '$confidencePercent% de probabilidad de ser',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontSize: 10.8,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: BioGTheme
                                                                  .charcoal
                                                                  .withValues(
                                                                    alpha: 0.50,
                                                                  ),
                                                              letterSpacing:
                                                                  0.02,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        _RevealIn(
                                                          progress: contentT,
                                                          start: 0.08,
                                                          end: 0.28,
                                                          distance: 14,
                                                          child: Text(
                                                            mainDiagnosis,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 27,
                                                                  height: 1.08,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  letterSpacing:
                                                                      -0.45,
                                                                  color:
                                                                      BioGTheme
                                                                          .ink,
                                                                ),
                                                          ),
                                                        ),
                                                        if (hasScientific) ...<
                                                          Widget
                                                        >[
                                                          const SizedBox(
                                                            height: 6,
                                                          ),
                                                          _RevealIn(
                                                            progress: contentT,
                                                            start: 0.16,
                                                            end: 0.34,
                                                            distance: 10,
                                                            child: Text(
                                                              scientificName,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                fontSize: 13.2,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: BioGTheme
                                                                    .charcoal
                                                                    .withValues(
                                                                      alpha:
                                                                          0.48,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        _RevealIn(
                                                          progress: contentT,
                                                          start: 0.18,
                                                          end: 0.38,
                                                          distance: 12,
                                                          child: Wrap(
                                                            alignment:
                                                                WrapAlignment
                                                                    .center,
                                                            spacing: 8,
                                                            runSpacing: 8,
                                                            children: <Widget>[
                                                              _MetaBadge(
                                                                label: _diagnosisTypeLabel(
                                                                  top
                                                                      ?.diagnosis
                                                                      .type,
                                                                ),
                                                              ),
                                                              if (top?.requiresCaution ==
                                                                  true)
                                                                const _MetaBadge(
                                                                  label:
                                                                      'Usar con cautela',
                                                                  isSubtle:
                                                                      true,
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (top?.varietyAdjusted ==
                                                                true ||
                                                            top?.requiresCaution ==
                                                                true) ...<
                                                          Widget
                                                        >[
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          _RevealIn(
                                                            progress: contentT,
                                                            start: 0.22,
                                                            end: 0.40,
                                                            distance: 10,
                                                            child: Text(
                                                              top?.requiresCaution ==
                                                                      true
                                                                  ? 'La variedad configurada modificó esta lectura. Úsala como orientación y confirma en campo.'
                                                                  : 'La variedad configurada modificó esta probabilidad.',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                fontSize: 12.4,
                                                                height: 1.42,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: BioGTheme
                                                                    .charcoal
                                                                    .withValues(
                                                                      alpha:
                                                                          0.54,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        _RevealIn(
                                                          progress: contentT,
                                                          start: 0.24,
                                                          end: 0.42,
                                                          distance: 12,
                                                          child: Wrap(
                                                            alignment:
                                                                WrapAlignment
                                                                    .center,
                                                            spacing: 8,
                                                            runSpacing: 8,
                                                            children: <Widget>[
                                                              _ContextInfoPill(
                                                                label:
                                                                    'Cultivo',
                                                                value:
                                                                    cropLabel,
                                                              ),
                                                              _ContextInfoPill(
                                                                label:
                                                                    'Variedad',
                                                                value:
                                                                    varietyLabel,
                                                              ),
                                                              _ContextInfoPill(
                                                                label: 'Etapa',
                                                                value:
                                                                    stageLabel,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (whyBullets
                                                            .isNotEmpty) ...<
                                                          Widget
                                                        >[
                                                          const SizedBox(
                                                            height: 26,
                                                          ),
                                                          _RevealIn(
                                                            progress: contentT,
                                                            start: 0.28,
                                                            end: 0.46,
                                                            child: _SectionHeader(
                                                              title:
                                                                  'Por qué BIO-G cree que puede ser esto',
                                                              accentColor:
                                                                  ringColor,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          ...whyBullets
                                                              .asMap()
                                                              .entries
                                                              .map(
                                                                (
                                                                  MapEntry<
                                                                    int,
                                                                    String
                                                                  >
                                                                  entry,
                                                                ) => _RevealIn(
                                                                  progress:
                                                                      contentT,
                                                                  start:
                                                                      0.30 +
                                                                      (entry.key *
                                                                          0.03),
                                                                  end:
                                                                      0.52 +
                                                                      (entry.key *
                                                                          0.03),
                                                                  distance: 12,
                                                                  child: _SectionBullet(
                                                                    text: entry
                                                                        .value,
                                                                    accentColor:
                                                                        ringColor,
                                                                  ),
                                                                ),
                                                              ),
                                                        ],
                                                        if (confirmationBullets
                                                            .isNotEmpty) ...<
                                                          Widget
                                                        >[
                                                          const SizedBox(
                                                            height: 22,
                                                          ),
                                                          _RevealIn(
                                                            progress: contentT,
                                                            start: 0.36,
                                                            end: 0.56,
                                                            child: _SectionHeader(
                                                              title:
                                                                  'Qué revisar para confirmar',
                                                              accentColor:
                                                                  BioGTheme
                                                                      .charcoal
                                                                      .withValues(
                                                                        alpha:
                                                                            0.70,
                                                                      ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          ...confirmationBullets
                                                              .asMap()
                                                              .entries
                                                              .map(
                                                                (
                                                                  MapEntry<
                                                                    int,
                                                                    String
                                                                  >
                                                                  entry,
                                                                ) => _RevealIn(
                                                                  progress:
                                                                      contentT,
                                                                  start:
                                                                      0.38 +
                                                                      (entry.key *
                                                                          0.03),
                                                                  end:
                                                                      0.60 +
                                                                      (entry.key *
                                                                          0.03),
                                                                  distance: 12,
                                                                  child: _SectionBullet(
                                                                    text: entry
                                                                        .value,
                                                                    accentColor: BioGTheme
                                                                        .charcoal
                                                                        .withValues(
                                                                          alpha:
                                                                              0.62,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                        ],
                                                        if (actionBullets
                                                            .isNotEmpty) ...<
                                                          Widget
                                                        >[
                                                          const SizedBox(
                                                            height: 22,
                                                          ),
                                                          _RevealIn(
                                                            progress: contentT,
                                                            start: 0.44,
                                                            end: 0.62,
                                                            child: _SectionHeader(
                                                              title:
                                                                  'Qué recomendamos hacer',
                                                              accentColor:
                                                                  BioGTheme
                                                                      .green600,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          ...actionBullets
                                                              .asMap()
                                                              .entries
                                                              .map(
                                                                (
                                                                  MapEntry<
                                                                    int,
                                                                    String
                                                                  >
                                                                  entry,
                                                                ) => _RevealIn(
                                                                  progress:
                                                                      contentT,
                                                                  start:
                                                                      0.46 +
                                                                      (entry.key *
                                                                          0.03),
                                                                  end:
                                                                      0.68 +
                                                                      (entry.key *
                                                                          0.03),
                                                                  distance: 12,
                                                                  child: _SectionBullet(
                                                                    text: entry
                                                                        .value,
                                                                    accentColor:
                                                                        BioGTheme
                                                                            .green600,
                                                                  ),
                                                                ),
                                                              ),
                                                        ],
                                                        const SizedBox(
                                                          height: 26,
                                                        ),
                                                        _RevealIn(
                                                          progress: contentT,
                                                          start: 0.52,
                                                          end: 0.70,
                                                          child: _SectionHeader(
                                                            title:
                                                                'Lectura técnica',
                                                            accentColor:
                                                                BioGTheme
                                                                    .charcoal
                                                                    .withValues(
                                                                      alpha:
                                                                          0.68,
                                                                    ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        _RevealIn(
                                                          progress: contentT,
                                                          start: 0.54,
                                                          end: 0.74,
                                                          distance: 12,
                                                          child: _InfoStrip(
                                                            label: 'Confianza',
                                                            value:
                                                                confidenceLabel,
                                                          ),
                                                        ),
                                                        _RevealIn(
                                                          progress: contentT,
                                                          start: 0.58,
                                                          end: 0.78,
                                                          distance: 12,
                                                          child: _InfoStrip(
                                                            label: 'Severidad',
                                                            value:
                                                                _severityLabel(
                                                                  result
                                                                      .severity,
                                                                ),
                                                          ),
                                                        ),
                                                        _RevealIn(
                                                          progress: contentT,
                                                          start: 0.62,
                                                          end: 0.82,
                                                          distance: 12,
                                                          child: _InfoStrip(
                                                            label: 'Urgencia',
                                                            value:
                                                                _urgencyLabel(
                                                                  result
                                                                      .urgency,
                                                                ),
                                                          ),
                                                        ),
                                                        _RevealIn(
                                                          progress: contentT,
                                                          start: 0.66,
                                                          end: 0.86,
                                                          distance: 12,
                                                          child: _InfoStrip(
                                                            label:
                                                                'Diagnósticos comparados',
                                                            value:
                                                                '${result.topDiagnoses.length}',
                                                          ),
                                                        ),
                                                        if (differentialDiagnoses
                                                            .isNotEmpty) ...<
                                                          Widget
                                                        >[
                                                          const SizedBox(
                                                            height: 22,
                                                          ),
                                                          _RevealIn(
                                                            progress: contentT,
                                                            start: 0.70,
                                                            end: 0.86,
                                                            child: _SectionHeader(
                                                              title:
                                                                  'Otros posibles',
                                                              accentColor:
                                                                  BioGTheme
                                                                      .charcoal
                                                                      .withValues(
                                                                        alpha:
                                                                            0.60,
                                                                      ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          for (
                                                            int i = 0;
                                                            i <
                                                                differentialDiagnoses
                                                                    .length;
                                                            i++
                                                          )
                                                            _RevealIn(
                                                              progress:
                                                                  contentT,
                                                              start:
                                                                  0.72 +
                                                                  (i * 0.04),
                                                              end:
                                                                  0.90 +
                                                                  (i * 0.04),
                                                              distance: 10,
                                                              child: _PlainDifferential(
                                                                index: i + 2,
                                                                diagnosis:
                                                                    differentialDiagnoses[i],
                                                              ),
                                                            ),
                                                        ],
                                                        if (result.disclaimerEs
                                                            .trim()
                                                            .isNotEmpty) ...<
                                                          Widget
                                                        >[
                                                          const SizedBox(
                                                            height: 24,
                                                          ),
                                                          _RevealIn(
                                                            progress: contentT,
                                                            start: 0.82,
                                                            end: 0.96,
                                                            distance: 8,
                                                            child: Text(
                                                              result
                                                                  .disclaimerEs
                                                                  .trim(),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                height: 1.42,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: BioGTheme
                                                                    .charcoal
                                                                    .withValues(
                                                                      alpha:
                                                                          0.38,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                        const SizedBox(
                                                          height: 20,
                                                        ),
                                                        Opacity(
                                                          opacity:
                                                              buttonOpacity,
                                                          child: Transform.translate(
                                                            offset: Offset(
                                                              0,
                                                              (1 - buttonOpacity) *
                                                                  12,
                                                            ),
                                                            child: BioGButton(
                                                              label:
                                                                  'Entendido',
                                                              onTap:
                                                                  _handleDismiss,
                                                              height: 52,
                                                              radius: 18,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _urgencyLabel(PlantHealthUrgency urgency) {
    switch (urgency) {
      case PlantHealthUrgency.monitor72h:
        return 'Monitorear 48–72 h';
      case PlantHealthUrgency.review48h:
        return 'Revisar pronto';
      case PlantHealthUrgency.review24h:
        return 'Revisar en 24 h';
      case PlantHealthUrgency.sameDay:
        return 'Revisar hoy';
      case PlantHealthUrgency.immediate:
        return 'Acción inmediata';
    }
  }

  static String _severityLabel(PlantHealthSeverity severity) {
    switch (severity) {
      case PlantHealthSeverity.low:
        return 'Baja';
      case PlantHealthSeverity.medium:
        return 'Media';
      case PlantHealthSeverity.high:
        return 'Alta';
      case PlantHealthSeverity.critical:
        return 'Crítica';
    }
  }

  static String _loadingMessage(double t) {
    if (t < 0.33) {
      return 'Correlacionando síntomas con el cuadro observado.';
    }
    if (t < 0.66) {
      return 'Validando contexto del cultivo, etapa y señales clave.';
    }
    return 'Priorizando diagnósticos probables y nivel de urgencia.';
  }

  static Color _urgencyTextColor(PlantHealthUrgency urgency) {
    switch (urgency) {
      case PlantHealthUrgency.monitor72h:
        return const Color(0xFF2E9D68);
      case PlantHealthUrgency.review48h:
        return const Color(0xFFB18433);
      case PlantHealthUrgency.review24h:
        return const Color(0xFFC17A42);
      case PlantHealthUrgency.sameDay:
        return const Color(0xFFC35E5E);
      case PlantHealthUrgency.immediate:
        return const Color(0xFFB84B4B);
    }
  }

  static Color _urgencyFillColor(PlantHealthUrgency urgency) {
    switch (urgency) {
      case PlantHealthUrgency.monitor72h:
        return const Color(0xFFEAF7F0);
      case PlantHealthUrgency.review48h:
        return const Color(0xFFF9F3E5);
      case PlantHealthUrgency.review24h:
        return const Color(0xFFF9EFE7);
      case PlantHealthUrgency.sameDay:
        return const Color(0xFFFAECEB);
      case PlantHealthUrgency.immediate:
        return const Color(0xFFF9E8E8);
    }
  }

  static Color _ringAccentColor(PlantHealthUrgency urgency) {
    switch (urgency) {
      case PlantHealthUrgency.monitor72h:
        return const Color(0xFF47C98B);
      case PlantHealthUrgency.review48h:
        return const Color(0xFFD1AE5A);
      case PlantHealthUrgency.review24h:
        return const Color(0xFFD58F63);
      case PlantHealthUrgency.sameDay:
        return const Color(0xFFD77566);
      case PlantHealthUrgency.immediate:
        return const Color(0xFFC95E5E);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PREMIUM BACKDROP
// ═══════════════════════════════════════════════════════════════════════════════

class _PremiumBackdrop extends StatelessWidget {
  final Color accentColor;
  final double ambienceT;

  const _PremiumBackdrop({required this.accentColor, required this.ambienceT});

  @override
  Widget build(BuildContext context) {
    final double backdropT = Curves.easeOutCubic.transform(
      (ambienceT * 0.76).clamp(0.0, 1.0),
    );
    final double pulse =
        (math.sin((backdropT * 2 * math.pi * 1.05) - (math.pi / 2)) + 1) / 2;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 7.5 * backdropT,
            sigmaY: 7.5 * backdropT,
          ),
          child: Container(
            color: Colors.black.withValues(alpha: 0.035 + (backdropT * 0.02)),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                const Color(
                  0xFFF3F7F4,
                ).withValues(alpha: 0.045 + (backdropT * 0.02)),
                const Color(
                  0xFFECF2EF,
                ).withValues(alpha: 0.055 + (backdropT * 0.02)),
                Colors.black.withValues(alpha: 0.08),
              ],
            ),
          ),
        ),
        Positioned(
          top: 76,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 320 + (pulse * 18),
              height: 320 + (pulse * 18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    accentColor.withValues(alpha: 0.08 + (pulse * 0.025)),
                    accentColor.withValues(alpha: 0.028 + (backdropT * 0.006)),
                    Colors.transparent,
                  ],
                  stops: const <double>[0.0, 0.46, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: -50,
          child: _MistOrb(
            size: 220,
            color: const Color(0xFF96C9B0).withValues(alpha: 0.06),
          ),
        ),
        Positioned(
          right: -34,
          top: 180,
          child: _MistOrb(
            size: 180,
            color: accentColor.withValues(alpha: 0.05),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 70,
          child: _MistOrb(
            size: 260,
            color: const Color(0xFF7F958C).withValues(alpha: 0.04),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.12,
              colors: <Color>[
                Colors.transparent,
                Colors.black.withValues(alpha: 0.09),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MistOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _MistOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _HeaderScanLine extends StatelessWidget {
  final double progress;
  final Color color;

  const _HeaderScanLine({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double shimmerWidth = 110;
            final double travel = constraints.maxWidth + shimmerWidth;
            final double dx = (progress * travel) - (shimmerWidth / 2);

            return Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                Container(
                  height: 1.2,
                  width: constraints.maxWidth,
                  color: color.withValues(alpha: 0.10),
                ),
                Transform.translate(
                  offset: Offset(dx, 0),
                  child: Container(
                    width: shimmerWidth,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Colors.transparent,
                          color.withValues(alpha: 0.00),
                          color.withValues(alpha: 0.22),
                          color.withValues(alpha: 0.00),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONFIDENCE RING
// ═══════════════════════════════════════════════════════════════════════════════

class _ConfidenceRing extends StatelessWidget {
  final double size;
  final int percent;
  final double progress;
  final Color accentColor;
  final bool isLoading;
  final double sweepT;
  final double pulseT;

  const _ConfidenceRing({
    required this.size,
    required this.percent,
    required this.progress,
    required this.accentColor,
    this.isLoading = false,
    this.sweepT = 0,
    this.pulseT = 0,
  });

  @override
  Widget build(BuildContext context) {
    final double percentFontSize = size * 0.208;
    final double labelFontSize = size * 0.069;
    final double pulse =
        (math.sin((pulseT * 2 * math.pi * 1.4) - (math.pi / 2)) + 1) / 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (isLoading)
            Container(
              width: size * (0.74 + (pulse * 0.05)),
              height: size * (0.74 + (pulse * 0.05)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    accentColor.withValues(alpha: 0.08 + (pulse * 0.02)),
                    accentColor.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const <double>[0.0, 0.58, 1.0],
                ),
              ),
            ),
          Container(
            width: size * 0.60,
            height: size * 0.60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  accentColor.withValues(alpha: 0.10),
                  accentColor.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const <double>[0.0, 0.68, 1.0],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.085),
                  blurRadius: size * 0.16,
                  spreadRadius: 0.5,
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.035),
                  blurRadius: size * 0.24,
                  spreadRadius: 1.5,
                ),
              ],
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                trackColor: accentColor.withValues(alpha: 0.08),
                progressColor: accentColor,
                strokeWidth: size * 0.064,
                showSweep: isLoading,
                sweepT: sweepT,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: percentFontSize,
                  height: 1.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: BioGTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'probabilidad',
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w700,
                  color: BioGTheme.charcoal.withValues(alpha: 0.44),
                  letterSpacing: 0.18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;
  final bool showSweep;
  final double sweepT;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
    required this.showSweep,
    required this.sweepT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double inset = strokeWidth / 2;
    final Rect arcRect = (Offset.zero & size).deflate(inset);
    final Offset center = size.center(Offset.zero);
    final double radius = (size.width / 2) - inset;

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, -math.pi / 2, 2 * math.pi, false, trackPaint);

    if (showSweep) {
      final Paint sweepPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.72
        ..strokeCap = StrokeCap.round;

      final double sweepStart = (-math.pi / 2) + (sweepT * 2 * math.pi * 1.4);
      canvas.drawArc(
        arcRect.deflate(strokeWidth * 0.16),
        sweepStart,
        math.pi * 0.26,
        false,
        sweepPaint,
      );
    }

    if (progress > 0) {
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );

      if (progress > 0.02) {
        final double angle = (-math.pi / 2) + (2 * math.pi * progress);
        final Offset dotCenter = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );

        canvas.drawCircle(
          dotCenter,
          strokeWidth * 0.58,
          Paint()..color = progressColor,
        );

        canvas.drawCircle(
          dotCenter,
          strokeWidth * 0.96,
          Paint()..color = progressColor.withValues(alpha: 0.10),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.strokeWidth != strokeWidth ||
      old.showSweep != showSweep ||
      old.sweepT != sweepT;
}

// ═══════════════════════════════════════════════════════════════════════════════
// REVEAL HELPER
// ═══════════════════════════════════════════════════════════════════════════════

class _RevealIn extends StatelessWidget {
  final double progress;
  final double start;
  final double end;
  final double distance;
  final Widget child;

  const _RevealIn({
    required this.progress,
    required this.start,
    required this.end,
    required this.child,
    this.distance = 16,
  });

  @override
  Widget build(BuildContext context) {
    final double t = _interval(
      progress,
      start,
      end,
      curve: Curves.easeOutCubic,
    );

    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * distance),
        child: child,
      ),
    );
  }
}

double _interval(
  double value,
  double start,
  double end, {
  Curve curve = Curves.easeOutCubic,
}) {
  if (end <= start) {
    return value >= end ? 1.0 : 0.0;
  }

  final double normalized = ((value - start) / (end - start)).clamp(0.0, 1.0);
  return curve.transform(normalized);
}

List<String> _normalizedBullets(
  List<String> items, {
  required int max,
  Set<String> exclude = const <String>{},
}) {
  final Set<String> seen = <String>{};
  final Set<String> excluded = exclude
      .map((String e) => e.trim())
      .where((String e) => e.isNotEmpty)
      .toSet();

  final List<String> cleaned = <String>[];
  for (final String raw in items) {
    final String text = raw.trim();
    if (text.isEmpty) continue;
    if (excluded.contains(text)) continue;
    if (seen.contains(text)) continue;
    seen.add(text);
    cleaned.add(text);
    if (cleaned.length >= max) break;
  }
  return cleaned;
}

String _diagnosisTypeLabel(String? type) {
  switch ((type ?? '').trim().toLowerCase()) {
    case 'fungus':
      return 'Hongo';
    case 'insect':
      return 'Insecto';
    case 'virus':
      return 'Virus';
    case 'stress':
      return 'Estrés';
    case 'bacteria':
      return 'Bacteria';
    default:
      return 'Diagnóstico';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXTRA INFO WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _ContextInfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _ContextInfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: Colors.white.withValues(alpha: 0.70),
      borderColor: Colors.white.withValues(alpha: 0.86),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 12.2,
                fontWeight: FontWeight.w700,
                color: BioGTheme.charcoal.withValues(alpha: 0.60),
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 12.2,
                fontWeight: FontWeight.w800,
                color: BioGTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final bool isSubtle;

  const _MetaBadge({required this.label, this.isSubtle = false});

  @override
  Widget build(BuildContext context) {
    final Color fillColor = isSubtle
        ? Colors.black.withValues(alpha: 0.035)
        : BioGTheme.green600.withValues(alpha: 0.08);
    final Color strokeColor = isSubtle
        ? Colors.black.withValues(alpha: 0.06)
        : BioGTheme.green600.withValues(alpha: 0.10);
    final Color textColor = isSubtle
        ? BioGTheme.charcoal.withValues(alpha: 0.58)
        : BioGTheme.green700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: strokeColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.6,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.08,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color accentColor;

  const _SectionHeader({required this.title, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
            color: BioGTheme.ink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  accentColor.withValues(alpha: 0.12),
                  accentColor.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionBullet extends StatelessWidget {
  final String text;
  final Color accentColor;

  const _SectionBullet({required this.text, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.08),
                border: Border.all(color: accentColor.withValues(alpha: 0.10)),
              ),
              child: Center(
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.6,
                height: 1.46,
                fontWeight: FontWeight.w500,
                color: BioGTheme.charcoal.withValues(alpha: 0.74),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoStrip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.2,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: BioGTheme.charcoal.withValues(alpha: 0.56),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.4,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: BioGTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PLAIN TEXT WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _PlainDifferential extends StatelessWidget {
  final int index;
  final RankedDiagnosis diagnosis;

  const _PlainDifferential({required this.index, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    final int pct = (diagnosis.displayProbability01 * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Text(
            '$index.',
            style: TextStyle(
              fontSize: 13.4,
              fontWeight: FontWeight.w800,
              color: BioGTheme.charcoal.withValues(alpha: 0.40),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              diagnosis.diagnosis.labelEs,
              style: const TextStyle(
                fontSize: 13.8,
                fontWeight: FontWeight.w600,
                color: BioGTheme.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: BioGTheme.charcoal.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
