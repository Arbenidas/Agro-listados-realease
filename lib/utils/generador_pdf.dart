// Archivo: lib/utils/pdf_generator.dart
// Modificado para soportar la descarga en la web

import 'dart:io' show File; // Importa solo 'File' de dart:io
// Necesario para Uint8List
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
// ignore: deprecated_member_use
import 'dart:html' as html; // Para interactuar con el navegador web
import '../models/product.dart';

Future<List<int>> generateProductListPdf(List<Product> products, {bool openFile = true}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(marginTop: 20, marginBottom: 20),
      build: (pw.Context context) {
        return [
          pw.Center(
            child: pw.Text(
              'LISTA DE PRODUCTOS',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Producto', 'Cantidad', 'Precio Unitario'],
            data: products.map((product) {
              return [
                product.name,
                product.quantity.toString(),
                '\$${product.unitPrice.toStringAsFixed(2)}',
              ];
            }).toList(),
            border: pw.TableBorder.all(color: PdfColors.black),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
            },
            cellStyle: const pw.TextStyle(fontSize: 10),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total de productos: ${products.length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ];
      },
    ),
  );

  final pdfBytes = await pdf.save();

  if (openFile) {
    if (kIsWeb) {
      // ✅ Lógica específica para la web: descarga el PDF
      final blob = html.Blob([Uint8List.fromList(pdfBytes)], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      // ignore: unused_local_variable
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "lista_productos.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Lógica existente para móvil/escritorio
      final String dir = (await getApplicationDocumentsDirectory()).path;
      final String path = '$dir/lista_productos.pdf';
      final File file = File(path);
      await file.writeAsBytes(pdfBytes);
      await OpenFilex.open(path);
    }
  }

  return pdfBytes;
}