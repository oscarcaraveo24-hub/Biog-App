import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

typedef PdfLoader = Future<Uint8List> Function();

class PdfPreviewScreen extends StatefulWidget {
  final Uint8List? pdfBytes;
  final PdfLoader? onLoadPdf;
  final String fileName;
  final Duration minimumLoadingDuration;

  const PdfPreviewScreen({
    super.key,
    required Uint8List pdfBytes,
    this.fileName = 'BioG_Reporte.pdf',
  }) : pdfBytes = pdfBytes,
       onLoadPdf = null,
       minimumLoadingDuration = Duration.zero;

  const PdfPreviewScreen.generate({
    super.key,
    required PdfLoader this.onLoadPdf,
    this.fileName = 'BioG_Reporte.pdf',
    this.minimumLoadingDuration = const Duration(seconds: 3),
  }) : pdfBytes = null;

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen>
    with SingleTickerProviderStateMixin {
  final List<Uint8List> _pages = <Uint8List>[];

  late final AnimationController _loadingController;

  Uint8List? _pdfBytes;
  bool _preparingPdf = true;
  bool _renderingPages = false;
  String? _errorMessage;

  bool get _isBusy => _preparingPdf || (_renderingPages && _pages.isEmpty);

  @override
  void initState() {
    super.initState();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prepareDocument();
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _prepareDocument() async {
    setState(() {
      _pages.clear();
      _errorMessage = null;
      _preparingPdf = true;
      _renderingPages = false;
      _pdfBytes = null;
    });

    try {
      final Future<Uint8List> pdfFuture = widget.pdfBytes != null
          ? Future<Uint8List>.value(widget.pdfBytes!)
          : widget.onLoadPdf!.call();

      final Uint8List pdfBytes;
      if (widget.pdfBytes != null) {
        pdfBytes = widget.pdfBytes!;
      } else {
        final List<dynamic> results = await Future.wait<dynamic>(
          <Future<dynamic>>[
            pdfFuture,
            Future<void>.delayed(widget.minimumLoadingDuration),
          ],
        );
        pdfBytes = results.first as Uint8List;
      }

      if (!mounted) return;

      setState(() {
        _pdfBytes = pdfBytes;
        _preparingPdf = false;
        _renderingPages = true;
      });

      await _renderPages(pdfBytes);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo generar el PDF.\n$error';
        _preparingPdf = false;
        _renderingPages = false;
      });
    }
  }

  Future<void> _renderPages(Uint8List bytes) async {
    _pages.clear();

    await for (final PdfRaster page in Printing.raster(bytes, dpi: 150)) {
      if (!mounted) return;
      final Uint8List png = await page.toPng();
      if (!mounted) return;
      setState(() => _pages.add(png));
    }

    if (!mounted) return;
    setState(() => _renderingPages = false);
  }

  Future<void> _share() async {
    if (_pdfBytes == null) return;

    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/${widget.fileName}');
    await file.writeAsBytes(_pdfBytes!, flush: true);

    if (!mounted) return;

    final RenderObject? renderObject = context.findRenderObject();
    final Rect origin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : const Rect.fromLTWH(0, 0, 1, 1);

    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path)],
        subject: 'BIO-G · Reporte de Campo',
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPad = MediaQuery.of(context).padding.top;
    final double bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Colors.black.withValues(alpha: 0.65),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    const Color(0xFFF7FBF8),
                    const Color(0xFFF1F7F4),
                    const Color(0xFFECF3EF),
                  ],
                ),
              ),
            ),
          ),
          if (_errorMessage != null)
            _PreviewErrorState(
              message: _errorMessage!,
              onRetry: widget.onLoadPdf == null ? null : _prepareDocument,
            )
          else if (_isBusy)
            _PreviewLoadingState(
              controller: _loadingController,
              showRasterMessage: !_preparingPdf && _renderingPages,
            )
          else
            ListView.builder(
              padding: EdgeInsets.fromLTRB(
                20,
                topPad + kToolbarHeight + 8,
                20,
                84 + bottomPad,
              ),
              itemCount: _pages.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(_pages[index], fit: BoxFit.fitWidth),
                    ),
                  ),
                );
              },
            ),
          if (_pdfBytes != null && _errorMessage == null)
            Positioned(
              left: 40,
              right: 40,
              bottom: 20 + bottomPad,
              child: _ShareButton(onTap: _share),
            ),
        ],
      ),
    );
  }
}

class _PreviewLoadingState extends StatelessWidget {
  final AnimationController controller;
  final bool showRasterMessage;

  const _PreviewLoadingState({
    required this.controller,
    required this.showRasterMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          final double t = Curves.easeInOutCubic.transform(
            (math.sin(controller.value * math.pi * 2) + 1) / 2,
          );

          final double scale = 0.985 + (t * 0.035);
          final double glow = 0.12 + (t * 0.10);
          final String loadingLabel = showRasterMessage
              ? 'Preparando vista previa'
              : 'Generando PDF';
          final String message = showRasterMessage
              ? 'Montando páginas para que puedas revisarlo y compartirlo.'
              : 'Consolidando lecturas, resumen técnico y formato de exportación.';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          const Color(0xFF2E7D32).withValues(alpha: glow),
                          const Color(0xFF2E7D32).withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                        stops: const <double>[0.0, 0.62, 1.0],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.78),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFF2E7D32,
                            ).withValues(alpha: 0.08),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: const Color(
                                0xFF2E7D32,
                              ).withValues(alpha: 0.10),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2E7D32),
                                ),
                                strokeWidth: 4.2,
                                strokeCap: StrokeCap.round,
                                backgroundColor: const Color(
                                  0xFF2E7D32,
                                ).withValues(alpha: 0.08),
                              ),
                            ),
                            Icon(
                              showRasterMessage
                                  ? Icons.visibility_outlined
                                  : Icons.picture_as_pdf_outlined,
                              size: 24,
                              color: const Color(
                                0xFF2E7D32,
                              ).withValues(alpha: 0.48),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  loadingLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: Color(0xFF1E2926),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.2,
                    height: 1.42,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2926).withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    showRasterMessage
                        ? 'Ajustando páginas del reporte'
                        : 'Esto puede tardar unos segundos',
                    style: const TextStyle(
                      fontSize: 11.8,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                      letterSpacing: 0.08,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PreviewErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const _PreviewErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.90)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB84B4B).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 30,
                      color: const Color(0xFFB84B4B).withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No pudimos preparar el PDF',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: Color(0xFF1E2926),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.8,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E2926).withValues(alpha: 0.62),
                    ),
                  ),
                  if (onRetry != null) ...<Widget>[
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Reintentar',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: const SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.share_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Compartir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
