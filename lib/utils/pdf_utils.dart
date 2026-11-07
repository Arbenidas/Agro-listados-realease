// Archivo: lib/utils/pdf_generator.dart
// Unificado y completo

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/product.dart';

Future<Uint8List> generateProductListPdf(
    List<Product> products, {
    String? puntoName,
}) async {
  final pdf = pw.Document();

  final totalQuantity = products.fold<int>(0, (sum, p) => sum + p.quantity);
  final totalPrice = products.fold<double>(0.0, (sum, p) => sum + p.subtotal);

  final regularProducts = products.where((p) => !p.isCdaProduct).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  final cdaProducts = products.where((p) => p.isCdaProduct).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  List<List<dynamic>> buildRows(List<Product> list) {
    return list
        .map((p) => [
              '',
              p.name,
              pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(p.quantity.toString())),
              p.unit.name,
              pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(p.unitPrice.toStringAsFixed(2))),
              pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(p.subtotal.toStringAsFixed(2))),
            ])
        .toList();
  }

  const headers = [
    '',
    'Nombre',
    'Cantidad',
    'Unidad',
    'Precio Unitario',
    'Subtotal'
  ];

  const columnWidths = {
    0: pw.FlexColumnWidth(0.5),
    1: pw.FlexColumnWidth(2.5),
    2: pw.FlexColumnWidth(1),
    3: pw.FlexColumnWidth(1.2),
    4: pw.FlexColumnWidth(1.5),
    5: pw.FlexColumnWidth(1.5),
  };

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(marginTop: 20, marginBottom: 20),
      build: (pw.Context context) {
        return [
          pw.Center(
            child: pw.Text(
              puntoName != null
                  ? 'Lista de Productos para $puntoName'
                  : 'LISTA DE PRODUCTOS',
              style: pw.TextStyle(
                  fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 20),
          if (regularProducts.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: headers,
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              columnWidths: columnWidths,
              data: buildRows(regularProducts),
              border: pw.TableBorder.all(color: PdfColors.grey500),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey700),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(
                          color: PdfColors.grey300, width: 0.5))),
            ),
          if (cdaProducts.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text(
              'Central de Abastos (CDA)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: headers,
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              columnWidths: columnWidths,
              data: buildRows(cdaProducts),
              border: pw.TableBorder.all(color: PdfColors.grey500),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey600),
              cellStyle:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
              rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(
                          color: PdfColors.grey300, width: 0.5))),
            ),
          ],
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total Bultos:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.SizedBox(height: 5),
                  pw.Text(totalQuantity.toString(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Precio Total:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.SizedBox(height: 5),
                  pw.Text('\$${totalPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
                ],
              ),
            ],
          ),
        ];
      },
    ),
  );
  return await pdf.save();
}