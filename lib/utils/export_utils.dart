// Archivo: lib/utils/export_utils.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_listados/models/units.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../models/product.dart';

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
      "",
      puntoId,
      csvFecha,
      p.id,
      p.name,
      totalProducto,
      p.unitPrice.toStringAsFixed(2),
      p.quantity.toString(),
      mapping["id"],
      mapping["name"],
      "",
      "",
    ];
  }).toList();

  final csv = StringBuffer();
  csv.writeln(headers.join(","));
  for (final row in rows) {
    csv.writeln(row.join(","));
  }

  return Uint8List.fromList(csv.toString().codeUnits);
}

Future<Uint8List> _generatePdfInBackground(Map<String, dynamic> data) async {
  final List<Product> products = data['products'];
  final String puntoName = data['puntoName'];
  final pdf = pw.Document();

  // ✅ Calcular totales
  final totalQuantity = products.fold<int>(0, (sum, p) => sum + p.quantity);
  final totalPrice = products.fold<double>(0.0, (sum, p) => sum + p.subtotal);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Lista de Productos para $puntoName',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: [
                '', // ✅ Columna para el checkbox
                'Nombre',
                'Cantidad',
                'Unidad',
                'Precio Unitario',
                'Subtotal'
              ],
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5), // Ancho para el checkbox
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.5),
              },
              data: products
                  .map((p) => [
                        '', // ✅ Espacio en blanco para el checkbox
                        p.name,
                        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(p.quantity.toString())),
                        p.unit.name,
                        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(p.unitPrice.toStringAsFixed(2))),
                        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(p.subtotal.toStringAsFixed(2))),
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 30),
            // ✅ Nuevo apartado de totales
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Bultos:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.SizedBox(height: 5),
                    pw.Text(totalQuantity.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Precio Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.SizedBox(height: 5),
                    pw.Text('\$${totalPrice.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
  return await pdf.save();
}

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
  final now = DateTime.now().add(const Duration(days: 1));
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
        fileData = await compute(_generatePdfInBackground, {
          'products': products,
          'puntoName': puntoName,
        });
        fileName = 'Lista_${puntoName}_$fileDate.pdf';
        mimeType = 'application/pdf';
        title = 'Lista de Productos (PDF)';
        break;

      case 'zip':
        final csvData = await compute(_generateCsvInBackground, {
          'items': products,
          'puntoId': puntoId,
        });
        final pdfData = await compute(_generatePdfInBackground, {
          'products': products,
          'puntoName': puntoName,
        });
        
        final archive = Archive();
        archive.addFile(ArchiveFile('${puntoName}_$fileDate.csv', csvData.length, csvData));
        archive.addFile(ArchiveFile('${puntoName}_$fileDate.pdf', pdfData.length, pdfData));
        fileData = Uint8List.fromList(ZipEncoder().encode(archive)!);
        fileName = 'Despacho_${puntoName.replaceAll(' ', '_')}_$fileDate.zip';
        mimeType = 'application/zip';
        title = 'Archivos de Despacho (ZIP)';
        break;
    }

    if (context.mounted) Navigator.of(context).pop();

    if (fileData != null) {
      if (kIsWeb) {
        // En la web, se fuerza la descarga para todos los tipos de archivo.
        final blob = html.Blob([fileData], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

      } else {
        // Lógica de compartir en móvil con fallback para guardar el archivo
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
            // Lógica de fallback: preguntar al usuario si desea guardar
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
                // Guarda el archivo en un directorio público accesible
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
              // El usuario no quiso guardar, no hacemos nada
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
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir: $e')),
      );
    }
  } finally {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
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