// Archivo: lib/utils/export_utils.dart
// Modificado para añadir el resumen total de bultos y precio al final del PDF.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../models/product.dart';
import '../data/units.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// --- Funciones de generación en segundo plano ---

Future<Uint8List> _generateCsvInBackground(Map<String, dynamic> data) async {
  final List<Product> items = data['items'];
  final String puntoId = data['puntoId'];
  final now = DateTime.now().add(const Duration(days: 1));
  final csvFecha = DateFormat('dd/MM/yyyy').format(now);

  final headers = [
    "IdCargado",
    "IdPunto",
    "FechaVenta",
    "IdProducto",
    "Producto",
    "TotalProducto",
    "UnidadesPrecio",
    "Cantidad",
    "IdMedida",
    "UnidadMedida",
    "DatosCargados",
    "UsuarioApp",
  ];

  final rows = items.map((p) {
    final mapping = unitMapping[p.unit]!;
    final totalProducto = (p.quantity * p.unitPrice).toStringAsFixed(2);
    return [
      _escapeCsvField(""),
      _escapeCsvField(puntoId),
      _escapeCsvField(csvFecha),
      _escapeCsvField(p.id),
      _escapeCsvField(p.name),
      _escapeCsvField(totalProducto),
      _escapeCsvField(p.unitPrice.toStringAsFixed(2)),
      _escapeCsvField(p.quantity.toString()),
      _escapeCsvField(mapping["id"].toString()),
      _escapeCsvField(mapping["name"]!),
      _escapeCsvField(""),
      _escapeCsvField(""),
    ];
  }).toList();

  final csv = StringBuffer();
  csv.writeln(headers.map(_escapeCsvField).join(","));
  for (final row in rows) {
    csv.writeln(row.join(","));
  }

  return Uint8List.fromList(utf8.encode(csv.toString()));
}

String _escapeCsvField(String field) {
  if (field.contains(',') || field.contains('"') || field.contains('\n')) {
    return '"${field.replaceAll('"', '""')}"';
  }
  return field;
}

// ✅ Función consolidada para generar el PDF con el resumen al final
Future<Uint8List> _generateProductListPdf(List<Product> products, {String? puntoName}) async {
  final pdf = pw.Document();

  final totalBultos = products.fold(0.0, (sum, p) => sum + p.quantity);
  final totalPrecio = products.fold(0.0, (sum, p) => sum + (p.quantity * p.unitPrice));

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Lista de Productos',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            if (puntoName != null) ...[
              pw.SizedBox(height: 5),
              pw.Text('Punto de Despacho: $puntoName', style: const pw.TextStyle(fontSize: 9)),
            ],
            pw.SizedBox(height: 10),
            pw.Text(
              'Detalles de Productos:',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Table.fromTextArray(
              cellPadding: const pw.EdgeInsets.all(3),
              headers: ['Producto', 'Cantidad', 'Precio Unitario'],
              data: products.map((product) {
                final isPriceMissing = product.unitPrice == 0 || product.unitPrice == null;
                final productNameText = isPriceMissing
                    ? pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: product.name,
                              style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 8),
                            ),
                            pw.TextSpan(
                              text: '\n(No lleva precio)',
                              style: pw.TextStyle(color: PdfColors.red, fontSize: 6, fontStyle: pw.FontStyle.italic),
                            ),
                          ],
                        ),
                      )
                    : pw.Text(product.name, style: const pw.TextStyle(fontSize: 8));

                return [
                  productNameText,
                  '${product.quantity}',
                  isPriceMissing ? 'N/A' : '\$${product.unitPrice.toStringAsFixed(2)}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
            // ✅ Se añade un expansor para que la tabla y el resumen se separen
            pw.Spacer(), 
            pw.Divider(),
            pw.Text(
              'Resumen de la lista',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total de Bultos:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text(totalBultos.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total del Precio:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('\$${totalPrecio.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        );
      },
    ),
  );
  return pdf.save();
}

// Wrapper para `compute`
Future<Uint8List> _pdfGeneratorComputeWrapper(Map<String, dynamic> data) async {
  final List<Product> products = data['products'];
  final String? puntoName = data['puntoName'];
  return await _generateProductListPdf(products, puntoName: puntoName);
}

// --- Funciones de exportación y compartición ---

Future<void> shareCsv(List<Product> items,
    {required String puntoId,
    required String puntoName,
    required BuildContext context}) async {
  await _prepareAndShare(
    context: context,
    products: items,
    puntoId: puntoId,
    puntoName: puntoName,
    exportType: 'csv',
  );
}

Future<void> sharePdf(List<Product> products,
    {required String puntoId,
    required String puntoName,
    required BuildContext context}) async {
  await _prepareAndShare(
    context: context,
    products: products,
    puntoId: puntoId,
    puntoName: puntoName,
    exportType: 'pdf',
  );
}

Future<void> shareZip(List<Product> products,
    {required String puntoId,
    required String puntoName,
    required BuildContext context}) async {
  await _prepareAndShare(
    context: context,
    products: products,
    puntoId: puntoId,
    puntoName: puntoName,
    exportType: 'zip',
  );
}

Future<void> _prepareAndShare({
  required BuildContext context,
  required List<Product> products,
  required String puntoId,
  required String puntoName,
  required String exportType,
}) async {
  _showLoadingDialog(context);
  final now = DateTime.now();
  final fileDate = DateFormat('dd-MM-yyyy').format(now);
  String title = '';
  Uint8List? fileData;
  String fileName = '';
  String mimeType = '';

  try {
    switch (exportType) {
      case 'csv':
        fileData = await compute(_generateCsvInBackground, {
          'items': products,
          'puntoId': puntoId,
        });
        fileName = 'DESPACHO_${puntoName.replaceAll(' ', '_')}_$fileDate.csv';
        mimeType = 'text/csv';
        title = 'Lista de Productos (CSV)';
        break;

      case 'pdf':
        fileData = await compute(_pdfGeneratorComputeWrapper, {
          'products': products,
          'puntoName': puntoName,
        });
        fileName = 'Lista_${puntoName.replaceAll(' ', '_')}_$fileDate.pdf';
        mimeType = 'application/pdf';
        title = 'Lista de Productos (PDF)';
        break;

      case 'zip':
        final csvData = await compute(_generateCsvInBackground, {
          'items': products,
          'puntoId': puntoId,
        });
        final pdfData = await compute(_pdfGeneratorComputeWrapper, {
          'products': products,
          'puntoName': puntoName,
        });
        
        final archive = Archive();
        archive.addFile(ArchiveFile('DESPACHO_${puntoName.replaceAll(' ', '_')}_$fileDate.csv', csvData.length, csvData));
        archive.addFile(ArchiveFile('Lista_${puntoName.replaceAll(' ', '_')}_$fileDate.pdf', pdfData.length, pdfData));
        
        fileData = Uint8List.fromList(ZipEncoder().encode(archive, level: Deflate.DEFAULT_COMPRESSION)!);
        fileName = 'Despacho_${puntoName.replaceAll(' ', '_')}_$fileDate.zip';
        mimeType = 'application/zip';
        title = 'Archivos de Despacho (ZIP)';
        break;
    }

    if (context.mounted) Navigator.of(context).pop();

    if (fileData != null) {
      if (kIsWeb) {
        final blob = html.Blob([fileData], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

      } else {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(p.join(tempDir.path, fileName));
        await tempFile.writeAsBytes(fileData);
        final filesToShare = [XFile(tempFile.path, name: fileName)];
        
        bool sharedSuccessfully = false;
        try {
          await Share.shareXFiles(filesToShare,
            subject: title,
            sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1));
          sharedSuccessfully = true;
        } catch (e) {
          debugPrint("Error o cancelación al compartir: $e");
        }

        if (context.mounted) {
          if (sharedSuccessfully) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title compartido exitosamente')),
            );
          } else {
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Compartir Cancelado'),
                content: const Text('¿Deseas guardar el archivo en tu dispositivo?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            );

            if (result == true) {
              final status = await Permission.storage.request();
              if (status.isGranted) {
                final directory = await getExternalStorageDirectory();
                if (directory != null) {
                  final newPath = p.join(directory.path, fileName);
                  await tempFile.copy(newPath);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Archivo guardado en ${directory.path}')),
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Permiso denegado para guardar archivo')),
                  );
                }
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Operación cancelada')),
                );
              }
            }
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Error general en _prepareAndShare: $e');
    if (context.mounted) {
      if (Navigator.of(context).canPop()) {
         Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al preparar/compartir archivo: $e')),
      );
    }
  } finally {
    if (context.mounted && Navigator.of(context).canPop()) {
       final currentRoute = ModalRoute.of(context);
       if (currentRoute is PopupRoute && currentRoute.barrierDismissible == false) {
           Navigator.of(context).pop();
       }
    }
  }
}

void _showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(child: CircularProgressIndicator());
    },
  );
}