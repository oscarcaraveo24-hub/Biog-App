import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bio_g/features/reporting/quick_report_card.dart';
import 'package:bio_g/features/reporting/quick_report_data.dart';

class ReportExportService {
  const ReportExportService();

  static const double _reportWidth = 1080;
  static const double _reportHeight = 1600;

  Future<void> exportQuickReport({
    required BuildContext context,
    required QuickReportData data,
  }) async {
    try {
      final Uint8List pngBytes = await _captureReportPng(
        context: context,
        data: data,
      );

      final File file = await _writeTempFile(pngBytes);

      if (!context.mounted) return;

      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        subject: 'BIO-G · Reporte del lote',
        text: _buildShareText(data),
        sharePositionOrigin: _shareOrigin(context),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo exportar el reporte. ${error.toString()}',
            ),
          ),
        );
    }
  }

  Future<Uint8List> _captureReportPng({
    required BuildContext context,
    required QuickReportData data,
  }) async {
    final OverlayState? overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) {
      throw Exception('No se encontró el overlay raíz para exportar.');
    }

    final GlobalKey boundaryKey = GlobalKey();
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return IgnorePointer(
          ignoring: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: -(_reportWidth + 48),
                top: 0,
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: QuickReportCard(
                    data: data,
                    width: _reportWidth,
                    height: _reportHeight,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(entry);

    try {
      await _waitForPaint();

      final BuildContext? boundaryContext = boundaryKey.currentContext;
      if (boundaryContext == null) {
        throw Exception('No se pudo construir el reporte para exportar.');
      }

      final RenderObject? renderObject = boundaryContext.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw Exception('No se pudo capturar la imagen del reporte.');
      }

      final ui.Image image = await renderObject.toImage(pixelRatio: 1.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      image.dispose();

      if (byteData == null) {
        throw Exception('No se pudo convertir el reporte a PNG.');
      }

      return byteData.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }

  Future<void> _waitForPaint() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  Future<File> _writeTempFile(Uint8List bytes) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String fileName =
        'biog_quick_report_${DateTime.now().millisecondsSinceEpoch}.png';
    final File file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Rect _shareOrigin(BuildContext context) {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }

    final Offset origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }

  String _buildShareText(QuickReportData data) {
    final StringBuffer buffer = StringBuffer()
      ..write('BIO-G · Reporte del lote')
      ..write('\n')
      ..write(data.displayLotOrDevice)
      ..write('\n')
      ..write('${data.cropLabel} · ${data.profileLabel}')
      ..write('\n')
      ..write(data.stageLabel);

    if (data.daySinceSowing != null) {
      buffer.write(' · Día ${data.daySinceSowing}');
    }

    buffer
      ..write('\n')
      ..write(data.recommendationTitle);

    return buffer.toString();
  }
}
