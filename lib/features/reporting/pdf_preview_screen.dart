import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String fileName;

  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    this.fileName = 'BioG_Reporte.pdf',
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final List<Uint8List> _pages = <Uint8List>[];
  bool _rendering = true;

  @override
  void initState() {
    super.initState();
    _renderPages();
  }

  Future<void> _renderPages() async {
    await for (final PdfRaster page in Printing.raster(
      widget.pdfBytes,
      dpi: 150,
    )) {
      if (!mounted) return;
      final Uint8List png = await page.toPng();
      if (!mounted) return;
      setState(() => _pages.add(png));
    }
    if (mounted) setState(() => _rendering = false);
  }

  Future<void> _share() async {
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/${widget.fileName}');
    await file.writeAsBytes(widget.pdfBytes, flush: true);

    if (!mounted) return;

    final RenderObject? renderObject = context.findRenderObject();
    final Rect origin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : const Rect.fromLTWH(0, 0, 1, 1);

    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path)],
        subject: 'BIO-G \u00b7 Reporte de Campo',
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          if (_rendering && _pages.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            ListView.builder(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + kToolbarHeight + 8,
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
                      child: Image.memory(
                        _pages[index],
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                );
              },
            ),
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
