import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../../models/koko_bill_model.dart';
import 'formatters.dart';
import 'web_exporter.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';


class KokoExporter {
  static Future<void> exportToJpg({
    required BuildContext context,
    required GlobalKey boundaryKey,
    required String filename,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        downloadImage(filename, pngBytes);
      }
    } catch (e) {
      debugPrint('Export JPG Error: $e');
    }
  }

  static Future<void> exportToPdf({
    required List<KokoBillEntry> whiteEntries,
    required List<KokoBillEntry> mykostEntries,
    required String filename,
  }) async {
    final pdf = pw.Document();
    int currentNota = 1;

    // White Kost Entries
    for (final entry in whiteEntries) {
      if (entry.receiptUrl == null || entry.receiptUrl!.isEmpty) continue;

      await _addPdfPage(pdf, entry, 'Nota $currentNota', 'White Kost 35', PdfColors.green700);
      currentNota++;
    }

    // Mykost Entries
    for (final entry in mykostEntries) {
      if (entry.receiptUrl == null || entry.receiptUrl!.isEmpty) continue;

      await _addPdfPage(pdf, entry, 'Nota $currentNota', 'Mykost 179', PdfColors.orange900);
      currentNota++;
    }

    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  static Future<void> _addPdfPage(
      pw.Document pdf,
      KokoBillEntry entry,
      String notaLabel,
      String kostName,
      PdfColor kostColor,
      ) async {
    try {
      final response = await http.get(Uri.parse(entry.receiptUrl!));
      if (response.statusCode == 200) {
        final image = pw.MemoryImage(response.bodyBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.copyWith(
              height: 550, // Reduced height for less white space
            ),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.yellow,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          notaLabel,
                          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Text(
                        kostName,
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: kostColor),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    entry.title.isEmpty ? '(Tanpa Judul)' : entry.title,
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    entry.date ?? '',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Image(image, fit: pw.BoxFit.contain),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading receipt image for PDF: $e');
    }
  }
}
