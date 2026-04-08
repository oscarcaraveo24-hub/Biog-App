import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:bio_g/features/reporting/quick_report_data.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class PdfReportBuilder {
  const PdfReportBuilder();

  static const PdfColor _brand = PdfColors.green800;
  static const PdfColor _brandLight = PdfColors.green50;
  static const PdfColor _ink = PdfColors.grey900;
  static const PdfColor _subtle = PdfColors.grey600;
  static const PdfColor _border = PdfColors.grey300;
  static const PdfColor _altRow = PdfColors.grey50;

  Future<Uint8List> build({
    required QuickReportData data,
    BioGTelemetry? telemetry,
  }) async {
    final ByteData logoData = await rootBundle.load(
      'assets/images/logo_bio_g.png',
    );
    final pw.MemoryImage logo = pw.MemoryImage(logoData.buffer.asUint8List());

    final pw.Document doc = pw.Document(
      title: 'BIO-G · Reporte de Campo',
      author: 'BIO-G',
      subject: 'Reporte de monitoreo agrícola',
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context ctx) => _header(data, logo),
        footer: (pw.Context ctx) => _footer(data, ctx),
        build: (pw.Context ctx) => <pw.Widget>[
          pw.SizedBox(height: 6),
          _cropSection(data),
          pw.SizedBox(height: 16),
          _npkSection(data),
          pw.SizedBox(height: 16),
          _soilSection(telemetry),
          pw.SizedBox(height: 16),
          _environmentSection(telemetry),
          pw.SizedBox(height: 16),
          _recommendationSection(data),
          if (data.hasClimateBanner) ...<pw.Widget>[
            pw.SizedBox(height: 16),
            _climateSection(data),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _header(QuickReportData data, pw.MemoryImage logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 14),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 1.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: -17),
            child: pw.Transform.scale(
              scale: 1.35,
              alignment: pw.Alignment.centerLeft,
              child: pw.Image(
                logo,
                width: 54,
                height: 54,
                fit: pw.BoxFit.contain,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  'BIO-G · Reporte de Campo',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  data.displayLotOrDevice,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _subtle,
                  ),
                ),
                pw.Text(
                  'Dispositivo: ${data.deviceName}',
                  style: const pw.TextStyle(fontSize: 9, color: _subtle),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              _headerPrimaryStamp(
                label: 'Lectura',
                value: data.readingAt,
                emptyLabel: 'Sin lectura actual',
              ),
              if (data.generatedAt != null) ...<pw.Widget>[
                pw.SizedBox(height: 5),
                _headerSecondaryStamp(
                  label: 'Generado',
                  value: data.generatedAt!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _headerPrimaryStamp({
    required String label,
    required DateTime? value,
    String emptyLabel = '—',
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: <pw.Widget>[
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _subtle)),
        pw.SizedBox(height: 2),
        if (value == null)
          pw.Text(
            emptyLabel,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          )
        else ...<pw.Widget>[
          pw.Text(
            _fmtDate(value),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.Text(
            _fmtTime(value),
            style: const pw.TextStyle(fontSize: 9, color: _subtle),
          ),
        ],
      ],
    );
  }

  pw.Widget _headerSecondaryStamp({
    required String label,
    required DateTime value,
  }) {
    return pw.Text(
      '$label: ${_fmtDate(value)} · ${_fmtTime(value)}',
      style: const pw.TextStyle(fontSize: 7, color: _subtle),
      textAlign: pw.TextAlign.right,
    );
  }

  pw.Widget _footer(QuickReportData data, pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            'Reporte generado por BIO-G · Compartible con ingeniero agrónomo',
            style: const pw.TextStyle(fontSize: 7, color: _subtle),
          ),
          pw.Text(
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: _subtle),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionBar(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _brand,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _cropSection(QuickReportData data) {
    final String dayText = data.daySinceSowing != null
        ? 'Día ${data.daySinceSowing} desde siembra'
        : '—';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionBar('INFORMACIÓN DEL CULTIVO'),
        pw.SizedBox(height: 8),
        _kvTable(<List<String>>[
          <String>['Cultivo', data.cropLabel],
          <String>['Perfil / Variedad', data.profileLabel],
          <String>['Etapa fenológica', data.stageLabel],
          <String>['Día de cultivo', dayText],
        ]),
      ],
    );
  }

  pw.Widget _npkSection(QuickReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionBar('LECTURA NPK ACTUAL'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.5),
          columnWidths: <int, pw.TableColumnWidth>{
            0: const pw.FlexColumnWidth(1.4),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.6),
          },
          children: <pw.TableRow>[
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _brand),
              children: <pw.Widget>[
                _cell('Nutriente', header: true),
                _cell('Valor (ppm)', header: true),
                _cell('Estado', header: true),
              ],
            ),
            _npkRow('Nitrógeno (N)', data.nValue, data.nStatus, false),
            _npkRow('Fósforo (P)', data.pValue, data.pStatus, true),
            _npkRow('Potasio (K)', data.kValue, data.kStatus, false),
          ],
        ),
      ],
    );
  }

  pw.TableRow _npkRow(String label, double ppm, String status, bool alt) {
    return pw.TableRow(
      decoration: alt ? const pw.BoxDecoration(color: _altRow) : null,
      children: <pw.Widget>[_cell(label), _cell(_fmtPpm(ppm)), _cell(status)],
    );
  }

  pw.Widget _soilSection(BioGTelemetry? t) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionBar('MÉTRICAS DE SUELO'),
        pw.SizedBox(height: 8),
        if (t == null)
          _noDataBox()
        else
          _kvTable(<List<String>>[
            <String>[
              'Humedad de suelo',
              '${t.soilMoisturePct.toStringAsFixed(1)} %',
            ],
            <String>[
              'Temperatura del suelo',
              '${t.soilTempC.toStringAsFixed(1)} °C',
            ],
            <String>['pH', t.ph.toStringAsFixed(2)],
            <String>[
              'Conductividad eléctrica (EC)',
              '${t.ec.toStringAsFixed(2)} mS/cm',
            ],
            <String>[
              'Resistencia / Compactación',
              '${t.resistance.toStringAsFixed(2)} MPa',
            ],
          ]),
      ],
    );
  }

  pw.Widget _environmentSection(BioGTelemetry? t) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionBar('CONDICIONES AMBIENTALES'),
        pw.SizedBox(height: 8),
        if (t == null)
          _noDataBox()
        else
          _kvTable(<List<String>>[
            <String>[
              'Temperatura ambiente',
              '${t.airTempC.toStringAsFixed(1)} °C',
            ],
            <String>[
              'Humedad del aire',
              '${t.airHumidityPct.toStringAsFixed(1)} %',
            ],
          ]),
      ],
    );
  }

  pw.Widget _recommendationSection(QuickReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionBar('RECOMENDACIÓN PRINCIPAL'),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _brandLight,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: _border, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                data.recommendationTitle,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                data.recommendationBody,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: _ink,
                  lineSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _climateSection(QuickReportData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.amber200, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            data.climateBannerTitle ?? 'Clima inteligente',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            data.climateBannerBody ?? '',
            style: const pw.TextStyle(fontSize: 10, color: _ink),
          ),
        ],
      ),
    );
  }

  pw.Widget _cell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: header ? PdfColors.white : _ink,
        ),
      ),
    );
  }

  pw.Widget _kvTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
      },
      children: rows.asMap().entries.map((MapEntry<int, List<String>> e) {
        final bool alt = e.key.isOdd;
        return pw.TableRow(
          decoration: alt ? const pw.BoxDecoration(color: _altRow) : null,
          children: <pw.Widget>[
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: pw.Text(
                e.value[0],
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              child: pw.Text(
                e.value[1],
                style: const pw.TextStyle(fontSize: 10, color: _ink),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  pw.Widget _noDataBox() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _altRow,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        'Sin datos disponibles en este momento.',
        style: const pw.TextStyle(fontSize: 10, color: _subtle),
      ),
    );
  }

  String _fmtPpm(double v) => v <= 0 ? '—' : v.toStringAsFixed(1);

  String _fmtDate(DateTime dt) {
    const List<String> m = <String>[
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  String _fmtTime(DateTime dt) {
    final int h24 = dt.hour;
    final int h = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    final String min = dt.minute.toString().padLeft(2, '0');
    final String suf = h24 >= 12 ? 'pm' : 'am';
    return '$h:$min $suf';
  }
}
