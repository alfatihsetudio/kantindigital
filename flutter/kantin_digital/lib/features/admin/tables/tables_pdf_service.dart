import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import '../../../core/config/api_config.dart';
import '../../../shared/models/table_model.dart';

class TablesPdfService {
  /// Generate PDF untuk daftar meja dengan QR code
  Future<void> generateAndDownloadPdf(List<TableModel> tables) async {
    final pdf = pw.Document();

    // Process tables in batches of 6 per page (2 columns, 3 rows)
    final pageSize = 6;
    for (int i = 0; i < tables.length; i += pageSize) {
      final batch = tables.sublist(
        i,
        i + pageSize > tables.length ? tables.length : i + pageSize,
      );

      final page = await _buildTablePage(batch);
      pdf.addPage(page);
    }

    // Download PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'daftar_meja_qr_${DateTime.now().toString().split(' ')[0]}.pdf',
    );
  }

  /// Build page dengan 2 kolom layout
  Future<pw.Page> _buildTablePage(List<TableModel> tables) async {
    // Split tables into 2 columns
    final col1 = <pw.Widget>[];
    final col2 = <pw.Widget>[];

    for (int i = 0; i < tables.length; i++) {
      final table = tables[i];
      final card = await _buildTableCard(table);

      if (i % 2 == 0) {
        col1.add(card);
      } else {
        col2.add(card);
      }

      if (i < tables.length - 1) {
        if (i % 2 == 0) {
          col1.add(pw.SizedBox(height: 16));
        } else {
          col2.add(pw.SizedBox(height: 16));
        }
      }
    }

    // Equalize column heights
    while (col1.length < col2.length) {
      col1.add(pw.SizedBox(height: 0));
    }
    while (col2.length < col1.length) {
      col2.add(pw.SizedBox(height: 0));
    }

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) {
        return pw.Column(
          children: [
            pw.Text(
              'Daftar Meja & QR Code',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: pw.Column(children: col1)),
                pw.SizedBox(width: 20),
                pw.Expanded(child: pw.Column(children: col2)),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Build individual table card dengan QR code
  Future<pw.Widget> _buildTableCard(TableModel table) async {
    // Generate QR code
    final qrImage = await _generateQrImage(table.code);

    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Meja ${table.code}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          if (qrImage != null)
            pw.Image(
              qrImage,
              width: 120,
              height: 120,
            ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Scan untuk memesan',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Generate QR code sebagai image
  Future<pw.ImageProvider?> _generateQrImage(String code) async {
    try {
      final qrData = '${ApiConfig.webBaseUrl}/#/?table=$code';

      // Generate QR code image
      final qrImage = await QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
      ).toImage(200);

      // Convert to bytes
      final byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      return pw.MemoryImage(pngBytes);
    } catch (e) {
      // Error generating QR code, return null to handle gracefully
      return null;
    }
  }
}
